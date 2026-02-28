mod json_no_timestamps;
use chrono::{DateTime, NaiveDateTime, Utc};
use regex::Regex;
use std::env;
use std::fs::File;
use std::io::{self, BufRead};
use std::path::Path;
use std::sync::LazyLock;

// Regex to match lines like:
// **2024-05-01T12:00:00 - Alice:** Hello, how are you?
// static MSG_REGEX: LazyLock<Regex> =
//     LazyLock::new(|| Regex::new(r"\*\*(.+?) - (.+?):\*\* (.+)").unwrap());

// Regex to match lines like:
// 2024-05-01T12:00:00 - Alice: Hello, how are you?
static MSG_REGEX: LazyLock<Regex> =
    LazyLock::new(|| Regex::new(r"(\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}) - (.+?): (.+)").unwrap());

#[derive(Clone, Debug)]
struct Conversation {
    start_time: DateTime<Utc>,
    end_time: Option<DateTime<Utc>>,
    name: String,
    message: String,
}

fn main() -> io::Result<()> {
    let args: Vec<String> = env::args().collect();
    let file_path = args.get(1).map(String::as_str).unwrap_or("./output.txt");
    let flag = args.get(2).map(String::as_str).unwrap_or("");
    if flag == "--help" {
        eprintln!("Usage: {} [input_file] [--help]", args[0]);
        eprintln!("  input_file: Path to the input text file (default: './output.txt')");
        eprintln!("  --help: Show this help message");
        return Ok(());
    } else if flag == "json" {
        json_no_timestamps::json_to_md(file_path, "output.md");
        return Ok(());
    }

    let conversations = parse_conversations(file_path)?;

    if conversations.is_empty() {
        eprintln!("No conversations found in '{}'.", file_path);
        return Ok(());
    }

    println!("{}", to_markdown_table(&conversations));
    Ok(())
}

/// Parse the file at `path` into a list of merged conversations.
fn parse_conversations(path: &str) -> io::Result<Vec<Conversation>> {
    let mut conversations: Vec<Conversation> = Vec::new();
    let mut current: Option<Conversation> = None;

    for line in read_lines(path)? {
        let line = line?;

        let Some((timestamp, name, message)) = parse_message(&line) else {
            continue;
        };

        let ts = match parse_timestamp(&timestamp) {
            Ok(t) => t,
            Err(e) => {
                eprintln!("Skipping line with bad timestamp '{}': {}", timestamp, e);
                continue;
            }
        };

        match current.as_mut() {
            // Same author — merge the message into the running conversation
            Some(prev) if prev.name == name => {
                let last_char = prev.message.trim().chars().last();
                if last_char == Some('.') {
                    prev.message.push(' ');
                    prev.message.push_str(&message);
                } else {
                    prev.message.push(' ');
                    prev.message.push_str(&to_lowercase_first(&message));
                }
            }
            // Different author — flush the previous conversation and start a new one
            Some(prev) => {
                prev.end_time = Some(ts);
                conversations.push(current.take().unwrap());
                current = Some(Conversation {
                    start_time: ts,
                    end_time: None,
                    name,
                    message,
                });
            }
            // Very first message
            None => {
                current = Some(Conversation {
                    start_time: ts,
                    end_time: None,
                    name,
                    message,
                });
            }
        }
    }

    // Don't forget to flush the last conversation
    if let Some(last) = current {
        conversations.push(last);
    }

    Ok(conversations)
}

fn read_lines<P>(filename: P) -> io::Result<io::Lines<io::BufReader<File>>>
where
    P: AsRef<Path>,
{
    let file = File::open(filename)?;
    Ok(io::BufReader::new(file).lines())
}

fn parse_message(input: &str) -> Option<(String, String, String)> {
    MSG_REGEX.captures(input.trim()).map(|caps| {
        (
            caps[1].to_string(),
            caps[2].to_string(),
            caps[3].to_string(),
        )
    })
}

fn parse_timestamp(s: &str) -> Result<DateTime<Utc>, chrono::ParseError> {
    NaiveDateTime::parse_from_str(s, "%Y-%m-%dT%H:%M:%S").map(|ndt| ndt.and_utc())
}

fn to_lowercase_first(s: &str) -> String {
    let mut chars = s.chars();
    match chars.next() {
        None => String::new(),
        Some(first) => first.to_lowercase().to_string() + chars.as_str(),
    }
}

fn to_markdown_table(conversations: &[Conversation]) -> String {
    let mut table = String::new();

    table.push_str("| Start Time | Name | Message |\n");
    table.push_str("|------------|------|--------|\n");

    for conv in conversations {
        table.push_str(&format!(
            "| {} | {} | {} |\n",
            conv.start_time.format("%Y-%m-%dT%H:%M:%S"),
            conv.name,
            conv.message
        ));
    }

    table
}
