--A configuration file to create a basic grid menu.

--Liscened under MIT. Authored by J. Cournoyer.

--Setup the menu using the desired template script. 
--The Grid Menu template is used here.
--This example should create a 3x3 grid with 9 cells.
--Each cell is 16px^2, has 4px between each other,
--and has 4px between cells and the edge of the menu.

--[[
Allowed objects is a table that holds the objects to be displayed in the menu. Each object is a table that can take multiple parameters:
- name (string): if this is an equipment item, this is the path to the item from the /items directory. Otherwise unused
- sprite (string): the sprite to display in the grid. If this is not specified, we assume this is an equipment item and use the name as the animation for a sprite in sprites/entities/items
- animation (string)(optional): the animation of the sprite. Ignored if no sprite is specified (as we assume an equipment item)
--]]
local menu = sol.modules.get_object("trilmenu_grid").create{
  allowed_objects = {
    {name = "materials/animal/butterfly"},
    {name = "materials/animal/dragonfly"},
    {name = "materials/mineral/amber"},
    {name = "materials/mineral/amethyst"},
    {name = "materials/mineral/diamond"},
    {name = "materials/mineral/emerald"},
    {name = "materials/mineral/iron"},
    {name = "materials/mineral/meteorite"},
    {name = "materials/mineral/ruby"},
    {name = "materials/mineral/sapphire"},
    {name = "materials/plant/ragwort"},
  },
  grid_size = {columns=5, rows=3}, --Grid Size is a table comprised of two key/value pairs; the # of Rows and Columns in the grid.
  cell_size = {width=32, height=32},  --Cell Size is a table comprised of two key/value pairs; Width and Height of the cell in pixels.
  cell_spacing = 4,  --Cell Spacing is an integer that determines the distance between cells.
  edge_spacing = 4,  --Edge Spacing is an integer that determines the distance between cells and the menu's edge.
}

--Define the controls specific to this menu. These will be added to
--(or replace?) the controls that may be defined in the template script.
menu:register_event("on_command_pressed", function(self, command)
    --Add control behaviour here.
    if command == "confirm" then
      print("Selected:", menu:get_selected_object().name)
    end
  end)

return menu