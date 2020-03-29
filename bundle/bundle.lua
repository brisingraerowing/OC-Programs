--[[
Bundle API by TetraSource
version v1.0

Merges multiple file systems that are attached to one computer or server
into a virtual one.

dependencies:
 none
]]--

---------------
-- constants --
---------------

-- adapts this to your hardware, OC configuration and OS.

-- Set this to true if you're running the script on a machine with
-- case insensitive file system, e.g. the one of a windows machine.
local CASE_INSENSITIVE = true

-- The maximal length of a string to be written or read from this file system.
-- You should adapt it to the RAM capacity of your computer.
local MAX_IO = 1024

-- The extra size each file takes (see OC config - fileCost).
local FILE_COST = 512

-- The address of the file system component provided by this API.
local ADDRESS = "ffffffff-ffff-ffff-ffff-ffffffffffff"

---------------
-- variables --
---------------

local component = require("component")

local currIndex = 1
local filesystems = {}

local label = ""
local spaceTotal = 0
local structure = {}
local handles = setmetatable({}, {__mode = "k"})

local cmp = {
  slot = -1,
  address = ADDRESS,
  type = "filesystem",
}

local otherAddress = component.list("filesystem", true)()
local nativeComponent = {}
local running = false

----------------------
-- helper functions --
----------------------

local function segments(path)
  if CASE_INSENSITIVE then
    path = path:lower()
  end
  local parts = {}
  for part in path:gmatch("[^\\/]+") do
    local current, up = part:find("^%.?%.$")
    if current then
      if up == 2 then
        table.remove(parts)
      end
    else
      table.insert(parts, part)
    end
  end
  return parts
end

