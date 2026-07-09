---
--- Created by Administrator.
--- DateTime: 2023/10/21 18:19:25
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISelFightTsure:LWnd
local UISelFightTsure = LxWndClass("UISelFightTsure", LWnd)

UISelFightTsure.NORMAL = 1
UISelFightTsure.MULTI = 2

UISelFightTsure.PASV = 3

UISelFightTsure.TYPE_ACTIVE_ALL = 4
UISelFightTsure.TYPE_PASV_ALL = 3

UISelFightTsure.TYPE_POS_1 = 1
UISelFightTsure.TYPE_POS_2 = 2
UISelFightTsure.TYPE_POS_3 = 3
UISelFightTsure.TYPE_POS_4 = 4
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISelFightTsure:UISelFightTsure()
    ---@type table<number,CommonIcon>
    self._uiCommonList = {}
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISelFightTsure:OnWndClose()
    self:ClearCommonIconList(self._uiCommonList)
    self._uiCommonList = nil
    self:CleanDragList()

    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISelFightTsure:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISelFightTsure:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    --self:InitEmptyList()
    self:InitText()
    self:InitEvent()
    self:InitData()
end

function UISelFightTsure:ChuShiEvent()
    if self._func then
        local list = table.clone(self._treaPosToId)
        self._func(list)
    end
    self:WndClose()
end

function UISelFightTsure:UIDragOnEnd(dragKey, eventData)
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

function UISelFightTsure:CheckDragItemSwap(curData, curPos)
    local curIndexPos = self._dragOriginPos[curData.index]
    local curOriginPosX = curIndexPos.x + curData.centerX
    local centerX = curData.centerX + curPos.x
    local swapIndex = nil
    local bMoveUp = true
    for k, v in pairs(self._dragIndexList) do
        if k ~= curData.index and self:IsItemOpen(k) then
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
                bMoveUp = curOriginPosX <= itemcenterX
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

function UISelFightTsure:SelSkillEvent(skillRefId)
    local isChange = false

    local treaPos = self._treaIdToPos[skillRefId]
    if treaPos then
        isChange = true
        self._treaPosToId[treaPos] = 0
        self._treaIdToPos[skillRefId] = nil
    else
        local isLock = false
        local emptyPos = nil
        local pos
        for k = 1, self._maxPos do
            isLock = not self:IsItemOpen(k)
            if not pos and isLock then
                pos = k
            end
            local skillRefId = self._treaPosToId[k]
            if skillRefId == 0 and not isLock then
                emptyPos = k
                break
            end
        end

        if emptyPos then
            local isOnOther = self:CheckOtherFormation(skillRefId)
            if not isOnOther then
                isChange = true
                self._treaPosToId[emptyPos] = skillRefId
                self._treaIdToPos[skillRefId] = emptyPos
            end
        else
            if isLock then
                -- GF.ShowMessage(ccClientText(41071))
                local needLev = gModelDraconic:GetSkillOpenLev(pos)
                GF.ShowMessage(ccClientText(41060, needLev))
            else
                GF.ShowMessage(ccClientText(41070))
            end
        end
    end

    if isChange then
        self:RefreshSkillContent()
    end
end

function UISelFightTsure:InitList()
    for i = 1, self._maxPos do
        local skillRefId = self._treaPosToId[i] or 0
        self:CreateSkillList(i, skillRefId)
    end

    local list = {}

    if self._isPasvWnd then
        list = gModelDraconic:GetActiveUpRefList()--gModelTreasure:GetPasvSkillList()
    else
        local combatType = self._combatType
        if combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
            --list = gModelDraconic:GetActiveUpRefList()--gModelTreasure:FormatFakeTreasure(self._targetId)

            list = gModelCareSchool:GetDraconicId(self._targetId)
        else
            list = gModelDraconic:GetActiveUpRefList()
        end
    end

    self:CreateTreasureList(list)
    local emptyList = #list <= 0
    CS.ShowObject(self.mNoRecord2, emptyList)
end

function UISelFightTsure:InitDragList()
    self._dragItemList = { self.mSkillItem1, self.mSkillItem2, self.mSkillItem3, self.mSkillItem4 }
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

    self._dragOriginLimitMinX = top.x - itemTopData.maxX
    self._dragOriginLimitMaxX = bottom.x + itemBottomData.maxX
end

function UISelFightTsure:IsItemOpen(index)
    local type = 1
    if self._isPasvWnd then
        type = 2
    end

    local design = nil
    if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
        design = self._allowPos[index]
        if design then
            return true
        else
            return false,ccClientText(20926)
        end
    end
    return gModelDraconic:IsSkillOpenByPos(index)
    -- return gModelTreasure:CheckTreaPosOpen(type,index,design)
