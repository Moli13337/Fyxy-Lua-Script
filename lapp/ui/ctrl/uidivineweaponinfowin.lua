---
--- Created by Administrator.
--- DateTime: 2024/11/18 18:03:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineWeaponInfoWin:LWnd
local UIDivineWeaponInfoWin = LxWndClass("UIDivineWeaponInfoWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineWeaponInfoWin:UIDivineWeaponInfoWin()
	self._tabList = {}
	self.addStarPanel = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineWeaponInfoWin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineWeaponInfoWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineWeaponInfoWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
	self:WndEventRecv(EventNames.DIVINE_WEAPON_UPDATE,function()
		self:AddStarPanel()
		self:UpdateTabRed()
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:UpdateTabRed()
	end)
	self:SetWndText(self.mTxtClose,ccClientText(10320))
	self:InitDatas()
	self:UpdateTabList()
	self:OpenChildCtrl()
end

function UIDivineWeaponInfoWin:OnDrawTab(list, item, itemData, index)
	self:SetWndTabText(item,itemData.name,nil,true)
	local state = 1
	if itemData.id == 3 then
		local ref = gModelDivineWeapon:GetDivineWeaponRef(self.refId) or {}
		if not ref.linkGoal or not ref.linkGoal[1] then--and not gModelDivineWeapon:GetDivineWeaponByRefId(ref.linkGoal[1])
			state = 2
		end
	end
	self:SetWndTabStatus(item, state)
	self:SetWndTabIcon(item,itemData.icon,itemData.icon)
	self._tabList[index] = item
	self:SetWndClick(item, function (...)
		if state ==2 then
			GF.ShowMessage(ccClientText(46163))
			return
		end
		self:DoChangeTab(index)
	end)
	self:UpdateRed(index)
end
function UIDivineWeaponInfoWin:AddStarPanel()
	local info = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
	if info and not self.addStarPanel then
		self.addStarPanel = true
		table.insert(self._tabDatas,{id = 2,uiName="UISubDivineStar",icon ="weapon_page7",name=ccClientText(20108)})
		self:UpdateTabList()
		if self._curTabIndex then self:SetWndTabStatus(self._tabList[self._curTabIndex],0,self._curTabIndex) end
	end
end

function UIDivineWeaponInfoWin:OpenChildCtrl()
    local uiName = self._tabDatas[self._curTabIndex].uiName
    if string.isempty(uiName) then return end
	self:CreateChildWnd(self.mChildRoot,self._tabDatas[self._curTabIndex].uiName,self:GetWndArgList())
	self:SetWndTabStatus(self._tabList[self._curTabIndex],0,self._curTabIndex)
end
function UIDivineWeaponInfoWin:UpdateTabList()
    local uiList = self:GetUIScroll("badgeTab")
	uiList:Create(self.mTabScroll,self._tabDatas,function(...) self:OnDrawTab(...) end)
    self._tabUiList = uiList
end
function UIDivineWeaponInfoWin:UpdateTabRed()
	for index, value in ipairs(self._tabDatas) do
		self:UpdateRed(index)
	end
end

function UIDivineWeaponInfoWin:RefreshSelectTable(newIndex,oldIndex)
    self:SetWndTabStatus(self._tabList[oldIndex],1,oldIndex)
	self:SetWndTabStatus(self._tabList[newIndex],0,newIndex)
    self:CreateChildWnd(self.mChildRoot,self._tabDatas[newIndex].uiName,self:GetWndArgList())
end

function UIDivineWeaponInfoWin:DoChangeTab(index)
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

function UIDivineWeaponInfoWin:InitDatas()
	local refId = self:GetWndArg("refId")
	self.refId = refId
    self._tabDatas = {
        {id = 1, uiName="UISubDivineInfo",icon ="weapon_page6", name=ccClientText(46103)},
		{id = 3,uiName="UISubDivineLink",icon ="weapon_page6", name=ccClientText(46120)}
    }
	self:AddStarPanel()
    local openName = self:GetWndArg("name")
    self._curTabIndex = 1--#self._tabDatas
    if openName then
		for k,v in ipairs(self._tabDatas) do
			if v.uiName == openName then
				if v.openId and not gModelFunctionOpen:CheckIsOpened(v.openId,true) then self:WndClose() end
				self._curTabIndex = k
				break
			end
		end
	else
		local isShow = self.addStarPanel and gModelDivineWeapon:DivineWeaponStarRedById(self.refId)
		if isShow and not gModelDivineWeapon:DivineWeaponUpRedById(self.refId) then
			self._curTabIndex = 3
		end
	end
end

function UIDivineWeaponInfoWin:UpdateRed(index)
	local data = self._tabDatas[index]
	local redPoint = self:FindWndTrans(self._tabList[index],"redPoint")
	local isShow = false
	if data.id == 1 then
		local isActivate = gModelDivineWeapon:GetDivineWeaponByRefId(self.refId)
		if isActivate then
			isShow = gModelDivineWeapon:DivineWeaponUpRedById(self.refId)
		else
			isShow =  gModelDivineWeapon:DivineWeaponStarRedById(self.refId)
		end
	elseif data.id ==2 then
		isShow = gModelDivineWeapon:DivineWeaponStarRedById(self.refId)
	elseif data.id == 3 then

	end
	CS.ShowObject(redPoint,isShow)

end
------------------------------------------------------------------
return UIDivineWeaponInfoWin