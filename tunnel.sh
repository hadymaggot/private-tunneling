#!/bin/bash

# Universal SSH Tunneling Script
# Compatible with Windows (Git Bash/WSL/PowerShell) and Linux (Ubuntu)
# Author: Private Tunneling Project
# License: MIT

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Default values
USERNAME=""
PASSWORD=""
HOST=""
LOCAL_PORT=""
REMOTE_PORT=""
VERBOSE=false
TUNNEL_PID=""
TUNNEL_START_TIME=""
ENABLE_MONITORING=false

# Function to load environment variables from .env file
load_env_file() {
    local env_file="${1:-.env}"
    
    if [ -f "$env_file" ]; then
        print_colored $BLUE "📄 Loading configuration from $env_file"
        
        # Read .env file and export variables
        while IFS='=' read -r key value; do
            # Skip empty lines and comments
            [[ -z "$key" || "$key" =~ ^[[:space:]]*# ]] && continue
            
            # Remove leading/trailing whitespace and quotes
            key=$(echo "$key" | xargs)
            value=$(echo "$value" | xargs | sed 's/^["'\'']//' | sed 's/["'\'']$//')
            
            # Set variables based on .env content
            case "$key" in
                SSH_USERNAME|USERNAME)
                    [ -z "$USERNAME" ] && USERNAME="$value"
                    ;;
                SSH_PASSWORD|PASSWORD)
                    [ -z "$PASSWORD" ] && PASSWORD="$value"
                    ;;
                SSH_HOST|HOST)
                    [ -z "$HOST" ] && HOST="$value"
                    ;;
                LOCAL_PORT)
                    [ -z "$LOCAL_PORT" ] && LOCAL_PORT="$value"
                    ;;
                REMOTE_PORT)
                    [ -z "$REMOTE_PORT" ] && REMOTE_PORT="$value"
                    ;;
                VERBOSE)
                    [ "$VERBOSE" = false ] && [ "$value" = "true" ] && VERBOSE=true
                    ;;
                ENABLE_MONITORING)
                    [ "$ENABLE_MONITORING" = false ] && [ "$value" = "true" ] && ENABLE_MONITORING=true
                    ;;
            esac
        done < "$env_file"
        
        print_colored $GREEN "✅ Configuration loaded successfully"
        echo
    else
        print_colored $YELLOW "⚠️  No .env file found at $env_file"
        echo
    fi
}

# Function to print colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
}

