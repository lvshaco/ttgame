local shaco = require "shaco"
local nodepool = require "nodepool"
local ctx = require "ctx"
local tbl = require "tbl"

local nodelogic = {}

function nodelogic.init(conf)
end

function nodelogic.update()
end

function nodelogic.dispatch(connid, msgid, v)
    if msgid == 1 then
        local ok = nodepool.add(connid, v)
        ctx.send2n(connid, msgid, {code=ok and 0 or 1})
    elseif msgid == 11 then -- todo
        shaco.trace(tbl(v, "fightresult"))
        for k, v in pairs(v) do
            local ur = userpool.find_byid(v.roleid)
            if ur then
                ur:copper_got(v.copper)
                ur:addexp(v.exp)
                ur:addeat1(v.eat)
                ur:setmaxmass(v.mass)
                ur:syncrole()
                ur:db_flush()
            end
        end
    end
end

return nodelogic
