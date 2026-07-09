---
--- Created by Administrator.
--- DateTime: 2024/11/13 15:07:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineWeaponWin:LWnd
local UIDivineWeaponWin = LxWndClass("UIDivineWeaponWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
---关节动画、骨骼动画、单一网格模型动画（关键帧动画）
------------------------------------------------------------------
function UIDivineWeaponWin:UIDivineWeaponWin()
	self._tabList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineWeaponWin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineWeaponWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineWeaponWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	gModelDivineWeapon:OnDivineWeaponInfoReq()
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
	self:SetWndText(self.mTxtClose,ccClientText(10320))
	self:InitDatas()
	self:InitTabList()
	self:OpenChildCtrl()
end
function UIDivineWeaponWin:OnWndRefresh()
	LWnd.OnWndRefresh(self)
	local indx = self:InitSelectIndex()
	self:DoChangeTab(indx)
end
function UIDivineWeaponWin:InitSelectIndex()
	local openName = self:GetWndArg("name")
	local page = self:GetWndArg("page")
    local indx  = #self._tabDatas
    if openName or page then
		for k,v in ipairs(self._tabDatas) do
			if v.uiName == openName or k == page then
				if v.openId and not gModelFunctionOpen:CheckIsOpened(v.openId,true) then
					self:WndClose()
				end
				indx = k
				break
			end
		end
	end
	return indx
end

function UIDivineWeaponWin:InitDatas()
    self._tabDatas = {
        {uiName="UISubDivineResolve",icon ="weapon_page5", name=ccClientText(41004)},
		{uiName="UISubDivineBook",icon ="weapon_page3",name=ccClientText(46173),redId = gModelRedPoint.DIVINE_WEAPON_BOOK},--showLock = true
		{uiName="UISubDivineResonance",icon ="weapon_page4", name=ccClientText(46101),redId = gModelRedPoint.DIVINE_WEAPON_RESONANCE},
        {uiName="UISubDivineList",icon ="weapon_page2", name=ccClientText(46100),redId = gModelRedPoint.DIVINE_WEAPON_LIST},
		{uiName="UISubDivineCall",icon ="weapon_page1",name=ccClientText(46102),redId = gModelRedPoint.DIVINE_WEAPON_CALL},
    }

	self._curTabIndex = self:InitSelectIndex()
end

function UIDivineWeaponWin:OnDrawTab(list, item, itemData, index)
	self:SetWndTabText(item,itemData.name,nil,true)
	self:SetWndTabStatus(item, 1)
	self:SetWndTabIcon(item,itemData.icon,itemData.icon)
	self._tabList[index] = item
	self:SetWndClick(item, function (...)
		self:DoChangeTab(index) end)
	if itemData.redId then
		self:RegisterRedPointFunc(itemData.redId,function(isShow)
			self:SetRed(item,isShow)
		end)
	end
end
function UIDivineWeaponWin:InitTabList()
	if self._tabUiList then
		self._tabUiList:DrawAllItems()
	else
		local uiList = self:GetUIScroll("badgeTab")
		uiList:Create(self.mTabScroll,self._tabDatas,function(...) self:OnDrawTab(...) end)
		self._tabUiList = uiList
	end
end

function UIDivineWeaponWin:OpenChildCtrl()
    local uiName = self._tabDatas[self._curTabIndex].uiName
    if string.isempty(uiName) then return end
	self:CreateChildWnd(self.mChildRoot,self._tabDatas[self._curTabIndex].uiName,self:GetWndArgList())
	self:SetWndTabStatus(self._tabList[self._curTabIndex],0,self._curTabIndex)
end

function UIDivineWeaponWin:DoChangeTab(index)
    if self._curTabIndex == index then return end
	local itemData = self._tabDatas[index]
	if itemData.openId and not gModelFunctionOpen:CheckIsOpened(itemData.openId,true) then return end
    local oldIndex = self._curTabIndex
    self._curTabIndex = index
	self:SetWndTabStatus(self._tabList[oldIndex],1,oldIndex)
	self:SetWndTabStatus(self._tabList[index],0,index)

	local uiname = self._tabDatas[index].uiName
    local wnd = self:CreateChildWnd(self.mChildRoot,uiname,self:GetWndArgList())
	if wnd and wnd._wndTrans then CS.ShowObject(wnd._wndTrans,true) end
	local childPetRelation = self:FindChild(self._tabDatas[oldIndex].uiName)
	if childPetRelation and childPetRelation._wndTrans then
		CS.ShowObject(childPetRelation._wndTrans,childPetRelation._wndName==uiname)
	end
end

------------------------------------------------------------------
return UIDivineWeaponWin