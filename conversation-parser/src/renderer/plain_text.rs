//! Renders rows as plain-text conversation (Name: speech\n\n).

use crate::model::Row;
use crate::traits::Renderer;

pub struct PlainTextRenderer;

impl Renderer for PlainTextRenderer {
    fn name(&self) -> &'static str {
        "plain-text"
    }

    fn supports_extension(&self, ext: &str) -> bool {
        matches!(ext.to_ascii_lowercase().as_str(), "txt" | "text")
    }

    fn render(&self, rows: &[Row]) -> String {
        rows.iter()
            .map(|r| format!("{}: {}\n", r.speaker, r.speech))
            .collect::<Vec<_>>()
            .join("\n")
    }
}
