---
--- Created by Administrator.
--- DateTime: 2024/9/18 11:28:52
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMicMin:LWnd
local UIMicMin = LxWndClass("UIMicMin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMicMin:UIMicMin()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMicMin:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMicMin:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMicMin:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitMsg()
    self:InitPara()
    self:InitCommon()
    self:InitText()
end

function UIMicMin:CreateSubEntrance(tabIndex)
    local type = self._bottomBtnList[tabIndex]

    local entranceData = gModelMagic:GetMagicCircleRefsByType(type)

    if table.isempty(entranceData) then
        printInfoNR2("UIMicMin--", "--cfg--MagicCircleRef--not--type" .. type)
    end

    local showData = {}

    for k, v in pairs(entranceData) do
        table.insert(showData, v)
    end

    table.sort(showData, function(a, b)
        return a.refId < b.refId
    end)

    local uiList = self._entranceList

    if not uiList then
        uiList = self:GetUIScroll("WndMagicEntranceList")
        uiList:Create(self.mMagicSubEntrance, showData or {}, function(...)
            self:OnDrawEntrance(...)
        end, UIItemList.SUPER_GRID)
    else
        uiList:RefreshList(showData)
        uiList:DrawAllItems()
    end
    uiList:EnableScroll(false, false)
    self._entranceList = uiList
end

function UIMicMin:InitText()
    self:SetWndText(self.mTxtClose, ccClientText(41102))
    self:SetWndText(self.mTopTitle, ccClientText(45701))

    --收集度
    local collectTxt = CS.FindTrans(self.mCollectBtn, "Text")
    self:SetWndText(collectTxt, ccClientText(45702))

    self:SetWndText(self.mMagicPanText, ccClientText(45801))
end

--endregion --------------------------------------------------------------------------------------

--region 界面方法 --------------------------------------------------------------------------------
function UIMicMin:CreateBottomBtn()
    if table.isempty(self._bottomBtnList) then
        printInfoNR2("UIMicMin--", "--cfg--MagicTypeRef--not--refId")
    end

    local uiList = self._bottomBtnListTran

    if not uiList then
        uiList = self:GetUIScroll("WndMagicBtnTabList")
        uiList:Create(self.mTabScroll, self._bottomBtnList or {}, function(...)
            self:OnDrawTab(...)
        end)
    end

    self._bottomBtnListTran = uiList
end

function UIMicMin:SetCollectSchedule()
    local code, _ = gModelMagic:GetCollectSchedule()
    local collectTran = CS.FindTrans(self.mCollectBtn, "CollectNumBag")
    local CollectNum = CS.FindTrans(self.mCollectBtn, "CollectNumBag/CollectNum")
    self:SetWndText(CollectNum, code)

    CS.ShowObject(collectTran, code > 0)
end

function UIMicMin:SetRedPoint()

    --刷新一次入口和进度     --入口的红点
    self:CreateSubEntrance(self._tabIndex)

    for refId, eff in pairs(self._magicEffect[self._tabIndex]) do
        local circleData = gModelMagic:GetCircleData(refId)
        if circleData then
            eff:SetVisible(circleData:GetActive())
        else
            eff:SetVisible(false)
        end
    end

    --收集部分的红点
    local collectRedPoint = CS.FindTrans(self.mCollectBtn, "redPoint")
    local isShowRed = gModelMagic:CheckCollectRedpoint()
    CS.ShowObject(collectRedPoint, isShowRed)

    --下发大按钮的红点
    for index, itemdata in ipairs(self._bottomBtnList) do

        local item = self._tabList[index]
        --检查是否上锁
        local lockTran = CS.FindTrans(item, "Lock")
        local isOpen = gModelMagic:CheckMagicTypeIsOpen(itemdata)
        CS.ShowObject(lockTran, not isOpen)

        local redPoint = CS.FindTrans(item, "redPoint")
        CS.ShowObject(redPoint, false)
        if isOpen then
            --检查是否有红点
            local entranceData = gModelMagic:GetMagicCircleRefsByType(itemdata)
            for k, v in pairs(entranceData) do
                local isShowRed = gModelMagic:CheckMagicCircleRedpoint(v.refId)

                if isShowRed then
                    CS.ShowObject(redPoint, isShowRed)
                    break
                end

            end
        else
            CS.ShowObject(redPoint, false)
        end

    end

    --魔药锅的红点
    -- local isShowMagicPanRedPoint = gModelQuest:IsHaveFinishTaskByType(182)
    -- local redTran =CS.FindTrans(self.mMagicPan,"redPoint")
    -- CS.ShowObject(redTran,isShowMagicPanRedPoint)
end

--endregion --------------------------------------------------------------------------------------

--region Msg回调 --------------------------------------------------------------------------------
function UIMicMin:OnLightCandle()
    if self._tabIndex then
        --刷新一次入口和进度
        self:CreateSubEntrance(self._tabIndex)
        self:SetCollectSchedule()
    end
end

function UIMicMin:InitCommon()
    self:SetCollectSchedule()

    --魔药锅 显示
    -- local isShow = gModelFunctionOpen:CheckIsShow(21008100)
    -- CS.ShowObject(self.mMagicPan, isShow)
    -- local isShowMagicPanRedPoint =gModelQuest:IsHaveFinishTaskByType(182) or gModelMagicPot:GetGiftRedPoint()
    -- local redTran =CS.FindTrans(self.mMagicPan,"redPoint")
    -- CS.ShowObject(redTran, isShowMagicPanRedPoint)

    --底部的按钮部分
    self:CreateBottomBtn()

    --收集的红点
    local collectRedPoint = CS.FindTrans(self.mCollectBtn, "redPoint")
    local isShowRed = gModelMagic:CheckCollectRedpoint()
    CS.ShowObject(collectRedPoint, isShowRed)
end

function UIMicMin:OnDrawTab(list, item, itemdata, index)
    local cfg = gModelMagic:GetMagicTypeRef(itemdata)

    self:SetWndTabText(item, ccLngText(cfg.name))
    self:SetWndTabIcon(item, cfg.icon, cfg.icon)

    local isLock = false
    self:SetWndTabStatus(item, isLock and 2 or 1)

    self:SetWndClick(item, function(...)
        self:OnClickBottomBtn(index)
    end)

    if index == self._tabIndex then
        self:OnClickBottomBtn(index)
        self:SetWndTabStatus(item, 0, index)
    end

    --检查是否上锁
    local lockTran = CS.FindTrans(item, "Lock")
    local isOpen = gModelMagic:CheckMagicTypeIsOpen(itemdata)
    CS.ShowObject(lockTran, not isOpen)

    --检查是否有红点
    local redPoint = CS.FindTrans(item, "redPoint")
    if isOpen then
        --检查是否有红点
        local entranceData = gModelMagic:GetMagicCircleRefsByType(itemdata)
        for k, v in pairs(entranceData) do
            local isShowRed = gModelMagic:CheckMagicCircleRedpoint(v.refId)
            CS.ShowObject(redPoint, isShowRed)

            if isShowRed then
                break
            end
        end
    else
        CS.ShowObject(redPoint, false)
    end

    self._tabList[index] = item
end

--region 界面初始化 --------------------------------------------------------------------------------
function UIMicMin:InitEvent()
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mCollectBtn, function()
        GF.OpenWnd("UIMicCollectSow")
    end)

    self:SetWndClick(self.mMagicPan, function()
        local isOpen = gModelFunctionOpen:CheckIsOpened(21008100, true)
        if isOpen then
            GF.OpenWnd("UIMicPot")
        end
    end)

    self:SetWndClick(self.mHelpBtn, function()
        GF.OpenWnd("UIBzTips", { refId = 179 })
    end)
