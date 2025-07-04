# Private SSH Tunneling

A universal Bash script for creating SSH tunnels that works seamlessly across Windows (Git Bash/WSL/PowerShell) and Linux (Ubuntu) environments.

## SSH Tunnel Flow Diagram

```
┌─────────────────┐    SSH Tunnel     ┌─────────────────┐    ┌─────────────────┐
│   Local Client  │ ◄═══════════════► │   SSH Server    │ ◄──┤  Remote Service │
│  (Your Machine) │                   │  (Jump Host)    │    │   (Database,    │
│                 │                   │                 │    │    Web API,     │
│ localhost:LOCAL │                   │ REMOTE_HOST     │    │    etc.)        │
│      PORT       │                   │                 │    │ localhost:REMOTE│
└─────────────────┘                   └─────────────────┘    │      PORT       │
         │                                     │              └─────────────────┘
         │                                     │
    Application connects                  Tunnel forwards
    to localhost:LOCAL_PORT              to REMOTE_HOST:REMOTE_PORT
    
Example: ./tunnel.sh -u user -p pass -h ssh.example.com -l 8080 -r 3306
         connects localhost:8080 ───► ssh.example.com ───► localhost:3306 (MySQL)
```

## Features

- 🌐 **Cross-platform compatibility** - Works on Windows (Git Bash, WSL, PowerShell) and Linux
- 🔒 **Secure tunneling** - Uses SSH protocol for secure port forwarding
- 🚀 **Easy to use** - Simple command-line interface with clear parameter options
- 🛡️ **Input validation** - Validates ports, checks availability, and provides helpful error messages
- 📝 **Comprehensive logging** - Optional verbose mode for debugging
- 🎨 **Colored output** - Easy-to-read colored terminal output

## Quick Start

```bash
# Clone the repository
git clone https://github.com/hadymaggot/private-tunneling.git
cd private-tunneling

# Make script executable
chmod +x tunnel.sh

# Create a tunnel (example: MySQL database)
./tunnel.sh -u myuser -p mypassword -h db.example.com -l 8080 -r 3306
```

## Usage

### Basic Syntax

```bash
./tunnel.sh -u USERNAME -p PASSWORD -h HOST -l LOCAL_PORT -r REMOTE_PORT [OPTIONS]
```

### Parameters

| Parameter | Description | Required | Example |
|-----------|-------------|----------|---------|
| `-u` | SSH username | ✅ | `-u admin` |
| `-p` | SSH password | ✅ | `-p mypassword` |
| `-h` | Remote host (IP or hostname) | ✅ | `-h example.com` |
| `-l` | Local port to bind tunnel | ✅ | `-l 8080` |
| `-r` | Remote port to tunnel to | ✅ | `-r 3306` |
| `-v` | Verbose mode | ❌ | `-v` |
| `--help` | Show help message | ❌ | `--help` |

### Examples

**MySQL Database Tunnel:**
```bash
./tunnel.sh -u dbuser -p dbpass -h mysql.example.com -l 3306 -r 3306
```

**PostgreSQL Database Tunnel:**
```bash
./tunnel.sh -u postgres -p secret -h pg.example.com -l 5432 -r 5432
```

**Web Service Tunnel:**
```bash
./tunnel.sh -u webuser -p webpass -h api.example.com -l 8080 -r 80
```

**With Verbose Output:**
```bash
./tunnel.sh -u user -p pass -h example.com -l 8080 -r 3306 -v
```

## Example Output

When you run the script, you'll see a modern interface with animated spinner and status information:

```
⚠️  Security Warning: Using password authentication
💡 For better security, consider using SSH keys instead of passwords
💡 Avoid passing passwords as command-line arguments in production
💡 Consider using environment variables: export SSHPASS='your_password' && sshpass -e ssh ...

╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                          🚇 SSH TUNNEL SETUP                                                          ║
╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

📡 Tunnel Configuration:
   Local:  localhost:8080
   Remote: db.example.com:3306
   User:   myuser

🔌 Establishing SSH connection...
⏳ Connecting to db.example.com ▉   
✅ SSH tunnel established successfully!

╔════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╗
║                                          🚇 SSH TUNNEL STATUS                                                          ║
╠════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╣
║ Status:      ✓ Active                                                                                                 ║
║ Local IP:    192.168.1.100                                                                                            ║
║ Local Port:  8080                                                                                                     ║
║ Remote:      db.example.com:3306                                                                                      ║
║ Uptime:      00m 05s                                                                                                  ║
║ Connect to:  localhost:8080                                                                                           ║
╚════════════════════════════════════════════════════════════════════════════════════════════════════════════════════╝

💡 Monitor traffic: netstat -an | grep :8080
💡 Check connections: ss -tuln | grep :8080

🎯 Tunnel is now active. Press Ctrl+C to stop.
🔗 Connect your applications to localhost:8080

⏱️  Tunnel uptime: 00m 35s               
```

## Testing & Verification Checklist

Use this checklist to verify your SSH tunnel setup and test the script's features:

