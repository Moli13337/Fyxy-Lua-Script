---
--- Created by Administrator.
--- DateTime: 2023/10/10 16:51:29
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPkQukBuyPop:LWnd
local UIPkQukBuyPop = LxWndClass("UIPkQukBuyPop", LWnd)
UIPkQukBuyPop.PAGE_BUY = 1				--档位购买
UIPkQukBuyPop.PAGE_ELITE = 2			--普通战令
UIPkQukBuyPop.PAGE_ADVANCE = 3			--进阶战令
UIPkQukBuyPop.PAGE_SUPER = 4			--豪华战令
UIPkQukBuyPop.QUICK_SHOP = 5			--快捷购买
UIPkQukBuyPop.QUICK_SHOP2 = 6			--快捷购买2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPkQukBuyPop:UIPkQukBuyPop()
	---@type UIIconEasyList
	self._rewardListCls = nil

	self.pages = {}
	self._bGuy = false				--是否购买战令
	self._passKey = "_passQuickBuyKey"
	self._numSliderKey = "_numSliderKey"
	self._delayReqTimeKey = "delayReqTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPkQukBuyPop:OnWndClose()
	if self._rewardListCls then
		self._rewardListCls:Destroy()
		self._rewardListCls = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPkQukBuyPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPkQukBuyPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	--self:DoWndStartScale(0,self.mPop)
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIPkQukBuyPop:ResetBuyRewardIndex()
	local buyNum = self._curSchedule + self._buyNum
	self._curBuyIndex = 1
	for k,v in ipairs(self._rewardList) do
		local goal = v.goal
		if buyNum < goal then
			break
		end

		self._curBuyIndex = k
	end
end


--#####################################################################################################################
--### Count ###########################################################################################################
--#####################################################################################################################
function UIPkQukBuyPop:RefreshCount()
	self._buyNumSlider = self:UIProgressFind(self.mNumSlider,self._numSliderKey,0)
	self._buyNumSlider:SetSliderDelegate(nil)
	self._buyNumSlider:SetSliderDelegate(function(value)
		self:OnValueChange(value)
	end)
	self:OnValueChange(0)
end

function UIPkQukBuyPop:SetTotalBuyContent()
	local price = self._quickBuyCost
	local rewardPrice = self._quickReward.itemNum

	local totalPrice = math.ceil(self._buyNum / rewardPrice * price.itemNum)
	self._totalPrice = totalPrice
	self:RefreshPayText()

	self:SetWndText(self.mBuyNum, self._buyNum)

	local progress = 0
	if self._limitNum>0 then
		progress = self._buyNum/self._limitNum
	end

	self._buyNumSlider:SetSliderDelegate(nil)
	self._buyNumSlider:SetUIProgress(progress)
	self._buyNumSlider:SetSliderDelegate(function (value) self:OnValueChange(value) end)

	local oldBuyRewardIndex = self._curBuyIndex
	self:ResetBuyRewardIndex()
	self:RefreshDescText()
	if oldBuyRewardIndex ~= self._curBuyIndex then
		self:RefreshRewardList()
	end
end

--#####################################################################################################################
--### Server ##########################################################################################################
--#####################################################################################################################
function UIPkQukBuyPop:ResetData(pb)
	local sid = pb.sid
	if(self._sid~=sid)then
		return
	end
	for i, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		self.pages[v.pageId]=page
	end
	self:RefreshData()
end

function UIPkQukBuyPop:OnClickSub()
	if self._buyNum<=self._startSchedule then
		return
	end
	self._buyNum= math.max(self._buyNum-self._defaultChangeValue, self._startSchedule)

	self:SetTotalBuyContent()
end

function UIPkQukBuyPop:OnTimer(key)
	if key == self._passKey then
		self:SetTime()
	elseif key == self._delayReqTimeKey then
		gModelActivity:OnActivityPageReq(self._sid)
	end
end

