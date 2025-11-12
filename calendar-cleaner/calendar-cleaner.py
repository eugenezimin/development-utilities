#!/usr/bin/env python3
"""
ICS Calendar Filter Script
Removes all events that occurred before specified date
@author: Eugene Zimin
"""

from datetime import datetime
import re
import sys
import os

def parse_datetime(dt_string):
    """
    Parse various datetime formats from ICS files.
    Returns a datetime object or None if parsing fails.
    """
    # Remove TZID prefix if present
    dt_string = re.sub(r'^TZID=[^:]+:', '', dt_string)
    
    # Try different datetime formats
    formats = [
        '%Y%m%dT%H%M%S',      # 20250826T150000
        '%Y%m%dT%H%M%SZ',     # 20250826T150000Z
        '%Y%m%d',             # 20250826
    ]
    
    for fmt in formats:
        try:
            return datetime.strptime(dt_string, fmt)
        except ValueError:
            continue
    
    return None

def extract_event_start_date(event_lines):
    """
    Extract the start date from a VEVENT block.
    Returns datetime object or None.
    """
    for line in event_lines:
        if line.startswith('DTSTART'):
            # Extract the value after the colon
            match = re.search(r'DTSTART[^:]*:(.+)', line)
            if match:
                dt_str = match.group(1).strip()
                return parse_datetime(dt_str)
    return None

def filter_calendar(input_file, output_file, cutoff_date):
    """
    Filter ICS file to keep only events on or after the cutoff date.
    
    Args:
        input_file: Path to input ICS file
        output_file: Path to output ICS file
        cutoff_date: datetime object for the cutoff date
    """
    with open(input_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
    
    # Parse the file and identify VEVENT blocks
    filtered_lines = []
    in_event = False
    current_event = []
    events_removed = 0
    events_kept = 0
    
    i = 0
    while i < len(lines):
        line = lines[i].rstrip('\n')
        
        if line == 'BEGIN:VEVENT':
            in_event = True
            current_event = [line + '\n']
        elif line == 'END:VEVENT':
            current_event.append(line + '\n')
            
            # Check if this event should be kept
            start_date = extract_event_start_date(current_event)
            
            if start_date is None or start_date >= cutoff_date:
                # Keep the event
                filtered_lines.extend(current_event)
                events_kept += 1
            else:
                # Remove the event
                events_removed += 1
            
            in_event = False
            current_event = []
        elif in_event:
            current_event.append(line + '\n')
        else:
            # Keep non-event lines (header, timezone info, etc.)
            filtered_lines.append(line + '\n')
        
        i += 1
    
    # Write the filtered content to output file
    with open(output_file, 'w', encoding='utf-8') as f:
        f.writelines(filtered_lines)
    
    print(f"Filtering complete!")
    print(f"Events kept: {events_kept}")
    print(f"Events removed: {events_removed}")
    print(f"Output written to: {output_file}")

def main():
    print("=" * 60)
    print("ICS Calendar Event Filter")
    print("=" * 60)
    print()
    
    # Get input file
    input_file = input("Enter input calendar file path: ").strip()
    # Remove surrounding quotes if present (handles paths with spaces)
    input_file = input_file.strip('"').strip("'")
    if not input_file:
        print("Error: Input file path cannot be empty")
        sys.exit(1)
    
    # Expand user home directory (~) and make path absolute
    input_file = os.path.expanduser(input_file)
    input_file = os.path.abspath(input_file)
    
    # Extract base filename for suggestions
    base_name = os.path.splitext(os.path.basename(input_file))[0]
    dir_name = os.path.dirname(input_file)
    
    # Suggest output filenames
    print()
    print("Suggested output filenames:")
    print(f"  1. {base_name}_filtered.ics")
    print(f"  2. {base_name}_cleaned.ics")
    print(f"  3. {base_name}_new.ics")
    print(f"  4. custom (you'll specify)")
    print()
    
    output_file = input("Enter output calendar file path (or press Enter for option 1): ").strip()
    # Remove surrounding quotes if present
    output_file = output_file.strip('"').strip("'")
    
    if not output_file:
        output_file = f"{base_name}_filtered.ics"
        print(f"Using: {output_file}")
    
    # Add file to the same folder where the original file was taken from
    output_file = os.path.join(dir_name, output_file)

    # Expand user home directory (~) and make path absolute
    output_file = os.path.expanduser(output_file)
    output_file = os.path.abspath(output_file)
    
    # Get cutoff date
    print()
    print("Enter cutoff date (events before this date will be removed)")
    print("Format examples:")
    print("  - 2025-11-01")
    print("  - 2025/11/01")
    print("  - 01-11-2025")
    print()
    
    date_input = input("Cutoff date: ").strip()
    
    # Parse the date input
    cutoff_date = None
    date_formats = [
        '%Y-%m-%d',
        '%Y/%m/%d',
        '%d-%m-%Y',
        '%d/%m/%Y',
        '%m-%d-%Y',
        '%m/%d/%Y',
    ]
    
    for fmt in date_formats:
        try:
            cutoff_date = datetime.strptime(date_input, fmt)
            break
        except ValueError:
            continue
    
    if cutoff_date is None:
        print(f"Error: Could not parse date '{date_input}'")
        sys.exit(1)
    
    print()
    print("=" * 60)
    print(f"Filtering calendar events...")
    print(f"Cutoff date: {cutoff_date.strftime('%B %d, %Y')}")
    print(f"Input file: {input_file}")
    print(f"Output file: {output_file}")
    print("=" * 60)
    
    try:
        filter_calendar(input_file, output_file, cutoff_date)
    except FileNotFoundError:
        print(f"Error: Input file '{input_file}' not found", file=sys.stderr)
        sys.exit(1)
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        sys.exit(1)

if __name__ == '__main__':
    main()