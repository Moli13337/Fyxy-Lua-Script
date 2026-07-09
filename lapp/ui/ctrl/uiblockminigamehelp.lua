---
--- Created by wzz.
--- DateTime: 2024/6/13 16:43:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBlockMiniGameHelp:LWnd
local UIBlockMiniGameHelp = LxWndClass("UIBlockMiniGameHelp", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBlockMiniGameHelp:UIBlockMiniGameHelp()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBlockMiniGameHelp:OnWndClose()
	LWnd.OnWndClose(self)

	local func = self:GetWndArg("callback")
	if func then
		func()
	end
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBlockMiniGameHelp:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBlockMiniGameHelp:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	self:InitTexts()
	self:InitEvents()
end

-- 初始事件
function UIBlockMiniGameHelp:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

-- 初始界面化文本
function UIBlockMiniGameHelp:InitTexts()
	self:SetWndText(self.mTxtTips1, ccClientText(43507))
	self:SetWndText(self.mTxtTips2, ccClientText(43508))
	self:SetWndText(self.mTxtTips3, ccClientText(43509))

	if self._isEnus then
		self:SetWndText(self.mTxtTips4_enus, ccClientText(43510))
	else
		self:SetWndText(self.mTxtTips4, ccClientText(43510))

	end
end

------------------------------------------------------------------
return UIBlockMiniGameHelp