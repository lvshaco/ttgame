local shaco = require "shaco"
local tbl = require "tbl"
local tpcompose = require "__tpcompose"

local REQ = {}

REQ[IDUM_HeroLevelup] = function(ur)
    local info = ur.info
    local heroid = info.heroid
    local level = info.herolevel
    if heroid == 0 then
        heroid = 1
        level = 0
    end
    if level >= 5 then -- [0,5]
        heroid = heroid + 1
        level = 0
    else
        level = level+1
    end
    local tps = tpcompose[heroid]
    if not tps then
        return SERR_Notplt
    end
    local tp = tps[level+1]
    if not tp then
        return SERR_Notplt
    end

    local bag = ur.bag 
    for i=1, 4 do
        local id = tp['matid'..i]
        local cnt = tp['matn'..i]
        if id > 0 and cnt > 0 then
            if not bag:has(id, cnt) then
                return SERR_Nomat
            end
        end
    end
    for i=1, 4 do
        local id = tp['matid'..i]
        local cnt = tp['matn'..i]
        if id > 0 and cnt > 0 then
            bag:remove(id, cnt)
        end
    end
    info.heroid = heroid
    info.herolevel =level 
    
    ur:db_tagdirty(ur.DB_ROLE)
    ur:refreshbag()

    ur:send(IDUM_Hero, {heroid=heroid, herolevel=level})
end

return REQ
