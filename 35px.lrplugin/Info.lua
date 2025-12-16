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

  -- Publish Service Provider - must reference the file containing the provider
  LrPublishServiceProvider = {
    title = "35px",
    file = '35pxPublishService.lua',
    
    -- Plugin icons
    small_icon = 'icon-small.png',
    large_icon = 'icon-large.png',
  },

  -- Export Service Provider (for one-off exports)
  LrExportServiceProvider = {
    title = "35px Album",
    file = '35pxPublishService.lua',
    
    -- Plugin icons
    small_icon = 'icon-small.png',
    large_icon = 'icon-large.png',
  },

  -- Library menu items
  LrLibraryMenuItems = {
    {
      title = "Configure 35px API Key...",
      file = "35pxMenuItems.lua",
    },
  },

  VERSION = { major = 1, minor = 0, revision = 0, build = 1 },
}

