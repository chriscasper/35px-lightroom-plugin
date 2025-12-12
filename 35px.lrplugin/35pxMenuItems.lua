--[[----------------------------------------------------------------------------
35px Lightroom Publish Service Plugin
35pxMenuItems.lua - Library menu items

Copyright (c) 2025-2026 35px. MIT License.
------------------------------------------------------------------------------]]

local LrDialogs = import 'LrDialogs'
local LrView = import 'LrView'
local LrBinding = import 'LrBinding'
local LrFunctionContext = import 'LrFunctionContext'
local LrTasks = import 'LrTasks'
local LrHttp = import 'LrHttp'
local LrColor = import 'LrColor'

local API = require '35pxAPI'

--------------------------------------------------------------------------------
-- Configure API Key Dialog
--------------------------------------------------------------------------------

local function showConfigureApiKeyDialog()
  LrFunctionContext.callWithContext("configureApiKey", function(context)
    local f = LrView.osFactory()
    
    local properties = LrBinding.makePropertyTable(context)
    properties.apiKey = API.getApiKey() or ""
    properties.status = ""
    properties.statusColor = LrColor(0.5, 0.5, 0.5)
    
    local contents = f:column {
      spacing = f:control_spacing(),
      bind_to_object = properties,
      
      f:row {
        f:static_text {
          title = "Enter your 35px API key below.",
          fill_horizontal = 1,
        },
      },
      
      f:row {
        f:static_text {
          title = "You can generate an API key at:",
          fill_horizontal = 1,
        },
      },
      
      f:row {
        f:push_button {
          title = "Open 35px Settings →",
          action = function()
            LrHttp.openUrlInBrowser("https://35px.com/profile/settings/api")
          end,
        },
      },
      
      f:separator { fill_horizontal = 1 },
      
      f:row {
        spacing = f:label_spacing(),
        
        f:static_text {
          title = "API Key:",
          alignment = 'right',
          width = 80,
        },
        
        f:edit_field {
          value = LrView.bind 'apiKey',
          width_in_chars = 50,
          immediate = true,
        },
      },
      
      f:row {
        spacing = f:label_spacing(),
        
        f:static_text {
          title = "",
          width = 80,
        },
        
        f:push_button {
          title = "Verify Key",
          action = function()
            LrTasks.startAsyncTask(function()
              local key = properties.apiKey
              if not key or key == "" then
                properties.status = "Please enter an API key"
                properties.statusColor = LrColor(0.8, 0, 0)
                return
              end
              
              properties.status = "Verifying..."
              properties.statusColor = LrColor(0.5, 0.5, 0.5)
              
              local valid, userOrError = API.verifyApiKey(key)
              
              if valid then
                properties.status = "✓ Connected as: " .. (userOrError.username or "Unknown")
                properties.statusColor = LrColor(0, 0.6, 0)
              else
                properties.status = "✗ " .. (userOrError or "Invalid API key")
                properties.statusColor = LrColor(0.8, 0, 0)
              end
            end)
          end,
        },
        
        f:static_text {
          title = LrView.bind 'status',
          text_color = LrView.bind 'statusColor',
          fill_horizontal = 1,
        },
      },
      
      f:separator { fill_horizontal = 1 },
      
      f:row {
        f:static_text {
          title = "Note: Your API key is stored in your Lightroom catalog.",
          text_color = LrColor(0.5, 0.5, 0.5),
          fill_horizontal = 1,
        },
      },
    }
    
    local result = LrDialogs.presentModalDialog {
      title = "Configure 35px API Key",
      contents = contents,
      actionVerb = "Save",
    }
    
    if result == "ok" and properties.apiKey and properties.apiKey ~= "" then
      API.setApiKey(properties.apiKey)
      LrDialogs.message("API Key Saved", "Your 35px API key has been saved.")
    end
  end)
end

--------------------------------------------------------------------------------
-- Menu Item Entry Point
--------------------------------------------------------------------------------

showConfigureApiKeyDialog()

