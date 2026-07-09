---
--- Created by BY.
--- DateTime: 2023/10/12 18:29:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActPrizeSlotSelectPop:LWnd
local UIActPrizeSlotSelectPop = LxWndClass("UIActPrizeSlotSelectPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActPrizeSlotSelectPop:UIActPrizeSlotSelectPop()
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActPrizeSlotSelectPop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActPrizeSlotSelectPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActPrizeSlotSelectPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMessage()
	self:InitCommon()
end

function UIActPrizeSlotSelectPop:CreateCommonIcon(data)
	local instanceID = data.instanceID
	local trans = data.trans
	local itemType,itemId,itemNum = data.itemType, data.itemId, data.itemNum
	local baseClass = self._uiCommonList[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonList[instanceID] = baseClass
		baseClass:Create(trans)
	end
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	local showNum = itemNum > 0
	baseClass:EnableShowNum(showNum)
	baseClass:DoApply()
end
function UIActPrizeSlotSelectPop:RefreshPool()
	local _itemData = self._itemData
	local _poolList = self._poolList or {}
	if not _itemData then return end
	local entryId = _itemData.entryId
	local _pools = _poolList[entryId]

	CS.ShowObject(self.mNoCustomItemTxt,#_pools <= 0)

	table.sort(_pools,function (a,b)
		local aentryCfg = a.entryCfg
		local aentry = a.entry
		local aplayerLimitNum = aentryCfg.playerLimitNum
		local anetData =JSON.decode(aentry.moreInfo)
		local ahasBuyNum = anetData["quantitative"] or 0
		local aStro = 9999
		if aplayerLimitNum > 0 then
			aStro = 99999
			if aplayerLimitNum - ahasBuyNum > 0 then
				aStro = aplayerLimitNum
			end
		end
		local bentryCfg = b.entryCfg
		local bentry = b.entry
		local bplayerLimitNum = bentryCfg.playerLimitNum
		local bnetData =JSON.decode(bentry.moreInfo)
		local bhasBuyNum = bnetData["quantitative"] or 0
		local bStro = 9999
		if bplayerLimitNum > 0 then
			bStro = 99999
			if bplayerLimitNum - bhasBuyNum > 0 then
				bStro = bplayerLimitNum
			end
		end
		if aStro ~= bStro then
			return aStro < bStro
		end
		return a.entryId < b.entryId
	end)
	local _uiPoolList = self._uiPoolList
	if _uiPoolList then
		_uiPoolList:RefreshList(_pools)
		_uiPoolList:DrawAllItems()
	else
		_uiPoolList	 = self:GetUIScroll("mPoolSuper")
		_uiPoolList:Create(self.mPoolSuper, _pools, function(...) self:OnDrawCellCustomItem(...) end,UIItemList.SUPER_GRID)
		_uiPoolList:EnableScroll(true, false)
		self._uiPoolList = _uiPoolList
	end
end
function UIActPrizeSlotSelectPop:CheckIsAllSelect()
	local list = self._list or {}
	for i, v in ipairs(list) do
		local selectEntryId = self:GetSelectEntryId(v)
		if selectEntryId == 0 then
			return v
		end
	end
	return nil
end

function UIActPrizeSlotSelectPop:OnDrawCellItem(list, item, itemData, itemPos)
	local itemRoot = self:FindWndTrans(item, "ItemRoot/Root")
	local selectImg = self:FindWndTrans(item, "ItemRoot/SelectImg")
	local itemName = self:FindWndTrans(item,"ItemRoot/ItemName")

	local _poolList = self._poolList or {}
	local _itemData = self._itemData or {}
	local _selEntryId = _itemData.entryId

	local InstanceID = item:GetInstanceID()
	local entryId = itemData.entryId

	local selectEntryId = self:GetSelectEntryId(itemData)

	CS.ShowObject(selectImg,_selEntryId == entryId)
	if selectEntryId > 0 then
		self._selectEntryId = selectEntryId
		local _poolEntryCfg = nil
		local _pools = _poolList[entryId]
		for i, v in ipairs(_pools) do
			if selectEntryId == v.entryId then
				_poolEntryCfg = v.entryCfg
				break
			end
		end
		if _poolEntryCfg then
			local reward = LxDataHelper.ParseItem_3(_poolEntryCfg.reward)
			reward.trans = itemRoot
			reward.instanceID = InstanceID
			self:CreateCommonIcon(reward)
			self:SetWndLongClick(itemRoot, function()
				gModelGeneral:ShowCommonItemTipWnd(reward)
			end,0.5,false)
			local nameStr = gModelGeneral:GetCommonItemName(reward)
            if gLGameLanguage:IsKoreaRegion() or gLGameLanguage:IsUSARegion() then
                nameStr = ""
            end

			self:SetWndText(itemName,nameStr)
		end
	end

	self:SetWndClick(item, function() self:OnClickSel(itemData) end)
end

function UIActPrizeSlotSelectPop:OnTryTcpReconnect()
	self:WndClose()
end
function UIActPrizeSlotSelectPop:OnDrawCellCustomItem(list, item, itemData, itemPos)
	local limitInfo = self:FindWndTrans(item,"LimitInfo")
	local itemRoot = self:FindWndTrans(item,"ItemRoot")
	local icon = self:FindWndTrans(itemRoot,"Icon")
	local selImg = self:FindWndTrans(itemRoot,"SelImg")
	local itemName = self:FindWndTrans(item,"ItemName")
	local mask = self:FindWndTrans(itemRoot,"Mask")
	local buyMask = self:FindWndTrans(itemRoot,"BuyMask")

	local _selEntryId = self._selectEntryId

	local InstanceID = item:GetInstanceID()
	local entryId = itemData.entryId
	local entryCfg = itemData.entryCfg
	local isSel = entryId == _selEntryId
	local entry = itemData.entry
	local playerLimitNum = entryCfg.playerLimitNum
	local netData =JSON.decode(entry.moreInfo)
	local hasBuyNum = netData["quantitative"] or 0

	CS.ShowObject(limitInfo,playerLimitNum > 0)
	CS.ShowObject(selImg,isSel)
	CS.ShowObject(mask,isSel)
	CS.ShowObject(buyMask,playerLimitNum > 0 and playerLimitNum - hasBuyNum <= 0)

	if playerLimitNum > 0 then
		local num = playerLimitNum - hasBuyNum
		local numStr = num
		if num <= 0 then
			numStr = LUtil.FormatColorStr(numStr,"red")
		end

		self:SetWndText(limitInfo,string.replace(ccClientText(27658),numStr))
	end
	local reward = LxDataHelper.ParseItem_3(entryCfg.reward)
	local nameStr = gModelGeneral:GetCommonItemName(reward)
	if gLGameLanguage:IsKoreaRegion() or gLGameLanguage:IsUSARegion() then
		nameStr = ""
	end

	reward.trans = icon
	reward.instanceID = InstanceID
	self:CreateCommonIcon(reward)
	self:SetWndText(itemName,nameStr)
	self:SetWndClick(itemRoot,function ()
		self:OnClickPoolItem(itemData)
	end)
	self:SetWndLongClick(itemRoot, function()
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end,0.5,false)
end
function UIActPrizeSlotSelectPop:ResetData(pb)
	local pages = self.pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		pages[v.pageId] = page
	end
	self.pages = pages
	self:RefreshData()
end
function UIActPrizeSlotSelectPop:OnClickPoolItem(itemData)
	local customEntryId = itemData.entryId
	local _itemData = self._itemData
	if not _itemData then
		GF.ShowMessage(string.replace(ccClientText(26804),self._guaRewardTitle or ccClientText(23218)))
		return
	end
	gModelActivity:OnActivitySpecialOpReq(self._sid,_itemData.pageId,_itemData.entryId,nil, tostring(customEntryId), self._optionalEnum)
end

function UIActPrizeSlotSelectPop:InitEvent()
	self:SetWndClick(self.mBgImage,function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnOk, function() self:OnClickOk() end, LSoundConst.CLICK_CLOSE_COMMON)
end
function UIActPrizeSlotSelectPop:RefreshData()
	self:InitGridPoolInfo()
	self:RefreshSel()

	local _entryId = self._entryId
	local list = self._list or {}
	if _entryId then
		self._entryId = nil
		if _entryId > 0 then
			for i, v in ipairs(list) do
				if _entryId == v.entryId then
					self:OnClickSel(v)
					break
				end
			end
		else
			self:OnClickSel(list[1])
		end
		return
	end

	self:RefreshPool()
end
function UIActPrizeSlotSelectPop:InitGridPoolInfo()
	local _pages = self.pages
	if not _pages then return end
	local _poolPage = _pages[self._turnPoolEnum]
	local _poolEntrys = _poolPage.entry
	if not _poolPage then return end

	local _poolList = self._poolList
	if not _poolList then
		_poolList = {}
		for i, v in ipairs(_poolEntrys) do
			local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
			local moreInfo = string.split(entryCfg.moreInfo,"|")
			local id = tonumber(moreInfo[1])
			local list = _poolList[id] or {}
			local data = {
				entryCfg = entryCfg,
				entry = v,
				entryId = v.entryId,
				rare = tonumber(moreInfo[2])
			}
			table.insert(list,data)
			_poolList[id] = list
		end
		for i, v in pairs(_poolList) do
			local list = v
			table.sort(list,function (a,b)
				return a.entryId < b.entryId
			end)
		end
		self._poolList = _poolList							--奖池列表
	end
end
function UIActPrizeSlotSelectPop:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function (...) self:RefreshData() end)
end

function UIActPrizeSlotSelectPop:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	if not activityData then return end
	local data = activityData.config

	local guaRewardBgImage,guaRewardTitle
	= data.guaRewardBgImage,data.guaRewardTitle
	self._guaRewardTitle = guaRewardTitle

	if LxUiHelper.IsImgPathValid(guaRewardBgImage) then
		self:SetWndEasyImage(self.mBgImage,guaRewardBgImage)
	end
	if not string.isempty(guaRewardTitle) then
		self:SetWndText(self.mLblBiaoti,guaRewardTitle)
		self._guaRewardTitle = guaRewardTitle
	end
	self:RefreshData()
end
function UIActPrizeSlotSelectPop:InitData()
	self._modelEnumList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = {ModelActivity.SWEET_COUNTRY_7,ModelActivity.SWEET_COUNTRY_8},
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_96] = {ModelActivity.MOTIF_ACTIVITY_LOTTERY_1,ModelActivity.MOTIF_ACTIVITY_LOTTERY_2},
	}
	self._modelSelectEnum = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = ModelActivity.SWEETS_COUNTRY_OPTIONAL_AWARD,
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_96] = ModelActivity.DROP_REWARD_OPTIONAL_AWARD,
	}
	self:SetWndText(self.mLblBiaoti, ccClientText(23218))
	self:SetWndText(self.mLblBiaoti2, ccClientText(23231))
	self:SetWndText(self.mNoCustomItemTxt, ccClientText(18604))
	self:SetWndButtonText(self.mBtnOk,ccClientText(26800))
end
function UIActPrizeSlotSelectPop:InitCommon()
	self._sid 		= self:GetWndArg("sid")
	self._entryId		= self:GetWndArg("entryId") or 0
	local pages 	= self:GetWndArg("pages")
	local modelId = gModelActivity:GetActivityModeIdBySid(self._sid)
	local enums = self._modelEnumList[modelId]
	self.pages = pages
	self._turnTableEnum = enums[1]										--奖槽表
	self._turnPoolEnum = enums[2]										--奖池表
	self._optionalEnum = self._modelSelectEnum[modelId]					--自选奖励奖励条目id

	self:OnActivityConfigData()
end
function UIActPrizeSlotSelectPop:OnClickOk()
	local  itemData = self:CheckIsAllSelect()
	if itemData then
		self:OnClickSel(itemData)
		return
	end
	self:WndClose()
end
function UIActPrizeSlotSelectPop:GetSelectEntryId(itemData)
	local selectEntryId = 0
	local entryMoreInfo = JSON.decode(itemData.moreInfo)
	for a,b in pairs(entryMoreInfo) do
		selectEntryId = tonumber(b)
		break
	end
	return selectEntryId
end

function UIActPrizeSlotSelectPop:OnClickSel(itemData)
	self._itemData = itemData
	self:RefreshSel()
	self:RefreshPool()
