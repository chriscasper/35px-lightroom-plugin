# 35px Lightroom Publish Service Plugin

A Lightroom Classic plugin that allows photographers to upload photos directly to their 35px photo albums.

## Features

- **Publish Service Integration**: Appears as a publish service in Lightroom's Library module
- **Album Sync**: View and select your 35px albums directly from Lightroom
- **Batch Upload**: Upload multiple photos at once with progress tracking
- **Incremental Publishing**: Only uploads new or modified photos
- **EXIF Preservation**: Maintains all camera metadata during upload
- **Caption Support**: Optionally include photo captions/titles

## Requirements

- Adobe Lightroom Classic 2019 or later (SDK 9.0+)
- A 35px account with a paid subscription (API access required)
- An API key generated from your 35px settings

## Installation

### Method 1: Download and Install (Recommended)

1. Download the latest release: `35px-lightroom-plugin-vX.X.X.zip`
2. Extract the ZIP file
3. Open Lightroom Classic
4. Go to **File → Plug-in Manager**
5. Click **Add** and navigate to the extracted `35px.lrplugin` folder
6. Click **Select Folder** (Mac) or **OK** (Windows)
7. The plugin should now appear in the list as "35px"

### Method 2: Copy to Plugins Folder

Extract and copy the `35px.lrplugin` folder to:

- **Mac**: `~/Library/Application Support/Adobe/Lightroom/Modules/`
- **Windows**: `C:\Users\[username]\AppData\Roaming\Adobe\Lightroom\Modules\`

Restart Lightroom after copying.

### Method 3: Double-Click Install (Mac)

On macOS, you can double-click the `35px.lrplugin` bundle to open Lightroom's Plug-in Manager directly.

## Setup

### 1. Generate an API Key

1. Log in to your 35px account
2. Go to **Settings → API Access**
3. Click **Generate New API Key**
4. Copy the key (you won't be able to see it again!)

### 2. Configure the Plugin

1. In Lightroom, go to the **Library** module
2. In the left panel, find **Publish Services**
3. Click **Set Up...** next to "35px"
4. Paste your API key in the configuration dialog
5. Click **Authenticate** to verify the connection
6. Select your default album or create a new one

## Usage

### Publishing Photos

1. In Lightroom's Library module, select photos to publish
2. Drag them to your 35px publish service collection (or right-click → Publish)
3. Click **Publish** in the publish service panel
4. Photos will upload to your selected 35px album

### Creating Albums

1. Right-click on the 35px publish service
2. Select **Create Published Folder**
3. Enter the album name
4. The album will be created on 35px and synced locally

### Updating Photos

When you edit a published photo in Lightroom:
1. The photo will appear in "Modified Photos to Re-Publish"
2. Click **Publish** to upload the updated version

## Troubleshooting

### "Authentication Failed"
- Verify your API key is correct
- Check that your subscription includes API access
- Ensure you have internet connectivity

### "Upload Failed"
- Check file size (max 25MB per photo)
- Verify the file format is supported (JPEG, PNG, TIFF, HEIC)
- Check your storage quota hasn't been exceeded

### Plugin Not Appearing
- Restart Lightroom
- Verify the plugin is enabled in Plug-in Manager
- Check the plugin status shows "Installed and running"

## File Structure

```
35px.lrplugin/
├── Info.lua              # Plugin metadata and entry points
├── 35pxAPI.lua           # API communication layer
├── 35pxPublishService.lua # Publish service provider
├── 35pxDialogs.lua       # UI dialogs and settings
└── 35pxUtils.lua         # Utility functions
```

## API Endpoints Used

The plugin communicates with the following 35px API endpoints:

- `POST /api/v1/auth/verify` - Verify API key
- `GET /api/v1/albums` - List user's albums
- `POST /api/v1/albums` - Create new album
- `POST /api/v1/albums/:id/photos` - Upload photo
- `DELETE /api/v1/albums/:id/photos/:photoId` - Delete photo

## Development

### Building

No build step required - Lua files are interpreted directly by Lightroom.

### Testing

1. Enable the plugin in Lightroom's Plug-in Manager
2. Check "Reload plug-in on each export" during development
3. View logs in Lightroom's plugin logs folder

### Debugging

Enable debug logging by setting `debugMode = true` in `35pxAPI.lua`

Logs are written to:
- **Mac**: `~/Library/Logs/Adobe/Lightroom/`
- **Windows**: `%APPDATA%\Adobe\Lightroom\Logs\`

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add some amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## License

MIT License - See [LICENSE](LICENSE) file for details.

This means you can:
- ✅ Use commercially
- ✅ Modify
- ✅ Distribute
- ✅ Use privately

Just keep the copyright notice in the code.

## Support

For issues or feature requests:
- Email: support@35px.com
- GitHub Issues: [link to repo]

---

Built with ❤️ for photographers by 35px

