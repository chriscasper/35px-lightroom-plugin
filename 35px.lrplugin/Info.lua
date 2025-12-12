--[[----------------------------------------------------------------------------
35px Lightroom Publish Service Plugin
Info.lua - Plugin manifest and metadata

Copyright (c) 2025-2026 35px. MIT License.
------------------------------------------------------------------------------]]

return {
  LrSdkVersion = 9.0,
  LrSdkMinimumVersion = 9.0,

  LrToolkitIdentifier = 'com.35px.lightroom.publish',
  LrPluginName = "35px",
  LrPluginInfoUrl = "https://35px.com/lightroom",

  -- Publish Service Provider
  LrPublishServiceProvider = {
    title = "35px",
    supportsIncrementalPublish = 'only',
    
    -- Plugin icons
    small_icon = 'icon-small.png',
    large_icon = 'icon-large.png',
    
    -- Export/Publish settings
    exportPresetFields = {
      { key = 'apiKey', default = '' },
      { key = 'apiKeyName', default = '' },
      { key = 'defaultAlbumId', default = '' },
      { key = 'defaultAlbumName', default = '' },
      { key = 'includeCaption', default = true },
      { key = 'jpegQuality', default = 95 },
      { key = 'resizeMaxDimension', default = 0 }, -- 0 = no resize
    },
    
    -- Service definition module
    requires = {
      LrDialogs = true,
      LrHttp = true,
      LrPathUtils = true,
      LrFileUtils = true,
      LrTasks = true,
      LrProgressScope = true,
      LrErrors = true,
      LrDate = true,
      LrStringUtils = true,
    },
  },

  -- Export Service Provider (for one-off exports)
  LrExportServiceProvider = {
    title = "35px Album",
    file = '35pxPublishService.lua',
    builtInPresetsDir = 'presets',
  },

  -- Library menu items
  LrLibraryMenuItems = {
    {
      title = "Configure 35px API Key...",
      file = "35pxMenuItems.lua",
      enabledWhen = "anytime",
    },
  },

  VERSION = { major = 1, minor = 0, revision = 0, build = 1 },
}

