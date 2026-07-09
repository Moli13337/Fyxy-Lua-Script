---
--- Created by Administrator.
--- DateTime: 2024/7/8 17:27:09
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubEqStrength:LChildWnd
local UISubEqStrength = LxWndClass("UISubEqStrength", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubEqStrength:UISubEqStrength()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubEqStrength:OnWndClose()
    self:TimerStop(self._timeKey)
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubEqStrength:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubEqStrength:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitPara()
    self:InitData()
    self:InitText()

end

function UISubEqStrength:InitText()
    self:SetWndText(self.mExpendTitleText, ccClientText(44503)) --[44503] [强化材料]

    self:SetWndText(self:GetBtnTextTran(self.mOneKeyAddBtn), ccClientText(44505))  --[44505] [一鍵添加]
    self:SetWndText(self:GetBtnTextTran(self.mStrengthBtn), ccClientText(44500))  --[44500] [强 化]
    self:SetWndText(self:GetBtnTextTran(self.mRefineBtn), ccClientText(44508))  --[44500] [强 化]
end

function UISubEqStrength:OnSubItemClick_LongClick(itemdata)

    self:OnSubItemClick(itemdata, true)
end

function UISubEqStrength:OnSubItemClick_NoLongClick(itemdata)
    self._longSubClickTicker = 0
    self:OnSubItemClick(itemdata)
end

function UISubEqStrength:InitData()
    self._refId = self._equip:GetRefId()
    self._id = self._equip:GetId()

    self._equipRef = gModelEquip:GetEquipRefByRefId(self._refId)
    self._strengthType = gModelEquip:GetEquipStrengthType(self._equipRef)

    self._equipStrengthRef = gModelEquip:GetEquipStrengthRef(self._strengthType, self._equip:GetLevel())

    local curRefineId = self._equip:GetRefineRefId()
    if curRefineId == 0 then
        self._limitRef = gModelEquip:GetRefineLevelRef(curRefineId, self._strengthType)
    else
        local curRefineRefId = gModelEquip:GetRefineLevelRef(curRefineId, self._strengthType)
        self._limitRef = gModelEquip:GetRefineLevelRefByLv(curRefineRefId.lvMax, self._strengthType)
    end

    self._useExpendItemExp = 0
    self._useExpendItemInfo = {}
    --当前总归的提升等级
    self._curStrength = 0
    --直接开始调用界面的刷新
    self:SetItemInfo()

    self._longClickTicker = 0 --长按计数
    self._longSubClickTicker = 0
    self._isLongCalculate = false
    self._timeKey = "UISubEqStrength_LongClickTimerKey"
end

--提升属性
function UISubEqStrength:SetNextAttr(level)
    if nil == level or level == 0 then
        CS.ShowObject(self.mArrow, false)
        CS.ShowObject(self.mNextValue, false)
        return
    end

    CS.ShowObject(self.mArrow, true)
    CS.ShowObject(self.mNextValue, true)

    local upLevel = self._equip:GetLevel() + level
    local limitLevel = gModelEquip:GetEquipStrengLimitLv(self._strengthType)

    upLevel = upLevel > limitLevel and limitLevel or upLevel

    local ref = gModelEquip:GetEquipStrengthRef(self._strengthType, upLevel)

    local attrInfo = gModelEquip:ParseEquipAttrInfo(ref.attrAdd)

    self:SetWndText(self.mNextValue, attrInfo.value)
end


--经验条
function UISubEqStrength:SetExp()
    --先设置中间的数字
    local curExp = self._equip:GetExp()
    local nextExp = self._equipStrengthRef.upNeedExp

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
    self:SetWndText(self.mBarNum, str)
end

--ui Click
function UISubEqStrength:OnExpendItemClick_LongClick(itemdata)
    --进行判断 当前装备等级是否达到最大
    if self:CheckIsMax() then
        GF.ShowMessage(ccClientText(44506))
        return
    end

    if self:CheckIsCurMax() then
        --打开精炼的页面
        GF.OpenWnd("UIEqRefine", { equip = self._equip, limitRef = self._limitRef })
        return
    end

    if self:CheckAddIsCurMax() then
        GF.ShowMessage(ccClientText(44506))
        return
    end
    local isLeft, leftNum = self:CheckNum(itemdata.refId)
    if not isLeft then
        GF.ShowMessage(ccClientText(44515)) --[44515] [道具不足]
        return
    end

    if not self._isLongCalculate then
        self._isLongCalculate = true
        self:OnLongExpendItemClick(itemdata)
    end
end
--endregion --------------------------------------------------------------------------------------

--region 页面的check的方法 --------------------------------------------------------------------------------
--检查当前的道具是否用完
function UISubEqStrength:CheckNum(itemId)
    local usenum = self._useExpendItemInfo[itemId] or 0
    local leftNum = gModelItem:GetNumByRefId(itemId) - usenum

    return leftNum > 0, leftNum
end

function UISubEqStrength:OnSubItemClick(itemdata, isLong)
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

--region 页面初始化 --------------------------------------------------------------------------------
function UISubEqStrength:InitPara()
    self._refId = self:GetWndArg("refId")
    self._id = self:GetWndArg("id")
    self._equip = self:GetWndArg("equip")
end

--是否达到当前类型的最大的等级
function UISubEqStrength:CheckIsMax()
    local maxUp = gModelEquip:GetEquipStrengLimitLv(self._strengthType)
    return self._equip:GetLevel() >= maxUp
end

function UISubEqStrength:OnTimer(key)
    if (self._timeKey == key) then
        self:SetTime()
    end
end
function UISubEqStrength:SetTime()
    local itemdata = self._culLongItem
    if self._curLongTicker >= 10 then
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

function UISubEqStrength:InitEvent()
    --event
    self:WndEventRecv(gModelEquip.EventArgs.StrengthChange, function(...)
        self:OnStrengthChange(...)
        self:OnRefreshItemInfo()
    end)

    --uiCLick
    self:SetWndClick(self.mStrengthBtn, function()
        self:OnStrengthClick()
    end)

    self:SetWndClick(self.mOneKeyAddBtn, function()
        self:OnOneKeyAddClick()
    end)

    self:SetWndClick(self.mRefineBtn, function()
        self:OnRefineBtnClick()
    end)

    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:OnRefreshItemInfo()
    end)
