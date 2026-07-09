---
--- Created by LCM.
--- DateTime: 2024/3/21 19:53:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopePray:LWnd
local UIHopePray = LxWndClass("UIHopePray", LWnd)

local Tweening = DG.Tweening
local typeRectTransform = typeof(UnityEngine.RectTransform)


UIHopePray.EFFTYPE_ZD = "fx_mjzhadan"     -- 炸弹
UIHopePray.EFFTYPE_QQ = "fx_ui_qipaochuopo"     -- 气球

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopePray:UIHopePray()
    self._waitCountDownTimerKey = "waitCountDownTimerKey"           -- 倒计时3秒开始
    self._createQiQiuTimerKey = "createQiQiuTimerKey"               -- 创建气球倒计时
    self._paryTimeKey = "paryTimeKey"                               -- 游戏时间


    self._countDownTime = 3                                         -- 倒计时
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopePray:OnWndClose()
    self:ClearSeqList()
    self:ClearTimerList()
    self:HideQiPaoTransList()
    GF.CloseWndByName("UIOrdinSowMsg")
    FireEvent(EventNames.ON_FDT_EVENT_CLOSEUI)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopePray:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopePray:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
    GF.OpenWnd("UIOrdinSowMsg")
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
    self:InitImgList()
	self:InitTimeList()
	self:InitNeedAddItemList()
    self:CreateTimer(self._waitCountDownTimerKey,1,-1)
end

function UIHopePray:InitText()
    self:SetWndText(self.mLimitTxt,ccClientText(28725))
end

function UIHopePray:FinishTask()
    self:TimerStop(self._paryTimeKey)
    self:TimerStop(self._createQiQiuTimerKey)
    self:ClearSeqList()
    self:ClearTimerList()
    self:HideQiPaoTransList()
    self:SendMsg()
end

function UIHopePray:InitData()

    ---@type StructDreamTripEventInfo
    local eventInfo = self:GetWndArg("eventInfo")
    self._eventInfo = eventInfo

    local gameParams = self:GetWndArg("gameParams")
    self._gameParams = gameParams

    self._eventId = eventInfo.eventId
    self._index = eventInfo.index
    self._eventRefId = eventInfo.eventRefId
    self._eventType = eventInfo.eventType

    self:InitTransInfoData()
    self:InitConfigData()
    self:InitChangeData()

    self._useItemList = {}
    self._seqList = {}
    self._timerList = {}
    self._qipaoTransList = {}
end

function UIHopePray:RunParyTimer()
    self:InitTimeList()
    self._changeParyTime = self._changeParyTime - 1
    if self._changeParyTime < 0 then
        self:FinishTask()
    end
end

function UIHopePray:InitConfigData()
    local configMap = {}
    local eventRefId = self._eventRefId
    local config = gModelFastDreamTrip:GetDreamTripEventConfigByRefId(eventRefId)
    if not string.isempty(config) then
        local configList = string.split(config,"|")
        local key,value
        for i,v in ipairs(configList) do
            v = string.split(v,"=")
            key = v[1]
            value = v[2]
            configMap[key] = value
        end
    end

    --- 祈愿事件：游戏参与时间s
    local paryTimeKey = "paryTime"
    local paryTime = configMap[paryTimeKey] or gModelFastDreamTrip:GetConfigByKey(paryTimeKey)
    paryTime = tonumber(paryTime)
    self._paryTime = paryTime


    --- 祈愿事件：道具刷新间隔时间（区间内随机）
    self._paryRefreshList = {}
    local paryRefreshKey = "paryRefresh"
    local paryRefresh = configMap[paryRefreshKey] or gModelFastDreamTrip:GetConfigByKey(paryRefreshKey)
    paryRefresh = string.split(paryRefresh,";")
    for i,v in ipairs(paryRefresh) do
        table.insert(self._paryRefreshList,tonumber(v))
    end


    --- 祈愿事件：每次随机刷新路线个数&刷新道具个数（区间内随机）
    self._paryPathList = {}
    local paryPathKey = "paryPath"
    local paryPath = configMap[paryPathKey] or gModelFastDreamTrip:GetConfigByKey(paryPathKey)
    paryPath = string.split(paryPath,";")
    for i,v in ipairs(paryPath) do
        table.insert(self._paryPathList,tonumber(v))
    end


    local parySpeedList = {}
    --- 祈愿事件：气球位移速度（区间内随机）
    local parySpeedKey = "parySpeed"
    local parySpeed = configMap[parySpeedKey] or gModelFastDreamTrip:GetConfigByKey(parySpeedKey)
    parySpeed = string.split(parySpeed,";")
    for i,v in ipairs(parySpeed) do
        table.insert(parySpeedList,tonumber(v))
    end
    self._parySpeedList = parySpeedList

