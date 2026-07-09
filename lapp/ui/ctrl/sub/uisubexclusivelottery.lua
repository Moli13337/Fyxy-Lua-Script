---
--- Created by BY.
--- DateTime: 2023/10/20 17:05:17
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubExclusiveLottery:LChildWnd
local UISubExclusiveLottery = LxWndClass("UISubExclusiveLottery", LChildWnd)
local YXTween = YXTween
local Tweening = DG.Tweening
local EaseInQuad = Tweening.Ease.InQuad

local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubExclusiveLottery:UISubExclusiveLottery()
    self._timeRankKey = "_timeRankKey"                                --排行榜倒计时
    self._timeKey = "_timeKey"
    self._timeFreeKey = "_timeFreeKey"
    self._rankTweenKey = "_rankTweenKey"

    self._isUnfold = true
    self._rankScoreImgList = {
        [1] = "public_num_1",
        [2] = "public_num_2",
        [3] = "public_num_3",
    }

    self._jumpAniStatus = gModelActivity:GetExclusiveLotteryJumpAniState()


end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubExclusiveLottery:OnWndClose()
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubExclusiveLottery:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubExclusiveLottery:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitDate()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    self:RefreshForeign()
end
function UISubExclusiveLottery:OnClickOneTen(type)
    local sid = self._sid
    gModelActivity:GetCallDataBySid(sid, self.turnPageEnum, type, self:GetParentWndName(), type == 1 and 1 or 10)
end

function UISubExclusiveLottery:GetIndexStr(numValue)
    return gModelEquip:GetLevelDesStr(numValue)
end

function UISubExclusiveLottery:OnRankTimeText()
    local _rankTimeValue = self._rankTimeValue
    if not _rankTimeValue then
        return
    end

    local time = _rankTimeValue - GetTimestamp()
    if time <= 0 then
        self:TimerStop(self._timeRankKey)
        self:SetWndText(self.mRankTimeTxt, ccClientText(23253))
        return
    end
    local timeStr = LUtil.FormatTimespanCn(time)
    timeStr = string.replace(ccClientText(23252), timeStr)
    self:SetWndText(self.mRankTimeTxt, timeStr)
end

function UISubExclusiveLottery:InitRankBaseInfo()
    if self._rankBaseInfo then
        return
    end

    local activityData = gModelActivity:GetWebActivityDataById(self._sid)
    local config = activityData.config
    local limitRank_temp = config.rankLimit

    if string.isempty(limitRank_temp) then
        return
    end

    limitRank_temp = string.split(limitRank_temp, "|")
    local limitRankText = config.rankTxt
    self._rankBaseInfo = {}
    for k, v in ipairs(limitRank_temp) do
        local temp = string.split(v, "=")
        self._rankBaseInfo[checknumber(temp[1])] = {}
        self._rankBaseInfo[checknumber(temp[1])].score = checknumber(temp[2])
        self._rankBaseInfo[checknumber(temp[1])].notEnoughDes = string.replace(limitRankText, checknumber(temp[2]))
    end
    printInfoN2("--", "--")
end

function UISubExclusiveLottery:OnClickLook()
    local _mySelect = self._mySelect
    if _mySelect <= 0 then
        return
    end
    local list = self._pages[self.turnPageEnum].entry
    local entry = list[_mySelect]
    if not entry then
        return
    end

    local itemData = entry.items[1]
    if self._templateType == 0 then
        gModelGeneral:ShowCommonItemTipWnd(itemData)

    elseif self._templateType == 1 then
        local list = self._pages[self.turnPageEnum].entry
        local entry = list[_mySelect]
        if not entry then
            return
        end

        local itemdata = entry.items[1]
        local refId = itemdata.itemId
        local itemRef = gModelItem:GetRefByRefId(refId)

        local petRefId = string.split(itemRef.typeDate, ",")
        local petId = checknumber(petRefId[1])

        GF.OpenWnd("UIPeView", { refId = petId, isPreview = true, playerId = gLGameLogin:GetPlayerId() })

    elseif self._templateType == 2 then
        local itemRef = gModelItem:GetRefByRefId(itemData.itemId)
        local dragonRefId
        if itemRef.type == ModelItem.TTEM_TYPE_DRACONIC_ITEM then
            dragonRefId = itemRef.refId
        elseif itemRef.type == ModelItem.TTEM_TYPE_DRACONIC then
            dragonRefId = checknumber(itemRef.typeDate)
        end

        GF.OpenWnd("UIDraconicUpStar", { refId = dragonRefId, tips = true, maxPre = true })
    end


end
function UISubExclusiveLottery:GetRankAwardList()
    local sid = self._sid
    local _pages = self._pages
    if not _pages then
        return
    end
    local _rankRewardId = self._rankRewardId or 3
    local _rewardList = nil
    local page = _pages[_rankRewardId]
    if page then
        _rewardList = LxDataHelper.SevenParseRewardList(sid, page)
    end
    return _rewardList
end

function UISubExclusiveLottery:InitRankRewardList(listTrans, list)
    local key = listTrans:GetInstanceID()
    local uiRewardList = self:FindUIScroll(key)
    if uiRewardList then
        uiRewardList:RefreshList(list)
    else
        uiRewardList = self:GetUIScroll(key)
        uiRewardList:Create(listTrans, list, function(...)
            self:OnDrawRewardCell(...)
        end)
    end
    local enable = #list > 3
    uiRewardList:EnableScroll(enable, true)
end

function UISubExclusiveLottery:OnClickJumpAniFunc()
    self._jumpAniStatus = not self._jumpAniStatus
    gModelActivity:SetExclusiveLotteryJumpAniState(self._jumpAniStatus)
    self:RefreshJumpAniStatus()
end
function UISubExclusiveLottery:RefreshForeign()
    if self._isVie then
        self:InitTextLineWithLanguage(self.mJumpAniBgTxt,0)
        LxUiHelper.SetSizeWithCurAnchor(self.mJumpAniBgTxt,0,80)
    end
    if self.jpj then
        self:SetAnchorPos(self.mJumpAniBtn,Vector2.New(-19,-88))
        self:InitTextLineWithLanguage(self.mJumpAniBgTxt,0)
        LxUiHelper.SetSizeWithCurAnchor(self.mJumpAniBgTxt,0,80)
    end
