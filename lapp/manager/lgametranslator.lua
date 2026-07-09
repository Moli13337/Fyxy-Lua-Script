local LxBaseMgr = require("LApp.Manager.LxBaseMgr")
---@class LGameTranslator:LxBaseMgr
local LGameTranslator = LxClass("LGameTranslator",LxBaseMgr)

LGameTranslator.KEY = ""

function LGameTranslator:Initialize()
    LxBaseMgr.Initialize(self)
    self._isExist = true

    self._cacheMaxCnt = 20

    self._cacheResult = {
        cacheList = {},
        cacheMap ={},
    }

    self._serviceUrl = "web/api/translation.do"

    self._reqList = {}

end

---回调参数 code -1:失败 0:成功; content 翻译后文本
function LGameTranslator:GetTranslate(content,func)
    if not self._isExist then
        if not func then
            func(0,content)
        end
        return
    end

    local cache = self:GetCacheText(content)
    if cache then
        if func then
            func(0,cache)
        end
        return
    end

    local translateType = 1
    local timeStamp = tostring(GetTimestamp() * 1000)
    local httpKey = LGameLogin.AuthKey
    local sign = string.format("%s%s%s%s",timeStamp,httpKey,translateType,content)
    local signMd5 = string.upper(CS.md5FromString(sign))
    local str = JSON.encode({
        type = translateType,
        timestamp = timeStamp,
        sign = signMd5,
        text = content,
        dist = self:GetTarget(),
        format = "text"
    })
    self:StartReq(str,func,content)
end

function LGameTranslator:GetTarget()
    local lng = gLGameLanguage:GetLanguageFlag()
    local ref = GameTable.MulLanguageShowRef[lng]
    local tag = ref and ref.googleMark
    return tag or "en"
end

function LGameTranslator:StartReq(str,func,defaultText)
    local httpHeaderData = CS.HttpHeaderData.New()
    httpHeaderData:AddHeader("Content_Type","application/json")

    local urlList = gLGameLogin:GetServicesUrlList()
    local tmpUrlList = {}
    for k,url in ipairs(urlList) do
        table.insert( tmpUrlList, string.format("%s%s",url,self._serviceUrl))
    end

    table.insert(self._reqList,{
        url = tmpUrlList,
        content = str,
        func = func,
        httpHeaderData = httpHeaderData,
        defaultText = defaultText
    })
    self:CheckStartReq()
end

function LGameTranslator:CheckStartReq()
    if self._wait then return end

    local data = table.remove(self._reqList,1)
    if not data then return end

    self._wait = true
    MgrCenter.HttpMgr:DoPostByBody(data.url, data.content, data.httpHeaderData,function (url, isOk, result)
        self._wait = false
        self:DealCheckRet(data,isOk,result)
        self:CheckStartReq()
    end, nil , true)
end

function LGameTranslator:DealCheckRet(srcData,webRet,result)
    local retCode = 0
    local newText = srcData.defaultText
    if webRet ~= CS.YXWebRet.ok then
        retCode = -1
        printErrorN(string.format("translate error info:%s",result))
    else
        printInfoN("content "..result)
        if result then
            local retdata = JSON.decode(result)
            if retdata and retdata.code == 0 then
                newText = retdata.tranResult
            else
                retCode = -1
            end
        else
            retCode = -1
        end
    end

    if LOG_INFO_ENABLED then
        printErrorN(string.format("translate text %s",newText))
    end

    if retCode == 0 then
        self:AddCacheList(srcData.defaultText,newText)
    end

    ---retCode -1:网络错误; 0: 成功;
    if srcData.func then
        srcData.func(retCode,newText)
    end
end

function LGameTranslator:AddCacheList(defaultText,newText)
    local cacheMap = self._cacheResult.cacheMap
    local cache = cacheMap[defaultText]
    if cache then return end

    local list = self._cacheResult.cacheList
    local cnt = #list
    if cnt > self._cacheMaxCnt then
        local oldText = table.remove(self._cacheResult.cacheList,1)
        self._cacheResult.cacheMap[oldText] = nil
    end

    table.insert(list,defaultText)
    cacheMap[defaultText]= newText
end

function LGameTranslator:GetCacheText(defaultText)
    local cacheMap = self._cacheResult.cacheMap
    return cacheMap[defaultText]
end

return LGameTranslator