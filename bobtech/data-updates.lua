require("prototypes.recipe.recipe-updates")
require("prototypes.technology.technology-updates")
require("prototypes.item.item-updates")
require("prototypes.entity.entity-updates")

-- Vanilla labs at 150% speed, matching the Bob tiers.
for _, name in pairs({ "lab", "biolab" }) do
  local lab = data.raw.lab[name]
  if lab then
    lab.researching_speed = (lab.researching_speed or 1) * 1.5
  end
end
