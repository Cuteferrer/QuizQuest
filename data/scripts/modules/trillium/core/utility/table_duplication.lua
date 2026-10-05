--Duplicates a table
function table.duplicate(init_table)
  local new_table = {}
  for k, v in pairs(init_table) do new_table[k] = v end
  return new_table
end