end

function UISelFightTsure:InitEmptyList(refId)
    local data = {
        refId = refId, -- 18002,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UISelFightTsure:InitData()
    local treasureSkilIds = self:GetWndArg("treasureSkilIds") or {}
    self._targetId = self:GetWndArg("targetId")
    self._combatType = self:GetWndArg("combatType") or LCombatTypeConst.COMBAT_MAIN
    self._wndType = self:GetWndArg("wndType") or UISelFightTsure.NORMAL
    self._idRecord = self:GetWndArg("idRecord")
    self._func = self:GetWndArg("func")

    self._treaPosToId = {}
    self._treaIdToPos = {}

    local isPasvWnd = self._wndType == UISelFightTsure.PASV
    self._isPasvWnd = isPasvWnd

    self._maxPos = UISelFightTsure.TYPE_ACTIVE_ALL
    if isPasvWnd then
        self._maxPos = UISelFightTsure.TYPE_PASV_ALL
    end

    for i = 1, self._maxPos do
        local skillRefId = treasureSkilIds[i] or 0
        if skillRefId ~= 0 then
            self._treaIdToPos[skillRefId] = i
        end
        self._treaPosToId[i] = skillRefId
    end

    if not isPasvWnd then
        if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
            local ref = gModelCareSchool:GetCollegeLibraryCheckpointRefByRefId(self._targetId)
            local numList = LxDataHelper.ParseNumber_Sign(ref.treasurePos, ',')
            local record = {}
            for i, v in ipairs(numList) do
                record[v] = true
            end

            self._allowPos = record
        end
    end

    self._skillAllTransList = {
        [UISelFightTsure.TYPE_POS_1] = {
            root = self.mSkillItem1,
            haveDivTrans = self.mHave1,
            skillTrans = self.mSkill1,
            lock = self.mLock1,
            skillDescTrans = self.mSkillDesc1,
            downBtnTrans = self.mDownBtn1,
            noHaveTxtTrans = self.mNotHaveTxt1,
            skillIdxTrans = self.mSkillIdx1,
        },
        [UISelFightTsure.TYPE_POS_2] = {
            root = self.mSkillItem2,
            haveDivTrans = self.mHave2,
            skillTrans = self.mSkill2,
            lock = self.mLock2,
            downBtnTrans = self.mDownBtn2,
            noHaveTxtTrans = self.mNotHaveTxt2,
            skillIdxTrans = self.mSkillIdx2,
        },
        [UISelFightTsure.TYPE_POS_3] = {
            root = self.mSkillItem3,
            haveDivTrans = self.mHave3,
            skillTrans = self.mSkill3,
            lock = self.mLock3,
            downBtnTrans = self.mDownBtn3,
            noHaveTxtTrans = self.mNotHaveTxt3,
            skillIdxTrans = self.mSkillIdx3,
        },
        [UISelFightTsure.TYPE_POS_4] = {
            root = self.mSkillItem4,
            haveDivTrans = self.mHave4,
            skillTrans = self.mSkill4,
            lock = self.mLock4,
            downBtnTrans = self.mDownBtn4,
            noHaveTxtTrans = self.mNotHaveTxt4,
            skillIdxTrans = self.mSkillIdx4,
        },
    }

    for k, v in pairs(self._skillAllTransList) do
        self:InitTextLineWithLanguage(v.skillDescTrans, -30)

        local isShow = k <= self._maxPos
        CS.ShowObject(v.root, isShow)
    end

    self:InitList()

    if not isPasvWnd then
        self:InitDragList()
    end

    local emptyRefId = isPasvWnd and 23006 or 23006
    self:InitEmptyList(emptyRefId)


    --CS.ShowObject(self.mAttrBtn,not isPasvWnd)
    CS.ShowObject(self.mDescTxt, not isPasvWnd)
    local str = ""
    if isPasvWnd then
        str = ccClientText(32601)
    else
        str = ccClientText(19066)
    end

    self:SetWndText(self.mTitle, str)
end

function UISelFightTsure:UIDragOnDrag(dragKey, eventData)
    if self._dragItemData and self._dragItemData.key == dragKey then
        local trans = self._dragItemData.item
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

function UISelFightTsure:UIDragOnBegin(dragKey, eventData)
    self._dragItemData = nil

    local itemData = self._dragItemDataList[dragKey]
    if not self:IsItemOpen(itemData.index) then
        return
    end

    local item = itemData.item
    self._dragItemData = itemData
    item:SetAsLastSibling()
    local camera = eventData.pressEventCamera
    local pos = camera:ScreenToWorldPoint(eventData.position)
    pos = item.parent:InverseTransformPoint(pos)
    self._dragOffsetPosX = item.localPosition.x - pos.x
end

function UISelFightTsure:InitText()
    self:SetWndText(self.mBotTitle, ccClientText(41072))
    self:SetWndText(self.mTitle, ccClientText(41066))
    self:SetWndText(self.mDescTxt, ccClientText(41073))
    self:InitTextLineWithLanguage(self.mDescTxt, -30)
end

function UISelFightTsure:CreateTreasureList(list)
    local uiList = self._uiTreasureList
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll("_uiTreasureList")
        self._uiTreasureList = uiList
        uiList:Create(self.mSkillAllList, list, function(...)
            self:OnDrawTreasureCell(...)
        end, UIItemList.WRAP)
    end
end

function UISelFightTsure:OnSwap(oldIndex, newIndex)
    local oldValue = self._treaPosToId[oldIndex]
    local newValue = self._treaPosToId[newIndex]

    --printErrorN("swap ..old index="..oldIndex.." value="..oldValue..", new index="..newIndex.." value="..newValue)

    self._treaPosToId[oldIndex] = newValue
    self._treaPosToId[newIndex] = oldValue

    if newValue ~= 0 then
        self._treaIdToPos[newValue] = oldIndex
    end
    if oldValue ~= 0 then
        self._treaIdToPos[oldValue] = newIndex
    end

    local oldTrans = self._skillAllTransList[oldIndex]
    local newTrans = self._skillAllTransList[newIndex]

    self._skillAllTransList[oldIndex] = newTrans
    self._skillAllTransList[newIndex] = oldTrans

    self:SetWndText(newTrans.skillIdxTrans, oldIndex)
    self:SetWndText(oldTrans.skillIdxTrans, newIndex)
end

function UISelFightTsure:CleanDragList()
    for k, v in pairs(self._dragItemDataList or {}) do
        v.item = nil
        if v.tween then
            v.tween:Kill(false)
            v.tween = nil
        end
    end
end

function UISelFightTsure:CreateSkillList(idx, skillRefId)
    local transData = self._skillAllTransList[idx]
    if not transData then
        return
    end

    self:SetWndText(transData.skillIdxTrans, idx)

    local isOpen, openStr = self:IsItemOpen(idx)

    local notHaveSkill = skillRefId == 0

    local showNotSkillTxt = not isOpen or notHaveSkill
    CS.ShowObject(transData.haveDivTrans, not showNotSkillTxt)

    local noHaveTxtTrans = transData.noHaveTxtTrans
    CS.ShowObject(noHaveTxtTrans, notHaveSkill)
    CS.ShowObject(transData.lock, not isOpen)

    if showNotSkillTxt then
        if not isOpen then
            self:SetTextTile(transData.lock, ccClientText(41076) .. openStr)
        else
            self:SetTextTile(transData.lock, "")
            if notHaveSkill then
                self:SetWndText(noHaveTxtTrans, ccClientText(41068))
            else
                self:SetWndText(noHaveTxtTrans, "")
            end
        end
    else
        -- local upRef = GameTable.DraconicSuitRankRef[skillRefId]
        -- local ref = GameTable.DraconicRef[upRef.type]

        -- local nameStr = ccClientText(41069, ccLngText(ref.name), upRef.rankNow + 1)
        -- local skillNameTrans = transData.skillNameTrans
        -- self:SetWndText(skillNameTrans, nameStr)
        -- local color = gModelItem:GetColorByQualityId(ref.quality)
        -- self:SetXUITextTransColor(skillNameTrans, color)

        -- local skillRef = GameTable.SnakeSkillRef[upRef.skillId]
        -- local skillDescTrans = transData.skillDescTrans
        -- self:SetWndText(skillDescTrans, ccLngText(skillRef.description))

        -- local effectDesc = ccLngText(upRef.effectDesc)
        -- local skillDescTrans = transData.skillDescTrans
        -- self:SetWndText(skillDescTrans, effectDesc)


        gModelDraconic:DrawSkillItem(self, transData.skillTrans, { upRefId = skillRefId, showLev = true, showStar = true, showName = true })

        self:SetWndClick(transData.downBtnTrans, function()

            if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
                --训练模式不处理

            else
                self:DownEvent(skillRefId)

            end
        end)
    end
end

function UISelFightTsure:InitEvent()
    self:SetWndClick(self.mBg, function()
        self:ChuShiEvent()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose, function()
        self:ChuShiEvent()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mChuShiBtn, function()
        self:ChuShiEvent()
    end)

    self:SetWndClick(self.mAttrBtn, function()
        GF.OpenWnd("WndTreasureHouse")
    end)

    self:WndEventRecv(EventNames.REFRESH_OTHER_TEAM_TREA, function(skillRefId, index)
        if self._idRecord then
            self._idRecord[skillRefId] = nil
        end

        self:SelSkillEvent(skillRefId)

        local list = self:FindUIScroll("_uiTreasureList")
        if list then
            list:DrawAllItems(false)
        end
    end)
end

function UISelFightTsure:CheckOtherFormation(skillRefId)
    local index = self._idRecord and self._idRecord[skillRefId]
    if index then
        if self._wndType == UISelFightTsure.MULTI then
            local para = {
                refId = 10034,
                para = { index },
                func = function()
                    FireEvent(EventNames.REFRESH_OTHER_TEAM_TREA, skillRefId, index)
                end
            }

            gModelGeneral:OpenUIOrdinTips(para)
        else
            local str = ccClientText(21837, index)
            GF.ShowMessage(str)
        end

        return true
    end
end

function UISelFightTsure:OnDrawTreasureCell(list, item, itemdata, itempos)
    local skillTrans = self:FindWndTrans(item, "Skill")
    local tips = self:FindWndTrans(item, "mask/tip")
    local SkillName = self:FindWndTrans(item, "SkillName")
    local SkillDesc = self:FindWndTrans(item, "SkillDesc")
    local Up = self:FindWndTrans(item, "Up")
    local Down = self:FindWndTrans(item, "Down")
    local attach = self:FindWndTrans(item, "attach")

    local skillRefId = itemdata
    local upRef = GameTable.DraconicSuitRankRef[skillRefId]
    local ref = GameTable.DraconicRef[upRef.type]

    self:SetWndText(SkillName, ccLngText(ref.name))
    local color = gModelItem:GetColorByQualityId(ref.quality)
    self:SetXUITextTransColor(SkillName, color)

    local skillRef = GameTable.SnakeSkillRef[upRef.skillId]
    self:SetWndText(SkillDesc, ccLngText(skillRef.description))

    local select = self._treaIdToPos[skillRefId] ~= nil
    local param = {
        upRefId = skillRefId,
        showLev = true,
        select = select,
        showStar = true,
    }
    gModelDraconic:DrawSkillItem(self, skillTrans, param)

    CS.ShowObject(Up, not select)
    CS.ShowObject(Down, select)


    local attachMainRefId = gModelDraconic:GetMainAttachRefId(upRef.type)
    local strAttachName = ""
    if attachMainRefId > 0 then
        local ref = gModelDraconic:GetDraconicRef(attachMainRefId)
        strAttachName = ccLngText(ref.name)
    end

    self:SetWndClick(Up, function()
        if attachMainRefId > 0 then
            GF.ShowMessage(ccClientText(40914, strAttachName))
            return
        end

        self:SelSkillEvent(skillRefId)
    end)
    self:SetWndClick(Down, function()
        self:SelSkillEvent(skillRefId)
    end)
    self:SetWndClick(skillTrans, function()
        -- 打开宝物tips

        local upRef = GameTable.DraconicSuitRankRef[skillRefId]
        GF.OpenWnd("UIDraconicUpStar", { refId = upRef.type, starNum = upRef.rankNow, tips = true })
    end)

    local teamIndex = self._idRecord and self._idRecord[skillRefId]

    if teamIndex then
        local str = ccClientText(21817, teamIndex)
        self:SetWndText(tips, str)
    end
    CS.ShowObject(tips.parent, teamIndex ~= nil)

    if attachMainRefId > 0 then
        -- local color = gModelItem:GetColorStringByQualityId(ref.quality)
        -- strName = ccClientText(41021, color, ccLngText(ref.name))
        self:SetTextTile(attach, ccClientText(40908, strAttachName))
    end

    CS.ShowObject(attach, attachMainRefId > 0)

end

function UISelFightTsure:DownEvent(skillRefId)
    local pos = self._treaIdToPos[skillRefId]
    if not pos then
        return
    end
    self._treaPosToId[pos] = 0
    self._treaIdToPos[skillRefId] = nil

    self:RefreshSkillContent()
end

function UISelFightTsure:RefreshSkillContent()
    for i = 1, self._maxPos do
        local skillRefId = self._treaPosToId[i] or 0
        self:CreateSkillList(i, skillRefId)
    end

    local list = self:FindUIScroll("_uiTreasureList")
    if list then
        list:DrawAllItems(false)
    end
end

------------------------------------------------------------------
return UISelFightTsure