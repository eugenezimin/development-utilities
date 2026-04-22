//! Parser for the ASR JSON format produced by transcription tools.
//!
//! Expected schema (array of objects):
//! ```json
//! [
//!   { "speaker": "Alice", "text": "Hello", "timestamp": "00:00-00:02" },
//!   ...
//! ]
//! ```

use crate::model::Segment;
use crate::traits::Parser;
use serde::Deserialize;

#[derive(Debug, Deserialize)]
struct RawSegment {
    speaker: String,
    text: String,
    timestamp: Option<String>,
}

pub struct AsrJsonParser;

impl Parser for AsrJsonParser {
    fn name(&self) -> &'static str {
        "asr-json"
    }

    fn supports_extension(&self, ext: &str) -> bool {
        ext.eq_ignore_ascii_case("json")
    }

    fn parse(&self, content: &str) -> Result<Vec<Segment>, String> {
        let raw: Vec<RawSegment> =
            serde_json::from_str(content).map_err(|e| format!("JSON parse error: {e}"))?;

        Ok(raw
            .into_iter()
            .map(|r| Segment {
                speaker: r.speaker,
                text: r.text,
                timestamp: r.timestamp,
            })
            .collect())
    }
}