end

--添加的经验是否达到限制的等级
function UISubEqStrength:CheckAddIsCurMax()
    local max = self._limitRef.lv

    if max == -1 then
        max = gModelEquip:GetEquipStrengLimitLv(self._strengthType)
    end

    return self._curStrength >= max
end

function UISubEqStrength:OnStrengthClick()
    if self:CheckIsMax() then
        GF.ShowMessage(ccClientText(44506))
        return
    end

    if self._isEmptyStrengthItem then
        --gModelGeneral:ShowCommonItemTipWnd(self._firstUseItem)
        local notEnoughEquipId= gModelEquip:GetEquipCfgRefByKey("equipGetWay")
        gModelGeneral:OpenGetWayWnd({ itemId =notEnoughEquipId or  self._firstUseItem.itemId })
        return
    end

    if not table.isempty(self._useExpendItemInfo) then
        gModelEquip:OnEquipStrengthReq(self._refId, self._id, self._useExpendItemInfo, self._equip)
    else
        GF.ShowMessage(ccClientText(44523))
    end
end
--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
--data Change

function UISubEqStrength:OnStrengthChange(data)
    self._equip = data.equip

    self:InitData()
    self:SetUseInfo()

    self:SetEquipName()
    local index = data.index
    if index == 1 then
        self:CreateWndEffect(self.mBarEffect, "fx_ui_zhuangbei_up_1", "fx_ui_zhuangbei_up_1", 100, nil, nil, 1, nil, nil, true)
    end
end

