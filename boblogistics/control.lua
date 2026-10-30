local mod_gui = require("mod-gui")

if not bobmods then
  bobmods = {}
end
if not bobmods.logistics then
  bobmods.logistics = {}
end
if not bobmods.logistics.inserters then
  bobmods.logistics.inserters = {}
end
if not bobmods.math then
  bobmods.math = {}
end

function bobmods.math.mod(number, div)
  if number < 0 then
    local newnumber = 0 - number
    local mod = newnumber % div
    return 0 - mod
  else
    return number % div
  end
end

function bobmods.math.floor(number)
  local num
  if number < 0 then
    num = number - 0.1
  else
    num = number + 0.1
  end
  return math.floor(num - bobmods.math.mod(num, 1))
end

function bobmods.math.round(number)
  local num
  if number < 0 then
    num = number - 0.5
  else
    num = number + 0.5
  end
  return math.floor(num - bobmods.math.mod(num, 1))
end

function bobmods.math.offset(number)
  local num = bobmods.math.mod(number, 1)
  if num < 0 then
    if num > -0.5 then
      return num
    else
      return num + 1
    end
  else
    if num < 0.5 then
      return num
    else
      return num - 1
    end
  end
end

bobmods.logistics.long_technology = "bob-long-inserters-1"
changed_position_event = script.generate_event_name()

bobmods.logistics.offset = 0.2

bobmods.logistics.inserters.range1 = {
  pickup = {
    { x = 0, y = -1 },
    { x = 1, y = 0 },
    { x = 0, y = 1 },
    { x = -1, y = 0 },
  },
  drop = {
    { x = 0, y = 1 },
    { x = -1, y = 0 },
    { x = 0, y = -1 },
    { x = 1, y = 0 },
  },
}

bobmods.logistics.inserters.range2 = {
  pickup = {
    { x = 0, y = -2 },
    { x = 2, y = 0 },
    { x = 0, y = 2 },
    { x = -2, y = 0 },
  },
  drop = {
    { x = 0, y = 2 },
    { x = -2, y = 0 },
    { x = 0, y = -2 },
    { x = 2, y = 0 },
  },
}

bobmods.logistics.inserters.offset_positions = {
  near = {
    { x = 0, y = -bobmods.logistics.offset },
    { x = bobmods.logistics.offset, y = 0 },
    { x = 0, y = bobmods.logistics.offset },
    { x = -bobmods.logistics.offset, y = 0 },
  },
  far = {
    { x = 0, y = bobmods.logistics.offset },
    { x = -bobmods.logistics.offset, y = 0 },
    { x = 0, y = -bobmods.logistics.offset },
    { x = bobmods.logistics.offset, y = 0 },
  },
}

function bobmods.logistics.normalise_tile_offset(tile_offset)
  local new_offset = { x = 0, y = 0 }
  if tile_offset.x > 0 then
    new_offset.x = bobmods.logistics.offset
  end
  if tile_offset.x < 0 then
    new_offset.x = -bobmods.logistics.offset
  end
  if tile_offset.y > 0 then
    new_offset.y = bobmods.logistics.offset
  end
  if tile_offset.y < 0 then
    new_offset.y = -bobmods.logistics.offset
  end
  return new_offset
end

function bobmods.logistics.set_range(position_in, range)
  local position = { x = 0, y = 0 }
  if position_in.x > 0.1 then
    position.x = range
  elseif position_in.x < -0.1 then
    position.x = -range
  else
    position.x = 0
  end
  if position_in.y > 0.1 then
    position.y = range
  elseif position_in.y < -0.1 then
    position.y = -range
  else
    position.y = 0
  end
  return position
end

function bobmods.logistics.create_global_table_basic()
  if not storage.bobmods then
    storage.bobmods = {}
  end
  if not storage.bobmods.logistics then
    storage.bobmods.logistics = {}
  end
  if not storage.bobmods.logistics.blacklist then
    storage.bobmods.logistics.blacklist = {}
  end
end

function bobmods.logistics.create_global_table(player_index)
  bobmods.logistics.create_global_table_basic()

  if not storage.bobmods.logistics[player_index] then
    storage.bobmods.logistics[player_index] = {}
  end
  if not storage.bobmods.logistics[player_index].enabled then
    storage.bobmods.logistics[player_index].enabled = false
  end
  if not storage.bobmods.logistics[player_index].long_in then
    storage.bobmods.logistics[player_index].long_in = false
  end
  if not storage.bobmods.logistics[player_index].show then
    storage.bobmods.logistics[player_index].show = false
  end
end

function bobmods.logistics.player_setup(player_index)
  bobmods.logistics.create_global_table(player_index)
  bobmods.logistics.create_gui_button(player_index)
end

function tech_unlocked(force, tech)
  if force.technologies[tech] then
    return force.technologies[tech].researched
  end
end

function bobmods.logistics.create_gui_button(player_index)
  if not script.active_mods["bobinserters"] then
    local player = game.players[player_index]

    -- remove legacy GUI
    if player.gui.top.bob_logistics_inserter_gui then
      player.gui.top.bob_logistics_inserter_gui.destroy()
    end

    -- remove legacy button
    if player.gui.top.bob_logistics_inserter_button then
      player.gui.top.bob_logistics_inserter_button.destroy()
    end

    if mod_gui.get_button_flow(player).bob_logistics_inserter_button then
      mod_gui.get_button_flow(player).bob_logistics_inserter_button.destroy()
    end

    local long_unlocked = tech_unlocked(player.force, bobmods.logistics.long_technology)
    if settings.startup["bobmods-logistics-inserteroverhaul"].value == true and long_unlocked then
      mod_gui.get_button_flow(player).add({
        type = "sprite-button",
        name = "bob_logistics_inserter_button",
        tooltip = { "gui.bob-inserter-open-gui" },
        sprite = "item/fast-inserter",
        style = "mod_gui_button",
      })
    end
  end
end

function bobmods.logistics.create_gui(player_index)
  local player = game.players[player_index]
  local long_unlocked = tech_unlocked(game.players[player_index].force, bobmods.logistics.long_technology)

  if player.gui.left.bob_logistics_inserter_gui then
    player.gui.left.bob_logistics_inserter_gui.destroy()
  end

  local gui = player.gui.left.add({ type = "frame", name = "bob_logistics_inserter_gui", direction = "vertical" })
  gui.style.bottom_padding = 8
  gui.style.vertically_stretchable = false
  gui.style.horizontally_stretchable = false

  gui.add({ type = "table", name = "table", column_count = 1 })

  if long_unlocked then
    gui.table.add({
      type = "checkbox",
      name = "bob_logistics_inserter_enabled",
      state = storage.bobmods.logistics[player_index].enabled,
      caption = { "gui.bob-logistics-enabled" },
    })
  end
  if storage.bobmods.logistics[player_index].enabled then
    if long_unlocked then
      gui.table.add({
        type = "checkbox",
        name = "bob_logistics_inserter_long_in",
        state = storage.bobmods.logistics[player_index].long_in,
        caption = { "gui.bob-logistics-long" },
      })
    end
  end
end

function bobmods.logistics.show_gui_options(player_index)
  local player = game.players[player_index]

  if not storage.bobmods then
    bobmods.logistics.player_setup(player_index)
  end

  if player.gui.left.bob_logistics_inserter_gui then
    player.gui.left.bob_logistics_inserter_gui.destroy()
  end

  if storage.bobmods.logistics[player_index].show then
    bobmods.logistics.create_gui(player_index)
  end
end

