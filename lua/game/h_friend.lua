local shaco = require "shaco"
local pb = require "protobuf"
local myredis = require "myredis"
local cache = require "cache"
local tbl = require "tbl"
local friend = require "friend"

local REQ = {}

REQ[IDUM_GetFriend] = function(ur, v)
    local typ = v.type
    local l
    if typ==1 then
        l=friend.getfris(ur)
    elseif typ==2 then
        l=friend.getfrisin(ur)
    elseif typ==3 then
        l=friend.getblacks(ur)
    elseif typ==4 then
        l=friend.getopponents(ur)
    end
    if not l then
        return SERR_Arg
    end
    ur:send(IDUM_Friends, {type=typ, list=l})
end

REQ[IDUM_InviteFriend] = function(ur, v)
    local roleid = v.roleid
    local err = friend.invite(ur, v.roleid, v.name)
    return err or SERR_OK
end

REQ[IDUM_ResponseInvite] = function(ur, v)
    local err
    if v.ok ==1 then
        err = friend.accept(ur, v.roleid)
    else
        err = friend.refuse(ur, v.roleid)
    end
    return err or SERR_OK
end

REQ[IDUM_ToBlack] = function(ur, v)
    local roleid = v.roleid
    return friend.toblack(ur, roleid)
end

return REQ