end
function UISubExclusiveLottery:OnClickCut(isAdd)
    if not self:CheckCanChangeWish() and not isAdd then return end

    local _config = self._config
    local pageId = self.turnPageEnum
    local pages = self._pages
    local page = pages[pageId]
    if not page then
        return
    end
    local list = {}
    local wishKeys = {}
    local wishHero = string.split(_config.wishHero, ";")
    local len = 0
    for i, v in ipairs(wishHero) do
        local arr = string.split(v, "=")
        wishKeys[tonumber(arr[1])] = true
        len = len + 1
    end
    if len <= 1 then
        return
    end
    local entry = page.entry
    for i, v in ipairs(entry) do
        if wishKeys[v.entryId] then
            table.insert(list, v)
        end
    end
    local entryExtraShowMap = {}
    local spNum = _config.spNum
    if not string.isempty(spNum) then
        local spBg = _config.spBg
        local spTxt = _config.spTxt
        local spNums = string.split(spNum,",")
        for i,v in ipairs(spNums) do
            v = checknumber(v)
            entryExtraShowMap[v] = {
                spBg = spBg,
                spTxt = spTxt,
            }
        end
    end
    GF.OpenWnd("UIActLotterySagaSel", {
        sid = self._sid,
        entry = list,
        selEntryId = self._mySelect,
        templateType = self._templateType,
        config = self._config,
        canAwardReplace = self._canAwardReplace,
        awardReplaceTxt = self._awardReplaceTxt,
        entryExtraShowMap = entryExtraShowMap,
    })
end
function UISubExclusiveLottery:RefreshRank()
    local _rankId = self._rankId

    local list = {}
    local rankList = gModelRank:GetRankListInfo(2, _rankId)

    for i = 1, 3 do
        local name

        if self._rankBaseInfo and self._rankBaseInfo[i] then
            name = self._rankBaseInfo[i].notEnoughDes
        else
            name = ccClientText(44808)
        end

        table.insert(list, {
            name = name,
            rank = i,
            score = 0,
            playerId = "-1",
        })
    end

    for i = 1, 3 do
        local data = rankList[i]

        if data and data.rank <= 3 then
            local temp_data = {
                name = data.info._name,
                rank = data.rank,
                score = data.score,
                playerId = data.info._playerId,
            }

            list[data.rank] = temp_data
        end
    end

    local len = #list

    CS.ShowObject(self.mRankEmptyText, len <= 0)

    local uiRankList = self._uiRankList
    if uiRankList then
        uiRankList:RefreshList(list)
    else
        uiRankList = self:GetUIScroll("mRankList")
        self._uiRankList = uiRankList
        uiRankList:Create(self.mRankList, list, function(...)
            self:RankListItem(...)
        end)
    end

    local myRankInfo = gModelRank:GetMeRank()
    local myRank = myRankInfo.rank

    local isHaveRankInfo = myRank > 0 and myRank
    self:SetWndText(self.mMyRankNum, isHaveRankInfo or ccClientText(44808))  --[44808] [暫無上榜騎士]

    CS.ShowObject(self.mMyRankRoot, myRank > 3)
    CS.ShowObject(self.mMyName, isHaveRankInfo)
    self:SetWndText(self.mMyName, gModelPlayer:GetPlayerName())

    CS.ShowObject(self.mRankRewardDiv, myRank > 0)
    CS.ShowObject(self.mMyNoAwardDiv, myRank <= 0)
    local curRankInfo
    if myRank > 0 and self._isShowRank then
        local rankAwardList = self:GetRankAwardList()
        for i, v in ipairs(rankAwardList) do
            local ranks = string.split(v.rank, ",")
            if tonumber(ranks[1]) <= myRank and (myRank <= tonumber(ranks[2]) or ranks[2] == "-1") then
                curRankInfo = v
                break
            end
        end
        if not curRankInfo then
            return
        end
        local reward = LxDataHelper.ParseItem(curRankInfo.reward)
        local rewardLen = #reward
        local showUIList = rewardLen > 3 and self.mRankRewardMoreList or self.mRankRewardList
        --local hideUIList = isShowMore and self.mRankRewardList or self.mRankRewardMoreList
        CS.ShowObject(self.mRankRewardMoreList, rewardLen > 3)
        CS.ShowObject(self.mRankRewardList, rewardLen <= 3)
        self:InitRankRewardList(showUIList, reward)
    end
end
function UISubExclusiveLottery:OnDrawRewardCell(list, item, itemdata, itempos)
    local IconTrans = self:FindWndTrans(item, "CommonUI/Icon")
    local NumTxtTrans = self:FindWndTrans(item, "NumTxt")

    self:CreateCommonIconImpl(IconTrans, itemdata)
    self:SetWndText(NumTxtTrans, LUtil.NumberCoversion(itemdata.itemNum))
end

function UISubExclusiveLottery:CheckCanChangeWish()
    local canChangeWishHero = self._canChangeWishHero or false
    if canChangeWishHero and not self._canAwardReplace then
        local DropSum = self._dropNum
        if not DropSum or DropSum > 0 then
            canChangeWishHero = false
        end
    end
    return canChangeWishHero
end

function UISubExclusiveLottery:SetTime()
    local activityData = gModelActivity:GetActivityBySid(self._sid)
    if not activityData then
        return
    end
    local endTime = activityData.endTime
    if endTime == 0 then
        self:TimerStop(self._timeKey)
        self:SetWndText(self.mTimeText, ccClientText(18404))
        CS.ShowObject(self.mTimeBg, true)
        return
    end
    local time = GetTimestamp()
    local timespan = endTime - time
    local timeStr = ""
    if (timespan < 0) then
        timeStr = ccClientText(14301)
        self:TimerStop(self._timeKey)
    else
        timeStr = LUtil.FormatTimespanCn(timespan)
        timeStr = string.replace(ccClientText(18400), timeStr)
    end
    self:SetWndText(self.mTimeText, timeStr)
    CS.ShowObject(self.mTimeBg, true)
