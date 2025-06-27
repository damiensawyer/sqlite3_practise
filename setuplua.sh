#!/bin/bash

# Setup Lua SQLite environment
set -e

echo "=== Setting up Lua SQLite environment ==="

# Check if luarocks is installed
if ! command -v luarocks &>/dev/null; then
  echo "Installing luarocks..."
  if command -v brew &>/dev/null; then
    brew install luarocks
  elif command -v apt-get &>/dev/null; then
    sudo apt-get update
    sudo apt-get install -y luarocks libsqlite3-dev
  elif command -v yum &>/dev/null; then
    sudo yum install -y luarocks sqlite-devel
  else
    echo "Please install luarocks manually"
    exit 1
  fi
fi

# Install SQLite Lua binding
echo "Installing SQLite Lua binding..."
if ! luarocks list | grep -q "lsqlite3"; then
  if luarocks install lsqlite3; then
    echo "lsqlite3 installed successfully"
  elif luarocks install --local lsqlite3; then
    echo "lsqlite3 installed locally"
    echo "You may need to set:"
    echo "export LUA_PATH=\"\$HOME/.luarocks/share/lua/5.4/?.lua;\$HOME/.luarocks/share/lua/5.4/?/init.lua;\$LUA_PATH\""
    echo "export LUA_CPATH=\"\$HOME/.luarocks/lib/lua/5.4/?.so;\$LUA_CPATH\""
  else
    echo "Failed to install lsqlite3"
    exit 1
  fi
else
  echo "lsqlite3 already installed"
fi

echo "=== Setup complete ==="
echo "Run: lua lua_sqlite_tutorial.lua"