end

function UIMicMin:OnDrawEntrance(list, item, itemdata, index)
    local EntranceIcon = CS.FindTrans(item, "EntranceIcon")
    local EntranceName = CS.FindTrans(item, "EntranceName")
    local EntranceSchedule = CS.FindTrans(item, "EntranceSchedule")
    local EntranceEffect = CS.FindTrans(item, "EntranceEffect")

    local effectName = itemdata.eff
    local refId = itemdata.refId

    if not self._magicEffect then
        self._magicEffect = {}
    end

    if not self._magicEffect[self._tabIndex] then
        self._magicEffect[self._tabIndex] = {}
    end

    if not self._magicEffect[self._tabIndex][refId] then
        self._magicEffect[self._tabIndex][refId] = self:CreateWndEffect(EntranceEffect, effectName, effectName .. refId, 100, nil, nil, nil, nil, nil, true)
    end

    self._magicEffect[self._tabIndex][refId]:SetVisible(false)
    local redPoint = CS.FindTrans(item, "redPoint")

    self:SetWndEasyImage(EntranceIcon, itemdata.icon)
    self:SetWndText(EntranceName, ccLngText(itemdata.name))

    self:SetWndClick(EntranceIcon, function()
        GF.OpenWnd("UIMicSub", { magicRefId = itemdata.refId })
    end)

    local circleData = gModelMagic:GetCircleData(refId)

    local candleCount, _ = gModelMagic:ParseCandleCell(itemdata.cell)

    local schedule = "%s/%s"
    if circleData then
        local seat = circleData:GetSeat()
        schedule = string.format(schedule, #seat, candleCount)

        local isShowEffect = circleData:GetActive()

        self._magicEffect[self._tabIndex][refId]:SetVisible(isShowEffect)

    else
        schedule = string.format(schedule, 0, candleCount)

        self._magicEffect[self._tabIndex][refId]:SetVisible(false)
    end

    self:SetWndText(EntranceSchedule, schedule)

    local isShowRed = gModelMagic:CheckMagicCircleRedpoint(refId)
    CS.ShowObject(redPoint, isShowRed)

    self._checkRedPoingTran = self._checkRedPoingTran or {}
    self._checkRedPoingTran[refId] = redPoint
end

--endregion --------------------------------------------------------------------------------------

--region Event回调 --------------------------------------------------------------------------------
function UIMicMin:OnClickBottomBtn(index)
    local checkTypeId = self._bottomBtnList[index]
    local isOpen, str = gModelMagic:CheckMagicTypeIsOpen(checkTypeId)
    if not isOpen then
        GF.ShowMessage(str)
        return
    end

    local oldIndex = self._tabIndex
    if self._tabList[oldIndex] then
        self:SetWndTabStatus(self._tabList[oldIndex], 1, oldIndex)

    end

    self:SetWndTabStatus(self._tabList[index], 0, index)
    self._tabIndex = index

    if self._magicEffect then
        for k, v in pairs(self._magicEffect[oldIndex]) do
            v:SetVisible(false)
        end
    end

    --创建SubEntrance
    self:CreateSubEntrance(index)
end

function UIMicMin:InitMsg()
    self:WndEventRecv(gModelMagic.EventArgs.LightCandle, function()
        self:OnLightCandle()
        self:SetRedPoint()
    end)

    self:WndEventRecv(gModelMagic.EventArgs.UpLightCandle, function()
        self:SetRedPoint()
    end)

    self:WndEventRecv(EventNames.ON_QUEST_CHANGE, function()
        self:SetRedPoint()
    end)

    self:WndEventRecv(EventNames.On_Item_Change, function()
        self:SetRedPoint()
    end)

    self:WndEventRecv(gModelMagic.EventArgs.CollectionActive, function()
        self:SetRedPoint()
    end)

    self:RegisterRedPointFunc(21008100, function(isShow)
        if not isShow then
            isShow = gModelMagicPot:GetGiftRedPoint() or gModelQuest:IsHaveFinishTaskByType(182) or gModelMagicPot:GetRewardRedpoint()
        end
        local redTran = CS.FindTrans(self.mMagicPan, "redPoint")
        CS.ShowObject(redTran, isShow)
    end)
    self:WndEventRecv("magicPotRedPointChange", function()
        local isOpen = gModelFunctionOpen:CheckIsOpened(21008100)
        local isShow
        if isOpen then
            isShow = gModelMagicPot:GetGiftRedPoint() or gModelQuest:IsHaveFinishTaskByType(182) or gModelMagicPot:GetRewardRedpoint()
        end
        local redTran = CS.FindTrans(self.mMagicPan, "redPoint")
        CS.ShowObject(redTran, isShow)
    end)
end

function UIMicMin:InitPara()
    self._tabList = {}
    self._bottomBtnList = gModelMagic:GetMagicType()
    local tabIndex = self:SetWndArg("tabIndex")

    self._tabIndex = tabIndex or #self._bottomBtnList

end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIMicMin