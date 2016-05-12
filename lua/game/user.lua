local shaco = require "shaco"
local util = require "util"
local pb = require "protobuf"
local tbl = require "tbl"
local MSG_RESNAME = require "msg_resname"
local ctx = require "ctx"
local mydb = require "mydb"
--local bag = require "bag"
--local itemop = require "itemop"

local spack = string.pack

local user = {
    DB_ROLE=1,
    DB_ROLE_DELAY=2,
    DB_ITEM=4,
}
user.__index = user

function user.new(connid, status)
    local self = {
        connid = connid,
        status = status,
        gmlevel = 0,
        db_dirty_flag = 0,
        acc = false,
        info = false,
    }
    setmetatable(self, user)
    return self
end

function user:init(roleid, gmlevel, info, itemv)
    if not info then
        info = {
            roleid = roleid,
            name = "testname",
            create_time=0,
            icon=1,
            sex=0,
            level=0,
            copper=10000,
            gold=10000,
            duanwei=0,
            xing=0,
            mvp_cnt=0,
            champion_cnt=0,
            eat1_cnt=0,
            eat2_cnt=0,
            max_mass=0,
            province=0,
            city=0,
            describe="",
        }
    else
        info.roleid = roleid -- force
    end
    self.info = info
    self.gmlevel = gmlevel
end

function user:entergame()
	self:send(IDUM_EnterGame, {info=self.info})
end

function user:exitgame()
    self:db_flush(true)
end

function user:syncrole()
    self:send(IDUM_SyncRole, {info=self.info})
end

function user:update(now)
end

function user:onchangeday(login)
end

-- db
function user:db_tagdirty(t)
    self.db_dirty_flag = (self.db_dirty_flag | t)
end

function user:db_flush(force)
    local roleid = self.info.roleid
    local flag = self.db_dirty_flag

    local up_role = false
    if (flag & self.DB_ROLE) ~= 0 then
        flag = (flag & (~(self.DB_ROLE)))
        up_role = true
    elseif (force and ((flag & self.DB_ROLE_DELAY) ~= 0)) then
        flag = (flag & (~(self.DB_ROLE_DELAY)))
        up_role = true
    end
    if up_role then
        mydb.send("S.role", roleid, pb.encode("role_info", self.info))
    end 
    if (flag & self.DB_ITEM) ~= 0 then
        --mydb.exec("S.ex", "item", roleid,
        --    pb.encode("item_list"))
        flag = (flag & (~(self.DB_ITEM)))
		
    end  
	self.db_dirty_flag = flag
end

-- money
function user:copper_enough(take)
    return self.info.copper >= take
end

function user:copper_take(take)
    local old = self.info.copper
    if old >= take then
        self.info.copper = old - take
        return true
    else
        return false
    end
end

function user:copper_got(got)
    if got == 0 then
        return 0
    end
    local old = self.info.copper
    self.info.copper = old + got 
    if self.info.copper < 0 then
        self.info.copper = 0
    end
    return self.info.copper-old
end

-- gold
function user:gold_enough(take)
    return self.info.gold >= take
end

function user:gold_take(take)
    local old = self.info.gold
    if old >= take then
        self.info.gold = old - take
        return true
    else
        return false
    end
end

function user:gold_got(got)
    if got == 0 then
        return 0
    end
    local old = self.info.gold
    self.info.gold = old + got
    if self.info.gold < 0 then
        self.info.gold = 0     
    end
    return self.info.gold-old
end

-- send
function user:sendpackedmsg(msgid, packedmsg)
    ctx.send(self.connid, spack("<I2", msgid)..packedmsg)
end

function user:send(msgid, v)
    local name = MSG_RESNAME[msgid]
    assert(name)
    self:sendpackedmsg(msgid, pb.encode(name, v))
end

return user
