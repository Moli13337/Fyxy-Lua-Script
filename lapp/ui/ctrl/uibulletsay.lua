---
--- Created by Administrator.
--- DateTime: 2023/10/18 19:00:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBulletSay:LWnd
local UIBulletSay = LxWndClass("UIBulletSay", LWnd)
local Tweening = DG.Tweening
local typeRectTransform = typeof(UnityEngine.RectTransform)

UIBulletSay.TYPE_1 = 1
UIBulletSay.TYPE_2 = 2			--春节2022
UIBulletSay.TYPE_3 = 3			--乐队音乐播放
UIBulletSay.TYPE_4 = 4
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBulletSay:UIBulletSay()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBulletSay:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBulletSay:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBulletSay:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	CS.ShowObject(self.mTemplate,false)
	local wndType = self:GetWndArg("wndType") or UIBulletSay.TYPE_1
	if wndType == UIBulletSay.TYPE_2 then
		self.mArea.anchoredPosition = Vector2.New(0,-30)
		self.mArea.sizeDelta = Vector2.New(640,300)
	elseif wndType == UIBulletSay.TYPE_3 then
		self.mArea.anchoredPosition = Vector2.New(0,0)
		self.mArea.sizeDelta = Vector2.New(640,470)
	elseif wndType == UIBulletSay.TYPE_4 then
		self.mArea.anchoredPosition = Vector2.New(0,-290)
		self.mArea.sizeDelta = Vector2.New(640,680)
	end
	self:InitData()
	self:InitMessage()
end


