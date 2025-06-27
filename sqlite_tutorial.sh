#!/bin/bash

# Ultra-Fast SQLite3 Tutorial Script
# In-memory database with final dump to disk

NUM_ROOMS=2
LOGS_PER_ROOM=1000
DB_FILE="tutorial.db"

echo "=== Ultra-Fast SQLite3 Tutorial ==="
echo "Creating $NUM_ROOMS rooms with $LOGS_PER_ROOM logs each"

rm -f "$DB_FILE"

echo "Building database in memory..."

# Create everything in memory, then dump to disk
sqlite3 ":memory:" <<EOF | sqlite3 "$DB_FILE"
PRAGMA synchronous = OFF;
PRAGMA cache_size = 1000000;
PRAGMA temp_store = MEMORY;

CREATE TABLE rooms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_number TEXT UNIQUE NOT NULL,
    building_name TEXT NOT NULL,
    floor_number INTEGER NOT NULL,
    room_type TEXT NOT NULL,
    capacity INTEGER
);

CREATE TABLE sensor_logs (
    room_id INTEGER NOT NULL,
    timestamp DATETIME NOT NULL,
    temperature_celsius REAL NOT NULL,
    humidity_percent REAL NOT NULL,
    pressure_hpa REAL NOT NULL,
    co2_ppm INTEGER NOT NULL,
    light_lux REAL NOT NULL,
    noise_db REAL NOT NULL,
    motion_detected BOOLEAN NOT NULL,
    air_quality_index INTEGER NOT NULL,
    occupancy_count INTEGER NOT NULL,
    voltage_v REAL NOT NULL,
    power_consumption_w REAL NOT NULL,
    FOREIGN KEY (room_id) REFERENCES rooms(id)
);

$(
# Generate rooms
buildings=("North Tower" "South Tower" "East Wing" "West Wing" "Central Hub")
room_types=("Office" "Conference Room" "Laboratory" "Storage" "Classroom" "Break Room")

echo "BEGIN TRANSACTION;"
for ((i = 1; i <= NUM_ROOMS; i++)); do
    building=${buildings[$((RANDOM % ${#buildings[@]}))]}
    room_type=${room_types[$((RANDOM % ${#room_types[@]}))]}
    floor=$((RANDOM % 10 + 1))
    capacity=$((RANDOM % 50 + 5))
    room_number="${building:0:1}${floor}$(printf "%02d" $((RANDOM % 99 + 1)))"
    echo "INSERT INTO rooms (room_number, building_name, floor_number, room_type, capacity) VALUES ('$room_number', '$building', $floor, '$room_type', $capacity);"
done

# Generate sensor data with bulk inserts (500 rows per statement)
batch_size=500
total_logs=$((NUM_ROOMS * LOGS_PER_ROOM))
current=0

for ((room_id = 1; room_id <= NUM_ROOMS; room_id++)); do
    for ((batch_start = 1; batch_start <= LOGS_PER_ROOM; batch_start += batch_size)); do
        batch_end=$((batch_start + batch_size - 1))
        if [ $batch_end -gt $LOGS_PER_ROOM ]; then
            batch_end=$LOGS_PER_ROOM
        fi
        
        echo "INSERT INTO sensor_logs (room_id, timestamp, temperature_celsius, humidity_percent, pressure_hpa, co2_ppm, light_lux, noise_db, motion_detected, air_quality_index, occupancy_count, voltage_v, power_consumption_w) VALUES"
        
        for ((j = batch_start; j <= batch_end; j++)); do
            temp=$(awk "BEGIN {printf \"%.1f\", rand()*60+10}")
            humidity=$(awk "BEGIN {printf \"%.1f\", rand()*80+20}")
            pressure=$(awk "BEGIN {printf \"%.1f\", rand()*50+1000}")
            co2=$((RANDOM % 1500 + 400))
            light=$(awk "BEGIN {printf \"%.1f\", rand()*2000}")
            noise=$(awk "BEGIN {printf \"%.1f\", rand()*80+30}")
            motion=$((RANDOM % 2))
            aqi=$((RANDOM % 300 + 1))
            occupancy=$((RANDOM % 20))
            voltage=$(awk "BEGIN {printf \"%.2f\", rand()*50+200}")
            power=$(awk "BEGIN {printf \"%.2f\", rand()*5000+100}")
            
            days_ago=$((RANDOM % 30))
            hours=$((RANDOM % 24))
            minutes=$((RANDOM % 60))
            seconds=$((RANDOM % 60))
            timestamp=$(date -d "$days_ago days ago $hours:$minutes:$seconds" '+%Y-%m-%d %H:%M:%S')
            
            if [ $j -eq $batch_end ]; then
                echo "($room_id, '$timestamp', $temp, $humidity, $pressure, $co2, $light, $noise, $motion, $aqi, $occupancy, $voltage, $power);"
            else
                echo "($room_id, '$timestamp', $temp, $humidity, $pressure, $co2, $light, $noise, $motion, $aqi, $occupancy, $voltage, $power),"
            fi
            
            current=$((current + 1))
        done
    done
    echo "-- Generated room $room_id data" >&2
done

echo "COMMIT;"
)

-- Create indexes
CREATE INDEX idx_rooms_building ON rooms(building_name);
CREATE INDEX idx_rooms_floor ON rooms(floor_number);
CREATE INDEX idx_rooms_type ON rooms(room_type);
CREATE INDEX idx_rooms_number ON rooms(room_number);
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

ANALYZE;

.dump
EOF

echo "Database created: $DB_FILE"

# Quick verification
echo "=== Database Stats ==="
sqlite3 "$DB_FILE" "SELECT 'Rooms:', COUNT(*) FROM rooms; SELECT 'Sensor logs:', COUNT(*) FROM sensor_logs;"

echo "=== Sample Queries ==="

echo "Room temperature averages:"
sqlite3 "$DB_FILE" -header -column "
SELECT r.room_number, r.building_name, 
       ROUND(AVG(sl.temperature_celsius), 2) as avg_temp,
       COUNT(*) as readings
FROM rooms r 
JOIN sensor_logs sl ON r.id = sl.room_id 
GROUP BY r.id 
ORDER BY avg_temp DESC;"

echo "Temperature extremes:"
sqlite3 "$DB_FILE" -header -column "
SELECT r.room_number, sl.temperature_celsius, sl.timestamp
FROM rooms r 
JOIN sensor_logs sl ON r.id = sl.room_id 
WHERE sl.temperature_celsius IN (
    (SELECT MAX(temperature_celsius) FROM sensor_logs),
    (SELECT MIN(temperature_celsius) FROM sensor_logs)
);"

echo "=== Performance Test ==="
sqlite3 "$DB_FILE" ".timer on" "
SELECT COUNT(*) as hot_readings 
FROM sensor_logs 
WHERE temperature_celsius > 40;"

echo "Use: sqlite3 $DB_FILE"
