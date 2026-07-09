---
--- Created by Admin.
--- DateTime: 2023/10/24 11:52
---
-------------------------------------------------------------------------------
-------------------------------------------------------------------------------
local CS = CS
local USystemInfo = CS.SystemInfo
local UApplication = CS.UApplication
local NativeHelper = CardEHT.NativeHelper
local YXResClearMode = CS.YXResClearMode
local LxBaseMgr = require("LApp.Manager.LxBaseMgr")
---@class LGameMemory : LxBaseMgr
local LGameMemory = LxClass("LGameMemory", LxBaseMgr)
------------------------------------------------------------------
LGameMemory.MEMORY_QUERY_TIME_LIMIT = 3    -- 内存查询间隔
LGameMemory.UNITY_MEM_SHARE_SIZE = 100    -- unity共享内存近似值
LGameMemory.SYSTEM_MEM_LEFT_LIMIT = 170    -- 系统剩余内存临界值
------------------------------------------------------------------
function LGameMemory:Initialize()
	LxBaseMgr.Initialize(self)

	self._unityReserved = 0
	self._unityAllocated = 0
	self._unityReserveUnused = 0
	self._monoHeap = 0
	self._monoUsed = 0
	self._lowMemoryCount = nil                -- 高危内存警告计数
	self._lastQueryMemTime = nil            -- 上一次查询内存时间
	self.assetBundleMemData = {}
	--self.assetBundleTotalMemory = 0
	--self.assetBundleLastTotalMemory = 0
end

function LGameMemory:Dispose()
	LxBaseMgr.Dispose(self)
end

function LGameMemory:DoAfterInitialize()
	self:QuerySystemMemory()
	self:ReportInfo()
	self:ReportMemory()
end
-------------------------------------------------------------------------------
--- memory query
-------------------------------------------------------------------------------
function LGameMemory:PrintMemoryStatus(title)
	local str = "[memory] : " .. title .. " "
	str = str .. "sys=" .. self._fMemSysAvail .. "/" .. self._fMemLimitSysAvail .. "/" .. self._fMemSysTotal
	str = str .. ",app=" .. self._fMemAppUsed .. "/" .. self._fMemLimitAppUsed
	str = str .. "\nunityReserved=" .. self._unityReserved
	str = str .. "\nunityUsed=" .. self._unityAllocated
	str = str .. "\nunityUnused=" .. self._unityReserveUnused
	str = str .. "\nmonoHeap=" .. self._monoHeap
	str = str .. "\nmonoUsed=" .. self._monoUsed
	LXFW.LxLog.MEMORY(str)
end

function LGameMemory:ReportInfo()
	local str = "[LApplicationInfo] : "
	str = str .."identifier=" ..tostring(UApplication.identifier)..", productName="..tostring(UApplication.productName)..", companyName="..tostring(UApplication.companyName)..", version="..tostring(UApplication.version)..", systemLanguage="..tostring(UApplication.systemLanguage)
	LXFW.LxLog.log(str)
	str = "[Apk info] : ".." packageName="..LNativeHelper.GetPackageName()..", versioncode="..LNativeHelper.GetVersionCode()..", versionname="..LNativeHelper.GetVersionName()..", appname="..LNativeHelper.GetAppName()
	LXFW.LxLog.log(str)
