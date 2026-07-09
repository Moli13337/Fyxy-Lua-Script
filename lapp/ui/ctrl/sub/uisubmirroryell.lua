---
--- Created by LCM.
--- DateTime: 2024/3/5 15:17:17
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubMirrorYell:LChildWnd
local UISubMirrorYell = LxWndClass("UISubMirrorYell", LChildWnd)

local UScreen = UnityEngine.Screen
local Tweening = DG.Tweening
--- 1：使用箱子特效
UISubMirrorYell.USE_BOX_TYPE = 2

UISubMirrorYell.SHOW_TYPE_NORMAL = 1            --- 常驻召唤
UISubMirrorYell.SHOW_TYPE_ACTIVITY = 2        --- 活动召唤

local adMethodId = ModelAds.TYPE_ADS_501
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubMirrorYell:UISubMirrorYell()
    self._oneTimerKey = "oneTimerKey"
    self._tenTimerKey = "tenTimerKey"
    self._cutHeroTimerKey = "cutHeroTimerKey"
    self._curHeroIconTimerKey = "curHeroIconTimerKey"

    self._showAniKey = "showAniKey"

    --self._spineBoxKey = "Shiguangbaozanxiangzi_hong"
    self._spineBoxKey = "spineBoxKey"

    self._timerPrivileKey = "_timerPrivileKey"
    self._jumpAniStatus = gModelCallHero:GetMirrorCallJumpAniStats()
    self._autoSacrifice = gModelHero:GetAutoSacrificeStatus()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubMirrorYell:OnWndClose()
    self:ClearAllActTimer()
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubMirrorYell:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubMirrorYell:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    
    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isJapaness  =gLGameLanguage:IsJapanVersion()
    if self._isEnus or self._isJapaness then
        self.mJinDuTxtBg.sizeDelta= Vector2.New(120,45)
        self:SetAnchorPos(self.mJinDuTxtBg,Vector2.New(0,-60))
        self:SetAnchorPos(self.mJinDuDesTxt,Vector2.New(0,0))
        self:SetAnchorPos(self.mJinDuTxt,Vector2.New(-1.5,-40))
    end

    if self._isJapaness then
        self:SetAnchorPos(self.mSacrificeSelBtn,Vector2.New(230,160))
    end
    
    if gModelCallHero:CheckIsExamineSex() then
        --todo : 暂时全部屏蔽
        CS.ShowObject(self.mSpineBgRoot, false)
        CS.ShowObject(self.mJumpAniBtn, false)
    end
    
    CS.ShowObject(self.mJumpAniBtn,not gModelCallHero:CheckIsExamineSex())
    self:InitEff()
    self:InitText()
    self:InitEvent()
    self:InitHeroShowTransInfo()
    self:InitCallTypeBtnInfo()
    self:InitActivityCallTypeBtnInfo()
    self:InitCallBtnTransInfo()
    self:InitMsg()
    self:InitData()
    self:RefreshJumpAniStatus()
    self:RefreshSacrificeSelStatus()
    self:RefreshCallTypeBtnStatus()
    gModelCallHero:CallOpt(self._page)
    self:TimerStart(self._timerPrivileKey, 0.5, false, 1)
    self:SetSecretJumpBtn(self.mBtnSecret, 1)

    if ModelCallHero.TYPE_SHOW_STATE == 0 then
        self:RefreshCallShow()
    else
        CS.ShowObject(self.mGameCallView, false)
        local spineBgName = ModelCallHero.CALL_SPINE_BGNAME
        ---@param dpSpine LDisplaySpine
        self:CreateWndSpine(self.mSpineRoot, spineBgName, spineBgName, false, function(dpSpine)
            dpSpine:PlayAnimationSolid("idle", true)
        end)

        local spineName = ModelCallHero.CALL_SPINE_NAME
        self:CreateWndSpine(self.mSpineBgRoot, spineName, spineName, false, function(dpSpine)
            dpSpine:PlayAnimationSolid("idle", true)
        end)
        if PRODUCT_G_VER ~= 0 then
            CS.ShowObject(self.mSpineBgRoot, false)
        end
    end
    
    if gLGameLanguage:IsJapanRegion() then 
        if PRODUCT_G_VER~=0 then 
            CS.ShowObject(self.mBoxBtn,false)
            CS.ShowObject(self.mDetailsBtn,false)
        end 
    end 
end

function UISubMirrorYell:InitData()
    self._page = self:GetWndArg("page")
    local callRefId
    local subPage = self:GetWndArg("subPage")
    if subPage then
        local list = {
            ModelCallHero.CALL_TYPE_SPECIAL, ModelCallHero.CALL_TYPE_BASE, ModelCallHero.CALL_TYPE_FRIEND
        }
        callRefId = list[subPage] or ModelCallHero.CALL_TYPE_SPECIAL
    else
        callRefId = self:GetWndArg("callRefId") or ModelCallHero.CALL_TYPE_SPECIAL
    end

    local activityCallRefId = self:GetWndArg("activityCallRefId")
    if activityCallRefId then
        if self:CheckIsHaveActivity() then
            callRefId = activityCallRefId
        end
    end

    self._callRefIdEffList = {
        [ModelCallHero.CALL_TYPE_BASE] = "fx_ui_putongzhaohuan_01",
        [ModelCallHero.CALL_TYPE_SPECIAL] = "fx_ui_putongzhaohuan_02",
        [ModelCallHero.CALL_TYPE_FRIEND] = "fx_ui_putongzhaohuan_03",
    }

    self._lihuiInitPos = self.mLiHuiPos.localPosition

    self._callRefId = callRefId
    self._showType = nil

    self._sendMsg = false            -- 是否发送事件

    self:GetActivityLimitCallDataList()

    --屏蔽欧皇榜
    if not gModelFunctionOpen:CheckIsShow(15500100) then
        CS.ShowObject(self.mRankBtn, false)
    end
end

----------------------------- list -----------------------------

function UISubMirrorYell:GetNeedAddItemList()
    local list = {}
    local ref = self:GetCallTypeRef()
    if ref then
        list = LUtil.ConvertCommonItemStrToList(ref.showItem, "|")
    end
    return list
end

function UISubMirrorYell:InitHeroShowTransInfo()
    local heroShowTransList = {
        self.mHeroShow1, self.mHeroShow2, self.mHeroShow3, self.mHeroShow4, self.mHeroShow5,
    }
    local heroShowTransInfoList = {}
    for i, v in ipairs(heroShowTransList) do
        local NoHeroTrans = self:FindWndTrans(v, "NoHero")
        local HeroIconTrans = self:FindWndTrans(v, "HeroIcon")
        local EffRootTrans = self:FindWndTrans(v, "EffRoot")
        self:CreateHeroShowEff(EffRootTrans)
        table.insert(heroShowTransInfoList, {
            NoHeroTrans = NoHeroTrans,
            HeroIconTrans = HeroIconTrans,
            EffRootTrans = EffRootTrans,
            rootTrans = v,
        })
        self:RunHeroShowAni(v)
    end
    self._heroShowTransInfoList = heroShowTransInfoList
end

function UISubMirrorYell:RefreshBoxShow()
    local integralNeedRefId = self._integralNeedRefId
    local integralNeedNum = self._integralNeedNum
    if not integralNeedRefId or not integralNeedNum then
        self:InitIntegralInfo()
        integralNeedRefId = self._integralNeedRefId
        integralNeedNum = self._integralNeedNum
    end
    local haveNum = gModelItem:GetNumByRefId(integralNeedRefId)
    local percentage = haveNum / integralNeedNum
    LxUiHelper.SetProgress(self.mJinDuTiao, percentage)

    local color = haveNum >= integralNeedNum and "lightGreen_new" or "red"
    local haveStr=    LUtil.FormatColorStr(haveNum, color)

    local str = string.format("%s/%s", haveStr, integralNeedNum)
    self:SetWndText(self.mJinDuTxt, str)
    self:SetWndText(self.mJinDuDesTxt, ccClientText(27865))
    local isMax = haveNum >= integralNeedNum
    local showBoxImg = false
    local showBoxEff = false
    if UISubMirrorYell.USE_BOX_TYPE == 1 then
        showBoxEff = isMax
        showBoxImg = not showBoxEff
    else
        showBoxEff = true
        local dpSpine = self:FindWndSpineByKey(self._spineBoxKey)
        if dpSpine and dpSpine:IsDpValid() then
            local aniName = isMax and "idle_2" or "idle_1"
            dpSpine:PlayAnimationSolid(aniName, true)
        end
    end

    CS.ShowObject(self.mBoxEffect, false)
    CS.ShowObject(self.mBoxImg, true)
    --CS.ShowObject(self.mBoxEffect,showBoxEff)
    --CS.ShowObject(self.mBoxImg,showBoxImg)
end

function UISubMirrorYell:OnRefreshNormalCallType(tCallRefId)
    self._callRefId = tCallRefId
    self:RefreshCallTypeBtnList(true)
end

function UISubMirrorYell:OnClickActivityFunc(curActivityData, times, callType)
    if not curActivityData then
        return
    end
    local func = function()
        if gModelGeneral:IsFullHeroBag(times, nil, nil, nil, nil, self:GetWndName()) then
            return
        end
        gModelActivity:GetCallDataBySid(curActivityData.sid, nil, callType, self:GetWndName(), times, function()
            self._sendMsg = true
        end)
    end
    if self:CheckIsWishEmpty(curActivityData) then
        gModelGeneral:OpenUIOrdinTips({ refId = 110053, func = function()
            func()
        end }, true)
    else
        func()
    end
end

function UISubMirrorYell:OnClickActivityLogBtnFunc()
    local curActivityData = self:GetCurSelLimitCallData()
    if not curActivityData then
        return
    end
    GF.OpenWnd("UIYellLog", { sid = curActivityData.sid, callType = 3, maxNum = curActivityData.logNumMax })
end

function UISubMirrorYell:OnClickSacrificeSelBtnEvent()
    self._autoSacrifice = not self._autoSacrifice
    gModelHero:SetAutoSacrificeStatus(self._autoSacrifice)
    self:RefreshSacrificeSelStatus()
