---
--- Created by BY.
--- DateTime: 2023/10/27 15:43:56
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubCHNExcGje:LChildWnd
local UISubCHNExcGje = LxWndClass("UISubCHNExcGje", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubCHNExcGje:UISubCHNExcGje()
	self._commonIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubCHNExcGje:OnWndClose()
	self:ClearCommonIconList(self._commonIconList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubCHNExcGje:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubCHNExcGje:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubCHNExcGje:DoBatchBuy(itemdata)
	local marketData   	= itemdata.MarketData
	local goodsData = {}
	goodsData.personalGoal = marketData.personalGoal
	goodsData.personal = marketData.personal
	local list = LxDataHelper.ParseItem(marketData.expend2)
	goodsData.price = {itemPrices=list}

	goodsData.sid = self._sid
	goodsData.pageId = self._pageId
	goodsData.entryId = itemdata.entryId

	local item = itemdata.items[1]
	goodsData.item = {
		itemId = item.itemId,
		itemNum = item.count,
		itemType = item.type,
	}
	goodsData.resetType = marketData.condResetType

	GF.OpenWnd("UIDianBuy",{goodsData =goodsData,shopType = ModelShop.ACTIVITY, bSupportMultiPrice = true})
end

function UISubCHNExcGje:OnClickExchange(itemdata)
	local bool = self:IsMeet(itemdata,true)
	if not bool then
		return
	end

	local item = itemdata.items[1]
	local notBatchBuyIds = {}
	notBatchBuyIds[120026] = true
	notBatchBuyIds[161004] = true
	notBatchBuyIds[13000001] = true
	notBatchBuyIds[195272] = true
	notBatchBuyIds[1200005] = true

	if notBatchBuyIds[item.itemId] then
		gModelActivity:OnActivityMarkeyBuyReq(self._sid, self._pageId, itemdata.entryId)
	else
		self:DoBatchBuy(itemdata)
	end

	--gModelActivity:OnActivityReceiveGoalReq(self._sid, self._pageId,itemdata.entryId)
end

function UISubCHNExcGje:ListItem(list,item, itemdata, itempos)
	local itemRoot = CS.FindTrans(item,"ItemRoot")
	local cellSuper = CS.FindTrans(item,"CellSuper")
	local btnExchange = CS.FindTrans(item,"BtnExchange")
	local redPoint = CS.FindTrans(item,"BtnExchange/redPoint")
	local numText = CS.FindTrans(item,"NumText")
	local marketData   	= itemdata.MarketData
	local InstanceID = item:GetInstanceID()

	local baseClass = self._commonIconList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._commonIconList[InstanceID] = baseClass
		baseClass:Create(itemRoot)
		self:SetIconClickScale(itemRoot, true)
	end

	local itemS = itemdata.items[1]
	baseClass:SetCommonReward(itemS.type, itemS.itemId, itemS.count)
	baseClass:DoApply()
	self:SetWndClick(itemRoot,function ()
		gModelGeneral:OpenItemInfoTipsFormChat(itemS)
	end)
	local buyNum = marketData.personalGoal - marketData.personal
	local buyStr = LUtil.FormatColorStr(buyNum,buyNum > 0 and "lightGreen" or "lightRed")
	self:SetWndText(numText,string.replace(ccClientText(22203),buyStr))
	self:InitTextLineWithLanguage(numText, -30)
	self:SetWndButtonText(btnExchange,ccClientText(22202))
	local isRed = self:IsMeet(itemdata,false)
	CS.ShowObject(redPoint,isRed)
	self:SetWndButtonGray(btnExchange,buyNum <= 0)
	self:SetWndClick(btnExchange,function ()
		self:OnClickExchange(itemdata)
	end)

	local list = LxDataHelper.ParseItem(marketData.expend2)
	local _uiItemList = self:GetUIScroll(InstanceID)
	if _uiItemList:GetList() then
		_uiItemList:RefreshList(list)
	else
		_uiItemList:Create(cellSuper,list,function (...) self:ItemListItem(...) end,UIItemList.SUPER)
		_uiItemList:EnableScroll(false,false)
	end
	_uiItemList:DrawAllItems()
end

function UISubCHNExcGje:IsMeet(itemdata,isTips)
	local marketData   	= itemdata.MarketData
	if marketData.personalGoal - marketData.personal <= 0 then
		if isTips then
			GF.ShowMessage(ccClientText(22204))
		end
		return false
	end
	local isExchange = true
	local list = LxDataHelper.ParseItem(marketData.expend2)
	for i, v in ipairs(list) do
		local refId = v.itemId
		local itemNum = v.itemNum
		local curritemNum = gModelItem:GetNumByRefId(refId)
		if curritemNum < itemNum then
			isExchange = false
			break
		end
	end
	if not isExchange then
		if isTips then
			GF.ShowMessage(ccClientText(22206))
		end
		return false
	end
	return true
end


function UISubCHNExcGje:ResetData(pb)
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

function UISubCHNExcGje:InitEvent()

end

function UISubCHNExcGje:InitCommand()
	self._sid = self:GetWndArg("sid")
	local entry = self:GetWndArg("entry")
	self._pageId = entry[1].pageId
	self._entry = entry
	local _sid = self._sid

	local activityData = gModelActivity:GetWebActivityDataById(_sid)
	local data = activityData.config

	local privilegeHero,privilegeHeroPos,privilegeHeroTxt,itemId,dropTxtPos
	= data.heroCollect,data.heroCollectPos,data.dropTxt,data.dropItemId,data.dropTxtPos
	if privilegeHero and privilegeHero > 0 then
		local ref = gModelHero:GetShowEffectById(privilegeHero)
		self:CreateWndSpine(self.mHeroPaint,ref.heroDrawing,"collectionHero",false,function(dpSpine)
			dpSpine:SetScale(0.8)
		end)
		local privilegeHeroPosArr = string.split(privilegeHeroPos,"|")
		self.mHeroPaint.anchoredPosition = Vector3(tonumber(privilegeHeroPosArr[1]),tonumber(privilegeHeroPosArr[2]),0)
	end
	if privilegeHeroTxt and privilegeHeroTxt ~= "" then
		local str = string.gsub(privilegeHeroTxt,"\\n","\n")
		self:SetWndText(self.mDesText,str)
		CS.ShowObject(self.mDesBg,true)
		local arr = string.split(dropTxtPos,"|")
		local isScale = arr[1] and arr[1] == "1"
		if isScale then
			self.mBg.localScale = Vector2(-1,1)
		end
		if arr[2] then
			local pos = string.split(arr[2],",")
			self.mDesBg.anchoredPosition = Vector2(tonumber(pos[1]),tonumber(pos[2]))
		end
	end
	self._itemId = itemId
	self:RefreshData()
	local bool = gModelActivity:GetIsOpentBySidPageId(_sid,self._pageId)
	if bool then
		gModelActivity:SetIsOpentBySidPageId(_sid,self._pageId)
	end
end

function UISubCHNExcGje:ItemListItem(list,item, itemdata, itempos)
	local icon = CS.FindTrans(item,"Image")
	local text = CS.FindTrans(item,"UIText")

	local refId = itemdata.itemId
	local ref = gModelItem:GetRefByRefId(refId)
	local itemNum = itemdata.itemNum
	local curritemNum = gModelItem:GetNumByRefId(refId)
	self:SetWndEasyImage(icon,ref.icon)
	local buyStr = LUtil.FormatColorStr(LUtil.NumberCoversion(curritemNum),curritemNum >= itemNum and "lightGreen" or "lightRed")
	self:SetWndText(text,string.replace(ccClientText(22201),buyStr,LUtil.NumberCoversion(itemNum)))

	local itemInfo = {
		itemId = refId,
		itemNum = itemNum,
		itemType = 1,
	}
	self:SetWndClick(item,function ()
		gModelGeneral:ShowCommonItemTipWnd(itemInfo,{showSkinCode=true})
	end)
end

function UISubCHNExcGje:RefreshData()
	local list = self._entry or {}

	table.sort(list,function (a,b)
		local aMarketData   	= a.MarketData
		local bMarketData   	= b.MarketData
		local isA = aMarketData.personalGoal - aMarketData.personal <= 0 and 1 or 0
		local isB = bMarketData.personalGoal - bMarketData.personal <= 0 and 1 or 0
		if isA ~= isB then
			return isA < isB
		end
		return a.sort < b.sort
	end)
	local _uiItemList = self._uiItemList
	if _uiItemList then
		_uiItemList:RefreshList(list)
	else
		_uiItemList = self:GetUIScroll("ExchangeList")
		_uiItemList:Create(self.mItemSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
		_uiItemList:EnableScroll(true,false)
		self._uiItemList = _uiItemList
	end
	_uiItemList:DrawAllItems()
end

function UISubCHNExcGje:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:ResetData(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityMarkeyBuyResp,function (pb)
		self:RefreshData()
	end)
end
------------------------------------------------------------------
return UISubCHNExcGje


