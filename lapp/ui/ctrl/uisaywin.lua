---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
local CS = CS
local typeof = typeof
local typeGridLayoutGroup = typeof(CS.GridLayoutGroup)
---@class UISayWin:LWnd
local UISayWin = LxWndClass("UISayWin", LWnd)
local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
local typeLayoutElement = typeof(UnityEngine.UI.LayoutElement)

UISayWin.GAME_HELPER_CHANNEL = -1
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISayWin:UISayWin()
	self._funBtnList={}--扩展类型按钮Trans列表
	self._isLongClisk = false--是否长按了头像
	self._targetInfo={}--目标玩家信息
	self._uiChatFriendList=nil--私聊好友Scroll
	self._typeBtnList={}--类型按钮
	self._uicommonList={}
	self._omfpScrollWidth=0
	self._omfpScrollHeight=0
	self._uiHyperList = {}
	self._uiheadList={}
	self._tabBtnList = {}					--频道按钮Trans列表
	self._currChannel = nil					--当前频道
	self._currPritavePlayer = nil			--当前私聊对象
	self._privateRedList = {}				--私聊好友红点
	self._pointerUpKey = "_pointerUpKey"	--是否长按了表情
	self._playerOnlineKey = "_playerOnlineKey"
	self._childChannelTimeKey = "_childChannelTimeKey"
	self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISayWin:OnWndClose()
	LWnd.OnWndClose(self)
	if CS.IsValidObject(self.mXUIInputText) then
		gModelChat:SetInputMsg(self.mXUIInputText.text)
	end
	gModelChat:DelAllTranslate()
	local _currChannel = self._currChannel
	if _currChannel then
		local ref = gModelChat:GetChatChannelRefByChannelId(_currChannel)
		if ref then
			gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT,"关闭聊天",ccLngText(ref.channel))
			LPlayerPrefs.SetGameChatChannel(tostring(_currChannel))
		end
	end
	FireEvent(EventNames.ON_CHAT_AIR_WIN_UPDATE,true)
	self:ClearCommonIconList(self._uiheadList)
	self:ClearCommonIconList(self._uiHyperList)
	self._uiHyperList = nil
	self:ClearCommonIconList(self._uicommonList)
	self._uicommonList = nil
	FireEvent(EventNames.ON_CHAT_TA_SHOW,true)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISayWin:OnCreate()
	LWnd.OnCreate(self)
	FireEvent(EventNames.ON_CHAT_AIR_WIN_UPDATE,false)
	gModelChat:GetChatSaveToFile()--读取私聊
	FireEvent(EventNames.ON_CHAT_TA_SHOW,false)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISayWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	--self:DisableInputText(self.mXUIInputText)
	self:InitAdaptKeyboard()

	self:VersionRefresh()
end
--点击浮窗
function UISayWin:OnClickAir()
	local gameAirSetToggle = LPlayerPrefs.gameAirSetToggle or "0"
	local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
	if not sensitive then
		GF.ShowMessage(ccClientText(30800))
		return
	end
	if gameAirSetToggle == "1" then
		gModelGeneral:OpenUIOrdinTips({refId = 130003,func = function()
			self:CloseAir()
			GF.ShowMessage(ccClientText(11154))
		end })
	else
		gModelGeneral:OpenUIOrdinTips({refId = 130002,func = function()
			LPlayerPrefs.SetGameAirSetToggle("1")
			FireEvent(EventNames.ON_CHAT_AIR_UPDATE)
			CS.ShowObject(self.mMaskAir,false)
			gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT,"浮窗功能开启")
			GF.ShowMessage(ccClientText(11153))
		end })
	end
end

function UISayWin:InitCommand()
	local channelId = self:GetWndArg("channel")
	--local isFromAir = self:GetWndArg("isFromAir")
	--local isAuto = tonumber(LPlayerPrefs.gameHelperSel) == 1
	--if isAuto then
	--	if isFromAir or not channelId then
	--		channelId = -1
	--	end
	--end

	if not channelId then
		channelId = tonumber(LPlayerPrefs.gameChatChannel)
	end

	if channelId ~= -1 then
		if(not gModelChat:GetChatChannelIsOpent(channelId,3,false))then
			channelId = ModelChat.CHANNEL_WORLD
		end
	end

	self._callFun=self:GetWndArg("call")
	self._privatePlayerInfo=self:GetWndArg("playerInfo")

	self:SetWndButtonText(self.mSendBtn,ccClientText(12433))
	self.mXUIInputText.characterLimit = gModelChat:GetChatConfigRefByKey("chatWordLimit")

	local _inputMsg = gModelChat:GetInputMsg()
	if _inputMsg and _inputMsg ~= "" then
		--self.mXUIInputText.text = _inputMsg
		self:SetWndTextInput(self.mXUIInputText, _inputMsg)
	else
		--local text = CS.FindTrans(self.mXUIInputText_1,"Text Area/Placeholder")
		--self:SetWndText(text,ccClientText(11133))
		self:SetWndTextInput(self.mXUIInputText, nil, ccClientText(11133))
	end

	self:SetWndText(self.mBubbleText,ccClientText(11145))
	self:SetWndText(self.mAirText,ccClientText(11146))

	self:RefreshTabUiList()

	--if channelId == -1 then
	--	self:OpenGameHelper()
	--else
		self:OnClickChannelTab(channelId)
	--end
	self:RefreshChannlTab(true)

	local isAir = gModelFunctionOpen:CheckIsOpened(11700010,false)
	CS.ShowObject(self.mBtnAir,isAir)
	local isBubble = gModelFunctionOpen:CheckIsOpened(11700020,false)
	CS.ShowObject(self.mBtnBubble,isBubble)
	if isAir then
		local gameAirSetToggle = LPlayerPrefs.gameAirSetToggle or "0"
		CS.ShowObject(self.mMaskAir,gameAirSetToggle == "0")
	end
	if isBubble then
		local gameBubbleSetToggle = LPlayerPrefs.gameBubbleSetToggle or "0"
		CS.ShowObject(self.mMaskBubble,gameBubbleSetToggle == "0")
	end
end
--点击切换好友聊天
function UISayWin:OnClickCutFriend(playerInfo, bReset)
	if playerInfo then
		gModelChat:DelPrivateRed(playerInfo.playerId)
	end
	self._currPritavePlayer = playerInfo
	self._uiFriendList:DrawAllItems()
	self:RefreshInfoScroll(ModelChat.CHANNEL_PRIVATE)
end

function UISayWin:OnClickCutBtn()--点击切换 语音 或 输入
	GF.ShowMessage(ccClientText(11108))
end

