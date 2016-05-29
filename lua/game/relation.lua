local shaco = require "shaco"
local myredis = require "myredis"

local relation = {}

function relation.has(roleid, typ, targetid)
    return myredis.zscore(typ..':'..roleid, targetid)
end

function relation.mhas(roleid, typ, targetl)
    local r = {}
    for _, v in ipairs(targetl) do
        if relation.has(roleid, typ, v) then
            r[#r+1] = true
        else
            r[#r+1] = false
        end
    end
    return r
end

return relation
