--[[----------------------------------------------------------------------------
35px Lightroom Publish Service Plugin
35pxPublishService.lua - Publish service provider implementation

Copyright (c) 2025-2026 35px. MIT License.
------------------------------------------------------------------------------]]

local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrHttp = import 'LrHttp'
local LrPathUtils = import 'LrPathUtils'
local LrFileUtils = import 'LrFileUtils'
local LrTasks = import 'LrTasks'
local LrProgressScope = import 'LrProgressScope'
local LrErrors = import 'LrErrors'
local LrApplication = import 'LrApplication'
local LrBinding = import 'LrBinding'
local LrFunctionContext = import 'LrFunctionContext'
local LrColor = import 'LrColor'

local API = require '35pxAPI'

local publishServiceProvider = {}

--------------------------------------------------------------------------------
-- Service Definition
--------------------------------------------------------------------------------

publishServiceProvider.supportsIncrementalPublish = 'only'
publishServiceProvider.hideSections = { 'exportLocation', 'fileNaming' }
publishServiceProvider.allowFileFormats = { 'JPEG', 'TIFF', 'ORIGINAL' }
publishServiceProvider.allowColorSpaces = { 'sRGB', 'AdobeRGB', 'ProPhotoRGB' }
publishServiceProvider.canExportVideo = false

publishServiceProvider.exportPresetFields = {
  { key = 'apiKey', default = '' },
  { key = 'apiKeyName', default = '' },
  { key = 'defaultAlbumId', default = '' },
  { key = 'defaultAlbumName', default = '' },
  { key = 'includeCaption', default = true },
  { key = 'jpegQuality', default = 95 },
}

--------------------------------------------------------------------------------
-- UI Sections
--------------------------------------------------------------------------------

function publishServiceProvider.sectionsForTopOfDialog(viewFactory, propertyTable)
  local f = viewFactory
  local bind = LrView.bind
  local share = LrView.share
  
  return {
    {
      title = "35px Account",
      synopsis = bind { key = 'apiKeyName', object = propertyTable },
      
      f:row {
        spacing = f:control_spacing(),
        
        f:static_text {
          title = "API Key:",
          alignment = 'right',
          width = share 'labelWidth',
        },
        
        f:edit_field {
          value = bind 'apiKey',
          width_in_chars = 40,
          immediate = true,
        },
      },
      
      f:row {
        spacing = f:control_spacing(),
        
        f:static_text {
          title = "",
          width = share 'labelWidth',
        },
        
        f:push_button {
          title = "Verify API Key",
          action = function(button)
            LrTasks.startAsyncTask(function()
              local key = propertyTable.apiKey
              if not key or key == "" then
                LrDialogs.message("Please enter an API key first.")
                return
              end
              
              local valid, userOrError = API.verifyApiKey(key)
              
              if valid then
                propertyTable.apiKeyName = userOrError.username or "Connected"
                LrDialogs.message("Success!", "API key verified. Connected as: " .. (userOrError.username or "Unknown"))
              else
                propertyTable.apiKeyName = ""
                LrDialogs.message("Verification Failed", userOrError or "Invalid API key")
              end
            end)
          end,
        },
        
        f:static_text {
          title = bind 'apiKeyName',
          fill_horizontal = 1,
          text_color = LrColor(0, 0.5, 0),
        },
      },
      
      f:row {
        spacing = f:control_spacing(),
        
        f:static_text {
          title = "",
          width = share 'labelWidth',
        },
        
        f:static_text {
          title = "Get your API key from 35px.com → Settings → API Access",
          fill_horizontal = 1,
          text_color = LrColor(0.5, 0.5, 0.5),
        },
      },
    },
  }
end

function publishServiceProvider.sectionsForBottomOfDialog(viewFactory, propertyTable)
  local f = viewFactory
  local bind = LrView.bind
  local share = LrView.share
  
  return {
    {
      title = "Upload Options",
      
      f:row {
        spacing = f:control_spacing(),
        
        f:checkbox {
          title = "Include photo caption/title",
          value = bind 'includeCaption',
        },
      },
      
      f:row {
        spacing = f:control_spacing(),
        
        f:static_text {
          title = "JPEG Quality:",
          alignment = 'right',
          width = share 'labelWidth',
        },
        
        f:slider {
          value = bind 'jpegQuality',
          min = 60,
          max = 100,
          integral = true,
          width_in_chars = 10,
        },
        
        f:static_text {
          title = bind 'jpegQuality',
          width_in_chars = 3,
        },
      },
    },
  }
end

--------------------------------------------------------------------------------
-- Publish Service Callbacks
--------------------------------------------------------------------------------

-- Called when the publish service is first set up
function publishServiceProvider.startDialog(propertyTable)
  -- Initialize API with stored key if available
  if propertyTable.apiKey and propertyTable.apiKey ~= "" then
    API.setApiKey(propertyTable.apiKey)
  end
end

-- Called when dialog is closed
function publishServiceProvider.endDialog(propertyTable)
  -- Store the API key for future use
  if propertyTable.apiKey then
    API.setApiKey(propertyTable.apiKey)
  end
end

-- Validate settings before publishing
function publishServiceProvider.updateExportSettings(exportSettings)
  -- Ensure we have an API key
  if not exportSettings.apiKey or exportSettings.apiKey == "" then
    return nil, "Please configure your 35px API key in the publish service settings."
  end
  
  API.setApiKey(exportSettings.apiKey)
  return exportSettings
end

--------------------------------------------------------------------------------
-- Collection Management (Albums)
--------------------------------------------------------------------------------

-- Can we create collections (albums)?
function publishServiceProvider.supportsCustomSortOrder()
  return true
end

-- Get list of albums from 35px
function publishServiceProvider.getCollectionBehaviorInfo(publishSettings)
  return {
    defaultCollectionName = "35px Albums",
    defaultCollectionCanBeDeleted = false,
    canAddCollection = true,
    maxCollectionSetDepth = 0, -- No nested collections/sets
  }
end

-- Called when user wants to create a new published folder (album)
function publishServiceProvider.createPublishedCollection(publishSettings, info)
  -- Debug: Show that we got here
  LrDialogs.message("35px: Creating Album", "Creating album '" .. (info.name or "unknown") .. "' on 35px...")
  
  -- Check if we have an API key
  if not publishSettings.apiKey or publishSettings.apiKey == "" then
    LrDialogs.message("35px Error", "No API key found. Please configure your API key in the publish service settings.")
    LrErrors.throwUserError("Please configure your 35px API key first. Edit the publish service settings to add your API key.")
  end
  
  API.setApiKey(publishSettings.apiKey)
  
  local album, err = API.createAlbum(info.name, "", "private")
  
  if err then
    local fullError = "Failed to create album: " .. tostring(err)
    LrDialogs.message("35px Error", fullError, "critical")
    LrErrors.throwUserError(fullError)
  end
  
  if not album then
    LrDialogs.message("35px Error", "No response from 35px server")
    LrErrors.throwUserError("Failed to create album: No response from 35px server")
  end
  
  if not album.id then
    LrDialogs.message("35px Error", "Invalid response - no album ID")
    LrErrors.throwUserError("Failed to create album: Invalid response from 35px server")
  end
  
  -- Success!
  LrDialogs.message("35px: Album Created", "Album '" .. (album.title or info.name) .. "' created successfully on 35px!")
  
  -- Use slug if available, otherwise fall back to ID for URL
  local urlSlug = album.slug or album.id
  
  return {
    remoteId = album.id,
    remoteUrl = "https://35px.com/albums/" .. urlSlug,
    name = album.title or info.name,
  }
end

-- Called when user renames a published folder
function publishServiceProvider.renamePublishedCollection(publishSettings, info)
  -- For now, we don't support renaming on the server
  -- The local name will change but server stays the same
  return true
end

-- Called when user deletes a published folder
function publishServiceProvider.deletePublishedCollection(publishSettings, info)
  -- We won't delete the album on 35px - just remove the local reference
  -- Users should delete albums through the 35px web interface
  return true
end

--------------------------------------------------------------------------------
-- Photo Publishing
--------------------------------------------------------------------------------

