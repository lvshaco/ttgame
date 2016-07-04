local shaco = require "shaco"
local login = require "login"
local userpool = require "userpool"
local user = require "user"
local pb = require "protobuf"
local myredis = require "myredis"
local gamestate = require "gamestate"
local msghelper = require "msghelper"
local tbl = require "tbl"
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

local A_DAYS = {
    1, 8, 15, 22
}

local function calc_award(now)
    local award = ctx.award
    if not award then
        award = myredis.get("award")
        if not award then
            award = {
                refresh_time = 0,
            }
        else
            award = pb.decode("award_list", award)
            shaco.info(tbl(award, "load award"))
        end
        ctx.award = award
    end
    local tm = os.date("*t", now)
    local lasttm = os.date("*t", award.refresh_time)

    if tm.year == lasttm.year and
       tm.month == lasttm.month then
        if not award.list then
            award.list = {}
        end
    else
        local l = {}
        for _, v in ipairs(A_DAYS) do
            if v>= tm.day then
                local v2 = v+6
                local day1 = math.random(v, v2) 
                local day2
                while true do
                    day2 = math.random(v, v2)
                    if day2 ~= day1 then
                        break
                    end
                end
                local a1 = { type=1, day=day1 }
                local a2 = { type=2, day=day2 }
                if day1 < day2 then
                    l[#l+1] = a1
                    l[#l+1] = a2
                else
                    l[#l+1] = a2
                    l[#l+1] = a1
                end
            end
        end
        award.list = l
        award.refresh_time = now
        myredis.set("award", pb.encode("award_list", award))
        shaco.info(tbl(award, "recalc award"))
        local pkg = msghelper.packmsg(IDUM_AwardList, {list = award.list})
        userpool.foreach_user(function(ur)
            ur:sendpackedmsg(IDUM_AwardList, pkg)
        end) 
    end 
end

function logic.init(conf)
    local now = shaco.now()//1000
    math.randomseed(now)

    local msgn2id = {}
    for id, v in pairs(MSG_REQNAME) do
        msgn2id[v] = id
    end
    ctx.msgn2id = msgn2id

    --mydb.init(conf.db)
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

    calc_award(now)

    rank.init()
end

local __lastday = util.msecond2day(shaco.now())
local __lastw = shaco.now()//1000

function logic.update()
    local now = shaco.now()//1000
	local nowday = util.second2day(now)
    local week = os.date("*t", now).wday

    local daychanged
    if nowday ~= __lastday then
        __lastday = nowday
        daychanged = true
    end
    
    local weekchanged, week = util.changeweek(__lastw, now)
    if weekchanged then
        __lastw = week
        weekchanged = true
    end
    if daychanged then
        calc_season(now)
        calc_award(now)
    end
	userpool.update(now, daychanged, weekchanged)
	rank.update(now, daychanged, weekchanged)
end

function logic.dispatch(connid, msgid, v)
    if msgid == IDUM_Login then
        local ok, err = xpcall(login.login, traceback, connid, v)
        if not ok then
            if err == ctx.error_logout then
                return
            else 
                shaco.error(err)
                ctx.logout(connid, err)
            end
        else
            if err then
                ur:send(IDUM_Response, {msgid=msgid, err=err})
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
        end
        ur:db_flush()
    end
end

return logic 
