---
--- Created by wzz.
--- DateTime: 2024/6/11 17:05:16
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBlockMiniGamePause:LWnd
local UIBlockMiniGamePause = LxWndClass("UIBlockMiniGamePause", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBlockMiniGamePause:UIBlockMiniGamePause()
	FireEvent(EventNames.BLOCKMINIGAME_PAUSE)
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBlockMiniGamePause:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBlockMiniGamePause:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBlockMiniGamePause:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTexts()
	self:InitEvents()
end

-- 点击重新开始
function UIBlockMiniGamePause:OnClickBtnRestart()
	GF.CloseWndByName("UIBlockMiniGameReady")
	self:WndClose()
	local type = self._ref and self._ref.type or nil
	local ref = gModelBlockMiniGame:GetCurLevRef(type)
	FireEvent(EventNames.BLOCKMINIGAME_RESTART, ref.refId)
end

-- 初始事件
function UIBlockMiniGamePause:InitEvents()
	self:SetWndClick(self.mBtnResume, function() self:OnClickBtnResume() end)
	self:SetWndClick(self.mBtnBack, function() self:OnClickBtnBack() end)
	self:SetWndClick(self.mBtnRestart, function() self:OnClickBtnRestart() end)
end

-- 点击继续游戏
function UIBlockMiniGamePause:OnClickBtnResume()
	self:WndClose()
	FireEvent(EventNames.BLOCKMINIGAME_RESUME)
end

-- 初始界面化文本
function UIBlockMiniGamePause:InitTexts()
	self:SetWndText(self.mTxtTips, ccClientText(43500))
	self:SetWndButtonText(self.mBtnBack, ccClientText(43502))
	self:SetWndButtonText(self.mBtnResume, ccClientText(43501))
	self:SetWndButtonText(self.mBtnRestart, ccClientText(43522))
end

-- 点击返回
function UIBlockMiniGamePause:OnClickBtnBack()
	GF.CloseWndByName("UIBlockMiniGameReady")
	self:WndClose()

    local wnd = GF.FindFirstWndByName("UIBlockMiniGame")
	if wnd then
		local useTime, id = wnd:GetUseTime()
		gModelBlockMiniGame:ExitGame(id, useTime)
	end
	GF.ChangeMap("LCityMap")
	GF.OpenWnd("UIBlockMiniGameLevel")
end



------------------------------------------------------------------
return UIBlockMiniGamePause