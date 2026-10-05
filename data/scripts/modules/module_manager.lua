--[[
Created by Max Mraz, licensed MIT
Sets up module features

When starting Solarus, call require("scripts/modules/_index") to require all modules indexed in that file
Make changes to that file to include/ignore any modules in the scripts/modules directory
--]]

sol.modules = {
  module_objects = {},
}

--Register an object to a key in sol.modules
--This allows other scripts to refer to this module object without needing to know the specific path
--It also allows things such as menus to be treated as an interface without referring to the specific implementation path
function sol.modules.register_object(key, ob)
  assert(sol.modules.module_objects[key] == nil, "Modules Object with key '" .. key .. "' already exists!")
  sol.modules.module_objects[key] = ob
end

--Register by path:
function sol.modules.register_object_by_path(key, path)
  assert(sol.file.exists(path .. ".lua"), "No lua file found at path '" .. "', cannot register")
  assert(sol.modules.module_objects[key] == nil, "Modules Object with key '" .. key .. "' already exists!")
  sol.modules.module_objects[key] = require(path)
end


--Get registered object:
function sol.modules.get_object(key)
  assert(sol.modules.module_objects[key], "No module object found registered with key '" .. key .. "'. Call sol.modules.get_object_keys() to print all object keys")
  return sol.modules.module_objects[key]
end

function sol.modules.get_object_keys()
  print("Module keys registered:")
  for k, _ in pairs(sol.modules.module_objects) do
    print(k)
  end
end
