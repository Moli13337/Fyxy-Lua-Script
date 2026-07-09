---
--- Created by BY.
--- DateTime: 2023/10/9 14:25:05
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISayPop:LWnd
local UISayPop = LxWndClass("UISayPop", LWnd)
local typeof = typeof
local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)

UISayPop.PopType_1 = 1        --窗口常态
UISayPop.PopType_2 = 2        --窗口缩放

UISayPop.TabType_1 = 1        --频道常态
UISayPop.TabType_2 = 2        --频道缩放
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISayPop:UISayPop()
    self._popType = 1
    self._tabType = 1
    self._uiHyperList = {}
    self._uiHeadList = {}
    self._bubbleTypeList = {}
    self._funBtnList = {}
    self._pointerUpKey = "_pointerUpKey"
    self._isOpentAdd = false
    self._addTypeList = {}
    self._uicommonList = {}
    self._playerOnlineIds = {}
    self._playerOnlineKey = "_playerOnlineKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISayPop:OnWndClose()
    FireEvent(EventNames.ON_CHAT_TA_SHOW, true)
    if CS.IsValidObject(self.mInputChat) then
        gModelChat:SetInputMsg(self.mInputChat.text)
    end
    LPlayerPrefs.SetChatPopState(tostring(self._popType))
    gModelChat:DelAllTranslate()
    local _currChannel = self._currChannel
    if _currChannel then
        _currChannel = _currChannel == ModelChat.CHANNEL_PRIVATE and ModelChat.CHANNEL_WORLD or _currChannel
        local ref = gModelChat:GetChatChannelRefByChannelId(_currChannel)
        if ref then
            gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT, "关闭聊天", ccLngText(ref.channel))
            LPlayerPrefs.SetGameChatChannel(tostring(_currChannel))
        end
    end
    self:ClearCommonIconList(self._uiHyperList)
    self:ClearCommonIconList(self._uiHeadList)
    self:ClearCommonIconList(self._uicommonList)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISayPop:OnCreate()
    FireEvent(EventNames.ON_CHAT_TA_SHOW, false)
    gModelChat:GetChatSaveToFile()--读取私聊
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISayPop:OnStart()
    LWnd.OnStart(self)
    self:InitUI()



    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitFullViewPara()

    self:InitEvent()
    self:InitMessage()
    self:InitData()
    self:InitCommand()
end
function UISayPop:OnClickHead(itemdata)
    if self._isLongClisk then
        self._isLongClisk = false
        return
    end
    if (not itemdata.playerId or itemdata.playerId == "") then
        return
    end
    local playerId = gModelPlayer:GetPlayerId()
    if itemdata.playerId == playerId then
        GF.ShowMessage(ccClientText(11522))
        return
    end
    if (self._currChannel == ModelChat.CHANNEL_PROVINCE) then
        --- ChatConfigRef.provinceReport  省份频道：0=弹举报，1=弹详情。没有key默认为0
        local provinceReport = gModelChat:GetChatConfigRefByKey("provinceReport") or 0
        if provinceReport == 0 then
            gModelGeneral:OpenUIOrdinTips(
                    {
                        refId = 50001,
                        para = { itemdata.playerName },
                        func = function(...)
                            gModelFriend:OnRelationProcessReq(3, playerId, itemdata.playerId, 1)
                        end,
                        leftFunc = function(...)
                            if (gModelFunctionOpen:CheckIsOpened(11799000, true)) then
                                GF.OpenWnd("UIRepin", { channelId = itemdata.channel, channelIndex = itemdata.number })
                            end
                        end
                    }
            )
            return
        end
    end
    if itemdata.playerId == "-1" then
        GF.ShowMessage(ccClientText(11122))
        return
    end
    gModelGeneral:PlayerShowReq(itemdata.playerId, LCombatTypeConst.COMBAT_SHOW_BATTLE, LPlayerShowConst.CHAT_SYSTEM, itemdata.channel, itemdata.number or 1)
end
function UISayPop:CombatListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local icon = self:FindWndTrans(root, "Icon")
    local nameText = self:FindWndTrans(root, "NameText")
    local powerText = self:FindWndTrans(root, "PowerBg_1/PowerText")

    if gLGameLanguage:IsJapanVersion() then
        LxUiHelper.SetSizeWithCurAnchor(nameText,0,200)
        self:InitTextSizeWithLanguage(nameText,-3)
    end

    self:SetWndEasyImage(icon, itemdata.campIcon)
    self:SetWndText(nameText, ccLngText(itemdata.name))
    local power = gModelPower:GetFormationPower(itemdata.refId)
    local force = LUtil.PowerNumberCoversion(power)
    self:SetWndText(powerText, force)
    self:SetWndClick(root, function()
        GF.OpenWnd("UISpreadCombatPop", {
            channel = self._currChannel,
            combatType = itemdata.refId,
            atPlayerId = self._currPritavePlayer and self._currPritavePlayer.playerId,
            func = function()
                self:OnClickCloseAdd()
            end
        })
    end)
end
function UISayPop:OnClickChannel(itemdata, itempos)
    local bool = gModelChat:GetChatChannelIsOpent(itemdata.channelId, 1, true)
    if not bool then
        --if itemdata.channelId == ModelChat.CHANNEL_PROVINCE then
        --	self:OnClickSet()
        --end
        return
    end
    self._tabIndex = itempos
    self._currChannel = itemdata.channelId
    self:SetWndText(self.mChannelNameText, itemdata.titleName)
    gModelChat:DelChannelRed(itemdata.channelId)
    self:RefreshChannelTabSel(itempos)
    CS.ShowObject(self.mChannelTips, itemdata.channelId == ModelChat.CHANNEL_SYSTEM)
    CS.ShowObject(self.mBottomMar, itemdata.channelId ~= ModelChat.CHANNEL_SYSTEM)
    self:RefreshAddBtnStatus()
    if itemdata.channelId == ModelChat.CHANNEL_GUILD then
        if not gModelGuild:GetBHaveGuild() then
            CS.ShowObject(self.mNoRecord, true)
            self:CreateEmptyShow(5402)
            --CS.ShowObject(self.mMsgSuperMin,false)
            --CS.ShowObject(self.mMsgSuperMax,false)
            local listPara = self:GetListRootPara()
            CS.ShowObject(listPara.root)
            return
        end
    end
    self:RefreshMsg()
end
function UISayPop:SetMsgShow(item, root, itemdata, msg, isTag, isVipTip, InstanceID)
    local emojiImage = self:FindWndTrans(root, "EmojiImage")
    local chatBg = self:FindWndTrans(root, "ChatBg")
    local textTran = self:FindWndTrans(root, "ChatBg/XUIText")
    if itemdata.type == ModelChat.MSGTYPE_GUILDNOTICE or itemdata.type == ModelChat.MSGTYPE_NOTICE then
        msg = gModelChat:SetChatSkipFun(textTran, InstanceID, itemdata, msg, self._uiHyperList, self:GetWndName())
    end
    msg = self:SetATPlayerName(msg, itemdata.atPlayerName)
    msg = LUtil.GetFaceStr(msg, 46)
    local isShare, shareInfo = gModelChat:SetShareType(itemdata, msg)
    if isShare then
        msg = gModelChat:OnAddHyper(textTran, InstanceID, shareInfo, self._uiHyperList)
    else
        msg = shareInfo
    end
    self:GetChatInfoWidth(msg, chatBg, item, isTag, itemdata.bubble, isVipTip)
    chatBg.anchoredPosition = Vector2.New(chatBg.anchoredPosition.x, isTag and -80 or -60)
    self:SetWndText(textTran, msg)
end
function UISayPop:PlayerOnlineResp(pb)
    local playerIdList = pb.playerIdList
    local moreInfo = pb.moreInfo
    if moreInfo ~= "1" then
        return
    end
    --local isOnline = false
    local _playerOnlineIds = {}
    for i, v in ipairs(playerIdList) do
        _playerOnlineIds[v] = true
        --isOnline = true
    end
    --if not isOnline then return end
    self._playerOnlineIds = _playerOnlineIds
    local uiList = self._tabType == UISayPop.TabType_1 and self._uiTabSuperMin or self._uiTabSuperMax
    if not uiList:GetList() then
        return
    end
    uiList:DrawAllItems()
end
function UISayPop:GetChatWidth(msg, addW)
    self:SetWndText(self.mTestText, msg)
    local width = self.mTestText_1.preferredWidth + (addW or 0)
    if (width > 325) then
        width = 325
    end
    return width
end
function UISayPop:RefreshTypeScroll(list)
    local _uiTypeList = self._uiTypeList
    if _uiTypeList then
        _uiTypeList:RefreshList(list)
    else
        _uiTypeList = self:GetUIScroll("mTypeScroll")
        _uiTypeList:Create(self.mTypeScroll, list, function(...)
            self:TypeListItem(...)
        end)
        self._uiTypeList = _uiTypeList
        _uiTypeList:EnableScroll(true, true)
    end
end

function UISayPop:RefreshData()
    local _currChannel = self._currChannel
    if _currChannel == 6 then
        if(not self._currPritavePlayer)then
            local currPrivateInfo = gModelChat:GetPrivateCurPlayerInfo()
            local playerData = currPrivateInfo.playerInfo
            local tabType = currPrivateInfo.type
            local tabIdx = currPrivateInfo.itempos
            self._currPritavePlayer = playerData.playerInfo
            if(self._currPritavePlayer)then
                local privateInfo = gModelChat:GetPrivatePlayerInfo()
                if(privateInfo)then
                    self._callFun = privateInfo.callBack
                    self._currChannel = privateInfo.channel
                    self._privatePlayerInfo = privateInfo.playerInfo
                end
                self:OnClickTab(tabType,playerData,tabIdx)
                return
            end
        end
    end
    self:RefreshMsg()
end
function UISayPop:OnClickCloseBubble()
    CS.ShowObject(self.mBottomChat, true)
    CS.ShowObject(self.mChatBubbleMar, false)
    CS.ShowObject(self.mBubbleMask, false)
end

-- 【C宠物系统】删掉宠物系统相关
-- function UISayPop:RefreshPetList(itemdata)
-- 	local list = gModelPetSpace:GetPetDictByType(itemdata.rank-1,1)
-- 	self:RefreshItemList(list)
-- end

function UISayPop:RefreshHeroList(itemdata)
    local list = gModelHero:GetHeroListByType(itemdata.race)
    self:RefreshItemList(list)
end
---点击方法
function UISayPop:OnClickClose()
    --关闭界面
    local _callFun = self._callFun
    if _callFun ~= nil then
        _callFun()
    end
    self:WndClose()
end
function UISayPop:OnClickSave()
    local useId = gModelPlayer:GetBubble()
    local _curSelBubble = self._curSelBubble
    if useId == _curSelBubble then
        GF.ShowMessage(ccClientText(21153))
        return
    end
    self:OnClickCloseBubble()
    local activateLis = gModelPlayer:GetPersonaliseInfo(ModelPlayerSpace.BUBBLE) or {}
    local isActivate = activateLis[_curSelBubble] and activateLis[_curSelBubble].state == 0
    if isActivate then
        gModelPlayerSpace:OnPersonaliseChangeTotalReq(nil, nil, nil, nil, nil, nil, nil, _curSelBubble)
    else
        local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(_curSelBubble)
        if ref.jump == 0 then
            GF.ShowMessage(ccLngText(ref.description))
            return
        end
        gModelFunctionOpen:Jump(ref.jump, self:GetWndName())
        self:WndClose()
    end
end
function UISayPop:SystemListItem(item, itemdata, itempos)
    local system = self:FindWndTrans(item, "System")
    local bImage = self:FindWndTrans(system, "BImage")
    local desText = self:FindWndTrans(system, "XUIText")
    local nameText = self:FindWndTrans(system, "Image/XUIText")

    local InstanceID = item:GetInstanceID()
    local name = gModelChat:GetMailNoticesRefName(tonumber(itemdata.atPlayerId))
    local msg = itemdata:GetMsg()

    CS.ShowObject(bImage, itempos % 2 == 0)
    self:SetWndText(nameText, name)
    msg = gModelChat:SetChatSkipFun(desText, InstanceID, itemdata, msg, self._uiHyperList, self:GetWndName())
    msg = self:SetATPlayerName(msg, itemdata.atPlayerName)

    self:SetWndText(desText, msg)
    self:GetSysInfoWidth(msg, bImage, item)

    local elementTypeDescTxt = self:FindWndText(desText)

    if elementTypeDescTxt then
        local descHeight = elementTypeDescTxt.preferredHeight

        bImage.rect.height = descHeight + 10
    end

    if self._isForeign then
        self:InitTextSizeWithLanguage(nameText, -2)
    end
    if self._isVie then
        self:InitTextCharacterWithLanguage(nameText,-5)
        self:InitTextSizeWithLanguage(nameText,-4.5)
    end
    --如果是空的隐藏下
    if string.isempty(msg) then
        CS.ShowObject(item, false)
    else
        CS.ShowObject(item, true)
    end
end
function UISayPop:OnReqPlayerOnline()
    local playerIdList = self._playerIdList or {}
    if #playerIdList <= 0 then
        return
    end
    local _playerOnlineIds = {}
    for i, v in ipairs(playerIdList) do
        if v.playerId then
            _playerOnlineIds[v.playerId] = false
        end
    end
    self._playerOnlineIds = _playerOnlineIds
    gModelChat:PlayerOnlineReq(playerIdList, "1")
end
function UISayPop:SetChatPlayer(item, itemdata)
    local rateMar = CS.FindTrans(item, "RateMar")
    local severText = self:FindWndTrans(item, "SeverText")
    local sex = self:FindWndTrans(item, "Sex")
    local nameText = self:FindWndTrans(item, "NameText")

    local severStr = ""
    if itemdata.channel == ModelChat.CHANNEL_PROVINCE then
        local city = gModelChat:GetRoleCityListRefByRefId(itemdata.city)
        severStr = string.replace(ccClientText(11126), city)
    elseif itemdata.channel == ModelChat.CHANNEL_SERVE then
        local sevenName
        if not string.isempty(itemdata.serverName) then
            sevenName = itemdata.serverName
        else
            sevenName = gModelFriend:GetSevenName(itemdata.serverId)
        end
        severStr = sevenName and string.replace(ccClientText(11125), sevenName)
    end
    --local sexStr = itemdata.sex == 1 and "role_zone_ui_man" or "role_zone_ui_woman"
    local sexStr = gModelPlayer:GetDefaultIcon()

    local nameStr = itemdata.sex == 1 and string.replace(ccClientText(11148), itemdata.playerName) or string.replace(ccClientText(11147), itemdata.playerName)
    local title = itemdata.title

    self:SetWndText(severText, severStr)
    self:SetWndEasyImage(sex, sexStr)
    CS.ShowObject(sex, false)
    self:SetWndText(nameText, nameStr)
    CS.ShowObject(rateMar, title and title > 0)
    if title and title > 0 then
        self:SetTitleLevel(rateMar, itemdata)
    end

    LxTimer.DelayFrameCall(function()
        UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(item)
    end)
end
function UISayPop:OtherListItem(item, itemdata, itempos)
    local other = self:FindWndTrans(item, "Other")
    local otherMar = self:FindWndTrans(other, "OtherMar")
    local headIcon = self:FindWndTrans(other, "HeadRoot/HeadIcon")
    local chatBg = self:FindWndTrans(other, "ChatBg")
    local vipTitle = self:FindWndTrans(other, "VipTitle")
    local emojiImage = self:FindWndTrans(other, "EmojiImage")
    local emojiSpine = self:FindWndTrans(other, "EmojiSpine")
    local tagItemRoot = self:FindWndTrans(other, "TagItemRoot")
    local btnTranslate = self:FindWndTrans(other, "BtnTranslate")
    local translateLine = self:FindWndTrans(other, "TranslateLine")
    local gradeIcon = self:FindWndTrans(otherMar, "GradeIcon")

    local InstanceID = item:GetInstanceID()
    local msg = itemdata:GetMsg()
    local faceId = LUtil.ChatInfoGetDaFace(msg)
    local isForeign = gLGameLanguage:IsUSARegion()
    local isShowTranslate = isForeign and self._languageLen > 1 and faceId <= 0

    self:SetChatPlayer(otherMar, itemdata)
    self:SetHeadIcon(headIcon, itemdata, InstanceID)
    local isShowVipTip = self:SetVipTip(vipTitle, itemdata)
    CS.ShowObject(vipTitle, isShowVipTip)
    local isShowTag = self:SetTabItemRoot(tagItemRoot, itemdata)
    CS.ShowObject(tagItemRoot, isShowTag)
    CS.ShowObject(btnTranslate, isShowTranslate)
    CS.ShowObject(translateLine, isShowTranslate)
    if isShowTranslate then
        self:SetTranslate(item, itemdata, msg, isShowTag)
    end
    CS.ShowObject(chatBg, faceId <= 0)
    if faceId > 0 then
        self:SetBigFace(item, other, faceId, InstanceID, isShowTag)
    else
        CS.ShowObject(emojiImage, false)
        CS.ShowObject(emojiSpine, false)
        self:SetChatBubble(chatBg, itemdata.bubble, false)
        self:SetMsgShow(item, other, itemdata, msg, isShowTag, isShowVipTip, InstanceID)
    end
    self:SetGradeIcon(gradeIcon, itemdata, false)
    self:SetWndClick(headIcon, function()
        self:OnClickHead(itemdata)
    end)
    -- 长按
    self:SetWndLongClick(headIcon, function()
        self:OnLongClickHead(itemdata)
    end, 0.8, false)

    --
    local report = CS.FindTrans(chatBg, "BtnReport")
    if report then
        CS.ShowObject(report, false)
    end

    if gLGameLanguage:IsJapanRegion() then
        if PRODUCT_G_VER ~= 0 then
            local isIos = CS.IsOSIos()
            if isIos then
                local report = CS.FindTrans(chatBg, "BtnReport")
                local isSystem = itemdata.playerId == "-1"
                CS.ShowObject(report, not isSystem)
                self:SetWndClick(report, function()
                    gModelGeneral:OpenUIOrdinTips({ refId = 50010 })
                end)
            end
        end
    end
end
function UISayPop:TypeListItem(list, item, itemdata, itempos)
    local image = self:FindWndTrans(item, "Image")
    local selectImage = self:FindWndTrans(item, "SelectImage")
    local uiText = self:FindWndTrans(item, "UIText")

    local icon, selIcon, nameStr = "", "", ""
    if itemdata.type == ModelChat.EXTENDFUN_TYPE_1 then
        icon = itemdata.icon
        selIcon = itemdata.iconChecked
    elseif itemdata.type == ModelChat.EXTENDFUN_TYPE_2 then
        icon = itemdata.icon
        selIcon = itemdata.iconChecked
        --local showText = gModelChat:GetChatConfigRefByKey("showText") or 1
        --if showText == 1 then
        --    nameStr = ccLngText(itemdata.name)
        --end
        -- 【C宠物系统】删掉宠物系统相关
        -- elseif itemdata.type == ModelChat.EXTENDFUN_TYPE_5 then
        -- 	icon = itemdata.icon
        -- 	selIcon = itemdata.iconChecked
        -- 	nameStr = ""
    else
        icon = itemdata.icon
        selIcon = itemdata.iconChecked
        nameStr = ccLngText(itemdata.name)
    end
    self._addTypeList[itemdata.refId] = selectImage

    self:SetWndEasyImage(image, icon)
    self:SetWndEasyImage(selectImage)

    --屏蔽掉筛选部分的文字
    --self:SetWndText(uiText,nameStr)
    if gLGameLanguage:IsJapanRegion() and itemdata.type == ModelChat.EXTENDFUN_TYPE_2 and itempos == 1 then
        self:InitTextSizeWithLanguage(uiText, -2)
    end

    self:SetWndClick(item, function()
        self:OnClickAddItemType(itemdata)
    end)
end

function UISayPop:OnChatMsgPushResp(pb)
    local _currPritavePlayer = self._currPritavePlayer
    local _currChannel = self._currChannel
    if _currPritavePlayer and _currChannel == ModelChat.CHANNEL_PRIVATE then
        gModelChat:DelPrivateRed(_currPritavePlayer.playerId)
        --else
        --	gModelChat:DelChannelRed(_currChannel)
    end

    local _btnDataList = self._btnDataList or {}
    local list = {}
    for i, v in ipairs(_btnDataList) do
        if v.type == 1 then
            list[v.channelId] = i
        elseif v.type == 3 then
            list[v.playerInfo.playerId] = i
        end
    end
    local msgs = pb.msgs
    local playerId
    for i, v in ipairs(msgs) do
        local channel = v.channel
        playerId = v.playerId
        local index = list[channel]
        if channel == ModelChat.CHANNEL_PRIVATE then
            index = list[v.playerId]
        end

        if index then
            self:RefreshChannelTabByPos(index)
            break
        end
    end

    for i, v in ipairs(msgs) do
        local channel = v.channel
        if channel == self._currChannel then
            self:RefreshMsg()
            break
        end
    end

end
function UISayPop:ItemListItem(list, item, itemdata, itempos)
    local root = CS.FindTrans(item, "Root")

    local uiCommonList = self._uicommonList
    local InstanceID = item:GetInstanceID()
    local baseClass = uiCommonList[InstanceID]
    if not baseClass then
        baseClass = CommonIcon:New(self)
        uiCommonList[InstanceID] = baseClass
        baseClass:Create(root)
    end
    if (itemdata.itemType == 2) then
        baseClass:SetHeroPlayer(itemdata.id)
    elseif (itemdata.itemType == 4) then
        baseClass:SetCommonReward(itemdata.itemType, itemdata.refId, nil)
    elseif (itemdata.itemType == LItemTypeConst.TYPE_OUTFIT) then
        baseClass:SetOutfitId(itemdata.id)

    else
        baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    end
    self:SetWndClick(root, function()
        self:OnClickShare(itemdata)
    end)
    baseClass:DoApply()
end
function UISayPop:RefreshFaceType()
    CS.ShowObject(self.mEmojiList, true)
    local list = gModelChat:GetEmojiTypeRef()
    self:RefreshTypeScroll(list)
    if #list > 0 then
        self:OnClickAddItemType(list[1])
    end
end
function UISayPop:RefreshFaceList(itemdata)
    local list = {}
    local cfgList = gModelChat:GetEmojiByType(itemdata.faceType)
    local textType = itemdata.textType
    for i, v in ipairs(cfgList) do
        table.insert(list,{
            cfg = v,
            textType = textType,
        })
    end
    CS.ShowObject(self.mEmojiScroll, textType == 1)
    CS.ShowObject(self.mEmojiScroll2, textType ~= 1)
    local _uiEmojiList = textType == 1 and self._uiEmojiList1 or self._uiEmojiList2
    if _uiEmojiList then
        _uiEmojiList:RefreshList(list)
    else
        local mEmojiScroll = textType == 1 and self.mEmojiScroll or self.mEmojiScroll2
        _uiEmojiList = self:GetUIScroll("mEmojiScroll" .. textType)
        _uiEmojiList:Create(mEmojiScroll, list, function(...)
            self:EmojiListItem(...)
        end)
        if textType == 1 then
            self._uiEmojiList1 = _uiEmojiList
        else
            self._uiEmojiList2 = _uiEmojiList
        end
        _uiEmojiList:EnableScroll(true, false)
    end
