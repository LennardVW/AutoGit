# AutoGit

🤖 Automatic commit message generation for Git. Analyzes your changes and writes meaningful commit messages.

## Features

- 🧠 **AI-Powered** - Uses heuristics to understand code changes
- 📝 **Conventional Commits** - Follows conventional commit format
- 🏷️ **Smart Categorization** - Auto-detects feat/fix/docs/refactor/test
- 📊 **Change Analysis** - Understands file patterns and modifications
- 🎯 **Context Aware** - Reads diff to generate accurate messages
- ⚡ **Quick Mode** - Auto-commit without confirmation
- 🔄 **Batch Commits** - Handle multiple logical changes

## Installation

```bash
git clone https://github.com/LennardVW/AutoGit.git
cd AutoGit
swift build -c release
sudo cp .build/release/autogit /usr/local/bin/
```

## Usage

```bash
# Stage your changes
git add .

# Get commit suggestions
autogit suggest

# Auto-commit with best suggestion
autogit auto

# Configure settings
autogit config
```

## Examples

| Changes | Generated Commit |
|---------|------------------|
| Added new login view | `feat: Add user login interface` |
| Fixed crash in network layer | `fix: Resolve crash in network request handling` |
| Updated README | `docs: Update installation instructions` |
| Refactored API client | `refactor: Simplify API client architecture` |

## Configuration

```bash
# Set commit style
autogit config style conventional

# Enable auto-push
autogit config autopush true

# Set custom prefixes
autogit config prefix.feature "✨"
```

## Git Hook Integration

```bash
# Install post-commit hook
autogit install-hook

# Now commits will be auto-suggested after staging
```

## Requirements
- macOS 15.0+ (Tahoe)
- Swift 6.0+
- Git 2.0+

## License
MIT
