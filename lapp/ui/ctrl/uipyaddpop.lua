---
--- Created by BY.
--- DateTime: 2023/10/6 14:30:28
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPYAddPop:LWnd
local UIPYAddPop = LxWndClass("UIPYAddPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPYAddPop:UIPYAddPop()
    self._playerOnlineKey = "_playerOnlineKeyAdd"
    self._playerOnlineIds = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPYAddPop:OnWndClose()
    self:ClearCommonIconList(self._uiheadList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPYAddPop:OnCreate()
    LWnd.OnCreate(self)
    self._uiheadList = {}
    self._typeBtnList = {}
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPYAddPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()



    self._isVie = gLGameLanguage:IsVieVersion()
    self:SetStaticContent()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    self:DisableInputText(self.mFindInput_1)
    self:DisableSensitiveInputText(self.mFindInput_1, ModelPlayer.SENSITIVE_TYPE_6)
    self:VersionRefresh()
end

function UIPYAddPop:SetStaticContent()
    local str = ccClientText(12065)
    self:SetWndButtonText(self.mNeglectBtn, str, nil, -2, -30)
    str = ccClientText(12066)
    self:SetWndButtonText(self.mConsentBtn, str, nil, -2, -30)
end
--申请
function UIPYAddPop:OnClickOputIn(playerInfo)
    gModelFriend:OnRelationProcessReq(1, gModelPlayer:GetPlayerId(), playerInfo.playerId, 1)
end

function UIPYAddPop:OnClickHeadIcon(_playerId, type)
    local openType = LPlayerShowConst.OTHER_SYSTEM
    if type == 3 then
        openType = LPlayerShowConst.BLACKLISET
    end
    gModelGeneral:PlayerShowReq(_playerId, LCombatTypeConst.COMBAT_MAIN, openType)
end

function UIPYAddPop:RefreshCellList(bEliminate)
    local dataList = {}
    if (self._oldType == 1) then
        self:CreateEmptyShow(8002)
        dataList = gModelFriend:GetFriendPopListByType(self._oldType)
    elseif (self._oldType == 2) then
        self:CreateEmptyShow(8003)
        dataList = gModelFriend:GetFriendPopListByType(self._oldType)
        local limit = gModelFriend:GetApplicationNumLimit()
        self:SetWndText(self.mAddNumText, #dataList .. "/" .. limit)
    elseif (self._oldType == 3) then
        self:CreateEmptyShow(8004)
        dataList = gModelFriend:GetFriendPopListByType(self._oldType)
    elseif (self._oldType == 4) then
        self:CreateEmptyShow(8005)
        dataList = gModelFriend:GetDelFriendData()
        self._dataList = dataList
    end
    if (bEliminate and self._oldType == 1) then
        for i = 1, #dataList do
            local playerData = dataList[i]
            if (not playerData) then
                break
            end
            local id = gModelFriend:GetRelationIdByType(2, playerData._playerId)
            if (id and id ~= "") then
                table.remove(dataList, i)
            end
        end
    end

    local isOwnFriend = false
    local playerIdList = {}
    for i, v in ipairs(dataList) do
        table.insert(playerIdList, v._playerId)
        isOwnFriend = true
    end
    self._playerIdList = playerIdList
    local _playerOnlineKey = self._playerOnlineKey
    if not isOwnFriend then
        self:TimerStop(_playerOnlineKey)
    elseif not self:IsTimerExist(_playerOnlineKey) then
        self:TimerStart(_playerOnlineKey, 60, false, -1)
    end

    self._listLen = #dataList
    CS.ShowObject(self.mNoRecord, self._listLen <= 0)
    if (self._uiList) then
        self._uiList:RefreshList(dataList)
        return
    end
    self._uiList = self:GetUIScroll("cell")
    self._uiList:Create(self.mCellListScroll, dataList, function(...)
        self:ListItem(...)
    end, UIItemList.WRAP)
end

function UIPYAddPop:VersionRefresh()
    self:InitTextSizeWithLanguage(self.mHeiText, -2)
end

function UIPYAddPop:OnClickFind()
    local name = self.mFindInput_1.text
    name = LUtil.FilterEmoji(name, "?")
    if (name == "") then
        GF.ShowMessage(ccClientText(12040))
        return
    end

    local func = function(isMatched, newText)
        if self:IsWndClosed() then
            return
        end

        if isMatched then
            --self.mFindInput_1.text = newText
            self:SetWndTextInput(self.mFindInput_1, newText)
            GF.ShowMessage(ccClientText(12496))
        else
            gModelFriend:OnRecommendReq(2, newText)
        end
    end

    LWordMaskUtil.ClearShieldWordEx(name, false, false, LGameWordMask.SCENE_TYPE_PRIVATE_CHAT, func)


    --local notice,bool = LWordMaskUtil.ClearShieldWord(name,false,ccClientText(12496))
    --if(not bool)then
    --	self.mFindInput_1.text = notice
    --	return
    --end
    --gModelFriend:OnRecommendReq(2,name)
end
function UIPYAddPop:OnReqPlayerOnline()
    local playerIdList = self._playerIdList
    if not playerIdList then
        return
    end
    gModelChat:PlayerOnlineReq(playerIdList, "4")
end
--同意
function UIPYAddPop:OnClickConsent(playerId)
    gModelFriend:OnRelationProcessReq(2, gModelPlayer:GetPlayerId(), playerId, 1)
end
--移出
function UIPYAddPop:OnClickRemove(playerId)
    gModelGeneral:OpenUIOrdinTips({ refId = 53003, func = function()
        gModelFriend:OnRelationProcessReq(3, gModelPlayer:GetPlayerId(), playerId, 2)
    end })
end

--删除好友
function UIPYAddPop:OnClickDelete(playerId)
    local refId = 50004
    local refIdStr = LPlayerPrefs.gameCommonTipAlert
    local bool = string.find(refIdStr, tostring(refId))
    if (not bool) then
        GF.OpenWnd("UIOrdinTip", { refId = refId, func = function(...)
            gModelFriend:OnRelationProcessReq(2, gModelPlayer:GetPlayerId(), playerId, 2)
        end })
    else
        gModelFriend:OnRelationProcessReq(2, gModelPlayer:GetPlayerId(), playerId, 2)
    end
end

function UIPYAddPop:CreateEmptyShow(refId)
    local data = {
        refId = refId,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UIPYAddPop:BtnListItem(list, item, itemdata, itempos)
    local btnTab1 = CS.FindTrans(item, "BtnTab1")
    self._typeBtnList[itempos] = btnTab1
    local nameText = itemdata.name
    self:SetWndTabStatus(btnTab1, LWnd.StateOff)
    self:SetWndTabText(btnTab1, nameText)
    self:SetWndClick(item, function(...)
        self:OnClickTab(itempos)
    end)
end

function UIPYAddPop:ListItem(list, item, itemdata, itempos)
    local headIcon = CS.FindTrans(item, "HeadIcon")
    local nameText = CS.FindTrans(item, "NameText")
    local serverText = CS.FindTrans(item, "ServerText")
    local powerText = CS.FindTrans(item, "IconBg/NumText")
    local funBtn = CS.FindTrans(item, "Btn1")
    local funText = CS.FindTrans(funBtn, "XUIText")
    local timeText = CS.FindTrans(item, "TimeText")

    if self._isVie then
        local level = CS.FindTrans(item, "HeadIcon/lvBg/level")
        self:SetAnchorPos(level,Vector2.New(0,-8))
    end
    local playerData = itemdata--玩家数据
    local _oldType = self._oldType
    if (not playerData) then
        return
    end
    local playerInfo = {
        trans = headIcon,
        playerId = playerData._playerId,
        name = playerData._name,
        icon = playerData._head,
        level = playerData._grade,
        headFrame = playerData._headFrame,
        _lastLogoutTime = playerData._lastLogoutTime,
        _playerState = self._playerOnlineIds[playerData._playerId] and 1 or 0
    }
    local timeStr = gModelFriend:GetLastLogoutTime(playerInfo)
    self:SetWndText(timeText, timeStr)
    local funStr = ""
    local funFunc = nil
    if (_oldType == 1) then
        funStr = ccClientText(12013)
        funFunc = function(...)
            self:OnClickOputIn(playerInfo)
        end
    elseif (_oldType == 2) then
        funStr = ccClientText(12018)
        funFunc = function(...)
            self:OnClickConsent(playerInfo.playerId)
        end
    elseif (_oldType == 3) then
        funStr = ccClientText(12024)
        funFunc = function(...)
            self:OnClickRemove(playerInfo.playerId)
        end
    else
        funStr = ccClientText(12025)
        funFunc = function(...)
            self:OnClickDelete(playerInfo.playerId)
        end
    end
    self:SetWndText(funText, funStr)
    self:SetWndClick(funBtn, function(...)
        if (funFunc) then
            funFunc()
        end
    end)
    self:SetWndClick(headIcon, function()
        self:OnClickHeadIcon(playerData._playerId, _oldType)
    end)
    --local serverName = gModelFriend:GetSevenName(playerData._serverId)

    local serverName = gModelFriend:GetSevenName(playerData._serverId)

    local allName = string.replace(ccClientText(12054), serverName) .. " " .. playerInfo.name
    self:SetWndText(nameText, allName)
    --self:SetWndText(serverText, string.replace(ccClientText(12054), serverName))
    self:SetWndText(powerText, LUtil.PowerNumberCoversion(playerData._power))

    local uiheadlist = self._uiheadList
    local InstanceID = item:GetInstanceID()
    local baseClass = uiheadlist[InstanceID]
    if not baseClass then
        baseClass = HeadIcon:New(self)
        uiheadlist[InstanceID] = baseClass
    end

    local image=_oldType == 4 and "public_btn_2_3" or "public_btn_1_2"
    self:SetWndEasyImage(funBtn, image)
    baseClass:SetHeadData(playerInfo)
    baseClass:RefreshUI()
end

function UIPYAddPop:OnClickRefresh()
    --print("刷新好友")
    gModelFriend:OnRecommendReq(1, nil, true)
end

function UIPYAddPop:InitCommand()
    self:SetWndText(self.mRecomText, ccClientText(12011))
    self:SetWndText(CS.FindTrans(self.mRefreshBtn, "XUIText"), ccClientText(12012))
    --self:SetWndText(CS.FindTrans(self.mFindInput,"Text Area/Placeholder"),ccClientText(12023))
    self:SetWndTextInput(self.mFindInput_1, nil, ccClientText(12023))
    self:SetWndText(CS.FindTrans(self.mFindBtn, "XUIText"), ccClientText(12014))
    self:SetWndText(self.mAddText, ccClientText(12021))
    self._oldType = nil--当前类型
    local list = {}
    for i = 1, 3 do
        local str = ccClientText(12014 + i)
        local data = { name = str }
        list[i] = data
    end
    list[4] = { name = ccClientText(12025) }
    self._uiBtnList = self:GetUIScroll("tab")
    self._uiBtnList:Create(self.mTypeBtnList, list, function(...)
        self:BtnListItem(...)
    end)
    local itype = self:GetWndArg("index") or 1
    if itype then
        self:OnClickTab(itype)
    else
        --if (gModelRedPoint:CheckShowRedPoint(11801010)) then
        --    self:OnClickTab(2)
        --else
            self:OnClickTab(1)
        --end
    end


    if itype == 1 then
        gModelFriend:OnRecommendReq(1)
    end

    --隐藏掉列表
    CS.ShowObject(self.mTypeBtnList, false)

end

function UIPYAddPop:OnClickOnKeyNeglect()
    if (self._listLen <= 0) then
        GF.ShowMessage(ccClientText(12041))
        return
    end
    gModelFriend:OnQuickOperalReq(2)
end

function UIPYAddPop:OnCloseFun()
    gModelFriend:OnBRelatioListnReq()
    self:WndClose()
end

function UIPYAddPop:OnClickTab(type)
    if (type and type ~= self._oldType) then
        if (self._oldType) then
            local oldTrans = self._typeBtnList[self._oldType]
            self:SetWndTabStatus(oldTrans, LWnd.StateOff)
        end
        local trans = self._typeBtnList[type]
        self:SetWndTabStatus(trans, LWnd.StateOn)
        self._oldType = type
    end
    CS.ShowObject(self.mFindFriend, false)
    CS.ShowObject(self.mAddFriend, false)
    CS.ShowObject(self.mHeiFriend, false)
    local titleStr
    if (type == 1) then
        CS.ShowObject(self.mFindFriend, true)
        self:RefreshCellList()
        titleStr = ccClientText(12015)
    elseif (type == 2) then
        gModelFriend:SetReqIdsList()
        CS.ShowObject(self.mAddFriend, true)
        gModelFriend:OnRelationListReq(1)
        titleStr = ccClientText(12016)
    elseif (type == 3) then
        self:SetWndText(self.mHeiText, ccClientText(12022))

        CS.ShowObject(self.mHeiFriend, true)
        gModelFriend:OnRelationListReq(3)
        titleStr = ccClientText(12017)
    else
        self:SetWndText(self.mHeiText, ccClientText(12052))
        --self:InitTextSizeWithLanguage(self.mHeiText, -2)
        --self:InitTextLineWithLanguage(self.mHeiText, -40)
        CS.ShowObject(self.mHeiFriend, true)
        gModelFriend:OnBRelatioListnReq()
        self:RefreshCellList()
        titleStr = ccClientText(12025)
    end

    titleStr = string.gsub(titleStr, "<br>", "")
    self:SetWndText(self.mTitleText, titleStr)
end

function UIPYAddPop:OnTimer(key)
    if self._playerOnlineKey == key then
        self:OnReqPlayerOnline()
    end
end

function UIPYAddPop:InitMessage()
    self:WndEventRecv(EventNames.FRIEND_POP_UPDATE_END, function(...)
        self:RefreshCellList()
        self:OnReqPlayerOnline()
    end)
    --self:WndEventRecv(EventNames.FRIEND_WIN_UPDATE_END, function(...)
    --	self:RefreshCellList()
    --end)
    self:WndNetMsgRecv(LProtoIds.RecommendResp, function(...)
        self:RefreshCellList()
        self:OnReqPlayerOnline()
    end)
    self:WndNetMsgRecv(LProtoIds.RelationIdResp, function(...)
        if (self._uiList) then
            self._uiList:DrawAllItems()
        end
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerOnlineResp, function(pb)
        local playerIdList = pb.playerIdList
        local moreInfo = pb.moreInfo
        if moreInfo ~= "4" then
            return
        end
        local _playerOnlineIds = {}
        for i, v in ipairs(playerIdList) do
            _playerOnlineIds[v] = true
        end
        self._playerOnlineIds = _playerOnlineIds
        self:RefreshCellList()
    end)
    self:WndNetMsgRecv(LProtoIds.RelationProcessResp, function(pb)
        local relationType = pb.relationType--关系类型（1.好友请求，2.好友，3.黑名单）
        local targetId = pb.targetId
        local type = pb.type--操作类型（1.创建，2.删除）
        if (relationType == 1) then
            self:RefreshCellList(true)
        elseif (relationType == 2 and type == 2) then
            self._targetId = targetId
            if (self._dataList) then
                local pos
                for i, v in ipairs(self._dataList) do
                    if (v._playerId == self._targetId) then
                        pos = i
                        break
                    end
                end
                if (self._uiList and pos) then
                    local uiList = self._uiList:GetList()
                    table.remove(self._dataList, pos)
                    uiList:DelDataByIndex(pos)
                    uiList:RemoveItemByDataPos(pos)
                end
            end
        end
        self:OnReqPlayerOnline()
    end)
    self:WndNetMsgRecv(LProtoIds.RelationListChangeResp, function(...)
        if (self._oldType == 4) then
            gModelFriend:OnBRelatioListnReq()
        end
    end)
end

function UIPYAddPop:InitEvent()
    self:SetWndClick(self.mBgImage, function(...)
        self:OnCloseFun()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose, function(...)
        self:OnCloseFun()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mRefreshBtn, function(...)
        self:OnClickRefresh()
    end)
    self:SetWndClick(self.mFindBtn, function(...)
        self:OnClickFind()
    end)
    self:SetWndClick(self.mNeglectBtn, function(...)
        self:OnClickOnKeyNeglect()
    end)
    self:SetWndClick(self.mConsentBtn, function(...)
        self:OnClickOnKeyConsent()
    end)
end
--一键同意
function UIPYAddPop:OnClickOnKeyConsent()
    local listLen = self._listLen or 0
    if (listLen <= 0) then
        GF.ShowMessage(ccClientText(12041))
        return
    end
    gModelFriend:OnQuickOperalReq(1)
end
------------------------------------------------------------------
return UIPYAddPop