function UIPkQukBuyPop:RefreshDescText()
	local buyRewardIndex = self._curBuyIndex
	local rewardList 	 = self._rewardList
	local goal = rewardList[buyRewardIndex].goal
	local curHaveNum = self._curSchedule
	local buyNum = goal - curHaveNum
	local str = string.replace(ccClientText(15816), self._itemName, buyNum)

	local needShowExtra = buyRewardIndex < #rewardList
	if needShowExtra then
		local nextGoal = rewardList[buyRewardIndex + 1].goal
		buyNum = nextGoal - curHaveNum - self._buyNum
		str = str..string.replace(ccClientText(15817), buyNum)
	end

	self:SetWndText(self.mDescText, str)
end

function UIPkQukBuyPop:RefreshRewardList()
	local buyRewardIndex = self._curBuyIndex

	local itemList = {}
	for k,v in ipairs(self._rewardList) do
		--普通版奖励
		local reward1 = v.reward1
		for p,q in ipairs(reward1) do
			local itemId = q.itemId
			if not itemList[itemId] then
				itemList[itemId] = {
					itemId		 = q.itemId,
					itemType	 = q.itemType,
					itemNum	 	 = q.itemNum,
				}
			else
				local oldNum = itemList[itemId].itemNum
				itemList[itemId].itemNum = oldNum + q.itemNum
			end
		end

		--进阶版奖励
		local reward2 = v.reward2
		if reward2 then
			for p,q in ipairs(reward2) do
				local itemId = q.itemId
				if not itemList[itemId] then
					itemList[itemId] = {
						itemId		 = q.itemId,
						itemType	 = q.itemType,
						itemNum	 	 = q.itemNum,
					}
				else
					local oldNum = itemList[itemId].itemNum
					itemList[itemId].itemNum = oldNum + q.itemNum
				end
			end
		end

		--豪华版奖励
		local reward3 = v.reward3
		if reward3 then
			for p,q in ipairs(reward3) do
				local itemId = q.itemId
				if not itemList[itemId] then
					itemList[itemId] = {
						itemId		 = q.itemId,
						itemType	 = q.itemType,
						itemNum	 	 = q.itemNum,
					}
				else
					local oldNum = itemList[itemId].itemNum
					itemList[itemId].itemNum = oldNum + q.itemNum
				end
			end
		end

		if k == buyRewardIndex then
			break
		end
	end

	local resultList = {}
	for k,v in pairs(itemList) do
		table.insert(resultList, v)
	end

	local uiList = self._rewardListCls
	if(not uiList)then
		uiList = UIIconEasyList:New(self)
		uiList:Create(self, self.mItemScroll)
		uiList:SetIconParentPath("Root/CommonUI/Icon")
		self._rewardListCls = uiList
		uiList:SetShowNum(false)
		uiList:SetShowExtraNum(true, "NumText")
	end
	uiList:EnableScroll(#resultList > 4,true)
	uiList:RefreshList(resultList)
end

function UIPkQukBuyPop:OnClickAdd()
	if self._buyNum>= self._limitNum then
		return
	end

	self._buyNum= math.min(self._buyNum+ self._defaultChangeValue, self._limitNum)

	self:SetTotalBuyContent()
end

function UIPkQukBuyPop:RefreshPayText()
	if not self._totalPrice then
		return
	end

	local priceNumStr = LUtil.AddNumberSeparate( self._totalPrice)
	self:SetWndText(self.mPayText1, priceNumStr)
end

function UIPkQukBuyPop:OnValueChange(value)
	local num =math.floor(value* self._limitNum)
	if self._limitNum>0 then
		num = math.max(num, self._startSchedule)
		num = math.floor(num / 10 + 0.5) * 10  --计算为10的倍数
	end
	self._buyNum = num

	self:SetTotalBuyContent()
end

function UIPkQukBuyPop:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then
			return
		end
		self:OnActivityConfigData()
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
end

function UIPkQukBuyPop:InitCount()
	CS.ShowObject(self.mCount, true)
	local item = self._quickReward

	local icon = gModelItem:GetItemIconByRefId(item.itemId)
	self:SetWndEasyImage(self.mItemIcon,icon)
	CS.ShowObject(self.mItemIcon, true)

	item = self._quickBuyCost
	CS.ShowObject(self.mPayText1, true)
	icon = gModelItem:GetItemIconByRefId(item.itemId)
	self:SetWndEasyImage(self.mPayIcon,icon)
	self:RefreshPayText()
end

function UIPkQukBuyPop:RefreshData()
	if not self.pages then return end
	if not self.pages[self._quickShopEnum] then return end
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	local data = JSON.decode(activityData.moreInfo)
	self._endTime = (data.playerEndTime and tonumber(data.playerEndTime) / 1000) or tonumber(activityData.endTime)
	local quickData 	= self.pages[self._quickShopEnum].entry[1]
	local quickEntryCfg = gModelActivity:GetWebActivityEntryData(self._sid,quickData.pageId,quickData.entryId)
	if not quickEntryCfg then
		return
	end
	local quickReward 	= LxDataHelper.ParseItem(quickEntryCfg.reward)
	self._quickReward 	= quickReward[1]
	local itemRefId		= self._quickReward.itemId
	self._itemName   	= gModelItem:GetNameByRefId(itemRefId)
	local quickBuyCost 	= LxDataHelper.ParseItem(quickEntryCfg.expend2)
	self._quickBuyCost 	= quickBuyCost[1]

	self:InitSayText()

	local haveSuperPage = false
	if self._modelActivityType == ModelActivity.MODEL_PASSE then
		self._bGuy =  self._bGuys[1] == "1"
		self._bGuy2 =  self._bGuys[2] == "1"
		haveSuperPage = true
	else
		self._bGuy = data.buyPassNum > 0
	end


	local eliteList = self.pages[UIPkQukBuyPop.PAGE_ELITE].entry
	local advanceList = self.pages[UIPkQukBuyPop.PAGE_ADVANCE].entry
	local superList
	if haveSuperPage then
		superList = self.pages[UIPkQukBuyPop.PAGE_SUPER].entry
	end


	self._rewardList = {}
	self._startSchedule = nil
	self._limitNum = nil
	local maxListNum  = #eliteList
	self._curSchedule = 0
	local isClose   = true
	for i, v in ipairs(eliteList) do
		local advanceData 	= advanceList[i]
		local goalData	  	= v.goalData
		local schedule		= goalData.schedules[1]
		local scdle = tonumber(schedule.schedule)
		if(scdle > 0 and self._curSchedule<scdle)then
			self._curSchedule = scdle
		end

		if(goalData.status == 0)then
			isClose = false
			local eliteEntryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
			if not eliteEntryCfg then return end
			local rewardData  	= {
				reward1		  	= LxDataHelper.ParseItem(eliteEntryCfg.reward),
				goalData1	  	= goalData,
				goal   		  	= tonumber(goalData.schedules[1].goal),
			}

			if self._bGuy then
				local advanceEntryCfg = gModelActivity:GetWebActivityEntryData(self._sid,advanceData.pageId,advanceData.entryId)
				rewardData.reward2 = LxDataHelper.ParseItem(advanceEntryCfg.reward)
			end

			if self._bGuy2 and superList and superList[i] then
				local superData 	= superList[i]
				local superEntryCfg = gModelActivity:GetWebActivityEntryData(self._sid,superData.pageId,superData.entryId)
				rewardData.reward3 = LxDataHelper.ParseItem(superEntryCfg.reward)
			end

			table.insert(self._rewardList, rewardData)

			if not self._startSchedule then
				self._startSchedule = rewardData.goal - scdle
			end

			if i == maxListNum then
				self._limitNum = rewardData.goal - self._curSchedule
			end
		end
	end

	if isClose then
		--全部卖完了，关闭
		self:WndClose()
		return
	end

	if not self._buyNum then
		self._buyNum = self._startSchedule
	end

	self:RefreshCount()
	self:InitCount()
	self:RefreshDescText()
	self:RefreshRewardList()
end

--#####################################################################################################################
--### Common ##########################################################################################################
--#####################################################################################################################
function UIPkQukBuyPop:OnActivityConfigData()
	self._defaultChangeValue = 10 --默认变化值
	self:TimerStart(self._delayReqTimeKey,0.3,false,1)
end

function UIPkQukBuyPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mAddBtn,function () self:OnClickAdd() end)
	self:SetWndLongClick(self.mAddBtn,function()
		self:OnClickAdd()
	end,0.2,true)
	self:SetWndClick(self.mSubBtn,function () self:OnClickSub() end)
	self:SetWndLongClick(self.mSubBtn,function()
		self:OnClickSub()
	end,0.2,true)
	self:SetWndClick(self.mNumBg,function () self:OpenKeyboard() end)
	self:SetWndClick(self.mPayBtn, function(...) self:OnClickBuy() end)
