local map_meta = sol.main.get_metatable"map"

------Fire------
function map_meta:create_fire(props)
  --props: name, x, y, layer, properties
  local map = self
  local fire = map:create_custom_entity({
    x = props.x, y = props.y, layer = props.layer, width = 16, height = 16, direction = 0,
    model = "elements/flame",
    properties = props.properties or {},
  })
  return fire
end

function map_meta:old_propagate_fire(x, y, z)
  local num_flames = 6
  for i=1, num_flames do
    local flame = self:create_fire{x=x, y=y, layer=z}
    local m = sol.movement.create"straight"
    m:set_max_distance(16)
    m:set_ignore_obstacles()
    m:set_angle(2* math.pi / num_flames * i)
    m:start(flame)
  end
end

function map_meta:propagate_fire(x, y, z, distance)
  local map = self
  local dist = distance or 22
  for e in map:get_entities() do
    if e:get_distance(x, y) <= dist and e:get_layer() == z and (e.can_burn or e:get_property("can_burn") ) then
      local ex, ey, ez = e:get_position()
      local prop_flame = map:create_fire{x=ex, y=ey, layer=ez}
      if e.burn_duration then prop_flame.burn_duration = e.burn_duration end
    end
  end
end


----Lightning----------
function map_meta:create_lightning(props)
  local lightning_type = props.lightning_type or "lightning_zap"
  local lightning = self:create_custom_entity{
    x = props.x, y = props.y, layer = props.layer,
    width = props.width or 16, height = props.height or 16, direction = 0,
    model = "elements/" .. lightning_type,
  }
  return lightning
end

function map_meta:create_lightning_static(props)
  local lightning = self:create_custom_entity{
    x = props.x, y = props.y, layer = props.layer, width = 16, height = 16, direction = 0,
    model = "elements/lightning_static",
  }
  lightning:set_source(props.source or "none")
  return lightning
end

function map_meta:create_lightning_bolt(props)
  local map = self
  local x, y, z = props.x, props.y, props.layer
  local delay = props.delay or 0
  local seek_enemy_distance = props.seek_enemy_distance or nil
  local lightning_rod_range = props.lightning_rod_range or 96

  --Get drawn to enemies if they're nearby, if seek_enemy_distance was passed in props
  if seek_enemy_distance then
    for e in map:get_entities_in_rectangle(x - seek_enemy_distance, y - seek_enemy_distance, seek_enemy_distance * 2, seek_enemy_distance * 2) do
      if e:get_type() == "enemy" then
        x, y, z = e:get_position()
      end
    end
  end
  --Get drawn to conductive objects if they're nearby the strike location. Note: this overwrites being drawn to nearby enemies, metal/conductive entity > enemy
  for e in map:get_entities_in_rectangle(x - lightning_rod_range, y - lightning_rod_range, lightning_rod_range * 2, lightning_rod_range * 2) do
    if e.can_conduct_electricity or e.is_conductive then
      x, y, z = e:get_position()
    end
  end
  local warning_sparks = map:create_custom_entity{
    x=x, y=y+4, layer=z, width=16, height=16, direction=0, sprite="elements/lightning_warning"
  }
  sol.timer.start(map, delay, function()
    sol.audio.play_sound"thunder1"
    local bolt = self:create_custom_entity{
      x=x, y=y, layer=z, width=24, height=24, direction=0,
      model = "elements/lightning_bolt",
    }
    --[[Hack to register collision with custom entities to burn plants:
    warning_sparks:add_collision_test("sprite", function(warning_sparks, other_entity)
      warning_sparks.lightning_affected_entities = warning_sparks.lightning_affected_entities or {}
      if other_entity.react_to_lightning_bolt and not warning_sparks.lightning_affected_entities[other_entity]
      and (other_entity:get_type() == "custom_entity") then
        other_entity:react_to_lightning_bolt(entity)
        warning_sparks.lightning_affected_entities[other_entity] = other_entity
      end
    end)
    sol.timer.start(warning_sparks, 50, function() warning_sparks:remove() end)
    --]]
    --Hack to register collision with custom entities to burn plants
    for e in map:get_entities_in_rectangle(bolt:get_bounding_box()) do
      if e:get_type() == "custom_entity" and e.react_to_lightning_bolt then
        e:react_to_lightning_bolt(entity)
      end
    end
    warning_sparks:remove()
  end)
end


----Ice-----------------------
function map_meta:create_ice_sparkle(x,y,z)
  local map = self
  local sparkle = map:create_custom_entity{
    x=x, y=y, layer=z, direction=0, width=32, height=32,
    model = "elements/ice_sparkle",
  }
  sparkle:set_origin(16, 16)
  return sparkle
end

function map_meta:create_ice_blast(x,y,z)
  local map = self
  local blast = map:create_custom_entity{
    x=x, y=y, layer=z, direction=0, width=16, height=16,
    model = "elements/ice_blast",
  }
  return blast
end


function map_meta:create_ice_platform(x,y,z)
  local map = self
  local platform = map:create_custom_entity{
    x=x, y=y, layer=z, direction=0, width=32, height=32,
    model = "elements/ice_platform",
  }
  return platform
end

function map_meta:create_ice_block(x, y, z)
  local map = self
  local block = map:create_custom_entity{
    x=x, y=y, layer=z, direction=0, width=16, height=16,
    sprite = "elements/ice_block",
    model = "elements/ice_block",
  }
  return block
end
