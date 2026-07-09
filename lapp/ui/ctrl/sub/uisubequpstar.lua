---
--- Created by Administrator.
--- DateTime: 2024/7/8 20:13:02
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubEqUpStar:LChildWnd
local UISubEqUpStar = LxWndClass("UISubEqUpStar", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubEqUpStar:UISubEqUpStar()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubEqUpStar:OnWndClose()
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubEqUpStar:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubEqUpStar:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitText()
    self:InitPara()
    self:InitData()

    self:SetPanel()


end
--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------
function UISubEqUpStar:OnStrengthChange(data)
    self._equip = data.equip

    self:InitData()
    self:SetPanel()
    local index = data.index
    if index == 2 then
        self:CreateWndEffect(self.mEquipEffect, "fx_ui_zhuangbei_up_2", "fx_ui_zhuangbei_up_2", 100, nil, nil, 1, nil, nil, true)
    end
end

--SetWndClick
function UISubEqUpStar:OnUpstarBtnClick()
    if self._isEmptyStrengthItem then
        --gModelGeneral:ShowCommonItemTipWnd(self._firstUseItem)

        gModelGeneral:OpenGetWayWnd({ itemId = self._firstUseItem.itemId })
        return
    end

    gModelEquip:OnEquipUpStarReq(self._refId, self._id)
end

function UISubEqUpStar:OnRefreshItemInfo()
    if not self._showData then
        return
    end

    self._isEmptyStrengthItem = false
    local haveItemNoEnough=false
    local count = #self._showData

    for k, itemdata in ipairs(self._showData) do
        local Num = self._itemUesInfo[itemdata.itemId]
        local have = gModelItem:GetNumByRefId(itemdata.itemId)
        if have == 0 then
            count = count - 1
        end
        if Num then
            local str = LUtil.FormatColorStr(have, have >= itemdata.itemNum and "lightGreen" or "lightRed")

            local numStr = string.format("%s/%s", str, itemdata.itemNum)
            --

            self:SetWndText(Num, numStr)

            if not self._itemUesInfo then
                self._itemUesInfo = {}
            end
        end

        if not haveItemNoEnough then
            haveItemNoEnough = have<itemdata.itemNum
        end
    end

    --self._isEmptyStrengthItem = count <= 0
    self._isEmptyStrengthItem = haveItemNoEnough
end

function UISubEqUpStar:GetBtnTextTran(tran)
    local textTran = CS.FindTrans(tran, "UIText")
    return textTran
end

function UISubEqUpStar:SetEquipName()
    --名字
    local equipName = gModelEquip:GetNameByRefId(self._refId)

    local grade = self._equip:GetGrade()

    if grade > 0 then
        equipName = equipName .. string.format("+%s", grade)
    end
    self:SetWndText(self.mEquipNameText, ccLngText(equipName))
end

function UISubEqUpStar:SetAttrTran(tran, curData, nextData)
    local AttrIcon = CS.FindTrans(tran, "AttrIcon")
    local AttrName = CS.FindTrans(tran, "AttrName")
    local CurValue = CS.FindTrans(tran, "CurValue")
    local Arrow = CS.FindTrans(tran, "Arrow")
    local NextValue = CS.FindTrans(tran, "NextValue")

    self:SetWndEasyImage(AttrIcon, curData.icon)
    self:SetWndText(AttrName, curData.attrName)
    self:SetWndText(CurValue, curData.value)

    if nil == nextData then
        CS.ShowObject(Arrow, false)
        CS.ShowObject(NextValue, false)
    else
        CS.ShowObject(Arrow, true)
        CS.ShowObject(NextValue, true)

        self:SetWndText(NextValue, nextData.value)
    end
end

--region 页面初始化 --------------------------------------------------------------------------------
function UISubEqUpStar:InitEvent()
    --event
    self:WndEventRecv(gModelEquip.EventArgs.StrengthChange, function(data)
        self:OnStrengthChange(data)
    end)


    --uiCLick
    self:SetWndClick(self.mUpstarBtn, function()
        self:OnUpstarBtnClick()
    end)

    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:OnRefreshItemInfo()
    end)
end



function UISubEqUpStar:SetEquipItem()
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

