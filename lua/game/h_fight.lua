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
    if ur.fightenter then
        return SERR_State
    end
    local r
    local serverid
    local mode
    local ticketcnt
    local fighting = ur.fighting
    if not fighting then
        serverid = v.serverid
        local connid = nodepool.find_byserverid(serverid)
        if not connid then
            return SERR_Arg
        end
        mode = v.mode
        local life = 0
        ticketcnt = 0
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
        local key = math.random(1000000, 2000000)
        local equips = ur.info.equips
        r = noderpc.urcall(ur, connid, 10, {
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
            name = ur.info.name,
        })
    else
        serverid = fighting.serverid
        local connid = nodepool.find_byserverid(serverid);
        if not connid then
            return SERR_FightGone
        end
        r = noderpc.urcall(ur, connid, 10, {
            roleid = ur.info.roleid,
            reenter = true,
        })
    end 
    if not r then
        ur.fightenter = false
        return SERR_Remote
    end
    local code = r.code
    if code == 0 then
    elseif code == 1 then
        shaco.trace("Login fight return exist")
    elseif code == 2 then
        ur.fightenter = false
        ur.fighting = false
        return SERR_ReenterFight -- client recv this, should re request fight normal
    else
        ur.fightenter = false
        shaco.error("Login fight return code:", r.code)
        return SERR_Remote
    end
    if not fighting then
        ur.fighting = {
            serverid = serverid,
            mode = mode,
        }
        if ticketcnt > 0 then -- take ticket
            ur.bag:remove(1001, ticketcnt)
            ur:refreshbag(4)
        end
    end
    ur:send(IDUM_LoginFightKey, {serverid=serverid, key=r.key})
end

REQ[IDUM_ReqGameRecord] = function(ur, v)
    local tarid = v.roleid
    local l = fight.getlist(tarid)
    ur:send(IDUM_GameRecord, {list=l})
end

REQ[IDUM_ExitFight] = function(ur, v)
    if not ur.fighting then
        return SERR_State
    end
    local connid = nodepool.find_byserverid(ur.fighting.serverid)
    if not connid then
        return SERR_Arg
    end
    local r = noderpc.urcall(ur, connid, 12, {
        roleid = ur.info.roleid,
    })
    if not r then
        return SERR_ExitFight
    end
    ur.fighting = false
    shaco.trace("ExitFight:", r.code);
    return SERR_OK
end

return REQ
