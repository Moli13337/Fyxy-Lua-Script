---
--- Created by wzz.
--- DateTime: 2025/3/18 10:52:45
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDefenceWarGift:LWnd
local UIDefenceWarGift = LxWndClass("UIDefenceWarGift", LWnd)
------------------------------------------------------------------

local _buyTypeText = {
	[0] = ccClientText(42500),
	[1] = ccClientText(42501), -- 每日限购
	[2] = ccClientText(42502), -- 每周限购
	[3] = ccClientText(42503), -- 每月限购
	[4] = ccClientText(42504), -- 每月限购
}

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWarGift:UIDefenceWarGift()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWarGift:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWarGift:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDefenceWarGift:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._pageId = 3
	self._activeData = gModelDefenceWar:GetActivityData()
	self._activeWebData = gModelDefenceWar:GetWebActivityData()

	-- 每次恢复体力的点数
	self._recoverNum = 1
	self._recoverTime = self._activeWebData.config.roguelikeStaminaTime


	gModelActivity:OnActivityPageReq(self._activeData.sid)

	self:InitTexts()
	self:InitEvents()
	self:InitTimer()
	-- self:InitSpine()
	-- self:Refresh()
end

-- 获取数据列表
function UIDefenceWarGift:GetDataList()
	local pages = self._pages or {}
	local entries = pages[self._pageId] and pages[self._pageId].entry or {}

	local list = {}
	local chunk = self._activeWebData.chunk[self._pageId] or {}
	for k, v in ipairs(chunk.entries or {}) do
		local data = entries[v.id]
		table.insert(list, { ref = v, data = data })
	end

	table.sort(list, function(a, b)
		return a.ref.sort < b.ref.sort
	end)
	return list
end

-- 初始精灵
function UIDefenceWarGift:InitSpine()
	self:CreateWndSpine(self.mSpine, "LH_Shuiranniang01", "key", false, function(dpSpine)

	end)
end

-- 绘制列表item项
function UIDefenceWarGift:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			root     = item,
			txtTitle = CS.FindTrans(item, "TxtTitle"),
			txtLimit = CS.FindTrans(item, "TxtLimit"),
			itemList = CS.FindTrans(item, "ItemList"),
			buyOver  = CS.FindTrans(item, "BuyOver"),
			btnFree  = CS.FindTrans(item, "BtnFree"),
			btnBuy   = CS.FindTrans(item, "BtnBuy"),
			costIcon = CS.FindTrans(item, "BtnBuy/Cost/1/CostIcon"),
			costNum  = CS.FindTrans(item, "BtnBuy/Cost/CostNum"),
		}

		local uiList = UIIconEasyList:New()
		uiList:Create(self, itemCache.itemList)
		uiList:SetShowNum(true)
		uiList:SetIconParentPath("itemRoot")
		uiList:EnableScroll(true, true)
		itemCache.uiList = uiList

		self:SetComponentCache(instanceID, itemCache)
		self:SetTextTile(itemCache.btnFree, ccClientText(44301))
	end
	local ref = itemData.ref
	local data = itemData.data

	local welfareId = tonumber(ref.expend2)
	local priceStr = ""
	local showCostIcon = false
	local costItemNumStr = ""
	local showFree = false
	local showBuyOver = false

	local leftNum = ref.personLimit
	local maxNum = leftNum

	if data then
		leftNum = data.MarketData.personal
		if leftNum == maxNum then
			showBuyOver = true
		end
	end
	local strLimit = _buyTypeText[ref.condResetType] .. "：" .. leftNum .. "/" .. maxNum

	if welfareId then
		-- 计费点礼包
		priceStr = gModelPay:GetShowByWelfareId(welfareId)
	elseif string.isempty(ref.expend2) then
		-- 免费礼包
		showFree = true
	else
		-- 消耗物品
		local costItem = LUtil.GetRefItemData(ref.expend2)

		local priceIcon = gModelItem:GetItemImgByRefId(costItem.itemId)
		if priceIcon then
			self:SetWndEasyImage(itemCache.costIcon, priceIcon)
			showCostIcon = true
		end
		costItemNumStr = costItem.itemNum
	end
	if showBuyOver then
		showFree = false
	end


	CS.ShowObject(itemCache.btnFree, showFree)
	CS.ShowObject(itemCache.btnBuy, not showFree and not showBuyOver)
	CS.ShowObject(itemCache.buyOver, showBuyOver)
	self:SetWndText(itemCache.costNum, costItemNumStr)
	self:SetWndText(itemCache.txtTitle, ccLngText(ref.name))
	self:SetWndText(itemCache.txtLimit, strLimit)
	self:SetWndButtonText(itemCache.btnBuy, priceStr)

	-- 奖励
	local itemList = LUtil.GetRefItemDataList(ref.reward)
	itemCache.uiList:RefreshList(itemList)

	self:SetWndClick(itemCache.btnBuy, function()
		self:OnClickBtnBuy(itemData)
	end)
	self:SetWndClick(itemCache.btnFree, function()
		self:OnClickBtnBuy(itemData)
	end)
