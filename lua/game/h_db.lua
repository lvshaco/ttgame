local shaco = require "shaco"
local tbl = require "tbl"
local sfmt = string.format

local function exec(db, fmt, ...)
    local r = db:execute(sfmt(fmt, ...))
    --shaco.trace(tbl(r))
    assert(r.err_code==nil, r.message)
    return r
end

local REQ = {}

REQ['L.role'] = function(db, acc)
    local r = exec(db, "select roleid, gmlevel, info from x_role where acc=%s",
        db.escape_string(acc))
    shaco.ret(shaco.pack(r[1]))
end

REQ['I.role'] = function(db, acc, gmlevel)
    local r = exec(db, "insert into x_role (acc, gmlevel) values (%s,%d)", 
        db.escape_string(acc), gmlevel)
    shaco.ret(shaco.pack(r.last_insert_id))
end

REQ["S.role"] = function(db, roleid, info)
    exec(db, "update x_role set info=%s where roleid=%u", 
        db.escape_string(info), roleid)
end


return REQ
