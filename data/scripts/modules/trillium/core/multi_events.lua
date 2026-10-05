--[[
Multi Events
Adapted from script by Splyth and Shargon: https://gitlab.com/Splyth/solarus-mit-starter-quest/-/blob/master/data/project_db.dat
By Max Mraz, licensed MIT


Allows you to write multiple callbacks for game events. Require this script (probably first thing in main.lua)
Usage:
game:register_event("on_started", some_function)
game:register_event("on_started", some_other_function)

Both will be called when the game starts.

This is activated for all solarus objects when you require this script, but if you want to call it on a normal table (like a menu)
you need to enable it for that table:
multievents:enable(some_table)
--]]

local multievents = {}

--We keep a list of what events have already been registered for an object
--Then we can throw an error if we would accidentally overwrite a registered event
--rawget/set are used to avoid triggering metamethods

local function get_registered_events(object)
  return sol.main.rawget(object,"_registered_events") or {}
end

local function set_registered_events(object, registered_events)
  assert(type(registered_events) == "table" or type(registered_events) == "nil", "Can only set registered events to be a table or nil")
  sol.main.rawset(object, "_registered_events", registered_events)
end

local function set_registered_event(object, event_name, is_registered)
  local registered_events = get_registered_events(object)
  registered_events[event_name] = is_registered
  set_registered_events(object, registered_events)
end


--This is the main thing: a function wrapper that will add the callback to the list of callbacks to call when triggered
--Event names are strings
local function register_event(object, event_name, callback)
  --Clear this event off the list of previously registered events, so we don't trigger the __newindex metamethod when we define it
  set_registered_event(object, event_name, false)

  --Define the event with all its previous callbacks
  local previous_callbacks = object[event_name] or function() end
  object[event_name] = function(...)
    return previous_callbacks(...) or callback(...)
  end
  
  --Mark this event as registered on this object's list of registered events
  --Put this event on a list so we can check if we've already registered it
  set_registered_event(object, event_name, true)
end


--Enable the multievents functionality for an object
--You can do tables or solarus userdata
function multievents:enable(object)
  object.register_event = register_event

  --Add a check to warn you if you would overwrite a registered event by defining it directly on the table:
  local what_do = object.__newindex or rawset --save the object's default behavior when being indexed upon or whatever
  function object.__newindex(t, k, v)
    --When adding a new index to a table, check if that table already has that index as a registered event:
    if get_registered_events(t)[k] then
      error("You are trying to define event '" .. k .. "' that was previously registered using register_event")
    else
      --If there was already a __newindex defined before event registration, we do that (unlikely)
      --Otherwise let the value get set like normal (we use rawset rather than just t[k]=v because we'd get stuck in a loop)
      what_do(t, k, v)
    end
  end
end


--Enable multievents on the metatables of all Solarus userdata types:
local solarus_userdata_types = {
  "arrow",
  "block",
  "bomb",
  "boomerang",
  "carried_object",
  "camera",
  "chest",
  "circle_movement",
  "crystal",
  "crystal_block",
  "custom_entity",
  "destination",
  "destructible",
  "door",
  "dynamic_tile",
  "enemy",
  "explosion",
  "fire",
  "game",
  "hero",
  "hookshot",
  "item",
  "jumper",
  "jump_movement",
  "map",
  "movement",
  "npc",
  "path_finding_movement",
  "path_movement",
  "pickable",
  "pixel_movement",
  "random_movement",
  "random_path_movement",
  "sensor",
  "separator",
  "shop_treasure",
  "sprite",
  "stairs",
  "state",
  "stream",
  "straight_movement",
  "surface",
  "switch",
  "target_movement",
  "teletransporter",
  "text_surface",
  "timer",
  "wall"
}

for _, sudt in ipairs(solarus_userdata_types) do
  local mt = sol.main.get_metatable(sudt)
  if mt ~= nil then
    multievents:enable(mt)
  else
    error("Trying to enable multievents for userdata type '" .. sudt .. "', but no metatable found")
  end
end

--Also enable sol.main
multievents:enable(sol.main)



return multievents
