# 🚀 DigitalOcean Droplet Deployment Guide

This guide provides step-by-step instructions for deploying Open SWE on a DigitalOcean Droplet using our automated deployment script.

## 📋 Prerequisites

### DigitalOcean Droplet Requirements
- **OS**: Ubuntu 20.04 LTS or Ubuntu 22.04 LTS (recommended)
- **Size**: Minimum 2GB RAM, 2 vCPUs (4GB RAM recommended for production)
- **Storage**: At least 25GB SSD
- **Network**: Public IP address

### Required Accounts & API Keys
Before running the deployment script, ensure you have:

#### 🐙 GitHub App (Required)
1. Create a GitHub App at: https://github.com/settings/apps/new
2. Configure with the following settings:
   - **Permissions**: Contents (Read & Write), Issues (Read & Write), Pull requests (Read & Write)
   - **Events**: Issues, Pull request review, Pull request review comment, Issue comment
   - **Installation**: Choose "Any account" or "Only on this account"

#### 🤖 API Keys (At least one LLM provider required)
- **Anthropic API Key** (recommended): https://console.anthropic.com/
- **OpenAI API Key** (optional): https://platform.openai.com/api-keys
- **Google AI API Key** (optional): https://makersuite.google.com/app/apikey
- **Daytona API Key** (required): https://daytona.io/
- **Firecrawl API Key** (optional): https://firecrawl.dev/
- **LangSmith API Key** (optional): https://smith.langchain.com/

## 🚀 Quick Deployment

### Step 1: Create DigitalOcean Droplet

1. **Create Droplet**:
   - Choose Ubuntu 22.04 LTS
   - Select appropriate size (minimum 2GB RAM)
   - Add your SSH key
   - Create droplet

2. **Connect to Droplet**:
   ```bash
   ssh root@your-droplet-ip
   ```

3. **Create Non-Root User** (if not already done):
   ```bash
   adduser deploy
   usermod -aG sudo deploy
   su - deploy
   ```

### Step 2: Download and Run Deployment Script

#### Option A: Standard Deployment (GitHub Clone)
```bash
# Download the deployment script
wget https://raw.githubusercontent.com/your-repo/deploy-openswe.sh
chmod +x deploy-openswe.sh

# Run the deployment script
./deploy-openswe.sh
```

#### Option B: Local Development Deployment (Recommended for Developers)
If you have a local copy of the Open SWE repository and want to deploy your local changes:

```bash
# Navigate to your local Open SWE directory
cd /path/to/your/open-swe-project

# Copy the deployment script to your local directory
wget https://raw.githubusercontent.com/your-repo/deploy-openswe.sh
chmod +x deploy-openswe.sh

# Run the deployment script from within the Open SWE directory
./deploy-openswe.sh
```

**🏠 Local Installation Benefits:**
- **Faster Deployment**: No need to download from GitHub
- **Deploy Local Changes**: Test your modifications directly
- **Development Workflow**: Perfect for iterative development
- **Offline Capability**: Works without internet access to GitHub

#### 🔍 How Local Detection Works

The deployment script automatically detects if you're running it from within an Open SWE project directory by:

1. **Directory Name Check**: Looks for "open-swe" in the current or parent directory name
2. **Structure Validation**: Verifies the presence of required files and directories:
   - `package.json` (root package file)
   - `apps/open-swe/` (agent application directory)
   - `apps/web/` (web application directory)

**Detection Examples:**
```bash
# ✅ These directories will be detected as Open SWE projects:
/home/user/open-swe/
/home/user/open-swe-main/
/home/user/my-open-swe-fork/
/projects/open-swe-development/

# ❌ These will fall back to GitHub clone:
/home/user/my-project/
/home/user/deployment-scripts/
```

**What Happens During Local Installation:**
1. **File Copy**: All local files are copied to `/opt/open-swe/`
2. **Ownership Setup**: Files are assigned to the `openswe` user
3. **Git Cleanup**: Any `.git` directory is removed to avoid conflicts
4. **Dependency Installation**: `yarn install` runs on the copied files
5. **Build Process**: Applications are built from your local code

**Deployment Summary Display:**
The final deployment summary will show which method was used:
```
📋 Deployment Summary:
  • Installation Method: 🏠 Local copy (from /path/to/your/project)
  # OR
  • Installation Method: 🌐 GitHub clone
```

### Step 3: Configuration Options

The enhanced deployment script now offers multiple configuration methods:

#### 🆕 Configuration Management Features
- **Save/Load Configurations**: Save deployment settings for reuse
- **Interactive User Management**: Configure allowed GitHub users with validation
- **Advanced Settings**: Memory limits, PM2 clustering, debug mode
- **Configuration Templates**: Reuse settings across deployments

#### Configuration Flow
1. **Choose Configuration Method**:
   - Create new configuration (full interactive setup)
   - Load from existing configuration file
   - Load from default configuration (if available)

2. **Interactive Setup** (for new configurations):
   - **Domain Configuration**: IP-only or custom domain with SSL
   - **GitHub App Setup**: App credentials and webhook configuration
   - **User Access Control**: Configure allowed GitHub users with validation
   - **API Keys**: LLM provider keys (Anthropic, OpenAI, Google AI, etc.)
   - **Advanced Options**: Memory limits, clustering, debug mode

3. **Configuration Save**: Option to save settings for future deployments

#### 👥 Enhanced User Management
- **GitHub Username Validation**: Ensures valid usernames
- **Duplicate Prevention**: Prevents adding the same user twice
- **Admin User Setup**: Automatically suggests current system user
- **Team Member Addition**: Interactive process to add multiple users

#### ⚙️ Advanced Configuration Options
- **Memory Limits**: Choose from 1GB, 2GB, 4GB, or custom limits
- **PM2 Clustering**: Enable multi-process clustering for better performance
- **Debug Mode**: Enable detailed logging for troubleshooting
- **Custom Webhook Paths**: Configure custom GitHub webhook endpoints
- **LangSmith Integration**: Optional project tracking and monitoring

#### 💾 Configuration File Management
```bash
# Example: Using saved configuration for multiple deployments
./deploy-openswe.sh
# Choose option 2: Load from existing configuration file
# Enter path: my-production-config.json

# Configuration files are saved in JSON format:
{
  "deployment_info": {
    "created_at": "2025-01-01T00:00:00Z",
    "server_ip": "192.168.1.100",
    "script_version": "2.0"
  },
  "domain_config": {
    "domain": "openswe.example.com",
    "use_ssl": true
  },
  "allowed_users": ["admin", "developer1", "developer2"],
  "advanced_config": {
    "memory_limit": "2G",
    "enable_clustering": true,
    "debug_mode": false
  }
}
```

## 🔧 Post-Deployment Configuration

### Update GitHub App Webhook

After deployment, update your GitHub App settings:

1. Go to your GitHub App settings
2. Update **Webhook URL** to: `https://your-domain.com/webhook/github` or `http://your-ip/webhook/github`
3. Use the webhook secret provided by the deployment script

### Configure Allowed Users

Edit the environment file to add authorized users:

```bash
sudo -u openswe nano /opt/open-swe/.env
```

Update the `NEXT_PUBLIC_ALLOWED_USERS_LIST`:
```bash
NEXT_PUBLIC_ALLOWED_USERS_LIST='["your-github-username", "teammate1", "teammate2"]'
```

Restart services after changes:
```bash
sudo -u openswe pm2 restart all
```

## 🛠️ Management Commands

### Service Management
```bash
# View service status
sudo -u openswe pm2 status

# View logs
sudo -u openswe pm2 logs

# Restart all services
sudo -u openswe pm2 restart all

# Stop all services
sudo -u openswe pm2 stop all

# Start all services
sudo -u openswe pm2 start all
```

### System Management
```bash
# Check Nginx status
sudo systemctl status nginx

# Restart Nginx
sudo systemctl restart nginx

# View Nginx logs
sudo tail -f /var/log/nginx/error.log
```

### SSL Certificate Management (if using domain)
```bash
# Check certificate status
sudo certbot certificates

# Renew certificates manually
sudo certbot renew

# Test auto-renewal
sudo certbot renew --dry-run
```

## 🔍 Troubleshooting

### Common Issues

#### Services Not Starting
```bash
# Check PM2 logs for errors
sudo -u openswe pm2 logs

# Check if ports are available
sudo netstat -tlnp | grep -E ':(3000|2024)'

# Restart services
sudo -u openswe pm2 restart all
```

#### Nginx Configuration Issues
```bash
# Test Nginx configuration
sudo nginx -t

# Check Nginx error logs
sudo tail -f /var/log/nginx/error.log

# Restart Nginx
sudo systemctl restart nginx
```

#### SSL Certificate Issues
```bash
# Check certificate status
sudo certbot certificates

# Check domain DNS resolution
nslookup your-domain.com

# Manually renew certificate
sudo certbot renew --force-renewal
```

#### GitHub Webhook Issues
1. Verify webhook URL is accessible from internet
2. Check webhook secret matches GitHub App settings
3. Ensure user is in allowed users list
4. Check agent service logs for webhook errors

### Health Check Commands
```bash
# Test web application
curl -I http://your-domain-or-ip

# Test agent service (may return 404, which is normal)
curl -I http://localhost:2024

# Check all services
sudo -u openswe pm2 status
sudo systemctl status nginx
```

## 🔐 Security Considerations

### Firewall Configuration
The deployment script configures UFW with these rules:
- SSH (port 22): Allowed
- HTTP (port 80): Allowed
- HTTPS (port 443): Allowed
- Development ports (3000, 2024): Allowed (consider removing in production)

### Additional Security Hardening
```bash
# Disable root SSH login
sudo sed -i 's/PermitRootLogin yes/PermitRootLogin no/' /etc/ssh/sshd_config
sudo systemctl restart ssh

# Install fail2ban for brute force protection
sudo apt install fail2ban
sudo systemctl enable fail2ban

# Remove development port access (optional)
sudo ufw delete allow 3000/tcp
sudo ufw delete allow 2024/tcp
```

## 📊 Monitoring and Maintenance

### Log Locations
- **PM2 Logs**: `/opt/open-swe/logs/`
- **Nginx Logs**: `/var/log/nginx/`
- **System Logs**: `/var/log/syslog`

### Regular Maintenance Tasks
```bash
# Update system packages (monthly)
sudo apt update && sudo apt upgrade -y

# Rotate PM2 logs (weekly)
sudo -u openswe pm2 flush

# Check disk space
df -h

# Monitor memory usage
free -h
```

### Backup Recommendations
- **Environment Configuration**: Backup `/opt/open-swe/.env`
- **Nginx Configuration**: Backup `/etc/nginx/sites-available/openswe`
- **SSL Certificates**: Backup `/etc/letsencrypt/` (if using SSL)

## 🚀 Scaling and Performance

### Vertical Scaling (Upgrade Droplet)
1. Power off droplet
2. Resize to larger plan
3. Power on and verify services

### Performance Optimization
```bash
# Enable PM2 clustering (if needed)
sudo -u openswe pm2 delete all
# Edit ecosystem.config.js to set instances: 'max'
sudo -u openswe pm2 start ecosystem.config.js
```

### Monitoring Setup
Consider adding monitoring tools:
- **Uptime monitoring**: UptimeRobot, Pingdom
- **Performance monitoring**: New Relic, DataDog
- **Log aggregation**: ELK Stack, Splunk

## 📞 Support

### Getting Help
- **Logs**: Always check PM2 and Nginx logs first
- **GitHub Issues**: Report bugs in the Open SWE repository
- **Community**: Join LangChain Discord for community support

### Useful Resources
- [Open SWE Documentation](https://docs.langchain.com/labs/swe/)
- [DigitalOcean Tutorials](https://www.digitalocean.com/community/tutorials)
- [PM2 Documentation](https://pm2.keymetrics.io/docs/)
- [Nginx Documentation](https://nginx.org/en/docs/)

---

**🎉 Congratulations!** Your Open SWE instance should now be running successfully on DigitalOcean. Remember to keep your system updated and monitor the logs regularly.
