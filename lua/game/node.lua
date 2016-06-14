local shaco = require "shaco"
local socket = require "socket"
local websocket = require "websocket"
local sunpack = string.unpack
local ssub = string.sub
local traceback = debug.traceback
local cjson = require "cjson"
local tbl = require "tbl"

local noderpc = require "noderpc"
local nodelogic = require "nodelogic"
local nodepool = require "nodepool"
local ctx = require "ctx"
ctx.send2n = function(id, msgid, data)
    local msg = {
        id = msgid,
        body = data,
    }
    websocket.send(id, cjson.encode(msg))
end

local node = {}

local function logout(id, err)
    shaco.info("Node logout", id, err)
    socket.close(id)
    local v = nodepool.remove(id)
    if v then
        noderpc.error(id, err)
        nodelogic.error(v.serverid, err)
    end
end

function node.start(conf)
    local host = conf.node_host
    assert(socket.listen(host, function(id, addr)
        local function __handle(id, data)
            local msg = cjson.decode(data)
            shaco.trace(tbl(msg, "Node msg"))
            local msgid = msg.id
            local v = msg.body
            shaco.fork(function()
                if not noderpc.dispatch(id, msgid, v) then
                    nodelogic.dispatch(id, msgid, v)
                end
            end)
        end
        local ok, err = pcall(function() -- todo replace to pcall
            shaco.trace("New node:", id, addr)
            socket.start(id)
            socket.readon(id)
            websocket.accept(id)
            while true do
                local data, typ = websocket.read(id)
                if typ == "close" then
                    socket.close(id)
                    --logout(id, "websocket close")
                    break
                elseif typ == "data" then
                    __handle(id, data)
                end
            end
        end)--, debug.traceback)
        if not ok then
            logout(id, err)
        end
    end))
    shaco.info("Node Listen on: "..host)
end

return node
