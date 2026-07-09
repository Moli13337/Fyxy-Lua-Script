---
--- Created by BY.
--- DateTime: 2023/10/16 16:40:05
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdMeleeEffPop:LWnd
local UIGdMeleeEffPop = LxWndClass("UIGdMeleeEffPop", LWnd)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdMeleeEffPop:UIGdMeleeEffPop()
	self._onDelEffKey = "onDelEffKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdMeleeEffPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdMeleeEffPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdMeleeEffPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdMeleeEffPop:OnTimer(key)
	if self._onDelEffKey == key then
		CS.ShowObject(self.mPop,true)
		self:SetTowee("key")
	end
end

function UIGdMeleeEffPop:SetTowee(key)
	local seqTween
	self:TweenSeqKill(key)
	if not seqTween then
		seqTween = self:TweenSeqCreate(key,function(seq)
			local canvasGroup = self.mPop:GetComponent(typeofCanvasGroup)
			canvasGroup.alpha = 0
			local tween = canvasGroup:DOFade(1,0.5)
			seq:Append(tween)
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(key)
	end)
end

function UIGdMeleeEffPop:InitEvent()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:SetWndClick(self.mBgImage, function(...)
		local callback = self:GetWndArg("callback")
		if callback then
			callback()
		end
		self:WndClose() end)
end

function UIGdMeleeEffPop:InitMessage()

end

function UIGdMeleeEffPop:InitCommand()
	-- self:CreateWndEffect(self.mEff,"fx_ui_mengzhanshengji","fx_ui_mengzhanshengji",100)
	self:SetWndText(self.mDesText,ccClientText(17971))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	CS.ShowObject(self.mPop,false)
	self:TimerStart(self._onDelEffKey,0.5,false,1)
end
------------------------------------------------------------------
return UIGdMeleeEffPop


