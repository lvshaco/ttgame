local shaco = require "shaco"
local login = require "login"
local userpool = require "userpool"
local user = require "user"
local mydb = require "mydb"
local gamestate = require "gamestate"
local pcall = pcall
local xpcall = xpcall
local traceback = debug.traceback

local REQ = require "req"
REQ.__REG {
    "h_gm",
--    "h_user",
--    "h_item",
}

local ctx = require "ctx"
ctx.error_logout = setmetatable({}, { 
    __tostring = function() return "[Error: have logout]" end
})

local logic = {}

function logic.update()
end

function logic.dispatch(connid, msgid, v)
    if msgid == IDUM_Login then
        local ok, err = xpcall(login.login, traceback, connid, v)
        if not ok then
            if err == ctx.error_logout then
                return
            else 
                ctx.logout(connid, err)
                shaco.error(err)
            end
        end
    else
        local f = assert(REQ[msgid], "Invalid msg id")
        local ur = userpool.find_byconnid(connid)
        assert(ur, "Not found user")
        local ok, err = xpcall(f, traceback, ur, v)
        if not ok then
            shaco.error(err)
            err = SERR_Exception
        end
        if err then
            ur:send(IDUM_Response, {msgid=msgid, err=err})
        end
        if ur.status == gamestate.GAME then
            ur:db_flush()
        end
    end
end

return logic 
