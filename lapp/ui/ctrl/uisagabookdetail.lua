---
--- Created by Administrator.
--- DateTime: 2023/10/22 16:03:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaBookDetail:LWnd
local UISagaBookDetail = LxWndClass("UISagaBookDetail", LWnd)
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
local typeofRenderer = typeof(UnityEngine.Renderer)
local Time = Time
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUISkillCtrl = LxRequire("LApp.UI.Display.LUISkillCtrl")
local LUIDrawingCtrl = LxRequire("LApp.UI.Display.LUIDrawingCtrl")
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local typeofCanvas = typeof(UnityEngine.Canvas)
local YXUIPointUtil = CS.YXUIPointUtil
local typeSpineClick = typeof(CS.SpineClick)

UISagaBookDetail.BASE_KEY_LIST = {
    LAttrConst.Atk,
    LAttrConst.MaxHP,
    LAttrConst.Def,
    LAttrConst.Speed,

}

UISagaBookDetail.Spine_Scale = 1

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaBookDetail:UISagaBookDetail()
    self._effectKey = "_effectKey"
    self._checkIsPlayingTimerKey = "_checkIsPlayingTimerKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaBookDetail:OnWndClose()
    self.ImgHorn0 = nil
    self.ImgHorn1 = nil

    if self._uiDrawingCtrl then
        self._uiDrawingCtrl:Destroy()
        self._uiDrawingCtrl = nil
    end

    LUtil.ClearHashTable(self._uiHeroLiHuiList)
    self._uiHeroLiHuiList = nil
    self._curUILiHuiObj = nil

    LUtil.ClearHashTable(self._hightStateHeroLihui)
    self._hightStateHeroLihui = nil
    self._curHightUIObj = nil

    self:ClearCommonIconList(self._uiCommonList)
    self._uiCommonList = nil
    self:TweenSeqKill("upSeq")
    self:TimerStop(self._checkIsPlayingTimerKey)
    gLGameAudio:StopSingleSound();
    if self._delayCloseTimer then
        LxTimer.DelayTimeStop(self._delayCloseTimer)
        self._delayCloseTimer = nil
    end
    self:ClearTween()
    self._rendererList = nil
    self._heroHightStates = {}
    self._curHightStateIndex = 1
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaBookDetail:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaBookDetail:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isShow = true
    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self._isJapaness  =gLGameLanguage:IsJapanVersion()
    self:InitData()
    self:SetStaicContent()
    self:InitMsg()
    self:InitEvent()
    self:InitCommon()
    -- self:InitLoveLvOrder()
    self:RefreshVersionShow()
end
function UISagaBookDetail:InitLoveLvOrder()
    local canvas = self.mTxtTotalLv:GetComponent(typeofCanvas)
    if not canvas then
        canvas = self.mTxtTotalLv.gameObject:AddComponent(typeofCanvas)
    end
    local canvasG5 = self.mG5:GetComponent(typeofCanvas)
    local orderG5 = canvasG5 and canvasG5.sortingOrder or self:GetWndSortOrder()
    canvas.overrideSorting = true
    canvas.sortingLayerName = self:GetWndSortLayer()
    canvas.sortingOrder = orderG5 + 3
end

function UISagaBookDetail:CheckQMJDCanUp(refId)
    local isUp = gModelHeroBook:ShowHeroCloseWnd(refId)
    if isUp ~= nil then
        self:PlayEffShow(isUp)
    end
    --self:PlayEffShow(20)
end

function UISagaBookDetail:ChangeShowOrHideBtnState()
    self.mButton_ShowOrHide.localScale = self._isShow and Vector3.New(1, 1, 1) or Vector3.New(1, -1, 1)
    --local str = self._isShow and "收起" or "展开"
    local str = self._isShow and ccClientText(20215) or ccClientText(20214)
    self:SetWndText(self.mShowOrHide_Text, str)
end
function UISagaBookDetail:OnUpdateProgressTxt()
    local loveLevel = gModelHero:GetHeroLoveLvByRefId(self._heroRefId)
    local curLv = loveLevel or 0
    local nexRef = GameTable.CharacterFavorabilityRef[curLv + 1]
    local nextLvExp = nexRef and nexRef.exp or GameTable.CharacterFavorabilityRef[curLv].exp
    local add = ""
    if self.selectGift then
        local typeDate = GameTable.PlayerItemRef[self.selectGift].typeDate or ""
        local loves = string.split(typeDate, ",")
        if loves and loves[1] then
            add = string.replace("<color=#139056>(+#a1#~#a2#)</color>", loves[1], loves[2])
        end
    end
    local curValue = gModelHero:GetHeroLoveExpByRefId(self._heroRefId) or 0
    self:SetWndText(self.mTxtProgress, curValue .. "/" .. nextLvExp .. add)
    self.mSlider.value = (nexRef and curValue or nextLvExp) / nextLvExp
end

function UISagaBookDetail:OnDrawTab(list, item, itemData, index)

    local name = ccClientText(itemData.name)
    self:SetWndTabText(item, name, nil, true)
    self:SetWndTabStatus(item, 1)
    self._tabList[index] = item
    self:SetWndClick(item, function(...)
        self:OnClickTab(index)
    end)

    local offTrans = CS.FindTrans(item, "Off")
    local onTrans = CS.FindTrans(item, "On")
    self:SetWndEasyImage(offTrans, itemData.offIcon)
    self:SetWndEasyImage(onTrans, itemData.onIcon)
    if itemData.indexId == 5 then
        local redpoit = self:FindWndTrans(item, "redPoint")
        -- CS.ShowObject(redpoit,gModelHeroBook:GetFavorabilityGiftRed(self._heroRefId))
        CS.ShowObject(redpoit, gModelHero:GetFavorabilityGiftRed(self._heroRefId))
    end

end

function UISagaBookDetail:UpdateInteractBtnRed()
    local heroRefId = GameTable.CharacterEffectRef[self._heroRefId].heroType
    local effectList = gModelHero:GetHeroEffectListByRefId(heroRefId) or {}
    local redImg = self:FindWndTrans(self.mHBInteractBtn, "RedPoint")
    for i, v in pairs(effectList) do
        local show = gModelHero:GetFavorabilityInteractRed(v.refId, true) or gModelHero:GetFavorabilityInteractRed(v.refId)
        if show then
            CS.ShowObject(redImg, show)
            return
        end
    end
    CS.ShowObject(redImg, false)
end

function UISagaBookDetail:SetRewardIsShow()
    local serverData = gModelHeroBook:GetHeroInfoByHeroRefId(self._heroRefId)
    if not serverData then
        return
    end
    local isActive = serverData.isActive
    --是否显示钻石
    local rewardStoryData = nil
    for k, v in pairs(self._storyData) do
        local got = serverData.storyRewardsKey[v.refId] ~= nil
        local islock = true

        if serverData.heroMaxStar then
            islock = serverData.heroMaxStar >= v.needStar
        end

        rewardStoryData = v

        if not got and not string.isempty(v.reward) then
            -- 未领取的
            break
        end
        if not islock then
            --未达到亲密度的
            break
        end
    end

    local rewardData = rewardStoryData and rewardStoryData.reward
    local got = rewardStoryData and serverData.storyRewardsKey[rewardStoryData.refId] ~= nil
    local showReward = not string.isempty(rewardData) and isActive and not got
    local rewardItem = self.mReward
    CS.ShowObject(rewardItem, showReward)
    CS.ShowObject(self.mRewardGet, showReward)
    CS.ShowObject(self.mRewardRedPoint, showReward)
end

function UISagaBookDetail:InitEvent()
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end)

    -- self:SetWndClick(self.mTab1, function()
    --     self:OnClickTab(1)
    -- end)

    -- self:SetWndClick(self.mTab2, function()
    --     self:OnClickTab(2)
    -- end)

    -- self:SetWndClick(self.mTabVoice, function()
    --     self:OnClickTab(3)
    -- end)

    -- self:SetWndClick(self.mTab4, function()
    --     self:OnClickTab(4)
    -- end)

    self:SetWndClick(self.mCurLeftBtn, function()
        self:CutHero(1)
    end)
    self:SetWndClick(self.mCurRightBtn, function()
        self:CutHero(-1)
    end)

    self:SetWndClick(self.mStoryRightBtn, function()

        if self._storyIndex < #self._storyData then
            self._storyIndex = self._storyIndex + 1
            self:UpdateStory()
        end
    end)

    self:SetWndClick(self.mStoryLeftBtn, function()

        if self._storyIndex > 1 then
            self._storyIndex = self._storyIndex - 1
            self:UpdateStory()
        end
    end)

    self:SetWndClick(self.mStoryBtn, function()


        GF.OpenWndUp("UISagaBookSyPop", { heroRefId = self._heroRefId, index = self._storyIndex })
    end)
    self:SetWndClick(self.mAwakeBtn, function()
        self._showAwaken = true
        self:RefreshStarPage()
    end)

    self:SetWndClick(self.mShiftUpStarBtn, function()
        self._showAwaken = false
        self:RefreshStarPage()
    end)

    self:SetWndClick(self.mHeroRaceImg, function()
        CS.ShowObject(self.mTypeImgMask, true)
        self:ShowRaecKeZhiInfo()
    end)

    self:SetWndClick(self.mTypeImgMask, function()
        CS.ShowObject(self.mTypeImgMask, false)
    end)
    self:SetWndClick(self.mQualityImg, function()
        GF.OpenWndTop("UISagaQualitySow")
    end)

    self:SetWndClick(self.mButton_Right, function()
        if not self._curHightStateIndex then
            return
        end
        if self._curHightStateIndex >= #self._heroHightStates then
            self._curHightStateIndex = #self._heroHightStates
        else
            self._curHightStateIndex = self._curHightStateIndex + 1
        end

        self:RefreshHightStateView()
    end)

    self:SetWndClick(self.mButton_Left, function()
        if self._curHightStateIndex == 1 then
            self._curHightStateIndex = 1
        else
            self._curHightStateIndex = self._curHightStateIndex - 1
        end
        self:RefreshHightStateView()
    end)

    self:SetWndClick(self.mButton_ShowOrHide, function()
        if self._isShow then
            self:PlayHideTween()
        else
            self:PlayShowTween()
        end

        self._isShow = not self._isShow

        self:ChangeShowOrHideBtnState()
    end)

    self:SetWndClick(self.mBtnGift, function()
        self:UseGiveGift()
    end)
    self:SetWndClick(self.mBtnOneGift, function()
        self:OneUseGiveGift()
    end)
    self:SetWndClick(self.mItemLove, function()
        GF.OpenWnd("UIFavorabilityAttr")
    end)

    self:SetWndClick(self.mHBHeroTreeBtn, function()
        GF.OpenWnd("UISagaAwakenAttr", {
            isPre = true,
            preHeroRefId = self._heroRefId
        })
    end)
    self:SetWndClick(self.mSoundBtn, function()
        self:ClickSoundBtn()
    end)
    self:SetWndClick(self.mHBShopBtn, function()
        GF.OpenWnd("UIDian", { shopId = 1007 })
    end)

    self:SetWndClick(self.mGuideRoot, function()
        if self._curUILiHuiObj and self._curUILiHuiObj:IsDpValid() then
            self._curUILiHuiObj:OnHeroClick()
        end
    end)
end

function UISagaBookDetail:CreateStarList(star)
    local list = {}
    local img, showNum = gModelHero:GetHeroStarImg(star)
    for i = 1, showNum do
        table.insert(list, {
            show = true,
            img = img
        })
    end
    local uiStarList = self._uiStarList
    if uiStarList then
        uiStarList:RefreshList(list)
    else
        uiStarList = self:GetUIScroll("uiStarList")
        self._uiStarList = uiStarList
        uiStarList:Create(self.mStarList, list, function(...)
            self:OnDrawStarCell1(...)
        end)
    end
end

function UISagaBookDetail:OnDrawAwakenAttrCell(list, item, itemdata, itempos)
    local AttrIcon = self:FindWndTrans(item, "AttrIcon")
    local AttrName = self:FindWndTrans(item, "AttrName")
    local AttrValue = self:FindWndTrans(item, "AttrValue")
    local NextAttrValue = self:FindWndTrans(item, "NextAttrValue")
    local refId, type, value, nextValue = itemdata.refId, itemdata.type, itemdata.value, itemdata.nextValue

    local icon = gModelHero:GetAttributeIconById(refId)
    self:SetWndEasyImage(AttrIcon, icon, function()
        CS.ShowObject(AttrIcon, true)
    end)

    local name = gModelHero:GetAttributeNameById(refId)
    self:SetWndText(AttrName, name)

    local val = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, type, value)
    local haveNextValue = nextValue and nextValue > 0
    local addVal = ""
    local addStrColor = haveNextValue and "lightGreen" or "yellow_2"
    if haveNextValue then
        val = "+" .. val
        addVal = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, type, nextValue)
    else
        addVal = val
        val = ""
    end

    self:SetWndText(AttrValue, val)

    addVal = LUtil.FormatColorStr("+" .. addVal, addStrColor)
    self:SetWndText(NextAttrValue, addVal)

end

function UISagaBookDetail:RefreshHightStateView()
    local curCfgRefId = self._heroHightStates[self._curHightStateIndex]
    local curEffectRef = gModelHero:GetShowEffectById(curCfgRefId.refId)

    --设置名字
    --self:SetWndText(self.mSkinName, ccLngText(curEffectRef.nickName))
    self:SetWndText(self.mSkinName, ccLngText(curEffectRef.skinName))
    CS.ShowObject(self.mBgL, false)
    CS.ShowObject(self.mBgR, false)
    CS.ShowObject(self.mUnLockConditionDesBg, false)


    --判断是不是激活过乐
    local skinData = gModelHero:GetHeroSkinInfoByRefId(curCfgRefId.refId)
    local ishasskin = false
    if skinData then
        local numEndTime = tonumber(skinData.endTime)
        ishasskin = numEndTime == -1
    end

    local ishaveDes = true
    if curEffectRef.needStar and curEffectRef.needStar > 0 then
        CS.ShowObject(self.mUnLockConditionDesBg, not ishasskin)
        self:SetWndText(self.mUnLockConditionDes, string.replace(ccClientText(17430), curEffectRef.needStar))
    else
        self:SetWndText(self.mUnLockConditionDes, "")
        ishaveDes = false
    end
    local showUnLockDesBg = not ishasskin and ishaveDes
    CS.ShowObject(self.mUnLockConditionDesBg, showUnLockDesBg)
    self:SetHightStateHeroLihui(curCfgRefId.refId, showUnLockDesBg)
end

function UISagaBookDetail:SetAwakenPointEffShow(isShow, effName, pointTrans)
    local InstanceID = pointTrans:GetInstanceID()
    local effKey = effName .. InstanceID
    if isShow then
        self:CreateWndEffect(pointTrans, effName, effKey, 100, false, false, 26)
    else
        self:DestroyWndEffectByKey(effKey)
    end
end

function UISagaBookDetail:OnDrawAttrCell(list, item, itemdata, itempos)

    local AttrIconTrans = self:FindWndTrans(item, "AttrIcon")
    local AttrNameTrans = self:FindWndTrans(item, "AttrName")
    local AttrValueTrans = self:FindWndTrans(item, "AttrValue")
    local refId, numType, value, saveNum = itemdata.refId, itemdata.numType, itemdata.value, itemdata.saveNum

    if AttrIconTrans then
        local icon = gModelHero:GetAttributeIconById(refId)

        self:SetWndEasyImage(AttrIconTrans, icon, function()

            CS.ShowObject(AttrIconTrans, true)
        end)
    end
    if AttrNameTrans then
        local name = gModelHero:GetAttributeNameById(refId)
        self:SetWndText(AttrNameTrans, name)
    end
    if AttrValueTrans then
        if saveNum == 0 then
            value = math.floor(value + 0.5)
        end
        if numType == 2 then
            value = (value * 100) .. "%"
        end
        self:SetWndText(AttrValueTrans, value)
    end
