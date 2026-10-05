local game_meta = sol.main.get_metatable"game"

game_meta:register_event("on_started", function(self)
  --Add a checker to trigger a game:on_healed() event and on_healed event for the event manager
  local current_life = self:get_max_life()
  sol.timer.start(self, 30, function()
    local new_life = self:get_life()
    --Check if been healed
    if new_life > current_life then
      --Trigger on_healed(amount_healed) event
      local amount_healed = current_life - new_life
      --Trigger charm event
      self.event_manager:trigger_event("on_healed", amount_healed)
      if self.on_healed then self:on_healed(amount_healed) end
    end
    current_life = new_life
    return true
  end)
end)
