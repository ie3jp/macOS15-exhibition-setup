#!/bin/zsh
# =============================================================================
# macOS 15 Sequoia / Apple Silicon - Exhibition Machine Setup Script
# =============================================================================
#
# Author: rettuce (Original: 2015, Updated: 2025)
# Target: macOS 15 (Sequoia) or later, Apple Silicon only
# Purpose: Configure Mac for unattended exhibition/kiosk use
#
# Usage:
#   chmod +x macOS15-exhibition-setup.command
#   ./macOS15-exhibition-setup.command
#
# Note: Some settings require System Integrity Protection (SIP) considerations
#       and may need manual confirmation in System Settings.
# =============================================================================

set -e

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

print_section() {
    echo ""
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo "${BLUE}▶ $1${NC}"
    echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

print_status() {
    echo "${GREEN}✓${NC} $1"
}

print_warning() {
    echo "${YELLOW}⚠${NC} $1"
}

print_error() {
    echo "${RED}✗${NC} $1"
}

print_manual() {
    echo "${YELLOW}📋 MANUAL:${NC} $1"
}

# Check if running on Apple Silicon
check_apple_silicon() {
    if [[ $(uname -m) != "arm64" ]]; then
        print_error "This script is designed for Apple Silicon Macs only."
        print_error "Detected architecture: $(uname -m)"
        exit 1
    fi
}

# Check macOS version
check_macos_version() {
    local version=$(sw_vers -productVersion)
    local major_version=$(echo $version | cut -d. -f1)

    if [[ $major_version -lt 15 ]]; then
        print_error "This script requires macOS 15 (Sequoia) or later."
        print_error "Current version: $version"
        exit 1
    fi
    print_status "macOS version: $version (OK)"
}

# =============================================================================
# MAIN SCRIPT
# =============================================================================

echo ""
echo "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo "${GREEN}║  macOS 15 Sequoia - Exhibition Machine Setup                 ║${NC}"
echo "${GREEN}║  For Apple Silicon Macs                                      ║${NC}"
echo "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Pre-flight checks
print_section "Pre-flight Checks"
check_apple_silicon
print_status "Apple Silicon detected: $(sysctl -n machdep.cpu.brand_string)"
check_macos_version

# =============================================================================
print_section "Desktop & Screen Saver"
# =============================================================================

# Set desktop to solid black (using dynamic desktop with dark appearance)
echo "Setting desktop to solid color..."
# macOS 15 uses different path for solid colors
if [[ -f "/System/Library/Desktop Pictures/Solid Colors/Black.png" ]]; then
    osascript -e 'tell application "Finder" to set desktop picture to POSIX file "/System/Library/Desktop Pictures/Solid Colors/Black.png"' 2>/dev/null && \
        print_status "Desktop set to Black" || \
        print_warning "Could not set desktop picture via AppleScript"
elif [[ -f "/System/Library/Desktop Pictures/Solid Colors/Stone.png" ]]; then
    osascript -e 'tell application "Finder" to set desktop picture to POSIX file "/System/Library/Desktop Pictures/Solid Colors/Stone.png"' 2>/dev/null && \
        print_status "Desktop set to Stone (dark gray)" || \
        print_warning "Could not set desktop picture via AppleScript"
else
    print_warning "Solid color wallpapers not found at expected path"
    print_manual "Set desktop manually: System Settings > Wallpaper > Colors"
fi

# Disable screen saver
echo "Disabling screen saver..."
defaults write com.apple.screensaver idleTime -int 0
defaults -currentHost write com.apple.screensaver idleTime -int 0
print_status "Screen saver disabled"

# Disable screen saver password requirement
defaults write com.apple.screensaver askForPassword -int 0
defaults -currentHost write com.apple.screensaver askForPassword -int 0
print_status "Screen saver password requirement disabled"

# =============================================================================
print_section "Dock Settings"
# =============================================================================

# Function to add app to Dock
add_app_to_dock() {
    local app_path="$1"
    if [[ -e "$app_path" ]]; then
        defaults write com.apple.dock persistent-apps -array-add \
            "<dict><key>tile-data</key><dict><key>file-data</key><dict><key>_CFURLString</key><string>$app_path</string><key>_CFURLStringType</key><integer>0</integer></dict></dict></dict>"
        print_status "Added to Dock: $(basename "$app_path" .app)"
    else
        print_warning "App not found, skipped: $app_path"
    fi
}

# Position dock on bottom
echo "Configuring Dock..."
defaults write com.apple.dock orientation -string 'bottom'
print_status "Dock position: bottom"

# Auto-hide dock
defaults write com.apple.dock autohide -bool true
defaults write com.apple.dock autohide-delay -float 0
defaults write com.apple.dock autohide-time-modifier -float 0.5
print_status "Dock auto-hide enabled"

# Minimize dock size
defaults write com.apple.dock tilesize -int 36
print_status "Dock size minimized"

# Don't show recent applications in Dock
defaults write com.apple.dock show-recents -bool false
print_status "Recent apps in Dock disabled"

# Set custom Dock apps
echo "Setting Dock applications..."
defaults write com.apple.dock persistent-apps -array
add_app_to_dock "/System/Applications/Finder.app"
add_app_to_dock "/Applications/Google Chrome.app"
add_app_to_dock "/System/Applications/System Settings.app"
add_app_to_dock "/System/Applications/Utilities/Terminal.app"
add_app_to_dock "/System/Applications/Utilities/Activity Monitor.app"
print_status "Dock apps configured"

# =============================================================================
print_section "Mission Control & Spaces"
# =============================================================================

# Disable separate spaces for displays (important for multi-display exhibitions)
defaults write com.apple.spaces spans-displays -bool true
print_status "Displays share single Space"

# Disable auto-rearrange Spaces based on most recent use
defaults write com.apple.dock mru-spaces -bool false
print_status "Auto-rearrange Spaces disabled"

# Disable Mission Control animations for faster response
defaults write com.apple.dock expose-animation-duration -float 0.1
print_status "Mission Control animations minimized"

# =============================================================================
print_section "Notifications (macOS 15)"
# =============================================================================

# Note: Direct disabling of Notification Center is no longer possible via launchctl
# due to System Integrity Protection. Use Do Not Disturb instead.

echo "Configuring notification settings..."

# Disable notification previews when locked
defaults write com.apple.ncprefs content_visibility -int 0
print_status "Notification previews disabled on lock screen"

# Schedule Do Not Disturb (Focus mode) - requires manual setup
print_warning "Notification Center cannot be fully disabled programmatically on macOS 15"
print_manual "Enable Focus mode: System Settings > Focus > Do Not Disturb"
print_manual "Schedule: 00:00 - 23:59 (all day)"

# Suppress Tips app notifications
defaults write com.apple.tips suggestionsDisabled -bool true
print_status "Tips app suggestions disabled"

# Suppress Apple Intelligence notifications (macOS 15.1+)
defaults write com.apple.suggestions SuggestionsAllowed -bool false
print_status "Apple Intelligence suggestions disabled"

# =============================================================================
print_section "Energy & Power Management (Apple Silicon)"
# =============================================================================

echo "Configuring power settings..."

# Disable system sleep
sudo pmset -a sleep 0
print_status "System sleep disabled"

# Disable display sleep
sudo pmset -a displaysleep 0
print_status "Display sleep disabled"

# Disable disk sleep
sudo pmset -a disksleep 0
print_status "Disk sleep disabled"

# Wake on network access (Wake on LAN)
sudo pmset -a womp 1
print_status "Wake on LAN enabled"

# Disable Power Nap (prevents background activity during sleep)
sudo pmset -a powernap 0
print_status "Power Nap disabled"

# Disable proximity wake (prevents wake when iPhone/Apple Watch nearby)
sudo pmset -a proximitywake 0
print_status "Proximity wake disabled"

# Disable TCP keepalive during sleep
sudo pmset -a tcpkeepalive 0
print_status "TCP keepalive during sleep disabled"

# Auto restart after power failure (critical for exhibitions)
sudo pmset -a autorestart 1
print_status "Auto restart after power failure enabled"

# Disable Low Power Mode for consistent performance
sudo pmset -a lowpowermode 0
print_status "Low Power Mode disabled"

# Prevent idle sleep (additional safety)
sudo pmset -a sleep 0 disablesleep 1
print_status "Idle sleep prevention enabled"

# Disable standby (deep sleep) - important for instant wake
sudo pmset -a standby 0
sudo pmset -a autopoweroff 0
print_status "Standby/Autopoweroff disabled"

# =============================================================================
print_section "Mouse & Trackpad"
# =============================================================================

echo "Configuring input devices..."

# Disable natural scrolling (traditional scroll direction)
defaults write NSGlobalDomain com.apple.swipescrolldirection -bool false
print_status "Natural scrolling disabled"

# Enable secondary click (right-click) for mice
defaults write com.apple.driver.AppleBluetoothMultitouch.mouse MouseButtonMode -string 'TwoButton'
defaults write com.apple.AppleMultitouchMouse MouseButtonMode -string 'TwoButton'
print_status "Mouse secondary click enabled"

# Disable mouse acceleration (useful for precise control in exhibitions)
defaults write NSGlobalDomain com.apple.mouse.scaling -float 0
print_status "Mouse acceleration disabled"

# =============================================================================
print_section "User & Login Settings"
# =============================================================================

echo "Configuring login settings..."

# Setup auto login
# Note: This requires FileVault to be disabled and may prompt for password
CURRENT_USER=$(whoami)
sudo defaults write /Library/Preferences/com.apple.loginwindow autoLoginUser "$CURRENT_USER"
print_status "Auto login configured for user: $CURRENT_USER"
print_warning "Auto login requires FileVault to be disabled"

# Disable login window input menu
sudo defaults write /Library/Preferences/com.apple.loginwindow showInputMenu -bool false
print_status "Login input menu disabled"

# Disable guest account
sudo defaults write /Library/Preferences/com.apple.loginwindow GuestEnabled -bool false
print_status "Guest account disabled"

# Hide sleep, restart, and shut down buttons on login window
sudo defaults write /Library/Preferences/com.apple.loginwindow PowerOffDisabled -bool true
sudo defaults write /Library/Preferences/com.apple.loginwindow RestartDisabled -bool true
sudo defaults write /Library/Preferences/com.apple.loginwindow ShutDownDisabled -bool true
print_status "Power buttons hidden on login window"

# =============================================================================
print_section "Software Update & App Store"
# =============================================================================

echo "Disabling automatic updates..."

# Disable automatic update check
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticCheckEnabled -bool false
print_status "Automatic update check disabled"

# Disable automatic download of updates
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate AutomaticDownload -bool false
print_status "Automatic download disabled"

# Disable critical update installs
sudo defaults write /Library/Preferences/com.apple.SoftwareUpdate CriticalUpdateInstall -bool false
print_status "Critical update auto-install disabled"

# Disable automatic app updates from App Store
sudo defaults write /Library/Preferences/com.apple.commerce AutoUpdate -bool false
print_status "App Store auto-updates disabled"

# Suppress update notifications (set future date)
defaults write com.apple.SoftwareUpdate MajorOSUserNotificationDate -date "2030-01-01 00:00:00 +0000"
defaults write com.apple.SoftwareUpdate UserNotificationDate -date "2030-01-01 00:00:00 +0000"
print_status "Update notifications suppressed"

# =============================================================================
print_section "Security & Gatekeeper (macOS 15)"
# =============================================================================

echo "Configuring security settings..."

# Note: spctl --master-disable now requires manual confirmation in macOS 15
# Attempt to trigger the setting, user must confirm in System Settings
sudo spctl --master-disable 2>/dev/null || true
print_warning "Gatekeeper: Manual confirmation required in System Settings"
print_manual "System Settings > Privacy & Security > Allow apps from: Anywhere"
print_manual "(Keep System Settings open, run spctl command, then select 'Anywhere')"

# Disable quarantine for downloaded apps
defaults write com.apple.LaunchServices LSQuarantine -bool false
print_status "Download quarantine warning disabled"

# =============================================================================
print_section "Finder & System Utilities"
# =============================================================================

echo "Configuring Finder and utilities..."

# Show Library folder
chflags nohidden ~/Library
print_status "~/Library folder visible"

# Avoid creating .DS_Store on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true
print_status "Network .DS_Store creation disabled"

# Avoid creating .DS_Store on USB volumes
defaults write com.apple.desktopservices DSDontWriteUSBStores -bool true
print_status "USB .DS_Store creation disabled"

# Disable extension change warning
defaults write com.apple.finder FXEnableExtensionChangeWarning -bool false
print_status "Extension change warning disabled"

# Disable empty trash warning
defaults write com.apple.finder WarnOnEmptyTrash -bool false
print_status "Empty trash warning disabled"

# =============================================================================
print_section "Crash & Error Handling"
# =============================================================================

echo "Configuring crash handling..."

# Disable app state restoration (prevents "reopen windows" dialog)
defaults write NSGlobalDomain NSQuitAlwaysKeepsWindows -bool false
print_status "Window restoration on quit disabled"

# Disable Resume system-wide
defaults write com.apple.systempreferences NSQuitAlwaysKeepsWindows -bool false
print_status "System-wide Resume disabled"

# Disable app persistence
defaults write -g ApplePersistenceIgnoreState -bool true
print_status "App persistence disabled"

# Disable crash reporter dialog
defaults write com.apple.CrashReporter DialogType none
print_status "Crash reporter dialog disabled"

# Disable submitting crash reports
defaults write com.apple.CrashReporter UseUNC 1
print_status "Crash report submission disabled"

# =============================================================================
print_section "Additional Exhibition Settings"
# =============================================================================

echo "Applying additional exhibition optimizations..."

# Disable Spotlight indexing for better performance (optional)
# sudo mdutil -a -i off
# print_status "Spotlight indexing disabled"

# Disable Time Machine prompts for new disks
defaults write com.apple.TimeMachine DoNotOfferNewDisksForBackup -bool true
print_status "Time Machine new disk prompts disabled"

# Disable Bluetooth setup assistant
defaults write com.apple.systemuiserver "NSStatusItem Visible com.apple.menuextra.bluetooth" -bool false 2>/dev/null || true
print_status "Bluetooth setup assistant suppressed"

# Disable Photos auto-opening when devices connect
defaults -currentHost write com.apple.ImageCapture disableHotPlug -bool true
print_status "Photos auto-open disabled"

# Disable AirDrop
defaults write com.apple.NetworkBrowser DisableAirDrop -bool true
print_status "AirDrop disabled"

# Disable Handoff
defaults write ~/Library/Preferences/ByHost/com.apple.coreservices.useractivityd.plist ActivityAdvertisingAllowed -bool false
defaults write ~/Library/Preferences/ByHost/com.apple.coreservices.useractivityd.plist ActivityReceivingAllowed -bool false
print_status "Handoff disabled"

# Disable automatic termination of inactive apps
defaults write NSGlobalDomain NSDisableAutomaticTermination -bool true
print_status "Automatic app termination disabled"

# =============================================================================
print_section "Applying Changes"
# =============================================================================

echo "Restarting affected services..."

# Restart Dock
killall Dock 2>/dev/null || true
print_status "Dock restarted"

# Restart Finder
killall Finder 2>/dev/null || true
print_status "Finder restarted"

# Restart SystemUIServer (for menu bar changes)
killall SystemUIServer 2>/dev/null || true
print_status "SystemUIServer restarted"

# =============================================================================
print_section "Summary & Manual Steps Required"
# =============================================================================

echo ""
echo "${GREEN}╔══════════════════════════════════════════════════════════════╗${NC}"
echo "${GREEN}║  Setup Complete!                                             ║${NC}"
echo "${GREEN}╚══════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "${YELLOW}The following steps require manual configuration:${NC}"
echo ""
echo "1. ${YELLOW}Gatekeeper (Allow apps from Anywhere):${NC}"
echo "   • Open System Settings > Privacy & Security"
echo "   • Keep the window open"
echo "   • Run: sudo spctl --master-disable"
echo "   • Select 'Anywhere' under 'Allow applications from'"
echo ""
echo "2. ${YELLOW}Focus Mode (Do Not Disturb):${NC}"
echo "   • System Settings > Focus > Do Not Disturb"
echo "   • Set schedule: 00:00 to 23:59"
echo "   • Or use Control Center to enable manually"
echo ""
echo "3. ${YELLOW}Auto Login:${NC}"
echo "   • Ensure FileVault is disabled"
echo "   • System Settings > Users & Groups > Auto login"
echo ""
echo "4. ${YELLOW}Startup Items (if needed):${NC}"
echo "   • System Settings > General > Login Items"
echo "   • Add your exhibition application"
echo ""
echo "5. ${YELLOW}Full Disk Access (if required):${NC}"
echo "   • System Settings > Privacy & Security > Full Disk Access"
echo "   • Add Terminal or your exhibition app"
echo ""
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "${GREEN}A system restart is recommended to apply all changes.${NC}"
echo "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

read -p "Press Enter to continue, or Ctrl+C to exit..."
