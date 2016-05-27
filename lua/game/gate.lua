local shaco = require "shaco"
local socket = require "socket"
local websocket = require "websocket"
local pb = require "protobuf"
local MSG_REQNAME = require "msg_reqname"
local sunpack = string.unpack
local ssub = string.sub
local traceback = debug.traceback

local logic = require "logic"
local userpool = require "userpool"
local ctx = require "ctx"
ctx.send2c = function(id, data)
    websocket.send(id, data)
end
ctx.logout = function(id, err)
    userpool.logout(id, err)
    socket.close(id)
    shaco.trace("Conn disconnect:", id, err)
end
local logout = ctx.logout

local gate = {}

function gate.start(conf)
    local host = conf.host
    assert(socket.listen(host, function(id, addr)
        local function __handle(id, data)
            assert(#data >= 2, "Invalid msg length")
            local msgid, pos = sunpack("<I2", data)
            assert(msgid >= IDUM_GATEB and msgid <= IDUM_GATEE, "Out msg id")
            data = ssub(data, pos)
            shaco.debug("Msg:", id, msgid, #data)
            local v = pb.decode(MSG_REQNAME[msgid], data)
            shaco.fork(logic.dispatch, id, msgid, v)
        end
        local ok, err = pcall(function() -- todo replace to pcall
            shaco.trace("New conn:", id, addr)
            socket.start(id)
            socket.readon(id)
            websocket.accept(id)
            while true do
                local data, typ = websocket.read(id)
                if typ == "close" then
                    logout(id, "websocket close")
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
    shaco.info("Listen on: "..host)
end

return gate
