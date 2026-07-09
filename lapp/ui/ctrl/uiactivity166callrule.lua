---
--- Created by Administrator.
--- DateTime: 2025/6/17 14:53:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActivity166CallRule:LWnd
local UIActivity166CallRule = LxWndClass("UIActivity166CallRule", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActivity166CallRule:UIActivity166CallRule()
	---@type number
	self._btnType = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActivity166CallRule:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActivity166CallRule:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActivity166CallRule:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitTypeBtnList()
	self:RefreshView()
end




function UIActivity166CallRule:GetTypeBtnList()
	return self._btnList or {}
end

function UIActivity166CallRule:OnDrawTypeBtnCell(list, item, itemdata, itempos)
	local BtnTab1 = self:FindWndTrans(item,"BtnTab1")
	self:SetWndTabText(BtnTab1,itemdata.btnName)
	local isSel = self:CheckIsSelTypeBtn(itemdata)
	self:SetWndTabStatus(BtnTab1,isSel and LWnd.StateOn or LWnd.StateOff)
	self:SetWndClick(BtnTab1,function() self:OnClickBtnTab1(itemdata) end)
end

function UIActivity166CallRule:InitEvent()
	--- 返回按钮必备
	-- self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	-- self:SetWndClick(self.mXXXBtn,function() self:OnClickXXXBtnFunc() end)
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end


function UIActivity166CallRule:InitData()
	self._ruleMap = self:GetWndArg("ruleMap") or {}

	local title = self:GetWndArg("title") or ""
	self:SetTextTile(self.mRuleTitle,title)

	local policyTxt = self:GetWndArg("policyTxt")
	self:SetWndText(self.mRuleTxt, policyTxt)

	local showExplainStatus = self:GetWndArg("showExplainStatus") or 0
	local showExplain = showExplainStatus == 1
	if showExplain then
		self:SetWndText(self.mExplainTxt,self:GetWndArg("explainTxt") or "")

		local explainList = self:GetWndArg("explainList")
		self:InitExplainList(explainList)
	end
	CS.ShowObject(self.mExplain,showExplain)


	self._btnType = self:GetWndArg("btnType") or 1

	self._btnList = self:GetWndArg("btnList")
end

function UIActivity166CallRule:OnDrawRuleMoreCell(list,item,itemdata,itempos)
	self:CreateCommonHero(item,itemdata)
end

function UIActivity166CallRule:OnEventXXXXX()
end

function UIActivity166CallRule:OnDrawExplainCell(list, item, itemdata, itempos)
	local UITextTrans = self:FindWndTrans(item,"DescDiv/UIText")
	self:SetWndText(UITextTrans,itemdata)
end

function UIActivity166CallRule:RefreshView()
	local ruleMap = self._ruleMap
	local ruleList = ruleMap[self._btnType]
	self:SetRuleMoreList(ruleList)
end

function UIActivity166CallRule:OnClickBtnTab1(itemdata)
	if self:CheckIsSelTypeBtn(itemdata) then return end

	self._btnType = itemdata.btnType
	local uiTypeBtnList = self._uiTypeBtnList
	local uiList = uiTypeBtnList:GetList()
	uiList:RefreshList()

	self:RefreshView()
end


function UIActivity166CallRule:InitExplainList(list)
	list = list or {}
	local uiList = self:FindUIScroll("uiExplainList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("uiExplainList")
		uiList:Create(self.mExplainList, list, function(...) self:OnDrawExplainCell(...) end,UIItemList.WRAP)
	end
end

function UIActivity166CallRule:OnMsgXXXXX()
end

function UIActivity166CallRule:InitText()
end

function UIActivity166CallRule:OnClickXXXBtnFunc()
end

function UIActivity166CallRule:CheckIsSelTypeBtn(itemdata)
	return self._btnType == itemdata.btnType
end

function UIActivity166CallRule:CreateCommonHero(item,itemdata)
	local IconTrans = self:FindWndTrans(item,"CommonUI/Icon")
	local ProbabilityTxtTrans = self:FindWndTrans(item,"ProbabilityTxt")

	local showItem = itemdata.item
	local itemType,itemId,itemNum = showItem.type or showItem.itemType,showItem.itemId,showItem.count or showItem.itemNum
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
		else
			gModelGeneral:OpenItemInfoTip(itemId,itemNum)
		end
	end)

	self:SetWndText(ProbabilityTxtTrans,itemdata.probability)
end

function UIActivity166CallRule:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	-- self:WndNetMsgRecv(LProtoIds.xxxxx,function(...) self:OnMsgXXXXX(...) end)
end

function UIActivity166CallRule:InitTypeBtnList()
	local list = self:GetTypeBtnList()
	---@type UIItemList
	local uiList = self._uiTypeBtnList
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("uiTypeBtnList")
		self._uiTypeBtnList = uiList
		uiList:Create(self.mTypeBtnList, list, function(...) self:OnDrawTypeBtnCell(...) end)
	end
end


function UIActivity166CallRule:SetRuleMoreList(list)
	CS.ShowObject(self.mRuleMoreList,true)
	list = list or {}
	---@type UIItemList
	local uiRuleMoreList = self._uiRuleMoreList
	if uiRuleMoreList then
		uiRuleMoreList:RefreshList(list)
	else
		uiRuleMoreList = self:GetUIScroll("uiRuleMoreList")
		self._uiRuleMoreList = uiRuleMoreList
		uiRuleMoreList:Create(self.mRuleMoreList,list,function(...) self:OnDrawRuleMoreCell(...) end,UIItemList.WRAP)
	end
	uiRuleMoreList:MoveToPos(1)
end


------------------------------------------------------------------
return UIActivity166CallRule