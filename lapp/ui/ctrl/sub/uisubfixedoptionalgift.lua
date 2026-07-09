---
--- Created by BY.
--- DateTime: 2023/10/14 14:30:40
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubFixedOptionalGift:LChildWnd
local UISubFixedOptionalGift = LxWndClass("UISubFixedOptionalGift", LChildWnd)

UISubFixedOptionalGift.HAVE_GIFT_NO_SEL = 0	--0：有普通奖励，没有自选奖励（默认，没这个字段时取该值）；
UISubFixedOptionalGift.HAVE_CELL_AND_GIFT = 1	--1：全都有；
UISubFixedOptionalGift.HAVE_SEL_NO_GIFT = 2	--2：有自选奖励，没有普通奖励

UISubFixedOptionalGift.TYPE_BUY_FREE = 0		--免费购买
UISubFixedOptionalGift.TYPE_BUY_ITEM = 1		--道具购买
UISubFixedOptionalGift.TYPE_BUY_RMB = 2		--充值购买
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubFixedOptionalGift:UISubFixedOptionalGift()
	self._uiCommonList 	= {}
	self._timeKey = "UISubFixedOptionalGift"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubFixedOptionalGift:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubFixedOptionalGift:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubFixedOptionalGift:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubFixedOptionalGift:SetTime()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local endTime = activityData.endTime
	if endTime == 0 then
		self:TimerStop(self._timeKey)
		self:SetWndText(self.mTimeText,ccClientText(18404))
		CS.ShowObject(self.mTimeBg,true)
		return
	end
	local time = GetTimestamp()
	local timespan = endTime - time
	local  timeStr = ""
	if(timespan < 0)then
		timeStr = ccClientText(14301)
		self:TimerStop(self._timeKey)
	else
		timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(ccClientText(18400),timeStr)
	end
	self:SetWndText(self.mTimeText,timeStr)
	CS.ShowObject(self.mTimeBg,true)
end

function UISubFixedOptionalGift:IsBuyNumEmpty(itemdata)
	local buyNum = itemdata.buyNum
	return buyNum > 0
end

function UISubFixedOptionalGift:CreateCommonIcon(data)
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
--####################################################################################################################
--### Top ############################################################################################################
--####################################################################################################################
function UISubFixedOptionalGift:SetContent()
	self:InitCustomList()
end
--####################################################################################################################
--### Common #########################################################################################################
--####################################################################################################################

