---
--- Created by Administrator.
--- DateTime: 2024/4/17 20:52:13
---
------------------------------------------------------------------
local typeofCanvas = typeof(UnityEngine.Canvas)
local LWnd = LWnd
---@class UIGenWin:LWnd
local UIGenWin = LxWndClass("UIGenWin", LWnd)

------------------------------------------------------------------

local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGenWin:UIGenWin()
    self._gradeType = 0 --0-所有 1-1阶，2-2阶，3-3阶，4-其他
    self._raceType = 0
    self._isShowList = false--是否显示隐藏列表
    self._isUnfold = true--是否展开折叠
    self._selectItem = nil
    self._selectEffRefId = nil
    self.tweenTime = 0.4
    local gradeNeedRef = string.split(GameTable.CharacterConfigRef.heroClassNeed, ",")
    self.gradeNeed = {}
    for _, value in ipairs(gradeNeedRef) do
        local strs = string.split(value, "=")
        self.gradeNeed[tonumber(strs[1])] = tonumber(strs[2])
    end
    self.gradeName = {
        ccClientText(41643),
        ccClientText(41644),
        ccClientText(41645),
        ccClientText(41646),
    }
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGenWin:OnWndClose()

    LUtil.ClearHashTable(self._uiHeroObjList)
    self._uiHeroObjList = nil
    self._curUIHeroObj = nil

    self._showTween = nil
    self._hideTween = nil
    self._foldTween = nil
    gLGameAudio:StopSingleSound()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGenWin:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGenWin:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    if gModelHero._gardenShowHeroEffRefId > 0 then
        self._selectEffRefId = gModelHero._gardenShowHeroEffRefId
    end


    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitRedPointOrder()
    self:SetHideTop(self._isShowList)
    self:InitMessage()
    self:SetWndText(self.mTxtIsShow, ccClientText(41300))
    self:SetWndText(self.mTxtSetting, ccClientText(41301))
    self:SetWndButtonText(self.mBtnUse, ccClientText(10228))
    self:SetWndButtonText(self.mBtnFavorability, ccClientText(41302))
    self:SetWndButtonText(self.mBtnBadge, ccClientText(47500))
    self:SetWndButtonText(self.mBtnInteract, ccClientText(41303))
    self:SetWndButtonText(self.mBtnPet, ccClientText(43700))
    self:SetWndButtonText(self.mBtnCall, ccClientText(41537))
    self:SetWndButtonText(self.mBtnMagic, ccClientText(45701))
    self:NullListTip()
    self:InitHeroShenList()
    self:InitRaceTypeList()
    self:InitCareerTypeList()
    self:CreateLiHui()
    self:UpdateEntranceBtn()
    local isShow = self._isUnfold and self._isShowList
    CS.ShowObject(self.mObjHeroList, isShow)
    CS.ShowObject(self.mBtnFold, not self._isShowList)
    CS.ShowObject(self.mBtnSetting, self._isUnfold)
    CS.ShowObject(self.mBtnTask, false)
    CS.ShowObject(self.mBtnBadge, not self._isShowList and gModelFunctionOpen:CheckIsShow(37000002))

    local soundFuncCfg = GameTable.FeatureOpenRef[21003001]
    self:SetWndButtonText(self.mBtnSound, ccLngText(soundFuncCfg.name))
    self:SetAnchorPos(self.mBtnSetting, Vector2.New(-270, 186))
    self:UpdateHeroListBtnRed()
    gModelHeroExtra:OnHeroInteractQuestReq()--互动任务信息
end

function UIGenWin:OnDrawHeroShenCell(list, item, itemdata, itempos)
    if self:IsWndClosed() then
        return
    end
    CS.ShowObject(item, true)
    local aniRootTrans = self:FindWndTrans(item, "AniRoot")
    local QualityImgTrans = self:FindWndTrans(aniRootTrans, "QualityImg")
    local HeroMapImgTrans = self:FindWndTrans(aniRootTrans, "HeroMapImg")
    local HeroBgTrans = self:FindWndTrans(aniRootTrans, "HeroBg")
    local HeronNameTrans = self:FindWndTrans(aniRootTrans, "HeronName")
    local RaceImgTrans = self:FindWndTrans(item, "RaceImg")

    local ImgUseing = self:FindWndTrans(aniRootTrans, "ImgFlag")
    local TxtUseing = self:FindWndTrans(ImgUseing, "TxtFlag")
    local redPointTrans = self:FindWndTrans(aniRootTrans, "redPoint")
    local ImgMask = self:FindWndTrans(aniRootTrans, "ImgMask")
    local ImgSelect = self:FindWndTrans(aniRootTrans, "ImgSelect")

    local effRef = itemdata
    local name = effRef.skinType <= 1 and ccLngText(effRef.name) or ccLngText(effRef.skinName)
    self:SetWndText(HeronNameTrans, name)
    if gLGameLanguage:IsJapanVersion() then
        LxUiHelper.SetSizeWithCurAnchor(HeronNameTrans,1,40)
    end

    self:SetWndText(TxtUseing, ccClientText(30306))
    -- self:InitTextShowWithLanguage(HeronNameTrans)
    local active = gModelHero:IsActiveHeroEffRefId(effRef.refId)
    local notActive = not active
    local pathFalg = notActive and "public_txt_5_1" or "public_bg_13"
    self:SetWndEasyImage(ImgUseing, pathFalg)
    CS.ShowObject(TxtUseing, not notActive)
    -- local red = gModelHero:GetFavorabilityInteractRed(effRef.refId,true) or gModelHero:GetFavorabilityInteractRed(effRef.refId)
    local isUse = gModelHero._gardenShowHeroEffRefId == effRef.refId
    if isUse then
        self.useItem = item
    end
    CS.ShowObject(ImgUseing, isUse or notActive)
    CS.ShowObject(ImgMask, notActive)
    -- CS.ShowObject(redPointTrans,red)
    local raceType = effRef.heroType > 0 and GameTable.CharacterRef[effRef.heroType].raceType
    local img = gModelHero:GetRaceImgByRefId(raceType)
    if img then
        self:SetWndEasyImage(RaceImgTrans, img, function()
            CS.ShowObject(RaceImgTrans, true)
        end)
    end
    local quality = itemdata.heroType > 0 and GameTable.CharacterRef[itemdata.heroType].quality
    if quality then
        local listBgBig = gModelItem:GetListBgBigByQuality(quality)
        self:SetWndEasyImage(HeroBgTrans, listBgBig)
        local heorBook1Bg = gModelItem:GetHeorBook1BgByQuality(quality)
        self:SetWndEasyImage(QualityImgTrans, heorBook1Bg)
    end
    local iconBig = effRef and effRef.iconBig
    if iconBig then
        if notActive then
            iconBig = gModelHeroExtra:GetShieldIconBig(iconBig,effRef)
        end
        self:SetWndEasyImage(HeroMapImgTrans, iconBig, function()
            CS.ShowObject(HeroMapImgTrans, true)
        end, true)
    end
    if self._selectEffRefId == itemdata.refId then
        self._selectItem = item
        CS.ShowObject(ImgSelect, true)
        CS.ShowObject()
        self:OnUpdateBtn()
    else
        CS.ShowObject(ImgSelect, false)
    end
    self:SetWndClick(HeroBgTrans, function()
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
        else
            --更換
            if self._selectEffRefId == itemdata.refId then
                return
            end
            self:OnClickItem(item, itemdata)
        end
    end)
end
function UIGenWin:UpdateHeroListBtnRed()
    -- for k,v in pairs(self.allHeroEffData) do
    -- 	if gModelHero:GetFavorabilityInteractRed(v.refId,true) or gModelHero:GetFavorabilityInteractRed(v.refId) then
    -- 		self:OnUpdateRedPoint(self.mBtnSetting,true)
    -- 		return
    -- 	end
    -- end
    -- local favorabilityInfo = gModelHero:GetFavorabilityInfoList()
    -- local isShow = false
    -- for i ,v in pairs(favorabilityInfo or {}) do
    --     if gModelHero:GetFavorabilityInteractRed(v.heroRefId,true) or gModelHero:GetFavorabilityInteractRed(v.heroRefId,false) then
    --         isShow = true
    --         break
    --     end
    -- end
    -- self:OnUpdateRedPoint(self.mBtnSetting,isShow)
end

function UIGenWin:NullListTip()
    local emptyList = self:GetCommonEmptyList("_empty")
    local data = {
        refId = 36101,
        IntroTran = self.mTxtNullList,
    }
    emptyList:RefreshUI(data)
end
function UIGenWin:InitCareerTypeList()
    local list = { 0, 1, 2, 3, 4 }--所有階，1階，2階，3階，其他
    local uiCareerTypeList = self._uiCareerTypeList
    if uiCareerTypeList then
        uiCareerTypeList:RefreshList(list)
    else
        uiCareerTypeList = self:GetUIScroll("uiCareerTypeList")
        self._uiCareerTypeList = uiCareerTypeList
        uiCareerTypeList:Create(self.mCareerTypeList, list, function(...)
            self:OnDrawCareerTypeCell(...)
        end)
    end
