---
--- Created by Ease.
--- DateTime: 2023/10/18 11:31:30
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIYellMitCRule:LWnd
local UIYellMitCRule = LxWndClass("UIYellMitCRule", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIYellMitCRule:UIYellMitCRule()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIYellMitCRule:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIYellMitCRule:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIYellMitCRule:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitUI()
	self:InitEvent()
	self:InitData()
	self:SetUI()
end

function UIYellMitCRule:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mSpecialHelpBtn,function() self:OnClickSpecialHelpBtnFunc() end)
end

function UIYellMitCRule:SetBgImgAndPos(imgTrans, imgPath, offset)
	if (imgPath) then
		self:SetWndEasyImage(imgTrans, imgPath)
		if (offset and not string.isempty(offset)) then
			local pos = LxDataHelper.ParseVector2NotEmpty3(offset)
			self:SetAnchorPos(imgTrans, pos)
		end
	end
	CS.ShowObject(imgTrans, imgPath ~= nil)
end

function UIYellMitCRule:InitData()
	self._ruleData = self:GetWndArg("ruleData")
end

function UIYellMitCRule:SetExplainList()
	local textArr = string.split(self._ruleData.helpTxt,"|")
	local list = textArr or {}
	local uiExplainList = self._uiExplainList
	if uiExplainList then
		uiExplainList:RefreshList(list)
	else
		uiExplainList = self:GetUIScroll("uiExplainList")
		self._uiExplainList = uiExplainList
		uiExplainList:Create(self.mExplainList,list,function(...) self:OnDrawExplainCell(...) end,UIItemList.WRAP)
	end
end

function UIYellMitCRule:SetUI()
	local titleTxt = self:FindWndTrans(self.mRuleTitle,"UIText")
	if(self._ruleData.heroImg)then
		self:SetWndEasyImage(self.mHeroImg,self._ruleData.heroImg)
		self:SetBgImgAndPos(self.mHeroImg,self._ruleData.heroImg,self._ruleData.heroImgPos)
	end
	self:SetBgImgAndPos(self.mBotImg,self._ruleData.botImg,self._ruleData.botImgPos)

	self:SetWndEasyImage(self.mBotImg,self._ruleData.botImg)
	self:SetWndText(titleTxt,self._ruleData.title)

	local policyTxt = self._ruleData.policyTxt
	local isShow = not string.isempty(policyTxt)
	self:SetWndText(self.mRuleTxt, policyTxt)
	CS.ShowObject(self.mPrivate, isShow)
	self:SetWndText(self.mExplainTxt,self._ruleData.helpTitle)
	self:SetExplainList()
	self:SetRuleMoreList()
end

function UIYellMitCRule:CreateCommonHero(item,itemdata)
	local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
	local ProbabilityTxtTrans = self:FindWndTrans(item,"ProbabilityTxt")
	local itemData =  LxDataHelper.ParseItem_4(itemdata.reward)
	if(not itemData)then
		itemData = {
			itemId = 0, itemNum = -1,
		}
	end
	local itemType,itemId,itemNum = itemData.itemType,itemData.itemId,itemData.itemNum
	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(IconTrans)
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	baseClass:EnableShowNum(itemNum > 1)
	baseClass:SetNoShowLv(true)
	baseClass:DoApply()
	self:SetIconClickScale(IconTrans, true)
	self:SetWndClick(IconTrans,function()
		if itemType == 2 then
			gModelGeneral:OpenHeroSimpleTip(itemId,true)
		elseif(itemType == LItemTypeConst.TYPE_GOLEM)then
			itemData.itype = itemType
			itemData.refId = itemId
			gModelGeneral:ShowRewardDetailTip(itemData)
		else
			gModelGeneral:ShowCommonItemTipWnd(itemData)
		end
	end)
	local moreInfo = string.split(itemdata.moreInfo,"|")
	local probabilityIndex = self._ruleData.probabilityIndex or 5
	local probability = moreInfo[probabilityIndex]
	if(probability)then
		--local str = probability * 100 .. "%"
		local str = probabilityIndex == 5 and probability .. "%" or probability
		self:SetWndText(ProbabilityTxtTrans,str)
	end
end

function UIYellMitCRule:SetRuleMoreList()
	CS.ShowObject(self.mRuleMoreList,true)
	local list ={}
	for i, v in pairs(self._ruleData.rewardList) do
		table.insert(list,v)
	end
	local uiRuleMoreList = self._uiRuleMoreList
	if uiRuleMoreList then
		uiRuleMoreList:RefreshList(list)
	else
		uiRuleMoreList = self:GetUIScroll("uiRuleMoreList")
		self._uiRuleMoreList = uiRuleMoreList
		uiRuleMoreList:Create(self.mRuleMoreList,list,function(...) self:OnDrawRuleMoreCell(...) end,UIItemList.WRAP)
	end
end

function UIYellMitCRule:OnDrawExplainCell(list,item,itemdata,itempos)
	local UITextTrans = self:FindWndTrans(item,"DescDiv/UIText")
	self:SetWndText(UITextTrans,itemdata)
end

function UIYellMitCRule:OnDrawRuleMoreCell(list,item,itemdata,itempos)
	self:CreateCommonHero(item,itemdata)
end

------------------------------------------------------------------
return UIYellMitCRule


