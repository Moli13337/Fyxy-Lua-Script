---
--- Created by Administrator.
--- DateTime: 2024/10/16 15:01:29
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGdHoFightPkSchedule16:LChildWnd
local UISubGdHoFightPkSchedule16 = LxWndClass("UISubGdHoFightPkSchedule16", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGdHoFightPkSchedule16:UISubGdHoFightPkSchedule16()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGdHoFightPkSchedule16:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGdHoFightPkSchedule16:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGdHoFightPkSchedule16:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()

	gModelGuildHolyPeak:GuildPinnacleMatchInfoReq()
end

function UISubGdHoFightPkSchedule16:SetGuildItem(trans, data, isWin)
	local win = CS.FindTrans(trans, "Win")
	local off = CS.FindTrans(trans, "Off")
	local offNum = CS.FindTrans(off, "Num")
	local offText = CS.FindTrans(off, "Text")
	local on = CS.FindTrans(trans, "On")
	local flag = CS.FindTrans(on, "Flag")
	local icon = CS.FindTrans(on, "Icon")
	local serverName = CS.FindTrans(on, "ServerName")
	local name = CS.FindTrans(on, "Name")
	local me = CS.FindTrans(on, "Me")

	if data then
		local flagRes = gModelGuild:GetGuildFlagRefByRefId(data.flagBgId).res
		local iconRes = gModelGuild:GetGuildFlagRefByRefId(data.flagId).res
		self:SetWndEasyImage(flag, flagRes)
		self:SetWndEasyImage(icon, iconRes)
		self:SetWndText(serverName, "[" .. gLGameLogin:GetServerShotNameById(data.serverId) .. "]")
		self:SetWndText(name, data.guildName)
		self:SetTextOutLineByColor(serverName, "black")
		self:SetTextOutLineByColor(name, "black")
		local guildId = gModelPlayer:GetGuildId()
		CS.ShowObject(me, guildId == data.guildId)
		if win then
			CS.ShowObject(win, isWin)
		end
	else
		if offNum then
			self:SetWndText(offNum, "16")
		end
		if offText then
			self:SetWndText(offText, ccClientText(11707))
		end
	end
	CS.ShowObject(on, data ~= nil)
	CS.ShowObject(off, data == nil)
	self:SetWndClick(trans, function()
		if data then
			gModelGuild:OnGuildMemberListReq(data.guildId, data.serverId)
		end
	end)
end

function UISubGdHoFightPkSchedule16:SetItem(trans, data)
	local guildA = CS.FindTrans(trans, "GuildA")
	local guildB = CS.FindTrans(trans, "GuildB")
	local guildWin = CS.FindTrans(trans, "GuildWin")
	local reportBtn = CS.FindTrans(trans, "ReportBtn")

	if not data then
		return
	end
	local guildAData = gModelGuildHolyPeak:GetGuildInfoById(data.guildA)
	local guildBData = gModelGuildHolyPeak:GetGuildInfoById(data.guildB)
	self:SetGuildItem(guildA, guildAData, data.guildA == data.winGuild)
	self:SetGuildItem(guildB, guildBData, data.guildB == data.winGuild)
	local guildWinData
	if data.winGuild == data.guildA then
		guildWinData = guildAData
	elseif data.winGuild == data.guildB then
		guildWinData = guildBData
	end
	self:SetGuildItem(guildWin, guildWinData)

	CS.ShowObject(reportBtn, guildAData and guildBData and guildWinData)
	self:SetWndClick(reportBtn, function()
		GF.OpenWnd("UIGdHoFightPkFight", { id = data.id })
	end)
end

function UISubGdHoFightPkSchedule16:UpdateItem()
	local matchInfo = gModelGuildHolyPeak:GetMatchInfoByRound(ModelGuildHolyPeak.ROUND_1)
	for i = 1, 8 do
		local trans = self["mRoot" .. i]
		local data = matchInfo[i]
		self:SetItem(trans, data)
	end
end

function UISubGdHoFightPkSchedule16:InitCommon()
	------------------------------------------------------------------
	---event
	self:WndEventRecv("GuildPinnacleMatchInfoResp", function()
		self:UpdateItem()
	end)
	self:WndEventRecv("GuildPinnacleFightResultResp", function()
		gModelGuildHolyPeak:GuildPinnacleMatchInfoReq()
	end)
	self:WndEventRecv("GuildPinnacleStageResp", function()
		gModelGuildHolyPeak:GuildPinnacleMatchInfoReq()
	end)

	------------------------------------------------------------------
	---eff
	self:CreateWndEffect(self.mImage, "fx_ui_sqzz_saicheng_jiangbei", "mImage", 100)
end



------------------------------------------------------------------
return UISubGdHoFightPkSchedule16