---
--- Created by Administrator.
--- DateTime: 2024/7/8 20:46:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEqRefine:LWnd
local UIEqRefine = LxWndClass("UIEqRefine", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEqRefine:UIEqRefine()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEqRefine:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEqRefine:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEqRefine:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitText()
    self:InitPara()
    self:InitData()

end

function UIEqRefine:SetEquipItem()
    local baseClass = self._baseEquipIcon

    if not self._baseEquipIcon then
        baseClass = CommonIcon:New()
        baseClass:Create(self.mEquip)

        self._baseEquipIcon = baseClass
    end

    baseClass:SetCommonReward(LItemTypeConst.TYPE_EQUIP, self._refId, 0, nil, true)
    baseClass:EnableShowNum(false)
    baseClass:EnableShowStarRoot(true)
    baseClass:DoApply()

    local level = self._equip:GetLevel()
    baseClass:SetEquipExtension(level)
end
--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIEqRefine:SetPanel()
    self:SetItemInfo()
    self:SetAttr()

    self:SetExpendItem()
end

function UIEqRefine:SetAttr()
    local lvData = {}
    lvData.image = "equip_lv"
    lvData.name = ccClientText(44511)
    lvData.cur = self._limitRef.lv
    lvData.next = self._limitRef.lvMax
    local arrData = {}

    local attrInfo_2 = gModelEquip:ParseEquipAttrInfo(self._limitRef.attrAdd1)

    arrData.image = attrInfo_2.icon
    arrData.name = attrInfo_2.attrName

    arrData.next = attrInfo_2.value

    local refineId = self._equip:GetRefineRefId()

    if refineId > 0 then
        local attrInfo_1 = gModelEquip:ParseEquipAttrInfo(self._curRefineRef.attrAdd1)
        arrData.cur = attrInfo_1.value

    else
        arrData.cur = 0

    end

    self:SetAttrTran(self.mLevel, lvData)
    self:SetAttrTran(self.mAttr, arrData)
end

--设置道具
function UIEqRefine:SetItemInfo()
    self:SetEquipItem()
    self:SetEquipName()

end

function UIEqRefine:InitText()
    self:SetWndText(self.mTitleText, ccClientText(44507)) --[44507] [裝備精煉]
    self:SetWndText(self.mTZAttrTxt_1, ccClientText(44509)) --[44509] [精煉結果]
    self:SetWndText(self.mTZAttrTxt_2, ccClientText(44510)) --[44510] [精煉材料]

    self:SetWndText(self:GetBtnTextTran(self.mRefineBtn), ccClientText(44508))  --[44508] [精 煉]
end

function UIEqRefine:SetExpendItem()

    local showData = {}
    local temp_item =string.split(self._limitRef.itemCost,",")

    for k,v in ipairs(temp_item) do
        local item = LxDataHelper.ParseItem_4(v)
        table.insert(showData, item)
    end

    self._isEmptyStrengthItem = false

    self._firstUseItem = nil

    local haveItemNoEnough=false
    local count = #showData

    for k, v in ipairs(showData) do

        local num = gModelItem:GetNumByRefId(v.itemId)

        if not haveItemNoEnough then
            haveItemNoEnough = num<v.itemNum
        end
        if num == 0 then
            count = count - 1
        end

        if haveItemNoEnough and (not   self._firstUseItem) then
            self._firstUseItem = {
                itemType = v.itemType,
                itemId = v.itemId,
                itemNum = gModelItem:GetNumByRefId(v.refId), -- 这里取背包数据
                isShowEff = 0,
            }
        end
    end
    self._isEmptyStrengthItem =haveItemNoEnough


    self._refineData = showData

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
    uiList:EnableScroll(true, true)
end

--endregion --------------------------------------------------------------------------------------

--region 事件 --------------------------------------------------------------------------------
--ui
function UIEqRefine:OnRefineBtnClick()
    --判断是不是足够材料 --不够材料 要进行其他的处理
    if self._isEmptyStrengthItem then
        --gModelGeneral:ShowCommonItemTipWnd(self._firstUseItem)
        gModelGeneral:OpenGetWayWnd({ itemId = self._firstUseItem.itemId })
        return
    end

    gModelEquip:OnEquipStrengthReq_Refine(self._refId, self._id, self._refineData)
end

function UIEqRefine:SetEquipName()
    --名字
    local equipName = gModelEquip:GetNameByRefId(self._refId)
    local grade= self._equip:GetGrade()
    if grade> 0 then
        equipName=string.format("%s +%s",equipName,grade)
    end
    self:SetWndText(self.mEquipNameText, ccLngText(equipName))

    local lvStr = "Lv." .. self._equip:GetLevel()
    self:SetWndText(self.mLvTxt, lvStr)
end

function UIEqRefine:CreateRecordList(list, item, itemdata, itempos)
    --
    local itemRoot = CS.FindTrans(item, "Icon")
    local Num = CS.FindTrans(item, "Num")

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

    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)

    baseClass:DoApply()

    self:SetWndClick(itemRoot, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)

    local have = gModelItem:GetNumByRefId(itemdata.itemId)

    local str = LUtil.FormatColorStr(have, have >= itemdata.itemNum and "lightGreen" or "lightRed")

    local numStr = string.format("%s/%s", str, itemdata.itemNum)

    self:SetWndText(Num, numStr)
end

function UIEqRefine:InitData()
    self._refId = self._equip:GetRefId()
    self._id = self._equip:GetId()

    self._equipRef = gModelEquip:GetEquipRefByRefId(self._refId)
    self._strengthType = gModelEquip:GetEquipStrengthType(self._equipRef)
    self._nextRef = gModelEquip:GetRefineLevelRefByLv(self._limitRef.lvMax, self._strengthType)

    local refineId = self._equip:GetRefineRefId()
    if refineId == 0 then
        self._curRefineRef = nil
    else
        self._curRefineRef = gModelEquip:GetRefineLevelRef(refineId, self._strengthType)
    end

    self:SetPanel()
end

function UIEqRefine:SetAttrTran(tran, data)
    local Icon = CS.FindTrans(tran, "Icon")
    local Name = CS.FindTrans(tran, "Name")
    local Cur = CS.FindTrans(tran, "Cur")
    local Next = CS.FindTrans(tran, "Next")

    self:SetWndEasyImage(Icon, data.image)
    self:SetWndText(Name, data.name)
    self:SetWndText(Cur, data.cur)
    self:SetWndText(Next, data.next)
end

function UIEqRefine:GetBtnTextTran(tran)
    local textTran = CS.FindTrans(tran, "UIText")
    return textTran
end

--region 页面初始化 --------------------------------------------------------------------------------
function UIEqRefine:InitEvent()
    --uiclick

    self:SetWndClick(self.mRefineBtn, function()
        self:OnRefineBtnClick()
        self:WndClose()
    end)

    self:SetWndClick(self.mBg, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIEqRefine:InitPara()
    self._equip = self:GetWndArg("equip")
    self._limitRef = self:GetWndArg("limitRef")

end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIEqRefine