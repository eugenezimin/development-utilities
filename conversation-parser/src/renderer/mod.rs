//! All available renderers.

pub mod markdown_table;
pub mod plain_text;

use crate::traits::Renderer;

/// Returns every renderer known to the application.
pub fn all_renderers() -> Vec<Box<dyn Renderer>> {
    vec![
        Box::new(markdown_table::MarkdownTableRenderer),
        Box::new(plain_text::PlainTextRenderer),
        // Box::new(html::HtmlRenderer),
        // Box::new(csv::CsvRenderer),
    ]
}

/// Find a renderer that handles the given output file extension.
pub fn renderer_for_ext(ext: &str) -> Option<Box<dyn Renderer>> {
    all_renderers()
        .into_iter()
        .find(|r| r.supports_extension(ext))
}

/// Find a renderer by name.
pub fn renderer_by_name(name: &str) -> Option<Box<dyn Renderer>> {
    all_renderers().into_iter().find(|r| r.name() == name)
}
