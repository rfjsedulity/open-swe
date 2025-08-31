#!/bin/bash

# ============================================================================
# 🚀 Open SWE DigitalOcean Droplet Deployment Script
# ============================================================================
# This script automates the deployment of Open SWE on a DigitalOcean Droplet
# with options for IP-only or domain deployment, SSL certificates, and more.
# ============================================================================

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

log_step() {
    echo -e "\n${PURPLE}[STEP]${NC} $1"
    echo "============================================"
}

# Global variables
OPENSWE_DIR="/opt/open-swe"
OPENSWE_USER="openswe"
DOMAIN=""
USE_SSL=false
SERVER_IP=""
GITHUB_APP_NAME=""
GITHUB_APP_ID=""
GITHUB_APP_CLIENT_ID=""
GITHUB_APP_CLIENT_SECRET=""
GITHUB_APP_PRIVATE_KEY=""
GITHUB_WEBHOOK_SECRET=""
LINEAR_API_KEY=""
LINEAR_WORKSPACE_ID=""
LINEAR_WEBHOOK_SECRET=""
LINEAR_TEAM_ID=""
ANTHROPIC_API_KEY=""
OPENAI_API_KEY=""
GOOGLE_API_KEY=""
DAYTONA_API_KEY=""
FIRECRAWL_API_KEY=""
LANGCHAIN_API_KEY=""
SECRETS_ENCRYPTION_KEY=""
ALLOWED_USERS_LIST=""
LANGCHAIN_PROJECT=""
CUSTOM_API_BEARER_TOKEN=""
MEMORY_LIMIT="1G"
ENABLE_CLUSTERING=false
CUSTOM_WEBHOOK_PATH=""
DEBUG_MODE=false
CONFIG_FILE="openswe-deploy-config.json"

# Function to check if running as root
check_root() {
    if [[ $EUID -eq 0 ]]; then
        log_error "This script should not be run as root for security reasons."
        log_info "Please run as a regular user with sudo privileges."
        exit 1
    fi
}

# Function to check system requirements
check_system() {
    log_step "Checking System Requirements"
    
    # Check if Ubuntu/Debian
    if ! command -v apt &> /dev/null; then
        log_error "This script requires Ubuntu or Debian with apt package manager."
        exit 1
    fi
    
    # Check sudo privileges
    if ! sudo -n true 2>/dev/null; then
        log_error "This script requires sudo privileges. Please run: sudo visudo"
        log_info "Add this line: $USER ALL=(ALL) NOPASSWD:ALL"
        exit 1
    fi
    
    # Get server IP
    SERVER_IP=$(curl -s ifconfig.me || curl -s ipinfo.io/ip || echo "")
    if [[ -z "$SERVER_IP" ]]; then
        log_warning "Could not detect server IP automatically."
        read -p "Please enter your server's public IP: " SERVER_IP
    fi
    
    log_success "System check passed. Server IP: $SERVER_IP"
}

