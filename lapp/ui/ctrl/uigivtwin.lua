---
--- Created by Administrator.
--- DateTime: 2024/4/23 22:32:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGivtWin:LWnd
local UIGivtWin = LxWndClass("UIGivtWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGivtWin:UIGivtWin()
	self._tabList = {}
	self._curTabIndex = 1
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGivtWin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGivtWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGivtWin:OnStart()
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

function UIGivtWin:OnWndRefresh()
	LWnd.OnWndRefresh(self)
	local oldIndex = self._curTabIndex
	self:InitDatas()
	local newIndex = self._curTabIndex
	self:RefreshSelectTable(newIndex,oldIndex)

end

function UIGivtWin:InitTabList()
    local uiList = self:GetUIScroll("badgeTab")
	uiList:Create(self.mTabScroll,self._tabDatas,function(...) self:OnDrawTab(...) end)
    self._tabUiList = uiList
end

function UIGivtWin:OnDrawTab(list, item, itemData, index)
	self:SetWndTabText(item,itemData.name,nil,true)
	self:SetWndTabStatus(item, 1)
	self._tabList[index] = item
	self:SetWndClick(item, function (...) self:DoChangeTab(index) end)

	local funcRed =function (isShow)
		local RedPoint=self:FindWndTrans(item,"redPoint")
		CS.ShowObject(RedPoint,isShow)
	end
	self:RegisterRedPointFunc(itemData.redId,funcRed)
end

function UIGivtWin:DoChangeTab(index)
    if self._curTabIndex == index then return end
    local oldIndex = self._curTabIndex
    self._curTabIndex = index
	self:SetWndTabStatus(self._tabList[oldIndex],1,oldIndex)
	self:SetWndTabStatus(self._tabList[index],0,index)

    self:CloseChildByName(self._tabDatas[oldIndex].uiName)
    self:CreateChildWnd(self.mChildRoot,self._tabDatas[index].uiName)
end

function UIGivtWin:OpenChildCtrl()
    local uiName = self._tabDatas[self._curTabIndex].uiName
    if string.isempty(uiName) then return end
	self:CreateChildWnd(self.mChildRoot,self._tabDatas[self._curTabIndex].uiName,{chapterId = self:GetWndArg("chapterId")})
	self:SetWndTabStatus(self._tabList[self._curTabIndex],0,self._curTabIndex)
end

function UIGivtWin:InitDatas()
    self._tabDatas = {
        {uiName="", name="羁绊",redId = ModelRedPoint.HOLY_LAND_TABBAR},
    }

    local openName = self:GetWndArg("name") or ""
    self._curTabIndex = 1
    for k,v in ipairs(self._tabDatas) do
        if v.uiName == openName then
            self._curTabIndex = k
        end
    end
end

function UIGivtWin:RefreshSelectTable(newIndex,oldIndex)
    self:SetWndTabStatus(self._tabList[oldIndex],1,oldIndex)
	self:SetWndTabStatus(self._tabList[newIndex],0,newIndex)

    self:CloseChildByName(self._tabDatas[oldIndex].uiName)
    self:CreateChildWnd(self.mChildRoot,self._tabDatas[newIndex].uiName)
end


------------------------------------------------------------------
return UIGivtWin