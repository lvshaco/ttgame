local shaco = require "shaco"
local GM = require "gm"
local string = string
local table = table
local sfmt = string.format
local REQ = {}

REQ[IDUM_Gm] = function(ur, v)
	if ur.gmlevel <= 0 then
		return SERR_Illegal
	end
    local args = {}
    for v in string.gmatch(v.command, "[%w_]+") do
        table.insert(args, v)
    end
    local function has_privilege(ur, cmd)
        -- 最高权限不需要判断权限表，
        -- 这样最高权限指令也就不用加到权限表
        if ur.gmlevel == 100 then 
            return true
        end
        local pri = GM.__PRIVILEGE[cmd]
        if pri and pri <= ur.gmlevel then
            return true
        end
    end
    if #args >= 1 then
        local cmd = args[1]
        if cmd ~= "__PRIVILEGE" then
            if has_privilege(ur, cmd) then
                local f = GM[cmd]
                if f then
                    shaco.trace("Gm:", ur.info.roleid, v.command)
                    f(ur, select(2, table.unpack(args)))
                end
            end
        end
    end
    return SERR_OK
end

return REQ