end

--#####################################################################################################################
--### Time ############################################################################################################
--#####################################################################################################################
function UIPkQukBuyPop:SetTime()--设置时间
	local time = GetTimestamp()
	local timespan = self._endTime - time

	if(timespan <= 0)then
		self:TimerStop(self._passKey)
		return false
	end

	local timeStr
	if timespan > 86400 then
		timeStr = LUtil.GetCurTimeDayNum(timespan)..ccClientText(10304)
	else
		timeStr = "\n"..LUtil.FormatTimespanNumber(timespan)
	end

	local str  = string.replace(ccClientText(15814), timeStr, self._itemName)
	self:SetWndText(self.mSayDescText,str)
	return true
end

function UIPkQukBuyPop:InitSayText()
	local succeed = self:SetTime()
	if not succeed then return end

	CS.ShowObject(self.mSayBg, true)

	if not self:IsTimerExist(self._passKey) then
		self:TimerStart(self._passKey,1,false,-1)
	end
end

function UIPkQukBuyPop:OpenKeyboard()
	local min,max,default=0,0,0
	if self._limitNum>0 then
		min = 1
		max = self._limitNum
		default = 1
	end


	local func= function(input,cmd)
		if self:IsWndClosed() then return end

		local num = tonumber(input)
		if num < self._startSchedule and cmd ~= "D" then
			self:SetWndText(self.mBuyNum, num)
			return
		end

		num = math.max(num, self._startSchedule)
		num = math.floor(num / 10 + 0.5) * 10  --计算为10的倍数
		self._buyNum = num
		self:SetTotalBuyContent()
	end

	GF.OpenWndUp("UINuoardUI",
			{minNum = min,maxNum = max,defaultNum = default, inputFunc = func, inputTran = self.mBuyNum})
