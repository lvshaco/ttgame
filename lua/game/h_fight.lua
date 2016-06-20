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

local LIFE = {3,6,10,13,16,20,23,26,30,33}

REQ[IDUM_ReqLoginFight] = function(ur, v)
    if ur.fighting then
        return SERR_State
    end
    local serverid = v.serverid
    local connid = nodepool.find_byserverid(serverid)
    if not connid then
        return SERR_Arg
    end
    local mode = v.mode
    local life = 0
    local ticketcnt = 0
    if mode == 1 then
        ticketcnt = v.ticket_count
        if ticketcnt <=0 or ticketcnt >#LIFE then
            return SERR_Arg
        end
        if not ur.bag:has(1001, ticketcnt) then
            return SERR_Noticket
        end
        life = LIFE[ticketcnt]
    else
        mode = 0
    end
    
    ur.fighting = serverid
    local key = math.random(1000000, 2000000)
    local equips = ur.info.equips
    local r = noderpc.urcall(ur, connid, 10, {
        mode = mode,
        life = life,
        key = key,
        roleid = ur.info.roleid,
        sex = ur.info.sex,
        icon = ur.info.icon,
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

    if ticketcnt > 0 then -- take ticket
        ur.bag:remove(1001, ticketcnt)
        ur:refreshbag()
    end
    ur:send(IDUM_LoginFightKey, {serverid=serverid, key=key})
end

REQ[IDUM_ReqGameRecord] = function(ur, v)
    local tarid = v.roleid
    local l = fight.getlist(tarid)
    ur:send(IDUM_GameRecord, {list=l})
end

return REQ
