---
---活动83 每日锦鲤
--- Created by Ease.
--- DateTime: 2023/10/4 20:00:51
---
------------------------------------------------------------------
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local LWnd = LWnd
---@class UIAnniversaryDTDKoi:LWnd
local UIAnniversaryDTDKoi = LxWndClass("UIAnniversaryDTDKoi", LWnd)
UIAnniversaryDTDKoi.AniTypeIdle = 1 --未抽奖待机

UIAnniversaryDTDKoi.AniTypeOpen = 2
UIAnniversaryDTDKoi.AniTypeOpen2 = 3

UIAnniversaryDTDKoi.AniTypeIdle2 = 4 --国庆抽奖中待机
UIAnniversaryDTDKoi.AniTypeIdle3 = 5 --国庆抽奖完毕待机
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAnniversaryDTDKoi:UIAnniversaryDTDKoi()
    self._playerNum = nil --默认号码，玩家未抽取时显示
    self._firPrizer = ""
    self._prizeNum = "00000" --中奖号码 锦鲤号
    self._playerRecord = {} --玩家抽奖记录
    self._isGetNum = false

    self._page = {}--分页数据
    self._entry = {}--分页数据中中奖列表
    self._cfgEntry = {} --锦鲤奖励条目配置表
    self._cfgActivityName = "" --活动名称
    self._cfgSignHelpTips = "" --帮助窗口描述
    self._cfgSignImage = nil --背景图
    self._cfgHeadLine = nil --文字图片
    self._cfgHeroImage = nil--英雄背景图

    self._cfgSignImageHeroPos = nil--英雄背景偏移量
    self._cfgSignImagePos = nil--背景图偏移量
    self._cfgHeadLinePos = nil--艺术字偏移量

    self._cfgLotteryTime = 0

    self._prizeEndTime = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAnniversaryDTDKoi:OnWndClose()
    self:ClearCommonIconList(self._uiCommonList)
    if (self._timerList) then
        for key, timer in pairs(self._timerList) do
            LxTimer.LoopTimeStop(timer)
            timer = nil
        end
    end
    self._timerList = {}
    LWnd.OnWndClose(self)
    
    if self._timerNum then
        LxTimer.DelayTimeStop(self._timerNum )
    end 
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAnniversaryDTDKoi:OnCreate()
    LWnd.OnCreate(self)
    self._uiCommonList = {}
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAnniversaryDTDKoi:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isJapaness  =gLGameLanguage:IsJapanVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self._isSEA = gLGameLanguage:IsSEALngRegion()
    
    if self._isEnus or   self._isJapaness or self._isVie or  self._isSEA then 
        self:SetAnchorPos(self.mTimeCntTxt,Vector2.New(20,-23))
    end 
    
    self:InitBtnEvent()
    self:InitEvent()
    self:InitMessage()
    self:InitData()

    self:SetWndText(self.mTxtReturn, ccClientText(20723))
    --self:SetWndText(self.mShareBtnTxt, ccClientText(29625))

    CS.ShowObject(self.mSecMyNumImgList, false)
end
----中奖排名说明列表
function UIAnniversaryDTDKoi:InitRankList()
    local list = self._entry
    if (self._rankList) then
        self._rankList:RefreshList(list)
    else
        self._rankList = self:GetUIScroll("mRankList")
        self._rankList:Create(self.ranScroll, list, function(...)
            self:OnDrawItemCell(...)
        end, UIItemList.NORMAL)
        self._rankList:EnableScroll(true, false)
    end
end

