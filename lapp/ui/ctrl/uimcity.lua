---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class  UIMCity:LWnd
local UIMCity = LxWndClass("UIMCity", LWnd)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local typeofRectTransform = typeof(CS.RectTransform)
local Tweening = DG.Tweening
local EaseOutCubic = Tweening.Ease.OutCubic
local EaseInCubic = Tweening.Ease.InCubic
local YXTouchManager = CS.YXTouchManager
local YXUIPointUtil = CS.YXUIPointUtil
local typeofRenderer = typeof(UnityEngine.Renderer)
local YXUIClickListener = CS.YXUIClickListener
local typeVerticalLayoutGroup = typeof(UnityEngine.UI.VerticalLayoutGroup)

UIMCity.ACTIVITY_FUN = 10400000 --内置活动功能

--UIMCity.POPUPGIFT = 1		--弹窗礼包
UIMCity.FIRSTPAY = 2          --首充活动
UIMCity.QUESTIONNAIRE = 3     --调查问卷
UIMCity.TENCALL = 4           --十连抽
UIMCity.ACTIVITY_CALLHERO = 7 --活动召唤


local BTN_COMBAT_INDEX = 6 --战斗按钮下标


-----------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMCity:UIMCity()
    self._delayOnlineReqCountDownKey = "_delayOnlineReqCountDownKey"
    self._giftCountDownKey = "giftCountDownKey"
    self._giftTweenKey = "giftTweenKey"
    self._giftCurTweenKey = "giftCurTweenKey"
    self._giftCurEndTweenKey = "giftCurEndTweenKey"
    self._characterRedTimeKey = "_characterRedTimeKey"
    self._enjoyMonthCardTimeKey = "_enjoyMonthCardTimeKey"
    self._enjoyMonthCardSeqKey = "_enjoyMonthCardSeqKey"
    self._enjoyMonthCardEff = "fx_ui_tubiaorukou"
    self._giftIndex = 0
    self._giftTime = 1
    self._uiEasyLists = {}
    self._specialActivtyListKey = "SpecialActivtyList"

    self._giftTimeTransList = {}
    self._giftInfoList = {}
    self._uiHyperList = {}
    self._tsDesKey = "_tsDesKey"
    self._oneWelfareKey = "_oneWelfareKey"
    self._oneWelfareSeqKey = "_oneWelfareSeqKey"
    self._oneWelfareEff = "fx_yiyuanfuli"
    self._nameMoveSeqKey = "_nameMoveSeqKey"
    self._nameMoveTimeKey = "_nameMoveTimeKey"
    self._layoutNameTextPath = "NameText"
    self._layoutNameTextPathEn = "NameMask/NameText"

    self._merchantTimerKey = "_merchantTimerKey"
    self._merchantSeqKey = "_merchantSeqKey"
    self._merchantImgSeqKey = "_merchantImgSeqKey"
    self._merchantEff = "fx_yiyuanfuli"

    self._OffLineReqSid = nil

    self._chatAniKey = "_chatAniKey"

    local lime = gModelChat:GetChatConfigRefByKey("floatWindowAutoFold")
    self._chatInitTime = lime
    self._chatCutTimeKey = "_chatCutTimeKey"
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMCity:OnWndClose()
    if self._seqCom then
        self._seqCom:Destroy()
        self._seqCom = nil
    end
    self:ClearCommonIconList(self._uiEasyLists)
    self:ReleaseTouchEvent()
    self:ClearCommonIconList(self._uiHyperList)
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMCity:OnCreate()
    LWnd.OnCreate(self)

    self._seqCom = SequenceCom:New()
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMCity:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isForeign = gLGameLanguage:IsSEALngRegion() or gLGameLanguage:IsAmericaRegion() or gLGameLanguage:IsVietnamRegion() or gLGameLanguage:IsJapanRegion()

    if self._isForeign then
        CS.ShowObject(self.mGradeAwardTitle_Bg, false)
    end

    self.isTishen = gLGameLanguage:IsHmtRegion() and PRODUCT_G_VER and PRODUCT_G_VER ~= 0
    if self.isTishen then
        CS.ShowObject(self.mOutskirtsBtn, false)
        CS.ShowObject(self.mHomesBtn, false)
        CS.ShowObject(self.mActivitiesBtn, false)
        local setImg = function(tran, path)
            local image = self:FindWndTrans(tran, "Image")
            self:SetWndEasyImage(image, path)
        end
        setImg(self.mCityImage, "mainui_btn_1_ios")
        setImg(self.mPartnersImage, "mainui_btn_3_ios")
        setImg(self.mAdventuresImage, "mainui_btn_6_ios")
    end
    self.jpj = gLGameLanguage:IsJapanVersion()
    if self.jpj then
        local text = self:FindWndTrans(self.mCityImage, "UIText")
        local selectText = self:FindWndTrans(self.mCityImage, "UIText_Select")
        local UIText_Lock = self:FindWndTrans(self.mCityImage, "UIText_Lock")
        self:InitTextCharacterWithLanguage(text, -10)
        self:InitTextCharacterWithLanguage(selectText, -20)
        self:InitTextCharacterWithLanguage(UIText_Lock, -10)

    end
    self:InitData()
    self:InitEvent()
    self:InitMsg()
    self:InitMainEntrace()

    self:InitTopShow()
    self:RefreshEffBtnList()

    self:SetStaticContent()
    self:InitCommand()
    self:RefreshActivityList()

    local firstIndex = LMainBtnIndexConst.CITY
    local map = GF.GetCurMap()
    if map and map:IsSameMap("LFightIdleMap") then
        firstIndex = LMainBtnIndexConst.ADVENTURE
    end
    self:ChangeCurBtn(firstIndex)

    if not self.isTishen then
        self:CreateFightBtnEff()
    end

    self:RefreshFightBtnEffect()

    self:CheckInStoryVisible()

    self:RefreshHeadRed()

    self:InitTouchEvent()

    gModelGuide:RecordOperTime()
    self:DelayShowFinger()

    self:RefreshStrongShow()

    self:VersionRefresh()
    self:RefreshLngVersion()
    self:ShowBulletin()
    self:IsShowWndAssistBtn()
    -- self:ShowEnjoyMonthCard(true)
    -- self:ShowOneWelfare(true)
    self:ShowMerchant(true)

    self:InitResultPart()

    self:UpdateShow(true)

    gLGameUI:ChangeMainCityShow()

    self:TimerStart(self._actCountDownKey, 1, false, -1)
    self:RefreshGardenInteractRed()
    self:RefreshLinkPetRed()

    gModelFunctionOpen:OpenForeshowPop()

    --刷新下聊天窗的部分
    self:InitSizeDelta()
    self:SetChatAirPop()
    self:SetChatAirPopDrag()

    --开始聊天的倒计时
    self._chatStarCutTime = 0
    self:TimerStop(self._chatCutTimeKey)
    self:TimerStart(self._chatCutTimeKey, 1, false, -1)
    self:SetUnreadMsgRP()
    self:RefreshWebIconInfo()
end

function UIMCity:InitResultPart()
    self._rPosList = {
        [1] = Vector3.New(0, -114, 0),
        [2] = Vector3.New(0, 0, 0),
        [3] = Vector3.New(0, 114, 0),
        [4] = Vector3.New(464, -114, 0),
    }

    self._objPool = UIObjPool:New()
    self._objPool:Create(self.mUnuse, self.mRTemplate)

    self:WndEventRecv(EventNames.RESULT_LITTLE_TIP, function(...)
        self:ReceiveResultData(...)
    end)
end

function UIMCity:ShowSpecialActivityScrollUI(show)
    self._isShowSpecialActivtyScroll = show
    -- local haveMiniGame = false
    -- local specialShowActList = gModelActivity:GetMainCitySpecialShowActs()
    -- for k, v in ipairs(specialShowActList) do
    --     if v.model == ModelActivity.MODEL_GAME_TYPE_DOG then
    --         haveMiniGame = true
    --         break
    --     end
    -- end

    local isShowMainTop = gModelFunctionOpen:CheckShowMainTop()

    local isShow = isShowMainTop
    -- if haveMiniGame then
    --     isShow = true
    -- else
    -- isShow = isShowMainTop
    -- end

    CS.ShowObject(self.mSpecialActivtyScroll, show and isShow)
    self:RefreshMainEntrace()

    --除小游戏外，其他活动节点都随正常活动开放显示流程
    -- self:ShowSpecialActivityExcludeMiniGame(show and isShowMainTop)
end

--更新聊天外围的红点
function UIMCity:UpdateMsgBtnRedPoing()
    local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
    if not sensitive then
        return
    end
    local channelList = gModelChat:GetChannelRed()
    local redChannelList = {
        ["8"] = ModelChat.CHANNEL_SYSTEM,
        ["9"] = ModelChat.CHANNEL_PROVINCE,
        ["10"] = ModelChat.CHANNEL_SERVE,
        ["11"] = ModelChat.CHANNEL_CHILD_29,
        ["12"] = ModelChat.CHANNEL_WORLD,
        ["13"] = ModelChat.CHANNEL_GUILD,
        ["14"] = ModelChat.CHANNEL_PRIVATE,
    }
    local showRedList = {}

    for k, v in pairs(redChannelList) do
        showRedList[v] = gModelChat:GetChatSetValue(tonumber(k))
    end

    local redNum = 0
    for i, v in pairs(channelList) do
        if showRedList[i] then
            local bool = gModelChat:GetChatChannelIsOpent(i, 1, false)
            if bool then
                redNum = redNum + v
            end
        end
    end
    local bool = gModelChat:GetChatChannelIsOpent(ModelChat.CHANNEL_PRIVATE, 1, false)
    if bool then
        local list = gModelChat:GetPrivateChannelList()
        for i, v in pairs(list) do
            redNum = redNum + v
        end
    end

    CS.ShowObject(self.mRedImage, redNum > 0)
end

function UIMCity:CreateHeadIcon()
    local baseClass = self._headBaseClass
    local playerInfo = self:GetPlayerInfo()
    if baseClass then
        baseClass:SetHeadData(playerInfo)
        baseClass:RefreshUI()
    else
        baseClass = HeadIcon:New(self)
        baseClass:SetHeadData(playerInfo)
        baseClass:RefreshUI()
        self._headBaseClass = baseClass
    end
end

function UIMCity:OnSdkGetSceneEntryInfoResult(isOk,sceneEnum)
    self:RefreshWebIconInfo()
end

function UIMCity:RefreshLngVersion()
    if gLGameLanguage:IsJapanRegion() then
        return
    end

    if self._isForeign then
        self:SetWndTextMat(self.mLvNum,"NarkisimMJ_000000_1")
        return
    end

    self:InitTextSizeWithLanguage(self.mPowerNum, 6)
    self:InitTextSizeWithLanguage(self.mMasonryNum, 6)
    self:InitTextSizeWithLanguage(self.mGoldNum, 6)
    self:InitTextSizeWithLanguage(self.mLvNum, 6)

end

function UIMCity:MoveRoot(index)
    if index == UIMCity.MOVE_CENTER then
        return
    end
    --index 为 左1  右-1    --刷新index
    self:RefreshCurSelectPageWhenMove(index)
    --刷新列表数据
    self:CalculateDataList()
    --刷新位置
    self:RetSetRootPos()
    self:UpDataItem()
    self:RefreshPoint()
end

function UIMCity:ShowBottom(b)
    CS.ShowObject(self.mMainBottom, b)
end

function UIMCity:SetGiftCountDownTime()
    local _giftTimeTransList = self._giftTimeTransList or {}
    local _giftInfoList = self._giftInfoList or {}

    self:SetTime(_giftTimeTransList[0], _giftInfoList[0], 0)

    local giftInfo = _giftInfoList[1]
    if giftInfo and giftInfo.sid and giftInfo.sid > 0 then
        local activityData = gModelActivity:GetActivityBySid(giftInfo.sid)
        if activityData and activityData.status ~= ModelActivity.STATUS_NO_SHOW then
            local endTime = giftInfo.endTime
            local activityTime = activityData.endTime * 1000
            if activityTime < endTime then
                if not self._initGiftInfoTime then
                    if LOG_INFO_ENABLED then
                        printInfoNR2("礼包时间打印：", "因活动时间小于弹窗礼包条目所有的时间，即结束时间使用活动时间")
                    end
                    self._initGiftInfoTime = true
                end
                giftInfo = {
                    endTime = activityTime,
                    sid = giftInfo.sid,
                }
            end
        end
    end
    self:SetTime(_giftTimeTransList[1], giftInfo, 1)

    --设置第三个时间嘛
    giftInfo = _giftInfoList[2]
    self:SetTime(_giftTimeTransList[2], giftInfo, 2)

    if not _giftInfoList[0] and not _giftInfoList[1] and not _giftInfoList[2] then
        self:TimerStop(self._giftCountDownKey)
    end
end

function UIMCity:IsOpent()
    self._isShowAir = true
    local isAir = false
    local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)

    if sensitive then
        local _bool = gModelFunctionOpen:CheckIsOpened(11700010, false)

        if _bool then
            isAir = gModelChat:GetChatSetValue(7)
            --local chatSetServerList = LPlayerPrefs.chatSetServerList or ""
            --local arr = string.split(chatSetServerList,"|")
            --for i, v in ipairs(arr) do
            --	local as = string.split(v,"=")
            --	if as[1] == "7" and as[2] == "1" then
            --		isAir = true
            --	end
            --end
        end
    end

    --printInfoN("cjh------updateshow---6.."..not isAir)
    --CS.ShowObject(self.mChatAirPop,isAir)
    CS.ShowObject(self.mChatAirPop, not isAir)
    CS.ShowObject(self.mChatBtn, not isAir)
    CS.ShowObject(self.mChatAirPopOptBtn, false)
    CS.ShowObject(self.mChatBtnRoot, not isAir)
end

function UIMCity:ChangeWhatever(index, extraWnds)
    local changeSuc, wndOpenName = self._bottomBtnFunc[index]()
    if not changeSuc then
        return
    end
    self:ChangeCurBtn(index)

    extraWnds = extraWnds or {}
    if wndOpenName then
        extraWnds[wndOpenName] = true
    end
    self:OnSwitchToOther(index, extraWnds)
end

function UIMCity:AutoMoveRoot(moveType, nextFunc)
    local itemRoot = self.mItemRoot
    if not CS.IsValidObject(itemRoot) then
        return
    end
    self._bMove = true

    local moveX
    if moveType == UIMCity.MOVE_RIGHT then
        --自动右移一页
        moveX = self._changeDistanceX
    elseif moveType == UIMCity.MOVE_LEFT then
        --自动左移一页
        moveX = -self._changeDistanceX
    else
        --复位到原页
        moveX = 0
    end

    local seqTween
    self:TweenSeqKill(self._autoMoveKey)
    if not seqTween then
        seqTween = self:TweenSeqCreate(self._autoMoveKey, function(seq)
            if CS.IsValidObject(self.mItemRoot) then
                local vec = Vector2.New(moveX, self.mItemRoot.localPosition.y)
                local tweener = self.mItemRoot:DOLocalMove(vec, self._moveTime)
                seq:Join(tweener)
            end
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(self._autoMoveKey)
        self:MoveRoot(moveType)
        self._bMove = false
        -- 刷新item
        self:RetSetRootPos()
        self:StartScroll()
        if nextFunc then
            --给移动两格使用
            nextFunc()
        end
    end)
end

function UIMCity:RefreshSpecialActivtyScrollPos()
    local show = self.mGradeSpine.gameObject.activeSelf
    local pos = self._initSpecialActivtyScrollPos
    if not show then
        pos = self.mGradeRoot.anchoredPosition
    end
    self.mSpecialActivtyScroll.anchoredPosition = pos
end

function UIMCity:OnClickActState()
    local isOn = gModelActivity:IsMoreListShow()
    local newValue = not isOn
    local saveV = newValue and 1 or 0
    LPlayerPrefs.SetShowMoreList(saveV)

    self:ShowActivityList(true)

    self:TweenMoreList(isOn)
    self:RefreshMainEntrace()
end

function UIMCity:SetOneWelfareCD()
    -- local durationTime = self._oneWelfareEndTime - GetTimestamp()
    -- if durationTime <= 0 then
    --     self:ShowOneWelfare(false)
    --     return
    -- end

    -- local timeStr = LUtil.FormatTimespanCn(durationTime, { hTextId = 10371 })
    -- self:SetWndText(self.mOneWelfareTimeText, timeStr)
end

function UIMCity:ShowBottomUI(show)
    if PRODUCT_G_VER ~= 0 and show then
        if gLGameLanguage:CheckIsUseSpecialProduct() then
            local packId = gLGameLanguage:GetPackProductInfo()
            show = gLGameLanguage:GetMainCityAllBottomShowOrHide(packId)
        end
    end

    self._isShowBottom = show
    local isShow = gModelFunctionOpen:CheckShowMainTop()
    CS.ShowObject(self.mMainBottom, show and isShow)
end

function UIMCity:ShowTopUI(show)
    self._isShowTop = show

    local isShow = gModelFunctionOpen:CheckShowMainTop()
    CS.ShowObject(self.mMainTop, show and isShow)
end

function UIMCity:NoticeListItem(list, item, itemdata, itempos)
    local Image = self:FindWndTrans(item, "Image")
    local ImageIcon = self:FindWndTrans(Image, "Icon")
    local IconEff = self:FindWndTrans(ImageIcon, "Eff")
    local ImageNameText = self:FindWndTrans(Image, "NameText")
    local ImageTimeText = self:FindWndTrans(Image, "TimeText")
    local ImageExtraBg = self:FindWndTrans(Image, "extraBg")
    local extraBgExtraText = self:FindWndTrans(ImageExtraBg, "extraText")
    local ImageRedPoint = self:FindWndTrans(Image, "redPoint")

    local ref = itemdata.ref
    local refId = itemdata.refId

    local showRed = false
    CS.ShowObject(ImageExtraBg, false)
    self:CreateWndEffect(IconEff, "fx_ui_dianfengsai", "notice" .. itempos, 100)
    local timeDes = ccLngText(itemdata.des)
    local onClickFun = nil
    if (refId == ModelGeneral.NOTICE_ENDLES) then
        onClickFun = function()
            local combatData = gModelEndles:FormatEndlessCombatData()
            if not combatData then
                return
            end
            combatData.isBattleToBackground = true
            GF.OpenWnd("UIUendBfPop", { combatData = combatData })
        end
    elseif (refId == ModelGeneral.NOTICE_MELEE) then
        local state = itemdata.state
        local jump
        if (state == 3) then
            timeDes = timeDes
            jump = ref.activityFunction
        elseif (state == 4 or state == 5) then
            timeDes = ccLngText(ref.des2)
            jump = ref.activityFunction2
        else
            local time = LUtil.OSDate("%H:%M:%S", itemdata.time)
            timeDes = string.replace(ccClientText(17700), time)
            jump = ref.foreshowFunction
        end
        onClickFun = function()
            if ModelGuild:GetBHaveGuild() then
                gModelFunctionOpen:Jump(jump)
            else
                gModelFunctionOpen:Jump(12100000)
                --GF.OpenWndBottom("UIGdSeekPop")
                GF.ShowMessage(ccClientText(17969))
            end
        end
    elseif refId == ModelGeneral.NOTICE_SIMULATE then
        showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.SIMU_MAIN)

        local isInterOpen = gModelSimuFight:IsInteractiveOpen()
        CS.ShowObject(ImageExtraBg, isInterOpen)
        self:SetWndText(extraBgExtraText, ccClientText(25327))
        timeDes = gModelSimuFight:GetCurScheduleName()
        timeDes = string.replace(ccClientText(25328), timeDes)
        onClickFun = function()
            gModelFunctionOpen:Jump(ref.foreshowFunction)
        end

        self._simuRedTran = ImageRedPoint
        --elseif refId == ModelGeneral.NOTICE_RACE then
        --    local default = ccLngText(ref.des2)
        --    local _, timeLeft = gModelRaceGame:IsNoticeShow()
        --    if timeLeft then
        --        timeDes = LUtil.FormatTimespanNumber(timeLeft)
        --    else
        --        timeDes = default
        --    end
        --
        --    self._noticeTimeTextMap[refId] = { textTran = ImageTimeText, defaultStr = default }
        --    local jump = ref.foreshowFunction
        --    onClickFun = function()
        --        if gModelFunctionOpen:CheckIsOpened(jump, true) then
        --            gModelFunctionOpen:Jump(jump)
        --        end
        --    end
    elseif refId == ModelGeneral.NOTICE_HELPERLIGHTENING then
        local gameHelperExecuteList = gModelGameHelperAlleviation:GetGameHelperExecuteList()
        local helpStatus = gModelGameHelperAlleviation:GetGameHelperExecuteStatus(gameHelperExecuteList)
        local default = ccLngText(ref.des)
        if helpStatus == ModelGameHelperAlleviation.STATUS_TYPE_END then
            default = ccLngText(ref.des2)
        end
        timeDes = default
        onClickFun = function()
            gModelGameHelperAlleviation:OpenCurExecuteResultWnd()
        end
    else
        local jump
        if (itemdata.state == 1) then
            local time = LUtil.OSDate("%H:%M:%S", itemdata.time)
            timeDes = string.replace(ccClientText(17700), time)
            jump = ref.foreshowFunction
        else
            jump = ref.activityFunction
        end
        onClickFun = function()
            if gModelFunctionOpen:CheckIsOpened(jump, true) then
                gModelFunctionOpen:Jump(jump)
            end
        end
    end
    self:SetWndEasyImage(Image, ref.cellImage)
    self:SetWndEasyImage(ImageIcon, ref.icon)
    self:SetWndText(ImageNameText, ccLngText(ref.name))
    self:SetWndText(ImageTimeText, timeDes)
    self:SetWndClick(item, function()
        if (onClickFun) then
            onClickFun()
        end
    end)

    CS.ShowObject(ImageRedPoint, showRed)
end

function UIMCity:GetCharacterRedPointState()
    if not self:IsWndValid() then
        return
    end

    self._nextRefreshCharacterRedTime = GetTimestamp() + 300
    self:StopCharacterRedPointStateTime()
    gLSdkImpl:CallMethod(LSdkMethod.CallSdkMsgReadState)
end

function UIMCity:GetActivityEffType(actData)
    local effType = 1
    -- if actData.model == ModelActivity.MODEL_ACTIVITY_TYPE_4108 or actData.model == ModelActivity.MODEL_ACTIVITY_TYPE_4110 then
    --     effType = 2
    -- end
    return effType
end

function UIMCity:SetGradeSpineAin()
    local dpSpine = self._gradespine
    if not dpSpine or not dpSpine:IsDpValid() then
        return
    end
    local bShow = self._bGradeSpineAin or false

    CS.ShowObject(self.mGradeSpine, bShow)
    self:RefreshSpecialActivtyScrollPos()

    CS.ShowObject(self.mGradeAwards, bShow)

    FireEvent("UpdateGradeBigRewardShow", bShow)

    if not bShow then
        dpSpine:PlayAnimation(0, "idle2", true)
        return
    end
    local isNew, rewardSignRef = gModelGrade:GetCurRewardSignRef()
    if not rewardSignRef then
        CS.ShowObject(self.mGradeSpine, false)
        self:RefreshSpecialActivtyScrollPos()
        CS.ShowObject(self.mGradeAwards, false)
        FireEvent("UpdateGradeBigRewardShow", false)
        return
    end
    self:CreateWndEffect(self.mGradeAwardEff, "fx_daoju_orange", "mGradeAwardEff", 60, false, false)
    dpSpine:PlayAnimation(0, "idle2", true)
    --local itemList = LxDataHelper.ParseItem(isNew and rewardSignRef.rewardUp1 or rewardSignRef.rewardUp)
    local itemList = LxDataHelper.ParseItem(rewardSignRef.rewardUp)
    self:InitItemList("GradeAward", self.mGradeAwardScroll, itemList)
    -- 【G公共支持】删除冒险评级的等级补偿机制
    -- local txt = isNew and rewardSignRef.txt1 or rewardSignRef.txt
    local txt = not isNew and rewardSignRef.txt or ""
    local txtStr = ccLngText(txt)
    if not string.isempty(txtStr) then
        self:SetWndText(self.mTsDesText, txtStr)
        CS.ShowObject(self.mTsDesBg, true)
    else
        CS.ShowObject(self.mTsDesBg, false)
    end

    --顺便设置下大奖预告
    self:SetWndText(self.mGradeAwardTitle, ccClientText(13438))
end

function UIMCity:RefreshLinkPetRed()
    --連接寵物红点
    local isShow = gModelPet:HeroLinkPetRed()
    gModelRedPoint:ShowPointRed(ModelRedPoint.MAINCITY_HERO_PET, isShow)
end

function UIMCity:MirageChallengeCD(item, itemdata)
    local sid = itemdata.actData.sid
    local actData = gModelActivity:GetActivityBySid(sid)
    if not actData then
        return
    end
    if not CS.IsValidObject(item) then
        return
    end
    local dynamicData = actData:GetMoreInfo()
    if not dynamicData or not dynamicData.nextRoundTime then
        return
    end
    local nextRoundTime = dynamicData.nextRoundTime / 1000
    local curTime = nextRoundTime - GetTimestamp()
    self:CommonSetTimeText(item, curTime)
end

function UIMCity:RefreshHeadRed()
    local bool = gModelPlayerSpace:GetTodayZoneRed()
    --local level = gModelPlayer:GetRoleConfigRefByKey("level") or 20
    --local playerLv = gModelPlayer:GetPlayerLv()
    local isopen = gModelFunctionOpen:CheckIsOpened(15000010)

    --CS.ShowObject(self.mHeadRedPoint, bool and playerLv >= level)
    CS.ShowObject(self.mHeadRedPoint, bool and isopen)
end

function UIMCity:OnClickMasonryBuyBtn()
    --if gLGameLanguage:IsChinaRegion() and CS.IsWebGL() and LWxHelper.IsMiniGamePlatform() then
    --    if PRODUCT_G_VER ~= 0 then
    --        return
    --    end
    --end
    if gLSdkImpl and gLSdkImpl:CallMethod(LSdkMethod.IsProductBlockRecharging) then
        return
    end

    gLxTKData:OnUIBtnClick("UIHuiYPay")
    local wndInst = GF.FindFirstWndByName("UIHuiYPay")
    if wndInst then
        return
    end
    GF.OpenWndBottom("UIHuiYPay", { page = 2 })
end

function UIMCity:CommonSetTimeText(item, timeLeft, showTimeStr, showTime2)
    local layoutRoot = self:GetCommonLayerTrans(item)

    local layoutTimeBg = self:FindWndTrans(layoutRoot, "TimeBg")
    local TimeBgTimeText = self:FindWndTrans(layoutTimeBg, "TimeText")
    local timeText2 = self:FindWndTrans(item, "TimeText2")

    local timeStr = LUtil.FormatTimespanCn(timeLeft, { hTextId = 10371 })

    CS.ShowObject(layoutRoot, not showTime2)
    CS.ShowObject(timeText2, showTime2)
    if not showTime2 then
        self:SetWndText(TimeBgTimeText, showTimeStr or timeStr)
        if (not layoutTimeBg.gameObject.activeSelf) then
            CS.ShowObject(layoutTimeBg, true)
        end
    else
        self:SetWndText(timeText2, showTimeStr or timeStr)
    end

    if gLGameLanguage:IsJapanRegion() then
        self:InitTextSizeWithLanguage(TimeBgTimeText, -2)
        self:SetWndInputLimit(TimeBgTimeText, -10)
        self:SetWndInputLimit(timeText2, -10)
    end
end

