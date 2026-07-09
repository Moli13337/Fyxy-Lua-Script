---
--- Created by LCM.
--- DateTime: 2024/3/6 18:05:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIUpStarSagaSowNew:LWnd
local UIUpStarSagaSowNew = LxWndClass("UIUpStarSagaSowNew", LWnd)

--- 默认英雄
UIUpStarSagaSowNew.TYPE_WND_NORMAL = 0

--- 欲望召唤英雄
UIUpStarSagaSowNew.TYPE_WND_CALLHERO = 1

--- 女神召唤英雄
UIUpStarSagaSowNew.TYPE_WND_GODDESS = 2

local typeof = typeof
local UnityEngine = UnityEngine
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local YXTween = YXTween
local Tweening = DG.Tweening
local EaseOutCubic = Tweening.Ease.OutCubic
local EaseInQuad = Tweening.Ease.InQuad
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIUpStarSagaSowNew:UIUpStarSagaSowNew()
    self._runAniKey = "_runAniKey"                  -- 整体动画运行 key
    self._showBotAniKey = "_showBotAniKey"          -- 整体动画运行 key

    self._runTimeKey = "_runTimeKey"                -- 特效倒计时

    self._teshuEffKey = "_teshuEffKey"              -- 特殊展示 Effect

    self._recordSpKey = "_recordSpKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIUpStarSagaSowNew:OnWndClose()
    if self._callBackFunc then
        self._callBackFunc()
    end
    self._callBackFunc = nil

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIUpStarSagaSowNew:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIUpStarSagaSowNew:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    local openCallBack = self:GetWndArg("openCallBack")
    if openCallBack then
        openCallBack()
    end
    self.jpj = gLGameLanguage:IsJapanVersion()
    CS.ShowObject(self.mCloseEffBtn, true)
    self:InitText()
    self:InitCommonData()
    self:InitEvent()
    --self:InitMsg()
    self:InitData()

    local wndType = self._wndType
    if wndType == UIUpStarSagaSowNew.TYPE_WND_CALLHERO then
        CS.ShowObject(self.mEffect1, false)
        local bgEffName = "fx_ui_yuwangchoujiang_zhanshi"
        self:CreateWndEffect(self.mEffect1, bgEffName, bgEffName, 100, false, false,
                nil, nil, nil, nil, nil, nil, 10)

        local effectName = "fx_ui_yuwangchoujiang_teshu"
        self:CreateWndEffect(self.mStarEffRoot, effectName, self._teshuEffKey, 100, false, false,
                nil, nil, nil, nil, nil, function(dpTrans)
                    self:ResetWndShow()

                    local jueseTrans = self:FindWndTrans(dpTrans, "fx_ui_yuwangchoujiang/juese")
                    if not jueseTrans then
                        return
                    end

                    self._jueseTrans = jueseTrans

                    self:InitImgShow()
                end, 10)
    elseif wndType == UIUpStarSagaSowNew.TYPE_WND_GODDESS then
        self:RefreshGoddessBgEffect()
    else
        print("===========")
        ---- 其他方式获得使用 特殊召唤效果
        self:RefreshGoddessBgEffect(ModelCallHero.CALL_TYPE_SPECIAL)
        --[[        self:ResetWndShow()
                self:InitImgShow()]]
    end
    self:SendGuideReadyEvent(self:GetWndName())

end

function UIUpStarSagaSowNew:OnShareClick(sid, canGetIndex, canGet)
    --直接显示出来就行
    CS.ShowObject(self.mShareNewInfoDiv, true)
    --保存图片的节点
    local list = { self.mLiHuiPos, self.mBefore }

    local shareData = {}
    shareData = { shareScene = LShareConst.SCENE_MADFUN, shareLocation = "GameShareActivity40" }
    gLGameUI:CaptureUIScreen(self:GetWndTrans(), list, true, shareData, function()
        if not self:IsWndValid() then
            return
        end
        --printInfoN2("share-----------","---------ok--------")
        self:WndClose()
        --GF.OpenWnd("UIActFB")
    end)
    gModelActivity:SetFBRewardCanGetList(sid, canGetIndex, canGet)
end

function UIUpStarSagaSowNew:InitImgShowOld()
    local heroRefId = self._heroRefId
    if not heroRefId then
        return
    end

    local heroRef = gModelHero:GetHeroRef(heroRefId)
    if not heroRef then
        return
    end

    local raceRef = gModelHero:GetHeroRaceRefByRefId(heroRef.raceType)
    if not raceRef then
        return
    end

    local careerRef = gModelHero:GetCareerRefByRefId(heroRef.careerType)
    if not careerRef then
        return
    end

    local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
    if not qualityRef then
        return
    end

    local effRef = gModelHero:GetHeroEffectRef(heroRefId)
    if not effRef then
        return
    end

    local star = heroRef.initStar
    local effInfo
    if gLGameLanguage:IsUSARegion() or gLGameLanguage:IsKoreaRegion() then
        effInfo = {
            effName = qualityRef.callHeroShowEffect,
            runTime = 1,
        }
    else
        effInfo = self._initStarEffList[star]
    end

    local isRunEff = effInfo ~= nil
    if isRunEff then
        CS.ShowObject(self.mStarEffRoot, true)
        CS.ShowObject(self.mCloseEffBtn, true)
        self:CreateWndEffect(self.mStarEffRoot, effInfo.effName, effInfo.effName, 100, false, false)
    end

    self._heroName = gModelHero:GetHeroNameByRefId(heroRefId)
    local careerName = ccLngText(careerRef.name)
    local location = ccLngText(effRef.location)
    self._heroJob = string.format("%s <color=#139056>[%s]</color>", careerName, location)

    self._callHeroDesc = ccLngText(effRef.callDesc)

    local heroDrawing = effRef.heroDrawing

    ---- 英雄获得界面Y轴
    self.mLiHuiPos.localPosition = gModelHeroExtra:GetHeroShowLH1(effRef, self.mLiHuiPos)

    ---- 英雄获得界面倍数
    local heroShowLH2 = 1.2
    --local heroShowLH2 = effRef.heroShowLH2 or 0
    --if heroShowLH2 == 0 then
    --    heroShowLH2 = 1.2
    --end

    self:CreateWndSpine(self.mLiHuiPos, heroDrawing, heroDrawing, false, function(dpSpine)
        dpSpine:SetScale(heroShowLH2)
    end)

    self:InitStarList(star)

    self:InitSkillList(star, heroRefId)

    --- 英雄品质图标
    self:SetWndEasyImage(self.mHeroQualityImg, heroRef.qualityIcon, function()
        CS.ShowObject(self.mHeroQualityImg, true)
    end)

    --- 英雄种族图标
    self:SetWndEasyImage(self.mHeroRaceImg, raceRef.icon)

    --- 背景图


    --- 英雄品质背景图

    local rotateZ = 180

    if isRunEff then
        self:RunTime(effInfo.runTime)
    else
        self:RunAni()
    end

    local isShowTwitterLink = gModelPlayer:CheckShowTwitterLink()
    CS.ShowObject(self.mBtnShareTwitter, isShowTwitterLink)
end

function UIUpStarSagaSowNew:RefreshGoddessBgEffect(callRefId)
    callRefId = callRefId or self._callRefId
    local rewardBgAniEff = gModelCallHero:GetMirrorCallRewardBgAniEff(callRefId)
    self:CreateWndEffect_Ex({
        trans = self.mBgEffect,
        effName = rewardBgAniEff,
        effKey = rewardBgAniEff,
        upSortOrder = 10,
        endFunc = function()
            self:RefreshGoddessEffect(callRefId)
        end,
    })
end

function UIUpStarSagaSowNew:GetSkillList(star, refId)
    self._skillTransList = {}
    local list = {}
    local heroSkillIdList = gModelHero:GetSkillListByRefIdAndStar(refId, star)
    for i = 1, 4 do
        local skillData = heroSkillIdList[i]
        local data = {
            grade = 0,
            refId = refId,
            star = star,
            index = i,
        }
        if skillData then
            data.skillId = skillData.skillId
            data.openClass = skillData.openClass
        end
        table.insert(list, data)
    end
    return list
end

