local shaco = require "shaco"
local nodepool = require "nodepool"
local userpool = require "userpool"
local ctx = require "ctx"
local tbl = require "tbl"
local relation = require "relation"
local fight = require "fight"

local nodelogic = {}

function nodelogic.init(conf)
end

function nodelogic.update()
end

function nodelogic.dispatch(connid, msgid, msg)
    if msgid == 1 then
        local ok = nodepool.add(connid, msg)
        ctx.send2n(connid, msgid, {code=ok and 0 or 1})
    elseif msgid == 2 then
        local node = nodepool.find(connid)
        assert(node)
        local serverid = node.serverid
        for k, v in ipairs(msg) do
            local ur = userpool.find_byid(v.roleid)
            if ur then
                if not ur.fighting then
                    ur.fighting = serverid
                else
                    -- todo
                end
            end
        end
    elseif msgid == 11 then 
        local roles = msg.roles
        local ranks = msg.ranks
        for i=1, #ranks do
            ranks[i] = math.floor(ranks[i])
        end
        local now = shaco.now()//1000
        for k, v in ipairs(roles) do
            local roleid = math.floor(v.roleid)
            local ur = userpool.find_byid(roleid)
            if ur and ur.fighting then
                ur.fighting = false
                ur:copper_got(v.copper)
                ur:addexp(v.exp)
                ur:addeat1(v.eat)
                ur:setmaxmass(v.mass)
                ur:setduanwei(v.rank)
                ur:syncrole()
                if v.box1>0 then
                  ur.bag:add(701, v.box1)
                end
                if v.box2>0 then
                  ur.bag:add(702, v.box2)
                end
                ur:refreshbag()
                ur:db_flush()
                fight.record(roleid, {
                    roleid=roleid,
                    nickname=v.name, --
                    icon=ur.info.icon,
                    sex=ur.info.sex,
                    time=now, --
                    rank=v.rank,
                    mass=v.mass,
                    eat=v.eat,
                    live=v.live, --
                    copper=v.copper,
                })
                local l1 = relation.mhas(roleid, 'attention', ranks)
                local l2 = relation.mhas(roleid, 'like', ranks)
                ur:send(IDUM_FightLikes, {attentions=l1, likes=l2})
            end
        end
        for k, v in ipairs(ranks) do
        end
    end
end

function nodelogic.error(serverid, err)
    userpool.foreach_user(function(ur)
        if ur.fighting == serverid then
            ur.fighting = false
        end
    end)
end

return nodelogic
