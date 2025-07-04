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
        local uptime=$((current_time - TUNNEL_START_TIME))
        local local_ip=$(get_local_ip)
        
        echo
        print_colored $GREEN "╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
        print_colored $GREEN "║                                          🚇 SSH TUNNEL STATUS                                                          ║"
        print_colored $GREEN "╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣"
        printf "${GREEN}║${NC} ${BLUE}Status:${NC}      ${GREEN}✓ Active${NC}%*s${GREEN}║${NC}\n" $((96 - 19)) ""
        printf "${GREEN}║${NC} ${BLUE}Local IP:${NC}    ${YELLOW}%-20s${NC}%*s${GREEN}║${NC}\n" "$local_ip" $((96 - 31)) ""
        printf "${GREEN}║${NC} ${BLUE}Local Port:${NC}  ${YELLOW}%-20s${NC}%*s${GREEN}║${NC}\n" "$LOCAL_PORT" $((96 - 33)) ""
        printf "${GREEN}║${NC} ${BLUE}Remote:${NC}      ${YELLOW}%-20s:%-10s${NC}%*s${GREEN}║${NC}\n" "$HOST" "$REMOTE_PORT" $((96 - 42)) ""
        printf "${GREEN}║${NC} ${BLUE}Uptime:${NC}      ${CYAN}%-20s${NC}%*s${GREEN}║${NC}\n" "$(format_uptime $uptime)" $((96 - 29)) ""
        printf "${GREEN}║${NC} ${BLUE}Connect to:${NC}  ${GREEN}localhost:$LOCAL_PORT${NC}%*s${GREEN}║${NC}\n" $((96 - 25 - ${#LOCAL_PORT})) ""
        print_colored $GREEN "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
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

Usage: $0 -u USERNAME -p PASSWORD -h HOST -l LOCAL_PORT -r REMOTE_PORT [OPTIONS]

Required Parameters:
  -u USERNAME     SSH username
  -p PASSWORD     SSH password (use SSH keys for better security)
  -h HOST         Remote SSH host (IP address or hostname)
  -l LOCAL_PORT   Local port to bind tunnel to
  -r REMOTE_PORT  Remote port to tunnel to

Optional Parameters:
  -v              Verbose mode
  --help          Show this help message

Examples:
  $0 -u user -p mypassword -h example.com -l 8080 -r 3306
  $0 -u admin -p secret123 -h 192.168.1.100 -l 5432 -r 5432 -v

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
    print_colored $MAGENTA "╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗"
    print_colored $MAGENTA "║                                          🚇 SSH TUNNEL SETUP                                                          ║"
    print_colored $MAGENTA "╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝"
    echo
    print_colored $BLUE "📡 Tunnel Configuration:"
    print_colored $CYAN "   Local:  localhost:$LOCAL_PORT"
    print_colored $CYAN "   Remote: $HOST:$REMOTE_PORT"
    print_colored $CYAN "   User:   $USERNAME"
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
    else
        print_colored $RED "❌ Failed to establish SSH tunnel!"
        print_colored $YELLOW "💡 Check your credentials and network connectivity"
        exit 1
    fi
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
        local total_uptime=$((end_time - TUNNEL_START_TIME))
        print_colored $CYAN "⏱️  Total uptime: $(format_uptime $total_uptime)"
    fi
    print_colored $BLUE "👋 Thank you for using SSH Tunnel!"
    exit 0
}

# Set up signal handlers
trap cleanup SIGINT SIGTERM

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