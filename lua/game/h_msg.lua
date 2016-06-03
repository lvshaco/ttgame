local shaco = require "shaco"
local myredis = require "myredis"
local cache = require "cache"
local pb = require "protobuf"
local friend = require "friend"
local tbl = require "tbl"
local sfmt = string.format

local REQ = {}

local function build_msg_info(ri, mb, cnt)
    return {
        roleid=ri.roleid,
        name=ri.name,
        icon=ri.icon,
        sex=ri.sex,
        id=mb.id,
        createtime=mb.createtime,
        content=mb.content,
        likecnt=cnt,
    }
end

REQ[IDUM_SendMsg] = function(ur, v)
    if #v.content > 38*3 then
        return SERR_Arg
    end
    local targetid = v.roleid
    if not friend.has(ur, targetid) then
        return SERR_Notfriend
    end
    local time = shaco.now()//1000
    local id=myredis.incr("msgid:"..targetid)
    local mb = {
        roleid=ur.info.roleid,
        id=id,
        createtime=time,
        content=v.content,
    }
    shaco.trace(tbl(mb, "SendMsg"))
    local mb=pb.encode("msg_base", mb)
    local key="msg:"..targetid
    myredis.set(key..":"..id, mb)
    myredis.rpush(key, id)
    return SERR_OK
end

REQ[IDUM_LikeMsg] = function(ur, v)
    local targetid = v.roleid
    if not friend.has(ur, targetid) then
        return SERR_Notfriend
    end
    local myid = ur.info.roleid
    local id = v.msgid
    local key="msg:"..targetid
    -- query msg
    local mb=myredis.get(key..":"..id)
    if not mb then
        return SERR_Arg
    end
    local likekey = "msglike:"..targetid
    local likeidkey = likekey..":"..id
    local up
    -- update like member
    if v.set ==1 then
        if myredis.sadd(likeidkey, myid) ~= 1 then
            return SERR_Arg
        end
        up=1
    else
        if myredis.srem(likeidkey, myid) ~= 1 then
            return SERR_Arg
        end
        up=-1
    end
    -- update like rank
    myredis.zincrby(likekey, up, id)
    return SERR_OK
end

local function query_msg(key, likekey, id)
    local mb = myredis.get(key..":"..id)
    mb = pb.decode("msg_base", mb)
    local ri = cache.query(mb.roleid)
    if not ri then
        return {}
    end
    local cnt =myredis.zscore(likekey, id)
    return build_msg_info(ri,mb,tonumber(cnt))
end

REQ[IDUM_GetTopMsg] = function(ur, v)
    local targetid = v.roleid
    if not friend.has(ur, targetid) then
        return SERR_Notfriend
    end
    local key = "msg:"..targetid
    local likekey = "msglike:"..targetid
    local top = myredis.zrevrange(likekey, 0, 2)
    local l = {}
    for _, id in ipairs(top) do
        l[#l+1] = query_msg(key, likekey, id)
    end
    shaco.trace(tbl(l, 'TopMsg'))
    ur:send(IDUM_TopMsg, {
        roleid=targetid,
        list=l})
end

REQ[IDUM_GetMsg] = function(ur, v)
    local targetid = v.roleid
    if not friend.has(ur, targetid) then
        return SERR_Notfriend
    end
    local key = "msg:"..targetid
    local likekey = "msglike:"..targetid
    local ids=myredis.lrange(key, v.range1, v.range2)
    local l = {}
    for _,id in ipairs(ids) do
        l[#l+1] = query_msg(key, likekey, id)
    end
    shaco.trace(tbl(l, 'GetMsg'))
    ur:send(IDUM_MsgList, {
        roleid=targetid,
        range1=v.range1,
        range2=v.range2,
        list=l})
end

return REQ
