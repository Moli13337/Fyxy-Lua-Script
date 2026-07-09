---
--- Created by BY.
--- DateTime: 2023/10/11 22:33:43
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISayAddPY:LWnd
local UISayAddPY = LxWndClass("UISayAddPY", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISayAddPY:UISayAddPY()
    self._tabTransList = {}
    self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISayAddPY:OnWndClose()
    self:ClearCommonIconList(self._uiheadList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISayAddPY:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISayAddPY:OnStart()
    LWnd.OnStart(self)
    self:InitUI()

    self._reqGuildMemberTicker = 0

    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
end

function UISayAddPY:CreateEmptyShow(refId)
    local text = self:FindWndTrans(self.mEmptyBtn, "Light/Text")
    local data = {
        refId = refId,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
        GetBtn = self.mEmptyBtn,
        GetBtnText = text,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UISayAddPY:ListItem(list, item, itemdata, itempos)
    local headIcon = CS.FindTrans(item, "HeadIcon")
    local nameText = CS.FindTrans(item, "NameText")
    local serverText = CS.FindTrans(item, "ServerText")
    local powerText = CS.FindTrans(item, "IconBg/NumText")
    local timeText = CS.FindTrans(item, "TimeText")
    local btn1 = CS.FindTrans(item, "Btn1")

    local playerData = itemdata.info or itemdata--玩家数据
    if (not playerData) then
        return
    end
    local playerInfo = {
        trans = headIcon,
        playerId = playerData._playerId,
        icon = playerData._head,
        headFrame = playerData._headFrame,
        level = playerData._grade,
    }

    self:SetWndText(nameText, playerData._name)
    local serverName = gModelFriend:GetSevenName(playerData._serverId)
    self:SetWndText(serverText, string.replace(ccClientText(12054), serverName))
    self:SetWndText(powerText, LUtil.PowerNumberCoversion(playerData._power))
    local timeStr = gModelFriend:GetLastLogoutTime(playerData)
    self:SetWndText(timeText, timeStr)

    local uiheadlist = self._uiheadList
    local InstanceID = item:GetInstanceID()
    local baseClass = uiheadlist[InstanceID]
    if not baseClass then
        baseClass = HeadIcon:New(self)
        uiheadlist[InstanceID] = baseClass
    end
    baseClass:SetHeadData(playerInfo)
    baseClass:RefreshUI()

    local isFriend = gModelFriend:GetBFriend(playerData._playerId)
    local str = isFriend and ccClientText(11140) or ccClientText(11141)
    self:SetWndButtonText(btn1, str, nil, -4)
    self:SetWndClick(btn1, function()
        if isFriend then
            self:OnClickChat(playerData)
        else
            self:OnClickAddFriends(playerData)
        end
    end)
    self:SetWndClick(headIcon, function()
        self:OnClickHeadIcon(playerData._playerId)
    end)
end

function UISayAddPY:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose, function(...)
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)

end

function UISayAddPY:InitCommand()
    self:SetWndText(self.mLblBiaoti, ccClientText(11144))
    local list = {
        { type = 1, title = ccClientText(11142) },
        { type = 2, title = ccClientText(11143) },
    }
    local _uiList = self:GetUIScroll("_uiFriendTypeList")
    _uiList:Create(self.mTypeBtnList, list, function(...)
        self:TypeListItem(...)
    end)
    self:OnClickTab(list[1].type)
    gModelFriend:OnRelationListReq(2)
    local isGuild = gModelGuild:GetBHaveGuild()
    if isGuild then
        local guildInfo = gModelGuild:GetGuildInfo()
        gModelGuild:OnGuildMemberListReq(guildInfo.guildId)
    end

end

-- 点击加好友
function UISayAddPY:OnClickAddFriends(_playerInfo)
    gModelFriend:OnRelationProcessReq(1, gModelPlayer:GetPlayerId(), _playerInfo._playerId, 1)
end

function UISayAddPY:TypeListItem(list, item, itemdata, itempos)
    local btnTab1 = CS.FindTrans(item, "BtnTab1")
    self._tabTransList[itemdata.type] = btnTab1
    self:SetWndTabText(btnTab1, itemdata.title)
    self:SetWndTabStatus(btnTab1, 1)
    self:SetWndClick(item, function()
        self:OnClickTab(itemdata.type)
    end)
end

function UISayAddPY:OnClickTab(type)
    local _tab = self._tabTransList
    local _type = self._type
    if _type then
        local trans = _tab[_type]
        self:SetWndTabStatus(trans, 1)
    end
    local trans = _tab[type]
    self._type = type
    self:SetWndTabStatus(trans, 0)
    self:RefreshData()
end

function UISayAddPY:RefreshData()
    local type = self._type
    local list = {}
    if type == 1 then
        list = gModelFriend:GetFriendData()
        if (#list <= 0) then
            self:CreateEmptyShow(8001)
        end
    else
        local isGuild = gModelGuild:GetBHaveGuild()
        if isGuild then
            local guildInfo = gModelGuild:GetGuildInfo()
            local guildMemberList = gModelGuild:GetGuildMemberList()
            local _playerId = gModelPlayer:GetPlayerId()
            for i, v in ipairs(guildMemberList) do
                local playerId = v.info._playerId
                if _playerId ~= playerId then
                    table.insert(list, v)
                end
            end
            if (#list <= 0) and self._reqGuildMemberTicker <= 5 then
                self._reqGuildMemberTicker = self._reqGuildMemberTicker + 1
                self:CreateEmptyShow(5403)
                gModelGuild:OnGuildMemberListReq(guildInfo.guildId)
            else
                self._reqGuildMemberTicker = 0
            end
        else
            self:CreateEmptyShow(5402)
        end
    end
    CS.ShowObject(self.mNoRecord, #list <= 0)
    local _uiList = self._uiList
    if (_uiList) then
        _uiList:RefreshList(list)
        _uiList:DrawAllItems()
    else
        _uiList = self:GetUIScroll("_uiList")
        _uiList:Create(self.mCellSuper, list, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER)
        _uiList:EnableScroll(true, false)
        self._uiList = _uiList
    end
end

function UISayAddPY:OnClickHeadIcon(_playerId)
    gModelGeneral:PlayerShowReq(_playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
end

function UISayAddPY:InitMessage()
    self:WndEventRecv(EventNames.FRIEND_WIN_UPDATE_END, function(...)
        self:RefreshData()
    end)
    self:WndNetMsgRecv(LProtoIds.GuildMemberListResp, function(pb)
        self:RefreshData()
    end)
end
-- 点击私聊
function UISayAddPY:OnClickChat(_playerInfo)
    if (not gModelFunctionOpen:CheckIsOpened(11706000, true)) then
        return
    end
    local playerInfo = {
        playerId = _playerInfo._playerId,
        name = _playerInfo._name,
        icon = _playerInfo._head,
        headFrame = _playerInfo._headFrame,
        serverId = _playerInfo._serverId
    }

    gModelChat:OnClickOpenChat({ channel = ModelChat.CHANNEL_PRIVATE, playerInfo = playerInfo })
    FireEvent(EventNames.ON_CHAT_SKIP_PRIVATE, { channel = ModelChat.CHANNEL_PRIVATE, playerInfo = playerInfo })
    self:WndClose()
end
------------------------------------------------------------------
return UISayAddPY


