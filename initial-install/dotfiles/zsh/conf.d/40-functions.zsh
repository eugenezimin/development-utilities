# Find files by name pattern: ftext [pattern] [dir] [path-to-prune]
ftext() {
  local pattern="${1:-*.*}"
  local dir="${2:-.}"
  local prune="${3:-/System/Volumes/Data}"
  find "$dir" -path "$prune" -prune -o -name "$pattern" -print 2>/dev/null
}
