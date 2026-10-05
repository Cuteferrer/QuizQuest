--[[
Created by Max Mraz, licensed MIT

Set up some music config per map

You can set them in one of two ways:
1) Reference a music preset in a config file
map.music_config = "id_of_preset"
    --This is a key for a music preset in scripts/modules/trillium/sounds/music_presets
    --This is the preferred way, since the system can refrain from restarting musics if two maps share a preset

2) Put the music config table right onto the map
map.music_config = {
  default = {
    "north_village_theme",
    "cold_wind",
  },
  exploration = {
    "north_village_calm",
  },
  battle = {
    "north_village_percussion",
  },
}
    --This is useful for testing, but if you do this in the game,
    --then there's no way for the system to tell if a newly-loaded map's config matched the previous map's config.
    --This means the musics will all restart from the beginning

Music config objects are a table with three music type categories:
default: always plays
exploration: starts playing when map loads
battle: starts playing as well, but at 0 volume

This script will start the default and exploration musics when a map loads.
Entering battle with enemies can crossfade to the battle music instead of the exploration music, but this is handled in another script

NOTE: Any arbitrary music categories can be added to the music config, and then activated/deactivated with map:set_music_type_active("category_id", true | false)

--------------------------
-- API Functions --
--------------------------

map:set_music_type_active(music_type: string, is_active: boolean)
    - Fades in/out this music type


music:fade_in(speed: number)
music:fade_out(speed: number)
    - Fades a music object in/out. Speed should be a number between 1 - 100. Speed of 100 is instant fade, speed of 1 is almost 10 seconds of fade.

--]]

local manager = {}

local music_presets = require("scripts/modules/trillium/sound/music_presets")
local map_meta = sol.main.get_metatable"map"
local music_meta = sol.main.get_metatable"map"



--Add additional functions to sol.music
function sol.music.crossfade(a, b, speed)
  assert(sol.main.get_type(a) == "music" and sol.main.get_type(b) == "music", "Must pass two music objects to sol.music.crossfade(music_a, music_b)")
  assert(type(speed) == "number" and speed <= 100 and speed > 0, "Must pass a number between 1 and 100 to sol.music.crossfade(music_a, music_b, speed)")
  local freq = 100 - speed
  --TODO
  error("This function is not implemented yet")
end


function music_meta:fade_in(speed)
  local music = self
  assert(type(speed) == "number" and speed <= 100 and speed > 0, "Must pass a number between 1 and 100 to sol.music.crossfade(music_a, music_b, speed)")
  local freq = 100 - speed

  music:set_volume(0)
  sol.timer.start(sol.main, freq, function()
    local v = music:get_volume()
    v = v + 1
    music:set_volume(math.min(v, 100))
    if v < 100 then return freq end
  end)
end

function music_meta:fade_out(speed)
  local music = self
  assert(type(speed) == "number" and speed <= 100 and speed > 0, "Must pass a number between 1 and 100 to sol.music.crossfade(music_a, music_b, speed)")
  local freq = 100 - speed

  music:set_volume(100)
  sol.timer.start(sol.main, freq, function()
    local v = music:get_volume()
    v = v - 1
    music:set_volume(math.max(v, 0))
    if v > 0 then return freq end
  end)
end



map_meta:register_event("on_started", function(map)
  --ENGINE BUG: don't call this init function yet, sol.music.create() crashes the engine right now lolololol
  --manager.init_map_music_config(map)
end)



function manager.init_map_music_config(map)
  local game = map:get_game()
  local map_music_id = map:get_music()

  local music_config
  if type(map.music_config) == "string" then
    game.last_map_music_config_preset = map.music_config
    music_config = music_presets[map.music_config]
  else
    music_config = map.music_config
  end

  --TODO: use "game.last_map_music_config_preset" to not re-start music if the previous map had the same preset

  if map_music_id == "same" then
    --Special <Same as before> option in the map editor
    --I guess do nothing, so we don't restart all the music
    return
  elseif map_music_id == "nil" and not music_config then
    --Map doesn't specify a track or a config, we assume this map is supposed to be silent:
    sol.audio.stop_music()
  end

  if not music_config then
    --map didn't set anything, if we have a music ID set in the editor, use that as the default music
    music_config = {
      default_musics = { map_music_id }
    }
  end
  sol.audio.stop_music()

  --Start all musics at zero volume:
  map.music_objects = {}
  for category, music_ids in pairs(music_config) do
    map.music_objects[category] = {}
    for _, music_id in pairs(music_ids) do
      map.music_objects[category][music_id] = sol.music.create(music_id)
      map.music_objects[category][music_id]:set_volume(0)
      map.music_objects[category][music_id]:play()
    end
  end

  map:set_music_type_active("default", true)
  map:set_music_type_active("exploration", true)

end



function map_meta:set_music_type_active(music_category, is_active)
  local map = self

  for _, music in pairs(map.music_objects[music_category]) do
    if is_active then
      music:fade_in()
    else
      music:fade_out()
    end
  end
end



return manager
