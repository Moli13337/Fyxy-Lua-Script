---
--- Created by Administrator.
--- DateTime: 2024/10/28 11:15:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightPkGuessList:LWnd
local UIGdHoFightPkGuessList = LxWndClass("UIGdHoFightPkGuessList", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightPkGuessList:UIGdHoFightPkGuessList()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightPkGuessList:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightPkGuessList:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightPkGuessList:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()

	gModelGuildHolyPeak:GuildPinnacleQuizRecordsReq()
end

function UIGdHoFightPkGuessList:SetGuildItem(trans, data, isWin, isLeft)
	local win = CS.FindTrans(trans, "Win")
	local lose = CS.FindTrans(trans, "Lose")
	local flag = CS.FindTrans(trans, "Flag")
	local icon = CS.FindTrans(trans, "Icon")
	local level = CS.FindTrans(trans, "Level")
	local text = CS.FindTrans(trans, "Text")
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
	local s = isLeft and data.guildName .. "<color=#aaff96>【#a1#】</color>" or "<color=#aaff96>【#a1#】</color>" .. data.guildName
	self:SetWndText(text, string.replace(s, gLGameLogin:GetServerShotNameById(data.serverId)))
	local s = isLeft and ccClientText(46025) .. "<color=#fef01e>#a1#</color>" or "<color=#fef01e>#a1#</color>" .. ccClientText(46025)
	self:SetWndText(power, string.replace(s, LUtil.NumberCoversion(data.guildPower)))
end

function UIGdHoFightPkGuessList:DrawList(_, trans, data)
	local getText = CS.FindTrans(trans, "Get")
	local guildA = CS.FindTrans(trans, "GuildA")
	local guildB = CS.FindTrans(trans, "GuildB")
	local reportBtn = CS.FindTrans(trans, "ReportBtn")
	local stageText = CS.FindTrans(trans, "Stage")

	local stage = tonumber(string.split(data.id, "_")[1])
	self:SetWndText(stageText, gModelGuildHolyPeak:GetGuessStageText(stage))

	local str = ccClientText(46059)
	if data.item ~= 0 then
		local name = gModelGeneral:GetCommonItemName(gModelGuildHolyPeak:GetGuessItem())
		str = data.item > 0 and ccClientText(46060) or ccClientText(46061)
		str = string.replace(str, math.abs(data.item)) .. name
	end
	self:SetWndText(getText, str)

	local guildAData = gModelGuildHolyPeak:GetGuildInfoById(data.guildA)
	local guildBData = gModelGuildHolyPeak:GetGuildInfoById(data.guildB)
	self:SetGuildItem(guildA, guildAData, data.windGuild == data.guildA, true)
	self:SetGuildItem(guildB, guildBData, data.windGuild == data.guildB)
	self:SetWndClick(reportBtn, function()
		GF.OpenWnd("UIGdHoFightPkFight", { id = data.id })
	end)
end

function UIGdHoFightPkGuessList:UpdateList(pb)
	local list = pb.quizRecords
	local t = {}
	for _, v in ipairs(list) do
		if v.windGuild ~= "0" then
			table.insert(t, v)
		end
	end
	CS.ShowObject(self.mNoRecord2, #t <= 0)
	if self.uiList then
		self.uiList:ResetList(t)
		self.uiList:DrawAllItems()
	else
		self.uiList = self:GetUIScroll("list")
		self.uiList:Create(self.mList, t, function(...) self:DrawList(...) end, UIItemList.SUPER)
	end
end

function UIGdHoFightPkGuessList:InitCommon()
	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)

	------------------------------------------------------------------
	---text
	self:SetWndText(self.mLblBiaoti, ccClientText(11823))
	self:SetWndText(self.mEmptyText, ccClientText(46062))

	------------------------------------------------------------------
	---resp
	self:WndNetMsgRecv(LProtoIds.GuildPinnacleQuizRecordsResp, function(pb)
		self:UpdateList(pb)
	end)
end



------------------------------------------------------------------
return UIGdHoFightPkGuessList