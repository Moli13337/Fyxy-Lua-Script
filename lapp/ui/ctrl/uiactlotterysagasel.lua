---
--- Created by BY.
--- DateTime: 2023/10/21 16:46:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActLotterySagaSel:LWnd
local UIActLotterySagaSel = LxWndClass("UIActLotterySagaSel", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActLotterySagaSel:UIActLotterySagaSel()
    self._raceList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActLotterySagaSel:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActLotterySagaSel:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActLotterySagaSel:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
end

function UIActLotterySagaSel:OnTryTcpReconnect()
    self:WndClose()
end

function UIActLotterySagaSel:RefreshDragonShow(itemdata, isItemSet)
    if not isItemSet then
        CS.ShowObject(self.mAdd, true)
        CS.ShowObject(self.mDragonImg, false)
        return
    end
    CS.ShowObject(self.mAdd, false)
    CS.ShowObject(self.mDragonImg, true)

    local refId = itemdata.itemId
    local itemRef = gModelItem:GetRefByRefId(refId)
    local dragonRefId
    if itemRef.type == ModelItem.TTEM_TYPE_DRACONIC_ITEM then
        dragonRefId = itemRef.refId
    elseif itemRef.type == ModelItem.TTEM_TYPE_DRACONIC then
        dragonRefId = checknumber(itemRef.typeDate)
    end

    local param = {
        refId    = dragonRefId,
        showType = true,
    }

    gModelDraconic:DrawCard(self, self.mDragonImg, param)
    CS.ShowObject(self.mDragonImg,true)

    local itemData = {
        isEmpty = true,
        itemId = itemdata.itemId, -- 拿下refId 就可以了
        itemNum = -1,
        itemType = 1
    }
    self:SetWndClick(self.mDragonImg, function()
        gModelGeneral:ShowCommonItemTipWnd(itemData)
    end)

end

function UIActLotterySagaSel:ListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local heroRoot = self:FindWndTrans(root, "HeroRoot")
    local selImg = self:FindWndTrans(root, "SelImg")
    local selimgText = self:FindWndTrans(selImg, "Image/UIText")
    local LimitBg = self:FindWndTrans(root,"LimitBg")
    local selItemdata = self._itemdata
    local selEntryId = selItemdata and selItemdata.entryId or self._selEntryId

    local entryId = itemdata.entryId
    local heroDatas = LxDataHelper.SevenParseItems(itemdata.items)

    CS.ShowObject(selImg, entryId == selEntryId)

    --self._entryExtraShowMap
    local entryExtraShowMap = self._entryExtraShowMap
    local entryExtraShowInfo = entryExtraShowMap and entryExtraShowMap[entryId]
    if entryExtraShowInfo then
        self:SetWndEasyImage(LimitBg,entryExtraShowInfo.spBg,function()
            CS.ShowObject(LimitBg,true)
        end)
        local LimitTxt = self:FindWndTrans(LimitBg,"LimitTxt")
        self:SetWndText(LimitTxt,entryExtraShowInfo.spTxt)
    else
        CS.ShowObject(LimitBg,false)
    end

    if entryId == selEntryId then
        self:RefreshHeroShow(heroDatas, true)
    end
    self:CreateCommonIconImpl(heroRoot, heroDatas[1], { noClick = true })

    self:SetWndText(selimgText, ccClientText(44807))

    self:SetWndClick(item, function()
        self:OnClickItem(itemdata)
    end)
    self:SetWndLongClick(item, function()
        gModelGeneral:OpenHeroStarPre({ refId = heroDatas[1].itemId })
    end, 0.5, false)
end

function UIActLotterySagaSel:GetPetList()

    local entry = self._entry
    if not entry then
        return {}
    end
    local list = self._petList
    if not list then
        list = {}
        for i, v in ipairs(entry) do
            local item = v.items[1]
            local type = item.type
            if type == 1 then
                table.insert(list, v)
            end
        end
        self._petList = list
    end
    return list
end

function UIActLotterySagaSel:RefreshPetInfo()
    local petList = self:GetPetList()
    local selItemdata = self._itemdata

    local len = #petList
    if len <= 0 then
        self:CreateEmptyShow(10009)
    end

    local uiList = self._uiList
    if uiList then
        uiList:RefreshList(petList)
    else
        uiList = self:GetUIScroll("mItemList")
        self._uiList = uiList
        uiList:Create(self.mItemList, petList, function(...)
            self:ListPetItem(...)
        end, UIItemList.WRAP)
    end

    local isSelect = false

    if not selItemdata then
    else
        isSelect = selItemdata.entryId > 0
    end

    local showTipsStr
    if not self._config then
        showTipsStr = self._selEntryId > 0 and ccClientText(44805) or ccClientText(44806)
    else
        showTipsStr = self._selEntryId > 0 and ccLngText(self._config.switchText2) or ccLngText(self._config.switchText1)
    end
    self:SetWndText(self.mShowHeroTips, showTipsStr)
end

function UIActLotterySagaSel:OnClickItem(itemdata)
    self._itemdata = itemdata
    self:RefreshHero()
end

function UIActLotterySagaSel:GetHeroList()
    --只获取是英雄的
    local entry = self._entry
    if not entry then
        return {}
    end
    local list = self._heroList
    if not list then
        list = {}
        for i, v in ipairs(entry) do
            local item = v.items[1]
            local type = item.type
            if type == 2 then
                table.insert(list, v)
            end
        end
        self._heroList = list
    end
    return list
end
function UIActLotterySagaSel:OnClickRace(type)
    local oldType = self._type
    local _raceList = self._raceList or {}
    if oldType then
        if oldType == type then
            return
        end
        CS.ShowObject(_raceList[oldType], false)
    end
    self._type = type
    CS.ShowObject(_raceList[type], true)
    self._isSort = false
    self:RefreshHero()
end

function UIActLotterySagaSel:RefreshPetShow(itemdata, isItemSet)
    if not isItemSet then
        CS.ShowObject(self.mAdd, true)
        CS.ShowObject(self.mPetSpinePos, false)
        return
    end
    CS.ShowObject(self.mAdd, false)
    CS.ShowObject(self.mPetSpinePos, true)
    local refId = itemdata.itemId
    local itemRef = gModelItem:GetRefByRefId(refId)

    local petRefId = string.split(itemRef.typeDate, ",")
    petRefId = checknumber(petRefId[1])
    local petCfg = GameTable.MagicPetRef[petRefId]

    local prefabName = petCfg.spine

    if prefabName then

        --创建对应的英雄部分
        local oldHeroPrefab = self._oldHeroPrefab
        if oldHeroPrefab and oldHeroPrefab ~= prefabName then
            self:DestroyWndSpineByKey("heroSpinePos")
        end

        self:CreateWndSpine(self.mPetSpinePos, prefabName, "heroSpinePos", false)

        self._oldHeroPrefab = prefabName
    end

    local itemData = {
        isEmpty = true,
        itemId = refId, -- 拿下refId 就可以了
        itemNum = -1,
        itemType = 1,
    }

    self:SetWndClick(self.mPetClickArea, function()
        gModelGeneral:ShowCommonItemTipWnd(itemData)
    end)
end

--endregion --------------------------------------------------------------------------------------


--region 设置宠物的部分 --------------------------------------------------------------------------------
function UIActLotterySagaSel:SetPetInfo()
    self:RefreshPetInfo()
end


--endregion --------------------------------------------------------------------------------------

--region 设置龙纹 --------------------------------------------------------------------------------
function UIActLotterySagaSel:SetDragonInfo()
    self:RefreshDragonInfo()
end
function UIActLotterySagaSel:InitMessage()
    --self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
    --    --self:OnActivityPageResp(...)
    --end)
    self:WndNetMsgRecv(LProtoIds.ActivitySelectDropGiftResp, function(...)
        self:WndClose()
    end)
end

--region 英雄部分 --------------------------------------------------------------------------------

function UIActLotterySagaSel:SetHeroInfo()
    local showTipsStr
    if not self._config then
        showTipsStr = self._selEntryId > 0 and ccClientText(44805) or ccClientText(44806)
    else
        showTipsStr = self._selEntryId > 0 and ccLngText(self._config.switchText2) or ccLngText(self._config.switchText1)
    end
    self:SetWndText(self.mShowHeroTips, showTipsStr)

    local list = gModelHero:GetHeroRaceRefSortByRank()
    CS.ShowObject(self.mRaceDiv, true)
    CS.ShowObject(self.mRaceBg, true)
    local _uiRaceList = self:GetUIScroll("mRaceScroll")
    _uiRaceList:Create(self.mRaceScroll, list, function(...)
        self:RaceListItem(...)
    end)
    self:OnClickRace(list[1].refId)
end
function UIActLotterySagaSel:InitCommand()
    CS.ShowObject(self.mNoRecord3,false)

    self:SetWndText(self.mLblBiaoti, ccClientText(11635))
    self:SetWndText(self.mDesText, ccClientText(13266))
    self:SetWndButtonText(self.mBtnCancel, ccClientText(10101))
    self:SetWndButtonText(self.mBtnEnter, ccClientText(10102))

    local sid = self:GetWndArg("sid")
    local entry = self:GetWndArg("entry")
    local selEntryId = self:GetWndArg("selEntryId")
    self._config = self:GetWndArg("config")
    self._templateType = self:GetWndArg("templateType") or 0
    self._canAwardReplace = self:GetWndArg("canAwardReplace") or false

    self._entryExtraShowMap = self:GetWndArg("entryExtraShowMap") or {}

    if not self._canAwardReplace then
        self:SetWndText(self.mAwardReplaceTxt,self:GetWndArg("awardReplaceTxt"))
    end

    self._sid = sid
    self._entry = entry
    self._selEntryId = selEntryId or 0

    if self._templateType == 0 then
        self:SetHeroInfo()
    elseif self._templateType == 1 then
        self:SetPetInfo()
    elseif self._templateType == 2 then
        --设置龙纹
        self:SetDragonInfo()
    end
end

function UIActLotterySagaSel:OnClickDragonItem(itemdata)
    self._itemdata = itemdata
    self:RefreshDragonInfo()
end

function UIActLotterySagaSel:RefreshHeroShow(heroDatas, isItemSet)
    if not isItemSet then
        CS.ShowObject(self.mAdd, true)
        CS.ShowObject(self.mHeroRoot, false)
        return
    end
    CS.ShowObject(self.mAdd, false)
    CS.ShowObject(self.mHeroRoot, true)

    --解析对应的英雄数据
    local heroRefId = heroDatas[1].itemId
    local effRef = gModelHero:GetHeroEffectRef(heroRefId)
    local prefabName = effRef.prefabName

    --创建对应的英雄部分
    local oldHeroPrefab = self._oldHeroPrefab
    if oldHeroPrefab and oldHeroPrefab ~= prefabName then
        self:DestroyWndSpineByKey("heroSpinePos")
    end

    self:CreateWndSpine(self.mHeroSpinePos, prefabName, "heroSpinePos", false)

    self._oldHeroPrefab = prefabName

    local itemData = {
        isEmpty = true,
        itemId = heroRefId, -- 拿下refId 就可以了
        itemNum = -1,
        itemType = LItemTypeConst.TYPE_HERO,
    }

    self:SetWndClick(self.mHeroSpinePos, function()
        gModelGeneral:ShowCommonItemTipWnd(itemData)
    end)
end
function UIActLotterySagaSel:OnClickEnter()
    local itemdata = self._itemdata
    local _selEntryId = self._selEntryId
    if not itemdata and _selEntryId <= 0 then
        GF.ShowMessage(ccClientText(11646))
    elseif not itemdata and _selEntryId > 0 then
        self:WndClose()
    else
        gModelActivity:OnActivitySelectDropGiftReq(self._sid, itemdata.pageId, itemdata.entryId)
    end
end
function UIActLotterySagaSel:RaceListItem(list, item, itemdata, itempos)
    local image = self:FindWndTrans(item, "Icon")
    local selImg = self:FindWndTrans(item, "SelImg")

    self._raceList[itemdata.refId] = selImg
    self:SetWndEasyImage(image, itemdata.icon)
    self:SetWndClick(item, function(...)
        self:OnClickRace(itemdata.refId)
    end)
end

function UIActLotterySagaSel:RefreshHero()
    local heroRace = self._type or 0
    local selItemdata = self._itemdata
    local list = self._list
    if not self._isSort then
        self._isSort = true
        list = {}
        local heroList = self:GetHeroList()
        for i, v in ipairs(heroList) do
            local item = v.items[1]
            local itemId = item.itemId
            local heroRef = gModelHero:GetHeroRef(itemId)
            if heroRef then
                if heroRace == 0 or heroRace == heroRef.raceType then
                    table.insert(list, v)
                end
            end
        end
        local selEntryId = selItemdata and selItemdata.entryId or self._selEntryId
        if selEntryId > 0 then
            table.sort(list, function(a, b)
                local aid = a.entryId
                local bid = b.entryId
                local aisSel = aid == selEntryId and 1 or 0
                local bisSel = bid == selEntryId and 1 or 0
                if aisSel ~= bisSel then
                    return aisSel > bisSel
                end
                return aid < bid
            end)
        end

        self._list = list

    end

    local len = #list
    CS.ShowObject(self.mNoRecord3, len <= 0)
    if len <= 0 then
        self:CreateEmptyShow(10009)
    end

    local uiList = self._uiList
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("mItemList")
        self._uiList = uiList
        uiList:Create(self.mItemList, list, function(...)
            self:ListItem(...)
        end, UIItemList.WRAP)
    end

    local isSelect = false

    if not selItemdata then
    else
        isSelect = selItemdata.entryId > 0
    end

    local showTipsStr
    if not self._config then
        showTipsStr = self._selEntryId > 0 and ccClientText(44805) or ccClientText(44806)
    else
        showTipsStr = self._selEntryId > 0 and ccLngText(self._config.switchText2) or ccLngText(self._config.switchText1)
    end

    self:SetWndText(self.mShowHeroTips, showTipsStr)
