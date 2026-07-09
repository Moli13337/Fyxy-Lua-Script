---
--- Created by Administrator.
--- DateTime: 2023/10/19 16:02:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UICumSelect:LWnd
local UICumSelect = LxWndClass("UICumSelect", LWnd)
------------------------------------------------------------------

local OK_BUTTON_ICON_PATH = {
	COMMON 	= "public_btn_1_2",		--彩色
	GREY	= "public_btn_ash_8",	--灰色
}

--道具配置格式
local ITEM_CFG_FORMAT = "%s=%s=%s"


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UICumSelect:UICumSelect()
	---@type table<number,CommonIcon>
	self._uiCommonList = nil
	---@type table<number,CommonIcon>
	self._uiCommonPoolList = nil
	---@type table<number,table>
	self._formatsData = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UICumSelect:OnWndClose()
	LWnd.OnWndClose(self)

	self:ClearUIDrawCellList()
	self:ClearPoolCommonIconList()
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UICumSelect:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UICumSelect:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	self:InitMsg()
	self:Refresh()

	self:SetWndText(self.mNoSelectTxt, ccClientText(18601))
	self:SetWndButtonText(self.mCancelBtn, ccClientText(10101))
	self:SetWndText(self.mBottomTitleTxt, ccClientText(18602))
	self:SetWndText(self.mNoCustomItemTxt, ccClientText(18604))
end


function UICumSelect:OnActivityCustomGiftResp(pb)

end

function UICumSelect:ReSetSelectItemIndex()
	self._index = 1
	if not self._giftItemData then
		LogError("self._giftItemData is a nil")
		return
	end

	for k,v in ipairs(self._giftItemData) do
		if v.itemId == nil then
			self._index = k
			return
		end
	end
end

function UICumSelect:OnDrawCellItem(list, item, itemData, itemPos)
	local itemNumTrans	= self:FindWndTrans(item, "itemNum")
	local itemRoot		= self:FindWndTrans(item, "itemRoot")
	local selectImgTrans = self:FindWndTrans(item, "SelectImg")

	local itemNum, itemId, itemType, customList, customItemPos = itemData.itemNum, itemData.itemId, itemData.itemType, itemData.customList, itemData.customItemPos
	local haveItem		= itemId ~= nil
	local isCustomItem	= customList ~= nil
	local instanceID 	= item:GetInstanceID()
	local itemNumStr
	local formatData
	local isCurSelectItem = self._index == itemPos

	CS.ShowObject(selectImgTrans,isCurSelectItem)

	if not self._uiCommonList then
		self._uiCommonList = {}
	end
	local baseClass 	= self._uiCommonList[instanceID]
	if not baseClass then
		baseClass		= CommonIcon:New()
		self._uiCommonList[instanceID] = baseClass
		baseClass:Create(CS.FindTrans(itemRoot, "Icon"))
	end

	if not haveItem then
		--显示空格子
		itemNumStr = ""
		formatData	= {
			itemId			= nil,
			itemType		= nil,
			itemNum			= nil,
		}
	else
		itemNumStr = LUtil.NumberCoversion(itemNum)
		formatData	= {
			itemId			= itemId,
			itemType		= itemType,
			itemNum			= itemNum,
		}
	end
	if not self._formatsData then
		self._formatsData = {}
	end
	self._formatsData[customItemPos] = formatData
	baseClass:SetCommonReward(formatData.itemType, formatData.itemId, -1)
	self:SetWndText(itemNumTrans, itemNumStr)
	self:SetWndClick(itemRoot, function()
		self:SelectItemOnClick(customItemPos, formatData)
	end)
	baseClass:DoApply()
end