end

function UISagaBookDetail:RefreshVersionShow()
    if self._isVie then
        self:InitTextSizeWithLanguage(self.mNickName, -8)

        local textTran =CS.FindTrans(self.mSoundBtn,"Light/Text")
        self:InitTextLineWithLanguage(textTran,0)
        textTran =CS.FindTrans(self.mSoundBtn,"Gray/Text")
        self:InitTextLineWithLanguage(textTran,0)

        self:SetAnchorPos(self.mTxtFavor,Vector2.New(-245,400))
    end

    if self._isJapaness  then
        self:SetAnchorPos(self.mRewardGet,Vector2.New(190,-206))
    end
end

function UISagaBookDetail:OnDrawStarCell1(list, item, itemdata, itempos)
    local Star = self:FindWndTrans(item, "Star")
    if Star then
        self:SetWndEasyImage(Star, itemdata.img, function()
            CS.ShowObject(Star, true)
        end)
    end
end

---@param newUILiHuiObj LUIHeroObject
function UISagaBookDetail:UpdateJD(effectId,bCalm,newUILiHuiObj)
    ---@type LDisplaySpine
    local _displaySpine = newUILiHuiObj:GetDpObject()
    --local parseLHKPDrawingAllAge = gModelHeroExtra:GetParseLHDrawingAllAges(effectId)
    local parseLHKPDrawingAllAge = gModelHeroExtra:GetLHDrawingAllAgesDataByPrefabName(_displaySpine:GetSpineName())
    self:CreateHeroJDImgShow(parseLHKPDrawingAllAge,_displaySpine:GetDisplayTrans(),bCalm)
end

function UISagaBookDetail:OnDrawAwakenTreePointCell(parentRoot, itemdata, itempos)
    local treePbName = self._treePbName
    if not treePbName then
        return
    end

    local list = self._awakenTreeTransList[treePbName]
    if not list then
        self._awakenTreeTransList[treePbName] = {}
        list = self._awakenTreeTransList[treePbName]
    end

    local treePointRefId = itemdata.treePointRefId
    local info = list[treePointRefId]
    if not info then
        local pointRef = gModelHero:GetHeroTreePointRef(treePointRefId)
        local treePbNode = pointRef.treePbNode
        local pointTrans = self:FindWndTrans(parentRoot, treePbNode)
        if not pointTrans then
            printInfoNR("trans not find, transName = " .. treePbNode)
            return
        end

        info = {
            pointTrans = pointTrans,
            commonBgTrans = self:FindWndTrans(pointTrans, "CommonBg"),
            coverBgTrans = self:FindWndTrans(pointTrans, "CoverBg"),
            commonIcon = self:FindWndTrans(pointTrans, "CommonIcon"),
            coverIcon = self:FindWndTrans(pointTrans, "CoverIcon"),
            selectIcon = self:FindWndTrans(pointTrans, "SelectIcon"),
            upIcon = self:FindWndTrans(pointTrans, "UpIcon"),
            newIcon = self:FindWndTrans(pointTrans, "NewIcon"),
            skillTrans = self:FindWndTrans(pointTrans, "Skill/Root/SkillIcon"),
        }

        list[treePointRefId] = info
    end

    local isTryHero = self._isTryHero
    local pointTrans = info.pointTrans
    local isActivate = itemdata.isActivate or false
    local canActivate = itemdata.canActivate or false
    local canLvlUp = itemdata.canLvlUp or false
    local isSelect = treePointRefId == self._curSelectTreePointId
    local showActivate = canActivate and canLvlUp and not isTryHero
    local showLvUp = isActivate and canLvlUp and not isTryHero

    CS.ShowObject(info.commonBgTrans, not isActivate)
    CS.ShowObject(info.commonIcon, not isActivate)
    CS.ShowObject(info.coverBgTrans, isActivate)
    CS.ShowObject(info.coverIcon, isActivate)
    CS.ShowObject(info.selectIcon, isSelect)
    CS.ShowObject(info.upIcon, showLvUp)

    local showNewIcon = false
    CS.ShowObject(info.newIcon, showNewIcon)

    self:SetWndClick(pointTrans, function()
        self:OnClickTreePoint(treePointRefId)
    end)

    local pointType = itemdata.pointType

    --技能图标
    if pointType == ModelHero.TREE_POINT_TYPE_SKILL and info.skillTrans then
        local skillIconList = self._skillIconList
        if not skillIconList then
            skillIconList = {}
            self._skillIconList = skillIconList
        end

        local skillIconTrans = info.skillTrans
        local skillId = itemdata.skillId
        local haveSkill = skillId and skillId > 0

        local InstanceID = skillIconTrans:GetInstanceID()
        local baseClass = skillIconList[InstanceID]
        if not baseClass then
            baseClass = SkillIcon:New(self)
        end

        if not haveSkill then
            baseClass:SetShowIcon(false, false)
            baseClass:SetSkillInfo(nil, nil, nil, 1)
            baseClass:ShowLvl(false)

            baseClass:Create(skillIconTrans, 0, function()
                self:OnClickSkillSelect(treePointRefId)
            end)
            baseClass:SetIconAndIconBgGray(false)
        else
            baseClass:SetSkillInfo(nil, false, nil, 1)
            baseClass:ShowLvl(false)
            baseClass:ShowLock(false)

            baseClass:Create(skillIconTrans, skillId, function()
                self:OnClickSkillSelect(treePointRefId)
            end)
            baseClass:SetIconAndIconBgGray(false)
        end
    end
end

--function UISagaBookDetail:OnDrawAttrCell(list, item, itemdata, itempos)
--    local AttrIcon = self:FindWndTrans(item, "AttrIcon")
--    local AttrName = self:FindWndTrans(item, "AttrName")
--    local AttrValue = self:FindWndTrans(item, "AttrValue")
--    local numType, refId, value = itemdata.numType, itemdata.refId, itemdata.value
--    if AttrIcon then
--        local icon = gModelHero:GetAttributeIconById(refId)
--        self:SetWndEasyImage(AttrIcon, icon, function()
--            CS.ShowObject(AttrIcon, true)
--        end)
--    end
--    if AttrName then
--        local name = gModelHero:GetAttributeNameById(refId)
--        name = name .. "："
--        self:SetWndText(AttrName, name)
--    end
--    if AttrValue then
--        local attrValue = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, numType, value)
--        self:SetWndText(AttrValue, attrValue)
--    end
--end

function UISagaBookDetail:SetBotBtnState(btnTrans, isSele)
    local seleTrans = self:FindWndTrans(btnTrans, "SelImg")
    local imgOff = self:FindWndTrans(btnTrans, "ImageOff")
    local imgOn = self:FindWndTrans(btnTrans, "ImageOn")
    CS.ShowObject(imgOff, not isSele)
    CS.ShowObject(imgOn, isSele)

    CS.ShowObject(seleTrans, isSele)
end

function UISagaBookDetail:OnDrawVoiceCell(list, item, itemdata, itempos)
    --单个

    local VoiceTxtG = self:FindWndTrans(item, "VoiceTxtG")
    local VoiceTxt = self:FindWndTrans(VoiceTxtG, "VoiceTxt")
    local skinName = itemdata.refId == itemdata.heroType and ccLngText(itemdata.name) or ccLngText(itemdata.skinName)
    self:SetWndText(VoiceTxt, skinName)

    local skinListData = {}
    local favorRefs = gModelHero:GetHeroSpActionSoundRef()
    local VoiceConf = string.split(itemdata.RoleRef, ";")--语音

    --todo 暂时屏蔽 语录的报错
    local heroLove = gModelHero:GetHeroLoveLvByRefId(self._heroRefId) or 0
    local lockStr = string.replace(ccClientText(41323), favorRefs.RoleRef.refId)
    local icon = itemdata.icon
    -- local textConf = itemdata.RoleRefTxt or ""
    local VoiceTxtConf = ""-- string.split(ccLngText(textConf), ";")
    -- for i, v in ipairs(VoiceConf) do
    --     table.insert(skinListData, {
    --         icon = icon,
    --         text = VoiceTxtConf,
    --         voice = v,
    --         itempos = itempos
    --     })
    -- end

    local BattleRef = itemdata.BattleRef
    if not string.isempty(BattleRef) then
        local haveNum = #skinListData
        local battleConf = string.split(BattleRef, ";")
        for i, v in ipairs(battleConf) do
            local voiceTxt = VoiceTxtConf
            table.insert(skinListData, {
                icon = icon,
                text = voiceTxt,
                voice = v,
                itempos = itempos
            })
        end
    end

    local func = function(needLv)
        local str = ""
        if itemdata.skinType <= 1 then
            str = string.replace(ccClientText(41323), needLv)
        elseif itemdata.skinType == 2 then
            if itemdata.needStar and itemdata.needStar > 0 then
                str = string.replace(ccClientText(41639), needLv, itemdata.needStar)
            else
                str = string.replace(ccClientText(41638), needLv)
            end
        end
        return str
    end
    local addSkinData = function(soundStr, favorRef, desc)
        local sounds = string.split(soundStr, ";")
        local descs = string.split(desc or "", ";")
        for i, sound in ipairs(sounds) do
            if not string.isempty(sound) then
                VoiceTxtConf = heroLove >= favorRef.refId and ccLngText(favorRef.text2) or func(favorRef.refId)
                local color = heroLove >= favorRef.refId and "#734f22" or "#c81313"
                VoiceTxtConf = string.replace("<color=#a1#>#a2#</color>", color, VoiceTxtConf)
                local nameStr = itemdata.skinType <= 1 and ccLngText(itemdata.name) or ccLngText(itemdata.skinName)
                local cvName = (itemdata.cvName and itemdata.cvName ~= "") and "Cv." .. ccLngText(itemdata.cvName) or ""
                table.insert(skinListData, {
                    icon = icon,
                    text = VoiceTxtConf,
                    txtDesc = descs[i],
                    voice = sound,
                    itempos = itempos,
                    cvName = cvName,
                    name = nameStr,
                    islock = heroLove >= favorRef.refId,
                })
            end
        end
    end
    --基础语音
    addSkinData(itemdata.RoleRef, favorRefs.RoleRef, itemdata.RoleRefTxt)
    --点击交互语音
    local clickSound = itemdata.heroClickSpActionSound
    local favorRef = favorRefs.heroClickSpActionSound
    addSkinData(clickSound, favorRef, itemdata.heroClickSpActionDesc)
    --道具反馈语音
    local itemSound = itemdata.heroPlayItemSpActionSound
    favorRef = favorRefs.heroPlayItemSpActionSound
    addSkinData(itemSound, favorRef, itemdata.heroPlayItemSpActionDesc)
    --特写语音
    local closeUpSound = itemdata.heroCloseUpSpActionSound
    favorRef = favorRefs.heroCloseUpSpActionSound
    addSkinData(closeUpSound, favorRef, itemdata.heroCloseUpSpActionDesc)
    --升星语音
    local starUp = itemdata.heroStarUpSound
    favorRef = favorRefs.heroStarUpSound
    addSkinData(starUp, favorRef, itemdata.heroStarUpDesc)
    --技能语音
    local skillSound1 = itemdata.skillSound1
    favorRef = favorRefs.skillSound1
    addSkinData(skillSound1, favorRef, itemdata.skillSound1Desc)
    local skillSound2 = itemdata.skillSound2
    favorRef = favorRefs.skillSound2
    addSkinData(skillSound2, favorRef, itemdata.skillSound2Desc)
    --胜利语音
    local winSound = itemdata.heroWinMVPSound
    favorRef = favorRefs.heroWinMVPSound
    addSkinData(winSound, favorRef)

    local skinListTrans = self:FindWndTrans(item, "SkinList")
    local uiSkillKey = skinListTrans:GetInstanceID()
    local uiSkillList = self:FindUIScroll(uiSkillKey)
    if uiSkillList then
        uiSkillList:RefreshList(skinListData)
    else
        uiSkillList = self:GetUIScroll(uiSkillKey)
        uiSkillList:Create(skinListTrans, skinListData, function(...)
            self:OnDrawVoiceCell1(...)
        end)
    end

    local len = #skinListData
    local haveSkin = len > 0

    -- CS.ShowObject(VoiceTxtG, haveSkin)
    if not haveSkin then
        return
    end

    local t = len * 88 + (len - 1) * 8
    LxUiHelper.SetSizeWithCurAnchor(skinListTrans, 1, t)
    local height = t
    LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
end

function UISagaBookDetail:InitMsg()
    self:WndNetMsgRecv(LProtoIds.BookChangeInfoResp, function(...)
        self:RefreshHeroBookView(self._heroRefId, true, 2)
    end)

    self:WndNetMsgRecv(LProtoIds.HeroBookAddCloseCleanResp, function(...)
        self:OnHeroBookAddCloseResp(...)
    end)

    self:WndEventRecv(EventNames.FAVORABILITY_INTERACT, function(addExp)
        self:UpdateInteractBtnRed()
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_EXP_UPDATE, function(addExp)
        self:UpdateG5()
        self:UpdateSelectTabBtn()
        self:OnPlayEffect(addExp)
        self:CheckGuide()
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_LOVE_UPLV, function(params)
        self:UpdateG5()
        self:UpdateSelectTabBtn()
        self.params = params
        self:OnPlayEffect(params.addExp)
    end)
    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:UpdateG5()
    end)

    local funcId = 21003001
    local bShowSound = gModelFunctionOpen:CheckIsShow(funcId)
    if bShowSound then
        local cfg = gModelFunctionOpen:GetFunctionOpenCfg(funcId)
        if cfg then
            self:SetWndButtonText(self.mSoundBtn, ccLngText(cfg.name))
        end
        local isOpen = gModelFunctionOpen:CheckIsOpened(funcId)
        self:SetWndButtonGray(self.mSoundBtn, not isOpen)
    end
    CS.ShowObject(self.mSoundBtn,bShowSound)
end

function UISagaBookDetail:RefreshVoice()
    if not self._lockVoice then
        return
    end

    local list = self:GetSkinList()

    local uiSkinVoiceList = self._uiSkinVoiceList
    if uiSkinVoiceList then
        uiSkinVoiceList:RefreshList(list)
        uiSkinVoiceList:DrawAllItems()
        uiSkinVoiceList:MoveToPos(1)
    else
        uiSkinVoiceList = self:GetUIScroll("uiSkinVoiceList")
        self._uiSkinVoiceList = uiSkinVoiceList
        uiSkinVoiceList:Create(self.mVoiceList, list, function(...)
            self:OnDrawVoiceCell(...)
        end, UIItemList.SUPER)
    end

    local len = #list
    uiSkinVoiceList:EnableScroll(len > 0, false)

    -- local uiList = uiSkinVoiceList:GetList()
    -- uiList:RefreshList()


    local showLen = 1
    if gLGameLanguage:IsJapanRegion() then
        showLen = 0
    end

    -- CS.ShowObject(self.mTipMoreTxt, len <= showLen)
end

function UISagaBookDetail:GetMaxClass(lv, classType)
    local maxLv = 0
    local _classList = {}
    for k, v in pairs(GameTable.CharacterClassRef) do
        if v.type == classType then
            if maxLv < v.needLevel then
                maxLv = v.needLevel
            end
            table.insert(_classList, v)
        end
    end
    table.sort(_classList, function(c1, c2)
        return c1.grade < c2.grade
    end)
    self._classType = _classList
    local grade = 0
    for i, v in ipairs(_classList) do
        local tempGrade = v.grade
        local needLv = v.needLevel
        if lv >= needLv and needLv ~= -1 and grade <= tempGrade then
            grade = tempGrade
        elseif needLv == -1 and maxLv < lv then
            grade = tempGrade
        end
    end
    return grade
end

