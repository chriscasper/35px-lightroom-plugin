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
  API.setApiKey(publishSettings.apiKey)
  
  local album, err = API.createAlbum(info.name, "", "private")
  
  if err then
    LrErrors.throwUserError("Failed to create album: " .. err)
  end
  
  return {
    remoteId = album.id,
    remoteUrl = "https://35px.com/albums/" .. album.slug,
    name = album.title,
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
  
  -- Get the album ID from the collection
  local collectionInfo = publishedCollection:getCollectionInfoSummary()
  local albumId = collectionInfo.remoteId
  
  if not albumId then
    LrErrors.throwUserError("This collection is not linked to a 35px album. Please recreate it.")
  end
  
  -- Set up API
  API.setApiKey(exportSettings.apiKey)
  
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
  if info.remoteUrl then
    LrHttp.openUrlInBrowser(info.remoteUrl)
  else
    LrHttp.openUrlInBrowser("https://35px.com/albums")
  end
end

function publishServiceProvider.goToPublishedPhoto(publishSettings, info)
  if info.remoteUrl then
    LrHttp.openUrlInBrowser(info.remoteUrl)
  else
    LrHttp.openUrlInBrowser("https://35px.com/albums")
  end
end

--------------------------------------------------------------------------------

return publishServiceProvider

