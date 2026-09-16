local ccexpect = require "cc.expect"
local expect, range = ccexpect.expect, ccexpect.range
local serialization = require "serialization"
local hasJson, json = pcall(require, "dkjson")

--- @alias ValidComparison "<" | "=" | ">"
--- @alias ValidExactness "=" | ">"
--- @alias ValidTime "t" | "s" | "m"
--- @alias ValidIntervals "daily" | "12h" | "6h" | "4h" | "3h" | "2h" | "hourly" | "45m" | "30m" | "15m"
local valid_comparison = { ["<"] = 1, ["="] = 2, [">"] = 0 }
local valid_exactness = { ["="] = 0, [">"] = 1 }
local valid_time = { t = 0, s = 1, m = 2 }
local valid_intervals = {
   daily = 0,
   ["12h"] = 1,
   ["6h"] = 2,
   ["4h"] = 3,
   ["3h"] = 4,
   ["2h"] = 5,
   hourly = 6,
   ["45m"] = 7,
   ["30m"] = 8,
   ["15m"] = 9
}

--- @class Scheduler
--- @field cyclic boolean
--- @field entries table
local Scheduler = {}

--- A utility helper to make code more readable.
--- Should be used as the "any item/fluid" placeholder.
--- ```lua
--- s:item(Scheduler.any, "<", 64)
---  :fluid(Scheduler.any, ">", 200)
--- ```
Scheduler.any = "minecraft:air"

--- Create new Scheduler
--- @param data boolean|Scheduler If the schedule should be cyclic, or Scheduler table.
--- @return Scheduler
--- ```lua
--- local s = Scheduler.new(true)
--- s:to("Station A")
---     :wait(1, "m")
---     :OR():passengers(">", 1):wait(5)
--- s:to("Station B")
---     :passengers("=", 0):wait(5):passengers("=", 0)
--- station.setSchedule(s)
--- ```
--- ```lua
--- station.setSchedule(Scheduler.new(true)
---     :to("Station A")
---     :wait(1, "m")
---     :OR():passengers(">", 1):wait(5)
---     :to("Station B")
---     :passengers("=", 0):wait(5):passengers("=", 0))
--- ```
--- ```lua
--- station.setSchedule(Scheduler.new(true)
---     :to("Station A"):wait(1, "m"):OR():passengers(">", 1):wait(5)
---     :to("Station B"):passengers("=", 0):wait(5):passengers("=", 0))
--- ```
function Scheduler.new(data)
   expect(1, data, "boolean", "table")
   local initial = type(data) == "boolean" and { cyclic = data, entries = {} } or data --[[@as table]]
   -- deep copy initial.ctx if it exists because pointing a metatable
   -- towards a table that was created and interacted with outside
   -- our view doesn't seem like a good idea
   local station, condition = 0, 0
   if initial.ctx then
      station, condition = initial.ctx.station, initial.ctx.condition
   end
   -- create a double metatable system where intial.__index points
   -- to context_wrapper and then context_wrapper.__index points
   -- to Scheduler
   --
   -- This way initial.ctx can be written to and it's state kept
   -- seperate from other schedules, but it won't be read by
   -- station.getSchedule() (which would break things)
   local context_wrapper = setmetatable(
      { ctx = { station = station, condition = condition } },
      { __index = Scheduler }
   )
   initial = setmetatable(initial, { __index = context_wrapper })
   return initial
end

--- Append a generic station entry.
--- @param id string The ID of the instruction
--- @param data table Data associated with the instruction, see docs
function Scheduler:entry(id, data)
   expect(1, id, "string")
   expect(2, data, "table")
   self.ctx.station = self.ctx.station + 1
   self.ctx.condition = 1
   self.entries[self.ctx.station] = {
      instruction = { id = id, data = data },
      conditions = {}
   }
   return self
end

--- Append a generic condition entry.
--- @param id string The ID of the condition
--- @param data table Data associated with the condition, see docs
function Scheduler:condition(id, data)
   expect(1, id, "string")
   expect(2, data, "table")
   local conds = self.entries[self.ctx.station].conditions
   conds[self.ctx.condition] = conds[self.ctx.condition] or {}
   table.insert(conds[self.ctx.condition], { id = id, data = data })
   return self
end

--- Set the stage for an OR (alternative) condition.
function Scheduler:OR()
   self.ctx.condition = self.ctx.condition + 1
   return self
end

