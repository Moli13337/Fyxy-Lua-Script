---
--- Created by Administrator.
--- DateTime: 2023/10/8 23:56:41
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEventGuess:LWnd
local UIHopeEventGuess = LxWndClass("UIHopeEventGuess", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEventGuess:UIHopeEventGuess()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEventGuess:OnWndClose()
	--FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEventGuess:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEventGuess:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitText()
	self:RefreshView()
	self:InitToogleList()
end

function UIHopeEventGuess:OnDrawToogleCell(list,item,itemdata,itempos)
	local CoverImg = self:FindWndTrans(item,"CoverImg")
	local Icon = self:FindWndTrans(item,"Icon")
	local index = itemdata.index
	local icon = itemdata.icon

	local show = index == self._selIndex
	CS.ShowObject(CoverImg,show)

	self:SetWndEasyImage(Icon,icon,nil,true)
	self:SetWndClick(item,function()
		self:SelToogleEvent(index)
	end)
end

function UIHopeEventGuess:GetExtraData()
	return self._extraData
end

function UIHopeEventGuess:OnClickConfirm()
	if self._isEnd then return end
	if self._selIndex or not string.isempty(self._selIndex) then
		--gModelDreamTrip:OnDreamTripStartEventReq(self._eventId,{tostring(self._selIndex)})

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
			mapType = extraData.mapType,
			sid = extraData.sid,
			argList = {tostring(self._selIndex)},
		})
	else
		GF.ShowMessage(ccClientText(20463))
	end
end

function UIHopeEventGuess:RefreshChooseTxt()
	local index = self._index
	local eventId = self._eventId
	--local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(eventId,index)

	local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(eventId,index,self:GetExtraData())
	if not eventData then return end
	local eventRefId = eventData.eventRefId
	local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
	if not eventRef then return end
	local choose = string.split(eventRef.choose,"|")
	local len = #choose
	local isOneTxt = len == 1
	local textId
	if isOneTxt then
		textId = tonumber(choose)
	else
		local randomNum = math.random(1,len)
		textId = tonumber(choose[randomNum])
	end
	if not textId then return end
	local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(textId)
	if not textRef then return end
	local dec = ccLngText(textRef.dec)
	self:SetWndText(self.mTopText,dec)
end

function UIHopeEventGuess:InitToogleList()
	local list = self._selInfo

	local uiToogleList = self._uiToogleList
	if uiToogleList then
		uiToogleList:RefreshList(list)
	else
		uiToogleList = self:GetUIScroll("uiToogleList")
		self._uiToogleList = uiToogleList
		uiToogleList:Create(self.mItemList,list,function(...) self:OnDrawToogleCell(...) end)
	end
end

function UIHopeEventGuess:OnCommonStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end
	local func = function()
		if not self:IsWndValid() then return end
		self._selIndex = nil
		self:RefreshView()
		self:RefreshChooseTxt()
		self:InitToogleList()
	end
	local rewardFunc
	self:RefreshBtnStatus()
	local endInfo = pb.endInfo
	if endInfo then
		local endInfoServerData = gModelDreamTrip:GetEventInfoServerDataByPb(endInfo)
		if endInfoServerData then
			local moreInfo = endInfoServerData.moreInfo or {}
			local more = moreInfo[StructDreamTripEventInfo.MORA_INFO]
			if more then
				local len = #more
				local data = more[len]
				if data then
					local extraData = self:GetExtraData()
					if endInfoServerData.state == StructDreamTripGrid.FINISH then
						local reward = {}
						for i,v in ipairs(endInfoServerData.reward) do
							table.insert(reward,{
								itemId = v.itemId,
								itype = v.itemType,
								count = v.itemNum,
							})
						end
						rewardFunc = function()
							gModelWndPop:TryOpenPopWnd("UIAward", {itemList = reward,callBackFunc = function()
								--gModelDreamTrip:OnDreamTripRobberInfoReq()

								gModelCommonDreamTrip:CheckSendSpeedUpEvent(extraData)
								gModelCommonDreamTrip:OnDreamTripRobberInfoProcessor(extraData)
							end})
							self:WndClose()
						end
					end

					--local mapId = gModelDreamTrip:GetMapRefId()

					local mapId = gModelCommonDreamTrip:GetCurMapRefId(extraData.mapType,extraData.sid)
					if mapId == -1 then
						mapId = 1
					end

					local headInfo
					if mapId == 2 then
						headInfo = gModelDreamTrip:GetConfigByKey("systemHeadTheme")
					else
						headInfo = gModelDreamTrip:GetConfigByKey("systemHeadInfo")
					end

					--systemHeadTheme
					local systemHeadInfo = gModelDreamTrip:GetConfigByKey("systemHeadInfo")
					GF.OpenWndUp("UIHopeEventGuessResult",{
						leftInfo = {
							name = gModelPlayer:GetPlayerName(),
							result = data.myShow,
							headImg = gModelPlayer:GetHeadIcon(gModelPlayer:GetPlayerHead()),
							headFrameImg = gModelPlayer:GetPlayerHeadFrame()
						},
						rightInfo = {
							name = self._name or ccClientText(11117),
							result = data.youShow,
							headImg = headInfo.headImg,
							headFrameImg = headInfo.headFrameImg
						},
						result = data.winStatus,
						func = func,
						rewardFunc = rewardFunc,
					})
					return
				end
			end
		end
	end
	func()
