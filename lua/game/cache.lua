local shaco = require "shaco"
local pb = require "protobuf"
local myredis = require "myredis"
local userpool = require "userpool"

local cache = {}

function cache.query(roleid)
    local ur = userpool.find_byid(roleid)
    if ur then
        return ur.info, ur
    end
    local r = myredis.get('role:'..roleid)
    if not r then
        return nil, SERR_Norole
    end
    return pb.decode('role_info', r), nil
end

function cache.queryv(rl, func)
    local l = {}
    for _, v in ipairs(rl) do
        local r = cache.query(v)
        if r then
            l[#l+1]=func(r)
        end
    end
    return l
end

return cache
