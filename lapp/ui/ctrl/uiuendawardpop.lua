---
--- Created by BY.
--- DateTime: 2023/10/4 17:23:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIUendAwardPop:LWnd
local UIUendAwardPop = LxWndClass("UIUendAwardPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIUendAwardPop:UIUendAwardPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIUendAwardPop:OnWndClose()
    self:ClearCommonIconList(self._uiCommonList)
    self._uiCommonList = nil
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIUendAwardPop:OnCreate()
    LWnd.OnCreate(self)
    self._tabTransList = {}
    self._uiCommonList = {}
    self._tabType = -1
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIUendAwardPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isEnus = gLGameLanguage:IsEnglishVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEvent()
    --self:InitMessage()
    self:InitCommand()
end

function UIUendAwardPop:ChangeType(trans, bool)
    self:SetWndTabStatus(trans, bool and LWnd.StateOn or LWnd.StateOff)
end

function UIUendAwardPop:AwardListItem(list, item, itemdata, itempos)
    local root = CS.FindTrans(item, "Root")
    local uiCommonList = self._uiCommonList
    local InstanceID = item:GetInstanceID()
    local baseClass = uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        uiCommonList[InstanceID] = baseClass
        baseClass:Create(root)
    end
    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    self:SetWndClick(root, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
    baseClass:DoApply()
end

function UIUendAwardPop:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UIUendAwardPop:InitCommand()
    self._endlesInfo = self:GetWndArg("endlesInfo")
    local tabType = self:GetWndArg("tabType") or 1
    local isBattle = self:GetWndArg("isBattle")
    if (isBattle) then
        self._list = {
            { type = 2, title = ccClientText(17235) }
        }
        tabType = 2
    else
        self._list = {
            { type = 1, title = ccClientText(17234) },
            { type = 2, title = ccClientText(17235) }
        }
    end

    self._uiList = self:GetUIScroll("tab")
    self._uiList:Create(self.mTabScroll, self._list, function(...)
        self:TabListItem(...)
    end)
    self:OnClickTab(tabType)

    local ref = gModelEndles:GetUnclaimedAward(self._endlesInfo.type, self._endlesInfo.receiveIds)
    CS.ShowObject(self.mTabScroll, ref)
end

function UIUendAwardPop:OnClickTab(type)
    --点击标签类型
    if (self._tabType > 0) then
        if (self._tabType == type) then
            return
        end
        local trans = self._tabTransList[self._tabType]
        self:ChangeType(trans, false)
    end
    self._tabType = type
    local trans = self._tabTransList[type]
    self:ChangeType(trans, true)
    self:RefreshData(type)
end

function UIUendAwardPop:TabListItem(list, item, itemdata, itempos)
    --标签cell
    local btnTab1 = CS.FindTrans(item, "BtnTab1")

    if self._isEnus then
        self:SetWndTabText(btnTab1, itemdata.title, -2, -10)
    elseif self._isVie then
        self:SetWndTabText(btnTab1, itemdata.title, -6, -10)
    else
        self:SetWndTabText(btnTab1, itemdata.title, -2, -60)
    end
    self:SetWndTabStatus(btnTab1, LWnd.StateOff)
    self._tabTransList[itemdata.type] = btnTab1
    self:SetWndClick(item, function(...)
        self:OnClickTab(itemdata.type)
    end, LSoundConst.CLICK_PAGE_COMMON)

end

function UIUendAwardPop:RefreshData(type)
    local titleStr = ""
    for i, v in ipairs(self._list) do
        if (v.type == type) then
            titleStr = v.title
            break
        end
    end
    self:SetWndText(self.mTitleText, titleStr)
    local _endlesInfo = self._endlesInfo
    local tipsStr = ""
    local list
    if (type == 1) then
        tipsStr = ccClientText(17238)
        if (not self._checkList) then
            self._checkList = gModelEndles:GetCheckAwardList(_endlesInfo.type, _endlesInfo.initNode)
        end
        list = self._checkList
    else
        tipsStr = ccClientText(17239)
        if (not self._firstList) then
            local maxNode = _endlesInfo.maxNode > 0 and _endlesInfo.maxNode or _endlesInfo.dayNode
            self._firstList = gModelEndles:GetFirstAwardList(_endlesInfo.type, maxNode, _endlesInfo.receiveIds)
        end
        list = self._firstList
    end
    if (self._uiCellList) then
        self._uiCellList:RefreshSimpleList(list)
    else
        self._uiCellList = self:GetUIScroll("_uiCellList")
        self._uiCellList:Create(self.mCellScroll, list, function(...)
            self:CellListItem(...)
        end, UIItemList.WRAP)
    end
    self:SetWndText(self.mTipsText, tipsStr)
end

function UIUendAwardPop:CellListItem(list, item, itemdata, itempos)
    local titleText = CS.FindTrans(item, "TitleText")
    local awardScroll = CS.FindTrans(item, "AwardScroll")
    local num = itemdata.id
    local itemList = LxDataHelper.ParseItem(itemdata.reward)
    local titleStr = itempos == 1 and ccClientText(17236) or string.replace(ccClientText(17237), num)
    self:SetWndText(titleText, titleStr)

    local InstanceID = item:GetInstanceID()
    local _uiAwardList = self:GetUIScroll(InstanceID)
    if (_uiAwardList:GetList()) then
        _uiAwardList:RefreshList(itemList)
    else
        _uiAwardList:Create(awardScroll, itemList, function(...)
            self:AwardListItem(...)
        end)
    end

end
------------------------------------------------------------------
return UIUendAwardPop


