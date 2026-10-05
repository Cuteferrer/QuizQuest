
function tobool(val)
  if val == nil then
    return false
  end
  if val == true then
    return true
  elseif val == false then
    return false
  end
  assert((val == "true") or (val == "false"), "Cannot convert value '" .. val .. "' to boolean")
  local converter = { ["true"]=true, ["false"]=false }
  return converter[val]
end
