---
--- Created by Administrator.
--- DateTime: 2024/10/16 21:46:25
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightPkReportList:LWnd
local UIGdHoFightPkReportList = LxWndClass("UIGdHoFightPkReportList", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightPkReportList:UIGdHoFightPkReportList()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightPkReportList:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightPkReportList:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightPkReportList:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	self:InitCommon()
	self:ClickTab(1)

	gModelGuildHolyPeak:GuildPinnacleGuildInfoReq()
end

function UIGdHoFightPkReportList:DrawList(_, trans, data)
	local guildA = CS.FindTrans(trans, "GuildA")
	local guildB = CS.FindTrans(trans, "GuildB")
	local reportBtn = CS.FindTrans(trans, "ReportBtn")

	local guildAData = gModelGuildHolyPeak:GetGuildInfoById(data.guildA)
	local guildBData = gModelGuildHolyPeak:GetGuildInfoById(data.guildB)
	self:SetGuildItem(guildA, guildAData, data.winGuild == data.guildA, true)
	self:SetGuildItem(guildB, guildBData, data.winGuild == data.guildB)
	self:SetWndClick(reportBtn, function()
		GF.OpenWnd("UIGdHoFightPkFight", { id = data.id })
	end)
end

function UIGdHoFightPkReportList:SetGuildItem(trans, data, isWin, isLeft)
	local win = CS.FindTrans(trans, "Win")
	local lose = CS.FindTrans(trans, "Lose")
	local flag = CS.FindTrans(trans, "Flag")
	local icon = CS.FindTrans(trans, "Icon")
	local level = CS.FindTrans(trans, "Level")
	local text = CS.FindTrans(trans, "Text")
	local text_enus = CS.FindTrans(trans, "Text_Enus")
	local power = CS.FindTrans(trans, "Power")

	CS.ShowObject(win, isWin)
	CS.ShowObject(lose, not isWin)
	if not data then
		return
	end
	local flagRes = gModelGuild:GetGuildFlagRefByRefId(data.flagBgId).res
	local iconRes = gModelGuild:GetGuildFlagRefByRefId(data.flagId).res
	self:SetWndEasyImage(flag, flagRes)
	self:SetWndEasyImage(icon, iconRes)
	self:SetWndText(level, data.level .. ccClientText(46014))

	if self._isEnus then
		local s = "<color=#aaff96>【#a1#】</color>"
		self:SetWndText(text_enus, string.replace(s, gLGameLogin:GetServerShotNameById(data.serverId)))
		self:SetWndText(text,data.guildName)
	else
		local s = isLeft and data.guildName .. "<color=#aaff96>【#a1#】</color>" or "<color=#aaff96>【#a1#】</color>" .. data.guildName
		self:SetWndText(text, string.replace(s, gLGameLogin:GetServerShotNameById(data.serverId)))
	end
	local s = isLeft and ccClientText(46025) .. "<color=#fef01e>#a1#</color>" or "<color=#fef01e>#a1#</color>" .. ccClientText(46025)
	self:SetWndText(power, string.replace(s, LUtil.NumberCoversion(data.guildPower)))
end

function UIGdHoFightPkReportList:UpdateList()
	local t = gModelGuildHolyPeak:GetReportList()
	local list = {}
	for _, v in ipairs(t) do
		if v.id and v.id ~= "" and v.guildA ~= "0" and v.guildB ~= "0" then
			table.insert(list, v)
		end
	end
	if not self.isAll then
		local tb = {}
		for _, v in ipairs(list) do
			local guildId = gModelPlayer:GetGuildId()
			if v.guildA == guildId or v.guildB == guildId then
				table.insert(tb, v)
			end
		end
		list = tb
	end
	if self.uiList then
		self.uiList:ResetList(list)
		self.uiList:DrawAllItems()
	else
		self.uiList = self:GetUIScroll("mRewardList")
		self.uiList:Create(self.mList, list, function(...) self:DrawList(...) end, UIItemList.SUPER)
	end
end

function UIGdHoFightPkReportList:ClickTab(index)
	self.isAll = index == 1
	self:SetWndTabStatus(self.mAllBtn, self.isAll and 0 or 1)
	self:SetWndTabStatus(self.mSelfBtn, self.isAll and 1 or 0)
	self:UpdateList()
end

function UIGdHoFightPkReportList:InitCommon()
	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mAllBtn, function()
		self:ClickTab(1)
	end)
	self:SetWndClick(self.mSelfBtn, function()
		self:ClickTab(2)
	end)

	------------------------------------------------------------------
	---text
	self:SetWndText(self.mLblBiaoti, ccClientText(46022))
	self:SetWndTabText(self.mAllBtn, ccClientText(46023))
	self:SetWndTabText(self.mSelfBtn, ccClientText(46024))

	------------------------------------------------------------------
	---event
	self:WndEventRecv("GuildPinnacleGuildInfoResp", function()
		gModelGuildHolyPeak:GuildPinnacleCombatProfilesReq()
	end)
	self:WndEventRecv("GuildPinnacleCombatProfilesResp", function()
		self:UpdateList()
	end)
end



------------------------------------------------------------------
return UIGdHoFightPkReportList