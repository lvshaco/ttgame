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

rawset(_ENV, "IDUM_UnequipItem", 23)--卸下装备
--IDUM_OpenBox = 24; -- 开宝箱(feiqi)

rawset(_ENV, "IDUM_HeroLevelup", 30) -- 神兽升级

rawset(_ENV, "IDUM_ReqServerList", 50)-- 请求战斗服务器列表
rawset(_ENV, "IDUM_ReqLoginFight", 51) -- 请求登录战斗服

rawset(_ENV, "IDUM_SetFocus", 60) 
rawset(_ENV, "IDUM_ReqRole", 62) -- 请求他人数据
rawset(_ENV, "IDUM_ReqFans", 63) -- 请求喜欢列表

rawset(_ENV, "IDUM_ReqRanks", 70) -- 排名列表
rawset(_ENV, "IDUM_GetTopMsg", 80) --请求热门留言
rawset(_ENV, "IDUM_GetMsg", 81)--请求留言
rawset(_ENV, "IDUM_SendMsg", 82)--发送留言
rawset(_ENV, "IDUM_LikeMsg", 83)--喜欢留言
rawset(_ENV, "IDUM_GetFriend", 90) --请求好友列表
rawset(_ENV, "IDUM_InviteFriend", 91) --邀请好友
rawset(_ENV, "IDUM_ResponseInvite", 92) --应答好友邀请
rawset(_ENV, "IDUM_ToBlack", 95) -- 请求拉入黑名单

rawset(_ENV, "IDUM_ReqSeasonRank", 100) --赛季排名
rawset(_ENV, "IDUM_ReqGameRecord", 101) --比赛记录
rawset(_ENV, "IDUM_SetPhoto", 102) --设置照片
rawset(_ENV, "IDUM_ReqPhotos", 103) --req照片

rawset(_ENV, "IDUM_SetName", 110) -- 设置姓名(现在是注册)
rawset(_ENV, "IDUM_SetSex", 111) -- 设置性别
rawset(_ENV, "IDUM_SetDesc", 112) -- 设置个人说明
rawset(_ENV, "IDUM_SetGeo", 113) -- 设置地理位置
rawset(_ENV, "IDUM_SetIcon", 114) -- 设置地理位置
rawset(_ENV, "IDUM_GetTicket", 115) -- 免费领票

rawset(_ENV, "IDUM_ReqIcons", 120) --批量请求照片icon数据

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
rawset(_ENV, "IDUM_EquipUpdate", 1023) --装备更新

rawset(_ENV, "IDUM_Hero", 1030) -- 神兽升级反馈

rawset(_ENV, "IDUM_ServerList", 1050) -- 战斗服列表
rawset(_ENV, "IDUM_LoginFightKey", 1051) -- 战斗服钥匙

rawset(_ENV, "IDUM_RoleInfo", 1062) -- 他人数据
rawset(_ENV, "IDUM_Fans", 1063) -- 粉丝列表
rawset(_ENV, "IDUM_Ranks", 1070) -- 排名列表
rawset(_ENV, "IDUM_FightLikes", 1071) -- 战斗结束是否喜欢列表
rawset(_ENV, "IDUM_TopMsg", 1080) --热门留言
rawset(_ENV, "IDUM_MsgList", 1081)-- 留言列表
rawset(_ENV, "IDUM_Friends", 1090) --好友列表
rawset(_ENV, "IDUM_AddFriend", 1091) --添加好友
rawset(_ENV, "IDUM_AddInvite", 1092) --添加邀请
rawset(_ENV, "IDUM_DelInvite", 1093) --删除邀请
rawset(_ENV, "IDUM_AddBlack", 1095) --添加黑名单

rawset(_ENV, "IDUM_SeasonRank", 1100) --赛季排名
rawset(_ENV, "IDUM_GameRecord", 1101) --比赛记录
rawset(_ENV, "IDUM_Photos", 1103)--照片列表

rawset(_ENV, "IDUM_Icons", 1120) --照片icon数据列表

rawset(_ENV, "IDUM_CLIE", 1999) -- to client end
