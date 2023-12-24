rocks_trees = {
  { name = "system",
    root = "<% return build.test_modules %>"
  } }

<% template:push(build.iswasm) %>

-- NOTE: Not specifying the interpreter, version, LUA, LUA_BINDIR, and LUA_DIR
-- so that the host lua is used install rocks. The other variables affect how
-- those rocks are built

-- lua_interpreter = "lua"
-- lua_version = "5.1"

variables = {

  LUALIB = "liblua.a",
  LUA_INCDIR = "<% return build.client_lua_dir %>/include",
  LUA_LIBDIR = "<% return build.client_lua_dir %>/lib",
  LUA_LIBDIR_FILE = "liblua.a",

  CFLAGS = "-I <% return build.client_lua_dir %>/include",
  LDFLAGS = "-L <% return build.client_lua_dir %>/lib",
  LIBFLAG = "-shared",

  CC = "emcc",
  CXX = "em++",
  AR = "emar",
  LD = "emcc",
  NM = "llvm-nm",
  LDSHARED = "emcc",
  RANLIB = "emranlib",

}

<% template:pop() %>
