-- Undergrounds only pair with undergrounds of the same prototype, which is why weaving needs different tiers.
-- Give every buildable underground copies, one per channel, built and mined with the same item.
-- Clicking an underground opens a GUI (control.lua) that swaps it to the copy for the picked channel.
-- Channel 1 is the original underground.
local channels = 6
local numbered = { "direction_in", "direction_out", "direction_in_side_loading", "direction_out_side_loading" }

local placed_by = {}
for name, item in pairs(data.raw.item) do
  if item.place_result then
    placed_by[item.place_result] = name
  end
end

-- Turns a Sprite4Way into one layered sprite per direction, with the channel number on top.
local function with_number(sprite4way, number)
  if not sprite4way then
    return nil
  end
  local sheets = sprite4way.sheets or (sprite4way.sheet and { sprite4way.sheet })
  local result = {}
  for i, direction in ipairs({ "north", "east", "south", "west" }) do
    local layers = {}
    if sheets then
      for _, sheet in pairs(sheets) do
        local sprite = util.table.deepcopy(sheet)
        local width = sheet.width or (type(sheet.size) == "table" and sheet.size[1]) or sheet.size
        sprite.frames = nil
        sprite.x = (sheet.x or 0) + (i - 1) * width
        table.insert(layers, sprite)
      end
    else
      table.insert(layers, sprite4way[direction])
    end
    table.insert(layers, number)
    result[direction] = { layers = layers }
  end
  return result
end

local undergrounds = {}
for name, underground in pairs(data.raw["underground-belt"]) do
  if placed_by[name] and not underground.hidden then
    undergrounds[name] = underground
  end
end

for name, underground in pairs(undergrounds) do
  for channel = 2, channels do
    local icon = "__base__/graphics/icons/signal/signal_" .. channel .. ".png"
    local number = { filename = icon, size = 64, scale = 0.3, priority = "extra-high" }

    local entity = util.table.deepcopy(underground)
    entity.name = name .. "-channel-" .. channel
    entity.localised_name = {
      "entity-name.bob-underground-channel",
      underground.localised_name or { "entity-name." .. name },
      tostring(channel),
    }
    entity.icons =
      util.table.deepcopy(underground.icons or { { icon = underground.icon, icon_size = underground.icon_size } })
    table.insert(entity.icons, { icon = icon, icon_size = 64, scale = 0.25, shift = { 8, -8 } })
    entity.icon = nil
    -- Not hidden: the game refuses to upgrade hidden entities, which would break the upgrade planner.
    entity.hidden_in_factoriopedia = true
    entity.factoriopedia_alternative = name
    entity.placeable_by = { item = placed_by[name], count = 1 }
    local next_upgrade = underground.next_upgrade
    entity.next_upgrade = undergrounds[next_upgrade] and next_upgrade .. "-channel-" .. channel
    if entity.structure then
      for _, key in pairs(numbered) do
        entity.structure[key] = with_number(underground.structure[key], number)
      end
    end
    data:extend({ entity })
  end
end

data:extend({
  {
    type = "custom-input",
    name = "bob-underground-channel",
    key_sequence = "",
    linked_game_control = "open-gui",
  },
  {
    type = "custom-input",
    name = "bob-underground-channel-copy",
    key_sequence = "",
    linked_game_control = "copy-entity-settings",
  },
  {
    type = "custom-input",
    name = "bob-underground-channel-paste",
    key_sequence = "",
    linked_game_control = "paste-entity-settings",
  },
})
