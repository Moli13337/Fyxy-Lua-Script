---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISaga:LWnd
local UISaga = LxWndClass("UISaga", LWnd)
--local typeof = typeof
local CS = CS
--local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISaga:UISaga()
    ---@type table<number,CommonIcon>
    self._heroIconList = {}
    self._itemIconList = {}

    self._recordTimer = nil
    self._nextRefreshTime = nil

    self:SetHideHurdle()

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISaga:OnWndClose()
    if self._time then
        LxTimer.DelayTimeStop(self._time)
    end

    if self._recordTimer then
        LxTimer.LoopTimeStop(self._recordTimer)
        self._recordTimer = nil
    end

    --if gModelHero then gModelHero:ClearHeroBagData() end

    if self._uiList then
        self._uiList:OnWndClose()
    end
    if self._uiHeroShenList then
        self._uiHeroShenList:OnWndClose()
    end
    if self._uispList then
        self._uispList:OnWndClose()
    end

    LWnd.OnWndClose(self)
end

function UISaga:DoWndDestroy()
    if self._heroIconList then
        local heroIconList = self._heroIconList
        self._heroIconList = nil
        for k, v in pairs(heroIconList) do
            v:Destroy()
            heroIconList[k] = nil
        end
    end
    local itemIconList = self._itemIconList
    if itemIconList then
        self._itemIconList = nil
        for k, v in pairs(itemIconList) do
            v:Destroy()
            itemIconList[k] = nil
        end
    end
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISaga:OnCreate()
    LWnd.OnCreate(self)

    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISaga:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEmptyList()

    self:InitLanguageGridLayout(self.mHeroList, Vector2.New(115, 114))
    if not self._isEnus then
        self:InitLanguageGridLayout(self.mHeroSpList, Vector2.New(108, 114))
    end
    if PRODUCT_G_VER ~= 0 then
        -- 提审
        if gLGameLanguage:CheckIsUseSpecialProduct() then
            local packId = gLGameLanguage:GetPackProductInfo()
            if packId == 1 then
            elseif packId == 2 then
                self:SetWndEasyImage(self.mImage__1_, "warDomain_big_bg1", nil, nil, true)
                CS.ShowObject(self.mLblBiaoti, false)
                CS.ShowObject(self.mImage__2_, false)
            end
        else
            self:SetWndEasyImage(self.mImage__1_, "warDomain_big_bg1", nil, nil, true)
            CS.ShowObject(self.mLblBiaoti, false)
            CS.ShowObject(self.mImage__2_, false)
        end
    end
    self:InitText()
    --self:DoWndStartMove(0, LWnd.StartMoveLeft, self.mBg)
    self:InitData()
    self:InitMsg()
    self:RefreshPanel()
    self:InitEvent()
    self:InitRaceTypeList()
    self:InitCareerTypeList()
    self:RefreshBtnEvent()
    self:RefreshOpen()
    --self._time = LxTimer.DelayTimeCall(function()
    --    self._time = nil
    --    local wndName = self:GetWndName()
    --    self:SendGuideReadyEvent(wndName)
    --end,0.31)
    self:RefreshItemBtnRedPoint()
    self:RefreshTuJianRedPoint()
    self:RefreshTimeWearRedPoint()
    local ref = gModelActivity:GetActivityFunsById(5)
    if ref then
        --local name = ccLngText(ref.name)
        self:SetWndText(self.mTimeWearBtnTxt, ccClientText(20102))
        self._timeWearType = ref.type
        self._uniqueJump = ref.uniqueJump
    end
    self:SetWndText(self.mTimeWearBtnTxt, ccClientText(20102))

    self:VersionRefresh()
    self:RefreshForeign()
end

------------------------------------------------------------------
--- 英雄碎片列表
------------------------------------------------------------------
function UISaga:CheckIsHaveHeightWnd()
    local wndList = {
        "UISagaBook",
    }
    for i, v in ipairs(wndList) do
        local wndInst = GF.FindFirstWndByName(v)
        if wndInst ~= nil then
            return true
        end
    end
    return false
end
function UISaga:GetHistory()
    local list = LWnd.GetHistory(self)
    local wndArgList = list.wndArgList
    wndArgList.raceType = self._raceType
    wndArgList.careerType = self._careerType
    return list
end

function UISaga:GetHeroList()
    local record = gModelFormation:GetOnFormationHeros(LCombatTypeConst.COMBAT_MAIN)
    local heroList = gModelHero:GetHeroSortList(record, nil, true)

    local showRedPoint = false
    local combatHeroList = gModelFormation:GetHeroFormationData(LCombatTypeConst.COMBAT_MAIN)
    self._combatHeroList = combatHeroList

    local allListData = {}
    self._allHeroDataList = allListData
    local combatHero = {}
    local combatHeroRef = {}
    --gModelHero:ClearHeroBagData()

    local heroNum = 0
    if heroList then
        --local heroIdx = 1
        for k, v in ipairs(heroList) do
            local refId = v:GetRefId()
            local id = v:GetId()
            local ref = gModelHero:GetHeroRef(refId)
            local bAdd = false

            if ref then
                local race = ref.raceType
                local career = ref.careerType
                bAdd = (self._careerType == 0 or career == self._careerType) and (self._raceType == 0 or race == self._raceType)
            end

            if combatHeroList[id] then
                if not showRedPoint then
                    showRedPoint = self:GetHeroStatus(id)
                end

                bAdd = false
                local hero = v:GetServerData()
                table.insert(combatHero, hero)
                table.insert(combatHeroRef, ref)
            end

            if bAdd then
                local hero = v:GetServerData()
                --gModelHero:SetHeroBagData(id,heroIdx)
                --hero.index = heroIdx
                table.insert(allListData, hero)
                --heroIdx = heroIdx + 1
            end
        end
        showRedPoint = showRedPoint or gModelRedPoint:CheckShowRedPoint(ModelRedPoint.MAINCITY_HERO_PET)
        CS.ShowObject(self._funcBtnRedPointList[1], showRedPoint)
        --heroNum = heroIdx - 1
        --gModelHero:SetLastNum(heroNum)
    end
    self._heroNum = heroNum

    table.sort(combatHero, function(a, b)
        return a.fightPower < b.fightPower
    end)

    for k, v in ipairs(combatHero) do
        local refId = v.refId
        local ref = gModelHero:GetHeroRef(refId)

        local race = ref.raceType
        local career = ref.careerType
        local bAdd = false

        bAdd = (self._careerType == 0 or career == self._careerType) and (self._raceType == 0 or race == self._raceType)

        if bAdd then
            table.insert(allListData, 1, v)
        end
    end

    return allListData
