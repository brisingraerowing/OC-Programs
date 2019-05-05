local mp = require("MessagePack")
local fs = require("filesystem")


local databaseFile = "/var/db/ae2-stockpile/craftable.db"

local craftableDb = {}

local function ensure_db_dir()
    if not fs.isDirectory("/var/db/ae2-stockpile") then
        if fs.exists("/var/db/ae2-stockpile") then
            error("/var/db/ae2-stockpile exists but isn't a directory!")
        end
        fs.makeDirectory("/var/db/ae2-stockpile")
    end
end

local function load_db()

    ensure_db_dir()

    if fs.exists(databaseFile) then
        local file = io.open(databaseFile, "r")
        local data = file:read("*a")
        file:close()
        craftableDb = mp.unpack(data)
    end

end

local function save_db()

    ensure_db_dir()

    local file = io.open(databaseFile, "w")
    file:write(mp.pack(craftableDb))
    file:close()

end

local function get_craftable_item(name)
    
end