---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEqWear:LWnd
local UIEqWear = LxWndClass("UIEqWear", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEqWear:UIEqWear()
    ---@type table<number,CommonIcon>
    self._equipIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEqWear:OnWndClose()
    self:ClearCommonIconList(self._equipIconList)
    self._equipIconList = nil
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEqWear:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEqWear:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitData()
    self:SetEmptyData()
    self:InitEvent()
    self:InitMsg()
    self:InitText()
    if self._isRefId then
        -- 替换
        self:EquipReplaceView()
    else
        -- 穿戴
        self:EquipWearView()
    end
    self:InitEquipList()
end

-- 穿戴界面
function UIEqWear:EquipWearView()
    self:SetXUITextText(self.mTitle, ccClientText(11304))
    CS.ShowObject(self.mView1, true)
end

function UIEqWear:InitEquipList()
    local isRefId = self._isRefId
    local uiList = self._uiList
    if not uiList then
        uiList = UIListWrap:New()
        if isRefId then
            uiList:Create(self, self.mWearList2)
        else
            uiList:Create(self, self.mWearList1)
        end
        uiList:SetFuncOnItemDraw(function(...)
            self:OnDrawEquipCell(...)
        end)
        self._uiList = uiList
    end
    uiList:RemoveAll()
    local equipType = self._equipType
    local equipList = gModelEquip:GetEquipListByPart(tonumber(equipType))

    local isEmpty = table.isempty(equipList)
    if not isEmpty then
        local sortEquipList = {}
        for k, v in pairs(equipList) do
            local refId = v:GetRefId()
            if self._refId ~= refId then
                local ref = gModelEquip:GetEquipRefByRefId(refId)

                if not ref then
                    printInfoNR2("--------------Equip缺少配置--refId--", refId)
                    return
                end

                local data = { ref = ref, equip = v }
                --local ref = gModelEquip:GetEquipRefByRefId(refId)
                table.insert(sortEquipList, data)
            end
        end
        table.sort(sortEquipList, function(equip1, equip2)
            local score1, score2 = equip1.equip:GetScore(), equip2.equip:GetScore()
            return score1 > score2
        end)
        for i, v in ipairs(sortEquipList) do
            uiList:AddData(i, v)
        end
    end
    if isEmpty then
        if self._isRefId then
            CS.ShowObject(self.mNoRecord1, false)
            CS.ShowObject(self.mNoRecord2, true)
            CS.ShowObject(self.mWearList2, false)
        else
            CS.ShowObject(self.mNoRecord1, true)
            CS.ShowObject(self.mNoRecord2, false)
            CS.ShowObject(self.mWearList1, false)
        end
    end
    uiList:RefreshList()
end

function UIEqWear:InitEvent()
    self:SetWndClick(self.mBg, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mGetBtn, function()
        self:ClickGetText()
    end)
    self:SetWndClick(self.mGetBtn2, function()
        self:ClickGetText()
    end)
end

function UIEqWear:InitData()
    self._heroId = self:GetWndArg("heroId")
    local refId = self:GetWndArg("refId")
    self._equipType = self:GetWndArg("part")

    if not refId then
        return
    end
    self._wearAttrList = {
        self.mWearAttr1,
        self.mWearAttr2,
    }
    self:SaveEquipWearData(refId)
end

function UIEqWear:InitText()
    self:SetWndButtonText(self.mGetBtn, ccClientText(13247))
    self:SetWndButtonText(self.mGetBtn2, ccClientText(13247))
end

function UIEqWear:SetInfo(item, InstanceID, refId, itemdata_new)

    local itemdata = itemdata_new.ref
    local isRefId = self._isRefId
    local isAlike = refId == self._refId
    local EquipIconTrans = self.mEquipIconTrans
    CS.ShowObject(self.mEquipIconTrans, true)
    if item then
        EquipIconTrans = CS.FindTrans(item, "IconRoot")
    end
    if EquipIconTrans then
        local baseClass = self._equipIconList[InstanceID]
        if not baseClass then
            baseClass = CommonIcon:New(self)
            self._equipIconList[InstanceID] = baseClass
            baseClass:Create(CS.FindTrans(EquipIconTrans, "Icon"))
        end
        local equipnum = 0
        if not itemdata_new.equip then
            equipnum = gModelEquip:GetEquipStructByRefId(self._refId):GetNum()
        else
            equipnum = itemdata_new.equip:GetNum()
        end

        baseClass:SetEquipIcon(refId, equipnum)
        --baseClass:SetCommonReward(LItemTypeConst.TYPE_EQUIP, refId)
        baseClass:EnableShowNum(item ~= nil)
        self:SetIconClickScale(EquipIconTrans, true)

        local quality = gModelEquip:GetEquipQualityByRefId(refId)
        self:SetWndClick(EquipIconTrans, function()
            if quality and quality >= 7 then
                gModelGeneral:OpenEquipInfoTip(refId, nil, 3, true, nil, nil, nil, nil, true, itemdata_new.equip)
            else
                gModelGeneral:OpenEquipInfoTip(refId, nil, nil, true)

            end
        end)
        baseClass:DoApply()
        baseClass._curIconCls._iconInst.transform.localScale = Vector3.New(0.77, 0.77, 0.77)

         quality = gModelEquip:GetEquipQualityByRefId(refId)
        if quality and quality >= 7 then
            local level = itemdata_new.equip:GetLevel()
            baseClass:SetEquipExtension(level)
        else
            baseClass:SetEquipExtension(0)
        end

    end
    local EquipNameTrans = self.mWearEquipName
    if item then
        EquipNameTrans = CS.FindTrans(item, "EquipName")
    end
    if EquipNameTrans then
        local name = ccLngText(itemdata.name)
        self:SetWndText(EquipNameTrans, name)

        local quaId = itemdata.quality
        -- 名字设置颜色
        local color = gModelItem:GetColorByQualityId(quaId)
        self:SetXUITextTransColor(EquipNameTrans, color)
    end
    local attrList = {}
    if item then
        for i = 1, 2 do
            local attrTrans = CS.FindTrans(item, "Attr" .. i)
            if attrTrans then
                attrList[i] = attrTrans
                CS.ShowObject(attrTrans, false)
            end
        end
    end
    local list = string.split(itemdata.attr, ",")
    local temp_equipStrengthRef
    if itemdata_new.equip then

        local temp_equipRef = gModelEquip:GetEquipRefByRefId(refId)
        local temp__strengthType = gModelEquip:GetEquipStrengthType(temp_equipRef)
        temp_equipStrengthRef = gModelEquip:GetEquipStrengthRef(temp__strengthType, itemdata_new.equip:GetLevel())

    end

    for i = 1, #list do
        local trans
        if item then
            trans = attrList[i]
        else
            trans = self._wearAttrList[i]
        end
        if trans then
            CS.ShowObject(trans, true)
            local data = list[i]
            local sAttrList = string.split(data, "=")
            local attrType, numType, attrNum = tonumber(sAttrList[1]), tonumber(sAttrList[2]), tonumber(sAttrList[3])
            local attrTrans
            if item then
                attrTrans = CS.FindTrans(trans, "Attr")
            else
                attrTrans = trans
            end
            if attrTrans then
                local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrType, numType, attrNum)
                if temp_equipStrengthRef then
                    local attrInfo = gModelEquip:ParseEquipAttrInfo(temp_equipStrengthRef.attrAdd)
                    if attrInfo.refId == attrType and attrInfo.type == numType then
                        value = value + attrInfo.value
                    end
                end

                if itemdata_new.equip then
                    local refineId = itemdata_new.equip:GetRefineRefId()
                    if refineId>0 then
                        local refineRef = gModelEquip:GetRefineLevelRef(refineId)

                        if refineRef then
                            local attrInfo = gModelEquip:ParseEquipAttrInfo(refineRef.attrAdd1)

                            if attrInfo.refId == attrType and attrInfo.type == nType then
                                value = value + attrInfo.value
                            end
                        end

                    end
                end

                local str = gModelHero:GetAttributeNameById(attrType)
                str = str .. "：<color=#559175>" .. value .. "</color>"
                self:SetWndText(attrTrans, str)
            end
        end
    end
    local ScoreTxtTrans = self.mWearScoreTxt
    if item then
        ScoreTxtTrans = CS.FindTrans(item, "ScoreTxt")
    end
    local scoreNum

    if nil == itemdata_new.equip then
        scoreNum = gModelEquip:GetEquipRefByRefId(refId).score
    else
        scoreNum = itemdata_new.equip:GetScore()
    end

    if ScoreTxtTrans then
        local str = ccClientText(11311)
        local score = math.floor(scoreNum + 0.5)
        str = string.replace(str, score)
        self:SetWndText(ScoreTxtTrans, str)
    end
    local WearBtnTrasn = self.mWearBtn
    if item then
        WearBtnTrasn = CS.FindTrans(item, "WearBtn")
    end
    if WearBtnTrasn then
        self:SetWndClick(WearBtnTrasn, function()
            print("==== self._heroId = " .. self._heroId .. "====" .. refId)
            if isAlike then
                gModelEquip:OnEquipUnloadReq(self._heroId, { refId })
            else
                if self._isRefId then
                    gModelEquip:OnEquipWearReq(self._heroId, { itemdata_new.equip }, 1)
                else
                    gModelEquip:OnEquipWearReq(self._heroId, { itemdata_new.equip })
                end
            end
        end)
        local btnNameTrans = CS.FindTrans(WearBtnTrasn, "btnName")
        if btnNameTrans then
            if isAlike then
                self:SetWndText(btnNameTrans, ccClientText(11302))
            else
                if self._isRefId then
                    self:SetWndText(btnNameTrans, ccClientText(11310))
                else
                    self:SetWndText(btnNameTrans, ccClientText(11301))
                end
            end
        end
    end
    if isRefId and item then
        local redPointTrans = CS.FindTrans(item, "redPoint")
        if redPointTrans then
            local show = false
            local curScore = gModelEquip:GetEquipStructByRefId(self._refId)._score
            if curScore and curScore < scoreNum then
                show = true
            end
            CS.ShowObject(redPointTrans, show)
        end
    end
end

function UIEqWear:SaveEquipWearData(refId, chang)
    self._refId = refId
    local equipRef = gModelEquip:GetEquipRefByRefId(refId)
    local isRefId = true
    if not equipRef then
        isRefId = false
    else
        self._equipRef = equipRef
    end
    self._isRefId = isRefId
end

function UIEqWear:ClickGetText()
    local cfg = gModelGeneral:GetEmptyCfg(100)
    gModelGeneral:OpenGetWayWnd({ itemId = cfg.jumpItem })
end

-- 替换界面
function UIEqWear:EquipReplaceView()
    self:SetXUITextText(self.mTitle, ccClientText(11303))
    CS.ShowObject(self.mView2, true)
    local ref = self._equipRef
    if ref then

        local data = { ref = ref, equip = self:GetWndArg("equip") }
        self:SetInfo(nil, 1, self._refId, data)
    end
end

function UIEqWear:InitMsg()
    self:WndNetMsgRecv(LProtoIds.EquipWearResp, function()
        self:WndClose()
    end)
    self:WndNetMsgRecv(LProtoIds.EquipUnloadResp, function()
        self:WndClose()
    end)
end

function UIEqWear:OnDrawEquipCell(list, item, itemdata, itempos, fromHeadTail)
    local InstanceID = item:GetInstanceID()
    local refId = itemdata.ref.refId
    self:SetInfo(item, InstanceID, refId, itemdata)
end

function UIEqWear:SetEmptyData()
    local data = { refId = 100, IntroTran = self.mEmptyText, TextBgTran = self.mEmptyTextBg, IconTran = self.mEmptyIcon }
    local emptyList = self:GetCommonEmptyList("_empty1")
    emptyList:RefreshUI(data)
    data = { refId = 100, IntroTran = self.mEmptyText2, TextBgTran = self.mEmptyTextBg2, IconTran = self.mEmptyIcon2 }
    emptyList = self:GetCommonEmptyList("_empty2")
    emptyList:RefreshUI(data)
end
------------------------------------------------------------------
return UIEqWear