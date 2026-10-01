-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023 Birch Point SWE
local test = require("santoku.test")
local fi = require("santoku.fracidx")
local arr = require("santoku.array")
local num = require("santoku.num")

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
  local ok = pcall(fi.validate, "a0V0")
  assert(not ok)
  ok = pcall(fi.validate, "a")
  assert(not ok)
  ok = pcall(fi.validate, "0a")
  assert(not ok)
end)

test("suffix encodes fixed width, sorts numerically, never ends in zero", function ()
  assert(fi.suffix(0, 1) == "1")
  assert(fi.suffix(60, 1) == "z")
  assert(fi.suffix(0, 3) == "111")
  assert(fi.suffix(61, 2) == "21")
  assert(#fi.suffix(12345, 4) == 4)
  local prev = nil
  for i = 0, 61 * 61 - 1, 7 do
    local s = fi.suffix(i, 2)
    assert(#s == 2)
    assert(s:sub(-1) ~= "0")
    if prev then assert(prev < s, prev .. " >= " .. s) end
    prev = s
  end
  assert(fi.suffix_desc(0, 2) == fi.suffix(61 * 61 - 1, 2))
  assert(fi.suffix_desc(5, 2) > fi.suffix_desc(6, 2))
  assert(not pcall(fi.suffix, 61, 1))
  assert(not pcall(fi.suffix, -1, 1))
  assert(not pcall(fi.suffix, 1.5, 1))
  assert(not pcall(fi.suffix, 1, 0))
  assert(not pcall(fi.suffix, 1, 9))
end)

test("gap keys sit strictly inside the interval for every suffix", function ()
  local function check (a, b)
    local g = fi.gap(a, b)
    assert(g:sub(1, #a) == a)
    for _, s in ipairs({ "1", "z", "11", "zz", "1z1", fi.suffix(3000, 3) }) do
      local k = g .. s
      fi.validate(k)
      assert(k > a, k .. " <= " .. a)
      if b then assert(k < b, k .. " >= " .. b) end
      local k2 = k .. fi.suffix(7, 2)
      fi.validate(k2)
      assert(k2 > k)
      if b then assert(k2 < b) end
    end
    if b then
      local p = fi.between(a, b)
      local gp = fi.gap(a, p)
      assert(gp .. "zzzz" < p, gp .. "zzzz >= " .. p)
    end
  end
  check("a0", "a1")
  check("a0", "a0V")
  check("a0V", "a0VG")
  check("a0V", "a0V1")
  check("a0V", "a0V01")
  check("a0V", "a0V001")
  check("a0V", "a0W")
  check("a0", "b00")
  check("Zz", "a0")
  check("a0", nil)
  check("a0V", nil)
  local keys = { fi.between(nil, nil) }
  for i = 1, 40 do
    if i % 2 == 0 then
      arr.push(keys, fi.between(keys[#keys], nil))
    else
      local m = num.floor(#keys / 2)
      if m >= 1 then
        arr.insert(keys, m + 1, fi.between(keys[m], keys[m + 1]))
      end
    end
  end
  for i = 1, #keys - 1 do
    check(keys[i], keys[i + 1])
  end
  assert(not pcall(fi.gap, "a1", "a0"))
  assert(not pcall(fi.gap, "a0", "a0"))
  assert(not pcall(fi.validate, fi.gap("a0", "a1")))
end)

test("lex order matches insertion order across many ops", function ()

  local keys = { fi.between(nil, nil) }
  for i = 1, 30 do
    if i % 3 == 0 then
      arr.insert(keys, 1, fi.between(nil, keys[1]))
    elseif i % 3 == 1 then
      arr.push(keys, fi.between(keys[#keys], nil))
    else
      local mid_idx = num.floor(#keys / 2)
      if mid_idx >= 1 and mid_idx < #keys then
        local m = fi.between(keys[mid_idx], keys[mid_idx + 1])
        arr.insert(keys, mid_idx + 1, m)
      end
    end
    for j = 2, #keys do
      assert(keys[j - 1] < keys[j],
        "out of order at step " .. i .. ": " .. keys[j - 1] .. " >= " .. keys[j])
    end
  end
end)
