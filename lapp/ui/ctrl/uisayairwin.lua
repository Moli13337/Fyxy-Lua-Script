---
--- Created by BY.
--- DateTime: 2023/10/10 14:09:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISayAirWin:LWnd
local UISayAirWin = LxWndClass("UISayAirWin", LWnd)
local typeofRectTransform = typeof(CS.RectTransform)
local YXUIPointUtil = CS.YXUIPointUtil
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISayAirWin:UISayAirWin()
	self._uiHyperList = {}
	self._faceTypes = {}
	self._delayTimer = "_delayTimer"
	self._isOpentAir = true
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISayAirWin:OnWndClose()
	self:ClearCommonIconList(self._uiHyperList)
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT,"浮窗收起")
	FireEvent(EventNames.ON_CHAT_AIR_SHOW,false)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISayAirWin:OnCreate()
	LWnd.OnCreate(self)
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT,"浮窗展开")
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISayAirWin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	FireEvent(EventNames.ON_CHAT_AIR_SHOW,true)
end
------------------------------------Hyper--------------------------------
function UISayAirWin:OnTimer(key)
	self:SetPos()
end

function UISayAirWin:OnClickSend()
	local msg = self.mInputSend.text
	local bool = gModelChat:GetIfSend(self._channel,msg)
	if(bool == false ) then
		return
	else
		local info = gModelChat:GetChatRestrict(msg)
		if(info.bool)then
			--self.mInputSend.text = info.str
			self:SetWndTextInput(self.mInputSend, info.str)
			CS.ShowObject(self.mTextArea,false)
			CS.ShowObject(self.mTextArea,true)
			return
		end
	end
	gModelChat:OnChatMsgReq(self._channel,ModelChat.MSGTYPE_NORMAL,msg)
	--self.mInputSend.text=""
	self:SetWndTextInput(self.mInputSend, "")
end

function UISayAirWin:SetATPlayerName(msg,name)
	local str = msg
	local text = string.match(msg,"%@"..name)
	if(text)then
		str= string.gsub(str,text,"<u>"..text.."</u>",1)
	end
	return str
end

function UISayAirWin:MsgListItem(list, item, itemdata, itempos)
	local InstanceID = item:GetInstanceID()
	local image = self:FindWndTrans(item,"Image")
	local msgText = self:FindWndTrans(item,"MsgText")
	local faceImg = self:FindWndTrans(item,"FaceImg")
	local playerIcon = self:FindWndTrans(item,"PlayerImg")

	CS.ShowObject(faceImg,false)
	local ref = gModelChat:GetChatChannelRefByChannelId(itemdata.channel)
	local playerName = itemdata.playerName
	if itemdata.sex == 1 then
		playerName = LUtil.FormatColorStr(playerName,"blue")
	elseif itemdata.sex == 0 then
		playerName = LUtil.FormatColorStr(playerName,"purple")
	end
	local msgPot = string.replace(ccClientText(11150),ccLngText(ref.channel),playerName)
	--local msgPot = ccLngText(ref.channel)..playerName
	local channelStr = "["..ccLngText(ref.channel).."]"
	self:SetWndText(self.mTestText,channelStr)
	local uiText = LxUiHelper.FindXTextCtrl(self.mTestText)
	local posX = uiText.preferredWidth

	self:SetWndText(self.mTestText,msgPot)
	local uiText = LxUiHelper.FindXTextCtrl(self.mTestText)
	local preferredWidth = uiText.preferredWidth + 10
	playerIcon.sizeDelta = Vector2(preferredWidth - posX,20)
	playerIcon.anchoredPosition = Vector2.New(posX,0)

	self:SetWndClick(playerIcon,function () self:OnClickPlayer(itemdata) end)
	self:SetWndClick(image,function ()
		self:OnClickChannelChat()
	end)

	local msg = itemdata:GetMsg()
	if(itemdata.type == ModelChat.MSGTYPE_GUILDNOTICE or itemdata.channel == ModelChat.CHANNEL_SYSTEM or itemdata.type == ModelChat.MSGTYPE_NOTICE)then
		msg = gModelChat:SetChatSkipFun(msgText,InstanceID,itemdata,msg,self._uiHyperList)
	else
		msg = self:SetATPlayerName(msg,itemdata.atPlayerName)
		local faceId = LUtil.ChatInfoGetDaFace(msg)
		if(faceId > 0)then
			self:SetWndText(msgText,msgPot)
			local icon = gModelChat:GetDaEmoji(faceId)
			self:SetWndEasyImage(faceImg,icon)
			faceImg.anchoredPosition = Vector2(preferredWidth,0)
			CS.ShowObject(faceImg,true)
			LxUiHelper.SetSizeWithCurAnchor(item,1,70)
			return
		end
		msg = LUtil.GetFaceStr(msg,18)
		local isShare,shareInfo = gModelChat:SetShareType(itemdata,msg)
		if isShare then
			msg = gModelChat:OnAddHyper(msgText,InstanceID,shareInfo,self._uiHyperList,function ()
				self:OnClickChannelChat()
			end)
		else
			msg = shareInfo
		end
	end
	self:SetWndText(msgText,msgPot.." "..msg)
	local desuiText = LxUiHelper.FindXTextCtrl(msgText)
	local height = desuiText.preferredHeight
	LxUiHelper.SetSizeWithCurAnchor(item,1,height)
end

function UISayAirWin:ListItem(list,item, itemdata, itempos)
	local channelIcon = self:FindWndTrans(item,"Root/ChannelIcon")
	local redText = self:FindWndTrans(item,"Root/ChannelIcon/RedImg/RedText")

	local num = itemdata.num
	local tabBtnArr = string.split(itemdata.ref.tabBtn,",")
	self:SetWndEasyImage(channelIcon,tabBtnArr[1])
	local limit = gModelChat:GetChatConfigRefByKey("chatInfoLimit")
	local numStr = "..."
	if num <= limit then
		numStr = num
	end
	self:SetWndText(redText,numStr)
	self:SetWndClick(channelIcon,function ()
		local ref = itemdata.ref
		self:OnClickChannelChat(ref.channelId)
	end)
end

function UISayAirWin:OnClickPlayer(itemdata)
	gModelGeneral:PlayerShowReq(itemdata.playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end

function UISayAirWin:OnClickFace()
	local channel = self._channel
	if(channel == ModelChat.CHANNEL_GUILD)then--公会
		local bool = gModelGuild:GetBHaveGuild()
		if not bool then
			GF.ShowMessage(ccClientText(11103))
			return
		end
	elseif(channel == ModelChat.CHANNEL_SYSTEM)then--系统
		GF.ShowMessage(ccClientText(11135))
		return
	end

	CS.ShowObject(self.mFaceBg,not self._isOpenFace)
	if self._isOpenFace then
		self._isOpenFace = false
		return
	end
	self._isOpenFace = true
	local list = gModelChat:GetEmojiTypeRef()
	local _uiTypeList = self:GetUIScroll("uiFaceTypeList")
	_uiTypeList:Create(self.mFaceTabScroll,list,function (...) self:FaceTypeListItem(...) end)
	self:OnClickFaceType(list[1].refId)
end

function UISayAirWin:InitEvent()
	self:SetWndClick(self.mBtnSel, function (...) self:OnClickSelChannel() end)
	self:SetWndClick(self.mBtnSend, function (...) self:OnClickSend() end)
	self:SetWndClick(self.mBtnArrowUp, function (...) self:OnClickArrow(true) end)
	self:SetWndClick(self.mBtnArrowDown, function (...) self:OnClickArrow(false) end)
	self:SetWndClick(self.mBtnSet, function (...) GF.OpenWndUp("UISayAirSetPop") end)
	self:SetWndClick(self.mFaceMask, function (...) self:OnClickFace() end)

	self:SetWndClick(self.mBtnFace, function (...) self:OnClickFace() end)
	self:SetWndClick(self.mImageBg,function () self:OnClickChannelChat(self._channel) end)
	self:WndEventRecv(EventNames.ON_CHAT_CHANNEL_SET,function ()
		local channel = LPlayerPrefs.gameAirSetChannel or ""
		local arr = string.split(channel,"|")
		local isUpdate = true
		local currChannel = self._channel
		for i, v in ipairs(arr) do
			if tonumber(v) == currChannel then
				isUpdate = false
			end
		end
		if isUpdate then
			self._channel = tonumber(arr[1])
			self:UpdateChannel()
		end
	end)
	self:SetWndClick(self.mBtnChat,function () self:OnClickChannelChat(ModelChat.CHANNEL_PRIVATE) end)
	self:SetWndClick(self.mBtnClose,function () self:OnClickClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mChannelBg,function () self:OnClickSelChannel() end)
end

function UISayAirWin:FaceTypeListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local selImg = self:FindWndTrans(root,"SelImg")
	local image = self:FindWndTrans(root,"Image")

	local refId = itemdata.refId
	self._faceTypes[refId] = selImg
	self:SetWndEasyImage(image,itemdata.icon)
	self:SetWndEasyImage(selImg,itemdata.iconChecked)
	self:SetWndClick(root,function ()
		self:OnClickFaceType(refId)
	end)
end

function UISayAirWin:UpdateRedShow()
	local channelList = gModelChat:GetChannelRed()
	local slist = gModelChat:GetAirChannelSetList()
	local ref = gModelChat:GetChatChannelRefByChannelId(ModelChat.CHANNEL_PRIVATE)
	table.insert(slist,{ref = ref})
	local redList = {}
	for i, v in ipairs(slist) do
		local bool = v.bool
		if not bool then
			local ref = v.ref
			local channel = ref.channelId
			local redNum = channelList[channel] or 0
			if redNum > 0 then
				local data = v
				data.num = redNum
				table.insert(redList,data)
			end
		end
	end
	if #redList > 1 then
		table.sort(redList,function (a,b)
			local aC = a.ref.channelId
			local bC = b.ref.channelId
			return aC < bC
		end)
	end
	local _redUIList = self._redUiList
	if _redUIList then
		_redUIList:RefreshList(redList)
	else
		_redUIList = self:GetUIScroll("_redUIList")
		_redUIList:Create(self.mRedTipsSuper,redList,function (...) self:ListItem(...) end)
		_redUIList:EnableScroll(false,false)
	end
end

function UISayAirWin:InitSizeDelta()
	local width,height
	local bWidth,bHeight
	local btnRect = self.mPop:GetComponent(typeofRectTransform)
	if btnRect then
		bWidth,bHeight = btnRect.sizeDelta.x/2,btnRect.sizeDelta.y/2 + 10
	end
	local rect = self.mAniRoot:GetComponent(typeofRectTransform)
	if rect then
		width,height = rect.rect.width/2,rect.rect.height/2
	end
	--self._maxX = (width or 320) - bWidth
	self._maxY = (height or 438) - bHeight
end

function UISayAirWin:OnClickClose()
	FireEvent(EventNames.ON_CHAT_AIR_WIN_UPDATE,false)
end

function UISayAirWin:ChannelListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local selImg = self:FindWndTrans(root,"SelImg")
	local text = self:FindWndTrans(root,"Text")

	local _channel = self._channel
	local isSel = _channel == itemdata.channelId
	CS.ShowObject(selImg,isSel)
	local isOpent = gModelChat:CheckIsOpenedStr(itemdata.openId)
	local strColor = (isSel or not isOpent) and "white" or "yellow_2"
	local textStr = LUtil.FormatColorStr(ccLngText(itemdata.channel),strColor)
	self:SetWndText(text,textStr)
	self:InitTextLineWithLanguage(text, -30)
	self:SetWndClick(root,function ()
		if gModelChat:CheckIsOpenedStr(itemdata.openId,true) then
			self:OnClickChannelSel(itemdata.channelId)
		end
	end)
end

function UISayAirWin:OnClickSelChannel()
	local _isOpenSel = self._isOpenSel
	CS.ShowObject(self.mChannelBg,not _isOpenSel)
	if _isOpenSel then
		self._isOpenSel = false
		return
	end
	self._isOpenSel = true

	local list = gModelChat:GetAirChannelList()
	local channelList = self._channelList
	if channelList then
		channelList:RefreshList(list)
	else
		channelList = self:GetUIScroll("ChannelScroll")
		channelList:Create(self.mChannelScroll,list,function (...) self:ChannelListItem(...) end)
		channelList:EnableScroll(true,false)
		self._channelList = channelList
	end
end

function UISayAirWin:InitCommand()
	self:InitSizeDelta()
	self._root = self:GetWndArg("root")
	self:UpdateChannel()
	self:UpdateMsg()
	self:UpdateRedShow()
	self.mInputSend.characterLimit = gModelChat:GetChatConfigRefByKey("chatWordLimit")
	--激活聊天框不选中所有内容
	self.mInputSend.onFocusSelectAll = false
	--local text = CS.FindTrans(self.mInputSend_1,"TextArea/Placeholder")
	--self:SetWndText(text,ccClientText(11139))
	self:SetWndTextInput(self.mInputSend, nil, ccClientText(11139))

	CS.ShowObject(self.mBtnArrowUp,true)
	--self:TimerStart(self._delayTimer,0,false,1)
	local chatAirArrowBool = LPlayerPrefs.chatAirArrowBool or "false"
	self:OnClickArrow(chatAirArrowBool == "true")
end

function UISayAirWin:OnClickFaceType(refId)
	local _faceType = self._faceType
	if _faceType then
		local selImg = self._faceTypes[_faceType]
		CS.ShowObject(selImg,false)
	end
	local selImg = self._faceTypes[refId]
	CS.ShowObject(selImg,true)
	self._faceType = refId

	local ref = gModelChat:GetChatFaceTypeRefByRefId(refId)
	local list = gModelChat:GetEmojiByType(ref.faceType)
	local isDaFace = ref.textType == 2
	for i, v in ipairs(list) do
		v.textType = ref.textType
	end
	if not isDaFace then
		CS.ShowObject(self.mFaceListSuper,true)
		CS.ShowObject(self.mDaFaceListSuper,false)
		local _faceListSuper = self._faceListSuper
		if _faceListSuper then
			_faceListSuper:RefreshList(list)
			_faceListSuper:DrawAllItems()
		else
			_faceListSuper = self:GetUIScroll("mFaceListSuper")
			_faceListSuper:Create(self.mFaceListSuper,list,function (...) self:FaceListItem(...) end,UIItemList.SUPER_GRID)
			self._faceListSuper = _faceListSuper
			_faceListSuper:EnableScroll(true,false)
		end
	else
		CS.ShowObject(self.mFaceListSuper,false)
		CS.ShowObject(self.mDaFaceListSuper,true)
		local _daFaceListSuper = self._daFaceListSuper
		if _daFaceListSuper then
			_daFaceListSuper:RefreshList(list)
			_daFaceListSuper:DrawAllItems()
		else
			_daFaceListSuper = self:GetUIScroll("mDaFaceListSuper")
			_daFaceListSuper:Create(self.mDaFaceListSuper,list,function (...) self:FaceListItem(...) end,UIItemList.SUPER_GRID)
			self._daFaceListSuper = _daFaceListSuper
			_daFaceListSuper:EnableScroll(true,false)
		end
	end
end

--选择表情
function UISayAirWin:OnClickEmojiBtn(faceinstead)
	--self.mInputSend.text = self.mInputSend.text..faceinstead
	self:SetWndTextInput(self.mInputSend, self.mInputSend.text..faceinstead)
end

function UISayAirWin:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ChatMsgPushResp,function (...)
		--local bool = gModelChat:GetIsOpentAir()
		if self._isOpentAir then
			self:UpdateMsg()
			self:UpdateRedShow()
		end
	end)
	self:WndEventRecv(EventNames.ON_CHAT_RED_CHANGE,function (...)
		self:UpdateRedShow()
	end)