end
function LGameMemory:ReportMemory()
	local fMemSysAvail = self._fMemSysAvail or 0
	local fMemLimitSysAvail = self._fMemLimitSysAvail or 0
	local fMemSysTotal = self._fMemSysTotal or 0
	if (not fMemSysTotal or fMemSysTotal <= 0) then
		fMemSysTotal = USystemInfo.systemMemorySize
	end
	local fMemAppUsed = self._fMemAppUsed or 0
	local fMemLimitAppUsed = self._fMemLimitAppUsed or 0
	local strMemSys = fMemSysAvail .. "/" .. fMemLimitSysAvail .. "/" .. fMemSysTotal
	local strMemApp = fMemAppUsed .. "/" .. fMemLimitAppUsed
	LNativeHelper.SetReportLog("memory", "sys = " .. strMemSys .. ", app = " .. strMemApp)
	local sCpuInfo = USystemInfo.processorType .. ", count=" .. USystemInfo.processorCount .. ", frequency=" .. USystemInfo.processorFrequency
	LNativeHelper.SetReportLog("cpu", sCpuInfo)
	local sGpuInfo = USystemInfo.graphicsDeviceName .. ", vendor=" .. USystemInfo.graphicsDeviceVendor .. ", vendorID=" .. USystemInfo.graphicsDeviceVendorID
	LNativeHelper.SetReportLog("gpu", sGpuInfo)
	local deviceUniqueIdentifier = "" ---USystemInfo.deviceUniqueIdentifier --不再获取
	local sOsInfo = USystemInfo.operatingSystem .. ",  uniqueIdentifier=" .. deviceUniqueIdentifier
	LNativeHelper.SetReportLog("os", sOsInfo)
	local sDeviceInfoStr = "model=" .. USystemInfo.deviceModel .. ", name=" .. USystemInfo.deviceName .. ", deviceType=" .. USystemInfo.deviceType:ToString()
	LNativeHelper.SetReportLog("device", sDeviceInfoStr)
	local sDeviceInfo = LNativeHelper.GetDeviceInfo()
	local arrList = string.split(sDeviceInfo,"|,") or {}
	local modelStr = arrList[1] or ""
	local brandStr = arrList[2] or ""
	local manufacturerStr = arrList[3] or ""
	local sSysInfo = "model=" .. modelStr .. ", brand=" .. brandStr .. ", manufacturer=" .. manufacturerStr
	LNativeHelper.SetReportLog("phone", sSysInfo)
end
function LGameMemory:QuerySystemMemory(isTimeLimit)
	if isTimeLimit then
		local nowTime = GetTimestamp()
		local lastQueryMemTime = self._lastQueryMemTime
		if lastQueryMemTime then
			if (nowTime - lastQueryMemTime) <= LGameMemory.MEMORY_QUERY_TIME_LIMIT then
				return 
			end
		end
		self._lastQueryMemTime = nowTime
	end
	--LNativeHelper.GetMemoryStatus()--c# 里面有个字符串转数字的，因为ios法语会报错，ios法语的字符串的是小数是用逗号表示的,不是点
	local memTotal = NativeHelper.sysMemTotal
	local memAvail = NativeHelper.sysMemLeft
	local memHold = NativeHelper.sysMemNeedHold
	local memApp = NativeHelper.sysMemApp
	local memAppLimit = 480
	if memTotal > 0 then
		if memTotal < 520 then
			memAppLimit = 180
		elseif memTotal < 1200 then
			memAppLimit = 360
		else
			memAppLimit = 480
		end 
	end 

	if memApp > LGameMemory.UNITY_MEM_SHARE_SIZE then
		memApp = memApp - LGameMemory.UNITY_MEM_SHARE_SIZE
	end

	self._fMemSysTotal = memTotal
	self._fMemSysAvail = memAvail
	self._fMemSysNeedHold = memHold
	self._fMemAppUsed = memApp
	self._fMemLimitSysAvail = LGameMemory.SYSTEM_MEM_LEFT_LIMIT
	self._fMemLimitAppUsed = memAppLimit
end
function LGameMemory:QueryUnityMemory()
	if LGameSettings.platformDev then
		LNativeHelper.CheckProfileMemory()
		self._unityReserved = NativeHelper.unityMemReserved
		self._unityAllocated = NativeHelper.unityMemAllocated
		self._unityReserveUnused = NativeHelper.unityMemReservedUnused
		self._monoHeap = NativeHelper.unityMonoHeap
		self._monoUsed = NativeHelper.unityMonoHeapUsed
	end