end

------------------------------------------------------------------
--- 按钮事件
--- 处理按钮事件
------------------------------------------------------------------
function UISaga:InitEvent()
    --self:WndEventRecv(EventNames.CLOSE_CURRENT_WND,function ()
    --    self:WndClose()
    --end)

    self:SetWndClick(self.mTimeWearBtn, function()
        local isOpen = gModelFunctionOpen:CheckIsOpened(self._heroSkinJump)
        if isOpen then
            --gModelFunctionOpen:Jump(self._heroSkinJump)
            GF.OpenWnd("UISnBook")
        end

        --FireEvent(EventNames.CHANGE_MAIN_BTN, 5)
        --GF.OpenWndBottom("UIAct", { page = self._timeWearType, subPage = self._uniqueJump })
        --GF.ChangeMap("LCityMap")
    end)

    self:SetWndClick(self.mRuneComBtn, function()
        --GF.OpenWndBottom("UIEqCompound",{page = 2})
        -- GF.OpenWnd("WndRuneCompound")
        GF.OpenWnd("UIMid", { page = 1 })
    end)
    self:SetWndClick(self.mBtnSorceryCard, function()
        GF.OpenWnd("UISorceryCardBook")
    end)

    --self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE,function () self:WndClose() end)

    self:SetWndClick(self.mAddBtn, function()
        self:BuyHeroNum()

        --[[        local perOutfit = {
                    id = "9110028000000005088",
                    playerId = "9110001000000000001",
                    refId = 15001,
                    star = 0,
                    heroRefId = 0,
                    starExp = 0,
                    heroId = 0,
                    score = 12860,
                    nextHeroRefId = 0,
                }
                local outfitInfo = {
                    id = "9110028000000005088",
                    playerId = "9110001000000000001",
                    refId = 15002,
                    star = 0,
                    heroRefId = 0,
                    starExp = 0,
                    heroId = 0,
                    score = 36860,
                    nextHeroRefId = 0,
                }
                GF.OpenWndUp("WndUpOutfitOpt",{outfitType = 2,perOutfitInfo = perOutfit,outfitInfo = outfitInfo})]]
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

    local funcBtnList = self._funcBtnList
    for i, v in ipairs(funcBtnList) do
        self:SetWndClick(v, function()
            self:FuncBtnEvent(i)
        end, LSoundConst.CLICK_PAGE_COMMON)
    end

    self:SetWndClick(self.mBuZhenBtn, function()
        gModelFormation:OpenSetFormationWnd()
        self:WndClose()
    end)

    self:SetWndClick(self.mBaowuBtn, function()
        --GF.OpenWndBottom("WndTreasure")
        -- gModelTreasure:OpenTreasureWnd()
    end)

    self:SetWndClick(self.mTuJianBtn, function()
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK, "1-1")
        --GF.OpenWnd("UISagaBookNew", { func = function()
        --    self:RefreshTuJianRedPoint()
        --end })
        GF.OpenWnd("UISagaBookParent", { func = function()
            self:RefreshTuJianRedPoint()
        end })
    end)

    self:SetWndClick(self.mAutoCompItemBtn, function()
        self:autoCompItemFunc()
    end)

    self:SetWndClick(self.mChangeShowHeroBtn, function()
        self:OnClickChangeShowHeroBtnFunc()
    end)

    self:SetWndClick(self.mHelpBtn, function()
        self:OnClickHelp()
    end, LSoundConst.CLICK_ERROR_COMMON)
end

function UISaga:RefreshTujian(redpointType)
    local isRed = false
    if redpointType == ModelRedPoint.BAG_HEROMAP then
        for k, v in pairs(GameTable.CharacterRef) do
            if isRed then
                break
            end

            isRed = gModelHeroBook:CheckHeroBookInfoStatusByRefId(k)

        end

        CS.ShowObject(self.mTuJianBtnRedPoint, isRed)
    end
end
function UISaga:InitData()
    self._showRaceBtnList = false
    self.isPlayEffect = false
    --self._isOpenInfoWnd = false
    self._raceType = self:GetWndArg("raceType") or 0              -- 种猪
    self._careerType = self:GetWndArg("careerType") or 0            -- 职业
    self._moveRaceKey = "moveRace"
    self._heroSkinJump = gModelHero:GeConfigByKey("heroSkinJump") or 29000000

    self._heroAwaken = gModelHero:GeConfigByKey("heroAwaken")

    self._funcBtnList = {
        self.mHeroListBtn,
        self.mHalidomBtn,
        self.mHeroMapBtn,
    }

    self._funcBtnRedPointList = {
        self.mHeroListBtnRedPoint,
        self.mHalidomBtnRedPoint,
        self.mHeroMapBtnRedPoint,
    }

    self._listTrans = {
        self.mHeroList,
        self.mHeroSpList,
        self.mHeroMapList,
    }
    self._selImgList = {
        self.mHeroListSelImg,
        self.mHalidomSelImg,
        self.mHeroMapSelImg,
    }

    local page = self:GetWndArg("page") or 1
    self._btnIndex = page
    CS.ShowObject(self.mHeroContainerBg, page == 1)
    CS.ShowObject(self.mTypeBtnList, page ~= 2)
    CS.ShowObject(self.mPack1, page ~= 2)
    CS.ShowObject(self.mDi2, page == 2)
    CS.ShowObject(self.mAutoCompItemBtn, page == 2)

    for i, v in ipairs(self._funcBtnList) do
        local show = i == page and 0 or 1
        self:SetWndTabStatus(v, show)
    end

    self:SetWndTabText(self._funcBtnList[1], ccClientText(10013))
    self:SetWndTabText(self._funcBtnList[2], ccClientText(10059))
    self:SetWndTabText(self._funcBtnList[3], ccClientText(10015))

    self._btnEvent = {
        [1] = function()
            self:InitScrollView()
        end,
        [2] = function()
            self:InitSPScrollView()
        end,
    }
    self._mapList = {}
    local mapList = self._mapList
    for k, v in pairs(GameTable.CharacterRef) do
        table.insert(mapList, v)
    end
    table.sort(mapList, function(hero1, hero2)
        local raceType1, raceType2 = hero1.raceType, hero2.raceType
        if raceType1 ~= raceType2 then
            return raceType1 < raceType2
        else
            local careerType1, careerType2 = hero1.careerType, hero2.careerType
            if careerType1 ~= careerType1 then
                return careerType1 < careerType2
            else
                local initStar1, initStar2 = hero1.initStar, hero2.initStar
                if initStar1 ~= initStar2 then
                    return initStar1 > initStar2
                else
                    local quality1, quality2 = hero1.quality, hero2.quality
                    if quality1 ~= quality1 then
                        return quality1 > quality2
                    else
                        local refId1, refId2 = hero1.refId, hero2.refId
                        return refId1 < refId2
                    end
                end
            end
        end
    end)
    --print("================")
    self._showHeroBgList = self:GetShowHeroBgList()
