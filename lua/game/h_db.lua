local shaco = require "shaco"
local tbl = require "tbl"
local sfmt = string.format

local function exec(db, fmt, ...)
    local r = db:execute(sfmt(fmt, ...))
    --shaco.trace(tbl(r))
    if r.err_code then
        error(r.message)
    end
    return r
end

local REQ = {}

REQ['L.role'] = function(db, acc)
    local r = exec(db, "select roleid, gmlevel, info from x_role where acc=%s",
        db.escape_string(acc))
    shaco.ret(shaco.pack(r[1]))
    shaco.trace("L.role ok", acc)
end

REQ['I.role'] = function(db, acc, gmlevel)
    local r = exec(db, "insert into x_role (acc, gmlevel) values (%s,%d)", 
        db.escape_string(acc), gmlevel)
    shaco.ret(shaco.pack(r.last_insert_id))
    shaco.trace("I.role ok", acc, r.last_insert_id, gmlevel)
end

REQ["S.role"] = function(db, roleid, info)
    exec(db, "update x_role set info=%s where roleid=%u", 
        db.escape_string(info), roleid)
    shaco.trace("S.role ok", roleid)
end

REQ["L.ex"] = function(db, name, roleid)
    local r = exec(db, "select data from x_%s where roleid=%u", name, roleid)
    r = r[1]
    shaco.ret(shaco.pack(r and r.data or nil))
    shaco.trace("L.ex ok", name, roleid)
end

REQ["S.ex"] = function(db, name, roleid, data)
    local to = db.escape_string(data)
    exec(db, "insert into x_%s (roleid,data) values (%d,%s) on duplicate key update data=%s", 
        name, roleid, to, to)
    shaco.trace("S.ex ok", name, roleid)
end

return REQ
