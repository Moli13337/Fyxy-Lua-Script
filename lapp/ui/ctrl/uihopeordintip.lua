---
--- Created by LCM.
--- DateTime: 2024/3/21 17:31:44
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeOrdinTip:LWnd
local UIHopeOrdinTip = LxWndClass("UIHopeOrdinTip", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeOrdinTip:UIHopeOrdinTip()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeOrdinTip:OnWndClose()
	--FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeOrdinTip:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeOrdinTip:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UIHopeOrdinTip:RefreshView()
	local eventRefId = self._eventRefId
	if not eventRefId then return end
	local eventRef = gModelFastDreamTrip:GetDreamTripEventRefByRefId(eventRefId)
	if not eventRef then return end

	local name = ccLngText(eventRef.name)
	self:SetWndText(self.mLblBiaoti,name)

	local choose = tonumber(eventRef.choose)
	local textRef = gModelFastDreamTrip:GetDreamTripTextRefByRefId(choose)
	local dec = ""
	if textRef then
		dec = ccLngText(textRef.dec)
	end
	self:SetWndText(self.mEventDesc,dec)

	local prefabSize = gModelFastDreamTrip:GetDreamTripEventPrefabSizeByRefId(self._eventRefId)
	local resType = eventRef.resType
	if resType == 1 then
		local res = eventRef.res
		self:SetWndEasyImage(self.mEventIcon,res,function()
			CS.ShowObject(self.mEventIcon,true)
			self.mEventIcon.localScale = Vector3(prefabSize,prefabSize,prefabSize)
		end,true)
	elseif resType == 2 then
		local prefab = eventRef.prefab
		self:CreateWndSpine(self.mEventSpinePos,prefab,prefab,false,function(dpSpine)
			dpSpine:SetScale(prefabSize or 1)
			CS.ShowObject(self.mEventSpinePos,true)
		end)
	end
end

function UIHopeOrdinTip:InitText()
	self:SetWndButtonText(self.mGoToBtn,ccClientText(28708))
end

function UIHopeOrdinTip:GoToAnchorEventFunc()
	gModelFastDreamTrip:OpenDropAnchorUI(self._eventInfo,self._gameParams)
end

function UIHopeOrdinTip:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mGoToBtn,function() self:OnClickGoToBtnFunc() end)
end

function UIHopeOrdinTip:InitData()
	---@type StructDreamTripEventInfo
	local eventInfo = self:GetWndArg("eventInfo")
	self._eventInfo = eventInfo

	local gameParams = self:GetWndArg("gameParams")
	self._gameParams = gameParams

	self._eventId = eventInfo.eventId
	self._index = eventInfo.index
	self._eventRefId = eventInfo.eventRefId
	self._eventType = eventInfo.eventType
end


function UIHopeOrdinTip:InitMsg()
end

function UIHopeOrdinTip:OnClickGoToBtnFunc()
	if not self._eventType then return end
	local eventType = self._eventType
	if eventType == ModelFastDreamTrip.EVENT_TYPE_DROPANCHOR then
		self:GoToAnchorEventFunc()
	elseif eventType == ModelFastDreamTrip.EVENT_TYPE_PRAY then
		self:GoToPrayEventFunc()
	elseif eventType == ModelFastDreamTrip.EVENT_TYPE_FLIGHT then
		gModelFastDreamTrip:OnDreamTripStartEventReq(self._eventId)
	end
	self:WndClose()
end

function UIHopeOrdinTip:GoToPrayEventFunc()
	gModelFastDreamTrip:OpenPrayUI(self._eventInfo,self._gameParams)
end
------------------------- List -------------------------


------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeOrdinTip



