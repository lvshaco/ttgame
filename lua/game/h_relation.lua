local shaco = require "shaco"
local pb = require "protobuf"
local myredis = require "myredis"
local cache = require "cache"
local tbl = require "tbl"
local rank = require "rank"

local REQ = {}

REQ[IDUM_ReqRole] = function(ur, v)
    local roleid = v.roleid
    local info, err = cache.query(roleid)
    if not info then
        return err
    end
    ur:send(IDUM_RoleInfo, {info=info})
end

REQ[IDUM_SetFocus] = function(ur, v)
    local myid = ur.info.roleid
    local targetid = v.roleid
    if targetid == myid then
        return SERR_Arg
    end
    local typ = v.type
    local now = shaco.now()//1000
    if v.set==1 then
        if typ==1 then -- 关注
            myredis.zadd('attention:'..myid, now, targetid)
            if myredis.zadd('fans:'..targetid, now, myid) == 1 then
                rank.addscore(targetid, 'fans', 1)
            end
            return SERR_OK
        elseif typ==2 then -- 喜欢
            myredis.zadd('like:'..myid, now, targetid)
            if myredis.zadd('belike:'..targetid, now, myid) == 1 then
                rank.addscore(targetid, 'belike', 1)
            end
            return SERR_OK
        end
    elseif v.set==0 then
        if typ==1 then
            myredis.zrem('attention:'..myid, targetid)
            if myredis.zrem('fans:'..targetid, myid) == 1 then
                rank.addscore(targetid, 'fans', -1)
            end
            return SERR_OK
        elseif typ==2 then
            myredis.zrem('like:'..myid, targetid)
            if myredis.zrem('belike:'..targetid, myid) == 1 then
                rank.addscore(targetid, 'belike', -1)
            end
            return SERR_OK
        end
    end
end

local function build_fans_info(a)
    return {
        roleid=a.roleid,
        name=a.name,
        icon=a.icon,
        sex=a.sex,
        count=0,
    }
end

REQ[IDUM_ReqFans] = function(ur, v)
    local myid = ur.info.roleid
    local vtyp = v.type
    local targetid = v.roleid
    local now = shaco.now()//1000
    local typ
    if vtyp==1 then --粉丝列表
        typ='fans:'
    elseif vtyp==2 then --喜欢我列表
        typ='belike:'
    end
    if not typ then
        return SERR_Arg
    end
    local r = myredis.zrange(typ..targetid, v.range1, v.range2)
    local l = {}
    for _, v in ipairs(r) do
        local a = cache.query(tonumber(v))
        a = a and build_fans_info(a) or {}
        a.count = myredis.zcard('belike:'..a.roleid)
        l[#l+1] = a
    end
    ur:send(IDUM_Fans, {list=l})
end

return REQ
