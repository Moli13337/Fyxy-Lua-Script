---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISayFlow:LWnd
local UISayFlow = LxWndClass("UISayFlow", LWnd)
local typeof = typeof
local Vector3 = Vector3
local typeofRectTransform = typeof(CS.RectTransform)
local Tweening = DG.Tweening
local EaseOutCubic = Tweening.Ease.OutCubic
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISayFlow:UISayFlow()
	self._bubbleShow = "bubbleShow"
	self._bubbleCool = "bubbleCool"
	self._scaleKey = "_scaleKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISayFlow:OnWndClose()
	if self._delayRefreshTimer then
		LxTimer.DelayTimeStop(self._delayRefreshTimer)
		self._delayRefreshTimer = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISayFlow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISayFlow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()

	self:SetStaticContent()

	if gLGpManager:IsGpInit(LGamePlayType.STORYCOPY) then
		local manager = gLGpManager:FindStoryCopyGp()
		if manager:IsRunning() then
			self:SetWndVisible(false)
		end
	end

end

function UISayFlow:UpdateAirShowCondition(bool)
	--local keyBubbles = {}
	--local list = gModelChat:GetChannelListRef()
	--for i, v in ipairs(list) do
	--	if v.bubble == 1 then
	--		keyBubbles[v.channelId] = true
	--	end
	--end
	--if bool then
	--	local refs = gModelChat:GetAirChannelList()
	--	for i, v in ipairs(refs) do
	--		keyBubbles[v.channelId] = false
	--	end
	--end
	--self._keyBubbles = keyBubbles
end

function UISayFlow:CheckHelpBtnShow()
	if not self._helpBtnOpen then
		local isOpen = gModelFunctionOpen:CheckIsOpened(self._helpBtnFuncId)
		if not isOpen then return end
		self._helpBtnOpen = isOpen
	end
	if gModelGuide and gModelGuide:IsInGuide() then
		return
	end
	local funcId = GameTable.AssistantConfig["helperAccelerateOpen1"]
	local isOpen = gModelFunctionOpen:CheckIsOpened(funcId)
	if not isOpen then
		CS.ShowObject(self.mHelperBtn, false)
		return
	end

	local isJustMain = gLGameUI:IsJustMain()
	if not isJustMain then
		CS.ShowObject(self.mHelperBtn, false)
		return
	end
	CS.ShowObject(self.mHelperBtn, true)
end

function UISayFlow:InitCommand()
	self:InitSizeDelta()
	self:InitDrag()
	self:IsOpent()
	self:UpdateRedShow()
	self:SetWndText(self.mChatText,ccClientText(11132))
	self:InitTextLineWithLanguage(self.mChatText, -30)
	self:SetWndText(self.mChatText1,ccClientText(11132))
	self:InitTextLineWithLanguage(self.mChatText1, -30)
	self:UpdateAirShowCondition(false)

	self:RefreshHelperBtn()
	self:OnClickOpentAir()
	self:CheckHelpBtnShow()
end

function UISayFlow:UpdateRedShow()
	local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
	if not sensitive then
		return
	end
	local channelList = gModelChat:GetChannelRed()
	local redChannelList = {
		["8"] = ModelChat.CHANNEL_SYSTEM,
		["9"] = ModelChat.CHANNEL_PROVINCE,
		["10"] = ModelChat.CHANNEL_SERVE,
		["11"] = ModelChat.CHANNEL_CHILD_29,
		["12"] = ModelChat.CHANNEL_WORLD,
		["13"] = ModelChat.CHANNEL_GUILD,
		["14"] = ModelChat.CHANNEL_PRIVATE,
	}
	local showRedList = {}
	--local chatSetServerList = LPlayerPrefs.chatSetServerList or ""
	--local arr = string.split(chatSetServerList,"|")
	--for i, v in ipairs(arr) do
	--	local as = string.split(v,"=")
	--	local key = as[1]
	--	local channelId =  redChannelList[key]
	--	if channelId and as[2] == "1" then
	--		showRedList[channelId] = true
	--	end
	--end

	for k,v in pairs(redChannelList) do
		showRedList[v] = gModelChat:GetChatSetValue(tonumber(k))
	end

	local redNum = 0
	for i, v in pairs(channelList) do
		if showRedList[i] then
			local bool= gModelChat:GetChatChannelIsOpent(i,1,false)
			if bool then
				redNum = redNum + v
			end
		end
	end
	local bool= gModelChat:GetChatChannelIsOpent(ModelChat.CHANNEL_PRIVATE,1,false)
	if bool then
		local list = gModelChat:GetPrivateChannelList()
		for i, v in pairs(list) do
			redNum = redNum + v
		end
	end

	CS.ShowObject(self.mRedImage,redNum > 0)
	CS.ShowObject(self.mRedImage1,redNum > 0)
	local limit = gModelChat:GetChatConfigRefByKey("chatInfoLimit")
	local numStr = "..."
	if redNum <= limit then
		numStr = redNum
	end
	self:SetWndText(self.mRedXUIText,numStr)
	self:SetWndText(self.mRedXUIText1,numStr)
end

function UISayFlow:SetSystemMsg(id,msg)--系统信息读表
	local ref = gModelChat:GetMailNoticesRefByRefId(tonumber(id))
	if(not ref)then
		return msg
	end
	local text = ccLngText(ref.content)
	if(string.isempty(text))then
		return msg
	end
	text = LUtil.GetReplacedContent(text,msg)
	return text
end

function UISayFlow:InitSizeDelta()
	local width,height
	local bWidth,bHeight
	local btnRect = self.mChatBtn:GetComponent(typeofRectTransform)
	if btnRect then
		bWidth,bHeight = btnRect.sizeDelta.x/2,btnRect.sizeDelta.y/2 + 10
	end
	local rect = self.mScope:GetComponent(typeofRectTransform)
	if rect then
		width,height = rect.rect.width/2,rect.rect.height/2
	end
	self._maxX = (width or 320) - bWidth
	self._maxY = (height or 438) - bHeight
	self._btnX = self.mChatAirBtn.localPosition.x
end

function UISayFlow:SetStaticContent()
	local str =ccClientText(24204)--"助手"
	self:SetTextTile(self.mNormal,str)

	self._waitSwitchKey = "_waitSwitchKey"
	self._waitTimePara=
	{
		key = self._waitSwitchKey,
		interval = 30,
		func = function()
			self:ShowSwitchBtn(true)
		end,
	}
end

function UISayFlow:SaveHelperBtnPos(posY)
	local str = string.format("{%s}",posY)
	LPlayerPrefs.SetHelperBtnPos(str)
end
function UISayFlow:UIDragOnDrag(dragKey,eventData)
	if dragKey == "chatBtn" then
		self:SetDragItemPos(self.mChatBtn,eventData)
	elseif dragKey == "chatAirBtn" then
		--self:SetDragItemPos(self.mChatAirBtn,eventData)
	elseif dragKey == "helperBtn" then
		self:ShowSwitchBtn(false,true)
		self:TimerStop(self._waitSwitchKey)
		self:SetDragItemPos(self.mHelperBtn,eventData)
	end
end
function UISayFlow:OnClickOpentChat()
	local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
	if not sensitive then
		GF.ShowMessage(ccClientText(30800))
		return
	end
	if GF.FindFirstWndByName("UISayPop") then
		GF.CloseWndByName("UISayPop")
		return
	end
	GF.OpenWnd("UISayPop")
	--GF.OpenWnd("UISayWin")
end

function UISayFlow:SetDragItemPos(trans,eventData)
	local camera = eventData.pressEventCamera
	local pos = camera:ScreenToWorldPoint(eventData.position)
	pos = trans.parent:InverseTransformPoint(pos)

	local transPos = trans.localPosition

	local x = Mathf.Clamp(pos.x,-self._maxX,self._maxX)
	local y = Mathf.Clamp(pos.y,-self._maxY,self._maxY)

	trans.localPosition = Vector3.New(x,y,transPos.z)
end

function UISayFlow:UpdateChatBubble(pb)
	local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
	if not sensitive then
		return
	end

	if self._isCD then
		return
	end
	local keyBubbles = self._keyBubbles
	if not keyBubbles then
		return
	end

	local msg = nil
	local msgs = pb.msgs
	for i, v in ipairs(msgs) do
		local chatMsg = gModelChat:GetStructChatMsg(v)
		if keyBubbles[chatMsg.channel] and chatMsg.chatStatus == 0 then
			msg = chatMsg
			break
		end
	end
	if not msg then
		return
	end
	--local isBubble = false
	--local chatSetServerList = LPlayerPrefs.chatSetServerList or ""
	--local arr = string.split(chatSetServerList,"|")
	--for i, v in ipairs(arr) do
	--	local as = string.split(v,"=")
	--	if as[1] == "6" and as[2] == "1" then
	--		isBubble = true
	--	end
	--end

	local isBubble = gModelChat:GetChatSetValue(6)
	if not isBubble then
		return
	end
	local msgStr = msg:GetMsg()
	if(msg.type == ModelChat.MSGTYPE_GUILDNOTICE or msg.channel == ModelChat.CHANNEL_SYSTEM)then
		msgStr = self:SetSystemMsg(msg.atPlayerId,msgStr)
	elseif msg.type == ModelChat.MSGTYPE_NOTICE then
		return
	elseif msg.type == ModelChat.MSGTYPE_SHARE then
		return
	else
		msgStr = LUtil.GetFaceStr(msgStr,24)
	end
	self:SetWndText(self.mBubbleText,msgStr)
	self:SetWndText(self.mBubbleText1,msgStr)

	self._isCD = true
	local bubbleShow = gModelChat:GetChatConfigRefByKey("bubbleShow")
	CS.ShowObject(self.mBubbleBg,true)
	CS.ShowObject(self.mBubbleBg1,true)
	self:TimerStop(self._bubbleShow)
	self:TimerStart(self._bubbleShow,bubbleShow,false,1)
	local func = function()
		local channel = msg.channel or 3
		gModelChat:OnClickOpenChat({ channel = channel, })
		local ref = gModelChat:GetChatChannelRefByChannelId(channel)
		if ref then
			gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT,"切换频道",ccLngText(ref.channel),"由气泡进入",msg.msg)
		end
	end
	self:SetWndClick(self.mBubbleBg,function ()
		if func then func() end
	end)
	self:SetWndClick(self.mBubbleBg1,function ()
		if func then func() end
	end)
	self.mBubbleBg.localScale = Vector2.New(0,1)
	self.mBubbleBg1.localScale = Vector2.New(0,1)
	self:ScaleBubble(0.5)
end

function UISayFlow:OnTimer(key)
	if(self._bubbleShow == key)then
		CS.ShowObject(self.mBubbleBg,false)
		CS.ShowObject(self.mBubbleBg1,false)
		local bubbleShow = gModelChat:GetChatConfigRefByKey("bubbleCool")
		self:TimerStop(self._bubbleCool)
		self:TimerStart(self._bubbleCool,bubbleShow,false,1)
	elseif(self._bubbleCool == key)then
		self._isCD = false
	end
end

function UISayFlow:RefreshHelperBtn()
	local funcId = GameTable.AssistantConfig["helperAccelerateOpen1"]
	self._helpBtnFuncId = funcId
	local isOpen = gModelFunctionOpen:CheckIsOpened(funcId)
	if isOpen then
		self._helpBtnOpen = isOpen
	end
	CS.ShowObject(self.mHelperBtn,isOpen)
	self:CheckHelpBtnShow()

	local pos = string.match(LPlayerPrefs.helperBtnPos,"{(.-)}")
	if pos then
		pos = tonumber(pos)
	end
	pos = pos or 56

	local anchoredPos = self.mHelperBtn.anchoredPosition
	local setPos = Vector2.New(anchoredPos.x,pos)

	self:SetAnchorPos(self.mHelperBtn,setPos)
end

