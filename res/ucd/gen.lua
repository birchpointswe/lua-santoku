local UCD_VERSION = "16.0.0"

local SOURCES = {
  ["UnicodeData.txt"] =
    "https://www.unicode.org/Public/" .. UCD_VERSION .. "/ucd/UnicodeData.txt",
  ["CaseFolding.txt"] =
    "https://www.unicode.org/Public/" .. UCD_VERSION .. "/ucd/CaseFolding.txt",
}

local function lines (path)
  local f = io.open(path, "r")
  if not f then
    io.stderr:write(
      "gen.lua: " .. path .. " not found in the working directory.\n" ..
      "This generator produces lib/santoku/string/utf8.h from the Unicode Character\n" ..
      "Database, which is not vendored. Fetch both inputs for UCD " .. UCD_VERSION ..
      " and rerun:\n" ..
      "  curl -fsSLO " .. SOURCES["UnicodeData.txt"] .. "\n" ..
      "  curl -fsSLO " .. SOURCES["CaseFolding.txt"] .. "\n" ..
      "  lua5.1 gen.lua ../../lib/santoku/string/utf8.h\n")
    os.exit(1)
  end
  local t = {}
  for l in f:lines() do t[#t + 1] = l end
  f:close()
  return t
end

local function fields (l)
  local t = {}
  local pos = 1
  while true do
    local b = string.find(l, ";", pos, true)
    if not b then t[#t + 1] = string.sub(l, pos) break end
    t[#t + 1] = string.sub(l, pos, b - 1)
    pos = b + 1
  end
  return t
end

local function trim (s)
  return (string.gsub(string.gsub(s, "^%s+", ""), "%s+$", ""))
end

local lower = {}
for _, l in ipairs(lines("UnicodeData.txt")) do
  local f = fields(l)
  if f[1] and f[14] and f[14] ~= "" then
    local cp = tonumber(f[1], 16)
    local to = tonumber(f[14], 16)
    if cp ~= to then lower[cp] = to end
  end
end

local fold1 = {}
local foldn = {}
for _, l in ipairs(lines("CaseFolding.txt")) do
  local h = string.find(l, "#", 1, true)
  if h then l = string.sub(l, 1, h - 1) end
  l = trim(l)
  if l ~= "" then
    local f = fields(l)
    local cp = tonumber(trim(f[1]), 16)
    local st = trim(f[2])
    local map = {}
    for m in string.gmatch(trim(f[3]), "%x+") do map[#map + 1] = tonumber(m, 16) end
    if st == "C" then
      assert(#map == 1)
      if map[1] ~= cp then fold1[cp] = map[1] end
    elseif st == "F" then
      assert(#map > 1)
      foldn[cp] = map
    end
  end
end

local function compress (map)
  local cps = {}
  for cp in pairs(map) do cps[#cps + 1] = cp end
  table.sort(cps)
  local ranges = {}
  local i = 1
  while i <= #cps do
    local lo = cps[i]
    local delta = map[lo] - lo
    local n1 = 1
    while i + n1 <= #cps and cps[i + n1] == lo + n1 and map[cps[i + n1]] - cps[i + n1] == delta do
      n1 = n1 + 1
    end
    local n2 = 1
    while i + n2 <= #cps and cps[i + n2] == lo + 2 * n2 and map[cps[i + n2]] - cps[i + n2] == delta
      and map[lo + 2 * n2 - 1] == nil do
      n2 = n2 + 1
    end
    if n2 > n1 then
      ranges[#ranges + 1] = { lo, lo + 2 * (n2 - 1), 2, delta }
      i = i + n2
    else
      ranges[#ranges + 1] = { lo, lo + (n1 - 1), 1, delta }
      i = i + n1
    end
  end
  return ranges
end

local function lookup (ranges, cp)
  local a, b = 1, #ranges
  while a <= b do
    local m = math.floor((a + b) / 2)
    local r = ranges[m]
    if cp < r[1] then b = m - 1
    elseif cp > r[2] then a = m + 1
    else
      if (cp - r[1]) % r[3] == 0 then return cp + r[4] end
      return cp
    end
  end
  return cp
end

local function verify (ranges, map, name)
  for i = 2, #ranges do
    assert(ranges[i][1] > ranges[i - 1][2], name .. ": overlapping ranges")
  end
  for cp = 0, 0x10FFFF do
    local want = map[cp] or cp
    local got = lookup(ranges, cp)
    assert(got == want, string.format("%s: U+%04X want %X got %X", name, cp, want, got))
  end
end

local function utf8 (cp)
  if cp < 0x80 then
    return string.char(cp)
  elseif cp < 0x800 then
    return string.char(0xC0 + math.floor(cp / 64), 0x80 + cp % 64)
  elseif cp < 0x10000 then
    return string.char(0xE0 + math.floor(cp / 4096), 0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
  else
    return string.char(0xF0 + math.floor(cp / 262144), 0x80 + math.floor(cp / 4096) % 64,
      0x80 + math.floor(cp / 64) % 64, 0x80 + cp % 64)
  end
end

local lr = compress(lower)
local fr = compress(fold1)
verify(lr, lower, "lower")
verify(fr, fold1, "fold")

local fkeys = {}
for cp in pairs(foldn) do fkeys[#fkeys + 1] = cp end
table.sort(fkeys)

local maxlen = 0
for _, cp in ipairs(fkeys) do
  local s = ""
  for _, c in ipairs(foldn[cp]) do s = s .. utf8(c) end
  if #s > maxlen then maxlen = #s end
end

for _, cp in ipairs(fkeys) do
  assert(fold1[cp] == nil, string.format("U+%04X in both C and F", cp))
end

local out = {}
local function w (s) out[#out + 1] = s end

w("#ifndef TK_STRING_UTF8_H")
w("#define TK_STRING_UTF8_H")
w("")
w("#include <stdint.h>")
w("#include <stddef.h>")
w("")
w("#define TK_UTF8_FOLD_MAX " .. maxlen)
w("")
w("typedef struct {")
w("  uint32_t lo;")
w("  uint32_t hi;")
w("  uint8_t step;")
w("  int32_t delta;")
w("} tk_utf8_range_t;")
w("")
w("typedef struct {")
w("  uint32_t cp;")
w("  uint8_t len;")
w("  char bytes[TK_UTF8_FOLD_MAX];")
w("} tk_utf8_expand_t;")
w("")

local function emit_ranges (name, ranges)
  w("static const tk_utf8_range_t " .. name .. "[" .. #ranges .. "] = {")
  for i = 1, #ranges do
    local r = ranges[i]
    w(string.format("  { 0x%X, 0x%X, %d, %d },", r[1], r[2], r[3], r[4]))
  end
  w("};")
  w("")
end

emit_ranges("tk_utf8_lower_ranges", lr)
emit_ranges("tk_utf8_fold_ranges", fr)

w("static const tk_utf8_expand_t tk_utf8_fold_expand[" .. #fkeys .. "] = {")
for _, cp in ipairs(fkeys) do
  local s = ""
  for _, c in ipairs(foldn[cp]) do s = s .. utf8(c) end
  local esc = {}
  for i = 1, maxlen do
    esc[#esc + 1] = i <= #s and string.format("'\\x%02x'", string.byte(s, i)) or "0"
  end
  w(string.format("  { 0x%X, %d, { %s } },", cp, #s, table.concat(esc, ", ")))
end
w("};")
w("")

w([[
static inline uint32_t tk_utf8_map (const tk_utf8_range_t *rs, size_t n, uint32_t cp)
{
  size_t a = 0, b = n;
  while (a < b) {
    size_t m = a + (b - a) / 2;
    if (cp < rs[m].lo) b = m;
    else if (cp > rs[m].hi) a = m + 1;
    else return ((cp - rs[m].lo) % (uint32_t) rs[m].step) ? cp : (uint32_t) ((int32_t) cp + rs[m].delta);
  }
  return cp;
}

static inline uint32_t tk_utf8_lower_cp (uint32_t cp)
{
  return tk_utf8_map(tk_utf8_lower_ranges, sizeof(tk_utf8_lower_ranges) / sizeof(tk_utf8_range_t), cp);
}

static inline uint32_t tk_utf8_fold_cp (uint32_t cp)
{
  return tk_utf8_map(tk_utf8_fold_ranges, sizeof(tk_utf8_fold_ranges) / sizeof(tk_utf8_range_t), cp);
}

static inline const tk_utf8_expand_t *tk_utf8_fold_full (uint32_t cp)
{
  size_t a = 0, b = sizeof(tk_utf8_fold_expand) / sizeof(tk_utf8_expand_t);
  while (a < b) {
    size_t m = a + (b - a) / 2;
    if (cp < tk_utf8_fold_expand[m].cp) b = m;
    else if (cp > tk_utf8_fold_expand[m].cp) a = m + 1;
    else return &tk_utf8_fold_expand[m];
  }
  return NULL;
}

static inline int tk_utf8_decode (const char *s, size_t len, size_t pos, uint32_t *cp)
{
  uint8_t c = (uint8_t) s[pos];
  if (c < 0x80) {
    *cp = c;
    return 1;
  }
  int n;
  uint32_t v;
  if ((c & 0xE0) == 0xC0) { n = 2; v = (uint32_t) (c & 0x1F); }
  else if ((c & 0xF0) == 0xE0) { n = 3; v = (uint32_t) (c & 0x0F); }
  else if ((c & 0xF8) == 0xF0) { n = 4; v = (uint32_t) (c & 0x07); }
  else return 0;
  if (pos + (size_t) n > len)
    return 0;
  for (int i = 1; i < n; i ++) {
    uint8_t cc = (uint8_t) s[pos + (size_t) i];
    if ((cc & 0xC0) != 0x80)
      return 0;
    v = (v << 6) | (uint32_t) (cc & 0x3F);
  }
  if (n == 2 ? v < 0x80u : n == 3 ? v < 0x800u : v < 0x10000u)
    return 0;
  if (v > 0x10FFFFu || (v >= 0xD800u && v <= 0xDFFFu))
    return 0;
  *cp = v;
  return n;
}

static inline int tk_utf8_encode (uint32_t cp, char *out)
{
  if (cp < 0x80u) {
    out[0] = (char) cp;
    return 1;
  } else if (cp < 0x800u) {
    out[0] = (char) (0xC0u | (cp >> 6));
    out[1] = (char) (0x80u | (cp & 0x3Fu));
    return 2;
  } else if (cp < 0x10000u) {
    out[0] = (char) (0xE0u | (cp >> 12));
    out[1] = (char) (0x80u | ((cp >> 6) & 0x3Fu));
    out[2] = (char) (0x80u | (cp & 0x3Fu));
    return 3;
  } else {
    out[0] = (char) (0xF0u | (cp >> 18));
    out[1] = (char) (0x80u | ((cp >> 12) & 0x3Fu));
    out[2] = (char) (0x80u | ((cp >> 6) & 0x3Fu));
    out[3] = (char) (0x80u | (cp & 0x3Fu));
    return 4;
  }
}

#endif]])

local f = assert(io.open(arg[1], "w"))
f:write(table.concat(out, "\n"), "\n")
f:close()

io.write(string.format("lower ranges: %d\nfold ranges: %d\nfold expansions: %d\nmax fold bytes: %d\n",
  #lr, #fr, #fkeys, maxlen))
