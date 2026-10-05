function sol.main.get_items_in_directory(path)
  local new_table = {}
  for k, v in ipairs(sol.file.list_dir(path)) do
    if v:match(".lua") then
      local item_name = v:gsub(".lua", "")
      path = path:gsub("items/", "")
      item_name = path .. "/" .. item_name
      table.insert(new_table, item_name)
    end
  end
  return new_table
end
