--[[
Determines what other factions an enemy of a faction might attack
Relationships are not necessarily reciprocal, so watch out that you don't
accidentally create an enemy that will passively take attacks from another faction.
--]]

return {

  assassin = {
    physician = true,
    pinkerton = true,
  },

  physician = {
    assassin = true,
  },

  pinkerton = {
    townsfolk = true,
    assassin = true,
  },

  townsfolk = {
    pinkerton = true,
  },

  graveyard_sentinel = {
    corpse = true,
  },

}


