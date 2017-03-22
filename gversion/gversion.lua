---------
-- Lua library for Gentoo-style versioning format
--
-- **Examples:**
--     local ver = require "gversion"
--
--     -- Parse version
--     local pkgver = ver.parse("2.1_rc3-r1")
--     local pkgver = ver"2.1_rc3-r1"
--
--     -- Access version components
--     pkgver[1]     --> "2"
--     pkgver.major  --> "2"
--     pkgver[2]     --> "1"
--     pkgver.minor  --> "1"
--     pkgver.rc     --> "3"
--     pkgver.r      --> "1"
--
--     -- Change version components
--     pkgver[1] = "2"     -- 2.1_rc3-r1
--     pkgver.minor = "0"  -- 2.0_rc3-r1
--     pkgver.rc = nil     -- 2.0-r1
--
--     -- Compare versions
--     ver"1.5" == ver"1.005"           --> true
--     ver"1.2_rc1" < ver"1.2b"         --> true
--     ver"1.2_beta_pre" > ver"1.2_p1"  --> false
--
--     -- Normalize version; try to convert it into our versioning format
--     ver.normalize("2_1-beta3")  --> "2.1_beta3"
--     ver.normalize("2.1b3")      --> "2.1_beta3"
--
-- See <https://devmanual.gentoo.org/ebuild-writing/file-format/#file-naming-rules>
-- for specification of the versioning format.
--
-- @author Jakub Jirutka <jakub@jirutka.cz>
-- @license MIT
--

local format = string.format
local join = table.concat

local function cmp (a, b, field, conv, default)
  local lhs = conv(a[field]) or default
  local rhs = conv(b[field]) or default

  if lhs == rhs then
    return 0
  elseif lhs > rhs then
    return 1
  else
    return -1
  end
end

local function identity (a)
  return a
end


local M = {}

--- Version of this module.
M._VERSION = '0.2.0'

-- List of pre/post-release suffixes (initialized in `set_suffixes`).
local suffixes_pre = {}
local suffixes_post = {}

-- Map of all suffixes as keys for quick lookup (initialized in `set_suffixes`).
local suffixes = {}

-- List of field aliases.
local aliases = { major = 1, minor = 2, tiny = 3 }


--- Sets pre-release and post-release suffixes.
--
-- Default pre-release suffixes are: *alpha, beta, pre, rc*.
-- Default post-release suffixes are: *p*.
--
-- Suffix **must not** be `r` or `suffix`, these have special meaning!
--
-- @tparam {string,...} pre_release
-- @tparam {string,...} post_release
function M.set_suffixes (pre_release, post_release)
  suffixes_pre = pre_release
  suffixes_post = post_release
  suffixes = {}

  for _, list in ipairs { suffixes_pre, suffixes_post } do
    for _, suffix in ipairs(list) do
      suffixes[suffix] = true
    end
  end
end

-- Initialize default suffixes.
M.set_suffixes({ 'alpha', 'beta', 'pre', 'rc' }, { 'p' })


-- Metatable for `Version` type.
local meta = {}

function meta:__eq (other)
  return M.compare(self, other) == 0
end

function meta:__lt (other)
  return M.compare(self, other) == -1
end

function meta:__index (key)
  key = aliases[key] or key
  return rawget(self, key)
end

function meta:__newindex (key, value)
  key = aliases[key] or key
  rawset(self, key, value)
end

function meta:__tostring ()
  local res = join(self, '.')

  if self.suffix then
    res = res..self.suffix
  end

  for _, list in ipairs { suffixes_pre, suffixes_post } do
    for _, suffix in ipairs(list) do
      local val = self[suffix]
      if val then
        res = res..'_'..suffix..(val ~= '0' and val or '')
      end
    end
  end

  if self.r then
    res = res..'-r'..self.r
  end

  return res
end


--- Compares two versions.
--
-- @tparam Version a
-- @tparam Version b
-- @treturn number -1 if `a < b`, 0 if `a == b`, or 1 if `a > b`
function M.compare (a, b)
  local res

  -- Numerical part
  for i=1, math.max(#a, #b) do
    res = cmp(a, b, i, tonumber, 0)
    if res ~= 0 then return res end
  end

  -- A Letter after the final number
  res = cmp(a, b, 'suffix', identity, '')
  if res ~= 0 then return res end

  -- Pre-release suffixes
  for _, suffix in ipairs(suffixes_pre) do
    res = cmp(a, b, suffix, tonumber, math.huge)
    if res ~= 0 then return res end
  end

  -- Post-release suffixes
  for _, suffix in ipairs(suffixes_post) do
    res = cmp(a, b, suffix, tonumber, -1)
    if res ~= 0 then return res end
  end

  -- Revision
  res = cmp(a, b, 'r', tonumber, 0)
  if res ~= 0 then return res end

  return 0
end

--- Tries to convert the given `version` into a Gentoo-style versioning format.
--
-- The conversion consists of:
--
-- * converting all letters to lowercase (1)
-- * removing all whitespaces (2)
-- * removing prefix "v" and "r" (3)
-- * replacing "_" and "-" between each two numbers with "." (4)
-- * inserting "_" between a digit and a known suffix (5.1)
-- * replacing "." and "-" between a digit and a known suffix with "_" (5.1)
-- * replacing "a", ".a", and "-a" between two numbers with "_alpha" (5.2)
-- * replacing "b", ".b", and "-b" between two numbers with "_beta" (5.2)
--
-- Note: There's no guarantee that the result will really be a valid version
-- number! Always pass it to `parse` for validation.
--
-- @tparam string version
-- @treturn string
-- @raise Error when `version` is not a string.
function M.normalize (version)
  assert(type(version) == 'string', 'version must be a string', 2)

  local suffix_aliases = { a = 'alpha', b = 'beta' }

  return version
    :lower()  -- 1
    :gsub('%s', '')  -- 2
    :gsub('^[rv]', '', 1)  -- 3
    :gsub('(%d+)[_%-]%f[%d]', '%1.')  -- 4
    :gsub('(%d)[_%.%-]?(%l+)(%d*)', function(leading, letters, digits)  -- 5
      if suffixes[letters] then
        return leading..'_'..letters..digits  -- 5.1
      elseif digits ~= '' and suffix_aliases[letters] then
        return leading..'_'..suffix_aliases[letters]..digits  -- 5.2
      end
    end)
end

--- Parses given `str` and returns `Version`, if `str` is a valid version.
--
-- @tparam string str The string to parse.
-- @treturn Version A parsed version.
-- @error An error message if version is malformed.
-- @raise Error when `str` is not a string.
function M.parse (str)
  assert(type(str) == 'string', 'str must be a string', 2)

  local version = {}
  local pos = 1

  -- This leading dot allows to avoid special case of the first number
  -- component in the version and also ensures that at least one number
  -- component is matched (the following patterns don't match leading dot).
  str = '.'..str

  -- Numbers
  while true do
    local _, eend, digits = str:find('^%.(%d+)', pos)
    if not eend then break end

    table.insert(version, digits)
    pos = eend + 1
  end

  -- A letter after the final number
  if str:match('^%l', pos) then
    version['suffix'] = str:sub(pos, pos)
    pos = pos + 1
  end

  -- Suffixes
  while true do
    local _, eend , suffix, digits = str:find('^_(%l+)(%d*)', pos)
    if not eend then break end

    if not suffixes[suffix] then
      return nil, format("Malformed version %s, unknown suffix %s",
                         str:sub(2), suffix)  -- remove leading dot
    end
    version[suffix] = tonumber(digits) and digits or '0'
    pos = eend + 1
  end

  -- Revision
  do
    local _, eend, digits = str:find('^-r(%d+)', pos)
    if eend then
      version['r'] = digits
      pos = eend + 1
    end
  end

  if #str ~= pos - 1 then
    return nil, 'Malformed version: '..str:sub(2)  -- remove leading dot
  end

  return setmetatable(version, meta)
end


--- An alias for `parse`.
-- @function __call
return setmetatable(M, {
  __call = function(_, ...)
    return M.parse(...)
  end,
})
