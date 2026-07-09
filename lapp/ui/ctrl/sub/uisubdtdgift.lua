---
--- Created by BY.
--- DateTime: 2023/10/1 21:33:00
---
---活动4 ， 每日特惠
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubDTDGift:LChildWnd
local UISubDTDGift = LxWndClass("UISubDTDGift", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubDTDGift:UISubDTDGift()
	self._integralTimeKey = "_integralTimeKey"
	self._resetClickStateTimeKey = "_resetClickStateTimeKey"
	self._integralGiftLoopScaleKey = "_integralGiftLoopScaleKey"
	self._celliconList = {
		"activity4_cell_1",
		"activity4_cell_2",
		"activity4_cell_3"
	}
	self._celliconBotList = {
		"activity4_cell1",
		"activity4_cell2",
		"activity4_cell3"
	}

	self._textMatList = {
		"OPPOSansRMixB_377351_2",
		"OPPOSansRMixB_48629d_2",
		"OPPOSansRMixB_6f5425_2"
	}

	self._textColorList = {
		"139057FF",
		"133f90FF",
		"734f22FF",
	}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubDTDGift:OnWndClose()
	self:OnDestroyHyper()
	self:ClearCommonIconList(self._uiCommonList)
	if self.timer then
		LxTimer.LoopTimeStop(self.timer)
	end
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubDTDGift:OnCreate()
	LChildWnd.OnCreate(self)
	self._pageIndex = ModelActivity.DAILY_GIFT_TYPE_COMMON				--分页索引
	self._uiCommonList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubDTDGift:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	self:InitEvent()
	self:InitMessage()
	self:InitData()
	-- UIHelper.InitTopInfo(self)
	if  self._isEnus then
		self:SetWndEasyImage(self.mIntegralGiftDescBg,"activity_discount_bg_1_2")
	end
	self:SetWndText(self.mTenHelpText, ccClientText(15630))
	self:SetWndText(self.mTipsText2, ccClientText(15518))
	self:InitTextSizeWithLanguage(self.mTenHelpText, -2)

	if self._isEnus then
		UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mTips)
	end 
	--
	--printInfoN2("----------cjh ---------redpoint--10405111", gModelRedPoint:CheckShowRedPoint(10405111))
end

function UISubDTDGift:SetContent()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end

	--CS.ShowObject(self.mBuyBtn,false)
	local data = webData.config
	local otherJump = data.otherJump
	if not string.isempty(otherJump)then
		local arrs = string.split(otherJump,"|")
		local list = {}
		for i, v in ipairs(arrs) do
			local arr = string.split(v,"=")
			table.insert(list,{des = arr[1],jumpId = tonumber(arr[2])})
		end
		self._otherJump = list
	end
	self:SetInitData()

	local text = data.Text
	if(text)then
		self:SetWndText(self.mTipsText,text)

		local addSize = -2
		local addLine = -30
		if gLGameLanguage:IsJapanRegion() then
			addSize = -4
			addLine = -40
		end

		self:InitTextSizeWithLanguage(self.mTipsText, addSize)
		self:InitTextLineWithLanguage(self.mTipsText, addLine)
	end
	local shopname = data.shopname
	if(shopname)then
		self:SetWndText(self.mGiftText,shopname)
		self:InitTextSizeWithLanguage(self.mGiftText, -2)
		self:InitTextLineWithLanguage(self.mGiftText, -30)
	end

	self._shopIconJump = data.shopIconJump
	local freeIcon,freeIconPosition = data.freeIcon,data.freeIconPosition
	if LxUiHelper.IsImgPathValid(freeIcon) then
		self:SetWndEasyImage(self.mGiftImg,freeIcon,function ()
			CS.ShowObject(self.mGiftImg,true) end,true)
		if not string.isempty(freeIconPosition)then
			self:SetAnchorPos(self.mGiftImg, LxDataHelper.ParseVector2NotEmpty(freeIconPosition))
		end
	end

	local image = data.image
	if LxUiHelper.IsImgPathValid(image) then
		self:SetWndEasyImage(self.mTop,image,nil,false)
	end
	local descIcon = data.descIcon
	local descIconPosition = data.descIconPosition
	if LxUiHelper.IsImgPathValid(descIcon) then
		self:SetWndEasyImage(self.mTextImg,descIcon,function ()
			CS.ShowObject(self.mTextImg,true)
		end,true)
		self:SetAnchorPos(self.mTextImg, LxDataHelper.ParseVector2NotEmpty(descIconPosition))
	end
	local showHelp = data.helpTips == 1
	CS.ShowObject(self.mBtnHelp,showHelp)
	CS.ShowObject(self.mTenHelpText,showHelp)
	CS.ShowObject(self.mHelpBtn,false)

	self:CreateWndEffect(self.mGiftEff,"fx_tehuishangdian","fx_tehuishangdian",100)
	self:RefreshFuncBtnShow()
