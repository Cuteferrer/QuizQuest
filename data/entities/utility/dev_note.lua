local entity = ...
local game = entity:get_game()
local map = entity:get_map()

local menu = {}

function entity:on_created()
  --Do not let this exist if debug mode isn't on:
  if not sol.main.debug_mode then
    entity:remove()
    return
  end

  entity:set_drawn_in_y_order(true)
  entity:set_traversable_by("hero", function(entity, hero)
    return hero:overlaps(entity)
  end)
end


function entity:on_interaction()

  menu.text = entity:get_property("note") or "ERROR: Dev Note entities need a field called 'note' to display text, you fool"

  sol.timer.start(map, 10, function()
    sol.menu.start(map, menu)
  end)
end





local width, height = 384, 96
local bg_surface = sol.surface.create(width, height)
bg_surface:fill_color{0,0,0,100}
local textbox = sol.surface.create(width, height)


function menu:on_started()
  local char_limit = 50 --next space after this many characters will create a new line

  --Clear textbox:
  textbox:clear()

  --Build lines:
  local lines = {}
  local i = 0
  local substr = ""
  for j = 1, #menu.text do
    local char = menu.text:sub(j,j)
    i = i + 1
    substr = substr .. char
    if (char == " " and i > char_limit) or (j >= #menu.text) then
      --New line
      lines[#lines + 1] = substr
      substr = ""
      i = 0
    end
  end

  --Draw lines onto textbox:
  for i = 1, #lines do
    local text = sol.text_surface.create{
      font = "enter_command",
      font_size = 16,
      text = lines[i]
    }
    text:draw(textbox, 8, (i-1) * 16 + 8)
  end
end


function menu:on_draw(dst)
  bg_surface:draw(dst, 16, 120)
  textbox:draw(dst, 16, 120)
end


function menu:on_command_pressed(cmd)
  if cmd == "confirm" then
    sol.menu.stop(menu)
    return true
  end
end