function bobmods.logistics.set_positions(entity, player_index)
  local enabled = storage.bobmods.logistics[player_index].enabled
  if enabled then
    local force = game.players[player_index].force

    local long_unlocked = tech_unlocked(force, bobmods.logistics.long_technology)

    local long_in = storage.bobmods.logistics[player_index].long_in

    local pickup_position =
      { x = entity.pickup_position.x - entity.position.x, y = entity.pickup_position.y - entity.position.y }
    local drop_full_position =
      { x = entity.drop_position.x - entity.position.x, y = entity.drop_position.y - entity.position.y }
    local drop_position = { x = bobmods.math.round(drop_full_position.x), y = bobmods.math.round(drop_full_position.y) }
    local drop_offset = bobmods.logistics.normalise_tile_offset({
      x = bobmods.math.offset(drop_full_position.x),
      y = bobmods.math.offset(drop_full_position.y),
    })

    if long_unlocked then
      if long_in then
        pickup_position = bobmods.logistics.set_range(pickup_position, 2)
        drop_position = bobmods.logistics.set_range(drop_position, 2)
      else
        pickup_position = bobmods.logistics.set_range(pickup_position, 1)
        drop_position = bobmods.logistics.set_range(drop_position, 1)
      end
    end

    local original_positions = { drop_position = entity.drop_position, pickup_position = entity.pickup_position }
    local new_positions = {
      drop_position = {
        x = entity.position.x + drop_position.x + drop_offset.x,
        y = entity.position.y + drop_position.y + drop_offset.y,
      },
      pickup_position = { x = entity.position.x + pickup_position.x, y = entity.position.y + pickup_position.y },
    }
    entity.drop_position = new_positions.drop_position
    entity.pickup_position = new_positions.pickup_position
    script.raise_event(
      changed_position_event,
      { entity = entity, new_positions = new_positions, original_positions = original_positions }
    ) -- Raise positions changed event.
  end
end

function bobmods.logistics.long_range(entity, player)
  local long_unlocked = tech_unlocked(player.force, bobmods.logistics.long_technology)
  if settings.startup["bobmods-logistics-inserteroverhaul"].value == true and long_unlocked then
    local pickup_position =
      { x = entity.pickup_position.x - entity.position.x, y = entity.pickup_position.y - entity.position.y }
    local drop_full_position =
      { x = entity.drop_position.x - entity.position.x, y = entity.drop_position.y - entity.position.y }
    local drop_position = { x = bobmods.math.round(drop_full_position.x), y = bobmods.math.round(drop_full_position.y) }
    local drop_offset = bobmods.logistics.normalise_tile_offset({
      x = bobmods.math.offset(drop_full_position.x),
      y = bobmods.math.offset(drop_full_position.y),
    })

    if pickup_position.x > 1.1 or pickup_position.x < -1.1 or pickup_position.y > 1.1 or pickup_position.y < -1.1 then
      pickup_position = bobmods.logistics.set_range(pickup_position, 1)
      drop_position = bobmods.logistics.set_range(drop_position, 1)
    else
      pickup_position = bobmods.logistics.set_range(pickup_position, 2)
      drop_position = bobmods.logistics.set_range(drop_position, 2)
    end

    local original_positions = { drop_position = entity.drop_position, pickup_position = entity.pickup_position }
    local new_positions = {
      drop_position = {
        x = entity.position.x + drop_position.x + drop_offset.x,
        y = entity.position.y + drop_position.y + drop_offset.y,
      },
      pickup_position = { x = entity.position.x + pickup_position.x, y = entity.position.y + pickup_position.y },
    }
    entity.drop_position = new_positions.drop_position
    entity.pickup_position = new_positions.pickup_position
    entity.direction = entity.direction -- set direction to force update
    script.raise_event(
      changed_position_event,
      { entity = entity, new_positions = new_positions, original_positions = original_positions }
    ) -- Raise positions changed event.
  end
end

function bobmods.logistics.check_range(event)
  local player = game.players[event.player_index]
  local entity = player.selected
  if
    entity
    and entity.type == "inserter"
    and player.can_reach_entity(entity)
    and not storage.bobmods.logistics.blacklist[entity.name]
  then
    bobmods.logistics.long_range(entity, player)
  end
end

script.on_load(function()
  if
    settings.startup["bobmods-logistics-inserteroverhaul"].value == true and not script.active_mods["bobinserters"]
  then
    script.on_event("bob-inserter-long", bobmods.logistics.check_range)
  end
end)

script.on_configuration_changed(function(event)
  for i, player in pairs(game.players) do
    bobmods.logistics.player_setup(player.index)
  end
  for index, force in pairs(game.forces) do
    force.reset_technology_effects()
  end
end)

script.on_init(function(event)
  for i, player in pairs(game.players) do
    bobmods.logistics.player_setup(player.index)
  end

  if
    settings.startup["bobmods-logistics-inserteroverhaul"].value == true and not script.active_mods["bobinserters"]
  then
    script.on_event("bob-inserter-long", bobmods.logistics.check_range)
  end
end)