-- Main export/publish function
function publishServiceProvider.processRenderedPhotos(functionContext, exportContext)
  local exportSession = exportContext.exportSession
  local exportSettings = exportContext.propertyTable
  local publishedCollection = exportContext.publishedCollection
  
  -- Set up API first
  API.setApiKey(exportSettings.apiKey)
  
  -- Get the album ID from the collection
  local collectionInfo = publishedCollection:getCollectionInfoSummary()
  local albumId = collectionInfo.remoteId
  
  -- If no album ID, create the album on 35px automatically
  if not albumId then
    local collectionName = publishedCollection:getName()
    
    local album, err = API.createAlbum(collectionName, "", "private")
    
    if err then
      LrErrors.throwUserError("Failed to create album on 35px: " .. err)
    end
    
    if album and album.id then
      albumId = album.id
      -- Store the remote ID and URL on the collection
      local catalog = LrApplication.activeCatalog()
      catalog:withWriteAccessDo("Update collection remote ID", function()
        publishedCollection:setRemoteId(album.id)
        publishedCollection:setRemoteUrl("https://35px.com/albums/" .. (album.slug or album.id))
      end)
    else
      LrErrors.throwUserError("Failed to create album on 35px. Please try again.")
    end
  end
  
  -- Get count for progress
  local nPhotos = exportSession:countRenditions()
  
  -- Set up progress scope
  local progressScope = exportContext:configureProgress {
    title = string.format("Publishing %d photo(s) to 35px", nPhotos),
  }
  
  -- Track results
  local failures = {}
  
  -- Process each photo
  for i, rendition in exportContext:renditions { stopIfCanceled = true } do
    progressScope:setPortionComplete((i - 1) / nPhotos)
    
    if progressScope:isCanceled() then
      break
    end
    
    local photo = rendition.photo
    local success, pathOrMessage = rendition:waitForRender()
    
    if success then
      local filePath = pathOrMessage
      
      -- Get caption if enabled
      local caption = nil
      if exportSettings.includeCaption then
        caption = photo:getFormattedMetadata('caption')
        if not caption or caption == "" then
          caption = photo:getFormattedMetadata('title')
        end
      end
      
      -- Upload to 35px
      progressScope:setCaption(string.format("Uploading %s (%d of %d)", 
        LrPathUtils.leafName(filePath), i, nPhotos))
      
      local result, uploadErr = API.uploadPhoto(albumId, filePath, caption)
      
      if result then
        -- Mark as published with the remote photo ID
        local remoteId = result.id or result.image_id
        local remoteUrl = nil
        
        if result.image and result.image.cloudflare_variant_url then
          remoteUrl = result.image.cloudflare_variant_url
        end
        
        rendition:recordPublishedPhotoId(remoteId)
        
        if remoteUrl then
          rendition:recordPublishedPhotoUrl(remoteUrl)
        end
      else
        -- Record failure
        table.insert(failures, {
          photo = photo,
          error = uploadErr or "Unknown error"
        })
        rendition:uploadFailed(uploadErr or "Upload failed")
      end
      
      -- Clean up temp file
      LrFileUtils.delete(filePath)
    else
      -- Render failed
      table.insert(failures, {
        photo = photo,
        error = pathOrMessage or "Render failed"
      })
    end
  end
  
  progressScope:done()
  
  -- Report any failures
  if #failures > 0 then
    local message = string.format("%d photo(s) failed to upload:", #failures)
    for _, failure in ipairs(failures) do
      message = message .. "\n• " .. (failure.error or "Unknown error")
    end
    LrDialogs.message("Some uploads failed", message, "warning")
  end
end

-- Called when user wants to delete a published photo
function publishServiceProvider.deletePhotosFromPublishedCollection(publishSettings, arrayOfPhotoIds, deletedCallback)
  API.setApiKey(publishSettings.apiKey)
  
  for _, photoId in ipairs(arrayOfPhotoIds) do
    -- We have the remote photo ID stored - delete it
    -- Note: We'd need the album ID too, which we might need to track differently
    -- For now, just mark as deleted locally
    deletedCallback(photoId)
  end
end

-- Metadata that triggers republish when changed
function publishServiceProvider.metadataThatTriggersRepublish(publishSettings)
  return {
    default = false,
    caption = true,
    title = true,
    keywords = false,
  }
end

--------------------------------------------------------------------------------
-- Going to Publish Service Site
--------------------------------------------------------------------------------

function publishServiceProvider.goToPublishedCollection(publishSettings, info)
  -- Try to get the URL from the collection info
  local url = nil
  
  -- First check if we have a stored remoteUrl
  if info.remoteUrl and info.remoteUrl ~= "" then
    url = info.remoteUrl
  -- If we have a remoteId, construct the URL from that
  elseif info.remoteId and info.remoteId ~= "" then
    -- remoteId might be the album ID - use it to construct URL
    url = "https://35px.com/albums/" .. info.remoteId
  -- If we have publishedCollection, try to get info from it
  elseif info.publishedCollection then
    local collectionInfo = info.publishedCollection:getCollectionInfoSummary()
    if collectionInfo.remoteUrl and collectionInfo.remoteUrl ~= "" then
      url = collectionInfo.remoteUrl
    elseif collectionInfo.remoteId and collectionInfo.remoteId ~= "" then
      url = "https://35px.com/albums/" .. collectionInfo.remoteId
    end
  end
  
  -- Fallback to albums page
  if not url then
    url = "https://35px.com/albums"
  end
  
  LrHttp.openUrlInBrowser(url)
end

function publishServiceProvider.goToPublishedPhoto(publishSettings, info)
  -- Try to get the photo URL
  local url = nil
  
  if info.remoteUrl and info.remoteUrl ~= "" then
    url = info.remoteUrl
  elseif info.remoteId and info.remoteId ~= "" then
    -- remoteId is the photo ID - link to the photo page
    url = "https://35px.com/photos/" .. info.remoteId
  end
  
  -- Fallback to albums page
  if not url then
    url = "https://35px.com/albums"
  end
  
  LrHttp.openUrlInBrowser(url)
end

--------------------------------------------------------------------------------

return publishServiceProvider