function UISagaBookDetail:RefreshSkillList(star, grade)
    local refId = self._heroRefId
    local heroSkillIdList = gModelHero:GetSkillListByRefIdAndStar(refId, star, self._curForm)

    local list = {}
    for i = 1, 4 do
        local skillData = heroSkillIdList[i]
        local data = {
            refId = refId,
            star = star,
            index = i,
            grade = grade
        }
        if skillData then
            data.skillId = skillData.skillId
            data.openClass = skillData.openClass
        end
        table.insert(list, data)
    end

    local uiSkillList = self._uiSkillList
    if uiSkillList then
        uiSkillList:RefreshList(list)
    else
        uiSkillList = self:GetUIScroll("uiSkillList")
        self._uiSkillList = uiSkillList
        uiSkillList:Create(self.mSkillList, list, function(...)
            self:OnDrawSkillCell(...)
        end)
    end
end

function UISagaBookDetail:InitHightState()
    self._curHightStateIndex = 1

    self:RefreshHightStateView()
end

function UISagaBookDetail:ShowPrepositionPointEff(isShow, treePointRefId)
    local heroTreePointInfo = self._heroTreeInfoList[treePointRefId]
    if not heroTreePointInfo then
        return
    end

    local isShowEff = isShow
    if isShowEff then
        isShowEff = false
        if not heroTreePointInfo.isActivate then

            if not heroTreePointInfo.canActivate and heroTreePointInfo.needConType == ModelHero.TREE_CON_TYPE_LVL then
                isShowEff = true
            end
        end
    end

    local ref = gModelHero:GetHeroTreePointRef(treePointRefId)
    if not ref then
        printInfoNR("GameTable.CharacterTreePointRef[refId] is a nil, refId = " .. treePointRefId)
        return
    end

    local front = ref.front
    if not front or front <= 0 then
        return
    end

    local treePointTransList = self._awakenTreeTransList[self._treePbName]
    local frontPointInfo = treePointTransList[front]
    if not frontPointInfo then
        return
    end

    local frontHeroTreePointInfo = self._heroTreeInfoList[front]
    if not frontHeroTreePointInfo then
        return
    end

    local pointTrans = frontPointInfo.pointTrans
    local pointType = frontHeroTreePointInfo.pointType
    local effName = pointType == ModelHero.TREE_POINT_TYPE_ATTR and "ui_yingxiongjuexing_qianzhi" or "ui_yingxiongjuexing_qianzhi_2"
    self:SetAwakenPointEffShow(isShowEff, effName, pointTrans)
end
function UISagaBookDetail:isShowTab5()
    if not gModelFunctionOpen:CheckIsOpened(21002000, false) then
        return false
    end
    local favor = GameTable.CharacterRef[self._heroRefId].maxFavorability
    if not favor or favor <= 0 then
        return false
    end
    local active = gModelHero:IsActiveHeroEffRefId(self._heroRefId)
    if active then
        local bgRedPoint = self:FindWndTrans(self.mHBShopBtn, "RedPoint")
        self:RegisterRedPointFunc(ModelRedPoint.SHOP, function()
            local showRed = gModelRedPoint:CheckSingleShopRedPoint(1007)
            CS.ShowObject(bgRedPoint, showRed)
        end)
    end
    return active
end

function UISagaBookDetail:ChangHeroLiPos(trans, selSkinRefId)
    if not selSkinRefId or not trans then
        return
    end
    local x, y = gModelHeroBook:GetHeroPosByRefIdAndType(selSkinRefId, "heroDrawingPos1")
    if x and y then
        trans.anchoredPosition = Vector3.New(x, y, 0)
        self.mHeroLiHuEffiPos.anchoredPosition = Vector3.New(x, y, 0)
    end
end

function UISagaBookDetail:RefreshStoryContent(list, item, itemdata, pos)
    local titleRoot = self:FindWndTrans(item, "TitleTemplate")
    local title_1 = self:FindWndTrans(titleRoot, "Title_1")
    local title_2 = self:FindWndTrans(titleRoot, "Title_2")
    local title_3 = self:FindWndTrans(titleRoot, "Title_3")
    local Line = self:FindWndTrans(item, "Line")
    local contentRoot = self:FindWndTrans(item, "ContentTemplate")
    local content = self:FindWndTrans(contentRoot, "Content")
    local LockInfoDiv = self:FindWndTrans(item, "LockInfoDiv")
    local ImgLove = self:FindWndTrans(LockInfoDiv, "ImgLove")
    local LoveLevel = self:FindWndTrans(ImgLove, "LoveLevel")
    local UnLockTxt = self:FindWndTrans(LockInfoDiv, "UnLockTxt")

    if self.unlockStoryNum then
        local showStory = pos <= tonumber(self.unlockStoryNum[#self.unlockStoryNum])
        local levelTxt = gModelHeroBook:GetActiveLevelByStoryNum(itemdata.number)
        self:SetWndText(LoveLevel, levelTxt)
        self:SetWndText(UnLockTxt, string.replace(ccClientText(41324),levelTxt))
        CS.ShowObject(LockInfoDiv,not showStory)
        CS.ShowObject(Line,showStory)
        if not showStory then
            return
        end
    else
        CS.ShowObject(LockInfoDiv,false)
    end


    local title_1_Str = ccLngText(itemdata.decName)
    self:SetWndText(title_1, title_1_Str)

    local contentStr = ccLngText(itemdata.dec)
    self:SetWndText(content, contentStr)

    --文本的处理嘛  ImgStar.sizeDelta = del
    --item.sizeDelta = Vector2.New(601,300)

end

function UISagaBookDetail:RefreshVoiceTab()
    if not self._lockVoice then
        return
    end

    local lock = self:GetisEmptySkinVoice()
    CS.ShowObject(self.mUnlockVoiceIcon, not lock)
    self._lockSkinTab = lock

end

function UISagaBookDetail:CreateAwakenTree(treeTrans)
    local heroTreeInfoList = self._heroTreeInfoList
    if not heroTreeInfoList then
        return
    end

    local pointListTrans = self:FindWndTrans(treeTrans, "ScrollRect/Content/PointList")
    for k, v in pairs(heroTreeInfoList) do
        self:OnDrawAwakenTreePointCell(pointListTrans, v, k)
    end
end

function UISagaBookDetail:InitStoryData(heroRefId)
    local heroRef = gModelHero:GetHeroRef(heroRefId)
    local heroStory = heroRef.heroStory
    if type(heroStory) == "string" then
        heroStory = tonumber(ccLngText(heroStory))
    end
    local storyRefList = gModelHeroBook._initHeroStoryRefList[heroStory]

    if storyRefList == nil then
        storyRefList = gModelHeroBook._initHeroStoryRefList[2000] -- 兼容配置没有 使用2000类型故事
    end
    local storyData = {}
    for k, v in pairs(storyRefList) do
        table.insert(storyData, v)
    end
    table.sort(storyData, function(a, b)
        if a.needStar ~= b.needStar then
            return a.needStar < b.needStar
        end
        return a.refId < b.refId
    end)
    self._storyData = storyData
end

function UISagaBookDetail:OnDrawAwakenSkillCell(list, item, itemdata, itempos)
    local skillId = tonumber(itemdata.skillId)
    local curSelectTreePointId = self._curSelectTreePointId
    local awakenPointActivate = true
    local Root = self:FindWndTrans(item, "CommonUI/Root")
    if Root then

        local SkillIconTrans = self:FindWndTrans(Root, "SkillIcon")
        local baseClass = SkillIcon:New(self)
        if skillId then
            baseClass:SetSkillInfo(nil, false, nil, 1)

            baseClass:Create(SkillIconTrans, skillId, function()
                local skillList = gModelHero:GetTreePointSkillIdList(curSelectTreePointId, itempos)
                if not table.isempty(skillList) then
                    local firstSkillId = skillList[1]
                    gModelGeneral:OpenSkillWnd({
                        skill = firstSkillId,
                        curSkillId = skillId,
                        wndType = 5,
                        pointActivate = awakenPointActivate,
                    })
                    --[[					GF.OpenWnd("UINewJNTip",{
                                            skill = firstSkillId,
                                            curSkillId = skillId,
                                            wndType = 5,
                                            pointActivate = awakenPointActivate,
                                        })]]
                end
            end)
        else
            baseClass:SetShowIcon(false, false)
            baseClass:SetSkillInfo(nil, nil, nil, 1)

            baseClass:Create(SkillIconTrans, 0, function()
            end)
        end
        if not skillId then
            baseClass:SetIconAndIconBgGray(false)
        end
    end

    local skillType = itemdata.skillType
    local ExtraImgTrans = self:FindWndTrans(item, "ExtraImg")
    local isShow = skillType == ModelHero.TYPE_AWAKEN_SKILL_EXTRA
    CS.ShowObject(ExtraImgTrans, isShow)

    local selectBg = self:FindWndTrans(item, "SelectBg")
    local isActivate = true
    local selectYesIcon = self:FindWndTrans(selectBg, "SelectYesIcon")
    local isSelect = isActivate and self._curSelectTreePointSkillId == skillId
    CS.ShowObject(selectYesIcon, isSelect)
    self:SetWndClick(selectBg, function()
        self:OnClickAwakenSkillSelect(skillId)
    end)
end

function UISagaBookDetail:CreateBaseAttrList(attrList)
    local uiAttrList = self._uiAttrList
    if uiAttrList then
        uiAttrList:RefreshList(attrList)
    else
        uiAttrList = self:GetUIScroll("uiAttrList")
        self._uiAttrList = uiAttrList
        uiAttrList:Create(self.mAttrList, attrList, function(...)
            self:OnDrawAttrCell(...)
        end)
    end
end

function UISagaBookDetail:CreateAttrList(key, list, listTrans)
    local uiAttrList = self:FindUIScroll(key)
    if uiAttrList then
        uiAttrList:RefreshList(list)
    else
        uiAttrList = self:GetUIScroll(key)
        uiAttrList:Create(listTrans, list, function(...)
            self:OnDrawAttrCell(...)
        end)
    end
end
function UISagaBookDetail:OneUseGiveGift()
    local costStr = GameTable.CharacterRef[self._heroRefId].favorabilityGIft
    local curLv = gModelHero:GetHeroLoveLvByRefId(self._heroRefId) or 0
    if not GameTable.CharacterFavorabilityRef[curLv + 1] then
        GF.ShowMessage(ccClientText(42021))
        return
    end
    local curExp = gModelHero:GetHeroLoveExpByRefId(self._heroRefId) or 0
    local costItem = string.split(costStr, ",")
    local needExp = GameTable.CharacterFavorabilityRef[curLv + 1].exp - curExp
    local usableLove = 0
    local costGift = {}
    for i, v in ipairs(costItem) do
        local itemRef = GameTable.PlayerItemRef[tonumber(v)]
        local loves = string.split(itemRef.typeDate, ",")
        local itemLove = loves and tonumber(loves[1]) or 0
        local haveCount = gModelItem:GetNumByRefId(itemRef.refId)
        usableLove = usableLove + itemLove * haveCount
        if haveCount > 0 then
            table.insert(costGift, { _refId = itemRef.refId, _num = haveCount })
        end
        if usableLove > 0 and usableLove >= needExp then
            break
        end
    end
    if usableLove <= 0 or usableLove < needExp then
        if usableLove > 0 then
            gModelGeneral:OpenUIOrdinTips({ refId = 10044, func = function()
                gModelHeroExtra:OnHeroGiveGiftReq(self._heroRefId, costGift)
            end })
            return
        end
        local itemRef = GameTable.PlayerItemRef[tonumber(costItem[#costItem])]
        if itemRef.jump ~= "" then
            gModelGeneral:OpenGetWayWnd({ itemId = itemRef.refId })
        else
            GF.ShowMessage(ccClientText(41642))
        end
    else
        gModelHeroExtra:OnHeroGiveGiftReq(self._heroRefId, costGift)
    end
end

function UISagaBookDetail:RefreshHeroBookView(refId, netWork, getRewardIndex)

    --如果是网络的数据应该是要return 掉
    if self._isStoryClickGetReward then
        self._isStoryClickGetReward = false
        self:SetRewardIsShow()
        return
    end

    local serverData = gModelHeroBook:GetHeroInfoByHeroRefId(refId)
    if not serverData then
        return
    end
    self._heroRefId = refId

    local closeGrade = serverData.heroMaxStar
    local heroRef = gModelHero:GetHeroRef(refId)
    if not heroRef then
        return
    end
    self:CheckQMJDCanUp(refId)
    local maxStar = heroRef.maxStar
    local heroBookShowAwake = gModelHero:GeConfigByKey("heroBookShowAwake") or 1
    local isShowAwaken = maxStar and maxStar >= 10 and heroBookShowAwake == 1
    --暂时屏蔽
    --CS.ShowObject(self.mAwakeBtn, isShowAwaken)
    CS.ShowObject(self.mAwakeBtn, false)

    gModelHero:PlayHeroRoleSound(refId)
    --local closeLv = heroRef.closeLv
    --local heroCloseRef = gModelHeroBook:GetHeroCloseLvRefByCloseTypeAndCloseGrade(closeLv, closeGrade)
    --if not heroCloseRef then return end

    local race = heroRef.raceType
    local raceRef = gModelHero:GetHeroRaceRefByRefId(race)
    if raceRef then
        --local heroBgHalf = "hero_bg_big_"..race
        self:SetWndEasyImage(self.mHeroBookImg, raceRef.heroBg)
        self:SetWndEasyImage(self.mHeroRaceImg, raceRef.icon)
        --self:SetWndEasyImage(self.mRaceCol, "herobook1_quality_" .. race)
        self:SetWndText(self.mRaceTypeValueTxt, ccLngText(raceRef.name))
    end
    local careerRef = GameTable.CharacterCareerRef[heroRef.careerType]
    self:SetWndText(self.mCareerNumTxt, ccLngText(careerRef.name))

    self:SetWndEasyImage(self.mQualityImg, heroRef.qualityIcon)

    if not netWork then
        self:CreateLiHui(refId)
    end
    self:CreateQMDJList(closeGrade, refId)

    -- self:RefreshHeroCVName(refId)

    local isActive = serverData.isActive
    --local closeValue = serverData.closeValue
    --local needLevel = heroCloseRef.needLevel
    --local isMax = needLevel == ModelHeroBook.HEROCLOSELV_MAX
    --local maxValue = isMax and 1 or needLevel
    --local value = isMax and 1 or closeValue
    --LxUiHelper.SetProgress(self.mFill,value / maxValue)
    --local proStr = string.replace(ccClientText(19713),closeValue,needLevel)
    --self:SetWndText(self.mqmNum,proStr)


    CS.ShowObject(self.mCloseMaxTxt, not false)
    local status = gModelHeroBook:CheckBookInfoStatusByRefId(refId)

    self._canUp = canUp or status

    self:UpdateG1()
    self:InitStoryData(refId)
    self._storyIndex = 1

    self:UpdateStory(true)
    self:UpdateG5()

    self:OnUpdateEffectLove()

    --local showQMNum = not isMax
    --local qmNumTrans = self.mQmNum
    --if showQMNum then
    --	local str = string.replace(ccClientText(19713), closeValue, needLevel)
    --	self:SetWndText(qmNumTrans, str)
    --end
    --CS.ShowObject(qmNumTrans, showQMNum)
    --local attrList = heroCloseRef.attrList or {}
    --self:CreateAttrList("mQmAddAttrList", attrList, self.mQmAddAttrList)

    local haveHero = gModelHeroBook:GetHeroIsActByRefId(refId)

    self:SetWndClick(self.mHBStoryBtn, function()
        local storyStatus = gModelHeroBook:CheckBookStoryStatusByRefId(refId)
        local t = storyStatus and 1 or 0
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK, "2-1-1-3", refId, haveHero, t)
        GF.OpenWnd("UISagaSy", { refId = refId })
    end)
    local storyStatus = gModelHeroBook:CheckBookStoryStatusByRefId(refId)
    CS.ShowObject(self.mHBStoryBtnRedPoint, storyStatus)
    self:SetWndClick(self.mHeroBookViewLoveBtn, function()
        --GF.OpenWndTop("UIXAddSow", { closeType = closeLv,heroRefId = refId })
    end)
    self:SetWndClick(self.mHBSkinBtn, function()
        --gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK, "2-1-1-5", refId, haveHero, 0)
        --GF.OpenWndTop("UISagaDisPy", { heroRefId = refId })
    end)

    --self:SetWndClick(self.mUpG, function()
    --	if not canUp then
    --
    --		local str = ccClientText(19787)
    --		local heroName = gModelHero:GetHeroNameByRefId(refId)
    --		local addNum = gModelHero:GetCloseValueByRefId(refId)
    --		str = string.replace(str,heroName,addNum)
    --		GF.ShowMessage(str)
    --		return
    --	end
    --	gModelHeroBook:OnHeroBookUpCloseGradeReq(refId)
    --end)


    CS.ShowObject(self.mHBPinlunBtn,gModelFunctionOpen:CheckIsShow(10303006))
    self:SetWndClick(self.mHBPinlunBtn, function()
        local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_3)
        if not sensitive then
            GF.ShowMessage(ccClientText(30800))
            return
        end
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK, "2-1-1-4", refId, haveHero, 0)
        GF.OpenWnd("UISagaComment", { refId = refId })
    end)
    self:SetWndClick(self.mHBWayBtn, function()
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK, "2-1-1-1", refId, haveHero, 0)
        gModelGeneral:OpenGetWayWnd({ itemId = refId, refIdType = LItemTypeConst.TYPE_HERO, srcWnd = self:GetWndName() })
    end)
    self:SetWndClick(self.mHeroBookViewAttrBtn, function()
        --GF.OpenWndTop("UIXAddSow", { closeType = closeLv,heroRefId = refId })
    end)

    self:SetWndClick(self.mBtnForm, function()
        self:OnClickBtnForm()
    end)

    local tempList = gModelHeroExtra:GetPolymorphismNew(self._heroRefId)

    if nil == tempList then
    else
        self._heroHightStates = {}
        for k, v in ipairs(tempList) do
            table.insert(self._heroHightStates, v)
        end
    end

    getRewardIndex = getRewardIndex or 1

    self:InitTabData(getRewardIndex)
end

--region 构建界面 dotween --------------------------------------------------------------------------------
UISagaBookDetail.PlayTime = 0.3
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)

function UISagaBookDetail:PlayShowTween()
    local tweenSeq = YXTween.TweenSequenceIns()
    local isTab4 = self._showTabData[self._tabIndex].indexId == 4
    local isTab5 = self._showTabData[self._tabIndex].indexId == 5
    CS.ShowObject(self.mGameObject_1, true)
    CS.ShowObject(self.mG4, isTab4)
    CS.ShowObject(self.mG5, isTab5)
    CS.ShowObject(self.mGameObject_3, true)

    local moveFunc = function(value)
        self:SetAnchorPos(self.mGameObject_1, Vector2.New(0, value))
        if isTab4 then
            self:SetAnchorPos(self.mG4, Vector2.New(0, -value))
        end
        if isTab5 then
            self:SetAnchorPos(self.mG5, Vector2.New(0, -value))
        end
        self:SetAnchorPos(self.mGameObject_3, Vector2.New(0, -value))
    end

    local moveTween = YXTween.TweenFloat(100, 0, UISagaBookDetail.PlayTime, moveFunc):SetEase(DG.Tweening.Ease.InSine)

    tweenSeq:AppendInterval(UISagaBookDetail.PlayTime)
    tweenSeq:Append(moveTween)

    tweenSeq:OnComplete(function()
        self._showTween = nil
    end)

    self._showTween = tweenSeq
    tweenSeq:PlayForward()

end

function UISagaBookDetail:OnDrawSkillCell(list, item, itemdata, itempos)
    local skillId, openClass = itemdata.skillId, itemdata.openClass
    local refId, star, index = itemdata.refId, itemdata.star, itemdata.index
    local grade = itemdata.grade
    local Root = self:FindWndTrans(item, "CommonUI/Root")
    if Root then

        local SkillIconTrans = self:FindWndTrans(Root, "SkillIcon")
        local baseClass = SkillIcon:New(self)
        if skillId then
            baseClass:SetSkillInfo(openClass, false, openClass, 1)

            baseClass:Create(SkillIconTrans, skillId, function()
                local heroData = {
                    refId = refId,
                    star = star,
                    grade = grade,
                }
                gModelGeneral:OpenHeroSkillWnd({ curSkillId = skillId, curSkillIdx = index, heroData = heroData })
                --[[				local skillInfo = {
                                    grade = openClass,
                                    refId = refId,
                                    star = star,
                                }
                                GF.OpenWndTop("UIJNInfo",{
                                    skillId = skillId,
                                    heroData = skillInfo,
                                    needGrade = openClass,
                                    index = index
                                })]]
            end)
        else
            baseClass:SetShowIcon(false, false)
            baseClass:SetSkillInfo(nil, nil, nil, 1)

            baseClass:Create(SkillIconTrans, 0, function()
            end)
        end
        if not skillId then
            baseClass:SetIconAndIconBgGray(false)
        end
    end
    local SkillName = self:FindWndTrans(item, "SkillName")
    if SkillName then
        local name
        if skillId then
            local skillRef = gModelHero:GetSkillByStarId(skillId)
            if skillRef then
                name = ccLngText(skillRef.name)
            end
        else
            name = ccClientText(10149)
        end
        self:SetWndText(SkillName, name)
    end

    self:InitTextModeWithLanguage(SkillName)
end

function UISagaBookDetail:OnClickBtnForm()
    if self._curForm == 0 then
        self._curForm = 1
    else
        self._curForm = 0
    end

    self:RefreshHeroBookView(self._heroRefId)
end

function UISagaBookDetail:ClearTween()
    self._showTween = nil
    self._hideTween = nil
    self.effectTween = nil
end

function UISagaBookDetail:OnClickTab(index, isSecondCall)
    local indexId = self._showTabData[index] and self._showTabData[index].indexId or index
    local isTab1 = indexId == 1;
    local isTab2 = indexId == 2;
    local isTab3 = indexId == 3;
    local isTab4 = indexId == 4;
    local isTab5 = indexId == 5;

    if isTab3 and not self._lockSkinTab then
        local str = ccClientText(19784)
        GF.ShowMessage(str)
        return
    end

    if isTab4 then
        local wndArgList = self:GetWndArgList()
        wndArgList.page = indexId
        self:SendWndOpenDetailInfo()

        local heroRef = GameTable.CharacterRef[self._heroRefId]
        if heroRef and heroRef.quality == 7 then
            FireEvent(EventNames.ON_WND_IN_SHENHUAHERO)
        end
    end

    -- self:SetBotBtnState(self.mTab1, isTab1)
    -- self:SetBotBtnState(self.mTab2, isTab2)
    -- self:SetBotBtnState(self.mTabVoice, isTab3)
    -- self:SetBotBtnState(self.mTab4, isTab4)
    CS.ShowObject(self.mG1, isTab1)

    CS.ShowObject(self.mHeroLiHuiBgPos, false)
    CS.ShowObject(self.mHeroLiHuiHdPos, false)

    CS.ShowObject(self.mG2, isTab2)
    CS.ShowObject(self.mStoryRoot, isTab2)
    CS.ShowObject(self.mHBShopBtn, isTab5)

    LayoutRebuilder.ForceRebuildLayoutImmediate(self.mStoryList_New)
    if isTab2 and not isSecondCall then
        self:UpdateStory(true)
        self:OnClickTab(index, true)
    end

    CS.ShowObject(self.mG3, isTab3)
    CS.ShowObject(self.mG4, isTab4)
    CS.ShowObject(self.mG5, isTab5)
    CS.ShowObject(self.mGameObject_2, isTab4 or isTab5)

    --CS.ShowObject(self.mBgL, not isTab3)
    --CS.ShowObject(self.mBgR, not isTab3)

    CS.ShowObject(self.mCurLeftBtn, not (isTab3 or self._isOnly))
    CS.ShowObject(self.mCurRightBtn, not (isTab3 or self._isOnly))

    CS.ShowObject(self.mHeroLiHuiPos, not isTab4)
    CS.ShowObject(self.mHeroLihui, isTab4)

    if isTab3 then
        self:RefreshVoice()
    end

    if isTab4 or isTab5 then
        if isTab4 then
            self:InitHightState()
        end
        if isTab5 and self._tabIndex ~= index then
            self:ShowRewardList()
            self:InitLoveLvOrder()
        end

        CS.ShowObject(self.mBgL, false)
        CS.ShowObject(self.mBgR, false)

        CS.ShowObject(self.mCurLeftBtn, false)
        CS.ShowObject(self.mCurRightBtn, false)
    end

    CS.ShowObject(self.mGameObject, not isTab4)

    local oldIndex = self._tabIndex
    self._tabIndex = index;
    if oldIndex ~= index and self.isClickSound then
        gLGameAudio:StopSingleSound()
    end
    self:SetWndTabStatus(self._tabList[oldIndex], 1)
    self:SetWndTabStatus(self._tabList[index], 0)


    --屏蔽掉 左右切换的按钮
    CS.ShowObject(self.mCurLeftBtn, false)
    CS.ShowObject(self.mCurRightBtn, false)
end

function UISagaBookDetail:RefreshAwakenView()
    local refId = self._heroRefId
    local treeRefId = gModelHero:GetHeroAwakenByRefId(refId)
    if treeRefId == 0 then
        return
    end
    self._treeRefId = treeRefId
    local heroTreeInfoList = gModelHero:GetFakeMaxAwakenDataByRefId(treeRefId)
    if not heroTreeInfoList then
        return
    end
    self._heroTreeInfoList = heroTreeInfoList

    local curSelectTreePointId
    if not self._curSelectTreePointId then
        curSelectTreePointId = self:GetDefaultSelectTreePoint()
    end

    self:RefreshAwakenTree()
    self:RefreshAwakenDetails()

    local heroRef = gModelHero:GetHeroRef(refId)
    local starRef = gModelHero:GetHeroStarRef(refId, self._curForm, heroRef.maxStar)

    local effectId = starRef.effectId
    local effRef = gModelHero:GetShowEffectById(effectId)
    local heroName = ccLngText(effRef.name)
    self:SetWndText(self.mShiftUpStarText, heroName)

    local quality = starRef.quality
    local qualityRef = gModelItem:GetQualityRef(quality)

    local nickName = ccLngText(effRef.nickName)
    self:SetWndText(self.mNickName, nickName)
    self:SetXUITextTransColor(self.mNickName, qualityRef.nameColor)

    if curSelectTreePointId then
        self:OnClickTreePoint(curSelectTreePointId)
    end
end

function UISagaBookDetail:OnClickTreePoint(treePointRefId)
    if self._curSelectTreePointId == treePointRefId then
        return
    end

    local oldSelectTreePointId = self._curSelectTreePointId
    local treePointTransList = self._awakenTreeTransList[self._treePbName]
    local oldPointInfo = treePointTransList[oldSelectTreePointId]
    if oldPointInfo then
        CS.ShowObject(oldPointInfo.selectIcon, false)
    end

    local curPointInfo = treePointTransList[treePointRefId]
    if curPointInfo then
        CS.ShowObject(curPointInfo.selectIcon, true)
    end

    self:ShowPrepositionPointEff(false, oldSelectTreePointId)
    self:ShowPrepositionPointEff(true, treePointRefId)

    self._curSelectTreePointId = treePointRefId
    self:RefreshAwakenDetails()
end

function UISagaBookDetail:CheckSingleIsPlaying()
    if self._checkSingleTime >= 1 then
        CS.ShowObject(self.ImgHorn1, false)
        CS.ShowObject(self.ImgHorn0, false)
        self._checkSingleTime = 0
        return
    end
    local logicIsPlaying = self._isPlayVoiceId ~= nil and self._isPlayVoiceId
    local isPlaying = gLGameAudio:IsSingleSoundPlaying()
    local oldItemBtn = self._isPlayVoiceItemBtn ~= nil and self._isPlayVoiceItemBtn

    if not logicIsPlaying or not oldItemBtn then
        self:TimerStop(self._checkIsPlayingTimerKey)
        CS.ShowObject(self.ImgHorn0, true)
        CS.ShowObject(self.ImgHorn1, true)
    end

    if logicIsPlaying and not isPlaying then
        self:TimerStop(self._checkIsPlayingTimerKey)
        if oldItemBtn then
            -- self:SetPlayBtnState(oldItemBtn, false)
        end
        CS.ShowObject(self.ImgHorn0, true)
        CS.ShowObject(self.ImgHorn1, true)
        self._isPlayVoiceId = nil
        self._isPlayVoiceItemBtn = nil
    end
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

end

function UISagaBookDetail:RefreshHeroCVName(heroRefId)
    local cvName = gModelHero:GetHeroCVName(heroRefId)
    local isShow = not string.isempty(cvName)
    CS.ShowObject(self.mCVNameBg, isShow)
    if not isShow then
        return
    end

    local cvNameStr = string.replace(ccClientText(19786), cvName)
    self:SetWndText(self.mCVNameTxt, cvNameStr)
end

function UISagaBookDetail:OnClickSkillSelect(treePointRefId)
    local heroRefId = self._heroRefId
    gModelHeroExtra:OpenHeroTreeSkillWnd({
        viewType = 3,
        heroRefId = heroRefId,
        targetTreePointRefId = treePointRefId,
    })
    --[[	GF.OpenWnd("UISagaAwakenJNSelect",{
            pointRefId = treePointRefId,
            heroRefId  = heroRefId,
        })]]
end

