local bobpump2 = table.deepcopy(data.raw.pump.pump)
bobpump2.name = "bob-pump-2"
bobpump2.minable.result = "bob-pump-2"
bobpump2.max_health = 220
bobpump2.next_upgrade = "bob-pump-3"
bobpump2.energy_usage = "50kW"
bobpump2.circuit_wire_max_distance = 10

local bobpump3 = table.deepcopy(data.raw.pump.pump)
bobpump3.name = "bob-pump-3"
bobpump3.minable.result = "bob-pump-3"
bobpump3.max_health = 260
bobpump3.next_upgrade = "bob-pump-4"
bobpump3.energy_usage = "65kW"
bobpump3.circuit_wire_max_distance = 12.5

local bobpump4 = table.deepcopy(data.raw.pump.pump)
bobpump4.name = "bob-pump-4"
bobpump4.minable.result = "bob-pump-4"
bobpump4.max_health = 300
bobpump4.next_upgrade = nil
bobpump4.energy_usage = "75kW"
bobpump4.circuit_wire_max_distance = 15

if mods["quality"] then
  data.raw.pump.pump.pumping_speed = 15
  bobpump2.pumping_speed = 30
  bobpump3.pumping_speed = 45
  bobpump4.pumping_speed = 60
else
  data.raw.pump.pump.pumping_speed = 30
  bobpump2.pumping_speed = 60
  bobpump3.pumping_speed = 90
  bobpump4.pumping_speed = 120
end

data:extend({ bobpump2, bobpump3, bobpump4 })

data.raw["offshore-pump"]["offshore-pump"].pumping_speed = 30
data.raw["offshore-pump"]["offshore-pump"].next_upgrade = "bob-offshore-pump-2"

local boboffshorepump2 = table.deepcopy(data.raw["offshore-pump"]["offshore-pump"])
boboffshorepump2.name = "bob-offshore-pump-2"
boboffshorepump2.minable.result = "bob-offshore-pump-2"
boboffshorepump2.max_health = 200
boboffshorepump2.next_upgrade = "bob-offshore-pump-3"
boboffshorepump2.pumping_speed = 60

local boboffshorepump3 = table.deepcopy(data.raw["offshore-pump"]["offshore-pump"])
boboffshorepump3.name = "bob-offshore-pump-3"
boboffshorepump3.minable.result = "bob-offshore-pump-3"
boboffshorepump3.max_health = 250
boboffshorepump3.next_upgrade = nil
boboffshorepump3.pumping_speed = 90

data:extend({ boboffshorepump2, boboffshorepump3 })
