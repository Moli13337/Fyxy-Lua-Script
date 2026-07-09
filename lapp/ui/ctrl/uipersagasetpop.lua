---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPerSagaSetPop:LWnd
local UIPerSagaSetPop = LxWndClass("UIPerSagaSetPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPerSagaSetPop:UIPerSagaSetPop()
    ---@type table<number,CommonIcon>
    self._uiHeroIconClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPerSagaSetPop:OnWndClose()
    self:CleanDragList()
    self:ClearCommonIconList(self._uiHeroIconClsList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPerSagaSetPop:OnCreate()
    LWnd.OnCreate(self)

    self._typeBtnList = {}
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPerSagaSetPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    
    self:InitEmptyList()
    self:InitEvent()
    self:InitCommand()
    self:InitDragList()

    --self:InitRaceTypeList()
end

function UIPerSagaSetPop:InitDragList()
    self._dragItemList = { self.mHeroRoot1, self.mHeroRoot2, self.mHeroRoot3, self.mHeroRoot4, self.mHeroRoot5, self.mHeroRoot6 }
    self._dragItemDataList = {}
    self._dragOriginPos = {}
    self._dragIndexList = {}
    for k, v in ipairs(self._dragItemList) do
        table.insert(self._dragIndexList, k)

        local dragKey = "_dragItem_" .. k

        local vector3List = v:GetLocalCorners()
        local vecMin = vector3List[0]
        local vecMax = vector3List[2]

        local minX = vecMin.x
        local minY = vecMin.y
        local maxX = vecMax.x
        local maxY = vecMax.y
        local centerX = (vecMax.x + vecMin.x) / 2
        local centerY = (vecMax.y + vecMin.y) / 2

        local width = vecMax.x - vecMin.x
        local height = vecMax.y - vecMin.y
        local midW = width / 2
        local midH = height / 2

        self._dragItemDataList[dragKey] = {
            key = dragKey,
            keyIndex = k,
            index = k,
            item = v,
            minX = minX,
            minY = minY,
            maxX = maxX,
            maxY = maxY,
            centerX = centerX,
            centerY = centerY,
            width = width,
            height = height,
            midW = midW,
            midH = midH,
        }
        table.insert(self._dragOriginPos, v.localPosition)
        self:InternalUIDragSetItem(dragKey, v, CS.YXUIDrag.DragMode.DragNothing)
    end

    local len = #self._dragOriginPos
    local top = self._dragOriginPos[1]
    local bottom = self._dragOriginPos[len]
    local itemTopData = self._dragItemDataList["_dragItem_1"]
    local itemBottomData = self._dragItemDataList["_dragItem_" .. len]

    self._dragOriginLimitMinX = top.x + itemTopData.minX
    self._dragOriginLimitMaxX = bottom.x + itemBottomData.maxX

end

function UIPerSagaSetPop:SetFormation()
    --设置阵型
    local list = self._heros
    if not list then
        return
    end
    local formations = {}
    for i, v in ipairs(list) do
        if (v.id) then
            local girld = {
                id = v.id,
                grid = i
            }
            table.insert(formations, girld)
        end
    end
    local formationData = {
        formationType = LCombatTypeConst.COMBAT_SHOW_BATTLE,
        grids = formations,
        formationRefId = 1,
        formationSetType = 1,
        treasureSkilIds = {}
    }
    gModelFormation:OnSetFormationList(formationData)
    self:OnClickColoseWnd()
    self:WndClose()
end

--region 构建英雄race type --------------------------------------------------------------------------------
function UIPerSagaSetPop:InitRaceTypeList()
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
            --self._raceType = raceType
            --self:RefreshBtnEvent()
        end,
        checkSelFunc = function(raceType)
            if not self:IsWndValid() then
                return
            end
            --return self._raceType == raceType
        end,
    }
    self:GetUIHeroRaceList(data)
end

function UIPerSagaSetPop:TypeChange(trans, bool)
    local selImg = CS.FindTrans(trans, "SelImg")
    CS.ShowObject(selImg, bool)
end

function UIPerSagaSetPop:OnClickAddHeroIcon(id)
    --点击下面列表
    local _heroList = self._heros
    for i, v in ipairs(_heroList) do
        if v and v.id == id then
            self:OnDestroyHeroIcon(id)
            return
        end
    end
    local list = gModelHero:GetHeroList()
    local hero = list[id]
    local len = 0
    local nilIndex = 0
    for i = 1, #_heroList do
        if (_heroList[i].id) then
            len = len + 1
        elseif nilIndex == 0 then
            nilIndex = i
        end
    end
    if (len < 6) then
        local data = {
            id = hero._id,
            refId = hero._refId,
            star = hero._star,
            lv = hero._level,
            isResonance = hero._isResonance,
            skin = hero._skin,
            treeInfo = hero._treeInfo,
            name = hero.name
        }
        self._heros[nilIndex] = data
    else
        GF.ShowMessage(ccClientText(11529))
        return
    end
    self:UpdateShowHeroList()
end

function UIPerSagaSetPop:InitCommand()
    self.combatHeroData = self:GetWndArg("combatHeroData")

    gModelHero:SetHeroListChange()
    self._heroItemList = { self.mHeroRoot1, self.mHeroRoot2, self.mHeroRoot3, self.mHeroRoot4, self.mHeroRoot5, self.mHeroRoot6 }
    local heros = self.combatHeroData._heros
    local grids = self.combatHeroData._grids
    local _heros = {}
    local list = {}
    for i, v in ipairs(heros) do
        local pos = grids[i]
        _heros[pos] = v
    end
    for i = 1, 6 do
        local hero = _heros[i] or {}
        table.insert(list, hero)
    end
    self._heros = list

    self._callFun = self:GetWndArg("callFun")

    self:SetWndText(self.mNameXUITextObj, ccClientText(11513))
    self:SetWndText(self.mCloseTipObj, ccClientText(11530))

    local list = gModelHero:GetHeroRaceRefSortByRank()
    if (self._uiTypeList) then
        self._uiTypeList:RefreshData(list)
    else
        self._uiTypeList = self:GetUIScroll("typeList")
        self._uiTypeList:Create(self.mRaceListObj, list, function(...)
            self:SetTypeListItem(...)
        end)
    end
    self:UpdateShowHeroList()
end

function UIPerSagaSetPop:CheckDragItemSwap(curData, curPos)
    if false then
        return
    end
    local curIndexPos = self._dragOriginPos[curData.index]
    local curOriginPosX = curIndexPos.x + curData.centerX
    local centerX = curData.centerX + curPos.x
    local swapIndex = nil
    local bMoveUp = true
    for k, v in pairs(self._dragIndexList) do
        if k ~= curData.index then
            local originPos = self._dragOriginPos[k]
            local dragKey = "_dragItem_" .. v
            local dragItemData = self._dragItemDataList[dragKey]
            local itemcenterX = dragItemData.centerX + originPos.x
            local itemmidW = dragItemData.midW
            local odis = centerX - itemcenterX
            local dis = odis
            if dis < 0 then
                dis = -dis
            end
            if dis < itemmidW then
                bMoveUp = curOriginPosX < itemcenterX
                swapIndex = k
                break
            end
        end
    end
    if not swapIndex then
        return
    end

    local min = bMoveUp and (curData.index + 1) or (curData.index - 1)
    local max = bMoveUp and swapIndex or swapIndex

    local delta = bMoveUp and -1 or 1

    for k = min, max, -delta do
        local keyIndex = self._dragIndexList[k]
        local dragKey = "_dragItem_" .. keyIndex
        local dragItemData = self._dragItemDataList[dragKey]
        local newIndex = k + delta
        local oldIndex = dragItemData.index
        dragItemData.index = newIndex
        local item = dragItemData.item
        local tween = dragItemData.tween
        if tween then
            tween:Kill(false)
        end
        local originPos = self._dragOriginPos[newIndex]
        tween = item:DOLocalMoveX(originPos.x, 0.2)
        tween:OnComplete(function()
            local dragItemData = self._dragItemDataList[dragKey]
            if dragItemData then
                dragItemData.tween = nil
            end
        end)
        dragItemData.tween = tween
        tween:PlayForward()
        self:OnSwap(oldIndex, newIndex)
    end
    table.remove(self._dragIndexList, curData.index)
    curData.index = swapIndex
    table.insert(self._dragIndexList, swapIndex, curData.keyIndex)
end

function UIPerSagaSetPop:SetCommListItem(list, item, itemdata, itempos)
    --英雄列表
    local heroTrans = CS.FindTrans(item, "AniRoot/HeroIcon")
    local _heroList = self._heros
    local heroData = {
        index = itemdata.index,
        id = itemdata._id,
        refId = itemdata._refId,
        star = itemdata._star,
        level = itemdata._level,
        isResonance = itemdata._isResonance,
        skin = itemdata._skin,
        treeInfo = itemdata._treeInfo
    }

    self:SetWndClick(heroTrans, function(...)
        self:OnClickAddHeroIcon(itemdata._id)
    end)

    local bGou = false
    for i = 1, #_heroList do
        if (_heroList[i].id == heroData.id) then
            bGou = true
            break
        end
    end

    local InstanceID = item:GetInstanceID()
    local uiHeroIconClsList = self._uiHeroIconClsList
    local baseClass = uiHeroIconClsList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New(self)
        uiHeroIconClsList[InstanceID] = baseClass
        baseClass:Create(heroTrans)
        self:SetIconClickScale(heroTrans, true)
    end
    baseClass:SetHeroDataSet(heroData)
    baseClass:SetShowGouImg(bGou)
    baseClass:DoApply()
end

function UIPerSagaSetPop:OnDestroyHeroIcon(id)
    local list = self._heros
    for i = 1, #list do
        if (list[i].id == id) then
            list[i] = {}
        end
    end
    local _heros = {}

    for i, v in pairs(list) do
        table.insert(_heros, v)
    end
    self._heros = _heros
    self:UpdateShowHeroList()
end

function UIPerSagaSetPop:UIDragOnEnd(dragKey, eventData)
    if self._dragItemData and self._dragItemData.key == dragKey then
        local dragItemData = self._dragItemData
        local item = dragItemData.item
        local tween = dragItemData.tween
        if tween then
            tween:Kill(false)
        end
        local originPos = self._dragOriginPos[dragItemData.index]
        tween = item:DOLocalMoveX(originPos.x, 0.15)
        tween:OnComplete(function()
            local dragItemData = self._dragItemDataList[dragKey]
            if dragItemData then
                dragItemData.tween = nil
            end
        end)
        dragItemData.tween = tween
        tween:PlayForward()
    end
    self._dragItemData = nil
end

function UIPerSagaSetPop:UpdateShowHeroList()
    local _heroItemList = self._heroItemList
    local list = self._heros
    for i, v in ipairs(list) do
        self:SetHeroIconListItem(nil, _heroItemList[i], {}, i)
    end
    for i, v in ipairs(list) do

        self:SetHeroIconListItem(nil, _heroItemList[i], v, i)
    end
    --if(self._uiHeroIconList)then
    --	self._uiHeroIconList:RefreshList(list)
    --else
    --	self._uiHeroIconList = self:GetUIScroll("heroList")
    --	self._uiHeroIconList:Create(self.mHeroScrollObj,list,function (...) self:SetHeroIconListItem(...) end)
    --end
    local type = self._oldType and self._oldType or 0
    self:OnClickBtnTypeBtn(type)
end

function UIPerSagaSetPop:CleanDragList()
    for k, v in pairs(self._dragItemDataList or {}) do
        v.item = nil
        if v.tween then
            v.tween:Kill(false)
            v.tween = nil
        end
    end
end

function UIPerSagaSetPop:OnClickColoseWnd()
    --回调
    local callFun = self._callFun
    if callFun ~= nil then
        callFun()
    end
end

function UIPerSagaSetPop:OnClickBtnTypeBtn(type)
    --点击类型按钮
    local isRefresh = false
    if (self._oldType) then
        local oldTrans = self._typeBtnList[self._oldType]
        self:TypeChange(oldTrans, false)
        isRefresh = self._oldType ~= type
    end
    local trans = self._typeBtnList[type]
    self:TypeChange(trans, true)
    self._oldType = type

    local list = gModelHero:GetHeroSortList()
    local itemList = {}
    local j = 1
    for i, v in pairs(list) do
        local race = gModelHero:GetHeroType(v._refId)
        if (race == type or type == 0) then
            itemList[j] = v
            itemList[j].type = "Hero"
            itemList[j].rank = gModelHero:GetHeroRaceRefRank(race)
            j = j + 1
        end
    end

    if type == 0 then
        table.sort(itemList, function(a, b)
            -- if a.rank ~= b.rank then
            --     return a.rank < b.rank
            -- else
            --     return a._star> b._star
            -- end
            if a.level ~= b.level then
                return a._constLevel > b._constLevel
            else
                return a._fightPower> b._fightPower
            end
        end)
    end

    if (self._uiCommList) then
        if (isRefresh) then
            self._uiCommList:RefreshList(itemList)
            --self._uiCommList:RefreshSimpleList(itemList)
        else
            self._uiCommList:RefreshData(itemList)
        end
    else
        self._uiCommList = self:GetUIScroll("commList")
        self._uiCommList:Create(self.mHeroSetListScrollObj, itemList, function(...)
            self:SetCommListItem(...)
        end, UIItemList.WRAP)
    end

    local isEmpty = #itemList < 1
    CS.ShowObject(self.mNoRecord2, isEmpty)
end

function UIPerSagaSetPop:UIDragOnBegin(dragKey, eventData)
    self._dragItemData = nil

    local itemData = self._dragItemDataList[dragKey]
    --if self:IsItemLock(itemData.index) then
    --	return
    --end

    local item = itemData.item
    self._dragItemData = itemData
    item:SetAsLastSibling()
    local camera = eventData.pressEventCamera
    local pos = camera:ScreenToWorldPoint(eventData.position)
    pos = item.parent:InverseTransformPoint(pos)
    self._dragOffsetPosX = item.localPosition.x - pos.x
end

function UIPerSagaSetPop:InitEvent()
    self:SetWndClick(self.mBgImageObj, function(...)
        self:SetFormation()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose, function(...)
        self:SetFormation()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIPerSagaSetPop:OnClickShowHeroIcon(id)
    --点击上面头像
    self:OnDestroyHeroIcon(id)
end

function UIPerSagaSetPop:OnSwap(oldIndex, newIndex)
    local _heroItemList = self._heroItemList
    local oldItem = _heroItemList[oldIndex]
    local newItem = _heroItemList[newIndex]
    _heroItemList[oldIndex] = newItem
    _heroItemList[newIndex] = oldItem
    self._heroItemList = _heroItemList

    local _heros = self._heros
    local oldHero = _heros[oldIndex]
    local newHero = _heros[newIndex]
    _heros[oldIndex] = newHero
    _heros[newIndex] = oldHero
    self._heros = _heros
    --printErrorN("swap ..old index="..oldIndex..", new index="..newIndex)
end

function UIPerSagaSetPop:SetTypeListItem(list, item, itemdata, itempos)
    --类型按钮
    local imageTran = CS.FindTrans(item, "Icon")
    local selectTran = CS.FindTrans(item, "SelImg")
    CS.ShowObject(selectTran, false)
    self:SetWndEasyImage(imageTran, itemdata.icon)
    self._typeBtnList[itemdata.refId] = item
    self:SetWndClick(item, function(...)
        self:OnClickBtnTypeBtn(itemdata.refId)
    end)
end

function UIPerSagaSetPop:InitEmptyList()
    local data = {
        refId = 10008,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UIPerSagaSetPop:SetHeroIconListItem(list, item, itemdata, itempos)
    --展示英雄
    local rootTrans = self:FindWndTrans(item, "Root")
    local heroTrans = CS.FindTrans(rootTrans, "HeroIcon")
    local nameText = CS.FindTrans(item, "NameXUIText")
    local addTrans = CS.FindTrans(item, "BtnAdd")
    self:SetWndClick(addTrans, function(...)
        GF.ShowMessage(ccClientText(11527))
    end)
    if (not itemdata.id) then
        CS.ShowObject(heroTrans, false)
        CS.ShowObject(nameText, false)
        return
    end

    --if gLGameLanguage:IsForeignVersion() then
    --    self:SetAnchorPos(rootTrans, Vector2.New(0, 0))
    --end
    local isShowName = not gLGameLanguage:IsForeignRegion()
    CS.ShowObject(heroTrans, true)
    CS.ShowObject(nameText, isShowName)
    self:InitTextModeWithLanguage(nameText)

    local heroData = {
        index = itemdata.index,
        id = itemdata.id,
        refId = itemdata.refId,
        star = itemdata.star,
        level = itemdata.lv,
        isResonance = itemdata.isResonance,
        skin = itemdata.skin,
        treeInfo = itemdata.treeInfo,
        name = itemdata.name
    }
    self:SetWndClick(heroTrans, function(...)
        self:OnClickShowHeroIcon(itemdata.id)
    end)
    local color = gModelHero:GetHeroNameColor(heroData.id)
    --local name = gModelHero:GetHeroNameById(heroData.id)
    local name = gModelHeroExtra:GetHeroSetName(heroData,true)
    if not string.isempty(name) then
        if color then
            local uiText = LxUiHelper.FindXTextCtrl(nameText)
            --self:SetXUITextColor(uiText,color)
        end
        self:SetWndText(nameText, name)
    end

    local InstanceID = item:GetInstanceID()
    local uiHeroIconClsList = self._uiHeroIconClsList
    local baseClass = uiHeroIconClsList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New(self)
        uiHeroIconClsList[InstanceID] = baseClass
        baseClass:Create(heroTrans)
        self:SetIconClickScale(heroTrans, true)
    end
    baseClass:SetHeroDataSet(heroData)
    baseClass:DoApply()
end

function UIPerSagaSetPop:UIDragOnDrag(dragKey, eventData)
    if self._dragItemData and self._dragItemData.key == dragKey then
        local trans = self._dragItemData.item
        if not trans then
            return
        end
        local camera = eventData.pressEventCamera
        local pos = camera:ScreenToWorldPoint(eventData.position)
        pos = trans.parent:InverseTransformPoint(pos)
        pos.x = pos.x + self._dragOffsetPosX

        local min = pos.x + self._dragItemData.minX
        local max = self._dragItemData.maxX + pos.x

        if min < self._dragOriginLimitMinX then
            pos.x = self._dragOriginLimitMinX - self._dragItemData.minX
        elseif max > self._dragOriginLimitMaxX then
            pos.x = self._dragOriginLimitMaxX - self._dragItemData.maxX
        end

        local transPos = trans.localPosition
        local curPos = Vector3.New(pos.x, transPos.y, transPos.z)
        trans.localPosition = curPos
        self:CheckDragItemSwap(self._dragItemData, curPos)
    end
end

--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIPerSagaSetPop


