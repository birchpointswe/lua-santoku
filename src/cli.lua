-- TODO: Write tests for this

local argparse = require("argparse")
local gen = require("santoku.gen")
local err = require("santoku.err")
local fs = require("santoku.fs")
local tpl = require("santoku.template")
local bundle = require("santoku.bundle")
local compat = require("santoku.compat")

local parser = argparse()
  :name("toku")
  :description("A command lind interface to the santoku lua library")

local cbundle = parser
  :command("bundle", "create standalone executables")

cbundle
  :argument("input", "the entrypoint lua file")
  :args(1)

cbundle
  :option("-o --output", "output directory")
  :default(".")
  :count(1)

local ctemplate = parser
  :command("template", "process templates")

ctemplate
  :argument("input", "files or directories")
  :args("+")

ctemplate
  :flag("-r --recursive", "descend directories")

ctemplate
  :option("-o --output", "output directory")
  :count(1)

ctemplate
  :option("-t --trim", "prefix to trim off sources files before output")
  :count("?")

ctemplate
  :option("-f --config", "a configuration file")
  :count("0-1")

local args = parser:parse()

-- TODO: Consider migrating this logic to
-- santoku.template or to a santoku.cli.template
-- sub-module.
function process_file (check, conf, trim, input, mode, output, recurse)
  if mode == "directory" and recurse then
    fs.files(input, { recurse = true })
      :map(check)
      :each(function (fp, mode)
        process_file(check, conf, trim, fp, mode, output, recurse)
      end)
  elseif mode == "file" then
    local data = check(fs.readfile(input))
    local tmpl = check(tpl(data, conf))
    local out = check(tmpl(conf.env))
    -- TODO: this doesn't need to be computed
    -- every time this is called
    local trimlen = string.len(trim)
    if trim and input:sub(0, trimlen) == trim then
      input = input:sub(trimlen + 1)
    end
    output = fs.join(output, input)
    check(fs.mkdirp(fs.dirname(output)))
    check(fs.writefile(output, out))
  else
    error("Unexpected mode: " .. mode .. " for file: " .. input)
  end
end

-- TODO: Same as above
function get_config (check, config)
  if config then
    return check(fs.loadfile(config))()
  else
    return {}
  end
end

assert(err.pwrap(function (check)

  if args.template then
    check(fs.mkdirp(args.output))
    local conf = get_config(check, args.config)
    gen.ivals(args.input):each(function (i) 
      local mode = check(fs.attr(i, "mode"))
      process_file(check, conf, args.trim, i, mode, args.output, args.recursive)
    end)
  elseif args.bundle then
    check(bundle(args.input, args.output))
  end

end, err.error))
