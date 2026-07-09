---
--- Created by Administrator.
--- DateTime: 2023/10/17 19:44:44
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubCumGift:LChildWnd
local UISubCumGift = LxWndClass("UISubCumGift", LChildWnd)

UISubCumGift.TYPE_BUY_FREE = 0
UISubCumGift.TYPE_BUY_ITEM = 1
UISubCumGift.TYPE_BUY_RMB = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubCumGift:UISubCumGift()
	---@type table<number,CommonIcon>
	self._uiCommonList 	= {}
	self._timer = {}

	self._getBtnEff = "fx_anniu_02"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubCumGift:OnWndClose()
	if self._timer then
		for key, timer in pairs(self._timer) do
			LxTimer.DelayTimeStop(timer)
		end
		self._timer = {}
	end

	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil

	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubCumGift:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubCumGift:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
end

function UISubCumGift:GetCommonExpendType(itemdata)
	local expendType = itemdata.expendType
	if not expendType or expendType == 0 then
		local expend2 = itemdata.expend2
		local expend2List = string.split(expend2,"=")
		local len = #expend2List
		local isFree = expend2List[1] and expend2List[1] == "-1" or false
		if isFree then
			expendType = UISubCumGift.TYPE_BUY_FREE
		else
			if len > 1 then
				expendType = UISubCumGift.TYPE_BUY_ITEM
			else
				expendType = UISubCumGift.TYPE_BUY_RMB
			end
		end
	end
	return expendType
end

function UISubCumGift:InitData()
	self._sid 	  = self:GetWndArg("sid")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	self._pageId 	= self:GetWndArg("pageId") or 1

	self._pageData = {}
	self._pages    = {}
	self._giftList = {}
	self._drawItemData = {}
	gModelActivity:ReqActivityConfigData(self._sid)
end

function UISubCumGift:GetPayType(expendType,expend2)
	local txt
	local showIconImg = false
	if expendType == UISubCumGift.TYPE_BUY_FREE then
		txt = ccClientText(11913)
	elseif expendType == UISubCumGift.TYPE_BUY_ITEM then
		showIconImg = true
		local expend2Info =  string.split(expend2,"=")
		txt = expend2Info[3]
	elseif expendType == UISubCumGift.TYPE_BUY_RMB then
		--local rmb = gModelPay:GetRMBValueByWelfareId(tonumber(expend2))
		txt = gModelPay:GetShowByWelfareId(tonumber(expend2)) --string.replace(ccClientText(21718),rmb)
	end
	return txt,showIconImg
end

function UISubCumGift:ChangeCustomList(customList,status)
	local list = {}
	for i,v in ipairs(customList or {}) do
		v.status = status
		table.insert(list,v)
	end
	return list
end

function UISubCumGift:GetCustomList()
	local list = {}
	local pageData = self._giftList
	local pageId   = self._pageId
	if not pageData then
		printInfoN("self._pages[self._pageId] is not find, self._pageId = " .. pageId)
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

	self._activityResetTime = -1
	local resetRemainTime = -1

	local selList = {}
	local entryList = pageData.entry or {}
	for i,v in ipairs(entryList) do
		local entryId = v.entryId
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,entryId)
		local MarketData = v.MarketData
		resetRemainTime = MarketData.resetRemainTime
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

	if resetRemainTime then
		self._activityResetTime = resetRemainTime
	end

	return selList
end

function UISubCumGift:CreateCustom(trans,itemdata)
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

	--local TitleImg = self:FindWndTrans(trans,"TitleImg")
	local Txt = self:FindWndTrans(trans,"TxtBg/Txt")

	local CountDownTxt = self:FindWndTrans(trans,"CountDownTxt")

	--self:SetWndEasyImage(TitleImg,itemdata.icon)
	self:SetWndText(Txt,itemdata.title)

	local buyNum = itemdata.buyNum
	local buyCountText = string.replace(ccClientText(18600), buyNum)
	self:SetWndText(CountDownTxt,buyCountText)

	local fixReward = itemdata.fixReward
	self:CreateSelGiftList(fixRewardList,fixReward)

	local isEmpty = buyNum < 1
	local show = not isEmpty

	local customGiftList = self:ChangeCustomList(itemdata.customGiftList,isEmpty)
	self:CreateSelGiftList(RewardList,customGiftList, true)


	CS.ShowObject(OverImg,isEmpty)
	CS.ShowObject(BuyBtn,show)
	CS.ShowObject(CountDownTxt,show)

	local expendType = itemdata.expendType
	local expend2 = itemdata.expend2
	local txt,showIconImg = self:GetPayType(expendType,expend2)
	CS.ShowObject(Image,showIconImg)
	local expend2Info =  string.split(expend2,"=")
	if(expend2Info and expend2Info[2])then
		local iconPath = gModelItem:GetItemIconByRefId(tonumber(expend2Info[2]))
		self:SetWndEasyImage(Image,iconPath)
	end

	self:SetWndText(BuyBtnTxt,txt)

	local effKey = trans:GetInstanceID()
	self:DestroyWndEffectByKey(effKey)
	local isFree = expendType == self.TYPE_BUY_FREE
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

