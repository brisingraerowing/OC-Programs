-- LuaFileSystem Emulation for OpenOS.

local filesystem = require('filesystem')
local shell = require('shell')

local lfs = {}

function lfs.attributes(filepath, attribute_name_or_table)
	local tmp = {}
	
	if type(attribute_name_or_table) == "table"
		tmp = attribute_name_or_table
	end
	
	if filesystem.isDirectory(filepath) then
		tmp.mode = "directory"
	elseif filesystem.exists(filepath) then
		tmp.mode = "file"
	else
		return nil, "ERROR: Item is not a directory, or a file! (Might be a bug)"
	end
	tmp.dev = -1
	tmp.ino = -1
	tmp.nlink = -1
	tmp.uid = -1
	tmp.gid = -1
	tmp.rdev = -1
	tmp.access = -1
	tmp.modification = filesystem.lastModified(filepath)
	tmp.change = -1
	tmp.size = filesystem.size(filepath)
	tmp.permissions = 511 -- 0777 (octal)
	tmp.blocks = -1
	tmp.blksize = -1
	
	if type(attribute_name_or_table) == "string" then
		return tmp[attribute_name_or_table]
	else
		return attribute_name_or_table
	end	
end

function lfs.chdir(path)
	shell.setWorkingDirectory(path)
	return true
end

function lfs.currentdir()
	return shell.getWorkingDirectory()
end

function lfs.dir(path)
	return filesystem.list(path)
end

function lfs.link(old, new, symlink)
	if symlink then
		return filesystem.link(old, new)
	else
		return filesystem.copy(old, new)
	end
end

function lfs.lock(fh, mode)
	return true
end

function lfs.lock_dir(path)
	return true
end

function lfs.mkdir(path)
	return filesystem.makeDirectory(path)
end

function lfs.rmdir(path)
if not filesystem.isDirectory(path) then
	return nil, "Not a directory"
end
local iter = lfs.dir(path)
local res, _ = iter()

if res ~= nil then
	return nil, "Directory not empty"
end

return filesystem.remove(path)

end

function lfs.setmode(filepath, mode)
	if mode ~= "binary" and mode ~= "text" then
		return nil, "Invalid mode"
	end	
	return true, mode
end

function lfs.symlinkattributes(filepath, attribute_name_or_table)
	local tmp = {}
	
	if type(attribute_name_or_table) == "table"
		tmp = attribute_name_or_table
	end
	
	if filesystem.isLink(filepath) then
		tmp.mode = "link"
	elseif filesystem.isDirectory(filepath) then
		tmp.mode = "directory"
	elseif filesystem.exists(filepath) then
		tmp.mode = "file"
	else
		return nil, "ERROR: Item is not a directory, or a file! (Might be a bug)"
	end
	tmp.dev = -1
	tmp.ino = -1
	tmp.nlink = -1
	tmp.uid = -1
	tmp.gid = -1
	tmp.rdev = -1
	tmp.access = -1
	tmp.modification = filesystem.lastModified(filepath)
	tmp.change = -1
	tmp.size = filesystem.size(filepath)
	tmp.permissions = 511 -- 0777 (octal)
	tmp.blocks = -1
	tmp.blksize = -1
	
	if type(attribute_name_or_table) == "string" then
		return tmp[attribute_name_or_table]
	else
		return attribute_name_or_table
	end	
	
end

function lfs.touch(filepath, atime, mtime)
	if not filesystem.exists(filepath) then
		io.open(filepath, "wb"):close()
	end
end

function lfs.unlock(fh)
	return true
end