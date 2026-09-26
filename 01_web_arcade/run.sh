#!/bin/bash
# Simple one-command script to launch the web game
cd "$(dirname "$0")"
echo "🎮 Starting Cyber Survivor Web Game..."
echo "🌐 Opening http://localhost:8080 in your default browser..."
python3 -m http.server 8080 &
SERVER_PID=$!
sleep 1
open http://localhost:8080
echo "Server running (PID: $SERVER_PID). Press Ctrl+C to stop."
wait $SERVER_PID