--- 设置节点打字机效果
function UIUpStarSagaSowNew:SetTransScaleAndPriterAni(transInfo, seq)
    local scale = transInfo.scale
    local trans = transInfo.trans
    local scaleTime = transInfo.scaleTime or 0.3
    local strength = transInfo.strength or 2
    local shakeTime = transInfo.shakeTime or 1
    local isJoin = transInfo.isJoin or false
    CS.ShowObject(trans, false)

    if scale then
        trans.localScale = Vector3(scale, scale, scale)
    end

    seq:AppendCallback(function()
        if not trans.gameObject.activeSelf then
            CS.ShowObject(trans, true)
        end
    end)

    local newImgScaleTween = trans.transform:DOScale(Vector3(1, 1, 1), scaleTime)
    if isJoin then
        seq:Join(newImgScaleTween)
    else
        seq:Append(newImgScaleTween)
    end

    local newShake = self:CreateShakeTrans({
        strength = strength,
        time = shakeTime
    })
    seq:Join(newShake)
end

function UIUpStarSagaSowNew:OnTimer(key)
    if key == self._runTimeKey then
        self:RunAni()
    end
end

function UIUpStarSagaSowNew:InitText()
    self:SetWndText(self.mCloseTip, ccClientText(10103))
    self:SetWndText(self.mShareTwitterText, ccClientText(21180))
    self:SetTextTile(self.mNewImg, ccClientText(20182))
    if self.jpj then
        local text = CS.FindTrans(self.mNewImg,"UIText")
        self:SetAnchorPos(self.mNewImg,Vector2.New(56,19))
        self.mNewImg.sizeDelta = Vector2.New(60,40)
        self:InitTextSizeWithLanguage(text,-2)
    end
end

function UIUpStarSagaSowNew:OnDrawStarCell(list, item, itemdata, itempos)
    local StarImgTrans = self:FindWndTrans(item, "StarImg")
    CS.ShowObject(StarImgTrans, true)
    local img = itemdata.img
    self:SetWndEasyImage(StarImgTrans, img)

    local starTransList = self._starTransList
    if not starTransList then
        starTransList = {}
        self._starTransList = starTransList
    end
    table.insert(starTransList, StarImgTrans)
end

function UIUpStarSagaSowNew:OnClickCloseEffBtnFunc()
    self:RunAni()
end

function UIUpStarSagaSowNew:InitImgShow()
    LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_HERO_RARE)
    local wndType = self._wndType
    local callHeroType = wndType == UIUpStarSagaSowNew.TYPE_WND_CALLHERO

    local jueseTrans = self._jueseTrans
    if callHeroType then
        if not jueseTrans then
            return
        end
    end

    local heroRefId = self._heroRefId
    if not heroRefId then
        return
    end

    gModelHero:PlayHeroRoleSound(heroRefId)

    local heroRef = gModelHero:GetHeroRef(heroRefId)
    if not heroRef then
        return
    end

    local raceRef = gModelHero:GetHeroRaceRefByRefId(heroRef.raceType)
    if not raceRef then
        return
    end

    local careerRef = gModelHero:GetCareerRefByRefId(heroRef.careerType)
    if not careerRef then
        return
    end

    local qualityRef = gModelItem:GetQualityRef(heroRef.quality)
    if not qualityRef then
        return
    end

    if not string.isempty(qualityRef.callHeroShow) then
        self:SetWndEasyImage(self.mBg, qualityRef.callHeroShow, function()
            CS.ShowObject(self.mBg, true)
        end)
    else
        CS.ShowObject(self.mBg, true)
    end

    local effRef = gModelHero:GetHeroEffectRef(heroRefId)
    if not effRef then
        return
    end

    --self._heroName = gModelHero:GetHeroNameByRefId(heroRefId)
    --self:SetWndText(self.mNameTxt,self._heroName)

    local nickName = ccLngText(effRef.nickName)
    self:SetWndText(self.mNameTxt, nickName)
    self:SetXUITextTransColor(self.mNameTxt, qualityRef.nameColor)

    local careerName = ccLngText(careerRef.name)
    local location = ccLngText(effRef.location)
    self._heroJob = string.format("%s <color=#139056>[%s]</color>", careerName, location)
    self._callHeroDesc = ccLngText(effRef.callDesc)
    self:SetWndText(self.mJobTxt, self._heroJob)

    local spine = self:FindWndSpineByKey(self._recordSpKey)
    if spine then
        self:DestroyWndSpineByKey(self._recordSpKey)
    end

    self._effRef = effRef

    local heroDrawing = effRef.heroDrawing
    ---@param dpSpine LDisplaySpine
    self:CreateWndSpine(self.mLHContent, heroDrawing, self._recordSpKey, false, function(dpSpine)
        ---- 英雄获得界面倍数
        local heroShowLH2 = 1
        --local heroShowLH2 = effRef.heroShowLH2 or 0
        --if heroShowLH2 == 0 then
        --    heroShowLH2 = 1.2
        --end
        self._recordHeroShowLH2 = heroShowLH2
        dpSpine:SetScale(heroShowLH2)

        if callHeroType then
            local callType = gModelCallHero:GetExtractType(self._callRefId)
            if (gModelCallHero:GetMirrorCallJumpAniStats() and callType==1) or gModelRegression:GetRegressionCallJumpAniStats() and callType==4 then
                self:RunAni()
            else
                dpSpine:SetColor(Color.New(0, 0, 0, 1))

                self.mLHContent:SetParent(jueseTrans, false)
                self.mLHContent.localPosition = Vector3.zero
                local scalePos = 0.01
                self.mLHContent.localScale = Vector3(scalePos, scalePos, scalePos)

                self:RunTime(3.5)
            end
        else
            self:RunAni()
        end
    end)

    local star = heroRef.initStar
    self:InitStarList(star)

    self:InitSkillList(star, heroRefId)

    --- 英雄品质图标
    self:SetWndEasyImage(self.mHeroQualityImg, heroRef.qualityIcon, function()
        CS.ShowObject(self.mHeroQualityImg, true)
    end)

    --- 英雄种族图标
    self:SetWndEasyImage(self.mHeroRaceImg, raceRef.icon)

    local isShowTwitterLink = gModelPlayer:CheckShowTwitterLink()
    CS.ShowObject(self.mBtnShareTwitter, isShowTwitterLink)
