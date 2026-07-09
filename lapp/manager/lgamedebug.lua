---
--- Created by Admin.
--- DateTime: 2023/10/2 23:12
---
------------------------------------------------------------------
local UnityEngine = UnityEngine
local Input = UnityEngine.Input
local UTime = UnityEngine.Time
local KeyCode = UnityEngine.KeyCode

------------------------------------------------------------------
local LxBaseMgr = require("LApp.Manager.LxBaseMgr")
---@class  LGameDebug : LxBaseMgr
local LGameDebug = LxClass("LGameDebug", LxBaseMgr)
------------------------------------------------------------------

------------------------------------------------------------------
local CS = CS
local UApplication = CS.UApplication
local URuntimePlatform = CS.URuntimePlatform
local ULogType = CS.ULogType
local LStringUtil = LStringUtil
------------------------------------------------------------------
LGameDebug.DebugLogDirPath = CS.AppPersistentDataPath() .. "/debugLog/"
LGameDebug.DebugLogTypeAll = "All"
LGameDebug.DebugLogTypeWarning = "Warning"
LGameDebug.DebugLogTypeError = "Error"
LGameDebug.DebugWndModeHide = -1
LGameDebug.DebugWndModeShow = 0
LGameDebug.DebugWndModeFullLog = 1
--------------------------------------------------------------------

function LGameDebug.GetDebugLogTextList()
	local list = gDebugLogTextList
	if not list then
		list = {}
		gDebugLogTextList = list
	end
	return list
end
------------------------------------------------------------------
function LGameDebug:Initialize()
	LxBaseMgr.Initialize(self)
	if not self._debugLogFilePath then
		self._debugLogFilePath = nil
	end
	if not self._debugWndMode then
		self._debugWndMode = -1
	end
end

function LGameDebug:Dispose()
	gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_DEBUG)
	if self._timer then
		self._timer:Stop()
	end
	self._timer = nil
	LxBaseMgr.Dispose(self)
end

---------------------------------------------------------------------
--- on Gizmos
---------------------------------------------------------------------
function LGameDebug:OnDrawGizmos()

end
---------------------------------------------------------------------
--- on update
---------------------------------------------------------------------
function LGameDebug:OnUpdate()
	if CS.IsOsWinOrEdit() then
		if Input.anyKey then
			self:OnAnyKeyHold()
		end
		if Input.anyKeyDown then
			self:OnAnyKeyDown()
		end
		self:OnAnyKeyUp()
		local wheelFactor = Input.GetAxis("Mouse ScrollWheel")
		if wheelFactor ~= 0 then
			self:OnMouseScrollWheel(wheelFactor)
		end
	end
	--if (LGameDebug.WorldCamera_debug) then
	--	--CS.UDrawRectByPosHoldY(LGameDebug.WorldCamera_planeCenterPos, LGameDebug.WorldCamera_planeRadius, Color.blue, 1)
	--	CS.UDrawRect(LGameDebug.WorldCamera_planeLeftTop,LGameDebug.WorldCamera_planeLeftBottom,LGameDebug.WorldCamera_planeRightBottom,LGameDebug.WorldCamera_planeRightTop,Color.blue, 1)
	--end
	self:OnCheckTouchEVT()
