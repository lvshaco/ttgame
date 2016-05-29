local shaco = require "shaco"
local nodepool = require "nodepool"
local userpool = require "userpool"
local ctx = require "ctx"
local tbl = require "tbl"
local relation = require "relation"

local nodelogic = {}

function nodelogic.init(conf)
end

function nodelogic.update()
end

function nodelogic.dispatch(connid, msgid, v)
    if msgid == 1 then
        local ok = nodepool.add(connid, v)
        ctx.send2n(connid, msgid, {code=ok and 0 or 1})
    elseif msgid == 2 then
        local node = nodepool.find(connid)
        assert(node)
        local serverid = node.serverid
        for k, v in ipairs(v) do
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
        local roles = v.roles
        local ranks = v.ranks
        for i=1, #ranks do
            ranks[i] = math.floor(ranks[i])
        end
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
                ur:db_flush()
                local l1 = relation.mhas(roleid, 'attention', ranks)
                local l2 = relation.mhas(roleid, 'like', ranks)
                print("role fightlikes:", roleid)
                print(tbl(l1))
                print(tbl(l2))
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
