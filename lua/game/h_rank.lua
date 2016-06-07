local shaco = require "shaco"
local pb = require "protobuf"
local myredis = require "myredis"
local cache = require "cache"
local rank = require "rank"
local tbl = require "tbl"

local REQ = {}


local function build_rank_info(a, rank)
    return {
        roleid=a.roleid,
        name=a.name,
        icon=a.icon,
        sex=a.sex,
        rank=rank,
    }
end

REQ[IDUM_ReqRanks] = function(ur, v)
    local typ = rank.rankt(v.type)
    if not typ then
        return SERR_Arg
    end
    local subt = rank.datet(v.subtype)
    if not subt then
        return SERR_Arg
    end
    local rdkey = rank.curkey(typ, subt)
    local now = shaco.now()//1000
    local last = rank.lastdatekey(typ, subt, now)
    
    local r = myredis.zrevrange(rdkey, 0, 20-1, 'withscores')
    local l = {}
    for i=1, #r//2 do
        local roleid = tonumber(r[i*2-1])
        local score = tonumber(r[i*2])
        local a = cache.query(roleid)
        if a then
            a = build_rank_info(a, i)
            a.value1=score
            if last then
                a.value2=myredis.zscore(last, roleid)
            end
        else
            a = {}
        end
        l[#l+1] = a
    end
    ur:send(IDUM_Ranks, {list=l})
end

REQ[IDUM_ReqSeasonRank] = function(ur, v)
    local tarid = v.roleid
    local t = rank.getseasonrank(tarid)
    ur:send(IDUM_SeasonRank, {list=t})
end

return REQ