end

function UISaga:InitCareerTypeList()
    local list = self:GetCareerTypeList()
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

function UISaga:BuyHeroNum()
    gModelHero:PayBuyHeroTrench(self:GetWndName())
    --[[    local before = {
            refId = 13011,
            rankRefId = 0,
            strengRefId = 0,
        }
        local after = {
            refId = 13011,
            rankRefId = 1301101,
            strengRefId = 0,
        }
        gModelTreasure:OpenTreasureActWnd(ModelTreasure.TYPE_ARTICLE,before,after)]]

    --[[    local before = {
            refId = 27016,
            rankRefId = 0,
            strengRefId = 0,
        }
        local after = {
            refId = 27016,
            rankRefId = 2701605,
            strengRefId = 0,
        }
        gModelTreasure:OpenTreasureActWnd(ModelTreasure.TYPE_ARTICLE,before,after)]]

    --[[        local before = {
                refId = 2701,
                skillRefId = 270105,
            }
            local after = {
                refId = 2701,
                skillRefId = 270106,
            }
            gModelTreasure:OpenTreasureActWnd(ModelTreasure.TYPE_TREASURE,before,after)]]

    --[[    GF.OpenWndTop("WndTreasureCanAct",{treasureData = {
            refId = 2701,
            skillRefId = 0,
        }})]]
end
function UISaga:InitMsg()
    self:WndNetMsgRecv(LProtoIds.HeroListResp, function()
        --if self._btnIndex == 1 then self:InitScrollView() end
        self:RefreshOnHeroChange()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroUpLevelResp, function()
        self:RefreshOnHeroChange()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroUpGradeResp, function()
        self:RefreshOnHeroChange()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroAttributeResp, function()
        self:RefreshOnHeroChange()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroUpStarResp, function()
        --self._isOpenInfoWnd = true
        --self:RefreshPanel()
        --if self._btnIndex == 1 then self:InitScrollView() end

        self:RefreshOnHeroChange()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroChangeResp, function()
        self:RefreshOnHeroChange()
        --local newInfo = gModelGeneral:IsNewHeroWnd()
        --local wndHeroInfo = "UINewSagaInfo"
        --local wndInst = GF.FindFirstWndByName(wndHeroInfo)
        --if not wndInst then
        --    self:RefreshPanel()
        --    if self._btnIndex == 1 then self:InitScrollView() end
        --end
        self:RefreshTuJianRedPoint()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroBagExpandResp, function()
        self:RefreshPanel(true)
    end)
    self:WndNetMsgRecv(LProtoIds.ItemChangeResp, function()
        --self:RefreshHeroView(true)
        self:RefreshOnHeroChange()
        self:RefreshTuJianRedPoint()
        self:RefreshTimeWearRedPoint()
    end)

    self:WndNetMsgRecv(LProtoIds.EquipChangeResp, function()
        self:RefreshOnHeroChange()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroSkinSelectResp, function()
        self:RefreshOnHeroChange()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroBookRewardResp, function()
        --self:RefreshHeroView()
        self:RefreshOnHeroChange()
        self:RefreshTuJianRedPoint()
    end)

    self:WndNetMsgRecv(LProtoIds.HeroRelationActiveResp, function()
        self:RefreshTuJianRedPoint()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroBookUpCloseGradeResp, function()
        --self:RefreshHeroView()
        self:RefreshOnHeroChange()
        self:RefreshTuJianRedPoint()
    end)
    self:WndNetMsgRecv(LProtoIds.ItemUseResp, function()
        self:RefreshTuJianRedPoint()
        self:RefreshTimeWearRedPoint()
    end)
    self:WndEventRecv(EventNames.ON_ACT_PAGE_RED_CHANGE, function()
        self:RefreshTimeWearRedPoint()
    end)

    self:WndEventRecv(EventNames.REFRESH_SKIN_INFO, function()
        self:RefreshTimeWearRedPoint()
    end)
    self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE, function()
        self:RefreshOpen()
    end)
    self:WndEventRecv(EventNames.ON_OPENOUTFITOPT_EVENT, function()
        --if self._btnIndex == 1 then self:InitScrollView() end
        self:RefreshOnHeroChange()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroSetNameResp, function()
        self:RefreshOnHeroChange()
    end)

    self:WndEventRecv(EventNames.ON_WND_HERO_INFO_CLOSE, function()
        self:RefreshOnHeroChange()
    end)

    self:WndNetMsgRecv(LProtoIds.RuneCompoundResp, function()
        self:RefreshOnHeroChange()
    end)
end

function UISaga:OnDrawCareerTypeCell(list, item, itemdata, itempos)
    local RaceIconTrans = self:FindWndTrans(item, "RaceIcon")
    local SelImgTrans = self:FindWndTrans(item, "SelImg")
    local icon = itemdata.icon
    local refId = itemdata.refId
    local show = icon ~= nil
    local isSel = false
    if show then
        isSel = self._careerType == refId
        self:SetWndEasyImage(RaceIconTrans, icon)
    end
    CS.ShowObject(RaceIconTrans, show)
    CS.ShowObject(SelImgTrans, isSel)
    self:SetWndClick(RaceIconTrans, function()
        self:OnClickCareerTypeFunc(refId)
    end, LSoundConst.CLICK_PAGE_COMMON)
end

function UISaga:VersionRefresh()
    local isShow = gModelHero:IsTimeWardrobeShow()
    local isOpen = gModelFunctionOpen:CheckIsShow(self._heroSkinJump)
    CS.ShowObject(self.mTimeWearBtn, isShow and isOpen)
end

function UISaga:OpenHeroInfoWnd(itemdata)
    local refId = itemdata.refId
    --local index = itemdata.index
    local id = itemdata.id
    local paramArgs = {
        refId = refId,
        --index = index or 1,
        id = id,
        career = self._careerType,
        race = self._raceType,
    }
    local wndHeroInfo = "UINewSagaInfo"
    GF.OpenWnd(wndHeroInfo, paramArgs)
