local shaco = require "shaco"
local ctx = require "ctx"
local gamestate = require "gamestate"
local sformat = string.format
local callum = shaco.callum
local sendum = shaco.sendum
local LOGOUT = gamestate.LOGOUT

local myredis = {}

local __db

function myredis.init(db)
    assert(db)
    __db = db
end

function myredis.urcall(ur, cmd, ...)
    local result = callum(__db, cmd, ...)
    if ur.status == LOGOUT then
        error(ctx.error_logout)
    end
    return result
end

function myredis.call(cmd, ...)
    return callum(__db, cmd, ...)
end

function myredis.send(cmd, ...)
    return sendum(__db, cmd, ...)
end

local function new_key(key, newkey)
    if not newkey then
        local now = shaco.now()//1000
        newkey = sformat("%s:%s", key, os.date("%Y%m%d", now))
    end
    if myredis.exists(newkey) then
        local now_ms = shaco.now()
        local now = now_ms//1000
        newkey = sformat("%s:%s.%d", key, 
            os.date("%Y%m%d-%H%M%S", now),
            now_ms-now*1000)
        shaco.error("Conflict redis key, regen to: "..newkey)
    end
    return newkey
end

function myredis.rename(key, newkey)
    local newkey = new_key(key, newkey)
    myredis.call('rename', key, newkey)
    local count = myredis.zcount(newkey, "-inf", "+inf")
    return newkey, count
end

function myredis.backupkey(key, newkey)
    local newkey = new_key(key, newkey)
    local count = myredis.zunionstore(newkey, 1, key)
    return newkey, count
end

setmetatable(myredis, { __index = function(t, k)
    local f = function(...)
        return myredis.call(k, ...)
    end
    t[k] = f
    return f
end})

return myredis