end
function UIGenWin:PlayShowTween(isSetting)
    local tweenSeq = YXTween.TweenSequenceIns()
    local moveFunc
    if isSetting then
        --设置显示
        CS.ShowObject(self.mObjHeroList, true)
        self:SetAnchorPos(self.mBtnSetting, Vector2.New(-270, 187))
        moveFunc = function(value)
            self:SetAnchorPos(self.mObjHeroList, Vector2.New(0, -44 + value))--显示
            self:SetAnchorPos(self.mBtnFold, Vector2.New(267, -109 + value)) --隐藏
            self:SetAnchorPos(self.mBtnSetting, Vector2.New(-270, 186+(self._showRaceBtnList and 61 or 0) + value))--显示
            self:SetWndEasyImage(self.mBtnSetting, "public_btn_icon_33_1")
        end
    else
        CS.ShowObject(self.mBtnSetting, self._isUnfold)
        self:SetAnchorPos(self.mBtnSetting, Vector2.New(-270, 186))
        moveFunc = function(value)
            self:SetAnchorPos(self.mBtnSetting, Vector2.New(-270, -83 + value))--显示
        end
    end

    self:SetAnchorPos(self.mObjHeroList, Vector2.New(0, -44))
    CS.ShowObject(self.mBtnFavorability, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(21002000))
    CS.ShowObject(self.mBtnBadge, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(37000002))
    CS.ShowObject(self.mBtnInteract, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(21002100))
    CS.ShowObject(self.mBtnPet, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(21006000))
    CS.ShowObject(self.mBtnCall, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(21007000))
    CS.ShowObject(self.mBtnSound, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(21003001))
    CS.ShowObject(self.mBtnMagic, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(21008000))
    CS.ShowObject(self.mBtnTask, not self._isShowList and self._isUnfold and self.interactHeroRefId > 0)
    -- self:SetHideBottom(not (not self._isShowList and self._isUnfold))
    self:SetHideTop(not (not self._isShowList and self._isUnfold))

    local moveTween = YXTween.TweenFloat(0, 269, self.tweenTime, moveFunc):SetEase(DG.Tweening.Ease.InSine)
    tweenSeq:Append(moveTween)
    tweenSeq:OnComplete(function()
        self._showTween = nil
    end)
    self._showTween = tweenSeq
    tweenSeq:PlayForward()

end
function UIGenWin:OnDrawCareerTypeCell(list, item, itemdata, itempos)
    local RaceIconTrans = self:FindWndTrans(item, "RaceIcon")
    local SelImgTrans = self:FindWndTrans(item, "SelImg")
    local TxtGrade = self:FindWndTrans(item, "TxtGrade")
    local refId = itemdata
    local isSel = self._gradeType == refId
    CS.ShowObject(RaceIconTrans, refId == 0)
    CS.ShowObject(TxtGrade, refId ~= 0)
    CS.ShowObject(SelImgTrans, isSel)
    local str = self.gradeName[refId] or ""
    self:SetWndText(TxtGrade, str)
    if self._isVie then
        local textTran = LxUiHelper.FindXTextCtrl(TxtGrade)
        textTran.enableWordWrapping = true
    end
    self:SetWndClick(item, function()
        self:OnClickCareerTypeFunc(refId)
    end, LSoundConst.CLICK_PAGE_COMMON)
end
function UIGenWin:UpdateEntranceBtn()
    local isGray = false
    local isShow = gModelFunctionOpen:CheckIsShow(21007000)
    CS.ShowObject(self.mBtnCall, isShow and not self._isShowList)
    if isShow then
        isGray = gModelFunctionOpen:CheckIsOpened(21007000, false)
        self:SetWndButtonGray(self.mBtnCall, not isGray)
    end
    isShow = gModelFunctionOpen:CheckIsShow(21002000)
    CS.ShowObject(self.mBtnFavorability, isShow and not self._isShowList)
    if isShow then
        isGray = gModelFunctionOpen:CheckIsOpened(21002000, false)
        self:SetWndButtonGray(self.mBtnFavorability, not isGray)
    end

    isShow = gModelFunctionOpen:CheckIsShow(37000002)
    CS.ShowObject(self.mBtnBadge, isShow)
    if isShow then
        isGray = gModelFunctionOpen:CheckIsOpened(37000002)
        self:SetWndButtonGray(self.mBtnBadge, not isGray)
    end

    isShow = gModelFunctionOpen:CheckIsShow(21002100)
    CS.ShowObject(self.mBtnInteract, isShow and not self._isShowList)
    if isShow then
        isGray = gModelFunctionOpen:CheckIsOpened(21002100, false)
        self:SetWndButtonGray(self.mBtnInteract, not isGray)
    end

    isShow = gModelFunctionOpen:CheckIsShow(21006000)
    CS.ShowObject(self.mBtnPet, isShow and not self._isShowList)
    if isShow then
        isGray = gModelFunctionOpen:CheckIsOpened(21006000, false)
        self:SetWndButtonGray(self.mBtnPet, not isGray)
    end

    isShow = gModelFunctionOpen:CheckIsShow(21003001)
    CS.ShowObject(self.mBtnSound, isShow and not self._isShowList)
    if isShow then
        isGray = gModelFunctionOpen:CheckIsOpened(21003001, false)
        self:SetWndButtonGray(self.mBtnSound, not isGray)
    end

    isShow = gModelFunctionOpen:CheckIsShow(21008000)
    CS.ShowObject(self.mBtnMagic, isShow and not self._isShowList)
    if isShow then
        isGray = gModelFunctionOpen:CheckIsOpened(21008000, false)
        self:SetWndButtonGray(self.mBtnMagic, not isGray)
    end
end
function UIGenWin:InitRaceTypeList()
    local data = {
        wndClass = self,
        listTrans = self.mHeroRaceList,
        showType = UIHeroRaceList.TYPE_NORMAL,
        callbackFunc = function(raceType)
            if not self:IsWndValid() then
                return
            end
            if raceType == self._raceType then
                return
            end
            self._raceType = raceType
            self:InitHeroShenList()
        end,
        checkSelFunc = function(raceType)
            if not self:IsWndValid() then
                return
            end
            return self._raceType == raceType
        end,
    }
    self:GetUIHeroRaceList(data)
