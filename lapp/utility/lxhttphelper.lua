---
--- Created by Admin.
--- DateTime: 2023/10/2 23:12
---
------------------------------------------------------------------
local Time = Time
local JSON = JSON
local LxTimer = LXFW.LxTimer
local CS = CS
---@class LxHttpHelper
local LxHttpHelper = LxClass("LxHttpHelper", nil)
------------------------------------------------------------------
LxHttpHelper.RETRY_MAX = 2
LxHttpHelper.GET_MODE_TIME = 30
------------------------------------------------------------------
--- DoWebRequestURL
------------------------------------------------------------------
function LxHttpHelper.DoWebRequestURL(isPostMode, urlList, urlSuffix, func, isFixTimestamp, retryMax)
	if not string.isempty(urlSuffix) then
		local newUrlList = {}
		for k,v in ipairs(urlList) do
			newUrlList[k] = v..urlSuffix
		end
		urlList = newUrlList
	end
	if isFixTimestamp == nil then
		isFixTimestamp = true
	end
	if isPostMode then
		MgrCenter.HttpMgr:DoPost(urlList, function(url, isOk, result)
			if func then
				func(isOk and CS.YXWebRet.ok or CS.YXWebRet.Error, result, url)
			end
		end, not isFixTimestamp, retryMax)
	else
		MgrCenter.HttpMgr:DoGet(urlList, function(url, isOk, result)
			if func then
				func(isOk and CS.YXWebRet.ok or CS.YXWebRet.Error, result, url)
			end
		end, not isFixTimestamp, retryMax)
	end
end
------------------------------------------------------------------
--- DoWebRequestURL
------------------------------------------------------------------
function LxHttpHelper.DoWebDownFile(fileUrlList, func, isFixTimestamp)
	local retLoading = CS.YXWebRet.Loading
	MgrCenter.HttpMgr:DoDownload(fileUrlList, nil, function(url, isOk, result)
		if func then
			local ret = isOk and CS.YXWebRet.ok or CS.YXWebRet.Error
			func(url, ret, result, 1, result)
		end
	end, function(url, progress)
		if func then
			func(url, retLoading, nil, progress, nil)
		end
	end, not isFixTimestamp)
end

------------------------------------------------------------------
--- Check WebRequest URL Is OK!
------------------------------------------------------------------
function LxHttpHelper.CheckWebDownFile(fileUrlList, func)
	MgrCenter.HttpMgr:DoHead(fileUrlList, function(url, isOk, result)
		if func then
			func(isOk and CS.YXWebRet.ok or CS.YXWebRet.Error, result, url)
		end
	end)
end
------------------------------------------------------------------
--- CheckWebJson
------------------------------------------------------------------
function LxHttpHelper.CheckWebJson(ret, result, url)
	if ret ~= CS.YXWebRet.ok then
		LogError(tostring(ret) .. " | " .. tostring(result))
		return nil
	end
	local objJson, jsonErr = JSON.decode(result)
	if not objJson then
		LogError("json err | " .. jsonErr .. " | " .. result)
		return nil
	end
	if objJson.code ~= 0 then
		LogError(tostring(objJson.code) .. " | " .. tostring(objJson.msg))
		return nil
	end
	return objJson
end
------------------------------------------------------------------

return LxHttpHelper