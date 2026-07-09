---
--- Created by wzz.
--- DateTime: 2024/5/20 21:49:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDraconicSummonRule:LWnd
local UIDraconicSummonRule = LxWndClass("UIDraconicSummonRule", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconicSummonRule:UIDraconicSummonRule()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconicSummonRule:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconicSummonRule:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconicSummonRule:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self.rwdList = self:GetWndArg("rwdList")
	self:InitTexts()
	self:InitEvents()
	self:InitExplainList()
	self:InitItemList()
end

-- 绘制描述列表项
function UIDraconicSummonRule:OnDrawExplainCell(list, item, itemdata, itempos)
	local UITextTrans = self:FindWndTrans(item, "DescDiv/UIText")
	self:SetWndText(UITextTrans, itemdata)
end

-- 物品列表
function UIDraconicSummonRule:InitItemList()
	local list
	if self.rwdList then
		list = self.rwdList
	else
		list = gModelDraconic:GetSummonDetail()
	end
	local uiRuleNormalList = self:GetUIScroll("uiRuleNormalList")
	uiRuleNormalList:Create(self.mRuleNormalList, list, function(...) self:OnDrawItemCell(...) end, UIItemList.WRAP)
end

-- 描述列表
function UIDraconicSummonRule:InitExplainList()
	local list = {}
	if self.rwdList then
		list = {
			ccClientText(46133),
			ccClientText(46134),
			ccClientText(46135),
			ccClientText(46136),
		}
	else
		list = {
			ccClientText(41078),
			ccClientText(41079),
			ccClientText(41080),
			ccClientText(41081),
		}
	end

	local uiExplainList = self:GetUIScroll("uiExplainList")
	uiExplainList:Create(self.mExplainList, list, function(...) self:OnDrawExplainCell(...) end, UIItemList.WRAP)
end

-- 初始界面化文本
function UIDraconicSummonRule:InitTexts()
	self:SetTextTile(self.mRuleTitle, ccClientText(27803))
	self:SetWndText(self.mRuleTxt, ccClientText(41077))
	self:SetWndText(self.mExplainTxt, ccClientText(27804))
end

-- 绘制物品列表项
function UIDraconicSummonRule:OnDrawItemCell(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			itemRoot = CS.FindTrans(item, "CommonUI/Icon"),
			probabilityTxt = CS.FindTrans(item, "ProbabilityTxt"),
		}
		self:SetComponentCache(instanceID, itemCache)
	end
	local num = itemdata.probabilityShow
	if self.rwdList then
		num = math.ceil(num*100000)
		num = num/100000
	end
	self:SetWndText(itemCache.probabilityTxt, num * 100 .. "%")

	local data = LUtil.GetRefItemData(itemdata.reward)
	self:CreateCommonIconImpl(itemCache.itemRoot, data, { showNum = true })
end

-- 初始事件
function UIDraconicSummonRule:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end)
end

------------------------------------------------------------------
return UIDraconicSummonRule