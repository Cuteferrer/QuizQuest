--[[
Created by Max Mraz, licensed MIT
--]]

local game_meta = sol.main.get_metatable"game"

function game_meta:rumble(lf_amount, hf_amount, duration)
  local game = self
  if sol.main.old_controls_version then return end -- solarus <= 1.6 doesn't support rumble
  local joypad = sol.controls.get_main_controls().joypad
  if not joypad then return end

  if game:get_value("option_disable_rumble") then return end --disable rumble option
  --Presets
  if type(lf_amount) == "string" then
    local preset = lf_amount
    if preset == "melee_hit" then
      lf_amount, hf_amount, duration = 0, .8, 100
    elseif preset == "hero_hurt" then
      lf_amount, hf_amount, duration = 0, 1, 400
    else
      error("Invalid rumble preset passed to game:rumble(preset)")
    end
  end

  if joypad:has_rumble() then
    joypad:rumble(lf_amount, hf_amount, duration)
  end
end
