--[[
Unlock values:
possession_crafting_book_alchemist --for elemental effects
possession_crafting_book_artificer --for tinkering things
possession_crafting_book_apothecary --for special potions
--]]


local recipes = {
  {
    item = "inventory/grenade",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "blackpowder", quantity = 1,},
  },

  {
    item = "inventory/grenade_cluster",
    {ingredient = "flask", quantity = 3,},
    {ingredient = "blackpowder", quantity = 1,},
    {ingredient = "antimony", quantity = 1,},
  },

  {
    item = "inventory/grenade_stun",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "blackpowder", quantity = 1,},
    {ingredient = "yarrow", quantity = 1,},
  },

  {
    item = "inventory/grenade_cluster_stun",
    unlock_value = "possession_crafting_book_artificer",
    {ingredient = "flask", quantity = 3,},
    {ingredient = "blackpowder", quantity = 1,},
    {ingredient = "yarrow", quantity = 1,},
    {ingredient = "antimony", quantity = 1,},
  },

  {
    item = "inventory/grenade_cactus",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "blackpowder", quantity = 1,},
    {ingredient = "needle", quantity = 1,},
  },

  {
    item = "inventory/grenade_fire",
    unlock_value = "possession_crafting_book_alchemist",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "blackpowder", quantity = 1,},
    {ingredient = "foxglove", quantity = 1,},
  },

  {
    item = "inventory/grenade_ice",
    unlock_value = "possession_crafting_book_alchemist",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "blackpowder", quantity = 1,},
    {ingredient = "yarrow", quantity = 1,},
  },

  {
    item = "inventory/grenade_magic",
    unlock_value = "possession_crafting_book_alchemist",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "blackpowder", quantity = 1,},
    {ingredient = "silverwater", quantity = 1,},
  },

  {
    item = "inventory/grenade_poison",
    unlock_value = "possession_crafting_book_alchemist",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "blackpowder", quantity = 1,},
    {ingredient = "st_laurence_wort", quantity = 1,},
  },

  {
    item = "inventory/grenade_pitch",
    unlock_value = "possession_crafting_book_artificer",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "blackpowder", quantity = 1,},
    {ingredient = "foxglove", quantity = 1,},
    {ingredient = "pine_resin", quantity = 1,},
  },

  {
    item = "inventory/dynamite",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "blackpowder", quantity = 1,},
    {ingredient = "foxglove", quantity = 1,},
  },
--===Tools===--
  {
    item = "inventory/dart",
    {ingredient = "needle", quantity = 1,},
  },

  {
    item = "inventory/dart_stun",
    {ingredient = "needle", quantity = 1,},
    {ingredient = "yarrow", quantity = 1,},
  },

  {
    item = "inventory/dart_ice",
    unlock_value = "possession_crafting_book_alchemist",
    {ingredient = "needle", quantity = 1,},
    {ingredient = "yarrow", quantity = 1,},
  },

  {
    item = "inventory/dart_poison",
    unlock_value = "possession_crafting_book_alchemist",
    {ingredient = "needle", quantity = 1,},
    {ingredient = "st_laurence_wort", quantity = 1,},
  },

  {
    item = "inventory/mine_proximity",
    unlock_value = "possession_crafting_book_artificer",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "blackpowder", quantity = 1,},
    {ingredient = "antimony", quantity = 1,},
    {ingredient = "iron_filings", quantity = 1,},
  },

  {
    item = "inventory/mine_cactus",
    unlock_value = "possession_crafting_book_artificer",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "blackpowder", quantity = 1,},
    {ingredient = "antimony", quantity = 1,},
    {ingredient = "needle", quantity = 1,},
  },

  --{line_break = true},
--===Potions===--
  {
    item = "potions/increase_guns",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "silverwater", quantity = 1,},
    {ingredient = "antimony", quantity = 1,},
  },

  {
    item = "potions/increase_strength",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "silverwater", quantity = 1,},
    {ingredient = "foxglove", quantity = 1,},
  },

  --TODO: increase_magic, increase strength ++ but inflict burn

  {
    item = "potions/defense_type_bullet",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "silverwater", quantity = 1,},
    {ingredient = "blackpowder", quantity = 1,},
  },

  {
    item = "potions/defense_type_physical",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "silverwater", quantity = 1,},
    {ingredient = "yarrow", quantity = 1,},
  },

  {
    item = "potions/madness_recovery",
    unlock_value = "possession_crafting_book_apothecary",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "silverwater", quantity = 1,},
    {ingredient = "yarrow", quantity = 1,},
  },

  {
    item = "potions/resistance_burn",
    unlock_value = "possession_crafting_book_apothecary",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "silverwater", quantity = 1,},
    {ingredient = "foxglove", quantity = 1,},
  },

  {
    item = "potions/resistance_poison",
    unlock_value = "possession_crafting_book_apothecary",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "silverwater", quantity = 1,},
    {ingredient = "st_laurence_wort", quantity = 1,},
  },

  {
    item = "potions/vengence",
    unlock_value = "possession_crafting_book_apothecary",
    {ingredient = "flask", quantity = 1,},
    {ingredient = "silverwater", quantity = 1,},
    {ingredient = "pine_resin", quantity = 1,},
  },

}

return recipes
