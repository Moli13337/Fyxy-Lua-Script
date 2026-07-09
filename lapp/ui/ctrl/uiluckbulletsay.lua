---
--- Created by BY.
--- DateTime: 2023/10/24 10:39:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UILuckBulletSay:LWnd
local UILuckBulletSay = LxWndClass("UILuckBulletSay", LWnd)

local Tweening = DG.Tweening
local typeRectTransform = typeof(UnityEngine.RectTransform)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UILuckBulletSay:UILuckBulletSay()
	self._msgList = {}
	self._effTrList = {}
	self._seqIdList = {}
	--self._likeCountList = {}
	self._seqTimeKey = "UILuckBulletSay_seqTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UILuckBulletSay:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UILuckBulletSay:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UILuckBulletSay:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitMessage()
end

function UILuckBulletSay:InitMessage()
	self:WndNetMsgRecv(LProtoIds.SpaceLuckMessageListResp,function (pb)
		local messages = pb.messages
		local page = pb.page
		local _msgList = self._msgList or {}
		if page == 1 then
			_msgList = {}
		end
		for i, v in ipairs(messages) do
			local msg = gModelOneNight:GenerateStructSpaceVisitInfoFromPb(v)
			table.insert(_msgList,msg)
		end
		self._msgList = _msgList
		self:UpdateBarrage(_msgList)
	end)
	self:WndNetMsgRecv(LProtoIds.SpaceLuckMessageResp,function (pb)
		local messages = pb.messages
		local msg = gModelOneNight:GenerateStructSpaceVisitInfoFromPb(messages)
		table.insert(self._msgList,msg)
		self:UpdateBarrage(self._msgList)
	end)
	self:WndNetMsgRecv(LProtoIds.SpaceLuckMessageLikeResp,function (pb)
		self:OnSpaceLuckMessageLikeResp(pb)
	end)
end

function UILuckBulletSay:OnDestroy()
	if(self._timerList)then
		for k,v in pairs(self._timerList) do
			LxTimer.DelayTimeStop(v)
		end
	end
	self._timerList = nil
	--if(self._seqList)then
	--	for k,v in pairs(self._seqList) do
	--		v:Kill(false)
	--	end
	--end
	--self._seqList= nil
	LWnd.OnDestroy(self)
end

function UILuckBulletSay:DelayTween(itemdata)
	local timer = nil
	timer = LxTimer.DelayFrameCall(function ()
		self:TweenItem(itemdata)
		LxTimer.DelayTimeStop(timer)
		self._timerList[timer] = nil
	end,1)
	self._timerList[timer] = timer
end

function UILuckBulletSay:OnSatrtBarrage()
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

function UILuckBulletSay:OnSpaceLuckMessageLikeResp(pb)
	local messages = pb.messages
	local msg = gModelOneNight:GenerateStructSpaceVisitInfoFromPb(messages)
	local _msgList = self._msgList or {}

	for i, v in ipairs(_msgList) do
		if msg.id == v.id then
			v.likeCount = msg.likeCount
			v.like = msg.like
			break
		end
	end

	local seqCom = self:GetSeqCom()
	local seq = seqCom:FindSeq(msg.id) --self._seqList[msg.id]
	if seq then
		seq:Pause()
		table.insert(self._seqIdList,msg.id)
		if not self:IsTimerExist(self._seqTimeKey) then
			self:TimerStart(self._seqTimeKey,1,false,1)
		end
	end

	self._msgList = _msgList
	self:UpdateBarrage(_msgList,true)
	local itemTran = self._effTrList[msg.id]

	if not CS.IsValidObject(itemTran) then
		return
	end

	local Image = self:FindWndTrans(itemTran,"Image")
	local ImageText = self:FindWndTrans(Image,"Text")
	local TextEff = self:FindWndTrans(ImageText,"Eff")
	local TextNoLikeIcon = self:FindWndTrans(ImageText,"NoLikeIcon")
	local NoLikeIconLikeText = self:FindWndTrans(TextNoLikeIcon,"LikeText")

	local likeCount = msg.likeCount
	self:CreateWndEffect(TextEff,"fx_ui_dianzan","like_eff"..msg.id,100)
	CS.ShowObject(TextNoLikeIcon,true)
	self:SetWndText(NoLikeIconLikeText,likeCount)

