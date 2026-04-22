//! All available parsers.
//! Register new parsers here and expose them through [`all_parsers`].

pub mod asr_json;
pub mod timestamped_text;

use crate::traits::Parser;

/// Returns every parser known to the application.
/// The registry is checked in order — first match wins.
///
/// Note: when two parsers share an extension (e.g. both `.txt`), the one
/// listed first wins for auto-detection. Use `--parser <name>` on the CLI
/// to force a specific parser regardless of extension.
pub fn all_parsers() -> Vec<Box<dyn Parser>> {
    vec![
        Box::new(asr_json::AsrJsonParser),
        Box::new(timestamped_text::TimestampedTextParser),
        // Box::new(srt::SrtParser),
        // Box::new(vtt::VttParser),
        // Box::new(csv::CsvParser),
    ]
}

/// Look up a parser by name (for `--parser <name>` CLI flag).
pub fn find_parser(name: &str) -> Option<Box<dyn Parser>> {
    all_parsers().into_iter().find(|p| p.name() == name)
}