function UIMCity:ChangeCurBtn(index)
    if PRODUCT_G_VER ~= 0 then
        if gLGameLanguage:CheckIsUseSpecialProduct() then
            local packId = gLGameLanguage:GetPackProductInfo()
            if packId == 1 then

            elseif packId == 2 then
            elseif packId == 3 then
                --这里屏蔽下面
                --self:ShowBottom(false)
                --打开页面
                --GF.OpenWnd("UIOuttsList", { listRefId = 10101 })
                return
            end
        end
    end

    local lastIndex = self._lastBotBtnIndex

    if lastIndex == -1 then
        for k, v in ipairs(self._btnImgList) do
            self:ShowBtnDeSelect(k)
        end
    else
        self:ShowBtnDeSelect(lastIndex)
    end

    self._lastBotBtnIndex = index
    FireEvent(EventNames.ON_CHANGE_MAIN_BTN, index)

    self:ShowTrans(self._btnBgList[index], true)
    local root = self._btnImgList[index]
    if root then
        local text = self:FindWndTrans(root, "UIText")

        local selectText = self:FindWndTrans(root, "UIText_Select")
        local str = self._btnStrs[index]
        --str = LUtil.FormatColorStr(str, "#ffffff")
        self:SetWndText(text, str)
        self:SetWndText(selectText, str)

        self:ShowTrans(text, false)
        self:ShowTrans(selectText, true)

    end
    if lastIndex > 0 then
        self:RefreshFightBtnEffect()
    end

    gModelGeneral:CheckShowIgnoredPopGift()
    if index == 1 then
        -- self:ShowOneWelfare(true, true)--回到主城显示广告
        self:ShowMerchant(true) --回到主城显示广告
    end
    self:RefreshMainEntrace()
    self:RefreshFuncPreView()
end

function UIMCity:IsCurBtn(index)
    if self._lastBotBtnIndex == index then
        return true
    end
    return false
end

function UIMCity:DelayShowFinger()
    self:TimerStop(self._delayShowFinger)
    self:TimerStart(self._delayShowFinger, 1, false, -1)
end

--endregion --------------------------------------------------------------------------------------

--region 主界面下方区域的初始化和效果方法 --------------------------------------------------------------------------------
function UIMCity:InitBottomData()
    self._lastBotBtnIndex = -1

    self._isShowInCity = true

    self._btnBgList = {
        self.mCityImageBg,
        self.mOutskirtsBg,
        self.mHomesBg,
        self.mPartnersBg,
        self.mActivitiesBg,
        self.mAdventuresBg,
    }
    self._btnImgList = {
        self.mCityImage,
        self.mOutskirtsImage,
        self.mHomesImage,
        self.mPartnersImage,
        self.mActivitiesImage,
        self.mAdventuresImage,
    }

    self._adventuresImageIcon = self:FindWndTrans(self.mAdventuresImage, "Image")

    self._btnSoundList = {
        LSoundConst.CLICK_MAINBTN_CITY,
        LSoundConst.CLICK_MAINBTN_SUBURB,
        LSoundConst.CLICK_MAINBTN_HERO,
        LSoundConst.CLICK_BUTTON_COMMON,
        LSoundConst.CLICK_BUTTON_COMMON,
        LSoundConst.CLICK_MAINBTN_ADVENTURE, }

    --点击之后要载入的地图的资源
    self._mapList = {
        "LCityMap",
        "LCityMap",
        "LCityMap",
        "LCityMap",
        "LCityMap",
        "LFightIdleMap", } -- 载入地图资源

    --对应按钮点击时 期望打开并且不关闭的页面
    self._exceptWnd = {
        [2] = { "UIOutts", "UISubOuttsPvpEnter", "UISubOuttsPvEEnter" },
        [3] = { "UIGenWin", "UISubVideoEntrance" },
        [4] = { "UISaga" },
        [5] = { "UIAct" },
        [6] = { "UIMinFight" },
        --[4] = { "WndPet" },
        --[4] = { "UIGdWin", "UIGdSeekPop", "UIGdSeekPopEn", },
    }

    if gLGameLanguage:IsJapanRegion() then
        if PRODUCT_G_VER ~= 0 then
            local isIos = true
            if isIos then
                self._exceptWnd[3] = { "UIOutts", "UISubOuttsPvpEnter", "UISubOuttsPvEEnter" }
            end
        end
    end

    self._btnStrs = {
        ccClientText(13410), --"主城",
        ccClientText(13411), --"郊外"),
        ccClientText(13426), --"家园",
        ccClientText(13412), --"伙伴",

        ccClientText(13414), --"活动",
        ccClientText(13413), --"冒险推图",

    }
    -- 拼接请求
    self._taInfos = {
        [1] = "主城",
        [2] = "郊外",
        [3] = "家园",
        [4] = "伙伴",
        [5] = "活动",
        [6] = "冒险推图",
    }



    --底部按钮的方法
    self._bottomBtnFunc = {
        function()
            return self:OnClickMainCity()
        end,
        function()
            return self:OnClickOutskirts()
        end,
        function()
            return self:OnClickHomes()
        end,
        function()
            return self:OnClickPartners()
        end,

        function()
            return self:OnClickActivity()
        end,
        function()
            return self:OnClickAdventures()
        end,
    }

    --按钮对应的功能id
    self._bottomFuncId = {
        [1] = 10000000,
        [2] = 10000020,
        [3] = 21000000,
        [4] = 10300000,
        [5] = 10400000,
        [6] = 10200000,
    }

    if self._isForeign then
        self:AdjustBottomBtnLockText()
    end
end

function UIMCity:OnClickPartners()
    GF.ChangeMap("LCityMap", true)
    GF.OpenWndBottom("UISaga")

    if LOG_INFO_ENABLED then
        printInfoN("cjh-------点完了 伙伴按钮 我的页面呢")
    end
    return true
end

-- function UIMCity:ShowSpecialActivityExcludeMiniGame(isShow)
--     local activityList = self._activityItemList[self._specialActivtyListKey]
--     if not activityList then
--         return
--     end
--     local isShowAct
--     for k, v in pairs(activityList) do
--         local item = v
--         -- local itemdata = k
--         -- local actData = itemdata.actData
--         -- if actData then
--             -- local actModel = actData.model
--             -- if actModel == ModelActivity.MODEL_GAME_TYPE_DOG then
--             --     isShowAct = true
--             -- else
--                 isShowAct = isShow
--             -- end
--         -- end
--         CS.ShowObject(item, isShow)
--     end
-- end

function UIMCity:ShowUIMCityTop(bShow)
    local MainTopRight = CS.FindTrans(self._wndTrans, "MainTopRight")
    if MainTopRight then
        CS.ShowObject(MainTopRight, bShow)
    end
end

--创建聊天的子项目
function UIMCity:MsgListItem(list, item, itemdata, itempos)
    local InstanceID = item:GetInstanceID()
    local image = self:FindWndTrans(item, "Image")
    local msgText = self:FindWndTrans(item, "MsgText")
    local faceImg = self:FindWndTrans(item, "FaceImg")
    local faceSpine = self:FindWndTrans(item, "FaceSpine")
    local playerIcon = self:FindWndTrans(item, "PlayerImg")

    CS.ShowObject(faceImg, false)
    CS.ShowObject(faceSpine, false)
    local ref = gModelChat:GetChatChannelRefByChannelId(itemdata.channel)
    local playerName = itemdata.playerName
    if itemdata.sex == 1 then
        playerName = LUtil.FormatColorStr(playerName, "blue")
    elseif itemdata.sex == 0 then
        playerName = LUtil.FormatColorStr(playerName, "purple")
    end
    local msgPot = string.replace(ccClientText(11150), ccLngText(ref.channel), playerName)
    --local msgPot = ccLngText(ref.channel)..playerName
    --local channelStr = "["..ccLngText(ref.channel).."]"
    --self:SetWndText(self.mTestText2,channelStr)
    --local uiText = LxUiHelper.FindXTextCtrl(self.mTestText2)
    --local posX = uiText.preferredWidth

    self:SetWndText(self.mTestText2, msgPot)
    local uiText = LxUiHelper.FindXTextCtrl(self.mTestText2)
    local preferredWidth = uiText.preferredWidth + 10
    --playerIcon.sizeDelta = Vector2(preferredWidth - posX,20)
    --playerIcon.anchoredPosition = Vector2.New(posX,0)

    --self:SetWndClick(playerIcon,function ()self:OnClickChatAirBg() end)
    self:SetWndClick(image, function()
        self:OnClickChatAirBg()
    end)

    self:SetWndClick(msgText, function()
        self:OnClickChatAirBg()
    end)

    local msg = itemdata:GetMsg()
    if (itemdata.type == ModelChat.MSGTYPE_GUILDNOTICE or itemdata.channel == ModelChat.CHANNEL_SYSTEM or itemdata.type == ModelChat.MSGTYPE_NOTICE) then
        msg = gModelChat:SetChatSkipFun(msgText, InstanceID, itemdata, msg, self._uiHyperList, "")
    else
        msg = self:SetATPlayerName(msg, itemdata.atPlayerName)
        local faceId = LUtil.ChatInfoGetDaFace(msg)
        if (faceId > 0) then
            --大表情改成显示替代的文字
            self:SetWndText(msgText, msgPot .. ccClientText(11163))
            LxUiHelper.SetSizeWithCurAnchor(item, 1, 23)
            --self:SetWndText(msgText, msgPot)
            --self:SetBigFace(item, faceId, InstanceID, preferredWidth)
            return
        end
        msg = LUtil.GetFaceStr(msg, 18)
        local isShare, shareInfo = gModelChat:SetShareType(itemdata, msg)
        if isShare then
            msg = gModelChat:OnAddHyper(msgText, InstanceID, shareInfo, self._uiHyperList, function()
                self:OnClickChatAirBg()
            end)
        else
            msg = shareInfo
        end
    end
    local msgStr = msgPot .. " " .. msg
    self:SetWndText(self.mTestText, msgStr)
    local uiText = LxUiHelper.FindXTextCtrl(self.mTestText)
    local height = uiText.preferredHeight
    self:SetWndText(msgText, msgStr)
    --local desuiText = LxUiHelper.FindXTextCtrl(msgText)
    --local height = desuiText.preferredHeight
    height = 23
    LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
end

function UIMCity:OnGuideEnd()
    if gModelNotice:CheckNeedWaitGameNotice() and gModelGuide:IsAllowPopWnd() then
        self:ShowBulletin()
    end

    CS.ShowObject(self.mResultPart, true)
end

function UIMCity:GetActTitle(itemdata)
    local actData = itemdata.actData
    if not actData then
        return
    end
    local actModel = actData.model
    if actModel == ModelActivity.PRIVILEGE_SHOP then
        local showAct = gModelActivity:CheckPermanentPrivilege()
        if showAct == 1 then
            return gModelNormalActivity:GetBIActivityConfigRefByKey("permanentIconText")
        end
    end
end

function UIMCity:InitSizeDelta()
    local width, height
    local bWidth, bHeight
    local btnRect = self.mChatBtn:GetComponent(typeofRectTransform)
    if btnRect then
        bWidth, bHeight = btnRect.sizeDelta.x / 2, btnRect.sizeDelta.y / 2 + 10
    end
    local rect = self.mScope:GetComponent(typeofRectTransform)
    if rect then
        width, height = rect.rect.width / 2, rect.rect.height / 2
    end
    self._maxX = (width or 320) - bWidth
    self._maxY = (height or 438) - bHeight
    self._btnX = self.mChatBtnRoot.localPosition.x
end

function UIMCity:RefreshItemChangeAct()
    local recordActKeyMap = self._recordActKeyMap
    if not recordActKeyMap then return end

    for key,root in pairs(recordActKeyMap) do
        local uiItemList = self:FindUIScroll(key)
        if uiItemList then
            local uiList = uiItemList:GetList()
            uiList:RefreshList()
        end
    end
end

function UIMCity:ResetRedSortingOrder(tran)
    local curOrder = self:GetWndSortOrder()
    local list = tran:GetComponentsInChildren(typeofRenderer, true)
    local rendererLen = list.Length
    for k = 1, rendererLen do
        local renderer = list[k - 1]
        renderer.sortingOrder = curOrder + 5
    end
end

function UIMCity:OnClickOutskirts()
    --printInfoN("====== 点击了郊外=== 这里暂不知挑转")


    --if true then
    --    GF.OpenWndBottom("UIMicMin")
    --    return
    --end

    local open, msg = gModelFunctionOpen:CheckIsOpened(10000020)
    if open then
        GF.ChangeMap("LCityMap", true)
        GF.OpenWndBottom("UIOutts")
    else
        if msg then
            GF.ShowMessage(msg)
        end
    end

    return true
end

function UIMCity:ShowActNameTextMove()
    for k, v in pairs(self._activityItemList) do
        for k1, v1 in pairs(v) do
            local item = v1
            self:SetActNameTextMove(item)
        end
    end
end

function UIMCity:RefreshSurveyBtn()
    local surveyData = gLSdkImpl:CallMethod(LSdkMethod.GetSurveyData)
    if not gModelFunctionOpen:CheckIsOpened(10010002) then
        surveyData = nil
    end
    if self._surveyData ~= surveyData then
        self._surveyData = surveyData
        self:ShowActivityList()
    end
end

function UIMCity:SetPower()
    local num = gModelPower:GetMainCityPower()
    self._oldPower = tonumber(num)
    --print("=== num = ",num,type(num))
    --num = tonumber(num)
    self:SetWndText(self.mPowerNum, LUtil.PowerNumberCoversion(num))
end

--hurdle 跟多里面的按钮监察
function UIMCity:CheckIsShowHudleTopFunc()
    for k, v in ipairs(self._hudleTopFunc) do
        local isopen = gModelFunctionOpen:CheckIsOpened(v.openid)
        CS.ShowObject(v.trans, isopen)
    end
end

function UIMCity:OnClickMerchantBtn()
    local activityData = gModelActivity:GetSpecialActivity(ModelActivity.MODEL_ACTIVITY_TYPE_901)
    if not activityData then
        return
    end
    GF.OpenWnd("UIDanMerchantPop", { sid = activityData.sid })
    gLxTKData:OnMainUIActivityClick(activityData)
end

function UIMCity:SetDragItemPos(trans, eventData)
    local camera = eventData.pressEventCamera
    local pos = camera:ScreenToWorldPoint(eventData.position)
    pos = trans.parent:InverseTransformPoint(pos)

    local transPos = trans.localPosition

    local x = Mathf.Clamp(pos.x, -self._maxX, self._maxX)
    local y = Mathf.Clamp(pos.y, -self._maxY, self._maxY)

    trans.localPosition = Vector3.New(x, y, transPos.z)
end

-- 点击item
function UIMCity:OnClickItem(index)
    GF.OpenWnd("UIMinEntranceList", { index = index })
end

function UIMCity:Pop3CD(item, itemdata)
    local id = itemdata.actData.sid
    local showGroup = itemdata.actData.showGroup
    local gift = gModelPopupGift:GetSpecialGiftListById(showGroup, id)
    if not gift then
        return
    end
    local time = GetTimestamp()
    local timespan = gift.endTime / 1000 - time
    if timespan <= 0 then
        gModelPopupGift:OnPopupGiftNowListReq()
        return
    end
    self:CommonSetTimeText(item, timespan)
end

function UIMCity:Activity164_1EndTimeCd(item,itemdata)
    local curTime = GetTimestamp()
    local time = LUtil.GetNextDayTimes(curTime,1)
    local timeLeft = time - curTime
    if timeLeft < 0 then
        if time > 0 then
            self:RefreshActivityList()
        end
        return
    end

    if timeLeft < 0 then
        timeLeft = 0
    end

    if not CS.IsValidObject(item) then
        return
    end
    self:CommonSetTimeText(item, timeLeft)
end

function UIMCity:TweenResult()
    local cnt = #self._showResultList
    local index = 1
    for k = cnt, 1, -1 do
        local data = self._showResultList[k]
        data.index = index
        index = index + 1
    end
    self._isResultTweening = true

    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq("moveResult")
    for k, v in ipairs(self._showResultList) do
        local curPos = v.tran.localPosition
        local targetPos = self._rPosList[v.index]
        local dis = Vector3.Distance(curPos, targetPos)
        if dis > 0.01 then
            local tween = YXTween.TweenFloat(0, 1, 0.5, function(t)
                local pos = Vector3.Lerp(curPos, targetPos, t)
                v.tran.localPosition = pos
            end)

            seq:Append(tween)
            if v.isNew then
                v.isNew = false
                local canvasGroup = v.tran:GetComponent(typeofCanvasGroup)
                YXTween.TweenFloat(0, 1, 0.5, function(t)
                    canvasGroup.alpha = t
                end)
                seq:Join(tween)
            end
        end
    end

    seq:OnComplete(function()
        self._isResultTweening = false

        self:CheckWaitResult()
    end)

    seq:PlayForward()
end

function UIMCity:ShowMerchant(isEnable)
    local inMainFight = GF.FindFirstWndByName("UIMinFight")
    local show = not inMainFight and self._isHurdleShow
    isEnable = show and isEnable
    local isShowCard = isEnable
    local durationTime
    if isEnable then
        local isShow, endTime = gModelActivity:CheckMerchantShow()
        isShowCard = isShow
        durationTime = endTime
    end
    CS.ShowObject(self.mMerchantBtn, isShowCard)
    local activityData = gModelActivity:GetSpecialActivity(ModelActivity.MODEL_ACTIVITY_TYPE_901)
    if not activityData then
        return
    end
    local moreInfo = activityData:GetMoreInfo()
    local cityEnterIcon = moreInfo.cityEnterImg
    local cityEnterSpine = moreInfo.cityEnterSpine
    local cityEnterPopupImg = moreInfo.cityEnterPopupImg
    if LxUiHelper.IsImgPathValid(cityEnterIcon) then
        self:SetWndEasyImage(self.mMerchantBtnImg, cityEnterIcon)
    end
    if LxUiHelper.IsImgPathValid(cityEnterPopupImg) then
        self:SetWndEasyImage(self.mMerchantContentImg, cityEnterPopupImg)
    end
    local title = activityData.title
    self:SetWndText(self.mMerchantText, title)
    -- local sid = activityData.sid
    -- local red = gModelActivity:GetSaveRedBySid(sid)
    -- local showRed = gModelRedPoint:CheckActivityShowRed(sid)
    -- CS.ShowObject(self.mOneWelfareRedPoint, showRed or red)
    self:CreateWndSpine(self.mMerchantEff, self._merchantEff, self._merchantEff, 100, function(spine)
        spine:SetRaycastTarget(false)
    end, false)
    if (durationTime) then
        self._merchantEndTime = durationTime
        self:SetMerchantCD()
        self:TimerStart(self._merchantTimerKey, 1, false, durationTime + 3)
    end
    if (gModelMainCity:GetMerchantState()) then
        return
    end
    gModelMainCity:SetMerchantState(true)

    if (cityEnterSpine and not string.isempty(cityEnterSpine)) then
        self:DestroyWndSpineByKey(cityEnterSpine)
        self:CreateWndSpine(self.mMerchantContent, cityEnterSpine, cityEnterSpine, 100, function(spine)
            spine:PlayAnimation(0, cityEnterSpine, false)
            spine:SetAnimationCompleteFunc(function()
                spine:PlayAnimation(0, cityEnterSpine .. "_loop", true)
            end)
        end, false)
    end
    CS.ShowObject(self.mMerchantContent, true)
    CS.ShowObject(self.mMerchantContentContentBtn, true)
    local completeFunc = function()
        CS.ShowObject(self.mMerchantContent, false)
        CS.ShowObject(self.mMerchantContentContentBtn, false)
    end
    self:TweenSeq_FadeInStaysAway(self._merchantSeqKey, self.mMerchantContent,
            { waitTime = 5, completeFunc = completeFunc })
    self:TweenSeq_FadeInStaysAway(self._merchantImgSeqKey, self.mMerchantContentImg,
            { waitTime = 5, completeFunc = completeFunc })
end

function UIMCity:InitItemList(key, awardRoot, itemList)
    local uiIconEasyList = self._uiEasyLists[key]
    if (not uiIconEasyList) then
        uiIconEasyList = UIIconEasyList:New()
        self._uiEasyLists[key] = uiIconEasyList
        uiIconEasyList:Create(self, awardRoot)
        --if key == "GradeAward" then
        uiIconEasyList:SetItemClickFunc(function(item)
            GF.OpenWnd("UIRiskRtWin", { type = 2 })
        end)
        --end
    end
    uiIconEasyList:RefreshList(itemList)
end

--是否显示Hudr区域
function UIMCity:ShowHurdleUI(show)
    self._isHurdleShow = show

    local isShow = gModelFunctionOpen:CheckShowHurdle()
    CS.ShowObject(self.mHurdle, show and isShow)

    local isHideReward = gModelGrade:GetIsHideReward()
    self:IsShowGradeQuest(show and isHideReward)
    local isShowTsBg = show and isHideReward and not self._gradeShow
    -- CS.ShowObject(self.mTsDesBg, isShowTsBg)
    if isShowTsBg and not self._initTsTowee then
        self._initTsTowee = true
        self:SetScaleTowee(self.mTsDesBg, self._tsDesKey)
    end
end

function UIMCity:OnActivityClick(showData)
    printInfoN(string.format("_________maincity act sid %s", showData.actData.sid))
    local model = showData.actData.model
    local func = gModelActivity:GetShowActivityFun(model)
    if func then
        func(showData.actData)
    end
end

function UIMCity:DoMsgTween()
    local tweenSeq = YXTween.TweenSequenceIns()

    --old 的消失部分
    local alphaTime = 0.3
    local moveTime = 0.2

    local canvas_old = self.mText_Old:GetComponent(typeofCanvasGroup)
    local canvas_new = self.mText_New:GetComponent(typeofCanvasGroup)

    local old_alphaTween = canvas_old:DOFade(0, alphaTime):SetEase(DG.Tweening.Ease.InSine)

    --移动部分
    local old_moveTween = self.mText_Old:DOMove(self.mChat_Up.position, moveTime)
    local new_moveTween = self.mText_New:DOMove(self.mChat_Center.position, moveTime)

    tweenSeq:Append(old_alphaTween)
    tweenSeq:Insert(0, old_moveTween)
    tweenSeq:Insert(0, new_moveTween)

    tweenSeq:OnComplete(function()
        CS.ShowObject(self.mText_Cur, true)
        canvas_new.alpha = 0

        self._isPlayChatTween = false
        if self._isCacheChatMsg then
            --有缓存信息 重新更新一次消息
            self._isCacheChatMsg = false
            self:UpdateMsg()
        end
    end)

    tweenSeq:PlayForward()
end

function UIMCity:GiftReturnCD(item, itemdata)
    local sid = itemdata.actData.sid
    local actData = gModelActivity:GetActivityBySid(sid)
    if not actData then
        return
    end
    local moreInfo = actData:GetMoreInfo()
    local day = moreInfo.day
    local buyEndTime = LUtil.GetNextDayTimes(actData.startTime, day)

    local endTime = buyEndTime
    local time = tonumber(endTime)
    if not time then
        return
    end
    local timeLeft = time - GetTimestamp()


    --if timeLeft < 0 then
    --    if time > 0 then
    --        self:RefreshActivityList()
    --    end
    --    return
    --end
    if not CS.IsValidObject(item) then
        return
    end
    if timeLeft < 0 then
        local layout = self:FindWndTrans(item, "layout")
        local timeBg = CS.FindTrans(layout, "TimeBg")
        CS.ShowObject(timeBg, false)
        return
    end
    self:CommonSetTimeText(item, timeLeft)
end

function UIMCity:InitCommand()
    self:RefreshInfo()

    self:SetPower()
    --local hidTop = self:GetWndArg("hidTop")
    --if hidTop then
    --	self:ShowTop(false,false)
    --end

    self:CreateHeadIcon()

    self:RefreshFunctionOpen()
    --self:SetDefaultState()
    --CS.ShowObject(self.mBulletinBtn,true)
    self:SetNoticeUIList()
    self:SetGiftUIList()
    self._gradeShow = true
    self:RefreshGrade()
    self:IsOpent()
    self:UpdateMsg()
end

function UIMCity:ShowActCountDown()
    for k, v in pairs(self._activityItemList) do
        for k1, v1 in pairs(v) do
            if not k1.isSurveyData or not k1.isRecharge then
                local itemdata = k1
                if itemdata.actData then
                    local item = v1
                    local model = itemdata.actData.model
                    if model == ModelActivity.EIGHTLOGIN then
                        self:EightLoginCD(item, itemdata)
                    elseif model == ModelActivity.MODEL_ACTIVITY_TYPE_155 then
                        self:DamselTrialCD(item, itemdata)
                    elseif model == ModelActivity.GIFT_SPECIAIPOP then
                        self:Pop3CD(item, itemdata)
                    elseif model == ModelActivity.Mirage_Challenge then
                        self:MirageChallengeCD(item, itemdata)
                    elseif model == ModelActivity.DREAM_SCHOOL then
                        self:SchoolCd(item, itemdata)
                    elseif model == ModelActivity.MODEL_DAILYGIFTBAG then
                        self:DailyGiftBagIntegralCD(item, itemdata)
                    elseif self._commonCdActivity[model] then
                        self:CommonActivityCd(item, itemdata)
                    elseif model == ModelActivity.BUILTIN_ACTIVITY_10002 then
                        self:BackflowCd(item, itemdata)
                    elseif model == ModelActivity.MODEL_ACTIVITY_TYPE_74 then
                        self:OnlineRewardCd(item, itemdata)
                    elseif model == ModelActivity.MODEL_ACTIVITY_TYPE_123 then
                        self:GiftReturnCD(item, itemdata)
                    elseif model == ModelActivity.MODEL_ACTIVITY_TYPE_153 then
                        self:OpenSerGiftTime(item, itemdata)
                    elseif model == ModelActivity.MODEL_ACTIVITY_TYPE_94 then
                        self:ActivityShowEndTimeCd(item, itemdata)
                    elseif model == ModelActivity.MODEL_ACTIVITY_TYPE_165 then
                        self:ActivityShowEndTimeCd(item, itemdata)
                    elseif model == ModelActivity.MODEL_ACTIVITY_TYPE_164_1 then
                        self:Activity164_1EndTimeCd(item, itemdata)
                    end
                end
            end
        end
    end
end

function UIMCity:RefreshSimuRed()
    if not self._simuRedTran then
        return
    end

    local showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.SIMU_MAIN)
    CS.ShowObject(self._simuRedTran, showRed)
end

function UIMCity:VideoOpt()
    GF.OpenWndBottom("UIVdoCenter")
end

-- 计算数据列表
function UIMCity:CalculateDataList()
    local pageIndex = self._pageIndex

    self.showDataList = {}
    if pageIndex == 1 then
        self.showDataList[1] = self.originalDataList[self._mainEntraceDataMax]
        self.showDataList[2] = self.originalDataList[pageIndex]
        self.showDataList[3] = self.originalDataList[pageIndex + 1] or self.originalDataList[pageIndex]
    elseif pageIndex == self._mainEntraceDataMax then
        self.showDataList[1] = self.originalDataList[pageIndex - 1]
        self.showDataList[2] = self.originalDataList[pageIndex]
        self.showDataList[3] = self.originalDataList[1]
    else
        self.showDataList[1] = self.originalDataList[pageIndex - 1]
        self.showDataList[2] = self.originalDataList[pageIndex]
        self.showDataList[3] = self.originalDataList[pageIndex + 1]
    end
end

function UIMCity:UpDateMainEntraceTxt()
    local curTime = GetTimestamp()

    for k, v in ipairs(self._itemList) do
        local leftTime = 0
        local data = self.showDataList[k]
        if data then
            if data.pb then
                leftTime = math.max(0, data.pb.endTime - curTime)
            else
                local serverData = gModelFunctionOpen:GetForeshowData(data.data.refId)
                if serverData and serverData.endTime > 0 then
                    leftTime = math.max(0, serverData.endTime - curTime)
                end
            end
        end

        if leftTime > 0 then
            local strTime = LUtil.FormatTimespanCn(math.ceil(leftTime))
            self:SetWndText(v.txtTime, strTime)
        end

        CS.ShowObject(v.txtBg, leftTime > 0)
    end
end

function UIMCity:CheckStartResultTimer()
    local timerKey = "resultCd"
    if not self._showResultList or #self._showResultList == 0 then
        self:TimerStop(timerKey)
        return
    else
        if self:IsTimerExist(timerKey) then
            return
        end
    end

    local timePara = {
        key = "resultCd",
        interval = 0.2,
        timescale = false,
        loopcnt = -1,
        func = function()
            self:SetRCountDown()
        end
    }

    self:TimerStartImpl(timePara)
end

