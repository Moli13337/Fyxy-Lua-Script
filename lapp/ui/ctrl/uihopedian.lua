---
--- Created by Administrator.
--- DateTime: 2023/10/8 15:54:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeDian:LWnd
local UIHopeDian = LxWndClass("UIHopeDian", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeDian:UIHopeDian()
	---@type table<number, CommonIcon>
	self._commonIconClsTbl = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeDian:OnWndClose()
	self:ClearCommonIconList(self._commonIconClsTbl)
	self._commonIconClsTbl = nil
	--FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeDian:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeDian:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mTitle,ccClientText(20439))
	self:SetWndButtonText(self.mGotoBtn,ccClientText(20441))
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitRewardList()
	self:RefreshView()
end

function UIHopeDian:OnDrawRewardCell(list,item,itemdata,itempos)
	local reward = itemdata.reward
	local price = itemdata.price
	local fixDiscount = itemdata.fixDiscount
	local buyNum = itemdata.buyNum
	local shopRefId = itemdata.shopRefId
	local instanceId = item:GetInstanceID()
	local root = self:FindWndTrans(item,"root")
	local iconTrans = CS.FindTrans(root, "CommonUI/Icon")
	if iconTrans then
		local iconCls = self._commonIconClsTbl[instanceId]
		if not iconCls then
			iconCls = CommonIcon:New()
			self._commonIconClsTbl[instanceId] = iconCls
			iconCls:Create(iconTrans)
		end
		iconCls:SetCommonReward(reward.itemType, reward.itemId, reward.itemNum)
		iconCls:EnableShowNum(true)
		iconCls:DoApply()
		self:SetIconClickScale(iconTrans,true)
		self:SetWndClick(iconTrans, function () gModelGeneral:ShowCommonItemTipWnd(reward) end)
	end

	local buyBtn = self:FindWndTrans(item,"buyBtn")
	if buyBtn then
		local itemNum = price.itemNum
		local itemId = price.itemId
		local buyBtnIcon = self:FindWndTrans(buyBtn,"icon")
		local buyBtnNum = self:FindWndTrans(buyBtn,"num")
		local rewardId = reward.itemId

		local icon = gModelItem:GetItemImgByRefId(itemId)
		if icon then
			self:SetWndEasyImage(buyBtnIcon,icon)
		end

		local numStr = LUtil.NumberCoversion(itemNum)
		self:SetWndText(buyBtnNum,numStr)

		local status = self._status ~= StructDreamTripGrid.FINISH and not self._allBuy
		local gray = status and buyNum > 0
		local state = gray and 1 or 0
		self:SetImageActorState(buyBtn,state)

		self:SetWndClick(buyBtn,function()
			if buyNum > 0 then
				local name = gModelItem:GetNameByRefId(rewardId)
				local str = string.replace(ccClientText(20472),name)
				GF.ShowMessage(str)
				return
			end
			if state == 0 then
				self:BuyEvent(shopRefId,itemNum,rewardId,itemId)
			end
		end)
	end
	local discount = self:FindWndTrans(item,"discount")
	if discount then
		local showDis = false
		if fixDiscount > 0 then
			showDis = true
			local iconPath = self._discountIcons[fixDiscount]
			self:SetWndEasyImage(discount,iconPath)
		end
		CS.ShowObject(discount,showDis)
	end
end

function UIHopeDian:OnDreamTripStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end

	if pb.endInfo and pb.endInfo.state == StructDreamTripGrid.FINISH then
		--gModelDreamTrip:OnDreamTripRobberInfoReq()

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:OnDreamTripRobberInfoProcessor(extraData)
		gModelCommonDreamTrip:CheckSendSpeedUpEvent(extraData)
		self:WndClose()
		return
	end
	self:RefreshStatus()
	self:InitRewardList()
end

function UIHopeDian:BuyEvent(shopRefId,itemNum,rewardId,itemId)
	local func = function()
		--gModelDreamTrip:OnDreamTripStartEventReq(self._eventId,{tostring(shopRefId)})

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
			mapType = extraData.mapType,
			sid = extraData.sid,
			argList = {tostring(shopRefId)},
		})
	end
	local name = gModelItem:GetNameByRefId(rewardId)
	local payItemIdName = gModelItem:GetNameByRefId(itemId)
	local numStr = LUtil.NumberCoversion(itemNum)
	local str = numStr..payItemIdName
	gModelGeneral:OpenUIOrdinTips({refId = 230002,func = func,para = {str,name},consume={itemNum, itemId}})
end

