local err = require("santoku.err")
local vec = require("santoku.vector")
local gen = require("santoku.gen")
local str = require("santoku.string")
local sys = require("santoku.system")
local fs = require("santoku.fs")

local M = {}

M.MT = {
  __index = M,
  __call = function(M, ...)
    return M.bundle(...)
  end
}

M.write_deps = function (check, modules, infile, outfile)
  local depsfile = outfile .. ".d"
  local out = gen.chain(
      gen.pack(outfile, ": "),
      gen.vals(modules):map(gen.vals):flatten():intersperse(" "),
      gen.pack("\n", depsfile, ": ", infile))
    :vec():concat()
  check(fs.writefile(depsfile, out))
end

M.addmod = function (check, modules, mod, path, cpath)
  if not (modules.lua[mod] or modules.c[mod]) then
    local fp, typ = check(M.searchpaths(mod, path, cpath))
    modules[typ][mod] = fp
    return fp, typ
  end
end

M.parsemodule = function (check, mod, modules, ignores, path, cpath)
  if ignores[mod] then
    return
  end
  local fp, typ = M.addmod(check, modules, mod, path, cpath)
  if typ == "lua" then
    M.parsemodules(check, fp, modules, ignores, path, cpath)
  end
end

M.parsemodules = function (check, infile, modules, ignores, path, cpath)
  check(fs.lines(infile))
    :map(function (line)
      -- TODO: The second match causes the bundler
      -- to skip any lines with the word
      -- 'require' in quotes, which may not be
      -- right
      -- if line:match("^%s*%-%-") or line:match("\"[^\"]*require[^\"]*\"") then
      if line:match("^%s*%-%-") then
        return gen.empty()
      else
        -- TODO: This pattern matches
        -- require("abc'). Notice the quotes.
        local pat = "require%(?[^%S\n]*[\"']([^\"']*)['\"][^%S\n]*%)?"
        return gen.ivals(str.match(line, pat))
      end
    end)
    :flatten()
    :each(function (mod)
      M.parsemodule(check, mod, modules, ignores, path, cpath)
    end)
end

-- TODO: Create a 5.1 shim for
-- package.searchpath
M.searchpaths = function (mod, path, cpath)
  local fp0, err0 = package.searchpath(mod, path) -- luacheck: ignore
  if fp0 then
    return true, fp0, "lua"
  end
  local fp1, err1 = package.searchpath(mod, cpath) -- luacheck: ignore
  if fp1 then
    return true, fp1, "c"
  end
  return false, err0, err1
end

M.parsemodules = function (infile, mods, ignores, path, cpath)
  return err.pwrap(function (check)
    local modules = { c = {}, lua = {} }
    gen.ivals(mods):each(function(mod)
      M.parsemodule(check, mod, modules, ignores, path, cpath)
    end)
    M.parsemodules(check, infile, modules, ignores, path, cpath)
    return modules
  end)
end

M.mergelua = function (modules, infile, mods)
  return err.pwrap(function (check)
    local ret = vec()
    gen.pairs(modules.lua):each(function (mod, fp)
      local data = check(fs.readfile(fp))
      ret:append("package.preload[\"", mod, "\"] = function ()\n\n", data, "\nend\n")
    end)
    gen.ivals(mods):each(function (mod)
      ret:append("require(\"", mod, "\")\n")
    end)
    ret:append("\n", check(fs.readfile(infile)))
    return ret:concat()
  end)
end

M.bundle = function (infile, outdir, opts)
  opts = opts or {}
  opts.mods = vec.wrap(opts.mods)
  opts.env = vec.wrap(opts.env)
  opts.env_compile = vec.wrap(opts.env_compile)
  opts.flags = vec.wrap(opts.flags)
  local ignores = gen.ivals(opts.ignores or {}):set()
  return err.pwrap(function (check)
    opts.path = opts.path or ""
    opts.cpath = opts.cpath or ""
    opts.outprefix = opts.outprefix or fs.splitexts(fs.basename(infile)).name
    local modules = check(M.parsemodules(infile, opts.mods, ignores, opts.path, opts.cpath))
    local outluafp = fs.join(outdir, opts.outprefix .. ".lua")
    local outluadata = check(M.mergelua(modules, infile, opts.mods))
    check(fs.writefile(outluafp, outluadata))
    local outluacfp
    if opts.luac then
      if opts.luac == true then
        opts.luac = "luac -s -o %output %input"
      end
      outluacfp = fs.join(outdir, opts.outprefix .. ".luac")
      opts.luac = str.interp(opts.luac, { input = outluafp, output = outluacfp })
      local args = str.split(opts.luac)
      check(sys.execute(args:unpack()))
    else
      outluacfp = outluafp
    end
    opts.xxd = opts.xxd or "xxd -i -n data"
    local outluahfp = fs.join(outdir, opts.outprefix .. ".h")
    check(sys.execute(str.split(opts.xxd):append(outluacfp, outluahfp):unpack()))
    local outcfp = fs.join(outdir, opts.outprefix .. ".c")
    local outmainfp = fs.join(outdir, opts.outprefix)
    if opts.deps then
      M.write_deps(check, modules, infile, opts.depstarget or outmainfp)
    end
    check(fs.writefile(outcfp, table.concat({[[
      #include "lua.h"
      #include "lualib.h"
      #include "lauxlib.h"
    ]], opts.env_compile.n > 0 and [[
      #include "stdlib.h"
    ]] or "", check(fs.readfile(outluahfp)), [[
      const char *reader (lua_State *L, void *data, size_t *sizep) {
        *sizep = data_len;
        return (const char *)data;
      }
    ]], gen.pairs(modules.c):map(function (mod)
      local sym = "luaopen_" .. string.gsub(mod, "%.", "_")
      return "int " .. sym .. "(lua_State *L);"
    end):concat("\n"), "\n", [[
      int main (int argc, char **argv) {
    ]], gen.ivals(opts.env_compile):map(function (e)
      return string.format("setenv(%s, %s, 1);", str.quote(e[1]), str.quote(e[2]))
    end):concat(), "\n", [[
    ]], [[
        lua_State *L = luaL_newstate();
        if (L == NULL)
          return 1;
        luaL_openlibs(L);
        int rc = 0;
    ]], gen.pairs(modules.c):map(function (mod)
      local sym = "luaopen_" .. string.gsub(mod, "%.", "_")
      return str.interp("luaL_requiref(L, \"%mod\", %sym, 0);", {
        mod = mod,
        sym = sym
      })
    end):concat("\n"), "\n", [[
        if (LUA_OK != (rc = luaL_loadbuffer(L, (const char *)data, data_len, "]], outluacfp, [[")))
          goto err;
        lua_createtable(L, argc, 0);
        for (int i = 0; i < argc; i ++) {
          lua_pushstring(L, argv[i]);
          lua_pushinteger(L, argc + 1);
          lua_settable(L, -3);
        }
        lua_setglobal(L, "arg");
        if (LUA_OK != (rc = lua_pcall(L, 0, 0, 0)))
          goto err;
        goto end;
      err:
        fprintf(stderr, "%s\n", lua_tostring(L, -1));
      end:
      ]], (opts.close == false) and [[
        lua_close(L);
      ]] or "", [[
        return rc;
      }
    ]]})))
    opts.cc = opts.cc or "cc"
    local args = vec()
    args:append(opts.cc, outcfp)
    args:extend(opts.flags)
    gen.pairs(modules.c)
      :each(function (_, fp)
        args:append(fp)
      end)
    args:append("-o", outmainfp)
    check(sys.execute({ env = opts.env }, args:unpack()))
  end)
end

return setmetatable(M, M.MT)
