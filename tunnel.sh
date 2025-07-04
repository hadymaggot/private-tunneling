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
NC='\033[0m' # No Color

# Default values
USERNAME=""
PASSWORD=""
HOST=""
LOCAL_PORT=""
REMOTE_PORT=""
VERBOSE=false

# Function to print colored output
print_colored() {
    local color=$1
    local message=$2
    echo -e "${color}${message}${NC}"
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
    print_colored $GREEN "Creating SSH tunnel..."
    print_colored $BLUE "Local: localhost:$LOCAL_PORT -> Remote: $HOST:$REMOTE_PORT"
    echo
    
    local ssh_options="-N -L $LOCAL_PORT:localhost:$REMOTE_PORT"
    
    if [ "$VERBOSE" = true ]; then
        ssh_options="$ssh_options -v"
        print_colored $YELLOW "Running in verbose mode..."
    fi
    
    # Add options for better compatibility
    ssh_options="$ssh_options -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o LogLevel=ERROR"
    
    print_colored $GREEN "Tunnel is now active. Press Ctrl+C to stop."
    print_colored $BLUE "You can now connect to localhost:$LOCAL_PORT"
    echo
    
    # Create the tunnel using sshpass
    if [ "$VERBOSE" = true ]; then
        sshpass -p "$PASSWORD" ssh $ssh_options "$USERNAME@$HOST"
    else
        sshpass -p "$PASSWORD" ssh $ssh_options "$USERNAME@$HOST" 2>/dev/null
    fi
}

# Function to handle cleanup on exit
cleanup() {
    print_colored $YELLOW "\nCleaning up and closing tunnel..."
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

# Validate inputs
validate_port "$LOCAL_PORT" "local"
validate_port "$REMOTE_PORT" "remote"

# Check if sshpass is installed
check_sshpass

# Check if local port is available
check_local_port "$LOCAL_PORT"

# Create the SSH tunnel
create_tunnel