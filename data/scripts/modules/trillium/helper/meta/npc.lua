local npc_meta = sol.main.get_metatable"npc"


npc_meta:register_event("on_created", function(npc)
  local hero = npc:get_map():get_hero()
  local sprite = npc:get_sprite()

  if npc:get_property("watch_hero") then    
    local default_direction = sprite:get_direction()
    sol.timer.start(npc, 300, function()
      if npc:get_distance(hero) <= 200 then
        sprite:set_direction(npc:get_direction4_to(hero))
      else
        sprite:set_direction(default_direction)
      end
      return true
    end)
  end

end)

