# Audio Scripts

A collection of macOS audio utility scripts for managing audio device configurations and properties.

## Scripts

### set_c920_highest_samplerate.swift

This Swift script automatically configures your Logitech C920 webcam to the highest available sample rate supported by the device. It's useful for improving audio quality when using the webcam's built-in microphone for recording, streaming, or video conferencing.

## Prerequisites

- macOS (Intel or Apple Silicon)
- Swift 5.0+ (typically included with Xcode Command Line Tools)
- CoreAudio framework (included with macOS)

## Usage

To run the script:

```bash
swift set_c920_highest_samplerate.swift
```

The script will:
1. Detect all audio devices on your system
2. Find the C920 webcam
3. Query available sample rates
4. Set the highest available rate (preferring 32kHz, then 48kHz, then 44.1kHz)
5. Display the results for each audio stream

### Example Output

```
📷 Logitech USB Headset C920
   Available rates: [8000, 16000, 32000, 48000]
   Targeting: 48000 Hz
   Input streams: 1
   ✅ Stream 12345: 16000 → 48000 Hz
```

## Notes

- The script requires CoreAudio framework access, which is built into macOS
- Changes made by this script persist until the device is disconnected or the system restarts
- The script is non-destructive and will not harm your audio devices
- Some USB audio devices may not support sample rate changes; in such cases, you'll see an error message with the OSStatus code
