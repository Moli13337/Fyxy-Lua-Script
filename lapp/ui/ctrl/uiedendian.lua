---
--- Created by Administrator.
--- DateTime: 2023/10/31 18:34:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEdenDian:LWnd
local UIEdenDian = LxWndClass("UIEdenDian", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEdenDian:UIEdenDian()
	---@type table<number, CommonIcon>
	self._commonIconClsTbl = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEdenDian:OnWndClose()
	self:ClearCommonIconList(self._commonIconClsTbl)
	self._commonIconClsTbl = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEdenDian:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEdenDian:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	--self:DoWndStartScale(0,self.mRoot)

	self:SetStaticContent()
	self:InitData()
	self:InitUIEvent()
	self:RefreshUI()
end

function UIEdenDian:InitData()
	self._buyList ={}

	self._discountIcons=
	{
		[1] = "shop_txt_sale_1",
		[2] = "shop_txt_sale_2",
		[3] = "shop_txt_sale_3",
		[4] = "shop_txt_sale_4",
		[5] = "shop_txt_sale_5",
		[6] = "shop_txt_sale_6",
		[7] = "shop_txt_sale_7",
		[8] = "shop_txt_sale_8",
		[9] = "shop_txt_sale_9",
	}
end

function UIEdenDian:SetStaticContent()
	local str =ccClientText(16797) --"商品购买"
	self:SetWndText(self.mTitle,str)

	self:SetWndText(self.mCloseTip,ccClientText(10103))
end

function UIEdenDian:OnDrawItem(list,item,itemdata,itempos)
	local root = self:FindWndTrans(item,"root")
	local buyBtn = self:FindWndTrans(item,"buyBtn")
	local buyBtnIcon = self:FindWndTrans(buyBtn,"icon")
	local buyBtnNum = self:FindWndTrans(buyBtn,"num")
	local soldout = self:FindWndTrans(item,"soldout")
	--local soldoutIcon = self:FindWndTrans(soldout,"icon")
	local discount = self:FindWndTrans(item,"discount")


	local refId = itemdata.refId
	local cfg = gModelWonderland:GetGoodsConfig(refId)
	local reward = cfg.reward

	local iconTrans = CS.FindTrans(root, "CommonUI/Icon")
	local instanceId = item:GetInstanceID()
	local iconCls = self._commonIconClsTbl[instanceId]
	if not iconCls then
		iconCls = CommonIcon:New()
		self._commonIconClsTbl[instanceId] = iconCls
		iconCls:Create(iconTrans)
	end
	iconCls:SetCommonReward(reward.itemType, reward.itemId, reward.itemNum)
	iconCls:EnableShowNum(true)
	iconCls:DoApply()

	self:SetIconClickScale(iconTrans,true)
	self:SetWndClick(iconTrans, function () gModelGeneral:ShowCommonItemTipWnd(reward) end)

	local price = cfg.price
	local icon = gModelItem:GetItemImgByRefId(price.itemId)
	if icon then
		self:SetWndEasyImage(buyBtnIcon,icon)
	end

	local numStr = LUtil.NumberCoversion(price.itemNum)
	self:SetWndText(buyBtnNum,numStr)

	local disc = cfg.discount
	local showDis = false
	if disc > 0 then
		showDis = true
		local iconPath = self._discountIcons[cfg.discount]
		self:SetWndEasyImage(discount,iconPath)
	end
	CS.ShowObject(discount,showDis)


	--local state = self._data.state
	--local allowBuy = state == StructWonderlandGrid.SELECTED
	local cnt = self._buyList[refId] or 0
	local num = itemdata.num
	local isSoldOut =cnt>= num

	CS.ShowObject(soldout,isSoldOut)

	--local showGray = isSoldOut or not allowBuy
	--local state = showGray and 1 or 0

	self:SetWndClick(buyBtn,function () self:OnClickBuy(itempos) end,LSoundConst.TRIGGER_BUY_COMMON)
end

function UIEdenDian:OnClickGoto()
	local state = self._data.state
	local gridIndex = self._data.gridIndex
	if state == StructWonderlandGrid.ALLOW then
		self._data.state = StructWonderlandGrid.SELECTED
		gModelWonderland:WonderlandOpsReq(ModelWonderland.EVENT_SELECT_GRID,tostring(gridIndex))
		local list = self:GetUIScroll("goodsList")
		local uiList  =  list:GetList()
		if uiList then
			uiList:DrawAllItems()
		end
		self:SetButtonText()

		local str =ccClientText(16728) --"欢迎来到奇境商店"
		GF.ShowMessage(str)
	elseif state == StructWonderlandGrid.SELECTED then
		self:LeaveShop()
	else
		local str =ccClientText(16732)-- "你还没有到达商店，不可购买"
		GF.ShowMessage(str)
	end
end

function UIEdenDian:SetEventTitle(eventId)
	local eventCfg = gModelWonderland:GetEventConfig(eventId)
	local name = ccLngText(eventCfg.name)
	self:SetWndText(self.mMainTitle,name)
end

function UIEdenDian:OnClickBuy(itempos)

	local canSelect = self._data.canSelect
	if not canSelect then
		local str =ccClientText(16735)-- "你还没有到达商店，不可购买"
		GF.ShowMessage(str)
		return
	end



	local state = self._data.state
	--local gridIndex = self._data.gridIndex
	if state == StructWonderlandGrid.ALLOW then
		local str =ccClientText(16755) --"请先点击前往"
		GF.ShowMessage(str)
		return
	end



	self:SetButtonText()

	local goodsData = self._goodsList[itempos]
	local itemId = goodsData.refId

	local cfg = gModelWonderland:GetGoodsConfig(itemId)
	local num = goodsData.num
	local cnt = self._buyList[itemId] or 0

	local name = gModelGeneral:GetCommonItemName(cfg.reward)
	if cnt >= num then

		local str =ccClientText(16736)-- "%s已经卖光了,请选择其他商品购买"
		str = string.replace(str,name)
		GF.ShowMessage(str)
		return
	end

	local price = cfg.price
	local priceId = price.itemId
	local priceNum = price.itemNum
	local own = gModelItem:GetNumByRefId(priceId)
	if own< priceNum then
		gModelGeneral:OpenGetWayWnd({itemId= priceId,srcWnd = self:GetWndName()})
		return
	end

	local func = function()

		if self:IsWndClosed() then
			return
		end

		self._buyList[itemId] = cnt + 1
		local index = itempos-1

		local itemList = self:GetUIScroll("goodsList")
		local uiList= itemList:GetList()
		uiList:DrawItemByIndex(itempos)

		gModelWonderland:WonderlandOpsReq(self._eventType,tostring(index))

		local isAllSold = self:CheckAllSold()
		if isAllSold then
			gModelWonderland:WonderlandOpsReq(self._eventType,tostring(-1))
			self:WndClose()
		end
	end

	local para =
	{
		refId = 70007,
		func = func,
		para ={tostring(priceNum),name},
		consume = {priceNum, priceId},
	}

	gModelGeneral:OpenUIOrdinTips(para)
end

function UIEdenDian:InitUIEvent()
	self:SetWndClick(self.mGotoBtn,function () self:OnClickGoto() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function ()	self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseTip,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIEdenDian:RefreshUI()
	local data = self:GetWndArg("data")
	self._data = data
	self._eventType = data.eventType --self:GetWndArg("eventType")
	local moreInfo = data.moreInfo
	self._eventId = data.eventId
	local strs = string.split(moreInfo,"|")
	local dataList = {}
	for k,v in ipairs(strs) do
		local tempStr = string.split(v,"=")
		if #tempStr>=2 then
			local data =
			{
				refId = tonumber(tempStr[1]),
				num = tonumber(tempStr[2]),
			}

			table.insert(dataList,data)
		end
	end

	self._goodsList = dataList

	local list = self:GetUIScroll("goodsList")
	list:Create(self.mItemList,dataList,function (...) self:OnDrawItem(...) end)

	local eventId = data.eventId
	local textId = gModelWonderland:GetEventTextId(eventId)
	if textId then
		local textCfg = gModelWonderland:GetEventTextConfig(textId)
		local post = ccLngText(textCfg.dec)
		self:SetWndText(self.mPost,post)
	end
	local eventCfg = gModelWonderland:GetEventConfig(eventId)
	local spineKey = eventCfg.prefab
	if string.isempty(spineKey) then
		return
	end
	local scale = eventCfg.prefabSize or 1
	self:CreateWndSpine(self.mRole,spineKey,spineKey,false,function (spine)
		spine:SetScale(scale)
		spine:PlayAnimation(0,"idle",true)
	end)

	self:SetButtonText()

	--local canSelect = data.canSelect
	--self:SetWndImageGray(self.mGotoBtn,not canSelect)

	self:SetEventTitle(eventId)
end

function UIEdenDian:LeaveShop()
	local func = function()
		gModelWonderland:WonderlandOpsReq(self._eventType,tostring(-1))
		self:WndClose()
	end

	local para =
	{
		refId = 70008,
		func = func,
	}

	gModelGeneral:OpenUIOrdinTips(para)
end



function UIEdenDian:CheckAllSold()
	for k,v in pairs(self._goodsList) do
		local num = v.num
		local itemId = v.itemId
		local cnt = self._buyList[itemId] or 0
		if cnt<num then
			return false
		end
	end
	return true
end

function UIEdenDian:SetButtonText()
	local state = self._data.state
	local str =ccClientText(16733)-- "前  往"

	local imagePath = "public_btn_1_1"
	if self._data.canSelect then
		imagePath = "public_btn_1_2"
		if state == StructWonderlandGrid.SELECTED then
			str =ccClientText(16734)-- "离  店"
			imagePath = "public_btn_1_3"
		end
	end

	local text = self:FindWndTrans(self.mGotoBtn,"text")
	self:SetBtnImageAndMat(self.mGotoBtn,imagePath,text)
	self:SetWndText(text,str)
end

------------------------------------------------------------------
return UIEdenDian