function UISagaBookDetail:UpdateG1()
    --local hasSkin =
    --CS.ShowObject(self.mHBSkinBtn,false)

    local refId = self._heroRefId
    local heroRef = gModelHero:GetHeroRef(refId)
    --local starType = heroRef.starType
    --local starId = gModelHero:GetStarId(starType,heroRef.maxStar)
    --local starRef = gModelHero:GetHeroStarById(starId)

    local starRef = gModelHero:GetHeroStarRef(refId, self._curForm, heroRef.maxStar)--英雄id+最大星级-> 英雄类型*100+星级=星级id
    local starId = starRef.refId
    self._starId = starId

    self:RefreshVoiceTab()

    local lv = starRef.maxLevel
    local star = starRef.star

    self:SetWndText(self.mLvNumTxt, lv)
    local classType = heroRef.classType
    local grade = self:GetMaxClass(lv, classType)
    local gradeId = gModelHero:ConvertToHeroGradeId(heroRef.classType, grade)

    local buffList = gModelHero:GetSkillBuff(refId, star)
    local Atk, maxHp, Def, Speed = gModelHero:GetBaseAttrInfo(refId, lv, starId, gradeId, buffList)

    local heroInitCritRatio = gModelHero:GeConfigByKey("heroInitCritRatio")        -- 暴伤基础
    local heroInitHit = gModelHero:GeConfigByKey("heroInitHit")                    -- 暴伤基础

    local attrInfoList = {}
    local attrList = { Atk, maxHp, Def, Speed, heroInitCritRatio, heroInitHit }
    for i, v in pairs(UISagaBookDetail.BASE_KEY_LIST) do
        local attrRef = gModelHero:GetAttributeRefById(v)
        local powerHero = attrRef.powerHero
        local value = attrList[i]
        local attrName = ccLngText(attrRef.name)
        table.insert(attrInfoList, {
            refId = v,
            numType = attrRef.numType,
            value = value,
            saveNum = attrRef.saveNum,
        })
    end

    self:SetWndClick(self.mHBStarPreBtn, function()
        --gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-1-1-2",refId,haveHero,0)
        --local index = self._heroBookKeyList and self._heroBookKeyList[refId]
        --if not index then
        --	for i, v in ipairs(self._heroList) do
        --		if v == refId then
        --			index = i
        --			break
        --		end
        --	end
        --end
        --gModelGeneral:OpenHeroStarPreNew({ refId = refId, list = self._heroList or {}, index = index, func = function(curHeroRefId)
        --	if curHeroRefId ~= refId then
        --		self:RefreshHeroBookView(curHeroRefId)
        --	end
        --end})
        local heroListData = self:CheckWearHeroList(refId) -- 判断是否有该类型的英雄
        gModelGeneral:OpenHeroSkin({ refId = refId, isFromBook = true })
        --gModelGeneral:OpenHeroSkin({ refId = refId ,  preview = true})
    end)

    self:CreateBaseAttrList(attrInfoList)

    local effectId = starRef.effectId
    local effRef = gModelHero:GetShowEffectById(effectId)

    local showSkin = gModelHeroExtra:CheckIsOpenSkin()
    if showSkin then
        local skinType = effRef.skinType
        showSkin = skinType and skinType > 0
    end
    CS.ShowObject(self.mHBStarPreBtn, showSkin)

    self:SetWndEasyImage(self.mHeroIconImg, effRef.icon)

    if star > 10 then
        CS.ShowObject(self.mStarList, false)
        CS.ShowObject(self.mHightStarNewHeroInfo, true)
        CS.ShowObject(self.mHightStarNewHeroInforText, true)
        self:SetWndText(self.mHightStarNewHeroInforText, star - 10)
    else
        CS.ShowObject(self.mStarList, true)
        CS.ShowObject(self.mHightStarNewHeroInfo, false)
        CS.ShowObject(self.mHightStarNewHeroInforText, false)
        self:CreateStarList(star)
    end

    local quality = heroRef.quality
    local heroName = ccLngText(effRef.name)
    self:SetWndText(self.mHeroName, heroName)

    self:SetWndText(self.mChaNumTxt, ccLngText(effRef.location))

    local qualityRef = gModelItem:GetQualityRef(quality)

    --self:SetWndEasyImage(self.mNameBg, qualityRef.heroMsgNameBg)
    --self:SetWndEasyImage(self.mHeroQuaImg, qualityRef.heroMsgNameBg)
    self:RefreshSkillList(star, grade)

    local nickName = ccLngText(effRef.nickName)
    self:SetWndText(self.mNickName, nickName)
    self:SetXUITextTransColor(self.mNickName, qualityRef.nameColor)

    local qualityIcon = heroRef.qualityIcon
    self:SetWndEasyImage(self.mHeroZZImg, qualityIcon, function()
        CS.ShowObject(self.mHeroZZImg, true)
    end)
end

function UISagaBookDetail:SetStaicContent()

    self:SetWndText(self.mTxtClose, ccClientText(30205))
    self:SetWndText(self.mG2Txt1, ccClientText(10122))
    self:SetWndText(self.mLvTxt, ccClientText(19769))
    self:SetWndText(self.mRaceTypeTxt, ccClientText(19770))
    self:SetWndText(self.mCareerTxt, ccClientText(19771))
    self:SetWndText(self.mChaTxt, ccClientText(19772))
    self:SetWndText(self.mAwakeBtnTitle, ccClientText(20137))

    self:SetWndText(self.mCloseMaxTxt, ccClientText(19768))

    self:SetWndText(self.mHBWayBtnTitle, ccClientText(19714))
    self:SetWndText(self.mHBPinlunBtnTitle, ccClientText(19717))
    self:SetWndText(self.mHBStarPreBtnTitle, ccClientText(20102))
    self:SetWndText(self.mHBInteractBtnTitle, ccClientText(41303))
    self:SetWndText(self.mHBSkinBtnTitle, ccClientText(19718))

    if self._isEnus then
        self:InitTextCharacterWithLanguage(self.mHBWayBtnTitle, 9.3)
        self:InitTextCharacterWithLanguage(self.mHBPinlunBtnTitle, 9.3)
        self:InitTextCharacterWithLanguage(self.mHBStarPreBtnTitle, 9.3)
        self:InitTextCharacterWithLanguage(self.mHBInteractBtnTitle, 9.3)
        self:InitTextCharacterWithLanguage(self.mHBSkinBtnTitle, 9.3)
        self:InitTextCharacterWithLanguage(self.mHBShopBtnTitle, 9.3)
    end

    if self._isJapaness then
        LxUiHelper.SetSizeWithCurAnchor(self.mHBInteractBtnTitle, 0, 80)
        local textTran = LxUiHelper.FindXTextCtrl(self.mHBInteractBtnTitle)
        textTran.enableWordWrapping = true
        self:InitTextLineWithLanguage(self.mHBInteractBtnTitle,-50)
        self:SetAnchorPos(text,Vector2.New(0,-25))
    end

    self:SetWndText(self.mTipMoreTxt, ccClientText(19781))

    self:SetWndText(self.mLockTxt1, ccClientText(19730))
    self:SetWndText(self.mLockTxt2, ccClientText(19731))

    self:SetWndText(self.mKeZhiGuanXiTxt, ccClientText(10080))

    self:SetWndButtonText(self.mBtnGift, ccClientText(41314))
    self:SetWndButtonText(self.mBtnOneGift, ccClientText(41315))
    self:SetWndClick(self.mObjSilder, function()
        GF.OpenWnd("UIFavorabilityPrivilege", { heroRefId = self._heroRefId })
    end)

    self:SetWndText(self.mRewardGet, ccClientText(10191))
end

function UISagaBookDetail:SetTabRedPoint(btnTrans, isShow)
    local redPoint = self:FindWndTrans(btnTrans, "redPoint")
    CS.ShowObject(redPoint, isShow)
end

function UISagaBookDetail:OnPlayEffect(addExp)
    self:CreateWndEffect(self.mUIEffect, "fx_haogandu_tisheng", "fx_haogandu_tisheng", 100, nil, nil, nil, nil, nil, true, nil, function()
        self._delayCloseTimer = LxTimer.DelayTimeCall(function()
            self:CreateWndEffect(self.mUIEffBullet, "fx_haogandu_tisheng_bullet", "fx_haogandu_tisheng_bullet", 100, nil, nil, nil, nil, nil, true, nil, function()
                local sizeDe = self.mUIEffBullet.transform.localPosition
                sizeDe.x = 210
                sizeDe.y = -215
                self.mUIEffBullet.transform.localPosition = sizeDe
                local toPos = self.mItemLove.transform.localPosition
                local canvasGroup = self.mTxtAddExp:GetComponent(typeofCanvasGroup)
                self.effectTween = YXTween.TweenSequenceIns()
                self.effectTween:Append(self.mUIEffBullet.transform:DOLocalMove(toPos, 0.5))
                self.effectTween:AppendCallback(function()
                    self:CreateWndEffect(self.mItemLove, "fx_haogandu_tisheng_hit", "fx_haogandu_tisheng_hit", 100, nil, nil, nil, nil, nil, true, nil, function()
                        if self.params then
                            if self.params.isTotal and not self.params.isPrivilege then
                                GF.OpenWnd("UIFavorabilityUpLvPop")
                                --播放總好感度升級音效
                            end
                            if self.params.isPrivilege then
                                GF.OpenWnd("UIFavorabilityPrivilegePop", { heroRefId = self.params.heroRefId, isTotalPop = self.params.isTotal })
                                --播放好感度升級音效
                            end
                            self.params = nil
                        end
                        self:OnUpdateEffectLove()

                        self:SetWndText(self.mTxtAddExp, addExp and "+" .. addExp or "")
                        local pos = self.mTxtAddExp.anchoredPosition
                        pos.y = 430
                        self.mTxtAddExp.anchoredPosition = pos
                        canvasGroup.alpha = 1
                    end, 7)
                    -- self.effectTween = nil
                end)

                self.effectTween:Append(self.mTxtAddExp:DOAnchorPosY(450, 1.2))
                self.effectTween:Insert(0.7, canvasGroup:DOFade(0, 1))
                self.effectTween:OnComplete(function()
                    local tisheng = self:FindWndEffectByKey("fx_haogandu_tisheng")
                    if tisheng then
                        tisheng:SetVisible(false)
                    end
                    local hit = self:FindWndEffectByKey("fx_haogandu_tisheng_hit")
                    if hit then
                        hit:SetVisible(false)
                    end
                end)
                self.effectTween:PlayForward()
            end, 7)
            LxTimer.DelayTimeStop(self._delayCloseTimer)
            self._delayCloseTimer = nil
        end, 0.4)
    end, 7)
end

function UISagaBookDetail:OnUpdateEffectLove()
    local curTotalLv = gModelHero._loveTotalLevel
    local totalRef = GameTable.CharacterFavorabilityAttrRef[curTotalLv + 1]
    local nexTotalExp = totalRef and totalRef.exp or GameTable.CharacterFavorabilityAttrRef[curTotalLv].exp
    self:SetWndText(self.mTxtTotalProgress, gModelHero._loveTotalValue .. "/" .. nexTotalExp)

    self:CreateWndEffect(self.mEffectLove, "fx_haogandu_yeti", "haogandulove_yeti", 100, nil, nil, nil, nil, nil, true, nil, nil, 7)
    self:CreateWndEffect(self.mItemLove, "fx_haogandu", "haogandulove", 100, nil, nil, nil, nil, nil, true, nil, function()
        if not self._rendererList then
            local rendererList = self.mEffectLove:GetComponentsInChildren(typeofRenderer, true)
            self._rendererList = rendererList:ToTable()
        end-- 初0.25
        local temp = (gModelHero._loveTotalValue / nexTotalExp) * 0.4
        for k, v in ipairs(self._rendererList) do
            local material = v.material
            if material then
                material.mainTextureOffset = Vector2(0, 0.26 - temp)
            end
        end
    end, 7)
end

function UISagaBookDetail:CutHero(optNum)


    local heroBookList = self._heroList
    if not heroBookList then
        return
    end
    local heroBookKeyList = self._heroKeyList
    if not heroBookKeyList then
        return
    end
    local curRefId = self._heroRefId
    if not curRefId then
        return
    end
    local curIdx = heroBookKeyList[curRefId]
    if not curIdx then
        return
    end
    local newIdx = curIdx + optNum
    local len = #heroBookList
    if newIdx < 1 then
        newIdx = len
    elseif newIdx > len then
        newIdx = 1
    end
    local newRefId = heroBookList[newIdx]
    if newRefId then
        --self:CheckQMJDCanUp(newRefId)
        self._curForm = 0
        self:RefreshHeroBookView(newRefId)
    end
end

function UISagaBookDetail:UpdateG5()
    self:ShowRewardList()
    self:SetWndText(self.mTxtFavor, ccClientText(41305))
    local loveLevel = gModelHero:GetHeroLoveLvByRefId(self._heroRefId)
    local curLv = loveLevel or 0
    self.curLv = curLv
    self:SetWndText(self.mTxtLove, curLv)
    self:OnUpdateProgressTxt()
    local nexRef = GameTable.CharacterFavorabilityRef[curLv + 1]
    local fullLv = not nexRef
    local curTotalLv = gModelHero._loveTotalLevel
    self:SetWndText(self.mTxtTotalLv, curTotalLv)

    local Favor = GameTable.CharacterRef[self._heroRefId].maxFavorability
    local isRef = gModelHero:GetFavorabilityGiftRed(self._heroRefId)
    local interactIsOpen = gModelFunctionOpen:CheckIsOpened(21002100)
    local hasHeros = gModelHero:IsActiveHeroEffRefId(self._heroRefId)
    local heroType = GameTable.CharacterEffectRef[self._heroRefId].heroType
    local noInteract,hasActive = gModelHero:GetHeroEffectListByRefId(heroType,true)
    CS.ShowObject(self.mLoveRedPoint, isRef)
    CS.ShowObject(self.mTxtProgress, not fullLv)
    CS.ShowObject(self.mImgFull, fullLv)
    CS.ShowObject(self.mHBInteractBtn, hasHeros and interactIsOpen and Favor and Favor > 0 and noInteract and hasActive)
    CS.ShowObject(self.mBtnGift, not fullLv)
    CS.ShowObject(self.mBtnOneGift, not fullLv)
    self:SetWndClick(self.mHBInteractBtn, function()
        GF.OpenWnd("UIFavorabilityInteract", { heroRefId = self._heroRefId })
    end)
    self:SetWndClick(self.mItemTips, function()
        CS.ShowObject(self.mItemTips, false)
    end)
    self:UpdateInteractBtnRed()
end

function UISagaBookDetail:RefreshAwakenTree()
    local treeRefId = self._treeRefId
    if not self._treeRefId then
        return
    end

    local treeRef = gModelHero:GetHeroTreeRef(treeRefId)
    if not treeRef then
        printInfoNR("GameTable.CharacterTreeRef[refId] is a nil, refId = " .. treeRefId)
        return
    end

    local treePbName = treeRef.treePb
    self._treePbName = treePbName
    local awakenTreeList = self._awakenTreeList

    local awakenTreeTrans = awakenTreeList[treePbName]
    if not awakenTreeTrans then
        self:CreateWndPrefab(self.mAwakenTree, treePbName, treePbName, function(prefabTrans)
            self._awakenTreeList[treePbName] = prefabTrans
            self:CreateAwakenTree(prefabTrans, treePbName)
        end, CS.RES_UI_HERO_AWAKEN_TREE)
    else
        self:CreateAwakenTree(awakenTreeTrans, treePbName)
    end

    for k, v in pairs(awakenTreeList) do
        CS.ShowObject(v, k == treePbName)
    end
end

function UISagaBookDetail:SetPlayBtnState(btn, isPlaying)
    local On = self:FindWndTrans(btn, "On")
    local Off = self:FindWndTrans(btn, "Off")
    local Title = self:FindWndTrans(btn, "Title")

    CS.ShowObject(On, isPlaying)
    CS.ShowObject(Off, not isPlaying)

    local str = isPlaying and 19783 or 19782

    if gLGameLanguage:IsJapanRegion() then
        str = ""
    else
        str = ccClientText(str)
    end

    self:SetWndText(Title, str)
end

function UISagaBookDetail:CreateAwakenSkillItemList(list)
    local uiSkillList = self._uiAwakenSkillList
    if uiSkillList then
        uiSkillList:RefreshList(list)
    else
        uiSkillList = self:GetUIScroll("uiAwakenSkillList")
        self._uiAwakenSkillList = uiSkillList
        uiSkillList:Create(self.mAwakenSkillList, list, function(...)
            self:OnDrawAwakenSkillCell(...)
        end)
    end
end

