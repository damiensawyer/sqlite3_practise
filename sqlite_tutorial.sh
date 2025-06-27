#!/bin/bash

# SQLite3 Tutorial Script
# This script teaches SQLite3 CLI usage by creating a sample database
# with realistic data and demonstrating various SQL operations

DB_FILE="tutorial.db"

echo "=== SQLite3 CLI Tutorial ==="
echo "This script will create a sample database and demonstrate SQLite3 operations"
echo

# Remove existing database to ensure idempotency
if [ -f "$DB_FILE" ]; then
    echo "Removing existing database..."
    rm "$DB_FILE"
fi

echo "Creating new database: $DB_FILE"
echo

# Create database and tables
echo "=== Creating Tables ==="

# 1. Users table
echo "Creating users table..."
sqlite3 "$DB_FILE" <<EOF
CREATE TABLE users (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    username TEXT UNIQUE NOT NULL,
    email TEXT UNIQUE NOT NULL,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'active'
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_status ON users(status);
EOF

# 2. Categories table
echo "Creating categories table..."
sqlite3 "$DB_FILE" <<EOF
CREATE TABLE categories (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT UNIQUE NOT NULL,
    description TEXT
);
EOF

# 3. Products table
echo "Creating products table..."
sqlite3 "$DB_FILE" <<EOF
CREATE TABLE products (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    name TEXT NOT NULL,
    category_id INTEGER,
    price DECIMAL(10,2) NOT NULL,
    stock_quantity INTEGER DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id)
);

CREATE INDEX idx_products_category ON products(category_id);
CREATE INDEX idx_products_price ON products(price);
EOF

# 4. Orders table
echo "Creating orders table..."
sqlite3 "$DB_FILE" <<EOF
CREATE TABLE orders (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    user_id INTEGER NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    order_date DATETIME DEFAULT CURRENT_TIMESTAMP,
    status TEXT DEFAULT 'pending',
    FOREIGN KEY (user_id) REFERENCES users(id)
);

CREATE INDEX idx_orders_user ON orders(user_id);
CREATE INDEX idx_orders_date ON orders(order_date);
EOF

# 5. Order items table
echo "Creating order_items table..."
sqlite3 "$DB_FILE" <<EOF
CREATE TABLE order_items (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    product_id INTEGER NOT NULL,
    quantity INTEGER NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id),
    FOREIGN KEY (product_id) REFERENCES products(id)
);

CREATE INDEX idx_order_items_order ON order_items(order_id);
CREATE INDEX idx_order_items_product ON order_items(product_id);
EOF

echo "All tables created successfully!"
echo

# Insert sample data
echo "=== Inserting Sample Data ==="

echo "Inserting users..."
sqlite3 "$DB_FILE" <<EOF
INSERT INTO users (username, email, status) VALUES
    ('alice_smith', 'alice@email.com', 'active'),
    ('bob_jones', 'bob@email.com', 'active'),
    ('carol_white', 'carol@email.com', 'inactive'),
    ('david_brown', 'david@email.com', 'active'),
    ('eve_davis', 'eve@email.com', 'active');
EOF

echo "Inserting categories..."
sqlite3 "$DB_FILE" <<EOF
INSERT INTO categories (name, description) VALUES
    ('Electronics', 'Electronic devices and accessories'),
    ('Books', 'Physical and digital books'),
    ('Clothing', 'Apparel and fashion items'),
    ('Home & Garden', 'Home improvement and gardening supplies'),
    ('Sports', 'Sports equipment and accessories');
EOF

echo "Inserting products..."
sqlite3 "$DB_FILE" <<EOF
INSERT INTO products (name, category_id, price, stock_quantity) VALUES
    ('Smartphone', 1, 699.99, 50),
    ('Laptop', 1, 1299.99, 25),
    ('Headphones', 1, 199.99, 100),
    ('Python Programming Book', 2, 45.99, 30),
    ('JavaScript Guide', 2, 39.99, 20),
    ('T-Shirt', 3, 19.99, 200),
    ('Jeans', 3, 79.99, 75),
    ('Garden Hose', 4, 29.99, 40),
    ('Flower Pot', 4, 15.99, 60),
    ('Tennis Racket', 5, 89.99, 15);
EOF

echo "Inserting orders..."
sqlite3 "$DB_FILE" <<EOF
INSERT INTO orders (user_id, total_amount, status, order_date) VALUES
    (1, 719.98, 'completed', '2024-01-15 10:30:00'),
    (2, 1299.99, 'completed', '2024-01-20 14:45:00'),
    (1, 45.99, 'pending', '2024-02-01 09:15:00'),
    (4, 109.98, 'completed', '2024-02-05 16:20:00'),
    (5, 199.99, 'shipped', '2024-02-10 11:00:00');
EOF

echo "Inserting order items..."
sqlite3 "$DB_FILE" <<EOF
INSERT INTO order_items (order_id, product_id, quantity, unit_price) VALUES
    (1, 1, 1, 699.99),
    (1, 6, 1, 19.99),
    (2, 2, 1, 1299.99),
    (3, 4, 1, 45.99),
    (4, 3, 1, 199.99),
    (4, 8, 1, 29.99),
    (4, 9, 5, 15.99),
    (5, 3, 1, 199.99);
EOF

echo "Sample data inserted successfully!"
echo

# Demonstrate SQLite3 CLI operations
echo "=== SQLite3 CLI Tutorial - Basic Operations ==="
echo

