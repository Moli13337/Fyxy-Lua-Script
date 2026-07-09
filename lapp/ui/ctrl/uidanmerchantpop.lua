---
--- 模板901 数数运营任务礼包(深海商人)
--- Created by Ease.
--- DateTime: 2023/10/10 16:22:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDanMerchantPop:LWnd
local UIDanMerchantPop = LxWndClass("UIDanMerchantPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDanMerchantPop:UIDanMerchantPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDanMerchantPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDanMerchantPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDanMerchantPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitMessage()
	self:InitEvent()
	self:InitData()
end

function UIDanMerchantPop:SetDefultUI()
	self:SetWndText(self.mCloseDescTxt,ccClientText(10103))
end
function UIDanMerchantPop:GetRewardSortNum(rewardData)
	local webData = rewardData.webData
	local marketData = webData.MarketData
	local personal,personalGoal = marketData.personal,marketData.personalGoal
	local buyNum = personalGoal - personal
	return (personalGoal == -1 or buyNum>0) and 0 or 1
end
function UIDanMerchantPop:OnCustonRewardListCell(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item,"itemRoot/Icon")
	local itemNum = self:FindWndTrans(item,"itemNum")
	local shift = self:FindWndTrans(item,"Shift")
	local eff = self:FindWndTrans(item,"Eff")

	local webData = itemdata.webData
	local marketData = webData.MarketData
	local personal,personalGoal = marketData.personal,marketData.personalGoal
	local buyNum = personalGoal - personal

	local itemType = itemdata.itemType
	local showShift = itemType ~= nil and (personalGoal == -1 or buyNum>0)
	CS.ShowObject(shift,showShift)
	local instanceID = Icon:GetInstanceID()
	local commonInfo = {
		instanceID = instanceID,
		trans = Icon,
		itemType = itemdata.itemType,
		itemId = itemdata.itemId,
		itemNum = -1,
	}
	self:CreateCommonIcon(commonInfo)
	local num = itemdata.itemNum
	local showNum = num > 0
	CS.ShowObject(itemNum,showNum)
	self:SetWndText(itemNum,LUtil.NumberCoversion(num))
	local notShowTips = itemdata.notShowTips --点击不显示道具tips
	if notShowTips then
		return
	end
	self:SetWndClick(shift,function()
		self:OpenUICumSelectNew(itemdata)
	end)
	self:SetWndClick(Icon,function()
		if(itemdata.isEmpty)then
			self:OpenUICumSelectNew(itemdata)
		else
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end
	end)
end
function UIDanMerchantPop:BuyGift(refId,expend,giftName)
	local giftName = ccLngText(giftName)
	local isUseItemBuy = string.find(expend,"=")
	if isUseItemBuy then
		local item = LxDataHelper.ParseItem_3(expend)
		local itemId = item.itemId
		iconPath = gModelItem:GetItemIconByRefId(itemId)
		local dia = gModelItem:GetNumByRefId(itemId)
		local value = item.itemNum
		btnStr = tostring(value)
		local func = function()
			if dia >= value then
				self:OnBuyPrivilegeGiftReq(refId)
			else
				gModelGeneral:OpenGetWayWnd({itemId = item.itemId})
			end
		end
		GF.OpenWnd("UIOrdinTip",{
			refId = 110002,
			func = func,
			para = {value,giftName},
			consume = {value, itemId}
		})
	else
		local expendId = tonumber(expend)
		gModelPay:GiftPayCtrl(refId,expendId,ModelPay.PAY_TYPE_ACTIVITY,nil,self._sid,1)
	end
end
function UIDanMerchantPop:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
		self:OnActivityConfigData(...)
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end
function UIDanMerchantPop:SetTransPos(trans,pos)
	if(pos and not string.isempty(pos))then
		local posData = LxDataHelper.ParseVector2NotEmpty3(pos)
		self:SetAnchorPos(trans,posData)
	end
end
function UIDanMerchantPop:SetFixRewardList(trans,cfg)
	local itemList = LxDataHelper.ParseItem(cfg)
	local rewardScroll = trans
	local key = rewardScroll:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(itemList)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(rewardScroll, itemList, function(...)
			self:OnFixRewardListCell(...)
		end)
	end
	uiList:EnableScroll(false,true)
end
function UIDanMerchantPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		self:OnActivityPageResp(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp, function(pb)
		for k,v in ipairs(pb.activities) do
			local activity = StructActivity:New()
			activity:CreateByPb(v)
			local model = activity.model
			if(activity.sid == self._sid and model == 901 and activity.status == 3)then
				self:WndClose()
				return
			end
		end
	end)
end

function UIDanMerchantPop:OnActivityConfigData(data, sid)
	if sid ~= self._sid then
		return
	end
	self._cfgData = data
	self:SetData()
	gModelActivity:OnActivityPageReq(self._sid)
end
function UIDanMerchantPop:SetUI()
	local titlepath = self._mainCfg.img2
	self:SetWndEasyImage(self.mTitleImg,titlepath)
	self:SetWndEasyImage(self.mBgImage,self._mainCfg.img1)

	local titleImgPos = self._mainCfg.img2Pos
	self:SetTransPos(self.mTitleImg,titleImgPos)
end
function UIDanMerchantPop:OnActivityPageResp(pb, ret)
	local sid = pb.sid
	if sid ~= self._sid then
		return
	end
	local page = pb.pages[1]
	if(not page)then
		self:WndClose()
		return
	end
	local pageId = page.pageId
	local pageData = gModelActivity:GenerateActivePageDataFromPb(page)
	local entry = {}
	for i, v in ipairs(pageData.entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(sid, pageId, v.entryId)
		local data = {}
		data.webData = v
		data.title = entryCfg.name
		data.desc = entryCfg.description
		data.moreInfo = entryCfg.moreInfo
		data.status = v.status or v.goalData.status
		data.reward = entryCfg.reward
		data.customList = v.MarketData.customList
		data.customGift = v.MarketData.customGift
		data.rewardFree = entryCfg.rewardFree
		data.discount = entryCfg.discount
		data.name = entryCfg.name
		data.expend2 = entryCfg.expend2
		data.id = entryCfg.id
		data.sort = entryCfg.sort
		data.personLimit = entryCfg.personLimit
		table.insert(entry, data)
	end    --后端已经排序
	self._page = pageData
	self._entry = entry
	self:SetRewardScroll()
end

function UIDanMerchantPop:SetCustomRewardList(trans, customArr, customRewardArr,webData,titleName)
	local itemList = {}
	for i = 1, #customRewardArr do
		local data = customArr[i] and LxDataHelper.ParseItem_4(customArr[i]) or {isEmpty = true,itemId = 0,itemNum = -1}
		data = table.light_copy(data)
		data.webData = webData
		data.index = i
		data.titleName = titleName
		table.insert(itemList, data)
	end
	local rewardScroll = trans
	local key = rewardScroll:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(itemList)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(rewardScroll, itemList, function(...)
			self:OnCustonRewardListCell(...)
		end)
	end
	uiList:EnableScroll(false,true)
end
function UIDanMerchantPop:OnTimer(key)
	for i, v in pairs(self._timerKeyList) do
		self:SetTime(i)
	end
end
function UIDanMerchantPop:InitData()
	self._uiCommonList 	= {}
	if(self._timerKeyList)then
		for i, v in pairs(self._timerKeyList) do
			self:TimerStop(v)
		end
	end
	self._timerKeyList = {}
	self._timeTxtDict={}
	self._endTimeDict={}
	self._sid = self:GetWndArg("sid")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end
	self._showTimeKey = "_endTimeKey"
	self:SetDefultUI()
	gModelActivity:ReqActivityConfigData(self._sid)
end
function UIDanMerchantPop:InitBtnEvent()
	self:SetWndClick(self.mMaskImage, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end
function UIDanMerchantPop:SetRewardScroll()
	local list = table.light_copy(self._entry)
	table.sort(list, function(a,b)
		local aSortNum = self:GetRewardSortNum(a)
		local bSortNum = self:GetRewardSortNum(b)
		if(aSortNum~=bSortNum)then
			return aSortNum<bSortNum
		end
		return a.sort<b.sort
	end)
	local rewardScroll = self.mRewardScroll
	local key = rewardScroll:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(rewardScroll, list, function(...)
			self:OnRewardScrollCell(...)
		end)
	end
	uiList:EnableScroll(#list>3,false)
end
function UIDanMerchantPop:SetTime(key)
	if(not self._timeTxtDict[key])then
		self:TimerStop(key)
		return
	end
	local stime = GetTimestamp()
	local endTime = self._endTimeDict[key]
	local timespan = endTime - stime
	local timeStr = ""
	if(timespan <= 0)then
		self:TimerStop(key)
		gModelActivity:OnActivityPageReq(self._sid)
	else
		timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(self._mainCfg.desc1,timeStr)
	end
	self:SetWndText(self._timeTxtDict[key],timeStr)
end

function UIDanMerchantPop:SetData()
	local cfgData = self._cfgData --配置表f
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if (not cfgData or not activityData) then
		return
	end
	self._mainCfg = cfgData.config
	self._entriesCfg = cfgData.chunk[1].entries
	self:SetUI()
end
function UIDanMerchantPop:OnRewardScrollCell(list, item, itemdata, itempos)
	local rewardDiv = self:FindWndTrans(item, "RewardDiv")
	local fixRewardList = self:FindWndTrans(rewardDiv, "FixRewardList")
	local addImgGroup = self:FindWndTrans(rewardDiv, "AddImgGroup")
	local customRewardList = self:FindWndTrans(rewardDiv, "CustomRewardList")
	local discountTxt = self:FindWndTrans(item, "DiscountImg/DiscountTxt")
	local buyBtn = self:FindWndTrans(item, "BuyBtn")
	local overImg = self:FindWndTrans(item, "OverImg")
	local countDownTxt = self:FindWndTrans(item, "CountDownTxt")
	local titleTxt = self:FindWndTrans(item, "TxtBg/Txt")
	local timeTxt = self:FindWndTrans(item, "TimeTxt")
	self:SetWndText(titleTxt, itemdata.name)
	self:SetWndText(discountTxt,tostring(itemdata.discount).."%")
	local webData = itemdata.webData
	local marketData = webData.MarketData
	local personal,personalGoal = marketData.personal,marketData.personalGoal
	local lastBuyTims = personalGoal - personal
	CS.ShowObject(countDownTxt,personalGoal~= -1)
	local limitStr = string.replace(ccClientText(38900),lastBuyTims)
	--local limitStr = lastBuyTims
	self:SetWndText(countDownTxt,limitStr)
	local fixRewardCfg = itemdata.reward
	--local customList = itemdata.customList
	local customGift = itemdata.customGift
	local customArr = string.split(customGift,",")
	local customReward = itemdata.rewardFree
	local showCustom = customReward and not string.isempty(customReward)
	self:SetFixRewardList(fixRewardList,fixRewardCfg)
	local seleRewardEnd = true
	if(showCustom)then
		local customRewardArr = string.split(customReward,"|")
		seleRewardEnd = #customArr == #customRewardArr
		self:SetCustomRewardList(customRewardList, customArr, customRewardArr,webData,itemdata.name)
	end
	CS.ShowObject(addImgGroup,showCustom)
	CS.ShowObject(customRewardList,showCustom)

	local hasBuyTime = lastBuyTims>0 or personalGoal == -1

	if(hasBuyTime)then
		local expentIcon = self:FindWndTrans(buyBtn,"Icon")
		local expentTxt = self:FindWndTrans(buyBtn,"Txt")
		--local effTrans = self:FindWndTrans(buyBtn,"Eff")
		local expentCfg = itemdata.expend2
		CS.ShowObject(expentIcon,false)
		if(expentCfg and not string.isempty(expentCfg))then
			local isUseItemBuy = string.find(expentCfg,"=")
			local iconPath = ""
			local btnStr = ""
			if isUseItemBuy then
				local item = LxDataHelper.ParseItem_3(expentCfg)
				local itemId = item.itemId
				iconPath = gModelItem:GetItemIconByRefId(itemId)
				self:SetWndEasyImage(expentIcon,iconPath)
				btnStr = tostring(item.itemNum)
				CS.ShowObject(expentIcon,iconPath and not string.isempty(iconPath))
			else
				local expendId = tonumber(expentCfg)
				btnStr = gModelPay:GetShowByWelfareId(expendId)
			end
			self:SetWndText(expentTxt,btnStr)
		end
		self:SetWndClick(buyBtn, function()
			if(not seleRewardEnd)then
				self:OpenUICumSelectNew(itemdata)
			else
				self:BuyGift(itemdata.id,expentCfg,itemdata.name)
			end
		end)
	end
	CS.ShowObject(buyBtn,hasBuyTime)
	CS.ShowObject(overImg,not hasBuyTime)
	CS.ShowObject(timeTxt,hasBuyTime)
	if(hasBuyTime)then
		local instanceId = item:GetInstanceID()
		local timerKey = "timeKey_"..instanceId
		local moreInfo = JSON.decode(webData.moreInfo)
		local endTime = moreInfo.showEndTime and tonumber(moreInfo.showEndTime)/ 1000 or 0
		self._timeTxtDict[timerKey] = timeTxt
		self._endTimeDict[timerKey] = endTime
		self:TimerStop(timerKey)
		self._timerKeyList[timerKey] = true
		self:TimerStart(timerKey,1,false,-1)
		self:SetTime(timerKey)
	end
end
function UIDanMerchantPop:CreateCommonIcon(data)
	local instanceID = data.instanceID
	local trans = data.trans
	local itemType,itemId,itemNum = data.itemType, data.itemId, data.itemNum
	local baseClass = self._uiCommonList[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonList[instanceID] = baseClass
		baseClass:Create(trans)
	end
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	local showNum = itemNum > 0
	baseClass:EnableShowNum(showNum)
	baseClass:DoApply()
end
function UIDanMerchantPop:OpenUICumSelectNew(itemdata)
	local webData = itemdata.webData
	local para = {
		sid = self._sid,
		pageId = webData.pageId,
		entryId = webData.entryId,
		itemIndex = itemdata.index or 1,
		giftData = webData,
		title = itemdata.titleName,
	}
	GF.OpenWnd("UICumSelectNew",para)
end
function UIDanMerchantPop:OnFixRewardListCell(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item,"itemRoot/Icon")
	local itemNum = self:FindWndTrans(item,"itemNum")
	local Shift = self:FindWndTrans(item,"Shift")
	local Eff = self:FindWndTrans(item,"Eff")
	local itemType = itemdata.itemType
	local showShift = itemType ~= nil
	CS.ShowObject(Shift,showShift)
	local instanceID = Icon:GetInstanceID()
	local commonInfo = {
		instanceID = instanceID,
		trans = Icon,
		itemType = itemdata.itemType,
		itemId = itemdata.itemId,
		itemNum = -1,
	}
	self:CreateCommonIcon(commonInfo)
	local num = itemdata.itemNum
	local showNum = num > 0
	CS.ShowObject(itemNum,showNum)
	self:SetWndText(itemNum,LUtil.NumberCoversion(num))
	local notShowTips = itemdata.notShowTips --点击不显示道具tips
	if notShowTips then
		return
	end
	self:SetWndClick(Icon,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end
----------------
------------------------------------------------------------------
return UIDanMerchantPop


