if settings.startup["bobmods-library-recipe-cleanup"].value == true then
  bobmods.lib.recipe.ingredients_cleanup()
end

-- Multipliers from the startup settings. Runs in final fixes so every mod's prototypes already exist.
local function multiplier(name)
  return settings.startup["bobmods-library-" .. name .. "-multiplier"].value
end
-- Counts never round down to 0 unless they started there.
local function scale_count(count, factor)
  return math.max(math.floor(count * factor + 0.5), math.min(count, 1))
end
local function scale_energy(energy, factor)
  local amount, unit = energy:match("^([%d%.]+)(%a*[JW])$")
  return tonumber(amount) * factor .. unit
end

-- Vanilla and Bob's prototypes only, so other mods' machines keep their own balance.
local function scale_own(types, vanilla_names, fields, factor)
  local vanilla = {}
  for _, name in pairs(vanilla_names) do
    vanilla[name] = true
  end
  for _, prototype_type in pairs(types) do
    for name, prototype in pairs(data.raw[prototype_type] or {}) do
      if vanilla[name] or name:find("^bob%-") then
        for _, field in pairs(fields) do
          local value = prototype[field]
          if type(value) == "string" then
            prototype[field] = scale_energy(value, factor)
          elseif value then
            prototype[field] = value * factor
          end
        end
      end
    end
  end
end

scale_own({ "assembling-machine", "furnace" }, {
  "assembling-machine-1",
  "assembling-machine-2",
  "assembling-machine-3",
  "chemical-plant",
  "oil-refinery",
  "centrifuge",
  "foundry",
  "electromagnetic-plant",
  "biochamber",
  "cryogenic-plant",
  "crusher",
  "stone-furnace",
  "steel-furnace",
  "electric-furnace",
  "recycler",
}, { "crafting_speed" }, multiplier("crafting-speed"))
-- Electric furnaces get a second multiplier on top.
for _, name in pairs({ "electric-furnace", "bob-electric-furnace-2", "bob-electric-furnace-3" }) do
  local furnace = data.raw.furnace[name]
  if furnace then
    furnace.crafting_speed = furnace.crafting_speed * multiplier("electric-furnace-speed")
  end
end
scale_own(
  { "mining-drill" },
  { "burner-mining-drill", "electric-mining-drill", "pumpjack", "big-mining-drill" },
  { "mining_speed" },
  multiplier("mining-speed")
)
scale_own({ "lab" }, { "lab", "biolab" }, { "researching_speed" }, multiplier("research-speed"))
scale_own(
  { "inserter" },
  { "burner-inserter", "inserter", "long-handed-inserter", "fast-inserter", "bulk-inserter", "stack-inserter" },
  { "rotation_speed", "extension_speed" },
  multiplier("inserter-speed")
)
scale_own({ "pump", "offshore-pump" }, { "pump", "offshore-pump" }, { "pumping_speed" }, multiplier("pump-speed"))
-- Boilers, heat sources and generators all scale, so building ratios stay the same.
scale_own(
  { "generator", "boiler", "reactor", "solar-panel", "burner-generator" },
  { "steam-engine", "steam-turbine", "boiler", "heat-exchanger", "nuclear-reactor", "heating-tower", "solar-panel" },
  { "fluid_usage_per_tick", "max_power_output", "energy_consumption", "consumption", "production" },
  multiplier("power")
)

-- Stacks of 1 stay 1: armor, blueprints and remotes can't stack.
local stack_size = multiplier("stack-size")
for item_type in pairs(defines.prototypes.item) do
  for _, item in pairs(data.raw[item_type] or {}) do
    if item.stack_size > 1 then
      item.stack_size = scale_count(item.stack_size, stack_size)
    end
  end
end

for _, storage_type in pairs({ "container", "logistic-container", "cargo-wagon", "car", "spider-vehicle" }) do
  for _, storage in pairs(data.raw[storage_type]) do
    storage.inventory_size = scale_count(storage.inventory_size, multiplier("inventory-size"))
  end
end

local fluid_capacity = multiplier("fluid-capacity")
for _, fluid_type in pairs({ "storage-tank", "pipe", "pipe-to-ground" }) do
  for _, fluid_storage in pairs(data.raw[fluid_type]) do
    fluid_storage.fluid_box.volume = fluid_storage.fluid_box.volume * fluid_capacity
  end
end
for _, wagon in pairs(data.raw["fluid-wagon"]) do
  wagon.capacity = wagon.capacity * fluid_capacity
end

local underground_reach = multiplier("underground-reach")
for _, belt in pairs(data.raw["underground-belt"]) do
  belt.max_distance = scale_count(belt.max_distance, underground_reach)
end
-- Every belt-like entity, Better Belt Balancer's hidden belts included, so balancers stay faster than the belts feeding them.
for _, belt_type in pairs({ "transport-belt", "underground-belt", "splitter", "lane-splitter", "loader", "loader-1x1", "linked-belt" }) do
  for _, belt in pairs(data.raw[belt_type]) do
    belt.speed = belt.speed * multiplier("belt-speed")
  end
end
for _, pipe in pairs(data.raw["pipe-to-ground"]) do
  for _, connection in pairs(pipe.fluid_box.pipe_connections) do
    if connection.max_underground_distance then
      connection.max_underground_distance = scale_count(connection.max_underground_distance, underground_reach)
    end
  end
end

local pole_reach = multiplier("pole-reach")
for _, pole in pairs(data.raw["electric-pole"]) do
  pole.maximum_wire_distance = math.min(pole.maximum_wire_distance * pole_reach, 64) -- engine maximum
  -- Keep the supply area on the tile grid: x.5 for 1x1 poles, whole numbers for 2x2.
  local grid_offset = pole.supply_area_distance % 1
  pole.supply_area_distance = math.floor(pole.supply_area_distance * pole_reach - grid_offset + 0.5) + grid_offset
end

for _, generator_type in pairs({ "solar-panel-equipment", "generator-equipment" }) do
  for _, generator in pairs(data.raw[generator_type]) do
    generator.power = scale_energy(generator.power, multiplier("power"))
  end
end

for _, battery_type in pairs({ "accumulator", "battery-equipment" }) do
  for _, battery in pairs(data.raw[battery_type]) do
    battery.energy_source.buffer_capacity =
      scale_energy(battery.energy_source.buffer_capacity, multiplier("battery-capacity"))
  end
end

local roboport_factor = multiplier("roboport")
for _, roboport in pairs(data.raw["roboport-equipment"]) do
  roboport.charging_energy = scale_energy(roboport.charging_energy, roboport_factor)
  roboport.construction_radius = scale_count(roboport.construction_radius, roboport_factor)
  if roboport.charging_station_count then
    roboport.charging_station_count = scale_count(roboport.charging_station_count, roboport_factor)
  end
  if roboport.robot_limit then
    roboport.robot_limit = scale_count(roboport.robot_limit, roboport_factor)
  end
  local energy_source = roboport.energy_source
  if energy_source.buffer_capacity then
    energy_source.buffer_capacity = scale_energy(energy_source.buffer_capacity, roboport_factor)
  end
  -- Faster charging draws more power, so the grid feed has to keep up.
  if energy_source.input_flow_limit then
    energy_source.input_flow_limit = scale_energy(energy_source.input_flow_limit, roboport_factor)
  end
end

-- Radius 1 marks chest-sized ports (robochest, charge port) meant to cover only themselves.
local function scale_radius(radius)
  return radius > 1 and radius * roboport_factor or radius
end
for _, roboport in pairs(data.raw["roboport"]) do
  roboport.logistics_radius = scale_radius(roboport.logistics_radius)
  roboport.construction_radius = scale_radius(roboport.construction_radius)
  if roboport.logistics_connection_distance then -- must stay >= logistics_radius
    roboport.logistics_connection_distance = scale_radius(roboport.logistics_connection_distance)
  end
  roboport.robot_slots_count = scale_count(roboport.robot_slots_count, roboport_factor)
  roboport.material_slots_count = scale_count(roboport.material_slots_count, roboport_factor)
  roboport.charging_energy = scale_energy(roboport.charging_energy, roboport_factor)

  -- Pads round down: a single pad has no neighbour to add one beside, so it stays 1.
  local pad_ratio = 1
  local pads = roboport.charging_offsets
  if (roboport.charging_station_count or 0) > 0 then
    local count = roboport.charging_station_count
    roboport.charging_station_count = math.max(math.floor(count * roboport_factor), 1)
    pad_ratio = roboport.charging_station_count / count
  elseif pads and #pads > 1 then
    local count = #pads
    local extra = math.floor(count * roboport_factor) - count
    -- New pads go halfway between neighbouring ones, spread around the list.
    for k = 0, extra - 1 do
      local i = math.floor(k * count / extra) + 1
      local a, b = pads[i], pads[i % count + 1]
      table.insert(pads, { ((a.x or a[1]) + (b.x or b[1])) / 2, ((a.y or a[2]) + (b.y or b[2])) / 2 })
    end
    pad_ratio = #pads / count
  end

  local energy_source = roboport.energy_source
  if energy_source.buffer_capacity then
    energy_source.buffer_capacity = scale_energy(energy_source.buffer_capacity, roboport_factor)
  end
  -- More pads, each charging faster: the grid feed has to cover both.
  if energy_source.input_flow_limit then
    energy_source.input_flow_limit = scale_energy(energy_source.input_flow_limit, roboport_factor * pad_ratio)
  end
end

-- U-235 odds from the setting, taken from U-238 so each craft still yields one item.
local uranium = {}
for _, result in pairs(data.raw.recipe["uranium-processing"].results) do
  uranium[result.name] = result
end
local uranium_235 = settings.startup["bobmods-library-uranium-235-percent"].value / 100
uranium["uranium-235"].probability = uranium_235
uranium["uranium-238"].probability = 1 - uranium_235

local robot_factor = multiplier("robot")
for _, robot_type in pairs({ "logistic-robot", "construction-robot" }) do
  for _, robot in pairs(data.raw[robot_type]) do
    robot.max_payload_size = scale_count(robot.max_payload_size, robot_factor)
    robot.max_energy = scale_energy(robot.max_energy, robot_factor)
    robot.speed = robot.speed * robot_factor
    if robot.max_speed then
      robot.max_speed = robot.max_speed * robot_factor
    end
  end
end

-- Module bonuses and beacon strength multiply together on beaconed machines. Penalties stay as they are.
local module_bonus = multiplier("module-bonus")
local bonus_when_negative = { consumption = true, pollution = true }
for _, module in pairs(data.raw.module) do
  for effect, value in pairs(module.effect) do
    local negative_is_bonus = bonus_when_negative[effect] or false
    -- Pollution-create modules exist to add pollution, so for them more is the bonus.
    if effect == "pollution" and module.category == "pollution-create" then
      negative_is_bonus = false
    end
    if (value < 0) == negative_is_bonus then
      -- The engine truncates past hundredths, so float noise like 0.58 * 1.5 = 0.8699... would lose a point.
      module.effect[effect] = math.floor(value * (100 * module_bonus) + 0.5) / 100
    end
  end
end
local beacon_effectivity = multiplier("beacon-effectivity")
for _, beacon in pairs(data.raw.beacon) do
  beacon.distribution_effectivity = beacon.distribution_effectivity * beacon_effectivity
  -- Measured from the beacon's edge: vanilla's 3 tiles at 4x is 12, a 27x27 area instead of 9x9.
  beacon.supply_area_distance = math.min(beacon.supply_area_distance * multiplier("beacon-range"), 64) -- engine maximum
  if beacon.distribution_effectivity_bonus_per_quality_level then
    beacon.distribution_effectivity_bonus_per_quality_level = beacon.distribution_effectivity_bonus_per_quality_level
      * beacon_effectivity
  end
end

-- Turrets, vehicle guns and laser defense: damage, fire rate, range and turn speed.
-- Worms are type "turret", so enemies are left out.
local turret_damage = multiplier("turret-damage")
local turret_fire_rate = multiplier("turret-fire-rate")
local turret_range = multiplier("turret-range")
local turret_turn_speed = multiplier("turret-turn-speed")
local function each(list) -- prototypes accept one table or an array of them
  return ipairs(list and (list.type and { list } or list) or {})
end
-- Shells stop at max_range and beams at max_length, so those have to grow with the range.
local function scale_reach(ammo_type)
  for _, action in each(ammo_type and ammo_type.action) do
    for _, delivery in each(action.action_delivery) do
      if delivery.max_range then
        delivery.max_range = delivery.max_range * turret_range
      end
      if delivery.max_length then
        delivery.max_length = delivery.max_length * turret_range
      end
    end
  end
end
local ammo_categories = {}
local function scale_attack(attack)
  attack.damage_modifier = (attack.damage_modifier or 1) * turret_damage
  attack.cooldown = attack.cooldown / turret_fire_rate
  attack.range = attack.range * turret_range
  scale_reach(attack.ammo_type)
  if attack.ammo_category then
    ammo_categories[attack.ammo_category] = true
  end
  for _, category in pairs(attack.ammo_categories or {}) do
    ammo_categories[category] = true
  end
end
for _, turret_type in pairs({ "ammo-turret", "electric-turret", "fluid-turret" }) do
  for _, turret in pairs(data.raw[turret_type]) do
    scale_attack(turret.attack_parameters)
    if turret.prepare_range then
      turret.prepare_range = turret.prepare_range * turret_range
    end
    if turret.rotation_speed then
      turret.rotation_speed = turret.rotation_speed * turret_turn_speed
    end
  end
end
-- Guns are shared (artillery turret and wagon, tank tiers, spidertrons), so collect them and scale each once.
local guns = {}
for _, gunner_type in pairs({ "artillery-turret", "artillery-wagon", "car", "spider-vehicle" }) do
  for _, gunner in pairs(data.raw[gunner_type]) do
    if gunner.turret_rotation_speed then
      gunner.turret_rotation_speed = gunner.turret_rotation_speed * turret_turn_speed
    end
    for _, gun in pairs(gunner.guns or { gunner.gun }) do
      guns[gun] = true
    end
  end
end
for gun in pairs(guns) do
  scale_attack(data.raw.gun[gun].attack_parameters)
end
for _, equipment in pairs(data.raw["active-defense-equipment"]) do
  if equipment.automatic then -- discharge defense is a manual area stun, not a turret
    scale_attack(equipment.attack_parameters)
  end
end
for _, ammo in pairs(data.raw.ammo) do
  if ammo_categories[ammo.ammo_category] then
    scale_reach(ammo.ammo_type)
  end
end
