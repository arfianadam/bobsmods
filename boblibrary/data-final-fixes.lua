if settings.startup["bobmods-library-recipe-cleanup"].value == true then
  bobmods.lib.recipe.ingredients_cleanup()
end

-- Capacities at 150%. Runs in final fixes so every mod's prototypes already exist.
local function scale_count(count)
  return math.floor(count * 1.5 + 0.5)
end
local function scale_energy(energy, factor)
  local amount, unit = energy:match("^([%d%.]+)(%a*[JW])$")
  return tonumber(amount) * (factor or 1.5) .. unit
end

-- Stacks of 1 stay 1: armor, blueprints and remotes can't stack.
for item_type in pairs(defines.prototypes.item) do
  for _, item in pairs(data.raw[item_type] or {}) do
    if item.stack_size > 1 then
      item.stack_size = scale_count(item.stack_size)
    end
  end
end

for _, storage_type in pairs({ "container", "logistic-container", "cargo-wagon", "car", "spider-vehicle" }) do
  for _, storage in pairs(data.raw[storage_type]) do
    storage.inventory_size = scale_count(storage.inventory_size)
  end
end

for _, fluid_type in pairs({ "storage-tank", "pipe", "pipe-to-ground" }) do
  for _, fluid_storage in pairs(data.raw[fluid_type]) do
    fluid_storage.fluid_box.volume = fluid_storage.fluid_box.volume * 1.5
  end
end
for _, wagon in pairs(data.raw["fluid-wagon"]) do
  wagon.capacity = wagon.capacity * 1.5
end

for _, belt in pairs(data.raw["underground-belt"]) do
  belt.max_distance = scale_count(belt.max_distance)
end
-- Every belt-like entity, Better Belt Balancer's hidden belts included, so balancers stay faster than the belts feeding them.
for _, belt_type in pairs({ "transport-belt", "underground-belt", "splitter", "lane-splitter", "loader", "loader-1x1", "linked-belt" }) do
  for _, belt in pairs(data.raw[belt_type]) do
    belt.speed = belt.speed * 1.5
  end
end
for _, pipe in pairs(data.raw["pipe-to-ground"]) do
  for _, connection in pairs(pipe.fluid_box.pipe_connections) do
    if connection.max_underground_distance then
      connection.max_underground_distance = scale_count(connection.max_underground_distance)
    end
  end
end

for _, pole in pairs(data.raw["electric-pole"]) do
  pole.maximum_wire_distance = math.min(pole.maximum_wire_distance * 1.5, 64) -- engine maximum
  -- Keep the supply area on the tile grid: x.5 for 1x1 poles, whole numbers for 2x2.
  local grid_offset = pole.supply_area_distance % 1
  pole.supply_area_distance = math.floor(pole.supply_area_distance * 1.5 - grid_offset + 0.5) + grid_offset
end

for _, generator_type in pairs({ "solar-panel-equipment", "generator-equipment" }) do
  for _, generator in pairs(data.raw[generator_type]) do
    generator.power = scale_energy(generator.power)
  end
end

for _, battery_type in pairs({ "accumulator", "battery-equipment" }) do
  for _, battery in pairs(data.raw[battery_type]) do
    battery.energy_source.buffer_capacity = scale_energy(battery.energy_source.buffer_capacity)
  end
end

for _, roboport in pairs(data.raw["roboport-equipment"]) do
  roboport.charging_energy = scale_energy(roboport.charging_energy)
  roboport.construction_radius = scale_count(roboport.construction_radius)
  if roboport.charging_station_count then
    roboport.charging_station_count = scale_count(roboport.charging_station_count)
  end
  if roboport.robot_limit then
    roboport.robot_limit = scale_count(roboport.robot_limit)
  end
  local energy_source = roboport.energy_source
  if energy_source.buffer_capacity then
    energy_source.buffer_capacity = scale_energy(energy_source.buffer_capacity)
  end
  -- Faster charging draws more power, so the grid feed has to keep up.
  if energy_source.input_flow_limit then
    energy_source.input_flow_limit = scale_energy(energy_source.input_flow_limit)
  end
end

-- Radius 1 marks chest-sized ports (robochest, charge port) meant to cover only themselves.
local function scale_radius(radius)
  return radius > 1 and radius * 1.5 or radius
