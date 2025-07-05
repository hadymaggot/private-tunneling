#!/bin/bash

# Test script for network monitoring functionality
echo "🧪 Testing network monitoring features..."
echo

# Test 1: Check if bc is available (needed for floating point calculations)
if ! command -v bc &> /dev/null; then
    echo "⚠️  bc (calculator) not found - installing..."
    if command -v apt-get &> /dev/null; then
        sudo apt-get update && sudo apt-get install -y bc
    elif command -v yum &> /dev/null; then
        sudo yum install -y bc
    else
        echo "❌ Please install 'bc' package manually"
        exit 1
    fi
fi

# Test 2: Test ASCII chart generation
echo "🔍 Testing ASCII chart generation..."

# Source the functions from tunnel.sh
source tunnel.sh 2>/dev/null || {
    echo "❌ Cannot source tunnel.sh functions"
    exit 1
}

# Test data for chart
test_data=(10 25 45 30 60 40 80 35 70 55 90 45 75 60 85)

echo "📊 Sample ASCII chart with test data:"
create_ascii_chart "${test_data[@]}"

echo
echo "✅ Network monitoring test completed!"
echo
echo "📝 Available features:"
echo "   - Real-time data transfer rate monitoring"
echo "   - ASCII chart visualization"
echo "   - Network interface auto-detection"
echo "   - Human-readable byte formatting"
echo
echo "🚀 Usage:"
echo "   ./tunnel.sh -m                    # Enable monitoring via command line"
echo "   ./tunnel.sh                       # Interactive prompt for monitoring"
echo "   Edit .env: ENABLE_MONITORING=true # Auto-enable via .env file"
