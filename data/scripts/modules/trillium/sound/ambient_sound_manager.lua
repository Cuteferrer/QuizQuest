--[[
Created by Max Mraz, licensed MIT
A script to allow ambient sounds to occur on a map. For example, bird calls or wind blowing
Usage: call map:start_ambient_sound(id)
--]]

local manager = {}
local map_meta = sol.main.get_metatable("map")

local soundsets = {

  gulls = {
    sounds = {
      "ambiance/seagull_01",
      "ambiance/seagull_02",
      "ambiance/seagull_03",
      "ambiance/seagull_04",
      "ambiance/seagull_05",
      "ambiance/seagull_06",
      "ambiance/seagull_07",
      "ambiance/seagull_08",
      "ambiance/seagull_09",
    },
    volume_min = 20,
    volume_max = 50,
    frequency_min = 500,
    frequency_max = 5000,
  },

  cave_drip = {
    sounds = {
      "ambiance/cave_drip_01",
      "ambiance/cave_drip_02",
      "ambiance/cave_drip_03",
    },
    volume_min = 20,
    volume_max = 70,
    frequency_min = 100,
    frequency_max = 8000,
  },

  cold_wind = {
    sounds = {"ambiance/wind"},
    volume_min = 40,
    volume_max = 45,
    length = 61000,
  },

  wind = {
    sounds = {"ambiance/wind"},
    volume_min = 16,
    volume_max = 30,
    length = 61000,
  },

  wind_in_trees = {
    sounds = {"ambiance/wind_in_trees"},
    volume_min = 86,
    volume_max = 99,
    length = 28000,
  },
}


local function get_delay(soundset, first_play)
  if (soundset.frequency_min and soundset.frequency_max) then
    return math.random(soundset.frequency_min, soundset.frequency_max)
  elseif soundset.length then
    return first_play and 0 or soundset.length
  else
     error("Soundset is missing either property 'frequency_min' or 'frequency_max' (for intermittent sounds) or property 'length' (for constant sounds)")
  end
end



function map_meta:start_ambient_sound(sound_id)
  local map = self
  if not map.ambient_sounds then map.ambient_sounds = {} end
  local soundset = soundsets[sound_id]
  local start_delay = get_delay(soundset, true)

  local am_sfx_timer = sol.timer.start(map, start_delay, function()
    local sfx = sol.sound.create(soundset.sounds[math.random(1, #soundset.sounds)])
    local vol = math.random(soundset.volume_min, soundset.volume_max)
    vol = sol.audio.get_sound_volume() * (vol / 100)
    sfx:set_volume(vol)
    sfx:play()
    map.ambient_sounds[sound_id] = sfx
    return get_delay(soundset)
  end)
  am_sfx_timer:set_suspended_with_map(false)
end


map_meta:register_event("on_finished", function(map)
  if map.ambient_sounds then
    for _, sfx in pairs(map.ambient_sounds) do
      sfx:stop()
    end
  end
end)



return manager
