local shaco = require "shaco"
local mysql = require "mysql"
local REQ = require "h_db"

shaco.start(function()
    local __db

    shaco.dispatch("um", function(source, session, cmd, ...)
        shaco.trace(cmd, ...)
        local f = assert(REQ[cmd])
        f(__db, ...)
    end)

    __db = assert(mysql.connect{
        host = assert(shaco.getenv("gamedb_host")),
        port = assert(shaco.getenv("gamedb_port")),
        db = assert(shaco.getenv("gamedb_name")),
        user = assert(shaco.getenv("gamedb_user")),
        passwd = assert(shaco.getenv("gamedb_passwd"))
    })
    shaco.info("gamedb connect ok")

    shaco.fork(function()
        while true do
            __db:ping()
            shaco.info("gamedb ping")
            shaco.sleep(1800*1000)
        end
    end)
end)