end

function UISubExclusiveLottery:OnTipsClick()
    GF.OpenWnd("UIBzTips", { title = self._helpTitle, text = self._helpContent })
end

function UISubExclusiveLottery:RefreshPetShow(dataS)
    local _mySelect = self._mySelect
    if _mySelect <= 0 then
        return
    end
    local list = self._pages[self.turnPageEnum].entry
    local entry = list[_mySelect]
    if not entry then
        return
    end

    local itemdata = entry.items[1]
    local refId = itemdata.itemId
    local itemRef = gModelItem:GetRefByRefId(refId)
    local petRefId = string.split(itemRef.typeDate, ",")
    petRefId = checknumber(petRefId[1])
    local petCfg = GameTable.MagicPetRef[petRefId]

    local prefabName = petCfg.spine

    local petDrawing = prefabName
    --中间的部分
    local oldHeroDrawing = self._oldHeroDrawing
    if oldHeroDrawing and oldHeroDrawing ~= petDrawing then
        self:DestroyWndSpineByKey("heroSpine")
    end
    self:CreateWndSpine(self.mHeroSpine, petDrawing, "heroSpine", false)
    self._oldHeroDrawing = petDrawing

    --右下角的部分
    local oldHeroPrefab = self._oldHeroPrefab
    if oldHeroPrefab and oldHeroPrefab ~= prefabName then
        self:DestroyWndSpineByKey("heroSpinePos")
    end
    self:CreateWndSpine(self.mPetSpinePos, prefabName, "heroSpinePos", false, function(spine)
        spine:MatchRectTransform()
    end)
    self._oldHeroPrefab = prefabName

    --设置左上角部分
    if self._templateType == 1 then
        self:SetWndEasyImage(self.mHeroRaceImg, "activity_120_icon_pet", function()
            CS.ShowObject(self.mHeroRaceImg, true)
        end)
    end

    local qualityIcon = GameTable.RarityRef[petCfg.quality]
    self:SetWndEasyImage(self.mHeroZZImg, qualityIcon.qualityText)

    --local list = self._pages[self.turnPageEnum].entry
    --local entry = list[_mySelect]

    local pageData = gModelActivity:GetWebActivityPageData(self._sid, self.turnPageEnum)
    local entryData = pageData.entries[_mySelect]
    local moreInfo = entryData.moreInfo

    if moreInfo then
        moreInfo = gModelActivity:GetLngNameById(moreInfo)
        local des = string.split(moreInfo, "|")
        des = des[3]
        self:SetWndText(self.mHeroNickName, ccLngText(des) or "")
        self:SetWndText(self.mHeroName, petCfg and ccLngText(petCfg.name) or "")
    else
        self:SetWndText(self.mPetName, petCfg and ccLngText(petCfg.name) or "")
    end


end

function UISubExclusiveLottery:SetFreeEndTime()

    local now = GetTimestamp()
    local date = LUtil.OSDate("*t", now)
    --0 点部分
    local _endTime = LUtil.OSTime({ year = date.year, month = date.month, day = date.day + 1, hour = 0, min = 0, sec = 0 })  --凌晨0点为刷新点
    _endTime = _endTime - GetTimestamp()
    if _endTime and _endTime > 0 then
        self:SetFreeTime()
        self:TimerStop(self._timeFreeKey)
        self:TimerStart(self._timeFreeKey, 1, false, -1)

    end
end
function UISubExclusiveLottery:ResetData(pb)
    local _pages = self._pages or {}
    for i, v in ipairs(pb.pages) do
        local page = gModelActivity:GenerateActivePageDataFromPb(v)
        local pageId = page.pageId
        _pages[pageId] = page
    end
    self._pages = _pages
    self:RefreshData()
end

function UISubExclusiveLottery:SetFreeTime()
    local now = GetTimestamp()
    local date = LUtil.OSDate("*t", now)
    --0 点部分
    local endTime = LUtil.OSTime({ year = date.year, month = date.month, day = date.day + 1, hour = 0, min = 0, sec = 0 })  --凌晨0点为刷新点
    endTime = endTime - GetTimestamp()

    CS.ShowObject(self.mFreeCutDownTime, false)

    if endTime == 0 then
        self:TimerStop(self._timeFreeKey)
        self:SetWndText(self.mFreeCutDownTime, ccClientText(18404))
        return
    end
    --local time = GetTimestamp()
    --local timespan = endTime - time
    local timeStr = ""
    if (endTime < 0) then
        timeStr = ccClientText(14301)
        self:TimerStop(self._timeFreeKey)
    else
        timeStr = LUtil.FormatTimespanCn(endTime)
        timeStr = string.replace(ccClientText(44803), timeStr)
    end
    self:SetWndText(self.mFreeCutDownTime, timeStr)
    CS.ShowObject(self.mFreeCutDownTime, true)
end

--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UISubExclusiveLottery:RefreshData()
    local sid = self._sid
    if not sid then
        return
    end
    local activityDataS = gModelActivity:GetActivityBySid(sid)
    if not activityDataS then
        return
    end
    --------------------------------------后端数据------------------------------------------------
    local dataS = JSON.decode(activityDataS.moreInfo)
    local freeNum = dataS.freeNum or 0                --剩余免费次数
    local callNum = dataS.callNum or 0                --已购买次数
    local mySelect = dataS.mySelect or 0            --选择掉落奖励entryId
    local myDropNum = dataS.myDropNum or 0            --抽奖次数
    local dropNumToday = dataS.dropNumToday or 0    --今日总抽奖次数
    local myRankScore = dataS.rankScore or 0    --今日总抽奖次数
    local dropNum = dataS.dropNum or 0
    if LOG_INFO_ENABLED then
        print("总抽奖次数：" .. tostring(dropNum))
    end
    self._freeNum = freeNum
    self._callNum = callNum
    self._mySelect = mySelect
    self._myDropNum = myDropNum
    self._dropNumToday = dropNumToday
    self._myRankScore = myRankScore
    self._dropNum = dropNum
    --------------------------------------后端数据------------------------------------------------

    CS.ShowObject(self.mPop1, mySelect <= 0)  -- 未选择
    CS.ShowObject(self.mPop2, mySelect > 0)  -- 选择过
    self:RefreshItem()
    if mySelect <= 0 then
        return
    end

    if self._templateType == 0 then
        self:RefreshShowHero()
        self:RefreshBottomText()
    elseif self._templateType == 1 then
        self:RefreshPetShow(dataS)
        self:RefreshBottomText()

    elseif self._templateType == 2 then
        self:RefreshDragonShow()
        self:RefreshBottomText()
    end

    self:RefreshShowChangeBtn()

