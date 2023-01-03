runreport = true
statsfile = "test/luacov.stats.out"
reportfile = "test/luacov.report.out"
includeuntestedfiles = true

-- TODO: Can we load this from the rockspec
-- itself?
modules = {

    ["santoku"] = "src/santoku.lua",

    ["santoku.co"] = "src/santoku/co.lua",
    ["santoku.err"] = "src/santoku/err.lua",
    ["santoku.fs"] = "src/santoku/fs.lua",
    ["santoku.gen"] = "src/santoku/gen.lua",
    ["santoku.inherit"] = "src/santoku/inherit.lua",
    ["santoku.op"] = "src/santoku/op.lua",
    ["santoku.statistics"] = "src/santoku/statistics.lua",
    ["santoku.string"] = "src/santoku/string.lua",
    ["santoku.utils"] = "src/santoku/utils.lua",
    ["santoku.validation"] = "src/santoku/validation.lua",

    ["santoku.posix"] = "src/santoku/posix.lua",
    ["santoku.socket"] = "src/santoku/socket.lua",
    ["santoku.sqlite"] = "src/santoku/sqlite.lua",

}
