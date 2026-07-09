---
--- Created by wzz.
--- DateTime: 2024/6/12 18:09:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBlockMiniGameFail:LWnd
local UIBlockMiniGameFail = LxWndClass("UIBlockMiniGameFail", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBlockMiniGameFail:UIBlockMiniGameFail()
	gLGameAudio:PlaySound("SoundS_26")
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBlockMiniGameFail:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBlockMiniGameFail:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBlockMiniGameFail:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._ref = self:GetWndArg("ref")
	local isWxBs = self._ref.type == 3
	self._isWxBs = isWxBs
	if(isWxBs)then
		CS.ShowObject(self.mBtnBack,false)
	end
	self:InitTexts()
	self:InitEvents()
end

-- 点击下一步
function UIBlockMiniGameFail:OnClickBtnNext()
	local func = function()
		self:WndClose()
		FireEvent(EventNames.BLOCKMINIGAME_RESTART)
	end
	gModelBlockMiniGame:ShowEntryGameMainTips(func)
end

-- 点击击返回
function UIBlockMiniGameFail:OnClickBtnBack()
	self:WndClose()

	GF.ChangeMap("LCityMap")
	-- GF.OpenWndBottom("UIOutts", { childIndex = 1 })
	-- FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.OUTSKIRTS })
	GF.OpenWnd("UIBlockMiniGameLevel")
end

-- 初始事件
function UIBlockMiniGameFail:InitEvents()
	self:SetWndClick(self.mBtnBack, function() self:OnClickBtnBack() end)
	self:SetWndClick(self.mBtnNext, function() self:OnClickBtnNext() end)
end

-- 初始界面化文本
function UIBlockMiniGameFail:InitTexts()
	self:SetWndText(self.mTxtTitle, ccClientText(43503, self._ref.level))
	self:SetWndText(self.mTxtTips, ccClientText(43504))
	self:SetWndButtonText(self.mBtnBack, ccClientText(30205))
	self:SetWndButtonText(self.mBtnNext, ccClientText(43505))


	self:CreateWndEffect(self.mEff, "fx_ui_shibai", "bg", 100)
end

------------------------------------------------------------------
return UIBlockMiniGameFail