end

function UISubExclusiveLottery:OnClickDetails()
    local _config = self._config

    local _mySelect = self._mySelect
    local list = self._pages[self.turnPageEnum].entry
    local entry = list[_mySelect]
    --增加
    local data = {
        title = _config.binWeightShow,
        policyTxt = _config.policyTxt,
        helpTitle = _config.callHelpTitleTxt,
        helpTxt = _config.callHelpTitle,
        heroImg = _config.callImage1,
        heroImgPos = _config.callImagePos1,
        botImg = _config.callImage2,
        botImgPos = _config.callImagePos2,
        rewardList = self._pages[self.turnPageEnum].entry,
        listType = 2,
        sid = self._sid,
        select = entry,
    }

    GF.OpenWnd("UIYellConstellationRule", { ruleData = data })
end

function UISubExclusiveLottery:RefreshShowChangeBtn()
    local canChangeWishHero = self:CheckCanChangeWish()
    --隐藏掉对应的按钮
    CS.ShowObject(self.mHeroUpImg, canChangeWishHero)
    CS.ShowObject(self.mBtnCut, canChangeWishHero)
end

function UISubExclusiveLottery:OnClickRank()
    local sid = self._sid
    local _rankId = self._rankId
    local _rewardList = self:GetRankAwardList()
    GF.OpenWndBottom("UIRkPop", { refId = _rankId, sid = sid, rewardList = _rewardList, rankBaseInfo = self._rankBaseInfo })
end

function UISubExclusiveLottery:RefreshBtnText()
    local sid = self._sid
    local config = self._config
    if not sid then
        return
    end
    local costOne1, costOne2, costTen1, costTen2, callBtnTxt = config.costOne1, config.costOne2, config.costTen1, config.costTen2, config.callBtnTxt

    local _costOne1 = LxDataHelper.ParseItem_3(costOne1)
    local _costOne2 = LxDataHelper.ParseItem_3(costOne2)
    local _costTen1 = LxDataHelper.ParseItem_3(costTen1)
    local _costTen2 = LxDataHelper.ParseItem_3(costTen2)
    local bagItemNum = gModelItem:GetNumByRefId(_costOne2.itemId)
    local bagTenItemNum = gModelItem:GetNumByRefId(_costTen2.itemId)
    local freeNum = self._freeNum
    local btnImgs = string.split(callBtnTxt, "=")
    self._callBtnImg = {
        freeImg = btnImgs[1],
        onCall = btnImgs[2],
        tenCall = btnImgs[3],
    }
    if LxUiHelper.IsImgPathValid(self._callBtnImg.freeImg) then
        self:SetWndEasyImage(self.mOneCall_Img, self._callBtnImg.freeImg, nil, true)
    end
    if LxUiHelper.IsImgPathValid(self._callBtnImg.freeImg) then
        self:SetWndEasyImage(self.mTenCall_Img, self._callBtnImg.freeImg, nil, true)
    end

    if not string.isempty(callBtnTxt) then
        local _callBtnTxt = string.split(callBtnTxt, "=")
        local btnOneStr = freeNum > 0 and _callBtnTxt[1] or _callBtnTxt[2]
        --self:SetWndButtonText(self.mBtnOne,btnOneStr)
        self:SetWndText(self.mOneText, btnOneStr)
        self:SetWndText(self.mTenText, _callBtnTxt[3])
        --self:SetWndButtonText(self.mBtnTen,_callBtnTxt[3])
    end

    CS.ShowObject(self.mOneCostText, freeNum < 1)
    CS.ShowObject(self.mOneCallRedPoint, freeNum >= 1)

    if freeNum < 1 then
        local isItemCost = bagItemNum >= 1
        local oneCostStr = isItemCost and _costOne2.itemNum or _costOne1.itemNum
        local oneCostRefId = isItemCost and _costOne2.itemId or _costOne1.itemId
        local icon, iconBg = gModelItem:GetItemImgByRefId(oneCostRefId)
        self:SetWndText(self.mOneCostText, oneCostStr)
        self:SetWndEasyImage(self.mOneCostIcon, icon)

        self:SetFreeEndTime()

        if LxUiHelper.IsImgPathValid(self._callBtnImg.onCall) then
            self:SetWndEasyImage(self.mOneCall_Img, self._callBtnImg.onCall, nil, true)
        end
    end
    CS.ShowObject(self.mTenCostText, freeNum < 10)
    if freeNum < 10 then
        local isItemCost = bagTenItemNum >= 10
        local tenCostStr = isItemCost and _costTen2.itemNum or _costTen1.itemNum
        local tenCostRefId = isItemCost and _costTen2.itemId or _costTen1.itemId
        local icon, iconBg = gModelItem:GetItemImgByRefId(tenCostRefId)
        self:SetWndText(self.mTenCostText, tenCostStr)
        self:SetWndEasyImage(self.mTenCostIcon, icon)

        if LxUiHelper.IsImgPathValid(self._callBtnImg.tenCall) then
            self:SetWndEasyImage(self.mTenCall_Img, self._callBtnImg.tenCall, nil, true)
        end
    end

    local wishKeys = {}
    local wishHero = string.split(config.wishHero, ";")
    local len = 0
    for i, v in ipairs(wishHero) do
        local arr = string.split(v, "=")
        wishKeys[tonumber(arr[1])] = true
        len = len + 1
    end
    local canChangeWishHero = len > 1
    self._canChangeWishHero = canChangeWishHero
end

function UISubExclusiveLottery:RefreshDragonShow()
    local _mySelect = self._mySelect

    if _mySelect <= 0 then
        return
    end

    local list = self._pages[self.turnPageEnum].entry
    local entry = list[_mySelect]
    if not entry then
        return
    end

    --中间的部分
    local itemdata = entry.items[1]
    local refId = itemdata.itemId
    --local iconPath = gModelItem:GetItemImgByRefId(refId)
    --self:SetWndEasyImage(self.mDragonImgmDragonImg, iconPath, function()
    --    CS.ShowObject(self.mDragonImg, true)
    --end)
    local itemRef = gModelItem:GetRefByRefId(refId)
    local dragonRefId
    if itemRef.type == ModelItem.TTEM_TYPE_DRACONIC_ITEM then
        dragonRefId = itemRef.refId
    elseif itemRef.type == ModelItem.TTEM_TYPE_DRACONIC then
        dragonRefId = checknumber(itemRef.typeDate)
    end

    --左上角的显示
    local ref = GameTable.DraconicRef[dragonRefId]
    local heroRef = GameTable.CharacterRef[ref.heroId]

    local _, name, color = gModelHeroExtra:GetHeroConfigNameByServerData({ refId = ref.heroId, star = heroRef.initStar },
            true)
    local SkillNameStr = ccLngText(ref.name)

    local param = {
        refId = dragonRefId,
        showType = true,
    }

    gModelDraconic:DrawCard(self, self.mDragonImg, param)
    CS.ShowObject(self.mDragonImg, true)
    --
    --self:SetWndEasyImage(self.mHeroInfo, ref.callBg)

    self:SetWndEasyImage(self.mHeroRaceImg, ref.callIcon)
    self:SetWndText(self.mHeroName, name)
    self:SetWndText(self.mHeroNickName, SkillNameStr)
    CS.ShowObject(self.mHeroZZImg, false)
    --屏蔽掉光线
    CS.ShowObject(self.mHeroSpinePos, false)
    CS.ShowObject(self.mPetSpinePos, false)
end
--------------------------------------------兑换道具end------------------------------------------------

--------------------------------------------排行榜start------------------------------------------------
function UISubExclusiveLottery:InitRank()
    local config = self._config
    if string.isempty(config.rankId) then
        return
    end
    local rankIds = string.split(config.rankId, "=")
    local rankId = tonumber(rankIds[1])
    local rankRewardId = tonumber(rankIds[2])
    if rankId <= 0 then
        return
    end
    self._rankId = rankId
    self._rankRewardId = rankRewardId

    gModelRank:OnRankReq(2, rankId, 1, 3, self._sid)
end

