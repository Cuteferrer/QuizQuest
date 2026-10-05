--[[
Okay to be honest, this was an idea I had that I didn't follow through with.
--]]

LOGGER = {}

local serpent = sol.serpent_serializer

function LOGGER.debug(arg)
  if not sol.main.debug_mode then return end
  if type(arg) == "table" then
    arg = serpent.block(arg)
  end

  print(arg)
end


function LOGGER.print_table(t)
  print(serpent.dump(t))
end

