---
--- Created by Administrator.
--- DateTime: 2025/6/11 20:21:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandYellRule:LWnd
local UIBrandYellRule = LxWndClass("UIBrandYellRule", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandYellRule:UIBrandYellRule()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandYellRule:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandYellRule:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandYellRule:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:UpdatePanel()
	self:InitExplainList()
	self:InitRuleMoreList()
end


function UIBrandYellRule:OnDrawRuleMoreNewCell(list,item,itemdata,itempos)
	local StarDesc = self:FindWndTrans(item,"TopDiv/StarDesc")
	local InRuleList = self:FindWndTrans(item,"InRuleList")
	self:SetWndText(StarDesc,itemdata.showKindStr)
	self:CreateInRuleList(InRuleList,itemdata.jackpotList)
end

function UIBrandYellRule:InitExplainList()
	local list = {}
	local desc = string.split(ccClientText(47574),"|")
	for _, value in ipairs(desc) do
		table.insert(list,{str = value})
	end
	local isEmpty = list== nil or #list == 0
	CS.ShowObject(self.mExplain,not isEmpty)

	local height = isEmpty and 690 or 850
	local width = self.mBg.rect.width
	self.mBg.sizeDelta = Vector2.New(width,height)
	if isEmpty then return end

	list = list or {}
	local uiExplainList = self._uiExplainList
	if uiExplainList then
		uiExplainList:RefreshList(list)
	else
		uiExplainList = self:GetUIScroll("badgeCallRule")
		self._uiExplainList = uiExplainList
		uiExplainList:Create(self.mExplainList,list,function(...) self:OnDrawExplainCell(...) end,UIItemList.WRAP)
	end
end
function UIBrandYellRule:GetRuleMoreList()
	local luckRef = GameTable.BadgeLuckRef
	local list = {}
	local showType = 0
	local typeRate = {}
	local rates = string.split(ccClientText(47576),"|")
	for _, value in ipairs(rates) do
		local data = LxDataHelper.ParseResConfig(value,":")
		typeRate[data.resType] = data.resName
	end
	for _, value in pairs(luckRef) do
		showType = value.showType
		if not list[showType] then list[showType] = {} end
		table.insert(list[showType],value)
	end
	local listRule = {}
	for sType, value in pairs(list) do
		table.sort(value,function(a, b) return a.refId>b.refId end)
		table.insert(listRule,{quality = sType,showKindStr = typeRate[sType],jackpotList = value})
	end
	table.sort(listRule,function(a, b) return a.quality<b.quality end)
	return listRule
end

function UIBrandYellRule:InitRuleMoreList()
	local list = self:GetRuleMoreList()

	local uiRuleMoreList = self._uiRuleMoreList
	if uiRuleMoreList then
		uiRuleMoreList:RefreshList(list)
	else
		uiRuleMoreList = self:GetUIScroll("uiRuleMoreList")
		self._uiRuleMoreList = uiRuleMoreList
		uiRuleMoreList:Create(self.mRuleMoreList,list,function(...) self:OnDrawRuleMoreNewCell(...) end)
	end
	uiRuleMoreList:EnableScroll(true)
end

function UIBrandYellRule:UpdatePanel()
	self:SetWndText(self.mRuleTxt,ccClientText(47572))
	self:SetTextTile(self.mRuleTitle,ccClientText(11614))
	self:SetTextTile(self.mExplainTxt,ccClientText(27804))
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)
end

function UIBrandYellRule:OnDrawRuleMoreCell(list,item,itemdata,itempos)
	local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
	local ProbabilityTxtTrans = self:FindWndTrans(item,"ProbabilityTxt")

	local reward = LxDataHelper.ParseItem_4(itemdata.reward)
	local itemType,itemId,itemNum = reward.itemType,reward.itemId,reward.itemNum
	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(IconTrans)
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	baseClass:EnableShowNum(itemNum>0)
	baseClass:SetNoShowLv(true)
	baseClass:DoApply()

	self:SetIconClickScale(IconTrans, true)

	self:SetWndClick(IconTrans,function()
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end)

	local show = false--itemdata.show
	if show then
		local probability = itemdata.showWeight--probability
		local str
		if probability then
			--保留5位小数
			str = (math.floor(probability * 10000000) /10000000) * 100 .. "%"
		else
			str = itemdata.probabilityStr
		end
		self:SetWndText(ProbabilityTxtTrans,str)
	end
	CS.ShowObject(ProbabilityTxtTrans,show)
end

function UIBrandYellRule:CreateInRuleList(listTrans,list)
	local key = listTrans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(listTrans,list,function(...) self:OnDrawRuleMoreCell(...) end)
	end
end

function UIBrandYellRule:OnDrawExplainCell(list,item,itemdata,itempos)
	local UITextTrans = self:FindWndTrans(item,"DescDiv/UIText")
	self:SetWndText(UITextTrans,itemdata.str)
end
------------------------------------------------------------------
return UIBrandYellRule