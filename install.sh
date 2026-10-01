#!/bin/bash
set -Eeuo pipefail

# ── Graceful cleanup and error reporting ──────────────────────
TEMP_DIR=""
SPINNER_PID=""

cleanup() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
        SPINNER_PID=""
    fi
    if [[ -n "$TEMP_DIR" && -d "$TEMP_DIR" ]]; then
        rm -rf -- "$TEMP_DIR" 2>/dev/null || true
    fi
}

handle_error() {
    local status=$?
    stop_spinner ""
    printf "\n  %b✕%b Installer stopped at line %s (exit %s): %s\n" \
        "$C_RED$C_BOLD" "$C_RESET" "$1" "$status" "$2" >&2
    exit "$status"
}

cancelled() {
    stop_spinner ""
    printf "\n  %b✕%b %bCancelled by user%b\n\n" "$C_RED$C_BOLD" "$C_RESET" "$C_DIM" "$C_RESET"
    exit 130
}
trap cleanup EXIT
trap cancelled SIGINT TERM
trap 'handle_error "$LINENO" "$BASH_COMMAND"' ERR

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
TOTAL_STEPS=7
current_step=0

draw_progress() {
    ((current_step += 1))
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
stop_spinner() {
    if [[ -n "$SPINNER_PID" ]]; then
        kill "$SPINNER_PID" 2>/dev/null || true
        wait "$SPINNER_PID" 2>/dev/null || true
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
    (
        frames=("⠋" "⠙" "⠹" "⠸" "⠼" "⠴" "⠦" "⠧" "⠇" "⠏")
        i=0
        while true; do
            printf "\r  %b%s%b %s" "$C_YELLOW" "${frames[$((i++ % 10))]}" "$C_RESET" "$1" > /dev/tty
            sleep 0.08
        done
    ) 2>/dev/null &
    SPINNER_PID=$!
}

# ── Print Helpers ─────────────────────────────────────────────
print_banner() {
    clear
    printf "%b" "${C_CYAN}${C_BOLD}"
    cat << 'BANNER'
  ╭────────────────────────────────────────────────────────────╮
  │                                                            │
  │  NIZAR                                          RESTORE    │
  │  ARCH LINUX  /  KDE PLASMA 6                              │
  │                                                            │
  ╰────────────────────────────────────────────────────────────╯
BANNER
    printf "%b" "${C_RESET}"
    printf "  %bPersonal setup, restored with care.%b\n\n" "$C_DIM" "$C_RESET"
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

select_optional_apps() {
    local app_count=${#optional_app_names[@]}
    local focus_index=0
    local row_count=$((app_count + 3))
    local rendered=false
    local all_selected key next_key
    local app_index
    local -a selected_flags=()

    for ((app_index = 0; app_index < app_count; app_index++)); do
        selected_flags+=(false)
    done

    while true; do
        if [[ "$rendered" == true ]]; then
            printf "\033[%dA\033[J" "$row_count" > /dev/tty
        fi

        printf "  %b│%b  %bChoose optional applications%b\n" "$C_CYAN" "$C_RESET" "$C_WHITE$C_BOLD" "$C_RESET" > /dev/tty
        for ((app_index = 0; app_index < app_count; app_index++)); do
            local marker=' '
            local pointer=' '
            if [[ "${selected_flags[$app_index]}" == true ]]; then
                marker='✓'
            fi
            if (( focus_index == app_index )); then
                pointer='›'
            fi
            printf "  %b%s%b  [%b%s%b]  %s\n" "$C_CYAN$C_BOLD" "$pointer" "$C_RESET" "$C_GREEN$C_BOLD" "$marker" "$C_RESET" "${optional_app_names[$app_index]}" > /dev/tty
        done

        all_selected=true
        for app_index in "${selected_flags[@]}"; do
            if [[ "$app_index" != true ]]; then
                all_selected=false
                break
            fi
        done
        local all_marker=' '
        local all_pointer=' '
        if [[ "$all_selected" == true ]]; then
            all_marker='✓'
        fi
        if (( focus_index == app_count )); then
            all_pointer='›'
        fi
        printf "  %b%s%b  [%b%s%b]  %bSelect all%b\n" "$C_CYAN$C_BOLD" "$all_pointer" "$C_RESET" "$C_GREEN$C_BOLD" "$all_marker" "$C_RESET" "$C_WHITE$C_BOLD" "$C_RESET" > /dev/tty
        printf "  %b↑/↓ move   Space toggle   Enter confirm%b\n" "$C_DIM" "$C_RESET" > /dev/tty
        rendered=true

        if ! IFS= read -r -s -n1 key </dev/tty; then
            break
        fi
        case "$key" in
            $'\e')
                if IFS= read -r -s -n1 -t 0.1 next_key </dev/tty && [[ "$next_key" == "[" ]]; then
                    if IFS= read -r -s -n1 -t 0.1 next_key </dev/tty; then
                        case "$next_key" in
                            A) (( focus_index > 0 )) && ((focus_index -= 1)) || true ;;
                            B) (( focus_index < app_count )) && ((focus_index += 1)) || true ;;
                        esac
                    fi
                fi
                ;;
            k) (( focus_index > 0 )) && ((focus_index -= 1)) || true ;;
            j) (( focus_index < app_count )) && ((focus_index += 1)) || true ;;
            ' ')
                if (( focus_index == app_count )); then
                    if [[ "$all_selected" == true ]]; then
                        for ((app_index = 0; app_index < app_count; app_index++)); do
                            selected_flags[$app_index]=false
                        done
                    else
                        for ((app_index = 0; app_index < app_count; app_index++)); do
                            selected_flags[$app_index]=true
                        done
                    fi
                elif [[ "${selected_flags[$focus_index]}" == true ]]; then
                    selected_flags[$focus_index]=false
                else
                    selected_flags[$focus_index]=true
                fi
                ;;
            '')
                selected_packages=()
                for ((app_index = 0; app_index < app_count; app_index++)); do
                    if [[ "${selected_flags[$app_index]}" == true ]]; then
                        selected_packages+=("${optional_app_packages[$app_index]}")
                    fi
                done
                printf "\n" > /dev/tty
                break
                ;;
        esac
    done
}

