-- Configuration
local totalspace = math.huge
local curspace = 0
local port = 14948
local label = "netfs"
local change = false
local debug = true
local mount_path = "C:/TestDir"
-- Configuration - End

local physfs = require("physfs")
local socket = require("socket")

local function recurseCount(path)
    local count = 0
    local list = physfs.files(path)
    
    for i = 1, #list do
        local stat = physfs.stat(list[i])
        if stat.type == "dir" then
            count = count + 512 + recurseCount(path .. "/" .. list[i])
        else
            count = count + stat.size
        end
    end
    
end

print("Warning, I take no responsibility if a bug in this program eats your computer\nIt's your fault for running it under such a permission\nThough, bug reports and fixes are welcomed ;)\n")

if change then
	print("Warning, modification enabled on potentially dangerous program\n")
end


local stat, server = pcall(assert,socket.bind("*", port))
if not stat then
	print("Failed to get default port " .. port .. ": " .. server)
	server = assert(socket.bind("*", 0))
end
local sID, sPort = server:getsockname()
server:settimeout(0)


print("Listening on " .. sID .. ":" .. sPort)

local ots = tostring
function tostring(obj)
	if obj == math.huge then
		return "math.huge"
	elseif obj == -math.huge then
		return "-math.huge"
	elseif obj ~= obj then
		return "0/0"
	else
		return ots(obj)
	end
end

-- Unserialize without loadstring, for security purposes.
-- Not very robust but gets the job done.
local unserialize
function unserialize(str)
	if type(str) ~= "string" then
		error("bad argument #1: string expected, got " .. type(str),2)
	end
	if str:sub(1,1) == "{" and str:sub(-1,-1) == "}" then
		local i = 1
		local gen = {}
		local block = str:sub(2,-2) .. ","
		local piece = ""
		for part in block:gmatch("(.-),") do
			piece = piece .. part
			if (piece:sub(1,1) == "\"" and piece:sub(-1,-1) == "\"") or piece:sub(1,1) ~= "\"" then
				if piece:find("^%[.-%]=.*") then
					local key, value = piece:match("^%[(.-)%]=(.*)")
					gen[unserialize(key)] = unserialize(value)
				else
					gen[i] = unserialize(piece)
					i = i + 1
				end
				piece = ""
			else
				piece = piece .. ","
			end
		end
		if piece ~= "" then
			error("Cannot unserialize " .. piece,2)
		end
		return gen
	elseif str:sub(1,1) == "\"" and str:sub(-1,-1) == "\"" then -- string
		return str:sub(2,-2):gsub("\\a","\a"):gsub("\\b","\b"):gsub("\\f","\f"):gsub("\\n","\n"):gsub("\\r","\r"):gsub("\\t","\t"):gsub("\\v","\v"):gsub("\\\"","\""):gsub("\\'","'"):gsub("\\\n","\n"):gsub("\\0","\0"):gsub("\\(%d%d?%d?)",string.char):gsub("\\\\","\\")
	elseif tonumber(str) then
		return tonumber(str)
	elseif str == "0/0" then
		return 0/0
	elseif str == "math.huge" then
		return math.huge
	elseif str == "-math.huge" then
		return -math.huge
	elseif str == "true" then
		return true
	elseif str == "false" then
		return false
	elseif str == "nil" or str == "" then
		return nil
	else
		error("Cannot unserialize " .. str,2)
	end
end

local curclient
local function sendData(msg)
	if debug then
		local ip,port = curclient:getpeername()
		print(ip .. ":" .. port .. " < " .. msg)
	end
	curclient:send(msg .. "\n")
end

local function checkArg(pos,obj,what)
	if type(obj) ~= what then
		sendData("bad argument #" .. pos .. " (" .. what .. " expected, got " .. type(obj) .. ")")
		return false
	end
	return true
end

local function dprint(ctrl, line)
	print(" > " .. ctrl .. "," .. line:gsub("[^\32-\126]", function(a) return "\\"..a:byte() end))
end

local function rename(old_file, new_file)
    if physfs.exists(new_file) then return false end
    if physfs.stat(old_file).type == "dir" then return recursive_rename(old_file, new_file) end
    local f1 = physfs.openRead(old_file)
    local f2 = physfs.openWrite(new_file);
    f2:write(f1:read("*a"))
    f1:close()
    f2:close()
    physfs.delete(old_file)
    return true
end

function recursive_rename(old_path, new_path)
    local list = physfs.files(old_path)
    
    for i = 1, #list do
        
        if physfs.stat(old_path .. "/" .. list[i]).type == "dir" then
            return recursive_rename(old_path .. "/" .. list[i], new_path .. "/" .. list[i])
        else
            return rename(old_path .. "/" .. list[i], new_path .. "/" .. list[i])
        end
    end
    return true
end

local function recursive_delete(path)

    local list = physfs.files(path)
    
    for i = 1, #list do
        if physfs.stat(path .. "/" .. list[i]).type == "dir" then
            return recursive_delete(path .. "/" .. list[i])
        else
            return physfs.delete(path .. "/" .. list[i])
        end
    end
return true
end

-- do not change order
local ops={"size","seek","read","isDirectory","open","spaceTotal","setLabel","lastModified","close","rename","isReadOnly","exists","getLabel","spaceUsed","makeDirectory","list","write","remove"}

local open_func_list = {
    ["w"] = physfs.openWrite,
    ["a"] = physfs.openAppend,
    ["r"] = physfs.openRead
}

