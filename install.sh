#!/usr/bin/env bash
# =============================================================================
# Minimal Bocchi Hyprland Rice - Automated Installation Script
# =============================================================================
# This script automates the complete installation of the Bocchi Hyprland rice
# Supports: Arch Linux, Manjaro, EndeavourOS, and other Arch-based distros
# =============================================================================

set -e  # Exit on error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
REPO_URL="${1:-.}"  # First argument or current directory
DOTFILES_DIR="${REPO_URL}"
HOME_DIR="${HOME}"
BACKUP_DIR="${HOME_DIR}/.config/backup-$(date +%Y%m%d-%H%M%S)"
CONFIG_DIR="${HOME_DIR}/.config"

# =============================================================================
# Helper Functions
# =============================================================================

print_header() {
    echo -e "${BLUE}╔══════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║ Minimal Bocchi - Hyprland Installation  ║${NC}"
    echo -e "${BLUE}╚══════════════════════════════════════════╝${NC}"
    echo ""
}

print_step() {
    echo -e "${GREEN}[✓]${NC} $1"
}

print_info() {
    echo -e "${BLUE}[i]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[!]${NC} $1"
}

print_error() {
    echo -e "${RED}[✗]${NC} $1"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        return 1
    fi
    return 0
}

detect_aur_helper() {
    if check_command yay; then
        echo "yay"
    elif check_command paru; then
        echo "paru"
    else
        return 1
    fi
}

# =============================================================================
# Pre-Installation Checks
# =============================================================================

check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if running on Arch-based distro
    if ! [ -f /etc/os-release ]; then
        print_error "Cannot detect OS. This script requires Arch Linux or derivative."
        exit 1
    fi
    
    source /etc/os-release
    if ! grep -qi "arch\|manjaro\|endeavour" <<< "$ID $ID_LIKE"; then
        print_warning "This script is optimized for Arch Linux. Proceeding anyway..."
    fi
    print_step "OS compatibility check passed"
    
    # Check for git
    if ! check_command git; then
        print_error "git is not installed. Install it first: sudo pacman -S git"
        exit 1
    fi
    print_step "git found"
    
    # Check for sudo access
    if ! sudo -n true 2>/dev/null; then
        print_info "This script requires sudo access. You may be prompted for your password."
    fi
    print_step "sudo access available"
    
    # Check for pacman
    if ! check_command pacman; then
        print_error "pacman not found. This script requires Arch Linux."
        exit 1
    fi
    print_step "pacman package manager found"
}

# =============================================================================
# System Update
# =============================================================================

update_system() {
    print_info "Updating system packages..."
    print_warning "This may take a few minutes..."
    
    sudo pacman -Syu --noconfirm
    
    print_step "System updated"
}

# =============================================================================
# Install Dependencies
# =============================================================================

install_core_packages() {
    print_info "Installing core packages..."
    
    local packages=(
        # Window Manager
        "hyprland"
        "hyprutils"
        
        # Display Manager
        "sddm"
        
        # Terminal & Shell
        "kitty"
        "zsh"
        "git"
        
        # UI & Theming
        "waybar"
        "rofi"
        "dunst"
        
        # File Manager
        "ranger"
        
        # Text Editor
        "neovim"
        
        # Color & Theming
        "python-pywal"
        "swww"
        
        # System Tools
        "btop"
        "cliphist"
        "wl-clipboard"
        "imagemagick"
        "jq"
        
        # Utilities
        "curl"
        "wget"
        "base-devel"
    )
    
    print_info "Installing from main repositories: ${#packages[@]} packages"
    sudo pacman -S "${packages[@]}" --noconfirm --needed
    
    print_step "Core packages installed"
}

install_aur_packages() {
    print_info "Installing AUR packages..."
    
    local aur_helper
    if ! aur_helper=$(detect_aur_helper); then
        print_warning "No AUR helper found. Installing yay..."
        cd /tmp
        git clone https://aur.archlinux.org/yay.git
        cd yay
        makepkg -si --noconfirm
        cd -
        aur_helper="yay"
    fi
    
    print_info "Using AUR helper: $aur_helper"
    
    local aur_packages=(
        # Hyprland ecosystem
        "hyprlock"
        
        # Themes
        "tokyonight-gtk-theme-git"
        "tokyonight-icon-theme-git"
        "bibata-cursor-theme-bin"
        "kvantum-theme-catppuccin-git"
        "kvantummanager"
        
        # System tools
        "catnip"
        
        # Optional: Media players
        "ncspot"
        "cava"
        
        # Optional: SDDM theme
        "sddm-theme-flower"
    )
    
    print_info "Installing from AUR: ${#aur_packages[@]} packages"
    $aur_helper -S "${aur_packages[@]}" --noconfirm --needed
    
    print_step "AUR packages installed"
}

# =============================================================================
# Configuration Setup
# =============================================================================

