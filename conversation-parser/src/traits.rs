//! Trait definitions that form the extension points of the pipeline.
//!
//! To add a new format, implement [`Parser`] and/or [`Renderer`].
//! To change merge/join behaviour, implement [`Merger`].

use crate::model::{Row, Segment};

/// Parses raw text/bytes into a flat list of [`Segment`]s.
pub trait Parser {
    /// Human-readable label, e.g. `"asr-json"`.
    fn name(&self) -> &'static str;

    /// Returns `true` when this parser recognises the given file extension
    /// (without leading dot, e.g. `"json"`, `"csv"`).
    fn supports_extension(&self, ext: &str) -> bool;

    /// Parse the full file content.  May return an error string.
    fn parse(&self, content: &str) -> Result<Vec<Segment>, String>;
}

/// Collapses a flat list of [`Segment`]s into merged [`Row`]s.
pub trait Merger {
    fn name(&self) -> &'static str;
    fn merge(&self, segments: Vec<Segment>) -> Vec<Row>;
}

/// Converts merged [`Row`]s into a final string representation.
pub trait Renderer {
    /// Human-readable label, e.g. `"markdown-table"`.
    fn name(&self) -> &'static str;

    /// Returns `true` when this renderer can write the given file extension.
    fn supports_extension(&self, ext: &str) -> bool;

    fn render(&self, rows: &[Row]) -> String;
}
