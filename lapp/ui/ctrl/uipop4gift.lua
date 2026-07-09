---
--- Created by BY.
--- DateTime: 2023/10/19 16:58:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPop4Gift:LWnd
local UIPop4Gift = LxWndClass("UIPop4Gift", LWnd)
local typeof = typeof
local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local typeUIText = typeof(CS.YXUIText)
local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
------------------------------------------------------------------

local adMethodId = ModelAds.TYPE_ADS_401
--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPop4Gift:UIPop4Gift()
	self._timeKey = "timeKey"
	self._giftIndex = 0
	self._giftTransList = {}
	self._tabIndex = 0
	self._tabTransList = {}
	self._iceCountDown = "_iceCountDown"
	self._ice2CountDown = "_ice2CountDown"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPop4Gift:OnWndClose()
	FireEvent(EventNames.ON_MAIN_GIFT_SHOW, false)
	self:StopDelayTimer()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPop4Gift:OnCreate()
	FireEvent(EventNames.ON_MAIN_GIFT_SHOW, true)
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPop4Gift:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._recordSpinePox = self.mSpPos.anchoredPosition
	self.jpj = gLGameLanguage:IsJapanVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()

	gModelWndPop:RemovePopWnd("UIPop4Gift")
	
	if gLGameLanguage:IsJapanVersion() then
		self:InitTextSizeWithLanguage(self.mIntro_new,-2)
		self:InitTextLineWithLanguage(self.mIntro_new,-40)
	end 
end
function UIPop4Gift:CreateEffect(trans,effectName,effectKey,effectSize)
	effectKey = effectKey or trans:GetInstanceID()
	effectSize = effectSize or 100
	self:CreateWndEffect(trans,effectName,effectKey,effectSize,false,false)
end

function UIPop4Gift:GetCurActiveGift()
	local gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)
	if not gift then
		gift = self._curActiveGift
	end

	return gift
end
function UIPop4Gift:Ice2TabListItem(list, item, itemdata, itempos)
	self._ice2TabTransList[itempos] = item
	self:ChangeGiftImage(item, false)
	local giftGradeName = itemdata.isActivity and itemdata.giftGradeName or ccLngText(itemdata.giftGradeName)
	local str = string.replace(ccClientText(14908), giftGradeName)
	self:SetWndTabText(item,str)
	local tabState = itemdata.refId == self._curRefId and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(item,tabState)
	self:SetWndClick(item, function()
		self:OnClickIce2Tab(itempos)
	end)
end
function UIPop4Gift:CheckCurActGiftIsSoleOut()
	if(self._curSid)then
		local pageData = self._activityPageKeyList[self._curSid][1]
		local entryData = pageData.entry[self._curRefId]
		local marketData = entryData.MarketData
		local personal = marketData.personal
		local personalGoal = marketData.personalGoal
		local hasBuyTime = personalGoal == -1 and -1 or personalGoal - personal
		return hasBuyTime~=-1 and hasBuyTime <= 0
	end
end

function UIPop4Gift:StopDelayTimer()
	if self._delayUpdateScrollTimer then
		LxTimer.DelayTimeStop(self._delayUpdateScrollTimer)
		self._delayUpdateScrollTimer = nil
	end
end

function UIPop4Gift:UpdateResultText(ResultText, ResultNode, text, normalized)
	self:SetWndText(ResultText, text)
	self:StartDelayTimer(ResultNode, normalized)
end

function UIPop4Gift:JumpTargetGiftDelay(giftPos)
	if not self._uiGiftList2 then
		local list = self._uiGiftList2:GetList()
		if (not list) then
			return
		end
		list:DelayScrollTo(giftPos, UIListEasy.SCROLL_CENTER)
	end
end

function UIPop4Gift:OnClickTab(itempos)
	if self._tabIndex > 0 then
		local trans = self._tabTransList[self._tabIndex]
		self:ChangeGiftImage(trans, false)
	end
	local trans = self._tabTransList[itempos]
	self:ChangeGiftImage(trans, true)
	self._tabIndex = itempos

	if(self._curSid and (not self._giftArrList or not self._giftArrList[itempos]))then
		self:OnClickClose()
		return
	end

	local ref = self._giftArrList[itempos]

	self._curRefId = ref and ref.refId or self._curRefId

	self:TimerStop(self._timeKey)

	if(not ref)then
		self:OnClickClose()
		return
	end

	if (ref.isActivity) then
		local isSoldGroupOver = self:CheckSoleGroupOver(ref.giftGroup,ref.sid)
		if(isSoldGroupOver)then
			self:OnClickClose()
			return
		end
	end

	self:SetGiftInfo(self.mRoot1, ref)

	if not self._giftTransList then
		return
	end
	local trans = self._giftTransList[self._giftIndex]
	if not CS.IsValidObject(trans) then
		return
	end

	local rateText = self:FindWndTrans(trans, "Root/RateBg/RateText")
	if (ref) then
		self:SetWndText(rateText, ref.discount .. "%+")
	end
end
function UIPop4Gift:OnActivityPageResp(pb, ret)
	local modelId = gModelActivity:GetActivityModeIdBySid(pb.sid)
	if (modelId == ModelActivity.MODEL_ACTIVITY_TYPE_93) then
		local _activityPageList = {}
		local _activityPageKeyList = self._activityPageKeyList or {}
		for i, v in ipairs(pb.pages) do
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			_activityPageList[page.pageId] = page
		end
		_activityPageKeyList[pb.sid] = _activityPageList
		self._activityPageKeyList = _activityPageKeyList
		self:RefreshUIByActivityPageResp()
	end
end

function UIPop4Gift:JumpTargetGift(giftPos)
	if self._uiGiftList1 then
		local list = self._uiGiftList1:GetList()
		if (not list) then
			return
		end
		list:ScrollTo(giftPos)
	end
	if self._uiGiftList2 then
		local list = self._uiGiftList2:GetList()
		if (not list) then
			return
		end
		list:ScrollTo(giftPos)
	end
end