end

function UIUpStarSagaSowNew:OnAwake()
    local delay = gModelGuide:GetGuidePara("heroDelay")
    self:DelaySendFinish(delay)
end

function UIUpStarSagaSowNew:OnClickShareTwitter()
    local isShow, link = gModelPlayer:CheckShowTwitterLink()
    if not isShow then
        return
    end

    if gModelPlayer:CheckReceiveSpecialDailyShareRewardGet() then
        gModelPlayer:OnReceiveSpecialDailyReq(ModelPlayer.RECEIVE_SPECIAL_DAILY_SHARE)
    end

    CS.UApplication.OpenURL(link)
end

--- 获取CanvasGroup
function UIUpStarSagaSowNew:GetTransCanvasGroup(trans, initAlpha)
    local csCanvasGroup = trans:GetComponent(typeofCanvasGroup)
    if not csCanvasGroup then
        csCanvasGroup = trans.gameObject:AddComponent(typeofCanvasGroup)
    end
    initAlpha = initAlpha or 0
    csCanvasGroup.alpha = initAlpha
    if not trans.gameObject.activeSelf then
        CS.ShowObject(trans, true)
    end
    return csCanvasGroup
end

function UIUpStarSagaSowNew:InitSkillList(star, heroRefId)
    local list = self:GetSkillList(star, heroRefId)
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

function UIUpStarSagaSowNew:OnDrawSkillCell(list, item, itemdata, itempos)
    local RootTrans = self:FindWndTrans(item, "CommonUI/Root")
    RootTrans.localScale = Vector3(1, 1, 1)
    CS.ShowObject(RootTrans, true)
    local SkillIconTrans = self:FindWndTrans(RootTrans, "SkillIcon")

    local skillTransList = self._skillTransList
    if not skillTransList then
        skillTransList = {}
        self._skillTransList = skillTransList
    end
    table.insert(skillTransList, RootTrans)

    local tempPosX = 0
    if itempos == 1 then
        tempPosX = -800
    elseif itempos == 2 then
        tempPosX = -600
    elseif itempos == 3 then
        tempPosX = 600
    elseif itempos == 4 then
        tempPosX = 800
    end
    local curPos = RootTrans.localPosition
    RootTrans.localPosition = Vector3(tempPosX, curPos.y, curPos.z)

    local skillId, openClass = itemdata.skillId, itemdata.openClass
    local refId, star, index = itemdata.refId, itemdata.star, itemdata.index
    local grade = itemdata.grade

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
        end)
    else
        baseClass:SetShowIcon(false, false)
        baseClass:SetSkillInfo(nil, nil, nil, 1)
        baseClass:Create(SkillIconTrans, 0, function()
        end)
    end
    --[[    if not skillId then
            baseClass:SetIconAndIconBgGray(false)
        end]]
end

function UIUpStarSagaSowNew:ShowBotFunc(showBotCGTime)
    local seqTween
    self:TweenSeqKill(self._showBotAniKey)
    if not seqTween then
        seqTween = self:TweenSeqCreate(self._showBotAniKey, function(seq)
            --- 渐变显示底层UI底
            local showBotTween = self:SetAlphaInOutAni({
                trans = self.mBotImg,
                showTime = showBotCGTime,
            })
            seq:Append(showBotTween)
            return seq
        end)
    end
    seqTween:OnComplete(function()
        self:TweenSeqKill(self._showBotAniKey)
    end)
    seqTween:PlayForward()
end

function UIUpStarSagaSowNew:RunAni()
    local wndType = self._wndType
    local callHeroType = wndType == UIUpStarSagaSowNew.TYPE_WND_CALLHERO
    CS.ShowObject(self.mLiHuiPos, true)
    local spine = self:FindWndSpineByKey(self._recordSpKey)
    if callHeroType then
        if spine then
            self.mLHContent:SetParent(self.mLiHuiPos, false)
            self.mLHContent.localPosition = Vector3.zero
            self.mLHContent.localScale = Vector3.one
            spine:SetColor(Color.New(1, 1, 1, 1))
        end
    end

    if self._recordHeroShowLH2 and spine then
        spine:SetScale(self._recordHeroShowLH2)
    end

    if self._effRef then
        ---- 英雄获得界面Y轴
        self.mLiHuiPos.localPosition = gModelHeroExtra:GetHeroShowLH1(self._effRef, self.mLiHuiPos)
    end

    CS.ShowObject(self.mBgEffect, true)
    CS.ShowObject(self.mLiHuiEffect, true)

    CS.ShowObject(self.mEffect1, true)
    CS.ShowObject(self.mStarEffRoot, false)
    CS.ShowObject(self.mCloseEffBtn, false)
    CS.ShowObject(self.mShareDiv, false)

    local seqTween
    self:TweenSeqKill(self._runAniKey)
    if not seqTween then
        seqTween = self:TweenSeqCreate(self._runAniKey, function(seq)

            local showAddTime = 0

            local showLiHuiTime = 0.1
            if not callHeroType then
                local showLiHuiTween = self:SetAlphaInOutAni({
                    trans = self.mLiHuiPos,
                    showTime = showLiHuiTime,
                })
                seq:Append(showLiHuiTween)
            end

            showAddTime = showAddTime + showLiHuiTime

            --- 首先出现最上面的品质图标
            local showTopCGTime = 0.1
            local showTopHQTween = self:SetAlphaInOutAni({
                trans = self.mTopHeroQualityBg,
                showTime = showTopCGTime,
            })
            seq:Append(showTopHQTween)

            showAddTime = showAddTime + showTopCGTime

            --- 如果是新英雄，则显示新标识，做一个砸下的动画，屏幕震动效果
            if self._isNew then
                local newImgScaleTime = 0.1
                self:SetTransScaleAndPriterAni({
                    trans = self.mNewImg,
                    scale = 2,
                    scaleTime = newImgScaleTime,
                    strength = 5,
                    shakeTime = newImgScaleTime,
                }, seq)

                showAddTime = showAddTime + newImgScaleTime
            end


            --- 先出现种族图标，打字机的模式从左到右打印 英雄名字，英雄职业和定位

            seq:AppendCallback(function()
                CS.ShowObject(self.mNameBg, true)

                --同时初始化分享
                self:InitShareDiv()
            end)

            seq:Append(self:SetAlphaInOutAni({
                trans = self.mHeroRaceImg,
                showTime = 0,
            }))

            --[[local showHRTime = 0.2
            local showHRTween = self:SetAlphaInOutAni({
                trans = self.mHeroRaceImg,
                showTime = showHRTime,
            })
            seq:Append(showHRTween)
            showAddTime = showAddTime + showHRTime

            local heroNameFPTween,heroNameFPTime = self:SetFormmatPrinterAni({
                str = self._heroName,
                trans = self.mNameTxt
            })
            seq:Append(heroNameFPTween)
            showAddTime = showAddTime + heroNameFPTime

            local heroJobFPTween,heroJobFPTime = self:SetFormmatPrinterAni({
                str = self._heroJob,
                trans = self.mJobTxt
            })
            seq:Join(heroJobFPTween)
            showAddTime = showAddTime + heroJobFPTime


            --- 出现星星，以打印机的模式砸下来，从左到右，砸下来后有星光粒子特效溢出
            local starTransList = self._starTransList
            if not starTransList then
                starTransList = {}
                self._starTransList = starTransList
            end

            local starTransScaleTime = 0.07
            local starTransLen = #starTransList
            local showBotCGTime = starTransScaleTime * starTransLen

            seq:InsertCallback(showAddTime,function()
                self:ShowBotFunc(showBotCGTime)
            end)

            local bigStarScale = 2
            for i,starTrans in ipairs(starTransList) do
                self:SetTransScaleAndPriterAni({
                    trans = starTrans,
                    scale = bigStarScale,
                    scaleTime = starTransScaleTime,
                    strength = 2,
                    shakeTime = starTransScaleTime,
                    isJoin = true,
                },seq)
            end]]

            local showBot = 0.1
            seq:InsertCallback(showBot, function()
                self:ShowBotFunc(0.5)
            end)
            seq:Join(self.mNameDiv:DOMove(self.mNameMoveEndPos.position, 0.2))

            --- 出现召唤文本，打字机形式，从左到右显示
            local heroCallFPTween = self:SetFormmatPrinterAni({
                str = self._callHeroDesc,
                trans = self.mHeroDesc
            })
            seq:Join(heroCallFPTween)


            --- 出现技能图标，打字机形式，从左到右，每出现一个屏幕轻微震动
            --[[            local skillTransList = self._skillTransList
                        if not skillTransList then
                            skillTransList = {}
                            self._skillTransList = skillTransList
                        end
                        local skillTransScaleTime = 0.1
                        local bigSkillScale = 2
                        for i,skillTrans in ipairs(skillTransList) do
                            self:SetTransScaleAndPriterAni({
                                trans = skillTrans,
                                scale = bigSkillScale,
                                scaleTime = skillTransScaleTime,
                                strength = 5,
                                shakeTime = skillTransScaleTime,
                            },seq)
                        end]]

            --- 出现技能图标，移动到中心位置
            local skillTransList = self._skillTransList
            if not skillTransList then
                skillTransList = {}
                self._skillTransList = skillTransList
            end
            for i, skillTrans in ipairs(skillTransList) do
                seq:Insert(showAddTime, skillTrans:DOLocalMove(Vector3.zero, 0.2))
                seq:Insert(showAddTime, self:SetAlphaInOutAni({
                    trans = skillTrans,
                }))
            end

            --- 出现点击空白处关闭界面文本
            local showEmptyTxtTime = 0.3
            local showEmptyTxtTween = self:SetAlphaInOutAni({
                trans = self.mCloseTip,
                showTime = showEmptyTxtTime,
            })
            seq:Append(showEmptyTxtTween)

            return seq
        end)
    end
    seqTween:OnComplete(function()
        for i, v in ipairs(self._skillTransList) do
            v.localScale = Vector3(1, 1, 1)
            v.localPosition = Vector3.zero
        end
        self:TweenSeqKill(self._runAniKey)
    end)
    seqTween:PlayForward()
end

--- 屏幕震动
function UIUpStarSagaSowNew:CreateShakeTrans(shakeInfo)
    shakeInfo = shakeInfo or {}
    local strength = shakeInfo.strength or 1
    local time = shakeInfo.time or 0.5
    local trans = shakeInfo.trans or self.mAniRoot
    local shake = trans:DOShakePosition(time, strength)
    return shake
end

--function UIUpStarSagaSowNew:InitMsg()
--
--	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
--	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
--end

function UIUpStarSagaSowNew:InitData()
    local wndType = self:GetWndArg("wndType") or UIUpStarSagaSowNew.TYPE_WND_NORMAL

    self._callRefId = self:GetWndArg("callRefId")
    if self._callRefId then
        if self._callRefId == 0 or gModelCallHero:GetExtractType(self._callRefId) == 1 then
            wndType = UIUpStarSagaSowNew.TYPE_WND_GODDESS
        end
    end
    if wndType ~= UIUpStarSagaSowNew.TYPE_WND_CALLHERO then
        self:SetImageAlpha(self.mBg, 1)
    end
    self._wndType = wndType

    local heroList = self:GetWndArg("heroList")
    self._heroList = heroList
    local heroRefId = table.remove(heroList, 1)
    --self._heroRefId = self:GetWndArg("heroRefId")
    --self._isNew = self:GetWndArg("isNew")
    --self._showEff = true

    self._heroRefId = heroRefId

    self._isNew = gModelHeroBook:CheckIsNewHero(self._heroRefId)
    --self._isNew = checkIsNew

    self._callBackFunc = self:GetWndArg("callBackFunc")

    self._starTransList = {}
    self._skillTransList = {}