end
for _, roboport in pairs(data.raw["roboport"]) do
  roboport.logistics_radius = scale_radius(roboport.logistics_radius)
  roboport.construction_radius = scale_radius(roboport.construction_radius)
  if roboport.logistics_connection_distance then -- must stay >= logistics_radius
    roboport.logistics_connection_distance = scale_radius(roboport.logistics_connection_distance)
  end
  roboport.robot_slots_count = scale_count(roboport.robot_slots_count)
  roboport.material_slots_count = scale_count(roboport.material_slots_count)
  roboport.charging_energy = scale_energy(roboport.charging_energy)

  -- Pads round down: a single pad has no neighbour to add one beside, so it stays 1.
  local pad_ratio = 1
  local pads = roboport.charging_offsets
  if (roboport.charging_station_count or 0) > 0 then
    local count = roboport.charging_station_count
    roboport.charging_station_count = math.floor(count * 1.5)
    pad_ratio = roboport.charging_station_count / count
  elseif pads and #pads > 1 then
    local count = #pads
    local extra = math.floor(count * 1.5) - count
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
    energy_source.buffer_capacity = scale_energy(energy_source.buffer_capacity)
  end
  -- More pads, each charging faster: the grid feed has to cover both.
  if energy_source.input_flow_limit then
    energy_source.input_flow_limit = scale_energy(energy_source.input_flow_limit, 1.5 * pad_ratio)
  end
end

-- U-235 odds at 5%, taken from U-238 so each craft still yields one item.
local uranium = {}
for _, result in pairs(data.raw.recipe["uranium-processing"].results) do
  uranium[result.name] = result
end
uranium["uranium-235"].probability = 0.05
uranium["uranium-238"].probability = 0.95

for _, robot_type in pairs({ "logistic-robot", "construction-robot" }) do
  for _, robot in pairs(data.raw[robot_type]) do
    robot.max_payload_size = scale_count(robot.max_payload_size)
    robot.max_energy = scale_energy(robot.max_energy)
    robot.speed = robot.speed * 1.5
    if robot.max_speed then
      robot.max_speed = robot.max_speed * 1.5
    end
  end
end

-- Module bonuses and beacon strength at 150%, so beaconed bonuses land at 225%. Penalties stay as they are.
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
      module.effect[effect] = math.floor(value * 150 + 0.5) / 100
    end
  end
end
for _, beacon in pairs(data.raw.beacon) do
  beacon.distribution_effectivity = beacon.distribution_effectivity * 1.5
  -- 12 tiles out from the beacon's edge: a 27x27 area instead of 9x9.
  beacon.supply_area_distance = 12
  if beacon.distribution_effectivity_bonus_per_quality_level then
    beacon.distribution_effectivity_bonus_per_quality_level = beacon.distribution_effectivity_bonus_per_quality_level * 1.5
  end
end

-- Turrets, vehicle guns and laser defense at 125% damage and fire rate, 150% turn speed and range.
-- Worms are type "turret", so enemies are left out.
local function each(list) -- prototypes accept one table or an array of them
  return ipairs(list and (list.type and { list } or list) or {})
end
-- Shells stop at max_range and beams at max_length, so those have to grow with the range.
local function scale_reach(ammo_type)
  for _, action in each(ammo_type and ammo_type.action) do
    for _, delivery in each(action.action_delivery) do
      if delivery.max_range then
        delivery.max_range = delivery.max_range * 1.5
      end
      if delivery.max_length then
        delivery.max_length = delivery.max_length * 1.5
      end
    end
  end
end
local ammo_categories = {}
local function scale_attack(attack)
  attack.damage_modifier = (attack.damage_modifier or 1) * 1.25
  attack.cooldown = attack.cooldown / 1.25
  attack.range = attack.range * 1.5
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
      turret.prepare_range = turret.prepare_range * 1.5
    end
    if turret.rotation_speed then
      turret.rotation_speed = turret.rotation_speed * 1.5
    end
  end
end
-- Guns are shared (artillery turret and wagon, tank tiers, spidertrons), so collect them and scale each once.
local guns = {}
for _, gunner_type in pairs({ "artillery-turret", "artillery-wagon", "car", "spider-vehicle" }) do
  for _, gunner in pairs(data.raw[gunner_type]) do
    if gunner.turret_rotation_speed then
      gunner.turret_rotation_speed = gunner.turret_rotation_speed * 1.5
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
