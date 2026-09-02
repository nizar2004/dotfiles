#!/bin/sh
set -e

# ANSI Color Codes
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[1;36m'
C_MAGENTA='\033[1;35m'
C_GREEN='\033[1;32m'
C_WHITE='\033[1;37m'
C_GRAY='\033[0;90m'

print_banner() {
    clear
    printf "%b" "${C_MAGENTA}${C_BOLD}"
    cat << 'BANNER'
  ╭────────────────────────────────────────────────────────────╮
  │                                                            │
  │   ███╗  ██╗██╗███████╗██████╗ ██████╗                      │
  │   ████╗ ██║██║╚══███╔╝██╔══██╗██╔══██╗                     │
  │   ██╔██╗██║██║  ███╔╝ ███████║██████╔╝                     │
  │   ██║╚██╗██║██║ ███╔╝  ██╔══██║██╔══██╗                     │
  │   ██║ ╚████║██║███████║██║  ██║██║  ██║                     │
  │   ╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝                     │
  │                                                            │
  │                ✦ ARCH LINUX • KDE PLASMA ✦                 │
  │                                                            │
  ╰────────────────────────────────────────────────────────────╯
BANNER
    printf "%b\n" "${C_RESET}"
}

step() {
    printf "\n%b[ Step %s ]%b %b%s%b\n" "${C_CYAN}${C_BOLD}" "$1" "${C_RESET}" "${C_WHITE}${C_BOLD}" "$2" "${C_RESET}"
}

sub() {
    printf "  %b➜%b %s\n" "${C_MAGENTA}" "${C_RESET}" "$1"
}

success() {
    printf "  %b✔%b %b%s%b\n" "${C_GREEN}${C_BOLD}" "${C_RESET}" "${C_GREEN}" "$1" "${C_RESET}"
}

print_banner

# Step 1: System Packages & Vertical Clock Widget
step "1/7" "Synchronizing System Packages & Widgets"
sub "Installing discord, papirus-icon-theme, cargo, dbus..."
sudo pacman -S --noconfirm --needed --quiet discord papirus-icon-theme base-devel git cargo pkgconf dbus >/dev/null 2>&1
success "Essential packages ready"

sub "Fetching Vertical Clock repository..."
TEMP_CLOCK_DIR=$(mktemp -d)
git clone --quiet https://github.com/Cyberbessa/plasma-vertical-clock.git "$TEMP_CLOCK_DIR"

sub "Registering Vertical Clock applet..."
kpackagetool6 --type Plasma/Applet --install "$TEMP_CLOCK_DIR" >/dev/null 2>&1 || \
kpackagetool6 --type Plasma/Applet --upgrade "$TEMP_CLOCK_DIR" >/dev/null 2>&1 || true
rm -rf "$TEMP_CLOCK_DIR"
success "Vertical Clock widget installed"

# Step 2: Advanced Separator Plasmoid
step "2/7" "Installing Advanced Separator Widget"
TEMP_WIDGET_DIR=$(mktemp -d)
sub "Fetching widget repository..."
git clone --quiet https://github.com/luisbocanegra/plasma-advanced-separator.git "$TEMP_WIDGET_DIR"

sub "Registering Plasma applet..."
kpackagetool6 --type Plasma/Applet --install "$TEMP_WIDGET_DIR" >/dev/null 2>&1 || \
kpackagetool6 --type Plasma/Applet --upgrade "$TEMP_WIDGET_DIR" >/dev/null 2>&1 || true

PLASMOID_TARGET="$HOME/.local/share/plasma/plasmoids/luisbocanegra.advanced_separator"
mkdir -p "$PLASMOID_TARGET"
cp -rf "$TEMP_WIDGET_DIR"/* "$PLASMOID_TARGET/"
rm -rf "$TEMP_WIDGET_DIR"
success "Advanced Separator widget installed"

# Step 3: kdotool
step "3/7" "Verifying System Utilities"
if ! command -v kdotool >/dev/null 2>&1; then
    sub "Building kdotool from source..."
    TEMP_DIR=$(mktemp -d)
    git clone --quiet https://github.com/jinliu/kdotool.git "$TEMP_DIR/kdotool"
    cd "$TEMP_DIR/kdotool"
    cargo build --release --quiet
    sudo install -Dm755 target/release/kdotool /usr/local/bin/kdotool
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    success "kdotool binary compiled"
else
    success "kdotool already present"
fi

# Step 4: Dotfiles (Chezmoi Check & Install)
step "4/7" "Applying Chezmoi Dotfiles"
sub "Stopping Plasmashell safely..."
kquitapp6 plasmashell >/dev/null 2>&1 || true
sleep 1

if ! command -v chezmoi >/dev/null 2>&1; then
    sub "Chezmoi not found. Installing chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
    success "Chezmoi installed"
else
    success "Chezmoi binary already present"
fi

CHEZMOI_SRC="$(chezmoi source-path 2>/dev/null || echo "$HOME/.local/share/chezmoi")"

if [ -d "$CHEZMOI_SRC/.git" ]; then
    sub "Dotfiles repository found. Pulling latest changes..."
    git -C "$CHEZMOI_SRC" pull --quiet
    chezmoi apply --force >/dev/null 2>&1
    success "Dotfiles updated and applied"
else
    sub "Dotfiles repository not found. Initializing and downloading..."
    chezmoi init --apply --force nizar2004 >/dev/null 2>&1
    success "Dotfiles initialized and applied"
fi

# Step 5: Scripts & Shortcuts
step "5/7" "Configuring Helpers & Hotkeys"
mkdir -p "$HOME/.local/bin"
sub "Fetching Discord toggle helper..."
curl -fsLS https://raw.githubusercontent.com/nizar2004/dotfiles/main/toggle-discord.sh -o "$HOME/.local/bin/toggle-discord.sh"
chmod +x "$HOME/.local/bin/toggle-discord.sh"

sub "Creating application desktop entry..."
mkdir -p "$HOME/.local/share/applications"
cat << 'DESK' > "$HOME/.local/share/applications/net.local.toggle-discord.sh.desktop"
[Desktop Entry]
Type=Application
Name=Toggle Discord
Exec=$HOME/.local/bin/toggle-discord.sh
Icon=discord
NoDisplay=false
StartupNotify=false
DESK

sub "Registering Meta+Shift+D shortcut service..."
pkill -9 kglobalaccel6 || true
KGLOBLALRC="$HOME/.config/kglobalshortcutsrc"
sed -i '/net.local.toggle-discord/d' "$KGLOBLALRC" 2>/dev/null || true
echo "" >> "$KGLOBLALRC"
echo "[services][net.local.toggle-discord.sh.desktop]" >> "$KGLOBLALRC"
echo "_launch=Meta+Shift+D" >> "$KGLOBLALRC"
success "Shortcuts & helper scripts active"

# Step 6: Reload desktop daemons
step "6/7" "Restoring KDE Plasma Environment"
sub "Updating system service cache..."
kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
sub "Restarting Plasmashell..."
kstart plasmashell >/dev/null 2>&1 &
success "Desktop environment fully reloaded"

# Step 7: Create 'backup' command utility
step "7/7" "Setting up 'backup' command utility"
mkdir -p "$HOME/.local/bin"
cat << 'EOF' > "$HOME/.local/bin/backup"
#!/bin/sh
set -e

CHEZMOI_SRC="$(chezmoi source-path)"

echo "Synchronizing local changes into chezmoi..."
chezmoi re-add

echo "Committing and pushing to GitHub..."
cd "$CHEZMOI_SRC"

if git diff-index --quiet HEAD --; then
    echo "No new changes to backup."
    exit 0
fi

git add .
git commit -m "Auto-backup workspace: $(date +'%Y-%m-%d %H:%M:%S')"
git push origin main

echo "✔ Successfully backed up to GitHub!"
EOF
chmod +x "$HOME/.local/bin/backup"
success "'backup' command is now active"

# Interactive: Install Necessary Apps
printf "\n"
printf "\033[1;36mDo you want to install your necessary apps? (y/N): \033[0m"
if read -r REPLY </dev/tty; then
    case "$REPLY" in
        [yY][eE][sS]|[yY])
            sub "Installing necessary apps..."
            sudo pacman -S --noconfirm --needed --quiet asusctl >/dev/null 2>&1
            success "Completed!"
            ;;
        *)
            sub "Skipping install necessary apps."
            ;;
    esac
else
    sub "Skipping install necessary apps."
fi

# Interactive Wallpaper Prompt
printf "\n"
printf "\033[1;36mDo you want to clone Catppuccin Mocha wallpapers to ~/Pictures/wallpapers? (y/N): \033[0m"
if read -r REPLY </dev/tty; then
    case "$REPLY" in
        [yY][eE][sS]|[yY])
            WALLPAPER_DIR="$HOME/Pictures/wallpapers"
            if [ -d "$WALLPAPER_DIR/.git" ]; then
                sub "Updating Catppuccin Mocha wallpapers repository..."
                git -C "$WALLPAPER_DIR" pull --progress
                success "Wallpapers repository updated"
            else
                mkdir -p "$HOME/Pictures"
                rm -rf "$WALLPAPER_DIR"
                sub "Cloning Catppuccin Mocha wallpapers (showing live download progress)..."
                git clone --depth 1 --progress https://github.com/orangci/walls-catppuccin-mocha.git "$WALLPAPER_DIR"
                success "Wallpapers repository cloned"
            fi
            ;;
        *)
            sub "Skipping wallpaper repository setup."
            ;;
    esac
else
    sub "Skipping wallpaper repository setup."
fi

# Completion Banner
printf "\n%b" "${C_GREEN}${C_BOLD}"
cat << 'BANNER'
  ╭────────────────────────────────────────────────────────────╮
  │                                                            │
  │   ✨  RESTORE COMPLETE! WORKSPACE READY, NIZAR.  ✨        │
  │                                                            │
  ╰────────────────────────────────────────────────────────────╯
BANNER
printf "%b\n" "${C_RESET}"