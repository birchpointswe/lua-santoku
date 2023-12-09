-- TODO: Match the most general xml spec possible
-- TODO: Allow adding text in chunks (perhaps final generator value is the
-- unprocessed text?)

local gen = require("santoku.gen")
local L = require("lpeg")
local P = L.P
local S = L.S
local Cg = L.Cg
local Ct = L.Ct
local Cp = L.Cp

local M = {}

L.locale(L)

M.closing_tag = P("</") * L.space^0 * Cg((P(1) - (P(">") + L.space))^0, "close") * L.space^0 * P(">")
M.opening_tag_open = (P("<") - M.closing_tag) * Cg((P(1) - (P(">") + P("/>") + L.space))^0, "open") * L.space^0
M.opening_tag_close = Cg((P(">") + P("/>")), "open_close")
M.text = Cg((P(1) - (M.opening_tag_open + M.closing_tag))^1, "text")
M.value = P("=") * ((Cg(P('"'), "quote") * Cg((P('\\"') + (P(1) - P('"')))^0, "value") * P('"')) +
                    (Cg(P("'"), "quote") * Cg((P("\\'") + (P(1) - P("'")))^0, "value") * P("'")))

-- TODO: Attribute names are defined here as alnum/_/- but this is not accurate
-- per the spec
M.attribute = Cg(Ct(Cg((L.alnum + S("_-"))^1, "name") * M.value^0^-1), "attribute") * L.space^0

-- Matches text, opening tags, or closing tags. If an open tag is matched, state
-- moves to attributes
M.state_default = Ct((M.text + M.opening_tag_open + M.closing_tag) * Cg(Cp(), "position"))

-- Matches attributes or tag close
M.state_attributes = Ct((M.attribute + M.opening_tag_close) * Cg(Cp(), "position"))

M.parse = function (text)
  return gen(function (yield)
    local state = M.state_default
    local max = #text
    local start = 1
    while start <= max do
      local m = state:match(text, start)
      if not m then
        break
      end
      m.start = start
      start = m.position
      if m.open then
        state = M.state_attributes
        yield(m)
      elseif m.open_close then
        state = M.state_default
      elseif m.attribute then
        -- TODO: Ugly hack.
        -- How can we just modify the capture so that \\" becomes "?
        if m.attribute.value and m.attribute.quote then
          m.attribute.value = m.attribute.value:gsub("\\" .. m.attribute.quote, m.attribute.quote)
        end
        m.attribute.quote = nil
        yield(m)
      else
        yield(m)
      end
    end
  end)
end

return M
