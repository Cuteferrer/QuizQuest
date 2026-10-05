require("scripts/multi_events")

local function initialize_commands_features(game)
    local commands_config = require("scripts/commands_config.lua")

    -- If a command has no binding (new game or new command from a quest update)
    -- set the default binding to the command
    local function init_custom_command_bindings()
        for _, command in ipairs(commands_config) do
            if command.customizable and type(command.command) ~= "string" then
                if game:get_value("keyboard_" .. command.name) == nil then
                    game:set_custom_command_keyboard_binding(command, command.default_key)
                end
            end
        end
    end

    -- Reset the command keyboard bindings to the default values
    function game:reset_command_keyboard_bindings()
        for _, command in ipairs(commands_config) do
            if command.customizable then
                self:set_custom_command_keyboard_binding(command, command.default_key)
            end
        end
    end

    -- Like game:get_command_keyboard_binding(),
    -- but handles additional commands from the quest.
    -- Returns an empty string if the command has no keyboard key.
    function game:get_custom_command_keyboard_binding(item)

        local command = item.command
        if type(command) == "string" then
            -- Customizable command from the engine.
            return game:get_command_keyboard_binding(command) or ""
        end

        -- Customizable command from the quest.
        return game:get_value("keyboard_" .. item.name) or ""
    end

    -- Like game:set_command_keyboard_binding(),
    -- but handles additional commands from the quest.
    function game:set_custom_command_keyboard_binding(item, key)

        local command = item.command
        if type(command) == "string" then
            -- Built-in command from the engine.
            game:set_command_keyboard_binding(command, key)
        else
            -- Command from the quest.
            game:set_value("keyboard_" .. item.name, key)
        end

        -- TODO swap commands if the binding is already used
    end

    -- Like game:get_command_joypad_binding(),
    -- but handles additional commands from the quest.
    -- Returns an empty string if the command has no joypad action.
    function game:get_custom_command_joypad_binding(item)

        local command = item.command
        if type(command) == "string" then
            -- Customizable command from the engine.
            return game:get_command_joypad_binding(command) or ""
        end

        -- Customizable command from the quest.
        return game:get_value("joypad_" .. item.name) or ""
    end

    -- Like game:set_command_joypad_binding(),
    -- but handles additional commands from the quest.
    function game:set_custom_command_joypad_binding(item, key)

        local command = item.command
        if type(command) == "string" then
            -- Built-in command from the engine.
            game:set_command_joypad_binding(command, key)
        else
            -- Command from the quest.
            game:set_value("joypad_" .. item.name, key)
        end

        -- TODO swap commands if the binding is already used
    end

    local function process_command(game, command)
        local function is_command(command, name)
          local trigger = false
      
          if command == game:get_value("keyboard_" .. name) then
            trigger = true
          elseif command == game:get_value("joypad_" .. name) then
            trigger = true
          end
      
          return trigger
        end
      
        if game.customizing_command then
          -- Don't treat this input normally, it will be recorded as a new command binding
          -- by the commands menu.
          return false
        end
      
        local handled = false
        for _, c in ipairs(commands_config) do
            if is_command(command, c.name) then
                if type(c.command) == "function" then
                    handled = c.command()
                end
                break
            end
        end
        return handled
    end

    -- Function called when the player presses a key during the game.
    game:register_event("on_key_pressed", function(game, key)
        return process_command(game, key)
    end)
    
    -- Function called when the player presses a joypad button during the game.
    game:register_event("on_joypad_button_pressed", function(game, button)
        return process_command(game, button)
    end)
    
    init_custom_command_bindings()
end

-- Set up the pause menu on any game that starts.
local game_meta = sol.main.get_metatable("game")
game_meta:register_event("on_started", initialize_commands_features)

return true
