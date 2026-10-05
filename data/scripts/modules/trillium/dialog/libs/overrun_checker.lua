local language_manager = sol.modules.get_object("language_manager")
local manager = {}


function manager:check_dialog_overruns(language_id, max_dialog_length)
  local font, font_size = language_manager:get_dialog_font(language_id)
  local test_surface = sol.text_surface.create{font = font, font_size = font_size}

  --create an environment to read the dialogs.dat, set a default metatable function to avoid errors for anything other than a dialog
  local env = setmetatable({}, {__index = function() return function() end end})

  --process dialogs on dialogs.dat --each dialog is a function with a single argument, a table of properties.
  function env.dialog(props)
    local text = props.text

    --Remove inline dialog tags:
    text = text:gsub("%$[%w_=/%?]+%$", "")

    local lines = {}
    for s in text:gmatch("([^\n]*)\n") do --break out each line, including empty lines
        table.insert(lines, s)
    end

    --Test each line
    for _, line in ipairs(lines) do
      test_surface:set_text(line)
      local width, _ = test_surface:get_size()
      if width > max_dialog_length then
        print("Warning: line overrun in dialog '" .. props.id .."'")
        print("Overrun line is: '" .. line .. "'")
      end
    end
  end

  --Load dialogs file to run through environment
  local chunk = sol.main.load_file("languages/" .. language_id .. "/text/dialogs.dat")
  setfenv(chunk, env)
  chunk()
end


return manager
