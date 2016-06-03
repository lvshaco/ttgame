local shaco = require "shaco"
local tbl = require "tbl"
local myredis = require "myredis"
local cache = require "cache"

local friend = {}

local function build_info(info)
    return {
        roleid=info.roleid,
        name=info.name,
        icon=info.icon,
        sex=info.sex,
    }
end

function friend.getfris(ur)
    local myid = ur.info.roleid
    local l = myredis.smembers('friends:'..myid)
    return cache.queryv(l, build_info)
end

function friend.getfrisin(ur)
    local myid = ur.info.roleid
    local l = myredis.smembers('friendsin:'..myid)
    return cache.queryv(l, build_info)
end

function friend.has(ur, roleid)
    local myid = ur.info.roleid
    return myredis.urcall(ur, 'sismember', 'friends:'..myid, roleid)
end

function friend.hasinviteout(ur, roleid)
    local myid = ur.info.roleid
    return myredis.urcall(ur, 'sismember', 'friendsout:'..myid, roleid)
end

function friend.hasinviteme(ur, roleid)
    local myid = ur.info.roleid
    return myredis.urcall(ur, 'sismember', 'friendsin:'..myid, roleid)
end

local function addoffline(myid, objid)
    myredis.sadd('friends:'..myid, objid)
    myredis.srem('friendsout:'..myid, objid)
    myredis.srem('friendsin:'..myid, objid)
end

local function addfriend(ur, objinfo, obj) 
    local myid = ur.info.roleid
    local objid = objinfo.roleid
    
    addoffline(myid, objid)
    ur:send(IDUM_AddFriend, { type=1, info=build_info(objinfo)})
    addoffline(objid, myid)
    if obj then
        obj:send(IDUM_AddFriend, { type=2, info=build_info(ur.info)})
    end
end

function friend.invite(ur, roleid)
    local objinfo, obj = cache.query(roleid)
    if not objinfo then
        return obj -- err
    end
    if friend.has(ur, roleid) then
        return SERR_Friendyet
    end
    if friend.hasinviteout(ur, roleid) then
        return SERR_HasInvite
    end
    local myid = ur.info.roleid
    if not friend.hasinviteme(ur, roleid) then
        myredis.sadd('friendsout:'..myid, roleid)
        myredis.sadd('friendsin:'..roleid, myid)
        ur:send(IDUM_AddInvite, { type=1, info=build_info(objinfo) })
        if obj then
            obj:send(IDUM_AddInvite, { type=2, info=build_info(ur.info) })
        end
        return SERR_OK
    else
        addfriend(ur, objinfo, obj)
    end
end

function friend.accept(ur, roleid)
    local objinfo, obj = cache.query(roleid)
    if not objinfo then
        return obj -- err
    end
    if not friend.hasinviteme(ur, roleid) then
        return SERR_State
    end
    addfriend(ur, objinfo, obj)
end

function friend.refuse(ur, roleid)
    local objinfo, obj = cache.query(roleid)
    if not objinfo then
        return obj -- err
    end
    if not friend.hasinviteme(ur, roleid) then
        return SERR_State
    end
    local myid = ur.info.roleid
    myredis.srem('friendsin:'..myid, roleid)
    ur:send(IDUM_DelInvite, { type=1, info=build_info(objinfo) })
    myredis.srem('friendsout:'..roleid, myid)
    if obj then
        obj:send(IDUM_DelInvite, { type=2, info=build_info(ur.info) })
    end
end

return friend
