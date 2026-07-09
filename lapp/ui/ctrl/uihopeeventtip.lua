---
--- Created by Administrator.
--- DateTime: 2023/10/15 14:50:48
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEventTip:LWnd
local UIHopeEventTip = LxWndClass("UIHopeEventTip", LWnd)
------------------------------------------------------------------

--- 预览
UIHopeEventTip.TYPE_OPEN_PRE = 1

--- 触发事件
UIHopeEventTip.TYPE_OPEN_TRIGGER = 2


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEventTip:UIHopeEventTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEventTip:OnWndClose()
	if self._trigger and self._eventId then
		gModelFastDreamTrip:OnDreamTripStartEventReq(self._eventId)
		FireEvent(EventNames.ON_FDT_EVENT_CLOSEUI)
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEventTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEventTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndButtonText(self.mCloseBtn,ccClientText(20432))
	self:InitEvent()
	self:InitData()
	--self:OnTriggerEvent()
	self:RefreshView()
end

function UIHopeEventTip:RefreshView()
	local eventData = self._eventInfo
	if not eventData then return end

	local eventRefId = eventData.eventRefId
	local eventType = eventData.eventType
	local eventRef = gModelFastDreamTrip:GetDreamTripEventRefByRefId(eventRefId)
	if not eventRef then return end

	local choose
	if eventType == ModelFastDreamTrip.EVENT_TYPE_MONSTER or
			eventType == ModelFastDreamTrip.EVENT_TYPE_BOMB or
			eventType == ModelFastDreamTrip.EVENT_TYPE_DROPANCHOR or
			eventType == ModelFastDreamTrip.EVENT_TYPE_PRAY or
			eventType == ModelFastDreamTrip.EVENT_TYPE_MONEYTREE or
			eventType == ModelFastDreamTrip.EVENT_TYPE_END then
		choose = tonumber(eventRef.choose)
	elseif eventType == ModelFastDreamTrip.EVENT_TYPE_DIRECTREWARD then
		local temp = string.split(eventRef.choose,"|")
		choose = tonumber(temp[1])
	else
		choose = tonumber(eventRef.choose)
	end
	if choose then
		local textRef = gModelFastDreamTrip:GetDreamTripTextRefByRefId(choose)
		if textRef then
			self:SetWndText(self.mText,ccLngText(textRef.dec))
		end
	end
	local resType = eventRef.resType
	local prefab = eventRef.prefab
	local prefabSize = eventRef.prefabSize
	if resType == 1 then
		self:SetWndEasyImage(self.mEventIcon,prefab,function()
			if not self:IsWndValid() then return end
			CS.ShowObject(self.mEventIcon,true)
			self.mEventIcon.localScale = Vector3(prefabSize,prefabSize,prefabSize)
		end,true)
	else
		self:CreateWndSpine(self.mFigure,prefab,prefab,false,function(dpSpine)
			dpSpine:SetScale(prefabSize)
		end)
	end

	self:SetWndText(self.mLblBiaoti,ccLngText(eventRef.name))
end

function UIHopeEventTip:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIHopeEventTip:OnTriggerEvent()
	if self._trigger then
		local textStr = ccClientText(20457)
		local eventData = self._eventInfo
		if eventData then
			local eventRefId = eventData.eventRefId
			local eventRef = gModelFastDreamTrip:GetDreamTripEventRefByRefId(eventRefId)
			if eventRef then
				local eventType = eventRef.type
			end
		end
		GF.ShowMessage(textStr)
	end
end

function UIHopeEventTip:InitData()
	---@type StructDreamTripEventInfo
	local eventInfo = self:GetWndArg("eventInfo")
	self._eventInfo = eventInfo

	local gameParams = self:GetWndArg("gameParams") or {}
	self._gameParams = gameParams
	self._openType = gameParams.openType or UIHopeEventTip.TYPE_OPEN_PRE

	self._eventId = eventInfo.eventId
	self._index = eventInfo.index

	self._trigger = gameParams.trigger
end

------------------------------------------------------------------
return UIHopeEventTip


