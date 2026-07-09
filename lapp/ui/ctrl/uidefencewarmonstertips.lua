---
--- Created by wzz.
--- DateTime: 2025/3/20 21:02:52
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDefenceWarMonsterTips:LWnd
local UIDefenceWarMonsterTips = LxWndClass("UIDefenceWarMonsterTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWarMonsterTips:UIDefenceWarMonsterTips()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWarMonsterTips:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWarMonsterTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDefenceWarMonsterTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._monsterRefId = self:GetWndArg("monsterRefId")

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 刷新界面
function UIDefenceWarMonsterTips:Refresh()
	local monsterRef = gModelDefenceWar:GetMonsterRef(self._monsterRefId)

	self:SetWndText(self.mTxtName, ccLngText(monsterRef.name))
	self:SetWndText(self.mTxtDesc, ccLngText(monsterRef.dses))
end

-- 初始事件
function UIDefenceWarMonsterTips:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)
end

-- 初始界面化文本
function UIDefenceWarMonsterTips:InitTexts()

end

------------------------------------------------------------------
return UIDefenceWarMonsterTips