end
---------------------------------------------------------------------
--- touch event
---------------------------------------------------------------------
function LGameDebug:OnCheckTouchEVT()
	local posX = nil
	local posY = nil
	if CS.IsOsWinOrEdit() then
		--posX = Input.mousePosition.x
		--posY = Input.mousePosition.y
	else
		if Input.touchCount > 2 then
			local touch2 = Input.touches[2]
			posX = touch2.position.x
			posY = touch2.position.y
		end
	end
	if posX and posX > 0 and posY and posY > 0 then
		local touchCheckSecond = 0.233
		local touchDisX = 733
		local touchDisY = 533
		local nowTime = UTime.time
		local touchLastTime = self.__touchLastTime
		if not touchLastTime then
			self.__touchLastX = posX
			self.__touchLastY = posY
			self.__touchLastTime = nowTime
		elseif (nowTime - touchLastTime) >= touchCheckSecond then
			local distanceX = nil
			local distanceY = nil
			local lastX = self.__touchLastX
			local lastY = self.__touchLastY
			if lastX then
				distanceX = math.abs(posX - lastX)
			end
			if lastY then
				distanceY = math.abs(posY - lastY)
			end
			self.__touchLastX = nil
			self.__touchLastY = nil
			self.__touchLastTime = nil
			local triggerMode = 0
			if distanceX and distanceX > touchDisX then
				triggerMode = 1
			end
			if distanceY and distanceY > touchDisY then
				if triggerMode == 1 then
					triggerMode = 3
				else
					triggerMode = 2
				end
			end
			if triggerMode > 0 then
				local triggerCheckSecond = 2.0
				local triggerlastTime = self.__triggerlastTime
				if not triggerlastTime or (nowTime - triggerlastTime) >= triggerCheckSecond then
					self.__triggerlastTime = nowTime
					if triggerMode == 1 then
						self:SetDebugWndMode(LGameDebug.DebugWndModeFullLog)
					elseif triggerMode == 2 then
						self:OnBackPressed()
					elseif triggerMode == 3 then
						LNativeHelper.Vibrate()
						CS.SetDeviceShake(function(...) self:OnShakeShake(...) end)
					end
				end
			end
		end
	end
end

function LGameDebug:On_DoubleTap2Fingers(gesture)
end

function LGameDebug:On_TouchDown(gesture)
	if gesture.touchCount == 2 then
		CS.SetDeviceShake(function(...) self:OnShakeShake(...) end)
	end
end

function LGameDebug:On_TouchUp(gesture)
end

function LGameDebug:OnShakeShake(opRet)
	if opRet == CS.YXOpRet.TimeOut then
		printInfoN("shakeshake timeout")
		return 
	end
	gLGameAudio:VideoPlayByUrl("qy_logo.mp4")
end
---------------------------------------------------------------------
--- on backpressed
---------------------------------------------------------------------
function LGameDebug:OnBackPressed()
	---CS.PrintMethodWatchMsg("blockDeLZMA")
end

---------------------------------------------------------------------
--- only for windows
---------------------------------------------------------------------
function LGameDebug:OnMouseScrollWheel(factor)

end

function LGameDebug:OnAnyKeyUp()

end

function LGameDebug:OnAnyKeyHold()

end

function LGameDebug:OnAnyKeyDown()
	self:DoAnyKeyDown()
end

function LGameDebug:DoAnyKeyDown()
	if Input.GetMouseButton(1) then
		--左键

	elseif Input.GetMouseButton(2) then
		--右键
	end

	if Input.GetKeyDown(KeyCode.Backspace) then
		self:OnBackPressed()
	elseif Input.GetKeyDown(KeyCode.F1) then

	elseif Input.GetKeyDown(KeyCode.F2) then

	elseif Input.GetKeyDown(KeyCode.F3) then
		if gModelGuide then                   --结束引导
			gModelGuide:EndGuide()
		end
	elseif Input.GetKeyDown(KeyCode.F4) then
		ReLoginGame()
	elseif Input.GetKeyDown(KeyCode.F5) then
		--重启
		RestartGame()
	elseif Input.GetKeyDown(KeyCode.F6) then

		if gModelPlot then
			gModelPlot:GMSkip()
		end

    elseif Input.GetKeyDown(KeyCode.F7) then
		MgrCenter.ResourceMgr:LogRequesterStatus()
	elseif Input.GetKeyDown(KeyCode.F8) then
		-- GF.OpenWndBottom("WndTreasure")
	elseif Input.GetKeyDown(KeyCode.F9) then
		GF.OpenWndDebug("UIScreenShotSpread")
	elseif Input.GetKeyDown(KeyCode.F10) then
	elseif Input.GetKeyDown(KeyCode.F11) then
		LogWarn("[debug] "..CS.FormatBundlesStatus())
		self:SetDebugWndMode(LGameDebug.DebugWndModeFullLog)
	elseif Input.GetKeyDown(KeyCode.F12) then
		self:SetDebugWndMode()
	end
end


---------------------------------------------------------------------
--- debug wnd mode
---------------------------------------------------------------------
function LGameDebug:GetDebugWndMode()
	return self._debugWndMode
end
function LGameDebug:IsDebugWndVisible()
	local debugWndMode = self._debugWndMode
	if debugWndMode == LGameDebug.DebugWndModeShow or debugWndMode == LGameDebug.DebugWndModeFullLog then return true end
	return false
end
function LGameDebug:SetDebugWndMode(mode)
	local wndName = "UIDebug"
	local wnd = GF.FindFirstWndByName(wndName)
	if mode == nil then
		if wnd then
			mode = LGameDebug.DebugWndModeHide
		else
			mode = LGameDebug.DebugWndModeShow
		end
	end
	if self._debugWndMode == mode then return end

	self._debugWndMode = mode
	if mode == LGameDebug.DebugWndModeShow then
		if not wnd then
			GF.OpenWndDebug(wndName)
		end
	elseif mode == LGameDebug.DebugWndModeHide then
		if wnd then
			GF.CloseWndByName(wndName)
		end
	elseif mode == LGameDebug.DebugWndModeFullLog then
		if not wnd then
			wnd = GF.OpenWndDebug(wndName)
		end
	end
	FireEvent("debug_log_mode")
end
function LGameDebug:AddDebugLog(msg, logType)
	local textList = LGameDebug.GetDebugLogTextList()
	local sLogType = nil
	local color = "#008000ff"
	if logType == ULogType.Error or logType == ULogType.Exception or logType == ULogType.Assert then
		sLogType = LGameDebug.DebugLogTypeError
		color = "#a52a2aff"
	elseif logType == ULogType.Warning then
		sLogType = LGameDebug.DebugLogTypeWarning
		color = "#ffa500ff"
	end
	local strLog = string.format("<color=%s>%s</color>\n", color, msg)

	local maxLen = 13333
	local minLen = 7777

	local textAll = textList[LGameDebug.DebugLogTypeAll] or ""
	if string.len(textAll) > maxLen then
		textAll = "\n[cut too long]\n" .. string.right(textAll, minLen)
	end
	textList[LGameDebug.DebugLogTypeAll] = textAll .. strLog

	if sLogType then
		local text = textList[sLogType] or ""
		if string.len(text) > maxLen then
			text = "\n[cut too long]\n" .. string.right(text, minLen)
		end
		textList[sLogType] = text .. strLog
	end

	if self:IsDebugWndVisible() then
		FireEvent("debug_log_notify")
	end
	self:SaveToLogFile(msg .. "\n")
end
function LGameDebug:SaveToLogFile(msg)
	local debugLogFilePath = self._debugLogFilePath
	if not debugLogFilePath then
		local logDirPath = LGameDebug.DebugLogDirPath
		local logFileList = CS.DirectoryTopFileList(logDirPath, true)
		if logFileList.Length > 5 then
			for i = 0, 2 do
				CS.FileDelete(logFileList[i])
			end
		end
		local sTime = LStringUtil.TightFormatTimestamp(os.time())
		debugLogFilePath = logDirPath .. "debugLog_" .. sTime .. ".txt"
		self._debugLogFilePath = debugLogFilePath
	end
	CS.FileAppendText(debugLogFilePath, msg)
end
function LGameDebug:DebugFPSUpdate(fps)
	self._logFPS = fps
	if self:IsDebugWndVisible() then
		FireEvent("debug_log_fps")
	end
end
function LGameDebug:DebugMemoryUpdate(str)
	self._logMemory = str
	if self:IsDebugWndVisible() then
		FireEvent("debug_log_memory")
	end
end
function LGameDebug:GetLogFPS()
	return self._logFPS or 0
end
function LGameDebug:GetLogMemory()
	return self._logMemory or {}
end


---------------------------------------------------------------------
return LGameDebug


