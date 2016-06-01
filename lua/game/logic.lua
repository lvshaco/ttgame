local shaco = require "shaco"
local login = require "login"
local userpool = require "userpool"
local user = require "user"
local mydb = require "mydb"
local myredis = require "myredis"
local gamestate = require "gamestate"
local MSG_REQNAME = require "msg_reqname"
local rank = require "rank"
local util = require "util"
local pcall = pcall
local xpcall = xpcall
local traceback = debug.traceback

local REQ = require "req"
REQ.__REG {
    "h_gm",
    "h_fight",
    "h_user",
    "h_item",
    "h_rank",
    "h_relation",
    "h_msg",
}

local ctx = require "ctx"
ctx.error_logout = setmetatable({}, { 
    __tostring = function() return "[Error: have logout]" end
})

local logic = {
    interval = 1000,
}

function logic.init(conf)
    math.randomseed(shaco.now())

    local msgn2id = {}
    for id, v in pairs(MSG_REQNAME) do
        msgn2id[v] = id
    end
    ctx.msgn2id = msgn2id

    mydb.init(conf.db)
    myredis.init(conf.rd)
    local opentime = tonumber(myredis.get('server_opentime'))
    if not opentime then
        opentime = shaco.now()//1000
        myredis.set('server_opentime', opentime)
    end
    ctx.server_opentime = opentime
    
    rank.init()
end

local __lastday = util.msecond2day(shaco.now())

function logic.update()
    local now = shaco.now()
	local nowday = util.second2day(now)
    local daychanged
    if nowday ~= __lastday then
        __lastday = nowday
        daychanged = true
    end
	userpool.update(now, daychanged)
	rank.update(now, daychanged)
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
            shaco.trace("Response:", err)
        end
        if ur.status == gamestate.GAME then
            ur:db_flush()
        end
    end
end

return logic 
