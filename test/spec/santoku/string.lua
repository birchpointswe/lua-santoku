local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local err = require("santoku.error")
local assert = err.assert

local arr = require("santoku.array")
local amap = arr.map

local tbl = require("santoku.table")
local teq = tbl.equals
local tmap = tbl.map

local vdt = require("santoku.validate")
local eq = vdt.isequal

local str = require("santoku.string")
local ssplit = str.splits
local smatch = str.matches
local sinterp = str.interp

test("split", function ()
  assert(teq(ssplit("this is a test", "%s+"), { "this", "is", "a", "test" }))
  assert(teq(ssplit("a b c", "%s+"), { "a", "b", "c" }))
  assert(teq(ssplit("a b c   ", "%s+"), { "a", "b", "c", "" }))
  assert(teq(amap(ssplit("10 39.5 46.8", "%s+"), tonumber), { 10, 39.5, 46.8 }))
end)

test("match", function ()
  assert(teq(smatch("this is a test", "%S+"), { "this", "is", "a", "test" }))
  assert(teq(smatch("this is a test  ", "%S+"), { "this", "is", "a", "test" }))
  assert(teq(amap(smatch("10 39.5 46.8", "%S+"), tonumber), { 10, 39.5, 46.8 }))
end)

test("match with delim", function ()
  assert(teq(ssplit("a b c", "%s+", true), { "a", " ", "b", " ", "c" }))
  assert(teq(ssplit("a b c", "%s+", true), { "a", " ", "b", " ", "c" }))
  assert(teq(ssplit("a   b c  ", "%s+", true), { "a", "   ", "b", " ", "c", "  " }))
  assert(teq(ssplit("a b c", "%s+", "right"), { "a", " b", " c" }))
  assert(teq(ssplit("a b c", "%s+", "left"), { "a ", "b ", "c" }))
end)

test("split with delim", function ()
  assert(teq(ssplit("a b c", "%s+", true), { "a", " ", "b", " ", "c" }))
  assert(teq(ssplit("a b c", "%s+", "right"), { "a", " b", " c" }))
  assert(teq(ssplit("a b c", "%s+", "left"), { "a ", "b ", "c" }))
end)

test("match no matches", function ()
  assert(teq(smatch("a b c", "%d+"), {}))
end)

test("split no matches", function ()
  assert(teq(ssplit("a b c", "%d+"), { "a b c" }))
  assert(teq(ssplit("a b c", "%d+", true), { "a b c" }))
  assert(teq(ssplit("a b c", "%d+", "left"), { "a b c" }))
  assert(teq(ssplit("a b c", "%d+", "right"), { "a b c" }))
end)

test("split/match start/end", function ()
  assert(teq(ssplit("a b c d e", "%S+", false, 3, 7), { "", " ", " ", "" }))
  assert(teq(smatch("a b c d e", "%s+", 3, 7), { " ", " " }))
  assert(teq(ssplit("a b c d e", "%S+", false, 3, nil), { "", " ", " ", " ", "" }))
  assert(teq(smatch("a b c d e", "%s+", 3, nil), { " ", " ", " " }))
  assert(teq(ssplit("a b c d e", "%S+", false, nil, 7), { "", " ", " ", " ", "" }))
  assert(teq(smatch("a b c d e", "%s+", nil, 7), { " ", " ", " " }))
end)

test("split first char", function ()
  assert(teq(ssplit("asdf.tar.gz", "%.", false, 5), { "", "tar", "gz" }))
  assert(teq(ssplit("asdf.tar.gz", "%.", "right", 5), { "", ".tar", ".gz" }))
end)

test("interp", function ()

  test("should interpolate values", function ()
    local tmpl = "Hello %who, %adj to meet you!"
    local vals = { who = "World", adj = "nice" }
    local expected = "Hello World, nice to meet you!"
    local res = sinterp(tmpl, vals)
    assert(expected == res)
  end)

  test("should replace missing keys with blanks", function ()
    local tmpl = "This should be %adj: '%something'"
    local vals = { adj = "blank" }
    local expected = "This should be blank: ''"
    local res = sinterp(tmpl, vals)
    assert(expected == res)
  end)

  test("should work with integer indices on tables", function ()
    assert("a c b" == sinterp("%1 %3 %2", { "a", "b", "c" }))
  end)

  test("should support format strings", function ()
    assert("1.0" == sinterp("%.1f#(1)", { 1 }))
    assert("1.0" == sinterp("%.1f#(number)", { number = 1 }))
  end)

  test("should support long names", function ()
    assert("1" == sinterp("%(num_to_display)", { num_to_display = 1 }))
  end)

end)

