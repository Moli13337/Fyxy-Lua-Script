---
--- Created by Administrator.
--- DateTime: 2026/2/10 18:25:52
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAct172Tips:LWnd
local UIAct172Tips = LxWndClass("UIAct172Tips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAct172Tips:UIAct172Tips()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAct172Tips:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAct172Tips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAct172Tips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitCommon()
end

function UIAct172Tips:InitData()

end

function UIAct172Tips:InitEvent()
	self:SetWndClick(self.mMaskCell, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mCloseBtn1, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnCancel, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnGo, function()
		self:OnClickGo()
	end)
end

function UIAct172Tips:InitCommon()
	self:SetWndText(self.mTitle1, ccClientText(20911))
	self:SetWndButtonText(self.mBtnCancel,ccClientText(43838))
	self:SetWndButtonText(self.mBtnGo,ccClientText(20307))
	self:SetWndText(self.mContent1, ccClientText(47800))
end

function UIAct172Tips:OnClickGo()
	GF.OpenWndBottom("UIHuiYPay", { page = 2 })
	self:WndClose()
end

------------------------------------------------------------------
return UIAct172Tips