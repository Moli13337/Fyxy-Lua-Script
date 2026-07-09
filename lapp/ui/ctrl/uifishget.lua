---
--- Created by wzz.
--- DateTime: 2024/7/11 22:12:38
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishGet:LWnd
local UIFishGet = LxWndClass("UIFishGet", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishGet:UIFishGet()
	if gLGameAudio then
        gLGameAudio:PlaySound("SoundS_20")
    end
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishGet:OnWndClose()
	if self._SellData then
		local wnd = GF.FindFirstWndByName("UIFish")
		if wnd then
			local param = self._SellData
			param.position = param.trans.position
			wnd:FlyAsset(param)
		end
	end

	LWnd.OnWndClose(self)

	local callback = self:GetWndArg("callback")
	if callback then
		callback()
	end
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishGet:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishGet:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	CS.ShowObject(self.mTxtSellTipsSpace_En,self._isEnus)
	
	self._theBait = self:GetWndArg("theBait")
	self._fishObj = self._theBait.fish

	self:PlayEffect()
	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 刷新Item
function UIFishGet:RefreshItem()

end

-- true: 表示需要打开鱼釭
function UIFishGet:NeedOpenFishTank()
	return gModelFish:NeedOpenFishTank(self._fishObj)
end

-- 点击售卖
function UIFishGet:OnBtnSell()
	gModelFish:SellFishReq(0, self._fishObj.id)
	self:WndClose()
end

-- 初始事件
function UIFishGet:InitEvents()
	-- self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnSell, function() self:OnBtnSell() end)
	self:SetWndClick(self.mBtnSave, function() self:OnBtnSave() end)
	self:SetWndClick(self.mBtnOpen, function() self:OnBtnOpen() end)
end

-- 属性 item
function UIFishGet:OnDrawAttrItem(uiList, item, data)
	if not uiList then
		uiList        = {}
		uiList.icon   = CS.FindTrans(item, "icon")
		uiList.name   = CS.FindTrans(item, "name")
		uiList.value  = CS.FindTrans(item, "name/value")
		uiList.up     = CS.FindTrans(item, "name/value/flag/up")
		uiList.new    = CS.FindTrans(item, "name/value/flag/new")
		uiList.weight = CS.FindTrans(item, "name/value/flag/weight")
	end

	local isNew = not not data.isNew
	local isUp = not not data.isNew
	local isMax = not not data.isMax

	if data.weight then
		self:SetWndText(uiList.name, ccClientText(44247) .. ":")
		self:SetWndText(uiList.value, gModelFish:WeightToString(data.weight))
	else
		local attr = data.attr
		local icon = gModelHero:GetAttributeIconById(attr.refId)
		self:SetWndEasyImage(uiList.icon, icon)

		local name = gModelHero:GetAttributeNameById(attr.refId)
		self:SetWndText(uiList.name, name .. ":")

		local value = gModelFish:CheckAttrValue(attr.refId, attr.type,  attr.value)
		local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attr.refId, attr.type, value)
		self:SetWndText(uiList.value, valueStr)
	end


	CS.ShowObject(uiList.icon, not data.weight)
	CS.ShowObject(uiList.weight, isMax)
	CS.ShowObject(uiList.up, isUp)
	CS.ShowObject(uiList.isNew, isNew)

	return uiList
end

-- 播特效
function UIFishGet:PlayEffect()
	self:CreateWndEffect(self.mEff, "fx_ui_shengxing_1", 1, 100)
end

-- 点击打开
function UIFishGet:OnBtnOpen()
	local itemData = LUtil.GetRefItemData(self._theBait.things)

	local info = {}
	table.insert(info, { refId = itemData.refId, num = 1 })
	gModelItem:OnItemUseReq(info)
	self:WndClose()
end

