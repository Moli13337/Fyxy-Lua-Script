---
--- Created by Admin.
--- DateTime: 2023/10/2 23:12
---
-----------------------------------------------------------------
local LUnityQuality = LxClass("LUnityQuality", nil)
-----------------------------------------------------------------
LUnityQuality.UQUALITY_LV_FASTEST = 0
LUnityQuality.UQUALITY_LV_FAST = 1
LUnityQuality.UQUALITY_LV_SIMPLE = 2
LUnityQuality.UQUALITY_LV_GOOD = 3
LUnityQuality.UQUALITY_LV_BEAUTIFUL = 4
LUnityQuality.UQUALITY_LV_FANTASTIC = 5
-----------------------------------------------------------------
local UnityEngine = UnityEngine
local CS = CS
local USystemInfo = CS.SystemInfo
local LxBaseMgr = require("LApp.Manager.LxBaseMgr")
---@class LGameQuality : LxBaseMgr
local LGameQuality = LxClass("LGameQuality", LxBaseMgr)
-----------------------------------------------------------------
LGameQuality.QUALITY_LV_LOW = 100                	-- 低
LGameQuality.QUALITY_LV_NORMAL = 200                -- 中
LGameQuality.QUALITY_LV_HIGH = 300                	-- 高
-----------------------------------------------------------------
LGameQuality.SCREEN_MODEL_CREATE_MAX = 1                -- 动态模型创建最大数量
LGameQuality.SCREEN_MODEL_SHOW_MAX = 2                	-- 动态模型同屏显示最大数量
-----------------------------------------------------------------
LGameQuality.QUALITY_SETTING = {
	[LGameQuality.QUALITY_LV_LOW] = {
		[LGameQuality.SCREEN_MODEL_CREATE_MAX] = 20,
		[LGameQuality.SCREEN_MODEL_SHOW_MAX] = 7
	},
	[LGameQuality.QUALITY_LV_NORMAL] = {
		[LGameQuality.SCREEN_MODEL_CREATE_MAX] = 100,
		[LGameQuality.SCREEN_MODEL_SHOW_MAX] = 23
	},
	[LGameQuality.QUALITY_LV_HIGH] = {
		[LGameQuality.SCREEN_MODEL_CREATE_MAX] = 300,
		[LGameQuality.SCREEN_MODEL_SHOW_MAX] = 100
	},
}

LGameQuality.QUALITY_CONVERT_TO_UNITY = {
	[LGameQuality.QUALITY_LV_LOW] = LUnityQuality.UQUALITY_LV_FASTEST,
	[LGameQuality.QUALITY_LV_NORMAL] = LUnityQuality.UQUALITY_LV_GOOD,
	[LGameQuality.QUALITY_LV_HIGH] = LUnityQuality.UQUALITY_LV_FANTASTIC,
}

LGameQuality.QUALITY_SCALE_MATCH = {
	[LGameQuality.QUALITY_LV_LOW] = true,
	[LGameQuality.QUALITY_LV_NORMAL] = false,
	[LGameQuality.QUALITY_LV_HIGH] = false,
}

-----------------------------------------------------------------
LGameQuality.FPS_LOW_LIMIT = 25            			-- 低FPS临界值
-----------------------------------------------------------------
LGameQuality.SCREEN_WIDTH_LOWEST = 480            	-- 低端分辨率
LGameQuality.SCREEN_HEIGHT_LOWEST = 852            	-- 低端分辨率
-----------------------------------------------------------------
LGameQuality.SCREEN_WIDTH_DESIGN = 640            	-- 设计分辨率
LGameQuality.SCREEN_HEIGHT_DESIGN = 1136            -- 设计分辨率
-----------------------------------------------------------------
LGameQuality.SCREEN_WIDTH_DEVICE = 0            	-- 设备分辨率
LGameQuality.SCREEN_HEIGHT_DEVICE = 0            	-- 设备分辨率
-----------------------------------------------------------------
LGameQuality.SCREEN_WIDTH_SCALE = 0            		-- 缩放分辨率
LGameQuality.SCREEN_HEIGHT_SCALE = 0            	-- 缩放分辨率

