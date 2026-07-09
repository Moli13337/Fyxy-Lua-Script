---
--- Created by Administrator.
--- DateTime: 2024/5/7 17:29:19
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITmWardrobeGift:LWnd
local UITmWardrobeGift = LxWndClass("UITmWardrobeGift", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITmWardrobeGift:UITmWardrobeGift()
	self._curSelIdx = 1
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITmWardrobeGift:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITmWardrobeGift:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITmWardrobeGift:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitTrans()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UITmWardrobeGift:InitTrans()
	local buttonTrans = self.mPayBtn
	self._lightIconDivTrans = self:FindWndTrans(buttonTrans,"Light/Div/IconDiv")
	self._lightIcon = self:FindWndTrans(self._lightIconDivTrans,"Icon")

	self._grayIconDivTrans = self:FindWndTrans(buttonTrans,"Gray/Div/IconDiv")
	self._grayIcon = self:FindWndTrans(self._grayIconDivTrans,"Icon")
end





function UITmWardrobeGift:RefreshView()
	self:InitGiftScrollList()
	self:InitGiftItemList()
end

function UITmWardrobeGift:OnDrawGiftScrollCell(list,item,itemdata,itempos)
	local Root = self:FindWndTrans(item,"Root")
	local Icon = self:FindWndTrans(Root,"Icon")
	local SelImage = self:FindWndTrans(Root,"SelImage")
	local RateBg = self:FindWndTrans(Root,"RateBg")
	local RateText = self:FindWndTrans(RateBg,"RateText")

	local NameList = self:FindWndTrans(item,"NameList")
	local NameText = self:FindWndTrans(NameList,"NameText")

	local nameBg = itemdata.nameBg
	if string.isempty(nameBg) then
		nameBg = "icon_hero_1101"
	end
	self:SetWndEasyImage(Icon, nameBg, function()
		CS.ShowObject(Icon,true)
	end)

	local fixDiscount = itemdata.fixDiscount
	local showDiscount = not string.isempty(fixDiscount)
	if showDiscount then
		self:SetWndText(RateText, fixDiscount)
	end
	CS.ShowObject(RateBg,showDiscount)

	self:SetWndText(NameText,itemdata.name)

	local isSel = itempos == self._curSelIdx
	CS.ShowObject(SelImage,isSel)

	self:SetWndClick(item,function()
		self:OnClickGiftScrollFunc(itemdata,itempos)
	end)
end

function UITmWardrobeGift:InitGiftData()
	self._giftDatas = self._giftType2List[self._curSelIdx]
end

function UITmWardrobeGift:OnDrawGiftItemCell(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item,"CommonUI/Icon")
	local Name = self:FindWndTrans(item,"Name")

	local itemId = itemdata.itemId
	local instance = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instance)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(itemdata.itemType,itemId,itemdata.itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	self:SetIconClickScale(Icon, true)

	self:SetWndText(Name,gModelItem:GetNameByRefId(itemId))

	self:SetWndClick(Icon,function() self:OnClickGiftItemFunc(itemdata) end)
end


function UITmWardrobeGift:InitData()
	self._shopServerDatas = {}
	self._shopServerData = nil
	self._shopId = gModelShop:GetShopType6BaseRefId()
	self._giftType2List = gModelShop:GetShopRefByShopType(ModelShop.SKIN) or {}
	if self._shopId then
		gModelShop:ShopListReq(self._shopId)
	end
end

function UITmWardrobeGift:SetWndButtonIcon(iconPath,showState)
	local showLight = showState == 1
	local showGray = showState == 2
	if showLight then
		local lightIcon = self._lightIcon
		self:SetWndEasyImage(lightIcon,iconPath,function()
			CS.ShowObject(lightIcon,true)
		end,true)
	end
	if showGray then
		local grayIcon = self._grayIcon
		self:SetWndEasyImage(grayIcon,iconPath,function()
			CS.ShowObject(grayIcon,true)
		end,true)
	end
	CS.ShowObject(self._lightIconDivTrans,showLight)
	CS.ShowObject(self._grayIconDivTrans,showGray)
end

function UITmWardrobeGift:SetIconDivShow(buttonTrans,isShow)
	local lightIconDiv = self:FindWndTrans(buttonTrans,"Light/Div/IconDiv")
	local grayIconDiv = self:FindWndTrans(buttonTrans,"Gray/Div/IconDiv")
	CS.ShowObject(lightIconDiv,isShow)
	CS.ShowObject(grayIconDiv,isShow)
end


function UITmWardrobeGift:GetGiftItemList()
	local list = {}
	local ref = self._giftDatas
	if ref then
		list = ref.reward
	end
	return list
end

function UITmWardrobeGift:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mPayBtn,function()
		self:OnClickPayBtnFunc()
	end)
	-- self:SetWndClick(self.mXXXBtn,function() self:OnClickXXXBtnFunc() end)