end

function UILuckBulletSay:InitData()
	CS.ShowObject(self.mTemplate,false)

	self._duration = gModelChat:GetChatConfigRefByKey("textSpeed")					--弹幕：文本滚动速度，数值越大速度越快
	local _showSpeed = gModelChat:GetChatConfigRefByKey("divineTextIntervalSpeed") or 1			--弹幕：弹幕播放间隔速度：单位秒
	self._showAgainSpeed = gModelChat:GetChatConfigRefByKey("divineTextLoopSpeed") or 1	--弹幕：弹幕循环播放间隔：单位秒
	local _showFirst = gModelChat:GetChatConfigRefByKey("textShowFirst")			--弹幕：初始播放时，从第max=（1，rounddown（总数量 x n））开始播放
	local _textColor = gModelChat:GetChatConfigRefByKey("divineTextColor") or "ffffff"				--弹幕：文本颜色，多个用,隔开

	self._textColor = string.split(_textColor,",")
	self._repeat = gModelChat:GetChatConfigRefByKey("textRepeat")					--弹幕：循环播放开关，1=开，0=关
	self._textColorSelf = gModelChat:GetChatConfigRefByKey("divineTextColorSelf") or "ffffff"			--弹幕：我的文本颜色

	self._plyaerId = gModelPlayer:GetPlayerId()
	local _msgList = self:GetWndArg("msgList")

	local rectTran = self.mArea:GetComponent(typeRectTransform)
	if rectTran then
		self._width = rectTran.rect.width
		self._height = rectTran.rect.height
	end
	rectTran = self.mTemplate:GetComponent(typeRectTransform)
	if rectTran then
		self._itemHeight = rectTran.rect.height
	end

	self._showSpeed = _showSpeed
	self._interval = _showSpeed
	self._colCnt = 15
	self._msgCnt = 0
	self._maxMsgCnt = 15
	self._timerList = {}
	--self._seqList = {}
	self._record = {}
	self._line ={}
	self._unusedItemList ={}

	local len = #_msgList
	self._msgList = _msgList
	self._channelInfoList = _msgList
	self._infoLen = len

	local _infoIndex = 1
	if(len > 1)then
		_infoIndex = math.floor(len * _showFirst)
	end
	self._infoIndex = _infoIndex
	self._barrageKey = "_barrageKey"
	self:OnSatrtBarrage()
	self:TimerStop(self._barrageKey)
	self:TimerStart(self._barrageKey,self._interval,false,-1)
end

function UILuckBulletSay:OnTimer(key)
	self:TimerStop(key)
	if(key == self._barrageKey)then
		self:OnSatrtBarrage()
	elseif self._seqTimeKey == key then
		local seqCom = self:GetSeqCom()
		for i, v in ipairs(self._seqIdList) do
			local seq = seqCom:FindSeq(v)
			if seq then
				seq:Play()
			end
		end
	end
end

function UILuckBulletSay:ReturnToPool(item)
	CS.ShowObject(item,false)
	table.insert(self._unusedItemList, item)
end

function UILuckBulletSay:OnReceiveMsg(StructChatMsg)
	if self._msgCnt >= self._maxMsgCnt then
		return
	end

	local key = StructChatMsg.id
	if self._record[key] then
		return
	end

	self._record[key] = true

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

	self._msgCnt =self._msgCnt+1
	local msgdata =
	{
		msg = StructChatMsg,
		lineIndex  = lineIndex,
	}
	self._line[lineIndex] = true

	self:CreateBarrage(msgdata)
end

