local test = require("santoku.test")
local serialize = require("santoku.serialize") -- luacheck: ignore

local err = require("santoku.error")
local assert = err.assert

local tbl = require("santoku.table")
local teq = tbl.equals
local tmap = tbl.map

local vdt = require("santoku.validate")
local eq = vdt.isequal

local str = require("santoku.string")
local ssplit = str.splits
local smatch = str.matches
local ssub = str.sub
local snumber = str.number
local sinterp = str.interp

local iter = require("santoku.iter")
local icollect = iter.collect
local imap = iter.map

test("split", function ()
  assert(teq(icollect(imap(ssub, ssplit("this is a test", "%s+"))), { "this", "is", "a", "test" }))
  assert(teq(icollect(imap(ssub, ssplit("a b c", "%s+"))), { "a", "b", "c" }))
  assert(teq(icollect(imap(ssub, ssplit("a b c   ", "%s+"))), { "a", "b", "c", "" }))
  assert(teq(icollect(imap(snumber, ssplit("10 39.5 46.8", "%s+"))), { 10, 39.5, 46.8 }))
end)

test("match", function ()
  assert(teq(icollect(imap(ssub, smatch("this is a test", "%S+"))), { "this", "is", "a", "test" }))
  assert(teq(icollect(imap(ssub, smatch("this is a test  ", "%S+"))), { "this", "is", "a", "test" }))
  assert(teq(icollect(imap(snumber, smatch("10 39.5 46.8", "%S+"))), { 10, 39.5, 46.8 }))
end)

test("match with delim", function ()
  assert(teq(icollect(imap(ssub, smatch("a b c", "%S+", true))), { "a", " ", "b", " ", "c" }))
  assert(teq(icollect(imap(ssub, ssplit("a b c", "%s+", true))), { "a", " ", "b", " ", "c" }))
  assert(teq(icollect(imap(ssub, smatch("a   b c  ", "%s+", true))), { "a", "   ", "b", " ", "c", "  " }))
  assert(teq(icollect(imap(ssub, smatch("a b c", "%S+", "right"))), { "a", " b", " c" }))
  assert(teq(icollect(imap(ssub, smatch("a b c", "%S+", "left"))), { "a ", "b ", "c" }))
end)

test("split with delim", function ()
  assert(teq(icollect(imap(ssub, ssplit("a b c", "%s+", true))), { "a", " ", "b", " ", "c" }))
  assert(teq(icollect(imap(ssub, ssplit("a b c", "%s+", "right"))), { "a", " b", " c" }))
  assert(teq(icollect(imap(ssub, ssplit("a b c", "%s+", "left"))), { "a ", "b ", "c" }))
end)

test("match no matches", function ()
  assert(teq(icollect(imap(ssub, smatch("a b c", "%d+"))), {}))
  assert(teq(icollect(imap(ssub, smatch("a b c", "%d+", true))), { "a b c" }))
  assert(teq(icollect(imap(ssub, smatch("a b c", "%d+", "left"))), {}))
  assert(teq(icollect(imap(ssub, smatch("a b c", "%d+", "right"))), {}))
end)

test("split no matches", function ()
  assert(teq(icollect(imap(ssub, ssplit("a b c", "%d+"))), { "a b c" }))
  assert(teq(icollect(imap(ssub, ssplit("a b c", "%d+", true))), { "a b c" }))
  assert(teq(icollect(imap(ssub, ssplit("a b c", "%d+", "left"))), { "a b c" }))
  assert(teq(icollect(imap(ssub, ssplit("a b c", "%d+", "right"))), { "a b c" }))
end)

test("split/match start/end", function ()
  assert(teq(icollect(imap(ssub, ssplit("a b c d e", "%S+", false, 3, 7))), { "", " ", " ", "" }))
  assert(teq(icollect(imap(ssub, smatch("a b c d e", "%s+", false, 3, 7))), { " ", " " }))
  assert(teq(icollect(imap(ssub, ssplit("a b c d e", "%S+", false, 3, nil))), { "", " ", " ", " ", "" }))
  assert(teq(icollect(imap(ssub, smatch("a b c d e", "%s+", false, 3, nil))), { " ", " ", " " }))
  assert(teq(icollect(imap(ssub, ssplit("a b c d e", "%S+", false, nil, 7))), { "", " ", " ", " ", "" }))
  assert(teq(icollect(imap(ssub, smatch("a b c d e", "%s+", false, nil, 7))), { " ", " ", " " }))
end)

