---
--- Created by Administrator.
--- DateTime: 2024/4/10 15:53:01
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOptem:LWnd
local UIOptem = LxWndClass("UIOptem", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOptem:UIOptem()
    self._title = ""
    self._para = nil
    self._rewards = nil
    self._curSelectReward = nil
    self._curSelectIndex = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOptem:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOptem:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOptem:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitData()
    self:InitEvent()

    self:InitCommon()
end

function UIOptem:OnDrawCellItem(list, item, itemData, itemPos)
    local iconRootTrans = CS.FindTrans(item, "ItemRoot")

    local itemInfo = LUtil.GetRefItemFourData(itemData)

    local InstanceID = item:GetInstanceID()

    local uicommonlist = self._uicommonList
    local baseClass = uicommonlist[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New()
        uicommonlist[InstanceID] = baseClass
        baseClass:Create(CS.FindTrans(iconRootTrans, "Icon"))
    end

    baseClass:SetCommonReward(itemInfo.type, itemInfo.refId, itemInfo.count)
    baseClass:DoApply()
    local formatData
    formatData = {
        itemId = itemInfo.refId,
        itemType = itemInfo.type,
        itemNum = itemInfo.count,
    }

    self:SetWndLongClick(iconRootTrans, function()
        gModelGeneral:ShowCommonItemTipWnd(formatData)
    end, 0.2, true)

    --设置点击方法
    self:SetWndClick(iconRootTrans, function()
        self:OnRewardsItemClick(itemPos)
    end)
end

function UIOptem:InitEvent()
    self:SetWndClick(self.mBtnClose, function(...)
        self:WndClose()
    end)
    self:SetWndClick(self.mConfirmBtn, function(...)
        self:OnClickConfirm()
    end)
end

function UIOptem:InitCommon()
    self:SetWndText(self.mLblBiaoti, self._para.title)
    self:SetWndButtonText(self.mConfirmBtn, ccClientText(10102))
    self:SetWndText(self.mBottomTitleTxt, ccClientText(18606))
    self:SetWndText(self.mItemTipsTxt, ccClientText(18605))
    self:SetSelectReward()

    self:SetCurSelectReward()
end

function UIOptem:OnClickConfirm()
    FireEvent(self._para.confirmEventString, self._curSelectIndex)
    self:WndClose()
end

function UIOptem:OnRewardsItemClick(index)
    self._curSelectReward = self._para.rewards[index]
    self._curSelectIndex = index
    self:SetCurSelectReward()
end

function UIOptem:SetCurSelectReward()
    if not string.isempty(self._curSelectReward) then
        local iconRootTrans = CS.FindTrans(self.mCurSelectItem, "ItemRoot")

        local itemInfo = LUtil.GetRefItemFourData(self._curSelectReward)
        local baseClass = self._curSelectItemBase
        if not baseClass then
            baseClass = CommonIcon:New()
            self._curSelectItemBase = baseClass
            baseClass:Create(CS.FindTrans(iconRootTrans, "Icon"))
        end

        baseClass:SetCommonReward(itemInfo.type, itemInfo.refId, itemInfo.count)
        baseClass:DoApply()

        CS.ShowObject(self.mItemTipsTxt, false)
        CS.ShowObject(self.mTipBtn, true)

        local formatData
        formatData = {
            itemId = itemInfo.refId,
            itemType = itemInfo.type,
            itemNum = itemInfo.count,
        }

        self:SetWndClick(self.mTipBtn, function()
            gModelGeneral:ShowCommonItemTipWnd(formatData)
        end)
    else
        CS.ShowObject(self.mItemTipsTxt, true)
        CS.ShowObject(self.mTipBtn, false)
    end
end

function UIOptem:InitData()
    self._para = self:GetWndArg("para")

    if not self._para then
        self:WndClose()
        return
    end

    self._uicommonList = {}
    self._curSelectReward = nil

end

function UIOptem:SetSelectReward()
    local uiList = self._uiCustomItemListList
    if uiList then
        uiList:RefreshList(self._para.rewards)
    else
        uiList = self:GetUIScroll("UIOptemselectItemList")
        uiList:Create(self.mCustomItemList, self._para.rewards, function(...)
            self:OnDrawCellItem(...)
        end)
        uiList:EnableScroll(false)
        self._uiCustomItemListList = uiList
    end
end

------------------------------------------------------------------
return UIOptem