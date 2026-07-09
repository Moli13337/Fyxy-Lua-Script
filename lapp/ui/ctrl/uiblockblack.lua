---
--- Created by Administrator.
--- DateTime: 2023/10/28 18:25:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBlockBlack:LWnd
local UIBlockBlack = LxWndClass("UIBlockBlack", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBlockBlack:UIBlockBlack()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBlockBlack:OnWndClose()
	if self._animTween then
		self._animTween:Kill(false)
		self._animTween = nil
	end

	FireEvent(EventNames.CHECK_POP_WND)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBlockBlack:OnCreate()
	LWnd.OnCreate(self)
	self:SetAutoAdjustNotch(1)
	self:SetWndAsync(false)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBlockBlack:OnStart()
	LWnd.OnStart(self)



	self:InitUI()

	self:InitAnim()
end

function UIBlockBlack:InitAnim()
	local blackTime = self:GetWndArg(1) or 2
	local rootCanvas = self.mBlackRoot

	local tween = YXTween.TweenSequenceIns()
	self._animTween = tween

	if blackTime > 0  then
		rootCanvas.alpha = 0
		local alphaTweenIn = rootCanvas:DOFade(1,blackTime)
		tween:Append(alphaTweenIn)
	else
		rootCanvas.alpha = 1
	end

	local waitInterval = self:GetWndArg(3) or 0.1
	tween:AppendInterval(waitInterval)

	local outBlackTime = self:GetWndArg(2) or 0.5
	local alphaTweenOut = rootCanvas:DOFade(0,outBlackTime)
	tween:Append(alphaTweenOut)

	tween:OnComplete(function ()
		self._animTween = nil
		self:WndClose()
	end)
	tween:PlayForward()
end



------------------------------------------------------------------
return UIBlockBlack


