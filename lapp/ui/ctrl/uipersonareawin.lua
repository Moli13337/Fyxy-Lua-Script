---
--- Created by BY.
--- DateTime: 2023/10/24 18:13:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPersonAreaWin:LWnd
local UIPersonAreaWin = LxWndClass("UIPersonAreaWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPersonAreaWin:UIPersonAreaWin()
    self._tabList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPersonAreaWin:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPersonAreaWin:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPersonAreaWin:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._isAmerica = LGameLanguage:IsAmericaRegion()


    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitEvent()
    self:InitMessage()

    self:InitCommand(gModelPlayerSpace:GetCurrSpaceInfo())
    self:UpdateBgImg(gModelPlayer:GetPlayerFigure())

    --local playerId = self:GetWndArg("playerId") or gModelPlayer:GetPlayerId()
    --gModelPlayerSpace:OnPlayerSpaceReq(playerId)
    self:SetAreaShow()

end

function UIPersonAreaWin:OnTryTcpReconnect()
    self:WndClose()
end

function UIPersonAreaWin:RefreshData()
    local list = self._btnList
    local uiList = self.tabList
    if uiList then
        uiList:RefreshList(list)
    end
end


function UIPersonAreaWin:SetAreaShow()
    if self._isAmerica   then
        local haveNum = gModelItem:GetNumByRefId(100304)

        if haveNum > 0 then
            CS.ShowObject(self.mGoldDiv, true)
            local icon = gModelItem:GetItemIconByRefId(100304)

            self:SetWndEasyImage(self.mGoldicon, icon)
            self:SetWndText(self.mGoldNum, haveNum)

            self:SetWndClick(self.mGoldDiv,function()

                gModelGeneral:ShowCommonItemTipWnd({itemId=100304,itemType=LItemTypeConst.TYPE_ITEM})
            end)
        else
            CS.ShowObject(self.mGoldDiv, false)
        end
    end
end

function UIPersonAreaWin:UpdateBgImg(figure)
    local res = gModelPlayer:GetRoleAdventureImageRefByRefId(figure)
    if res then
        self:SetWndEasyImage(self.mBgImage, res.heroBg)
        self:CreateLiHui(res.skinSpineBg, res.skinSpineHd)
    end
end

function UIPersonAreaWin:CreateLiHui(skinSpineBg, skinSpineHd)
    if not string.isempty(skinSpineBg) then
        self:DestroyWndSpineByKey("skinSpineBg")
        self:CreateWndSpine(self.mHeroLiHuiBgPos, skinSpineBg, "skinSpineBg", false)
    else
        self:DestroyWndSpineByKey("skinSpineBg")
    end
    if not string.isempty(skinSpineHd) then
        self:DestroyWndSpineByKey("skinSpineHd")
        self:CreateWndSpine(self.mHeroLiHuiHdPos, skinSpineHd, "skinSpineHd", false)
    else
        self:DestroyWndSpineByKey("skinSpineHd")
    end
end

function UIPersonAreaWin:InitMessage()
    self:WndEventRecv(EventNames.ON_ZONE_SPINE, function()
        self:OnClickBtn(3)
    end)
    self:WndNetMsgRecv(LProtoIds.PersonaliseNewInfoResp, function(...)
        self:RefreshData(...)
    end)
    self:WndNetMsgRecv(LProtoIds.PersonaliseClickInfoResp, function(...)
        self:RefreshData(...)
    end)
    self:WndEventRecv(EventNames.ON_ZONE_HEROLIST, function()
        self:RefreshData()
    end)

    self:WndEventRecv(EventNames.ON_SPACE_PLAY_FIGURE_CHANGE, function()
        self:UpdateBgImg(gModelPlayer:GetPlayerFigure())
    end)
    self:WndEventRecv("UISubAreaFigure_change_figure", function(...)
        self:UpdateBgImg(...)
    end)

    --self:WndNetMsgRecv(LProtoIds.PlayerSpaceResp, function(pb)
    --	local spaceInfo = gModelPlayerSpace:FormatPlayerSpaceInfo(pb)
    --	self:InitCommand(spaceInfo)
    --end)
end

function UIPersonAreaWin:OnDrawTab(_, item, itemData)
    local Off = self:FindWndTrans(item, "Off")
    local On = self:FindWndTrans(item, "On")
    self:SetWndEasyImage(Off, itemData.Off)
    self:SetWndEasyImage(On, itemData.On)
    Off.sizeDelta = Vector2.New(86, 82)
    On.sizeDelta = Vector2.New(86, 82)
    local s = 0
    local l = 0
    if self.jpj then
        s = -2
        l = -40
    end
    self:SetWndTabText(item, itemData.title,s,l)
    self:SetWndTabStatus(item, self._type == itemData.type and 0 or 1)
    self.tabBtn[itemData.type] = item
    self:SetWndClick(item, function(...)
        self:OnClickBtn(itemData.type)
    end)
end

function UIPersonAreaWin:InitCommand(spaceInfo)
    local _currInfo = spaceInfo -- gModelPlayerSpace:GetCurrSpaceInfo()

    --local isShowZoneCareer = gModelFunctionOpen:CheckIsShow(17500010)
    self._isShowZoneCareer = false

    local list = {
        { type = 1, title = ccClientText(21100), On = "role_zone_btn_1_1", Off = "role_zone_btn_1_1" },
    }
    if _currInfo then
        self._isMe = _currInfo.isMe
    else
        return
    end

    local isMe = self:GetWndArg("isMe")
    if isMe then
        self._isMe = true
    end

    if self._isMe then
        local isCanInsert = true
        if PRODUCT_G_VER ~= 0 then
            if gLGameLanguage:IsJapanRegion() then
                isCanInsert = false
            elseif gLGameLanguage:IsChinaRegion() then
                isCanInsert = false
            end
        end
        if isCanInsert then
            table.insert(list, {
                type = 3,
                title = ccClientText(21102),
                On = "role_zone_btn_3_1",
                Off = "role_zone_btn_3_1"
            })
        end
        if gModelFunctionOpen:CheckIsOpened(18008000) then
            table.insert(list, {
                type = 4,
                title = ccClientText(30300),
                On = "role_zone_btn_5_1",
                Off = "role_zone_btn_5_1"
            })
        end
        -- table.insert(list, {
        -- 	type = 4,
        -- 	title = ccClientText(21103),
        -- 	On = "role_zone_btn_4_1",
        -- 	Off = "role_zone_btn_4_1"
        -- })
    end
    local list2 = {}
    for i = #list, 1, -1 do
        table.insert(list2, list[i])
    end
    self._btnList = list2

    self.tabBtn = {}
    self.tabList = self:GetUIScroll("TabScroll")
    self.tabList:Create(self.mTabScroll, list2, function(...)
        self:OnDrawTab(...)
    end)

    local btnType = self:GetWndArg("page") or list2[#list2].type
    self._subPage = self:GetWndArg("subPage")
    self:OnClickBtn(btnType)
end

function UIPersonAreaWin:OnClickBtn(type)
    if self._type == type then
        return
    end
    local oldType = self._type
    self._type = type
    self:SetWndTabStatus(self.tabBtn[oldType], 1)
    self:SetWndTabStatus(self.tabBtn[type], 0)
    local _subPage = self._subPage
    self:CloseAllChild()
    if type == 1 then
        self:CreateChildWnd(self.mChildRoot, "UISubAreaCompile")
    elseif type == 3 then
        self:CreateChildWnd(self.mChildRoot, "UISubAreaFigure", { page = _subPage })
    elseif type == 4 then
        self:CreateChildWnd(self.mChildRoot, "UISubMCitySn")
    end
end

function UIPersonAreaWin:InitEvent()
    self:SetWndClick(self.mCloseBtn, function(...)
        self:WndClose()
    end)
    self:SetWndText(self:FindWndTrans(self.mCloseBtn, "TxtClose"), ccClientText(30205))
end
------------------------------------------------------------------
return UIPersonAreaWin


