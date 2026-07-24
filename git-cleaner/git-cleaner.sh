#!/bin/bash

# Check Java installation
if ! command -v java >/dev/null; then
  echo "Error: Java is not installed."
  exit 1
fi

if ! command -v tput >/dev/null; then
  echo "Error: 'tput' is not installed."
  exit 1
fi

# Check for files starting with "bfg" and ending with ".jar" using ls and grep
bfg_jar=$(ls | grep -E "^bfg.*\.jar$" | head -n 1)

if [[ -z "$bfg_jar" ]]; then
  echo "No 'BFG-Cleaner' JAR found in the local folder."

  bfg_source_dir="$(pwd)/bfg-repo-cleaner"
  if [ ! -d "$bfg_source_dir" ]; then
    echo "Error: No BFG jar found, and no 'bfg-repo-cleaner' source folder is present to build it from."
    exit 1
  fi

  if ! command -v sbt >/dev/null; then
    echo "Error: 'sbt' is required to build the BFG jar from source, but it is not installed."
    echo "Install sbt (e.g. 'brew install sbt') and re-run this script."
    exit 1
  fi

  echo "Building the BFG jar from source using sbt (this may take a while)..."
  (cd "$bfg_source_dir" && sbt "bfg/assembly")
  if [ $? -ne 0 ]; then
    echo "Error: Failed to build the BFG jar with sbt."
    exit 1
  fi

  built_jar=$(find "$bfg_source_dir" -type f -name "bfg-*.jar" ! -name "*-sources.jar" ! -name "*-javadoc.jar" -print0 | xargs -0 ls -t 2>/dev/null | head -n 1)
  if [[ -z "$built_jar" ]]; then
    echo "Error: BFG build finished, but no jar artefact was found."
    exit 1
  fi

  cp "$built_jar" "$(pwd)/"
  bfg_jar="$(pwd)/$(basename "$built_jar")"
  echo "Built and copied BFG jar to: $bfg_jar"
else
  bfg_jar="$(pwd)/$bfg_jar"
fi

echo "######################################################"
echo "#              Git Repo History Cleaner              #"
echo "######################################################"

echo
echo -n "Enter path to repo to clean (absolute): " && read -p "" repo

# Check if folder exists
if [ ! -d "$repo" ]; then
  echo "Error: Folder '$repo' does not exist."
  exit 1
fi

# Check for .git directory
if [ ! -d "$repo/.git" ]; then
  echo "Error: '$repo' is not a git repository."
  exit 1
fi

echo -n "Enter the filename to delete (from repo's root): " && read -p "" filename
# Check if the filename is empty
if [[ -z "$filename" ]]; then
  echo "Error: Please enter a valid filename."
  exit 1
fi

# BFG's --delete-files only matches on the filename itself, not on path segments.
if [[ "$filename" == */* ]]; then
  echo "Warning: BFG matches files by name only, not by path."
  echo "This will delete every file named '$(basename "$filename")' anywhere in the repo's history, not just at '$filename'."
fi

echo "The following file will be deleted: $filename"
echo

echo -n "Do you want to continue? (y/n): "
while true; do
  # Setting curson after the question
  tput hpa 32
  
  # Waiting for input string
  read -n 1 -t 60 -p "" answer
  case "$answer" in
    y)
      echo
      echo "Deleting..."

      bfg_output=$(java -jar "$bfg_jar" --delete-files "$(basename "$filename")" "$repo" 2>&1)
      bfg_exit_code=$?
      echo "$bfg_output"

      # BFG's CLI can exit 0 even when it fails to parse arguments (e.g. path
      # segments in --delete-files), so also check its output for known errors.
      if [ $bfg_exit_code -ne 0 ] || echo "$bfg_output" | grep -q "^Error:\|Can only match on filename"; then
        echo "Error: BFG failed to delete '$filename'."
        exit 1
      fi

      echo "Cleaning up repository (expiring reflog and running gc)..."
      (cd "$repo" && git reflog expire --expire=now --all && git gc --prune=now --aggressive)
      if [ $? -ne 0 ]; then
        echo "Error: Failed to clean up repository after BFG run."
        exit 1
      fi

      echo "Done. '$filename' has been removed from the history of '$repo'."
      echo "Remember to force-push the cleaned branches/tags to any remotes: git push --force"
      break
      ;;
    n)
      echo
      echo "Exiting..."
      exit 0
      ;;
    *)
      # Move cursor one symbol left and 
      # clean up till the end of the string
      tput cub1
      tput el
      ;;
  esac
done