------------------------------------------------------------------
LGameQuality.FRAME_RATE_HIGH = 60            		-- 高帧率
LGameQuality.FRAME_RATE_NORMAL = 30            		-- 普通帧率
-----------------------------------------------------------------

LGameQuality._IsWEBGLCleanDevice = false
LGameQuality._IsWEBGLRC = 0
LGameQuality._IsWEBGLRCLastFrame = 31
-----------------------------------------------------------------
function LGameQuality:Initialize()
	LxBaseMgr.Initialize(self)

	self._fpsAverage = 0
	self._baseFrameRate = 60

	self._frameRateIndex = 0
	self._curFrameRateId = 0

	self._delaySetTimer = nil

	UnityEngine.Screen.sleepTimeout = UnityEngine.SleepTimeout.NeverSleep

	self:InitFrameRate()

	Time.maximumDeltaTime = 0.1
end

function LGameQuality:Dispose()
	if self._delaySetTimer then
		LxTimer.DelayTimeStop(self._delaySetTimer)
		self._delaySetTimer = nil
	end
	LxBaseMgr.Dispose(self)
end
-----------------------------------------------------------------
--- 设置游戏帧率
-----------------------------------------------------------------
function LGameQuality:InitFrameRate()
	local highFrameRate = tonumber(LPlayerPrefs.highFrameRate) or -1
	local bHigh = true

	if CS.IsWebGL() then
		local isWxIos = LWxHelper.IsMiniGamePlatform() and LWxHelper.IsInIos()
		local isWebIos = LPlatformUtil.IsInIos()
		if isWxIos or isWebIos then
			LXFW.LxLog.log("enter webgl ios frame rate setting")
			LGameQuality._IsWEBGLCleanDevice = true
			LGameQuality.FRAME_RATE_HIGH = 31
			LGameQuality.FRAME_RATE_NORMAL = 30
			if highFrameRate < 0 then
				bHigh = false
			end	
		else
			bHigh = highFrameRate > 0
		end
	else
		if highFrameRate < 0 then
			if CS.IsOSIos() then
				local strModel = USystemInfo.deviceModel -- iPhone12,1 ...
				strModel = string.lower(strModel)
				--其他都用高帧率
				if string.find(strModel, "iphone") then
					local arrList = string.split(strModel, ",")
					local modelName = arrList[1]
					modelName = string.gsub(modelName,"iphone","")
					modelName = tonumber(modelName)
					if modelName and modelName < 10 then -- 苹果8 以前的 用低帧率
						bHigh = false
					end
				end
			elseif CS.IsOSAndroid() then
				local memorySize = USystemInfo.systemMemorySize
				---4G以上内存手机 用高帧率
				bHigh = memorySize > 4000
			end
		else
			bHigh = highFrameRate == 1  
		end
	end	
	self._baseFrameRate = 0
	self:SetHighFrameRate(bHigh)
end

function LGameQuality:SetHighFrameRate(bHigh)
	LPlayerPrefs.SetHighFrameRate(bHigh and 1 or 0)
	local frameRate = self._baseFrameRate
	local newFrameRate = bHigh and LGameQuality.FRAME_RATE_HIGH or LGameQuality.FRAME_RATE_NORMAL
	LGameQuality._IsWEBGLRCLastFrame = newFrameRate
	if newFrameRate == frameRate then return end
	self:SetFrameRate(newFrameRate)
end

function LGameQuality:SetNoTouchFrameRate(bNoTouch)
	if CS.IsWebGL() then return end

	if self._isOpenMax then return end

	local bHigh = (tonumber(LPlayerPrefs.highFrameRate) or -1) == 1
	local baseFrameRate = self._baseFrameRate or LGameQuality.FRAME_RATE_NORMAL
	local originFrame = bHigh and LGameQuality.FRAME_RATE_HIGH or LGameQuality.FRAME_RATE_NORMAL
	local newFrameRate = bNoTouch and LGameQuality.FRAME_RATE_NORMAL or originFrame
	if baseFrameRate == newFrameRate then return end
	self:SetFrameRate(newFrameRate)
end

function LGameQuality:GetFrameRate()
	return UnityEngine.Application.targetFrameRate
end

function LGameQuality:SetFrameRate(frameRate)
	self._baseFrameRate = frameRate
	--微信小游戏提示用回unity接口
	--if LWxHelper.IsWxPlatform() then
	--	LWxHelper.WxSetFrameRate(frameRate)
	--else
	--	UnityEngine.Application.targetFrameRate = frameRate
	--end
	UnityEngine.Application.targetFrameRate = frameRate
end

function LGameQuality:OpenMaxFrameRate(bOpen)
	if CS.IsWebGL() then return end

	self._isOpenMax = bOpen
	if bOpen then
		UnityEngine.Application.targetFrameRate = -1
	else
		UnityEngine.Application.targetFrameRate = self._baseFrameRate
	end
end

function LGameQuality:AccelerateFrameRate(frameRate, frameRateId)
	local retId = frameRateId
	if not retId then
		retId = self._frameRateIndex + 1
		self._frameRateIndex = retId
	end
	self._curFrameRateId = retId
	if self._baseFrameRate == frameRate then return retId end
	self:SetFrameRate(frameRate)
	return retId
end

function LGameQuality:CancelFrameRate(frameRateId)
	if self._curFrameRateId ~= frameRateId then return end
	local bHigh = (tonumber(LPlayerPrefs.highFrameRate) or 0) == 1
	local setRate = bHigh and LGameQuality.FRAME_RATE_HIGH or LGameQuality.FRAME_RATE_NORMAL
	if self._baseFrameRate == setRate then return end
	self:SetFrameRate(setRate)
end
-----------------------------------------------------------------
function LGameQuality:GetFpsAverage()
	return self._fpsAverage
end
-----------------------------------------------------------------
--- 设置游戏品质等级
-----------------------------------------------------------------
function LGameQuality:SetQualityLv(v)
	if LPlayerPrefs.qualityLv == v then return end
	local qualityLv = LPlayerPrefs.SetQualityLv(v)
	self:ApplyQualityLv(qualityLv)
end
-----------------------------------------------------------------
--- 获取当前游戏品质等级
-----------------------------------------------------------------
function LGameQuality:GetQualityLv()
	local quality = tonumber(LPlayerPrefs.qualityLv)
	--or quality == LGameQuality.QUALITY_LV_HIGH
	if quality == LGameQuality.QUALITY_LV_LOW or quality == LGameQuality.QUALITY_LV_NORMAL then
		return quality
	end

	quality = LGameQuality.QUALITY_LV_NORMAL
	if CS.IsOSAndroid() then
		local memorySize = USystemInfo.systemMemorySize
		---2G内存手机 用低画质
		if memorySize <= 2500 then
			quality = LGameQuality.QUALITY_LV_LOW
		end
	elseif CS.IsWebGL() then
		quality = LGameQuality.QUALITY_LV_LOW
	end
	LPlayerPrefs.SetQualityLv(quality)
	return quality
end
-----------------------------------------------------------------
--- 获取当前游戏品质设置参数
-----------------------------------------------------------------
function LGameQuality:GetQualitySetting()
	local qualityLv = self:GetQualityLv()
	return LGameQuality.QUALITY_SETTING[qualityLv]
end
-----------------------------------------------------------------
--- 更新品质参数
-----------------------------------------------------------------
function LGameQuality:ApplyQualityLv(qualityLv)
	local uQualityLv = LGameQuality.QUALITY_CONVERT_TO_UNITY[qualityLv]
	if uQualityLv then
		CS.SetQualityLevel(uQualityLv)
	end
	self:ResetScreenScale(qualityLv)
	FireEvent(EventNames.GAME_MAX_MODEL)
	self:DoScaleScreenResolution()
	self:DoSetWinFixedResolution()
