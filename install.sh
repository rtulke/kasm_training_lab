#!/bin/bash
# Author: Robert Tulke (rt@debian.sh)

# Global variables
SOURCES_LIST="/etc/apt/sources.list"
REQUIRED_PKGS="tree ansible git"
TAG="installer"
REPO_URL="https://github.com/rtulke/kasm_training_lab.git"
REPO_DIR="/tmp/kasm_training_lab"
PLAYBOOK="main_install.yaml"
VERSION="1.1.0"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Helper function for logging
log_message() {
    local MESSAGE="$1"
    local PRIORITY="$2"
    
    # Default to info if no priority specified
    [ -z "$PRIORITY" ] && PRIORITY="info"
    
    logger -t "$TAG" -p "user.$PRIORITY" "$MESSAGE"
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $MESSAGE"
}

# Function to show welcome screen
show_welcome() {
    clear
    echo -e "${BLUE}============================================${NC}"
    echo -e "${GREEN}        KASM TRAINING LAB INSTALLER        ${NC}"
    echo -e "${BLUE}============================================${NC}"
    echo
    echo -e "This script installs a ${GREEN}KASM Training Lab${NC}"
    echo -e "with GitLab and Ansible Workspaces for training purposes."
    echo
    echo -e "Version: ${YELLOW}${VERSION}${NC}"
    echo -e "Repository: ${YELLOW}${REPO_URL}${NC}"
    echo
    echo -e "${BLUE}============================================${NC}"
    echo
}

# Function to display help
show_help() {
    echo -e "${GREEN}KASM Training Lab - Help${NC}"
    echo
    echo -e "Usage: $0 [OPTIONS]"
    echo
    echo -e "Options:"
    echo -e "  ${YELLOW}--download-only${NC}   Only downloads the repository without installation"
    echo -e "  ${YELLOW}--full-install${NC}    Performs a complete installation"
    echo -e "  ${YELLOW}--help${NC}            Displays this help information"
    echo
    echo -e "Without options, the script starts in interactive mode."
    echo
    echo -e "Description:"
    echo -e "  This script sets up a KASM environment with GitLab and"
    echo -e "  Ansible Workspaces for training purposes."
    echo -e "  It configures the Debian environment, installs KASM,"
    echo -e "  and sets up the required containers."
    echo
}

# Function to check for root privileges
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        log_message "ERROR: This script must be run as root" "err"
        echo -e "\n${RED}ERROR:${NC} This script must be run as root."
        echo -e "Try: ${YELLOW}sudo $0${NC}\n"
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
    echo -e "\n${BLUE}Updating package lists...${NC}"
    apt update -y
    if [ $? -ne 0 ]; then
        log_message "Failed to update package lists" "err"
        echo -e "\n${RED}ERROR:${NC} Failed to update package lists.\n"
        exit 1
    fi
    
    log_message "Installing required packages: $REQUIRED_PKGS"
    echo -e "\n${BLUE}Installing required packages: ${YELLOW}$REQUIRED_PKGS${NC}"
    apt install -y $REQUIRED_PKGS
    if [ $? -ne 0 ]; then
        log_message "Failed to install packages" "err"
        echo -e "\n${RED}ERROR:${NC} Failed to install packages.\n"
        exit 1
    fi
    
    # Check if installation was successful
    for PKG in $REQUIRED_PKGS; do
        if dpkg -l | grep -q "^ii  $PKG "; then
            log_message "$PKG installed successfully"
            echo -e "${GREEN}✓${NC} $PKG successfully installed"
        else
            log_message "ERROR: Failed to install $PKG" "err"
            echo -e "${RED}✗${NC} Failed to install $PKG"
            exit 1
        fi
    done
}

# Function to clone the repository
clone_repository() {
    log_message "Cloning repository: $REPO_URL"
    echo -e "\n${BLUE}Cloning repository: ${YELLOW}$REPO_URL${NC}"
    
    # Remove existing directory if it exists
    if [ -d "$REPO_DIR" ]; then
        log_message "Removing existing repository directory"
        echo -e "${YELLOW}Removing existing repository directory...${NC}"
        rm -rf "$REPO_DIR"
    fi
    
    # Clone the repository
    git clone "$REPO_URL" "$REPO_DIR"
    if [ $? -ne 0 ]; then
        log_message "Failed to clone repository" "err"
        echo -e "\n${RED}ERROR:${NC} Failed to clone repository.\n"
        exit 1
    fi
    
    log_message "Repository cloned successfully to $REPO_DIR"
    echo -e "${GREEN}✓${NC} Repository successfully cloned to $REPO_DIR"
}