function UISayWin:RefreshInfoUIList(infoList,isTranslate)--刷新聊天数据不刷cell
	local channel = self._currChannel
	if channel ~= ModelChat.CHANNEL_PRIVATE then
		local isChildChannelList = gModelChat:GetIsChildChannelUiListByChannel(channel)
		local uiList = isChildChannelList and self.mChildChannelMsgScrol or self.mMsgScroll
		local key = isChildChannelList and "childChannel" or "channel"
		local _uiInfoList = self:GetUIScroll("uiInfoList"..key)
		if(_uiInfoList:GetList())then
			_uiInfoList:RefreshList(infoList,true)
		else
			_uiInfoList:Create(uiList,infoList,function (...) self:SetInfoListItem(...) end, UIItemList.SUPER)
		end
		self._uiInfoList = _uiInfoList
		local _uiList = _uiInfoList:GetList()
		if isTranslate then
			_uiList:DrawAllItems()
		end
	else
		local _uiFriendMsgList = self._uiFriendMsgList
		if(_uiFriendMsgList)then
			_uiFriendMsgList:RefreshList(infoList)
		else
			_uiFriendMsgList = self:GetUIScroll("_uiFriendMsgList")
			_uiFriendMsgList:Create(self.mFriendMsgScrol,infoList,function (...) self:SetInfoListItem(...) end, UIItemList.SUPER)
			self._uiFriendMsgList = _uiFriendMsgList
		end
		local _uiList = _uiFriendMsgList:GetList()
		if isTranslate then
			_uiList:DrawAllItems()
		else
			_uiList:MoveToPos(#infoList + 1)
		end
		gModelChat:DelChannelRed(ModelChat.CHANNEL_PRIVATE)
	end
end

function UISayWin:RefreshChannlTab(initCom)--刷新频道标签红点
	--local _currChannel = self._currChannel

	local channelList = gModelChat:GetChannelRed()
	--if _currChannel > 0 and not initCom then--打开界面已经刷新过了，不刷新
	--	self:RefreshInfoScroll(_currChannel)--刷新频道信息
	--end
	local Redlist = {}
	for i, v in pairs(channelList) do
		local ref = gModelChat:GetChatChannelRefByChannelId(i)
		local bool = gModelChat:CheckIsOpenedStr(ref.openId)
		if bool then
			local channelId = ref.channelId
			if ref.sortSmall > 0 then
				channelId =ref.sortSmall
			end
			local num = Redlist[channelId] or 0
			num = num + v
			Redlist[channelId] = num
		end
	end
	for i, v in pairs(self._tabBtnList) do
		local red = CS.FindTrans(v,"Root/Red")
		CS.ShowObject(red,false)
	end
	for i, v in pairs(Redlist) do--设置红点
		local bool = gModelChat:GetChatChannelIsOpent(i,3,false)
		if( bool)then
			local trans = self._tabBtnList[i]
			if trans then
				local red = CS.FindTrans(trans,"Root/Red")
				local redText = CS.FindTrans(red,"UIText")
				CS.ShowObject(red,true)
				local limit=gModelChat:GetChatConfigRefByKey("chatInfoLimit")
				if(v>limit)then
					self:SetWndText(redText,"...")
				else
					self:SetWndText(redText,v)
				end
			end
		end
	end
end
--点击头像
function UISayWin:OnClickHead(itemdata)
	if(self._isLongClisk)then
		self._isLongClisk = false
		return
	end
	if(not itemdata.playerId or itemdata.playerId == "")then
		return
	end
	local playerId = gModelPlayer:GetPlayerId()
	if(itemdata.playerId == playerId )then
		GF.ShowMessage(ccClientText(11522))
		return
	end
	if( self._currChannel == ModelChat.CHANNEL_PROVINCE)then
		--- ChatConfigRef.provinceReport  省份频道：0=弹举报，1=弹详情。没有key默认为0
		local provinceReport = gModelChat:GetChatConfigRefByKey("provinceReport") or 0
		if provinceReport == 0 then
			gModelGeneral:OpenUIOrdinTips({refId = 50001,para = {itemdata.playerName},func = function (...)
				gModelFriend:OnRelationProcessReq(3,playerId,itemdata.playerId,1)
			end, leftFunc = function (...)
				if(gModelFunctionOpen:CheckIsOpened(11799000,true))then
					GF.OpenWnd("UIRepin",{channelId = itemdata.channel, channelIndex = itemdata.number})
				end
			end})
			return
		end
	end
	if(itemdata.playerId == "-1")then
		GF.ShowMessage(ccClientText(11122))
		return
	end
	gModelGeneral:PlayerShowReq(itemdata.playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.CHAT_SYSTEM,itemdata.channel,itemdata.number or 1)
end

function UISayWin:OnClickVoice()--语音
	GF.ShowMessage(ccClientText(11108))
end

--刷新信息列表
function UISayWin:RefreshInfoScroll(index,isTranslate)
	local _currPritavePlayer = self._currPritavePlayer
	local infoList = gModelChat:GetTypeInfo(index,_currPritavePlayer)
	local infoLen = #infoList
	local isShowNR = infoLen <= 0
	if index == ModelChat.CHANNEL_GUILD then
		local isGuild = gModelChat:GetGuildIsOpent()
		if not isGuild then
			isShowNR = true
		end
	end
	self:RefreshInfoUIList(infoList,isTranslate)
	CS.ShowObject(self.mNoRecord,isShowNR)
	if index == ModelChat.CHANNEL_PRIVATE then
		CS.ShowObject(self.mImportMar,_currPritavePlayer)
		return
	end
	if isTranslate then
		return
	end
	local _uiMsgItemList = self._uiInfoList
	local _uiInfoList = _uiMsgItemList:GetList()
	local _currInfoIndex = self._currInfoIndex or 0
	if  _currInfoIndex > 0 and infoLen - _currInfoIndex > 10 and index ~= ModelChat.CHANNEL_SYSTEM then
		CS.ShowObject(self.mDownBtn,true)
		local channelList = gModelChat:GetChannelRed()
		local num = channelList[index] or 1
		self:SetWndText(self.mDownBtnText,num..ccClientText(11107))
		self:SetWndClick(self.mDownBtn, function (...)
			CS.ShowObject(self.mDownBtn,false)
			self:RefreshInfoUIList(infoList)
			local lastIndex = infoLen
			_uiInfoList:RefreshList()
			_uiInfoList:MoveToPos(lastIndex)
			gModelChat:DelChannelRed(index)
		end)
		return
	end
	local _callTaIndex = gModelChat:GetChannelCall(index)
	if _callTaIndex > 0 and infoLen - _callTaIndex > 5 then
		CS.ShowObject(self.mUpBtn,true)
		local num = infoLen - _callTaIndex
		self:SetWndText(self.mUpBtnText,string.replace(ccClientText(11120),num))
		self:SetWndClick(self.mUpBtn, function (...)
			CS.ShowObject(self.mUpBtn,false)
			_uiInfoList:RefreshList()
			_uiInfoList:MoveToPos(_callTaIndex)
			gModelChat:DelChannelCall(index)
		end)
	end

	if _currInfoIndex == 0 or infoLen - _currInfoIndex <= 10 or self.mIfMeSend or index == ModelChat.CHANNEL_SYSTEM then
		self.mIfMeSend = false
		local lastIndex = infoLen+1
		_uiInfoList:RefreshList()
		_uiInfoList:MoveToPos(lastIndex)
		gModelChat:DelChannelRed(index)
		return
	end
	_uiInfoList:RefreshList(infoList)
	_uiInfoList:DrawAllItems()
end

function UISayWin:CreateEmptyShow(refId)
	local text = self:FindWndTrans(self.mEmptyBtn,"Light/Text")
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

function UISayWin:OnClickDelUp()
	CS.ShowObject(self.mUpBtn,false)
	gModelChat:DelChannelCall(self._currChannel)
end
--刷新私聊设置
function UISayWin:RefreshPriverChatFrind()
	local _privatePlayerInfo = self._privatePlayerInfo or self._currPritavePlayer
	local chatFriendLsit = gModelChat:AddPrivateChat(_privatePlayerInfo,false)
	local friendLen = #chatFriendLsit
	--self._playerOnlineTrs = {}
	local chatClean = gModelChat:GetChatConfigRefByKey("chatClean")
	CS.ShowObject(self.mFriendTips,friendLen > chatClean)
	local _playerOnlineIds = {}
	for i, v in ipairs(chatFriendLsit) do
		local playerInfo = v.playerInfo
		if playerInfo then
			table.insert(_playerOnlineIds,playerInfo.playerId)
		end
	end
	table.sort(chatFriendLsit,function (a,b)
		local _aplayerId = a.playerId
		local _bplayerId = b.playerId
		local isAPlayer = _aplayerId and 1 or 0
		local isBPlayer = _bplayerId and 1 or 0
		if isAPlayer ~= isBPlayer then
			return isAPlayer > isBPlayer
		end
		if _aplayerId and _bplayerId then
			local aRed = gModelChat:GetPrivateChannelRed(_aplayerId)
			local bRed = gModelChat:GetPrivateChannelRed(_bplayerId)
			if aRed ~= bRed then
				return aRed > bRed
			end
			local isATime = a.time and 1 or 0
			local isBTime = b.time and 1 or 0
			if isATime ~= isBTime then
				return isATime > isBTime
			end
			local aTime = a.time and a.time or "-1"
			local bTime = b.time and b.time or "-1"
			if aTime ~= bTime then
				return aTime > bTime
			end
		end
		return false
	end)
	if  _privatePlayerInfo then
		self._currPritavePlayer = _privatePlayerInfo
	elseif  chatFriendLsit[1].playerInfo then
		self._currPritavePlayer = chatFriendLsit[1].playerInfo
	end
	local _uiFriendList = self._uiFriendList
	if(_uiFriendList)then
		_uiFriendList:RefreshList(chatFriendLsit)
	else
		_uiFriendList = self:GetUIScroll("uiFriendList")
		_uiFriendList:Create(self.mFriendSuper,chatFriendLsit,function (...) self:SetChatFriendListItem(...) end, UIItemList.SUPER)
		_uiFriendList:EnableScroll(true,true)
		self._uiFriendList = _uiFriendList
	end

	if _privatePlayerInfo then
		_uiFriendList:MoveToPos(1)
	else
		_uiFriendList:DrawAllItems()
	end
	self._privatePlayerInfo = nil
	self:UpdatePrivateRed()
	local _playerOnlineKey = self._playerOnlineKey
	if #_playerOnlineIds <= 0 then
		self:TimerStop(_playerOnlineKey)
		return
	end
	if not self:IsTimerExist(_playerOnlineKey) then
		self:TimerStart(_playerOnlineKey,60,false,-1)
	end
	self._currPlayerOnlineIds = _playerOnlineIds
	gModelChat:PlayerOnlineReq(_playerOnlineIds,"1")
end

function UISayWin:RefreshTabUiList()
	local list = gModelChat:GetChannelListRef()

	local btnDataList = {}

	--local helperBtnData =
	--{
	--	type = 2,
	--	channelId = UISayWin.GAME_HELPER_CHANNEL,
	--	btnName = ccClientText(24204), --"助手" ,
	--	btnOn = "chat_icon_8_1",
	--	btnOff = "chat_icon_8_2",
	--	btnGray = "chat_icon_8_3",
	--	funcId = GameTable.AssistantConfig["helperAccelerateOpne"],
	--}
    --
	--if gModelFunctionOpen:CheckIsShow(23000000) then
	--	table.insert(btnDataList,helperBtnData)
	--end

	for k,v in ipairs(list) do
		local tabBtn = string.split(v.tabBtn,",")
		local data =
		{
			type = 1,
			channelId = v.channelId,
			btnName = ccLngText(v.channel),
			btnOn = tabBtn[1],
			btnOff = tabBtn[2],
			btnGray = tabBtn[3],
		}

		table.insert(btnDataList,data)
	end
	local uiList = self._tabUiList
	if uiList then
		uiList:RefreshList(btnDataList)
	else
		uiList = self:GetUIScroll("tab")
		uiList:Create(self.mChannelScroll,btnDataList,function (...) self:SetTabListItem(...) end)
		self._tabUiList = uiList
		uiList:EnableScroll(true, false)
	end
end

--设置气泡资源
function UISayWin:SetChatBubble(item,bubbleId,isMe)
	local initChatBg = gModelPlayer:GetRoleConfigRefByKey("initChatBg")
	local refId = initChatBg
	if bubbleId and bubbleId > 0 then
		refId = bubbleId
	end
	local arrows = self:FindWndTrans(item,"Arrows")
	local uiText = self:FindWndTrans(item,"XUIText")
	local pendantList = {}
	for i = 1, 4 do
		local pendant = self:FindWndTrans(item,"Pendant"..i)
		pendantList[i] = pendant
	end

	if refId == initChatBg then

		--self:SetWndEasyImage(item,isMe and "chat_bg_1" or "chat_bg_2")
		--self:SetWndEasyImage(arrows,isMe and "chat_arrow_1" or "chat_arrow_2")
		self:SetWndEasyImage(arrows,isMe and "chat_arrow_1" or "chat_frame_bg_1_2")
		for i, v in ipairs(pendantList) do
			CS.ShowObject(v,false)
		end
		local color = isMe and "734f22ff" or "e5e5e5ff"
		color = LUtil.ColorByHex(color)
		local xuitxt = self:FindWndText(uiText)
		self:SetXUITextColor(xuitxt,color)
		arrows.anchoredPosition = Vector2.New(arrows.anchoredPosition.x,-20)
		return
	end

	local roleRef = gModelPlayer:GetRolePlayerHeadRefByRefId(refId)
	local iconArr = string.split(roleRef.icon,"|")
	self:SetWndEasyImage(item,iconArr[1])
	self:SetWndEasyImage(arrows,iconArr[2])
	for i, v in ipairs(pendantList) do
		local iconStr = iconArr[i+2] or "0"
		CS.ShowObject(v,iconStr ~= "0")
		if iconStr ~= "0" then
			self:SetWndEasyImage(v,iconStr,nil,true)
		end
	end
	local tagColour = roleRef.tagColour
	if string.isempty(tagColour) then return end
	local color = LUtil.ColorByHex(tagColour.."FF")
	local xuitxt = self:FindWndText(uiText)
	self:SetXUITextColor(xuitxt,color)
	arrows.anchoredPosition = Vector2.New(arrows.anchoredPosition.x,roleRef.arrowPointY)
end

--设置扩展功能类型
function UISayWin:SetAddFunListItem(list, item, itemdata, itempos)
	self._funBtnList[itemdata.type]=item
	local name = ccLngText(itemdata.name)
	local addFontSize = -4
	if gLGameLanguage:IsKoreaVersion() then
		addFontSize = -6
	end
	self:SetWndTabText(item, name,addFontSize)
	self:SetWndClick(item, function (...) self:OnClickAddFunTypeBtn(itemdata.type) end)
end

function UISayWin:SetTabListItem(list, item, itemdata, itempos)--标签设置
	self._tabBtnList[itemdata.channelId]=item
	local title =itemdata.btnName -- ccLngText(itemdata.channel)
	if gLGameLanguage:IsForeignVersion() then
		local size = 22
		if itemdata.channelId == 5 then
			size = 20
		elseif itemdata.channelId == 2 then
			size = 16
		elseif itemdata.channelId == 6 then
			size = 18
		end
		title = string.format("<size=%s>%s</size>",size,title)
	end
	local root = self:FindWndTrans(item, "Root")
	local btnTabTrans = self:FindWndTrans(root, "BtnTabIcon")
	local imgOff = self:FindWndTrans(btnTabTrans, "Off")
	local textOff = self:FindWndTrans(btnTabTrans, "Off/Text")
	local imgOn = self:FindWndTrans(btnTabTrans, "On/Image")
	local textOn = self:FindWndTrans(btnTabTrans, "On/Text")
	local imgGray = self:FindWndTrans(btnTabTrans, "Gray")
	local textGray = self:FindWndTrans(btnTabTrans, "Gray/Text")

	self:SetWndText(textOff, title)
	self:SetWndText(textOn, title)
	self:SetWndText(textGray, title)
	self:SetWndEasyImage(imgOff,itemdata.btnOff)
	self:SetWndEasyImage(imgOn,itemdata.btnOn)
	self:SetWndEasyImage(imgGray,itemdata.btnGray)

	local isOpen = true
	if itemdata.type == 1 then
		isOpen = gModelChat:GetChatChannelIsOpent(itemdata.channelId,3,false)
	else
		if itemdata.funcId then
			isOpen = gModelFunctionOpen:CheckIsOpened(itemdata.funcId)
		end
	end
	local tapState = isOpen and LWnd.StateOff or  LWnd.StateGray
	self:ChangeTab(item,tapState)

	self:SetWndClick(root, function (...)
		self:OnClickTabBtn(itemdata)
	end)
end
function UISayWin:RefreshChildChannel(childList,channelId)
	local list = childList or {}
	local uiList = self._childChannelUiList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("_childChannelUiList")
		uiList:Create(self.mChildChannelSuper,list,function (...) self:ChildChannelListItem(...) end,UIItemList.SUPER)
		self._childChannelUiList = uiList
		uiList:EnableScroll(true, true)
	end
	if channelId > 2 then
		self:OnClickChildChannel(channelId)
	else
		self:OnClickChildChannel(list[1].channelId)
	end
end
--刷新频道设置
function UISayWin:RefreshChannel()
	local _currChannel = self._currChannel
	if not _currChannel or _currChannel < 0 then
		return
	end
	local isPrivte = _currChannel == ModelChat.CHANNEL_PRIVATE
	local isChildChannelList = gModelChat:GetIsChildChannelUiListByChannel(_currChannel)
	CS.ShowObject(self.mChatPart,true)
	CS.ShowObject(self.mHelperPart,false)
	CS.ShowObject(self.mHelperTop,false)
	CS.ShowObject(self.mDownBtn,false)
	CS.ShowObject(self.mUpBtn,false)
	CS.ShowObject(self.mImportMar,true)
	CS.ShowObject(self.mMsgScroll,not isPrivte and not isChildChannelList)
	CS.ShowObject(self.mFriendMar,isPrivte)
	CS.ShowObject(self.mFriendMsgScrol,isPrivte)
	CS.ShowObject(self.mChildChannelMsgScrol,isChildChannelList)

	local showTips,tipsStr = false,""
	self:CreateEmptyShow( 5401)
	if(_currChannel == ModelChat.CHANNEL_GUILD)then--公会
		local bool = gModelChat:GetGuildIsOpent()
		if(not bool)then
			CS.ShowObject(self.mMsgScroll,false)
			CS.ShowObject(self.mImportMar,false)
			showTips = true
			tipsStr = ccClientText(11103)
			gModelChat:DelChannelRed(_currChannel)
			self:CreateEmptyShow( 5402)
		end
	elseif(_currChannel == ModelChat.CHANNEL_SYSTEM)then--系统
		CS.ShowObject(self.mImportMar,false)
		showTips = true
		tipsStr = ccClientText(11102)
	elseif isPrivte then--私聊
		self:RefreshPriverChatFrind()
	end
	CS.ShowObject(self.mTipsBg,showTips)
	self:SetWndText(self.mTipsText,tipsStr)
	self:RefreshInfoScroll(_currChannel)
end

function UISayWin:InitData()
	self._helperTabDatas =
	{
		[1] =
		{
			name = ccClientText(24202), --"战斗助手",
			index = 1,
		},
		[2] =
		{
			name = ccClientText(24203), --"减负助手",
			index = 2,
		},

	}

	self._playCountdown = "_playCountdown"
	local list = gLGameLanguage:GetShowLanguageList()
	self._languageLen = #list
end
--选择扩展类型
function UISayWin:OnClickBtnTypeBtn(type, dataType)
	if type==1 then--表情
		local size,count
		if(not gModelChat:GetEmojiTypeIsOpent(dataType))then
			return
		end
		local ref= gModelChat:GetChatFaceTypeRefByRefId(dataType)
		local emojiList=gModelChat:GetEmojiByType(ref.faceType)
		if(ref.textType == 1)then
			size,count=55,9
		elseif(ref.textType == 2)then
			size,count=86,6
		end
		if not size or not count then
			printInfoNR(string.format("ChatFaceTypeRef refId : %s   .textType :%s 没有改类型",dataType,ref.textType))
			return
		end
		for i, v in ipairs(emojiList) do
			v.textType = ref.textType
		end
		local group= CS.FindTrans(self.mEmojiScroll,"ItemRoot"):GetComponent(typeGridLayoutGroup)
		group.cellSize=Vector2.New(size,size)
		group.constraintCount=count
		if(self._uiEmojiList)then
			self._uiEmojiList:RefreshList(emojiList)
		else
			self._uiEmojiList = self:GetUIScroll("uiEmojiList")
			self._uiEmojiList:Create(self.mEmojiScroll,emojiList,function (...) self:SetEmojiListItem(...) end,UIItemList.WRAP)
		end
	else
		local itemList = {}
		if type==2 then--装备
			itemList= gModelHero:GetHeroListByType(dataType)
		else--物品
			if(dataType == 203)then
				--itemList = gModelEquip:GetEquipItemList()
				-- itemList = gModelOutfit:GetChatList()
			elseif(dataType == 206)then
				itemList = gModelRune:GetNotWearRuneList(false)
			else
				itemList=gModelItem:GetItemListByType(dataType)
			end

		end
		if(self._uiCommList)then
			self._uiCommList:RefreshList(itemList)
		else
			self._uiCommList = self:GetUIScroll("uiCommList")
			self._uiCommList:Create(self.mCommScroll,itemList,function (...) self:ItemListItem(...) end,UIItemList.WRAP)
		end
	end
	if(dataType and dataType~=self._oldType)then
		if(self._oldType>=0)then
			local trans=self._typeBtnList[self._oldType]
			self:ChangeTypeBtn(trans,false)
		end
		local trans= self._typeBtnList[dataType]
		self:ChangeTypeBtn(trans,true)
		self._oldType=dataType
	end
end

function UISayWin:OnCallTaOpenInfoPop(table)
	GF.OpenWnd("UIPerInfoPop",{
		playerInfo=table.playerInfo,
		combatHeroData=table.combatHeroData,
		systemType=table.systemType,
		channelId=table.channelId,
		channelIndex=table.channelIndex,
		treasures = table.treasures,
		--cellFun=function (...)
		--	self:OnLongClickHead(...)
		--end
	})
end
----------------------------------------------------OnClick-------------------------------------------------
function UISayWin:OnClickChannelTab(index)--点击频道标签
	if(not gModelChat:GetChatChannelIsOpent(index,3,true))then
		return
	end
	local ref = gModelChat:GetChatChannelRefByChannelId(index)
	local channelId = index
	if ref.sortSmall > 0 then
		channelId = ref.sortSmall
	end
	local _currChannel = self._currChannel
	if(_currChannel)then
		if(channelId == _currChannel and _currChannel ~= ModelChat.CHANNEL_PRIVATE)then
			return
		end
		self:ChangeTab(nil,LWnd.StateOff,_currChannel)
	end
	self:ChangeTab(nil,LWnd.StateOn,channelId)

	local childList = gModelChat:GetChildChannelListByChannel(channelId)
	local childLen = #childList
	CS.ShowObject(self.mChildChannelMar,ref.sortSmall > 0)
	CS.ShowObject(self.mChildChannelTips,ref.sortSmall > 0)
	if childLen > 0 then
		self:RefreshChildChannel(childList,index)
		return
	end
	self:TimerStop(self._childChannelTimeKey)
	self:ChangeChannel(channelId)
end

--item调整
function UISayWin:GetChatInfoWidth(msg, chatBg,item,isTag,bubble,isShowVipTitle)
	local initChatBg = gModelPlayer:GetRoleConfigRefByKey("initChatBg")
	local isBubble = not bubble or bubble == 0 or bubble ==  initChatBg
	local uiText = self:FindWndTrans(chatBg,"XUIText")
	local width = self:GetChatWidth(msg)
	local height = self:GetChatHeight(msg)
	local height2 = height
	local cH = 0								--高度差
	local itemH = 76							--item要加的高度
	local chatGH = 45							--气泡必须的高度	--根据ui
	local chatAH = 18							--气泡必须加的高度
	uiText.anchoredPosition = Vector2.New(uiText.anchoredPosition.x,-10)
	if isBubble then
		chatGH = chatAH
	end

	local chatAddH = chatGH - (height2 + chatAH)		--气泡附加高度
	if chatAddH < 0 then
		chatAddH = 0
	end
	if not isBubble and chatAddH > 0 then
		uiText.anchoredPosition = Vector2.New(uiText.anchoredPosition.x,-18)
	end

	local chatGW = 61							--气泡必须的宽度	--根据ui
	local chatAW = 36							--气泡必须加的宽度
	if isBubble then
		chatGW = chatAW
	end

	local chatAddW = chatGW - (width + chatAW)		--气泡附加宽度
	if chatAddW < 0 then
		chatAddW = 0
	end
	if(height < 30)then
		cH = 15
	end

	height = itemH + height + cH
	local higth = isTag and height + 20 or height
    higth = isShowVipTitle and higth + 20 or higth
	LxUiHelper.SetSizeWithCurAnchor(item,1,higth)
	chatBg.sizeDelta = Vector2.New(width + chatAddW + chatAW,height2 + chatAddH + chatAH)
	uiText.sizeDelta = Vector2.New(width,height2)
end

function UISayWin:OnClickTabBtn(itemdata)
	--if itemdata.type == 1 then
		--[[ --策划说不用了，太频繁，去掉
		if itemdata.channelId == ModelChat.CHANNEL_HW then
			if gLGameLanguage:IsForeignVersion() and LPlayerPrefs.chat50009pop == "true" then
				gModelGeneral:OpenUIOrdinTips({refId = 50009, func = function ()
					LPlayerPrefs.SetChat50009pop("false")
				end})
			end
		end
		]]--
		self._currInfoIndex = nil
		self:OnClickChannelTab(itemdata.channelId)
	--else
	--	self:OpenGameHelper()
	--end
end
--点击扩展功能类型
function UISayWin:OnClickAddFunTypeBtn(type)
	local _btnType = self._btnType
	local _funBtnList = self._funBtnList
	if(_btnType)then
		if(_btnType == type)then
			return
		end
		local oldTrans = _funBtnList[_btnType]
		self:SetWndTabStatus(oldTrans, LWnd.StateOff)
	end
	local trans = _funBtnList[type]
	self:SetWndTabStatus(trans, LWnd.StateOn)
	self._btnType = type

	CS.ShowObject(self.mEmojiList,false)
	CS.ShowObject(self.mCommScroll,false)
	CS.ShowObject(self.mCombatSuper,false)
	CS.ShowObject(self.mTypeBg,true)
	local list={}
	local dataType
	if type == ModelChat.EXTENDFUN_TYPE_1 then--表情
		CS.ShowObject(self.mEmojiList,true)
		list=gModelChat:GetEmojiTypeRef()
		dataType = list[1].type
	elseif type == ModelChat.EXTENDFUN_TYPE_4 then
		CS.ShowObject(self.mTypeScroll,false)
		CS.ShowObject(self.mCombatSuper,true)
		CS.ShowObject(self.mTypeBg,false)
		local dataList = gModelFormation:GetCombatTypeList()
		local combatList = {}
		for i, v in ipairs(dataList) do
			local power = gModelPower:GetFormationPower(v.refId)
			if power > 0 then
				table.insert(combatList,v)
			end
		end
		local _uiCombatList = self._uiCombatList
		if(_uiCombatList)then
			_uiCombatList:RefreshList(combatList)
		else
			_uiCombatList = self:GetUIScroll("_uiCombatList")
			_uiCombatList:Create(self.mCombatSuper,combatList,function (...) self:CombatListItem(...) end,UIItemList.SUPER_GRID)
			self._uiCombatList = _uiCombatList
			_uiCombatList:EnableScroll(true,false)
		end
		_uiCombatList:DrawAllItems()
		return
	else				--英雄或道具
		CS.ShowObject(self.mCommScroll,true)
		list = gModelChat:GetChatBtnScreenRefListByType(type)
		if(type == 1)then--英雄
			dataType=list[1].race
		else
			dataType=list[1].itemPage
		end
	end
	CS.ShowObject(self.mTypeScroll,true)
	local _uiTypeList = self._uiTypeList
	if(_uiTypeList)then
		_uiTypeList:RefreshList(list)
	else
		_uiTypeList = self:GetUIScroll("uiTypeList")
		_uiTypeList:Create(self.mTypeScroll,list,function (...) self:SetTypeListItem(...) end)
		self._uiTypeList = _uiTypeList
	end
	if(#list>0)then
		self._oldType = -1
		self:OnClickBtnTypeBtn(type,dataType)
	end
end

function UISayWin:GetChatHeight(msg,addH)
	self:SetWndText(self.mTestText2,msg)
	local height = self.mTestText2_1.preferredHeight + (addH or 0)
	return height
end

--聊天信息设置
function UISayWin:SetInfoListItem(list, item, itemdata, itempos)
	if not itemdata then
		return
	end
	local InstanceID = item:GetInstanceID()
	self._currInfoIndex = itempos
	local _currChannel = self._currChannel
	local infoList = gModelChat:GetTypeInfo(_currChannel)
	if(infoList and #infoList == itempos)then
		gModelChat:DelChannelRed(_currChannel)
		CS.ShowObject(self.mDownBtn,false)
	end
	local meParent,otherParent,systemParent=CS.FindTrans(item,"Me"),CS.FindTrans(item,"Other"),CS.FindTrans(item,"System")
	local parent,head,textTran,infoText,tipsText,chatBg,EmojiImage,tagItemRoot,BattleGroupImg,EmojiSpine
	local msg = ""
	CS.ShowObject(meParent,false)
	CS.ShowObject(otherParent,false)
	CS.ShowObject(systemParent,false)
	local playerTips
	local playerName = itemdata.playerName

	local channelRef = gModelChat:GetChatChannelRefByChannelId(itemdata.channel)
	msg = itemdata:GetMsg()
	if(itemdata.channel==1)then
		local city = gModelChat:GetRoleCityListRefByRefId(itemdata.city)
		playerTips = string.replace(ccClientText(11126),city)
	elseif(channelRef.sortSmall == ModelChat.CHANNEL_SERVE) then
		local sevenName
		if not string.isempty(itemdata.serverName) then
			sevenName = itemdata.serverName
		else
			sevenName = gModelFriend:GetSevenName(itemdata.serverId)
		end
		playerTips = string.replace(ccClientText(11125),sevenName)
	end

	if(itemdata.channel==5)then--系统
		parent=systemParent
		chatBg=CS.FindTrans(parent,"BImage")
		local nameText=CS.FindTrans(parent,"Image/XUIText")
		textTran=CS.FindTrans(parent,"XUIText")
		if(itempos%2==0)then
			CS.ShowObject(chatBg,false)
		else
			CS.ShowObject(chatBg,true)
		end
		local name = gModelChat:GetMailNoticesRefName(tonumber(itemdata.atPlayerId))
		self:SetWndText(nameText,name)
	elseif(itemdata.isMe==true)then--我
		parent=meParent
		infoText=CS.FindTrans(parent,"MeMar/NameText")
		tipsText = CS.FindTrans(parent,"MeMar/SeverText")
		chatBg=CS.FindTrans(parent,"ChatBg")
		textTran=CS.FindTrans(parent,"ChatBg/XUIText")
		head = CS.FindTrans(parent,"HeadIcon")

		if itemdata.channel == ModelChat.CHANNEL_PRIVATE and self._currPritavePlayer then
			if self._currPritavePlayer.playerId == itemdata.atPlayerId and (itemdata.atHead ~=0 and itemdata.atHeadFrame~= 0) then
				self._currPritavePlayer.icon = itemdata.atHead
				self._currPritavePlayer.headFrame = itemdata.atHeadFrame
			end
		end
		self:SetWndClick(head.gameObject,function()
			GF.OpenWnd("UIChaePop",{startType = ModelPlayerSpace.ROLE_HEAD})
		end)
	elseif(itemdata.isMe==false)then--其他人
		parent=otherParent
		infoText=CS.FindTrans(parent,"OtherMar/NameText")
		tipsText = CS.FindTrans(parent,"OtherMar/SeverText")
		chatBg=CS.FindTrans(parent,"ChatBg")
		textTran=CS.FindTrans(parent,"ChatBg/XUIText")
		head = CS.FindTrans(parent,"HeadIcon")

		if itemdata.channel == ModelChat.CHANNEL_PRIVATE and self._currPritavePlayer then
			if self._currPritavePlayer.playerId == itemdata.playerId then
				self._currPritavePlayer.icon = itemdata.head
				self._currPritavePlayer.headFrame = itemdata.headFrame
			end
		end
		self:SetWndClick(head.gameObject,function()
			self:OnClickHead(itemdata)
		end)
		-- 长按
		self:SetWndLongClick(head,function()
			self:OnLongClickHead(itemdata)
		end,0.8,false)
	end
	EmojiImage = CS.FindTrans(parent,"EmojiImage")
	EmojiSpine = CS.FindTrans(parent,"EmojiSpine")
	tagItemRoot = self:FindWndTrans(parent,"TagItemRoot")
	BattleGroupImg = self:FindWndTrans(parent,"BattleGroupImg")
	local isTag = false
	if(infoText)then
		local nameStr,sexStr = "",""
		if itemdata.sex == 1 then
			nameStr = string.replace(ccClientText(11148),playerName)
			--sexStr = "role_zone_ui_man"
		else
			nameStr = string.replace(ccClientText(11147),playerName)
			--sexStr = "role_zone_ui_woman"
		end

		sexStr=gModelPlayer:GetDefaultIcon()
		self:SetWndText(infoText,nameStr)
		self:SetWndText(tipsText,playerTips)
		local mar,rateMar,vipIcon,sex
		if(itemdata.isMe == true)then
			mar = CS.FindTrans(parent,"MeMar")
		else
			mar = CS.FindTrans(parent,"OtherMar")
		end
		rateMar = CS.FindTrans(mar,"RateMar")
		vipIcon = CS.FindTrans(mar,"VipIcon")
		sex = CS.FindTrans(mar,"Sex")

		self:SetWndEasyImage(sex,sexStr)
		CS.ShowObject(sex, false)
		--CS.ShowObject(sex,true and itemdata.playerId ~= "-1")
		CS.ShowObject(rateMar,false)
		CS.ShowObject(vipIcon,false)
		local title = itemdata.title
		if(title and title > 0)then
			local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(title)
			local rateIcon = CS.FindTrans(rateMar,"RateIcon")
			if ref then
				self:SetWndEasyImage(rateIcon,ref.icon,function()
					CS.ShowObject(rateMar,true)
				end ,true)
				self:SetWndClick(rateIcon,function ()
					GF.OpenWnd("UIPerSpreadPop",{StructPersonaliseInfo = {refId = title,playerName = itemdata.playerName}})
				end)
			else
				self:SetWndClick(rateIcon,function ()
				end)
			end
		end
		local tags = itemdata.tag
		if tagItemRoot then
			local chatTagNum = gModelPlayer:GetRoleConfigRefByKey("chatTagNum") or 5
			local chatTagDis = gModelPlayer:GetRoleConfigRefByKey("chatTagDis") or 5
			--local layoutGroup = tagItemRoot:GetComponent(typeHorizontalLayoutGroup)
			--if layoutGroup then
			--	layoutGroup.spacing = chatTagDis
			--end
			for i = 1, 5 do
				local item = self:FindWndTrans(tagItemRoot,"TagItem"..i)
				CS.ShowObject(item,false)
			end
			local chatTagIndex = 0
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
						local tagItem = self:FindWndTrans(tagItemRoot,"TagItem"..i)
						local tagText = self:FindWndTrans(tagItem,"UIText")

						CS.ShowObject(tagItem,true)
						local ref = gModelPlayer:GetRolePlayerHeadRefByRefId(tag)
						if ref then
							self:SetWndEasyImage(tagItem,ref.tagBg)
							self:SetWndText(tagText,LUtil.FormatColorStr(ccLngText(ref.name),"#"..ref.tagColour))
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
			CS.ShowObject(tagItemRoot,isTag)
		end
		if BattleGroupImg then
			local simulationBattleGroupType = itemdata.simulationBattleGroupType or 0
			CS.ShowObject(BattleGroupImg,simulationBattleGroupType > 0)
			if simulationBattleGroupType > 0 then
				self:DestroyWndEffectByKey(InstanceID)
				self:CreateWndEffect(BattleGroupImg,simulationBattleGroupType == 1 and "fx_ui_dianfengzu" or "fx_ui_jingyingzu",InstanceID,100,false,false,nil,nil,nil,nil,nil,nil,2)
			end
			--self:SetWndEasyImage(BattleGroupImg,simulationBattleGroupType == 1 and "chat_txt_3" or "chat_txt_2" )
		end
	end
    local isShowVipTitle = false
    local vipTitle = self:FindWndTrans(parent,"VipTitle")
    if vipTitle then
        CS.ShowObject(vipTitle,false)
        local vip = itemdata.vip
        local vipLvRef = gModelVip:GetRefByVipLv(vip)
        if vipLvRef then
            --local chatTitle = vipLvRef.chat
            --local shieldInfo = string.split(itemdata.shieldInfo,"|")
            --if LxUiHelper.IsImgPathValid(chatTitle) and shieldInfo[2] and shieldInfo[2] == "0" then
            --    CS.ShowObject(vipTitle,true)
            --    self:SetWndEasyImage(vipTitle,chatTitle)
            --    isShowVipTitle = true
            --end
        end
    end

	CS.ShowObject(parent,true)
	head=CS.FindTrans(parent,"HeadIcon")
	if(head)then
		local playerLevel = itemdata.level;
		local playerInfo={
			trans=head,
			icon=itemdata.head,
			headFrame = itemdata.headFrame,
			playerId=itemdata.playerId,
			NoClick=true,
			level = playerLevel,
			noLv= playerLevel == 0,
		}
		local uiheadlist = self._uiheadList
		local baseClass = uiheadlist[InstanceID]
		if not baseClass then
			baseClass = HeadIcon:New(self)
			uiheadlist[InstanceID] = baseClass
		end
		baseClass:SetHeadData(playerInfo)
		baseClass:RefreshUI()
	end
	if(itemdata.type == ModelChat.MSGTYPE_GUILDNOTICE or itemdata.channel ==ModelChat.CHANNEL_SYSTEM or itemdata.type == ModelChat.MSGTYPE_NOTICE)then
		msg = gModelChat:SetChatSkipFun(textTran,InstanceID,itemdata,msg,self._uiHyperList,self:GetWndName())
	end
	msg=self:SetATPlayerName(msg,itemdata.atPlayerName)

	local btnTranslate = self:FindWndTrans(parent,"BtnTranslate")
	local translateLine = self:FindWndTrans(parent,"TranslateLine")
	local isOnlyFace = LUtil.CheckInfoOnlyFace(msg)
	if(itemdata.channel ~= 5)then
		local faceId = LUtil.ChatInfoGetDaFace(msg)
		if(faceId and faceId ~= 0)then
			CS.ShowObject(chatBg,false)

			if btnTranslate and translateLine then
				CS.ShowObject(btnTranslate,false)
				CS.ShowObject(translateLine,false)
			end

			local faceRef = gModelChat:GetChatFaceRefByRefId(faceId)
			if faceRef then
				local isSpine = faceRef.isSpine and faceRef.isSpine == 1
				CS.ShowObject(EmojiSpine,isSpine)
				CS.ShowObject(EmojiImage,not isSpine)
				if isSpine then
					self:DestroyWndSpineByKey(InstanceID)
					self:CreateWndSpine(EmojiSpine,faceRef.faceSpine,InstanceID,false,function(dpSpine)
						dpSpine:SetScale(0.9)
						local dpTrans = dpSpine:GetDisplayTrans()
						dpTrans.anchorMin = Vector2.New(0.5,0.5)
						dpTrans.anchorMax = Vector2.New(0.5,0.5)
						dpTrans.pivot = Vector2.New(0.5,0.5)
					end)
					EmojiSpine.anchoredPosition = Vector2.New(EmojiSpine.anchoredPosition.x,isTag and -62 or -42)
				else
					self:SetWndEasyImage(EmojiImage,faceRef.faceIcon)
					EmojiImage.anchoredPosition = Vector2.New(EmojiImage.anchoredPosition.x,isTag and -62 or -42)
				end
			end
			local higth = isTag and 206 or 186
			LxUiHelper.SetSizeWithCurAnchor(item,1,higth)
			return
		end
		msg= LUtil.GetFaceStr(msg,46)
		CS.ShowObject(EmojiSpine,false)
		CS.ShowObject(EmojiImage,false)
		CS.ShowObject(chatBg,true)
		local isShare,shareInfo = gModelChat:SetShareType(itemdata,msg)
		if isShare then
			msg = gModelChat:OnAddHyper(textTran,InstanceID,shareInfo,self._uiHyperList)
		else
			msg = shareInfo
		end
		local isShowTranslate = false
		local isForeign = gLGameLanguage:IsUSARegion()
		if(not itemdata.isMe and isForeign and self._languageLen > 1)then
			if btnTranslate and translateLine then
				CS.ShowObject(translateLine,false)
				local translate = gModelChat:GetTranslate(itemdata.channel,itemdata.number)
				if (itemdata.type ~= ModelChat.MSGTYPE_NORMAL and itemdata.type ~= ModelChat.MSGTYPE_AT) or faceId > 0 or isOnlyFace then
					CS.ShowObject(btnTranslate,false)
				elseif translate then
					isShowTranslate = true
					CS.ShowObject(btnTranslate,true)
					CS.ShowObject(translateLine,true)
					local height = self:GetChatHeight(msg .. "\n\n")
					local width = self:GetChatWidth(msg,14)
					local lh = isTag and -62 or -42
					translateLine.anchoredPosition = Vector2.New(136,- height + lh + 7)
					translateLine.sizeDelta = Vector2.New(width,2)
					self:SetWndEasyImage(btnTranslate,"chat_btn_translate_2")
					msg = msg .."\n\n" .. LUtil.GetFaceStr(translate,46)
					self:SetWndClick(btnTranslate,function ()
						gModelChat:DelTranslate(itemdata)
					end)
				else
					isShowTranslate = true
					CS.ShowObject(btnTranslate,true)
					self:SetWndEasyImage(btnTranslate,"chat_btn_translate_1")
					self:SetWndClick(btnTranslate,function ()
						gModelChat:SetTranslate(itemdata)
					end)
				end
				local width = self:GetChatWidth(msg) + 124 + 42
				btnTranslate.anchoredPosition = Vector2.New(width,isTag and -82 or -62)
			end
		end
		local bubble = itemdata.bubble
		self:GetChatInfoWidth(msg,chatBg,item,isTag,bubble,isShowVipTitle)

		self:SetChatBubble(chatBg,bubble,itemdata.isMe)

		chatBg.anchoredPosition = Vector2.New(EmojiImage.anchoredPosition.x,isTag and -72 or -52)
	else
		self:GetSysInfoWidth(msg,chatBg,item)
	end

	self:SetWndText(textTran,msg)
end

function UISayWin:ItemListItem(list,item, itemdata, itempos)
	local root = CS.FindTrans(item,"Root")

	local uiCommonList = self._uicommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
	end
	if(itemdata.itemType == 2)then
		baseClass:SetHeroPlayer(itemdata.id)
	elseif(itemdata.itemType == 4)then
		baseClass:SetCommonReward(itemdata.itemType, itemdata.refId, nil)
	elseif(itemdata.itemType == LItemTypeConst.TYPE_OUTFIT)then
		baseClass:SetOutfitId(itemdata.id)
	else
		baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	end
	self:SetWndClick(root, function()
		self:OnClickShare(itemdata)
	end)
	baseClass:DoApply()
end

function UISayWin:GetSysInfoWidth(msg, chatBg,item)
	self:SetWndText(self.mTestText3,msg)
	local height = self.mTestText3_1.preferredHeight
	height= 20 + height

	LxUiHelper.SetSizeWithCurAnchor(chatBg,1,height)
	LxUiHelper.SetSizeWithCurAnchor(item,1,height)
end
function UISayWin:OnClickChildChannel(channelId)
	self._currInfoIndex = nil
	self:ChangeChannel(channelId)
	gModelChat:DelChannelRed(channelId)
	local uiList = self._childChannelUiList
	if uiList then
		uiList:DrawAllItems()
	end
	local _currChannel = self._currChannel
	CS.ShowObject(self.mChildChannelTips,_currChannel ~= ModelChat.CHANNEL_SERVE)
	self:TimerStop(self._childChannelTimeKey)
	if _currChannel == ModelChat.CHANNEL_SERVE then
		return
	end

	self:TimerStart(self._childChannelTimeKey,1,false,-1)
	self:SetChildChannelTipsTime()
end

function UISayWin:OnClickSend()
	if(self._cutIndex==2)then
		GF.ShowMessage(ccClientText(11108))
		return
	end
	self._isLongClisk = false
	local cmd = self.mXUIInputText.text
	local type = ModelChat.MSGTYPE_NORMAL
	self:SendChatMsg(cmd,type)
end

function UISayWin:SetStaticContent()
	self:SetTextTile(self.mBtnFAQ,ccClientText(141))
	--local str =ccClientText(24200) --"打开聊天时，是否默认打开助手页签"
	--self:SetTextTile(self.mHelperTog,str)
	--str = ccClientText(24201) --"(测试版)"
	--self:SetWndText(self.mHelperText,str)

	--str =ccClientText(24214) --"仅加速战斗"
	--self:SetTextTile(self.mOnlyBattleTog,str)
	--str =ccClientText(24217) --"自定义排序"
	--self:SetTextTile(self.mBtnDesign,str)

	local isShowHelpTop = gLGameLanguage:IsKoreaRegion()
	CS.ShowObject(self.mHelpTop, isShowHelpTop)
	if isShowHelpTop then
		self:SetWndText(self.mHelpTopText,ccClientText(155))
		self:InitTextLineWithLanguage(self.mHelpTopText, -30)
	end
end
--选择大表情
function UISayWin:OnClickDaEmojiBtn(faceinstead)
	if self._isLongClickFace then
		return
	end
	local type = ModelChat.MSGTYPE_NORMAL
	self:SendChatMsg(faceinstead,type,true)
end

function UISayWin:GetHistory()
	local list = LWnd.GetHistory(self)
	local wndArgList = list.wndArgList
	wndArgList.channel = self._currChannel
	return list
end
--------------------------------------------------------------------
function UISayWin:OnTimer(key)
	if(self._pointerUpKey == key)then
		self._isLongClickFace = false
	elseif(self._playerOnlineKey == key)then
		local _playerOnlineIds = self._currPlayerOnlineIds
		if #_playerOnlineIds > 0 then
			gModelChat:PlayerOnlineReq(_playerOnlineIds,"1")
		end
	elseif key == self._playCountdown then
		--todo
		self:HelperCountDown()
	elseif key == self._childChannelTimeKey then
		self:SetChildChannelTipsTime()
	end
end
--点击删除好友聊天
function UISayWin:OnClickCloseFriend(playerInfo)
	gModelGeneral:OpenUIOrdinTips({refId = 50006,para = {playerInfo.name},func = function()
		gModelChat:DeletePrivateChat(playerInfo)
		self._currPritavePlayer = nil
		self:RefreshChannel()
	end })
end

function UISayWin:GetChatWidth(msg,addW)
	self:SetWndText(self.mTestText,msg)
	local width = self.mTestText_1.preferredWidth + (addW or 0)
	if(width > 338)then
		width = 338
	end
	return width
end

function UISayWin:PlayerOnlineResp(pb)
	local playerIdList = pb.playerIdList
	local moreInfo = pb.moreInfo
	if moreInfo ~= "1" then
		return
	end
	local isOnline = false
	local _playerOnlineIds = {}
	for i, v in ipairs(playerIdList) do
		_playerOnlineIds[v] = true
		isOnline = true
	end
	self._playerOnlineIds = _playerOnlineIds
	self._uiFriendList:DrawAllItems()
end

-----------------------------------------------------------------
function UISayWin:InitAdaptKeyboard()
	local content = self:FindWndTrans(self:GetWndTrans(), "AniRoot/Pop")
	if not content then return end
	local uiAdaptKeyboard = UIAdaptKeyboard:New()
	self._uiAdaptKeyboard = uiAdaptKeyboard
	uiAdaptKeyboard:Create(self.mXUIInputText, content, Vector3.zero, self.mMovePos,self.mMovePosIos)
end
--------------------------------------------扩展功能---------------------------------------------------------
--类型按钮
function UISayWin:SetTypeListItem(list, item, itemdata, itempos)
	local imageTran=CS.FindTrans(item,"Image")
	local selectTran=CS.FindTrans(item,"SelectImage")
	local text=CS.FindTrans(item,"UIText")
	CS.ShowObject(selectTran,false)
	CS.ShowObject(imageTran,true)
	self:SetWndEasyImage(imageTran,itemdata.icon)
	local dataIndex
	if(itemdata.type==1)then
		dataIndex=itemdata.refId
	elseif(itemdata.type==2)then
		dataIndex=itemdata.race
	else
		dataIndex=itemdata.itemPage
	end
	if(itemdata.type==3)then
		self:SetWndText(text,ccLngText(itemdata.name))
		self:SetWndEasyImage(imageTran,itemdata.icon,nil,false)
	else
		self:SetWndText(text,"")
		self:SetWndEasyImage(imageTran,itemdata.icon)
	end
	imageTran.sizeDelta=Vector2.New(56,56)
	self:SetWndEasyImage(selectTran,itemdata.iconChecked,nil,false)
	self._typeBtnList[dataIndex]=item
	self:SetWndClick(item, function (...) self:OnClickBtnTypeBtn(itemdata.type,dataIndex) end)
end

function UISayWin:OnClickAddFun()--扩展功能
	local isAddFun = self._isAddFun
	local bImg = isAddFun and "chat_btn_jia" or "chat_btn_jian"
	self:SetWndEasyImage(self.mAddBtnImg,bImg)
	CS.ShowObject(self.mAddFun,not isAddFun)
	self._isAddFun = not isAddFun
	if isAddFun then
		return
	end

	local btnList = gModelChat:GetChatBtnRefListByChannle(self._currChannel)
	local _addFuncType = self._addFuncType
	if(_addFuncType)then
		_addFuncType:RefreshList(btnList)
		local uiList = _addFuncType:GetList()
		uiList:SetContentPosition(1,1)
	else
		_addFuncType = self:GetUIScroll("addFinType")
		_addFuncType:Create(self.mAddFuncType,btnList,function (...) self:SetAddFunListItem(...) end)
		self._addFuncType = _addFuncType
		_addFuncType:EnableScroll(true,false)
	end
	if(btnList and #btnList>0)then
		self:OnClickAddFunTypeBtn(btnList[1].type)
	end
end

function UISayWin:ChangeTab(trans,tapState,channelId)--切换标签
	if not trans then
		local ref = gModelChat:GetChatChannelRefByChannelId(channelId)
		if ref and ref.sortSmall > 0 then
			channelId = ref.sortSmall
		end
		trans = self._tabBtnList[channelId]
	end
	local btnTabTrans = CS.FindTrans(trans, "Root/BtnTabIcon")
	local Off = CS.FindTrans(btnTabTrans, "Off")
	local On = CS.FindTrans(btnTabTrans, "On")
	local Gray = CS.FindTrans(btnTabTrans, "Gray")
	--local red = CS.FindTrans(trans,"Root/Red")
	--if(tapState == 0)then
	--	CS.ShowObject(red,false)
	--end
	CS.ShowObject(Off,tapState == 1)
	CS.ShowObject(On, tapState == 0)
	CS.ShowObject(Gray, tapState == -1)
end

function UISayWin:OnClickFAQ()
	gLSdkImpl:CallMethod(LSdkMethod.DoShowAIGMorFAQ,1)
end

function UISayWin:SetFacePreview(itemdata)
	self._isLongClickFace = true
	CS.ShowObject(self.mFaceBubble,true)
	local isSpine = itemdata.isSpine and itemdata.isSpine == 1
	CS.ShowObject(self.mFaceSpine,isSpine)
	CS.ShowObject(self.mFaceIcon,not isSpine)
	if isSpine then
		local faceSpine = self._oldFaceSpine
		local _faceSpine = itemdata.faceSpine
		if faceSpine and faceSpine ~= _faceSpine then
			self:DestroyWndSpineByKey("faceKey")
		end
		self:CreateWndSpine(self.mFaceSpine,_faceSpine,"faceKey",false)
		self._oldFaceSpine = _faceSpine
	else
		self:SetWndEasyImage(self.mFaceIcon,itemdata.faceIcon)
	end
end

function UISayWin:UpdatePrivateRed()
	local list = self._privateRedList
	local curr = self._currPritavePlayer
	for i, v in pairs(list) do
		local num = gModelChat:GetPrivateChannelRed(i)
		local item = v
		if curr and i == curr.playerId and num > 0 then
			gModelChat:DelPrivateRed(i)
		elseif item then
			CS.ShowObject(item,num > 0)
			local text = self:FindWndTrans(item,"XUIText")
			self:SetWndText(text,num)
		end
	end
end

function UISayWin:CombatListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local icon = self:FindWndTrans(root,"Icon")
	local nameText = self:FindWndTrans(root,"NameText")
	local powerText = self:FindWndTrans(root,"PowerBg_1/PowerText")

	self:SetWndEasyImage(icon,itemdata.campIcon)
	self:SetWndText(nameText,ccLngText(itemdata.name))
	local power = gModelPower:GetFormationPower(itemdata.refId)
	local force = LUtil.PowerNumberCoversion(power)
	self:SetWndText(powerText,force)
	self:SetWndClick(root,function ()
		GF.OpenWnd("UISpreadCombatPop",{
			channel = self._currChannel,
			combatType = itemdata.refId,
			atPlayerId = self._currPritavePlayer and self._currPritavePlayer.playerId,
			func = function () self:OnCloseAddFunBg() end
		})
	end)
end

function UISayWin:OnClickDelDown()
	CS.ShowObject(self.mDownBtn,false)
	gModelChat:DelChannelRed(self._currChannel)
end
function UISayWin:ClearAdaptKeyboard()
	if self._uiAdaptKeyboard then
		self._uiAdaptKeyboard:Destroy()
		self._uiAdaptKeyboard = nil
	end
end
--表情按钮
function UISayWin:SetEmojiListItem(list, item, itemdata, itempos)
	local root = CS.FindTrans(item,"Root")
	local imageTran = CS.FindTrans(root,"Image")
	self:SetWndEasyImage(imageTran,itemdata.faceIcon)
	if(itemdata.textType == 1)then
		self:SetWndClick(root, function (...) self:OnClickEmojiBtn(itemdata.faceinstead) end)
		self:SetWndLongClick(root, function () end, 0.7, true, LSoundConst.CLICK_BUTTON_COMMON,function () end)
	elseif(itemdata.textType == 2)then
		self:SetWndClick(root, function (...)
			self:OnClickDaEmojiBtn(itemdata.faceinstead)
		end)
		self:SetWndLongClick(root, function ()
			self:SetFacePreview(itemdata)
		end , 0.7, true, LSoundConst.CLICK_BUTTON_COMMON,function ()
			CS.ShowObject(self.mFaceBubble,false)
			self:TimerStop(self._pointerUpKey)
			self:TimerStart(self._pointerUpKey,0.1,false,1)
		end)
	end
end
--点击分享
function UISayWin:OnClickShare(itemdata)
	local atPlayerId
	local _currChannel = self._currChannel
	if(_currChannel == ModelChat.CHANNEL_PRIVATE)then
		atPlayerId = self._currPritavePlayer.playerId
	end
	if(itemdata.itemType == 1)then
		gModelGeneral:OpenItemInfoTip(itemdata.itemId,nil,nil,nil,nil,true,function()
			local shareMsg = string.format("%s=%s=%s",itemdata.itemType,itemdata.itemId,itemdata.itemNum)
			gModelChat:OnChatShareReq(_currChannel,ModelChat.CHATSHARE_ITEM,shareMsg,atPlayerId)
		end)
	elseif (itemdata.itemType == 3) then
		gModelGeneral:OpenEquipInfoTip(itemdata.itemId, nil, nil, nil, nil, function()
			local shareMsg = string.format("%s=%s=%s", itemdata.itemType, itemdata.itemId, itemdata.itemNum)
			gModelChat:OnChatShareReq(_currChannel, ModelChat.CHATSHARE_ITEM, shareMsg, atPlayerId)
		end)
	elseif(itemdata.itemType == 2)then
		gModelHero:ReqShowHeroTip("",itemdata,true,function()
			gModelChat:OnChatShareReq(_currChannel,ModelChat.CHATSHARE_HERO,itemdata.id,atPlayerId)
		end)
	elseif(itemdata.itemType == 4)then
		local data = {
			runeData = itemdata,
			runeId = itemdata.id,
			share = true,
			shareFunc = function()
				gModelChat:OnChatShareReq(_currChannel,ModelChat.CHATSHARE_RUNE,itemdata.id,atPlayerId)
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
		gModelGeneral:OpenOutfitInfoTip(data,true)
	end
	self:OnCloseAddFunBg()
end
function UISayWin:CloseAir()
	LPlayerPrefs.SetGameAirSetToggle("0")
	FireEvent(EventNames.ON_CHAT_AIR_UPDATE)
	CS.ShowObject(self.mMaskAir,true)
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT,"浮窗功能关闭")
	FireEvent(EventNames.ON_CHAT_AIR_WIN_UPDATE,false)
end

function UISayWin:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId=106})
end

function UISayWin:SetChildChannelTipsTime()
	local _currChannel = self._currChannel
	local _childChannelTimeKey = self._childChannelTimeKey
	local info = gModelChat:GetChildChannelOpenList(_currChannel)
	self:SetWndText(self.mTipsTimeText,ccClientText(11156))
	if not info then
		CS.ShowObject(self.mImportMar,false)
		self:TimerStop(_childChannelTimeKey)
		return
	end
	local openTIme = tonumber(info.openTIme)/1000
	local endTIme = tonumber(info.endTIme)/1000
	local currTime = GetTimestamp()
	local isOpent = openTIme == 0 or (openTIme < currTime and currTime < endTIme)
	if not isOpent then
		self:TimerStop(_childChannelTimeKey)
		CS.ShowObject(self.mImportMar,false)
		return
	end
	if openTIme == 0 then
		CS.ShowObject(self.mChildChannelTips,false)
	else
		CS.ShowObject(self.mChildChannelTips,true)
		local timespan = endTIme - currTime
		local timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(ccClientText(11157),timeStr)
		self:SetWndText(self.mTipsTimeText,timeStr)
	end

	CS.ShowObject(self.mImportMar,true)
end

--私聊好友设置
function UISayWin:SetChatFriendListItem(list,item, itemdata, itempos)
	local root = CS.FindTrans(item,"Root")
	local trans = CS.FindTrans(root,"Image")
	local closeBtn = CS.FindTrans(root,"CloseFriend")
	local nameText = CS.FindTrans(root,"NameText")
	local head = CS.FindTrans(root,"HeadIcon")
	local onCut = CS.FindTrans(root,"OnCut")
	local statusEff = CS.FindTrans(root,"StatusEff")
	local setImage = CS.FindTrans(item,"Root/SelImg")
	local red = CS.FindTrans(item,"red")
	local InstanceID = item:GetInstanceID()
	CS.ShowObject(closeBtn,false)
	CS.ShowObject(nameText,false)
	CS.ShowObject(head,false)
	CS.ShowObject(onCut,false)
	CS.ShowObject(setImage,false)
	CS.ShowObject(statusEff,false)
	CS.ShowObject(red,false)
	if(itemdata.type == 0)then
		self:SetWndClick(trans, function (...) self:OnClickAddFriend() end)

		return
	end
	local playerInfo = itemdata.playerInfo
	if(not playerInfo)then
		return
	end
	local _playerOnlineIds = self._playerOnlineIds or {}
	local _playerId = playerInfo.playerId
	local effName = _playerOnlineIds[_playerId] and "fx_liaotian_zaixianlvdian" or "fx_liaotian_lixianhuidian"
	CS.ShowObject(statusEff,true)
	self:DestroyWndEffectByKey(InstanceID)
	self:CreateWndEffect(statusEff,effName,InstanceID,80)
	--self._playerOnlineTrs[_playerId] = statusEff
	CS.ShowObject(closeBtn,true)
	CS.ShowObject(nameText,true)
	CS.ShowObject(head,true)
	CS.ShowObject(onCut,true)
	playerInfo.trans = head
	playerInfo.noLv = false
	self._privateRedList[_playerId] = red
	local _currPritavePlayer = self._currPritavePlayer
	if _currPritavePlayer then
		if _currPritavePlayer.playerId == _playerId then
			CS.ShowObject(setImage,true)
		end
	end
	self:SetWndClick(onCut, function (...) self:OnClickCutFriend(playerInfo, true) end)
	self:SetWndClick(closeBtn, function (...) self:OnClickCloseFriend(playerInfo) end)
	--好友信息赋值
	self:SetWndText(nameText,playerInfo.name)

	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerInfo)
	baseClass:RefreshUI()
end
---------------------------------------SendMsg--------------------------------------------------------
function UISayWin:SendChatMsg(cmd,type,isNoRestrictLv)
	local _currChannel = self._currChannel
	if not type then
		type = ModelChat.MSGTYPE_NORMAL
	end
	if not isNoRestrictLv then
		local bool = gModelChat:GetIfSend(_currChannel,cmd)
		if(bool == false ) then
			return
		else
			local info= gModelChat:GetChatRestrict(cmd)
			if(info.bool)then
				--self.mXUIInputText.text = info.str
				self:SetWndTextInput(self.mXUIInputText, info.str)
				CS.ShowObject(self.mText_Area,false)
				CS.ShowObject(self.mText_Area,true)
				return
			end
		end
	end

	local playerId,playerName,extraMsg,serverId
	local _currPritavePlayer = self._currPritavePlayer
	if(_currChannel == ModelChat.CHANNEL_PRIVATE and _currPritavePlayer)then
		self._targetInfo={}
		self._targetInfo.playerId = _currPritavePlayer.playerId
		self._targetInfo.playerName = _currPritavePlayer.name
		self._targetInfo.serverId = _currPritavePlayer.serverId
	end
	if(self._targetInfo and self._targetInfo.playerName and  self._targetInfo.playerName~="")then
		local name =string.match(cmd,self._targetInfo.playerName)
		if(_currChannel ~= ModelChat.CHANNEL_PRIVATE and name == self._targetInfo.playerName)then
			type = ModelChat.MSGTYPE_AT
		end
		playerId=self._targetInfo.playerId
		playerName=self._targetInfo.playerName
		serverId=self._targetInfo.serverId
	end
	gModelChat:OnChatMsgReq(_currChannel,type,cmd,playerId,playerName,extraMsg,serverId,isNoRestrictLv)
	--self.mXUIInputText.text=""
	self:SetWndTextInput(self.mXUIInputText,"")
	self.mIfMeSend=true
	self._targetInfo=nil
	self:OnCloseAddFunBg()
	CS.ShowObject(self.mText_Area,false)
	CS.ShowObject(self.mText_Area,true)
	local caret = self:FindWndTrans(self.mText_Area,"Caret")
	local text = self:FindWndTrans(self.mText_Area,"Text")
	caret.anchoredPosition = Vector2.New(0,0)
	text.anchoredPosition = Vector2.New(0,0)
end

function UISayWin:OnCloseWnd()--关闭界面
	local _callFun = self._callFun
	if _callFun ~= nil then
		_callFun()
		self:WndClose()
	else
		self:WndCloseAndBack()
	end

end
--点击添加好友聊天
function UISayWin:OnClickAddFriend()
	GF.OpenWnd("UISayAddPY")
	--GF.ShowMessage(ccClientText(11124))
end

function UISayWin:VersionRefresh()
	CS.ShowObject(self.mBtnFAQ,false)

	self:InitTextLineWithLanguage(self.mTipsTimeText,-40)
	self:InitTextLineWithLanguage(self.mAirText,-40)
end

--长按头像
function UISayWin:OnLongClickHead(itemdata)
	if itemdata.playerId == "-1" or itemdata.playerId == gModelPlayer:GetPlayerId() then
		return
	end
	self._isLongClisk = true
	--self.mXUIInputText.text="@" .. itemdata.playerName.."  "
	self:SetWndTextInput(self.mXUIInputText, "@" .. itemdata.playerName.."  ")
	self._targetInfo=itemdata
end
--选择表情
function UISayWin:OnClickEmojiBtn(faceinstead)
	--self.mXUIInputText.text=self.mXUIInputText.text..faceinstead
	self:SetWndTextInput(self.mXUIInputText, self.mXUIInputText.text..faceinstead)
end
--点击创建加入公会
function UISayWin:OnClickGuild()
	if(not gModelFunctionOpen:CheckIsOpened(12100000,true))then
		return
	end
	gModelFunctionOpen:Jump(12100000,self:GetWndName())
	--GF.OpenWndBottom("UIGdSeekPop")
	self:OnCloseWnd()
end

function UISayWin:ChangeChannel(channelId)
	self._currChannel = channelId										--当前频道
	local ref = gModelChat:GetChatChannelRefByChannelId(channelId)
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT,"切换频道",ccLngText(ref.channel))
	self:RefreshChannel()
