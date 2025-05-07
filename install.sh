#!/bin/bash
# Author: Robert Tulke (rt@debian.sh)

# Global variables
SOURCES_LIST="/etc/apt/sources.list"
REQUIRED_PKGS="tree ansible git"
TAG="installer"
REPO_URL="https://github.com/rtulke/kasm_training_lab.git"
REPO_DIR="/tmp/kasm_training_lab"
PLAYBOOK="main_install.yaml"

# Helper function for logging
log_message() {
    local MESSAGE="$1"
    local PRIORITY="$2"
    
    # Default to info if no priority specified
    [ -z "$PRIORITY" ] && PRIORITY="info"
    
    logger -t "$TAG" -p "user.$PRIORITY" "$MESSAGE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MESSAGE"
}

# Function to check for root privileges
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_message "ERROR: This script must be run as root" "err"
        exit 1
    fi
}

# Function to create sources.list
create_sources_list() {
    log_message "Creating sources.list file"
    
    # Create backup of existing file
    if [ -f "$SOURCES_LIST" ]; then
        cp "$SOURCES_LIST" "${SOURCES_LIST}.bak"
        log_message "Backup of sources.list created at ${SOURCES_LIST}.bak"
    fi
    
    # Create new sources.list
    cat > "$SOURCES_LIST" << 'EOF'
# Debian 12 (Bookworm) repository
deb http://deb.debian.org/debian bookworm main contrib non-free-firmware
deb-src http://deb.debian.org/debian bookworm main contrib non-free-firmware

# Debian 12 security updates
deb http://security.debian.org/debian-security bookworm-security main contrib non-free-firmware
deb-src http://security.debian.org/debian-security bookworm-security main contrib non-free-firmware

# Debian 12 updates
deb http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware
deb-src http://deb.debian.org/debian bookworm-updates main contrib non-free-firmware
EOF
    
    log_message "sources.list file created successfully"
}

# Function to install packages
install_packages() {
    log_message "Updating package lists"
    apt update -y || {
        log_message "Failed to update package lists" "err"
        exit 1
    }
    
    log_message "Installing required packages: $REQUIRED_PKGS"
    apt install -y $REQUIRED_PKGS || {
        log_message "Failed to install packages" "err"
        exit 1
    }
    
    # Check if installation was successful
    for PKG in $REQUIRED_PKGS; do
        if dpkg -l | grep -q "^ii  $PKG "; then
            log_message "$PKG installed successfully"
        else
            log_message "ERROR: Failed to install $PKG" "err"
            exit 1
        fi
    done
}

# Function to clone the repository
clone_repository() {
    log_message "Cloning repository: $REPO_URL"
    
    # Remove existing directory if it exists
    if [ -d "$REPO_DIR" ]; then
        log_message "Removing existing repository directory"
        rm -rf "$REPO_DIR"
    fi
    
    # Clone the repository
    git clone "$REPO_URL" "$REPO_DIR" || {
        log_message "Failed to clone repository" "err"
        exit 1
    }
    
    log_message "Repository cloned successfully to $REPO_DIR"
}

# Function to run Ansible playbook
run_ansible_playbook() {
    log_message "Running Ansible playbook: $PLAYBOOK"
    
    # Change to repository directory
    cd "$REPO_DIR" || {
        log_message "Failed to change to repository directory" "err"
        exit 1
    }
    
    # Check if playbook exists
    if [ ! -f "$PLAYBOOK" ]; then
        log_message "Playbook $PLAYBOOK not found in repository" "err"
        exit 1
    }
    
    # Run the playbook
    ansible-playbook "$PLAYBOOK" || {
        log_message "Failed to run Ansible playbook" "err"
        exit 1
    }
    
    log_message "Ansible playbook executed successfully"
}

# Main function
main() {
    log_message "Starting installation script"
    check_root
    create_sources_list
    install_packages
    
    # Display versions
    echo "Installed versions:"
    tree --version
    ansible --version | head -n 1
    
    # Clone repository and run Ansible playbook
    clone_repository
    run_ansible_playbook
    
    log_message "Installation and configuration complete"
}

# Execute script
main
