---
--- Created by LCM.
--- DateTime: 2024/3/4 15:44:51
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReItemSow:LWnd
local UIReItemSow = LxWndClass("UIReItemSow", LWnd)

UIReItemSow.TYPE_USE = 1
UIReItemSow.TYPE_SHOW = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReItemSow:UIReItemSow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReItemSow:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReItemSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReItemSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
end

function UIReItemSow:InitData()
	local openType = self:GetWndArg("openType")
	if not openType then
		openType = UIReItemSow.TYPE_USE
	end
	self._openType = openType

	self._refId = self:GetWndArg("refId")
	self._showNum = self:GetWndArg("showNum")

end

function UIReItemSow:InitMsg()
end

function UIReItemSow:InitEvent()
end



------------------------------------------------------------------
return UIReItemSow


