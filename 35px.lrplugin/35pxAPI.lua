--[[----------------------------------------------------------------------------
35px Lightroom Publish Service Plugin
35pxAPI.lua - API communication layer

Copyright (c) 2025-2026 35px. MIT License.
------------------------------------------------------------------------------]]

local LrHttp = import 'LrHttp'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrStringUtils = import 'LrStringUtils'
local LrDate = import 'LrDate'
local LrErrors = import 'LrErrors'
local LrDialogs = import 'LrDialogs'

local JSON = require '35pxJSON'

local API = {}

-- Configuration
API.debugMode = true  -- Enable for debugging
API.baseUrl = "https://35px.com"
API.apiVersion = "v1"

-- Internal state
local apiKey = nil

--------------------------------------------------------------------------------
-- Utility Functions
--------------------------------------------------------------------------------

local function log(message)
  if API.debugMode then
    local timestamp = LrDate.timeToUserFormat(LrDate.currentTime(), "%Y-%m-%d %H:%M:%S")
    print(string.format("[35px %s] %s", timestamp, message))
  end
end

-- Helper to get table keys for debugging
local function getKeys(t)
  local keys = {}
  if type(t) == "table" then
    for k, _ in pairs(t) do
      table.insert(keys, tostring(k))
    end
  end
  return keys
end

local function getApiUrl(endpoint)
  return string.format("%s/api/%s%s", API.baseUrl, API.apiVersion, endpoint)
end

local function makeHeaders()
  local headers = {
    { field = 'Authorization', value = 'Bearer ' .. (apiKey or '') },
    { field = 'Content-Type', value = 'application/json' },
    { field = 'Accept', value = 'application/json' },
    { field = 'User-Agent', value = '35px-Lightroom-Plugin/1.0' },
  }
  return headers
end

local function makeMultipartHeaders(boundary)
  local headers = {
    { field = 'Authorization', value = 'Bearer ' .. (apiKey or '') },
    { field = 'Content-Type', value = 'multipart/form-data; boundary=' .. boundary },
    { field = 'Accept', value = 'application/json' },
    { field = 'User-Agent', value = '35px-Lightroom-Plugin/1.0' },
  }
  return headers
end

local function handleResponse(body, headers)
  if not body then
    return nil, "No response from server"
  end
  
  log("Response body: " .. tostring(body))
  
  local success, result = pcall(function()
    return JSON.decode(body)
  end)
  
  if not success then
    log("Failed to parse JSON response: " .. body)
    -- Return the raw body for debugging
    local preview = string.sub(body, 1, 200)
    return nil, "Invalid response from server: " .. preview
  end
  
  return result, nil
end

--------------------------------------------------------------------------------
-- Authentication
--------------------------------------------------------------------------------

function API.setApiKey(key)
  apiKey = key
  log("API key set")
end

function API.getApiKey()
  return apiKey
end

function API.verifyApiKey(key)
  log("Verifying API key...")
  
  local tempKey = apiKey
  apiKey = key
  
  local url = getApiUrl("/auth/verify")
  local body, headers = LrHttp.post(url, "{}", makeHeaders())
  
  local result, err = handleResponse(body, headers)
  
  if err then
    apiKey = tempKey
    return false, err
  end
  
  if result and result.valid then
    log("API key verified successfully")
    return true, result.user
  else
    apiKey = tempKey
    return false, result and result.error or "Invalid API key"
  end
end

--------------------------------------------------------------------------------
-- Albums
--------------------------------------------------------------------------------