end

-- 看板娘显示隐藏
function UIGenWin:OnIsShowHeroList()
    self._isShowList = not self._isShowList
    self:SetWndText(self.mTxtSetting, self._isShowList and ccClientText(41641) or ccClientText(41301))
    if self._isShowList then
        --显示
        self:PlayShowTween(true)
    else
        self:PlayHideTween(true)
        self:OnClickCareerTypeFunc(0)

        --重新选中已使用
        if gModelHero._gardenShowHeroEffRefId <= 0 or gModelHero._gardenShowHeroEffRefId == self._selectEffRefId then
            return
        end
        if self._selectItem then
            local imgSel = self:FindWndTrans(self._selectItem, "AniRoot/ImgSelect")
            CS.ShowObject(imgSel, false)
        end
        self._selectEffRefId = self.allHeroEffData[1].refId
        if self.useItem then
            self._selectItem = self.useItem
            local ImgSelect = self:FindWndTrans(self.useItem, "AniRoot/ImgSelect")
            CS.ShowObject(ImgSelect, true)
        end
        self:OnUpdateBtn()
        -- self:UpdateInteractBtnRed()
        self:CreateLiHui()--更新立绘
    end
end
function UIGenWin:OnClickItem(item, itemdata)
    if self._selectItem and item then
        local imgSel = self:FindWndTrans(self._selectItem, "AniRoot/ImgSelect")
        CS.ShowObject(imgSel, false)
    end
    self._selectEffRefId = itemdata.refId
    if item then
        self._selectItem = item
        local ImgSelect = self:FindWndTrans(item, "AniRoot/ImgSelect")
        CS.ShowObject(ImgSelect, true)
    end
    gLGameAudio:StopSingleSound()
    self:OnUpdateBtn()
    -- self:UpdateInteractBtnRed()
    self:CreateLiHui()--更新立绘
end

function UIGenWin:ClickSoundBtn()
    if not gModelFunctionOpen:CheckIsOpened(21003001, true) then
        return
    end
    local heroRefId = self._selectEffRefId
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
    GF.OpenWnd("UISagaSound", { heroRefId = heroRefId, from = "UIGenWin" })
end

function UIGenWin:OnInteractTask()
    local heroRefId = self.interactHeroRefId
    if not heroRefId or heroRefId <= 0 then
        GF.ShowMessage(ccClientText(41666))
        return
    end
    local heroEffRef = GameTable.CharacterEffectRef[heroRefId]
    if not heroEffRef then
        return
    end
    local plotCfg = GameTable.GardenHeroRef[heroEffRef.heroType]
    local eventRefId = self.interactEvtRefid
    local eventRef = GameTable.GardenEventRef[eventRefId]
    if not eventRef then
        return
    end
    local func = function()
        gModelGeneral:OpenHeroStarPre({ refId = heroRefId, showTab = true, selectIndex = 5 })
        self.interactHeroRefI = 0
        if eventRef.type == LInteractEventType.INTERACT_EVT_1
                or eventRef.type == LInteractEventType.INTERACT_EVT_2 then
            GF.OpenWnd("UIInsKey", { heroEffectRef = heroEffRef, eventId = eventRefId, moreInfo = tonumber(self.interactMoreInfo) })
        elseif eventRef.type == LInteractEventType.INTERACT_EVT_3 then
            GF.OpenWnd("UIInsGuess", { heroEffectRef = heroEffRef, eventId = eventRefId })
        else
            GF.OpenWnd("UIInsObviate", { heroEffectRef = heroEffRef, eventId = eventRefId })
        end
    end
    if plotCfg and not string.isempty(plotCfg.plot) then
        local plots = string.split(plotCfg.plot, ",")
        local plotId = nil
        plotId = plots[math.random(1, #plots)]
        gModelPlot:StartPlotAndCallback(tonumber(plotId), function()
            func()
        end, nil, heroEffRef, { plotTitle = ccLngText(heroEffRef.name), hideSpine = eventRef.type == LInteractEventType.INTERACT_EVT_2 })
    else
        func()
    end
end

function UIGenWin:CreateLiHui()
    local effRef = GameTable.CharacterEffectRef[self._selectEffRefId]
    if not effRef then
        return
    end

    local uiHeroObjList = self._uiHeroObjList
    if not uiHeroObjList then
        uiHeroObjList = {}
        self._uiHeroObjList = uiHeroObjList
    end

    local imgPath = not string.isempty(effRef.skinBg) and effRef.skinBg or effRef.heroBg
    self:SetWndEasyImage(self.mBgImage, imgPath)

    local heroDrawing = effRef.heroDrawing

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
            effRef = effRef,
            lihuiBgTrans = self.mHeroLiHuiBgPos,
            lihuiHdTrans = self.mHeroLiHuiHdPos,
        })
        newUILiHuiObj:SetRectMatch(true)
        newUILiHuiObj:ShowHero(true)
        newUILiHuiObj:SetLoadedFunction(function()

        end)
        newUILiHuiObj:StartLoad()
    end
    self._curUIHeroObj = newUILiHuiObj

    self:SetWndClick(self.mLihuiClick, function()
        local interact = gModelHero:GetHeroClickAction(effRef.refId)
        if interact and interact ~= "" then
            --互动动作
            --- 2024/6/4： 背景需要播放对应动画
            newUILiHuiObj:PlayAni(interact, false, nil, nil, true,LSpineAniConst.idle)

            --[[			local spine = newUILiHuiObj:GetDisplaySpine()
                        spine:SetAnimationCompleteFunc(function(ainName)
                            if ainName == interact then
                                spine:PlayAnimation(0, "idle", true)
                            end
                        end)
                        spine:PlayAnimation(0,interact,false)]]

            local actionSound = gModelHero:GetHeroClickSound(effRef.refId)
            if actionSound and actionSound ~= "" then
                gLGameAudio:PlaySingleSound(actionSound, function()
                end)
            end
        else
            if self._isUnfold then
                return
            end
            self:OnFoldOrUnfold()
        end
    end)
end

function UIGenWin:PlayHideTween(isSetting)
    local tweenSeq = YXTween.TweenSequenceIns()
    local moveFunc = nil
    if isSetting then
        --设置隐藏
        moveFunc = function(value)
            self:SetAnchorPos(self.mBtnFold, Vector2.New(267, 160 - value))--显示
            self:SetAnchorPos(self.mObjHeroList, Vector2.New(0, 225 - value)) --隐藏
            self:SetAnchorPos(self.mBtnSetting, Vector2.New(-270, (self._showRaceBtnList and 480 or 455) - value))--隐藏
            self:SetWndEasyImage(self.mBtnSetting, "public_btn_icon_33")
        end
    else
        moveFunc = function(value)

            self:SetAnchorPos(self.mBtnSetting, Vector2.New(-270, 187 - value))--显示
        end
    end
    local moveTween = YXTween.TweenFloat(0, 269, self.tweenTime, moveFunc):SetEase(DG.Tweening.Ease.InSine)
    tweenSeq:Append(moveTween)
    tweenSeq:OnComplete(function()
        self._hideTween = nil
        CS.ShowObject(self.mObjHeroList, self._isShowList)
        CS.ShowObject(self.mBtnSetting, self._isUnfold)
        CS.ShowObject(self.mBtnFavorability, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(21002000))
        CS.ShowObject(self.mBtnBadge, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(37000002))
        CS.ShowObject(self.mBtnInteract, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(21002100))
        CS.ShowObject(self.mBtnPet, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(21006000))
        CS.ShowObject(self.mBtnCall, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(21007000))
        CS.ShowObject(self.mBtnSound, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(21003001))
        CS.ShowObject(self.mBtnMagic, not self._isShowList and self._isUnfold and gModelFunctionOpen:CheckIsShow(21008000))
        CS.ShowObject(self.mBtnTask, not self._isShowList and self._isUnfold and self.interactHeroRefId > 0)
        -- self:SetHideBottom(not (not self._isShowList and self._isUnfold))
        self:SetHideTop(not (not self._isShowList and self._isUnfold))
    end)

    self._hideTween = tweenSeq
    tweenSeq:PlayForward()

end
function UIGenWin:GetActHeroData()
    local allListData = {}
    local refs = GameTable.CharacterRef
    local curTimeSpan = GetTimestamp()
    for k, v in pairs(refs) do
        local isOpen = gModelHero:GetHeroActShowState(v.refId, curTimeSpan)
        local heroEffects,hasActive = gModelHero:GetHeroEffectListByRefId(v.refId,true)
        if isOpen and v.maxFavorability and v.maxFavorability > 0 and heroEffects and hasActive then
            table.insert(allListData, v)
        end
    end
    table.sort(allListData, function(a, b)
        if a.quality ~= b.quality then
            return a.quality > b.quality
        else
            return a.refId < b.refId
        end
    end)
    return allListData
end
function UIGenWin:OnUpdateBtn(heroId)
    self:SetWndButtonText(self.mBtnUse, self._selectEffRefId == gModelHero._gardenShowHeroEffRefId and ccClientText(41320) or ccClientText(10228))
    if heroId then
        if self.useItem then
            local oldUse = self:FindWndTrans(self.useItem, "AniRoot/ImgFlag")
            CS.ShowObject(oldUse, false)
        end
        self.useItem = self._selectItem
        local newUse = self:FindWndTrans(self.useItem, "AniRoot/ImgFlag")
        CS.ShowObject(newUse, true)
        self:OnIsShowHeroList()
    end
end
function UIGenWin:OnUpdateRedPoint(trans, isShow)
    local RedPoint = self:FindWndTrans(trans, "RedPoint")
    CS.ShowObject(RedPoint, isShow)
end

function UIGenWin:FoldDoTween(isShow)
    local tweenSeq = YXTween.TweenSequenceIns()
    local moveTween = self.mBtnFoldImg:DOLocalRotate(Vector3.New(0, 0, isShow and 0 or 180), self.tweenTime):SetEase(DG.Tweening.Ease.InSine)
    tweenSeq:Append(moveTween)
    tweenSeq:OnComplete(function()
        self._foldTween = nil
    end)
    self._foldTween = tweenSeq
    tweenSeq:PlayForward()
end
function UIGenWin:InitHeroShenList()
    CS.ShowObject(self.mHeroShenList, true)

    local allHeroEffData = self:GetHeroList()
    CS.ShowObject(self.mNullList, #allHeroEffData <= 0)
    self.allHeroEffData = allHeroEffData
    if not self._selectEffRefId then
        local refId = self.allHeroEffData[1].refId
        self._selectEffRefId = refId
    end
    local uiHeroShenList = self._uiHeroShenList
    if not uiHeroShenList then
        uiHeroShenList = self:GetUIScroll("mHeroShenList")
        self._uiHeroShenList = uiHeroShenList
        uiHeroShenList:Create(self.mHeroShenList, allHeroEffData, function(...)
            self:OnDrawHeroShenCell(...)
        end, UIItemList.SUPER_GRID, false)
        local superList = uiHeroShenList:GetList()
        superList:EnableLoadAnimation(true)
        superList:SetLoadAnimationScale(0.2, 0.15)
        superList:RefreshList()
    else
        uiHeroShenList:RefreshList(allHeroEffData)

        local superList = uiHeroShenList:GetList()
        superList:MoveToPos(1, 0)
        superList:DrawAllItems(true)
    end
end
function UIGenWin:InitMessage()
    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function(index)
        if index ~= 3 then
            self:WndClose()
        end
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_LOVE_UPLV, function()
        self:UpdateHeroListBtnRed()
    end)
    self:WndEventRecv(EventNames.FAVORABILITY_SPINE_UPDATE, function(id)
        self._selectEffRefId = gModelHero._gardenShowHeroEffRefId
        self:InitHeroShenList()
        self:CreateLiHui()
        self._isShowList = true
        self:OnUpdateBtn(id)
    end)
    self:WndNetMsgRecv(LProtoIds.HeroInteractQuestResp, function(pb)
        self.interactHeroRefId = pb.heroRefId or 0
        self.interactEvtRefid = pb.eventRefId --事件Id
        self.interactMoreInfo = pb.moreInfo--当前事件的附加数据（当事件类型是1或2答题时，为题库RefId）
        local isShow = self.interactHeroRefId > 0
        if isShow then
            self:CreateWndEffect(self.mBtnTask, "fx_ui_garden_huayuanmutangrukou", nil, 100, nil, nil, nil, nil, nil, true, nil, nil)
        end
        CS.ShowObject(self.mBtnTask, isShow)
    end)
    self:SetWndClick(self.mBtnFavorability, function()
        if not gModelFunctionOpen:CheckIsOpened(21002000, true) then
            return
        end
        GF.OpenWnd("UIFavorabilityWin")
    end)

    self:SetWndClick(self.mBtnBadge, function()
        if not gModelFunctionOpen:CheckIsOpened(37000002, true) then return end
        GF.OpenWnd("UIBrandWin")
    end)

    self:RegisterRedPointFunc(ModelRedPoint.GARDEN_FAVORABILITY_UPLEVEL, function(isShow)
        local isopen = gModelFunctionOpen:CheckIsOpened(21002000, false)
        self:OnUpdateRedPoint(self.mBtnFavorability, isShow and isopen)
    end)

    self:RegisterRedPointFunc(ModelRedPoint.BADGE_ENTRANCE, function(isShow)
        self:OnUpdateRedPoint(self.mBtnBadge, isShow)
    end)

    self:RegisterRedPointFunc(ModelRedPoint.GARDEN_FAVORABILITY_INTERACT, function(isShow)
        self:OnUpdateRedPoint(self.mBtnInteract, isShow)
    end)

    self:RegisterRedPointFunc(ModelRedPoint.GARDEN_PET_ENTER, function(isShow)
        self:OnUpdateRedPoint(self.mBtnPet, isShow)
    end)

    self:RegisterRedPointFunc(21008000, function(isShow)
        if not isShow then
            isShow = gModelMagicPot:GetGiftRedPoint() or gModelQuest:IsHaveFinishTaskByType(182) or gModelMagicPot:GetRewardRedpoint()
        end

        if isShow then
            --local isOpen = gModelFunctionOpen:CheckIsOpened(21008001, false)
            local isOpen = gModelFunctionOpen:CheckIsOpened(21008100,false)
            if not isOpen then
                isShow = false
            end
        end



        self:OnUpdateRedPoint(self.mBtnMagic, isShow)
    end)

    self:WndEventRecv("magicPotRedPointChange", function()
        local isOpen = gModelFunctionOpen:CheckIsOpened(21008100,false)
        local isShow
        if isOpen then
            isShow = gModelMagicPot:GetGiftRedPoint() or gModelQuest:IsHaveFinishTaskByType(182) or gModelMagicPot:GetRewardRedpoint()
        end

        --这里的红点还要去check另一边的 魔法阵的
        if not isShow then
            isShow = gModelRedPoint:CheckShowRedPoint(21008000)
        end
        self:OnUpdateRedPoint(self.mBtnMagic, isShow)
    end)

    self:RegisterRedPointFunc(ModelRedPoint.RP_HALIDOM_34000001, function(isShow)
        self:OnUpdateRedPoint(self.mBtnCall, isShow)
    end)

    self:RegisterRedPointFunc(ModelRedPoint.GARDEN_FAVORABILITY_TASK, function(isShow)
        if isShow then
            -- self:CreateWndEffect(self.mBtnTask,"fx_ui_garden_huayuanmutangrukou",nil,100)
        end
        -- if isShow and (not self.interactHeroRefId or self.interactHeroRefId<=0) then
        -- 	gModelHeroExtra:OnHeroInteractQuestReq()--互动任务信息
        -- end
        -- CS.ShowObject(self.mBtnTask,isShow)
    end)

    self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE, function()
        self:UpdateEntranceBtn()
    end)
    self:SetWndClick(self.mBtnFold, function()
        self:OnFoldOrUnfold()
    end)
    self:SetWndClick(self.mUnfoldBtn, function()
        -- 展开按钮
        if not self._showRaceBtnList then
            self._showRaceBtnList = true
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mPackBtn, function()
        -- 收起按钮
        if self._showRaceBtnList then
            self._showRaceBtnList = false
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mShowAllBtn, function()
        -- 收起按钮
        if self._showRaceBtnList then
            self._showRaceBtnList = false
            self:PlayRaceBtnAni()
        end
    end)
    self:SetWndClick(self.mBtnSetting, function()
        -- 看板娘显示隐藏
        self:OnIsShowHeroList()
    end)
    self:SetWndClick(self.mBtnInteract, function()
        if not gModelFunctionOpen:CheckIsOpened(21002100, true) then
            return
        end
        local heroRefs = GameTable.CharacterRef
        local heroEffRef = GameTable.CharacterEffectRef[self._selectEffRefId]
        local favor = heroEffRef.heroType > 0 and heroRefs[heroEffRef.heroType].maxFavorability or 0
        local heroRefId = self._selectEffRefId
        local heroEffects ,hasActive= gModelHero:GetHeroEffectListByRefId(heroEffRef.heroType,true)
        if not favor or favor <= 0 or not heroEffects or not hasActive then
            --当前英雄没有好感度设置-默认打开已拥有最小品质英雄 or 当前表现为不可互动
            local heroList = self:GetActHeroData()
            if #heroList > 0 then
                heroRefId = heroList[1].refId
            else
                GF.ShowMessage(ccClientText(41648))
                return
            end
        end
        GF.OpenWnd("UIFavorabilityInteract", { heroRefId = heroRefId, from = "UIGenWin" })
    end)
    self:SetWndClick(self.mBtnUse, function()
        local active = gModelHero:IsActiveHeroEffRefId(self._selectEffRefId)
        if not active then
            GF.ShowMessage(ccClientText(41627))
            return
        end
        if gModelHero._gardenShowHeroEffRefId == self._selectEffRefId then
            return
        end
        gModelHeroExtra:OnHeroSetShowReq(self._selectEffRefId)
    end)
    self:SetWndClick(self.mBtnPet, function()
        if not gModelFunctionOpen:CheckIsOpened(21006000, true) then
            return
        end
        GF.OpenWnd("UIPeMinWin")
    end)

    self:SetWndClick(self.mBtnMagic, function()
        if not gModelFunctionOpen:CheckIsOpened(21008000, true) then
            return
        end
        GF.OpenWnd("UIMicMin")
    end)
    self:SetWndClick(self.mBtnCall, function()
        if not gModelFunctionOpen:CheckIsOpened(21007000, true) then
            return
        end
        gModelCallHero:OpenCallWnd({ page = 5 })
    end)
    self:SetWndClick(self.mBtnTask, function()
        self:OnInteractTask()
    end)
    self:SetWndClick(self.mBtnSound, function()
        self:ClickSoundBtn()
    end)
end

function UIGenWin:CreateLiHui1()
    self:DestroyWndSpineByKey("GardenHeroDrawing")
    local effRef = GameTable.CharacterEffectRef[self._selectEffRefId]
    local imgPath = not string.isempty(effRef.skinBg) and effRef.skinBg or effRef.heroBg
    self:SetWndEasyImage(self.mBgImage, imgPath)
    local drawing = effRef.heroDrawing
    local dpSpine = self:CreateWndSpine(self.mHeroLiHuiPos, drawing, "GardenHeroDrawing", true, function(dpLoaded)
        dpLoaded:PlayAnimation(0, "idle", true)
    end, true)
    dpSpine:StartLoad()
    self:SetWndClick(self.mLihuiClick, function()
        local interact = gModelHero:GetHeroClickAction(effRef.refId)
        if interact and interact ~= "" then
            --互动动作
            dpSpine:PlayAnimation(0, interact, false)
            dpSpine:SetAnimationCompleteFunc(function(ainName)
                if ainName == interact then
                    dpSpine:PlayAnimation(0, "idle", true)
                end
            end)
            local actionSound = gModelHero:GetHeroClickSound(effRef.refId)
            if actionSound and actionSound ~= "" then
                gLGameAudio:PlaySingleSound(actionSound, function()
                end)
            end
        else
            if self._isUnfold then
                return
            end
            self:OnFoldOrUnfold()
        end
    end)
