# Conversation Parser (`transcript_formatter`)

A small Rust CLI that turns ASR/transcript output into a clean conversation document. It runs a modular **Parser → Merger → Renderer** pipeline: parse raw transcript segments, merge consecutive same-speaker segments into readable rows, then render the result as a Markdown table or plain text.

## Requirements

- Rust toolchain (`cargo`) — install via [rustup](https://rustup.rs/) if not already present.

## Build

```bash
cd conversation-parser
cargo build --release
```

The compiled binary will be at `target/release/transcript_formatter`.

## Usage

```bash
transcript_formatter <input> [--output <path>] [--parser <name>] [--merger <name>] [--renderer <name>] [--list]
```

### Options

| Flag | Description |
|---|---|
| `--output <path>` | Output file path. Defaults to `<input_stem>.md`. |
| `--parser <name>` | Force a specific parser instead of auto-detecting from the input's file extension. |
| `--merger <name>` | Merger to use. Defaults to `conversation`. |
| `--renderer <name>` | Force a specific renderer instead of auto-detecting from the output's file extension. |
| `--list` | List all registered parsers, mergers, and renderers, then exit. |

### Example

```bash
transcript_formatter transcript.json --output transcript.md
```

```bash
$ transcript_formatter --list
Parsers:
  asr-json
Mergers:
  conversation
Renderers:
  markdown-table
  plain-text
```

## Input format

The built-in `asr-json` parser (auto-selected for `.json` input) expects an array of segment objects:

```json
[
  { "speaker": "Alice", "text": "Hello", "timestamp": "00:00-00:02" },
  { "speaker": "Bob", "text": "Hi there!", "timestamp": "00:02-00:04" }
]
```

`timestamp` is optional.

## Pipeline

1. **Parser** — reads the input file and produces a list of `Segment { speaker, text, timestamp }`.
   - `asr-json` (`.json`) — deserializes the ASR JSON schema shown above.
2. **Merger** — collapses the segments into `Row { speaker, speech }` entries.
   - `conversation` (default) — merges consecutive segments from the same speaker, joining their text at sentence boundaries.
3. **Renderer** — turns the merged rows into the final output text.
   - `markdown-table` (`.md`, `.markdown`) — GitHub-flavoured Markdown table with `Speaker` / `Speech` columns (escapes `|` in content).
   - `plain-text` (`.txt`, `.text`) — `Speaker: speech` lines separated by blank lines.

Parser/renderer selection is automatic based on file extension unless overridden with `--parser`/`--renderer`. When two components share an extension, the first one registered wins — use the explicit flag to force a specific one.

## Extending

New parsers, mergers, and renderers are added by implementing the corresponding trait in [src/traits.rs](src/traits.rs) and registering the implementation in the relevant `mod.rs`:

- Parsers: [src/parser/mod.rs](src/parser/mod.rs)
- Mergers: [src/merger/mod.rs](src/merger/mod.rs)
- Renderers: [src/renderer/mod.rs](src/renderer/mod.rs)

Each registry file already has commented-out placeholders for likely future formats (e.g. `srt`, `vtt`, `csv`, `html`, `timestamped_text`) as a starting point.
