local shaco = require "shaco"
local tbl = require "tbl"
local tpshop = require "__tpshop"

local REQ = {}

REQ[IDUM_ReqShop] = function(ur, v)
    local items = {}
    for k, v in pairs(tpshop) do
        items[#items+1] = {
            tpltid = v.id,
        }
    end
    shaco.trace(tbl(items, "shop"))
    ur:send(IDUM_Shop, {list=items})
end

REQ[IDUM_BuyItem] = function(ur, v)
    local id = v.id
    local tp = tpshop[id]
    if not tp then
        return SERR_Notplt
    end
    if tp.copper > 0 then
        if not ur:copper_enough(tp.copper) then
            return SERR_Nocopper
        end
    end
    if tp.gold > 0 then
        if not ur:gold_enough(tp.gold) then
            return SERR_Nogold
        end
    end
    if tp.copper then
        ur:copper_take(tp.copper)
    end
    if tp.gold > 0 then
        ur:gold_take(tp.gold)
    end
    ur.bag:add(id, 1)
    ur:refreshbag()
    ur:syncrole()
end

REQ[IDUM_UseItem] = function(ur, v)
end

return REQ
