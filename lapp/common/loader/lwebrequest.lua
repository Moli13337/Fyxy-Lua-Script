local LWebRequest = LxClass("LWebRequest")


local UnityWebRequest = UnityEngine.Networking.UnityWebRequest
local UnityWebRequestResult = UnityWebRequest.Result
local typeUnityWebRequest = typeof(UnityWebRequest)

LWebRequest.LOADING = 11
LWebRequest.OK = 0
LWebRequest.ERROR= -1
LWebRequest.TIMEOUT= -2

local _UnityWebRequestResult ={
    Success = UnityWebRequestResult.Success
}


function LWebRequest:LWebRequest()
    self._tryCntMax = 2
    self._timeOut = 30
end


function LWebRequest:HttpDownFile(url,callback)
    self._url = url
    self._callback = callback

    self._tryCnt = 1
    self:StartLoad()
end

function LWebRequest:CompareVer(unityVer, tarVer)
	local symbol = '.' 	
	local verList1 = string.split(unityVer, symbol)
	local verList2 = string.split(tarVer, symbol)
	-- 只对比前两位
	for i=1,2 do
		local v1 = tonumber(verList1[i]) or 0
		local v2 = tonumber(verList2[i]) or 0
		if v1 ~= v2 then
			return (v1 - v2)
		end
	end
	return 0
end

function LWebRequest:StartLoad()
    self:Clear()

    local webRequest = UnityWebRequest.Get(self._url)
    webRequest.timeout = self._timeOut
	local unityVer = CS.UApplication.unityVersion
	if self:CompareVer(unityVer, "2018.4.36f1") <= 0 then
		webRequest.chunkedTransfer = true
	end
    webRequest.disposeDownloadHandlerOnDispose = true
    webRequest:SendWebRequest()

    self._webRequest = webRequest

    local timer = LFrameTimer.New(function () self:Loading() end, 1, -1)
    timer:Start()
    self._timer = timer
end

function LWebRequest:Loading()
    local webRequest = self._webRequest
    if not webRequest.isDone then
        if self._callback then
            self._callback(self._url,LWebRequest.LOADING,"",webRequest.downloadProgress)
        end
    else
        if webRequest.result ~= _UnityWebRequestResult.Success then
            self:Retry(LWebRequest.ERROR,webRequest.error)
        else
            self:OnLoadEnd(LWebRequest.OK,"",1,webRequest.downloadHandler.data)
        end
    end
end

function LWebRequest:Retry(webRet,result)
    if self._tryCnt > self._tryCntMax then
        self:OnLoadEnd(webRet,result,0)
        return
    end

    self._tryCnt = self._tryCnt + 1
    self:StartLoad()
end

function LWebRequest:OnLoadEnd(webRet,result,progress,data)
    self:Clear()
    if self._callback then
        self._callback(self._url,webRet,result,progress,data)
    end
end

function LWebRequest:Clear()
    if self._timer then
        self._timer:Stop()
    end

    self._timer = nil

    if self._webRequest then
        if not self._webRequest.isDone then
            self._webRequest:Abort()
        end
        self._webRequest:Dispose()
    end

    self._webRequest = nil
end

function LWebRequest:Destroy()
    if self._isDestroy then
         return
    end
    self:Clear()
    table.removeall(self)
    self._isDestroy = true
end

return LWebRequest














