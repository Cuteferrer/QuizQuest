--[[
This config file is used in the cooking system. When ingredients are combined, often there will be multiple matches.
The values in this file are used to detemine which of the matches should be the resultant recipe.

For example, if you put in these ingredients:
- flour
- apples
- peaches
- sugar

You might match two recipes.
- Fruitcake (flour, sugar, any fruit)
- Chutney (any fruit, sugar)

You would probably want the fruitcake to be the result, as it is more complex and specific.
Anyway, there are several vectors that can play into the results, so adjust them here and the cooking system will take them into account.

Each value specifies how many priority points will be awarded for matching that criteria. Adjust these numbers to weight the algorithm differently.
--]]

return {
  recipe_complexity = 30, --number of ingredients in the recipe, total
  specific_matches = 10, --number of specific matches, rather than those who match category (so "apple", not any "fruit")
  total_matches = 10, --number of total matches for a requirement, including duplicates for the requirement
  --this next one is complex. This modifies total matches, where i = order ingredient was selected. points = total_matches * (i ^ (order_mod * -1)).
  --Set closer to 0 so order matters less, 1 (or more) so order matters a lot. Set to nil if order doesn't matter.
  ingredient_order_mod = .1,
}
