---
--- Created by LCM.
--- DateTime: 2024/3/2 14:51:53
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubLimitedTrea:LChildWnd
local UISubLimitedTrea = LxWndClass("UISubLimitedTrea", LChildWnd)

UISubLimitedTrea.ARROW_TYPE_0 = 0            -- 所有都生效
UISubLimitedTrea.ARROW_TYPE_1 = 1            -- 分针所指
UISubLimitedTrea.ARROW_TYPE_2 = 2            -- 时针所指


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubLimitedTrea:UISubLimitedTrea()
    self._minArrowAniKey = "minArrowAniKey"
    self._maxArrowAniKey = "maxArrowAniKey"

    self._arrowRotateTimeKey = "arrowRotateTimeKey"

    self._spAniKey = "_spAniKey"
    self._spBoxAniKey = "_spBoxAniKey"

    self._runRewardTimerKey = "runRewardTimerKey"
    self._runShowRewardTimerKey = "runShowRewardTimerKey"
    self._freeTimeRefreshTimerKey = "freeTimeRefreshTimerKey"

    self._reSetAniKey = "_reSetAniKey"

    --self._jumpRefreshAniStatus = not gModelCallHero:GetLuckyMagicIsEff()

    self._jumpRefreshAniStatus = gModelCallHero:GetTimeTreasureJumpAni()

    self._isPlayAnimation = true
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubLimitedTrea:OnWndClose()
    self:RunRewardFunc()
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubLimitedTrea:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubLimitedTrea:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()


    self.jpj = gLGameLanguage:IsJapanVersion()
    --初始化池子
    self:InitSliderRewardPool()

    self._isForeign = gLGameLanguage:IsForeignRegion()
    self:InitText()


    --表盘spine
    --self:CreateWndSpine(self.mSpRoot,"fx_yuelunzhuanpan_idle",self._spAniKey)

    self._effectList = {}

    self._effectList["fx_rilunzhuanpan_idle"] = self:CreateWndEffect(self.mSpRoot, "fx_rilunzhuanpan_idle", "fx_rilunzhuanpan_idle", 100, nil, nil, nil, nil, nil, true)
    self._effectList["fx_rilunzhuanpan_turn"] = self:CreateWndEffect(self.mSpRoot, "fx_rilunzhuanpan_turn", "fx_rilunzhuanpan_turn", 100, nil, nil, nil, nil, nil, true)
    self._effectList["fx_yuelunzhuanpan_idle"] = self:CreateWndEffect(self.mSpRoot, "fx_yuelunzhuanpan_idle", "fx_yuelunzhuanpan_idle", 100, nil, nil, nil, nil, nil, true)
    self._effectList["fx_yuelunzhuanpan_turn"] = self:CreateWndEffect(self.mSpRoot, "fx_yuelunzhuanpan_turn", "fx_yuelunzhuanpan_turn", 100, nil, nil, nil, nil, nil, true)
    --宝箱spine 
    --self:CreateWndSpine(self.mBoxImg,"Shiguangbaozanxiangzi",self._spBoxAniKey,nil,function()
    --end)

    self._effectList["fx_rilunzhuanpan_idle"]:SetVisible(false)
    self._effectList["fx_rilunzhuanpan_turn"]:SetVisible(false)
    self._effectList["fx_yuelunzhuanpan_idle"]:SetVisible(false)
    self._effectList["fx_yuelunzhuanpan_turn"]:SetVisible(false)

    self:RefreshJumpRefreshAniStatus()

    self:InitStatus()
    self:InitCallBtnTransInfo()
    self:InitRewardTransInfo()
    self:InitCallTypeBtnInfo()
    self:InitArrowTransList()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:RefreshCallTypeLockStatus()
    self:RefreshView()
    self:ReqServerData()

    self._isVie = gLGameLanguage:IsVieVersion()
    self:RefreshForeign()
end

function UISubLimitedTrea:OnClickMinCallBtnFunc()
    self._isCanPlayGetRewadAnim = true
    self:SendMagicWheelMsg(1)
end

function UISubLimitedTrea:OnClickRewardRootFunc(itemdata)
    if not itemdata then
        return
    end
    local itemType = itemdata.itemType
    local itemId = itemdata.itemId
    if itemType == LItemTypeConst.TYPE_EQUIP then
        gModelGeneral:OpenEquipInfoTip(itemId, nil, 1, true)
    elseif itemType == LItemTypeConst.TYPE_ITEM then
        gModelGeneral:OpenItemInfoTip(itemId, itemdata.itemNum)
    elseif itemType == LItemTypeConst.TYPE_OUTFIT then
        gModelGeneral:OpenOutfitInfoTipByRefId(itemId)
    end
end

function UISubLimitedTrea:RefreshCallTypeLockStatus()
    local curMagicWheelType = self._curMagicWheelType
    local callTypeBtnInfoList = self._callTypeBtnInfoList
    local isLock
    local functionId, btnType
    for k, v in pairs(callTypeBtnInfoList) do
        btnType = v.btnType
        functionId = v.functionId
        local isOpen = true
        if functionId and functionId > 0 then
            isOpen = gModelFunctionOpen:CheckIsOpened(functionId)
        end
        isLock = not isOpen
        CS.ShowObject(v.LockImgTrans, isLock)
        if isLock then
            CS.ShowObject(v.NoSelImgTrans, false)
            CS.ShowObject(v.SelImgTrans, false)
        else
            local isSel = btnType == curMagicWheelType
            CS.ShowObject(v.NoSelImgTrans, not isOpen)
            CS.ShowObject(v.SelImgTrans, isSel)
        end
    end
end

function UISubLimitedTrea:OnClickJumpAniSelBtnFunc()
    self._jumpRefreshAniStatus = not self._jumpRefreshAniStatus
    gModelCallHero:SetTimeTreasureJumpAniStats(self._jumpRefreshAniStatus)
    self:RefreshJumpRefreshAniStatus()
end

function UISubLimitedTrea:InitCallBtnTransInfo()
    local callBtnList = {
        {
            btnTrans = self.mMinCallBtn,
            effName = "fx_ui_putongzhaohuan_04",
        },
        {
            btnTrans = self.mMaxCallBtn,
            effName = "fx_ui_putongzhaohuan_05",
        },
    }
    local callBtnTransInfo
    local callBtnTransInfoList = {}
    for i, v in ipairs(callBtnList) do
        callBtnTransInfo = self:GetCallBtnTransInfo(v)
        table.insert(callBtnTransInfoList, callBtnTransInfo)
    end
    self._callBtnTransInfoList = callBtnTransInfoList
end

function UISubLimitedTrea:OnMagicLuckyReceiveResp(pb)
    LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_LUCKY_MIRROR)
    self:DisposeLuckyReceive(pb.luckyReceive)
    self:RefreshBox(pb.luckyCount)

    self:OnSliderMagicLuckyReceiveResp(pb)
end

function UISubLimitedTrea:PlayArrowRotationAni(aniTime)
    --local rotateZ = rewardTransPosInfo.leftPos - rewardTransPosInfo.rightPos

    local zeroArrow, rotationArrow, rewardTransPosInfo = self:GetZeroArrorAndRotationArrow()
    if not zeroArrow or not rotationArrow then
        return
    end

    self:TweenSeq_LocalRotate(zeroArrow, {
        rotateZ = 0,
        showTime = aniTime / 2,
        loop = false,
    })

    self:TweenSeq_LocalRotate(rotationArrow, {
        rotateZ = -360,
        showTime = aniTime,
        loop = false,
    })
end

--region 上方进度条部分 --------------------------------------------------------------------------------
function UISubLimitedTrea:InitSliderRewardPool()
    --创建奖励的pool
    self._sliderRewardPool = UIObjPool:New()
    self._sliderRewardPool:Create(self.mRewardUnUse, self.mSliderItemTemplate)
end

function UISubLimitedTrea:DisposeLuckyReceive(luckyReceive)
    self._luckyReceiveList = {}
    for i, v in ipairs(luckyReceive) do
        self._luckyReceiveList[v] = v
    end
end

function UISubLimitedTrea:OnClickLuckyBtnFunc()
    self:OnClickTimeTreasureTypeFunc(1)
end

