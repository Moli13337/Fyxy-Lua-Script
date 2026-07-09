---
--- Created by wzz.
--- DateTime: 2025/3/13 19:58:02
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDefenceWarPause:LWnd
local UIDefenceWarPause = LxWndClass("UIDefenceWarPause", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWarPause:UIDefenceWarPause()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWarPause:OnWndClose()
	gLGpManager:FindDefenceWarGp():ResumeByTimeScale()
	
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWarPause:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------

function UIDefenceWarPause:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	gLGpManager:FindDefenceWarGp():PauseByTimeScale()
	self:InitTexts()
	self:InitEvents()
end

-- 初始事件
function UIDefenceWarPause:InitEvents()
	self:SetWndClick(self.mBtnResume, function() self:OnClickBtnResume() end)
	self:SetWndClick(self.mBtnBack, function() self:OnClickBtnBack() end)
	-- self:SetWndClick(self.mBtnRestart, function() self:OnClickBtnRestart() end)
end

-- 初始界面化文本
function UIDefenceWarPause:InitTexts()
	self:SetWndText(self.mTxtTips, ccClientText(43500))
	self:SetWndButtonText(self.mBtnBack, ccClientText(43502))
	self:SetWndButtonText(self.mBtnResume, ccClientText(43501))
	-- self:SetWndButtonText(self.mBtnRestart, ccClientText(43522))
end

-- 点击继续游戏
function UIDefenceWarPause:OnClickBtnResume()
	self:WndClose()
	local mgr = gLGpManager:FindDefenceWarGp()
	mgr:SetPause(false)
end

-- 点击重新开始
function UIDefenceWarPause:OnClickBtnRestart()
	self:WndClose()
end

-- 点击返回
function UIDefenceWarPause:OnClickBtnBack()
	self:WndClose()

	GF.ChangeMap("LCityMap")
	GF.OpenWnd("UIDefenceWarMain")
end

------------------------------------------------------------------
return UIDefenceWarPause