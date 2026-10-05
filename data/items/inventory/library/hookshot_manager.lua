local manager = {}

local config = require("items/inventory/library/hookshot_config.lua")

function manager:init()
  --set hookable entity types
  for _, entity_type in ipairs(config.hookable_entity_types) do
    local meta = sol.main.get_metatable(entity_type)
    function meta:is_hookable() return true end
  end
  --set hookable entities by sprite, within types
  for entity_type, sprites in pairs(config.hookable_by_animation_set) do
    local meta = sol.main.get_metatable(entity_type)
    function meta:is_hookable()
      local sprite = self:get_sprite()
      for _, sprite_name in pairs(sprites) do
        if sprite:get_animation_set() == sprite_name then
          return true
        end
      end
      return false
    end
  end
end

manager:init()

return manager