# ── Main ──────────────────────────────────────────────────────
print_banner
printf "  %b●%b %bInitializing workspace restore...%b\n" "$C_CYAN" "$C_RESET" "$C_DIM" "$C_RESET"

if [[ ${EUID:-$(id -u)} -eq 0 ]]; then
    printf "Run this installer as your regular user, not as root. It will use sudo when needed.\n" >&2
    exit 1
fi
command -v pacman >/dev/null
command -v sudo >/dev/null
if [[ ${KDE_SESSION_VERSION:-} != 6 ]]; then
    printf "Run this installer from a logged-in KDE Plasma 6 session.\n" >&2
    exit 1
fi
for command_name in kpackagetool6 kquitapp6 kbuildsycoca6 plasmashell; do
    if ! command -v "$command_name" >/dev/null 2>&1; then
        printf "Required KDE command is missing: %s. Install or repair Plasma 6 first.\n" "$command_name" >&2
        exit 1
    fi
done

export PATH="$HOME/.local/bin:$PATH"

# Pre-authenticate sudo safely on the main thread
printf "  %b⏳%b %bAuthenticating sudo (if required)...%b " "$C_YELLOW" "$C_RESET" "$C_DIM" "$C_RESET"
sudo -v
printf "%b✔%b\n" "$C_GREEN$C_BOLD" "$C_RESET"

# Step 1
step "1/7" "Synchronizing System Packages & Widgets"
sub "Installing Discord, Asusctl, KDE applets, Chezmoi, and build tools..."
sudo pacman -Syu --noconfirm --needed asusctl base-devel chezmoi curl dbus discord git kdeconnect kdeplasma-addons materia-kde papirus-icon-theme pkgconf rust
stop_spinner "Essential packages ready"

sub "Fetching Vertical Clock repository..."
TEMP_DIR=$(mktemp -d)
start_spinner "Cloning plasma-vertical-clock..."
git clone --quiet https://github.com/Cyberbessa/plasma-vertical-clock.git "$TEMP_DIR/plasma-vertical-clock"
stop_spinner "Repository cloned"

sub "Registering Vertical Clock applet..."
kpackagetool6 --type Plasma/Applet --install "$TEMP_DIR/plasma-vertical-clock/vertical-clock.plasmoid" || \
    kpackagetool6 --type Plasma/Applet --upgrade "$TEMP_DIR/plasma-vertical-clock/vertical-clock.plasmoid"
rm -rf -- "$TEMP_DIR"
TEMP_DIR=""
success "Vertical Clock widget installed"

sub "Installing Plasma Gnome Pager..."
TEMP_DIR=$(mktemp -d)
start_spinner "Cloning plasma-gnome-pager..."
git clone --quiet https://github.com/KenanSalar/plasma-gnome-pager.git "$TEMP_DIR/plasma-gnome-pager"
stop_spinner "Repository cloned"
kpackagetool6 --type Plasma/Applet --install "$TEMP_DIR/plasma-gnome-pager/package" || \
    kpackagetool6 --type Plasma/Applet --upgrade "$TEMP_DIR/plasma-gnome-pager/package"
rm -rf -- "$TEMP_DIR"
TEMP_DIR=""
success "Plasma Gnome Pager installed"
step_done

# Step 2
step "2/7" "Select Optional Applications"
optional_app_names=("ROG Control Center" "Floorp")
optional_app_packages=("rog-control-center" "floorp-bin")
selected_packages=()

if [[ -r /dev/tty && -w /dev/tty ]]; then
    printf "  %b│%b  Apps are built from the Arch User Repository (AUR).\n" "$C_CYAN" "$C_RESET"
    select_optional_apps
else
    info "No interactive terminal available; skipping optional apps"
fi

if (( ${#selected_packages[@]} == 0 )); then
    info "No optional apps selected"
else
    for app_package in "${selected_packages[@]}"; do
        sub "Building $app_package from the AUR..."
        TEMP_DIR=$(mktemp -d)
        git clone --quiet "https://aur.archlinux.org/${app_package}.git" "$TEMP_DIR/$app_package"
        (cd "$TEMP_DIR/$app_package" && makepkg --syncdeps --install --noconfirm)
        rm -rf -- "$TEMP_DIR"
        TEMP_DIR=""
        success "$app_package installed"
    done
fi
step_done

# Step 3
step "3/7" "Verifying System Utilities"
if ! command -v kdotool >/dev/null 2>&1; then
    sub "Building kdotool from source..."
    TEMP_DIR=$(mktemp -d)
    start_spinner "Cloning kdotool..."
    git clone --quiet https://github.com/jinliu/kdotool.git "$TEMP_DIR/kdotool"
    stop_spinner "Repository cloned"

    start_spinner "Compiling with Rust (this may take a moment)..."
    cargo build --quiet --release --manifest-path "$TEMP_DIR/kdotool/Cargo.toml"
    install -Dm755 "$TEMP_DIR/kdotool/target/release/kdotool" "$HOME/.local/bin/kdotool"
    rm -rf -- "$TEMP_DIR"
    TEMP_DIR=""
    stop_spinner "kdotool installed in ~/.local/bin"
else
    info "kdotool already present — skipping build"
fi
step_done

# Step 4
step "4/7" "Applying Chezmoi Dotfiles"
sub "Stopping Plasmashell safely..."
kquitapp6 plasmashell >/dev/null 2>&1 || true
sleep 1
success "Plasmashell stopped"

CHEZMOI_SRC="$(chezmoi source-path)"

if [ -d "$CHEZMOI_SRC/.git" ]; then
    sub "Dotfiles repository found — pulling latest changes..."
    start_spinner "Syncing dotfiles..."
    git -C "$CHEZMOI_SRC" pull --ff-only
    chezmoi apply --force
    stop_spinner "Dotfiles updated and applied"
else
    sub "No dotfiles repository found — initializing..."
    start_spinner "Cloning & applying dotfiles from nizar2004..."
    chezmoi init --apply --force nizar2004
    stop_spinner "Dotfiles initialized and applied"
fi
step_done

# Step 5
step "5/7" "Verifying Managed Helpers & Hotkeys"
[[ -x "$HOME/.local/bin/toggle-discord.sh" ]]
[[ -f "$HOME/.local/share/applications/net.local.toggle-discord.sh.desktop" ]]
success "Discord helper and Meta+Shift+D shortcut applied from chezmoi"
step_done

# Step 6
step "6/7" "Restoring KDE Plasma Environment"
sub "Updating system service cache..."
kbuildsycoca6 --noincremental
success "Service cache rebuilt"

sub "Restarting Plasmashell..."
plasmashell --replace >/dev/null 2>&1 &
success "Desktop environment reloaded"
step_done

# Step 7
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

git add -- .
if git diff --cached --quiet; then
    echo "No new changes to backup."
    exit 0
fi

git commit -m "Auto-backup workspace: $(date +'%Y-%m-%d %H:%M:%S')"
git push

echo "✔ Successfully backed up to GitHub!"
EOF
chmod +x "$HOME/.local/bin/backup"
success "'backup' command is now available at ~/.local/bin/backup"
step_done