function UILuckBulletSay:OnTweenComplete(itemdata)
	--self._seqList[itemdata.key] = nil

	local seqCom = self:GetSeqCom()
	seqCom:DeleteSeq(itemdata.key)

	self._msgCnt = self._msgCnt-1
	self:ReturnToPool(itemdata.item)
	self._line[itemdata.lineIndex] = false

	self._effTrList[itemdata.key] = nil

	self._record[itemdata.key] = nil


	self:DestroyWndEffectByKey("like_eff"..itemdata.key)
end

function UILuckBulletSay:UpdateBarrage(_msgList,isNo)
	local len = #_msgList
	self._channelInfoList = _msgList
	self._infoLen = len
	if isNo then
		return
	end
	local _infoIndex = self._infoIndex or 1
	if(_infoIndex + 1 < len)then
		self._oldIndex = _infoIndex
	end
	self._infoIndex = _infoIndex
	if(len == 1 or self._interval == self._showAgainSpeed)then
		self:OnSatrtBarrage()
		self:TimerStart(self._barrageKey,self._interval,false,-1)
	end
end

function UILuckBulletSay:TweenItem(itemdata)
	local item = itemdata.item
	local imageTrans = itemdata.imageTrans
	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq(itemdata.key)
	--self._seqList[itemdata.key] = seq
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
		self:OnTweenComplete(itemdata)
	end)
	seq:SetUpdate(true)
	seq:PlayForward()
end

function UILuckBulletSay:CreateBarrage(msgdata)
	local itemTemp = self.mTemplate
	local itemRoot = self.mArea
	local itemNew = table.remove(self._unusedItemList)
	if not itemNew then
		itemNew = LxResUtil.NewObject(itemTemp.gameObject)
		itemNew.transform:SetParent(itemRoot.transform, false)
	end
	local _height = self._height
	local _colCnt = self._colCnt
	local _itemHeight = _height/_colCnt
	local posY = -(msgdata.lineIndex)* _itemHeight
	itemNew.transform.anchoredPosition = Vector3.New(self._width,posY ,0)

	local textTran = self:FindWndTrans(itemNew.transform,"Image/Text")
	local imageTrans = self:FindWndTrans(itemNew.transform,"Image")
	local effTran = self:FindWndTrans(itemNew.transform,"Image/Text/Eff")
	local likeIcon = self:FindWndTrans(itemNew.transform,"Image/Text/NoLikeIcon")
	local likeText = self:FindWndTrans(itemNew.transform,"Image/Text/NoLikeIcon/LikeText")

	local chatMsg = msgdata.msg
	local playerId = chatMsg.info._playerId
	local isSelf = playerId == self._plyaerId
	--if(imageTrans)then
	--	self:SetWndImageColor(imageTrans,Color.New(1,1,1,isSelf and 1 or 0))
	--end
	local _color
	if(isSelf)then
		_color = self._textColorSelf
	else
		local _textColors = self._textColor
		local rand = math.random(1,#_textColors)
		_color = _textColors[rand]
	end
	local msg = chatMsg.text
	msg = LUtil.ChatInfoFaceBinToDec(msg)
	msg = LUtil.GetFaceStr(msg,32)
	local msgs = msg
	local msgStr = LUtil.FormatColorStr(msgs, "#".._color) --string.replace(ccClientText(17606),_color,msgs)
	self:SetWndText(textTran,msgStr)

	CS.ShowObject(itemNew, true)
	local data ={item =itemNew, imageTrans = imageTrans, lineIndex = msgdata.lineIndex,key = chatMsg.id}
	self:DelayTween(data)
	CS.ShowObject(likeIcon,true)
	local likeCount = chatMsg.likeCount
	self:SetWndText(likeText,likeCount)

	self._effTrList[chatMsg.id] = itemNew.transform


	self:SetWndClick(imageTrans,function ()
		if chatMsg.like == 1 then
			GF.ShowMessage(ccClientText(23106))
		else

			gModelOneNight:SpaceLuckMessageLikeReq(chatMsg.id)
		end
	end)
end
------------------------------------------------------------------
return UILuckBulletSay


