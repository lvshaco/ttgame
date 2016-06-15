local shaco = require "shaco"
local pb = require "protobuf"
local myredis = require "myredis"
local userpool = require "userpool"

local cache = {}

function cache.query(roleid, name)
    local ur
    roleid = roleid or 0
    if roleid > 0 then
        ur = userpool.find_byid(roleid)
    else
        ur = userpool.find_byname(name)
        if not ur then
            local id = tonumber(name)
            if id then
                roleid = id
                ur = userpool.find_byid(roleid)
            end
        end
    end
    if ur then
        return ur.info, ur
    end
    if roleid <= 0 then
        roleid = myredis.get('rolen2id:'..name)
        roleid = tonumber(roleid)
        if not roleid then
            return nil, SERR_Norole
        end
    end
    local r = myredis.get('role:'..roleid)
    if not r then
        return nil, SERR_Norole
    end
    return pb.decode('role_info', r), nil
end

function cache.queryv(rl, func)
    local l = {}
    for _, v in ipairs(rl) do
        v = tonumber(v)
        local r = cache.query(v)
        if r then
            l[#l+1]=func(r)
        end
    end
    return l
end

function cache.checkname(name)
    if not name or name == "" then
        return SERR_InvalidName
    end
    name = string.match(name, "%g+.*%g+")
    if myredis.get('rolen2id:'..name) then
        return SERR_ExistName
    end
    if myredis.get('acc:'..name) then --帐号名和角色名一个概念了
        return SERR_ExistName
    end
    return SERR_OK
end

return cache