end

function UISaga:OnDrawHeroShenCell(list, item, itemdata, itempos)
    if self:IsWndClosed() then
        return
    end

    local aniRootTrans = self:FindWndTrans(item, "AniRoot")
    local QualityImgTrans = self:FindWndTrans(aniRootTrans, "QualityImg")
    local HeroMapImgTrans = self:FindWndTrans(aniRootTrans, "HeroMapImg")
    local HeroBgTrans = self:FindWndTrans(aniRootTrans, "HeroBg")
    local HeronNameTrans = self:FindWndTrans(aniRootTrans, "HeronName")
    local RaceImgTrans = self:FindWndTrans(item, "RaceImg")
    local AwakenImgTrans = self:FindWndTrans(item, "AwakenImg")

    local StarListTrans = self:FindWndTrans(aniRootTrans, "StarList")

    local HightStar = self:FindWndTrans(aniRootTrans, "HightStar")
    local HightStarText = self:FindWndTrans(HightStar, "HightStarText")
    local HightStarEff = self:FindWndTrans(aniRootTrans, "HightStarEff")

    local LvTxtTrans = self:FindWndTrans(aniRootTrans, "LvTxt")
    local UpOutTrans = self:FindWndTrans(aniRootTrans, "UpOut")
    local redPointTrans = self:FindWndTrans(aniRootTrans, "redPoint")
    local MainTrans = self:FindWndTrans(aniRootTrans, "Main")

    local refId = itemdata.refId
    local id = itemdata.id
    local index = itemdata.index
    local star = itemdata.star

    local showAwakenImg = false
    local treeInfo = itemdata.treeInfo
    if treeInfo and treeInfo:IsAwakenActivate() and (star >= self._heroAwaken) then
        local lv = treeInfo:GetAwakenAllLv()
        local iconPath = gModelHero:GetAwakenIconPathByLvl(lv, false)
        self:SetWndEasyImage(AwakenImgTrans, iconPath)
        showAwakenImg = true
        RaceImgTrans.localScale = Vector3.New(0.3, 0.3, 0.3)
    end
    CS.ShowObject(AwakenImgTrans, showAwakenImg)

    local combatHeroList = self._combatHeroList or {}
    local isMain = combatHeroList[id] ~= nil
    local isTry = itemdata.isTry
    if isTry then
        isMain = false
    end
    CS.ShowObject(MainTrans, isMain)

    local tempStar = itemdata.star

    if tempStar > 10 then
        CS.ShowObject(StarListTrans, false)
        CS.ShowObject(HightStar, true)
        self:SetWndText(HightStarText, tempStar - 10)
    else
        CS.ShowObject(StarListTrans, true)
        CS.ShowObject(HightStar, false)

        self:OnDrawStarList(StarListTrans, itemdata.star)
    end

    local lvStr = "<color=#a1#>#a2#</color>"
    local lvColor, lvMat = LUtil.GetResonanceColor(itemdata.isResonance)
    lvStr = string.replace(lvStr, "#" .. lvColor, itemdata.lv)
    self:SetWndText(LvTxtTrans, lvStr)
    if lvMat then
        self:SetWndTextMat(LvTxtTrans, lvMat)
    end

    local effRef = gModelHero:GetHeroEffectRefById(id)

    --- 2024/6/6：半身像逻辑优化，直接使用皮肤显示
    --local _polymorphism
    ----这里effRef 判断下有没有高级的部分
    --if effRef then
    --    _polymorphism = gModelHero:GetPolymorphism(effRef.refId)
    --else
    --    if LOG_INFO_ENABLED then
    --        printInfoNR2("丢失配置", "id--" .. tostring(id) .. "表现表没有对应的配置")
    --    end
    --end
    --
    --if _polymorphism then
    --    local showChangeEffRefId = -1
    --
    --    for k, v in ipairs(_polymorphism) do
    --        if itemdata.star >= v.needStar then
    --            showChangeEffRefId = v.refId
    --        end
    --    end
    --
    --    if showChangeEffRefId > 0 then
    --        effRef = gModelHero:GetShowEffectById(showChangeEffRefId)
    --    end
    --end

    --local name = ccLngText(effRef.name) -- gModelHero:GetHeroNameByRefId(refId,star)
    local name = gModelHeroExtra:GetHeroSetName(itemdata)
    self:SetWndText(HeronNameTrans, name)
    --self:InitTextShowWithLanguage(HeronNameTrans)

    if gLGameLanguage:IsJapanVersion() then
        LxUiHelper.SetSizeWithCurAnchor(HeronNameTrans,1,33)
    end

    -- local showOutfitUpClass = gModelOutfit:ExamineHeroOutfitIsUpClass(id)
    local showOutfitUpClass = false
    CS.ShowObject(UpOutTrans, showOutfitUpClass)

    local raceType = gModelHero:GetHeroType(refId)
    local img = gModelHero:GetRaceImgByRefId(raceType)
    if img then
        self:SetWndEasyImage(RaceImgTrans, img, function()
            CS.ShowObject(RaceImgTrans, true)
        end)
    end

    local quality
    -- if gModelHero:CheckIsShowHeroQualityForeign() then
    local heroRef = gModelHero:GetHeroRef(refId)
    if heroRef then
        quality = heroRef.quality
    end
    -- else
    -- quality = gModelHero:GetHeroQualityByRefId(refId, star)
    -- end
    if quality then
        local listBgBig = gModelItem:GetListBgBigByQuality(quality)
        self:SetWndEasyImage(HeroBgTrans, listBgBig)
        local heorBook1Bg = gModelItem:GetHeorBook1BgByQuality(quality)
        self:SetWndEasyImage(QualityImgTrans, heorBook1Bg)
    end

    --local skin = itemdata.skin
    --if skin and skin > 0 then
    --    effRef = gModelHero:GetShowEffectById(skin)
    --else
    --    effRef = gModelHero:GetHeroShowRefByRefId(refId,star)
    --end
    local iconBig = effRef and effRef.iconBig
    if iconBig then
        self:SetWndEasyImage(HeroMapImgTrans, iconBig, function()
            CS.ShowObject(HeroMapImgTrans, true)
        end, true)
    end

    local showRedPoint = false
    if redPointTrans then
        if self._combatHeroList[id] and (not showOutfitUpClass) then
            showRedPoint = self:GetHeroStatus(id)
        end
        showRedPoint = showRedPoint or gModelPet:HeroLinkPetRedById(id)
        CS.ShowObject(redPointTrans, showRedPoint)
    end

    self:SetWndClick(HeroBgTrans, function()
        self:OpenHeroInfoWnd(itemdata)
    end)

    if not isTry then
        self:RecordFirstHeroIcon(HeroBgTrans)
    end

    local hightEffKey = HightStarEff:GetInstanceID()

    if not self._heroHightStarEff then
        self._heroHightStarEff = {}
    end
    if not self._heroHightStarEff[hightEffKey] then
        self._heroHightStarEff[hightEffKey] = self:CreateWndEffect(HightStarEff, "fx_ui_yingxiong_tujian", hightEffKey, 80, nil, nil, 1, nil, nil, true)
    end

    local checkNum = gModelHero:GeConfigByKey("highHeroStarEffect")
    local isShowHightEff = checknumber(star) >= checknumber(checkNum)
    self._heroHightStarEff[hightEffKey]:SetVisible(isShowHightEff)
