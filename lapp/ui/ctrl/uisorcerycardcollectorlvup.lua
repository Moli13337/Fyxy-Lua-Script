---
--- Created by BY.
--- DateTime: 2022/7/27 11:29:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISorceryCardCollectorLvUp:LWnd
local UISorceryCardCollectorLvUp = LxWndClass("UISorceryCardCollectorLvUp", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISorceryCardCollectorLvUp:UISorceryCardCollectorLvUp()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISorceryCardCollectorLvUp:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISorceryCardCollectorLvUp:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISorceryCardCollectorLvUp:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UISorceryCardCollectorLvUp:ArrtListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local icon = self:FindWndTrans(root,"Icon")
	local nameText = self:FindWndTrans(root,"NameText")
	local addText = self:FindWndTrans(root,"AddText")

	local iconStr = gModelHero:GetAttributeIconById(itemdata.refId)
	local nameStr = gModelHero:GetAttributeNameById(itemdata.refId)
	local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(itemdata.refId,itemdata.numType,itemdata.value)
	self:SetWndEasyImage(icon,iconStr)
	self:SetWndText(nameText,nameStr)
	self:SetWndText(addText,valueStr)
end
function UISorceryCardCollectorLvUp:InitCommand()
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	local oldRefId = self:GetWndArg("oldRefId")
	local newRefId = self:GetWndArg("newRefId")

	local oldRef = gModelSorceryCard:GetCollectLevelRefByRefId(oldRefId)
	local newRef = gModelSorceryCard:GetCollectLevelRefByRefId(newRefId)
	if not oldRef or not newRef then return end

	self:SetWndEasyImage(self.mCollector1Icon,oldRef.icon)
	self:SetWndText(self.mCollector1Text,ccLngText(oldRef.name))
	local arrt1List = LUtil.GetRefAttrData(oldRef.attr)
	local _arrt1UiList = self:GetUIScroll("mArrt1Scroll_UISorceryCardCollectorLvUp")
	_arrt1UiList:Create(self.mArrt1Scroll,arrt1List,function(...) self:ArrtListItem(...) end)
	_arrt1UiList:EnableScroll(#arrt1List > 3,false)

	self:SetWndEasyImage(self.mCollector2Icon,newRef.icon)
	self:SetWndText(self.mCollector2Text,ccLngText(newRef.name))
	local arrt2List = LUtil.GetRefAttrData(newRef.attr)
	local _arrt2UiList = self:GetUIScroll("mArrt2Scroll_UISorceryCardCollectorLvUp")
	_arrt2UiList:Create(self.mArrt2Scroll,arrt2List,function(...) self:ArrtListItem(...) end)
	_arrt2UiList:EnableScroll(#arrt2List > 3,false)
end

function UISorceryCardCollectorLvUp:InitEvent()
	self:SetWndClick(self.mBgImage,function ()self:WndClose() end)
end
------------------------------------------------------------------
return UISorceryCardCollectorLvUp


