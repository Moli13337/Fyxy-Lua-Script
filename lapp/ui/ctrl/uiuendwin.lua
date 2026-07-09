---
--- Created by BY.
--- DateTime: 2023/10/22 9:42:29
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIUendWin:LWnd
local UIUendWin = LxWndClass("UIUendWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIUendWin:UIUendWin()
    ---@type table<number, CommonIcon>
    self._heroIconList = {}
    ---@type table<number, CommonIcon>
    self._uiCommonList = {}
    self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIUendWin:OnWndClose()
    self:ClearCommonIconList(self._heroIconList)
    self:ClearCommonIconList(self._uiCommonList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIUendWin:OnCreate()
    LWnd.OnCreate(self)

    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    self._nextFlushTimeKey = "_nextFlushTimeKey"
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIUendWin:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()

    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    self:SetHideTop()
    self._redFun1 = function(pb)
        self:RefreshRed(ModelRedPoint.ENDLES_AID_COMPLEX)
    end
    self._redFun2 = function(pb)
        self:RefreshRed(ModelRedPoint.ENDLES_AID_SPECIAL)
    end
    self:RegisterRedPointFunc(ModelRedPoint.ENDLES_AID_COMPLEX, self._redFun1)
    self:RegisterRedPointFunc(ModelRedPoint.ENDLES_AID_SPECIAL, self._redFun2)

    gModelRedPoint:SetRedPointClicked(ModelRedPoint.ENDLESS_LOGIN_CHECK)
    --gModelBackflow:SetPrivileBtn(self.mBtnPrivile,2,self)
    -- local priviCom = self:GetPrivilegeCom()
    -- priviCom:Create(self.mBtnPrivile, 2, self)

    self:UpdateRankRed()
    self:RefreshForeign()
end

function UIUendWin:InitCommand()
    self:SetWndText(self.mRankTileText, ccClientText(17201))
    self:SetWndText(self.mLookRankText, ccClientText(17205))
    self:SetWndText(self.mBoxText, ccClientText(17207))
    self:SetWndText(self.mHeroText, ccClientText(17208))
    self:SetWndText(self.mChallengeTips, ccClientText(17213))
    self:SetWndText(self.mAwardPvwText, ccClientText(17218))
    self:SetWndText(self.mShopText, ccClientText(17953))
    self:InitTextLineWithLanguage(self.mAwardPvwText, -30)
    self:SetWndText(self.mChangePvwText, ccClientText(17219))
    self:InitTextLineWithLanguage(self.mChangePvwText, -30)

    self:InitTextLineWithLanguage(self.mLookRankText, -40)
    self.mLookRankText.sizeDelta = Vector2.New(180, 30)

    local page = self:GetWndArg("page") or 1

    self._tabTransList = {}
    self._type = -1
    self._tabList = gModelEndles:GetTabList()
    self._uiList = self:GetUIScroll("tab")
    self._uiList:Create(self.mTabScroll, self._tabList, function(...)
        self:TabListItem(...)
    end)
    self:OnClickType(self._tabList[page].type)
end

function UIUendWin:OnClickChallenge()
    --点击挑战
    local _endlesInfo = self._endlesInfo
    --local isChallenge = self:IsChallengeType(_endlesInfo.type)
    --if(not isChallenge)then
    --	return
    --end
    local ref = gModelEndles:GetEndlessRefByType(_endlesInfo.type)
    local battleType = gModelEndles:GetCurrSpecialType()
    if (battleType <= 0 or battleType == _endlesInfo.type) then
        local initNode = _endlesInfo.initNode
        local dayNode = _endlesInfo.dayNode
        local isBasics = gModelEndles:GetIsBasicsReward(initNode, dayNode)
        if (not isBasics) then
            GF.OpenWnd("UIOrdinTip", { refId = 140001, func = function(...)
                --重新挑战
                gLFightManager:PrepareGoToBattle(ref.combatTyep, { specialType = _endlesInfo.type })
                self:WndClose()
            end })
        else
            --开始挑战
            gLFightManager:PrepareGoToBattle(ref.combatTyep, { specialType = _endlesInfo.type })
            self:WndClose()
        end
    else
        GF.ShowMessage(ccClientText(17212))
    end
end

function UIUendWin:OnTryRefreshRedPoint(...)
    self:UpdateRankRed()
end
function UIUendWin:UpdateRankRed()
    local showRed = gModelRedPoint:CheckRankShowRed(701)
    CS.ShowObject(self.mRankRedPoint, showRed)
end

function UIUendWin:OnClickLookRank()
    --排行榜
    local _endlesInfo = self._endlesInfo
    local ref = gModelEndles:GetEndlessRefByType(_endlesInfo.type)
    GF.OpenWndBottom("UIRkPop", { refId = ref.rankRefId })
end

function UIUendWin:AwardListItem(list, item, itemdata, itempos)
    local root = CS.FindTrans(item, "Root")
    --local numText = CS.FindTrans(item,"NumText")

    local uiCommonList = self._uiCommonList
    local InstanceID = item:GetInstanceID()
    local baseClass = uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        uiCommonList[InstanceID] = baseClass
        baseClass:Create(root)
    end
    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    self:SetWndClick(root, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
    baseClass:DoApply()

    --self:SetWndText(numText, LUtil.NumberCoversion(itemdata.itemNum))
end

function UIUendWin:ChangeType(trans, bool)
    local on = CS.FindTrans(trans, "OnImage")
    local text = CS.FindTrans(trans, "UIText")
    local color
    if bool then
        color = "734f22ff"
    else
        color = "cbe3faff"
    end
    color = LUtil.ColorByHex(color)
    local xuitxt = self:FindWndText(text)
    self:SetXUITextColor(xuitxt, color)
    CS.ShowObject(on, bool)
end

function UIUendWin:SetTextandcharater(tran)
    self:InitTextCharacterWithLanguage(tran,-5)
    LxUiHelper.SetSizeWithCurAnchor(tran,0,100)
end

function UIUendWin:RefreshHelpHero()
    --刷新援助英雄
    local _endlesInfo = self._endlesInfo
    if not _endlesInfo then
        return
    end
    local heroInfo = _endlesInfo.helpHero
    local _isNoHero = heroInfo == nil or heroInfo.id == ""
    CS.ShowObject(self.mAddHeroRoot, _isNoHero)
    CS.ShowObject(self.mHeroRoot, not _isNoHero)
    if (not _isNoHero) then
        local heroIcon = CS.FindTrans(self.mHeroRoot, "HeroIcon")
        local heroData = {
            id = heroInfo.id,
            refId = heroInfo.refId,
            star = heroInfo.star,
            level = heroInfo.lvl,
            trans = heroIcon,
            fightPower = heroInfo.power,
            grade = heroInfo.grade,
            isHelp = true,
            skin = heroInfo.skin,
            form = heroInfo.form,
        }
        local instanceId = self.mHeroRoot:GetInstanceID()
        local baseClass = self._heroIconList[instanceId]
        if not baseClass then
            baseClass = CommonIcon:New()
            self._heroIconList[instanceId] = baseClass
            baseClass:Create(heroIcon)
            self:SetIconClickScale(heroIcon, true)
        end
        baseClass:SetHeroDataSet(heroData)
        baseClass:DoApply()

        self:SetWndClick(heroIcon, function()
            self:OnClickAddHero(_endlesInfo)
        end)
        self:SetWndText(self.mHeroPowerText, LUtil.PowerNumberCoversion(heroInfo.power))
    end
end

function UIUendWin:RefreshRed(index)
    if (self._type == 1 and index == ModelRedPoint.ENDLES_AID_SPECIAL) then
        return
    elseif (self._type ~= 1 and index == ModelRedPoint.ENDLES_AID_COMPLEX) then
        return
    end
    local showRed = gModelRedPoint:CheckShowRedPoint(index)
    CS.ShowObject(self.mAddHeroRed, showRed)
end

function UIUendWin:OnClickAddHero(_endlesInfo)
    --点击援助英雄
    local _endlesInfo = _endlesInfo or self._endlesInfo
    local type = _endlesInfo.type
    local index = type == 1 and ModelRedPoint.ENDLES_AID_COMPLEX or ModelRedPoint.ENDLES_AID_SPECIAL
    local showRed = gModelRedPoint:CheckShowRedPoint(index)
    local page = showRed and 2 or 1
    GF.OpenWnd("UIUendAidPop", { type = type, page = page })
end

function UIUendWin:RefreshUnclaimedAward()
    --刷新首通奖励
    local _endlesInfo = self._endlesInfo
    local maxNode = _endlesInfo.maxNode
    local ref = gModelEndles:GetUnclaimedAward(_endlesInfo.type, _endlesInfo.receiveIds)
    local isGetAward = false
    CS.ShowObject(self.mFirstImage, ref)
    if not ref then
        return
    end
    if ref.refId <= maxNode and not _endlesInfo.receiveIds[ref.refId] then
        isGetAward = true
    end
    local maxNodeStr = maxNode
    if (maxNode > 0) then
        local maxRef = gModelEndles:GetEndlessCheckpointRefByRefId(maxNode)
        maxNodeStr = maxRef.id
    end
    local getRef = gModelEndles:GetEndlessCheckpointRefByRefId(ref.refId)
    self:SetWndText(self.mBoxNumText, string.replace(ccClientText(17206), maxNodeStr, getRef.id))

    local itemList = LxDataHelper.ParseItem(ref.reward)
    if (self._boxAwardScroll) then
        self._boxAwardScroll:RefreshList(itemList)
    else
        self._boxAwardScroll = self:GetUIScroll("_boxAwardScroll")
        self._boxAwardScroll:Create(self.mBoxAwardScroll, itemList, function(...)
            self:AwardListItem(...)
        end)
    end
    CS.ShowObject(self.mBoxEff, isGetAward)
    CS.ShowObject(self.mRedPoint, isGetAward)
    if (isGetAward) then
        self:CreateWndEffect(self.mBoxEff, "fx_richangbaoxiang", "boxEff", 100)
    end
    self:SetWndClick(self.mBoxBtn, function(...)
        if (isGetAward) then
            self:OnClickBox(_endlesInfo.type, ref.refId)
        else
            self:OnClickBoxAwardListWin()
        end
    end)
end

function UIUendWin:OnClickHelp()
    --帮助
    GF.OpenWnd("UIBzTips", { refId = 52 })
end
function UIUendWin:RefreshForeign()
    if self._isVie then
        self:InitTextSizeWithLanguage(self.mTitleText, -7)
        self:InitTextSizeWithLanguage(self.mRankTileText, -1)
        self:SetAnchorPos(self.mFirstImage,Vector2.New(0,140))
        local textBg = CS.FindTrans(self.mFirstImage,"textBg")
        textBg.pivot = Vector2(0.5, 1)
        LxUiHelper.SetSizeWithCurAnchor(textBg,1,90)
        self:SetAnchorPos(self.mBoxText,Vector2.New(-86.2,-60))
    end

    if self.jpj then
        self:InitTextSizeWithLanguage(self.mBoxText,-2)
        self:SetTextandcharater(self.mShopText)
        self:SetTextandcharater(self.mAwardPvwText)
        self:SetTextandcharater(self.mChangePvwText)

    end
end

function UIUendWin:SetTime()
    --设置时间
    local time = GetTimestamp()
    local endTime = gModelEndles:GetEndTime()
    local timespan = endTime / 1000 - time
    if (timespan <= 0) then
        self:TimerStop(self._nextFlushTimeKey)
        return
    end
    if (timespan > 86400) then
        local timeStr = LUtil.FormatTimespanCn(timespan)
        self:SetWndText(self.mTimeText, string.replace(ccClientText(17217), timeStr))
        return
    end
    local h = math.floor(timespan / 3600)
    local m = math.floor(timespan / 60) % 60
    local s = math.floor(timespan) % 60
    local timeStr = string.format("%02d:%02d:%02d", h, m, s)
    self:SetWndText(self.mTimeText, string.replace(ccClientText(17217), timeStr))
end
function UIUendWin:OnClickShop()
    --商店
    GF.OpenWnd("UIDian", { page = ModelShop.SCORE, subPage = 2013 })
end

function UIUendWin:OnClickBoxAwardListWin()
    --首通奖励列表
    local _endlesInfo = self._endlesInfo
    GF.OpenWnd("UIUendAwardPop", { endlesInfo = _endlesInfo, tabType = 2 })
end

function UIUendWin:OnClickChangePvw()
    --轮换预览
    GF.OpenWnd("UIUendPvwPop")
end

function UIUendWin:OnClickBox(type, node)
    --首通宝箱
    gModelEndles:OnReceiveNodeRewardReq(type, node)
end

function UIUendWin:OnClickClose()
    if not self:WndCloseAndBack() then
    end
    GF.OpenWndBottom("UIOutts")
    self:WndClose()
end

function UIUendWin:TabListItem(list, item, itemdata, itempos)
    local text = CS.FindTrans(item, "UIText")
    self:SetWndText(text, itemdata.name)
    self:InitTextSizeWithLanguage(text, -2)
    self:InitTextLineWithLanguage(text, -30)
    self._tabTransList[itemdata.type] = item
    self:SetWndClick(item, function(...)
        self:OnClickType(itemdata.type)
    end, LSoundConst.CLICK_PAGE_COMMON)
end

function UIUendWin:OnClickAwardPvw()
    --奖励预览
    local _endlesInfo = self._endlesInfo
    GF.OpenWnd("UIUendAwardPop", { endlesInfo = _endlesInfo, tabType = 1 })
end

function UIUendWin:InitEvent()
    --self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
    --self:SetWndClick(self.mBgImage, function(...) self:OnClickClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn, function(...)
        self:OnClickClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mHelpBtn, function(...)
        self:OnClickHelp()
    end)
    self:SetWndClick(self.mShopBtn, function(...)
        self:OnClickShop()
    end)
    self:SetWndClick(self.mAwardPvwBtn, function(...)
        self:OnClickAwardPvw()
    end)
    self:SetWndClick(self.mChangePvwBtn, function(...)
        self:OnClickChangePvw()
    end)
    self:SetWndClick(self.mLookRankBtn, function(...)
        self:OnClickLookRank()
    end)
    self:SetWndClick(self.mAddHeroBtn, function(...)
        self:OnClickAddHero()
    end)
    self:SetWndClick(self.mChallengeBtn, function(...)
        self:OnClickChallenge()
    end)
    self:WndEventRecv(EventNames.RANK_UPDATE_END, function(...)
        self:OnUpdateRankResp(...)
    end)
end

function UIUendWin:OnUpdateRankResp(type, rankType)
    -- if rankType == ModelRank.RANK_ENDLES_COMPLEX then
    local ranks = gModelRank:GetRankListInfo(type, rankType)
    local selfRank = gModelRank:GetMeRank()
    local playerId = gModelPlayer:GetPlayerId()
    local isExist = nil
    local value = nil
    for i = 1, 3, 1 do
        value = ranks[i]
        if not value then
            self:SetWndText(self["mRankText" .. i], "<color=#d2efff>" .. ccClientText(17270) .. "</color>")
            self:SetWndText(self["mTxtRankNum" .. i], "")
        else
            local str = value.info._name
            self:SetWndText(self["mRankText" .. i], "<color=#ffffff>" .. str .. "</color>")
            if not isExist and value.info._playerId == playerId then
                isExist = i
            end
            local maxNodeRef = gModelEndles:GetEndlessCheckpointRefByRefId(value.score)
            self:SetWndText(self["mTxtRankNum" .. i], maxNodeRef.id)

        end
    end
    CS.ShowObject(self.mRankTextMe, not isExist and selfRank.rank > 0)
    CS.ShowObject(self.mImgRankMe, selfRank.rank > 0)
    local sizeDelta = self.mRankImage.sizeDelta
    sizeDelta.y = self.mRankTextMe.gameObject.activeSelf and 197 or 172
    self.mRankImage.sizeDelta = sizeDelta
    if selfRank.rank > 0 then
        local maxNode = self._endlesInfo.maxNode
        local maxNodeStr = maxNode
        if (maxNode > 0) then
            local maxNodeRef = gModelEndles:GetEndlessCheckpointRefByRefId(maxNode)
            maxNodeStr = maxNodeRef.id
        end
        self:InitTextSizeWithLanguage(self.mTxtRankNumMe, -2)
        self:SetWndText(self.mTxtRankNumMe, maxNodeStr)--string.replace(ccClientText(17215),maxNodeStr)
        self:SetWndText(self.mTxtRankMe, selfRank.rank)
        self:SetWndText(self.mRankTextMe, gModelPlayer:GetPlayerName())
        local anchoredPos = self.mImgRankMe.anchoredPosition
        if isExist then
            anchoredPos.y = self["mRankText" .. isExist].anchoredPosition.y
        end
        self.mImgRankMe.anchoredPosition = anchoredPos
    end
    -- end
end

function UIUendWin:RefreshData()
    local _endlesInfo = self._endlesInfo

    local bool = _endlesInfo.type > ModelEndles.ENDLES_COMPLEX    --是否特殊试炼
    CS.ShowObject(self.mTimeImage, bool)
    CS.ShowObject(self.mChangePvwBtn, bool)
    if (bool) then
        local time = GetTimestamp()
        local endTime = gModelEndles:GetEndTime()
        local timespan = endTime / 1000 - time
        self:SetTime()
        if (timespan > 0 and timespan <= 86400) then
            self:TimerStop(self._nextFlushTimeKey)
            self:TimerStart(self._nextFlushTimeKey, 1, false, -1)
        end
    end

    local rank = _endlesInfo.selfRank
    local rankStr
    if (rank <= 0) then
        rankStr = ccClientText(17216)
    else
        rankStr = string.replace(ccClientText(17214), rank)
    end

    local initNodeRef = gModelEndles:GetEndlessCheckpointRefByRefId(_endlesInfo.initNode)
    self:SetWndText(self.mTxtRankOneNum, rankStr)
    self:InitTextSizeWithLanguage(self.mTxtRankOneNum, -2)

    self:SetWndText(self.mLevelTipsText, string.replace(ccClientText(17209), initNodeRef.id))
    local challengeStr = ""
    local isGray = false
    local battleType = gModelEndles:GetCurrSpecialType()
    if (battleType <= 0 or battleType == _endlesInfo.type) then
        local initNode = _endlesInfo.initNode
        local dayNode = _endlesInfo.dayNode
        local isBasics = gModelEndles:GetIsBasicsReward(initNode, dayNode)
        if (isBasics) then
            challengeStr = ccClientText(17210)
        else
            challengeStr = ccClientText(17211)
        end
    else
        challengeStr = ccClientText(17259)
        isGray = true
    end
    self:SetWndButtonText(self.mChallengeBtn, challengeStr)
    self:SetWndButtonGray(self.mChallengeBtn, isGray)
    -- local ref = gModelEndles:GetEndlessRankRefByRank(_endlesInfo.type,rank)
    -- local itemList = LxDataHelper.ParseItem_3List(ref.reward)
    -- if(self._rankAwardScroll)then
    -- 	self._rankAwardScroll:RefreshList(itemList)
    -- else
    -- 	self._rankAwardScroll = self:GetUIScroll("_rankAwardScroll")
    -- 	self._rankAwardScroll:Create(self.mRankAwardScroll,itemList,function (...) self:AwardListItem(...) end)
    -- end
    self:RefreshHelpHero()
    self:RefreshUnclaimedAward()
end

function UIUendWin:OnClickType(type)
    --点击类型
    --local isChallenge = self:IsChallengeType(type)
    --if(not isChallenge)then
    --	type = 1
    --end
    if (self._type > 0) then
        if (self._type == type) then
            return
        end
        local trans = self._tabTransList[self._type]
        self:ChangeType(trans, false)
    end
    self._type = type
    local trans = self._tabTransList[type]
    self:ChangeType(trans, true)
    self:RefreshWin(type)
    local title
    for i, v in ipairs(self._tabList) do
        if (type == v.type) then
            title = v.name
            break
        end
    end
    self:SetWndText(self.mTitleText, title)
    self:RefreshRed(ModelRedPoint.ENDLES_AID_COMPLEX)
    self:RefreshRed(ModelRedPoint.ENDLES_AID_SPECIAL)

    -- --综合试炼-请求排行数据
    -- if type == ModelEndles.ENDLES_COMPLEX then
    local ref = gModelEndles:GetEndlessRefByType(type)
    gModelRank:OnRankReq(2, ref.rankRefId, 1, 3, nil)
    -- end

end

function UIUendWin:RefreshWin(type)
    self._endlesInfo = gModelEndles:GetEndlesData(type)
    if (not self._endlesInfo) then
        gModelEndles:OnPlayerEndLessInfoReq(type)
        return
    end
    self:RefreshData()
    self:SetModelPaint()
end

function UIUendWin:OnTimer(key)
    if (self._nextFlushTimeKey == key) then
        self:SetTime()
    end
end

function UIUendWin:InitMessage()
    self:WndNetMsgRecv(LProtoIds.PlayerEndLessInfoResp, function(pb)
        self:RefreshWin(self._type)
    end)
    self:WndNetMsgRecv(LProtoIds.ReceiveNodeRewardResp, function(pb)
        self._endlesInfo = gModelEndles:GetEndlesData(self._type)
        self:RefreshUnclaimedAward()
    end)
    self:WndNetMsgRecv(LProtoIds.SelectHelpHeroResp, function(pb)
        self._endlesInfo = gModelEndles:GetEndlesData(self._type)
        self:RefreshHelpHero()
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerEndLessSpecialResp, function(pb)
        local type = gModelEndles:GetSpecialType()
        if not self._endlesInfo then
            return
        end
        if (self._endlesInfo.specialType ~= type) then
            self._tabList = gModelEndles:GetTabList()
            self._uiList:RefreshList(self._tabList)
            local bool = self._type ~= ModelEndles.ENDLES_COMPLEX
            self._type = -1
            if (bool) then
                self:OnClickType(self._tabList[2].type)
            else
                self:OnClickType(self._tabList[1].type)

            end
        end
    end)
end
--设置立绘
function UIUendWin:SetModelPaint()
    local paintTans = self.mSpine
    local ref = gModelEndles:GetEndlessRefByType(self._endlesInfo.type)
    local races = string.split(ref.race or "", ",")
    local index = math.random(1, #races)
    local initRaceHeroList = gModelHero:GetInitRaceHeroList(tonumber(races[index])) or {}
    index = math.random(1, #initRaceHeroList)
    local effHero = GameTable.CharacterEffectRef[initRaceHeroList[index].heroRefId]
    local whileCount = 0
    while (not gModelHero:GetHeroActShowState(effHero.heroType) and whileCount <= 100) do
        index = math.random(1, #races)
        initRaceHeroList = gModelHero:GetInitRaceHeroList(tonumber(races[index])) or {}
        index = math.random(1, #initRaceHeroList)
        effHero = GameTable.CharacterEffectRef[initRaceHeroList[index].heroRefId]
        whileCount = whileCount + 1
    end
    local figure = effHero.heroDrawing
    self:SetWndEasyImage(self.mBgImage, effHero.heroBg)
    if (figure) then
        CS.ShowObject(paintTans, true)
        local spine = self:FindWndSpineByKey("wndEndlesSpine")
        if (spine) then
            self:DestroyWndSpineByKey("wndEndlesSpine")
        end
        -- local paintFlip = ref.paintFlip == 1
        -- local paintMultiple = ref.paintMultiple
        self:CreateWndSpine(paintTans, figure, "wndEndlesSpine", false, function(dpSpine)
            -- dpSpine:SetScale(1.5)
            -- dpSpine:SetFlipX(paintFlip)
            local dpTrans = dpSpine:GetDisplayTrans()
            dpTrans.anchorMin = Vector2.New(0.5, 0.5)
            dpTrans.anchorMax = Vector2.New(0.5, 0.5)
            dpSpine:PlayAnimationSolid("idle", true)
            self:SetWndClick(self.mSpine, function()
                -- self:SetRunSpineAin("spineKey")
                self:SetModelPaint()

            end)
        end)
    else
        CS.ShowObject(paintTans, false)
    end
end
--function UIUendWin:IsChallengeType(type)
--	if(type>1)then
--		local maxNode = gModelEndles:GetMaxNode()
--		if(maxNode>0)then
--			local ref = gModelEndles:GetEndlessCheckpointRefByRefId(maxNode)
--			maxNode = ref.id
--		end
--		local node = gModelEndles:GetEndlessConfigRefByKey("rotateUnlockNum")
--		if(maxNode < node)then
--			GF.ShowMessage(string.replace(ccClientText(17260),node))
--			return false
--		end
--		local lv = gModelEndles:GetEndlessConfigRefByKey("rotateUnlockLv")
--		local playerLv = gModelPlayer:GetPlayerLv()
--		if(playerLv < lv)then
--			GF.ShowMessage(string.replace(ccClientText(17262),lv))
--			return false
--		end
--	end
--	return true
--end
------------------------------------------------------------------
return UIUendWin