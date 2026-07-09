---
--- Created by BY.
--- DateTime: 2023/10/25 14:40:43
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubCHNDian:LChildWnd
local UISubCHNDian = LxWndClass("UISubCHNDian", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubCHNDian:UISubCHNDian()
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubCHNDian:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubCHNDian:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubCHNDian:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubCHNDian:ListItem(list,item, itemdata, itempos)
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local image = CS.FindTrans(item,"Image")
	local buyNum = CS.FindTrans(image,"BuyNum")
	local itemRoot = CS.FindTrans(image,"ItemIcon")
	local discountText = CS.FindTrans(image,"DiscountImg/DiscountText")
	local nameText = CS.FindTrans(image,"NameText")
	local originalText = CS.FindTrans(image,"OriginalText")
	local originalIcon = CS.FindTrans(image,"OriginalText/OriginalIcon")
	local nowText = CS.FindTrans(image,"NowText")
	local nowIcon = CS.FindTrans(image,"NowText/NowIcon")
	local buyMask = CS.FindTrans(image,"BuyMask")

	local discountStr = ""
	local _shopDiscount = self._shopDiscount
	if _shopDiscount == 0 then
		discountStr = string.replace(ccClientText(19211),"?")
	else
		if self._noChinese then
			discountStr = 100-_shopDiscount
			discountStr = discountStr.."%"
		else
			discountStr = _shopDiscount/10
		end

		discountStr = string.replace(ccClientText(19211),discountStr)
	end
	self:SetWndText(discountText,discountStr)
	self:InitTextSizeWithLanguage(discountText, -2)
	local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
	local _itemdata = itemList[1]
	local itemName = gModelGeneral:GetItemName(_itemdata.itemType,_itemdata.itemId,nil,nil,_itemdata)
	self:SetWndText(nameText,itemName)

	local marketData = itemdata.MarketData
	local originalStr = marketData.expend2
	local money = ""
	local moneyStr = ""
	local isItemBuy = string.find(originalStr,"=")
	if isItemBuy then
		CS.ShowObject(originalIcon,true)
		CS.ShowObject(nowIcon,true)
		local originalArr = string.split(originalStr,"=")
		local icon = gModelItem:GetItemIconByRefId(tonumber(originalArr[2]))
		self:SetWndEasyImage(originalIcon,icon)
		self:SetWndEasyImage(nowIcon,icon)
		money = originalArr[3]
		moneyStr = LUtil.NumberCoversion(money)
	else
		CS.ShowObject(originalIcon,false)
		CS.ShowObject(nowIcon,false)
		--money = gModelPay:GetRMBValueByWelfareId(tonumber(originalStr))
		moneyStr = gModelPay:GetShowByWelfareId(tonumber(originalStr)) --string.replace(ccClientText(19206),LUtil.NumberCoversion(money))
	end
	self:SetWndText(originalText,moneyStr)

	local marketBuyNum = marketData.personalGoal - marketData.personal
	self:SetWndText(buyNum,string.replace(ccClientText(22216),marketBuyNum))
	local isPersonal = marketBuyNum > 0
	CS.ShowObject(buyMask,not isPersonal)
	local _shopDiscount = self._shopDiscount
	if _shopDiscount > 0 then
		moneyStr = LUtil.NumberCoversion(math.ceil(money / 100 * _shopDiscount))
	else
		moneyStr = "???"
	end
	if not isItemBuy then
		moneyStr = string.replace(ccClientText(19206),moneyStr)
	end
	self:SetWndText(nowText,moneyStr)
	self:SetWndClick(image,function ()
		if not isPersonal then
			GF.ShowMessage(ccClientText(15517))
		else
			self:OnClickBuyGift(itemdata,isItemBuy,moneyStr)
		end
	end)

	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(itemRoot)
	end
	baseClass:SetCommonReward(_itemdata.itemType, _itemdata.itemId, _itemdata.itemNum)
	self:SetWndClick(itemRoot,function()
		gModelGeneral:ShowCommonItemTipWnd(_itemdata)
	end)
	baseClass:DoApply()
end

function UISubCHNDian:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		self:RefreshData()
	end)
end

function UISubCHNDian:ResetData(pb)
	local sid = pb.sid
	if(self._sid ~= sid)then
		return
	end
	for i, v in ipairs(pb.pages) do
		if self._pageId == v.pageId then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			self._entry = page.entry
			break
		end
	end
	self:RefreshData()
end

function UISubCHNDian:OnClickDiscount()
	GF.OpenWnd("UILuckDianDisc",{sid = self._sid,pageId = self._pageId})
end

function UISubCHNDian:RefreshData()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local data = JSON.decode(activityData.moreInfo)
	local shopDiscount = data.shopDiscount_lsp or 0		--折扣

	local discountTextStr = ""
	self._shopDiscount = shopDiscount
	local discountStr
	if shopDiscount == 0 then
		discountStr = "???"
		discountTextStr = ccClientText(19210)
	else
		if self._noChinese then
			discountStr = 100-shopDiscount
			discountStr = discountStr.."%"
		else
			shopDiscount = shopDiscount/10
			discountStr = shopDiscount
		end

		discountTextStr = ccClientText(19245)
	end
	CS.ShowObject(self.mRedPoint,self._shopDiscount == 0)
	discountStr = string.replace(ccClientText(19209),discountStr)
	self:SetWndText(self.mDiscountText,discountStr)
	self:SetWndButtonText(self.mDiscountBtn,discountTextStr)
	local list = self._entry or {}
	if self._uiCellList then
		self._uiCellList:RefreshList(list)
	else
		self._uiCellList = self:GetUIScroll("shopList")
		self._uiCellList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
		self._uiCellList:EnableScroll(true,false)
	end
end

function UISubCHNDian:InitCommand()
	self._sid = self:GetWndArg("sid")
	local entry = self:GetWndArg("entry")
	self._pageId = entry[1].pageId
	self._entry = entry

	self._noChinese = gLGameLanguage:IsForeignVersion()

	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config
	local shopHero,shopHeroPos,shopHeroTxt,shopHeroTxtImage,shopHeroTxtImagePos,shopWindows,shopHeroTxtPos
	= data.shopHero,data.shopHeroPos,data.shopHeroTxt,data.shopHeroTxtImage,data.shopHeroTxtImagePos,data.shopWindows,data.shopHeroTxtPos
	if shopHero and shopHero > 0 then
		local ref = gModelHero:GetShowEffectById(shopHero)
		self:CreateWndSpine(self.mHeroPaint,ref.heroDrawing,"shopHero",false,function(dpSpine)
			--dpSpine:SetScale(0.8)
		end)
		local shopHeroPosArr = string.split(shopHeroPos,"|")
		self.mHeroPaint.anchoredPosition = Vector3(tonumber(shopHeroPosArr[1]),tonumber(shopHeroPosArr[2]),0)
	end
	if not string.isempty(shopHeroTxt) then
		local str = string.gsub(shopHeroTxt,"\\n","\n")
		self:SetWndText(self.mDesText,str)
		CS.ShowObject(self.mDesBg,true)
		local arr = string.split(shopHeroTxtPos,"|")
		local isScale = arr[1] and arr[1] == "1"
		if isScale then
			self.mBg.localScale = Vector2(-1,1)
		end
		if arr[2] then
			local pos = string.split(arr[2],",")
			self.mDesBg.anchoredPosition = Vector2(tonumber(pos[1]),tonumber(pos[2]))
		end
	end
	if LxUiHelper.IsImgPathValid(shopHeroTxtImage) then
		CS.ShowObject(self.mTextImg,true)
		self:SetWndEasyImage(self.mTextImg,shopHeroTxtImage,nil,true)
		local shopHeroTxtImagePosArr = string.split(shopHeroTxtImagePos,"|")
		self.mTextImg.anchoredPosition = Vector3(tonumber(shopHeroTxtImagePosArr[1]),tonumber(shopHeroTxtImagePosArr[2]),0)
	end
	self._shopWindows = shopWindows
	self:RefreshData()
end

function UISubCHNDian:InitEvent()
	self:SetWndClick(self.mDiscountBtn,function ()
		self:OnClickDiscount()
	end)
end

function UISubCHNDian:OnClickBuyGift(itemdata,isItemBuy,moneyStr)
	local _shopWindows = self._shopWindows
	if not _shopWindows then
		return
	end
	local item = itemdata.items and itemdata.items[1]
	if not item then
		return
	end
	local _shopDiscount = self._shopDiscount
	if _shopDiscount and _shopDiscount > 0 then
		local itemId = item.itemId
		local itemName = gModelItem:GetItemNameRichText(itemId)
		local buyItemName = ""
		local consumeItemId
		local consumeItemNum
		if not isItemBuy then
			buyItemName = string.replace(ccClientText(19206),moneyStr)
		else
			local marketData = itemdata.MarketData
			local expend2 = marketData.expend2
			local arr = string.split(expend2,"=")
			consumeItemId = tonumber(arr[2])
			consumeItemNum = tonumber(moneyStr)
			local item = gModelItem:GetNameByRefId(consumeItemId)
			buyItemName = moneyStr..item
		end
		gModelGeneral:OpenUIOrdinTips({refId = _shopWindows,itemList = itemdata.items,
										 para = {buyItemName,itemName}, consume = {consumeItemNum, consumeItemId,},
		func = function()
			if isItemBuy then
				gModelActivity:OnActivityMarkeyBuyReq(self._sid, itemdata.pageId, itemdata.entryId)
			else
				local welfareId = tonumber(itemdata.MarketData.expend2)
				gModelPay:GiftPayCtrl(itemdata.entryId,welfareId,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,itemdata.pageId)
			end
		end })
	else
		GF.ShowMessage(ccClientText(19227))
	end
end
------------------------------------------------------------------
return UISubCHNDian


