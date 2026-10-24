# macOS Development Environment Setup Script

A zsh script that restores my macOS setup on a new (or existing) Mac: Homebrew formulae and apps, App Store apps, fonts, the zsh configuration, Git, VS Code and iTerm2 settings, and dev toolchains. **Everything is chosen at runtime** from checklists, so you can skip any step and any individual app.

## Features

✅ **Pick what you want** - Checklists for every step and every app category; untick anything you don't need  
✅ **Questions first** - All choices are made up front, then the install runs unattended  
✅ **Safe to re-run** - Already-installed apps are detected (including apps installed by hand) and skipped  
✅ **Automatic Backups** - Existing configs are copied to `*.backup.YYYYmmdd_HHMMSS` before being replaced  
✅ **Keeps going on failure** - A failed package is recorded and shown in the summary instead of aborting the run  
✅ **Dry run** - `--dry-run` prints every command without changing anything  
✅ **Snapshot** - `--snapshot` refreshes the repo copy of the config and app list from the current Mac  

## Prerequisites

- **macOS** (Apple Silicon or Intel)
- **Active internet connection**
- **Administrator privileges** (for Homebrew)
- **Signed in to the App Store** if you want the App Store apps

Xcode Command Line Tools, Homebrew and [gum](https://github.com/charmbracelet/gum) (used for the checklists) are installed automatically.

## Quick Start

```bash
cd initial-install
./install-all-macos.sh             # interactive install
./install-all-macos.sh --dry-run   # see what would happen, change nothing
./install-all-macos.sh --all       # no questions: install everything marked "on"
./install-all-macos.sh --snapshot  # refresh dotfiles/ and packages.conf from this Mac
```

In the checklists: **space** toggles an item, **enter** confirms, **ctrl+c** aborts.

## What Happens During Installation

1. **Preflight** - macOS check, Xcode Command Line Tools
2. **Homebrew** - installed or updated, then `gum`
3. **Choose steps** - all preselected:

   | Step | What it does |
   |---|---|
   | `git` | Writes `~/.gitconfig` (aliases below) with your name/email, adds `~/.gitignore` if missing |
   | `shell` | Restores the zsh config from `dotfiles/` (antidote + starship) |
   | `apps` | Homebrew formulae and casks, one checklist per category |
   | `appstore` | App Store apps via `mas` |
   | `fonts` | Nerd Font casks and the fonts in [`../nerd-fonts`](../nerd-fonts) |
   | `configs` | VS Code settings, keybindings and extensions from [`../vscode-configuration-dark`](../vscode-configuration-dark); iTerm2 prefs from [`../iterm2-config`](../iterm2-config) |
   | `toolchains` | Node 20 + 24 via nvm (with pnpm and serverless@3), Rust via rustup (with cargo-deny and cargo-nextest), Oracle JDK 25 reminder |
   | `mail` | Runs [`../mail-reminder/install.sh`](../mail-reminder) |

4. **Choose apps** - one checklist per category; apps already on the Mac are listed but not offered
5. **Confirm** - shows the plan, then installs
6. **Summary** - what was installed, what failed, and manual follow-ups

## Files

```
initial-install/
├── install-all-macos.sh   # the script
├── packages.conf          # app manifest: categories, packages, defaults
└── dotfiles/
    ├── zshenv             # → ~/.zshenv (sets ZDOTDIR=~/.config/zsh)
    ├── zsh/               # → ~/.config/zsh (.zshrc, .zprofile, plugins, conf.d/, prompt)
    ├── starship.toml      # → ~/.config/starship.toml
    └── gitignore          # → ~/.gitignore (only if missing)
```

## The App Manifest (`packages.conf`)

One package per line:

```
# category | type | id | description | default
Dev Apps   | cask    | visual-studio-code | Visual Studio Code | on
CLI Tools  | formula | lsd                | ls with colours    | on
App Store  | mas     | 441258766          | Magnet             | on
Manual     | manual  | pgModeler          | https://pgmodeler.io/download | -
```

- **type**: `formula`, `cask`, `mas` (App Store ID) or `manual` (shown as a reminder only)
- **default**: `on` is preselected in the checklist, `off` is listed but unticked
- Categories appear in the order they're first used; `App Store`, `Fonts` and `Manual` have their own steps
- Descriptions must not contain commas

To add an app, add a line. To find an App Store ID: `mdls -name kMDItemAppStoreAdamID /Applications/Name.app`.

## Keeping It Up To Date

After changing your shell config or installing new apps, run:

```bash
./install-all-macos.sh --snapshot
git diff
```

This copies `~/.config/zsh`, `~/.zshenv`, `~/.config/starship.toml` and `~/.gitignore` into `dotfiles/`, saves the VS Code extension list, and appends any installed packages missing from `packages.conf` under `Uncategorized` (move them into a proper category). It warns if anything that looks like a secret ended up in `dotfiles/`.

## Shell Configuration

The zsh config lives in `~/.config/zsh` (`ZDOTDIR`), loaded by `~/.zshenv`:

- **antidote** loads plugins from `.zsh_plugins.txt`: Oh My Zsh lib files and plugins (git, colored-man-pages, colorize, jsontools, macos) without the framework, zsh-autocomplete and zsh-syntax-highlighting
- **starship** is the prompt; `ZSH_PROMPT=p10k zsh` switches to Powerlevel10k. It shows the path with parent folders cut to one letter and the repo root highlighted (computed by `_prompt_dir` in `prompt.zsh`), git counts (ahead/behind, staged, modified, untracked, stash, conflicts), changed lines, rebase/merge progress, and the project version, language and Docker context in project folders. Icons need a Nerd Font, or Ghostty, which bundles the symbols
- `conf.d/` holds options, environment, aliases, functions, tool setup, the Ghostty tab title and the login greeting (`90-motd.zsh`: a system summary table, printed once per terminal; run `motd` to show it again)
- **Secrets** go in `~/.config/zsh/.zsh_secrets` (chmod 600). It is never copied into the repo; the script creates an empty one

Restoring copies files over the existing directory, so history, sessions and `.zsh_secrets` are kept. A previous `~/.zshrc` is no longer read once `ZDOTDIR` is set.

## Git Configuration

### Aliases Included

| Alias | Command |
|---|---|
| `git co` | `checkout` |
| `git br` | `branch` |
| `git ci` | `commit` |
| `git st` | `status` |
| `git unstage` | `reset HEAD --` |
| `git last` | `log -1 HEAD` |
| `git cim` | `commit -m` |
| `git ciam` | `commit -a -m` |

### Additional Git Settings

- `core.excludesfile = ~/.gitignore`
- `core.editor = micro`
- `pull.rebase = false`
- `commit.gpgsign = false`
- `init.defaultBranch = main`
- `mergetool.keepBackup = true`

Name and email default to your current global Git identity.

## Troubleshooting

### An App Store app fails to install
`mas` can only install apps you've already got (bought or downloaded before) with the Apple ID signed in to the App Store app. Sign in, then re-run the script; installed apps are skipped.

### A cask fails because the app already exists
Apps installed by hand are detected and skipped. If an install still fails, delete the old app from `/Applications` and re-run, or untick it.

### The prompt or plugins don't load
Open a new terminal (or `exec zsh`). On the first start antidote clones the plugins and builds `.zsh_plugins.zsh`. Check that `antidote` and `starship` are installed: `brew list antidote starship`.

### `Unable to locate a Java Runtime` on shell start
`conf.d/20-env.zsh` sets `JAVA_HOME` from `/usr/libexec/java_home`. Install JDK 25 (the toolchains step opens the download page).

## Backup Recovery

```bash
# List backups
ls -d ~/.gitconfig.backup.* ~/.zshenv.backup.* ~/.config/zsh.backup.* ~/.config/starship.toml.backup.*

# Restore one, e.g. the zsh config
rm -rf ~/.config/zsh && cp -R ~/.config/zsh.backup.YYYYmmdd_HHMMSS ~/.config/zsh
```

## Not Covered

- Apps without a Homebrew or App Store package (listed as `manual` in `packages.conf` and in the summary)
- LaunchAgents other than the mail reminder
- App licences, sign-ins and secrets

## License

This script is provided as-is for personal use. Modify and distribute freely.

### Tools Used
- [Homebrew](https://brew.sh) - Package manager
- [gum](https://github.com/charmbracelet/gum) - Interactive checklists
- [mas](https://github.com/mas-cli/mas) - App Store command line
- [antidote](https://antidote.sh) - zsh plugin manager
- [Starship](https://starship.rs) - Prompt

---

**Note**: Always review scripts before executing them, especially those requiring administrator privileges or downloading content from the internet.

**Last Updated**: October 2026  
**Version**: 3.0 (Restore current setup)