test("parse", function ()

  test("should support mapping string.match strings into an object", function ()

    local s = "2023-10-26 09:10:26"
    local obj = str.parse(s, "(%d+)#(year)-(%d+)#(month)-(%d+)#(day) (%d+)#(hour):(%d+)#(minute):(%d+)#(second)")
    tmap(obj, tonumber)
    assert(teq({ year = 2023, month = 10, day = 26, hour = 9, minute = 10, second = 26 }, obj))

  end)

end)

test("quote", function ()
  local s = "hello"
  assert("\"hello\"" == str.quote(s))
end)

test("uquote", function ()
  local s = "\"hello\""
  assert("hello" == str.unquote(s))
end)

test("quote escapes the escape character", function ()
  assert("\"a\\\\\"" == str.quote("a\\"))
  assert("\"a\\\\b\"" == str.quote("a\\b"))
  assert("\"a\\\\\\\"b\"" == str.quote("a\\\"b"))
  assert("\"\\\\\\\\\"" == str.quote("\\\\"))
end)

test("quoted values are safe to embed", function ()
  local a = str.quote("ends with backslash\\")
  local b = str.quote("next")
  local doc = a .. "," .. b
  local _, close = str.find(doc, "^\"")
  assert(close == 1)
  local i = 2
  while i <= #doc do
    local c = str.sub(doc, i, i)
    if c == "\\" then
      i = i + 2
    elseif c == "\"" then
      break
    else
      i = i + 1
    end
  end
  assert(str.sub(doc, 1, i) == a)
  assert(str.sub(doc, i + 2) == b)
end)

test("unquote inverts quote", function ()
  local cases = {
    "",
    "hello",
    "a\\",
    "\\",
    "\\\\",
    "a\"b",
    "\"",
    "a\\\"b",
    "\\\"",
    "\"\\",
    "tab\tand\nnewline",
    "mixed \\\\ \" \\ end",
  }
  for i = 1, #cases do
    assert(cases[i] == str.unquote(str.quote(cases[i])))
  end
end)

test("unquote returns one value", function ()
  assert(1 == select("#", str.unquote("\"hello\"")))
  assert(1 == select("#", str.unquote("bare")))
end)

test("quote and unquote with a custom quote and escape string", function ()
  assert("'a|'b'" == str.quote("a'b", "'", "|"))
  assert("a'b" == str.unquote(str.quote("a'b", "'", "|"), "'", "|"))
  assert("a|b" == str.unquote(str.quote("a|b", "'", "|"), "'", "|"))
  assert("a|'b" == str.unquote(str.quote("a|'b", "'", "|"), "'", "|"))
end)

test("quote emits the quote string at both ends", function ()
  assert("<<a%b<<" == str.quote("a%b", "<<", ">>"))
  assert("<<a>><<b>>>>c<<" == str.quote("a<<b>>c", "<<", ">>"))
  assert("a%b" == str.unquote(str.quote("a%b", "<<", ">>"), "<<", ">>"))
  assert("a<<b>>c" == str.unquote(str.quote("a<<b>>c", "<<", ">>"), "<<", ">>"))
end)

test("quote escapes a percent in the quote or escape string", function ()
  assert("'a%%b'" == str.quote("a%b", "'", "%"))
  assert("a%b" == str.unquote(str.quote("a%b", "'", "%"), "'", "%"))
  assert("'a%'b'" == str.quote("a'b", "'", "%"))
  assert("a'b" == str.unquote(str.quote("a'b", "'", "%"), "'", "%"))
  assert("a%'b" == str.unquote(str.quote("a%'b", "'", "%"), "'", "%"))
end)

test("quote with an empty escape leaves the body untouched", function ()
  assert("'a'b'" == str.quote("a'b", "'", ""))
  assert("a'b" == str.unquote("'a'b'", "'", ""))
end)

test("unquote leaves unquoted input alone", function ()
  assert("hello" == str.unquote("hello"))
  assert("\"hello" == str.unquote("\"hello"))
  assert("hello\"" == str.unquote("hello\""))
end)

test("interp multiple", function ()
  assert(teq({ "hello world" }, { str.interp("%s#(greet) %s#(target)", { greet = "hello", target = "world" }) }))
end)

test("interp cloats", function ()
  assert(teq({ "1234.123" }, { str.interp("%4.3f#(score)", { score = 1234.1234 }) }))
end)

test("equals", function ()
  assert(teq({ true }, { str.equals("two", "one two three", 5, 7) }));
  assert(teq({ true }, { str.equals("one", "one two three", 1, 3) }));
  assert(teq({ false }, { str.equals("one", "one two three", -10, 3) }));
  assert(teq({ false }, { str.equals("one", "one two three", 0, 3) }));
  assert(teq({ false }, { str.equals("one", "one two three", 3, 1) }));
end)

test("to/from_hex", function ()
  local s = "this is an easy test"
  assert(eq(s, str.from_hex(str.to_hex(s))))
  assert(eq("", str.from_hex(str.to_hex(""))))
  assert(eq(" ", str.from_hex(str.to_hex(" "))))
  assert(eq("!", str.from_hex(str.to_hex("!"))))
  assert(eq("1234567890", str.from_hex(str.to_hex("1234567890"))))
  assert(eq("\xFF\xFE\xFD", str.from_hex(str.to_hex("\xFF\xFE\xFD"))))
  assert(eq("\x00\x01\x02\x03", str.from_hex(str.to_hex("\x00\x01\x02\x03"))))
end)

test("to/from_base64", function ()
  local s = "this is an easy test"
  assert(eq(s, str.from_base64(str.to_base64(s))))
  assert(eq("", str.from_base64(str.to_base64(""))))
  assert(eq("A", str.from_base64(str.to_base64("A"))))
  assert(eq("AB", str.from_base64(str.to_base64("AB"))))
  assert(eq("ABC", str.from_base64(str.to_base64("ABC"))))
  assert(eq("ABCD", str.from_base64(str.to_base64("ABCD"))))
  assert(eq("\xFF\xFE\xFD", str.from_base64(str.to_base64("\xFF\xFE\xFD"))))
  assert(eq("Man", str.from_base64("TWFu")))
  assert(eq("Man", str.from_base64("TWFu==")))
end)

test("to/from_base64_url", function ()
  local s = "this is an easy test"
  assert(eq(s, str.from_base64_url(str.to_base64_url(s))))
  assert(eq("", str.from_base64_url(str.to_base64_url(""))))
  assert(eq("A", str.from_base64_url(str.to_base64_url("A"))))
  assert(eq("AB", str.from_base64_url(str.to_base64_url("AB"))))
  assert(eq("ABC", str.from_base64_url(str.to_base64_url("ABC"))))
  assert(eq("ABCD", str.from_base64_url(str.to_base64_url("ABCD"))))
  assert(eq("\xFF\xFE\xFD", str.from_base64_url(str.to_base64_url("\xFF\xFE\xFD"))))
  assert(eq("Man", str.from_base64_url("TWFu")))
  assert(eq("Man", str.from_base64_url("TWFu==")))
  assert(eq(
    "AD55961CE994BB017566DFCF04DF81A489BF6B48BC9A9C1BEAF7308A44DC31A550C98AA79348A91ABB8CC906C48295321791C792DBF67FE6795593963C01B29BD179E6EBD83B41BF20F30DCDCE8A291C24B5C81A7B730E2AB1BEFA1B55EC7B469E6AA624E956B36E810B7BD8682E37891BB53202BFA46D6B9790EA113689CD87B1F46ABBF26B6151AC76816D5CCB6EDA83781374B8CE37BC478C767E2CCC61F7DD5D78913F0068DFB3325C3BA238A2599EB59A854EC56DFB0D55E70824980BA499A91336B47892D23A98DB10023AF859167CA531B94C32EA8C94FCA46D615246286747433FAD1B9078A81B14F736652BD48AA25421BCE6F63ADF047B1CDAD05F", -- luacheck: ignore
    str.to_hex(str.from_base64_url("rVWWHOmUuwF1Zt_PBN-BpIm_a0i8mpwb6vcwikTcMaVQyYqnk0ipGruMyQbEgpUyF5HHktv2f-Z5VZOWPAGym9F55uvYO0G_IPMNzc6KKRwktcgae3MOKrG--htV7HtGnmqmJOlWs26BC3vYaC43iRu1MgK_pG1rl5DqETaJzYex9Gq78mthUax2gW1cy27ag3gTdLjON7xHjHZ-LMxh991deJE_AGjfszJcO6I4olmetZqFTsVt-w1V5wgkmAukmakTNrR4ktI6mNsQAjr4WRZ8pTG5TDLqjJT8pG1hUkYoZ0dDP60bkHioGxT3NmUr1IqiVCG85vY63wR7HNrQXw")) -- luacheck: ignore
  ))
end)

test("to/from_url", function ()
  local s = "this is an easy test"
  assert(eq(s, str.from_url(str.to_url(s))))
  assert(eq("", str.from_url(str.to_url(""))))
  assert(eq(" ", str.from_url(str.to_url(" "))))
  assert(eq("!@#$%^&*()", str.from_url(str.to_url("!@#$%^&*()"))))
  assert(eq("A simple test with   spaces",
    str.from_url(str.to_url("A simple test with   spaces"))))
end)