echo "1. Show all tables:"
echo "Command: sqlite3 $DB_FILE '.tables'"
sqlite3 "$DB_FILE" '.tables'
echo

echo "2. Show schema for users table:"
echo "Command: sqlite3 $DB_FILE '.schema users'"
sqlite3 "$DB_FILE" '.schema users'
echo

echo "3. Show all indexes:"
echo "Command: sqlite3 $DB_FILE '.indexes'"
sqlite3 "$DB_FILE" '.indexes'
echo

echo "=== Basic SELECT Queries ==="
echo

echo "4. Select all users:"
echo "Command: sqlite3 $DB_FILE 'SELECT * FROM users;'"
sqlite3 "$DB_FILE" 'SELECT * FROM users;'
echo

echo "5. Count products by category:"
echo "Command: sqlite3 $DB_FILE 'SELECT category_id, COUNT(*) as product_count FROM products GROUP BY category_id;'"
sqlite3 "$DB_FILE" 'SELECT category_id, COUNT(*) as product_count FROM products GROUP BY category_id;'
echo

echo "=== JOIN Queries ==="
echo

echo "6. Products with category names (INNER JOIN):"
echo "Command: sqlite3 $DB_FILE 'SELECT p.name, c.name as category, p.price FROM products p INNER JOIN categories c ON p.category_id = c.id;'"
sqlite3 "$DB_FILE" 'SELECT p.name, c.name as category, p.price FROM products p INNER JOIN categories c ON p.category_id = c.id;'
echo

echo "7. User orders with totals (INNER JOIN):"
echo "Command: sqlite3 $DB_FILE 'SELECT u.username, o.id as order_id, o.total_amount, o.status FROM users u INNER JOIN orders o ON u.id = o.user_id;'"
sqlite3 "$DB_FILE" 'SELECT u.username, o.id as order_id, o.total_amount, o.status FROM users u INNER JOIN orders o ON u.id = o.user_id;'
echo

echo "8. Complex JOIN - Order details with user and product info:"
echo "Command: sqlite3 $DB_FILE 'SELECT u.username, p.name as product, oi.quantity, oi.unit_price, o.order_date FROM users u JOIN orders o ON u.id = o.user_id JOIN order_items oi ON o.id = oi.order_id JOIN products p ON oi.product_id = p.id ORDER BY o.order_date;'"
sqlite3 "$DB_FILE" 'SELECT u.username, p.name as product, oi.quantity, oi.unit_price, o.order_date FROM users u JOIN orders o ON u.id = o.user_id JOIN order_items oi ON o.id = oi.order_id JOIN products p ON oi.product_id = p.id ORDER BY o.order_date;'
echo

echo "=== Advanced Queries ==="
echo

echo "9. Users who haven't placed orders (LEFT JOIN):"
echo "Command: sqlite3 $DB_FILE 'SELECT u.username, u.email FROM users u LEFT JOIN orders o ON u.id = o.user_id WHERE o.id IS NULL;'"
sqlite3 "$DB_FILE" 'SELECT u.username, u.email FROM users u LEFT JOIN orders o ON u.id = o.user_id WHERE o.id IS NULL;'
echo

echo "10. Top spending customers:"
echo "Command: sqlite3 $DB_FILE 'SELECT u.username, SUM(o.total_amount) as total_spent FROM users u JOIN orders o ON u.id = o.user_id GROUP BY u.id, u.username ORDER BY total_spent DESC;'"
sqlite3 "$DB_FILE" 'SELECT u.username, SUM(o.total_amount) as total_spent FROM users u JOIN orders o ON u.id = o.user_id GROUP BY u.id, u.username ORDER BY total_spent DESC;'
echo

echo "11. Products never ordered (subquery):"
echo "Command: sqlite3 $DB_FILE 'SELECT name, price FROM products WHERE id NOT IN (SELECT DISTINCT product_id FROM order_items);'"
sqlite3 "$DB_FILE" 'SELECT name, price FROM products WHERE id NOT IN (SELECT DISTINCT product_id FROM order_items);'
echo

echo "12. Average order value by month:"
echo "Command: sqlite3 $DB_FILE 'SELECT strftime(\"%Y-%m\", order_date) as month, AVG(total_amount) as avg_order_value, COUNT(*) as order_count FROM orders GROUP BY strftime(\"%Y-%m\", order_date);'"
sqlite3 "$DB_FILE" 'SELECT strftime("%Y-%m", order_date) as month, AVG(total_amount) as avg_order_value, COUNT(*) as order_count FROM orders GROUP BY strftime("%Y-%m", order_date);'
echo

echo "=== Useful SQLite3 CLI Commands ==="
echo
echo "Try these commands yourself:"
echo "  sqlite3 $DB_FILE                    # Enter interactive mode"
echo "  .help                               # Show all dot commands"
echo "  .mode column                        # Better formatting"
echo "  .headers on                         # Show column headers"
echo "  .output results.txt                 # Redirect output to file"
echo "  .read script.sql                    # Execute SQL from file"
echo "  .backup backup.db                   # Backup database"
echo "  .exit                               # Exit SQLite3"
echo

echo "=== Tutorial Complete! ==="
echo "Database '$DB_FILE' has been created with sample data."
echo "You can now experiment with your own queries using:"
echo "  sqlite3 $DB_FILE"
echo