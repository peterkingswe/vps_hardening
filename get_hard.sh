#!/bin/bash
# Comprehensive and Robust VPS Hardening Script with Custom Banner, Error Handling, and Validation

# Define colors for text
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Ensure the script is run as root
if [[ $EUID -ne 0 ]]; then
    echo -e "${RED}This script must be run as root. Please try again with 'sudo'.${NC}"
    exit 1
fi

# Custom Banner
function display_banner() {
    echo -e "${CYAN}"
    echo -e "############################################################"
    echo -e "#                                                          #"
    echo -e "#                WELCOME TO KING'S VPS HARDENING           #"
    echo -e "#                                                          #"
    echo -e "############################################################"
    echo -e "${NC}"
}

# Prompt user for confirmation with a default 'no' response for safety
function confirm() {
    echo -e "${CYAN}$1 (y/N):${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Helper to check command success
function check_command() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}$1 succeeded.${NC}"
    else
        echo -e "${RED}$1 failed. Exiting...${NC}"
        exit 1
    fi
}

# Step 1: Update and upgrade the system
function update_system() {
    if confirm "Do you want to update and upgrade the system packages?"; then
        echo -e "${GREEN}Updating system...${NC}"
        sudo apt update && sudo apt upgrade -y
        check_command "System update and upgrade"
    fi
}

# Step 2: Create a new user
function setup_user() {
    if confirm "Would you like to create a new user with sudo privileges?"; then
        while true; do
            echo -e "${CYAN}Enter new username:${NC}"
            read -r new_user
            if id "$new_user" &>/dev/null; then
                echo -e "${YELLOW}User $new_user already exists. Please choose a different username.${NC}"
            else
                sudo adduser "$new_user"
                sudo usermod -aG sudo "$new_user"
                check_command "User creation and sudo privileges setup"
                break
            fi
        done
    fi
}

# Step 3: SSH configuration with verification
function configure_ssh() {
    if confirm "Do you want to configure SSH for added security?"; then
        while true; do
            echo -e "${CYAN}Enter a custom SSH port (e.g., 2022):${NC}"
            read -r ssh_port
            if [[ $ssh_port =~ ^[0-9]+$ ]] && [ "$ssh_port" -ge 1024 ] && [ "$ssh_port" -le 65535 ]; then
                sudo sed -i "s/#Port 22/Port $ssh_port/" /etc/ssh/sshd_config
                sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
                sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config

                # Validate sshd configuration before restarting
                if sudo sshd -t; then
                    echo -e "${GREEN}SSH configuration is valid. Proceeding to restart sshd.${NC}"
                    if confirm "Are you sure you want to restart sshd? This may disconnect your session."; then
                        sudo systemctl restart sshd
                        check_command "SSH daemon restart"
                    else
                        echo -e "${YELLOW}Skipping SSH restart. Changes will apply on next restart.${NC}"
                    fi
                else
                    echo -e "${RED}SSH configuration test failed. Please check /etc/ssh/sshd_config for errors.${NC}"
                fi
                break
            else
                echo -e "${YELLOW}Invalid port. Please enter a number between 1024 and 65535.${NC}"
            fi
        done
        echo -e "${GREEN}SSH configured. Root login disabled, password authentication off, and port changed to $ssh_port.${NC}"
    fi
}

# Step 4: Set up the firewall with UFW
function setup_firewall() {
    if confirm "Would you like to set up UFW firewall?"; then
        sudo ufw allow "$ssh_port"
        sudo ufw allow 80
        sudo ufw allow 443
        sudo ufw enable
        check_command "UFW firewall setup"
        echo -e "${GREEN}Firewall configured to allow HTTP, HTTPS, and SSH on port $ssh_port.${NC}"
    fi
}

# Step 5: Install security tools
function install_security_tools() {
    if confirm "Install security tools (fail2ban, AIDE)?"; then
        sudo apt install fail2ban aide -y
        sudo aideinit
        sudo systemctl enable fail2ban
        sudo systemctl start fail2ban
        check_command "Security tools installation"
        echo -e "${GREEN}fail2ban and AIDE installed and configured.${NC}"
    fi
}

# Step 6: Disable IPv6
function disable_ipv6() {
    if confirm "Disable IPv6 for additional security?"; then
        echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
        check_command "IPv6 disablement"
        echo -e "${GREEN}IPv6 has been disabled.${NC}"
    fi
}

# Step 7: Secure shared memory
function secure_shared_memory() {
    if confirm "Secure shared memory (helps prevent certain exploits)?"; then
        echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0" | sudo tee -a /etc/fstab
        sudo mount -o remount /run/shm
        check_command "Shared memory securing"
        echo -e "${GREEN}Shared memory secured.${NC}"
    fi
}

# Step 8: Limit login attempts
function limit_login_attempts() {
    if confirm "Limit login attempts to prevent brute force attacks?"; then
        echo "auth required pam_tally2.so deny=5 onerr=fail unlock_time=600" | sudo tee -a /etc/pam.d/common-auth
        check_command "Login attempt limitations"
        echo -e "${GREEN}Login attempts limited to 5, with a 10-minute lockout.${NC}"
    fi
}

# Step 9: Enable automatic security updates
function auto_security_updates() {
    if confirm "Enable automatic security updates?"; then
        sudo apt install unattended-upgrades -y
        sudo dpkg-reconfigure --priority=low unattended-upgrades
        check_command "Automatic security updates setup"
        echo -e "${GREEN}Automatic security updates enabled.${NC}"
    fi
}

# Step 10: Kernel Hardening using sysctl
function kernel_hardening() {
    if confirm "Apply kernel hardening settings?"; then
        echo "net.ipv4.conf.all.rp_filter = 1" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.default.rp_filter = 1" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.all.accept_source_route = 0" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.default.accept_source_route = 0" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.all.accept_redirects = 0" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.default.accept_redirects = 0" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.all.log_martians = 1" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
        check_command "Kernel hardening"
        echo -e "${GREEN}Kernel hardening applied.${NC}"
    fi
}

# Run all hardening steps
display_banner
update_system
setup_user
configure_ssh
setup_firewall
install_security_tools
disable_ipv6
secure_shared_memory
limit_login_attempts
auto_security_updates
kernel_hardening

echo -e "${GREEN}Comprehensive VPS hardening steps completed.${NC}"