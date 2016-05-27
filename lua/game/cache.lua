local shaco = require "shaco"
local pb = require "protobuf"
local myredis = require "myredis"

local cache = {}

function cache.query(roleid)
    local r = myredis.get('role:'..roleid)
    if not r then
        return SERR_Norole
    end
    return pb.decode('role_info', r)
end

function cache.store(ur)
end

return cache
