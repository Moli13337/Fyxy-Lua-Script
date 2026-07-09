---
--- Created by Administrator.
--- DateTime: 2024/11/27 21:58:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISelFightGodWeapon:LWnd
local UISelFightGodWeapon = LxWndClass("UISelFightGodWeapon", LWnd)
------------------------------------------------------------------
UISelFightGodWeapon.NORMAL = 1
UISelFightGodWeapon.MULTI = 2

UISelFightGodWeapon.PASV = 3 -- 被动

UISelFightGodWeapon.TYPE_ACTIVE_ALL = 4
UISelFightGodWeapon.TYPE_PASV_ALL = 3

UISelFightGodWeapon.TYPE_POS_1 = 1
UISelFightGodWeapon.TYPE_POS_2 = 2
UISelFightGodWeapon.TYPE_POS_3 = 3
UISelFightGodWeapon.TYPE_POS_4 = 4

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISelFightGodWeapon:UISelFightGodWeapon()
    ---@type table<number,CommonIcon>
    self._uiCommonList = {}
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISelFightGodWeapon:OnWndClose()
    self:ClearCommonIconList(self._uiCommonList)
    self._uiCommonList = nil
    self:CleanDragList()

    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISelFightGodWeapon:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISelFightGodWeapon:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitText()
    self:InitEvent()
    self:InitData()
end

function UISelFightGodWeapon:InitList()
    for i = 1, self._maxPos do
        local starRefId = self._posToStarRefId[i] or 0
        self:CreateSkillList(i, starRefId)
    end

    local list = {}

    if self._isPasvWnd then---獲取技能列表-
        list = gModelDivineWeapon:GetActivateStarRefId() -- gModelDraconic:GetActiveUpRefList()
    else
        local combatType = self._combatType
        if combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
            list = gModelCareSchool:GetDraconicId(self._targetId)
        else
            list = gModelDivineWeapon:GetActivateStarRefId()
        end
    end

    table.sort(list, function(a, b)
        local aCfg = GameTable.DivineWeaponRef[a.type]
        local bCfg = GameTable.DivineWeaponRef[b.type]
        if aCfg.quality == bCfg.quality then
            return aCfg.refId < bCfg.refId
        else
            return aCfg.quality > bCfg.quality
        end
    end)

    self:CreateTreasureList(list)
    local emptyList = #list <= 0
    CS.ShowObject(self.mNoRecord2, emptyList)
end

function UISelFightGodWeapon:CreateSkillList(idx, starRefId)
    local transData = self._skillAllTransList[idx]
    if not transData then
        return
    end

    self:SetWndText(transData.skillIdxTrans, idx)

    local isOpen, openStr = self:IsItemOpen(idx)

    local notHaveSkill = starRefId == 0

    local showNotSkillTxt = not isOpen or notHaveSkill
    CS.ShowObject(transData.haveDivTrans, not showNotSkillTxt)

    local noHaveTxtTrans = transData.noHaveTxtTrans
    CS.ShowObject(noHaveTxtTrans, notHaveSkill)
    CS.ShowObject(transData.lock, not isOpen)

    if showNotSkillTxt then
        if not isOpen then
            self:SetTextTile(transData.lock, ccClientText(46150) .. openStr)
        else
            self:SetTextTile(transData.lock, "")
            if notHaveSkill then
                self:SetWndText(noHaveTxtTrans, ccClientText(41068))
            else
                self:SetWndText(noHaveTxtTrans, "")
            end
        end
    else

		local starRef = GameTable.DivineWeaponStarRef[starRefId]
		local skillId = starRef.skillId
		local skillRef = GameTable.SnakeSkillRef[skillId]
		-- local skillBg = self:FindWndTrans(transData.skillTrans,"bg")
		-- self:SetWndEasyImage(skillBg,skill)
		local skillIcon = self:FindWndTrans(transData.skillTrans,"icon")
		local starTran = self:FindWndTrans(transData.skillTrans,"star")
		local lev = self:FindWndTrans(transData.skillTrans,"levBg/lev")
        self:SetWndText(lev,skillRef.level)
        local starNum = gModelDivineWeapon:GetCurStar(starRef.type) or 0
        local sizeDe = starTran.sizeDelta
        sizeDe.x = starNum *40
        starTran.sizeDelta = sizeDe
		self:SetWndEasyImage(skillIcon,skillRef.icon)
		local divineRef = GameTable.DivineWeaponRef[starRef.type]
		local name = self:FindWndTrans(transData.skillTrans,"name")
		self:SetWndText(name,ccLngText(divineRef.name))
		local color = gModelItem:GetColorByQualityId(divineRef.quality)
		self:SetXUITextTransColor(name, color)
        self:SetWndClick(transData.downBtnTrans, function()
            if self._combatType == LCombatTypeConst.COMBAT_TACTICAL_TRAINING then
                --训练模式不处理

            else
                self:DownEvent(starRefId)

            end
        end)
    end
