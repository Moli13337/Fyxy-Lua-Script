---
--- Created by Administrator.
--- DateTime: 2023/10/11 17:44:48
---
------------------------------------------------------------------
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)

local LWnd = LWnd
---@class UIGjKillMon:LWnd
local UIGjKillMon = LxWndClass("UIGjKillMon", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGjKillMon:UIGjKillMon()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGjKillMon:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGjKillMon:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGjKillMon:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._monKillNum = self:GetWndArg("killNum") or 0

	local delayTime = gModelInstance:GetInstancePara("MonKillShowDisappear")
	self:TimerStart("delayHide",delayTime,false,1)

	self:SetStaticContent()
end

function UIGjKillMon:DelayHide()
	local wndTrans = self:GetWndTrans()
	local canvasGroup = wndTrans:GetComponent(typeofCanvasGroup)
	self:TweenSeqCreate("fade",function (seq)
		local alphaTween = canvasGroup:DOFade(0,1)
		seq:Append(alphaTween)
		seq:OnComplete(function ()
			self:WndClose()
		end)
		seq:PlayForward()
		return seq
	end)
end

function UIGjKillMon:OnTimer(key)
	self:DelayHide()
end

function UIGjKillMon:SetStaticContent()
	self:SetWndText(self.mTitle,ccClientText(10775))

	local str = ccClientText(10776)
	local showStr = string.replace(str, tostring(self._monKillNum))

	self:SetWndText(self.mTips1,showStr)

	self:SetWndText(self.mTips2,ccClientText(10777))
end

------------------------------------------------------------------
return UIGjKillMon