function UIMCity:GiftListItem(list, item, itemdata, itempos)
    local ItemBg = self:FindWndTrans(item, 'ItemBg')
    local icon = CS.FindTrans(ItemBg, "Icon")
    local timeText = CS.FindTrans(ItemBg, "TimeBg/TimeText")
    local eff_0 = CS.FindTrans(icon, "Eff")
    local eff_1 = CS.FindTrans(icon, "Eff_1")
    local eff_2 = CS.FindTrans(icon, "Eff_2")

    local eff

    CS.ShowObject(eff_0, false)
    CS.ShowObject(eff_1, false)
    CS.ShowObject(eff_2, false)

    local ref = itemdata.ref
    local giftType = ref.giftType

    local itemBgPath = giftType == 1 and "mainui_bg_notice_21" or "mainui_bg_notice_2"
    self:SetWndEasyImage(ItemBg, itemBgPath)

    local effName = "fx_ui_popupGift"
    if giftType == 0 then
        eff = eff_0
        effName = "fx_ui_popupGift"
    elseif giftType == 1 then
        eff = eff_1
        effName = "fx_ui_popupGift_2"
    elseif giftType == 2 then
        eff = eff_2
        effName = "fx_ui_popupGift_3"
    end

    CS.ShowObject(eff, true)
    local effInsatnce = eff:GetInstanceID()

    self:SetWndEasyImage(icon, ref.icon)
    self:CreateWndEffect(eff, effName, "gift" .. effInsatnce, 100)
    self._giftTimeTransList[giftType] = timeText
    self._giftIconTrans = icon
    self:SetWndClick(item, function()
        self:OnClickPopGift(itemdata, giftType)
    end)
end

--endregion --------------------------------------------------------------------------------------


--region 主界面聊天区域部分 --------------------------------------------------------------------------------
--判断聊天部分是否开启
function UIMCity:UpdateShow(isShow)
    if not isShow and isShow ~= nil then
        CS.ShowObject(self.mChatAirPop, isShow and gModelFunctionOpen:CheckIsShow(11700000))
        CS.ShowObject(self.mChatBtn, isShow and gModelFunctionOpen:CheckIsShow(11700000))
        CS.ShowObject(self.mChatAirPopOptBtn, false and gModelFunctionOpen:CheckIsShow(11700000))
        CS.ShowObject(self.mChatBtnRoot, isShow and gModelFunctionOpen:CheckIsShow(11700000))

        return
    end

    --这块的bool值屏蔽了就可以 不然会受到服务器的控制  --就是主界面有活动的时候 不会显示这个
    --if not bool then return end

    self:IsOpent()
end

function UIMCity:GetCommonLayerTrans(item)
    local layout = self:FindWndTrans(item, "layout")
    local layoutEn = self:FindWndTrans(item, "layoutEn")

    local isShowActNameRoll = self._isShowActNameRoll and CS.IsValidObject(layoutEn)
    local layoutRoot, layoutHideRoot
    if isShowActNameRoll then
        layoutRoot = layoutEn
        layoutHideRoot = layout
    else
        layoutRoot = layout
        layoutHideRoot = layoutEn
    end
    return layoutRoot, layoutHideRoot
end

function UIMCity:AutoScroll()
    self:AutoMoveRoot(UIMCity.MOVE_LEFT)
end

function UIMCity:OnClickHomes()
    --printInfoN("====== 点击了家园=== 这里暂不知挑转  -- 打开放映机先 后续再来调整")
    -- local open, msg = gModelFunctionOpen:CheckIsOpened(21000000)
    -- if open then
    --     GF.OpenWnd("UIHeartPark", { playerId = gModelPlayer:GetPlayerId(), playerName = "name" })
    -- else
    --     if msg then
    --         GF.ShowMessage(msg)
    --     end
    -- end


    if gLGameLanguage:IsJapanRegion() then
        if PRODUCT_G_VER ~= 0 then
            local isIos = true
            if isIos then
                --self:OnClickOutskirts()
                GF.ChangeMap("LCityMap", true)
                GF.OpenWndBottom("UIOutts", { ios = 1 })
                return true
            end
        end
    end

    GF.ChangeMap("LCityMap")
    GF.OpenWnd("UIGenWin")
    return true
end

function UIMCity:_CreateTxtEffFunc(trans, eff, instanceId)
    self:CreateWndEffect(trans, eff, instanceId, 100, false, false, 2, function(dpTrans)
        dpTrans.gameObject:SetActive(true)
    end)
end

--聊天气泡部分
function UIMCity:PlayVie18TipsShow()
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq("_cVie18TipsAniKey")

    if self.mVie18Tips_2.localScale.x > 0 then
        seq:Insert(0, self.mVie18Tips_2:DOScale(Vector3.one * 0, 0.2))

    else
        seq:Insert(0, self.mVie18Tips_2:DOScale(Vector3.one * 0.5, 0.2))
    end

    seq:OnComplete(function()
        seqCom:DeleteSeq("_cVie18TipsAniKey")
    end)
    seq:PlayForward()
end

function UIMCity:OnTryTcpReconnect()
    self._onlineShowEntryId = 0
end

function UIMCity:SetGiftUIList()
    local _giftList = gModelPopupGift:GetGiftArrListByGiftType(0)
    local _giftList2 = gModelPopupGift:GetGiftArrListByGiftType(1)
    local _giftList3 = gModelPopupGift:GetGiftArrListByGiftType(2)
    local _giftIndex = self._giftIndex
    _giftIndex = _giftIndex + 1
    if _giftIndex < 1 then
        _giftIndex = #_giftList
    elseif _giftIndex > #_giftList then
        _giftIndex = 1
    end
    local _giftInfo = _giftList[_giftIndex]
    local list = {}
    if _giftInfo then
        if _giftList2[1] then
            table.insert(list, _giftList2[1])
        end
        table.insert(list, _giftInfo)
        if self._giftIndex == 0 then
            self:SetTowee(self._giftTweenKey)
        end
        self._giftIndex = _giftIndex

        if _giftList3[1] then
            table.insert(list, _giftList3[1])
        end
    else
        self._giftIndex = 0
        if _giftList2[1] then
            table.insert(list, _giftList2[1])
            self:SetTowee(self._giftTweenKey)
        end

        if _giftList3[1] then
            table.insert(list, _giftList3[1])
            self:SetTowee(self._giftTweenKey)
        end
    end
    self._giftInfoList = {
        [0] = _giftInfo,
        [1] = _giftList2[1],
        [2] = _giftList3[1],
    }

    table.sort(list, function(a, b)
        return a.ref.giftType > b.ref.giftType
    end)

    local _uiGiftList = self._uiGiftList
    if not _uiGiftList then
        _uiGiftList = self:GetUIScroll("uiGiftList")
        self._uiGiftList = _uiGiftList
        _uiGiftList:Create(self.mGiftScroll, list, function(...)
            self:GiftListItem(...)
        end, UIItemList.NORMAL, false)
        local uiList = _uiGiftList:GetList()
        uiList:EnableLoadAnimation(true, 0.03, 1)
        uiList:RefreshList()
    else
        _uiGiftList:RefreshList(list)
    end
    local _giftCountDownKey = self._giftCountDownKey
    self:TimerStop(_giftCountDownKey)
    self:TimerStart(_giftCountDownKey, 1, false, -1)
    self:SetGiftCountDownTime()
    if self._isGiftCut then
        self:SetTowee(self._giftCurEndTweenKey)
    end

    if gLGameLanguage:IsVietnamRegion() and gLGameLanguage:CheckIsShowVie18Tips() then
        CS.ShowObject(self.mVie18Tips, self:GetCurIndex() == LMainBtnIndexConst.CITY)
        --vie  18+ 新增提示 根据礼包数量调整位置     120
        local count = #list
        local offsetY = 120 * count
        local initPosY = -311
        local endPosY = initPosY - offsetY

        self:SetAnchorPos(self.mVie18Tips, Vector2.New(54, endPosY))

        self:SetWndClick(self.mVie18Tips, function()
            self:PlayVie18TipsShow()
        end)
    else
        CS.ShowObject(self.mVie18Tips, false)
    end

    if gLGameLanguage:CheckIsVie119Pack() then
        CS.ShowObject(self.mVie18Tips_3, true)
    else
        CS.ShowObject(self.mVie18Tips_3, false)
    end
end

function UIMCity:RefreshFxSorting()
    if not self._activityItemList then
        return
    end

    for k, v in pairs(self._activityItemList) do
        for k1, v1 in pairs(v) do
            local item = v1
            local RedPoint = self:FindWndTrans(item, "redPoint")
            self:ResetRedSortingOrder(RedPoint)

            --[[			local Eff = self:FindWndTrans(item,"Eff")
			self:ResetRedSortingOrder(Eff)]]
        end
    end
end

function UIMCity:StopCharacterRedPointStateTime()
    self:TimerStop(self._characterRedTimeKey)
end

function UIMCity:RefreshGrade()
    local _gradeLevel = gModelGrade:GetGradeLevel()
    if (not _gradeLevel or _gradeLevel < 1) then
        return
    end
    local isShow = gModelGrade:GetIsShow()
    CS.ShowObject(self.mGradeImg, isShow)
    local isHideReward = gModelGrade:GetIsHideReward()

    self:IsShowGradeQuest(isShow and self._gradeShow and isHideReward)
    if (not isShow or not self._gradeShow) then
        return
    end
    --self:PlayEff(self.mGradeEff, "fx_maoxianpingji", "fx_maoxianpingji")

    local posParent = self.mGradeSpine

    if self._isForeign then
        posParent = self.mGradeSpine_enus
    end

    if self._gradespine then
        self._gradespine:PlayAnimation(0, "idle2", true)
        self._gradespine:SetAnimationTimeScale(0.3)
    else
        self._gradespine = self:CreateWndSpine(posParent, "ui_maoxianpingji_qizhi", "ui_maoxianpingji_qizhi", false)
        self._gradespine:PlayAnimation(0, "idle2", true)
        --self._gradespine._animationTimeScale = 0.3
        self._gradespine:SetAnimationTimeScale(0.3)
    end

    self._gradespine:ResumeAnimation()

    local ref = gModelGrade:GetGradeLvRefByRefId(_gradeLevel)
    self:SetWndEasyImage(self.mGradeIcon, ref.iconCity)

    -- CS.ShowObject(self.mGradeSpine, true)
    -- local starNum = ref.starNum
    -- CS.ShowObject(self.mGradeStarMag, starNum > 0)
    -- if starNum > 0 then
    --     for i = 1, 5 do
    --         local trans = CS.FindTrans(self.mGradeStarMag, "Star" .. i)
    --         if i <= starNum then
    --             self:SetWndEasyImage(trans, ref.starColor)
    --         else
    --             self:SetWndEasyImage(trans, "mianui_risk_star_3")
    --         end
    --     end
    -- end
end

function UIMCity:ClearActEff(listKey)
    local record = self._actEffRecord and self._actEffRecord[listKey]
    if not record then
        return
    end

    for k, v in pairs(record) do
        self:DestroyWndEffectByKey(k)
    end
    self._actEffRecord[listKey] = {}
end

function UIMCity:OperCurResult(showdata)
    if not showdata.canOper then
        return
    end
    self:RemoveResultItem(showdata)
    self:QuickExecuteResult(showdata)
end

function UIMCity:OnRefreshActivityModel34()
    self:ShowActivityList()
    self:RefreshActivityRed()
end

function UIMCity:OnDrawItem(list, item, itemdata, itempos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")

    local extra = {
        noClick = true,
    }
    self:CreateCommonIconImpl(AniRoot, itemdata, extra)
end

-- 停止倒计时
function UIMCity:StopMainEntraceTimer()
    self:TimerStop("mainEntraceTimerKey")
end

function UIMCity:RefreshActivityEffRed(item, itemdata)
    local Eff = self:FindWndTrans(item, "Eff")
    local Icon = self:FindWndTrans(item, "Icon")
    local instanceId = Eff:GetInstanceID()
    local iconEffect = self:GetActivityEffName(itemdata)
    local isEmpty = string.isempty(iconEffect)
    local eff = self:FindWndEffectByKey(instanceId)
    if not isEmpty then
        if eff then
            local effName = eff:GetEffectName()
            if effName and effName == iconEffect then
                if Icon and Icon.gameObject.activeSelf then
                    CS.ShowObject(Icon, false)
                end
                return
            end
            self:DestroyWndEffectByKey(instanceId)
        end
    end
    if isEmpty then
        if Icon and not Icon.gameObject.activeSelf then
            CS.ShowObject(Icon, true)
        end
        if eff then
            self:DestroyWndEffectByKey(instanceId)
        end
        return
    end
    self:_CreateTxtEffFunc(Eff, iconEffect, instanceId)
end

-- 显示特效
function UIMCity:ShowEff(trans, key, isShow)
    local effName = "fx_ui_gunping_2"

    if isShow then
        if self._effectList and self._effectList[key] then
            return
        end
        self:CreateWndEffect(trans, effName, key, 100, nil, nil, nil, nil, nil, true)
    else
        self:DestroyWndEffectByKey(key)
    end
end

function UIMCity:OnClickGiftCode()
    GF.OpenWnd("WndGiftCode")
end

function UIMCity:RefreshMasonryMore()
    if not self.mMasonryMoreBg.gameObject.activeSelf then
        return
    end

    for k, v in ipairs(self._japanMasonryIdList) do
        local itemTrans = self:FindWndTrans(self.mMasonryMoreBg, "Item" .. k)
        if CS.IsValidObject(itemTrans) then
            local nameTrans = self:FindWndTrans(itemTrans, "Name")
            local numTrans = self:FindWndTrans(itemTrans, "Num")
            local iconTrans = self:FindWndTrans(itemTrans, "icon")

            local nameStr
            if v == ModelItem.ITEM_DIAMOND then
                nameStr = ccClientText(10179)
            else
                nameStr = gModelItem:GetNameByRefId(v)
            end
            self:SetWndText(nameTrans, nameStr)

            local num = gModelItem:GetNumByRefId(v, true)
            num = LUtil.NumberCoversion(num)
            self:SetWndText(numTrans, num)

            local iconPath = ModelItem:GetItemImgByRefId(v)
            if LxUiHelper.IsImgPathValid(iconPath) then
                self:SetWndEasyImage(iconTrans, iconPath)
            end
        end
    end
end

function UIMCity:OnSwitchToOther(index, extraWnds)
    local extraWndList = self._exceptWnd[index]
    extraWnds = extraWnds or {}
    if extraWndList then
        for i, v in ipairs(extraWndList) do
            extraWnds[v] = true
        end
    end
    if gLGameUI then
        gLGameUI:CloseAllBySwitchTypeButExcept(LWnd.SWITCH_TYPE_CHANGE_BTN, extraWnds)
    end
    FireEvent(EventNames.ON_MAIN_CITY_BTN_CHANGE)
end

function UIMCity:OnCanvasParaChange()
    LWnd.OnCanvasParaChange(self)
    self:RefreshFxSorting()
    self:RefreshBtnRedPointSorting()
end

function UIMCity:RefreshCharacterBtnShow()
    local isKorea = gLGameLanguage:IsKoreaRegion()
    if not isKorea then
        CS.ShowObject(self.mCharacterBtn, false)
        return
    end

    local _bool = gModelFunctionOpen:CheckIsOpened(10010004, false)

    if PRODUCT_G_VER == 2 then
        --ios提审屏蔽
        _bool = false
    end

    CS.ShowObject(self.mCharacterBtn, _bool)

    self._characterBtnShow = _bool
    if _bool then
        self:TryGetCharacterRedPointState()
    else
        self:StopCharacterRedPointStateTime()
    end
end

function UIMCity:GetActivityEffName(itemdata)
    local actData = itemdata.actData
    if not actData then
        return
    end
    local actModel = actData.model
    if actModel == ModelActivity.DREAM_SCHOOL then
        --- 骑士学院：不管有无红点，都默认显示这个特效
        --if self:CheckShowRed(itemdata) then
        --    return "ui_fx_dreamcollege"
        --else
        --    return "ui_fx_dreamcollege"
        --end
        return "ui_fx_dreamcollege"
    end
end

function UIMCity:DamselTrialCD(item, itemdata)
    local sid = itemdata.actData.sid
    local data = gModelActivity:GetActivityBySid(sid)
    if not data then
        return
    end

    local endTime = data.endTime
    local curTime = GetTimestamp()
    local leftTime = endTime - curTime
    if leftTime <= 0 then
        return
    end

    self:CommonSetTimeText(item, leftTime)
end

function UIMCity:SetWndVisible(active)
    LWnd.SetWndVisible(self, active)
    CS.ShowObject(self.mAniRoot, active)
    local effect = self:FindWndEffectByKey(self._fightBtnOffEff)
    if effect then
        effect:SetVisible(active)
    end
end

function UIMCity:ShowSdkGameGuide(para)
    local tran = self._sdkGameTran
    if not CS.IsValidObject(tran) then
        return
    end

    GF.OpenWnd("UIGueTip", { wndType = 1, targetTran = tran, para = { info = para and para.guideTxt } })
end

function UIMCity:SetGiftScrollAlphaTween(seq, index)
    local trans = self._giftIconTrans
    if not trans then
        return
    end
    local canvasGroup = trans:GetComponent(typeofCanvasGroup)
    if not canvasGroup then
        return
    end
    if index == 1 then
        canvasGroup.alpha = 1
        local tween = canvasGroup:DOFade(0, 0.6)
        seq:Append(tween)
        seq:AppendCallback(function()
            self._isGiftCut = true
            self:SetGiftUIList()
        end)
    else
        canvasGroup.alpha = 0
        local tween = canvasGroup:DOFade(1, 0.6)
        seq:Append(tween)
        seq:AppendCallback(function()
            self._isGiftCut = false
        end)
    end
end

function UIMCity:RefreshActivityRed()
    for k, v in pairs(self._activityItemList) do
        for k1, v1 in pairs(v) do
            local item = v1
            local itemdata = k1
            local RedPoint = CS.FindTrans(item, "redPoint")
            local showRed = self:CheckShowRed(itemdata)
            self:RefreshActivityEffRed(item, itemdata)
            CS.ShowObject(RedPoint, showRed)
        end
    end
    self:RefreshActBtnRed()
end

function UIMCity:InitMsg()
    self:WndEventRecv(EventNames.ON_POWER_CHANGE, function(pType, pKey, pPower)
        if pType == 0 then
            if (self._oldPower < pPower) then
                CS.ShowObject(self.mPowerDiv, false)
                GF.CloseWndByName("UIPowps")
                GF.OpenWndDebug("UIPowps", { oldPower = self._oldPower, power = pPower })
            end
            self:SetPower()
        end
    end)

    self:WndEventRecv(EventNames.ON_POWER_CHANGE_END, function()
        CS.ShowObject(self.mPowerDiv, true)
    end)

    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:RefreshInfo(true)
    end)

    self:WndNetMsgRecv(LProtoIds.ItemListResp, function()
        self:RefreshInfo(true)
    end)

    self:WndEventRecv(EventNames.SHOW_MAIN_MORE_FUN, function(isShow)
        self:Show(isShow)
    end)
    self:WndEventRecv(EventNames.ON_CHAT_CHANGE_CHATAIRPOP_SET, function()
        self:SetChatAirPopDrag()
    end)

    self:WndEventRecv(EventNames.Examine_Fight_Wnd, function()
        if self._lastBotBtnIndex ~= 3 then
            local wnd = GF.FindFirstWndByName("UIMinFight")
            if wnd then
                GF.CloseWndByName("UIMinFight")
            end
        end
    end)

    self:WndEventRecv(EventNames.SHOW_MAIN_TOP, function(isShow)
        self:ShowTopUI(isShow)
    end)

    self:WndEventRecv(EventNames.SHOW_MAIN_BOTTOM, function(isShow)
        self:ShowBottomUI(isShow)
    end)
    self:WndEventRecv(EventNames.SHOW_MAIN_ACTSCROLL, function(isShow)
        CS.ShowObject(self.mActPart, isShow)
        --todo 先屏蔽掉 该部分的显示
        --CS.ShowObject(self.mInformScroll, isShow)
        CS.ShowObject(self.mInformScroll, false)
        CS.ShowObject(self.mGiftScroll, isShow)
        self:ShowSpecialActivityScrollUI(isShow)
        self:UpdateShow(isShow)
        self._gradeShow = isShow
        if isShow then
            self:RefreshGrade()
            CS.ShowObject(self.mTsDesBg, false)
        else
            --self:IsShowGradeQuest(false)
        end

        -- self:ShowEnjoyMonthCard(isShow, true)
        -- self:ShowOneWelfare(isShow)
        self:ShowMerchant(isShow)

        if gLGameLanguage:IsVietnamRegion() and gLGameLanguage:CheckIsShowVie18Tips() then
            CS.ShowObject(self.mVie18Tips, self:GetCurIndex() == LMainBtnIndexConst.CITY and isShow)
        end
    end)

    self:WndEventRecv(EventNames.CHANGE_MAIN_BTN, function(index, extraWnds,ignoreCurBtn)
        self:OnChangeMainBtn(index, extraWnds,ignoreCurBtn)
    end)
    self:WndEventRecv(EventNames.CHANGE_MAIN_BTN_WHATEVER, function(index, extraWnds)
        self:ChangeWhatever(index, extraWnds)
    end)
    self:WndEventRecv(EventNames.ONLY_CHANGE_MAIN_BTN_ON, function(...)
        self:OnlyChangeMainIndex(...)
    end)

    self:WndNetMsgRecv(LProtoIds.PlayerChangeResp, function()
        self:RefreshInfo(true)
        self:CreateHeadIcon()
    end)

    self:WndEventRecv(EventNames.MAINFIGHT_BATTLE_UPDATE, function()
        self:RefreshInfo(true)
    end)

    self:WndNetMsgRecv(LProtoIds.PopupGiftNowListResp, function()
        self:SetGiftUIList()
        self:RefreshActivityList()
    end)

    self:WndNetMsgRecv(LProtoIds.PopupGiftNowResp, function()
        self:SetGiftUIList()
        self:RefreshActivityList()
    end)
    self:WndNetMsgRecv(LProtoIds.RegressionInfoResp, function()
        self:SetGiftUIList()
        self:RefreshActivityList()
    end)

    self:WndEventRecv(EventNames.ON_ACTIVITY_PAGE_CHANGE, function(modelId, sid)
        if modelId == ModelActivity.MODEL_ACTIVITY_TYPE_74 then
            self:ShowSpecialActivityList()
        end
    end)

    self:WndEventRecv(EventNames.QUERY_SURVEY_LIST_RESULT, function()
        self:RefreshSurveyBtn()
    end)

    self:WndEventRecv(EventNames.SDK_SUPPORT_POPUPOFFICIALPAYMENT, function(isCanPopup)
        if isCanPopup then
            self:ShowActivityList()
        end
    end)

    self:WndEventRecv(EventNames.ON_ACTIVITY_LIST_CHANGE, function()
        self:RefreshActivityList()
        -- self:ShowEnjoyMonthCard(true)
        -- self:ShowOneWelfare(true)
        self:ShowMerchant(true)
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_DREAMSCHOOL_CHANGE, function()
        self:RefreshActivityList()
    end)
    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        self:RefreshActivityList()
        self:IsShowWndAssistBtn()
        FireEvent(EventNames.REFRESH_FUNCTION_STATE)
    end)
    self:WndEventRecv(EventNames.KKK_AUTH_RECEIVE, function(type)
        if type == 4 or type == 9 then
            self:RefreshActivityList()
        end
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
        if ModelActivity.MODEL_ACTIVITY_TYPE_153 == sid then
            self:ShowActivityList()
        end

        ---- 旧模版数据要保留
        local iconSpeacialMainCityRedpointData = self._iconSpeacialMainCityRedpointData
        --如果是特殊处理的 这里就进行下处理吧
        if iconSpeacialMainCityRedpointData and iconSpeacialMainCityRedpointData.specialSid == sid then
            local webConfig = gModelActivity:GetActivityBySid(sid)
            local webMoreInfo = JSON.decode(webConfig.moreInfo)
            if webMoreInfo.pop == true and iconSpeacialMainCityRedpointData.isFirst  then
                iconSpeacialMainCityRedpointData.isFirst = false
                gModelGeneral:InsertPopActivityWnd({ uiName = "UIActivityGiftModel4PopOld", sid = sid })
            end
            local webData = gModelActivity:GetWebActivityDataById(sid)
            iconSpeacialMainCityRedpointData.webData = webData
        end

        if gModelActivity:CheckFirstPop164ReqConfigData(sid) then
            ---@type StructActivity
            local activity = gModelActivity:GetActivityBySid(sid)
            local moreInfo = activity and JSON.decode(activity.moreInfo)
            if moreInfo and moreInfo.pop then
                gModelActivity:ChangeFirstPop164ReqConfigStatus(sid)
                gModelGeneral:InsertPopActivityWnd({ uiName = "UIActivityGiftModel4Pop", sid = sid })
            end
        end

        self:RefreshSpecialRedpoint()
    end)
    self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE, function()
        --先刷新下显示
        self:SetMainCityShow("story", true)

        self:RefreshActivityList()

        self:ShowTopUI(self._isShowTop)
        self:ShowBottomUI(self._isShowBottom)
        self:ShowHurdleUI(self._isHurdleShow)
        self:ShowSpecialActivityScrollUI(self._isShowSpecialActivtyScroll)
        -- self:ShowEnjoyMonthCard(true)
        -- self:ShowOneWelfare(true)
        self:ShowMerchant(true)
        self:RefreshFunctionOpen()
        self:CheckBottomBtnIsLock()
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_SAVE_RED_UPDATE, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.DREAM_SCHOOL_PARENT, function(pb)
        self:RefreshActivityRed()
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_SAVE_RED_TIPS, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.ACTIVITY_WELFARE, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.ACTIVITY_ACTIVITY, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.ACTIVITY_TIME, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.ACTIVITY_FIVE, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.ACTIVITY_TYPE4, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.DREAM_SCHOOL_THEME, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.DREAM_SCHOOL_TASK, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.REDPOINT_ID_23000000, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.REDPOINT_ID_10450000, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.NATURAL_PARTNER_ENTRANCE, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(ModelRedPoint.NATURAL_PARTNER_WEAL, function(pb)
        self:RefreshActivityRed()
    end)
    self:RegisterRedPointFunc(21000000, function(isShow)
        if not isShow then
            isShow = gModelMagicPot:GetGiftRedPoint() or gModelQuest:IsHaveFinishTaskByType(182) or
                    gModelMagicPot:GetRewardRedpoint()
        end
        local redTran = CS.FindTrans(self.mHomesImage, "redPoint")
        CS.ShowObject(redTran, isShow)
    end)
    self:WndEventRecv("magicPotRedPointChange", function()
        local isOpen = gModelFunctionOpen:CheckIsOpened(21008100)
        local isShow
        if isOpen then
            isShow = gModelMagicPot:GetGiftRedPoint() or gModelQuest:IsHaveFinishTaskByType(182) or
                    gModelMagicPot:GetRewardRedpoint()
        end
        local redTran = CS.FindTrans(self.mHomesImage, "redPoint")
        CS.ShowObject(redTran, isShow)
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_LOCAL_CLICK_RED_CHANGE, function(para)
        self:RefreshActivityRed()
    end)
    self:WndEventRecv(EventNames.FARM_INFO_UPDATE, function(playerId)
        if playerId == gModelPlayer:GetPlayerId() then
            self:RefreshActivityRed()
        end
    end)
    self:WndEventRecv(EventNames.FARM_DOGTIME_UPDATE, function()
        self:RefreshActivityRed()
    end)
    self:WndEventRecv(EventNames.ON_GUIDE_START, function()
        self:OnGuideStart()
    end)
    self:WndEventRecv(EventNames.ON_OPERATION_TIME_CHANGE, function()
        self:CheckShowFinger()
    end)
    self:WndEventRecv(EventNames.ON_ENDLESS_BUFF_SELECT, function(...)
        self:SetNoticeUIList()
    end)
    self:WndEventRecv(EventNames.SIMULATE_STATE_CHANGE, function(...)
        self:SetNoticeUIList()
    end)
    self:WndEventRecv(EventNames.ON_SIMULATE_INTER_OPEN, function(...)
        self:SetNoticeUIList()
    end)
    self:WndEventRecv(EventNames.ON_ENDLESS_BUFF_SELECTEND, function(...)
        self:SetNoticeUIList()
    end)
    self:WndEventRecv(EventNames.CHANGE_NOTICE_LIST, function(...)
        self:SetNoticeUIList()
    end)
    self:WndEventRecv(EventNames.SHOW_MAIN_GRADE, function(...)
        self:RefreshGrade()
    end)

    self:WndEventRecv(EventNames.SHOW_MAIN_HURDLE, function(isShow)
        self:ShowHurdleUI(isShow)
        self:ShowMerchant(isShow)
        -- self:ShowPrePost()【G功能预告】删除玩法预告机制（客户端&服务端）
        if isShow then
            self:TryGetCharacterRedPointState()
        else
            self:StopCharacterRedPointStateTime()
        end
        self:RefreshFuncPreView()
    end)

    self:WndNetMsgRecv(LProtoIds.QuestReceiveResp, function(...)
        self:RefreshGrade()
    end)

    -- 【G功能预告】删除玩法预告机制（客户端&服务端）
    -- self:WndEventRecv(EventNames.REFRESH_PREPOST, function()
    --     self:ShowPrePost()
    -- end)

    self:WndEventRecv(EventNames.ON_CLICK_SELF, function()
        local func = self._bottomBtnFunc[self._lastBotBtnIndex]
        if func then
            func()
        end
        self:ChangeCurBtn(self._lastBotBtnIndex)
    end)

    self:WndEventRecv(EventNames.ON_STORY_SHOW_WND, function(key, value, time)
        --print("EventNames.ON_STORY_SHOW_WND")
        --self:SetWndVisible(value)
        self:SetMainCityShow(key, value, time)
    end)

    self:WndNetMsgRecv(LProtoIds.PersonaliseNewInfoResp, function(...)
        self:RefreshHeadRed(...)
    end)
    self:WndNetMsgRecv(LProtoIds.PersonaliseClickInfoResp, function(...)
        self:RefreshHeadRed(...)
    end)
    self:WndEventRecv(EventNames.MAINCITY_ZONE_RED_UPDATE, function(...)
        self:RefreshHeadRed(...)
    end)

    self:WndEventRecv(EventNames.ON_PLAYER_LEVEL_CHANGE, function()
        self:CheckShowFinger()

        self:RefreshStrongShow()

        self:RefreshSurveyBtn()
    end)

    self:WndEventRecv(EventNames.ON_WND_CLOSE, function(wndName)
        gModelGeneral:CheckShowIgnoredPopGift()
        self:ShowMasonryMore(false)
        self:CheckOpenForeShowPop(wndName)
    end)

    self:WndEventRecv(EventNames.SPREAD_ACT_LIST, function()
        self:RefreshActivityList()
    end)

    self:RegisterRedPointFunc(ModelRedPoint.SIMU_MAIN, function()
        self:RefreshSimuRed()
    end)

    self:WndEventRecv(EventNames.ON_BATTLE_BACK_PRESS, function()
        self:OnBottomBtnClick(1)
    end)

    self:WndEventRecv(EventNames.ON_GUILD_HINT, function()
        self:IsShowWndAssistBtn()
    end)

    self:WndEventRecv(EventNames.ON_GUIDE_END, function()
        self:OnGuideEnd()
    end)

    self:WndEventRecv(EventNames.SDK_READ_STATE, function(isOk)
        self:SetCharacterRedPoint(isOk)
    end)

    self:WndEventRecv(EventNames.APPLICATION_PAUSE, function(isPause)
        if not isPause then
            self:GetCharacterRedPointState()
        end
    end)

    self:WndEventRecv(EventNames.SDK_MEMBER_CENTER_CLOSED, function()
        self:GetCharacterRedPointState()
    end)
    self:WndEventRecv(EventNames.REFRESH_ACTIVITY_POPGIFT_DATA, function()
        self:SetGiftUIList()
        --self._refreshActPopData = nil
    end)

    self:WndEventRecv(EventNames.PLAYER_VIP_LEVEL_CHANGE, function(oldLv, newLv)
        self:ShowVipServiceWnd(oldLv, newLv)
    end)
    self:WndNetMsgRecv(LProtoIds.Activity102WindowResp, function()
        self._activity102Resp = true
        self:ShowVipServiceBtn()
    end)

    self:WndEventRecv(EventNames.ON_WND_FINISH, function(...)
        self:OnOperBattleResult(...)
    end)

    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BOT_BTN, function(btnIndex)
        self:OnBottomBtnClick(btnIndex)
    end)
    self:WndNetMsgRecv(LProtoIds.ChatMsgPushResp, function(...)
        self:UpdateMsg()
    end)

    self:WndEventRecv(EventNames.ON_CHAT_RED_CHANGE, function(...)
        self:UpdateMsgBtnRedPoing()
    end)

    self:WndEventRecv(EventNames.ON_CHAT_TA_SHOW, function(bool)
        self._isShowAir = bool
        CS.ShowObject(self.mChatAirShow, bool)
        CS.ShowObject(self.mChatAirPopOptBtn, false)
        CS.ShowObject(self.mChatBtnRoot, bool)
    end)
    self:SetWndClick(self.mChatBtn, function(...)
        self:OnClickChatAirBg()
    end)
    self:WndEventRecv(EventNames.SENSITIVE_REGULATE, function()
        -- 重连之后导致聊天显示在别的界面上
        --self:IsOpent()
    end)
    self:WndNetMsgRecv(LProtoIds.PrivilegeGiftResp, function(...)
        self:RefreshActivityList()
    end)

    self:WndEventRecv(EventNames.SDK_GAME_GUIDE, function(...)
        self:ShowSdkGameGuide(...)
    end)

    self:WndEventRecv("PlayerGradeLvlUp", function()
        self:InitTopShow()
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_INTERACT, function(...)
        self:RefreshGardenInteractRed()
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_LOVE_UPLV, function(...)
        self:RefreshGardenInteractRed()
    end)
    self:WndEventRecv(EventNames.PET_CHANGE_LINK, function()
        self:RefreshLinkPetRed()
    end)
    self:WndEventRecv(EventNames.PET_CHANGE_STAR, function()
        self:RefreshLinkPetRed()
    end)
    self:WndEventRecv(EventNames.On_Hero_Change, function()
        self:RefreshLinkPetRed()
    end)
    self:WndEventRecv(EventNames.PET_LIST_UPATE, function()
        self:RefreshLinkPetRed()
    end)


    self:WndNetMsgRecv(LProtoIds.QuestionnaireAnswerResp,function()
        self._surveyData = nil
        FireEvent(EventNames.FINISH_SURVEY_RESULT)
        self:RefreshSurveyBtn()
    end)
    self:WndEventRecv(EventNames.SDK_UNREADMSG_RESULT,function() self:SetUnreadMsgRP() end)

    self:WndEventRecv(EventNames.SDK_GETSCENEENTRYINFO_RESULT,function(...) self:OnSdkGetSceneEntryInfoResult(...) end)
    self:WndEventRecv(EventNames.ON_REFRESH_ACTIVITY_MODEL_34,function() self:OnRefreshActivityModel34() end)

    self:WndEventRecv(EventNames.ON_ACT_PAGE_RED_CHANGE, function(redMap)
        self:RefreshSpecialRedpoint()
    end)

    self:WndEventRecv(EventNames.ON_QUEST_CHANGE, function(...)
        self:RefreshSpecialRedpoint()
    end)
