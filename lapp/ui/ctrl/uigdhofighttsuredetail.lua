---
--- Created by Administrator.
--- DateTime: 2024/6/28 11:24:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightTsureDetail:LWnd
local UIGdHoFightTsureDetail = LxWndClass("UIGdHoFightTsureDetail", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightTsureDetail:UIGdHoFightTsureDetail()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightTsureDetail:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightTsureDetail:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightTsureDetail:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitEvent()
    self:InitText()
    self:InitData()
    self:OpenReq()
end

function UIGdHoFightTsureDetail:SetLeftTime()
    if self._timeSpan <= 0 or self._timeSpan == nil then
        self:TimerStop(self._timeKey)
        return
    end
    local leftTime = self._timeSpan
    local timeStr = LUtil.FormatTimespanNumber(leftTime)
    local desStr = string.replace(ccClientText(44047), timeStr)
    self:SetWndText(self.mGetLeftTime, desStr)
    self._timeSpan = self._timeSpan - 1
end

function UIGdHoFightTsureDetail:OpenReq()
    gModelGuildHolyBattle:SendGuildBattleTreasureBoxReq(1)
end

--endregion --------------------------------------------------------------------------------------

--region 页面事件 --------------------------------------------------------------------------------
function UIGdHoFightTsureDetail:SetReward()
    local showDatas = self._treasure

    local uiList = self._rewardList

    if not uiList then
        uiList = self:GetUIScroll(self.mRewardList:GetInstanceID())
        uiList:Create(self.mRewardList, showDatas, function(...)
            self:CreateRewardList(...)
        end, UIItemList.SUPER_GRID, false)

        self._rewardList = uiList
    else
        uiList:RefreshList(showDatas)
        uiList:DrawAllItems(true)
    end
end
function UIGdHoFightTsureDetail:InitData()
    self._timeKey = "UIGdHoFightTsureDetail_TimeKey" -- 每隔1S刷新一次
end

function UIGdHoFightTsureDetail:InitPara()

end

function UIGdHoFightTsureDetail:InitEvent()
    self:WndEventRecv(gModelGuildHolyBattle.EventArgs.TreasureDataChange, function()
        self:OnTreasureDataChange()
    end)

    --ui
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mClose, function()
        self:WndClose()
    end)

end

--endregion --------------------------------------------------------------------------------------


--region 回调事件 --------------------------------------------------------------------------------
function UIGdHoFightTsureDetail:OnTreasureDataChange()
    self._canGet, self._timeSpan, self._treasure = gModelGuildHolyBattle:GetTreasureInfo()
    self._isWin = gModelGuildHolyBattle:CheckGuildHolyIsWin()


    self:SetLeftTime()
    self:SetReward()
end

--endregion --------------------------------------------------------------------------------------

--region 计时器 --------------------------------------------------------------------------------
function UIGdHoFightTsureDetail:OnTimer(key)
    if (self._timeKey == key) then

        self:SetLeftTime()
    end
end

function UIGdHoFightTsureDetail:CreateRewardList(list, item, itemdata, itempos)
    --使用哪张背景
    local Unknown = CS.FindTrans(item, "Unknown")
    local Known = CS.FindTrans(item, "Known")
    CS.ShowObject(Unknown, itemdata.rewardRefId == 0)
    CS.ShowObject(Known, not (itemdata.rewardRefId == 0))
    if itemdata.rewardRefId == 0 then
        self:SetWndClick(Unknown, function()
            if itemdata.rewardRefId == 0 then
                gModelGuildHolyBattle:SendGuildBattleTreasureBoxReq(2, itemdata.index)
            end
        end)
    else
        local itemRoot = CS.FindTrans(Known, "Icon")
        local Des = CS.FindTrans(Known, "Des")

        local InstanceID = itemRoot:GetInstanceID()
        local ref = gModelGuildHolyBattle:GetTreasureRefByRefId(itemdata.rewardRefId)
        local itemDataList = LxDataHelper.ParseItem(ref.reward) -- itemdata.items
        if not self._uiCommonList then
            self._uiCommonList = {}
        end
        local baseClass = self._uiCommonList[InstanceID]
        if not baseClass then
            baseClass = CommonIcon:New()
            self._uiCommonList[InstanceID] = baseClass
            baseClass:Create(itemRoot)
        end
        local showRewarditem = itemDataList[1]
        baseClass:SetCommonReward(showRewarditem.itemType, showRewarditem.itemId, showRewarditem.itemNum)
        self:SetWndClick(itemRoot, function()
            gModelGeneral:ShowCommonItemTipWnd(showRewarditem)
        end)
        baseClass:DoApply()

        self:SetWndText(Des, ccClientText(44023))
        self:SetWndClick(Des, function()
            --GF.ShowMessage("点击了详情")
            local para={}
            para.rewardRefId=itemdata.rewardRefId
            para.isWin=self._isWin

            GF.OpenWnd("UIGdHoFightTsureGetView", { para=para })
        end)
    end
end

--region 页面的初始化 --------------------------------------------------------------------------------
function UIGdHoFightTsureDetail:InitText()
    self:SetWndText(self.mTitle, ccClientText(44043))  --[44043] [聖騎寶藏]
    self:SetWndText(self.mInfo_Title_1, ccClientText(44046))  --[44046] [寶藏詳情]
end

--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIGdHoFightTsureDetail