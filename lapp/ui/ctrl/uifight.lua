---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
local CS = CS
local typeof = typeof
local Tweening = DG.Tweening
local typeDOTween = Tweening.DOTween
local EaseOutCubic = Tweening.Ease.OutCubic
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local Vector3 = Vector3
---@class UIFight:LWnd
local UIFight = LxWndClass("UIFight", LWnd)

local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)
local YXTouchManager = CS.YXTouchManager

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFight:UIFight()
    -- self._timeGuildFeudalKey = "_timeGuildFeudalKey"
    self:SetHideHurdle()
    self:SetHideTop()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFight:OnWndClose()
    self:ClearBloodTween()
    self:ClearCommonIconList(self._uiCommonList)
    self:StopHurtCountTween()

    if self._meSliderUp and self._otherSliderUp and self._meSliderDown and self._otherSliderDown then
        self._meSliderUp:CleanUp()
        self._otherSliderUp:CleanUp()
        self._meSliderDown:CleanUp()
        self._otherSliderDown:CleanUp()
        self._meSlider = nil
        self._otherSlider = nil
        self._meSliderDown = nil
        self._otherSliderDown = nil
    end

    if self._rewardBar then
        self._rewardBar:CleanUp()
        self._rewardBar = nil
    end

    if self._preparatoryBar then
        self._preparatoryBar:CleanUp()
        self._preparatoryBar = nil
    end

    if self._seqCom then
        self._seqCom:Destroy()
        self._seqCom = nil
    end

    GF.CloseWndByName("UIBulletSaySendPop")
    GF.CloseWndByName("UIWatchAllBf")
    GF.CloseWndByName("UIBulletSay")
    GF.CloseWndByName("UIBfDetails")
    GF.CloseWndByName("UIFightInfoSow")

    GF.CloseWndByName("UIFightEffectSow")

    LWnd.OnWndClose(self)
    self:IsShowBarrage(false)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFight:OnCreate()
    LWnd.OnCreate(self)
    self._uiCommonList = {}
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

    self._seqCom = SequenceCom:New()
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFight:OnStart()
    LWnd.OnStart(self)

    --- 用于屏幕特效显示层级
    GF.OpenWndTop("UIFightEffectSow")

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isJa = gLGameLanguage:IsJapanVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitUI()
    self:SetStaticContent()
    self:InitData()
    self:InitEvent()
    self:InitMessage()
    self:InitTeamInfo()
    self:OnWndRefresh()

    self:RefreshForeign()
end

function UIFight:IsShowBarrage(bool)
    if (bool) then
        local channel = self:GetBarrageChannel()
        if not channel then
            return
        end
        gModelGeneral:OpenBarrage({ channel = channel })
    else
        GF.CloseWndByName("UIBulletSay")
    end
end

function UIFight:ReplaceFirstItem(index)
    --移除首位
    if index <= 1 then
        return
    end

    local isPlayed = true
    local firstItemInfo = self._heroUIList[1]
    local battle = gLFightManager:GetCurBattleUnit()
    if battle then
        isPlayed = battle:IsHeroPlayed(firstItemInfo.itemdata.id)
    end
    local removeList = {}

    self._heroUIList[1] = nil
    table.insert(removeList, firstItemInfo)

    local itemInfo = self._heroUIList[index]
    self._heroUIList[index] = nil
    --table.insert(removeList,itemInfo)
    local originPos = itemInfo.item.localPosition
    local itemdata = itemInfo.itemdata

    for k, v in ipairs(itemInfo.startList) do
        self._starItemPool:ReturnObj(v)
    end
    self._sHeroItemPool:ReturnObj(itemInfo.item)

    local curList = {}
    local first = {
        itempos = 1,
        itemdata = itemdata
    }
    table.insert(curList, first)
    if not isPlayed then
        local second = {
            itempos = 2,
            itemdata = firstItemInfo.itemdata

        }

        table.insert(curList, second)
    end

    for k, v in pairs(self._heroUIList) do
        if v.itempos < index then
            if not v.itemdata.isDead then
                table.insert(curList, v)
            else
                table.insert(removeList, v)
            end
        else
            table.insert(curList, v)
        end
    end

    table.sort(curList, function(a, b)
        if a.itempos ~= b.itempos then
            return a.itempos < b.itempos
        end
        local isANew = a.item == nil and 1 or 2
        local isBNew = b.item == nil and 1 or 2
        return isANew < isBNew
    end)

    local list = {}
    for k, v in ipairs(curList) do
        v.itempos = k
        list[k] = v
    end

    self._heroUIList = list

    local item = self._bHeroItemPool:GetObj()
    CS.ShowObject(item, true)
    item.transform:SetParent(self.mHeroList, false)
    item.transform.localPosition = originPos
    item.transform.localScale = Vector3.New(1, 1, 1)
    self:OnDrawHero(item.transform, itemdata, 1)

    if not isPlayed then
        local sItem = self._sHeroItemPool:GetObj()
        CS.ShowObject(sItem, true)
        sItem.transform:SetParent(self.mHeroList, false)
        sItem.transform.localPosition = firstItemInfo.item.localPosition
        sItem.transform.localScale = Vector3.New(1, 1, 1)
        self:OnDrawHero(sItem.transform, firstItemInfo.itemdata, 2)
    end

    local seq = self._seqCom:CreateSeq("heroItemMove")

    for k, v in pairs(self._heroUIList) do
        local pos = self._posList[k]
        --printInfoN("movepos "..pos)
        local tween = v.item:DOLocalMoveX(pos, 0.5)
        if k == 1 then
            seq:Append(tween)
        else
            seq:Join(tween)
        end
    end

    local time = 0.5
    for k, v in pairs(removeList) do
        local pos = self._posList[v.itempos]
        local dest = pos + 68 * 6
        local tween = v.item:DOLocalMoveX(dest, time)
        seq:Join(tween)
    end

    local recycleFunc = function()
        for k, v in pairs(removeList) do
            for k1, v1 in ipairs(v.startList) do
                self._starItemPool:ReturnObj(v1)
            end
            if v.itempos == 1 then
                self._bHeroItemPool:ReturnObj(v.item)
            else
                self._sHeroItemPool:ReturnObj(v.item)
            end
        end
    end

    seq:OnComplete(function()
        self._seqCom:DeleteSeq("heroItemMove")
    end)

    seq:OnKill(function()
        recycleFunc()
    end)
    seq:PlayForward()
end

function UIFight:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:OnClickReturn()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mSkipBtn, function()
        self:OnClickSkip()
    end, LSoundConst.CLICK_BUTTON_COMMON) --跳过战斗按钮
    self:SetWndClick(self.mSkipAllBtn, function()
        self:OnClickSkipAll()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mMeBuffBg, function()
        self:ShowBuffWnd(true)
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mOtherBuffBg, function()
        self:ShowBuffWnd(false)
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mSpeedBtn, function()
        self:FightSpeed()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mBtnBalance, function()
        self:OnClickBalance()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mBarrageInputBtn, function()
        self:OnClickBarrageInput()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mBtnSorceryCard, function()
        self:OnClickSorceryCard()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    self:SetWndClick(self.mBtnTSorceryCard, function()
        self:OnClickSorceryCard()
    end, LSoundConst.CLICK_BUTTON_COMMON)
    -- self:SetWndClick(self.mGuildFeudalWeakMask,function () self:OnClickGuildFeudalWeakness() end)
    -- self:SetWndClick(self.mGuildFeudalWeakness,function () self:OnClickGuildFeudalWeakness() end)
end

function UIFight:InitRewardProgress()
    self._showRewardProgress = self:IsShowRewardProgress()
    CS.ShowObject(self.mRewardProgress, self._showRewardProgress)

    if not self._showRewardProgress then
        return
    end
    self:UpDateRewardProgress()
end

function UIFight:OnClickBarrageInput()
    local channel = self:GetBarrageChannel()
    if not channel then
        return
    end
    local bool = gModelChat:GetChatChannelIsOpent(channel, 2, true)
    if (not bool) then
        return
    end
    local para = { channel = channel, isShow = self._isBarrageShow }
    gModelChat:OnClickOpentBarrageWin(para)
end

function UIFight:SetPlayerName()
    local leftName = nil
    local rightName = nil
    local comBatType = self._combatType
    if comBatType == LCombatTypeConst.COMBAT_BATTLE_VIDEO_SIMULATION then
        leftName = self._combatExtraData.meName
        rightName = self._combatExtraData.otherName
    else
        local curBattle = gLFightManager:GetCurBattleUnit()
        if curBattle then
            leftName = curBattle:GetFormationName(true)
            rightName = curBattle:GetFormationName(false)
            rightName = ccLngText(rightName)
        end
    end

    if string.isempty(leftName) then
        leftName = self._combatExtraData.meName
        if string.isempty(leftName) and comBatType == LCombatTypeConst.COMBAT_MAIN then
            leftName = gModelPlayer:GetPlayerName()
        end
    end

    if string.isempty(leftName) then
        leftName = self._combatExtraData.meName
        if string.isempty(leftName) and LCombatTypeConst.COMBAT_INVASION_BOSS then
            leftName = gModelPlayer:GetPlayerName()
        end
    end

    if string.isempty(rightName) then
        rightName = self._combatExtraData.otherName
    end

    if comBatType == LCombatTypeConst.COMBAT_DUNGEON_DAILY then

    end

    self:SetWndText(self.mMeName, leftName)

    if gModelTower:GetIsTowerTypeByCombatType(comBatType) then
        local towerType = gModelTower:GetTowerTypeByCombatTyep(comBatType)

        if towerType == ModelTower.RACE_TYPE_99 then
            rightName = gModelTower:GetTowerCurrNameByType(ModelTower.RACE_TYPE_99, comBatType)
        end
    end

    self:SetWndText(self.mOtherName, rightName)

    self:InitTextSizeWithLanguage(self.mMeName, -2)
    self:InitTextSizeWithLanguage(self.mOtherName, -2)
end

function UIFight:RefreshCrusadeAgainstShow()
    --local combatExtraData = self._combatExtraData
    --if not combatExtraData then return end
    --local combatType = combatExtraData.combatType
    --if combatType ~= LCombatTypeConst.COMBAT_CRUSADE_AGAINST then return end
    --local targetId = combatExtraData.targetId
    --local ref = gModelCrusadeAgainst:GetDreamCrusadeCheckpointRefByRefId(targetId)
    --if string.isempty(ref.requirement)then return end
    --CS.ShowObject(self.mCrusadeAgainstMag,true)
    --local requirement = string.split(ref.requirement,"=")
    --local str = ""
    --if requirement[1] == "1" then
    --	str = string.replace(ccClientText(32311),requirement[2])
    --elseif requirement[1] == "2" then
    --	str = string.replace(ccClientText(32334),requirement[2])
    --elseif requirement[1] == "3" then
    --	str = string.replace(ccClientText(32335),requirement[2])
    --end
    --self:SetWndText(self.mCrusadeAgainstText,str)
end

function UIFight:OnHeroPlay(id)
    if not self._heroUIList then
        return
    end
    local index
    for k, v in pairs(self._heroUIList) do
        if v.itemdata.id == id then
            index = v.itempos
        end
    end

    if index then
        self:ReplaceFirstItem(index)
    end
end

function UIFight:ShowBuffWnd(isMe)
    local heroIDList = self:GetCurrentBattleHeroID(isMe)
    GF.OpenWnd("UIBf", { refIdList = heroIDList })
end

function UIFight:ShowWithoutTween()
    self:SetBloodPositionCenter()
    self:SetMeAndOtherBattleTeamBuff()
    self:ShowBattleRoundNum()
    --self:CalcArtifactUIPos()
    local size = Vector3(1, 1, 1)

    local otherEndP = 1
    local meEndP = 1

    local curBattleUnit = gLFightManager:GetCurBattleUnit()
    if not curBattleUnit then
        return
    end
    local maxHpA = curBattleUnit:GetTeamHPCountA() or 1
    local maxHpB = curBattleUnit:GetTeamHPCountB() or 1
    local curHpA = curBattleUnit:GetTeamHPA() or 1
    local curHpB = curBattleUnit:GetTeamHPB() or 1

    meEndP = curHpA / maxHpA
    otherEndP = curHpB / maxHpB

    self:ModifyTopUIPos()

    self._meSliderUp:SetUIProgress(meEndP)
    self._meSliderDown:SetUIProgress(meEndP)
    self._otherSliderUp:SetUIProgress(otherEndP)
    self._otherSliderDown:SetUIProgress(otherEndP)
    --self.mRound.localScale = size
    --self.mBuffBtn.localScale = size
    local showSpeed = self:IsShowFightSpeedBtn()
    CS.ShowObject(self.mSpeedBtn, showSpeed)
    --if showSpeed then
    --	self.mSpeedBtn.localScale = midSize
    --end

    self.mMultiRoot.localScale = Vector3.one
    --local showSkip = self:IsShowSkipBtn()
    --CS.ShowObject(self.mSkipBtn,showSkip)

    self:RefreshSkipBtnShow()

    --if showSkip then
    --	self.mSkipBtn.localScale = midSize
    --end
    --self.mBarrageBtn.localScale = size
    self.mBarrageInputBtn.localScale = size
    --self.mBuffBtn.localScale = size
    self.mBottom.localScale = size
    self.mVs.localScale = size
    self.mBtnBalance.localScale = size
    --if self:IsReturnBtnShow() then
    --	self.mReturnBtn.localScale = size
    --end

    self.mRewardProgress.localPosition = Vector3.New(0, self.mRewardProgress.localPosition.y, 0)
    self.mInvasionPart.localPosition = Vector3.New(0, self.mInvasionPart.localPosition.y, 0)

    local tPos = self.mLeftDivineSkillDiv.localPosition
    self.mLeftDivineSkillDiv.localPosition = Vector3(-141, tPos.y, tPos.z)

    tPos = self.mRightDivineSkillDiv.localPosition
    self.mRightDivineSkillDiv.localPosition = Vector3(141, tPos.y, tPos.z)
    self.mLeftDivineSkillCG.alpha = 1
    self.mRightDivineSkillCG.alpha = 1
end

function UIFight:RabbitEffect(effect)
    local seqCom = self:GetSeqCom()
    local seq = seqCom:CreateSeq("loopRestart")
    seq:AppendCallback(function()
        effect:RestartFx()
    end)
    seq:AppendInterval(5)
    seq:SetLoops(-1)
    seq:PlayForward()
end

function UIFight:ShowWonderHeroPower()
    local idList = self:GetSelfHeroIdList()
    local power, percent = gModelWonderland:GetFormationPower(idList)
    if power == 0 then
        return false
    end
    local powerStr = LUtil.FormatPowerShowStr(power)
    self:SetWndText(self.mMeFightNum, powerStr)
    local percentStr = ""
    if percent > 0 then
        percentStr = string.format("(+%0.2f%%)", percent * 100)
        percentStr = LUtil.FormatColorStr(percentStr, "lightGreen")
        percentStr = LUtil.FormatSizeStr(percentStr, 16)
        --percentStr = string.format("<voffset=-0.7em>%s</voffset>",percentStr)
    end

    self:SetWndText(self.mAddPercent, percentStr)
    --self:SetWndText(self.mMeFightNum,powerStr.." "..percentStr)
    return true
end

function UIFight:PlayStartFightAnimation()
    self:SetMeAndOtherBattleTeamBuff()
    --self:CalcArtifactUIPos()
    local size = Vector3(1, 1, 1)
    local showTime = 0.7

    local otherEndP = 1
    local meEndP = 1

    local curBattleUnit = gLFightManager:GetCurBattleUnit()

    if not curBattleUnit then
        return
    end
    local curHpA = curBattleUnit:GetTeamHPA() or 1
    local curHpB = curBattleUnit:GetTeamHPB() or 1
    local maxHpA = curBattleUnit:GetTeamHPCountA() or 1
    local maxHpB = curBattleUnit:GetTeamHPCountB() or 1

    meEndP = curHpA / maxHpA
    otherEndP = curHpB / maxHpB

    self._meSliderUp:SetUIProgress(0)
    self._meSliderDown:SetUIProgress(0)
    self._otherSliderUp:SetUIProgress(0)
    self._otherSliderDown:SetUIProgress(0)

    local seqCom = self:GetSeqCom()
    local tween = seqCom:CreateSeq(self._uiStartTweenKey)
    --self:StopSeqTween()
    --local tween = typeDOTween.Sequence()
    --self._seqTween = tween
    local localMoveTween = self.mMe:DOLocalMoveX(-156, showTime)
    tween:Append(localMoveTween)
    --local meArtifactTween = self.mMeArtifact:DOLocalMoveX(self.mMeArtifact.localPosition.x + 720,showTime)
    --tween:Join(meArtifactTween)
    localMoveTween = self.mOther:DOLocalMoveX(156, showTime)
    tween:Join(localMoveTween)
    --local otherArtifactTween = self.mOtherArtifact:DOLocalMoveX(self.mOtherArtifact.localPosition.x - 720,showTime)
    --tween:Join(otherArtifactTween)

    localMoveTween = self.mRewardProgress:DOLocalMoveX(0, showTime)
    tween:Join(localMoveTween)
    localMoveTween = self.mInvasionPart:DOLocalMoveX(0, showTime)
    tween:Join(localMoveTween)

    self.mMultiRoot.localScale = Vector3.zero
    local tweener = self.mMultiRoot:DOScale(Vector3.one, 0.3)
    tween:Join(tweener)
    --local moveTween = self.mLeftSkill:DOLocalMoveX(-126,showTime)
    --tween:Join(moveTween)
    --
    --moveTween = self.mRightSkill:DOLocalMoveX(126,showTime)
    --tween:Join(moveTween)

    local isEndless = gModelBattle:IsEndlessCombat(self._combatType)
    if not isEndless then
        local lvTween = self.mLeftDivineSkillDiv:DOLocalMoveX(-141, showTime)
        tween:Join(lvTween)
        local lSkillCG = self.mLeftDivineSkillCG
        local lSkillCGTweener = YXTween.TweenFloat(0, 1, showTime, function(t)
            lSkillCG.alpha = t
        end)
        tween:Join(lSkillCGTweener)

        lvTween = self.mRightDivineSkillDiv:DOLocalMoveX(141, showTime)
        tween:Join(lvTween)
        local rSkillCG = self.mRightDivineSkillCG
        local rSkillCGTweener = YXTween.TweenFloat(0, 1, showTime, function(t)
            rSkillCG.alpha = t
        end)
        tween:Join(rSkillCGTweener)
    end

    local time = 0.5
    local meTweener = YXTween.TweenFloat(0, meEndP, time, function(t)
        self._meSliderUp:SetUIProgress(t)
    end)
    tween:Append(meTweener)

    local otherTweener = YXTween.TweenFloat(0, otherEndP, time, function(t)
        self._otherSliderUp:SetUIProgress(t)
    end)
    tween:Join(otherTweener)

    local meTweenerDown = YXTween.TweenFloat(0, meEndP, time, function(t)
        self._meSliderDown:SetUIProgress(t)
    end)
    tween:Join(meTweenerDown)

    local otherTweenerDown = YXTween.TweenFloat(0, otherEndP, time, function(t)
        self._otherSliderDown:SetUIProgress(t)
    end)
    tween:Join(otherTweenerDown)

    self.mBottom.localScale = Vector3.zero
    local scaleTween = self.mBottom:DOScale(size, 0.3):SetEase(EaseOutCubic)
    tween:Join(scaleTween)

    --tween:AppendInterval(staytime)
    --self.mRound.localScale = Vector3.zero
    --local roundTween = self.mRound:DOScale(size,0.3):SetEase(EaseOutCubic)
    --tween:Join(roundTween)


    --self:AddBtnTween(tween,self.mBuffBtn,size)
    local showSpeed = self:IsShowFightSpeedBtn()
    CS.ShowObject(self.mSpeedBtn, showSpeed)
    --if showSpeed then
    --	self:AddBtnTween(tween,self.mSpeedBtn,midSize)
    --end
    --local showSkip = self:IsShowSkipBtn()
    --CS.ShowObject(self.mSkipBtn,showSkip)
    self:RefreshSkipBtnShow()
    --if showSkip then
    --	self:AddBtnTween(tween,self.mSkipBtn,midSize)
    --end
    self:AddBtnTween(tween, self.mVs, size)
    self:AddBtnTween(tween, self.mBtnBalance, size)


    --local isOpenShow = gModelFunctionOpen:CheckIsShow(16002030)
    --CS.ShowObject(self.mBuffBtn, isOpenShow)
    --if isOpenShow then
    --	self:AddBtnTween(tween,self.mBuffBtn,size)
    --end

    --local isOpenShow = gModelFunctionOpen:CheckIsShow(11721000)
    local isOpenShow = true
    if isOpenShow then
        self:AddBtnTween(tween, self.mBarrageInputBtn, size)
    end

    local showStatus = self:GetShowBtnSorceryCardStatus()
    if showStatus > 0 then
        local btnCG = showStatus == 1 and self.mBtnSorceryCardCG or self.mBtnTSorceryCardCG
        local btnCGTweener = YXTween.TweenFloat(0, 1, time, function(t)
            btnCG.alpha = t
        end)
        tween:Join(btnCGTweener)
    end

    --if self:IsReturnBtnShow() then
    --	self:AddBtnTween(tween,self.mReturnBtn,size)
    --end

    tween:OnComplete(function()
        local wndName = self:GetWndName()
        self:SendGuideReadyEvent(wndName)
        --self._seqTween = nil

        --self:InitHeroList()
        self:OnBadgeGameStar()

        self:ShowBattleRoundNum()
        seqCom:DeleteSeq(self._uiStartTweenKey)
    end)

    tween:Play()
end

function UIFight:UpdateHurtCntBar()
    if self._defaultCombatType ~= LCombatTypeConst.COMBAT_INVASION_BOSS then
        return
    end
    local curBattle = gLFightManager:GetCurBattleUnit()
    if not curBattle then
        return
    end

    local seq = self._seqCom:CreateSeq("tweenHurtBar") --会kill 未完成的tween


    local totalHurt = curBattle:GetTeamShowHurtCnt(LFightConst.SIDE_TEAM_A)
    local bossId = curBattle:GetMonsterAttrId(LFightConst.SIDE_TEAM_B)

    local reward, nextReward = gModelInvasion:GetBossRewardByHurt(bossId, totalHurt)
    local curNeedHurt = reward and reward.needHurt or 0
    local needHurt = nextReward.needHurt
    local sort = reward and reward.sort or 0

    local curTotal = needHurt - curNeedHurt
    local percent = 1
    if needHurt > 0 then
        percent = (totalHurt - curNeedHurt) / curTotal
    end

    percent = Mathf.Clamp(percent, 0, 1)

    local oldPercent = self._oldPercent or 0
    local oldSort = self._oldSort or 0

    --print("oldPercent -------------------"..oldPercent)
    local tweenDataList = {}
    local dif = sort - oldSort
    local data = nil

    local totalLength = 0
    local startP = oldPercent
    for k = 1, dif do
        data = {
            from = startP,
            to = 1,
        }
        table.insert(tweenDataList, data)
        totalLength = 1 - startP + totalLength

        startP = 0
    end

    data = {
        from = startP,
        to = percent,
    }
    totalLength = percent - startP + totalLength
    table.insert(tweenDataList, data)

    local timePer = 0.8 / totalLength

    timePer = math.min(10, timePer)

    self._oldPercent = percent
    self._oldSort = sort

    local frontTween, backTween, time
    for k, v in ipairs(tweenDataList) do
        time = (v.to - v.from) * timePer
        backTween = YXTween.TweenFloat(0, 1, time, function(t)
            local value = Mathf.Lerp(v.from, v.to, t)
            LxUiHelper.SetProgress(self.mBack, value)
        end)
        frontTween = YXTween.TweenFloat(0, 1, time, function(t)
            local value = Mathf.Lerp(v.from, v.to, t)
            LxUiHelper.SetProgress(self.mFront, value)
        end)

        seq:Append(backTween)
        seq:Append(frontTween)
        seq:AppendInterval(0.05)
    end

    seq:OnComplete(function()
        self._seqCom:DeleteSeq("tweenHurtBar")
    end)

    seq:OnKill(function()
        self:ShowHurtCntBarInter(bossId, totalHurt)
    end)
    seq:PlayForward()
end

function UIFight:ShowNewHeroThemeStoryPower()
    local battle = gLFightManager:GetCurBattleUnit()
    local powerA, powerB = 0

    if battle then
        local teamData = battle and battle:GetTeamAData()
        powerA = teamData and teamData:GetGridPower() or 0
        teamData = battle and battle:GetTeamBData()
        local monsterRefId = teamData and teamData.monsterFormationRefId
        if monsterRefId then
            local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(monsterRefId)
            powerB = monsterFormationRef.monsterPower
        end
    end

    local str = LUtil.FormatPowerShowStr(powerA)
    self:SetWndText(self.mMeFightNum, str)
    str = LUtil.FormatPowerShowStr(powerB)
    self:SetWndText(self.mOtherFightNum, str)
end

function UIFight:InitHeroList()
    local battle = gLFightManager:GetCurBattleUnit()
    if battle then
        local speedDataList = battle:GetCurSpeedDataList()
        self:ShowHeroList(speedDataList)
    end
end

function UIFight:OnClickReturn()
    local combatType = self._combatType
    if gModelBattle:IsEndlessCombat(combatType) then
        self:ExitEndless()
    elseif gModelBattle:IsTimeCorridorCombat(combatType) then
        self:ExitTimeCorridor()
    elseif combatType == LCombatTypeConst.COMBAT_TYPE_75 then
        self:ExitHardTower()
    else
        gLFightManager:OnClickBattleClose(self._combatType)
    end
end

function UIFight:InitData()
    self._countDownSkipKey = "skipClickCountDownKey"
    self._skipClickCD = 1 -- 跳过按钮间隔时间
    self._isClickSkip = true
    self._skipBtnCount = 0
    self._combatType = LCombatTypeConst.COMBAT_MAIN
    self._battleSpeed = 0.1
    self._meHP = nil    --我方队伍生命值
    self._otherHP = nil --对方队伍生命值
    self._meSliderUp = self:UIProgressFind(self.mMeBloodUp, "meBloodSliderUp", 1)
    self._meSliderDown = self:UIProgressFind(self.mMeBloodDown, "meBloodSliderDown", 1)
    self._otherSliderUp = self:UIProgressFind(self.mOtherBloodUp, "otherBloodSliderUp", 1)
    self._otherSliderDown = self:UIProgressFind(self.mOtherBloodDown, "otherBloodSliderDown", 1)
    self._rewardBar = self:UIProgressFind(self.mRewardBar, "rewardBar", 0)
    self._preparatoryBar = self:UIProgressFind(self.mPreparatoryBar, "preparatoryBar", 0)
    self._preparatoryHideKey = "preparatoryHideKey" --宝箱进度条满格后虚进度消失的计时器
    self._preparatoryHideTime = 0.8                 --宝箱进度条满格后虚进度消失的计时器
    self._targetProgressValue = nil
    self._curRewardBoxIndex = 1
    self._noSkipCombats = {
        [LCombatTypeConst.COMBAT_BATTLE_VIDEO] = true,
    }
    self._showReturnBtnTypes = {
        [LCombatTypeConst.COMBAT_TEST_BATTLE] = true,
        [LCombatTypeConst.COMBAT_TEST_LOCAL_FILE] = true,
        [LCombatTypeConst.COMBAT_BATTLE_VIDEO] = true,
        [LCombatTypeConst.COMBAT_ENDLES_LIGHT_DARK] = true,
        [LCombatTypeConst.COMBAT_ENDLES] = true,
        [LCombatTypeConst.COMBAT_ENDLES_FIRE] = true,
        [LCombatTypeConst.COMBAT_ENDLES_WIND] = true,
        [LCombatTypeConst.COMBAT_ENDLES_WATER] = true,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_STATIC] = true,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_TIME] = true,
        [LCombatTypeConst.COMBAT_TIME_CORRIDOR_THEATER] = true,
        [LCombatTypeConst.COMBAT_TYPE_75] = true,
    }
    self._canSpeedTypes = {
        [LCombatTypeConst.COMBAT_BATTLE_VIDEO] = true,
        [LCombatTypeConst.COMBAT_TEST_LOCAL_FILE] = true,
    }
    self._barrageShowTypeList = {
        LCombatTypeConst.COMBAT_MAIN,
        LCombatTypeConst.COMBAT_ARENA_PEAK_ATTACK,
        LCombatTypeConst.COMBAT_BATTLE_VIDEO,
    }
    self._bloodTweeList = {}
    self._sHeroItemPool = UIObjPool:New()
    self._sHeroItemPool:Create(self.mUnsuse, self.mSHeroItem)
    self._bHeroItemPool = UIObjPool:New()
    self._bHeroItemPool:Create(self.mUnsuse, self.mBHeroItem)
    self._starItemPool = UIObjPool:New()
    self._starItemPool:Create(self.mUnsuse, self.mStar)
    self._uiStartTweenKey = "_uiStartTweenKey"
    self._isForeign = gLGameLanguage:IsForeignVersion()

    self:InitNodeLanguage(self.mSHeroItem)
    self:InitNodeLanguage(self.mBHeroItem)

    --- 圣武
    self._leftStartPos = self.mLeftDivineStartPos.localPosition
    self._leftEndPos = self.mLeftDivineEndPos.localPosition

    self._rightStartPos = self.mRightDivineStartPos.localPosition
    self._rightEndPos = self.mRightDivineEndPos.localPosition

    self:ResetDivineDiv()
end

function UIFight:OnClickBarrage(isOne)
    local channel = self:GetBarrageChannel()
    self._isBarrageShow = not self._isBarrageShow
    if channel == 20 then
        --巅峰赛
        self._isBarrageShow = false
    end
    self:IsShowBarrage(self._isBarrageShow)
    CS.ShowObject(self.mBarrageMask, not self._isBarrageShow)
    if not channel then
        return
    end
    if (not isOne) then
        gModelChat:SetBarrageSav(channel, self._isBarrageShow)
    end
end
------------------------------------------------------------------
------------------------------------------------------------------
function UIFight:ShowBuffStatus(isLeft, refIdList)
    local trans = nil
    local effRoot = nil
    if isLeft then
        trans = self.mMeBuff
        effRoot = self.mMeEff
    else
        trans = self.mOtherBuff
        effRoot = self.mOtherEff
    end

    local buffIcon, buffEff, isActive = gModelFormation:GetBuffInfo(refIdList)
    local showIcon = false
    if buffIcon then
        self:SetWndEasyImage(trans, buffIcon)
        showIcon = true
    end

    CS.ShowObject(trans, showIcon)

    local buffStatusEffKey = isLeft and "selfBuff" or "otherBuff"
    self:DestroyWndEffectByKey(buffStatusEffKey)
    if buffEff then
        self:CreateWndEffect(effRoot, buffEff, buffStatusEffKey, 150, false, false)
    end

    --CS.ShowObject(bgTran,isActive)
end

--战斗加速
function UIFight:FightSpeed()
    local initMax = self._combatExtraData.accelerateNum

    local isGuideClickSpeed = false
    local isGuide = gModelGuide:IsInGuide()
    if isGuide then
        local guideRefId = gModelGuide:GetCurGuide()
        isGuideClickSpeed = guideRefId >= 105200
        if LOG_INFO_ENABLED then
            local state = isGuideClickSpeed and 1 or 0
            printInfoNR2("触发加速打印：", "指引触发状态" .. state)
        end
    else
        if gModelGuide:IsGuideFinished(1030) then
            isGuideClickSpeed = true
        end
        if LOG_INFO_ENABLED then
            local state = isGuideClickSpeed and 1 or 0
            printInfoNR2("触发加速打印：", "指引触发状态" .. state)
        end
    end
    local speed, speedIndex = gModelBattle:AddSpeed(self._combatType, initMax, self.clickCount, isGuideClickSpeed)

    self.clickCount = speedIndex
    local str = "X" .. self.clickCount
    self:SetTextTile(self.mSpeedBtn, str)
    --self:SetWndText(self.mSpeedBtnText,str)

    local curBattleUnit = gLFightManager:GetCurBattleUnit()
    if curBattleUnit then
        curBattleUnit:SetSpeed(speed)
    end

    CS.ShowObject(self.mSpeedEffect, false)
end

function UIFight:RefreshSkillContent()
    local battle = gLFightManager:GetCurBattleUnit()
    if not battle then
        return
    end

    local unitData, skillList, show
    --if self._defaultCombatType ~= LCombatTypeConst.COMBAT_DREAMTRIP then
    --else
    --    CS.ShowObject(self.mLeftSkill, false)
    --end

    unitData = battle:GetBattleUnitData(LFightConst.OBJ_TREASURE, LFightConst.ACTON_TEAM_A)
    skillList = nil
    if unitData then
        skillList = unitData:GetSkillRunDataList()
    end
    skillList = skillList or {}

    local dataList = {}
    show = false
    for k = 4, 1, -1 do
        local data = skillList[k]
        if not data then
            data = {
                isEmpty = true,
            }
        else
            show = true
        end
        table.insert(dataList, data)
    end
    CS.ShowObject(self.mLeftSkill, show)
    self:RefreshSkillList(self.mLeftSkillList, dataList, "leftSkillList")

    unitData = battle:GetBattleUnitData(LFightConst.OBJ_TREASURE, LFightConst.ACTON_TEAM_B)
    skillList = nil
    if unitData then
        skillList = unitData:GetSkillRunDataList()
    end

    skillList = skillList or {}

    local dataList1 = {}
    show = false
    for k = 1, 4 do
        local data = skillList[k]
        if not data or (data and data.skillId == 0) then
            data = {
                isEmpty = true,
            }
        else
            show = true
        end
        table.insert(dataList1, data)
    end
    CS.ShowObject(self.mRightSkill, show)
    self:RefreshSkillList(self.mRightSkillList, dataList1, "rightSkillList")
end

function UIFight:InitHurtCntProgress()
    if self._defaultCombatType ~= LCombatTypeConst.COMBAT_INVASION_BOSS then
        return
    end
    local curBattle = gLFightManager:GetCurBattleUnit()
    if not curBattle then
        return
    end

    local totalHurt = curBattle:GetTeamShowHurtCnt(LFightConst.SIDE_TEAM_A)
    local bossId = curBattle:GetMonsterAttrId(LFightConst.SIDE_TEAM_B)
    local reward, nextReward = gModelInvasion:GetBossRewardByHurt(bossId, totalHurt)
    local curNeedHurt = reward and reward.needHurt or 0
    local needHurt = nextReward.needHurt
    local sort = reward and reward.sort or 0

    local curTotal = needHurt - curNeedHurt
    local percent = 1
    if needHurt > 0 then
        percent = (totalHurt - curNeedHurt) / curTotal
    end

    self._oldPercent = percent
    self._oldSort = sort

    percent = Mathf.Clamp(percent, 0, 1)
    LxUiHelper.SetProgress(self.mBack, percent)
    LxUiHelper.SetProgress(self.mFront, percent)
    self:ShowHurtCntBarInter(bossId, totalHurt)
end

function UIFight:ShowBoxProgressTween(targetValue)
    self._rewardBar:StopProgressTween()
    self:TimerStop(self._preparatoryHideKey)
    local startValue = self._preparatoryBar:GetUIProgress()
    self._targetProgressValue = targetValue

    if targetValue >= startValue then
        self._preparatoryBar:SetUIProgress(targetValue)
        self._rewardBar:SetProgressTween(startValue, targetValue, 0.8)
    else
        --到下一个宝箱阶段
        self._preparatoryBar:SetUIProgress(1)
        self._rewardBar:SetUIProgress(targetValue)
        self:TimerStart(self._preparatoryHideKey, self._preparatoryHideTime, false, 1)
    end
end

-- 【G公共支持】删掉联盟领主玩法
-- function UIFight:ShowGuildBossHurtCntBar()
-- 	if self._defaultCombatType ~= LCombatTypeConst.COMBAT_TYPE_32 then
-- 		CS.ShowObject(self.mGuildBossPart,false)
-- 		return
-- 	end
-- 	CS.ShowObject(self.mGuildBossPart,true)
-- 	local curBattle = gLFightManager:GetCurBattleUnit()
-- 	if not curBattle then return end
-- 	local showInfo = curBattle:GetShowInfo()
-- 	local totalHurt = curBattle:GetTeamShowHurtCnt(LFightConst.SIDE_TEAM_A)
-- 	local monsterId = curBattle:GetMonsterAttrId(LFightConst.SIDE_TEAM_B)
-- 	self:InitGuildBossBar(totalHurt)
-- 	if not string.isempty(showInfo)then
-- 		local showInfoJ = JSON.decode(showInfo)
-- 		local bossId = showInfoJ.bossId
-- 		local damageMultiple = showInfoJ.damageMultiple
-- 		if not string.isempty(bossId) then
-- 			local isDamage = false
-- 			if not string.isempty(damageMultiple) then
-- 				isDamage = tonumber(damageMultiple) > 1
-- 			end
-- 			local bossRef = gModelGuildFeudal:GetGuildFeudalBossRefByRefId(bossId)
-- 			local formatStr,weaknessStr = ""
-- 			if monsterId == bossRef.monstet then
-- 				formatStr = ccLngText(bossRef.name)
-- 				weaknessStr = ccClientText(37352)
-- 			elseif monsterId == bossRef.monstet1 then
-- 				formatStr = isDamage and ccClientText(37333) or ccClientText(37336)
-- 				weaknessStr = string.replace(ccClientText(37353),ccClientText(37354))
-- 			elseif monsterId == bossRef.monstet2 then
-- 				formatStr = isDamage and ccClientText(37334) or ccClientText(37337)
-- 				weaknessStr = string.replace(ccClientText(37353),ccClientText(37355))
-- 			elseif monsterId == bossRef.monstet3 then
-- 				formatStr = isDamage and ccClientText(37335) or ccClientText(37338)
-- 				weaknessStr = string.replace(ccClientText(37353),ccClientText(37356))
-- 			end
-- 			if not string.isempty(damageMultiple) then
-- 				self:SetWndText(self.mGuildBossFoibleHurt,string.replace(formatStr,damageMultiple))
-- 			end
-- 			self:SetWndEasyImage(self.mGuildBossIcon,bossRef.bossIcon)
-- 			self:SetWndText(self.mWeaknessText,weaknessStr)
-- 			CS.ShowObject(self.mGuildFeudalWeakness,true)
-- 			CS.ShowObject(self.mWeaknessTextBg,true)
-- 			CS.ShowObject(self.mGuildFeudalWeakMask,true)
-- 			self._isShowWeakness = true
-- 			self:TimerStop(self._timeGuildFeudalKey)
-- 			self:TimerStart(self._timeGuildFeudalKey,10,false,1)
-- 		end
-- 	end
-- end
-- function UIFight:OnGuildFeudalNoShowMask()
-- 	CS.ShowObject(self.mWeaknessTextBg,false)
-- 	CS.ShowObject(self.mGuildFeudalWeakMask,false)
-- 	self._isShowWeakness = false
-- end
-- function UIFight:OnClickGuildFeudalWeakness()
-- 	local _isShowWeakness = self._isShowWeakness

-- 	CS.ShowObject(self.mWeaknessTextBg,not _isShowWeakness)
-- 	CS.ShowObject(self.mGuildFeudalWeakMask,not _isShowWeakness)
-- 	self._isShowWeakness = not _isShowWeakness
-- end
-- function UIFight:InitGuildBossBar(totalHurt)
-- 	if self._defaultCombatType ~= LCombatTypeConst.COMBAT_TYPE_32 then return end
-- 	local curBattle = gLFightManager:GetCurBattleUnit()
-- 	if not curBattle then return end

-- 	local curRef,nexRef = gModelGuildFeudal:GetGuildFeudalBossHpRefByRound(totalHurt)
-- 	local sort = curRef and curRef.sort or 0
-- 	local curNeedHurt = curRef and curRef.needHurt or 0
-- 	local needHurt = nexRef.needHurt
-- 	local str = tostring(totalHurt)

-- 	local curTotal = needHurt - curNeedHurt
-- 	local percent = 1
-- 	if curTotal>0 then
-- 		percent = (totalHurt- curNeedHurt)/curTotal
-- 	end
-- 	percent = Mathf.Clamp(tonumber(percent),0,1)
-- 	self._oldSort = sort
-- 	self._oldPercent = percent
-- 	LxUiHelper.SetProgress(self.mGuildBossFront,percent)
-- 	LxUiHelper.SetProgress(self.mGuildBossBack,percent)
-- 	self:SetWndText(self.mGuildBossHurtDetail,str)
-- end
-- 【G公共支持】删掉联盟领主玩法
-- function UIFight:UpdateGuildBossHurtCntBar()
-- 	if self._defaultCombatType ~= LCombatTypeConst.COMBAT_TYPE_32 then return end
-- 	local curBattle = gLFightManager:GetCurBattleUnit()
-- 	if not curBattle then return end
-- 	local seq = self._seqCom:CreateSeq("tweenGuildBossHurtBar") --会kill 未完成的tween
-- 	local totalHurt = curBattle:GetTeamShowHurtCnt(LFightConst.SIDE_TEAM_A)
-- 	local cutRef,nexRef = gModelGuildFeudal:GetGuildFeudalBossHpRefByRound(totalHurt)
-- 	local curNeedHurt = cutRef and cutRef.needHurt or 0
-- 	local needHurt = nexRef.needHurt
-- 	local sort = cutRef and cutRef.sort or 0
-- 	local curTotal = needHurt - curNeedHurt
-- 	local percent = 1
-- 	if needHurt>0 then
-- 		percent = (totalHurt- curNeedHurt)/curTotal
-- 	end
-- 	percent = Mathf.Clamp(percent,0,1)
-- 	local oldPercent = self._oldPercent or 0
-- 	local oldSort = self._oldSort or 0
-- 	local tweenDataList = {}
-- 	local dif = sort - oldSort
-- 	local data = nil
-- 	local totalLength = 0
-- 	local startP = oldPercent
-- 	for k = 1 , dif do
-- 		data =
-- 		{
-- 			from = startP,
-- 			to = 1,
-- 		}
-- 		table.insert(tweenDataList,data)
-- 		totalLength = 1 - startP + totalLength
-- 		startP = 0
-- 	end
-- 	data =
-- 	{
-- 		from = startP,
-- 		to = percent,
-- 	}
-- 	totalLength = percent - startP + totalLength
-- 	table.insert(tweenDataList,data)
-- 	local timePer = 0.8 / totalLength
-- 	timePer = math.min(10,timePer)
-- 	self._oldPercent = percent
-- 	self._oldSort = sort
-- 	local frontTween,backTween,time
-- 	for k,v in ipairs(tweenDataList) do
-- 		time = (v.to- v.from) * timePer
-- 		backTween = YXTween.TweenFloat(0,1,time,function (t)
-- 			local value = Mathf.Lerp(v.from,v.to,t)
-- 			LxUiHelper.SetProgress(self.mGuildBossBack,value)
-- 		end)
-- 		frontTween = YXTween.TweenFloat(0,1,time,function (t)
-- 			local value = Mathf.Lerp(v.from,v.to,t)
-- 			LxUiHelper.SetProgress(self.mGuildBossFront,value)
-- 		end)
-- 		seq:Append(backTween)
-- 		seq:Append(frontTween)
-- 		seq:AppendInterval(0.05)
-- 	end
-- 	seq:OnComplete(function ()
-- 		self._seqCom:DeleteSeq("tweenGuildBossHurtBar")
-- 	end)
-- 	seq:OnKill(function ()
-- 		self:InitGuildBossBar(totalHurt)
-- 	end)
-- 	seq:PlayForward()
-- end

function UIFight:ShowHurtCntBar()
    if self._defaultCombatType ~= LCombatTypeConst.COMBAT_INVASION_BOSS then
        CS.ShowObject(self.mInvasionPart, false)
        return
    end
    CS.ShowObject(self.mInvasionPart, true)

    local curBattle = gLFightManager:GetCurBattleUnit()
    if not curBattle then
        return
    end
    local totalHurt = curBattle:GetTeamShowHurtCnt(LFightConst.SIDE_TEAM_A)
    local bossId = curBattle:GetMonsterAttrId(LFightConst.SIDE_TEAM_B)

    self:ShowHurtCntBarInter(bossId, totalHurt)

    local iconPath = gModelInvasion:GetBossBuffIcon(bossId)
    self:SetWndEasyImage(self.mBossBuff, iconPath)
end
function UIFight:RefreshForeign()
    if self._isVie then
        local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
        local csHorizontalLayout = self.mHurtCountBg:GetComponent(typeHorizontalLayoutGroup)
        csHorizontalLayout.spacing = -100
        self:InitTextSizeWithLanguage(self.mSorceryCardText,-6)
    elseif self._isJa then
        local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
        local layout = self.mHurtCountBg:GetComponent(typeHorizontalLayoutGroup)
        layout.spacing = -90
    end
end

function UIFight:GetPlayModuleBelong()
    local combatType = self:GetWndArg("combatType")
    if combatType == LCombatTypeConst.COMBAT_BATTLE_VIDEO then
        local extraData = self:GetWndArg("extraData")
        combatType = extraData.combatType
    end

    local playModule = gLFightManager:GetPlayModuleByCombat(combatType)
    return playModule
end

function UIFight:LoadDivineWeaponImgCB(isLeft)
    self._curLoadDivineImgNum = self._curLoadDivineImgNum + 1
    if self._curLoadDivineImgNum >= self._curLoadDivineImgNum then
        if isLeft then
            CS.ShowObject(self.mLeftDivineDiv, true)
        else
            CS.ShowObject(self.mRightDivineDiv, true)
        end
        local startPos = isLeft and self._leftStartPos or self._rightStartPos
        local endPos = isLeft and self._leftEndPos or self._rightEndPos
        local moveTrans = isLeft and self.mLeftDivineDiv or self.mRightDivineDiv
        local seqCom = self:GetSeqCom()
        local seq = seqCom:CreateSeq("DoDivineWeaponUI")
        seq:Append(moveTrans:DOLocalMoveX(endPos.x, 0.2))
        seq:AppendInterval(1)
        seq:Append(moveTrans:DOLocalMoveX(startPos.x, 0.2))
        seq:OnComplete(function()
            self:ResetDivineDiv()
            seqCom:DeleteSeq("DoDivineWeaponUI")
        end)
        seq:PlayForward()
    end
end

function UIFight:OnClickSkip()
    local combatExtraData = self._combatExtraData
    if not combatExtraData then
        return
    end
    local combatType = combatExtraData.combatType
    local targetId = combatExtraData.targetId

    local canSkip = gModelBattle:CanSkip(combatType, true, targetId)
    if not canSkip then
        return
    end
    combatType = self._combatType
    if self._isClickSkip then
        self._isClickSkip = false
        self:TimerStart(self._countDownSkipKey, self._skipClickCD, false, -1)
        gLFightManager:SkipBattle(combatType)
    end
end

function UIFight:RefreshTeamStateSingle(data, index)
    if not self._teamRootList then
        return
    end

    local item = self._teamRootList[index]
    if not CS.IsValidObject(item) then
        return
    end

    local winTag = self:FindWndTrans(item, "winTag")
    local selfBlood = self:FindWndTrans(item, "selfBlood")
    local otherBlood = self:FindWndTrans(item, "otherBlood")

    CS.ShowObject(winTag, data.isEnd)
    if data.isEnd then
        local icon = "trial2_txt_1"
        if data.isWin then
            icon = "trial2_txt_2"
        end

        self:SetWndEasyImage(winTag, icon)
    end

    LxUiHelper.SetProgress(selfBlood, data.percentA)
    LxUiHelper.SetProgress(otherBlood, data.percentB)
end

function UIFight:OnHeroLifeChange(id, isDead)
    if not self._heroUIList then
        return
    end
    for k, v in pairs(self._heroUIList) do
        if v.itemdata.id == id then
            local death = self:FindWndTrans(v.item, "death")
            CS.ShowObject(death, isDead)
            v.itemdata.isDead = isDead
        end
    end
end

function UIFight:RefreshSpeedEffect(speedIndex)
    local hasMaxSpeed = gModelBattle:CheckHasUnlockMaxSpeed(self._combatType, speedIndex)
    if hasMaxSpeed then
        if LOG_INFO_ENABLED then
            printInfoNR2("莫慌，战斗速度打印：", "第一次使用速度")
        end
        self:CreateWndEffect(self.mSpeedEffect, "fx_btn_jiasu", "fx_btn_jiasu", 100)
    end
    CS.ShowObject(self.mSpeedEffect, hasMaxSpeed)
end

function UIFight:RefreshSkipBtnShow()
    local showSkip = false
    local showSkipAll = false
    if self._combatType == LCombatTypeConst.COMBAT_BATTLE_VIDEO_SIMULATION then
        showSkip = self._combatExtraData.skip == 1 and true or false
    elseif self._noSkipCombats[self._combatType] then
        showSkip = false
    else
        local skipCfg = gModelBattle:GetBattleSkipCfg(self._combatType)
        if skipCfg then
            for k, v in ipairs(skipCfg) do
                if v == 1 then
                    showSkip = true
                elseif v == 2 then
                    showSkipAll = true
                end
            end
        end

        --# http://192.168.16.2:3002/issues/580
        --# 当段位赛玩法为多队伍模式时，战斗中同时显示跳过单场和跳过整场按钮
        --# 当段位赛玩法为单队伍模式时，战斗中仅显示跳过整场按钮
        local isMultlReport = self:IsMultiReport()
        if self._combatType == LCombatTypeConst.COMBAT_CROSSGRADING_RANK and not isMultlReport then
            if showSkipAll and showSkip then
                showSkip = false
            end
        end
    end

    CS.ShowObject(self.mSkipBtn, showSkip)
    CS.ShowObject(self.mSkipAllBtn, showSkipAll)

    local str = ccClientText(14009)
    if showSkipAll then
        str = ccClientText(16619) --"单场"
    end

    self:SetTextTile(self.mSkipBtn, str)

    if self._isJa then
        local text =CS.FindTrans(self.mSkipBtn,"UIText")
        local textTran = LxUiHelper.FindXTextCtrl(text)
        textTran.enableWordWrapping = true
        self:SetAnchorPos(text,Vector2.New(0,10))
        self:InitTextLineWithLanguage(text,-50)
    end

    str = ccClientText(16620) --"整场"

    self:SetTextTile(self.mSkipAllBtn, str)

    --ios屏蔽
    if PRODUCT_G_VER == 1 then
        local combatExtraData = self._combatExtraData
        if not combatExtraData then
            return
        end
        local targetId = combatExtraData.targetId
        local canSkip = gModelBattle:CanSkip(self._combatType, false, targetId)
        CS.ShowObject(self.mSkipBtn, showSkip and canSkip)
        CS.ShowObject(self.mSkipAllBtn, showSkipAll and canSkip)
    end
end