function UISubEqStrength:SetBtnState()
    CS.ShowObject(self.mRefineBtn, false)
    CS.ShowObject(self.mStrengthBtn, true)
    CS.ShowObject(self.mOneKeyAddBtn, true)

    self:SetWndText(self.mExpendTips, ccClientText(44504)) --[44504] [長按可快速添加強化材料]


    if self:CheckIsMax() then
        CS.ShowObject(self.mOneKeyAddBtn, false)
        CS.ShowObject(self.mStrengthBtn, false)
        CS.ShowObject(self.mRefineBtn, false)

        self:SetWndText(self.mExpendTips, ccClientText(44524)) --[44524] [已强化到最高级]
        return
    end

    if self:CheckIsCurMax() then
        CS.ShowObject(self.mRefineBtn, true)
        CS.ShowObject(self.mStrengthBtn, false)

        local isShowRed = gModelEquip:GetEquipStrengthRedPoint(self._equip)
        local redPoint = CS.FindTrans(self.mRefineBtn,"redPoint")
        CS.ShowObject(redPoint,isShowRed)
    end
end

function UISubEqStrength:OnRefreshItemInfo()
    local showData = gModelItem:GetEquipStrengthItem_1()

    self._isEmptyStrengthItem = false

    local count = #showData

    for k, itemdata in ipairs(showData) do
        local t = {
            itemType = itemdata.itemType,
            itemId = itemdata.refId,
            itemNum = gModelItem:GetNumByRefId(itemdata.refId), -- 这里取背包数据
            isShowEff = 0,
        }

        if t.itemNum == 0 then
            count = count - 1
        end

        local itemId = t.itemId
        local useNum = self._useExpendItemInfo[t.itemId] or 0
        local tran = self._itemUesInfo[itemId]
        local num = gModelItem:GetNumByRefId(itemId) - useNum
        local useStr = string.format("%s/%s", LUtil.NumberCoversion(useNum), LUtil.NumberCoversion(gModelItem:GetNumByRefId(itemId)))
        self:SetWndText(tran, useStr)

        local maskTran = self._itemMask[itemId]
        CS.ShowObject(maskTran, num <= 0)
        local subTran = self._itemSubBtn[itemId]
        CS.ShowObject(subTran, useNum > 0)
    end

    self._isEmptyStrengthItem = count <= 0
end
--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UISubEqStrength:SetItemInfo()
    --名字
    self:SetEquipName()
    --星星
    self:SetStarState()
    --icon
    self:SetEquipItem()
    --强化等级
    self:SetEquipStrengInfo()
    --经验
    self:SetExp()
    --属性
    self:SetAttr()
    --强化材料
    self:SetExpendItem()

    --设置按钮状态
    self:SetBtnState()
end

function UISubEqStrength:OnLongExpendItemClick(itemdata)
    -- 这里进行计算
    if not self._numExp then
        self._numExp = self._equip:GetExp()
    end

    local isLeft, leftNum = self:CheckNum(itemdata.refId)
    local useNum = gModelEquip:GetMaxCostItemNum_Strength(self._equip:GetLevel(), self._limitRef.lv, self._numExp, self._strengthType, itemdata, leftNum)

    self._culLongItem = itemdata
    self._curLongUseNum = useNum
    self._curLongTicker = 0
    local _timeKey = self._timeKey
    if not self:IsTimerExist(_timeKey) then
        self:TimerStart(_timeKey, 0.03, false, -1)
    end
end

function UISubEqStrength:GetBtnTextTran(tran)
    local textTran = CS.FindTrans(tran, "UIText")
    return textTran
end

--是否达到装备的限制等级
function UISubEqStrength:CheckIsCurMax()
    return self._equip:GetLevel() >= self._limitRef.lv
end

