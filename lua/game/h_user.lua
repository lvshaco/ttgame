local shaco = require "shaco"
local tbl = require "tbl"
local tpcompose = require "__tpcompose"
local sfmt = string.format
local myredis = require "myredis"
local userpool = require "userpool"
local cache = require "cache"
local pb = require "protobuf"
local util = require "util"
local ctx = require "ctx"

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
    ur:refreshbag(8)

    ur:send(IDUM_Hero, {heroid=heroid, herolevel=level})
end

REQ[IDUM_SetPhoto] = function(ur, v)
    local myid = ur.info.roleid
    local slot = v.data.slot
    local data = v.data.data
    if slot <1 or slot > 10 then
        return SERR_Arg
    end
    myredis.hmset('photo:'..myid, slot, data)
    return SERR_OK
end

REQ[IDUM_ReqPhotos] = function(ur, v)
    local roleid = v.roleid
    local t = myredis.hmget('photo:'..roleid, 1,2,3,4,5,6,7,8,9,10)
    local l = {}
    for k, v in pairs(t) do
        l[#l+1] = {
            slot = k,
            data = v,
        }
    end
    ur:send(IDUM_Photos, {roleid=roleid, list=l})
end

REQ[IDUM_SetName] = function(ur, v)
  if #v.passwd <= 0 or #v.name <= 0 then
    return SERR_Arg
  end
    if ur.info.name and #ur.info.name > 0 then
        return SERR_NameChanged
    end
    local name = v.name
    local err = cache.checkname(name)
    if err ~= SERR_OK then
        return err
    end
    local oldacc = ur.acc
    local accinfo = myredis.urcall(ur, 'get', 'acc:'..oldacc)
    if not accinfo then
      return SERR_Noacc
    end
    accinfo = pb.decode('acc_info', accinfo)
    accinfo.passwd = v.passwd

    local old = ur.info.name
    local myid = ur.info.roleid

    userpool.changename(ur, name)
    ur.info.sex = v.sex
    ur:db_tagdirty(ur.DB_ROLE)
    ur:db_flush()

    shaco.trace(tbl(accinfo, "acc_info"))
    myredis.send('set', 'acc:'..oldacc, pb.encode('acc_info', accinfo))
    myredis.send('rename', 'acc:'..oldacc, 'acc:'..name)
    myredis.send('set', 'rolen2id:'..name, myid)
    myredis.send('del', 'rolen2id:'..old)
    
    ur:syncrole()
    return SERR_OK
end

REQ[IDUM_SetSex] = function(ur, v)
    if v.sex ~= 0 and v.sex ~= 1 then
        return SERR_Arg
    end
    ur.info.sex = v.sex
    ur:db_tagdirty(ur.DB_ROLE)
    ur:syncrole()
    return SERR_OK
end

REQ[IDUM_SetDesc] = function(ur, v)
    local desc = v.desc
    if #desc <= 0 or #desc > 128 then
        return SERR_Arg
    end
    ur.info.describe = desc
    ur:db_tagdirty(ur.DB_ROLE)
    ur:syncrole()
    return SERR_OK
end

REQ[IDUM_SetGeo] = function(ur, v)
    ur.info.province = v.province
    ur.info.city = v.city
    ur:db_tagdirty(ur.DB_ROLE)
    ur:syncrole()
    return SERR_OK
end

REQ[IDUM_SetIcon] = function(ur, v)
    local icon = v.icon
    local data = v.data
    if icon >= 0 and icon < 100 then
        if data == "" then --没有照片icon数据
            return SERR_Arg
        end
    else
        data = nil
    end
    local myid = ur.info.roleid
    if data then
        myredis.urcall(ur, 'hmset', 'photo:'..myid, 0, data) -- store in slot 0
    end
    ur.info.icon = v.icon
    ur:db_tagdirty(ur.DB_ROLE)
    ur:syncrole()
    return SERR_OK
end

REQ[IDUM_GetTicket] = function(ur, v)
    if ur.info.free_ticket <=0 then
        return SERR_State
    end
    ur.info.free_ticket = ur.info.free_ticket-1
    ur:db_tagdirty(ur.DB_ROLE)
    ur:syncrole()
    ur.bag:add(1001, 1)
    ur:refreshbag(9)
    return SERR_OK
end

REQ[IDUM_ReqIcons] = function(ur, v)
    local l = {}
    for _, id in ipairs(v.list) do
        local data = myredis.urcall(ur, 'hmget', 'photo:'..id, 0)
        if data then
            l[#l+1] = {
                roleid = id,
                data = data[1],
            }
        end
    end
    ur:send(IDUM_Icons, {list = l})
end

REQ[IDUM_Sign] = function(ur, v)
    local info = ur.info
    if info.sign == true then
        return SERR_State
    end
    local now = shaco.now()//1000
    
    local lasttm = os.date("*t", info.last_sign_time)
    local tm = os.date("*t", now)
    local day = tm.day
    if tm.year == lasttm.year and tm.month == lasttm.month then
        info.sign_tags = (info.sign_tags) | (1<<(day-1))
    else
        info.sign_tags = (1<<(day-1))
    end
    info.last_sign_time = now

    ur:copper_got(10)
    info.sign = true
    ur:db_tagdirty(ur.DB_ROLE)
    ur:syncrole()
    return SERR_OK
end

REQ[IDUM_Award] = function(ur, v)
    local info = ur.info
    local index
    local typ
    local day = tonumber(os.date("*t").day)
    for i, v in ipairs(ctx.award.list) do
        if day == v.day then
            index = i
            typ = v.type
            break
        end
    end
    if not index then
        return SERR_State
    end
    if info.award_gots[index] then
        shaco.error("has got award", index)
        return SERR_State
    end
    info.award_gots[index] = true
    if typ==1 then
        ur.bag:add(701, 1)
        ur:refreshbag(11)
    else
        ur:gold_got(20)
    end
    ur:db_tagdirty(ur.DB_ROLE)
    ur:syncrole()
    return SERR_OK
end

return REQ