end

function UIMCity:ShowVipServiceBtn()
    local activity = gModelActivity:GetEarlyActivity(ModelActivity.MODEL_ACTIVITY_TYPE_102)
    if activity then
        if gModelActivity:IsHasPackId(activity.packId) then
            local txtTrans = self:FindWndTrans(self.mVipServiceBtn, "Text")
            self:SetWndEasyImage(self.mVipServiceBtn, activity.icon)
            self:SetWndText(txtTrans, activity.title)
        end
    end
    --CS.ShowObject(self.mVipService, activity ~= nil and activity ~= false)
    CS.ShowObject(self.mVipService, false)
    if (self._activity102Resp) then
        self._activity102Resp = nil
        self:VipServiceOpt()
    end
end

function UIMCity:ShowOneWelfare(isEnable, enableHelpPop)
    -- local inMainFight = GF.FindFirstWndByName("UIMinFight")
    -- local show = not inMainFight and self._isHurdleShow
    -- isEnable = show and isEnable
    -- local isShowCard = isEnable
    -- local durationTime
    -- if isEnable then
    --     local isShow, endTime = gModelActivity:CheckOneWelfareShow(true)
    --     isShowCard = isShow
    --     durationTime = endTime
    -- end

    -- CS.ShowObject(self.mOneWelfareBtn, isShowCard)
    -- if not isShowCard then
    --     self:TimerStop(self._oneWelfareKey)
    --     return
    -- end

    -- local activityData = gModelActivity:GetSpecialActivity(ModelActivity.MODEL_ACTIVITY_TYPE_4111)
    -- if not activityData then
    --     return
    -- end

    -- local moreInfo = JSON.decode(activityData.moreInfo)
    -- local cityEnterIcon = moreInfo.cityEnterImg
    -- local cityEnterSpine = moreInfo.cityEnterSpine
    -- if LxUiHelper.IsImgPathValid(cityEnterIcon) then
    --     self:SetWndEasyImage(self.mOneWelfareImg, cityEnterIcon)
    -- end

    -- local title = activityData.title
    -- self:SetWndText(self.mOneWelfareText, title)

    -- local sid = activityData.sid
    -- local red = gModelActivity:GetSaveRedBySid(sid)
    -- local showRed = gModelRedPoint:CheckActivityShowRed(sid)
    -- CS.ShowObject(self.mOneWelfareRedPoint, showRed or red)
    -- local isBuy = moreInfo.isBuy
    -- self:CreateWndSpine(self.mOneWelfareEff, self._oneWelfareEff, self._oneWelfareEff, 100, function(spine)
    --     spine:SetRaycastTarget(false)
    -- end, false)
    -- if isBuy ~= 1 then
    --     self._oneWelfareEndTime = durationTime
    --     self:SetOneWelfareCD()
    --     self:TimerStart(self._oneWelfareKey, 1, false, durationTime + 3)

    -- else
    --     CS.ShowObject(self.mOneWelfareTimeText, false)
    -- end

    -- if enableHelpPop and isBuy == 0 then
    --     self:DestroyWndSpineByKey(cityEnterSpine)
    --     self:CreateWndSpine(self.mOneWelfareContent, cityEnterSpine, cityEnterSpine, 100, function(spine)
    --         spine:PlayAnimation(0, "fx_yiyuanfulitangchuang", false)
    --         spine:SetAnimationCompleteFunc(function()
    --             spine:PlayAnimation(0, "fx_yiyuanfulitangchuang_loop", true)
    --         end)
    --     end, false)
    --     --self:SetWndText(self.mEnjoyMonthCardHelpContentText, ccClientText(36005))
    --     CS.ShowObject(self.mOneWelfareContent, true)
    --     local completeFunc = function()
    --         CS.ShowObject(self.mOneWelfareContent, false)
    --     end
    --     self:TweenSeq_FadeInStaysAway(self._oneWelfareSeqKey, self.mOneWelfareContent, { waitTime = 5, completeFunc = completeFunc })
    -- end
end

function UIMCity:OnClickPopGift(itemdata, giftType)
    local id = itemdata.id
    local list, index = gModelPopupGift:GetPopGiftShowList(id, giftType)
    local giftWndName = giftType == 0 and "UIPop2Gift" or "UIPop4Gift"

    if giftType == 2 then
        giftWndName = "UIPop5Gift"
    end
    GF.OpenWnd(giftWndName, { id = id, dataList = list, index = index })
    local attr1 = gModelPopupGift:FormatPopGiftStr(itemdata, index)

    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_POPUP_GIFT, "popup_click", attr1)
end

function UIMCity:InitTouchEvent()
    local op = LGameTouch.TOUCH_FINGER
    local wndName = self:GetWndName()

    gLGameTouch:TouchRegister(op, LGameTouch.TOUCH_EVT_END, function(screenPos)
        gModelGuide:RecordOperTime()

        local isFind = false
        local touchObject = YXTouchManager.EventSystemRaycastGameObject(screenPos)
        if touchObject then
            local name = touchObject.transform.name
            local path = LxUiHelper.GetRelativePath(wndName, touchObject.transform)
            if string.find(path, "GongNengBtn") or name == "TopFuncBg" then
                isFind = true
            end
            if string.find(path, "UIGue/mask") then
                local curGuide = gModelGuide:GetCurGuide()
                if curGuide == 13210 or curGuide == 13200 or 22040 then
                    isFind = true
                end
            end
        end

        if not isFind then
            self:Show(false)
        end
    end)

    gLGameTouch:TouchRegister(op, LGameTouch.TOUCH_EVT_START, function(screenPos)
        if gLGameLanguage.IsVietnamRegion() and gLGameLanguage:CheckIsShowVie18Tips() then
            if self.mVie18Tips_2.localScale.x > 0 then
                self:PlayVie18TipsShow()
            end
        end
    end)
end

function UIMCity:StrengOpt()
    -- 通用奖励测试 变强

    GF.OpenWndBottom("UIGwWin")
end

function UIMCity:SetNoticeCountdown()
    if not self._noticeTimeTextMap then
        return
    end

    for k, v in pairs(self._noticeTimeTextMap) do
        --if k == ModelGeneral.NOTICE_RACE then
        --    local str = ""
        --    local _, timeLeft = gModelRaceGame:IsNoticeShow()
        --    if timeLeft then
        --        str = LUtil.FormatTimespanNumber(timeLeft)
        --    else
        --        str = v.defaultStr
        --    end
        --
        --    self:SetWndText(v.textTran, str)
        --end
    end
end

function UIMCity:RefreshActBtnRed()
    local actBtnRedTran = self:FindWndTrans(self.mActStateBtn, "redPoint")
    local isOn = self:IsShowMoreList()
    if isOn then
        CS.ShowObject(actBtnRedTran, false)
        return
    end

    local showRed = false

    if self._moreActDataList then
        for k, v in pairs(self._moreActDataList) do
            if self:CheckShowRed(v) then
                showRed = true
                break
            end
        end
    end
    CS.ShowObject(actBtnRedTran, showRed)
end

--#endregion -------------------------------------------------------------------------------------------------

--region 滚屏预告

UIMCity.MOVE_RIGHT = -1
UIMCity.MOVE_LEFT = 1
UIMCity.MOVE_CENTER = 0

-- 初始化
function UIMCity:InitMainEntrace()
    self._pageIndex = 1

    --move 使用到的定义  --tween的定义
    self._autoMoveKey = "_autoMoveKey"
    self._moveTime = 0.2
    self._effectList = {}
    self.showDataList = {}

    self:InitList()
    self:InitHandlerMainEntrace()

    self:RefreshMainEntraceList()
    self:StartScroll()
end

function UIMCity:ShowActListImpl(listKey, dataList)
    local oldList = self._activityRecord[listKey] or {}
    local isChange = self:CheckActChange(oldList, dataList)
    if not isChange then
        return
    end

    local root = self.mActLessList
    if listKey == "actMoreList" then
        root = self.mActMoreList
    elseif listKey == self._specialActivtyListKey then
        root = self.mSpecialActivtyScroll
    end

    local recordActKeyMap = self._recordActKeyMap
    if not recordActKeyMap then
        recordActKeyMap = {}
        self._recordActKeyMap = recordActKeyMap
    end
    recordActKeyMap[listKey] = root

    self:ClearActEff(listKey)
    self._activityRecord[listKey] = {}
    self._activityItemList[listKey] = {}
    local uiList = self:FindUIScroll(listKey)
    if not uiList then
        uiList = self:GetUIScroll(listKey)
        local para = {
            root = root,
            dataList = dataList,
            setFunc = function(...)
                self:OnDrawActivityItem(...)
            end,
            metaData = { listKey = listKey },
        }
        uiList:InitListData(para)
    else
        uiList:RefreshList(dataList)
    end
end

function UIMCity:RefreshWebIconInfo()
    local webIconData = gLSdkImpl:CallMethod(LSdkMethod.GetWebIconInfo)
    if self._webIconData ~= webIconData then
        self._webIconData = webIconData
        self:ShowActivityList()
    end
end

function UIMCity:OnGuideStart()
    local key = "guideFinger"
    self:DestroyWndEffectByKey(key)
    CS.ShowObject(self.mResultPart, false)
end

function UIMCity:GetPlayerInfo()
    local data = {
        trans = self.mHeadIcon,
        --playerId = gModelPlayer:GetPlayerId(),
        --name = gModelPlayer:GetPlayerName(),
        icon = gModelPlayer:GetPlayerHead(),
        headFrame = gModelPlayer:GetPlayerHeadFrame(),
        --level = gModelPlayer:GetPlayerLv(),
        --noLv = true,
        --func = function()
        --	self:Show(false)
        --	gModelPlayerSpace:OpenSpaceWnd(gModelPlayer:GetPlayerId())
        --end,
    }
    return data
end

--function UIMCity:ShowBottomBtnState()
--end


function UIMCity:GetCurIndex()
    return self._lastBotBtnIndex
end

--判断是否加锁
function UIMCity:CheckBottomBtnIsLock()
    local strs = self._btnStrs
    for k, v in ipairs(self._btnImgList) do
        local openId = self._bottomFuncId[k]
        local lock = self:FindWndTrans(v, "Lock")
        local isopen = true
        if openId and openId > 0 then
            isopen = gModelFunctionOpen:CheckIsOpened(openId)
        end

        CS.ShowObject(lock, not isopen)

        local text = self:FindWndTrans(v, "UIText")
        local text_lock = self:FindWndTrans(v, "UIText_Lock")

        local image = self:FindWndTrans(v, "Image")
        self:SetWndImageGray(image,not isopen)

        CS.ShowObject(text, isopen)
        CS.ShowObject(text_lock, not isopen)
        self:SetWndText(text_lock, strs[k])
    end
end

function UIMCity:RefreshGardenInteractRed()
    --互动红点
    local favorabilityInfo = gModelHero:GetFavorabilityInfoList()
    local isShow = false
    local isopen = gModelFunctionOpen:CheckIsOpened(21002100, false)
    if isopen then
        for i, v in pairs(favorabilityInfo or {}) do
            if gModelHero:GetFavorabilityInteractRed(v.heroRefId, true) or gModelHero:GetFavorabilityInteractRed(v.heroRefId, false) then
                isShow = true
                break
            end
        end
    end
    gModelRedPoint:ShowPointRed(ModelRedPoint.GARDEN_FAVORABILITY_INTERACT, isShow)
end

function UIMCity:InitEvent()
    for k, v in pairs(self._btnFuncList) do
        self:SetWndClick(v.btn, v.func)
    end

    self:SetWndClick(self.mPowerDiv, function()
        self:StrengOpt()
    end)
    self:SetWndClick(self.mGradeImg, function()
        GF.OpenWnd("UIRiskRtWin", { type = 1 })
    end)
    self:SetWndClick(self.mTsDesBg, function()
        GF.OpenWnd("UIRiskRtWin", { type = 1 })
    end)
    self:SetWndClick(self.mVipObj, function()
        --if gLGameLanguage:IsChinaRegion() and CS.IsWebGL() and LWxHelper.IsMiniGamePlatform() then
        --    if PRODUCT_G_VER ~= 0 then
        --        return
        --    end
        --end

        if gLSdkImpl and gLSdkImpl:CallMethod(LSdkMethod.IsProductBlockRecharging) then
            return
        end
        if gModelFunctionOpen:CheckIsOpened(15000010, true) then
            GF.OpenWndBottom("UIHuiYPay", { page = 1 })
            gModelPlayerSpace:SetTodayZoneRed(false)
        end
    end)

    self:SetWndClick(self.mGongNengBtn, function()
        local isShow = not self.mTopFuncBg.gameObject.activeSelf
        self:Show(isShow)
    end)

    self:SetWndClick(self.mMasonryDiv, function()
        self:OnClickMasonryBuyBtn()
    end)

    self:SetWndClick(self.mGoldDiv, function()
        GF.OpenWnd("UIGBuy")
    end)

    self:SetWndClick(self.mHeadImgObj, function()

        GF.OpenWnd("UIPerReNameUI")
    end)

    local btnList = self._btnImgList
    local soundList = self._btnSoundList
    for k, btn in ipairs(btnList) do
        self:SetWndClick(btn, function()
            --LxUiHelper.PlayAudioSoundName(soundList[k])
            self:OnTaReport(k)
            self:OnBottomBtnClick(k)
            self:IsShowWndAssistBtn()
            if k == LMainBtnIndexConst.CITY  then self:CheckOpenForeShowPop() end
            -- if k == 1 then
            --     gModelGuide:CheckShowSDkGameGuide()
            -- end
        end)
    end

    self:SetWndClick(self.mPrepost, function()
        GF.OpenWnd("WndPrePost")
    end)

    self:SetWndClick(self.mHeadIcon, function()
        gModelPlayerSpace:OpenSpaceWnd(gModelPlayer:GetPlayerId())
        --gModelPlayerSpace:SetTodayZoneRed(false)
    end)

    self:SetWndClick(self.mActStateBtn, function()
        self:OnClickActState()
    end)
    -- 【G公会系统】删除联盟互助功能（客户端&服务端）
    -- self:SetWndClick(self.mAssistBtn, function()
    --     GF.OpenWnd("WndGuildHelpMembers")
    -- end)

    -- self:SetWndClick(self.mEnjoyMonthCardBtn, function()
    --     local activityData = gModelActivity:GetSpecialActivity(ModelActivity.MONTH_ACTIVITY_ENJOY_CARD)
    --     if not activityData then
    --         return
    --     end
    --     GF.OpenWnd("UIActEnjoyMonthCardPop", { sid = activityData.sid })
    --     gLxTKData:OnMainUIActivityClick(activityData)
    -- end)
    self:SetWndClick(self.mChatAirBg, function()
        self:OnClickChatAirBg()
    end)

    self:SetWndClick(self.mChatAirShow, function()
        self:OnClickChatAirBg()
    end)

    self:SetWndClick(self.mChatAirPopOptBtn, function()
        if not self._isPlayChatAni then
            self:OnChatAirPopOptBtnClick()
        end
    end)


    -- self:SetWndClick(self.mOneWelfareBtn, function()
    --     local activityData = gModelActivity:GetSpecialActivity(ModelActivity.MODEL_ACTIVITY_TYPE_4111)
    --     if not activityData then
    --         return
    --     end
    --     GF.OpenWnd("UIAct4111", { sid = activityData.sid })
    --     gLxTKData:OnMainUIActivityClick(activityData)
    -- end)
    -- self:SetWndClick(self.mOneWelfareContent, function()
    --     local activityData = gModelActivity:GetSpecialActivity(ModelActivity.MODEL_ACTIVITY_TYPE_4111)
    --     if not activityData then
    --         return
    --     end
    --     GF.OpenWnd("UIAct4111", { sid = activityData.sid })
    --     gLxTKData:OnMainUIActivityClick(activityData)
    -- end)
    self:SetWndClick(self.mMerchantBtn, function()
        self:OnClickMerchantBtn()
    end)
    self:SetWndClick(self.mMerchantContentContentBtn, function()
        self:OnClickMerchantBtn()
    end)
    self:SetWndClick(self.mMerchantContentImg, function()
        self:OnClickMerchantBtn()
    end)

    local ref1 = GameTable.FeatureOpenRef[gModelRedPoint.FUNC_PRE_VIEW1]
    local ref2 = GameTable.FeatureOpenRef[gModelRedPoint.FUNC_PRE_VIEW2]
    self:SetTextTile(self.mFuncPreView1, ccLngText(ref1.name))
    self:SetTextTile(self.mFuncPreView2, ccLngText(ref2.name))

    self:SetWndClick(self.mFuncPreView1, function()
        self:OnClickBtnFuncPreView()
    end)
    self:SetWndClick(self.mFuncPreView2, function()
        self:OnClickBtnFuncPreView()
    end)
end
function UIMCity:UIDragOnBegin(dragKey, eventData)

    if dragKey == "myDraw" then
        self._bMove = true
        self:StopScroll()
    end

end

function UIMCity:GetActivityTranByModel(modelId)
    for k, v in pairs(self._activityItemList) do
        for k1, v1 in pairs(v) do
            if not k1.isSurveyData or not k1.isRecharge then
                if k1.actData.model == modelId then
                    return self:FindWndTrans(v1, 'Btn')
                end
            end
        end
    end
end

--endregion --------------------------------------------------------------------------------------
--变强的刷新--目前先屏蔽掉
function UIMCity:RefreshStrongShow()
    if PRODUCT_G_VER == 1 then
        return -- ios写死屏蔽
    end

    --if gLGameLanguage:IsUSARegion() then
    --    --CS.ShowObject(self.mStrongBtn, true)
    --    return
    --end
    -- local level = GameTable.CityMapConfRef['strongLvVariety']【Z主城场景】主城场景相关配置调整（客户端）
    local level = GameTable.SnakeRoleConfigRef['strongLvVariety']
    local showInHur = gModelPlayer:GetPlayerLv() < level

    CS.ShowObject(self.mStrongBtn, showInHur)

    local tran = self:FindWndTrans(self.mTopFuncBg, 'bianqiang')
    CS.ShowObject(tran, not showInHur)
end

function UIMCity:OnlineRewardCd(item, itemdata)
    local _sid = itemdata.actData.sid
    if not _sid then
        return
    end
    local page = gModelActivity:GetActivityPagesBySid(_sid, 1)
    local isCur = self._OffLineReqSid == _sid
    if not page then
        if isCur then
            return
        end
        gModelActivity:OnActivityPageReq(_sid)
        self._OffLineReqSid = _sid
        return
    else
        if isCur then
            self._OffLineReqSid = nil
        end
    end

    local onlineShowEntryId = self._onlineShowEntryId

    local onlineData = gModelActivity:GetOnlineRewardData(_sid)
    self._onlineData = onlineData
    local cureIndex = onlineData and onlineData.curIndex or 0
    if cureIndex > 0 then
        local goal = onlineData.goal
        local schedule = onlineData.schedule
        local status = onlineData.status
        local curEntry = onlineData.curEntry
        if curEntry.entryId ~= onlineShowEntryId then
            local items = curEntry.items
            local reward = items[1]
            local imageBg = self:FindWndTrans(item, "ImageBg")
            local icon = self:FindWndTrans(item, "Icon")
            local iconStr = gModelGeneral:GetCommonItemImgRef(reward)
            CS.ShowObject(imageBg, true)
            if icon then
                self:SetWndEasyImage(icon, iconStr, function()
                    CS.ShowObject(icon, true)
                end)
            end
        end
        self._onlineShowEntryId = curEntry.entryId
        if status == 0 then
            local passTime = Time.RawUnityEngineTime.realtimeSinceStartup - onlineData.time
            if passTime < 0 then
                passTime = 0
            end
            local leftTime = goal - schedule - passTime

            if leftTime < 0 and passTime > 2 and not onlineData.isReqing then
                --local nowSinceTime = Time.RawUnityEngineTime.realtimeSinceStartup
                --if nowSinceTime >= onlineData.nextTime then
                --    onlineData.isReqing = true
                --    onlineData.nextTime = Time.RawUnityEngineTime.realtimeSinceStartup + 2
                --    gModelActivity:OnActivityPageReq(_sid)
                --    return
                --end
            end
            leftTime = leftTime < 0 and 0 or leftTime
            local showStr = leftTime <= 0 and ccClientText(14801) or nil
            self:CommonSetTimeText(item, leftTime, showStr, true)
        else
            self:CommonSetTimeText(item, 0, ccClientText(14801), true)
        end
    else
        self:CommonSetTimeText(item, 0, ccClientText(28502), true)
    end
end

function UIMCity:RemoveResultItem(showData)
    table.removeidata(self._showResultList, showData)
    self._objPool:ReturnObj(showData.tran)

    local ret = self:CheckWaitResult()
    if ret == 2 then
        self:TweenResult()
    end
end

