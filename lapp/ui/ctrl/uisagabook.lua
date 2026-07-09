---
--- Created by Administrator.
--- DateTime: 2023/10/26 15:44:18
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaBook:LWnd
local UISagaBook = LxWndClass("UISagaBook", LWnd)

local Time = Time
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUISkillCtrl = LxRequire("LApp.UI.Display.LUISkillCtrl")
local LUIDrawingCtrl = LxRequire("LApp.UI.Display.LUIDrawingCtrl")
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)

UISagaBook.CARD_MAX_NUM = 3            -- 英雄图鉴一行个数
UISagaBook.CHANGEPAGE_FORWARD = 1      -- 向前翻页
UISagaBook.CHANGEPAGE_BACKWARDS = 2    -- 向后翻页

UISagaBook.JB_STATUS_NOACT = 0         -- 未激活
UISagaBook.JB_STATUS_CANRECEIVE = 1       -- 领取奖励
UISagaBook.JB_STATUS_RECEIVE = 2       -- 已经领取奖励

UISagaBook.MORE_HERO_NUM = 5

UISagaBook.NOACT_TEXT_COLOR = "9f835cff"
UISagaBook.ACT_TEXT_COLOR = "139057ff"

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaBook:UISagaBook()
    ---@type LUIDrawingCtrl
    self._uiDrawingCtrl = nil
    self._uiHeroLiHuiList = nil        -- 立绘列表
    self._curUILiHuiObj = nil            -- 当前立绘
    self._loopHeroObjTimerKey = 1119
    ---@type table<number,CommonIcon>
    self._uiCommonList = {}
    self._effectKey = "_effectKey"
    self._colorGradientDefault = "FFFFFFFF"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaBook:OnWndClose()
    if self._uiDrawingCtrl then
        self._uiDrawingCtrl:Destroy()
        self._uiDrawingCtrl = nil
    end
    LUtil.ClearHashTable(self._uiHeroLiHuiList)
    self._uiHeroLiHuiList = nil
    self._curUILiHuiObj = nil
    self:ClearCommonIconList(self._uiCommonList)
    self._uiCommonList = nil

    GF.CloseWndByName("UIOrdinBulletSay")
    gModelHeroBook:SetHeroBookInfoList()

    if self._func then self._func() end

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaBook:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaBook:OnAwake()
    LWnd.OnAwake(self)
    self._viewAniKey = "viewAniKey"
    self._isPlayEffect = false

end

function UISagaBook:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitEmptyList()
    self._fanshuSp = self:CreateWndSpine(self.mChangePageEffRoot, "Tujian", "Tujian", false)
    self:InitText()
    self:InitData()
    self:InitEvent()
    self:InitBtnList()
    self:InitMsg()
    self:InitHeroRaceTypeList()
    self:RefreshListView()
    self:InitCommonBarrageWnd()
end

function UISagaBook:CreateRelationAttrList(trans, attrList, actStatus)
    local list = {}
    for i, v in ipairs(attrList) do
        local data = table.clone(v)
        data.actStatus = actStatus
        table.insert(list, data)
    end
    local key = trans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(trans, list, function(...)
            self:OnDrawAttrStrCell(...)
        end)
    end
end

function UISagaBook:RefreshJBJCView(network)
    local jbTabBtnInfoList = self._jbTabBtnInfoList
    local itemdata = jbTabBtnInfoList and jbTabBtnInfoList[self._jbPage]
    if not itemdata then
        return
    end
    self:ShowJSTransView(itemdata.root, itemdata.otherRootList)
    local selRelationRefId = self._selRelationRefId
    if selRelationRefId == 0 then
        return
    end
    local cardData = gModelHeroBook:GetHeroRelationRefByRefId(selRelationRefId)
    if not cardData then
        return
    end
    local refId = cardData.refId
    local attrType = cardData.attrType
    self:CreateHeroRelationAttrList(refId, attrType, network)
end

function UISagaBook:ClickRelationCard(key, init)
    LxResUtil.DestroyChildImmediate(self.mHeroRelationImg)
    self:CreateHeroPrefab(key)
    CS.ShowObject(self.mRelationListBg,false)
    local serverData = gModelHeroBook:GetRelationInfoByRefId(key)
    if serverData then
        local status = gModelHeroBook:CheckHeroRelationInfoStatusByRefId(key)
        local haveRed = status and 1 or 0
        local actNum = #serverData.heroes
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-2-1",key,actNum,haveRed)
    end
    self:RefreshRelationView(key, init)
    CS.ShowObject(self.mHeroRelationView,true)
    self:ChangeSubPageViewStatus(self.mHeroRelationView, true, true, function()
    end,"idle1")
end

function UISagaBook:OnHeroBookAddCloseResp(pb)
    if self._curHeroBookRefId ~= pb.heroRefId then return end
    if self._page ~= ModelHeroBook.HEROTJ_IDX then return end
    if self._heroBookState ~= 1 then return end
    local canUp = gModelHeroBook:CheckBookInfoStatusByRefId(self._curHeroBookRefId)
    if canUp then
        FireEvent(EventNames.ON_HERO_CHAIN_CAN_UP)
    end
end

function UISagaBook:InitEmptyList()
    local data = {
        refId = 10005,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UISagaBook:CreateRelationItem(trans, key, itemdata)
    local relationHeroKeyList = itemdata.relationHeroKeyList
    local heroesKey = itemdata.heroesKey
    for k, v in pairs(relationHeroKeyList) do
        local heroTrans = self:FindWndTrans(trans, v)
        local isGray = not heroesKey[v]
        self:SetWndImageGray(heroTrans, isGray)
    end
    local redPoint = self:FindWndTrans(trans,"redPoint")
    if redPoint then
        local status = gModelHeroBook:CheckHeroRelationInfoStatusByRefId(key)
        CS.ShowObject(redPoint,status)
    end
    local HeroBookName2Trans = self:FindWndTrans(trans,"HeroBookName2")
    if HeroBookName2Trans then
        local NameTxt = self:FindWndTrans(HeroBookName2Trans,"NameTxt")
        local NumTxt = self:FindWndTrans(HeroBookName2Trans,"NumTxt")
        self:SetHeroRelationNameAndNum(NameTxt,ccLngText(itemdata.name),NumTxt,itemdata.heroes,itemdata.relationHeroNum)
    end
    self:SetWndClick(trans, function()
        self:ClickRelationCard(key, true)
    end)
end

function UISagaBook:SetHeroRelationNameAndNum(nameTrans,relationName,numTxtTrans,heroes,relationHeroList)
    self:SetWndText(nameTrans,relationName)
    heroes = heroes or {}
    local curHeroNum = #heroes
    relationHeroList = relationHeroList or {}
    local allHeroNum = relationHeroList
    local str = string.format("(%s/%s)",curHeroNum,allHeroNum)
    self:SetWndText(numTxtTrans,str)
end
------------------------------ HeroRelationView ------------------------------

------------------------------ BookListView ------------------------------
function UISagaBook:RefreshHeroBookListView(isTop)
    self:InitHeroBookList(isTop)
end

function UISagaBook:InitRelationBtnList(init)
    local list = {}
    for k, v in pairs(self._jbTabBtnInfoList) do
        local data = table.clone(v)
        table.insert(list, data)
    end
    table.sort(list, function(a, b)
        return a.index < b.index
    end)
    local uiRelationBtnList = self._uiRelationBtnList
    if uiRelationBtnList then
        uiRelationBtnList:RefreshList(list)
    else
        uiRelationBtnList = self:GetUIScroll("uiRelationBtnList")
        self._uiRelationBtnList = uiRelationBtnList
        uiRelationBtnList:Create(self.mHeroRelationTabList, list, function(...)
            self:OnDrawRelationBtnCell(...)
        end)

        self:DelaySendFinish(0.2)
    end
    if init then
        local jbTabBtnInfoList = self._jbTabBtnInfoList
        local refreshFunc = jbTabBtnInfoList and jbTabBtnInfoList[self._jbPage].refreshFunc
        if refreshFunc then
            refreshFunc()
        end
    end
end

function UISagaBook:OnDrawHeroRelationAddAttrCell(list, item, itemdata, itempos)
    local status = itemdata.status
    local need = itemdata.need
    local refId = itemdata.refId
    local groupRefId = itemdata.groupRefId
    local attrList = itemdata.attrList or {}
    local showAct = status == UISagaBook.JB_STATUS_RECEIVE
    local ImgDiv = self:FindWndTrans(item, "ImgDiv")
    if ImgDiv then
        local NoActImg = self:FindWndTrans(ImgDiv, "NoActImg")
        local ActImg = self:FindWndTrans(ImgDiv, "ActImg")
        CS.ShowObject(NoActImg, not showAct)
        CS.ShowObject(ActImg, showAct)
    end
    local AddDiv = self:FindWndTrans(item, "AddDiv")
    if AddDiv then
        local DescDiv = self:FindWndTrans(AddDiv, "DescDiv")
        if DescDiv then
            local ActDesc = self:FindWndTrans(DescDiv, "ActDesc")
            if ActDesc then
                local str = string.replace(ccClientText(19738), need)
                self:SetWndText(ActDesc, str)
            end
        end
        local AttrDiv = self:FindWndTrans(AddDiv, "AttrDiv")
        if AttrDiv then
            local AttrList = self:FindWndTrans(AttrDiv, "AttrList")
            if AttrList then
                self:CreateRelationAttrList(AttrList, attrList, showAct)
            end
        end
    end
    local BtnDiv = self:FindWndTrans(item, "BtnDiv")
    if BtnDiv then
        local ActivityImg = self:FindWndTrans(BtnDiv, "ActivityImg")
        local GetBtn = self:FindWndTrans(BtnDiv, "GetBtn")
        local redPoint = self:FindWndTrans(BtnDiv,"redPoint")
        CS.ShowObject(ActivityImg, showAct)
        CS.ShowObject(GetBtn, not showAct)
        if not showAct then
            local showRedPoint = false
            local gray = false
            local textId
            if status == UISagaBook.JB_STATUS_NOACT then
                gray = true
                textId = 19742
            elseif status == UISagaBook.JB_STATUS_CANRECEIVE then
                textId = 19741
                showRedPoint = true
            elseif status == UISagaBook.JB_STATUS_RECEIVE then
                textId = 19742
            end
            CS.ShowObject(redPoint,showRedPoint and not showAct)
            self:SetWndButtonText(GetBtn, ccClientText(textId))
            self:SetWndButtonGray(GetBtn, gray)
            self:SetWndClick(GetBtn, function()
                gModelHeroBook:OnHeroRelationActiveReq(groupRefId, refId)
            end)
        else
            CS.ShowObject(redPoint,false)
        end
    end

    local attrNum = math.ceil(#attrList / 2)
    local height = 35 + attrNum * 25 + 6
    if height < 80 then
        height = 80
    end
    LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
end

function UISagaBook:RefreshHeroRaceTypeList()
    --local FindUIHeroRaceList
    local uiHeroRaceList = self._uiHeroRcaeList
    if not uiHeroRaceList then return end
    uiHeroRaceList:RefreshHeroRaceList()
end

function UISagaBook:CreateHeroCardList(trans, list)
    for i = 1, UISagaBook.CARD_MAX_NUM do
        local heroTransName = "HeroCard" .. i
        local heroCardTrans = self:FindWndTrans(trans, heroTransName)
        if heroCardTrans then
            local data = list[i]
            local showCard = data ~= nil
            if showCard then
                self:CreateCard(heroCardTrans, data)
            end
            CS.ShowObject(heroCardTrans, showCard)
        end
    end
end

function UISagaBook:CheckQMJDCanUp(refId)
    local isUp = gModelHeroBook:ShowHeroCloseWnd(refId)
    if isUp ~= nil then
        self:PlayEffShow(isUp)
    end
end

function UISagaBook:OpenBarrageShow()
    if self._showRelationViewBarrage then
        FireEvent(EventNames.CHANGE_COMMON_BARRAGE_INFO, {
            heroRefId = self._selRelationRefId,
            barrageType = ModelHeroBook.BARRAGE_TYPE_HERORELATION
        })
    else
        FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS, false)
    end
    CS.ShowObject(self.mRelationBarrageMask, not self._showRelationViewBarrage)
end

function UISagaBook:CloseSend()
    local page = self._page
    local str
    local refId
    if page == ModelHeroBook.HEROTJ_IDX then
        local isShow = self.mHeroBookView.gameObject.activeSelf
        str = isShow and "2-1-1" or "2-1"
        if isShow then
            refId = self._curHeroBookRefId
        end
    elseif page == ModelHeroBook.HEROJB_IDX then
        local isShow = self.mHeroRelationView.gameObject.activeSelf
        str = isShow and "2-2-1" or "2-2"
        if isShow then
            refId = self._selRelationRefId
        end
    end
    gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"图鉴功能close",str,refId)