end
--点击气泡
function UISayWin:OnClickBubble()
	local gameBubbleSetToggle = LPlayerPrefs.gameBubbleSetToggle or "0"
	local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
	if not sensitive then
		GF.ShowMessage(ccClientText(30800))
		return
	end
	if gameBubbleSetToggle == "1" then
		gModelGeneral:OpenUIOrdinTips({refId = 130005,func = function()
			self:CloseBubble()
			GF.ShowMessage(ccClientText(11152))
		end })
	else
		gModelGeneral:OpenUIOrdinTips({refId = 130004,func = function()
			LPlayerPrefs.SetGameBubbleSetToggle("1")
			FireEvent(EventNames.ON_CHAT_BUBBLE_UPDATE)
			CS.ShowObject(self.mMaskBubble,false)
			gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT,"气泡功能开启")
			GF.ShowMessage(ccClientText(11151))
		end })
	end
end

function UISayWin:SetATPlayerName(msg,name)
	local str = msg
	local text =string.match(msg,"%@"..name)
	if(text)then
		str= string.gsub(str,text,"<u>"..text.."</u>",1)
	end
	return str
end
function UISayWin:ChangeTypeBtn(trans,bool)
	local select = CS.FindTrans(trans,"SelectImage")
	local btnName = CS.FindTrans(trans,"UIText")
	local color
	if bool then
		color = "FFFFFFFF"
	else
		color = "FFFFFFFF"
	end
	CS.ShowObject(select,bool)
	color = LUtil.ColorByHex(color)
	local xuitxt = self:FindWndText(btnName)
	self:SetXUITextColor(xuitxt,color)
