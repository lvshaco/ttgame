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
    "h_friend",
}

local ctx = require "ctx"
ctx.error_logout = setmetatable({}, { 
    __tostring = function() return "[Error: have logout]" end
})

local logic = {
    interval = 1000,
}

local function calc_season(now)
    local season = 1 
    local last = util.lastmonthbase(now)
    local openbase = util.lastmonthbase(ctx.server_opentime)
    while last >= openbase do
        season = season+1
        assert(season < 24)
        last = util.lastmonthbase(last)
    end
    ctx.season = season
    shaco.info("season:", season)
end

function logic.init(conf)
    local now = shaco.now()//1000
    math.randomseed(now)

    local msgn2id = {}
    for id, v in pairs(MSG_REQNAME) do
        msgn2id[v] = id
    end
    ctx.msgn2id = msgn2id

    mydb.init(conf.db)
    myredis.init(conf.rd)

    -- roleid
    local startid = 1000000
    local roleid = myredis.incr('role_uniqueid')
    if roleid < startid then
        roleid = startid
        myredis.set('role_uniqueid', roleid)
    end
    shaco.info("role_uniqueid:", roleid)

    -- server_opentime
    local opentime = tonumber(myredis.get('server_opentime'))
    if not opentime then
        opentime = now
        myredis.set('server_opentime', opentime)
    end
    ctx.server_opentime = opentime
    shaco.info("server_opentime:", os.date("%Y%m%d %H%M%S", opentime))

    -- season
    calc_season(now)

    rank.init()
end

local __lastday = util.msecond2day(shaco.now())

function logic.update()
    local now = shaco.now()//1000
	local nowday = util.second2day(now)
    local daychanged
    if nowday ~= __lastday then
        __lastday = nowday
        daychanged = true
    end
    if daychanged then
        calc_season(now)
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
        assert(ur.status == gamestate.GAME)
        local ok, err = xpcall(f, traceback, ur, v)
        if not ok then
            shaco.error(err)
            err = SERR_Exception
        end
        if err then
            ur:send(IDUM_Response, {msgid=msgid, err=err})
            shaco.trace("Response:", err)
        end
        ur:db_flush()
    end
end

return logic 