end
--选择大表情
function UISayAirWin:OnClickDaEmojiBtn(faceinstead)
	gModelChat:OnChatMsgReq(self._channel,ModelChat.MSGTYPE_NORMAL,faceinstead)
end

function UISayAirWin:OnClickChannelChat(channel)
	local _channel = channel or self._channel
	gModelChat:OnClickOpenChat({channel = _channel,isFromAir = true})
	local ref = gModelChat:GetChatChannelRefByChannelId(_channel)
	if ref then
		gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT,"切换频道",ccLngText(ref.channel),"由浮窗进入")
	end
	--self._isOpentAir = false
	--self:SetWndVisible(false)
end

function UISayAirWin:OnClickChannelSel(channelId)
	local bool = gModelChat:GetChatChannelIsOpent(channelId,1,true)
	if(not bool)then
		return
	end
	self:OnClickSelChannel()
	self._channel = channelId
	self:UpdateChannel()
	self:UpdateMsg()
end

function UISayAirWin:SetPos()
	local follow = self._root
	if not follow then
		return
	end
	local target = self.mPosMar:GetComponent(typeofRectTransform)

	local canvasRect = LGameUI.GetUICanvasRoot()
	local targetPos = YXUIPointUtil.GetScreenPoint(canvasRect,follow)
	local _maxY = self._maxY
	local y = targetPos.y - 100
	if y < - _maxY then
		y = y + 220
	end
	local pos = Vector3.New(-270,y,0)
	target.localPosition = pos
end

function UISayAirWin:OnClickArrow(bool)
	CS.ShowObject(self.mBtnArrowUp,not bool)
	CS.ShowObject(self.mBtnArrowDown,bool)
	local height = bool and 240 or 160
	self.mPop.sizeDelta = Vector2(320,height)

	LPlayerPrefs.SetChatAirArrowBool(bool and "true" or "flase")
	--local list = gModelChat:GetAirChannelMsg()
	local msgList = self._msgUiList
	if(not bool)then
		msgList:MoveToPos()
	end
end

function UISayAirWin:UpdateMsg()
	local list = gModelChat:GetAirChannelMsg()
	local msgList = self._msgUiList
	if(msgList)then
		msgList:RefreshList(list)
	else
		msgList = self:GetUIScroll("MsgSuper")
		msgList:Create(self.mMsgSuper,list,function (...) self:MsgListItem(...) end, UIItemList.SUPER)
		self._msgUiList = msgList
	end
	msgList:DrawAllItems()
	msgList:MoveToPos(1)
end

function UISayAirWin:UpdateChannel()
	local channel = self._channel
	local _channel = LPlayerPrefs.gameAirChannel
	if not channel then
		channel = _channel and tonumber(_channel) or ModelChat.CHANNEL_WORLD
	else
		local toChannel = tostring(channel)
		if _channel ~= toChannel then
			LPlayerPrefs.SetGameAirChannel(toChannel)
		end
	end
	local ref = gModelChat:GetChatChannelRefByChannelId(channel)
	self:SetWndText(self.mTextSel,ccLngText(ref.channel))
	self:InitTextLineWithLanguage(self.mTextSel, -30)
	self.mInputSend.enabled = true
	if(channel == ModelChat.CHANNEL_GUILD)then--公会
		local bool = gModelGuild:GetBHaveGuild()
		self.mInputSend.enabled = bool
	elseif(channel == ModelChat.CHANNEL_SYSTEM)then--系统
		self.mInputSend.enabled = false
	end

	--self:DisableInputText(self.mInputSend)
	self:SetWndClick(self.mInputSend.transform,function()
		if(channel == ModelChat.CHANNEL_GUILD)then--公会
			local bool = gModelGuild:GetBHaveGuild()
			if not bool then
				GF.ShowMessage(ccClientText(11103))
			end
		elseif(channel == ModelChat.CHANNEL_SYSTEM)then--系统
			GF.ShowMessage(ccClientText(11135))
		end
	end)
	self._channel = channel
end

function UISayAirWin:FaceListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local image = CS.FindTrans(root,"Image")
	self:SetWndEasyImage(image,itemdata.faceIcon)
	self:SetWndClick(image, function (...)
		CS.ShowObject(self.mFaceBg,false)
		self._isOpenFace = false
		if(itemdata.textType == 1)then
			self:OnClickEmojiBtn(itemdata.faceinstead)
		elseif(itemdata.textType == 2)then
			self:OnClickDaEmojiBtn(itemdata.faceinstead)
		end
	end)
end
------------------------------------------------------------------
return UISayAirWin


