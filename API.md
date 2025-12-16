# 35px API v1 Documentation

Base URL: `https://35px.com/api/v1`

## Authentication

All API endpoints require authentication using an API key. Include your API key in the `Authorization` header:

```
Authorization: Bearer 35px_your_api_key_here
```

### Generating an API Key

1. Log in to your 35px account
2. Go to **Settings → API Access**
3. Click **Generate New API Key**
4. Give your key a name (e.g., "Lightroom Plugin")
5. Copy the key immediately - it won't be shown again!

### API Key Scopes

API keys can have the following scopes:

| Scope | Description |
|-------|-------------|
| `albums:read` | View your albums |
| `albums:write` | Create, update, delete albums |
| `photos:read` | View photos in your albums |
| `photos:write` | Upload, update, delete photos |
| `user:read` | View your profile and storage info |

---

## Endpoints

### Authentication

#### Verify API Key

```
POST /auth/verify
GET  /auth/verify
```

Verifies that your API key is valid and returns user information.

**Response:**
```json
{
  "valid": true,
  "user": {
    "id": "uuid",
    "username": "photographer"
  },
  "scopes": ["albums:read", "albums:write", "photos:read", "photos:write"]
}
```

---

### User

#### Get User Profile

```
GET /user
```

Returns information about the authenticated user.

**Required Scope:** `user:read`

**Response:**
```json
{
  "user": {
    "id": "uuid",
    "username": "photographer",
    "first_name": "John",
    "last_name": "Doe",
    "avatar_url": "https://...",
    "created_at": "2024-01-01T00:00:00Z"
  },
  "subscription": {
    "status": "active",
    "plan_name": "Pro",
    "storage_limit_gb": 100,
    "storage_used_bytes": 5368709120
  }
}
```

#### Get Storage Usage

```
GET /user/storage
```

Returns detailed storage usage information.

**Response:**
```json
{
  "storage": {
    "used_bytes": 5368709120,
    "limit_bytes": 107374182400,
    "used_gb": 5.0,
    "limit_gb": 100,
    "percentage_used": 5.0,
    "remaining_bytes": 102005473280
  },
  "counts": {
    "albums": 12,
    "photos": 450
  }
}
```

---

### Albums

#### List Albums

```
GET /albums
```

Returns all albums for the authenticated user.

**Required Scope:** `albums:read`

**Query Parameters:**
| Parameter | Type | Description |
|-----------|------|-------------|
| `visibility` | string | Filter by visibility: `all`, `public`, `private`, `unlisted` |
| `include_counts` | boolean | Include photo counts (default: true) |

**Response:**
```json
{
  "albums": [
    {
      "id": "uuid",
      "title": "Wedding Photos",
      "description": "Beautiful wedding in Tuscany",
      "slug": "wedding-photos",
      "visibility": "private",
      "photo_count": 150,
      "total_size_bytes": 1073741824,
      "cover_photo_id": "uuid",
      "created_at": "2024-01-01T00:00:00Z",
      "updated_at": "2024-01-15T00:00:00Z",
      "url": "https://35px.com/@photographer/albums/wedding-photos"
    }
  ],
  "total": 1
}
```

#### Create Album

```
POST /albums
```

Creates a new album.

**Required Scope:** `albums:write`

**Request Body:**
```json
{
  "title": "New Album",
  "description": "Optional description",
  "visibility": "private"
}
```

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `title` | string | Yes | Album title (max 255 chars) |
| `description` | string | No | Album description |
| `visibility` | string | No | `private`, `public`, or `unlisted` (default: `private`) |

**Response:** `201 Created`
```json
{
  "album": {
    "id": "uuid",
    "title": "New Album",
    "description": "Optional description",
    "slug": "new-album",
    "visibility": "private",
    "photo_count": 0,
    "created_at": "2024-01-01T00:00:00Z",
    "url": "https://35px.com/@photographer/albums/new-album"
  }
}
```

#### Get Album

```
GET /albums/{albumId}
```

Returns details for a specific album. `albumId` can be a UUID or slug.

**Required Scope:** `albums:read`

#### Update Album

```
PATCH /albums/{albumId}
```

Updates an album's properties.

**Required Scope:** `albums:write`

**Request Body:**
```json
{
  "title": "Updated Title",
  "description": "New description",
  "visibility": "public"
}
```

#### Delete Album

```
DELETE /albums/{albumId}
```

Deletes an album and removes all photo associations.

**Required Scope:** `albums:write`

**Note:** System albums cannot be deleted.

---

### Photos

#### List Photos in Album

```
GET /albums/{albumId}/photos
```

Returns all photos in an album.

**Required Scope:** `photos:read`

**Response:**
```json
{
  "photos": [
    {
      "id": "uuid",
      "image_id": "uuid",
      "sort_order": 1,
      "caption": "Sunset at the beach",
      "added_at": "2024-01-01T00:00:00Z",
      "url": "https://imagedelivery.net/.../public",
      "filename": "IMG_1234.jpg",
      "file_size_bytes": 5242880,
      "width": 6000,
      "height": 4000,
      "mime_type": "image/jpeg",
      "exif": {
        "camera_make": "Canon",
        "camera_model": "EOS R5",
        "lens_model": "RF 24-70mm F2.8 L IS USM",
        "aperture": 2.8,
        "shutter_speed": "1/250",
        "iso": 100,
        "focal_length": 50,
        "date_taken": "2024-01-01T12:00:00Z"
      }
    }
  ],
  "total": 1
}
```

#### Upload Photo

```
POST /albums/{albumId}/photos
```

Uploads a photo to an album.

**Required Scope:** `photos:write`

**Content-Type:** `multipart/form-data`

**Form Fields:**
| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `file` | File | Yes | Image file (JPEG, PNG, TIFF, HEIC, WebP) |
| `caption` | string | No | Photo caption |

**File Requirements:**
- Maximum size: 25MB
- Supported formats: JPEG, PNG, TIFF, HEIC, HEIF, WebP

**Response:** `201 Created`
```json
{
  "photo": {
    "id": "uuid",
    "image_id": "uuid",
    "sort_order": 5,
    "caption": "Beautiful sunset",
    "added_at": "2024-01-01T00:00:00Z",
    "url": "https://imagedelivery.net/.../public",
    "filename": "sunset.jpg",
    "file_size_bytes": 5242880,
    "width": 6000,
    "height": 4000
  },
  "upload_result": {
    "cloudflare_image_id": "abc123",
    "cloudflare_variant_url": "https://imagedelivery.net/.../public"
  }
}
```

#### Get Photo

```
GET /albums/{albumId}/photos/{photoId}
```

Returns details for a specific photo including full EXIF data.

**Required Scope:** `photos:read`

#### Update Photo

```
PATCH /albums/{albumId}/photos/{photoId}
```

Updates a photo's caption or sort order.

**Required Scope:** `photos:write`

**Request Body:**
```json
{
  "caption": "New caption",
  "sort_order": 3
}
```

#### Delete Photo from Album

```
DELETE /albums/{albumId}/photos/{photoId}
```

Removes a photo from a specific album.

**Required Scope:** `photos:write`

#### Delete Photo

```
DELETE /photos/{photoId}
```

Deletes a photo by its ID without requiring the album ID. This will remove the photo from all albums and delete the underlying image if it's no longer referenced.

**Required Scope:** `photos:write`

**Response:** `200 OK`
```json
{
  "success": true,
  "message": "Photo deleted successfully"
}
```

---

## Error Responses

All errors follow this format:

```json
{
  "error": "Error message",
  "message": "Detailed description of the error"
}
```

### HTTP Status Codes

| Code | Description |
|------|-------------|
| `200` | Success |
| `201` | Created |
| `400` | Bad Request - Invalid input |
| `401` | Unauthorized - Invalid or missing API key |
| `403` | Forbidden - Insufficient permissions or subscription |
| `404` | Not Found - Resource doesn't exist |
| `429` | Too Many Requests - Rate limit exceeded |
| `500` | Internal Server Error |

---

## Rate Limiting

API requests are rate limited to prevent abuse:

- **100 requests per minute** per API key
- **10 uploads per minute** per API key

Rate limit headers are included in responses:
```
X-RateLimit-Limit: 100
X-RateLimit-Remaining: 95
X-RateLimit-Reset: 1704067260
```

---

## Examples

### cURL - List Albums

```bash
curl -X GET "https://35px.com/api/v1/albums" \
  -H "Authorization: Bearer 35px_your_api_key_here"
```

### cURL - Upload Photo

```bash
curl -X POST "https://35px.com/api/v1/albums/{albumId}/photos" \
  -H "Authorization: Bearer 35px_your_api_key_here" \
  -F "file=@/path/to/photo.jpg" \
  -F "caption=Beautiful sunset"
```

### JavaScript - Create Album

```javascript
const response = await fetch('https://35px.com/api/v1/albums', {
  method: 'POST',
  headers: {
    'Authorization': 'Bearer 35px_your_api_key_here',
    'Content-Type': 'application/json'
  },
  body: JSON.stringify({
    title: 'My New Album',
    visibility: 'private'
  })
});

const { album } = await response.json();
console.log('Created album:', album.id);
```

### Python - Upload Photos

```python
import requests

api_key = '35px_your_api_key_here'
album_id = 'your-album-id'

with open('photo.jpg', 'rb') as f:
    response = requests.post(
        f'https://35px.com/api/v1/albums/{album_id}/photos',
        headers={'Authorization': f'Bearer {api_key}'},
        files={'file': f},
        data={'caption': 'Beautiful photo'}
    )
    
print(response.json())
```

