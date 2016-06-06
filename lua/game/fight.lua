local shaco = require "shaco"
local myredis = require "myredis"
local pb = require "protobuf"

local MAX = 10

local fight = {}

function fight.record(roleid, v)
    v = pb.encode('game_record', v)
    myredis.lpush('fight:'..roleid, v)
    myredis.ltrim('fight:'..roleid, 0, MAX-1)
end

function fight.getlist(roleid)
    local t = {}
    local t = myredis.lrange('fight:'..roleid, 0, MAX-1)
    for i, v in ipairs(t) do
        v = pb.decode('game_record', v)
        t[i] = v
    end
    return t
end

return fight
