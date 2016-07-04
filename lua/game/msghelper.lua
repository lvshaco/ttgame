local MSG_RESNAME = require "msg_resname"
local pb = require "protobuf"

local msghelper = {}

function msghelper.packmsg(msgid, v)
    local name = MSG_RESNAME[msgid]
    assert(name)
    return msgid, pb.encode(name, v)
end

return msghelper
