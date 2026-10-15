if settings.startup["bobmods-library-recipe-cleanup"].value == true then
  bobmods.lib.recipe.ingredients_cleanup()
end

-- Capacities at 150%. Runs in final fixes so every mod's prototypes already exist.
local function scale_count(count)
  return math.floor(count * 1.5 + 0.5)
end
local function scale_energy(energy)
  local amount, unit = energy:match("^([%d%.]+)(%a*[JW])$")
  return tonumber(amount) * 1.5 .. unit
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

for _, battery_type in pairs({ "accumulator", "battery-equipment" }) do
  for _, battery in pairs(data.raw[battery_type]) do
    battery.energy_source.buffer_capacity = scale_energy(battery.energy_source.buffer_capacity)
  end
end

for _, robot_type in pairs({ "logistic-robot", "construction-robot" }) do
  for _, robot in pairs(data.raw[robot_type]) do
    robot.max_payload_size = scale_count(robot.max_payload_size)
    robot.max_energy = scale_energy(robot.max_energy)
  end
end
