---
--- Created by Administrator.
--- DateTime: 2024/10/16 16:35:04
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGdHoFightPkSchedule8:LChildWnd
local UISubGdHoFightPkSchedule8 = LxWndClass("UISubGdHoFightPkSchedule8", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGdHoFightPkSchedule8:UISubGdHoFightPkSchedule8()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGdHoFightPkSchedule8:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGdHoFightPkSchedule8:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGdHoFightPkSchedule8:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	self:InitCommon()

	gModelGuildHolyPeak:GuildPinnacleMatchInfoReq()
end

function UISubGdHoFightPkSchedule8:SetGuildItem(trans, data, isWin)
	local win = CS.FindTrans(trans, "Win")
	local off = CS.FindTrans(trans, "Off")
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
	end
	CS.ShowObject(on, data ~= nil)
	CS.ShowObject(off, data == nil)
	self:SetWndClick(trans, function()
		if data then
			gModelGuild:OnGuildMemberListReq(data.guildId, data.serverId)
		end
	end)
end

function UISubGdHoFightPkSchedule8:SetItem(trans, data)
	if not data then
		return
	end
	local guildA = trans.guildA
	local guildB = trans.guildB
	local guildWin = trans.guildWin

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
end

function UISubGdHoFightPkSchedule8:UpdateItem()
	local tb = {
		ModelGuildHolyPeak.ROUND_2,
		ModelGuildHolyPeak.ROUND_3
	}
	for _, round in ipairs(tb) do
		local info = gModelGuildHolyPeak:GetMatchInfoByRound(round)
		local trans = self.roundTrans[round]
		for i, v in ipairs(trans) do
			local data = info[i]
			self:SetItem(v, data)

			if data and data.winGuild ~= "0" then
				local reportBtn = CS.FindTrans(v.guildWin, "ReportBtn")
				CS.ShowObject(reportBtn, true)
				self:SetWndClick(reportBtn, function()
					if data then
						GF.OpenWnd("UIGdHoFightPkFight", { id = data.id })
					end
				end)
			end
		end
	end

	local info = gModelGuildHolyPeak:GetMatchInfoByRound(ModelGuildHolyPeak.ROUND_4)
	local trans = self.roundTrans[ModelGuildHolyPeak.ROUND_4]
	for _, v in ipairs(info) do
		local isThird = v.third == 1
		local trans = isThird and trans[1] or trans[2]
		self:SetItem(trans, v)

		local reportBtn = CS.FindTrans(trans.guildWin, "ReportBtn")
		local rank = CS.FindTrans(trans.guildWin, "Rank")
		local rankText = CS.FindTrans(rank, "Text")

		if self._isEnus then
			LxUiHelper.SetSizeWithCurAnchor(rank, 0, 120)
			LxUiHelper.SetSizeWithCurAnchor(rank, 1, 35)
		end

		if isThird and v.winGuild ~= 0 then
			self:SetWndText(rankText, ccClientText(46028))
			CS.ShowObject(rank, true)
			CS.ShowObject(reportBtn, true)
		elseif not isThird and v.winGuild ~= 0 then
			self:SetWndText(rankText, ccClientText(46029))
			CS.ShowObject(rank, true)
			local trans2 = v.winGuild == v.guildA and trans.guildB or trans.guildA
			local rank2 = CS.FindTrans(trans2, "Rank")
			local rankText2 = CS.FindTrans(rank2, "Text")
			self:SetWndText(rankText2, ccClientText(46030))
			CS.ShowObject(rank2, true)
			CS.ShowObject(reportBtn, true)

			self:CreateWndEffect(trans.guildWin, "fx_ui_sqzz_saicheng_guanjun", "rank1", 100)

			if self._isEnus then
				LxUiHelper.SetSizeWithCurAnchor(rank2, 0, 120)
				LxUiHelper.SetSizeWithCurAnchor(rank2, 1, 35)
			end
		end
		self:SetWndClick(reportBtn, function()
			if v then
				GF.OpenWnd("UIGdHoFightPkFight", { id = v.id })
			end
		end)


	end
end

function UISubGdHoFightPkSchedule8:InitCommon()
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
	---member
	self.roundTrans = {
		[ModelGuildHolyPeak.ROUND_2] = {
			{
				guildA = self.mGuild1,
				guildB = self.mGuild2,
				guildWin = self.mGuild9
			},
			{
				guildA = self.mGuild3,
				guildB = self.mGuild4,
				guildWin = self.mGuild10
			},
			{
				guildA = self.mGuild5,
				guildB = self.mGuild6,
				guildWin = self.mGuild11
			},
			{
				guildA = self.mGuild7,
				guildB = self.mGuild8,
				guildWin = self.mGuild12
			},
		},
		[ModelGuildHolyPeak.ROUND_3] = {
			{
				guildA = self.mGuild9,
				guildB = self.mGuild10,
				guildWin = self.mGuild13
			},
			{
				guildA = self.mGuild11,
				guildB = self.mGuild12,
				guildWin = self.mGuild14
			},
		},
		[ModelGuildHolyPeak.ROUND_4] = {
			{
				guildA = self.mGuild15,
				guildB = self.mGuild16,
				guildWin = self.mGuild17
			},
			{
				guildA = self.mGuild13,
				guildB = self.mGuild14,
				guildWin = self.mGuild18
			},
		}
	}

	------------------------------------------------------------------
	---text
	for _, v in pairs(self.roundTrans) do
		for _, v2 in ipairs(v) do
			for _, trans in pairs(v2) do
				local offText = CS.FindTrans(trans, "Off/Text")
				self:SetWndText(offText, ccClientText(11707))
			end
		end
	end
end



------------------------------------------------------------------
return UISubGdHoFightPkSchedule8