-- 刷新界面
function UIFishGet:Refresh()
	local fishRef
	local strName = ""
	local imgPath, typeIcon = "", ""
	local strScore, strDesc = "", ""
	if self._theBait.type == CommonIcon.ICON_TYPE_FISH then
		fishRef = gModelFish:GetFishRef(self._fishObj.refId)
		local typeRef = gModelFish:GetFishTypeRef(fishRef.type)
		imgPath = fishRef.icon
		typeIcon = typeRef.icon

		local color = gModelItem:GetColorStringByQualityId(fishRef.quality)
		strName = LUtil.FormatColorStr(ccLngText(fishRef.name), "#" .. color)
		if self._fishObj.score > 0 then
			strScore = ccClientText(44246, self._fishObj.score)
		end
		strDesc = ccLngText(fishRef.desc)
	else
		local itemData = LUtil.GetRefItemData(self._theBait.things)
		imgPath = gModelItem:GetItemImgByRefId(itemData.refId)
		strName = gModelItem:GetItemNameRichText(itemData.refId)
		strDesc = gModelItem:GetDescByRefId(itemData.refId)
	end

	self:SetWndText(self.mTxtName, strName)
	self:SetWndEasyImage(self.mItemIcon, imgPath, nil, true)

	self:SetWndEasyImage(self.mType, typeIcon)
	CS.ShowObject(self.mType, typeIcon ~= "")

	self:SetWndText(self.mTxtScore, strScore)
	self:SetWndText(self.mTxtDesc, strDesc)
	CS.ShowObject(self.mFirstGet, self._theBait.firstGet)

	local showSell = false
	local showBoxTips = false
	local showSave = false
	local showAttr = false
	if fishRef then
		showSell = true
		if gModelFish:InFishTankTypeList(fishRef.refId) then
			showSell = self:NeedOpenFishTank()
			showSave = true
			showAttr = true
		end
	else
		showBoxTips = true
	end

	CS.ShowObject(self.mBtnSell, showSell)
	CS.ShowObject(self.mBoxTips, showBoxTips)
	CS.ShowObject(self.mBtnOpen, showBoxTips)
	CS.ShowObject(self.mBtnSave, showSave)
	CS.ShowObject(self.mAttrList, showAttr)

	if not fishRef then
		return
	end


	if showAttr then
		-- 属性
		local dataList = {}
		local attrList = self._fishObj.attrs

		local oldAttrMap = {}
		local oldObj = gModelFish:GetFishTankObj(fishRef.refId)
		if oldObj then
			for k, v in ipairs(oldObj.attrs) do
				oldAttrMap[v.refId] = v.value
			end
		end

		local weight = self._fishObj.weight
		local weightMax = gModelFish:GetFishWeightMax(fishRef.refId)
		local isMax = weight > weightMax
		dataList[1] = { weight = weight, isMax = isMax }
		for i, attr in ipairs(attrList) do
			local tab = { attr = attr }
			if oldObj then
				if oldAttrMap[attr.refId] then
					tab.isUp = oldAttrMap[attr.refId] < attr.value
				else
					tab.isNew = true
				end
			end
			table.insert(dataList, tab)
		end
		self:SetComList(self.mAttrList, dataList, function(...) return self:OnDrawAttrItem(...) end)
	end

	if showSell or showSave then
		local itemData = LUtil.GetRefItemData(fishRef.sell)
		local path = gModelItem:GetItemIconByRefId(itemData.refId)
		self:SetWndEasyImage(self.mSellIcon, path)
		-- self:CreateCommonIconImpl(self.mSellIcon, itemData, { showNum = false, showBg = false })
		self:SetWndText(self.mTxtSell, itemData.itemNum)
		self._SellData = {
			trans = self.mSellIcon,
			refId = itemData.refId,
			num = itemData.itemNum,
		}
	end
end

-- 初始界面化文本
function UIFishGet:InitTexts()
	self:SetWndText(self.mTxtSellTips, ccClientText(44242))


	self:SetTextTile(self.mBoxTips, ccClientText(44248))

	self:SetWndButtonText(self.mBtnSell, ccClientText(44244))
	self:SetWndButtonText(self.mBtnSave, ccClientText(44243))
	self:SetWndButtonText(self.mBtnOpen, ccClientText(44245))
	self:SetTextTile(self.mFirstGet, ccClientText(44328))
	-- self:SetWndText(self.mTxtSaveTips, ccClientText(44329))
end

-- 点击保存
function UIFishGet:OnBtnSave()
	if self:NeedOpenFishTank() then
		GF.OpenWnd("UIFishReplace", {sellType = 0, replaceFishObj = self._fishObj })
		return
	end
	self._SellData = nil
	gModelFish:SettleFishingReq(0, self._fishObj.id)

	self:WndClose()
end

------------------------------------------------------------------
return UIFishGet