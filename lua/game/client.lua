local shaco = require "shaco"
local socket = require "socket"
local websocket = require "websocket"
local linenoise = require "linenoise"
local pb = require "protobuf"
local tbl = require "tbl"
local MRES = require "msg_resname"
local MREQ = require "msg_reqname"
local sunpack = string.unpack
local spack = string.pack

local TRACE = shaco.getenv("trace")

local function info_trace(msgid, tag, r)
    if not TRACE then return end
    if tag == "<" then
        print(string.format("%s--[%s:%d]", tag, MREQ[msgid], msgid))
    elseif tag == ">" then
        print(string.format("--%s[%s:%d]", tag, MRES[msgid], msgid))
    else
        print(string.format("  %s[%s:%d]", tag, MRES[msgid], msgid))
    end
    if r then
        print(tbl(r))
    end
end

local function responseid(reqid)
    if reqid == IDUM_Login then
        return IDUM_EnterGame
    elseif reqid == IDUM_ReqServerList then
        return IDUM_ServerList
    elseif reqid == IDUM_ReqLoginFight then
        return IDUM_LoginFightKey
    else
        return IDUM_Response
    end
end

local function encode(mid, v)
    print(mid, MREQ[mid])
    local s = pb.encode(MREQ[mid], v)
    return string.pack("<I2", mid)..s
end

local function decode(s)
    local mid, pos = string.unpack("<I2", s)
    return mid, pb.decode(MRES[mid], string.sub(s,pos))
end

local function read(id, resid)
    while true do
        local s = websocket.read(id)
        local mid, r = decode(s)
        if mid == resid then
            info_trace(mid, ">", r)
            return r
        end
        info_trace(mid, "*", r)
    end
end

local function rpc(id, reqid, v)
    info_trace(reqid, "<")
    local resid = responseid(reqid)
    websocket.send(id, encode(reqid, v)) 
    return read(id, resid)
end

local function fight(s, roleid, key)
    local id = websocket.connect(s.serverip..":"..s.serverport, '/')
    -- EnterBoard
    websocket.send(id, spack("<I1I4I1I4I4s1", 255, 1, 0, roleid, key, "R"))
    shaco.fork(function()
        while true do
            websocket.read(id)
        end
    end)
end

local function create_robot(host, account, index, rolename) 
    local id = websocket.connect(host, "/")
    local v = rpc(id, IDUM_Login, {acc=account, passwd="123456"})
    local roleid = v.info.roleid
    local v = rpc(id, IDUM_ReqServerList,{})
    if #v.list > 0 then
        local s = v.list[1]
        local v = rpc(id, IDUM_ReqLoginFight, {serverid=s.serverid})
        assert(v.serverid == s.serverid)
        fight(s, roleid, v.key)
    end
    return id
end

shaco.start(function()
    pb.register_file("../res/pb/enum.pb")
    pb.register_file("../res/pb/struct.pb")
    pb.register_file("../res/pb/msg_client.pb")

    local host = assert(shaco.getenv("host"))
    local robotid = tonumber(shaco.getenv("robotid"))
    local account  = shaco.getenv("acc") or string.format("robot_acc_%u", robotid)
    local rolename = shaco.getenv("name") or string.format("robot_name_%u", robotid)
    local index = tonumber(shaco.getenv("index")) or 0
    local id = create_robot(host, account, index, rolename)

    local history_file = ".gmrobot.history"
    linenoise.loadhistory(history_file)

    while true do
        local s = linenoise.read("> ",
            function() return io.stdin:read(1) end,
            function() return io.stdin:read("l") end)
        if s == nil then
            linenoise.savehistory(history_file)
            os.exit(1)
        end
        s = string.match(s, "^%s*(.-)%s*$")
        if s ~= "" then
            rpc(id, IDUM_Gm, {command=s})
        end
    end
    linenoise.savehistory(history_file)
end)