end
function UIActPrizeSlotSelectPop:RefreshSel()
	local pages = self.pages
	local _turnTableEnum = self._turnTableEnum
	local sid = self._sid
	if not sid or not _turnTableEnum or not pages then return end
	local pageEntry = pages[_turnTableEnum]
	if not pageEntry then return end

	local _keyList = self._keyList
	local keyList ={}
	local list = {}
	for k,v in pairs(pageEntry.entry) do
		if (not _keyList or _keyList[v.entryId]) then
			local entryCfg = gModelActivity:GetWebActivityEntryData(sid,v.pageId,v.entryId)
			local moreInfo = string.split(entryCfg.moreInfo,"|")
			local isSel = tonumber(moreInfo[4]) > 0
			if isSel then
				keyList[v.entryId] = true
				local data = v
				data.entryCfg = entryCfg
				table.insert(list,data)
			end
		end
	end
	self._keyList = keyList
	self._list = list

	local uiList = self._uiList
	if not uiList then
		uiList = self:GetUIScroll("mItemScroll")
		uiList:Create(self.mItemScroll,list,function (...) self:OnDrawCellItem(...)  end)
		uiList:EnableScroll(#list > 3, true)
		self._uiList = uiList
	else
		uiList:RefreshList(list)
	end
end
------------------------------------------------------------------
return UIActPrizeSlotSelectPop


