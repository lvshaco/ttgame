local fighttag = {}

local fight_tag_pool = {}
function fighttag.set(roleid, fighting)
    if fight_tag_pool[roleid] then
        return false
    end
    fight_tag_pool[roleid] = fighting
end

function fighttag.unset(roleid) 
    local fighting = fight_tag_pool[roleid]
    fight_tag_pool[roleid] = nil
    return fighting
end

function fighttag.clear_byserverid(serverid)
end

return fighttag
