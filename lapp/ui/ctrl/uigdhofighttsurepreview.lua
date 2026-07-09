---
--- Created by Administrator.
--- DateTime: 2024/6/28 11:47:36
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightTsurePreview:LWnd
local UIGdHoFightTsurePreview = LxWndClass("UIGdHoFightTsurePreview", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightTsurePreview:UIGdHoFightTsurePreview()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightTsurePreview:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightTsurePreview:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightTsurePreview:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()

    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitEvent()
    self:InitText()
    self:InitData()
    self:InitPara()
end


--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIGdHoFightTsurePreview:SetTab()
    for k, v in ipairs(self._tabInfo) do
        local offTxt = CS.FindTrans(v.tran, "Off/UIText")
        local onTxt = CS.FindTrans(v.tran, "On/UIText")

        self:SetWndText(offTxt, v.tabText)
        self:SetWndText(onTxt, v.tabText)

        self:SetWndClick(v.tran, v.clickFunc)

        if self._isVie then
            local text = offTxt
            self:InitTextLineWithLanguage(text, 0)
            LxUiHelper.SetSizeWithCurAnchor(text,0,120)
            self:InitTextSizeWithLanguage(text,-4)
            local uiText =LxUiHelper.FindXTextCtrl(text)
            uiText.characterSpacing = -4
            text = onTxt
            self:InitTextLineWithLanguage(text, 0)
            LxUiHelper.SetSizeWithCurAnchor(text,0,120)
            self:InitTextSizeWithLanguage(text,-4)
            uiText =LxUiHelper.FindXTextCtrl(text)
            uiText.characterSpacing = -4
        end
        if self.jpj then
            local text = offTxt
            self:InitTextLineWithLanguage(text, -40)
            LxUiHelper.SetSizeWithCurAnchor(text,0,120)
            self:InitTextSizeWithLanguage(text,-5)
            local uiText =LxUiHelper.FindXTextCtrl(text)
            uiText.characterSpacing = -4
            text = onTxt
            self:InitTextLineWithLanguage(text, -40)
            LxUiHelper.SetSizeWithCurAnchor(text,0,120)
            self:InitTextSizeWithLanguage(text,-5)
            uiText =LxUiHelper.FindXTextCtrl(text)
            uiText.characterSpacing = -4
        end
    end
end

function UIGdHoFightTsurePreview:InitTabInfo()
    self._tabInfo = {
        [1] = {
            tran = self.mTab_1,
            clickFunc = function()
                self:OnChangeTabState(1)
                self:SetRewardPreview(1)
            end,
            tabText = ccClientText(44044), --[44044] [獲勝寶藏]
        },
        [2] = {
            tran = self.mTab_2,
            clickFunc = function()
                self:OnChangeTabState(2)
                self:SetRewardPreview(2)
            end,
            tabText = ccClientText(44045), --[44045] [戰敗寶藏]
        },
    }

    self:SetTab()
end

function UIGdHoFightTsurePreview:InitEvent()


    --ui
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mClose, function()
        self:WndClose()
    end)

end

function UIGdHoFightTsurePreview:CreateRewardPreviewList(list, item, itemdata, itempos)
    local itemRoot = CS.FindTrans(item, "ItemIcon")

    --缓存下道具
    local InstanceID = item:GetInstanceID()
    if not self._uiCommonList then
        self._uiCommonList = {}
    end
    local baseClass = self._uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        self._uiCommonList[InstanceID] = baseClass
        baseClass:Create(itemRoot)
    end

    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    self:SetWndClick(itemRoot, function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata)
    end)
    baseClass:DoApply()
end

function UIGdHoFightTsurePreview:InitPara()
    self._para = self:GetWndArg("para")
    local tabIndex = 1
    if self._para then
        tabIndex = self._para.tabIndex
    end
    self._curtabIndex = tabIndex
    self._tabInfo[tabIndex].clickFunc()
end
--endregion --------------------------------------------------------------------------------------

--region 事件回调 --------------------------------------------------------------------------------

--ui
function UIGdHoFightTsurePreview:OnChangeTabState(tabIndex)
    for k, v in ipairs(self._tabInfo) do
        local off = CS.FindTrans(v.tran, "Off")
        local on = CS.FindTrans(v.tran, "On")
        CS.ShowObject(off, not (k == tabIndex))
        CS.ShowObject(on, k == tabIndex)


    end
end

function UIGdHoFightTsurePreview:InitData()
    self:InitTabInfo()
end

function UIGdHoFightTsurePreview:SetRewardPreview(group)
    --local showDatas = gModelGuildHolyBattle:GetTreasurePreviewReward(group)

    local showDatas = group == 1 and gModelGuildHolyBattle:GetWinTreasurePreviewData()  or gModelGuildHolyBattle:GetLoseTreasurePreviewData()

    local uiList = self._rewardList

    if not uiList then
        uiList = self:GetUIScroll(self.mRewardList:GetInstanceID())
        uiList:Create(self.mRewardList, showDatas, function(...)
            self:CreateRewardPreviewList(...)
        end, UIItemList.SUPER_GRID, false)

        self._rewardList = uiList
    else
        uiList:RefreshList(showDatas)
        uiList:DrawAllItems(true)
    end
end

--region 页面的初始化 --------------------------------------------------------------------------------
function UIGdHoFightTsurePreview:InitText()
    self:SetWndText(self.mTitle, ccClientText(44049))  --[44049] [寶藏預覽]
end
--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIGdHoFightTsurePreview