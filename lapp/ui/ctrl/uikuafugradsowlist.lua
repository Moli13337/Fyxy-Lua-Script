---
--- Created by LCM.
--- DateTime: 2024/3/28 15:18:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuGradSowList:LWnd
local UIKuafuGradSowList = LxWndClass("UIKuafuGradSowList", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuGradSowList:UIKuafuGradSowList()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuGradSowList:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuGradSowList:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuGradSowList:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:SetWndButtonText(self.mCloseBtn, ccClientText(10321))
    self:SetWndText(self.mTitle, ccClientText(21858))
    self:SetWndText(self.mCloseTip, ccClientText(15800))

    local curRankRefId = gModelCrossGrading:GetRankRefIdByScore()
    self._curRankRefId = curRankRefId

    self:InitEvent()
    self:InitGradingList()
end

function UIKuafuGradSowList:OnDrawGradingCell(list, item, itemdata, itempos)
    local RankIcon = self:FindWndTrans(item, "RankIcon")
    local RankEff = self:FindWndTrans(RankIcon, "RankEff")
    local RankName = self:FindWndTrans(item, "RankName")
    local RankDesc = self:FindWndTrans(item, "RankDescScroll/RankDesc")
    local CurRankImg = self:FindWndTrans(item, "CurRankImg")
    local CurRankImg_en = self:FindWndTrans(item, "CurRankImg_en")

    local refId = itemdata.refId
    local show = refId == self._curRankRefId
    --CS.ShowObject(CurRankImg,show)

    local iconEffect = itemdata.iconEffect
    if not string.isempty(iconEffect) then
        CS.ShowObject(RankEff, true)
        local InstanceID = RankEff:GetInstanceID()
        self:DestroyWndEffectByKey(InstanceID)
        self:CreateWndEffect(RankEff, iconEffect, InstanceID, 100, false, false)

    else
        CS.ShowObject(RankEff, false)
    end

    if RankIcon then
        self:SetWndEasyImage(RankIcon, itemdata.icon, nil, true)
    end

    if RankName then
        local name = ccLngText(itemdata.name)
        local nameColor = itemdata.nameColor
        if nameColor then
            nameColor = "#" .. nameColor
            name = LUtil.FormatColorStr(name, nameColor)
        end
        self:SetWndText(RankName, name)
    end

    if RankDesc then
        self:SetWndText(RankDesc, ccLngText(itemdata.des))
    end

    local isUSAVersion = gLGameLanguage:IsUSAVersion()
    CS.ShowObject(CurRankImg, not isUSAVersion and show)
    CS.ShowObject(CurRankImg_en, isUSAVersion and show)
    if show then
        if not isUSAVersion then
            self:SetWndEasyImage(CurRankImg, "risk_txt_2")
        else
            self:SetWndEasyImage(CurRankImg_en, "risk_txt_2")
        end
    end
end

function UIKuafuGradSowList:InitGradingList()
    local list = self:GetGradingList()
    local index = 0
    local curRankRefId = self._curRankRefId
    for i, v in ipairs(list) do
        if v.refId == curRankRefId then
            index = i - 1
            break
        end
    end

    local uiGradingList = self._uiGradingList
    if uiGradingList then
        uiGradingList:RefreshList(list)
    else
        uiGradingList = self:GetUIScroll("uiGradingList")
        self._uiGradingList = uiGradingList
        uiGradingList:Create(self.mGradingList, list, function(...)
            self:OnDrawGradingCell(...)
        end, UIItemList.WRAP, false)
    end

    local uiList = uiGradingList:GetList()
    uiList:RefreshList(UIListWrap.RefreshMode.Custom, index)
end

function UIKuafuGradSowList:GetGradingList()
    local rankList = gModelCrossGrading:GetSortCrossGradingIntervalList()

    local list = {}
    for i, v in ipairs(rankList) do
        table.insert(list, {
            refId = v.refId,
            iconEffect = v.iconEffect,
            icon = v.icon,
            name = v.name,
            nameColor = v.nameColor,
            des = v.des,
            sort = v.sort,
        })
    end

    table.sort(list, function(a, b)
        return a.sort > b.sort
    end)

    return list
end

function UIKuafuGradSowList:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end
------------------------------------------------------------------
return UIKuafuGradSowList


