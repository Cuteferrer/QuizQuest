local name_box = require("scripts/modules/trillium/dialog/libs/name_box_menu")
local profiles_prefix =  "scripts/modules/trillium_config/dialog_profiles/"

local manager = {}
local config = {}

function manager:set_config(new_config)
  config = new_config
end


function manager:set_profile(profile_id, dialog_menu)
  local profile = {}

  --Set
  if sol.file.exists(profiles_prefix .. profile_id .. ".lua") then
    --Copy from the original profile so we don't overwrite it with any changes we make:
    local origin_profile = require(profiles_prefix .. profile_id)
    for k, v in pairs(origin_profile) do
      profile[k] = v
    end
  end

  dialog_menu.active_profile = profile
  dialog_menu:set_portrait(profile)

  --Set name box:
  local display_name = sol.language.get_string("dialog.profiles." .. profile_id)
  if not display_name then display_name = profile_id end
  assert(config.name_box, "Error: dialog menu config must include a 'name_box' table")
  --set config:
  name_box:set_config(config.name_box)
  name_box.x, name_box.y = config.origin_x, config.origin_y
  --Start menu (if not started already) and set name
  if not sol.menu.is_started(name_box) then
    sol.menu.start(dialog_menu, name_box)
    name_box:opening_animation()
  end
  name_box:set_name(display_name)

  --Play vox bark if present
  if profile.vox_barks then
    sol.audio.play_sound(profile.vox_barks[math.random(1, #profile.vox_barks)])
  end
end



function manager:unset_profile()
  if sol.menu.is_started(name_box) then
    sol.menu.stop(name_box)
  end
end


return manager