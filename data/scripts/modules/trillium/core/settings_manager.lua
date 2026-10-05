--[[
Created by Max Mraz, licensed MIT

Manages overall quest settings: reads and writes to the "settings.dat" file in the quest write directory.

Usage:
- When starting the program (on sol.main.on_started perhaps), run
  settings.load()
- When closing the program, changing settings, call:
  settings.save()
- To get/set values:
  settings.get_value(key)
  settings.set_value(key, value)

NOTES:
- Don't call sol.main.load_settings() or sol.main.save_settings() with this system! They conflict!

--]]

local manager = {}
local settings = {}

local SETTINGS_FILE = "settings.dat"

--Engine-managed attributes that are saved to the settings file don't use this system
--Therefore, we have to adapt when reading / writing these
local ENGINE_SETTINGS_DEFAULTS = {
  fullscreen = true,
	sound_volume = 40,
	music_volume = 40,
	language = nil,
	joypad_enabled = true,
}

local ENGINE_GETTERS = {
  fullscreen = sol.video.is_fullscreen,
  sound_volume = sol.audio.get_sound_volume,
  music_volume = sol.audio.get_music_volume,
  joypad_enabled = sol.input.is_joypad_enabled,
  language = sol.language.get_language
}

local ENGINE_SETTERS = {
  fullscreen = sol.video.set_fullscreen,
  sound_volume = sol.audio.set_sound_volume,
  music_volume = sol.audio.set_music_volume,
  joypad_enabled = sol.input.set_joypad_enabled,
  language = sol.language.set_language
}

local ENGINE_SETTINGS_KEYS = {}
for k, _ in pairs(ENGINE_GETTERS) do ENGINE_SETTINGS_KEYS[k]=true end --lookup to check if a key is an engine setting

local function is_valid_key(key)
  local match = key:match("^%a[%w_]*$")
  return match ~= nil
end


--Load a settings file.
function manager.load(overwrite_path)
  local path = overwrite_path or SETTINGS_FILE
  settings = {} --clear existing settings
  if sol.file.exists(path) then
    --Read file in the data table:
		local env = setmetatable({}, {__newindex = function(self, key, value)
        local t = type(value) --check the key's type to make sure it's valid before we try and load it
        if t == "string" or t == "boolean" or t == "number" or t == "nil" then
          settings[key] = value
        end
    end})
    local chunk = sol.main.load_file(path)
		setfenv(chunk, env)
		chunk()
  else
    --Set defaults into data table:
    for k, v in pairs(ENGINE_SETTINGS_DEFAULTS) do
      settings[k] = v
    end
  end
  --Apply engine-managed settings:
  for k, engine_setter in pairs(ENGINE_SETTERS) do
    local v = settings[k]
    if v ~= nil then engine_setter(v) end
  end
end


--Save the value of current settings to the settings file.
function manager.save(overwrite_path)
  local path = overwrite_path or SETTINGS_FILE
  --Get the current value of engine-managed settings:
  for k, engine_getter in pairs(ENGINE_GETTERS) do
    settings[k] = engine_getter()
  end
  local file = sol.file.open(path, "w")
  for k, v in pairs(settings) do
		if type(v)=="string" then
			v = string.format("%q", v) --add quotes and escape characters to string
		else v = tostring(v) end
		file:write(string.format("%s = %s\n", k, v))
  end
  file:close()
end


--Returns the value of a setting in the settings file.
function manager.get_value(key)
  assert(not ENGINE_SETTINGS_KEYS[key], "Do not use settings script to get value for '" .. key .. "', this setting is managed by the engine. Use the API to check this.")
  return settings[key]
end


--Set the value of a setting in the settings file. This should not be used for engine-managed settings.
--Note: settings_manager.save() must be called to write current settings to file.
function manager.set_value(key, value)
  assert(is_valid_key(key), "Invalid key '" .. key .. "', you can't call a setting that")
  assert(not ENGINE_SETTINGS_KEYS[key], "Do not use settings script to set value for '" .. key .. "', this setting is managed by the engine. Use the API to set this.")
  settings[key] = value
end


return manager
