# VS Code Dark Configuration

A Visual Studio Code profile and settings for a dark-theme setup, including editor/terminal font stacks, word wrap, and a few custom chat keybindings.

## Contents

- [`DefaultVSCodeDarkProfile.code-profile`](./DefaultVSCodeDarkProfile.code-profile) — exported VS Code profile (settings + extensions) that can be imported directly.
- [`settings.json`](./settings.json) — theme (`Bluloco Dark Italic`), editor typography (font size 15, bounded word wrap at column 120, ligatures, custom font stacks), and terminal font/typography settings.
- [`keybindings.json`](./keybindings.json) — custom chat keybindings (e.g. remaps previous-code-block navigation to `Ctrl+Cmd+[`).

## Requirements

The font stacks in `settings.json` reference [Anka:Coder](../nerd-fonts/Anka%3ACoder/), [Anka:Coder Condensed](../nerd-fonts/Anka%3ACoder%20Condensed/), and [AudioLink Mono](../nerd-fonts/AudioLink%20Mono/) from [nerd-fonts](../nerd-fonts/) — install those fonts first, or the editor will fall back to `Courier New`/monospace.

## Installation (recommended)

1. Open VS Code's Profile menu (`Cmd+Shift+P` > **Profiles: Import Profile...**).
2. Select [`DefaultVSCodeDarkProfile.code-profile`](./DefaultVSCodeDarkProfile.code-profile) and import it.

## Example Configuration Preview

![Configuration preview](./vscode-theme-view.png)


### Manual file backup

All your config lives in one folder:

| OS | Path |
|---|---|
| **macOS** | `~/Library/Application Support/Code/User/` |
| **Windows** | `%APPDATA%\Code\User\` |
| **Linux** | `~/.config/Code/User/` |

The key files to back up:
- `settings.json` — all your settings
- `keybindings.json` — custom shortcuts
- `snippets/` — custom code snippets

For extensions, export the list:
```bash
code --list-extensions > extensions.txt
```

Then restore on the new machine:
```bash
cat extensions.txt | xargs -L 1 code --install-extension
```

To restore settings, just copy the files back to the same path on the new machine.

---

### Store config in a Git repo (power user)

Copy your `settings.json` and `keybindings.json` into a dotfiles repo, then symlink them back:

```bash
# Example on macOS/Linux
CWD=$(pwd)
rm ~/Library/Application\ Support/Code/User/keybindings.json
rm ~/Library/Application\ Support/Code/User/settings.json
ln -s $CWD/settings.json ~/Library/Application\ Support/Code/User/settings.json
ln -s $CWD/keybindings.json ~/Library/Application\ Support/Code/User/keybindings.json
```

This way your config is version-controlled and shareable.
