---
--- Created by BY.
--- DateTime: 2023/10/6 15:03:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEvent6:LWnd
local UIHopeEvent6 = LxWndClass("UIHopeEvent6", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEvent6:UIHopeEvent6()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEvent6:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEvent6:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEvent6:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIHopeEvent6:OnClickConfirm()

end

function UIHopeEvent6:InitCommand()
	self:SetWndText(self.mTitleText,"事件名字")
	self:SetWndButtonText(self.mBtnConfirm,"确定")
end

function UIHopeEvent6:InitMessage()

end

function UIHopeEvent6:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function(...) self:OnClickConfirm() end)
end
------------------------------------------------------------------
return UIHopeEvent6