end

function UISagaBook:OnDrawAttrStrCell(list, item, itemdata, itempos)
    local UIText = self:FindWndTrans(item, "UIText")
    if UIText then
        local actStatus = itemdata.actStatus
        local refId, numType, value = itemdata.refId, itemdata.numType, itemdata.value
        local name = gModelHero:GetAttributeNameById(refId)
        local val = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, numType, value)
        local str = string.replace(ccClientText(19739), name, val)
        self:SetWndText(UIText, str)
        local color = actStatus and UISagaBook.ACT_TEXT_COLOR or UISagaBook.NOACT_TEXT_COLOR
        self:SetXUITextTransColor(UIText, color)
    end
end

function UISagaBook:CreateQMDJList(dj,heroRefId)
    local list = {}
    local closeLv = gModelHeroBook:GetHeroCloseLv(heroRefId)
    for i = 1,closeLv do
        local actStar = dj >= i
        table.insert(list, { actStar = actStar })
    end
    local uiQMDJList = self._uiQMDJList
    if uiQMDJList then
        uiQMDJList:RefreshList(list)
    else
        uiQMDJList = self:GetUIScroll("uiQMDJList")
        self._uiQMDJList = uiQMDJList
        uiQMDJList:Create(self.mQmDJList, list, function(...)
            self:OnDrawStarCell(...)
        end)
    end
end

function UISagaBook:SaveWndArg()
	if self._page or self._subPage or self._curHeroBookRefId then
		local argList = self:GetWndArgList() or {}
		argList["page"] = self._page
		argList["subPage"] = self._subPage
		argList["refId"] = self._curHeroBookRefId
		self:SetWndArg(argList)
	end
end

function UISagaBook:OnDrawAttrCell(list, item, itemdata, itempos)
    local AttrIcon = self:FindWndTrans(item, "AttrIcon")
    local AttrName = self:FindWndTrans(item, "AttrName")
    local AttrValue = self:FindWndTrans(item, "AttrValue")
    local numType, refId, value = itemdata.numType, itemdata.refId, itemdata.value
    if AttrIcon then
        local icon = gModelHero:GetAttributeIconById(refId)
        self:SetWndEasyImage(AttrIcon, icon, function()
            CS.ShowObject(AttrIcon, true)
        end)
    end
    if AttrName then
        local name = gModelHero:GetAttributeNameById(refId)
        name = name .. "："
        self:SetWndText(AttrName, name)
    end
    if AttrValue then
        local attrValue = gModelHero:GetAttributeValueNoNameByIdAndVal(refId, numType, value)
        self:SetWndText(AttrValue, attrValue)
    end
end

function UISagaBook:CheckShowHeroInfo(openHeroBookRefId)
	if openHeroBookRefId then
		self:ClickHeroCard({refId = openHeroBookRefId},true)
	end
    return openHeroBookRefId ~= nil
end

function UISagaBook:InitRelationList()
    local list = self:GetRelationList()
    local uiRelationList = self._uiRelationList
    if uiRelationList then
        uiRelationList:RefreshData(list)
    else
        uiRelationList = self:GetUIScroll("uiRelationList")
        self._uiRelationList = uiRelationList
        uiRelationList:Create(self.mRelationList, list, function(...)
            self:OnDrawRelationCell(...)
        end, UIItemList.SUPER)
    end
    local index = 0
    for i,v in ipairs(list) do
        local status = gModelHeroBook:CheckHeroRelationInfoStatusByRefId(v.refId)
        if status then
            index = i
            break
        end
    end
    if index ~= 0 then
        uiRelationList:MoveToPos(index - 1)
    end
end

function UISagaBook:OnDrawRelationBtnCell(list, item, itemdata, itempos)
    local index = itemdata.index
    local BtnTab2 = self:FindWndTrans(item, "BtnTab2")
    if BtnTab2 then
        local refreshFunc = itemdata.refreshFunc

        local addSize = -2
        local addLine = -30
        if gLGameLanguage:IsThaiVersion() then
            addSize = -4
            addLine = -50
        end
        self:SetWndTabText(BtnTab2, itemdata.btnTxt, addSize, addLine)
        local status = itemdata.index == self._jbPage and 0 or 1
        self:SetWndTabStatus(BtnTab2, status)
        self:SetWndClick(BtnTab2, function()
            self:ChangeRelationBtn(index, refreshFunc)
        end)
    end
    local redPoint = self:FindWndTrans(item,"redPoint")
    if redPoint then
        local status = false
        if index == ModelHeroBook.HEROJB_SHOUJI_IDX then
            status = gModelHeroBook:CheckJBSJStatusByRefId(self._selRelationRefId)
        elseif index == ModelHeroBook.HEROJB_JIACHENG_IDX then
            status = gModelHeroBook:CheckJBJCStatusByRefId(self._selRelationRefId)
        end
        CS.ShowObject(redPoint,status)
    end
end

function UISagaBook:InitEvent()
    self:SetWndClick(self.mHeroBookTip,function()
        GF.OpenWndUp("UIBzTips",{refId = 71})
    end)
    self:SetWndClick(self.mRelationTip,function()
        GF.OpenWndUp("UIBzTips",{refId = 82})
    end)
    self:SetWndClick(self.mCloseBtn, function()
        if self._isPlayEffect then
            return
        end
        self:CloseSend()
        self:WndCloseAndBack()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mMask, function()
        if self._isPlayEffect then
            return
        end
        self:CloseSend()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mHeroBookReturnBtn, function()
        FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS, false)
        CS.ShowObject(self.mHeroBookView,false)
        self:InitHeroBookList()
        self:ChangeSubPageViewStatus(self.mHeroBookView, false, true,function()
            CS.ShowObject(self.mBookListBg,true)
            self._heroBookState = 0
        end,"idle2")
    end)
    self:SetWndClick(self.mHeroRelationReturnBtn, function()
        FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS, false)
        local uiHeroRelationAttrList = self._uiHeroRelationAttrList
        if uiHeroRelationAttrList then
            local uiList = uiHeroRelationAttrList:GetList()
            uiList:RemoveAll()
            uiList:RefreshList()
        end
        --if self.mHeroRelationView.gameObject.activeSelf then
        --    CS.ShowObject(self.mHeroRelationView,false)
        --end
        self:InitRelationList()
        self:ChangeSubPageViewStatus(self.mHeroRelationView, false, true,function()
            CS.ShowObject(self.mRelationListBg,true)
        end,"idle2")
    end)
    self:SetWndClick(self.mRelationAddShowBtn, function()
        gModelHeroBook:OpenRelationHeroAddAttrWnd()
    end)
    self:SetWndClick(self.mRelationBarrageBtn, function()
        self._showRelationViewBarrage = not self._showRelationViewBarrage
        gModelHeroBook:SetRelationBarrageStatus(self._showRelationViewBarrage)
        self:OpenBarrageShow()
    end)
    self:SetWndClick(self.mCurLeftBtn,function()
        self:CutHero(1)
    end)
    self:SetWndClick(self.mCurRightBtn,function()
        self:CutHero(-1)
    end)
    self:SetWndClick(self.mHeroBookViewAttrBtn, function()
        GF.OpenWnd("UIBzTips",{refId = 71})
    end)
end

function UISagaBook:OnDrawRelationItemCell(list, item, itemdata, itempos)
    local InstanceID = item:GetInstanceID()
    local itemType, itemRefId, itemNum = itemdata.itemType, itemdata.itemRefId, itemdata.itemNum
    local CommonUI = self:FindWndTrans(item, "CommonUI")
    if CommonUI then
        local Icon = CS.FindTrans(CommonUI, "Icon")
        local uiCommonList = self._uiCommonList
        if not uiCommonList then
            uiCommonList = {}
            self._uiCommonList = uiCommonList
        end
        local baseClass = uiCommonList[InstanceID]
        if not baseClass then
            baseClass = CommonIcon:New()
            uiCommonList[InstanceID] = baseClass
            baseClass:Create(Icon)
        end
        baseClass:SetCommonReward(itemType, itemRefId, itemNum)
        baseClass:EnableShowNum(itemNum > 0)
        baseClass:SetNoShowLv(true)
        baseClass:DoApply()
        self:SetWndClick(Icon, function()
            gModelGeneral:OpenItemInfoTipTop(itemRefId, itemNum)
        end)
    end
end
------------------------------ RelationListView ------------------------------
function UISagaBook:RefreshRelationListView()
    if not self._selRelationRefId then
        self._selRelationRefId = 0
    end
    self:InitRelationList()
    if self._page == ModelHeroBook.HEROJB_IDX then
        FireEvent(EventNames.ON_ENTER_HERO_CHAIN) --进入羁绊，触发指引
    end
end

function UISagaBook:InitCommonBarrageWnd()
    local cd = gModelChat:GetChatConfigRefByKey("textShowSpeed")
    local colorList = gModelHero:GetBarrageColorList()
    gModelHeroBook:OpenCommonBarrage({
        cd = cd,
        colorList = colorList,
        barrageType = ModelHeroBook.BARRAGE_TYPE_HEROCOMMENT,
        heroRefId = self._refId,
        autoRun = false,
    })
end

function UISagaBook:InitHeroRaceTypeList()
    local data = {
        wndClass = self,
        listTrans = self.mHeroRaceList,
        showType = UIHeroRaceList.TYPE_NORMAL,
        callbackFunc = function(raceType)
            if not self:IsWndValid() then return end
            if raceType == self._raceType then return end
            self._raceType = raceType
            self:RefreshHeroBookListView(true)
        end,
        checkSelFunc = function(raceType)
            if not self:IsWndValid() then return end
            return self._raceType == raceType
        end,
        checkRedPointFunc = function(raceType)
            if not self:IsWndValid() then return end
            return self:CheckRaceTypeRedPointStatus(raceType)
        end,
    }
    self._uiHeroRcaeList = self:GetUIHeroRaceList(data)
end

function UISagaBook:CreateCard(trans, itemdata)
    local refId = itemdata.refId
    local quality = itemdata.quality
    local heroBookListForward
    local qualityRef = gModelItem:GetQualityRef(quality)
    if qualityRef then
        heroBookListForward = qualityRef.heroBookListForward
    end

    local effTrans = self:FindWndTrans(trans,"Eff")
    if effTrans then
        LxResUtil.DestroyChildImmediate(effTrans)
        self:DestroyWndEffectByKey(refId)
        local status = gModelHeroBook:FindIsNewActHeroInfoByRefId(refId)
        if status then
--[[            local quality = gModelHero:GetHeroQualityByRefId(refId)
            if quality then
                local quaRef = gModelItem:GetQualityRef(quality)
                if quaRef then
                    local effName = quaRef.heroBookListLock
                    self:CreateWndEffect(effTrans,effName,refId,100,nil,nil,10)
                end
            end]]

            if qualityRef then
                local effName = qualityRef.heroBookListLock
                self:CreateWndEffect(effTrans,effName,refId,100,nil,nil,10)
            end
        end
        CS.ShowObject(effTrans,status)
    end

    local effRef = gModelHero:GetHeroShowRefByRefId(refId)
    local Bg = self:FindWndTrans(trans, "Bg")
    if Bg then
    end
    local HeroIcon = self:FindWndTrans(trans, "HeroIcon")
    if HeroIcon then
        local heroBookIcon = effRef and effRef.iconBig
        if heroBookIcon then
            self:SetWndEasyImage(HeroIcon, heroBookIcon, function()
                CS.ShowObject(HeroIcon, true)
            end, true)
        end
    end
    local RaceType = self:FindWndTrans(trans, "RaceType")
    if RaceType then
        local img = gModelHero:GetRaceImgByRefId(itemdata.raceType)
        if img then
            self:SetWndEasyImage(RaceType, img, function()
                CS.ShowObject(RaceType, true)
            end)
        end
    end
    local NameBg = self:FindWndTrans(trans, "NameBg")
    if NameBg then
        local HeroName = self:FindWndTrans(NameBg, "HeroName")
        if HeroName then
            local name = gModelHero:GetHeroNameByRefId(refId)
            if name then
                self:SetWndText(HeroName, name)
            end
        end

        self:InitTextLineWithLanguage(HeroName,-40)
        self:InitTextSizeWithLanguage(HeroName,-2)
    end
    local LoveList = self:FindWndTrans(trans, "LoveList")
    if LoveList then
        local ItemRoot = self:FindWndTrans(LoveList, "ItemRoot")
        if ItemRoot then
            local star = 0
            local serverData = gModelHeroBook:GetHeroInfoByHeroRefId(refId)
            if serverData then
                local isActive = serverData.isActive
                star = isActive and serverData.heroMaxStar or 0
            end
            --local showCloseLvNum = gModelHeroBook:GetOnlyShowCloseLvNum()
            --local closeLv = gModelHeroBook:GetHeroCloseLv(refId)
            --for i = 1,showCloseLvNum do
            --    local starTrans = self:FindWndTrans(ItemRoot, "Star" .. i)
            --    if starTrans then
            --        local isGray = star < i
            --        self:SetWndImageGray(starTrans, isGray)
            --
            --        local show = i <= closeLv
            --        CS.ShowObject(starTrans,show)
            --    end
            --end
        end
    end
    local redPoint = self:FindWndTrans(trans,"redPoint")
    if redPoint then
        local rstatus = gModelHeroBook:CheckHeroBookInfoStatusByRefId(refId)
        CS.ShowObject(redPoint,rstatus)
    end
    local Mask = self:FindWndTrans(trans, "Mask")
    if Mask then
        local isActive = gModelHeroBook:FindHeroInfoStatusByHeroRefId(refId)
        CS.ShowObject(Mask, not isActive)
    end

    if self._isForeign then
        local coverImg = self:FindWndTrans(trans, "CoverImg")
        local isShowCoverBg =  LxUiHelper.IsImgPathValid(heroBookListForward)
        if isShowCoverBg then
            self:SetWndEasyImage(coverImg, heroBookListForward, nil, true)
        end
        CS.ShowObject(coverImg, isShowCoverBg)
    end

    self:SetWndClick(trans, function()
        self:ClickHeroCard(itemdata)
    end)
end

function UISagaBook:CreateAttrList(key, list, listTrans)
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

