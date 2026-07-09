---
--- Created by BY.
--- DateTime: 2023/10/29 14:51:46
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActKeyAwardPop:LWnd
local UIActKeyAwardPop = LxWndClass("UIActKeyAwardPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActKeyAwardPop:UIActKeyAwardPop()
	self._uiIconEasyList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActKeyAwardPop:OnWndClose()
	self:ClearCommonIconList(self._uiIconEasyList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActKeyAwardPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActKeyAwardPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIActKeyAwardPop:InitItemList(InstanceID,awardRoot,itemList)
	local uiIconEasyList = self._uiIconEasyList[InstanceID]
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiIconEasyList[InstanceID] = uiIconEasyList
		uiIconEasyList:Create(self, awardRoot)
		uiIconEasyList:EnableScroll(false,false)
	end
	uiIconEasyList:RefreshList(itemList)
end

function UIActKeyAwardPop:ListItem(list,item, itemdata, itempos)
	local text = self:FindWndTrans(item,"UIText")
	local awardRoot = self:FindWndTrans(item,"AwardRoot")

	self:SetWndText(text,itemdata.title)
	local itemList = itemdata.itemList or {}
	local InstanceID = item:GetInstanceID()
	self:InitItemList(InstanceID,awardRoot,itemList)
end

function UIActKeyAwardPop:InitCommand()
	local para = self:GetWndArg("para")
	if not para then return end
	local title = para.title
	self:SetWndText(self.mLblBiaoti,title)
	local list = para.list
	local _uiList = self:GetUIScroll("ActivityAnswerAwardPop_mCellScroll")
	_uiList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
	_uiList:EnableScroll(true,false)
end

function UIActKeyAwardPop:InitEvent()
	self:SetWndClick(self.mBg, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
end
------------------------------------------------------------------
return UIActKeyAwardPop


