-- TODO: Write tests for this
-- TODO: Split into multiple cli modules

local argparse = require("argparse")
local inherit = require("santoku.inherit")
local gen = require("santoku.gen")
local err = require("santoku.err")
local vec = require("santoku.vector")
local str = require("santoku.string")
local sys = require("santoku.system")
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
  :flag("-M --deps", "generate a make .d file")
  :count("0-1")

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

-- TODO: Use emscripten to allow iterative
-- client-side notebooks
local cnotebook = parser
  :command("notebook", "generate lua notebooks")

cnotebook
  :option("-c --config", "a template configuration file")
  :args(1)
  :count("0-1")

cnotebook
  :flag("-s --serve", "open a browser to serve the generated html and automatically re-generate on changes")
  :count("0-1")

cnotebook
  :option("-p --port", "port to run the server on")
  :args(1)
  :count("0-1")

cnotebook
  :option("-S --rlcmd", "reload command")
  :default("reload -b -p %port -d \"%outputdir\" -s \"%outputfile\" &")
  :args(1)
  :count(1)

cnotebook
  :option("-M --mdcmd", "markdown command")
  :default("pandoc \"%input\" -o \"%output\"")
  :args(1)
  :count(1)

cnotebook
  :option("-C --codefmt", "code formatter")
  :default("santoku.template.format.markdown-pre")
  :args(1)
  :count("+")

cnotebook
  :option("-R --resultfmt", "result formatter")
  :default("santoku.template.format.inspect", "santoku.template.format.markdown-pre")
  :args(1)
  :count("+")

cnotebook
  :option("-f --file", "input file")
  :args(1)
  :count(1)

cnotebook
  :option("-o --output", "output file")
  :args(1)
  :count(1)

local args = parser:parse()

-- TODO: Move this logic into santoku.template
local function write_deps (check, deps, input, output)
  local depsfile = output .. ".d"
  local out = gen.chain(
      gen.pack(output, ": "),
      gen.ivals(deps):intersperse(" "),
      gen.pack("\n", depsfile, ": ", input, "\n"))
    :vec()
    :concat()
  check(fs.writefile(depsfile, out))
end

-- TODO: Same as above
local function process_file (check, conf, input, output, codefmt, resultfmt, deps)
  local data = check(fs.readfile(input))
  local tmpl = check(tpl(data, conf))
  local out = check(tmpl(conf.env, codefmt, resultfmt))
  check(fs.mkdirp(fs.dirname(output)))
  check(fs.writefile(output, out))
  if deps then
    write_deps(check, tmpl.deps, input, output)
  end
end

-- TODO: Same as above
local function process_files (check, conf, trim, input, mode, output, codefmt, resultfmt, deps)
  if mode == "directory" then
    fs.files(input, { recurse = true })
      :map(check)
      :each(function (fp, mode)
        process_files(check, conf, trim, fp, mode, output, codefmt, resultfmt, deps)
      end)
  elseif mode == "file" then
    local trimlen = trim and string.len(trim)
    local outfile = input
    if trim and outfile:sub(0, trimlen) == trim then
      outfile = outfile:sub(trimlen + 1)
    end
    output = fs.join(output, outfile)
    process_file(check, conf, input, output, codefmt, resultfmt, deps)
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

local function process_markdown (check, mdcmd, input, output)
  local cmd = str.interp(mdcmd, { 
    input = input,
    output = output 
  })
  check(sys.sh(cmd))
end

local function run_reloader (check, rlcmd, port, output)
  local cmd = str.interp(rlcmd, {
    port = port,
    outputdir = fs.dirname(output),
    outputfile = fs.basename(output)
  })
  check(sys.sh(cmd))
end

local function process_notebook (check, conf, mdcmd, input, output, codefmt, resultfmt) 
  local posttpl = fs.replaceext(args.output, ".html")
  local pretpl = fs.replaceext(args.output, ".tmp.md")
  local conf = get_config(check, args.config)
  process_file(check, conf, args.file, pretpl, args.codefmt, args.resultfmt, false)
  process_markdown(check, mdcmd, pretpl, posttpl)
end

assert(err.pwrap(function (check)

  if args.template then
    local conf = get_config(check, args.config)
    if args.directory then
      check(fs.mkdirp(args.output))
      gen.ivals(args.input):each(function (i) 
        local mode = check(fs.attr(i, "mode"))
        process_files(check, conf, args.trim, i, mode, args.output, false, false, args.deps)
      end)
    elseif args.file then 
      process_file(check, conf, args.file, args.output, false, false, args.deps)
    else
      parser:error("either -f --file or -d --directory must be provided")
    end
  elseif args.bundle then
    check(bundle(args.file, args.output, args.env, args.deps))
  elseif args.notebook then
    process_notebook(check, conf, args.mdcmd, args.file, args.output, args.codefmt, args.resultfmt)
    if args.serve then
      run_reloader(check, args.rlcmd, args.port, args.output)
      check(fs.watch(args.file, function ()
        process_notebook(check, conf, args.mdcmd, args.file, args.output, args.codefmt, args.resultfmt)
      end))
    end
  else
    -- Not possible
    error("This is a bug")
  end

end, err.error))