script.on_event(defines.events.on_player_created, function(event)
  bobmods.logistics.player_setup(event.player_index)
end)

script.on_event(defines.events.on_player_joined_game, function(event)
  bobmods.logistics.player_setup(event.player_index)
end)

script.on_event(defines.events.on_gui_checked_state_changed, function(event)
  if not script.active_mods["bobinserters"] then
    if event.element.name == "bob_logistics_inserter_enabled" then
      storage.bobmods.logistics[event.player_index].enabled = event.element.state
      bobmods.logistics.create_gui(event.player_index)
    elseif event.element.name == "bob_logistics_inserter_long_in" then
      storage.bobmods.logistics[event.player_index].long_in = event.element.state
    end
  end
end)

-- Each underground channel is a copy named "<underground>-channel-<n>", see prototypes/underground-channels.lua.
-- Returns the channel 1 name and the channel of an underground that has channels.
function bobmods.logistics.underground_channel(entity)
  if entity.type ~= "underground-belt" then
    return nil
  end
  local base, channel = string.match(entity.name, "^(.+)%-channel%-(%d+)$")
  base = base or entity.name
  if prototypes.entity[base .. "-channel-2"] then
    return base, tonumber(channel) or 1
  end
end

-- The player's own underground with channels under the cursor, with its channel 1 name and channel.
function bobmods.logistics.selected_underground(player)
  local entity = player.selected
  if entity and entity.force == player.force then
    local base, channel = bobmods.logistics.underground_channel(entity)
    if base then
      return entity, base, channel
    end
  end
end

function bobmods.logistics.open_underground_channel_gui(player, entity)
  local base, current = bobmods.logistics.underground_channel(entity)
  if player.gui.screen.bob_underground_channel then
    player.gui.screen.bob_underground_channel.destroy()
  end
  local frame = player.gui.screen.add({
    type = "frame",
    name = "bob_underground_channel",
    caption = { "gui.bob-underground-channel" },
    tags = { surface = entity.surface.index, position = entity.position, name = entity.name },
  })
  local flow = frame.add({ type = "flow" })
  local channel = 1
  while channel == 1 or prototypes.entity[base .. "-channel-" .. channel] do
    local button = flow.add({
      type = "button",
      caption = tostring(channel),
      tags = { bob_underground_channel = channel },
      enabled = channel ~= current,
    })
    button.style.minimal_width = 40
    channel = channel + 1
  end
  frame.force_auto_center()
  player.opened = frame
end

-- Swapping the prototype makes the game re-pair this underground with undergrounds of the new channel.
function bobmods.logistics.set_underground_channel(entity, channel)
  local base = bobmods.logistics.underground_channel(entity)
  return entity.surface.create_entity({
    name = channel == 1 and base or base .. "-channel-" .. channel,
    position = entity.position,
    direction = entity.direction,
    quality = entity.quality,
    force = entity.force,
    type = entity.belt_to_ground_type,
    fast_replace = true,
    spill = false,
    raise_built = true,
  })
end

script.on_event("bob-underground-channel", function(event)
  local player = game.get_player(event.player_index)
  local entity = bobmods.logistics.selected_underground(player)
  if entity and player.is_cursor_empty() then
    bobmods.logistics.open_underground_channel_gui(player, entity)
  end
end)

-- Undergrounds have no settings, so the game's own copy and paste does nothing on them.
script.on_event("bob-underground-channel-copy", function(event)
  local player = game.get_player(event.player_index)
  if player.selected then
    -- Copying anything else forgets the channel, so pasting those settings doesn't also change undergrounds.
    local _, _, channel = bobmods.logistics.selected_underground(player)
    storage.underground_channel_copy = storage.underground_channel_copy or {}
    storage.underground_channel_copy[player.index] = channel
  end
end)

script.on_event("bob-underground-channel-paste", function(event)
  local player = game.get_player(event.player_index)
  local entity, _, current = bobmods.logistics.selected_underground(player)
  local channel = storage.underground_channel_copy and storage.underground_channel_copy[player.index]
  if entity and channel and channel ~= current and player.is_cursor_empty() then
    bobmods.logistics.set_underground_channel(entity, channel)
  end
end)

