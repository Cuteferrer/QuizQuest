local manager = {}

function manager.get_color_from_preset(preset)
  local color
  if type(preset) == "table" then
    return preset
  --Numbers 0-6: amounts of how dark it is:
  elseif preset == 0 then
    color = {255,255,255}
  elseif preset == 1 then
    color = {150,180,200}
  elseif preset == 2 then
    color = {100,115,135}
  elseif preset == 3 then
    color = {75,85,90}
  elseif preset == 4 then
    color = {20,40,55}
  elseif preset == 5 then
    color = {5, 15, 25}
  elseif preset == 6 then
    color = {0, 0, 0}

  --Presets
  elseif preset == "abandoned_interior" then
    color = {230,220,210}
  elseif preset == "cave" then
    color = {180,180,180}
  elseif preset == "dim" then
    color = {190,180,180}
  elseif preset == "crypt" then
    color = {125,140,145}
    
  else
    error("Invalid value passed as darkness level:" .. preset)
  end

  return color
end

return manager
