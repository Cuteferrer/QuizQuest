-- Generic Ammo Tracking Utility

--[[ Copyright (C) 2021-2022 Cluedrew Kenfar Ink

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
--]]

-- This is a utility for making configurable items that can change how they
-- limit their use. This is intended for resource packs as items made for
-- particular quests can hard code their ammunition rules. Complex systems will
-- also need to be hand coded, but this can handle a power taking one arrow,
-- 5 magic points or 15 coins to fire.
--
-- Interface:
--
--   ammo_tracker.clear_ammo(object)
-- Removes any and all ammo functions and other additions to an object made
-- by set_ammo. The indexes are set to nil, there is no save/restore.
--
--   ammo_tracker.set_ammo(object, key)
-- Sets or removes the ammo functions from the object depending on the value
-- of the key. Object must always support indexing and key can be any of:
-- +   nil: Remove any ammo function on the object, as clear_ammo.
-- +   '_unlimited': Effectively don't use ammo. There is always as much as
--     possible and there will always be enough.
-- +   '_life': Use life as ammunition, using ammo will lower the hero's life.
--     Note they can always spend life including going down to or below 0 life.
-- +   '_safe_life': As _life but makes sure the hero always has 1 life left.
-- +   '_magic': Use the hero's magic as ammo.
-- +   '_money': Use the hero's money as ammo.
-- +   '_amount': Can only be used if the object is an item, which must be
--     given an amount variable before the functions are used. Ammo is
--     withdrawn from the item's amount.
-- +   Other String: Must be a valid savegame variable, uses that variable.
--
--   ammo_tracker.add_to_item_api()
-- Adds ammo_tracker.set_ammo to the item metatable (as set_ammo). It can be
-- used as a one point access for the ammo tracker.
--
-- Ammo Functions:
--
-- These are the functions that are added by module by something that wants
-- to track ammunition. The self parameter is always this object and amount,
-- when used, is a non-negative number representing an amount of ammunition;
-- it defaults to 1 in all cases.
--
--   self:get_ammo()
-- Return the current value of the ammo. Usually a non-negative integer.
--
--   self:remove_ammo([amount])
-- Remove that amount of ammo, down to zero ammo.
--
--   self:can_spend_ammo([amount])
-- Checks to see if that amount of ammo can be spend and returns true.
--
--   self:try_spend_ammo([amount])
-- As can_spend_ammo but the check passes it also removes (spends) the ammo.
--
-- Example:
--
-- local ammo_tracker = require("scripts/utility/ammo_tracker")
--
-- local item = ...
-- ammo_tracker.set_ammo(item, "_amount")
--
-- function item:on_using()
--     if self:try_spend_ammo() then
--         -- Use the item, ammo has already been deducted.
--     else
--         -- Show some out-of-ammo indicator.
--     end
-- end
--
-- If you want to add it to the item api add the following line to one of
-- your set-up files and then do the same but set_ammo is an item method.
--   `require("scripts/utility/ammo_tracker").add_to_item_api()`

local ammo_tracker = {}

function ammo_tracker.clear_ammo(object)
    object.get_ammo = nil
    object.remove_ammo = nil
    object.can_spend_ammo = nil
    object.try_spend_ammo = nil
end

-- All of these are helpers for set_ammo.
local clear_ammo = ammo_tracker.clear_ammo

local function unlimited_ammo(object)
    function object:get_ammo()
        return math.huge
    end
    function object:remove_ammo(amount)
        -- Does nothing.
    end
    function object:can_spend_ammo(amount)
        return true
    end
    function object:try_spend_ammo(amount)
        return true
    end
end

local function life_ammo(object)
    function object:get_ammo()
        return self:get_game():get_life()
    end
    function object:remove_ammo(amount)
        self:get_game():remove_life(amount or 1)
    end
    function object:can_spend_ammo(amount)
        return true
    end
    function object:try_spend_ammo(amount)
        self:get_game():remove_life(amount)
        return true
    end
end

local function safe_life_ammo(object)
    function object:get_ammo() return
        self:get_game():get_life()
    end
    function object:remove_ammo(amount)
        return self:get_game():remove_life()
    end
    function object:can_spend_ammo(amount)
        return (amount or 1) < self:get_game():get_life()
    end
    function object:try_spend_ammo(amount)
        amount = amount or 1
        local game = self:get_game()
        local can = amount < game:get_life()
        if can then game:remove_life(amount) end
        return can
    end
end

local function magic_ammo(object)
    function object:get_ammo()
        return self:get_game():get_magic()
    end
    function object:remove_ammo(amount)
        self:get_game():remove_magic(amount)
    end
    function object:can_spend_ammo(amount)
        return (amount or 1) <= self:get_game():get_magic()
    end
    function object:try_spend_ammo(amount)
        amount = amount or 1
        local game = self:get_game()
        local can = amount <= game:get_magic()
        if can then game:remove_magic(amount) end
        return can
    end
end

local function stamina_ammo(object)
    function object:get_ammo()
        return self:get_game():get_stamina()
    end
    function object:remove_ammo(amount)
        self:get_game():remove_stamina(amount)
    end
    function object:can_spend_ammo(amount)
        return self:get_game():get_stamina() > 0
    end
    function object:try_spend_ammo(amount)
        amount = amount or 1
        local game = self:get_game()
        local can = game:get_stamina() > 0
        if can then game:remove_stamina(amount) end
        return can
    end
