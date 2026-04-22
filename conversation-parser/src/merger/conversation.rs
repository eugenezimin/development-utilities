//! Conversation merger: collapses consecutive segments from the same speaker
//! and joins them organically at sentence boundaries.

use crate::model::{Row, Segment};
use crate::traits::Merger;

pub struct ConversationMerger;

impl Merger for ConversationMerger {
    fn name(&self) -> &'static str {
        "conversation"
    }

    fn merge(&self, segments: Vec<Segment>) -> Vec<Row> {
        let mut rows: Vec<Row> = Vec::new();

        for seg in segments {
            let speaker = normalize_speaker(&seg.speaker);
            let text = seg.text.trim().to_string();

            if let Some(last) = rows.last_mut() {
                if same_speaker(&last.speaker, &speaker) {
                    last.speech = join_texts(&last.speech, &text);
                    continue;
                }
            }

            rows.push(Row {
                speaker,
                speech: text,
            });
        }

        rows
    }
}

// ── helpers ──────────────────────────────────────────────────────────────────

/// Collapse internal whitespace and trim.
fn normalize_speaker(name: &str) -> String {
    name.split_whitespace().collect::<Vec<_>>().join(" ")
}

fn same_speaker(a: &str, b: &str) -> bool {
    if a == b {
        return true;
    }
    let mut wa: Vec<&str> = a.split_whitespace().collect();
    let mut wb: Vec<&str> = b.split_whitespace().collect();
    wa.sort_unstable();
    wb.sort_unstable();
    wa == wb
}

/// Join two text fragments at a natural boundary.
///
/// * If `prev` ends with terminal punctuation → clean space join.
/// * Otherwise → continuation join, stripping leading ASR artefact dots from `next`.
fn join_texts(prev: &str, next: &str) -> String {
    let prev = prev.trim_end();
    let next = next.trim_start();

    let is_terminal = |c: char| matches!(c, '.' | '?' | '!' | '…' | '»');

    if prev.chars().last().map(is_terminal).unwrap_or(false) {
        format!("{prev} {next}")
    } else {
        // Strip leading dots that ASR inserts at segment boundaries
        let cont = next.trim_start_matches('.').trim_start();
        format!("{prev} {cont}")
    }
}
