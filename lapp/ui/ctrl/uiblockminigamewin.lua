---
--- Created by wzz.
--- DateTime: 2024/6/12 18:06:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBlockMiniGameWin:LWnd
local UIBlockMiniGameWin = LxWndClass("UIBlockMiniGameWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBlockMiniGameWin:UIBlockMiniGameWin()
	gLGameAudio:PlaySound("SoundS_25")
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBlockMiniGameWin:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBlockMiniGameWin:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBlockMiniGameWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._ref = self:GetWndArg("ref")
	self._isFirstPass = self:GetWndArg("isFirstPass")

	local isWxBs = self._ref.type == 3
	self._isWxBs = isWxBs
	if(isWxBs)then
		CS.ShowObject(self.mBtnBack,false)
	end

	self:InitTexts()
	self:InitEvents()
	self:InitItemList()
end

-- 点击下一步
function UIBlockMiniGameWin:OnClickBtnNext()
	if(self._isWxBs)then
		gModelBlockMiniGame:SetIsOutFiveMin(true)
	end
	local func = function()
		self:WndClose()
		local lev = self._ref.refId
		local nextLev = gModelBlockMiniGame:GetNextLev(lev)
		if(self._isWxBs and nextLev == lev)then
			nextLev = gModelBlockMiniGame:GetWXBSFirstRefId()
		end
		if nextLev == lev then
			self:OnClickBtnBack()
			return
		end
		FireEvent(EventNames.BLOCKMINIGAME_RESTART, nextLev)
	end
	gModelBlockMiniGame:ShowEntryGameMainTips(func)
end

-- 初始物品列表
function UIBlockMiniGameWin:InitItemList()
	CS.ShowObject(self.mTxtTips.parent, self._isFirstPass)
	if not self._isFirstPass then
		return
	end

	local itemList = LUtil.GetRefItemDataList(self._ref.reward)
	local uiList = UIIconEasyList:New()
	uiList:Create(self, self.mItemList)
	uiList:SetShowNum(true)
	uiList:SetIconParentPath("itemRoot")

	uiList:RefreshList(itemList)
end


-- 初始事件
function UIBlockMiniGameWin:InitEvents()
	self:SetWndClick(self.mBtnBack, function() self:OnClickBtnBack() end)
	self:SetWndClick(self.mBtnNext, function() self:OnClickBtnNext() end)
end

-- 点击击返回
function UIBlockMiniGameWin:OnClickBtnBack()
	self:WndClose()

	GF.ChangeMap("LCityMap")
	-- GF.OpenWndBottom("UIOutts", { childIndex = 1 })
	-- FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.OUTSKIRTS })
	GF.OpenWnd("UIBlockMiniGameLevel")
end

-- 初始界面化文本
function UIBlockMiniGameWin:InitTexts()
	self:SetWndText(self.mTxtTitle, ccClientText(43503, self._ref.level))
	self:SetWndText(self.mTxtTips, ccClientText(43521))
	self:SetWndButtonText(self.mBtnBack, ccClientText(30205))
	self:SetWndButtonText(self.mBtnNext, ccClientText(43520))


	self:CreateWndEffect(self.mEff, "fx_ui_shengli", "bg", 100)
end

------------------------------------------------------------------
return UIBlockMiniGameWin