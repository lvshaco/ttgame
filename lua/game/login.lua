local shaco = require "shaco"
local socket = require "socket"
local pb = require "protobuf"
local userpool = require "userpool"
local user = require "user"
local mydb = require "mydb"
local gamestate = require "gamestate"
local tbl = require "tbl"

local login = {}

function login.login(connid, v)
    local acc = v.acc
    shaco.trace("user login ...", connid, acc)
    local ur 
    ur = userpool.find_byconnid(connid)
    if ur then
        error("conn has login:", connid)
    end
    if #acc <= 0 then
        error("Invalid acc")
    end
    ur = userpool.find_byacc(acc)
    if ur then
        error("user has login:", acc) -- undisplay character
    end
    ur = user.new(connid, gamestate.LOGIN)
    userpool.add_byconnid(connid, ur)
    
    ur.acc = acc
    userpool.add_byacc(acc, ur)

    local v = mydb.urcall(ur, 'L.role', acc)

    local newrole 
    local gmlevel = 0
    local roleid
    local info
    if not v then
        newrole = true
        roleid = mydb.urcall(ur, "I.role", acc, gmlevel)
    else
        newrole = false
        if v.info then
            info = pb.decode("role_info", v.info)
        end
        roleid = v.roleid
        gmlevel = v.gmlevel
    end
    local items
    if not newrole then
        items = mydb.urcall(ur, "L.ex", "item", roleid)
        if items then
            items = pb.decode("item_list", items)
        end
    end
    local gmlevel = 100 -- just for test use

    ur:init(roleid, gmlevel, info, items)
    
    userpool.add_byid(roleid, ur)
    ur.status = gamestate.GAME
    ur:entergame()
    shaco.trace("user login ok:", connid, acc, ur.info.roleid)
end

return login
