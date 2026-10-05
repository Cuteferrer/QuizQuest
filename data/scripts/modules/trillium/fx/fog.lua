--[[
Fog script, written by Max Mraz and Llamazing

Example usage:
	For any preset fog that is defined by a keyword in the "generate_fogs" function, you can simply call:
	map:set_fog("clouds")

	if you need to create a unique fog on a map and don't want to write it into the generate fogs function as a preset:

  local fog_manager = require("scripts/fx/fog")
  local fog1 = fog_manager.new({
  	fog_texture = {png = "fogs/fog.png", mode = "blend", opacity = 100},
  	opacity_range = {60,110},
    drift = {5, 0, -1, 1},
    parallax_speed = 1,
  })
  sol.menu.start(map, fog1)


--]]

local fog_manager = {}

function fog_manager.new(props)
	local fog_menu = {}

	fog_menu.drift = props and props.drift or {7, 0, -1, 1}
	fog_menu.parallax_speed = props and props.parallax_speed or 1
	fog_menu.texture = props and props.fog_texture or "fogs/fog.png"
	fog_menu.opacity_range = props and props.opacity_range or {60, 100}
  fog_menu.waver_distance = props and props.waver_distance or {0,0}

	fog_menu.props_set = true

	local surface = sol.surface.create(fog_menu.texture.png or "fogs/fog.png")

	local opacity_min, opacity_max = 50, 150

	fog_menu.drift_x = 0
	fog_menu.drift_y = 0



	function fog_menu:on_started()

		if not fog_menu.props_set then fog_menu:set_props() end
    sol.menu.bring_to_back(fog_menu) --so that it'll be behind the lighting_effects

    fog_menu.width, fog_menu.height = surface:get_size()
		surface:set_blend_mode(fog_menu.texture.mode or "blend")
		surface:set_opacity(fog_menu.texture.opacity or 100)

		--Drift
    local waver_count_x, waver_count_y = 0, 0
		if fog_menu.drift[1] ~= 0 then
			sol.timer.start(fog_menu, 1000 / fog_menu.drift[1], function()
				fog_menu.drift_x = fog_menu.drift_x + 1 * (fog_menu.drift[3] or 1)
        if fog_menu.waver_distance[1] > 0 then
          waver_count_x = waver_count_x + 1
          if waver_count_x >= fog_menu.waver_distance[1] then
            waver_count_x = 0
            fog_menu.drift[3] = fog_menu.drift[3] * -1
          end
        end
				return true
			end)
		end
		if fog_menu.drift[2] ~= 0 then
			sol.timer.start(fog_menu, 1000 / fog_menu.drift[2], function()
				fog_menu.drift_y = fog_menu.drift_y + 1 * (fog_menu.drift[4] or 1)
        if fog_menu.waver_distance[2] > 0 then
          waver_count_y = waver_count_y + 1
          if waver_count_y >= fog_menu.waver_distance[2] then
            waver_count_y = 0
            fog_menu.drift[4] = fog_menu.drift[4] * -1
          end
        end
				return true
			end)
		end

		--Opacity Pulse
		opacity_decreasing = true
		opacity_step = 2
		if fog_menu.opacity_range then
			fog_menu.opacity_pulse_timer = sol.timer.start(fog_menu, 150, function()
				local current_opacity = surface:get_opacity()
        local min_opacity = fog_menu.opacity_range[1]
        local max_opacity = fog_menu.opacity_range[2]
        local new_opacity = 0
				if opacity_decreasing and current_opacity > min_opacity then
					new_opacity = (current_opacity - opacity_step)
				elseif opacity_decreasing and current_opacity <= min_opacity then
					opacity_decreasing = false
					new_opacity = (current_opacity + opacity_step)
				elseif current_opacity < max_opacity then
					new_opacity = (current_opacity + opacity_step)
				elseif current_opacity >= max_opacity then
					opacity_decreasing = true
					new_opacity = (current_opacity - opacity_step)
				end
        --Don't allow new opacity to go below 0:
        new_opacity = math.max(new_opacity, 0)
        surface:set_opacity(new_opacity)
				return true
			end)
		end
	end

  function fog_menu:fade_out()
    local opacity_step = 2
    local timer_delay = 150
    if fog_menu.opacity_pulse_timer then fog_menu.opacity_pulse_timer:stop() end
    sol.timer.start(fog_menu, timer_delay, function()
      local current_opacity = surface:get_opacity()
      local new_opacity = current_opacity - opacity_step
      if new_opacity > 0 then
        surface:set_opacity(new_opacity)
        return true
      else
        sol.menu.stop(fog_menu)
      end
    end)
  end



	local function tile_draw(x_offset, y_offset, dst_surface, x, y)
	    local region_x = x_offset % fog_menu.width
	    local region_y = y_offset % fog_menu.height
	    
	    local region_width = fog_menu.width - region_x
	    local region_height = fog_menu.height - region_y
	    
	    --draw region 4
	    surface:draw_region(region_x, region_y, region_width, region_height, dst_surface, x, y)
	    
	    --draw region 3
	    if region_width>0 then
	        surface:draw_region(0, region_y, region_x, region_height, dst_surface, x + fog_menu.width - region_x, y)
	    end
	    
	    --draw region 2
	    if region_height>0 then
	        surface:draw_region(region_x, 0, region_width, region_y, dst_surface, x, y + fog_menu.height - region_y)
	    end
	    
	    --draw region 1
	    if region_width>0 and region_height>0 then
	        surface:draw_region(0, 0, region_x, region_y, dst_surface, x + fog_menu.width - region_x, y + fog_menu.height - region_y)
	    end
	end


	function fog_menu:on_draw(dst_surface)
    if sol.main.get_game() then
      local camera = sol.main.get_game():get_map():get_camera()
      if not camera then return end
    	  local camera_x, camera_y = camera:get_position()
    	  tile_draw(
    	  	fog_menu.drift_x + math.floor(camera_x * fog_menu.parallax_speed) % fog_menu.width,
    	  	fog_menu.drift_y + math.floor(camera_y * fog_menu.parallax_speed) % fog_menu.height,
    	  	dst_surface, 0, 0
    	  	)
    else
    	  tile_draw(
    	  	fog_menu.drift_x % fog_menu.width,
    	  	fog_menu.drift_y % fog_menu.height,
    	  	dst_surface, 0, 0
    	  	)
    end
	end

	return fog_menu
