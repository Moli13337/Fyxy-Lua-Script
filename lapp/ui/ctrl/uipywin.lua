---
--- Created by BY.
--- DateTime: 2023/10/6 11:14:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPYWin:LWnd
local UIPYWin = LxWndClass("UIPYWin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPYWin:UIPYWin()
    self._playerOnlineIds = {}
    self._playerOnlineKey = "_playerOnlineKeyFriend"
    self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPYWin:OnWndClose()
    if self._isTrueOneKey then
        gModelGeneral:SetAlertId(99999999)
    end
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPYWin:OnCreate()
    LWnd.OnCreate(self)
    self._uiheadList = {}
    self._bChat = false
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPYWin:OnStart()
    LWnd.OnStart(self)
    self:InitUI()



    self.jpj = gLGameLanguage:IsJapanVersion()
    self:InitView()
    self:InitEvent()
    self:InitMessage()
    self:InitCommand()
    self:DisableInputText(self.mFindInput)
    self:DisableSensitiveInputText(self.mFindInput, ModelPlayer.SENSITIVE_TYPE_6)

    self:InitFriendOptTabData()
    self:CreateFriendOptTabList()
    

end

function UIPYWin:OnClickReqGift(playerId)
    --赠送
    if (not gModelFriend:GetIsOnGift()) then
        GF.ShowMessage(ccClientText(12063))
        return
    end
    if (gModelFriend:GetBGift(playerId)) then
        GF.ShowMessage(ccClientText(12029))
        return
    end
    gModelFriend:OnGiftProcessReq(2, playerId)
end

function UIPYWin:OnClickRespGift(playerId)
    --领取
    if (not gModelFriend:GetIsOnGet()) then
        GF.ShowMessage(ccClientText(12062))
        return
    end
    if (not gModelFriend:GetBGet(playerId)) then
        GF.ShowMessage(ccClientText(12030))
        return
    end
    if (gModelFriend:GetBReceive(playerId)) then
        GF.ShowMessage(ccClientText(12031))
        return
    end
    gModelFriend:OnGiftProcessReq(1, playerId)
end
function UIPYWin:OnClickCloseWnd()
    self:WndClose()
end

function UIPYWin:ListItem(list, item, itemdata, itempos)
    local headIcon = CS.FindTrans(item, "HeadIcon")
    local nameText = CS.FindTrans(item, "NameText")
    local serverText = CS.FindTrans(item, "ServerText")
    local powerText = CS.FindTrans(item, "PowerBg/PowerText")
    local timeText = CS.FindTrans(item, "TimeText")
    local reqGiftBtn = CS.FindTrans(item, "ReqGiftBtn")
    local reqEff = CS.FindTrans(item, "ReqGiftBtn/ReqEff")
    local respGiftBtn = CS.FindTrans(item, "RespGiftBtn")
    local VisitSpaceBtn = CS.FindTrans(item, "VisitSpaceBtn")

    local InstanceID = item:GetInstanceID()
    local playerData = itemdata--玩家数据
    if (not playerData) then
        return
    end
    local playerInfo = {
        trans = headIcon,
        playerId = playerData._playerId,
        name = playerData._name,
        icon = playerData._head,
        headFrame = playerData._headFrame,
        level = playerData._grade,
        serverId = playerData._serverId,
        spaceName = playerData._spaceName,
        power = playerData._power,
        _lastLogoutTime = playerData._lastLogoutTime,
        _playerState = self._playerOnlineIds[playerData._playerId] and 1 or 0
    }
    self:SetWndClick(headIcon, function(...)
        self:OnClickHeadIcon(playerInfo)
    end)
    local timeStr = gModelFriend:GetLastLogoutTime(playerInfo)
    self:SetWndText(timeText, timeStr)
    local serverName = gModelFriend:GetSevenName(playerInfo.serverId)

    local allName = string.replace(ccClientText(12054), serverName) .. " " .. playerInfo.name

    self:SetWndText(nameText, allName)
    --self:SetWndText(serverText,string.replace(ccClientText(12054),serverName))
    self:SetWndText(powerText, LUtil.PowerNumberCoversion(playerInfo.power))

    --local reqGiftText=CS.FindTrans(reqGiftBtn,"XUIText")
    --local reqGiftImage=CS.FindTrans(reqGiftBtn,"Image")
    --local btnStr,btnImage
    local isOnGift = gModelFriend:GetIsOnGift()
    local isReqGift = gModelFriend:GetBGift(playerInfo.playerId)
    CS.ShowObject(reqGiftBtn, not isReqGift and isOnGift)
    --if not isReqGift and isOnGift then
    --	self:CreateWndEffect(reqEff,"fx_ui_shou_3",InstanceID,100)
    --end
    --if(isReqGift)then
    --	--btnStr = ccClientText(12005)
    --	btnImage = "friend_icon_6"
    --else
    --	--btnStr = ccClientText(12004)
    --	btnImage = "friend_icon_4"
    --end
    --self:SetWndEasyImage(reqGiftImage,btnImage)
    --self:SetWndText(reqGiftText,btnStr)
    self:SetWndClick(reqGiftBtn, function(...)
        self:OnClickReqGift(playerInfo.playerId)
    end)
    --领取
    local isGet = gModelFriend:GetIsOnGet()
    local isNowGet = gModelFriend:GetBGet(playerInfo.playerId)
    local isReceive = gModelFriend:GetBReceive(playerInfo.playerId)
    local isShow = isGet and isNowGet and not isReceive
    CS.ShowObject(respGiftBtn, isShow)
    --if isShow then
    --	local respGiftText=CS.FindTrans(respGiftBtn,"XUIText")
    --	self:SetWndText(respGiftText,ccClientText(12006))
    --end
    self:SetWndClick(respGiftBtn, function(...)
        self:OnClickRespGift(playerInfo.playerId)
    end)

    --self:SetWndClick(VisitSpaceBtn, function(...)
    --	if string.isempty(playerInfo.spaceName) then
    --		GF.ShowMessage(ccClientText(22840))
    --	else
    --		if self._backFunc then self._backFunc() end
    --		GF.OpenWndWait("UIOneNightSpaceOpenEffect", {type = 1, targetId = playerInfo.playerId})
    --	end
    --
    --end)

    local uiheadlist = self._uiheadList
    local baseClass = uiheadlist[InstanceID]
    if not baseClass then
        baseClass = HeadIcon:New(self)
        uiheadlist[InstanceID] = baseClass
    end
    baseClass:SetHeadData(playerInfo)
    baseClass:RefreshUI()
end

function UIPYWin:OnClickAddLove()
    local id = gModelFriend:GetFindLoveId()
    gModelGeneral:OpenGetWayWnd({ itemId = id, srcWnd = self:GetWndName() })
end

function UIPYWin:OnClickHelp()
    GF.OpenWnd("UIBzTips", { refId = 53 })
end

function UIPYWin:InitMessage()
    self:WndEventRecv(EventNames.FRIEND_WIN_UPDATE_END, function(...)
        self:RefreshFriend()
        self:OnReqPlayerOnline()
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerOnlineResp, function(pb)
        local playerIdList = pb.playerIdList
        local moreInfo = pb.moreInfo
        if moreInfo ~= "3" then
            return
        end
        local _playerOnlineIds = {}
        for i, v in ipairs(playerIdList) do
            _playerOnlineIds[v] = true
        end
        self._playerOnlineIds = _playerOnlineIds
        self:RefreshFriend()
    end)
    self:WndNetMsgRecv(LProtoIds.GiftProcessResp, function(...)
        self:RefreshFriend()
    end)
    self:WndNetMsgRecv(LProtoIds.FriendGiftResp, function(...)
        self:RefreshFriend()
    end)
    self:WndNetMsgRecv(LProtoIds.RelationListChangeResp, function(...)
        gModelFriend:OnBRelatioListnReq()
    end)
    self.mFindInput.onValueChanged:AddListener(function(str)
        self:OnInputDes(str)
    end)
end

function UIPYWin:OnInputDes(str)
    local length = LxUtf8.cnLen(str)
    if (length > self._inputMax) then
        str = self._oldStr
        self:SetWndTextInput(self.mFindInput, str)
        GF.ShowMessage(ccClientText(12068))
    else
        self._oldStr = str
    end
end

function UIPYWin:DoSelectItem(index)
    if self._oldOptItem then
        --操作旧的
    end

    local curItem = self._optItem[index]

    --操作新的

    self._oldOptItem = curItem
end

function UIPYWin:GetHistory()
    local list = LWnd.GetHistory(self)
    local wndArgList = list.wndArgList
    wndArgList.lookPlayerId = self._lookPlayerId
    return list
end

function UIPYWin:InitCommand()
    self._bChat = self:GetWndArg("bChat")
    self:SetWndText(self.mTitleText, ccClientText(12000))
    local manageText = CS.FindTrans(self.mManageBtn, "XUIText")
    self:SetWndText(manageText, ccClientText(12001))
    self:InitTextLineWithLanguage(manageText, -30)
    self:InitTextSizeWithLanguage(manageText, -2)
    local oneKeyText = CS.FindTrans(self.mOneKeyBtn, "XUIText")
    self:SetWndText(oneKeyText, ccClientText(12002))
    self:InitTextLineWithLanguage(oneKeyText, -30)

    self:SetWndTextInput(self.mFindInput, nil, ccClientText(12067))
    self:SetWndText(CS.FindTrans(self.mFindBtn, "XUIText"), ccClientText(23902))

    self._inputMax = gModelFriend:GetFriendConfigRefByKey("foundNum")

    self.lookPlayerId = self:GetWndArg("lookPlayerId")
    gModelFriend:OnRelationListReq(2)

    self:RefreshFriend()
end

function UIPYWin:onClickFindFriend()
    local findName = self.mFindInput.text;
    if not findName or string.len(findName) == 0 then
        GF.ShowMessage(ccClientText(12069))
    end
    self:RefreshFriend()


end
function UIPYWin:OnClickBackWnd()
    if self._backFunc then
        self._backFunc()
        self:WndClose()
    else
        self:WndCloseAndBack()
    end
end

function UIPYWin:OnTimer(key)
    if self._playerOnlineKey == key then
        self:OnReqPlayerOnline()
    end
end

function UIPYWin:CreateEmptyShow(refId)
    local data = {
        refId = refId,
        IntroTran = self.mEmptyText,
        TextBgTran = self.mEmptyTextBg,
        IconTran = self.mEmptyIcon,
    }
    local emptyList = self:GetCommonEmptyList("_empty")
    emptyList:RefreshUI(data)
end

function UIPYWin:OnClickOneKey()
    --一键
    local playerIds = {}
    local list = gModelFriend:GetFriendData()
    for i, v in ipairs(list) do
        if (not gModelFriend:GetBGift(v._playerId)) then
            table.insert(playerIds, v._playerId)
        end
    end
    gModelFriend:OnGiftProcessReq(3, nil, playerIds)
end

function UIPYWin:CreateFriendOptTabList()
    local uiList = self._optList

    if uiList then
        uiList:RefreshList(self._friendOptData)
        uiList:DrawAllItems(true)
    else
        uiList = self:GetUIScroll("UIPYWin_OptList")
        uiList:Create(self.mFuncBtnList, self._friendOptData, function(...)
            self:OnDrawOptItem(...)
        end, UIItemList.SUPER)
        uiList:EnableScroll(false,true)
    end


end

function UIPYWin:OnTryTcpReconnect()
    gModelFriend:OnRelationListReq(2)
end

function UIPYWin:OnClickHeadIcon(playerInfo)
    if (self._bChat) then
        if gModelChat:OnClickOpenChat({ channel = ModelChat.CHANNEL_PRIVATE, playerInfo = playerInfo }) then
            self:OnClickCloseWnd()
        end
    else
        self._lookPlayerId = playerInfo.playerId
        gModelGeneral:PlayerShowReq(playerInfo.playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
    end
end
function UIPYWin:OnDrawOptItem(list, item, itemdata, itempos)

    if not self._optItem then
        self._optItem = {}
    end
    self._optItem[itempos] = item

    local itemtran = CS.FindTrans(item, "Item")
    local name = CS.FindTrans(itemtran, "UIText")
    if self.jpj then
        LxUiHelper.SetSizeWithCurAnchor(name, 0, 80)
        self:InitTextLineWithLanguage(name,-30)
        local uiText =LxUiHelper.FindXTextCtrl(name)
        uiText.enableWordWrapping = true
        self:SetAnchorPos(self.mFuncBtnList,Vector2.New(-268.6,-160))
        self.mFuncBtnList.sizeDelta =Vector2.New(524.6,100)
    end

    self:SetWndText(name, itemdata.name)
    self:SetWndEasyImage(itemtran,itemdata.icon)
    self:SetWndClick(item, function()
        GF.OpenWnd(itemdata.openWnd, itemdata.openArg)
    end)

    if itempos== 3 then
        self:RegisterRedPoint()

    end
end

function UIPYWin:RefreshFriend()
    --local list=gModelFriend:GetFriendData()
    local list = {}
    local list2 = gModelFriend:GetFriendData();
    local findName = self.mFindInput.text
    if not string.isempty(findName) then
        for k, v in pairs(list2) do
            local name = v:GetName()
            local s, t, str = string.find(name, findName)
            if s then
                --list[k] = v
                table.insert(list, v)
            end
        end
    else
        list = list2
    end
    local isOwnFriend = false
    local playerIdList = {}
    for i, v in ipairs(list2) do
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

    CS.ShowObject(self.mNoRecord, #list <= 0)
    if (#list <= 0) then
        if not string.isempty(findName) then
            self:CreateEmptyShow(20005)
        else
            self:CreateEmptyShow(8001)
        end
    elseif not gModelGeneral:FindAlertId(99999999) then
        local giftPlayers = gModelFriend:GetGiftPlayerList()--已送礼的玩家Id列表
        local receivePlayers = gModelFriend:GetReceiveList()--已领取爱心的的玩家Id列表
        local getPlayers = gModelFriend:GetPlayerList()--可领取爱心的的玩家Id列表

        local sendLoveNum = gModelFriend:GetFindSendLoveNum()--每天赠送爱心上限
        local receiveLoveNum = gModelFriend:GetFindReceiveLoveNum()--每天接收爱心上限

        local isSendGift = false    --是否能送礼
        local isGetGift = false        --是否能收礼

        local receiveNum = 0
        for i, v in pairs(receivePlayers) do
            receiveNum = receiveNum + 1
        end
        if receiveNum < receiveLoveNum then
            for i, v in pairs(getPlayers) do
                if not receivePlayers[v] then
                    isGetGift = true
                    break
                end
            end
        end

        local sendNum = 0
        for i, v in pairs(giftPlayers) do
            sendNum = sendNum + 1
        end
        if sendNum < sendLoveNum then
            for i, v in ipairs(list) do
                if not giftPlayers[v._playerId] then
                    isSendGift = true
                    break
                end
            end
        end

        local isOneKey = isGetGift or isSendGift
        CS.ShowObject(self.mOneKeyEff, isOneKey)
        if isOneKey then
            self:CreateWndEffect(self.mOneKeyEff, "fx_ui_shou_3", "fx_ui_shou_3_UIPYWin_", 100)
            self._isTrueOneKey = true
        end
    end
    local _uiList = self._uiList
    if _uiList then
        _uiList:RefreshList(list)
    else
        _uiList = self:GetUIScroll("_uiList")
        self._uiList = _uiList
        _uiList:Create(self.mCellListScroll, list, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER)
    end
    local lookPlayerId = self.lookPlayerId
    if lookPlayerId and #list > 0 then
        self.lookPlayerId = nil
        local index = 1
        for i, v in ipairs(list) do
            if v._playerId == lookPlayerId then
                index = i
            end
        end
        _uiList:MoveToPos(index)
    else
        _uiList:DrawAllItems()
    end

    self:SetWndText(self.mFriendshipText, gModelFriend:GetFriendship())
    self:SetWndText(self.mFriendText, #list .. "/" .. gModelFriend:GetFriendLimit())
    local giftNum = gModelFriend:GetGiftPlayerNum()
    local giftEx = gModelFriend:GetFindSendLoveNum()
    giftNum = giftNum < giftEx and giftNum or giftEx
    self:SetWndText(self.mPresentedText, string.replace(ccClientText(12060), giftNum, giftEx))
end

function UIPYWin:InitView()
    self._openType = self:GetWndArg("openType") or 0
    self._backFunc = self:GetWndArg("backFunc")

    if self._openType == 1 then
        CS.ShowObject(self.mBgImage, false)
        CS.ShowObject(self.mCloseBtn, false)
    else
        CS.ShowObject(self.mBgImage, true)
        CS.ShowObject(self.mCloseBtn, true)
    end
end
function UIPYWin:OnReqPlayerOnline()
    local playerIdList = self._playerIdList
    if not playerIdList then
        return
    end
    gModelChat:PlayerOnlineReq(playerIdList, "3")
end

function UIPYWin:OnClickManage()
    --管理
    GF.OpenWnd("UIPYAddPop")
end

function UIPYWin:InitEvent()
    self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN, function()
        self:OnClickCloseWnd()
    end)
    self:SetWndClick(self.mCloseBtn, function(...)
        self:OnClickBackWnd()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBgImage, function(...)
        self:OnClickBackWnd()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mManageBtn, function(...)
        self:OnClickManage()
    end)
    self:SetWndClick(self.mOneKeyBtn, function(...)
        self:OnClickOneKey()
    end)
    self:SetWndClick(self.mPresentedNum, function(...)
        self:OnClickHelp()
    end)
    self:SetWndClick(self.mFriendshipNum, function(...)
        self:OnClickAddLove()
    end)
    self:SetWndClick(self.mFindBtn, function(...)
        self:onClickFindFriend()
    end)
end

--region 新增tab部分 --------------------------------------------------------------------------------
function UIPYWin:InitFriendOptTabData()
    self._friendOptData = {
        --删除好友
        [1] = { name = ccClientText(12073), openArg = { index = 4 }, openWnd = "UIPYAddPop", icon = "friend_btn_2" },
        --黑名单
        [2] = { name = ccClientText(12072), openArg = { index = 3 }, openWnd = "UIPYAddPop", icon = "friend_btn_1" },
        --申请列表
        [3] = { name = ccClientText(12071), openArg = { index = 2 }, openWnd = "UIPYAddPop", icon = "friend_btn_3" },


    }
end
--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIPYWin


