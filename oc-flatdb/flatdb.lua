local mp = require("MessagePack")
local fs = require("filesystem")

local function isFile(path)
	return (fs.exists(path) and not fs.isDirectory(path))
end

local function isDir(path)
	return(fs.isDirectory(path))
end

local function load_page(path)
	local ret
	local f = io.open(path, "rb")
	if f then
		ret = mp.unpack(f:read("*a"))
		f:close()
	end
	return ret
end

local function store_page(path, page)
	if type(page) == "table" then
		local f = io.open(path, "wb")
		if f then
			f:write(mp.pack(page))
			f:close()
			return true
		end
	end
	return false
end

local pool = {}

local db_funcs = {
	save = function(db, p)
		if p then
			if type(p) == "string" and type(db[p]) == "table" then
				return store_page(pool[db].."/"..p, db[p])
			else
				return false
			end
		end
		for p, page in pairs(db) do
			if not store_page(pool[db].."/"..p, page) then
				return false
			end
		end
		return true
	end
}

local mt = {
	__index = function(db, k)
		if db_funcs[k] then return db_funcs[k] end
		if pool[db].funcs[k] then return pool[db].funcs[k] end
		if isFile(pool[db].."/"..k) then
			db[k] = load_page(pool[db].."/"..k)
		end
		return rawget(db, k)
	end
}

pool.hack = db_funcs

return setmetatable(pool, {
	__mode = "kv",
	__call = function(pool, path)
		assert(isDir(path), path.." is not a directory.")
		if pool[path] then return pool[path] end
		local db = {}
		db.funcs = {}
		setmetatable(db, mt)
		pool[path] = db
		pool[db] = path
		return db
	end
})
