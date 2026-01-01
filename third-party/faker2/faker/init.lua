-- faker.lua
-- Generates random names, emails, numbers and etc

local Faker = {}

local random = math.random

function Faker:new(o)
	o = o or {}
	o.locale = o.locale or 'en_US'
	
	-- Support seed parameter
	if o.seed then
		math.randomseed(o.seed)
	else
		math.randomseed(os.clock() * 100000000000)
	end
	
	local generator = require('faker.generators.' .. o.locale)
	for k, v in pairs(generator) do
		o[k] = v
	end
	setmetatable(o, self)
	self.__index = self
	return o
end

-- Pattern matching helper
local function matches_pattern(str, pattern)
	if not pattern then return true end
	return string.match(str, '^' .. pattern .. '$') ~= nil
end

-- Generate string matching a pattern (simple implementation)
local function generate_from_pattern(pattern, min_len, max_len)
	if not pattern then
		-- No pattern, generate random string
		local len = min_len or (max_len or 10)
		if min_len and max_len then
			len = random(min_len, max_len)
		end
		local chars = {}
		for i = 1, len do
			chars[i] = string.char(random(97, 122)) -- a-z
		end
		return table.concat(chars)
	end
	
	-- Simple pattern matching - handle common cases
	-- For complex patterns, we'll generate and validate
	local max_attempts = 1000
	for attempt = 1, max_attempts do
		local result = generate_from_pattern(nil, min_len, max_len)
		if matches_pattern(result, pattern) then
			return result
		end
	end
	
	-- Fallback: return a simple string
	return generate_from_pattern(nil, min_len or 10, max_len or 10)
end

function Faker:string(properties)
	properties = properties or {}
	local min_len = properties.minLength or properties.min_length
	local max_len = properties.maxLength or properties.max_length
	local pattern = properties.pattern
	
	-- If no min/max specified, use default
	if not min_len and not max_len then
		min_len = 10
		max_len = 10
	elseif min_len and not max_len then
		max_len = min_len
	elseif not min_len and max_len then
		min_len = 1
	end
	
	return generate_from_pattern(pattern, min_len, max_len)
end

function Faker.randstring(size)
	-- Backward compatibility
	if type(size) == 'table' then
		return Faker:string(size)
	end
	local properties = {}
	if size then
		properties.minLength = size
		properties.maxLength = size
	end
	return Faker:string(properties)
end

function Faker:integer(properties)
	properties = properties or {}
	local min = properties.min
	local max = properties.max
	local pattern = properties.pattern
	
	-- If min/max not specified, use size for backward compatibility
	if not min and not max and properties.size then
		local first = tonumber('1' .. string.rep('0', properties.size - 1))
		local second = tonumber(string.rep('9', properties.size))
		min = first or 1
		max = second or 9999999999
	elseif not min and not max then
		min = 1
		max = 9999999999
	elseif min and not max then
		max = min + 100
	elseif not min and max then
		min = 1
	end
	
	-- Ensure min and max are numbers
	min = tonumber(min) or 1
	max = tonumber(max) or 9999999999
	
	-- Generate integer
	local value = random(min, max)
	
	-- If pattern specified, convert to string and validate
	if pattern then
		local max_attempts = 1000
		for attempt = 1, max_attempts do
			value = random(min, max)
			local str_value = tostring(value)
			if matches_pattern(str_value, pattern) then
				return value
			end
		end
	end
	
	return value
end

function Faker.randint(size)
	-- Backward compatibility
	if type(size) == 'table' then
		return Faker:integer(size)
	end
	local properties = {}
	if size then
		properties.size = size
	end
	return Faker:integer(properties)
end

function Faker:firstname(properties)
	self.firstnames = {{}, {}}
		-- 1 - feminine
	self.firstnames[1] = require('faker.data.pt_BR.firstnames_female')
	-- 2 - masculine
	self.firstnames[2] = require('faker.data.pt_BR.firstnames_male')
	function self:firstname(properties)
		properties = properties or {}
		local gender = 1
		if properties.gender == 'masculine' then
			gender = 2
		elseif properties.gender ~= 'feminine' then
			gender = math.random(1, 2)
		end
		return self.firstnames[gender][math.random(1, #self.firstnames[gender])]
	end
	return self:firstname(properties)
end

function Faker:surname()
	self.surnames = require('faker.data.' .. self.locale .. '.surnames')
	function self:surname()
		return self.surnames[math.random(1, #self.surnames)]
	end
	return self:surname()
end

function Faker:name(properties)
	return self:firstname(properties or {}) .. ' ' .. self:surname()
end

function Faker:email(properties)
	properties = properties or {}
	
	-- If pattern specified, generate email matching pattern
	if properties.pattern then
		local max_attempts = 1000
		for attempt = 1, max_attempts do
			local username = self:firstname(properties) .. '.' .. string.gsub(self:surname(), '%s+', '')
			local email = string.gsub(string.lower(self.normalize(username)), "'", '') .. '@example.com'
			if matches_pattern(email, properties.pattern) then
				return email
			end
		end
	end
	
	-- Default behavior
	local username = self:firstname(properties) .. '.' .. string.gsub(self:surname(), '%s+', '')
	return string.gsub(string.lower(self.normalize(username)), "'", '') .. '@example.com'
end

-- Generate UUID v4
function Faker:uuid()
	local template = 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'
	local uuid = string.gsub(template, '[xy]', function(c)
		local v = (c == 'x') and random(0, 0xf) or random(8, 0xb)
		return string.format('%x', v)
	end)
	return uuid
end

-- Generate URI
function Faker:uri(properties)
	properties = properties or {}
	local schemes = {'http', 'https', 'ftp', 'file', 'data'}
	local scheme = schemes[random(1, #schemes)]
	local hostname = self:hostname()
	local path = '/' .. self:string({minLength = 5, maxLength = 15})
	local uri = scheme .. '://' .. hostname .. path
	if properties.pattern and not matches_pattern(uri, properties.pattern) then
		-- Try to generate matching URI
		for i = 1, 100 do
			uri = scheme .. '://' .. hostname .. '/' .. self:string({minLength = 5, maxLength = 15})
			if matches_pattern(uri, properties.pattern) then
				break
			end
		end
	end
	return uri
end

-- Generate URL (similar to URI but always http/https)
function Faker:url(properties)
	properties = properties or {}
	local scheme = random(1, 2) == 1 and 'http' or 'https'
	local hostname = self:hostname()
	local path = '/' .. self:string({minLength = 5, maxLength = 15})
	local url = scheme .. '://' .. hostname .. path
	if properties.pattern and not matches_pattern(url, properties.pattern) then
		for i = 1, 100 do
			url = scheme .. '://' .. hostname .. '/' .. self:string({minLength = 5, maxLength = 15})
			if matches_pattern(url, properties.pattern) then
				break
			end
		end
	end
	return url
end

-- Generate date in YYYY-MM-DD format
function Faker:date(properties)
	properties = properties or {}
	local year = random(1970, 2024)
	local month = random(1, 12)
	local days_in_month = {31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31}
	-- Handle leap years
	if month == 2 and year % 4 == 0 and (year % 100 ~= 0 or year % 400 == 0) then
		days_in_month[2] = 29
	end
	local day = random(1, days_in_month[month])
	return string.format('%04d-%02d-%02d', year, month, day)
end

-- Generate date-time in RFC 3339 format
function Faker:dateTime(properties)
	properties = properties or {}
	local date = self:date(properties)
	local hour = random(0, 23)
	local minute = random(0, 59)
	local second = random(0, 59)
	local tz_offset = random(-12, 12)
	local tz_sign = tz_offset >= 0 and '+' or '-'
	return string.format('%sT%02d:%02d:%02d%s%02d:00', date, hour, minute, second, tz_sign, math.abs(tz_offset))
end

-- Generate timestamp (Unix timestamp)
function Faker:timestamp(properties)
	properties = properties or {}
	local min = properties.min or 0
	local max = properties.max or os.time()
	return random(min, max)
end

-- Generate IPv4 address
function Faker:ipv4()
	return string.format('%d.%d.%d.%d', random(1, 255), random(0, 255), random(0, 255), random(1, 254))
end

-- Generate IPv6 address
function Faker:ipv6()
	local parts = {}
	for i = 1, 8 do
		parts[i] = string.format('%x', random(0, 0xffff))
	end
	return table.concat(parts, ':')
end

-- Generate hostname
function Faker:hostname(properties)
	properties = properties or {}
	local domains = {'com', 'org', 'net', 'io', 'co', 'edu', 'gov'}
	local name = self:string({minLength = 5, maxLength = 15})
	local domain = domains[random(1, #domains)]
	return name .. '.' .. domain
end

-- Generate base64 encoded byte string
function Faker:byte(properties)
	properties = properties or {}
	local min_len = properties.minLength or properties.min_length or 10
	local max_len = properties.maxLength or properties.max_length or 20
	local len = random(min_len, max_len)
	local bytes = {}
	for i = 1, len do
		bytes[i] = string.char(random(0, 255))
	end
	local data = table.concat(bytes)
	-- Simple base64 encoding (Lua 5.1 compatible, no bitwise ops)
	local base64_chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
	local result = {}
	for i = 1, #data, 3 do
		local b1 = string.byte(data, i) or 0
		local b2 = string.byte(data, i + 1) or 0
		local b3 = string.byte(data, i + 2) or 0
		
		-- Combine bytes manually (Lua 5.1 compatible)
		local combined = b1 * 65536 + b2 * 256 + b3
		
		-- Extract 6-bit chunks
		for j = 0, 3 do
			local shift = 6 * (3 - j)
			local idx = math.floor((combined / (2^shift)) % 64) + 1
			result[#result + 1] = string.sub(base64_chars, idx, idx)
		end
	end
	return table.concat(result)
end

-- Generate binary data (for file upload simulation)
function Faker:binary(properties)
	properties = properties or {}
	local min_len = properties.minLength or properties.min_length or 100
	local max_len = properties.maxLength or properties.max_length or 1000
	local len = random(min_len, max_len)
	local bytes = {}
	for i = 1, len do
		bytes[i] = string.char(random(0, 255))
	end
	return table.concat(bytes)
end

-- Generate password
function Faker:password(properties)
	properties = properties or {}
	local min_len = properties.minLength or properties.min_length or 8
	local max_len = properties.maxLength or properties.max_length or 16
	local len = random(min_len, max_len)
	
	-- Ensure minimum length is at least 4 for required character types
	if len < 4 then len = 4 end
	
	local lowercase = 'abcdefghijklmnopqrstuvwxyz'
	local uppercase = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
	local numbers = '0123456789'
	local symbols = '!@#$%^&*()_+-=[]{}|;:,.<>?'
	local all_chars = lowercase .. uppercase .. numbers .. symbols
	
	local password = {}
	-- Ensure at least one of each type
	local idx1 = random(1, #lowercase)
	password[1] = string.sub(lowercase, idx1, idx1)
	local idx2 = random(1, #uppercase)
	password[2] = string.sub(uppercase, idx2, idx2)
	local idx3 = random(1, #numbers)
	password[3] = string.sub(numbers, idx3, idx3)
	local idx4 = random(1, #symbols)
	password[4] = string.sub(symbols, idx4, idx4)
	
	-- Fill rest randomly
	for i = 5, len do
		local idx = random(1, #all_chars)
		password[i] = string.sub(all_chars, idx, idx)
	end
	
	-- Shuffle
	for i = len, 2, -1 do
		local j = random(1, i)
		password[i], password[j] = password[j], password[i]
	end
	
	return table.concat(password)
end

-- Generate boolean
function Faker:boolean()
	return random(1, 2) == 1
end

-- Generate ID (simple numeric or string ID)
function Faker:id(properties)
	properties = properties or {}
	local id_type = properties.type or 'alphanumeric'
	
	if id_type == 'numeric' then
		return self:integer({min = 1, max = 999999999})
	elseif id_type == 'string' then
		return self:string({minLength = 8, maxLength = 16})
	elseif id_type == 'uuid' then
		return self:uuid()
	else
		-- Default: alphanumeric
		local chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789'
		local len = properties.length or 10
		local id = {}
		for i = 1, len do
			local idx = random(1, #chars)
			id[i] = string.sub(chars, idx, idx)
		end
		return table.concat(id)
	end
end

function Faker:country()
	self.countries = require('faker.data.' .. self.locale .. '.countries')
	function self:country()
		return self.countries[math.random(1, #self.countries)]
	end
	return self:country()
end

function Faker:state()
	self.states = require('faker.data.' .. self.locale .. '.states')
	function self:state()
		return self.states[math.random(1, #self.states)]
	end
	return self:state()
end

function Faker:city()
	self.cities = require('faker.data.' .. self.locale .. '.cities')
	function self:city()
		return self.cities[math.random(1, #self.cities)]
	end
	return self:city()
end

return Faker