function UIBulletSay:InitData()
	self._msgUpdateTime = 0
	self._lineSpacing  = 33
	self._msgList ={}
	self._maxMsgCnt = 15
	self._duration = gModelChat:GetChatConfigRefByKey("textSpeed")
	self._showSpeed = gModelChat:GetChatConfigRefByKey("textShowSpeed")
	self._showAgainSpeed = gModelChat:GetChatConfigRefByKey("textShowAgainSpeed")
	self._showFirst = gModelChat:GetChatConfigRefByKey("textShowFirst")
	self._interval = self._showSpeed
	self._colCnt = 15
	self._msgCnt = 0
	local _textColor = gModelChat:GetChatConfigRefByKey("textColor")
	self._repeat = gModelChat:GetChatConfigRefByKey("textRepeat")
	self._textColor = string.split(_textColor,",")
	self._textColorSelf = gModelChat:GetChatConfigRefByKey("textColorSelf")
	local rectTran = self.mArea:GetComponent(typeRectTransform)
	if rectTran then
		self._width = rectTran.rect.width
		self._height = rectTran.rect.height
	end
	rectTran = self.mTemplate:GetComponent(typeRectTransform)
	if rectTran then
		self._itemHeight = rectTran.rect.height
	end
	self._timerList = {}
	--self._seqList = {

	self._line ={}
	--self._unusedItemList ={}

	self._playerId = gModelPlayer:GetPlayerId()
	local _channel = self:GetWndArg("channel")
	local _roomId = self:GetWndArg("roomId") or ""
	self._sid = self:GetWndArg("sid")
	self._channel = _channel
	self._roomId = _roomId

	self._objPool = UIObjPool:New()
	self._objPool:Create(self.mUnuse,self.mTemplate)

	if _channel == ModelChat.CHANNEL_RACE then
		self._repeat = 0
	end

	self._barrageFormatStr = self:GetWndArg("barrageFormatStr") --弹幕msg显示文本
	if self._channel~= ModelChat.CHANNEL_RACE then
		self:ShowBarrage()
	end
end

function UIBulletSay:CheckShowNextMsg()
	if not self._waitMsgList then
		return
	end

	if self._msgCnt >= self._maxMsgCnt then
		return
	end

	local lineIndex = self:GetLineIndex()
	if not lineIndex then
		return
	end

	local msg = table.remove(self._waitMsgList,1)
	if not msg then
		return
	end
	self:OnReceiveMsg(msg)
end

function UIBulletSay:OnTimer(key)
	self:TimerStop(key)
	if(key == self._barrageKey)then
		self:OnStartBarrage()
	end
end

function UIBulletSay:OnReceiveChatMsg()
	-- 一秒钟内只可以刷新一次
	if (GetTimestamp() - self._msgUpdateTime < 1.1) then
		return
	end
	self._msgUpdateTime = GetTimestamp()

	local list = self:GetChatMsgList()
	local len = #list
	self._channelInfoList = list
	self._infoLen = len

	---- 当前频道自己发言，才需要马上刷新我的信息
	--if(StructChatMsg.channel ~= self._channel or StructChatMsg.playerId~=gModelPlayer:GetPlayerId())then
	--	return
	--end
	local _infoIndex = self._infoIndex or 1
	if(_infoIndex + 1 < len)then
		self._oldIndex = _infoIndex
	end
	self._infoIndex = _infoIndex
	if(len == 1 or self._interval == self._showAgainSpeed)then
		self:OnStartBarrage()
		self:TimerStart(self._barrageKey,self._interval,false,-1)
	end
end

function UIBulletSay:OnStartBarrage()
	local chatMsg = self._channelInfoList[self._infoIndex]
	if(not chatMsg)then
		return
	end
	self:OnReceiveMsg(chatMsg)
	if(self._oldIndex)then
		self._infoIndex = self._oldIndex
		self._oldIndex = nil
	else
		self._infoIndex = self._infoIndex + 1
		if(self._infoIndex > self._infoLen)then
			if(self._repeat == 0)then
				return
			end
			self._interval = self._showAgainSpeed
			self._infoIndex = 1
		else
			self._interval = self._showSpeed
		end
	end
	self:TimerStart(self._barrageKey,self._interval,false,-1)
end


function UIBulletSay:OnReceiveMsg(StructChatMsg)
	if self._msgCnt >= self._maxMsgCnt then
		return
	end
	local lineIndex = self:GetLineIndex()
	if not lineIndex then
		return
	end

	self._msgCnt =self._msgCnt+1
	local msgdata =
	{
		msg = StructChatMsg,
		lineIndex  = lineIndex,
	}
	self._line[lineIndex] = true

	self:CreateBarrage(msgdata)
end

function UIBulletSay:OnReceiveRaceMsg(StructChatMsg)
	if not self._waitMsgList then
		self._waitMsgList = {}
	end
	table.insert(self._waitMsgList,StructChatMsg)

	self:CheckShowNextMsg()
end

function UIBulletSay:GetChatMsgList()
	local _channel = self._channel
	local _roomId = self._roomId
	local _channelInfoList = gModelChat:GetTypeInfo(_channel)
	local list = {}
	for i, v in ipairs(_channelInfoList) do
		local roomId = v.roomId or ""
		if roomId == _roomId then
			table.insert(list,v)
		end
	end
	--活动弹幕排序
	if(list and #list>0 and self._channel == ModelChat.CHANNEL_FIREWORKS_CASTLE)then
		table.sort(list, function(a,b)
			local aLvl = self:GetMsgLvl(a)
			local bLvl = self:GetMsgLvl(b)
			return aLvl>bLvl
		end)
	end
	return list
end

function UIBulletSay:CreateBarrage(msgdata)

	local itemNew = self._objPool:GetObj() -- table.remove(self._unusedItemList)
	CS.SetParentTrans(itemNew,self.mArea.transform)

	local _height = self._height
	local _colCnt = self._colCnt
	local _itemHeight = _height/_colCnt
	local posY = -(msgdata.lineIndex)* _itemHeight
	itemNew.transform.anchoredPosition = Vector3.New(self._width,posY ,0)

	local textTran = self:FindWndTrans(itemNew.transform,"Image/text")
	local imageTrans = self:FindWndTrans(itemNew.transform,"Image")
	local textImage = self:FindWndImage(imageTrans)

	local chatMsg = msgdata.msg
	local playerId = chatMsg.playerId
	local isSelf = playerId == self._playerId
	if(textImage)then
		textImage.enabled = isSelf
	end
	local _color
	if(isSelf)then
		_color = self._textColorSelf
	else
		local rand = math.random(1,#self._textColor)
		_color = self._textColor[rand]
	end
	local msg = chatMsg:GetMsg()
	msg = LUtil.GetFaceStr(msg,32)
	local ref = gModelChat:GetChatChannelRefByChannelId(self._channel)
	local HeadShow = ref.HeadShow
	local msgs = msg
	if not string.isempty(HeadShow) then
		local arr = string.split(HeadShow,"=")
		if arr[2] == "1" then
			msgs = chatMsg.playerName..": "..msgs
		end
		if arr[1] == "1" then
			local serverName = ccClientText(24719)
			if gModelPlayer:GetServerId() ~= chatMsg.serverId then
				serverName = gLGameLogin:GetServerShotNameById(chatMsg.serverId)
			end
			msgs = (string.format("【%s】",serverName)..msgs)
		end
	end
	local msgStr
	local showActivityMsgTxt = true
	if(self._channel == ModelChat.CHANNEL_FIREWORKS_CASTLE and self._barrageFormatStr)then
		local msgArr = string.split(msgs,"*")
		msgArr = (not msgArr or #msgArr <= 1) and string.split(msgs,"|") or msgArr
		local msgSid = tonumber(msgArr[3])
		msgStr = (self._sid and self._sid == msgSid) and string.replace(self._barrageFormatStr,msgArr[1],msgArr[2]) or ""
		showActivityMsgTxt = not string.isempty(msgStr)
		msgStr = string.replace(ccClientText(17606),_color, msgStr)
	elseif(self._channel == ModelChat.CHANNEL_PUPPET_THEATRE and self._barrageFormatStr)then
		local msgArr = string.split(msgs,"*")
		msgArr = (not msgArr or #msgArr <= 1) and string.split(msgs,"|") or msgArr
		local msgSid = tonumber(msgArr[3])
		msgStr = (self._sid and self._sid == msgSid) and string.replace(self._barrageFormatStr,msgArr[1],msgArr[2]) or ""
		--msgStr = string.replace(self._barrageFormatStr,msgArr[1],msgArr[2])
		showActivityMsgTxt = not string.isempty(msgStr)
		msgStr = string.replace(ccClientText(17606),_color, msgStr)

	else
		msgStr = string.replace(ccClientText(17606),_color, msgs)
	end
	CS.ShowObject(imageTrans,showActivityMsgTxt)
	self:SetWndText(textTran,msgStr)
	CS.ShowObject(itemNew, true)
	local data ={item =itemNew, imageTrans = imageTrans, lineIndex = msgdata.lineIndex}
		self:DelayTween(data)
end

function UIBulletSay:ShowBarrage()
	local showFirst = self._showFirst
	local list = self:GetChatMsgList()
	local len = #list
	self._channelInfoList = list
	self._infoLen = len

	local _infoIndex = 1
	if(len > 1)then
		_infoIndex = math.floor(len * showFirst)
	end
	if(self._channel == ModelChat.CHANNEL_FIREWORKS_CASTLE)then
		self._infoIndex = 1
	elseif(self._channel == ModelChat.CHANNEL_PUPPET_THEATRE)then
		self._infoIndex = 1
	else
		self._infoIndex = _infoIndex
	end
	self._barrageKey = "_barrageKey"
	self:OnStartBarrage()
	self:TimerStop(self._barrageKey)
	self:TimerStart(self._barrageKey,self._interval,false,-1)
end

function UIBulletSay:TweenItem(itemdata)
	local item = itemdata.item
	local imageTrans = itemdata.imageTrans
	local seqCom = self:GetSeqCom()
	local instanceId = item:GetInstanceID()
	local seq = seqCom:CreateSeq(instanceId)
	local length = imageTrans:GetComponent(typeRectTransform).rect.width
	local movX = -(length+ self._width)
	local oldPos = item.transform.anchoredPosition
	local tweener =YXTween.TweenFloat(0,1,self._duration,function (value)
		local pos = movX* value
		item.transform.anchoredPosition =oldPos + Vector3.New(pos,0,0)
	end)
	seq:Append(tweener)
	seq:SetAutoKill(true)
	seq:OnComplete(function()
		seqCom:DeleteSeq(instanceId)
		self._msgCnt = self._msgCnt-1
		self._objPool:ReturnObj(itemdata.item)
		self._line[itemdata.lineIndex] = false

		self:CheckShowNextMsg()
	end)
	seq:SetUpdate(true)
	seq:PlayForward()
end

function UIBulletSay:InitMessage()
	self:WndEventRecv(EventNames.ON_CHAT_WORLD_MSG,function (StructChatMsg)

		if StructChatMsg.channel~= self._channel then
			return
		end

		if self._channel == ModelChat.CHANNEL_RACE then
			self:OnReceiveRaceMsg(StructChatMsg)
		else
			self:OnReceiveChatMsg()
		end

	end)
end



function UIBulletSay:OnDestroy()
	if(self._timerList)then
		for k,v in pairs(self._timerList) do
			LxTimer.DelayTimeStop(v)
		end
	end
	self._timerList = nil

	LWnd.OnDestroy(self)
end

function UIBulletSay:DelayTween(itemdata)

	local timer = nil
	timer = LxTimer.DelayFrameCall(function ()
		self:TweenItem(itemdata)
		LxTimer.DelayTimeStop(timer)
		self._timerList[timer] = nil
	end,1)
	self._timerList[timer] = timer
end

function UIBulletSay:GetLineIndex()
	local canUseIndexs ={}
	for k =1,self._colCnt do
		if not self._line[k] then
			table.insert(canUseIndexs,k)
		end
	end
	if #canUseIndexs<=0 then
		return
	end
	local rand = math.random(1,#canUseIndexs)
	local lineIndex = canUseIndexs[rand]
	return lineIndex
end
function UIBulletSay:GetMsgLvl(msgData)
	local chatMsg = msgData.msg
	local msgArr = string.split(chatMsg,"*")
	msgArr = (not msgArr or #msgArr <= 1) and string.split(chatMsg,"|") or msgArr
	local msgLvl = tonumber(msgArr[4]) or 0
	return msgLvl
end


------------------------------------------------------------------
return UIBulletSay


