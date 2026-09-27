#!/bin/sh
set -eu

die() {
    printf 'Error: %s\n' "$1" >&2
    exit 1
}

require_command() {
    command -v "$1" >/dev/null 2>&1 || die "Required command not found: $1"
}

pacman_install() {
    if [ "$(id -u)" -eq 0 ]; then
        pacman -S --noconfirm --needed "$@"
    else
        sudo pacman -S --noconfirm --needed "$@"
    fi
}

pacman_upgrade_install() {
    if [ "$(id -u)" -eq 0 ]; then
        pacman -Syu --noconfirm --needed "$@"
    else
        sudo pacman -Syu --noconfirm --needed "$@"
    fi
}

TEMP_DIR=
PLASMASHELL_STOPPED=0

cleanup() {
    if [ -n "$TEMP_DIR" ] && [ -d "$TEMP_DIR" ]; then
        rm -rf -- "$TEMP_DIR"
    fi
    if [ "$PLASMASHELL_STOPPED" -eq 1 ]; then
        kstart plasmashell >/dev/null 2>&1 || true
    fi
}

trap cleanup EXIT
trap 'exit 1' HUP INT TERM

new_temp_dir() {
    TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/dotfiles-install.XXXXXX") || die "Could not create a temporary directory"
}

ask_yes_no() {
    REPLY=
    if [ -r /dev/tty ] && read -r REPLY </dev/tty 2>/dev/null; then
        case "$REPLY" in
            [yY]|[yY][eE][sS]) return 0 ;;
        esac
    fi
    return 1
}

[ -n "${HOME:-}" ] && [ -d "$HOME" ] || die "HOME is unset or does not point to a directory"
require_command pacman
require_command curl
require_command mktemp
require_command kpackagetool6
require_command kquitapp6
require_command kstart
require_command kbuildsycoca6
if [ "$(id -u)" -ne 0 ]; then
    require_command sudo
fi

# ANSI Color Codes
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_CYAN='\033[1;36m'
C_MAGENTA='\033[1;35m'
C_GREEN='\033[1;32m'
C_WHITE='\033[1;37m'
C_GRAY='\033[0;90m'

print_banner() {
    if [ -t 1 ]; then
        clear 2>/dev/null || true
    fi
    printf "%b" "${C_MAGENTA}${C_BOLD}"
    cat << 'BANNER'
  ╭────────────────────────────────────────────────────────────╮
  │                                                            │
  │   ███╗  ██╗██╗███████╗██████╗ ██████╗                      │
  │   ████╗ ██║██║╚══███╔╝██╔══██╗██╔══██╗                     │
  │   ██╔██╗██║██║  ███╔╝ ███████║██████╔╝                     │
  │   ██║╚██╗██║██║ ███╔╝  ██╔══██║██╔══██╗                    │
  │   ██║ ╚████║██║███████║██║  ██║██║  ██║                    │
  │   ╚═╝  ╚═══╝╚═╝╚══════╝╚═╝  ╚═╝╚═╝  ╚═╝                    │
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

# Step 1: System Packages 
step "1/7" "Synchronizing System Packages & Widgets"
sub "Installing discord, papirus-icon-theme, build tools, and dependencies..."
pacman_upgrade_install discord asusctl papirus-icon-theme base-devel git cargo pkgconf dbus curl
require_command git
success "Essential packages ready"

sub "Fetching Vertical Clock repository..."
new_temp_dir
git clone --quiet --depth 1 https://github.com/Cyberbessa/plasma-vertical-clock.git "$TEMP_DIR/vertical-clock"

sub "Registering Vertical Clock applet..."
kpackagetool6 --type Plasma/Applet --install "$TEMP_DIR/vertical-clock" || \
    kpackagetool6 --type Plasma/Applet --upgrade "$TEMP_DIR/vertical-clock"
rm -rf -- "$TEMP_DIR"
TEMP_DIR=
success "Vertical Clock widget installed"

# Step 2: Advanced Separator Plasmoid
step "2/7" "Installing Advanced Separator Widget"
new_temp_dir
sub "Fetching widget repository..."
git clone --quiet --depth 1 https://github.com/luisbocanegra/plasma-advanced-separator.git "$TEMP_DIR/advanced-separator"

sub "Registering Plasma applet..."
kpackagetool6 --type Plasma/Applet --install "$TEMP_DIR/advanced-separator" || \
    kpackagetool6 --type Plasma/Applet --upgrade "$TEMP_DIR/advanced-separator"
rm -rf -- "$TEMP_DIR"
TEMP_DIR=
success "Advanced Separator widget installed"

# Step 3: kdotool
step "3/7" "Verifying System Utilities"
if ! command -v kdotool >/dev/null 2>&1; then
    sub "Building kdotool from source..."
    new_temp_dir
    git clone --quiet --depth 1 https://github.com/jinliu/kdotool.git "$TEMP_DIR/kdotool"
    (cd "$TEMP_DIR/kdotool" && cargo build --release --quiet)
    if [ "$(id -u)" -eq 0 ]; then
        install -Dm755 "$TEMP_DIR/kdotool/target/release/kdotool" /usr/local/bin/kdotool
    else
        sudo install -Dm755 "$TEMP_DIR/kdotool/target/release/kdotool" /usr/local/bin/kdotool
    fi
    rm -rf -- "$TEMP_DIR"
    TEMP_DIR=
    success "kdotool binary compiled"
else
    success "kdotool already present"
fi

# Step 4: Dotfiles (Chezmoi Check & Install)
step "4/7" "Applying Chezmoi Dotfiles"
sub "Stopping Plasmashell safely..."
kquitapp6 plasmashell >/dev/null 2>&1 || true
PLASMASHELL_STOPPED=1

if ! command -v chezmoi >/dev/null 2>&1; then
    sub "Chezmoi not found. Installing chezmoi via pacman..."
    pacman_install chezmoi
    success "Chezmoi installed"
else
    success "Chezmoi binary already present"
fi

CHEZMOI_SRC=$(chezmoi source-path)

if git -C "$CHEZMOI_SRC" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    sub "Dotfiles repository found. Pulling latest changes..."
    git -C "$CHEZMOI_SRC" pull --quiet --rebase --autostash
    chezmoi apply
    success "Dotfiles updated and applied"
else
    sub "Dotfiles repository not found. Initializing and downloading..."
    chezmoi init --apply nizar2004
    success "Dotfiles initialized and applied"
fi

# Step 5: Scripts & Shortcuts
step "5/7" "Configuring Helpers & Hotkeys"
mkdir -p "$HOME/.local/bin"
sub "Fetching Discord toggle helper..."
curl --fail --location --silent --show-error --retry 3 https://raw.githubusercontent.com/nizar2004/dotfiles/main/toggle-discord.sh -o "$HOME/.local/bin/toggle-discord.sh"
chmod +x "$HOME/.local/bin/toggle-discord.sh"

sub "Creating application desktop entry..."
mkdir -p "$HOME/.local/share/applications"
printf '[Desktop Entry]\nType=Application\nName=Toggle Discord\nExec="%s"\nIcon=discord\nNoDisplay=false\nStartupNotify=false\n' \
    "$HOME/.local/bin/toggle-discord.sh" > "$HOME/.local/share/applications/net.local.toggle-discord.sh.desktop"

sub "Registering Meta+Shift+D shortcut service..."
KGLOBALRC="$HOME/.config/kglobalshortcutsrc"
mkdir -p "$HOME/.config"
: >> "$KGLOBALRC"
SHORTCUT_SECTION='[services][net.local.toggle-discord.sh.desktop]'
SHORTCUT_TMP=$(mktemp "${KGLOBALRC}.XXXXXX")
awk -v target="$SHORTCUT_SECTION" '
    $0 == target { skip = 1; next }
    /^\[/ { skip = 0 }
    !skip { print }
' "$KGLOBALRC" > "$SHORTCUT_TMP"
printf '\n%s\n_launch=Meta+Shift+D\n' "$SHORTCUT_SECTION" >> "$SHORTCUT_TMP"
mv "$SHORTCUT_TMP" "$KGLOBALRC"
kquitapp6 kglobalaccel >/dev/null 2>&1 || true
success "Shortcuts & helper scripts active"

# Step 6: Reload desktop daemons
step "6/7" "Restoring KDE Plasma Environment"
sub "Updating system service cache..."
kbuildsycoca6 --noincremental
sub "Restarting Plasmashell..."
kstart plasmashell
PLASMASHELL_STOPPED=0
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

# Interactive Wallpaper Prompt
printf "\n"
printf "\033[1;36mDo you want to clone Catppuccin Mocha wallpapers to ~/Pictures/wallpapers? (y/N): \033[0m"
if ask_yes_no; then
    WALLPAPER_DIR="$HOME/Pictures/wallpapers"
    WALLPAPER_URL=https://github.com/orangci/walls-catppuccin-mocha.git
    if [ -d "$WALLPAPER_DIR" ] && \
        [ "$(git -C "$WALLPAPER_DIR" remote get-url origin 2>/dev/null || true)" = "$WALLPAPER_URL" ]; then
        sub "Updating Catppuccin Mocha wallpapers repository..."
        git -C "$WALLPAPER_DIR" pull --ff-only --progress
        success "Wallpapers repository updated"
    elif [ -e "$WALLPAPER_DIR" ]; then
        sub "The wallpaper path already exists and is not the expected repository; leaving it untouched."
    else
        mkdir -p "$HOME/Pictures"
        new_temp_dir
        sub "Cloning Catppuccin Mocha wallpapers (showing live download progress)..."
        git clone --depth 1 --progress "$WALLPAPER_URL" "$TEMP_DIR/wallpapers"
        mv "$TEMP_DIR/wallpapers" "$WALLPAPER_DIR"
        rm -rf -- "$TEMP_DIR"
        TEMP_DIR=
        success "Wallpapers repository cloned"
    fi
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
