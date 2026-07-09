---
--- Created by BY.
--- DateTime: 2023/10/11 17:10:43
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBackin:LWnd
local UIBackin = LxWndClass("UIBackin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBackin:UIBackin()
	self._tabTransList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBackin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBackin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBackin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIBackin:ListItem(list, item, itemdata, itempos)
	local btnTab = CS.FindTrans(item,"BtnTab12_1")
	local redPoint = CS.FindTrans(item,"redPoint")
	local redPointRefId = itemdata.redPointRefId
	local isShowRed = false
	if redPointRefId > 0 then
		isShowRed = gModelRedPoint:CheckShowRedPoint(redPointRefId)
	end
	CS.ShowObject(redPoint,isShowRed)
	local refId = itemdata.refId
	self._tabTransList[refId] = btnTab
	self:SetWndTabText(btnTab,ccLngText(itemdata.name))
	self:SetWndTabStatus(btnTab, 1)
	self:SetWndClick(item,function  ()
		self:OpenChildWnd(refId)
	end)
end

function UIBackin:InitCommand()
	self._page = self:GetWndArg("page") or 1
	self:RefreshTab()
	self:SetWndText(self.mCloseTip,ccClientText(17003))
end
function UIBackin:OpenTypePage(refId)
	local ref = gModelBackflow:RegressionBackflowRefByRefId(refId)
	if not ref then
		return
	end
	local type = ref.type
	if type == 5 then
		local isFight = gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_TYPE_23)
		if isFight then
			--优先进入当前的战斗中
			gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TYPE_23,{})
			return
		end
	end
	self:CreateChildWnd(self.mChildRoot,"WndChildBackflowType"..type,{refId = refId})
end

function UIBackin:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
end
---打开子界面
function UIBackin:OpenChildWnd(refId)
	local _refId = self._refId or 0
	for i, v in pairs(self._tabTransList) do
		self:SetWndTabStatus(v, i == refId and 0 or 1)
	end
	if refId == _refId then
		return
	end
	self:CloseAllChild()
	self:OpenTypePage(refId)
	self._refId = refId
end

function UIBackin:OnTryTcpReconnect()

end

function UIBackin:RefreshTab()
	local list = gModelBackflow:RegressionBackflowRef()
	local _uiTabList = self._uiTabList
	if _uiTabList then
		_uiTabList:RefreshList(list)
	else
		_uiTabList = self:GetUIScroll("tabList")
		_uiTabList:Create(self.mTabScroll,list,function (...) self:ListItem(...) end)
		self._uiTabList = _uiTabList
	end
	local _page = self._page
	local refId = self._refId
	if _page then
		self:OpenChildWnd(list[_page].refId)
		self._page = nil
	elseif refId then
		self:OpenChildWnd(refId)
	end
end

function UIBackin:InitMessage()
	self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshTab() end)
end
------------------------------------------------------------------
return UIBackin


