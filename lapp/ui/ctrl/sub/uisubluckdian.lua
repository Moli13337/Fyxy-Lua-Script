---
--- Created by BY.
--- DateTime: 2023/10/19 14:58:17
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubLuckDian:LChildWnd
local UISubLuckDian = LxWndClass("UISubLuckDian", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubLuckDian:UISubLuckDian()
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubLuckDian:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubLuckDian:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubLuckDian:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubLuckDian:InitCommand()
	self._sid = self:GetWndArg("sid")
	local entry = self:GetWndArg("entry")
	self._pageId = entry[1].pageId
	self._entry = entry
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config
	local shopHero,shopHeroPos,shopHeroTxt,shopHeroTxtImage,shopHeroTxtImagePos
	= data.shopHero,data.shopHeroPos,data.shopHeroTxt,data.shopHeroTxtImage,data.shopHeroTxtImagePos
	local newImage,newImageFrame2,newDiscount
	= data.newImage4,data.newImageFrame2,data.newDiscount
	self._bargainAnim = data.bargainAnim
	if LxUiHelper.IsImgPathValid(newImage) then
		local paint = self.mTopBg
		self:SetWndEasyImage(paint,newImage,function ()
			CS.ShowObject(paint,true)
		end ,true)
	end
	if not string.isempty(newImageFrame2) then
		local arr = string.split(newImageFrame2,"=")
		if LxUiHelper.IsImgPathValid(arr[1]) then
			self:SetWndEasyImage(self.mTopImg,arr[1])
		end
		if LxUiHelper.IsImgPathValid(arr[2]) then
			self:SetWndEasyImage(self.mBottonImg,arr[2])
		end
		if LxUiHelper.IsImgPathValid(arr[3]) then
			self:SetWndEasyImage(self.mCentreImg,arr[3])
		end
	end
	if not string.isempty(newDiscount) then
		local paint
		local arr = string.split(newDiscount,"=")
		if LxUiHelper.IsImgPathValid(arr[1]) then
			paint = self.mDiscountImg
			self:SetWndEasyImage(paint,arr[1],function ()
				CS.ShowObject(paint,true)
			end ,true)
		end
		if paint and not string.isempty(arr[2]) then
			CS.ShowObject(paint,true)
			local pos = LxDataHelper.ParseVector2NotEmpty(arr[2])
			self:SetAnchorPos(paint, pos)
		end
	end
	if not string.isempty(shopHero) then
		local paint
		local arr = string.split(shopHero,"=")
		if arr[1] == "1" then
			paint = self.mHeroImg
			self:SetWndEasyImage(paint,arr[2],nil,true)
		elseif arr[1] == "2" then
			paint = self.mHeroPaint
			self:CreateWndSpine(paint,arr[2],"shopHero")
		elseif tonumber(shopHero) > 0 then
			local ref = gModelHero:GetShowEffectById(tonumber(shopHero))
			if ref then
				paint = self.mHeroPaint
				self:CreateWndSpine(paint,ref.heroDrawing,"shopHero",false,function(dpSpine)
					dpSpine:SetScale(0.8)
				end)
			end
		end
		if paint and not string.isempty(shopHeroPos) then
			CS.ShowObject(paint,true)
			local pos = LxDataHelper.ParseVector2NotEmpty2(shopHeroPos)
			self:SetAnchorPos(paint, pos)
		end
	end
	if shopHeroTxt and shopHeroTxt ~= "" then
		local str = string.gsub(shopHeroTxt,"\\n","\n")
		self:SetWndText(self.mDesText,str)
	end
	if LxUiHelper.IsImgPathValid(shopHeroTxtImage) then
		local paint = self.mTextImg
		self:SetWndEasyImage(paint,shopHeroTxtImage,function ()
			CS.ShowObject(paint,true)
		end ,true)
		if paint and not string.isempty(shopHeroTxtImagePos) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(shopHeroTxtImagePos)
			self:SetAnchorPos(paint, pos)
		end
	end

	self:RefreshData()
end

function UISubLuckDian:OnClickBuyGift(itemdata,isItemBuy)
	local _shopDiscount = self._shopDiscount
	if _shopDiscount and _shopDiscount > 0 then
		if isItemBuy then
			gModelActivity:OnActivityMarkeyBuyReq(self._sid, itemdata.pageId, itemdata.entryId)
		else
			local welfareId = tonumber(itemdata.MarketData.expend2)
			gModelPay:GiftPayCtrl(itemdata.entryId,welfareId,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,itemdata.pageId)
		end
	else
		GF.ShowMessage(ccClientText(19227))
	end
end

function UISubLuckDian:RefreshData()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local data = JSON.decode(activityData.moreInfo)
	local shopDiscount = data.shopDiscount_lsp			--折扣

	local discountTextStr = ""
	self._shopDiscount = shopDiscount
	if shopDiscount == 0 then
		shopDiscount = "???"
		discountTextStr = ccClientText(19210)
	else
		shopDiscount = shopDiscount/10
		discountTextStr = ccClientText(19245)
	end
	local discountStr = string.replace(ccClientText(19209),shopDiscount)
	self:SetWndText(self.mDiscountText,discountStr)
	self:SetWndText(self.mBtnDiscountText,discountTextStr)
	local list = self._entry or {}
	if self._uiCellList then
		self._uiCellList:RefreshList(list)
	else
		self._uiCellList = self:GetUIScroll("shopList")
		self._uiCellList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
		self._uiCellList:EnableScroll(true,false)
	end
end

function UISubLuckDian:InitEvent()
	self:SetWndClick(self.mBtnDiscount,function ()
		self:OnClickDiscount()
	end)
end

function UISubLuckDian:ResetData(pb)
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

function UISubLuckDian:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		self:RefreshData()
	end)
