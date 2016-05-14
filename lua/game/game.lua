local shaco = require "shaco"
local pb = require "protobuf"

require "enum"
require "struct"
require "msg_client"
require "msg_error"

local gate  = require "gate"
local logic = require "logic"
local mydb  = require "mydb"

shaco.start(function() 
    pb.register_file("../res/pb/enum.pb")
    pb.register_file("../res/pb/struct.pb")
    pb.register_file("../res/pb/msg_client.pb")
    
    local CMD = {}
    CMD.open = function(conf)
        mydb.init(conf.db)

        local function tick()
            shaco.timeout(2000, tick)
            logic.update()
        end
        shaco.timeout(2000, tick)

        gate.start(conf)
    end
    shaco.dispatch("lua", function(source, session, cmd, ...)
        local f = CMD[cmd]
        if f then
            shaco.ret(shaco.pack(f(...)))
        end
    end)    
end)
