---
--- Created by BY.
--- DateTime: 2023/10/6 14:25:52
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEvent4:LWnd
local UIHopeEvent4 = LxWndClass("UIHopeEvent4", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEvent4:UIHopeEvent4()
	self._gotoBattleKey = "_gotoBattleKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEvent4:OnWndClose()
	if self._isAutoBattle then
		self:OpenEvent1Wnd()
	end
	if self._sendMsg then
		--gModelDreamTrip:OnDreamTripRobberInfoReq()
		gModelCommonDreamTrip:OnDreamTripRobberInfoProcessor(self:GetExtraData())
	end
	--FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEvent4:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEvent4:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self:RefreshView()

	if self._isAutoBattle then
		self:StarTime()
	end
end

function UIHopeEvent4:OnClickConfirm()
	if self._sendMsg then return end
	local eventId = self._eventId
	if not eventId then return end
	local index = self._index
	if index and eventId then
		--local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(eventId,index)
		local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(eventId,index,self:GetExtraData())
		if eventData then
			local eventRefId = eventData.eventRefId
			local eventType = gModelDreamTrip:GetDreamTripEventTypeByRefId(eventRefId)
			if eventType == ModelDreamTrip.EVENT_TYPE_DBZ then
				self:WndClose()
				self._isAutoBattle = false
				return
			end
		end
	end
	self._sendMsg = true
	if self._isAutoBattle then
		self:OpenEvent1Wnd()
		self:WndClose()
	elseif self._isDBZEvent then
		self:WndClose()
	else
		--gModelDreamTrip:OnDreamTripStartEventReq(self._eventId)

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:OnDreamTripStartEventProcessor(eventId,{
			mapType = extraData.mapType,
			sid = extraData.sid,
			argList = {},
		})

	end
	self._isAutoBattle = false
end

function UIHopeEvent4:OnTimer(key)
	if key == self._gotoBattleKey then
		self:CountDownTime()
	end
end

function UIHopeEvent4:OpenEvent1Wnd()
	gModelDreamTrip:OpenDreamTripEvent1Wnd({eventId = self._eventId,index = self._index,extraData = self:GetExtraData()})
end

function UIHopeEvent4:OnDreamTripStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end
	local isBX = false
	local eventId,index,eventRefId
	local endInfo = pb.endInfo
	local sendTxt
	if endInfo then
		endInfo = gModelDreamTrip:GetEventInfoServerDataByPb(endInfo)
		eventRefId = endInfo.eventRefId
		local eventType = gModelDreamTrip:GetDreamTripEventTypeByRefId(eventRefId)
		if eventType == ModelDreamTrip.EVENT_TYPE_GW and eventRefId == 1111 then
			sendTxt = ccClientText(20452)
		elseif eventType == ModelDreamTrip.EVENT_TYPE_ZD then
			sendTxt = ccClientText(20453)
		else
			local name = gModelDreamTrip:GetDreamTripNameByRefId(eventRefId)
			sendTxt = string.replace(ccClientText(20454),name)
		end
		isBX = eventType == ModelDreamTrip.EVENT_TYPE_BX and endInfo.state ~= StructDreamTripGrid.FINISH
		eventId,index = endInfo.eventId,endInfo.index
	end
	self:WndClose()
	local state = pb.state
	if state ~= StructDreamTripGrid.FINISH then
		local clickEvent = isBX
		if clickEvent then
			gModelDreamTrip:ClickEvent(eventRefId,eventId,index)
		end
	end
	if sendTxt and self._isCSM then
		GF.ShowMessage(sendTxt)
	end
end

function UIHopeEvent4:StarTime()
	CS.ShowObject(self.mTimeText,true)
	self._time = 3
	self:TimerStop(self._gotoBattleKey)
	self:TimerStart(self._gotoBattleKey,1,false,-1)
end

function UIHopeEvent4:RefreshView()
	local index = self._index
	local eventId = self._eventId
	--local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(eventId,index)
	local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(eventId,index,self:GetExtraData())
	if not eventData then return end
	local eventRefId = eventData.eventRefId
	local eventType = gModelDreamTrip:GetDreamTripEventTypeByRefId(eventRefId)

	--self._isAutoBattle = eventType == ModelDreamTrip.EVENT_TYPE_DBZ
	self._isDBZEvent = eventType == ModelDreamTrip.EVENT_TYPE_DBZ

	local textId = 20443
	local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
	if not eventRef then return end
	if eventType == ModelDreamTrip.EVENT_TYPE_ZD then
		self:ShowZDView(eventRef)
		textId = 20440
	elseif eventType == ModelDreamTrip.EVENT_TYPE_BX or
			eventType == ModelDreamTrip.EVENT_TYPE_CSM then
		self:ShowBXView(eventRef)
	elseif eventType == ModelDreamTrip.EVENT_TYPE_DBZ then
		self:ShowDBZView(eventRef)
		textId = 20443
	end
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(textId))

	if eventRef then
		local prefab = eventRef.prefab
		self:CreateWndSpine(self.mSpine,prefab,prefab,false,function(dpSpine)
			dpSpine:SetScale(eventRef.prefabSize or 1)
		end)
		self:SetWndText(self.mTitleText,ccLngText(eventRef.name))
	end
end

function UIHopeEvent4:OnActivityDreamTripStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end
	local isBX = false
	local eventId,index,eventRefId
	local endInfo = pb.endInfo
	local sendTxt
	if endInfo then
		endInfo = gModelDreamTrip:GetEventInfoServerDataByPb(endInfo)
		eventRefId = endInfo.eventRefId
		local eventType = gModelDreamTrip:GetDreamTripEventTypeByRefId(eventRefId)
		if eventType == ModelDreamTrip.EVENT_TYPE_GW and eventRefId == 1111 then
			sendTxt = ccClientText(20452)
		elseif eventType == ModelDreamTrip.EVENT_TYPE_ZD then
			sendTxt = ccClientText(20453)
		else
			local name = gModelDreamTrip:GetDreamTripNameByRefId(eventRefId)
			sendTxt = string.replace(ccClientText(20454),name)
		end
		isBX = eventType == ModelDreamTrip.EVENT_TYPE_BX and endInfo.state ~= StructDreamTripGrid.FINISH
		eventId,index = endInfo.eventId,endInfo.index
	end
	self:WndClose()
	local state = pb.state
	if state ~= StructDreamTripGrid.FINISH then
		local clickEvent = isBX
		if clickEvent then
			gModelDreamTrip:ClickEvent(eventRefId,eventId,index,self:GetExtraData())
		end
	else
		gModelCommonDreamTrip:CheckSendSpeedUpEvent(self:GetExtraData())
	end
	if sendTxt and self._isCSM then
		GF.ShowMessage(sendTxt)
	end
end

function UIHopeEvent4:CountDownTime()
	if self._time <= 0 then
		CS.ShowObject(self.mTimeText,false)
		self:TimerStop(self._gotoBattleKey)
		self:OpenEvent1Wnd()
		self:WndClose()
		return
	end
	local str = string.replace(ccClientText(20413),self._time)
	self:SetWndText(self.mTimeText,str)
	self._time = self._time - 1
end

function UIHopeEvent4:ShowDBZView(eventRef)
	if not eventRef then return end
	local choose = string.split(eventRef.choose,"|")
	local chooseNum = tonumber(choose[1])
	local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(chooseNum)
	if not textRef then return end
	local dec = ccLngText(textRef.dec)
	self:SetWndText(self.mDesText,dec)
end

function UIHopeEvent4:ShowZDView(eventRef)
	if not eventRef then return end
	local choose = tonumber(eventRef.choose)
	local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(choose)
	if not textRef then return end
	local dec = ccLngText(textRef.dec)
	self:SetWndText(self.mDesText,dec)
end

function UIHopeEvent4:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnConfirm, function(...) self:OnClickConfirm() end)
end

function UIHopeEvent4:InitText()
	self:SetWndText(self.mTitleText,"事件名字")
end

function UIHopeEvent4:InitMessage()
	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb,ret)
		self:OnDreamTripStartEventResp(pb)
	end)

	--- 7.20新增活动梦境之旅
	--self:WndNetMsgRecv(LProtoIds.ActivityDreamTripStartEventResp,function(pb,ret)
	--	self:OnActivityDreamTripStartEventResp(pb)
	--end)
end

function UIHopeEvent4:InitCommand()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")
	self._isCSM = self:GetWndArg("isCSM")

	local extraData = self:GetWndArg("extraData")
	self._extraData = extraData

	self._sendMsg = false
end

function UIHopeEvent4:GetExtraData()
	return self._extraData
end

function UIHopeEvent4:ShowBXView(eventRef)
	if not eventRef then return end
	local choose = string.split(eventRef.choose,"|")
	local chooseNum = tonumber(choose[1])
	local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(chooseNum)
	if not textRef then return end
	local dec = ccLngText(textRef.dec)
	self:SetWndText(self.mDesText,dec)
end
------------------------------------------------------------------
return UIHopeEvent4