function UISubLimitedTrea:RunRewardAni(pb)
    self._rewardCallBackFunc = function()
        self:OpenRewardWnd()
        self:RunSpineIdle()
        self:RefreshBox(pb.luckyCount)
        self._sendCallStatus = false
        gModelGameHelper:RefreshGameSpeed()
    end
    if self:IsPlayRewardAni() then

        if self._jumpRefreshAniStatus then
            self:RunRewardFunc()
        else
            local aniTime = self:GetRunRewardAniTime()
            self:PlayArrowRotationAni(aniTime)
            self:TimerStop(self._runRewardTimerKey)
            self:TimerStart(self._runRewardTimerKey, aniTime, true, 1)
            local ani = self._curMagicWheelType == ModelCallHero.LUCKY and "xingyunzhuangdong_loop" or "qijizhuangdong_loop"
            self:PlaySpineAni({
                aniName = ani,
                loop = true
            })
            gModelGameHelper:TemporaryCloseSpeed()
        end
    else
        self._isPlayAnimation = true
        self:RunRewardFunc()
    end
end

function UISubLimitedTrea:RefreshView()
    self:RefreshShow()
end

function UISubLimitedTrea:RunRewardFunc()
    if self._rewardCallBackFunc then
        self._rewardCallBackFunc()
    end
    self._rewardCallBackFunc = nil
end

function UISubLimitedTrea:SendMagicWheelReset()
    self._resetPlayAniStatus = true
    gModelCallHero:OnMagicWheelResetReq(self._curMagicWheelType)
end

function UISubLimitedTrea:RunIdleAni(init)
    self:TimerStop(self._arrowRotateTimeKey)

    if init then
        local initMinArrowRotation = Quaternion.Euler(0, 0, 0)
        self.mMinArrow.localRotation = initMinArrowRotation

        local initMaxArrowRotation = Quaternion.Euler(0, 0, 0)
        self.mMaxArrow.localRotation = initMaxArrowRotation
    end

    local rotateZ = -360

    self:TweenSeq_LocalRotate(self.mMinArrow, {
        rotateZ = rotateZ,
        showTime = 10,
        loop = true,
    })

    self:TweenSeq_LocalRotate(self.mMaxArrow, {
        rotateZ = rotateZ,
        showTime = 5,
        loop = true,
    })
    --self:RunCheckArrowItem()
end

function UISubLimitedTrea:OnSliderMagicLuckyReceiveResp(pb)

    self:DisposeLuckyReceive(pb.luckyReceive)
    self:RefreshIntegralShow(self._lucky)
end

function UISubLimitedTrea:CheckArrowItemStatus()
    local minArrowAngles = self.mMinArrow.localEulerAngles
    local maxArrowAngles = self.mMaxArrow.localEulerAngles

    local minArrowAZ = minArrowAngles.z
    local maxArrowAZ = maxArrowAngles.z

    local rewardTransInfoList = self._rewardTransInfoList
    local rewardTransPosList = self._rewardTransPosList

    local transPosInfo
    local leftPos, rightPos, arrowType
    for i, v in ipairs(rewardTransInfoList) do
        transPosInfo = rewardTransPosList[i]
        local showSel = false
        if transPosInfo then
            leftPos = transPosInfo.leftPos
            rightPos = transPosInfo.rightPos
            arrowType = transPosInfo.arrowType

            if arrowType == UISubLimitedTrea.ARROW_TYPE_0 then
                showSel = minArrowAZ <= leftPos and minArrowAZ >= rightPos or maxArrowAZ <= leftPos and maxArrowAZ >= rightPos
            elseif arrowType == UISubLimitedTrea.ARROW_TYPE_1 then
                showSel = maxArrowAZ <= leftPos and maxArrowAZ >= rightPos
            elseif arrowType == UISubLimitedTrea.ARROW_TYPE_2 then
                showSel = minArrowAZ <= leftPos and minArrowAZ >= rightPos
            end
        end
        CS.ShowObject(v.EffRootTrans, false)
        CS.ShowObject(v.RewardTrans, showSel)
    end
end

function UISubLimitedTrea:ReqServerData()
    gModelCallHero:CallOpt(self._page, self._subPage)
end

function UISubLimitedTrea:OnDrawNeedAddItemCell(list, item, itemdata, itempos)
    local IconTrans = self:FindWndTrans(item, "IconDiv/Icon")
    local NumTrans = self:FindWndTrans(item, "Num")
    local AddBtnTrans = self:FindWndTrans(item, "BtnDiv/AddBtn")

    local itemId = itemdata.itemId

    local icon = gModelItem:GetItemIconByRefId(itemId)
    self:SetWndEasyImage(IconTrans, icon)

    local haveNum = gModelItem:GetNumStrByRefId(itemId)
    self:SetWndText(NumTrans, haveNum)

    self:SetWndClick(AddBtnTrans, function()
        self:OnClickNeedAddBtnFunc(itemId)
    end)
end

function UISubLimitedTrea:OnMagicWheelResetResp(pb)
    if self._jumpRefreshAniStatus then
        self:OnMagicWheelInfoResp(pb.info)
        self._resetPlayAniStatus = false
    else
        self:PlayReSetAni(pb)
    end
end

function UISubLimitedTrea:InitConfigData()
    self._viewShowInfoList = {
        --蓝色的
        [ModelCallHero.LUCKY] = {
            minArrow = "magicwheel_arrow_ui_4",
            maxArrow = "magicwheel_arrow_ui_5",
            arrowRoot = "magicwheel_arrow_ui_6",
            frameBg = "magicwheel_frame_bg_2",
            bg = "magicwheel_bg_big_2",
            star = "magicwheel_star_ui_2",
            biaopanBg = "magicwheel_frame_bg_2",
            bar = "magicwheel_bar_2",
            wenzidi = "magicwheel_bg_2",
            wheelline = "magicwheel_line_2",

            idleSpine = "fx_yuelunzhuanpan_idle",
            runSpine = "fx_yuelunzhuanpan_turn",

            textId = 14607,
        },
        --橙色的
        [ModelCallHero.MIRACLE] = {
            minArrow = "magicwheel_arrow_ui_1",
            maxArrow = "magicwheel_arrow_ui_2",
            arrowRoot = "magicwheel_arrow_ui_3",
            frameBg = "magicwheel_frame_bg_1",
            bg = "magicwheel_bg_big_1",
            star = "magicwheel_star_ui_1",
            biaopanBg = "magicwheel_frame_bg_1",
            bar = "magicwheel_bar_1",
            wenzidi = "magicwheel_bg_1",
            wheelline = "magicwheel_line_1",

            idleSpine = "fx_rilunzhuanpan_idle",
            runSpine = "fx_rilunzhuanpan_turn",

            textId = 14610,
        },
    }

    self._rewardTransPosList = {
        [1] = {
            arrowType = UISubLimitedTrea.ARROW_TYPE_1,
            leftPos = 36,
            rightPos = 15,
            index = 1,
        },
        [2] = {
            arrowType = UISubLimitedTrea.ARROW_TYPE_1,
            leftPos = 348,
            rightPos = 332,
            index = 2,
        },
        [3] = {
            arrowType = UISubLimitedTrea.ARROW_TYPE_1,
            leftPos = 310,
            rightPos = 286,
            index = 3,
        },
        [4] = {
            arrowType = UISubLimitedTrea.ARROW_TYPE_1,
            leftPos = 270,
            rightPos = 245,
            index = 4,
        },
        [5] = {
            arrowType = UISubLimitedTrea.ARROW_TYPE_1,
            leftPos = 231,
            rightPos = 210,
            index = 5,
        },
        [6] = {
            arrowType = UISubLimitedTrea.ARROW_TYPE_2,
            leftPos = 190,
            rightPos = 160,
            index = 6,
        },
        [7] = {
            arrowType = UISubLimitedTrea.ARROW_TYPE_2,
            leftPos = 140,
            rightPos = 110,
            index = 7,
        },
        [8] = {
            arrowType = UISubLimitedTrea.ARROW_TYPE_2,
            leftPos = 85,
            rightPos = 54,
            index = 8,
        },
    }
end

function UISubLimitedTrea:RefreshJumpRefreshAniStatus()
    CS.ShowObject(self.mJumpAniSelBgGou, self._jumpRefreshAniStatus)
end

function UISubLimitedTrea:IsPlayRewardAni()
    return self._isPlayAnimation
end

function UISubLimitedTrea:GetRewardTransInfo(trans)
    local RewardBgTrans = self:FindWndTrans(trans, "RewardBg")
    local RewardTrans = self:FindWndTrans(RewardBgTrans, "Reward")
    local IconTrans = self:FindWndTrans(RewardBgTrans, "Icon")
    local MinIconTrans = self:FindWndTrans(IconTrans, "MinIcon")
    local EffRootTrans = self:FindWndTrans(RewardBgTrans, "EffRoot")
    local GetTips = self:FindWndTrans(RewardBgTrans, "GetTips")
    local GetTipsText = self:FindWndTrans(GetTips, "GetTipsText")
    CS.ShowObject(EffRootTrans, false)
    local UITextTrans = self:FindWndTrans(trans, "UIText")
    return {
        root = trans,
        RewardBgTrans = RewardBgTrans,
        RewardTrans = RewardTrans,
        IconTrans = IconTrans,
        MinIconTrans = MinIconTrans,
        EffRootTrans = EffRootTrans,
        UITextTrans = UITextTrans,
        GetTips = GetTips,
        GetTipsText = GetTipsText,
    }
