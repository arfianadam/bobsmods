-- The base game ships a hidden lane splitter: a 1 tile splitter that works on the two lanes of one belt.
-- Unhide it and add one per splitter tier, built from that tier's splitter.
local template = util.table.deepcopy(data.raw["lane-splitter"]["lane-splitter"])
local template_item = util.table.deepcopy(data.raw.item["lane-splitter"])
local overlay = template.icons[2]

local tiers = {
  ["bob-basic-splitter"] = "bob-basic-lane-splitter",
  ["splitter"] = "lane-splitter",
  ["fast-splitter"] = "fast-lane-splitter",
  ["express-splitter"] = "express-lane-splitter",
  ["turbo-splitter"] = "turbo-lane-splitter",
  ["bob-ultimate-splitter"] = "bob-ultimate-lane-splitter",
}

-- The base lane splitter draws the splitter sprites at half size, so do the same for every tier.
local function half_size(sprites)
  if not sprites then
    return nil
  end
  sprites = util.table.deepcopy(sprites)
  for _, sprite in pairs(sprites) do
    sprite.scale = (sprite.scale or 1) / 2
    if sprite.shift then
      sprite.shift = { sprite.shift[1] / 2, sprite.shift[2] / 2 }
    end
  end
  return sprites
end

local function unlocking_technology(recipe)
  for name, technology in pairs(data.raw.technology) do
    for _, effect in pairs(technology.effects or {}) do
      if effect.type == "unlock-recipe" and effect.recipe == recipe then
        return name
      end
    end
  end
end

for name, lane in pairs(tiers) do
  local splitter = data.raw.splitter[name]
  local item = data.raw.item[name]
  local recipe = data.raw.recipe[name]
  if splitter and item and recipe then
    local icons = util.table.deepcopy(item.icons or { { icon = item.icon, icon_size = item.icon_size } })
    table.insert(icons, overlay)

    local entity = util.table.deepcopy(template)
    entity.name = lane
    entity.hidden = nil
    entity.icons = icons
    entity.minable.result = lane
    entity.speed = splitter.speed
    entity.belt_animation_set = splitter.belt_animation_set
    entity.structure = half_size(splitter.structure)
    entity.structure_patch = half_size(splitter.structure_patch)
    entity.structure_animation_speed_coefficient = splitter.structure_animation_speed_coefficient
    local next_upgrade = splitter.next_upgrade
    entity.next_upgrade = next_upgrade and data.raw.splitter[next_upgrade] and tiers[next_upgrade] or nil

    local lane_item = util.table.deepcopy(template_item)
    lane_item.name = lane
    lane_item.hidden = nil
    lane_item.icons = icons
    lane_item.subgroup = item.subgroup
    lane_item.order = item.order .. "-lane"
    lane_item.place_result = lane

    data:extend({
      entity,
      lane_item,
      {
        type = "recipe",
        name = lane,
        enabled = recipe.enabled,
        ingredients = { { type = "item", name = name, amount = 1 } },
        results = { { type = "item", name = lane, amount = 2 } },
      },
    })

    local technology = unlocking_technology(name)
    if technology then
      bobmods.lib.tech.add_recipe_unlock(technology, lane)
    end
  end
end
