# Changelog

All notable changes to the 35px Lightroom Plugin will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2025-12-15

### Initial Release

#### Added
- **Publish Service Integration**: Seamlessly publish photos from Lightroom to 35px
- **API Key Authentication**: Secure authentication using 35px API keys with verification
- **Album Management**: 
  - Create new albums directly from Lightroom
  - Automatically create albums when publishing
  - Navigate to albums on 35px.com from Lightroom
- **Photo Publishing**:
  - Upload single or multiple photos with batch processing
  - Progress tracking during uploads
  - EXIF metadata preservation
  - Optional caption/title inclusion
  - Configurable JPEG quality settings (60-100)
- **Incremental Publishing**: 
  - Only uploads new or modified photos
  - Metadata change detection (caption/title)
  - Smart re-publish when needed
- **Photo Deletion**:
  - Delete photos from collections
  - API integration for server-side deletion
  - Graceful error handling if deletion fails
- **User Interface**:
  - Clean settings dialog with API key verification
  - Custom plugin icons
  - Progress indicators for all operations
  - Helpful error messages with troubleshooting guidance
- **Error Handling**:
  - Comprehensive error messages
  - Network failure handling
  - Invalid API key detection
  - File size and format validation
  - Database constraint error detection

#### Technical Features
- Full 35px API v1 integration
- JSON encoding/decoding for API communication
- Multipart form data support for file uploads
- Configurable debug logging for troubleshooting
- HTTP method override for DELETE requests

#### Supported File Formats
- JPEG
- PNG
- TIFF
- HEIC
- WebP

#### Known Limitations
- Maximum file size: 25MB per photo
- Album titles are truncated to 50 characters (temporary server constraint)
- Collection rename only affects local name, not server
- Collection deletion only removes local reference, not server album

---

## Future Enhancements

Planned features for upcoming releases:
- Batch album operations
- Photo metadata sync (keywords, ratings)
- Custom upload presets
- Storage usage display in plugin
- Export service templates
- Album visibility settings (public/private/unlisted)
- Photo reordering and sort order
- Download published photos
- Publish collections sets (nested albums)

---

For API documentation, see [API.md](API.md).
