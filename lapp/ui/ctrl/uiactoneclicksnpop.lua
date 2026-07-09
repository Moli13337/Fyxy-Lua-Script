---
--- Created by Administrator.
--- DateTime: 2023/10/23 21:12:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActOneClickSnPop:LWnd
local UIActOneClickSnPop = LxWndClass("UIActOneClickSnPop", LWnd)

local typeof = typeof
local CS = CS
local typeofGridLayoutGroup = typeof(CS.GridLayoutGroup)
local Tweening = DG.Tweening

UIActOneClickSnPop.SKIN_MIN_ID = 10000000
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActOneClickSnPop:UIActOneClickSnPop()
	--一行最大显示道具数
	self._lineItemNum = 4
	self._itemTempPath = "Item"

	self._arrowUpTweenKey = "_arrowUpTweenKey"
	self._arrowDownTweenKey = "_arrowDownTweenKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActOneClickSnPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActOneClickSnPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActOneClickSnPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitParam()
	self:InitStatic()
end

function UIActOneClickSnPop:OnClickBuyBtn()
	local price = self._price
	if not price then return end

	local entryIdList = {}
	for k,v in ipairs(self._pageData) do
		table.insert(entryIdList, v.entryId)
	end

	local sid 		 = self._sid
	local entryIsStr = table.concat(entryIdList, "#")
	gModelPay:GiftPayCtrl(entryIsStr, price, ModelPay.PAY_TYPE_ACTIVITY, 0, sid, 1)
end

function UIActOneClickSnPop:OnItemReachHead(bool)
	if bool then
		self._showArrowUp = false
		self._showArrowDown = true
	else
		self._showArrowUp = true
	end
	self:RefreshScrollArrow()
end
--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIActOneClickSnPop:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:InitData()
	self:InitTop()

	gModelActivity:OnActivityPageReq(self._sid)
end

function UIActOneClickSnPop:OnActivityListResp(pb)
	local activities = pb.activities
	for i, v in ipairs(activities) do
		local sid = v.sid
		if self._sid == sid then
			self:InitData()
			self:RefreshUI()
			break
		end
	end
end

function UIActOneClickSnPop:OnDrawRewardListCell(list, item, itemdata, itempos)
	for i = 1, self._lineItemNum do
		local itemTemp = self:FindWndTrans(item, self._itemTempPath..i)
		self:OnDrawRewardItemCell(list,itemTemp,itemdata[i],i)
	end
end

function UIActOneClickSnPop:GetScoreByItemId(itemId)
	if itemId > self.SKIN_MIN_ID then
		--皮肤道具
		return 100
	elseif itemId == ModelItem.ITEM_DIAMOND then
		return 10
	else
		return 1
	end
end

function UIActOneClickSnPop:OnActivityPageResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then return end

	self:ResetActivePageData(pb)
	self:RefreshUI()
end

function UIActOneClickSnPop:ResetActivePageData(pb)
	local activityPage
	for i, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		if v.pageId == 1 and page then
			activityPage = page
			break
		end
	end

	if not activityPage then
		printInfoNR("activityPage is a nil")
		return
	end

	self._isBuyAll = true
	self._pageData = {}
	for k,v in pairs(activityPage.entry) do
		local entryCfg  = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		if entryCfg then
			local marketData 	= v.MarketData
			local personal 		= marketData.personal; -- 已使用个人限购次数
			local personalGoal	= marketData.personalGoal; -- 个人可购买次数
			local haveCount		= personalGoal - personal
			--local expend2 		= tonumber(entryCfg.expend2)

			local data = {
				entryId = v.entryId,
				pageId = v.pageId,
				id 	   = entryCfg.id,
				reward = LxDataHelper.ParseItem(entryCfg.reward),
				sort   = entryCfg.sort,
				haveCount = haveCount,
			}
			table.insert(self._pageData, data)

			if haveCount > 0 then
				self._isBuyAll = false
			end
		end
	end
end

