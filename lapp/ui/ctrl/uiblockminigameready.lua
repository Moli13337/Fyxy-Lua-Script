---
--- Created by wzz.
--- DateTime: 2024/6/12 10:41:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBlockMiniGameReady:LWnd
local UIBlockMiniGameReady = LxWndClass("UIBlockMiniGameReady", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBlockMiniGameReady:UIBlockMiniGameReady()
	self._isPause = false
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBlockMiniGameReady:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBlockMiniGameReady:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBlockMiniGameReady:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitEvents()
	local times = 3
	local timePara = {
		key = 1,
		loopcnt = -1,
		interval = 1,
		timescale = false,
		callOnStart = true,
		func = function()
			if self._isPause then
				return
			end

			if times <= 0 then
				self:WndClose()
				FireEvent(EventNames.BLOCKMINIGAME_START)
				return
			end

			for i = 1, 3 do
				CS.ShowObject(self["mTime" .. i], i == times)
			end
			times = times - 1
		end
	}

	self:TimerStartImpl(timePara)

	gLGameAudio:PlaySound("SoundS_201")
	LxUnity.UResources.UnloadUnusedAssets()
end

-- 初始事件
function UIBlockMiniGameReady:InitEvents()
	self:WndEventRecv(EventNames.BLOCKMINIGAME_RESUME, function() self._isPause = false end)
	self:WndEventRecv(EventNames.BLOCKMINIGAME_PAUSE, function() self._isPause = true end)
end

------------------------------------------------------------------
return UIBlockMiniGameReady