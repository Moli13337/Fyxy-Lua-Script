---
--- Created by wzz.
--- DateTime: 2024/5/13 21:24:25
---

local ViewType = {
    First = 1,
    Second = 2,
}

local ViewTypeList = {
    { id = ViewType.First, name = ccClientText(42055) },
    { id = ViewType.Second, name = ccClientText(42056) },
}

local AwardState = gModelWarTemple.AwardState
local BtnStr = {
    [AwardState.CanNotGet] = ccClientText(42059),
    [AwardState.CanGet] = ccClientText(12207),
    [AwardState.HadGet] = ccClientText(42062),
}

------------------------------------------------------------------
local LWnd = LWnd
---@class UIWarTempleAward:LWnd
local UIWarTempleAward = LxWndClass("UIWarTempleAward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWarTempleAward:UIWarTempleAward()
    self.noNeedRegisterRed = true

    if gModelWarTemple:HadPalaceReward() then
        self._viewType = ViewType.First
    elseif gModelWarTemple:HadTargetReward() then
        self._viewType = ViewType.Second
    else
        self._viewType = ViewType.First
    end
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWarTempleAward:OnWndClose()
    LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWarTempleAward:OnCreate()
    LWnd.OnCreate(self)
    return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWarTempleAward:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitTexts()
    self:InitEvents()
    self:InitTabList()

    self:Refresh()
end

-- 初始事件
function UIWarTempleAward:InitEvents()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)
    self:WndEventRecv(EventNames.WARTEMPLE_INFO_RETURN, function(...)
        self._uiTypeList:DrawAllItems()
        self:Refresh(...)
    end)
end

-- 绘制item
function UIWarTempleAward:OnDrawItem(list, item, itemData, itemPos)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {
            itemRoot = CS.FindTrans(item, "itemRoot"),
        }
        self:SetComponentCache(instanceID, itemCache)
    end
    self:CreateCommonIconImpl(itemCache.itemRoot, itemData, { showNum = true })
end

-- 绘制tab按钮
function UIWarTempleAward:DrawTabItem(list, item, itemdata)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {
            btn = CS.FindTrans(item, "BtnTab1"),
            bg = CS.FindTrans(item, "bg"),
        }
        self:SetComponentCache(instanceID, itemCache)
    end
    self:SetWndTabText(itemCache.btn, itemdata.name, nil, -30)
    self:SetWndClick(itemCache.bg, function()
        self:OnClickTabBtn(itemdata.id)
    end)

    local state = self._viewType == itemdata.id and LWnd.StateOn or LWnd.StateOff
    self:SetWndTabStatus(itemCache.btn, state)
    local hadRed = false
    if itemdata.id == ViewType.First then
        hadRed = gModelWarTemple:HadPalaceReward()
    else
        hadRed = gModelWarTemple:HadTargetReward()
    end
    self:SetRed(itemCache.bg, hadRed)
end

-- 点击tab按钮
function UIWarTempleAward:OnClickTabBtn(viewType)
    if self._viewType == viewType then
        return
    end

    self._viewType = viewType
    self._uiTypeList:DrawAllItems()

    self:Refresh()
end

-- 点击按钮
function UIWarTempleAward:OnClickBtn(refId, state)
    if state == AwardState.CanGet then
        if self._viewType == ViewType.First then
            gModelWarTemple:WarTemplePalaceRewardReq()
        else
            gModelWarTemple:WarTempleRankRewardReq()
        end
        return
    end

    if state == AwardState.HadGet then
        GF.ShowMessage(ccClientText(42062))
        return
    end

    GF.ShowMessage(ccClientText(42059))
end

-- 绘制列表item项
function UIWarTempleAward:OnDrawListItem(list, item, itemData, itemPos)
    local instanceID = item:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {
            txtTitle = CS.FindTrans(item, "AniRoot/TxtTitle"),
            itemList = CS.FindTrans(item, "AniRoot/ItemList"),
            button = CS.FindTrans(item, "AniRoot/Button"),
            hadGet = CS.FindTrans(item, "AniRoot/HadGet"),
        }
        self:SetComponentCache(instanceID, itemCache)
    end

    local ref = itemData.ref

    local state = itemData.state
    local strTitle = ccLngText(ref.name)
    if self._viewType == ViewType.First then
        strTitle = ccClientText(42058, strTitle)
    end
    self:SetWndButtonText(itemCache.button, BtnStr[state])
    self:SetWndText(itemCache.txtTitle, strTitle)

    local itemList = LUtil.GetRefItemDataList(ref.reward)
    if ref.titleReward and ref.titleReward ~= "" then
        table.insert(itemList, LUtil.GetRefItemFourData(ref.titleReward))
    end

    -- self:InitItemList(itemCache.itemList, itemList)
    self:InitItemList2(itemCache.itemList, itemList)
    self:ShowBtnEff(itemCache.button, instanceID, state == AwardState.CanGet)
    self:SetWndClick(itemCache.button, function()
        self:OnClickBtn(ref.refId, state)
    end)
    self:SetWndButtonGray(itemCache.button, state == AwardState.HadGet)
    CS.ShowObject(itemCache.button, state == AwardState.CanGet)
    CS.ShowObject(itemCache.hadGet, state == AwardState.HadGet)

    if self._isVie then
        self:InitTextSizeWithLanguage(itemCache.txtTitle,-1)
    end
end

-- 初始化item列表
function UIWarTempleAward:InitItemList2(root, itemList)
    local instanceID = root:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {}
        local uiList = UIIconEasyList:New()
        uiList:Create(self, root)
        uiList:SetShowNum(true)
        uiList:SetIconParentPath("itemRoot")
        -- uiList:SetShowExtraNum(true, "itemNum")

        itemCache.uiList = uiList
        self:SetComponentCache(instanceID, itemCache)
    end
    itemCache.uiList:RefreshList(itemList)
end

-- 初始化tab按钮列表
function UIWarTempleAward:InitTabList()
    local uiTypeList = self:FindUIScroll("uiTypeList")
    if not uiTypeList then
        uiTypeList = self:GetUIScroll("uiTypeList")
        uiTypeList:Create(self.mTypeList, ViewTypeList, function(...)
            self:DrawTabItem(...)
        end)
    end
    self._uiTypeList = uiTypeList
end

-- 初始界面化文本
function UIWarTempleAward:InitTexts()
    self:SetWndText(self.mTitle, ccClientText(42057))
end

-- 刷新界面
function UIWarTempleAward:Refresh()
    local list = {}
    if self._viewType == ViewType.First then
        list = gModelWarTemple:GetWarTempleRefList()
    else
        list = gModelWarTemple:GetWarTempleTargetRefList()
    end

    local dataList = {}
    for i, ref in ipairs(list) do
        local state
        if self._viewType == ViewType.First then
            state = gModelWarTemple:GetPalaceRewardState(ref.refId)
        else
            state = gModelWarTemple:GetTargetRewardState(ref.refId)
        end
        dataList[i] = { state = state, ref = ref, index = i }
    end
    table.sort(dataList, function(a, b)
        if a.state ~= b.state then
            return a.state < b.state
        end
        return a.index < b.index
    end)

    if not self._uiList then
        local uiList = self:GetUIScroll("mList")
        self._uiList = uiList

        uiList:Create(self.mList, dataList, function(...)
            self:OnDrawListItem(...)
        end, UIItemList.SUPER_GRID)
    else
        self._uiList:RefreshList(dataList)
        self._uiList:DrawAllItems()
    end
end

-- item 列表
function UIWarTempleAward:InitItemList(root, itemList)
    local instanceID = root:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {}
        local uiList = self:GetUIScroll("mItemList" .. instanceID)
        itemCache.uiList = uiList

        uiList:Create(root, itemList, function(...)
            self:OnDrawItem(...)
        end, UIItemList.SUPER)
        self:SetComponentCache(instanceID, itemCache)
    else
        itemCache.uiList:RefreshList(itemList)
        itemCache.uiList:DrawAllItems()
    end
end

------------------------------------------------------------------
return UIWarTempleAward