end

function UITmWardrobeGift:RefreshPayBtn()
	local btnName = ""
	local iconPath
	local showState = 0
	local isGray = false
	local ref = self._giftDatas
	if ref then
		local buyType = ref.buyType
		if buyType == ModelPopupGift.BUYTYPE_MONEY then
			btnName = gModelPay:GetShowByWelfareId(ref.item)
		elseif buyType == ModelPopupGift.BUYTYPE_JEWEL or
				buyType == ModelPopupGift.BUYTYPE_CURRENCY then
			local item = ref.item
			local itemId = item.itemId
			local itemNum = item.itemNum
			iconPath = gModelItem:GetItemIconByRefId(itemId)
			btnName = itemNum
			local hasNum = gModelItem:GetNumByRefId(itemId)
			isGray = hasNum < itemNum
			showState = isGray and 2 or 1
		else
			btnName = ccClientText(14903)
		end
	end
	self:SetWndButtonIconText(self.mPayBtn,btnName)
	self:SetWndButtonIcon(iconPath,showState)
	self:SetWndButtonGray(self.mPayBtn,isGray)
end

function UITmWardrobeGift:OnClickGiftScrollFunc(itemdata,itempos)
	if itempos == self._curSelIdx then return end
	self._curSelIdx = itempos
	if self._uiGiftScroll then
		self._uiGiftScroll:DrawAllItems()
	end
	self:InitGiftItemList()
end


function UITmWardrobeGift:InitText()
end

function UITmWardrobeGift:OnShopListResp(pb)
	local shopId = pb.shopId
	if shopId ~= self._shopId then return end
	self._shopServerDatas = gModelShop:GetShopNetData(shopId)
	self:RefreshView()
end

function UITmWardrobeGift:GetGiftScrollList()
	return self._giftType2List
end

function UITmWardrobeGift:OnClickPayBtnFunc()
	if not self._giftDatas then return end
	local ref = self._giftDatas
	local limitCount = ref.limitCount
	local itemNum = limitCount.itemNum
	local refId = ref.refId
	local buyType = ref.buyType
	if itemNum == -1 then
		if buyType == ModelPopupGift.BUYTYPE_MONEY then
			gModelPay:GiftPayCtrl(ref.refId, ref.item, ModelPay.PAY_TYPE_GIFT, ModelPay.PAY_TIMEWARDROBE_SKIN, nil, nil, false,nil,{
				shopId = self._shopId
			})
		elseif buyType == ModelPopupGift.BUYTYPE_FREE or buyType == ModelPopupGift.BUYTYPE_JEWEL then
			gModelShop:BuyGoods(self._shopId, refId, false, self:GetWndName())
		end
	else
	end
end

function UITmWardrobeGift:OnClickGiftItemFunc(itemdata)
	gModelGeneral:ShowCommonItemTipWnd(itemdata)
end

function UITmWardrobeGift:InitGiftItemList()
	self:InitGiftData()
	self:RefreshPayBtn()
	local list = self:GetGiftItemList()
	local uiList = self:FindUIScroll("mGiftItemList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("mGiftItemList")
		uiList:Create(self.mGiftItemList, list, function(...) self:OnDrawGiftItemCell(...) end)
	end
end

function UITmWardrobeGift:InitGiftScrollList()
	local list = self:GetGiftScrollList()
	local len = #list
	local isMax = len >= 5
	local listTrans = isMax and self.mGiftScroll2 or self.mGiftScroll1
	local uiList = self._uiGiftScroll
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("GiftScroll")
		self._uiGiftScroll = uiList
		uiList:Create(listTrans,list,function(...) self:OnDrawGiftScrollCell(...) end)
	end
	CS.ShowObject(self.mMinListDiv,not isMax)
	CS.ShowObject(self.mMaxListDiv,isMax)
end

function UITmWardrobeGift:SetWndButtonIconText(buttonTrans, str, pos, addFontSize, addLine)
	if CS.IsNullObject(buttonTrans) then return end
	addFontSize = addFontSize or -2
	local lightText = CS.FindTrans(buttonTrans, "Light/Div/Text")
	local grayText = CS.FindTrans(buttonTrans, "Gray/Div/Text")
	self:SetWndText(lightText, str)
	self:SetWndText(grayText, str)
	self:InitTextSizeWithLanguage(lightText, addFontSize)
	self:InitTextSizeWithLanguage(grayText, addFontSize)
	if pos then
		lightText.transform.localPosition = pos
		grayText.transform.localPosition = pos
	end
	if addLine then
		self:InitTextLineWithLanguage(lightText, addLine)
		self:InitTextLineWithLanguage(grayText, addLine)
	end
end




function UITmWardrobeGift:InitMsg()
	self:WndEventRecv(EventNames.ON_SHOP_DATA_RETURN, function(...) self:OnShopListResp(...) end)
end


------------------------------------------------------------------
return UITmWardrobeGift