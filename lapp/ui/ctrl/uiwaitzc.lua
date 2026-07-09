---
--- Created by By.
--- DateTime: 2023/10/29 21:23:25
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWaitZC:LWnd
local UIWaitZC = LxWndClass("UIWaitZC", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWaitZC:UIWaitZC()
	self._spine = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWaitZC:OnWndClose()
	self._spine = nil
	self:StopWaitTimer()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWaitZC:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndAsync(false)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWaitZC:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	--self:StartLoadSpine()
	self:StartLoadEffect()
end


------------------------------------------------------------------
--加载完之后播放 第一段动画， 乌鸦带起黑屏
function UIWaitZC:OnSpineLoaded()
	local firstEndFunc = function(...)
		self._bEnterOk = true
		local func = self._hidEndFunc
		if func then
			func()
		end
		self:StartWaitZhuanchangEnd()
	end

	self._spine:SetAnimationCompleteFunc(firstEndFunc)
	self._spine:PlayAnimation(0, "idle1", false, true, 0)
	LxUiHelper.PlayAudioSoundName(LSoundConst.BATS_FLY)

	self:StopWaitTimer()
	self._waitTimer = LxTimer.DelayTimeCall(firstEndFunc, 2)
end

------------------------------------------------------------------
--黑幕等待 2s, 如果转场提前结束了，等待指定时间
function UIWaitZC:StartWaitZhuanchangEnd()
	self:StopWaitTimer()

	local waitTime = 0.1

	if self._bZhuanchangEnd then
		waitTime = 0.1
	end

	if self._hideTime then
		waitTime = self._hideTime
	end

	self._waitTimer = LxTimer.DelayTimeCall(function ()
		--printInfoN("转场.....超时等待"..tostring(waitTime))
		self:OnWaitZhuanChangeEnd()
	end, waitTime, true)
end

function UIWaitZC:StartLoadEffect()
	self:CreateWndEffect_Ex({
		trans=self.mView,
		effName="guochangdonghua_2",
		effKey="guochangdonghua_2",
		endFunc = function ()
			self:OnEffectLoaded()
		end ,
	})
end

function UIWaitZC:OnEffectLoaded()
	local seq = self:GetSeqCom()
	local key = "guochangdonghua_2"
	local sequence = seq:CreateSeq(key)
	sequence:AppendInterval(0.8)
	sequence:AppendCallback(function()
		local func = self._hidEndFunc
		if func then
			func()
		end
	end)
	sequence:AppendInterval(0.76)
	sequence:OnComplete(function()
		seq:DeleteSeq(key)
		self:WndClose()
	end)
	sequence:PlayForward()
end

function UIWaitZC:InitData()
	self._isMapTransit = self:GetWndArg("isMapTransit")
	self._hidEndFunc = self:GetWndArg("hideEndFunc")
	self._hideTime = self:GetWndArg("hideTime")
end

-----------------------------------------------------------------

function UIWaitZC:StopWaitTimer()
	if self._waitTimer then
		LxTimer.DelayTimeStop(self._waitTimer)
		self._waitTimer = nil
	end
end

function UIWaitZC:InitEvent()
	self:WndEventRecv(EventNames.WAIT_ZHUANCHANGE_END, function()
		self._bZhuanchangEnd = true
		--printErrorN("转场加载结束")
		--self:OnWaitZhuanChangeEnd()
	end)
end

--播放 第二段动画， 乌鸦带走黑屏, 最长等待4s自动关闭，或者播放完毕自动关闭界面
function UIWaitZC:OnWaitZhuanChangeEnd()
	if not self._bEnterOk then return end
	self._bEnterOk = false
	--LResRelease.ClearBundleUnused(true)
	self:StopWaitTimer()
	self._spine:SetAnimationCompleteFunc(function(...)
		self:WndClose()
	end)
	self._spine:PlayAnimation(0, "idle2", false, true, 0)

	self._waitTimer = LxTimer.DelayTimeCall(function ()
		CS.ShowObject(self.mBg.gameObject, false)
	end, 0.4, true)
end


------------------------------------------------------------------
function UIWaitZC:StartLoadSpine()
	self._spine = self:CreateWndSpine(self.mView, "Bianfuzhuanchang", "Bianfuzhuanchang",  nil,
	function ()
		self:OnSpineLoaded()
	end ,
	true)
	self._spine:StartLoad()
end
------------------------------------------------------------------
return UIWaitZC


