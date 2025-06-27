#!/usr/bin/env lua

-- Ultra-Fast SQLite3 Tutorial Script in Lua (using lsqlite3)
local sqlite3 = require("lsqlite3")

local NUM_ROOMS = 2
local LOGS_PER_ROOM = 1000
local DB_FILE = "tutorial.db"

print("=== Ultra-Fast SQLite3 Tutorial (Lua/lsqlite3) ===")
print(string.format("Creating %d rooms with %d logs each", NUM_ROOMS, LOGS_PER_ROOM))

-- Remove existing database
os.remove(DB_FILE)

-- Open in-memory database
local db = sqlite3.open(":memory:")

-- Performance settings
db:exec("PRAGMA synchronous = OFF")
db:exec("PRAGMA journal_mode = MEMORY")
db:exec("PRAGMA cache_size = 1000000")
db:exec("PRAGMA temp_store = MEMORY")

-- Create tables
db:exec([[
CREATE TABLE rooms (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    room_number TEXT UNIQUE NOT NULL,
    building_name TEXT NOT NULL,
    floor_number INTEGER NOT NULL,
    room_type TEXT NOT NULL,
    capacity INTEGER
)
]])

db:exec([[
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
    power_consumption_w REAL NOT NULL
)
]])

print("Generating data...")

-- Seed random
math.randomseed(os.time())

local buildings = {"North Tower", "South Tower", "East Wing", "West Wing", "Central Hub"}
local room_types = {"Office", "Conference Room", "Laboratory", "Storage", "Classroom", "Break Room"}

-- Start transaction
db:exec("BEGIN TRANSACTION")

-- Generate rooms
local room_stmt = db:prepare("INSERT INTO rooms (room_number, building_name, floor_number, room_type, capacity) VALUES (?,?,?,?,?)")

for i = 1, NUM_ROOMS do
    local building = buildings[math.random(#buildings)]
    local room_type = room_types[math.random(#room_types)]
    local floor = math.random(1, 10)
    local capacity = math.random(5, 54)
    local room_number = string.format("%s%d%02d", building:sub(1,1), floor, math.random(1, 99))
    
    room_stmt:bind_values(room_number, building, floor, room_type, capacity)
    room_stmt:step()
    room_stmt:reset()
end
room_stmt:finalize()

-- Generate sensor data
local sensor_stmt = db:prepare([[
INSERT INTO sensor_logs (room_id, timestamp, temperature_celsius, humidity_percent, 
pressure_hpa, co2_ppm, light_lux, noise_db, motion_detected, air_quality_index, 
occupancy_count, voltage_v, power_consumption_w) VALUES (?,?,?,?,?,?,?,?,?,?,?,?,?)
]])

local base_time = os.time()

for room_id = 1, NUM_ROOMS do
    for j = 1, LOGS_PER_ROOM do
        local temp = math.random() * 60 + 10
        local humidity = math.random() * 80 + 20
        local pressure = math.random() * 50 + 1000
        local co2 = math.random(400, 1899)
        local light = math.random() * 2000
        local noise = math.random() * 80 + 30
        local motion = math.random(2) - 1
        local aqi = math.random(1, 300)
        local occupancy = math.random(0, 19)
        local voltage = math.random() * 50 + 200
        local power = math.random() * 5000 + 100
        
        local days_ago = math.random(0, 29)
        local hours = math.random(0, 23)
        local minutes = math.random(0, 59)
        local seconds = math.random(0, 59)
        local timestamp_epoch = base_time - (days_ago * 86400) + (hours * 3600) + (minutes * 60) + seconds
        local timestamp = os.date("%Y-%m-%d %H:%M:%S", timestamp_epoch)
        
        sensor_stmt:bind_values(room_id, timestamp, 
            string.format("%.1f", temp),
            string.format("%.1f", humidity), 
            string.format("%.1f", pressure),
            co2,
            string.format("%.1f", light),
            string.format("%.1f", noise),
            motion, aqi, occupancy,
            string.format("%.2f", voltage),
            string.format("%.2f", power))
        sensor_stmt:step()
        sensor_stmt:reset()
    end
    
    print(string.format("Generated room %d data...", room_id))
end

sensor_stmt:finalize()
db:exec("COMMIT")

print("Creating indexes...")

-- Create indexes
local indexes = {
    "CREATE INDEX idx_rooms_building ON rooms(building_name)",
    "CREATE INDEX idx_rooms_floor ON rooms(floor_number)",
    "CREATE INDEX idx_rooms_type ON rooms(room_type)",
    "CREATE INDEX idx_rooms_number ON rooms(room_number)",
    "CREATE INDEX idx_sensor_logs_room_id ON sensor_logs(room_id)",
    "CREATE INDEX idx_sensor_logs_timestamp ON sensor_logs(timestamp)",
    "CREATE INDEX idx_sensor_logs_temperature ON sensor_logs(temperature_celsius)",
    "CREATE INDEX idx_sensor_logs_humidity ON sensor_logs(humidity_percent)",
    "CREATE INDEX idx_sensor_logs_co2 ON sensor_logs(co2_ppm)",
    "CREATE INDEX idx_sensor_logs_room_temp ON sensor_logs(room_id, temperature_celsius)",
    "CREATE INDEX idx_sensor_logs_room_time ON sensor_logs(room_id, timestamp)",
    "CREATE INDEX idx_sensor_logs_temp_time ON sensor_logs(temperature_celsius, timestamp)",
    "CREATE INDEX idx_sensor_logs_motion ON sensor_logs(motion_detected)",
    "CREATE INDEX idx_sensor_logs_occupancy ON sensor_logs(occupancy_count)"
}

for _, idx in ipairs(indexes) do
    db:exec(idx)
end

db:exec("ANALYZE")

print("Saving to disk...")

-- Backup to file
local file_db = sqlite3.open(DB_FILE)
db:backup(file_db)
file_db:close()
db:close()

print("Database created: " .. DB_FILE)

-- Quick verification
print("\n=== Database Stats ===")
os.execute(string.format("sqlite3 %s \"SELECT 'Rooms:', COUNT(*) FROM rooms; SELECT 'Sensor logs:', COUNT(*) FROM sensor_logs;\"", DB_FILE))

print("\n=== Performance Test ===")
os.execute(string.format("sqlite3 %s \".timer on\" \"SELECT COUNT(*) FROM sensor_logs WHERE temperature_celsius > 40;\"", DB_FILE))

print("\nUse: sqlite3 " .. DB_FILE)
