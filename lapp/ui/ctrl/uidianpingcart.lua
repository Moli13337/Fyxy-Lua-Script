---
--- Created by Administrator.
--- DateTime: 2023/10/5 14:45:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDianpingCart:LWnd
local UIDianpingCart = LxWndClass("UIDianpingCart", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDianpingCart:UIDianpingCart()
	self._isOneKeyToggle = false
	self._checkedItems = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDianpingCart:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDianpingCart:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDianpingCart:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitUIEvent()
	self:InitEvent()

	self:OnWndRefresh()
end

function UIDianpingCart:InitUIEvent()
	self:SetWndClick(self.mBuyBtn,function ()
		self:OnClickBuy()
	end)

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBuyBtn,function ()
		self:OnClickBuy()
	end)

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mHelpBtn,function ()
		self:OnClickHelp()
	end)

	self:SetWndToggleDelegate(self.mOneKeyToggle,function(value)
		self:OnToggleOneKey(value)
	end)
	self:SetWndToggleValue(self.mOneKeyToggle,false)
end

function UIDianpingCart:ShowKeyboard(itemdata,inputTran)
	local minNum = 0
	local maxNum = self:GetMaxNum(itemdata)
	if maxNum < 0 then
		maxNum = 999
	end
	local default = itemdata.num

	local inputFunc = function(input,cmd)
		if self:IsWndClosed() then
			return
		end
		local num = tonumber(input) or 0
		if cmd == "D" then
			self:ChangeNum(itemdata,num)
		else
			self:SetWndText(inputTran,num)
		end
	end

	GF.OpenWndUp("UINuoardUI",{minNum = minNum,maxNum = maxNum,defaultNum = default,inputFunc = inputFunc,inputTran = inputTran})

end


function UIDianpingCart:GetMaxNum(itemdata)
	local entryData = itemdata.entryData
	local marketData = entryData.MarketData
	local limitNum = marketData.personalGoal
	if limitNum > 0 then
		local leftNum = marketData.personalGoal- marketData.personal
		leftNum = math.max(0,leftNum)
		return leftNum
	end

	return -1
end

function UIDianpingCart:InitEvent()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...) self:OnActivityPageResp(...) end)
	local func =nil
	func = function (data,sid)
		if self._sid ~= sid then
			return
		end

		self:ShowPriceOwn()

		self:WndEventRemove(EventNames.ON_ACTIVITY_CONFIG_DATA,func)

		self:InitDisRule()

		gModelActivity:OnActivityPageReqEx(self._sid,self._pageId)
	end
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,func)

	self:WndEventRecv(EventNames.On_Item_Change,function ()
		local list = self:FindUIScroll("currencyList")
		if list then
			list:DrawAllItems(false)
		end
	end)
end

function UIDianpingCart:RefreshEmptyRecord()
	local showRecord = table.isempty(self._shopCart) or #self._shopCart <= 0
	CS.ShowObject(self.mNoRecord4, showRecord)
	if showRecord then
		self:CreateEmptyShow()
	end
end

function UIDianpingCart:OnActivityPageResp(pb)
	if self._sid ~= pb.sid then
		return
	end

	local pageMap = self._pageMap or {}

	for k,v in ipairs(pb.pages) do
		local structPage = StructActivityPage:New()
		structPage:CreateByPb(v)
		pageMap[structPage.pageId] = structPage
	end

	self._pageMap = pageMap

	self:ShowContent()
end

function UIDianpingCart:ShowPriceOwn()

	local actCfg = gModelActivity:GetWebActivityDataById(self._sid)
	if not actCfg then
		return
	end

	local refId  = actCfg.config.exchangeItem
	local dataList = {refId}


	local itemList = self:FindUIScroll("currencyList")
	if not itemList then
		itemList = self:GetUIScroll("currencyList")
		itemList:Create(self.mMoneyList,dataList,function(...) self:OnDrawCurrency(...) end)
	else
		itemList:RefreshList(dataList)
	end
end

function UIDianpingCart:RefreshOneKeyToggle()
	local isAllSelect = true
	for k,v in ipairs(self._shopCart) do
		local refId = v.refId
		if not self._checkedItems[refId] then
			isAllSelect = false
			break
		end
	end

	if self._isOneKeyToggle == isAllSelect then return end

	self._justChangeShow = true
	self:SetWndToggleValue(self.mOneKeyToggle,isAllSelect)
end

function UIDianpingCart:RefreshGoodsList()
	local goodsListInCart = self._shopCart
	local index = nil
	for k,v in ipairs(goodsListInCart) do
		if self._changeRefId and self._changeRefId == v.refId then
			index = k
		end
	end

	local uiList = self:FindUIScroll("goodsList")
	if not uiList then
		uiList= self:GetUIScroll("goodsList")
		uiList:Create(self.mGoodsList,goodsListInCart,function (...) self:OnDrawGoods(...) end,UIItemList.SUPER)
		uiList:DrawAllItems(true)

	else
		uiList:RefreshList(goodsListInCart)
		if index then
			uiList:DrawItemByIndex(index)
		else
			uiList:DrawAllItems(false)
		end
	end
end

function UIDianpingCart:InitDisRule()
	local webdata = gModelActivity:GetWebActivityDataById(self._sid)
	if not webdata then
		return
	end

	local discount = webdata.config.reductionDiscount
	local strs = string.split(discount,';')
	local dataList = {}
	for k,v in ipairs(strs) do
		local temp = string.split(v,'=')
		local count = tonumber(temp[1])
		local dis = tonumber(temp[2])
		table.insert(dataList,{count = count,dis = dis})
	end

	self._disRule = dataList

end


function UIDianpingCart:OnWndRefresh()
	local sid = self:GetWndArg("sid")
	local pageId= self:GetWndArg("pageId")
	self._sid = sid
	self._pageId = pageId

	gModelActivity:ReqActivityConfigData(sid)
end

function UIDianpingCart:ChangeNum(itemdata,num)
	--local entryData = itemdata.entryData
	local limitNum = self:GetMaxNum(itemdata)
	if limitNum > 0 and num > limitNum then
		local str =ccClientText(23804)-- "已达到限购次数无法添加"
		GF.ShowMessage(str)
		return
	end

	if num < 0 then
		return
	end

	local data =
	{
		opType = 2,
		sid = self._sid,
		pageId = self._pageId,
		entryId = itemdata.refId,
		num = num
	}

	self._changeRefId = itemdata.refId
	gModelActivity:OnActivityMarketRefreshOpReq(data)

	self._shopCart = nil
end