function UISagaBook:PlayEffShow(upNum)
    local seqTween
    self:TweenSeqKill(self._effectKey)
    local pos = self.mShowUpTxt.localPosition
    if not seqTween then
        seqTween = self:TweenSeqCreate(self._effectKey,function(seq)
            local effKey = "fx_qinmijindu"
            self:CreateWndEffect(self.mBarEff,"fx_qinmijindu",effKey,100)
            seq:AppendInterval(1.1)

            seq:AppendCallback(function()
                CS.ShowObject(self.mShowUpTxt,true)
            end)

            local alphaTime = 0.5
            local Ease = DG.Tweening.Ease.OutCubic

            local str = string.format("+%s",upNum)
            self:SetWndText(self.mShowUpTxt,str)

            local newCanvasGroup = self.mShowUpTxt:GetComponent(typeofCanvasGroup)
            if newCanvasGroup then
                local _temp = YXTween.TweenFloat(0, 1, alphaTime, function(ival)
                    newCanvasGroup.alpha = ival
                end):SetEase(Ease)
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
        CS.ShowObject(self.mShowUpTxt,false)
    end)
end

function UISagaBook:OnDrawRelationHeroCell(list, item, itemdata, itempos)
    local InstanceID = item:GetInstanceID()
    local mask = itemdata.mask
    local itemType, itemRefId, itemNum = itemdata.itemType, itemdata.itemRefId, itemdata.itemNum
    local CommonUI = self:FindWndTrans(item, "CommonUI")
    if CommonUI then
        local Icon = CS.FindTrans(CommonUI, "Icon")
        local uiCommonList = self._uiCommonList
        if not uiCommonList then
            uiCommonList = {}
            self._uiCommonList = uiCommonList
        end
        local baseClass = uiCommonList[InstanceID]
        if not baseClass then
            baseClass = CommonIcon:New()
            uiCommonList[InstanceID] = baseClass
            baseClass:Create(Icon)
        end
        if itemRefId then
            baseClass:SetCommonReward(itemType, itemRefId, itemNum)
            baseClass:SetShowMaskOnly(mask)
        else
            baseClass:SetHeroOnlyShow()
            baseClass:SetShowMaskOnly(false)
        end
        baseClass:EnableShowNum(false)
        baseClass:SetNoShowLv(true)
        baseClass:DoApply()
        self:SetWndClick(Icon, function()
            if itemRefId then
                gModelGeneral:OpenHeroStarPre({ refId = itemRefId })
            else
                GF.ShowMessage(ccClientText(19748))
            end
        end)
    end
    local HeroName = self:FindWndTrans(item, "HeroName")
    if HeroName then
        local name
        if itemRefId then
            name = gModelHero:GetHeroNameByRefId(itemRefId)
        else
            name = ccClientText(19748)
        end
        self:SetWndText(HeroName, name)

        self:InitTextShowWithLanguage(HeroName)
    end
end

function UISagaBook:CreateHeroRelationAttrList(refId, attrType, network)
    local list = self:GetHeroRelationAttrList(refId, attrType)
    local uiHeroRelationAttrList = self._uiHeroRelationAttrList
    if uiHeroRelationAttrList then
        if not network then
            local uiList = uiHeroRelationAttrList:GetList()
            uiList:MoveToPos(1)
        end
        uiHeroRelationAttrList:RefreshList(list)
        local uiList = uiHeroRelationAttrList:GetList()
        uiList:DrawAllItems()
    else
        uiHeroRelationAttrList = self:GetUIScroll("uiHeroRelationAttrList")
        self._uiHeroRelationAttrList = uiHeroRelationAttrList
        uiHeroRelationAttrList:Create(self.mJBJCAddList, list, function(...)
            self:OnDrawHeroRelationAddAttrCell(...)
        end, UIItemList.SUPER)
    end
    self:DelaySendFinish(0.2)
end

function UISagaBook:RefreshJBSJView()
    local jbTabBtnInfoList = self._jbTabBtnInfoList
    local itemdata = jbTabBtnInfoList and jbTabBtnInfoList[self._jbPage]
    if not itemdata then
        return
    end
    self:ShowJSTransView(itemdata.root, itemdata.otherRootList)
    local selRelationRefId = self._selRelationRefId
    if selRelationRefId == 0 then
        return
    end
    local cardData = gModelHeroBook:GetHeroRelationRefByRefId(selRelationRefId)
    if not cardData then
        return
    end
    local serverData = gModelHeroBook:GetRelationInfoByRefId(selRelationRefId)
    if not serverData then
        return
    end
    local relationHeroList = cardData.relationHeroList or {}
    local relationHeroNum = cardData.relationHeroNum
    self:CreateRelationHeroList(relationHeroNum, relationHeroList,selRelationRefId)
    local rewardList = cardData.rewardList or {}
    local heroes = serverData.heroes or {}
    self:CreateRelationItemList(rewardList)
    local isRec = serverData.isRec or false
    local btnTxtId = isRec and 19762 or 19744
    local cardHeroLen = #relationHeroList
    local serverHeroesLen = #heroes
    if not isRec then
        isRec = cardHeroLen ~= serverHeroesLen
    end
    if not isRec then
        isRec = relationHeroNum ~= serverHeroesLen and relationHeroNum ~= cardHeroLen
    end
    local status = gModelHeroBook:CheckJBSJStatusByRefId(selRelationRefId)
    CS.ShowObject(self.mJBSJViewGetBtnRedPoint,status)
    self:SetWndButtonText(self.mJBSJViewGetBtn, ccClientText(btnTxtId))
    self:SetWndButtonGray(self.mJBSJViewGetBtn, isRec)
    self:SetWndClick(self.mJBSJViewGetBtn, function()
        gModelHeroBook:OnHeroRelationReceiveRewardReq(cardData.refId)
    end)
end

function UISagaBook:OnDrawStarCell(list, item, itemdata, itempos)
    local Star = self:FindWndTrans(item, "Star")
    if Star then
        local actStar = not itemdata.actStar
        self:SetWndImageGray(Star, actStar)
    end
end

function UISagaBook:InitData()
    local page = self:GetWndArg("page")
    self._page = page and page or ModelHeroBook.HEROTJ_IDX            -- 打开的时候确定是哪个tab

    local subPage = self:GetWndArg("subPage")
    self._subPage = subPage and subPage or ModelHeroBook.HEROJB_SHOUJI_IDX

    self._func = self:GetWndArg("func")

	self._openHeroBookRefId = self:GetWndArg("refId")

    self._changePageSpineList = {
        [UISagaBook.CHANGEPAGE_FORWARD] = "",
        [UISagaBook.CHANGEPAGE_BACKWARDS] = "",
    }
    self._pageAniSpineName = "TuJian"
    self._isChangePage = false

    self._raceType = 0

    -- 主界面的tab
    self._tabBtnInfoList = {
        [ModelHeroBook.HEROTJ_IDX] = {
            title = ccClientText(19700),
            btnTxt = ccClientText(19702),
            index = ModelHeroBook.HEROTJ_IDX,
            root = self.mBookListView,
            infoRoot = self.mBookListBg,
            examineIdx = ModelHeroBook.HEROJB_IDX,
            otherRootList = { self.mHeroRelationView },
            disposeFunc = function()
                self:RefreshHeroBookListView()
            end,
        },
        [ModelHeroBook.HEROJB_IDX] = {
            title = ccClientText(19708),
            btnTxt = ccClientText(19703),
            index = ModelHeroBook.HEROJB_IDX,
            root = self.mRelationListView,
            infoRoot = self.mRelationListBg,
            examineIdx = ModelHeroBook.HEROTJ_IDX,
            otherRootList = { self.mHeroBookView },
            disposeFunc = function()
                self:RefreshRelationListView()
            end,
        },
    }

    --屏蔽羁绊
    --if not gModelFunctionOpen:CheckIsShow(10303003) then
    --    self._tabBtnInfoList[ModelHeroBook.HEROJB_IDX] = nil
    --end
    self._tabBtnInfoList[ModelHeroBook.HEROJB_IDX] = nil

    self._viewActStatusList = {
        [ModelHeroBook.HEROTJ_IDX] = false,
        [ModelHeroBook.HEROJB_IDX] = false,
    }
    -- 羁绊界面的tab
    self._jbTabBtnInfoList = {
        [ModelHeroBook.HEROJB_SHOUJI_IDX] = {
            index = ModelHeroBook.HEROJB_SHOUJI_IDX,
            btnTxt = ccClientText(19710),
            root = self.mJBSJView,
            otherRootList = { self.mJBJCView },
            refreshFunc = function()
                self:RefreshJBSJView()
            end,
        },
        [ModelHeroBook.HEROJB_JIACHENG_IDX] = {
            index = ModelHeroBook.HEROJB_JIACHENG_IDX,
            btnTxt = ccClientText(19711),
            root = self.mJBJCView,
            otherRootList = { self.mJBSJView },
            refreshFunc = function()
                self:RefreshJBJCView()
            end,
        },
    }
    self._jbPage = ModelHeroBook.HEROJB_SHOUJI_IDX
    self._selRelationRefId = 0

    self._showRelationViewBarrage = gModelHeroBook:GetRelationBarrageStatus()
    self._isForeign = gLGameLanguage:IsForeignRegion()
end

