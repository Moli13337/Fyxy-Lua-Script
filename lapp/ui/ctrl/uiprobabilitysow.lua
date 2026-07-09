---
--- Created by BY.
--- DateTime: 2023/10/16 10:53:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIProbabilitySow:LWnd
local UIProbabilitySow = LxWndClass("UIProbabilitySow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIProbabilitySow:UIProbabilitySow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIProbabilitySow:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIProbabilitySow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIProbabilitySow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitList()

	self:SetStaticContent()
end

function UIProbabilitySow:InitEvent()
	self:SetWndClick(self.mBg,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIProbabilitySow:OnDrawHeroCell(list, item, itemdata, itempos, fromHeadTail)
	local root = self:FindWndTrans(item,"root")
	local rootItem = self:FindWndTrans(root,"item")
	local itemText = self:FindWndTrans(rootItem,"text")
	local itemText1 = self:FindWndTrans(rootItem,"text1")

	local name = ccLngText(itemdata.name)
	local num = tonumber(itemdata.num) / 100 .. "%"
	self:SetWndText(itemText,name)
	self:InitTextSizeWithLanguage(itemText, -4)
	self:InitTextLineWithLanguage(itemText, -30)
	self:SetWndText(itemText1,num)
end

function UIProbabilitySow:SetStaticContent()
	self:SetWndText(self.mTypeName,ccClientText(16500))  -- 概率一览
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mIntro,ccClientText(14618))
end

function UIProbabilitySow:InitData()
	local itemList = self:GetWndArg("itemList")
	self._itemList = itemList
end

function UIProbabilitySow:InitList()
	local uiList = self._uiList
	if not uiList then
		uiList = self:GetUIScroll("uiList")
		uiList:Create(self.mRuleList,self._itemList,function(...) self:OnDrawHeroCell(...) end)
		uiList:EnableScroll(true,false)
		self._uiList = uiList
	else
		uiList:RefreshList(self._itemList)
	end
end
------------------------------------------------------------------
return UIProbabilitySow


