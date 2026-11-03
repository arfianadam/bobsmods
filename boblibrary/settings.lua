data:extend({
  {
    type = "bool-setting",
    name = "bobmods-library-recipe-cleanup",
    setting_type = "startup",
    default_value = true,
  },
  {
    type = "double-setting",
    name = "bobmods-library-uranium-235-percent",
    setting_type = "startup",
    default_value = 5,
    minimum_value = 0,
    maximum_value = 100,
    order = "c",
  },
})

-- Listed in the order they show in the settings menu.
for index, multiplier in ipairs({
  { "crafting-speed", 1.5 },
  { "electric-furnace-speed", 1.5 },
  { "mining-speed", 1.5 },
  { "research-speed", 1.5 },
  { "inserter-speed", 1.5 },
  { "pump-speed", 1.5 },
  { "power", 1.5 },
  { "stack-size", 1.5 },
  { "inventory-size", 1.5 },
  { "fluid-capacity", 1.5 },
  { "belt-speed", 1.5 },
  { "underground-reach", 1.5 },
  { "pole-reach", 1.5 },
  { "battery-capacity", 1.5 },
  { "robot", 1.5 },
  { "roboport", 1.5 },
  { "module-bonus", 1.5 },
  { "beacon-effectivity", 1.5 },
  { "beacon-range", 4 },
  { "turret-damage", 1.25 },
  { "turret-fire-rate", 1.25 },
  { "turret-range", 1.5 },
  { "turret-turn-speed", 1.5 },
}) do
  data:extend({
    {
      type = "double-setting",
      name = "bobmods-library-" .. multiplier[1] .. "-multiplier",
      setting_type = "startup",
      default_value = multiplier[2],
      minimum_value = 0.1, -- 0 would divide turret cooldowns by zero and stop machines
      order = string.format("b%02d", index),
    },
  })
end
