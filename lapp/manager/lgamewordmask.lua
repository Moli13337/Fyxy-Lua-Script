local LxBaseMgr = require("LApp.Manager.LxBaseMgr")
---@class LGameWordMask:LxBaseMgr
local LGameWordMask = LxClass("LGameWordMask",LxBaseMgr)

LGameWordMask.ZHIJIE = 1 ---字节

LGameWordMask.SCENE_TYPE_PUBLIC_DATA = 1204  ---公开编辑资料
LGameWordMask.SCENE_TYPE_PUBLIC_CHAT = 1201  ---通用公开聊天场景
LGameWordMask.SCENE_TYPE_HALF_PUBLIC_CHAT = 1202  ---通用半公开聊天场景
LGameWordMask.SCENE_TYPE_PRIVATE_CHAT = 1203  ---通用私密聊天场景


function LGameWordMask:Initialize()
    LxBaseMgr.Initialize(self)

    self._reqList = {}
    self._reqIndex = 1
    self._curData = nil
    self._reqInfoMap ={
        [LGameWordMask.ZHIJIE] = {
            app_id = "262959",
            url = "https://bcms-sandbox.bytedance.com/gcs/api/v1/review_client",
            --url = "https://bcms.bytedance.com/gcs/api/v1/review_client",
            accessKey = "3198a3f5bc1bc1455391d0a1a54df484",
            secretKey = "5275f3e7e18b1047f38a8e2a82e7c16e",
            expiration = 5,
            appid_src = 0,
            cc_type = 1
        }
    }
    self._cacheMaxCnt = 20
    self._cacheResult = {
        cacheList = {},
        cacheMap ={},
    }
end


local sceneTypeToWxTypeMap = {
    --场景枚举值（1 资料；2 评论；3 论坛；4 社交日志）
    --类型: 1私聊; 2 喇叭;3 邮件;4 世界;5 国家; 6 工会/帮 会;7队伍 ;8 附近 ;9 创角;  10 其他;

    [LGameWordMask.SCENE_TYPE_PUBLIC_CHAT] = {"3", "4"},  ---通用公开聊天场景
    [LGameWordMask.SCENE_TYPE_HALF_PUBLIC_CHAT] = {"3", "10"},  ---通用半公开聊天场景
    [LGameWordMask.SCENE_TYPE_PRIVATE_CHAT] = {"3", "1"},  ---通用私密聊天场景
    [LGameWordMask.SCENE_TYPE_PUBLIC_DATA] = {"1", "10"},  ---公开编辑资料
}

function LGameWordMask:OnWxMsgSecCheckCallback(msgId, isOk)
    if self._curData then
        if LOG_INFO_ENABLED then
            printInfoN2("wordmask", string.format("msg sec check callback msgId = %s isOk = %s", tostring(msgId), tostring(isOk)))
        end
        if self._curData.msgId ~= msgId then
            if LOG_INFO_ENABLED then
                printInfoN2("wordmask", string.format("msgsec check not work msgId = %s needmsgid = %s", tostring(msgId), tostring(self._curData.msgId)))
            end
            return
        end
        local content = self._curData.content
        self:AddCacheList(content, isOk and content or "")
        local retCode = isOk and 0 or 1

        local func = self._curData.func
        if func then
            func(retCode, content)
        end
    end
    self._curData = nil
    if #self._reqList > 0 then
        local data = table.remove(self._reqList)
        self._curData = data
        gLSdkImpl:CallMethod(LSdkMethod.MsgSecCheckNew, data.msgId, data.content, data.sceneType, data.funcType)
    end
end

function LGameWordMask:CheckStringMaskWx(content,sceneType,func)
    local cache = self:GetCacheText(content)
    if cache then
        if func then
            local retCode = cache == content and 0 or 1
            func(retCode,content)
        end
        return
    end

    local typeData =  sceneTypeToWxTypeMap[sceneType] or sceneTypeToWxTypeMap[LGameWordMask.SCENE_TYPE_PUBLIC_CHAT]
    sceneType = typeData[1]
    local funcType = typeData[2]

    local msgId = self:GetMsgId()
    local timestamp = os.time()

    local data =
    {
        msgId = msgId,
        content = content,
        func = func,
        timestamp = timestamp,
        sceneType = sceneType,
        funcType = funcType
    }

    if not self._curData or (self._curData.timestamp - timestamp) > 10 then
        self._curData = data
        gLSdkImpl:CallMethod(LSdkMethod.MsgSecCheckNew, msgId, content, sceneType, funcType)
    else
        table.insert(self._reqList,data)
    end
