---
--- Created by BY.
--- DateTime: 2023/10/19 16:22:03
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubLuckGift:LChildWnd
local UISubLuckGift = LxWndClass("UISubLuckGift", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubLuckGift:UISubLuckGift()
	self._uiScrollList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubLuckGift:OnWndClose()
	self:ClearCommonIconList(self._uiScrollList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubLuckGift:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubLuckGift:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubLuckGift:ListItem(list,item, itemdata, itempos)
	local entryCfg1 = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local discountImg = CS.FindTrans(item,"DiscountImg")
	local discountText = CS.FindTrans(item,"DiscountImg/DiscountText")
	local icon = CS.FindTrans(item,"Image/Icon")
	local nameText = CS.FindTrans(item,"Image/NameText")
	local awardScroll = CS.FindTrans(item,"Image/AwardScroll")
	local buyNum = CS.FindTrans(item,"Image/BuyNum")
	local buyMask = CS.FindTrans(item,"Image/BuyMask")
	local buyBtn = CS.FindTrans(item,"Image/BuyBtn")
	local redPoint = CS.FindTrans(item,"Image/BuyBtn/redPoint")
	local buyCountBtn = CS.FindTrans(item,"Image/BuyCountBtn")
	local buyCountText = CS.FindTrans(item,"Image/BuyCountBtn/BuyCountText")
	local buyCountIcon = CS.FindTrans(item,"Image/BuyCountBtn/BuyCountText/BuyCountIcon")

	local marketData = itemdata.MarketData
	local dataArr = string.split(entryCfg1.moreInfo,"|")
	CS.ShowObject(discountImg,dataArr[1] ~= "-1")
	CS.ShowObject(redPoint,dataArr[1] == "-1")
	if dataArr[1] ~= "-1" then
		self:SetWndText(discountText,dataArr[1].."%")
	end
	self:SetWndEasyImage(icon,dataArr[2],nil,true)
	local marketBuyNum = marketData.personalGoal - marketData.personal
	self:SetWndText(buyNum,string.replace(ccClientText(19215),marketBuyNum))
	local isPersonal = marketBuyNum > 0

	--local expendType = marketData.expendType
	local money = ""
	local expend2 = marketData.expend2
	local isItemBuy = string.find(expend2,"=")
	CS.ShowObject(buyMask,not isPersonal)
	CS.ShowObject(buyBtn,isPersonal and not isItemBuy)
	CS.ShowObject(buyCountBtn,isPersonal and isItemBuy)
	self:SetWndText(nameText,entryCfg1.name)
	if expend2 == "-1" then
		money = ccClientText(19246)
	elseif isItemBuy then
		CS.ShowObject(originalIcon,true)
		local originalArr = string.split(expend2,"=")
		local icon = gModelItem:GetItemIconByRefId(tonumber(originalArr[2]))
		self:SetWndEasyImage(buyCountIcon,icon)
		money = originalArr[3]
	else
		--money = gModelPay:GetRMBValueByWelfareId(tonumber(expend2))
		money =gModelPay:GetShowByWelfareId(tonumber(expend2)) -- string.replace(ccClientText(19206),money)
	end
	self:SetWndButtonText(buyBtn,money)
	if isPersonal then
		self:SetWndClick(buyBtn,function ()
			self:OnClickBuyGift(itemdata,not isItemBuy and expend2 ~= "-1")
		end)
		self:SetWndClick(buyCountBtn,function ()
			self:OnClickBuyGift(itemdata,not isItemBuy and expend2 ~= "-1")
		end)
	end

	local InstanceID = item:GetInstanceID()
	local itemList = LxDataHelper.ParseItem(entryCfg1.reward)
	local uiIconEasyList = self._uiScrollList[InstanceID]
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		uiIconEasyList:Create(self, awardScroll)
		uiIconEasyList:SetShowNum(true)
		uiIconEasyList:SetIconClickPath("CommonUI")
		--uiIconEasyList:SetShowExtraNum(true,"CommonUI/NumTxt")
		self._uiScrollList[InstanceID] = uiIconEasyList
	end
	uiIconEasyList:RefreshList(itemList)
end

function UISubLuckGift:InitEvent()

end

function UISubLuckGift:RefreshData()
	local list = self._entry or {}
	table.sort(list,function (a,b)
		local aMarketData = a.MarketData
		local bMarketData = b.MarketData
		local apersonal,apersonalGoal = aMarketData.personal,aMarketData.personalGoal
		local abuyNum = apersonalGoal - apersonal > 0 and 1 or 0
		local bpersonal,bpersonalGoal = bMarketData.personal,bMarketData.personalGoal
		local bbuyNum = bpersonalGoal - bpersonal > 0 and 1 or 0
		if abuyNum ~= bbuyNum then
			return abuyNum > bbuyNum
		end
		return a.entryId < b.entryId
	end)
	if self._uiCellList then
		self._uiCellList:RefreshList(list)
	else
		self._uiCellList = self:GetUIScroll("giftList")
		self._uiCellList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
		self._uiCellList:EnableScroll(true,false)
	end
end

function UISubLuckGift:ResetData(pb)
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

function UISubLuckGift:InitCommand()
	self._sid = self:GetWndArg("sid")
	local entry = self:GetWndArg("entry")
	self._pageId = entry[1].pageId
	self._entry = entry
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	local data = activityData.config
	local giftHero,giftHeroPos,giftHeroTxt,giftHeroTxtImage,giftHeroTxtImagePos
	= data.giftHero,data.giftHeroPos,data.giftHeroTxt,data.giftHeroTxtImage,data.giftHeroTxtImagePos
	local newImage,newImageFrame2
	= data.newImage3,data.newImageFrame2
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
	if not string.isempty(giftHero) then
		local paint
		local arr = string.split(giftHero,"=")
		if arr[1] == "1" then
			paint = self.mHeroImg
			self:SetWndEasyImage(paint,arr[2],nil,true)
		elseif arr[1] == "2" then
			paint = self.mHeroPaint
			self:CreateWndSpine(paint,arr[2],"giftHero")
		elseif tonumber(giftHero) > 0 then
			local ref = gModelHero:GetShowEffectById(tonumber(giftHero))
			if ref then
				paint = self.mHeroPaint
				self:CreateWndSpine(paint,ref.heroDrawing,"giftHero",false,function(dpSpine)
					dpSpine:SetScale(0.8)
				end)
			end
		end
		if paint and not string.isempty(giftHeroPos) then
			CS.ShowObject(paint,true)
			local pos = LxDataHelper.ParseVector2NotEmpty2(giftHeroPos)
			self:SetAnchorPos(paint, pos)
		end
	end
	if giftHeroTxt and giftHeroTxt ~= "" then
		local str = string.gsub(giftHeroTxt,"\\n","\n")
		self:SetWndText(self.mDesText,str)
	end
	if LxUiHelper.IsImgPathValid(giftHeroTxtImage) then
		local paint = self.mTextImg
		self:SetWndEasyImage(paint,giftHeroTxtImage,function ()
			CS.ShowObject(paint,true)
		end ,true)
		if paint and not string.isempty(giftHeroTxtImagePos) then
			local pos = LxDataHelper.ParseVector2NotEmpty2(giftHeroTxtImagePos)
			self:SetAnchorPos(paint, pos)
		end
	end
	self:RefreshData()
end

function UISubLuckGift:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
end

function UISubLuckGift:OnClickBuyGift(itemdata,isRMB)
	if isRMB then
		local welfareId = tonumber(itemdata.MarketData.expend2)
		gModelPay:GiftPayCtrl(itemdata.entryId,welfareId,ModelPay.PAY_TYPE_ACTIVITY,0,self._sid,itemdata.pageId)
	else
		gModelActivity:OnActivityMarkeyBuyReq(self._sid, itemdata.pageId, itemdata.entryId)
	end
end
------------------------------------------------------------------
return UISubLuckGift


