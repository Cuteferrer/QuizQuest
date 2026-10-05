--[[
Uses the serpent lua serializer to allow read/write of tables to the savegame file
--]]

local game_metatable = sol.main.get_metatable("game")
local serpent = sol.serpent_serializer

function game_metatable:set_table_value(key, table)
  local t = serpent.dump(table)
  t = string.gsub(t, '"', '\\"') --escape quotation marks
  self:set_value(key, t)
end

function game_metatable:get_table_value(key)
  local value = self:get_value(key)
  if value == nil then return nil end
  value = value:gsub('\\"', '"')
  local ok, t = serpent.load(value)
  if ok then
    return t
  else
    error("Failed to load table by key: '" .. key .. "', possible error is trying to save a table with functions as values")
  end
end
