local argparse = require("argparse")
local err = require("santoku.err")

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

function process_file (check, conf, input, output)
  local data = check(fs.readfile(input))
  local tmpl = check(tpl(data, conf))
  local out = check(tmpl(conf.env))
  check(fs.writefile(output))
end

function get_config (check, config)
  if config then
    return check(compat.loadfile(config))
  else
    return {}
  end
end

err.pwrap(function (check)

  if args.template then
    local conf = get_config(check, args.config)
    if args.recursive then
      check(fs.files(args.input, { recurse = true }))
        :map(check)
        :each(function (fp)
          process_file(fp, conf, check)
        end)
    else
      process_file(args.input, conf, check)
    end
  end

end, err.error)