end

function LGameWordMask:CheckStringMask(content,sceneType,func)
    local needCheck = false

    if not needCheck then
        if func then
            func(0,content)
        end
        return
    end


    local cache = self:GetCacheText(content)
    if cache then
        if func then
            local retCode = cache == content and 0 or 1
            func(retCode,cache)
        end
        return
    end

    local msgId,data,timestamp = self:FormatZhiJieMsg(content,sceneType)
    local checkContent = JSON.encode(data)
    self:CheckStringMask_ZhiJie(msgId,checkContent,timestamp,content,func)
end

function LGameWordMask:GetMsgId()
    local playerId = gLGameLogin:GetPlayerId() or nil
    local time = os.time()
    local msgId = string.format("%s_%s_%s",playerId,time,self._reqIndex)
    self._reqIndex = self._reqIndex + 1
    return msgId
end

function LGameWordMask:FormatZhiJieMsg(content,sceneType)
    local info = self._reqInfoMap[LGameWordMask.ZHIJIE]
    local msgId = self:GetMsgId()
    local timestamp = os.time()
    local contentList = {}
    table.insert(contentList,{
        ["content_id"] = "text_1",
        ["content_type"] = 1,
        ["content"] = content,
        ["desc"] ="",
    })

    local data = {
        ["app_id"] = info.app_id,
        ["appid_src"] = info.appid_src,
        ["scene_type"] = sceneType,
        ["cc_type"] = info.cc_type,
        ["msg_id"] = msgId,
        ["send_ts_sec"] = timestamp,
        ["content_list"]= contentList,
    }
    return msgId,data,timestamp
end

function LGameWordMask:CheckStringMask_ZhiJie(msgId,content,timestamp,defaultText,func)
    local info = self._reqInfoMap[LGameWordMask.ZHIJIE]
    local url = info.url
    local accessKey = info.accessKey
    local secretKey = info.secretKey
    local expiration = info.expiration
    local signature = CS.YXUtility.GetSha256Sign("auth-v1/{0}/{1}/{2}",accessKey,secretKey,content,expiration,timestamp)
    local auth = string.format("auth-v1/%s/%s/%s/%s",accessKey,timestamp,expiration,signature)
    local httpHeaderData = CS.HttpHeaderData.New()
    if LOG_INFO_ENABLED then
        printErrorN(string.format("auth: %s",auth))
        printErrorN(string.format("request json: %s",content))
    end
    httpHeaderData:AddHeader("Agw-Auth",auth)
    httpHeaderData:AddHeader("Content_Type","application/json")
    table.insert(self._reqList,{
        msgId = msgId,
        url= url,
        content = content,
        httpHeaderData = httpHeaderData,
        func = func,
        defaultText = defaultText,
    })
    self:CheckStartReq()
end

function LGameWordMask:CheckStartReq()
    if self._wait then return end

    local data = table.remove(self._reqList,1)
    if not data then return end
    
    MgrCenter.HttpMgr:DoPostByBody(data.url,data.content,data.httpHeaderData,function(url,isOk,result)
        self._wait = false

        self:DealCheckRet(data,isOk,result)

        self:CheckStartReq()
    end, nil ,true)
end

function LGameWordMask:DealCheckRet(srcData,webRet,result)
    local retCode = 0
    local newText = srcData.defaultText
    if webRet ~= CS.YXWebRet.ok then
        retCode = -1
    else
        local retData = JSON.decode(result)
        local retContent = retData and retData.data and retData.data.result
        if retContent then
            local itemList = retContent and retContent["review_details"]
            local item = itemList and itemList[1]
            if item then
                local matchList = item["word_match_list"]
                if #matchList> 0 then
                    retCode = 1
                    newText = item["filter_text"]
                end
            end
        end
    end

    if LOG_INFO_ENABLED then
        printErrorN(string.format("fiter text %s",newText))
    end

    self:AddCacheList(srcData.defaultText,newText)

    ---retCode -1:网络错误; 0: 没有检测到屏蔽字; 1:存在屏蔽字;
    if srcData.func then
        srcData.func(retCode,newText)
    end
end

function LGameWordMask:AddCacheList(defaultText,newText)
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

function LGameWordMask:GetCacheText(defaultText)
    local cacheMap = self._cacheResult.cacheMap
    local cache = cacheMap[defaultText]
    return cache
end



return LGameWordMask