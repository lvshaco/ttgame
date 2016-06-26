local shaco = require "shaco"
local tbl = require "tbl"
local tpshop = require "__tpshop"
local tpitem = require "__tpitem"

local REQ = {}

REQ[IDUM_ReqShop] = function(ur, v)
    local items = {}
    for k, v in pairs(tpshop) do
        items[#items+1] = {
            tpltid = v.id,
        }
    end
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
    return SERR_OK
end

local function rollitem(typ)
  local f_rate = 'boxrate'..typ
  local f_cnt  = 'boxcnt'..typ
  local allrate = 0
  for k, v in pairs(tpitem) do
    if v.type==4 then -- 材料
      allrate = allrate + v[f_rate]
    end
  end
  allrate = math.floor(allrate*10)
  local rate = math.random(1,allrate)/10
  local cur_rate = 0
  for k, v in pairs(tpitem) do
    if v.type==4 then
      cur_rate = cur_rate + v[f_rate]
      if cur_rate >= rate then
        local cnt = v[f_cnt]
        if #cnt == 1 then
          return {v.id, math.floor(cnt[1])}
        else
          return {v.id, math.random(math.floor(cnt[1]), math.floor(cnt[2]))}
        end
      end
    end
  end
  error(string.format('rollitem error: %s, %s, %s', f_rate, allrate, rate))
end

local function openbox(ur, item)
  local id = item.info.tpltid
  local typ 
  if id == 701 then -- 701
    typ=1 
  else -- 702
    typ=2
  end
  if typ ~= 1 and
     typ ~= 2 then
    return SERR_Arg 
  end
  local take
  local typcnt1, typcnt2
  if typ==1 then
    take=10
    typcnt1=1
    typcnt2=3
  else
    take=20
    typcnt1=2
    typcnt2=4
  end
  --if not ur:gold_enough(take) then
  --  return SERR_Nogold
  --end
  local ol = {}
  local typcnt = math.random(typcnt1, typcnt2)
  for i=1, typcnt do
    table.insert(ol, rollitem(typ))
  end
  shaco.trace(tbl(ol, "openbox_list"))
  for _, v in ipairs(ol) do
    ur.bag:add(v[1], v[2])
  end
  ur.bag:remove(id, 1)
  --ur:gold_take(take)
  --ur:syncrole()
  ur:refreshbag()
  return SERR_OK
end


local function typ2field(typ)
  if typ==2 then -- 光环
    return 1
  elseif typ==3 then -- 孢子
    return 2
  elseif typ==5 then -- 残影
    return 3
  elseif typ==6 then -- 花环
    return 4
  end
end

local function unequip(ur, typ)
  local field = typ2field(typ)
  if not field then
    return SERR_Arg
  end
  local item = ur.info.equips[field]
  if item.tpltid == 0 then
    return SERR_Arg
  end
  ur.bag:replace(item)
  item.tpltid = 0
end

REQ[IDUM_UseItem] = function(ur, v)
  local id = v.id
  local item = ur.bag:get(id)
  if not item then
    return SERR_Arg
  end
  local typ = item.tp.type
  if typ==7 then -- 宝箱
    return openbox(ur, item)
  end
  local field = typ2field(typ)
  if not field then
    return SERR_Arg
  end
  local old = ur.info.equips[field]
  if old.tpltid ~= 0 then
    unequip(ur, typ)
  end
  local iteminfo = ur.bag:remove(id, item.info.stack, true)
  ur.info.equips[field] = iteminfo
  ur:db_tagdirty(ur.DB_ROLE)
  ur:refreshbag()
  ur:send(IDUM_EquipUpdate, {itemtype=typ, id=id})
  return SERR_OK
end

REQ[IDUM_UnequipItem] = function(ur, v)
  local typ = v.itemtype
  local err = unequip(ur, typ)
  if err then
    return err
  end
  ur:db_tagdirty(ur.DB_ROLE)
  ur:refreshbag()
  ur:send(IDUM_EquipUpdate, {itemtype=typ, id=0})
end

return REQ