function UIAnniversaryDTDKoi:UpdateSpineState()
    local aniName
    local isLoop = true
    local aniType = self._spinType
    if aniType == UIAnniversaryDTDKoi.AniTypeIdle then
        aniName = "idle"
    elseif aniType == UIAnniversaryDTDKoi.AniTypeOpen then
        self._isPlay = true
        aniName = "open"
        isLoop = false
    elseif aniType == UIAnniversaryDTDKoi.AniTypeOpen2 then
        aniName = "open2"
    elseif aniType == UIAnniversaryDTDKoi.AniTypeIdle2 then
        aniName = "idle2"
    elseif aniType == UIAnniversaryDTDKoi.AniTypeIdle3 then
        aniName = "idle3"
    end
    if (self._spineName) then
        local dpSpine = self:FindWndSpineByKey(self._spineName)
        if dpSpine then
            if (aniType == UIAnniversaryDTDKoi.AniTypeOpen) then
                dpSpine:SetAnimationCompleteFunc(function()
                    if (self._uiPrefab and self._uiPrefab == 2) then
                        dpSpine:SetAnimationCompleteFunc()
                        self:SetSpineAni(UIAnniversaryDTDKoi.AniTypeIdle2)
                        local totalTime = self:GetAniTypeIdle2PlayTotalTime()
                        local timerKey = "SpineIdle2End"
                        local timer = LxTimer:New()
                        timer:TimerRemoveByKey(timerKey)
                        timer:TimerCreate(timerKey, function(...)
                            self:SetSpineAni(UIAnniversaryDTDKoi.AniTypeIdle3)
                        end, totalTime, false, 1)
                        self._timerList[timerKey] = timer
                    else
                        self:SetSpineAni(UIAnniversaryDTDKoi.AniTypeOpen2)
                        if (self._spinType == UIAnniversaryDTDKoi.AniTypeOpen2) then
                            dpSpine:SetAnimationCompleteFunc()
                        end
                    end
                    self._isPlay = false
                end)
            elseif (aniType == UIAnniversaryDTDKoi.AniTypeIdle3 and not self._isClickGetBtn) then
                dpSpine:PlayAnimationSolid(aniName, nil, false)
                dpSpine:SetIgnoreTimeScale(true)
                return
            end
            dpSpine:PlayAnimation(0, aniName, isLoop, false)
        end
        dpSpine:SetIgnoreTimeScale(true)
    end
end
--刷新界面UI
function UIAnniversaryDTDKoi:RefreshUI()
    self:StopShowPrizeTimer()
    self:StopShowTimer()
    self:StopStartDrawTimer()
    self:RefreshTime()
    local lotteryCfg = self._cfgLotteryTime
    local drawCfg = self._cfgDrawTime
    local lotteryStr = self:GetLotteryTime(lotteryCfg)
    local CanLottery = self:CheckCanLottery(drawCfg)
    CS.ShowObject(self.mTopNumGroup, not lotteryStr and not CanLottery)
    if (not lotteryStr and not CanLottery) then
        local prizeNum = self._prizeNum
        self:SetWndText(self.mPrizeNumDesTxt, ccClientText(29602))
        self:SetWndText(self.mPrizeNumTxt, prizeNum)
        local prizerName = self._firPrizer

        if not string.isempty(prizerName) then
            CS.ShowObject(self.mPrizerNameTxt, true)
            local prizerNameStr = string.replace(ccClientText(29603), prizerName)--29601 恭喜玩家 ：<color=#139057>%s</color>
            self:SetWndText(self.mPrizerNameTxt, prizerNameStr)
        else
            CS.ShowObject(self.mPrizerNameTxt, false)
        end

        CS.ShowObject(self.mTopTimeGroup, false)
    else
        CS.ShowObject(self.mTopTimeGroup, true)
        self._prizeEndTime = self:GetPrizeTime(lotteryCfg)
        self:ShowPrizeTimerFunc()
        self:TimerStart(self._prizeTimeKey, 1, false, -1)
    end
    self:SetWndText(self.mMyNumTxt, ccClientText(29606))
    if (self._isGetNum) then
        self:SetWndText(self.mGetBtnTxt, ccClientText(29605))--[29605]	[今日已抽取幸運號]
    else
        self:SetWndText(self.mGetBtnTxt, ccClientText(29604))--[29604]	[抽取幸運號碼]
    end
    self:SetBtnStateIsGray(self.mGetBtn, self._isGetNum or not CanLottery)
    CS.EnableClickListener(self.mGetBtn.gameObject, not self._isGetNum and CanLottery)
    CS.ShowObject(self.mGetBtn, true)
    CS.ShowObject(self.mRedPoint, not self._isGetNum and CanLottery)
    self:InitRankList()
    self:ShowTimerFunc()
    self:SetSpine()


    --我的奖励按钮红点 self._playerRecord
    self:SetMyRewardBtnRP()

    --设置我的数字
    if not self._isClickGetBtn then
        self:SetMyNum()
    end
end
function UIAnniversaryDTDKoi:SetUIPositon(imgTrans, position)
    if (position and not string.isempty(position)) then
        local pos = LxDataHelper.ParseVector2NotEmpty2(position)
        self:SetAnchorPos(imgTrans, pos)
    end
end
--获取开奖时间 getNum:true return number / false return string
function UIAnniversaryDTDKoi:GetLotteryTime(lotteryTime)
    local nowTime = GetTimestamp()
    local zeroTime = self:GetTodayTimeStamp()
    local lTime = zeroTime + lotteryTime--开奖时间戳
    local timeDif = os.difftime(lTime, nowTime)
    if (timeDif > 0) then
        local timeStr = LUtil.FormatTimeToCn1(timeDif)--xx时/xx分/xx秒
        return timeStr
    else
        return nil
    end