--[[    local parySpeedMin = tonumber(parySpeed[1])
    local parySpeedMax = tonumber(parySpeed[2])
    self._parySpeedMin = parySpeedMin
    self._parySpeedMax = parySpeedMax]]


    --- 祈愿事件：获取上限个数（服务端验证）
    local paryNumKey = "paryNum"
    local paryNum = configMap[paryNumKey] or gModelFastDreamTrip:GetConfigByKey(paryNumKey)
    self._paryNum = tonumber(paryNum)


    --- 祈愿事件：祈愿事件炸弹id
    local paryBombKey = "paryBomb"
    local paryBomb = configMap[paryBombKey] or gModelFastDreamTrip:GetConfigByKey(paryBombKey)
    paryBomb = string.split(paryBomb,"=")
    self._paryBombInfo = paryBomb
    self._paryBombId = tonumber(paryBomb[2])


    self._showItemList = {}
    --local playStarListKey = "playStarList"
    --local playStarList = configMap[playStarListKey] or gModelFastDreamTrip:GetConfigByKey(playStarListKey)
    --if playStarList then
    --end
    self._playStarRefId = gModelFastDreamTrip:GetMainWndShowPayItem()

    self._showItemList = {
        [self._playStarRefId] = 0,
    }


    self._rewardList = {}
    local rewardIdList = {}

    local rewardList = gModelFastDreamTrip:GetDreamTripRewardListByByEventRefId(eventRefId)
    for idx,val in ipairs(rewardList) do
        table.insert(rewardIdList,val)
    end

    table.sort(rewardIdList,function(a,b)
        return a.refId < b.refId
    end)
    local allWeight = 0
    local weightList = {}
    for i,v in ipairs(rewardIdList) do
        local weight = v.weight
        local oldWeight = allWeight + 1
        allWeight = allWeight + weight
        table.insert(weightList,{
            minW = oldWeight,
            maxW = allWeight,
        })
    end
    self._weightList = weightList
    self._allWeight = allWeight

    self._rewardIdList = rewardIdList
end

function UIHopePray:CreateQiPao(rewardInfo)
    local areaTrans = self._areaTrans
    local templateTrans = self._templateTrans
    local itemNew = table.remove(self._userItemList)
    if not itemNew then
        itemNew = LxResUtil.NewObject(templateTrans.gameObject)
        itemNew.transform:SetParent(areaTrans.transform, false)
    end

    local width = self._width
    local center = width / 2
    local itemWidth = self._itemWidth
    local centerItemWidth = itemWidth / 2
    local leftPox =  - center + itemWidth
    local rightPos = center - itemWidth

    local posX = self:CommonGetRandomNum(leftPox,rightPos)

    if self._usePosList[posX] then
        posX = self:CommonGetRandomNum(leftPox,rightPos)
    end

    local leftPosX = posX - centerItemWidth
    local rightPosX = posX + centerItemWidth
    local isSame = false
    local samePos
    for k,v in pairs(self._usePosList) do
        local lW = k - centerItemWidth
        local rW = k + centerItemWidth
        if leftPosX >= lW and leftPosX <= rW then
            isSame = true
        elseif rightPosX >= lW and rightPosX <= rW then
            isSame = true
        end
        if isSame then
            samePos = k
            break
        end
    end

    local posY = - self._height / 2 - self._itemHeight
    if isSame and samePos then
        local count = math.random(1,5)
        posY = posY - self._itemHeight * count
    end

    local transform = itemNew.transform
    transform.anchoredPosition = Vector3.New(posX,posY,0)

    local key = transform:GetInstanceID()

    local extraData = {
        index = posX
    }
    self._qipaoTransList[key] = {
        qpTrans = transform,
        extraData = extraData
    }

    self._usePosList[posX] = true
    self:SetQiPaoTrans(transform,rewardInfo,extraData)

    self:DelayTimer(transform,extraData)
end

function UIHopePray:GetPrayRefId()
    local weightList = self._weightList
    local allWeight = self._allWeight
    local ramdonNum = self:CommonGetRandomNum(1,allWeight)
    for i,v in ipairs(weightList) do
        if v.minW <= ramdonNum and v.maxW >= ramdonNum then
            return i
        end
    end
    return 1
end

function UIHopePray:CreateTimer(key,time,loopCnt)
    loopCnt = loopCnt or -1
    self:TimerStop(key)
    self:TimerStart(key,time,false,loopCnt)
end

function UIHopePray:InitChangeData()
    self._changeParyTime = self._paryTime
    self._getRewardList = {}
    self._showRewardList = {}
    self._getCount = 0
end

function UIHopePray:RunCreateQiQiuTimer()
    local paryRefreshList = self._paryRefreshList
    local minNum = 1
    local maxNum = #paryRefreshList
    local randomNum = self:CommonGetRandomNum(minNum,maxNum)
    local randomTime = paryRefreshList[randomNum]
    self:CreateTimer(self._createQiQiuTimerKey,randomTime,1)
end

function UIHopePray:InitMsg()
    self:WndEventRecv(EventNames.ON_FDT_EVENT_FINISH,function(...) self:OnFDTEventFinish(...) end)
    self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList) self:WndClose() end)
end

function UIHopePray:InitTimeList()
    --- 使用程序字
    local changeParyTime = self._changeParyTime or 0
    self:SetWndText(self.mTimeCountDown,LUtil.FormatTimespanToMin2New(changeParyTime))

--[[    local list = self:GetTimeList()
    local uiTimeList = self._uiTimeList
    if uiTimeList then
        uiTimeList:RefreshList(list)
    else
        uiTimeList = self:GetUIScroll("uiTimeList")
        self._uiTimeList = uiTimeList
        uiTimeList:Create(self.mTimeList,list,function(...) self:OnDrawTimeCell(...) end)
    end]]
end

function UIHopePray:InitEvent()
    self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
end

function UIHopePray:CreateOnlyShowEFF(trans,extraData,effName,showTime)
    if trans then
        local EffRootTrans = self:FindWndTrans(trans,"EffRoot")
        if EffRootTrans then
            local BtnTrans = self:FindWndTrans(trans,"Bg/Btn")
            CS.ShowObject(BtnTrans,false)
            local key = EffRootTrans:GetInstanceID()
            self:CreateWndEffect(EffRootTrans,effName,key,100,false, false,nil,
                    nil,nil,nil,nil,function(dpTrans)
                        self:StopSeq(trans)
                        CS.ShowObject(EffRootTrans,true)
                        if dpTrans then
                            dpTrans.gameObject:SetActive(true)
                        end
                    end)
        end
    end
end

function UIHopePray:ClearSeqList()
    for k,v in pairs(self._seqList) do
        v:Kill(false)
    end
    self._seqList = {}
end

function UIHopePray:SendMsg()
    local rewardStr
    local getRewardList = self._getRewardList or {}
    for rewardId,num in pairs(getRewardList) do
        local str = rewardId .. "=" .. num
        if rewardStr then
            rewardStr = rewardStr .. ";" .. str
        else
            rewardStr = str
        end
    end
    gModelFastDreamTrip:OnDreamTripStartEventReq(self._eventId,{rewardStr})
end

function UIHopePray:ClearTimerList()
    for k,v in pairs(self._timerList) do
        LxTimer.DelayTimeStop(v)
    end
    self._timerList = {}
end

function UIHopePray:OnTimer(key)
    if key == self._waitCountDownTimerKey then
        self:RunWaitTime()
    elseif key == self._createQiQiuTimerKey then
        self:OnCreateQiQiu()
    elseif key == self._paryTimeKey then
        self:RunParyTimer()
    end
end

function UIHopePray:CreateHideTimer(key,trans,extraData,showTime,effName)
    local timer = LxTimer.DelayTimeCall(function()
        if not self:IsWndValid() then return end
        self:StopSeqInfo(trans,extraData)
        if effName == self._bombQPEff then
            self:ClearTimerList()
            --self:HideQiPaoTransList(trans:GetInstanceID())
            self:HideQiPaoTransList()
        end
    end,showTime,false)
    self._timerList[key] = timer
end

function UIHopePray:OnDrawNeedAddItemCell(list,item,itemdata,itempos)
    local IconTrans = self:FindWndTrans(item,"IconDiv/Icon")
    local NumTrans = self:FindWndTrans(item,"Num")
    local itemId = itemdata.itemId
    local itemNum = LUtil.NumberCoversion(itemdata.itemNum)

    local icon = gModelItem:GetItemIconByRefId(itemId)
    self:SetWndEasyImage(IconTrans,icon)

    self:SetWndText(NumTrans,itemNum)