function UISubEqStrength:SetUseInfo()
    --计算提示的等级
    local numExp = self._equip:GetExp()
    numExp = self._useExpendItemExp + numExp

    self._numExp = numExp

    local nextExp = self._equipStrengthRef.upNeedExp

    local scale = self:CalcuPercent(numExp, nextExp)
    self.mBar_1.localScale = scale

    local isFull = false
    if nextExp == -1 then
        nextExp = 0
        isFull = true
    end

    if isFull then
        str = "<color=#31ff9f>EXP </color>Max "
        self.mBar_2.localScale = Vector3.New(1, 1, 1)
        self:SetAnchorPos(self.mBarNum, Vector2.New(60, 0))
    else
        str = string.format("<color=#31ff9f>EXP </color> %s/%s", numExp, nextExp)
        self:SetAnchorPos(self.mBarNum, Vector2.New(20, 0))
    end
    self:SetWndText(self.mBarNum, str)


    --道具的设置部分
    for itemId, useNum in pairs(self._useExpendItemInfo) do
        local num = gModelItem:GetNumByRefId(itemId) - useNum
        --self._itemBase[itemId]:SetCommonReward(1, itemId, num)
        --
        --self._itemBase[itemId]:DoApply()

        local tran = self._itemUesInfo[itemId]

        local useStr = string.format("%s/%s", LUtil.NumberCoversion(useNum), LUtil.NumberCoversion(gModelItem:GetNumByRefId(itemId)))
        self:SetWndText(tran, useStr)

        local maskTran = self._itemMask[itemId]
        CS.ShowObject(maskTran, num <= 0)
        local subTran = self._itemSubBtn[itemId]
        CS.ShowObject(subTran, useNum > 0)
    end

    local upLevel = gModelEquip:GetStrengthUpLevel(numExp, self._equip:GetLevel(), self._strengthType)
    local uplevelNum = upLevel - self._equip:GetLevel()

    self._curStrength = upLevel

    CS.ShowObject(self.mUpText, uplevelNum > 0)
    if uplevelNum > 0 then
        self:SetWndText(self.mUpText, " +" .. uplevelNum)
    end

    self:SetNextAttr(uplevelNum)
end

function UISubEqStrength:SetEquipStrengInfo()
    local levelStr = gModelEquip:GetLevelDesStr(self._equip._level)
    self:SetWndText(self.mLevel, levelStr)

    local limitLevel = self._limitRef.lv
    local limitStr = "Lv." .. limitLevel
    self:SetWndText(self.mLevelLimitText, limitStr)
end

function UISubEqStrength:OnRefineBtnClick()
    GF.OpenWnd("UIEqRefine", { equip = self._equip, limitRef = self._limitRef })
end
function UISubEqStrength:OnExpendItemClick_NoLongClick(itemdata)
    self._longClickTicker = 0
    self:OnExpendItemClick(itemdata)
end

function UISubEqStrength:SetEquipName()
    local equipName = gModelEquip:GetNameByRefId(self._refId)

    local grade = self._equip:GetGrade()

    if grade > 0 then
        equipName = equipName .. string.format("+%s", grade)
    end

    self:SetWndText(self.mEquipName, ccLngText(equipName))
end

--计算一个百分比
function UISubEqStrength:CalcuPercent(curValue, nextValue)
    local percent = curValue / nextValue
    percent = percent > 1 and 1 or percent

    percent = percent < 0 and 1 or percent

    return Vector3.New(percent, 1, 1)
end

function UISubEqStrength:SetExpendItem()
    local showData = gModelItem:GetEquipStrengthItem_1()

    self._isEmptyStrengthItem = false

    local count = #showData

    for k, v in ipairs(showData) do

        local num = gModelItem:GetNumByRefId(v.refId)
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

    local uiList = self._expendList

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
    uiList:EnableScroll(false, true)

end

function UISubEqStrength:SetStarState()
    local starCount = tonumber(self._equipRef.star)
    for i = 1, 5 do
        local img = i <= starCount and "equip_star1" or "equip_star2"
        local starTranKey = "Star_" .. i

        local starTran = CS.FindTrans(self.mStarRoot, starTranKey)

        self:SetWndEasyImage(starTran, img)
    end
end