end

function UISelFightGodWeapon:IsItemOpen(index)
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
            return false,ccClientText(46148)
        end
    end
    return gModelDivineWeapon:IsSkillOpenByPos(index)
end

function UISelFightGodWeapon:UIDragOnDrag(dragKey, eventData)
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

function UISelFightGodWeapon:InitData()
    local divineStarRefIds = self:GetWndArg("divineStarRefIds") or {}
    self._targetId = self:GetWndArg("targetId")
    self._combatType = self:GetWndArg("combatType") or LCombatTypeConst.COMBAT_MAIN
    self._wndType = self:GetWndArg("wndType") or UISelFightGodWeapon.NORMAL
    self._idRecord = self:GetWndArg("idRecord")
    self._func = self:GetWndArg("func")

    self._posToStarRefId = {}
    self._starRefIdToPos = {}

    local isPasvWnd = self._wndType == UISelFightGodWeapon.PASV
    self._isPasvWnd = isPasvWnd

    self._maxPos = UISelFightGodWeapon.TYPE_ACTIVE_ALL
    if isPasvWnd then
        self._maxPos = UISelFightGodWeapon.TYPE_PASV_ALL
    end

    for i = 1, self._maxPos do
        local starRefId = divineStarRefIds[i] or 0
        if starRefId ~= 0 then
            self._starRefIdToPos[starRefId] = i
        end
        self._posToStarRefId[i] = starRefId
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
        [UISelFightGodWeapon.TYPE_POS_1] = {
            root = self.mSkillItem1,
            haveDivTrans = self.mHave1,
            skillTrans = self.mSkill1,
            lock = self.mLock1,
            skillDescTrans = self.mSkillDesc1,
            downBtnTrans = self.mDownBtn1,
            noHaveTxtTrans = self.mNotHaveTxt1,
            skillIdxTrans = self.mSkillIdx1,
        },
        [UISelFightGodWeapon.TYPE_POS_2] = {
            root = self.mSkillItem2,
            haveDivTrans = self.mHave2,
            skillTrans = self.mSkill2,
            lock = self.mLock2,
            downBtnTrans = self.mDownBtn2,
            noHaveTxtTrans = self.mNotHaveTxt2,
            skillIdxTrans = self.mSkillIdx2,
        },
        [UISelFightGodWeapon.TYPE_POS_3] = {
            root = self.mSkillItem3,
            haveDivTrans = self.mHave3,
            skillTrans = self.mSkill3,
            lock = self.mLock3,
            downBtnTrans = self.mDownBtn3,
            noHaveTxtTrans = self.mNotHaveTxt3,
            skillIdxTrans = self.mSkillIdx3,
        },
        [UISelFightGodWeapon.TYPE_POS_4] = {
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

    local emptyRefId = 43000--isPasvWnd and 23006 or 23006
    self:InitEmptyList(emptyRefId)


    --CS.ShowObject(self.mAttrBtn,not isPasvWnd)
    CS.ShowObject(self.mDescTxt, not isPasvWnd)
    local str = ""
    if isPasvWnd then
        str = ccClientText(46152)
    else
        str = ccClientText(46153)
    end

    self:SetWndText(self.mTitle, str)
end

function UISelFightGodWeapon:CreateTreasureList(list)
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

function UISelFightGodWeapon:InitDragList()
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

function UISelFightGodWeapon:InitEmptyList(refId)
    local data = {
        refId = refId, -- 18002,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UISelFightGodWeapon:SelSkillEvent(starRefId)
    local isChange = false

    local treaPos = self._starRefIdToPos[starRefId]
    if treaPos then
        isChange = true
        self._posToStarRefId[treaPos] = 0
        self._starRefIdToPos[starRefId] = nil
    else
        local isLock = false
        local emptyPos = nil
        local pos
        for k = 1, self._maxPos do
            isLock = not self:IsItemOpen(k)
            if not pos and isLock then
                pos = k
            end
            local starRefId = self._posToStarRefId[k]
            if starRefId == 0 and not isLock then
                emptyPos = k
                break
            end
        end

        if emptyPos then
            local isOnOther = self:CheckOtherFormation(starRefId)
            if not isOnOther then
                isChange = true
                self._posToStarRefId[emptyPos] = starRefId
                self._starRefIdToPos[starRefId] = emptyPos
            end
        else
            if isLock then
                -- GF.ShowMessage(ccClientText(41071))
                local _,str = gModelDivineWeapon:IsSkillOpenByPos(pos,46181)
                GF.ShowMessage(str)
            else
                GF.ShowMessage(ccClientText(41070))
            end
        end
    end

    if isChange then
        self:RefreshSkillContent()
    end
end

function UISelFightGodWeapon:InitEvent()
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
        GF.OpenWnd("WndTreasureHouse")--不存在界面
    end)

    self:WndEventRecv(EventNames.REFRESH_OTHER_TEAM_DIVINE, function(starRefId, index)
        if self._idRecord then
            self._idRecord[starRefId] = nil
        end

        self:SelSkillEvent(starRefId)

        local list = self:FindUIScroll("_uiDivineList")
        if list then
            list:DrawAllItems(false)
        end
    end)
end

function UISelFightGodWeapon:InitText()
    self:SetWndText(self.mBotTitle, ccClientText(41072))
    self:SetWndText(self.mTitle, ccClientText(46147))
    self:SetWndText(self.mDescTxt, ccClientText(41073))
    self:InitTextLineWithLanguage(self.mDescTxt, -30)
end

function UISelFightGodWeapon:RefreshSkillContent()
    for i = 1, self._maxPos do
        local starRefId = self._posToStarRefId[i] or 0
        self:CreateSkillList(i, starRefId)
    end

    local list = self:FindUIScroll("_uiTreasureList")
    if list then
        list:DrawAllItems(false)
    end
end

function UISelFightGodWeapon:OnSwap(oldIndex, newIndex)
    local oldValue = self._posToStarRefId[oldIndex]
    local newValue = self._posToStarRefId[newIndex]

    --printErrorN("swap ..old index="..oldIndex.." value="..oldValue..", new index="..newIndex.." value="..newValue)

    self._posToStarRefId[oldIndex] = newValue
    self._posToStarRefId[newIndex] = oldValue

    if newValue ~= 0 then
        self._starRefIdToPos[newValue] = oldIndex
    end
    if oldValue ~= 0 then
        self._starRefIdToPos[oldValue] = newIndex
    end

    local oldTrans = self._skillAllTransList[oldIndex]
    local newTrans = self._skillAllTransList[newIndex]

    self._skillAllTransList[oldIndex] = newTrans
    self._skillAllTransList[newIndex] = oldTrans

    self:SetWndText(newTrans.skillIdxTrans, oldIndex)
    self:SetWndText(oldTrans.skillIdxTrans, newIndex)
end

function UISelFightGodWeapon:CleanDragList()
    for k, v in pairs(self._dragItemDataList or {}) do
        v.item = nil
        if v.tween then
            v.tween:Kill(false)
            v.tween = nil
        end
    end
end

function UISelFightGodWeapon:DownEvent(starRefId)
    local pos = self._starRefIdToPos[starRefId]
    if not pos then
        return
    end
    self._posToStarRefId[pos] = 0
    self._starRefIdToPos[starRefId] = nil

    self:RefreshSkillContent()
end

function UISelFightGodWeapon:UIDragOnBegin(dragKey, eventData)
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

function UISelFightGodWeapon:CheckOtherFormation(starRefId)
    local index = self._idRecord and self._idRecord[starRefId]
    if index then
        if self._wndType == UISelFightGodWeapon.MULTI then
            local para = {
                refId = 10034,
                para = { index },
                func = function()
                    FireEvent(EventNames.REFRESH_OTHER_TEAM_DIVINE, starRefId, index)
                end
            }

            gModelGeneral:OpenUIOrdinTips(para)
        else
            local str = ccClientText(46151, index)
            GF.ShowMessage(str)
        end

        return true
    end
end

function UISelFightGodWeapon:OnDrawTreasureCell(list, item, itemdata, itempos)
    local skillTrans = self:FindWndTrans(item, "Skill")
    local tips = self:FindWndTrans(item, "mask/tip")
    local SkillName = self:FindWndTrans(item, "SkillName")
    local SkillDesc = self:FindWndTrans(item, "SkillDesc")
    local Up = self:FindWndTrans(item, "Up")
    local Down = self:FindWndTrans(item, "Down")
    local attach = self:FindWndTrans(item, "attach")
	local skillIcon = self:FindWndTrans(skillTrans,"icon")
	local selectTran = self:FindWndTrans(skillTrans,"select")
	local starTran = self:FindWndTrans(skillTrans,"star")
	local lev = self:FindWndTrans(skillTrans,"levBg/lev")

    local starRef = itemdata
    local ref = GameTable.DivineWeaponRef[starRef.type]

    self:SetWndText(SkillName, ccLngText(ref.name))
    local color = gModelItem:GetColorByQualityId(ref.quality)
    self:SetXUITextTransColor(SkillName, color)

    local skillRef = GameTable.SnakeSkillRef[starRef.skillId]
    self:SetWndText(SkillDesc, ccLngText(skillRef.description))
    self:SetWndText(lev,skillRef.level)
    local select = self._starRefIdToPos[starRef.refId] ~= nil
	self:SetWndEasyImage(skillIcon,skillRef.icon)

    local starNum = gModelDivineWeapon:GetCurStar(ref.refId) or 0
    local sizeDe = starTran.sizeDelta
    sizeDe.x = starNum *40
    starTran.sizeDelta = sizeDe

    CS.ShowObject(Up, not select)
    CS.ShowObject(Down, select)
    CS.ShowObject(selectTran, select)


    local attachMainRefId = gModelDivineWeapon:GetMainAttachRefId(starRef.type)
    local strAttachName = ""
    if attachMainRefId > 0 then
        local ref = GameTable.DivineWeaponRef[attachMainRefId]
        strAttachName = ccLngText(ref.name)
        self:SetTextTile(attach, ccClientText(40908, strAttachName))
    end
    CS.ShowObject(attach, attachMainRefId > 0)

    self:SetWndClick(Up, function()
        if attachMainRefId > 0 then
            GF.ShowMessage(ccClientText(46179, strAttachName))
            return
        end

        self:SelSkillEvent(starRef.refId)
    end)
    self:SetWndClick(Down, function()
        self:SelSkillEvent(starRef.refId)
    end)
    self:SetWndClick(skillTrans, function()
        -- 打开宝物tips
		-----------------未改-------
        GF.OpenWnd("UIDivineWeaponTips",{refId = ref.refId})
    end)

    local teamIndex = self._idRecord and self._idRecord[starRef.refId]

    if teamIndex then
        local str = ccClientText(21817, teamIndex)
        self:SetWndText(tips, str)
    end
    CS.ShowObject(tips.parent, teamIndex ~= nil)

    -- if attachMainRefId > 0 then
    --     -- local color = gModelItem:GetColorStringByQualityId(ref.quality)
    --     -- strName = ccClientText(41021, color, ccLngText(ref.name))
    --     self:SetTextTile(attach, ccClientText(40908, strAttachName))
    -- end

    -- CS.ShowObject(attach, attachMainRefId > 0)

end

function UISelFightGodWeapon:CheckDragItemSwap(curData, curPos)
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

function UISelFightGodWeapon:ChuShiEvent()
    if self._func then
        local list = table.clone(self._posToStarRefId)
        self._func(list)
    end
    self:WndClose()
end

function UISelFightGodWeapon:UIDragOnEnd(dragKey, eventData)
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

------------------------------------------------------------------
return UISelFightGodWeapon