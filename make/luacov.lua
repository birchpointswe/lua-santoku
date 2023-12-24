<%

  str = require("santoku.string")
  fs = require("santoku.fs")
  gen = require("santoku.gen")

  files = gen.ivals(build.libs):pastel("lib"):chain(gen.ivals(build.bins):pastel("bin"))
    :map(function (dir, fp)
      local mod = fs.stripextension(str.stripprefix(fp.src, dir)):gsub("/", "."):gsub("^.", "")
      return { mod = mod, fp = fp }
    end):vec()

%>

modules = {
  <% return gen.ivals(files):map(function (d)
    return str.interp("[\"%mod\"] = \"%src\"", { mod = d.mod, src = d.fp.src })
  end):concat(",\n") %>
}

include = {
  <% return gen.ivals(files):map(function (d)
    return str.quote(d.fp.build)
  end):concat(",\n") %>
}

statsfile = "<% return build.test_luacov_stats_file %>"
reportfile = "<% return build.test_luacov_report_file %>"