end
--奖励列表子项
function UIAnniversaryDTDKoi:RewardListItem(list, item, itemdata, itempos)
    local itemRoot = self:FindWndTrans(item, "itemRoot")
    local root = self:FindWndTrans(itemRoot, "Icon")
    local itemNum = self:FindWndTrans(item, "itemNum")
    local InstanceID = item:GetInstanceID()
    local baseClass = self._uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        self._uiCommonList[InstanceID] = baseClass
        baseClass:Create(root)
        self:SetIconClickScale(root, true)
    end
    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()
    self:SetWndText(itemNum, itemdata.itemNum)
    self:SetWndClick(root, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
end

--消息事件监听初始化
function UIAnniversaryDTDKoi:InitEvent()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)    --活动配置
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        --printInfoNR("----ON_TIME_ZERO----")
        gModelActivity:OnActivityPageReq(self._sid)
    end)

    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end
function UIAnniversaryDTDKoi:InitNumImgPos()
    for i = 1, 5 do
        local scrollTrans = CS.GetChild(self.mSecMyNumImgList, i - 1)
        for j = 1, 10 do
            local imgTrans = CS.GetChild(scrollTrans, j - 1)
            self:SetAnchorPos(imgTrans, Vector2.New(18, 0))
        end
    end
end
function UIAnniversaryDTDKoi:OnTimer(key)
    if key == self._showTimeKey then
        self:ShowTimerFunc()
    end
    if (key == self._prizeTimeKey) then
        self:ShowPrizeTimerFunc()
    end
    if (key == self._startDrawTimeKey) then
        self:SetBtnStateIsGray(self.mGetBtn, false)
        CS.ShowObject(self.mRedPoint, true)
        CS.EnableClickListener(self.mGetBtn.gameObject, true)
    end
end
--检测是否能够抽奖
function UIAnniversaryDTDKoi:CheckCanLottery(drawTime)
    local nowTime = GetTimestamp()
    local zeroTime = self:GetTodayTimeStamp()
    local dTimeArr = string.split(drawTime, "=")
    local dTime = zeroTime + dTimeArr[2]--开奖时间戳
    local timeDif = os.difftime(dTime, nowTime)
    local startTime = zeroTime + dTimeArr[1]
    local startTimeDif = os.difftime(startTime, nowTime)
    if (startTimeDif > 0) then
        self:TimerStart(self._startDrawTimeKey, startTimeDif, false)
    end
    return timeDif > 0 and startTimeDif <= 0
end

function UIAnniversaryDTDKoi:GetPrizeTime(lotteryTime, dayOffset)
    --local zeroTime = self:GetTodayTimeStamp(dayOffset)

    local zeroTime = LUtil.GetNextDayTimes(GetTimestamp(), dayOffset)

    local pTime = zeroTime + lotteryTime--开奖时间戳
    return pTime
end
--倒计时
function UIAnniversaryDTDKoi:ShowTimerFunc()
    local nowTime = GetTimestamp()
    local drawCfg = self._cfgDrawTime
    local drawTime = string.split(drawCfg, "=")
    local nextPrizeTime = self:GetPrizeTime(drawTime[1], 1)

    local timeDif
    local zeroTime = self:GetTodayTimeStamp()
    if (nowTime - zeroTime <= tonumber(drawTime[1])) then
        timeDif = os.difftime(zeroTime + tonumber(drawTime[1]), nowTime)
    else
        timeDif = os.difftime(nextPrizeTime, nowTime)
    end
    if timeDif <= 0 then
        self:StopShowTimer()
        return
    end
    local timeStr = LUtil.FormatTimespanCn(timeDif)

    timeStr = string.replace(ccClientText(29600), timeStr)--11637 [29601]	[剩餘倒計時：#a1#]
    self:SetWndText(self.mTimeTxt, timeStr)
    CS.ShowObject(self.mTimeBg, true)
end
--UI2套处理 设置滚动数字列表
function UIAnniversaryDTDKoi:SetSecMyNumImgList()
    if (self._uiPrefab and self._uiPrefab == 2) then
        self.secScrollList = self.secScrollList and self.secScrollList or {}
        local showNum = self._playerNum
        local numArr = LStringUtil.StringToCharArray(tostring(showNum))
        self.posList = {}
        for i = 1, 5 do
            --5组数字
            local scrollTrans = CS.GetChild(self.mSecMyNumImgList, i - 1)
            self.secScrollList[i] = scrollTrans
            for j = 1, 10 do
                --每组10个数字
                local path = string.format("%s%d", "activity_nationalday2_num_", 10 - j) -- 10-j:数字从下往上排
                local itemTrans = CS.GetChild(scrollTrans, 10 - j)
                self:SetWndEasyImage(itemTrans, path)
                itemTrans.name = 10 - j
                local offset = -58 * (j - 1)
                --[[
                -29为数字0坐标,
                58为数字图片高度,共10张图得出493为坐标数组1号位值
                493 = -29 + (58 * 9)
                 ]]
                local pos = Vector2.New(18, 493 + offset)
                self:SetAnchorPos(itemTrans, pos)
                self.posList[j] = -87 + ((j - 1) * 58)
            end
            --不是点击抽奖按钮打开窗口是直接显示数字
            if (not self._isClickGetBtn and showNum) then
                local itemTrans = CS.GetChild(scrollTrans, 0)
                local itemPath = string.format("%s%d", "activity_nationalday2_num_", numArr[i])
                --self:SetWndEasyImage(itemTrans, itemPath)
            end
        end
    end
    CS.ShowObject(self.mSecMyNumImgList, false)
    if (self._isClickGetBtn) then
        self._isClickGetBtn = false
        self:SetTweenNumImgTimer()
    end
end

--function UIAnniversaryDTDKoi:OnClickShare()
--    local data = {
--        root = self.mShareBtn,
--        shareType = self._shareId,
--        shareData = tostring(self._sid)
--    }
--    gModelGeneral:OpenShareTip(data)
--end

--设置数据
function UIAnniversaryDTDKoi:SetData()
    local cfgData = self._cfgData --配置表
    local activityData = gModelActivity:GetActivityBySid(self._sid)--activity pb
    local webActivityData = gModelActivity:GetWebActivityDataById(self._sid)
    if (not cfgData or not activityData) then
        return
    end
    local cfg = cfgData
    self._signHelpTips = cfg.signHelpTips or ""        --帮助窗口描述
    self._signHelpTitle = activityData.title or ""     --帮助窗口标题
    self._endActivityTime = activityData.endTime --活动结束时间
    self._startActivityTime = activityData.startTime --活动开始时间
    self._signHeroImage = cfg.signImageHero
    self._cfgHeadLine = cfg.headline    --艺术字标题
    self._cfgEntry = webActivityData.chunk[1].entries
end

function UIAnniversaryDTDKoi:SetTweenNumImgTimer()
    local num = self._playerNum
    if (not num or num == "") then
        return
    end
    local numArr = LStringUtil.StringToCharArray(tostring(self._playerNum))
    if not self._timerList then
        self._timerList = {}
    end
    local timeDur = 0.14  -- 速度
    for i, v in pairs(self.secScrollList) do
        local itemRoot = v
        local key = itemRoot:GetInstanceID()
        local keyDelay = key .. "Delay"
        local targetNum = tonumber(numArr[i])--目标值
        local loopCnt = 10 * i --完整圈数
        local totalLoopCnt = loopCnt + targetNum
        if self._timerList[keyDelay] then
            LxTimer.LoopTimeStop(self._timerList[keyDelay])
            self._timerList[keyDelay] = nil
        end
        local timer = LxTimer.LoopTimeCall(function()
            self:DoTweenNumImg(itemRoot, timeDur - 0.05)
        end, timeDur, false, totalLoopCnt)
        self._timerList[keyDelay] = timer
    end
end
--停止倒计时定时器
function UIAnniversaryDTDKoi:StopShowTimer()
    self:TimerStop(self._showTimeKey)
    CS.ShowObject(self.mTimeBg, false)
end
--按钮事件监听初始化
function UIAnniversaryDTDKoi:InitBtnEvent()
    --帮助按钮
    self:SetWndClick(self.mHelpBtn, function()
        local title = self._signHelpTitle
        local helpTips = self._signHelpTips
        local helpData = { title = title, text = helpTips }
        GF.OpenWnd("UIBzTips", helpData)
    end)
    --关闭按钮，若有self._enterSid则打开该字段窗口
    self:SetWndClick(self.mCloseBtn, function()
        if (self._enterSid) then
            local activityData = gModelActivity:GetActivityBySid(self._enterSid)
            local func = gModelActivity:GetShowActivityFun(activityData.model)
            if func then
                func(activityData)
            end
        end
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    --抽取幸运号码按钮
    self:SetWndClick(self.mGetBtn, function()
        ------------老虎机数字滚动测试代码-------
        --self._isClickGetBtn = true
        --self._playerNum = "15978"
        --self:SetSecMyNumImgList()
        --return
        ---------------------------------------
        self:SetBtnStateIsGray(self.mGetBtn, true)
        self._isClickGetBtn = true
        --self:SetSpineAni(UIAnniversaryDTDKoi.AniTypeOpen)
        if self._sid then
            gModelActivity:OnActivitySpecialOpReq(self._sid, 1, 1, nil, nil, ModelActivity.LUCKY_NUM_DRAW)
        end
    end)
    --我的奖励按钮 打开我的奖励弹框 UIAnniversaryDTDKoiRecordPop
    self:SetWndClick(self.mRewardBtn, function()
        GF.OpenWnd("UIAnniversaryDTDKoiRecordPop", { sid = self._sid, recordList = self._playerRecord })
    end)
    --self:SetWndClick(self.mShareBtn, function()
    --    self:OnClickShare()
    --end)
end
--协议监听初始化
function UIAnniversaryDTDKoi:InitMessage()
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        self:OnActivityPageResp(pb)    --分页数据返回
    end)
    self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp, function(pb)
        gModelActivity:ReqActivityConfigData(self._sid)
    end)
