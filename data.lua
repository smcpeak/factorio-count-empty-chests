-- data.lua
-- Define new entities, etc.


-- Recipe to create a combinator.
local combinator_recipe = {
  type = "recipe",
  name = "empty-combinator-recipe",
  enabled = true,       -- TODO: Hide this behind research.

  -- For now, same ingredients as a constant combinator.
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
  },

  results = {
    {
      amount = 1,
      name = "empty-combinator-item",
      type = "item",
    },
  },
};


-- Inventory item corresponding to the combinator.
local combinator_item = table.deepcopy(data.raw.item["constant-combinator"]);
combinator_item.name         = "empty-combinator-item";
combinator_item.place_result = "empty-combinator-entity";
combinator_item.order        = "c[combinators]-d[empty-combinator]";
combinator_item.icon         = "__CountEmptyChests__/graphics/icons/empty-combinator.png";


-- World entity for the combinator.
local combinator_entity = table.deepcopy(data.raw["constant-combinator"]["constant-combinator"]);
combinator_entity.name           = "empty-combinator-entity";
combinator_entity.minable.result = "empty-combinator-item";
combinator_entity.icon           = combinator_item.icon;

for direction_name, direction in pairs(combinator_entity.sprites) do
  -- The first layer is the main image.  The four directions all have
  -- different (x,y) offsets, but share the same image.  The offsets are
  -- the same as in the original.
  direction.layers[1].filename = "__CountEmptyChests__/graphics/entity/combinator/empty-combinator.png";

  -- The second layer is the shadow, which I retain as the one from the
  -- base constant-combinator.
end;


-- Update Factorio data.
data:extend{
  combinator_recipe,
  combinator_item,
  combinator_entity,
};


-- EOF
