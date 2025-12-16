# 35px Lightroom Publish Service Plugin

A Lightroom Classic plugin that allows photographers to upload photos directly to their 35px photo albums.

## Features

- **Publish Service Integration**: Appears as a publish service in Lightroom's Library module
- **Album Management**: Create and manage 35px albums directly from Lightroom
- **Batch Upload**: Upload multiple photos at once with progress tracking
- **Incremental Publishing**: Only uploads new or modified photos
- **Photo Deletion**: Remove photos from albums via the API
- **EXIF Preservation**: Maintains all camera metadata during upload
- **Caption Support**: Optionally include photo captions/titles
- **Quality Control**: Configurable JPEG quality (60-100)
- **Direct Navigation**: Open albums and photos on 35px.com directly from Lightroom

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
4. Paste your API key in the **API Key** field
5. Click **Verify API Key** to confirm the connection
6. Configure your upload preferences:
   - Enable/disable caption/title inclusion
   - Set JPEG quality (60-100)
7. Click **Save**

## Usage

### Publishing Photos

1. In Lightroom's Library module, select photos to publish
2. Drag them to your 35px publish service collection (or right-click → Publish)
3. Click **Publish** in the publish service panel
4. Photos will upload to your selected 35px album

### Creating Albums

1. Right-click on the 35px publish service
2. Select **Create Published Collection**
3. Enter the album name (will be truncated to 50 characters if longer)
4. The album will be created on 35px immediately

Alternatively, albums are created automatically when you publish photos to a new collection.

### Updating Photos

When you edit a published photo in Lightroom:
1. The photo will appear in "Modified Photos to Re-Publish"
2. Click **Publish** to upload the updated version
3. Changes to caption or title automatically trigger re-publishing

### Deleting Photos

To remove photos from an album:
1. Right-click a published photo
2. Select **Delete from Published Collection**
3. The photo will be removed from both Lightroom and 35px.com

**Note**: If the backend deletion endpoint is not yet available, photos will be removed from Lightroom but may still exist on 35px.com. You'll receive a warning if this happens.

### Navigate to Website

- **View Album**: Right-click collection → "Go to Published Collection"
- **View Photo**: Right-click photo → "Go to Published Photo"

Opens the album or photo directly on 35px.com in your browser.

## Troubleshooting

### "Authentication Failed" or "Verification Failed"
- Verify your API key is correct (copy/paste carefully)
- Check that your API key has the required permissions:
  - `albums:read`, `albums:write`
  - `photos:read`, `photos:write`
- Ensure you have internet connectivity
- Try regenerating your API key on 35px.com

### "Upload Failed"
- Check file size (max 25MB per photo)
- Verify the file format is supported (JPEG, PNG, TIFF, HEIC, WebP)
- Check your storage quota hasn't been exceeded
- Ensure the album exists (create it first if needed)

### "Delete Failed" Warning
- This is expected if the backend deletion endpoint isn't implemented yet
- Photos are still removed from Lightroom
- You can manually delete photos from 35px.com

### "Failed to Create Album" Error
- Try using a shorter album name (max 50 characters)
- Avoid special characters that might cause issues
- Check your API key has `albums:write` permission
- Contact support if the issue persists

### Plugin Not Appearing
- Restart Lightroom completely
- Verify the plugin is enabled in Plug-in Manager
- Check the plugin status shows "Installed and running"
- Look for error messages in the plugin log

### Wrong URL When Opening Album
- Make sure you're using the latest version of the plugin
- The plugin now uses the correct URL format: `https://35px.com/profile/photos/albums/{id}`

## File Structure

```
35px.lrplugin/
├── Info.lua               # Plugin metadata and entry points
├── 35pxAPI.lua            # API communication layer
├── 35pxPublishService.lua # Publish service provider
├── 35pxMenuItems.lua      # Menu item handlers
├── 35pxJSON.lua           # JSON encoding/decoding
├── icon-small.png         # Plugin icon (small)
└── icon-large.png         # Plugin icon (large)
```

## API Endpoints Used

The plugin communicates with the following 35px API endpoints:

- `POST /api/v1/auth/verify` - Verify API key
- `GET /api/v1/albums` - List user's albums (currently unused, planned for future)
- `POST /api/v1/albums` - Create new album
- `POST /api/v1/albums/{albumId}/photos` - Upload photo to album
- `DELETE /api/v1/photos/{photoId}` - Delete photo (requires backend implementation)
- `GET /api/v1/user` - Get user profile (currently unused, planned for future)
- `GET /api/v1/user/storage` - Get storage usage (currently unused, planned for future)

See [API.md](API.md) for complete API documentation.

## Development

### Building for Release

Create a distributable package:

```bash
./build.sh
```

This creates `dist/35px-lightroom-plugin-v{version}.zip` with all necessary files.

### Development Setup

1. Clone the repository
2. Open the `35px.lrplugin` folder in Lightroom's Plug-in Manager
3. Check "Reload plug-in on each export" during development

### Testing

See [PRE-RELEASE-CHECKLIST.md](PRE-RELEASE-CHECKLIST.md) for a comprehensive testing guide.

### Debugging

Enable debug logging by setting `debugMode = true` in `35pxAPI.lua` (line 22):

```lua
API.debugMode = true  -- Enable detailed logging
```

Logs are written to:
- **Mac**: `~/Library/Logs/Adobe/Lightroom/`
- **Windows**: `%APPDATA%\Adobe\Lightroom\Logs\`

Look for files named `35pxAPI.log`.

## Development Process

This plugin was developed with AI assistance to accelerate development and ensure best practices. The combination of human expertise and AI capabilities helped create a robust, well-documented solution for the photography community.

**AI Tools Used:**
- Code generation and optimization
- Documentation writing
- API integration design
- Testing strategy development

All code has been reviewed, tested, and validated to ensure quality and reliability.

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

## Known Limitations

- Maximum file size: 25MB per photo (35px API limit)
- Album names are truncated to 50 characters (temporary server constraint)
- Collection rename only updates the local name, not the server
- Deleting a collection only removes it from Lightroom, not from 35px.com
- Photo deletion requires backend implementation (shows warning if unavailable)

## Support

For issues or feature requests:
- Email: support@35px.com
- Documentation: https://35px.com/docs
- Plugin Issues: Report via GitHub Issues

## Changelog

See [CHANGELOG.md](CHANGELOG.md) for version history and release notes.

---

**Version**: 1.0.0  
**License**: MIT  
**Built with ❤️ for photographers by 35px**

