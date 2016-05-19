local shaco = require "shaco"
local ctx = require "ctx"
local nodepool = require "nodepool"
local noderpc = require "noderpc"

local REQ = {}

REQ[IDUM_ReqServerList] = function(ur)
    local list = {}
    nodepool.foreach(function(v)
        list[#list+1] =v
    end)
    ur:send(IDUM_ServerList, {list = list})
end

REQ[IDUM_ReqLoginFight] = function(ur, v)
    print("======")
    if ur.fighting then
        return SERR_State
    end
    print("======2")
    local serverid = v.serverid
    local connid = nodepool.find_byserverid(serverid)
    if not connid then
        return SERR_Arg
    end

    print("======3")
    ur.fighting = true
    local key = math.random(1000000, 2000000)
    local r = noderpc.urcall(ur, connid, 10, {
        key = key,
        roleid = ur.info.roleid,
    })
    print("======4")
    if not r then
        ur.fighting = false
        return SERR_Remote
    end
    print("======5")
    if r.code ~= 0 then
        ur.fighting = false
        shaco.error("Login fight return code:", r.code)
        return SERR_Remote
    end

    print("======6")
    ur:send(IDUM_LoginFightKey, {serverid=serverid, key=key})
end

return REQ
