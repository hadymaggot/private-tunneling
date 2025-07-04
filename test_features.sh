#!/bin/bash

# Test script for SSH tunneling tool features
# This script demonstrates the new features without requiring actual SSH connections

echo "🧪 Testing SSH Tunneling Tool Features"
echo "========================================"
echo

echo "1. Testing help command..."
./tunnel.sh --help
echo

echo "2. Testing parameter validation (invalid port)..."
./tunnel.sh -u testuser -p testpass -h example.com -l 99999 -r 3306 2>&1
echo

echo "3. Testing missing parameters..."
./tunnel.sh -u testuser -h example.com -l 8080 -r 3306 2>&1
echo

echo "4. Testing invalid port format..."
./tunnel.sh -u testuser -p testpass -h example.com -l abc -r 3306 2>&1
echo

echo "5. Testing port availability check..."
# This will show the warning if netstat/ss is not available
./tunnel.sh -u testuser -p testpass -h example.com -l 8080 -r 3306 2>&1 | head -10
echo

echo "✅ Feature testing completed!"
echo "💡 To test actual connections, use valid SSH credentials and hostnames"