function UISayFlow:OnClickOpentAir()
	--local sensitive = gModelPlayer:GetChatForbid(ModelPlayer.SENSITIVE_TYPE_1)
	--if not sensitive then
	--	GF.CloseWndByName("UISayAir2Win")
	--	return
	--end
	--local isOpenAir = false
	--local _bool = gModelFunctionOpen:CheckIsOpened(11700010,false)
	--if _bool then
	--	local chatSetServerList = LPlayerPrefs.chatSetServerList or ""
	--	local arr = string.split(chatSetServerList,"|")
	--	for i, v in ipairs(arr) do
	--		local as = string.split(v,"=")
	--		if as[1] == "7" then
	--			isOpenAir = as[2] == "1"
	--			break
	--		end
	--	end
	--end
	--if isOpenAir then
	--	GF.OpenWnd("UISayAir2Win")
	--else
	--	GF.CloseWndByName("UISayAir2Win")
	--end
end

function UISayFlow:UpdateShow(bool)
	CS.ShowObject(self.mChatBtn,false)
	CS.ShowObject(self.mChatAirBtn,false)
	if not bool then
		return
	end
	self:IsOpent()
end

function UISayFlow:InitEvent()
	self:SetWndClick(self.mChatBtn, function (...)
		self:OnClickOpentChat()
	end)
	self:SetWndClick(self.mChatAirBtn, function (...)
		self:OnClickOpentChat()
	end)

	self:SetWndClick(self.mHelperBtn,function ()
		self:ShowSwitchBtn(false)
		self:TimerStartImpl(self._waitTimePara)

		GF.OpenWnd("UIGameBzerNew")
	end)
end
function UISayFlow:ShowSwitchBtn(isShow,noAni)
	if noAni then
		CS.ShowObject(self.mTiny,isShow)
		CS.ShowObject(self.mNormal,not isShow)
		self.mTiny.localPosition = Vector3.New(-15,0,0)
		self.mNormal.localPosition = Vector3.zero

		return
	end
	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("helperBtnSwitch")
	if isShow then
		CS.ShowObject(self.mTiny,true)
		local tween = self.mNormal:DOLocalMoveX(-77,0.5)
		seq:Append(tween)
		tween = self.mTiny:DOLocalMoveX(-25,0.3)
		seq:Insert(0.3,tween)
		seq:PlayForward()
	else
		local tween =self.mTiny:DOLocalMoveX(-55.5,0.3)
		seq:Append(tween)
		tween = self.mNormal:DOLocalMoveX(0,0.5)
		seq:Insert(0.2,tween)
		seq:AppendCallback(function ()
			CS.ShowObject(self.mTiny,false)
		end)
		seq:PlayForward()
	end

end

function UISayFlow:ScaleBubble(scaleTime)
	local seqTween
	self:TweenSeqKill(self._scaleKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._scaleKey,function(seq)
			local tweener = self.mBubbleBg:DOScale(Vector3(1,1,1),scaleTime):SetEase(EaseOutCubic)
			seq:Join(tweener)
			local tweener = self.mBubbleBg1:DOScale(Vector3(1,1,1),scaleTime):SetEase(EaseOutCubic)
			seq:Join(tweener)
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._scaleKey)
	end)
end
function UISayFlow:UIDragOnEnd(dragKey,eventData)
	if dragKey == "helperBtn" then
		local trans = self.mHelperBtn
		local camera = eventData.pressEventCamera
		local pos = camera:ScreenToWorldPoint(eventData.position)
		pos = trans.parent:InverseTransformPoint(pos)

		local transPos = trans.localPosition
		local chatPos = self.mChatBtn.localPosition.y
		local x = -self._maxX
		local y = Mathf.Clamp(pos.y,-self._maxY,self._maxY)

		if math.abs(y - chatPos) < 80 then
			y = chatPos + 80
			if y > self._maxY then
				y = chatPos - 80
			end
		end


		trans.localPosition = Vector3.New(x,y,transPos.z)
		self:SaveHelperBtnPos(trans.anchoredPosition.y)


		self:TimerStartImpl(self._waitTimePara)
	end
