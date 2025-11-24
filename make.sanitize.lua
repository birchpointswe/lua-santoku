local arr = require("santoku.array")
local fs = require("santoku.fs")
local err = require("santoku.error")
local env = require("santoku.env")
local str = require("santoku.string")
local sys = require("santoku.system")
local base = fs.runfile("make.lua")
local ld_preload = env.var("LD_PRELOAD", nil)
local asan = sys.sh({ "sh", "-c", str.format([[
  %s -fsanitize=address -xc /dev/null -### 2>&1 | grep -o '"[^"]*asan[^"]*\.so[^"]*"' | head -1 | tr -d '"'
]], env.var("CC", "clang")) })()
if not asan or asan == "" then
  local cc = env.var("CC", "clang")
  local arch = sys.sh({ "uname", "-m" })()
  asan = sys.sh({ "sh", "-c", str.format([[
    resdir=$(%s -print-resource-dir 2>/dev/null) && find "$resdir" -name 'libclang_rt.asan*%s*.so' 2>/dev/null | head -1 || \
    libdir=$(%s -print-file-name=libasan.so 2>/dev/null) && [ -f "$libdir" ] && echo "$libdir"
  ]], cc, arch, cc) })()
end
err.assert(asan and asan ~= "", "Couldn't determine asan lib to preload")
if ld_preload then
  ld_preload = ld_preload .. ":" .. asan
else
  ld_preload = asan
end
local symbolizer = sys.sh({ "sh", "-c", "command -v llvm-symbolizer 2>/dev/null || command -v llvm-symbolizer-10 2>/dev/null || true" })()
local symbolizer_opt = ""
if symbolizer and symbolizer ~= "" and not symbolizer:match("^%-") then
  symbolizer_opt = ":external_symbolizer_path=" .. symbolizer
end
local asan_options = env.var("ASAN_OPTIONS", "fast_unwind_on_malloc=0:malloc_context_size=30:detect_stack_use_after_return=1:strict_string_checks=1:halt_on_error=0:symbolize=1" .. symbolizer_opt)
local ubsan_options = env.var("UBSAN_OPTIONS", "print_stacktrace=1:halt_on_error=1")
base.env.test = base.env.test or {}
base.env.test.env_vars = {
  ASAN_OPTIONS = asan_options,
  UBSAN_OPTIONS = ubsan_options,
  LD_PRELOAD = ld_preload
}
base.env.cflags = arr.extend({
  "-fsanitize=address,undefined", "-fno-sanitize-recover=undefined",
  "-g3", "-O0", "-fno-inline", "-fno-omit-frame-pointer",
}, base.env.cflags)
base.env.ldflags = arr.extend({
  "-fsanitize=address,undefined",
  "-g3", "-O0"
}, base.env.ldflags)
return base