end

function UISayPop:SetATPlayerName(msg, name)
    local str = msg
    local text = string.match(msg, "%@" .. name)
    if (text) then
        str = string.gsub(str, text, "<u>" .. text .. "</u>", 1)
    end
    return str
end

function UISayPop:GetHistory()
    local list = LWnd.GetHistory(self)
    local wndArgList = list.wndArgList
    wndArgList.channel = self._currChannel
    return list
end
function UISayPop:RefreshBagType()
    CS.ShowObject(self.mCommScroll, true)
    local list = gModelChat:GetChatBtnScreenRefListByType(ModelChat.EXTENDFUN_TYPE_3)
    self:RefreshTypeScroll(list)
    if #list > 0 then
        self:OnClickAddItemType(list[1])
    end
end
function UISayPop:SetBigFace(item, root, faceId, InstanceID, isTag)
    local emojiImage = self:FindWndTrans(root, "EmojiImage")
    local emojiSpine = self:FindWndTrans(root, "EmojiSpine")
    local faceRef = gModelChat:GetChatFaceRefByRefId(faceId)
    if faceRef then
        local isSpine = faceRef.isSpine and faceRef.isSpine == 1
        CS.ShowObject(emojiSpine, isSpine)
        CS.ShowObject(emojiImage, not isSpine)
        if isSpine then
            self:DestroyWndSpineByKey(InstanceID)
            self:CreateWndSpine(emojiSpine, faceRef.faceSpine, InstanceID, false, function(dpSpine)
                dpSpine:SetScale(0.9)
                local dpTrans = dpSpine:GetDisplayTrans()
                dpTrans.anchorMin = Vector2.New(0.5, 0.5)
                dpTrans.anchorMax = Vector2.New(0.5, 0.5)
                dpTrans.pivot = Vector2.New(0.5, 0.5)
            end)
            emojiSpine.anchoredPosition = Vector2.New(emojiSpine.anchoredPosition.x, isTag and -57 or -50)
        else
            self:SetWndEasyImage(emojiImage, faceRef.faceIcon)
            emojiImage.anchoredPosition = Vector2.New(emojiImage.anchoredPosition.x, isTag and -57 or -50)
        end
    end
    local higth = isTag and 206 or 186
    LxUiHelper.SetSizeWithCurAnchor(item, 1, higth)
end
function UISayPop:SetTabItemRoot(item, itemdata)
    local isTag = false
    local tags = itemdata.tag
    local chatTagIndex = 0
    local chatTagNum = gModelPlayer:GetRoleConfigRefByKey("chatTagNum") or 5
    local chatTagDis = gModelPlayer:GetRoleConfigRefByKey("chatTagDis") or 5

    for i = 1, 5 do
        local item = self:FindWndTrans(item, "TagItem" .. i)
        CS.ShowObject(item, false)
    end
    for i, v in ipairs(tags) do
        local tag = v
        local type = type(tag)
        if type == "number" then
            if tag > 0 then
                chatTagIndex = chatTagIndex + 1
                if chatTagIndex > chatTagNum then
                    break
                end
                isTag = true
                local tagItem = self:FindWndTrans(item, "TagItem" .. i)
                local tagText = self:FindWndTrans(tagItem, "UIText")

                CS.ShowObject(tagItem, true)
                local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(tag)
                if ref then
                    self:SetWndEasyImage(tagItem, ref.tagBg)
                    self:SetWndText(tagText, LUtil.FormatColorStr(ccLngText(ref.name), "#" .. ref.tagColour))
                    if gLGameLanguage:IsJapanVersion() then
                        self:InitTextSizeWithLanguage(tagText, -2)
                    end

                    if gLGameLanguage:IsForeignVersion() then
                        local uiText = LxUiHelper.FindXTextCtrl(tagText)
                        local width = uiText.preferredWidth
                        local itemW = width + chatTagDis
                        if itemW < 58 then
                            itemW = 58
                        end
                        local layoutEle = tagItem:GetComponent(typeLayoutElement)
                        if layoutEle then
                            layoutEle.preferredWidth = itemW
                        end
                    end
                end
            end
        end
    end
    return isTag
end
---扩展功能
function UISayPop:RefreshAddFun()
    local btnList = gModelChat:GetChatBtnRefListByChannle(self._currChannel)
    if #btnList < 1 then return end
    local type = self._btnType or btnList[1].type

    --如果是省服 则切换成表情部分
    if ModelChat.CHANNEL_PROVINCE == self._currChannel then
        type = btnList[1].type
    end
    self:RefreshAddFunTypeItem(btnList, type)
    self:OnClickAddFunTypeBtn(type)
end

function UISayPop:InitEvent()
    self:SetWndClick(self.mBgImage, function()
        self:OnClickClose()
    end)
    self:SetWndClick(self.mBtnClose, function()
        self:OnClickClose()
    end)
    self:SetWndClick(self.mBtnScale, function()
        self:OnClickScale()
    end)
    self:SetWndClick(self.mBtnSet, function()
        self:OnClickSet()
    end)
    self:SetWndClick(self.mBtnClickSet, function()
        self:OnClickSet()
    end)
    self:SetWndClick(self.mBtnSend, function()
        self:OnClickSend()
    end)
    self:SetWndClick(self.mBtnAdd, function()
        self:OnClickAdd()
    end)
    self:SetWndClick(self.mBtnBubble, function()
        self:OnClickBubble()
    end)
    self:SetWndClick(self.mBtnClickBubble, function()
        self:OnClickBubble()
    end)
    self:SetWndClick(self.mBtnSave, function()
        self:OnClickSave()
    end)
    self:SetWndClick(self.mBtnCloseBubble, function()
        self:OnClickCloseBubble()
    end)
    self:SetWndClick(self.mBubbleMask, function()
        self:OnClickCloseBubble()
    end)
    self:SetWndClick(self.mAddFunMask, function()
        self:OnClickCloseAdd()
    end)
    self:SetWndClick(self.mBtnSpread, function()
        self:OnClickSpread()
    end)
    self:SetWndClick(self.mBtnLessen, function()
        self:OnClickLessen()
    end)
    self:SetWndClick(self.mBtnDelDown, function()
        self:OnClickDelDown()
    end)
    self:SetWndClick(self.mCloseFriend, function()
        if self._currPritavePlayer then
            self:OnClickDelFrind(self._currPritavePlayer)
        end
    end)
    self:SetWndClick(self.mCrossBtn, function()
        local serverList, groupId = gModelChat:GetServers()
        GF.OpenWnd("UIKfSyerGroupingPop", {
            wndType = 2,
            groupId = groupId,
            serverList = serverList
        })
    end)
end
function UISayPop:InitCommand()
    self:SetWndText(self.mTipsText, ccClientText(11135))
    self:SetWndText(self.mSetNameText, ccClientText(11158))
    self:SetWndText(self.mBubbleNameText, ccClientText(11161))
    self:SetWndButtonText(self.mBtnSend, ccClientText(12433))
    self:SetWndButtonText(self.mBtnCloseBubble, ccClientText(11160))
    self._isForeignFr = gLGameLanguage:IsFrenchVersion()

    self._isForeign = gLGameLanguage:IsForeignVersion()
    local chatPopState = LPlayerPrefs.chatPopState or "1"
    self._popType = tonumber(chatPopState)

    self:SetMsgContentType()

    local channelId = self:GetWndArg("channel")
    if not channelId then
        channelId = tonumber(LPlayerPrefs.gameChatChannel)
    end
    if channelId ~= -1 then
        if (not gModelChat:GetChatChannelIsOpent(channelId, 3, false)) then
            channelId = ModelChat.CHANNEL_WORLD
        end
    end
    self._callFun = self:GetWndArg("call")
    local playerInfo = self:GetWndArg("playerInfo")
    self._privatePlayerInfo = playerInfo

    gModelChat:SetPrivatePlayerInfo({channel=channelId,callBack = self._callFun,playerInfo=playerInfo})
    
    self._currChannel = channelId

    if channelId and channelId > 0 then
        gModelChat:DelChannelRed(channelId)
    end

    self.mInputChat.characterLimit = gModelChat:GetChatConfigRefByKey("chatWordLimit")
    local _inputMsg = gModelChat:GetInputMsg()
    if _inputMsg and _inputMsg ~= "" then
        self:SetWndTextInput(self.mInputChat, _inputMsg)
    else
        self:SetWndTextInput(self.mInputChat, nil, ccClientText(11133))
    end
    CS.ShowObject(self.mChatBubbleMar, false)
    CS.ShowObject(self.mBottomChat, true)
    CS.ShowObject(self.mBottomMar, channelId ~= ModelChat.CHANNEL_SYSTEM)
    CS.ShowObject(self.mAddFun, false)
    CS.ShowObject(self.mAddFunMask, false)
    CS.ShowObject(self.mBubbleMask, false)
    if playerInfo then
        self:RefreshChannelTab(playerInfo.playerId)
    else
        self:RefreshChannelTab()
    end
    self:RefreshData()
    self:RefreshAddBtnStatus()
end

function UISayPop:SetMsgContentType()
    local position = nil
    local sizeDelta = nil
    local isFull = gModelChat:GetChatSetValue(17)
    local listShow = 1
    if isFull then
        local para = gModelChat:GetChatConfigRefByKey("chatListMax")
        position = Vector2.New(0, 0)
        sizeDelta = Vector2.New(600, para)
        listShow = 3
    else
        local popType = self._popType
        if popType == UISayPop.PopType_1 then
            position = Vector2.New(0, 13.5)
            sizeDelta = Vector2.New(640, 893)
            listShow = 1
        else
            position = Vector2.New(0, 29.5)
            sizeDelta = Vector2.New(640, 680)
            listShow = 2
        end
    end
    self.mPop.localPosition = position
    self.mPop.sizeDelta = sizeDelta

    CS.ShowObject(self.mMsgSuperMin, listShow == 2)
    CS.ShowObject(self.mMsgSuperMax, listShow == 1)
    CS.ShowObject(self.mMsgSuperFull, listShow == 3)

    CS.ShowObject(self.mBtnScale, listShow == 1 or listShow == 2)
end
function UISayPop:SetTranslate(item, itemdata, msg, isTag)
    local btnTranslate = self:FindWndTrans(item, "Other/BtnTranslate")
    local translateLine = self:FindWndTrans(item, "Other/TranslateLine")
    local isOnlyFace = LUtil.CheckInfoOnlyFace(msg)
    local translate = gModelChat:GetTranslate(itemdata.channel, itemdata.number)
    if itemdata.type ~= ModelChat.MSGTYPE_NORMAL and itemdata.type ~= ModelChat.MSGTYPE_AT or isOnlyFace then
        CS.ShowObject(btnTranslate, false)
        CS.ShowObject(translateLine, false)
    elseif translate then
        local height = self:GetChatHeight(msg .. "\n\n")
        local width = self:GetChatWidth(msg, 14)
        local lh = isTag and -62 or -42
        translateLine.anchoredPosition = Vector2.New(136, -height + lh + 7)
        translateLine.sizeDelta = Vector2.New(width, 2)
        self:SetWndEasyImage(btnTranslate, "chat_btn_translate_2")
        msg = msg .. "\n\n" .. LUtil.GetFaceStr(translate, 46)
        self:SetWndClick(btnTranslate, function()
            gModelChat:DelTranslate(itemdata)
        end)
    else
        self:SetWndEasyImage(btnTranslate, "chat_btn_translate_1")
        self:SetWndClick(btnTranslate, function()
            gModelChat:SetTranslate(itemdata)
        end)
    end
    local width = self:GetChatWidth(msg) + 124 + 42
    btnTranslate.anchoredPosition = Vector2.New(width, isTag and -82 or -62)