end

function UISubLimitedTrea:SaveItemPosList()
    local itemList = self._pbItemList or {}
    local itemIndexList = {}
    for i, v in ipairs(itemList) do
        local itemId = tonumber(v.itemId)
        if itemId and itemId > 0 then
            local ref = gModelCallHero:GetInitMagicWheelRewardRefByRefId(itemId)
            if ref then
                local reward = ref.reward
                local list = ref.list
                itemIndexList[list] = {
                    itemType = reward.itemType,
                    itemId = reward.itemId,
                    itemNum = reward.itemNum,
                    refId = itemId,
                    extractCount = v.extractCount,
                    list = list,
                }
            end
        end
    end
    local itemIdPos = {}
    for idx, idxInfo in ipairs(itemIndexList) do
        local itemIdList = itemIdPos[idxInfo.itemId]
        if not itemIdList then
            itemIdList = {}
            itemIdPos[idxInfo.itemId] = itemIdList
        end
        local itemIndexInfoList = itemIdList[idxInfo.list]
        if not itemIndexInfoList then
            itemIndexInfoList = {}
            itemIdList[idxInfo.list] = itemIndexInfoList
        end
        itemIndexInfoList[idxInfo.itemNum] = idxInfo.itemNum
    end
    self._itemIdPos = itemIdPos
end

function UISubLimitedTrea:OnTimer(key)
    if key == self._arrowRotateTimeKey then
        self:CheckArrowItemStatus()
    elseif key == self._runRewardTimerKey then
        self:RunEndShowRewardAni()
    elseif key == self._runShowRewardTimerKey then

        self:ShowEnd()
    elseif key == self._freeTimeRefreshTimerKey then
        self:CountDownFreeTime()
    end
end

function UISubLimitedTrea:InitNeedAddItemList()
    local list = self:GetNeedAddItemList()
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

function UISubLimitedTrea:GetGradReward(str)
    str = str or ""
    local itemList = LUtil.ConvertCommonItemStrToList(str)
    return itemList[1]
end

function UISubLimitedTrea:SendMagicWheelMsg(num)
    if self._resetPlayAniStatus then
        GF.ShowMessage(ccClientText(14616))
        return
    end
    if self._sendCallStatus then
        return
    end
    local callBackFunc = function()

        self._sendCallStatus = true
    end

    gModelCallHero:SendMagicWheelReq(self._curMagicWheelType, num, self:GetWndName(), callBackFunc)


end

function UISubLimitedTrea:OnMagicWheelInfoResp(pb)
    self._pbItemList = pb.items
    self._extractCount = pb.extractCount
    self:SaveItemPosList()
    self:ChangeMagicWheelStatus(pb.type)
    self._freeTime = pb.freeTime / 1000
    self:RefreshFreeTime()
    self:RefreshRewardShow()
    self:DisposeLuckyReceive(pb.luckyReceive)
    self:RefreshBox(pb.lucky)
    self:InitNeedAddItemList()

    self:OnSliderMagicWheelInfoResp(pb)
end

function UISubLimitedTrea:InitMsg()
    -- 魔轮信息返回
    self:WndNetMsgRecv(LProtoIds.MagicWheelInfoResp, function(pb, ret)
        self:OnMagicWheelInfoResp(pb)
    end)
    -- 魔轮重置
    self:WndNetMsgRecv(LProtoIds.MagicWheelResetResp, function(pb, ret)
        self:OnMagicWheelResetResp(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.MagicWheelResp, function(pb, ret)
        self:OnMagicWheelResp(pb)
    end)
    self:WndNetMsgRecv(LProtoIds.MagicLuckyReceiveResp, function(pb, ret)
        self:OnMagicLuckyReceiveResp(pb)
    end)
    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:InitNeedAddItemList()
    end)
    self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE, function()
        self:RefreshCallTypeLockStatus()
    end)
end

function UISubLimitedTrea:OpenRewardWnd()
    local itemDetail = self._itemDetail
    if not itemDetail or #itemDetail < 1 then
        return
    end
    self:RefreshRewardShow()
    local magicType = self._curMagicWheelType
    local fixedCfg
    if magicType == ModelCallHero.LUCKY then
        fixedCfg = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelLuckNum")
    else
        fixedCfg = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighLuckNum")
    end
    local fixedItem = LxDataHelper.ParseItem_3(fixedCfg)
    local fixedReward

    local checkFunc = function(serverData)
        if serverData.refId == fixedItem.itemId then
            fixedReward = {
                itemId = serverData.refId,
                itemType = serverData.itype,
                itemNum = serverData.num
            }
        end
    end

    local serverData
    local itemList = {}
    for i, v in ipairs(itemDetail) do
        local info = gModelGeneral:GetThingsDetailInfoByPb(v)
        local allRewardList = info:GetThingsDetailAllRewardList() or {}
        for idx, val in ipairs(allRewardList) do
            serverData = val.serverData
            checkFunc(serverData)
            table.insert(itemList, serverData)
        end
    end

    local moreNum = 1
    local itemNum = moreNum
    if self._wheelType ~= 1 then
        local curMagicWheelType = self._curMagicWheelType
        if curMagicWheelType == ModelCallHero.LUCKY then
            moreNum = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelMoreNum")
            itemNum = moreNum

            local vipLv = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelDisMoreCondition")
            local currVipLv = gModelPlayer:GetVipLevel()
            if vipLv > currVipLv then
            else
                local expend = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelDisMoreExpend")
                local payInfo = LxDataHelper.ParseItem_3(expend)

                itemNum = payInfo.itemNum
            end
        else
            moreNum = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighMoreNum")
            itemNum = moreNum
        end
    end

    local btnTextList = { ccClientText(14612), string.replace(ccClientText(14613), moreNum) }
    local para = {
        itemList = itemList,
        btnTextList = btnTextList,
        func = function()
            self._isPlayAnimation = false
            self:SendMagicWheelMsg(self._wheelType)
        end,
        callBackFunc = function()
            if not self:IsWndValid() then
                return
            end
            self:RunIdleAni(true)
            self:RefreshRewardShow()
        end,
        detail = true,
        fixedReward = fixedReward,
        -- 数量 moreNum
        costItem = { itemId = self._itemId, itemNum = itemNum },
    }
    gModelWndPop:TryOpenPopWnd("UIAward", para)
end

function UISubLimitedTrea:RefreshCallBtnTransShow()
    local curMagicWheelType = self._curMagicWheelType
    local callBtnTransInfoList = self._callBtnTransInfoList
    local isForeign = self._isForeign
    for i, transInfo in ipairs(callBtnTransInfoList) do
        local callImg
        local callTextId
        local expend
        local limitStr = ""
        local showLimitStatus = false
        if curMagicWheelType == ModelCallHero.LUCKY then
            if i == 2 then
                callImg = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelMoreNum1")
                callTextId = 14622

                local vipLv = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelDisMoreCondition")
                local currVipLv = gModelPlayer:GetVipLevel()
                if vipLv > currVipLv then
                    limitStr = string.replace(ccClientText(14615), vipLv)
                    showLimitStatus = true
                    expend = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelMoreExpend")
                else
                    expend = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelDisMoreExpend")
                end
                if string.isempty(expend) then
                    expend = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelMoreExpend")
                end
            else
                expend = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelExpend")
            end
        else
            if i == 2 then
                callImg = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighMoreNum1")
                callTextId = 14623
                expend = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighMoreExpend")
            else
                expend = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighExpend")
            end
        end

        if isForeign then
            if i == 1 then
                callTextId = 14621
            end

            if callTextId then
                self:SetWndText(transInfo.BtnNameTrans, ccClientText(callTextId))
                self:InitTextLineWithLanguage(transInfo.BtnNameTrans, -30)
            end
        else
            if callImg then
                self:SetWndEasyImage(transInfo.BtnImgTrans, callImg, nil, true)
            end
        end
        --CS.ShowObject(transInfo.BtnNameTrans, isForeign)
        --CS.ShowObject(transInfo.BtnImgTrans, not isForeign)

        local LimitTxtTrans = transInfo.LimitTxtTrans
        self:SetWndText(LimitTxtTrans, limitStr)
        self:InitTextLineWithLanguage(LimitTxtTrans, -30)
        CS.ShowObject(LimitTxtTrans, showLimitStatus)

        local showOnePay = expend ~= nil
        local payInfo = LxDataHelper.ParseItem_3(expend)
        if showOnePay then
            local icon = gModelItem:GetItemIconByRefId(payInfo.itemId)
            self:SetWndEasyImage(transInfo.IconImgTrans, icon)
            self:SetWndText(transInfo.NumTxtTrans, LUtil.NumberCoversion(payInfo.itemNum))
        end
        self._itemId = payInfo.itemId
        self._itemNeedCount = payInfo.itemNum

        CS.ShowObject(transInfo.PayDivTrans, showOnePay)
    end
end

function UISubLimitedTrea:RunEndShowRewardAni()
    self:TimerStop(self._runRewardTimerKey)

    local aniTime = 1

    local zeroArrow, rotationArrow, rewardTransPosInfo = self:GetZeroArrorAndRotationArrow()
    if rotationArrow and rewardTransPosInfo then
        local arrowAngles = rotationArrow.localEulerAngles
        local arrowAnglesZ = arrowAngles.z

        local index = rewardTransPosInfo.index
        local rotationList = self._rotationList
        local endRo = rotationList[index]

        --local isLeft = endRo < arrowAnglesZ or false
        --[[		if not isLeft then
                    endRo = 360 - endRo
                elseif arrowAnglesZ - endRo < 180 then
                    endRo = endRo - 360
                end]]
        --printInfoN(string.format("arrowAnglesZ %s",arrowAnglesZ))
        --printInfoN(string.format("endRo %s",endRo))

        endRo = endRo - 360
        --printInfoN(string.format("final endRo %s",endRo))
        self:TweenSeq_LocalRotate(rotationArrow, {
            rotateZ = endRo,
            showTime = aniTime,
            loop = false,
        })
    end

    local ani = self._curMagicWheelType == ModelCallHero.LUCKY and "xingyuntingzhi" or "qijitingzhi"
    self:PlaySpineAni({
        aniName = ani,
        loop = false,
    })

    if self._jumpRefreshAniStatus then
        self:RunRewardFunc()
    else


        self:TimerStop(self._runShowRewardTimerKey)
        self:TimerStart(self._runShowRewardTimerKey, aniTime, true, 1)
    end
end

function UISubLimitedTrea:OnTcpReconnect()
    self:InitStatus()
    self:ReqServerData()
end

