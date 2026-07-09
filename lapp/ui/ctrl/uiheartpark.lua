---
--- Created by Administrator.
--- DateTime: 2023/10/8 15:39:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHeartPark:LWnd
local UIHeartPark = LxWndClass("UIHeartPark", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHeartPark:UIHeartPark()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHeartPark:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHeartPark:OnCreate()
    LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)

    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHeartPark:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self:InitUIEvent()

    self:OnWndRefresh()

end

function UIHeartPark:OnClickTab(tabType)
    if self._curTabType == tabType then
        return
    end

    if tabType == 1 then
        local myPlayerId = gModelPlayer:GetPlayerId()
        if myPlayerId ~= self:GetWndArg("playerId") then
            local str = ccClientText(26112)--"这是Ta的隐私，你不能看呢！"
            GF.ShowMessage(str)
            return
        end
    end

    self._curTabType = tabType

    local list = self:FindUIScroll("tabList")
    if list then
        list:DrawAllItems(false)
    end

    self:OpenPage()
end

function UIHeartPark:OnDrawTab(list, item, itemdata, itempos)
    local select = self:FindWndTrans(item, "select")
    local off = self:FindWndTrans(item, "off")
    local offName = self:FindWndTrans(off, "name")
    local on = self:FindWndTrans(item, "on")
    local onName = self:FindWndTrans(on, "name")
    local redPoint = self:FindWndTrans(item, "redPoint")
    local lock = self:FindWndTrans(item, "lock")
    local lockImage = self:FindWndTrans(lock, "Image")

    local isOpen = true
    local isShow = true
    if itemdata.funcId > 0 then
        isOpen = gModelFunctionOpen:CheckIsOpened(itemdata.funcId)
        isShow = gModelFunctionOpen:CheckIsShow(itemdata.funcId)
    end

    if itemdata.tabType == 1 then
        local myPlayerId = gModelPlayer:GetPlayerId()
        if myPlayerId ~= self:GetWndArg("playerId") then
            isOpen = false
        end
    end

    --只保留放映机部分
    if itemdata.tabType == 1 then
        CS.ShowObject(item, isShow)
    end

    CS.ShowObject(lock, not isOpen)

    local isSel = self._curTabType == itemdata.tabType
    CS.ShowObject(select, isSel)

    self:SetWndEasyImage(off, itemdata.iconOff)
    self:SetWndEasyImage(on, itemdata.iconOn)

    local btnName = itemdata.name
    self:SetWndText(offName, btnName)
    self:SetWndText(onName, btnName)
    CS.ShowObject(on, isSel)
    CS.ShowObject(off, not isSel)

    self:SetWndClick(item, function()
        self:OnClickTab(itemdata.tabType)
    end)
end

function UIHeartPark:OnWndRefresh()
    local playerId = self:GetWndArg("playerId")
    local selfPlayerId = gModelPlayer:GetPlayerId()
    if playerId ~= selfPlayerId then
        local ignoreMap = {
            [ModelRedPoint.THEME_VIDEO_PLAYER] = true
        }
        self._ignoreRedId = ignoreMap
    end

    self:HideAllRedPoint()

    self:RegisterRedPoint(nil, true)

    local list = {}
    local ref = GameTable.SnakeRoleBookTyepRef
    for k, v in pairs(ref) do
        local data = {
            tabType = v.sort,
            name = ccLngText(v.name),
            iconOn = v.iconSelect,
            iconOff = v.icon,
            funcId = v.funcId
        }
        table.insert(list, data)
    end
    table.sort(list, function(a, b)
        return a.tabType < b.tabType
    end)
    local tabDataList = list

    self._curTabType = 2

    local tabList = self:FindUIScroll("tabList")
    if not tabList then
        tabList = self:GetUIScroll("tabList")
        tabList:Create(self.mTabList, tabDataList, function(...)
            self:OnDrawTab(...)
        end)
    else
        tabList:RefreshList(tabDataList)
    end

    self:OpenPage()
end

function UIHeartPark:InitUIEvent()
    self:SetWndClick(self.mBtnClose, function()
        self:WndClose()
    end)
end

function UIHeartPark:OpenPage()

    self:CloseAllChild()

    if self._curTabType == 1 then
        self:CreateChildWnd(self.mChildRoot, "UISubVideoEntrance")
    elseif self._curTabType == 2 then
        --local para =
        --{
        --	playerId = self:GetWndArg("playerId"),
        --	playerName = self:GetWndArg("playerName"),
        --}
        --self:CreateChildWnd(self.mChildRoot,"UISubBrandMap",para)
    elseif self._curTabType == 3 then
        --self:CreateChildWnd(self.mChildRoot,"UISubTreasureMap")
    end
end

------------------------------------------------------------------
return UIHeartPark


