---
--- Created by BY.
--- DateTime: 2023/10/20 20:30:39
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISowItemListPop:LWnd
local UISowItemListPop = LxWndClass("UISowItemListPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISowItemListPop:UISowItemListPop()
	self._uiIconEasyList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISowItemListPop:OnWndClose()
	self:ClearCommonIconList(self._uiIconEasyList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISowItemListPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISowItemListPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UISowItemListPop:InitItemList(InstanceID,awardRoot,itemList)
	local uiIconEasyList = self._uiIconEasyList[InstanceID]
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiIconEasyList[InstanceID] = uiIconEasyList
		uiIconEasyList:Create(self, awardRoot)
		--uiIconEasyList:SetIconParentPath("itemRoot")
		uiIconEasyList:EnableScroll(true,true)
	end
	uiIconEasyList:RefreshList(itemList)
end

function UISowItemListPop:InitCommand()
	local title = self:GetWndArg("title")
	local itemList = self:GetWndArg("itemList") or {}
	self:SetWndText(self.mLblBiaoti,title)
	self:InitItemList("UISowItemListPop_mAwardRoot",self.mAwardRoot,itemList)
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(26806))
end

function UISowItemListPop:InitEvent()
	self:SetWndClick(self.mBgImage,function (...)self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function (...)self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm,function (...)self:WndClose() end)
end
------------------------------------------------------------------
return UISowItemListPop


