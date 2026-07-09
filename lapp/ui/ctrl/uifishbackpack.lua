---
--- Created by wzz.
--- DateTime: 2024/8/7 17:28:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishBackpack:LWnd
local UIFishBackpack = LxWndClass("UIFishBackpack", LWnd)

local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
------------------------------------------------------------------

local function Sort(a, b)
    return a.ref.refId < b.ref.refId
end

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishBackpack:UIFishBackpack()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishBackpack:OnWndClose()
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishBackpack:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishBackpack:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitTexts()
    self:InitEvents()
    self:InitTimer()
    self:Refresh()
end

-- 初始事件
function UIFishBackpack:InitEvents()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
    self:WndEventRecv(EventNames.FISH_BASE_INFO, function(...)
        self:Refresh(...)
    end)
end

-- 列表 item
function UIFishBackpack:OnDrawItem(uilist, root, data)
    if not uilist then
        uilist = {}
        uilist.itemRoot = CS.FindTrans(root, "itemRoot")
        uilist.txtName = CS.FindTrans(root, "txtName")
        uilist.txtScore = CS.FindTrans(root, "txtScore")
        uilist.txtKg = CS.FindTrans(root, "txtKg")
        uilist.attrList = CS.FindTrans(root, "attrList")
        uilist.btnSave = CS.FindTrans(root, "1/btnSave")
        uilist.btnSell = CS.FindTrans(root, "1/btnSell")
        uilist.sell = CS.FindTrans(root, "1/sell")
        uilist.txtSellTips = CS.FindTrans(root, "1/sell/txtSellTips")
        uilist.txtSell = CS.FindTrans(root, "1/sell/txtSell")
        uilist.sellIcon = CS.FindTrans(root, "1/sell/SellIcon/sellIcon")
        uilist.Img1_enus = CS.FindTrans(root, "1/sell/Img1_enus")

        self:SetWndButtonText(uilist.btnSave, ccClientText(44243))
        self:SetWndButtonText(uilist.btnSell, ccClientText(44244))

        CS.ShowObject(uilist.Img1_enus, self._isEnus)
    end
    local fishObj = data.fishObj
    local fishRef = data.ref

    self:SetWndText(uilist.txtName, ccLngText(fishRef.name))
    self:SetWndText(uilist.txtScore, ccClientText(44246, fishObj.score))
    self:SetWndText(uilist.txtKg, gModelFish:WeightToString(fishObj.weight))

    local itemData = { itemId = fishRef.refId, itemType = CommonIcon.ICON_TYPE_FISH }
    self:CreateCommonIconImpl(uilist.itemRoot, itemData,
            { showNum = false, clickFunc = function()
                self:OnClickItem(fishRef.refId)
            end })

    local attrList = fishObj.attrs

    self:SetComList(uilist.attrList, attrList, function(...)
        return self:OnDrawAttrItem(...)
    end)

    local oepnTank = self:NeedOpenFishTank(fishObj)
    if oepnTank then
        local itemData = LUtil.GetRefItemData(fishRef.sell)
        local path = gModelItem:GetItemIconByRefId(itemData.refId)
        self:SetWndEasyImage(uilist.sellIcon, path)
        self:SetWndText(uilist.txtSell, itemData.itemNum)
        self:SetWndText(uilist.txtSellTips, ccClientText(44348))
    end

    self:SetWndClick(uilist.btnSave, function()
        self:OnClickSave(fishObj)
    end)
    self:SetWndClick(uilist.btnSell, function()
        self:OnClickSell(fishObj)
    end)

    CS.ShowObject(uilist.btnSell, oepnTank)
    CS.ShowObject(uilist.sell, oepnTank)

    return uilist
end

-- 点击列表item
function UIFishBackpack:OnClickItem(refId)
    GF.OpenWnd("UIFishTips", { refId = refId, isTips = true })
end

-- 点击售卖按钮
function UIFishBackpack:OnClickSell(fishObj)
    gModelFish:SellFishReq(2, fishObj.id)
end

