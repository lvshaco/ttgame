local shaco = require "shaco"
local pb = require "protobuf"

require "enum"
require "struct"
require "msg_client"
require "msg_error"

local node  = require "node"
local gate  = require "gate"
local logic = require "logic"
local nodelogic = require "nodelogic"

shaco.start(function() 
    pb.register_file("../res/pb/enum.pb")
    pb.register_file("../res/pb/struct.pb")
    pb.register_file("../res/pb/msg_client.pb")
    
    local CMD = {}
    CMD.open = function(conf)
        nodelogic.init(conf)
        logic.init(conf)

        local intv = logic.interval
        local function tick()
            shaco.timeout(intv, tick)
            nodelogic.update()
            logic.update()
        end
        shaco.timeout(intv, tick)

        node.start(conf)
        gate.start(conf)
    end
    shaco.dispatch("lua", function(source, session, cmd, ...)
        local f = CMD[cmd]
        if f then
            shaco.ret(shaco.pack(f(...)))
        end
    end)    
end)