end

function UISubMirrorYell:OnClickWishListBtnFunc()
    -- local curActivityData = self:GetCurSelLimitCallData()
    -- if not curActivityData then return end
    -- GF.OpenWnd("UIActCallHeroWishList",{
    -- 	sid = curActivityData.sid,
    -- 	choseTips = curActivityData.choseTips,
    -- })
end

function UISubMirrorYell:RefreshSacrificeSelStatus()
    CS.ShowObject(self.mSacrificeSelGou, self._autoSacrifice)
end

function UISubMirrorYell:GetRandomSuspendTime()
    local times = { 3.5, 4, 3, 3.8, 5, 4.5, 3.2, 4.2, 3.4, 4.8 }
    local random = math.random(1, #times)
    return times[random]
end

function UISubMirrorYell:CheckIsWishEmpty(curActivityData)
    if not curActivityData then
        return false
    end

    local allNum = 0
    local wishes = curActivityData.wishes
    for tGroupId, selVal in pairs(wishes) do
        for idx, val in ipairs(selVal) do
            allNum = allNum + 1
        end
    end
    return allNum == 0
end

function UISubMirrorYell:CreateHeroShowEff(trans)
    local key = trans:GetInstanceID()
    self:CreateWndEffect(trans, "ui_fx_guangquanqiehuan", key, 130, false, false, 10)
end

function UISubMirrorYell:RefreshHeroCVName(heroRefId)
    local cvName = gModelHero:GetHeroCVName(heroRefId)

    cvName = ""

    local isShow = not string.isempty(cvName)
    CS.ShowObject(self.mCVNameBg, isShow)
    if not isShow then
        return
    end

    local cvNameStr = string.replace(ccClientText(19786), cvName)
    self:SetWndText(self.mCVNameTxt, cvNameStr)
end

function UISubMirrorYell:OnClickActivityDetailsBtnFunc()
    local curActivityData = self:GetCurSelLimitCallData()
    if not curActivityData then
        return
    end
    GF.OpenWnd("UIYellHRew", {
        viewType = 5,
        sid = curActivityData.sid,
        jackpotId = ModelActivity.LIMIT_CALL_JACKPOT,
        policyTxt = curActivityData.policyTxt,
        specialTxt = curActivityData.specialTxt,
    })
end

function UISubMirrorYell:RefreshCallShow()
    self:TimerStop(self._cutHeroTimerKey)
    self:CreateEff()
    self:CreateShowHeroLiHui()
end

function UISubMirrorYell:CreateEff()
    local list = self._callRefIdEffList
    if not list then
        return
    end
    local callRefId = self._callRefId
    local effName = list[callRefId]
    if not effName then
        return
    end
    if self._showEffName and self._showEffName ~= effName then
        local effect = self:FindWndEffectByKey(self._showEffName)
        if effect then
            effect:SetVisible(false)
        end
    end
    self._showEffName = effName
    local newEffect = self:FindWndEffectByKey(self._showEffName)
    if newEffect then
        newEffect:SetVisible(true)
    else
        self:CreateWndEffect(self.mEffRoot, effName, effName, 100, false, false)
    end
end

function UISubMirrorYell:RefreshBox()
    local integralNeedRefId = self._integralNeedRefId
    local integralNeedNum = self._integralNeedNum
    if not integralNeedRefId or not integralNeedNum then
        self:InitIntegralInfo()
        integralNeedRefId = self._integralNeedRefId
        integralNeedNum = self._integralNeedNum
    end
    local haveNum = gModelItem:GetNumByRefId(integralNeedRefId)
    local showBoxEff = haveNum >= integralNeedNum
    local needVip = GameTable.SummonConfigRef["integralNeedVip"]
    local curVip = gModelPlayer:GetVipLevel()
    local show = curVip >= needVip
    CS.ShowObject(self.mBoxRedPoint, showBoxEff and show)
    self:RefreshBoxShow()
end

function UISubMirrorYell:InitCallBtnTransInfo()
    local callBtnTransInfo = {}
    local oneCallBtnTrans = self.mOneCallBtn
    local oneCallTransInfo = self:GetCallBtnTransInfo(oneCallBtnTrans)
    callBtnTransInfo.oneCallTransInfo = oneCallTransInfo
    self:CreateBtnEff(oneCallTransInfo.effRootTrans, "fx_ui_putongzhaohuan_04")

    local tenCallBtnTrans = self.mTenCallBtn
    local tenCallTransInfo = self:GetCallBtnTransInfo(tenCallBtnTrans)
    callBtnTransInfo.tenCallTransInfo = tenCallTransInfo
    self:CreateBtnEff(tenCallTransInfo.effRootTrans, "fx_ui_putongzhaohuan_05")

    self._oneCallTimeTxtTrans = oneCallTransInfo.timeTxtTrans
    self._tenCallTimeTxtTrans = tenCallTransInfo.timeTxtTrans

    self._callBtnTransInfo = callBtnTransInfo
end

function UISubMirrorYell:OnClickActivityBoxBtnFunc()
    local curActivityData = self:GetCurSelLimitCallData()
    if not curActivityData then
        return
    end
    local score = curActivityData.score
    local extraCallGoal = curActivityData.extraCallGoal
    if score < extraCallGoal then
        GF.ShowMessage(ccClientText(32111))
        return
    end
    local num = math.floor(score / extraCallGoal)
    if num < 1 then
        return
    end
    if num > 10 then
        num = 10
    end
    if gModelGeneral:IsFullHeroBag(num, nil, nil, nil, nil, self:GetWndName()) then
        return
    end
    local wishInfo = {
        sid = curActivityData.sid,
        args = tostring(num)
    }
    local func = function()
        gModelActivity:GetActHeroCallIntegral(wishInfo)
    end
    if self:CheckIsWishEmpty(curActivityData) then
        gModelGeneral:OpenUIOrdinTips({ refId = 110053, func = function()
            func()
        end }, true)
    else
        func()
    end
end

function UISubMirrorYell:GetCurSelLimitCallData()
    if not self._curSelLimitCallSid then
        return
    end
    if not self._activityDataSidList then
        return
    end
    return self._activityDataSidList[self._curSelLimitCallSid]
end

function UISubMirrorYell:OpentPrivileKey()
    -- local priviCom = self:GetPrivilegeCom()
    -- priviCom:Create(self.mBtnPrivile, 9, self)
end

function UISubMirrorYell:OnTimerCurHeroIconFunc()
    local curActivityData = self:GetCurSelLimitCallData()
    if not curActivityData then
        self:TimerStop(self._curHeroIconTimerKey)
        return
    end
    local activityRaceType = self._activityRaceType
    local curIndex
    local exRatesNum = curActivityData.exRatesNum
    if exRatesNum > 0 then
        local exRatesSortKeyList = curActivityData.exRatesSortKeyList or {}
        curIndex = exRatesSortKeyList[activityRaceType]
    else
        local wishSettingIndexOpenList = curActivityData.wishSettingIndexOpenList
        curIndex = wishSettingIndexOpenList[activityRaceType]
    end
    if not curIndex then
        self:TimerStop(self._curHeroIconTimerKey)
        return
    end
    local exRatesSortList
    if exRatesNum > 0 then
        exRatesSortList = curActivityData.exRatesSortList or {}
    else
        exRatesSortList = curActivityData.wishSettingSortOpenList
    end
    local newIndex = curIndex + 1
    local len = #exRatesSortList
    if newIndex > len then
        newIndex = 1
    end
    local newRaceInfo = exRatesSortList[newIndex]
    if not newRaceInfo then
        return
    end
    local newRace
    if exRatesNum > 0 then
        newRace = newRaceInfo.raceType
    else
        newRace = newRaceInfo.raceType
    end
    if not newRace then
        self:TimerStop(self._curHeroIconTimerKey)
        return
    end
    self._activityRaceType = newRace
    self:RefreshActivityZHHeroIcon(true)
    self:RefreshActivityZHHeroRaceList()
    self:CreateCurHeroIconTimer(curActivityData.rollingTime)
end

function UISubMirrorYell:GetCallBtnTransInfo(btnTrans)
    local EffRootTrans = self:FindWndTrans(btnTrans, "EffRoot")
    local btnNameTrans = self:FindWndTrans(btnTrans, "BtnName")
    local timeTxtTrans = self:FindWndTrans(btnTrans, "TimeTxt")
    local payDivTrans = self:FindWndTrans(btnTrans, "PayDiv")
    local iconImgTrans = self:FindWndTrans(payDivTrans, "IconImg")
    local numTxtTrans = self:FindWndTrans(payDivTrans, "NumTxt")
    local freeTxtTrans = self:FindWndTrans(btnTrans, "FreeTxt")
    local redPointTrans = self:FindWndTrans(btnTrans, "redPoint")
    return {
        effRootTrans = EffRootTrans,
        btnNameTrans = btnNameTrans,
        timeTxtTrans = timeTxtTrans,
        payDivTrans = payDivTrans,
        iconImgTrans = iconImgTrans,
        numTxtTrans = numTxtTrans,
        freeTxtTrans = freeTxtTrans,
        redPointTrans = redPointTrans,
    }
end

function UISubMirrorYell:OnClickJumpAniFunc()
    self._jumpAniStatus = not self._jumpAniStatus
    gModelCallHero:SetMirrorCallJumpAniStats(self._jumpAniStatus)
    self:RefreshJumpAniStatus()
end

function UISubMirrorYell:OnClickRecommendBtnFunc()
    gModelFunctionOpen:Jump(gModelCallHero:GetCallConfigRefByKey("growJump"), self:GetWndName())
end

function UISubMirrorYell:InitEff()
    self:CreateBoxEff()
    self:CreateWndEffect(self.mActivityEffRoot, "ui_fx_yuntuan", "ui_fx_yuntuan", 100, false, false)
    self:CreateWndEffect(self.mActivityEffRoot, "ui_fx_xingxingbeijing", "ui_fx_xingxingbeijing", 100, false, false)
    self:CreateWndEffect(self.mActivityBoxEffect, "fx_ui_putongzhaohuan_05", "fx_ui_putongzhaohuan_05", 100, false, false)
end

function UISubMirrorYell:OnClickActivityZHHeroRaceFunc(itemdata)
    local raceType = itemdata.raceType
    if self._activityRaceType == raceType then
        return
    end
    self._activityRaceType = raceType
    self:CreateCurHeroIconTimer(itemdata.rollingTime)
    self:RefreshActivityZHHeroIcon()
    self:RefreshActivityZHHeroRaceList()
end

function UISubMirrorYell:InitMsg()
    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:RefreshServerData()
    end)
    self:WndEventRecv(EventNames.ON_REFRESH_ANIJUMPSTATUS, function()
        self._jumpAniStatus = gModelCallHero:GetMirrorCallJumpAniStats()
        self:RefreshJumpAniStatus()
    end)
    self:WndNetMsgRecv(LProtoIds.MagicResp, function()
        self:RefreshServerData()
    end)
    self:WndNetMsgRecv(LProtoIds.CallHeroResp, function()
        self._sendMsg = false
        if self._callRefId ~= ModelCallHero.CALL_TYPE_SPECIAL then
            gModelCallHero:CallOpt(self._page)
        end
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        self:OnActivityListResp(pb)
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
        self:OnActivityConfigData(...)
    end)
    self:WndEventRecv(EventNames.NET_ERROR_CODE, function(code, error, argList)
        self._sendMsg = false
    end)

    self:WndEventRecv(EventNames.REFRESH_ADS,function() self:OnRefreshAds() end)
