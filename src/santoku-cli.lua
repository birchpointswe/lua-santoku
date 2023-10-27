-- TODO: Write tests for this

local argparse = require("argparse")
local inherit = require("santoku.inherit")
local gen = require("santoku.gen")
local test = require("santoku.test")
local err = require("santoku.err")
local fs = require("santoku.fs")
local tpl = require("santoku.template")
local bundle = require("santoku.bundle")

local parser = argparse()
  :name("toku")
  :description("A command lind interface to the santoku lua library")

local cbundle = parser
  :command("bundle", "create standalone executables")

cbundle
  :option("-e --env", "set an environment variable that applies only for the compilation step")
  :args(2)
  :count("*")

cbundle
  :option("--cflags", "set command-line CFLAGS")
  :args(1)
  :count("0-1")

cbundle
  :option("--ldflags", "set command-line LDFLAGS")
  :args(1)
  :count("0-1")

cbundle
  :option("-E --cmpenv", "set an environment variable that applies only at runtime")
  :args(2)
  :count("*")

cbundle
  :flag("-L --noluac", "do not first compile lua code with luac")
  :count("0-1")

cbundle
  :option("-l --load", "load a module during startup")
  :args(1)
  :count("*")

cbundle
  :option("-i --ignore", "ignore bundling a module")
  :args(1)
  :count("*")

cbundle
  :flag("-C --noclose", "don't call lua_close(...)")
  :count("0-1")

cbundle
  :option("-f --file", "input file")
  :args(1)
  :count(1)

cbundle
  :flag("-M --deps", "generate a make .d file")
  :count("0-1")

cbundle
  :flag("-m --depstarget", "override dependency target file")
  :args(1)
  :count("0-1")

cbundle
  :option("-o --output", "output directory")
  :args(1)
  :count(1)

cbundle
  :option("-O --outputname", "output name prefix")
  :args(1)
  :count("0-1")

local ctemplate = parser
  :command("template", "process templates")

ctemplate:mutex(

  ctemplate
    :option("-f --file", "input file")
    :args(1)
    :count("0-1"),

  ctemplate
    :option("-d --directory", "input directory")
    :args(1)
    :count("0-1"))

ctemplate
  :option("-o --output", "output file or directory")
  :args(1)
  :count(1)

ctemplate
  :flag("-M --deps", "generate a make .d file")
  :count("0-1")

ctemplate
  :option("-t --trim", "prefix to remove from directory prefix before output (only used when -d is provided)")
  :args(1)
  :count("?")

ctemplate
  :option("-c --config", "a configuration file")
  :args(1)
  :count("0-1")

local ctest = parser
  :command("test", "run tests")

ctest
  :option("-m --match", "only load the matching files")
  :args(1)
  :count("0-1")

ctest
  :flag("-s --stop", "stop after the first error")
  :count("0-1")

ctest
  :option("-i --interp", "run files with <interp> instead of via lua dofile")
  :args(1)
  :count("0-1")

ctest
  :argument("files")
  :args("*")

local args = parser:parse()

-- TODO: Move this logic into santoku.template
local function write_deps (check, deps, input, output, fp_config)
  local depsfile = output .. ".d"
  local out = gen.chain(
      gen.pack(output, ": ", fp_config),
      gen.ivals(deps):intersperse(" "),
      gen.pack("\n", depsfile, ": ", input, "\n"))
    :vec()
    :concat()
  check(fs.writefile(depsfile, out))
end

-- TODO: Same as above
local function process_file (check, conf, input, output, deps, fp_config)
  local data = check(fs.readfile(input))
  local tmpl = check(tpl(data, conf))
  local out = check(tmpl(conf.env))
  check(fs.mkdirp(fs.dirname(output)))
  check(fs.writefile(output, out))
  if deps then
    write_deps(check, tmpl.deps, input, output, fp_config)
  end
end

-- TODO: Same as above
local function process_files (check, conf, trim, input, mode, output, deps, fp_config)
  if mode == "directory" then
    fs.files(input, { recurse = true })
      :map(check)
      :each(function (fp, mode)
        process_files(check, conf, trim, fp, mode, output, deps, fp_config)
      end)
  elseif mode == "file" then
    local trimlen = trim and string.len(trim)
    local outfile = input
    if trim and outfile:sub(0, trimlen) == trim then
      outfile = outfile:sub(trimlen + 1)
    end
    output = fs.join(output, outfile)
    process_file(check, conf, input, output, deps, fp_config)
  else
    error("Unexpected mode: " .. mode .. " for file: " .. input)
  end
end

-- TODO: Same as above
local function get_config (check, config)
  local lenv = inherit.pushindex({}, _G)
  local cfg = config and check(fs.loadfile(config, lenv))() or {}
  cfg.env = inherit.pushindex(cfg.env or {}, _G)
  return cfg
end

assert(err.pwrap(function (check)

  if args.template then
    local conf = get_config(check, args.config)
    if args.directory then
      check(fs.mkdirp(args.output))
      gen.ivals(args.input):each(function (i)
        local mode = check(fs.attr(i, "mode"))
        process_files(check, conf, args.trim, i, mode, args.output, args.deps, args.config)
      end)
    elseif args.file then
      process_file(check, conf, args.file, args.output, args.deps, args.config)
    else
      parser:error("either -f --file or -d --directory must be provided")
    end
  elseif args.bundle then
    check(bundle(
      args.file, args.output, args.outputname,
      args.env, args.cflags, args.ldflags, args.cmpenv,
      args.deps, args.depstarget, args.load, args.ignore,
      args.noclose, args.noluac))
  elseif args.test then
    check(test.runfiles(args.files, args.interp, args.match, args.stop))
  else
    -- Not possible
    error("This is a bug")
  end

end, err.error))