function UISagaBook:PlayEffect(showStatus, func, trans,idleName)
    local openHeroBookRefId = self._openHeroBookRefId
    self._openHeroBookRefId = nil
    if self:CheckShowHeroInfo(openHeroBookRefId) then
        return
    end
    if self._isPlayEffect then
        return
    end
    self._isPlayEffect = true
    CS.ShowObject(self.mCloseBtn, false)
    local seqTween
    self:TweenSeqKill(self._viewAniKey)
    if not seqTween then
        seqTween = self:TweenSeqCreate(self._viewAniKey, function(seq)
            seq:AppendCallback(function()
                CS.ShowObject(self.mChangePageEffRoot,true)
                -- 创建翻页特效
                if self._fanshuSp then
                    if idleName == nil then
                        if showStatus then
                            idleName = "idle1"
                        else
                            idleName = "idle2"
                        end
                    end
                    printInfoNR("=== idleName = "..idleName)
                    self._fanshuSp:PlayAnimationSolid(idleName,false)
                end
            end)
            if idleName == "idle1" then
                seq:AppendInterval(0.6)
            else
                seq:AppendInterval(0.7)
            end
            seq:AppendCallback(function()
                CS.ShowObject(self.mChangePageEffRoot,false)
            end)

--[[            local effTime = 0.5
            local tempX = 5
            local fRotationX = showStatus and tempX or 0
            local tRotationX = showStatus and 0     or tempX

            local tempY = 90
            local fRotationY = showStatus and tempY or 0
            local tRotationY = showStatus and 0     or tempY

            local tempZ = -2
            local fRotationZ = showStatus and -tempZ or 0
            local tRotationZ = showStatus and 0      or -tempZ
            trans.transform.localRotation = Quaternion.Euler(fRotationX,fRotationY,fRotationZ)
            CS.ShowObject(trans,true)

            local rotateTween = trans.transform:DORotate(Vector3.New(tRotationX,tRotationY,tRotationZ),effTime)
            seq:Append(rotateTween)]]

            return seq
        end)
    end
    seqTween:PlayForward()
    seqTween:OnComplete(function()
        if func then
            func()
        end
        self._isPlayEffect = false
        CS.ShowObject(self.mChangePageEffRoot,false)
        CS.ShowObject(self.mCloseBtn, true)
        self:TweenSeqKill(self._viewAniKey)
    end)
end

function UISagaBook:OnDrawHeroSpCell(list, item, itemdata, itempos)
    local showQuaDiv = itemdata.showQuaDiv or false
    local QualityDiv = self:FindWndTrans(item, "QualityDiv")
    if QualityDiv then
        if showQuaDiv then
            local QualityImg = self:FindWndTrans(QualityDiv, "QualityImg")
            if QualityImg then
                local quaName = ""
                local quality = itemdata.quality
                if quality then
                    local qualityRef = gModelItem:GetQualityRef(quality)
                    quaName = qualityRef and ccLngText(qualityRef.heroQualityName) or ""
                end
                local color = gModelItem:GetColorByQualityId(quality)
                local str = string.replace(ccClientText(19701), quaName)

                local isForeign = self._isForeign
                local QualityTxt = self:FindWndTrans(QualityImg, "QualityTxt")
                local QualityTxtEn = self:FindWndTrans(QualityImg, "QualityTxtEn")
                local isShow = not isForeign
                if QualityTxt then
                    CS.ShowObject(QualityTxt, isShow)
                    if isShow then
                        self:SetWndText(QualityTxt, str)
                        if color then
                            self:SetXUITextTransColor(QualityTxt, color)
                        end
                    end
                end

                isShow = isForeign
                if QualityTxtEn then
                    CS.ShowObject(QualityTxtEn,  isShow)
                    if isShow then
                        self:SetWndText(QualityTxtEn, str)
                        local heroBookTagColorList = gModelItem:GetHeroBookTagColorListByQuality(quality)
                        local colorGradientDefault = self._colorGradientDefault
                        if not table.isempty(heroBookTagColorList) then
                            self:SetXUITextTransColor(QualityTxtEn, colorGradientDefault)
                            self:SetTextTransColorGradient(QualityTxtEn,heroBookTagColorList[1],heroBookTagColorList[2])
                        elseif color then
                            self:SetXUITextTransColor(QualityTxtEn, color)
                            self:SetTextTransColorGradient(QualityTxtEn,colorGradientDefault,colorGradientDefault)
                        end
                    end
                end
            end
        end
        CS.ShowObject(QualityDiv, showQuaDiv)
        LxUiHelper.SetSizeWithCurAnchor(item, 1, 48)
    end
    local HeroMapList = self:FindWndTrans(item, "HeroMapList")
    if HeroMapList then
        CS.ShowObject(HeroMapList, not showQuaDiv)
        if not showQuaDiv then
            self:CreateHeroCardList(HeroMapList, itemdata.heroList)
            LxUiHelper.SetSizeWithCurAnchor(item, 1, 280)
        end
    end
end

function UISagaBook:RefreshJBJCViewBtnList()
    local uiRelationBtnList = self._uiRelationBtnList
    if uiRelationBtnList then
        local uiList = uiRelationBtnList:GetList()
        uiList:RefreshList()
    end
end

function UISagaBook:InitMsg()
    self:WndNetMsgRecv(LProtoIds.HeroRelationReceiveRewardResp, function(pb)
        local refId = pb.refId
        local isRefresh = self._page == ModelHeroBook.HEROJB_IDX and self._jbPage == ModelHeroBook.HEROJB_SHOUJI_IDX
        if isRefresh and refId == self._selRelationRefId then
            self:RefreshJBSJView()
        end
        self:RefreshJBJCViewBtnList()
        self:RefreshBotBtnList()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroRelationActiveResp, function(pb)
        local refId = pb.refId
        local isRefresh = self._page == ModelHeroBook.HEROJB_IDX and self._jbPage == ModelHeroBook.HEROJB_JIACHENG_IDX
        if isRefresh and refId == self._selRelationRefId then
            self:RefreshJBJCView(true)
        end
        self:RefreshJBJCViewBtnList()
        self:RefreshBotBtnList()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroBookUpCloseGradeResp, function(pb)
        self:InitHeroBookList()
        self:RefreshHeroBookView(pb.newBook.heroRefId,true)
        self:RefreshBotBtnList()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroBookRewardResp, function(pb)
        self:InitHeroBookList()
        local heroRefId = pb.heroRefId
        self:RefreshHeroBookView(heroRefId,true)
        self:RefreshBotBtnList()
    end)
    self:WndNetMsgRecv(LProtoIds.HeroBookAddCloseResp,function(...)
--[[        self:OnHeroBookAddCloseResp(...)
        self:RefreshBotBtnList()]]
    end)
    self:WndNetMsgRecv(LProtoIds.HeroBookAddCloseCleanResp,function(...)
        self:OnHeroBookAddCloseResp(...)
        self:RefreshBotBtnList()
    end)
    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
end

function UISagaBook:ClickHeroCard(itemdata,ignore)
    self:DestroyWndEffectByKey("fx_qinmijindu")
    CS.ShowObject(self.mBookListBg,false)
    local refId = itemdata.refId
    local serverData = gModelHeroBook:GetHeroInfoByHeroRefId(refId)
    if serverData then
        local isActive = serverData.isActive
        local haveHero = isActive and 1 or 0
        local status = gModelHeroBook:CheckBookInfoStatusByRefId(refId)
        local haveRed = status and 1 or 0
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-1-1",refId,haveHero,haveRed)
    end

	self:ShowHeroInfo(refId,ignore)
end

function UISagaBook:GetRelationList()
    local list = {}
    local serverList = gModelHeroBook:GetSortRelationInfoList()
    local refList = gModelHeroBook:GetHeroRelationRefList()
    for i, v in ipairs(serverList) do
        --[[        local data = v
                local refId = v.refId
                local refData = refList[refId]
                if refData then
                    local relationHeroKeyList = refData.relationHeroKeyList
                    local relationHeroList = refData.relationHeroList
                    data.relationHeroList = relationHeroList
                    data.relationHeroKeyList = relationHeroKeyList
                    data.listPrefabName = refData.listPrefabName
                    data.selfPrefabName = refData.selfPrefabName
                    data.bgList = refData.bgList
                    data.name = refData.name
                    data.rewardList = refData.rewardList
                    data.attrType = refData.attrType
                end
                table.insert(list,data)]]
        local data = table.clone(v)
        local refId = data.refId
        local refData = refList[refId]
        if refData then
            data.listPrefabName = refData.listPrefabName
            data.selfPrefabName = refData.selfPrefabName
            local relationHeroKeyList = refData.relationHeroKeyList
            local relationHeroList = refData.relationHeroList
            data.relationHeroList = relationHeroList
            data.relationHeroKeyList = relationHeroKeyList
            data.name = refData.name
            data.relationHeroNum = refData.relationHeroNum
        end
        table.insert(list, data)
    end
    return list
end

function UISagaBook:RefreshListView(isTujianBtn)
    local tabBtnInfoList = self._tabBtnInfoList or {}
    local page = self._page
    local func
    local showTrans, hideTrans
    local showIndex = 0
    local hideIndex = 0
    local infoRoot
    for k, v in pairs(tabBtnInfoList) do
        local index = v.index
        local show = index == page
        if show then
            showTrans = v.root
            showIndex = index
            func = v.disposeFunc
            infoRoot = v.infoRoot
        else
            hideIndex = index
            hideTrans = v.root
        end
    end
    local idleName
    if isTujianBtn ~= nil then
        if isTujianBtn then
            idleName = "idle2"
        else
            idleName = "idle1"
        end
    else
        idleName = "idle1"
    end
    if showIndex > hideIndex then
        CS.ShowObject(hideTrans, false)
        self:ChangeSubPageViewStatus(showTrans, true, true, function()
            CS.ShowObject(hideTrans, false)
        end,idleName)
    else
        if hideTrans.gameObject.activeSelf then
            CS.ShowObject(hideTrans, false)
        end
        self:ChangeSubPageViewStatus(showTrans, true, true, function()
            CS.ShowObject(hideTrans, false)
        end,idleName)
    end
    if infoRoot then
        CS.ShowObject(infoRoot,true)
    end
    if func then func() end
