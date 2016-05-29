--/*this file is generate by proto2c.lua do not change it by hand*/
--IDUM_CLI

-------------------------------------------
--c->s
-------------------------------------------

rawset(_ENV, "IDUM_GATEB", 0) -- client request begin

rawset(_ENV, "IDUM_Gm", 1) -- gm for test
rawset(_ENV, "IDUM_Login", 10) -- login
rawset(_ENV, "IDUM_BuyItem", 20)
rawset(_ENV, "IDUM_UseItem", 21)
rawset(_ENV, "IDUM_ReqShop", 22) -- 请求商城列表
rawset(_ENV, "IDUM_HeroLevelup", 30) -- 神兽升级

rawset(_ENV, "IDUM_ReqServerList", 50)-- 请求战斗服务器列表
rawset(_ENV, "IDUM_ReqLoginFight", 51) -- 请求登录战斗服

rawset(_ENV, "IDUM_SetFocus", 60) 
rawset(_ENV, "IDUM_ReqRole", 62) -- 请求他人数据
rawset(_ENV, "IDUM_ReqFans", 63) -- 请求喜欢列表

rawset(_ENV, "IDUM_ReqRanks", 70) -- 排名列表

rawset(_ENV, "IDUM_GATEE", 999) -- client request end

------------------------------------------
--s->c
------------------------------------------

rawset(_ENV, "IDUM_CLIB", 1000) -- to client begin 

rawset(_ENV, "IDUM_Response", 1001) -- 如果没有具体的反馈，用这条回复client（如错误提示，ok提示)

rawset(_ENV, "IDUM_Logout", 1010)
rawset(_ENV, "IDUM_EnterGame", 1011) -- 进入游戏
rawset(_ENV, "IDUM_SyncRole", 1012) -- 同步角色属性

rawset(_ENV, "IDUM_ItemUpdate", 1020) -- 物品更新
rawset(_ENV, "IDUM_Shop", 1022) -- 反馈商城列表 

rawset(_ENV, "IDUM_Hero", 1030) -- 神兽升级反馈

rawset(_ENV, "IDUM_ServerList", 1050) -- 战斗服列表
rawset(_ENV, "IDUM_LoginFightKey", 1051) -- 战斗服钥匙

rawset(_ENV, "IDUM_RoleInfo", 1062) -- 他人数据
rawset(_ENV, "IDUM_Fans", 1063) -- 粉丝列表
rawset(_ENV, "IDUM_Ranks", 1070) -- 排名列表
rawset(_ENV, "IDUM_FightLikes", 1071) -- 战斗结束是否喜欢列表

rawset(_ENV, "IDUM_CLIE", 1999) -- to client end
