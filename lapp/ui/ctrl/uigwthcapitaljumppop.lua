---
--- Created by BY.
--- DateTime: 2023/10/29 15:57:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGwthCapitalJumpPop:LWnd
local UIGwthCapitalJumpPop = LxWndClass("UIGwthCapitalJumpPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGwthCapitalJumpPop:UIGwthCapitalJumpPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGwthCapitalJumpPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGwthCapitalJumpPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGwthCapitalJumpPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGwthCapitalJumpPop:OnTryTcpReconnect()
	self:WndClose()
end
function UIGwthCapitalJumpPop:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
end

function UIGwthCapitalJumpPop:OnClickJump()
	local sid = self._sid
	if not sid then return end
	local activityData = gModelActivity:GetActivityBySid(sid)
	if not activityData then return end
	gModelActivity:CommonActJump(sid)
	self:WndClose()
end
function UIGwthCapitalJumpPop:InitCommand()
	self:SetWndButtonText(self.mBtnCancel,ccClientText(29000))
	self:SetWndButtonText(self.mBtnJump,ccClientText(29001))

	local sid = self:GetWndArg("sid")
	local reward = self:GetWndArg("reward")
	self._sid = sid

	self._isForeign = gLGameLanguage:IsForeignRegion()

	gModelActivity:ReqActivityConfigData(sid)

	local rewards = LxDataHelper.ParseItem(reward)
	local rewardItem = rewards[1]

	if not rewardItem then
		self:WndClose()
		return
	end
	local itemNumStr = LUtil.FormatHurtNumSpriteText(rewardItem.itemNum)
	if self._isForeign then
		self:SetWndText(self.mNumTextEn,itemNumStr)
	else
		self:SetWndText(self.mNumText,itemNumStr)
	end

	self:SetWndEasyImage(self.mCommBg, "fund_frame_2")
end
function UIGwthCapitalJumpPop:InitEvent()
	self:SetWndClick(self.mBg, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnCancel, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnJump, function(...) self:OnClickJump() end)
end

function UIGwthCapitalJumpPop:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config

	local guideTitle,guideText
	= data.guideTitle,data.guideText
	if not string.isempty(guideTitle) then
		self:SetWndText(self.mTipsText,guideTitle)
	end


	if not string.isempty(guideText) then
		CS.ShowObject(self.mTextMag,not self._isForeign)
		CS.ShowObject(self.mTextMagEn,self._isForeign)

		if self._isForeign then
			self:SetWndText(self.mDesTextEn,guideText)
		else
			self:SetWndText(self.mDesText,guideText)
		end
	end

	local guideImage = data.guideImage
	if not string.isempty(guideImage) then
		if LxUiHelper.IsImgPathValid(guideImage) then
			if self._isForeign then
				self:SetWndEasyImage(self.mGuideImageEn, guideImage, nil, true)
			else
				self:SetWndEasyImage(self.mGuideImage, guideImage, nil, true)
			end
		end
	end
end
------------------------------------------------------------------
return UIGwthCapitalJumpPop


