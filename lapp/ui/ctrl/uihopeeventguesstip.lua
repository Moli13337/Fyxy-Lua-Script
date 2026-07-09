---
--- Created by admin-pc.
--- DateTime: 2024/3/7 11:50:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEventGuessTip:LWnd
local UIHopeEventGuessTip = LxWndClass("UIHopeEventGuessTip", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEventGuessTip:UIHopeEventGuessTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEventGuessTip:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEventGuessTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEventGuessTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
end



------------------------------------------------------------------
return UIHopeEventGuessTip