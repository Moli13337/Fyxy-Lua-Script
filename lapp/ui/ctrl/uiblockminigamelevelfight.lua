---
--- Created by wzz.
--- DateTime: 2024/6/25 12:01:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBlockMiniGameLevelFight:LWnd
local UIBlockMiniGameLevelFight = LxWndClass("UIBlockMiniGameLevelFight", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBlockMiniGameLevelFight:UIBlockMiniGameLevelFight()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBlockMiniGameLevelFight:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBlockMiniGameLevelFight:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBlockMiniGameLevelFight:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	local refId = self:GetWndArg("refId")
	self._ref = gModelBlockMiniGame:GetLevRef(refId)

	self:InitTexts()
	self:InitEvents()
	self:InitItemList()

	self:Refresh()
end

-- 刷新界面
function UIBlockMiniGameLevelFight:Refresh()

end

-- 初始事件
function UIBlockMiniGameLevelFight:InitEvents()
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function() self:OnClickBtnConfirm() end)
end

-- 初始化item列表
function UIBlockMiniGameLevelFight:InitItemList()
	local itemList = LUtil.GetRefItemDataList(self._ref.reward)

	local hadGet = gModelBlockMiniGame:GetPassMaxLev() >= self._ref.refId
	local uiList = UIIconEasyList:New()
	uiList:Create(self, self.mItemList, nil, nil, function(list, item)
		local trans = CS.FindTrans(item, "get")
		CS.ShowObject(trans, hadGet)
	end)
	uiList:SetShowNum(true)
	uiList:SetIconParentPath("itemRoot")
	-- uiList:SetShowExtraNum(true, "itemNum")

	uiList:RefreshList(itemList)
end

-- 初始界面化文本
function UIBlockMiniGameLevelFight:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(43512, self._ref.refId))
	self:SetWndText(self.mTxtTips1, ccClientText(43516, self._ref.time))
	self:SetWndText(self.mTxtTips2, ccClientText(43517))
	self:SetWndText(self.mTxtTips3, ccLngText(self._ref.desc))
	self:SetWndButtonText(self.mBtnConfirm, ccClientText(43518))
end

-- 点击确认按钮
function UIBlockMiniGameLevelFight:OnClickBtnConfirm()
	self:WndClose()

	GF.ChangeMap("LBlockMiniGameMap", nil, {refId = self._ref.refId})
end

------------------------------------------------------------------
return UIBlockMiniGameLevelFight