end

function UIDefenceWarGift:ResetData(pb)
	local _pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = page.pageId
		_pages[pageId] = page
	end
	self._pages = _pages
end

-- update
function UIDefenceWarGift:Update()
	local costItemId, maxNum = gModelDefenceWar:GetCostItemData()
	local hasNum = gModelItem:GetNumByRefId(costItemId)
	local leftTime = 0
	local leftTotalTime = 0
	local curTime = GetTimestamp()
	if hasNum < maxNum then
		leftTime = gModelDefenceWar:GetNextRecoverTime() - curTime

		if leftTime <= 0 then
			if self._sendMsgTimer and self._sendMsgTimer < os.time() then
				self._sendMsgTimer = os.time() + 3
				gModelDefenceWar:ProtectCityInfoReq()
			else
				if not self._sendMsgTimer then
					self._sendMsgTimer = os.time() + 3
					gModelDefenceWar:ProtectCityInfoReq()
				end
			end
			leftTime = 0
		end

		leftTotalTime = math.floor((maxNum - hasNum) / self._recoverNum) * self._recoverTime + leftTime
	else
		leftTime = 0
		leftTotalTime = 0
	end

	local strTime = ""
	if leftTotalTime > 0 then
		strTime = LUtil.FormatTimespanNumber(leftTotalTime)
		strTime = ccClientText(46841, strTime)
	end

	self:SetWndText(self.mTxtTimes, strTime)
	self:SetWndText(self.mTxtNum, hasNum .. "/" .. maxNum)
end

-- 点击购买按钮
function UIDefenceWarGift:OnClickBtnBuy(itemData)
	local ref = itemData.ref
	local welfareId = tonumber(ref.expend2)
	local entryId = ref.id
	local sid = self._activeData.sid
	if welfareId then
		-- 充值购买
		gModelPay:GiftPayCtrl(entryId, welfareId, ModelPay.PAY_TYPE_ACTIVITY, nil, sid, self._pageId)
		return
	end

	gModelActivity:OnActivityMarkeyBuyReq(sid, self._pageId, entryId)
end

-- 初始界面化文本
function UIDefenceWarGift:InitTexts()
	local config = self._activeWebData.config
	self:SetWndText(self.mTxtTitle, ccLngText(config.giftName))

	local costItemId = gModelDefenceWar:GetCostItemData()
	local imgPath = gModelItem:GetItemImgByRefId(costItemId)
	self:SetWndEasyImage(self.mItemIcon, imgPath)
end

-- 初始时间
function UIDefenceWarGift:InitTimer()
	local timePara = {
		key = 1,
		loopcnt = -1,
		interval = 1,
		timescale = false,
		callOnStart = true,
		func = function()
			self:Update()
		end
	}
	self:TimerStartImpl(timePara)
end

-- 刷新界面
function UIDefenceWarGift:Refresh()
	local list = self:GetDataList()

	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList

		uiList:Create(self.mList, list, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList:RefreshOnlyData(list)
		self._uiList:DrawAllItems()
	end
end

-- 初始事件
function UIDefenceWarGift:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)

	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		local activityData = gModelDefenceWar:GetActivityData()

		local sid = pb.sid
		if activityData and activityData.sid == sid then
			self:ResetData(pb)
			self:Refresh()
		end
	end)

	self:WndEventRecv(EventNames.On_Item_Change, function()
		self:Refresh()
	end)
	self:WndNetMsgRecv(LProtoIds.ChargeResp, function()
		gModelActivity:OnActivityPageReq(self._activeData.sid)
	end)
end

------------------------------------------------------------------
return UIDefenceWarGift