function UIMCity:SetTime(text, _giftInfo, giftType)
    if not text or not _giftInfo then
        return
    end
    local time = GetTimestamp()
    local endTime = _giftInfo.endTime / 1000
    local timespan = endTime - time
    if (timespan <= 0) then
        --if(not self._refreshActPopData)then
        --	self._refreshActPopData = true
        --	gModelActivity:OnActivityPageReq(_giftInfo.sid)
        --end
        --self:TimerStop(self._giftCountDownKey)
        return
    end
    local timeStr = LUtil.FormatTimespanToMin2(timespan)
    --self:SetWndText(text, string.replace(ccClientText(14913), timeStr))
    self:SetWndText(text, timeStr)

    if not giftType ~= 0 then
        return
    end
    local _giftTim = self._giftTime
    _giftTim = _giftTim + 1
    local giftEnter = gModelPopupGift:GetPopupGiftConfigRefByKey("PopupGiftEnterShow")
    if _giftTim > giftEnter then
        self._giftTime = 1
        self:SetTowee(self._giftCurTweenKey)
    else
        self._giftTime = _giftTim
    end
end

function UIMCity:RefreshEffBtnList()
    local btnFuncList = self._btnFuncList
    if not btnFuncList then
        return
    end
    local effName
    for k, v in pairs(btnFuncList) do
        effName = v.effName
        local btn = v.btn
        local useEffTxt = not string.isempty(effName)
        if useEffTxt then
            local Image = self:FindWndTrans(btn, "Image")
            local Eff = self:FindWndTrans(btn, "Eff")
            local instanceId = Eff:GetInstanceID()
            self:CreateWndEffect(Eff, effName, instanceId, 100, false, false, 0, function(dpTrans)
                dpTrans.gameObject:SetActive(true)
                CS.ShowObject(Image, false)
            end)
        end
    end
end

function UIMCity:ShowBtnDeSelect(index)
    self:ShowTrans(self._btnBgList[index], false)
    local root = self._btnImgList[index]
    if root then
        local text = self:FindWndTrans(root, "UIText")
        local str = self._btnStrs[index]
        local selectText = self:FindWndTrans(root, "UIText_Select")

        --使用默认颜色
        --str = LUtil.FormatColorStr(str, "#244CB2")
        self:SetWndText(text, str)
        self:SetWndText(selectText, str)

        if self._isForeign then
            local textTran = LxUiHelper.FindXTextCtrl(text)
            textTran.characterSpacing = 0

            local selectTextTran = LxUiHelper.FindXTextCtrl(selectText)
            selectTextTran.characterSpacing = 0

        end

        self:ShowTrans(text, true)
        self:ShowTrans(selectText, false)
    end
end

--endregion --------------------------------------------------------------------------------------
-------------------------/按钮事件-----------------------------------------


function UIMCity:RefreshFunctionOpen()
    for k, v in pairs(self._functionBtns) do
        local isShow = gModelFunctionOpen:CheckIsShow(k)
        CS.ShowObject(v, isShow)
    end

    for k, v in pairs(self._bottomLock) do
        local isOpen = gModelFunctionOpen:CheckIsOpened(k)
        local lockTran = self:FindWndTrans(v.rootTran, "lock")
        --if(k == 36000001)then
        --	local isShow = gModelFunctionOpen:CheckIsOpened(k)
        --	CS.ShowObject(v.rootTran, isShow)
        --end
        CS.ShowObject(lockTran, not isOpen)
        local image = self:FindWndTrans(v.imageRoot, "Image")
        local color = Color.New(1, 1, 1, 1)
        if not isOpen then
            color = Color.New(0, 0, 0, 1)
        end
        self:SetWndImageColor(image, color)
    end

    -- self:ShowPrePost()【G功能预告】删除玩法预告机制（客户端&服务端）

    if not self._characterBtnShow then
        self:RefreshCharacterBtnShow()
    end
end

function UIMCity:VipServiceOpt()
    local activityList = gModelActivity:GetEarlyActivity(ModelActivity.MODEL_ACTIVITY_TYPE_102)
    if (activityList) then
        if gModelActivity:IsHasPackId(activityList.packId) then
            gModelActivity:CommonActJump(activityList.sid)
        end
    end
end
function UIMCity:UIDragOnDrag(dragKey, eventData)
    local canDrag = gModelChat:GetChatSetValue(7)

    if dragKey == "wndMainCitychatBtn" then
        if canDrag then
            self:SetDragItemPos(self.mChatBtnRoot, eventData)
        end
    end

    if dragKey == "myDraw" then
        local moveX = self.mItemRoot.localPosition.x

        local pageIndex = self._pageIndex
        if moveX > 0 then
            if pageIndex - 1 <= 0 then
                self:RetSetRootPos()
                self:StartScroll()
                return
            end
        else
            if pageIndex + 1 > self._mainEntraceDataMax then
                self:RetSetRootPos()
                self:StartScroll()
                return
            end
        end

        if moveX >= self._changeDistanceX then
            self:MoveRoot(UIMCity.MOVE_RIGHT)
        elseif moveX <= -self._changeDistanceX then
            self:MoveRoot(UIMCity.MOVE_LEFT)
        else
            local curPos = Vector3.New(moveX, 0, 0)
            self.mItemRoot.localPosition = curPos
        end
    end
end

function UIMCity:SetActNameTextMoveData(itemTrans, isMove)
    if not self._actNameMoveSeqKeyList then
        self._actNameMoveSeqKeyList = {}
    end

    local instanceId = itemTrans:GetInstanceID()
    local curSeqTweenKey = self._nameMoveSeqKey .. instanceId
    self._actNameMoveSeqKeyList[curSeqTweenKey] = isMove
end

function UIMCity:BagOpt()
    local wndName = "UIBags"
    GF.OpenWndBottom(wndName)
end

function UIMCity:ReceiveResultData(combatResult)
    if not self._showResultList then
        self._showResultList = {}
    end
    local cnt = #self._showResultList
    if cnt >= 3 or self._isResultTweening then
        local waitResultList = self._waitResultList or {}
        table.insert(waitResultList, combatResult)
        self._waitResultList = waitResultList
        return
    end

    local template = self._objPool:GetObj()

    local operPara = gModelBattle:GetTipOperPara(combatResult.combatType)

    local data = {
        isNew = true,
        index = 1,
        tran = template,
        itemdata = combatResult,
        operType = operPara.operType,
        operWaitEnd = GetTimestamp() + operPara.operWait,
        autoWaitEnd = GetTimestamp() + operPara.autoWait + operPara.operWait,
        operWait = operPara.operWait,
        autoWait = operPara.autoWait,
        canOper = operPara.operWait <= 0,
    }

    self:SetResultItem(template, combatResult, data)
    CS.SetParentTrans(template, self.mResultPart)
    CS.ShowObject(template, true)
    template.localPosition = self._rPosList[4]
    table.insert(self._showResultList, data)

    self:TweenResult()

    self:CheckStartResultTimer()
end

function UIMCity:RefreshMainEntraceList()
    self.originalDataList = gModelFunctionOpen:GetForeshowList(true)
    self._mainEntraceDataMax = #self.originalDataList
    if self._mainEntraceDataMax == 0 then
        CS.ShowObject(self.mMainEntrance, false)
        return
    end

    self:UIDragSetItem("myDraw", "AniRoot/MainEntrance/PageList/ItemRoot", CS.YXUIDrag.DragMode.DragOrigin,
            self._mainEntraceDataMax > 1)

    self:CalculateDataList()
    self:UpDataItem()
    self:InitPoint()
    self:RefreshPoint()
end

function UIMCity:OnOperBattleResult(wndName)
    local combatRecord = nil
    --if wndName == "UIDreamFountainWin" then
    --    combatRecord = { [LCombatTypeConst.COMBAT_DUNGEON_DAILY] = true }
    --else
    combatRecord = gModelFunctionOpen:GetWndRelaCombatType(wndName)
    --end
    if table.isempty(combatRecord) then
        return
    end
    local showData = nil
    if self._showResultList then
        for k, v in ipairs(self._showResultList) do
            if combatRecord[v.itemdata.combatType] then
                showData = v
                break
            end
        end
    end

    if showData then
        local itemdata = showData.itemdata
        itemdata.isFromBack = false
        self:OpenResultDetail(showData)
        return
    end

    if self._waitResultList then
        local result = nil
        local cnt = #self._waitResultList
        for k = cnt, 1, -1 do
            local data = self._waitResultList[k]
            if combatRecord[data.combatType] then
                result = data
                table.remove(self._waitResultList, k)
                break
            end
        end
        if result then
            result.isFromBack = false
            gModelBattle:OpenAccountRelaWnd(result.wndName, result)
        end
    end
end

function UIMCity:OnClickBtnFuncPreView()
    GF.OpenWnd("UIFoction")
end

function UIMCity:InitTopShow()
    local lvl = gModelPlayer:GetGradeLevel()
    local cfg = gModelGrade:GetGradeLvRefByRefId(lvl)

    if self._isForeign then
        CS.ShowObject(self.mGradeIconBg_enus, true)
        CS.ShowObject(self.mGradeTitle_enus, true)
        CS.ShowObject(self.mGradeIconBg, false)
        self:SetWndText(self.mGradeTitle_enus, ccLngText(cfg.name))
    else
        CS.ShowObject(self.mGradeIconBg_enus, false)
        CS.ShowObject(self.mGradeIconBg, true)
        CS.ShowObject(self.mGradeTitle, true)
        self:SetWndText(self.mGradeTitle, ccLngText(cfg.name))
    end

end

function UIMCity:SettingOpt()
    gModelPlayerSpace:OpenSpaceWnd(gModelPlayer:GetPlayerId(), 4)
end

function UIMCity:DailyGiftBagIntegralCD(item, itemdata)
    if not CS.IsValidObject(item) then
        return
    end
    local nDayTime = LUtil.GetNextDayTimes(GetTimestamp(), 1)
    local lostTime = nDayTime - GetTimestamp()
    if lostTime <= 1 then
        --零点重置
        return
    end

    self:CommonSetTimeText(item, lostTime)
end

function UIMCity:_CreateActEffFunc(trans, eff, instanceId, bDefaultSortNum)
    local effData = {
        trans = trans,
        effName = eff,
        effKey = instanceId,
        addMask = true,
        bDefaultSortNum = bDefaultSortNum,
    }
    self:CreateWndEffect_Ex(effData)
end

function UIMCity:RefreshJaServiceBtnShow()
    local isJapan = gLGameLanguage:IsJapanRegion()
    local isGMOpen = gLGameLogin:IsOpenGm()

    isJapan = false --日本不显示

    CS.ShowObject(self.mJaService, isJapan and isGMOpen)
end

--endregion --------------------------------------------------------------------------------------

--region 主界面右边区域 --------------------------------------------------------------------------------
--右边区域需要的初始化
function UIMCity:InitHudrleData()
    self._btnFuncList = {
        [1] = {
            btn = self.mFriendBtn,
            textid = 13404,
            func = function()
                self:FriendOpt()
            end
        },
        [2] = {
            btn = self.mMailBtn,
            textid = 13406,
            func = function()
                self:MailOpt()
            end
        },
        [3] = {
            btn = self.mRangBtn,
            textid = 13407,
            func = function()
                self:RangOpt()
            end
        },
        [4] = {
            btn = self.mVideoBtn,
            textid = 21539,
            func = function()
                self:VideoOpt()
            end
        },
        [5] = {
            btn = self.mStrengBtn,
            textid = 13405,
            func = function()
                self:StrengOpt()
            end
        },
        [6] = {
            btn = self.mBulletinBtn,
            textid = 13408,
            func = function()
                self:BulletinOpt()
            end
        },
        [7] = {
            btn = self.mGiftCodeBtn,
            textid = 14001,
            func = function()
                self:OnClickGiftCode()
            end
        },
        [10] = {
            btn = self.mTaskBtn,
            textid = 13401,
            func = function()
                self:TaskOpt()
            end
        },
        [11] = {
            btn = self.mBagBtn,
            textid = 13402,
            func = function()
                self:BagOpt()
            end
        },
        --[12] = { btn = self.mActGiftBtn, textid = 13400, effName = "ui_fx_zhujiemianlibao", func = function()
        --    self:GiftOpt()
        --end },
        [12] = {
            btn = self.mActGiftBtn,
            textid = 13400,
            func = function()
                self:GiftOpt()
            end
        },
        [13] = {
            btn = self.mStrongBtn,
            textid = 13405,
            func = function()
                self:StrengOpt()
            end
        },
        [14] = {
            btn = self.mSettingBtn,
            textid = 11545,
            func = function()
                self:SettingOpt()
            end
        },
        [15] = {
            btn = self.mTopFriendBtn,
            textid = 13404,
            func = function()
                self:FriendOpt()
            end
        },
        [16] = {
            btn = self.mTopRankBtn,
            textid = 13407,
            func = function()
                self:RangOpt()
            end
        },
        [17] = {
            btn = self.mTopMailBtn,
            textid = 13406,
            func = function()
                self:MailOpt()
            end
        },
        [18] = {
            btn = self.mTopSettingBtn,
            textid = 13417,
            func = function()
                self:SettingOpt()
            end
        },
        [19] = {
            btn = self.mVipServiceBtn,
            textid = 13417,
            func = function()
                self:VipServiceOpt()
            end
        },
        [20] = {
            btn = self.mCharacterBtn,
            textid = 153,
            func = function()
                self:OnClickCharacterOpt()
            end
        },
        [21] = {
            btn = self.mJaServiceBtn,
            textid = 141,
            func = function()
                self:OnClickServiceJa()
            end
        },
    }

    if PRODUCT_G_VER == 1 then
        --ios 写死屏蔽
        CS.ShowObject(self.mStrongBtn, false)
        CS.ShowObject(self.mTaskBtn, false)
        CS.ShowObject(self.mBulletinBtn.parent, false)
        CS.ShowObject(self.mVideoBtn.parent, false)
        CS.ShowObject(self.mRangBtn.parent, false)
        CS.ShowObject(self.mStrengBtn.parent, false)
    end

    self._hudleTopFunc = {
        [1] = { openid = 12000040, trans = self.mLuxiang },
    }
end
--endregion
function UIMCity:OnClickCharacterOpt()
    gLSdkImpl:CallMethod(LSdkMethod.CallSdkMemberCenter)
end

function UIMCity:OnTimer(key)
    if key == self._delayShowFinger then
        self:CheckShowFinger()
    elseif key == self._delayOnlineReqCountDownKey then
        if self._OnlineReqSid then
            self:TimerStop(self._delayOnlineReqCountDownKey)
            gModelActivity:OnActivityPageReq(self._OnlineReqSid)
        end
    elseif key == self._actCountDownKey then
        self:ShowActCountDown()
    elseif key == self._giftCountDownKey then
        self:SetGiftCountDownTime()
    elseif (self._characterRedTimeKey == key) then
        if not self._nextRefreshCharacterRedTime or GetTimestamp() >= self._nextRefreshCharacterRedTime then
            self:GetCharacterRedPointState()
        end
        -- elseif (self._enjoyMonthCardTimeKey == key) then
        --     if self._enjoyMonthCardDurationTime then
        --         self:SetEnjoyMonthCardCD()
        --     end
    elseif (self._nameMoveTimeKey == key) then
        if self._isShowActNameRoll then
            self:ShowActNameTextMove()
        end
    elseif (self._merchantTimerKey == key) then
        self:SetMerchantCD()
    elseif key == "_maincityShowRecordCheck" then
        local show = table.isempty(self._maincityShowRecord)
        self:SetWndVisible(show)

    elseif key == self._chatCutTimeKey then
        self._chatStarCutTime = self._chatStarCutTime - 1
        local isAir = gModelChat:GetChatSetValue(7)
        if self._chatStarCutTime <= 0 and isAir then
            if self.mChatAirPop.localScale.x > 0 then
                self:OnChatAirPopOptBtnClick()
            end
        end
    end
end

function UIMCity:CheckShowFinger()
    local isAllow = false
    local isClean = gLGameUI:IsCurMainClean()
    if isClean then
        local combatType = LCombatTypeConst.COMBAT_MAIN
        local inFight = gLFightManager:IsCombatTypeInFight(combatType)
        if not inFight then
            isAllow = true
        end
    end

    local showTip = gModelGuide:CheckShowTipWnd()
    if isAllow and showTip and not self.isTishen then
        local para = {
            refId = 170021,
            func = function()
                FireEvent(EventNames.CHANGE_MAIN_BTN, LMainBtnIndexConst.ADVENTURE)
            end
        }
        gModelGeneral:OpenUIOrdinTips(para)
    end

    local showFinger = gModelGuide:CheckShowFinger() and isAllow

    CS.ShowObject(self.mFingerPart, showFinger)

    local key = "guideFinger"
    if not showFinger then
        self:DestroyWndEffectByKey(key)
        return
    end

    local effectName = "fx_ui_shou_2"
    self:CreateWndEffect(self.mFingerEff, effectName, key, 100, nil, nil, 10)
end

function UIMCity:SetATPlayerName(msg, name)
    local str = msg
    local text = string.match(msg, "%@" .. name)
    if (text) then
        str = string.gsub(str, text, "<u>" .. text .. "</u>", 1)
    end
    return str
end

function UIMCity:ActivityShowEndTimeCd(item, itemdata)
    local sid = itemdata.actData.sid
    local actData = gModelActivity:GetActivityBySid(sid)
    if not actData then
        return
    end
    local endTime = actData.endTime
    local showEndTime = actData.showEndTime
    if showEndTime and showEndTime > endTime then
        endTime = showEndTime
    end
    local time = tonumber(endTime)
    if not time then
        return
    end
    local timeLeft = time - GetTimestamp()
    if timeLeft < 0 then
        if time > 0 then
            self:RefreshActivityList()
        end
        return
    end
    if not CS.IsValidObject(item) then
        return
    end
    self:CommonSetTimeText(item, timeLeft)
end

function UIMCity:FriendOpt()
    GF.OpenWndBottom("UIPYWin")
end

function UIMCity:IsShowWndAssistBtn()
    CS.ShowObject(self.mAssistBtn, gModelGuild:GetBoolHint())
    self:PlayEff(self.mAssistBtn, "fx_ui_lianmenghuzhu", "fx_ui_lianmenghuzhu")
end

function UIMCity:CheckShowRed(showActData)
    if showActData.isSurveyData then
        return not self._isClickSurvey
    end
    if showActData.isRecharge then
        return false
    end
    --检查非活动红点
    local redPoint = showActData.actData.redPoint
    local model = showActData.actData.model
    
    -- 首次打开需要的红点，没有则后续使用服务端下发的红点
    if model == ModelActivity.MODEL_ACTIVITY_TYPE_168 then
        local showRed = not LUtil.IsToDay(tonumber(LPlayerPrefs.openActivity82) or 0)
        if showRed then
            return true
        end
    end


    if model == ModelActivity.MODEL_ACTIVITY_TYPE_172 then
        local showRed = not LUtil.IsToDay(tonumber(LPlayerPrefs.openActivity172) or 0)
        if showRed then
            return true
        end
    end

    if model == ModelActivity.MODEL_ACTIVITY_TYPE_10009 then
        local showRed = gModelSubscriber:CheckTTFeedSubscriberRP()
        if showRed then
            return true
        end
    end

    if redPoint and redPoint > 0 then
        local isClick = gModelRedPoint:GetSpecialRedPointMapIsClickBySid(showActData.actData.sid)
        local showRed = gModelRedPoint:CheckShowRedPoint(redPoint)
        return showRed and not isClick
    elseif model == ModelActivity.DREAM_SCHOOL then
        local showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.DREAM_SCHOOL_PARENT)
        return showRed
    elseif model == ModelActivity.MODEL_DAILYGIFTBAG then
        return false
    elseif model == ModelActivity.BUILTIN_ACTIVITY_10002 then
        local showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.REDPOINT_ID_23000000)
        return showRed
    elseif model == ModelActivity.ANNIVERSARY_SIGN_80 then
        local showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.REDPOINT_ID_10450000)
        local activityRPMap = gModelRedPoint:GetActRedPointMap(showActData.actData.sid)
        if (activityRPMap and showRed) then
            return showRed
        end

        local sid = showActData.actData.sid
        local red = gModelActivity:GetSaveRedBySid(sid)
        local showRed = gModelRedPoint:CheckActivityShowRed(sid)
        return showRed or red
        -- elseif model == ModelActivity.MODEL_ACTIVITY_TYPE_112 then
        --     local sid = showActData.actData.sid
        --     local activityDataS = gModelActivity:GetActivityBySid(sid)
        --     if not activityDataS then
        --         return
        --     end
        --     local dataS = JSON.decode(activityDataS.moreInfo)
        --     local freeNum = dataS.freeNum or 0                --剩余次数
        --     local extraFreeNum = dataS.extraFreeNum or 0    --额外抽取次数
        --     return freeNum > 0 or extraFreeNum > 0
        -- elseif model == ModelActivity.MODEL_GAME_TYPE_DOG then
        --     return gModelLittleGames:GetMiniGameRedPointShowByGameType(ModelLittleGames.GAME_TYPE_DOG)
        --elseif showActData.actData.model == ModelActivity.ACCOUNT_BIND_JA then
        --    local isClick = gModelRedPoint:GetSpecialRedPointMapIsClickBySid(showActData.actData.sid)
        --    local showRed = gLSdkImpl:CallMethod(LSdkMethod.GetIsSdkAccountBind) and not gModelPlayer:InAccoutBindingReward()
        --    return showRed or not isClick
    elseif (model == ModelActivity.NATURAL_PARTNER) then
        local showRed = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.NATURAL_PARTNER_ENTRANCE)
        return showRed
    elseif (model == ModelActivity.MODEL_ACTIVITY_TYPE_153) then
        local showRed = not LUtil.IsToDay(tonumber(LPlayerPrefs.actOpenSerGiftRed) or 0)
        return showRed
    elseif (model == ModelActivity.MODEL_ACTIVITY_TYPE_156) then
        local sid = showActData.actData.sid
        local showRed = not LUtil.IsToDay(tonumber(LPlayerPrefs.actFarmDayRed) or 0)
        local isMature = gModelFarm:CropMatureRed() or gModelFarm:GetFarmStealNum(sid) > 0
        return showRed or isMature or gModelFarm:ActivateDogRed(showActData.actData.sid) or gModelFarm:ZhanlingRed(sid) or gModelFarm:DropScoreRed()
        -- elseif (model == ModelActivity.MODEL_ACTIVITY_TYPE_154) then
        --     local sid = showActData.actData.sid
        --     if not gModelActivity:IsClickActivityRed(sid) then
        --         return true
        --     end
        --     local showRed = gModelRedPoint:CheckActivityShowRed(sid)
        --     return showRed
    elseif (model == ModelActivity.MODEL_ACTIVITY_TYPE_103) then
        --check的顺序 是否有未领取的奖励+当天是否点击过  -false-> 是否有未领取已激活的奖励
        local showRed = false
        local curDayClick = gModelActivity:GetFbOpenState()
        local noGet = false
        local canGet = false
        local checkName = {
            "daily1",
            "receive1",
            "receive2",
        }

        local sid = showActData.actData.sid

        local activityData = gModelActivity:GetActivityBySid(sid)
        if not activityData then
            return showRed
        end
        --要刷新这个嘛 那么不用缓存的 去model类里面去取
        local activityMoreInfo = activityData:GetMoreInfo()

        for k, v in ipairs(checkName) do
            if not activityMoreInfo[v] then
                --判断可领取的状态
                noGet = true
                break
            end
        end

        showRed = noGet and (not curDayClick)

        if not noGet then
            return false
        end

        if not showRed then
            for i = 1, #checkName do
                canGet = gModelActivity:GetFBRewardCanGetList(sid, i)
                if canGet then
                    return canGet
                end
            end
        end

        return showRed
    elseif model == ModelActivity.PRIVILEGE_SHOP then
        local showRed = gModelRedPoint:CheckShowRedPoint(10401102)
        return showRed
    elseif model == ModelActivity.MODEL_ACTIVITY_TYPE_165 then
        local actData = showActData.actData
        local sid = actData.sid
        local showRed = gModelRedPoint:CheckActivityShowRed(sid)
        if not showRed then
            local moreInfo = JSON.decode(actData.moreInfo)
            local allActivation = moreInfo and moreInfo.allActivation or 0
            if allActivation == 0 then
                local webData = gModelActivity:GetWebActivityDataById(sid)
                if webData then
                    local config = webData.config
                    local puzzleNums = checknumber(config.puzzleNums)
                    if puzzleNums and puzzleNums > 0 then
                        local item = LxDataHelper.ParseItem_3(config.puzzleConsume)
                        if item then
                            if gModelGeneral:CheckItemEnough(item.itemId,item.itemNum) then
                                showRed = true
                            end
                        end
                    end
                end
            end
        end
        return showRed
    elseif model == ModelActivity.MODEL_ACTIVITY_TYPE_10003 then
        return gModelQuest:CheckHasIntiveFriendRP()
    elseif model == ModelActivity.MODEL_ACTIVITY_TYPE_34 then
        return gModelActivity:CheckModel34RP()
    elseif model == ModelActivity.MODEL_ACTIVITY_TYPE_10005 then
        return gModelActivity:CheckModel10005RP()
    else
        local sid = showActData.actData.sid
        local red = gModelActivity:GetSaveRedBySid(sid)
        local showRed = gModelRedPoint:CheckActivityShowRed(sid)

        if sid == 351 then
            if LOG_INFO_ENABLED then
                printInfoN2("cjh---------------------152---redpoint", "---------")
            end
        end
        if not showRed and not red then
            local data = showActData.actData
            local moreInfo = data:GetMoreInfo() or {}
            ---@type table
            local modelActRed = moreInfo.modelActRed
            if not string.isempty(modelActRed) then
                local modelArr = string.split(modelActRed, "|")
                for i, v in ipairs(modelArr) do
                    local arr = string.split(v, "=")
                    local dataList = gModelActivity:GetActivityDataByModelId(tonumber(arr[1]))
                    for j, k in ipairs(dataList) do
                        local uniqueJump = k.uniqueJump
                        if arr[2] and tonumber(arr[2]) == uniqueJump then
                            showRed = gModelRedPoint:GetActRedPointMap(k.sid)
                            break
                        end
                    end
                    if showRed then
                        break
                    end
                end
            end
            if not showRed then
                if model == ModelActivity.MODEL_ACTIVITY_TYPE_85 then
                    showRed = gModelActivity:CheckActivityRedPoint(sid)
                end
            end
        end
        return showRed or red
    end
end

function UIMCity:SetEnjoyMonthCardCD()
    --     local durationTime = self._enjoyMonthCardDurationTime - GetTimestamp()
    --     if durationTime <= 0 then
    --         self:ShowEnjoyMonthCard(false)
    --         return
    --     end

    --     local timeStr = LUtil.FormatTimespanCn(durationTime, { hTextId = 10371 })
    --     self:SetWndText(self.mEnjoyMonthCardTimeText, timeStr)
end

