local test = require("santoku.test")
local fi = require("santoku.fracidx")

test("between empty and empty returns canonical zero", function ()
  assert(fi.between(nil, nil) == "a0")
end)

test("between nil and a key produces a key before it", function ()
  local k = fi.between(nil, "a1")
  assert(k < "a1")
  assert(fi.between(nil, "a0") == "Zz")
end)

test("between a key and nil produces a key after it", function ()
  local a0_next = fi.between("a0", nil)
  assert(a0_next > "a0")
  assert(a0_next == "a1")
end)

test("between two keys produces a strictly-between key", function ()
  local mid = fi.between("a0", "a1")
  assert(mid > "a0" and mid < "a1", "mid was: " .. tostring(mid))
end)

test("repeated mid-insertion stays sorted", function ()
  local a, b = "a0", "a1"
  for _ = 1, 50 do
    local m = fi.between(a, b)
    assert(m > a and m < b)
    a = m
  end
end)

test("appending many keys stays compact", function ()
  local prev = nil
  local last
  for _ = 1, 100 do
    local k = fi.between(prev, nil)
    if prev then assert(k > prev) end
    prev = k
    last = k
  end
  -- 100 sequential appends should not produce an absurdly long key.
  assert(#last <= 4, "key grew too long: " .. last)
end)

test("between rejects prev >= next", function ()
  local ok = pcall(fi.between, "a1", "a0")
  assert(not ok)
  ok = pcall(fi.between, "a0", "a0")
  assert(not ok)
end)

test("between_n produces n distinct sorted keys", function ()
  local ks = fi.between_n("a0", "a5", 4)
  assert(#ks == 4)
  local prev = "a0"
  for _, k in ipairs(ks) do
    assert(k > prev, "not sorted: " .. prev .. " < " .. k)
    prev = k
  end
  assert(prev < "a5")
end)

test("validate accepts well-formed keys and rejects malformed", function ()
  fi.validate("a0")
  fi.validate("a1")
  fi.validate("Zz")
  fi.validate("b0V")
  local ok = pcall(fi.validate, "a0V0") -- trailing 0 in fractional part
  assert(not ok)
  ok = pcall(fi.validate, "a")          -- too short for integer part
  assert(not ok)
  ok = pcall(fi.validate, "0a")         -- invalid head
  assert(not ok)
end)

test("lex order matches insertion order across many ops", function ()
  -- Mix insert-at-end, insert-at-front, and mid-insert operations and
  -- assert the resulting key list is strictly sorted at every step.
  local keys = { fi.between(nil, nil) }
  for i = 1, 30 do
    if i % 3 == 0 then
      table.insert(keys, 1, fi.between(nil, keys[1]))
    elseif i % 3 == 1 then
      table.insert(keys, fi.between(keys[#keys], nil))
    else
      local mid_idx = math.floor(#keys / 2)
      if mid_idx >= 1 and mid_idx < #keys then
        local m = fi.between(keys[mid_idx], keys[mid_idx + 1])
        table.insert(keys, mid_idx + 1, m)
      end
    end
    for j = 2, #keys do
      assert(keys[j - 1] < keys[j],
        "out of order at step " .. i .. ": " .. keys[j - 1] .. " >= " .. keys[j])
    end
  end
end)