--- This should only be used for testing Scheduler.
--- To set the schedule, just do it- `station.setSchedule(Scheduler:new(true):to(":3"))`.
--- Will remove some stuff, so using this Scheduler instance after is not recommended.
--- @param json boolean Use JSON?
--- @return string
function Scheduler:serialize(json)
   self.ctx = nil
   if json and !hasJson then
      error("JSON not available (requires DKJSON)", 1)
   end
   return json and json.encode(self) or serialization.serialize(self)
end

--- Moves the train to the chosen train station. This instruction must have at least one condition.
--- @param name string The name of the station to travel to. Can include * as a wildcard.
function Scheduler:to(name)
   expect(1, name, "string")
   return self:entry("create:destination", { text = name })
end

--- Deliver first package in cargo. Drives to the first station with the correct postbox.
function Scheduler:deliverPackage()
   return self:entry("create:package_delivery", {})
end

--- Fetch a package adressed to address. Drives to a postbox with an undelivered item. This instruction cannot have conditions.
--- @param address string The address of the package.
function Scheduler:fetchPackage(address)
   expect(1, address, "string")
   return self:entry("create:package_retrieval", { text = address })
end

--- Renames the schedule. This name shows up on display link targets. This instruction cannot have conditions.
--- @param name string The name to rename the schedule to.
function Scheduler:rename(name)
   expect(1, name, "string")
   return self:entry("create:rename", { text = name })
end

--- Changes the current Schedule Section. This instruction cannot have conditions.
--- See https://github.com/MisterJulsen/Create-Train-Navigator/wiki/Train-Schedule-Sections
--- @param group string The filter group to use.
--- @param line string The line this train should be grouped into.
--- @param includeStart boolean Wether to include the start of the next section; if true you will be able to navigate between regions.
--- @param allow boolean If true, this hides the train from a section.
--- @*requires* Create Railways Navigator
function Scheduler:section(group, line, includeStart, allow)
   expect(1, group, "string")
   expect(2, line, "string")
   expect(3, includeStart, "boolean")
   expect(4, allow, "boolean")
   return self:entry("createrailwaysnavigator:travel_section",
      { train_group = group, train_line = line, include_previous_station = includeStart, usable = allow })
end

--- Changes the throttle of the train. This instruction cannot have conditions.
--- @param to number The throttle to set the train to. Must be an integer within the range of [5..100].
function Scheduler:throttle(to)
   expect(1, to, "number")
   range(to, 5, 100)
   return self:entry("create:throttle", { value = to })
end

--- Moves the train to the chosen train station without stopping. This instruction cannot have conditions.
--- @param name string The name of the station to travel to. Can include * as a wildcard.
--- @*requires* Create Steam 'n' Rails
function Scheduler:through(name)
   expect(1, name, "string")
   return self:entry("railways:waypoint_destination", { text = name })
end

--- Triggers a redstone link. This instruction cannot have conditions.
--- @param a string The first item used for the frequency.
--- @param b string The second item used for the frequency.
--- @param level number The redstone power level to send.
--- @see Scheduler.getlink To listen to a redstone link.
--- @*requires* Create Steam 'n' Rails
function Scheduler:setlink(a, b, level)
   expect(1, a, "string")
   expect(2, b, "string")
   expect(3, level, "number")
   return self:entry("railways:redstone_link",
      { frequency = { { id = a, count = 1 }, { id = b, count = 1 } }, power = level })
end

--- Reset timings for the current train. This instruction cannot have conditions.
--- See https://github.com/MisterJulsen/Create-Train-Navigator/wiki/Scheduled-Time-and-Real-Time \
--- @*requires* Create Railways Navigator
function Scheduler:fixtimings()
   return self:entry("createrailwaysnavigator:reset_timings", {})
end

--- Wait for a set delay.
--- @param len number The amount of time to wait for.
--- @param unit nil|ValidTime The unit of time.
function Scheduler:wait(len, unit)
   expect(1, len, "number")
   expect(2, unit, "string", "nil")
   unit = unit or "s"
   return self:condition("create:delay", { value = len, time_unit = valid_time[unit] })
end

--- Wait for a time of day, then repeat at a specified interval.
--- @param hour number The hour of the day to wait for in a 24-hour format. Must be an integer within the range of [0..23].
--- @param minute number The minute of the hour to wait for. Must be an integer within the range of [0..59].
--- @param rotation ValidIntervals The interval to repeat at after the time of day has been met. Check the rotation table below for valid values. Must be an integer within the range of [0..9].
function Scheduler:time(hour, minute, rotation)
   expect(1, hour, "number")
   expect(2, minute, "number")
   expect(3, rotation, "string")
   range(hour, 0, 23)
   range(minute, 0, 59)
   return self:condition("create:time_of_day", { hour = hour, minute = minute, rotation = valid_intervals[rotation] })
