--[[----------------------------------------------------------------------------
35px Lightroom Publish Service Plugin
35pxJSON.lua - Minimal JSON encoder/decoder

Copyright (c) 2025-2026 35px. MIT License.
Based on public domain JSON parsing code.
------------------------------------------------------------------------------]]

local JSON = {}

--------------------------------------------------------------------------------
-- Encoder
--------------------------------------------------------------------------------

local function encodeValue(value)
  local valueType = type(value)
  
  if value == nil then
    return "null"
  elseif valueType == "boolean" then
    return value and "true" or "false"
  elseif valueType == "number" then
    if value ~= value then -- NaN
      return "null"
    elseif value == math.huge or value == -math.huge then
      return "null"
    else
      return tostring(value)
    end
  elseif valueType == "string" then
    -- Escape special characters
    local escaped = value:gsub('\\', '\\\\')
                         :gsub('"', '\\"')
                         :gsub('\n', '\\n')
                         :gsub('\r', '\\r')
                         :gsub('\t', '\\t')
    return '"' .. escaped .. '"'
  elseif valueType == "table" then
    local isArray = true
    local maxIndex = 0
    
    for k, v in pairs(value) do
      if type(k) ~= "number" or k <= 0 or math.floor(k) ~= k then
        isArray = false
        break
      end
      if k > maxIndex then
        maxIndex = k
      end
    end
    
    if isArray and maxIndex > 0 then
      -- Encode as array
      local parts = {}
      for i = 1, maxIndex do
        parts[i] = encodeValue(value[i])
      end
      return "[" .. table.concat(parts, ",") .. "]"
    else
      -- Encode as object
      local parts = {}
      for k, v in pairs(value) do
        local key = type(k) == "string" and k or tostring(k)
        table.insert(parts, encodeValue(key) .. ":" .. encodeValue(v))
      end
      return "{" .. table.concat(parts, ",") .. "}"
    end
  else
    error("Cannot encode value of type: " .. valueType)
  end
end

function JSON.encode(value)
  return encodeValue(value)
end

--------------------------------------------------------------------------------
-- Decoder
--------------------------------------------------------------------------------

local function skipWhitespace(str, pos)
  while pos <= #str do
    local c = str:sub(pos, pos)
    if c ~= ' ' and c ~= '\t' and c ~= '\n' and c ~= '\r' then
      break
    end
    pos = pos + 1
  end
  return pos
end

local function decodeValue(str, pos)
  pos = skipWhitespace(str, pos)
  
  if pos > #str then
    error("Unexpected end of JSON")
  end
  
  local c = str:sub(pos, pos)
  
  -- String
  if c == '"' then
    local startPos = pos + 1
    local endPos = startPos
    local result = {}
    
    while endPos <= #str do
      local char = str:sub(endPos, endPos)
      if char == '\\' then
        local nextChar = str:sub(endPos + 1, endPos + 1)
        if nextChar == '"' then
          table.insert(result, '"')
        elseif nextChar == '\\' then
          table.insert(result, '\\')
        elseif nextChar == 'n' then
          table.insert(result, '\n')
        elseif nextChar == 'r' then
          table.insert(result, '\r')
        elseif nextChar == 't' then
          table.insert(result, '\t')
        elseif nextChar == 'u' then
          -- Unicode escape (simplified - just skip for now)
          local hex = str:sub(endPos + 2, endPos + 5)
          local codepoint = tonumber(hex, 16)
          if codepoint and codepoint < 128 then
            table.insert(result, string.char(codepoint))
          else
            table.insert(result, '?') -- Placeholder for non-ASCII
          end
          endPos = endPos + 4
        else
          table.insert(result, nextChar)
        end
        endPos = endPos + 2
      elseif char == '"' then
        return table.concat(result), endPos + 1
      else
        table.insert(result, char)
        endPos = endPos + 1
      end
    end
    error("Unterminated string")
  end
  
  -- Number
  if c == '-' or (c >= '0' and c <= '9') then
    local endPos = pos
    while endPos <= #str do
      local char = str:sub(endPos, endPos)
      if char == '-' or char == '+' or char == '.' or char == 'e' or char == 'E' or
         (char >= '0' and char <= '9') then
        endPos = endPos + 1
      else
        break
      end
    end
    local numStr = str:sub(pos, endPos - 1)
    local num = tonumber(numStr)
    if not num then
      error("Invalid number: " .. numStr)
    end
    return num, endPos
  end
  
  -- Boolean/null
  if str:sub(pos, pos + 3) == "true" then
    return true, pos + 4
  elseif str:sub(pos, pos + 4) == "false" then
    return false, pos + 5
  elseif str:sub(pos, pos + 3) == "null" then
    return nil, pos + 4
  end
  
  -- Array
  if c == '[' then
    local result = {}
    pos = skipWhitespace(str, pos + 1)
    
    if str:sub(pos, pos) == ']' then
      return result, pos + 1
    end
    
    while true do
      local value
      value, pos = decodeValue(str, pos)
      table.insert(result, value)
      
      pos = skipWhitespace(str, pos)
      local next = str:sub(pos, pos)
      
      if next == ']' then
        return result, pos + 1
      elseif next == ',' then
        pos = pos + 1
      else
        error("Expected ',' or ']' in array")
      end
    end
  end
  
  -- Object
  if c == '{' then
    local result = {}
    pos = skipWhitespace(str, pos + 1)
    
    if str:sub(pos, pos) == '}' then
      return result, pos + 1
    end
    
    while true do
      -- Key
      pos = skipWhitespace(str, pos)
      if str:sub(pos, pos) ~= '"' then
        error("Expected string key in object")
      end
      
      local key
      key, pos = decodeValue(str, pos)
      
      -- Colon
      pos = skipWhitespace(str, pos)
      if str:sub(pos, pos) ~= ':' then
        error("Expected ':' after object key")
      end
      pos = pos + 1
      
      -- Value
      local value
      value, pos = decodeValue(str, pos)
      result[key] = value
      
      -- Next
      pos = skipWhitespace(str, pos)
      local next = str:sub(pos, pos)
      
      if next == '}' then
        return result, pos + 1
      elseif next == ',' then
        pos = pos + 1
      else
        error("Expected ',' or '}' in object")
      end
    end
  end
  
  error("Unexpected character: " .. c)
end

function JSON.decode(str)
  if not str or str == "" then
    return nil
  end
  
  local value, pos = decodeValue(str, 1)
  return value
end

--------------------------------------------------------------------------------

return JSON

