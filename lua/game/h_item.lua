local shaco = require "shaco"
local itemop = require "itemop"
local tpitem = require "__tpitem"
local tbl = require "tbl"
local tpgamedata = require "__tpgamedata"
local tpgift_treasure = require "__tpgift_treasure"
local card_container = require "card_container"
local club = require "club"
local sfmt = string.format
local gift_reward = require "gift_reward"
local tpgem = require "__tpgem"
local broad_cast = require "broad_cast"
local task = require "task"
local equip_attributes = require "equip_attribute"
local REQ = {}

local function check_equip_task(ur,bag)
	local blue = 0
	local violet = 0 
	local orange = 0
	local max_cnt = EQUIP_MAX
	for i =2,max_cnt do
		local item = bag:get(i)
		if item then
			local tp = tpitem[item.tpltid]
			if tp.quality >= CARD_BLUE then
				blue = blue + 1
			end
			if tp.quality >= CARD_VIOLET then
				violet = violet + 1
			end
			if tp.quality >= CARD_ORANGE then
				orange = orange + 1
			end
		end
	end
	if blue == max_cnt -1 then
		task.set_task_progress(ur,10,1,0)
		task.refresh_toclient(ur, 10)
	end
	if violet == (max_cnt - 1) then
		task.set_task_progress(ur,11,1,0)
		task.refresh_toclient(ur, 11)
	end
	if orange == (max_cnt - 1) then
		task.set_task_progress(ur,12,1,0)
		task.refresh_toclient(ur, 12)
	end
end

REQ[IDUM_EQUIP] = function(ur, v)
    if v.bag_type ~= BAG_MAT then
        return SERR_PARAM
    end
    local bag1 = ur:getbag(v.bag_type)
    if not bag1 then
        return SERR_PARAM
    end
    local item = itemop.get(bag1,v.pos)
	if not item then
		return SERR_ITEM_NOT_EXIST
	end
    local tp = tpitem[item.tpltid]
    if not tp then
        return SERR_NOTPLT
    end
    -- tp.occup is binrary bit, autogen by excelto
	if tp.occup ~= 1 and (tp.occup >> ur.base.race) & 1 == 0 then
		return SERR_NOT_NEED_OCCUPATION
	end
    if tp.equipPart < EQUIP_WEAPON or tp.equipPart > EQUIP_BRACELET then
    	return SERR_PARAM
    end
    local bag2 = ur:getbag(BAG_EQUIP)
    if itemop.exchange(bag2,tp.equipPart,bag1,v.pos) then
        local unequip_item = itemop.get(bag1, v.pos)
        if unequip_item then
            ur.attribute.equip_attribute[tp.equipPart] = nil 
        end
        ur.attribute.equip_attribute[tp.equipPart] = equip_attributes.new(item.info,item.tpltid)
        ur:change_attribute()
        itemop.refresh(ur)
        ur:db_tagdirty(ur.DB_ITEM)
        check_equip_task(ur,bag2)
    end
end

REQ[IDUM_UNEQUIP] = function(ur, v)
	local bag1 = ur:getbag(v.bag_type)
    if not bag1 then
        return SERR_PARAM
    end
    local bag2 = ur:getbag(BAG_MAT)
	local item = itemop.get(bag1,v.pos)
    if not item then 
        return SERR_ITEM_NOT_EXIST 
    end 
    local tp = tpitem[item.tpltid] 
    if not tp then
        return SERR_NOTPLT
    end
    if itemop.move(bag1,v.pos,bag2) then
		ur.attribute.equip_attribute[v.pos] = nil
		ur:change_attribute()
    	itemop.refresh(ur)
        ur:db_tagdirty(ur.DB_ITEM)
    end
end

REQ[IDUM_ITEMSALE] = function(ur, v)
    local bag = ur:getbag(v.bag_type)
    if not bag then
        return SERR_PARAM
    end
    local up
    local got_money = 0
    for _, one in ipairs(v.posnumv) do
        local pos, count = one.int1, one.int2
        local item = itemop.get(bag, pos)
        if item then
            local tp = tpitem[item.tpltid]
            if tp then
                if count == 0 then
                    count = item.stack
                end
                local count = itemop.remove_bypos(bag, pos, count)
                if count > 0 then
                    got_money = got_money + tp.sellPrice*count
                    up = true
                end
            end
        end
    end
    if up then
        if got_money > 0 then
            ur:coin_got(got_money)
            ur:sync_role_data()
            ur:db_tagdirty(ur.DB_ROLE)
        end
        itemop.refresh(ur)
        ur:db_tagdirty(ur.DB_ITEM)
    end
end

