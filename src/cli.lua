-- TODO: Write tests for this

local argparse = require("argparse")
local gen = require("santoku.gen")
local err = require("santoku.err")
local vec = require("santoku.vector")
local str = require("santoku.string")
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
  :option("-f --file", "input file")
  :args(1)
  :count(1)

cbundle
  :option("-o --output", "output directory")
  :args(1)
  :count(1)

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
  :option("-t --trim", "prefix to remove from directory prefix before output (only used when -d is provided)")
  :args(1)
  :count("?")

ctemplate
  :option("-c --config", "a configuration file")
  :args(1)
  :count("0-1")

ctemplate
  :option("-l --load", "load a module to the global namespace")
  :args(1)
  :count("*")

local args = parser:parse()

-- TODO: Move this logic into santoku.template
function process_file (check, conf, input, output)
  local data = check(fs.readfile(input))
  local tmpl = check(tpl(data, conf))
  local out = check(tmpl(conf.env))
  check(fs.mkdirp(fs.dirname(output)))
  check(fs.writefile(output, out))
end

-- TODO: Same as above
function process_files (check, conf, trim, input, mode, output)
  if mode == "directory" then
    fs.files(input, { recurse = true })
      :map(check)
      :each(function (fp, mode)
        process_files(check, conf, trim, fp, mode, output, recurse)
      end)
  elseif mode == "file" then
    local trimlen = trim and string.len(trim)
    local outfile = input
    if trim and outfile:sub(0, trimlen) == trim then
      outfile = outfile:sub(trimlen + 1)
    end
    output = fs.join(output, outfile)
    process_file(check, conf, input, output)
  else
    error("Unexpected mode: " .. mode .. " for file: " .. input)
  end
end

-- TODO: Same as above
function get_config (check, config, libs)
  local cfg = config and check(fs.loadfile(config))() or {} 
  cfg.env = cfg.env or {}
  if libs then
    gen.ivals(libs):each(function (lib)
      -- TODO: How does this behave with
      -- modules that contain dots?
      cfg.env[lib] = require(lib)
    end)
  end
  return cfg
end

assert(err.pwrap(function (check)

  if args.template then
    local libs = vec.wrap(args.load or {})
    local conf = get_config(check, args.config, libs)
    if args.directory then
      check(fs.mkdirp(args.output))
      gen.ivals(args.input):each(function (i) 
        local mode = check(fs.attr(i, "mode"))
        process_files(check, conf, args.trim, i, mode, args.output)
      end)
    elseif args.file then 
      process_file(check, conf, args.file, args.output)
    else
      parser:error("either -f --file or -d --directory must be provided")
    end
  elseif args.bundle then
    check(bundle(args.file, args.output, args.env))
  else
    -- Not possible
    error("This is a bug")
  end

end, err.error))
