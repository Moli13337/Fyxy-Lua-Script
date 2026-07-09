---
--- Created by Administrator.
--- DateTime: 2023/10/1 20:25:17
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAwardDetail:LWnd
local UIAwardDetail = LxWndClass("UIAwardDetail", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAwardDetail:UIAwardDetail()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAwardDetail:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAwardDetail:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAwardDetail:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitEvent()

	self:SetWndButtonText(self.mBtnYellow2,ccClientText(10102))
	self:SetWndText(self.mLblBiaoti,ccClientText(31903))
	self:OnWndRefresh()
end

function UIAwardDetail:OnDrawItem(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootItem = self:FindWndTrans(AniRoot,"item")

	self:CreateCommonIconImpl(AniRootItem,itemdata)
end

function UIAwardDetail:OnWndRefresh()
	local itemList = self:GetWndArg("itemList")
	local intro = self:GetWndArg("intro")

	self:SetWndText(self.mIntro,intro)
	self:CreateUIScrollImpl('itemList',self.mItemList,itemList,function (...)
		self:OnDrawItem(...)
	end,UIItemList.SUPER_GRID)
end

function UIAwardDetail:InitEvent()
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
	self:SetWndClick(self.mBtnYellow2,function () self:WndClose() end)
	self:SetWndClick(self.mMask,function () self:WndClose() end)
end

------------------------------------------------------------------
return UIAwardDetail