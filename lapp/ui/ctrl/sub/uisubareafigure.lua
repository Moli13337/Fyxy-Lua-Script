---
--- Created by BY.
--- DateTime: 2023/10/25 21:25:53
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubAreaFigure:LChildWnd
local UISubAreaFigure = LxWndClass("UISubAreaFigure", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubAreaFigure:UISubAreaFigure()
    self._status = 0
    self._raceList = {}
    self._tabList = {}
    self._spineKey = "spineKey"
    self.tipsByType = {
        [1] = ccClientText(21181),
        [2] = ccClientText(21189),
        [3] = ccClientText(21182),
        [4] = ccClientText(21183)
    }
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubAreaFigure:OnWndClose()
    FireEvent("UISubAreaFigure_change_figure", gModelPlayer:GetPlayerFigure())
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubAreaFigure:OnCreate()
    LChildWnd.OnCreate(self)

    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubAreaFigure:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    self:RefreshForeign()
end

function UISubAreaFigure:InitCommand()
    self._figure = gModelPlayer:GetPlayerFigure()
    self._isUseId = self._figure
    self._isFigure = false
    self:OnClickCut()
    self._raceType = 0

    self:RefreshRace()
    self:InitTabScroll()
end

function UISubAreaFigure:InitTabScroll()
    self._status = 0
    self._activateList = gModelPlayer:GetPersonaliseInfo(ModelPlayerSpace.ROLE_FIGURE)
    if (not self._activateList) then
        self._status = 1
        gModelPlayer:OnPersonaliseInfoReq(ModelPlayerSpace.ROLE_FIGURE)
        return
    end

    local refTypes = gModelPlayer:GetRoleAdventureImageTypeRef(ModelPlayerSpace.ROLE_FIGURE)
    local list = {}
    for i,v in ipairs(refTypes) do
        local datas = self:GetHeroList(v.type,0)
        if datas and #datas > 0 then
            table.insert(list,v)
        end
    end
    local _uiList = self:GetUIScroll("figureType")
    _uiList:Create(self.mTabScroll, list, function(...)
        self:ListItem(...)
    end)

    -- self:SetAnchorPos(self.mTabScroll, Vector2.New(-262, -99)
    self.mTabScroll.sizeDelta = Vector2.New(94, (94 * #list) + (#list * 3) - 3)

    local page = self:GetWndArg("page")
    local openType
    if not page then
        local cfg = gModelPlayer:GetRoleAdventureImageRefByRefId(self._figure)
        if cfg then
            openType = cfg.type
        else
            openType = list[1].type
        end
    else
        openType = list[page].type
    end
    self:OnClickTab(openType)
end

function UISubAreaFigure:HeroListItem(list, item, itemdata, itempos)
    local bg = CS.FindTrans(item, "Bg")
    local spine = CS.FindTrans(item, "Spine")
    local bgFrame = CS.FindTrans(item, "BgFrame")
    local name = CS.FindTrans(item, "Name")
    local mask = CS.FindTrans(item, "Mask")
    local lockText = CS.FindTrans(mask, "LockText")
    local isSel = CS.FindTrans(item, "IsSel")
    local isUse = CS.FindTrans(item, "IsUse")
    local ref = gModelPlayer:GetRoleAdventureImage(itemdata.refId)
    local effCfg = GameTable.CharacterEffectRef[ref.hero]
    local quality = GameTable.CharacterRef[effCfg.heroType].quality
    local qualityEff = GameTable.RarityRef[quality]
    self:SetWndEasyImage(bg, qualityEff.heorBook1Bg)
    self:SetWndEasyImage(bgFrame, qualityEff.listBgBig)
    self:SetWndText(name, ccLngText(effCfg.name))
    -- self:SetWndText(lockText, ccLngText(ref.description))
    local activateList = self._activateList or {}
    local bLock = not activateList[itemdata.refId]
    local iconBig = effCfg.iconBig
    if bLock then
        iconBig = gModelHeroExtra:GetShieldIconBig(iconBig,effCfg)
    end
    self:SetWndEasyImage(spine, iconBig)

    CS.ShowObject(mask, bLock)

    CS.ShowObject(isSel, itemdata.refId == self._figure)
    CS.ShowObject(isUse, itemdata.refId == self._isUseId)

    self:SetWndClick(item, function()
        if bLock then
            if ref then
                local tips = self.tipsByType[self._type]
                GF.ShowMessage(string.replace(tips,ccLngText(ref.name)))
            end
        else
            FireEvent("UISubAreaFigure_change_figure", itemdata.refId)
            self:OnClickHeroIcon(itemdata.refId, itempos)
        end
    end)
end

function UISubAreaFigure:OnClickTab(type)
    if self._type then
        if self._type == type then
            return
        end
        self:SetWndTabStatus(self._tabList[self._type], 1)
    end
    self._type = type
    self:SetWndTabStatus(self._tabList[type], 0)
    self:RefreshHeroList()
end

function UISubAreaFigure:OnClickSave()
    local _figure = self._figure
    if self._isUseId == _figure then
        GF.ShowMessage(ccClientText(21166))
        return
    end
    if self._activateList[_figure] then
        gModelPlayer:OnPersonaliseChangeReq(ModelPlayerSpace.ROLE_FIGURE, _figure)
    else
        local ref = gModelPlayer:GetRoleAdventureImage(_figure)
        if not gModelFunctionOpen:CheckIsOpened(ref.jump, true) then
            return
        end
        gModelFunctionOpen:Jump(ref.jump)
    end
end

function UISubAreaFigure:RefreshForeign()
    if gLGameLanguage:IsVieVersion() then
        self:InitTextLineWithLanguage(self.mSaveText,0)
        self:InitTextLineWithLanguage(self.mCompileText,0)
    end
end

function UISubAreaFigure:RefreshData()
    self:RefreshHeroList()
    self:RefreshFigure()
end

function UISubAreaFigure:ShowUI()
    local tweenSeq = YXTween.TweenSequenceIns()
	local moveFunc = function(value)
		self:SetAnchorPos(self.mTop, Vector2.New(0, 600 - value))
		self:SetAnchorPos(self.mBottom, Vector2.New(0, -600 + value))
        self:SetAnchorPos(self.mRight, Vector2.New(600 - value, 568))
        self:SetAnchorPos(self.mLeft, Vector2.New(-600 + value, 568))
	end
	local moveTween = YXTween.TweenFloat(0, 600, 0.5, moveFunc):SetEase(DG.Tweening.Ease.InSine)
	tweenSeq:Append(moveTween)
	tweenSeq:PlayForward()
end

function UISubAreaFigure:OnClickShow()
    if not self.showState then
        self.showState = true
    else
        self.showState = not self.showState
    end
    local img = "public_btn_icon_33_1"
    if self.showState then
        img = "public_btn_icon_33"
        self:HideUI()
    else
        self:ShowUI()
    end
    self:SetWndEasyImage(self.mBtnShow, img)
end

function UISubAreaFigure:CheckIsUse(refId)
    local activateList = self._activateList or {}
    return activateList[refId]
end

function UISubAreaFigure:GetHeroList(type,raceType)
    local list = {}
    local bIns = false
    local refs = gModelPlayer:GetRoleAdventureImageRefListByType(type)
    for i, v in pairs(refs) do
        local effRef = gModelHero:GetShowEffectById(v.hero)
        if effRef then
            bIns = false
            if gModelHeroExtra:NeedCheckResType() then
                if type == 1 or not gModelHeroExtra:CheckBookIsCalm(effRef.refId) then
                    bIns = true
                end
            else
                bIns = true
            end
            if bIns then
                local heroRef = gModelHero:GetHeroRef(effRef.heroType)
                if raceType == 0 or heroRef.raceType == raceType then
                    table.insert(list, v)
                end
            end
        end

    end
    table.sort(list, function(a, b)
        local ais = a.refId == self._isUseId and 0 or 1
        local bis = b.refId == self._isUseId and 0 or 1
        if not self._isOne then
            if ais ~= bis then
                return ais < bis
            end
        end
        ais = self._activateList[a.refId] and 0 or 1
        bis = self._activateList[b.refId] and 0 or 1
        if ais ~= bis then
            return ais < bis
        end
        return a.sort < b.sort
    end)
    return list
end

function UISubAreaFigure:RefreshHeroList()
    self._activateList = gModelPlayer:GetPersonaliseInfo(ModelPlayerSpace.ROLE_FIGURE)
    if (not self._activateList) then
        gModelPlayer:OnPersonaliseInfoReq(ModelPlayerSpace.ROLE_FIGURE)
        return
    end
    local list = self:GetHeroList(self._type,self._raceType)
    self._heroDataList = list
    local uiHeroList = self._uiHeroList
    if uiHeroList then
        uiHeroList:RefreshList(list)
        local _uiListSuper = uiHeroList:GetList()
        _uiListSuper:DrawAllItems()
    else
        uiHeroList = self:GetUIScroll("roloFigure")
        uiHeroList:Create(self.mHeroListScroll, list, function(...)
            self:HeroListItem(...)
        end, UIItemList.SUPER_GRID)
        -- uiHeroList:EnableScroll(true, true)
        self._uiHeroList = uiHeroList
    end
    self:ChangeSaveBtn()
    self:RefreshSpineAni()
    --self._isOne = true
end

function UISubAreaFigure:RaceListItem(list, item, itemdata, itempos)
    local image = CS.FindTrans(item, "Image")
    local selImg = CS.FindTrans(item, "SelImg")

    CS.ShowObject(selImg, self._raceType == itemdata.refId)
    self._raceList[itemdata.refId] = selImg

    -- if self._type == 3 and itemdata.refId ~= 0 then
    --     self:SetWndEasyImage(image, "public_race_icon_buff_0")
    --     self:SetWndClick(item, function(...)
    --     end)
    -- else
        self:SetWndEasyImage(image, itemdata.icon)
        self:SetWndClick(item, function(...)
            self:OnClickRace(itemdata.refId)
        end)
    -- end
end

function UISubAreaFigure:ListItem(list, item, itemdata, itempos)
    self._tabList[itemdata.type] = item
    local instanceId = item:GetInstanceID()
    if not self:FindWndEffectByKey(instanceId) then
        local on = CS.FindTrans(item, "On")
        self:CreateWndEffect(on, "fx_ui_geren_yeqian", instanceId, 100, false, false)
    end

    if gLGameLanguage:IsVieVersion() then
        self:SetWndTabText(item, ccLngText(itemdata.name),-7,0)
    else
        self:SetWndTabText(item, ccLngText(itemdata.name))
    end

    self:SetWndTabStatus(item, 1)
    self:SetWndClick(item, function()
        self:OnClickTab(itemdata.type)
        if itemdata.type == 3 then
            self:OnClickRace(0)
        end
        self:RefreshRace()
    end)
end

function UISubAreaFigure:SetRolePaint(ref)
    local paintTans = self.mSpine
    if (not ref) then
        return
    end
    local spine = self:FindWndSpineByKey(self._spineKey)
    if (spine) then
        self:DestroyWndSpineByKey(self._spineKey)
    end
    local paint, paintMultiple, pos
    if self._isFigure then
        paintMultiple = ref.paintMultiple
        paint = ref.paint
        pos = ref.rolePaint
    else
        paintMultiple = ref.heroFightMultiple
        paint = ref.spine
        pos = ref.roleHeroFight
    end

    local refId = ref.refId
    local paintFlip = ref.paintFlip == 1
    self:CreateWndSpine(paintTans, paint, self._spineKey, false, function(dpSpine)
        dpSpine:SetScale(paintMultiple)
        dpSpine:SetFlipX(paintFlip)
        local dpTrans = dpSpine:GetDisplayTrans()
        if CS.IsNullObject(dpTrans) then
            return
        end
        dpTrans.anchorMin = Vector2.New(0.5, 0.5)
        dpTrans.anchorMax = Vector2.New(0.5, 0.5)
        local posArr = string.split(pos, ",")
        dpTrans.localPosition = Vector2.New(tonumber(posArr[1]), tonumber(posArr[2]))

        self:RefreshSpineAni()

        if self._isFigure then
            self:SetWndClick(self.mSpine, function()
                self:SetRunSpineAin(self._spineKey,refId)
            end)
        else
            self:SetWndClick(dpTrans, function()

            end)
        end
    end)
end

function UISubAreaFigure:OnClickHeroIcon(refId, itempos)
    --if not self:CheckIsUse(refId) then
    --    local ref = gModelPlayer:GetRoleAdventureImage(refId)
    --    if ref then
    --        GF.ShowMessage(string.replace(ccClientText(41319),ccLngText(ref.name)))
    --    end
    --    return
    --end
    local oldClickHeroIcon = self._curClickHeroIcon
    local oldFigure = self._figure
    if oldFigure ~= refId then
        for k, v in ipairs(self._heroDataList) do
            if v.refId == oldFigure then
                oldClickHeroIcon = k
                break
            end
        end
    end

    self._figure = refId
    if oldClickHeroIcon then
        self._uiHeroList:DrawItemByIndex(oldClickHeroIcon)
    end

    self._curClickHeroIcon = itempos
    self._uiHeroList:DrawItemByIndex(itempos)
    self:RefreshFigure()
end

function UISubAreaFigure:RefreshSpineAni()
    local spine = self:FindWndSpineByKey(self._spineKey)
    if not spine then return end

    local ref = gModelPlayer:GetRoleAdventureImage(self._figure)
    if not ref then return end

    local showUse = self:CheckIsUse(ref.refId)
    local aniName = showUse and "idle" or "calm"
    if LOG_INFO_ENABLED then
        printInfoNR2("刷新空间 Spine 动作：",">> 播放的动画名称：" .. aniName)
    end
    spine:PlayAnimationSolid(aniName, true)
end

function UISubAreaFigure:ChangeSaveBtn()
    local icon, text
    if self._activateList[self._figure] then
        icon = "role_btn_3"
        text = ccClientText(21113)

        if PRODUCT_G_VER == 1 then
            CS.ShowObject(self.mBtnSave, true) --ios写死屏蔽
        end

    else
        icon = "role_btn_4"
        text = ccClientText(21116)

        if PRODUCT_G_VER == 1 then
            CS.ShowObject(self.mBtnSave, false) --ios写死屏蔽
        end
    end
    self:SetWndEasyImage(self.mSaveIcon, icon)
    self:SetWndText(self.mSaveText, text)
end

function UISubAreaFigure:RefreshFigure()
    local ref = gModelPlayer:GetRoleAdventureImage(self._figure)
    if not ref then
        return
    end
    local effRef = gModelHero:GetShowEffectById(ref.hero)
    local heroRef = gModelHero:GetHeroRef(effRef.heroType)
    if not heroRef then
        return
    end
    -- self:SetWndEasyImage(self.mTitleBg, "hero_title_" .. heroRef.quality)
    local raceCfg = GameTable.CharacterRaceRef[heroRef.raceType]
    self:SetWndEasyImage(self.mRaceIcon, raceCfg.icon)
    local name = ccLngText(ref.name)
    if gLGameLanguage:IsForeignVersion() then
        name = string.format("<size=20>%s</size>", name)
    end
    self:SetWndText(self.mTitleText, name)
    self:SetWndText(self.mLockText, ccLngText(ref.description))
    self:SetWndText(self.mAttrText, ccLngText(ref.attrDesc))
    CS.ShowObject(self.mAttrBg, not string.isempty(ref.attrDesc))
    self:SetRolePaint(ref)
end

function UISubAreaFigure:OnClickRace(type)
    if self._raceType then
        if self._raceType == type then
            return
        end
        CS.ShowObject(self._raceList[self._raceType], false)
    end
    self._raceType = type
    CS.ShowObject(self._raceList[type], true)
    self:RefreshHeroList()
end

function UISubAreaFigure:InitEvent()
    self:SetWndClick(self.mBtnFigure, function()
        self:OnClickCut()
    end)
    self:SetWndClick(self.mBtnSave, function()
        self:OnClickSave()
    end)
    self:SetWndClick(self.mBtnShow, function()
        self:OnClickShow()
    end)
end

function UISubAreaFigure:RefreshRace()
    local list = gModelHero:GetHeroRaceRefSortByRank()
    --table.insert(list, { refId = 0, icon = "public_race_0" })
    --table.sort(list, function(a, b)
    --    return a.refId < b.refId
    --end)
    local _uiRaceList = self._uiRaceList
    if list and #list > 0 then
        if _uiRaceList then
            _uiRaceList:RefreshList(list)
            _uiRaceList:DrawAllItems()
        else
            _uiRaceList = self:GetUIScroll("mRaceScroll")
            _uiRaceList:Create(self.mRaceScroll, list, function(...)
                self:RaceListItem(...)
            end, UIItemList.SUPER_GRID)
        end
    end
end

function UISubAreaFigure:InitMessage()
    self:WndNetMsgRecv(LProtoIds.PersonaliseInfoResp, function(pb)
        if self._status and self._status == 1 then
            self._status = 0
            self:InitTabScroll()
        else
            self:RefreshHeroList()
        end
    end)
    self:WndNetMsgRecv(LProtoIds.PersonaliseUpdateResp, function(pb)
        gModelPlayer:OnPersonaliseInfoReq(ModelPlayerSpace.ROLE_FIGURE)
    end)
    self:WndNetMsgRecv(LProtoIds.PersonaliseChangeResp, function(pb)
        if pb.type ~= ModelPlayerSpace.ROLE_FIGURE then
            return
        end
        self._isOne = true
        GF.ShowMessage(string.replace(ccClientText(21152), ccClientText(21102)))
        self._isUseId = pb.parameter
        self._figure = pb.parameter
        self:RefreshData()
    end)
end

function UISubAreaFigure:OnClickCut()
    local icon, text
    self._isFigure = not self._isFigure
    if self._isFigure then
        icon = "role_btn_1"
        text = ccClientText(21114)
    else
        icon = "role_btn_2"
        text = ccClientText(21115)
    end
    self:SetWndText(self.mCompileText, text)
    self:SetWndEasyImage(self.mCompileIcon, icon)
    self:RefreshFigure()
end

function UISubAreaFigure:SetRunSpineAin(key,refId)
    local dpSpine = self:FindWndSpineByKey(key)
    if not dpSpine:IsDpValid() then return end
    if not dpSpine:GetAnimation("attack1") then return end
    if refId and refId > 0 then
        --- 未获得不进行下面逻辑
        if not self:CheckIsUse(refId) then return end
    end
    local entryName = dpSpine:GetCurTrackEntryName()
    if entryName ~= "attack1" then
        dpSpine:PlayAnimation(0, "attack1", false)
        dpSpine:SetAnimationCompleteFunc(function(ainName)
            if ainName == "attack1" then
                dpSpine:PlayAnimation(0, "idle", true)
            end
        end)
    end
end

function UISubAreaFigure:HideUI()
    local tweenSeq = YXTween.TweenSequenceIns()
	local moveFunc = function(value)
		self:SetAnchorPos(self.mTop, Vector2.New(0, 0 + value))
		self:SetAnchorPos(self.mBottom, Vector2.New(0, 0 - value))
        self:SetAnchorPos(self.mRight, Vector2.New(0 + value, 568))
        self:SetAnchorPos(self.mLeft, Vector2.New(0 - value, 568))
	end
	local moveTween = YXTween.TweenFloat(0, 600, 0.5, moveFunc):SetEase(DG.Tweening.Ease.InSine)
	tweenSeq:Append(moveTween)
	tweenSeq:PlayForward()
end
------------------------------------------------------------------
return UISubAreaFigure