end

function UISaga:OnDrawHeroSpCell(list, item, itemdata, itempos, fromHeadTail)
    if self:IsWndClosed() then
        return
    end
    local aniRootTrans = self:FindWndTrans(item, "AniRoot")
    local itemTrans = self:FindWndTrans(aniRootTrans, "IconRoot")
    local nameTrans = self:FindWndTrans(aniRootTrans, "HeronName")
    local redPointTrans = self:FindWndTrans(aniRootTrans, "redPoint")

    local refId = itemdata:GetRefId()
    local instanceID = item:GetInstanceID()
    local itemIconList = self._itemIconList
    local baseClass = itemIconList[instanceID]
    if not baseClass then
        baseClass = CommonIcon:New(self)
        itemIconList[instanceID] = baseClass
        baseClass:Create(itemTrans)
    end
    baseClass:SetCommonReward(LItemTypeConst.TYPE_ITEM, refId, nil)
    self:SetWndClick(itemTrans, function()
        gModelGeneral:OpenItemInfoTip(refId)
    end)
    baseClass:DoApply()

    if nameTrans then
        local name = gModelItem:GetNameByRefId(refId)
        self:SetWndText(nameTrans, name)
        --self:InitTextShowWithLanguage(nameTrans, name)
    end
    if redPointTrans then
        local needNum = gModelItem:GetSuiPianNeedNumByRefId(refId)
        if needNum == nil then
            CS.ShowObject(redPointTrans, false)
        else
            local num = gModelItem:GetNumByRefId(refId)
            CS.ShowObject(redPointTrans, needNum <= num)
        end
    end

    CS.ShowObject(item, true)
end

function UISaga:OnTryRefreshRedPoint(...)
    self:RefreshOnHeroChange(...)
end
function UISaga:RefreshTuJianRedPoint()
    --local status = gModelHeroBook:CheckHeroBookAllRedPointStatus()
    ----if gModelHeroBook:IgnoreHeroJB() then status = false end
    --CS.ShowObject(self.mTuJianBtnRedPoint, status)
    self:RefreshTujian(ModelRedPoint.BAG_HEROMAP)
end

------------------------------------------------------------------
--- 英雄列表
------------------------------------------------------------------
function UISaga:InitScrollView()
    CS.ShowObject(self.mChangeShowHeroBtn, false)
    CS.ShowObject(self.mHeroSpList, false)
    --self:VersionRefresh()
    local showHeroList = self._showHeroBgList
    if showHeroList == 0 then
        --CS.ShowObject(self.mHeroShenList,false)
        --self:InitHeroList()

        CS.ShowObject(self.mHeroList, false)
        self:InitHeroShenList()
    elseif showHeroList == 1 then
        CS.ShowObject(self.mHeroList, false)
        self:InitHeroShenList()
    end
end
function UISaga:RefreshBtnEvent(index)
    if index then
        if index ~= self._btnIndex then
            return
        end
    end
    --[[    for i,v in ipairs(self._listTrans) do
            local show = false
            if i == self._btnIndex then show = true end
            CS.ShowObject(self._selImgList[i],show)
            CS.ShowObject(v,show)
        end]]
    self._btnEvent[self._btnIndex]()
end

function UISaga:_DelayRefreshOnHeroChange()

    self._needRefreshHero = true

    local wndHeroInfo = "UINewSagaInfo"
    local wndInst = GF.FindFirstWndByName(wndHeroInfo)
    if wndInst then
        return
    end
    self:RefreshPanel()
    if self._btnIndex == 1 then
        self:InitScrollView()
    elseif self._btnIndex == 2 then
        self:InitSPScrollView()
    end

    local showRedPoint = false
    local combatHeroList = gModelFormation:GetHeroFormationData(LCombatTypeConst.COMBAT_MAIN)
    for k, v in pairs(combatHeroList) do
        if showRedPoint then
            break
        end
        showRedPoint = self:GetHeroStatus(k)
    end
    if not showRedPoint then
        showRedPoint = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.MAINCITY_HERO_PET)
    end
    CS.ShowObject(self._funcBtnRedPointList[1], showRedPoint)

    self._needRefreshHero = false

end
function UISaga:RefreshItemBtnRedPoint()
    local showItemRedPoint = false
    local itemList = gModelItem:GetItemTypeListByType(ModelItem.Item_DEBRIS)
    --local itemList = gModelItem:GetItemTypeListByTypeList(ModelItem.TYPE_DEBRISLIST)
    local len = #itemList
    if len > 0 then
        for i, v in ipairs(itemList) do
            if showItemRedPoint then
                break
            end
            local refId = v:GetRefId()
            local needNum = gModelItem:GetSuiPianNeedNumByRefId(refId)
            local num = gModelItem:GetNumByRefId(refId)
            showItemRedPoint = needNum and num >= needNum
        end
    end
    if showItemRedPoint then
        local isFull = gModelGeneral:IsFullHeroBag(nil, nil, nil, nil, nil, self:GetWndName(), true)
        if isFull then
            showItemRedPoint = false
        end
    end
    CS.ShowObject(self._funcBtnRedPointList[2], showItemRedPoint)
    CS.ShowObject(self.mAutoCompItemBtnRedPoint, showItemRedPoint)
end

function UISaga:RecordFirstHeroIcon(tran)
    if self._firstHeroIcon then
        return
    end
    self._firstHeroIcon = tran
    self:SendGuideReadyEvent(self:GetWndName())
end

