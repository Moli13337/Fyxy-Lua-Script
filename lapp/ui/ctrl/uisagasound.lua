---
--- Created by Administrator.
--- DateTime: 2024/6/20 20:20:34
---
------------------------------------------------------------------
local LWnd = LWnd
local LUISpineSpCtrl = LxRequire("LApp.UI.Display.LUISpineSpCtrl")
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
---@class UISagaSound:LWnd
local UISagaSound = LxWndClass("UISagaSound", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaSound:UISagaSound()
    self.allHeroList = {}
    self.allHeroIndx = {}
    self.allHeroLeng = 0
    self.effectListData = {}
    self.isHide = false
    self.curEffRefId = nil
    self.curEffRefIdIndx = nil
    self.selectItem = nil
    self.isShow = true
    self.tweenTime = 0.4
    self._ActionTimerKey = "_ActionTimerKey"
    self._checkIsPlayingTimerKey = "_checkIsPlayingTimerKey"
   
    --更改初始化
    self.soundKey = gModelHero:GetHerpSpActionSoundKey()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaSound:OnWndClose()
    LUtil.ClearHashTable(self._uiHeroObjList)
    self._uiHeroObjList = nil
    self._curUIHeroObj = nil
    if self.uiSpineSpCtrl then
        self.uiSpineSpCtrl:Destroy()
    end
    self._showTween = nil
    self._hideTween = nil
    self:TimerStop(self._ActionTimerKey)
    self:TimerStop(self._checkIsPlayingTimerKey)
    gLGameAudio:StopSingleSound()
    if self.delayTimer then
        self.delayTimer = nil
        LxTimer.DelayTimeStop(self.delayTimer)
    end
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaSound:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaSound:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self.isCHN = gLGameLanguage:IsChinaRegion()
    self._isVie = gLGameLanguage:IsVieVersion()
    if self._isVie then
        self.mTxtSet.sizeDelta = Vector2.New(100, 0)
        self:InitTextCharacterWithLanguage(self.mTxtSet, 6.8)
        local textTran = LxUiHelper.FindXTextCtrl(self.mTxtSet)
        textTran.enableWordWrapping = true

    end
    self:InitMenber()
    self:InitEvent()
    self:InitText()
    self:InitHeroData()

    self:SetAnchorPos(self.mListHeroObj, Vector2.New(390, 206))
    self:ClickHideShow(self.isShow)
    self:OnUpdateCurHero()
end

function UISagaSound:OnUpdateList()
    table.sort(self.effectListData, function(a, b)
        local aActive = gModelHero:IsActiveHeroEffRefId(a.refId)
        local bActive = gModelHero:IsActiveHeroEffRefId(b.refId)
        local aActive = aActive and 1 or 2
        local bActive = bActive and 1 or 2
        if aActive ~= bActive then
            return aActive < bActive
        else
            return a.refId < b.refId
        end
    end)

    if not self.curEffRefId then
        self.curEffRefIdIndx = 1
        self.curEffRefId = self.effectListData[self.curEffRefIdIndx].refId
    else
        for indx, value in ipairs(self.effectListData or {}) do
            if value.refId == self.curEffRefId then
                self.curEffRefIdIndx = indx
                break
            end
        end
        if not self.curEffRefIdIndx then
            self.curEffRefIdIndx = 1
            self.curEffRefId = self.effectListData[self.curEffRefIdIndx].refId
        end
    end
    self:UpdateSoundList()
    self:UpdateSkinName()
    CS.ShowObject(self.mListHero, #self.effectListData > 1)
    if #self.effectListData <= 1 then
        return
    end
    if (not self._uiList) then
        self._uiList = self:GetUIScroll("IconList")
        self._uiList:Create(self.mListHero, self.effectListData, function(...)
            self:ListItem(...)
        end, UIItemList.WRAP)
    else
        self._uiList:RefreshList(self.effectListData)
    end
end

function UISagaSound:CheckSingleIsPlaying()
    if self._checkSingleTime >= 1 then
        CS.ShowObject(self.ImgHorn1, false)
        CS.ShowObject(self.ImgHorn0, false)
        self._checkSingleTime = 0
        return
    end
    local logicIsPlaying = self._isPlayVoiceId ~= nil
    local isPlaying = gLGameAudio:IsSingleSoundPlaying()
    self.countTime = self.countTime + 1
    if self.countTime == 1 then
        CS.ShowObject(self.ImgHorn0, true)
    end
    if self.countTime == 2 then
        CS.ShowObject(self.ImgHorn1, true)
    end
    if self.countTime == 3 and self._isPlayVoiceId then
        CS.ShowObject(self.ImgHorn0, false)
        CS.ShowObject(self.ImgHorn1, false)
        self.countTime = 0
    end
    if not logicIsPlaying then
        self:TimerStop(self._checkIsPlayingTimerKey)
        self:ShowSoundDes()
        CS.ShowObject(self.ImgHorn0, true)
        CS.ShowObject(self.ImgHorn1, true)
    end
    if not isPlaying then
        self:TimerStop(self._checkIsPlayingTimerKey)
        self:ShowSoundDes()
        CS.ShowObject(self.ImgHorn0, true)
        CS.ShowObject(self.ImgHorn1, true)
    end
end

function UISagaSound:OnPlayIdle(action)
    if action and action == "idle" then
        self.delayTimer = LxTimer.DelayTimeCall(function()
            CS.ShowObject(self.mItemTips, false)
            LxTimer.DelayTimeStop(self.delayTimer)
            self.delayTimer = nil
        end, 4)
    end
end

function UISagaSound:UpdateSoundList()
    local effCfg = gModelHero:GetShowEffectById(self.curEffRefId)
    local favorRefs = gModelHero:GetHeroSpActionSoundRef()
    local heroRefId = effCfg.heroType
    self.heroLove = gModelHero:GetHeroLoveLvByRefId(heroRefId) or 0
    local list = {}
    for _, v in ipairs(self.soundKey) do
        if not string.isempty(effCfg[v.key]) then
            local sounds = string.split(effCfg[v.key], ";")
            local s = ccLngText(effCfg[v.desKey])
            local des = string.split(s, ";")

            local tempData = favorRefs[v.key]
            if tempData then
                local soundName = favorRefs[v.key].text2
                local lvl = favorRefs[v.key].refId
                for i = 1, #sounds do
                    table.insert(list, {
                        sound = sounds[i],
                        des = des[i] or "",
                        soundName = soundName,
                        lvl = lvl
                    })
                end
            end

        end
    end

    if not self.soundList then
        self.soundList = self:GetUIScroll("SoundList")
        self.soundList:Create(self.mSoundList, list, function(...)
            self:DrawSound(...)
        end, UIItemList.SUPER_GRID)
    else
        self.soundList:ResetList(list)
        self.soundList:DrawAllItems()
    end
end

------------------------------------------------------------------
---Init
function UISagaSound:InitMenber()
    self.initSpinePos = self.mHeroLiHuiPos.anchoredPosition
    self.uiSpineSpCtrl = LUISpineSpCtrl:New()
end

function UISagaSound:DrawSound(_, item, data)
    local soundImg1 = self:FindWndTrans(item, "SoundImg1")
    local soundImg2 = self:FindWndTrans(item, "SoundImg2")
    local lock = self:FindWndTrans(item, "Lock")
    local lockText = self:FindWndTrans(lock, "Text")
    local lockNumText = self:FindWndTrans(lock, "NumText")
    local unlock = self:FindWndTrans(item, "UnLock")
    local isLock = self.heroLove < data.lvl
    CS.ShowObject(lock, isLock)
    CS.ShowObject(unlock, not isLock)
    if isLock then
        self:SetWndText(lockText, ccClientText(41668))
        self:SetWndText(lockNumText, data.lvl)
    else
        self:SetWndText(unlock, ccLngText(data.soundName))
    end

    self:SetWndClick(item, function()
        if isLock then
            return
        end
        local old = self._isPlayVoiceId ~= nil and self._isPlayVoiceId
        if old then
            gLGameAudio:StopSingleSound();
            self:ShowSoundDes()
            self._isPlayVoiceId = nil
            self:TimerStop(self._checkIsPlayingTimerKey)
            CS.ShowObject(self.ImgHorn0, true)
            CS.ShowObject(self.ImgHorn1, true)
            if old == data.sound then
                return
            end
        end

        local isMute = gLGameAudio:IsSingleSoundMute() or gLGameAudio:GetSingleSoundVolume() <= 0
        if isMute then
            GF.ShowMessage(ccClientText(19785))
            return
        end
        self.isClickSound = true
        self._isPlayVoiceId = data.sound
        self._checkSingleTime = 1
        gLGameAudio:PlaySingleSound(data.sound, function()
            if self:IsWndClosed() then
                gLGameAudio:StopSingleSound();
                CS.ShowObject(self.ImgHorn0, true)
                CS.ShowObject(self.ImgHorn1, true)
                return
            end
            self.ImgHorn0 = soundImg1
            self.ImgHorn1 = soundImg2
            self.countTime = 0
            self:ShowSoundDes(data.des)
            self:TimerStart(self._checkIsPlayingTimerKey, 0.4, false, -1)
        end)
        printInfoNR2("播放音乐", data.sound)
    end)
end

function UISagaSound:isLove(isTip)
    local curHeroRefId = GameTable.CharacterEffectRef[self.curEffRefId].heroType
    local favor = GameTable.CharacterRef[curHeroRefId].maxFavorability
    local isOpen = true
    if not favor or favor <= 0 then
        isOpen = false
    end
    isOpen = isOpen and gModelHero:IsActiveHeroEffRefId(curHeroRefId)
    if not isOpen and isTip then
        GF.ShowMessage(ccClientText(41669))
    end
    return isOpen
end

function UISagaSound:OnTimer(key)
    if self._checkIsPlayingTimerKey == key then
        self:CheckSingleIsPlaying()
    end
end

function UISagaSound:InitText()
    self:SetWndText(self.mTxtReturn, ccClientText(30205))
    self:SetWndText(self.mTxtHideShow, self.isHide and ccClientText(41304) or ccClientText(41300))
    self:SetWndText(self.mTxtSet, ccClientText(41318))
    self:SetWndText(self.mTxtLoveTitle, ccClientText(41302))
    self:SetWndText(self.mReturnTxt, ccClientText(42010))
end

function UISagaSound:CreateLiHui()
    local effectRef = gModelHero:GetShowEffectById(self.curEffRefId)
    local heroRefId = effectRef.heroType
    local loveLevel = gModelHero:GetHeroLoveLvByRefId(heroRefId)
    self:SetWndText(self.mTxtLove, loveLevel or 0)
    local effectRef = gModelHero:GetShowEffectById(self.curEffRefId)
    if not effectRef then
        return
    end

    local uiHeroObjList = self._uiHeroObjList
    if not uiHeroObjList then
        uiHeroObjList = {}
        self._uiHeroObjList = uiHeroObjList
    end

    local heroDrawing = effectRef.heroDrawing

    ---@type LUIHeroObject
    local newUILiHuiObj = uiHeroObjList[heroDrawing]

    ---@type LUIHeroObject
    local oldUIHeroObj = self._curUIHeroObj
    if oldUIHeroObj and newUILiHuiObj ~= oldUIHeroObj then
        oldUIHeroObj:ShowHero(false)
    end

    if newUILiHuiObj then
        newUILiHuiObj:ShowHero(true)
    else
        newUILiHuiObj = LUIHeroObject:New(self)
        uiHeroObjList[heroDrawing] = newUILiHuiObj
        newUILiHuiObj:Create(self.mHeroLiHuiPos, heroDrawing, heroDrawing)
        newUILiHuiObj:SetHeroBgParams({
            effRef = effectRef,
            lihuiBgTrans = self.mHeroLiHuiBgPos,
            lihuiHdTrans = self.mHeroLiHuiHdPos,
        })
        newUILiHuiObj:ShowHero(true)
        newUILiHuiObj:SetLoadedFunction(function()
            newUILiHuiObj:PlayIdleAni()
            CS.ShowObject(self.mHeroLiHuiPos, true)
        end)
        newUILiHuiObj:SetClickFunc(function()
            local action = gModelHero:GetHeroClickAction(self.curEffRefId)
            if action and action ~= "" then
                newUILiHuiObj:PlayAni(action, false, nil, nil, true)
            end

            local actionSound = gModelHero:GetHeroClickSound(self.curEffRefId)
            if actionSound and actionSound ~= "" then
                gLGameAudio:PlaySingleSound(actionSound)
            end
            self:OnPlayIdle(action)
        end)
        newUILiHuiObj:SetRectMatch(true)
        newUILiHuiObj:StartLoad()
    end
    self._curUIHeroObj = newUILiHuiObj
end

function UISagaSound:UpdateLoveLevel()
    local effectRef = gModelHero:GetShowEffectById(self.curEffRefId)
    local heroRefId = effectRef.heroType
    local loveLevel = gModelHero:GetHeroLoveLvByRefId(heroRefId)
    self:SetWndText(self.mTxtLove, loveLevel or 0)
end

function UISagaSound:ListItem(_, item, itemdata, itempos)
    local IconBg = CS.FindTrans(item, "IconBg")
    local ImgIcon = CS.FindTrans(item, "ImgIcon")
    local ImgMask = CS.FindTrans(item, "ImgMask")
    local ImgSelect = CS.FindTrans(item, "ImgSelect")

    local effRef = GameTable.CharacterEffectRef[itemdata.refId]
    local qualityBg = "public_item_bg_" .. (itemdata.quality or 0)
    self:SetWndEasyImage(IconBg, qualityBg)
    self:SetWndEasyImage(ImgIcon, effRef.icon)
    CS.ShowObject(ImgSelect, self.curEffRefId == itemdata.refId)
    local notActive = not gModelHero:IsActiveHeroEffRefId(itemdata.refId)

    CS.ShowObject(ImgMask, notActive)
    if self.curEffRefId == itemdata.refId then
        self.selectItem = item
        self.curEffRefIdIndx = itempos
    end
    self:SetWndClick(item, function()
        if notActive then
            if effRef.skinType <= 1 and (not effRef.needStar or effRef.needStar <= 1) then
                --1阶
                GF.ShowMessage(string.replace(ccClientText(41319), ccLngText(effRef.name)))
            elseif effRef.skinType == 2 then
                if not effRef.needStar or effRef.needStar <= 0 then
                    GF.ShowMessage(string.replace(ccClientText(41319), ccLngText(effRef.skinName)))
                else
                    local star = string.replace(ccClientText(41637), effRef.needStar)
                    GF.ShowMessage(string.replace(ccClientText(41319), star .. ccLngText(effRef.name)))
                end
            end
            return
        end
        if self.curEffRefId == itemdata.refId then
            return
        end
        gLGameAudio:StopSingleSound()
        self:OnClickIcon(item, itemdata, itempos)
    end)
end

function UISagaSound:OnUpdateSkinList()
    local heroRefId = GameTable.CharacterEffectRef[self.curEffRefId].heroType
    local list = gModelHero:GetHeroEffectList2ByRefId(heroRefId) or {}
    table.sort(list,function(a,b) return a.sort<b.sort end)
    local roleRef
    self.effectListData = {}
    for _, v in ipairs(list) do
        if not roleRef then
            if not string.isempty(v.RoleRef) then
                roleRef = v.RoleRef
                table.insert(self.effectListData, v)
            end
        else
            if roleRef ~= v.RoleRef and not string.isempty(v.RoleRef) then
                roleRef = v.RoleRef
                table.insert(self.effectListData, v)
            end
        end
    end
end

function UISagaSound:PlayHideTween()
    local tweenSeq = YXTween.TweenSequenceIns()
    local moveFunc = function(value)
        self:SetAnchorPos(self.mBtnSet, Vector2.New(46, -65 + value))
        if gLGameLanguage:IsJapanVersion() then
            self:SetAnchorPos(self.mBtnSet, Vector2.New(80, -65 + value))
        end
        self:SetAnchorPos(self.mImgLove, Vector2.New(238, 57 - value))
        self:SetAnchorPos(self.mReturnBtn, Vector2.New(69.4, 61.7 - value))
        -- if LxUnity.IsShowObject(self.mListHero) then
        self:SetAnchorPos(self.mListHeroObj, Vector2.New(-62 + value, -318))
        self:SetAnchorPos(self.mSound, Vector2.New(0, 100 - (value * 4)))
        -- end
    end
    local moveTween = YXTween.TweenFloat(0, 160, self.tweenTime, moveFunc):SetEase(DG.Tweening.Ease.InSine)
    tweenSeq:Append(moveTween)
    tweenSeq:OnComplete(function()
        self._hideTween = nil
        CS.ShowObject(self.mBtnSet, false)
        CS.ShowObject(self.mImgLove, false)
    end)
    self._hideTween = tweenSeq
    tweenSeq:PlayForward()
end

------------------------------------------------------------------
---click
function UISagaSound:ClickHideShow(setState)
    self.isShow = setState
    self:FoldDoTween(self.isShow)
    if self.isShow then
        self:PlayShowTween()
    else
        self:PlayHideTween()
    end
end

function UISagaSound:OnClickIcon(item, itemdata, index)
    self:ResetUISpineSpCtrl()
    local oldItem = self.selectItem
    if oldItem then
        local oldSelect = CS.FindTrans(oldItem, "ImgSelect")
        CS.ShowObject(oldSelect, false)
    end
    self.curEffRefIdIndx = index
    self.curEffRefId = itemdata.refId
    if item then
        self.selectItem = item
        local ImgSelect = CS.FindTrans(item, "ImgSelect")
        CS.ShowObject(ImgSelect, true)
    end
    CS.ShowObject(self.mBtnSet, gModelHero._gardenShowHeroEffRefId ~= self.curEffRefId)
    self:CreateLiHui()
    print("389012839012839012830912 ")
    self:UpdateSoundList()
    self:UpdateSkinName()
end

function UISagaSound:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:ResetUISpineSpCtrl()
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnHideShow, function()
        self:ClickHideShow(not self.isShow)
    end)
    self:SetWndClick(self.mImgLove, function()
        if not self:isLove(true) then
            return
        end
        self:ResetUISpineSpCtrl()
        gLGameAudio:StopSingleSound()
        local heroRefId = GameTable.CharacterEffectRef[self.curEffRefId].heroType
        gModelGeneral:OpenHeroStarPre({ refId = heroRefId, showTab = true, selectIndex = 5 })
    end)
    self:SetWndClick(self.mCurLeftBtn, function()
        self:OnUpdateCurHero(-1)
    end)
    self:SetWndClick(self.mCurRightBtn, function()
        self:OnUpdateCurHero(1)
    end)
    self:SetWndClick(self.mBtnSet, function()
        gModelHeroExtra:OnHeroSetShowReq(self.curEffRefId)
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_SPINE_UPDATE, function()
        CS.ShowObject(self.mBtnSet, gModelHero._gardenShowHeroEffRefId ~= self.curEffRefId)
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_LOVE_UPLV, function()
        self:OnUpdateCurHero()
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_EXP_UPDATE, function()
        self:UpdateLoveLevel()
    end)
end

function UISagaSound:ShowSoundDes(des)
    if  self.isCHN then
        return
    end
    if des and not string.isempty(des) then
        self:SetWndText(self.mTranText, ccLngText(des))
        LxTimer.DelayTimeCall(function()
            local height = self:GetWndTextPreferHeight(self.mTranText)
            local initHeight = 112
            local initPosY = 116
            local offsetY = -52
            LxUiHelper.SetSizeWithCurAnchor(self.mTranObj, 1, initHeight + height + offsetY)
            self:SetAnchorPos(self.mTranObj, Vector2.New(0, initPosY + height + offsetY))
            CS.ShowObject(self.mTranObj, true)
        end, 0.2)
    else
        CS.ShowObject(self.mTranObj, false)
    end
    if des and not string.isempty(des) then
        self:SetWndText(self.mTranText, ccLngText(des))
        LxTimer.DelayTimeCall(function()
            local height = self:GetWndTextPreferHeight(self.mTranText)
            local initHeight = 112
            local initPosY = 116
            local offsetY = -52
            LxUiHelper.SetSizeWithCurAnchor(self.mTranObj, 1, initHeight + height + offsetY)
            self:SetAnchorPos(self.mTranObj, Vector2.New(0, initPosY + height + offsetY))
            CS.ShowObject(self.mTranObj, true)
        end, 0.2)
    else
        CS.ShowObject(self.mTranObj, false)
    end

end

function UISagaSound:UpdateSkinName()
    local effCfg = gModelHero:GetShowEffectById(self.curEffRefId)
    local s = effCfg.skinType == 2 and effCfg.skinName or effCfg.name
    local cvName = string.isempty(effCfg.cvName) and "" or "Cv." .. ccLngText(effCfg.cvName)
    self:SetWndText(self.mSkinName, ccLngText(s))
    self:SetWndText(self.mCVName, cvName)
end

------------------------------------------------------------------
---handle
function UISagaSound:ResetUISpineSpCtrl()
    if not self.uiSpineSpCtrl then
        return
    end
    self.uiSpineSpCtrl:ResetUI()
end

function UISagaSound:PlayShowTween()
    local tweenSeq = YXTween.TweenSequenceIns()
    CS.ShowObject(self.mBtnSet, true)
    CS.ShowObject(self.mImgLove, true)
    CS.ShowObject(self.mBtnSet, gModelHero._gardenShowHeroEffRefId ~= self.curEffRefId)
    local moveFunc = function(value)
        self:SetAnchorPos(self.mBtnSet, Vector2.New(46, 95 - value))
        if gLGameLanguage:IsJapanVersion() then
            self:SetAnchorPos(self.mBtnSet, Vector2.New(80, 95 - value))
        end
        self:SetAnchorPos(self.mImgLove, Vector2.New(238, -100 + value))
        self:SetAnchorPos(self.mReturnBtn, Vector2.New(69.4, -98.3 + value))
        -- if LxUnity.IsShowObject(self.mListHero) then
        self:SetAnchorPos(self.mListHeroObj, Vector2.New(98 - value, -318))
        self:SetAnchorPos(self.mSound, Vector2.New(0, -540 + (value * 4)))
        -- end
    end
    local moveTween = YXTween.TweenFloat(0, 160, self.tweenTime, moveFunc):SetEase(DG.Tweening.Ease.InSine)
    tweenSeq:Append(moveTween)
    tweenSeq:OnComplete(function()
        self._showTween = nil
    end)
    self._showTween = tweenSeq
    tweenSeq:PlayForward()
end

function UISagaSound:FoldDoTween(isShow)
    local tweenSeq = YXTween.TweenSequenceIns()
    local moveTween = self.mBtnHideShow:DOLocalRotate(Vector3.New(0, 0, isShow and 0 or 180), self.tweenTime):SetEase(DG.Tweening.Ease.InSine)
    tweenSeq:Append(moveTween)
    tweenSeq:OnComplete(function()
        self.foldTween = nil
        self:SetWndText(self.mTxtHideShow, self.isShow and ccClientText(41300) or ccClientText(41304))
    end)
    self.foldTween = tweenSeq
    tweenSeq:PlayForward()
end

function UISagaSound:InitHeroData()
    self.curEffRefId = self:GetWndArg("heroRefId") --英雄id或表现id
    local allListData = {}
    local refs = GameTable.CharacterRef
    local curTime = GetTimestamp()
    for _, v in pairs(refs) do
        -- if v.maxFavorability and v.maxFavorability > 0 then
        local effCfg = gModelHero:GetShowEffectById(v.refId)
        if not string.isempty(effCfg.RoleRef) and gModelHero:GetHeroActShowState(v.refId, curTime) then
            table.insert(allListData, v)
        end
        -- end
    end
    table.sort(allListData, function(a, b)
        local aActive = gModelHero:IsActiveHeroEffRefId(a.refId) and 1 or 2
        local bActive = gModelHero:IsActiveHeroEffRefId(b.refId) and 1 or 2
        if aActive ~= bActive then
            return aActive < bActive
        else
            if a.quality ~= b.quality then
                return a.quality > b.quality
            else
                return a.refId < b.refId
            end
        end
    end)
    self.allHeroList = allListData
    self.allHeroLeng = #allListData
    self.allHeroIndx = {}
    for i, v in ipairs(allListData) do
        self.allHeroIndx[v.refId] = i
    end
end

function UISagaSound:OnUpdateCurHero(num)
    self:ResetUISpineSpCtrl()
    local curHeroRefId = GameTable.CharacterEffectRef[self.curEffRefId].heroType
    local curHeroIndx = self.allHeroIndx[curHeroRefId]
    local newHeroIndx = curHeroIndx
    if num then
        newHeroIndx = curHeroIndx + num
        local nexHeroRef = self.allHeroList[newHeroIndx]
        self.curEffRefId = nexHeroRef.refId
    end
    gLGameAudio:StopSingleSound()
    local nexHeroIndx = newHeroIndx + 1
    local nexHeroRef = self.allHeroList[nexHeroIndx]
    local nexHero = nexHeroRef
    self:OnUpdateSkinList()
    self:OnUpdateList()
    self:CreateLiHui()
    CS.ShowObject(self.mCurLeftBtn, newHeroIndx > 1)
    CS.ShowObject(self.mCurRightBtn, newHeroIndx < self.allHeroLeng and nexHero)
    local effectRef = GameTable.CharacterEffectRef[self.curEffRefId]
    local isActive = gModelHero:IsActiveHeroEffRefId(self.curEffRefId)
    CS.ShowObject(self.mBtnSet, gModelHero._gardenShowHeroEffRefId ~= self.curEffRefId and isActive)
    local imgPath = not string.isempty(effectRef.skinBg) and effectRef.skinBg or effectRef.heroBg
    self:SetWndEasyImage(self.mHeroBookImg, imgPath)
    self:SetWndImageGray(self.mImgLove, not self:isLove())
end

------------------------------------------------------------------
return UISagaSound