function UIDianpingCart:OnDrawGoods(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	--local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootIconRoot = self:FindWndTrans(AniRoot,"iconRoot")
	local AniRootItemName = self:FindWndTrans(AniRoot,"itemName")
	local AniRootLayout = self:FindWndTrans(AniRoot,"layout")
	local layoutIcon = self:FindWndTrans(AniRootLayout,"icon")
	local layoutNum = self:FindWndTrans(AniRootLayout,"num")
	local AniRootNumBg = self:FindWndTrans(AniRoot,"numBg")
	local numBgNum = self:FindWndTrans(AniRootNumBg,"num")
	local AniRootSubBtn = self:FindWndTrans(AniRoot,"subBtn")
	local AniRootAddBtn = self:FindWndTrans(AniRoot,"addBtn")
	local AniRootUIText = self:FindWndTrans(AniRoot,"UIText")
	local AniRootToggle = self:FindWndTrans(AniRoot,"Toggle")
	--local ToggleBackground = self:FindWndTrans(AniRootToggle,"Background")
	--local BackgroundCheckmark = self:FindWndTrans(ToggleBackground,"Checkmark")
	local AniRootDiscountImg = self:FindWndTrans(AniRoot,"DiscountImg")
	local DiscountImgText = self:FindWndTrans(AniRootDiscountImg,"text")


	local entryCfg = itemdata.entryCfg

	local rewardItem = LxDataHelper.ParseItem_3(entryCfg.reward)
	self:CreateCommonIconImpl(AniRootIconRoot,rewardItem)

	local itemName = gModelGeneral:GetCommonItemName(rewardItem)
	self:SetWndText(AniRootItemName,itemName)
	self:InitTextSizeWithLanguage(AniRootItemName, -2)
	self:InitTextLineWithLanguage(AniRootItemName, -30)

	local priceItem = itemdata.price
	local icon = gModelItem:GetItemIconByRefId(priceItem.itemId)
	self:SetWndEasyImage(layoutIcon,icon)
	self:SetWndText(layoutNum,priceItem.itemNum)

	local num = itemdata.num
	self:SetWndText(numBgNum,itemdata.num)

	local strs = string.split(entryCfg.moreInfo,"|")
	local disText = strs and strs[1]

	local hasDis = not string.isempty(disText)
	CS.ShowObject(AniRootDiscountImg,hasDis)
	if hasDis then
		self:SetWndText(DiscountImgText,disText)
	end

	local entryData = itemdata.entryData
	local marketData = entryData.MarketData
	local limitNum = marketData.personalGoal
	local str = ""
	if limitNum>0 then
		local personalValue = marketData.personal + num
		local personalGoal = marketData.personalGoal
		str = personalValue.."/"..personalGoal
		if personalValue >= personalGoal then
			str = LUtil.FormatColorStr(str, "red")
		end

		str = string.replace(ccClientText(23803),str)
	end
	self:SetWndText(AniRootUIText,str)

	self:SetWndClick(AniRootSubBtn,function () self:ChangeNum(itemdata,itemdata.num - 1) end)
	self:SetWndClick(AniRootAddBtn,function () self:ChangeNum(itemdata,itemdata.num + 1) end)

	self:SetWndClick(AniRootNumBg,function () self:ShowKeyboard(itemdata,numBgNum) end)

	local isChecked = self._checkedItems and self._checkedItems[itemdata.refId] or false

	self:SetWndToggleDelegate(AniRootToggle,function () end)
	self:SetWndToggleValue(AniRootToggle,isChecked)

	self:SetWndToggleDelegate(AniRootToggle,function (value)
		self:SetItemCheck(itemdata,value)
	end)
end

function UIDianpingCart:OnClickBuy()
	if not self._shopCart then
		return
	end

	local totalPrice = 0
	local priceItemId = nil
	local entryId = nil
	local cartList = {}
	for k,v in ipairs(self._shopCart) do
		local refId = v.refId
		if self._checkedItems and self._checkedItems[refId] then
			if v.num> 0 then
				local price = v.price
				priceItemId = price.itemId
				totalPrice =totalPrice + price.itemNum * v.num
				entryId = v.refId
				local str = string.format("%s=%s",v.refId,v.num)
				table.insert(cartList,str)
			end
		end
	end

	if totalPrice == 0 then
		local str =ccClientText(23800)-- "请添加商品"
		GF.ShowMessage(str)
		return
	end

	if not self._disRule then
		return
	end

	local curDis = 1
	for k,v in ipairs(self._disRule) do
		if totalPrice >= v.count then
			curDis = math.min(v.dis,curDis)
		end
	end

	local finalPrice = math.floor(totalPrice * curDis)

	local wndName = self:GetWndName()
	if not gModelGeneral:CheckItemEnough(priceItemId,finalPrice,true,wndName) then
		return
	end

	local shoppingCart = table.concat(cartList,',')


	gModelActivity:OnActivityMarkeyBuyReq(self._sid,self._pageId,entryId,nil,shoppingCart)


end

function UIDianpingCart:OnDrawCurrency(list,item, itemdata, itempos)
	local icon = self:FindWndTrans(item,"icon")
	local num = self:FindWndTrans(item,"num")
	local addBtn = self:FindWndTrans(item,"addBtn")

	local refId = itemdata
	local iconPath,iconBgPath = gModelItem:GetItemImgByRefId(refId)
	self:SetWndEasyImage(icon,iconPath)
	self:SetWndClick(addBtn,function () self:OnClickAdd(refId) end)
	local count = gModelItem:GetNumByRefId(refId)
	count = LUtil.NumberCoversion(count)
	self:SetWndText(num,count)
end

function UIDianpingCart:CreateEmptyShow()
	local text = self:FindWndTrans(self.mEmptyBtn,"Light/Text")
	local data = {
		refId =  14009,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
		GetBtn = self.mEmptyBtn,
		GetBtnText = text,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIDianpingCart:ShowContent()
	local sid = self._sid
	local pageId = self._pageId
	local pageData = self._pageMap[pageId]
	local pageCfg = gModelActivity:GetWebActivityPageData(self._sid,pageId)
	if not pageData or not pageCfg then
		return
	end


	local moreInfoData = JSON.decode(pageData.moreInfo)
	local netData = JSON.decode(moreInfoData.shoppingCart)
	local goodsList = netData.goodsList
	local goodsListInCart = {}
	if goodsList then
		for k,v in ipairs(goodsList) do
			local refId = v.refId

			local entryCfg = gModelActivity:GetWebActivityEntryData(sid,pageId,refId)
			local entryData = pageData:GetEntry(refId)
			if entryData then
				local priceStr = entryCfg.expend1
				if string.isempty(priceStr) then
					priceStr = entryCfg.expend2
				end

				local priceItem = LxDataHelper.ParseItem_3(priceStr)

				local data =
				{
					refId = refId,
					num = v.num,
					createTime = v.createTime,
					entryCfg = entryCfg,
					entryData = entryData,

					price = priceItem
				}


				table.insert(goodsListInCart,data)
			else
				printErrorN(string.format("miss entry data refId %s",refId))
			end


		end
	end

	table.sort(goodsListInCart,function(a,b)
		return a.createTime< b.createTime
	end)


	self._shopCart = goodsListInCart

	self:RefreshPriceText()
	self:RefreshGoodsList()
	self:RefreshEmptyRecord()
end


function UIDianpingCart:SetStaticContent()
	local str =ccClientText(23801)-- "购物车"
	self:SetWndText(self.mLblBiaoti,str)
	str =ccClientText(23802)-- "购买"
	self:SetWndButtonText(self.mBuyBtn,str)
	self:SetWndText(self.mToggleText, ccClientText(23822))

	self._isForeign = gLGameLanguage:IsForeignVersion()
end

function UIDianpingCart:OnClickHelp()
	local actCfg = gModelActivity:GetWebActivityDataById(self._sid)
	if not actCfg then
		return
	end
	local config = actCfg.config
	local para =
	{
		title = gModelActivity:GetLngNameByActivitySid(self._sid),
		text = config.shopDesc,
	}

	GF.OpenWnd("UIBzTips",para)
end

function UIDianpingCart:SetItemCheck(itemdata,value)
	if not self._checkedItems then
		self._checkedItems ={}
	end

	self._checkedItems[itemdata.refId] = value

	self:RefreshPriceText()
	self:RefreshOneKeyToggle()
end

function UIDianpingCart:RefreshPriceText()
	local totalPrice = 0
	local priceItemId = nil
	local cnt = 0
	for k,v in ipairs(self._shopCart) do
		local refId = v.refId
		if self._checkedItems and self._checkedItems[refId] then
			if  v.num> 0 then
				local price = v.price
				priceItemId = price.itemId
				totalPrice = totalPrice +  price.itemNum * v.num

				cnt = cnt + 1
			end
		end

	end

	local curDis = 1
	local nextRule
	for k,v in ipairs(self._disRule) do
		if totalPrice >= v.count then
			curDis = math.min(v.dis,curDis)
		elseif not nextRule then
			nextRule = v
		end
	end

	local str, str2
	local priceStr=""
	if curDis< 1 then
		str =  ccClientText(23805)
		str2 = ccClientText(23806)
		str = string.replace(str,cnt)

		local curDisStr
		if self._isForeign then
			curDisStr = (1 - curDis) * 100
			curDisStr = curDisStr.."%"
		else
			curDisStr = curDis*10
		end

		str2 = string.replace(str2,curDisStr)

		local disPrice = math.floor(curDis* totalPrice)
		priceStr = string.replace(ccClientText(23807),totalPrice,disPrice)
	else
		str =ccClientText(23805)
		str = string.replace(str,cnt)
		str2 = ""

		priceStr = string.replace(ccClientText(23820),totalPrice)
	end

	self:SetWndText(self.mGoodsInfo,str)
	self:InitTextSizeWithLanguage(self.mGoodsInfo, -2)
	self:SetWndText(self.mGoodsInfo2,str2 or "")
	self:InitTextLineWithLanguage(self.mGoodsInfo2, -30)
	self:InitTextSizeWithLanguage(self.mGoodsInfo2, -2)
	self:SetWndText(self.mPriceInfo,priceStr)
	self:InitTextSizeWithLanguage(self.mPriceInfo, -2)

	local nextPriceStr
	if not nextRule then
		nextPriceStr = ccClientText(23824)
	else
		local nextPrice
		local nextRuleDis = nextRule.dis
		if self._isForeign then
			nextPrice = (1- nextRuleDis) * 100
			nextPrice = nextPrice.."%"
		else
			nextPrice = math.floor(nextRuleDis*10)
		end

		local nextCount = nextRule.count-totalPrice
		nextPriceStr = string.replace(ccClientText(23823),nextCount,nextPrice)
	end

	self:SetWndText(self.mNextPriceInfo,nextPriceStr)
end

function UIDianpingCart:OnToggleOneKey(isOpen)
	self._isOneKeyToggle = isOpen
	if self._justChangeShow then
		self._justChangeShow = false
		return
	end

	if not isOpen then
		self._checkedItems ={}
	else
		for k,v in ipairs(self._shopCart) do
			local refId = v.refId
			self._checkedItems[refId] = true
		end
	end
	self._changeRefId = nil
	self:RefreshPriceText()
	self:RefreshGoodsList()
end

function UIDianpingCart:OnClickAdd(refId)
	local wndName = self:GetWndName()
	GF.OpenWndUp("UIGeay",{itemId=refId,srcWnd = wndName})
end

------------------------------------------------------------------
return UIDianpingCart