function UIMCity:OnDrawActivityItem(list, item, itemdata, itempos)
    local imageBg = self:FindWndTrans(item, "ImageBg")
    local Icon = self:FindWndTrans(item, "Icon")
    local layout = self:FindWndTrans(item, "layout")
    local layoutEn = self:FindWndTrans(item, "layoutEn")
    local Eff = self:FindWndTrans(item, "Eff")
    local EffName = self:FindWndTrans(item, "EffName")
    local redPoint = self:FindWndTrans(item, "redPoint")
    local BtnPoint = self:FindWndTrans(item, "Btn")
    local emphasisEffectRoot1 = self:FindWndTrans(item, "EmphasisEffectRoot1")
    local emphasisEffectRoot2 = self:FindWndTrans(item, "EmphasisEffectRoot2")
    local effSpine = self:FindWndTrans(item, "EffSpine")

    local metadata = list:GetMetaData()
    local listKey = metadata.listKey
    local uiItemMap = self._activityItemList[listKey]
    if not uiItemMap then
        uiItemMap = {}
        self._activityItemList[listKey] = uiItemMap
    end
    uiItemMap[itemdata] = item
    if itemdata.isSpecialMainCityAct then
        ---@type V_BIActivityFuncTypeRef
        local refData = itemdata.refData
        self:SetWndEasyImage(Icon, refData.icon, function()
            CS.ShowObject(Icon, true)
        end)

        local nameTranRoot = self:FindWndTrans(item, "TimeBg")
        local nameTran = self:FindWndTrans(item, "TimeBg/TimeText")
        self:SetWndText(nameTran, ccLngText(refData.name))
        CS.ShowObject(nameTranRoot, true)

        local effSpecialMainCity = string.split(refData.eff, "=")
        if checknumber(effSpecialMainCity[1]) == 1 then
            local eff_0 = CS.FindTrans(item, "Eff")
            CS.ShowObject(eff_0, true)
            self:CreateWndEffect(eff_0, effSpecialMainCity[2], "effSpecialMainCity" .. itempos, 100)
        end

        local actData = itemdata.actData
        local targetModel = itemdata.targetModel
        if targetModel and targetModel > 0 then
            local specialSid = actData.sid
            ---- 旧模版数据要保留
            if not self._iconSpeacialMainCityRedpointData then
                --未设置过 进行设置
                if specialSid and specialSid > 0 then
                    self._iconSpeacialMainCityRedpointData = {
                        specialSid = specialSid,
                        isFirst = true,
                    }
                    gModelActivity:ReqActivityConfigData(specialSid)
                end
            end
            if specialSid and specialSid > 0 then
                local showRed = gModelRedPoint:CheckActivityHasRed(specialSid)
                CS.ShowObject(redPoint, showRed)
            end

            self:SetWndClick(item, function()
                --gModelFunctionOpen:Jump( itemdata.actData.uniqueJump, self:GetWndName())
                --gModelFunctionOpen:Jump(10405121)
                GF.OpenWnd("UIActivityGiftModel4PopOld")
            end)
        else
            local specialSid = actData.sid
            if not gModelActivity:CheckFirstPop164(specialSid) then
                gModelActivity:SetFirstPop164(specialSid)
                gModelActivity:ReqActivityConfigData(specialSid)
            end

            local showRed = gModelRedPoint:CheckActivityHasRed(specialSid)
            CS.ShowObject(redPoint, showRed)

            self:SetWndClick(item, function()
                gModelActivity:CommonActJump(specialSid)
            end)
        end
        return
    end

    local dataMap = self._activityRecord[listKey]
    if not dataMap then
        dataMap = {}
        self._activityRecord[listKey] = dataMap
    end
    dataMap[itempos] = itemdata

    local isShowActNameRoll = self._isShowActNameRoll and CS.IsValidObject(layoutEn)
    local layoutRoot, layoutHideRoot, layoutNameTextPath
    if isShowActNameRoll then
        layoutRoot = layoutEn
        layoutHideRoot = layout
        layoutNameTextPath = self._layoutNameTextPathEn
    else
        layoutRoot = layout
        layoutHideRoot = layoutEn
        layoutNameTextPath = self._layoutNameTextPath
    end
    local layoutNameText = self:FindWndTrans(layoutRoot, layoutNameTextPath)
    local layoutTimeBg = self:FindWndTrans(layoutRoot, "TimeBg")
    local TimeBgTimeText = self:FindWndTrans(layoutTimeBg, "TimeText")
    CS.ShowObject(layoutRoot, true)
    CS.ShowObject(layoutHideRoot, false)
    CS.ShowObject(imageBg, false)

    if itemdata.isSurveyData then
        CS.ShowObject(layoutTimeBg, false)
        CS.ShowObject(layoutNameText, false)
        CS.ShowObject(EffName, false)
        CS.ShowObject(Eff, false)
        CS.ShowObject(effSpine, false)
        local isShowLayoutNameText = not string.isempty(itemdata.title)
        if isShowLayoutNameText then
            CS.ShowObject(layoutNameText, true)
            self:SetWndText(layoutNameText, itemdata.title)
            self:SetWndText(EffName, itemdata.title)
        end
        self:SetWndEasyImage(Icon, itemdata.iconPath, function()
            CS.ShowObject(Icon, true)
        end)
        self:SetWndClick(BtnPoint, function()
            self._isClickSurvey = true
            self:RefreshActivityRed()
            local surveyData = gLSdkImpl:CallMethod(LSdkMethod.GetSurveyData)
            if not surveyData then
                GF.ShowMessage(ccClientText(13443))
            else
                FireEvent(EventNames.CLICK_SURVEY_ENTER)
                gLSdkImpl:CallMethod(LSdkMethod.OpenSurvey, 0, 0, -1, -1, surveyData.linkUrl)
            end
        end)

        local showRed = self:CheckShowRed(itemdata)
        CS.ShowObject(redPoint, showRed)
        self:ResetRedSortingOrder(redPoint)
        return
    elseif itemdata.isRecharge then
        CS.ShowObject(layoutTimeBg, false)
        CS.ShowObject(EffName, false)
        CS.ShowObject(Eff, false)
        CS.ShowObject(effSpine, false)
        CS.ShowObject(layoutNameText, true)
        self:SetWndText(layoutNameText, itemdata.title)
        self:SetWndEasyImage(Icon, itemdata.iconPath, function()
            CS.ShowObject(Icon, true)
        end)
        self:SetWndClick(BtnPoint, function()
            gLSdkImpl:CallMethod(LSdkMethod.CheckHasSceneEntryInfo,1)
        end)

        local showRed = self:CheckShowRed(itemdata)
        CS.ShowObject(redPoint, showRed)
        self:ResetRedSortingOrder(redPoint)
        return
    end

    local actData = itemdata.actData

    local isSpecialAct = itemdata.isSpecialAct
    local iconEffect = actData.iconEffect
    --local iconName = actData.iconName
    local iconPath = nil
    local title = nil
    if isSpecialAct then
        iconPath = itemdata.specialShowSceneIcon
        title = itemdata.specialShowTitle
    else
        iconPath = actData.showSceneIcon
        title = actData and actData.title
    end

    if isShowActNameRoll then
        title = string.gsub(title, "<br>", "")
    end

    CS.ShowObject(layoutTimeBg, false)
    CS.ShowObject(layoutNameText, false)
    CS.ShowObject(EffName, false)

    local actModel = actData.model

    if actModel == ModelActivity.EIGHTLOGIN or actModel == ModelActivity.MODEL_ACTIVITY_TYPE_155 then
        local moreInfo = actData:GetMoreInfo()
        local showTime = false
        local endTime = actData.endTime
        if moreInfo and moreInfo.overTime then
            if not string.isempty(moreInfo.overTime) then
                --八天登录过期时间
                local milliSec = tonumber(moreInfo.overTime) or 0
                endTime = milliSec / 1000
            end
            local timeLeft = endTime - GetTimestamp()
            showTime = timeLeft > 0
        end
        CS.ShowObject(layoutTimeBg, showTime)
    end

    local special = false
    local showIconEffect = string.isempty(iconEffect)
    if showIconEffect then
        if actModel == ModelActivity.DREAM_SCHOOL then
            iconEffect = self:GetActivityEffName(itemdata)
            special = not string.isempty(iconEffect)
        end
    end

    local showIconBg = true
    showIconEffect = not string.isempty(iconEffect)
    local effType = self:GetActivityEffType(actData) --eff还是spine
    if showIconEffect then
        showIconBg = self:ShowActivityIcon(actData)

        if effType == 1 then
            self:CreateActEff(Eff, iconEffect, listKey, special)
        else
            self:CreateActSpine(effSpine, iconEffect, listKey, special)
        end
        --self:CreateActEff(Eff, iconEffect, listKey,special)
        --self:ResetRedSortingOrder(Eff)
        --self:CreateActSpine
    end
    CS.ShowObject(Eff, showIconEffect and effType == 1)
    CS.ShowObject(effSpine, showIconEffect and effType == 2)


    --if not (string.isempty(iconName) or string.isempty(title)) then
    --	CS.ShowObject(EffName, true)
    --	self:SetWndText(EffName, title)
    --end

    local isShowLayoutNameText = not string.isempty(title)
    if isShowLayoutNameText then
        CS.ShowObject(layoutNameText, true)
        self:SetWndText(layoutNameText, title)
        self:SetWndText(EffName, title)
    end

    if showIconBg then
        self:SetWndEasyImage(Icon, iconPath, function()
            CS.ShowObject(Icon, true)
        end)
    else
        CS.ShowObject(Icon, false)
    end
    self:SetWndClick(BtnPoint, function()
        self:OnActivityClick(itemdata)
    end)
    local showRed = self:CheckShowRed(itemdata)
    CS.ShowObject(redPoint, showRed)

    self:ResetRedSortingOrder(redPoint)



    -- ---优化需求 #11264----
    local emphasisEffName = actData.showEffect
    if (not emphasisEffName and actData.showCommonEffect ~= nil and actData.showCommonEffect ~= 0) then
        emphasisEffName = "ui_fx_huodongrukou"
    end

    --local emphasisEffName = "ui_fx_huodongrukou_down|ui_fx_huodongrukou"
    local isShowEmphasisEff = emphasisEffName and not string.isempty(emphasisEffName)
    if (isShowEmphasisEff) then
        local effArr = string.split(emphasisEffName, "|")
        if (effArr[1]) then
            self:CreateActEff(emphasisEffectRoot1, effArr[1], listKey .. "EmphasisEffect", false, 1)
        end
        if (effArr[2]) then
            self:CreateActEff(emphasisEffectRoot2, effArr[2], listKey .. "EmphasisEffect", false, 3)
        end
    end
    CS.ShowObject(emphasisEffectRoot1, isShowEmphasisEff)
    CS.ShowObject(emphasisEffectRoot2, isShowEmphasisEff)
    ----------


    if actModel == ModelActivity.MODEL_GAME_TYPE_SDK_RULING then
        self._sdkGameTran = BtnPoint
    end

    if isShowActNameRoll then
        --self:SetActNameTextMove(item, layoutNameText, isShowLayoutNameText)
        self:SetActNameTextMoveData(item, isShowLayoutNameText)
    end
end

function UIMCity:SetUnreadMsgRP()
    local showUnreadMsg = gLSdkImpl:CallMethod(LSdkMethod.GetUnreadMsgRP)
    CS.ShowObject(self.mGNUnreadMsgRP,showUnreadMsg)
    CS.ShowObject(self.mSTUnreadMsgRP,showUnreadMsg)
end

function UIMCity:SetMerchantCD()
    local durationTime = self._merchantEndTime - GetTimestamp()
    if durationTime <= 0 then
        self:ShowMerchant(false)
        return
    end
    local timeStr = LUtil.FormatTimespanCn(durationTime, { hTextId = 10371 })
    self:SetWndText(self.mMerchantTimeText, timeStr)
end

function UIMCity:CommonActivityCd(item, itemdata)
    local sid = itemdata.actData.sid
    local actData = gModelActivity:GetActivityBySid(sid)
    if not actData then
        return
    end
    local endTime = actData.endTime
    local time = tonumber(endTime)
    if not time then
        return
    end

    local showEndTime = tonumber(actData.showEndTime)

    local timeLeft = time - GetTimestamp()
    if showEndTime and showEndTime > 0 and showEndTime > time then
        local showTimeLeft = showEndTime - GetTimestamp()
        if showTimeLeft < 0 then
            self:RefreshActivityList()
            return
        end
    else
        if timeLeft < 0 then
            if time > 0 then
                self:RefreshActivityList()
            end
            return
        end
    end

    if timeLeft < 0 then
        timeLeft = 0
    end

    if not CS.IsValidObject(item) then
        return
    end
    self:CommonSetTimeText(item, timeLeft)
end

