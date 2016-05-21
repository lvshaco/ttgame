local shaco = require "shaco"
local tbl = require "tbl"
local tpitem = require "__tpitem"

local bag = {}
bag.__index = bag

function bag.new(data)
    local items = {}
    if data then
        for k, v in ipairs(data) do
            local id = v.tpltid
            local tp = tpitem[id]
            if not tp then
                shaco.error("bag.new no tplt:", id)
            else
                items[id] = {
                    up = false,
                    tp = tp,
                    info = v,
                }
            end
        end
    end
    shaco.trace(tbl(items, "bag.new items"))
    return setmetatable({
        up = false,
        items = items,
    }, bag)
end

function bag:add(id, stack)
    if stack <= 0 then
        shao.error("bag:add stack=0")
        return false
    end
    local tp = tpitem[id]
    if not tp then
        shaco.error("bag:add no tplt:", id)
        return false
    end
    local item = self.items[id]
    if not item then
        self.items[id] = {
            up = true,
            tp = tp,
            info = {
                tpltid = id,
                stack = stack,
                create_time = shaco.now()//1000,
            }
        }
    else
        item.info.stack = item.info.stack + stack 
        item.up = true
    end
    self.up = true
    return true
end

function bag:remove(id, stack)
    local item = self.items[id]
    if not item then
        return false
    end
    local old = item.info.stack
    if old < stack then
        return false
    end
    item.info.stack = old-stack
    item.up = true
    self.up = true
    return true
end

function bag:has(id, stack)
    local item = self.items[id]
    if not item then
        return false
    end
    local old = item.info.stack
    if old < stack then
        return false
    end
    return true
end

function bag:refresh(func)
    if not self.up then
        return false
    end
    for k, v in pairs(self.items) do
        if v.up then
            func(v)
        end
    end
    self.up = false
end

function bag:foreach(func)
    for k, v in pairs(self.items) do
        func(v)
    end
end

return bag
