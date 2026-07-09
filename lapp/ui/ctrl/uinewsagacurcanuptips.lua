---
--- Created by Administrator.
--- DateTime: 2024/8/12 15:17:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UINewSagaCurCanUpTips:LWnd
local UINewSagaCurCanUpTips = LxWndClass("UINewSagaCurCanUpTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UINewSagaCurCanUpTips:UINewSagaCurCanUpTips()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UINewSagaCurCanUpTips:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UINewSagaCurCanUpTips:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UINewSagaCurCanUpTips:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitText()
    self:InitEvent()
    self:InitPara()

end

function UINewSagaCurCanUpTips:GetColorStr(refId, num, itemType, selNum)
    local allNum
    if itemType == LItemTypeConst.TYPE_ITEM then
        allNum = gModelItem:GetNumByRefId(refId)
    else
        allNum = selNum
    end
    local color = "139057FF"
    if num > allNum then
        color = "c81212ff"
    end
    allNum = LUtil.NumberCoversion(allNum)
    num = LUtil.NumberCoversion(num)
    local str = string.replace(ccClientText(10065), color, allNum, num)
    return str
end

function UINewSagaCurCanUpTips:InitEvent()
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end)
    self:SetWndClick(self.mBtnCancel, function()
        self:WndClose()
    end)

    self:SetWndClick(self.mBtnOk, function()
        self:OnBtnOKClick()
    end)
end

function UINewSagaCurCanUpTips:InitNeedItemList()
    local needItemList = {}
    local itemRefIdList = { 101001, 104001 }

    local needGold, needExp = self._curCanUpCostItem.needGold, self._curCanUpCostItem.needExp
    local needList = { needGold, needExp }

    local needItem = self._curCanUpCostItem.needitem

    CS.ShowObject(self.mUpLvNeedItemLis_Extra, false)
    if needItem then
        CS.ShowObject(self.mUpLvNeedItemLis_Extra, true)

        local itemRefIdList_extra= {}

        table.insert(itemRefIdList_extra, { itemId =100110, itemNum = needItem, itemType = LItemTypeConst.TYPE_ITEM })
        self:CreateUpLvNeedItem_Extra(itemRefIdList_extra)
    end

    for i, v in ipairs(itemRefIdList) do
        local num = needList[i]

        table.insert(needItemList, { itemId = v, itemNum = num, itemType = LItemTypeConst.TYPE_ITEM })
    end

    self:CreateUpLvNeedItem(needItemList)
end

function UINewSagaCurCanUpTips:OnDrawNeedItemCell(list, item, itemdata, itempos)
    local itemId, itemType, itemNum = itemdata.itemId, itemdata.itemType, itemdata.itemNum
    local CommonUI = self:FindWndTrans(item, "CommonUI")

    if CommonUI then
        local ItemIcon = self:FindWndTrans(CommonUI, "ItemIcon")
        local icon = gModelItem:GetItemIconByRefId(itemId)
        self:SetWndEasyImage(ItemIcon, icon)

        self:SetWndClick(CommonUI, function()
            gModelGeneral:OpenGetWayWnd({ itemId = itemId })
        end)
    end
    local NumTxt = self:FindWndTrans(item, "NumTxt")
    if NumTxt then
        local colorStr = self:GetColorStr(itemId, itemNum, LItemTypeConst.TYPE_ITEM)
        self:SetWndText(NumTxt, colorStr)
    end
end

--endregion --------------------------------------------------------------------------------------

--region 面板方法 --------------------------------------------------------------------------------
--设置消耗的道具
function UINewSagaCurCanUpTips:CreateUpLvNeedItem(list)
    local uiUpLvList = self._uiUpLvList
    if uiUpLvList then
        uiUpLvList:RefreshList(list)
    else
        uiUpLvList = self:GetUIScroll("uiUpLvList")
        self._uiUpLvList = uiUpLvList
        uiUpLvList:Create(self.mUpLvNeedItemList, list, function(...)
            self:OnDrawNeedItemCell(...)
        end)
    end
end

function UINewSagaCurCanUpTips:SetUpInfo()
    local curStr = "Lv." .. self._curCanUpCostItem.curLv
    self:SetWndText(self.mCur, curStr)
    local nextStr = "Lv." .. self._curCanUpCostItem.upLv
    self:SetWndText(self.mNext, nextStr)
end

--设置额外的道具
function UINewSagaCurCanUpTips:CreateUpLvNeedItem_Extra(list)
    local uiUpLvList = self._uiUpLvList_extra
    if uiUpLvList then
        uiUpLvList:RefreshList(list)
    else
        uiUpLvList = self:GetUIScroll("uiUpLvList_Extra")
        self._uiUpLvList_extra = uiUpLvList
        uiUpLvList:Create(self.mUpLvNeedItemLis_Extra, list, function(...)
            self:OnDrawNeedItemCell(...)
        end)
    end
end

--endregion --------------------------------------------------------------------------------------

--region 事件 --------------------------------------------------------------------------------
function UINewSagaCurCanUpTips:OnBtnOKClick()
    self:WndClose()
    local oneClick = self._curCanUpCostItem.isOneClick
    gModelHero:OnHeroUpLevelReq(self._curCanUpCostItem.heroId, self._curCanUpCostItem.addLv,oneClick)
end

--region 初始化 --------------------------------------------------------------------------------
function UINewSagaCurCanUpTips:InitText()
    self:SetWndButtonText(self.mBtnCancel, ccClientText(19789))
    self:SetWndButtonText(self.mBtnOk, ccClientText(10102))
    self:SetWndText(self.mTitle1, ccClientText(10075))
end

function UINewSagaCurCanUpTips:InitPara()
    self._curCanUpCostItem = self:GetWndArg("curCanUpCostItem")

    self:InitNeedItemList()
    self:SetUpInfo()

end
--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UINewSagaCurCanUpTips