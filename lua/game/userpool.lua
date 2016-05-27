local shaco = require "shaco"
local user = require "user"
local util = require "util"
local gamestate = require "gamestate"
local sfmt = string.format

-- user container
local conn2user = {}
local acc2user = {}
local oid2user = {} -- US_GAME state
--local name2user = {} -- US_GAME state
local userpool = {}

function userpool.find_byconnid(connid)
    return conn2user[connid]
end

function userpool.find_byid(roleid)
    return oid2user[roleid]
end

function userpool.find_byname(rolename)
    return name2user[rolename]
end

function userpool.find_byacc(acc)
    return acc2user[acc]
end

function userpool.isgaming(ur)
    return ur.status == gamestate.GAME
end

function userpool.add_byconnid(connid, ur)
    conn2user[connid] = ur
end

function userpool.add_byacc(acc, ur)
    acc2user[acc] = ur
end

function userpool.add_byname(name, ur)
    name2user[name] = ur
end

function userpool.add_byid(roleid, ur)
    oid2user[roleid] = ur
end

function userpool.logout(connid, err) 
    local ur = conn2user[connid]
    if ur then
        conn2user[connid] = nil
        acc2user[ur.acc] = nil
        --name2user[ur.base.name] = nil
        if ur.status >= gamestate.GAME then
            oid2user[ur.info.roleid] = nil
            ur:exitgame()
        end
        ur.status = gamestate.LOGOUT
        shaco.trace("user logout:", ur.connid, ur.acc, err)
    else
        shaco.trace("conn logout:", connid, err)
    end
end

function userpool.update(now, daychanged)
    for _, ur in pairs(oid2user) do
        ur:update(now)
        if daychanged then
            ur:onchangeday()
        end
    end
end

function userpool.foreach_conn(func)
    for _, ur in pairs(conn2user) do
        func(ur)
    end
end

function userpool.foreach_user(func)
    for _, ur in pairs(oid2user) do
        func(ur)
    end
end

return userpool