end

function UISubMirrorYell:RefreshJumpAniStatus()
    local status = self._jumpAniStatus
    CS.ShowObject(self.mJumpAniBgGou, status)
end

function UISubMirrorYell:SetDayTimer(timeTxtTrans, serverTime, addHour)
    local curTime = GetTimestamp()
    local curYear = tonumber(LUtil.OSDate("%Y", curTime))
    local curMon = tonumber(LUtil.OSDate("%m", curTime))
    local curDay = tonumber(LUtil.OSDate("%d", curTime))
    local curHour = tonumber(LUtil.OSDate("%H", curTime))
    local addDay = 0
    if curHour >= addHour then
        addDay = 1
    end
    local newDay = curDay + addDay
    local serDay = tonumber(LUtil.OSDate("%d", serverTime))
    local timeStr = ""
    if newDay - serDay > 1 then
        self:TimerStop(self._oneTimerKey)
    else
        local nextDayTime = LUtil.OSTime({ hour = addHour, day = newDay, month = curMon, year = curYear })
        local remainTime = nextDayTime - curTime
        if remainTime <= 0 then
            self:TimerStop(self._oneTimerKey)
        else
            timeStr = string.replace(ccClientText(11623), LUtil.FormatTimespanNumber(remainTime))
        end
    end
    self:SetWndText(timeTxtTrans, timeStr)
end

function UISubMirrorYell:RefreshActCallTypeView(curActivityData)
    if not curActivityData then
        return
    end
    local callBtnTransInfo = self._callBtnTransInfo
    if not callBtnTransInfo then
        return
    end

    self:SetWndEasyImage(self.mBg, curActivityData.image)
    self:InitNeedAddItemList(curActivityData.callCurrencyBar)

    local callBtnTxt = curActivityData.callBtnTxt
    local freeNum = curActivityData.freeNum
    local isHaveFree = freeNum > 0
    local btnName = ""
    local freeText = ""
    local isNewYear, activitys, textList = gModelActivity:GetPrivilegeShow1()
    if isHaveFree then
        btnName = callBtnTxt.freeBtnTxt or ccClientText(11610)
        if isNewYear then
            local freeStr = textList[1] or ""
            freeText = string.replace(freeStr, freeNum)
        elseif gModelBackflow:GetPrivilegesTypeListByType(9) then
            freeText = string.replace(ccClientText(12141), freeNum)
        end
        freeText = string.replace(ccClientText(12141), freeNum)
    else
        btnName = callBtnTxt.oneBtnTxt or ccClientText(11600)
        self:CreateTimer(self._oneTimerKey)
    end
    local isExRatesEmpty = curActivityData.isExRatesEmpty
    if not self._activityRaceType then
        if isExRatesEmpty then
            local wishSettingSortOpenList = curActivityData.wishSettingSortOpenList
            if #wishSettingSortOpenList > 0 then
                self._activityRaceType = wishSettingSortOpenList[1].raceType
            end
        else
            local exRatesSortList = curActivityData.exRatesSortList or {}
            if exRatesSortList[1] then
                self._activityRaceType = exRatesSortList[1].raceType
            end
        end
    end

    self:SetWndText(self.mRandCallTxt, curActivityData.callTips)

    local dropNumToday = curActivityData.dropNumToday
    local callMaxNum = curActivityData.callMaxNum
    local callMaxStr = string.replace(curActivityData.callLimitTips, dropNumToday, callMaxNum)
    self:SetTextTile(self.mTextTitle7, callMaxStr)

    local lastNum = curActivityData.goldTimes - curActivityData.callNum
    local callDiamondTips = string.replace(curActivityData.callDiamondTips, lastNum)
    self:SetWndText(self.mActivityRemainNum, callDiamondTips)

    local rollingTime = curActivityData.rollingTime
    local exRates
    if isExRatesEmpty then
        exRates = {}
        for k, v in pairs(curActivityData.wishSettingOpenList) do
            table.insert(exRates, {
                raceType = k,
                exRates = 0,
            })
        end
    else
        exRates = curActivityData.exRatesSortList
    end
    self:InitActivityZHHeroRaceList(exRates, rollingTime)

    local oneCallTransInfo = callBtnTransInfo.oneCallTransInfo
    local onePayInfo = self:GetUsePayInfo(curActivityData.onePayList)
    local oneCallInfo = {
        btnName = btnName,
        freeText = freeText,
        isHaveFree = isHaveFree,
        itemId = onePayInfo and onePayInfo.itemId,
        itemNum = onePayInfo and onePayInfo.itemNum,
        payType = 1,
    }
    self:SetCallBtn(oneCallTransInfo, oneCallInfo)

    local tenPayInfo = self:GetUsePayInfo(curActivityData.tenPayList)
    local tenCallTransInfo = callBtnTransInfo.tenCallTransInfo
    local tenCallInfo = {
        btnName = callBtnTxt.tenBtnTxt or ccClientText(11608),
        freeText = "",
        isHaveFree = false,
        itemId = tenPayInfo and tenPayInfo.itemId,
        itemNum = tenPayInfo and tenPayInfo.itemNum,
        payType = 10,
    }
    self:SetCallBtn(tenCallTransInfo, tenCallInfo)

    self:RefreshActBox(curActivityData)

    local showTips = false
    --[[	local wishes = curActivityData.wishes
        local serverexRates = curActivityData.exRates
        for groupId,selList in pairs(wishes) do
            if showTips then break end
            if #selList > 0 then
                local exRatesNum = serverexRates[tostring(groupId)]
                if exRatesNum and exRatesNum <= 0 then
                    showTips = true
                end
            end
        end]]
    local dropRecordsNum
    local tPlayerLimitNum
    local id_numKeyList = curActivityData.id_numKeyList
    local dropRecordsKeyList = curActivityData.dropRecordsKeyList
    local wishes = curActivityData.wishes
    for k, v in pairs(wishes) do
        if showTips then
            break
        end
        for idx, entryId in pairs(v) do
            if showTips then
                break
            end
            dropRecordsNum = dropRecordsKeyList[tostring(entryId)]
            if dropRecordsNum then
                tPlayerLimitNum = id_numKeyList[entryId]
                if tPlayerLimitNum and tPlayerLimitNum ~= -1 then
                    showTips = tPlayerLimitNum - dropRecordsNum < 1
                end
            end
        end
    end
    if showTips then
        self:SetWndText(self.mActivityCallHeroTips, curActivityData.getLimitTips)
    end
    CS.ShowObject(self.mActivityCallHeroTipsDiv, showTips)

    if not self:IsTimerExist(self._curHeroIconTimerKey) then
        self:CreateCurHeroIconTimer(rollingTime)
        self:RefreshActivityZHHeroIcon()
    end
end

function UISubMirrorYell:CheckRedPoint(callRefId)
    local showRedPoint = false
    if callRefId == ModelCallHero.CALL_TYPE_FRIEND then
        showRedPoint = gModelCallHero:GetFriendCallStatus()
        -- elseif callRefId == ModelActivity.LIMIT_CALL then
        -- 	local curActivityData = self:GetCurSelLimitCallData()
        -- 	local freeNum = curActivityData and curActivityData.freeNum or 0
        -- 	showRedPoint = freeNum > 0 or false
    else
        local serverData = self:GetCallHeroServerData(callRefId)
        local freeNum = serverData and serverData.freeNum or 0
        showRedPoint = freeNum > 0 or false
        if not showRedPoint and callRefId == ModelCallHero.CALL_TYPE_SPECIAL then
            showRedPoint = gModelCallHero:CheckIsSpecialCallInDayAndHaveEnoughItem()
        end
    end
    if not showRedPoint then
        local config = gModelAds:GetAdConfigByParam({
            adMethodId = adMethodId,
            refId = callRefId,
        })
        if config then
            showRedPoint = gModelAds:CheckNeedShowAdBtn({
                adMethodId = adMethodId,
                refId = callRefId,
            })
        end
    end
    return showRedPoint
end

function UISubMirrorYell:RefreshCallTypeView()
    self:TimerStop(self._oneTimerKey)

    local ref = self:GetCallTypeRef()
    if not ref then
        return
    end

    local showStar = string.split(ref.showStar, ",")
    local isSingle = #showStar == 1
    if not isSingle then
        if showStar[1] == showStar[2] then
            isSingle = true
        end
    end
    local showStarStr = ""
    if isSingle then
        showStarStr = string.replace(ccClientText(11683), showStar[1])
    else
        showStarStr = string.replace(ccClientText(11605), showStar[1], showStar[2])
    end
    self:SetWndText(self.mRandCallTxt, showStarStr)

    local serverData = self:GetCallHeroServerData()
    local callNum = serverData and serverData.callNum or 0
    local dayLimitNumStr = string.replace(ccClientText(11609), callNum, ref.dayExtractNumMax)
    self:SetTextTile(self.mTextTitle7, dayLimitNumStr)

    self:SetWndEasyImage(self.mBg, ref.bg)

    self:RefreshBox()
    self:RefreshCallBtn()
    self:InitNeedAddItemList()

    local refId = ref.refId
    --- 广告按钮
    self:SetWndAdBtnInfo(self.mBtnAd,{
        adMethodId = adMethodId,
        refId = refId,
        callRefId = refId,
        wndId = 490007,
        jumpCB = function()
            GF.CloseWndByName("UIMirNew")
        end,
    })
    self:RefreshAdBtnShow()