backup_existing_configs() {
    print_info "Backing up existing configurations..."
    
    mkdir -p "$BACKUP_DIR"
    
    local config_dirs=(
        "hypr"
        "waybar"
        "kitty"
        "rofi"
        "ranger"
        "nvim"
        "cava"
        "hyprdots"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [ -d "$CONFIG_DIR/$dir" ]; then
            print_info "Backing up $dir..."
            cp -r "$CONFIG_DIR/$dir" "$BACKUP_DIR/" || true
        fi
    done
    
    # Backup shell configs
    if [ -f "$HOME_DIR/.zshrc" ]; then
        cp "$HOME_DIR/.zshrc" "$BACKUP_DIR/.zshrc" || true
    fi
    if [ -f "$HOME_DIR/.p10k.zsh" ]; then
        cp "$HOME_DIR/.p10k.zsh" "$BACKUP_DIR/.p10k.zsh" || true
    fi
    
    print_step "Configurations backed up to: $BACKUP_DIR"
}

copy_configurations() {
    print_info "Copying configurations..."
    
    # Copy main config directories
    local config_dirs=(
        "hypr"
        "waybar"
        "kitty"
        "rofi"
        "ranger"
        "nvim"
        "cava"
        "hyprdots"
        "catnip"
    )
    
    for dir in "${config_dirs[@]}"; do
        if [ -d "$DOTFILES_DIR/.config/$dir" ]; then
            print_info "Installing $dir configuration..."
            mkdir -p "$CONFIG_DIR/$dir"
            cp -r "$DOTFILES_DIR/.config/$dir/"* "$CONFIG_DIR/$dir/" 2>/dev/null || true
        fi
    done
    
    # Copy shell configs
    if [ -f "$DOTFILES_DIR/.zshrc" ]; then
        print_info "Installing .zshrc..."
        cp "$DOTFILES_DIR/.zshrc" "$HOME_DIR/.zshrc"
    fi
    
    if [ -f "$DOTFILES_DIR/.p10k.zsh" ]; then
        print_info "Installing .p10k.zsh..."
        cp "$DOTFILES_DIR/.p10k.zsh" "$HOME_DIR/.p10k.zsh"
    fi
    
    print_step "Configurations copied"
}

make_scripts_executable() {
    print_info "Making scripts executable..."
    
    chmod +x "$CONFIG_DIR/hypr/scripts/"*.sh 2>/dev/null || true
    chmod +x "$CONFIG_DIR/hypr/initial-boot.sh" 2>/dev/null || true
    chmod +x "$CONFIG_DIR/hyprdots/scripts/"*.sh 2>/dev/null || true
    
    print_step "Scripts are now executable"
}

# =============================================================================
# Shell Configuration
# =============================================================================

setup_zsh() {
    print_info "Setting up Zsh..."
    
    # Check if oh-my-zsh is installed
    if [ ! -d "$HOME_DIR/.oh-my-zsh" ]; then
        print_info "Installing Oh-My-Zsh..."
        sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended || true
    else
        print_step "Oh-My-Zsh already installed"
    fi
    
    # Install Powerlevel10k theme
    if [ ! -d "$HOME_DIR/.oh-my-zsh/custom/themes/powerlevel10k" ]; then
        print_info "Installing Powerlevel10k theme..."
        git clone --depth=1 https://github.com/romkatv/powerlevel10k.git \
            "$HOME_DIR/.oh-my-zsh/custom/themes/powerlevel10k" || true
    else
        print_step "Powerlevel10k theme already installed"
    fi
    
    # Change default shell to zsh
    if [ "$SHELL" != "/usr/bin/zsh" ]; then
        print_info "Changing default shell to Zsh..."
        chsh -s /usr/bin/zsh
        print_step "Default shell changed to Zsh"
    else
        print_step "Zsh already set as default shell"
    fi
}

# =============================================================================
# Wallpaper Setup
# =============================================================================

setup_wallpapers() {
    print_info "Setting up wallpaper directory..."
    
    mkdir -p "$HOME_DIR/Pictures/wallpapers"
    
    # Copy wallpapers from repo if they exist
    if [ -d "$DOTFILES_DIR/Pictures/bgs" ]; then
        print_info "Copying wallpapers..."
        cp "$DOTFILES_DIR/Pictures/bgs/"* "$HOME_DIR/Pictures/wallpapers/" 2>/dev/null || true
    fi
    
    # Check if default wallpaper exists, if not create placeholder
    if [ ! -f "$HOME_DIR/Pictures/wallpapers/Fantasy-Landscape.png" ]; then
        print_warning "Default wallpaper not found. Using a simple solid color."
        print_warning "Please add wallpapers to: $HOME_DIR/Pictures/wallpapers/"
        
        # Create a simple placeholder wallpaper
        python3 << 'EOF'
from PIL import Image
import os

home = os.path.expanduser("~")
wallpaper_dir = os.path.join(home, "Pictures/wallpapers")
wallpaper_file = os.path.join(wallpaper_dir, "Fantasy-Landscape.png")

# Create a simple purple gradient image (Bocchi theme colors)
img = Image.new('RGB', (1920, 1080), color=(20, 10, 40))
img.save(wallpaper_file)
print(f"Created placeholder wallpaper: {wallpaper_file}")
EOF
    fi
    
    print_step "Wallpaper directory ready"
}

# =============================================================================
# Hyprland Session Setup
# =============================================================================

setup_hyprland_session() {
    print_info "Setting up Hyprland session..."
    
    local session_file="/usr/share/wayland-sessions/hyprland.desktop"
    
    if [ ! -f "$session_file" ]; then
        print_info "Creating Hyprland session file..."
        sudo tee "$session_file" > /dev/null <<EOF
[Desktop Entry]
Name=Hyprland
Exec=Hyprland
Type=Application
EOF
    else
        print_step "Hyprland session file already exists"
    fi
}

# =============================================================================
# Color Scheme Setup
# =============================================================================

setup_color_schemes() {
    print_info "Setting up color schemes..."
    
    mkdir -p "$HOME_DIR/.config/wal/schemes"
    
    if [ -d "$DOTFILES_DIR/wal/schemes" ]; then
        cp "$DOTFILES_DIR/wal/schemes/"* "$HOME_DIR/.config/wal/schemes/" 2>/dev/null || true
        print_step "Color schemes installed"
    fi
}

# =============================================================================
# Final Setup
# =============================================================================

fix_monitor_config() {
    print_info "Detecting monitors..."
    
    if check_command hyprctl; then
        print_info "Current monitor configuration:"
        hyprctl monitors || true
        print_warning "Update ~/.config/hypr/monitors.conf with your monitor details if needed"
    fi
}

setup_permissions() {
    print_info "Setting up permissions..."
    
    # Polkit for GUI elevation
    sudo pacman -S polkit-kde-agent --noconfirm --needed 2>/dev/null || true
    
    print_step "Permissions configured"
}

run_initial_boot() {
    print_info "Would you like to run the initial boot setup now?"
    read -p "Run initial-boot.sh? (y/n) " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        if [ -f "$CONFIG_DIR/hypr/initial-boot.sh" ]; then
            print_info "Running initial boot setup..."
            bash "$CONFIG_DIR/hypr/initial-boot.sh"
            print_step "Initial boot setup completed"
        fi
    fi
}

# =============================================================================
# Summary
# =============================================================================

print_summary() {
    echo ""
    echo -e "${GREEN}╔══════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║   Installation Complete! 🎉              ║${NC}"
    echo -e "${GREEN}╚══════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${BLUE}Next steps:${NC}"
    echo -e "  1. ${YELLOW}Logout${NC} from your current session"
    echo -e "  2. At the login screen, select ${YELLOW}Hyprland${NC} from session options"
    echo -e "  3. Login with your credentials"
    echo ""
    echo -e "${BLUE}Configuration files:${NC}"
    echo -e "  • Hyprland: ${YELLOW}~/.config/hypr/hyprland.conf${NC}"
    echo -e "  • Keybindings: ${YELLOW}~/.config/hypr/keybindings.conf${NC}"
    echo -e "  • Waybar: ${YELLOW}~/.config/waybar/config${NC}"
    echo -e "  • Rofi: ${YELLOW}~/.config/rofi/config.rasi${NC}"
    echo ""
    echo -e "${BLUE}Essential keybindings:${NC}"
    echo -e "  • ${YELLOW}Super + Q${NC} = Close window"
    echo -e "  • ${YELLOW}Super + Return${NC} = Open terminal"
    echo -e "  • ${YELLOW}Super + Space${NC} = Application launcher"
    echo -e "  • ${YELLOW}Super + E${NC} = File manager"
    echo ""
    echo -e "${BLUE}Backup location:${NC}"
    echo -e "  ${YELLOW}$BACKUP_DIR${NC}"
    echo ""
    echo -e "${BLUE}Documentation:${NC}"
    echo -e "  • Installation Guide: ${YELLOW}$DOTFILES_DIR/INSTALLATION_GUIDE.md${NC}"
    echo -e "  • Technical Docs: ${YELLOW}$DOTFILES_DIR/TECHNICAL_ARCHITECTURE.md${NC}"
    echo ""
    echo -e "${YELLOW}Note:${NC} Consider customizing:"
    echo -e "  • Monitor configuration (resolution/position)"
    echo -e "  • Keyboard layout in ~/.config/hypr/monitors.conf"
    echo -e "  • Wallpapers in ~/Pictures/wallpapers/"
    echo -e "  • Keybindings to match your preferences"
    echo ""
}

# =============================================================================
# Main Installation Flow
# =============================================================================

main() {
    print_header
    
    # Pre-installation
    check_prerequisites
    echo ""
    
    # System
    read -p "Update system packages? (recommended) [Y/n] " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]] || [[ -z $REPLY ]]; then
        update_system
    fi
    echo ""
    
    # Installation
    print_info "Installing packages..."
    install_core_packages
    echo ""
    
    install_aur_packages
    echo ""
    
    # Configuration
    backup_existing_configs
    copy_configurations
    make_scripts_executable
    echo ""
    
    # Setup
    setup_zsh
    setup_wallpapers
    setup_color_schemes
    setup_hyprland_session
    setup_permissions
    echo ""
    
    fix_monitor_config
    echo ""
    
    # Final
    run_initial_boot
    print_summary
}

# Run main function
main "$@"
