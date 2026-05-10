-- Fractional indexing: generate string keys that sort lexicographically
-- between two existing keys. Allows ordered insertion in arbitrary positions
-- without renumbering, with key length growing logarithmically with the
-- number of mid-insertions between the same pair of neighbors.
--
-- Algorithm: base-62 with a leading "exponent" character that encodes the
-- integer-part length. Lowercase head = positive (a..z = lengths 2..27);
-- uppercase head = negative (Z..A = lengths 2..27). Lexicographic ordering
-- matches numeric ordering by construction.
--
-- API:
--   between(prev, next)  → returns a key strictly between prev and next.
--                          Pass nil for either end to mean "before all"
--                          (prev=nil) or "after all" (next=nil).
--   between(nil, nil)    → "a0"  (the canonical starting key)
--
-- Errors when prev >= next, when either key is malformed, or when the
-- algorithm has exhausted the integer-part range (very rare; only matters
-- if you've inserted billions of items at the same boundary).

local M = {}

local DIGITS = "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz"
local BASE = 62
local INTEGER_ZERO = "a0"

local digit_index = {}
for i = 1, #DIGITS do
  digit_index[DIGITS:sub(i, i)] = i - 1
end

local function digit_at(idx)
  return DIGITS:sub(idx + 1, idx + 1)
end

local function integer_length(head)
  local b = head:byte()
  if b >= 0x61 and b <= 0x7A then -- 'a'..'z'
    return b - 0x61 + 2
  elseif b >= 0x41 and b <= 0x5A then -- 'A'..'Z'
    return 0x5A - b + 2
  else
    error("invalid order key head: " .. head)
  end
end

local function integer_part(key)
  local len = integer_length(key:sub(1, 1))
  if len > #key then
    error("invalid order key (too short): " .. key)
  end
  return key:sub(1, len)
end

local function validate_integer(int)
  if #int ~= integer_length(int:sub(1, 1)) then
    error("invalid integer part: " .. int)
  end
end

local function validate_key(key)
  if #key == 0 then
    error("invalid order key (empty)")
  end
  -- integer_length will error if the head char is invalid
  local ilen = integer_length(key:sub(1, 1))
  if ilen > #key then
    error("invalid order key (too short for integer part): " .. key)
  end
  -- ensure all digits are valid
  for i = 1, #key do
    if not digit_index[key:sub(i, i)] then
      error("invalid order key digit: " .. key)
    end
  end
  -- A trailing 0 in the fractional part is forbidden because it would
  -- create an alternate spelling of the same logical position. The
  -- integer part itself can end in 0 (e.g. "a0").
  if key:sub(-1) == "0" and #key > ilen then
    error("invalid order key (trailing zero in fractional part): " .. key)
  end
end

local function increment_integer(x)
  validate_integer(x)
  local head = x:sub(1, 1)
  local digs = {}
  for i = 2, #x do digs[#digs + 1] = x:sub(i, i) end
  local carry = true
  for i = #digs, 1, -1 do
    if not carry then break end
    local d = digit_index[digs[i]] + 1
    if d == BASE then
      digs[i] = "0"
    else
      digs[i] = digit_at(d)
      carry = false
    end
  end
  if carry then
    if head == "Z" then
      return "a0"
    elseif head == "z" then
      return nil
    end
    local h = string.char(head:byte() + 1)
    if h > "a" then
      digs[#digs + 1] = "0"
    else
      digs[#digs] = nil
    end
    return h .. table.concat(digs)
  end
  return head .. table.concat(digs)
end

local function decrement_integer(x)
  validate_integer(x)
  local head = x:sub(1, 1)
  local digs = {}
  for i = 2, #x do digs[#digs + 1] = x:sub(i, i) end
  local borrow = true
  for i = #digs, 1, -1 do
    if not borrow then break end
    local d = digit_index[digs[i]] - 1
    if d == -1 then
      digs[i] = digit_at(BASE - 1)
    else
      digs[i] = digit_at(d)
      borrow = false
    end
  end
  if borrow then
    if head == "a" then
      return "Zz"
    elseif head == "A" then
      return nil
    end
    local h = string.char(head:byte() - 1)
    if h < "Z" then
      digs[#digs + 1] = digit_at(BASE - 1)
    else
      digs[#digs] = nil
    end
    return h .. table.concat(digs)
  end
  return head .. table.concat(digs)
end

local midpoint
midpoint = function (a, b)
  if b ~= "" and a ~= nil and a >= b then
    error("a >= b in midpoint: " .. a .. " >= " .. b)
  end
  if (a ~= "" and a:sub(-1) == "0") or (b ~= "" and b:sub(-1) == "0") then
    error("trailing zero")
  end
  if b ~= "" then
    -- Find common prefix
    local n = 0
    while true do
      local ca = (n + 1 <= #a) and a:sub(n + 1, n + 1) or "0"
      local cb = b:sub(n + 1, n + 1)
      if ca ~= cb or cb == "" then break end
      n = n + 1
    end
    if n > 0 then
      return b:sub(1, n) .. midpoint(a:sub(n + 1), b:sub(n + 1))
    end
  end
  local digit_a = (a ~= "") and digit_index[a:sub(1, 1)] or 0
  local digit_b = (b ~= "") and digit_index[b:sub(1, 1)] or BASE
  if digit_b - digit_a > 1 then
    local mid = math.floor(0.5 * (digit_a + digit_b) + 0.5)
    return digit_at(mid)
  end
  if b ~= "" and #b > 1 then
    return b:sub(1, 1)
  end
  return digit_at(digit_a) .. midpoint(a == "" and "" or a:sub(2), "")
end

-- Compute a key strictly between prev and next. Pass nil for either to
-- indicate "no bound on that side" (smaller-than-everything for prev,
-- larger-than-everything for next).
M.between = function (prev, next_)
  if prev ~= nil then validate_key(prev) end
  if next_ ~= nil then validate_key(next_) end
  if prev ~= nil and next_ ~= nil and prev >= next_ then
    error("prev >= next: " .. prev .. " >= " .. next_)
  end
  if prev == nil then
    if next_ == nil then
      return INTEGER_ZERO
    end
    local ib = integer_part(next_)
    local fb = next_:sub(#ib + 1)
    if ib == "A0" then
      return "Zz" .. midpoint("", fb)
    end
    if ib < next_ then
      return ib
    end
    local dec = decrement_integer(ib)
    if dec == nil then
      error("cannot decrement integer below smallest")
    end
    return dec
  end
  if next_ == nil then
    local ia = integer_part(prev)
    local fa = prev:sub(#ia + 1)
    local inc = increment_integer(ia)
    if inc == nil then
      return ia .. midpoint(fa, "")
    end
    return inc
  end
  local ia = integer_part(prev)
  local fa = prev:sub(#ia + 1)
  local ib = integer_part(next_)
  local fb = next_:sub(#ib + 1)
  if ia == ib then
    return ia .. midpoint(fa, fb)
  end
  local inc = increment_integer(ia)
  if inc == nil then
    error("cannot increment any more")
  end
  if inc < next_ then
    return inc
  end
  return ia .. midpoint(fa, "")
end

-- Generate n keys, evenly distributed, between prev and next. Useful for
-- bulk migration / initial seeding so we don't pessimize the structure
-- with all keys at one extreme.
M.between_n = function (prev, next_, n)
  if n <= 0 then return {} end
  if n == 1 then return { M.between(prev, next_) } end
  -- Recurse: split in half repeatedly. A balanced split keeps key lengths
  -- short for typical bulk insertions.
  local mid = M.between(prev, next_)
  local left_n = math.floor(n / 2)
  local right_n = n - left_n - 1
  local left = M.between_n(prev, mid, left_n)
  local right = M.between_n(mid, next_, right_n)
  local out = {}
  for _, k in ipairs(left) do out[#out + 1] = k end
  out[#out + 1] = mid
  for _, k in ipairs(right) do out[#out + 1] = k end
  return out
end

-- Validate a key is well-formed (raises on malformed). Useful at sync /
-- import boundaries.
M.validate = validate_key

return M
