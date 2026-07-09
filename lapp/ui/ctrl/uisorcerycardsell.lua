---
--- Created by BY.
--- DateTime: 2022/7/28 17:47:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISorceryCardSell:LWnd
local UISorceryCardSell = LxWndClass("UISorceryCardSell", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISorceryCardSell:UISorceryCardSell()
	self._isAll = true
	self._commonIconList = {}
	self._sellNumList = {}
	self._selAllList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISorceryCardSell:OnWndClose()
	self:ClearCommonIconList(self._commonIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISorceryCardSell:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISorceryCardSell:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISorceryCardSell:InitEvent()
	self:SetWndClick(self.mBgImage,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnCut,function ()self:OnClickCut() end)
	self:SetWndClick(self.mBtnCancel,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm,function ()self:OnClickConfirm() end)
end
function UISorceryCardSell:OnDrawAllItems()
	if self._uiList then
		self._uiList:DrawAllItems()
	end
end
function UISorceryCardSell:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local itemRoot = self:FindWndTrans(root,"ItemRoot")
	local toggle = self:FindWndTrans(root,"Toggle")
	local checkmark = self:FindWndTrans(root,"Toggle/Background/Checkmark")
	local btnJian = self:FindWndTrans(root,"Image/BtnJian")
	local numText = self:FindWndTrans(root,"Image/NumText")
	local btnJia = self:FindWndTrans(root,"Image/BtnJia")

	local InstanceID = item:GetInstanceID()
	local _isAll = not self._isAll
	local curNum = self._sellNumList[itemdata] or 0
	local bagNum = gModelItem:GetNumByRefId(itemdata)

	CS.ShowObject(toggle,_isAll)
	if _isAll then
		CS.ShowObject(checkmark,self._selAllList[itemdata])
	end
	self:SetWndText(numText,curNum)

	local itemInfo = {
		itemType = 1,
		itemId = itemdata,
		itemNum = bagNum
	}
	self:InitCommonIcon(InstanceID,itemRoot,itemInfo,function ()
		if _isAll then
			self:OnClickAll(itemdata,bagNum)
		else
			gModelGeneral:ShowCommonItemTipWnd(itemInfo)
		end
	end)
	self:SetWndClick(btnJian,function ()
		self:OnChangeItemNum(1,itemdata,bagNum)
	end)
	self:SetWndClick(btnJia,function ()
		self:OnChangeItemNum(2,itemdata,bagNum)
	end)
end
function UISorceryCardSell:OnClickAll(itemId,maxNum)
	local isAll = self._selAllList[itemId]
	self._sellNumList[itemId] = not isAll and maxNum or 0
	self._selAllList[itemId] = not isAll
	self:UpdateGetItemShow()
	self:OnDrawAllItems()
end

function UISorceryCardSell:SetCutText()
	local _isAll = self._isAll
	local _cutStr = _isAll and ccClientText(29525) or ccClientText(29544)
	self:SetWndButtonText(self.mBtnCut,_cutStr)
end
function UISorceryCardSell:OnClickConfirm()
	local data = {}
	local _sellNumList = self._sellNumList or {}
	for i, v in pairs(_sellNumList) do
		if v > 0 then
			local d = {
				refId = i,
				num = v,
				itype = 1,
			}
			table.insert(data,d)
		end
	end
	if #data <= 0 then
		GF.ShowMessage(ccClientText(29555))
		return
	end
	gModelGeneral:OnSellGoodsReq(data)
end

function UISorceryCardSell:OnClickCut()
	local _isAll = not self._isAll
	self._isAll = _isAll
	self:SetCutText()
	self:OnDrawAllItems()
end
function UISorceryCardSell:SetItemList(item,itemdata)
	if not item then return end
	CS.ShowObject(item,itemdata)
	if not itemdata then return end
	local numIcon = self:FindWndTrans(item,"Item/NumIcon")
	local numText = self:FindWndTrans(item,"NumText")

	local ref = gModelItem:GetRefByRefId(itemdata.itemId)
	self:SetWndEasyImage(numIcon,ref.icon)
	self:SetWndText(numText,itemdata.itemNum)
end

function UISorceryCardSell:RefreshData()
	local cardList = gModelSorceryCard:GetCardList()
	if not cardList then
		gModelSorceryCard:OnSorceryCardOpenReq()
		return
	end
	local list = {}
	local refList = gModelSorceryCard:GetSorceryCardRefByTheme(0)
	for i, v in ipairs(refList) do
		local cardInfo = cardList[v.refId]
		if cardInfo then
			local level = cardInfo.level
			if level >= v.sellLimitLevel then
				local bagNum = gModelItem:GetNumByRefId(v.associateItem)
				if bagNum > 0 then
					table.insert(list,v.associateItem)
				end
			end
		end
	end

	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(list)
		uiList:DrawAllItems()
	else
		uiList = self:GetUIScroll("mCellSuper_UISorceryCardSell")
		self._uiList = uiList
		uiList:Create(self.mCellSuper,list,function(...) self:ListItem(...) end,UIItemList.SUPER_GRID)
		uiList:EnableScroll(true,false)
	end
end
function UISorceryCardSell:UpdateGetItemShow()
	local selNum = 0
	local list = {}
	local _sellNumList = self._sellNumList or {}
	for i, v in pairs(_sellNumList) do
		if v and v > 0 then
			selNum = selNum + 1
		end
		local ref = gModelItem:GetRefByRefId(i)
		local sell = ref.sell
		if not string.isempty(sell) then
			local item = LxDataHelper.ParseItem(sell)
			for j, k in ipairs(item) do
				local data = list[k.itemId]
				if data then
					data.itemNum = data.itemNum + k.itemNum * v
				else
					k.itemNum = k.itemNum * v
					data = k
				end
				list[k.itemId] = data
			end

		end
	end
	local itemList = {}
	for i, v in pairs(list) do
		table.insert(itemList,v)
	end
	for i = 1, 3 do
		local item = self._itemList[i]
		local data = itemList[i]
		self:SetItemList(item,data)
	end
	CS.ShowObject(self.mGetMag,selNum > 0)
	self:SetWndText(self.mSelText,string.replace(ccClientText(29524),selNum))
end
function UISorceryCardSell:OnChangeItemNum(type,itemId,maxNum)
	local curNum = self._sellNumList[itemId] or 0
	local num = 0
	if type == 1 then
		num = curNum - 1
		if num <= 0 then
			num = 0
			self._selAllList[itemId] = false
		end
	else
		num = curNum + 1
		if num > maxNum then
			num = maxNum
		end
	end
	self._sellNumList[itemId] = num
	self:UpdateGetItemShow()
	self:OnDrawAllItems()
end
function UISorceryCardSell:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(29543))
	self:SetWndText(self.mGetText,ccClientText(29523))
	self:SetWndButtonText(self.mBtnCancel,ccClientText(29545))
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(29546))
	self._itemList = {
		self.mItem1,
		self.mItem2,
		self.mItem3
	}
	self:SetCutText()
	self:RefreshData()
end
function UISorceryCardSell:InitCommonIcon(key,root,itemInfo,func)
	local baseClass = self._commonIconList[key]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._commonIconList[key] = baseClass
		baseClass:Create(root)
		self:SetIconClickScale(root, true)
	end
	baseClass:SetCommonReward(itemInfo.itemType, itemInfo.itemId, itemInfo.itemNum)
	baseClass:DoApply()
	self:SetWndClick(root,function () if func then func() end end)
end
function UISorceryCardSell:InitMessage()
	self:WndNetMsgRecv(LProtoIds.SorceryCardOpenResp,function(pb) self:RefreshData() end)
	self:WndNetMsgRecv(LProtoIds.SellGoodsResp,function(pb)
		self._sellNumList = {}
		self:UpdateGetItemShow()
		self:RefreshData()
	end)
end
------------------------------------------------------------------
return UISorceryCardSell