-- 初始化页点
function UIMCity:InitPoint()
    local allListData = self.originalDataList or {}
    self._pointList = self._pointList or {}
    for k, v in ipairs(allListData) do
        local trans = self._pointList[k]
        if not trans then
            local obj = CS.InstantObject(self.mPointRoot.gameObject)
            trans = obj.transform
            trans:SetParent(self.mPointParent, false)
            self._pointList[k] = trans
        end
        CS.ShowObject(trans, true)
    end

    for i = #allListData + 1, #self._pointList do
        CS.ShowObject(self._pointList[i], false)
    end

    CS.ShowObject(self.mPointParent.gameObject, #allListData > 1)
end

function UIMCity:InitMsgTween()
    self._isPlayChatTween = true
    --设置位置
    self.mText_Old.position = self.mChat_Center.position
    self.mText_New.position = self.mChat_Down.position

    --设置显示
    local canvas_old = self.mText_Old:GetComponent(typeofCanvasGroup)
    local canvas_new = self.mText_New:GetComponent(typeofCanvasGroup)

    canvas_old.alpha = 1
    canvas_new.alpha = 1

    self:DoMsgTween()
end

function UIMCity:SetStaticContent()
    self:SetWndText(CS.FindTrans(self.mGongNengBtn, "Text"), ccClientText(13403))

    for k, v in pairs(self._btnFuncList) do
        local textId = v.textid
        if textId and textId > 0 then
            local textTrans = self:FindWndTrans(v.btn, "Text")
            self:SetWndText(textTrans, ccClientText(textId))
            if gLGameLanguage:IsFrenchVersion() then
                self:InitTextLineWithLanguage(textTrans, -20)
            elseif gLGameLanguage:IsJapanRegion() then
                self:InitTextLineWithLanguage(textTrans, -40)
                self:InitTextSizeWithLanguage(textTrans, -2)
            end
        end
    end

    self:SetBtnName()

    self:SetWndText(self.mBubbleText, ccClientText(10786))
    --self:SetWndText(self.mCharacterText, ccClientText(153))

    if gLGameLanguage:IsJapanRegion() then
        --local group = self.mLayerVertical:GetComponent(typeVerticalLayoutGroup)
        --group.spacing = 14
    end

    self:CheckBottomBtnIsLock()
end

function UIMCity:OnDrawMainEntranceItem(tab, itemdata, index)
    local iconPath = itemdata.data.icon
    local iconTxtPath = itemdata.data.iconTxt
    self:SetWndEasyImage(tab.icon, iconPath)
    self:SetWndEasyImage(tab.iconTxt, iconTxtPath)
    self:SetWndClick(tab.item, function()
        self:OnClickItem(index)
    end)

    local showRed = false
    if itemdata.pb then
        showRed = gModelMainCity:CheckMainActivityRed(itemdata.pb)
    elseif itemdata.data then
        local redId = gModelRedPoint:GetRedIdByFuncId(itemdata.data.functionOpen)
        if redId then
            showRed = gModelRedPoint:CheckShowRedPoint(redId)
        end
    end
    self:SetRed(tab.item, not not showRed)
end

function UIMCity:IsShowMoreList()
    if gModelGuide:IsInGuide() then
        return true
    end

    return gModelActivity:IsMoreListShow()
end

function UIMCity:SetAirMsg(tran, data)
    self:MsgListItem(nil, tran, data)
end

--region 主界面上方区域 --------------------------------------------------------------------------------
function UIMCity:InitTopData()
end

-- 开始倒计时
function UIMCity:StarMainEntraceTimer()
    local timePara = {
        func = function()
            self:UpDateMainEntrace()
        end,
        callOnStart = false,
        loopcnt = -1,
        interval = 1,
        key = "mainEntraceTimerKey"
    }
    self:TimerStartImpl(timePara)
end

function UIMCity:TaskOpt()
    GF.OpenWndBottom("UIQst")
end

function UIMCity:SetChatAirPop()
    --配置  gModelChat:GetChatConfigRefByKey(key)  floatWindowWordsMax

    --文本
    local floatWindowWordsMax = gModelChat:GetChatConfigRefByKey("floatWindowWordsMax")
    floatWindowWordsMax = checknumber(floatWindowWordsMax)
    if floatWindowWordsMax > 0 then
        local msgText = self:FindWndTrans(self.mText_Old, "MsgText")
        LxUiHelper.SetSizeWithCurAnchor(msgText, 0, floatWindowWordsMax)
        msgText = self:FindWndTrans(self.mText_New, "MsgText")
        LxUiHelper.SetSizeWithCurAnchor(msgText, 0, floatWindowWordsMax)
        msgText = self:FindWndTrans(self.mText_Cur, "MsgText")
        LxUiHelper.SetSizeWithCurAnchor(msgText, 0, floatWindowWordsMax)
    end

    --气泡框
    local floatWindowLength = gModelChat:GetChatConfigRefByKey("floatWindowLength")
    floatWindowLength = checknumber(floatWindowLength)
    if floatWindowLength > 0 then
        LxUiHelper.SetSizeWithCurAnchor(self.mChatAirBg, 0, floatWindowLength)
    end
end

function UIMCity:RefreshInfo(refreshItem)
    -- 砖石
    local num = gModelItem:GetNumByRefId(ModelItem.ITEM_DIAMOND)
    num = LUtil.NumberCoversion(num)
    self:SetWndText(self.mMasonryNum, num)

    -- 金币
    num = gModelItem:GetNumByRefId(ModelItem.ITEM_GOLD)
    num = LUtil.NumberCoversion(num)
    self:SetWndText(self.mGoldNum, num)

    ---- 战力
    ----num = gModelPlayer:GetPlayerFightPower()
    --num = gModelPower:GetMainCityPower()
    --print("=== num = ",num,type(num))
    --num = tonumber(num)
    --self:SetWndText(self.mPowerNum,num)

    -- 等级
    num = gModelPlayer:GetPlayerLv()
    --num = LUtil.FormatHurtNumSpriteText(num,false)
    --self:SetXUITextText(self.mLvNum, num)
    self:SetWndText(self.mLvNum, num)
    -- vip等级
    num = gModelPlayer:GetVipLevel()
    num = tonumber(num)
    local showNum = 0
    if num >= 0 then
        showNum = num
    end
    self:SetWndText(self.mVipTex, string.replace(ccClientText(11942),showNum))
    CS.ShowObject(self.mVipObj, gModelFunctionOpen:CheckIsOpened(15000010))
    --if num >= 0 then
    --    self:SetWndText(self.mVipTex, LUtil.PowerNumberCoversion(num))
    --    local vipLvRef = gModelVip:GetRefByVipLv(num)
    --    if vipLvRef then
    --        local mainInterface = vipLvRef.mainInterface
    --        --local typeface = vipLvRef.typeface
    --        if not string.isempty(mainInterface) then
    --            local arr = string.split(mainInterface, "=")
    --            if LxUiHelper.IsImgPathValid(arr[1]) then
    --                --调整为使用名字来赋值
    --                self:SetWndEasyImage(self.mVipObj, arr[1], nil, true)
    --                if not string.isempty(arr[2]) then
    --                    local pos = LxDataHelper.ParseVector2NotEmpty3(arr[2])
    --                    self:SetAnchorPos(self.mVipObj, pos)
    --                end
    --            end
    --        end
    --        --if not string.isempty(typeface) then
    --        --	local arr = string.split(typeface,"|")
    --        --	local topColor = LUtil.ColorByHex_6(arr[1])
    --        --	local bottomColor = LUtil.ColorByHex_6(arr[2])
    --        --	LxUiHelper.SetTextColorGradient(self.mVipTex,topColor,topColor,bottomColor,bottomColor)
    --        --	if not string.isempty(arr[3]) then
    --        --		local pos = LxDataHelper.ParseVector2NotEmpty3(arr[3])
    --        --		self:SetAnchorPos(self.mVipTex, pos)
    --        --	end
    --        --end
    --    end
    --end

    -- 经验条计算
    local needExp = gModelPlayer:GetCurLevelTotalExp()
    local percentage
    if needExp == -1 then
        percentage = 0
    else
        num = gModelPlayer:GetPlayerExp()
        if refreshItem then
            num = gModelItem:GetNumByRefId(103001)
        end
        percentage = num / needExp
    end
    LxUiHelper.SetProgress(self.mExpImg, percentage)

    percentage = percentage > 1 and 1 or percentage
    percentage = percentage < 0 and 0 or percentage
    self.mExpEff.anchoredPosition = Vector2(self._expImageWidth * percentage, 0)

    --免费钻石+充值钻石（日本）
    if gLGameLanguage:IsJapanRegion() then
        self:RefreshMasonryMore()
    end

    self:RefreshItemChangeAct()
end
-------------------------按钮事件-----------------------------------------
function UIMCity:OnBottomBtnClick(index)
    --printInfoN2("cjh--1","关闭不需要保留的页面--如果这里还是没有关闭 那么就是没有注册之类的东西")
    if gModelBattle:IsExitPK(index) then
        --  printInfoN2("cjh--2","关闭不需要保留的页面--如果这里还是没有关闭 那么就是没有注册之类的东西")
        return
    end

    if self:IsCurBtn(index) then
        --printInfoN2("cjh--3","关闭不需要保留的页面--如果这里还是没有关闭 那么就是没有注册之类的东西")
        if index == BTN_COMBAT_INDEX then
            local inBattle = gLFightManager:IsFightIntFront(LCombatTypeConst.COMBAT_MAIN)
            if inBattle then
                return
            end
        else
            -- if index == 2 then
            --     return
            -- end

            local exceptWnds = self._exceptWnd[index]
            local para = {}
            if exceptWnds then
                for i, v in ipairs(exceptWnds) do
                    para[v] = true
                end
            end

            gLGameUI:CloseAllButExcept(para)
            --   printInfoN2("cjh--5","关闭不需要保留的页面--如果这里还是没有关闭 那么就是没有注册之类的东西")
            local openFunc = self._bottomBtnFunc[index]
            if openFunc then
                openFunc()
            end
        end
        return
    end
    --self:ShowTop(true,true)

    FireEvent(EventNames.ON_CLICK_MAIN_BTN, index)
    --gModelGeneral:ClearHistroyList()
    --  printInfoN2("cjh--6","关闭不需要保留的页面--如果这里还是没有关闭 那么就是没有注册之类的东西")
    if index == BTN_COMBAT_INDEX then
        gModelInstance:SetShowFormationTipsBubble()
    end

    local changeSuc, wndOpenName = self._bottomBtnFunc[index]()
    if not changeSuc then
        return
    end
    self:ChangeCurBtn(index)

    local extraWnds
    if wndOpenName then
        extraWnds = { [wndOpenName] = true }
    end
    self:OnSwitchToOther(index, extraWnds)
    self:ShowMasonryMore(false)
end

function UIMCity:SetMainCityShow(key, isShow, time)
    --print(string.format(" show  key %s, value %s", key, tostring(isShow)))

    if not self._maincityShowRecord then
        self._maincityShowRecord = {}
    end

    if isShow then
        self._maincityShowRecord[key] = nil
    else
        self._maincityShowRecord[key] = 1
    end
    time = time and tonumber(time) or nil
    if time and time > 0 then
        self:TimerStart("_maincityShowRecordCheck", time, false, 1)
    else
        local show = table.isempty(self._maincityShowRecord)
        self:SetWndVisible(show)
    end
end

function UIMCity:CreateActSpine(trans, eff, listKey, special, bDefaultSortNum)
    if (not trans) then
        return
    end
    local instanceId = trans:GetInstanceID()
    local effRecord = self._actEffRecord or {}
    self._actEffRecord = effRecord
    local listEffRecord = effRecord[listKey] or {}
    effRecord[listKey] = listEffRecord
    listEffRecord[instanceId] = true
    self:CreateWndSpine(trans, eff, instanceId, false, function(spine)
        spine:SetRaycastTarget(false)
    end, false)
end

function UIMCity:OnClickChatAirBg()
    self:UpdateMsg()

    local open, msg = gModelFunctionOpen:CheckIsOpened(11700000)
    if open then
        if self._newMsg then
            GF.OpenWnd("UISayPop", { channel = tonumber(self._newMsg.channel) })
        else
            GF.OpenWnd("UISayPop")
        end
    else
        if msg then
            GF.ShowMessage(msg)
        end
    end
end

function UIMCity:OnClickAdventures()
    local openWndName
    local mainCombat = {
        LCombatTypeConst.COMBAT_MAIN,
        LCombatTypeConst.COMBAT_TYPE_30,
        LCombatTypeConst.COMBAT_TYPE_31
    }
    for i, v in ipairs(mainCombat) do
        local isFight = gLFightManager:IsCombatTypeInFight(v)
        if isFight then
            gLFightManager:PrepareGoToBattle(v, {})
            openWndName = "UIFight"
            return true, openWndName
        end
    end

    local extraWnds = self:CheckNeedOpenFeedSceneUI()
    --关闭对应的页面 只保留主界面
    gLGameUI:CloseAllButExcept(extraWnds)
    GF.ChangeMap("LFightIdleMap")
    openWndName = "UIMinFight"
    return true, openWndName
end

function UIMCity:SetBtnName()
    local strs = self._btnStrs
    local packId = gLGameLanguage:GetPackProductInfo()
    local showOrHideInfo = gLGameLanguage:GetMainCityBottomShowOrHide(packId)
    for k, v in pairs(self._btnImgList) do
        local text = self:FindWndTrans(v, "UIText")
        local btnName = strs[k]

        if gLGameLanguage:CheckIsUseSpecialProduct() and PRODUCT_G_VER ~= 0 then
            local btnData = showOrHideInfo[k]
            if btnData then
                local Image = self:FindWndTrans(v, "Image")
                self:SetWndImageGray(Image,btnData.icon)
                CS.ShowObject(v, btnData.isShow)
                btnName = btnData.btnName
            end
        end
        self:SetWndText(text, btnName)
    end
end

function UIMCity:RefreshPoint()
    for k, v in ipairs(self._pointList) do
        self:SetWndButtonGray(v, k ~= self._pageIndex)
    end
end

function UIMCity:ShowTop(b, constraint)
    CS.ShowObject(self.mMainTop, b)
end

function UIMCity:ShowMoreFunPart(show)

end

--region 多语言进行的按钮显示和屏蔽 --------------------------------------------------------------------------------
function UIMCity:VersionRefresh()
    local curShowType = 1
    if gLGameLanguage:IsUSARegion() then
        curShowType = 2
    elseif gLGameLanguage:IsKoreaRegion() then
        curShowType = 3
    elseif gLGameLanguage:IsJapanRegion() then
        curShowType = 5
    end

    ---showtype 1,仅非欧美地区版本 2,仅欧美地区版本 3,韩语地区,5,日本地区
    local showList = {
        --[1] = {root = self.mActGiftBtn,showTypeList = {[1] = true, [3] = true, [5] = true}},
        --[2] = {root = self.mStrongBtn,showType = 2 },
        --[3] = { root = self.mTopFriendBtn, showTypeList = { [3] = true } },
        --[4] = {root = self.mTopMailBtn,showType = 2 },
        --[5] = {root = self.mTopRankBtn,showType = 2 },
        --[6] = { root = self.mTopSettingBtn, showType = 2 },
        --[7] = {root = self.mGongNengBtn,showTypeList = {[1] = true, [3] = true} },
        --[8] = { root = self.mHaoyou, showTypeList = { [1] = true, [5] = true } },
        --[9] = { root = self.mVideoBtn.parent, showTypeList = { [1] = true, [3] = true, [5] = true } },
        --[10] = { root = self.mSettingBtn.parent, showTypeList = { [1] = true, [3] = true, [5] = true } },
    }

    local show
    for k, v in pairs(showList) do
        local showType = v.showType
        local showTypeList = v.showTypeList
        if showType then
            show = showType == curShowType
        elseif showTypeList then
            show = showTypeList[curShowType] == true
        else
            show = false
        end
        CS.ShowObject(v.root, show)
    end

    if PRODUCT_G_VER ~= 0 then
        CS.ShowObject(self.mActGiftBtn, false)
    end

    if PRODUCT_G_VER == 1 then
        local videoFuncId = 12000040
        local showVideoBtn = gModelFunctionOpen:CheckIsShow(videoFuncId)

        --local isOpen = gModelFunctionOpen:CheckIsOpened(videoFuncId)
        --if not isOpen then
        --	showVideoBtn = gModelFunctionOpen:GetIsShowStatus(videoFuncId)
        --end
        CS.ShowObject(self.mVideoBtn.parent, showVideoBtn)
    end

    self:RefreshCharacterBtnShow()
    self:RefreshJaServiceBtnShow()

    if PRODUCT_G_VER ~= 0 then
        if gLGameLanguage:CheckIsUseSpecialProduct() then
            local packId = gLGameLanguage:GetPackProductInfo()

            local topGoldInfo_1, topGoldInfo_2 = gLGameLanguage:GetTopGoldInfo(packId)

            if packId == 1 then
                --
                --for k, v in ipairs(self._btnImgList) do
                --    CS.ShowObject(v, true)
                --end
            elseif packId == 2 then

            elseif packId == 3 then
                --这里屏蔽下面
                --self:ShowBottom(false)
                --打开页面
                --GF.OpenWnd("UIOuttsList", { listRefId = 10101 })
            end

            local gold_icon = CS.FindTrans(self.mGoldDiv, "icon")
            self:SetWndEasyImage(gold_icon, topGoldInfo_1)
            self:SetWndEasyImage(self.mMasonryIcon, topGoldInfo_2)


            local showBotImg = gLGameLanguage:GetMainCityAllBottomShowOrHide(packId)
            local BottomImg = self:FindWndTrans(self.mMainBottom,"BottomImg")
            CS.ShowObject(BottomImg,showBotImg)
        end
    end
end

function UIMCity:CheckInStoryVisible()
    if gLGpManager:IsGpInit(LGamePlayType.STORYCOPY) then
        local manager = gLGpManager:FindStoryCopyGp()
        if manager:IsRunning() then
            self:SetMainCityShow("story", false)
        end
    end
    if gLGpManager:IsGpInit(LGamePlayType.NEWBIE) then
        local manager = gLGpManager:FindNewbieGp()
        if manager:IsRunning() then
            self:SetMainCityShow("story", false)
        end
    end
end

function UIMCity:CheckActChange(oldList, newList)
    local isChange = false
    local oldCnt = #oldList
    local curCnt = #newList
    if oldCnt ~= curCnt then
        isChange = true
    end

    if isChange then
        return isChange
    end

    for k, v in ipairs(newList) do
        local oldData = oldList[k]
        if (oldData.isSurveyData or v.isSurveyData) then
            if (oldData.surveyId ~= v.surveyId) then
                isChange = true
                break
            end
        elseif oldData.isRecharge or v.isRecharge then
            if oldData.imgUrl ~= v.imgUrl then
                isChange = true
                break
            end
        else
            if oldData.actData.model ~= v.actData.model then
                isChange = true
                break
            end

            local sid = oldData.actData.sid
            local newSid = v.actData.sid
            if sid ~= newSid then
                isChange = true
                break
            end

            if oldData.actData.iconEffect ~= v.actData.iconEffect then
                isChange = true
                break
            end
        end

        if v.actData and v.actData.model == ModelActivity.MODEL_ACTIVITY_TYPE_153 then
            if oldData.actData.title ~= v.actData.title then
                isChange = true
                break
            end
        end

    end

    return isChange
end

function UIMCity:SetGiftScrollMoveTween(seq)
    -- local trans = self.mGiftScroll
    -- local downPos = Vector2.New(-320, trans.localPosition.y)
    -- trans.localPosition = Vector2.New(-600, trans.localPosition.y)
    -- local tweener = trans:DOLocalMove(downPos, 0.5)
    -- seq:AppendInterval(3)
    -- seq:Append(tweener)
end

function UIMCity:StopScroll()
    self:TimerStop("AutoScroll")
end

function UIMCity:OperResultList(dataList)
    for k, v in ipairs(dataList) do
        table.removeidata(self._showResultList, v)
        self._objPool:ReturnObj(v.tran)
        self:QuickExecuteResult(v)
    end

    if self._isResultTweening then
        return
    end

    local ret = self:CheckWaitResult()

    if ret == 2 then
        self:TweenResult()
    end
end

function UIMCity:SetActNameTextMove(itemTrans)
    local instanceId = itemTrans:GetInstanceID()
    local curSeqTweenKey = self._nameMoveSeqKey .. instanceId
    if self._actNameMoveSeqKeyList[curSeqTweenKey] == nil then
        return
    end

    local nameTrans = self:FindWndTrans(itemTrans, "layoutEn/" .. self._layoutNameTextPathEn)
    if not CS.IsValidObject(nameTrans) then
        self._actNameMoveSeqKeyList[curSeqTweenKey] = false
        return
    end

    local defaultPosY = nameTrans.localPosition.y
    local fromPos = Vector3.New(self._nameTxtDefaultX, defaultPosY, 0)
    local isMove = self._actNameMoveSeqKeyList[curSeqTweenKey]
    self:TweenSeqKill(curSeqTweenKey)
    if not isMove then
        --还原
        nameTrans.localPosition = fromPos
        self._actNameMoveSeqKeyList[curSeqTweenKey] = false
        return
    end

    local sizeDeltaX = nameTrans.sizeDelta.x
    local toPosX = -self._nameTxtDefaultX - sizeDeltaX
    if toPosX >= self._nameTxtDefaultX then
        --长度足够显示内容，不需要滑动
        nameTrans.localPosition = fromPos
        self._actNameMoveSeqKeyList[curSeqTweenKey] = false
        return
    end

    local toPos = Vector3.New(toPosX, defaultPosY, 0)

    if not self._rollTime then
        self._rollTime = gModelNormalActivity:GetBIActivityConfigRefByKey("rollTime") or 2
        self._rollingTime = gModelNormalActivity:GetBIActivityConfigRefByKey("rollingTime") or 2
    end

    self:TweenSeq_MoveAndBack(curSeqTweenKey, nameTrans, fromPos, toPos, self._rollingTime,
            self._rollTime, self._rollTime, nil, nil, true, false)

    self._actNameMoveSeqKeyList[curSeqTweenKey] = true
end

function UIMCity:IsShowGradeQuest(bShow)
    local isShow = gModelGrade:GetIsShow()
    CS.ShowObject(self.mGradeImg, isShow)
    if not isShow then
        return
    end
    self._bGradeSpineAin = bShow
    local dpSpine = self:FindWndSpineByKey("ui_maoxianpingji_qizhi")
    if dpSpine then
        self:SetGradeSpineAin()
    else
        local posParent = self.mGradeSpine
        --这里调整下
        self._gradespine = self:CreateWndSpine(posParent, "ui_maoxianpingji_qizhi", "ui_maoxianpingji_qizhi", false,
                function(dpSpine)
                    self:SetGradeSpineAin()
                end)
    end
end

function UIMCity:SetScaleTowee(trans, key)
    local seqTween
    self:TweenSeqKill(key)
    if not seqTween then
        seqTween = self:TweenSeqCreate(key, function(seq)
            local time = 1
            local scale = trans.localScale
            local downPos = Vector3.New(0.9, 0.9, 0.9)
            local tweener = trans:DOScale(downPos, time)
            seq:Append(tweener)
            local tweener = trans:DOScale(scale, time)
            seq:Append(tweener)
            seq:SetLoops(-1, Tweening.LoopType.Restart)
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(key)
    end)
end

--region  底部按钮的点击方法--------------------------------------------------------------------------------
function UIMCity:OnClickMainCity()
    local extraWnds = self:CheckNeedOpenFeedSceneUI()
    gLGameUI:CloseAllButExcept(extraWnds)
    GF.ChangeMap("LCityMap")
    --GF.OpenWnd('UIMCity')
    --self:SetGiftUIList()
    return true
end

function UIMCity:IsResultWin(itemdata)
    local resultWin = true
    local accType = itemdata.accWndType or 1
    local combatType = itemdata.combatType
    if accType == 1 then
        if combatType == LCombatTypeConst.COMBAT_GUILD_BRAVE then
            resultWin = true
        else
            if gModelBattle:IsEndlessCombat(combatType) then
                resultWin = itemdata.isWin
            else
                resultWin = (itemdata.combatResult.winner or 1) == 1
            end
        end
    elseif accType == 2 then
        resultWin = true
    elseif accType == 3 then
        resultWin = true
    elseif accType == 4 then
        resultWin = true
    end
    return resultWin
end


--调整锁字体的间距
function UIMCity:AdjustBottomBtnLockText()

    for k, v in ipairs(self._btnImgList) do
        local text_lock = self:FindWndTrans(v, "UIText_Lock")

        self:InitTextCharacterWithLanguage(text_lock, -10)

    end
end

function UIMCity:OpenSerGiftTime(item, itemdata)
    local moreInfo = itemdata.actData:GetMoreInfo()
    if not moreInfo.timeSwitch or moreInfo.timeSwitch <= 0 then
        return
    end
    local endTime = itemdata.actData.endTime
    local time = tonumber(endTime)
    if not time then
        return
    end
    local timeLeft = time - GetTimestamp()

    if timeLeft < 0 then
        if time > 0 then
            self:RefreshActivityList()
        end
        return
    end
    if not CS.IsValidObject(item) then
        return
    end
    self:CommonSetTimeText(item, timeLeft)
end
--endregion --------------------------------------------------------------------------------------

--region 点击按钮的处理 --------------------------------------------------------------------------------------
function UIMCity:RefreshFuncPreView()
    local isOpen = gModelFunctionOpen:CheckIsOpened(gModelRedPoint.FUNC_PRE_VIEW1, false)
    local isShow = false
    if isOpen then
        local list = gModelFunctionOpen:GetSortForeList()
        if list then
            isShow = #list > 0
        end
    end
    if isShow then
        local curLev = gModelPlayer:GetPlayerLv()
        local needLev = gModelPlayer:GetRoleConfigRefByKey("foreshowLvVariety")

        CS.ShowObject(self.mFuncPreView1, curLev < needLev and self:GetCurIndex() == LMainBtnIndexConst.CITY)
        CS.ShowObject(self.mFuncPreView2, curLev >= needLev)
    else
        CS.ShowObject(self.mFuncPreView1, false)
        CS.ShowObject(self.mFuncPreView2, false)
    end
end

function UIMCity:StartScroll()
    self:StopScroll()

    if #self.originalDataList < 2 then
        return
    end

    local tab = {
        -- callOnStart = true,
        func = function()
            self:AutoScroll()
        end,
        loopcnt = -1,
        interval = gModelFunctionOpen:GetForeshowScrollTime(),
        key = "AutoScroll"
    }

    self:TimerStartImpl(tab)
end

function UIMCity:CreateFightBtnEff()
    --local data = {
    --    trans = self.mFightEff,
    --    effName = "fx_maoxian", --"fx_maoxian_xuanzhong",
    --    effKey = self._fightBtnOnEff,
    --    onVisibleCall = function(effect, isVisible)
    --        CS.ShowObject(self._adventuresImageIcon, false)
    --        if not isVisible then
    --            return
    --        end
    --        local effTran = effect:GetDisplayTrans()
    --        local redTran = self:FindWndTrans(effTran, "redPoint")
    --        if redTran then
    --            self:OnRedPointEffLoaded(self.mAdventuresImage, redTran)
    --        end
    --    end
    --}
    --self:CreateWndEffect_Ex(data)
    local data = {
        trans = self.mFightEff,
        effName = "fx_maoxian", -- "fx_maoxian",
        effKey = self._fightBtnOffEff,
        onVisibleCall = function(effect, isVisible)
            CS.ShowObject(self._adventuresImageIcon, false)
            if not isVisible then
                return
            end
            local effTran = effect:GetDisplayTrans()
            local redTran = self:FindWndTrans(effTran, "redPoint")
            if redTran then
                self:OnRedPointEffLoaded(self.mAdventuresImage, redTran)
            end
        end
    }
    self:CreateWndEffect_Ex(data)
end

function UIMCity:BulletinOpt()
    local has = gModelNotice:HasNotice()
    if not has then
        local str = ccClientText(11214)
        GF.ShowMessage(str)
        return
    end
    GF.OpenWndTop("UIBulin", { type = 1, order = 800 })
end

function UIMCity:ShowSpecialActivityList()
    local showList = {}

    local reqSid = self._OnlineReqSid
    local actList = gModelActivity:GetMainCitySpecialShowActs()

    ---- 旧模版数据要保留
    --构建对应的活动 BIActivityFuncTypeRef
    local specialMainCityData = gModelActivity:GetActivityFunsById(18)
    if specialMainCityData then
        local lv = gModelPlayer:GetPlayerLv()
        local isOpen = gModelFunctionOpen:CheckIsOpened(specialMainCityData.uniqueJump)
        if lv <= checknumber(specialMainCityData.limitLv) and isOpen then
            local model_4 = ModelActivity.MODEL_DAILYGIFTBAG
            --未设置过 进行设置
            local tActDatas = gModelActivity:GetActivityDataByModelId(model_4)
            if tActDatas and #tActDatas > 0 then
                for i,v in ipairs(tActDatas) do
                    table.insert(showList, {
                        isSpecialMainCityAct = true,
                        targetModel = model_4,
                        actData = v,
                        refData = specialMainCityData,
                    })
                end
            end
        end
    end

    local specialAct = gModelActivity:GetMainCitySpecialAct()
    if specialAct and #specialAct > 0 then
        for i,v in ipairs(specialAct) do
            table.insert(showList,v)
        end
    end

    if actList then
        for k, v in ipairs(actList) do
            local data
            if v.isSpecialAct then
                data = {
                    isSpecialAct = true,
                    actData = v.actData,
                    specialShowSceneIcon = v.specialShowSceneIcon,
                    specialShowTitle = v.specialShowTitle,
                }
            else
                data = {
                    actData = v,
                }
            end

            local bAdd = true
            if data.actData.model == ModelActivity.MODEL_ACTIVITY_TYPE_74 then
                local _sid = data.actData.sid
                local page = gModelActivity:GetActivityPagesBySid(_sid, 1)
                local isCur = reqSid == _sid
                if not page then
                    bAdd = false
                    if not isCur then
                        reqSid = _sid
                    end
                else
                    if reqSid == _sid then
                        reqSid = nil
                    end
                    if self._OnlineReqSid == _sid then
                        self._OnlineReqSid = nil
                    end
                end
                bAdd = false
            end
            if bAdd then
                table.insert(showList, data)
            end
        end
    end

    self:ShowActListImpl(self._specialActivtyListKey, showList)

    if reqSid and reqSid ~= self._OnlineReqSid then
        self._OnlineReqSid = reqSid
        self:TimerStart(self._delayOnlineReqCountDownKey, 0.2, false, 1)
    end
    --if not self:IsTimerExist(self._actCountDownKey) then
    --	self:TimerStart(self._actCountDownKey, 1, false, -1)
    --end
    FireEvent(EventNames.ON_MAIN_ACTIVITY_SHOW)
end

function UIMCity:MailOpt()
    GF.OpenWndBottom("UIMil")
end

function UIMCity:UpDataItem()
    for k, v in ipairs(self._itemList) do
        local data = self.showDataList[k]
        if data then
            self:OnDrawMainEntranceItem(v, data, k)
        end
    end
    self:UpDateMainEntraceTxt()
end

function UIMCity:ShowActivityList(isClick)
    if gModelGuide:IsInGuide() then
        LPlayerPrefs.SetShowMoreList(1)
    end

    --printInfoN2("---cjh---", "isClick--"..tostring(isClick).."----1")
    local showList = {}

    local actList = gModelActivity:GetMainCityShowActs()
    if actList then
        for k, v in ipairs(actList) do
            local data
            if v.isSpecialAct then
                data = {
                    isSpecialAct = true,
                    actData = v.actData,
                    specialShowSceneIcon = v.specialShowSceneIcon,
                    specialShowTitle = v.specialShowTitle,
                }
            else
                data = {
                    actData = v,
                }
            end

            table.insert(showList, data)
        end
    end

    local webIconData = self._webIconData
    if webIconData then
        table.insert(showList,{
            iconPath = "mainui_icon_weChat_4",
            isRecharge = true,
            title = ccClientText(11941),
            showInfo = webIconData,
        })
    end

    local surveyData = self._surveyData
    if surveyData then
        table.insert(showList,
                { isSurveyData = true, surveyId = surveyData.surveyId, iconPath = "mainui_questionnaire_1", title = ccClientText(13444), surveyData = surveyData })
    end

    local curCnt = #showList

    local showLessList = curCnt <= 5

    CS.ShowObject(self.mActStateBtn, not showLessList)
    CS.ShowObject(self.mActMoreList, true)

    local lessCnt = 5
    local lessDataList = {}

    local showMoreList = false
    if not showLessList then
        lessCnt = 4
        local isOn = self:IsShowMoreList()
        local onTran = self:FindWndTrans(self.mActStateBtn, "on")
        local offTran = self:FindWndTrans(self.mActStateBtn, "off")
        CS.ShowObject(onTran, isOn)
        CS.ShowObject(offTran, not isOn)
        showMoreList = isOn
    end

    for k = 1, lessCnt do
        local data = showList[k]
        table.insert(lessDataList, data)
    end

    local lessListKey = "actLessList"
    self:ShowActListImpl(lessListKey, lessDataList)

    local moreDataList = {}
    for k = lessCnt + 1, curCnt do
        local data = showList[k]
        table.insert(moreDataList, data)
    end
    local moreListKey = "actMoreList"
    self:ShowActListImpl(moreListKey, moreDataList)

    self._moreActDataList = moreDataList

    if not isClick then
        --第一次的时候 会走这个的逻辑 -- 后续的click
        local moreCnt = #moreDataList
        local defaultPos = Vector3.New(426, 0)
        local alpha = 1
        if not showMoreList then
            local height = moreCnt * 90 + 20 + math.max(moreCnt - 1, 0) * 14
            defaultPos = Vector3.New(426, height)
            alpha = 0
        end

        local itemRoot = self:FindWndTrans(self.mActMoreList, "ItemRoot")
        itemRoot.anchoredPosition = defaultPos

        local canvasGroup = self.mActMoreList:GetComponent(typeofCanvasGroup)
        canvasGroup.alpha = alpha
    end

    self:RefreshActBtnRed()

    --self:TimerStop(self._actCountDownKey)

    FireEvent(EventNames.ON_MAIN_ACTIVITY_SHOW)
    self:StartActNameTextMoveTime()
end

function UIMCity:ShowActivityIcon(actData)
    local showIcon = true
    if actData.model == ModelActivity.DREAM_SCHOOL or actData.model == ModelActivity.PRIVILEGE_SHOP then
        showIcon = false
    end
    return showIcon
end

function UIMCity:RefreshBtnRedPointSorting()
    local btnFuncList = self._btnFuncList
    if not btnFuncList then
        return
    end
    for k, v in pairs(btnFuncList) do
        local RedPoint = self:FindWndTrans(v.btn, "redPoint")
        if RedPoint then
            self:ResetRedSortingOrder(RedPoint)
        end
    end
end

function UIMCity:RangOpt()
    GF.OpenWndBottom("UIRain", { rankType = ModelRank.RANK_TYPE_COMPLEX })
end

function UIMCity:ShowBulletin()
    if not gLGameLanguage:IsForeignRegion() then
        return
    end

    if not gModelNotice:HasNotice() then
        return
    end

    if not gModelNotice:CheckPopPlatformGameNotice() then
        return
    end

    if not gModelGuide:IsAllowPopWnd() then
        gModelNotice:SetNeedWaitGameNotice(true)
        return
    end

    gModelNotice:SetNeedWaitGameNotice(false)
    --海外公告进入主城出现一次
    local tempWnd = {
        uiName = "UIBulin",
        para = { type = 1, order = 800 }
    }
    gModelGeneral:InsertTimeLimitWndEx(tempWnd)
end

function UIMCity:RefreshActivityList()
    self:ShowSpecialActivityList()
    self:ShowActivityList()
    --self:ShowVipServiceBtn()
end

function UIMCity:StartActNameTextMoveTime()
    local stempTime = 2
    if self:IsTimerExist(self._nameMoveTimeKey) then
        stempTime = 0.5
    end

    self:TimerStop(self._nameMoveTimeKey)
    self:TimerStart(self._nameMoveTimeKey, stempTime, false, 1)
end

function UIMCity:OnClickServiceJa()
    if gLGameLogin:IsOpenGm() then
        gLSdkImpl:CallMethod(LSdkMethod.OpenCustomerService)
    end
end

--region 滚动列表 --------------------------------------------------------------------------------
-- 实始化滚动列表 ,防：UISubOuttsPVP.lua
function UIMCity:InitList()
    self._itemList = {}
    for i = 1, 3 do
        local tab = {}
        tab.item = self["mItemTemplate" .. i]
        tab.icon = self:FindWndTrans(tab.item, "Icon")
        tab.iconTxt = self:FindWndTrans(tab.item, "IconTxt")
        tab.txtBg = self:FindWndTrans(tab.item, "bg")
        tab.txtTime = self:FindWndTrans(tab.item, "bg/txtTime")
        self._itemList[i] = tab
    end
    self._changeDistanceX = self.mItemTemplate1.rect.width
    self._autoChangeDistanceX = self._changeDistanceX / 4
    self._pageIndex = 1

    local trans = self.mPageList
    self:ShowEff(trans, "trans", true)
end

function UIMCity:RefreshCurSelectPageWhenMove(index)
    local pageIndex = self._pageIndex
    pageIndex = pageIndex + index

    if pageIndex < 1 then
        --当抵达左边界 的时候  下一个-1 则应该抵达右边界
        pageIndex = self._mainEntraceDataMax
    elseif pageIndex > self._mainEntraceDataMax then
        --当抵达右边界 的时候  下一个+1 则应该抵达左边界
        pageIndex = 1
    end
    self._pageIndex = pageIndex
end

--function UIMCity:ShowEndlessBuff()
--	local list = {}
--	if(gModelEndles:HaveNewSelectBuff())then
--		local ref = gModelGeneral:GetForeshowRefByRefId(ModelGeneral.NOTICE_ENDLES)
--		table.insert(list,ref)
--	end
--	if not self._uiNoticeList then
--		self._uiNoticeList = self:GetUIScroll("uiNoticeList")
--		self._uiNoticeList:Create(self.mInformScroll,list,function (...) self:NoticeListItem(...) end,UIItemList.NORMAL,false)
--		local uiList = self._uiNoticeList:GetList()
--		uiList:EnableLoadAnimation(true,0.03,1)
--		uiList:RefreshList()
--	else
--		self._uiNoticeList:RefreshList(list)
--	end
--end

function UIMCity:SetNoticeUIList()
    self._simuRedTran = nil

    local list = gModelGeneral:GetNoticeWndList()
    self._noticeTimeTextMap = {}
    if not self._uiNoticeList then
        self._uiNoticeList = self:GetUIScroll(" uiNoticeList")
        self._uiNoticeList:Create(self.mInformScroll, list, function(...)
            self:NoticeListItem(...)
        end, UIItemList.NORMAL, false)
        local uiList = self._uiNoticeList:GetList()
        uiList:EnableLoadAnimation(true, 0.03, 1)
        uiList:RefreshList()
    else
        self._uiNoticeList:RefreshList(list)
    end

    local para = {
        key = "noticeTimer",
        interval = 1,
        loopcnt = -1,
        func = function()
            self:SetNoticeCountdown()
        end
    }

    self:TimerStartImpl(para)
end

function UIMCity:SetRCountDown()
    if not self._showResultList or #self._showResultList == 0 then
        return
    end

    local list = {}
    local cnt = #self._showResultList
    for k = cnt, 1, -1 do
        local data = self._showResultList[k]
        if self:SetSingleRCd(data) then
            table.insert(list, data)
        end
    end

    if #list > 0 then
        self:OperResultList(list)
    end

    return true
end

function UIMCity:OnChatAirPopOptBtnClick()
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq(self._chatAniKey)

    self._isPlayChatAni = true
    local chatPlayDelayTime = 0.5
    local chatPlayTime = 0.3

    if self.mChatAirPop.localScale.x > 0 then
        seq:Insert(0, self.mChatAirPop:DOScale(Vector3.one * 0, chatPlayTime))
        self:SetWndEasyImage(self.mChatAirPopOptBtn, "chat_icon_11_1")
    else
        seq:Insert(0, self.mChatAirPop:DOScale(Vector3.one, chatPlayTime))
        self:SetWndEasyImage(self.mChatAirPopOptBtn, "chat_icon_11")
    end

    seq:InsertCallback(chatPlayDelayTime, function()
        self._isPlayChatAni = false
    end)

    seq:OnComplete(function()
        seqCom:DeleteSeq(self._chatAniKey)
    end)
    seq:PlayForward()
end

function UIMCity:UIDragOnEnd(dragKey, eventData)
    if dragKey == "wndMainCitychatBtn" then
        local trans = self.mChatBtnRoot
        local camera = eventData.pressEventCamera
        local pos = camera:ScreenToWorldPoint(eventData.position)
        pos = trans.parent:InverseTransformPoint(pos)
        local posY = self.mChatBtnRoot.anchoredPosition.y

        self:SetAnchorPos(self.mChatBtnRoot, Vector2.New(30, posY))
    end

    if dragKey == "myDraw" then
        local endMoveX = self.mItemRoot.localPosition.x
        local autoChangeDistanceX = self._autoChangeDistanceX

        local moveType
        if endMoveX > 0 and endMoveX >= autoChangeDistanceX then
            moveType = UIMCity.MOVE_RIGHT
        elseif endMoveX < 0 and endMoveX <= -autoChangeDistanceX then
            moveType = UIMCity.MOVE_LEFT
        else
            moveType = UIMCity.MOVE_CENTER
        end

        local pageIndex = self._pageIndex
        if endMoveX > 0 then
            if pageIndex - 1 <= 0 then
                self:RetSetRootPos()
                self:StartScroll()
                return
            end
        else
            if pageIndex + 1 > self._mainEntraceDataMax then
                self:RetSetRootPos()
                self:StartScroll()
                return
            end
        end

        self:AutoMoveRoot(moveType)
    end
end

--刷新特效 todo--后续应该是加载第六个位置上
function UIMCity:RefreshFightBtnEffect()
    if not self._wndVisible then
        return
    end

    local newIndex = self._lastBotBtnIndex

    --if newIndex == 3 then
    --	self:TimerStop(self._delayShowFinger)
    --	self:DestroyWndEffectByKey("guideFinger")
    --	CS.ShowObject(self.mFingerPart,false)
    --else
    --	self:DelayShowFinger()
    --end

    --[[
    local effect = self:FindWndEffectByKey(self._fightBtnOffEff)
    if effect then
        effect:SetVisible(newIndex ~= 3)
    end

    effect = self:FindWndEffectByKey(self._fightBtnOnEff)
    if effect then
        effect:SetVisible(newIndex == 3)
    end
    ]]
    --
end

--function UIMCity:SetWndVisibleExcludeMiniGameAct(active)
--	local haveMiniGame = false
--	local specialShowActList = gModelActivity:GetMainCitySpecialShowActs()
--	for k,v in ipairs(specialShowActList) do
--		if v.model == ModelActivity.MODEL_GAME_TYPE_DOG then
--			haveMiniGame = true
--			break
--		end
--	end
--
--	if haveMiniGame then
--		self:ShowBottomUI(active)
--		self:ShowTopUI(active)
--		self:UpdateShow(active)
--		self:ShowSpecialActivityScrollUI(true)
--	else
--		self:SetWndVisible(active)
--	end
--end

-- 【G功能预告】删除玩法预告机制（客户端&服务端）
-- function UIMCity:ShowPrePost()
--     local list = gModelFunctionOpen:GetPrePostList()
--     local hasPre = #list > 0

--     local inMainFight = GF.FindFirstWndByName("UIMinFight")
--     local show = not inMainFight and hasPre and self._isHurdleShow
--     CS.ShowObject(self.mPrepost, show)
--     self._showPre = not inMainFight and hasPre
--     if not hasPre then
--         return
--     end
--     local data = list[1]
--     local icon = data.icon
--     self:SetWndEasyImage(self.mPostIcon, icon)
--     self:SetWndText(self.mPostText, ccLngText(data.name))

--     self:CreateWndEffect(self.mPrepost, "fx_wanfayugao", "fx_wanfayugao", 100)
-- end

function UIMCity:OnTaReport(index)
    local map = GF.GetCurMap()
    if map then
        if map:IsSameMap("LInvasionMap") then
            local attr = self._taInfos[index]
            gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_INVASION, "离开场景", attr)
        end
    end
end

function UIMCity:CreateActEff(trans, eff, listKey, special, bDefaultSortNum)
    if (not trans) then
        return
    end
    local instanceId = trans:GetInstanceID()
    local effRecord = self._actEffRecord or {}
    self._actEffRecord = effRecord
    local listEffRecord = effRecord[listKey] or {}
    effRecord[listKey] = listEffRecord
    listEffRecord[instanceId] = true
    if special then
        self:_CreateTxtEffFunc(trans, eff, instanceId)
    else
        self:_CreateActEffFunc(trans, eff, instanceId, bDefaultSortNum)
    end
end

function UIMCity:PlayEff(trans, eff, key)
    if self:FindWndEffectByKey(key) then
        return
    end
    self:CreateWndEffect(trans, eff, key, 100)
end

function UIMCity:OpenResultDetail(showData)
    self:RemoveResultItem(showData)
    local itemdata = showData.itemdata
    itemdata.force = true
    gModelBattle:OpenAccountRelaWnd(itemdata.wndName, itemdata)