function UISubFixedOptionalGift:GetCustomList()
	local list = {}
	local activityPageData = self.pages
	if not activityPageData then
		return list
	end

	local sortFunc = function(a,b)
		local sellOut1,sellOut2 = a.sellOut,b.sellOut
		if sellOut1 ~= sellOut2 then
			return sellOut1 > sellOut2
		else
			return a.sort < b.sort
		end
	end
	local selList = {}
	local pageId = self._giftCustomEnum
	local pageData = activityPageData[pageId] or {}
	local entryList = pageData.entry or {}
	for i,v in ipairs(entryList) do
		local entryId = v.entryId
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,entryId)
		local MarketData = v.MarketData
		local customListStr = string.split(MarketData.customList,"|")
		local customList = LxDataHelper.ParseItem(MarketData.customList)
		local len = #customListStr
		local customGiftList = LxDataHelper.ParseItem(MarketData.customGift) or {}
		local title = entryCfg.name
		local items = LxDataHelper.ParseItem(entryCfg.reward) or {}
		local getItemList = {}
		for k,v in ipairs(items) do
			table.insert(getItemList,v)
		end
		local personal,personalGoal = MarketData.personal,MarketData.personalGoal
		local buyNum = personalGoal - personal
		local sellOut = buyNum > 0 and 1 or 0
		for idx = 1,len do
			local curData = customGiftList[idx]
			if not curData then
				customGiftList[idx] = {
					isEmpty = true,
					itemId = 0,
					itemNum = -1,
				}
			else
				table.insert(getItemList,curData)
			end
			customGiftList[idx].pageId = pageId
			customGiftList[idx].entryId = entryId
			customGiftList[idx].title = title
			customGiftList[idx].index = idx
			customGiftList[idx].selList = customList
			customGiftList[idx].MarketData = MarketData
			customGiftList[idx].isSel = true
			customGiftList[idx].canSel = buyNum > 0
		end
		table.insert(selList,{
			isSel = true,
			customGiftList = customGiftList,
			fixReward = items,
			entryId = entryId,
			sort = entryCfg.sort,
			title = title,
			pageId = pageId,
			icon = entryCfg.icon,
			personal = personal,
			personalGoal = personalGoal,
			buyNum = buyNum,
			expend1 = MarketData.expend1,
			expend2 = MarketData.expend2,
			expendType = MarketData.expendType,
			sellOut = sellOut,
			discount = MarketData.discount,
			getItemList = getItemList,
		})
	end
	table.sort(selList,sortFunc)

	--local player = gModelPlayer:GetPlayerLv()
	local shopAllList = {}
	pageId = self._giftCommonEnum
	pageData = activityPageData[pageId] or {}
	entryList = pageData.entry or {}
	for i,v in ipairs(entryList) do
		local entryId = v.entryId
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,entryId)
		local cfgMoreInfo = entryCfg.moreInfo
		local moreInfo = string.split(cfgMoreInfo,";")
		--local showLv = moreInfo[2]
		--local needShowLv = showLv and tonumber(showLv) or 0 --显示等级
		local ins = true --player >= needShowLv
		if ins then
			local valuePercent = moreInfo[3]
			--local typeId = tonumber(moreInfo[4])		-- 类型ID=礼包卡底资源图=售卖文本字色=售卖文本描边色
			local MarketData = v.MarketData
			local personal,personalGoal = MarketData.personal,MarketData.personalGoal
			local buyNum = personalGoal - personal
			local sellOut = buyNum > 0 and 1 or 0

			local commonGiftList = {}
			local rewards = LxDataHelper.ParseItem(entryCfg.reward) or {}
			for p,q in ipairs(rewards) do
				local curData = {
					itemId = q.itemId,
					itemType = q.itemType,
					itemNum = q.itemNum,
					notShowTips = true, --点击不显示道具tips，直接打开详情弹窗
				}

				table.insert(commonGiftList,curData)
			end

			table.insert(shopAllList,{
				fixReward = rewards,
				entryId = entryId,
				sort = entryCfg.sort,
				title = entryCfg.name,
				pageId = pageId,
				expend1 = MarketData.expend1,
				expend2 = MarketData.expend2,
				personal = personal,
				personalGoal = personalGoal,
				buyNum = buyNum,
				sellOut = sellOut,
				moreInfo = cfgMoreInfo,
				--showLv = showLv,
				valuePercent = valuePercent,
				--typeId = typeId,
				desc = entryCfg.description,
				expendType = MarketData.expendType,
				commonGiftList = commonGiftList,
			})
		end
	end
	table.sort(shopAllList,sortFunc)

	local shopList = {}
	local index = 1
	for i,v in ipairs(shopAllList) do
		local indexList = shopList[index]
		if not indexList then
			indexList = {}
			shopList[index] = indexList
		end
		table.insert(indexList,v)
		if i % 3 == 0 then
			index = index + 1
		end
	end

	for i,v in ipairs(selList) do
		table.insert(list,v)
	end
	for i,v in ipairs(shopList) do
		table.insert(list,v)
	end


	return list
end