### Prerequisites
- [ ] SSH client installed on your system
- [ ] `sshpass` installed (see [Installing sshpass](#installing-sshpass))
- [ ] Network connectivity to target SSH server
- [ ] Valid SSH credentials (username/password or SSH keys)

### Basic Functionality Tests
- [ ] **Help Command**: `./tunnel.sh --help` displays usage information
- [ ] **Parameter Validation**: Script rejects invalid ports (e.g., `-l 99999`)
- [ ] **Missing Parameters**: Script shows error for missing required parameters
- [ ] **Port Availability**: Script checks if local port is already in use

### Connection Tests
- [ ] **Basic Tunnel**: Successfully establish tunnel to a known SSH server
- [ ] **Connection Test**: Verify you can connect to `localhost:LOCAL_PORT`
- [ ] **Verbose Mode**: Test with `-v` flag for detailed SSH output
- [ ] **Different Ports**: Test with various local and remote port combinations

### Security Features
- [ ] **Password Warning**: Script displays security warnings for password usage
- [ ] **SSH Key Alternative**: Test connection using SSH keys (modify script as needed)
- [ ] **Process Isolation**: Tunnel runs as separate process that can be cleanly terminated

### User Interface Features
- [ ] **Spinner Animation**: Animated spinner appears during connection establishment
- [ ] **Status Display**: Tunnel status box appears with connection details
- [ ] **Uptime Counter**: Uptime updates periodically while tunnel is active
- [ ] **Colored Output**: Messages appear in appropriate colors (green for success, red for errors)
- [ ] **Clean Shutdown**: Ctrl+C properly terminates tunnel with summary

### Cross-Platform Compatibility
- [ ] **Linux**: Test on Ubuntu/Debian system
- [ ] **macOS**: Test on macOS with Homebrew-installed dependencies
- [ ] **Windows Git Bash**: Test in Git Bash environment
- [ ] **Windows WSL**: Test in Windows Subsystem for Linux

### Network Monitoring
- [ ] **Traffic Commands**: Verify suggested monitoring commands work:
  - `netstat -an | grep :LOCAL_PORT`
  - `ss -tuln | grep :LOCAL_PORT`
- [ ] **Connection Verification**: Confirm actual application connections through tunnel

### Error Handling
- [ ] **Invalid Credentials**: Script handles authentication failures gracefully
- [ ] **Network Issues**: Script detects and reports connection failures
- [ ] **Port Conflicts**: Script detects when local port is already in use
- [ ] **Missing Dependencies**: Script reports missing `sshpass` with installation instructions

## Platform-Specific Instructions

### Windows

#### Git Bash
1. Install Git for Windows (includes Git Bash)
2. Open Git Bash terminal
3. Install sshpass (see installation section below)
4. Run the script as shown in examples

#### Windows Subsystem for Linux (WSL)
1. Install WSL with Ubuntu
2. Open WSL terminal
3. Install sshpass: `sudo apt-get update && sudo apt-get install sshpass`
4. Run the script as shown in examples

#### PowerShell
1. Install Windows Subsystem for Linux or use Git Bash
2. Alternatively, use PowerShell with SSH client and manual port forwarding

### Linux (Ubuntu/Debian)

1. Install sshpass: `sudo apt-get update && sudo apt-get install sshpass`
2. Make script executable: `chmod +x tunnel.sh`
3. Run the script as shown in examples

### macOS

1. Install sshpass: `brew install sshpass`
2. Make script executable: `chmod +x tunnel.sh`
3. Run the script as shown in examples

## Installing sshpass

The script requires `sshpass` for password-based SSH authentication.

### Ubuntu/Debian
```bash
sudo apt-get update
sudo apt-get install sshpass
```

### CentOS/RHEL/Fedora
```bash
# CentOS/RHEL
sudo yum install sshpass

# Fedora
sudo dnf install sshpass
```

### macOS (with Homebrew)
```bash
brew install sshpass
```

### Windows

#### Option 1: WSL (Recommended)
```bash
# In WSL Ubuntu terminal
sudo apt-get update && sudo apt-get install sshpass
```

#### Option 2: Git Bash
Download a Windows-compatible sshpass binary or use alternative methods like SSH keys.

## Integration Examples

### Python Integration

```python
import subprocess
import sys

def create_ssh_tunnel(username, password, host, local_port, remote_port):
    """Create SSH tunnel using the tunnel.sh script"""
    try:
        cmd = [
            './tunnel.sh',
            '-u', username,
            '-p', password,
            '-h', host,
            '-l', str(local_port),
            '-r', str(remote_port)
        ]
        
        # Start tunnel in background
        process = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        return process
    except Exception as e:
        print(f"Error creating tunnel: {e}")
        return None

# Example usage
if __name__ == "__main__":
    tunnel_process = create_ssh_tunnel(
        username="myuser",
        password="mypass",
        host="db.example.com",
        local_port=8080,
        remote_port=3306
    )
    
    if tunnel_process:
        print("Tunnel created successfully!")
        print("Connect to localhost:8080 to access remote service")
        
        # Your application logic here
        # ...
        
        # Clean up
        tunnel_process.terminate()
```

### Node.js Integration

```javascript
const { spawn } = require('child_process');

class SSHTunnel {
    constructor(config) {
        this.config = config;
        this.process = null;
    }
    
    start() {
        return new Promise((resolve, reject) => {
            const args = [
                '-u', this.config.username,
                '-p', this.config.password,
                '-h', this.config.host,
                '-l', this.config.localPort.toString(),
                '-r', this.config.remotePort.toString()
            ];
            
            this.process = spawn('./tunnel.sh', args);
            
            this.process.stdout.on('data', (data) => {
                console.log(`Tunnel: ${data}`);
                if (data.includes('Tunnel is now active')) {
                    resolve();
                }
            });
            
            this.process.stderr.on('data', (data) => {
                console.error(`Tunnel Error: ${data}`);
                reject(new Error(data.toString()));
            });
            
            this.process.on('close', (code) => {
                console.log(`Tunnel process exited with code ${code}`);
            });
        });
    }
    
    stop() {
        if (this.process) {
            this.process.kill('SIGTERM');
            this.process = null;
        }
    }
}

// Example usage
const tunnel = new SSHTunnel({
    username: 'myuser',
    password: 'mypass',
    host: 'db.example.com',
    localPort: 8080,
    remotePort: 3306
});

tunnel.start()
    .then(() => {
        console.log('Tunnel is ready!');
        // Your application logic here
        // Connect to localhost:8080
    })
    .catch((error) => {
        console.error('Failed to start tunnel:', error);
    });

// Clean up on exit
process.on('SIGINT', () => {
    tunnel.stop();
    process.exit();
});
```

### PHP Integration

```php
<?php
class SSHTunnel {
    private $process;
    private $pipes;
    
    public function __construct($username, $password, $host, $localPort, $remotePort) {
        $cmd = sprintf(
            './tunnel.sh -u %s -p %s -h %s -l %d -r %d',
            escapeshellarg($username),
            escapeshellarg($password),
            escapeshellarg($host),
            $localPort,
            $remotePort
        );
        
        $descriptorspec = [
            0 => ["pipe", "r"],  // stdin
            1 => ["pipe", "w"],  // stdout
            2 => ["pipe", "w"]   // stderr
        ];
        
        $this->process = proc_open($cmd, $descriptorspec, $this->pipes);
    }
    
    public function isRunning() {
        if (!$this->process) return false;
        
        $status = proc_get_status($this->process);
        return $status['running'];
    }
    
    public function stop() {
        if ($this->process) {
            proc_terminate($this->process);
            proc_close($this->process);
        }
    }
    
    public function __destruct() {
        $this->stop();
    }
}

// Example usage
$tunnel = new SSHTunnel('myuser', 'mypass', 'db.example.com', 8080, 3306);

if ($tunnel->isRunning()) {
    echo "Tunnel is active! Connect to localhost:8080\n";
    
    // Your application logic here
    // Connect to localhost:8080 for database access
    
    sleep(5); // Simulate work
}

$tunnel->stop();
?>
```

## Security Recommendations

⚠️ **Important Security Notes:**

### 1. Use SSH Keys Instead of Passwords
SSH key authentication is much more secure than password authentication:

```bash
# Generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "your_email@example.com"

# Copy public key to remote server
ssh-copy-id username@hostname

# Modify script to use key-based auth (remove -p parameter)
```

### 2. Environment Variables for Passwords
Instead of passing passwords as command-line arguments:

```bash
# Set password as environment variable
export SSH_PASSWORD="your_password"

# Modify script to read from environment
# sshpass -e ssh ... (uses SSHPASS environment variable)
```

### 3. Restrict Network Access
- Only allow SSH tunnels from trusted IP addresses
- Use firewall rules to limit tunnel access
- Monitor tunnel usage and connections

### 4. Use VPN When Possible
For production environments, consider using VPN solutions instead of SSH tunnels for better security and performance.

### 5. Regular Security Updates
- Keep SSH client and server updated
- Regularly rotate SSH keys and passwords
- Monitor for unauthorized access attempts

## Troubleshooting

### Common Issues

**1. "sshpass: command not found"**
```bash
# Install sshpass based on your platform (see installation section)
```

**2. "Permission denied (publickey,password)"**
```bash
# Check username and password
# Verify SSH server allows password authentication
# Try connecting manually: ssh username@hostname
```

**3. "Port already in use"**
```bash
# Check what's using the port:
netstat -tuln | grep :PORT_NUMBER

# Or use ss command:
ss -tuln | grep :PORT_NUMBER

# Kill process using the port or choose different port
```

**4. "Connection refused"**
```bash
# Check if SSH service is running on remote host
# Verify firewall settings
# Ensure correct hostname/IP address
```

**5. Windows Git Bash Issues**
```bash
# Ensure you're using the latest Git for Windows
# Try running in WSL instead
# Check if sshpass is properly installed for Windows
```

## Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## Support

If you encounter any issues or have questions:

1. Check the [Troubleshooting](#troubleshooting) section
2. Search existing [GitHub Issues](../../issues)
3. Create a new issue with detailed information about your problem

---

**Note:** This tool is designed for development and testing purposes. For production environments, consider more robust solutions like VPN or dedicated tunnel management tools.