end
-------------------------------------------------------------------------------
--- 检测并判断当前内存是否够用
-------------------------------------------------------------------------------
function LGameMemory:CheckMemoryEnough()
	self:QuerySystemMemory(true)

	local sysMemTotal = self._fMemSysTotal
	local sysMemLeft = self._fMemSysAvail
	local sysMemLeftLimit = self._fMemLimitSysAvail
	local appMemUsed = self._fMemAppUsed
	local appMemUsedLimit = self._fMemLimitAppUsed

	if (not sysMemTotal or sysMemTotal <= 0 or
			not sysMemLeft or sysMemLeft <= 0 or
			not sysMemLeftLimit or sysMemLeftLimit <= 0 or
			not appMemUsed or appMemUsed <= 0 or
			not appMemUsedLimit or appMemUsedLimit <= 0
	) then
		return true
	end

	local sysMemTotalLimit = 1777
	if CS.IsOSAndroid() then
		sysMemTotalLimit = 3777
	end

	if sysMemTotal <= sysMemTotalLimit then
		return false
	end
	if sysMemLeft <= sysMemLeftLimit then
		return false
	end
	if appMemUsed >= 577 then
		return false
	end
	--if (appMemUsed >= appMemUsedLimit) then
	--	return false
	--end

	return true
end
-------------------------------------------------------------------------------
--- 判断是否坏手机
-------------------------------------------------------------------------------
function LGameMemory:IsBadPhone()
	local memTotal = self._fMemSysTotal
	if CS.IsOSAndroid() then
		if memTotal > 0 and memTotal < 3777 then
			return true
		end
	elseif CS.IsOSIos() then
		if memTotal > 0 and memTotal < 1777 then
			return true
		end
	end
	return false
end
-------------------------------------------------------------------------------
--- 物理内存低
-------------------------------------------------------------------------------
function LGameMemory:IsLowPhysicalMemory()
	local memTotal = self._fMemSysTotal
	local limit = 1200
	if CS.IsOSAndroid() then
		limit = 4096
	end
	if memTotal > 0 and memTotal < limit then
		return true
	end
	return false
end
-------------------------------------------------------------------------------
--- 查询并判断内存状态
-------------------------------------------------------------------------------
function LGameMemory:DoCheckMemoryStatus(isToFree, tips)
	tips = tips or ""
	self:QuerySystemMemory()
	if gLGameDebug then
		local checkFlag = self._checkFlag
		if checkFlag then
			checkFlag = false
		else
			checkFlag = true
		end
		self._checkFlag = checkFlag
		local strFlag = ""
		if checkFlag then
			strFlag = " "
		end
		gLGameDebug:DebugMemoryUpdate({
			k1 = "",
			k2 = "",
			k3 = "",
			k4 = "",
			sys = strFlag .. self._fMemSysAvail .. "/" .. self._fMemLimitSysAvail .. "/" .. self._fMemSysTotal,
			app = strFlag .. self._fMemAppUsed .. "/" .. self._fMemLimitAppUsed,
		})
	end

	local fMemSysAvail = self._fMemSysAvail
	local fMemLimitSysAvail = self._fMemLimitSysAvail
	local fMemLimitAppUsed = self._fMemLimitAppUsed
	local memApp = self._fMemAppUsed

	local ret = 0
	if fMemSysAvail > 0 and fMemSysAvail < fMemLimitSysAvail then
		ret = -1
	elseif memApp > 0 and memApp > fMemLimitAppUsed then
		ret = 1
	end
	if isToFree then
		if ret > 0 then
			LXFW.LxLog.log(tips .. " | CheckMemoryStatus | " .. memApp .. "/" .. fMemLimitAppUsed)
		elseif (ret < 0) then
			LXFW.LxLog.log(tips .. " | CheckMemoryStatus | " .. fMemSysAvail .. "/" .. fMemLimitSysAvail)
			--self:OnLowMemory("sys_low_memory")
		end
	end
	return ret
end

