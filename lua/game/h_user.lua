local shaco = require "shaco"
local tbl = require "tbl"
local tpcompose = require "__tpcompose"
local sfmt = string.format
local myredis = require "myredis"
local userpool = require "userpool"
local cache = require "cache"
local pb = require "protobuf"

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

REQ[IDUM_SetPhoto] = function(ur, v)
    local myid = ur.info.roleid
    local slot = v.data.slot
    local data = v.data.data
    if slot <1 or slot > 10 then
        return SERR_Arg
    end
    myredis.hmset('photo:'..myid, slot, data)
end

REQ[IDUM_ReqPhotos] = function(ur, v)
    local myid = ur.info.roleid
    local t = myredis.hmget('photo:'..myid, 1,2,3,4,5,6,7,8,9,10)
    local l = {}
    for k, v in pairs(t) do
        l[#l+1] = {
            slot = k,
            data = v,
        }
    end
    ur:send(IDUM_Photos, {list=l})
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
end

REQ[IDUM_SetDesc] = function(ur, v)
    local desc = v.desc
    if #desc <= 0 or #desc > 128 then
        return SERR_Arg
    end
    ur.info.describe = desc
    ur:db_tagdirty(ur.DB_ROLE)
    ur:syncrole()
end

REQ[IDUM_SetGeo] = function(ur, v)
    ur.info.province = v.province
    ur.info.city = v.city
    ur:db_tagdirty(ur.DB_ROLE)
    ur:syncrole()
end

return REQ
