---
--- Created by Administrator.
--- DateTime: 2024/10/15 15:12:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightPkSchedule:LWnd
local UIGdHoFightPkSchedule = LxWndClass("UIGdHoFightPkSchedule", LWnd)
local stateText = {
    [ModelGuildHolyPeak.STAGE_0] = ccClientText(44001),
    [ModelGuildHolyPeak.STAGE_1] = ccClientText(44002),
    [ModelGuildHolyPeak.STAGE_2] = ccClientText(46048),
    [ModelGuildHolyPeak.STAGE_3] = ccClientText(46049),
    [ModelGuildHolyPeak.STAGE_4] = ccClientText(46050),
    [ModelGuildHolyPeak.STAGE_5] = ccClientText(46051),
    [ModelGuildHolyPeak.STAGE_6] = ccClientText(46052),
    [ModelGuildHolyPeak.STAGE_7] = ccClientText(46053),
    [ModelGuildHolyPeak.STAGE_8] = ccClientText(46054),
    [ModelGuildHolyPeak.STAGE_9] = ccClientText(46055),
    [ModelGuildHolyPeak.STAGE_10] = ccClientText(46056),
    [ModelGuildHolyPeak.STAGE_11] = ccClientText(46057),
    [ModelGuildHolyPeak.STAGE_12] = ccClientText(46058),
}
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightPkSchedule:UIGdHoFightPkSchedule()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightPkSchedule:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightPkSchedule:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightPkSchedule:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()

	local stage = gModelGuildHolyPeak:GetStage()
	local index = stage < ModelGuildHolyPeak.STAGE_5 and 1 or 2
	self:ClickTabBtn(index)

	self:UpdateTime()
	self:TimerStart("leftTimeRun", 1, false)
end

function UIGdHoFightPkSchedule:UpdateTime()
	local stage = gModelGuildHolyPeak:GetStage()
	if stage == ModelGuildHolyPeak.STAGE_0 or stage == ModelGuildHolyPeak.STAGE_12 then
		self:SetWndText(self.mStateText, stateText[stage])
		self:SetWndText(self.mTimeText, "")
		return
	end
	local endTime = tonumber(gModelGuildHolyPeak:GetStageEndTime()) / 1000
	local cur = GetTimestamp()
	local leftTime = math.max(math.floor(endTime - cur), 0)
	local timeS = LUtil.FormatTimeStr1(leftTime)
	self:SetWndText(self.mStateText, stateText[stage])
	self:SetWndText(self.mTimeText, timeS)
end

function UIGdHoFightPkSchedule:OnTimer(key)
	if key == "leftTimeRun" then
		self:UpdateTime()
	end
end

function UIGdHoFightPkSchedule:ClickTabBtn(index)
	if self.curSelect == index then
		return
	end
	self.curSelect = index
	self:CloseAllChild()
	for i, v in ipairs(self.tabData) do
		CS.ShowObject(v.trans, i == index)
	end
	self:CreateChildWnd(self.mChildRoot, self.tabData[index].childWnd)
end

function UIGdHoFightPkSchedule:InitCommon()
	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mReturnBtn, function()
		self:WndClose()
	end)
	self:SetWndClick(self.m16Btn, function()
		self:ClickTabBtn(1)
	end)
	self:SetWndClick(self.m8Btn, function()
		self:ClickTabBtn(2)
	end)
	self:SetWndClick(self.mGuessBtn, function()
		local stage = gModelGuildHolyPeak:GetStage()
		local guildNum = #gModelGuildHolyPeak:GetGuildInfoList()
		local b1 = stage >= 3 and guildNum > 8
		local b2 = stage >= 5
		if b1 or b2 then
			GF.OpenWnd("UIGdHoFightPkGuess")
		else
			GF.ShowMessage(ccClientText(46033))
		end
	end)
	self:SetWndClick(self.mReportBtn, function()
		if gModelGuildHolyPeak:GetStage() < ModelGuildHolyPeak.STAGE_3 then
			GF.ShowMessage(ccClientText(46042))
			return
		end
		GF.OpenWnd("UIGdHoFightPkReportList")
	end)

	------------------------------------------------------------------
	---text
	self:SetWndText(self.mTxtReturn, ccClientText(42010))
	self:SetWndText(self.mTitle, ccClientText(46002))
	self:SetWndText(CS.FindTrans(self.m16Btn, "Text"), ccClientText(46019))
	self:SetWndText(CS.FindTrans(self.m8Btn, "Text"), ccClientText(46020))
	self:SetTextTile(self.mGuessBtn, ccClientText(46021))
	self:SetTextTile(self.mReportBtn, ccClientText(46013))

	------------------------------------------------------------------
	---member
	self.tabData = {
		{
			trans = CS.FindTrans(self.m16Btn, "On"),
			childWnd = "UISubGdHoFightPkSchedule16"
		},
		{
			trans = CS.FindTrans(self.m8Btn, "On"),
			childWnd = "UISubGdHoFightPkSchedule8"
		},
	}
end

------------------------------------------------------------------
return UIGdHoFightPkSchedule