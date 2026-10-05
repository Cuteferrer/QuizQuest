local game = sol.main.get_game()
local commands_info = {
    {
        name = "action",
        unlocked = true,
        customizable = true,
        command = "action"
    },
    {
        name = "sword",
        unlocked = game:has_ability("sword"),
        customizable = true,
        command = "attack",
    },
    {
        name = "item",
        unlocked = true,
        customizable = true,
        command = "item_1",
    },
    {
        name = "pause",
        unlocked = true,
        customizable = true,
        command = "pause",
    },
    {
        name = "save",
        unlocked = true,
        customizable = true,
        default_key = "escape",
        command = function()
            if game:is_pause_allowed() then  -- Keys below are menus.
                if not game:is_paused() and not game:is_dialog_enabled() and game:get_life() > 0 then
                    game:start_dialog("save_quit", function(answer)
                        if answer == 1 then
                        -- Continue.
                        sol.audio.play_sound("danger")
                        elseif answer == 2 then
                        -- Save and quit.
                        sol.audio.play_sound("danger")
                        game:save()
                        sol.main.reset()
                        else
                        -- Quit without saving.
                        sol.audio.play_sound("danger")
                        sol.main.reset()
                        end
                    end)
                    return true
                end
            end
            return false
        end
    },
    {
        name = "up",
        unlocked = true,
        customizable = true,
        command = "up",
    },
    {
        name = "down",
        unlocked = true,
        customizable = true,
        command = "down",
    },
    {
        name = "left",
        unlocked = true,
        customizable = true,
        command = "left",
    },
    {
        name = "right",
        unlocked = true,
        customizable = true,
        command = "right",
    },
    {
        name = "fullscreen",
        unlocked = true,
        customizable = false,
        default_key = "F11",
    },
}

return commands_info