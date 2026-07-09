---
--- Created by Administrator.
--- DateTime: 2024/11/14 14:21:08
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubSorceryCardBook:LChildWnd
local UISubSorceryCardBook = LxWndClass("UISubSorceryCardBook", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubSorceryCardBook:UISubSorceryCardBook()
    self._raceList = {}
    self._raceItemList = {}
    self._raceItemGroupList = {}
    self._heroIconList = {}
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubSorceryCardBook:OnWndClose()
    LChildWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubSorceryCardBook:OnCreate()
    self:ClearCommonIconList(self._heroIconList)
    LChildWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubSorceryCardBook:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()

    self:InitEvent()
    self:InitMessage()
    self:InitCommand()

    gModelSorceryCard:OnSorceryCardOpenReq()
end

function UISubSorceryCardBook:InitEvent()
    self:SetWndClick(self.mTypeBg, function()
        self:OnClickType()
    end)
    self:SetWndClick(self.mTypeMask, function()
        self:OnClickTypeMask()
    end)
end

function UISubSorceryCardBook:InitMessage()
    self:WndNetMsgRecv(LProtoIds.SorceryCardOpenResp, function(pb)
        self:RefreshContent()
    end)
    self:WndNetMsgRecv(LProtoIds.SorceryCardUpgradeResp, function(pb)
        self:RefreshData()
        self._themeUiList:DrawAllItems()
    end)
    self:WndNetMsgRecv(LProtoIds.SorceryCardUnloadResp, function(pb)
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.SorceryCardCollectorResp, function(pb)
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.SorceryCardWearResp, function(pb)
        self:RefreshData()
    end)
    self:WndEventRecv(EventNames.On_Item_Change,function()
        if gModelGuide:IsInGuide() then
            self._isMoveTab = true
            self:RefreshData()
        end
    end)
end

function UISubSorceryCardBook:CardListItem(item, itemdata, itempos, layer)
    if not item then
        return
    end
    CS.ShowObject(item, itemdata)
    if not itemdata then
        return
    end
    local root = self:FindWndTrans(item, "Root")
    local icon = self:FindWndTrans(root, "Icon")
    local image = self:FindWndTrans(root, "Image")
    local nameText = self:FindWndTrans(root, "NameText")
    local heroBg = self:FindWndTrans(root, "HeroBg")
    local heroRoot = self:FindWndTrans(root, "HeroBg/HeroRoot")
    local lvText = self:FindWndTrans(root, "LVText")
    local luck = self:FindWndTrans(root, "Luck")
    local seal = self:FindWndTrans(root, "Seal")
    local sealT = self:FindWndTrans(seal, "Seal")
    local redPoint = self:FindWndTrans(root, "redPoint")

    if self._isEnus then
        sealT.sizeDelta = Vector2.New(168, 55)
    end

    local InstanceID = item:GetInstanceID()
    local scRefId = itemdata.refId
    local _cardList = self._cardList
    local _card = _cardList[scRefId]
    local lvStr = _card and string.replace(ccClientText(29550), _card.level) or ""
    local themeRef = gModelSorceryCard:GetSorceryCardThemeRefByRefId(itemdata.theme)

    self:SetWndEasyImage(icon, itemdata.icon, function()
        CS.ShowObject(icon, true)
    end, not CS.IsWebGL())
    self:SetWndEasyImage(image, itemdata.frameRes, function()
        CS.ShowObject(image, true)
    end)
    self:SetWndEasyImage(luck, themeRef.cardFrame, nil, false, false)
    self:SetWndEasyImage(seal, themeRef.cardFrame, nil, false, false)
    self:SetWndText(nameText, ccLngText(itemdata.name))
    self:SetWndText(lvText, lvStr)
    self:SetTextTile(sealT, ccClientText(29570))

    self:SetWndClick(root, function()
        self:OnClickCard(itemdata, layer)
    end)
    self:SetWndClick(heroBg, function()
        self:OnClickCard(itemdata, layer, true)
    end)
    CS.ShowObject(heroBg, _card)
    local heroId = _card and _card.heroId
    local isHero = not string.isempty(heroId) and tonumber(heroId) > 0
    CS.ShowObject(heroRoot, isHero)
    local baseClass = self._heroIconList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New(self)
        self._heroIconList[InstanceID] = baseClass
        baseClass:Create(heroRoot)
    end
    baseClass:SetHeroPlayer(heroId)
    baseClass:DoApply()

    if not _card then
        local isUp = gModelSorceryCard:VerifyCardUpCost(itemdata.refId, 0)
        CS.ShowObject(luck, not isUp)
        CS.ShowObject(seal, isUp)
        CS.ShowObject(redPoint, isUp)
        return
    end
    CS.ShowObject(luck, false)
    CS.ShowObject(seal, false)
    local isUp = gModelSorceryCard:VerifyCardUpCost(itemdata.refId, _card.level)
    CS.ShowObject(redPoint, isUp)
end

function UISubSorceryCardBook:RaceListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local icon = self:FindWndTrans(root, "Icon")
    local selImg = self:FindWndTrans(root, "SelImg")
    local nameText = self:FindWndTrans(root, "NameText")
    local redPoint = self:FindWndTrans(root, "redPoint")

    local filterOptions = gModelSorceryCard:GetFilterOptions()
    local isRed = self:GetThemeRed(itemdata.refId)
    local _race = self._race
    local num, len = 0, 0
    if filterOptions == 1 then
        local sorceryCardRefs = gModelSorceryCard:GetSorceryCardRefByTheme(itemdata.refId)
        len = #sorceryCardRefs
        num = 0
        for i, v in ipairs(sorceryCardRefs) do
            if gModelSorceryCard:GetCardInfoByRefId(v.refId) then
                num = num + 1
            end
        end
    elseif filterOptions == 2 then
        local sorceryCardRecomGroupRef = gModelSorceryCard:GetSorceryCardRecomGroupRefByTheme(itemdata.refId)
        len = #sorceryCardRecomGroupRef
        num = 0
        for i, v in ipairs(sorceryCardRecomGroupRef) do
            local cardDetail = string.split(v.cardDetail, ",")
            local isAct = true
            for j, k in ipairs(cardDetail) do
                if not gModelSorceryCard:GetCardInfoByRefId(tonumber(k)) then
                    isAct = false
                    break
                end
            end
            if isAct then
                num = num + 1
            end
        end
    end

    CS.ShowObject(redPoint, isRed)
    CS.ShowObject(selImg, _race and _race == itemdata.refId)
    self:SetWndEasyImage(icon, itemdata.icon,nil,true)
    self:SetWndText(nameText, ccLngText(itemdata.name) .. "\n" .. string.format("(%s/%s)", num, len))
    self:InitTextSizeWithLanguage(nameText, -4)
    self:InitTextLineWithLanguage(nameText, -30)
    self:SetWndClick(root, function()
        self:OnClickRace(itemdata.refId)
    end)

    self._redTabTranList[itemdata.refId] = redPoint

    self._selTranList[selImg] = itemdata.refId
end

function UISubSorceryCardBook:GetThemeRed(theme)
    local _cardList = self._cardList or {}
    local sorceryCardRefs = gModelSorceryCard:GetSorceryCardRefByTheme(theme)
    for i, v in ipairs(sorceryCardRefs) do
        local _card = _cardList[v.refId]
        local level = _card and _card.level or 0
        local isUp = gModelSorceryCard:VerifyCardUpCost(v.refId, level)
        if isUp then
            return true
        end
    end
    return false
end

function UISubSorceryCardBook:ListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local titleBg = self:FindWndTrans(root, "TitleBg")
    local titleText = self:FindWndTrans(titleBg, "TitleText")
    local titleBg2 = self:FindWndTrans(root, "TitleBg2")
    local titleText2 = self:FindWndTrans(titleBg2, "TitleText")
    local titleBg3 = self:FindWndTrans(root, "TitleBg3")
    local titleText3 = self:FindWndTrans(titleBg3, "TitleText")
    local cardList = self:FindWndTrans(root, "CardList")

    local selType = gModelSorceryCard:GetFilterOptions()
    local type = itemdata.type
    local higth = 40
    CS.ShowObject(titleBg, type == 1 and selType == 1)
    CS.ShowObject(titleBg2, false)
    CS.ShowObject(titleBg3, false)
    CS.ShowObject(cardList, type == 2)
    if type == 1 then
        self:SetWndText(titleText, itemdata.titleName)
        self:SetWndText(titleText2, itemdata.titleName)
        self:SetWndText(titleText3, itemdata.titleName)
        if selType == 2 then
            local uiText = LxUiHelper.FindXTextCtrl(titleText2)
            local width = uiText.preferredWidth
            CS.ShowObject(titleBg2, width > 110)
            CS.ShowObject(titleBg3, width <= 110)
        end
    else
        higth = 304
        local list = itemdata.list
        for i = 1, 3 do
            local item = self:FindWndTrans(cardList, "Card" .. i)
            local itemdata = list[i]
            self:CardListItem(item, itemdata, i, itempos)
        end
    end
    LxUiHelper.SetSizeWithCurAnchor(item, 1, higth)
end

function UISubSorceryCardBook:RefreshContent()
    self._cardList = gModelSorceryCard:GetCardList()
    if not self._cardList then
        return
    end

    if self._redTabTranList then
        for k, v in pairs(self._redTabTranList) do
            local isRed = self:GetThemeRed(k)
            CS.ShowObject(v, isRed)
        end
    end

    local theme = self:GetWndArg("theme")
    local list = gModelSorceryCard:GetSorceryCardThemeRef()
    if theme then
        self:OnClickRace(theme)
    elseif not self._isOneTab then
        self._isOneTab = true
        local index = 1
        for i, v in ipairs(list) do
            local bool = self:GetThemeRed(v.refId)
            if bool then
                index = i
                break
            end
        end
        local uiList = self:FindUIScroll("tabList")
        if uiList then
            uiList:MoveToPos(index)
        end

        self:OnClickRace(list[index].refId)
    else
        self:OnClickRace(list[1].refId)
    end
end

function UISubSorceryCardBook:OnClickCard(itemdata, layer, isOpenWear)
    GF.OpenWnd("UISorceryCardUpLv", { refId = itemdata.refId, callMoveLayer = layer, callTheme = self._race, isOpenWear = isOpenWear })
end

function UISubSorceryCardBook:OnClickTypeMask()
    self._isShowType = false
    CS.ShowObject(self.mTypeMask, false)
    CS.ShowObject(self.mTypeListBg, false)
end

function UISubSorceryCardBook:TypeListItem(list, item, itemdata, itempos)
    local selImg = self:FindWndTrans(item, "SelImg")
    local uIText = self:FindWndTrans(item, "UIText")

    local oldType = gModelSorceryCard:GetFilterOptions()

    self:SetWndText(uIText, itemdata.title)
    CS.ShowObject(selImg, oldType == itemdata.type)
    self:SetWndClick(item, function()
        if oldType and oldType == itemdata.type then
            return
        end
        self:OnClickTypeItem(itemdata.type)
    end)
end

function UISubSorceryCardBook:GetItemGroupByRace(_race)
    local itemList = {}
    local groups = gModelSorceryCard:GetSorceryCardRecomGroupRefByTheme(_race)
    for i, v in ipairs(groups) do
        table.insert(itemList, { type = 1, titleName = ccLngText(v.name) })
        local list = {}
        local cardDetail = string.split(v.cardDetail, ",")
        for j, k in ipairs(cardDetail) do
            local ref = gModelSorceryCard:GetSorceryCardRefByRefId(tonumber(k))
            table.insert(list, ref)
        end
        table.insert(itemList, { type = 2, list = list })
    end
    self._raceItemGroupList[_race] = itemList
    return itemList
end

function UISubSorceryCardBook:RefreshData()
    local cardList = gModelSorceryCard:GetCardList()
    if not cardList then
        gModelSorceryCard:OnSorceryCardOpenReq()
        return
    end
    local filterOptions = gModelSorceryCard:GetFilterOptions()
    self._cardList = cardList
    local _race = self._race
    local _raceItemList = self._raceItemList
    if filterOptions == 1 then
        _raceItemList = self._raceItemList
    elseif filterOptions == 2 then
        _raceItemList = self._raceItemGroupList
    end
    local itemList = _raceItemList[_race]
    if not itemList then
        if filterOptions == 1 then
            itemList = self:GetItemListByRace(_race)
        elseif filterOptions == 2 then
            itemList = self:GetItemGroupByRace(_race)
        end
    end
    local moveIndex = 0
    local isMoveTab = self._isMoveTab
    if isMoveTab then
        for i, v in ipairs(itemList) do
            if v.type == 2 then
                for j, k in ipairs(v.list) do
                    local _card = cardList[k.refId]
                    local isUp = false
                    if _card then
                        isUp = gModelSorceryCard:VerifyCardUpCost(k.refId, _card.level)
                    else
                        isUp = gModelSorceryCard:VerifyCardUpCost(k.refId, 0)
                    end
                    if isUp then
                        moveIndex = i
                        break
                    end
                end
            end
            if moveIndex > 0 then
                break
            end
        end
    end

    local uiList = self._uiList
    if uiList then
        uiList:RefreshList(itemList)
        uiList:DrawAllItems()
    else
        uiList = self:GetUIScroll("mCellSuper_UISorceryCardBook_")
        self._uiList = uiList
        uiList:Create(self.mCellSuper, itemList, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER)
        uiList:EnableScroll(true, false)
    end
    if isMoveTab then
        if moveIndex > 0 and not self._isUp then
            uiList:MoveToPos(moveIndex - 1)
        else
            uiList:MoveToPos(1)
        end
        self._isMoveTab = false
        self._isUp = false
    end
end

function UISubSorceryCardBook:InitCommand()
    self._moveLayer = self:GetWndArg("moveLayer")

    self:RefreshTypeShow()

    self._redTabTranList = {}
    self._selTranList = {}

    local list = gModelSorceryCard:GetSorceryCardThemeRef()
    local uiList = self:GetUIScroll("tabList")
    self._themeUiList = uiList
    uiList:Create(self.mThemeSuper, list, function(...)
        self:RaceListItem(...)
    end, UIItemList.SUPER)
    uiList:EnableScroll(#list > 5, true)
end

function UISubSorceryCardBook:GetItemListByRace(_race)
    local itemList = {}
    local _race = _race or 1
    local sorceryCardRefs = gModelSorceryCard:GetSorceryCardRefByTheme(_race)
    local qualityList = {}
    for i, v in ipairs(sorceryCardRefs) do
        local quality = v.quality
        local list = qualityList[quality] or {}
        table.insert(list, v)
        qualityList[quality] = list
    end
    local list = {}
    for i, v in pairs(qualityList) do
        table.insert(list, { quality = i, list = v })
    end
    table.sort(list, function(a, b)
        return a.quality > b.quality
    end)
    for i, v in ipairs(list) do
        table.sort(v, function(a, b)
            return a.refId < b.refId
        end)
    end
    for i, v in ipairs(list) do
        local quality = v.quality
        local cardList = v.list
        local qualityRef = gModelItem:GetQualityRef(quality)
        local titleName = ccLngText(qualityRef.heroQualityName)
        table.insert(itemList, {
            type = 1,
            titleName = titleName
        })
        local _cardList = {}
        for j, k in ipairs(cardList) do
            local times = math.ceil(j / 3)
            local _list = _cardList[times] or {}
            table.insert(_list, k)
            _cardList[times] = _list
        end
        local wIndex = 1
        while (true)
        do
            local cList = _cardList[wIndex]
            if not cList then
                break
            end
            table.insert(itemList, { type = 2, list = cList })
            wIndex = wIndex + 1
        end
    end
    self._raceItemList[_race] = itemList
    return itemList
end

function UISubSorceryCardBook:RefreshTypeShow()
    local filterOptions = gModelSorceryCard:GetFilterOptions()
    local filterOptionsStr = gModelSorceryCard:GetSorceryCardConfigRefByKey("filterOptions")
    local filterOptionsArr = string.split(filterOptionsStr, "|")
    for i, v in ipairs(filterOptionsArr) do
        local arr = string.split(v, "=")
        if filterOptions == tonumber(arr[1]) then
            self:SetWndText(self.mTypeText, arr[2])
            return
        end
    end
end

function UISubSorceryCardBook:OnClickTypeItem(type)
    gModelSorceryCard:SetFilterOptions(type)
    self:OnClickTypeMask()
    self._isMoveTab = true
    self._isUp = true
    self:RefreshTypeShow()
    self._themeUiList:DrawAllItems()
    self:RefreshData()
    GF.ShowMessage(ccClientText(29569))
end

function UISubSorceryCardBook:OnClickRace(race)
    self._isMoveTab = true
    self._race = race

    if self._selTranList then
        for k, v in pairs(self._selTranList) do
            CS.ShowObject(k, v == race)
        end
    end

    self:RefreshData()
end

function UISubSorceryCardBook:OnClickType()
    local isShowType = self._isShowType
    if isShowType then
        self:OnClickTypeMask()
        return
    end
    self._isShowType = true
    CS.ShowObject(self.mTypeMask, true)
    CS.ShowObject(self.mTypeListBg, true)
    local typeUiList = self._typeUiList
    local list = {}
    local filterOptionsStr = gModelSorceryCard:GetSorceryCardConfigRefByKey("filterOptions")
    local filterOptionsArr = string.split(filterOptionsStr, "|")
    for i, v in ipairs(filterOptionsArr) do
        local arr = string.split(v, "=")
        table.insert(list, { type = tonumber(arr[1]), title = arr[2] })
    end
    if typeUiList then
        typeUiList:RefreshList(list)
        typeUiList:DrawAllItems()
    else
        typeUiList = self:GetUIScroll("mTypeSuper")
        self._typeUiList = typeUiList
        typeUiList:Create(self.mTypeSuper, list, function(...)
            self:TypeListItem(...)
        end, UIItemList.SUPER)
    end
end

------------------------------------------------------------------
return UISubSorceryCardBook