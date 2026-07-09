---
--- Created by wzz.
--- DateTime: 2024/9/19 21:11:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishReplace:LWnd
local UIFishReplace = LxWndClass("UIFishReplace", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishReplace:UIFishReplace()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishReplace:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishReplace:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishReplace:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._replaceFishObj = self:GetWndArg("replaceFishObj")
	self._sellType = self:GetWndArg("sellType")

	self._itemSpacing = 8 --item间距
	self._itemH = self.mItemTemplate.rect.height
	self._layoutH = self.mLayout.rect.height

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 绘制AttrItem项
function UIFishReplace:OnDrawAttrItem(uiList, item, itemData, itemPos)
	if not uiList then
		uiList       = {}
		uiList.icon  = CS.FindTrans(item, "icon")
		uiList.name  = CS.FindTrans(item, "name")
		uiList.value = CS.FindTrans(item, "name/value")
		uiList.up    = CS.FindTrans(item, "name/value/up")
		uiList.down  = CS.FindTrans(item, "name/value/down")
		uiList.new   = CS.FindTrans(item, "name/value/new")
	end

	local data = itemData.attr
	CS.ShowObject(uiList.up, itemData.up)
	CS.ShowObject(uiList.down, itemData.down)
	CS.ShowObject(uiList.new, itemData.new)

	local icon = gModelHero:GetAttributeIconById(data.refId)
	self:SetWndEasyImage(uiList.icon, icon)

	local name = gModelHero:GetAttributeNameById(data.refId)
	self:SetWndText(uiList.name, name .. "：")

	local value = gModelFish:CheckAttrValue(data.refId, data.type, data.value)
	local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(data.refId, data.type, value)
	self:SetWndText(uiList.value, valueStr)
	return uiList
end

-- 刷新界面
function UIFishReplace:Refresh()
	local fishRef      = gModelFish:GetFishRef(self._replaceFishObj.refId)
	local fishType     = fishRef.type
	local fishTypeRef  = gModelFish:GetFishTypeRef(fishType)
	local fishObjList  = gModelFish:GetFishTankObjListByType(fishType)
	local otherFishObj = nil

	local index = nil
	for k, v in ipairs(fishObjList) do
		if v.refId == self._replaceFishObj.refId then
			otherFishObj = v
			index = k
			break
		end
	end
	self._hadCompared = otherFishObj ~= nil
	self:SetItem(self.mTopItem, self._replaceFishObj, true)

	local num         = #fishObjList
	local curTankLev  = gModelFish:GetFishTankLev()
	local maxNum      = gModelFish:GetFishNumMaxByType(fishType, curTankLev)
	self:SetWndText(self.mTxtType2, ccClientText(44362, ccLngText(fishTypeRef.name), num, maxNum))


	local listH = 0
	if num > 4 then
		num = 3.5
		listH = self._layoutH + (num - 1) * self._itemH + (num - 1) * self._itemSpacing
	else
		listH = self._layoutH + (num - 1) * self._itemH + (num - 1) * self._itemSpacing
	end
	LxUiHelper.SetSizeWithCurAnchor(self.mLayout, 1, listH)

	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList
		uiList:Create(self.mList, fishObjList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER_GRID)

		if index and num > 3 then
			uiList:MoveToPos(index)
		end
		uiList:EnableScroll(num > 3)
	else
		self._uiList:ResetList(fishObjList)
		self._uiList:DrawAllItems()
	end
end

-- 绘制列表item项
function UIFishReplace:OnDrawListItem(list, item, itemData, itemPos)
	self:SetItem(item, itemData, false)
end

-- 初始事件
function UIFishReplace:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

-- 点击售卖
function UIFishReplace:OnBtnSell()
	gModelFish:SellFishReq(self._sellType, self._replaceFishObj.id)
	self:WndClose()
end

-- 初始界面化文本
function UIFishReplace:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(44361))
	self:SetWndText(self.mTxtCloseTips, ccClientText(41037))
	self:SetWndText(self.mTxtType1, ccClientText(44360))
end

-- 处理属性数据
function UIFishReplace:DealWithAttrData(fishObj, otherFishObj)
	if not otherFishObj then
		local list = {}
		for k, v in ipairs(fishObj.attrs) do
			list[k] = { attr = v, up = false, down = false, new = false }
		end
		return list
	end

	local attrList = fishObj.attrs
	local otherAttrList = otherFishObj.attrs

	local list = {}
	for k, v in ipairs(attrList) do
		list[k] = { attr = v, up = false, down = false, new = false }

		for kk, vv in ipairs(otherAttrList) do
			if v.refId == vv.refId and v.type == vv.type then
				list[k].up = v.value > vv.value
				list[k].down =  v.value < vv.value
				break
			end
		end
	end
	return list
end

-- 绘制fish Item项
function UIFishReplace:SetItem(item, fishObj, isTop)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			txtName  = CS.FindTrans(item, "txtName"),
			itemRoot = CS.FindTrans(item, "itemRoot"),
			attrList = CS.FindTrans(item, "attrList"),
			btn      = CS.FindTrans(item, "btn"),
		}

		if isTop then
			itemCache.txtSellTips = CS.FindTrans(itemCache.btn, "CostSell/txtSellTips")
			itemCache.sellIcon    = CS.FindTrans(itemCache.btn, "CostSell/SellIcon/sellIcon")
			itemCache.txtSell     = CS.FindTrans(itemCache.btn, "CostSell/txtSell")

			self:SetWndButtonText(itemCache.btn, ccClientText(44244))
		else
			self:SetWndButtonText(itemCache.btn, ccClientText(44286))
		end

		self:SetComponentCache(instanceID, itemCache)
	end

	local ref = gModelFish:GetFishRef(fishObj.refId)
	local name = ccLngText(ref.name)
	self:SetWndText(itemCache.txtName, name)

	local itemData = { itemId = ref.refId, itemType = CommonIcon.ICON_TYPE_FISH }
	self:CreateCommonIconImpl(itemCache.itemRoot, itemData,
		{ showNum = false, clickFunc = function() GF.OpenWnd("UIFishTips", { refId = ref.refId, isTips = true }) end })

	local showBtn = true
	-- 出售
	if isTop then
		local itemData = LUtil.GetRefItemData(ref.sell)
		local path = gModelItem:GetItemIconByRefId(itemData.refId)
		self:SetWndEasyImage(itemCache.sellIcon, path)
		self:SetWndText(itemCache.txtSell, itemData.itemNum)
		self:SetWndText(itemCache.txtSellTips, ccClientText(44242))

		self:SetWndClick(itemCache.btn, function()
			self:OnBtnSell()
		end)
	else
		showBtn = (self._hadCompared and self._replaceFishObj.refId == fishObj.refId) or not self._hadCompared

		self:SetWndClick(itemCache.btn, function()
			self:OnReplaceBtnClick(fishObj)
		end)
	end
	CS.ShowObject(itemCache.btn, showBtn)


	local attrList
	if isTop then
		attrList = self:DealWithAttrData(fishObj, nil)
	else
		local otherFishObj = showBtn and self._replaceFishObj or nil
		attrList = self:DealWithAttrData(fishObj, otherFishObj)
	end

	self:SetComList(itemCache.attrList, attrList, function(...) return self:OnDrawAttrItem(...) end)


end

-- 点击替换
function UIFishReplace:OnReplaceBtnClick(fishObj)
	local id = fishObj.id
	local fishRef = gModelFish:GetFishRef(fishObj.refId)
	local itemData = LUtil.GetRefItemData(fishRef.sell)
	local name = ccLngText(fishRef.name)
	local itemList = {itemData}
	gModelGeneral:OpenUIOrdinTips({
		refId = 450000,
		para = {name, name},
		itemList = itemList,
		func = function()
			if self:GetWndArg("isFast") then
				gModelFish:SettleFishingReq(4, id, self._replaceFishObj.id)
			else
				gModelFish:SettleFishingReq(1, id)
			end
		end,
	})
end

------------------------------------------------------------------
return UIFishReplace