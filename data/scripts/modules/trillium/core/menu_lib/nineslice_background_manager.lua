local manager = {}


function manager.get_surface(config)
  config = config or {}
  local width, height = config.width, config.height
  local source_png = config.source_png or "menus/panel_blocks/general.png"
  local tile_width = config.tile_width or 16
  local tile_height = config.tile_height or tile_width
  local repeat_style = config.repeat_style or "tile" --can be "tile" or "scale"
  local tiles_wide = math.floor(width / tile_width)
  local tiles_tall = math.floor(height / tile_height)
  local surface = sol.surface.create(width, height)
  --Create 9 blocks
  local blocks = {}
  local ib = 0
  for iy = 0, 2 do
    for ix = 0, 2 do
      --Find source x, y on PNG:
      local source_x = ix * tile_width
      local source_y = iy * tile_height
      local block = sol.surface.create(source_png)
      block.source_x, block.source_y = source_x, source_y
      blocks[ib] = block

      --Find where to draw it
      local targets_x = {0, tile_width, width - tile_width}
      local targets_y = {0, tile_height, height - tile_height}
      local target_x = targets_x[ix + 1]
      local target_y = targets_y[iy + 1]

      --Stretch the middle tiles
      if repeat_style == "scale" then
        local scale_x = { 1, tiles_wide - 2 , 1 }
        local scale_y = { 1, tiles_tall - 2 , 1 }
        block:set_scale(scale_x[ix + 1], scale_y[iy + 1])
      end

      --Draw
      block:draw_region(source_x, source_y, tile_width, tile_height, surface, target_x, target_y)

      --Tile
      if repeat_style == "tile" then
        --Middle block
        if (ix == 1) and (iy == 1) then
          for i = 1, tiles_wide - 2 do
            for j = 1, tiles_tall - 2 do
              block:draw_region(source_x, source_y, tile_width, tile_height, surface, target_x + (i - 1) * tile_width, target_y + (j - 1) * tile_height)
            end
          end

        elseif ix == 1 then
          for i = 1, math.floor((width - tile_width * 2) / tile_width) do
            block:draw_region(source_x, source_y, tile_width, tile_height, surface, target_x + (i - 1) * tile_width, target_y)
          end

        elseif iy == 1 then
          for i = 1, math.floor((height - tile_height * 2) / tile_height) do
            block:draw_region(source_x, source_y, tile_width, tile_height, surface, target_x, target_y + (i - 1) * tile_height)
          end
        end
      end

      ib = ib + 1
    end
  end

  return surface
  
end


return manager