end

function UISubMirrorYell:DoMoveTween(trans, callback)
    local pos = trans.localPosition
    local moveX = 0
    local isZero = pos.x == 0
    if not isZero then
        local curDivPos = self.mCallHeroTypeDiv.localPosition
        local curDivPosX = curDivPos.x
        local divIsLeft = curDivPosX > 0
        local transIsLeft = pos.x < 0
        local halfSceneWidth = 640 / 2
        local divWidth = self.mCallHeroTypeDiv.rect.width / 2
        moveX = (divWidth - halfSceneWidth) * (transIsLeft and 1 or -1)
    end
    local seq = self:TweenSeqCreate("MoveCallHeroTypeDiv", function(seq)
        local moveTween = self.mCallHeroTypeDiv:DOLocalMoveX(moveX, 0.5)
        seq:Append(moveTween)
        return seq
    end)
    seq:OnComplete(function()
        self:TweenSeqKill("MoveCallHeroTypeDiv")
        if callback then
            callback()
        end
    end)
    seq:PlayForward()
end

function UISubMirrorYell:OnDrawNeedAddItemCell(list, item, itemdata, itempos)
    local IconTrans = self:FindWndTrans(item, "IconDiv/Icon")
    local NumTrans = self:FindWndTrans(item, "Num")
    local AddBtnTrans = self:FindWndTrans(item, "BtnDiv/AddBtn")

    local itemId = itemdata.itemId
    local icon = gModelItem:GetItemIconByRefId(itemId)
    self:SetWndEasyImage(IconTrans, icon)

    local haveNum = gModelItem:GetNumStrByRefId(itemId)
    self:SetWndText(NumTrans, haveNum)

    self:SetWndClick(AddBtnTrans, function()
        self:OnClickAddBtnFunc(itemdata)
    end)
end

function UISubMirrorYell:RefreshAct()

end

----------------------------- timer -----------------------------

function UISubMirrorYell:CreateTimer(key, time, loopCnt)
    time = time or 1
    loopCnt = loopCnt or -1
    self:TimerStop(key)
    self:TimerStart(key, time, false, loopCnt)
end

function UISubMirrorYell:RefreshCallRedPoint()
    local callBtnInfoList = self._callBtnInfoList
    for i, v in ipairs(callBtnInfoList) do
        local showRedPoint = self:CheckRedPoint(v.callRefId)
        CS.ShowObject(v.btnRedPointTrans, showRedPoint)
    end
end

function UISubMirrorYell:RefreshServerData()
    self._sendMsg = false
    self:InitCallServerData()
    self:RefreshBox()
    local isHaveAct = self:CheckIsHaveActivity()
    if isHaveAct then
        self:RefreshActivityCallTypeBtnList()
    else
        self:RefreshCallRedPoint()
        self:RefreshCallTypeView()
    end
end

function UISubMirrorYell:OnTcpReconnect()
    self._sendMsg = false
end

function UISubMirrorYell:ClearActTimer(key)
    if not self._actTimerList then
        return
    end
    local timer = self._actTimerList[key]
    if not timer then
        return
    end
    LxTimer.DelayTimeStop(timer)
    self._actTimerList[key] = nil
end

function UISubMirrorYell:ClearAllActTimer()
    if not self._actTimerList then
        return
    end
    local actTimerList = self._actTimerList
    for k, timer in pairs(actTimerList) do
        LxTimer.DelayTimeStop(timer)
        actTimerList[k] = nil
    end
    self._actTimerList = nil
end

function UISubMirrorYell:OnClickTenCallBtnFunc()
    local callRefId = self._callRefId
    -- local curIsSelAct = callRefId == ModelActivity.LIMIT_CALL
    -- if curIsSelAct then
    -- 	local curActivityData = self:GetCurSelLimitCallData()
    -- 	if curActivityData then
    -- 		self:OnClickActivityFunc(curActivityData,10,2)
    -- 	end
    -- else
    self:OnSendCallFunc(2)
    -- end
end

function UISubMirrorYell:OnClickCallTypeBtnFunc(tCallRefId, showType)
    if tCallRefId == self._callRefId then
        return
    end
    if self:TweenSeqFind("MoveCallHeroTypeDiv") then
        return
    end

    local callback = function()
        local isShowAct = self:CheckIsHaveActivity()
        if isShowAct then
            self:OnRefreshActivityCallType(tCallRefId)
        else
            self:OnRefreshNormalCallType(tCallRefId)
        end
    end
    local curSelTrans
    for i, v in ipairs(self._callBtnInfoList) do
        local isSel = v.callRefId == tCallRefId
        if isSel then
            curSelTrans = v.btnTrans
            break
        end
    end
    if curSelTrans then
        self:DoMoveTween(curSelTrans, callback)
    else
        callback()
    end
end

