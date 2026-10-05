local font, font_size = sol.modules.get_object("language_manager"):get_dialog_font()

local builder = {}

function builder:new(game, config)
  local menu = {}
  menu.x, menu.y = config.x or 208, config.y or 155
  local width, height = config.width or 200, config.height or 128
  local cell_width, cell_height = config.cell_width or width, config.cell_height or 24
  local message_duration = config.message_duration or 4000

  local message_queue = {}

  function menu:add_message(props)
    local message_string = props.message or ""
    local sprite_id = props.sprite
    local sprite_animation = props.animation

    local message = {}
    message.y = 0
    message.surface = sol.surface.create(cell_width, cell_height)
    message.text_surface = sol.text_surface.create({
      font = font, font_size = font_size,
      horizontal_alignment = "center",
      text = message_string,
    })
    if sprite_id then
      message.sprite = sol.sprite.create(sprite_id)
      if sprite_animation then message.sprite:set_animation(sprite_animation) end
    end
    message.timer = sol.timer.start(game, message_duration, function()
      message.surface:fade_out()
      sol.timer.start(game, 1000, function() table.remove(message_queue, 1) end)
    end)
    --Scoot any other messages up:
    for _, old_message in pairs(message_queue) do
      local m = sol.movement.create"straight"
      m:set_angle(math.pi / 2)
      m:set_max_distance(cell_height)
      m:set_speed(120)
      m:start(old_message)
    end

    table.insert(message_queue, message)
  end


  local function draw_message(message)
    message.surface:clear()
    if message.sprite then
      message.sprite:draw(message.surface, cell_width / 2, cell_height - 3)
    end
    message.text_surface:draw(message.surface, cell_width / 2, cell_height / 2)
  end


  function menu:on_draw(dst)
    for i, message in ipairs(message_queue) do
      draw_message(message)
      message.surface:draw(dst, menu.x - cell_width / 2, menu.y + message.y )
    end
  end


  function game:show_hud_message(arg)
    local props = {}
    if type(arg) == "string" then
      props.message = arg
      props.sprite = "hud/message_queue_background"
    else
      props = arg
    end
    menu:add_message(props)
  end


  return menu
end


return builder
