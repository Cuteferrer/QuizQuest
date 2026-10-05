local manager = {}

function manager.get_tone_from_preset(tone)
  local color = {255,255,255}

  --If tone is a preset name:
  if type(tone) == "string" then
    --Times:
    if tone == "day" then
      color = {255,250,245}
    elseif tone == "evening" then
      color = {240,230,180}
    elseif tone == "sunset" then
      color = {255,200,130}
    elseif tone == "dusk" then
      color = {170,160,140}
    elseif tone == "night" then
      color = {100,115,135}
    elseif tone == "dawn" then
      color = {200,200,255}
    elseif tone == "morning" then
      color = {240,240,255}


    --Old presets:
    elseif tone == "desert" then
      color = {255, 240, 210}

    --Presets
    elseif tone == "town" then
      color = {220,200,180}
    elseif tone == "town_day" then
      color = {240,230,205}
    elseif tone == "town_cloudy" then
      color = {220,230,240}
    elseif tone == "town_overcast" then
      color = {220,230,235}
    elseif tone == "wilderness" then
      color = {230,230,205}
    elseif tone == "wilderness_cold" then
      color = {230,230,250}
    elseif tone == "wilderness_warm" then
      color = {255,235,190}
    elseif tone == "lake" then
      --color = {230,240,255}
      color = {210,220,235}
    elseif tone == "graveyard" then
      color = {200,200,220}
    elseif tone == "mesas" then
      color = {255,230,200}
    elseif tone == "deep_city" then
      color = {200,240,240}

    --Interior
    elseif tone == "interior" then
      color = {255,255,235}
    elseif tone == "tunnels" then
      color = {190,220,240}
    elseif tone == "cathedral" then
      --color = {230,240,230}
      color = {2550,240,230}
    elseif tone == "cave" then
      color = {180,180,180}
    elseif tone == "warm_cave" then
      color = {255,200,130}
    elseif tone == "mine" then
      color = {190,220,250}
    elseif tone == "foggy_woods" then
      color = {200,200,245}
    elseif tone == "forest" then
      color = {240,255,240}
    elseif tone == "lower_ward" then
      color = {200,230,180}
    elseif tone == "interior_warm" then
      color = {255,240,220}
    elseif tone == "mausoleum" then
      color = {200,220,235}

    --Test
    elseif tone == "test_red" then
      color = {255, 100, 100}
    elseif tone == "test_blue" then
      color = {100, 100, 255}

    else
      error("WARN: passed tone preset '" .. tone .. "' -- this is not a recognized tone preset keyword")
      color = {255,255,255}
    end

  elseif type(tone) == "table" then
    assert(type(tone[1]) == "number" and type(tone[2]) == "number" and type(tone[3]) == "number", "Must pass an {r,g,b} table to 'get_tone_from_preset()")
    color = tone

  else
    error("Must pass either a preset name or an {r,g,b} table to get_tone_from_preset()")
  end

  return color
end


return manager
