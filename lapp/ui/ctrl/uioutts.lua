---
--- Created by Administrator.
--- DateTime: 2024/3/11 10:59:43
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOutts:LWnd
local UIOutts = LxWndClass("UIOutts", LWnd)
local childIndex = nil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOutts:UIOutts()
    self._tabList = {}
    self._tabListInfo = {}


end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOutts:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOutts:OnCreate()
    LWnd.OnCreate(self)
    FireEvent(EventNames.ON_INVASION_OPEN)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOutts:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitTabBtnData()
    self:InitPanelData()

    self:InitTabBtn()
    self:InitEvent()
    self:InitMessage()

    self:OpenChildPanel()

end

function UIOutts:OpenChildPanel()
    self._btnFuncList[childIndex]()
end

function UIOutts:GetHistory()
    local list = LWnd.GetHistory(self)
    local wndArgList = list.wndArgList
    wndArgList.childIndex = childIndex
    return list
end
--endregion --------------------------------------------------------------------------------------

--region 注册的事件和方法 --------------------------------------------------------------------------------
function UIOutts:InitEvent()
    --self:SetWndClick(self.mBtnClose, function(...)
    --    self:WndClose()
    --end)
end

function UIOutts:CreateListItem(list, item, itemdata, itempos)
    local redPoint = CS.FindTrans(item, "redPoint")
    CS.ShowObject(redPoint, false)
    self._tabList[itemdata.type] = item

    local select = CS.FindTrans(item, "Select")
    local noselect = CS.FindTrans(item, "NoSelect")

    local selectNameText = CS.FindTrans(select, "NameText")
    local noselectNameText = CS.FindTrans(noselect, "NameText")

    self:SetWndText(selectNameText, itemdata.btnName)
    self:SetWndText(noselectNameText, itemdata.btnName)

    local bool = childIndex == itemdata.type

    CS.ShowObject(select, bool)
    CS.ShowObject(noselect, not bool)

    self:SetWndClick(item, function()
        if childIndex == itemdata.type then
            return
        end

        local open, msg = gModelFunctionOpen:CheckIsOpened(itemdata.functionId)
        if not open then

            if msg then
                GF.ShowMessage(msg)
            end

            return
        end

        self:OnClickTabBtn(itemdata.type)

        self:ChangeBtn()
    end)

    --check 按钮是否开启不开启则换下底的图片
    local noSelectImg = CS.FindTrans(noselect, "Image")

    local isOpen = gModelFunctionOpen:CheckIsOpened(itemdata.functionId, false)
    local noSelectImgPath = isOpen and "public_btn_tab_off_2" or "public_btn_ash_7"
    self:SetWndEasyImage(noSelectImg, noSelectImgPath)
end

--UI事件
---- 下方List Btn被点击时候的方法
function UIOutts:OnClickTabBtn(type)
    --GF.ShowMessage("点击了--type--" .. tostring(type))

    if self._btnFuncList[type] then
        self._btnFuncList[type]()
    end

    childIndex = type
end

--region 初始化数据和下方按钮部分 --------------------------------------------------------------------------------
function UIOutts:InitPanelData()
    local openindex = 1
    if self._tabListInfo then
        for k, v in ipairs(self._tabListInfo) do
            local open, msg = gModelFunctionOpen:CheckIsOpened(v.functionId)

            if open then
                openindex = k
                break
            end
        end
    end

    --然后获取下对应的部分
    childIndex = self:GetWndArg("childIndex")
    childIndex = childIndex == nil and openindex or childIndex

    if PRODUCT_G_VER and PRODUCT_G_VER ~= 0 then
        --提审
        if gLGameLanguage:IsJapanRegion() then
            local ios = self:GetWndArg("ios")
            if ios and checknumber(ios) == 1 then
                childIndex = 1
            else
                childIndex = 2
            end

        end
    end
end

function UIOutts:InitMessage()
    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function()
        self:WndClose()
    end)
end

function UIOutts:InitTabBtn()

    --创建列表
    local uiList = self:GetUIScroll("cell")
    uiList:Create(self.mBtnScroll, self._tabListInfo, function(...)
        self:CreateListItem(...)
    end)
    self._uiList = uiList

    --列表的点击方法的注册
    self._btnFuncList = {
        [1] = function()

            local open, msg = gModelFunctionOpen:CheckIsOpened(10000030)
            if open then
                --self:CloseChildByName("UISubOuttsPVP")
                self:CloseChildByName("UISubOuttsPvpEnter")

                -- 打开郊外的PVE玩法
                self:CreateChildWnd(self.mChildRoot, "UISubOuttsPvEEnter", {})
            else
                if msg then
                    GF.ShowMessage(msg)
                end
            end
        end,
        [2] = function()

            local open, msg = gModelFunctionOpen:CheckIsOpened(10000040)
            if open then
                -- 打开郊外的PVP玩法
                --self:CreateChildWnd(self.mChildRoot, "UISubOuttsPVP", {})
                self:CloseChildByName("UISubOuttsPvEEnter")
                self:CreateChildWnd(self.mChildRoot, "UISubOuttsPvpEnter", {})
            else
                if msg then
                    GF.ShowMessage(msg)
                end
            end

        end,
    }
end

function UIOutts:ChangeBtn(type, bool)

    -- 点击之后的按钮样式的切换
    for k, v in ipairs(self._tabListInfo) do


        local item = self._tabList[v.type]

        local select = CS.FindTrans(item, "Select")
        local noselect = CS.FindTrans(item, "NoSelect")

        local bool = childIndex == v.type

        CS.ShowObject(select, bool)
        CS.ShowObject(noselect, not bool)

    end


end

function UIOutts:InitTabBtnData()
    if PRODUCT_G_VER and PRODUCT_G_VER ~= 0 then
        --提审
        if gLGameLanguage:IsJapanRegion() then
            local ios = self:GetWndArg("ios")
            if ios and checknumber(ios) == 1 then
                table.insert(self._tabListInfo, { type = 1, btnName = ccClientText(40300), img1 = "role_zone_btn_3_1", img2 = "role_zone_btn_3_2", functionId = 10000030 })
            else
                table.insert(self._tabListInfo, { type = 2, btnName = ccClientText(40301), img1 = "role_zone_btn_3_1", img2 = "role_zone_btn_3_2", functionId = 10000040 })
            end

            return
        end
    end
    table.insert(self._tabListInfo, { type = 1, btnName = ccClientText(40300), img1 = "role_zone_btn_3_1", img2 = "role_zone_btn_3_2", functionId = 10000030 })
    table.insert(self._tabListInfo, { type = 2, btnName = ccClientText(40301), img1 = "role_zone_btn_3_1", img2 = "role_zone_btn_3_2", functionId = 10000040 })
end

--事件

--endregion --------------------------------------------------------------------------------------


------------------------------------------------------------------
return UIOutts