end

--- 设置节点渐隐/渐现
function UIUpStarSagaSowNew:SetAlphaInOutAni(alphaInfo)
    if not alphaInfo then
        return
    end
    local csCanvasGroup = self:GetTransCanvasGroup(alphaInfo.trans, alphaInfo.initAlpha)
    local showTime = alphaInfo.showTime or 0.2
    local fromTime = alphaInfo.fromTime or 0
    local toTime = alphaInfo.toTime or 1
    local easeType = alphaInfo.easeType or EaseInQuad
    local alphaTween = YXTween.TweenFloat(fromTime, toTime, showTime, function(ival)
        csCanvasGroup.alpha = ival
    end)                      :SetEase(easeType)
    return alphaTween
end

function UIUpStarSagaSowNew:ResetWndShow()
    self:TimerStop(self._runTimeKey)
    self:TweenSeqKill(self._runAniKey)
    for i, v in ipairs(self._skillTransList) do
        v.localScale = Vector3(1, 1, 1)
        v.localPosition = Vector3.zero
        CS.ShowObject(v, false)
    end

    self.mNameDiv.position = self.mNameMoveStartPos.position

    CS.ShowObject(self.mStarEffRoot, true)
    CS.ShowObject(self.mCloseEffBtn, true)

    CS.ShowObject(self.mBgEffect, false)
    CS.ShowObject(self.mLiHuiEffect, false)

    CS.ShowObject(self.mNameBg, false)
    self:DestroyWndSpinetAll()

    self:GetTransCanvasGroup(self.mBotImg)
    --self:GetTransCanvasGroup(self.mLiHuiPos)
    self:GetTransCanvasGroup(self.mTopHeroQualityBg)
    self:GetTransCanvasGroup(self.mHeroRaceImg)
    self:GetTransCanvasGroup(self.mCloseTip)

end
------------------------- List -------------------------
function UIUpStarSagaSowNew:GetStarList(star)

    self._starTransList = {}
    local list = {}
    star = star or 1
    local img, temp, index = LUtil.GetHeroStarImg(star)
    for i = 1, temp do
        table.insert(list, {
            index = i,
            img = img,
        })
    end
    return list
end

function UIUpStarSagaSowNew:InitStarList(star)
    local list = self:GetStarList(star)
    local uiStarList = self._uiStarList
    if uiStarList then
        uiStarList:RefreshList(list)
    else
        uiStarList = self:GetUIScroll("uiStarList")
        self._uiStarList = uiStarList
        uiStarList:Create(self.mStarList, list, function(...)
            self:OnDrawStarCell(...)
        end)
    end
end

function UIUpStarSagaSowNew:OnClickClose()
    local heroRefId = table.remove(self._heroList, 1)
    if not heroRefId then
        self:WndClose()
        return
    end
    self._heroRefId = heroRefId
    self._isNew = gModelHeroBook:CheckIsNewHero(self._heroRefId)

    self:ResetWndShow()

    self:InitImgShow()
end