end

function UIGenWin:UpdateInteractBtnRed()
    local effId = self._selectEffRefId
    local red = gModelHero:GetFavorabilityInteractRed(effId, true) or gModelHero:GetFavorabilityInteractRed(effId)
    self:OnUpdateRedPoint(self.mBtnInteract, red)
end
function UIGenWin:OnFoldOrUnfold()
    self._isUnfold = not self._isUnfold
    local txtCode = self._isUnfold and 41300 or 41304--展开
    self:SetWndText(self.mTxtIsShow, ccClientText(txtCode))
    if self._isUnfold then
        --显示
        -- self:SetHideBottom(self._isShowList)
        self:SetHideTop(self._isShowList)
        self:PlayShowTween()
        self:FoldDoTween(true)
    else
        -- self:SetHideBottom(not self._isUnfold)
        self:SetHideTop(not self._isUnfold)
        self:PlayHideTween()
        self:FoldDoTween()
    end
end
function UIGenWin:PlayRaceBtnAni()

    local isShow = self._showRaceBtnList
    CS.ShowObject(self.mLine1, not isShow)
    CS.ShowObject(self.mLine2, isShow)
    CS.ShowObject(self.mUnfoldBtn, not isShow)
    local delPos = self.mImgListBg.sizeDelta
    delPos.y = isShow and 360 or 292
    self.mImgListBg.sizeDelta = delPos
    local btnPos = self.mBtnUse.localPosition
    btnPos.y = isShow and 300 or 229
    self.mBtnUse.localPosition = btnPos
    local pos = self.mBtnSetting.anchoredPosition
    pos.y = isShow and 516 or 455
    self.mBtnSetting.anchoredPosition = pos
end
function UIGenWin:GetHeroList()
    local allListData = {}

    local refs = GameTable.CharacterRef
    local heroEffRef = GameTable.CharacterEffectRef
    local curUse = nil
    local curTimeSpan = GetTimestamp()
    for k, v in pairs(heroEffRef) do
        local heroRef = refs[v.heroType]
        local isOpen = true
        if heroRef then
            isOpen = gModelHero:GetHeroActShowState(heroRef.refId, curTimeSpan)
        end
        local isShow = not v.boardShow or v.boardShow ~= 1
        if v.heroType and v.heroType > 0 and isOpen and isShow then
            local bAdd = false
            if self._gradeType == 0 then
                bAdd = true
            elseif self._gradeType == 1 then
                ----0-所有 1-1阶，2-2阶，3-3阶，4-其他
                bAdd = v.skinType <= 1 --and (not v.needStar or v.needStar <= 1)
            elseif self._gradeType == 2 or self._gradeType == 3 then
                local gradeNeed = self.gradeNeed
                bAdd = v.skinType == 2 and v.needStar == gradeNeed[self._gradeType]
            elseif self._gradeType == 4 then
                local gradeNeed = self.gradeNeed
                bAdd = v.skinType == 2 and v.needStar ~= gradeNeed[2] and v.needStar ~= gradeNeed[3]
            end
            if bAdd and gModelHeroExtra:NeedCheckResType() then
                if v.skinType == 2 then
                    if gModelHeroExtra:CheckBookIsCalm(k) then
                        bAdd = false
                    end
                end
            end
            if bAdd and (self._raceType == 0 or heroRef.raceType == self._raceType) then
                --and heroRef.maxFavorability and heroRef.maxFavorability>0
                if nil ==heroRef then
                    bAdd=false
                end
                if gModelHero._gardenShowHeroEffRefId == v.refId then
                    --使用中
                    curUse = v
                else
                    table.insert(allListData, v)
                end
            end
        end
    end

    table.sort(allListData, function(a, b)
        local aState = gModelHero:IsActiveHeroEffRefId(a.refId) and 1 or 2
        local bState = gModelHero:IsActiveHeroEffRefId(b.refId) and 1 or 2
        if aState ~= bState then
            return aState < bState
        else
            if a.heroType ~= b.heroType then
                return a.heroType < b.heroType
            else
                return a.refId < b.refId
            end
        end
    end)
    if curUse then
        table.insert(allListData, 1, curUse)
    end
    return allListData
end

function UIGenWin:OnClickCareerTypeFunc(refId)
    if self._gradeType == refId then
        return
    end
    self._gradeType = refId
    self:InitHeroShenList()

    local uiCareerTypeList = self._uiCareerTypeList
    if not uiCareerTypeList then
        return
    end
    local uiList = uiCareerTypeList:GetList()
    uiList:RefreshList()
end

function UIGenWin:InitRedPointOrder()
    local redPoint = self:FindWndTrans(self.mBtnTask, "RedPoint")
    local canvas = redPoint:GetComponent(typeofCanvas)
    if not canvas then
        canvas = redPoint.gameObject:AddComponent(typeofCanvas)
    end
    local order = self:GetWndSortOrder()
    canvas.overrideSorting = true
    canvas.sortingLayerName = self:GetWndSortLayer()
    canvas.sortingOrder = order + 3
end
------------------------------------------------------------------
---
---
return UIGenWin