function UISubCumGift:InitEvent()
	self:SetWndClick(self.mHelpBtn, function() self:OnClickHelp() end)
end

function UISubCumGift:OnDrawCustomCell(list,item,itemdata,itempos)
	local Custom = self:FindWndTrans(item,"Custom")
	local Immobilization = self:FindWndTrans(item,"Immobilization")
	local isSel = true --itemdata.isSel
	CS.ShowObject(Custom,isSel)
	CS.ShowObject(Immobilization,not isSel)
	local height = item.sizeDelta.y
	local isShow = true
	--if isSel then
		CS.ShowObject(item, isShow)
		self:CreateCustom(Custom,itemdata)
		LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
	--else
		--isShow = self._callGiftOptional ~= UIActNewHeroTheme.HAVE_SEL_NO_GIFT
		--CS.ShowObject(item, isShow)
		--if not isShow then
		--	return
		--end
        --
		--self:CreateImmobilization(Immobilization,itemdata)
		--LxUiHelper.SetSizeWithCurAnchor(item, 1, height)
	--end
end
--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UISubCumGift:OnActivityPageResp(pb)
	local sid = pb.sid
	if self._sid ~= sid then return end

	for k,v in ipairs(pb.pages) do
		self._pageData[v.pageId] = gModelActivity:GenerateActivePageDataFromPb(v)
	end

	self._pages    = {}
	for k,v in ipairs(self._pageData) do
		table.insert(self._pages, v)
	end

	self:RefreshData()
end

function UISubCumGift:RefreshEndTimeText()
	-- 活动剩余时间
	local curTime = GetTimestamp()
	local time = self._activityEndTime - curTime
	self:CreateTimer("actEndTime",self._activityEndTime,self.mTimeText,ccClientText(15506))
	local isShow = time > 0
	CS.ShowObject(self.mTimeBg,isShow)

	if isShow then
		CS.ShowObject(self.mTimeBg2,false)
		return
	end

	-- 活动重置时间
	time = self._activityResetTime - curTime
	self:CreateTimer("actResetTime",self._activityResetTime,self.mTimeText2,ccClientText(15505))
	isShow = time > 0
	CS.ShowObject(self.mTimeBg2,isShow)
end



--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UISubCumGift:CreateTimer(key,times,trans,strText)
	self:ClearTimer(key)
	self:SetTimeStr(times,trans,strText,key)
	self._timer[key] = LxTimer.LoopTimeCall(function()
		self:SetTimeStr(times,trans,strText,key)
	end, 1, false, -1)
end
--#####################################################################################################################
--## ItemList #########################################################################################################
--#####################################################################################################################
function UISubCumGift:RefreshItemListData()
	if not self._giftList then
		printInfoN("self._pages[self._pageId] is not find, self._pageId = " .. self._pageId)
		return
	end

	self._drawItemData = self:GetCustomList()
	self:RefreshEndTimeText()
	self:InitCustomList()
end

function UISubCumGift:ClearTimer(key)
	local timer = self._timer[key]
	if timer then
		LxTimer.DelayTimeStop(timer)
		self._timer[key] = nil
	end
end

function UISubCumGift:RefreshData()
	if not self._pages then
		LogError("self._pages is not a nil")
		return
	end

	self._giftList = self._pages[self._pageId]
	self:RefreshItemListData()
end

function UISubCumGift:IsBuyNumEmpty(itemdata)
	local buyNum = itemdata.buyNum
	return buyNum > 0
end


function UISubCumGift:SetTimeStr(times,trans,strText,key)
	local time = times - GetTimestamp()
	if time > 0 then
		local timeStr = LUtil.FormatTimeToCn4(time)
		local text = strText .. timeStr
		self:SetWndText(trans,text)
	else
		self:ClearTimer(key)
	end
end

--#####################################################################################################################
--## Top ##############################################################################################################
--#####################################################################################################################
function UISubCumGift:SetTop()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end

	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local data 		=webData.config
	self._actWebConfig = data

	local path		= data.image
	local pos 		= data.descIconPosition

	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTop, path)
	end

	self._title 	= activityData.title
	path			= data.descIcon

	local isImgPathValid = LxUiHelper.IsImgPathValid(path)
	if isImgPathValid then
		self:SetWndEasyImage(self.mTitleImage, path, nil, true)
		if pos then
			self:SetAnchorPos(self.mTitleImage, LxDataHelper.ParseVector2NotEmpty(pos))
		else
			LogError("data.descIconPosition is a nil")
		end
	end
	CS.ShowObject(self.mTitleImage, isImgPathValid)

	self._activityEndTime = activityData.endTime
end

function UISubCumGift:OnClickHelp()
	local config = self._actWebConfig
	local content = config.helpTipsContent
	local title = ccClientText(18607)
	GF.OpenWnd("UIBzTips",{title= title,text = content})
end

function UISubCumGift:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:SetTop()
	self:RefreshData()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UISubCumGift:InitCustomList()
	local list = self._drawItemData
	local itemUIList = self._itemUIList
	if itemUIList then
		itemUIList:RefreshData(list)
	else
		itemUIList = self:GetUIScroll("itemUIList")
		self._itemUIList = itemUIList
		itemUIList:Create(self.mSelGiftList,list,function(...) self:OnDrawCustomCell(...) end,UIItemList.WRAP)
		itemUIList:EnableLoadAnimation(true, 0.03, 1, 2)
		local uiList = itemUIList:GetList()
		uiList:RefreshList(UIListWrap.RefreshMode.Solid)
	end
end

function UISubCumGift:CreateSelGiftList(trans,list,maxList, canScroll)
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

function UISubCumGift:OnDrawItemCell(list,item,itemdata,itempos)
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


function UISubCumGift:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...) self:OnActivityPageResp(...) end)
end

function UISubCumGift:BuyClick(itemdata,isSel)
	local canBuy = self:IsBuyNumEmpty(itemdata)
	if not canBuy then
		GF.ShowMessage(ccClientText(15511))
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

function UISubCumGift:CommonBuyEvent(itemdata)
	local expendType = self:GetCommonExpendType(itemdata)
	local pageId,entryId = itemdata.pageId,itemdata.entryId
	local expend2 = itemdata.expend2
	local expend2Info =  string.split(expend2,"=")
	if expend2 == "" then
		expendType = UISubCumGift.TYPE_BUY_FREE
	end
	local itemId = tonumber(expend2Info[2])
	local callFunc
	local setTextStr
	local isFreeBuy = expendType == UISubCumGift.TYPE_BUY_FREE
	if expendType == UISubCumGift.TYPE_BUY_FREE then
		callFunc = function()
			gModelActivity:OnActivityMarkeyBuyReq(self._sid,pageId,entryId)
		end
		setTextStr = ccClientText(11913)
	elseif expendType == UISubCumGift.TYPE_BUY_ITEM then
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
	elseif expendType == UISubCumGift.TYPE_BUY_RMB then
		local expendId = tonumber(expend2Info[1])
		--local rmb = gModelPay:GetRMBValueByWelfareId(expendId)
		setTextStr = gModelPay:GetShowByWelfareId(expendId) --string.replace(ccClientText(21718),rmb)
		callFunc = function()
			gModelPay:GiftPayCtrl(entryId,expendId,ModelPay.PAY_TYPE_ACTIVITY,nil,self._sid,pageId)
		end
	end
	local buyNum = itemdata.buyNum
	local buyCountText = string.replace(ccClientText(23803), buyNum)
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
	})
end

function UISubCumGift:CreateCommonIcon(data)
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



------------------------------------------------------------------
return UISubCumGift


