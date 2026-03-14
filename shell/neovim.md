# Neovim + cmux Collaborative Editing Workflow

**Date:** 2026-03-14
**Status:** active

## What This Is

A workflow where the agent controls a neovim instance running in a cmux split pane. The user says "open the cookbook" or "take me to the graph module" and the agent navigates them there. The user edits and reads in neovim while the agent works in its own pane.

## Setup

### Neovim config

Location: `~/.config/nvim/init.lua`

Minimal config with:
- **lazy.nvim** - plugin manager (bootstraps itself on first run)
- **nvim-tree** - file tree sidebar (replaces netrw)
- **nvim-web-devicons** - file type icons in the tree
- Basic settings: line numbers, 2-space tabs, termguicolors

Plugins stored at: `~/.local/share/nvim/lazy/`

### nvopen script

Location: `~/.local/bin/nvopen`

CLI tool that finds the "editor" neovim surface in the current cmux workspace and sends commands to it.

```bash
nvopen /path/to/file          # Open file in nvim
nvopen /path/to/dir           # Open directory in nvim
nvopen --tree                 # Toggle the file tree sidebar
nvopen --find                 # Find current file in tree
nvopen --cmd ':some command'  # Send arbitrary nvim command
```

**How it works:**
1. Scans all pane surfaces in the current cmux workspace for one titled "editor"
2. If none found, creates a right split, launches nvim, and names the tab "editor"
3. Sends the `:e <path>` command (or other command) to that surface via `cmux send`

**Path note:** `~/.local/bin` is in the user's PATH (configured in `~/.zshrc`) but may not be loaded in the agent's shell. Use the full path `~/.local/bin/nvopen` from the agent.

## How to Use (Agent Onboarding)

### Starting a session

Create the editor pane and name it:

```bash
cmux new-pane --direction right
# Returns: OK surface:NN pane:NN workspace:NN

cmux rename-tab --surface surface:NN "editor"

cmux send --surface surface:NN "nvim"
cmux send-key --surface surface:NN Enter
```

Or just run `nvopen` with any file - it auto-creates the editor if none exists.

### Navigating the user to a file

Always use absolute paths:

```bash
~/.local/bin/nvopen /path/to/project/path/to/file.json
```

Or equivalently:

```bash
cmux send --surface surface:NN ":e /absolute/path/to/file"
cmux send-key --surface surface:NN Enter
```

**Never use relative paths.** The nvim instance's cwd may be `~` or anywhere else. Always resolve to absolute paths.

### Showing the file tree

```bash
~/.local/bin/nvopen --find    # Opens tree focused on current file
~/.local/bin/nvopen --tree    # Toggles tree open/closed
```

### Sending arbitrary vim commands

```bash
~/.local/bin/nvopen --cmd ':set wrap'
~/.local/bin/nvopen --cmd ':NvimTreeCollapse'
```

### Finding the editor surface

If you need to interact with cmux directly (beyond what nvopen provides), find the editor surface:

```bash
cmux --json list-pane-surfaces --pane pane:NN
# Look for the surface with "title": "editor"
```

Or scan all panes:

```bash
cmux --json list-panes
# Then list-pane-surfaces for each pane, find title "editor"
```

### cmux send gotchas

- `cmux send` types text into the surface as if the user typed it
- `cmux send-key` sends a single keypress (Enter, Escape, etc.)
- For vim commands, send the command string then send-key Enter
- For vim keybindings (like Space+f), just send the key sequence - no Enter needed
- If nvim is in insert mode, commands won't work - send Escape first
- "Surface is not a terminal" error means vim or another program is running in a mode cmux can't send to - try a different approach

## User's Neovim Keybindings

| Key | Action |
|---|---|
| Space+e | Toggle file tree sidebar |
| Space+f | Find current file in tree |

### In nvim-tree (file tree sidebar)

| Key | Action |
|---|---|
| Enter | Open file / expand folder |
| Ctrl+] | Change tree root to folder under cursor (move into) |
| - | Go up one directory |
| a | Create file or directory |
| d | Delete |
| r | Rename |
| H | Toggle hidden files |
| ? | Show all keybindings |

## Architecture Note

The surface ID (e.g. surface:14) is ephemeral - it changes every cmux session. The tab title "editor" is the stable identifier. nvopen uses the title to discover the surface dynamically, so it works across sessions without hardcoded IDs.

Multiple workspaces can each have their own "editor" surface. nvopen finds the one in the current workspace (via CMUX_WORKSPACE_ID environment variable set automatically in cmux terminals).
