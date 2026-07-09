---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDebug:LWnd
local UIDebug = LxWndClass("UIDebug", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDebug:UIDebug()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDebug:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDebug:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDebug:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:WndEventRecv("debug_log_mode",function() self:OnDebugLogMode() end)
	self:WndEventRecv("debug_log_fps",function() self:OnDebugLogFPS() end)
	self:WndEventRecv("debug_log_memory",function() self:OnDebugLogMemory() end)
	self:WndEventRecv("debug_log_notify",function() self:OnDebugLogNotify() end)

	--self._bgImage = self:FindWndTrans(nil, "Image")

	self:SetWndClick(self.mButtonAllObj, function()
		self._curLogType = LGameDebug.DebugLogTypeAll
		self:UpdateLogText(true)
	end)
	self:SetWndClick(self.mButtonWarnObj, function()
		self._curLogType = LGameDebug.DebugLogTypeWarning
		self:UpdateLogText(true)
	end)
	self:SetWndClick(self.mButtonErrorObj, function()
		self._curLogType = LGameDebug.DebugLogTypeError
		self:UpdateLogText(true)
	end)

	self._curLogType = LGameDebug.DebugLogTypeAll

	self:UpdateDeviceStatusText()

	self:OnDebugLogMode()
end

------------------------------------------------------------------
--- on event
------------------------------------------------------------------
function UIDebug:OnDebugLogMode()
	if (gLGameDebug) then
		local mode = gLGameDebug:GetDebugWndMode()
		if (mode == LGameDebug.DebugWndModeHide) then
			self:WndClose()
		elseif (mode == LGameDebug.DebugWndModeShow) then
			--CS.ShowObject(self._bgImage, false)
			CS.ShowObject(self.mButtonListObj, false)
			CS.ShowObject(self.mScrollViewObj, false)
		elseif (mode == LGameDebug.DebugWndModeFullLog) then
			--CS.ShowObject(self._bgImage, true)
			CS.ShowObject(self.mButtonListObj, true)
			CS.ShowObject(self.mScrollViewObj, true)
			self:UpdateLogText(true)
		end
	end
end
function UIDebug:UpdateDeviceStatusText()
	if (gLGameDebug) then
		local fps = gLGameDebug:GetLogFPS()
		local memory = gLGameDebug:GetLogMemory()
		local str = "FPS:"..(math.floor(fps * 100) / 100)
		for k,v in pairs(memory) do
			str = string.format("%s\n%s:%s",str,tostring(k), tostring(v))
		end
		local color = "22f252ff"
		str = string.format("<color=#%s>%s</color>",color,str)
		self:SetWndText(self.mTextDeviceStatus,str)
	end
end
function UIDebug:OnDebugLogMemory()
	self:UpdateDeviceStatusText()
end
function UIDebug:OnDebugLogFPS()
	self:UpdateDeviceStatusText()
end
function UIDebug:OnDebugLogNotify()
	self:UpdateLogText()
end


------------------------------------------------------------------
--- update ui
------------------------------------------------------------------
function UIDebug:UpdateLogText(toRefreshCanvas)
	if (gLGameDebug) then
		local textList = LGameDebug.GetDebugLogTextList()
		if (textList) then
			local text = textList[self._curLogType] or ""
			self:SetWndText(self.mLogText,text)
		end
	end
	if (toRefreshCanvas) then
		CS.UCanvas.ForceUpdateCanvases()
		self.mScrollRect.verticalNormalizedPosition = 0.03
		CS.UCanvas.ForceUpdateCanvases()
	end
end

------------------------------------------------------------------
return UIDebug


