#!/bin/bash

# 🚀 Auto-Connect Script for Android Dev Environment
# Universal script to detect device, forward ports, and check SSH.

echo "🔍 Searching for Android devices..."

# Check ADB devices
DEVICES=$(adb devices | grep "device$" | awk '{print $1}')

if [ -z "$DEVICES" ]; then
    echo "❌ No device found! Please connect your Android device via USB or Wi-Fi Debugging."
    exit 1
fi

echo "✅ Device found: $DEVICES"

# Forward SSH port
echo "🔄 Forwarding port 8022..."
adb forward tcp:8022 tcp:8022

if [ $? -eq 0 ]; then
    echo "✅ Port forwarding successful (localhost:8022 -> device:8022)"
else
    echo "❌ Failed to forward port. Check ADB authorization."
    exit 1
fi

# Check SSH connection
echo "Testing SSH connection..."
nc -zv localhost 8022 2>/dev/null

if [ $? -eq 0 ]; then
    echo "✅ SSH Service is reachable!"
    echo "🚀 You can now connect using: ssh -p 8022 localhost"
else
    echo "⚠️ SSH Service not reachable on localhost:8022."
    echo "💡 Tip: Run 'sshd' in Termux on your device."
    exit 1
fi

exit 0