--[[
Configuration for dash / roll
Note: Many of these values are arrays
In these cases, each value corresponds to the property at a given "dash level"
So for example, dash_distances = {48, 64} means that dash level 1 will do 48px, but dash level 2 will go 64

Dash level is set with: game:get_dash_level() / game:set_dash_level(lvl)
--]]

return {
  dash_distances = {72, 96},
  dash_speeds = {300, 400},
  dash_animations = {"roll", "dash"},
  dash_sounds = {
    {"dash_1", "dash_2","dash_3", "dash_4"},
    {"dash_1", "dash_2","dash_3", "dash_4"},
  },
  invincibility_lengths = {200, 900},
  minimum_distance = 30, --after this distance, the dash will stop before you hit water, a hole, etc
  bad_ground_lookahead = 6, --how far ahead of your movement to check for holes, water, etc
  recovery_length = 200, --how long the "dash recovery" state lasts
  dash_cooldown_time = 200, --time between allowing to dash again. Overlaps with dash cooldown length.
  can_cross_hole = {false, true}, --determines whether it's possible to dash over a hole for platforming
}
