# Git Clone and Convert Script

This Bash script allows you to clone a Git repository as a mirror and then convert it into a normal repository. It's useful when you want to create a full copy of a repository, including all branches and history, and then work with it as a standard local repository.

## Prerequisites

- Git installed on your system
- Bash shell

## Usage

```bash
./git-mirror.sh <source_repo_url> <destination_directory>
```

### Parameters:

- `<source_repo_url>`: The URL of the Git repository you want to clone.
- `<destination_directory>`: The local directory where you want to clone the repository.

## What the Script Does

1. Clones the repository as a mirror into the specified destination directory.
2. Converts the mirrored repository into a normal repository.
3. Creates a `.git` folder and moves the repository contents into it.
4. Checks out the default branch (usually `main` or `master`).
5. Resets the working directory to match the HEAD commit.

## Example

```bash
./git-mirror.sh https://github.com/username/repo.git /path/to/destination
```

## Notes

- Ensure you have the necessary permissions to clone the source repository.
- The script will overwrite any existing content in the destination directory.
- After running the script, you'll have a fully functional local copy of the repository that you can work with normally.

## Troubleshooting

If you encounter any issues:

1. Make sure Git is installed and accessible from your command line.
2. Check that you have the correct permissions for the destination directory.
3. Verify that the source repository URL is correct and accessible.

## Contributing 

Contributions to this repository are welcome! If you would like to add a something new or improve an existing, please follow these steps: 
1. Fork the repository. 
2. Create a new branch for your changes: `git checkout -b my-new-branch` 
3. Add your code or make changes to an existing one. 
4. Commit your changes: `git commit -m "Add new code"` 
5. Push your changes to your forked repository: `git push origin my-new-branch` 
6. Open a pull request in this repository, describing your changes. 

Please ensure that your code is well-written, accurate, and commented.

## License 
This repository is licensed under the [BSD 2-Clause License](LICENSE).