end

--- Wait for a certain amount of a specific fluid to be loaded onto the train.
--- @param item string The bucket item of the fluid.
--- @param operator ValidComparison Whether the condition should wait for the train to be loaded above the threshold, below the threshold or exactly at the threshold.
--- @param threshold number The threshold in number of buckets of fluid. Must be a positive integer.
function Scheduler:fluid(item, operator, threshold)
   expect(1, item, "string")
   expect(2, operator, "string")
   expect(3, threshold, "number")
   return self:condition("create:fluid_threshold",
      { bucket = { id = item, count = 1 }, threshold = tostring(threshold), operator = valid_comparison[operator], measure = 0 })
end

--- Wait for a certain amount of a specific item to be loaded onto the train.
--- @param item string The item.
--- @param operator ValidComparison Whether the condition should wait for the train to be loaded above the threshold, below the threshold or exactly at the threshold.
--- @param threshold number The threshold of items. Must be a positive integer.
function Scheduler:item(item, operator, threshold)
   expect(1, item, "string")
   expect(2, operator, "string")
   expect(3, threshold, "number")
   return self:condition("create:item_threshold",
      { bucket = { id = item, count = 1 }, threshold = tostring(threshold), operator = valid_comparison[operator], measure = 0 })
end

--- Wait for a redstone link to be powered.
--- @param a string The first item used for the frequency.
--- @param b string The second item used for the frequency.
--- @param powered boolean Whether the redstone link should be powered or not to meet the condition.
--- @see Scheduler.setlink To trigger a redstone link.
function Scheduler:getlink(a, b, powered)
   expect(1, a, "string")
   expect(2, b, "string")
   expect(3, powered, "boolean")
   return self:condition("create:redstone_link",
      { frequency = { { id = a, count = 1 }, { id = b, count = 1 } }, inverted = (powered and 0 or 1) })
end

--- Wait for a certain amount of players to be seated on the train.
--- @param operator ValidExactness Whether the seated player count has to be exact to meet the condition.
--- @param count number The number of players to be seated on the train. Must be a positive integer.
function Scheduler:passengers(operator, count)
   expect(1, operator, "string")
   expect(2, count, "number")
   return self:condition("create:player_count", { count = count, exact = valid_exactness[operator] })
end

--- Wait for a period of inactivity in loading or unloading cargo.
--- @param len number The amount of time to wait for.
--- @param unit nil|ValidTime The unit of time.
function Scheduler:cargoidle(len, unit)
   expect(1, len, "number")
   expect(2, unit, "string", "nil")
   unit = unit or "s"
   return self:condition("create:idle", { value = len, time_unit = valid_time[unit] })
end

--- Wait for the chunk the train is in to be unloaded.
function Scheduler:unloaded()
   return self:condition("create:unloaded", {})
end

--- Wait for the station to be powered with a redstone signal.
function Scheduler:powered()
   return self:condition("create:powered", {})
end

--- Wait for the chunk the train is in to be loaded.
--- @*requires* Create Steam 'n' Rails
function Scheduler:loaded()
   return self:condition("railways:loaded", {})
end

--- Wait for a set delay dynamically.
--- See https://github.com/MisterJulsen/Create-Train-Navigator/wiki/Dynamic-Delays
--- @param len number The amount of time to wait for.
--- @param min number The minimum amount of time, in case the train was delayed.
--- @param unit nil|ValidTime The unit of time.
--- @*requires* Create Railways Navigator
function Scheduler:waitdynamic(len, min, unit)
   expect(1, len, "number")
   expect(2, min, "number")
   expect(3, unit, "string", "nil")
   unit = unit or "s"
   return self:condition("createrailwaysnavigator:dynamic_delay",
      { value = len, min = min, time_unit = valid_time[unit] })
end

--- Wait for a certain amount of electricity to be loaded onto the train.
--- @param operator ValidComparison Whether the condition should wait for the train to be loaded above the threshold, below the threshold or exactly at the threshold.
--- @param threshold number The threshold of energy (K⚡). Must be a positive integer.
--- @*requires* Create Crafts & Additions
function Scheduler:energy(operator, threshold)
   expect(1, operator, "string")
   expect(2, threshold, "number")
   return self:condition("createaddition:energy_threshold",
      { threshold = threshold, operator = valid_comparison[operator], measure = 0 })
end

return Scheduler
