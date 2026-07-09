---
--- Created by BY.
--- DateTime: 2023/10/19 14:50:54
---
------------------------------------------------------------------
local LWnd = LWnd
local LxUtf8 = LXFW.LxUtf8
---@class UIRepin:LWnd
local UIRepin = LxWndClass("UIRepin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRepin:UIRepin()
	self._reportTrList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRepin:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRepin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRepin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	--self:SetWndText(self.mPlaceholder, ccClientText(17113))
	--self:DisableInputText(self.mExplainInput, nil, ccClientText(17113))
	self:DisableInputText(self.mExplainInput)
	self:DisableSensitiveInputText(self.mExplainInput,ModelPlayer.SENSITIVE_TYPE_5)
end

function UIRepin:SetATPlayerName(msg,name)
	local str = msg
	local text =string.match(msg,"%@"..name)
	if(text)then
		str= string.gsub(str,text,"<u>"..text.."</u>",1)
	end
	return str
end

function UIRepin:OnInput(str)
	local length = LxUtf8.len(str)
	local desNum = gModelChat:GetChatConfigRefByKey("reportDescriptionNum")
	self:SetWndText(self.mExplainLen,length.."/"..desNum)
end

function UIRepin:OnTryTcpReconnect()
	self:WndClose()
end

function UIRepin:RemoveMsgColor(msg)
	msg = LUtil.RemoveAllColorStr(msg)

	local s = "<u color=#(%x+)>"
	msg = string.gsub(msg,s,"<u>")
	return msg
end

function UIRepin:SetChatSkipFun(id,msg) --去除跳转逻辑
	local ref = gModelChat:GetMailNoticesRefByRefId(tonumber(id))
	if(not ref)then
		return msg
	end
	local text = ccLngText(ref.content)
	if(string.isempty(text))then
		return msg
	end
	local jumpList = {}
	if(ref.jump ~= "")then
		jumpList = string.split(ref.jump,";")
	end
	local kList = {}
	local k ="<a (key%d+)>"
	for v in string.gmatch(text,k) do
		table.insert(kList,v)
	end
	local mList={}
	local m ="<a key%d+>([^%<]*)"
	for v in string.gmatch(text,m) do
		table.insert(mList,v)
	end
	local len = #kList
	local uiHyper
	local keyList = {}
	for i = 1,len do
		local key = kList[i]
		local txt = mList[i]
		local value = ""
		local index = keyList[key]
		if(not index)then
			index = 1
		else
			index=index + 1
		end
		keyList[key]=index
		local t="<a "..key..">"..txt.."</a>"
		if(key == "key2")then
			value = jumpList[index]
		else
			local pattern = JSON.decode(msg)
			if(not pattern)then
				return msg
			end
			for k,v in pairs(pattern) do
				if(k==key)then
					local arry =string.split(v,";")
					value = arry[index]
				end
			end
		end
		text= string.gsub(text,t,txt)
	end
	text = LUtil.GetReplacedContent(text,msg)
	return text
end

function UIRepin:SetReportCauseList()
	local list = {}
	local reportReason = gModelChat:GetChatConfigRefByKey("reportReason")
	local reportReasonArr = string.split(reportReason,",")
	for i, v in ipairs(reportReasonArr) do
		local report = string.split(v,"=")
		local data = {
			type = tonumber(report[1]),
			des = ccClientText(tonumber(report[2])),
		}
		table.insert(list,data)
	end
	local uiList = self:GetUIScroll("uiList")
	uiList:Create(self.mCauseScroll,list,function (...) self:ListItem(...) end)
	self:OnClickReport(1)
end

function UIRepin:ChangeReport(trans,bool)
	local check = CS.FindTrans(trans,"Check")
	CS.ShowObject(check,bool)
end

function UIRepin:OnClickReport(type)
	if(self._type)then
		local trans = self._reportTrList[self._type]
		self:ChangeReport(trans,false)
	end
	local trans = self._reportTrList[type]
	self:ChangeReport(trans,true)
	self._type = type
end

function UIRepin:SendMsgChat(explain)
	local _msgData = self._msgData
	if(not _msgData)then
		self:WndClose()
		return
	end
	gModelChat:OnChatReportReq(1,_msgData.msg,_msgData.sendTime,_msgData.channel,_msgData.type,_msgData.playerId,tostring(self._type),explain)
end

function UIRepin:SetProofInfo(msgData,_channelId)
	CS.ShowObject(self.mProofEmoji,false)
	self:SetWndText(self.mProofInfo,"")
	local name = msgData.playerName
	local ref = gModelChat:GetChatChannelRefByChannelId(_channelId)
	if ref.channelType == 2 then
		name = ccClientText(17617)
	end
	self:SetWndText(self.mNameText,name)
	local msg = msgData.msg
	local faceId= LUtil.ChatInfoGetDaFace(msg)
	if(faceId and faceId~=0)then
		local icon = gModelChat:GetDaEmoji(faceId)
		self:SetWndEasyImage(self.mProofEmoji,icon,function ()
			CS.ShowObject(self.mProofEmoji,true)
		end)
	else
		local chatType = msgData.type
		if(chatType == ModelChat.MSGTYPE_GUILDNOTICE or chatType ==ModelChat.CHANNEL_SYSTEM)then
			msg=self:SetChatSkipFun(msgData.atPlayerId,msg)
		end
		msg = self:SetATPlayerName(msg,msgData.atPlayerName)
		msg = LUtil.GetFaceStr(msg,46)
		local isShare,shareInfo = gModelChat:SetShareType(msgData,msg)
		if isShare then
			msg = self:OnAddHyper(shareInfo)
		else
			msg = shareInfo
		end
		msg = self:RemoveMsgColor(msg)
		self:SetWndText(self.mProofInfo,msg)
	end
end

function UIRepin:ListItem(list,item, itemdata, itempos)
	self._reportTrList[itemdata.type] = item
	local text = CS.FindTrans(item,"UIText")
	self:SetWndText(text,itemdata.des)
	self:InitTextLineWithLanguage(text, -20)
	self:SetWndClick(item, function(...) self:OnClickReport(itemdata.type) end)
end

function UIRepin:OnClickHelf()
	local reportNum = gModelChat:GetChatConfigRefByKey("reportNum")
	GF.OpenWnd("UIBzTips",{refId=51,para ={reportNum}})
end

function UIRepin:SendMsgDailyLuck(explain)
	local channelId = self:GetWndArg("channelId") or 100
	local playerInfo  = self:GetWndArg("playerInfo")
	local sendTime = self:GetWndArg("sendTime")
	local text = self:GetWndArg("text")

	gModelChat:OnChatReportReq(1,text,sendTime,channelId,nil,playerInfo._playerId,tostring(self._type),explain)
end

function UIRepin:SetMsgDailyLuck()
	local playerInfo  = self:GetWndArg("playerInfo")
	local text = self:GetWndArg("text")

	self:SetWndText(self.mNameText,playerInfo._name)
	local _msg = LUtil.FilterEmoji(text,"?")
	_msg = LWordMaskUtil.ClearShieldWord(_msg,false,nil,true)
	_msg = LUtil.ChatInfoFaceBinToDec(_msg)
	local msg = LUtil.GetFaceStr(_msg,46)
	self:SetWndText(self.mProofInfo,msg)
end

function UIRepin:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(17100))
	self:SetWndText(self.mReportText,ccClientText(17101))
	self:SetWndText(self.mProofText,ccClientText(17102))
	self:SetWndText(self.mExplainText,ccClientText(17103))
	self:SetWndText(self.mCauseText,ccClientText(17105))
	local text =CS.FindTrans(self.mSubBtn,"XUIText")
	self:SetWndText(text,ccClientText(17107))
	local desNum = gModelChat:GetChatConfigRefByKey("reportDescriptionNum")
	self.mExplainInput.characterLimit = desNum
	self:SetWndTextInput(self.mExplainInput, "")
	self:SetWndText(self.mExplainLen,"0/"..desNum)

	local _getSetMsgFunc = {
		[ModelChat.REPORT_TYPE_CHAT] = function() self:SetMsgChat() end, ----聊天
		[ModelChat.REPORT_TYPE_SPACE] = function() self:SetMsgDailyLuck() end, ----空间留言
	}
	self._getSendMsgFunc = {
		[ModelChat.REPORT_TYPE_CHAT] = function(explain) self:SendMsgChat(explain) end, ----聊天
		[ModelChat.REPORT_TYPE_SPACE] = function(explain) self:SendMsgDailyLuck(explain) end, ----空间留言
	}

	self:SetReportCauseList()
	gModelChat:OnChatReportReq(0)

	local _reportType = self:GetWndArg("reportType") or ModelChat.REPORT_TYPE_CHAT
	self._reportType = _reportType
	local func = _getSetMsgFunc[_reportType]
	if func then
		func()
	end
end

function UIRepin:OnAddHyper(data)--设置分享名字
	if(not data.item)then
		return data.msg
	end

	local msg = data.msg
	local name = gModelChat:GetAddHyperShareNameColor(data)
	msg = string.replace(msg,name)
	return msg
end

----------------------------------------------聊天-----------------------------------------------------
function UIRepin:SetMsgChat()
	local channelId = self:GetWndArg("channelId")
	local channelIndex = self:GetWndArg("channelIndex")
	local playerInfo  = self:GetWndArg("playerInfo")
	local pritavePlayer
	if playerInfo then
		pritavePlayer = {playerId = playerInfo._playerId}
	end
	local infoList= gModelChat:GetTypeInfo(channelId, pritavePlayer)
	local msgData
	for i, v in pairs(infoList) do
		if(v.number == channelIndex)then
			msgData = v
		end
	end
	if(not msgData)then
		return
	end
	self._msgData = msgData
	self:SetProofInfo(msgData,channelId)
end
----------------------------------------------聊天-----------------------------------------------------
function UIRepin:RefreshData()
	self._reportCount = gModelChat:GetReportCount()
	local reportNum = gModelChat:GetChatConfigRefByKey("reportNum")
	self:SetWndText(self.mNumText,string.replace(ccClientText(17106),reportNum - self._reportCount))
end

function UIRepin:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ChatReportResp,function (pb)
		local opsType = pb.opsType
		if(opsType==1)then
			self:WndClose()
			return
		end
		self:RefreshData()
	end)
	self.mExplainInput.onValueChanged:AddListener(function (str)
		self:OnInput(str)
	end)
end

function UIRepin:OnClickSub()
	local reportNum = gModelChat:GetChatConfigRefByKey("reportNum")
	if(self._reportCount >= reportNum )then
		GF.ShowMessage(ccClientText(17111))
		return
	end
	local explain=self.mExplainInput.text
	if(explain == "")then
		GF.ShowMessage(ccClientText(17109))
		return
	end
	local length = LxUtf8.len(explain)
	local desNum = gModelChat:GetChatConfigRefByKey("reportDescriptionNum")
	local xzLen = desNum
	if(length > xzLen)then
		GF.ShowMessage(string.replace(ccClientText(17110),xzLen))
		return
	end

	local _reportType = self._reportType
	local func = self._getSendMsgFunc[_reportType]
	if func then
		func(explain)
	end
end

function UIRepin:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mSubBtn, function(...) self:OnClickSub() end)
	self:SetWndClick(self.mHelfBtn, function(...) self:OnClickHelf() end)
end
------------------------------------------------------------------
return UIRepin


