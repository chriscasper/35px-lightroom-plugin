# Contributing to 35px Lightroom Plugin

First off, thank you for considering contributing to the 35px Lightroom Plugin! 🎉

## How Can I Contribute?

### Reporting Bugs

Before creating bug reports, please check existing issues to avoid duplicates. When creating a bug report, include:

- **Lightroom Classic version** (e.g., 2024, 13.0)
- **Operating system** (macOS/Windows and version)
- **Plugin version** (found in Lightroom's Plugin Manager)
- **Steps to reproduce** the issue
- **Expected behavior** vs **actual behavior**
- **Screenshots** if applicable
- **Error messages** from Lightroom's plugin log (if any)

### Suggesting Features

Feature requests are welcome! Please:

1. Check if the feature has already been requested
2. Open an issue with the `enhancement` label
3. Describe the feature and why it would be useful
4. Include mockups or examples if possible

### Pull Requests

1. **Fork** the repository
2. **Create a branch** for your feature (`git checkout -b feature/amazing-feature`)
3. **Make your changes**
4. **Test** in Lightroom Classic (multiple versions if possible)
5. **Commit** with clear messages (`git commit -m 'Add amazing feature'`)
6. **Push** to your branch (`git push origin feature/amazing-feature`)
7. **Open a Pull Request**

## Development Setup

### Prerequisites

- Adobe Lightroom Classic 2019+ (SDK 9.0)
- Text editor with Lua support (VS Code with Lua extension recommended)
- macOS or Windows

### Local Development

1. Clone the repo:
   ```bash
   git clone https://github.com/35px/lightroom-plugin.git
   ```

2. Create a symlink from Lightroom's plugin folder to your dev folder:
   
   **macOS:**
   ```bash
   ln -s /path/to/repo/35px.lrplugin ~/Library/Application\ Support/Adobe/Lightroom/Modules/35px.lrplugin
   ```
   
   **Windows:**
   ```cmd
   mklink /D "%APPDATA%\Adobe\Lightroom\Modules\35px.lrplugin" "C:\path\to\repo\35px.lrplugin"
   ```

3. In Lightroom, go to **File → Plugin Manager → Add** and select the `.lrplugin` folder

4. After making changes, click **Reload Plug-in** in Plugin Manager to test

### Testing Checklist

Before submitting a PR, please test:

- [ ] Plugin loads without errors
- [ ] API key verification works
- [ ] Albums can be fetched/created
- [ ] Photos upload successfully
- [ ] Photo deletion works
- [ ] Error states are handled gracefully

## Code Style

### Lua Guidelines

- Use 2-space indentation
- Use `local` for all variables
- Add comments for complex logic
- Follow existing patterns in the codebase

### File Structure

```
35px.lrplugin/
├── Info.lua              # Plugin manifest
├── 35pxAPI.lua           # API communication layer
├── 35pxPublishService.lua # Main publish service logic
├── 35pxMenuItems.lua     # Library menu items
├── 35pxJSON.lua          # JSON encoding/decoding
├── icon-small.png        # 16x16 icon
└── icon-large.png        # Plugin icon
```

### Commit Messages

- Use present tense ("Add feature" not "Added feature")
- Use imperative mood ("Move cursor to..." not "Moves cursor to...")
- Keep first line under 72 characters
- Reference issues when applicable (`Fix #123`)

## API Documentation

The 35px API documentation is available at:
- [API.md](API.md) - Full API reference
- [35px.com/docs/api](https://35px.com/docs/api) - Online documentation

## Questions?

- Open an issue with the `question` label
- Contact us at support@35px.com

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

