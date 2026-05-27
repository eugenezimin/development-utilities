//! Renders rows as a GitHub-Flavoured Markdown table.

use crate::model::Row;
use crate::traits::Renderer;

pub struct MarkdownTableRenderer;

impl Renderer for MarkdownTableRenderer {
    fn name(&self) -> &'static str {
        "markdown-table"
    }

    fn supports_extension(&self, ext: &str) -> bool {
        matches!(ext.to_ascii_lowercase().as_str(), "md" | "markdown")
    }

    fn render(&self, rows: &[Row]) -> String {
        let mut out = String::new();
        out.push_str("| Speaker | Speech |\n");
        out.push_str("| ------- | ------ |\n");
        for row in rows {
            let speaker = row.speaker.replace('|', "\\|");
            let speech = row.speech.replace('|', "\\|");
            out.push_str(&format!("| {speaker} | {speech} |\n"));
        }
        out
    }
}
