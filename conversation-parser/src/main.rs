//! transcript_formatter — modular transcript processing pipeline.
//!
//! Pipeline: Parser → Merger → Renderer
//!
//! Usage:
//!   transcript_formatter <input> [options]
//!
//! Options:
//!   --output <path>     Output file path (default: <input_stem>.md)
//!   --parser <n>        Parser to use (default: auto-detect from extension)
//!   --merger <n>        Merger to use (default: conversation)
//!   --renderer <n>      Renderer to use (auto-detected from output extension)
//!   --list              List all registered parsers, mergers and renderers

mod merger;
mod model;
mod parser;
mod renderer;
mod traits;

use std::{env, fs, path::Path};

fn main() {
    let args: Vec<String> = env::args().collect();

    // ── --list flag ───────────────────────────────────────────────────────────
    if args.iter().any(|a| a == "--list") {
        println!("Parsers:");
        for p in parser::all_parsers() {
            println!("  {}", p.name());
        }
        println!("Mergers:");
        for m in merger::all_mergers() {
            println!("  {}", m.name());
        }
        println!("Renderers:");
        for r in renderer::all_renderers() {
            println!("  {}", r.name());
        }
        return;
    }

    // ── positional: input file ────────────────────────────────────────────────
    let input_path = args
        .iter()
        .skip(1)
        .find(|a| !a.starts_with('-'))
        .unwrap_or_else(|| {
            eprintln!(
                "Usage: {} <input> [--output <path>] [--parser <n>] [--merger <n>] [--renderer <n>] [--list]",
                args[0]
            );
            std::process::exit(1);
        });

    // ── optional flags ────────────────────────────────────────────────────────
    let output_path: String = flag_value(&args, "--output").unwrap_or_else(|| {
        Path::new(input_path)
            .file_stem()
            .map(|s| format!("{}.md", s.to_string_lossy()))
            .unwrap_or_else(|| "output.md".to_string())
    });

    let parser_name = flag_value(&args, "--parser");
    let merger_name = flag_value(&args, "--merger");
    let renderer_name = flag_value(&args, "--renderer");

    // ── read input ────────────────────────────────────────────────────────────
    let content = fs::read_to_string(input_path).unwrap_or_else(|e| {
        eprintln!("Error reading '{}': {}", input_path, e);
        std::process::exit(1);
    });

    // ── select parser ─────────────────────────────────────────────────────────
    let input_ext = Path::new(input_path)
        .extension()
        .map(|e| e.to_string_lossy().to_string())
        .unwrap_or_default();

    let parser = match parser_name {
        Some(ref name) => parser::find_parser(name).unwrap_or_else(|| {
            eprintln!(
                "Unknown parser '{}'. Run with --list to see available parsers.",
                name
            );
            std::process::exit(1);
        }),
        None => parser::all_parsers()
            .into_iter()
            .find(|p| p.supports_extension(&input_ext))
            .unwrap_or_else(|| {
                eprintln!(
                    "No parser found for extension '{}'. Use --parser <n> to force one.",
                    input_ext
                );
                std::process::exit(1);
            }),
    };

    eprintln!("Parser:   {}", parser.name());

    // ── parse ─────────────────────────────────────────────────────────────────
    let segments = parser.parse(&content).unwrap_or_else(|e| {
        eprintln!("Parse failed: {}", e);
        std::process::exit(1);
    });

    eprintln!("Segments: {}", segments.len());

    // ── select merger ─────────────────────────────────────────────────────────
    let merger = match merger_name {
        Some(ref name) => merger::find_merger(name).unwrap_or_else(|| {
            eprintln!(
                "Unknown merger '{}'. Run with --list to see available mergers.",
                name
            );
            std::process::exit(1);
        }),
        None => merger::default_merger(),
    };

    eprintln!("Merger:   {}", merger.name());

    // ── merge ─────────────────────────────────────────────────────────────────
    let rows = merger.merge(segments);
    eprintln!("Rows:     {}", rows.len());

    // ── select renderer ───────────────────────────────────────────────────────
    let output_ext = Path::new(&output_path)
        .extension()
        .map(|e| e.to_string_lossy().to_string())
        .unwrap_or_default();

    let rend = match renderer_name {
        Some(ref name) => renderer::renderer_by_name(name).unwrap_or_else(|| {
            eprintln!(
                "Unknown renderer '{}'. Run with --list to see available renderers.",
                name
            );
            std::process::exit(1);
        }),
        None => renderer::renderer_for_ext(&output_ext).unwrap_or_else(|| {
            eprintln!(
                "No renderer found for output extension '{}'. Use --renderer <n> to force one.",
                output_ext
            );
            std::process::exit(1);
        }),
    };

    eprintln!("Renderer: {}", rend.name());

    // ── render & write ────────────────────────────────────────────────────────
    let output = rend.render(&rows);

    fs::write(&output_path, &output).unwrap_or_else(|e| {
        eprintln!("Error writing '{}': {}", output_path, e);
        std::process::exit(1);
    });

    println!("Written to {}", output_path);
}

/// Extract the value of a named flag, e.g. `--output foo.md` → `Some("foo.md")`.
fn flag_value(args: &[String], flag: &str) -> Option<String> {
    args.windows(2).find(|w| w[0] == flag).map(|w| w[1].clone())
}
