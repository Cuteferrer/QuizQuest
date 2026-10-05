--[[
Created by Max Mraz, licensed MIT. But let's be honest, this is so basic you can't copyright it really.
Automatically regenerates magic over time
--]]

local default_magic_regen = require("scripts/modules/trillium_config/action/magic_regen_config")
local game_meta = sol.main.get_metatable"game"

local manager = {}
local rate = default_magic_regen.rate or 1000
local rate_multiplier = 1
local amount = default_magic_regen.amount or 1
local amount_multiplier = 1


game_meta:register_event("on_started", function(game)
  local timer = sol.timer.start(game, rate / rate_multiplier, function()
    game:add_magic(amount * amount_multiplier)
    return rate / (rate_multiplier or 1)
  end)
  timer:set_suspended_with_map(true)
end)

function game_meta:set_magic_regen_multiplier(rm, am)
  rate_multiplier = rm or rate_multiplier
  amount_multiplier = am or amount_multiplier
end

function game_meta:get_magic_regen_multiplier()
  return rate_multiplier, amount_multiplier
end

return manager