end

function UISubLuckDian:ListItem(list,item, itemdata, itempos)
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local itemRoot = CS.FindTrans(item,"ItemIcon")
	local discountText = CS.FindTrans(item,"DiscountImg/DiscountText")
	local nameText = CS.FindTrans(item,"NameText")
	local originalText = CS.FindTrans(item,"OriginalText")
	local originalIcon = CS.FindTrans(item,"OriginalText/OriginalIcon")
	local buyMask = CS.FindTrans(item,"BuyMask")
	local payBtn = CS.FindTrans(item,"PayBtn")
	local buyBtn = CS.FindTrans(item,"BuyBtn")
	local buyText = CS.FindTrans(item,"BuyBtn/BuyText")
	local buyIcon = CS.FindTrans(item,"BuyBtn/BuyText/BuyIcon")

	local discountStr = ""
	local _shopDiscount = self._shopDiscount
	if _shopDiscount == 0 then
		discountStr = string.replace(ccClientText(19211),"?")
	else
		discountStr = string.replace(ccClientText(19211),_shopDiscount/10)
	end
	self:SetWndText(discountText,discountStr)
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
		local originalArr = string.split(originalStr,"=")
		local icon = gModelItem:GetItemIconByRefId(tonumber(originalArr[2]))
		self:SetWndEasyImage(originalIcon,icon)
		self:SetWndEasyImage(buyIcon,icon)
		money = originalArr[3]
		moneyStr = LUtil.NumberCoversion(money)
	else
		CS.ShowObject(originalIcon,false)
		money = gModelPay:GetRMBValueByWelfareId(tonumber(originalStr))
		moneyStr = gModelPay:GetShowByWelfareId(tonumber(originalStr)) --string.replace(ccClientText(19206),LUtil.NumberCoversion(money))
	end
	self:SetWndText(originalText,moneyStr)

	local marketBuyNum = marketData.personalGoal - marketData.personal
	local isPersonal = marketBuyNum > 0
	CS.ShowObject(buyMask,not isPersonal)
	CS.ShowObject(payBtn,isPersonal and not isItemBuy)
	CS.ShowObject(buyBtn,isPersonal and isItemBuy)
	local _shopDiscount = self._shopDiscount
	if _shopDiscount > 0 then
		moneyStr = LUtil.NumberCoversion(math.ceil(money / 100 * _shopDiscount))
	else
		moneyStr = "???"
	end
	if not isItemBuy then
		moneyStr = string.replace(ccClientText(19206),moneyStr)
	end
	self:SetWndButtonText(payBtn,moneyStr)
	self:SetWndText(buyText,moneyStr)
	if isPersonal then
		self:SetWndClick(buyBtn,function ()
			self:OnClickBuyGift(itemdata,isItemBuy)
		end)
	end

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

function UISubLuckDian:OnClickDiscount()
	GF.OpenWnd("UILuckDianDisc",{sid = self._sid,pageId = self._pageId,bargainAnim = self._bargainAnim})
end
------------------------------------------------------------------
return UISubLuckDian


