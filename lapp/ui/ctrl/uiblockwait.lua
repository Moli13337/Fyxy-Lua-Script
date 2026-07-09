---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
-- 多久后开始阻挡点击
local WAIT_START_MASK_TIME = 1
-- 多久后开始显示菊花
local WAIT_START_SHOW_TIME = 1.5

-- HTTP多久后开始阻挡点击
local WAIT_START_MASK_TIME_HTTP = 3
-- HTTP多久后开始显示菊花
local WAIT_START_SHOW_TIME_HTTP = 4

local Tweening = DG.Tweening
local EaseInOutCubic = Tweening.Ease.InOutCubic

local LWnd = LWnd
---@class UIBlockWait:LWnd
local UIBlockWait = LxWndClass("UIBlockWait", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBlockWait:UIBlockWait()
	self._WaitCallback = nil
	self._WaitSec = 0
	self._WaitTimerId = 1
	self._IsHttp = false
	self._IsShowing = false
	self._isNewWait = false
	self._isOnlyBg = false
	self._isNeedShow = false
	self._Info = ""
	self._WaitBgSeq = nil
	self._MsgTipsSeq = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBlockWait:OnWndClose()
	self:_ClearAllSequence()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBlockWait:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndAsync(false)
	self:SetAutoAdjustNotch(1)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBlockWait:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitWaitView()
end
------------------------------------------------------------------
-- 开始一个等待
function UIBlockWait:StartWait(waitSec, info, waitCallback, isHttp)
	self._WaitSec = waitSec or 30
	self._WaitCallback = waitCallback
	self._IsHttp = isHttp
	if info then
		self._Info = info
	else
		self._Info = ccClientText(120)
	end
	self:TimerStop(self._WaitTimerId)
	self:TimerStart(self._WaitTimerId, self._WaitSec, false, 1)

	self:_ShowWait(true)
end
------------------------------------------------------------------
-- 只显示一张半透的黑影
function UIBlockWait:StartWaitMask()
	self._WaitCallback = nil
	self._Info = ""
	self:_ShowWait(true, false, true)
end

function UIBlockWait:_ScaleToAndBack(tran, toScale, toTime, backScale, backTime, callback)
	local seq = Tweening.DOTween.Sequence()
	local toTween = tran:DOScale(toScale,toTime)
	seq:Append(toTween)
	local backTween = tran:DOScale(backScale,backTime)
	seq:Append(backTween)
	if callback then
		seq:AppendCallback(callback)
	end
	seq:SetLoops(-1)
	seq:Play()
	return seq
end
------------------------------------------------------------------
-- 关闭所有等待UI
function UIBlockWait:StopWait()
	self:TimerStop(self._WaitTimerId)
	self:_ShowWait(false)
end
------------------------------------------------------------------
-- 动画
function UIBlockWait:InitWaitView()

	self.mWaitBgOrgAlpha = self.mWaitBgCanvasGroup.alpha
	self.mWaitBgCanvasGroup.alpha = 0

	CS.ShowObject(self.mWaitBg, false)
	CS.ShowObject(self.mMsgNode, false)
	CS.ShowObject(self.mWaitIcon, false)

	if not self._IsShowing and self._isNeedShow then
		self:_ShowWait(self._isNeedShow, self._isNewWait, self._isOnlyBg)
	end
end

function UIBlockWait:_KillSequence(seq, complete)
	if seq then
		seq:Kill(complete or false)
        seq = nil
    end
end
-------------------------------------------------------------------
-- 等待进入重连状态
function UIBlockWait:StartWaitReConnect(idx, maxIdx, info)
	self:TimerStop(self._WaitTimerId)
	self._WaitCallback = nil
	self._IsHttp = false
	if info then
		self._Info = info
	else
		self._Info = string.replace(ccClientText(106), idx, maxIdx)
	end
	self:_ShowWait(true)
end

function UIBlockWait:_ShowWaitView(bShow)
	if not bShow then
		return
	end

	CS.ShowObject(self.mWaitIcon, bShow)

	self._MsgTipsSeq = self:_ScaleToAndBack(self.mMsgNode, 1.1, 0.5, 1, 0.5)
	------------------------------------------
	-- Tips
	local tipsWaitTime = 0.5
	-- 正在提交请求
	-- 正在重连(5/5)
	self._Info = self._Info or self.mMsgTips.text
	self:SetWndText(self.mMsgTips,self._Info)
	CS.ShowObject(self.mMsgNode, bShow)
end

-------------------------------------------------------------------
-- timer
function UIBlockWait:OnTimer(key)
	if key == self._WaitTimerId then
		local waitCallback = self._WaitCallback
		self._WaitCallback = nil
		if waitCallback then
			waitCallback()
		end
		self:TimerStop(self._WaitTimerId)
	end
end

function UIBlockWait:_ShowWait(bShow, bNew, bOnlyBg)
	if not bNew and self._isNeedShow == bShow then
		if bShow and bOnlyBg then
			CS.ShowObject(self.mWaitBg, true)
			CS.ShowObject(self.mMsgNode, false)
			CS.ShowObject(self.mWaitIcon, false)
		end
		return
	end
	self._isOnlyBg = bOnlyBg
	self._isNewWait = bNew
	self._isNeedShow = bShow

	if not self:IsWndValid() then return end
	if not self:GetWndStarted() then return end

	self._IsShowing = bShow
	self:_ClearAllSequence()

	CS.ShowObject(self.mWaitBg, false)
	CS.ShowObject(self.mMsgNode, false)
	CS.ShowObject(self.mWaitText, false)
	CS.ShowObject(self.mWaitIcon, false)

	self:SetWndVisible(bShow)

	if not bShow then
		return
	end
	self.mWaitBgCanvasGroup.alpha = 0

	local aniEnterTime = WAIT_START_SHOW_TIME - WAIT_START_MASK_TIME
	local maskEnterTime = WAIT_START_MASK_TIME
	if self._IsHttp then
		aniEnterTime = WAIT_START_SHOW_TIME_HTTP - WAIT_START_MASK_TIME_HTTP
		maskEnterTime = WAIT_START_MASK_TIME_HTTP
	end
	self._WaitBgSeq = Tweening.DOTween.Sequence()
	self._WaitBgSeq:AppendInterval(maskEnterTime)
	self._WaitBgSeq:AppendCallback(function() CS.ShowObject(self.mWaitBg, true) end )
	local needWaitTime = aniEnterTime - 0.5
	if needWaitTime > 0 then
		self._WaitBgSeq:AppendInterval(needWaitTime)
	end
	aniEnterTime = 0.5
	local bgTween = CS.TweenFloat(0, self.mWaitBgOrgAlpha, aniEnterTime, function(val) self.mWaitBgCanvasGroup.alpha = val end)
	self._WaitBgSeq:Append(bgTween)
	self._WaitBgSeq:AppendCallback(function() self:_ShowWaitView(not bOnlyBg) end)
	self._WaitBgSeq:SetUpdate(true)
	self._WaitBgSeq:Play()
end

function UIBlockWait:_MoveToAndBack(tran, toPos, toTime, backPos, backTime, callback)
	local seq = Tweening.DOTween.Sequence()
	local toTween = tran:DOMove(toPos,toTime)
	seq:Append(toTween)
	local backTween = tran:DOMove(backPos,backTime)
	seq:Append(backTween)
	if callback then
		seq:AppendCallback(callback)
	end
	seq:SetLoops(-1)
	seq:Play()
	return seq
end
function UIBlockWait:IsValid()
	local wndTrans = self:GetWndTrans()
	return CS.IsValidObject(wndTrans)
end

function UIBlockWait:_ClearAllSequence()
	self:_KillSequence(self._MsgTipsSeq)
	self:_KillSequence(self._WaitBgSeq)

	self._MsgTipsSeq = nil
	self._WaitBgSeq = nil
end
------------------------------------------------------------------
return UIBlockWait


