--[[
Created by Max Mraz, licensed MIT

Usage:

game:set_quest_phase("my_quest", 1)
  - sets quest "my_quest" to given phase. Right now, quests can only be one phase.

game:complete_quest("my_quest")
  - sets quest "my_quest" to completed status

Adding a new quest:
- Open scripts/menus/quest_log/quests - add a quest_id for your new quest, as either a main quest or a side quest
- Create a string and dialog at [dialogs|strings].quest_log.quest_id
- The quest will appear in the log when you set game:set_quest_phase(quest_id, number)
- The quest will appear but be grey-ed out as completed after you've called game:complete_quest(quest_id)
--]]

local quest_ids = require("scripts/modules/trillium_config/world_data/logged_quests")
require("scripts/modules/trillium/quest_log/quest_log_hud_notification") --init notification icon
local game_meta = sol.main.get_metatable"game"


--Internal Getters/Setters:
local function get_quest_string(quest_id)
  return "quest_log_" .. quest_id
end

local function get_quest_state(quest_id)
  return sol.main.get_game():get_value(get_quest_string(quest_id) .. "_state")
end

local function set_quest_state(quest_id, phase)
  return sol.main.get_game():set_value(get_quest_string(quest_id) .. "_state", phase)
end

local function get_last_updated(quest_id)
  return sol.main.get_game():get_value(get_quest_string(quest_id) .. "_last_updated")
end

local function set_last_updated(quest_id)
  local game = sol.main.get_game()
  return game:set_value(get_quest_string(quest_id) .. "_last_updated", game:get_playtime())
end



function game_meta:get_quest_phase(quest_id)
  return get_quest_state(quest_id)
end


function game_meta:set_quest_phase(quest_id, phase)
  local current_state = get_quest_state(quest_id) or 0
  if current_state == "completed" then return end --already complete
  if current_state == phase then return end --can't set it to what it already is
  set_quest_state(quest_id, math.max(phase, current_state)) --prevent lowering quest phase
  set_last_updated(quest_id)
  self:show_quest_log_icon()
  sol.audio.play_sound("quest_log_update")
end


function game_meta:complete_quest(quest_id)
  local current_state = get_quest_state(quest_id)
  if current_state == "completed" then return end --already complete
  set_quest_state(quest_id, "completed")
  set_last_updated(quest_id)
  self:show_quest_log_icon()
  sol.audio.play_sound("quest_log_update")
end


function game_meta:get_active_quests()
  local active_quests = {
    ["main"] = {},
    ["main_completed"] = {},
    ["side"] = {},
    ["side_completed"] = {},
  }
  --Check main quests
  for _, qid in pairs(quest_ids["main"]) do
    local state = get_quest_state(qid)
    if state then
      local quest_dto = {
        id = qid,
        last_updated = get_last_updated(qid),
        state = state,
      }
      table.insert(active_quests[state == "completed" and "main_completed" or "main"], quest_dto)
    end
  end
  --Check side quests
  for _, qid in pairs(quest_ids["side"]) do
    local state = get_quest_state(qid)
    if state then
      local quest_dto = {
        id = qid,
        last_updated = get_last_updated(qid),
        state = state,
      }
      table.insert(active_quests[state == "completed" and "side_completed" or "side"], quest_dto)
    end
  end

  --Sorting
  local function sort_by_time(qa, qb)
    return qa.last_updated > qb.last_updated
  end
  table.sort(active_quests.main, sort_by_time)
  table.sort(active_quests.main_completed, sort_by_time)
  table.sort(active_quests.side, sort_by_time)
  table.sort(active_quests.side_completed, sort_by_time)

  return active_quests
end


function game_meta:unlock_all_quests()
  for _, quest_type in pairs(quest_ids) do
    for _, id in pairs(quest_type) do
      self:set_quest_phase(id, 1)
    end
  end
end


