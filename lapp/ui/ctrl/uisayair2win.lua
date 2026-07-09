---
--- Created by BY.
--- DateTime: 2023/10/15 21:43:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISayAir2Win:LWnd
local UISayAir2Win = LxWndClass("UISayAir2Win", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISayAir2Win:UISayAir2Win()
	self._uiHyperList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISayAir2Win:OnWndClose()
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT,"浮窗收起")
	self:ClearCommonIconList(self._uiHyperList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISayAir2Win:OnCreate()
	LWnd.OnCreate(self)
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_CHAT,"浮窗展开")
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISayAir2Win:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISayAir2Win:InitEvent()
	self:SetWndClick(self.mImageBg,function () self:OnClickImageBg() end)
end
function UISayAir2Win:MsgListItem(list, item, itemdata, itempos)
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

	self:SetWndClick(playerIcon,function ()self:OnClickImageBg() end)
	self:SetWndClick(image,function ()
		self:OnClickImageBg()
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
				self:OnClickImageBg()
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

function UISayAir2Win:UpdateMsg()
	local list = gModelChat:GetAir2ChannelMsg()
	local msgList = self._msgUiList
	if msgList then
		msgList:RefreshList(list)
		msgList:DrawAllItems()
	else
		msgList = self:GetUIScroll("mMsgSuperAir2")
		msgList:Create(self.mMsgSuper,list,function (...) self:MsgListItem(...) end, UIItemList.SUPER)
		self._msgUiList = msgList
	end
	msgList:MoveToPos(1)
end

function UISayAir2Win:UpdateShow(bool)
	CS.ShowObject(self.mPop,false)
	if not bool then return end
	self:IsOpent()
end
function UISayAir2Win:InitCommand()
	self:IsOpent()
	self:UpdateMsg()
end

function UISayAir2Win:OnClickImageBg()
	GF.OpenWnd("UISayPop")
end
function UISayAir2Win:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ChatMsgPushResp,function (...)
		self:UpdateMsg()
	end)
	self:WndEventRecv(EventNames.ON_CHAT_TA_SHOW,function (...)
		self:UpdateShow(...)
	end)
end
function UISayAir2Win:IsOpent()
	--local isAir = false
	--local chatSetServerList = LPlayerPrefs.chatSetServerList or ""
	--local arr = string.split(chatSetServerList,"|")
	--for i, v in ipairs(arr) do
	--	local as = string.split(v,"=")
	--	if as[1] == "7" and as[2] == "1" then
	--		isAir = true
	--	end
	--end
	local isAir = gModelChat:GetChatSetValue(7)
	CS.ShowObject(self.mPop,isAir)
end

function UISayAir2Win:SetATPlayerName(msg,name)
	local str = msg
	local text =string.match(msg,"%@"..name)
	if(text)then
		str= string.gsub(str,text,"<u>"..text.."</u>",1)
	end
	return str
end
------------------------------------------------------------------
return UISayAir2Win


