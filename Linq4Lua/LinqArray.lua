local class = require("30log")

local LinqArray = class("LinqArray")

function LinqArray:init(items)
	if items then
		self:addRange(items)
	end
end

function LinqArray:add(item)
	table.insert(self, item)
end

function LinqArray:addRange(items)
	for k,v in ipairs(items) do
		self:add(v)
	end
end

function LinqArray:where(func)
	local results = LinqArray()
	
	for k,v in ipairs(self) do
		if func(v) then
			results:add(v)
		end
	end
	return results
end

function LinqArray:select(func)
	local results = LinqArray()
    for k, v in ipairs(self) do
        results:add(func(v))
    end
    
    return results
end

function LinqArray:selectMany(func)
    local results = LinqArray()
    local selectResults = self:select(func)
    
    for _,item in ipairs(selectResults) do
        results:addRange(item)
    end
    
    return results
end

function LinqArray:count()
	return # self
end

function LinqArray:first()
	return self[1]
end

function LinqArray:last()
	return self[self:count()]
end

function LinqArray:distinct(objHashFunc)
    local results = LinqArray()
    local valueExists = {}
    
    if objHashFunc then
        for k, v in ipairs(self) do
            if not valueExists[objHashFunc(v)] then
                results:add(v)
                valueExists[objHashFunc(v)] = true
            end
        end
    else
        for k, v in ipairs(self) do
            if not valueExists[v] then
                results:add(v)
                valueExists[v] = true
            end
        end
    end
    
    return results
end

function LinqArray:toDictionary(keyFunc, valueFunc)
	local results = {}
    for k, v in ipairs(self) do
        results[keyFunc(v)] = valueFunc(v)
    end
    
    return results
end

function LinqArray:sum(func)
	local sum = 0
    
    if func then
        for k, v in ipairs(self) do
            sum = sum + func(v)
        end
    else
        for k, v in ipairs(self) do
            sum = sum + v
        end
    end
    
    return sum
end

function LinqArray:avg(func)
    return self:sum(func) / self:count()
end

function LinqArray:any(func)
	local results = self
    if func then
        results = results:where(func)
    end
    return results:count() > 0
end

local function minOrMax(obj, selector, cond)
	local curResult = nil
    local curVal
    
    for _,i in ipairs(obj) do
        if selector then
            curVal = selector(i)
        else
            curVal = i
        end
                
        if not curResult then
            curResult = curVal
        elseif cond(curVal, curResult) then
            curResult = curVal
        end
    end
    
    return curResult
end

function LinqArray:min(selector)
	return minOrMax(self, selector, function(a, b) return a < b end)
end

function LinqArray:max(selector)
	return minOrMax(self, selector, function(a, b) return a > b end)
end

function LinqArray:removeWhere(func)
	local i = 1
    while i <= self:count() do
        if func(self[i]) then
            table.remove(self, i)
        else
            i = i + 1
        end
    end
end

function LinqArray:zip(second, func)
	
	local results = LinqArray()
	local count = math.min(self:count(), second:count())
	
	for i=1,count do
		results:add(func(self[i], second[i]))
	end
	
	return results
	
end

function LinqArray:concat(other)
	local results = LinqArray()
	
	results:addRange(self)
	results:addRange(other)
	
	return results
end

function LinqArray:take(count)
	local results = LinqArray()
	local minCount = math.min(count, self:count())
	
	for i=1,minCount do
		results:add(self[i])
	end
	
	return results
end

function LinqArray:takeWhile(func)
	
	local results = LinqArray()
	
	local index = 0
	
	for k,v in ipairs(self) do
		
		index = index + 1
		
		if not func(v, index) then break end
		
		results:add(v)
		
	end
	
	return results
	
end

function LinqArray:skip(count)
	local results = LinqArray()
	
	if count >= self:count() then error("count too big") end
	
	for k,v in ipairs(self) do
		
		count = count - 1
		
		if count <= 0 then
			results:add(v)
		end
		
	end
	
	return results
end

function LinqArray:skipWhile(func)
	
	local yielding = false
	local index = 0
	
	local results = LinqArray()
	
	for k,v in ipairs(self) do
		index = index + 1
		if not yielding and not func(v, index) then yielding = true end
		if yielding then
			results:add(v)
		end
	end
	
	return results
	
end

return LinqArray

