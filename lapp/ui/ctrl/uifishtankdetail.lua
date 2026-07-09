---
--- Created by wzz.
--- DateTime: 2024/7/17 11:44:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishTankDetail:LWnd
local UIFishTankDetail = LxWndClass("UIFishTankDetail", LWnd)

local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishTankDetail:UIFishTankDetail()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishTankDetail:OnWndClose()
    LWnd.OnWndClose(self)

    local func = self:GetWndArg("callFunc")
    if func then
        func()
    end
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishTankDetail:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishTankDetail:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._replaceFishObj = self:GetWndArg("replaceFishObj")

    self:InitTexts()
    self:InitEvents()
    self:Refresh()
end

-- 绘制AttrItem项
function UIFishTankDetail:OnDrawAttrItem(uiList, item, data, itemPos)
    if not uiList then
        uiList = {}
        uiList.icon = CS.FindTrans(item, "icon")
        uiList.name = CS.FindTrans(item, "name")
        uiList.value = CS.FindTrans(item, "name/value")
    end

    local icon = gModelHero:GetAttributeIconById(data.refId)
    self:SetWndEasyImage(uiList.icon, icon)

    local name = gModelHero:GetAttributeNameById(data.refId)
    self:SetWndText(uiList.name, name .. "：")

    local value = gModelFish:CheckAttrValue(data.refId, data.type, data.value)
    local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(data.refId, data.type, value)
    self:SetWndText(uiList.value, valueStr)
    return uiList
end

-- 初始界面化文本
function UIFishTankDetail:InitTexts()
    self:SetWndText(self.mTitle, ccClientText(44273))
    self:SetWndText(self.mTxtCloseTips, ccClientText(41037))
end

-- 点击替换
function UIFishTankDetail:OnReplaceBtnClick(fishObj)
    local id = fishObj.id
    local fishRef = gModelFish:GetFishRef(fishObj.refId)
    local itemData = LUtil.GetRefItemData(fishRef.sell)
    local name = ccLngText(fishRef.name)
    local itemList = { itemData }
    gModelGeneral:OpenUIOrdinTips({
        refId = 450000,
        para = { name, name },
        itemList = itemList,
        func = function()
            if self:GetWndArg("isFast") then
                gModelFish:SettleFishingReq(4, id, self._replaceFishObj.id)
            else
                gModelFish:SettleFishingReq(1, id)
            end
        end,
    })
end

-- 初始事件
function UIFishTankDetail:InitEvents()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
end

-- 刷新界面
function UIFishTankDetail:Refresh()
    local uiDataList = gModelFish:GetFishTankDetailFishTypeList()

    if not self._uiList then
        local uiList = self:GetUIScroll("mList")
        self._uiList = uiList
        uiList:Create(self.mList, uiDataList, function(...)
            self:OnDrawListItem(...)
        end, UIItemList.SUPER)
    else
        self._uiList:ResetList(uiDataList)
        self._uiList:DrawAllItems()
    end
end

-- 绘制ComListItem项
function UIFishTankDetail:OnDrawComListItem(uiList, item, itemData, itemPos)
    if not uiList then
        uiList = {}
        uiList.txtName = CS.FindTrans(item, "txtName")
        uiList.txtWeight = CS.FindTrans(item, "txtWeight")
        uiList.txtScore = CS.FindTrans(item, "txtScore")
        uiList.itemRoot = CS.FindTrans(item, "itemRoot")
        uiList.attrList = CS.FindTrans(item, "attrList")
        uiList.btnReplace = CS.FindTrans(item, "btnReplace")

        self:SetWndButtonText(uiList.btnReplace, ccClientText(44286))
    end

    local fishObj = itemData.fishObj
    local showReplace = itemData.showReplace
    local ref = gModelFish:GetFishRef(fishObj.refId)
    local name = ccLngText(ref.name)
    self:SetWndText(uiList.txtName, name)

    local score = fishObj.score
    self:SetWndText(uiList.txtScore, ccClientText(44246, score))
    self:SetWndText(uiList.txtWeight, gModelFish:WeightToString(fishObj.weight))

    local itemData = { itemId = ref.refId, itemType = CommonIcon.ICON_TYPE_FISH }
    self:CreateCommonIconImpl(uiList.itemRoot, itemData, { showNum = false, clickFunc = function()
        GF.OpenWnd("UIFishTips", { refId = ref.refId, isTips = true })
    end })

    local attrList = fishObj.attrs -- gModelFish:GetFishBaseAttr(ref.refId)
    self:SetComList(uiList.attrList, attrList, function(...)
        return self:OnDrawAttrItem(...)
    end)

    CS.ShowObject(uiList.btnReplace, showReplace)
    if showReplace then
        self:SetWndClick(uiList.btnReplace, function()
            self:OnReplaceBtnClick(fishObj)
        end)
    end

    return uiList
end

-- 绘制列表item项
function UIFishTankDetail:OnDrawListItem(list, item, itemData, itemPos)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {
            txtTitle = CS.FindTrans(item, "txtTitle"),
            empty = CS.FindTrans(item, "bg/empty"),
            lock = CS.FindTrans(item, "bg/lock"),
            list = CS.FindTrans(item, "bg/list"),
            emptyTxt = CS.FindTrans(item, "bg/empty/UIText"),
        }
        self:SetComponentCache(instanceID, itemCache)

        self:SetTextTile(itemCache.empty, ccClientText(44285))
    end

    if self._isEnus then
        self:SetAnchorPos(itemCache.emptyTxt, Vector2.New(10, -38))
    end

    local fishType = itemData
    local fishTypeRef = gModelFish:GetFishTypeRef(fishType)

    local fishObjList = gModelFish:GetFishTankObjListByType(fishType)
    local curNum = #fishObjList
    local curTankLev = gModelFish:GetFishTankLev()
    local maxNum = gModelFish:GetFishNumMaxByType(fishType, curTankLev)
    local name = ccLngText(fishTypeRef.name)
    if maxNum == 0 then
        name = name .. "：" .. ccClientText(44283)
    else
        name = name .. "：" .. curNum .. "/" .. maxNum
    end
    self:SetWndText(itemCache.txtTitle, name)

    CS.ShowObject(itemCache.empty, maxNum > 0 and curNum == 0)
    CS.ShowObject(itemCache.list, curNum > 0)
    CS.ShowObject(itemCache.lock, maxNum == 0)

    if maxNum == 0 then
        local unLockNeedLev = gModelFish:GetFishTankUnLockLevByFishType(fishType)
        self:SetTextTile(itemCache.lock, ccClientText(44284, unLockNeedLev))
    end

    local dataList = {}
    for _, fishObj in ipairs(fishObjList) do
        table.insert(dataList, { fishObj = fishObj, showReplace = false })
    end
    if self._replaceFishObj then
        local oldFishRef = gModelFish:GetFishRef(self._replaceFishObj.refId)
        if oldFishRef.type == fishType then
            local oldObj = gModelFish:GetFishTankObj(self._replaceFishObj.refId)
            local had = oldObj ~= nil
            for _, v in ipairs(dataList) do
                if had then
                    v.showReplace = v.fishObj.refId == self._replaceFishObj.refId
                else
                    v.showReplace = true
                end
            end
        end
    end

    if curNum > 0 then
        self:SetComList(itemCache.list, dataList, function(...)
            return self:OnDrawComListItem(...)
        end)
    end

    LayoutRebuilder.ForceRebuildLayoutImmediate(item)
end

------------------------------------------------------------------
return UIFishTankDetail