function UICumSelect:RefreshSelectDesc()
	if not self._index then
		self:ReSetSelectItemIndex()
	end

	local formatData = self._formatsData[self._index]
	if not formatData then
		LogError("self._formatsData[self._index] is not find, self._index"..self._index)
		printInfoNR(self._formatsData)
		return
	end

	local itemId		= formatData.itemId
	local itemType 		= formatData.itemType
	local haveItem		= itemId ~= nil

	CS.ShowObject(self.mNoSelectTxt, not haveItem)
	CS.ShowObject(self.mItemNameTxt,  haveItem)
	CS.ShowObject(self.mItemDescTxt,  haveItem)
	CS.ShowObject(self.mTipBtn,  haveItem)
	if not haveItem then return; end

	local itemName = gModelGeneral:GetCommonItemName(formatData)
	self:SetWndText(self.mItemNameTxt, itemName .. "×" .. formatData.itemNum)

	local desc
	if itemType == LItemTypeConst.TYPE_HERO then
		desc = ccClientText(17205)		 --英雄描述
	else
		desc = gModelItem:GetDescByRefId(itemId) --道具描述
	end
	self:SetWndText(self.mItemDescTxt, desc)

	self:SetWndClick(self.mTipBtn, function()
		if haveItem then
			gModelGeneral:ShowCommonItemTipWnd(formatData)
		end
	end)
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UICumSelect:OnActivityCustomGiftReq()
	local customItemData
	for k,v in ipairs(self._giftItemData) do
		local data = string.replace(ITEM_CFG_FORMAT, v.itemType, v.itemId, v.itemNum)
		if not customItemData then
			customItemData = data
		else
			customItemData = customItemData .. "," ..data
		end
	end

	gModelActivity:OnActivityCustomGiftReq(self._sid, self._pageId, self._entryId, customItemData)
end

function UICumSelect:OnClickCustomItem(itemNum, itemId, itemType, instanceID)
	local curGiftData = self._giftItemData[self._index]
	curGiftData.itemNum = itemNum
	curGiftData.itemId = itemId
	curGiftData.itemType = itemType
	self:RefreshTopChange()
	self:RefreshBottom()
end

function UICumSelect:GetShiftCustomPoolList(customPoolList)
	if not customPoolList then return nil; end

	local selectItemData	= self._giftItemData[self._index]
	local selectItemId, selectItemType = selectItemData.itemId, selectItemData.itemType

	local customPoolItemsList 		= string.split(customPoolList, ',')
	local customPoolItemsData		= {}
	for k, v in ipairs(customPoolItemsList) do
		local data 			= string.split(v or "" , "=")
		local itemType, itemId, itemNum = tonumber(data[1]), tonumber(data[2]),tonumber(data[3])
		local itemData 		= {
			itemId			= itemId,
			itemType		= itemType,
			itemNum			= itemNum,
			isSelect	= selectItemId == itemId and selectItemType == itemType,
		}
		table.insert(customPoolItemsData, itemData)
	end
	return customPoolItemsData
end

function UICumSelect:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...) self:OnActivityPageResp(...) end)
	--gModelActivity:OnActivityPageReq(self._sid)

	self:WndNetMsgRecv(LProtoIds.ActivityCustomGiftResp, function(...) self:OnActivityCustomGiftResp(...) end)
end

function UICumSelect:RefreshData()
	if not self._giftData then
		LogError("self._giftData is a nil")
		return
	end

	self:RefreshItemListData()
end

function UICumSelect:OnDrawCellCustomItem(list, item, itemData, itemPos)
	local itemNumTrans	= self:FindWndTrans(item, "itemNum")
	local itemRoot		= self:FindWndTrans(item, "itemRoot")
	local itemNameTrans = self:FindWndTrans(item,"itemName")

	local itemNum, itemId, itemType, isSelect = itemData.itemNum, itemData.itemId, itemData.itemType, itemData.isSelect
	local instanceID 	= item:GetInstanceID()
	local haveItem		= itemId ~= nil

	if not self._uiCommonPoolList then
		self._uiCommonPoolList = {}
	end
	local baseClass 	= self._uiCommonPoolList[instanceID]
	if not baseClass then
		baseClass		= CommonIcon:New()
		self._uiCommonPoolList[instanceID] = baseClass
		baseClass:Create(CS.FindTrans(itemRoot, "Icon"))
	end
	baseClass:SetCommonReward(itemType, itemId, -1)
	self:SetWndText(itemNumTrans, LUtil.NumberCoversion(itemNum))
	baseClass:ShowGouImg(isSelect or false)

	self:SetWndClick(itemRoot, function()
		if isSelect then return; end
		self:OnClickCustomItem(itemNum, itemId, itemType, instanceID)

	end)
	baseClass:DoApply()

	local name = ""
	if itemNameTrans and haveItem then
		name = gModelGeneral:GetCommonItemColorNameNoNum(itemData)
	end
	self:SetWndText(itemNameTrans,name)
end

function UICumSelect:ClearUIDrawCellList()
	if not self._uiCommonList then return end

	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil
end

function UICumSelect:InitEvent()
	self:SetWndClick(self.mCancelBtn, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UICumSelect:GetShiftCustomItemsData(customList)
	local customItemData = {}
	if not customList then
		return customItemData
	end

	local customItemsList 		= string.split(customList, '|')
	for k, v in ipairs(customItemsList) do
		local data 			= {
			customList		= v,
			customIndex		= k,
		}
		table.insert(customItemData, data)
	end
	return customItemData
end


--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################

function UICumSelect:Refresh()
	if not self._giftData then
		LogError("self._giftData is a nil")
		return
	end

	self:RefreshData()
	self:RefreshTop()
	self:RefreshBottom()
end

function UICumSelect:RefreshItemList()
	if not self._giftItemData then
		printInfoN("self._giftItemData is not find, self._pages = \n" .. (self._pages or nil))
		return
	end

	local uiList	 = self:GetUIScroll("itemList")
	if uiList:GetList() then
		uiList:RefreshList(self._giftItemData)
	else
		uiList:Create(self.mItemList, self._giftItemData, function(...) self:OnDrawCellItem(...) end)
		uiList:EnableScroll(false)
	end

end

function UICumSelect:GetShiftCustomGiftData(customList)
	local customGiftData = {}
	if not customList then
		return customGiftData
	end

	local customGiftList 	= string.split(customList or "", ',')
	for k, v in ipairs(customGiftList) do
		local giftData		= string.split(v, '=')
		if giftData then
			local data 			= {
				type		= tonumber(giftData[1]),
				itemId		= tonumber(giftData[2]),
				count		= tonumber(giftData[3]),
			}
			table.insert(customGiftData, data)
		end
	end
	return customGiftData
end

function UICumSelect:InitData()
	self._sid 		= self:GetWndArg("sid")
	self._pageId 	= self:GetWndArg("pageId")
	self._entryId	= self:GetWndArg("entryId")
	self._itemData	= self:GetWndArg("itemData")
	self._giftData  = self:GetWndArg("giftData")
	self._index		= self:GetWndArg("itemIndex")
	self._title		= self:GetWndArg("title")

	self._giftItemData = {}
end

function UICumSelect:SelectItemOnClick(itemPos, formatData)
	if self._index == itemPos then return; end
	self._index = itemPos
	self:RefreshTopChange()
	self:RefreshBottom()
end


function UICumSelect:OnActivityPageResp(pb)
	local sid = pb.sid
	if self._sid ~= sid then return end

	local pageData
	for k,v in ipairs(pb.pages) do
		if v.pageId == self._pageId then
			pageData = gModelActivity:GenerateActivePageDataFromPb(v)
			break
		end
	end
	if not pageData then return; end

	for k,v in ipairs(pageData.entry) do
		if v.entryId == self._entryId then
			self._giftData = {}
			table.insert(self._giftData, v)
			self:RefreshData()
		end
	end
end

function UICumSelect:RefreshTopChange()
	self:RefreshItemList()
	self:RefreshSelectDesc()
	self:RefreshBtnList()
end

function UICumSelect:CheckAllSelect()
	if not self._giftItemData then
		return false
	end

	for k,v in ipairs(self._giftItemData) do
		if v.itemId == nil then
			return false
		end
	end

	return true
end

--#####################################################################################################################
--## Bottom ###########################################################################################################
--#####################################################################################################################
function UICumSelect:RefreshBottom()
	if not self._giftItemData then
		LogError("self._giftItemData is a nil")
		return
	end

	local giftData = self._giftItemData[self._index]
	if not giftData then
		LogError("self._giftItemData[self._index] is not find, self._index = "..self._index.."; "..{self._giftItemData})
		return
	end

	local customData = self:GetShiftCustomPoolList(giftData.customList)
	local havePool	 = customData ~= nil

	CS.ShowObject(self.mNoCustomItemTxt, not havePool)
	CS.ShowObject(self.mCustomItemList, havePool)
	if not havePool then return; end

	local uiList	 = self:GetUIScroll("customItemList")
	if uiList:GetList() then
		uiList:RefreshList(customData)
	else
		uiList:Create(self.mCustomItemList, customData, function(...) self:OnDrawCellCustomItem(...) end)
		uiList:EnableScroll(true, false)
	end
end

function UICumSelect:RefreshBtnList()
	if not self._index then
		self:ReSetSelectItemIndex()
	end

	local formatData = self._formatsData[self._index]
	if not formatData then
		--LogError("self._formatsData[self._index] is not find, self._index"..self._index.."; self._formatsData"..self._formatsData)
		return
	end

	local itemId		= formatData.itemId
	local haveItem		= itemId ~= nil
	local allHaveItem	= self:CheckAllSelect()

	self:SetWndButtonText(self.mOkBtn, ccClientText(allHaveItem and 10102 or 18603))
	self:SetWndEasyImage(self.mOkBtn, haveItem and OK_BUTTON_ICON_PATH.COMMON or OK_BUTTON_ICON_PATH.GREY)
	self:SetWndClick(self.mOkBtn, function()
		if not haveItem then
			return
		elseif not allHaveItem then
			self:ReSetSelectItemIndex()
			self:RefreshTopChange()
			self:RefreshBottom()
		else
			self:OnActivityCustomGiftReq()
			self:WndClose()
		end
	end)
end

function UICumSelect:ClearPoolCommonIconList()
	if not self._uiCommonPoolList then return end
	self:ClearCommonIconList(self._uiCommonPoolList)
	self._uiCommonPoolList = nil
end

function UICumSelect:RefreshItemListData()
	local itemData		= self._giftData
	local marketData   	= itemData.marketData or itemData.MarketData
	local customList	= marketData.customList;	--可选商品列表
	local customGift	= marketData.customGift;	--已选商品列表

	local customPoolItemsData = self:GetShiftCustomItemsData(customList)
	local customGiftItemData  = self:GetShiftCustomGiftData(customGift)

	self._giftItemData	= {}
	for k,v in ipairs(customPoolItemsData) do
		local data 			= {
			customList		= v.customList,
			customIndex		= v.customIndex,
			customItemPos	= k,
		}

		if customGiftItemData and customGiftItemData[k] then
			local curCustomGift = customGiftItemData[k]
			data.itemId			= tonumber(curCustomGift.itemId)
			data.itemType		= tonumber(curCustomGift.type)
			data.itemNum		= tonumber(curCustomGift.count)
		end
		table.insert(self._giftItemData, data)
	end

	--local customItemNum = #self._giftItemData
	--for k,v in ipairs(itemsList) do
	--	local data = {
	--		itemId			= v.itemId,
	--		itemType		= v.itemType,
	--		itemNum			= v.itemNum,
	--		customList		= nil,
	--		customItemPos	= customItemNum + k,
	--	}
	--	table.insert(self._giftItemData, data)
	--end
end

--#####################################################################################################################
--## Top ##############################################################################################################
--#####################################################################################################################
function UICumSelect:RefreshTop()
	self:SetWndText(self.mTitleTxt, self._title)
	self:RefreshTopChange()
end

------------------------------------------------------------------
return UICumSelect


