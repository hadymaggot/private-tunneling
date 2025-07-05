#!/bin/bash

# Simple test for ASCII chart functionality
echo "🧪 Testing ASCII Chart Generation..."

# Color codes
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Chart configuration
MAX_CHART_WIDTH=50
MAX_CHART_HEIGHT=10

# Simple chart function
create_test_chart() {
    local data_string="$*"
    local -a data
    read -a data <<< "$data_string"
    
    local max_value=0
    
    # Find max value
    for value in "${data[@]}"; do
        if [ $value -gt $max_value ]; then
            max_value=$value
        fi
    done
    
    [ $max_value -eq 0 ] && max_value=1
    
    echo
    print_colored $CYAN "┌────────────────────────────────────────────────────────┐"
    print_colored $CYAN "│                    📊 Data Transfer Rate                │"
    print_colored $CYAN "├────────────────────────────────────────────────────────┤"
    
    # Create chart (simplified)
    for ((i = MAX_CHART_HEIGHT; i >= 1; i--)); do
        local line=""
        local threshold=$((max_value * i / MAX_CHART_HEIGHT))
        
        for value in "${data[@]}"; do
            if [ $value -ge $threshold ]; then
                line="${line}█"
            else
                line="${line} "
            fi
        done
        printf "${CYAN}│${NC}${GREEN}%-${MAX_CHART_WIDTH}s${NC}${CYAN}│${NC}\n" "$line"
    done
    
    print_colored $CYAN "└────────────────────────────────────────────────────────┘"
    
    # Get last value
    local last_value=0
    for value in "${data[@]}"; do
        last_value=$value
    done
    
    print_colored $YELLOW "  Max: $max_value units   Latest: $last_value units"
}

# Test with sample data
echo "Testing with sample network transfer rates..."
sample_data="10 25 45 30 60 40 80 35 70 55 90 45 75 60 85 95 80 65 70 75"

create_test_chart $sample_data

echo
echo "✅ Chart generation test completed!"
echo
echo "📋 Features implemented:"
echo "   - Real-time network monitoring"
echo "   - ASCII chart visualization"
echo "   - Transfer rate calculation"
echo "   - Auto-scaling chart"
echo "   - Interactive and automatic modes"