end
--开奖时间倒计时
function UIAnniversaryDTDKoi:ShowPrizeTimerFunc()
    local nowTime = GetTimestamp()
    local timeDif = os.difftime(self._prizeEndTime, nowTime)
    if timeDif <= 0 then
        self:StopShowPrizeTimer(true)
        return
    end
    --  FormatTimeToCn1
    local timeStr = LUtil.FormatTimespanCn(timeDif)
    local todayKoiStr = string.replace(ccClientText(29607), timeStr)--29607 今日开奖时间 ：[今日開獎時間：#a1#]
    self:SetWndText(self.mTimeCntTxt, todayKoiStr)
end

--抽奖完成之后的字体设置
function UIAnniversaryDTDKoi:SetMyNumHaveEffect(starIndex)
    local num = self._playerNum
    if (not num or num == "") then
        return
    end
    local numArr = LStringUtil.StringToCharArray(tostring(self._playerNum))

    local isStar = false
    if nil == starIndex then
        isStar = true
    end

    local starIndex = starIndex or 1
    local tranKey = string.format("MyNum_%s", starIndex)
    local tran = CS.FindTrans(self.mMyNumBg, tranKey)

    if tran and isStar then
        self:CreateWndEffect(tran, "fx_ui_sshd_huodeshuzi", "fx_ui_sshd_huodeshuzi" .. tranKey, 100)
        self:SetMyNumHaveEffect(starIndex + 1)
        self:SetWndText(tran, numArr[starIndex])
    elseif tran then
        --不是首次则在0.73S后调用下一次
        if self._timerNum then
            LxTimer.DelayTimeStop(self._timerNum )
        end
        self._timerNum=LxTimer.DelayTimeCall(function()
            self:CreateWndEffect(tran, "fx_ui_sshd_huodeshuzi", "fx_ui_sshd_huodeshuzi" .. tranKey, 100)
            self:SetMyNumHaveEffect(starIndex + 1)
            self:SetWndText(tran, numArr[starIndex])
        end, 0.73)
    end
end
--停止定时器
function UIAnniversaryDTDKoi:StopStartDrawTimer()
    self:TimerStop(self._startDrawTimeKey)
end
--刷新倒计时
function UIAnniversaryDTDKoi:RefreshTime()
    local timeValue = self._endActivityTime or 0
    self._endTime = timeValue
    local showTime = self._endTime > 0
    CS.ShowObject(self.mTimeBg, showTime)
    if not showTime then
        return
    end
    self:TimerStart(self._showTimeKey, 1, false, -1)
end
function UIAnniversaryDTDKoi:SetSpine()

    if true then
        CS.ShowObject(self.mBoxBg, false)
        return
    end

    local _spineName = self._spineName or "Shuishoujiuba"
    if (self._uiPrefab and self._uiPrefab == 2) then
        _spineName = "Guoqingyaoyaoji"
    end
    local dpSpine = self:FindWndSpineByKey(self._spineName)
    local spineRoot = (self._uiPrefab and self._uiPrefab == 2) and self.mSecBoxSpine or self.mBoxSpine
    if (not dpSpine) then
        self:CreateWndSpine(spineRoot, _spineName, _spineName, false, function(dpSpine)
            if (not self._uiPrefab or self._uiPrefab == 1) then
                --CS.ShowObject(self.mBoxBg, true)
                CS.ShowObject(self.mBoxBg, false)
            end
            dpSpine:SetIgnoreTimeScale(true)
            self:UpdateSpineState()
        end)
    end
    self._spineName = _spineName
    if (not self._isPlay) then
        if (self._playerNum) then
            local aniType = self._uiPrefab and self._uiPrefab == 2 and UIAnniversaryDTDKoi.AniTypeIdle3 or UIAnniversaryDTDKoi.AniTypeOpen2
            self:SetSpineAni(aniType)
        else
            self:SetSpineAni(UIAnniversaryDTDKoi.AniTypeIdle)
        end
    end
end
function UIAnniversaryDTDKoi:OnTryTcpReconnect()
    gModelActivity:ReqActivityConfigData(self._sid)
end
--获取零点时间
function UIAnniversaryDTDKoi:GetTodayTimeStamp(dayOffset)
    local oTime = GetTimestamp()
    if (dayOffset) then
        oTime = oTime + (dayOffset * 86400)
    end
    local yTxt, mTxt, dTxt = LUtil.GetYmdByTimestamp(oTime)
    local cDateTodayTime = LUtil.OSTime({ year = yTxt, month = mTxt, day = dTxt, hour = 0, min = 0, sec = 0 })
    return cDateTodayTime
end
function UIAnniversaryDTDKoi:OnActivityPageResp(pb, ret)
    local sid = pb.sid
    if sid ~= self._sid then
        return
    end
    local page = pb.pages[1]
    local pageId = page.pageId
    local pageData = gModelActivity:GenerateActivePageDataFromPb(page)
    local entry = {}
    for i, v in ipairs(pageData.entry) do
        local entryCfg = gModelActivity:GetWebActivityEntryData(sid, pageId, v.entryId)
        local data = {}
        data.webData = v
        data.title = entryCfg.name
        data.moreInfo = entryCfg.moreInfo
        data.rewards = LxDataHelper.ParseItem(entryCfg.reward)
        table.insert(entry, data)
    end
    self._page = pageData
    self._entry = entry
    local moreInfo = JSON.decode(self._page.moreInfo)

    local playNum = checknumber(moreInfo.playerNum)
    self._isGetNum = playNum > 0 and true or false
    self._playerNum = moreInfo.playerNum or self._playerNum
    self._firPrizer = moreInfo.firstPrizePlayer or self._firPrizer
    self._prizeNum = moreInfo.targetNum or self._prizeNum
    if moreInfo.playerRecord then
        self._playerRecord = JSON.decode(moreInfo.playerRecord)
    end
    for i, v in pairs(self._playerRecord) do
        local entryData = self._entry[v.id]
        v.rewards = entryData.rewards
        v.recordName = entryData.title
    end
    if (self._playerRecord and #self._playerRecord > 0) then
        table.sort(self._playerRecord, function(a, b)
            return a.createTime > b.createTime
        end)
    end
    self:RefreshUI()

    if self._isClickGetBtn then
        self:SetMyNumHaveEffect()
        self._isClickGetBtn = false
    end
end

--设置按钮颜色
function UIAnniversaryDTDKoi:SetBtnStateIsGray(btnTran, isGray)
    local path = isGray and "public_btn_ash_8_1" or "public_btn_1_4"

    self:SetWndEasyImage(btnTran, path)
end
--窗口背景以及艺术字标题
function UIAnniversaryDTDKoi:SetUI()
    self:DisplayDefultUI(self._uiPrefab)
    self:SetUIPositon(self.mHelpBtn, self._cfgData.helpTipsCoord)
    --self:SetUIPositon(self.mShareBtn, self._cfgData.shareCoord)
    self:SetUIPositon(self.mTimeBg, self._cfgData.timeCoord)
    self:SetUIPositon(self.mCenterGroup, self._cfgData.rewardCoord)
    self:SetUIPositon(self.mGetBtn, self._cfgData.buttonCoord)
    self:SetWndEasyImage(self.mTitleImage, self._cfgHeadLine)
    self:SetAnchorPos(self.mTitleImage, Vector2.New(0,-35))
    --self:SetBgImgAndPos(self.mTitleImage, self._cfgHeadLine, self._cfgHeadLinePos)
    self:SetBgImgAndPos(self.mHeroImage, self._signHeroImage, self._cfgSignImageHeroPos)
    self:SetWndText(self.mMyRewardTxt, ccClientText(29611))
    --self:SetWndText(self.mGetBtnTxt, ccClientText(29603))
    self:InitTextLineWithLanguage(self.mGetBtnTxt, -30)
    CS.ShowObject(self.mTopGroup, true)
end


--直接设置数字 不做动画
function UIAnniversaryDTDKoi:SetMyNum()
    local num = self._playerNum
    if (not num or num == "") then
        --清理
        for i=1,5  do
            local tranKey = string.format("MyNum_%s", i)
            local tran = CS.FindTrans(self.mMyNumBg, tranKey)

            self:SetWndText(tran, "")
        end

        return
    end
    local numArr = LStringUtil.StringToCharArray(tostring(self._playerNum))

    for k, v in ipairs(numArr) do
        local tranKey = string.format("MyNum_%s", k)
        local tran = CS.FindTrans(self.mMyNumBg, tranKey)

        self:SetWndText(tran, v)
    end

end



--UI2套处理 数字图片滚动
function UIAnniversaryDTDKoi:DoTweenNumImg(itemRoot, timeDur)
    local posList = self.posList
    local imgAllIndexList = self._imgAllIndexList
    if not imgAllIndexList then
        imgAllIndexList = {}
        self._imgAllIndexList = imgAllIndexList
    end
    local imgKey = itemRoot:GetInstanceID()
    local imgIndexList = imgAllIndexList[imgKey]
    if not imgIndexList then
        imgIndexList = {}
        imgAllIndexList[imgKey] = imgIndexList
    end
    for i = 1, 10 do
        local itemTrans = CS.GetChild(itemRoot, i - 1)
        imgIndexList[i] = not imgIndexList[i] and i - 1 or imgIndexList[i] - 1
        if (itemTrans.anchoredPosition.y <= posList[1] or imgIndexList[i] == -1) then
            imgIndexList[i] = #posList - 1
            local lastPos = Vector2.New(18, posList[imgIndexList[i]])
            self:SetAnchorPos(itemTrans, lastPos)
        end
        local endX = itemTrans.anchoredPosition.x
        local endY = itemTrans.anchoredPosition.y
        local endPos = Vector2.New(endX, posList[imgIndexList[i] + 1])
        local key = itemTrans:GetInstanceID()
        local seqCom = self:GetSeqCom()
        local seq = seqCom:CreateSeq(key)
        local tween = YXTween.TweenFloat(endY, endPos.y, timeDur, function(t)
            local pos = Vector2.New(18, t)
            self:SetAnchorPos(itemTrans, pos)
        end)
        seq:Append(tween)
        seq:AppendCallback(function()
            self:SetAnchorPos(itemTrans, Vector2.New(18, endPos.y))
            self:TweenSeqKill(key)
        end)
        seq:Play()
    end
end
--UI2套处理
function UIAnniversaryDTDKoi:DisplayDefultUI(uiType)
    CS.ShowObject(self.mBgImg, not uiType or uiType == 1)
    CS.ShowObject(self.mBoxSpine, not uiType or uiType == 1)
    CS.ShowObject(self.mMyNumTxt, not uiType or uiType == 1)
    CS.ShowObject(self.mRankScroll, not uiType or uiType == 1)

    CS.ShowObject(self.mSecBgImg, uiType and uiType == 2)
    CS.ShowObject(self.mSecBoxSpine, uiType and uiType == 2)
    CS.ShowObject(self.mSecMyNumTxt, uiType and uiType == 2)
    CS.ShowObject(self.mSecRankScroll, uiType and uiType == 2)

    local bgImg = (uiType and uiType == 2) and self.mSecBgImg or self.mBgImg
    local rankBgPath = (uiType and uiType == 2) and "activity_nationalday2_bg_di_2" or "activity_anniversary_bg_di_11"
    self:SetBgImgAndPos(self.mRankBg, rankBgPath)
    self:SetBgImgAndPos(bgImg, self._cfgSignImage, self._cfgSignImagePos)

    self.ranScroll = (uiType and uiType == 2) and self.mSecRankScroll or self.mRankScroll
    if (not uiType or uiType == 1) then
        self:SetWndText(self.mMyNumTxt, ccClientText(29606))
    end

    self:SetWndText(self.mSecMyNumTxt, ccClientText(29606))
end
--1:idel 2:open
function UIAnniversaryDTDKoi:SetSpineAni(aniType)
    self._spinType = aniType
    self:UpdateSpineState()
end

--获取数字滚动总时长 国庆版老虎机专属
function UIAnniversaryDTDKoi:GetAniTypeIdle2PlayTotalTime()
    if (not self.aniTypeIdle2PlayTotalTime and self._playerNum) then
        local numArr = LStringUtil.StringToCharArray(tostring(self._playerNum))
        local loopCnt = 50 + tonumber(numArr[#numArr])
        local totalTime = loopCnt * 0.14
        self.aniTypeIdle2PlayTotalTime = totalTime
    end
    return self.aniTypeIdle2PlayTotalTime
end
--设置背景图
function UIAnniversaryDTDKoi:SetBgImgAndPos(imgTrans, imgPath, offset)
    if (imgPath) then
        self:SetWndEasyImage(imgTrans, imgPath)
        self:SetUIPositon(imgTrans, offset)
    end
    CS.ShowObject(imgTrans, imgPath ~= nil)
end
--中奖排名说明列表子项
function UIAnniversaryDTDKoi:OnDrawItemCell(list, item, itemdata, itempos)
    local rankImg = self:FindWndTrans(item, "RankImg")
    local itemTitleTxt = self:FindWndTrans(item, "ItemTitleTxt")
    local itemDes = self:FindWndTrans(item, "ItemDes")
    local uiList = self:FindWndTrans(item, "RewardList")
    local cfgEntry = self._cfgEntry[itemdata.webData.entryId]
    self:SetWndText(itemTitleTxt, cfgEntry.name)
    self:SetWndText(itemDes, cfgEntry.description)
    --self:InitTextModeWithLanguage(itemDes)
    self:SetWndEasyImage(rankImg, cfgEntry.moreInfo)
    --UI2套处理
    local list = itemdata.rewards
    local rewardList = self:GetUIScroll(item:GetInstanceID())
    if (rewardList:GetList()) then
        rewardList:RefreshList(list)
    else
        rewardList:Create(uiList, list, function(...)
            self:RewardListItem(...)
        end, UIItemList.NORMAL)
    end
    rewardList:EnableScroll(#list > 3, true)
    local itemRoot = self:FindWndTrans(uiList, "ItemRoot")
    local itemRootRectTrans = itemRoot.gameObject:GetComponent(typeOfRectTransform)
    if (#list > 3) then
        local leftAnchorsData = Vector2.New(0, 0.5)
        itemRootRectTrans.anchorMin = leftAnchorsData
        itemRootRectTrans.anchorMax = leftAnchorsData
        itemRootRectTrans.pivot = leftAnchorsData
    else
        local middleAnchorsData = Vector2.New(0.5, 0.5)
        itemRootRectTrans.anchorMin = middleAnchorsData
        itemRootRectTrans.anchorMax = middleAnchorsData
        itemRootRectTrans.pivot = middleAnchorsData
    end
    self:SetAnchorPos(itemRoot, Vector2.New(0, 0))
end
function UIAnniversaryDTDKoi:SetMyRewardBtnRP()
    local showRP = false
    local rpTrans = self:FindWndTrans(self.mRewardBtn, "RedPoint")
    if (self._playerRecord) then
        for i, v in pairs(self._playerRecord) do
            local isReceive = v.isReceive
            if (isReceive == 0) then
                showRP = true
            end
        end
    end
    CS.ShowObject(rpTrans, showRP)
end

--后台活动配置回调
function UIAnniversaryDTDKoi:OnActivityConfigData(data, sid)
    if sid ~= self._sid then
        return
    end
    self._cfgData = data.config
    self._cfgActivityName = self._cfgData.name
    self._cfgSignHelpTips = self._cfgData.signHelpTips
    self._cfgSignImage = self._cfgData.signImage
    self._cfgLotteryTime = self._cfgData.lotteryTime
    self._cfgHeadLine = self._cfgData.headline
    self._cfgHeroImage = self._cfgData.signImageHero

    self._cfgSignImageHeroPos = self._cfgData.signImageHeroPos--英雄背景偏移量
    self._cfgSignImagePos = self._cfgData.signImagePos--背景图偏移量
    self._cfgHeadLinePos = self._cfgData.headlinePos--艺术字偏移量
    self._cfgDrawTime = self._cfgData.drawTime
    self._uiPrefab = self._cfgData.uiPrefab --ui展示方案 1：水手酒馆 2：国庆
    self._shareId = self._cfgData.shareId
    self:SetData()
    self:SetUI()
    gModelActivity:OnActivityPageReq(self._sid)
end
--初始化数据
function UIAnniversaryDTDKoi:InitData()
    self._timerList = {}
    self._sid = self:GetWndArg("sid")
    self._enterSid = self:GetWndArg("enterSid")
    local subpage = self:GetWndArg("subPage") --支持跳转
    if subpage then
        self._sid = gModelActivity:GetSidByUniqueJump(subpage)
    end
    self._showTimeKey = "_endTimeKey"
    self._prizeTimeKey = "_prizeTimeKey"
    self._startDrawTimeKey = "startDraw"
    CS.ShowObject(self.mTopGroup, true)
    CS.ShowObject(self.mMask, true)
    gModelActivity:ReqActivityConfigData(self._sid)
end
--停止倒计时定时器
function UIAnniversaryDTDKoi:StopShowPrizeTimer(isPageReq)
    self:TimerStop(self._prizeTimeKey)
    if (isPageReq) then
        gModelActivity:OnActivityPageReq(self._sid)
    end
end
------------------------------------------------------------------
return UIAnniversaryDTDKoi