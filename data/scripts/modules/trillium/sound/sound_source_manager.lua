--[[
By Max Mraz, licensed MIT
Used by sound source entities.
They'll play sound effects but drop off as you get further from them.
--]]

local manager = {}

--Config:
local sound_update_frequency = 200

local sounds = {

  example = {
    length = 25000, --length of the sound loop
    falloff = 3, --how far the sound will carry. 3 is default. Equates to n * 100 pixels until sound is silent
    sound = "path/to/sound_id",
    max_volume = 80, --percent of top volume. Useful if some sounds shouldn't ever be their full file volume
  },

  ocean_waves = {
    length = 33000,
    falloff = 6,
    sound = "ambiance/waves_1",
  },

  waterfall = {
    length = 10000,
    falloff = 2,
    sound = "ambiance/waterfall_1",
  },

  waterfall_big = {
    length = 15000,
    falloff = 5,
    sound = "ambiance/waterfall_2",
  },

  fountain = {
    length = 10000,
    falloff = 2,
    sound = "ambiance/fountain",
    max_volume = 50,
  },

  wind_in_trees = {
    length = 30000,
    falloff = 3,
    sound = "ambiance/wind_in_trees",
    max_volume = 50,
  },

  creek = {
    length = 10000,
    falloff = 1.7,
    sound = "ambiance/creek_1",
    max_volume = 50,
  },

  fire = {
    length = 10000,
    falloff = 1.5,
    sound = "ambiance/fire_crackle",
    max_volume = 80,
  },

  whispers = {
    length = 10000,
    falloff = 1.7,
    sound = "ambiance/whispers",
    max_volume = 50,
  },

  saloon_piano = {
    length = 10650,
    falloff = 6,
    sound = "ambiance/pine_apple_rag_section_filtered",
    max_volume = 75,
  },

  far_away_monster_growls = {
    length = 24500,
    falloff = 6,
    sound = "enemies/far_away_monster_growls",
    max_volume = 75,
  },

  gearhouse = {
    length = 20000,
    falloff = 4,
    sound = "ambiance/gearhouse",
    max_volume = 75,
  },

}

----------------------------------------------


function manager.get_sounds()
  return sounds
end


function manager.init_map(map)
  if not map.sound_source_sounds then map.sound_source_sounds = {} end
  --Update all sound levels on map every few ms:
  sol.timer.start(map, sound_update_frequency, function()
    manager.set_ambient_sound_levels(map)
    return true
  end)

  map:register_event("on_finished", function()
    manager.stop_all_sounds(map)
  end)
end


--Called by sound sources to activate a certain sound_id for a map
--Will play a sound which changes level based on how close you are to the closest entity for that sound source
function manager.start_sound(map, sound_id)
  assert(sounds[sound_id], "There is no entry in the sounds table for this ID, did you make a new sound effect and forget to add the config in this script?")
  if not map.sound_source_sounds then map.sound_source_sounds = {} end
  if map.sound_source_sounds[sound_id] then return end --sound has already been started for this ID

  local sound_data = sounds[sound_id]

  --Get all sources of that sound id:
  local source_entities = {}
  for e in map:get_entities_by_type("custom_entity") do
              --if e:get_model() == "environment/sound_source" then print("Does match?", e:get_property"sound_id", ":", sound_id) end
    if e:get_model() == "environment/sound_source" and e:get_property("sound_id") == sound_id then
      table.insert(source_entities, e)
    end
  end

  map.sound_source_sounds[sound_id] = {
    id = sound_id,
    falloff = sound_data.falloff or 3,
    max_volume = sound_data.max_volume or 100,
    source_entities = source_entities,
    sfx = nil,
  }

  local sfx_repeat_timer = sol.timer.start(map, 0, function()
    if map.sound_source_sounds[sound_id].sfx then map.sound_source_sounds[sound_id].sfx:stop() end
    local sfx = manager.create_and_play_sound(sound_data.sound)
    map.sound_source_sounds[sound_id].sfx = sfx
    return sound_data.length --repeat as soon as the sfx is over
  end)
  sfx_repeat_timer:set_suspended_with_map(false)

  manager.set_ambient_sound_levels(map)
end


function manager.create_and_play_sound(id, volume)
  local sfx = sol.sound.create(id)
  sfx:set_volume(volume or 0)
  sfx:play()
  return sfx
end


local function get_closest_entity(map, entities)
  assert(entities[1], "Cannot pass an empty array to get closest entity from")
  local hero = map:get_hero()
  local closest = entities[1]
  for _, e in pairs(entities) do
    if e:get_distance(hero) < closest:get_distance(hero) and e:is_enabled() then
      closest = e
    end
  end
  return closest
end


function manager.set_ambient_sound_levels(map)
  --Adjusts levels of each SFX playing depending on hero distance
  for sound_id, sound_data in pairs(map.sound_source_sounds) do
    local closest_entity = get_closest_entity(map, sound_data.source_entities)
    local volume = manager.get_volume(closest_entity, map, sound_data.falloff)
    volume = volume * (sound_data.max_volume / 100) --cap as percent of max volume
    if not closest_entity:is_enabled() then volume = 0 end --check to make sure any entity is actually enabled
    sound_data.sfx:set_volume(volume)
  end
end



function manager.get_volume(entity, map, falloff_rate)
  falloff_rate = falloff_rate or 3
  local hero = map:get_hero() --TODO: should this be distance to the center of the camera instead of distance to the hero?
  local distance = entity:get_distance(hero)
  local max_volume = sol.audio.get_sound_volume()
  --local vol = max_volume * (100 - (distance / falloff_rate)) / 100 --for now, until API is changed to do volume as percent of max, rather than absolute
  local vol = 100 - (distance / falloff_rate) --can use this once API is fixed
  vol = math.max(vol, 0)
  return vol
end


function manager.stop_all_sounds(map)
  for sound_id, sound_data in pairs(map.sound_source_sounds) do
    sound_data.sfx:stop()
  end
end



return manager