function UIFight:OnDrawDivineSkillItem(list, item, itemdata, itempos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")
    local Bg = self:FindWndTrans(AniRoot, "Bg")
    local Icon = self:FindWndTrans(Bg, "Icon")
    local Mask = self:FindWndTrans(AniRoot, "Mask")
    local UIText = self:FindWndTrans(AniRoot, "UIText")
    local eff = self:FindWndTrans(item, "eff")

    local key = tostring(eff:GetInstanceID())
    self:DestroyWndEffectByKey(key)

    ---@type V_DivineWeaponRef
    local ref = gModelDivineWeapon:GetDivineRefBySkillId(itemdata.skillId)
    local isEmptyRef = ref == nil
    local hasRef = not isEmptyRef

    local isOpen = gModelDivineWeapon:IsSkillOpenByPos(itemdata.index)
    if not isOpen and hasRef then
        --- 未开放但有圣武的数据，显示
        isOpen = true
    end
    local lockState = not isOpen
    if isOpen and hasRef then
        isOpen = true
        lockState = false
        local qualityBg = ref.qualityBg
        if string.isempty(qualityBg) then
            local qualityRef = gModelItem:GetQualityRef(ref.quality)
            if qualityRef then
                qualityBg = qualityRef.iconBg
            end
        end
        self:SetWndEasyImage(Bg, qualityBg, function()
        end, true)
        self:SetWndEasyImage(Icon, ref.icon, function()
        end, true)
    end
    CS.ShowObject(Bg, hasRef)
    CS.ShowObject(Mask, lockState)

    local skillCd = itemdata.curCd or ""
    if isEmptyRef then
        skillCd = ""
    end
    self:SetWndText(UIText, skillCd)

    if lockState then
        return
    end

    if itemdata.isPlaying and hasRef then
        self:CreateWndEffect(eff, "fx_baowu_kejihuo", key, 40)
    end

    local clickFun = function()
        local str = ccClientText(16905)
        GF.ShowMessage(str)
    end
    if hasRef then
        clickFun = function()
            local starNum = gModelDivineWeapon:GetStarNumBySkillId(itemdata.skillId) or 0
            GF.OpenWnd("UIDivineWeaponTips", { refId = ref.refId, starNum = starNum })
        end
    end
    self:SetWndClick(item, clickFun)
end

function UIFight:ExitTimeCorridor()
    local combatType = self._combatType
    local returnFun = gModelBattle:GetReturnFun(combatType)
    local func = function()
        gLFightManager:CancelBattle(combatType)
        if returnFun then
            returnFun()
        end
    end
    gModelGeneral:OpenUIOrdinTips({ refId = 200004, func = func })
end

function UIFight:ShowHurtCntBarInter(bossId, totalHurt)
    local reward, nextReward = gModelInvasion:GetBossRewardByHurt(bossId, totalHurt)
    local sort = reward and reward.sort or 0
    local curNeedHurt = reward and reward.needHurt or 0
    local needHurt = nextReward.needHurt
    local str = tostring(totalHurt)

    local curTotal = needHurt - curNeedHurt
    local percent = 1
    if curTotal > 0 then
        percent = (totalHurt - curNeedHurt) / curTotal
    end

    percent = Mathf.Clamp(percent, 0, 1)

    --print("percent---------------------------------------- "..percent)
    self._oldSort = sort
    self._oldPercent = percent

    LxUiHelper.SetProgress(self.mFront, percent)
    LxUiHelper.SetProgress(self.mBack, percent)

    self:SetWndText(self.mHurtDetail, str)
    self:SetWndText(self.mBoxCnt, tostring(sort))
    local buffAddRef = gModelInvasion:GetBossBuffByHurt(bossId, totalHurt)
    if buffAddRef then
        str = "x" .. buffAddRef.level
        self:SetWndText(self.mAddCnt, str)
    end
end

function UIFight:OnLoadDivineWeaponUI(info)
    self:ResetDivineDiv()

    ---@type LFightObject
    local obj = info.obj
    if not obj then
        return
    end

    if not obj:IsDivineWeaponObj() then
        return
    end

    local data = obj:GetHeroData()
    if not data then
        return
    end

    ---@type LFightSkill
    local battleSkill = info.battleSkill
    if not battleSkill then
        return
    end

    ---@type LSkillData
    local skillData = battleSkill:GetSkillData()
    if not skillData then
        return
    end

    local skillRefId = skillData:GetSkillRefId()
    if not skillRefId or skillRefId < 1 then
        return
    end

    local divineId = gModelDivineWeapon:GetDivineIdBySkillId(skillRefId)
    if not divineId or divineId < 1 then
        return
    end

    local ref = GameTable.DivineWeaponRef[divineId]
    if not ref then
        return
    end

    local side = obj:GetSide()
    local isLeft = side == 1
    local qualityImg = isLeft and self.mLeftDivineQualityImg or self.mRightDivineQualityImg
    local nameImg = isLeft and self.mLeftDivineNameImg or self.mRightDivineNameImg
    local iconImg = isLeft and self.mLeftDivineIcon or self.mRightDivineIcon
    self._needLoadDivineImgNum = 3
    self._curLoadDivineImgNum = 0
    self:SetWndEasyImage(qualityImg, ref.imgBg, function()
        self:LoadDivineWeaponImgCB(isLeft)
    end)
    self:SetWndEasyImage(nameImg, ref.skillTxt, function()
        self:LoadDivineWeaponImgCB(isLeft)
    end)
    self:SetWndEasyImage(iconImg, ref.img, function()
        self:LoadDivineWeaponImgCB(isLeft)
    end)
end

function UIFight:GetSelfHeroIdList()
    local curBattle = gLFightManager:GetBattleByType(self._combatType)
    local formation = curBattle:GetFormationA()
    local idList = {}
    for k, v in ipairs(formation) do
        table.insert(idList, v._id)
    end
    return idList
end

function UIFight:ShowHeroList(dataList)
    local showTween = true
    local battle = gLFightManager:GetCurBattleUnit()
    if battle then
        local curRound = battle:GetRoundCount()
        showTween = curRound ~= 1
    end
    self._sHeroItemPool:ReturnAllObj()
    self._bHeroItemPool:ReturnAllObj()
    self._starItemPool:ReturnAllObj()

    self._seqCom:DeleteSeq("setHeroPos")
    self._seqCom:DeleteSeq("heroItemMove")

    local isEmpty = false
    if gModelBattle:ShowBattleInfoState() then
        isEmpty = #dataList == 0
    else
        isEmpty = true
    end
    CS.ShowObject(self.mHeroContent, not isEmpty)
    if isEmpty then
        return
    end

    self._heroUIList = {}

    local posList = self:FormatItemPos(#dataList)
    self._posList = posList

    for k, v in ipairs(dataList) do
        local item
        if k == 1 then
            item = self._bHeroItemPool:GetObj()
        else
            item = self._sHeroItemPool:GetObj()
        end
        CS.ShowObject(item, true)
        item.transform:SetParent(self.mHeroList, false)
        local pos = posList[k]
        --printInfoN("defaultpos "..pos)
        item.transform.localPosition = Vector3.New(pos - 400, 0, 0)
        item.transform.localScale = Vector3.New(1, 1, 1)
        self:OnDrawHero(item.transform, v, k)
    end

    if not showTween then
        for k, v in pairs(self._heroUIList) do
            local pos = self._posList[k]
            v.item.transform.localPosition = Vector3.New(pos, 0, 0)
        end
        return
    end

    local seq = self._seqCom:CreateSeq("setHeroPos")

    for k, v in pairs(self._heroUIList) do
        local pos = self._posList[k]
        --printInfoN("movepos "..pos)
        local tween = v.item:DOLocalMoveX(pos, 0.5)
        if k == 1 then
            seq:Append(tween)
        else
            seq:Join(tween)
        end
    end
    seq:PlayForward()
end

function UIFight:RewardListItem(list, item, itemdata, itempos)
    local icon = CS.FindTrans(item, "Icon")
    local num = CS.FindTrans(item, "Num")
    local icon1, iconBg1 = gModelItem:GetItemImgByRefId(itemdata.itemId)
    local num1 = itemdata.count
    self:SetWndEasyImage(icon, icon1)
    self:SetWndText(num, num1)
end

function UIFight:UpDateRewardProgress()
    if not self._showRewardProgress then
        return
    end

    local combatType = self._combatType
    local curBattle = gLFightManager:GetBattleByType(combatType)
    local hurt
    if curBattle then
        hurt = curBattle:GetTeamShowHurtCnt(LFightConst.ACTON_TEAM_A)
    end

    if not self._allHurtValue then
        --第一次注册
        self._allHurtValue = hurt or 0
    elseif self._allHurtValue == hurt then
        --总伤害没有变化， 跳出
        return
    else
        --设置总伤害值
        self._allHurtValue = hurt
    end

    local rewardBoxData = self._combatExtraData.rewardBoxData
    local maxBoxNum = #rewardBoxData
    local isMax = false
    local oldGoal = 0
    local goal
    for i = 1, maxBoxNum do
        local curData = rewardBoxData[i]
        goal = curData.goal
        self._curRewardBoxIndex = i
        if self._allHurtValue < goal then
            break ;
        end

        oldGoal = goal

        if i == maxBoxNum and self._allHurtValue >= goal then
            --获得最后一个宝箱了
            isMax = true
        end
    end

    local curVal
    local haveBox
    local progressStr
    if not isMax then
        curVal = (self._allHurtValue - oldGoal) / (goal - oldGoal) --因为是累计伤害值，为下一宝箱进度条能从0开始做处理
        haveBox = self._curRewardBoxIndex - 1
        progressStr = self._allHurtValue .. "/" .. goal
    else
        curVal = 1
        haveBox = self._curRewardBoxIndex
        progressStr = goal .. "/" .. goal
    end

    self:SetWndText(self.mRewardBoxNum, haveBox)
    self:SetWndText(self.mRewardBarValue, progressStr)

    self:ShowBoxProgressTween(curVal)
end

function UIFight:OnBadgeGameStar()
    local conditionList = {}
    local okList = {}
    if self._combatType == LCombatTypeConst.COMBAT_BADGE_GAME then
        local refId = self._combatExtraData.battleRefId or self._combatExtraData.targetId
        local ref = GameTable.BadgeGameBarrierRef[refId]
        conditionList[1] = ref.starCond1
        conditionList[2] = ref.starCond2
        okList[1] = gModelBadgeGame.starCondRefId[conditionList[1]] and true or false
        okList[2] = gModelBadgeGame.starCondRefId[conditionList[2]] and true or false

        local starInfo = ModelBadgeGame.StarImgMap[ref.type]
        if starInfo then
            local actStar,noActStar = starInfo.Act,starInfo.NoAct
            self:SetWndEasyImage(self.mImgStar1,actStar)
            self:SetWndEasyImage(self.mImgStar2,actStar)
            self:SetWndEasyImage(self.mImgStar3,actStar)

            self:SetWndEasyImage(self.mImgStar1_0,noActStar)
            self:SetWndEasyImage(self.mImgStar2_0,noActStar)
            self:SetWndEasyImage(self.mImgStar3_0,noActStar)
        end

    elseif self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        conditionList = self._combatExtraData.conditionList or conditionList
        local pb = gModelBattle:GetCombatRespPb(self._combatExtraData.resultKey)
        if pb then
            local data = JSON.decode(pb.activityData)
            for k, v in ipairs(data.conditionList or {}) do
                okList[v] = false--true
            end
        end
    end

    local isShow = #conditionList > 0
    CS.ShowObject(self.mObjStar, isShow)
    if isShow then
        local isOk = false
        local color = isOk and "139057ff" or "C81212ff"
        CS.ShowObject(self.mImgStar1, isOk)
        CS.ShowObject(self.mImgStar1_0, not isOk)
        self:SetWndText(self.mTxtStar1, ccClientText(40226))
        self:SetXUITextTransColor(self.mTxtStar1, color)

        local condRefId = conditionList[1]
        local condRef = GameTable.BadgeGameCondRef[condRefId]
        isOk = okList[condRefId] and true or false
        color = isOk and "139057ff" or "C81212ff"
        CS.ShowObject(self.mImgStar2, isOk)
        CS.ShowObject(self.mImgStar2_0, not isOk)
        self:SetWndText(self.mTxtStar2, ccLngText(condRef.text))
        self:SetXUITextTransColor(self.mTxtStar2, color)

        local condRefId2 = conditionList[2]
        if condRefId2 then
            condRef = GameTable.BadgeGameCondRef[condRefId2]
            isOk = okList[condRefId2] and true or false
            color = isOk and "139057ff" or "C81212ff"
            CS.ShowObject(self.mImgStar3, isOk)
            CS.ShowObject(self.mImgStar3_0, not isOk)
            self:SetWndText(self.mTxtStar3, ccLngText(condRef.text))
            self:SetXUITextTransColor(self.mTxtStar3, color)
        end
        CS.ShowObject(self.mTxtStar3, condRefId2 ~= nil)
    end
end

-- 技能总伤害动画
function UIFight:ChangeHurtCount(isHurt, hurt)
    if not gLGameUI:IsVisibleBattleFont() then
        return
    end

    self:StopHurtCountTween()

    self._curHurtCount = self._curHurtCount or 0
    self._curHurtCount = self._curHurtCount + hurt

    --printErrorN("ui show hurtCnt --------------"..self._curHurtCount)

    local mHurtCountCanvasGroup = self.mHurtCount:GetComponent(typeofCanvasGroup)

    local large = Vector3(3, 3, 3)       -- 大
    local small = Vector3(1.5, 1.5, 1.5) -- 小
    local alphaTime = 2
    mHurtCountCanvasGroup.alpha = 1

    local textTrans, text

    if isHurt then
        CS.ShowObject(self.mHurtCountBg, true)
        CS.ShowObject(self.mTreatCountBg, false)
        textTrans = self.mHurt
        text = self.mHurtText
    else
        CS.ShowObject(self.mHurtCountBg, false)
        CS.ShowObject(self.mTreatCountBg, true)
        textTrans = self.mTreat
        text = self.mTreatText
    end

    --当数字>7位数时，显示单位“万”，去尾显示（例如12345678=1234万）
    local fixedInfo = { limit = 7, fontindex = 10, pos = 4 } --界面用的治疗数字的"万" 序号index是10
    if isHurt then
        --伤害数字的"万" 序号index是11
        fixedInfo.fontindex = 11
    end

    local numStr = LUtil.FormatHurtNumSpriteText(tonumber(self._curHurtCount), false, nil, fixedInfo)
    self:SetWndText(text, numStr)

    local tween = typeDOTween.Sequence()
    self._hurtCountTweem = tween

    local Tween1 = textTrans:DOScale(large, 0.1):SetEase(EaseOutCubic)
    tween:Append(Tween1)
    local Tween2 = textTrans:DOScale(small, 0.08):SetEase(EaseOutCubic)
    tween:Append(Tween2)

    local hurtCountAlphaTween = CS.YXDOTweenModuleUI.DOFade(mHurtCountCanvasGroup, 0, alphaTime)
    tween:Join(hurtCountAlphaTween)

    tween:Play()
end

function UIFight:UpdateRoundText()
    local curBattle = gLFightManager:GetCurBattleUnit()
    if not curBattle then
        return
    end

    local maxRound
    --有些没有新增录像类型的战斗，只传入了round
    --if self._combatType == LCombatTypeConst.COMBAT_BATTLE_VIDEO_SIMULATION then
    if self._combatExtraData and self._combatExtraData.round and self._combatExtraData.round > 0 then
        maxRound = self._combatExtraData.round
    else
        --local combatType = self._defaultCombatType
        ----self._defaultCombatType
        --local type = GameTable.BattleGameRef[combatType] or GameTable.BattleGameRef[1]
        --maxRound = type.combatRoundLimit		--玩法ID策划暂时没配
        maxRound = curBattle:GetMaxRound()
    end

    local curRound = curBattle:GetRoundCount() or 1
    curRound = curRound > 0 and curRound or 1
    local str = curRound .. "/" .. maxRound
    self:SetWndText(self.mRoundTxt, str)
end

function UIFight:IsShowSkipBtn()
    local isSkip = true
    local type = GameTable.BattleGameRef[self._combatType]
    if type then
        local data = type.skip
        if data then
            isSkip = data == 1 and true or false
        end
    end

    if self._combatType == LCombatTypeConst.COMBAT_BATTLE_VIDEO_SIMULATION then
        isSkip = self._combatExtraData.skip == 1 and true or false
    elseif self._noSkipCombats[self._combatType] then
        isSkip = false
    end

    if self._defaultCombatType == LCombatTypeConst.COMBAT_CROSSGRADING_RANK then
        local combatExtraData = self._combatExtraData
        if combatExtraData then
            isSkip = combatExtraData.skip
        end
    end

    return isSkip
end

function UIFight:RefreshBloodSlider()
    local index = self._curTeam
    local battleUnit = gLFightManager:GetBattleByType(self._combatType, index)
    if not battleUnit then
        return
    end
    local percentA = battleUnit:GetTeamBloodPercent(LFightConst.SIDE_TEAM_A)
    local percentB = battleUnit:GetTeamBloodPercent(LFightConst.SIDE_TEAM_B)
    self._meSliderUp:SetUIProgress(percentA)
    self._meSliderDown:SetUIProgress(percentA)
    self._otherSliderUp:SetUIProgress(percentB)
    self._otherSliderDown:SetUIProgress(percentB)
end

function UIFight:SetStaticContent()
    local str = ccClientText(16608)
    self:SetWndText(self.mBuffIntro, str)
    str = ccClientText(16607)
    self:SetWndText(self.mRoundIntro, str)
    self:SetTextTile(self.mBarrageInputBtn, ccClientText(10145))
    self:SetTextTile(self.mReturnBtn, ccClientText(10167))
    self:InitTextSizeWithLanguage(self.mEndlesBuffText, -2)
    local treatTextPos = self._isForeign and Vector2.New(32, -3) or Vector2.New(32, 1)
    self:SetAnchorPos(self.mTreatText, treatTextPos)
    self:SetWndText(self.mSorceryCardText, ccClientText(29526))
    self:SetWndText(self.mTSorceryCardText, ccClientText(29526))
    CS.ShowObject(self.mObjStar, false)

    if self._isEnus then
        self:SetAnchorPos(self.mRoundTxt, Vector2.New(70, 0))
        self:SetAnchorPos(self.mRoundIntro, Vector2.New(-32.5, 0))
    end
end

function UIFight:RefreshTeamInfo()
    local isMuitlBattle = self:IsMultiReport()
    CS.ShowObject(self.mMultiRoot, isMuitlBattle)
    if not isMuitlBattle then
        return
    end

    local combatUnitList = gLFightManager:GetCombatUnitList(self._combatType)

    local teamCnt = #combatUnitList
    self._teamCnt = teamCnt

    for k, v in pairs(self._teamBtnList) do
        CS.ShowObject(v, false)
    end

    local teamRootList = {}
    for k = 1, teamCnt - 1 do
        table.insert(teamRootList, self._teamBtnList[k])
    end

    table.insert(teamRootList, self._teamBtnList[5])

    self._teamRootList = teamRootList

    for k, v in ipairs(teamRootList) do
        CS.ShowObject(v, true)
        self:SetWndClick(v, function()
            self:OnClickTeam(k)
        end)
    end

    self._curTeam = 1

    self:RefreshTeamSel()
end

function UIFight:OnBattleStartPlay()
    if not self._waitPlayStart then
        return
    end
    self._waitPlayStart = false
    self:PlayStartFightAnimation()
end

function UIFight:TweenTeamBlood(isLeft, newPercent)
    local index = isLeft and 1 or 2
    local seq = self._bloodTweeList[index]
    if seq then
        seq:Kill(false)
        self._bloodTweeList[index] = nil
    end

    local tween = typeDOTween.Sequence()
    self._bloodTweeList[index] = tween

    local time = 0.5
    local downMoveTime = 0.1
    local startPlayAlphaTime = downMoveTime + time + 0.3
    local startPlayDownMoveTime = 0.3
    local alphaTime = 0.3
    local bloodRatioTime = 0.1

    local sliderUp = isLeft and self._meSliderUp or self._otherSliderUp
    local sliderDown = isLeft and self._meSliderDown or self._otherSliderDown
    local bloodRatio = isLeft and self.mMeBloodRatio or self.mOtherBloodRatio
    local ratioText = isLeft and self.mMeBloodRatioText or self.mOtherBloodRatioText

    local ratioCG, handlePos
    if isLeft then
        ratioCG = self.mMeBloodRatio:GetComponent(typeofCanvasGroup)
        handlePos = 155 - math.ceil((1 - newPercent) * 230)
    else
        ratioCG = self.mOtherBloodRatio:GetComponent(typeofCanvasGroup)
        handlePos = -155 + math.ceil((1 - newPercent) * 230)
    end
    newPercent = newPercent > 1 and 1 or newPercent
    local oldPercent = sliderDown:GetUIProgress()
    self:SetBloodRatioText(ratioText, (oldPercent - newPercent))
    tween:Join(YXTween.TweenFloat(oldPercent, newPercent, downMoveTime, function(t)
        sliderUp:SetUIProgress(t)
    end))
    tween:Join(bloodRatio:DOLocalMoveX(handlePos, bloodRatioTime))
    ratioCG.alpha = gLGameUI:IsVisibleBattleFont() and 1 or 0
    tween:Insert(startPlayDownMoveTime, YXTween.TweenFloat(oldPercent, newPercent, downMoveTime, function(t)
        sliderDown:SetUIProgress(t)
    end))
    tween:Insert(startPlayAlphaTime, CS.YXDOTweenModuleUI.DOFade(ratioCG, 0, alphaTime))
    tween:SetAutoKill(true)
    tween:Play()
end

function UIFight:OnDrawSkill(list, item, itemdata, itempos)
    local AniRoot = self:FindWndTrans(item, "AniRoot")
    local DraconicSkill = self:FindWndTrans(AniRoot, "DraconicSkill")
    local AniRootUIText = self:FindWndTrans(AniRoot, "UIText")
    local eff = self:FindWndTrans(item, "eff")

    local key = tostring(eff:GetInstanceID())
    self:DestroyWndEffectByKey(key)

    local lock = itemdata.state == 0 or itemdata.isEmpty
    local ref, upRef = gModelDraconic:GetDraconicRefBySkillId(itemdata.skillId)
    if ref then
        lock = false
    end

    local draconicUpRefId, mask, ref, upRef
    if itemdata.isEmpty or lock then
    else

        mask = not itemdata.isPlaying
        local skillId = itemdata.skillId
        ref, upRef = gModelDraconic:GetDraconicRefBySkillId(skillId)
        draconicUpRefId = upRef and upRef.refId
    end
    local param = {
        lock = lock,
        mask = mask,
        upRefId = draconicUpRefId,
    }
    gModelDraconic:DrawSkillItem(self, DraconicSkill, param)

    local skillCd = itemdata.curCd or ""
    if not draconicUpRefId then
        skillCd = ""
    end
    self:SetWndText(AniRootUIText, skillCd)

    if itemdata.isEmpty or lock then
        return
    end

    if itemdata.isPlaying and draconicUpRefId then
        self:CreateWndEffect(eff, "fx_baowu_kejihuo", key, 27.5)
    end

    local clickFun = function()
        local str = ccClientText(16905)
        GF.ShowMessage(str)
    end
    if draconicUpRefId then
        clickFun = function()
            -- gModelGeneral:OpenOnlyTreasureTip({ treasureData = itemdata.exhibitionInfo, curCd = skillCd })
            -- Log(itemdata)
            GF.OpenWnd("UIDraconicUpStar", { refId = upRef.type, starNum = upRef.rankNow, tips = true })
        end
    end
    self:SetWndClick(item, clickFun)

    local list = self._skillTranList
    if not list then
        list = {}
        self._skillTranList = list
    end
    local sideList = list[itemdata.side]
    if not sideList then
        sideList = {}
        list[itemdata.side] = sideList
    end
    sideList[itemdata.index] = item
end

function UIFight:ResetDivineDiv()
    CS.ShowObject(self.mLeftDivineDiv, false)
    CS.ShowObject(self.mRightDivineDiv, false)

    self.mLeftDivineDiv.localPosition = self._leftStartPos
    self.mRightDivineDiv.localPosition = self._rightStartPos
end

function UIFight:SetBloodPositionCenter()
    if self.mMe then
        self.mMe.localPosition = Vector3(-155, self.mMe.localPosition.y, 0)
    end

    if self.mOther then
        self.mOther.localPosition = Vector3(155, self.mMe.localPosition.y, 0)
    end
    CS.ShowObject(self.mBattleRound, false)
    CS.ShowObject(self.mBattleWinRound, false)
end

function UIFight:ExecuteBackPress()
    local battleNode = gModelInstance:GetBattleNode()
    local isStoryNode = gModelPlot:IsStoryInstance(battleNode)
    if isStoryNode then
        return
    end
    FireEvent(EventNames.ON_BATTLE_BACK_PRESS)
end

function UIFight:ExitHardTower()
    local combatType = self._combatType
    local returnFun = gModelBattle:GetReturnFun(combatType)
    local func = function()
        gLFightManager:CancelBattle(combatType)
        if returnFun then
            returnFun()
        end
    end
    gModelGeneral:OpenUIOrdinTips({ refId = 200004, func = func })
end

function UIFight:StopHurtCountTween()
    local seq = self._hurtCountTweem
    if seq then
        seq:Kill(false)
        self._hurtCountTweem = nil
    end
end

function UIFight:InitFightSpeed()
    local isGuideEd = false
    local isGuide = gModelGuide:IsInGuide()
    if isGuide then
        local guideRefId = gModelGuide:GetCurGuide()
        isGuideEd = guideRefId < 105200
    else
        if not gModelGuide:IsGuideFinished(1030) then
            isGuideEd = true
        end
    end
    local initSpeed = self._combatExtraData.initSpeed
    local speed, speedIndex = gModelBattle:GetBattleSpeed(self._combatType, initSpeed, isGuideEd)
    local curBattleUnit = gLFightManager:GetCurBattleUnit()
    if curBattleUnit then
        curBattleUnit:SetSpeed(speed)
    end
    self.clickCount = speedIndex
    local str = "X" .. self.clickCount
    self:SetTextTile(self.mSpeedBtn, str)
    self:RefreshSpeedEffect(speedIndex)
    --self:SetWndText(self.mSpeedBtnText,str)
end

function UIFight:IsShowRewardProgress()
    local combatType = self._defaultCombatType
    if combatType ~= LCombatTypeConst.COMBAT_FAIRYLAND_BOSS and combatType ~= LCombatTypeConst.COMBAT_HALLOWEEN_BOSS and combatType ~= LCombatTypeConst.COMBAT_SWEETCOUNTRY_BOSS then
        return false
    end

    local rewardBoxData = self._combatExtraData.rewardBoxData
    if not rewardBoxData then
        return false
    end

    return #rewardBoxData > 0
end

------------------------------------------------------------------
-----------------------------------------------------------------
--参数初始化
function UIFight:InitWndPara()
    self._combatType = self:GetWndArg("combatType")
    local combatExtraData = self:GetWndArg("extraData")
    self._combatExtraData = combatExtraData
    self._videoType = combatExtraData.videoType
    self._defaultCombatType = combatExtraData.combatType or self._combatType --回放时内外战斗类型会不一致
end

------------------------------------------------------------------
function UIFight:RefreshReturnBtnShow()
    local show = self:IsReturnBtnShow()
    CS.ShowObject(self.mReturnBtn, show)
end

function UIFight:ShowBattleRoundNum()
    local combatType = self._defaultCombatType
    if not combatType then
        return
    end
    local combatExtraData = self._combatExtraData
    if not combatExtraData then
        return
    end
    local battleRoundNumStr = ""
    local battleRoundWinNumStr = ""
    if combatType == LCombatTypeConst.COMBAT_CROSSGRADING_RANK then
        local index = combatExtraData.index or 1
        battleRoundNumStr = string.replace(ccClientText(21840), index)

        local winA, winB = 0, 0
        local winnerNumber = combatExtraData.winnerNumber or {}
        if index ~= 1 then
            for i, v in ipairs(winnerNumber) do
                if i < index then
                    if v == ModelCrossGrading.ATTACK_TYPE then
                        winA = winA + 1
                    else
                        winB = winB + 1
                    end
                end
            end
        end
        battleRoundWinNumStr = string.replace(ccClientText(21841), winA, winB)
    end
    self:SetWndText(self.mBattleRound, battleRoundNumStr)
    CS.ShowObject(self.mBattleRound, true)

    self:SetWndText(self.mBattleWinRound, battleRoundWinNumStr)
    CS.ShowObject(self.mBattleWinRound, true)
end

function UIFight:ShowMainContent(isShow, tweenTime, side, index)
    tweenTime = tweenTime or 0
    tweenTime = math.max(tweenTime, 0)
    self:SetSkillIconRootShow(side, index, isShow)
    local canvasGroup = self.mBattkeWnd:GetComponent(typeofCanvasGroup)
    if tweenTime == 0 then
        canvasGroup.alpha = 1
    else
        local tween
        if isShow then
            tween = canvasGroup:DOFade(1, tweenTime)
        else
            self:SetAllEffectShow(false)
            tween = canvasGroup:DOFade(0, tweenTime)
        end

        local seq = self._seqCom:CreateSeq("fadeTween")
        seq:Append(tween)
        seq:OnComplete(function()
            if isShow then
                self:SetAllEffectShow(true)
            end
        end)
        seq:PlayForward()
    end
end

function UIFight:InitMessage()
    self:WndEventRecv(EventNames.ON_CHAT_BARRAGE_WIN, function()
        self:OnClickBarrage()
    end)
    self:WndEventRecv(EventNames.ROUND_UPDATE, function()
        self:UpdateRoundText()
    end)
    self:WndEventRecv(EventNames.BLOOD_UPDATE, function(isLeft, newPercent)
        self:TweenTeamBlood(isLeft, newPercent)
    end)
    self:WndEventRecv(EventNames.INIT_HURT_CNT, function()
        self:InitHurtCntProgress()
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerEndLessInfoResp, function(...)
        self:UpdateEndlesInfo()
    end)
    self:WndNetMsgRecv(LProtoIds.ReceiveNodeRewardResp, function(...)
        self:UpdateEndlesInfo()
    end)
    self:WndEventRecv(EventNames.CHANGE_BATTLE_WND_SHOW, function(...)
        self:ShowMainContent(...)
    end)
    self:WndEventRecv(EventNames.ON_SKILL_LIST_UPDATE, function()
        self:RefreshSkillContent()
    end)
    self:WndEventRecv(EventNames.ON_HERO_SPEED_LIST_UPDATE, function(...)
        self:ShowHeroList(...)
    end)
    self:WndEventRecv(EventNames.ON_HERO_PLAY, function(...)
        self:OnHeroPlay(...)
    end)
    self:WndEventRecv(EventNames.ON_HERO_LIFE_CHANGE, function(...)
        self:OnHeroLifeChange(...)
    end)
    self:WndEventRecv(EventNames.PLAY_START_BATTLE_EFFECT, function()
        self:OnBattleStartPlay()
    end)
    self:WndEventRecv(EventNames.SHOW_BATTLE_BUFF_WND, function(heroId)
        GF.OpenWnd("UIFightInfoSow", { selId = heroId })
    end)
    self:WndEventRecv(EventNames.ON_TIME_HERO_CHANGE, function()
        self:SetPower()
    end)
    self:WndEventRecv(EventNames.REFRESH_BATTLE_TEAM_STATE, function(...)
        self:OnBloodPercentChange(...)
    end)
    self:WndEventRecv(EventNames.ON_CHANGE_BATTLE_PLAY_INDEX, function(...)
        self:OnChangeToTeam(...)
    end)
    self:WndEventRecv(EventNames.ON_ADD_NEW_BATTLE, function()
        self:RefreshTeamInfo()
        self:RefreshTeamState()
    end)
    self:WndEventRecv(EventNames.BATTLE_HURT_MAX_COUNT_UPDATE, function()
        self:UpdateHurtCntBar()
        -- self:UpdateGuildBossHurtCntBar()
        self:UpDateRewardProgress()
    end)
    self:WndEventRecv(EventNames.BATTLE_HURT_COUNT_UPDATE, function(isHurt, hurt)
        if hurt <= 0 then
            self._curHurtCount = 0
            return
        end
        self:ChangeHurtCount(isHurt, hurt)
    end)
    self:WndEventRecv(EventNames.BADGE_GAME_BATTLE_STAR, function(...)
        self:OnBadgeGameStar()
    end)
    self:WndEventRecv(EventNames.ON_LOAD_DIVINEWEAPONUI, function(info)
        self:OnLoadDivineWeaponUI(info)
    end)
    self:WndEventRecv(EventNames.ON_DIVINE_SKILL_UPDATE, function()
        self:RefreshDivineSkillDiv()
    end)
end

function UIFight:OnClickSkipAll()
    local combatExtraData = self._combatExtraData
    if not combatExtraData then
        return
    end
    local combatType = combatExtraData.combatType
    local targetId = combatExtraData.targetId

    local canSkip = gModelBattle:CanSkip(combatType, true, targetId)
    if not canSkip then
        return
    end
    combatType = self._combatType
    if self._isClickSkip then
        self._isClickSkip = false
        self:TimerStart(self._countDownSkipKey, self._skipClickCD, false, -1)
        gLFightManager:SkipBattleAll(combatType)
    end
end

function UIFight:SetMeAndOtherBattleTeamBuff()
    local heroIDList
    heroIDList = self:GetCurrentBattleHeroID(true)
    self:ShowBuffStatus(true, heroIDList)

    heroIDList = self:GetCurrentBattleHeroID(false)
    self:ShowBuffStatus(false, heroIDList)
end

function UIFight:SetUIBeforeTween()
    self.mMe.localPosition = Vector3(-875, self.mMe.localPosition.y, 0)
    self.mOther.localPosition = Vector3(875, self.mMe.localPosition.y, 0)
    self.mRewardProgress.localPosition = Vector3(-875, self.mRewardProgress.localPosition.y, 0)
    self.mBottom.localScale = Vector3.zero
    self.mVs.localScale = Vector3.zero
    self.mBarrageInputBtn.localScale = Vector3.zero
    self.mInvasionPart.localPosition = Vector3(-875, self.mInvasionPart.localPosition.y, 0)
    self.mMultiRoot.localScale = Vector3.zero
    self.mBtnBalance.localScale = Vector3.zero
    self.mBtnSorceryCardCG.alpha = 0
    self.mBtnTSorceryCardCG.alpha = 0
    self.mLeftDivineSkillCG.alpha = 0
    self.mRightDivineSkillCG.alpha = 0

    local tPos = self.mLeftDivineSkillDiv.localPosition
    self.mLeftDivineSkillDiv.localPosition = Vector3(-475, tPos.y, tPos.z)

    tPos = self.mRightDivineSkillDiv.localPosition
    self.mRightDivineSkillDiv.localPosition = Vector3(475, tPos.y, tPos.z)

    CS.ShowObject(self.mBattleRound, false)
    CS.ShowObject(self.mBattleWinRound, false)
end

function UIFight:IsShowFightSpeedBtn()
    if self._combatType == LCombatTypeConst.COMBAT_BATTLE_VIDEO_SIMULATION then
        return self._combatExtraData.accelerate == 1 and true or false
    end
    return true
end

function UIFight:OnWndRefresh()
    LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_FIGHT_PREPARE)
    self:RefreshUI()
    self:RefreshBtnSorceryCard()
    self:UpdateEndlesInfo()
    self:RefreshSkillContent()
    self:RefreshDivineSkillDiv()
    self:InitHeroList()
    self:InitRewardProgress()
    self:InitHurtCntProgress()
    -- self:ShowGuildBossHurtCntBar()【G公共支持】删掉联盟领主玩法
    self:RefreshTeamInfo()
    self:RefreshTeamState()
    self:RefreshBtnBalanceShow()
end

function UIFight:FormatItemPos(cnt)
    local totalWidth = self.mHeroList.rect.width
    local space = 10
    local bItemSize = 68
    local sItemSize = 58

    local list = {}
    local itemWidth = bItemSize
    local leftEdge = totalWidth / 2
    for k = 1, cnt do
        if k == 1 then
            itemWidth = bItemSize
        else
            itemWidth = sItemSize
        end
        local pos = leftEdge - itemWidth * 0.5
        table.insert(list, pos)
        leftEdge = leftEdge - space - itemWidth
    end

    return list
end

function UIFight:RefreshBarrageBtnShow()
    local isShow = false
    local channel = self:GetBarrageChannel()
    if channel then
        isShow = true
    end
    isShow = false

    CS.ShowObject(self.mBarrageInputBtn, isShow)
end

function UIFight:OnTimer(key)
    if key == self._countDownSkipKey then
        self._isClickSkip = true
    elseif key == self._preparatoryHideKey then
        self:PreparatoryProgressTimerFunc()
        -- elseif key == self._timeGuildFeudalKey then
        -- 	self:OnGuildFeudalNoShowMask()
    end
end

function UIFight:UpdateEndlesInfo()
    CS.ShowObject(self.mEndlesMask, false)
    if not gModelBattle:IsEndlessCombat(self._combatType) then
        return
    end
    --self.mBtnSorceryCard.localPosition = Vector2.New(-285, 187)
    CS.ShowObject(self.mEndlesMask, true)
    local info
    local specialType = gModelEndles:GetEndlessTypeByCombatType(self._combatType)
    if specialType then
        info = gModelEndles:GetEndlesData(specialType)
    else
        info = gModelEndles:GetCurrTypeEndlesData()
    end
    if not info then
        return
    end
    local _endlesInfo = info
    local nowNode = _endlesInfo.nowNode > 0 and _endlesInfo.nowNode or _endlesInfo.initNode
    local initNode = _endlesInfo.initNode
    local dayNode = _endlesInfo.dayNode
    local nodeRef = gModelEndles:GetEndlessCheckpointRefByRefId(nowNode)

    local nowBuff = gModelEndles:GetNowBuff()
    local buffRef = gModelEndles:GetEndlessBuffRefBySkillId(nowBuff)
    if buffRef then
        local skillRef = gModelHero:GetSkillByStarId(buffRef.addAttrSkill)
        local buffDes = ccLngText(skillRef.stateDes) -- string.replace(ccClientText(17250),ccLngText(buffRef.battleBuffDesc))
        self:SetWndText(self.mEndlesBuffText, buffDes)
    end

    local str = string.replace(ccClientText(17249), nodeRef.id)
    self:SetWndText(self.mEndlesNodeText, str)
    local _itemList = gModelEndles:GetItemList()
    local isAward = #_itemList > 0
    self:SetWndText(self.mEndlesAwardDesText, ccClientText(17251))
    self:InitTextSizeWithLanguage(self.mEndlesAwardDesText, -2)
    local desStr = ccClientText(17252)
    CS.ShowObject(self.mEndlesAward, isAward)
    if (isAward) then
        if (self._endlesUiList) then
            self._endlesUiList:RefreshList(_itemList)
        else
            self._endlesUiList = self:GetUIScroll("EndlesAward")
            self._endlesUiList:Create(self.mEndlesAwardScroll, _itemList, function(...)
                self:RewardListItem(...)
            end)
        end
        desStr = ""
    elseif (dayNode > 0) then
        local initRef = gModelEndles:GetEndlessCheckpointRefByRefId(initNode)
        local dayRef = gModelEndles:GetEndlessCheckpointRefByRefId(dayNode)
        local round = gModelEndles:GetEndlessConfigRefByKey("basicsRewardRound")
        if (dayRef.id > initRef.id + round) then
            desStr = ccClientText(17258)
        else
            desStr = string.replace(ccClientText(17257), dayRef.id)
        end
    end
    self:SetWndText(self.mEndlesNoDesText, desStr)

    local maxNode = _endlesInfo.maxNode
    local nowNode = _endlesInfo.nowNode
    local ref = gModelEndles:GetUnclaimedAward(_endlesInfo.type, _endlesInfo.receiveIds)
    CS.ShowObject(self.mEndlesReward, ref)
    if not ref then
        return
    end
    local isGetAward = ref.refId <= maxNode
    local maxNodeStr = maxNode
    if (maxNode > 0) then
        local maxNodeRef = gModelEndles:GetEndlessCheckpointRefByRefId(maxNode)
        maxNodeStr = maxNodeRef.id
    end
    local getRef = gModelEndles:GetEndlessCheckpointRefByRefId(ref.refId)
    local boxStr = ""
    CS.ShowObject(self.mEndlesBoxEff, isGetAward)
    if (isGetAward) then
        boxStr = ccClientText(17254)
        self:CreateWndEffect(self.mEndlesBoxEff, "fx_richangbaoxiang", "boxEff", 100)
    else
        if (nowNode < maxNode) then
            boxStr = string.replace(ccClientText(17256), getRef.id)
        else
            boxStr = string.replace(ccClientText(17253), getRef.id - maxNodeStr)
        end
    end
    self:SetWndText(self.mEndlesBoxNumText, boxStr)

    local itemList = LxDataHelper.ParseItem(ref.reward)
    if (self._endlesBoxList) then
        self._endlesBoxList:RefreshList(itemList)
    else
        self._endlesBoxList = self:GetUIScroll("_endlesBox")
        self._endlesBoxList:Create(self.mEndlesBoxAwardScroll, itemList, function(...)
            self:EndlesAwardListItem(...)
        end)
    end
    self:SetWndClick(self.mEndlesBoxBtn, function(...)
        if (isGetAward) then
            gModelEndles:OnReceiveNodeRewardReq(_endlesInfo.type, ref.refId)
        else
            GF.OpenWnd("UIUendAwardPop", { endlesInfo = _endlesInfo, isBattle = true })
        end
    end)
end

function UIFight:OnClickTeam(teamIndex)
    if self._curTeam == teamIndex then
        return
    end

    local combatUnit = gLFightManager:GetBattleByType(self._combatType, teamIndex)

    if combatUnit:IsEndExecute() then
        local str = ccClientText(16621)
        GF.ShowMessage(str)
        return
    end

    gLFightManager:TryChangeToActive(self._combatType, teamIndex)
    self:OnChangeToTeam(teamIndex)
end

function UIFight:SetSkillIconRootShow(side, index, isShow)
    if not self._skillTranList then
        return
    end
    if not side or not index then
        for k, v in pairs(self._skillTranList) do
            for k1, v1 in pairs(v) do
                local root = self:FindWndTrans(v1, "root")
                CS.ShowObject(root, isShow)
            end
        end
        return
    end
    local sideList = self._skillTranList[side]
    if not sideList then
        return
    end

    local tran = sideList[index]
    if not CS.IsValidObject(tran) then
        return
    end

    local root = self:FindWndTrans(tran, "root")
    CS.ShowObject(root, isShow)
end

function UIFight:RefreshUI()
    self:InitWndPara()
    self:InitFightSpeed()
    self:SetPlayerName()
    FireEvent(EventNames.BATTLE_MAP_OFFSET, 0)
    self:RefreshReturnBtnShow()
    self:RefreshBarrageBtnShow()
    local channel = self:GetBarrageChannel()
    if channel then
        self._isBarrageShow = gModelChat:GetBarrageIsShow(channel)
    end
    self._isBarrageShow = not self._isBarrageShow
    self:OnClickBarrage(true)
    self:ModifyTopUIPos()
    self:SetUIBeforeTween()
    if self._combatExtraData.isNew then
        self._waitPlayStart = true
        self._skipBtnCount = 0
    else
        self._waitPlayStart = false
        self:ShowWithoutTween()
        self:OnBadgeGameStar()
    end
    self:SetPower()
    self:UpdateRoundText()
    local showUi = not self._combatExtraData.hideUI
    CS.ShowObject(self.mView, showUi)
    --异步完成处理，避免场景完成了时间发送后，界面后面才打开的情况
    local curBattleUnit = gLFightManager:GetCurBattleUnit()
    if curBattleUnit and curBattleUnit:IsStartPlay() then
        self:OnBattleStartPlay()
    end
    -- self:ShowGuildBossHurtCntBar()【G公共支持】删掉联盟领主玩法
    self:ShowHurtCntBar()
    self:RefreshCrusadeAgainstShow()

    if self._combatType == LCombatTypeConst.COMBAT_ACTIVITY_155 then
        local size = Vector2.New(26, 26)
        for i = 1, 3 do
            local trans = self["mImgStar" .. i .. "_0"]
            self:SetWndEasyImage(trans, "public_false_01")
            trans.sizeDelta = size
            trans = self["mImgStar" .. i]
            trans.sizeDelta = size
            self:SetWndEasyImage(trans, "public_icon_right_2")
        end
    end

end

function UIFight:RefreshBtnBalanceShow()
    local show = self._defaultCombatType == LCombatTypeConst.COMBAT_TYPE_25
    CS.ShowObject(self.mBtnBalance, show)
end

function UIFight:OnChangeToTeam(teamIndex)
    self._curTeam = teamIndex
    self:RefreshTeamSel()

    self:SetMeAndOtherBattleTeamBuff()
    self:SetPlayerName()
    self:SetPower()
    self:UpdateRoundText()

    self:RefreshBloodSlider()
    self:RefreshSkillContent()
    self:RefreshDivineSkillDiv()
end

function UIFight:ShowTimeCorridorHeroPower()
    return false
    --local idList = self:GetSelfHeroIdList()
    --local power,percent = gModelTimeCorridor:GetFormationPower(idList)
    --if power == 0 then
    --	return false
    --end
    --local powerStr = LUtil.FormatPowerShowStr(power)
    --self:SetWndText(self.mMeFightNum,powerStr)
    --
    --local percentStr = ""
    --if percent>0 then
    --	percentStr = string.format("(+%0.2f%%)",percent*100)
    --	percentStr = LUtil.FormatColorStr(percentStr,"lightGreen")
    --	percentStr = LUtil.FormatSizeStr(percentStr,16)
    --	--percentStr = string.format("<voffset=-0.7em>%s</voffset>",percentStr)
    --end
    --
    --self:SetWndText(self.mAddPercent,percentStr)
    ----self:SetWndText(self.mMeFightNum,powerStr.." "..percentStr)
    --
    --return true
end

function UIFight:HideSwordEffect()
    local seqCom = self:GetSeqCom()
    seqCom:DeleteSeq("loopRestart")

    local key = "normalSword"
    local eff = self:FindWndEffectByKey(key)
    if eff then
        eff:SetVisible(false)
    end
end

function UIFight:RefreshTeamSel()
    for k, v in ipairs(self._teamRootList) do
        CS.ShowObject(v, true)
        local isSelect = self._curTeam == k

        local off = self:FindWndTrans(v, "off")
        local on = self:FindWndTrans(v, "on")
        local num = self:FindWndTrans(v, "num")

        local offNumImg = self:FindWndTrans(off, "num_img")
        local onNumImg = self:FindWndTrans(on, "num_img")

        self:SetWndEasyImage(offNumImg, self._teamNumOff[k])
        self:SetWndEasyImage(onNumImg, self._teamNumOn[k])
        CS.ShowObject(off, not isSelect)
        CS.ShowObject(on, isSelect)

        local color = "yellow_2"
        if isSelect then
            color = "black"
        end

        local str = LUtil.FormatColorStr(self._teamNumStr[k], color)
        self:SetWndText(num, str)
    end
end

function UIFight:SetBloodPositionOutside()

end

function UIFight:RefreshBtnSorceryCard()
    local showStatus = self:GetShowBtnSorceryCardStatus()
    CS.ShowObject(self.mBtnSorceryCard, showStatus == 1)
    CS.ShowObject(self.mBtnTSorceryCard, showStatus == 2)
end

function UIFight:IsMultiReport()
    local combatUnitList = gLFightManager:GetCombatUnitList(self._combatType)
    local cnt = table.keysize(combatUnitList)
    return cnt > 1
end

function UIFight:RefreshDivineSkillDiv()
    local battle = gLFightManager:GetCurBattleUnit()
    if not battle then
        return
    end

    local isEndless = gModelBattle:IsEndlessCombat(self._combatType)

    local unitType = LFightConst.OBJ_DIVINEWEAPON
    ---@type LFightObjectData
    local unitData, skillList, show
    unitData = battle:GetBattleUnitData(unitType, LFightConst.ACTON_TEAM_A)
    skillList = nil
    if unitData then
        skillList = unitData:GetSkillRunDataList()
    end
    skillList = skillList or {}

    local dataList = {}
    show = false
    for k = 4, 1, -1 do
        local data = skillList[k]
        if not data then
            data = { isEmpty = true, index = 4 - k + 1 }
        else
            show = true
        end
        table.insert(dataList, data)
    end
    local lDiv = isEndless and self.mTLeftDivineSkillDiv or self.mLeftDivineSkillDiv
    CS.ShowObject(lDiv, show)
    local hLDiv = isEndless and self.mLeftDivineSkillDiv or self.mTLeftDivineSkillDiv
    CS.ShowObject(hLDiv, false)

    local lSkillList = isEndless and self.mTLeftDivineSkill or self.mLeftDivineSkill
    self:RefreshDivineSkillList(lSkillList, dataList, "mLeftDivineSkill")

    unitData = battle:GetBattleUnitData(unitType, LFightConst.ACTON_TEAM_B)
    skillList = nil
    if unitData then
        skillList = unitData:GetSkillRunDataList()
    end
    skillList = skillList or {}

    local dataList1 = {}
    show = false
    for k = 1, 4 do
        local data = skillList[k]
        if not data or (data and data.skillId == 0) then
            data = { isEmpty = true, index = k }
        else
            show = true
        end
        table.insert(dataList1, data)
    end
    local rDiv = isEndless and self.mTRightDivineSkillDiv or self.mRightDivineSkillDiv
    CS.ShowObject(rDiv, show)
    local hRDiv = isEndless and self.mRightDivineSkillDiv or self.mTRightDivineSkillDiv
    CS.ShowObject(hRDiv, false)

    local rSkillList = isEndless and self.mTRightDivineSkill or self.mRightDivineSkill
    self:RefreshDivineSkillList(rSkillList, dataList1, "mRightDivineSkill")
end

function UIFight:RefreshDivineSkillList(root, dataList, key)
    local list = self:GetUIScroll(key)
    local uiList = list:GetList()
    if not uiList then
        list:Create(root, dataList, function(...)
            self:OnDrawDivineSkillItem(...)
        end)
    else
        list:RefreshList(dataList)
    end
end

function UIFight:ModifyTopUIPos()
    --local isBossFight = self._defaultCombatType == LCombatTypeConst.COMBAT_INVASION_BOSS

    local topUiPos = isBossFight and Vector2.New(0, -40) or Vector2.New(0, -90)
    self.mMainBattle.anchoredPosition = topUiPos

    local isBossFight = false

    CS.ShowObject(self.mMeFight, not isBossFight)
    CS.ShowObject(self.mOtherFight, not isBossFight)
    CS.ShowObject(self.mOtherBloodDownDi, not isBossFight)

    local isSpecialCombatType = self._defaultCombatType == LCombatTypeConst.COMBAT_INVASION_BOSS or self._defaultCombatType == LCombatTypeConst.COMBAT_FAIRYLAND_BOSS
    --CS.ShowObject(self.mOtherBloodRatio, not isBossFight)
    CS.ShowObject(self.mOtherBloodRatio, not isSpecialCombatType)

    CS.ShowObject(self.mOtherName, not isBossFight)
    local leftSkillPos = isBossFight and Vector3.New(6, 0, 0) or Vector3.New(30, -24, 0)
    local scale = isBossFight and Vector3.New(0.9, 0.9, 0.9) or Vector3.one
    local rightSkillPos = isBossFight and Vector3.New(-6, 0, 0) or Vector3.New(-30, -24, 0)
    self.mLeftSkill.localPosition = leftSkillPos
    self.mLeftSkill.localScale = scale
    self.mRightSkill.localPosition = rightSkillPos
    self.mRightSkill.localScale = scale
end

function UIFight:ExitEndless()
    local combatType = self._combatType
    if not gModelBattle:IsEndlessCombat(combatType) then
        return
    end

    local returnFun = gModelBattle:GetReturnFun(combatType)
    local func = function()
        gLFightManager:ExitBattle(combatType)
        if returnFun then
            returnFun()
        end
        gModelEndles:OnQuitBattleReq()
    end
    gModelGeneral:OpenUIOrdinTips({ refId = 140002, func = func })
end

----------------------------- 神器 -------------------------------
function UIFight:SetPower()
    local battle = gLFightManager:GetCurBattleUnit()
    if not battle then
        return
    end

    local defaultCombatType = self._defaultCombatType
    local isSuc = false
    if defaultCombatType == LCombatTypeConst.COMBAT_WONDERLAND then
        isSuc = self:ShowWonderHeroPower()
    elseif gModelBattle:IsTimeCorridorCombat(defaultCombatType) then
        isSuc = self:ShowTimeCorridorHeroPower()
    elseif defaultCombatType == LCombatTypeConst.COMBAT_NEW_HERO_THEME_CHAPTER
            or defaultCombatType == LCombatTypeConst.COMBAT_ACTIVITY_PLOT_COPY then
        self:ShowNewHeroThemeStoryPower()
        return
    end

    if not isSuc then
        local teamAdata = battle and battle:GetTeamAData() or nil
        local power = teamAdata and teamAdata.power or 0
        local str = LUtil.FormatPowerShowStr(power)
        self:SetWndText(self.mMeFightNum, str)
    end

    local teamBdata = battle and battle:GetTeamBData() or nil
    local power = teamBdata and teamBdata.power or 0
    local temp = LUtil.FormatPowerShowStr(power)
    self:SetWndText(self.mOtherFightNum, temp)
end

function UIFight:OnClickBalance()
    GF.OpenWnd("UISuBalanceTip")
end

function UIFight:ClearBloodTween()
    if self._bloodTweeList then
        for k, v in pairs(self._bloodTweeList) do
            v:Kill(false)
        end
    end
    self._bloodTweeList = {}
end

function UIFight:WorldPosChangeUIPos(objPos)
    --场景转ui
    local sceneCamera = gLGameScene:GetCurrentSceneCamera()
    local uiSceneCamrea = LGameUI.GetUICamera()
    local screenPos = sceneCamera:WorldToScreenPoint(objPos) --Vector3
    local worldPos = uiSceneCamrea:ScreenToWorldPoint(screenPos)
    worldPos.z = 0
    return worldPos
end

function UIFight:SetBloodRatioText(trans, Progres)
    --if Progres == 0 then
    --	return
    --end

    local value = Progres * 100
    local str = value < 0 and string.format("%.1f", value) or string.format("-%.1f", value)

    local progres = str .. "%"
    self:SetWndText(trans, progres)
end

function UIFight:RefreshSkillList(root, dataList, key)
    local list = self:GetUIScroll(key)
    local uiList = list:GetList()
    if not uiList then
        list:Create(root, dataList, function(...)
            self:OnDrawSkill(...)
        end)
    else
        list:RefreshList(dataList)
    end
end

function UIFight:GetBarrageChannel()
    local channel
    if (self._combatType == LCombatTypeConst.COMBAT_BATTLE_VIDEO) then
        if self._videoType == LVideoTypeConst.PEAK then
            channel = ModelChat.CHANNEL_PEAK
        elseif self._videoType == LVideoTypeConst.CHAMPION then
            channel = ModelChat.CHANNEL_CHAMPION
        elseif self._videoType == LVideoTypeConst.GUILD_WAR then
            channel = ModelChat.CHANNEL_WAR
        elseif self._videoType == LVideoTypeConst.PLAYBACK then
            if self._defaultCombatType == LCombatTypeConst.COMBAT_MAIN then
                channel = ModelChat.CHANNEL_RISK
            end
        end
    elseif (self._combatType == LCombatTypeConst.COMBAT_MAIN) then
        channel = ModelChat.CHANNEL_RISK
    end

    return channel
end

function UIFight:GetShowBtnSorceryCardStatus()
    local showStatus = 1
    local isShow = gModelFunctionOpen:CheckIsShow(28000100)
    if isShow then
        local combatType = self._defaultCombatType
        -- if gModelBossTower:IsBossTowerCombat(combatType) then
        -- 	isShow = false
        if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
            isShow = false
        end
        if gModelBattle:IsEndlessCombat(self._combatType) then
            showStatus = 2
        end
    end
    if not isShow then
        showStatus = 0
    end
    return showStatus
end

function UIFight:InitTeamInfo()
    self._teamBtnList = {
        [1] = self.mTeam_1,
        [2] = self.mTeam_2,
        [3] = self.mTeam_3,
        [4] = self.mTeam_4,
        [5] = self.mTeam_5,
    }
    self._teamNumImg = {
        [1] = "trial2_num_1",
        [2] = "trial2_num_2",
        [3] = "trial2_num_3",
        [4] = "trial2_num_4",
        [5] = "trial2_num_5",
    }
    self._teamNumStr = {
        [1] = "I",
        [2] = "II",
        [3] = "III",
        [4] = "IV",
        [5] = "V",
    }

    self._teamNumOff = {
        [1] = "trial2_num_1",
        [2] = "trial2_num_2",
        [3] = "trial2_num_3",
        [4] = "trial2_num_4",
        [5] = "trial2_num_5",
    }
    self._teamNumOn = {
        [1] = "trial1_num_1",
        [2] = "trial1_num_2",
        [3] = "trial1_num_3",
        [4] = "trial1_num_4",
        [5] = "trial1_num_5",
    }
end

function UIFight:GetCurrentBattleHeroID(isMe)
    local formation
    --local isHero = false
    local curBattle = gLFightManager:GetCurBattleUnit() -- gLFightManager:GetBattleByType(self._combatType)
    if not curBattle then
        return {}
    end

    if isMe then
        formation = curBattle:GetFormationA()
    else
        formation = curBattle:GetFormationB()
    end

    local heroIDList = {}
    for i, v in ipairs(formation) do
        table.insert(heroIDList, { id = v._refId, isMon = v._isMonster })
    end
    return heroIDList
end

function UIFight:OnClickSorceryCard()
    local battleUnit = gLFightManager:GetCurBattleUnit()
    if not battleUnit then
        return
    end

    local listA, listB = battleUnit:GetHeroDataList()
    GF.OpenWnd("UISorceryCardBattlePop", { heroGridA = listA, heroGridB = listB })
end

function UIFight:OnDrawHero(item, itemdata, itempos)
    local iconBg = self:FindWndTrans(item, "iconBg")
    local icon = self:FindWndTrans(item, "icon")
    local iconFrame = self:FindWndTrans(icon, "frame")
    local starRoot = self:FindWndTrans(item, "starRoot")
    local death = self:FindWndTrans(item, "death")
    local tag = self:FindWndTrans(death, "tag")

    local hightStarNewHeroInfo = self:FindWndTrans(item, "HightStarNewHeroInfo")
    local hightStarNewHeroInfoText = self:FindWndTrans(hightStarNewHeroInfo, "HightStarNewHeroInforText")
    local refId = itemdata.refId
    local isMonster = itemdata.isMon
    local star = itemdata.star
    local skin = itemdata.skin
    local isRight = itemdata.isRight
    local isFirst = itempos == 1
    local quality = itemdata.quality
    local form = itemdata.form
    --local isDead = itemdata.isDead
    local iconPath, iconBgPath
    if isMonster then
        iconPath, iconBgPath = gModelHero:GetMonsterIcon(refId, quality)
    else
        iconPath, iconBgPath = gModelHero:GetHeroIcon(refId, star, skin, form)
    end

    --防止多语言加载过慢导致显示中文
    self:SetWndEasyImage(tag, "timecopy_txt_1")

    CS.ShowObject(death, itemdata.isDead)
    local isShowDeathTag = gLGameUI:IsVisibleBattleFont()
    if isShowDeathTag then
        self:SetWndEasyImage(deathTag, "timecopy_txt_1")
    end
    CS.ShowObject(deathTag, isShowDeathTag)

    self:SetWndEasyImage(iconBg, iconBgPath)
    self:SetWndEasyImage(icon, iconPath)
    local frame
    if isRight then
        if isFirst then
            frame = "fight_bg_3_3"
        else
            frame = "fight_bg_3_2"
        end
    else
        if isFirst then
            frame = "fight_bg_4_3"
        else
            frame = "fight_bg_4_2"
        end
    end

    self:SetWndEasyImage(iconFrame, frame)
    local size = 10
    --if itemdata.isFirst then
    --	size = 10
    --end

    CS.ShowObject(hightStarNewHeroInfo, star > 10)
    CS.ShowObject(starRoot, star <= 10)
    local list = {}

    if star > 10 then
        local starStr = star - 10
        self:SetWndText(hightStarNewHeroInfoText, starStr)
    else
        local starImg, starNum = LUtil.GetHeroStarImg(star)
        for k = 1, starNum do
            local starTran = self._starItemPool:GetObj()
            self:SetWndEasyImage(starTran, starImg)
            local layout = starTran:GetComponent(typeLayoutElement)
            layout.preferredWidth = size
            layout.preferredHeight = size
            table.insert(list, starTran)
            starTran.localScale = Vector3.New(1, 1, 1)
            starTran:SetParent(starRoot, false)
        end
    end

    self._heroUIList[itempos] = { item = item, itemdata = itemdata, itempos = itempos, startList = list }
end

function UIFight:PlayStartBattleEffect()
    local effectName = "fx_zhandoujinchangtuzi"
    local key = "normalSword"
    local effData = {
        trans = self.mSEffecPos,
        effName = effectName,
        effKey = key,
        onVisibleCall = function(effect, isVisible)
            if not isVisible then
                return
            end
            self:RabbitEffect(effect)
        end,
        bDefaultLayer = true,
        bDefaultSorting = true,
        scale = Vector3.New(640, 640, 640)
    }
    self:CreateWndEffect_Ex(effData)
end

function UIFight:GetSkillIconPos(side, index)
    if not self._skillTranList then
        return Vector3.zero
    end
    local sideList = self._skillTranList[side]
    if not sideList then
        return Vector3.zero
    end

    local tran = sideList[index]
    if not CS.IsValidObject(tran) then
        return Vector3.zero
    end
    local uiCamera = LGameUI.GetUICamera()
    local sceneCamera = gLGameScene:GetCurrentSceneCamera()
    local screenPos = uiCamera:WorldToScreenPoint(tran.position)
    local worldPos = sceneCamera:ScreenToWorldPoint(screenPos)
    return worldPos
end

function UIFight:EndlesAwardListItem(list, item, itemdata, itempos)
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

function UIFight:IsReturnBtnShow()
    local combatType = self._combatType
    local showReturnBtn = self._showReturnBtnTypes[combatType] or false

    --if self._defaultCombatType == LCombatTypeConst.COMBAT_CROSSGRADING_RANK then
    --    local combatExtraData = self._combatExtraData
    --    if combatExtraData then
    --        showReturnBtn = combatExtraData.showReturn or false
    --    end
    --end
    return showReturnBtn
end

function UIFight:RefreshTeamState()
    local isMultlReport = self:IsMultiReport()
    CS.ShowObject(self.mMultiRoot, isMultlReport)
    if not isMultlReport then
        return
    end
    local combatUnitList = gLFightManager:GetCombatUnitList(self._combatType)

    for k, v in pairs(combatUnitList) do
        local teamIndex = k
        local data = {
            isEnd = v:IsEndExecute(),
            isWin = v:IsWin(),
            percentA = v:GetTeamBloodPercent(LFightConst.SIDE_TEAM_A),
            percentB = v:GetTeamBloodPercent(LFightConst.SIDE_TEAM_B),
        }

        self:RefreshTeamStateSingle(data, teamIndex)
    end
end

function UIFight:OnBloodPercentChange(index)
    local battleUnit = gLFightManager:GetBattleByType(self._combatType, index)
    if not battleUnit then
        return
    end

    local data = {
        isEnd = battleUnit:IsEndExecute(),
        isWin = battleUnit:IsWin(),
        percentA = battleUnit:GetTeamBloodPercent(LFightConst.SIDE_TEAM_A),
        percentB = battleUnit:GetTeamBloodPercent(LFightConst.SIDE_TEAM_B),
    }

    self:RefreshTeamStateSingle(data, index)
end

function UIFight:PreparatoryProgressTimerFunc()
    self._preparatoryBar:SetUIProgress(self._targetProgressValue)
end

function UIFight:AddBtnTween(sequence, tran, finalSize)
    if not sequence then
        return
    end
    local large = Vector3(1.5, 1.5, 1.5) -- 大
    local small = Vector3(0.5, 0.5, 0.5) -- 小
    tran.localScale = Vector3.zero
    local tween = tran:DOScale(large, 0.1):SetEase(EaseOutCubic)
    sequence:Append(tween)
    tween = tran:DOScale(small, 0.08):SetEase(EaseOutCubic)
    sequence:Append(tween)
    tween = tran:DOScale(finalSize, 0.05):SetEase(EaseOutCubic)
    sequence:Append(tween)
end

------------------------------------------------------------------
return UIFight