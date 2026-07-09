---
--- Created by Administrator.
--- DateTime: 2024/3/29 14:14:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaBookParent:LWnd
local UISagaBookParent = LxWndClass("UISagaBookParent", LWnd)

local childIndex = nil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaBookParent:UISagaBookParent()
    self._tabList = {}
    self._tabData = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaBookParent:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaBookParent:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaBookParent:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitPanelData()
    self:InitEvent()
    self:InitMessage()

    self:InitTabBtn()
    self:InitTabList()
    --self:OpenChildPanel()
    self:OnClickTabBtn(childIndex)
end
--endregion --------------------------------------------------------------------------------------

--region 注册的事件和方法 --------------------------------------------------------------------------------
function UISagaBookParent:InitEvent()

    --返回按钮
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UISagaBookParent:OpenChildPanel()
    self._btnFuncList[childIndex]()
end

function UISagaBookParent:OnDrawTab(list, item, itemData, index)

    local name = itemData.name
    self:SetWndTabText(item, name, nil, true)
    self:SetWndTabStatus(item, 1)
    self._tabList[itemData.type] = item
    self:SetWndClick(item, function(...)
        self:OnClickTabBtn(itemData.type)
    end)
    --
    local offTrans = CS.FindTrans(item, "Off")
    local onTrans = CS.FindTrans(item, "On")
    self:SetWndEasyImage(offTrans, itemData.offIcon)
    self:SetWndEasyImage(onTrans, itemData.onIcon)

    local redPoint = CS.FindTrans(item, "redPoint")

    local isRed = self:GetRedPointStatus(index)
    CS.ShowObject(redPoint, isRed)

    --按钮只有一个 所以直接记录 后续 有扩展 要做成list
    self._tujianRedPoint=redPoint
end

function UISagaBookParent:GetRedPointStatus(index)
    local showRedPoint = false
    for k, v in pairs(GameTable.CharacterRef) do
        if showRedPoint then
            break
        end

        showRedPoint = gModelHeroBook:CheckHeroBookInfoStatusByRefId(k)

    end
    return showRedPoint
end


--region 初始化数据和下方按钮部分 --------------------------------------------------------------------------------
function UISagaBookParent:InitPanelData()
    childIndex = self:GetWndArg("childIndex")
    childIndex = childIndex == nil and 1 or childIndex

    self:SetWndText(self.mTxtClose, ccClientText(30205))
end

function UISagaBookParent:InitMessage()
    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function()
        self:WndClose()
    end)

    self:WndNetMsgRecv(LProtoIds.BookChangeInfoResp, function(...)
        self:RefreshRedpoingState()
    end)
end

function UISagaBookParent:RefreshRedpoingState()
    local isRed = self:GetRedPointStatus()
    CS.ShowObject(  self._tujianRedPoint, isRed)
end

function UISagaBookParent:InitTabList()
    local uiList = self:GetUIScroll("UISagaBookParentTab")

    uiList:Create(self.mTabScroll, self._tabData, function(...)
        self:OnDrawTab(...)
    end)

    self._tabUiList = uiList
end

function UISagaBookParent:InitTabBtn()
    table.insert(self._tabData, { type = 1, name = ccClientText(19702), onIcon = "herobook_tab_1", offIcon = "herobook_tab_1" })

    if not gModelHeroBook:IgnoreHeroJB() then
        table.insert(self._tabData, { type = 2, name = ccClientText(19703), onIcon = "", offIcon = "" })
    end

    --列表的点击方法的注册
    self._btnFuncList = {
        [1] = function()
            self:CreateChildWnd(self.mChildRoot, "UISubSagaBookNew", {})
        end,
        [2] = function()
            self:CreateChildWnd(self.mChildRoot, "UISubSagaBookRelation", {})
        end,
    }
end

--UI事件
---- 下方List Btn被点击时候的方法
function UISagaBookParent:OnClickTabBtn(type)
    --GF.ShowMessage("点击了--type--" .. tostring(type))

    if self._btnFuncList[type] then
        self._btnFuncList[type]()
    end

    local oldIndex = childIndex
    childIndex = type
    self:SetWndTabStatus(self._tabList[oldIndex], 1)
    self:SetWndTabStatus(self._tabList[childIndex], 0)
end

--事件

--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UISagaBookParent