end
function UISayWin:ChildChannelListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local icon = self:FindWndTrans(item,"Root/Icon")
	local selImg = self:FindWndTrans(item,"Root/SelImg")
	local nameText = self:FindWndTrans(item,"Root/NameText")
	local redPoint = self:FindWndTrans(item,"Root/RedPoint")
	local numText = self:FindWndTrans(item,"Root/RedPoint/NumText")
	local eff = self:FindWndTrans(item,"Root/Eff")

	local channelId = itemdata.channelId
	local _currChannel = self._currChannel
	local channelRedList = gModelChat:GetChannelRed()
	local redNum = channelRedList[channelId] or 0
	CS.ShowObject(selImg,channelId == _currChannel)
	self:SetWndText(nameText,ccLngText(itemdata.windowName))

	local isOpened = gModelChat:GetChildChannelIsOpened(channelId)
	local isOpent = itemdata.channelType == 1 or isOpened

	local effName = isOpent and "fx_liaotian_zaixianlvdian" or "fx_liaotian_lixianhuidian"
	self:DestroyWndEffectByKey(channelId)
	self:CreateWndEffect(eff,effName,channelId,80,false,false)
	self:SetWndEasyImage(icon,itemdata.windowBtn)
	CS.ShowObject(redPoint,redNum > 0)
	self:SetWndText(numText,redNum)
	self:SetWndClick(root,function ()
		self:OnClickChildChannel(channelId)
	end)