end


--Generate a table of fogs by type:
local function generate_fogs(fog_type)
  local fogs = {}
  --Depending on type of fog, generate a fog table and insert into the fogs table
  if fog_type == "fog" then
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/fog.png", mode = "blend", opacity = 35},
      	opacity_range = {10,45},
      drift = {8, 0, -1, 1},
      parallax_speed = 1,
      }
    ))
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/fog_2.png", mode = "blend", opacity = 35},
      	opacity_range = {15,40},
      drift = {6, 0, -1, 1},
      parallax_speed = 1,
      }
    ))

  elseif fog_type == "forest" then
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/canopy_1.png", mode = "blend", opacity = 50},
      opacity_range = {50,50},
      drift = {1, 0, -1, 1},
      parallax_speed = 1,
      waver_distance = {1, 0}
      }
    ))
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/canopy_2.png", mode = "blend", opacity = 40},
      	opacity_range = {40,40},
      drift = {0, 1, 1, -1},
      parallax_speed = 1,
      waver_distance = {1, 1}
      }
    ))
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/canopy_3.png", mode = "blend", opacity = 25},
      	opacity_range = {25,25},
      drift = {3, 0, -1, 1},
      parallax_speed = 1,
      waver_distance = {1, 1}
      }
    ))

  elseif fog_type == "clouds" then
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/clouds_2.png", mode = "blend", opacity = 35},
      	opacity_range = {25,55},
      drift = {8, 5, -1, 1},
      parallax_speed = 1,
      }
    ))

  elseif fog_type == "dust" then
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/dust_1.png", mode = "blend", opacity = 35},
      	opacity_range = {15,65},
      drift = {6, 0, -1, 1},
      parallax_speed = 1,
      }
    ))
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/dust_2.png", mode = "blend", opacity = 35},
      	opacity_range = {10,50},
      drift = {10, 0, -1, 1},
      parallax_speed = 1,
      }
    ))

  elseif fog_type == "canyon_mist" then
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/canyon_mist_1.png", mode = "blend", opacity = 35},
      	opacity_range = {0,60},
      drift = {8, 0, -1, 1},
      parallax_speed = 1,
      }
    ))
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/canyon_mist_2.png", mode = "blend", opacity = 35},
      	opacity_range = {0,80},
      drift = {6, 0, -1, 1},
      parallax_speed = 1,
      }
    ))

  elseif fog_type == "light_mist" then
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/canyon_mist_1.png", mode = "blend", opacity = 10},
      	opacity_range = {5,15},
      drift = {8, 0, -1, 1},
      parallax_speed = 1,
      }
    ))
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/canyon_mist_2.png", mode = "blend", opacity = 10},
      	opacity_range = {5,25},
      drift = {6, 0, -1, 1},
      parallax_speed = 1,
      }
    ))

  elseif fog_type == "heavy_mist" then
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/canyon_mist_1.png", mode = "blend", opacity = 35},
      	opacity_range = {10,60},
      drift = {8, 0, -1, 1},
      parallax_speed = 1,
      }
    ))
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/canyon_mist_2.png", mode = "blend", opacity = 35},
      	opacity_range = {10,80},
      drift = {6, 0, -1, 1},
      parallax_speed = 1,
      }
    ))
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/canyon_mist_1.png", mode = "blend", opacity = 50},
      	opacity_range = {30,80},
      drift = {3, 0, -1, 1},
      parallax_speed = 1,
      }
    ))
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/canyon_mist_2.png", mode = "blend", opacity = 35},
      	opacity_range = {40,85},
      drift = {2, 0, -1, 1},
      parallax_speed = 1,
      }
    ))
    table.insert(fogs, fog_manager.new({
      	fog_texture = {png = "fogs/canyon_mist_3.png", mode = "blend", opacity = 55},
      	opacity_range = {40,70},
      drift = {6, 0, -1, 1},
      parallax_speed = 1,
      }
    ))

  end
  for _, fog in pairs(fogs) do
    fog.fog_type = fog_type
  end
  return fogs
end


local map_meta = sol.main.get_metatable"map"
function map_meta:set_fog(fog_type)
  local map = self
  local fogs = generate_fogs(fog_type)
  for _, fog in pairs(fogs) do
    sol.menu.start(map, fog)
  end
  return fogs
end


function map_meta:fade_in_fog(fog_type)
  local map = self
  local fogs = generate_fogs(fog_type)
  for _, fog in pairs(fogs) do
    fog.texture.opacity = 0
    sol.menu.start(map, fog)
  end
  return fogs
end


function map_meta:fade_out_fog(fogs)
  local map = self
  for _, fog in pairs(fogs) do
    fog:fade_out()
  end
end


return fog_manager