# Modern spinner animation with square box style
show_spinner() {
    local message=$1
    local frames=('▉   ' ' ▉  ' '  ▉ ' '   ▉' '  ▉ ' ' ▉  ')
    local frame_count=${#frames[@]}
    local i=0
    
    printf "${BLUE}${message}${NC} "
    
    # Simple animation loop for connection attempt
    local max_iterations=30  # 6 seconds at 0.2s intervals
    local iterations=0
    
    while [ $iterations -lt $max_iterations ]; do
        printf "\r${BLUE}${message}${NC} ${GREEN}${frames[i]}${NC}"
        i=$(((i + 1) % frame_count))
        iterations=$((iterations + 1))
        sleep 0.2
    done
    
    printf "\r${BLUE}${message}${NC} ${GREEN}✓${NC}\n"
}

# Function to get local IP address (cross-platform)
get_local_ip() {
    local ip=""
    
    # Try different methods to get local IP
    if command -v ip &> /dev/null; then
        ip=$(ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' 2>/dev/null)
    elif command -v hostname &> /dev/null; then
        ip=$(hostname -I 2>/dev/null | awk '{print $1}')
        if [ -z "$ip" ]; then
            ip=$(hostname -i 2>/dev/null | awk '{print $1}')
        fi
    fi
    
    # Fallback methods
    if [ -z "$ip" ] && command -v ifconfig &> /dev/null; then
        ip=$(ifconfig 2>/dev/null | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0.1' | head -1)
    fi
    
    # Final fallback
    if [ -z "$ip" ]; then
        ip="127.0.0.1"
    fi
    
    echo "$ip"
}

# Function to format uptime
format_uptime() {
    local seconds=$1
    local days=$((seconds / 86400))
    local hours=$(((seconds % 86400) / 3600))
    local minutes=$(((seconds % 3600) / 60))
    local secs=$((seconds % 60))
    
    if [ $days -gt 0 ]; then
        printf "%dd %02dh %02dm %02ds" $days $hours $minutes $secs
    elif [ $hours -gt 0 ]; then
        printf "%02dh %02dm %02ds" $hours $minutes $secs
    elif [ $minutes -gt 0 ]; then
        printf "%02dm %02ds" $minutes $secs
    else
        printf "%02ds" $secs
    fi
}

# Function to show tunnel status
show_tunnel_status() {
    if [ -n "$TUNNEL_START_TIME" ]; then
        local current_time=$(date +%s)
        local uptime=$((current_time - $TUNNEL_START_TIME))
        local local_ip=$(get_local_ip)
        
        echo
        print_colored $GREEN "═══════════════════════════════════════════════════════════════════"
        print_colored $GREEN "                      🚇 SSH TUNNEL STATUS"
        print_colored $GREEN "═══════════════════════════════════════════════════════════════════"
        printf "${GREEN}${NC} ${BLUE}Status:${NC}      ${GREEN}✓ Active${NC}%*s${GREEN}${NC}\n" $(($BOX_WIDTH - 19)) ""
        printf "${GREEN}${NC} ${BLUE}Local IP:${NC}    ${YELLOW}%-20s${NC}%*s${GREEN}${NC}\n" "$local_ip" $(($BOX_WIDTH - 31)) ""
        printf "${GREEN}${NC} ${BLUE}Local Port:${NC}  ${YELLOW}%-20s${NC}%*s${GREEN}${NC}\n" "$LOCAL_PORT" $(($BOX_WIDTH - 33)) ""
        printf "${GREEN}${NC} ${BLUE}Remote:${NC}      ${YELLOW}%-20s:%-10s${NC}%*s${GREEN}${NC}\n" "$HOST" "$REMOTE_PORT" $(($BOX_WIDTH - 42)) ""
        printf "${GREEN}${NC} ${BLUE}Uptime:${NC}      ${CYAN}%-20s${NC}%*s${GREEN}${NC}\n" "$(format_uptime $uptime)" $(($BOX_WIDTH - 29)) ""
        printf "${GREEN}${NC} ${BLUE}Connect to:${NC}  ${GREEN}localhost:$LOCAL_PORT${NC}%*s${GREEN}${NC}\n" $(($BOX_WIDTH - 25 - ${#LOCAL_PORT})) ""
        print_colored $GREEN "═══════════════════════════════════════════════════════════════════"
        echo
        print_colored $YELLOW "💡 Monitor traffic: netstat -an | grep :$LOCAL_PORT"
        print_colored $YELLOW "💡 Check connections: ss -tuln | grep :$LOCAL_PORT"
        echo
    fi
}

# Function to print usage information
usage() {
    cat << EOF
Universal SSH Tunneling Script

Usage: $0 [OPTIONS]
   or: $0 -u USERNAME -p PASSWORD -h HOST -l LOCAL_PORT -r REMOTE_PORT [OPTIONS]

Configuration Methods:
  1. Using .env file (recommended):
     - Copy .env.example to .env
     - Edit .env with your credentials
     - Run: $0

  2. Using command line parameters:
     - Provide all required parameters via command line

Required Parameters (if not using .env):
  -u USERNAME     SSH username
  -p PASSWORD     SSH password (use SSH keys for better security)
  -h HOST         Remote SSH host (IP address or hostname)
  -l LOCAL_PORT   Local port to bind tunnel to
  -r REMOTE_PORT  Remote port to tunnel to

Optional Parameters:
  -v              Verbose mode
  -m              Enable real-time network monitoring with chart
  --help          Show this help message

Examples:
  # Using .env file
  cp .env.example .env
  # Edit .env with your settings
  $0

  # Using command line parameters
  $0 -u user -p mypassword -h example.com -l 8080 -r 3306
  $0 -u admin -p secret123 -h 192.168.1.100 -l 5432 -r 5432 -v
  $0 -u user -p pass -h host.com -l 8080 -r 3306 -m  # with monitoring

.env File Format:
  SSH_USERNAME=your_username
  SSH_PASSWORD=your_password
  SSH_HOST=your_host
  LOCAL_PORT=8080
  REMOTE_PORT=3306
  VERBOSE=false
  ENABLE_MONITORING=false

Security Note:
  Using SSH keys is much more secure than passwords. Consider setting up
  key-based authentication instead of password authentication.

EOF
}

# Function to check if sshpass is installed
check_sshpass() {
    if ! command -v sshpass &> /dev/null; then
        print_colored $RED "Error: sshpass is not installed!"
        echo
        print_colored $YELLOW "To install sshpass:"
        echo
        print_colored $BLUE "Ubuntu/Debian:"
        echo "  sudo apt-get update && sudo apt-get install sshpass"
        echo
        print_colored $BLUE "CentOS/RHEL/Fedora:"
        echo "  sudo yum install sshpass  # or sudo dnf install sshpass"
        echo
        print_colored $BLUE "macOS (with Homebrew):"
        echo "  brew install sshpass"
        echo
        print_colored $BLUE "Windows (Git Bash):"
        echo "  # Download sshpass binary for Windows"
        echo "  # Or use WSL with Ubuntu and install via apt-get"
        echo
        print_colored $BLUE "Windows (WSL):"
        echo "  sudo apt-get update && sudo apt-get install sshpass"
        echo
        exit 1
    fi
}

# Function to validate port numbers
validate_port() {
    local port=$1
    local port_name=$2
    
    if ! [[ "$port" =~ ^[0-9]+$ ]] || [ "$port" -lt 1 ] || [ "$port" -gt 65535 ]; then
        print_colored $RED "Error: Invalid $port_name port: $port"
        print_colored $RED "Port must be a number between 1 and 65535"
        exit 1
    fi
}

# Function to check if local port is available
check_local_port() {
    local port=$1
    
    # Check if port is in use (cross-platform approach)
    if command -v netstat &> /dev/null; then
        if netstat -tuln 2>/dev/null | grep -q ":$port "; then
            print_colored $RED "Error: Local port $port is already in use"
            exit 1
        fi
    elif command -v ss &> /dev/null; then
        if ss -tuln 2>/dev/null | grep -q ":$port "; then
            print_colored $RED "Error: Local port $port is already in use"
            exit 1
        fi
    else
        print_colored $YELLOW "Warning: Cannot check if port $port is available (netstat/ss not found)"
    fi
}

# Function to create SSH tunnel
create_tunnel() {
    print_colored $MAGENTA "═══════════════════════════════════════════════════════════════════════"
    print_colored $MAGENTA "                      🚇 SSH TUNNEL SETUP"
    print_colored $MAGENTA "═══════════════════════════════════════════════════════════════════════"
    echo
    print_colored $BLUE "📡 Tunnel Configuration:"
    print_colored $CYAN "   Local:  localhost:$LOCAL_PORT"
    print_colored $CYAN "   Remote: $HOST:$REMOTE_PORT"
    print_colored $CYAN "   User:   $USERNAME"
    
    # Show configuration source
    if [ -f ".env" ]; then
        print_colored $GREEN "   Source: .env file"
    else
        print_colored $YELLOW "   Source: command line parameters"
    fi
    echo
    
    local ssh_options="-N -L $LOCAL_PORT:localhost:$REMOTE_PORT"
    
    if [ "$VERBOSE" = true ]; then
        ssh_options="$ssh_options -v"
        print_colored $YELLOW "🔍 Running in verbose mode..."
    fi
    
    # Add options for better compatibility
    ssh_options="$ssh_options -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
    
    # Show connection progress with spinner
    show_spinner "⏳ Connecting to $HOST"
    
    # Create the tunnel in background and capture PID
    if [ "$VERBOSE" = true ]; then
        sshpass -p "$PASSWORD" ssh $ssh_options "$USERNAME@$HOST" &
    else
        sshpass -p "$PASSWORD" ssh $ssh_options "$USERNAME@$HOST" 2>/dev/null &
    fi
    
    TUNNEL_PID=$!
    
    # Give it a moment to establish and check if successful
    sleep 1
    
    # Check if tunnel is still running (successful connection)
    if kill -0 $TUNNEL_PID 2>/dev/null; then
        TUNNEL_START_TIME=$(date +%s)
        print_colored $GREEN "✅ SSH tunnel established successfully!"
        
        # Show status
        show_tunnel_status
        
        print_colored $GREEN "🎯 Tunnel is now active. Press Ctrl+C to stop."
        print_colored $BLUE "🔗 Connect your applications to localhost:$LOCAL_PORT"
        echo
        
        # Check if monitoring should be enabled
        if [ "$ENABLE_MONITORING" = true ]; then
            print_colored $GREEN "🚀 Starting real-time network monitoring..."
            sleep 2
            monitor_network_traffic
        else
            # Ask user if they want real-time monitoring
            print_colored $YELLOW "🔍 Enable real-time network monitoring with chart? (y/N): "
            read -t 10 -n 1 enable_monitoring
            echo
            
            if [[ "$enable_monitoring" =~ ^[Yy]$ ]]; then
                print_colored $GREEN "🚀 Starting real-time network monitoring..."
                sleep 2
                monitor_network_traffic
            else
                print_colored $BLUE "📊 Basic monitoring mode (no real-time chart)"
                echo
                
                # Keep the tunnel alive and show periodic status
                local last_status_time=$TUNNEL_START_TIME
                while kill -0 $TUNNEL_PID 2>/dev/null; do
                    sleep 5
                    current_time=$(date +%s)
                    # Update status every 30 seconds
                    if [ $((current_time - last_status_time)) -ge 30 ]; then
                        printf "\r${BLUE}⏱️  Tunnel uptime: ${CYAN}$(format_uptime $((current_time - TUNNEL_START_TIME)))${NC}               "
                        last_status_time=$current_time
                    fi
                done
            fi
        fi
    else
        print_colored $RED "❌ Failed to establish SSH tunnel!"
        print_colored $YELLOW "💡 Check your credentials and network connectivity"
        exit 1
    fi
}

# Network monitoring variables
PREV_RX_BYTES=0
PREV_TX_BYTES=0
PREV_TIME=0
CHART_HISTORY=()
MAX_CHART_WIDTH=50
MAX_CHART_HEIGHT=10

# Function to get network interface for monitoring
get_network_interface() {
    local interface=""
    
    # Try to find the primary network interface
    if command -v ip &> /dev/null; then
        interface=$(ip route | grep default | awk '{print $5}' | head -1)
    elif command -v route &> /dev/null; then
        interface=$(route -n | grep '^0.0.0.0' | awk '{print $8}' | head -1)
    fi
    
    # Fallback to common interface names
    if [ -z "$interface" ]; then
        for iface in eth0 wlan0 en0 enp0s3 ens33; do
            if [ -d "/sys/class/net/$iface" ]; then
                interface=$iface
                break
            fi
        done
    fi
    
    echo "$interface"
}

# Function to get network statistics for an interface
get_network_stats() {
    local interface=$1
    local rx_bytes=0
    local tx_bytes=0
    
    if [ -f "/sys/class/net/$interface/statistics/rx_bytes" ]; then
        rx_bytes=$(cat "/sys/class/net/$interface/statistics/rx_bytes" 2>/dev/null || echo 0)
        tx_bytes=$(cat "/sys/class/net/$interface/statistics/tx_bytes" 2>/dev/null || echo 0)
    elif command -v ifconfig &> /dev/null; then
        local stats=$(ifconfig "$interface" 2>/dev/null)
        rx_bytes=$(echo "$stats" | grep -oE "RX.*bytes:?[0-9]+" | grep -oE "[0-9]+" | head -1)
        tx_bytes=$(echo "$stats" | grep -oE "TX.*bytes:?[0-9]+" | grep -oE "[0-9]+" | head -1)
        rx_bytes=${rx_bytes:-0}
        tx_bytes=${tx_bytes:-0}
    fi
    
    echo "$rx_bytes $tx_bytes"
}

# Function to format bytes to human readable format
format_bytes() {
    local bytes=$1
    local units=("B" "KB" "MB" "GB" "TB")
    local unit=0
    local size=$bytes
    
    while [ $size -gt 1024 ] && [ $unit -lt 4 ]; do
        size=$((size / 1024))
        unit=$((unit + 1))
    done
    
    printf "%.1f %s" $size ${units[$unit]}
}

# Function to format rate to human readable format
format_rate() {
    local rate=$1
    
    # Handle case where bc is not available
    if command -v bc &> /dev/null; then
        if [ $rate -gt 1048576 ]; then  # > 1MB/s
            printf "%.1f MB/s" $(echo "scale=1; $rate / 1048576" | bc -l 2>/dev/null || echo "0")
        elif [ $rate -gt 1024 ]; then   # > 1KB/s
            printf "%.1f KB/s" $(echo "scale=1; $rate / 1024" | bc -l 2>/dev/null || echo "0")
        else
            printf "%d B/s" $rate
        fi
    else
        # Fallback without bc - use integer division
        if [ $rate -gt 1048576 ]; then  # > 1MB/s
            local mb=$((rate / 1048576))
            printf "%d MB/s" $mb
        elif [ $rate -gt 1024 ]; then   # > 1KB/s
            local kb=$((rate / 1024))
            printf "%d KB/s" $kb
        else
            printf "%d B/s" $rate
        fi
    fi
}

# Function to create ASCII chart
create_ascii_chart() {
    local data_string="$*"
    local -a data
    
    # Convert string to array (bash 3+ compatible)
    read -a data <<< "$data_string"
    
    local max_value=0
    local chart_lines=()
    
    # Find maximum value for scaling
    for value in "${data[@]}"; do
        if [ $value -gt $max_value ]; then
            max_value=$value
        fi
    done
    
    # If max_value is 0, set it to 1 to avoid division by zero
    [ $max_value -eq 0 ] && max_value=1
    
    # Create chart lines
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
        chart_lines+=("$line")
    done
    
    # Print chart
    echo
    print_colored $CYAN "────────────────────────────────────────────────────"
    print_colored $CYAN "            📊 Data Transfer Rate"
    print_colored $CYAN "────────────────────────────────────────────────────"
    
    for line in "${chart_lines[@]}"; do
        printf "${CYAN}│${NC}${GREEN}%-${MAX_CHART_WIDTH}s${NC}${CYAN}${NC}\n" "$line"
    done
    
    print_colored $CYAN "────────────────────────────────────────────────────"
    
    # Get last element (more compatible way)
    local last_value=0
    for value in "${data[@]}"; do
        last_value=$value
    done
    
    if [ $max_value -gt 0 ]; then
        print_colored $YELLOW "  Max: $(format_rate $max_value)   Latest: $(format_rate $last_value)"
    fi
}

# Function to monitor network traffic in real-time
monitor_network_traffic() {
    local interface=$(get_network_interface)
    
    if [ -z "$interface" ]; then
        print_colored $YELLOW "⚠️  Cannot detect network interface for monitoring"
        return
    fi
    
    print_colored $BLUE "📡 Monitoring interface: $interface"
    
    while kill -0 $TUNNEL_PID 2>/dev/null; do
        local current_time=$(date +%s)
        local stats=$(get_network_stats "$interface")
        local rx_bytes=$(echo $stats | awk '{print $1}')
        local tx_bytes=$(echo $stats | awk '{print $2}')
        
        if [ $PREV_TIME -ne 0 ]; then
            local time_diff=$((current_time - PREV_TIME))
            if [ $time_diff -gt 0 ]; then
                local rx_rate=$(((rx_bytes - PREV_RX_BYTES) / time_diff))
                local tx_rate=$(((tx_bytes - PREV_TX_BYTES) / time_diff))
                local total_rate=$((rx_rate + tx_rate))
                
                # Add to chart history (keep last MAX_CHART_WIDTH points)
                CHART_HISTORY+=($total_rate)
                
                # Keep array size manageable
                local history_count=${#CHART_HISTORY[@]}
                if [ $history_count -gt $MAX_CHART_WIDTH ]; then
                    # Remove first element (shift array left)
                    local new_history=()
                    for ((i=1; i<history_count; i++)); do
                        new_history+=(${CHART_HISTORY[$i]})
                    done
                    CHART_HISTORY=("${new_history[@]}")
                fi
                
                # Clear screen and show updated chart every 2 seconds
                if [ $((current_time % 2)) -eq 0 ]; then
                    clear
                    show_tunnel_status
                    
                    # Show current rates
                    print_colored $GREEN "📈 Current Transfer Rates:"
                    printf "   ${BLUE}Download:${NC} ${GREEN}%-15s${NC}   ${BLUE}Upload:${NC} ${GREEN}%-15s${NC}\n" \
                           "$(format_rate $rx_rate)" "$(format_rate $tx_rate)"
                    printf "   ${BLUE}Total:${NC}    ${GREEN}%-15s${NC}\n" "$(format_rate $total_rate)"
                    
                    # Show chart if we have enough data
                    if [ ${#CHART_HISTORY[@]} -gt 5 ]; then
                        create_ascii_chart "${CHART_HISTORY[@]}"
                    fi
                    
                    print_colored $CYAN "⏱️  Press Ctrl+C to stop monitoring"
                fi
            fi
        fi
        
        PREV_RX_BYTES=$rx_bytes
        PREV_TX_BYTES=$tx_bytes
        PREV_TIME=$current_time
        
        sleep 1
    done
}

# Function to handle cleanup on exit
cleanup() {
    echo
    print_colored $YELLOW "🛑 Shutting down tunnel..."
    if [ -n "$TUNNEL_PID" ] && kill -0 $TUNNEL_PID 2>/dev/null; then
        kill $TUNNEL_PID 2>/dev/null
        print_colored $GREEN "✅ Tunnel closed successfully"
    fi
    if [ -n "$TUNNEL_START_TIME" ]; then
        local end_time=$(date +%s)
        local total_uptime=$((end_time - $TUNNEL_START_TIME))
        print_colored $CYAN "⏱️  Total uptime: $(format_uptime $total_uptime)"
    fi
    print_colored $BLUE "👋 Thank you for using SSH Tunnel!"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

# Load environment variables from .env file if it exists
load_env_file

# Parse command line arguments
while [[ $# -gt 0 ]]; do
    case $1 in
        -u|--username)
            USERNAME="$2"
            shift 2
            ;;
        -p|--password)
            PASSWORD="$2"
            shift 2
            ;;
        -h|--host)
            HOST="$2"
            shift 2
            ;;
        -l|--local-port)
            LOCAL_PORT="$2"
            shift 2
            ;;
        -r|--remote-port)
            REMOTE_PORT="$2"
            shift 2
            ;;
        -v|--verbose)
            VERBOSE=true
            shift
            ;;
        -m|--monitor)
            ENABLE_MONITORING=true
            shift
            ;;
        --help)
            usage
            exit 0
            ;;
        *)
            print_colored $RED "Unknown option: $1"
            usage
            exit 1
            ;;
    esac
done

# Check if all required parameters are provided
if [ -z "$USERNAME" ] || [ -z "$PASSWORD" ] || [ -z "$HOST" ] || [ -z "$LOCAL_PORT" ] || [ -z "$REMOTE_PORT" ]; then
    print_colored $RED "Error: Missing required parameters"
    echo
    
    # Check if .env file exists and suggest using it
    if [ ! -f ".env" ] && [ -f ".env.example" ]; then
        print_colored $YELLOW "💡 You can create a .env file to avoid typing parameters:"
        print_colored $CYAN "   cp .env.example .env"
        print_colored $CYAN "   # Edit .env with your credentials"
        print_colored $CYAN "   ./tunnel.sh"
        echo
    fi
    
    usage
    exit 1
fi

# Security warnings for password usage
print_colored $YELLOW "⚠️  Security Warning: Using password authentication"
print_colored $YELLOW "💡 For better security, consider using SSH keys instead of passwords"
print_colored $YELLOW "💡 Avoid passing passwords as command-line arguments in production"
print_colored $YELLOW "💡 Consider using environment variables: export SSHPASS='your_password' && sshpass -e ssh ..."
echo

# Validate inputs
validate_port "$LOCAL_PORT" "local"
validate_port "$REMOTE_PORT" "remote"

# Check if sshpass is installed
check_sshpass

# Check if local port is available
check_local_port "$LOCAL_PORT"

# Create the SSH tunnel
create_tunnel

# Start monitoring network traffic in the background
monitor_network_traffic &

# Wait for the tunnel process to exit
wait $TUNNEL_PID