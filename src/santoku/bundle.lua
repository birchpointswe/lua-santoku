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

M.bundle = function (
    infile, outdir, outprefix, env, cflags,
    ldflags, cmpenv, deps, depstarget,
    mods, ignores, noclose, noluac)
  mods = mods or {}
  env = vec.wrap(env)
  cmpenv = vec.wrap(cmpenv)
  ignores = gen.ivals(ignores or {}):set()
  return err.pwrap(function (check)
    local path = (env:find(function (p)
      return p[1] == "LUA_PATH"
    end) or { "", os.getenv("LUA_PATH") })[2]
    local cpath = (env:find(function (p)
      return p[1] == "LUA_CPATH"
    end) or { "", os.getenv("LUA_CPATH") })[2]
    outprefix = outprefix or fs.splitexts(fs.basename(infile)).name
    local modules = check(M.parsemodules(infile, mods, ignores, path, cpath))
    local outluafp = fs.join(outdir, outprefix .. ".lua")
    local outluadata = check(M.mergelua(modules, infile, mods))
    check(fs.writefile(outluafp, outluadata))
    local outluacfp
    if not noluac then
      outluacfp = fs.join(outdir, outprefix .. ".luac")
      local cmdluac = os.getenv("LUAC") or "luac"
      check(sys.execute(cmdluac, "-s", "-o", outluacfp, outluafp))
    else
      outluacfp = outluafp
    end
    local outluahfp = fs.join(outdir, outprefix .. ".h")
    local cmdxxd = os.getenv("XXD") or "xxd"
    check(sys.execute(cmdxxd, "-i", "-n", "data", outluacfp, outluahfp))
    local outcfp = fs.join(outdir, outprefix .. ".c")
    local outmainfp = fs.join(outdir, outprefix)
    if deps then
      M.write_deps(check, modules, infile, depstarget or outmainfp)
    end
    check(fs.writefile(outcfp, table.concat({[[
      #include "lua.h"
      #include "lualib.h"
      #include "lauxlib.h"
    ]], cmpenv.n > 0 and [[
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
    ]], gen.ivals(cmpenv):map(function (e)
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
      ]], not noclose and [[
        lua_close(L);
      ]] or "", [[
        return rc;
      }
    ]]})))
    local cmdcc = os.getenv("CC") or "cc"
    local cmdcflags = os.getenv("CFLAGS") or ""
    local cmdldflags = os.getenv("LDFLAGS") or ""
    local args = vec("2>&1")
    env:each(function (var)
      args:append(table.concat({ var[1], "=\"", var[2], "\"" }))
    end)
    args:append(cmdcc, outcfp)
    if cflags then
      args:append(cflags)
    end
    if ldflags then
      args:append(ldflags)
    end
    args:append(cmdcflags)
    args:append(cmdldflags)
    args:append("-lm", "-llua")
    args:append("-o", outmainfp)
    gen.pairs(modules.c)
      :each(function (_, fp)
        args:append(fp)
      end)
    check(sys.execute(args:unpack()))
  end)
end

return setmetatable(M, M.MT)