function UISubLimitedTrea:RefreshIntegralShow(lucky)
    --对应的幸运值
    self._lucky = lucky or 0
    -- 拿下对应的配置
    local list = {}
    local getRewardType = self._curMagicWheelType
    if getRewardType == ModelCallHero.LUCKY then
        -- 幸运魔轮
        list = gModelCallHero:GetLuckMagicWheelLuckyRef()
    elseif getRewardType == ModelCallHero.MIRACLE then
        -- 奇迹魔轮
        list = gModelCallHero:GetMiracleMagicWheelLuckyRef()
    end

    self._sliderRewardPool:ReturnAllObj()

    self._curMaxLength = list[#list].grad or 1

    for k, v in ipairs(list) do
        local item = self._sliderRewardPool:GetObj()

        item.transform:SetParent(self.mSliderRewardRoot, false)

        CS.ShowObject(item, true)

        item.transform.anchoredPosition = Vector2.New(0, 12)

        item.transform.localScale = Vector3.New(1, 1, 1)

        self:OnDrawSliderReward(item.transform, v, k)
    end


    --计算下进度条部分
    local list = self:GetIntegralGetList()
    local len = #list
    local lastRef = list[len]
    local grad = 0
    local percentage = 0
    if lastRef then
        grad = lastRef.grad
        percentage = self._lucky / grad
    end
    --local str = string.format("%s/%s", lucky, grad)

    percentage = percentage > 1 and 1 or percentage
    self.mIntegralGetSlider.localScale = Vector3.New(percentage, 1, 1)
    self:SetWndText(self.mIntegralGetLuckyNum, self._lucky)


end

function UISubLimitedTrea:GetIntegralCanGetRewardList()
    local lucky = self._lucky
    if not lucky then
        return
    end
    local list = self:GetIntegralGetList()
    local len = #list
    if len <= 0 then
        return
    end
    local luckyReceiveList = self._luckyReceiveList or {}
    local refIdList = {}
    local refId
    for i, v in ipairs(list) do
        refId = v.refId
        if lucky >= v.grad and not luckyReceiveList[refId] then
            table.insert(refIdList, refId)
        end
    end
    return refIdList
end

function UISubLimitedTrea:RunSpineIdle()
    --local ani = self._curMagicWheelType == ModelCallHero.LUCKY and "xingyundaiji_loop" or "qijidaiji_loop"

    local ani = self._viewShowInfoList[self._curMagicWheelType].idleSpine
    self:PlaySpineAni({
        aniName = ani,
        loop = true,
    })
end

function UISubLimitedTrea:OnClickFreeRefreshBtnFunc()
    if self._sendCallStatus then
        return
    end
    if self._resetPlayAniStatus then
        GF.ShowMessage(ccClientText(14616))
        return
    end
    local freeTime = self._freeTime
    if not freeTime then
        self:SendMagicWheelReset()
        return
    end
    local curTime = GetTimestamp()
    if freeTime > curTime then
        self:ShowWndTip()
    else
        self:SendMagicWheelReset()
    end
end

function UISubLimitedTrea:RefreshForeign()
    if self._isVie then
        LxUiHelper.SetSizeWithCurAnchor(self.mFreeRefreshBtn, 0, 210)
        self:SetAnchorPos(self.mJumpAniDiv,Vector2.New(210,-193))
    end
    if self.jpj then
        self:SetAnchorPos(self.mJumpAniDiv,Vector2.New(230,-193))
    end
end

function UISubLimitedTrea:OnClickLogBtnFunc()

end

function UISubLimitedTrea:RefreshFreeTime()
    self:TimerStop(self._freeTimeRefreshTimerKey)
    local freeTime = self._freeTime
    if not freeTime then
        return
    end
    self:CountDownFreeTime()
    local curTime = GetTimestamp()
    if freeTime > curTime then
        self:TimerStart(self._freeTimeRefreshTimerKey, 1, true, -1)
    else
        CS.ShowObject(self.mPayItemRoot, false)
        self:SetWndText(self.mPayItemNum, ccClientText(12308))

        if self._isEnus then
            self:InitTextSizeWithLanguage(self.mPayItemNum, -3)
        end

        self:SetWndText(self.mRefreshTimeStr, "")
    end
end

function UISubLimitedTrea:CountDownFreeTime()
    local freeTime = self._freeTime
    if not freeTime then
        self:TimerStop(self._freeTimeRefreshTimerKey)
        self:SetWndText(self.mPayItemNum, "")
        self:SetWndText(self.mRefreshTimeStr, "")
        CS.ShowObject(self.mPayItemRoot, false)
        return
    end
    local remainTime = freeTime - GetTimestamp()
    if remainTime <= 0 then
        self:TimerStop(self._freeTimeRefreshTimerKey)
        return
    end
    local str = LUtil.FormatTimespanNumber(remainTime) .. " " .. ccClientText(13011)
    self:SetWndText(self.mRefreshTimeStr, str)

    local diaValue
    local curMagicWheelType = self._curMagicWheelType
    if curMagicWheelType == ModelCallHero.LUCKY then
        diaValue = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelRefExpend")
    else
        diaValue = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighRefExpend")
    end
    local itemList = LxDataHelper.ParseItem_3(diaValue)
    local itemId = itemList.itemId
    local itemNum = itemList.itemNum
    local icon = gModelItem:GetItemIconByRefId(itemId)
    self:SetWndEasyImage(self.mPayItem, icon)
    self:SetWndText(self.mPayItemNum, itemNum)
    CS.ShowObject(self.mPayItemRoot, true)
end

function UISubLimitedTrea:RefreshBox(lucky)

    self:RefreshIntegralShow(lucky)

    --return
    --
    --
    --local list = self:GetIntegralGetList()
    --local len = #list
    --local lastRef = list[len]
    --local grad = 0
    --local percentage = 0
    --if lastRef then
    --    grad = lastRef.grad
    --    percentage = lucky / grad
    --end
    --local str = string.format("%s/%s", lucky, grad)
    --self:SetWndText(self.mJinDuTxt, str)
    --LxUiHelper.SetProgress(self.mJinDuTiao, percentage)
    --
    --local luckyReceiveList = self._luckyReceiveList
    --local showEffect = false
    --local tgrad
    --for i, v in ipairs(list) do
    --    if showEffect then
    --        break
    --    end
    --    tgrad = v.grad
    --    showEffect = lucky >= tgrad and not luckyReceiveList[v.refId]
    --end
    --if showEffect then
    --    self:CreateWndSpine(self.mBoxEffect, "fx_shiguangbaozanjindutiao", "fx_shiguangbaozanjindutiao")
    --end
    --self:ShowBoxEff(showEffect)
    --CS.ShowObject(self.mBoxEffect, showEffect)
    --CS.ShowObject(self.mBoxGetRedPoint, showEffect)


end

function UISubLimitedTrea:InitData()
    local page = self:GetWndArg("page") or 1
    local subPage = self:GetWndArg("subPage") or 1
    self._page = page
    self._subPage = subPage
    self._luckyReceiveList = {}
    self:RefreshCurMagicWheelType()

    self:InitConfigData()
end

function UISubLimitedTrea:RefreshShowBigRewardTxt()
    local extractCountSer = self._extractCount
    local extractCount
    local rewardStr
    local itemIndexList = self:GetItemIndexList()
    for i, v in ipairs(itemIndexList) do
        if v.extractMax and v.extractMax > 0 then
            local ref = gModelCallHero:GetMagicWheelRewardRefByRefId(v.refId)
            extractCount = v.extractCount
            local extractLimit = tonumber(ref.extractLimit)
            if extractLimit == 1 and extractCount < extractLimit then
                local extractMax = v.extractMax
                if extractMax and extractMax > 0 then
                    local last = extractMax - extractCountSer
                    local lastNum
                    if last > 0 then
                        lastNum = last
                    else
                        lastNum = 1
                    end
                    rewardStr = string.replace(ccClientText(27848), lastNum, gModelItem:GetNameByRefId(v.itemId))
                end
            end
        end
    end

    local show = rewardStr ~= nil
    if show then
        self:SetWndText(self.mShowBigRewardTxt, rewardStr)
    end
    CS.ShowObject(self.mShowBigRewardTxt, show)
    CS.ShowObject(self.mShowBigRewardTxtBg, show)
end

function UISubLimitedTrea:RefreshShow()
    local viewShowInfoList = self._viewShowInfoList
    if not viewShowInfoList then
        return
    end
    local curMagicWheelType = self._curMagicWheelType
    if not curMagicWheelType then
        curMagicWheelType = ModelCallHero.LUCKY
        self._curMagicWheelType = curMagicWheelType
    end
    local viewShowInfo = viewShowInfoList[curMagicWheelType]
    if not viewShowInfo then
        return
    end

    self:RefreshCallBtnTransShow()

    local callTypeBtnInfoList = self._callTypeBtnInfoList
    for i, v in ipairs(callTypeBtnInfoList) do
        local isSel = self._subPage == i
        CS.ShowObject(v.NoSelImgTrans, not isSel)
        CS.ShowObject(v.SelImgTrans, isSel)
    end

    self:SetWndEasyImage(self.mBg, viewShowInfo.bg)

    --self:SetWndEasyImage(self.mPanBg,viewShowInfo.frameBg)

    self:SetWndEasyImage(self.mStarImg, viewShowInfo.star)

    self:SetWndEasyImage(self.mMinArrow, viewShowInfo.minArrow, nil, true)

    self:SetWndEasyImage(self.mMaxArrow, viewShowInfo.maxArrow, nil, true)

    self:SetWndEasyImage(self.mArrowRoot, viewShowInfo.arrowRoot, nil, true)

    self:SetWndEasyImage(self.mRightImg, viewShowInfo.wheelline)

    self:SetWndEasyImage(self.mPanBg, viewShowInfo.biaopanBg)
    self:SetWndEasyImage(self.mIntegralGetSlider, viewShowInfo.bar)
    self:SetWndEasyImage(self.mIntegralGetLuckyDescBg, viewShowInfo.wenzidi)
    self:SetWndEasyImage(self.mShowBigRewardTxtBg, viewShowInfo.wenzidi)

    self:SetWndText(self.mIntegralGetLuckyDesc, ccClientText(viewShowInfo.textId))

    self._effectList["fx_yuelunzhuanpan_idle"]:SetVisible(curMagicWheelType == ModelCallHero.LUCKY)
    self._effectList["fx_rilunzhuanpan_idle"]:SetVisible(not (curMagicWheelType == ModelCallHero.LUCKY))
    --self:RunSpineIdle()

    self:RunIdleAni(true)
end

function UISubLimitedTrea:ChangeMagicWheelStatus(magicType)
    local isLucky = magicType == ModelCallHero.LUCKY
    local funcId = isLucky and 16700001 or 16700011
    gModelRedPoint:SetRedPointClicked(funcId)
end

function UISubLimitedTrea:GetNeedAddItemList()
    local initMagicWheelResourcesList = self._initMagicWheelResourcesList
    if not initMagicWheelResourcesList then
        initMagicWheelResourcesList = {}
        local showItem = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelResources")
        local showItemList = string.split(showItem, "|")
        for i, v in ipairs(showItemList) do
            v = string.split(v, "=")
            table.insert(initMagicWheelResourcesList, {
                itemId = tonumber(v[2])
            })
        end

        self._initMagicWheelResourcesList = initMagicWheelResourcesList
    end
    return initMagicWheelResourcesList
end

function UISubLimitedTrea:InitArrowTransList()
    local list = {
        self.mArrow1, self.mArrow2, self.mArrow3, self.mArrow4, self.mArrow5, self.mArrow6, self.mArrow7, self.mArrow8
    }

    local rotationList = {}
    for i, v in ipairs(list) do
        local arrowAngles = v.localEulerAngles
        local arrowAnglesZ = arrowAngles.z
        rotationList[i] = arrowAnglesZ
    end
    self._rotationList = rotationList
end

function UISubLimitedTrea:InitStatus()
    self._sendCallStatus = false                -- 召唤状态
    self._resetPlayAniStatus = false            -- 重置状态
    self._playCallStatus = false                --
end

function UISubLimitedTrea:CreateBtnEff(trans, effName)
    local key = trans:GetInstanceID()
    self:CreateWndEffect(trans, effName, key, 100, false, false)
end

function UISubLimitedTrea:RunCheckArrowItem()
    self:TimerStop(self._arrowRotateTimeKey)
    self:TimerStart(self._arrowRotateTimeKey, 0.1, true, -1)
end

function UISubLimitedTrea:GetZeroArrorAndRotationArrow()
    local itemDetail = self._itemDetail
    if not itemDetail then
        return
    end
    local rewardTransPosList = self._rewardTransPosList
    if not rewardTransPosList then
        return
    end

    local index
    local rewardItems = self._rewardItems
    if rewardItems then
        local first = rewardItems[1]
        if first then
            local ref = gModelCallHero:GetMagicWheelRewardRefByRefId(first)
            if ref then
                index = ref.list
            end
        end
    end
    if not index then
        local itemIdPos = self._itemIdPos
        local checkFunc = function(info, itemType)
            itemType = itemType or LItemTypeConst.TYPE_ITEM
            local refId = info.refId
            if itemType == LItemTypeConst.TYPE_HERO then
            elseif itemType == LItemTypeConst.TYPE_RUNE then
                for itemId, itemInfo in pairs(itemIdPos) do
                    local ref = gModelItem:GetRefByRefId(itemId)
                    if ref then
                        if ref.type == ModelItem.Item_RUNE and refId == tonumber(ref.typeDate) then
                            for list, t in pairs(itemInfo) do
                                return list
                            end
                        end
                    end
                end
            elseif itemType == LItemTypeConst.TYPE_OUTFIT then
                -- for itemId,itemInfo in pairs(itemIdPos) do
                -- 	local ref = gModelItem:GetRefByRefId(itemId)
                -- 	if ref then
                -- 		if ref.type == ModelItem.Item_OUTFIT then
                -- 			local typeDate = string.split(ref.typeDate,"=")
                -- 			if #typeDate > 1 and tonumber(typeDate[1]) == refId then
                -- 				for list,t in pairs(itemInfo) do
                -- 					return list
                -- 				end
                -- 			end
                -- 		end
                -- 	end
                -- end
                local itemIndexInfoList = itemIdPos[refId]
                if itemIndexInfoList then
                    local num = tonumber(info.num) or 1
                    for list, itemInfo in pairs(itemIndexInfoList) do
                        if itemInfo[num] then
                            return list
                        end
                    end
                end
            else
                local itemIndexInfoList = itemIdPos[refId]
                if itemIndexInfoList then
                    local num = tonumber(info.num) or 1
                    for list, itemInfo in pairs(itemIndexInfoList) do
                        if itemInfo[num] then
                            return list
                        end
                    end
                end
            end
        end
        for i, v in ipairs(itemDetail) do
            local items = v.items or {}
            local heroes = v.heroes or {}
            local runes = v.runes or {}
            local outfits = v.outfits or {}
            for idx, val in ipairs(items) do
                index = checkFunc(val, LItemTypeConst.TYPE_ITEM)
                if index then
                    break
                end
            end
            for idx, val in ipairs(heroes) do
                index = checkFunc(val, LItemTypeConst.TYPE_HERO)
                if index then
                    break
                end
            end
            for idx, val in ipairs(runes) do
                index = checkFunc(val, LItemTypeConst.TYPE_RUNE)
                if index then
                    break
                end
            end
            for idx, val in ipairs(outfits) do
                index = checkFunc(val, LItemTypeConst.TYPE_OUTFIT)
                if index then
                    break
                end
            end
            if index then
                break
            end
        end
    end
    index = index or 1
    local rewardTransPosInfo = rewardTransPosList[index]
    if not rewardTransPosInfo then
        return
    end
    local arrowType = rewardTransPosInfo.arrowType
    local zeroArrow, rotationArrow
    if arrowType == UISubLimitedTrea.ARROW_TYPE_0 then
        zeroArrow = self.mMaxArrow
        rotationArrow = self.mMinArrow
    elseif arrowType == UISubLimitedTrea.ARROW_TYPE_1 then
        zeroArrow = self.mMinArrow
        rotationArrow = self.mMaxArrow
    elseif arrowType == UISubLimitedTrea.ARROW_TYPE_2 then
        zeroArrow = self.mMaxArrow
        rotationArrow = self.mMinArrow
    end
    return zeroArrow, rotationArrow, rewardTransPosInfo
end

function UISubLimitedTrea:OnClickHelpBtnFunc()
    local isLucky = self._curMagicWheelType == ModelCallHero.LUCKY
    local id = isLucky and 17 or 18
    local luckyNum
    if isLucky then
        local t = string.split(gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelLuckNum"), "=")
        luckyNum = tonumber(t[3])
    else
        local t = string.split(gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighLuckNum"), "=")
        luckyNum = tonumber(t[3])
    end
    local luckCountNum = 0
    local list = self:GetIntegralGetList()
    if #list > 0 then
        luckCountNum = list[#list].grad
    end
    GF.OpenWnd("UIBzTips", { refId = id, para = { luckyNum or 10, luckCountNum or 1000 } })
end

function UISubLimitedTrea:RefreshRewardShow()
    local itemIndexList = self:GetItemIndexList()
    local itemId, itemNum, quality, icon, extractCount
    local qualityRef
    local itemNumStr
    local rewardTransInfoList = self._rewardTransInfoList
    for i, v in ipairs(rewardTransInfoList) do
        local data = itemIndexList[i]
        local show = data ~= nil
        if show then
            itemId = data.itemId
            itemNum = data.itemNum

            --非装备类型
            if not (data.itemType == LItemTypeConst.TYPE_EQUIP) then
                quality = gModelItem:GeQualityByRefId(itemId)
            end

            if not quality then
                quality = gModelEquip:GetEquipQualityByRefId(itemId)
            end
            quality = quality or 1

            qualityRef = gModelItem:GetQualityRef(quality)
            local RewardBgTrans = v.RewardBgTrans
            if qualityRef then
                self:SetWndEasyImage(RewardBgTrans, qualityRef.circleBg1, function()
                    CS.ShowObject(RewardBgTrans, true)
                end)

                self:SetWndEasyImage(v.RewardTrans, qualityRef.circleBg2)
            end

            itemNumStr = LUtil.NumberCoversion(itemNum)
            self:SetWndText(v.UITextTrans, itemNumStr)

            local IconTrans = v.IconTrans
            icon = self:GetIconImg(data)
            self:SetWndEasyImage(IconTrans, icon)

            local MinIconTrans = v.MinIconTrans
            local showMinIcon = false
            local minIconRes
            local itemRef

            if not (data.itemType == LItemTypeConst.TYPE_EQUIP) then
                itemRef = gModelItem:GetRefByRefId(itemId)
            end

            if itemRef then
                if not string.isempty(itemRef.race) then
                    showMinIcon = true
                    minIconRes = itemRef.race
                elseif not string.isempty(itemRef.minIcon) then
                    showMinIcon = true
                    minIconRes = itemRef.minIcon
                end
            end
            if minIconRes then
                self:SetWndEasyImage(MinIconTrans, minIconRes)
            end
            CS.ShowObject(MinIconTrans, showMinIcon)

            local gray = false
            local ref = gModelCallHero:GetMagicWheelRewardRefByRefId(data.refId)
            if ref then
                extractCount = data.extractCount
                local extractLimit = tonumber(ref.extractLimit)
                if extractLimit == 1 and extractCount >= extractLimit then
                    gray = true
                end
            end
            self:SetImageAlpha(v.RewardBgTrans, 1)
            self:SetImageAlpha(v.IconTrans, 1)

            if gray then
                --设置好道具和图标部分

                --self:SetWndImageGray(v.IconTrans, gray)
                --self:SetWndImageGray(v.RewardBgTrans, gray)
                self:SetImageAlpha(v.RewardBgTrans, 0.6)
                self:SetImageAlpha(v.IconTrans, 0.6)

                self:SetWndText(v.GetTipsText, ccClientText(40220))
            end

            CS.ShowObject(v.GetTips, gray)

            self:SetWndClick(RewardBgTrans, function()
                self:OnClickRewardRootFunc(data)
            end)
            CS.ShowObject(v.EffRootTrans, false)
        end
        CS.ShowObject(v.root, show)
    end
    self:RefreshShowBigRewardTxt()
end

function UISubLimitedTrea:GetCallTypeBtnInfo(transInfo)
    local trans = transInfo.trans

    local NoSelImgTrans = self._isEnus and self:FindWndTrans(trans, "NoSelImg_en") or self:FindWndTrans(trans, "NoSelImg")
    local SelImgTrans = self._isEnus and self:FindWndTrans(trans, "SelImg_en") or self:FindWndTrans(trans, "SelImg")
    local LockImgTrans = self:FindWndTrans(trans, "LockImg")

    self:SetTextTile(NoSelImgTrans, transInfo.btnName)
    self:SetTextTile(SelImgTrans, transInfo.btnName)
    self:SetTextTile(LockImgTrans, transInfo.btnName)

    return {
        root = trans,
        NoSelImgTrans = NoSelImgTrans,
        SelImgTrans = SelImgTrans,
        LockImgTrans = LockImgTrans,
        functionId = transInfo.functionId,
        btnType = transInfo.btnType,
    }
end

function UISubLimitedTrea:GetItemDetailList()
    local itemDetail = self._itemDetail
    if not itemDetail or #itemDetail < 1 then
        return
    end
end

function UISubLimitedTrea:OnClickItemFunc(itemdata)
    local first = self:GetGradReward(itemdata.gradReward)
    if not first then
        return
    end

    --判断下 够不够 够的话 先去领取奖励 不然就显示
    local refIdList = self:GetIntegralCanGetRewardList()
    if not refIdList then
        gModelGeneral:ShowCommonItemTipWnd(first)
        return
    else
        if #refIdList < 1 then
            local scoreStr
            local getRewardType = self._getRewardType
            if getRewardType == ModelCallHero.LUCKY then
                scoreStr = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelLuckNum")
            else
                scoreStr = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighLuckNum")
            end
            if scoreStr then
                local reward = self:GetGradReward(scoreStr)
                if reward then
                    local rewardId = reward.itemId
                    local payName = gModelItem:GetNameByRefId(rewardId)
                    --屏蔽掉提示
                    --local str = string.replace(ccClientText(27806), payName)
                    --GF.ShowMessage(str)
                end
            end

            gModelGeneral:ShowCommonItemTipWnd(first)
            return
        end
    end
    gModelCallHero:OnMagicLuckyReceiveReq(refIdList)
end

function UISubLimitedTrea:ShowWndTip()
    local curMagicWheelType = self._curMagicWheelType
    local diaValue
    if curMagicWheelType == ModelCallHero.LUCKY then
        diaValue = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelRefExpend")
    else
        diaValue = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelHighRefExpend")
    end
    local list = string.split(diaValue, "=")
    local itemId = tonumber(list[2])
    local value = tonumber(list[3])

    local wndId = curMagicWheelType == ModelCallHero.LUCKY and 101001 or 101002
    local dia = gModelItem:GetNumByRefId(itemId)
    -- 花费钻石重置
    local func = function()
        if self:IsWndClosed() then
            return
        end
        if dia >= value then
            self:SendMagicWheelReset()
        else
            gModelGeneral:OpenGetWayWnd({ itemId = itemId })
        end
    end
    gModelGeneral:OpenUIOrdinTips({ refId = wndId, func = func, para = { value }, consume = { value, itemId } })
end

function UISubLimitedTrea:GetItemIndexList()
    local itemList = self._pbItemList or {}
    local itemIndexList = {}
    for i, v in ipairs(itemList) do
        local itemId = tonumber(v.itemId)
        if itemId and itemId > 0 then
            local ref = gModelCallHero:GetInitMagicWheelRewardRefByRefId(itemId)
            if ref then
                local reward = ref.reward
                local list = ref.list
                itemIndexList[list] = {
                    itemType = reward.itemType,
                    itemId = reward.itemId,
                    itemNum = reward.itemNum,
                    refId = itemId,
                    extractCount = v.extractCount,
                    extractMax = ref.extractMax,
                }
            end
        end
    end
    return itemIndexList
end

function UISubLimitedTrea:ShowBoxEff(showEff)
    local dpSpine = self:FindWndSpineByKey(self._spBoxAniKey)
    if not dpSpine then
        return
    end
    local aniName = showEff and "doudong" or "jingtai"
    dpSpine:PlayAnimationSolid(aniName, true)
end

function UISubLimitedTrea:OnMagicWheelResp(pb)
    self._pbItemList = pb.items
    self:SaveItemPosList()
    self._wheelType = pb.wheelType
    self._itemDetail = pb.itemDetail
    self._rewardItems = pb.rewardItems
    local old = self._extractCount
    if old then
        old = old + #self._rewardItems
    else
        old = #self._rewardItems
    end
    self._extractCount = old
    self:RefreshShowBigRewardTxt()
    LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_LUCKY_MIRROR)

    if not self._jumpRefreshAniStatus and self._isCanPlayGetRewadAnim then
        self._isCanPlayGetRewadAnim = false
        local effectName = self._viewShowInfoList[self._curMagicWheelType].runSpine
        self._effectList[effectName]:SetVisible(true)
    end

    self:RunRewardAni(pb)
end

function UISubLimitedTrea:GetCallBtnTransInfo(transInfo)
    local btnTrans = transInfo.btnTrans
    local effRootTrans = self:FindWndTrans(btnTrans, "EffRoot")
    local BtnNameTrans = self:FindWndTrans(btnTrans, "BtnName")
    local BtnImgTrans = self:FindWndTrans(btnTrans, "BtnImg")
    local TimeTxtTrans = self:FindWndTrans(btnTrans, "TimeTxt")
    local PayDivTrans = self:FindWndTrans(btnTrans, "PayDiv")
    local IconImgTrans = self:FindWndTrans(PayDivTrans, "IconImg")
    local NumTxtTrans = self:FindWndTrans(PayDivTrans, "NumTxt")
    local FreeTxtTrans = self:FindWndTrans(btnTrans, "FreeTxt")
    local LimitTxtTrans = self:FindWndTrans(btnTrans, "LimitTxt")
    local RedPointTrans = self:FindWndTrans(btnTrans, "redPoint")

    self:CreateBtnEff(effRootTrans, transInfo.effName)

    return {
        BtnTrans = btnTrans,
        BtnNameTrans = BtnNameTrans,
        BtnImgTrans = BtnImgTrans,
        TimeTxtTrans = TimeTxtTrans,
        PayDivTrans = PayDivTrans,
        IconImgTrans = IconImgTrans,
        NumTxtTrans = NumTxtTrans,
        FreeTxtTrans = FreeTxtTrans,
        LimitTxtTrans = LimitTxtTrans,
        RedPointTrans = RedPointTrans,
    }
end

function UISubLimitedTrea:OnClickTimeTreasureTypeFunc(subPage)
    if self._resetPlayAniStatus then
        GF.ShowMessage(ccClientText(14616))
        return
    end
    if self._sendCallStatus then
        return
    end
    if self._subPage == subPage then
        return
    end
    self._subPage = subPage
    self:RefreshCurMagicWheelType()
    self:ReqServerData()
    self:RefreshShow()
end

function UISubLimitedTrea:OnClickMiracleBtnFunc()
    self:OnClickTimeTreasureTypeFunc(2)
end

function UISubLimitedTrea:DisposeLuckyReceive(luckyReceive)
    self._luckyReceiveList = {}
    for i, v in ipairs(luckyReceive) do
        self._luckyReceiveList[v] = v
    end
end

function UISubLimitedTrea:InitEvent()
    self:SetWndClick(self.mMinCallBtn, function()
        self:OnClickMinCallBtnFunc()
    end)
    self:SetWndClick(self.mMaxCallBtn, function()
        self:OnClickMaxCallBtnFunc()
    end)
    self:SetWndClick(self.mLuckyBtn, function()
        self:OnClickLuckyBtnFunc()
    end)
    self:SetWndClick(self.mMiracleBtn, function()
        self:OnClickMiracleBtnFunc()
    end)
    self:SetWndClick(self.mFreeRefreshBtn, function()
        self:OnClickFreeRefreshBtnFunc()
    end)
    self:SetWndClick(self.mBoxBtn, function()
        self:OnClickBoxBtnFunc()
    end)
    self:SetWndClick(self.mDetailsBtn, function()
        self:OnClickDetailsBtnFunc()
    end)
    self:SetWndClick(self.mLogBtn, function()
        self:OnClickLogBtnFunc()
    end)
    self:SetWndClick(self.mShopBtn, function()
        self:OnClickShopBtnFunc()
    end)
    self:SetWndClick(self.mJumpAniSelBtn, function()
        self:OnClickJumpAniSelBtnFunc()
    end)
    self:SetWndClick(self.mHelpBtn, function()
        self:OnClickHelpBtnFunc()
    end)
end

function UISubLimitedTrea:RefreshCurMagicWheelType()
    local subPage = self._subPage
    self._curMagicWheelType = subPage == 2 and ModelCallHero.MIRACLE or ModelCallHero.LUCKY

end

function UISubLimitedTrea:OnClickDetailsBtnFunc()
    --[[	local itemList = gModelCallHero:GetMagicWheelExplainRefByType(self._curMagicWheelType)
        GF.OpenWnd("UIProbabilitySow",{itemList = itemList})]]

    GF.OpenWnd("UIYellHRew", { curMagicWheelType = self._curMagicWheelType, viewType = 3 })
end

function UISubLimitedTrea:InitText()
    self:SetWndText(self.mJumpAniSelBgTxt, ccClientText(14617))
    self:SetTextTile(self.mDetailsBtn, ccClientText(21813))
    self:SetTextTile(self.mShopBtn, ccClientText(11676))
    self:SetTextTile(self.mLogBtn, ccClientText(11672))

    self:SetWndText(self.mMinBtnName, ccClientText(11694))
    self:SetWndText(self.mMaxBtnName, ccClientText(11695))
end

function UISubLimitedTrea:OnDrawSliderReward(item, itemdata, itempos)
    local ScheduleNumTrans = self:FindWndTrans(item, "ScheduleNum")
    local RewardDivTrans = self:FindWndTrans(item, "RewardDiv")
    local BgTrans = self:FindWndTrans(RewardDivTrans, "Bg")

    local IconTrans = self:FindWndTrans(BgTrans, "Icon")
    local MaskTrans = self:FindWndTrans(BgTrans, "Mask")
    local redPointTrans = self:FindWndTrans(BgTrans, "redPoint")
    local GetTrans = self:FindWndTrans(BgTrans, "Get")

    local BlueNumTxt = self:FindWndTrans(BgTrans, "BlueNumTxt")
    local YellowNumTxt = self:FindWndTrans(BgTrans, "YellowNumTxt")

    local grad = itemdata.grad
    self:SetWndText(ScheduleNumTrans, grad)

    local first = self:GetGradReward(itemdata.gradReward)
    if first then
        local itemId = first.itemId
        local icon = gModelItem:GetItemIconByRefId(itemId)
        self:SetWndEasyImage(IconTrans, icon)

        local count = first.itemNum
        self:SetWndText(BlueNumTxt, count)
        self:SetWndText(YellowNumTxt, count)
    end
    CS.ShowObject(BlueNumTxt, self._curMagicWheelType == ModelCallHero.LUCKY)
    CS.ShowObject(YellowNumTxt, self._curMagicWheelType == ModelCallHero.MIRACLE)

    local itemBg2 = itemdata.itemBg2
    self:SetWndEasyImage(BgTrans, itemBg2)

    local isFull = self._lucky >= grad
    if isFull then
        local itemBg1 = itemdata.itemBg1
        self:SetWndEasyImage(MaskTrans, itemBg1)
    end
    CS.ShowObject(MaskTrans, isFull)

    local luckyReceiveList = self._luckyReceiveList or {}
    local isGet = isFull and not luckyReceiveList[itemdata.refId] or false
    CS.ShowObject(redPointTrans, isGet)

    local isGray = luckyReceiveList[itemdata.refId]
    --self:SetWndImageGray(IconTrans, isGray)
    CS.ShowObject(GetTrans, isGray)
    local BtnTrans = self:FindWndTrans(BgTrans, "Btn")
    self:SetWndClick(BtnTrans, function()
        self:OnClickItemFunc(itemdata)
    end)

    --设置物体的位置
    local posxScale = grad / self._curMaxLength
    local width = self.mSliderBg.rect.width

    item.anchoredPosition = Vector2.New(width * posxScale, 12)
end

function UISubLimitedTrea:GetIconImg(itemdata)
    local itemType = itemdata.itemType
    local itemId = itemdata.itemId
    local icon = ""
    if itemType == LItemTypeConst.TYPE_EQUIP then
        icon = gModelEquip:GetEquipImgByRefId(itemId)
    elseif itemType == LItemTypeConst.TYPE_ITEM then
        icon = gModelItem:GetItemIconByRefId(itemId)
    end
    return icon
end

function UISubLimitedTrea:GetRunRewardAniTime()
    local drawAniDisplayTime = gModelCallHero:GetMagicWheelConfigRefByKey("drawAniDisplayTime")
    if not drawAniDisplayTime then
        if LOG_INFO_ENABLED then
            printInfoNR("MagicWheelConfigRef表里的 drawAniDisplayTime 字段用来表示抽奖动画展示时间，默认0.6秒")
        end
        drawAniDisplayTime = 0.6
    end
    return drawAniDisplayTime
end

function UISubLimitedTrea:GetIntegralGetList()
    local list = {}
    local curMagicWheelType = self._curMagicWheelType
    if curMagicWheelType == ModelCallHero.LUCKY then
        -- 幸运魔轮
        list = gModelCallHero:GetLuckMagicWheelLuckyRef()
    elseif curMagicWheelType == ModelCallHero.MIRACLE then
        -- 奇迹魔轮
        list = gModelCallHero:GetMiracleMagicWheelLuckyRef()
    end
    return list
end

function UISubLimitedTrea:OnClickBoxBtnFunc()
    if self._sendCallStatus then
        return
    end
    if self._resetPlayAniStatus then
        return
    end
    GF.OpenWnd("UIIntegralSow", {
        viewType = 2,
        getRewardType = self._curMagicWheelType,
        subPage = self._subPage,
        page = self._page,
        magicType = self._curMagicWheelType
    })
end

function UISubLimitedTrea:PlayReSetAni(pb)
    self:TweenSeqKill(self._reSetAniKey)
    local seqTween = self:TweenSeqCreate(self._reSetAniKey, function(seq)
        local rewardTransInfoList = self._rewardTransInfoList
        local intervalTime = 0.1
        local len = #rewardTransInfoList
        local payTime = len * intervalTime
        for i, v in ipairs(rewardTransInfoList) do
            local rootTrans = v.root
            local hideTime = intervalTime + i * 0.1
            local scaleTween = rootTrans:DOScale(Vector3(0, 0, 0), hideTime)
            seq:Join(scaleTween)
        end
        seq:AppendInterval(0.1)
        seq:AppendCallback(function()
            self:OnMagicWheelInfoResp(pb.info)
        end)
        payTime = payTime + 0.1
        for i, v in ipairs(rewardTransInfoList) do
            local rootTrans = v.root
            local hideTime = intervalTime + i * 0.1
            local scaleTween = rootTrans:DOScale(Vector3(1, 1, 1), hideTime)
            seq:Join(scaleTween)
        end
        return seq
    end)
    seqTween:OnComplete(function()
        self._resetPlayAniStatus = false
        self:TweenSeqKill(self._reSetAniKey)
    end)
    seqTween:PlayForward()
end

function UISubLimitedTrea:PlaySpineAni(aniInfo)
    local aniName = aniInfo.aniName
    local isLoop = aniInfo.loop or false
    local callBackFunc = aniInfo.callBackFunc
    local spine = self:FindWndSpineByKey(self._spAniKey)
    if spine then
        if callBackFunc then
            spine:OnAniamationComplete(function()
                callBackFunc()
            end)
        end
        spine:PlayAnimationSolid(aniName, isLoop)
    end
end

function UISubLimitedTrea:InitRewardTransInfo()
    local rewardTransList = {
        self.mReward1, self.mReward2, self.mReward3, self.mReward4, self.mReward5, self.mReward6, self.mReward7, self.mReward8,
    }
    local rewardTransInfo
    local rewardTransInfoList = {}
    for i, v in ipairs(rewardTransList) do
        rewardTransInfo = self:GetRewardTransInfo(v)
        table.insert(rewardTransInfoList, rewardTransInfo)
    end
    self._rewardTransInfoList = rewardTransInfoList
end

function UISubLimitedTrea:OnSliderMagicWheelInfoResp(pb)

    self:DisposeLuckyReceive(pb.luckyReceive)
    self:RefreshIntegralShow(self._lucky)
end

function UISubLimitedTrea:OnClickMaxCallBtnFunc()
    self._isCanPlayGetRewadAnim = true
    self:SendMagicWheelMsg(2)
end

function UISubLimitedTrea:InitCallTypeBtnInfo()
    local callTypeBtnList = {
        {
            trans = self.mLuckyBtn,
            btnName = ccClientText(14600),
            functionId = 0,
            btnType = ModelCallHero.LUCKY,
        },
        {
            trans = self.mMiracleBtn,
            btnName = ccClientText(14601),
            functionId = 16700011,
            btnType = ModelCallHero.MIRACLE,
        },
    }

    local callTypeBtnInfo
    local callTypeBtnInfoList = {}
    for i, v in ipairs(callTypeBtnList) do
        callTypeBtnInfo = self:GetCallTypeBtnInfo(v)
        table.insert(callTypeBtnInfoList, callTypeBtnInfo)
    end
    self._callTypeBtnInfoList = callTypeBtnInfoList
end

function UISubLimitedTrea:ShowEnd()
    self:TimerStop(self._runShowRewardTimerKey)

    local effectName = self._viewShowInfoList[self._curMagicWheelType].runSpine
    self._effectList[effectName]:SetVisible(false)

    local zeroArrow, rotationArrow, rewardTransPosInfo = self:GetZeroArrorAndRotationArrow()
    if rewardTransPosInfo then
        local index = rewardTransPosInfo.index
        local rewardTransInfoList = self._rewardTransInfoList or {}
        local transInfo = rewardTransInfoList[index]
        if transInfo then
            --屏蔽掉选中的特效
            --local EffRootTrans = transInfo.EffRootTrans
            --CS.ShowObject(EffRootTrans, false)
            --local key = EffRootTrans:GetInstanceID()
            --local spine = self:FindWndSpineByKey(key)
            --if not spine then
            --    self:CreateWndSpine(EffRootTrans, "fx_shiguangbaozanzhongjiang", key, false, function(dpSpine)
            --        dpSpine:PlayAnimationSolid("animation", false)
            --    end)
            --else
            --    spine:PlayAnimationSolid("animation", false)
            --end
            --CS.ShowObject(EffRootTrans, true)
        end
    end
    self:RunRewardFunc()
end

function UISubLimitedTrea:OnClickShopBtnFunc()
    local func = function()
        gModelCallHero:OpenCallWnd({ page = 3 })
    end
    local magicWheelShopJump = gModelCallHero:GetMagicWheelConfigRefByKey("MagicWheelShopJump")
    gModelFunctionOpen:Jump(magicWheelShopJump, nil, func)

    local callName = gModelCallHero:GetCallWndName()
    GF.CloseWndByName(callName)
end

function UISubLimitedTrea:OnClickNeedAddBtnFunc(itemId)
    gModelGeneral:OpenGetWayWnd({ itemId = itemId })
end
--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UISubLimitedTrea