REQ[IDUM_REQUSEITEM] = function(ur, v)
	local bag = ur:getbag(v.bag_type)
	 if not bag then
        return SERR_PARAM
    end
	local item = itemop.get(bag,v.pos)
	if not item then
		return SERR_ITEM_NOT_EXIST
	end
    if item.stack < v.item_cnt or v.item_cnt <= 0 then
        return SERR_ITEM_NOT_ENOUGH
    end
	local tp = tpitem[item.tpltid]
    if not tp then
        return SERR_NOTPLT
    end
	if tp.itemType == ITEM_CANUSE then
		if tp.affectType1 == AFFECT_HP then
			
		elseif tp.affectType1 == AFFECT_MP then
		
		elseif tp.affectType1 == AFFECT_PHYSICAL then
			if ur:physical_got(tp.affectValue1 * v.item_cnt) == 0 then
				return SERR_PHYSICAL_MAX
			end
		elseif tp.affectType1 == AFFECT_COIN then
			ur:coin_got(tp.affectValue1 * v.item_cnt)
		elseif tp.affectType1 == AFFECT_GOLD then
			ur:gold_got(tp.affectValue1 * v.item_cnt)
		elseif tp.affectType1 == AFFECT_BIND_GOLD then
		
		elseif tp.affectType1 == AFFECT_EXP then
			ur:addexp(tp.affectValue1 * v.item_cnt)
		end
		itemop.remove_bypos(bag, v.pos, v.item_cnt)
		ur:db_tagdirty(ur.DB_ROLE)
		ur:sync_role_data()
	elseif tp.itemType == ITEM_BAG then
        if #tp.items > 0 then
            if gift_reward.get_gift_reward(ur,tp.items,v.item_cnt,1) == 1 then
                return SERR_PACKAGE_SPACE_NOT_ENOUGH
            end
		end
		itemop.remove_bypos(bag, v.pos, v.item_cnt)
	end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
end

local function tpgem_bylevel(level)
    for k, v in pairs(tpgem) do
        if v.Level == level then
            return v
        end
    end
end

REQ[IDUM_REQGEMCOMPOSE] = function(ur,v)
	local bag = ur:getbag(BAG_MAT)
	 if not bag then
        return SERR_PARAM
    end
	local gem = itemop.get(bag,v.pos)
	if not gem then
		return SERR_ITEM_NOT_EXIST
	end
	local tp = tpgem[gem.tpltid]
    if not tp then
        return SERR_NOTPLT
    end
	local gem_level = tp.Level+1
    local tp_gem = tpgem_bylevel(gem_level)
    if not tp_gem then
		return SERR_GEMLEVELMAX
    end
    local gainid = tp_gem.ID
	if v.compose_type == 1 then
		if gem.stack < 3 then
            local other
			bag:change(function(other)
                if other.tpltid == gem.tpltid and other.pos ~= gem.pos then
                    -- gem堆叠很大，这里简单处理
                    if v.stack + gem.stack >= 3 then
                        return true
                    end
                end
            end)
			if not other then
				return SERR_GEMNUMNOTENOUGH
			end
            itemop.remove_bypos(bag, gem.pos, gem.stack)
            itemop.remove_bypos(bag, other.pos, 3-gem.stack)
		else
			itemop.remove_bypos(bag, v.pos, 3)
		end
		itemop.gain(ur, gainid, 1)
	elseif v.compose_type == 2 then
		local integer = item.stack//3
		if integer > 0 then
			itemop.remove_bypos(bag, v.pos, 3 * integer)
			itemop.gain(ur, gainid, integer)
        else return
		end
	end
	itemop.refresh(ur)
	ur:db_tagdirty(ur.DB_ITEM)
	broad_cast.set_borad_cast(ur,gem_level,NOTICE_GEM_COMPOSE_T)
end

local function compose_gem(ur,bag)
    local typ = ITEM_GEM
    local TOP_LEVEL = 20
    local min_level = TOP_LEVEL
    local min_item
    bag:foreach(function(item)
        local tp = tpitem[item.tpltid]
        if tp and tp.itemType == typ then
            local tp_gem = tpgem[item.tpltid]
            if tp_gem and tp_gem.Level < TOP_LEVEL then
                if tp.Level < min_level and item.stack >= 3 then
                    min_level = tp.Level
                    min_item = item
                end
            end
        end
    end)
    
    if min_level < TOP_LEVEL then
        local tp_gem = tpgem_bylevel(min_level+1)
        if not tp_gem then
            return nil, SERR_NOTPLT
        end
	    local integer = min_item.stack//3
        assert(integer > 0)
        itemop.remove_bypos(bag, min_item.pos, 3 * integer)
        itemop.gain(ur, tp_gem.ID, integer)
        return true
    end
end

REQ[IDUM_REQONEKEYCOMPOSEALLGEM] = function(ur,v)
    if not ur:onekeyop_check_pass() then
        return SERR_TOOFAST
    end
    local ok, err
    local up
	local bag = ur:getbag(BAG_MAT)
    while true do
        ok, err = compose_gem(ur,bag)
        if not ok then
            break
        end
        up = true
    end
    if up then
        itemop.refresh(ur)
        ur:db_tagdirty(ur.DB_ITEM)
    end
    return err
end

REQ[IDUM_REQONEKEYUNINSTALLGEM] = function(ur, v)
    if not ur:onekeyop_check_pass() then
        return SERR_TOOFAST
    end
    local skip = v.pos
    local typ = ITEM_EQUIP
	local bag = ur:getbag(BAG_MAT)
    if bag:change(function(item)
        local tp = tpitem[item.tpltid]
        if tp and tp.itemType == typ then
            if item.pos ~= skip and item.info.hole then
                local up
                for k, hole in ipairs(item.info.hole) do
                    if hole.gemid > 0 then
                        itemop.gain(ur,hole.gemid,1)
                        hole.gemid = 0
                        up = true
                    end	
                end
                return up
            end
        end
    end) then
        itemop.refresh(ur)
        ur:db_tagdirty(ur.DB_ITEM)
    end
end

return REQ
