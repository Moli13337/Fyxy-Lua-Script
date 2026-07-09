---
--- Created by Administrator.
--- DateTime: 2025/5/30 16:39:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandWin:LWnd
local UIBrandWin = LxWndClass("UIBrandWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandWin:UIBrandWin()

	self._tabList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandWin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandWin:OnStart()
	LWnd.OnStart(self)
	gModelBadge:BadgeDropInfoReq()
	self:InitUI()
	local jumpCallback = self:GetWndArg("jumpCallback")
	if jumpCallback then
		jumpCallback()
	end
	self:InitDatas()
	self:InitTabList()
	self:OpenChildCtrl()
	self:SetWndClick(self.mCloseBtn,function(...) self:WndCloseAndBack() end)
	self:SetWndClick(self.mBtnWin,function(...) self:WndClose() end)
	self:SetWndText(self.mTxtClose,ccClientText(30205))
end

function UIBrandWin:DoChangeTab(index)
	if self._curTabIndex == index then return end
	local itemData = self._tabDatas[index]
	if itemData.openId and not gModelFunctionOpen:CheckIsOpened(itemData.openId,true) then return end
	local oldIndex = self._curTabIndex
	self._curTabIndex = index
	CS.ShowObject(self.mImgTitleBg,self._tabDatas[index].showTitle)
	self:SetWndTabStatus(self._tabList[oldIndex],1,oldIndex)
	self:SetWndTabStatus(self._tabList[index],0,index)
	self:SetWndText(self.mTxtTitle,self._tabDatas[self._curTabIndex].name)
	local uiName = self._tabDatas[index].uiName
	self:CreateChildWnd(self.mChildRoot,uiName)
	self:ChangeChildWnd(oldIndex,index)
end
function UIBrandWin:InitDatas()
	self._tabDatas = {
		{uiName="UISubBrand",icon ="jewelry_icon_4", name=ccClientText(47545),showTitle = true,redId = gModelRedPoint.BADGE_BADGE_TAB},
		{uiName="UISubBrandYell",icon ="jewelry_icon_3", name=ccClientText(47568),showTitle = false,redId =gModelRedPoint.BADGE_CALL_TAB, openId = 37000003},
	}
	local page = self:GetWndArg("page")
	local name = self._tabDatas[page] and self._tabDatas[page].uiName
	local openName = self:GetWndArg("name") or name
	self._curTabIndex = 1
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
	self:SetWndText(self.mTxtTitle,self._tabDatas[self._curTabIndex].name)
	CS.ShowObject(self.mImgTitleBg,self._tabDatas[self._curTabIndex].showTitle)
end

function UIBrandWin:ChangeChildWnd(oldIndex,newIndex)
	local newUiName = self._tabDatas[newIndex].uiName
	local oldUiName = self._tabDatas[oldIndex].uiName
	local childPetRelation = self:FindChild(oldUiName)
	local childPetRelationNew = self:FindChild(newUiName)
	if childPetRelation and childPetRelation._wndTrans then
		CS.ShowObject(childPetRelation._wndTrans,false)
	end
	if childPetRelationNew and childPetRelationNew._wndTrans then
		CS.ShowObject(childPetRelationNew._wndTrans,true)
	end
end
function UIBrandWin:OnWndRefresh()
	LWnd.OnWndRefresh(self)
	local oldTabIndx = self._curTabIndex
	self:InitDatas()
	if oldTabIndx~=self._curTabIndex then
		self:ChangeChildWnd(oldTabIndx,self._curTabIndex)
	end
	self:InitTabList()
	self:OpenChildCtrl()

end

function UIBrandWin:InitTabList()
	local uiList = self:GetUIScroll("badgeTab")
	uiList:Create(self.mTabScroll,self._tabDatas,function(...) self:OnDrawTab(...) end)
	self._tabUiList = uiList
end

function UIBrandWin:OnDrawTab(list, item, itemData, index)
	self:SetWndTabText(item,itemData.name,nil,nil)
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
		self:RegisterRedPointFunc(itemData.redId,funcRed)
	end
end

function UIBrandWin:OpenChildCtrl()
	local uiName = self._tabDatas[self._curTabIndex].uiName
	if string.isempty(uiName) then return end
	self:CreateChildWnd(self.mChildRoot,self._tabDatas[self._curTabIndex].uiName,self:GetWndArgList())
	self:SetWndTabStatus(self._tabList[self._curTabIndex],0,self._curTabIndex)
end
------------------------------------------------------------------
return UIBrandWin