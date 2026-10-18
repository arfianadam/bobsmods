-- Cut and paste (Ctrl+X) normally sends a building's contents off with the robot that mines it.
-- This keeps them aside and puts them into the pasted copy instead: items, fluids and an inserter's held item.
--
-- storage.moves[old unit_number] = {
--   player_index, ghosts = pasted ghosts still waiting to be built,
--   target = new building waiting for the old one to be mined,
--   stash = { [inventory index or "hand"] = script inventory } once the old one is mined,
--   fluids = { [fluidbox index] = Fluid } once the old one is mined,
--   surface, position, force = where the old building stood,
-- }
-- storage.ghosts[on_object_destroyed registration number] = old unit_number
-- storage.cutting[player_index] = true while the cut tool is in that player's cursor

local TAG = "bobcutpaste_from"

local function inventories(entity)
  local list = {}
  for index = 1, entity.get_max_inventory_index() do
    local inventory = entity.get_inventory(index)
    -- modules are already in the blueprint, moving them as well would double them up
    if inventory and not (inventory.name and inventory.name:find("modules")) then
      list[index] = inventory
    end
  end
  return list
end

local function can_hold(entity)
  return next(inventories(entity)) or entity.type == "inserter" or #entity.fluidbox > 0
end

-- Writing a fluidbox sets its whole fluid segment, while reading gives only this box's share of it
local function segment_amount(fluidbox, index, name)
  local segment = fluidbox.get_fluid_segment_contents(index)
  local current = fluidbox[index]
  return segment and segment[name] or current and current.amount or 0
end

local function add_fluid(fluidbox, index, fluid)
  if index > #fluidbox then
    return
  end
  local current = fluidbox[index]
  -- shortcut: the fluid is lost when the pasted copy joins a segment of another fluid, or overflows it
  if current and current.name ~= fluid.name then
    return
  end
  local amount = segment_amount(fluidbox, index, fluid.name)
  local temperature = current
      and (amount * current.temperature + fluid.amount * fluid.temperature) / (amount + fluid.amount)
    or fluid.temperature
  fluidbox[index] = { name = fluid.name, amount = amount + fluid.amount, temperature = temperature }
end

local function find_blueprint(event)
  local player = game.get_player(event.player_index)
  for _, stack in pairs({ event.stack, player.blueprint_to_setup, player.cursor_stack }) do
    if stack.valid_for_read and stack.is_blueprint and stack.is_blueprint_setup() then
      return stack
    end
  end
end

-- Puts the stash into target, spilling what doesn't fit (or everything when there's no target)
-- on the ground, marked for deconstruction so robots collect it.
local function finish(unit, target)
  local move = storage.moves[unit]
  storage.moves[unit] = nil
  if not move.stash then
    return
  end
  target = target and target.valid and target or nil
  for index, source in pairs(move.stash) do
    local destination = target and index ~= "hand" and target.get_inventory(index)
    if target and index == "hand" then
      target.held_stack.transfer_stack(source[1])
    elseif destination then
      for i = 1, #source do
        local stack = source[i]
        if stack.valid_for_read and i <= #destination then
          destination[i].transfer_stack(stack)
        end
        if stack.valid_for_read then
          local inserted = destination.insert(stack)
          if inserted == stack.count then
            stack.clear()
          else
            stack.count = stack.count - inserted
          end
        end
      end
    end
    local at = target or move
    if not source.is_empty() and at.surface.valid then
      at.surface.spill_inventory({ position = at.position, inventory = source, force = at.force, allow_belts = false })
    end
    source.destroy()
  end
  -- shortcut: without a target (the paste was never built) the fluid is lost, like a plain deconstruction
  for index, fluid in pairs(target and move.fluids or {}) do
    add_fluid(target.fluidbox, index, fluid)
  end
end

local function on_cut(event)
  if not storage.cutting[event.player_index] then
    return
  end
  local blueprint = find_blueprint(event)
  if not blueprint then
    return
  end
  for index, entity in pairs(event.mapping.get()) do
    local unit = entity.valid and entity.unit_number
    if unit and can_hold(entity) then
      blueprint.set_blueprint_entity_tag(index, TAG, unit)
      storage.moves[unit] = { player_index = event.player_index, ghosts = 0 }
    end
  end
