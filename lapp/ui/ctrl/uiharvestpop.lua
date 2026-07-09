---
--- Created by BY.
--- DateTime: 2022/12/7 20:21:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHarvestPop:LWnd
local UIHarvestPop = LxWndClass("UIHarvestPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHarvestPop:UIHarvestPop()
	self._uiNetRewardList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHarvestPop:OnWndClose()
	if self._uiNetRewardList then
		self._uiNetRewardList:Destroy()
		self._uiNetRewardList = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHarvestPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHarvestPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIHarvestPop:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)
end

function UIHarvestPop:RefreshGetReward(rewards)
	local uiNetRewardList = self._uiNetRewardList
	if not uiNetRewardList then
		uiNetRewardList = UIIconEasyList:New()
		self._uiNetRewardList = uiNetRewardList
		uiNetRewardList:Create(self, self.mItemList,nil,true)
		uiNetRewardList:EnableScroll(true, false)
	end
	uiNetRewardList:RefreshList(rewards, true)
end
function UIHarvestPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.CrusadeDailyRewardResp,function(pb)
		self:RefreshData()
	end)
end

function UIHarvestPop:RefreshData()
	local winCount,thingsDetail = gModelCrusadeAgainst:GetRewardData()
	local list = thingsDetail and thingsDetail.allRewardList or {}
	local len = #list
	CS.ShowObject(self.mNoRecord3,len <= 0)
	local winCount = LUtil.FormatColorStr(winCount,winCount > 0 and "green" or "red")
	local desStr = string.format(ccClientText(32343),winCount)
	self:SetWndText(self.mDesText,desStr)
	if len <= 0 then
		self:CreateEmptyShow(29101)
	else
		self:RefreshGetReward(list)
	end
end

function UIHarvestPop:InitEvent()
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
end
function UIHarvestPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(32342))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	gModelCrusadeAgainst:OnCrusadeDailyRewardReq()
end
------------------------------------------------------------------
return UIHarvestPop


