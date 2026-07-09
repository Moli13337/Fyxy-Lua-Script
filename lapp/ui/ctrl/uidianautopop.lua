---
--- Created by BY.
--- DateTime: 2023/10/28 14:11:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDianAutoPop:LWnd
local UIDianAutoPop = LxWndClass("UIDianAutoPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDianAutoPop:UIDianAutoPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDianAutoPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDianAutoPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDianAutoPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIDianAutoPop:RefreshData()
	local shopId = self._shopId
	local shopRef = gModelShop:GetShopRef(shopId)
	local type = shopRef.type
	local list = gModelShop:GetShopItmeListByType(type)

	local uiList = self:FindUIScroll("UIDianAutoPop")
	if not uiList then
		uiList = self:GetUIScroll("UIDianAutoPop")
		uiList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end,UIItemList.SUPER_GRID)
		uiList:EnableScroll(true,false)
	else
		uiList:RefreshList(list)
		uiList:DrawAllItems()
	end
	local shopAutoBuySet = gModelShop:GetShopAutoBuySetList(shopId)
	local isAuto = shopAutoBuySet and shopAutoBuySet.open == 1
	self._isAuto = isAuto
	local btnStr = isAuto and ccClientText(11427) or ccClientText(11426)
	local iconStr = isAuto and "public_btn_icon_30" or "public_btn_icon_31"
	self:SetWndText(self.mOffText,btnStr)
	self:SetWndEasyImage(self.mOffIcon,iconStr)
end

function UIDianAutoPop:OnClickSel(refId,itempos)
	local isAuto = self._shopItemAutoList[refId]
	local noSel = not isAuto
	self._setList[refId] = noSel
	self._shopItemAutoList[refId] = noSel
	local uiList = self:FindUIScroll("UIDianAutoPop")
	if uiList then
		uiList:DrawAllItems()
	end
end
function UIDianAutoPop:OnClickClose()
	local isSeq = false
	for i, v in pairs(self._setList) do
		isSeq = true
		break
	end
	if not isSeq then
		self:WndClose()
		return
	end
	local list = {}
	for i, v in pairs(self._shopItemAutoList) do
		if v then
			table.insert(list,i)
		end
	end
	local len = #list
	local buySet = {
		shopId = self._shopId,
		open = len > 0 and (self._isAuto and 1 or 0) or 0,
		goodsId = list
	}
	gModelShop:ShopAutoBuySetReq(buySet,len > 0 and 1 or 2)
end
function UIDianAutoPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(11423))
	self:SetWndText(self.mDesText,ccClientText(11424))

	local shopId = self:GetWndArg("shopId")
	self._shopId = shopId
	local shopAutoBuySet = gModelShop:GetShopAutoBuySetList(shopId)
	local shopItemAutoList = {}
	if shopAutoBuySet and shopAutoBuySet.goodsId then
		for i, v in ipairs(shopAutoBuySet.goodsId) do
			shopItemAutoList[v] = true
		end
	end
	self._shopItemAutoList = shopItemAutoList
	self._setList = {}
	self:RefreshData()
end
function UIDianAutoPop:ListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local itemRoot = self:FindWndTrans(root,"ItemRoot")
	local tagImg = self:FindWndTrans(root,"TagImg")
	local tagText = self:FindWndTrans(root,"TagImg/TagText")
	local selImg = self:FindWndTrans(root,"SelBg/SelImg")
	local nameText = self:FindWndTrans(root,"NameText")
	local goldText = self:FindWndTrans(root,"GoldText")
	local goldIcon = self:FindWndTrans(root,"GoldText/GoldIcon")

	local reward = LxDataHelper.ParseItem_4(itemdata.reward)
	local fixDiscount = ccLngText(itemdata.fixDiscount)
	local name = gModelItem:GetNameByRefId(reward.itemId)
	local price = LxDataHelper.ParseItem_4(itemdata.price)
	local priceIcon = gModelItem:GetItemIconByRefId(price.itemId)
	local _isAuto = self._shopItemAutoList[itemdata.refId]

	self:CreateCommonIconImpl(itemRoot,reward)
	CS.ShowObject(tagImg,not string.isempty(fixDiscount))
	self:SetWndText(tagText,fixDiscount)
	CS.ShowObject(selImg,_isAuto)
	self:SetWndText(nameText,name)
	self:SetWndText(goldText,LUtil.NumberCoversion(price.itemNum))
	CS.ShowObject(goldIcon,true)
	self:SetWndEasyImage(goldIcon,priceIcon)
	self:SetWndClick(root,function ()
		self:OnClickSel(itemdata.refId,itempos)
	end)
end

function UIDianAutoPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnOff, function(...) self:OnClickOff() end)
end
function UIDianAutoPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ShopAutoBuySetResp,function (...) self:WndClose(...) end)
end
function UIDianAutoPop:OnClickOff()
	local list = {}
	for i, v in pairs(self._shopItemAutoList) do
		if v then
			table.insert(list,i)
		end
	end
	local len = #list
	if not self._isAuto and len <= 0 then
		GF.ShowMessage(ccClientText(11430))
		return
	end
	local func = function()
		local buySet = {
			shopId = self._shopId,
			open = self._isAuto and 0 or 1,
			goodsId = list
		}
		gModelShop:ShopAutoBuySetReq(buySet,2)
	end
	if not self._isAuto then
		gModelGeneral:OpenUIOrdinTips({refId = 53501,func = function (...)
			if func then func() end
		end})
		return
	end
	if func then func() end
end
------------------------------------------------------------------
return UIDianAutoPop