function UISagaBookDetail:OnDrawVoiceCell1(list, item, itemdata, itempos)
    local PlayerHeadGroup = self:FindWndTrans(item, "PlayerHeadGroup")
    local HeadBg = self:FindWndTrans(PlayerHeadGroup, "HeadBg")
    local HeadIcon = self:FindWndTrans(PlayerHeadGroup, "HeadIcon")
    local RoleName = self:FindWndTrans(PlayerHeadGroup, "RoleName")
    local heroRef = GameTable.CharacterRef[self._heroRefId]
    self:SetWndEasyImage(HeadBg, "public_item_bg_" .. heroRef.quality)
    self:SetWndEasyImage(HeadIcon, itemdata.icon, function()
        CS.ShowObject(PlayerHeadGroup, true)
    end)

    local PlayBtn = self:FindWndTrans(item, "PlayBtn")
    local RoleRefText = self:FindWndTrans(PlayBtn, "RoleRefText")
    local TxtCvName = self:FindWndTrans(PlayBtn, "GameObject/TxtCvName")
    local ImgHorn0 = self:FindWndTrans(PlayBtn, "ImgHorn0")
    local ImgHorn1 = self:FindWndTrans(PlayBtn, "ImgHorn1")
    local BtnTranslate = self:FindWndTrans(PlayBtn, "GameObject/BtnTranslate")
    local TxtBtnTrans = self:FindWndTrans(PlayBtn, "GameObject/BtnTranslate/TxtBtnTrans")
    self:SetWndText(TxtCvName, itemdata.cvName)
    self:SetWndText(TxtBtnTrans, ccClientText(41640))
    self:SetWndText(RoleRefText, itemdata.text)
    local hasPlay = self._isPlayVoiceId ~= nil

    self:SetPlayBtnState(PlayBtn, hasPlay and self._isPlayVoiceId == itemdata.voice)
    CS.ShowObject(BtnTranslate, not not itemdata.txtDesc)
    self:SetWndText(RoleName, itemdata.name)

    self:SetWndClick(PlayBtn, function()
        if not itemdata.islock then
            return
        end
        local old = self._isPlayVoiceId ~= nil and self._isPlayVoiceId
        local oldItemBtn = self._isPlayVoiceItemBtn ~= nil and self._isPlayVoiceItemBtn
        if old and old == itemdata.voice then
            -- self:SetPlayBtnState(PlayBtn, false)
            gLGameAudio:StopSingleSound();
            self._isPlayVoiceId = nil
            self._isPlayVoiceItemBtn = nil
            self:TimerStop(self._checkIsPlayingTimerKey)
            CS.ShowObject(self.ImgHorn0, true)
            CS.ShowObject(self.ImgHorn1, true)
            return
        end

        local isMute = gLGameAudio:IsSingleSoundMute() or gLGameAudio:GetSingleSoundVolume() <= 0
        if isMute then
            GF.ShowMessage(ccClientText(19785))
            return
        end
        self.isClickSound = true
        self._isPlayVoiceId = itemdata.voice
        self._isPlayVoiceItemBtn = PlayBtn
        if old then
            -- self:SetPlayBtnState(oldItemBtn, false)
        end
        -- self:SetPlayBtnState(PlayBtn, true)
        self._checkSingleTime = 1
        gLGameAudio:PlaySingleSound(itemdata.voice, function()
            if self:IsWndClosed() then
                gLGameAudio:StopSingleSound();
                CS.ShowObject(self.ImgHorn0, true)
                CS.ShowObject(self.ImgHorn1, true)
                return
            end
            self.ImgHorn0 = ImgHorn0
            self.ImgHorn1 = ImgHorn1
            self.countTime = 0
            self:TimerStart(self._checkIsPlayingTimerKey, 0.4, false, -1)
            self:DoTweenHorn(true, ImgHorn0, ImgHorn1)
        end)
        printInfoNR2("播放音乐", itemdata.voice)
    end)

    self:SetWndClick(BtnTranslate, function()
        -- local panelRect = PlayBtn:GetWorldCorners()
        -- local leftB = PlayBtn:InverseTransformPoint(panelRect[0])
        -- local rightT = PlayBtn:InverseTransformPoint(panelRect[2])

        -- local finalPos = self.mG3:TransformPoint(Vector3(leftB.x, rightT.y, 0))
        self.mItemTips.position = PlayBtn.position
        local locallPos = self.mItemTips.anchoredPosition
        self:SetAnchorPos(self.mItemTips, Vector3.New(locallPos.x, locallPos.y + 23, locallPos.z))
        self:SetWndText(self.mTxtTranslate, itemdata.txtDesc)
        CS.ShowObject(self.mItemTips, true)

    end)

end

function UISagaBookDetail:SetHightStateHeroLihui(effId, showUnLockDesBg)
    local effectRef = gModelHero:GetShowEffectById(effId)
    if not effectRef then
        CS.ShowObject(self.mHeroLihui, false)
        return
    end
    self:CreateHightStateHero(effectRef, showUnLockDesBg)
    --- 2024/5/30：不需要偏移
    --self:ChangHeroLiPos(self.mHeroLihui, effId)
    --self:ChangHeroLiPos(self.mHeroLiHuiBgPos, effId)
end

