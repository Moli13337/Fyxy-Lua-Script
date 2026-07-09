---
--- Created by BY.
--- DateTime: 2023/10/5 20:47:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMotifActPreview:LWnd
local UIMotifActPreview = LxWndClass("UIMotifActPreview", LWnd)
local typeof = typeof
local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMotifActPreview:UIMotifActPreview()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMotifActPreview:OnWndClose()
	self:StopDelayTimer()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMotifActPreview:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMotifActPreview:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIMotifActPreview:InitEvent()
	self:SetWndClick(self.mBg, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIMotifActPreview:InitCommand()
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	local templateName = self:GetWndArg("templateName")
	local reward = self:GetWndArg("reward")
	local openData = self:GetWndArg("openData")
	local templateText = self:GetWndArg("templateText")

	self:SetWndText(self.mLblBiaoti,templateName)
	if openData and openData[3] and openData[4] then
		local formatStr = ccClientText(18100)
		local startTime = LUtil.OSDate(formatStr, openData[3])
		local eTime = checknumber(openData[4])
		if eTime then
			local dayTable = LUtil.OSDate("*t", eTime)
			if dayTable then
				if dayTable.hour == 0 and dayTable.min == 0 and dayTable.sec == 0 then
					eTime = eTime - 1
				end
			end
		end
		local endTime = LUtil.OSDate(formatStr, eTime)
		local timeStr = string.replace(ccClientText(29204),startTime,endTime)
		self:SetWndText(self.mTimeText,timeStr)
	end
	self:UpdateResultText(self.mDesText,self.mResultNode,templateText,0)
	--self:SetWndText(self.mDesText,templateText)
	self:SetWndText(self.mAwardText,ccClientText(29202))
	if string.isempty(reward)then return end
	local rewardList = LxDataHelper.ParseItem(reward)
	local uiList = self._uiEasyList
	if not uiList then
		uiList = UIIconEasyList:New(self)
		self._uiEasyList = uiList
		uiList:Create(self, self.mItemScroll)
		uiList:SetIconParentPath("Root/CommonUI/Icon")
		uiList:SetShowNum(false)
	end
	uiList:RefreshList(rewardList)
	uiList:EnableScroll(#rewardList>4,true)
end
function UIMotifActPreview:StartDelayTimer(ResultNode,normalized)
	if not ResultNode then
		return
	end
	local resultNode = ResultNode:GetComponent(typeOfScrollRect)
	if self._delayUpdateScrollTimer then
		return
	end
	self._delayUpdateScrollTimer = LxTimer.DelayFrameCall(function ()
		if normalized then
			resultNode.verticalNormalizedPosition = normalized
		end
		self._delayUpdateScrollTimer = nil
	end,1)
end
function UIMotifActPreview:StopDelayTimer()
	if self._delayUpdateScrollTimer then
		LxTimer.DelayTimeStop(self._delayUpdateScrollTimer)
		self._delayUpdateScrollTimer = nil
	end
end

function UIMotifActPreview:UpdateResultText(ResultText,ResultNode,text,normalized)
	self:SetWndText(ResultText,text)
	self:StartDelayTimer(ResultNode,normalized)
end
------------------------------------------------------------------
return UIMotifActPreview