-- 绘制AttrItem项
function UIFishBackpack:OnDrawAttrItem(uiList, item, data, itemPos)
    if not uiList then
        uiList = {}
        uiList.icon = CS.FindTrans(item, "icon")
        uiList.name = CS.FindTrans(item, "name")
        uiList.value = CS.FindTrans(item, "name/value")
    end

    local icon = gModelHero:GetAttributeIconById(data.refId)
    self:SetWndEasyImage(uiList.icon, icon)

    local name = gModelHero:GetAttributeNameById(data.refId)
    if self._isEnus then
        self:SetWndText(uiList.name, name .. ":")
        self:SetAnchorPos(uiList.value,Vector2.New(50,0))
    else
        self:SetWndText(uiList.name, name .. ":")
    end

    local value = gModelFish:CheckAttrValue(data.refId, data.type, data.value)
    local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(data.refId, data.type, value)
    self:SetWndText(uiList.value, valueStr)
    if self._isVie then
        self:InitTextSizeWithLanguage(uiList.name,-2)
        self:InitTextSizeWithLanguage(uiList.value,-2)
    end
    return uiList
end

-- true: 表示需要打开鱼釭
function UIFishBackpack:NeedOpenFishTank(fishObj)
    return gModelFish:NeedOpenFishTank(fishObj)
end

-- 刷新界面
function UIFishBackpack:Refresh()
    local map = {}
    for k, obj in pairs(gModelFish:GetBackpackMap()) do
        local ref = gModelFish:GetFishRef(obj.refId)
        local fishType = ref.type
        if not map[fishType] then
            map[fishType] = {}
        end
        table.insert(map[fishType], { ref = ref, fishObj = obj, fishType = fishType })
    end

    local dataList = {}
    for k, v in pairs(map) do
        table.sort(v, Sort)
        table.insert(dataList, { fishType = v[1].fishType, fishList = v })
    end
    table.sort(dataList, function(a, b)
        return a.fishType < b.fishType
    end)

    if not self._uiList then
        local uiList = self:GetUIScroll("mList")
        self._uiList = uiList
        uiList:Create(self.mList, dataList, function(...)
            self:OnDrawListItem(...)
        end, UIItemList.SUPER)
    else
        self._uiList:RefreshList(dataList)
        self._uiList:DrawAllItems()
    end

    CS.ShowObject(self.mEmpty, #dataList == 0)
    CS.ShowObject(self.mTxtTime, #dataList ~= 0)
end

-- 点击保存按钮
function UIFishBackpack:OnClickSave(fishObj)
    if self:NeedOpenFishTank(fishObj) then
        GF.OpenWnd("UIFishReplace", { sellType = 2, replaceFishObj = fishObj, isFast = true })
        return
    end
    gModelFish:SettleFishingReq(3, fishObj.id)
end

-- 绘制列表item项
function UIFishBackpack:OnDrawListItem(list, item, itemData, itemPos)
    local txtTitle = CS.FindTrans(item, "Title/txtTitle")

    local fishList = itemData.fishList
    local fishType = itemData.fishType
    local fishTypeRef = gModelFish:GetFishTypeRef(fishType)
    local typeName = ccLngText(fishTypeRef.name)
    self:SetWndText(txtTitle, ccClientText(44347, typeName, #fishList))

    self:SetComList(item, fishList, function(...)
        return self:OnDrawItem(...)
    end)

    LayoutRebuilder.ForceRebuildLayoutImmediate(item)
end

-- 初始时间
function UIFishBackpack:InitTimer()
    local timePara = {
        key = 1,
        loopcnt = -1,
        interval = 1,
        timescale = false,
        callOnStart = true,
        func = function()
            self:Update()
        end
    }
    self:TimerStartImpl(timePara)
end

-- 初始界面化文本
function UIFishBackpack:InitTexts()
    self:SetWndText(self.mTitle, ccClientText(44345))
    self:SetWndText(self.mCloseTip, ccClientText(10103))
    self:SetTextTile(self.mEmpty, ccClientText(44349))
end

-- Update
function UIFishBackpack:Update()
    local curTime = GetTimestamp()
    local leftTime = gModelFish:GetEndTime() - curTime
    if leftTime < 0 then
        return
    end
    local str = LUtil.FormatTimespanCn(leftTime)
    self:SetWndText(self.mTxtTime, ccClientText(44350, str))
end

------------------------------------------------------------------
return UIFishBackpack