function UISagaBookDetail:CreateAwakenAttrItemList(attrList)
    local uiAwakenAttrList = self._uiAwakenAttrList
    if uiAwakenAttrList then
        uiAwakenAttrList:RefreshList(attrList)
    else
        uiAwakenAttrList = self:GetUIScroll("uiAwakenAttrList")
        self._uiAwakenAttrList = uiAwakenAttrList
        uiAwakenAttrList:Create(self.mAwakenAttrList, attrList, function(...)
            self:OnDrawAwakenAttrCell(...)
        end)
    end

    uiAwakenAttrList:EnableScroll(#attrList > 3, false)
end

function UISagaBookDetail:OnDrawStarCell(list, item, itemdata, itempos)
    local Star = self:FindWndTrans(item, "Star")
    if Star then
        local actStar = not itemdata.actStar
        self:SetWndImageGray(Star, actStar)
    end
end

function UISagaBookDetail:GetisEmptySkinVoice()

    local starRef = gModelHero:GetHeroStarById(self._starId)
    local orginSkinRef = GameTable.CharacterEffectRef[starRef.effectId]
    if (not orginSkinRef) then
        return false
    end
    if not orginSkinRef.RoleRef then
        return false
    end

    return true
end

function UISagaBookDetail:InitCommon()

    CS.ShowObject(self.mUpG, false)

    self._ShowTab = {}

    self._heroRefId = self:GetWndArg("heroRefId")

    local isShowHeroAwaken = gModelHero:CheckHeroIsCanAwaken(self._heroRefId)
    --ModelHero:GetPreHeroTreeMaxLv(heroRefId)
    if isShowHeroAwaken then
        local curAllLv, maxLv = gModelHero:GetPreHeroTreeMaxLv(self._heroRefId)
        self:SetWndText(self.mHBHeroTreeBtnTitle, string.replace(ccClientText(20150), curAllLv, maxLv))
    end
    CS.ShowObject(self.mHBHeroTreeBtn, isShowHeroAwaken)
    self:SetWndText(self.mHBShopBtnTitle, ccClientText(10362))

    --- 整个英雄是否解锁
    self._isAct = gModelHeroBook:FindHeroInfoStatusByHeroRefId(self._heroRefId)

    self._heroList = self:GetWndArg("heroList")
    self._heroKeyList = self:GetWndArg("heroKeyList")
    self._curForm = self:GetWndArg("form") or 0

    local showTab = self:GetWndArg("showTab") or false

    local selectIndexId = self:GetWndArg("selectIndex") or 1
    local heroRef = GameTable.CharacterEffectRef[self._heroRefId]
    self._lockVoice = not string.isempty(heroRef.RoleRef) and gModelFunctionOpen:CheckIsOpened(10303005, false)

    -- CS.ShowObject(self.mTab1, showTab)
    -- CS.ShowObject(self.mTab2, showTab)

    -- CS.ShowObject(self.mTabVoice, showTab and self._lockVoice)

    local only = not self._heroList or #self._heroList < 2
    self._isOnly = only
    CS.ShowObject(self.mCurLeftBtn, not only);
    CS.ShowObject(self.mCurRightBtn, not only);

    self._awakenTreeList = {}
    self._awakenTreeTransList = {}
    self:RefreshHeroBookView(self._heroRefId)

    local indexId = showTab and self._tab2Red and 2 or 1
    if selectIndexId > 1 then
        indexId = selectIndexId
    end

    --self:OnClickTab(indexTab)
    CS.ShowObject(self.mHBSkinBtn, false)

    self:ChangeShowOrHideBtnState()
    self._ShowTab[1] = showTab
    self._ShowTab[2] = showTab
    self._ShowTab[3] = showTab and self._lockVoice
    self._ShowTab[4] = showTab
    self._ShowTab[5] = showTab and self:isShowTab5()

    --self:OnClickTab(1)

    self:InitTabData(indexId)
end

function UISagaBookDetail:UpdateSelectTabBtn()
    local itemData = self._showTabData[self._tabIndex]
    local item = self._tabList[self._tabIndex]
    if itemData and itemData.indexId == 5 then
        local redpoit = self:FindWndTrans(item, "redPoint")
        CS.ShowObject(redpoit, gModelHero:GetFavorabilityGiftRed(self._heroRefId))
    end
end
function UISagaBookDetail:InitTabData(indexId)
    local showTab4 = false
    local tempList = gModelHeroExtra:GetPolymorphismNew(self._heroRefId)
    local hasPolymorphism = tempList and #tempList > 0
    if hasPolymorphism then
        showTab4 = true
        self._heroHightStates = {}
        for k, v in ipairs(tempList) do
            table.insert(self._heroHightStates, v)
        end
    end
    self._ShowTab[4] = showTab4 and self._ShowTab[4]
    local tabDatas = {
        { onIcon = "herobook_tab5", offIcon = "herobook_tab5", name = 19777, indexId = 1 }, --- 介紹
        { onIcon = "herobook_tab4", offIcon = "herobook_tab4", name = 19776, indexId = 2 }, --- 資訊
        -- { onIcon = "herobook_tab3", offIcon = "herobook_tab3", name = 19780, indexId = 3 }, --- 語錄
        { onIcon = "herobook_tab1", offIcon = "herobook_tab1", name = 41647, indexId = 5 }, --- 贈送
    }

    local hasHeros = gModelHero:GetRefIdTypeList(self._heroRefId)
    if hasHeros and hasPolymorphism then
        --- 形態
        table.insert(tabDatas, { onIcon = "herobook_tab2", offIcon = "herobook_tab2", name = 20171, indexId = 4 })
    end

    table.sort(tabDatas, function(a, b)
        return a.indexId < b.indexId
    end)
    self._tabDatas = tabDatas

    self._showTabData = {}
    self._tabList = {}
    local tabIndex = 1
    for k, v in ipairs(tabDatas) do
        local isCanInsert =true

        if gLGameLanguage:IsJapanRegion() then
            if PRODUCT_G_VER~=0 then
                if v.indexId ==2 or v.indexId == 5 then
                    isCanInsert =false
                end
            end
        end

        if self._ShowTab[v.indexId] and isCanInsert then
            table.insert(self._showTabData, v)
            if indexId == v.indexId then
                tabIndex = #self._showTabData
            end
        end
    end

    self:InitTabList()

    self:OnClickTab(tabIndex)
end

function UISagaBookDetail:OnHeroBookAddCloseResp(pb)
    if self._heroRefId ~= pb.heroRefId then
        return
    end

    local canUp = gModelHeroBook:CheckBookInfoStatusByRefId(self._heroRefId)
    if canUp then
        FireEvent(EventNames.ON_HERO_CHAIN_CAN_UP)
    end
end
function UISagaBookDetail:UseGiveGift()
    local itemId = self.selectGift
    if not self.selectGift then
        local costStr = GameTable.CharacterRef[self._heroRefId].favorabilityGIft
        local costItem = string.split(costStr, ",")
        itemId = tonumber(costItem[#costItem])
    end
    local curNum = gModelItem:GetNumByRefId(itemId)
    if curNum <= 0 then
        local itemRef = GameTable.PlayerItemRef[itemId]
        if itemRef.jump ~= "" then
            gModelGeneral:OpenGetWayWnd({ itemId = itemRef.refId })
        else
            GF.ShowMessage(ccClientText(41642))
        end
        return
    end
    gModelHeroExtra:OnHeroGiveGiftReq(self._heroRefId, { { _refId = self.selectGift, _num = 1 } })
end

function UISagaBookDetail:GetDefaultSelectTreePoint()
    local treeRefId = self._treeRefId
    local treeRef = gModelHero:GetHeroTreeRef(treeRefId)
    local bigRefId = treeRef.initPoint
    return bigRefId
end

function UISagaBookDetail:InitTabList()
    local uiList = self:GetUIScroll("UISagaBookDetailTab")
    uiList:Create(self.mTabScroll, self._showTabData, function(...)
        self:OnDrawTab(...)
    end)
    self._tabUiList = uiList
end

function UISagaBookDetail:PlayEffShow(upNum)
    local seqTween
    self:TweenSeqKill(self._effectKey)
    local pos = self.mShowUpTxt.localPosition
    local effKey = "fx_qinmijindu"
    if not seqTween then
        seqTween = self:TweenSeqCreate(self._effectKey, function(seq)

            self:CreateWndEffect(self.mBarEff, "fx_qinmijindu", effKey, 100, nil, nul, 50)
            seq:AppendInterval(1.1)

            seq:AppendCallback(function()
                CS.ShowObject(self.mShowUpTxt, true)
            end)

            local alphaTime = 0.5
            local Ease = DG.Tweening.Ease.OutCubic

            local str = string.format("+%s", upNum)
            self:SetWndText(self.mShowUpTxt, str)

            local newCanvasGroup = self.mShowUpTxt:GetComponent(typeofCanvasGroup)
            if newCanvasGroup then
                local _temp = YXTween.TweenFloat(0, 1, alphaTime, function(ival)
                    newCanvasGroup.alpha = ival
                end)                 :SetEase(Ease)
                seq:Append(_temp)
            end
            seq:AppendInterval(0.5)

            local tween = self.mShowUpTxt:DOLocalMoveY(30, alphaTime)
            seq:Join(tween)
            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        self:TweenSeqKill(self._effectKey)
        self.mShowUpTxt.localPosition = pos
        CS.ShowObject(self.mShowUpTxt, false)
        self:DestroyWndEffectByKey(effKey)
    end)
end

function UISagaBookDetail:CheckGuide()
    if gModelHero:IsOpenInteractCloseUp(self._heroRefId) then
        FireEvent(EventNames.ON_HERO_SP_UNLOCK, self._heroRefId)
    end
end

function UISagaBookDetail:ShowRaecKeZhiInfo()
    local canvasRect = LGameUI.GetUICanvasRoot()
    if not self._changePos then
        local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect, self.mTypeImgMask)
        self.mTypeImgMask.localPosition = targetPos - Vector3.New(0, 25, 0)
        self._changePos = true
    end
    local refId = self._heroRefId
    local raceType = gModelHero:GetHeroType(refId)
    if raceType then
        local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
        if raceRef then
            local restrainDetailsEff = raceRef.restrainDetailsEff
            local isEmpty = string.isempty(restrainDetailsEff)
            local str = ""
            if not isEmpty then
                local heroRaceImage = raceRef.heroRaceImage
                self:SetWndEasyImage(self.mTypeKeZhiImg, heroRaceImage, function()
                    CS.ShowObject(self.mTypeKeZhiImg, true)
                end, true)
            else
                CS.ShowObject(self.mTypeKeZhiImg, not isEmpty)
                str = ccClientText(31233)
            end
            CS.ShowObject(self.mTypeKZImgDiv, not isEmpty)
            CS.ShowObject(self.mNoHaveKeZhiTxtDiv, isEmpty)

            local name = string.replace(ccClientText(10079), ccLngText(raceRef.name))
            self:SetWndText(self.mRaceTypeName, name)

            self:SetWndText(self.mNoHaveKeZhiTxt, str)
        end
    end
end

function UISagaBookDetail:UpdateStory(toIndex)
    local serverData = gModelHeroBook:GetHeroInfoByHeroRefId(self._heroRefId)
    if not serverData then
        return
    end
    local storyIndex = self._storyIndex
    local data = self._storyData[storyIndex]
    local isActive = serverData.isActive

    if toIndex then
        self._storyIndex = 1
        for k, v in pairs(self._storyData) do
            local got = serverData.storyRewardsKey[v.refId] ~= nil
            local islock = true
            if serverData.heroMaxStar then
                islock = serverData.heroMaxStar >= v.needStar
            end
            if isActive and not got and islock and v.reward then
                storyIndex = tonumber(k)
                self._storyIndex = tonumber(k)
                break
            end
        end
    end

    self._storyIndex = storyIndex


    --这里进行数据构建先
    --CS.ShowObject(self.mStoryRoot, true)
    --for storykey, stroyvalue in ipairs(self._storyData) do
    --
    --    local isCanShow = (storykey == 1 or isActive  or stroyvalue.needStar==0)
    --
    --    if isCanShow then
    --        self:RefreshStoryContent(stroyvalue, serverData.heroMaxStar, storykey, isActive)
    --    end
    --    --
    --end
    local loveLevel = gModelHero:GetHeroLoveLvByRefId(self._heroRefId)
    self.curLv = loveLevel or 0
    local loveCfg = GameTable.CharacterFavorabilityRef[self.curLv]
    local unlockStoryNum = loveCfg.unlockStoryNum
    if  not string.isempty(unlockStoryNum) then
        self.unlockStoryNum = string.split(unlockStoryNum,"|")
    end
    --故事列表构建
    local itemList = self._uistoryList
    --if itemList then
    --    itemList:RefreshList(self._storyData)
    --    itemList:DrawAllItems(true)
    --else
    --    itemList = self:GetUIScroll("mPVEList")
    --    itemList:Create(self.mStoryList, self._storyData, function(...)
    --        self:RefreshStoryContent(...)
    --    end)
    --
    --    self._uistoryList = itemList
    --end


    if not itemList then
        itemList = UIListEasy:New()
        itemList:Create(self, self.mStoryList_New)
        itemList:SetFuncOnItemDraw(function(...)
            self:RefreshStoryContent(...)
        end)
        self._uistoryList = itemList
        itemList:EnableScroll(true, false)


    end
    itemList:RemoveAll()
    for i, v in ipairs(self._storyData) do
        itemList:AddData(i, v)
    end
    itemList:RefreshList()

    CS.ShowObject(self.mStoryList_New, true)

    LayoutRebuilder.ForceRebuildLayoutImmediate(self.mStoryList_New)

    --是否显示钻石
    local rewardStoryData = nil
    for k, v in pairs(self._storyData) do
        local got = serverData.storyRewardsKey[v.refId] ~= nil
        local islock = true

        if serverData.heroMaxStar then
            islock = serverData.heroMaxStar >= v.needStar
        end

        rewardStoryData = v

        if not got and not string.isempty(v.reward) then
            -- 未领取的
            break
        end
        if not islock then
            --未达到亲密度的
            break
        end
    end

    local rewardData = rewardStoryData and rewardStoryData.reward
    local got = rewardStoryData and serverData.storyRewardsKey[rewardStoryData.refId] ~= nil
    local showReward = not string.isempty(rewardData) and isActive and not got
    local rewardItem = self.mReward
    CS.ShowObject(rewardItem, showReward)
    CS.ShowObject(self.mRewardGet, showReward)

    self._tab2Red = self._canUp
    -- self:SetTabRedPoint(self.mTab2, self._tab2Red)

    if showReward then
        local itemIcon = self._rewardItem
        if not self._rewardItem then
            itemIconNew = CommonIcon:New()
            self._rewardItem = itemIconNew
            itemIconNew:Create(rewardItem)
            itemIcon = self._rewardItem
        end
        local rewardDataArr = string.split(rewardData, "=")
        local refId = tonumber(rewardDataArr[2])
        local num = tonumber(rewardDataArr[3])
        itemIcon:SetCommonReward(LItemTypeConst.TYPE_ITEM, refId, num)
        itemIcon:DoApply()

        local islock = true

        if serverData.heroMaxStar then
            islock = serverData.heroMaxStar >= rewardStoryData.needStar
        end

        local canGet = isActive and not got and islock
        self._tab2Red = self._canUp or canGet
        itemIcon:ShowLock(not canGet)
        CS.ShowObject(self.mRewardRedPoint, canGet)

        local G2Txt1Str = ""
        if canGet then
            G2Txt1Str = ccClientText(10122)
        else
            G2Txt1Str = string.replace(ccClientText(19767), rewardStoryData.needStar)
        end
        self:SetWndText(self.mG2Txt1, G2Txt1Str)

        self:SetWndClick(rewardItem, function()
            local data = rewardStoryData
            if not data or not canGet then

                local itemdata = {
                    itemType = rewardStoryData.rewardList[1].itemType,
                    itemId = rewardStoryData.rewardList[1].itemRefId,
                    itemNum = rewardStoryData.rewardList[1].itemNum,
                    isShowEff = "1",
                }
                gModelGeneral:ShowCommonItemTipWnd(itemdata)
                return ;
            end
            self._isStoryClickGetReward = true
            gModelHeroBook:OnHeroBookRewardReq(self._heroRefId, data.refId)
        end)

        self:SetWndClick(self.mRewardGet, function()
            local data = rewardStoryData
            if not data or not canGet then
                local itemdata = {
                    itemType = rewardStoryData.rewardList[1].itemType,
                    itemId = rewardStoryData.rewardList[1].itemRefId,
                    itemNum = rewardStoryData.rewardList[1].itemNum,
                    isShowEff = "1",
                }
                gModelGeneral:ShowCommonItemTipWnd(itemdata)
                return ;
            end
            self._isStoryClickGetReward = true
            gModelHeroBook:OnHeroBookRewardReq(self._heroRefId, data.refId)
        end)
    else
        CS.ShowObject(self.mRewardRedPoint, false)
    end

    --local strotyL = self.mStoryLeftBtn
    --local strotyR = self.mStoryRightBtn
    --CS.ShowObject(strotyL, storyIndex > 1)
    --CS.ShowObject(strotyR, storyIndex < #self._storyData)

    local ShowCharacterNum = loveCfg.spCharacter
    if not string.isempty(ShowCharacterNum) then
        ShowCharacterNum = string.split(ShowCharacterNum,"|")
    else
        ShowCharacterNum = nil
    end
    if ShowCharacterNum then
        local length = #ShowCharacterNum
        for i = 1, length do
            table.removeidata(ShowCharacterNum,"0")
        end
    end

    local showTxtNum = 0
    --左侧的属性部分  self._heroRefId
    --local heroRef = gModelHero:GetHeroRef(self._heroRefId)
    --local heroStoryType=heroRef.heroStory
    local character = self._storyData[1].character
    if not string.isempty(character) then
        local tempCharacter = string.split(ccLngText(character), "|")
        for characterKey, characterValue in ipairs(tempCharacter) do

            showTxtNum = showTxtNum + 1
            local isShow = self._storyData[1].needStar == 0 or isActive

            local showStr = isShow and characterValue or ccClientText(10189)
            local tempStr = ccClientText(self._storyCharacterTitle[characterKey]) .. "：" .. "<#ffffff>" .. showStr .. "</color>"
            self:SetWndText(self._storyCharacterTrans[characterKey], ccClientText(self._storyCharacterTitle[characterKey]))
            local showLockDiv = ShowCharacterNum and showTxtNum > #ShowCharacterNum or false
            CS.ShowObject(self.CharacterLockRootTrans[characterKey],showLockDiv)
            if showLockDiv then
                local LoveLevel = self:FindWndTrans(self.CharacterLockRootTrans[characterKey], "ImgLove/LoveLevel")
                local UnLockTxt = self:FindWndTrans(self.CharacterLockRootTrans[characterKey], "UnLockTxt")
                local levelTxt = gModelHeroBook:GetCharacterLevelByStoryNum(showTxtNum)
                self:SetWndText(LoveLevel, levelTxt)
                self:SetWndText(UnLockTxt, string.replace(ccClientText(41324),levelTxt))
            else
                local uitext = self:FindWndTrans(self._storyCharacterTrans[characterKey], "UIText")
                self:SetWndText(uitext, showStr)

                CS.ShowObject(self._storyCharacterRootTrans[characterKey], not string.isempty(tempStr))
            end


            --

        end
    else
        for k, v in ipairs(self._storyCharacterRootTrans) do
            CS.ShowObject(self._storyCharacterRootTrans[k], false)
        end
    end

end

function UISagaBookDetail:CreateLiHui(heroRefId)
    local heroRef = gModelHero:GetHeroRef(heroRefId)
    local starRef = gModelHero:GetHeroStarRef(heroRefId, self._curForm, heroRef.maxStar)
    local effId = starRef.effectId
    local effectRef = gModelHero:GetShowEffectById(effId)
    if not effectRef then
        CS.ShowObject(self.mHeroLiHuiPos, false)
        return
    end
    CS.ShowObject(self.mHeroLiHuiPos, true)
    if self._uiDrawingCtrl then
        self._uiDrawingCtrl:Destroy()
        self._uiDrawingCtrl = nil
    end
    local uiHeroLiHuiList = self._uiHeroLiHuiList
    if not uiHeroLiHuiList then
        uiHeroLiHuiList = {}
        self._uiHeroLiHuiList = uiHeroLiHuiList
    end
    local anim = "idle"
    local notHasHero = false

    local effRef = gModelHero:GetShowEffectById(effId)
    local heroType = effRef.heroType
    local isAct = gModelHeroBook:FindHeroInfoStatusByHeroRefId(heroType)
    if not isAct then
        local hasHeros = gModelHero:GetRefIdTypeList(self._heroRefId)
        if not hasHeros then
            notHasHero = true

            --- 2024/6/20：http://192.168.16.2:3002/issues/753
            anim = "calm"
        end
    end

    local action = nil
    local actionSound = nil
    local heroDrawing = effectRef.heroDrawing
    ---@type LUIHeroObject
    local newUILiHuiObj = uiHeroLiHuiList[heroDrawing]
    local oldUILiHuiObj = self._curUILiHuiObj
    if oldUILiHuiObj and newUILiHuiObj ~= oldUILiHuiObj then
        oldUILiHuiObj:ShowHero(false)
    end
    if not newUILiHuiObj then
        --local scale = effectRef.pos1Scale or UISagaBookDetail.Spine_Scale
        local scale = UISagaBookDetail.Spine_Scale
        newUILiHuiObj = LUIHeroObject:New(self)
        uiHeroLiHuiList[heroDrawing] = newUILiHuiObj
        self._curUILiHuiObj = newUILiHuiObj
        newUILiHuiObj:Create(self.mHeroLiHuiPos, heroDrawing, heroDrawing)
        newUILiHuiObj:SetHeroBgParams({
            effRef = effectRef,
            lihuiBgTrans = self.mHeroLiHuiBgPos,
            lihuiHdTrans = self.mHeroLiHuiHdPos,
        })
        newUILiHuiObj:SetLoadedFunction(function()
            newUILiHuiObj:PlayAni(anim, true)
            local _displaySpine = newUILiHuiObj:GetDpObject()
            if _displaySpine then _displaySpine:SetRaycastTarget(true) end
        end)
        newUILiHuiObj:SetDragFunc(function(...)
            --self:OnCutHero(...)
        end)
        newUILiHuiObj:SetClickFunc(function()
            if notHasHero then
                return
            end

            action = gModelHero:GetHeroClickAction(self._heroRefId)
            if action and action ~= "" then
                -- local spine = newUILiHuiObj:GetDisplaySpine()
                -- spine:SetAnimationCompleteFunc(function(ainName)
                --     if ainName == action then
                --         spine:PlayAnimation(0, "idle", true)
                --     end
                -- end)
                -- spine:PlayAnimation(0,action,false)
                newUILiHuiObj:PlayAni(action, false, nil, nil, true, LSpineAniConst.idle)
            end
            actionSound = gModelHero:GetHeroClickSound(self._heroRefId)
            if actionSound and actionSound ~= "" then
                gLGameAudio:StopSingleSound();
                gLGameAudio:PlaySingleSound(actionSound, function()
                end)
            end
        end)
        newUILiHuiObj:SetRectMatch(true)
        newUILiHuiObj:ShowHero(true)
        newUILiHuiObj:SetScale(scale)
        newUILiHuiObj:StartLoad()

        -- newUILiHuiObj:SetLoadedFunction(function()
        --     local spine = newUILiHuiObj:GetDisplaySpine()
        --     spine:SetAnimationCompleteFunc(function(ainName)
        --         if ainName == action then
        --             newUILiHuiObj:PlayAni("idle", true)
        --         end
        --     end)
        -- end)
    else
        self._curUILiHuiObj = newUILiHuiObj
        newUILiHuiObj:ShowHero(true)
    end
    local uiDrawCtrl = LUIDrawingCtrl:New()
    self._uiDrawingCtrl = uiDrawCtrl
    uiDrawCtrl:SetHeroObject(newUILiHuiObj)
    uiDrawCtrl:SetEffectInfo(self.mHeroLiHuEffiPos, 0, 3, 100)
    uiDrawCtrl:InitHeroEffectInfo(heroRefId)
    uiDrawCtrl:StartPlay()
    self:ChangHeroLiPos(self.mHeroLiHuiPos, effId)
end

function UISagaBookDetail:CreateLockQMDJList(dj)
    local list = {}
    for i = 1, dj do
        table.insert(list, { actStar = true })
    end
    local uiQMDJList = self._uiLockQMDJList
    if uiQMDJList then
        uiQMDJList:RefreshList(list)
    else
        uiQMDJList = self:GetUIScroll("uiLockQMDJList")
        self._uiLockQMDJList = uiQMDJList
        uiQMDJList:Create(self.mLockQmDJList, list, function(...)
            self:OnDrawStarCell(...)
        end)
    end
end

function UISagaBookDetail:InitData()
    self._storyCharacterTitle = {
        [1] = 10185, --屬性
        [2] = 10186, --性格
        [3] = 10187, --癖好
        [4] = 10188, --小秘密

        --10189  --未知
    }

    self._storyCharacterTrans = {
        [1] = self.mHero_Base_Info_1,
        [2] = self.mHero_Base_Info_2,
        [3] = self.mHero_Base_Info_3,
        [4] = self.mHero_Base_Info_4,
    }

    self._storyCharacterRootTrans = {
        [1] = self.mHero_Base_Info_Bg_1,
        [2] = self.mHero_Base_Info_Bg_2,
        [3] = self.mHero_Base_Info_Bg_3,
        [4] = self.mHero_Base_Info_Bg_4,
    }
    self.CharacterLockRootTrans = {
        [1] = self.mLockInfoDiv_1,
        [2] = self.mLockInfoDiv_2,
        [3] = self.mLockInfoDiv_3,
        [4] = self.mLockInfoDiv_4,
    }

end

function UISagaBookDetail:RefreshAwakenDetails()
    local treePointRefId = self._curSelectTreePointId
    if not treePointRefId then
        return
    end

    local heroTreePointInfo = self._heroTreeInfoList[treePointRefId]
    if not heroTreePointInfo then
        printInfoNR("self._heroTreeInfoList[treePointRefId] is a nil, treePointRefId = " .. treePointRefId)
        return
    end

    local lvRefId = heroTreePointInfo.lvRefId
    local nextLvRefId = heroTreePointInfo.nextLvRefId
    local pointType = heroTreePointInfo.pointType
    local lvList = heroTreePointInfo.lvList
    local isMaxLv = heroTreePointInfo.isMaxLv
    local maxLvListNum = #lvList
    local maxPointLvData = lvList[maxLvListNum]
    local maxPointLvRefId = maxPointLvData.refId
    local curPointLvRef = gModelHero:GetHeroTreePointLvRef(lvRefId)
    local nextPointLvRef = gModelHero:GetHeroTreePointLvRef(nextLvRefId)
    local maxPointLvRef = gModelHero:GetHeroTreePointLvRef(maxPointLvRefId)

    local isTryHero = self._isTryHero

    local curPointLv = curPointLvRef.lv
    local maxPointLv = maxPointLvRef.lv
    local titleStr = string.replace(ccClientText(20139), curPointLv, maxPointLv)
    self:SetWndText(self.mAwakenTitle, titleStr)

    -- 显示属性/技能
    if pointType == ModelHero.TREE_POINT_TYPE_ATTR then
        local curPointAttr = curPointLvRef.attr
        local nextPointAttr = nextPointLvRef and nextPointLvRef.attr or ""
        local attrList = gModelHero:GetAwakenTreePointAttrList(curPointAttr, nextPointAttr)
        self:CreateAwakenAttrItemList(attrList)
    else
        self._curSelectTreePointSkillId = heroTreePointInfo.skillId
        local curPointSkill = curPointLvRef.skill
        local extraSkill = curPointLvRef.extraSkill or ""
        local pointSkill
        if not string.isempty(curPointSkill) and curPointSkill ~= "0" then
            pointSkill = curPointSkill
        else
            pointSkill = nextPointLvRef.skill
            extraSkill = nextPointLvRef.extraSkill or ""
        end
        local pointSkillList = string.split(pointSkill, '|')
        local extraSkillList = string.split(extraSkill, "|")
        local list = {}
        for i, v in ipairs(pointSkillList) do
            table.insert(list, {
                skillId = v,
                skillType = ModelHero.TYPE_AWAKEN_SKILL_DEFAULT,
            })
        end
        for i, v in ipairs(extraSkillList) do
            table.insert(list, {
                skillId = v,
                skillType = ModelHero.TYPE_AWAKEN_SKILL_EXTRA,
            })
        end
        self:CreateAwakenSkillItemList(list)
    end
    CS.ShowObject(self.mAwakenAttr, pointType == ModelHero.TREE_POINT_TYPE_ATTR)
    CS.ShowObject(self.mAwakenSkill, pointType == ModelHero.TREE_POINT_TYPE_SKILL)

    -- 显示消耗区域
    self._awakenSelectHeroList = {}

    --升级按钮与描述屏蔽
    local isShowPageDesc = true
    local pageDesc = ccClientText(20142)

    CS.ShowObject(self.mAwakenPageDesc, isShowPageDesc)
    if not isTryHero then
        self:SetWndText(self.mAwakenPageDesc, pageDesc)
    end
end

function UISagaBookDetail:ClickSoundBtn()
    if not gModelFunctionOpen:CheckIsOpened(21003001, true) then
        return
    end
    local heroRefId = self._heroRefId
    local effCfg = gModelHero:GetShowEffectById(heroRefId)
    if string.isempty(effCfg.RoleRef) then
        local quality, raceRank, careerType
        heroRefId = nil
        for _, v in pairs(GameTable.CharacterRef) do
            if not quality then
                quality = v.quality
            end
            if not raceRank then
                raceRank = gModelHero:GetHeroRaceRefRank(v.raceType)
            end
            if not careerType then
                careerType = v.careerType
            end
            if not heroRefId then
                heroRefId = v.refId
            else
                if quality < v.quality then
                    quality = v.quality
                    raceRank = gModelHero:GetHeroRaceRefRank(v.raceType)
                    careerType = v.careerType
                    heroRefId = v.refId
                elseif quality == v.quality then
                    local curRaceRank = gModelHero:GetHeroRaceRefRank(v.raceType)
                    if curRaceRank < raceRank then
                        quality = v.quality
                        raceRank = curRaceRank
                        careerType = v.careerType
                        heroRefId = v.refId
                    elseif curRaceRank == raceRank then
                        if v.careerType < careerType then
                            quality = v.quality
                            raceRank = curRaceRank
                            careerType = v.careerType
                            heroRefId = v.refId
                        elseif v.careerType == careerType then
                            if v.refId < heroRefId then
                                quality = v.quality
                                raceRank = curRaceRank
                                careerType = v.careerType
                                heroRefId = v.refId
                            end
                        end
                    end
                end
            end
        end
    end
    GF.OpenWnd("UISagaSound", { heroRefId = heroRefId })
end

function UISagaBookDetail:CheckWearHeroList(heroRefIde)
    local heroRefIdList = gModelHero:GetServerHeroListByRefId(heroRefIde) -- 判断是否有该类型的英雄
    local maxPowerHeroId = gModelHero:GetRefIdTypeList(heroRefIde)--最高战力流水ID
    return { heroListCnt = #heroRefIdList, maxPowerId = maxPowerHeroId }
end

function UISagaBookDetail:RefreshStarPage()
    local isShow = self._showAwaken
    CS.ShowObject(self.mAwakenView, isShow)
    if isShow then
        self:RefreshAwakenView()
    end
end

function UISagaBookDetail:CreateHightStateHero(effectRef, showUnLockDesBg)
    local scale = UISagaBookDetail.Spine_Scale
    local anim = "idle"
    --[[    local effId = effectRef.refId
        local effRef = gModelHero:GetShowEffectById(effId)
        local heroType = effRef.heroType
        local isAct = gModelHeroBook:FindHeroInfoStatusByHeroRefId(heroType)
        if not isAct then
            local isCalm = gModelHeroExtra:CheckBookIsCalm(effId)
            if isCalm then
                anim = "calm"
            end
        end]]

    --- 2024/6/20：http://192.168.16.2:3002/issues/753
    if showUnLockDesBg then
        anim = "calm"
    end

    if not self._hightStateHeroLihui then
        self._hightStateHeroLihui = {}
    end
    local hightStateHeroLihui = self._hightStateHeroLihui

    CS.ShowObject(self.mHeroLiHuiBgPos, true)
    CS.ShowObject(self.mHeroLiHuiHdPos, true)

    local heroDrawing = effectRef.heroDrawing

    ---@type LUIHeroObject
    local newUILiHuiObj = hightStateHeroLihui[heroDrawing]
    local oldUILiHuiObj = self._curHightUIObj
    if oldUILiHuiObj and newUILiHuiObj ~= oldUILiHuiObj then
        oldUILiHuiObj:ShowHero(false)
    end
    local effectId = effectRef.refId
    if newUILiHuiObj then
        newUILiHuiObj:ShowHero(true)
        self:UpdateJD(effectId,showUnLockDesBg,newUILiHuiObj)
    else
        newUILiHuiObj = LUIHeroObject:New(self)
        hightStateHeroLihui[heroDrawing] = newUILiHuiObj
        newUILiHuiObj:Create(self.mHeroLihui, heroDrawing, heroDrawing)
        newUILiHuiObj:SetHeroBgParams({
            effRef = effectRef,
            lihuiBgTrans = self.mHeroLiHuiBgPos,
            lihuiHdTrans = self.mHeroLiHuiHdPos,
        })
        newUILiHuiObj:SetLoadedFunction(function()
            newUILiHuiObj:PlayAni(anim, true)
            local _displaySpine = newUILiHuiObj:GetDpObject()
            if _displaySpine then _displaySpine:SetRaycastTarget(true) end
            self:UpdateJD(effectId,showUnLockDesBg,newUILiHuiObj)
        end)
        newUILiHuiObj:SetClickFunc(function()
            if showUnLockDesBg then
                return
            end

            self.isClickSound = true
            local action = gModelHero:GetHeroClickAction(effectRef.refId)
            if action and action ~= "" then
                newUILiHuiObj:PlayAni(action, false, nil, nil, true, LSpineAniConst.idle)
                -- local spine = newUILiHuiObj:GetDisplaySpine()
                -- spine:SetAnimationCompleteFunc(function(ainName)
                --     if ainName == action then
                --         spine:PlayAnimation(0, "idle", true)
                --     end
                -- end)
                -- spine:PlayAnimation(0,action,false)
            end
            local actionSound = gModelHero:GetHeroClickSound(effectRef.refId)
            if actionSound and actionSound ~= "" then
                gLGameAudio:PlaySingleSound(actionSound, function()
                end)
            end
        end)
        newUILiHuiObj:SetRectMatch(true)
        newUILiHuiObj:ShowHero(true)
        newUILiHuiObj:SetScale(scale)
        newUILiHuiObj:StartLoad()
    end
    self._curHightUIObj = newUILiHuiObj
end

function UISagaBookDetail:OnClickAwakenSkillSelect()
    GF.ShowMessage(ccClientText(20160))
end

function UISagaBookDetail:GetSkinList()

    local skinList = {}
    -- local starRef = gModelHero:GetHeroStarById(self._starId)
    -- local orginSkinRef = GameTable.CharacterEffectRef[starRef.effectId]--星级表-effectId
    -- if (not orginSkinRef) then
    --     return
    -- end
    -- local orginSkinRefRoleRef = orginSkinRef.RoleRef--“sound_win_1;SoundM_2”
    -- if not orginSkinRefRoleRef then
    --     return
    -- end
    -- table.insert(skinList, orginSkinRef)
    -- local skinEffectId = starRef.skinEffectId or ""--多个皮肤id
    -- skinEffectId = string.split(skinEffectId, "|")
    -- for i, v in ipairs(skinEffectId) do
    --     local conf = GameTable.CharacterEffectRef[tonumber(v)]
    --     --皮肤id 语音
    --     local voice = conf and conf.RoleRef

    --     if voice and voice ~= orginSkinRefRoleRef then
    --         table.insert(skinList, conf)
    --     end

    -- end
    -- skinList = gModelHero:GetHeroEffectListByRefId(self._heroRefId, true)
    --获取英雄的表现列表
    if not self._heroEffectRef then
        self._heroEffectRef = {}
        local heroEffRef = GameTable.CharacterEffectRef
        for _, value in pairs(heroEffRef) do
            if not self._heroEffectRef[value.heroType] then
                self._heroEffectRef[value.heroType] = {}
            end
            table.insert(self._heroEffectRef[value.heroType], value)
        end
    end
    return self._heroEffectRef[self._heroRefId] or {}
end

function UISagaBookDetail:CreateQMDJList(dj, heroRefId)
    --local list = {}
    --local closeLv = gModelHeroBook:GetHeroCloseLv(heroRefId)
    --for i = 1,closeLv do
    --	local actStar = dj >= i
    --	table.insert(list, { actStar = actStar })
    --end
    --
    --local uiQMDJList = self._uiQMDJList
    --if uiQMDJList then
    --	uiQMDJList:RefreshList(list)
    --else
    --	uiQMDJList = self:GetUIScroll("uiQMDJList")
    --	self._uiQMDJList = uiQMDJList
    --	uiQMDJList:Create(self.mQmDJList, list, function(...)
    --		self:OnDrawStarCell(...)
    --	end)
    --end
end

function UISagaBookDetail:PlayHideTween()
    local tweenSeq = YXTween.TweenSequenceIns()

    local moveFunc = function(value)
        self:SetAnchorPos(self.mGameObject_1, Vector2.New(0, value))
        if self._showTabData[self._tabIndex].indexId == 4 then
            self:SetAnchorPos(self.mG4, Vector2.New(0, -value))
        end
        if self._showTabData[self._tabIndex].indexId == 5 then
            self:SetAnchorPos(self.mG5, Vector2.New(0, -value))
        end
        self:SetAnchorPos(self.mGameObject_3, Vector2.New(0, -value))
    end
    local moveTween = YXTween.TweenFloat(0, 100, UISagaBookDetail.PlayTime, moveFunc):SetEase(DG.Tweening.Ease.InSine)

    tweenSeq:AppendInterval(UISagaBookDetail.PlayTime)
    tweenSeq:Append(moveTween)

    tweenSeq:OnComplete(function()
        self._hideTween = nil
        CS.ShowObject(self.mGameObject_1, false)
        CS.ShowObject(self.mG4, false)
        CS.ShowObject(self.mG5, false)
        CS.ShowObject(self.mGameObject_3, false)
    end)

    self._hideTween = tweenSeq
    tweenSeq:PlayForward()


end

function UISagaBookDetail:OnDrawRwdItem(list, item, itemData, index)
    local instanceId = item:GetInstanceID()
    local Icon = self:FindWndTrans(item, "Icon")
    local ImgMask = self:FindWndTrans(item, "ImgMask")
    local ImgSelect = self:FindWndTrans(item, "ImgSelect")
    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(Icon)
    local itemId = tonumber(itemData)
    local haveCount = gModelItem:GetNumByRefId(itemId)
    CS.ShowObject(ImgMask, haveCount <= 0)
    CS.ShowObject(ImgSelect, itemId == self.selectGift)
    if itemId == self.selectGift then
        self.selGiftItem = item
    end
    baseClass:SetCommonReward(LItemTypeConst.TYPE_ITEM, itemId, haveCount)
    baseClass:EnableShowNum(haveCount > 0)
    baseClass:DoApply()
    self:SetWndClick(item, function()
        if haveCount == 0 then
            gModelGeneral:ShowCommonItemTipWnd({ refId = itemId, type = LItemTypeConst.TYPE_ITEM, count = haveCount })
            return
        end
        local imgselectOld = self:FindWndTrans(self.selGiftItem, "ImgSelect")
        CS.ShowObject(imgselectOld, false)
        self.selectGift = itemId
        self.selGiftItem = item
        CS.ShowObject(ImgSelect, true)
        self:OnUpdateProgressTxt()
    end)

    self:SetWndLongClick(item, function()
        gModelGeneral:ShowCommonItemTipWnd({ refId = itemId, type = LItemTypeConst.TYPE_ITEM, count = haveCount })--长按
    end, 0.8, false)
end

function UISagaBookDetail:OnTimer(key)
    if self._checkIsPlayingTimerKey == key then
        self:CheckSingleIsPlaying()
    end
end

function UISagaBookDetail:OnCutHero(heroObj, beginPos, endPos)
    if not self._showTabData[self._tabIndex] then
        return
    end
    if self._showTabData[self._tabIndex].indexId == 3 then
        return -- 语录不允许切换
    end
    if self._curUILiHuiObj == nil then
        return
    end
    if self._curUILiHuiObj ~= heroObj then
        return
    end
    local beginX = beginPos.x
    local endX = endPos.x
    local subX = beginX - endX
    if subX > 20 then
        self:CutHero(1)
    elseif subX < -20 then
        self:CutHero(-1)
    end
end

function UISagaBookDetail:ShowRewardList()
    if not self.mListRewards.gameObject.activeInHierarchy then
        return
    end
    local heroRef = GameTable.CharacterRef[self._heroRefId]
    local gifts = {}
    if heroRef and heroRef.favorabilityGIft then
        gifts = string.split(heroRef.favorabilityGIft, ",")
        table.sort(gifts, function(a, b)
            local aItem = GameTable.PlayerItemRef[tonumber(a)]
            local bItem = GameTable.PlayerItemRef[tonumber(b)]
            if aItem.quality ~= bItem.quality then
                return aItem.quality < bItem.quality
            else
                return aItem.refId < aItem.refId
            end
        end)
        if self.selectGift and gModelItem:GetNumByRefId(self.selectGift) <= 0 then
            self.selectGift = nil
        end
        if not self.selectGift then
            for _, itemId in pairs(gifts) do
                if gModelItem:GetNumByRefId(tonumber(itemId)) > 0 then
                    self.selectGift = tonumber(itemId)
                    break
                end
            end
        end
    end
    CS.ShowObject(self.mListRewards, true)
    -- self:OnCheckGiftCost()
    self:CreateUIScrollImpl(nil, self.mListRewards, gifts, function(...)
        self:OnDrawRwdItem(...)
    end, UIItemList.WRAP)
end
function UISagaBookDetail:DoTweenHorn(isPlaying, ImgHorn0, ImgHorn1)
    -- if isPlaying then
    --     -- if self._hornTween then return end
    --     local tweenSeq = YXTween.TweenSequenceIns()
    --     local moveFunc = function(value)

    --     end
    --     local time = 0.4
    --     local count = 0
    --     tweenSeq:AppendInterval(time)
    --     tweenSeq:OnComplete(function()
    --         tweenSeq:AppendInterval(time)
    --         count = count+1

    --     end)
    --     self._hornTween = tweenSeq
    --     tweenSeq:PlayForward()

    -- else
    --     self._hornTween = nil
    -- end
end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UISagaBookDetail



