-- local arr = require("santoku.array")
-- local fs = require("santoku.fs")
-- local base = fs.runfile("make.lua")
-- base.env.cflags = arr.extend({ "-fsanitize=address", "-g3", "-O0", "-fno-omit-frame-pointer" }, base.env.cflags)
-- base.env.ldflags = arr.extend({ "-fsanitize=address", "-g3", "-O0" }, base.env.ldflags)
-- return base

local arr = require("santoku.array")
local fs = require("santoku.fs")
local base = fs.runfile("make.lua")

local asan_runtime_path = "/data/data/com.termux/files/usr/lib/clang/20/lib/linux/libclang_rt.asan-aarch64-android.a"

base.env.cflags = arr.extend({
  "-fsanitize=address",
  "-g3",
  "-O0",
  "-fno-omit-frame-pointer"
}, base.env.cflags)

base.env.ldflags = arr.extend({
  "-fsanitize=address",
  "-Wl,--whole-archive", asan_runtime_path, "-Wl,--no-whole-archive",
  "-g3",
  "-O0"
}, base.env.ldflags)

return base