function UIActOneClickSnPop:InitParam()
	self._func = self:GetWndArg("func")
	self._sid = self:GetWndArg("sid")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end

	--已全部购买
	self._isBuyAll = nil
	self._scrollArrowStateList = {
		_up = false,
		_down = false,
	}

	self._showArrowUp = false
	self._showArrowDown = true

	self._upArrowPos = {
		_form = Vector3.New(-20, 1, 0),
		_to   = Vector3.New(-20, 15, 0),
	}

	self._downArrowPos = {
		_form = Vector3.New(-20, -242, 0),
		_to   = Vector3.New(-20, -262, 0),
	}

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActOneClickSnPop:GetCombinationRewardList()
	local rewardList = self:GetRewardList()
	local rewardNum  = #rewardList

	local combinationRewardList = {}
	local curCombinationData = {}
	for i = 1, rewardNum do
		local curData = rewardList[i]
		table.insert(curCombinationData, curData)

		if i % self._lineItemNum == 0 or i == rewardNum then
			table.insert(combinationRewardList, curCombinationData)
			curCombinationData = {}
		end
	end

	return combinationRewardList
end

function UIActOneClickSnPop:InitEvent()
	self:SetWndClick(self.mBg,function ()
		self:CloseWndFunc()
	end)

	self:SetWndClick(self.mGoTo,function ()
		self:OnClickBuyBtn()
	end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIActOneClickSnPop:OnDrawRewardItemCell(list,item,itemdata,itempos)
	local haveData = itemdata ~= nil
	CS.ShowObject(item, haveData)
	if not haveData then return end

	local CommonTrans = self:FindWndTrans(item,"CommonUI")
	local iconTrans = self:FindWndTrans(CommonTrans,"Icon")
	local maskTrans = self:FindWndTrans(item, "Mask")
	local instanceId = item:GetInstanceID()
	local haveCount   = itemdata.haveCount
	local itemId   = itemdata.itemId
	local itemType = itemdata.itemType
	local itemNum  = itemdata.itemNum
	local itemData =
	{
		itemId   = itemId,
		itemType = itemType,
		itemNum  = itemNum,
	}

	local isShowMask = haveCount == 0 and itemId > self.SKIN_MIN_ID
	CS.ShowObject(maskTrans, isShowMask)

	local uiIconClass = self:GetCommonIcon(instanceId)
	uiIconClass:Create(iconTrans)
	uiIconClass:SetCommonReward(itemType, itemId, itemNum)
	uiIconClass:EnableShowNum(true)
	uiIconClass:DoApply()

	self:SetIconClickScale(iconTrans, true)
	self:SetWndClick(iconTrans,function()
		gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)
end

function UIActOneClickSnPop:CloseWndFunc()
	GF.OpenWnd("UIActOneClickSn",{sid = self._sid})
	self:WndClose()
end

function UIActOneClickSnPop:InitRewardList()
	local list = self:GetCombinationRewardList()
	self._rewardMaxNum = #list

	local uiRewardList = self._uiRewardList
	if uiRewardList then
		uiRewardList:RefreshList(list)
	else
		uiRewardList = self:GetUIScroll("uiRewardList")
		self._uiRewardList = uiRewardList
		uiRewardList:Create(self.mRewardList,list,function(...) self:OnDrawRewardListCell(...) end, UIItemList.SUPER)
		--显示上下箭头，表示可滑动
		local uiList = uiRewardList:GetList()
		uiList:EnableLoadAnimation(true)
		uiList:SetLoadAnimationScale(0.2, 0.15)
		uiList:SetFuncOnItemReachHead(function (...) self:OnItemReachHead(...) end)
		uiList:SetFuncOnItemReachTail(function (...) self:OnItemReachTail(...) end)
	end
end

--####################################################################################################################
--### Common #########################################################################################################
--####################################################################################################################
function UIActOneClickSnPop:InitTop()
	local config = self._webCfg
	if not config then return end

	local buyAllTxt = config.buyAllTxt
	if not string.isempty(buyAllTxt) then
		self:SetWndText(self.mHelpText, buyAllTxt)
		CS.ShowObject(self.mHelpBg, true)
	end

	local showPrice = config.showPrice
	local isShowPrice = not string.isempty(showPrice)
	if isShowPrice then
		self:SetWndText(self.mOriginalText, showPrice)
	end
	CS.ShowObject(self.mOriginalText, isShowPrice)

	local isUSAForeign = gLGameLanguage:IsUSARegion()
	CS.ShowObject(self.mOriginalImage, not isUSAForeign)

	local payStr = gModelPay:GetShowByWelfareId(self._price)
	self:SetWndButtonText(self.mGoTo, payStr)
end

function UIActOneClickSnPop:InitData()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end

	local config  = webData.config
	self._webCfg  = config
	self._price   = config.price

	if LxUiHelper.IsImgPathValid(config.image2) then
		local pos = config.imagePos2
		self:SetWndEasyImage(self.mBgImage,config.image2,function ()
			CS.ShowObject(self.mBgImage,true)
			if not string.isempty(pos) then
				self:SetAnchorPos(self.mBgImage, LxDataHelper.ParseVector2NotEmpty(pos))
			end
		end,true)
	else
		CS.ShowObject(self.mBgImage,true)
	end

end

function UIActOneClickSnPop:InitArrowTween(isUp)
	local tweenKey, trans, posList
	if isUp then
		tweenKey = self._arrowUpTweenKey
		trans    = self.mArrowUP
		posList  = self._upArrowPos
	else
		tweenKey = self._arrowDownTweenKey
		trans    = self.mArrowDown
		posList  = self._downArrowPos
	end

	local seqTween = self:TweenSeq_LocalMoveTrans(tweenKey, trans,
			posList._form, posList._to,
			0.5, nil, Tweening.Ease.InOutFlash)
	seqTween:SetLoops(-1,Tweening.LoopType.Yoyo)
end

function UIActOneClickSnPop:OnItemReachTail(bool)
	if bool then
		self._showArrowDown = false
		self._showArrowUp = true
	else
		self._showArrowDown = true
	end
	self:RefreshScrollArrow()
end

function UIActOneClickSnPop:InitStatic()
	self:SetWndText(self.mCloseTip,ccClientText(10103))

	self:InitArrowTween(true)
	self:InitArrowTween(false)
end

function UIActOneClickSnPop:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb) self:OnActivityListResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb) self:OnActivityPageResp(pb) end)
end

