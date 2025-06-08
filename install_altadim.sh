#!/bin/bash

# --- Error Handling ---

# Exit immediately if a command exits with a non-zero status.
set -e
# Treat unset variables as an error when substituting.
set -u
# Exit if any command in a pipeline fails.
set -o pipefail

# Define log file
LOG_FILE="$HOME/ubuntu_setup_$(date +%Y%m%d_%H%M%S).log"

# Function to log messages to console and log file
log() {
    echo "$(date +'%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

error_exit() {
    log "ERROR: $1"
    exit 1
}

# Check if the script is run with root privileges
if [[ $EUID -ne 0 ]]; then
    error_exit "This script must be run with sudo or as root. Please run 'sudo ./khaldoun-setup.sh'"
fi

# Store the original user who invoked sudo
# This is crucial for operations that need to run as the regular user (e.g., Git cloning with SSH keys)
ORIGINAL_USER="$SUDO_USER"
if [ -z "$ORIGINAL_USER" ]; then
    error_exit "Could not determine the original user who invoked sudo. Please ensure SUDO_USER is set."
fi
log "Script invoked by user: $ORIGINAL_USER"

# Determine Ubuntu version for conditional installations
UBUNTU_VERSION=$(lsb_release -rs)
log "Detected Ubuntu Version: $UBUNTU_VERSION"

# --- Helper Functions ---

# Function to install multiple APT packages
install_apt_packages() {
    local packages=("$@")
    log "Installing APT packages: ${packages[*]}"
    sudo apt install -y "${packages[@]}" || error_exit "Failed to install APT packages."
}

# Function to install a Snap package, checking if it's already installed
install_snap_package() {
    local package_name="$1"
    local classic_flag="$2" # Can be "--classic" or empty
    log "Installing Snap package: $package_name $classic_flag"
    if ! snap list | grep -q "^$package_name "; then
        sudo snap install "$package_name" "$classic_flag" || error_exit "Failed to install Snap package $package_name."
    else
        log "$package_name is already installed. Skipping installation."
    fi
}

# Function to configure Git's global credential helper for the original user
configure_git() {
    log "Configuring Git global credential helper for user $ORIGINAL_USER."
    sudo -u "$ORIGINAL_USER" git config --global credential.helper store || error_exit "Failed to configure Git credential helper for user $ORIGINAL_USER."
}

# Function to set up a Python project using SSH for Git cloning
setup_python_project_ssh() {
    local repo_ssh_url="$1"
    local project_name="$2"
    local venv_dir="/home/$ORIGINAL_USER/virtualenvs/$project_name"
    local project_dir="/home/$ORIGINAL_USER/programming/$project_name" # Corrected typo here

    log "Setting up Python project (SSH) for user $ORIGINAL_USER: $project_name from $repo_ssh_url"

    # Clone the repository if it doesn't already exist, as ORIGINAL_USER
    if [ ! -d "$project_dir" ]; then
        sudo -u "$ORIGINAL_USER" git clone "$repo_ssh_url" "$project_dir" || error_exit "Failed to clone $repo_ssh_url via SSH for user $ORIGINAL_USER. Ensure their SSH key is set up with the Git provider (e.g., GitHub)."
    else
        log "Repository $project_name already exists. Skipping clone."
        # Optional: Uncomment the line below if you want to pull latest changes
        # sudo -u "$ORIGINAL_USER" (cd "$project_dir" && git pull) || log "Could not pull latest for $project_name."
    fi

    # Create the virtual environment if it doesn't already exist, as ORIGINAL_USER
    if [ ! -d "$venv_dir" ]; then
        sudo -u "$ORIGINAL_USER" python3 -m venv "$venv_dir" || error_exit "Failed to create virtual environment for $project_name for user $ORIGINAL_USER."
    else
        log "Virtual environment for $project_name already exists. Skipping creation."
    fi

    # Install Python requirements within the virtual environment, as ORIGINAL_USER
    log "Installing Python requirements for $project_name for user $ORIGINAL_USER."
    # Ensure pip, setuptools, and wheel are up-to-date in the venv
    sudo -u "$ORIGINAL_USER" "$venv_dir/bin/pip" install --upgrade pip setuptools wheel || log "Failed to upgrade pip/setuptools/wheel in $project_name venv for user $ORIGINAL_USER."
    # Install requirements from requirements.txt if the file exists
    if [ -f "$project_dir/requirements.txt" ]; then
        sudo -u "$ORIGINAL_USER" "$venv_dir/bin/pip" install -r "$project_dir/requirements.txt" || error_exit "Failed to install requirements for $project_name for user $ORIGINAL_USER."
    else
        log "No requirements.txt found for $project_name. Skipping pip install -r."
    fi
}

# Function to install the latest release of a GitHub binary (e.g., lazygit, lazydocker)
install_latest_github_release() {
    local repo="$1"        # e.g., "jesseduffield/lazygit"
    local binary_name="$2" # e.g., "lazygit"
    local install_path="/usr/local/bin" # Standard path for local binaries

    log "Installing latest $binary_name from $repo"
    local latest_version
    # Fetch the latest release tag name
    latest_version=$(curl -s "https://api.github.com/repos/$repo/releases/latest" | grep -Po '"tag_name": "v\K[^"]*')
    if [ -z "$latest_version" ]; then
        error_exit "Could not determine latest version for $binary_name from $repo."
    fi

    local download_url="https://github.com/$repo/releases/latest/download/${binary_name}_${latest_version}_Linux_x86_64.tar.gz"
    local temp_tar_file="${binary_name}.tar.gz"
    local temp_dir="${binary_name}-temp"

    log "Downloading $binary_name from $download_url"
    # Use sudo -u "$ORIGINAL_USER" to download to the user's home or a temp dir they own
    sudo -u "$ORIGINAL_USER" curl -fsSLo "/home/$ORIGINAL_USER/$temp_tar_file" "$download_url" || error_exit "Failed to download $binary_name."

    # Create temp dir as ORIGINAL_USER
    sudo -u "$ORIGINAL_USER" mkdir -p "/home/$ORIGINAL_USER/$temp_dir" || error_exit "Failed to create temporary directory $temp_dir for user $ORIGINAL_USER."
    # Extract as ORIGINAL_USER
    sudo -u "$ORIGINAL_USER" tar xf "/home/$ORIGINAL_USER/$temp_tar_file" -C "/home/$ORIGINAL_USER/$temp_dir" || error_exit "Failed to extract $temp_tar_file for user $ORIGINAL_USER."

    # Move the extracted binary to the install path (this still needs sudo as it's /usr/local/bin)
    if [ -f "/home/$ORIGINAL_USER/$temp_dir/$binary_name" ]; then
        sudo mv "/home/$ORIGINAL_USER/$temp_dir/$binary_name" "$install_path/" || error_exit "Failed to move $binary_name to $install_path."
        sudo chmod +x "$install_path/$binary_name" # Make the binary executable
        log "$binary_name installed successfully to $install_path."
    else
        error_exit "Expected binary '$binary_name' not found in extracted directory '/home/$ORIGINAL_USER/$temp_dir'."
    fi

    # Clean up temporary files, as ORIGINAL_USER
    sudo -u "$ORIGINAL_USER" rm -rf "/home/$ORIGINAL_USER/$temp_tar_file" "/home/$ORIGINAL_USER/$temp_dir" || log "WARNING: Failed to clean up temporary files for $binary_name for user $ORIGINAL_USER."
}

# --- Main Installation Logic ---

main() {
    log "Starting Ubuntu Development Environment Setup Script."
    log "This script will install various development tools and configure your system."
    log "Please ensure you have an active internet connection."

    # 1. System Update and Upgrade
    log "--- Section 1: System Update and Upgrade ---"
    log "Updating and upgrading system packages. This may take some time."
    sudo apt update -y || error_exit "APT update failed."
    sudo apt upgrade -y || error_exit "APT upgrade failed."
    log "System packages updated and upgraded."

    # 2. Install Core Applications via APT
    log "--- Section 2: Installing Core APT Packages ---"
    CORE_APT_PACKAGES=(
        "snapd"
        "gthumb"
        "python3-pip"
        "postgresql"
        "sqlite3"
        "tmux"
        "docker-compose"
        "docker.io"
        "alacritty"
        "htop"
        "pre-commit"
        "ripgrep"
        "flameshot"
        "chromium-chromedriver"
        "npm" # Required for markdownlint-cli2
        "virtualenv" # For global virtualenv command, though python3 -m venv is preferred
        "curl" # Ensure curl is installed for various downloads
        "wget" # Ensure wget is installed for various downloads
        "unzip" # Ensure unzip is installed for font extraction
        "apt-transport-https" # For Brave browser repository
        "pipx" # For installing global Python applications like aider and mypy-django
        "libffi-dev" # Required for building cffi and other Python packages with C extensions
        "libpq-dev" # Required for building psycopg2-binary (PostgreSQL adapter)
    )

    # Conditionally add python3.10-venv for Ubuntu 22.04 if available/needed,
    # or ensure a generic python3-venv is present for 24.04+
    if [[ "$UBUNTU_VERSION" == "22.04" ]]; then
        log "Adding python3.10-venv for Ubuntu 22.04."
        CORE_APT_PACKAGES+=("python3.10-venv")
    else
        log "Adding python3-venv for Ubuntu $UBUNTU_VERSION."
        CORE_APT_PACKAGES+=("python3-venv")
    fi

    install_apt_packages "${CORE_APT_PACKAGES[@]}"
    log "Core APT packages installed."

    # 3. Install Snap Packages
    log "--- Section 3: Installing Snap Packages ---"
    install_snap_package "zellij" "--classic"
    log "Snap packages installed."

    # 4. Docker Post-installation Steps
    log "--- Section 4: Docker Configuration ---"
    log "Adding current user to the 'docker' group to run docker commands without sudo."
    log "NOTE: A logout/login is required for this change to take effect."
    sudo usermod -aG docker "$ORIGINAL_USER" || log "WARNING: Failed to add user $ORIGINAL_USER to docker group. You might need to do this manually or check permissions."
    log "Docker group configuration complete."

    # 5. Python Global Tools (using pipx for applications)
    log "--- Section 5: Global Python Applications (via pipx) ---"
    # PEP 668: Avoids direct pip install into system Python.
    # pipx is installed via apt in CORE_APT_PACKAGES.
    
    log "Installing Aider (AI code assistant) using pipx for user $ORIGINAL_USER."
    sudo -u "$ORIGINAL_USER" pipx install aider-install || log "WARNING: Failed to install aider-install with pipx for user $ORIGINAL_USER. Check internet connection or pipx issues."
    # pipx handles the executable path, so no need for 'aider-install' command here.

    log "Global Python applications installed."

    # 6. Bluetooth Fix (preemptive)
    log "--- Section 6: Bluetooth Configuration ---"
    log "Reinstalling Bluetooth packages to preempt common headphone issues."
    sudo apt reinstall --purge bluez gnome-bluetooth -y || log "WARNING: Bluetooth package reinstallation failed. Check apt logs for details."
    log "Bluetooth packages reinstalled (if needed)."

    # 7. Setup Development Directories
    log "--- Section 7: Setting up Development Directories ---"
    log "Creating '/home/$ORIGINAL_USER/virtualenvs' and '/home/$ORIGINAL_USER/programming' directories for user $ORIGINAL_USER."
    sudo -u "$ORIGINAL_USER" mkdir -p "/home/$ORIGINAL_USER/virtualenvs" || log "WARNING: Directory /home/$ORIGINAL_USER/virtualenvs already exists or could not be created."
    sudo -u "$ORIGINAL_USER" mkdir -p "/home/$ORIGINAL_USER/programming" || log "WARNING: Directory /home/$ORIGINAL_USER/programming already exists or could not be created."
    # Change directory as ORIGINAL_USER to ensure subsequent git clones are in the correct place

    log "Attempting to change current directory to /home/$ORIGINAL_USER/programming/ (for informational purposes)."
    # The actual cloning commands use absolute paths, so the current directory of the root user is less important.

    # 8. Git Configuration
    # 8. Git Configuration
    log "--- Section 8: Git Configuration ---"

    # Check for SSH keys for GitHub
    SSH_PRIVATE_KEY="$HOME/.ssh/id_ed25519"
    if [ ! -f "$SSH_PRIVATE_KEY" ]; then
        log "WARNING: No SSH private key found at $SSH_PRIVATE_KEY for user $ORIGINAL_USER."
        log "         If you plan to clone Khaldoun projects via SSH, you need to generate an SSH key"
        log "         and add the public key to your GitHub account."
        log "         You can generate a new key with: ssh-keygen -t ed25519 -C \"your_email@example.com\""
        log "         See GitHub's documentation for adding the key to your account."
    else
        configure_git
        log "Git configured (credential helper)."
    fi
    log "Git configuration check complete."

    # 9. Khaldoun Projects Setup (using SSH URLs)
    log "--- Section 9: Cloning Khaldoun Projects (via SSH) ---"
    log "IMPORTANT: Ensure your SSH keys are set up with GitHub for these repositories for user $ORIGINAL_USER."
    declare -A khaldoun_ssh_repos
    khaldoun_ssh_repos["lugha"]="git@github.com:khaldoun-xyz/lugha.git"
    khaldoun_ssh_repos["sisu"]="git@github.com:khaldoun-xyz/sisu.git"
    khaldoun_ssh_repos["terminal_llm"]="git@github.com:khaldoun-xyz/terminal_llm.git"
    khaldoun_ssh_repos["renard"]="git@github.com:khaldoun-xyz/renard.git"
    khaldoun_ssh_repos["khaldoun"]="git@github.com:khaldoun-xyz/khaldoun.git" # Corrected from 'khaldoun hp' for consistency

    for project in "${!khaldoun_ssh_repos[@]}"; do
        setup_python_project_ssh "${khaldoun_ssh_repos[$project]}" "$project"
    done

    # Special case for core_skills (now also using SSH URL)
    log "Cloning core_skills via SSH for user $ORIGINAL_USER."
    local core_skills_ssh_url="git@github.com:khaldoun-xyz/core_skills.git"
    local core_skills_dir="/home/$ORIGINAL_USER/programming/core_skills"
    if [ ! -d "$core_skills_dir" ]; then
        sudo -u "$ORIGINAL_USER" git clone "$core_skills_ssh_url" "$core_skills_dir" || log "WARNING: Failed to clone core_skills via SSH for user $ORIGINAL_USER. Ensure their SSH key is set up with GitHub."
    else
        log "core_skills repository already exists. Skipping clone."
    fi
    log "Khaldoun projects cloning complete."

    # 10. Neovim Installation
    log "--- Section 10: Neovim Installation and Configuration ---"
    log "Installing Neovim AppImage for user $ORIGINAL_USER."
    local nvim_appimage="/home/$ORIGINAL_USER/nvim-linux-x86_64.appimage"
    if [ ! -f "$nvim_appimage" ]; then
        sudo -u "$ORIGINAL_USER" curl -fsSLo "$nvim_appimage" https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.appimage || error_exit "Failed to download Neovim AppImage for user $ORIGINAL_USER."
        sudo -u "$ORIGINAL_USER" chmod u+x "$nvim_appimage" || error_exit "Failed to make Neovim AppImage executable for user $ORIGINAL_USER."
        log "Neovim AppImage downloaded and made executable for user $ORIGINAL_USER."
    else
        log "Neovim AppImage already exists for user $ORIGINAL_USER. Skipping download."
    fi

    log "Setting up LazyVim configuration for user $ORIGINAL_USER."
    local nvim_config_dir="/home/$ORIGINAL_USER/.config/nvim"
    if [ ! -d "$nvim_config_dir" ]; then
        sudo -u "$ORIGINAL_USER" git clone https://github.com/LazyVim/starter "$nvim_config_dir" || error_exit "Failed to clone LazyVim starter config for user $ORIGINAL_USER."
        sudo -u "$ORIGINAL_USER" rm -rf "$nvim_config_dir/.git" || log "WARNING: Failed to remove .git from LazyVim config for user $ORIGINAL_USER. Manual cleanup might be needed."
    else
        log "LazyVim configuration already exists for user $ORIGINAL_USER. Skipping clone."
    fi
    log "Neovim and LazyVim setup complete."

    # 11. Install Lazygit and Lazydocker
    log "--- Section 11: Installing Lazygit and Lazydocker ---"
    # These are installed to /usr/local/bin, which is system-wide, but the download process
    # needs to be done as the original user to access their home directory for temp files.
    install_latest_github_release "jesseduffield/lazygit" "lazygit"
    install_latest_github_release "jesseduffield/lazydocker" "lazydocker"
    log "Lazygit and Lazydocker installed."

    # 12. Install Nerd Fonts for Alacritty
    log "--- Section 12: Installing FiraCode Nerd Font ---"
    local font_zip="FiraCode.zip"
    local font_dir="/home/$ORIGINAL_USER/.local/share/fonts"
    # Ensure font directory exists and is owned by the original user
    sudo -u "$ORIGINAL_USER" mkdir -p "$font_dir" || error_exit "Failed to create font directory '$font_dir' for user $ORIGINAL_USER."

    # Check for one of the font files to determine if fonts are already installed
    if [ ! -f "$font_dir/FiraCodeNerdFont-Regular.ttf" ]; then
        sudo -u "$ORIGINAL_USER" wget -P "/home/$ORIGINAL_USER/" https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/FiraCode.zip || error_exit "Failed to download FiraCode Nerd Font for user $ORIGINAL_USER."
        sudo -u "$ORIGINAL_USER" unzip "/home/$ORIGINAL_USER/$font_zip" -d "$font_dir" || error_exit "Failed to unzip FiraCode Nerd Font for user $ORIGINAL_USER."
        sudo -u "$ORIGINAL_USER" rm "/home/$ORIGINAL_USER/$font_zip" || log "WARNING: Failed to remove font zip file '/home/$ORIGINAL_USER/$font_zip'."
        # fc-cache needs to be run by the user for their font cache
        sudo -u "$ORIGINAL_USER" fc-cache -fv || log "WARNING: Failed to refresh font cache for user $ORIGINAL_USER. Font changes might not apply immediately."
        log "FiraCode Nerd Font installed and font cache refreshed for user $ORIGINAL_USER."
    else
        log "FiraCode Nerd Font appears to be already installed for user $ORIGINAL_USER. Skipping font installation."
    fi
    log "Nerd Fonts setup complete."

    # 13. Configure Alacritty
    log "--- Section 13: Configuring Alacritty Terminal ---"
    local alacritty_config_dir="/home/$ORIGINAL_USER/.config/alacritty/"
    # Ensure config directory exists and is owned by the original user
    sudo -u "$ORIGINAL_USER" mkdir -p "$alacritty_config_dir" || log "WARNING: Alacritty config directory already exists or could not be created for user $ORIGINAL_USER."
    # Use tee to write the alacritty.yml content, overwriting if it exists, as ORIGINAL_USER
    sudo -u "$ORIGINAL_USER" bash -c "cat <<EOF | tee \"$alacritty_config_dir/alacritty.yml\" > /dev/null
font:
  normal:
    family: \"FiraCode Nerd Font\"
    size: 12.0
  bold:
    family: \"FiraCode Nerd Font\"
  italic:
    family: \"FiraCode Nerd Font\"
env:
  LANG: en_US.UTF-8
EOF"
    log "Alacritty configuration updated with FiraCode Nerd Font for user $ORIGINAL_USER."

    # 14. Node.js and npm tools for LazyVim
    log "--- Section 14: Node.js and npm Tools ---"
    log "Installing global npm packages for LazyVim plugins."

    sudo npm install -g markdownlint-cli2 || log "WARNING: Failed to install markdownlint-cli2 globally. LazyVim linting might be affected."

    log "Installing NVM (Node Version Manager) for user $ORIGINAL_USER."
    local nvm_install_script="https://raw.githubusercontent.com/nvm-sh/nvm/v0.38.0/install.sh"
    local nvm_dir="/home/$ORIGINAL_USER/.nvm"
    if [ ! -d "$nvm_dir" ]; then
        # Run NVM install script as ORIGINAL_USER
        sudo -u "$ORIGINAL_USER" curl -o- "$nvm_install_script" | bash || log "WARNING: Failed to install NVM for user $ORIGINAL_USER. Node.js setup might be incomplete."
        # Source NVM for the current script session for the ORIGINAL_USER's environment
        # This is tricky as the script runs as root, but nvm commands need user context.
        # We will attempt to run nvm commands as ORIGINAL_USER.
        log "NVM installed for user $ORIGINAL_USER. Installing LTS Node.js."
        sudo -u "$ORIGINAL_USER" bash -c "export NVM_DIR=\"$nvm_dir\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"; nvm install --lts" || log "WARNING: Failed to install LTS Node.js via NVM for user $ORIGINAL_USER. Node.js might not be available."
        sudo -u "$ORIGINAL_USER" bash -c "export NVM_DIR=\"$nvm_dir\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"; nvm use --lts" || log "WARNING: Failed to set LTS Node.js as default via NVM for user $ORIGINAL_USER."
    else
        log "NVM already installed for user $ORIGINAL_USER. Skipping NVM installation."
        log "Ensuring LTS Node.js is installed for user $ORIGINAL_USER."
        sudo -u "$ORIGINAL_USER" bash -c "export NVM_DIR=\"$nvm_dir\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"; nvm install --lts" || log "WARNING: Failed to install LTS Node.js via NVM for user $ORIGINAL_USER. Node.js might not be available."
        sudo -u "$ORIGINAL_USER" bash -c "export NVM_DIR=\"$nvm_dir\"; [ -s \"\$NVM_DIR/nvm.sh\" ] && \\. \"\$NVM_DIR/nvm.sh\"; nvm use --lts" || log "WARNING: Failed to set LTS Node.js as default via NVM for user $ORIGINAL_USER."
    fi
    log "Node.js and npm tools setup complete."

    # 15. Python Linting Tool (using pipx)
    log "--- Section 15: Python Linting Tools (via pipx) ---"
    log "Installing mypy-django for Python linting using pipx for user $ORIGINAL_USER."
    sudo -u "$ORIGINAL_USER" pipx install mypy-django || log "WARNING: Failed to install mypy-django with pipx for user $ORIGINAL_USER. Python linting might be affected."
    log "Python linting tools installed."

    # 16. Install Brave Browser
    log "--- Section 16: Installing Brave Browser ---"
    log "Adding Brave Browser repository and installing Brave."
    # Ensure keyring directory exists
    sudo mkdir -p /usr/share/keyrings/ || log "WARNING: Failed to create /usr/share/keyrings/ directory."
    sudo curl -fsSLo /usr/share/keyrings/brave-browser-archive-keyring.gpg https://brave-browser-apt-release.s3.brave.com/brave-browser-archive-keyring.gpg || error_exit "Failed to download Brave keyring."
    echo "deb [signed-by=/usr/share/keyrings/brave-browser-archive-keyring.gpg arch=amd64] https://brave-browser-apt-release.s3.brave.com/ stable main" | sudo tee /etc/apt/sources.list.d/brave-browser-release.list || error_exit "Failed to add Brave repository."
    sudo apt update -y || error_exit "APT update after Brave repo addition failed."
    sudo apt install -y brave-browser || error_exit "Failed to install Brave Browser."
    log "Brave Browser installed."

    log "--- Setup Complete! ---"
    log "Ubuntu Development Environment Setup Script finished successfully (with warnings if any)."
    log "IMPORTANT NEXT STEPS:"
    log "1. Please log out and log back in for Docker group changes to take full effect."
    log "2. Open a new terminal session for NVM (Node Version Manager) changes to be fully active."
    log "3. Verify your SSH key setup for GitHub if you encountered any cloning issues."
    log "Review the log file at $LOG_FILE for any warnings or errors that occurred during execution."
}

# Execute the main function
main "$@"