function UISaga:InitSPScrollView(isReset)
    CS.ShowObject(self.mChangeShowHeroBtn, false)
    CS.ShowObject(self.mHeroList, false)
    CS.ShowObject(self.mHeroShenList, false)
    CS.ShowObject(self.mHeroSpList, true)

    local showItemRedPoint = false
    local itemList = gModelItem:GetItemTypeListByType(ModelItem.Item_DEBRIS)
    --local itemList = gModelItem:GetItemTypeListByTypeList(ModelItem.TYPE_DEBRISLIST)
    local len = #itemList
    if len > 0 then
        table.sort(itemList, function(item1, item2)
            local refId1, refId2 = item1:GetRefId(), item2:GetRefId()
            local ref1, ref2 = gModelItem:GetRefByRefId(refId1), gModelItem:GetRefByRefId(refId2)
            return ref1.order < ref2.order
        end)
        for i, v in ipairs(itemList) do
            if not showItemRedPoint then
                local refId = v:GetRefId()
                local needNum = gModelItem:GetSuiPianNeedNumByRefId(refId)
                local num = gModelItem:GetNumByRefId(refId)
                showItemRedPoint = needNum and num >= needNum
            end
            if showItemRedPoint then
                break
            end
        end
    end

    if showItemRedPoint then
        --[[        if not self:CheckIsHaveHeightWnd() then
                end]]
        local isFull = gModelGeneral:IsFullHeroBag(nil, nil, nil, nil, nil, self:GetWndName(), true)
        if isFull then
            showItemRedPoint = false
        end
    end
    CS.ShowObject(self._funcBtnRedPointList[2], showItemRedPoint)
    CS.ShowObject(self.mAutoCompItemBtnRedPoint, showItemRedPoint)

    local itemNum = #itemList

    local uiList = self._uispList
    if not uiList then
        uiList = self:GetUIScroll("key_uiSpList")
        self._uispList = uiList
        uiList:Create(self.mHeroSpList, itemList, function(...)
            self:OnDrawHeroSpCell(...)
        end, UIItemList.SUPER_GRID, false)
        local superList = uiList:GetList()
        superList:EnableLoadAnimation(true)
        superList:SetLoadAnimationScale(0.2, 0.15)
        superList:RefreshList(isReset)
    else
        uiList:RefreshList(itemList, nil, isReset)

        local superList = uiList:GetList()
        if self._saveItemNum and self._saveItemNum == itemNum then
            superList:DrawAllItems(false)
        else
            superList:MoveToPos(1, 0)
            superList:DrawAllItems(not isReset)
        end
    end

    local isEmpty = #itemList < 1
    CS.ShowObject(self.mNoRecord2, isEmpty)

    self._saveItemNum = itemNum
end

function UISaga:OnDrawStarList(trans, star)
    local img, temp, index = LUtil.GetHeroStarImg(star)
    local StarTrans
    local showStarImg
    for i = 1, 5 do
        StarTrans = self:FindWndTrans(trans, "Star" .. i)
        showStarImg = temp >= i
        CS.ShowObject(StarTrans, showStarImg)
        if showStarImg then
            self:SetWndEasyImage(StarTrans, img)
        end
    end
end

function UISaga:InitEmptyList()
    local data = {
        refId = 10008,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UISaga:OnClickHelp()
    GF.OpenWnd("UIBzTips", { refId = 145 })
end

function UISaga:GetCareerTypeList()
    local list = {}
    table.insert(list, {
        refId = UIHeroRaceList.ALL_RACE_REFID,
        icon = "public_race_0",
    })
    for k, v in pairs(GameTable.CharacterCareerRef) do
        table.insert(list, {
            refId = k,
            icon = v.jobIcon
        })
    end
    table.sort(list, function(a, b)
        return a.refId < b.refId
    end)
    local listLen = #list
    local allRaceNum = gModelHero:GetAllRaceNum()
    local loseNum = allRaceNum - listLen
    if loseNum > 0 then
        for i = 1, loseNum do
            table.insert(list, {
                show = false,
            })
        end
    end

    return list
end

function UISaga:RefreshOnHeroChange()
    if self._isNeedHeroRefresh then
        return
    end
    local nextTime = self._nextRefreshTime
    if not nextTime or Time.time >= nextTime then
        self._nextRefreshTime = Time.time + 0.5
        self._isNeedHeroRefresh = nil
        self:_DelayRefreshOnHeroChange()
        return
    end
    self._isNeedHeroRefresh = true
    local recordTimer = self._recordTimer
    if not recordTimer then
        self._recordTimer = LxTimer.LoopTimeCall(function()
            if self._isNeedHeroRefresh then
                if not self._nextRefreshTime or Time.time >= self._nextRefreshTime then
                    self._isNeedHeroRefresh = nil
                    self._nextRefreshTime = Time.time + 0.5
                    self:_DelayRefreshOnHeroChange()
                end
            end
        end, 0.1)
    end

end
function UISaga:RefreshTimeWearRedPoint()
    CS.ShowObject(self.mTimeWearBtnRedPoint, gModelSkinBook:CheckTimeWearActRedPointStatus())
end

function UISaga:FuncBtnEvent(index)
    if index == self._btnIndex then
        return
    end
    CS.ShowObject(self.mHeroContainerBg, index == 1)
    CS.ShowObject(self.mTypeBtnList, index ~= 2)
    self._btnIndex = index
    for i, v in ipairs(self._funcBtnList) do
        local show = i == index and 0 or 1
        self:SetWndTabStatus(v, show)
    end
    CS.ShowObject(self.mPack1, index ~= 2)
    CS.ShowObject(self.mDi2, index == 2)
    CS.ShowObject(self.mAutoCompItemBtn, index == 2)
    self:RefreshBtnEvent()
end

function UISaga:RefreshHeroView(isReset)
    --local newInfo = gModelGeneral:IsNewHeroWnd()
    local wndHeroInfo = "UINewSagaInfo"
    local wndInst = GF.FindFirstWndByName(wndHeroInfo)
    if not wndInst then
        if self._btnIndex == 1 then
            self:InitScrollView()
        elseif self._btnIndex == 2 then
            self:InitSPScrollView(isReset)
        end
    else
        self._isOpenInfoWnd = true
    end
    local showRedPoint = false
    local combatHeroList = gModelFormation:GetHeroFormationData(LCombatTypeConst.COMBAT_MAIN)
    for k, v in pairs(combatHeroList) do
        if showRedPoint then
            break
        end
        showRedPoint = self:GetHeroStatus(k)
    end
    if not showRedPoint then
        showRedPoint = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.MAINCITY_HERO_PET)
    end
    CS.ShowObject(self._funcBtnRedPointList[1], showRedPoint)
end
------------------------------------------------------------------
--- 动画
------------------------------------------------------------------
function UISaga:PlayRaceBtnAni()
    --[[    if self.isPlayEffect then return  end
        self.isPlayEffect = not self.isPlayEffect
        local isShow = self._showRaceBtnList
        local moveTrans = self.mRaceTypeBg
        self:TweenSeqKill(self._moveRaceKey)

        local seqTween = self:TweenSeqCreate(self._moveRaceKey,function(seq)
            local showTime = 0.1
            local pos,fromAlpha,toAlpha
            -- 展开
            if isShow then
                pos = 72.2
                fromAlpha,toAlpha = 0,1
            else
                pos = 0
                fromAlpha,toAlpha = 1,0
            end
            CS.ShowObject(self.mLine1,not isShow)
            CS.ShowObject(self.mLine2,isShow)
            CS.ShowObject(self.mUnfoldBtn,not isShow)
            CS.ShowObject(self.mDi,not isShow)
            CS.ShowObject(self.mDi1,isShow)
            local trans = self.mCareerTypeBg
            local Ease = DG.Tweening.Ease.OutCubic
            local vec = Vector2.New(moveTrans.localPosition.x,moveTrans.localPosition.y + pos)
            local tweener = trans:DOLocalMove(vec,showTime)
            seq:Join(tweener)
            local canvasGroup = trans:GetComponent(typeofCanvasGroup)
            if canvasGroup then
                CS.ShowObject(trans,isShow)
                local _temp = YXTween.TweenFloat(fromAlpha, toAlpha, showTime, function(ival)
                    canvasGroup.alpha = ival
                end):SetEase(Ease)
                seq:Join(_temp)
            end
            return seq
        end)
        seqTween:PlayForward()
        seqTween:OnComplete(function()
            self.isPlayEffect = not self.isPlayEffect
            self:TweenSeqKill(self._moveRaceKey)
        end)]]

    local isShow = self._showRaceBtnList
    CS.ShowObject(self.mLine1, not isShow)
    CS.ShowObject(self.mLine2, isShow)
    CS.ShowObject(self.mUnfoldBtn, not isShow)
    CS.ShowObject(self.mDi, not isShow)
    CS.ShowObject(self.mDi1, isShow)

    local sizeY = isShow and -215 or -150
    local size = Vector2.New(self.mHeroShenList.sizeDelta.x, sizeY)
    self.mHeroShenList.sizeDelta = size

    local posY = isShow and 60 or 27.5
    self.mHeroShenList.localPosition = Vector3(self.mHeroShenList.localPosition.x, posY, 0)
end

function UISaga:GetHeroFirstHeroIcon()
    return self._firstHeroIcon
end

function UISaga:RefreshForeign()
    if self._isVie then
        self:InitTextLineWithLanguage(self.mTimeWearBtnTxt, 30)

        self:InitTextSizeWithLanguage(self.mLblBiaoti, -8)
        local typeOfRectTransform = typeof(UnityEngine.RectTransform)
        local rectTran = self.mLblBiaoti:GetComponent(typeOfRectTransform)
        self:SetAnchorPos(rectTran, Vector2.New(-60,- 132))
    end
end

function UISaga:InitRaceTypeList()
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
            self:RefreshBtnEvent()
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

-- function UISaga:GetHeroStatus(id)
--     local showRedPoint = false
--     showRedPoint = gModelHero:GetHeroUpStatus(id)
--     return showRedPoint
-- end

function UISaga:OnDrawHeroCell(list, item, itemdata, itempos, fromHeadTail)
    if self:IsWndClosed() then
        return
    end

    local aniRootTrans = self:FindWndTrans(item, "AniRoot")
    local heroTrans = self:FindWndTrans(aniRootTrans, "IconRoot")
    local refId = itemdata.refId
    local id = itemdata.id
    local instanceID = item:GetInstanceID()
    local heroIconList = self._heroIconList
    local baseClass = heroIconList[instanceID]

    if not baseClass then
        baseClass = CommonIcon:New(self)
        heroIconList[instanceID] = baseClass
        baseClass:Create(heroTrans)
    end
    local combatHeroList = self._combatHeroList or {}
    local isMain = combatHeroList[id] ~= nil
    local isTry = itemdata.isTry
    if isTry then
        isMain = false
    end
    baseClass:SetHeroPlayer(id)
    baseClass:SetMainFormationStatus(isMain)
    baseClass:DoApply()

    self:SetWndClick(heroTrans, function()
        self:OpenHeroInfoWnd(itemdata)
    end)
    local heronNameTrans = self:FindWndTrans(aniRootTrans, "HeronName")
    if heronNameTrans then
        --[[        local star = itemdata.star
                local name = gModelHero:GetHeroNameByRefId(refId,star)]]
        local heroName = gModelHeroExtra:GetHeroSetName(itemdata)
        self:SetWndText(heronNameTrans, heroName)
        --self:InitTextShowWithLanguage(heronNameTrans)
    end

    local UpOutTrans = self:FindWndTrans(aniRootTrans, "UpOut")
    -- local showOutfitUpClass = gModelOutfit:ExamineHeroOutfitIsUpClass(id)
    local showOutfitUpClass = false
    CS.ShowObject(UpOutTrans, showOutfitUpClass)

    local showRedPoint = false
    local redPointTrans = self:FindWndTrans(aniRootTrans, "redPoint")
    if redPointTrans then
        if self._combatHeroList[id] and (not showOutfitUpClass) then
            showRedPoint = self:GetHeroStatus(id)
        end
        showRedPoint = showRedPoint or gModelPet:HeroLinkPetRedById(id)
        CS.ShowObject(redPointTrans, showRedPoint)
    end

    if not isTry then
        self:RecordFirstHeroIcon(heroTrans)
    end
end

function UISaga:GetShowHeroBgList()
    if gLGameLanguage:IsUSARegion() then
        return tonumber(LPlayerPrefs.showHeroBgListForeign)
    else
        return tonumber(LPlayerPrefs.showHeroBgList)
    end
end

function UISaga:GetHeroStatus(id)
    local showRedPoint = false
    showRedPoint = gModelHero:GetHeroUpStatus(id)
    return showRedPoint
end

function UISaga:RefreshPanel(refresh)
    local bagNum = gModelHero:GetHoerBagNum()
    local buyNum = gModelHero:GetHeroBagExpNum()
    if buyNum == nil then
        gModelHero:OnHeroBagExpandReq(1)
        return
    end
    local heroNum = gModelHero:GetHeroNum()
    if not heroNum then
        heroNum = 0
    end
    local str = ccClientText(10008)
    str = string.replace(str, heroNum, bagNum)
    self:SetWndText(self.mHeroNum, str)
    self:InitTextSizeWithLanguage(self.mHeroNum, -2)

    if not refresh then
        self:SetXUITextText(self.mLblBiaoti, ccClientText(10007))
    end
end

function UISaga:autoCompItemFunc()
    gModelItem:AutoCompItemFunc(self:GetWndName())
end

function UISaga:RefreshFormationBtn()
    local showFormation = true
    local dataList = gModelFormation:GetCombatTypeList()
    if #dataList <= 0 then
        showFormation = false
    end

    CS.ShowObject(self.mFormationBtn, showFormation)

end

function UISaga:OnClickChangeShowHeroBtnFunc()
    self._showHeroBgList = self:GetShowHeroBgList()
    if self._showHeroBgList == 0 then
        self._showHeroBgList = 1
    elseif self._showHeroBgList == 1 then
        self._showHeroBgList = 0
    end

    self:SetShowHeroBgList(self._showHeroBgList)
    self:InitScrollView()
end
function UISaga:ChangeSelImgParent(imgTrans, btnTrans)
    CS.SetParentTrans(imgTrans, btnTrans)
end

function UISaga:OnWndRefresh()
    local page = self:GetWndArg("page") or 1
    self:FuncBtnEvent(page)

end

function UISaga:SetShowHeroBgList(showValue)
    if gLGameLanguage:IsUSARegion() then
        LPlayerPrefs.SetShowHeroBgListForeign(showValue)
    else
        LPlayerPrefs.SetShowHeroBgList(showValue)
    end
end

function UISaga:OnClickCareerTypeFunc(refId)
    if self._careerType == refId then
        return
    end
    self._careerType = refId
    self:RefreshBtnEvent()

    local uiCareerTypeList = self._uiCareerTypeList
    if not uiCareerTypeList then
        return
    end
    local uiList = uiCareerTypeList:GetList()
    uiList:RefreshList()
end

function UISaga:InitText()
    self:SetWndText(self.mBuZhenBtnTxt, ccClientText(19753))
    self:SetWndText(self.mTuJianBtnTxt, ccClientText(19754))
    self:SetWndText(self.mBaowuBtnTxt, ccClientText(19756))
    self:SetWndText(self.mRuneComBtnTxt, ccClientText(20132))
    self:SetWndText(self.mSorceryCardText, ccClientText(29526))
    self:SetWndButtonText(self.mAutoCompItemBtn, ccClientText(10243))

    CS.ShowObject(self.mHelpBtn, gLGameLanguage:IsForeignRegion())
end

function UISaga:RefreshOpen()

    --CS.ShowObject(self.mBaowuBtn,gModelFunctionOpen:CheckIsShow(17400001))

    local isShowTuJian = gModelHeroBook:CheckIsShowHeroBook()
    CS.ShowObject(self.mTuJianBtn, isShowTuJian)
    --CS.ShowObject(self.mRuneComBtn,gModelFunctionOpen:CheckIsShow(16100001))
    local isRusRegion = gLGameLanguage:IsRussiaRegion()
    local isRusLng = gLGameLanguage:IsRussiaVersion()
    local isRus = isRusRegion or isRusLng
    local resType = LPlayerPrefs.GetIsForceSensitiveRes()
    if isRus then
        if resType > 0 then --保守
            CS.ShowObject(self.mBtnSorceryCard,false)
        else
            CS.ShowObject(self.mBtnSorceryCard,true)
        end
    end
    CS.ShowObject(self.mBtnSorceryCard, gModelFunctionOpen:CheckIsShow(28000000))
end

function UISaga:OnAwake()
    LWnd.OnAwake(self)
    self:DelaySendFinish(0.31)
end

function UISaga:InitHeroList()
    CS.ShowObject(self.mHeroList, true)

    local allListData = self:GetHeroList()

    local heroNum = self._heroNum or 1

    local uiList = self._uiList
    if not uiList then
        uiList = self:GetUIScroll("mHeroList")
        self._uiList = uiList
        uiList:Create(self.mHeroList, allListData, function(...)
            self:OnDrawHeroCell(...)
        end, UIItemList.SUPER_GRID, false)
        local superList = uiList:GetList()
        superList:EnableLoadAnimation(true)
        superList:SetLoadAnimationScale(0.2, 0.15)
        superList:RefreshList()
    else
        uiList:RefreshList(allListData)

        local superList = uiList:GetList()
        if self._saveHeroNum and self._saveHeroNum == heroNum then
            superList:DrawAllItems(false)
        else
            superList:MoveToPos(1, 0)
            superList:DrawAllItems(true)
        end
    end

    local isEmpty = #allListData < 1
    CS.ShowObject(self.mNoRecord2, isEmpty)

    self._saveHeroNum = heroNum
end

function UISaga:InitHeroShenList()
    if GF.FindFirstWndByName("UISkinUpOpt") or GF.FindFirstWndByName("UISagaSn") then
        return
    end
    
    CS.ShowObject(self.mHeroShenList, true)

    local allListData = self:GetHeroList()

    local heroNum = self._heroNum or 1

    local uiHeroShenList = self._uiHeroShenList
    if not uiHeroShenList then
        uiHeroShenList = self:GetUIScroll("mHeroShenList")
        self._uiHeroShenList = uiHeroShenList
        uiHeroShenList:Create(self.mHeroShenList, allListData, function(...)
            self:OnDrawHeroShenCell(...)
        end, UIItemList.SUPER_GRID, false)
        local superList = uiHeroShenList:GetList()
        superList:EnableLoadAnimation(true)
        superList:SetLoadAnimationScale(0.2, 0.15)
        superList:RefreshList()
    else
        uiHeroShenList:RefreshList(allListData)

        local superList = uiHeroShenList:GetList()
        self:RefreshSuperList(superList,allListData,function()
            if self._saveHeroNum and self._saveHeroNum == heroNum then
                superList:DrawAllItems(false)
            else
                superList:MoveToPos(1, 0)
                superList:DrawAllItems(true)
            end
        end)
    end
    local isEmpty = #allListData < 1
    CS.ShowObject(self.mNoRecord2, isEmpty)
    self._saveHeroNum = heroNum
end
------------------------------------------------------------------
return UISaga