function API.getAlbums()
  log("Fetching albums...")
  
  local url = getApiUrl("/albums")
  local body, headers = LrHttp.get(url, makeHeaders())
  
  local result, err = handleResponse(body, headers)
  
  if err then
    return nil, err
  end
  
  if result and result.albums then
    log(string.format("Retrieved %d albums", #result.albums))
    return result.albums, nil
  else
    return nil, result and result.error or "Failed to fetch albums"
  end
end

function API.getAlbum(albumId)
  log(string.format("Fetching album: %s", albumId))
  
  local url = getApiUrl("/albums/" .. albumId)
  local body, headers = LrHttp.get(url, makeHeaders())
  
  local result, err = handleResponse(body, headers)
  
  if err then
    return nil, err
  end
  
  if result and result.album then
    return result.album, nil
  else
    return nil, result and result.error or "Failed to fetch album"
  end
end

function API.createAlbum(title, description, visibility)
  log(string.format("Creating album: %s", title))
  
  -- Check API key
  if not apiKey or apiKey == "" then
    return nil, "API key not configured"
  end
  
  local url = getApiUrl("/albums")
  local payload = JSON.encode({
    title = title,
    description = description or "",
    visibility = visibility or "private"
  })
  
  log(string.format("POST %s with payload: %s", url, payload))
  
  local body, headers = LrHttp.post(url, payload, makeHeaders())
  
  -- Log response headers for debugging
  if headers then
    for k, v in pairs(headers) do
      if type(v) == "table" then
        log(string.format("Header %s: %s = %s", k, tostring(v.field), tostring(v.value)))
      else
        log(string.format("Header %s: %s", k, tostring(v)))
      end
    end
  end
  
  -- Check if request failed completely
  if not body then
    log("No response body received")
    return nil, "No response from server. Please check your internet connection."
  end
  
  log(string.format("Response body: %s", string.sub(body, 1, 500)))
  
  local result, err = handleResponse(body, headers)
  
  if err then
    log(string.format("Parse error: %s", err))
    return nil, err
  end
  
  -- Log the parsed result
  if result then
    log(string.format("Parsed result keys: %s", table.concat(getKeys(result), ", ")))
  end
  
  if result and result.album then
    log(string.format("Album created: %s", result.album.id))
    return result.album, nil
  elseif result and result.error then
    local errorMsg = result.error
    if result.message then
      errorMsg = errorMsg .. ": " .. result.message
    end
    if result.details then
      errorMsg = errorMsg .. " (" .. tostring(result.details) .. ")"
    end
    log(string.format("API error: %s", errorMsg))
    return nil, errorMsg
  else
    log("Unknown response format - returning raw body")
    return nil, "Unexpected response: " .. string.sub(body, 1, 200)
  end
end


--------------------------------------------------------------------------------
-- Photo Upload
--------------------------------------------------------------------------------

function API.uploadPhoto(albumId, filePath, caption, progressCallback)
  log(string.format("Uploading photo to album %s: %s", albumId, filePath))
  
  -- Read file
  local fileHandle = io.open(filePath, "rb")
  if not fileHandle then
    return nil, "Could not read file: " .. filePath
  end
  
  local fileContent = fileHandle:read("*all")
  fileHandle:close()
  
  if not fileContent or #fileContent == 0 then
    return nil, "File is empty: " .. filePath
  end
  
  -- Get filename
  local filename = LrPathUtils.leafName(filePath)
  
  -- Determine MIME type
  local extension = string.lower(LrPathUtils.extension(filePath))
  local mimeType = "image/jpeg"
  if extension == "png" then
    mimeType = "image/png"
  elseif extension == "tif" or extension == "tiff" then
    mimeType = "image/tiff"
  elseif extension == "heic" then
    mimeType = "image/heic"
  elseif extension == "webp" then
    mimeType = "image/webp"
  end
  
  -- Build multipart form data
  local boundary = "----35pxBoundary" .. tostring(os.time()) .. tostring(math.random(1000000))
  
  local parts = {}
  
  -- File part
  table.insert(parts, "--" .. boundary)
  table.insert(parts, string.format('Content-Disposition: form-data; name="file"; filename="%s"', filename))
  table.insert(parts, "Content-Type: " .. mimeType)
  table.insert(parts, "")
  table.insert(parts, fileContent)
  
  -- Caption part (if provided)
  if caption and caption ~= "" then
    table.insert(parts, "--" .. boundary)
    table.insert(parts, 'Content-Disposition: form-data; name="caption"')
    table.insert(parts, "")
    table.insert(parts, caption)
  end
  
  -- End boundary
  table.insert(parts, "--" .. boundary .. "--")
  table.insert(parts, "")
  
  local payload = table.concat(parts, "\r\n")
  
  -- Upload
  local url = getApiUrl("/albums/" .. albumId .. "/photos")
  local body, headers = LrHttp.post(url, payload, makeMultipartHeaders(boundary))
  
  local result, err = handleResponse(body, headers)
  
  if err then
    return nil, err
  end
  
  if result and (result.album_photo or result.photo) then
    local photo = result.album_photo or result.photo
    log(string.format("Photo uploaded successfully: %s", photo.id or "unknown"))
    return photo, nil
  else
    return nil, result and result.error or "Failed to upload photo"
  end
end

function API.deletePhoto(albumId, photoId)
  log(string.format("Deleting photo %s from album %s", photoId, albumId))
  
  local url = getApiUrl("/albums/" .. albumId .. "/photos/" .. photoId)
  
  -- LrHttp doesn't have a delete method, so we use post with method override
  local headers = makeHeaders()
  table.insert(headers, { field = 'X-HTTP-Method-Override', value = 'DELETE' })
  
  local body, respHeaders = LrHttp.post(url, "{}", headers)
  
  local result, err = handleResponse(body, respHeaders)
  
  if err then
    return false, err
  end
  
  if result and result.success then
    log("Photo deleted successfully")
    return true, nil
  else
    return false, result and result.error or "Failed to delete photo"
  end
end

--------------------------------------------------------------------------------
-- User Info
--------------------------------------------------------------------------------

function API.getUserInfo()
  log("Fetching user info...")
  
  local url = getApiUrl("/user")
  local body, headers = LrHttp.get(url, makeHeaders())
  
  local result, err = handleResponse(body, headers)
  
  if err then
    return nil, err
  end
  
  if result and result.user then
    return result.user, nil
  else
    return nil, result and result.error or "Failed to fetch user info"
  end
end

function API.getStorageUsage()
  log("Fetching storage usage...")
  
  local url = getApiUrl("/user/storage")
  local body, headers = LrHttp.get(url, makeHeaders())
  
  local result, err = handleResponse(body, headers)
  
  if err then
    return nil, err
  end
  
  return result, nil
end

--------------------------------------------------------------------------------

return API

