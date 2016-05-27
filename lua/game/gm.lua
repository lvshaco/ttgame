local shaco = require "shaco"
--local itemop = require "itemop"
local tonumber = tonumber
local REQ = require "req"

local GM = {}
GM.__PRIVILEGE = {
    getcopper=2,
    getgold=2,
    addexp=2,
    setlevel=2,
    getitem=2,
}

GM.getcopper = function(ur, count)
    local count = tonumber(count)
    if not count then return end
    if ur:copper_got(count) ~= 0 then
        ur:syncrole()
    end
end

GM.getgold = function(ur, count)
    local count = tonumber(count)
    if not count then return end
    if ur:gold_got(count) ~= 0 then
        ur:syncrole()
    end
end

GM.addexp = function(ur, exp)
	local exp = floor(tonumber(exp))
    if not exp then return end
	ur:addexp(exp)
    ur:syncrole()
end

GM.setlevel = function(ur, level)
	local level = floor(tonumber(level))
    if not level then return end
	ur:setlevel(level)
    ur:syncrole()
end

GM.getitem = function(ur, id, count)
    local id = tonumber(id)
    local count  = tonumber(count)
    if not id or not count then return end
    if ur.bag:add(id, count) then
        ur:refreshbag()
    end
end

GM.fight = function(ur, id)
    id = tonumber(id) or 1
    return REQ[IDUM_ReqLoginFight](ur, {serverid=id})
end

GM.duanwei = function(ur, i)
    ur:setduanwei(tonumber(i))
end

return GM
