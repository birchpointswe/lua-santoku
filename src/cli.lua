local argparse = require("argparse")
local err = require("santoku.err")
local fs = require("santoku.fs")
local tpl = require("santoku.template")

local parser = argparse()
  :name("toku")
  :description("A command lind interface to the santoku lua library")

local ctemplate = parser
  :command("template", "process templates")

ctemplate
  :argument("input", "file or directory")

ctemplate
  :flag("-r --recursive", "descend directories")

ctemplate
  :option("-o --output", "output file or directory")
  :count(1)

ctemplate
  :option("-f --config", "a configuration file")
  :count("0-1")

local args = parser:parse()

function process_file (check, conf, input, output, isdir)
  local data = check(fs.readfile(input))
  local tmpl = check(tpl(data, conf))
  local out = tmpl(conf.env)
  if isdir then
    local outfile = fs.join(output, input)
    local outdir = fs.dirname(outfile)
    check(fs.mkdirp(outdir))
    output = outfile
  end
  check(fs.writefile(output, out))
end

function get_config (check, config)
  if config then
    return check(compat.loadfile(config))
  else
    return {}
  end
end

assert(err.pwrap(function (check)

  if args.template then
    local conf = get_config(check, args.config)
    if args.recursive then
      fs.files(args.input, { recurse = true })
        :map(check)
        :each(function (fp)
          process_file(check, conf, fp, args.output, true)
        end)
      else
        process_file(check, conf, args.input, args.output, false)
      end
    end

end, err.error))
