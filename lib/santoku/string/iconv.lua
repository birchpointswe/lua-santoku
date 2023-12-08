local compat = require("santoku.compat")
local iconv = require("iconv")

local function strerror (e)
  return ({
    [iconv.ERROR_NO_MEMORY] = "no memory",
    [iconv.ERROR_INVALID] = "invalid",
    [iconv.ERROR_INCOMPLETE] = "incomplete",
    [iconv.ERROR_FINALIZED] = "finalized",
    [iconv.ERROR_UNKNOWN] = "unknown"
  })[e] or "unknown iconv error", e
end

return function (s, from, to, flag)

  assert(compat.istype.string(from))
  assert(compat.istype.string(to))
  assert(flag == nil or compat.istype.string(flag))

  from = string.upper(from)
  to = string.upper(to)

  if flag then
    to = to .. "//" .. string.upper(flag)
  end

  local ic, err = iconv.open(to, from)

  if err then
    return false, strerror(err)
  end

  local s0, err = ic:iconv(s)

  if err then
    return false, strerror(err)
  end

  return true, s0

end