end

function UIHopePray:TweenItem(item,extraData)
    local key = item:GetInstanceID()
    local seq = Tweening.DOTween.Sequence()
    self._seqList[key] = seq
    CS.ShowObject(item,true)
    local itemHeight = self._itemHeight
    local oldPos = item.anchoredPosition
    local oldLocalPos = item.localPosition
    local posX = oldPos.x
    local moveLocalY = oldLocalPos.y + self._height / 2
    if moveLocalY < 0 then
        moveLocalY = moveLocalY * -1
    end
    local moveY = itemHeight + self._height + moveLocalY
    local moveSpeed = 3
    local parySpeedList = self._parySpeedList
    local len = #parySpeedList
    if len > 0 then
        local randomNum = self:CommonGetRandomNum(1,len)
        moveSpeed = parySpeedList[randomNum]
    end
    local tween = YXTween.TweenFloat(0,1,moveSpeed,function (value)
        local pos = moveY * value
        item.anchoredPosition = Vector3.New(posX,oldPos.y + pos,0)
    end)
    seq:Append(tween)
    seq:SetAutoKill(true)
    seq:OnComplete(function()
        self:StopSeqInfo(item,extraData)
    end)
    seq:SetUpdate(true)
    seq:PlayForward()
end

function UIHopePray:OnFDTEventFinish(recordFinishMap,pb)
    if not recordFinishMap[self._eventId] then return end
    self:WndClose()
end

function UIHopePray:OnDreamTripStartEventResp(pb)
    if pb.eventId ~= self._eventId then return end
    local endInfo = pb.endInfo
    if not endInfo then return end
    if endInfo.state == StructDreamTripGrid.FINISH then
        self:WndClose()
    end
end

