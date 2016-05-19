local shaco = require "shaco"
local tbl = require "tbl"

local nodepool = {}

local __conn2node = {}

function nodepool.add(connid, v)
    if not __conn2node[connid] then
        if nodepool.find_byserverid(v.serverid) then
            shaco.info("Node register fail, conflict serverid", tbl(v, v.serverid))
            return false
        end
        __conn2node[connid] = v
        shaco.info("Node register ok", connid, tbl(v, v.serverid))
        return true
    else 
        shaco.info("Node register fail, conflict connid", connid)
        return false
    end
end

function nodepool.remove(connid)
    local v = __conn2node[connid]
    if v then
        __conn2node[connid] = nil
        shaco.info("Node unregister", connid, tbl(v, v.serverid))
    end
end

function nodepool.find_byserverid(serverid)
    for id, v in pairs(__conn2node) do
        if v.serverid == serverid then
            return id, v
        end
    end
end

function nodepool.foreach(func)
    for id, v in pairs(__conn2node) do
        func(v)
    end
end

return nodepool
