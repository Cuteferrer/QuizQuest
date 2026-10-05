--[[
By Max Mraz, licensed MIT
Creates footstep sfx when walking.

Note: this doesn't take terrain into account in any way, sadly. No matter what you're walking on, safe SFX.
Would be great to improve this someday.
--]]

local manager = {}

local hero_meta = sol.main.get_metatable"hero"
local NUM_STEP_SFX = 10
--affected animations table maps an animation that should have the footstep sound
--to a table where the keys are frame numbers that should play the sfx
local affected_animations = {
  ["walking"] = {[0]=true, [4]=true},
  ["running"] = {[0]=true, [4]=true},
  ["running_2"] = {[0]=true, [4]=true},
}

--Create footstep sfx:
local footstep_sfx = {}
for i = 1, NUM_STEP_SFX do
  local step_no = string.format("%02d", i)
  footstep_sfx[i] = sol.sound.create("footsteps/step_" .. step_no)
end


hero_meta:register_event("on_created", function(hero)
  local sprite = hero:get_sprite()
  sprite:register_event("on_frame_changed", function(self, animation, frame)
    if affected_animations[animation] and (affected_animations[animation][frame]) then
      if hero:get_ground_below() == "traversable" then
        footstep_sfx[math.random(1, NUM_STEP_SFX)]:play()
      end
    end
  end)
end)

return manager