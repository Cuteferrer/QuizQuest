--[[
Created by Max Mraz, licensed MIT

Uses the serpent lua serializer to allow read/write of tables
--]]

local serpent = sol.serpent_serializer

local manager = {}
--Make accessible:
sol.file_io = manager

--read / write table
--will serialize a data table using serpent, allowing for nested tables and stuff:
function manager.write_table(data, file_name)
  local file = sol.file.open(file_name, "w")
  if type(data) == "table" then
    local st = serpent.dump(data)
    file:write(st)

  elseif type(data) == "string" then
    string.format("%q", data)
    file:write(data)
  end

	file:flush()
	file:close()
end


function manager.read_table(file_name)
  assert(sol.file.exists(file_name), "Cannot find file " .. file_name)
  local file, err = sol.file.open(file_name, "r")
  if err then error("Could not read file " .. file_name) end
  local st = file:read("*a")
  local ok, data = serpent.load(st)
  file:close()
  if ok then
    return data
  else
    error("Could not load table from " .. file_name)
  end
end



--read_data / write_data a simple "key = value" table, does not allow for nested tables:
function manager.write_data(data, file_name)
  local file = sol.file.open(file_name, "w")

	for key,value in pairs(data) do
		if type(value)=="string" then
			value = string.format("%q", value) --add quotes and escape characters to string
		else value = tostring(value) end
		file:write(string.format("%s = %s\n", key, value))
	end
	
	file:flush()
	file:close()
end


function manager.read_data(file_name)
  local data = {}
  	if sol.file.exists(file_name) then
  		local env = setmetatable({}, {__newindex = function(self, key, value)
  			data[key] = value
  		end})
  		
  		local chunk = sol.main.load_file(file_name)
  		setfenv(chunk, env)
  		chunk()
  else
    error("File does not exist: " .. file_name)
  	end

  return data
end


return manager