function UIActOneClickSnPop:RefreshScrollArrow()
	local isShowUp   = self._showArrowUp or false
	local isShowDown = self._showArrowDown or false

	local oldShowState = self._scrollArrowStateList
	if oldShowState._up ~= isShowUp then
		CS.ShowObject(self.mArrowUP, isShowUp)
		self._scrollArrowStateList._up = isShowUp
	end

	if oldShowState._down ~= isShowDown then
		CS.ShowObject(self.mArrowDown, isShowDown)
		self._scrollArrowStateList._down = isShowDown
	end
end

function UIActOneClickSnPop:GetRewardList()
	local rewardList = {}
	for k,v in ipairs(self._pageData) do
		local rewards = v.reward
		local haveCount = v.haveCount
		local sort    = v.sort
		for p,q in ipairs(rewards) do
			local rewardData = {
				itemType = q.itemType,
				itemId   = q.itemId,
				itemNum  = q.itemNum,
				haveCount = haveCount,
				sort     = sort,
			}
			table.insert(rewardList, rewardData)
		end
	end

	table.sort(rewardList, function(a, b)
		local itemIdA = a.itemId
		local itemIdB = b.itemId
		local scoreA = self:GetScoreByItemId(a.itemId)
		local scoreB = self:GetScoreByItemId(b.itemId)
		if scoreA ~= scoreB then
			return scoreA > scoreB
		end

		if itemIdA ~= itemIdB then
			return itemIdA < itemIdB
		end

		return a.sort < b.sort
	end)

	return rewardList
end

function UIActOneClickSnPop:RefreshUI()
	if self._isBuyAll then
		self:WndClose()
		return
	end

	self:InitRewardList()
end


------------------------------------------------------------------
return UIActOneClickSnPop