end

function UIHopeEventGuess:InitData()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")

	local extraData = self:GetWndArg("extraData")
	self._extraData = extraData

	self._selIndex = nil
	self._selInfo = {
		{
			index = ModelDreamTrip.CQ_JIANDAO,
			icon = "dreamTrip_ui_7",
		},
		{
			index = ModelDreamTrip.CQ_SHITOU,
			icon = "dreamTrip_ui_6",
		},
		{
			index = ModelDreamTrip.CQ_BU,
			icon = "dreamTrip_ui_8",
		},
	}

	self:RefreshBtnStatus()
end

function UIHopeEventGuess:SelToogleEvent(index)
	if self._selIndex == index then return end
	self._selIndex = index
	local uiToogleList = self._uiToogleList
	if uiToogleList then
		local uiList = uiToogleList:GetList()
		uiList:RefreshList()
	end
end

function UIHopeEventGuess:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb,ret) self:OnCommonStartEventResp(pb) end)

	--- 7.20新增活动梦境之旅
	--self:WndNetMsgRecv(LProtoIds.ActivityDreamTripStartEventResp,function(pb,ret) self:OnCommonStartEventResp(pb) end)
end

function UIHopeEventGuess:RefreshView()
	--local mora_info = gModelDreamTrip:GetPlatMoreInfoKeyByIndexAndEventId(self._eventId,nil,StructDreamTripEventInfo.MORA_INFO)

	local extraData = self:GetExtraData()
	local mora_info = gModelCommonDreamTrip:GetDreamTripEventIdMoreInfoKey({
		mapType = extraData.mapType,
		sid = extraData.sid,
		eventId = self._eventId,
		index = self._index,
		key = StructDreamTripEventInfo.MORA_INFO,
	})
	if mora_info then
		local winNum,noWinNum = 0,0
		for i,v in ipairs(mora_info) do
			local myWin = v.myWin
			if myWin == 1 then
				winNum = winNum + 1
			elseif myWin == -1 then
				noWinNum = noWinNum + 1
			end
		end
		local str = string.replace(ccClientText(20418),winNum,noWinNum)
		self:SetWndText(self.mResultTxt,str)
	end
end

function UIHopeEventGuess:InitText()
	self:SetWndText(self.mButtomTitleText,ccClientText(20417))
	self:SetWndButtonText(self.mGoToBtn,ccClientText(20427))
	local index = self._index
	local eventId = self._eventId
	--local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(eventId,index)

	local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(eventId,index,self:GetExtraData())
	if not eventData then return end

	local eventRefId = eventData.eventRefId
	local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
	if not eventRef then return end

	self:RefreshChooseTxt()
	self:InitTextSizeWithLanguage(self.mTopText,-2)
	local name = ccLngText(eventRef.name)
	self._name = name
	self:SetWndText(self.mTitleText,name)
	self:InitTextLineWithLanguage(self.mTitleText, -30)
	local prefab = eventRef.prefab
	if prefab then
		self:CreateWndSpine(self.mFigure,prefab,prefab,false,function(dpSpine)
			dpSpine:SetScale(eventRef.prefabSize or 1)
		end)
	end
end

function UIHopeEventGuess:RefreshBtnStatus()
	--self._status = gModelDreamTrip:GetPlatformStatusByIndexAndEventId(self._eventId)


	self._status = gModelCommonDreamTrip:GetPlatformEventInfoStatus(self._eventId,self._index,self:GetExtraData())


	self._isEnd = self._status == StructDreamTripGrid.FINISH

	self:SetWndButtonGray(self.mGoToBtn,self._isEnd)
end

function UIHopeEventGuess:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mMask, function(...) self:WndClose() end)
	self:SetWndClick(self.mGoToBtn, function(...) self:OnClickConfirm() end)
end

------------------------------------------------------------------
return UIHopeEventGuess


