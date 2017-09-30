local gryphonlib = {
	_VERSION = "gryphonlib 0.1",
	_DESCRIPTION = "Common utility library for Brisingr Aerowing's programs",
	_URL = "",
	_LICENSE = "GNU LGPL"
}

function gryphonlib.toboolean(obj)
	local tObj = type(obj)

	if tObj == "boolean" then
		return obj
	elseif tObj = "string" then
		local lObj = obj:lower()
		return lObj == "true" or lObj == "t" or lObj == "yes" or lObj == "y"
	elseif tObj == "number" then
		return obj ~= 0
	else
		return not not obj
	end
end

function gryphonlib.iif(condition, true_value, false_value)
	if condition then return true_value else return false_value end
end

function gryphonlib.split_string(sep, str, maxSplit, isregex)
	assert(sep ~= '')
	assert(maxSplit == nil or maxSplit >= 1)

	local aRecord = {}

	if self:len() > 0 then
		local bPlain = not isregex
		maxSplit = maxSplit or -1

		local nField, nStart = 1, 1
		local nFirst,nLast = str:find(sep, nStart, bPlain)
		while nFirst and maxSplit ~= 0 do
			aRecord[nField] = str:sub(nStart, nFirst-1)
			nField = nField+1
			nStart = nLast+1
			nFirst,nLast = str:find(sep, nStart, bPlain)
			maxSplit = maxSplit-1
		end
		aRecord[nField] = str:sub(nStart)
	end

	return aRecord
end

function gryphonlib.string_starts(str, value)
	return string.sub(str, 1, string.len(value)) == value
end

function gryphonlib.string_ends(str, value)
	return value == "" or string.sub(str, -string.len(value)) == value
end

function gryphonlib.shell_expansion(s, ...)
  local args = {...}
  args = #args == 1 and type(args[1]) == "table" and args[1] or args
  -- return true if there was an expansion
  local function DoExpand (iscode)
    local was = false
    local mask = iscode and "()%$(%b{})" or "()%$([%a%d_]*)"
    local drepl = iscode and "\\$" or "\\\\$"
    s = s:gsub(mask, function (pos, code)
      if s:sub(pos-1, pos-1) == "\\" then return "$"..code
      else was = true
	  local v, err
        if iscode then code = code:sub(2, -2)
        else local n = tonumber(code)
          if n then v = args[n] end
        end
        if not v then
          v, err = loadstring("return "..code)
		  if not v then error(err) end
          v = v()
        end
        if v == nil then v = "" end
        v = tostring(v):gsub("%$", drepl)
        return v
      end
    end)
    if not (iscode or was) then s = s:gsub("\\%$", "$") end
    return was
  end;

  repeat DoExpand(true) until not DoExpand(false)
  return s
end