script.on_event(defines.events.on_gui_closed, function(event)
  if event.element and event.element.valid and event.element.name == "bob_underground_channel" then
    event.element.destroy()
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local channel = event.element.valid and event.element.tags.bob_underground_channel
  if channel then
    local frame = event.element.parent.parent
    local surface = game.get_surface(frame.tags.surface)
    local entity = surface and surface.find_entity(frame.tags.name, frame.tags.position)
    if entity then
      bobmods.logistics.set_underground_channel(entity, channel)
    end
    frame.destroy()
  end

  if not script.active_mods["bobinserters"] then
    if event.element.valid and event.element.name == "bob_logistics_inserter_button" then
      if storage.bobmods.logistics[event.player_index].show then
        storage.bobmods.logistics[event.player_index].show = false
      else
        storage.bobmods.logistics[event.player_index].show = true
      end
      bobmods.logistics.show_gui_options(event.player_index)
    end
  end
end)

script.on_event(defines.events.on_research_finished, function(event)
  if event.research.name == bobmods.logistics.long_technology then
    for i, player in pairs(event.research.force.players) do
      bobmods.logistics.create_gui_button(player.index)
      bobmods.logistics.show_gui_options(player.index)
    end
  end
end)

script.on_event(defines.events.on_built_entity, function(event)
  local player = game.players[event.player_index]
  local entity = event.entity

  local entity_name = entity.name
  if entity.type == "entity-ghost" then
    entity_name = entity.ghost_name
  end

  if
    not script.active_mods["bobinserters"]
    and (entity.type == "inserter" or (entity.type == "entity-ghost" and entity.ghost_type == "inserter"))
    and not storage.bobmods.logistics.blacklist[entity_name]
  then
    bobmods.logistics.set_positions(entity, event.player_index)
  end

  if
    settings.startup["bobmods-logistics-inserteroverhaul"].value == true
    and entity.type == "inserter"
    and entity.name == "long-handed-inserter"
  then
    entity.surface.create_entity({
      name = "bob-red-inserter",
      position = entity.position,
      force = entity.force,
      direction = entity.direction,
      fast_replace = true,
      spill = false,
    })
  end
end)

script.on_event(defines.events.on_robot_built_entity, function(event)
  local entity = event.entity
  if
    settings.startup["bobmods-logistics-inserteroverhaul"].value == true
    and entity.type == "inserter"
    and entity.name == "long-handed-inserter"
  then
    entity.surface.create_entity({
      name = "bob-red-inserter",
      position = entity.position,
      force = entity.force,
      direction = entity.direction,
      fast_replace = true,
      spill = false,
    })
  end
end)

-- Items on a belt or in an inserter's hand that a robot deconstructs are destroyed, not carried off to storage.
-- bobcutpaste loads first (see info.json), so a cut building's contents are already set aside by then.
script.on_event(defines.events.on_robot_pre_mined, function(event)
  local entity = event.entity
  if entity.type == "inserter" then
    entity.held_stack.clear()
    return
  end
  for i = 1, entity.get_max_transport_line_index() do
    entity.get_transport_line(i).clear()
  end
end, { { filter = "transport-belt-connectable" }, { filter = "type", type = "inserter" } })

remote.add_interface("boblogistics", {
  --[[
Pass this function the name of an inserter, and it will be ignored.
EG: remote.call("boblogistics", "blacklist_inserter", "burner-inserter") will blacklist the burner inserter.
]]
  --
  blacklist_inserter = function(data)
    bobmods.logistics.create_global_table_basic()
    storage.bobmods.logistics.blacklist[data] = true
  end,
  --[[
Pass this function a table of names of inserters, and they will be ignored.
EG: remote.call("boblogistics", "blacklist_inserters", {"burner-inserter"}) will blacklist the burner inserter.
]]
  --
  blacklist_inserters = function(data)
    bobmods.logistics.create_global_table_basic()
    for i, inserter in pairs(data) do
      storage.bobmods.logistics.blacklist[inserter] = true
    end
  end,
  --[[
Returns the ID number of the custom event
Triggered event returns the following table: {entity = entity, new_positions = {drop_position = {x,y}, pickup_position = {x,y}}, original_positions = {drop_position = {x,y}, pickup_position = {x,y}}}
]]
  --
  get_changed_position_event_id = function()
    return changed_position_event
  end,
})