end

function UIMCity:TryGetCharacterRedPointState()
    if not (gLGameLanguage:IsKoreaRegion() and self._characterBtnShow) then
        return
    end
    local timeKey = self._characterRedTimeKey
    self:TimerStop(timeKey)
    self:TimerStart(timeKey, 2, true, 1)
end

function UIMCity:SetSingleRCd(data)
    local itemdata = data.itemdata
    local str = ccClientText(10919) --"关闭"
    if data.operType == 1 then
        if itemdata.showNext then
            local isWin = self:IsResultWin(itemdata)
            if isWin then
                str = ccClientText(10920) --"下一关"
            else
                str = ccClientText(10921) --"再次挑战"
            end
        end
    end

    local percent = 1
    local appendStr = ""
    local color = "lightGreen"
    local showSlider = false
    data.canOper = true
    if data.operWait > 0 then
        local timeLeft = data.operWaitEnd - GetTimestamp()
        if timeLeft > 0 then
            data.canOper = false
            appendStr = string.format("(%s)", math.ceil(timeLeft))
            color = "grey_2"
        else
            showSlider = true
            if data.autoWait > 0 then
                timeLeft = data.autoWaitEnd - GetTimestamp()
                if timeLeft > 0 then
                    appendStr = string.format("(%s)", math.ceil(timeLeft))
                    percent = 1 - timeLeft / data.autoWait
                else
                    --todo
                    return true
                end
            end
        end
    end

    str = LUtil.FormatColorStr(str .. appendStr, color)
    local tipTran = self:FindWndTrans(data.tran, 'root/tip')
    self:SetWndText(tipTran, str)
    local slider = self:FindWndTrans(data.tran, 'root/Slider')
    CS.ShowObject(slider, showSlider)
    if showSlider then
        self:SetWndSliderPara(slider, percent)
    end
end

function UIMCity:InitData()
    self._delayShowFinger = "_delayShowFinger"
    self._headBaseClass = nil
    ------------------顶部------------------
    self:InitTopData()
    ------------------右边区域------------------
    self:InitHudrleData()
    ------------------底部------------------
    self:InitBottomData()

    local root = self.mSettingBtn.transform.parent
    self._functionBtns = {
        [18000010] = root,
    }

    --todo 锁定使用的节点和对应的图片节点
    self._bottomLock = {
        --[12100000] = { rootTran = self.mGuildBtn, imageRoot = self.mGuildImage },
        --[10400000] = { rootTran = self.mArtifactBtn, imageRoot = self.mArtifactImage },
        --[36000001] = { rootTran = self.mPetBtn, imageRoot = self.mPetImage },
    }

    self._activityItemList = {}

    self._activityRecord = {}

    self._actCountDownKey = "_actCountDownKey"

    self._fightBtnOnEff = "_fightBtnOnEff"
    self._fightBtnOffEff = "_fightBtnOffEff"

    --显示倒计时
    self._commonCdActivity = {
        [ModelActivity.COMMON_TARGET] = true,
        [ModelActivity.MODEL_PASSB] = true,
        [ModelActivity.COMMONRANK] = true,
        [ModelActivity.ACTIVITY_FAIRYLAND] = true,
        [ModelActivity.ACTIVITY_CUSTOMGIFT] = true,
        [ModelActivity.TENCALL] = true,
        -- [ModelActivity.MODEL_TREASURE_HOT] = true,
        -- [ModelActivity.ACTIVITY_CALLHERO] = true,
        -- [ModelActivity.ACTIVITY_FAIRY_TALE] = true,
        [ModelActivity.MODEL_WONDERLAND_SEVEN_DAY] = true,
        [ModelActivity.MODEL_NEWHEROCALL] = true,
        -- [ModelActivity.NEW_HERO_THEME_A] = true,
        -- [ModelActivity.NEW_HERO_THEME_B] = true,
        -- [ModelActivity.MODEL_CHN_CELEBRATE] = true,
        [ModelActivity.DISCOUNTS_SKIN] = true,
        -- [ModelActivity.BAND_THEME] = true,
        -- [ModelActivity.MODEL_HALLOWEEN] = true,
        -- [ModelActivity.THANKSGIVING] = true,
        -- [ModelActivity.RETURN_TO_INVITE] = true,
        [ModelActivity.WITCH_SECRET_LANGUAGE] = true,
        [ModelActivity.ONE_CLICK_SKIN] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_57] = true,
        -- [ModelActivity.ACTIVITY_VALENTINES_DAY] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_61] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_64] = true,
        -- [ModelActivity.CRAZY_LOTTERY_TEN] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_67] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_66] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_68] = true,
        -- [ModelActivity.ACTIVITY_MOTHER_DAY] = true,
        [ModelActivity.DOUBLE_DIAMOND] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = true,
        -- [ModelActivity.SUMMER_DAY] = true,
        [ModelActivity.DAILY_GIFT_A] = true,
        -- [ModelActivity.FAIRY_FATHER_DAY] = true,
        -- [ModelActivity.ACTIVITY_TOWER] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_85] = true,
        [ModelActivity.ANNIVERSARY_SIGN_80] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_81] = true,
        [ModelActivity.SKIN_GIFT_82] = true,
        [ModelActivity.ANNIVERSARY_DAILY_KOI_83] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_87] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_92] = true,
        --- 使用showEndTime倒计时
        --[ModelActivity.MODEL_ACTIVITY_TYPE_94] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_84] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_86] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_95] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_100] = true,
        [ModelActivity.MODEL_NEWHEROCALL_DOUBLE] = true,
        [ModelActivity.DAILY_GIFT_D] = true,
        [ModelActivity.MODEL_ACTIVITY_LIMIT_WEEK_CARD] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_4105] = true,
        [ModelActivity.EXCHANGE] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_96] = true,
        [ModelActivity.ACT_MODEL_97] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_103] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_104] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_112] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_115] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_116] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_117] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_119] = true,
        --[ModelActivity.MODEL_ACTIVITY_TYPE_107] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_129] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_4103] = true,
        [ModelActivity.MODEL_PASSD] = true,
        -- [ModelActivity.MODEL_NEWYEAR] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_120] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_121] = true,
        --[ModelActivity.MODEL_ACTIVITY_TYPE_123] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_4110] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_124] = true,
        -- [ModelActivity.MODEL_ACTIVITY_TYPE_4108] = true,
        [ModelActivity.MODEL_PASSE] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_132] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_154] = true,
        [ModelActivity.MODEL_ACTIVITY_TYPE_166] = true,
    }

    self._expImageWidth = self.mExpImg.sizeDelta.x

    self._japanMasonryIdList = {
        ModelItem.ITEM_DIAMOND,
        ModelItem.ITEM_PAY_DIAMOND,
    }

    local layoutEnWidth = 74
    self._nameTxtDefaultX = -layoutEnWidth / 2
    self._isShowActNameRoll = gLGameLanguage:IsJapanVersion() or gLGameLanguage:IsEnglishVersion()
    self._initSpecialActivtyScrollPos = self.mSpecialActivtyScroll.anchoredPosition
end

function UIMCity:EightLoginCD(item, itemdata)
    local sid = itemdata.actData.sid
    local actData = gModelActivity:GetActivityBySid(sid)
    if not actData then
        return
    end
    local moreInfo = actData:GetMoreInfo()

    local endTime = actData.endTime
    if not string.isempty(moreInfo.overTime) then
        --八天登录过期时间
        local milliSec = tonumber(moreInfo.overTime) or 0
        endTime = milliSec / 1000
    end

    local timeLeft = endTime - GetTimestamp()

    if timeLeft < 0 then
        return
    end

    if not CS.IsValidObject(item) then
        return
    end
    self:CommonSetTimeText(item, timeLeft)

    --local endType  = moreInfo.endType
    --
    --local time
    --if endType and endType == 1 then
    --	time = actData.endTime or 0
    --else
    --	local isAllReceive = moreInfo.isAllReceive
    --	if not isAllReceive then
    --		return
    --	end
    --	local overTime = moreInfo.overTime
    --	time = tonumber(overTime)
    --	if not time then
    --		return
    --	end
    --	time = time/1000
    --end
    --
    --local timeLeft = time - GetTimestamp()
    --
    --if timeLeft < 0 then
    --	return
    --end
    --if not CS.IsValidObject(item) then
    --	return
    --end
    --self:CommonSetTimeText(item,timeLeft)
end

function UIMCity:SetTopFuncBgPos()
    local target = self.mTopFuncBg:GetComponent(typeofRectTransform)

    local canvasRect = LGameUI.GetUICanvasRoot()
    local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect, self.mGongNengBtn)
    local canvasRectTran = canvasRect:GetComponent(typeofRectTransform)
    local area = canvasRectTran.rect

    local posX = targetPos.x - target.rect.width / 2 - 32
    local posY = targetPos.y - area.height / 2 - 10
    local pos = Vector3.New(posX, posY, 0)
    target.localPosition = pos

    local curGuide = gModelGuide:GetCurGuide()
    if curGuide == 13210 or curGuide == 13200 then
        self:DelaySendFinish()
    end
end

function UIMCity:ShowVipServiceWnd(oldLv, newLv)
    --if (newLv > oldLv) then
    --    local checkIsFirstOpen = checknumber(LPlayerPrefs.vipChangeOpenVipServiceWnd) == 0
    --    if checkIsFirstOpen then
    --        self:VipServiceOpt()
    --        LPlayerPrefs.SetVipChangeOpenVipServiceWnd(1)
    --    end
    --end
end

function UIMCity:SchoolCd(item, itemdata)
    local time = GetTimestamp()
    local settlementRankTime
    local _schoolInfos = gModelDreamSchool:GetSchoolInfos()
    for i, v in pairs(_schoolInfos) do
        if v.settlementRankTime / 1000 > time and time >= v.startRankTime / 1000 and (not settlementRankTime or settlementRankTime > v.settlementRankTime) then
            settlementRankTime = v.settlementRankTime
        end
    end
    if not settlementRankTime then
        local layoutRoot = self:GetCommonLayerTrans(item)
        if layoutRoot then
            local layoutTimeBg = self:FindWndTrans(layoutRoot, "TimeBg")
            CS.ShowObject(layoutTimeBg, false)
        end
        return
    end

    local timespan = settlementRankTime / 1000 - time
    if timespan <= 0 then
        local layoutRoot = self:GetCommonLayerTrans(item)
        if layoutRoot then
            local layoutTimeBg = self:FindWndTrans(layoutRoot, "TimeBg")
            CS.ShowObject(layoutTimeBg, false)
        end
        return
    end
    self:CommonSetTimeText(item, timespan)
end

--更新聊天信息
function UIMCity:UpdateMsg()
    if not self._isShowAir then
        return
    end
    --local list = gModelChat:GetAir2ChannelMsg()
    local list = gModelChat:GetAir2ChannelSingleMsg(true)

    self._oldMsg = self._newMsg
    self._newMsg = list[1]

    self._isCacheChatMsg = false
    if self._isPlayChatTween then
        self._isCacheChatMsg = true
    else
        local isNewMes = false
        if self._oldMsg and self._newMsg then
            local oldSendTime = self._oldMsg.sendTime
            local newSendTime = self._newMsg.sendTime

            if oldSendTime == newSendTime then
                isNewMes = false
            else
                isNewMes = true
            end
        else
            isNewMes = true
        end

        if isNewMes then
            --数据相同是别的部分的推送消息
            self._chatStarCutTime = self._chatInitTime

            --设置信息部分
            if self._oldMsg then
                self:SetAirMsg(self.mText_Old, self._oldMsg)
            end

            if self._newMsg then
                self:SetAirMsg(self.mText_New, self._newMsg)
                CS.ShowObject(self.mText_Cur, false)
                self:SetAirMsg(self.mText_Cur, self._newMsg)
            end

            --两个处理 --一个进行弹框一个进行消息的滚动
            if self.mChatAirPop.localScale.x > 0 then
                self:InitMsgTween()
            else
                local isAir = gModelChat:GetChatSetValue(7)

                local channelList = {
                    ["2"] = ModelChat.CHANNEL_GUILD,
                    ["3"] = ModelChat.CHANNEL_SERVE,
                    ["4"] = ModelChat.CHANNEL_WORLD,
                    ["5"] = ModelChat.CHANNEL_PROVINCE,
                }

                local isOpenOneChat = false
                for k, v in pairs(channelList) do
                    if gModelChat:GetChatSetValue(tonumber(k)) then
                        isOpenOneChat = true
                    end
                end



                if isAir then
                    CS.ShowObject(self.mText_Cur, true)
                    if isOpenOneChat then
                        self:OnChatAirPopOptBtnClick()
                    end
                else
                    self:InitMsgTween()
                end
            end
        end
    end

    self:UpdateMsgBtnRedPoing()
end

function UIMCity:CheckOpenForeShowPop(wndName)
    if wndName and wndName=="UIForeshowPop" then return end
    local popList = gModelFunctionOpen:GetForeshowPopList()
    if not popList or #popList<=0 then return end
    local justMain =  gLGameUI:IsJustMain()
    if self._lastBotBtnIndex ==1 and justMain then
        gModelFunctionOpen:OpenForeshowPop()
    end
end

-- 初始化协议
function UIMCity:InitHandlerMainEntrace()
    self:WndEventRecv(EventNames.ON_PRE_FUNC_PLAY, function()
        self:RefreshMainEntrace()
        self:RefreshMainEntraceList()
    end)
end

--更多部分
function UIMCity:Show(b)
    CS.ShowObject(self.mTopFuncBg, b)

    if b then
        self:CheckIsShowHudleTopFunc()
        self:SetTopFuncBgPos()
    end

    --CS.ShowObject(self.mMaskBg,b)
end

function UIMCity:UpDateMainEntrace()
    local list = gModelFunctionOpen:GetForeshowList()
    if #list ~= self._mainEntraceDataMax then
        self:RefreshMainEntraceList()
        return
    end
    if self._mainEntraceDataMax == 0 then
        return
    end

    if self._mainEntraceDataMax == 1 then
        self:UpDataItem()
    else
        self:UpDateMainEntraceTxt()
    end
end

function UIMCity:RefreshSpecialRedpoint()
    ---164活动
    ---164活动
    if self._recordTimer then return end

    self._recordTimer = LxTimer.DelayTimeCall(function()
        LxTimer.LoopTimeStop(self._recordTimer)
        self._recordTimer = nil

        local uiSpecialList = self:FindUIScroll(self._specialActivtyListKey)
        if uiSpecialList then
            local uiList = uiSpecialList:GetList()
            uiList:RefreshList()
        end
    end, 1,false)
end

function UIMCity:QuickExecuteResult(data)
    if not data.canOper then
        return
    end

    local itemdata = data.itemdata
    local executeType = 1
    if data.operType == 2 then
        executeType = 1
    elseif data.operType == 1 then
        if itemdata.showNext then
            executeType = 2
        else
            executeType = 1
        end
    end

    self:RemoveResultItem(data)
    if executeType == 2 then
        local combatType = itemdata.combatType
        gModelBattle:NextBattleOnTip(combatType, data)
    end

    FireEvent(EventNames.CHECK_WAIT_GUIDE)
end

function UIMCity:ShowEnjoyMonthCard(isEnable, enableHelpPop)
    --     local isShowCard = isEnable
    --     local durationTime
    --     if isEnable then
    --         local isShow, endTime = gModelActivity:CheckIsShowEnjoyMonthCard(true)
    --         isShowCard = isShow
    --         durationTime = endTime
    --     end

    --     CS.ShowObject(self.mEnjoyMonthCardBtn, isShowCard)
    --     if not isShowCard then
    --         self:TimerStop(self._enjoyMonthCardTimeKey)
    --         return
    --     end

    --     local activityData = gModelActivity:GetSpecialActivity(ModelActivity.MONTH_ACTIVITY_ENJOY_CARD)
    --     if not activityData then
    --         return
    --     end

    --     local moreInfo = JSON.decode(activityData.moreInfo)
    --     local cityEnterIcon = moreInfo.cityEnterIcon
    --     if LxUiHelper.IsImgPathValid(cityEnterIcon) then
    --         self:SetWndEasyImage(self.mEnjoyMonthCardBtn, cityEnterIcon)
    --     end

    --     local title = activityData.title
    --     self:SetWndText(self.mEnjoyMonthCardText, title)

    --     local sid = activityData.sid
    --     local red = gModelActivity:GetSaveRedBySid(sid)
    --     local showRed = gModelRedPoint:CheckActivityShowRed(sid)
    --     CS.ShowObject(self.mEnjoyMonthCardRedPoint, showRed or red)

    --     self._enjoyMonthCardDurationTime = durationTime
    --     self:SetEnjoyMonthCardCD()
    --     self:TimerStart(self._enjoyMonthCardTimeKey, 1, false, durationTime + 3)
    --     self:CreateWndEffect(self.mEnjoyMonthCardEff, self._enjoyMonthCardEff, self._enjoyMonthCardEff, 100, false, false)

    --     if enableHelpPop then
    --         self:SetWndText(self.mEnjoyMonthCardHelpContentText, ccClientText(36005))
    --         CS.ShowObject(self.mEnjoyMonthCardHelpContent, true)
    --         self:TweenSeq_FadeInStaysAway(self._enjoyMonthCardSeqKey, self.mEnjoyMonthCardHelpContent, { waitTime = 5 })
    --     end
end

function UIMCity:ShowTrans(trans, isShow)
    CS.ShowObject(trans, isShow)
end

function UIMCity:ReleaseTouchEvent()
    if gLGameTouch then
        gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_FINGER)
    end
end

function UIMCity:ShowMasonryMore(isShow)
    if isShow == nil then
        if self._isShowMasonryMoreBg == nil then
            self._isShowMasonryMoreBg = true
            isShow = self._isShowMasonryMoreBg
        else
            isShow = not self._isShowMasonryMoreBg
        end
    end

    if self.mMasonryMoreBg.gameObject.activeSelf == isShow then
        return
    end

    self._isShowMasonryMoreBg = isShow
    CS.ShowObject(self.mMasonryMoreBg, false)
    if isShow then
        self:RefreshMasonryMore()
    end
end

function UIMCity:OnChangeMainBtn(index, extraWnds,ignoreCurBtn)
    if self:IsCurBtn(index) and not ignoreCurBtn then
        return
    end
    --self:ShowTop(true,true)

    local changeSuc, wndOpenName = self._bottomBtnFunc[index]()
    if not changeSuc then
        return
    end
    self:ChangeCurBtn(index)

    extraWnds = extraWnds or {}
    if wndOpenName then
        extraWnds[wndOpenName] = true
    end
    self:OnSwitchToOther(index, extraWnds)
end

function UIMCity:RetSetRootPos()
    --重置原本节点
    local curPos = Vector3.New(0, 0, 0)
    self.mItemRoot.localPosition = curPos
end

function UIMCity:SetBigFace(item, faceId, InstanceID, preferredWidth)
    local emojiImage = self:FindWndTrans(item, "FaceImg")
    local emojiSpine = self:FindWndTrans(item, "FaceSpine")
    local faceRef = gModelChat:GetChatFaceRefByRefId(faceId)
    if faceRef then
        local isSpine = faceRef.isSpine and faceRef.isSpine == 1
        CS.ShowObject(emojiSpine, isSpine)
        CS.ShowObject(emojiImage, not isSpine)
        if isSpine then
            self:DestroyWndSpineByKey(InstanceID)
            self:CreateWndSpine(emojiSpine, faceRef.faceSpine, InstanceID, false, function(dpSpine)
                dpSpine:SetScale(0.5)
                dpSpine:SetRaycastTarget(false)
                local dpTrans = dpSpine:GetDisplayTrans()
                dpTrans.anchorMin = Vector2.New(0.5, 0.5)
                dpTrans.anchorMax = Vector2.New(0.5, 0.5)
                dpTrans.pivot = Vector2.New(0.5, 0.5)
            end)
            emojiSpine.anchoredPosition = Vector2.New(preferredWidth, 0)
        else
            self:SetWndEasyImage(emojiImage, faceRef.faceIcon)
            emojiImage.anchoredPosition = Vector2.New(preferredWidth, 0)
        end
    end
    LxUiHelper.SetSizeWithCurAnchor(item, 1, 70)
end

function UIMCity:RefreshMainEntrace()
    local isShow = false
    if self:GetCurIndex() == LMainBtnIndexConst.CITY then
        local isOpen = gModelFunctionOpen:CheckIsOpened(18007000, false)
        if isOpen then
            local list = gModelFunctionOpen:GetForeshowList()
            local moreActDataList = self._moreActDataList or {}
            if #list > 0 then
                isShow = true
                -- if self.mActStateBtn.gameObject.activeSelf then
                --     if #moreActDataList >= 6 then
                --         isShow = not (gModelActivity:IsMoreListShow())
                --     end
                -- end
            end
        end
    end
    if PRODUCT_G_VER == 1 or PRODUCT_G_VER == 2 then
        isShow = false
    end
    if isShow then
        isShow = self.mSpecialActivtyScroll.gameObject.activeSelf
    end
    CS.ShowObject(self.mMainEntrance, isShow)

    if isShow then
        self:StarMainEntraceTimer()
    else
        self:StopMainEntraceTimer()
    end
end

function UIMCity:SetResultItem(item, itemdata, showData)
    local root = self:FindWndTrans(item, "root")
    local rootBg = self:FindWndTrans(root, "bg")
    local rootTitle = self:FindWndTrans(root, "title")
    local rootIcon = self:FindWndTrans(root, "icon")
    local rootTag = self:FindWndTrans(root, "tag")
    --local rootTip = self:FindWndTrans(root,"tip")
    --local rootTipIcon = self:FindWndTrans(root,"tipIcon")
    local rootArea = self:FindWndTrans(root, "area")
    local rootItemList = self:FindWndTrans(root, "itemList")
    --local rootSlider = self:FindWndTrans(root,"Slider")
    --local SliderBackground = self:FindWndTrans(rootSlider,"Background")
    local rootDetail = self:FindWndTrans(root, "detail")

    self:SetWndClick(root, function()
        self:OpenResultDetail(showData)
    end)

    self:SetWndClick(rootArea, function()
        self:OperCurResult(showData)
    end)

    --local hyper = self:GetUIHyperText(detail)
    local str = ccClientText(10922) --"详情"
    --str=hyper:AddHyper(str,{func = function ()
    --	self:RemoveResultItem(showData)
    --	gModelBattle:OpenAccountRelaWnd(itemdata.wndName,itemdata)
    --end})
    self:SetWndText(rootDetail, str)

    local ref = gModelFormation:GetCombatGameRef(itemdata.combatType)
    self:SetWndEasyImage(rootIcon, ref.autoResponseIcon)
    self:SetWndText(rootTitle, ccLngText(ref.name))
    self:InitTextLineWithLanguage(rootTitle, -30)
    self:InitTextSizeWithLanguage(rootTitle, -2)

    self:SetSingleRCd(showData)

    local isWin = self:IsResultWin(itemdata)
    local icon = isWin and "finalEstimate_txt_2" or "finalEstimate_txt_1"
    self:SetWndEasyImage(rootTag, icon)

    local rewardList = gModelBattle:GetTipShowReward(itemdata)
    self:CreateUIScrollImpl(nil, rootItemList, rewardList, function(...)
        self:OnDrawItem(...)
    end)
end

function UIMCity:OnlyChangeMainIndex(sendData)
    local index = 0
    if sendData then
        index = sendData.index or 0
    end

    if self:IsCurBtn(index) then
        return
    end

    self:ChangeCurBtn(index)
    local extraWnds = sendData.extraWnds or {}
    self:OnSwitchToOther(index, extraWnds)
end

function UIMCity:SetCharacterRedPoint(isOk)
    if not gLGameLanguage:IsKoreaRegion() then
        return
    end

    CS.ShowObject(self.mCharacterRedPoint, isOk or false)
end

function UIMCity:SetTowee(key)
    local seqTween
    self:TweenSeqKill(key)
    if not seqTween then
        seqTween = self:TweenSeqCreate(key, function(seq)
            if key == self._giftTweenKey then
                self:SetGiftScrollMoveTween(seq)
            elseif key == self._giftCurTweenKey then
                self:SetGiftScrollAlphaTween(seq, 1)
            elseif key == self._giftCurEndTweenKey then
                self:SetGiftScrollAlphaTween(seq, 2)
            end
            return seq
        end)
    end
    seqTween:OnComplete(function()
        self:TweenSeqKill(key)
    end)
    seqTween:PlayForward()
end

function UIMCity:GiftOpt()
    GF.OpenWndBottom("UIHuiYPay", { page = 3 })
    gLxTKData:OnUIBtnClick("UIHuiYPay", 1)
end

function UIMCity:OnClickActivity()
    local canOpen = gModelActivity:CheckCanOpenActivity(true)
    if not canOpen then
        return
    end
    gLxTKData:OnUIBtnClick("UIAct")

    GF.ChangeMap("LCityMap")
    -- local wnd = GF.FindFirstWndByName("UIAct")
    -- if not wnd then
    GF.OpenWndBottom("UIAct")
    -- end
    return true
end

function UIMCity:TweenMoreList(isUp)
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq("tweenMoreList")
    local itemRoot = self:FindWndTrans(self.mActMoreList, "ItemRoot")
    local defaultPos = itemRoot.anchoredPosition
    local startPos = nil
    local moveY = nil
    local startA = nil
    local endA = nil
    local height = itemRoot.rect.height
    for i = 1, itemRoot.childCount do
        local emphasisEffectRoot1 = self:FindWndTrans(itemRoot:GetChild(i - 1), "EmphasisEffectRoot1")
        local emphasisEffectRoot2 = self:FindWndTrans(itemRoot:GetChild(i - 1), "EmphasisEffectRoot2")
        CS.ShowObject(emphasisEffectRoot1, not isUp)
        CS.ShowObject(emphasisEffectRoot2, not isUp)
    end
    if isUp then
        startPos = Vector3.New(defaultPos.x, 0)
        moveY = height / 3
        startA = 1
        endA = 0
    else
        startPos = Vector3.New(defaultPos.x, height / 3)
        moveY = 0
        startA = 0
        endA = 1
    end
    itemRoot.anchoredPosition = startPos
    local time = height / 650
    local tween = itemRoot:DOLocalMoveY(moveY, time)
    seq:Append(tween)
    local canvasGroup = self.mActMoreList:GetComponent(typeofCanvasGroup)
    canvasGroup.alpha = startA
    tween = canvasGroup:DOFade(endA, time)
    seq:Join(tween)

    seq:PlayForward()
    seq:OnComplete(function()
        CS.ShowObject(self.mActMoreList, not isUp)
    end)
end

function UIMCity:BackflowCd(item, itemdata)
    local timespan = gModelBackflow:GetResidueTime()
    if timespan <= 0 then
        return
    end
    self:CommonSetTimeText(item, timespan)
end

function UIMCity:CheckWaitResult()
    if #self._showResultList >= 3 then
        return
    end

    if self._isResultTweening then
        return
    end

    local waitR
    if self._waitResultList then
        waitR = table.remove(self._waitResultList)
    end
    if waitR then
        self:ReceiveResultData(waitR)
        return 1
    else
        self:CheckStartResultTimer()
        return 2
    end
end

function UIMCity:SetChatAirPopDrag()
    local canDrag = gModelChat:GetChatSetValue(7)
    self:UIDragSetItem("wndMainCitychatBtn", "AniRoot/ChatBtnRoot", CS.YXUIDrag.DragMode.DragOrigin, canDrag)

    if self.mChatAirPop.localScale.x > 0 then
        if canDrag then
            self:OnChatAirPopOptBtnClick()
        end
    else
        --如果是小于0 没法滑动就展开
        if not canDrag then
            self:OnChatAirPopOptBtnClick()
        end
    end
end

function UIMCity:CheckNeedOpenFeedSceneUI()
    local extraWnds
    local jumpStatus,jumpWnd = gLSdkImpl and gLSdkImpl:CallMethod(LSdkMethod.CheckNeedOpenFeedSceneUI)
    if jumpStatus and jumpWnd then
        extraWnds = {
            [jumpWnd] = true,
        }
    end
    return extraWnds
end
--endregion --------------------------------------------------------------------------------------

---------------------------------------------------------------------
return UIMCity
