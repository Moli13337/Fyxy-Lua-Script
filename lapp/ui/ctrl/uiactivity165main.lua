---
--- Created by Administrator.
--- DateTime: 2025/5/22 17:55:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActivity165Main:LWnd
local UIActivity165Main = LxWndClass("UIActivity165Main", LWnd)
------------------------------------------------------------------


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActivity165Main:UIActivity165Main()
	self._btnType = 1
	self._curWndName = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActivity165Main:OnWndClose()
	if self._delayTimer then
		LxTimer.DelayTimeStop(self._delayTimer)
	end
	self._delayTimer = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActivity165Main:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActivity165Main:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitText()
	self:InitStaticData()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
end

function UIActivity165Main:InitData()
	local sid = self:GetWndArg("sid")
	self._sid = sid

	gModelActivity:ReqActivityConfigData(sid)
end

function UIActivity165Main:RefreshView()
	if self._curWndName then
		self:CloseChildByName(self._curWndName)
	end

	local viewMap = self._viewMap
	local viewInfo = viewMap[self._btnType]
	if not viewInfo then return end

	local uiName = viewInfo.uiName
	self:CreateChildWnd(self.mChildRoot,uiName,{sid = self._sid})
end

function UIActivity165Main:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	-- self:WndNetMsgRecv(LProtoIds.xxxxx,function(...) self:OnMsgXXXXX(...) end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
end

function UIActivity165Main:OnMsgXXXXX()
end

function UIActivity165Main:CheckIsSelBtnType(itemdata)
	return self._btnType == itemdata.btnType
end

function UIActivity165Main:InitText()
	self:SetWndText(self.mTxtClose, ccClientText(30205))
end

function UIActivity165Main:InitTabScroll()
	local list = self:GetTabScroll()
	if #list < 2 then return end

	---@type UIItemList
	local uiTabScroll = self._uiTabScroll
	if uiTabScroll then
		uiTabScroll:RefreshList(list)
	else
		uiTabScroll = self:GetUIScroll("mTabScroll")
		self._uiTabScroll = uiTabScroll
		uiTabScroll:Create(self.mTabScroll, list, function(...) self:OnDrawTabScrollCell(...) end)
	end
end

function UIActivity165Main:OnClickXXXBtnFunc()
end

function UIActivity165Main:OnClickTabScrollCell(itemdata)
	if self:CheckIsSelBtnType(itemdata) then return end

	self._btnType = itemdata.btnType

	local uiTabScroll = self._uiTabScroll
	if uiTabScroll then
		local uiList = uiTabScroll:GetList()
		uiList:RefreshList()
	end
	self:RefreshView()
end



function UIActivity165Main:GetTabScroll()
	return self._viewList
end

function UIActivity165Main:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if webData then
		local config = webData.config
		local showMainBtnBg = checknumber(config.showMainBtnBg) or 0
		CS.ShowObject(self.mShowBotBg,showMainBtnBg == 1)
	end

	self:InitTabScroll()

	if self._delayTimer then
		LxTimer.DelayTimeStop(self._delayTimer)
	end
	self._delayTimer = LxTimer.DelayFrameCall(function()
		local wnd = self:IsWndValid()
		if not wnd then return end
		self:RefreshView()
	end)
end

function UIActivity165Main:InitStaticData()
	local viewList = {
		{
			uiName = "UISubActivity165Puzzle",
			btnType = 1,
			btnName = "",
		},
	}
	local viewMap = {}
	for i,v in ipairs(viewList) do
		viewMap[v.btnType] = v
	end
	self._viewMap = viewMap
	self._viewList = viewList
end

function UIActivity165Main:OnDrawTabScrollCell(list, item, itemdata, itempos)
	local isSel = self:CheckIsSelBtnType(itemdata)
	self:SetWndTabStatus(item,isSel and LWnd.StateOn or LWnd.StateOff)
	self:SetWndTabText(item,itemdata.btnName)
	self:SetWndClick(item,function() self:OnClickTabScrollCell(itemdata) end)
end

function UIActivity165Main:InitEvent()
	--- 返回按钮必备
	-- self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	-- self:SetWndClick(self.mXXXBtn,function() self:OnClickXXXBtnFunc() end)
	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end)
end


------------------------------------------------------------------
return UIActivity165Main