end

function LGameQuality:ResetScreenScale(qualityLv)
	qualityLv = qualityLv or self:GetQualityLv()
	if LGameQuality.QUALITY_SCALE_MATCH[qualityLv] then
		LGameQuality.SCREEN_WIDTH_SCALE = 0
		LGameQuality.SCREEN_HEIGHT_SCALE = 0
	else
		LGameQuality.SCREEN_WIDTH_SCALE = LGameQuality.SCREEN_WIDTH_DEVICE
		LGameQuality.SCREEN_HEIGHT_SCALE = LGameQuality.SCREEN_HEIGHT_DEVICE
	end
end
-----------------------------------------------------------------
--- 设置FPS采样
-----------------------------------------------------------------
function LGameQuality:EnableFps(isActive, sampleCnt, fpsInterval)
	if isActive then
		CS.EnableFps(function(...)
			self:OnFpsFinished(...)
		end, sampleCnt, fpsInterval)
	else
		CS.EnableFps()
	end
end

function LGameQuality:OnFpsFinished(fpsAverage, sampleCnt, useTime)
	LXFW.LxLog.GAME(string.format("fps=%d,sample=%d,usetime=%d", fpsAverage, sampleCnt, useTime))
	self._fpsAverage = fpsAverage
	self:DoCheckFpsAverage()
end

function LGameQuality:OnApplicationPause(isPause)
	if isPause then return end
	local nowResolution = UnityEngine.Screen.currentResolution
	LXFW.LxLog.log("--------------resolution=" .. nowResolution.width .. "x" .. nowResolution.height)
	self:DoCheckFpsAverage()
end
--------------------------------------------------------------------------
--- 检查FPS均值
--------------------------------------------------------------------------
function LGameQuality:DoCheckFpsAverage()
	local fpsAverage = self._fpsAverage
	if fpsAverage > 0 and fpsAverage <= LGameQuality.FPS_LOW_LIMIT then
		local nowResolution = UnityEngine.Screen.currentResolution
		LogError("LowFps=" .. fpsAverage .. ",now=" .. nowResolution.width .. "x" .. nowResolution.height)
		self:ApplyQualityLv(LGameQuality.QUALITY_LV_LOW)
	end
end

------------------------------------------------------------------
--------------------------------------------------------------------------
--- pc分辨率修改
--------------------------------------------------------------------------
function LGameQuality:DoSetWinFixedResolution()
	local UApplication = CS.UApplication
	local platform = UApplication.platform
	if platform ~= CS.URuntimePlatform.WindowsPlayer then return end

	local designWidth = LGameQuality.SCREEN_WIDTH_DESIGN
	local designHeight = LGameQuality.SCREEN_HEIGHT_DESIGN
	local nowWidth = LGameQuality.SCREEN_WIDTH_DEVICE
	local nowHeight = LGameQuality.SCREEN_HEIGHT_DEVICE
	if nowWidth == 0 or nowHeight == 0 then
		local nowResolution = UnityEngine.Screen.currentResolution
		nowWidth = nowResolution.width
		nowHeight = nowResolution.height
	end
	if nowWidth == 0 or nowHeight == 0 then
		if not self._isCheckSetTimer then
			self._isCheckSetTimer = true
			self._delaySetTimer = LxTimer.DelayFrameCall(function ()
				self._delaySetTimer = nil
				self:DoSetWinFixedResolution()
			end, 1)
		end
		return
	end

	nowWidth =  math.modf(nowWidth * 0.8)
	nowHeight = math.modf(nowHeight * 0.8)

	local rateDesign = designWidth / designHeight
	local rateNow = nowWidth / nowHeight

	if rateDesign > rateNow then
		nowHeight = math.modf(nowWidth / rateDesign)
	elseif rateDesign < rateNow then
		nowWidth = math.modf(nowHeight * rateDesign)
	end

	LXFW.LxLog.log("win fixed resolution : "..tostring(nowWidth).."x"..tostring(nowHeight))

	CS.DoSetScreenResolution(nowWidth, nowHeight, false)

	LGamePostProcess:ResetResolution()