--属性  --分为两块 一个是当前 一个是 Up 之后
function UISubEqStrength:SetAttr()
    local attrInfo = gModelEquip:ParseEquipAttrInfo(self._equipStrengthRef.attrAdd)

    self:SetWndEasyImage(self.mAttrIcon, attrInfo.icon)
    self:SetWndText(self.mAttrName, attrInfo.attrName)
    self:SetWndText(self.mCurValue, attrInfo.value)
end

function UISubEqStrength:SetEquipItem()
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

function UISubEqStrength:CreateRecordList(list, item, itemdata, itempos)
    --
    local itemRoot = CS.FindTrans(item, "ItemIcon")
    local UIText = CS.FindTrans(item, "UIText")
    local UseBtn = CS.FindTrans(item, "UseBtn")
    local SubBtn = CS.FindTrans(item, "SubBtn")
    local ImgMask = CS.FindTrans(item, "ImgMask")
    local UseInfo = CS.FindTrans(item, "UseInfo")

    itemRoot.localScale = Vector3.one * 0.85

    local t = {
        itemType = itemdata.itemType,
        itemId = itemdata.refId,
        itemNum = gModelItem:GetNumByRefId(itemdata.refId), -- 这里取背包数据
        isShowEff = 0,
    }

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

    if not self._itemSubBtn then
        self._itemSubBtn = {}
    end
    self._itemSubBtn[itemdata.refId] = SubBtn

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
        self:OnExpendItemClick_NoLongClick(itemdata)
    end)

    self:SetWndClick(UseBtn, function()
        if t.itemNum == 0 then
            gModelGeneral:OpenGetWayWnd({ itemId = t.itemId })
        else
            self:OnExpendItemClick_NoLongClick(itemdata)
        end
    end)

    self:SetWndClick(SubBtn, function()
        self:OnSubItemClick_NoLongClick(itemdata)
    end)


    -- 长按
    self:SetWndLongClick(UseBtn, function()
        if t.itemNum == 0 then

        else
            self:OnExpendItemClick_LongClick(itemdata)
        end
    end, 0.9, true, 0, function()
        self._longClickTicker = 0
    end)

    self:SetWndLongClick(itemRoot, function()
        if t.itemNum == 0 then

        else
            self:OnExpendItemClick_LongClick(itemdata)
        end
    end, 0.9, true, 0, function()
        self._longClickTicker = 0
    end)

    self:SetWndLongClick(SubBtn, function()
        self:OnSubItemClick_LongClick(itemdata)
    end, 0.9, true, 0, function()
        self._longSubClickTicker = 0
    end)
end

function UISubEqStrength:OnExpendItemClick(itemdata)
    --进行判断 当前装备等级是否达到最大
    if self:CheckIsMax() then
        GF.ShowMessage(ccClientText(44506))
        return
    end

    if self:CheckIsCurMax() then
        --打开精炼的页面
        GF.OpenWnd("UIEqRefine", { equip = self._equip, limitRef = self._limitRef })
        return
    end

    if self:CheckAddIsCurMax() then
        GF.ShowMessage(ccClientText(44506))
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

function UISubEqStrength:OnOneKeyAddClick()

    if self._isEmptyStrengthItem then
        --gModelGeneral:ShowCommonItemTipWnd(self._firstUseItem)
        local notEnoughEquipId= gModelEquip:GetEquipCfgRefByKey("equipGetWay")
        gModelGeneral:OpenGetWayWnd({ itemId =notEnoughEquipId or  self._firstUseItem.itemId })
        return
    end

    if self:CheckIsCurMax() then
        GF.ShowMessage(ccClientText(44528))
        return
    end

    self._useExpendItemInfo = {}
    self:SetExpendItem()
    --计算所需要的经验
    local numExp = self._equip:GetExp()
    --local nextExp = self._equipStrengthRef.upNeedExp

    local nextExp = gModelEquip:GetStrengthUpLimitLevelCostExp(self._equip:GetLevel(), self._limitRef.lv, self._strengthType)
    local needExp = nextExp - numExp

    self._useExpendItemInfo, self._useExpendItemExp = gModelEquip:GetOneKeyStrengthExpend(needExp)

    self:SetUseInfo()
end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UISubEqStrength