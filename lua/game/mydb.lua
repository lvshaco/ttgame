local shaco = require "shaco"
local ctx = require "ctx"
local gamestate = require "gamestate"

local mydb = {}

local __db

function mydb.init(db)
    assert(db)
    __db = db
end

function mydb.urcall(ur, cmd, ...)
    local result = shaco.callum(__db, cmd, ...)
    if ur.status == gamestate.LOGOUT then
        error(ctx.error_logout)
    end
    return result

end

function mydb.send(cmd, ...)
    return shaco.sendum(__db, cmd, ...)
end

return mydb
