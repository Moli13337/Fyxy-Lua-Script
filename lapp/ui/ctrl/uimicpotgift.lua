---
--- Created by Administrator.
--- DateTime: 2024/9/24 15:39:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMicPotGift:LWnd
local UIMicPotGift = LxWndClass("UIMicPotGift", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMicPotGift:UIMicPotGift()
	self.limitText = {
		ccClientText(11401),
		ccClientText(11403),
		ccClientText(11402)
	}
	self.rewardIconUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMicPotGift:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMicPotGift:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMicPotGift:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()

	gModelShop:ShopListReq(1010)
end

function UIMicPotGift:DrawRewardIcon(_, item, data)
	local root = self:FindWndTrans(item, "Root")
	local instanceId = root:GetInstanceID()
	local commonIcon = self:GetCommonIcon(instanceId)
	commonIcon:Create(root)
	commonIcon:SetCommonReward(data.itemType, data.itemId, data.itemNum)
	commonIcon:DoApply()

	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end

function UIMicPotGift:DrawList(_, item, data)
	local title = CS.FindTrans(item, "Title")
	local proText = CS.FindTrans(item, "ProText")
	local itemList = CS.FindTrans(item, "ItemList")
	local btn = CS.FindTrans(item, "Btn")
	local btnLight = CS.FindTrans(btn, "Light")
	local btnIcon = CS.FindTrans(btnLight, "Icon")
	local isGet = CS.FindTrans(item, "IsGet")

	self:SetWndText(title, data.name)
	local shopItemData = gModelShop:GetShopItemNetData(1010, data.refId)
	local buyNum = shopItemData:GetHasBuyNum()
	local limitText = self.limitText[data.limitCount.itemId]
	local str = "<color=#a1#>#a2#/#a3#</color>"
	local color = buyNum >= data.limitCount.itemNum and "#c81212" or "#139057"
	self:SetWndText(proText, limitText .. string.replace(str, color, buyNum, data.limitCount.itemNum))

	local InstanceID = item:GetInstanceID()
	local x = math.min(#data.reward * 77 + (#data.reward - 1) * 4, 355)
	itemList.sizeDelta = Vector2.New(x, 77)
	if self.rewardIconUIList[InstanceID] then
		self.rewardIconUIList[InstanceID]:RefreshList(data.reward)
		self.rewardIconUIList[InstanceID]:DrawAllItems()
	else
		self.rewardIconUIList[InstanceID] = self:GetUIScroll("rewardIconUIList" .. InstanceID)
		self.rewardIconUIList[InstanceID]:Create(itemList, data.reward, function(...) self:DrawRewardIcon(...) end, UIItemList.SUPER_GRID)
	end

	local priceStr = ccClientText(45810)
	if data.buyType == ModelPopupGift.BUYTYPE_JEWEL and data.item.itemNum > 0 then
		local priceIcon = gModelItem:GetItemImgByRefId(data.item.itemId)
		self:SetWndEasyImage(btnIcon, priceIcon)
		priceStr = LUtil.NumberCoversion(data.item.itemNum)
		self:DestroyWndEffectByKey(InstanceID)
	elseif data.buyType == ModelPopupGift.BUYTYPE_MONEY then
		priceStr = gModelPay:GetShowByWelfareId(data.item)
		self:DestroyWndEffectByKey(InstanceID)
	else
		self:CreateWndEffect(btn, "fx_anniu_03", InstanceID, 100)
	end
	self:SetWndButtonText(btn, priceStr)
	CS.ShowObject(btn, buyNum < data.limitCount.itemNum)
	CS.ShowObject(btnIcon, data.buyType == ModelPopupGift.BUYTYPE_JEWEL and data.item.itemNum > 0)
	CS.ShowObject(isGet, buyNum >= data.limitCount.itemNum)

	self:SetWndClick(btn, function()
		if data.buyType == ModelPopupGift.BUYTYPE_MONEY then
			gModelPay:GiftPayCtrl(data.refId, data.item, ModelPay.PAY_TYPE_GIFT, ModelPay.PAY_TIMEWARDROBE_SKIN, nil, nil, false, nil, { shopId = 1010 })
			return
		end
		gModelShop:BuyGoods(1010, data.refId, false, self:GetWndName())
	end)
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(btnLight)
end

function UIMicPotGift:UpdateList()
	local list = gModelShop:GetShopRefByShopType(21) or {}
	table.sort(list, function(a, b)
		local shopItemDataA = gModelShop:GetShopItemNetData(1010, a.refId)
		local buyNumA = shopItemDataA:GetHasBuyNum()
		local shopItemDataB = gModelShop:GetShopItemNetData(1010, b.refId)
		local buyNumB = shopItemDataB:GetHasBuyNum()
		local canBuyA = buyNumA < a.limitCount.itemNum
		local canBuyB = buyNumB < b.limitCount.itemNum
		if canBuyA ~= canBuyB then
			return canBuyA
		end

		if a.buyType == ModelPopupGift.BUYTYPE_FREE and b.buyType == ModelPopupGift.BUYTYPE_FREE then
			return a.refId < b.refId
		elseif a.buyType == ModelPopupGift.BUYTYPE_JEWEL and b.buyType == ModelPopupGift.BUYTYPE_JEWEL then
			return a.item.itemNum < b.item.itemNum
		elseif a.buyType == ModelPopupGift.BUYTYPE_MONEY and b.buyType == ModelPopupGift.BUYTYPE_MONEY then
			return a.item < b.item
		else
			return a.buyType > b.buyType
		end
	end)
	if self.list then
		self.list:RefreshList(list)
		self.list:DrawAllItems()
	else
		self.list = self:GetUIScroll("mList")
		self.list:Create(self.mList, list, function(...) self:DrawList(...) end, UIItemList.SUPER)
	end
end

function UIMicPotGift:InitCommon()
	-----------------------------------------------
	---Text
	self:SetWndText(self.mCloseTip, ccClientText(10103))

	-----------------------------------------------
	---Click
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)

	-----------------------------------------------
	---event
	self:WndEventRecv(EventNames.ON_SHOP_DATA_RETURN, function()
		self:UpdateList()
	end)
	self:WndEventRecv(EventNames.ON_SHOP_BUY_RETURN, function()
		gModelShop:ShopListReq(1010)
	end)

	-----------------------------------------------
	---resp
	self:WndNetMsgRecv(LProtoIds.ChargeResp, function()
		gModelShop:ShopListReq(1010)
	end)

	-----------------------------------------------
	---Spine
	self:CreateWndSpine(self.mSpine, "LH_Shuijingling01", "spine")
end



------------------------------------------------------------------
return UIMicPotGift