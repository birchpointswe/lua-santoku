-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023 Birch Point SWE
local env = {
  name = "santoku",
  version = "2.6.0-1",
  variable_prefix = "TK",
  license = "MIT",
  copyright = "Birch Point SWE",
  vendored = {
    {
      name = "klib",
      path = { "res/vendor/klib/khash.h", "res/vendor/klib/ksort.h", "res/vendor/klib/kvec.h" },
      copyright = {
        "(c) 2008, 2009, 2011 by Attractive Chaos <attractor@live.co.uk>",
        "(c) 2008, 2011 Attractive Chaos <attractor@live.co.uk>",
        "(c) 2008, by Attractive Chaos <attractor@live.co.uk>",
      },
      license = "MIT",
      note = "From https://github.com/attractivechaos/klib, inlined into the installed santoku/klib.h.",
    },
    {
      name = "SHA-256 by Brad Conte",
      path = { "res/vendor/bradconte/sha256.h" },
      license = "LicenseRef-PublicDomain",
      text = "This code is released into the public domain free of any restrictions. The author requests "
        .. "acknowledgement if the code is used, but does not require it. This code is provided free of any "
        .. "liability and without any quality claims by the author.",
      note = "From https://github.com/B-Con/crypto-algorithms, with identifiers renamed to tk_.",
    },
    {
      name = "Unicode Character Database 16.0.0 tables",
      path = { "lib/santoku/string/utf8.h" },
      license = "Unicode-3.0",
      note = "lib/santoku/string/utf8.h is generated from UnicodeData.txt and CaseFolding.txt by res/ucd/gen.lua.",
    },
  },
  public = true,
  cflags = {
    "-Wall", "-Wextra", "-Wsign-compare", "-Wsign-conversion",
    "-Wstrict-overflow", "-Wpointer-sign"
  },
  ldflags = {
    "-lm"
  },
  dependencies = {
    "lua == 5.1",
  },
}

env.homepage = "https://github.com/birchpointswe/lua-" .. env.name
env.tarball = env.name .. "-" .. env.version .. ".tar.gz"
env.download = env.homepage .. "/releases/download/" .. env.version .. "/" .. env.tarball

return { env = env }
