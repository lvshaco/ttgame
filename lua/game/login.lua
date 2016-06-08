local shaco = require "shaco"
local socket = require "socket"
local pb = require "protobuf"
local userpool = require "userpool"
local user = require "user"
local mydb = require "mydb"
local myredis = require "myredis"
local gamestate = require "gamestate"
local tbl = require "tbl"

local login = {}

function login.login(connid, v)
    local acc = v.acc
    shaco.trace("user login ...", connid, acc)
    local ur 
    ur = userpool.find_byconnid(connid)
    if ur then
        error("conn has login:"..connid)
    end
    if #acc <= 0 then
        error("Invalid acc")
    end
    ur = userpool.find_byacc(acc)
    if ur then
        error("user has login:"..acc) -- undisplay character
    end
    ur = user.new(connid, gamestate.LOGIN)
    userpool.add_byconnid(connid, ur)
    
    ur.acc = acc
    userpool.add_byacc(acc, ur)

    local gmlevel
    local newrole
    local roleid
    local info
    local v = myredis.urcall(ur, 'get', 'acc:'..acc)
    if v then
        v = pb.decode('acc_info', v)
    end
    if not v then
        newrole = true
        roleid = myredis.urcall(ur, 'incr', 'role_uniqueid')
        gmlevel = 0
        v = {roleid=roleid, gmlevel=gmlevel}
        myredis.urcall(ur, 'set', 'acc:'..acc,
            pb.encode('acc_info', v))
        myredis.urcall(ur, 'set', 'role:'..roleid, 
            pb.encode('role_info', {}))
        shaco.trace("new role:", acc, roleid)
    else
        newrole = false
        roleid = v.roleid
        gmlevel = v.gmlevel
        info = myredis.urcall(ur, 'get', 'role:'..roleid)
        if info then
            info = pb.decode('role_info', info)
        end
        shaco.trace("load role:", acc, roleid)
    end
    local items
    if not newrole then
        items = myredis.urcall(ur, 'get', 'item:'..roleid)
        if items then
            items = pb.decode("item_list", items)
        end
    end
    gmlevel = 100 -- just for test use

    ur:init(roleid, gmlevel, info, items)
    
    userpool.add_byid(roleid, ur)
    local name = ur.info.name
    if name ~= "" then
        userpool.add_byname(name, ur)
    end
    ur.status = gamestate.GAME
    ur:entergame()
    shaco.trace("user login ok:", connid, acc, roleid)
end

return login
