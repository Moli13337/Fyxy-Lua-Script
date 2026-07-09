---
--- Created by wzz.
--- DateTime: 2024/9/18 21:40:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDesireTrailFastFight:LWnd
local UIDesireTrailFastFight = LxWndClass("UIDesireTrailFastFight", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDesireTrailFastFight:UIDesireTrailFastFight()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDesireTrailFastFight:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDesireTrailFastFight:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDesireTrailFastFight:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTexts()
	self:InitEvents()
	self:PlayEffect()
	self:Refresh()
end

-- 初始界面化文本
function UIDesireTrailFastFight:InitTexts()
	self:SetWndText(self.mTxtTips, ccClientText(42073))
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndText(self.mTxtTips2, ccClientText(45435))
end

-- 播特效
function UIDesireTrailFastFight:PlayEffect()
	self:CreateWndEffect(self.mEff1, "fx_ui_wushendian_wqny_1", 1, 100)
	self:CreateWndEffect(self.mEff2, "fx_ui_wushendian_wqny_2", 2, 100)
end

-- 刷新界面
function UIDesireTrailFastFight:Refresh()
	local itemList = self:GetWndArg("itemList") or {}

	-- 奖励
	self:RefreshItemList(self.mItemList, itemList)
end

-- 初始事件
function UIDesireTrailFastFight:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

-- 初始化item列表
function UIDesireTrailFastFight:RefreshItemList(root, itemList)
	local instanceID = root:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {}
		local uiList = UIIconEasyList:New()
		uiList:Create(self, root)
		uiList:SetShowNum(true)
		uiList:SetIconParentPath("itemRoot")
		-- uiList:SetShowExtraNum(true, "itemNum")

		itemCache.uiList = uiList
		self:SetComponentCache(instanceID, itemCache)
	end
	itemCache.uiList:EnableScroll(true, false)
	itemCache.uiList:RefreshList(itemList)
end

------------------------------------------------------------------
return UIDesireTrailFastFight