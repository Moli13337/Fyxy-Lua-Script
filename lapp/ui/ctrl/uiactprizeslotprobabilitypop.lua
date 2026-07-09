---
--- Created by BY.
--- DateTime: 2023/10/12 16:41:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActPrizeSlotProbabilityPop:LWnd
local UIActPrizeSlotProbabilityPop = LxWndClass("UIActPrizeSlotProbabilityPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActPrizeSlotProbabilityPop:UIActPrizeSlotProbabilityPop()
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActPrizeSlotProbabilityPop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActPrizeSlotProbabilityPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActPrizeSlotProbabilityPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIActPrizeSlotProbabilityPop:OnDrawRewardListItem(list, item,itemdata,itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local itemText = self:FindWndTrans(item,"itemText")

	local reward = itemdata.reward
	local prob = itemdata.prob

	self:SetWndText(itemText, prob)

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

function UIActPrizeSlotProbabilityPop:OnDrawGridListItem(list, item, itemdata, itempos)
	local textTrans = self:FindWndTrans(item, "Text")
	local rewardList = self:FindWndTrans(item, "RewardList")
	local rewardListMax = self:FindWndTrans(item, "RewardListMax")

	local layer  = itemdata.layer
	local index  = itemdata.index
	local prob = itemdata.prob
	local poolList = itemdata.poolList or {}
	local InstanceID = item:GetInstanceID()

	local titleStr  = string.replace(ccClientText(27606), layer, index, prob)
	self:SetWndText(textTrans, titleStr)

	local listNum = poolList and #poolList or 0
	local isMax   = listNum > 4
	CS.ShowObject(rewardList, not isMax)
	CS.ShowObject(rewardListMax, isMax)

	local uiList
	if not isMax then
		uiList = self:GetUIScroll(InstanceID.."rewardList")
		if uiList:GetList() then
			uiList:RefreshList(poolList)
		else
			uiList:Create(rewardList,poolList,function (...) self:OnDrawRewardListItem(...)  end)
		end
	else
		uiList = self:GetUIScroll(InstanceID.."rewardListMax")
		if uiList:GetList() then
			uiList:RefreshList(poolList)
		else
			uiList:Create(rewardListMax,poolList,function (...) self:OnDrawRewardListItem(...)  end)
		end
	end
	uiList:EnableScroll(isMax, true)
	uiList:RefreshList(poolList)
end

function UIActPrizeSlotProbabilityPop:InitCommand()
	self:SetWndButtonText(self.mBtnOk, ccClientText(10102))

	local policyTitle  = self:GetWndArg("policyTitle") or ccClientText(23216)
	local policyTxt  = self:GetWndArg("policyTxt") or ""
	local helpTitle  = self:GetWndArg("helpTitle")
	local helpTxt  = self:GetWndArg("helpTxt")
	local turnTipImg = self:GetWndArg("turnTipImg")
	local turnTipPos = self:GetWndArg("turnTipPos")
	local list = self:GetWndArg("list")

	self:SetWndText(self.mLblBiaoti,policyTitle)

	local isShowDesc = not string.isempty(policyTxt)
	if isShowDesc then
		self:SetWndText(self.mDescText, policyTxt)
	end
	CS.ShowObject(self.mDescContent, isShowDesc)

	CS.ShowObject(self.mBtnHelp,helpTxt)
	if helpTxt then
		self:SetWndClick(self.mBtnHelp,function ()
			GF.OpenWnd("UIBzTips",{title = helpTitle,text = helpTxt})
		end)
	end
	if not string.isempty(turnTipImg)then
		local _parent
		local arr = string.split(turnTipImg,"=")
		if arr[1] == "1" then
			_parent = self.mHeroImg
			self:SetWndEasyImage(_parent,arr[2],nil,true)
		elseif arr[1] == "2" then
			_parent = self.mHeroLiHui
			self:CreateWndSpine(_parent,arr[2],"UIActPrizeSlotProbabilityPop_parent",false)
		end
		CS.ShowObject(_parent,true)
		if not string.isempty(turnTipPos)then
			local pos = LxDataHelper.ParseVector2NotEmpty2(turnTipPos)
			self:SetAnchorPos(_parent, pos)
		end
	end

	if not list or #list <= 0 then return end
	local contentList = list
	local uiList = self:GetUIScroll("contentList")
	uiList:Create(self.mContentList,contentList,function (...) self:OnDrawGridListItem(...) end,UIItemList.WRAP)
end
function UIActPrizeSlotProbabilityPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnOk, function(...) self:WndClose() end,LSoundConst.CLICK_BUTTON_COMMON)
end
------------------------------------------------------------------
return UIActPrizeSlotProbabilityPop


