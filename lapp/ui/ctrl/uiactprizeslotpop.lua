---
--- Created by BY.
--- DateTime: 2023/10/12 15:38:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActPrizeSlotPop:LWnd
local UIActPrizeSlotPop = LxWndClass("UIActPrizeSlotPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActPrizeSlotPop:UIActPrizeSlotPop()
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActPrizeSlotPop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActPrizeSlotPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActPrizeSlotPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIActPrizeSlotPop:OnDrawRewardListItem(list, item,itemdata,itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local itemText = self:FindWndTrans(item,"itemText")

	local moreInfo = string.split(itemdata.moreInfo,"|")
	local reward = LxDataHelper.ParseItem_3(itemdata.reward)

	self:SetWndText(itemText, moreInfo[4] and moreInfo[4] .. "%" or "")

	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(CS.FindTrans(itemRoot,"CommonUI/Icon"))
	end
	baseClass:SetCommonReward(reward.itemType, reward.itemId, reward.itemNum)
	self:SetWndClick(itemRoot, function()
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end)
	baseClass:DoApply()
end

function UIActPrizeSlotPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(27605))

	self:SetWndButtonText(self.mBtnOk, ccClientText(10102))

	local list  = self:GetWndArg("list")
	local des  = self:GetWndArg("des") or ""
	self:SetWndText(self.mDescText, des)
	local contentList = list
	local num = #contentList
	local isMax = num > 4
	local rewardList
	if not isMax then
		rewardList = self.mRewardList
	else
		rewardList = self.mRewardListMax
	end
	CS.ShowObject(self.mRewardList, not isMax)
	CS.ShowObject(self.mRewardListMax, isMax)

	local uiList = self:GetUIScroll("contentList")
	uiList:Create(rewardList,contentList,function (...) self:OnDrawRewardListItem(...) end)
	uiList:EnableScroll(isMax, true)
end

function UIActPrizeSlotPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnOk, function(...) self:WndClose() end,LSoundConst.CLICK_BUTTON_COMMON)
end
------------------------------------------------------------------
return UIActPrizeSlotPop


