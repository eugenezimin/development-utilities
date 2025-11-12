# ICS Calendar Event Filter

A Python script to filter calendar events from ICS files based on a cutoff date. Remove old events and keep only future events in your calendar files. Useful when you don't want to import the whole calendar, but need to leave the only last month(-s) events.

This project came from the Apple Calendar limitations, as Apple doesn't allow to store more than 50,000 events in one calendar on iCloud, thus many things become broken, like syncing, ability to add new events, etc.

## Author

Eugene Zimin

## Features

- ✅ Filter ICS calendar files by date
- ✅ Interactive command-line interface
- ✅ Handles file paths with spaces
- ✅ Supports multiple date formats
- ✅ Preserves calendar metadata and timezone information
- ✅ Provides helpful output filename suggestions
- ✅ Shows statistics of removed and kept events

## Requirements

- Python 3.6 or higher
- No external dependencies (uses only standard library)

## Installation

1. Download the `filter_calendar.py` script
2. Make it executable (optional):
   ```bash
   chmod +x filter_calendar.py
   ```

## Usage

Run the script:

```bash
python3 filter_calendar.py
```

The script will prompt you for three inputs:

### 1. Input Calendar File Path

Enter the path to your ICS calendar file. The script handles:
- Paths with spaces
- Paths with quotes
- Home directory shortcut (`~`)
- Relative paths

**Examples:**
```
/Users/username/Desktop/calendar.ics
~/Desktop/calendar.ics
"~/Desktop/folder with spaces/calendar.ics"
```

### 2. Output Calendar File Path

You can either:
- Press Enter to use the suggested filename (same directory as input)
- Enter a custom filename
- Enter a full path

**Suggested options:**
1. `filename_filtered.ics` (default)
2. `filename_cleaned.ics`
3. `filename_new.ics`
4. Custom name

### 3. Cutoff Date

Enter the date before which all events will be removed.

**Supported formats:**
- `YYYY-MM-DD` (e.g., `2025-11-01`)
- `YYYY/MM/DD` (e.g., `2025/11/01`)
- `DD-MM-YYYY` (e.g., `01-11-2025`)
- `DD/MM/YYYY` (e.g., `01/11/2025`)
- `MM-DD-YYYY` (e.g., `11-01-2025`)
- `MM/DD/YYYY` (e.g., `11/01/2025`)

## Example Session

```
============================================================
ICS Calendar Event Filter
============================================================

Enter input calendar file path: ~/Desktop/green.ics

Suggested output filenames:
  1. green_filtered.ics
  2. green_cleaned.ics
  3. green_new.ics
  4. custom (you'll specify)

Enter output calendar file path (or press Enter for option 1): 
Using: green_filtered.ics

Enter cutoff date (events before this date will be removed)
Format examples:
  - 2025-11-01
  - 2025/11/01
  - 01-11-2025

Cutoff date: 2025-11-01

============================================================
Filtering calendar events...
Cutoff date: November 01, 2025
Input file: /Users/username/Desktop/green.ics
Output file: /Users/username/Desktop/green_filtered.ics
============================================================
Filtering complete!
Events kept: 29
Events removed: 455
Output written to: /Users/username/Desktop/green_filtered.ics
```

## How It Works

1. **Parses the ICS file** - Reads and identifies all VEVENT blocks
2. **Extracts event dates** - Finds the DTSTART field for each event
3. **Filters events** - Keeps only events on or after the cutoff date
4. **Preserves structure** - Maintains all calendar metadata, timezones, and formatting
5. **Writes output** - Creates a new filtered ICS file

## Supported Event Date Formats

The script automatically handles various ICS date/time formats:
- `20250826T150000` (date with time)
- `20250826T150000Z` (UTC time)
- `20250826` (date only)
- Timezone-aware dates (e.g., `TZID=Europe/Moscow:20250826T150000`)

## Error Handling

The script handles common errors gracefully:
- ❌ File not found
- ❌ Invalid date format
- ❌ Empty file path
- ❌ Malformed ICS files

## Technical Details

### What Gets Preserved
- Calendar properties (VCALENDAR)
- Timezone definitions (VTIMEZONE)
- Calendar metadata (PRODID, VERSION, etc.)
- Event alarms (VALARM)
- Event attendees and organizers
- Event descriptions and locations

### What Gets Filtered
- Only VEVENT blocks are evaluated
- Events are kept if:
  - DTSTART is on or after the cutoff date
  - DTSTART is missing (to preserve events without dates)

## Use Cases

- 📅 Clean up old calendar events
- 🗂️ Archive only future events
- 📤 Export upcoming events only
- 🧹 Reduce calendar file size
- 🔄 Migrate calendars between systems

## Limitations

- The script filters based on DTSTART (start date) only
- Recurring events are evaluated based on their base DTSTART
- Does not modify RRULE (recurrence rules)

## License

Free to use and modify.

## Support

For issues or questions, please contact the author or check the script's inline documentation.

## Version History

- **v1.0** - Initial release with interactive interface and multi-format date support