function UISubFixedOptionalGift:CreateCustom(trans,itemdata)
	local OverImg = self:FindWndTrans(trans,"OverImg")

	local rewardTrans = self:FindWndTrans(trans, "Reward")
	local fixRewardList = self:FindWndTrans(rewardTrans, "FixRewardList")
	local RewardList = self:FindWndTrans(rewardTrans,"RewardList")

	local BuyBtn = self:FindWndTrans(trans,"BuyBtn")
	local Eff = self:FindWndTrans(BuyBtn,"Eff")
	local RedPoint = self:FindWndTrans(BuyBtn,"RedPoint")
	local AutoDiv = self:FindWndTrans(BuyBtn,"AutoDiv")
	local Image = self:FindWndTrans(AutoDiv,"Image")
	local BuyBtnTxt = self:FindWndTrans(AutoDiv,"Txt")
	local DiscountImg = self:FindWndTrans(trans,"DiscountImg")
	local DiscountTxt = self:FindWndTrans(DiscountImg,"DiscountTxt")

	local TitleImg = self:FindWndTrans(trans,"TitleImg")
	local Txt = self:FindWndTrans(trans,"TxtBg/Txt")

	local CountDownTxt = self:FindWndTrans(trans,"CountDownTxt")

	self:SetWndEasyImage(TitleImg,itemdata.icon)
	self:SetWndText(Txt,itemdata.title)

	local buyNum = itemdata.buyNum
	local buyCountText = string.replace(ccClientText(20810), buyNum)
	self:SetWndText(CountDownTxt,buyCountText)

	local fixReward = itemdata.fixReward
	self:CreateSelGiftList(fixRewardList,fixReward)

	local isEmpty = buyNum < 1
	local show = not isEmpty

	local customGiftList = self:ChangeCustomList(itemdata.customGiftList,isEmpty)
	self:CreateSelGiftList(RewardList,customGiftList, #fixReward > 2)


	CS.ShowObject(OverImg,isEmpty)
	CS.ShowObject(BuyBtn,show)
	CS.ShowObject(CountDownTxt,show)

	local expendType = itemdata.expendType
	local expend2 = itemdata.expend2
	local txt,showIconImg ,iconPath = gModelPay:GetPayType(expendType,expend2)
	CS.ShowObject(Image,showIconImg)
	if LxUiHelper.IsImgPathValid(iconPath) then
		self:SetWndEasyImage(Image, iconPath)
	end
	self:SetWndText(BuyBtnTxt,txt)

	local effKey = trans:GetInstanceID()
	self:DestroyWndEffectByKey(effKey)
	local isFree = expendType ==self.TYPE_BUY_FREE
	if isFree then
		if show then
			self:CreateWndEffect(Eff,self._getBtnEff,effKey,100,false,false,10)
		end
		CS.ShowObject(RedPoint,show)
	end
	CS.ShowObject(RedPoint,show and isFree)

	local discount = itemdata.discount
	local showDis = discount > 0
	if showDis then
		self:SetWndText(DiscountTxt, discount.."%")
	end
	CS.ShowObject(DiscountImg,showDis)

	self:SetWndClick(BuyBtn, function()
		self:BuyClick(itemdata,true)
	end, LSoundConst.CLICK_BUTTON_COMMON)
end

function UISubFixedOptionalGift:ResetData(pages)
	for i, v in ipairs(pages) do
		local pageId = v.pageId
		if pageId == self._giftCustomEnum or pageId == self._giftCommonEnum then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			self.pages[pageId] = page
		end
	end
	self:RefreshData()
end

function UISubFixedOptionalGift:OnDrawItemCell(list,item,itemdata,itempos)
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

	local isSel = itemdata.isSel
	local canSel = itemdata.canSel
	local status = itemdata.status
	self:SetWndClick(Icon,function()
		local notShowMsg = status ~= nil and status or false
		if not notShowMsg then
			if isSel and canSel then
				GF.OpenWnd("UICumSelectNew",{sid = self._sid,pageId = itemdata.pageId,entryId = itemdata.entryId,
												 itemIndex = itemdata.index,giftData = itemdata,title = itemdata.title,})
			else
				gModelGeneral:ShowCommonItemTipWnd(itemdata)
			end
		else
			--GF.ShowMessage(ccClientText(20811))
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end
	end)
end

function UISubFixedOptionalGift:RefreshData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config
	self._cfgDataMoreInfo = data

	self:SetContent()
end

function UISubFixedOptionalGift:InitCustomList()
	local list = self:GetCustomList()
	if #list <= 0 then return end

	local uiCallGiftList = self._uiCallGiftList
	if uiCallGiftList then
		uiCallGiftList:RefreshData(list)
	else
		uiCallGiftList = self:GetUIScroll("uiCallGiftList")
		self._uiCallGiftList = uiCallGiftList
		uiCallGiftList:Create(self.mCallGiftList,list,function(...) self:OnDrawCustomCell(...) end,UIItemList.WRAP, false)
		uiCallGiftList:EnableLoadAnimation(true, 0.03, 1, 2)
		local uiList = uiCallGiftList:GetList()
		uiList:RefreshList(UIListWrap.RefreshMode.Solid)
	end
end

function UISubFixedOptionalGift:InitCommand()
	local sid = self:GetWndArg("sid")
	self.pages = self:GetWndArg("pages")
	self._sid = sid
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	local list = self._modelList[modelId]
	self._giftCustomEnum = list[1]
	self._giftCommonEnum = list[2]
	--gModelActivity:ReqActivityConfigData(sid)
	self:OnActivityConfigData()
end

function UISubFixedOptionalGift:CreateSelGiftList(trans,list,maxList, canScroll)
	local key = trans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		local listType = maxList and UIItemList.WRAP
		uiList:Create(trans,list,function(...) self:OnDrawItemCell(...) end,listType)
		if listType then
			uiList:EnableScroll(canScroll or true,true)
		end
	end
end

function UISubFixedOptionalGift:InitEvent()
	self._modelList = {
		-- [ModelActivity.BAND_THEME] = {ModelActivity.BAND_THEME_GIFT_CUSTOM,ModelActivity.BAND_THEME_GIFT_COMMON},
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_57] = {ModelActivity.NEWYEAR2022_ITEM_2,ModelActivity.NEWYEAR2022_ITEM_3},
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_61] = {ModelActivity.FASHION_ITEM_4,ModelActivity.FASHION_ITEM_5},
		[ModelActivity.MODEL_ACTIVITY_TYPE_68] = {ModelActivity.KING_STREET_1,ModelActivity.KING_STREET_2},
		-- [ModelActivity.SUMMER_DAY] = {ModelActivity.BAND_THEME_GIFT_CUSTOM,ModelActivity.BAND_THEME_GIFT_COMMON},

	}
end

function UISubFixedOptionalGift:GetCommonExpendType(itemdata)
	local expendType = itemdata.expendType
	if not expendType or expendType == 0 then
		local expend2 = itemdata.expend2
		local expend2List = string.split(expend2,"=")
		local len = #expend2List
		local isFree = expend2List[1] and expend2List[1] == "-1" or false
		if isFree then
			expendType = self.TYPE_BUY_FREE
		else
			if len > 1 then
				expendType = self.TYPE_BUY_ITEM
			else
				expendType = self.TYPE_BUY_RMB
			end
		end
	end
	return expendType
end

function UISubFixedOptionalGift:CreateImmobilization(trans,itemdata)
	for i = 1,3 do
		local data = itemdata[i]
		local showGift = data ~= nil
		local giftTrans = self:FindWndTrans(trans,"Gift"..i)
		if giftTrans and showGift then
			self:CreateGift(giftTrans,data)
		end
		CS.ShowObject(giftTrans,showGift)
	end
end

function UISubFixedOptionalGift:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	end
end

function UISubFixedOptionalGift:OnActivityConfigData()
	local _sid = self._sid
	if not self.pages then
		self.pages = {}
		gModelActivity:OnActivityPageReq(_sid)
	end
	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	if not activityData then return end
	local data = activityData.config
	local giftImg,giftHeroImg,heroImgPos,giftSlogan,giftSloganPos,giftTimePos,giftBgImage
	= data.giftImg,data.giftHeroImg,data.heroImgPos,data.giftSlogan,data.giftSloganPos,data.giftTimePos,data.giftBgImage
	self._callGiftOptional = data.giftOptional
	if LxUiHelper.IsImgPathValid(giftImg) then
		CS.ShowObject(self.mBgImage,true)
		self:SetWndEasyImage(self.mBgImage,giftImg)
	end
	if not string.isempty(giftHeroImg) then
		local imgArr = string.split(giftHeroImg,"=")
		local posParent
		if imgArr[1] == "1" then
			posParent = self.mHeroImg
			self:SetWndEasyImage(posParent,imgArr[2],nil,true)
		else
			posParent = self.mHeroSpine
			local spineName = imgArr[2]
			self:CreateWndSpine(posParent,spineName,spineName.."WndNewYear2022Type5",false)
		end
		if imgArr[3] then
			local flip = tonumber(imgArr[3])
			posParent.localScale = Vector2.New(flip,1)
		end
		CS.ShowObject(posParent,true)
		if not string.isempty(heroImgPos) then
			local arr = string.split(heroImgPos,"|")
			posParent.anchoredPosition = Vector2(tonumber(arr[1]),tonumber(arr[2]))
		end
	end
	if LxUiHelper.IsImgPathValid(giftBgImage) then
		CS.ShowObject(self.mBg,true)
		self:SetWndEasyImage(self.mBg,giftBgImage)
	end
	if LxUiHelper.IsImgPathValid(giftSlogan) then
		CS.ShowObject(self.mTextImg,true)
		self:SetWndEasyImage(self.mTextImg,giftSlogan,nil,true)
		if not string.isempty(giftSloganPos) then
			local giftSloganPosArr = string.split(giftSloganPos,"|")
			self.mTextImg.anchoredPosition = Vector3(tonumber(giftSloganPosArr[1]),tonumber(giftSloganPosArr[2]),0)
		end
	end
	if not string.isempty(giftTimePos) then
		local arr = string.split(giftTimePos,"|")
		self.mTimeBg.anchoredPosition = Vector3(tonumber(arr[1]),tonumber(arr[2]),0)
		local activityDatas = gModelActivity:GetActivityBySid(_sid)
		local _endTime = activityDatas.endTime
		if(_endTime and _endTime ~= -1)then
			self:TimerStop(self._timeKey)
			self:TimerStart(self._timeKey,1,false,-1)
			self:SetTime()
		end
	end
	self:RefreshData()