test("to/from_query", function ()
  local params = {
    a = "",
    b = " ",
    c = "!@#$%^&*()",
    ["!@#$%^&*()"] = 1,
    d = 1,
    e = true,
  }
  assert(teq(params, str.from_query(str.to_query(params))))
end)

test("format_number", function ()
  assert(eq(str.format_number(12345678), "12,345,678"))
  assert(eq(str.format_number(-12345678), "-12,345,678"))
  assert(eq(str.format_number(-678), "-678"))
  assert(eq(str.format_number(-1678), "-1,678"))
  assert(eq(str.format_number(78), "78"))
end)

test("escape", function ()
  assert(eq(str.escape("a.b*c"), "a%.b%*c"))
  assert(eq(str.escape("hello"), "hello"))
  assert(eq(str.escape("(test)"), "%(test%)"))
end)

test("unescape", function ()
  assert(eq(str.unescape("a%.b%*c"), "a.b*c"))
  assert(eq(str.unescape("hello"), "hello"))
end)

test("trim", function ()
  assert(eq(str.trim("  hello  "), "hello"))
  assert(eq(str.trim("hello"), "hello"))
  assert(eq(str.trim("  hello"), "hello"))
  assert(eq(str.trim("hello  "), "hello"))
end)

test("trim custom", function ()
  assert(eq(str.trim("xxhelloxx", "x+"), "hello"))
  assert(eq(str.trim("  hello", false, "%s*"), "  hello"))
  assert(eq(str.trim("hello  ", "%s*", false), "hello  "))
end)

test("isempty", function ()
  assert(str.isempty(""))
  assert(str.isempty("   "))
  assert(str.isempty("\t\n"))
  assert(str.isempty(nil))
  assert(not str.isempty("a"))
  assert(not str.isempty(" a "))
end)

test("stripprefix", function ()
  assert(eq(str.stripprefix("/home/user/file", "/home/"), "user/file"))
  assert(eq(str.stripprefix("hello", "hello"), ""))
  assert(eq(str.stripprefix("hello", "world"), "hello"))
end)

test("startswith", function ()
  assert(str.startswith("hello world", "hello"))
  assert(not str.startswith("hello world", "world"))
  assert(str.startswith("hello", "h"))
end)

test("endswith", function ()
  assert(str.endswith("hello world", "world"))
  assert(not str.endswith("hello world", "hello"))
  assert(str.endswith("hello", "o"))
end)

test("compare", function ()
  assert(str.compare("a", "bb"))
  assert(not str.compare("bb", "a"))
  assert(str.compare("aa", "ab"))
  assert(not str.compare("ab", "aa"))
end)

test("commonprefix", function ()
  assert(eq(str.commonprefix("hello", "help", "helicopter"), "hel"))
  assert(eq(str.commonprefix("abc", "def"), ""))
  assert(eq(str.commonprefix("test"), "test"))
  assert(eq(str.commonprefix(), ""))
end)

test("count", function ()
  assert(eq(str.count("aaa", "a"), 3))
  assert(eq(str.count("abab", "ab"), 2))
  assert(eq(str.count("hello", "x"), 0))
end)

test("encode_url", function ()
  assert(eq(str.encode_url({ scheme = "https", host = "example.com", pathname = "/path" }), "https://example.com/path"))
  assert(eq(str.encode_url({ scheme = "https", host = "example.com", port = 8080 }), "https://example.com:8080"))
  assert(eq(str.encode_url({ host = "example.com", path = { "a", "b" } }), "//example.com/a/b"))
  assert(eq(str.encode_url({ host = "example.com", params = { x = 1 } }), "//example.com?x=1"))
  assert(eq(str.encode_url({ host = "example.com", fragment = "top" }), "//example.com#top"))
end)

local u_eacute = "\195\169"
local u_Eacute = "\195\137"
local u_euro = "\226\130\172"
local u_clef = "\240\157\132\158"
local u_alpha = "\206\177"
local u_Alpha = "\206\145"
local u_sharp_s = "\195\159"
local u_cap_sharp_s = "\225\186\158"
local u_kelvin = "\226\132\170"
local u_dotted_I = "\196\176"
local u_dot_above = "\204\135"
local u_ligature_fi = "\239\172\129"
local u_deseret_long_i = "\240\144\144\128"
local u_deseret_long_i_small = "\240\144\144\168"

