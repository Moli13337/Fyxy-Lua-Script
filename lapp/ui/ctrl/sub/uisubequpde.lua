---
--- Created by Administrator.
--- DateTime: 2024/7/8 20:19:59
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubEqUpde:LChildWnd
local UISubEqUpde = LxWndClass("UISubEqUpde", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubEqUpde:UISubEqUpde()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubEqUpde:OnWndClose()
    self:TimerStop(self._timeKey)
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubEqUpde:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubEqUpde:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitText()
    self:InitPara()
    self:InitData()

    self:SetPanel()
end

function UISubEqUpde:OnRefreshItemInfo()

    local showData = gModelEquip:GetUpGradeExpendItem(self._equipClassRef)

    self._isEmptyStrengthItem = false

    local count = #showData

    for k, itemdata in ipairs(showData) do
        local t = {
            itemType = itemdata.itemType,
            itemId = itemdata.refId,

            isShowEff = 0,
        }



        -- 构建 item table
        if itemdata.itemType == LItemTypeConst.TYPE_ITEM then
            t.itemNum = gModelItem:GetNumByRefId(itemdata.refId) -- 这里取背包数据
        elseif itemdata.itemType == LItemTypeConst.TYPE_EQUIP then
            local equipdata = gModelEquip:GetEquipStructByRefId(itemdata.refId)
            t.itemNum = equipdata:GetNum()
        end

        if t.itemNum == 0 then
            count = count - 1
        end

        self._haveExpendItemInfo[t.itemId] = t
        local useNum = self._useExpendItemInfo[t.itemId] or 0

        local num = self._haveExpendItemInfo[t.itemId].itemNum - useNum

        local tran = self._itemUesInfo[t.itemId]

        local useStr = string.format("%s/%s", LUtil.NumberCoversion(useNum), LUtil.NumberCoversion(self._haveExpendItemInfo[t.itemId].itemNum))
        self:SetWndText(tran, useStr)

        local maskTran = self._itemMask[t.itemId]
        CS.ShowObject(maskTran, num <= 0)
        local subTran = self._itemSubBtn[t.itemId]
        CS.ShowObject(subTran, useNum > 0)
    end
    self._isEmptyStrengthItem = count <= 0
end

--计算一个百分比
function UISubEqUpde:CalcuPercent(curValue, nextValue)
    local percent = curValue / nextValue
    percent = percent > 1 and 1 or percent

    percent = percent < 0 and 1 or percent

    return Vector3.New(percent, 1, 1)
end

function UISubEqUpde:SetItemInfo()
    self:SetEquipUpGradeInfo()

    self:SetEquipItem()
    self:SetEquipName()
    --星星
    self:SetStarState()
    --属性
    self:SetAttr()
    --经验条
    self:SetExp()
    --设置按钮状态
    self:SetBtnState()
end

function UISubEqUpde:InitData()
    self._refId = self._equip:GetRefId()
    self._id = self._equip:GetId()

    self._equipRef = gModelEquip:GetEquipRefByRefId(self._refId)

    local classlv = self._equip:GetGrade()
    self._equipClassRef = gModelEquip:GetUpGradeRef(self._equipRef.type, classlv)

    self._useExpendItemExp = 0
    self._curStrength = 0
    self._useExpendItemInfo = {}
    self._haveExpendItemInfo = {}

    self._curCanUpLv, self._curLimitLef = gModelEquip:GetEquipMaxUpGrade(self._equipRef)
    self._longClickTicker = 0
    self._longSubClickTicker = 0
    self._timeKey = "UISubEqUpde_LongClickTimerKey"
end

function UISubEqUpde:OnExpendItemClick(itemdata, itemdataInfo)
    if not self._haveExpendItemInfo[itemdata.refId] then
        self._haveExpendItemInfo[itemdata.refId] = itemdataInfo
    end

    -- check
    if self:CheckIsMax() then
        GF.ShowMessage(ccClientText(44520))  -- [44520] [已達當前最大鑄魂等級，無法添加道具]
        return
    end

    if not self:CheckCanUpStar() then
        if self._curLimitLef and self._curLimitLef.upNeedStar > 0 then
            local str = string.replace(ccClientText(44527), self._curLimitLef.upNeedStar)
            GF.ShowMessage(str)  --[44520] [已達當前最大鑄魂等級，無法添加道具]
        else

            GF.ShowMessage(ccClientText(44520))  --[44520] [已達當前最大鑄魂等級，無法添加道具]

        end
        return
    end

    if self:CheckAddIsCurMax() then
        GF.ShowMessage(ccClientText(44520))   -- [44520] [已達當前最大鑄魂等級，無法添加道具]
        return
    end

    local isLeft, leftNum = self:CheckNum(itemdata.refId)
    if not isLeft then
        GF.ShowMessage(ccClientText(44515)) --[44515] [道具不足]
        return
    end

    --记录一个上报的道具的信息  这里每次点击的话就对应的id记录+1
    if not self._useExpendItemInfo[itemdata.refId] then
        self._useExpendItemInfo[itemdata.refId] = 0
    end

    local useNum = 1

    self._useExpendItemInfo[itemdata.refId] = self._useExpendItemInfo[itemdata.refId] + useNum
    self._useExpendItemExp = self._useExpendItemExp + itemdata.addExp * useNum
    self:SetUseInfo()
end

function UISubEqUpde:InitPara()
    self._refId = self:GetWndArg("refId")
    self._id = self:GetWndArg("id")
    self._equip = self:GetWndArg("equip")
end

function UISubEqUpde:OnSubItemClick_NoLongClick(itemdata)
    self._longSubClickTicker = 0
    self:OnSubItemClick(itemdata)
end

function UISubEqUpde:OnExpendItemClick_NoLongClick(itemdata, itemdataInfo)
    self._longClickTicker = 0
    self:OnExpendItemClick(itemdata, itemdataInfo)
end

function UISubEqUpde:SetEquipItem()
    local baseClass = self._baseEquipIcon

    if not self._baseEquipIcon then
        baseClass = CommonIcon:New()
        baseClass:Create(self.mEquip)

        self._baseEquipIcon = baseClass
    end

    baseClass:SetCommonReward(LItemTypeConst.TYPE_EQUIP, self._refId, 0, nil, false)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()
    baseClass:EnableShowStarRoot(false)
end
function UISubEqUpde:SetTime()
    local itemdata = self._culLongItem
    if self._curLongTicker >= 10 or self._curLongTicker >= self._curLongUseNum then
        self:TimerStop(self._timeKey)
        local useNum = self._curLongUseNum
        local ticker = self._curLongTicker
        useNum = useNum - ticker
        self._useExpendItemInfo[itemdata.refId] = self._useExpendItemInfo[itemdata.refId] + useNum
        self._useExpendItemExp = self._useExpendItemExp + itemdata.addExp * useNum
        self:SetUseInfo()

        self._curLongUseNum = 0
        self._curLongTicker = 0
        self._isLongCalculate = false
    else
        self._curLongTicker = self._curLongTicker + 1

        if not self._useExpendItemInfo[itemdata.refId] then
            self._useExpendItemInfo[itemdata.refId] = 0
        end
        self._useExpendItemInfo[itemdata.refId] = self._useExpendItemInfo[itemdata.refId] + 1
        self._useExpendItemExp = self._useExpendItemExp + itemdata.addExp
        self:SetUseInfo()
    end
end

function UISubEqUpde:SetUseInfo()
    local numExp = self._equip:GetGradeExp()
    numExp = self._useExpendItemExp + numExp
    self._numExp = numExp

    local nextExp = self._equipClassRef.upNeedExp

    local scale = self:CalcuPercent(numExp, nextExp)
    self.mBar_1.localScale = scale

    local isFull = false
    if nextExp == -1 then
        nextExp = 0
        isFull = true
    end

    local str
    if isFull then
        str = "<color=#31ff9f>EXP </color>Max "
        self.mBar_2.localScale = Vector3.New(1, 1, 1)
        self:SetAnchorPos(self.mBarNum, Vector2.New(60, 0))
    else
        str = string.format("<color=#31ff9f>EXP </color> %s/%s", numExp, nextExp)
        self:SetAnchorPos(self.mBarNum, Vector2.New(20, 0))
    end

    self:SetWndText(self.mBarNum, str)

    for itemId, useNum in pairs(self._useExpendItemInfo) do
        local num = self._haveExpendItemInfo[itemId].itemNum - useNum

        local tran = self._itemUesInfo[itemId]

        local useStr = string.format("%s/%s", LUtil.NumberCoversion(useNum), LUtil.NumberCoversion(self._haveExpendItemInfo[itemId].itemNum))
        self:SetWndText(tran, useStr)

        local maskTran = self._itemMask[itemId]
        CS.ShowObject(maskTran, num <= 0)
        local subTran = self._itemSubBtn[itemId]
        CS.ShowObject(subTran, useNum > 0)
    end
    local upLevel = gModelEquip:GetGradeUpLevel(numExp, self._equip:GetGrade(), self._equipRef.type)

    local uplevelNum = upLevel - self._equip:GetGrade()

    self._curStrength = upLevel

    CS.ShowObject(self.mUpText, uplevelNum > 0)
    if uplevelNum > 0 then
        self:SetWndText(self.mUpText, " +" .. uplevelNum)
    end

    self:SetNextAttr(uplevelNum)
end
--endregion --------------------------------------------------------------------------------------

--region 检查部分 --------------------------------------------------------------------------------
function UISubEqUpde:CheckCanUpStar()
    --  self._curCanUpLv
    --先判断 当前的
    if self._equip:GetGrade() >= self._curCanUpLv then
        return false
    end

    if self._curStrength >= self._curCanUpLv then
        return false
    end

    return true
end

function UISubEqUpde:GetBtnTextTran(tran)
    local textTran = CS.FindTrans(tran, "UIText")
    return textTran
end

--是否达到当前类型的最大的等级
function UISubEqUpde:CheckIsMax()
    local maxUp = gModelEquip:GetGradeUpLevelLimitLv(self._equipRef.type)
    return self._equip:GetGrade() >= maxUp
end

function UISubEqUpde:OnLongExpendItemClick(itemdata, itemdataInfo)
    -- 这里进行计算
    if not self._numExp then
        self._numExp = self._equip:GetExp()
    end

    local isLeft, leftNum = self:CheckNum(itemdata.refId)
    local useNum = gModelEquip:GetMaxCostItemNum_UpGrade(self._equip:GetGrade(), self._curCanUpLv, self._numExp, self._equipRef.type, itemdata, leftNum)

    self._culLongItem = itemdata
    self._curLongUseNum = useNum

    self._curLongTicker = 0
    local _timeKey = self._timeKey
    if not self:IsTimerExist(_timeKey) then
        self:TimerStart(_timeKey, 0.03, false, -1)
    end
end

--endregion --------------------------------------------------------------------------------------

--region 事件 --------------------------------------------------------------------------------

function UISubEqUpde:OnStrengthChange(data)
    self._equip = data.equip
    self:InitData()

    self:SetPanel()
    self:SetUseInfo()

    local index = data.index
    if index == 3 then
        self:CreateWndEffect(self.mBarEffect, "fx_ui_zhuangbei_up_1", "fx_ui_zhuangbei_up_1", 100, nil, nil, 1, nil, nil, true)
    end
end

function UISubEqUpde:SetBtnState()
    CS.ShowObject(self.mStrengthBtn, true)

    if self:CheckIsMax() then
        CS.ShowObject(self.mStrengthBtn, false)
        self:SetWndText(self.mExpendTips, ccClientText(44530))  --[44529] [點擊放入鑄魂材料]
    else
        self:SetWndText(self.mExpendTips, ccClientText(44529))  --[44529] [點擊放入鑄魂材料]
    end

end

function UISubEqUpde:SetAttr()
    local addAtr = (self._equipClassRef.selfAddAttr * 100) .. "%"
    self:SetWndText(self.mCurValue, addAtr)
end

function UISubEqUpde:OnSubItemClick_LongClick(itemdata)

    self:OnSubItemClick(itemdata, true)
end

function UISubEqUpde:SetStarState()

    local starCount = tonumber(self._equipRef.star)
    for i = 1, 5 do
        local img = i <= starCount and "equip_star1" or "equip_star2"
        local starTranKey = "Star_" .. i

        local starTran = CS.FindTrans(self.mStarRoot, starTranKey)

        self:SetWndEasyImage(starTran, img)
    end
end

--经验条
function UISubEqUpde:SetExp()
    --先设置中间的数字
    local curExp = self._equip:GetGradeExp()
    local nextExp = self._equipClassRef.upNeedExp

    local scale = self:CalcuPercent(curExp, nextExp)
    self.mBar_2.localScale = scale

    local isFull = false
    if nextExp == -1 then
        nextExp = 0
        isFull = true
    end

    local str
    if isFull then
        str = "<color=#31ff9f>EXP </color>Max "
        self.mBar_2.localScale = Vector3.New(1, 1, 1)
        self:SetAnchorPos(self.mBarNum, Vector2.New(60, 0))
    else
        str = string.format("<color=#31ff9f>EXP </color> %s/%s", curExp, nextExp)
        self:SetAnchorPos(self.mBarNum, Vector2.New(20, 0))
    end

    --60
    self:SetWndText(self.mBarNum, str)
end

function UISubEqUpde:OnStrengthClick()
    if self._isEmptyStrengthItem then
        --gModelGeneral:ShowCommonItemTipWnd(self._firstUseItem)

        gModelGeneral:OpenGetWayWnd({ itemId = self._firstUseItem.itemId })
        return
    end

    if self._equip:GetGrade() >= self._curCanUpLv then
        if self._curLimitLef and self._curLimitLef.upNeedStar > 0 then
            local str = string.replace(ccClientText(44527), self._curLimitLef.upNeedStar)
            GF.ShowMessage(str)  --[44520] [已達當前最大鑄魂等級，無法添加道具]
        else

            GF.ShowMessage(ccClientText(44520))  --[44520] [已達當前最大鑄魂等級，無法添加道具]

        end
        return
    end

    gModelEquip:OnEquipUpGradeReq(self._refId, self._id, self._useExpendItemInfo, self._haveExpendItemInfo)
end

function UISubEqUpde:SetEquipName()
    --名字
    local equipName = gModelEquip:GetNameByRefId(self._refId)

    local grade = self._equip:GetGrade()

    if grade > 0 then
        equipName = equipName .. string.format("+%s", grade)
    end

    self:SetWndText(self.mEquipNameText, ccLngText(equipName))
end

--添加的经验是否达到最大限制的等级
function UISubEqUpde:CheckAddIsCurMax()
    local maxUp = gModelEquip:GetGradeUpLevelLimitLv(self._equipRef.type)
    return self._curStrength >= maxUp
end

--ui Click

function UISubEqUpde:OnExpendItemClick_LongClick(itemdata, itemdataInfo)
    if not self._haveExpendItemInfo[itemdata.refId] then
        self._haveExpendItemInfo[itemdata.refId] = itemdataInfo
    end
    -- check
    if self:CheckIsMax() then
        GF.ShowMessage(ccClientText(44520))  -- [44520] [已達當前最大鑄魂等級，無法添加道具]
        return
    end

    if not self:CheckCanUpStar() then
        if self._curLimitLef and self._curLimitLef.upNeedStar > 0 then
            local str = string.replace(ccClientText(44527), self._curLimitLef.upNeedStar)
            GF.ShowMessage(str)  --[44520] [已達當前最大鑄魂等級，無法添加道具]
        else

            GF.ShowMessage(ccClientText(44520))  --[44520] [已達當前最大鑄魂等級，無法添加道具]

        end
        return
    end

    if self:CheckAddIsCurMax() then
        GF.ShowMessage(ccClientText(44520))   -- [44520] [已達當前最大鑄魂等級，無法添加道具]
        return
    end

    local isLeft, leftNum = self:CheckNum(itemdata.refId)
    if not isLeft then
        GF.ShowMessage(ccClientText(44515)) --[44515] [道具不足]
        return
    end

    if not self._isLongCalculate then
        self._isLongCalculate = true
        self:OnLongExpendItemClick(itemdata, itemdataInfo)
    end
end

function UISubEqUpde:SetEquipUpGradeInfo()
    local levelStr = gModelEquip:GetLevelDesStr(self._equip:GetGrade())
    self:SetWndText(self.mLevel, levelStr)

    --local limitLevel = gModelEquip:GetGradeUpLevelLimitLv(self._equipRef.type)
    local limitLevel = gModelEquip:GetEquipMaxUpGrade(self._equipRef)
    local limitStr = "Lv." .. limitLevel
    self._limitLevel = limitLevel
    self:SetWndText(self.mLevelLimitText, limitStr)
end

--region 页面初始化 --------------------------------------------------------------------------------
function UISubEqUpde:InitEvent()
    --event
    self:WndEventRecv(gModelEquip.EventArgs.StrengthChange, function(...)
        self:OnStrengthChange(...)
        self:OnRefreshItemInfo()
    end)

    --uiCLick
    self:SetWndClick(self.mStrengthBtn, function()
        self:OnStrengthClick()
    end)

    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:OnRefreshItemInfo()
    end)