--设置道具消耗的部分
function UISubEqUpStar:SetExpendItem()
    local showData = {}
    local temp_item = string.split(self._equipRef.starCost, ",")

    if tonumber(self._equipRef.starCost) == -1 then
        CS.ShowObject(self.mUpstarBtn, false)
        CS.ShowObject(self.mNoRef, true)
        CS.ShowObject(self.mExpendItemList, false)
        return
    end
    CS.ShowObject(self.mUpstarBtn, true)
    CS.ShowObject(self.mNoRef, false)
    CS.ShowObject(self.mExpendItemList, true)

    for k, v in ipairs(temp_item) do
        local item = LxDataHelper.ParseItem_4(v)
        table.insert(showData, item)
    end

    self._showData = showData

    self._isEmptyStrengthItem = false

    local haveItemNoEnough=false
    local count = #showData
    for k, v in ipairs(showData) do
        local num = gModelItem:GetNumByRefId(v.itemId)

        if not haveItemNoEnough then
            haveItemNoEnough = num<v.itemNum
        end
        if k == 1 then
            self._firstUseItem = {
                itemType = v.itemType,
                itemId = v.itemId,
                itemNum = gModelItem:GetNumByRefId(v.itemId), -- 这里取背包数据
                isShowEff = 0,
            }
        end
    end

    self._isEmptyStrengthItem = haveItemNoEnough
    self._upStarData = showData

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

function UISubEqUpStar:InitPara()
    self._refId = self:GetWndArg("refId")
    self._id = self:GetWndArg("id")
    self._equip = self:GetWndArg("equip")
end

function UISubEqUpStar:CreateRecordList(list, item, itemdata, itempos)
    if not itemdata.itemId then
        return
    end

    --
    local itemRoot = CS.FindTrans(item, "ItemIcon")
    local Num = CS.FindTrans(item, "UIText")

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

    if not self._itemUesInfo then
        self._itemUesInfo = {}
    end

    self._itemUesInfo[itemdata.itemId] = Num
end
--endregion --------------------------------------------------------------------------------------

--region  页面初始化--------------------------------------------------------------------------------
function UISubEqUpStar:SetPanel()
    self:SetItemInfo()

    self:SetExpendItem()
end

function UISubEqUpStar:SetAttr()
    --解析属性
    local curAttrTemp_1 = string.split(self._equipRef.attr, ",")

    local curAttrTemp_2 = {}

    for k, v in ipairs(curAttrTemp_1) do
        local attrInfo = gModelEquip:ParseEquipAttrInfo(v)

        table.insert(curAttrTemp_2, attrInfo)
    end

    local nextAttrTemp = {}
    if self._equipNextStarRef then
        local nextAttrTemp_1 = string.split(self._equipNextStarRef.attr, ",")

        for k, v in ipairs(nextAttrTemp_1) do
            local attrInfo = gModelEquip:ParseEquipAttrInfo(v)

            table.insert(nextAttrTemp, attrInfo)
        end
    end

    self:SetAttrTran(self.mUpAttrRoot_1, curAttrTemp_2[1], nextAttrTemp[1])
    self:SetAttrTran(self.mUpAttrRoot_2, curAttrTemp_2[2], nextAttrTemp[2])
end
function UISubEqUpStar:SetItemInfo()
    self:SetEquipItem()
    self:SetEquipName()
    --星星
    self:SetStarState()
    --属性
    self:SetAttr()

end

function UISubEqUpStar:SetStarState()

    local starCount = tonumber(self._equipRef.star)
    for i = 1, 5 do
        local img = i <= starCount and "equip_star1" or "equip_star2"
        local starTranKey = "Star_" .. i

        local starTran = CS.FindTrans(self.mStarRoot, starTranKey)

        self:SetWndEasyImage(starTran, img)
    end
end

function UISubEqUpStar:InitData()
    self._refId = self._equip:GetRefId()
    self._id = self._equip:GetId()

    self._equipRef = gModelEquip:GetEquipRefByRefId(self._refId)
    self._nextRefId = self._equipRef.nextStar
    if self._nextRefId > 0 then
        self._equipNextStarRef = gModelEquip:GetEquipRefByRefId(self._nextRefId)
    end
end

function UISubEqUpStar:InitText()
    self:SetWndText(self.mUpStarTitleText, ccClientText(44512)) --[44512] [升星效果]
    self:SetWndText(self.mExpendTitleText, ccClientText(44513)) --[44513] [升星材料]
    self:SetWndText(self.mNoRef, ccClientText(44516)) --[44516] [已達到最大升星階段]

    self:SetWndText(self:GetBtnTextTran(self.mUpstarBtn), ccClientText(44501))  --[44501] [升 星]

end
--endregion -------------------------------------------------------------------------------------
------------------------------------------------------------------
return UISubEqUpStar