end

function UISubFixedOptionalGift:BuyClick(itemdata,isSel)
	local canBuy = self:IsBuyNumEmpty(itemdata)
	if not canBuy then
		GF.ShowMessage(ccClientText(23201))
		return
	end
	if isSel then
		local fixReward = itemdata.fixReward or {}
		local costomGiftList = itemdata.customGiftList or {}
		local getItemList = itemdata.getItemList or {}
		local fixLen,costomLen,getItemLen = #fixReward,#costomGiftList,#getItemList
		local isSelFull = fixLen + costomLen == getItemLen
		local firstData = costomGiftList[1]
		if not isSelFull and firstData then
			GF.OpenWnd("UICumSelectNew",{
				sid = self._sid,pageId = firstData.pageId,entryId = firstData.entryId,
				itemIndex = firstData.index,giftData = firstData,title = firstData.title,})
			return
		end
	end
	self:CommonBuyEvent(itemdata)
end

function UISubFixedOptionalGift:OnDrawCustomCell(list,item,itemdata,itempos)
	local Custom = self:FindWndTrans(item,"Custom")
	local Immobilization = self:FindWndTrans(item,"Immobilization")
	local isSel = itemdata.isSel
	CS.ShowObject(Custom,isSel)
	CS.ShowObject(Immobilization,not isSel)
	local height = item.sizeDelta.y
	local isShow
	if isSel then
		isShow = self._callGiftOptional ~= self.HAVE_GIFT_NO_SEL
		CS.ShowObject(item, isShow)
		if not isShow then
			return
		end

		self:CreateCustom(Custom,itemdata)
		LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
	else
		isShow = self._callGiftOptional ~= self.HAVE_SEL_NO_GIFT
		CS.ShowObject(item, isShow)
		if not isShow then
			return
		end

		self:CreateImmobilization(Immobilization,itemdata)
		LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
	end
