--TODO: reimplement button mapping menu:
local bind_menu = require("scripts/menus/button_mapping")
local confirmation_factory = sol.modules.get_object("trilmenu_component_confirmation")
local common_config = require("scripts/menus/title_screen/common_config"):get_config()
common_config.options = {
  "keybind",
  "default_controls_kbm",
  "default_controls_keyboard",
  "back",
}

local menu = require("scripts/menus/title_screen/title_menu_factory").new(common_config)

function menu:process_selection(option)
  if option == "keybind" then
    sol.menu.start(menu, bind_menu)

  elseif option == "default_controls_kbm" or option == "default_controls_keyboard" then
    local default_type = option == "default_controls_kbm" and "kbm" or "keyboard"
    local confirm_menu = confirmation_factory.new{
      message_key = "menu.options.set_default_controls",
      callback = function(choice)
        if choice == 1 then
          local con_man = sol.controls.get_controls_manager()
          con_man.reset_default_controls()
          con_man.load_keyboard_mapping_set(default_type)
        end
      end
    }
    sol.menu.start(menu, confirm_menu)

  elseif option == "set_default_controls" then
    local confirm_menu = confirmation_factory.new{
      message_key = "menu.options.set_default_controls",
      callback = function(choice)
        if choice == 1 then
          sol.controls.get_controls_manager().reset_default_controls()
        end
      end
    }
    sol.menu.start(menu, confirm_menu)

  elseif option == "back" then
    menu:switch_to_menu(require("scripts/menus/title_screen/options"))

  end
end

return menu