end

local function on_built(event)
  local entity = event.entity
  -- pasting a blueprint raises on_built_entity without tags, they're only on the ghost itself
  local tags = event.tags or (entity.type == "entity-ghost" and entity.tags)
  local unit = tags and tags[TAG]
  local move = unit and storage.moves[unit]
  if not move then
    return
  end
  if entity.type == "entity-ghost" then
    storage.ghosts[script.register_on_object_destroyed(entity)] = unit
    move.ghosts = move.ghosts + 1
  elseif move.stash then
    finish(unit, entity)
  else
    move.target = entity
  end
end

local function on_pre_mined(event)
  local entity = event.entity
  local unit = entity.unit_number
  local move = storage.moves[unit]
  -- robots empty a container over several trips, each raising this event: the first one takes everything
  if not move or move.stash then
    return
  end
  move.stash = {}
  for index, inventory in pairs(inventories(entity)) do
    if not inventory.is_empty() then
      local stash = game.create_inventory(#inventory)
      for i = 1, #inventory do
        if inventory[i].valid_for_read then
          stash[i].transfer_stack(inventory[i])
        end
      end
      move.stash[index] = stash
    end
  end
  if entity.type == "inserter" and entity.held_stack.valid_for_read then
    move.stash.hand = game.create_inventory(1)
    move.stash.hand[1].transfer_stack(entity.held_stack)
  end
  move.fluids = {}
  local fluidbox = entity.fluidbox
  for index = 1, #fluidbox do
    local fluid = fluidbox[index]
    if fluid then
      -- take only this building's share, the rest of a connected pipeline stays put
      local rest = segment_amount(fluidbox, index, fluid.name) - fluid.amount
      fluidbox[index] = rest > 0 and { name = fluid.name, amount = rest, temperature = fluid.temperature } or nil
      move.fluids[index] = fluid
    end
  end
  move.surface, move.position, move.force = entity.surface, entity.position, entity.force
  if move.target then
    finish(unit, move.target)
  end
end

local function on_cancelled_deconstruction(event)
  local unit = event.entity.unit_number
  local move = storage.moves[unit]
  if move and not move.stash then
    storage.moves[unit] = nil
  end
end

-- A pasted ghost went away. If it was built, on_built already took over; otherwise give up on it.
local function on_object_destroyed(event)
  local unit = storage.ghosts[event.registration_number]
  storage.ghosts[event.registration_number] = nil
  local move = unit and storage.moves[unit]
  if not move then
    return
  end
  move.ghosts = move.ghosts - 1
  if move.ghosts == 0 and not move.target then
    finish(unit)
  end
end

-- The cut blueprint left the cursor: anything it didn't paste stays a plain deconstruction.
local function on_cursor_changed(event)
  local player = game.get_player(event.player_index)
  local cursor = player.cursor_stack
  -- Ctrl+X raises on_player_setup_blueprint with item "blueprint", so the cut tool is noticed here instead,
  -- while it sits in the cursor during the drag
  storage.cutting[event.player_index] = cursor and cursor.valid_for_read and cursor.name == "cut-paste-tool" or nil
  if player.is_cursor_blueprint() then
    return
  end
  for unit, move in pairs(storage.moves) do
    if move.player_index == event.player_index and move.ghosts == 0 and not move.target then
      finish(unit)
    end
  end
end

local function init()
  storage.moves = storage.moves or {}
  storage.ghosts = storage.ghosts or {}
  storage.cutting = storage.cutting or {}
end

script.on_init(init)
script.on_configuration_changed(init)

script.on_event(defines.events.on_player_setup_blueprint, on_cut)
script.on_event({
  defines.events.on_built_entity,
  defines.events.on_robot_built_entity,
  defines.events.on_space_platform_built_entity,
  defines.events.script_raised_revive,
}, on_built)
script.on_event({
  defines.events.on_pre_player_mined_item,
  defines.events.on_robot_pre_mined,
  defines.events.on_space_platform_pre_mined,
}, on_pre_mined)
script.on_event(defines.events.on_cancelled_deconstruction, on_cancelled_deconstruction)
script.on_event(defines.events.on_object_destroyed, on_object_destroyed)
script.on_event(defines.events.on_player_cursor_stack_changed, on_cursor_changed)