end

function UISubFixedOptionalGift:CommonBuyEvent(itemdata)
	local expendType = self:GetCommonExpendType(itemdata)
	local pageId,entryId = itemdata.pageId,itemdata.entryId
	local expend2 = itemdata.expend2
	local expend2Info =  string.split(expend2,"=")
	if expend2 == "" then
		expendType = self.TYPE_BUY_FREE
	end
	local itemId = tonumber(expend2Info[2])
	local callFunc
	local setTextStr
	local isFreeBuy = expendType == self.TYPE_BUY_FREE
	if expendType == self.TYPE_BUY_FREE then
		callFunc = function()
			gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId,entryId)
		end
		setTextStr = ccClientText(11913)
	elseif expendType == self.TYPE_BUY_ITEM then
		callFunc = function()
			local dia = gModelItem:GetNumByRefId(itemId)
			local itemName = gModelItem:GetNameByRefId(itemId)
			local value = tonumber(expend2Info[3])
			-- 钻石购买
			local func = function()
				if dia >= value then
					gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId,entryId)
				else
					gModelGeneral:OpenGetWayWnd({itemId = itemId})
				end
			end
			GF.OpenWnd("UIOrdinTip",{refId = 110005,func = func,para = {value .. itemName},consume = {value, itemId}})
		end
		setTextStr = tonumber(expend2Info[3])
	elseif expendType == self.TYPE_BUY_RMB then
		local expendId = tonumber(expend2Info[1])
		--local rmb = gModelPay:GetRMBValueByWelfareId(expendId)
		setTextStr =gModelPay:GetShowByWelfareId(expendId) --string.replace(ccClientText(21718),rmb)
		callFunc = function()
			gModelPay:GiftPayCtrl(entryId,expendId,ModelPay.PAY_TYPE_ACTIVITY,nil,self._sid,pageId)
		end
	end
	local buyNum = itemdata.buyNum
	local buyCountText = string.replace(ccClientText(23202), buyNum)
	local showItemList
	if itemdata.isSel then
		showItemList = itemdata.getItemList
	else
		showItemList = itemdata.fixReward
	end
	GF.OpenWnd("UIGiftBuyPop", {
		title = itemdata.title,
		desc = buyCountText,
		payStr = setTextStr,
		payItemId = not isFreeBuy and itemId or nil,
		payFunc = callFunc,
		itemList = showItemList,
		sid = self._sid
	})
end

function UISubFixedOptionalGift:ChangeCustomList(customList,status)
	local list = {}
	for i,v in ipairs(customList or {}) do
		v.status = status
		table.insert(list,v)
	end
	return list
end

function UISubFixedOptionalGift:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function(pb) self:RefreshData() end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:RefreshData() end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb.pages)
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end

function UISubFixedOptionalGift:CreateGift(trans,itemdata)
	local BgImg = self:FindWndTrans(trans,"BgImg")
	local Bg = self:FindWndTrans(trans,"Bg")
	local BuyCount = self:FindWndTrans(trans,"BuyCount")
	local title = self:FindWndTrans(trans,"title")
	local btn = self:FindWndTrans(trans,"btn")
	local btn1 = self:FindWndTrans(trans,"btn1")
	local rewardList1 = self:FindWndTrans(trans,"rewardList1")
	local rewardList2 = self:FindWndTrans(trans,"rewardList2")
	local DiscountImg = self:FindWndTrans(trans,"DiscountImg")
	local DiscountTxt = self:FindWndTrans(DiscountImg,"DiscountTxt")
	local redPoint = self:FindWndTrans(trans,"redPoint")
	local Show = self:FindWndTrans(trans,"Show")
	local maskTrans = self:FindWndTrans(trans, "mask")
	local ShowZSImg = self:FindWndTrans(trans, "ShowZSImg")
	local ZSNum = self:FindWndTrans(ShowZSImg, "ZSNum")
	local EffRoot = self:FindWndTrans(trans, "EffRoot")

	local buyNum = itemdata.buyNum
	local valuePercent  = itemdata.valuePercent			-- 价格百分比
	local isHave = not string.isempty(valuePercent) and buyNum > 0
	if isHave then
		local show = true
		if buyNum <= 0 then show = false end
		if valuePercent == "0" then show = false end
		if show then
			self:SetWndText(DiscountTxt,valuePercent)
		end
		isHave = show
	end
	CS.ShowObject(DiscountImg,isHave)

	local dataTableData = string.split(itemdata.moreInfo,";")
	local zsNum = tonumber(dataTableData[5] or 0)
	local showZSImg = zsNum and zsNum ~= 0 or false
	CS.ShowObject(ShowZSImg,showZSImg)
	if showZSImg then
		self:SetWndText(ZSNum,zsNum)
	end

	local buyEmpty = buyNum <= 0
	CS.ShowObject(Show,buyEmpty)
	CS.ShowObject(maskTrans,buyEmpty)

	local typeId = itemdata.typeId						-- 类型ID=礼包卡底资源图=售卖文本字色=售卖文本描边色
	--self:SetActivityTitleImage(BgImg,typeId)
	self:SetWndEasyImage(Bg,itemdata.desc,function() CS.ShowObject(Bg,true) end)

	local buyCountText = string.replace(ccClientText(20810), buyNum)
	self:SetWndText(BuyCount,buyCountText)
	self:SetWndText(title,itemdata.title)

	local itemList = itemdata.commonGiftList
	local showMaxList = #itemList > 3
	local RewardList = showMaxList and rewardList2 or rewardList1
	CS.ShowObject(rewardList1, not showMaxList)
	CS.ShowObject(rewardList2, showMaxList)
	self:CreateSelGiftList(RewardList,itemList,nil, false)

	local expend2 = itemdata.expend2
	local expend2List = string.split(expend2,"=")
	local len = #expend2List
	local isFree = expend2List[1] and expend2List[1] == "-1" or false
	CS.ShowObject(redPoint,false)

	if EffRoot then
		local InstanceID = EffRoot:GetInstanceID()
		self:DestroyWndEffectByKey(InstanceID)
		local isShow = isFree and buyNum > 0
		if isShow then
			local bgEff = "fx_libaomianfeilingqu"
			self:CreateWndEffect(EffRoot,bgEff,InstanceID,100,false,false)
		end
	end

	local txt
	local showIconImg = false
	if isFree then
		txt = ccClientText(11913)
	else
		showIconImg = len > 1
		if showIconImg then
			txt = expend2List[3]
		else
			--local rmb = gModelPay:GetRMBValueByWelfareId(tonumber(expend2))
			txt =gModelPay:GetShowByWelfareId(tonumber(expend2)) -- string.replace(ccClientText(21718),rmb)
		end
	end

	CS.ShowObject(btn1,false)
	CS.ShowObject(btn,false)
	if not buyEmpty then
		local BuyBtnTxt
		if showIconImg then
			CS.ShowObject(btn1,true)
			BuyBtnTxt = self:FindWndTrans(btn1,"Content/text1")
			local icon = self:FindWndTrans(btn1,"Content/Image")
			local refId = tonumber(expend2List[2])
			local iconImg = gModelItem:GetItemImgByRefId(refId)
			self:SetWndEasyImage(icon,iconImg)
		else
			CS.ShowObject(btn,true)
			BuyBtnTxt = self:FindWndTrans(btn,"text")
		end
		self:SetWndText(BuyBtnTxt,txt)
	end

	self:SetWndClick(trans,function()
		self:BuyClick(itemdata)
	end)
end

------------------------------------------------------------------
return UISubFixedOptionalGift