local err = require("santoku.err")
local vec = require("santoku.vector")
local gen = require("santoku.gen")
local str = require("santoku.string")
local sys = require("santoku.system")
local fs = require("santoku.fs")

local M = {}

local function parsemodules (check, infile, modules, path, cpath) 
  local data = check(fs.readfile(infile))
  gen.ivals(str.match(data, "require%(?[^%S\n]*\"([^\"]*)\"[^%S\n]*%)?"))
    :each(function (mod)
      local fp0, err0 = package.searchpath(mod, path)
      if fp0 then
        modules.lua[mod] = fp0
        parsemodules(check, fp0, modules, path, cpath)
        return
      end
      local fp1, err1 = package.searchpath(mod, cpath)
      -- if fp1 and not str.endswith(fp1, ".a") then
      --   -- TODO: This should be a library
      --   -- function
      --   io.stderr:write(string.format("Ignoring %s \n", fp1))
      --   return
      -- else
      if fp1 then
        modules.c[mod] = fp1
        return
      end
      check(false, err0, err1)
    end)
end

M.parsemodules = function (infile, path, cpath) 
  return err.pwrap(function (check) 
    local modules = { c = {}, lua = {} }
    parsemodules(check, infile, modules, path, cpath)
    return modules
  end)
end

M.mergelua = function (modules, infile)
  return err.pwrap(function (check)
    local ret = vec()
    for mod, fp in pairs(modules) do
      local data = check(fs.readfile(fp))
      ret:append("package.preload[\"", mod, "\"] = function ()\n\n", data, "\nend\n")
    end
    ret:append("\n", check(fs.readfile(infile)))
    return ret:concat()
  end)
end

M.bundle = function (infile, outdir, path, cpath)
  return err.pwrap(function (check) 
    local outprefix = fs.splitexts(fs.basename(infile)).name
    local modules = check(M.parsemodules(infile, path, cpath))
    local outluafp = fs.join(outdir, outprefix .. ".lua")
    local outluadata = check(M.mergelua(modules.lua, infile))
    check(fs.writefile(outluafp, outluadata))
    local outluacfp = fs.join(outdir, outprefix .. ".luac")
    local cmdluac = os.getenv("LUAC") or "luac"
    check(sys.execute(cmdluac, "-s", "-o", outluacfp, outluafp))
    local outluahfp = fs.join(outdir, outprefix .. ".h")
    local cmdxxd = os.getenv("XXD") or "xxd"
    check(sys.execute(cmdxxd, "-i", "-n data", outluacfp, outluahfp))
    local outcfp = fs.join(outdir, outprefix .. ".c")
    fs.writefile(outcfp, table.concat({[[
      #include "lua.h"
      #include "lualib.h"
      #include "lauxlib.h"
    ]], check(fs.readfile(outluahfp)), [[
      const char *reader (lua_State *L, void *data, size_t *sizep) {
        *sizep = data_len;
        return (const char *)data;
      }
    ]], gen.pairs(modules.c):map(function (mod, fp)
      local sym = "luaopen_" .. string.gsub(mod, "%.", "_")
      return "int " .. sym .. "(lua_State *L);"
    end):concat("\n"), "\n", [[
      int main (int argc, char **argv) {
        lua_State *L = luaL_newstate();
        if (L == NULL) 
          return 1;
        luaL_openlibs(L);
        int rc = 0;
    ]], gen.pairs(modules.c):map(function (mod, fp)
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
        lua_close(L);
        return rc;
      }
    ]]}))
    local cmdcc = os.getenv("CC") or "cc"
    local cmdcflags = os.getenv("CFLAGS") or ""
    local outmainfp = fs.join(outdir, outprefix)
    local args = vec()
    args:append("LUA_PATH='" .. path .. "'")
    args:append("LUA_CPATH='" .. cpath .. "'")
    args:append(cmdcc, outcfp)
    args:append("-lm", "-llua")
    args:append("-o", outmainfp)
    args:append(cmdcflags)
    gen.pairs(modules.c)
      :each(function (mod, fp)
        args:append(fp)
      end)
    print(">", args:concat(" "))
    check(sys.execute(args:unpack()))
  end)
end

return setmetatable({}, {
  __index = M,
  __call = function(_, ...)
    return M.bundle(...)
  end
})
