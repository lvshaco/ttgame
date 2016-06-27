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
rawset(_ENV, "SERR_Noacc", 8) -- 无此账号
rawset(_ENV, "SERR_Passwd", 9) -- 密码错误

rawset(_ENV, "SERR_InvalidName", 10) -- 无效名字
rawset(_ENV, "SERR_ExistName", 11) -- 存在的名字
rawset(_ENV, "SERR_NameChanged", 12)--名字已经改过

rawset(_ENV, "SERR_Nocopper", 21) -- 铜币不足
rawset(_ENV, "SERR_Nogold", 22) -- 元宝不足
rawset(_ENV, "SERR_Noticket", 23) -- 入场劵不足
rawset(_ENV, "SERR_Nomat", 30) -- 材料不足
rawset(_ENV, "SERR_Norole", 31)-- 没有指定角色

rawset(_ENV, "SERR_Notfriend", 80)-- 不是好友
rawset(_ENV, "SERR_Friendyet", 81)-- 已经是好友
rawset(_ENV, "SERR_HasInvite", 82)--已经邀请
rawset(_ENV, "SERR_Blackyet", 83)-- 已经拉黑

rawset(_ENV, "SERR_FightGone", 84) --战斗服找不到
rawset(_ENV, "SERR_ReenterFight", 85) --重新进入战斗失败，需要重新正常进战斗
rawset(_ENV, "SERR_ExitFight", 86)--退出战斗出现错误
