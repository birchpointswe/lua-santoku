local gen = require("santoku.gen")
local compat = require("santoku.compat")
local err = require("santoku.err")
local sqlite = require("lsqlite3")

local M = {}

M.MT = {
  __index = sqlite
}

M.MT_SQLITE_DB = {
  __name = "santoku_sqlite_db",
  __index = function (o, k)
    return o.db[k]
  end
}

M.MT_SQLITE_STMT = {
  __index = function (o, k)
    return o.stmt[k]
  end,
  __call = function (o, ...)
    return o.fn(...)
  end
}

M._check = function (db, res, code, msg)
  if not res then
    if not msg and db then
      msg = db.db:errmsg()
    end
    if not code and db then
      code = db.db:errcode()
    end
    return false, msg, code
  else
    return true, res
  end
end

-- TODO: How does this work if I want to bind a
-- list of values by position?
M._bind = function (stmt, ...)
  if select("#", ...) == 0 then
    return stmt
  end
  local t = select(1, ...)
  if not compat.isprimitive(t) and compat.hasmeta.index(t) then
    return stmt:bind_names(t)
  else
    return stmt:bind_values(...)
  end
end

M._query = function (db, stmt, ...)
  local ok = M._bind(stmt, ...)
  if not ok then
    return false, db.db:errmsg(), db.db:errcode()
  else
    local res = nil
    local err = false
    return true, gen(function (yield)
      while true do
        res = stmt:step()
        if res == sqlite.ROW then
          yield(true, stmt:get_named_values())
        elseif res == sqlite.DONE then
          break
        else
          err = true
          break
        end
      end
      stmt:reset()
      if err then
        yield(false, db.db:errmsg(), db.db:errcode())
      end
    end)
  end
end

M._get_one = function (db, stmt, ...)
  local ok = M._bind(stmt, ...)
  if not ok then
    return false, db.db:errmsg(), db.db:errcode()
  else
    local res = stmt:step()
    if res == sqlite.ROW then
      local val = stmt:get_named_values()
      stmt:reset()
      return true, val
    elseif res == sqlite.DONE then
      stmt:reset()
      return true
    else
      local em, ec = db.db:errmsg(), db.db:errcode()
      stmt:reset()
      return false, em, ec
    end
  end
end

M._get_val = function (db, stmt, prop, ...)
  local ok, val = M._get_one(db, stmt, ...)
  if ok and val then
    return true, val[prop]
  elseif ok and not val then
    return true, nil
  else
    return false, val
  end
end

M.open = function (...)
  local ok, db, cd = M._check(nil, sqlite.open(...))
  if not ok then
    return false, db, cd
  else
    return true, M.wrap(db)
  end
end

M.open_memory = function (...)
  local ok, db, cd = M._check(nil, sqlite.open_memory(...))
  if not ok then
    return false, db, cd
  else
    return true, M.wrap(db)
  end
end

M.open_ptr = function (...)
  local ok, db, cd = M._check(nil, sqlite.open_ptr(...))
  if not ok then
    return false, db, cd
  else
    return true, M.wrap(db)
  end
end

M.wrap = function (db)
  -- TODO: Should these top-level functions
  -- accept extra arguments to be passed to the
  -- inner queries as fixed parameters?
  return setmetatable({

    db = db,

    begin = function (db)
      local res = db.db:exec("begin;")
      if res ~= sqlite.OK then
        return false, db.db:errmsg(), db.db:errcode()
      else
        return true
      end
    end,

    commit = function (db)
      local res = db.db:exec("commit;")
      if res ~= sqlite.OK then
        return false, db.db:errmsg(), db.db:errcode()
      else
        return true
      end
    end,

    rollback = function (db)
      local res = db.db:exec("rollback;")
      if res ~= sqlite.OK then
        return false, db.db:errmsg(), db.db:errcode()
      else
        return true
      end
    end,

    exec = function (db, ...)
      local res = db.db:exec(...)
      if res ~= sqlite.OK then
        return false, db.db:errmsg(), db.db:errcode()
      else
        return true
      end
    end,

    iter = function (db, sql)
      local ok, stmt, cd = M._check(db, db.db:prepare(sql))
      if not ok then
        return false, stmt, cd
      else
        return true, M.wrapstmt(stmt, function (...)
          return M._query(db, stmt, ...)
        end)
      end
    end,

    all = function (db, sql)
      local ok, stmt, cd = M._check(db, db.db:prepare(sql))
      if not ok then
        return false, stmt, cd
      else
        return true, M.wrapstmt(stmt, function (...)
          local ok, iter, cd = M._query(db, stmt, ...)
          if not ok then
            return ok, iter, cd
          else
            return err.pwrap(function (check)
              return iter:map(check):vec()
            end)
          end
        end)
      end
    end,

    runner = function (db, sql)
      local ok, stmt, cd = M._check(db, db.db:prepare(sql))
      if not ok then
        return false, stmt, cd
      else
        return true, M.wrapstmt(stmt, function (...)
          local ok, iter, cd = M._query(db, stmt, ...)
          if not ok then
            return false, iter, cd
          end
          local val
          iter:each(function (ok0, val0, cd0)
            ok, val, cd = ok0, val0, cd0
          end)
          return ok, val, cd
        end)
      end
    end,

    getter = function (db, sql, prop)
      local ok, stmt, cd = M._check(db, db.db:prepare(sql))
      if not ok then
        return false, stmt, cd
      else
        return true, M.wrapstmt(stmt, function (...)
          if prop then
            return M._get_val(db, stmt, prop, ...)
          else
            return M._get_one(db, stmt, ...)
          end
        end)
      end
    end,

    inserter = function (db, sql)
      local ok, getter, cd = db:getter(sql)
      if not ok then
        return false, getter, cd
      else
        return true, function (...)
          local ok, err, cd = getter(...)
          if ok then
            return true, db.db:last_insert_rowid()
          else
            return false, err, cd
          end
        end
      end
    end

  }, M.MT_SQLITE_DB)

end

M.wrapstmt = function (stmt, fn)
  return setmetatable({
    stmt = stmt,
    fn = fn,
  }, M.MT_SQLITE_STMT)
end

return setmetatable(M, M.MT)
