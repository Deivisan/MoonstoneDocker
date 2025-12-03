#!/bin/bash

# 🔄 Sync Workspace Script
# Synchronizes configurations and files between PC and Android (Termux).

DEVICE_USER="u0_a575" # Default Termux user, can be overridden
DEVICE_HOST="localhost"
DEVICE_PORT="8022"

echo "🔄 Starting Workspace Synchronization..."

# Ensure connection
./Scripts/auto-connect.sh > /dev/null
if [ $? -ne 0 ]; then
    echo "❌ Device not connected. Aborting sync."
    exit 1
fi

# 1. Pull Configs (Device -> PC)
echo "📥 Pulling configurations from device..."
adb shell su -c "cat /data/data/com.termux/files/home/.zshrc" > Termux/zshrc
adb shell su -c "cat /data/data/com.termux/files/home/.config/starship.toml" > Termux/starship.toml
echo "✅ Configs pulled to Termux/ folder."

# 2. Sync Agents (PC -> Device)
echo "📤 Syncing 'Agentes' folder to device..."
# We use adb push for simplicity, or rsync if available. Using adb push for universality.
adb push Agentes/ /data/local/tmp/Agentes_Sync 2>/dev/null
adb shell su -c "cp -r /data/local/tmp/Agentes_Sync/* /data/data/com.termux/files/home/Agentes/"
adb shell su -c "rm -rf /data/local/tmp/Agentes_Sync"
echo "✅ Agents synced."

# 3. Sync Scripts (PC -> Device)
echo "📤 Syncing 'Scripts' folder to device..."
adb push Scripts/ /data/local/tmp/Scripts_Sync 2>/dev/null
adb shell su -c "mkdir -p /data/data/com.termux/files/home/scripts"
adb shell su -c "cp -r /data/local/tmp/Scripts_Sync/* /data/data/com.termux/files/home/scripts/"
adb shell su -c "chmod +x /data/data/com.termux/files/home/scripts/*.sh"
adb shell su -c "rm -rf /data/local/tmp/Scripts_Sync"
echo "✅ Scripts synced."

echo "✨ Synchronization Complete!"