#!/bin/bash
# Comprehensive VPS Hardening Script with Custom Banner and Color-Coded Prompts

# Define colors for text
GREEN='\033[0;32m'
RED='\033[0;31m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

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

# Prompt user for confirmation
function confirm() {
    echo -e "${CYAN}$1 (y/n):${NC}"
    read -r response
    [[ "$response" =~ ^[Yy]$ ]]
}

# Step 1: Update and upgrade the system
function update_system() {
    if confirm "Do you want to update and upgrade the system packages?"; then
        echo -e "${GREEN}Updating system...${NC}"
        sudo apt update && sudo apt upgrade -y
    fi
}

# Step 2: Create a new user
function setup_user() {
    if confirm "Would you like to create a new user with sudo privileges?"; then
        echo -e "${CYAN}Enter new username:${NC}"
        read -r new_user
        sudo adduser "$new_user"
        sudo usermod -aG sudo "$new_user"
        echo -e "${GREEN}User $new_user created and granted sudo privileges.${NC}"
    fi
}

# Step 3: SSH configuration
function configure_ssh() {
    if confirm "Do you want to configure SSH for added security?"; then
        echo -e "${CYAN}Enter a custom SSH port (e.g., 2022):${NC}"
        read -r ssh_port
        sudo sed -i "s/#Port 22/Port $ssh_port/" /etc/ssh/sshd_config
        sudo sed -i "s/PermitRootLogin yes/PermitRootLogin no/" /etc/ssh/sshd_config
        sudo sed -i "s/#PasswordAuthentication yes/PasswordAuthentication no/" /etc/ssh/sshd_config
        sudo systemctl restart sshd
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
        echo -e "${GREEN}fail2ban and AIDE installed and configured.${NC}"
    fi
}

# Step 6: Disable IPv6
function disable_ipv6() {
    if confirm "Disable IPv6 for additional security?"; then
        echo -e "${GREEN}Disabling IPv6...${NC}"
        echo "net.ipv6.conf.all.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv6.conf.default.disable_ipv6 = 1" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
        echo -e "${GREEN}IPv6 has been disabled.${NC}"
    fi
}

# Step 7: Secure shared memory
function secure_shared_memory() {
    if confirm "Secure shared memory (helps prevent certain exploits)?"; then
        echo -e "${GREEN}Securing shared memory...${NC}"
        echo "tmpfs /run/shm tmpfs defaults,noexec,nosuid 0 0" | sudo tee -a /etc/fstab
        sudo mount -o remount /run/shm
        echo -e "${GREEN}Shared memory secured.${NC}"
    fi
}

# Step 8: Limit login attempts
function limit_login_attempts() {
    if confirm "Limit login attempts to prevent brute force attacks?"; then
        echo -e "${GREEN}Limiting login attempts...${NC}"
        echo "auth required pam_tally2.so deny=5 onerr=fail unlock_time=600" | sudo tee -a /etc/pam.d/common-auth
        echo -e "${GREEN}Login attempts limited to 5, with a 10-minute lockout.${NC}"
    fi
}

# Step 9: Enable automatic security updates
function auto_security_updates() {
    if confirm "Enable automatic security updates?"; then
        sudo apt install unattended-upgrades -y
        sudo dpkg-reconfigure --priority=low unattended-upgrades
        echo -e "${GREEN}Automatic security updates enabled.${NC}"
    fi
}

# Step 10: Kernel Hardening using sysctl
function kernel_hardening() {
    if confirm "Apply kernel hardening settings?"; then
        echo -e "${GREEN}Applying kernel hardening...${NC}"
        echo "net.ipv4.conf.all.rp_filter = 1" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.default.rp_filter = 1" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.all.accept_source_route = 0" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.default.accept_source_route = 0" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.all.accept_redirects = 0" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.default.accept_redirects = 0" | sudo tee -a /etc/sysctl.conf
        echo "net.ipv4.conf.all.log_martians = 1" | sudo tee -a /etc/sysctl.conf
        sudo sysctl -p
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