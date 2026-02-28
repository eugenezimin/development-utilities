use std::fs;
use std::io::Read;

#[derive(Debug)]
struct Entry {
    speaker: String,
    text: String,
}

/// Parse a quoted string starting right after the opening `"`
/// Returns (parsed_string, remaining_input_after_closing_quote)
fn parse_quoted(s: &str) -> Option<(String, &str)> {
    let mut result = String::new();
    let mut chars = s.char_indices();
    loop {
        match chars.next() {
            None => return None,
            Some((i, '\\')) => match chars.next() {
                Some((_, '"')) => result.push('"'),
                Some((_, 'n')) => result.push('\n'),
                Some((_, 't')) => result.push('\t'),
                Some((_, '\\')) => result.push('\\'),
                Some((_, c)) => {
                    result.push('\\');
                    result.push(c);
                }
                None => return None,
            },
            Some((i, '"')) => {
                let rest = &s[i + 1..];
                return Some((result, rest));
            }
            Some((_, c)) => result.push(c),
        }
    }
}

fn parse_entries(input: &str) -> Vec<Entry> {
    let mut entries = Vec::new();

    // Split into lines and parse line-by-line
    // Lines look like:  speaker: "value",  or  text: "value"
    let mut current_speaker: Option<String> = None;

    for line in input.lines() {
        let trimmed = line.trim();

        // Check for speaker: "..."
        let (key, rest) = if let Some(rest) = trimmed.strip_prefix("speaker:") {
            ("speaker", rest)
        } else if let Some(rest) = trimmed.strip_prefix("\"speaker\":") {
            ("speaker", rest)
        } else if let Some(rest) = trimmed.strip_prefix("text:") {
            ("text", rest)
        } else if let Some(rest) = trimmed.strip_prefix("\"text\":") {
            ("text", rest)
        } else {
            continue;
        };

        // Find opening quote for the value
        let rest = rest.trim();
        if !rest.starts_with('"') {
            continue;
        }
        let rest = &rest[1..]; // skip opening "

        let (value, _) = match parse_quoted(rest) {
            Some(v) => v,
            None => continue,
        };

        match key {
            "speaker" => {
                current_speaker = Some(value);
            }
            "text" => {
                if let Some(speaker) = current_speaker.take() {
                    entries.push(Entry {
                        speaker,
                        text: value,
                    });
                }
            }
            _ => {}
        }
    }

    entries
}

fn make_lowercase_first(s: &str) -> String {
    let mut chars = s.chars();
    match chars.next() {
        None => String::new(),
        Some(c) => c.to_lowercase().collect::<String>() + chars.as_str(),
    }
}

fn make_uppercase_first(s: &str) -> String {
    let mut chars = s.chars();
    match chars.next() {
        None => String::new(),
        Some(c) => c.to_uppercase().collect::<String>() + chars.as_str(),
    }
}

fn merge_entries(entries: Vec<Entry>) -> Vec<Entry> {
    let mut merged: Vec<Entry> = Vec::new();

    for entry in entries {
        if let Some(last) = merged.last_mut() {
            if last.speaker == entry.speaker {
                let ends_with_period = last.text.trim_end().ends_with('.');
                let next_text = if ends_with_period {
                    make_uppercase_first(&entry.text)
                } else {
                    make_lowercase_first(&entry.text)
                };
                last.text.push(' ');
                last.text.push_str(&next_text);
                continue;
            }
        }
        merged.push(entry);
    }

    merged
}

fn escape_md(s: &str) -> String {
    s.replace('|', "\\|").replace('\n', " ")
}

fn to_markdown_table(entries: &[Entry]) -> String {
    let mut out = String::new();
    out.push_str("| Speaker | Text |\n");
    out.push_str("|---------|------|\n");
    for e in entries {
        out.push_str(&format!(
            "| {} | {} |\n",
            escape_md(&e.speaker),
            escape_md(&e.text)
        ));
    }
    out
}

pub fn json_to_md(path: &str, output: &str) {
    let input = fs::read_to_string(path).expect("Failed to read input file");
    println!("Read input file '{}'", path);
    println!("Read input file '{}'", input);
    let entries = parse_entries(&input);
    let merged = merge_entries(entries);
    let table = to_markdown_table(&merged);

    print!("{}", table);
}
