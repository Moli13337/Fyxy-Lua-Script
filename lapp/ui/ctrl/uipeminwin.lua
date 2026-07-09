---
--- Created by Administrator.
--- DateTime: 2024/6/14 10:59:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeMinWin:LWnd
local UIPeMinWin = LxWndClass("UIPeMinWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeMinWin:UIPeMinWin()
	self._tabList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeMinWin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeMinWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeMinWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitDatas()
	self:InitTabList()
	self:OpenChildCtrl()

	self:SetWndClick(self.mCloseBtn, 
	function(...) self:WndClose() 
	end)
	self:SetWndClick(self.mBtnWin, 
	function(...) self:WndClose() 
	end)
	self:SetWndText(self.mTxtClose,ccClientText(30205))
end

function UIPeMinWin:RefreshSelectTable(newIndex,oldIndex)
    self:SetWndTabStatus(self._tabList[oldIndex],1,oldIndex)
	self:SetWndTabStatus(self._tabList[newIndex],0,newIndex)

    -- self:CloseChildByName(self._tabDatas[oldIndex].uiName)
    self:CreateChildWnd(self.mChildRoot,self._tabDatas[newIndex].uiName)
end

function UIPeMinWin:DoChangeTab(index)
    if self._curTabIndex == index then return end
	local itemData = self._tabDatas[index]
	if itemData.openId and not gModelFunctionOpen:CheckIsOpened(itemData.openId,true) then return end
    local oldIndex = self._curTabIndex
    self._curTabIndex = index
	self:SetWndTabStatus(self._tabList[oldIndex],1,oldIndex)
	self:SetWndTabStatus(self._tabList[index],0,index)

    -- self:CloseChildByName(self._tabDatas[oldIndex].uiName)
	local uiName = self._tabDatas[index].uiName
    self:CreateChildWnd(self.mChildRoot,uiName)
	local childPetRelation = self:FindChild("UISubPeRelation")
	if childPetRelation and childPetRelation._wndTrans then
		CS.ShowObject(childPetRelation._wndTrans,childPetRelation._wndName==uiName)
	end
end

function UIPeMinWin:OnDrawTab(list, item, itemData, index)
	self:SetWndTabText(item,itemData.name,nil,true)
	local isLock = false
	if itemData.openId and not gModelFunctionOpen:CheckIsOpened(itemData.openId,false) then
		local cfg = GameTable.FeatureOpenRef[itemData.openId]
		if cfg.show<=0 then
			CS.ShowObject(item,false)
			return
		end
		isLock = true
	end
	self:SetWndTabStatus(item, isLock and 2 or 1)
	self:SetWndTabIcon(item,itemData.icon,itemData.icon)
	self._tabList[index] = item
	self:SetWndClick(item, function (...) self:DoChangeTab(index) end)

	if itemData.redId then
		local funcRed =function (isShow)
			local RedPoint=self:FindWndTrans(item,"redPoint")
			CS.ShowObject(RedPoint,isShow)
		end
		self:RegisterRedPointFunc(itemData.redId,funcRed) end
end

function UIPeMinWin:InitTabList()
    local uiList = self:GetUIScroll("badgeTab")
	uiList:Create(self.mTabScroll,self._tabDatas,function(...) self:OnDrawTab(...) end)
    self._tabUiList = uiList
end

function UIPeMinWin:InitDatas()
    self._tabDatas = {
        {uiName="UISubPeResolve",icon ="pet_btn_icon_1", name=ccClientText(43704)},
        {uiName="UISubPeRelation",icon ="pet_btn_icon_3", name=ccClientText(43703),redId = ModelRedPoint.GARDEN_PET_RELATION,openId = 21006001},
        {uiName="UISubPeLink", icon ="pet_btn_icon_4", name=ccClientText(43701),redId = ModelRedPoint.GARDEN_PET_LINK},
        {uiName="UISubPeList", icon ="pet_btn_icon_2", name=ccClientText(43702),redId = ModelRedPoint.GARDEN_PET_LIST},
    }
	local page = self:GetWndArg("page")
	local name = self._tabDatas[page] and self._tabDatas[page].uiName
    local openName = self:GetWndArg("name") or name
    self._curTabIndex = #self._tabDatas
    if openName then
		for k,v in ipairs(self._tabDatas) do
			if v.uiName == openName then
				if v.openId and not gModelFunctionOpen:CheckIsOpened(v.openId,true) then
					self:WndClose()
				end
				self._curTabIndex = k
				break
			end
		end
	end
end

function UIPeMinWin:OpenChildCtrl()
    local uiName = self._tabDatas[self._curTabIndex].uiName
    if string.isempty(uiName) then return end
	self:CreateChildWnd(self.mChildRoot,self._tabDatas[self._curTabIndex].uiName,self:GetWndArgList())
	self:SetWndTabStatus(self._tabList[self._curTabIndex],0,self._curTabIndex)
end



------------------------------------------------------------------
return UIPeMinWin