--/*this file is generate by proto2c.lua do not change it by hand*/
--SERR
rawset(_ENV, "SERR_OK", 0)

-- common
rawset(_ENV, "SERR_Exception", 1) -- 服务器异常
rawset(_ENV, "SERR_Msg", 2) -- error msg
rawset(_ENV, "SERR_Notplt", 3) -- no data template
rawset(_ENV, "SERR_Illegal", 4)
rawset(_ENV, "SERR_Arg", 5) -- 参数错误
rawset(_ENV, "SERR_State", 6) -- 状态错误
rawset(_ENV, "SERR_Remote", 7) -- 远端异常

rawset(_ENV, "SERR_Nocopper", 21) -- 铜币不足
rawset(_ENV, "SERR_Nogold", 22) -- 元宝不足
rawset(_ENV, "SERR_Nomat", 30) -- 材料不足
rawset(_ENV, "SERR_Norole", 31)-- 没有指定角色

rawset(_ENV, "SERR_Notfriend", 80)-- 不是好友
rawset(_ENV, "SERR_Friendyet", 81)-- 已经是好友
rawset(_ENV, "SERR_HasInvite", 82)--已经邀请