test("split first char", function ()
  assert(teq(icollect(imap(ssub, ssplit("asdf.tar.gz", "%.", false, 5))), { "", "tar", "gz" }))
  assert(teq(icollect(imap(ssub, ssplit("asdf.tar.gz", "%.", "right", 5))), { "", ".tar", ".gz" }))
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

test("interp multiple", function ()
  assert(teq({ "hello world" }, { str.interp("%s#(greet) %s#(target)", { greet = "hello", target = "world" }) }))
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
  assert(eq("", str.from_hex(str.to_hex("")))) -- Empty string
  assert(eq(" ", str.from_hex(str.to_hex(" ")))) -- Single space
  assert(eq("!", str.from_hex(str.to_hex("!")))) -- Single character
  assert(eq("1234567890", str.from_hex(str.to_hex("1234567890")))) -- Numeric string
  assert(eq("\xFF\xFE\xFD", str.from_hex(str.to_hex("\xFF\xFE\xFD")))) -- Non-printable bytes
  assert(eq("\x00\x01\x02\x03", str.from_hex(str.to_hex("\x00\x01\x02\x03")))) -- Leading zeros
end)

test("to/from_base64", function ()
  local s = "this is an easy test"
  assert(eq(s, str.from_base64(str.to_base64(s))))
  assert(eq("", str.from_base64(str.to_base64("")))) -- Empty string
  assert(eq("A", str.from_base64(str.to_base64("A")))) -- Single character
  assert(eq("AB", str.from_base64(str.to_base64("AB")))) -- Two characters
  assert(eq("ABC", str.from_base64(str.to_base64("ABC")))) -- Three characters
  assert(eq("ABCD", str.from_base64(str.to_base64("ABCD")))) -- Four characters
  assert(eq("\xFF\xFE\xFD", str.from_base64(str.to_base64("\xFF\xFE\xFD")))) -- Non-printable bytes
  assert(eq("Man", str.from_base64("TWFu"))) -- Valid base64 for "Man"
  assert(eq("Man", str.from_base64("TWFu=="))) -- Base64 with padding
end)

test("to/from_base64_url", function ()
  local s = "this is an easy test"
  assert(eq(s, str.from_base64_url(str.to_base64_url(s))))
  assert(eq("", str.from_base64_url(str.to_base64_url("")))) -- Empty string
  assert(eq("A", str.from_base64_url(str.to_base64_url("A")))) -- Single character
  assert(eq("AB", str.from_base64_url(str.to_base64_url("AB")))) -- Two characters
  assert(eq("ABC", str.from_base64_url(str.to_base64_url("ABC")))) -- Three characters
  assert(eq("ABCD", str.from_base64_url(str.to_base64_url("ABCD")))) -- Four characters
  assert(eq("\xFF\xFE\xFD", str.from_base64_url(str.to_base64_url("\xFF\xFE\xFD")))) -- Non-printable bytes
  assert(eq("Man", str.from_base64_url("TWFu"))) -- Valid base64 URL for "Man"
  assert(eq("Man", str.from_base64_url("TWFu--"))) -- Base64 URL with padding
end)

test("to/from_url", function ()
  local s = "this is an easy test"
  assert(eq(s, str.from_url(str.to_url(s))))
  assert(eq("", str.from_url(str.to_url("")))) -- Empty string
  assert(eq(" ", str.from_url(str.to_url(" ")))) -- Single space
  assert(eq("!@#$%^&*()", str.from_url(str.to_url("!@#$%^&*()")))) -- Special characters
  assert(eq("A simple test with   spaces",
    str.from_url(str.to_url("A simple test with   spaces")))) -- URL encoding spaces
end)
