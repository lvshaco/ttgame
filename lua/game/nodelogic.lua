local shaco = require "shaco"
local nodepool = require "nodepool"
local ctx = require "ctx"

local nodelogic = {}

function nodelogic.init(conf)
end

function nodelogic.update()
end

function nodelogic.dispatch(connid, msgid, v)
    if msgid == 1 then
        local ok = nodepool.add(connid, v)
        ctx.send2n(connid, msgid, {code=ok and 0 or 1})
    end
end

return nodelogic