function UIHopeDian:GetRewardList()
	local list = {}
	local allBuy = false
	--local moreInfo = gModelDreamTrip:GetPlatMoreInfoKeyByIndexAndEventId(self._eventId,nil,StructDreamTripEventInfo.SHOP_ITEM)

	local extraData = self:GetExtraData()
	local moreInfo = gModelCommonDreamTrip:GetDreamTripEventIdMoreInfoKey({
		mapType = extraData.mapType,
		sid = extraData.sid,
		eventId = self._eventId,
		index = self._index,
		key = StructDreamTripEventInfo.SHOP_ITEM,
	})
	if moreInfo then
		local allBuyNum = 0
		for i,v in ipairs(moreInfo) do
			local shopRefId = v.shopRefId
			local buyNum = v.buyNum
			allBuyNum = allBuyNum + buyNum
			local shopRef = gModelDreamTrip:GetDreamTripShopRefByRefId(shopRefId)
			if shopRef then
				local rewardList,priceList = shopRef.rewardList,shopRef.priceList
				table.insert(list,{
					reward = rewardList,
					price = priceList,
					fixDiscount = shopRef.fixDiscount,
					buyNum = buyNum,
					shopRefId = shopRefId,
				})
			end
		end
		allBuy = allBuyNum >= #moreInfo
	end
	self._allBuy = allBuy
	return list
end
function UIHopeDian:InitData()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")

	local extraData = self:GetWndArg("extraData")
	self._extraData = extraData

	self._discountIcons=
	{
		[1] = "shop_txt_sale_1",
		[2] = "shop_txt_sale_2",
		[3] = "shop_txt_sale_3",
		[4] = "shop_txt_sale_4",
		[5] = "shop_txt_sale_5",
		[6] = "shop_txt_sale_6",
		[7] = "shop_txt_sale_7",
		[8] = "shop_txt_sale_8",
		[9] = "shop_txt_sale_9",
	}

	self:RefreshStatus()
end

function UIHopeDian:InitRewardList()
	local list = self:GetRewardList()

	local uiRewardList = self._uiRewardList
	if uiRewardList then
		uiRewardList:RefreshData(list)
	else
		uiRewardList = self:GetUIScroll("uiRewardList")
		self._uiRewardList = uiRewardList
		uiRewardList:Create(self.mItemList,list,function(...) self:OnDrawRewardCell(...) end)
	end
end

function UIHopeDian:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mGotoBtn,function()
		self:GoToEvent()
	end)
end

function UIHopeDian:RefreshView()
	local index = self._index
	local eventId = self._eventId

	--local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(eventId,index)

	local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(eventId,index,self:GetExtraData())
	if not eventData then return end

	local eventRefId = eventData.eventRefId
	local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
	if not eventRef then return end

	local choose = tonumber(eventRef.choose)
	local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(choose)
	if textRef then
		local dec = ccLngText(textRef.dec)
		self:SetWndText(self.mPost,dec)
	end
	local prefab = eventRef.prefab
	self:CreateWndSpine(self.mRole,prefab,prefab,false,function(dpSpine)
		dpSpine:SetScale(eventRef.prefabSize)
	end)
	self:SetWndText(self.mMainTitle,ccLngText(eventRef.name))
end

function UIHopeDian:GetExtraData()
	return self._extraData
end

function UIHopeDian:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb,ret) self:OnDreamTripStartEventResp(pb) end)

	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList)
		--gModelDreamTrip:EventIdCanCel(self._eventId)

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:CancelEventIdStatus({
			mapType = extraData.mapType,
			sid = extraData.sid,
			eventId = self._eventId
		})
	end)

	--- 7.20新增活动梦境之旅
	--self:WndNetMsgRecv(LProtoIds.ActivityDreamTripStartEventResp,function(pb,ret) self:OnActivityDreamTripStartEventResp(pb) end)
end

function UIHopeDian:RefreshStatus()
	--self._status = gModelDreamTrip:GetPlatformStatusByIndexAndEventId(self._eventId)

	self._status = gModelCommonDreamTrip:GetPlatformEventInfoStatus(self._eventId,self._index,self:GetExtraData())
end

function UIHopeDian:OnActivityDreamTripStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end

	if pb.endInfo and pb.endInfo.state == StructDreamTripGrid.FINISH then
		--gModelDreamTrip:OnDreamTripRobberInfoReq()

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:OnDreamTripRobberInfoProcessor(extraData)
		gModelCommonDreamTrip:CheckSendSpeedUpEvent(extraData)
		self:WndClose()
		return
	end
	self:RefreshStatus()
	self:InitRewardList()
end

function UIHopeDian:GoToEvent()
	if self._status ~= StructDreamTripGrid.FINISH then
		local func = function()
			--gModelDreamTrip:OnDreamTripStartEventReq(self._eventId,{"-1"})

			local extraData = self:GetExtraData()
			gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
				mapType = extraData.mapType,
				sid = extraData.sid,
				argList = {"-1"},
			})
		end
		gModelGeneral:OpenUIOrdinTips({refId = 230006,func = func})
	else
		self:WndClose()
	end
end
------------------------------------------------------------------
return UIHopeDian


