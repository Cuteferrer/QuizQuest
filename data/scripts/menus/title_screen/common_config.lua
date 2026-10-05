local manager = {}

function manager:get_config()
  local config = {
    x = 25,
    y = 132,
    cursor_offset = {x = -3, y = -3},
  }

  return config
end

return manager
