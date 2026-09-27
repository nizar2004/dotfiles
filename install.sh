#!/bin/bash

# ── Graceful Exit on Ctrl+C ───────────────────────────────────
cleanup() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
    fi
    printf "\r%*s\r" 80 ""
    printf "\n  %b✕%b %bCancelled by user%b\n\n" "$C_RED$C_BOLD" "$C_RESET" "$C_DIM" "$C_RESET"
    exit 1
}
trap cleanup SIGINT

# ── ANSI Colors & Styles ──────────────────────────────────────
C_RESET='\033[0m'
C_BOLD='\033[1m'
C_DIM='\033[2m'
C_CYAN='\033[1;36m'
C_MAGENTA='\033[1;35m'
C_GREEN='\033[1;32m'
C_YELLOW='\033[1;33m'
C_WHITE='\033[1;37m'
C_GRAY='\033[0;90m'
C_RED='\033[1;31m'

# ── Progress Bar ──────────────────────────────────────────────
TOTAL_STEPS=9
current_step=0

draw_progress() {
    ((current_step++))
    local filled=$((current_step * 30 / TOTAL_STEPS))
    local empty=$((30 - filled))
    local bar=""
    local i
    
    for ((i=0; i<filled; i++)); do bar+="█"; done
    for ((i=0; i<empty; i++)); do bar+="░"; done
    
    local pct=$((current_step * 100 / TOTAL_STEPS))
    printf "\r  %b[%s]%b %b%3d%%%b" "$C_CYAN" "$bar" "$C_RESET" "$C_BOLD" "$pct" "$C_RESET"
}

# ── Robust Spinner ────────────────────────────────────────────
SPINNER_PID=""

stop_spinner() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null
        wait "$SPINNER_PID" 2>/dev/null
        SPINNER_PID=""
    fi
    
    if [[ -z "$1" ]]; then
        printf "\r%*s\r" 80 ""
    else
        printf "\r  %b✔%b  %s\n" "$C_GREEN$C_BOLD" "$C_RESET" "$1"
    fi
}

start_spinner() {
    stop_spinner ""
    
    coproc SPINNER {
        local frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
        local i=0
        while true; do
            printf "\r  %b%s%b %s" "$C_YELLOW" "${frames[$((i++ % 10))]}" "$C_RESET" "$1" > /dev/tty
            sleep 0.08
        done
    } 2>/dev/null
        
    SPINNER_PID=$SPINNER_PID
}

# ── Print Helpers ─────────────────────────────────────────────
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
  │              ✦  ARCH LINUX · KDE PLASMA  ✦                 │
  │                       by Nizar                             │
  │                                                            │
  ╰────────────────────────────────────────────────────────────╯
BANNER
    printf "%b\n" "${C_RESET}"
}

step() {
    stop_spinner ""
    printf "\n"
    draw_progress
    printf "\n  %b┌─%b %b[%s]%b %b%s%b\n" "$C_CYAN" "$C_RESET" "$C_CYAN$C_BOLD" "$1" "$C_RESET" "$C_WHITE$C_BOLD" "$2" "$C_RESET"
}

sub() {
    printf "  %b│%b  %b➜%b %b%s%b\n" "$C_CYAN" "$C_RESET" "$C_MAGENTA" "$C_RESET" "$C_DIM" "$1" "$C_RESET"
}

success() {
    printf "  %b│%b  %b✔%b %b%s%b\n" "$C_CYAN" "$C_RESET" "$C_GREEN$C_BOLD" "$C_RESET" "$C_GREEN" "$1" "$C_RESET"
}

info() {
    printf "  %b│%b  %b●%b %b%s%b\n" "$C_CYAN" "$C_RESET" "$C_CYAN" "$C_RESET" "$C_GRAY" "$1" "$C_RESET"
}

step_done() {
    printf "  %b└─%b %bDone%b\n" "$C_CYAN" "$C_RESET" "$C_GREEN$C_BOLD" "$C_RESET"
}

ask_prompt() {
    printf "\n  %b?%b %b%s%b " "$C_YELLOW$C_BOLD" "$C_RESET" "$C_WHITE$C_BOLD" "$1" "$C_RESET"
    printf "%b[y/N]%b " "$C_DIM" "$C_RESET"
}

# ── Main ──────────────────────────────────────────────────────
print_banner
printf "  %b●%b %bInitializing workspace restore...%b\n" "$C_CYAN" "$C_RESET" "$C_DIM" "$C_RESET"

# Pre-authenticate sudo safely on the main thread
printf "  %b⏳%b %bAuthenticating sudo (if required)...%b " "$C_YELLOW" "$C_RESET" "$C_DIM" "$C_RESET"
sudo -v
printf "%b✔%b\n" "$C_GREEN$C_BOLD" "$C_RESET"

# Step 1
step "1/9" "Synchronizing System Packages & Widgets"
sub "Installing discord, papirus-icon-theme, Vertical Clock Widget, cargo, dbus..."
start_spinner "Downloading & installing packages..."
sudo pacman -S --noconfirm --needed --quiet discord asusctl papirus-icon-theme base-devel git cargo pkgconf dbus >/dev/null 2>&1
stop_spinner "Essential packages ready"

sub "Fetching Vertical Clock repository..."
TEMP_CLOCK_DIR=$(mktemp -d)
start_spinner "Cloning plasma-vertical-clock..."
git clone --quiet https://github.com/Cyberbessa/plasma-vertical-clock.git "$TEMP_CLOCK_DIR" >/dev/null 2>&1
stop_spinner "Repository cloned"

sub "Registering Vertical Clock applet..."
kpackagetool6 --type Plasma/Applet --install "$TEMP_CLOCK_DIR" >/dev/null 2>&1 || \
kpackagetool6 --type Plasma/Applet --upgrade "$TEMP_CLOCK_DIR" >/dev/null 2>&1 || true
rm -rf "$TEMP_CLOCK_DIR"
success "Vertical Clock widget installed"
step_done

# Step 2
step "2/9" "Installing Advanced Separator Widget"
TEMP_WIDGET_DIR=$(mktemp -d)
sub "Fetching widget repository..."
start_spinner "Cloning plasma-advanced-separator..."
git clone --quiet https://github.com/luisbocanegra/plasma-advanced-separator.git "$TEMP_WIDGET_DIR" >/dev/null 2>&1
stop_spinner "Repository cloned"

sub "Registering Plasma applet..."
kpackagetool6 --type Plasma/Applet --install "$TEMP_WIDGET_DIR" >/dev/null 2>&1 || \
kpackagetool6 --type Plasma/Applet --upgrade "$TEMP_WIDGET_DIR" >/dev/null 2>&1 || true

PLASMOID_TARGET="$HOME/.local/share/plasma/plasmoids/luisbocanegra.advanced_separator"
mkdir -p "$PLASMOID_TARGET"
cp -rf "$TEMP_WIDGET_DIR"/* "$PLASMOID_TARGET/"
rm -rf "$TEMP_WIDGET_DIR"
success "Advanced Separator widget installed"
step_done

# Step 3
step "3/9" "Verifying System Utilities"
if ! command -v kdotool >/dev/null 2>&1; then
    sub "Building kdotool from source..."
    TEMP_DIR=$(mktemp -d)
    start_spinner "Cloning kdotool..."
    git clone --quiet https://github.com/jinliu/kdotool.git "$TEMP_DIR/kdotool" >/dev/null 2>&1
    stop_spinner "Repository cloned"

    start_spinner "Compiling with cargo (this may take a moment)..."
    cd "$TEMP_DIR/kdotool" || exit 1
    cargo build --release --quiet 2>/dev/null
    sudo install -Dm755 target/release/kdotool /usr/local/bin/kdotool
    cd - > /dev/null
    rm -rf "$TEMP_DIR"
    stop_spinner "kdotool binary compiled & installed"
else
    info "kdotool already present — skipping build"
fi
step_done

# Step 4
step "4/9" "Applying Chezmoi Dotfiles"
sub "Stopping Plasmashell safely..."
kquitapp6 plasmashell >/dev/null 2>&1 || true
sleep 1
success "Plasmashell stopped"

if ! command -v chezmoi >/dev/null 2>&1; then
    sub "Chezmoi not found — installing..."
    start_spinner "Downloading chezmoi..."
    sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin" >/dev/null 2>&1
    stop_spinner "Chezmoi installed"
else
    info "Chezmoi binary already present"
fi

CHEZMOI_SRC="$(chezmoi source-path 2>/dev/null || echo "$HOME/.local/share/chezmoi")"

if [ -d "$CHEZMOI_SRC/.git" ]; then
    sub "Dotfiles repository found — pulling latest changes..."
    start_spinner "Syncing dotfiles..."
    git -C "$CHEZMOI_SRC" pull --quiet 2>/dev/null
    chezmoi apply --force >/dev/null 2>&1
    stop_spinner "Dotfiles updated and applied"
else
    sub "No dotfiles repository found — initializing..."
    start_spinner "Cloning & applying dotfiles from nizar2004..."
    chezmoi init --apply --force nizar2004 >/dev/null 2>&1
    stop_spinner "Dotfiles initialized and applied"
fi
step_done

# Step 5
step "5/9" "Configuring Helpers & Hotkeys"
mkdir -p "$HOME/.local/bin"
sub "Fetching Discord toggle helper..."
start_spinner "Downloading toggle-discord.sh..."
curl -fsLS https://raw.githubusercontent.com/nizar2004/dotfiles/main/toggle-discord.sh -o "$HOME/.local/bin/toggle-discord.sh" 2>/dev/null
chmod +x "$HOME/.local/bin/toggle-discord.sh"
stop_spinner "Helper script downloaded"

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
success "Desktop entry created"

sub "Registering Meta+Shift+D shortcut service..."
pkill -9 kglobalaccel6 2>/dev/null || true
KGLOBLALRC="$HOME/.config/kglobalshortcutsrc"
sed -i '/net.local.toggle-discord/d' "$KGLOBLALRC" 2>/dev/null || true
echo "" >> "$KGLOBLALRC"
echo "[services][net.local.toggle-discord.sh.desktop]" >> "$KGLOBLALRC"
echo "_launch=Meta+Shift+D" >> "$KGLOBLALRC"
success "Meta+Shift+D shortcut registered"
step_done

# Step 6
step "6/9" "Restoring KDE Plasma Environment"
sub "Updating system service cache..."
kbuildsycoca6 --noincremental >/dev/null 2>&1 || true
success "Service cache rebuilt"

sub "Restarting Plasmashell..."
kstart plasmashell >/dev/null 2>&1 &
success "Desktop environment reloaded"
step_done

# Step 7
step "7/9" "Setting up 'backup' command utility"
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
success "'backup' command is now available at ~/.local/bin/backup"
step_done

# Step 8: Interactive — Necessary Appsg
step "8/9" "Optional — Install Necessary Apps"
ask_prompt "Do you want to install your necessary apps?"
if read -r REPLY </dev/tty; then
    case "$REPLY" in
        [yY][eE][sS]|[yY])
            start_spinner "Installing necessary apps..."
            sudo pacman -S --noconfirm --needed --quiet asusctl >/dev/null 2>&1
            stop_spinner "Necessary apps installed"
            ;;
        *)
            info "Skipped"
            ;;
    esac
else
    info "Skipped"
fi
step_done