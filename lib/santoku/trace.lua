-- SPDX-License-Identifier: MIT
-- SPDX-FileCopyrightText: 2023 Birch Point SWE
local lua = require("santoku.lua")
local tracer = require("santoku.tracer")
_G[lua.userdata({ __gc = tracer() })] = true
