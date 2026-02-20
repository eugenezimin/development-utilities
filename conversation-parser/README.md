# Conversation Parser

A command-line tool written in Rust that parses structured chat logs, merges consecutive messages from the same author, and outputs a formatted Markdown table with timestamps and durations.

---

## Features

- Parses chat logs formatted with bold markdown timestamps and author names
- Merges consecutive messages from the same author into a single conversation entry
- Outputs a clean Markdown table with start time, author, and message
- Accepts an input file path as a command-line argument with a sensible default
- Gracefully skips malformed lines without crashing

---

## Input Format

The parser expects a plain text file where each message line follows this pattern:

```
**YYYY-MM-DDTHH:MM:SS ** Author Name:** Message content here
```

Example `output.txt`:

```
**2024-03-01T09:00:00 ** Alice:** Good morning everyone
**2024-03-01T09:00:45 ** Alice:** Just a quick heads up about today's standup
**2024-03-01T09:01:10 ** Bob:** Morning! I'll be a few minutes late
**2024-03-01T09:05:00 ** Alice:** No worries, we'll wait
```

Lines that do not match the expected format are silently skipped.

---

## Output Format

The tool prints a Markdown table to stdout:

| Start Time | Name | Message |
|------------|------|---------|
| 2024-03-01T09:00:00 | Alice | Good morning everyone just a quick heads up about today's standup |
| 2024-03-01T09:01:10 | Bob | Morning! I'll be a few minutes late |
| 2024-03-01T09:05:00 | Alice | No worries, we'll wait |

**Notes:**
Consecutive messages from the same author are merged. If the previous message ended with a period, the next one is appended with a space and capitalized. Otherwise it is joined with a lowercase continuation.

---

## Requirements

- [Rust](https://www.rust-lang.org/tools/install) 1.80 or later (for `std::sync::LazyLock` stabilization)

### Dependencies

Add the following to your `Cargo.toml`:

```toml
[dependencies]
chrono = "0.4"
regex = "1"
```

---

## Building

```bash
cargo build --release
```

The compiled binary will be available at `./target/release/conversation_parser`.

---

## Usage

Run with the default input file (`./output.txt`):

```bash
./target/release/conversation_parser
```

Run with a custom input file:

```bash
./target/release/conversation_parser /path/to/your/chatlog.txt
```

Redirect output to a Markdown file:

```bash
./target/release/conversation_parser chatlog.txt > report.md
```

---

## Error Handling

| Situation | Behaviour |
|-----------|-----------|
| Input file not found | Exits with an IO error message |
| Malformed timestamp on a line | Logs a warning to stderr, skips the line |
| Line does not match expected format | Silently skipped |
| No valid conversations found | Prints a message to stderr and exits cleanly |

---

## License

MIT