function UISubMirrorYell:GetActivityLimitCallDataList()
    self._curSelLimitCallSid = nil
    -- local activityDataList = gModelActivity:GetActivityDataByModelId(ModelActivity.LIMIT_CALL,ModelActivity.STATUS_VALID)
    local activityDataList = {}
    self._activityDataList = activityDataList
    local activityDataSidList = {}
    self._activityDataSidList = activityDataSidList
    local sid, actWebData, config
    for i, v in ipairs(activityDataList) do
        sid = v.sid
        if not self._curSelLimitCallSid then
            self._curSelLimitCallSid = sid
        end
        actWebData = gModelActivity:GetWebActivityDataById(sid)
        if actWebData then
            config = actWebData.config
            if config then
                local data = {}
                local moreInfo = JSON.decode(v.moreInfo)
                local playerWishData = moreInfo.playerWishData

                local wishSettingsList = {}
                local wishSettingOpenList = {}
                local wishSettingOpenNumList = {}
                local wishSettingKeyOpenList = {}
                local wishSettingSortOpenList = {}
                local wishSettingsRateKeyList = {}
                local tWSRaceType, openStatus, tOpenState, tOpenNum
                local wishSettings = string.split(config.wishSettings, "|")
                for idx, val in ipairs(wishSettings) do
                    val = string.split(val, "=")
                    tWSRaceType = tonumber(val[2])
                    tOpenNum = tonumber(val[4])
                    openStatus = tonumber(val[3]) or 0
                    tOpenState = openStatus == 1
                    if tOpenState then
                        wishSettingOpenList[tWSRaceType] = tWSRaceType
                        wishSettingKeyOpenList[tWSRaceType] = {}
                        wishSettingOpenNumList[tWSRaceType] = tOpenNum
                        table.insert(wishSettingSortOpenList, {
                            groupId = tonumber(val[1]),
                            raceType = tWSRaceType,
                        })
                    end
                    wishSettingsRateKeyList[tonumber(val[1])] = tonumber(val[5])
                    table.insert(wishSettingsList, {
                        groupId = tonumber(val[1]), --- 组序号
                        raceType = tWSRaceType, --- 种族refId
                        isOpen = openStatus, --- 是否开放
                        openNum = tOpenNum, --- 心愿槽位数
                        zhSucRate = tonumber(val[5]), --- 单位已选槽置换成功率
                    })
                end
                table.sort(wishSettingSortOpenList, function(a, b)
                    return a.raceType < b.raceType
                end)
                local wishSettingIndexOpenList = {}
                for idx, val in ipairs(wishSettingSortOpenList) do
                    wishSettingIndexOpenList[val.raceType] = idx
                end

                local id_rewardList = {}
                local id_rewardKeyList = {}
                local id_reward = moreInfo.id_reward
                local tEntryId, heroRefId
                local tStr
                for idx, val in ipairs(id_reward) do
                    val = string.split(val, "_")
                    tStr = string.split(val[2], "=")
                    tEntryId = tonumber(val[1])
                    heroRefId = tonumber(tStr[2])
                    table.insert(id_rewardList, {
                        entryId = tEntryId,
                        heroRefId = heroRefId,
                    })
                    id_rewardKeyList[tEntryId] = heroRefId
                end
                data.id_reward = id_rewardList
                data.id_rewardKeyList = id_rewardKeyList

                local id_numList = {}
                local id_numKeyList = {}
                local tEnrtyId, tPlayerLimitNum
                local id_num = moreInfo.id_num
                for idx, val in ipairs(id_num) do
                    val = string.split(val, "_")
                    tEnrtyId, tPlayerLimitNum = tonumber(val[1]), tonumber(val[2])
                    id_numKeyList[tEnrtyId] = tPlayerLimitNum
                    table.insert(id_numList, {
                        entryId = tEnrtyId,
                        playerLimitNum = tPlayerLimitNum
                    })
                end
                data.id_numList = id_numList
                data.id_numKeyList = id_numKeyList

                -------------------- wishes
                local wishes = playerWishData.wishes
                local wishesList = {}
                local wishesKeyList = {}
                for tGroupId, selVal in pairs(wishes) do
                    local tGoupIdList = {}
                    local tGroupIdSortList = {}
                    for idx, val in ipairs(selVal) do
                        tGoupIdList[val] = val
                        table.insert(tGroupIdSortList, val)
                    end
                    wishesList[tGroupId] = tGroupIdSortList
                    wishesKeyList[tGroupId] = tGoupIdList
                end
                -------------------- dropRecords
                local dropRecords = playerWishData.dropRecords
                local dropRecordsKeyList = {}
                for tGroupId, count in pairs(dropRecords) do
                    dropRecordsKeyList[tGroupId] = count
                end
                -------------------- exRates
                local exRatesSortList = {}
                local exRatesKeyList = {}
                local exRatesNum = 0
                local exRates = playerWishData.exRates
                local isExRatesEmpty = table.isempty(exRates)
                for tRaceType, tExRates in pairs(exRates) do
                    tRaceType = tonumber(tRaceType)
                    table.insert(exRatesSortList, {
                        raceType = tRaceType,
                        exRates = tExRates
                    })
                    exRatesKeyList[tRaceType] = tExRates
                    exRatesNum = exRatesNum + 1
                end

                --- 保证开放的组id全部显示
                local wishGroupId
                for idx, val in ipairs(wishSettingSortOpenList) do
                    wishGroupId = val.groupId
                    if not wishesList[tostring(wishGroupId)] then
                        wishesList[tostring(wishGroupId)] = {}
                    end
                    if not wishesKeyList[wishGroupId] then
                        wishesKeyList[wishGroupId] = {}
                    end
                    if not exRatesKeyList[wishGroupId] then
                        table.insert(exRatesSortList, {
                            raceType = wishGroupId,
                            exRates = 0
                        })
                        exRatesKeyList[wishGroupId] = 0
                        exRatesNum = exRatesNum + 1
                    end
                end

                data.wishes = wishes
                data.wishesList = wishesList
                data.wishesKeyList = wishesKeyList

                data.dropRecords = dropRecords
                data.dropRecordsKeyList = dropRecordsKeyList

                table.sort(exRatesSortList, function(a, b)
                    return a.raceType < b.raceType
                end)
                local exRatesSortKeyList = {}
                for idx, val in ipairs(exRatesSortList) do
                    exRatesSortKeyList[val.raceType] = idx
                end

                data.exRates = exRates
                data.isExRatesEmpty = isExRatesEmpty
                data.exRatesNum = exRatesNum
                data.exRatesSortList = exRatesSortList
                data.exRatesSortKeyList = exRatesSortKeyList
                data.exRatesKeyList = exRatesKeyList

                data.score = playerWishData.score

                data.callNum = moreInfo.callNum
                data.dropNumToday = moreInfo.dropNumToday
                data.freeNum = moreInfo.freeNum
                data.refreshTimeOfFreeNum = moreInfo.refreshTimeOfFreeNum
                data.nextRefreshTimeOfFreeNum = moreInfo.nextRefreshTimeOfFreeNum

                data.refreshTimeOfCallNum = moreInfo.refreshTimeOfCallNum
                data.nextRefreshTimeOfCallNum = moreInfo.nextRefreshTimeOfCallNum

                data.sid = sid
                data.endTime = v.endTime

                local callCurrencyBarList = {}
                local callCurrencyBar = string.split(config.callCurrencyBar, "|")
                for idx, val in ipairs(callCurrencyBar) do
                    table.insert(callCurrencyBarList, {
                        itemType = LItemTypeConst.TYPE_ITEM,
                        itemId = tonumber(val),
                    })
                end

                data.name = config.name                                        --- 活动名称
                data.extraCallGoal = config.extraCallGoal                    --- 额外召唤目标积分
                data.image = config.image                                    --- 背景图
                data.callMaxNum = config.callMaxNum                            --- 每日能召唤的最大次数
                data.freeTimes = config.freeTimes                            --- 每天赠送的免费次数
                data.goldTimes = config.goldTimes                            --- 每天使用钻石购买的次数上限
                data.logNumMax = config.logNumMax                            --- 每日志存放上限
                data.rollingTime = config.rollingTime                        --- 心愿伙伴头像滚动间隔，单位：秒
                data.helpTxt = config.helpTxt                                --- 帮助界面文本
                data.callTips = config.callTips                                --- 召唤提示
                data.getLimitTips = config.getLimitTips                        --- 获取上限提示
                data.choseTips = config.choseTips                            --- 伙伴列表提示文本
                data.callDiamondTips = config.callDiamondTips                --- 结果界面钻石提示文本
                data.callResultBg = config.callResultBg                        --- 结果界面背景
                data.tipRefId = config.tipRefId                                --- 召唤二次确认提示，填WindowAttRef的refID
                data.callLimitTips = config.callLimitTips                    --- 今日抽取上限提示文本
                data.diaCallLimitTips = config.diaCallLimitTips                --- 今日钻石抽取提示文本
                data.callHeroShowResultCd = config.callHeroShowResultCd        --- 结果界面背景立绘轮换cd，单位：秒
                data.policyTxt = config.policyTxt                            --- 【概率】界面的政策说明文本
                data.specialTxt = config.specialTxt                            --- 【概率】界面的特殊说明文本
                data.callEff = config.callEff                                --- 召唤动画特效
                data.extraCallBtnEff = config.extraCallBtnEff                --- 额外积分召唤：可召唤时的按钮特效

                local callBtnTxt = string.split(config.callBtnTxt, "=")
                data.callBtnTxt = {
                    freeBtnTxt = callBtnTxt[1],
                    oneBtnTxt = callBtnTxt[2],
                    tenBtnTxt = callBtnTxt[3],
                }                                                            --- 召唤按钮文本，配置格式：免费=单抽=十连抽

                local callAgainBtnTxt = string.split(config.callAgainBtnTxt, "=")
                data.callAgainBtnTxt = {
                    freeBtnTxt = callAgainBtnTxt[1],
                    oneBtnTxt = callAgainBtnTxt[2],
                    tenBtnTxt = callAgainBtnTxt[3],
                }                                                            --- 结果界面按钮文本，配置格式：免费=单次=十连抽

                data.costOne1 = LxDataHelper.ParseItem_3(config.costOne1)    --- 1抽的花费(钻石）
                data.costOne2 = LxDataHelper.ParseItem_3(config.costOne2)    --- 1抽的花费(道具）

                data.costTen1 = LxDataHelper.ParseItem_3(config.costTen1)    --- 10连抽的花费（钻石）
                data.costTen2 = LxDataHelper.ParseItem_3(config.costTen2)    --- 10连抽的花费（道具）

                data.onePayList = { data.costOne2, data.costOne1 }
                data.tenPayList = { data.costTen2, data.costTen1 }

                data.goodsOne = LUtil.ConvertCommonItemStrToList(config.goodsOne)    --- 抽1次购买的道具和数量(若有多个道具，提示弹窗只显示最后一个)
                data.goodsTen = LUtil.ConvertCommonItemStrToList(config.goodsTen)    --- 抽10次购买的道具和数量(若有多个道具，提示弹窗只显示最后一个)

                local icon = string.split(config.icon, "|")
                data.icon = {
                    notSelIcon = icon[1], --- 未选择
                    selIcon = icon[2], --- 已选择
                }                                                            --- 入口选项图标，配置格式：未选择|已选择
                data.wishSettings = wishSettingsList                        --- 心愿单列表
                data.wishSettingOpenList = wishSettingOpenList
                data.wishSettingKeyOpenList = wishSettingKeyOpenList
                data.wishSettingOpenNumList = wishSettingOpenNumList
                data.wishSettingSortOpenList = wishSettingSortOpenList
                data.wishSettingsRateKeyList = wishSettingsRateKeyList
                data.wishSettingIndexOpenList = wishSettingIndexOpenList
                data.callCurrencyBar = callCurrencyBarList                    --- 货币栏道具展示

                activityDataSidList[sid] = data
            end
        else
            self._getActWebDataSid = sid
        end
    end
end

function UISubMirrorYell:RefreshActivityZHHeroIcon(showEFF)
    local curActivityData = self:GetCurSelLimitCallData()
    if not curActivityData then
        return
    end

    local curActRaceType = self._activityRaceType
    if not curActRaceType then
        return
    end

    local wishesList
    local wishKey
    local isExRatesEmpty = curActivityData.isExRatesEmpty
    if not isExRatesEmpty then
        wishesList = curActivityData.wishesList
        wishKey = tostring(curActRaceType)
    else
        wishesList = curActivityData.wishSettingKeyOpenList
        wishKey = curActRaceType
    end
    if not wishesList then
        return
    end

    local wishesInfo = wishesList[wishKey]
    if not wishesInfo then
        return
    end

    local wishSettingOpenNumList = curActivityData.wishSettingOpenNumList
    local wishSettingOpenInfo = wishSettingOpenNumList[curActRaceType] or {}

    local heroShowTransInfoList = self._heroShowTransInfoList
    if not heroShowTransInfoList then
        return
    end

    local id_rewardKeyList = curActivityData.id_rewardKeyList
    for i, v in ipairs(heroShowTransInfoList) do
        local NoHeroTrans = v.NoHeroTrans
        local HeroIconTrans = v.HeroIconTrans

        local selId = wishesInfo[i]
        local isSel = selId ~= nil
        local showHeroIcon = false
        local checkFunc
        if isSel then
            --local heroRefId = id_rewardKeyList[selId]
            --if heroRefId then
            --	local effRef = gModelHero:GetHeroShowRefByRefId(heroRefId)
            --	if effRef then
            --		local heroRoundIcon = effRef.heroRoundIcon
            --		checkFunc = function()
            --			self:SetWndEasyImage(HeroIconTrans,heroRoundIcon)
            --		end
            --		showHeroIcon = true
            --	end
            --end
        end
        local showNoHero = not isSel
        if wishSettingOpenInfo < i then
            isSel = false
            showNoHero = false
        end
        local EffRootTrans = v.EffRootTrans
        local seqKey = EffRootTrans:GetInstanceID()
        if showEFF then
            self:CreateCurHeroAni({
                seqKey = seqKey,
                waitTime = 0.6,
                beforeFunc = function()
                    CS.ShowObject(EffRootTrans, true)
                end,
                callBackFunc = function()
                    CS.ShowObject(EffRootTrans, false)
                    if checkFunc then
                        checkFunc()
                    end
                    CS.ShowObject(HeroIconTrans, showHeroIcon)
                    CS.ShowObject(NoHeroTrans, showNoHero)
                end
            })
        else
            local seq = self:TweenSeqFind(seqKey)
            if seq then
                self:TweenSeqKill(seqKey)
            end
            if checkFunc then
                checkFunc()
            end
            CS.ShowObject(HeroIconTrans, showHeroIcon)
            CS.ShowObject(NoHeroTrans, showNoHero)
        end

        CS.ShowObject(v.rootTrans, true)
    end
end

function UISubMirrorYell:OnDrawActivityZHHeroRaceCell(list, item, itemdata, itempos)
    local RaceIconTrans = self:FindWndTrans(item, "RaceIcon")
    local SelIconTrans = self:FindWndTrans(item, "SelIcon")
    local BtnTrans = self:FindWndTrans(item, "Btn")
    local UITextTrans = self:FindWndTrans(item, "UIText")

    local raceType = itemdata.raceType
    local raceIcon = gModelHero:GetRaceImgByRefId(raceType)
    self:SetWndEasyImage(RaceIconTrans, raceIcon)

    local isSel = self._activityRaceType == raceType
    CS.ShowObject(SelIconTrans, isSel)

    self:SetWndText(UITextTrans, itemdata.exRates .. "%")

    self:SetWndClick(BtnTrans, function()
        self:OnClickActivityZHHeroRaceFunc(itemdata)
    end)
end

function UISubMirrorYell:SetHourTimer(timeTxtTrans, serverTime, addHour)
    local curYear = tonumber(LUtil.OSDate("%Y", serverTime))
    local curMon = tonumber(LUtil.OSDate("%m", serverTime))
    local curDay = tonumber(LUtil.OSDate("%d", serverTime))
    local curHour = tonumber(LUtil.OSDate("%H", serverTime))
    local nextDayTime = LUtil.OSTime({ hour = curHour + addHour, day = curDay, month = curMon, year = curYear })
    local curTime = tonumber(GetTimestamp())
    local timeStr = ""
    if nextDayTime < curTime then
        self:TimerStop(self._oneTimerKey)
    else
        local remainTime = nextDayTime - curTime
        if remainTime <= 0 then
            self:TimerStop(self._oneTimerKey)
        else
            timeStr = string.replace(ccClientText(11623), LUtil.FormatTimespanNumber(remainTime))
        end
    end
    self:SetWndText(timeTxtTrans, timeStr)
end

function UISubMirrorYell:InitIntegralInfo()
    local integralNeedRefId = self._integralNeedRefId
    local integralNeedNum = self._integralNeedNum
    if not integralNeedRefId or not integralNeedNum then
        -- 进度条计算
        local integralNeedItem = GameTable.SummonConfigRef["integralNeedItem"]
        integralNeedItem = string.split(integralNeedItem, "=")
        integralNeedRefId, integralNeedNum = tonumber(integralNeedItem[2]), tonumber(integralNeedItem[3])
        self._integralNeedRefId = integralNeedRefId
        self._integralNeedNum = integralNeedNum
    end
end

function UISubMirrorYell:InitActivityCallTypeBtnInfo()
    local activityCallBtnInfoList = {
        {
            btnTrans = self.mActivityBaseCallBtn,
            callRefId = ModelCallHero.CALL_TYPE_BASE,
            btnName = ccClientText(27802),
            showType = UISubMirrorYell.SHOW_TYPE_NORMAL,
        },
        {
            btnTrans = self.mActivitySpecialCallBtn,
            callRefId = ModelCallHero.CALL_TYPE_SPECIAL,
            btnName = ccClientText(27800),
            showType = UISubMirrorYell.SHOW_TYPE_NORMAL,
        },
        {
            btnTrans = self.mActivityFriendCallBtn,
            callRefId = ModelCallHero.CALL_TYPE_FRIEND,
            btnName = ccClientText(27801),
            showType = UISubMirrorYell.SHOW_TYPE_NORMAL,
        },
        -- {
        -- 	btnTrans = self.mActivityLimitCallBtn,
        -- 	callRefId = ModelActivity.LIMIT_CALL,
        -- 	btnName = "",
        -- 	showType = UISubMirrorYell.SHOW_TYPE_ACTIVITY,
        -- },
    }

    for i, v in ipairs(activityCallBtnInfoList) do
        local btnTrans = v.btnTrans

        local callRefId = v.callRefId

        self:SetWndClick(btnTrans, function()
            self:OnClickCallTypeBtnFunc(callRefId, v.showType)
        end)

        local NoSelImgTrans = self:FindWndTrans(btnTrans, "NoSelImg")
        local SelImgTrans = self:FindWndTrans(btnTrans, "SelImg")
        local RedPointTrans = self:FindWndTrans(btnTrans, "redPoint")
        local TimeBgTrans = self:FindWndTrans(btnTrans, "TimeBg")
        local UITextTrans = self:FindWndTrans(TimeBgTrans, "UIText")

        local btnName = v.btnName
        self:SetTextTile(NoSelImgTrans, btnName, -30)
        self:SetTextTile(SelImgTrans, btnName, -30)

        v.btnNoSelTrans = NoSelImgTrans
        v.btnSelTrans = SelImgTrans
        v.btnRedPointTrans = RedPointTrans
        v.btnTimeBgTrans = TimeBgTrans
        v.btnUITextTrans = UITextTrans
    end

    self._activityCallBtnInfoList = activityCallBtnInfoList
end

function UISubMirrorYell:InitCallTypeBtnInfo()
    local callBtnInfoList = {
        {
            btnTrans = self.mBaseCallBtn,
            callRefId = ModelCallHero.CALL_TYPE_BASE,
            btnName = ccClientText(27802),
            showType = UISubMirrorYell.SHOW_TYPE_NORMAL,
        },
        {
            btnTrans = self.mSpecialCallBtn,
            callRefId = ModelCallHero.CALL_TYPE_SPECIAL,
            btnName = ccClientText(27800),
            showType = UISubMirrorYell.SHOW_TYPE_NORMAL,
        },
        {
            btnTrans = self.mFriendCallBtn,
            callRefId = ModelCallHero.CALL_TYPE_FRIEND,
            btnName = ccClientText(27801),
            showType = UISubMirrorYell.SHOW_TYPE_NORMAL,
        },
    }

    for i, v in ipairs(callBtnInfoList) do
        local btnTrans = v.btnTrans

        self:SetWndClick(btnTrans, function()
            self:OnClickCallTypeBtnFunc(v.callRefId, v.showType)
        end)

        local NoSelImgTrans = self:FindWndTrans(btnTrans, "NoSelImg")
        local SelImgTrans = self:FindWndTrans(btnTrans, "SelImg")
        local RedPointTrans = self:FindWndTrans(btnTrans, "redPoint")

        local btnName = v.btnName
        self:SetTextTile(NoSelImgTrans, btnName, -30)
        self:SetTextTile(SelImgTrans, btnName)

        v.btnNoSelTrans = NoSelImgTrans
        v.btnSelTrans = SelImgTrans
        v.btnRedPointTrans = RedPointTrans
    end

    self._callBtnInfoList = callBtnInfoList
end

function UISubMirrorYell:RefreshCallTypeBtnStatus()
    local isHaveAct = self:CheckIsHaveActivity()
    CS.ShowObject(self.mCallHeroTypeDiv, not isHaveAct)
    CS.ShowObject(self.mActivityCallHeroTypeDiv, isHaveAct)
    if isHaveAct then
        self:RefreshActivityCallTypeBtnList()
    else
        self:RefreshCallTypeBtnList()
    end
end

function UISubMirrorYell:CreateCurHeroIconTimer(rollingTime)
    self:TimerStop(self._curHeroIconTimerKey)
    self:CreateTimer(self._curHeroIconTimerKey, rollingTime, 1)
end

function UISubMirrorYell:CreateBoxEff()
    if UISubMirrorYell.USE_BOX_TYPE == 1 then
        local effectKey = "fx_baoxiang_paiweisai01"
        --self:CreateWndEffect(self.mBoxEffect,effectKey,effectKey,100,false,false)
    else
        local curPos = self.mBoxEffect.localPosition
        self.mBoxEffect.localPosition = Vector3(curPos.x, curPos.y + 35, curPos.z)
        local spineName = "Shiguangbaozanxiangzi_hong"
        --self:CreateWndSpine(self.mBoxEffect,spineName,self._spineBoxKey,false,function()
        --	self:RefreshBoxShow()
        --end)
    end

    CS.ShowObject(self.mBoxEffect, false)
    CS.ShowObject(self.mBoxImg, true)
end

function UISubMirrorYell:RefreshActBox(curActivityData)
    curActivityData = curActivityData or self:GetCurSelLimitCallData()
    if not curActivityData then
        return
    end
    local score = curActivityData.score
    local extraCallGoal = curActivityData.extraCallGoal
    local str = string.format("%s/%s", score, extraCallGoal)
    self:SetWndText(self.mActivityJinDuTxt, str)
    local percentage = score / extraCallGoal
    LxUiHelper.SetProgress(self.mActivityJinDuTiao, percentage)
    local showRedPoint = score >= extraCallGoal
    CS.ShowObject(self.mActivityBoxRedPoint, showRedPoint)
    CS.ShowObject(self.mActivityBoxEffect, showRedPoint)
end

function UISubMirrorYell:OnClickOneCallBtnFunc()
    local callRefId = self._callRefId
    -- local curIsSelAct = callRefId == ModelActivity.LIMIT_CALL
    -- if curIsSelAct then
    -- 	local curActivityData = self:GetCurSelLimitCallData()
    -- 	if curActivityData then
    -- 		self:OnClickActivityFunc(curActivityData,1,1)
    -- 	end
    -- else
    self:OnSendCallFunc(1)
    -- end
end

function UISubMirrorYell:OnRefreshActivityCallType(tCallRefId)
    self._callRefId = tCallRefId
    self:RefreshActivityCallTypeBtnList(true)
end

function UISubMirrorYell:InitCallServerData()
    self._callHeroServerData = gModelCallHero:GetCallHeroData()
end

function UISubMirrorYell:InitText()
    self:SetTextTile(self.mDetailsBtn, ccClientText(21813))            -- 详情
    self:SetTextTile(self.mActivityDetailsBtn, ccClientText(21813))            -- 详情
    self:SetTextTile(self.mLogBtn, ccClientText(11672))
    self:SetTextTile(self.mActivityLogBtn, ccClientText(11672))
    self:SetTextTile(self.mWishListBtn, ccClientText(32105))
    self:SetTextTile(self.mRecommendBtn, ccClientText(11673))
    self:SetTextTile(self.mRankBtn, ccClientText(11674))
    self:SetWndText(self.mActivityZHTitle, ccClientText(32101))
    self:SetWndText(self.mJumpAniBgTxt, ccClientText(18321))
    self:InitTextLineWithLanguage(self.mJumpAniBgTxt, -30)
    self:SetWndText(self.mSacrificeSelTxt, ccClientText(10178))
end

function UISubMirrorYell:GetCallHeroServerData(tCallRefId)
    local callHeroServerData = self._callHeroServerData
    if not callHeroServerData then
        return
    end
    local callRefId = tCallRefId or self._callRefId
    return callHeroServerData[callRefId]
end

function UISubMirrorYell:OnRefreshAds()
    self:RefreshAdBtnShow()
end

--- 获取召唤按钮显示道具信息
function UISubMirrorYell:GetCallBtnInfo()
    local ref = self:GetCallTypeRef()
    if not ref then
        return
    end
    local oneExpend = LUtil.ConvertCommonItemStrToList(ref.oneExpend, "|")
    local tenExpend = LUtil.ConvertCommonItemStrToList(ref.tenExpend, "|")
    local onePayInfo = self:GetUsePayInfo(oneExpend)
    local tenPayInfo = self:GetUsePayInfo(tenExpend)
    return onePayInfo, tenPayInfo
end

function UISubMirrorYell:OnSendCallFunc(callType)
    local sendMsgFunc = function()
        if self._sendMsg then
            return
        end
        local sendFunc = function()
            self._sendMsg = true
        end
        local wndName = self:GetParentWndName()
        gModelCallHero:SendCallHeroReq(self._callRefId, callType, wndName, true, sendFunc)
    end

    local isEnough = gModelCallHero:CheckCallIsEnough(self._callRefId, callType, self:GetParentWndName())
    if isEnough == 1 then
        --- 背包满了
        return
    end
    if isEnough then
        local status = self._jumpAniStatus
        if status then
            sendMsgFunc()
        else
            if ModelCallHero.MIRRORCALLHERO_STATUS == 1 then
                sendMsgFunc()
            elseif PRODUCT_G_VER ~= 0 then
                --提审屏蔽
                sendMsgFunc()
            else

                local callNum = callType == 1 and 1 or 10
                GF.OpenWnd("UIMirrorYellSagaSow", {
                    viewType = 1,
                    callRefId = self._callRefId,
                    sendMsgFunc = sendMsgFunc,
                    callNum = callNum
                })
            end
        end
    else
        sendMsgFunc()
    end

end

function UISubMirrorYell:CreateBtnEff(trans, effName)
    local key = trans:GetInstanceID()
    self:CreateWndEffect(trans, effName, key, 100, false, false)
end

function UISubMirrorYell:OnClickAddBtnFunc(itemdata)
    gModelGeneral:OpenGetWayWnd({ itemId = itemdata.itemId })
end

function UISubMirrorYell:InitEvent()
    self:SetWndClick(self.mOneCallBtn, function()
        self:OnClickOneCallBtnFunc()
    end)
    self:SetWndClick(self.mTenCallBtn, function()
        self:OnClickTenCallBtnFunc()
    end)
    self:SetWndClick(self.mDetailsBtn, function()
        self:OnClickDetailsBtnFunc()
    end)
    self:SetWndClick(self.mLogBtn, function()
        self:OnClickLogBtnFunc()
    end)
    self:SetWndClick(self.mRecommendBtn, function()
        self:OnClickRecommendBtnFunc()
    end)
    self:SetWndClick(self.mRankBtn, function()
        self:OnClickRankBtnFunc()
    end)
    self:SetWndClick(self.mBoxBtn, function()
        self:OnClickBoxBtnFunc()
    end)
    self:SetWndClick(self.mJumpAniBtn, function()
        self:OnClickJumpAniFunc()
    end)
    self:SetWndClick(self.mJumpAniBg, function()
        self:OnClickJumpAniFunc()
    end)
    self:SetWndClick(self.mSacrificeSelBtn, function()
        self:OnClickSacrificeSelBtnEvent()
    end)
    self:SetWndClick(self.mSacrificeSelBg, function()
        self:OnClickSacrificeSelBtnEvent()
    end)
    self:SetWndClick(self.mActivityDetailsBtn, function()
        self:OnClickActivityDetailsBtnFunc()
    end)
    self:SetWndClick(self.mActivityLogBtn, function()
        self:OnClickActivityLogBtnFunc()
    end)
    self:SetWndClick(self.mWishListBtn, function()
        self:OnClickWishListBtnFunc()
    end)
    self:SetWndClick(self.mActivityBoxBtn, function()
        self:OnClickActivityBoxBtnFunc()
    end)
end

---@return V_CallRef
function UISubMirrorYell:GetCallTypeRef()
    local callRefId = self._callRefId
    return gModelCallHero:GetCallRefByRefId(callRefId)
end

function UISubMirrorYell:CheckIsHaveActivity()
    if not self._activityDataList then
        self:GetActivityLimitCallDataList()
    end
    return #self._activityDataList > 0
end

function UISubMirrorYell:RefreshSacrificeSelShow()
    local isShow = self._callRefId == ModelCallHero.CALL_TYPE_BASE
    CS.ShowObject(self.mSacrificeSelBtn, isShow)
end

function UISubMirrorYell:InitActivityZHHeroRaceList(exRates, rollingTime)
    local list = {}
    local tRaceType
    for k, v in pairs(exRates) do
        tRaceType = tonumber(v.raceType)
        table.insert(list, {
            raceType = tRaceType,
            exRates = v.exRates,
            rollingTime = rollingTime
        })
    end
    table.sort(list, function(a, b)
        return a.raceType < b.raceType
    end)
    local uiActivityZHHeroRaceList = self._uiActivityZHHeroRaceList
    if uiActivityZHHeroRaceList then
        uiActivityZHHeroRaceList:RefreshList(list)
    else
        uiActivityZHHeroRaceList = self:GetUIScroll("uiActivityZHHeroRaceList")
        self._uiActivityZHHeroRaceList = uiActivityZHHeroRaceList
        uiActivityZHHeroRaceList:Create(self.mActivityZHHeroRaceList, list, function(...)
            self:OnDrawActivityZHHeroRaceCell(...)
        end)
    end
end

--- 筛选召唤按钮显示道具信息
function UISubMirrorYell:GetUsePayInfo(payList)
    payList = payList or {}
    local len = #payList
    local usePayInfo
    if len == 1 then
        usePayInfo = payList[len]
    else
        local itemId, itemNum, haveNum
        for i, v in ipairs(payList) do
            itemId = v.itemId
            itemNum = v.itemNum
            haveNum = gModelItem:GetNumByRefId(itemId)
            if i == 1 and haveNum >= itemNum then
                usePayInfo = v
                break
            end
        end
        if not usePayInfo then
            usePayInfo = payList[len]
        end
    end
    return usePayInfo
end

function UISubMirrorYell:RefreshActivityCallTypeBtnList(changeCallType)
    local callRefId = self._callRefId
    -- local curIsSelAct = callRefId == ModelActivity.LIMIT_CALL
    local curIsSelAct = false

    local curActivityData = self:GetCurSelLimitCallData()
    CS.ShowObject(self.mGameActivityView, curIsSelAct)
    CS.ShowObject(self.mGameCallView, not curIsSelAct and ModelCallHero.TYPE_SHOW_STATE == 0)

    local activityCallBtnInfoList = self._activityCallBtnInfoList
    local curSelCallRefId
    for i, v in ipairs(activityCallBtnInfoList) do
        curSelCallRefId = v.callRefId
        -- if curSelCallRefId == ModelActivity.LIMIT_CALL and curActivityData then
        -- 	local icon = curActivityData.icon

        -- 	self:SetWndEasyImage(v.btnNoSelTrans,icon.notSelIcon)
        -- 	self:SetWndEasyImage(v.btnSelTrans,icon.selIcon)

        -- 	local name = curActivityData.name
        -- 	self:SetTextTile(v.btnNoSelTrans,name, -30)
        -- 	self:SetTextTile(v.btnSelTrans,name, -30)

        -- 	self:CreateActTimer(curActivityData.sid,v.btnTimeBgTrans,v.btnUITextTrans,curActivityData.endTime)
        -- end
        local isSel = curSelCallRefId == callRefId
        if isSel then
            self._showType = v.showType
        end
        CS.ShowObject(v.btnNoSelTrans, not isSel)
        CS.ShowObject(v.btnSelTrans, isSel)

        local showRedPoint = self:CheckRedPoint(curSelCallRefId)
        CS.ShowObject(v.btnRedPointTrans, showRedPoint)
    end
    self:RefreshSacrificeSelShow()
    if curIsSelAct then
        self:TimerStop(self._cutHeroTimerKey)
        self:RefreshActCallTypeView(curActivityData)
    else
        self:RefreshCallTypeView()
    end
end

function UISubMirrorYell:RefreshCallTypeBtnList(changeCallType)
    CS.ShowObject(self.mGameCallView, ModelCallHero.TYPE_SHOW_STATE == 0)
    CS.ShowObject(self.mGameActivityView, false)
    local callRefId = self._callRefId
    local callBtnInfoList = self._callBtnInfoList
    for i, v in ipairs(callBtnInfoList) do
        local isSel = v.callRefId == callRefId
        if isSel then
            self._showType = v.showType
        end
        --CS.ShowObject(v.btnNoSelTrans,not isSel)
        CS.ShowObject(v.btnSelTrans, isSel)
    end

    self:RefreshCallTypeView()
    self:RefreshSacrificeSelShow()
end

function UISubMirrorYell:RefreshCallBtn()
    local callBtnTransInfo = self._callBtnTransInfo
    local serverData = self:GetCallHeroServerData()
    local onePayInfo, tenPayInfo = self:GetCallBtnInfo()
    local freeNum = serverData and serverData.freeNum or 0
    local isHaveFree = freeNum > 0
    self:TimerStop(self._oneTimerKey)
    self:SetWndText(self._oneCallTimeTxtTrans, "")
    local oneCallTransInfo = callBtnTransInfo.oneCallTransInfo
    local freeText = ""
    local isNewYear, activitys, textList = gModelActivity:GetPrivilegeShow1(1)
    if isHaveFree then
        if isNewYear then
            local freeStr = textList[1] or ""
            freeText = string.replace(freeStr, freeNum)
        elseif gModelBackflow:GetPrivilegesTypeListByType(9) then
            freeText = string.replace(ccClientText(12141), freeNum)
        end
        freeText = string.replace(ccClientText(12141), freeNum)
    else
        self:CreateTimer(self._oneTimerKey)
    end

    local newYearList = {}
    if isNewYear then
        for i, v in ipairs(activitys) do
            local activity = v
            local moreInfo = JSON.decode(activity.moreInfo)
            local refIds = moreInfo.privilegeShow1
            local refIdArr = string.split(refIds, "|")
            for idx, val in ipairs(refIdArr) do
                local ref = gModelGeneral:GetSysEffectRef(tonumber(val))
                local effectValue = ref.effectValue
                local arr = string.split(effectValue, "=")
                local key = tonumber(arr[1])
                newYearList[key] = tonumber(arr[2])
            end
        end
    end
    local refId = serverData and serverData.refId or self._callRefId
    local isShowBuff = refId and newYearList[refId]
    CS.ShowObject(self.mBuffBg, isShowBuff)
    if isShowBuff then
        local buffStr = textList[3] or ""
        local tipsStr = textList[4] or ""
        self:SetWndText(self.mBuffText, buffStr)
        self:SetWndClick(self.mBuffBg, function()
            GF.ShowMessage(tipsStr)
        end)
    end

    local oneCallName = gModelCallHero:GetCallBtnName(refId, ModelCallHero.LEFT, isHaveFree)
    local oneCallInfo = {
        btnName = oneCallName,
        freeText = freeText,
        isHaveFree = isHaveFree,
        itemId = onePayInfo and onePayInfo.itemId,
        itemNum = onePayInfo and onePayInfo.itemNum,
        payType = 1,
    }
    self:SetCallBtn(oneCallTransInfo, oneCallInfo)

    local tenCallName = gModelCallHero:GetCallBtnName(refId, ModelCallHero.RIGHT)
    local tenCallTransInfo = callBtnTransInfo.tenCallTransInfo
    local tenCallInfo = {
        btnName = tenCallName,
        freeText = "",
        isHaveFree = false,
        itemId = tenPayInfo and tenPayInfo.itemId,
        itemNum = tenPayInfo and tenPayInfo.itemNum,
        payType = 10,
    }
    self:SetCallBtn(tenCallTransInfo, tenCallInfo)
end

function UISubMirrorYell:SetCallBtn(transInfo, dataInfo)
    local btnNameTrans = transInfo.btnNameTrans
    local payDivTrans = transInfo.payDivTrans
    local iconImgTrans = transInfo.iconImgTrans
    local numTxtTrans = transInfo.numTxtTrans
    local freeTxtTrans = transInfo.freeTxtTrans
    local redPointTrans = transInfo.redPointTrans

    local btnName = dataInfo.btnName
    local freeText = dataInfo.freeText
    self:SetWndText(btnNameTrans, btnName)
    CS.ShowObject(btnNameTrans, true)
    self:SetWndText(freeTxtTrans, freeText)

    local itemId = dataInfo.itemId
    local icon = gModelItem:GetItemIconByRefId(itemId)
    self:SetWndEasyImage(iconImgTrans, icon)

    local itemNum = dataInfo.itemNum
    self:SetWndText(numTxtTrans, itemNum)

    local isHaveFree = dataInfo.isHaveFree
    CS.ShowObject(freeTxtTrans, isHaveFree)
    CS.ShowObject(redPointTrans, isHaveFree)
    CS.ShowObject(payDivTrans, not isHaveFree)
end

function UISubMirrorYell:OnClickBoxBtnFunc()
    GF.OpenWnd("UIIntegralSow", {
        viewType = 1
    })
end

function UISubMirrorYell:SetCountDownTime(timeTxtTrans)
    local serverData = self:GetCallHeroServerData()
    if not serverData then
        self:TimerStop(self._oneTimerKey)
        return
    end
    local serverTime = serverData.nextRefreshTimeOfFreeNum / 1000

    local curTime = tonumber(GetTimestamp())
    local remainTime = serverTime - curTime
    local timeStr = ""
    if remainTime <= 0 then
        self:TimerStop(self._oneTimerKey)
    else
        timeStr = string.replace(ccClientText(11623), LUtil.FormatTimespanNumber(remainTime))
    end
    self:SetWndText(timeTxtTrans, timeStr)
end

function UISubMirrorYell:OnClickDetailsBtnFunc()
    GF.OpenWnd("UIYellHRew", { callRefId = self._callRefId, viewType = 2 })
end

function UISubMirrorYell:OnActivityListResp(pb)
    local activities = pb.activities
    for i, v in ipairs(activities) do
        -- if v.model == ModelActivity.LIMIT_CALL and v.status ~= 3 then
        -- 	self._activityDataList = nil
        -- 	self:RefreshCallTypeBtnStatus()
        -- 	self._sendMsg = false
        -- 	break
        -- end
    end
end

function UISubMirrorYell:OnTimer(key)
    if key == self._oneTimerKey then
        self:SetCountDownTime(self._oneCallTimeTxtTrans)
    elseif key == self._tenTimerKey then
    elseif key == self._cutHeroTimerKey then
        self:TimerStop(self._cutHeroTimerKey)
    elseif key == self._timerPrivileKey then
        self:OpentPrivileKey()
    elseif key == self._curHeroIconTimerKey then
        self:OnTimerCurHeroIconFunc()
    end
end

function UISubMirrorYell:CreateActCountDown(key, timeBgTrans, timeTxtTrans, endTime)
    local curTime = GetTimestamp()
    local lastTime = endTime - curTime
    if lastTime > 0 then
        local str = LUtil.FormatTimespanCn(lastTime)
        self:SetWndText(timeTxtTrans, str)
        CS.ShowObject(timeBgTrans, true)
    else
        self:ClearActTimer(key)
        CS.ShowObject(timeBgTrans, false)
        self:SetWndText(timeTxtTrans, "")
    end
end

function UISubMirrorYell:InitNeedAddItemList(list)
    list = list or self:GetNeedAddItemList()
    local uiNeedAddItemList = self._uiNeedAddItemList
    if uiNeedAddItemList then
        uiNeedAddItemList:RefreshList(list)
    else
        uiNeedAddItemList = self:GetUIScroll("uiNeedAddItemList")
        self._uiNeedAddItemList = uiNeedAddItemList
        uiNeedAddItemList:Create(self.mNeedAddItemList, list, function(...)
            self:OnDrawNeedAddItemCell(...)
        end)
    end
end

function UISubMirrorYell:CreateCurHeroAni(info)
    local seqKey = info.seqKey
    local seqTween = self:TweenSeqFind(seqKey)
    if seqTween then
        self:TweenSeqKill(seqKey)
        seqTween = nil
    end
    local callBackFunc = info.callBackFunc
    local beforeFunc = info.beforeFunc
    if beforeFunc then
        beforeFunc()
    end
    local waitTime = info.waitTime or 0.6
    seqTween = self:TweenSeqCreate(seqKey, function(seq)
        seq:AppendInterval(waitTime)
        return seq
    end)
    seqTween:OnStepComplete(function()
        self:TweenSeqKill(seqKey)
        if callBackFunc then
            callBackFunc()
        end
    end)
    seqTween:PlayForward()
end

function UISubMirrorYell:RefreshActivityZHHeroRaceList()
    local uiActivityZHHeroRaceList = self._uiActivityZHHeroRaceList
    if uiActivityZHHeroRaceList then
        local uiList = uiActivityZHHeroRaceList:GetList()
        uiList:RefreshList()
    end
end

function UISubMirrorYell:OnClickRankBtnFunc()
    GF.OpenWndBottom("UIRain", { rankType = ModelRank.RANK_TYPE_CALL })

    local callName = gModelCallHero:GetCallWndName()
    GF.CloseWndByName(callName)
end

function UISubMirrorYell:RunHeroShowAni(trans)
    local aniKey = trans:GetInstanceID()
    local formPos = trans.localPosition
    local toPos = formPos:Clone()
    toPos.y = toPos.y + 30
    local time = self:GetRandomSuspendTime()
    self:TweenSeq_Suspend(aniKey, trans, formPos, toPos, time, nil, Tweening.Ease.InOutFlash, true)
end

function UISubMirrorYell:OnActivityConfigData(data, sid)
    if self._getActWebDataSid ~= sid then
        return
    end
    self._getActWebDataSid = nil
    self._activityDataList = nil
    self:RefreshCallTypeBtnStatus()
    self._sendMsg = false
end

function UISubMirrorYell:CreateShowHeroLiHui()
    self:CreateWndSpine(self.mLiHuiPos, "LH_Tuzi02")
end

function UISubMirrorYell:RefreshAdBtnShow()
    self:RefreshAdBtnInfo({
        btnTrans = self.mBtnAd,
        btnTxt = self.mAdBtnName,
        redPoint = self.mAdRedPoint,
    },{
        adMethodId = adMethodId,
        refId = self._callRefId,
        textId = 47101,
    })
end

function UISubMirrorYell:CreateActTimer(key, timeBgTrans, timeTxtTrans, endTime)
    if not self._actTimerList then
        self._actTimerList = {}
    end
    self:ClearActTimer(key)
    self:CreateActCountDown(key, timeBgTrans, timeTxtTrans, endTime)
    self._actTimerList[key] = LxTimer.LoopTimeCall(function()
        self:CreateActCountDown(key, timeBgTrans, timeTxtTrans, endTime)
    end, 1, false, -1)
end

function UISubMirrorYell:OnClickLogBtnFunc()
    GF.OpenWnd("UIYellLog", { callType = self._page })
end

------------------------------------------------------------------
return UISubMirrorYell