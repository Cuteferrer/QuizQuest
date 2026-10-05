local manager = {}

function manager.new(commands)
  return {
    commands = commands,
    x = 8, y = 218,
    orientation = "horizontal"
  }
end

return manager
