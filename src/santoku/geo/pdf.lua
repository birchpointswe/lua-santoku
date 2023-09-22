local zlib = require("zlib")
local gen = require("santoku.gen")
local vec = require("santoku.vector")
local err = require("santoku.err")
local str = require("santoku.string")

local M = {}

-- TODO: This needs to be seriously refactored

-- Find a Dictionary with Type/Page. If there
-- are more than one of these, fail since we
-- don't handle multi-page maps.
--
-- Inside this dictionary, there will be a
-- MediaBox array which contains two points
-- corresponding to the diagonal of the page,
-- and a VP array containing multiple
-- Dictionaries, each of which will contain a
-- BBox array containing two x/y points
-- corresponding to the diagonal of a box.
-- within the page, and a Measure reference.
--
-- For each BBox, find the corresponding
-- Measure object, in which there will be a GPTS
-- array containing coordinates corresponding to
-- the 4 points of the BBox.
--
-- Open items:
--   - Doesn't account for projections
--   - Doesn't handle bounds and LPTS that are
--     less than the max of the BBox
--   - Some of this relies on certain objects
--     being direct and certain objects being
--     indirect.
--   - We are not caching any defaltes, which we
--     might want to do

M.extract_pdf_georefs = function (data)
  return err.pwrap(function (check)
    local page = nil
    for d in data:gmatch("%b<>") do
      if d:match("Type/Page[%/%>]") then
        if page then
          check(false, "Found more than one page")
        end
        page = d
      end
    end
    if not page then
      check(false, "Could't find a page")
    end
    page = page:gsub("[^%g%s]", "_")
    local mediabox = page:match("MediaBox(%b[])")
    if not mediabox then
      check(false, "Couldn't find a MediaBox")
    end
    local x0, y0, x1, y1 = str.match(mediabox:sub(2, #mediabox - 1), "%d*"):map(function (n)
      return check(pcall(tonumber, n))
    end):unpack()
    mediabox = { { x = x0, y = y0 }, { x = x1, y = y1 } }
    local vp = page:match("VP(%b[])")
    if not vp then
      check(false, "Couldn't find a viewport")
    end
    local bboxes = str.match(vp:sub(2, #vp - 1), "(%b<>)")
    if #bboxes < 1 then
      check(false, "Could't find any boxes")
    end
    local boxes = bboxes:map(function (b)
      local bbox = b:match("BBox(%b[])")
      if not bbox then
        check(false, "Couldn't find a bbox")
      end
      local left, bottom, top, right = str.match(bbox:sub(2, #bbox - 1), "[^%s]*"):map(function (n)
        return check(pcall(tonumber, n))
      end):unpack()
      bbox = vec({ x = left, y = bottom }, { x = left, y = top }, { x = right, y = top }, { x = right, y = bottom })
      local measure = b:match("/Measure (%d*) 0 R/")
      if not measure then
        check(false, "Couldn't find a measure")
      end
      for fd in data:gmatch("/FlateDecode/.-stream\r?\n.-\r?\nendstream") do
        if fd:match("Type/ObjStm.-stream") then
          local first = fd:match("First (%d*)")
          if not first then
            check(false, "Missing 'First' key")
          end
          first = check(pcall(tonumber, first))
          local stream = fd:match("stream\r\n(.-)endstream")
          local ok, inflated = pcall(zlib.inflate(), stream)
          if ok then
            local _, offset = gen.ivals(str.match(inflated:sub(1, first), "%d*")):group(2):co():find(function (id)
              return id == measure
            end)
            if offset then
              local dict = inflated:match("%b<>", first + offset)
              if dict then
                local gpts = dict:match("GPTS(%b[])")
                if err.pwrap(function (check)
                  local i = 1
                  gen.ipairs(gen.ivals(str.match(gpts:sub(2, #gpts - 1), "[^%s]*"))
                    :map(function (i)
                      return check(pcall(tonumber, i))
                    end)
                    :group(2):each(function (a, b)
                      bbox[i].lat = a
                      bbox[i].lon = b
                      i = i + 1
                    end))
                end) then
                  break
                end
              end
            end
          end
        end
      end
      return bbox
    end)
    return {
      -- IN INCHES, by default, pdf units are
      -- 1/72s of a inch. Wtf
      width = math.abs(mediabox[1].x - mediabox[2].x) / 72,
      height = math.abs(mediabox[1].y - mediabox[2].y) / 72,
      boxes = boxes
    }
  end)
end

return M
