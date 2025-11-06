#!/usr/bin/env bash

# Stop script if any errors
set -euo pipefail

# Configuration
DOTFILES_DIR="${HOME}/.dotfiles"
BACKUP_DIR="${HOME}/.dotfiles_backup_$(date +%Y%m%d_%H%M%S)"

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Helper functions
log_info() { echo -e "${GREEN}[INFO]${NC} $1"; }
log_warn() { echo -e "${YELLOW}[WARN]${NC} $1"; }
log_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Create symlink with backup
create_symlink() {
    local source="$1"
    local target="$2"
    
    # Check if source exists
    if [[ ! -e "$source" ]]; then
        log_error "Source does not exist: $source"
        return 1
    fi
    
    # Create parent directory if needed
    local target_dir
    target_dir=$(dirname "$target")
    if [[ ! -d "$target_dir" ]]; then
        log_info "Creating directory: $target_dir"
        mkdir -p "$target_dir"
    fi
    
    # Handle existing target
    if [[ -e "$target" || -L "$target" ]]; then
        if [[ -L "$target" ]] && [[ "$(readlink "$target")" == "$source" ]]; then
            log_info "Symlink already correct: $target"
            return 0
        fi
        
        # Backup existing file/symlink
        mkdir -p "$BACKUP_DIR"
        log_warn "Backing up existing: $target"
        mv "$target" "$BACKUP_DIR/"
    fi
    
    # Create symlink
    ln -s "$source" "$target"
    log_info "Created symlink: $target -> $source"
}

# Main installation
main() {
    log_info "Starting dotfiles installation..."
    
    if [[ ! -d "$DOTFILES_DIR" ]]; then
        log_error "Dotfiles directory not found: $DOTFILES_DIR"
        exit 1
    fi
    
    # Define symlinks (source -> target)
    declare -A symlinks=(
        ["${HOME}/.config"]="${DOTFILES_DIR}/config"
        ["${HOME}/.local/share/applications"]="${DOTFILES_DIR}/local/share/applications"
        ["${HOME}/.profile"]="${DOTFILES_DIR}/config/shell/profile"
        ["${HOME}/.zprofile"]="${DOTFILES_DIR}/config/shell/profile"
        ["${HOME}/.gitconfig"]="${DOTFILES_DIR}/.gitconfig"
    )
    
    # Create symlinks
    for target in "${!symlinks[@]}"; do
        create_symlink "${symlinks[$target]}" "$target"
    done
    
    log_info "Installation complete!"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        log_info "Backups saved to: $BACKUP_DIR"
    fi
}

main "$@"