end
function UISayPop:OnClickBubble()
    self:OnClickCloseAdd()
    CS.ShowObject(self.mBottomChat, false)
    CS.ShowObject(self.mAddFun, false)
    CS.ShowObject(self.mAddFunMask, false)
    CS.ShowObject(self.mChatBubbleMar, true)
    CS.ShowObject(self.mBubbleMask, true)
    self:RefreshBubbleType()
end
function UISayPop:SetChatBubble(item, bubbleId, isMe)
    local initChatBg = gModelPlayer:GetRoleConfigRefByKey("initChatBg")
    local refId = initChatBg
    if bubbleId and bubbleId > 0 then
        refId = bubbleId
    end
    local arrows = self:FindWndTrans(item, "Arrows")
    local uiText = self:FindWndTrans(item, "XUIText")
    local pendantList = {}
    for i = 1, 4 do
        local pendant = self:FindWndTrans(item, "Pendant" .. i)
        pendantList[i] = pendant
    end
    local roleRef = gModelPlayer:GetRolePlayerHeadRefByRefId(refId)
    if not roleRef then
        --self:SetWndEasyImage(item,isMe and "chat_bg_1" or "chat_bg_2")
        --self:SetWndEasyImage(arrows,isMe and "chat_arrow_1" or "chat_arrow_2")
        self:SetWndEasyImage(item, isMe and "chat_frame_bg_1_1" or "chat_frame_bg_1_1")
        self:SetWndEasyImage(arrows, isMe and "chat_frame_bg_1_2_1" or "chat_frame_bg_1_2_1")
        for i, v in ipairs(pendantList) do
            CS.ShowObject(v, false)
        end
        --local color = isMe and "734f22ff" or "e5e5e5ff"
        --color = LUtil.ColorByHex(color)
        --local xuitxt = self:FindWndText(uiText)
        --self:SetXUITextColor(xuitxt, color)
        arrows.anchoredPosition = Vector2.New(arrows.anchoredPosition.x, -20)
        return
    end
    local iconArr = string.split(roleRef.icon, "|")
    self:SetWndEasyImage(item, iconArr[1])
    self:SetWndEasyImage(arrows, iconArr[2])
    --self:SetWndEasyImage(item,"chat_frame_bg_1_1")
    --self:SetWndEasyImage(arrows,"chat_frame_bg_1_2")
    for i, v in ipairs(pendantList) do
        local iconStr = iconArr[i + 2] or "0"
        CS.ShowObject(v, iconStr ~= "0")
        if iconStr ~= "0" then
            self:SetWndEasyImage(v, iconStr, nil, true)
        end
    end
    local tagColour = roleRef.tagColour
    if string.isempty(tagColour) then
        return
    end
    local color = LUtil.ColorByHex(tagColour .. "FF")
    local xuitxt = self:FindWndText(uiText)
    --self:SetXUITextColor(xuitxt, color)
    arrows.anchoredPosition = Vector2.New(arrows.anchoredPosition.x, roleRef.arrowPointY)
end
function UISayPop:InitMessage()
    self:WndNetMsgRecv(LProtoIds.ChatMsgPushResp, function(pb)
        self:OnChatMsgPushResp(pb)
    end)
    self:WndEventRecv(EventNames.ON_CHAT_TA_CALL, function(...)
        self:OnCallTaOpenInfoPop(...)
    end)
    self:WndEventRecv(EventNames.ON_CHAT_FRIND_NEW, function(table)
        --收到私聊
        --self._privatePlayerInfo = table["playerInfo"]
        --local playerId = self._privatePlayerInfo.playerId
        --self:RefreshChannelTab(playerId)
    end)
    self:WndEventRecv(EventNames.ON_CHAT_SKIP_PRIVATE, function(table)
        self._privatePlayerInfo = table["playerInfo"]
        local playerId = self._privatePlayerInfo.playerId
        self:RefreshChannelTab(playerId)
    end)
    self:WndEventRecv(EventNames.CHAT_AT_OTHER, function(...)
        self:OnLongClickHead(...)
    end)
    self:WndEventRecv(EventNames.ON_CHAT_TRANSLATE_CALL, function(code, index)
        self:RefreshMsg()
    end)
    --激活聊天框不选中所有内容
    self.mInputChat.onFocusSelectAll = false
    self:WndNetMsgRecv(LProtoIds.PersonaliseInfoResp, function(...)
        self:RefreshBubble()
    end)
    self:WndEventRecv(EventNames.ON_CHAT_SET_CHANGE, function()
        self:RefreshChannelTab()
    end)
    self:WndEventRecv(EventNames.ON_CHAT_SET_CHANGE_GRADE, function()
        self:RefreshMsg()
    end)
    self:WndNetMsgRecv(LProtoIds.PlayerOnlineResp, function(...)
        self:PlayerOnlineResp(...)
    end)

    self:WndEventRecv(EventNames.ON_CHAT_CHANGE_VIEW_SET, function()
        self:SetMsgContentType()
        self:RefreshMsg()
    end)
end
function UISayPop:OnClickTab(type, itemdata, itempos)
    self._isReachBottom = true
    if type == 1 then
        CS.ShowObject(self.mBtnDown, false)
        self:OnClickChannel(itemdata, itempos)
    elseif type == 2 then
        GF.OpenWnd("UISayAddPY")
    elseif type == 3 then
        CS.ShowObject(self.mBtnDown, false)
        CS.ShowObject(self.mChannelTips, false)
        self._tabIndex = itempos
        self._currChannel = ModelChat.CHANNEL_PRIVATE
        self:SetWndText(self.mChannelNameText, itemdata.playerInfo.name)
        self._currPritavePlayer = itemdata.playerInfo
        gModelChat:SetPrivateCurPlayerInfo({playerInfo = itemdata,type = type,itempos = itempos})
        CS.ShowObject(self.mBottomMar, true)
        gModelChat:DelPrivateRed(itemdata.playerInfo.playerId)
        self:RefreshChannelTabSel(itempos)
        self:RefreshMsg()
        self:RefreshAddBtnStatus()
    end
end

function UISayPop:RefreshAddBtnStatus()
    local btnList = gModelChat:GetChatBtnRefListByChannle(self._currChannel)
    local showAddBtn = btnList and #btnList > 0
    CS.ShowObject(self.mBtnAdd,showAddBtn)
end
function UISayPop:SetGradeIcon(gradeIcon, itemdata, isme)
    if not gradeIcon then
        return
    end
    local gradeName = self:FindWndTrans(gradeIcon, "GradeName")

    local grade = itemdata.grade or 0
    if tonumber(grade) <= 0 then
        CS.ShowObject(gradeIcon, false)
        return
    end
    local channelRef = gModelChat:GetChatChannelRefByChannelId(self._currChannel)
    if not channelRef or channelRef.gradeLvShow ~= 1 then
        CS.ShowObject(gradeIcon, false)
        return
    end
    local showGrade = gModelChat:GetIsShowGrade(isme)
    if not showGrade then
        CS.ShowObject(gradeIcon, false)
        return
    end
    local lvRef = gModelGrade:GetGradeLvRefByRefId(grade)
    CS.ShowObject(gradeIcon, true)
    --self:SetWndEasyImage(gradeIcon,lvRef.iconSmall)

    if gradeName then
        self:SetWndText(gradeName, ccLngText(lvRef.name))
    end
end
function UISayPop:RefreshCombatType()
    CS.ShowObject(self.mCombatSuper, true)
    CS.ShowObject(self.mTypeBg, false)
    CS.ShowObject(self.mTypeScroll, false)

    local dataList = gModelFormation:GetCombatTypeList()
    local combatList = {}
    for i, v in ipairs(dataList) do
        local power = gModelPower:GetFormationPower(v.refId)
        if power > 0 then
            table.insert(combatList, v)
        end
    end

    local _uiCombatList = self._uiCombatList
    if (_uiCombatList) then
        _uiCombatList:RefreshList(combatList)
        _uiCombatList:DrawAllItems()
    else
        _uiCombatList = self:GetUIScroll("mCombatSuper")
        _uiCombatList:Create(self.mCombatSuper, combatList, function(...)
            self:CombatListItem(...)
        end, UIItemList.SUPER_GRID)
        self._uiCombatList = _uiCombatList
        _uiCombatList:EnableScroll(true, false)
    end
end
function UISayPop:RefreshAddFunTypeItem(btnList, type)
    --去掉2 的显示
    local typeIndex = type ~= ModelChat.EXTENDFUN_TYPE_4 and 1 or 1

    local _addFuncType = typeIndex == 1 and self._addFuncType1 or self._addFuncType2

    CS.ShowObject(self.mAddFuncType, typeIndex == 1)
    CS.ShowObject(self.mAddFuncType2, typeIndex == 2)

    if _addFuncType then
        _addFuncType:RefreshList(btnList)
        --local uiList = _addFuncType:GetList()
        --uiList:SetContentPosition(1,1)
    else
        _addFuncType = self:GetUIScroll("mAddFuncType" .. typeIndex)
        local mAddFuncType = typeIndex == 1 and self.mAddFuncType or self.mAddFuncType2
        _addFuncType:Create(mAddFuncType, btnList, function(...)
            self:AddFunListItem(...)
        end)
        self._addFuncType = _addFuncType
        _addFuncType:EnableScroll(true, true)
        if typeIndex == 1 then
            self._addFuncType1 = _addFuncType
        else
            self._addFuncType2 = _addFuncType
        end
    end
end
--点击分享
function UISayPop:OnClickShare(itemdata)
    local atPlayerId
    local _currChannel = self._currChannel
    if (_currChannel == ModelChat.CHANNEL_PRIVATE) then
        atPlayerId = self._currPritavePlayer.playerId
    end
    if (itemdata.itemType == 1) then
        gModelGeneral:OpenItemInfoTip(itemdata.itemId, nil, nil, nil, nil, true, function()
            local shareMsg = string.format("%s=%s=%s", itemdata.itemType, itemdata.itemId, itemdata.itemNum)
            gModelChat:OnChatShareReq(_currChannel, ModelChat.CHATSHARE_ITEM, shareMsg, atPlayerId)
        end)
    elseif (itemdata.itemType == 3) then
        gModelGeneral:OpenEquipInfoTip(itemdata.itemId, nil, nil, nil, nil, function()
            local shareMsg = string.format("%s=%s=%s", itemdata.itemType, itemdata.itemId, itemdata.itemNum)
            gModelChat:OnChatShareReq(_currChannel, ModelChat.CHATSHARE_ITEM, shareMsg, atPlayerId)
        end)
    elseif (itemdata.itemType == 2) then
        gModelHero:ReqShowHeroTip("", itemdata, true, function()
            gModelChat:OnChatShareReq(_currChannel, ModelChat.CHATSHARE_HERO, itemdata.id, atPlayerId)
        end)
    elseif (itemdata.itemType == 4) then
        local data = {
            runeData = itemdata,
            runeId = itemdata.id,
            share = true,
            shareFunc = function()
                gModelChat:OnChatShareReq(_currChannel, ModelChat.CHATSHARE_RUNE, itemdata.id, atPlayerId)
            end
        }
        gModelGeneral:OpenRuneInfoTip(data)
    elseif itemdata.itemType == LItemTypeConst.TYPE_OUTFIT then
        local wearHeroId = itemdata.heroId
        local heroData = gModelHero:GetHeroServerDataById(wearHeroId)
        -- 自己背包的装备
        local data = {
            curSerData = itemdata,
            heroData = heroData,
            outfitType = 7
        }
        gModelGeneral:OpenOutfitInfoTip(data, true)
        -- 【C宠物系统】删掉宠物系统相关
        -- elseif itemdata.itype == LItemTypeConst.TYPE_PET then
        -- 	GF.OpenWnd("WndPetSharePop",{id = itemdata.id,refId = itemdata.refId,shareData = itemdata,isChatWnd = true,shareFunc =function()
        -- 		gModelChat:OnChatShareReq(_currChannel,ModelChat.CHAT_SHARE_39,itemdata.id,atPlayerId)
        -- 	end})
    end
    self:OnClickCloseAdd()
end

function UISayPop:OnTimer(key)
    if self._pointerUpKey == key then
        self._isLongClickFace = false
    elseif self._playerOnlineKey == key then
        self:OnReqPlayerOnline()
    end

end
function UISayPop:HeadListItem(item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local headIcon = self:FindWndTrans(root, "HeadIcon/HeadIcon")
    local nameText = self:FindWndTrans(root, "HeadIcon/NameText")
    local eff = self:FindWndTrans(root, "HeadIcon/Eff")
    local btnDel = self:FindWndTrans(root, "HeadIcon/NameText/BtnDel")
    local redEff = self:FindWndTrans(root, "HeadIcon/RedEff")

    local InstanceID = item:GetInstanceID()
    local _tabType = self._tabType
    local tabIndex = self._tabIndex or 0
    local playerInfo = itemdata.playerInfo
    local _playerOnlineIds = self._playerOnlineIds or {}
    local playerId = playerInfo.playerId
    local redNum = gModelChat:GetPrivateChannelRed(playerId)

    local isShowRed = redNum > 0
    isShowRed = isShowRed and gModelChat:GetIsShowRedPrivate()
    CS.ShowObject(redEff, isShowRed)
    if redNum > 0 then
        self:CreateWndEffect(redEff, "fx_redPoint_01", InstanceID .. "HeadRed" .. _tabType, 140, false, false, 10)
    end
    local effName = _playerOnlineIds[playerId] and "fx_liaotian_zaixianlvdian" or "fx_liaotian_lixianhuidian"
    local onlieKey = InstanceID .. "Online" .. _tabType
    self:DestroyWndEffectByKey(onlieKey)
    self:CreateWndEffect(eff, effName, onlieKey, 80, false, false, 10)
    self:SetWndText(nameText, playerInfo.name)
    self:SetHeadIcon(headIcon, {
        head = playerInfo.icon,
        headFrame = playerInfo.headFrame,
        bDefaultSortNum = 10,
    }, InstanceID)
    self:SetWndClick(headIcon, function()
        self:OnClickTab(3, itemdata, itempos)
    end)
    self:SetWndClick(btnDel, function()
        self:OnClickDelFrind(playerInfo)
    end)
end
function UISayPop:OnClickBubbleType(type)
    local _type = self._bubbleType
    local _typeList = self._bubbleTypeList
    if _type then
        self:SetWndTabStatus(_typeList[_type], 1)
    end
    self._bubbleType = type
    self:SetWndTabStatus(_typeList[type], 0)
    self:RefreshBubble()
end
function UISayPop:BubbleTypeListItem(list, item, itemdata, itempos)
    local BtnTab1 = CS.FindTrans(item, "BtnTab7")

    self._bubbleTypeList[itemdata.type] = BtnTab1

    self:SetWndTabText(BtnTab1, ccLngText(itemdata.name), -4, self._isForeignFr and 40 or nil)
    self:SetWndTabStatus(BtnTab1, 1)
    self:SetWndClick(item, function()
        self:OnClickBubbleType(itemdata.type)
    end)
end
function UISayPop:OnClickDelFrind(playerInfo)
    gModelGeneral:OpenUIOrdinTips({ refId = 50006, para = { playerInfo.name }, func = function()
        gModelChat:DeletePrivateChat(playerInfo)
        self._currPritavePlayer = nil
        gModelChat:SetPrivateCurPlayerInfo()
        self._privatePlayerInfo = nil
        self:RefreshChannelTab(-1)
    end })
end
function UISayPop:OnClickBubbleItem(refId, itempos)
    self._curSelBubble = refId
    local uiList = self._bubbleSuper
    local oldSelIndex = self._oldSelIndex
    if oldSelIndex then
        uiList:DrawItemByIndex(oldSelIndex)
    end
    self._oldSelIndex = itempos
    uiList:DrawItemByIndex(itempos)
    self:RefreshBubbleInfo()
end

---刷新信息列表
function UISayPop:RefreshMsg()
    local _currChannel = self._currChannel
    local _popType = self._popType
    local infoList = gModelChat:GetTypeInfo(_currChannel, self._currPritavePlayer)

    local channelRef = gModelChat:GetChatChannelRefByChannelId(self._currChannel)
    if _currChannel == 6 then
        local s = ccLngText(channelRef.channelTitle)
        self:SetWndText(self.mChannelText, string.replace(s, self._currPritavePlayer.name))
    else
        self:SetWndText(self.mChannelText, ccLngText(channelRef.channelTitle))
    end

    CS.ShowObject(self.mCloseFriend, _currChannel == 6)

    CS.ShowObject(self.mCrossBtn, false)
    if _currChannel == 2 then
        local serverList, groupId = gModelChat:GetServers()
        if #serverList > 0 then
            CS.ShowObject(self.mCrossBtn, true)
        end
    end

    --缩略按钮
    local img = _popType == UISayPop.PopType_1 and "chat_icon_11" or "chat_icon_11_1"
    self:SetWndEasyImage(self.mBtnScale, img, nil, true)
    --插入时间
    local msgList = gModelChat:InsertionSendTimeToChatInfo(_currChannel, infoList)
    local msgLen = #msgList

    local listPara = self:GetListRootPara()

    local isempty = msgLen <= 0
    CS.ShowObject(self.mNoRecord, isempty)
    CS.ShowObject(listPara.root, not isempty)
    if isempty then
        self:CreateEmptyShow(5401)
        return
    end
    local uiList = self:FindUIScroll(listPara.key)

    if uiList then
        --uiList:RefreshList(msgList)
        uiList:RefreshList(msgList)
        uiList:DrawAllItems(true)
    else
        uiList = self:GetUIScroll(listPara.key)
        uiList:Create(listPara.root, msgList, function(...)
            self:ListItem(...)
        end, UIItemList.SUPER)
        uiList:EnableScroll(true, false)

    end

    local _uiList = uiList:GetList()
    _uiList:SetFuncOnItemReachTail(function(value)
        self._isReachBottom = value

        if value then
            self:OnClickDelDown()
        end
    end)

    if not self._oneToBottom then
        self._oneToBottom = true
        _uiList:MoveToBottom()
        return
    end
    if self._isReachBottom then
        self:OnClickDelDown()
        _uiList:MoveToBottom()
    else
        local channelList = gModelChat:GetChannelRed()
        local num = channelList[_currChannel] or 0

        CS.ShowObject(self.mBtnDown, num > 0)
        if num > 0 then
            self:SetWndText(self.mDownText, num .. ccClientText(11107))
            --uiList:DrawAllItems()
            self:SetWndClick(self.mBtnDown, function()
                _uiList:MoveToBottom()
                self:OnClickDelDown()
            end)
        else
            --GF.ShowMessage("------不在底部----")
            --_uiList:MoveToBottom()
        end
    end
end
function UISayPop:RefreshItemList(list)
    local _uiItemList = self._uiItemList
    if _uiItemList then
        _uiItemList:RefreshList(list)
    else
        _uiItemList = self:GetUIScroll("CommScroll")
        _uiItemList:Create(self.mCommScroll, list, function(...)
            self:ItemListItem(...)
        end, UIItemList.WRAP)
        self._uiItemList = _uiItemList
        _uiItemList:EnableScroll(true, false)
    end
end
function UISayPop:RefreshBubbleInfo()
    local useId = gModelPlayer:GetBubble()
    local _curSelBubble = self._curSelBubble or useId
    local activateLis = gModelPlayer:GetPersonaliseInfo(ModelPlayerSpace.BUBBLE) or {}
    local curInfo = activateLis[_curSelBubble]
    local isActivate = curInfo and curInfo.state == 0

    local saveStr = isActivate and ccClientText(21113) or ccClientText(21116)
    self:SetWndButtonText(self.mBtnSave, saveStr)
    --CS.ShowObject(self.mBtnSave,_curSelBubble ~= useId)
    --CS.ShowObject(self.mBtnCloseBubble,_curSelBubble == useId)

    local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(_curSelBubble)
    local headIcon = self:FindWndTrans(self.mBubbleMarTop, "Image/HeadIcon")
    self:SetHeadIcon(headIcon, {
        head = gModelPlayer:GetPlayerHead(),
        headFrame = gModelPlayer:GetPlayerHeadFrame()
    }, "mBubbleMarTop")
    local chatBg = self:FindWndTrans(self.mBubbleMarTop, "Image/ChatBg")
    self:SetBubbleImg(chatBg, ref)
    local infoModel = self:FindWndTrans(self.mBubbleMarTop, "Image/InfoModel")
    local nameText = self:FindWndTrans(infoModel, "NameText")
    local timeText = self:FindWndTrans(infoModel, "TimeText")
    local arrtText = self:FindWndTrans(infoModel, "ArrtText")
    self:SetWndText(nameText, ccLngText(ref.name))
    local timeStr = ""
    local expireTime = curInfo and tonumber(curInfo.expireTime) or 0
    if not isActivate then
        timeStr = ccClientText(21156)
    elseif expireTime <= 0 then
        timeStr = ccClientText(21123)
    else
        local time = GetTimestamp()
        local timespan = tonumber(curInfo.createTime + curInfo.expireTime) / 1000 - time
        timeStr = LUtil.FormatTimespanCn(timespan)
    end
    self:SetWndText(timeText, timeStr)
    local arrtStr = ""
    local arrtlist = LUtil.GetRefAttrData(ref.attributes)
    for i, v in ipairs(arrtlist) do
        local name = gModelHero:GetAttributeNameById(v.refId)
        local value = gModelHero:GetAttributeValueNoNameByIdAndVal(v.refId, v.numType, v.value)
        arrtStr = arrtStr .. name .. LUtil.FormatColorStr("+" .. value, "lightGreen") .. "  "
    end
    if arrtStr == "" then
        arrtStr = ccLngText(ref.description)
    else
        arrtStr = arrtStr .. "\n" .. ccLngText(ref.description)
    end
    self:SetWndText(arrtText, arrtStr)
end
function UISayPop:SetVipTip(item, itemdata)
    local vip = itemdata.vip
    local vipLvRef = gModelVip:GetRefByVipLv(vip)
    local isShowVipTitle = false
    if vipLvRef then
        --local chatTitle = vipLvRef.chat
        --local shieldInfo = string.split(itemdata.shieldInfo,"|")
        --if LxUiHelper.IsImgPathValid(chatTitle) and shieldInfo[2] and shieldInfo[2] == "0" then
        --	self:SetWndEasyImage(item,chatTitle)
        --	isShowVipTitle = true
        --end
    end
    return isShowVipTitle
end
--选择表情
function UISayPop:OnClickType1Emoji(faceinstead)
    self:SetWndTextInput(self.mInputChat, self.mInputChat.text .. faceinstead)
end
function UISayPop:OnClickScale(bool)
    local _popType = self._popType
    _popType = _popType == UISayPop.PopType_1 and UISayPop.PopType_2 or UISayPop.PopType_1
    self._popType = _popType

    LPlayerPrefs.SetChatPopState(_popType)

    self:SetMsgContentType()

    if bool then
        return
    end
    self:RefreshMsg()
end
function UISayPop:AddFunListItem(list, item, itemdata, itempos)
    self._funBtnList[itemdata.type] = item
    local name = ccLngText(itemdata.name)
    local addFontSize = -4
    if gLGameLanguage:IsKoreaVersion() then
        addFontSize = -6
    end
    self:SetWndTabText(item, name, addFontSize)
    self:SetWndClick(item, function(...)
        self:OnClickAddFunTypeBtn(itemdata.type)
    end)
end

function UISayPop:InitFullViewPara()
    local para = gModelChat:GetChatConfigRefByKey("chatListMax")
    self.mMsgSuperFull.sizeDelta = Vector2.New(538, para - 130)
end
function UISayPop:GetSysInfoWidth(msg, chatBg, item)
    self:SetWndText(self.mTestText3, msg)
    local height = self.mTestText3_1.preferredHeight
    height = 20 + height

    LxUiHelper.SetSizeWithCurAnchor(chatBg, 1, height)
    LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
end

function UISayPop:SetHeadIcon(item, itemdata, InstanceID)
    local playerInfo = {
        trans = item,
        icon = itemdata.head,
        headFrame = itemdata.headFrame,
        playerId = itemdata.playerId,
        level = itemdata.level,
        noLv = itemdata.level == 0,
        bDefaultSortNum = itemdata.bDefaultSortNum,
    }
    local uiheadlist = self._uiHeadList
    local baseClass = uiheadlist[InstanceID]
    if not baseClass then
        baseClass = HeadIcon:New(self)
        uiheadlist[InstanceID] = baseClass
    end
    baseClass:SetHeadData(playerInfo)
    baseClass:RefreshUI()
end

---刷新频道列表
function UISayPop:RefreshChannelTab(newPlayerId)
    local _tabType = self._tabType
    local _currChannel = self._currChannel
    local tabIndex = self._tabIndex
    local list = gModelChat:GetChannelListRef()

    local showProvince = gModelChat:GetChatSetValue(1)
    --local chatSetServerList = LPlayerPrefs.chatSetServerList or ""
    --local arr = string.split(chatSetServerList,"|")
    --for i, v in ipairs(arr) do
    --	local as = string.split(v,"=")
    --	if as[1] == "1" and as[2] == "1" then
    --		showProvince = true
    --	end
    --end
    local btnDataList = {}
    for k, v in ipairs(list) do
        if v.channelId ~= ModelChat.CHANNEL_PRIVATE and (showProvince or v.channelId ~= ModelChat.CHANNEL_PROVINCE) then
            local tabBtn = string.split(v.tabBtn, ",")
            local data = {
                type = 1,
                channelId = v.channelId,
                btnName = ccLngText(v.channel),
                titleName = ccLngText(v.channelTitle),
                btnOn = tabBtn[1],
                btnOff = tabBtn[2],
                btnGray = tabBtn[3],
            }
            table.insert(btnDataList, data)
        end
    end
    local _privatePlayerInfo = self._privatePlayerInfo
    local chatFriendLsit = gModelChat:AddPrivateChat(_privatePlayerInfo, false)
    local playerIdList = {}
    for i, v in ipairs(chatFriendLsit) do
        if v.type == 1 then
            local data = {
                type = 3,
                playerInfo = v.playerInfo,
            }
            table.insert(btnDataList, data)
            table.insert(playerIdList, v.playerInfo.playerId)
        end
    end

    table.insert(btnDataList, { type = 2, btnName = ccClientText(11159) })
    if not tabIndex then
        local curIndex = 1
        for i, v in ipairs(btnDataList) do
            if v.type == 1 and v.channelId == _currChannel then
                curIndex = i
            end
        end
        self._tabIndex = curIndex
        self._oldTabIndex = curIndex
        local curBtnInfo = btnDataList[curIndex]
        local channelNameTextStr = ""
        if curBtnInfo.type == 1 then
            channelNameTextStr = curBtnInfo.titleName
        elseif curBtnInfo.type == 3 then
            channelNameTextStr = curBtnInfo.playerInfo.name
        end
        self:SetWndText(self.mChannelNameText, channelNameTextStr)
    end
    self._btnDataList = btnDataList
    --右侧缩略部分 屏蔽
    CS.ShowObject(self.mBtnSpread, false)
    CS.ShowObject(self.mBtnLessen, false)
    local uiList = _tabType == UISayPop.TabType_1 and self._uiTabSuperMin or self._uiTabSuperMax
    local uiSuper = _tabType == UISayPop.TabType_1 and self.mChannelSuperMin or self.mChannelSuperMax

    CS.ShowObject(self.mSetNameText, _tabType == UISayPop.TabType_2)
    CS.ShowObject(self.mBubbleNameText, _tabType == UISayPop.TabType_2)
    CS.ShowObject(self.mBtnClickSet, _tabType == UISayPop.TabType_2)
    CS.ShowObject(self.mBtnClickBubble, _tabType == UISayPop.TabType_2)
    CS.ShowObject(uiSuper, true)
    if uiList then
        uiList:RefreshList(btnDataList)
        uiList:DrawAllItems()
    else
        uiList = self:GetUIScroll("mChannelSuper" .. _tabType)
        uiList:Create(uiSuper, btnDataList, function(...)
            self:TabListItem(...)
        end, UIItemList.SUPER)
        uiList:EnableScroll(true, false)
        if _tabType == UISayPop.PopType_1 then
            self._uiTabSuperMin = uiList
        else
            self._uiTabSuperMax = uiList
        end
    end
    if newPlayerId then
        for i, v in ipairs(btnDataList) do
            if v.playerInfo and (v.playerInfo.playerId == newPlayerId or newPlayerId == -1) then
                self:OnClickTab(3, v, i)
                return
            end
        end
        for i, v in ipairs(btnDataList) do
            if v.channelId == ModelChat.CHANNEL_WORLD then
                self:OnClickTab(1, v, i)
                return
            end
        end
    end
    local _playerOnlineKey = self._playerOnlineKey
    if #playerIdList <= 0 then
        self:TimerStop(_playerOnlineKey)
        return
    end
    if not self:IsTimerExist(_playerOnlineKey) then
        self:TimerStart(_playerOnlineKey, 60, false, -1)
    end
    self._playerIdList = playerIdList
    gModelChat:PlayerOnlineReq(playerIdList, "1")
end
function UISayPop:MeListItem(item, itemdata, itempos)
    local me = self:FindWndTrans(item, "Me")
    local meMar = self:FindWndTrans(me, "MeMar")
    local headIcon = self:FindWndTrans(me, "HeadRoot/HeadIcon")
    local chatBg = self:FindWndTrans(me, "ChatBg")
    local vipTitle = self:FindWndTrans(me, "VipTitle")
    local emojiImage = self:FindWndTrans(me, "EmojiImage")
    local emojiSpine = self:FindWndTrans(me, "EmojiSpine")
    local tagItemRoot = self:FindWndTrans(me, "TagItemRoot")
    local gradeIcon = self:FindWndTrans(meMar, "GradeIcon")

    local InstanceID = item:GetInstanceID()
    local msg = itemdata:GetMsg()
    local faceId = LUtil.ChatInfoGetDaFace(msg)

    self:SetChatPlayer(meMar, itemdata)
    self:SetHeadIcon(headIcon, itemdata, InstanceID)
    local isShowVipTip = self:SetVipTip(vipTitle, itemdata)
    CS.ShowObject(vipTitle, isShowVipTip)
    local isShowTag = self:SetTabItemRoot(tagItemRoot, itemdata)
    CS.ShowObject(tagItemRoot, isShowTag)
    CS.ShowObject(chatBg, faceId <= 0)
    if faceId > 0 then
        self:SetBigFace(item, me, faceId, InstanceID, isShowTag)
    else
        CS.ShowObject(emojiImage, false)
        CS.ShowObject(emojiSpine, false)
        self:SetChatBubble(chatBg, itemdata.bubble, true)
        self:SetMsgShow(item, me, itemdata, msg, isShowTag, isShowVipTip, InstanceID)
    end
    self:SetGradeIcon(gradeIcon, itemdata, true)

    self:SetWndClick(headIcon, function()
        GF.OpenWnd("UIChaePop", { startType = ModelPlayerSpace.ROLE_HEAD })
    end)
end

function UISayPop:OnClickSend()
    local cmd = self.mInputChat.text
    local type = ModelChat.MSGTYPE_NORMAL
    self:SendChatMsg(cmd, type)
    --发送后默认在最后
    --self._isReachBottom= true
end
function UISayPop:ListItem(list, item, itemdata, itempos)
    local me = self:FindWndTrans(item, "Me")
    local other = self:FindWndTrans(item, "Other")
    local system = self:FindWndTrans(item, "System")
    local timeTrans = self:FindWndTrans(item, "Time")

    self._currMsgIndex = itempos
    local channel = itemdata.channel
    local isMe = itemdata.isMe
    local isTime = itemdata.isTime
    local isOther = not (isMe or isTime)

    CS.ShowObject(me, isMe and channel ~= ModelChat.CHANNEL_SYSTEM)
    CS.ShowObject(other, isOther and channel ~= ModelChat.CHANNEL_SYSTEM)
    CS.ShowObject(system, channel == ModelChat.CHANNEL_SYSTEM)
    CS.ShowObject(timeTrans, isTime)
    if isTime then
        self:TimeListItem(item, itemdata, itempos)
    elseif isMe and channel ~= ModelChat.CHANNEL_SYSTEM then
        self:MeListItem(item, itemdata, itempos)
    elseif not isMe and channel ~= ModelChat.CHANNEL_SYSTEM then
        self:OtherListItem(item, itemdata, itempos)
    elseif channel == ModelChat.CHANNEL_SYSTEM then
        self:SystemListItem(item, itemdata, itempos)
    end


end
function UISayPop:OnClickAdd()
    local _isOpentAdd = not self._isOpentAdd
    if _isOpentAdd then
        CS.ShowObject(self.mAddFun, true)
        CS.ShowObject(self.mAddFunMask, true)
        self:SetWndEasyImage(self.mBtnAdd, "chat_btn_jian")
        self:RefreshAddFun()
        self._isOpentAdd = true
    else
        self:OnClickCloseAdd()
    end
end
--长按头像
function UISayPop:OnLongClickHead(itemdata)
    if itemdata.playerId == "-1" or itemdata.playerId == gModelPlayer:GetPlayerId() then
        return
    end
    self._isLongClisk = true
    self:SetWndTextInput(self.mInputChat, "@" .. itemdata.playerName .. "  ")
    self._targetInfo = itemdata
end
function UISayPop:TabListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local channelIcon = self:FindWndTrans(root, "ChannelIcon")
    local privateIcon = self:FindWndTrans(root, "PrivateIcon")
    local headIcon = self:FindWndTrans(root, "HeadIcon")
    local eff = self:FindWndTrans(headIcon, "Eff")
    local selImg = self:FindWndTrans(root, "Sel")

    local type = itemdata.type
    local tabIndex = self._tabIndex or 0
    local isSel = tabIndex == itempos

    CS.ShowObject(channelIcon, type == 1)
    CS.ShowObject(privateIcon, type == 2)
    CS.ShowObject(headIcon, type == 3)
    CS.ShowObject(selImg, isSel and type == 3)
    CS.ShowObject(eff, type == 3)

    if type == 1 then
        self:ChannelListItem(item, itemdata, itempos)
        local nameText = self:FindWndTrans(channelIcon, "channelName")
        local colorStr = tabIndex == itempos and "<color=#1a3365>#a1#</color>" or "<color=#ffffff>#a1#</color>"
        colorStr = string.replace(colorStr, itemdata.btnName)
        self:SetWndText(nameText, colorStr)

    elseif type == 2 then
        local nameText = self:FindWndTrans(privateIcon, "NameText")
        --local color = isSel and "white" or "lightGrey"
        --local str = LUtil.FormatColorStr(itemdata.btnName,color)
        local str = itemdata.btnName
        self:SetWndText(nameText, str)
    elseif type == 3 then
        self:HeadListItem(item, itemdata, itempos)
    end
    self:SetWndClick(root, function()
        self:OnClickTab(type, itemdata, itempos)
    end)

    self:SetWndClick(headIcon, function()
        gModelChat:DeletePrivateChat(itemdata.playerInfo)
    end)
end
function UISayPop:OnClickSet()
    --self:OnClickCloseBubble()
    GF.OpenWnd("UISaySetPop")
end
function UISayPop:OnClickAddItemType(itemdata)
    if itemdata.type == ModelChat.EXTENDFUN_TYPE_1 then
        local bool = gModelChat:GetEmojiTypeIsOpent(itemdata.refId)
        if not bool then
            return
        end
    end
    local _addTypeList = self._addTypeList or {}
    local type = self._addType
    if type then
        CS.ShowObject(_addTypeList[type], false)
    end
    CS.ShowObject(_addTypeList[itemdata.refId], true)
    self._addType = itemdata.refId

    if itemdata.type == ModelChat.EXTENDFUN_TYPE_1 then
        gModelChat:GetEmojiTypeIsOpent(itemdata.refId)
        self:RefreshFaceList(itemdata)
    elseif itemdata.type == ModelChat.EXTENDFUN_TYPE_2 then
        self:RefreshHeroList(itemdata)
    elseif itemdata.type == ModelChat.EXTENDFUN_TYPE_3 then
        self:RefreshBagList(itemdata)
        -- 【C宠物系统】删掉宠物系统相关
        -- elseif itemdata.type == ModelChat.EXTENDFUN_TYPE_5 then
        -- 	self:RefreshPetList(itemdata)
    end
end
function UISayPop:ChannelListItem(item, itemdata, itempos)
    local channelIcon = self:FindWndTrans(item, "Root/ChannelIcon")
    local icon1 = self:FindWndTrans(channelIcon, "Icon1")
    local icon2 = self:FindWndTrans(channelIcon, "Icon2")
    local icon3 = self:FindWndTrans(channelIcon, "Icon3")
    local nameText = self:FindWndTrans(channelIcon, "NameText")
    local redEff = self:FindWndTrans(channelIcon, "RedEff")

    local _tabType = self._tabType
    local InstanceID = item:GetInstanceID()
    local channelId = itemdata.channelId
    local channelRedList = gModelChat:GetChannelRed()
    local redNum = channelRedList[channelId] or 0
    local tabIndex = self._tabIndex or 0
    local bool = gModelChat:GetChatChannelIsOpent(channelId, 3, false)
    local isShowRed = bool and redNum > 0 and channelId ~= self._currChannel

    self:SetWndEasyImage(icon1, "chat_channel_btn_off")
    self:SetWndEasyImage(icon2, "chat_channel_btn_on")
    self:SetWndEasyImage(icon3, "chat_channel_btn_on")

    CS.ShowObject(redEff, isShowRed)
    --if isShowRed then
    --    --self:CreateWndEffect(redEff, "fx_redPoint_01", InstanceID .. "ChannelRed" .. _tabType, 70, false, false, 10)
    --end
    CS.ShowObject(icon3, not bool)
    CS.ShowObject(icon1, bool and tabIndex == itempos)
    CS.ShowObject(icon2, bool and tabIndex ~= itempos)

    local colorStr = tabIndex == itempos and "<color=#1a3365>#a1#</color>" or "<color=#ffffff>#a1#</color>"
    colorStr = string.replace(colorStr, itemdata.btnName)
    self:SetWndText(nameText, colorStr)
    --if bool and tabIndex == itempos then
    --	gModelChat:DelChannelRed(channelId)
    --end
end
function UISayPop:SetBubbleImg(chatBg, itemdata)
    local arrows = self:FindWndTrans(chatBg, "Arrows")
    local chatText = self:FindWndTrans(chatBg, "ChatText")
    local pendantList = {}
    for i = 1, 4 do
        local pendant = self:FindWndTrans(chatBg, "Pendant" .. i)
        pendantList[i] = pendant
    end

    local iconArr = string.split(itemdata.icon, "|")
    self:SetWndEasyImage(chatBg, iconArr[1])
    self:SetWndEasyImage(arrows, iconArr[2])
    for i, v in ipairs(pendantList) do
        local iconStr = iconArr[i + 2] or "0"
        CS.ShowObject(v, iconStr ~= "0")
        if iconStr ~= "0" then
            self:SetWndEasyImage(v, iconStr, nil, true)
        end
    end
    local name = ccLngText(itemdata.name)
    local tagColour = itemdata.tagColour or "734f22"
    if string.isempty(tagColour) then
        return
    end
    self:SetWndText(chatText, LUtil.FormatColorStr(name, "#" .. tagColour))
    self:InitTextSizeWithLanguage(chatText, -2)
    arrows.anchoredPosition = Vector2.New(arrows.anchoredPosition.x, itemdata.arrowPointY)
end

function UISayPop:GetListRootPara()
    local isFull = gModelChat:GetChatSetValue(17)
    if isFull then
        return { key = "msgListFull", root = self.mMsgSuperFull }
    else
        if self._popType == UISayPop.PopType_1 then
            return { key = "msgListMax", root = self.mMsgSuperMax }
        else
            return { key = "msgListMin", root = self.mMsgSuperMin }
        end
    end
end
function UISayPop:SendChatMsg(cmd, type, isNoRestrictLv)
    local mInputArea = self.mInputArea
    local _currChannel = self._currChannel
    if not type then
        type = ModelChat.MSGTYPE_NORMAL
    end
    if not isNoRestrictLv then
        local bool = gModelChat:GetIfSend(_currChannel, cmd)
        if not bool then
            return
        else
            local info = gModelChat:GetChatRestrict(cmd)
            if info.bool then
                self:SetWndTextInput(self.mInputChat, info.str)
                CS.ShowObject(mInputArea, false)
                CS.ShowObject(mInputArea, true)
                return
            end
        end
    end

    local playerId, playerName, extraMsg, serverId
    local _currPritavePlayer = self._currPritavePlayer
    local _targetInfo = self._targetInfo
    if _currPritavePlayer and _currChannel == ModelChat.CHANNEL_PRIVATE then
        _targetInfo = {
            playerId = _currPritavePlayer.playerId,
            playerName = _currPritavePlayer.name,
            serverId = _currPritavePlayer.serverId,
        }
    end
    if _targetInfo then
        local name = string.match(cmd, _targetInfo.playerName)
        if _currChannel ~= ModelChat.CHANNEL_PRIVATE and name == _targetInfo.playerName then
            type = ModelChat.MSGTYPE_AT
        end
        playerId = _targetInfo.playerId
        playerName = _targetInfo.playerName
        serverId = _targetInfo.serverId
    end
    gModelChat:OnChatMsgReq(_currChannel, type, cmd, playerId, playerName, extraMsg, serverId, isNoRestrictLv)
    self:SetWndTextInput(self.mInputChat, "")
    self._targetInfo = nil
    self:OnClickCloseAdd()
    CS.ShowObject(mInputArea, false)
    CS.ShowObject(mInputArea, true)
    local caret = self:FindWndTrans(mInputArea, "Caret")
    local text = self:FindWndTrans(mInputArea, "Text")
    caret.anchoredPosition = Vector2.New(0, 0)
    text.anchoredPosition = Vector2.New(0, 0)
end
function UISayPop:OnClickLessen()
    self._tabType = UISayPop.TabType_1
    self.mChannelBg.sizeDelta = Vector2.New(61, 0)
    self.mInputChatTr.localPosition = Vector2.New(-65, 41.5)
    self.mInputChatTr.sizeDelta = Vector2.New(322, 52)
    self.mBtnSendMag.localPosition = Vector2.New(161, 44)
    CS.ShowObject(self.mChannelSuperMin, false)
    CS.ShowObject(self.mChannelSuperMax, false)
    self:RefreshChannelTab()
end
function UISayPop:OnClickCloseAdd()
    CS.ShowObject(self.mAddFun, false)
    CS.ShowObject(self.mAddFunMask, false)
    self:SetWndEasyImage(self.mBtnAdd, "chat_btn_jia")
    self._isOpentAdd = false
end
--点击扩展功能类型
function UISayPop:OnClickAddFunTypeBtn(type)
    local _btnType = self._btnType
    local _funBtnList = self._funBtnList
    --if _btnType == type then return end
    if _btnType then
        local oldTrans = _funBtnList[_btnType]
        self:SetWndTabStatus(oldTrans, LWnd.StateOff)
    end
    local trans = _funBtnList[type]
    self:SetWndTabStatus(trans, LWnd.StateOn)
    self._btnType = type

    CS.ShowObject(self.mEmojiList, false)
    CS.ShowObject(self.mCommScroll, false)
    CS.ShowObject(self.mCombatSuper, false)
    CS.ShowObject(self.mTypeBg, true)
    CS.ShowObject(self.mTypeScroll, true)

    --local oldTypeIndex = self._typeIndex
    --local typeIndex = type ~= ModelChat.EXTENDFUN_TYPE_4 and 1 or 2
    --if oldTypeIndex and oldTypeIndex ~= typeIndex then
    --	self:RefreshAddFun()
    --end
    --self._typeIndex = typeIndex

    if type == ModelChat.EXTENDFUN_TYPE_1 then
        --表情
        self:RefreshFaceType()
    elseif type == ModelChat.EXTENDFUN_TYPE_2 then
        self:RefreshHeroType()
    elseif type == ModelChat.EXTENDFUN_TYPE_3 then
        self:RefreshBagType()
    elseif type == ModelChat.EXTENDFUN_TYPE_4 then
        self:RefreshCombatType()
        -- 【C宠物系统】删掉宠物系统相关
        -- elseif type == ModelChat.EXTENDFUN_TYPE_5 then
        -- 	self:RefreshPetType()
    end
end
function UISayPop:InitData()
    local list = gLGameLanguage:GetShowLanguageList()
    self._languageLen = #list
end

function UISayPop:OnClickSpread()
    self._tabType = UISayPop.TabType_2
    self.mChannelBg.sizeDelta = Vector2.New(111, 0)
    self.mInputChatTr.localPosition = Vector2.New(-111, 41.5)
    self.mInputChatTr.sizeDelta = Vector2.New(230, 52)
    self.mBtnSendMag.localPosition = Vector2.New(74, 44)
    CS.ShowObject(self.mChannelSuperMin, false)
    CS.ShowObject(self.mChannelSuperMax, false)
    self:RefreshChannelTab()
end
function UISayPop:OnCallTaOpenInfoPop(table)
    GF.OpenWnd("UIPerInfoPop", {
        playerInfo = table.playerInfo,
        combatHeroData = table.combatHeroData,
        systemType = table.systemType,
        channelId = table.channelId,
        channelIndex = table.channelIndex,
        treasures = table.treasures,
        draconic = table.draconic
        --cellFun=function (...)
        --	self:OnLongClickHead(...)
        --end
    })
end
function UISayPop:RefreshChannelTabByPos(itempos)
    local uiList = self._tabType == UISayPop.TabType_1 and self._uiTabSuperMin or self._uiTabSuperMax
    if uiList:GetList() then
        uiList:DrawItemByIndex(itempos)
    end
end
function UISayPop:RefreshChannelTabSel(itempos)
    local _oldTabIndex = self._oldTabIndex
    if _oldTabIndex then
        self:RefreshChannelTabByPos(_oldTabIndex)
    end
    self:RefreshChannelTabByPos(itempos)
    self._oldTabIndex = itempos

end
function UISayPop:RefreshBagList(itemdata)
    local dataType = itemdata.itemPage
    local list = {}
    if dataType == 203 then
        -- list = gModelOutfit:GetChatList()
    elseif dataType == 206 then
        list = gModelRune:GetNotWearRuneList(false)
    else
        list = gModelItem:GetItemListByType(dataType)
    end
    self:RefreshItemList(list)
end
function UISayPop:CreateEmptyShow(refId)
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
function UISayPop:EmojiListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    --local root = item
    local imageTran = self:FindWndTrans(root, "Image")
    local cfg = itemdata.cfg
    self:SetWndEasyImage(imageTran, cfg.faceIcon)

    --if(itemdata.textType == 1)then
    if (itemdata.textType == 1) then
        self:SetWndClick(root, function(...)
            self:OnClickType1Emoji(cfg.faceinstead)
        end)
        self:SetWndLongClick(root, function()
        end, 0.7, true, LSoundConst.CLICK_BUTTON_COMMON, function()
        end)
    elseif (itemdata.textType == 2) then
        self:SetWndClick(root, function(...)
            self:OnClickType2Emoji(cfg.faceinstead)
        end)
        self:SetWndLongClick(root, function()
            self:OnClickLongType2Emoji(cfg)
        end, 0.7, true, LSoundConst.CLICK_BUTTON_COMMON, function()
            CS.ShowObject(self.mFaceBubble, false)
            self:TimerStop(self._pointerUpKey)
            self:TimerStart(self._pointerUpKey, 0.1, false, 1)
        end)
    end
end
--item调整
function UISayPop:GetChatInfoWidth(msg, chatBg, item, isTag, bubble, isShowVipTitle)
    local initChatBg = gModelPlayer:GetRoleConfigRefByKey("initChatBg")
    local isBubble = not bubble or bubble == 0 or bubble == initChatBg
    local uiText = self:FindWndTrans(chatBg, "XUIText")
    local width = self:GetChatWidth(msg)
    local height = self:GetChatHeight(msg)
    local height2 = height
    local cH = 0                                --高度差
    local itemH = 76                            --item要加的高度
    local chatGH = 45                            --气泡必须的高度	--根据ui
    local chatAH = 18                            --气泡必须加的高度
    uiText.anchoredPosition = Vector2.New(uiText.anchoredPosition.x, -10)
    if isBubble then
        chatGH = chatAH
    end

    local chatAddH = chatGH - (height2 + chatAH)        --气泡附加高度
    if chatAddH < 0 then
        chatAddH = 0
    end
    if not isBubble and chatAddH > 0 then
        uiText.anchoredPosition = Vector2.New(uiText.anchoredPosition.x, -10)
    end

    local chatGW = 61                            --气泡必须的宽度	--根据ui
    local chatAW = 36                            --气泡必须加的宽度
    if isBubble then
        chatGW = chatAW
    end

    local chatAddW = chatGW - (width + chatAW)        --气泡附加宽度
    if chatAddW < 0 then
        chatAddW = 0
    end
    if (height < 30) then
        cH = 15
    end

    height = itemH + height + cH
    local higth = isTag and height + 20 or height
    higth = isShowVipTitle and higth + 20 or higth
    LxUiHelper.SetSizeWithCurAnchor(item, 1, higth)

    local chatBgHeight  = height2 + chatAddH + chatAH
    if height2 >30 then
        chatBgHeight = chatBgHeight - 10
    end
    chatBg.sizeDelta = Vector2.New(width + chatAddW + chatAW, chatBgHeight)


    uiText.sizeDelta = Vector2.New(width, height2)

    if gLGameLanguage:IsJapanRegion() then
        local report = CS.FindTrans(chatBg, "BtnReport")
        if report then
            self:SetAnchorPos(report, Vector2.New(width + 60, 20))
        end
    end
end

function UISayPop:OnClickDelDown()
    CS.ShowObject(self.mBtnDown, false)
    gModelChat:DelChannelRed(self._currChannel)
end
--选择大表情
function UISayPop:OnClickType2Emoji(faceinstead)
    if self._isLongClickFace then
        return
    end
    local type = ModelChat.MSGTYPE_NORMAL
    self:SendChatMsg(faceinstead, type, false)
end
function UISayPop:RefreshBubble()
    local _type = self._bubbleType
    local list = {}
    local refs = gModelPlayer:GetRolePlayerHeadListByType(ModelPlayerSpace.BUBBLE)
    for i, v in pairs(refs) do
        if _type == v.subType then
            table.insert(list, v)
        end
    end
    local useId = gModelPlayer:GetBubble()
    table.sort(list, function(a, b)
        --local aS = a.refId == useId and 1 or 0
        --local bS = b.refId == useId and 1 or 0
        return a.sort < b.sort
    end)
    if not self._curSelBubble then
        self._curSelBubble = useId
        for i, v in ipairs(list) do
            if v.refId == useId then
                self._oldSelIndex = i
                break
            end
        end
    end
    self:RefreshBubbleInfo()

    local _uiList = self._bubbleSuper
    if _uiList then
        _uiList:RefreshList(list)
        _uiList:DrawAllItems()
    else
        _uiList = self:GetUIScroll("mBubbleSuper")
        self._bubbleSuper = _uiList
        _uiList:Create(self.mBubbleSuper, list, function(...)
            self:BubbleListItem(...)
        end, UIItemList.SUPER_GRID)
        _uiList:EnableScroll(true, false)
    end
end
---刷新气泡
function UISayPop:RefreshBubbleType()
    local list = gModelPlayer:GetRoleAdventureImageTypeRef(ModelPlayerSpace.BUBBLE)
    local _uiList = self._uiBubbleTypeList
    if _uiList then
        _uiList:RefreshList(list)
    else
        _uiList = self:GetUIScroll("mBubbleTypeScroll")
        self._uiBubbleTypeList = _uiList
        _uiList:Create(self.mBubbleTypeScroll, list, function(...)
            self:BubbleTypeListItem(...)
        end)
    end
    if not self._isOnBubbleType then
        self._isOnBubbleType = true
        gModelPlayer:OnPersonaliseInfoReq(ModelPlayerSpace.BUBBLE)
    end
    local useId = gModelPlayer:GetBubble()
    if useId then
        local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(useId)
        local subType = ref.subType
        self:OnClickBubbleType(subType)
        return
    end
    self:OnClickBubbleType(list[1].type)
end
-- 【C宠物系统】删掉宠物系统相关
-- function UISayPop:RefreshPetType()
-- 	CS.ShowObject(self.mCommScroll,true)
-- 	local list = gModelChat:GetChatBtnScreenRefListByType(ModelChat.EXTENDFUN_TYPE_5)
-- 	self:RefreshTypeScroll(list)
-- 	if #list > 0 then
-- 		self:OnClickAddItemType(list[1])
-- 	end
-- end
function UISayPop:RefreshHeroType()
    CS.ShowObject(self.mCommScroll, true)
    local list = gModelChat:GetChatBtnScreenRefListByType(ModelChat.EXTENDFUN_TYPE_2)
    self:RefreshTypeScroll(list)
    if #list > 0 then
        self:OnClickAddItemType(list[1])
    end
end
function UISayPop:GetChatHeight(msg, addH)
    self:SetWndText(self.mTestText2, msg)
    local height = self.mTestText2_1.preferredHeight + (addH or 0)
    return height
end
function UISayPop:SetTitleLevel(item, itemdata)
    local rateIcon = self:FindWndTrans(item, "RateIcon")
    local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(itemdata.title)
    CS.ShowObject(rateIcon, ref)
    if not ref then
        return
    end
    self:SetWndEasyImage(rateIcon, ref.icon, nil, true)
    self:SetWndClick(rateIcon, function()
        GF.OpenWnd("UIPerSpreadPop", { StructPersonaliseInfo = { refId = itemdata.title, playerName = itemdata.playerName } })
    end)
end

function UISayPop:TimeListItem(item, itemdata, itempos)
    local timeTrans = self:FindWndTrans(item, "Time")
    local bImage = self:FindWndTrans(timeTrans, "BImage")
    local desText = self:FindWndTrans(bImage, "XUIText")

    local timeStr = itemdata.timeStr
    self:SetWndText(desText, timeStr)
    self:GetSysInfoWidth(timeStr, bImage, item)
end
function UISayPop:BubbleListItem(list, item, itemdata, itempos)
    local root = self:FindWndTrans(item, "Root")
    local chatBg = self:FindWndTrans(root, "ChatBg")
    local isSel = self:FindWndTrans(root, "IsSel")
    local isUse = self:FindWndTrans(root, "IsUse")

    self:SetBubbleImg(chatBg, itemdata)
    local refId = itemdata.refId
    local activateLis = gModelPlayer:GetPersonaliseInfo(ModelPlayerSpace.BUBBLE) or {}
    local isActivate = activateLis[refId] and activateLis[refId].state == 0
    local canvasGroup = chatBg:GetComponent(typeofCanvasGroup)
    canvasGroup.alpha = isActivate and 1 or 0.3
    local useId = gModelPlayer:GetBubble()

    CS.ShowObject(isUse, useId == refId)
    CS.ShowObject(isSel, self._curSelBubble == refId)
    self:SetWndClick(root, function()
        self:OnClickBubbleItem(refId, itempos)
    end)
end
function UISayPop:OnClickLongType2Emoji(itemdata)
    self._isLongClickFace = true
    CS.ShowObject(self.mFaceBubble, true)
    local isSpine = itemdata.isSpine and itemdata.isSpine == 1
    CS.ShowObject(self.mFaceSpine, isSpine)
    CS.ShowObject(self.mFaceIcon, not isSpine)
    if isSpine then
        local faceSpine = self._oldFaceSpine
        local _faceSpine = itemdata.faceSpine
        if faceSpine and faceSpine ~= _faceSpine then
            self:DestroyWndSpineByKey("faceKey")
        end
        self:CreateWndSpine(self.mFaceSpine, _faceSpine, "faceKey", false)
        self._oldFaceSpine = _faceSpine
    else
        self:SetWndEasyImage(self.mFaceIcon, itemdata.faceIcon)
    end
end
------------------------------------------------------------------
return UISayPop