# Function to validate GitHub username
validate_github_username() {
    local username="$1"
    if [[ "$username" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]*[a-zA-Z0-9])?$ ]] && [[ ${#username} -le 39 ]]; then
        return 0
    else
        return 1
    fi
}

# Function to collect allowed users
collect_allowed_users() {
    echo ""
    echo "👥 Allowed Users Configuration:"
    echo "Configure which GitHub users can access Open SWE without providing their own API keys."
    echo ""
    
    # Start with current user as default admin
    local current_user=$(whoami)
    echo "Default admin user: $current_user"
    read -p "Use '$current_user' as admin user? (y/n): " use_current
    
    local users_array=()
    if [[ "$use_current" =~ ^[Yy]$ ]]; then
        users_array+=("$current_user")
        log_info "Added $current_user as admin user"
    else
        read -p "Enter admin GitHub username: " admin_user
        if validate_github_username "$admin_user"; then
            users_array+=("$admin_user")
            log_info "Added $admin_user as admin user"
        else
            log_error "Invalid GitHub username format. Using $current_user instead."
            users_array+=("$current_user")
        fi
    fi
    
    # Add additional users
    echo ""
    echo "Add additional team members (press Enter with empty input to finish):"
    while true; do
        read -p "GitHub username (or Enter to finish): " additional_user
        if [[ -z "$additional_user" ]]; then
            break
        fi
        
        if validate_github_username "$additional_user"; then
            # Check for duplicates
            local duplicate=false
            for existing_user in "${users_array[@]}"; do
                if [[ "$existing_user" == "$additional_user" ]]; then
                    log_warning "User $additional_user already added, skipping."
                    duplicate=true
                    break
                fi
            done
            
            if [[ "$duplicate" == false ]]; then
                users_array+=("$additional_user")
                log_info "Added $additional_user"
            fi
        else
            log_error "Invalid GitHub username format: $additional_user (skipping)"
        fi
    done
    
    # Build JSON array
    ALLOWED_USERS_LIST="["
    for i in "${!users_array[@]}"; do
        if [[ $i -gt 0 ]]; then
            ALLOWED_USERS_LIST+=", "
        fi
        ALLOWED_USERS_LIST+="\"${users_array[$i]}\""
    done
    ALLOWED_USERS_LIST+="]"
    
    log_success "Configured ${#users_array[@]} allowed users: ${users_array[*]}"
}

# Function to collect additional configuration
collect_additional_config() {
    echo ""
    echo "⚙️ Additional Configuration (Optional):"
    echo "Configure advanced settings or press Enter to use defaults."
    echo ""
    
    # LangSmith project name
    read -p "LangSmith project name (default: open-swe-production): " custom_project
    LANGCHAIN_PROJECT="${custom_project:-open-swe-production}"
    
    # Custom API bearer token
    echo ""
    read -p "Generate custom API bearer token? (y/n, default: auto-generate): " custom_token_choice
    if [[ "$custom_token_choice" =~ ^[Yy]$ ]]; then
        read -s -p "Enter custom API bearer token: " CUSTOM_API_BEARER_TOKEN
        echo ""
    fi
    
    # Memory limit for PM2
    echo ""
    echo "Memory limit options:"
    echo "1) 1GB (default, suitable for small deployments)"
    echo "2) 2GB (recommended for production)"
    echo "3) 4GB (high-performance deployments)"
    echo "4) Custom"
    read -p "Choose memory limit (1-4, default: 1): " memory_choice
    
    case "$memory_choice" in
        2) MEMORY_LIMIT="2G" ;;
        3) MEMORY_LIMIT="4G" ;;
        4) 
            read -p "Enter custom memory limit (e.g., 512M, 8G): " custom_memory
            MEMORY_LIMIT="${custom_memory:-1G}"
            ;;
        *) MEMORY_LIMIT="1G" ;;
    esac
    
    # PM2 clustering
    echo ""
    read -p "Enable PM2 clustering for better performance? (y/n, default: n): " clustering_choice
    if [[ "$clustering_choice" =~ ^[Yy]$ ]]; then
        ENABLE_CLUSTERING=true
        log_info "PM2 clustering will be enabled"
    fi
    
    # Custom webhook path
    echo ""
    read -p "Custom webhook path (default: /webhook/github): " custom_webhook
    CUSTOM_WEBHOOK_PATH="${custom_webhook:-/webhook/github}"
    
    # Debug mode
    echo ""
    read -p "Enable debug mode for troubleshooting? (y/n, default: n): " debug_choice
    if [[ "$debug_choice" =~ ^[Yy]$ ]]; then
        DEBUG_MODE=true
        log_info "Debug mode will be enabled"
    fi
    
    log_success "Additional configuration completed"
}

# Function to save configuration to file
save_config() {
    local config_file="$1"
    log_info "Saving configuration to $config_file"
    
    cat > "$config_file" <<EOF
{
  "deployment_info": {
    "created_at": "$(date -Iseconds)",
    "server_ip": "$SERVER_IP",
    "script_version": "2.0"
  },
  "domain_config": {
    "domain": "$DOMAIN",
    "use_ssl": $USE_SSL
  },
  "github_app": {
    "name": "$GITHUB_APP_NAME",
    "app_id": "$GITHUB_APP_ID",
    "client_id": "$GITHUB_APP_CLIENT_ID"
  },
  "allowed_users": $ALLOWED_USERS_LIST,
  "advanced_config": {
    "langchain_project": "$LANGCHAIN_PROJECT",
    "memory_limit": "$MEMORY_LIMIT",
    "enable_clustering": $ENABLE_CLUSTERING,
    "custom_webhook_path": "$CUSTOM_WEBHOOK_PATH",
    "debug_mode": $DEBUG_MODE
  }
}
EOF
    
    log_success "Configuration saved to $config_file"
}

# Function to load configuration from file
load_config() {
    local config_file="$1"
    
    if [[ ! -f "$config_file" ]]; then
        log_error "Configuration file $config_file not found"
        return 1
    fi
    
    log_info "Loading configuration from $config_file"
    
    # Parse JSON and set variables
    DOMAIN=$(jq -r '.domain_config.domain // ""' "$config_file")
    USE_SSL=$(jq -r '.domain_config.use_ssl // false' "$config_file")
    GITHUB_APP_NAME=$(jq -r '.github_app.name // ""' "$config_file")
    GITHUB_APP_ID=$(jq -r '.github_app.app_id // ""' "$config_file")
    GITHUB_APP_CLIENT_ID=$(jq -r '.github_app.client_id // ""' "$config_file")
    ALLOWED_USERS_LIST=$(jq -c '.allowed_users // []' "$config_file")
    LANGCHAIN_PROJECT=$(jq -r '.advanced_config.langchain_project // "open-swe-production"' "$config_file")
    MEMORY_LIMIT=$(jq -r '.advanced_config.memory_limit // "1G"' "$config_file")
    ENABLE_CLUSTERING=$(jq -r '.advanced_config.enable_clustering // false' "$config_file")
    CUSTOM_WEBHOOK_PATH=$(jq -r '.advanced_config.custom_webhook_path // "/webhook/github"' "$config_file")
    DEBUG_MODE=$(jq -r '.advanced_config.debug_mode // false' "$config_file")
    
    log_success "Configuration loaded from $config_file"
    return 0
}

# Function to display configuration summary
display_config_summary() {
    echo ""
    log_step "Configuration Summary"
    
    echo -e "${CYAN}📋 Deployment Configuration:${NC}"
    echo "  • Server IP: $SERVER_IP"
    echo "  • Domain: ${DOMAIN:-"IP-only deployment"}"
    echo "  • SSL: $USE_SSL"
    echo "  • GitHub App: $GITHUB_APP_NAME"
    echo "  • Allowed Users: $ALLOWED_USERS_LIST"
    echo "  • LangSmith Project: $LANGCHAIN_PROJECT"
    echo "  • Memory Limit: $MEMORY_LIMIT"
    echo "  • Clustering: $ENABLE_CLUSTERING"
    echo "  • Debug Mode: $DEBUG_MODE"
    echo ""
    
    # Offer to save configuration
    read -p "Save this configuration for future deployments? (y/n): " save_config_choice
    if [[ "$save_config_choice" =~ ^[Yy]$ ]]; then
        read -p "Configuration filename (default: $CONFIG_FILE): " custom_config_file
        local config_filename="${custom_config_file:-$CONFIG_FILE}"
        save_config "$config_filename"
    fi
    
    echo ""
    read -p "Proceed with this configuration? (y/n): " confirm_config
    if [[ ! "$confirm_config" =~ ^[Yy]$ ]]; then
        log_error "Configuration cancelled by user"
        exit 1
    fi
    
    log_success "Configuration confirmed!"
}

# Function to collect user configuration
collect_config() {
    log_step "Collecting Configuration"
    
    echo -e "${CYAN}Welcome to Open SWE Deployment Setup!${NC}"
    echo "This script will guide you through deploying Open SWE on your DigitalOcean Droplet."
    echo ""
    
    # Check for existing configuration files
    echo "🔄 Configuration Options:"
    echo "1) Create new configuration"
    echo "2) Load from existing configuration file"
    
    if [[ -f "$CONFIG_FILE" ]]; then
        echo "3) Load from default configuration ($CONFIG_FILE)"
    fi
    
    read -p "Choose option (1-$(if [[ -f "$CONFIG_FILE" ]]; then echo "3"; else echo "2"; fi)): " config_choice
    
    case "$config_choice" in
        2)
            read -p "Enter configuration file path: " custom_config_path
            if load_config "$custom_config_path"; then
                echo ""
                echo "⚠️  Note: You'll still need to provide sensitive data (API keys, secrets)"
                collect_sensitive_data
                display_config_summary
                return
            else
                log_warning "Failed to load configuration, proceeding with manual setup"
            fi
            ;;
        3)
            if [[ -f "$CONFIG_FILE" ]] && load_config "$CONFIG_FILE"; then
                echo ""
                echo "⚠️  Note: You'll still need to provide sensitive data (API keys, secrets)"
                collect_sensitive_data
                display_config_summary
                return
            else
                log_warning "Failed to load default configuration, proceeding with manual setup"
            fi
            ;;
    esac
    
    # Proceed with manual configuration
    collect_manual_config
}

# Function to collect sensitive data when loading from config
collect_sensitive_data() {
    echo ""
    echo "🔐 Sensitive Data Collection:"
    echo "Please provide the following sensitive information (not stored in config files):"
    echo ""
    
    read -s -p "GitHub App Client Secret: " GITHUB_APP_CLIENT_SECRET
    echo ""
    
    echo "GitHub App Private Key (paste the entire key including headers):"
    echo "Press Ctrl+D when finished:"
    GITHUB_APP_PRIVATE_KEY=$(cat)
    
    # Generate webhook secret if not provided
    if [[ -z "$GITHUB_WEBHOOK_SECRET" ]]; then
        GITHUB_WEBHOOK_SECRET=$(openssl rand -hex 32)
        log_info "Generated new webhook secret: $GITHUB_WEBHOOK_SECRET"
    fi
    
    # Linear Integration (Optional)
    echo ""
    echo "📋 Linear Integration (Optional):"
    echo "Configure Linear integration to use Linear issues instead of GitHub issues."
    read -p "Enable Linear integration? (y/n, default: n): " enable_linear
    if [[ "$enable_linear" =~ ^[Yy]$ ]]; then
        read -s -p "Linear API Key (get from https://linear.app/settings/api): " LINEAR_API_KEY
        echo ""
        read -p "Linear Workspace ID: " LINEAR_WORKSPACE_ID
        read -p "Linear Team ID (optional): " LINEAR_TEAM_ID
        
        # Generate Linear webhook secret
        LINEAR_WEBHOOK_SECRET=$(openssl rand -hex 32)
        log_info "Generated Linear webhook secret: $LINEAR_WEBHOOK_SECRET"
    fi
    
    # API Keys
    echo ""
    echo "🤖 API Keys:"
    read -s -p "Anthropic API Key (required): " ANTHROPIC_API_KEY
    echo ""
    read -s -p "OpenAI API Key (optional): " OPENAI_API_KEY
    echo ""
    read -s -p "Google AI API Key (optional): " GOOGLE_API_KEY
    echo ""
    read -s -p "Daytona API Key (required): " DAYTONA_API_KEY
    echo ""
    read -s -p "Firecrawl API Key (optional): " FIRECRAWL_API_KEY
    echo ""
    read -s -p "LangSmith API Key (optional): " LANGCHAIN_API_KEY
    echo ""
    
    # Generate encryption key if not provided
    if [[ -z "$SECRETS_ENCRYPTION_KEY" ]]; then
        SECRETS_ENCRYPTION_KEY=$(openssl rand -hex 32)
        log_info "Generated new encryption key: $SECRETS_ENCRYPTION_KEY"
    fi
    
    log_success "Sensitive data collected"
}

# Function to collect manual configuration
collect_manual_config() {
    
    # Domain or IP setup
    echo "🌐 Domain Configuration:"
    echo "1) Use IP address only ($SERVER_IP)"
    echo "2) Use custom domain with SSL"
    read -p "Choose option (1 or 2): " domain_choice
    
    if [[ "$domain_choice" == "2" ]]; then
        read -p "Enter your domain name (e.g., openswe.yourdomain.com): " DOMAIN
        if [[ -n "$DOMAIN" ]]; then
            echo "🔒 SSL Certificate Setup:"
            read -p "Set up Let's Encrypt SSL certificate? (y/n): " ssl_choice
            if [[ "$ssl_choice" =~ ^[Yy]$ ]]; then
                USE_SSL=true
                log_info "SSL will be configured for $DOMAIN"
            fi
        fi
    fi
    
    # GitHub App Configuration
    echo ""
    echo "🐙 GitHub App Configuration:"
    echo "You need to create a GitHub App first. Visit: https://github.com/settings/apps/new"
    echo ""
    read -p "GitHub App Name: " GITHUB_APP_NAME
    read -p "GitHub App ID (numeric): " GITHUB_APP_ID
    read -p "GitHub App Client ID (starts with Iv1.): " GITHUB_APP_CLIENT_ID
    read -s -p "GitHub App Client Secret: " GITHUB_APP_CLIENT_SECRET
    echo ""
    
    echo "GitHub App Private Key (paste the entire key including headers):"
    echo "Press Ctrl+D when finished:"
    GITHUB_APP_PRIVATE_KEY=$(cat)
    
    # Generate webhook secret
    GITHUB_WEBHOOK_SECRET=$(openssl rand -hex 32)
    log_info "Generated webhook secret: $GITHUB_WEBHOOK_SECRET"
    
    # Collect allowed users
    collect_allowed_users
    
    # API Keys
    echo ""
    echo "🤖 API Keys Configuration:"
    read -s -p "Anthropic API Key (required): " ANTHROPIC_API_KEY
    echo ""
    read -s -p "OpenAI API Key (optional): " OPENAI_API_KEY
    echo ""
    read -s -p "Google AI API Key (optional): " GOOGLE_API_KEY
    echo ""
    read -s -p "Daytona API Key (required): " DAYTONA_API_KEY
    echo ""
    read -s -p "Firecrawl API Key (optional): " FIRECRAWL_API_KEY
    echo ""
    read -s -p "LangSmith API Key (optional): " LANGCHAIN_API_KEY
    echo ""
    
    # Generate encryption key
    SECRETS_ENCRYPTION_KEY=$(openssl rand -hex 32)
    log_info "Generated encryption key: $SECRETS_ENCRYPTION_KEY"
    
    # Collect additional configuration
    collect_additional_config
    
    # Display summary and confirm
    display_config_summary
    
    log_success "Configuration collected successfully!"
}

# Function to update system packages
update_system() {
    log_step "Updating System Packages"
    
    sudo apt update
    sudo apt upgrade -y
    sudo apt install -y curl wget git unzip software-properties-common apt-transport-https ca-certificates gnupg lsb-release jq
    
    log_success "System packages updated"
}

# Function to install Node.js and Yarn
install_nodejs() {
    log_step "Installing Node.js and Yarn"
    
    # Install Node.js 18.x
    curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
    sudo apt install -y nodejs
    
    # Install Yarn
    curl -sS https://dl.yarnpkg.com/debian/pubkey.gpg | sudo apt-key add -
    echo "deb https://dl.yarnpkg.com/debian/ stable main" | sudo tee /etc/apt/sources.list.d/yarn.list
    sudo apt update
    sudo apt install -y yarn
    
    # Verify installations
    node_version=$(node --version)
    yarn_version=$(yarn --version)
    
    log_success "Node.js $node_version and Yarn $yarn_version installed"
}

# Function to install PM2
install_pm2() {
    log_step "Installing PM2 Process Manager"
    
    sudo npm install -g pm2
    
    # Configure PM2 startup
    pm2 startup | grep -E '^sudo' | bash || true
    
    log_success "PM2 installed and configured"
}

# Function to install and configure Nginx
install_nginx() {
    log_step "Installing and Configuring Nginx"
    
    sudo apt install -y nginx
    
    # Remove default site
    sudo rm -f /etc/nginx/sites-enabled/default
    
    # Create Open SWE Nginx configuration
    if [[ -n "$DOMAIN" ]]; then
        create_nginx_domain_config
    else
        create_nginx_ip_config
    fi
    
    # Test Nginx configuration
    sudo nginx -t
    
    # Start and enable Nginx
    sudo systemctl start nginx
    sudo systemctl enable nginx
    
    log_success "Nginx installed and configured"
}

# Function to create Nginx config for domain
create_nginx_domain_config() {
    sudo tee /etc/nginx/sites-available/openswe > /dev/null <<EOF
server {
    listen 80;
    server_name $DOMAIN;
    
    # Redirect HTTP to HTTPS if SSL is enabled
    $(if [[ "$USE_SSL" == true ]]; then echo "return 301 https://\$server_name\$request_uri;"; fi)
    
    $(if [[ "$USE_SSL" != true ]]; then cat <<'INNER_EOF'
    # Web App
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Agent API
    location /api/agent/ {
        proxy_pass http://localhost:2024/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
INNER_EOF
fi)
}

$(if [[ "$USE_SSL" == true ]]; then cat <<'SSL_EOF'
server {
    listen 443 ssl http2;
    server_name $DOMAIN;
    
    # SSL configuration will be added by Certbot
    
    # Web App
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
    
    # Agent API
    location /api/agent/ {
        proxy_pass http://localhost:2024/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_cache_bypass $http_upgrade;
    }
}
SSL_EOF
fi)
EOF
    
    sudo ln -sf /etc/nginx/sites-available/openswe /etc/nginx/sites-enabled/
}

# Function to create Nginx config for IP
create_nginx_ip_config() {
    sudo tee /etc/nginx/sites-available/openswe > /dev/null <<EOF
server {
    listen 80 default_server;
    listen [::]:80 default_server;
    server_name $SERVER_IP _;
    
    # Web App
    location / {
        proxy_pass http://localhost:3000;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
    
    # Agent API
    location /api/agent/ {
        proxy_pass http://localhost:2024/;
        proxy_http_version 1.1;
        proxy_set_header Upgrade \$http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_cache_bypass \$http_upgrade;
    }
}
EOF
    
    sudo ln -sf /etc/nginx/sites-available/openswe /etc/nginx/sites-enabled/
}

# Function to setup SSL with Let's Encrypt
setup_ssl() {
    if [[ "$USE_SSL" == true && -n "$DOMAIN" ]]; then
        log_step "Setting up SSL Certificate with Let's Encrypt"
        
        # Install Certbot
        sudo apt install -y certbot python3-certbot-nginx
        
        # Get SSL certificate
        sudo certbot --nginx -d "$DOMAIN" --non-interactive --agree-tos --email "admin@$DOMAIN" --redirect
        
        # Setup auto-renewal
        sudo systemctl enable certbot.timer
        
        log_success "SSL certificate configured for $DOMAIN"
    fi
}

# Function to configure firewall
configure_firewall() {
    log_step "Configuring Firewall"
    
    # Enable UFW
    sudo ufw --force enable
    
    # Allow SSH
    sudo ufw allow ssh
    
    # Allow HTTP and HTTPS
    sudo ufw allow 80/tcp
    sudo ufw allow 443/tcp
    
    # Allow development ports (can be removed in production)
    sudo ufw allow 3000/tcp
    sudo ufw allow 2024/tcp
    
    log_success "Firewall configured"
}

# Function to detect local Open SWE installation
detect_local_openswe() {
    local current_dir=$(basename "$PWD")
    local parent_dir=$(basename "$(dirname "$PWD")")
    
    log_info "Checking for local Open SWE installation..."
    log_info "Current directory: $PWD"
    log_info "Directory name: $current_dir"
    
    # Check if current directory name contains "open-swe"
    if [[ "$current_dir" == *"open-swe"* ]] || [[ "$parent_dir" == *"open-swe"* ]]; then
        log_info "Directory name suggests Open SWE project, verifying structure..."
        
        # Verify it's actually an Open SWE project by checking for key files/directories
        if [[ -f "package.json" ]] && [[ -d "apps/open-swe" ]] && [[ -d "apps/web" ]]; then
            log_success "✅ Local Open SWE installation detected!"
            log_info "Found required files: package.json, apps/open-swe/, apps/web/"
            return 0  # Found local Open SWE
        else
            log_warning "Directory name suggests Open SWE but missing required structure"
            log_info "Required: package.json, apps/open-swe/, apps/web/"
        fi
    else
        log_info "Directory name doesn't suggest Open SWE project"
    fi
    
    log_info "No local Open SWE installation detected"
    return 1  # Not in Open SWE directory
}

# Function to create openswe user
create_user() {
    log_step "Creating Open SWE User"
    
    # Create user if it doesn't exist
    if ! id "$OPENSWE_USER" &>/dev/null; then
        sudo useradd -m -s /bin/bash "$OPENSWE_USER"
        sudo usermod -aG sudo "$OPENSWE_USER"
        log_success "Created user: $OPENSWE_USER"
    else
        log_info "User $OPENSWE_USER already exists"
    fi
}

# Function to clone and setup Open SWE
setup_openswe() {
    log_step "Setting up Open SWE Application"
    
    # Create directory and set permissions
    sudo mkdir -p "$OPENSWE_DIR"
    sudo chown "$OPENSWE_USER:$OPENSWE_USER" "$OPENSWE_DIR"
    
    # Check for local installation first
    if detect_local_openswe; then
        log_info "🏠 Using local Open SWE installation"
        log_info "Source directory: $PWD"
        log_info "Target directory: $OPENSWE_DIR"
        
        # Copy local files instead of cloning
        log_info "Copying local files to deployment directory..."
        sudo cp -r . "$OPENSWE_DIR/"
        
        # Set proper ownership
        sudo chown -R "$OPENSWE_USER:$OPENSWE_USER" "$OPENSWE_DIR"
        
        # Remove any existing .git directory to avoid conflicts
        sudo rm -rf "$OPENSWE_DIR/.git" 2>/dev/null || true
        
        log_success "✅ Local Open SWE files copied successfully"
        log_info "Installation method: Local copy"
    else
        log_info "🌐 No local Open SWE detected, cloning from GitHub..."
        
        # Clone repository (existing behavior)
        sudo -u "$OPENSWE_USER" git clone https://github.com/langchain-ai/open-swe.git "$OPENSWE_DIR"
        
        log_success "✅ Open SWE cloned from GitHub"
        log_info "Installation method: GitHub clone"
    fi
    
    # Change to directory
    cd "$OPENSWE_DIR"
    
    # Install dependencies
    log_info "Installing dependencies..."
    sudo -u "$OPENSWE_USER" yarn install
    
    log_success "Open SWE application setup complete"
}

# Function to create environment configuration
create_env_config() {
    log_step "Creating Environment Configuration"
    
    # Determine base URL
    if [[ -n "$DOMAIN" ]]; then
        if [[ "$USE_SSL" == true ]]; then
            BASE_URL="https://$DOMAIN"
        else
            BASE_URL="http://$DOMAIN"
        fi
    else
        BASE_URL="http://$SERVER_IP"
    fi
    
    # Determine API bearer token
    local api_token
    if [[ -n "$CUSTOM_API_BEARER_TOKEN" ]]; then
        api_token="$CUSTOM_API_BEARER_TOKEN"
    else
        api_token="$(openssl rand -hex 32)"
    fi
    
    # Create .env file
    sudo -u "$OPENSWE_USER" tee "$OPENSWE_DIR/.env" > /dev/null <<EOF
# ============================================================================
# 🚀 Open SWE Production Environment Configuration
# ============================================================================
# Generated by deployment script on $(date)
# Configuration: $(if [[ -n "$DOMAIN" ]]; then echo "Domain: $DOMAIN, SSL: $USE_SSL"; else echo "IP-only: $SERVER_IP"; fi)
# ============================================================================

# ============================================================================
# 🔐 SECURITY & AUTHENTICATION
# ============================================================================

# 👥 Access Control - Configured during deployment
NEXT_PUBLIC_ALLOWED_USERS_LIST='$ALLOWED_USERS_LIST'

# 🔑 API Bearer Token - $(if [[ -n "$CUSTOM_API_BEARER_TOKEN" ]]; then echo "Custom token"; else echo "Auto-generated secure token"; fi)
API_BEARER_TOKEN="$api_token"

# 🔐 Encryption Key - 32-byte hex string for AES-256 encryption
SECRETS_ENCRYPTION_KEY="$SECRETS_ENCRYPTION_KEY"

# ============================================================================
# 🐙 GITHUB APP CONFIGURATION
# ============================================================================

# 📱 GitHub App Basic Settings
GITHUB_APP_NAME="$GITHUB_APP_NAME"
GITHUB_APP_ID="$GITHUB_APP_ID"

# 🔑 GitHub App Authentication
NEXT_PUBLIC_GITHUB_APP_CLIENT_ID="$GITHUB_APP_CLIENT_ID"
GITHUB_APP_CLIENT_SECRET="$GITHUB_APP_CLIENT_SECRET"

# 🔐 GitHub App Private Key
GITHUB_APP_PRIVATE_KEY="$GITHUB_APP_PRIVATE_KEY"

# 🪝 GitHub Webhook Configuration
GITHUB_WEBHOOK_SECRET="$GITHUB_WEBHOOK_SECRET"
GITHUB_TRIGGER_USERNAME="$(whoami)"

# 🔄 GitHub App Redirect URI
GITHUB_APP_REDIRECT_URI="$BASE_URL/api/auth/github/callback"

# ============================================================================
# 🤖 LLM PROVIDER API KEYS
# ============================================================================

# 🧠 Anthropic (Claude) - Primary LLM provider
ANTHROPIC_API_KEY="$ANTHROPIC_API_KEY"

# 🤖 OpenAI (GPT models)
OPENAI_API_KEY="$OPENAI_API_KEY"

# 🔍 Google AI (Gemini models)
GOOGLE_API_KEY="$GOOGLE_API_KEY"

# ============================================================================
# 🌐 INFRASTRUCTURE & NETWORKING
# ============================================================================

# 🌍 Application URLs
OPEN_SWE_APP_URL="$BASE_URL"

# 🔗 API Configuration
NEXT_PUBLIC_API_URL="$BASE_URL/api"
LANGGRAPH_API_URL="http://localhost:2024"

# 🚪 Port Configuration
PORT="2024"

# 🌐 Environment Mode
NODE_ENV="production"

# ============================================================================
# 📊 MONITORING & TRACING
# ============================================================================

# 🔍 LangSmith Configuration
LANGCHAIN_PROJECT="$LANGCHAIN_PROJECT"
LANGCHAIN_API_KEY="$LANGCHAIN_API_KEY"
LANGCHAIN_TRACING_V2="true"
LANGCHAIN_TEST_TRACKING="false"

# ============================================================================
# 📋 LINEAR INTEGRATION (OPTIONAL)
# ============================================================================

$(if [[ -n "$LINEAR_API_KEY" ]]; then cat <<'LINEAR_EOF'
# 🔗 Linear API Configuration
LINEAR_API_KEY="$LINEAR_API_KEY"
LINEAR_WORKSPACE_ID="$LINEAR_WORKSPACE_ID"
LINEAR_WEBHOOK_SECRET="$LINEAR_WEBHOOK_SECRET"
$(if [[ -n "$LINEAR_TEAM_ID" ]]; then echo "LINEAR_TEAM_ID=\"$LINEAR_TEAM_ID\""; fi)
LINEAR_EOF
fi)

# ============================================================================
# 🛠️ EXTERNAL TOOLS & SERVICES
# ============================================================================

# 🕷️ Firecrawl - Web scraping and content extraction
FIRECRAWL_API_KEY="$FIRECRAWL_API_KEY"

# ☁️ Daytona - Cloud sandbox management
DAYTONA_API_KEY="$DAYTONA_API_KEY"

# ============================================================================
# ⚙️ APPLICATION CONFIGURATION
# ============================================================================

# 🚫 CI Skip Configuration
SKIP_CI_UNTIL_LAST_COMMIT="true"

# 🔧 Advanced Configuration
$(if [[ "$DEBUG_MODE" == true ]]; then echo "DEBUG=true"; fi)

# ============================================================================
# 🏠 LOCAL DEVELOPMENT & CLI
# ============================================================================

# 💻 CLI Configuration
OPEN_SWE_LOCAL_MODE="false"
OPEN_SWE_LOCAL_PROJECT_PATH=""
EOF
    
    # Set proper permissions
    sudo chmod 600 "$OPENSWE_DIR/.env"
    sudo chown "$OPENSWE_USER:$OPENSWE_USER" "$OPENSWE_DIR/.env"
    
    log_success "Environment configuration created"
}

# Function to create PM2 ecosystem file
create_pm2_config() {
    log_step "Creating PM2 Configuration"
    
    # Determine instances for clustering
    local web_instances=1
    local agent_instances=1
    if [[ "$ENABLE_CLUSTERING" == true ]]; then
        web_instances="max"
        agent_instances="max"
        log_info "PM2 clustering enabled - using max instances"
    fi
    
    sudo -u "$OPENSWE_USER" tee "$OPENSWE_DIR/ecosystem.config.js" > /dev/null <<EOF
module.exports = {
  apps: [
    {
      name: 'openswe-web',
      cwd: '$OPENSWE_DIR/apps/web',
      script: 'yarn',
      args: 'start',
      env: {
        NODE_ENV: 'production',
        PORT: 3000$(if [[ "$DEBUG_MODE" == true ]]; then echo ",
        DEBUG: 'true'"; fi)
      },
      instances: $web_instances,
      autorestart: true,
      watch: false,
      max_memory_restart: '$MEMORY_LIMIT',
      error_file: '$OPENSWE_DIR/logs/web-error.log',
      out_file: '$OPENSWE_DIR/logs/web-out.log',
      log_file: '$OPENSWE_DIR/logs/web-combined.log',
      time: true,
      merge_logs: true
    },
    {
      name: 'openswe-agent',
      cwd: '$OPENSWE_DIR/apps/open-swe',
      script: 'yarn',
      args: 'start',
      env: {
        NODE_ENV: 'production',
        PORT: 2024$(if [[ "$DEBUG_MODE" == true ]]; then echo ",
        DEBUG: 'true'"; fi)
      },
      instances: $agent_instances,
      autorestart: true,
      watch: false,
      max_memory_restart: '$MEMORY_LIMIT',
      error_file: '$OPENSWE_DIR/logs/agent-error.log',
      out_file: '$OPENSWE_DIR/logs/agent-out.log',
      log_file: '$OPENSWE_DIR/logs/agent-combined.log',
      time: true,
      merge_logs: true
    }
  ]
};
EOF
    
    # Create logs directory
    sudo -u "$OPENSWE_USER" mkdir -p "$OPENSWE_DIR/logs"
    
    log_success "PM2 configuration created with memory limit: $MEMORY_LIMIT, clustering: $ENABLE_CLUSTERING"
}

# Function to build applications
build_applications() {
    log_step "Building Applications"
    
    cd "$OPENSWE_DIR"
    
    # Build web app
    log_info "Building web application..."
    sudo -u "$OPENSWE_USER" bash -c "cd apps/web && yarn build"
    
    # Build agent (if needed)
    log_info "Building agent application..."
    sudo -u "$OPENSWE_USER" bash -c "cd apps/open-swe && yarn build || true"
    
    log_success "Applications built successfully"
}

# Function to start services
start_services() {
    log_step "Starting Services"
    
    cd "$OPENSWE_DIR"
    
    # Start PM2 processes
    sudo -u "$OPENSWE_USER" pm2 start ecosystem.config.js
    
    # Save PM2 configuration
    sudo -u "$OPENSWE_USER" pm2 save
    
    # Restart Nginx
    sudo systemctl restart nginx
    
    log_success "Services started successfully"
}

# Function to run health checks
run_health_checks() {
    log_step "Running Health Checks"
    
    sleep 10  # Wait for services to start
    
    # Check web app
    if curl -f -s "$BASE_URL" > /dev/null; then
        log_success "✅ Web application is responding"
    else
        log_error "❌ Web application is not responding"
    fi
    
    # Check agent
    if curl -f -s "http://localhost:2024/health" > /dev/null 2>&1; then
        log_success "✅ Agent service is responding"
    else
        log_warning "⚠️  Agent service health check failed (this may be normal)"
    fi
    
    # Check Nginx
    if sudo systemctl is-active --quiet nginx; then
        log_success "✅ Nginx is running"
    else
        log_error "❌ Nginx is not running"
    fi
    
    # Check PM2 processes
    if sudo -u "$OPENSWE_USER" pm2 list | grep -q "online"; then
        log_success "✅ PM2 processes are running"
    else
        log_error "❌ PM2 processes are not running"
    fi
}

# Function to display final information
display_final_info() {
    log_step "Deployment Complete!"
    
    echo -e "${GREEN}🎉 Open SWE has been successfully deployed!${NC}"
    echo ""
    echo -e "${CYAN}📋 Deployment Summary:${NC}"
    echo "  • Application URL: $BASE_URL"
    echo "  • Installation Directory: $OPENSWE_DIR"
    echo "  • User: $OPENSWE_USER"
    echo "  • SSL Enabled: $USE_SSL"
    
    # Show installation method used
    if detect_local_openswe; then
        echo "  • Installation Method: 🏠 Local copy (from $PWD)"
    else
        echo "  • Installation Method: 🌐 GitHub clone"
    fi
    
    echo ""
    echo -e "${CYAN}🔧 Management Commands:${NC}"
    echo "  • View logs: sudo -u $OPENSWE_USER pm2 logs"
    echo "  • Restart services: sudo -u $OPENSWE_USER pm2 restart all"
    echo "  • Stop services: sudo -u $OPENSWE_USER pm2 stop all"
    echo "  • Check status: sudo -u $OPENSWE_USER pm2 status"
    echo ""
    echo -e "${CYAN}🐙 GitHub App Configuration:${NC}"
    echo "  • Update your GitHub App webhook URL to: $BASE_URL/webhook/github"
    echo "  • Webhook secret: $GITHUB_WEBHOOK_SECRET"
    echo ""
    echo -e "${YELLOW}⚠️  Important Notes:${NC}"
    echo "  • Update the NEXT_PUBLIC_ALLOWED_USERS_LIST in $OPENSWE_DIR/.env"
    echo "  • Configure your GitHub App with the webhook URL above"
    echo "  • Monitor logs for any issues: sudo -u $OPENSWE_USER pm2 logs"
    echo ""
    echo -e "${GREEN}🚀 Your Open SWE instance is ready to use!${NC}"
}

# Main deployment function
main() {
    echo -e "${PURPLE}"
    echo "============================================"
    echo "🚀 Open SWE DigitalOcean Droplet Deployment"
    echo "============================================"
    echo -e "${NC}"
    
    check_root
    check_system
    collect_config
    update_system
    install_nodejs
    install_pm2
    configure_firewall
    create_user
    install_nginx
    setup_ssl
    setup_openswe
    create_env_config
    create_pm2_config
    build_applications
    start_services
    run_health_checks
    display_final_info
}

# Run main function
main "$@"