function UIPop4Gift:SetGiftInfo(root, ref)
	local resultNode = CS.FindTrans(root, "DesImage/ResultNode")
	local desText = self:FindWndTrans(resultNode, "DesText")
	--local rateText = self:FindWndTrans(root,"RateText")
	--local enrateText = self:FindWndTrans(root,"enRateText")
	local itemScroll = self:FindWndTrans(root, "ItemScroll")
	local payBtn = self:FindWndTrans(root, "PayBtn")
	local payText1 = self:FindWndTrans(root, "PayBtn/TextMg/PayText1")
	local payIcon = self:FindWndTrans(root, "PayBtn/TextMg/PayIcon")
	local payText2 = self:FindWndTrans(root, "PayBtn/TextMg/PayText2")
	local cutBtn = self:FindWndTrans(root, "CutBtn")
	local cutText = self:FindWndTrans(root, "CutBtn/CutText")
	local payMask = self:FindWndTrans(root, "PayMask")
	local buyLimitTxt = self:FindWndTrans(root, "BuyLimitTxt")
	self.buyLimitTxt = buyLimitTxt
	CS.ShowObject(payIcon, false)
	CS.ShowObject(payMask, false)
	self:SetWndText(payText1, "")
	self:SetWndText(payText2, "")
	CS.ShowObject(cutBtn, true)
	CS.ShowObject(payBtn, true)
	if (not ref) then
		self:OnClickClose()
		return
	end
	self:SetSpine(ref.showHero,ref.showXY,self.mSpPos,ref.showScale)

	local desStr = ""
	local butStr = ""
	local cutStr = ""

	local guyGift = gModelPopupGift:GetGiftByRefId(ref.refId, ref.sid)
	--self._guyGift = guyGift
	CS.ShowObject(payBtn, true)

	local curMaxGiftLv = self._curMaxGiftLv

	local isCountDown = false

	local rId = guyGift and guyGift.ref.refId or nil
	local giftList = rId and gModelPopupGift:GetGiftArrByRefId(rId, self._curSid) or nil
	local isBuyPrior, pGift, pIndex
	if (giftList and guyGift.isActivity and #giftList > 1 ) then
		if(ref.activateType == 0)then
			isBuyPrior, pGift, pIndex = self:CheckActivityIsBuyPrior(giftList, guyGift.ref.refId)
		end
		isBuyPrior = isBuyPrior or self:CheckActivityIsBuy(ref.sid, ref.refId)
	end
	local showBuyLimitTxt = guyGift and guyGift.isActivity and not isBuyPrior
	CS.ShowObject(self.buyLimitTxt, showBuyLimitTxt)

	local payIconPath
	local showPayIcon = false
	local isSoldOut = false
	if guyGift and not isBuyPrior then
		--后端有发礼包
		if (buyLimitTxt and guyGift.isActivity and self._activityPageKeyList and self._activityPageKeyList[self._curSid]) then
			local pageData = self._activityPageKeyList[self._curSid][1]
			local entryData = pageData.entry[self._curRefId]
			local marketData = entryData.MarketData
			local personal = marketData.personal
			local personalGoal = marketData.personalGoal
			local hasBuyTime = personalGoal == -1 and -1 or personalGoal - personal
			self:SetBuyLimitTxt(hasBuyTime)
		else
			self:SetBuyLimitTxt()
		end
		self._desTrans = resultNode
		CS.ShowObject(cutBtn, false)
		local payStr = ""
		if (ref.buyType == ModelPopupGift.BUYTYPE_JEWEL or ref.buyType == ModelPopupGift.BUYTYPE_CURRENCY) then
			showPayIcon = true
			CS.ShowObject(payIcon, true)
			local item = LxDataHelper.ParseItem_3(ref.expend)
			payIconPath = gModelItem:GetItemIconByRefId(item.itemId)
			payStr = item.itemNum
		elseif (ref.buyType == ModelPopupGift.BUYTYPE_MONEY) then
			payStr = gModelPay:GetShowByWelfareId(tonumber(ref.expend))
		elseif (ref.buyType == ModelPopupGift.BUYTYPE_FREE) then
			payStr = ccClientText(14903)
		end
		butStr = ref.isActivity and ref.buyBtnTxt or ccLngText(ref.buyBtnTxt)
		self:SetWndText(payText2, payStr)
		isCountDown = true
		self:SetTime()
		self:TimerStart(self._timeKey, 1, false, -1)
	else
		if (ref.isActivity) then
			isSoldOut = self:CheckActivityIsBuy(ref.sid, ref.refId)
		else
			if ref.activateType == 1 then
				isSoldOut = true
			else
				isSoldOut = ref.giftGroupCount < curMaxGiftLv or curMaxGiftLv == -1
			end
		end

		if isSoldOut then
			--前一档礼包
			CS.ShowObject(cutBtn, false)
			CS.ShowObject(payBtn, false)
			desStr = ref.isActivity and ref.descriptionSaleOut or ccLngText(ref.descriptionSaleOut)
		else
			desStr = ref.isActivity and ref.descriptionNo or ccLngText(ref.descriptionNo)
			local currBuyGift = self._giftArrList[curMaxGiftLv]
			local giftGradeName = currBuyGift.isActivity and pGift.giftGradeName or ccLngText(currBuyGift.giftGradeName)
			butStr = string.replace(ccClientText(14910), giftGradeName)
			cutStr = string.replace(ccClientText(14909), giftGradeName)
		end
	end

	CS.ShowObject(payMask, isSoldOut)

	local showAd = false
	if not isSoldOut and self:GetWndAdBtnShowStatus({
		adMethodId = adMethodId,
		refId = rId,
		giftRefId = ref.refId,
		giftSid = ref.sid,
		checkHasCount = true,
	}) then
		showAd = true
		showPayIcon = true
		payIconPath = "adShop_btn_1"
		self:SetWndText(payText2, ccClientText(47103))
	end
	if showPayIcon and payIconPath then
		self:SetWndEasyImage(payIcon, payIconPath,function()
			CS.ShowObject(payIcon,true)
		end)
	end

	self:SetWndText(payText1, butStr)
	if not isCountDown then
		self:UpdateResultText(desText, resultNode, desStr, 0)
	end
	self:SetWndText(cutText, cutStr)

	local rateStr = LUtil.FormatHurtNumSpriteText(ref.discount)
	self:SetWndText(self.mRateText, rateStr)

	local lng = gLGameLanguage:GetLanguageFlag()
	local space = -12
	local size = 85
	local padding = { x = -6, y = -6 }

	if gLGameLanguage:IsEnglishVersion() then
		space = -12
		padding = { x = 8, y = 8 }
	elseif lng ~= "zhcn" then
		space = -20
		padding = { x = 0, y = 4 }
	end

	local parent = self.mRateText.parent
	local layoutGroup = self:FindCommonComponent(parent, typeHorizontalLayoutGroup)
	layoutGroup.padding.left = padding.x
	layoutGroup.padding.right = padding.y
	local textCom = self:FindCommonComponent(self.mRateText, typeUIText)
	textCom.fontSize = size
	textCom.characterSpacing = space

	self:ShowRewardList(ref, itemScroll)

	self:SetWndClick(cutBtn, function()
		if (ref.isActivity) then
			self:OnClickTab(pIndex)
		else
			self:OnClickTab(curMaxGiftLv)
		end
	end)

	if showAd then
		self:SetWndAdBtnInfo(payBtn,{
			adMethodId = adMethodId,
			refId = rId,
			giftRefId = ref.refId,
			giftSid = ref.sid,
			checkHasCount = true,
			wndId = 490005,
		})
	else
		self:SetWndClick(payBtn, function()
			if guyGift and not pGift then
				self:OnClickPay()
			else
				if (ref.isActivity) then
					self:OnClickTab(pIndex)
				else
					self:OnClickTab(curMaxGiftLv)
				end
			end
		end)
	end
end

function UIPop4Gift:SetPayBtn(item, ref)
	local TextMg = self:FindWndTrans(item, "TextMg")
	local TextMgPayText1 = self:FindWndTrans(TextMg, "PayText1")
	local TextMgPayIcon = self:FindWndTrans(TextMg, "PayIcon")
	local TextMgPayText2 = self:FindWndTrans(TextMg, "PayText2")

	CS.ShowObject(TextMgPayIcon, false)

	local payStr = ""
	if (ref.buyType == ModelPopupGift.BUYTYPE_JEWEL or ref.buyType == ModelPopupGift.BUYTYPE_CURRENCY) then
		CS.ShowObject(TextMgPayIcon, true)
		local item = LxDataHelper.ParseItem_3(ref.expend)
		local icon = gModelItem:GetItemIconByRefId(item.itemId)
		self:SetWndEasyImage(TextMgPayIcon, icon)
		payStr = item.itemNum
	elseif (ref.buyType == ModelPopupGift.BUYTYPE_MONEY) then
		payStr = gModelPay:GetShowByWelfareId(tonumber(ref.expend))
	elseif (ref.buyType == ModelPopupGift.BUYTYPE_FREE) then
		payStr = ccClientText(14903)
	end
	local btnStr = ref.isActivity and ref.buyBtnTxt or ccLngText(ref.buyBtnTxt)
	self:SetWndText(TextMgPayText2, payStr)
	self:SetWndText(TextMgPayText1, btnStr)
end

--region 破冰样式2
function UIPop4Gift:ShowIcePart2()
	self:TimerStop(self._timeKey)
	self:TimerStop(self._iceCountDown)
	self:TimerStop(self._ice2CountDown)
	CS.ShowObject(self.mRoot1, false)
	CS.ShowObject(self.mIcePart, false)
	CS.ShowObject(self.mIcePart2, true)
	local icePart2Trans = self.mIcePart2
	local bgImg = self:FindWndTrans(icePart2Trans,"BgImg")
	local titleImg = self:FindWndTrans(icePart2Trans,"TitleImg")
	local heroSpine = self:FindWndTrans(icePart2Trans,"HeroSpine")
	local discountGroup = self:FindWndTrans(icePart2Trans,"DiscountGroup")
	local discountPreTxt = self:FindWndTrans(discountGroup,"DiscountPreTxt")
	local discountText = self:FindWndTrans(discountPreTxt,"DiscountText")
	local rewardListBg = self:FindWndTrans(icePart2Trans,"RewardListBg")
	local rewardList = self:FindWndTrans(rewardListBg,"RewardList")
	local payBtn = self:FindWndTrans(icePart2Trans,"PayBtn")
	local maskPay = self:FindWndTrans(icePart2Trans,"MaskPay")
	local closeBtn = self:FindWndTrans(icePart2Trans,"CloseBtn")
	local starScroll = self:FindWndTrans(icePart2Trans,"StarScroll")
	local effRoot = self:FindWndTrans(icePart2Trans,"EffRoot")
	local pbData
	local pbGiftList = self._dataList[self._giftIndex] --_curIce2MaxGiftLv
	for i, v in ipairs(pbGiftList) do
		if(v.refId == self._curRefId)then
			pbData = v
		end
	end
	self._ice2TabIndex = self._isClickTab and self._ice2TabIndex or pbData.ref.giftGroupCount
	self._isClickTab = nil
	self.ice2GiftList = gModelPopupGift:GetGiftArrByRefId(self._curRefId)
	local gift = self.ice2GiftList[self._ice2TabIndex]
	self._ice2GiftEndTime =pbData and pbData.endTime/1000 or 0

	--- http://192.168.16.2:3002/issues/347
	--- 代码删除
	self:SetIce2CountDown()
	if(pbData)then
		self:TimerStart(self._ice2CountDown, 1, false, -1)
	end

	self:ShowRewardList(gift, rewardList)
	self:SetSpine(gift.showHero,gift.showXY,self.mSpPos,gift.showScale)

	self:SetWndClick(closeBtn, function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetPayBtn(payBtn, gift)

	local refId = gift.refId
	local wndName = self:GetWndName()
	self:SetWndClick(payBtn, function()
		gModelPopupGift:BuyGift(refId, wndName)
	end)

	self:SetIce2TabList(starScroll)
	--self:OnClickIce2Tab(1)
	self:SetWndText(discountPreTxt,ccClientText(14914))
	LxUiHelper.SetTextColorGradientStr(discountPreTxt,"ffffff|e6ceff")
	local discount = gift.discount
	local disStr = string.format("+%s%%",discount)
	self:SetWndText(discountText,disStr)
	LxUiHelper.SetTextColorGradientStr(discountText,"fff5c0|ffed7b")

	local isSellOut = pbData == nil
	CS.ShowObject(payBtn,not isSellOut)
	CS.ShowObject(maskPay,isSellOut)
end

function UIPop4Gift:ShowIcePart()
	CS.ShowObject(self.mRoot1, false)
	self:TimerStop(self._timeKey)
	self:TimerStop(self._ice2CountDown)
	CS.ShowObject(self.mIcePart, true)
	CS.ShowObject(self.mIcePart2, false)

	local gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)

	self:TimerStop(self._iceCountDown)
	self:TimerStart(self._iceCountDown, 1, false, -1)
	self:SetIceCountDown()



	local spPos = self:FindWndTrans(self.mIcePart,"spPos")

	local giftRef = gift.ref
	self:ShowRewardList(giftRef, self.mItemList)
	self:SetSpine(giftRef.showHero,giftRef.showXY,spPos,giftRef.showScale)


	local description = giftRef.isActivity and giftRef.description or ccLngText(giftRef.description)
	self:SetWndText(self.mIntro_new, description)
	local discount = giftRef.discount
	local showZK = discount and discount > 0
	if showZK then
		self:SetWndText(self.mZKTxt,LUtil.FormatHurtNumSpriteText(discount))
	end
	CS.ShowObject(self.mZKDiv,showZK)

	if self.jpj then
		self:SetAnchorPos(self.mZKDiv,Vector2.New(90,240))
	end

	self:SetPayBtn(self.mPayBtn, gift.ref)
	local refId = gift.ref.refId
	local wndName = self:GetWndName()

	self:SetWndClick(self.mPayBtn, function()
		local customReward = self._curSid and "" or nil
		if (self._curSid and self._activityPageKeyList) then
			customReward = self._activityPageKeyList[self._curSid][1].entry[self._curRefId].MarketData.customGift
		end
		gModelPopupGift:BuyGift(refId, wndName, self._curSid, customReward)
	end)

	--设置下状态
	if gift then
		local curCanBuy = gift.ref.limit > 0 and gift.ref.limit or gift.ref.lifetimeLimit

		curCanBuy = curCanBuy - gift.buyNum
		if curCanBuy > 0 then
			local str = gift.ref.limit > 0 and ccClientText(45303) or ccClientText(45304)
			str = string.replace(str, curCanBuy)
			self:SetWndText(self.mBuyLimitTxt, str)
			CS.ShowObject(self.mBuyLimitTxt, true)
		else
			CS.ShowObject(self.mBuyLimitTxt, false)
		end

	end

end

function UIPop4Gift:InitMessage()
	self:WndNetMsgRecv(LProtoIds.PopupGiftNowListResp, function(...)
		self:OnPopupDataListChange()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
		self:OnActivityPageResp(...)
	end)
end

function UIPop4Gift:OnPopupDataListChange()
	local curId = 0
	if self._curRefId then
		local gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)
		if gift then
			curId = gift.id
		else
			local ref = gModelPopupGift:GetPopupGiftRefByRefId(self._curRefId, self._curSid)
			gift = gModelPopupGift:GetGiftByGroup(ref.giftGroup, self._curSid)
			if gift then
				curId = gift.id
				self._curRefId = ref.refId
				self._curSid = ref.sid
				self._curGiftGroup = ref.giftGroup

			end
		end
	end
	local dataList, index = gModelPopupGift:GetPopGiftShowList(curId, 1)
	self._dataList = dataList
	index = index or 1
	self._index = index or 1
	self:InitGiftList()

	local needJump = #dataList > 5
	self:OnSelectIndex(index, needJump)
	self:RefreshTopContent()
end

function UIPop4Gift:SetGiftRoot()
	CS.ShowObject(self.mRoot1, true)
	CS.ShowObject(self.mIcePart, false)
	CS.ShowObject(self.mIcePart2, false)
	self:TimerStop(self._iceCountDown)
	self:TimerStop(self._ice2CountDown)

	local list = gModelPopupGift:GetGiftArrByRefId(self._curRefId, self._curSid)
	if(self._curSid)then
		self:ActivitySandNewGift(list)
	end
	local curMaxGiftLv = -1

	local notBuyPos = -1
	local curSelect = -1
	for i, v in ipairs(list) do
		local _gift = gModelPopupGift:GetGiftByRefId(v.refId, v.sid) --取最新的数据
		if _gift then
			local _refGiftGroupCount = _gift.ref.giftGroupCount
			if _refGiftGroupCount == 0 then
				_refGiftGroupCount = 1
			end
			curMaxGiftLv = math.max(_refGiftGroupCount, curMaxGiftLv)


			if notBuyPos < 0 and _gift.isActivity and self:CheckActivityIsNoBuy(v.sid,v.refId) then
				notBuyPos = i
			end
		end

		if v.refId == self._curRefId then
			curSelect = i
		end
	end

	self._curMaxGiftLv = curMaxGiftLv

	self._tabTransList = {}

	self._giftArrList = list
	local tabScroll = self:FindWndTrans(self.mRoot1, "TabScroll")
	local TabScrollBg = self:FindWndTrans(self.mRoot1, "TabScrollBg")
	local isMoreType = #list > 1
	CS.ShowObject(tabScroll, isMoreType)
	CS.ShowObject(TabScrollBg, isMoreType)
	---@type UIItemList
	local _uitabList
	if isMoreType then
		_uitabList = self:FindUIScroll("tabScroll1")
		if _uitabList then
			_uitabList:RefreshList(list)
		else
			_uitabList = self:GetUIScroll("tabScroll1")
			_uitabList:Create(tabScroll, list, function(...)
				self:TabListItem(...)
			end)
		end
		_uitabList:EnableScroll(#list > 4,true)
	end

	local _tabPos = 1
	if notBuyPos > 0 then
		_tabPos = notBuyPos
		printInfoN(string.format("未购买的 tabpos %s", curSelect))
	else
		_tabPos = curSelect == -1 and 1 or curSelect
		printInfoN(string.format("tabpos %s", curSelect))
	end
	if isMoreType and _uitabList then
		_uitabList:MoveToPos(_tabPos)
	end
	self:OnClickTab(_tabPos)
end

function UIPop4Gift:CheckActivityIsBuy(sid, entryId)
	local apList = self._activityPageKeyList
	if (apList and apList[sid]) then
		local page = apList[sid][1]
		if (page and page.entry[entryId]) then
			local entryData = page.entry[entryId]
			if (entryData) then
				local marketData = entryData.MarketData
				local personal = marketData.personal
				local personalGoal = marketData.personalGoal
				local lastBuyTime = personalGoal - personal
				return lastBuyTime == 0
			end
		end
		return
	end
end
function UIPop4Gift:OnClickIce2Tab(itempos)
	local list = gModelPopupGift:GetGiftArrByRefId(self._curRefId)
	self._ice2TabIndex = itempos
	local ref = list[itempos]
	if (not ref) then
		self:OnClickClose()
		return
	end
	if(ref.refId==self._curRefId)then
		return
	end
	self._curRefId = ref.refId
	self._curGiftGroup = ref.giftGroup
	self._isClickTab = true
	self:ShowIcePart2()
end

function UIPop4Gift:InitGiftList()
	local list = self._dataList
	if (#list < 1) then
		self:WndClose()
		return false
	end
	CS.ShowObject(self.mGiftScroll1, false)
	CS.ShowObject(self.mGiftScroll2, false)
	CS.ShowObject(self.mLeftBtn, false)
	CS.ShowObject(self.mRightBtn, false)

	self._giftTransList = {}
	CS.ShowObject(self.mGiftBg, #list > 1)
	if (#list <= 4) then
		local _uiGiftList1 = self._uiGiftList1
		if (_uiGiftList1) then
			_uiGiftList1:RefreshList(list)
		else
			_uiGiftList1 = self:GetUIScroll("GiftScroll1")
			_uiGiftList1:Create(self.mGiftScroll1, list, function(...)
				self:GiftListItem(...)
			end)
			self._uiGiftList1 = _uiGiftList1
		end
		_uiGiftList1:EnableScroll(false)
		CS.ShowObject(self.mGiftScroll1, #list > 1)
	else
		CS.ShowObject(self.mLeftBtn, true)
		CS.ShowObject(self.mRightBtn, true)
		local _uiGiftList2 = self._uiGiftList2
		if (_uiGiftList2) then
			_uiGiftList2:RefreshList(list)
		else
			_uiGiftList2 = self:GetUIScroll("GiftScroll2")
			_uiGiftList2:Create(self.mGiftScroll2, list, function(...)
				self:GiftListItem(...)
			end, UIItemList.NORMAL)
			self._uiGiftList2 = _uiGiftList2
			_uiGiftList2:EnableScroll(true, true)
			self:JumpTargetGiftDelay(self._index)
		end
		CS.ShowObject(self.mGiftScroll2, #list > 1)
		self:SetWndClick(self.mLeftBtn, function(...)
			local _index = self._index
			if _index - 1 >= 1 then
				self._index = _index - 1
				self._tabIndex = 1
				self:OnClickGift(self._index, true)
			end
		end)
		self:SetWndClick(self.mRightBtn, function(...)
			local _index = self._index
			if _index + 1 <= #list then
				self._index = _index + 1
				self._tabIndex = 1
				self:OnClickGift(self._index, true)
			end
		end)

		_uiGiftList2:MoveToPos(self._index)
	end
end
function UIPop4Gift:RefreshUIByActivityPageResp()
	if (self._activityPageKeyList[self._curSid]) then
		local pageData = self._activityPageKeyList[self._curSid][1]
		if(not pageData)then
			return
		end
		local entryData = pageData.entry[self._curRefId]
		local marketData = entryData.MarketData
		local personal = marketData.personal
		local personalGoal = marketData.personalGoal
		local hasBuyTime = personalGoal == -1 and -1 or personalGoal - personal
		self:SetBuyLimitTxt(hasBuyTime)
		local customGift = marketData.customGift
		if (customGift) then
			self:SetGiftRoot()
		end

	end
end

function UIPop4Gift:OnClickGift(itempos, needJump)
	self._curRefId = nil
	self:OnSelectIndex(itempos, needJump)
	self:RefreshTopContent()
	self:ChackHadActivityItem()
end

--检查活动弹框是否购买前置礼包
function UIPop4Gift:CheckActivityIsBuyPrior(giftList, curRefId)
	if (not self._activityPageKeyList) then
		return
	end
	for i, v in pairs(giftList) do
		local priorRefId = giftList[i].refId
		if(not self._activityPageKeyList[self._curSid])then
			return
		end
		local pageData = self._activityPageKeyList[self._curSid][1]
		local entryData = pageData.entry[priorRefId]
		local marketData = entryData.MarketData
		local personal = marketData.personal
		if (personal == 0 and priorRefId < curRefId) then
			return true, giftList[i], i
		end
	end
end

function UIPop4Gift:RefreshTopContent()
	local gift = nil
	if self._curRefId then
		gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)
	end

	if not gift then
		local gifts = self._dataList[self._giftIndex]
		if not gifts then
			return
		end

		local group = nil
		for k, v in pairs(gifts) do
			local tempGroup = v.ref.giftGroupCount
			if not group or group > tempGroup then
				group = tempGroup
				gift = v
			end
		end

		if not gift then
			return
		end
	end

	self._curActiveGift = gift
	self._curRefId = gift.ref.refId
	self._curSid = gift.ref.sid
	self._curGiftGroup = gift.ref.giftGroup
	self._curGiftShowType = gift.ref.giftShowType

	local type = gift.isActivity and 2 or gift.ref.giftType
	if type == 1 then
		if(self._curGiftShowType == 4)then
			self:ShowIcePart2()
		else
			self:ShowIcePart()
		end
	else
		self:SetGiftRoot()
	end
end

--设置形象
function UIPop4Gift:SetSpine(showHero,showXY,spPos,showScale)
	local showSpineNode = not string.isempty(showHero)
	CS.ShowObject(self.mSpPos,showSpineNode)
	if not showSpineNode then return end
	spPos = spPos or self.mSpPos
	local x,y
	if not string.isempty(showXY) then
		local showXYInfo = string.split(showXY,",")
		x,y = tonumber(showXYInfo[1]),tonumber(showXYInfo[2])
	else
		local recordSpinePox = self._recordSpinePox
		x,y = recordSpinePox.x,recordSpinePox.y
	end

	local spine = showHero
	local key = "spine"
	if (self._oldSpine and self._oldSpine ~= spine and self._oldKey and self._oldKey == key) then
		self:DestroyWndSpineByKey(key)
	end
	---@param dpSpine LDisplaySpine
	self:CreateWndSpine(spPos, spine, key, false, function(dpSpine)
		local dpTrans = dpSpine:GetDisplayTrans()
		dpTrans.anchorMin = Vector2.New(0.5, 0.5)
		dpTrans.anchorMax = Vector2.New(0.5, 0.5)
		self:SetAnchorPos(spPos,Vector2(x,y))
		if showScale and showScale > 0 then
			dpSpine:SetScale(showScale)
		end
	end)
	self._oldKey = key
	self._oldSpine = spine
end

function UIPop4Gift:OnTimer(key)
	if (key == self._timeKey) then
		self:SetTime()
	elseif key == self._iceCountDown then
		self:SetIceCountDown()
	elseif key == self._ice2CountDown then
		self:SetIce2CountDown()
	end
end
function UIPop4Gift:SetIce2HeroSpine(root,ref)
	local showIcon = ref.showIcon
	local showIconArr = string.split(showIcon,"=")
	local showIcon = self:FindWndTrans(root,"ShowIcon")
	CS.ShowObject(showIcon,showIconArr[1] == "1")
	if showIconArr[1] == "1" then
		self:SetWndEasyImage(showIcon,showIconArr[2])
		local showIconPos = string.split(ref.showIconPos,",")
		showIcon.localPosition = Vector2.New(tonumber(showIconPos[1]),tonumber(showIconPos[2]))
		showIcon.localScale = Vector3(ref.showIconSize,ref.showIconSize,ref.showIconSize)
		local bFilp = ref.flip == 1
		self._skeleton.ScaleX = (bFilp and -1 or 1)
	else
		self:SetIce2Spine(root,showIconArr[2],ref)
	end
end

function UIPop4Gift:StartDelayTimer(ResultNode, normalized)
	if not ResultNode then
		return
	end
	local resultNode = ResultNode:GetComponent(typeOfScrollRect)
	if self._delayUpdateScrollTimer then
		return
	end
	self._delayUpdateScrollTimer = LxTimer.DelayFrameCall(function()
		if normalized then
			resultNode.verticalNormalizedPosition = normalized
		end
		self._delayUpdateScrollTimer = nil
	end, 1)
end

function UIPop4Gift:SetBuyLimitTxt(hasBuyTime)
	if (not self.buyLimitTxt) then
		return
	end
	if(not hasBuyTime)then
		self:SetWndText(self.buyLimitTxt, "")
		return
	end
	local limitColor = hasBuyTime > 0 and "<#139057>" or "<#c81212>"
	local buyLimitStr = hasBuyTime == -1 and "" or string.format("%s%s%s%s", ccClientText(31700), limitColor, tostring(hasBuyTime), "</color>")
	self:SetWndText(self.buyLimitTxt, buyLimitStr)
	CS.ShowObject(self.payMask, hasBuyTime == 0 and hasBuyTime~=-1)
	CS.ShowObject(self.payBtn, hasBuyTime ~= 0)
end

--点击购买
function UIPop4Gift:OnClickPay()
	local wndName = self:GetWndName()
	local customReward = self._curSid and "" or nil
	if (self._curSid and self._activityPageKeyList) then
		customReward = self._activityPageKeyList[self._curSid][1].entry[self._curRefId].MarketData.customGift
	end
	gModelPopupGift:BuyGift(self._curRefId, wndName, self._curSid, customReward)
end

function UIPop4Gift:ChangeGiftImage(trans, bool, isGift)
	if not trans then
		return
	end
	local RootTrans = self:FindWndTrans(trans, "Root")
	if not RootTrans then
		RootTrans = trans
	end
	local selImage = self:FindWndTrans(RootTrans, "SelImage")

	local nameText, SelNameText
	if isGift then
		local nameListRoot = self:FindWndTrans(trans, "NameList")
		nameText = self:FindWndTrans(nameListRoot, "NameText")
		SelNameText = self:FindWndTrans(nameListRoot, "SelNameText")
	else
		nameText = self:FindWndTrans(RootTrans, "NameText")
		SelNameText = self:FindWndTrans(RootTrans, "SelNameText")
	end

	--local Image = self:FindWndTrans(RootTrans, "Image")
	--
	--if Image and isGift then
	--	local rotation = bool and Quaternion.Euler(0, 0, 0) or Quaternion.Euler(0, 0, 90)
	--	Image.localRotation = rotation
	--
	--	local scale = bool and Vector3(1, 1, 1) or Vector3(0.8, 0.8, 0.8)
	--	RootTrans.localScale = scale
	--end
	local Image = self:FindWndTrans(RootTrans, "Image")
	CS.ShowObject(Image, not bool)
	CS.ShowObject(selImage, bool)
	CS.ShowObject(nameText, not bool)
	CS.ShowObject(SelNameText, bool)
end
function UIPop4Gift:SetIce2TabList(tabTrans)
	local list = gModelPopupGift:GetGiftArrByRefId(self._curRefId)
	CS.ShowObject(tabTrans, #list > 1)
	self._ice2TabTransList = {}
	if #list > 1 then
		local _uitabList = self:FindUIScroll("tabScroll1")
		if _uitabList then
			_uitabList:RefreshList(list)
		else
			_uitabList = self:GetUIScroll("tabScroll1")
			_uitabList:Create(tabTrans, list, function(...)
				self:Ice2TabListItem(...)
			end)
		end
	end
end

function UIPop4Gift:CheckSoleGroupOver(giftGroup,sid)
	if (not self._activityPageKeyList) then
		return
	end
	local giftGroupList = gModelPopupGift:GetActivityGiftArrListByGroup(sid, giftGroup)
	if (giftGroupList) then
		if (not self._activityPageKeyList[sid]) then
			return
		end
		local pageData = self._activityPageKeyList[sid][1]
		local buyCnt = 0
		local giftCnt = 0
		for i, v in pairs(giftGroupList) do
			giftCnt = giftCnt+1
			local entryData = pageData.entry[v.refId]
			local marketData = entryData.MarketData
			local personal = marketData.personal
			local personalGoal = marketData.personalGoal
			if (personalGoal~=-1 and personalGoal - personal == 0) then
				buyCnt = buyCnt + 1
			end
		end
		return buyCnt == giftCnt
	end
end

function UIPop4Gift:GiftListItem(list, item, itemdata, itempos)
	self._giftTransList[itempos] = item
	local InstanceID = item:GetInstanceID()
	self:ChangeGiftImage(item, false, true)
	local RootTrans = self:FindWndTrans(item, "Root")
	local icon = self:FindWndTrans(RootTrans, "Icon")
	local nameListRoot = self:FindWndTrans(item, "NameList")
	local nameText = self:FindWndTrans(nameListRoot, "NameText")
	local SelNameText = self:FindWndTrans(nameListRoot, "SelNameText")
	local rateText = self:FindWndTrans(RootTrans, "RateBg/RateText")
	local eff = self:FindWndTrans(nameListRoot, "EffParent/Eff")

	local giftData = itemdata[1]

	local ref = giftData.ref
	self:SetWndEasyImage(icon, ref.icon, function()
		CS.ShowObject(icon,true)
	end)
	local giftName = ref.isActivity and ref.giftName or ccLngText(ref.giftName)
	self:SetWndText(nameText, giftName)
	self:SetWndText(SelNameText, giftName)
	self:SetWndText(rateText, ref.discount .. "%+")
	local list = gModelPopupGift:GetGiftArrByRefId(ref.refId, ref.sid)
	local isShowEff = false
	--for i, v in ipairs(list) do
	--	if v.buyType == 1 then
	--		isShowEff = true
	--		break
	--	end
	--end

	CS.ShowObject(eff, isShowEff)
	if isShowEff then
		self:CreateWndEffect(eff, "fx_zuanshilibao", InstanceID, 100, false, false)
	end
	self:SetWndClick(item, function()
		self._index = itempos
		self._tabIndex = 1

		local attr1 = gModelPopupGift:FormatPopGiftStr(giftData, itempos)
		local attr2, attr3 = gModelPopupGift:GetAllIdStr()

		gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_POPUP_GIFT, "gift_select", attr1, attr2, attr3)
		self:OnClickGift(itempos)
	end)
end

function UIPop4Gift:InitCommand()
	local curId = self:GetWndArg("id")
	local index = self:GetWndArg("index")
	local dataList = self:GetWndArg("dataList")

	if not dataList then
		dataList, index = gModelPopupGift:GetPopGiftShowList(curId, 1)
	end
	index=index or 1
	self._index = index or 1
	self._dataList = dataList

	self:InitGiftList()

	local needJump = #dataList > 5


	self:OnClickGift(index, needJump)
end

function UIPop4Gift:OnSelectIndex(itempos, needJump)
	if self._giftIndex > 0 then
		local trans = self._giftTransList[self._giftIndex]
		self:ChangeGiftImage(trans, false, true)
	end
	local trans = self._giftTransList[itempos]
	self:ChangeGiftImage(trans, true, true)

	self._giftIndex = itempos

	if needJump and (self._uiGiftList1 or self._uiGiftList2) then
		self:JumpTargetGift(itempos)
	end
end
--设置形象
function UIPop4Gift:SetIce2Spine(paintTans,prefabName,ref)
	if not ref then
		return
	end
	local spine = prefabName
	local key = prefabName
	if(self._oldSpine and self._oldSpine ~= spine and self._oldKey and self._oldKey == key)then
		self:DestroyWndSpineByKey(key)
	end
	self:CreateWndSpine(paintTans,spine,key,false,function(dpSpine)
		local dpTrans = dpSpine:GetDisplayTrans()
		dpTrans.anchorMin = Vector2.New(0.5,0.5)
		dpTrans.anchorMax = Vector2.New(0.5,0.5)
		dpSpine:SetFlipX(ref.flip == 1)
		dpSpine:SetScale(ref.showIconSize)
		local showIconPos = string.split(ref.showIconPos,",")
		dpTrans.localPosition = Vector2.New(tonumber(showIconPos[1]),tonumber(showIconPos[2]))
		dpSpine:SetRaycastTarget(false)
	end)
	self._oldKey = key
	self._oldSpine = spine
end

function UIPop4Gift:ShowRewardList(ref, root)
	local dataList = {}
	if not string.isempty(ref.reward) then
		local itemList = LxDataHelper.ParseItem(ref.reward)
		for k, v in ipairs(itemList) do
			local data = {
				rewardType = 1,
				itemdata = v
			}
			table.insert(dataList, data)
		end
	end

	local giftData = gModelPopupGift:GetGiftByRefId(ref.refId, self._curSid)

	if not string.isempty(ref.rewardFree) then
		local freeList = string.split(ref.rewardFree, '|')
		local cnt = #freeList

		local record = {}
		local rewardStr = nil
		if giftData then
			if (ref.isActivity) then
				if (self._activityPageKeyList) then
					if(not self._activityPageKeyList[self._curSid])then
						return
					else
						rewardStr = self._activityPageKeyList[self._curSid][1].entry[self._curRefId].MarketData.customGift
					end
				end
			else
				rewardStr = giftData.reward
			end
		else
			rewardStr = gModelPopupGift:GetSelectReward(ref.refId)
		end
		record = LxDataHelper.ParseItem(rewardStr, ',') or {}

		for k = 1, cnt do
			local data = {
				rewardType = 2,
				index = k,
				itemdata = record[k],
			}

			table.insert(dataList, data)
		end
	end

	local isMore = #dataList > 4

	local minRoot = CS.FindTrans(root, "ItemScroll_3")
	local moreRoot_1 = CS.FindTrans(root, "ItemScroll_1")
	local moreRoot_2 = CS.FindTrans(root, "ItemScroll_2")
	CS.ShowObject(minRoot, not isMore)
	CS.ShowObject(moreRoot_1, isMore)
	CS.ShowObject(moreRoot_2, isMore)
	if isMore then
		--拆分数据
		local len = #dataList

		local showData_1 = {}
		local showData_2 = {}
		for i = 1, 3 do
			table.insert(showData_1, dataList[i])
		end

		for i = 4, len do
			table.insert(showData_2, dataList[i])
		end

		local instanceId = moreRoot_1:GetInstanceID()

		local list = self:FindUIScroll(instanceId)
		if not list then
			list = self:GetUIScroll(instanceId)
			list:Create(moreRoot_1, showData_1, function(...)
				self:OnDrawItem(...)
			end)
		else
			list:RefreshList(showData_1)
		end
		list:EnableScroll(false, true)

		--这里设置位置
		local x = 100 + (4 - #showData_1) * 50
		self:SetAnchorPos(moreRoot_1, Vector2.New(x, moreRoot_1.anchoredPosition.y))

		instanceId = moreRoot_2:GetInstanceID()

		list = self:FindUIScroll(instanceId)
		if not list then
			list = self:GetUIScroll(instanceId)
			list:Create(moreRoot_2, showData_2, function(...)
				self:OnDrawItem(...)
			end)
		else
			list:RefreshList(showData_2)
		end
		list:EnableScroll(false, true)

		x = 100 + (4 - #showData_2) * 50
		self:SetAnchorPos(moreRoot_2, Vector2.New(x, moreRoot_2.anchoredPosition.y))
	else
		local instanceId = minRoot:GetInstanceID()

		local list = self:FindUIScroll(instanceId)
		if not list then
			list = self:GetUIScroll(instanceId)
			list:Create(minRoot, dataList, function(...)
				self:OnDrawItem(...)
			end)
		else
			list:RefreshList(dataList)
		end
		--这里设置位置
		local x = 100 + (4 - #dataList) * 50
		self:SetAnchorPos(minRoot, Vector2.New(x, minRoot.anchoredPosition.y))
		list:EnableScroll(false, true)
	end

	--local instanceId = root:GetInstanceID()
	--
	--local list = self:FindUIScroll(instanceId)
	--if not list then
	--	list = self:GetUIScroll(instanceId)
	--	list:Create(root, dataList, function(...)
	--		self:OnDrawItem(...)
	--	end)
	--else
	--	list:RefreshList(dataList)
	--end
	--
	--local itemRoot = self:FindWndTrans(root, "ItemRoot")
	--local rectTran = self:FindCommonComponent(itemRoot, typeOfRectTransform)
	--local isMore = #dataList > 4
	--list:EnableScroll(isMore, isMore)
	--
	--rectTran.anchorMin = isMore and Vector2(0, 0.5) or Vector2(0.5, 0.5)
	--rectTran.anchorMax = isMore and Vector2(0, 0.5) or Vector2(0.5, 0.5)
	--rectTran.anchoredPosition = Vector2(0, 0)
	--rectTran.pivot = isMore and Vector2(0, 0.5) or Vector2(0.5, 0.5)
end
function UIPop4Gift:OpenCustomWnd(index)

	local gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)
	if not gift then
		local str = ccClientText(14911)-- "当前礼包不可购买")
		GF.ShowMessage(str)
		return
	end
	local ref = gift.ref
	if string.isempty(ref.rewardFree) then
		return
	end

	local marketData = {
		customList = ref.rewardFree,
		customGift = gift.reward
	}
	if(self._curSid and ref.isActivity)then
		marketData.customGift = self._activityPageKeyList[self._curSid][1].entry[self._curRefId].MarketData.customGift
	end
	local giftData = {
		marketData = marketData
	}
	local isSoleOut = self:CheckCurActGiftIsSoleOut()
	if(isSoleOut)then
		local targetGiftArr = string.split(marketData.customGift,",")
		local tmpGiftDataArr = string.split(targetGiftArr[1],"=")
		local data = {itemId = tonumber(tmpGiftDataArr[2]),itemType = tonumber(tmpGiftDataArr[1]),itemNum = tonumber(tmpGiftDataArr[3])}
		gModelGeneral:ShowCommonItemTipWnd(data)
		return
	end
	local giftName = ref.isActivity and ref.giftName or ccLngText(ref.giftName)
	local windType = ref.isActivity and 1 or 2
	local para = {
		wndType = windType,
		id = gift.id,
		itemIndex = index,
		giftData = giftData,
		title = giftName,

		sid = ref.sid,
		pageId = ref.pageId,
		entryId = ref.refId
	}

	printInfoN("refId " .. ref.refId)
	GF.OpenWnd("UICumSelectNew", para)
end

function UIPop4Gift:OnDrawItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item, "root")
	local rootClick = self:FindWndTrans(root, "click")
	local clickItem = self:FindWndTrans(rootClick, "item")
	local itemAdd = self:FindWndTrans(clickItem, "add")
	local itemIcon = self:FindWndTrans(clickItem, "icon")
	local itemShift = self:FindWndTrans(clickItem, "shift")

	local showShift = false
	local showItem = false
	if itemdata.rewardType == 1 then
		self:CreateCommonIconImpl(itemIcon, itemdata.itemdata, { noClick = true })

		self:SetWndClick(rootClick, function()
			local gift = self:GetCurActiveGift()
			local giftGroupCount = gift.giftGroupCount
			local attr1 = gModelPopupGift:FormatPopGiftStr(gift, giftGroupCount)
			local attr2 = tostring(itemdata.itemId)
			gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_POPUP_GIFT, "reward_preview", attr1, attr2)
			gModelGeneral:ShowCommonItemTipWnd(itemdata.itemdata, {showSkinCode=true})
		end)
		showItem = true
	else
		self:SetWndClick(rootClick, function()
			self:OpenCustomWnd(itemdata.index)
		end)

		if itemdata.itemdata then
			self:CreateCommonIconImpl(itemIcon, itemdata.itemdata, { noClick = true })
		end
		showShift = itemdata.itemdata ~= nil
		showItem = showShift

	end
	CS.ShowObject(itemShift, showShift)
	CS.ShowObject(itemIcon, showItem)
	item.localScale = Vector3.New(0.9, 0.9, 0.9)
end
--活动新触发标记
function UIPop4Gift:ActivitySandNewGift(giftList)
	local giftIdList = ""
	for i, v in pairs(giftList) do
		giftIdList = giftIdList == "" and tostring(v.refId) or giftIdList..","..v.refId
	end
	gModelActivity:OnActivitySpecialOpReq(self._curSid,1,self._curRefId,nil,giftIdList,ModelActivity.POPUP_NEW_GIFT)
end

function UIPop4Gift:InitEvent()
	self:SetWndClick(self.mCloseBtn, function(...)
		self:OnClickClose()
	end)
	self:SetWndClick(self.mBtnClose, function()
		self:OnClickClose()
	end)

	self.mIntro.sizeDelta = Vector2(480, 55)
end

---@return boolean 是否未购买
function UIPop4Gift:CheckActivityIsNoBuy(sid,entryId)
	local apList = self._activityPageKeyList
	if (apList and apList[sid]) then
		local page = apList[sid][1]
		if (page and page.entry[entryId]) then
			local entryData = page.entry[entryId]
			if (entryData) then
				local marketData = entryData.MarketData
				return marketData.personal == 0
			end
		end
	end
	return false
end

function UIPop4Gift:OnClickClose()
	local gift = self:GetCurActiveGift()
	local giftGroupCount = gift.ref.giftGroupCount
	local attr1 = gModelPopupGift:FormatPopGiftStr(gift, giftGroupCount)
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_POPUP_GIFT, "close", attr1)

	--FireEvent(EventNames.REFRESH_ACTIVITY_POPGIFT_DATA)
	self:WndClose()
end


function UIPop4Gift:SetIceCountDown()
	local gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)
	local ref = gift.ref
	local endTime = gift.isActivity and gift.endTime or gift.endTime / 1000
	local timespan = math.ceil(endTime - GetTimestamp())
	if timespan > 0 then
		local timeStr = LUtil.FormatTimespanNumber(timespan)
		--local description = ref.isActivity and ref.description or ccLngText(ref.description)
		local description = ccClientText(45301)
		local str = string.replace(description, timeStr)
		--self:SetWndText(self.mIntro, str)
		self:SetWndText(self.mCutDownTime, str)
	else
		self:TimerStop(self._iceCountDown)
	end

end
function UIPop4Gift:SetIce2CountDown()
	local endTime = self._ice2GiftEndTime
	local timespan = math.ceil(endTime - GetTimestamp())
	if timespan > 0 then
		local timeStr = LUtil.FormatTimespanNumber(timespan)
		self:SetWndText(self.mIcePart2TimeText,string.replace(ccClientText(14901),timeStr))
	else
		self:SetWndText(self.mIcePart2TimeText,"")
		self:TimerStop(self._ice2CountDown)
	end
end

function UIPop4Gift:SetTime()
	local _gift = gModelPopupGift:GetGiftByRefId(self._curRefId, self._curSid)
	local _desTrans = self._desTrans
	if not _desTrans or not _gift then
		if(self._curSid and self._curRefId)then
			self:OnClickClose()
		end
		return
	end
	local time = GetTimestamp()
	local endTime =  _gift.endTime / 1000
	if _gift.sid and _gift.sid > 0 then
		local activityData = gModelActivity:GetActivityBySid(_gift.sid)
		if activityData and activityData.status ~= ModelActivity.STATUS_NO_SHOW then
			if activityData.endTime < endTime then
				endTime = activityData.endTime
			end
		end
	end
	local timespan = endTime - time
	if (timespan <= 0) then
		self:TimerStop(self._timeKey)
		if(_gift.isActivity)then
			self:OnClickClose()
		end
		return
	end
	local ref = _gift.ref
	local timeStr = LUtil.FormatTimespanNumber(timespan)
	local desStr = _gift.isActivity and ref.description or ccLngText(ref.description)
	local str = string.replace(desStr, timeStr)
	local desText = CS.FindTrans(_desTrans, "DesText")
	self:UpdateResultText(desText, _desTrans, str)
end

function UIPop4Gift:TabListItem(list, item, itemdata, itempos)
	self._tabTransList[itempos] = item
	local InstanceID = item:GetInstanceID()
	self:ChangeGiftImage(item, false)
	local text = self:FindWndTrans(item, "NameText")
	local SelNameText = self:FindWndTrans(item, "SelNameText")
	local eff = self:FindWndTrans(item, "Eff")
	local giftGradeName = itemdata.isActivity and ccLngText(itemdata.giftGradeName) or ccLngText(itemdata.giftGradeName)
	local str = string.replace(ccClientText(14908), giftGradeName)
	self:SetWndText(text, str)
	self:SetWndText(SelNameText, str)
	local isShowEff = itemdata.buyType == 1
	isShowEff = false
	CS.ShowObject(eff, isShowEff)
	if isShowEff then
		self:CreateWndEffect(eff, "fx_zuanshilibao", InstanceID, 100, false, false)
	end

	self:SetWndClick(item, function()
		local gift = self:GetCurActiveGift()
		local giftGroupCount = itemdata.giftGroupCount
		local attr1 = gModelPopupGift:FormatPopGiftStr(gift, giftGroupCount)
		gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_POPUP_GIFT, "gift_detail_select", attr1)

		self:OnClickTab(itempos)
	end)
end

function UIPop4Gift:ChackHadActivityItem()
	if(self._dataList and self._dataList[self._index] and self._dataList[self._index][1])then
		local curData = self._dataList[self._index][1]
		if (curData.isActivity) then
			gModelActivity:OnActivityPageReq(curData.sid)
		end
	end
end

--endregion
------------------------------------------------------------------
return UIPop4Gift