--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
function UISubExclusiveLottery:OnActivityConfigData()
    local sid = self._sid
    local activityData = gModelActivity:GetWebActivityDataById(sid)
    local data = activityData.config
    self._config = data
    local shopId, callBg1, selectBg, callDescIcon, callDescIconPos, callWishImage, selectDescIcon, selectDescIconPos = data.shopId, data.callBg1, data.selectBg, data.callDescIcon, data.callDescIconPos, data.callWishImage, data.selectDescIcon, data.selectDescIconPos
    local imageHeroPos, imageHeroSize, timePos, timeImg, selectEffPos1, selectEffPos2 = data.imageHeroPos, data.imageHeroSize, data.timePos, data.timeImg, data.selectEffPos1, data.selectEffPos2
    local wishHero = data.wishHero

    local awardReplace = data.awardReplace or 0
    self._canAwardReplace = awardReplace == 0
    self._awardReplaceTxt = data.awardReplaceTxt

    local selectImage, selectImagePos = data.selectImage, data.selectImagePos
    self._templateType = data.templateType or 0

    self._showItem = data.currencyBar
    self._imageHero = data.imageHero or 1

    local isShowRank = data.rankShow == 1

    self._isShowRank = isShowRank
    CS.ShowObject(self.mRankRoot, isShowRank)

    if self._templateType == 1 then
        local petSpinePos = data.petSpinePos

        if not string.isempty(petSpinePos) then
            local pos = LxDataHelper.ParseVector2NotEmpty3(petSpinePos)
            self:SetAnchorPos(self.mHeroSpine, pos)
        end

        local petSpineSelectSize = data.petSpineSelectSize or 0.5
        petSpineSelectSize = checknumber(petSpineSelectSize)
        local petSpinePos2 = data.petSpinePos2
        if not string.isempty(petSpinePos2) then
            local pos = LxDataHelper.ParseVector2NotEmpty3(petSpinePos2)
            self:SetAnchorPos(self.mPetSpinePos, pos)
        end

        self.mPetSpinePos.localScale = Vector3.New(petSpineSelectSize, petSpineSelectSize, petSpineSelectSize)
    end

    local helpTips = data.helpTips or 0
    local isShowTips = helpTips == 1
    CS.ShowObject(self.mTips, isShowTips)

    local shopShow = data.shopShow or 0
    local isShowShop = shopShow == 1
    CS.ShowObject(self.mBtnShop, isShowShop)

    if LxUiHelper.IsImgPathValid(callBg1) then
        self:SetWndEasyImage(self.mBgImage1, callBg1, function()
            CS.ShowObject(self.mBgImage1, true)
        end)
    end

    if LxUiHelper.IsImgPathValid(selectBg) then
        self:SetWndEasyImage(self.mBgImage2, selectBg, function()
            --调整为别的立绘设置之后
            CS.ShowObject(self.mBgImage2, true)
        end)
    else
        CS.ShowObject(self.mBgImage2, false)
    end

    if LxUiHelper.IsImgPathValid(selectImage) then
        self:SetWndEasyImage(self.mSketch, selectImage, function()
            CS.ShowObject(self.mSketch, true)
        end, true)
    end

    if not string.isempty(selectImagePos) then
        local pos = LxDataHelper.ParseVector2NotEmpty3(selectImagePos)
        self:SetAnchorPos(self.mSketch, pos)
    end

    if LxUiHelper.IsImgPathValid(callDescIcon) then
        local paint = self.mGroupImg
        self:SetWndEasyImage(paint, callDescIcon, function()
            --CS.ShowObject(paint,true)
        end, true)
        if not string.isempty(callDescIconPos) then
            local pos = LxDataHelper.ParseVector2NotEmpty3(callDescIconPos)
            self:SetAnchorPos(paint, pos)
        end
    end

    --时间部分
    if LxUiHelper.IsImgPathValid(timeImg) then
        self:SetWndEasyImage(self.mTimeBg, timeImg, nil, false)
    end

    if not string.isempty(timePos) then
        local pos = LxDataHelper.ParseVector2NotEmpty3(timePos)
        self:SetAnchorPos(self.mTimeBg, pos)
    end

    --选择的图片部分selectDescIcon, selectDescIconPos
    if LxUiHelper.IsImgPathValid(selectDescIcon) then
        self:SetWndEasyImage(self.mSelectTips, selectDescIcon, nil, true)
    end

    if not string.isempty(selectDescIconPos) then
        local pos = LxDataHelper.ParseVector2NotEmpty3(selectDescIconPos)
        self:SetAnchorPos(self.mSelectTips, pos)
    end

    --召唤部分的描述  callWishImage
    if LxUiHelper.IsImgPathValid(callDescIcon) then
        self:SetWndEasyImage(self.mLeftCallTimesTips, callDescIcon, nil, true)
    end

    if not string.isempty(callDescIconPos) then
        local pos = LxDataHelper.ParseVector2NotEmpty3(callDescIconPos)
        self:SetAnchorPos(self.mLeftCallTimesTips, pos)
    end

    if self._isEnus then
        self.mLeftCallTimesTips.localScale = Vector3.one * 0.6

        --self:SetAnchorPos(self.mTipsText, Vector2.New(190, 0))
        --self:SetAnchorPos(self.mCallNumText, Vector2.New(-100, 0))
    end



    --切换按钮
    local switchPos = data.switchPos
    if not string .isempty(switchPos) then
        local pos = LxDataHelper.ParseVector2NotEmpty3(switchPos)
        self:SetAnchorPos(self.mSwitchPosTran, pos)
    end

    local lookPos = data.lookPos
    if not string .isempty(lookPos) then
        local pos = LxDataHelper.ParseVector2NotEmpty3(lookPos)
        self:SetAnchorPos(self.mBtnLook, pos)
    end

    --helptips
    self._helpTitle = data.callHelpTitleTxt
    self._helpContent = data.callHelpTitle

    --跳轉部分
    local jumpBtnSwitch = data.jumpBtnSwitch
    local showFuncJumpBtn = jumpBtnSwitch and jumpBtnSwitch == 1
    if (showFuncJumpBtn) then
        local showFuncJumpBtnPos = data.jumpBtnPos
        --self:SetAnchorPos(self.mPetSpine,LxDataHelper.ParseVector2NotEmpty2(showFuncJumpBtnPos))
        local iconPath = data.jumpBtnImg
        local funcBtnIcon = self:FindWndTrans(self.mBtnFuncJump, "ShopIcon")
        self:SetWndEasyImage(funcBtnIcon, iconPath)
        self:SetWndText(self.mBtnFuncTxt, data.jumpBtnText or "")
        self._jumpBtnId = data.jumpBtnId
    end
    CS.ShowObject(self.mBtnFuncJump, jumpBtnSwitch)

    --请求分页数据
    local enums = self._modelEnumList[self._modelId]
    gModelActivity:OnActivityPageReq(self._sid, enums)

    self:RefreshTime()

    self:InitRankBaseInfo()
    self:InitRank()


end

--------------------------------------------兑换道具start------------------------------------------------
function UISubExclusiveLottery:RefreshItem()
    local _currency = self._showItem
    local list = {}
    if not string.isempty(_currency) then
        local arr = string.split(_currency, "|")
        for i, v in ipairs(arr) do
            table.insert(list, { itemId = tonumber(v) })
        end
    end
    local _uiCellList = self._uiCellList
    if _uiCellList then
        _uiCellList:RefreshList(list)
    else
        _uiCellList = self:GetUIScroll("mItemScroll_UISubExtractAward")
        _uiCellList:Create(self.mItemScroll, list, function(...)
            self:ListItem(...)
        end)
        self._uiCellList = _uiCellList
    end
end

function UISubExclusiveLottery:InitCommand()
    self:SetWndText(self.mRankNameText, ccClientText(20863))
    self:SetWndText(self.mRankEmptyText, ccClientText(20808))
    self:SetWndText(self.mMyRankDesc, ccClientText(20864))
    self:SetWndText(self.mMyScoreDesc, ccClientText(20865))
    self:SetWndText(self.mMyAwardDesc, ccClientText(20866))
    self:SetWndText(self.mMyNoAwardDesc, ccClientText(20869))
    self:SetWndText(self.mMyNoAwardLook, ccClientText(20867))
    self:SetWndText(self.mSelText, ccClientText(20807))
    self:SetWndText(self.mDetailsText, ccClientText(44810))  --[44810] [概 率]
    self:SetWndText(self.mLogText, ccClientText(44809))  --[44809] [日 志]
    self:SetWndText(self.mShopText, ccClientText(10362))
    self:SetWndText(self.mLookText, ccClientText(20806))

    self:SetWndText(self.mHeroUpUIText, ccClientText(44802)) --[44802] [概率UP]
    self:SetWndText(self.mJumpAniBgTxt, ccClientText(14617)) --[14617]	[跳過動畫]

    self:SetWndText(self.mCheckMore, ccClientText(21067)) --[21067]	[查看更多]

    self:SetWndText(self.mAddText, ccClientText(44804))--[44804] [點擊選擇]

    self:InitTextSizeWithLanguage(self.mLookText, -2)
    self:InitTextLineWithLanguage(self.mLookText, -40)

    self:CreateWndEffect(self.mOneEff, "fx_ui_ZH_anniu", "mOneEff", 100)
    self:CreateWndEffect(self.mTenEff, "fx_ui_ZH_anniu", "mTenEff", 100)

    local sid = self:GetWndArg("sid")
    self._sid = sid
    local modelId = gModelActivity:GetActivityModeIdBySid(sid)
    if not modelId then
        return
    end
    self._modelId = modelId

    local enums = self._modelEnumList[modelId]
    self.turnPageEnum = enums[1]
    self:OnActivityConfigData()
    self:RefreshJumpAniStatus()
end

function UISubExclusiveLottery:RefreshShowHero()
    local _mySelect = self._mySelect
    if _mySelect <= 0 then
        return
    end
    local list = self._pages[self.turnPageEnum].entry
    local entry = list[_mySelect]
    if not entry then
        return
    end
    --解析对应的英雄数据
    local heroDatas = LxDataHelper.SevenParseItems(entry.items)
    local heroRefId = heroDatas[1].itemId
    local effRef = gModelHero:GetHeroEffectRef(heroRefId)
    local heroRef = gModelHero:GetHeroRef(heroRefId)
    local qualityIcon = heroRef.qualityIcon
    local raceId = heroRef.raceType
    local raceRef = gModelHero:GetHeroRaceRefByRefId(raceId)
    local raceImg = raceRef.icon
    local heroName = ccLngText(effRef.name)
    local nickName = ccLngText(effRef.nickName)
    local star = heroRef.initStar
    local quality = gModelHero:GetHeroQualityByRefId(heroRef.refId, star)
    local qualityRef = gModelItem:GetQualityRef(quality)

    local prefabName = effRef.prefabName
    local heroDrawing = effRef.heroDrawing
    local effId = effRef.refId
    --中间的部分
    local oldHeroDrawing = self._oldHeroDrawing
    if oldHeroDrawing and oldHeroDrawing ~= heroDrawing then
        self:DestroyWndSpineByKey("heroSpine")
    end
    self:CreateWndSpine(self.mHeroSpine, heroDrawing, "heroSpine", false, function()
        CS.ShowObject(self.mBgImage2, true)
    end)
    self._oldHeroDrawing = heroDrawing

    --右下角的部分
    local oldHeroPrefab = self._oldHeroPrefab
    if oldHeroPrefab and oldHeroPrefab ~= prefabName then
        self:DestroyWndSpineByKey("heroSpinePos")
    end
    self:CreateWndSpine(self.mHeroSpinePos, prefabName, "heroSpinePos", false, function(spine)
        spine:MatchRectTransform()
    end)
    self._oldHeroPrefab = prefabName

    --英雄信息
    local qualityIcon = heroRef.qualityIcon
    self:SetWndEasyImage(self.mHeroZZImg, qualityIcon, function()
        CS.ShowObject(self.mHeroZZImg, true)
    end)
    local raceImg = raceRef.icon
    self:SetWndEasyImage(self.mHeroRaceImg, raceImg, function()
        CS.ShowObject(self.mHeroRaceImg, true)
    end)

    self:SetWndText(self.mHeroName, heroName)

    self:SetWndText(self.mHeroNickName, nickName)
    self:SetXUITextTransColor(self.mHeroNickName, qualityRef.nameColor)
end

function UISubExclusiveLottery:InitMessage()
    self:WndNetMsgRecv(LProtoIds.ItemChangeResp, function(pb)
        self:RefreshItem()
        self:RefreshBtnText()
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityResp, function(pb)
        local activity = pb.activity
        local sid = activity.sid
        if self._sid ~= sid then
            return
        end
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
        local activities = pb.activities
        for i, v in ipairs(activities) do
            local sid = v.sid
            if self._sid == sid then
                self:RefreshData()
                return
            end
        end
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
        local sid = pb.sid
        if self._sid ~= sid then
            return
        end
        self:ResetData(pb)
    end)
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(data, sid)
        if sid ~= self._sid then
            return
        end
        self:OnActivityConfigData()
    end)
    self:WndEventRecv(EventNames.RANK_UPDATE_END, function(rankType, rankRefId)
        if rankRefId ~= self._rankId then
            return
        end
        self:RefreshRank()
    end)
    self:WndNetMsgRecv(LProtoIds.ActivityDropGiftResp, function(pb)
        self:InitRank()
    end)
end
function UISubExclusiveLottery:OnClickShop()
    local _sid = self._sid
    GF.OpenWndBottom("UIDian", { page = ModelShop.ACTIVITY, subPage = _sid })
end
function UISubExclusiveLottery:OnClickLog()
    local data = self._config
    local titleStr, tipsStr, timeStr = data.logTitle, data.logTips, data.logTimeTips
    GF.OpenWnd("UIYellLog", { sid = self._sid, callType = 3, titleStr = titleStr, tipsStr = tipsStr, timeStr = timeStr, emptyRefId = 14008 })
end

--endregion --------------------------------------------------------------------------------------

--region 计时器 --------------------------------------------------------------------------------
function UISubExclusiveLottery:OnTimer(key)
    if key == self._timeRankKey then
        self:OnRankTimeText()
    elseif key == self._timeKey then
        self:SetTime()
    elseif key == self._timeFreeKey then
        self:SetFreeTime()
    end
end
function UISubExclusiveLottery:RankListItem(list, item, itemdata, itempos)
    local RankImgTrans = self:FindWndTrans(item, "RankImg")
    local NameTrans = self:FindWndTrans(item, "Name")
    local ScoreTrans = self:FindWndTrans(item, "Score")
    local MyTag = self:FindWndTrans(item, "MyTag")

    if self._isEnus then
        NameTrans = self:FindWndTrans(item, "Name_Enus")
    end

    local rank = itemdata.rank
    local name = itemdata.name
    local score = itemdata.score
    local playerId = itemdata.playerId
    local myPlayerId = gModelPlayer:GetPlayerId()

    if not (tonumber(playerId) == -1) then
        local color = "white"
        name = LUtil.FormatColorStr(name, color)
    end

    self:SetWndText(NameTrans, name)
    self:SetWndText(ScoreTrans, score)
    local rankScoreImgList = self._rankScoreImgList
    local img = rankScoreImgList and rankScoreImgList[rank]
    if img and RankImgTrans then
        self:SetWndEasyImage(RankImgTrans, img)
    end

    local isme = playerId == myPlayerId
    CS.ShowObject(MyTag, isme)

end

function UISubExclusiveLottery:InitEvent()

    --抽取
    self:SetWndClick(self.mBtnOne, function(...)
        self:OnClickOneTen(1)
    end)
    self:SetWndClick(self.mBtnTen, function(...)
        self:OnClickOneTen(2)
    end)

    --打开选择的页面
    self:SetWndClick(self.mAdd_Bg, function()
        self:OnClickCut(true)
    end)

    self:SetWndClick(self.mHeroSpinePos, function()
        self:OnClickCut()
    end)
    self:SetWndClick(self.mBtnCut, function()
        self:OnClickCut()
    end)
    --
    self:SetWndClick(self.mBtnLog, function(...)
        self:OnClickLog()
    end)
    self:SetWndClick(self.mBtnShop, function()
        self:OnClickShop()
    end)

    self:SetWndClick(self.mBtnDetails, function()
        self:OnClickDetails()
    end)

    self:SetWndClick(self.mBtnLook, function()
        self:OnClickLook()
    end)

    self:SetWndClick(self.mBtnFuncJump, function()
        if (self._jumpBtnId) then
            gModelFunctionOpen:Jump(self._jumpBtnId, self:GetWndName())
        end
    end)

    self:SetWndClick(self.mCheckMore, function()
        self:OnClickRank()
    end)

    self:SetWndClick(self.mTips, function()
        self:OnTipsClick()
    end)

    --跳过动画
    self:SetWndClick(self.mJumpAniBg, function()
        self:OnClickJumpAniFunc()
    end)
end

function UISubExclusiveLottery:OnClickItemIcon(itemId)
    local wndName = self:GetParentWndName()
    gModelGeneral:OpenGetWayWnd({ itemId = itemId, srcWnd = wndName })
end

--region 初始化 --------------------------------------------------------------------------------
function UISubExclusiveLottery:InitDate()
    self._modelLotteryList = {
        [ModelActivity.MODEL_ACTIVITY_TYPE_120] = ModelActivity.SWEETS_COUNTRY_LOTTERY,
    }
    self._modelOptionalAwardList = {
        [ModelActivity.MODEL_ACTIVITY_TYPE_120] = ModelActivity.SWEETS_COUNTRY_OPTIONAL_AWARD,
    }
    self._modelEnumList = {
        [ModelActivity.MODEL_ACTIVITY_TYPE_120] = {
            ModelActivity.HappyLottery_1,
            ModelActivity.HappyLottery_2,
            ModelActivity.HappyLottery_3,
            ModelActivity.HappyLottery_4
        },
    }
end
function UISubExclusiveLottery:ListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local itemBg = self:FindWndTrans(root, "ItemBg")
    local itemIcon = self:FindWndTrans(itemBg, "ItemIcon")
    local itemText = self:FindWndTrans(itemBg, "ItemText")

    local itemId = itemdata.itemId
    local icon, iconBg = gModelItem:GetItemImgByRefId(itemId)
    local itemNum = gModelItem:GetNumByRefId(itemId)

    self:SetWndEasyImage(itemIcon, icon)
    self:SetWndText(itemText, LUtil.NumberCoversion(itemNum))

    self:SetWndClick(root, function()
        self:OnClickItemIcon(itemId)
    end)
end

function UISubExclusiveLottery:RefreshTime()
    local activityDatas = gModelActivity:GetActivityBySid(self._sid)
    local _endTime = activityDatas.endTime
    if _endTime and _endTime ~= -1 then
        self:TimerStop(self._timeKey)
        self:TimerStart(self._timeKey, 1, false, -1)
        self:SetTime()
    end
end
--------------------------------------------排行榜end------------------------------------------------

function UISubExclusiveLottery:RefreshJumpAniStatus()
    local status = self._jumpAniStatus
    CS.ShowObject(self.mJumpAniBgGou, status)
end

function UISubExclusiveLottery:RefreshBottomText()
    local _mySelect = self._mySelect
    if _mySelect <= 0 then
        return
    end
    local config = self._config
    local callNum = self._callNum
    local myDropNum = self._myDropNum
    local dropNumToday = self._dropNumToday
    local callLimitTips = config.callLimitTips or ccClientText(44800)  -- [44800] [今日召喚次數：<color=#68e6ac>#a1#/#a2#</color>]
    local callMaxNum = config.callMaxNum
    local goldTimes = config.goldTimes
    local diaCallLimitTips = config.diaCallLimitTips or ccClientText(23226)
    local wishKeys = {}
    local wishHero = string.split(config.wishHero, ";")
    for i, v in ipairs(wishHero) do
        local arr = string.split(v, "=")
        wishKeys[tonumber(arr[1])] = tonumber(arr[2])
    end

    --必得次数
    local guaranteeNum = wishKeys[_mySelect] or 100
    local lotteryNum = guaranteeNum - myDropNum
    lotteryNum = lotteryNum > 0  and lotteryNum  or 1
    local str = self:GetIndexStr(lotteryNum)
    self:SetWndText(self.mLeftCallTimes, str)

    --交易上限  <%s>%s</color>
    str = LUtil.FormatColorStr(dropNumToday, dropNumToday >= callMaxNum and "lightRed" or "lightGreen_new")
    self:SetWndText(self.mCallNumText, string.replace(callLimitTips, str, callMaxNum))

    str = LUtil.FormatColorStr(goldTimes - callNum, callNum >= goldTimes and "lightRed" or "lightGreen_new")
    self:SetWndText(self.mTipsText, string.replace(diaCallLimitTips, str))

    self:RefreshBtnText()
end


--endregion --------------------------------------------------------------------------------------

--region tween动画 --------------------------------------------------------------------------------

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UISubExclusiveLottery