test("utf8_next decodes each width", function ()
  assert(teq({ 97, 1 }, { str.utf8_next("a") }))
  assert(teq({ 233, 2 }, { str.utf8_next(u_eacute) }))
  assert(teq({ 8364, 3 }, { str.utf8_next(u_euro) }))
  assert(teq({ 119070, 4 }, { str.utf8_next(u_clef) }))
end)

test("utf8_next walks a string by byte offset", function ()
  local s = "a" .. u_eacute .. u_euro .. u_clef
  local cps = {}
  local i = 1
  while true do
    local cp, w = str.utf8_next(s, i)
    if not cp then break end
    cps[#cps + 1] = cp
    i = i + w
  end
  assert(teq({ 97, 233, 8364, 119070 }, cps))
  assert(eq(#s + 1, i))
end)

test("utf8_next returns nil off the ends and on continuation bytes", function ()
  assert(eq(nil, str.utf8_next("", 1)))
  assert(eq(nil, str.utf8_next("abc", 4)))
  assert(eq(nil, str.utf8_next("abc", 0)))
  assert(eq(nil, str.utf8_next(u_euro, 2)))
  assert(eq(nil, str.utf8_next(u_euro, 3)))
end)

test("utf8_len counts codepoints", function ()
  assert(eq(0, str.utf8_len("")))
  assert(eq(3, str.utf8_len("abc")))
  assert(eq(4, str.utf8_len("a" .. u_eacute .. u_euro .. u_clef)))
  assert(eq(1, str.utf8_len(u_clef)))
end)

test("malformed utf8 yields nil", function ()
  local cases = {
    "\226\130",
    "\240\157\132",
    "\195",
    "\169",
    "\128\128",
    "\192\175",
    "\224\128\175",
    "\240\128\128\175",
    "\237\160\128",
    "\244\144\128\128",
    "\254",
    "\255",
    "\226\130\226\130\172",
  }
  for i = 1, #cases do
    assert(eq(nil, str.utf8_next(cases[i], 1)))
    assert(eq(nil, str.utf8_len(cases[i])))
    assert(eq(nil, str.utf8_lower(cases[i])))
    assert(eq(nil, str.utf8_fold(cases[i])))
  end
end)

test("malformed utf8 later in a string still yields nil", function ()
  local s = "ok then \226\130"
  assert(eq(111, str.utf8_next(s, 1)))
  assert(eq(nil, str.utf8_next(s, 9)))
  assert(eq(nil, str.utf8_len(s)))
  assert(eq(nil, str.utf8_lower(s)))
  assert(eq(nil, str.utf8_fold(s)))
end)

test("utf8_lower maps across all widths", function ()
  assert(eq("", str.utf8_lower("")))
  assert(eq("abc", str.utf8_lower("ABC")))
  assert(eq(u_eacute, str.utf8_lower(u_Eacute)))
  assert(eq(u_alpha, str.utf8_lower(u_Alpha)))
  assert(eq(u_deseret_long_i_small, str.utf8_lower(u_deseret_long_i)))
  assert(eq("x" .. u_alpha .. "y", str.utf8_lower("X" .. u_Alpha .. "Y")))
end)

test("utf8_lower changes byte length where unicode says so", function ()
  assert(eq(u_sharp_s, str.utf8_lower(u_cap_sharp_s)))
  assert(eq(2, #str.utf8_lower(u_cap_sharp_s)))
  assert(eq("k", str.utf8_lower(u_kelvin)))
  assert(eq("i", str.utf8_lower(u_dotted_I)))
  assert(eq(u_sharp_s, str.utf8_lower(u_sharp_s)))
end)

test("utf8_fold expands beyond one codepoint", function ()
  assert(eq("", str.utf8_fold("")))
  assert(eq("ss", str.utf8_fold(u_sharp_s)))
  assert(eq("ss", str.utf8_fold(u_cap_sharp_s)))
  assert(eq("fi", str.utf8_fold(u_ligature_fi)))
  assert(eq("i" .. u_dot_above, str.utf8_fold(u_dotted_I)))
  assert(eq(u_alpha, str.utf8_fold(u_Alpha)))
  assert(eq("k", str.utf8_fold(u_kelvin)))
  assert(eq(u_deseret_long_i_small, str.utf8_fold(u_deseret_long_i)))
end)

test("utf8_fold equates case variants", function ()
  assert(eq(str.utf8_fold("Stra" .. u_sharp_s .. "e"), str.utf8_fold("STRASSE")))
  assert(eq(str.utf8_fold(u_Alpha .. "BC"), str.utf8_fold(u_alpha .. "bc")))
end)
