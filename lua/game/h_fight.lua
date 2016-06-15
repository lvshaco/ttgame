local shaco = require "shaco"
local ctx = require "ctx"
local nodepool = require "nodepool"
local noderpc = require "noderpc"
local myredis = require "myredis"
local fight = require "fight"

local REQ = {}

REQ[IDUM_ReqServerList] = function(ur)
    local list = {}
    nodepool.foreach(function(v)
        list[#list+1] =v
    end)
    ur:send(IDUM_ServerList, {list = list})
end

REQ[IDUM_ReqLoginFight] = function(ur, v)
    if ur.fighting then
        return SERR_State
    end
    local serverid = v.serverid
    local connid = nodepool.find_byserverid(serverid)
    if not connid then
        return SERR_Arg
    end

    ur.fighting = serverid
    local key = math.random(1000000, 2000000)
    local equips = ur.info.equips
    local r = noderpc.urcall(ur, connid, 10, {
        key = key,
        roleid = ur.info.roleid,
        sex = ur.info.sex,
        province = ur.info.province,
        city = ur.info.city,
        heroid = ur.info.heroid,
        herolevel = ur.info.herolevel,
        guanghuan= equips[1].tpltid,
        baozi = equips[2].tpltid,
        canying = equips[3].tpltid,
        huahuan = equips[4].tpltid,
    })
    if not r then
        ur.fighting = false
        return SERR_Remote
    end
    if r.code ~= 0 then
        if r.code ~= 1 then
            ur.fighting = false
            shaco.error("Login fight return code:", r.code)
            return SERR_Remote
        else
            shaco.trace("Login fight return exist")
        end
    end

    ur:send(IDUM_LoginFightKey, {serverid=serverid, key=key})
end

REQ[IDUM_ReqGameRecord] = function(ur, v)
    local tarid = v.roleid
    local l = fight.getlist(tarid)
    ur:send(IDUM_GameRecord, {list=l})
end

return REQ