end


------------------------------------------------------------------
function LGameQuality:IsAndroidEnableScale()
	if CS.IsOSAndroid() then
		--unity 2019 不进行分辨率缩放了
		--设置了分辨率后，手机分辨率变化， unity的屏幕大小不会自动进行调整
		local unityVer = CS.UApplication.unityVersion
		local verList1 = string.split(unityVer, ".") or {}
		local verInt = tonumber(verList1[1]) or 0
		if verInt >= 2019 then
			return false
		end
		return true
	end

	return false
end

--------------------------------------------------------------------------
--- android硬件缩放
--------------------------------------------------------------------------
function LGameQuality:DoScaleScreenResolution()
	if not CS.IsOSAndroid() then return end

	--if not self:IsAndroidEnableScale() then
	--	return
	--end
	if LGameQuality.SCREEN_WIDTH_SCALE == 0 and LGameQuality.SCREEN_HEIGHT_SCALE == 0 then
		local designWidth = LGameQuality.SCREEN_WIDTH_DESIGN
		local designHeight = LGameQuality.SCREEN_HEIGHT_DESIGN
		local nowWidth = LGameQuality.SCREEN_WIDTH_DEVICE
		local nowHeight = LGameQuality.SCREEN_HEIGHT_DEVICE
		if nowWidth == 0 or nowHeight == 0 then
			local nowResolution = UnityEngine.Screen.currentResolution
			nowWidth = nowResolution.width
			nowHeight = nowResolution.height
		end
		local rateDesign = designWidth / designHeight
		local rateNow = nowWidth / nowHeight
		local rateScale = designWidth / nowWidth
		if rateDesign < rateNow then
			designWidth = math.modf(designHeight * rateNow)
			rateScale = designWidth / nowWidth
		elseif rateDesign > rateNow then
			designHeight = math.modf(designWidth / rateNow)
		end
		if rateScale < 1.0 then
			LGameQuality.SCREEN_WIDTH_SCALE = designWidth
			LGameQuality.SCREEN_HEIGHT_SCALE = designHeight
			local msg = "screenDevice=" .. LGameQuality.SCREEN_WIDTH_DEVICE .. "x" .. LGameQuality.SCREEN_HEIGHT_DEVICE
			msg = msg .. " | screenScale=" .. LGameQuality.SCREEN_WIDTH_SCALE .. "x" .. LGameQuality.SCREEN_HEIGHT_SCALE
			LXFW.LxLog.log(msg)
		end
	end
	local scaleWidth = LGameQuality.SCREEN_WIDTH_SCALE
	local scaleHeight = LGameQuality.SCREEN_HEIGHT_SCALE
	if scaleWidth > 0 and scaleHeight > 0 then
		if (scaleWidth % 2) == 0 then
			scaleWidth = scaleWidth
		else
			scaleWidth = scaleWidth - 1
		end
		CS.DoSetScreenResolution(scaleWidth, scaleHeight, true)

		LGamePostProcess:ResetResolution()
	end
end

--折叠屏手机单屏幕 双屏幕切换
function LGameQuality:OnScreenResize(sw, sh)
	if sw ~= LGameQuality.SCREEN_WIDTH_DEVICE or sh ~= LGameQuality.SCREEN_HEIGHT_DEVICE then
		LGameQuality.SCREEN_WIDTH_DEVICE = sw
		LGameQuality.SCREEN_HEIGHT_DEVICE = sh

		self:ResetScreenScale()
		self:DoScaleScreenResolution()

		if CS.IsOSAndroid() then
			LNotchUtil.ReNotchFit()
		else
			LGamePostProcess:ResetResolution()
		end
	end
end

function LGameQuality:GetDeviceWH()
	return LGameQuality.SCREEN_WIDTH_DEVICE, LGameQuality.SCREEN_HEIGHT_DEVICE
end
-----------------------------------------------------------------
return LGameQuality