# Function to run Ansible playbook
run_ansible_playbook() {
    log_message "Running Ansible playbook: $PLAYBOOK"
    echo -e "\n${BLUE}Running Ansible playbook: ${YELLOW}$PLAYBOOK${NC}"
    
    # Change to repository directory
    cd "$REPO_DIR"
    if [ $? -ne 0 ]; then
        log_message "Failed to change to repository directory" "err"
        echo -e "\n${RED}ERROR:${NC} Failed to change to repository directory.\n"
        exit 1
    fi
    
    # Check if playbook exists
    if [ ! -f "$PLAYBOOK" ]; then
        log_message "Playbook $PLAYBOOK not found in repository" "err"
        echo -e "\n${RED}ERROR:${NC} Playbook $PLAYBOOK not found in repository.\n"
        exit 1
    fi
    
    # Run the playbook
    ansible-playbook "$PLAYBOOK"
    if [ $? -ne 0 ]; then
        log_message "Failed to run Ansible playbook" "err"
        echo -e "\n${RED}ERROR:${NC} Failed to run Ansible playbook.\n"
        exit 1
    fi
    
    log_message "Ansible playbook executed successfully"
    echo -e "${GREEN}✓${NC} Ansible playbook executed successfully"
}

# Function to execute download-only mode
do_download_only() {
    log_message "Starting download-only process"
    check_root
    clone_repository
    echo -e "\n${GREEN}Download completed.${NC} Repository is located at $REPO_DIR\n"
}

# Function to execute full installation mode
do_full_install() {
    log_message "Starting installation script"
    check_root
    create_sources_list
    install_packages
    
    # Display versions
    echo -e "\n${BLUE}Installed versions:${NC}"
    tree --version
    ansible --version | head -n 1
    
    # Clone repository and run Ansible playbook
    clone_repository
    run_ansible_playbook
    
    log_message "Installation and configuration complete"
    echo -e "\n${GREEN}Installation and configuration completed.${NC}"
    echo -e "\nThe KASM Training Lab is now ready to use!"
    echo -e "Access via: ${YELLOW}https://$(hostname -I | awk '{print $1}'):8443${NC}"
    echo -e "${BLUE}============================================${NC}"
}

# Interactive menu function
interactive_menu() {
    show_welcome
    
    while true; do
        echo -e "Please select an option:"
        echo
        echo -e "  ${YELLOW}1)${NC} Download KASM Training Lab Repository from GitHub"
        echo -e "  ${YELLOW}2)${NC} Install KASM Training Lab (Full Installation)"
        echo -e "  ${YELLOW}3)${NC} Display Help"
        echo -e "  ${YELLOW}4)${NC} Cancel"
        echo
        echo -n "Your choice [1-4]: "
        read choice
        
        case "$choice" in
            1)
                do_download_only
                exit 0
                ;;
            2)
                do_full_install
                exit 0
                ;;
            3)
                clear
                show_help
                echo -e "\nPress Enter to return to the menu..."
                read
                clear
                # Show welcome screen again for consistency
                show_welcome
                ;;
            4)
                echo -e "\nInstallation ${RED}cancelled${NC}."
                exit 0
                ;;
            *)
                echo -e "\n${RED}Invalid selection${NC}. Please choose 1-4."
                echo -e "Press Enter to continue..."
                read
                clear
                show_welcome
                ;;
        esac
    done
}

# Main function
main() {
    # Process command line arguments if provided
    if [ $# -gt 0 ]; then
        case "$1" in
            --download-only)
                log_message "Download-only mode selected via command line"
                do_download_only
                ;;
            --full-install)
                log_message "Full installation mode selected via command line"
                do_full_install
                ;;
            --help)
                show_help
                ;;
            *)
                echo -e "${RED}Invalid option:${NC} $1"
                show_help
                exit 1
                ;;
        esac
    else
        # No args provided, show interactive menu
        interactive_menu
    fi
}

# Execute script with all provided arguments
main "$@"