end

function UISubEqUpde:InitText()
    self:SetWndText(self.mExpendTitleText, ccClientText(44521)) --[44521] [鑄魂材料]
    --self:SetWndText(self.mExpendTitleText, ccClientText(44504)) --[44513] [鑄魂材料]
    self:SetWndText(self.mAttrName, ccClientText(44514)) --[44514] [裝備全屬性加成：]


    self:SetWndText(self:GetBtnTextTran(self.mStrengthBtn), ccClientText(44502))  --[44502] [鑄 魂]

end

--设置下一级的提升
function UISubEqUpde:SetNextAttr(level)
    if nil == level or level == 0 then
        CS.ShowObject(self.mArrow, false)
        CS.ShowObject(self.mNextValue, false)
        return
    end

    CS.ShowObject(self.mArrow, true)
    CS.ShowObject(self.mNextValue, true)

    local upLevel = self._equip:GetGrade() + level
    local limitLevel = gModelEquip:GetGradeUpLevelLimitLv(self._equipRef.type)

    upLevel = upLevel > limitLevel and limitLevel or upLevel

    local ref = gModelEquip:GetUpGradeRef(self._equipRef.type, upLevel)
    local addAtr = (ref.selfAddAttr * 100) .. "%"
    self:SetWndText(self.mNextValue, addAtr)
end

--检查当前的道具是否用完
function UISubEqUpde:CheckNum(itemId)

    local usenum = self._useExpendItemInfo[itemId] or 0
    local leftNum = self._haveExpendItemInfo[itemId].itemNum - usenum

    return leftNum > 0, leftNum
end

function UISubEqUpde:OnSubItemClick(itemdata, isLong)
    if self._useExpendItemInfo[itemdata.refId] and self._useExpendItemInfo[itemdata.refId] > 0 then
        if isLong then
            self._useExpendItemInfo[itemdata.refId] = 0
            self._useExpendItemExp = 0
        else
            self._useExpendItemInfo[itemdata.refId] = self._useExpendItemInfo[itemdata.refId] - 1
            self._useExpendItemExp = self._useExpendItemExp - itemdata.addExp
        end

        self:SetUseInfo()
    end
end

function UISubEqUpde:CreateRecordList(list, item, itemdata, itempos)
    --
    local itemRoot = CS.FindTrans(item, "ItemIcon")
    local UIText = CS.FindTrans(item, "UIText")
    local UseBtn = CS.FindTrans(item, "UseBtn")
    local SubBtn = CS.FindTrans(item, "SubBtn")
    local ImgMask = CS.FindTrans(item, "ImgMask")
    local UseInfo = CS.FindTrans(item, "UseInfo")

    local t = {
        itemType = itemdata.itemType,
        itemId = itemdata.refId,

        isShowEff = 0,
    }

    -- 构建 item table
    if itemdata.itemType == LItemTypeConst.TYPE_ITEM then
        t.itemNum = gModelItem:GetNumByRefId(itemdata.refId) -- 这里取背包数据
    elseif itemdata.itemType == LItemTypeConst.TYPE_EQUIP then
        local equipdata = gModelEquip:GetEquipStructByRefId(itemdata.refId)
        t.itemNum = equipdata:GetNum()
    end

    local useNum = self._useExpendItemInfo[t.itemId] or 0

    local useStr = string.format("%s/%s", LUtil.NumberCoversion(useNum), LUtil.NumberCoversion(t.itemNum))
    self:SetWndText(UseInfo, useStr)

    if not self._itemUesInfo then
        self._itemUesInfo = {}
    end

    self._itemUesInfo[itemdata.refId] = UseInfo

    if not self._itemMask then
        self._itemMask = {}
    end

    self._itemMask[itemdata.refId] = ImgMask

    if not self._itemSubBtn then
        self._itemSubBtn = {}
    end
    self._itemSubBtn[itemdata.refId] = SubBtn

    local InstanceID = itemRoot:GetInstanceID()
    if not self._uiCommonList then
        self._uiCommonList = {}
    end
    if not self._itemBase then
        self._itemBase = {}
    end

    local baseClass = self._uiCommonList[InstanceID]

    if not baseClass then
        baseClass = CommonIcon:New()
        self._uiCommonList[InstanceID] = baseClass
        baseClass:Create(itemRoot)
    end

    baseClass:SetCommonReward(t.itemType, t.itemId, t.itemNum)
    baseClass:EnableShowNum(false)
    baseClass:DoApply()

    self._itemBase[itemdata.refId] = baseClass

    CS.ShowObject(ImgMask, t.itemNum == 0)
    local expStr
    if nil == itemdata.addExp then
        expStr = "EXP+0"
    else
        expStr = "EXP+" .. itemdata.addExp
    end
    self:SetWndText(UIText, expStr)
    self:SetWndClick(ImgMask, function()
        gModelGeneral:ShowCommonItemTipWnd(t)
    end)

    self:SetWndClick(itemRoot, function()
        self:OnExpendItemClick_NoLongClick(itemdata, t)
    end)

    self:SetWndClick(UseBtn, function()
        if t.itemNum == 0 then
            local itemId = t.itemId
            if t.itemType == LItemTypeConst.TYPE_EQUIP then
                itemId = 9003003
            end

            gModelGeneral:OpenGetWayWnd({ itemId = itemId })
        else
            self:OnExpendItemClick_NoLongClick(itemdata, t)
        end
    end)

    self:SetWndClick(SubBtn, function()
        self:OnSubItemClick_NoLongClick(itemdata, t)
    end)


    -- 长按
    self:SetWndLongClick(UseBtn, function()
        if t.itemNum == 0 then

        else
            self:OnExpendItemClick_LongClick(itemdata, t)
        end
    end, 0.9, true, 0, function()
        self._longClickTicker = 0
    end)

    self:SetWndLongClick(itemRoot, function()
        if t.itemNum == 0 then

        else
            self:OnExpendItemClick_LongClick(itemdata, t)
        end
    end, 0.9, true, 0, function()
        self._longClickTicker = 0
    end)

    self:SetWndLongClick(SubBtn, function()
        self:OnSubItemClick_LongClick(itemdata, t)
    end, 0.9, true, 0, function()
        self._longSubClickTicker = 0
    end)
end
--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UISubEqUpde:SetPanel()
    self:SetItemInfo()
    self:SetExpendItem()
end

function UISubEqUpde:OnTimer(key)
    if (self._timeKey == key) then
        self:SetTime()
    end
end

function UISubEqUpde:SetExpendItem()

    local showData = gModelEquip:GetUpGradeExpendItem(self._equipClassRef)

    local uiList = self._expendList

    self._isEmptyStrengthItem = false
    local count = #showData

    for k, v in ipairs(showData) do
        local num = 0
        if v.itemType == LItemTypeConst.TYPE_ITEM then
            num = gModelItem:GetNumByRefId(v.refId) -- 这里取背包数据
        elseif v.itemType == LItemTypeConst.TYPE_EQUIP then
            local equipdata = gModelEquip:GetEquipStructByRefId(v.refId)
            num = equipdata:GetNum()
        end

        if num == 0 then
            count = count - 1
        end

        if k == 1 then
            self._firstUseItem = {
                itemType = v.itemType,
                itemId = v.refId,
                itemNum = gModelItem:GetNumByRefId(v.refId), -- 这里取背包数据
                isShowEff = 0,
            }
        end
    end
    self._isEmptyStrengthItem = count <= 0

    if not uiList then
        uiList = self:GetUIScroll(self.mExpendItemList:GetInstanceID())
        uiList:Create(self.mExpendItemList, showData, function(...)
            self:CreateRecordList(...)
        end, UIItemList.SUPER)

        self._expendList = uiList
    else
        uiList:RefreshList(showData)
        uiList:DrawAllItems(true)
    end
    uiList:EnableScroll(true, true)
end


--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UISubEqUpde