local sockets = {server}
local hndls = {}
local function update()
	-- Check for new data or new clients
	local ready, _, err = socket.select(sockets,nil)
	if not ready then
		print("select gave " .. tostring(err))
		return
	end
	for _, client in ipairs(ready) do
		if client == server then
			client = server:accept()
			if client ~= nil then
				local ci,cp = client:getpeername()
				print("User connected from: " .. ci .. ":" .. cp)
				sockets[#sockets + 1] = client
				client:settimeout(0)
			end
			break
		end
		curclient = client
		local line, err = client:receive()
		if not line then
			print("socket receive gave: " .. err)
			if err ~= "closed" then
				pcall(client.close,client)
			end
			for i = 1,#sockets do
				if sockets[i] == client then
					table.remove(sockets, i)
					break
				end
			end
			break
		end
		local ctrl = line:byte(1,1) - 31
		ctrl = ops[ctrl] or ctrl
		local line = line:sub(2)
		if debug then
			dprint(ctrl, line)
		end
		local stat,ret = pcall(unserialize, line)
		if not stat then
			if not debug then
				dprint(ctrl, line)
			end
			print("Bad Input: " .. ret)
			sendData("{nil,\"bad input\"}")
			return
		end
		if type(ret) ~= "table" then
			if not debug then
				dprint(ctrl, line)
			end
			print("Bad Input (exec): " .. type(ret))
			sendData("{nil,\"bad input\"}")
			return
		end
		if ctrl == "size" then
			if not checkArg(1,ret[1],"string") then return end
			local size = physfs.stat(ret[1]).size
			sendData("{" .. (size or 0) .. "}")
		elseif ctrl == "seek" then
			if not checkArg(1,ret[1],"number") then return end
			if not checkArg(2,ret[2],"string") then return end
			if not checkArg(3,ret[3],"number") then return end
			local fd = ret[1]
			if hndls[fd] == nil then
				sendData("{nil, \"bad file descriptor\"}")
			else
				local new = hndls[fd]:seek(ret[2],ret[3])
				sendData("{" .. new .. "}")
			end
		elseif ctrl == "read" then
			if not checkArg(1,ret[1],"number") then return end
			if not checkArg(2,ret[2],"number") then return end
			local fd = ret[1]
			if hndls[fd] == nil then
				sendData("{nil, \"bad file descriptor\"}")
			else
				local data = hndls[fd]:read(ret[2])
				if type(data) == "string" and #data > 0 then
					sendData("{" .. string.format("%q",data):gsub("\\\n","\\n") .. "}")
				else
					sendData("{nil}")
				end
			end
		elseif ctrl == "isDirectory" then
			if not checkArg(1,ret[1],"string") then return end
			sendData("{" .. (tostring(physfs.stat(ret[1]).type == "dir")) .. "}")
		elseif ctrl == "open" then
			if not checkArg(1,ret[1],"string") then return end
			if not checkArg(2,ret[2],"string") then return end
			local mode = ret[2]:sub(1,1)
			if (mode == "w" or mode == "a") and not change then
				sendData("{nil,\"file not found\"}") -- Yes, this is what it returns
            else
                local open_func = open_func_list[mode]
                if open_func == nil then sendData("{nil, \"invalid mode\"}") end
				local file, errorstr = open_func(ret[1])
				if not file then
					sendData("{nil," .. string.format("%q",errorstr):gsub("\\\n","\\n") .. "}")
				else
					local randhand
					while true do
						randhand = math.random(1000000000,9999999999)
						if not hndls[randhand] then
							hndls[randhand] = file
							break
						end
					end
					sendData("{" .. randhand .. "}")
				end
			end
		elseif ctrl == "spaceTotal" then
			sendData("{" .. tostring(totalspace) .. "}")
		elseif ctrl == "setLabel" then
			if not checkArg(1,ret[1],"string") then return end
			if change then
				label = ret[1]
				sendData("{\"" .. label .. "\"}")
			else
				sendData("label is read only")
			end
		elseif ctrl == "lastModified" then
			if not checkArg(1,ret[1],"string") then return end
			local modtime = physfs.stat(ret[1]).mtime
			sendData("{" .. (modtime or 0) .. "}")
		elseif ctrl == "close" then
			if not checkArg(1,ret[1],"number") then return end
			local fd = ret[1]
			if hndls[fd] == nil then
				sendData("{nil, \"bad file descriptor\"}")
			else
				hndls[fd]:close()
				hndls[fd] = nil
				sendData("{}")
			end
		elseif ctrl == "rename" then
			if not checkArg(1,ret[1],"string") then return end
			if not checkArg(2,ret[2],"string") then return end
			if change then
                sendData("{" .. tostring(rename(ret[1],ret[2]) == true) .. "}")
			else
				sendData("{false}")
			end
		elseif ctrl == "isReadOnly" then
			sendData("{" .. tostring(not change) .. "}")
		elseif ctrl == "exists" then
			if not checkArg(1,ret[1],"string") then return end
			sendData("{" .. tostring(physfs.exists(ret[1])) .. "}")
		elseif ctrl == "getLabel" then
			sendData("{\"" .. label .. "\"}")
		elseif ctrl == "spaceUsed" then
			sendData("{" .. curspace .. "}")
		elseif ctrl == "makeDirectory" then
			if not checkArg(1,ret[1],"string") then return end
			if change then
				sendData("{" .. tostring(physfs.mkdir(ret[1])) .. "}")
			else
				sendData("{false}")
			end
		elseif ctrl == "list" then
			if not checkArg(1,ret[1],"string") then return end
			local list = physfs.files(ret[1])
			local out = ""
			for i = 1,#list do
				if physfs.stat(ret[1]).type == "dir" then
					list[i] = list[i] .. "/"
				end
				out = out .. string.format("%q",list[i]):gsub("\\\n","\\n")
				if i < #list then
					out = out .. ","
				end
			end
			sendData("{{" .. out .. "}}")
		elseif ctrl == "write" then
			if not checkArg(1,ret[1],"number") then return end
			if not checkArg(2,ret[2],"string") then return end
			local fd = ret[1]
			if hndls[fd] == nil then
				sendData("{nil, \"bad file descriptor\"}")
			else
				local success = hndls[fd]:write(ret[2])
				sendData("{" .. tostring(success) .. "}")
			end
		elseif ctrl == "remove" then
			-- TODO: Recursive remove
			if not checkArg(1,ret[1],"string") then return end
			if change then
				if physfs.stat(ret[1]).type == "dir" then
					sendData("{" .. tostring(recursive_delete(ret[1])) .. "}")
				else
					physfs.delete(ret[1])
				end
			else
				sendData("{false}")
			end
		else
			print("Unknown control: " .. ctrl)
		end
	end
end

local tmp, msg = physfs.mount(mount_path, "")

if not tmp then
print(msg)
os.exit()
end

print("Calculating current space usage ...")
curspace = recurseCount("/")


while true do
	update()
end