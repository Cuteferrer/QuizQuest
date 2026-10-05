-- scripts/json.lua — минимальный JSON-декодер, без зависимостей.
local json = {}

local decode_value  -- forward

local function skip_ws(s, i)
	local _, e = s:find("^[ \t\r\n]*", i)
	return e + 1
end

local escapes = { ['"'] = '"', ['\\'] = '\\', ['/'] = '/', b = '\b', f = '\f', n = '\n', r = '\r', t = '\t' }

local function utf8_encode(code)
	if code < 0x80 then
		return string.char(code)
	elseif code < 0x800 then
		return string.char(0xC0 + math.floor(code / 0x40), 0x80 + code % 0x40)
	else
		return string.char(0xE0 + math.floor(code / 0x1000), 0x80 + math.floor(code / 0x40) % 0x40, 0x80 + code % 0x40)
	end
end

local function decode_string(s, i)
	local res = {}
	i = i + 1
	while true do
		local c = s:sub(i, i)
		if c == '"' then
			return table.concat(res), i + 1
		elseif c == '\\' then
			local n = s:sub(i + 1, i + 1)
			if n == 'u' then
				res[#res + 1] = utf8_encode(tonumber(s:sub(i + 2, i + 5), 16))
				i = i + 6
			else
				res[#res + 1] = escapes[n] or n
				i = i + 2
			end
		elseif c == '' then
			error("JSON: незакрытая строка")
		else
			res[#res + 1] = c
			i = i + 1
		end
	end
end

local function decode_array(s, i)
	local arr = {}
	i = skip_ws(s, i + 1)
	if s:sub(i, i) == ']' then return arr, i + 1 end
	while true do
		local v
		v, i = decode_value(s, i)
		arr[#arr + 1] = v
		i = skip_ws(s, i)
		local c = s:sub(i, i)
		if c == ',' then i = skip_ws(s, i + 1)
		elseif c == ']' then return arr, i + 1
		else error("JSON: ожидалась ',' или ']'") end
	end
end

local function decode_object(s, i)
	local obj = {}
	i = skip_ws(s, i + 1)
	if s:sub(i, i) == '}' then return obj, i + 1 end
	while true do
		i = skip_ws(s, i)
		local key
		key, i = decode_string(s, i)
		i = skip_ws(s, i)
		if s:sub(i, i) ~= ':' then error("JSON: ожидалось ':'") end
		local v
		v, i = decode_value(s, i + 1)
		obj[key] = v
		i = skip_ws(s, i)
		local c = s:sub(i, i)
		if c == ',' then i = i + 1
		elseif c == '}' then return obj, i + 1
		else error("JSON: ожидалась ',' или '}'") end
	end
end

function decode_value(s, i)
	i = skip_ws(s, i)
	local c = s:sub(i, i)
	if c == '{' then return decode_object(s, i)
	elseif c == '[' then return decode_array(s, i)
	elseif c == '"' then return decode_string(s, i)
	elseif c == 't' then return true, i + 4
	elseif c == 'f' then return false, i + 5
	elseif c == 'n' then return nil, i + 4
	else
		local j = s:find("[^%-%+%d%.eE]", i) or (#s + 1)
		return tonumber(s:sub(i, j - 1)), j
	end
end

function json.decode(s)
	return (decode_value(s, 1))
end

return json