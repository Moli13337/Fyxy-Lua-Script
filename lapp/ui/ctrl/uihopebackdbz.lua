---
--- Created by LCM.
--- DateTime: 2024/3/16 14:22:02
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeBackDBZ:LWnd
local UIHopeBackDBZ = LxWndClass("UIHopeBackDBZ", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeBackDBZ:UIHopeBackDBZ()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeBackDBZ:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeBackDBZ:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeBackDBZ:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndButtonText(self.mConfirmBtn,ccClientText(10102))
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
	self:InitToogleList()
end

function UIHopeBackDBZ:InitToogleList()
    local list = self:GetToogleList()
    local uiToogleList = self._uiToogleList
    if uiToogleList then
        uiToogleList:RefreshList(list)
    else
        uiToogleList = self:GetUIScroll("uiToogleList")
        self._uiToogleList = uiToogleList
        uiToogleList:Create(self.mToogleList,list,function(...) self:OnDrawToogleCell(...) end)
    end
end

function UIHopeBackDBZ:OnDrawToogleCell(list,item,itemdata,itempos)
    local OnImageTrans = self:FindWndTrans(item,"OnImage")
    local TextTrans = self:FindWndTrans(item,"Text")
	self:SetWndText(TextTrans,itemdata.name)

	local toogleIndex = itemdata.toogleIndex
	local isSel = self._selToogle == toogleIndex
	CS.ShowObject(OnImageTrans,isSel)

	self:SetWndClick(item,function()
		self:OnClickToogleFunc(toogleIndex)
	end)
end

------------------------- List -------------------------
function UIHopeBackDBZ:RefreshView()
	local index = self._index
	local eventId = self._eventId
	--local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(eventId,index)

	local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(eventId,index,self:GetExtraData())
	if not eventData then return end

	local eventRefId = eventData.eventRefId
	local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
	if not eventRef then return end

	local moreInfo = eventData.moreInfo
	local serverRoberBackCount = moreInfo.robber_back_count
	local roberBackCount = 0
	if serverRoberBackCount then
		roberBackCount = serverRoberBackCount[#serverRoberBackCount] and serverRoberBackCount[#serverRoberBackCount].roberBackCount or 0
	end
	roberBackCount = roberBackCount + 1

--[[	local choose = string.split(eventRef.choose,"|")
	local len = #choose
	local textId = len < roberBackCount and choose[len] or choose[roberBackCount]
	textId = tonumber(textId)]]

	local textId = gModelDreamTrip:GetConfigByKey("pirateSurrender")
	local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(textId)
	if textRef then
		self:SetWndText(self.mDesText,ccLngText(textRef.dec))
	end

	local prefab = eventRef.prefab
	self:CreateWndSpine(self.mSpine,prefab,prefab,false,function(dpSpine)
		dpSpine:SetScale(eventRef.prefabSize)
	end)

	self:SetWndText(self.mLblBiaoti,ccLngText(eventRef.name))
end

function UIHopeBackDBZ:OnTcpReconnect()
	self._sendMsg = false
end

function UIHopeBackDBZ:OnClickConfirmBtnFunc()
	if self._sendMsg then return end
	if not self._selToogle then
		GF.ShowMessage(ccClientText(20493))
		return
	end
	self._sendMsg = true
	--gModelDreamTrip:OnDreamTripStartEventReq(self._eventId,{tostring(self._selToogle)})

	local extraData = self:GetExtraData()
	gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
		mapType = extraData.mapType,
		sid = extraData.sid,
		argList = {tostring(self._selToogle)},
	})
end

function UIHopeBackDBZ:InitEvent()
    self:SetWndClick(self.mBgImage,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mConfirmBtn,function() self:OnClickConfirmBtnFunc() end)
end
------------------------- List -------------------------
function UIHopeBackDBZ:GetToogleList()
	return self._toogleDataList or {}
end

function UIHopeBackDBZ:InitMsg()
	 self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb) self:OnDreamTripStartEventResp(pb) end)
	 self:WndNetMsgRecv(LProtoIds.DreamTripRobberInfoResp,function(pb) self:OnDreamTripRobberInfoResp(pb) end)
	-- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)

	--- 7.20新增活动梦境之旅
	--self:WndNetMsgRecv(LProtoIds.ActivityDreamTripStartEventResp,function(pb,ret) self:OnDreamTripStartEventResp(pb) end)
end

function UIHopeBackDBZ:InitData()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")

	local extraData = self:GetWndArg("extraData")
	self._extraData = extraData

	self._sendMsg = false

	self._selToogle = nil

	self._toogleDataList = {
		{
			name = ccClientText(20491),
			toogleIndex = ModelDreamTrip.DBZ_LETOFF,
		},
		{
			name = ccClientText(20492),
			toogleIndex = ModelDreamTrip.DBZ_ARREST,
		},
	}
end

function UIHopeBackDBZ:OnDreamTripRobberInfoResp(pb)
	if pb.eventId ~= self._eventId then return end
end

function UIHopeBackDBZ:OnClickToogleFunc(toogleIndex)
	if self._selToogle == toogleIndex then
		return
	end
	self._selToogle = toogleIndex
	self:InitToogleList()
end

function UIHopeBackDBZ:GetExtraData()
	return self._extraData
end

function UIHopeBackDBZ:OnDreamTripStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end
--[[	local endInfo = pb.endInfo
	if endInfo then
		endInfo = gModelDreamTrip:GetEventInfoServerDataByPb(endInfo)
		if endInfo.state == StructDreamTripGrid.FINISH then
		end
	end]]
	self._sendMsg = false
	gModelCommonDreamTrip:CheckSendSpeedUpEvent(self:GetExtraData())
	self:WndClose()
end

------------------------------------------------------------------
return UIHopeBackDBZ



