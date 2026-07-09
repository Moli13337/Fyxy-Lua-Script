---
--- Created by Administrator.
--- DateTime: 2024/6/24 16:02:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFightEffectSow:LWnd
local UIFightEffectSow = LxWndClass("UIFightEffectSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFightEffectSow:UIFightEffectSow()

	self._battleWndEffKey = "_battleWndEffKey"
	self._battleWndEffList = {}

	self._wndEffectScale = 140
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFightEffectSow:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFightEffectSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFightEffectSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()

	self:TimerStop(self._battleWndEffKey)
	self:TimerStart(self._battleWndEffKey,0,true,-1)

	if gLGameAudio then
		gLGameAudio:StopSingleSound()
	end
end

---@param dpEff LDisplayEffect
function UIFightEffectSow:ExecutePlayEffect(data,dpEff,effectKey)
	local effData = data.effData
	local offset = effData.effOffsetStart --偏移
	offset = offset or Vector3.zero
	local dpTrans = dpEff:GetDisplayTrans()
	if not dpTrans then return end

	dpTrans.localPosition = Vector3(offset.x,offset.y,offset.z)

	local startTime = Time.time + effData.delayTime
	local playTime = startTime + effData.playTime
	self._battleWndEffList[effectKey] = {
		isPlaying = false,
		data = data,
		dpEff = dpEff,
		effectKey = effectKey,
		startTime = startTime,
		playTime = playTime,
		dissipateTime = playTime + effData.dissipateTime,
		onEndCall = function()
			self._battleWndEffList[effectKey] = nil
		end
	}
end


function UIFightEffectSow:OnTimer(key)
	if key == self._battleWndEffKey then
		self:PlayBattleWndEffectList()
	end
end


function UIFightEffectSow:_executePlayEffect(data)
	local effId = data.effId
	local effectKey = self:GetEffectKey(data)
	---@type LDisplayEffect
	local dpEffect = self:FindWndEffectByKey(effectKey)
	if not dpEffect then
		local wndEffScale = self._wndEffectScale
		---@type LDisplayEffect
		local oldEff = self:FindWndEffectByKey(effectKey)
		if oldEff then
			oldEff:SetVisible(false)
			self:ExecutePlayEffect(data,oldEff,effectKey)
		else
			self:CreateWndEffect_Ex({
				trans = self.mFullEffectRoot,
				effName = effId,
				scale = Vector3(wndEffScale,wndEffScale,wndEffScale),
				effKey = effectKey,
				preloadCallback = function(dpTrans)

				end,
				---@param dpEff LDisplayEffect
				endFunc = function(dpEff)
					self:ExecutePlayEffect(data,dpEff,effectKey)
				end,
			})
		end
		return
	end
	self:ExecutePlayEffect(data,dpEffect,effectKey)
end


function UIFightEffectSow:InitData()
end

---@return string
function UIFightEffectSow:GetEffectKey(data)
	local num = 0
	for k,v in pairs(self._battleWndEffList) do
		num = num + 1
	end
	return "effect_" .. data.effId .. "_" .. num
end

function UIFightEffectSow:InitEvent()
end


function UIFightEffectSow:PlayBattleWndEffectList()
	local time = Time.time
	for i,v in pairs(self._battleWndEffList) do
		if not v.isPlaying then
			if v.startTime <= time then
				---@type LDisplayEffect
				local dpEff = v.dpEff
				dpEff:SetVisible(true)
				v.isPlaying = true
			end
		else
			if v.dissipateTime < time then
				---@type LDisplayEffect
				local dpEff = v.dpEff
				dpEff:SetVisible(false)
				local onEndCall = v.onEndCall
				if onEndCall then
					onEndCall()
				end
			end
		end
	end
end

function UIFightEffectSow:OnLoadBattleWndEffect(data)
	local state = data.state
	if state == 1 then
		--- 执行特效
		self:_executePlayEffect(data)
	end
end

function UIFightEffectSow:InitText()
end


function UIFightEffectSow:InitMsg()
	self:WndEventRecv(EventNames.ON_LOAD_BATTLEWND_EFFECT,function(...)
		self:OnLoadBattleWndEffect(...)
	end)
end


function UIFightEffectSow:RefreshView()
end

------------------------------------------------------------------
return UIFightEffectSow