end

function UISubDTDGift:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:SetContent()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UISubDTDGift:RefreshFuncBtnShow()
	if self._shopIconJump then
		local isShow = gModelFunctionOpen:CheckIsShow(self._shopIconJump)
		CS.ShowObject(self.mGiftImg,isShow)
	end
end

function UISubDTDGift:RefreshIntegralGiftText()
	local nDayTime = LUtil.GetNextDayTimes(GetTimestamp(),1)
	local lostTime = nDayTime - GetTimestamp()
	if lostTime <= 1 then
		--零点重置
		self:TimerStop(self._integralTimeKey)
		self:SetIntegralGift(false)
		return
	end

	local endTime = LUtil.FormatTimespanCn(lostTime)
	endTime = string.replace(ccClientText(15631), endTime)
	self:SetWndText(self.mIntegralGiftDesc, endTime)
	self:InitTextSizeWithLanguage(self.mIntegralGiftDesc, -4)
	self:InitTextLineWithLanguage(self.mIntegralGiftDesc, -15)
end

function UISubDTDGift:OnClickGift()--领取免费礼包
	--local activityData=self.pages[self._pageIndex]
	--local data = JSON.decode(activityData.moreInfo)
	--if(data.freeRewardCnt)then
	--	GF.ShowMessage(ccClientText(15606))
	--	return
	--end
	--local page=self.pages[self._pageIndex]
	--gModelActivity:OnActivitySpecialOpReq(self._sid,page.pageId,0,2)
	local id = self._shopIconJump
	local isOpen = gModelFunctionOpen:CheckIsOpened(id,true)
	if(not isOpen)then
		return
	end
	gModelFunctionOpen:Jump(id,self:GetWndName())
end

function UISubDTDGift:CheckShowIntegralGiftPop(haveIntegralGift)
	local oldHaveIntegralGift = self._oldHaveIntegralGift
	self._oldHaveIntegralGift = haveIntegralGift

	if not self._isClickBuy then
		return
	end

	self:TimerStop(self._resetClickStateTimeKey)
	self:TimerStart(self._resetClickStateTimeKey, 1, false, 1)

	if haveIntegralGift == oldHaveIntegralGift or GF.FindFirstWndByName("UIDTDGiftPop") then
		return
	end

	self._waitOpenIntegralGiftPop = true
end

function UISubDTDGift:RefreshData()
	self:SetInitData()
	local payTextStr = ""
	self._bNoBuyAll = true
	self._buyAllExpend = nil
	self._isOneKeyBuy = true --是否可以一键购买
	local pageData = self.pages[ModelActivity.DAILY_GIFT_TYPE_COMMON]
	if not pageData then
		return
	end
	local list  = {}
	local cost = 0
	local barValue = 0
	local leftTime
	local value = 0
	for i, v in ipairs(pageData.entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		if not entryCfg then
			return
		end
		local curEntry = {
			pageId  = v.pageId,
			entryId = v.entryId,
			title   = entryCfg.name,
			items	= LxDataHelper.SevenParseItems(v.items),
			MarketData = v.MarketData,
			activeMoreInfo = v.moreInfo,
			moreInfo = entryCfg.moreInfo,
		}

		value = value + gModelPay:GetValueByWelfareId(tonumber(v.MarketData.expend2))

		table.insert(list, curEntry)

		local expend1 = v.MarketData.expend1
		local money
		if string.isempty(expend1) then
			money = gModelPay:GetRMBValueByWelfareId(tonumber(v.MarketData.expend2))
		else
			money = tonumber(expend1)
		end

		local personalGoal,personal = v.MarketData.personalGoal,v.MarketData.personal
		cost = cost + money
		if(personalGoal - personal > 0 and self._bNoBuyAll)then
			self._bNoBuyAll = false
		end
		if personalGoal - personal <= 0 then
			if self._isOneKeyBuy then
				self._isOneKeyBuy = false
			end
			local arr = string.split(entryCfg.moreInfo,",")
			if arr[4] then
				barValue = barValue + tonumber(arr[4])
			end
		end
		if not leftTime then
			leftTime = tonumber(v.MarketData.resetRemainTime)
		end
	end

	local symbol = gModelPay:GetMoneySymbol()
	local costStr = string.replace(ccClientText(15602), string.format("%s%s",symbol,value))

	local pageData = JSON.decode(pageData.moreInfo)
	if pageData.buyAllFlag then
		self._buyAllType = 0
	end
	CS.ShowObject(self.mTenDay,self._buyAllType == 0)
	CS.ShowObject(self.mOneDay,self._buyAllType == 1)

	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end

	local data =webData.config

	local buyAllLimit = data.buyAllLimit
	local isShowBuyAll = buyAllLimit ~= 0
	CS.ShowObject(self.mTenDay,isShowBuyAll and self._buyAllType == 0)
	CS.ShowObject(self.mOneDay,isShowBuyAll and self._buyAllType == 1)
	CS.ShowObject(self.mCommonBg,  isShowBuyAll)
	CS.ShowObject(self.mNoBuyAllBg,  not isShowBuyAll)

	local isEnglish = gLGameLanguage:IsUSARegion()
	self._isForeign = isEnglish
	local buyAllTime = 1
	local discount = 0
	if(self._buyAllType == 0)then		--购买10天
		local buyAllDescription = data.buyAllDescription
		if(buyAllDescription)then
			local str = string.gsub(buyAllDescription,"\\n","\n")

			if not isEnglish then
				self:SetWndText(self.mPriceText,str)
			else
				self:SetWndText(self.mPriceTextE,str)
				self:InitTextLineWithLanguage(self.mPriceTextE, -30)
				self:InitTextSizeWithLanguage(self.mPriceTextE, -2)
			end
			CS.ShowObject(self.mPriceText, not isEnglish)
			CS.ShowObject(self.mTenImage, not isEnglish)
			CS.ShowObject(self.mPriceTextE,  isEnglish)
			CS.ShowObject(self.mTenImageE,  isEnglish)
		end
		local buyAllJump = data.buyAllJump
		if(buyAllJump and buyAllJump~="")then
			self:SetWndText(self.mSkipText,buyAllJump)
			self:InitTextSizeWithLanguage(self.mSkipText, -4)
			local list = string.split(data.buyAllFunctionOpen,",") or {}
			if(#list>0)then
				self:SetSkipFun(self.mSkipText,list)
			end
		end
	elseif(self._buyAllType == 1)then		--一键购买
		local buyAllDescription2 = data.buyAllDescription2

		if(buyAllDescription2)then
			local str = string.gsub(buyAllDescription2,"\\n",'\n')
			self:SetWndText(self.mOneDesText,str)
		end
		local buyAllJump2,buyAllFunctionOpen2,scheduleBuyAll,scheduleUnlock
		= data.buyAllJump2,data.buyAllFunctionOpen2, data.scheduleBuyAll,data.scheduleUnlock
		if not string.isempty(buyAllJump2) then
			local str = string.gsub(buyAllJump2,"\\n",'\n')
			self:SetWndText(self.mOneSkipText,str)
			self:InitTextSizeWithLanguage(self.mOneSkipText, -4)
			if not string.isempty(buyAllFunctionOpen2) then
				local list = string.split(buyAllFunctionOpen2,",") or {}
				if(#list > 0)then
					self:SetSkipFun(self.mOneSkipText,list)
				end
			end
		end
		local isShowBar = scheduleBuyAll and scheduleBuyAll > 0
		CS.ShowObject(self.mBuyBar,isShowBar)
		if not string.isempty(scheduleUnlock) then
			CS.ShowObject(self.mBuyMag,true)
			local arr = string.split(scheduleUnlock,"|")
			local dataList = {}
			local initValue = 0
			for i, v in ipairs(arr) do
				local item = self:FindWndTrans(self.mBuyMag,"BuyItem"..i)
				local gold = tonumber(v)
				self:RefreshBuyItem(item,gold,barValue,i)
				if i == 1 then
					initValue = gold
				else
					table.insert(dataList,gold)
				end
			end
			if isShowBar then
				self.mBuyBar.maxValue = 1
				barValue = LUtil.GetCurPercent(dataList,barValue,initValue)
				self.mBuyBar.value = barValue
			end
		end
	end
	if(self._buyAllType == 0)then
		buyAllTime = data.buyAllTime
		self._buyAllExpend = data.buyAllExpend
	else
		local _buyAllStr = data.buyAllExpend2
		local _buyAllArr = string.split(_buyAllStr,";")
		for i, v in ipairs(_buyAllArr) do
			local costArr = string.split(v,"=")
			local costNum = tonumber(costArr[1])
			if(costNum == cost)then
				self._buyAllExpend = tonumber(costArr[2])
				discount = tonumber(costArr[3])
				break
			end
		end
	end

	if self._buyAllExpend then
		--local priceCost = gModelPay:GetRMBValueByWelfareId(tonumber(self._buyAllExpend))
		payTextStr =gModelPay:GetShowByWelfareId(tonumber(self._buyAllExpend)) -- string.replace(ccClientText(15603),priceCost)
		payTextStr =string.replace(ccClientText(15603),payTextStr)
	end

	local buyEnd = false
	local isGray = false
	self._bBuyAll = false
	if(pageData.buyAllFlag)then
		self._bBuyAll = true
		payTextStr = ccClientText(15623)
		-- costStr = string.replace(ccClientText(15622),pageData.buyAllFlag)
		buyEnd = true
	elseif(self._bNoBuyAll)then
		local temp = gModelPay:FormatValueShow(cost * buyAllTime)
		-- costStr = string.replace(ccClientText(15602),temp)
		isGray = true
		buyEnd = true
	else
		local temp = gModelPay:FormatValueShow(cost * buyAllTime)
		-- costStr = string.replace(ccClientText(15602),temp)
	end
	local isShowBuy = false
	if self._bBuyAll then
		if not self._bNoBuyAll then
			payTextStr = ccClientText(11204)
		end
		isShowBuy = not self._bNoBuyAll
	else
		isShowBuy = not buyEnd
	end

	local isShowUpRed = false --discount > 0 and isShowBuy
	CS.ShowObject(self.mUpRedImg,isShowUpRed)
	if(isShowUpRed)then
		self:SetWndText(self.mUpRedTxt,discount.."%")
	end

	if(self._uiList)then
		self._uiList:RefreshData(list)
	else
		self._uiList = self:GetUIScroll("cell")
		self._uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
	end


	local haveIntegralGift = self:CheckHaveIntegralGift()

	local isShowCost = not gLGameLanguage:IsForeignRegion()
	-- isShowCost = false

	-- CS.ShowObject(self.mBuyEndImg1,self._bNoBuyAll and self._buyAllType == 1 and not haveIntegralGift)
	CS.ShowObject(self.mCostImg,isShowCost and self._buyAllExpend and not haveIntegralGift)
	CS.ShowObject(self.mCostText,isShowCost and self._buyAllExpend and not haveIntegralGift)
	CS.ShowObject(self.mCostText0,isShowCost and self._buyAllExpend and not haveIntegralGift)
	CS.ShowObject(self.mBuyEndImg,not isShowBuy and self._buyAllType == 0 and not haveIntegralGift)
	self:SetWndText(self.mCostText,costStr)
	self:SetWndText(self.mCostText0,costStr)
	-- CS.ShowObject(self.mBuyBtn,isShowBuy)
	CS.ShowObject(self.mBuyBtn0,isShowBuy)
	CS.ShowObject(self.mRedWire,not self._bBuyAll)
	CS.ShowObject(self.mRedWire0,not self._bBuyAll)
	self:SetWndButtonText(self.mBuyBtn,payTextStr)
	self:SetWndButtonGray(self.mBuyBtn,not self._isOneKeyBuy or isGray)
	self:SetWndButtonText(self.mBuyBtn0,payTextStr)
	self:SetWndButtonGray(self.mBuyBtn0,not self._isOneKeyBuy or isGray)
	-- CS.ShowObject(self.mCostImg, not (not self._isOneKeyBuy or isGray))

	self:SetIntegralGift(haveIntegralGift)
	self:CheckShowIntegralGiftPop(haveIntegralGift)

	if gLGameLanguage:IsKoreaRegion() then
		local text = ccClientText(156)
		if not string.isempty(text) then
			self:SetWndText(self.mOneBuyTipsText, text)
			self:SetWndText(self.mTenBuyTipsText, text)
			CS.ShowObject(self.mOneBuyTipsText, true)
			CS.ShowObject(self.mTenBuyTipsText, true)
		end
	end

	if self.timer then
		LxTimer.LoopTimeStop(self.timer)
	end
	local endTime = tonumber(leftTime)
	self.timer = LxTimer.LoopTimeCall(function()
		local time = endTime - math.round2(GetTimestamp())
		local s = ccClientText(15505) .. "<color=#139057>" .. LUtil.FormatTimeStr1(time) .. "</color>"
		self:SetWndText(self.mTimeText, s)
	end, 1, true)
end

function UISubDTDGift:ListItem(list,item, itemdata, itempos)
	local bgImg = self:FindWndTrans(item, "bgImg")
	local botImg = self:FindWndTrans(item, "botImg")
	local title = CS.FindTrans(item,"Title")
	local UpRedImg = CS.FindTrans(item,"UpRedImg")
	local reward1 = CS.FindTrans(item,"Reward1")
	local rewardList = CS.FindTrans(item,"RewardList")
	local numText = CS.FindTrans(item,"NumText")
	local bgEn 		= self:FindWndTrans(item, "bgEn")
	local numTextEn = self:FindWndTrans(bgEn, "NumTextEn")
	local payText = CS.FindTrans(item,"XUIText")
	local ShowTrans = CS.FindTrans(item,"Show")

	local num = itempos % 3
	num = num == 0 and 3 or num
	local bgStr = self._celliconList[num] or ""
	self:SetWndEasyImage(bgImg,bgStr)
	self:SetWndEasyImage(botImg, self._celliconBotList[num] or "")
	self:SetWndText(title,itemdata.title)
	local titleColor = self._textColorList[num]
	if not string.isempty(titleColor) then
		self:SetXUITextTransColor(title, titleColor)
	end
	self:InitTextSizeWithLanguage(title, -4)
	self:InitTextLineWithLanguage(title, -30)

	local showRed = false
	if UpRedImg then
		local dataTableData = string.split(itemdata.moreInfo,",")
		local upNum = dataTableData[3]
		if not string.isempty(upNum) then
			local UpRedTxt = self:FindWndTrans(UpRedImg,"UpRedTxt")
			if UpRedTxt then
				local str = upNum .. "%"
				self:SetWndText(UpRedTxt,str)
			end
			showRed = true
		end
	end

	local list = itemdata.items
	local reward1Data = list[1]
	self:RewardListItem(nil, reward1, reward1Data)
	table.remove(list, 1)
	local listData = list
	local uilist = self:GetUIScroll(item:GetInstanceID())
	uilist:Create(rewardList,listData,function (...) self:RewardListItem(...) end)
	uilist:EnableScroll(true,false)

	local bBuy = false
	local personalGoal,personal = itemdata.MarketData.personalGoal,itemdata.MarketData.personal
	if(personalGoal - personal>0)then
		bBuy = true
	end

	local addLine,addSize = 0,0
	local numTextStr = string.replace(ccClientText(15600),personalGoal-personal)
	if gLGameLanguage:IsForeignRegion() then
		addSize = -2
		addLine = -30
		if gLGameLanguage:IsFrenchVersion() then
			addLine = -50
		end
	end
	self:SetWndText(numText,numTextStr)
	self:InitTextSizeWithLanguage(numText, addSize)
	self:InitTextLineWithLanguage(numText, addLine)

	local numTextStr = string.replace(ccClientText(15600),personalGoal-personal)
	if self._isForeign then
		self:SetWndText(numTextEn,numTextStr)

		local addLine = -30
		if gLGameLanguage:IsFrenchVersion() then
			addLine = -50
		end
		self:InitTextSizeWithLanguage(numTextEn, -2)
		self:InitTextLineWithLanguage(numTextEn, addLine)
	else
		self:SetWndText(numText,numTextStr)
	end
	CS.ShowObject(numText,not self._isForeign)
	CS.ShowObject(bgEn, self._isForeign)

	local buyStr = ""
	local buyEnd = false
	if(bBuy)then
		if(self._bBuyAll)then
			buyStr = ccClientText(15617)
			showRed = false
		else
			buyStr =gModelPay:GetShowByWelfareId(tonumber(itemdata.MarketData.expend2))
			showRed = true
		end
	else
		buyStr = ccClientText(15618)
		buyEnd = true
		showRed = false
	end
	CS.ShowObject(UpRedImg,showRed)
	self:SetWndText(payText,buyStr)
	CS.ShowObject(ShowTrans,buyEnd)
	self:SetWndClick(item, function(...)
		if(bBuy)then
			self:OnClickPay(itemdata)
		else
			GF.ShowMessage(ccClientText(15606))
		end
	end)
end

function UISubDTDGift:SetIntegralGift(isShow)
	CS.ShowObject(self.mIntegralGift, isShow)
	self:SetIntegralGiftDescTween(isShow)
	if not isShow then
		self:TimerStop(self._integralTimeKey)
		return
	end

	local timeKey = self._integralTimeKey
	if not self:IsTimerExist(timeKey) then
		self:TimerStart(timeKey, 1, false, -1)
	end

	self:RefreshIntegralGiftText()
end

function UISubDTDGift:OnTimer(key)
	if key == self._integralTimeKey then
		self:RefreshIntegralGiftText()
	elseif key == self._resetClickStateTimeKey then
		self._isClickBuy = false
	end
end

function UISubDTDGift:OnClickOneBuy()
	local pageData = self.pages[self._pageIndex]
	local data = JSON.decode(pageData.moreInfo)
	if self._bBuyAll and not self._bNoBuyAll then
		local pageId
		for i,v in ipairs(pageData.entry) do
			if pageId then break end
			pageId = v.pageId
		end
		self._isClickBuy = true
		gModelActivity:OnActivitySpecialOpReq(self._sid,pageId,0,3)
		return
	end
	if(data.buyAllFlag)then
		GF.ShowMessage(ccClientText(15605))
		return
	end
	if(self._bNoBuyAll)then
		GF.ShowMessage(ccClientText(15621))
		return
	end
	if not self._isOneKeyBuy then
		GF.ShowMessage(ccClientText(15629))
		return
	end
	local bBuy=true
	local list = pageData.entry
	local entryId=""
	local j = 1
	for i, v in ipairs(list) do
		local personalGoal,personal=v.MarketData.personalGoal,v.MarketData.personal
		if(personalGoal-personal>0)then
			if(j==1)then
				entryId = v.entryId
			else
				entryId = entryId.."#"..v.entryId
			end
			j=j+1
		end
	end
	if(not bBuy)then
		GF.ShowMessage(ccClientText(15605))
		return
	end
	self._isClickBuy = true
	gModelPay:GiftPayCtrl(entryId,self._buyAllExpend,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,pageData.pageId)
end

function UISubDTDGift:InitEvent()
	self:SetWndClick(self.mBuyBtn, function(...) self:OnClickOneBuy() end)
	self:SetWndClick(self.mBuyBtn0, function(...) self:OnClickOneBuy() end)
	self:SetWndClick(self.mTenHelpText, function(...) UIHelper.OnClickHelpBtn(self._sid) end,LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mBtnHelp, function(...) UIHelper.OnClickHelpBtn(self._sid) end,LSoundConst.CLICK_ERROR_COMMON)
	self:SetWndClick(self.mGiftImg, function(...) self:OnClickGift() end)
	self:SetWndClick(self.mIntegralGift, function() self:OnClickIntegralGift() end)
end

function UISubDTDGift:OnClickHyperFun(jump)
	local id = tonumber(jump)
	local isOpen = gModelFunctionOpen:CheckIsOpened(id,true)
	if(not isOpen)then
		return
	end
	gModelFunctionOpen:Jump(id,self:GetWndName())
end

function UISubDTDGift:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)

	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local activities = pb.activities
		for i, v in ipairs(activities) do
			if(v.sid == self._sid and v.status ~= 3)then
				gModelActivity:OnActivityPageReq(self._sid)
				return
			end
		end
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		local activity = pb.activity
		if(activity.sid == self._sid and activity.status ~= 3)then
			gModelActivity:OnActivityPageReq(self._sid)
		end
	end)

	self:WndEventRecv(EventNames.REFRESH_FUNCTION_STATE,function ()
		self:RefreshFuncBtnShow()
	end)

	self:WndEventRecv(EventNames.ON_WND_CLOSE,function (...)
		self:OnTargetWndClose(...)
	end)
end

function UISubDTDGift:OnDestroyHyper()
	if(not self._uiHyper)then
		return
	end
	self._uiHyper:Destroy()
end

function UISubDTDGift:OnClickIntegralGift()
	local sid = self._sid
	GF.OpenWnd("UIDTDGiftPop",{sid = sid})
end

function UISubDTDGift:SetIntegralGiftDescTween(isShow)
	local seqKey = self._integralGiftLoopScaleKey
	local tween = self:TweenSeqFind(seqKey)
	if not isShow then
		if tween then
			self:TweenSeqKill(seqKey)
		end
		return
	end

	if not tween then
		self:TweenSeq_DefalutScale(seqKey,self.mIntegralGiftDescBg,
				{x = 0.9,y = 0.9,z = 0.9,time = 1,recover = true})
	end
end

function UISubDTDGift:RewardListItem(list, item, itemdata, itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local root = self:FindWndTrans(item,"itemRoot/Icon")
	local itemNum = self:FindWndTrans(item,"itemNum")
	local itype,refId,count = itemdata.type or itemdata.itemType,itemdata.itemId,itemdata.count or itemdata.itemNum
	local formatData =
	{
		itemId = refId,
		itemType = itype,
		itemNum = count,
	}

	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
	end
	baseClass:SetCommonReward(formatData.itemType, formatData.itemId, count)
	baseClass:DoApply()
	self:SetIconClickScale(root, true)
	self:SetWndClick(root, function() gModelGeneral:ShowCommonItemTipWnd(formatData) end)

	self:SetWndText(itemNum,LUtil.NumberCoversion(count))

	-- local EffTrans = self:FindWndTrans(item,"Eff")
	-- if EffTrans then
	-- 	local show = false
	-- 	if itype == LItemTypeConst.TYPE_ITEM then
	-- 		LxResUtil.DestroyChildImmediate(EffTrans)
	-- 		local itemRef = gModelItem:GetRefByRefId(refId)
	-- 		local bgEff = itemRef and itemRef.bgEff or nil
	-- 		if not string.isempty(bgEff) then
	-- 			show = true
	-- 			local instanceId = item:GetInstanceID()
	-- 			self:CreateWndEffect(EffTrans,bgEff,instanceId,71,false,false)
	-- 		end
	-- 	end
	-- 	CS.ShowObject(EffTrans,show)
	-- end

	local instanceId = item:GetInstanceID()
	if itemdata.isShowEff then
		local quality = gModelGeneral:GetCommonItemQualityRef(itemdata)
		local eff = GameTable.RarityRef[quality].itemFx
		if not string.isempty(eff) then
			self:CreateWndEffect(root,eff,instanceId,100,false,false)
		end
	else
		self:DestroyWndEffectByKey(instanceId)
	end
end

function UISubDTDGift:SetSkipFun(textTran , jumpList)
	local jumpList = jumpList or {}
	if self._jumpList and self._jumpList == jumpList then
		return
	end
	local uiHyper = self._uiHyper
	if not uiHyper then
		uiHyper = UIHyperText:New()
		self._uiHyper = uiHyper
		uiHyper:Create(textTran)
	end
	self._jumpList = jumpList
	for i, v in ipairs(jumpList) do
		uiHyper:AddHyperFun(
				{ func =function (...) self:OnClickHyperFun(...)  end,
				  para =v }
		)
	end
end

function UISubDTDGift:InitData()
	self._sid = self:GetWndArg("sid")

	self._isClickBuy = false
	self._waitOpenIntegralGiftPop = false

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UISubDTDGift:SetInitData()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then
		return
	end

	local data =webData.config
	self._buyAllType = data.buyAllType
	self._activityData = gModelActivity:GetActivityBySid(self._sid)

	CS.ShowObject(self.mTenDay,false)
	CS.ShowObject(self.mOneDay,false)
	self:RefreshShopRed()
end

function UISubDTDGift:RefreshShopRed()
	local isRed = gModelRedPoint:CheckActivityShowRed(self._sid)

	isRed = isRed or gModelRedPoint:CheckShowRedPoint(10405111)
	CS.ShowObject(self.mRedPoint,isRed)
end

function UISubDTDGift:OnClickPay(itemdata)--点击购买
	if(self._bBuyAll)then
		self._isClickBuy = true
		gModelActivity:OnActivitySpecialOpReq(self._sid,itemdata.pageId,itemdata.entryId,3)
		return
	end
	local welfareId = tonumber(itemdata.MarketData.expend2)
	self._isClickBuy = true
	gModelPay:GiftPayCtrl(itemdata.entryId,welfareId,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,itemdata.pageId)
end

function UISubDTDGift:RefreshBuyItem(item,value,curValue,pos)
	if not item then return end
	local icon = self:FindWndTrans(item,"Icon")
	local numText = self:FindWndTrans(item,"NumText")
	local btnDes = self:FindWndTrans(item,"BtnDes")
	local desText = self:FindWndTrans(item,"BtnDes/DesText")

	local isD = value <= curValue
	local _otherJumps = self._otherJump or {}
	local _otherJump = _otherJumps[pos]

	CS.ShowObject(item,true)
	CS.ShowObject(icon,isD)
	self:SetWndText(numText,LUtil.FormatColorStr(value,isD and "black" or "white"))
	if _otherJump then
		self:SetWndText(desText,_otherJump.des)
		self:SetWndClick(btnDes,function ()
			local isOpen = gModelFunctionOpen:CheckIsOpened(_otherJump.jumpId,true)
			if(not isOpen)then
				return
			end
			gModelFunctionOpen:Jump(_otherJump.jumpId,self:GetWndName())
		end)
	end
end

function UISubDTDGift:OnTryRefreshRedPoint(redPointType)
	self:RefreshShopRed()
end

function UISubDTDGift:OnTargetWndClose(wndName)
	if self._waitOpenIntegralGiftPop and wndName == "UIAward" then
		self._waitOpenIntegralGiftPop = false
		self:OnClickIntegralGift()
	end
end

function UISubDTDGift:CheckHaveIntegralGift()
	if not self._bNoBuyAll then
		return false
	end

	return gModelActivity:CheckActDailyGiftBagShowIntegral(self._activityData)
end

function UISubDTDGift:ResetData(pb)
	local sid=pb.sid
	if(self._sid~=sid)then
		return
	end
	self.pages={}
	for i, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		table.insert(self.pages,page)
	end

	self:RefreshData()
end

------------------------------------------------------------------
return UISubDTDGift


