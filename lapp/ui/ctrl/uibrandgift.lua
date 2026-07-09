---
--- Created by Administrator.
--- DateTime: 2025/6/12 11:31:10
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandGift:LWnd
local UIBrandGift = LxWndClass("UIBrandGift", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandGift:UIBrandGift()
	self._refList = gModelBadge:GetBadgeGiftRefList()
	self._shopRef = gModelBadge:GetBadgeGiftShopRef()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandGift:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandGift:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandGift:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTexts()
	self:InitEvents()
	self:InitSpine()
	self:Refresh()
	gModelBadge:OnReqShop()
end

-- 初始事件
function UIBrandGift:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)


	self:WndEventRecv(EventNames.On_Item_Change, function()
		self:Refresh()
	end)

	self:WndEventRecv(EventNames.ON_SHOP_BUY_RETURN, function(...)
		self:Refresh()
		gModelRedPoint:SetBadgeGiftFreeRed()
	end)

	self:WndEventRecv(EventNames.ON_SHOP_DATA_RETURN, function()
		self:Refresh()
	end)
	self:WndNetMsgRecv(LProtoIds.ChargeResp, function()
		gModelShop:ShopListReq(self._shopRef.refId)
	end)
end

function UIBrandGift:OnRedPoint(ref)
	gModelShop:GetShopItemCfg(ref.refId)
	gModelShop:GetShopItemNetData(shopId, goodsId)
end

-- 绘制列表item项
function UIBrandGift:OnDrawListItem(list, item, data, itemPos)
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
	end
	self:SetWndButtonText(itemCache.btnFree, ccClientText(44301))
	local ref = data.ref
	local shopId = self._shopRef.refId
	local goodsId = ref.refId
	self:SetWndText(itemCache.txtTitle, ccLngText(ref.name))

	local goods = data.goods    --gModelShop:GetShopItemCfg(ref.refId)
	local itemdata = data.itemdata --gModelShop:GetShopItemNetData(shopId, goodsId)

	if not itemdata then
		return
	end

	-- 限购
	local limitCfg = goods.limitCount
	local isLimit = limitCfg.itemNum ~= -1
	local strLimit = ""
	local showBuyOver = false
	if isLimit then
		local pre = ccClientText(gModelShop:GetLimitStr(limitCfg.itemId))
		local hasBuyNum = itemdata:GetHasBuyNum()
		strLimit = pre .. hasBuyNum .. "/" .. limitCfg.itemNum
		showBuyOver = hasBuyNum >= limitCfg.itemNum
	else
		strLimit = ccClientText(44302)
	end
	self:SetWndText(itemCache.txtLimit, strLimit)

	-- 价格
	local isFree = false
	local showCostIcon = false
	local priceStr = ""
	if goods.price then
		local price = goods.price
		isFree = price.itemNum == 0
		local priceNum = price.itemNum
		if not isFree then
			local priceIcon = gModelItem:GetItemImgByRefId(price.itemId)
			if priceIcon then
				self:SetWndEasyImage(itemCache.costIcon, priceIcon)
				showCostIcon = true
			end

			if price.itemId == 101001 then
				priceStr = LUtil.NumberCoversion(priceNum)
			else
				priceStr = LUtil.AddNumberSeparate(priceNum)
			end
		end
	else
		-- 计费点礼包
		local refId = tonumber(ref.price)
		priceStr = gModelPay:GetShowByWelfareId(refId)
	end
	self:SetWndText(itemCache.costNum, priceStr)
	CS.ShowObject(itemCache.costIcon.parent, showCostIcon)

	CS.ShowObject(itemCache.btnBuy, not isFree and not showBuyOver)
	CS.ShowObject(itemCache.btnFree, isFree and not showBuyOver)
	CS.ShowObject(itemCache.buyOver, showBuyOver)


	-- 奖励
	local itemList = LUtil.GetRefItemDataList(ref.reward)
	itemCache.uiList:RefreshList(itemList)

	self:SetWndClick(itemCache.btnFree, function()
		self:OnClickBtnBuy(shopId, goodsId, ref)
	end)


	self:SetWndClick(itemCache.btnBuy, function()
		self:OnClickBtnBuy(shopId, goodsId, ref)
	end)
end

-- 初始界面化文本
function UIBrandGift:InitTexts()
	self:SetWndText(self.mTxtTitle, ccLngText(self._shopRef.name))
end

-- 刷新界面
function UIBrandGift:Refresh()
	local list = {}
	local shopId = self._shopRef.refId
	for k, ref in ipairs(self._refList) do
		local goodsId = ref.refId
		local goods = gModelShop:GetShopItemCfg(ref.refId)
		local itemdata = gModelShop:GetShopItemNetData(shopId, goodsId)
		if itemdata then
			local sort = 0
			local limitCfg = goods.limitCount
			local isLimit = limitCfg.itemNum ~= -1
			if isLimit then
				local hasBuyNum = itemdata:GetHasBuyNum()
				if hasBuyNum >= limitCfg.itemNum then
					sort = 1
				end
			end


			table.insert(list, { index = k, sort = sort, ref = ref, goods = goods, itemdata = itemdata })
		end
	end

	table.sort(list, function(a, b)
		if a.sort ~= b.sort then
			return a.sort < b.sort
		end
		return a.index < b.index
	end)




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

-- 点击购买按钮
function UIBrandGift:OnClickBtnBuy(shopId, goodsId, ref)
	local refId = tonumber(ref.price)
	if refId then
		-- 充值购买
		gModelPay:GiftPayCtrl(ref.refId, refId, ModelPay.PAY_TYPE_GIFT, ModelPay.PAY_TIMEWARDROBE_SKIN, nil, nil, false,
				nil, {
					shopId = shopId,
				})
		return
	end


	gModelShop:BuyGoods(shopId, goodsId, false, self:GetWndName())
end

-- 初始精灵（被注释掉了，不显示立绘）
function UIBrandGift:InitSpine()
	self:CreateWndSpine(self.mSpine, "LH_Tuzi01", nil, false, function(dpSpine)

	end)
end
------------------------------------------------------------------
return UIBrandGift