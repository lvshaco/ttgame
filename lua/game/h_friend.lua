local shaco = require "shaco"
local pb = require "protobuf"
local myredis = require "myredis"
local cache = require "cache"
local tbl = require "tbl"
local friend = require "friend"

local REQ = {}

REQ[IDUM_GetFriend] = function(ur, v)
    local l1 = friend.getfris(ur)
    local l2 = friend.getfrisin(ur)
    ur:send(IDUM_Friends, {fris=l1, frisin=l2})
end

REQ[IDUM_InviteFriend] = function(ur, v)
    local roleid = v.roleid
    local err = friend.invite(ur, v.roleid)
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

return REQ