local function findDir(path)
  local parts = segments(path)
  local start = structure
  for i = 1, #parts-1 do
    start = start[ parts[i] ]
    if not start or start.isFile == true then
      return nil
    end
  end
  return table.concat(parts, '/', 1, #parts-1), start, parts[#parts], parts
end

local function mark(pos)
  local proxy = filesystems[pos]
  local handle = proxy.open(".bundle_metadata", "w")
  proxy.write(handle, string.format("%s%4x", ADDRESS, bit32.band(pos, 0xffff)))
  proxy.close(handle)
end

--------------------------------
-- fake file system component --
--------------------------------

function cmp.setLabel(newLabel)
  checkArg(1, newLabel, "string")
  if filesystems[1] then
    label = filesystems[1].setLabel(newLabel)
  end
  return label
end

function cmp.getLabel()
  return label
end

function cmp.isReadOnly()
  return false
end

function cmp.spaceUsed()
  local used = 0
  for i = 1, #filesystems do
    used = used + filesystems[i].spaceUsed()
  end
  return used
end

function cmp.spaceTotal()
  return spaceTotal
end

function cmp.size(path)
  checkArg(1, path, "string")

  local file, name
  path, file, name = findDir(path)
  file = file and file[name]
  if not file or file.isFile ~= true then
    return 0
  end
  path = path .. "/" .. name

  local size = 0
  for i = file.from, file.to do
    size = size + filesystems[i].size(path)
  end
  return size
end

function cmp.exists(path)
  checkArg(1, path, "string")

  local parts = segments(path)
  local start = structure
  for i = 1, #parts do
    if start.isFile == true then
      return false
    end
    start = start[ parts[i] ]
    if not start then
      return false
    end
  end
  return true
end

function cmp.isDirectory(path)
  checkArg(1, path, "string")

  local parts = segments(path)
  local start = structure
  for i = 1, #parts do
    start = start[ parts[i] ]
    if not start or start.isFile == true then
      return false
    end
  end
  return true
end

function cmp.list(path)
  checkArg(1, path, "string")

  local dir, name
  path, dir, name = findDir(path)
  if name and dir and dir.isFile ~= true then
    dir = dir[name]
  end
  if not dir then
    return nil, "no such file or directory"
  elseif dir.isFile == true then
    return {n = 1, [1] = name}
  end

  local n, results = 0, {n = 0}
  for member, element in next, dir do
    n = n+1
    results[n] = element.isFile == true and member or member .. '/'
  end
  results.n = n
  return results -- is not sorted; no hidden files are hidden
end

function cmp.makeDirectory(path)
  checkArg(1, path, "string")

  if not filesystems[currIndex] then
    return nil, "not enough space"
  end

  local parts = segments(path)
  local dir = structure
  for i = 1, #parts do
    local nextDir = dir[ parts[i] ]
    if not nextDir then
      if i == 1 and parts[1] == ".bundle_metadata" then
        return false
      end

      local ok, err = filesystems[currIndex].makeDirectory(path)
      if not ok then
        return ok, err
      end
      for j = i, #parts do
        local new = {}
        dir[ parts[j] ] = new
        dir = new
      end
      return true
    elseif nextDir.isFile == true then
      return false
    end
    dir = nextDir
  end
  return false
end

function cmp.rename(oldPath, newPath)
  checkArg(1, oldPath, "string")
  checkArg(2, newPath, "string")

  local oldDir, newDir, oldName, newName
  oldPath, oldDir, oldName = findDir(oldPath)
  newPath, newDir, newName = findDir(newPath)
  if not (oldName and newName and oldDir and newDir and oldDir[oldName]) or
   oldDir.isFile == true or newDir.isFile == true then
    return false
  end
  if oldDir ~= newDir or oldName ~= newName then
    if newDir[newName] then
      return false
    end
    oldPath = oldPath .. "/" .. oldName
    newPath = newPath .. "/" .. newName
    local from = oldDir[oldName].isFile == true and oldDir[oldName].from or 1
    for i = from, oldDir[oldName].file == true and oldDir[oldName].to or 1 do
      if not filesystems[i].rename(oldPath, newPath) then
        for j = from, i-1 do
          filesystems[j].rename(newPath, oldPath)
        end
        return false
      end
    end
    newDir[newName] = oldDir[oldName]
    oldDir[oldName] = nil
  end
  return true
end

function cmp.remove(path)
  checkArg(1, path, "string")

  local dir, name
  path, dir, name = findDir(path)
  if not dir or name and not dir[name] then
    return false
  end
  local element = dir[name] or structure
  local from = element.isFile == true and element.from or 1
  local to = element.isFile == true and element.to or #filesystems
  path = name and path .. "/" .. name or ""

  for handle, data in next, handles do
    if data.path:sub(1, #path) == path then
      return false
    end
  end
  for i = from, to do
    if not filesystems[i].remove(path) then
      io.stderr:write("data is not entirely removed")
      return false
    end
  end
  if name then
    dir[name] = nil
  else
    structure = {}
    for i = from, to do
      mark(i)
    end
  end
  return true -- even if no file were removed
end

local function writeOpenNext(data)
  data.handle = nil
  local fs = filesystems[data.index]
  local i
  while fs do
    if currIndex < data.index then
      currIndex = data.index
    end

    -- create directory
    i = #data.parts-1
    if data.dir ~= "" then
      while fs do
        local dir = data.dir
        while not fs.isDirectory(dir) do
          i = i-1
          dir = table.concat(parts, "/", 1, i)
        end
        if i+1 == #data.parts or fs.makeDirectory(data.dir) then
          break
        end
        data.index = data.index+1
        fs = filesystems[data.index]
        if currIndex < data.index then
          currIndex = data.index
        end
        i = #data.parts-1
      end
      if not fs then
        break
      end
    end

    -- open / create file
    local err
    data.handle, err = fs.open(data.path, data.m)
    if data.handle then
      return nil
    end
    if i+1 < #data.parts then
      fs.remove(table.concat(data.parts, '/', 1, i+1))
    end
    if err ~= "not enough space" then
      return err
    end
    data.index = data.index+1
    fs = filesystems[data.index]
  end
  return "not enough space"
end

local function readOpenNext(data)
  data.handle = nil
  while data.index <= data.file.to do
    data.handle = filesystems[data.index].open(data.path, data.m)
    if data.handle then
      return true
    end
    data.index = data.index+1
  end
  return false
end

local modes = {
  r = "r",
  rb = "r",
  w = "w",
  wb = "w",
  a = "a",
  ab = "a",
}

local resetFiles = true

function cmp.open(path, mode)
  checkArg(1, path, "string")
  checkArg(2, mode, "string", "nil")
  if not mode then
    mode = "r"
  elseif not modes[mode] then
    error("unsupported mode", 2)
  end

  local dir, name, parts
  path, dir, name, parts = findDir(path)
  local m = mode
  mode = modes[mode]

  -- no target
  if not name or not dir[name] and mode == "r" or
   -- target is a directory
   dir[name] and dir[name].isFile ~= true or
   -- target is a hidden path
   path == "" and name == ".bundle_data" then
    return nil, "cannot open file: " .. (name and path .. "/" .. name or "/")
  elseif mode ~= "r" and not dir[name] and not filesystems[currIndex] then
    return nil, "not enough space"
  end

  local file = dir[name] or {
    isFile = true,
    from = currIndex,
    to = currIndex,
  }

  local data = {
    parts = parts,
    path = path .. "/" .. name,
    dir = path,
    m = m,
    mode = mode,
    file = file,
    globalPos = 0,
    localPos = 0,
    index = mode ~= "a" and file.from or file.to,
    handle = nil,
    -- "local" variables
    start = 0,
  }

  path = data.path
  if mode == "r" then
    readOpenNext(data)
  else
    local err = writeOpenNext(data)
    if err then
      return nil, err
    end

    if not dir[name] then
      dir[name] = file
    elseif mode == "w" then
      if resetFiles then
        -- Remove all files of the file in when opening it in write mode
        -- as this would clear the entire file on a file system, too.
        local blocked = false
        for handle, hData in next, handles do
          if hData.path:sub(1, #path) == path then
            if hData.mode ~= "r" then
              blocked = true
            elseif hData.handle then
              filesystems[data.index].close(hData.handle)
            end
          end
        end
        if not blocked then
          for i = file.from+1, file.to do
            filesystems[i].remove(path)
          end
        end
        for handle, hData in next, handles do
          if hData.path:sub(1, #path) == path and hData.handle then
            if blocked then
              hData.handle = filesystems[data.index].open(hData.path, hData.m)
              hData.seek(hData.handle, "set", hData.localPos)
            elseif hData.mode == "r" then
              hData.handle = nil
            end
          end
        end
        file.to = file.from
      end
    else--if mode == "a" then
      for i = data.file.from, data.file.to do
        data.localPos = filesystems[i].size(path)
        data.globalPos = data.globalPos + data.localPos
      end
    end
  end
  handles[data.handle] = data
  return data.handle
end

local function writeValue(data, value, count)
  local limited = count ~= math.huge
  count = math.min(count, #value - data.start)
  value = (limited or data.start > 0) and
   value:sub(data.start+1, data.start + count) or value

  if count > 0 then
    -- read data from the current file
    local ok, err = filesystems[data.index].write(data.handle, value)
    if ok then
      data.start = data.start + count
      data.globalPos = data.globalPos + count
      data.localPos = data.localPos + count
    elseif err ~= "not enough space" then
      return err
    end
  end

  if limited then
    -- open next file
    filesystems[data.index].close(data.handle)
    data.index = data.index+1
    data.localPos = 0
    local err = writeOpenNext(data)
    if err then
      return err
    elseif data.file.to < data.index then
      data.file.to = data.index
    elseif data.mode == "a" then
      filesystems[data.index].seek(data.handle, "set", 0)
    end
  end
  return nil
end

function cmp.write(handle, value)
  checkArg(2, value, "string")

  local data = handles[handle]
  if not data or data.mode == "r" then
    return nil, "bad file descriptor"
  elseif not data.handle then
    return nil, "not enough space"
  elseif value == "" then
    return true
  elseif #value > MAX_IO then
    value = value:sub(1, MAX_IO)
  end
  data.start = 0

  local err
  if data.mode == "a" then
    while data.file.to > data.index do
      err = writeValue(data, value,
       filesystems[data.index].size(data.path) - data.localPos)
      if err then
        return false, err
      elseif data.start >= #value then
        return true
      end
    end
  end

  while true do
    err = writeValue(data, value, math.huge)
    if err then
      return false, err
    elseif data.start >= #value then
      return true
    end

    err = writeValue(data, value, filesystems[data.index].spaceTotal()
     - filesystems[data.index].spaceUsed() - FILE_COST)
    if err then
      return false, err
    elseif data.start >= #value then
      return true
    end
  end
  return false
end

function cmp.read(handle, count)
  checkArg(2, count, "number")

  local data = handles[handle]
  if not data or data.mode ~= "r" then
    return nil, "bad file descriptor"
  elseif data.index > data.file.to then
    return nil
  elseif count <= 0 then
    return ""
  elseif count > MAX_IO then
    count = MAX_IO
  end

  local output = {}
  while true do
    local result = filesystems[data.index].read(data.handle, count)
    if result then
      output[#output+1] = result
      data.globalPos = data.globalPos + #result
      data.localPos = data.localPos + #result
      count = count - #result
      if count <= 0 then
        break
      end
    end

    filesystems[data.index].close(data.handle)
    data.index = data.index+1
    if data.file.to >= data.index then
      break
    end
    data.localPos = 0
    if not readOpenNext(data) then
      break
    end
  end
  return table.concat(output)
end

function cmp.seek(handle, whence, offset)
  checkArg(2, whence, "string")
  checkArg(3, offset, "number")
  offset = math.floor(offset)

  local data = handles[handle]
  if not (data and data.handle) then
    return nil, "bad file descriptor"
  end

  local size, index, globalPos = 0, 1, 0
  if whence == "set" or whence == "cur" then
    if whence == "set" then
      globalPos = offset
    else
      if offset == 0 then
        return data.globalPos
      end
      globalPos = data.globalPos + offset
    end
    index = 1
    for i = data.file.from, data.file.to-1 do
      local newSize = size + filesystems[i].size(data.path)
      if newSize > globalPos then
        break
      end
      index = i+1
      size = newSize
    end
    offset = globalPos - size
  elseif whence == "end" then
    index = data.file.to
    for i = data.file.to, data.file.from, -1 do
      local newSize = size + filesystems[i].size(data.path)
      if newSize >= -offset then
        index = i
        offset = newSize + offset
        globalPos = offset
        for j = data.file.from, i-1 do
          globalPos = globalPos + filesystems[j].size(data.path)
        end
        break
      end
      size = newSize
    end
  else
    error("invalid mode", 2)
  end
  if globalPos < 0 then
    error("bad argument", 2)
  end

  if data.index ~= index then
    filesystems[data.index].close(data.handle)
    data.index = index
    if data.mode == "r" then
      readOpenNext(data)
    else
      writeOpenNext(data)
    end
  end
  filesystems[index].seek(data.handle, "set", offset)
  data.localPos = offset
  data.globalPos = globalPos
  return globalPos
end

function cmp.close(handle)
  local data = handles[handle]
  if not data then
    return nil, "bad file descriptor"
  elseif data.handle then
    filesystems[data.index].close(data.handle)
  end
  handles[handle] = nil
end

function cmp.lastModified(path)
  checkArg(1, path, "string")

  local file, name
  path, file, name = findDir(path)
  file = file and file[name]
  if not file then
    return 0
  end
  path = path .. "/" .. name

  local tstmp = 0
  for i = file.isFile == true and file.to or 1,
   file.isFile == true and file.from or #filesystems do
    tstmp = math.max(tstmp, filesystems[i].lastModified(path))
  end
  return tstmp
end

-----------------------------
-- component API extension --
-----------------------------

local newApi = {}

function newApi.doc(address, method)
  checkArg(1, address, "string")
  checkArg(2, method, "string")
  return nativeComponent.doc(
   address == ADDRESS and otherAddress or address, method)
end

function newApi.invoke(address, name, ...)
  checkArg(1, address, "string")
  if address ~= ADDRESS then
    return nativeComponent.invoke(address, name, ...)
  end
  if type(cmp[name]) ~= "function" then
    error("no such method", 2)
  end
  local ok, res1, res2 = pcall(cmp[name], ...)
  if ok then
    return res1, res2
  else
    error(res1, 2)
  end
end

function newApi.list(filter, exact)
  checkArg(1, filter, "string", "nil")
  local list = nativeComponent.list(filter, exact)

  if not filter or (filter == string.sub("filesystem", 1, #filter) and
   (not exact or #filter == 10)) then
    list[ADDRESS] = "filesystem"
  end
  return list
end

function newApi.methods(address)
  checkArg(1, address, "string")
  return nativeComponent.methods(
   address == ADDRESS and otherAddress or address)
end

function newApi.proxy(address)
  checkArg(1, address, "string")
  if address == ADDRESS then
    return cmp
  end
  return nativeComponent.proxy(address)
end

function newApi.type(address)
  checkArg(1, address, "string")
  if address == ADDRESS then
    return "filesystem"
  end
  return nativeComponent.type(address)
end

function newApi.slot(address)
  checkArg(1, address, "string")
  if address == ADDRESS then
    return -1
  end
  return nativeComponent.slot(address)
end

function newApi.fields(address)
  checkArg(1, address, "string")
  return nativeComponent.fields(
   address == ADDRESS and otherAddress or address)
end

----------------
-- rc methods --
----------------

--[[
Adds a file system to the bundled one which wipes the added system.
Don't use this system for any other purpose afterwards.
]]--
function add(address)
  if type(address) ~= "string" then
    io.stderr:write("expected a string\n")
    return
  end

  local proxy
  for a in component.list("filesystem", true) do
    if a ~= ADDRESS and (a:sub(1, #address) == address or
     component.invoke(a, "getLabel") == address) then
      if proxy then
        io.stderr:write("address is ambiguous")
        return
      end
      proxy = component.proxy(a)
    end
  end
  if not proxy then
    io.stderr:write("cannot find filesystem component\n")
    return
  elseif proxy.isReadOnly() then
    io.stderr:write("cannot add a read-only filesystem\n")
    return
  elseif proxy.exists(".bundle_metadata") then
    io.stderr:write("cannot add a filesystem twice")
    return
  end

  proxy.remove("/")
  if not filesystems[1] then
    label = proxy.getLabel()
  end
  local index = #filesystems+1
  filesystems[index] = proxy
  spaceTotal = spaceTotal + proxy.spaceTotal()
  mark(index)
  io.stdout:write("added filesystem successfully: " .. proxy.address .. "\n")
end

--[[
Removes either the specified filesystem or the last added filesystem
from the bundle one as long as it causes no
loss of data. If you want to remove it anyway pass true as second parameter.
Note that the drive isn't wiped after removal.
To remove the last added filesystem, pass . for the address.
]]--
function remove(address, forcefully)
  if not running then
    io.stderr:write("bundle isn't running\n")
    return
  end
  -- TODO: allow relocation of data from every filesystem.
  local fs
  if address == "." then
    local index = #filesystems
    fs = filesystems[index]
    if #fs.list("") > 1 and not forcefully then
      io.stderr:write("removing the filesystem causes the loss of data. Pass true as first parameter to remove it anyway")
      return
    end
  else
    if address:len() == 8 then
      -- Short address
      for i=1, #filesystems do
        if filesystems[i].address:sub(0, 8) == address then
          fs = filesystems[i]
          if fs.list("") > 1 and not forcefully then
            io.stderr:write("removing the filesystem causes the loss of data. Pass true as first parameter to remove it anyway")
            return
          end
        end
      end
    else
      for i=1, #filesystems do
        if filesystems[i].address == address then
          fs = filesystems[i]
          if fs.list("") > 1 and not forcefully then
            io.stderr:write("removing the filesystem causes the loss of data. Pass true as first parameter to remove it anyway")
            return
          end
        end
      end
    end
  end

  if fs == nil then
    io.stderr:write("Specified filesystem '" .. address .. "' not found.")
    return
  end

  local function truncate(dir)
    for name, element in next, dir do
      if element.isFile ~= true then
        truncate(element)
      else
        if element.from == index then
          dir[name] = nil
        elseif element.to == index then
          element.to = index-1
        end
      end
    end
  end

  fs.remove(".bundle_metadata")
  truncate(structure)
  io.stdout:write("removed filesystem successfully: " .. fs.address .. "\n")
end

function list()
  if not running then
    io.stderr:write("bundle isn't running\n")
    return
  end
  io.stdout:write(string.format("Address%sLabel\n", string.rep(" ", 30)))
  for i = 1, #filesystems do
    io.stdout:write(string.format("%s %s\n",
     filesystems[i].address, filesystems[i].getLabel()))
  end
end

function start()
  if running then
    io.stderr:write("bundle is running already\n")
    return
  end

  -- find file systems
  for address in component.list("filesystem", true) do
    local proxy = component.proxy(address)
    if not proxy.isReadOnly() then
      local handle = proxy.open(".bundle_metadata", "r")
      if handle then
        local file = proxy.read(handle, 40)
        proxy.close(handle)
        if file:sub(1, 36) == ADDRESS then
          filesystems[ tonumber(file:sub(37, 40), 16) ] = proxy
        end
      end
    end
  end
  if not filesystems[1] then
    io.stderr:write("cannot find any bundle filesystem\n")
    return
  end

  -- import file systems into virtual file system
  local pos = 1
  local proxy
  local function addFilesystem(path, struc)
    local list = proxy.list(path)
    for i = 1, #list do
      local name = CASE_INSENSITIVE and list[i]:lower() or list[i]
      local currPath = path .. name
      if proxy.isDirectory(currPath) then
        name = name:sub(1, -2) -- remove trailing slash
        struc[name] = addFilesystem(currPath, struc[name] or {})
      else
        if struc[name] then
          struc[name].to = pos
        else
          struc[name] = {
            isFile = true,
            from = pos,
            to = pos,
          }
        end
      end
    end
    return struc
  end
  while pos <= #filesystems do
    proxy = filesystems[pos]
    spaceTotal = spaceTotal + proxy.spaceTotal()
    addFilesystem("", structure)
    pos = pos+1
  end
  structure[".bundle_metadata"] = nil
  label = filesystems[1].getLabel()

  -- overwrite component API
  for name, func in next, newApi do
    nativeComponent[name] = component[name]
    component[name] = func
  end
  require("computer").pushSignal("component_added", ADDRESS, "filesystem")

  io.stdout:write("launched bundle successfully\n")
  running = true
end