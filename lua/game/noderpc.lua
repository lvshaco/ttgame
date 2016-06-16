local shaco = require "shaco"
local ctx = require "ctx"
local gamestate = require "gamestate"
local tbl = require "tbl"

local noderpc = {}

local __pool = {}
local __resultok = {}
local __result = {}

local function wait(connid, msgid, v)
    local co = coroutine.running()
    assert(not shaco.iswait(co))

    local node = __pool[connid]
    if not node then
        node = {}
        __pool[connid] = node
    end
    local coq = node[msgid]
    if not coq then
        coq = {}
        node[msgid] = coq
    end
    ctx.send2n(connid, msgid, v)
    coq[#coq+1] = co
    shaco.wait()

    local ok = __resultok[co]
    local ret = __result[co]
    __resultok[co] = nil
    __result[co] = nil

    if ok then
        return ret
    else
        error(ret)
    end
end

local function wakeup(co, ok, ret)
    __resultok[co] = ok
    __result[co] = ret
    shaco.wakeup(co)
end

local function locateco(connid, msgid)
    local node = __pool[connid]
    if node then
        local coq = node[msgid]
        if coq then
            return table.remove(coq, 1)
        end
    end
end

function noderpc.call(connid, msgid, v)
    shaco.trace(tbl(v, "noderpc.call "..msgid))
    return wait(connid, msgid, v)
end

function noderpc.urcall(ur, connid, msgid, v)
    local ret
    local ok, err = xpcall(function()
        ret = noderpc.call(connid, msgid, v)
    end, debug.traceback)
    if not ok then
        shaco.error(err)
        ret = nil
    end
    if ur.status == gamestate.LOGOUT then
        error(ctx.error_logout)
    end
    return ret
end

function noderpc.dispatch(connid, msgid, v)
    local co = locateco(connid, msgid)
    if co then
        wakeup(co, true, v)
        return true
    end
end

function noderpc.error(connid, err)
    local node = __pool[connid]
    if node then
        for msgid, coq in pairs(node) do
            for _, co in ipairs(coq) do
                wakeup(co, false, err)
            end
        end
    end
end

return noderpc