end

function UISagaBook:ChangeSubPageViewStatus(root, showStatus, isAni, callFunc,idleName)
    if self._isPlayEffect then return end
    if not root then return end
    if idleName == "idle1" then
        CS.ShowObject(root, showStatus)
    end
    local func = function()
        if idleName == "idle2" then
            CS.ShowObject(root, showStatus)
        end
        root.transform.localRotation = Quaternion.Euler(0, 0, 0)
        if callFunc then
            callFunc()
        end
    end
    if isAni then
        self:PlayEffect(showStatus, func, root,idleName)
    else
        if func then
            func()
        end
    end
end

function UISagaBook:ChangeRelationBtn(index, refreshFunc)
    if index == self._jbPage then  return end
    self._jbPage = index
    local uiRelationBtnList = self._uiRelationBtnList
    if not uiRelationBtnList then return end
    local uiList = uiRelationBtnList:GetList()
    uiList:RefreshList()
    if refreshFunc then
        refreshFunc()
    end
end

function UISagaBook:CheckRaceTypeRedPointStatus(raceType)
    if not raceType then return false end
    local showRedPoint = false
    for k, v in pairs(GameTable.CharacterRef) do
        if showRedPoint then break end
        if raceType == UIHeroRaceList.ALL_RACE_REFID or v.raceType == raceType then
            showRedPoint = gModelHeroBook:CheckHeroBookInfoStatusByRefId(k)
        end
    end
    return showRedPoint
end

function UISagaBook:OnDrawRelationCell(list, item, itemdata, itempos)
    local Root = self:FindWndTrans(item, "Root")
    if Root then
        local key = itemdata.refId
        local listPrefabName = itemdata.listPrefabName
        if not listPrefabName then
            listPrefabName = "TestRelationIcon"
        end
        LxResUtil.DestroyChildImmediate(Root)
        self:CreateWndPrefab(Root, listPrefabName, key, function(prefabTrans)
            local width = prefabTrans.sizeDelta.x
            local height = prefabTrans.sizeDelta.y + 20
            LxUiHelper.SetSizeWithCurAnchor(item, 0, width)
            LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
            LxUiHelper.SetSizeWithCurAnchor(Root, 0, width)
            LxUiHelper.SetSizeWithCurAnchor(Root, 1, height)
            self:CreateRelationItem(prefabTrans, key, itemdata)

            self:SendGuideReadyEvent(self:GetWndName())
        end, CS.RES_UI_HEROBOOK)
    end
end

function UISagaBook:ShowHeroInfo(refId,ignore)
	self._curHeroBookRefId = refId
    self:RefreshHeroBookView(refId)
    local playAni = true
    if ignore then
        playAni = false
    end
    self:ChangeSubPageViewStatus(self.mHeroBookView, true, playAni, function()
        --self:PlayEffShow(10000)
        self:CheckQMJDCanUp(refId)
        self._heroBookState = 1
    end,"idle1")
	self:SaveWndArg()
end

function UISagaBook:OnCutHero(heroObj, beginPos, endPos)
    if self._page ~= ModelHeroBook.HEROTJ_IDX then return end
    if not self.mHeroBookView.gameObject.activeSelf then return end
    if self._curUILiHuiObj == nil then return end
    if self._curUILiHuiObj ~= heroObj then return end
    local beginX = beginPos.x
    local endX = endPos.x
    local subX = beginX - endX
    if subX > 20 then
        self:CutHero(1)
    elseif subX < -20 then
        self:CutHero(-1)
    end
end

function UISagaBook:InitText()
    local addLine = -30
    if gLGameLanguage:IsGermanVersion() then
        addLine = -50
    elseif gLGameLanguage:IsFrenchVersion() then
        addLine = -60
    end
    self:SetWndText(self.mBookListTitle, ccClientText(19700))
    self:SetWndText(self.mRelationListTitle, ccClientText(19708))
    self:SetWndText(self.mQmDJTxt, ccClientText(19705))
    self:SetWndText(self.mQmJDTxt, ccClientText(19706))
    self:SetWndText(self.mHBWayBtnTxt, ccClientText(19714))
    self:InitTextLineWithLanguage(self.mHBWayBtnTxt, addLine)
    self:SetWndText(self.mHBStarPreBtnTxt, ccClientText(19715))
    self:InitTextLineWithLanguage(self.mHBStarPreBtnTxt, addLine)
    self:SetWndText(self.mHBStoryBtnTxt, ccClientText(19716))
    self:InitTextLineWithLanguage(self.mHBStoryBtnTxt, addLine)
    self:SetWndText(self.mHBPinlunBtnTxt, ccClientText(19717))
    self:InitTextSizeWithLanguage(self.mHBPinlunBtnTxt, -2)
    self:InitTextLineWithLanguage(self.mHBPinlunBtnTxt, addLine)
    --self:InitTextLineWithLanguage(self.mHBPinlunBtnTxt, -50)
    self:SetWndText(self.mHBSkinBtnTxt, ccClientText(19718))
    self:InitTextLineWithLanguage(self.mHBSkinBtnTxt, addLine)
    self:SetWndButtonText(self.mRelationAddShowBtn, ccClientText(19709))
    --self:InitTextLineWithLanguage(self.mRelationAddShowBtn, -50)
    self:SetWndButtonText(self.mHeroBookUpBtn, ccClientText(19707))
    --self:InitTextLineWithLanguage(self.mHeroBookUpBtn, -50)
    self:SetWndButtonText(self.mJBSJViewGetBtn, ccClientText(19744))
    self:SetTextTile(self.mHeroBookTextTitle, ccClientText(19704))
    self:SetTextTile(self.mJBSJTextTitle, ccClientText(19712))
    self:SetWndText(self.mHeroRelationStoryBtnTxt, ccClientText(19716))
    self:InitTextLineWithLanguage(self.mHeroRelationStoryBtnTxt, addLine)
    self:SetWndText(self.mHeroRelationCommentBtnTxt, ccClientText(19717))
    self:InitTextLineWithLanguage(self.mHeroRelationCommentBtnTxt, addLine)
    self:SetWndText(self.mHeroRelationCameraBtnTxt, ccClientText(19743))
    self:InitTextLineWithLanguage(self.mHeroRelationCameraBtnTxt, addLine)
    self:SetWndText(self.mRelationBarrageBtnTxt,ccClientText(19736))
    self:SetWndText(self.mJBJCViewDesc,ccClientText(19740))
end

function UISagaBook:InitBtnList()
    local list = {}
    for k, v in pairs(self._tabBtnInfoList) do
        table.insert(list, table.clone(v))
    end
    table.sort(list, function(a, b)
        return a.index < b.index
    end)
    local uiBtnList = self._uiBtnList
    if uiBtnList then
        uiBtnList:RefreshList(list)
    else
        uiBtnList = self:GetUIScroll("uiBtnList")
        self._uiBtnList = uiBtnList
        uiBtnList:Create(self.mTabBtnList, list, function(...)
            self:OnDrawBtnCell(...)
        end)
    end
end

function UISagaBook:GetHeroRelationAttrList(refId, attrType)
    local attrList = {}
    local relationAttrRefList = gModelHeroBook:GetHeroRelationAttrRefListByRelationType(attrType)
    local serverData = gModelHeroBook:GetRelationInfoByRefId(refId)
    if not relationAttrRefList and not serverData then
        return attrList
    end
    local heroes = serverData.heroes or {}
    local heroLen = #heroes
    local activeNumKeyList = serverData.activeNumKeyList or {}
    for k, v in pairs(relationAttrRefList) do
        local relationAttrRefId = v.refId
        local need = v.need
        local status
        local isAct = heroLen >= need
        if isAct then
            status = activeNumKeyList[relationAttrRefId] and UISagaBook.JB_STATUS_RECEIVE or UISagaBook.JB_STATUS_CANRECEIVE
        else
            status = UISagaBook.JB_STATUS_NOACT
        end
        local data = {
            refId = relationAttrRefId,
            attrList = v.attrList,
            need = need,
            attrType = v.type,
            status = status,
            groupRefId = refId,
        }
        table.insert(attrList, data)
    end
    table.sort(attrList, function(a, b)
        return a.need < b.need
    end)
    return attrList
end

function UISagaBook:InitHeroBookList(isTop)
    local heroList = self:GetHeroBookList()
    local uiHeroList = self._uiHeroList
    if uiHeroList then
        uiHeroList:RefreshList(heroList)
        if isTop then
            local uiList = uiHeroList:GetList()
            uiList:MoveToPos(1)
        else
            uiHeroList:DrawAllItems()
        end
    else
        uiHeroList = self:GetUIScroll("uiHeroList")
        self._uiHeroList = uiHeroList
        uiHeroList:Create(self.mHeroSpQuaMapList, heroList, function(...)
            self:OnDrawHeroSpCell(...)
        end, UIItemList.SUPER)
    end
    local isempty = #heroList < 1
    CS.ShowObject(self.mNoRecord2,isempty)
    local index = 0
    for i,v in ipairs(heroList) do
        if index ~= 0 then break end
        if not v.showQuaDiv then
            for idx,heroInfo in ipairs(v.heroList) do
                local refId = heroInfo.refId
                local status = gModelHeroBook:FindIsNewActHeroInfoByRefId(refId,true)
                if status then
                    index = i
                    break
                end
            end
        end
    end
    if index == 0 then
        for i,v in ipairs(heroList) do
            if index ~= 0 then break end
            if not v.showQuaDiv then
                for idx,heroInfo in ipairs(v.heroList) do
                    local refId = heroInfo.refId
                    local rstatus = gModelHeroBook:CheckHeroBookInfoStatusByRefId(refId)
                    if rstatus then
                        index = i
                        break
                    end
                end
            end
        end
    end
    if index ~= 0 then
        uiHeroList:MoveToPos(index)
    end
end

function UISagaBook:GetHeroBookList()
    self:RefreshHeroRaceTypeList()
    self._heroBookList = {}
    self._heroBookKeyList = {}
    local heroIndex = 0
    local list = {}
    for k, v in pairs(GameTable.CharacterRef) do
        local refId = v.refId
        local raceType = v.raceType

        local ins = false
        if self._raceType == 0 then
            ins = true
        elseif raceType == self._raceType then
            ins = true
        end
        if ins then
            local quality = v.quality
            local listInfo = list[quality]
            if not listInfo then
                listInfo = {}
                listInfo.quality = quality
                listInfo.heroList = {}
                list[quality] = listInfo
            end
            local heroList = listInfo.heroList
            if not heroList then
                heroList = {}
                listInfo.heroList = listInfo
            end
            local heroQuality = gModelHero:GetHeroQualityByRefId(refId)
            local data = {
                raceType = v.raceType,
                careerType = v.careerType,
                refId = refId,
                quality = quality,
            }
            table.insert(heroList, data)
        end
    end

    local sortList = {}
    for k, v in pairs(list) do
        table.insert(sortList, v)
    end
    table.sort(sortList, function(a, b)
        return a.quality > b.quality
    end)

    local cardMaxNum = UISagaBook.CARD_MAX_NUM
    local qualityList = {}
    local tList = {}
    for k, v in ipairs(sortList) do
        local quality = v.quality
        local heroList = v.heroList or {}
        local listLen = #heroList
        local isHave = listLen > 0
        if isHave then
            local quaInfo = qualityList[quality]
            if not quaInfo then
                qualityList[quality] = true
                table.insert(tList, {
                    quality = quality,
                    showQuaDiv = true,
                })
            end
            table.sort(heroList, function(a, b)
                local raceType1, raceType2 = a.raceType, b.raceType
                if raceType1 ~= raceType2 then
                    return raceType1 < raceType2
                else
                    local careerType1, careerType2 = a.careerType, b.careerType
                    if careerType1 ~= careerType2 then
                        return careerType1 < careerType2
                    else
                        return a.refId < b.refId
                    end
                end
            end)
            local maxRow = math.ceil(listLen / cardMaxNum)
            for idx = 1, maxRow do
                local tHeroList = {}
                for num = 1, cardMaxNum do
                    local index = (idx - 1) * cardMaxNum + num
                    local data = heroList[index]
                    if data then
                        heroIndex = heroIndex + 1
                        local refId = data.refId
                        table.insert(tHeroList, data)
                        table.insert(self._heroBookList, refId)
                        self._heroBookKeyList[refId] = heroIndex
                    end
                end
                table.insert(tList, {
                    heroList = tHeroList
                })
            end
        end
    end
    return tList
end
------------------------------ BookListView ------------------------------

------------------------------ HeroBookView ------------------------------
function UISagaBook:RefreshHeroBookView(refId,netWork)
    local serverData = gModelHeroBook:GetHeroInfoByHeroRefId(refId)
    if not serverData then return end
    local closeGrade = serverData.heroMaxStar
    local heroRef = gModelHero:GetHeroRef(refId)
    if not heroRef then return end
    gModelHero:PlayHeroRoleSound(refId)
    local closeLv = heroRef.closeLv
    local heroCloseRef = gModelHeroBook:GetHeroCloseLvRefByCloseTypeAndCloseGrade(closeLv, closeGrade)
    if not heroCloseRef then return end

    local race = heroRef.raceType
    local raceRef = gModelHero:GetHeroRaceRefByRefId(race)
    if raceRef then
        local heroBgHalf = raceRef.heroBgHalf
        self:SetWndEasyImage(self.mHeroBookImg, heroBgHalf)
    end
    if not netWork then
        self:CreateLiHui(refId)
    end
    self:CreateQMDJList(closeGrade,refId)

    local isActive = serverData.isActive
    local closeValue = serverData.closeValue
    local needLevel = heroCloseRef.needLevel
    local isMax = needLevel == ModelHeroBook.HEROCLOSELV_MAX
    local maxValue = isMax and 1 or needLevel
    local value = isMax and 1 or closeValue
    local uiSlider = self._uiSlider
    if not uiSlider then
        uiSlider = self:FindWndSlider(self.mMeBar)
        self._uiSlider = uiSlider
    end
    uiSlider.maxValue = maxValue
    uiSlider.value = value

    local showHeroBookUpBtn = isActive and (not isMax) or false
    if not showHeroBookUpBtn then
        local textId
        if isMax then
            textId = 19720
        elseif (not isActive) then
            textId = 19719
        end
        if textId then
            self:SetWndText(self.mHeroBookStatusTxt, ccClientText(textId))
        end
    end
    CS.ShowObject(self.mHeroBookUpBtn, showHeroBookUpBtn)
    CS.ShowObject(self.mHeroBookStatusTxt, not showHeroBookUpBtn)
    local status = false
    if showHeroBookUpBtn then
        status = gModelHeroBook:CheckBookInfoStatusByRefId(refId)
    end
    CS.ShowObject(self.mHeroBookUpBtnRedPoint,showHeroBookUpBtn and status)

    local showQMNum = not isMax
    local qmNumTrans = self.mQmNum
    if showQMNum then
        local str = string.replace(ccClientText(19713), closeValue, needLevel)
        self:SetWndText(qmNumTrans, str)
    end
    CS.ShowObject(qmNumTrans, showQMNum)
    local attrList = heroCloseRef.attrList or {}
    self:CreateAttrList("mQmAddAttrList", attrList, self.mQmAddAttrList)

    local haveHero = gModelHeroBook:GetHeroIsActByRefId(refId)

    self:SetWndClick(self.mHeroBookUpBtn, function()
        gModelHeroBook:OnHeroBookUpCloseGradeReq(refId)
    end)
    self:SetWndClick(self.mHBStoryBtn, function()
        local storyStatus = gModelHeroBook:CheckBookStoryStatusByRefId(refId)
        local t = storyStatus and 1 or 0
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-1-1-3",refId,haveHero,t)
        GF.OpenWnd("UISagaSy", { refId = refId })
    end)
    local storyStatus = gModelHeroBook:CheckBookStoryStatusByRefId(refId)
    CS.ShowObject(self.mHBStoryBtnRedPoint,storyStatus)
    self:SetWndClick(self.mHeroBookViewLoveBtn,function()
        --GF.OpenWndTop("UIXAddSow", { closeType = closeLv,heroRefId = refId })
    end)
    self:SetWndClick(self.mHBSkinBtn, function()
        --gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-1-1-5",refId,haveHero,0)
        --GF.OpenWndTop("UISagaDisPy", { heroRefId = refId })
    end)
    self:SetWndClick(self.mHBStarPreBtn, function()
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-1-1-2",refId,haveHero,0)
        local index = self._heroBookKeyList and self._heroBookKeyList[refId]
        if not index then
            for i, v in ipairs(self._heroBookList) do
                if v == refId then
                    index = i
                    break
                end
            end
        end
        gModelGeneral:OpenHeroStarPre({ refId = refId, list = self._heroBookList or {}, index = index, func = function(curHeroRefId)
            if curHeroRefId ~= refId then
                self:RefreshHeroBookView(curHeroRefId)
            end
        end})
    end)
    self:SetWndClick(self.mHBPinlunBtn, function()
        local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_3)
        if not sensitive then
            GF.ShowMessage(ccClientText(30800))
            return
        end
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-1-1-4",refId,haveHero,0)
        GF.OpenWnd("UISagaComment", { refId = refId })
    end)
    self:SetWndClick(self.mHBWayBtn, function()
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-1-1-1",refId,haveHero,0)
        gModelGeneral:OpenGetWayWnd( { itemId = refId,refIdType = LItemTypeConst.TYPE_HERO,srcWnd = self:GetWndName()})
    end)
