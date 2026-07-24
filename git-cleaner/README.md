# Git Cleaner

This script helps you clean the history of a Git repository by deleting a specified file from the whole repository's history. It might be important to remove sensitive information from the repository's history, like passwords, API keys, or other confidential data, which may be stored in `.env` filed, or similar to them.

## Prerequisites

- Java must be installed on your system.
- `tput` must be installed on your system.
- The BFG Repo-Cleaner (`bfg*.jar`) should be present in the local directory.
  - If no `bfg*.jar` is found, the script automatically falls back to building it from the vendored [bfg-repo-cleaner/](./bfg-repo-cleaner/) source using `sbt bfg/assembly`, then copies the resulting jar locally. In that case, [sbt](https://www.scala-sbt.org/) must be installed (e.g. `brew install sbt`).

## Usage

**Ensure prerequisites are met:**
- Java is installed.
- `tput` is installed.
- Either a `bfg*.jar` is present in the local directory, or `sbt` is installed so the script can build one from `bfg-repo-cleaner/`.

To run the `git-cleaner.sh` script, you need to ensure that all prerequisites are met and then execute the script with the necessary inputs. Here is an example of a full working command sequence:

  1. Open your terminal.
  2. Navigate to the directory containing the `git-cleaner.sh` script.
  3. Run the script:

```bash
./git-cleaner.sh
```

4. Follow the prompts:

```plaintext
######################################################
#              Git Repo History Cleaner              #
######################################################

Enter path to repo to clean (absolute): /path/to/your/repo
Enter the filename to delete (from repo's root): sensitive_file.txt
The following file will be deleted: sensitive_file.txt

Do you want to continue? (y/n): y
Deleting...
```

Make sure to replace `/path/to/your/repo` with the absolute path to your Git repository and `sensitive_file.txt` with the filename you want to delete from the repository's history.
## Notes

- Ensure the repository path is correct and the repository exists.
- Ensure the filename is correct and not empty.
- The script will prompt for confirmation before proceeding with the deletion.

## License

MIT — see [LICENSE](./LICENSE). The vendored [bfg-repo-cleaner/](./bfg-repo-cleaner/) is a separate third-party project licensed under GPLv3 — see its own [LICENSE](./bfg-repo-cleaner/LICENSE).