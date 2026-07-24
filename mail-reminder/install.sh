#!/bin/zsh
#
# install_flagged_mail_reminders.sh
#
# One-click installer for flagged_mail_reminders.scpt:
#   1. Copies the AppleScript to ~/.scripts/
#   2. Generates the launchd plist (with your real username baked in)
#   3. Loads/bootstraps the LaunchAgent
#   4. Runs the script once so macOS prompts for Mail + Reminders permissions
#
# Usage:
#   chmod +x install_flagged_mail_reminders.sh
#   ./install_flagged_mail_reminders.sh
#
# Re-running this script is safe — it will unload/reload the agent and
# overwrite the plist and script copy with the current versions.

set -euo pipefail

SCRIPT_NAME="flagged_mail_reminders.scpt"
SOURCE_SCRIPT="${1:-$(pwd)/${SCRIPT_NAME}}"

SCRIPTS_DIR="${HOME}/.scripts"
DEST_SCRIPT="${SCRIPTS_DIR}/${SCRIPT_NAME}"

LABEL="com.org.flaggedmailreminders"
LAUNCH_AGENTS_DIR="${HOME}/Library/LaunchAgents"
PLIST_PATH="${LAUNCH_AGENTS_DIR}/${LABEL}.plist"

LOG_PATH="${SCRIPTS_DIR}/flagged_mail.log"
ERR_PATH="${SCRIPTS_DIR}/flagged_mail.err"

RUN_HOUR=8
RUN_MINUTE=0

autoload -U colors && colors

info()  { print -P "%F{cyan}==>%f $1" }
ok()    { print -P "%F{green}✔%f $1" }
warn()  { print -P "%F{yellow}!%f $1" }
fail()  { print -P "%F{red}✘%f $1"; exit 1 }

# --- 0. Sanity checks -------------------------------------------------

if [[ "$(uname)" != "Darwin" ]]; then
    fail "This installer only works on macOS."
fi

if [[ ! -f "$SOURCE_SCRIPT" ]]; then
    fail "Can't find ${SCRIPT_NAME} at: ${SOURCE_SCRIPT}
    Pass the path explicitly: ./install_flagged_mail_reminders.sh /path/to/${SCRIPT_NAME}"
fi

USERNAME="$(whoami)"
info "Installing for user: ${USERNAME}"

# --- 1. Copy the AppleScript ------------------------------------------

info "Copying script to ${DEST_SCRIPT}"
mkdir -p "$SCRIPTS_DIR"
cp "$SOURCE_SCRIPT" "$DEST_SCRIPT"
ok "Script installed"

# --- 2. Generate the launchd plist -------------------------------------

info "Writing LaunchAgent plist to ${PLIST_PATH}"
mkdir -p "$LAUNCH_AGENTS_DIR"

cat > "$PLIST_PATH" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>${LABEL}</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/osascript</string>
        <string>${DEST_SCRIPT}</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>${RUN_HOUR}</integer>
        <key>Minute</key>
        <integer>${RUN_MINUTE}</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>${LOG_PATH}</string>
    <key>StandardErrorPath</key>
    <string>${ERR_PATH}</string>
</dict>
</plist>
PLIST

ok "Plist written"

# --- 3. Load the LaunchAgent --------------------------------------------

UID_NUM="$(id -u)"

info "Loading LaunchAgent"
# Unload first in case a previous version is already loaded (safe to ignore errors here)
launchctl bootout "gui/${UID_NUM}" "$PLIST_PATH" 2>/dev/null || true
launchctl unload "$PLIST_PATH" 2>/dev/null || true

if launchctl bootstrap "gui/${UID_NUM}" "$PLIST_PATH" 2>/dev/null; then
    ok "Loaded via bootstrap"
elif launchctl load "$PLIST_PATH" 2>/dev/null; then
    ok "Loaded via legacy 'load'"
else
    fail "Could not load the LaunchAgent. Try running:
    launchctl bootstrap gui/${UID_NUM} ${PLIST_PATH}
    manually to see the error."
fi

# --- 4. First run — trigger permission prompts --------------------------

info "Running the script once so macOS can prompt for Mail + Reminders access..."
warn "Approve any permission dialogs that pop up now."

if osascript "$DEST_SCRIPT"; then
    ok "First run completed successfully"
else
    warn "First run exited with an error — this is normal if you haven't
    approved the permission dialogs yet. Re-run this script, or run:
    osascript ${DEST_SCRIPT}
    manually after granting Mail/Reminders automation permissions in
    System Settings > Privacy & Security > Automation."
fi

# --- Done ----------------------------------------------------------------

echo
ok "Installation complete."
print -P "  Script:   %F{cyan}${DEST_SCRIPT}%f"
print -P "  Plist:    %F{cyan}${PLIST_PATH}%f"
print -P "  Schedule: %F{cyan}${RUN_HOUR}:$(printf '%02d' ${RUN_MINUTE}) daily (runs on wake if missed)%f"
print -P "  Logs:     %F{cyan}${LOG_PATH}%f / %F{cyan}${ERR_PATH}%f"
echo
print -P "To uninstall:"
print -P "  launchctl bootout gui/${UID_NUM} ${PLIST_PATH}"
print -P "  rm ${PLIST_PATH} ${DEST_SCRIPT}"
