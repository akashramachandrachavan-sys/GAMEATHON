#!/bin/bash
cd "$(dirname "$0")"
echo "🤖 Opening Godot 4 Editor for Gameathon2D..."
godot -e --path . &
