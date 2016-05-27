local shaco = require "shaco"
local sfmt = string.format
local redis = require "redis"

shaco.start(function()
    local __db 

    shaco.dispatch("um", function(_, session, cmd, ...)
        if session > 0 then
            shaco.ret(shaco.pack(__db[cmd](__db, ...)))
        else
            __db[cmd](__db, ...)
        end
    end)    

    __db = assert(redis.connect {
        host = shaco.getenv("redis_host"),
        port = tonumber(shaco.getenv("redis_port")),
        auth = shaco.getenv("redis_passwd"),
    })
    shaco.info("redisdb connect ok")
    shaco.fork(function()
        while true do
            __db:ping()
            shaco.info("redisdb ping")
            shaco.sleep(1800*1000)
        end
    end)
end)
