---
--- Created by BY.
--- DateTime: 2023/10/3 12:12:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIExTips:LWnd
local UIExTips = LxWndClass("UIExTips", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIExTips:UIExTips()
	self._delayTimer = "_delayTimer"
	self._closeTimer = "_closeTimer"
	self._tweenKey = "_tweenKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIExTips:OnWndClose()
	self:TweenSeqKill(self._tweenKey)
	if gLGameTouch then gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_BT_WNDCLOSE) end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIExTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIExTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIExTips:OnTimer(key)
	if self._closeTimer == key then
		self:TweenAlpha()
	else
		self:SetPos()
	end
end

function UIExTips:SetPos()
	local follow = self._root
	local target = self.mPosMar:GetComponent(typeofRectTransform)

	local canvasRect =LGameUI.GetUICanvasRoot()
	local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,follow)
	local y = targetPos.y
	local pos = Vector3.New(0,y,0)
	target.localPosition = pos
end

function UIExTips:TweenAlpha()
	local seqTween
	self:TweenSeqKill(self._tweenKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._tweenKey,function(seq)
			local canvasGroup = self.mPosMar:GetComponent(typeofCanvasGroup)
			if canvasGroup then
				local tween = canvasGroup:DOFade(0,0.5)
				seq:Join(tween)
			end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:WndClose()
	end)
end

function UIExTips:InitEvent()
	local op = LGameTouch.TOUCH_BT_WNDCLOSE
	gLGameTouch:TouchRegister(op,LGameTouch.TOUCH_EVT_START,function (screenPos)
		self:WndClose()
	end)
end

function UIExTips:InitCommand()
	self._root = self:GetWndArg("root")
	local title = self:GetWndArg("title")
	local desc = self:GetWndArg("desc")
	local other = self:GetWndArg("other")

	local text = desc
	if other then
		text = LStringUtil.ReplaceStringCommon(text,nil,unpack(other))
		local target = self.mPosMar:GetComponent(typeofRectTransform)
		local pos = Vector3.New(0,20,0)
		target.localPosition = pos
		self:TimerStart(self._closeTimer,2.5,false,1)
	else
		self:TimerStart(self._delayTimer,0.1,false,1)
	end
	self:SetWndText(self.mTitleText,title)

	self:SetWndText(self.mDesText,text)
	local height = self.mDesText.preferredHeight
	height = height + 122
	local dpSizeDelta = self.mPosMar.sizeDelta
	self.mPosMar.sizeDelta = Vector2(dpSizeDelta.x, height)
end
------------------------------------------------------------------
return UIExTips


