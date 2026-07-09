---
--- Created by LCM.
--- DateTime: 2024/3/10 17:09:50
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEvent4New:LWnd
local UIHopeEvent4New = LxWndClass("UIHopeEvent4New", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEvent4New:UIHopeEvent4New()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEvent4New:OnWndClose()
	--FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEvent4New:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEvent4New:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(10102))
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UIHopeEvent4New:CreateSpine(eventRef)
	if not eventRef then return end
	local prefab = eventRef.prefab
	self:CreateWndSpine(self.mSpine,prefab,prefab,false,function(dpSpine)
		dpSpine:SetScale(eventRef.prefabSize or 1)
	end)
end

function UIHopeEvent4New:OnClickBtnConfirmFunc()
	local index = self._index
	local eventId = self._eventId
	gModelDreamTrip:OnClickEventFunc(nil,eventId,index,self:GetExtraData())
	self:WndClose()
end

function UIHopeEvent4New:GetExtraData()
	return self._extraData
end



function UIHopeEvent4New:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnConfirm,function() self:OnClickBtnConfirmFunc() end)
end


function UIHopeEvent4New:InitMsg()

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIHopeEvent4New:RefreshView()
	local initEventId = self._initEventId
	local initEventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(initEventId)
	local eventTxtIdList = {}
	if initEventRef then
		self:SetWndText(self.mTitleText,ccLngText(initEventRef.name))

		local parameter = string.split(initEventRef.parameter,";")
		for i,v in ipairs(parameter) do
			v = string.split(v,"=")
			eventTxtIdList[tonumber(v[1])] = tonumber(v[3])
		end
	end
	local index = self._index
	local eventId = self._eventId
	--local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(eventId,index)

	local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(eventId,index,self:GetExtraData())
	if not eventData then return end

	local eventRefId = eventData.eventRefId
	local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
	local textId = eventTxtIdList[eventRefId]
	if eventRef then
		self:CreateSpine(eventRef)
	else
		self:CreateSpine(initEventRef)
	end
	if not textId then
		textId = tonumber(initEventRef.choose)
	end
	if not textId then return end
	local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(textId)
	if not textRef then
		if LOG_INFO_ENABLED then
			LogError("没有配置的文本Id:" .. textId)
		end
		return
	end
	local dec = ccLngText(textRef.dec)
	self:SetWndText(self.mDesText,dec)
end

function UIHopeEvent4New:InitData()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")
	self._initEventId = self:GetWndArg("initEventId")

	local extraData = self:GetWndArg("extraData")
	self._extraData = extraData
end
------------------------- List -------------------------


------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeEvent4New