function UIUpStarSagaSowNew:InitCommonData()
    self._initStarEffList = {
        [4] = {
            effName = "fx_ui_zhaohuanhuode_purple",
            runTime = 1,
        },
        [5] = {
            effName = "fx_ui_zhaohuanhuode_orange",
            runTime = 1,
        }
    }
end

--- 设置文字打字机效果
function UIUpStarSagaSowNew:SetFormmatPrinterAni(formatInfo)
    formatInfo = formatInfo or {}
    local str = formatInfo.str or ""
    local trans = formatInfo.trans
    local color = formatInfo.color
    local len, itor = LUtil.FormatPrinterData(str)
    --local perTime = gModelPlot:GetPara("storyWriting") /1000
    local perTime = 0.015
    local time = len * perTime
    local tween = YXTween.TweenInt(0, len, time, function(value)
        local temp = itor(value) or ""
        if color then
            temp = LUtil.FormatColorStr(temp, color)
        end
        self:SetWndText(trans, temp)
    end)
    return tween, time
end


--region 分享部分 --------------------------------------------------------------------------------
function UIUpStarSagaSowNew:InitShareDiv()
    local isShowShareFB = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel, LShareConst.MADFUN_SYSTEM)

    --道具的部分
    local activityList = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_ACTIVITY_TYPE_103)

    local heroRefId = self._heroRefId
    local heroRef = gModelHero:GetHeroRef(heroRefId)
    local quality = checknumber(heroRef.quality)

    if isShowShareFB then
        isShowShareFB = quality >= 7
    end

    if isShowShareFB and activityList and activityList[1] then

        local activity = activityList[1]
        local activitySid = activity.sid
        local activityWebData = gModelActivity:GetWebActivityDataById(activitySid)
        if not activityWebData then
            return
        end

        if not gModelActivity:IsHasPackId(activity:GetMoreInfo().packId, true) then
            return
        end

        CS.ShowObject(self.mShareDiv, isShowShareFB)

        --设置文本
        self:SetWndText(self.mShareBtnTxt, ccClientText(14014))
        self:SetWndText(self.mShareTxt, ccClientText(14015))

        local rewards = string.split(activityWebData.config.daily1, ",")

        if not rewards then
            rewards = { activityWebData.daily1 }
        end

        local itemData = LUtil.GetRefItemFourData(rewards[1])
        local icon = gModelItem:GetItemImgByRefId(itemData.refId)

        self:SetWndEasyImage(self.mShareItemIcon, icon)
        self:SetWndText(self.mShareItemNum, itemData.count)

        self:SetWndClick(self.mShareBtn, function()
            self:OnShareClick(activity.sid, 3, true)
        end)

        --设置截屏保存的信息
        self:SetWndText(self.mShareHeroName, gModelPlayer:GetPlayerName())
        self:SetWndText(self.mShareServer, gModelPlayer:GetServerName())

    end
end

function UIUpStarSagaSowNew:OnWndRefresh()

    local heroList = self:GetWndArg("heroList")
    self._heroList = self._heroList or {}
    for k, v in ipairs(heroList) do
        table.insert(self._heroList, v)
    end

    local callback = self:GetWndArg("callBackFunc")
    self._callBackFunc = self._callBackFunc or callback
end

function UIUpStarSagaSowNew:RefreshGoddessEffect(callRefId)
    local rewardAniEff = gModelCallHero:GetMirrorCallRewardAniEff(callRefId)
    self:CreateWndEffect_Ex({
        trans = self.mLiHuiEffect,
        effName = rewardAniEff,
        effKey = rewardAniEff,
        upSortOrder = 20,
        endFunc = function()
            self:ResetWndShow()
            self:InitImgShow()
        end,
    })
end

function UIUpStarSagaSowNew:InitEvent()
    self:SetWndClick(self.mCloseEffBtn, function()
        self:OnClickCloseEffBtnFunc()
    end)
    self:SetWndClick(self.mGuideRoot, function()
        self:OnClickClose()
    end)
    self:SetWndClick(self.mBg, function()
        self:OnClickClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnShareTwitter, function(...)
        self:OnClickShareTwitter()
    end)
end

function UIUpStarSagaSowNew:RunTime(runTime)
    runTime = runTime or 1
    self:TimerStop(self._runTimeKey)
    self:TimerStart(self._runTimeKey, runTime, false, 1)
end


--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIUpStarSagaSowNew



