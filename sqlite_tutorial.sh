#!/bin/bash

# SQLite3 Tutorial Script
# This script teaches SQLite3 CLI usage by creating a sample database
# with realistic sensor data and demonstrating various SQL operations

# Configuration variables
NUM_ROOMS=50
LOGS_PER_ROOM=100000
DB_FILE="tutorial.db"

echo "=== SQLite3 CLI Tutorial ==="
echo "This script will create a sample database with $NUM_ROOMS rooms and $LOGS_PER_ROOM sensor logs per room"
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

# 1. Rooms table
echo "Creating rooms table..."
sqlite3 "$DB_FILE" <<EOF
CREATE TABLE rooms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_number TEXT UNIQUE NOT NULL,
    building_name TEXT NOT NULL,
    floor_number INTEGER NOT NULL,
    room_type TEXT NOT NULL,
    capacity INTEGER,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_rooms_building ON rooms(building_name);
CREATE INDEX idx_rooms_floor ON rooms(floor_number);
CREATE INDEX idx_rooms_type ON rooms(room_type);
CREATE INDEX idx_rooms_number ON rooms(room_number);
EOF

# 2. Sensor logs table
echo "Creating sensor_logs table..."
sqlite3 "$DB_FILE" <<EOF
CREATE TABLE sensor_logs (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_id INTEGER NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP,
    temperature_celsius REAL NOT NULL,
    humidity_percent REAL NOT NULL,
    pressure_hpa REAL NOT NULL,
    co2_ppm INTEGER NOT NULL,
    light_lux REAL NOT NULL,
    noise_db REAL NOT NULL,
    motion_detected BOOLEAN DEFAULT 0,
    air_quality_index INTEGER NOT NULL,
    occupancy_count INTEGER DEFAULT 0,
    voltage_v REAL NOT NULL,
    power_consumption_w REAL NOT NULL,
    FOREIGN KEY (room_id) REFERENCES rooms(id)
);

-- Critical indexes for performance with large datasets
CREATE INDEX idx_sensor_logs_room_id ON sensor_logs(room_id);
CREATE INDEX idx_sensor_logs_timestamp ON sensor_logs(timestamp);
CREATE INDEX idx_sensor_logs_temperature ON sensor_logs(temperature_celsius);
CREATE INDEX idx_sensor_logs_humidity ON sensor_logs(humidity_percent);
CREATE INDEX idx_sensor_logs_co2 ON sensor_logs(co2_ppm);
CREATE INDEX idx_sensor_logs_room_temp ON sensor_logs(room_id, temperature_celsius);
CREATE INDEX idx_sensor_logs_room_time ON sensor_logs(room_id, timestamp);
CREATE INDEX idx_sensor_logs_temp_time ON sensor_logs(temperature_celsius, timestamp);
CREATE INDEX idx_sensor_logs_motion ON sensor_logs(motion_detected);
CREATE INDEX idx_sensor_logs_occupancy ON sensor_logs(occupancy_count);
EOF

echo "All tables created successfully!"
echo

# Insert sample data
echo "=== Inserting Sample Data ==="

# Generate rooms
echo "Generating $NUM_ROOMS rooms..."
buildings=("North Tower" "South Tower" "East Wing" "West Wing" "Central Hub")
room_types=("Office" "Conference Room" "Laboratory" "Storage" "Classroom" "Break Room")

for ((i=1; i<=NUM_ROOMS; i++)); do
    building=${buildings[$((RANDOM % ${#buildings[@]}))]}
    room_type=${room_types[$((RANDOM % ${#room_types[@]}))]}
    floor=$((RANDOM % 10 + 1))
    capacity=$((RANDOM % 50 + 5))
    room_number="${building:0:1}${floor}$(printf "%02d" $((RANDOM % 99 + 1)))"
    
    sqlite3 "$DB_FILE" "INSERT INTO rooms (room_number, building_name, floor_number, room_type, capacity) VALUES ('$room_number', '$building', $floor, '$room_type', $capacity);"
    
    if ((i % 10 == 0)); then
        echo "Created $i rooms..."
    fi
done

echo "All rooms created successfully!"
echo

# Generate sensor logs for each room
echo "Generating sensor logs ($LOGS_PER_ROOM per room)..."
echo "This will create $((NUM_ROOMS * LOGS_PER_ROOM)) total sensor readings..."

for ((room_id=1; room_id<=NUM_ROOMS; room_id++)); do
    echo "Generating logs for room $room_id..."
    
    # Create batch insert for better performance
    sqlite3 "$DB_FILE" <<EOF
BEGIN TRANSACTION;
$(for ((j=1; j<=LOGS_PER_ROOM; j++)); do
    # Generate random sensor data
    temp=$(echo "scale=1; $RANDOM/32767*60+10" | bc)  # 10-70°C
    humidity=$(echo "scale=1; $RANDOM/32767*80+20" | bc)  # 20-100%
    pressure=$(echo "scale=1; $RANDOM/32767*50+1000" | bc)  # 1000-1050 hPa
    co2=$((RANDOM % 1500 + 400))  # 400-1900 ppm
    light=$(echo "scale=1; $RANDOM/32767*2000" | bc)  # 0-2000 lux
    noise=$(echo "scale=1; $RANDOM/32767*80+30" | bc)  # 30-110 dB
    motion=$((RANDOM % 2))  # 0 or 1
    aqi=$((RANDOM % 300 + 1))  # 1-300
    occupancy=$((RANDOM % 20))  # 0-19 people
    voltage=$(echo "scale=2; $RANDOM/32767*50+200" | bc)  # 200-250V
    power=$(echo "scale=2; $RANDOM/32767*5000+100" | bc)  # 100-5100W
    
    # Generate timestamp (random time within last 30 days)
    days_ago=$((RANDOM % 30))
    hours=$((RANDOM % 24))
    minutes=$((RANDOM % 60))
    seconds=$((RANDOM % 60))
    timestamp=$(date -d "$days_ago days ago $hours:$minutes:$seconds" '+%Y-%m-%d %H:%M:%S')
    
    echo "INSERT INTO sensor_logs (room_id, timestamp, temperature_celsius, humidity_percent, pressure_hpa, co2_ppm, light_lux, noise_db, motion_detected, air_quality_index, occupancy_count, voltage_v, power_consumption_w) VALUES ($room_id, '$timestamp', $temp, $humidity, $pressure, $co2, $light, $noise, $motion, $aqi, $occupancy, $voltage, $power);"
done)
COMMIT;
EOF
    
    if ((room_id % 5 == 0)); then
        echo "Completed $room_id/$NUM_ROOMS rooms..."
    fi
done

echo "Sample data inserted successfully!"
echo "Total sensor readings: $((NUM_ROOMS * LOGS_PER_ROOM))"
echo

# Demonstrate SQLite3 CLI operations
echo "=== SQLite3 CLI Tutorial - Basic Operations ==="
echo

echo "1. Show all tables:"
echo "Command: sqlite3 $DB_FILE '.tables'"
sqlite3 "$DB_FILE" '.tables'
echo

echo "2. Show schema for sensor_logs table:"
echo "Command: sqlite3 $DB_FILE '.schema sensor_logs'"
sqlite3 "$DB_FILE" '.schema sensor_logs'
echo

echo "3. Show all indexes:"
echo "Command: sqlite3 $DB_FILE '.indexes'"
sqlite3 "$DB_FILE" '.indexes'
echo

echo "=== Basic SELECT Queries ==="
echo

echo "4. Count total sensor readings:"
echo "Command: sqlite3 $DB_FILE 'SELECT COUNT(*) as total_readings FROM sensor_logs;'"
sqlite3 "$DB_FILE" 'SELECT COUNT(*) as total_readings FROM sensor_logs;'
echo

echo "5. Show room summary:"
echo "Command: sqlite3 $DB_FILE 'SELECT building_name, COUNT(*) as room_count FROM rooms GROUP BY building_name;'"
sqlite3 "$DB_FILE" 'SELECT building_name, COUNT(*) as room_count FROM rooms GROUP BY building_name;'
echo

echo "=== Temperature Analysis Queries ==="
echo

echo "6. Rooms with temperature around 40°C (39-41°C range):"
echo "Command: sqlite3 $DB_FILE 'SELECT r.room_number, r.building_name, sl.temperature_celsius, sl.timestamp FROM rooms r JOIN sensor_logs sl ON r.id = sl.room_id WHERE sl.temperature_celsius BETWEEN 39.0 AND 41.0 ORDER BY sl.temperature_celsius DESC LIMIT 10;'"
sqlite3 "$DB_FILE" 'SELECT r.room_number, r.building_name, sl.temperature_celsius, sl.timestamp FROM rooms r JOIN sensor_logs sl ON r.id = sl.room_id WHERE sl.temperature_celsius BETWEEN 39.0 AND 41.0 ORDER BY sl.temperature_celsius DESC LIMIT 10;'
echo

echo "7. Average temperature by room:"
echo "Command: sqlite3 $DB_FILE 'SELECT r.room_number, r.building_name, ROUND(AVG(sl.temperature_celsius), 2) as avg_temp FROM rooms r JOIN sensor_logs sl ON r.id = sl.room_id GROUP BY r.id ORDER BY avg_temp DESC LIMIT 10;'"
sqlite3 "$DB_FILE" 'SELECT r.room_number, r.building_name, ROUND(AVG(sl.temperature_celsius), 2) as avg_temp FROM rooms r JOIN sensor_logs sl ON r.id = sl.room_id GROUP BY r.id ORDER BY avg_temp DESC LIMIT 10;'
echo

echo "8. Temperature extremes (hottest and coldest readings):"
echo "Command: sqlite3 $DB_FILE 'SELECT r.room_number, r.building_name, sl.temperature_celsius, sl.timestamp FROM rooms r JOIN sensor_logs sl ON r.id = sl.room_id WHERE sl.temperature_celsius = (SELECT MAX(temperature_celsius) FROM sensor_logs) OR sl.temperature_celsius = (SELECT MIN(temperature_celsius) FROM sensor_logs);'"
sqlite3 "$DB_FILE" 'SELECT r.room_number, r.building_name, sl.temperature_celsius, sl.timestamp FROM rooms r JOIN sensor_logs sl ON r.id = sl.room_id WHERE sl.temperature_celsius = (SELECT MAX(temperature_celsius) FROM sensor_logs) OR sl.temperature_celsius = (SELECT MIN(temperature_celsius) FROM sensor_logs);'
echo

echo "9. Rooms with high temperature variance:"
echo "Command: sqlite3 $DB_FILE 'SELECT r.room_number, r.building_name, ROUND(AVG(sl.temperature_celsius), 2) as avg_temp, ROUND(MIN(sl.temperature_celsius), 2) as min_temp, ROUND(MAX(sl.temperature_celsius), 2) as max_temp, ROUND(MAX(sl.temperature_celsius) - MIN(sl.temperature_celsius), 2) as temp_range FROM rooms r JOIN sensor_logs sl ON r.id = sl.room_id GROUP BY r.id HAVING temp_range > 30 ORDER BY temp_range DESC LIMIT 10;'"
sqlite3 "$DB_FILE" 'SELECT r.room_number, r.building_name, ROUND(AVG(sl.temperature_celsius), 2) as avg_temp, ROUND(MIN(sl.temperature_celsius), 2) as min_temp, ROUND(MAX(sl.temperature_celsius), 2) as max_temp, ROUND(MAX(sl.temperature_celsius) - MIN(sl.temperature_celsius), 2) as temp_range FROM rooms r JOIN sensor_logs sl ON r.id = sl.room_id GROUP BY r.id HAVING temp_range > 30 ORDER BY temp_range DESC LIMIT 10;'
echo

echo "=== Advanced Sensor Analysis ==="
echo

echo "10. Correlation between temperature and humidity:"
echo "Command: sqlite3 $DB_FILE 'SELECT CASE WHEN temperature_celsius < 20 THEN \"Cold\" WHEN temperature_celsius < 30 THEN \"Moderate\" WHEN temperature_celsius < 40 THEN \"Warm\" ELSE \"Hot\" END as temp_category, ROUND(AVG(humidity_percent), 2) as avg_humidity, COUNT(*) as readings FROM sensor_logs GROUP BY temp_category;'"
sqlite3 "$DB_FILE" 'SELECT CASE WHEN temperature_celsius < 20 THEN "Cold" WHEN temperature_celsius < 30 THEN "Moderate" WHEN temperature_celsius < 40 THEN "Warm" ELSE "Hot" END as temp_category, ROUND(AVG(humidity_percent), 2) as avg_humidity, COUNT(*) as readings FROM sensor_logs GROUP BY temp_category;'
echo

echo "11. Rooms with motion detected at high temperatures (>35°C):"
echo "Command: sqlite3 $DB_FILE 'SELECT r.room_number, r.building_name, COUNT(*) as high_temp_motion_events FROM rooms r JOIN sensor_logs sl ON r.id = sl.room_id WHERE sl.temperature_celsius > 35.0 AND sl.motion_detected = 1 GROUP BY r.id ORDER BY high_temp_motion_events DESC LIMIT 5;'"
sqlite3 "$DB_FILE" 'SELECT r.room_number, r.building_name, COUNT(*) as high_temp_motion_events FROM rooms r JOIN sensor_logs sl ON r.id = sl.room_id WHERE sl.temperature_celsius > 35.0 AND sl.motion_detected = 1 GROUP BY r.id ORDER BY high_temp_motion_events DESC LIMIT 5;'
echo

echo "12. Daily temperature trends:"
echo "Command: sqlite3 $DB_FILE 'SELECT DATE(timestamp) as date, ROUND(AVG(temperature_celsius), 2) as avg_temp, ROUND(MIN(temperature_celsius), 2) as min_temp, ROUND(MAX(temperature_celsius), 2) as max_temp FROM sensor_logs GROUP BY DATE(timestamp) ORDER BY date DESC LIMIT 7;'"
sqlite3 "$DB_FILE" 'SELECT DATE(timestamp) as date, ROUND(AVG(temperature_celsius), 2) as avg_temp, ROUND(MIN(temperature_celsius), 2) as min_temp, ROUND(MAX(temperature_celsius), 2) as max_temp FROM sensor_logs GROUP BY DATE(timestamp) ORDER BY date DESC LIMIT 7;'
echo

echo "=== Performance Analysis ==="
echo

echo "13. Query performance test - Temperature range query with index:"
echo "Command: sqlite3 $DB_FILE '.timer on' 'SELECT COUNT(*) FROM sensor_logs WHERE temperature_celsius BETWEEN 35.0 AND 45.0;'"
sqlite3 "$DB_FILE" '.timer on' 'SELECT COUNT(*) FROM sensor_logs WHERE temperature_celsius BETWEEN 35.0 AND 45.0;'
echo

echo "=== Useful SQLite3 CLI Commands ==="
echo
echo "Try these commands yourself:"
echo "  sqlite3 $DB_FILE                    # Enter interactive mode"
echo "  .help                               # Show all dot commands"
echo "  .mode column                        # Better formatting"
echo "  .headers on                         # Show column headers"
echo "  .timer on                           # Show query execution time"
echo "  .explain                            # Show query execution plan"
echo "  .output results.txt                 # Redirect output to file"
echo "  .read script.sql                    # Execute SQL from file"
echo "  .backup backup.db                   # Backup database"
echo "  .exit                               # Exit SQLite3"
echo

echo "=== Sample Queries for Temperature Analysis ==="
echo
echo "More queries you can try:"
echo "  # Find readings exactly at 40°C:"
echo "  sqlite3 $DB_FILE 'SELECT * FROM sensor_logs WHERE ABS(temperature_celsius - 40.0) < 0.1 LIMIT 5;'"
echo
echo "  # Temperature distribution:"
echo "  sqlite3 $DB_FILE 'SELECT ROUND(temperature_celsius) as temp, COUNT(*) as count FROM sensor_logs GROUP BY ROUND(temperature_celsius) ORDER BY temp;'"
echo
echo "  # Rooms that never exceeded 40°C:"
echo "  sqlite3 $DB_FILE 'SELECT r.room_number, MAX(sl.temperature_celsius) as max_temp FROM rooms r JOIN sensor_logs sl ON r.id = sl.room_id GROUP BY r.id HAVING max_temp < 40.0;'"
echo

echo "=== Tutorial Complete! ==="
echo "Database '$DB_FILE' has been created with:"
echo "  - $NUM_ROOMS rooms"
echo "  - $((NUM_ROOMS * LOGS_PER_ROOM)) sensor readings"
echo "  - Comprehensive indexes for query performance"
echo "You can now experiment with your own queries using:"
echo "  sqlite3 $DB_FILE"
echo