end

local function bullets_ammo(object)
    function object:get_ammo()
        return self:get_game():get_bullets()
    end
    function object:remove_ammo(amount)
        self:get_game():remove_bullets(amount)
    end
    function object:can_spend_ammo(amount)
        return (amount or 1) <= self:get_game():get_bullets()
    end
    function object:try_spend_ammo(amount)
        amount = amount or 1
        local game = self:get_game()
        local can = amount <= game:get_bullets()
        if can then game:remove_bullets(amount) end
        return can
    end
end

local function money_ammo(object)
    function object:get_ammo()
        return self:get_game():get_money()
    end
    function object:remove_ammo(amount)
        self:get_game():remove_money(amount or 1)
    end
    function object:can_spend_ammo(amount)
        return (amount or 1) <= self:get_game():get_money()
    end
    function object:try_spend_ammo(amount)
        amount = amount or 1
        local game = self:get_game()
        local can = amount <= game:get_money()
        if can then game:remove_money(amount) end
        return can
    end
end

local function madness_ammo(object)
  function object:get_ammo()
    return math.huge
  end

  function object:remove_ammo(amount)
    local game = self:get_game()
    local hero = game:get_hero()
    local madness_cost_multiplier = game.madness_cost_multiplier or 1
    amount = math.floor(amount * madness_cost_multiplier)

    hero:build_up_status_effect("madness", amount)
  end

  function object:can_spend_ammo(amount)
    local game = self:get_game()
    local hero = game:get_hero()
    --If lingering madness is active, can't spend madness:
    if game:is_lingering_madness_active() then return false end
    local madness_cost_multiplier = game.madness_cost_multiplier or 1
    amount = math.floor(amount * madness_cost_multiplier)
    local is_mad = game:get_hero():is_status_effect_active("madness")
    local enough_sanity = hero:get_status_effect_buildup("madness") + (amount) < (game:get_value("status_resistance_madness") or 100)
    if is_mad then 
      return false 
    elseif game:get_value("spell_madness_safety") and not enough_sanity then
      return false
    else
      return true      
    end
  end

  function object:try_spend_ammo(amount)
    amount = amount or 1
    local game = self:get_game()
    local hero = game:get_hero()
    --If lingering madness is active, can't spend madness:
    if game:is_lingering_madness_active() then return false end
    local madness_cost_multiplier = game.madness_cost_multiplier or 1
    amount = math.floor(amount * madness_cost_multiplier)
    if hero:is_status_effect_active("madness") then return false end
    if not game:get_value("spell_madness_safety") then
      hero:build_up_status_effect("madness", amount)
      return true
    else
      local potential_amount = game:get_hero():get_status_effect_buildup("madness") + amount
      local is_over = potential_amount >= game:get_status_effect_resistance("madness")
      if is_over then return false end
      hero:build_up_status_effect("madness", amount)
      return true
    end
  end
end

local function amount_ammo(object)
    -- Has amount is not checked here, the functions themselves check it.
    if "item" ~= sol.main.get_type(object) then
        error('Amount ammo can only be added to an item.')
    end
    function object:get_ammo()
        return self:get_amount()
    end
    function object:remove_ammo(amount)
        self:remove_amount(amount or 1)
    end
    function object:can_spend_ammo(amount)
        return self:has_amount(amount or 1)
    end
    function object:try_spend_ammo(amount)
        amount = amount or 1
        local can = self:has_amount(amount)
        if can then self:remove_amount(amount) end
        return can
    end
end

local function savegame_ammo(object, savegame_variable)
    if not ("string" == type(savegame_variable)
            and savegame_variable:match"^%a[%w_]+$") then
        error('savegame_variable is not a properly formatted string.')
    end
    function object:get_ammo()
        return self:get_game():get_value(savegame_variable)
    end
    function object:remove_ammo(amount)
        amount = amount or 1
        local game = self:get_game()
        local current = game:get_value(savegame_variable)
        if current < amount then
            current = 0
        else
            current = current - amount
        end
        self:set_value(savegame_variable, current)
    end
    function object:can_spend_ammo(amount)
        return (amount or 1) <= self:get_ammo()
    end
    function object:try_spend_ammo(amount)
        amount = amount or 1
        local game = self:get_game()
        local current = game:get_value(savegame_variable)
        if current < amount then
            return false
        end
        self:set_value(savegame_variable, current - amount)
        return true
    end
end

function ammo_tracker.set_ammo(object, ammo)
    if nil == ammo then
        clear_ammo(object)
    elseif "_unlimited" == ammo then
        unlimited_ammo(object)
    elseif "_life" == ammo then
        life_ammo(object)
    elseif "_safe_life" == ammo then
        safe_life_ammo(object)
    elseif "_magic" == ammo then
        magic_ammo(object)
    elseif "_bullets" == ammo then
        bullets_ammo(object)
    elseif "_amount" == ammo then
        amount_ammo(object)
    elseif "_madness" == ammo then
        madness_ammo(object)
    elseif "_stamina" == ammo then
        stamina_ammo(object)
    else
        savegame_ammo(object, ammo)
    end
end

function ammo_tracker.add_to_item_api()
    local item_meta = sol.main.get_metatable("item")
    item_meta.set_ammo = ammo_tracker.set_ammo
end

return ammo_tracker