end

function UIActLotterySagaSel:OnClickPetItem(itemdata)
    self._itemdata = itemdata
    self:RefreshPetInfo()
end

function UIActLotterySagaSel:ListPetItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local itemRoot = self:FindWndTrans(root, "HeroRoot")
    local selImg = self:FindWndTrans(root, "SelImg")
    local selimgText = self:FindWndTrans(selImg, "Image/UIText")
    local selItemdata = self._itemdata
    local selEntryId = selItemdata and selItemdata.entryId or self._selEntryId

    local entryId = itemdata.entryId
    local itemDatas = LxDataHelper.SevenParseItems(itemdata.items)

    self:SetWndText(selimgText, ccClientText(44807))

    --设置道具
    local InstanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(itemRoot)
    baseClass:SetCommonReward(itemDatas[1].itemType, itemDatas[1].itemId, itemDatas[1].itemNum)
    baseClass:DoApply()

    self:SetWndLongClick(item, function()
        local itemdata = itemDatas[1]
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end, 0.5, false)

    --普通的点击部分
    self:SetWndClick(item, function()
        self:OnClickPetItem(itemdata)
    end)

    CS.ShowObject(selImg, entryId == selEntryId)
    --
    if entryId == selEntryId then
        self:RefreshPetShow(itemDatas[1], true)
    end

end


--endregion --------------------------------------------------------------------------------------

function UIActLotterySagaSel:CreateEmptyShow(refId)
    local data = {
        refId = refId,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty1")
    emptyList:RefreshUI(data)
end

function UIActLotterySagaSel:GetDragonList()

    local entry = self._entry
    if not entry then
        return {}
    end
    local list = self._dragonList
    if not list then
        list = {}
        for i, v in ipairs(entry) do
            local item = v.items[1]
            local type = item.type
            if type == 1 then
                table.insert(list, v)
            end
        end
        self._dragonList = list
    end
    return list
end

function UIActLotterySagaSel:RefreshDragonInfo()
    local dragonList = self:GetDragonList()
    local selItemdata = self._itemdata

    local len = #dragonList
    if len <= 0 then
        self:CreateEmptyShow(10009)
    end

    local uiList = self._uiList
    if uiList then
        uiList:RefreshList(dragonList)
    else
        uiList = self:GetUIScroll("mItemList")
        self._uiList = uiList
        uiList:Create(self.mItemList, dragonList, function(...)
            self:ListDragonItem(...)
        end, UIItemList.WRAP)
    end

    local isSelect = false

    if not selItemdata then
    else
        isSelect = selItemdata.entryId > 0
    end

    local showTipsStr
    if not self._config then
        showTipsStr = self._selEntryId > 0 and ccClientText(44805) or ccClientText(44806)
    else
        showTipsStr = self._selEntryId > 0 and ccLngText(self._config.switchText2) or ccLngText(self._config.switchText1)
    end
    self:SetWndText(self.mShowHeroTips, showTipsStr)
end

function UIActLotterySagaSel:ListDragonItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local itemRoot = self:FindWndTrans(root, "HeroRoot")
    local selImg = self:FindWndTrans(root, "SelImg")
    local selimgText = self:FindWndTrans(selImg, "Image/UIText")
    local selItemdata = self._itemdata
    local selEntryId = selItemdata and selItemdata.entryId or self._selEntryId

    local entryId = itemdata.entryId
    local itemDatas = LxDataHelper.SevenParseItems(itemdata.items)

    self:SetWndText(selimgText, ccClientText(44807))

    --设置道具
    local InstanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(InstanceID)
    baseClass:Create(itemRoot)
    baseClass:SetCommonReward(itemDatas[1].itemType, itemDatas[1].itemId, itemDatas[1].itemNum)
    baseClass:DoApply()

    self:SetWndLongClick(item, function()
        local itemdata = itemDatas[1]
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end, 0.5, false)

    --普通的点击部分
    self:SetWndClick(item, function()
        self:OnClickDragonItem(itemdata)
    end)

    CS.ShowObject(selImg, entryId == selEntryId)
    --
    if entryId == selEntryId then
        self:RefreshDragonShow(itemDatas[1], true)
    end


end
function UIActLotterySagaSel:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnClose, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnCancel, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnEnter, function()
        self:OnClickEnter()
    end)
end

------------------------------------------------------------------
return UIActLotterySagaSel