-------------------------------------------------------------------------------
--- on low memory
-------------------------------------------------------------------------------
function LGameMemory:OnLowMemory(title)
	local lowMemoryCount = self:AddLowMemoryCount()
	LXFW.LxLog.log(title .. " = " .. lowMemoryCount)
	self:QuerySystemMemory()
	self:ReportMemory()

	-- if (lowMemoryCount > 5) then
	-- LogError(title.." = restart")
	-- RestartGame()
	-- end
end
function LGameMemory:AddLowMemoryCount()
	local lowMemoryCount = self._lowMemoryCount
	if not lowMemoryCount then
		lowMemoryCount = 1
	else
		lowMemoryCount = lowMemoryCount + 1
	end
	self._lowMemoryCount = lowMemoryCount
	return lowMemoryCount
end


function LGameMemory:GetCpuInfo()
	local sCpuInfo = "cpu="..USystemInfo.processorType .. ",count=" .. USystemInfo.processorCount .. ",frequency=" .. (USystemInfo.processorFrequency/1000).."G"
	return sCpuInfo
end

function LGameMemory:GetGpuInfo()
	local sGpuInfo = USystemInfo.graphicsDeviceName
	return sGpuInfo
end

function LGameMemory:GetMemoryInfo()
	local fMemSysTotal = math.round(USystemInfo.systemMemorySize/1000).."G"
	return fMemSysTotal
end

function LGameMemory:GetMemorySize()
	local fMemSysTotal = math.round(USystemInfo.systemMemorySize)
	return fMemSysTotal
end

--设备厂商
function LGameMemory:GetDeviceCp()
	if CS.IsOSAndroid() then
		local sDeviceInfo = LNativeHelper.GetDeviceInfo()
		local arrList = string.split(sDeviceInfo,"|,") or {}
		local modelStr = arrList[1] or ""
		local brandStr = arrList[2] or ""
		local manufacturerStr = arrList[3] or ""
		return manufacturerStr
	elseif CS.IsOSOpenHarmony() then
		return "Huawei"
	elseif CS.IsOSIos() then
		return "Apple"
	else
		return "microsoft"
	end
end

----设置ab包内存
--function LGameMemory:SetAssetBunbleMemory(bundleName, size, isRemove)
--	if isRemove then
--		self.assetBundleMemData[bundleName] = nil;
--	else
--		self.assetBundleMemData[bundleName] = size;
--	end
--	self:UpdateAssetBunbleTotalMemory(size, isRemove);
--end
--
----获取ab包内存
--function LGameMemory:GetAssetBunblememory(bundleName)
--	return self.assetBundleMemData[bundleName] or 0
--end
--
----更新ab包总内存
--function LGameMemory:UpdateAssetBunbleTotalMemory(size, isRemove)
--	--gprint("UpdateAssetBunbleTotalMemory", size, isRemove)
--	if size == nil or not self.assetBundleTotalMemory == nil then
--		gprint("UpdateAssetBunbleTotalMemory size or  self.assetBundleTotalMemory nil", size, isRemove, self.assetBundleTotalMemory)
--		return
--	end
--	size = size / 1024 / 1024
--	if isRemove then
--		self.assetBundleTotalMemory = self.assetBundleTotalMemory - size
--		if self.assetBundleTotalMemory < 0 then
--			self.assetBundleTotalMemory = 0
--		end
--	else
--		self.assetBundleTotalMemory = self.assetBundleTotalMemory + size
--	end
--	--gprint("UpdateAssetBunbleTotalMemory assetBundleTotalMemory", self.assetBundleTotalMemory)
--end
--
----是否ab包超过内存最大峰值
--function LGameMemory:IsAssetBunbleMaxMemory()
--	if LGameSettings.assetBundleMaxMemory > 0 and self.assetBundleTotalMemory > LGameSettings.assetBundleMaxMemory then
--		return true
--	end
--	return false
--end

-------------------------------------------------------------------------------
return LGameMemory



