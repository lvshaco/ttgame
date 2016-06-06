local shaco = require "shaco"
local myredis = require "myredis"
local ctx = require "ctx"
local util = require "util"

local rank = {}

local MAX_RANK = 1000
local RANKT = {
'power', 'fans', 'belike', 'flower', 'kill',
}
local DATET = {
'day', 'week', 'month', 'total', 'history',
}

function rank.rankt(typ)
    return RANKT[typ]
end
function rank.datet(typ)
    return DATET[typ]
end

local function curkey(typ, subt)
    return typ..':'..subt
end

local function lastdatekey(typ, subt, now)
    local last
    if subt=='day' then
        last=util.lastdaybase(now)
    elseif subt=='week' then
        last=util.lastweekbase(now)
    elseif subt=='month' then
        last=util.lastmonthbase(now)
    elseif subt=='total' then
        last=util.lastmonthbase(now)
    end
    if last then
        last = os.date('%Y%m%d', last)
        return rank.curkey(typ, subt)..':'..last, last
    end
end

local function enc_power(v1,v2)
    return (v1<<8) | v2
end
local function dec_power(score)
    return (score>>8)&0xff, score&0xff
end

local function rankscore(key, roleid)
    local rs= {rank=0, duanwei=0,star=0}
    local r = myredis.zrevrank(key, roleid)
    if r then
        rs.rank=r+1
    end
    local r = myredis.zscore(key, roleid)
    if r then
        rs.duanwei, rs.star = dec_power(r)
    end
    return rs
end

function rank.getseasonrank(roleid)
    local typ = 'power'
    local subt = 'month'
    local now = shaco.now()//1000
    local key1, last1 = lastdatekey(typ, subt, now)
    local key2, last2 = lastdatekey(typ, subt, last1)
    local key3, last3 = lastdatekey(typ, subt, last2)

    local t = {}
    t[#t+1]= rankscore(key1, roleid)
    t[#t+1]= rankscore(key2, roleid)
    t[#t+1]= rankscore(key3, roleid)
    return t
end

function rank.setpower(roleid, v1, v2)
    local score = enc_power(v1,v2)
    rank.setscore(roleid, 'power', score)
end

function rank.getpower(roleid)
    local score = rank.getscore(roleid, 'power')
    if score then
        return dec_power(score)
    else 
        return 0, 0
    end
end

function rank.getscore(roleid, typ)
    local key = curkey(typ, 'day')
    return tonumber(myredis.zscore(key, roleid))
end

function rank.setscore(roleid, typ, score)
    for _, v in ipairs(DATET) do
        local key = curkey(typ, v)
        myredis.zadd(key, score, roleid)
        myredis.zremrangebyrank(key, MAX_RANK, -1)
    end
end

function rank.addscore(roleid, typ, score)
    for _, v in ipairs(DATET) do
        local key = curkey(typ, v)
        myredis.zincrby(key, score, roleid)
        myredis.zremrangebyrank(key, MAX_RANK, -1)
    end
end

local function reset(typ)
    local now = shaco.now()//1000
    local key, last
 
    key=curkey(typ, 'day')
    last=lastdatekey(typ, 'day', now)
    if not myredis.exists(last) then
        myredis.backupkey(key, last)
    end

    key=curkey(typ, 'week')
    last=lastdatekey(typ, 'week', now)
    if not myredis.exists(last) then
        myredis.backupkey(key, last)
    end

    key=curkey(typ, 'month')
    last=lastdatekey(typ, 'month', now)
    if not myredis.exists(last) then
        myredis.backupkey(key, last)
    end
end

local function resetall()
    for _, v in ipairs(RANKT) do
        reset(v)
    end
end

function rank.update(now, daychanged)
    if daychanged then
        resetall()
    end
end

function rank.init()
    local now = shaco.now()//1000
    local openbase  = util.daybase(ctx.server_opentime)
    local todaybase = util.daybase(now)
    if openbase < todaybase then
        resetall()
    end
end

rank.curkey = curkey
rank.lastdatekey = lastdatekey
rank.MAX_RANK = MAX_RANK

return rank
