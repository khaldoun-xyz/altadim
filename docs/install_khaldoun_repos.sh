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
