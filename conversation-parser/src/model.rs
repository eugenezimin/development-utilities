//! Core domain types shared across the entire pipeline.
//! Nothing here depends on any specific parser or renderer.

/// A raw segment as it comes out of any parser — speaker + text + optional timestamp.
#[derive(Debug, Clone)]
pub struct Segment {
    pub speaker: String,
    pub text: String,
    pub timestamp: Option<String>,
}

/// A fully merged, display-ready row produced by a merger.
#[derive(Debug, Clone)]
pub struct Row {
    pub speaker: String,
    pub speech: String,
}