end
------------------------------ RelationListView ------------------------------
------------------------------ HeroRelationView ------------------------------
function UISagaBook:RefreshRelationView(key, init)
    self._selRelationRefId = key
    self:OpenBarrageShow()
    self:InitRelationBtnList(init)

    self:SendGuideReadyEvent(self:GetWndName())
    self:SetWndClick(self.mHeroRelationStoryBtn, function()
        local serverData = gModelHeroBook:GetRelationInfoByRefId(key)
        local curHeroNum = serverData and #serverData.heroes or 0
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-2-1-1",key,curHeroNum,0)
        GF.OpenWndUp("UIRelationSy", { relationRefId = key })
    end)
    self:SetWndClick(self.mHeroRelationCommentBtn, function()
        local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_3)
        if not sensitive then
            GF.ShowMessage(ccClientText(30800))
            return
        end
        local serverData = gModelHeroBook:GetRelationInfoByRefId(key)
        local curHeroNum = serverData and #serverData.heroes or 0
        gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,"2-2-1-2",key,curHeroNum,0)
        GF.OpenWndTop("UIRelationBulletSaySendPop", { relationRefId = key })
    end)
end

function UISagaBook:CreateLiHui(heroRefId)
    local effectRef = gModelHero:GetShowEffectById(heroRefId)
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
    local heroDrawing = effectRef.heroDrawing
    local newUILiHuiObj = uiHeroLiHuiList[heroDrawing]
    local oldUILiHuiObj = self._curUILiHuiObj
    if oldUILiHuiObj and newUILiHuiObj ~= oldUILiHuiObj then
        oldUILiHuiObj:ShowHero(false)
    end
    if not newUILiHuiObj then
        newUILiHuiObj = LUIHeroObject:New(self)
        newUILiHuiObj[heroDrawing] = newUILiHuiObj
        self._curUILiHuiObj = newUILiHuiObj
        newUILiHuiObj:Create(self.mHeroLiHuiPos, heroDrawing, heroDrawing)
        newUILiHuiObj:SetDragFunc(function(...) self:OnCutHero(...) end)
        newUILiHuiObj:SetRectMatch(true)
        newUILiHuiObj:ShowHero(true)
        newUILiHuiObj:StartLoad()
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
end

function UISagaBook:CutHero(optNum)
    local heroBookList = self._heroBookList
    if not heroBookList then return end
    local heroBookKeyList = self._heroBookKeyList
    if not heroBookKeyList then return end
    local curRefId = self._curHeroBookRefId
    if not curRefId then return end
    local curIdx = heroBookKeyList[curRefId]
    if not curIdx then return end
    local newIdx = curIdx + optNum
    local len = #heroBookList
    if newIdx < 1 then
        newIdx = len
    elseif newIdx > len then
        newIdx = 1
    end
    local newRefId = heroBookList[newIdx]
    if newRefId then
        self._curHeroBookRefId = newRefId
        self:CheckQMJDCanUp(newRefId)
        self:RefreshHeroBookView(newRefId)
    end
end

function UISagaBook:OnDrawBtnCell(list, item, itemdata, itempos)
    local index = itemdata.index
    local BtnTab1 = self:FindWndTrans(item, "BtnTab1")
    if BtnTab1 then
        local btnTxt = itemdata.btnTxt
        self:SetWndTabText(BtnTab1, btnTxt)
        local status = index == self._page and 0 or 1
        self:SetWndTabStatus(BtnTab1, status)
        self:SetWndClick(BtnTab1, function()
            local step = "2-"..index
            gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_HERO_BOOK,step)
            self:ChnageTabFunc(index)
        end)
    end
    local redPoint = self:FindWndTrans(item,"redPoint")
    if redPoint then
        local status
        if index == ModelHeroBook.HEROTJ_IDX then
            status = gModelHeroBook:CheckBookInfoStatus()
        elseif index == ModelHeroBook.HEROJB_IDX then
            status = gModelHeroBook:CheckRelationInfoStatus()
        end
        CS.ShowObject(redPoint,status)
    end
end

function UISagaBook:CreateRelationHeroList(relationHeroNum, heroList,selRelationRefId)
    if self._uiRelationHeroList then
        self._uiRelationHeroList:RefreshList({})
    end
    if self._uiRelationMoreHeroList then
        self._uiRelationMoreHeroList:RefreshList({})
    end
    local serverData = gModelHeroBook:GetRelationInfoByRefId(selRelationRefId)
    if not serverData then return end
    local heroesKey = serverData.heroesKey
    local list = {}
    for i = 1, relationHeroNum do
        local mask = false
        local data = heroList[i]
        if data then
            if heroesKey[data] then
                mask = false
            else
                mask = true
            end
            printInfoNR("refId = " .. data .. ",name = " .. gModelHero:GetHeroNameByRefId(data))
        end
        table.insert(list, { itemType = LItemTypeConst.TYPE_HERO, itemRefId = data, itemNum = 1,mask = mask})
    end
    local uiHeroMoreList
    local uiHeroMoreListKey
    local uiListTrans,hideListTrans
    local isMore = #list > UISagaBook.MORE_HERO_NUM
    if not isMore then
        uiHeroMoreList = self._uiRelationHeroList
        uiHeroMoreListKey = "uiRelationHeroList"
        uiListTrans = self.mJBSJHeroList
        hideListTrans = self.mJBSJHeroMoreList
    else
        uiHeroMoreList = self._uiRelationMoreHeroList
        uiHeroMoreListKey = "uiRelationMoreHeroList"
        uiListTrans = self.mJBSJHeroMoreList
        hideListTrans = self.mJBSJHeroList
    end
    CS.ShowObject(self.mJBSJView, true)
    CS.ShowObject(uiListTrans, true)
    CS.ShowObject(hideListTrans, false)
    if uiHeroMoreList then
        if isMore then
            uiHeroMoreList:RefreshList(list,false)
            local uiList = uiHeroMoreList:GetList()
            uiList:RefreshList()
        else
            uiHeroMoreList:RefreshList(list)
        end
    else
        uiHeroMoreList = self:GetUIScroll(uiHeroMoreListKey)
        if isMore then
            self._uiRelationMoreHeroList = uiHeroMoreList
            uiHeroMoreList:Create(uiListTrans, list, function(...)
                self:OnDrawRelationHeroCell(...)
            end, UIItemList.SUPER)
        else
            self._uiRelationHeroList = uiHeroMoreList
            uiHeroMoreList:Create(uiListTrans, list, function(...)
                self:OnDrawRelationHeroCell(...)
            end)
        end
    end
end

function UISagaBook:CreateHeroPrefab(key)
    local serverData = gModelHeroBook:GetRelationInfoByRefId(key)
    if not serverData then return end
    local cardData = gModelHeroBook:GetHeroRelationRefByRefId(key)
    if not cardData then return end
    local selfPrefabName = cardData.selfPrefabName
    local relationHeroKeyList = cardData.relationHeroKeyList
    local heroesKey = serverData.heroesKey
    self:CreateWndPrefab(self.mHeroRelationImg, selfPrefabName, key, function(prefabTrans)
        for k, v in pairs(relationHeroKeyList) do
            local heroTrans = self:FindWndTrans(prefabTrans, v)
            local isGray = not heroesKey[v]
            self:SetWndImageGray(heroTrans, isGray)
        end
        local HeroBookName1 = self:FindWndTrans(prefabTrans,"HeroBookName1")
        if HeroBookName1 then
            local NameTxt = self:FindWndTrans(HeroBookName1,"NameTxt")
            local NumTxt = self:FindWndTrans(HeroBookName1,"NumTxt")
            self:SetHeroRelationNameAndNum(NameTxt,ccLngText(cardData.name),NumTxt,serverData.heroes,cardData.relationHeroNum)
        end
    end, CS.RES_UI_HEROBOOK)
end

function UISagaBook:CreateRelationItemList(list)
    local uiRelationItemList = self._uiRelationItemList
    if uiRelationItemList then
        uiRelationItemList:RefreshList(list)
    else
        uiRelationItemList = self:GetUIScroll("uiRelationItemList")
        self._uiRelationItemList = uiRelationItemList
        uiRelationItemList:Create(self.mJBSJRewardList, list, function(...)
            self:OnDrawRelationItemCell(...)
        end)
    end
end

function UISagaBook:ShowJSTransView(rootTrans, otherTransList)
    CS.ShowObject(rootTrans, true)
    for i, v in ipairs(otherTransList or {}) do
        CS.ShowObject(v, false)
    end
end

function UISagaBook:ChnageTabFunc(index)
    if self._isPlayEffect then return end
    if self._page == index then return end
    self:DestroyWndEffectByKey("fx_qinmijindu")
    local isTujianBtn = index == ModelHeroBook.HEROTJ_IDX
    self._page = index
    if isTujianBtn then
        FireEvent(EventNames.ON_COMMON_BARRAGE_STATUS, false)
    elseif self._selRelationRefId ~= 0 and self._showRelationViewBarrage then
        FireEvent(EventNames.CHANGE_COMMON_BARRAGE_INFO, {
            heroRefId = self._selRelationRefId,
            barrageType = ModelHeroBook.BARRAGE_TYPE_HERORELATION
        })
    end
	self:SaveWndArg()
    self:InitBtnList()
    self:RefreshListView(isTujianBtn)
end

function UISagaBook:RefreshBotBtnList()
    local uiBtnList = self._uiBtnList
    if uiBtnList then
        local uiList = uiBtnList:GetList()
        uiList:RefreshList()
    end
end
------------------------------ HeroBookView ------------------------------
return UISagaBook