# Mail Reminder

## AppleScript for counting flagged mails in the Apple Mail and add them as a reminders

### Short description

`flagged_mail_reminders.scpt` scans every mailbox across all accounts in Apple Mail for flagged messages, and tallies them by flag color/category (e.g. Finance, Attention, So-So, College, Blue, Innodata, Other — customize the `flagCategoryName` list to match your own flag color usage). For each category with at least one flagged message, it creates (or replaces) a reminder in the Reminders app's default "Reminders" list, named like `Finance: 3 Messages`, due and alerting at 9:00 AM the day it runs. Any reminder left over from a previous run is deleted first, so the list always reflects the current flagged-mail counts.

### Quick install (recommended)

`install.sh` automates the entire setup below in one step: it copies the script to `~/.scripts/`, generates the `launchd` plist with your real username filled in, loads the LaunchAgent, and runs the script once so macOS can prompt for Mail/Reminders permissions.

```bash
chmod +x install.sh
./install.sh
```

Re-running it is safe — it overwrites the script copy and plist with the current versions and reloads the agent.

### Manual setup via `launchd`

If your laptop is usually open/awake around 8am (or you don't want it to force-wake from sleep just for this) `StartCalendarInterval` will simply run the job the moment the Mac wakes up if it missed the 8am trigger while asleep — that's the most battery-friendly option since it doesn't force any wake cycles.

#### 1. Save your AppleScript

Put your script at `~/.scripts/flagged_mail_reminders.scpt` (open in Script Editor, save as `.scpt`).

#### 2. Create the LaunchAgent plist

Save this as `~/Library/LaunchAgents/com.org.flaggedmailreminders.plist`:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>Label</key>
    <string>com.org.flaggedmailreminders</string>

    <key>ProgramArguments</key>
    <array>
        <string>/usr/bin/osascript</string>
        <string>/Users/YOUR_USERNAME/.scripts/flagged_mail_reminders.scpt</string>
    </array>

    <key>StartCalendarInterval</key>
    <dict>
        <key>Hour</key>
        <integer>8</integer>
        <key>Minute</key>
        <integer>0</integer>
    </dict>

    <key>StandardOutPath</key>
    <string>/Users/YOUR_USERNAME/.scripts/flagged_mail.log</string>
    <key>StandardErrorPath</key>
    <string>/Users/YOUR_USERNAME/.scripts/flagged_mail.err</string>
</dict>
</plist>
```

Replace `YOUR_USERNAME` with your actual username (run `whoami` in Terminal if unsure).

#### 3. Load it

```bash
launchctl load ~/Library/LaunchAgents/com.org.flaggedmailreminders.plist
```

#### 4. First run — grant permissions

Run it once manually so macOS prompts for Automation permissions (Mail + Reminders access):

```bash
osascript ~/Scripts/flagged_mail_reminders.scpt
```

Approve the permission dialogs. After that, launchd can run it headlessly without prompts.