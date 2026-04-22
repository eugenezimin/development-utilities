//! All available mergers.

pub mod conversation;

use crate::traits::Merger;

/// Default merger used when none is specified.
pub fn default_merger() -> Box<dyn Merger> {
    Box::new(conversation::ConversationMerger)
}

/// All registered mergers, keyed by name.
pub fn all_mergers() -> Vec<Box<dyn Merger>> {
    vec![
        Box::new(conversation::ConversationMerger),
        // Box::new(verbatim::VerbatimMerger),   // future: no merging at all
        // Box::new(timed::TimedMerger),          // future: merge within time windows
    ]
}

/// Look up a merger by name.
pub fn find_merger(name: &str) -> Option<Box<dyn Merger>> {
    all_mergers().into_iter().find(|m| m.name() == name)
}