end

function UISayFlow:InitMessage()
	self:WndNetMsgRecv(LProtoIds.PlayerChangeResp,function (...)
		self:IsOpent(...)
	end)
	self:WndNetMsgRecv(LProtoIds.ChatMsgPushResp,function (...)
		self:UpdateRedShow()
		self:UpdateChatBubble(...)
	end)
	self:WndEventRecv(EventNames.ON_CHAT_CHANNEL_SET,function (...)
		self:UpdateAirShowCondition(true)
	end)
	self:WndEventRecv(EventNames.ON_CHAT_RED_CHANGE,function (...)
		self:UpdateRedShow()
	end)
	self:WndEventRecv(EventNames.ON_CHAT_RED_PRIVATE,function (...)
		self:UpdateRedShow()
	end)
	self:WndEventRecv(EventNames.ON_CHAT_AIR_SHOW,function (...)
		self:UpdateAirShowCondition(...)
	end)
	self:WndEventRecv(EventNames.ON_CHAT_TA_SHOW,function (...)
		self:UpdateShow(...)
	end)
	self:WndEventRecv(EventNames.SET_CHAT_FLOAT_SHOW,function (isShow)
		self:SetWndVisible(isShow)
	end)
	self:WndEventRecv(EventNames.ON_STORY_SHOW_WND,function(key,value)
		self:SetWndVisible(value)
	end)
	self:WndEventRecv(EventNames.ON_GUIDE_START,function ()
		self:SetWndVisible(false)
	end)
	self:WndEventRecv(EventNames.ON_GUIDE_END,function ()
		self:SetWndVisible(true)
	end)
	-- self:WndEventRecv(EventNames.ON_ACTIVITY_CRAZY_LOTTERY_TEN_CALL,function (value)
	-- 	self:SetWndVisible(value)
	-- end)
	self:WndEventRecv(EventNames.SENSITIVE_REGULATE,function ()
		self:OnClickOpentAir()
	end)
	self:WndEventRecv(EventNames.ON_CHAT_SET_CHANGE,function ()
		self:OnClickOpentAir()
	end)
	self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE,function ()
		self:RefreshHelperBtn()
	end)

	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function (index)
		if index ==1 then
			self:ShowSwitchBtn(false,true)
			self:TimerStartImpl(self._waitTimePara)
		end
	end)

	self:WndEventRecv(EventNames.ON_MAIN_CITY_SHOWREFRESH, function(index)
		if self._delayRefreshTimer then return end
		self._delayRefreshTimer = LxTimer.DelayFrameCall(function()
			self._delayRefreshTimer = nil
			self:CheckHelpBtnShow()
		end, 1)
	end)
end

-----------------------------------------------------------------------------------
function UISayFlow:InitDrag()
	self:UIDragSetItem("chatBtn","Scope/ChatBtn",CS.YXUIDrag.DragMode.DragNothing)
	self:UIDragSetItem("chatAirBtn","Scope/ChatAirBtn",CS.YXUIDrag.DragMode.DragNothing)
	self:UIDragSetItem("helperBtn","Scope/helperBtn",CS.YXUIDrag.DragMode.DragNothing)

end

function UISayFlow:IsOpent()
	local _bool = gModelFunctionOpen:CheckIsOpened(11700000,false)
	CS.ShowObject(self.mChatBtn,false)
	CS.ShowObject(self.mChatAirBtn,false)
	if not _bool then return end
	--local isAir = false
	--local chatSetServerList = LPlayerPrefs.chatSetServerList or ""
	--local arr = string.split(chatSetServerList,"|")
	--for i, v in ipairs(arr) do
	--	local as = string.split(v,"=")
	--	if as[1] == "7" then
	--		isAir = as[2] == "1"
	--	end
	--end
	local isAir = gModelChat:GetChatSetValue(7)
	--CS.ShowObject(self.mChatBtn,not isAir)
	CS.ShowObject(self.mChatBtn,false)
	--CS.ShowObject(self.mChatAirBtn,isAir)
end
------------------------------------------------------------------
return UISayFlow


