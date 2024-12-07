-- data.lua
-- Define new entities, etc.


-- Recipe to create a combinator.
local combinator_recipe = {
  type = "recipe",
  name = "empty-chest-combinator-recipe",
  enabled = false,       -- Enabled by advanced-combinators; see below.

  -- Ingredients are that of a constant combinator, plus a red circuit,
  -- which a storage chest also requires.
  ingredients = {
    {
      amount = 5,
      name = "copper-cable",
      type = "item",
    },
    {
      amount = 2,
      name = "electronic-circuit",
      type = "item",
    },
    {
      amount = 1,
      name = "advanced-circuit",
      type = "item",
    },
  },

  results = {
    {
      amount = 1,
      name = "empty-chest-combinator-item",
      type = "item",
    },
  },
};


-- Inventory item corresponding to the combinator.
local combinator_item = table.deepcopy(data.raw.item["constant-combinator"]);
combinator_item.name         = "empty-chest-combinator-item";
combinator_item.place_result = "empty-chest-combinator-entity";
combinator_item.order        = "c[combinators]-d[empty-chest-combinator]";
combinator_item.icon         = "__CountEmptyChests__/graphics/icons/empty-chest-combinator.png";


-- World entity for the combinator.
local combinator_entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"]);
combinator_entity.name           = "empty-chest-combinator-entity";
combinator_entity.minable.result = "empty-chest-combinator-item";
combinator_entity.icon           = combinator_item.icon;

for direction_name, direction in pairs(combinator_entity.sprites) do
  -- The first layer is the main image.  The four directions all have
  -- different (x,y) offsets, but share the same image.  The offsets are
  -- the same as in the original.
  direction.layers[1].filename = "__CountEmptyChests__/graphics/entity/combinator/empty-chest-combinator.png";

  -- The second layer is the shadow, which I retain as the one from the
  -- base constant-combinator.
end;


-- Update Factorio data.
data:extend{
  combinator_recipe,
  combinator_item,
  combinator_entity,
};


-- Related technologies:
--    construction-robotics: storage-chest
--    logistic-robotics: storage-chest
--    circuit-network: Basic combinators.
--    advanced-combinators: Selector combinator.

-- I put this in with advanced-combinators because that one is at the
-- tech tier of red circuit, like storage-chest, whereas the
-- circuit-network is at the green circuit tier.
table.insert(data.raw.technology["advanced-combinators"].effects, {
  type = "unlock-recipe",
  recipe = "empty-chest-combinator-recipe",
})


-- EOF
