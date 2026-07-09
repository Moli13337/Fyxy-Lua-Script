---
--- Created by Administrator.
--- DateTime: 2023/10/1 10:50:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UILoaask:LWnd
local UILoaask = LxWndClass("UILoaask", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UILoaask:UILoaask()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UILoaask:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UILoaask:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndAsync(false)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UILoaask:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:OnWndRefresh()
end


function UILoaask:OnWndRefresh()
	local isShow = self:GetWndArg("isShow")
	CS.ShowObject(self.mMask,isShow)
end


------------------------------------------------------------------
return UILoaask