end

function UISayWin:OnCloseAddFunBg()--关闭扩展功能
	self._isAddFun = false
	CS.ShowObject(self.mAddFun,false)
	self:SetWndEasyImage(self.mAddBtnImg,"chat_btn_jia")
end
-----------------------------------------------------------------

function UISayWin:InitEvent()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function (...) self:OnCloseWnd() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnCut, function (...) self:OnClickCutBtn() end)
	self:SetWndClick(self.mVoiceBtn, function (...) self:OnClickVoice() end)
	self:SetWndClick(self.mAddBtn, function (...) self:OnClickAddFun() end)
	self:SetWndClick(self.mSendBtn, function (...) self:OnClickSend() end)
	self:SetWndClick(self.mAddFunBg,function (...)self:OnCloseAddFunBg() end)
	self:SetWndClick(self.mGuildBtn, function (...) self:OnClickGuild() end)
	self:SetWndClick(self.mBtnBubble, function (...) self:OnClickBubble() end)
	self:SetWndClick(self.mBtnAir, function (...) self:OnClickAir() end)
	self:SetWndClick(self.mBtnDelUp,function (...) self:OnClickDelUp() end)
	self:SetWndClick(self.mBtnDelDown,function (...) self:OnClickDelDown() end)
	self:SetWndClick(self.mBtnFAQ,function () self:OnClickFAQ() end)
	self:SetWndClick(self.mBtnHelp, function (...) self:OnClickHelp() end,LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mFriendTips,function () GF.OpenWnd("UIBzTips",{refId = 97}) end)
	--self:SetWndSliderDelegate(self.mSpeedSlider,function (...) self:OnSpeedSliderChange(...)  end)
	--self:SetWndClick(self.mSetSpBtn,function () self:ApplySpeed() end)
	self:SetWndClick(self.mHelpBtn,function() GF.OpenWnd("UIBzTips",{refId = 104}) end)

	--local isSel = tonumber(LPlayerPrefs.gameHelperSel) == 1
	--self:SetWndToggleValue(self.mHelperTog,isSel)
	--self:SetWndToggleDelegate(self.mHelperTog,function (value)
	--	local v = value and 1 or 0
	--	LPlayerPrefs.SetGameHelperSel(v)
	--end)
	--local isOnlyBattle = gModelGameHelper:GetOnlyBattle()
	--self:SetWndToggleValue(self.mOnlyBattleTog,isOnlyBattle)
	--self:SetWndToggleDelegate(self.mOnlyBattleTog,function (value)
	--	gModelGameHelper:SetOnlyBattle(value)
	--end)

	--港澳台屏蔽语音按钮
	if gLGameLanguage:IsHmtRegion() then
		CS.ShowObject(self.mVoiceBtn, false)
		CS.ShowObject(self.mBtnCut, false)
	end

	if PRODUCT_G_VER == 1 then
		--IOS屏蔽
		CS.ShowObject(self.mVoiceBtn, false)
		CS.ShowObject(self.mBtnCut, false)
	elseif PRODUCT_G_VER == 2 then
		if gLGameLanguage:IsHmtRegion() then
			CS.ShowObject(self.mVoiceBtn, false)
			CS.ShowObject(self.mBtnCut, false)
		end
	end


	--self:SetWndClick(self.mBtnDesign,function ()
	--	GF.OpenWnd("UIBzerDesign")
	--end)

	--self:SetWndClick(self.mBtnSimple,function ()
	--	local showMode = LPlayerPrefs.helperShowMode
	--	if showMode == "1" then
	--		showMode = "2"
	--	else
	--		showMode = "1"
	--	end
    --
	--	LPlayerPrefs.SetHelperShowMode(showMode)
    --
	--	self:RefreshHelperList()
	--end)
end

function UISayWin:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ChatMsgPushResp,function (...)
		local _currChannel = self._currChannel
		local ref = gModelChat:GetChatChannelRefByChannelId(_currChannel)
		if not ref then		--有可能是游戏助手的
			return
		end
		local uiList = self._childChannelUiList
		if ref.sortSmall > 0 and uiList then
			uiList:DrawAllItems()
		end
		self:RefreshInfoScroll(_currChannel)--刷新频道信息
		self:RefreshChannlTab()
	end)
	self:WndEventRecv(EventNames.ON_CHAT_RED_CHANGE,function (...)
		self:RefreshChannlTab(true)
		local _currChannel = self._currChannel
		local ref = gModelChat:GetChatChannelRefByChannelId(_currChannel)
		local uiList = self._childChannelUiList
		if ref.sortSmall > 0 and uiList then
			uiList:DrawAllItems()
		end
	end)
	self:WndNetMsgRecv(LProtoIds.PositionChangeResp,function (...)
		self:RefreshTabUiList()
		self:OnClickChannelTab(ModelChat.CHANNEL_PROVINCE)
	end)
	self:WndEventRecv(EventNames.ON_CHAT_TA_CALL,function (...)
		self:OnCallTaOpenInfoPop(...)
	end)
	self:WndEventRecv(EventNames.ON_CHAT_RED_PRIVATE,function (...)
		self:UpdatePrivateRed()
	end)
	self:WndEventRecv(EventNames.ON_CHAT_FRIND_NEW,function (...)
		if(self._currChannel == ModelChat.CHANNEL_PRIVATE)then
			self:RefreshPriverChatFrind()
		end
	end)
	self:WndEventRecv(EventNames.ON_CHAT_SKIP_PRIVATE,function (table)
		self._privatePlayerInfo=table["playerInfo"]
		self:OnClickChannelTab(table["channel"])
	end)

	self:WndEventRecv(EventNames.CHAT_AT_OTHER,function(...)
		self:OnLongClickHead(...)
	end)
	self:WndNetMsgRecv(LProtoIds.PlayerOnlineResp,function (...)
		self:PlayerOnlineResp(...)
	end)

	--self:WndEventRecv(EventNames.ON_GAME_HELPER_REFRESH,function ()
	--	self:RefreshHelperList()
	--end)
    --
	--self:WndEventRecv(EventNames.ON_BATTLE_END,function ()
	--	self:RefreshHelperList()
	--end)

	--self:WndEventRecv(EventNames.ON_ADD_NEW_BATTLE,function ()
	--	self:RefreshHelperList()
	--end)
	self:WndEventRecv(EventNames.ON_CHAT_TRANSLATE_CALL,function (code,index)
		local _currChannel = self._currChannel
		local infoList = gModelChat:GetTypeInfo(_currChannel)
		local _uiList = _currChannel == ModelChat.CHANNEL_PRIVATE and self._uiFriendMsgList or self._uiInfoList
		if _uiList then
			local uiList = _uiList:GetList()
			if index == #infoList then
				uiList:MoveToBottom()
			else
				uiList:DrawAllItems()
			end
		end
	end)
	--激活聊天框不选中所有内容
	self.mXUIInputText.onFocusSelectAll = false
	self:WndEventRecv(EventNames.SENSITIVE_REGULATE,function ()
		local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
		if sensitive then return end
		self:CloseBubble()
		self:CloseAir()
	end)
end

function UISayWin:CloseBubble()
	LPlayerPrefs.SetGameBubbleSetToggle("0")
	FireEvent(EventNames.ON_CHAT_BUBBLE_UPDATE)
	CS.ShowObject(self.mMaskBubble,true)
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT,"气泡功能关闭")
end
------------------------------------------------------------------
return UISayWin