end

function UIPkQukBuyPop:InitCommand()
	self._sid = self:GetWndArg("sid")
	local _sid = self._sid

	self._modelActivityType = self:GetWndArg("modelActivityType")
	self._bGuys = self:GetWndArg("bGuys")

	local quickShopEnum = UIPkQukBuyPop.QUICK_SHOP
	if self._modelActivityType == ModelActivity.MODEL_PASSE then
		quickShopEnum = UIPkQukBuyPop.QUICK_SHOP2
	end
	self._quickShopEnum = quickShopEnum


	local titleStr = self:GetWndArg("titleStr") or ccClientText(15815)
	self:SetWndText(self.mTitleText, titleStr)

	self._buyNum = nil --购买道具数量
	self._totalPrice = nil
	self._curBuyIndex = 1
	gModelActivity:ReqActivityConfigData(_sid)
end

function UIPkQukBuyPop:OnClickBuy()
	local needNum = self._totalPrice
	local itemId  = self._quickBuyCost.itemId
	local haveNum = gModelItem:GetNumByRefId(itemId)
	if(haveNum < needNum)then
		gModelGeneral:OpenGetWayWnd({itemId = itemId})
		return
	end

	local count = needNum / self._quickBuyCost.itemNum
	local func = function()
		gModelActivity:OnActivityMarkeyBuyReq(self._sid,self._quickShopEnum,1,count)
	end

	local quickReward   =  self._quickReward
	local item = {
		itemId = quickReward.itemId,
		itemType = quickReward.itemType,
		itemNum = self._buyNum,
	}

	local para = {refId = 110012,func = func,para = {needNum}, itemList = {item}, consume=needNum}
	gModelGeneral:OpenUIOrdinTips(para)
end

------------------------------------------------------------------
return UIPkQukBuyPop


