---
--- Created by Administrator.
--- DateTime: 2023/10/28 10:41:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UICumSelectNew:LWnd
local UICumSelectNew = LxWndClass("UICumSelectNew", LWnd)

UICumSelectNew.NORMAl = 1
UICumSelectNew.POPUP_GIFT = 2

local OK_BUTTON_ICON_PATH = {
	COMMON 	= "public_btn_1_2",		--彩色
	GREY	= "public_btn_ash_8",	--灰色
}

--道具配置格式
local ITEM_CFG_FORMAT = "#a1#=#a2#=#a3#"
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UICumSelectNew:UICumSelectNew()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UICumSelectNew:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UICumSelectNew:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UICumSelectNew:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()


	local wndType = self:GetWndArg("wndType") or UICumSelectNew.NORMAl
	self._wndType = wndType

	if wndType == UICumSelectNew.NORMAl then
		self:ShowNormalContent()
	else
		self:ShowPopupContent()
	end

end

function UICumSelectNew:ShowPopupContent()
	self._id = self:GetWndArg("id")
	self._index = self:GetWndArg("itemIndex")
	self._giftData = self:GetWndArg("giftData")
	self._title = self:GetWndArg("title")

	self._giftItemData = {}

	self:SetWndText(self.mBottomTitleTxt, ccClientText(18606))
	self:SetWndText(self.mNoCustomItemTxt, ccClientText(18604))

	self:Refresh()

end

function UICumSelectNew:GetShiftCustomPoolList(customPoolList)
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

function UICumSelectNew:OnClickCustomItem(itemNum, itemId, itemType, instanceID)
	local curGiftData = self._giftItemData[self._index]
	curGiftData.itemNum = itemNum
	curGiftData.itemId = itemId
	curGiftData.itemType = itemType
	self:RefreshTopChange()
	self:RefreshBottom()
end

function UICumSelectNew:OnDrawCellItem(list, item, itemData, itemPos)
	local itemNumTrans	= self:FindWndTrans(item, "itemNum")
	local itemRoot		= self:FindWndTrans(item, "itemRoot")
	local selectImgTrans = self:FindWndTrans(item, "SelectImg")
	local itemName		= self:FindWndTrans(item, "itemNameTxt")
	local tipBtn		= self:FindWndTrans(item, "tipBtn")

	local itemNum, itemId, itemType, customList, customItemPos = itemData.itemNum, itemData.itemId, itemData.itemType, itemData.customList, itemData.customItemPos
	local haveItem		= itemId ~= nil
	local isCustomItem	= customList ~= nil
	local instanceID 	= item:GetInstanceID()
	local itemNumStr
	local formatData
	local isCurSelectItem = self._index == itemPos

	CS.ShowObject(selectImgTrans,isCurSelectItem)
	CS.ShowObject(itemName, not haveItem)
	CS.ShowObject(tipBtn,  haveItem)

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
	baseClass:SetCommonReward(formatData.itemType, formatData.itemId, itemNum)
	baseClass:EnableShowNum(true)
	--self:SetWndText(itemNumTrans, itemNumStr)
	self:SetWndClick(itemRoot, function()
		self:SelectItemOnClick(customItemPos, formatData)
	end)
	baseClass:DoApply()
	self:SetWndLongClick(itemRoot, function()
		gModelGeneral:ShowCommonItemTipWnd(formatData)
	end, 0.2,true)
	if haveItem then
		self:SetWndClick(tipBtn, function()
			gModelGeneral:ShowCommonItemTipWnd(formatData)
		end)
	else
		self:SetWndText(itemName, ccClientText(18605))
	end
end

function UICumSelectNew:SelectItemOnClick(itemPos, formatData)
	if self._index == itemPos then return; end
	self._index = itemPos
	self:RefreshTopChange()
	self:RefreshBottom()
end

function UICumSelectNew:CheckAllSelect()
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


function UICumSelectNew:OnActivityPageResp(pb)
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


--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################


function UICumSelectNew:Refresh()
	if not self._giftData then
		LogError("self._giftData is a nil")
		return
	end

	self:RefreshData()
	self:RefreshTop()
	self:RefreshBottom()
end

function UICumSelectNew:InitData()
	self._sid 		= self:GetWndArg("sid")
	self._pageId 	= self:GetWndArg("pageId")
	self._entryId	= self:GetWndArg("entryId")
	--self._itemData	= self:GetWndArg("itemData")
	self._giftData  = self:GetWndArg("giftData")
	self._index		= self:GetWndArg("itemIndex")
	self._title		= self:GetWndArg("title")
	self._callFunc  = self:GetWndArg("callFunc")
	self._giftItemData = {}
end

--#####################################################################################################################
--## Top ##############################################################################################################
--#####################################################################################################################
function UICumSelectNew:RefreshTop()
	self:SetWndText(self.mTitleTxt, self._title)
	self:InitTextLineWithLanguage(self.mTitleTxt, -30)
	self:RefreshTopChange()
end

function UICumSelectNew:GetShiftCustomItemsData(customList)
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

function UICumSelectNew:RefreshItemList()
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

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UICumSelectNew:OnActivityCustomGiftReq()
	local customItemData = self:FormatRewardStr()
	gModelActivity:OnActivityCustomGiftReq(self._sid, self._pageId, self._entryId, customItemData)
end

function UICumSelectNew:OnPopupGiftReq()
    local customItemData = self:FormatRewardStr()

    gModelPopupGift:OnPopupGiftSelectReq(self._id,customItemData)
end

function UICumSelectNew:OnClickBtnOk()
	local formatData = self._formatsData[self._index]
	if not formatData then
		return
	end

	local haveItem		= formatData.itemId ~= nil
	local allHaveItem	= self:CheckAllSelect()

	if not haveItem or not allHaveItem then

		--[[
                    -- 6.11
                    -- 心愿礼包修改了逻辑，点击下一个按钮时，不管是否选择了道具，都支持切换到下一个展示框。处于最后一个时，切换到第一个
                    return
                    ]]

		self:ReSetSelectItemIndex()
		self:RefreshTopChange()
		self:RefreshBottom()
	else
		if self._wndType == UICumSelectNew.NORMAl then
			if self._callFunc then
				self._callFunc(self._giftItemData)
			else
				self:OnActivityCustomGiftReq()
			end
		else
            self:OnPopupGiftReq()
		end
		self:WndClose()
	end
end

function UICumSelectNew:OnDrawCellCustomItem(list, item, itemData, itemPos)
	local itemNumTrans	= self:FindWndTrans(item, "itemNum")
	local itemRoot		= self:FindWndTrans(item, "itemRoot")
	--local itemNameTrans = self:FindWndTrans(item,"itemName")

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
	baseClass:SetCommonReward(itemType, itemId, itemNum)
	--self:SetWndText(itemNumTrans, LUtil.NumberCoversion(itemNum))
	baseClass:ShowGouImg(isSelect or false)


	--self:SetIconClickScale(itemRoot,true)
	self:SetWndClick(itemRoot, function()
		if isSelect then return; end
		self:OnClickCustomItem(itemNum, itemId, itemType, instanceID)
	end)

	self:SetWndLongClick(itemRoot, function()
		gModelGeneral:ShowCommonItemTipWnd(itemData)
	end, 0.2,true)

	baseClass:DoApply()

	--local name = ""
	--if itemNameTrans and haveItem then
	--	name = gModelGeneral:GetCommonItemColorNameNoNum(itemData)
	--end
	--self:SetWndText(itemNameTrans,name)
end

function UICumSelectNew:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...) self:OnActivityPageResp(...) end)
	--gModelActivity:OnActivityPageReq(self._sid)

	self:WndNetMsgRecv(LProtoIds.ActivityCustomGiftResp, function(...) self:OnActivityCustomGiftResp(...) end)
end


function UICumSelectNew:OnActivityCustomGiftResp(pb)

end

function UICumSelectNew:RefreshItemListData()
	local itemData		= self._giftData
	local marketData   	= itemData.marketData or itemData.MarketData
	if not marketData then return end

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

function UICumSelectNew:ClearUIDrawCellList()
	if not self._uiCommonList then return end

	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil
end

function UICumSelectNew:ShowNormalContent()
	self:InitData()
	self:InitMsg()
	self:Refresh()
	self:SetWndText(self.mBottomTitleTxt, ccClientText(18606))
	self:SetWndText(self.mNoCustomItemTxt, ccClientText(18604))
end


function UICumSelectNew:ReSetSelectItemIndex()
	local oldIndex = self._index
	if not oldIndex then return end
	self._index = 1
	if not self._giftItemData then
		LogError("self._giftItemData is a nil")
		return
	end
	local len = #self._giftItemData
	local newIndex = oldIndex + 1
	if newIndex > len then
		newIndex = 1
	end
	self._index = newIndex

--[[	for k,v in ipairs(self._giftItemData) do
		if v.itemId == nil then
			self._index = k
			return
		end
	end]]
end

function UICumSelectNew:RefreshTopChange()
	self:RefreshItemList()
	self:RefreshBtnList()
end

function UICumSelectNew:InitEvent()
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UICumSelectNew:RefreshData()
	if not self._giftData then
		LogError("self._giftData is a nil")
		return
	end

	self:RefreshItemListData()
end

function UICumSelectNew:FormatRewardStr()
    local strList = {}
    for k,v in ipairs(self._giftItemData) do
        local str = string.replace(ITEM_CFG_FORMAT, v.itemType, v.itemId, v.itemNum)
        table.insert(strList,str)
    end

    local rewardStr = table.concat(strList,',')
    return rewardStr
end

function UICumSelectNew:GetShiftCustomGiftData(customList)
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

function UICumSelectNew:ClearPoolCommonIconList()
	if not self._uiCommonPoolList then return end
	self:ClearCommonIconList(self._uiCommonPoolList)
	self._uiCommonPoolList = nil
end

function UICumSelectNew:RefreshBtnList()
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
		self:OnClickBtnOk()
	end)
	if(self._giftItemData and #self._giftItemData == 1 and not allHaveItem)then
		self:SetWndButtonText(self.mOkBtn, ccClientText(10102))
	end
	self:SetWndButtonGray(self.mOkBtn,self._giftItemData and #self._giftItemData == 1 and not allHaveItem)
end

--#####################################################################################################################
--## Bottom ###########################################################################################################
--#####################################################################################################################
function UICumSelectNew:RefreshBottom()
	if not self._giftItemData then
		LogError("self._giftItemData is a nil")
		return
	end

	local giftData = self._giftItemData[self._index]
	if not giftData then
		LogError(string.format("self._giftItemData[self._index] is not find, self._index = %s",self._index))
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
------------------------------------------------------------------
return UICumSelectNew