--[[function UIHopePray:DelayTimerOld(transform,extraData)
    local timeList = {
        0.5,0.8,0.1,0.6
    }
    local randomNum = self:CommonGetRandomNum(1,#timeList)
    local time = timeList[randomNum]

    local key = transform:GetInstanceID()
    local timer = nil
    timer = LxTimer.DelayTimeCall(function ()
        if not self:IsWndValid() then return end
        self:TweenItem(transform,extraData)
        LxTimer.DelayTimeStop(timer)
        self._timerList[key] = nil
    end,time,false)
    self._timerList[key] = timer
end]]


function UIHopePray:DelayTimer(item,extraData)
    local key = item:GetInstanceID()
    local seq = Tweening.DOTween.Sequence()
    self._seqList[key] = seq
    CS.ShowObject(item,true)
    local itemHeight = self._itemHeight
    local oldPos = item.anchoredPosition
    local oldLocalPos = item.localPosition
    local posX = oldPos.x
    local moveLocalY = oldLocalPos.y + self._height / 2
    if moveLocalY < 0 then
        moveLocalY = moveLocalY * -1
    end
    local moveY = itemHeight + self._height + moveLocalY
    local moveSpeed = 3
    local parySpeedList = self._parySpeedList
    local len = #parySpeedList
    if len > 0 then
        local randomNum = self:CommonGetRandomNum(1,len)
        moveSpeed = parySpeedList[randomNum]
    end
    local tween = YXTween.TweenFloat(0,1,moveSpeed,function (value)
        local movePos = Mathf.Lerp(oldPos.y,moveY,value)
        item.anchoredPosition = Vector3(posX,movePos,0)
--[[        local pos = moveY * value
        item.anchoredPosition = Vector3.New(posX,oldPos.y + pos,0)]]
    end)
    seq:Append(tween)
    seq:SetAutoKill(true)
    seq:OnComplete(function()
        self:StopSeqInfo(item,extraData)
    end)
    seq:SetUpdate(true)
    seq:PlayForward()

    --
end

function UIHopePray:StopSeq(item)
    local key = item:GetInstanceID()
    local seq = self._seqList[key]
    if seq then
        seq:Kill(false)
    end
    self._seqList[key] = nil
end

function UIHopePray:InitTransInfoData()
    local areaTrans = self.mArea
    self._areaTrans = areaTrans

    local width,height = 640,1136
    local rectTran = areaTrans:GetComponent(typeRectTransform)
    if rectTran then
        local rect = rectTran.rect
        width = rect.width
        height = rect.height
    end
    self._width = width
    self._height = height


    local templateTrans = self.mQiPaoTemplate
    self._templateTrans = templateTrans
    local itemWidth,itemHeight = 94,94
    local templateRectTrans = templateTrans:GetComponent(typeRectTransform)
    if templateRectTrans then
        local rect = templateRectTrans.rect
        itemWidth = rect.width
        itemHeight = rect.height
    end
    self._itemWidth = itemWidth
    self._itemHeight = itemHeight

    self._canSetNum = math.floor(width / itemWidth)


    self._lineSpacing = 10
    self._userItemList = {}
    -- 可用位置
    self._usePosList = {}
end

function UIHopePray:OnDrawTimeCell(list,item,itemdata,itempos)
    local ImgTrans = self:FindWndTrans(item,"Img")
    self:SetWndEasyImage(ImgTrans,itemdata,function()
        CS.ShowObject(ImgTrans,true)
    end,true)
end

function UIHopePray:SetQiPaoTrans(trans,rewardData,extraData)
    local IconTrans = self:FindWndTrans(trans,"Icon")
    local NumTrans = self:FindWndTrans(IconTrans,"Num")
    local BtnTrans = self:FindWndTrans(trans,"Bg/Btn")
    local EffRootTrans = self:FindWndTrans(trans,"EffRoot")
    CS.ShowObject(EffRootTrans,false)
    self:DestroyWndEffectByKey(EffRootTrans:GetInstanceID())
    CS.ShowObject(BtnTrans,true)
    local itemId = rewardData.itemId
    local itemNum = rewardData.itemNum

    local icon = gModelItem:GetItemIconByRefId(itemId)
    self:SetWndEasyImage(IconTrans,icon)

    self:SetWndText(NumTrans,itemNum)

    self:SetWndClick(BtnTrans,function()
        self:OnClickQiQiuFunc(rewardData,trans,extraData)
    end)
end

function UIHopePray:InitImgList()
    local clickQPEff,bombQPEff
    local countDownImgList
    local image = gModelFastDreamTrip:GetDreamTripEventImageByRefId(self._eventRefId)
    if not string.isempty(image) then
        local imageList = string.split(image,ModelDreamTrip.EVENTREF_IMAGE_SPLIT)
        --- 背景大图
        local bg = imageList[1]
        if not string.isempty(bg) then
            self:SetWndEasyImage(self.mBg,bg)
        end

        --- 标题底图
        local titleBg = imageList[2]
        if not string.isempty(titleBg) then
            self:SetWndEasyImage(self.mTimeCountDownBg,titleBg,nil,true)
        end

        --- 倒计时图片
        local countDownImg = imageList[3]
        if not string.isempty(countDownImg) then
            countDownImgList = {}
            local countDownImageList = string.split(countDownImg,",")
            for i,v in ipairs(countDownImageList) do
                v = string.split(v,"=")
                countDownImgList[tonumber(v[1])] = v[2]
            end
        end

        local QiPaoTemp = self.mQiPaoTemplate
        --- 气泡图素材
        local bubbleImg = imageList[4]
        if not string.isempty(bubbleImg) then
            local BgTrans = self:FindWndTrans(QiPaoTemp,"Bg")
            self:SetWndEasyImage(BgTrans,bubbleImg,nil,true)
        end

        --- 图标大小
        local bubbleSize = imageList[5]
        if not string.isempty(bubbleSize) then
            bubbleSize = tonumber(bubbleSize)
            local IconTrans = self:FindWndTrans(QiPaoTemp,"Icon")
            IconTrans.localScale = Vector3(bubbleSize,bubbleSize,bubbleSize)
        end

        --- 点击特效
        local clickEff = imageList[6]
        if not string.isempty(clickEff) then
            clickQPEff = clickEff
        end

        --- 爆炸特效
        local bombEff = imageList[7]
        if not string.isempty(bombEff) then
            bombQPEff = bombEff
        end

        --- 图标位置
        local iconPos = imageList[8]
        if not string.isempty(iconPos) then
            iconPos = string.split(iconPos,",")
            local IconTrans = self:FindWndTrans(QiPaoTemp,"Icon")
            IconTrans.localPosition = Vector3(tonumber(iconPos[1]) or 0,tonumber(iconPos[2]) or 0,tonumber(iconPos[3]) or 0)
        end

        --- 是否显示道具栏
        local showNeedItem = imageList[9]
        if not string.isempty(showNeedItem) then
            showNeedItem = tonumber(showNeedItem)
            local show = showNeedItem == 1
            CS.ShowObject(self.mNeedAddItemList,show)
        end
    end

    self._clickQPEff = clickQPEff or UIHopePray.EFFTYPE_QQ
    self._bombQPEff = bombQPEff or UIHopePray.EFFTYPE_ZD

    countDownImgList = countDownImgList or {
        [0] = "activity_music1_num_0",
        [1] = "activity_music1_num_1",
        [2] = "activity_music1_num_2",
        [3] = "activity_music1_num_3",
        [4] = "activity_music1_num_4",
        [5] = "activity_music1_num_5",
        [6] = "activity_music1_num_6",
        [7] = "activity_music1_num_7",
        [8] = "activity_music1_num_8",
        [9] = "activity_music1_num_9",
    }
    self._countDownImgList = countDownImgList
end

function UIHopePray:CreateShowEff(trans,extraData,effName,showTime)
    if trans then
        local EffRootTrans = self:FindWndTrans(trans,"EffRoot")
        if EffRootTrans then
            local BtnTrans = self:FindWndTrans(trans,"Bg/Btn")
            CS.ShowObject(BtnTrans,false)
            local key = EffRootTrans:GetInstanceID()
            self:CreateWndEffect(EffRootTrans,effName,key,100,false, false,nil,
                    nil,nil,nil,nil,function(dpTrans)
                        self:StopSeq(trans)
                        CS.ShowObject(EffRootTrans,true)
                        if dpTrans then
                            dpTrans.gameObject:SetActive(true)
                        end
                        local transKey = trans:GetInstanceID()
                        self:CreateHideTimer(transKey,trans,extraData,showTime,effName)
                        if effName == self._bombQPEff then
                            self:ClearSeqList()
                            self:ShowAllQPEff(trans:GetInstanceID())
                        end
                    end)
        end
    end
end

function UIHopePray:OnCreateQiQiu()
    self:TimerStop(self._createQiQiuTimerKey)
    local paryPathList = self._paryPathList
    local paryPathMin = 1
    local paryPathMax = #paryPathList

    local posList = {}
    for i = paryPathMin,paryPathMax do
        table.insert(posList,i)
    end

    local rewardList = self._rewardIdList
    local len = #rewardList
    local randomNum = self:CommonGetRandomNum(paryPathMin,paryPathMax)
    local randomPath = paryPathList[randomNum]
    for i = 1,randomPath do
        local randomRewardNum = self:GetPrayRefId()
        local rewardInfo = rewardList[randomRewardNum]
        self:CreateQiPao(rewardInfo)
    end
    self:RunCreateQiQiuTimer()
end

function UIHopePray:ShowAllQPEff(extraKey)
    for k,v in pairs(self._qipaoTransList) do
        if extraKey ~= k then
            local qpTrans = v.qpTrans
            if qpTrans and qpTrans.gameObject.activeSelf then
                local kouKey = qpTrans:GetInstanceID()
                self:TweenSeq_RootAlphaInOut({
                    aniKey = kouKey,
                    trans = qpTrans,
                    beforeFunc = function()
                        if not self:IsWndValid() then return end
                        CS.ShowObject(qpTrans,true)
                    end,
                    endFunc = function()
                        if not self:IsWndValid() then return end
                        CS.ShowObject(qpTrans,false)
                    end,
                    initAlpha = true,
                    loopNum = 2,
                    fromAlpha = 0,
                    toAlpha = 1,
                    toTime = 0.5,
                })
            end
        end
    end
end

function UIHopePray:RunWaitTime()
    local countDownTime = self._countDownTime
--[[    local img = self._countDownImgList[countDownTime]
    self:SetWndEasyImage(self.mCountDownImg,img,function()
        CS.ShowObject(self.mCountDownImg,true)
    end)]]
    self:SetWndText(self.mCountDownTxt,countDownTime)
    self._countDownTime = countDownTime - 1
    if self._countDownTime < 0 then
        CS.ShowObject(self.mCountDownBg,false)
        self:TimerStop(self._waitCountDownTimerKey)
        self:CreateTimer(self._paryTimeKey,1,-1)
        self:RunCreateQiQiuTimer()
    end
end

function UIHopePray:StopSeqInfo(item,extraData)
    self:StopSeq(item)
    self._usePosList[extraData.index] = false
    self:ReturnToPool(item)
end

function UIHopePray:CommonGetRandomNum(min,max)
    local ramdonNum = math.random(min,max)
    return ramdonNum
end

function UIHopePray:ReturnToPool(item)
    CS.ShowObject(item,false)
    table.insert(self._userItemList, item.gameObject)
end

------------------------- List -------------------------
function UIHopePray:GetTimeList()
    local countDownImgList = self._countDownImgList
    local list = {}
    local changeParyTime = self._changeParyTime
    local min = 0
    if changeParyTime > 3600 then
        min = math.floor(changeParyTime / 60) % 60
    end
    local zeroImg = countDownImgList[0]
    if min == 0 then
        table.insert(list,zeroImg)
        table.insert(list,zeroImg)
    else
        local tD = math.floor(min / 10)
        local sD = min % 10
        table.insert(list,countDownImgList[tD])
        table.insert(list,countDownImgList[sD])
    end
    table.insert(list,"activity_music1_ui_5")
    local sec = math.floor(changeParyTime) % 60
    if sec == 0 then
        table.insert(list,zeroImg)
        table.insert(list,zeroImg)
    else
        local tD = math.floor(sec / 10)
        local sD = sec % 10
        table.insert(list,countDownImgList[tD])
        table.insert(list,countDownImgList[sD])
    end
    return list
end

function UIHopePray:InitNeedAddItemList()
    local list = self:GetNeedAddItemList()
    local uiNeedAddItemList = self._uiNeedAddItemList
    if uiNeedAddItemList then
        uiNeedAddItemList:RefreshList(list)
    else
        uiNeedAddItemList = self:GetUIScroll("uiNeedAddItemList")
        self._uiNeedAddItemList = uiNeedAddItemList
        uiNeedAddItemList:Create(self.mNeedAddItemList,list,function(...) self:OnDrawNeedAddItemCell(...) end)
    end
end

function UIHopePray:GetNeedAddItemList()
    local list = {}
    for k,v in pairs(self._showItemList) do
        table.insert(list,{
            itemId = k,
            itemNum = v
        })
    end
    return list
end

function UIHopePray:HideQiPaoTransList(extraKey)
    for k,v in pairs(self._qipaoTransList) do
        if extraKey ~= k then
            CS.ShowObject(v.qpTrans,false)
        end
    end
end

function UIHopePray:OnClickQiQiuFunc(itemdata,trans,extraData)
--[[    if self._getCount >= self._paryNum then
        --- 次数上限
        return
    end]]

    --    优化需求3：不隐藏文本，改为显示进度
    --if self.mShowBg.gameObject.activeSelf then
    --    CS.ShowObject(self.mShowBg,false)
    --end

    local BtnTrans = self:FindWndTrans(trans,"Bg/Btn")
    CS.ShowObject(BtnTrans,false)
    local itemId = itemdata.itemId
    if itemId == self._paryBombId then
        self:CreateShowEff(trans,extraData,self._bombQPEff,1)
    else
        if self._getCount < self._paryNum then
            local getRewardList = self._getRewardList
            if not getRewardList then
                getRewardList = {}
                self._getRewardList = getRewardList
            end
            local refId = itemdata.refId
            if refId then
                local num = getRewardList[refId] or 0
                getRewardList[refId] = num + 1
            end

            local name = gModelItem:GetNameByRefId(itemId)
            local numStr = LUtil.NumberCoversion(itemdata.itemNum)

            local str = string.replace(ccClientText(28720),name,numStr)
            FireEvent(EventNames.ON_DREAMTRIP_SHOWMSG,3,str,self.mShowTxtRoot)

            self._getCount = self._getCount + 1

            local showItemNum = self._showItemList[itemId]
            if showItemNum then
                self._showItemList[itemId] = showItemNum + itemdata.itemNum
            end
            self:InitNeedAddItemList()
            self:CreateShowEff(trans,extraData,self._clickQPEff,0.5)

            gModelFastDreamTrip:PlayDreamTripSound(306)
        end

        local str = string.replace(ccClientText(28733),self._getCount,self._paryNum)
        self:SetWndText(self.mLimitTxt,str)

        if self._getCount >= self._paryNum then
            self:FinishTask()
        end
        --self:StopSeqInfo(trans,extraData)
    end
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIHopePray



