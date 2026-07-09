---
--- Created by Administrator.
--- DateTime: 2021/1/13 16:32:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFlandSurplus:LWnd
local UIFlandSurplus = LxWndClass("UIFlandSurplus", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFlandSurplus:UIFlandSurplus()
	---@type table<number,table>
	self._uiItemList = nil

end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFlandSurplus:OnWndClose()
	if self._uiItemList then
		self._uiItemList:OnWndClose()
	end
	self._uiItemList = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFlandSurplus:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFlandSurplus:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:SetItemList()

	self:SetWndText(self.mDescText, ccClientText(18727))
	self:SetWndText(self.mTitleText, ccClientText(18715))
	self:SetWndText(self.mItemTitleText, ccClientText(18725))
	self:SetWndText(self.mNumTitleText, ccClientText(18726))
end


--####################################################################################################################
--### Server #########################################################################################################
--####################################################################################################################
function UIFlandSurplus:OnActivityResp(pb,ret)
	if self._sid ~= pb.sid then return end
	self:SetItemList()
end

function UIFlandSurplus:ResetActivePageData(pb)
	local pageData
	for i, v in ipairs(pb.pages) do
		if v.pageId == self._pageId then
			local page= gModelActivity:GenerateActivePageDataFromPb(v)
			if page then
				pageData = page
				break
			end
		end
	end

	if not pageData then return end

	self._activityPageData = {}
	local moreInfo = JSON.decode(pageData.moreInfo)
	self._activityPageData = {
		nowSuperGift 	= moreInfo.nowSuperGift,	--当前大奖
		oldSuperGift 	= moreInfo.oldSuperGift,	--历史大奖
		roundTime 		= tonumber(moreInfo.roundTime),	--当前第几轮
		roundRecord 	= moreInfo.roundRecord,		--当前轮记录
		nowDropNum 		= moreInfo.nowDropNum,		--当前轮抽取次数
	}

	self._activityDrawData = {}
	self._activityBigDrawData = {}
	for k,v in ipairs(pageData.entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		if not entryCfg then
			return
		end

		moreInfo 			= JSON.decode(v.moreInfo)
		local type			= moreInfo.type
		local extractMaxNum = string.split(moreInfo.extractMaxNum, '=')
		local entryId		= v.entryId

		local reward		= entryCfg.reward
		if not string.isempty(reward) then
			local data = {
				entryId = entryId,
				items	= LxDataHelper.ParseItem(entryCfg.reward)[1],
				sort	= entryCfg.sort,
				type	= type,
				needRound = extractMaxNum[1],
				drawNum   = extractMaxNum[2],
			}

			if type == self._drawType.COMMON then
				table.insert(self._activityDrawData, data)
			else
				table.insert(self._activityBigDrawData, data)
			end
		end
	end
end

function UIFlandSurplus:GetDrawCellItemsData()
	local roundRecordData	= {}
	local roundRecord 		= self._activityPageData.roundRecord
	local roundRecordList 	= string.split(roundRecord, '|')
	local data
	local entryId
	for k,v in ipairs(roundRecordList) do
		data 		= string.split(v, ',')
		entryId 	= tonumber(data[2])
		roundRecordData[entryId] = true
	end

	local tempItemData = {}
	local item
	local itemId
	local getNum
	local allNum
	local resultData
	local isGet
	local itemCount
	local itemKey
	--普通翻牌
	for k,v in ipairs(self._activityDrawData) do
		entryId = v.entryId
		isGet = roundRecordData[entryId] or false
		item = v.items
		if item then
			itemId = item.itemId
			itemCount = item.itemNum
			itemKey = tostring(itemId).."|"..tostring(itemCount)
			resultData = tempItemData[itemKey]
			if not resultData then
				resultData = {
					entryId = entryId,
					items = item,
					getNum = 0,
					allNum = 1,
					residueNum = 1,
					qualityId = gModelGeneral:GetCommonItemQualityRef(item)
				}
				tempItemData[itemKey] = resultData
			else
				allNum = resultData.allNum
				resultData.allNum = allNum + 1
			end

			if isGet then
				getNum = resultData.getNum
				resultData.getNum = getNum + 1
			end
		end
	end

	--大奖翻牌
	local curSelectEntryId = self._activityPageData.nowSuperGift
	local haveSelectBigDraw = curSelectEntryId ~= nil and curSelectEntryId ~= "" and curSelectEntryId ~= 0
	if haveSelectBigDraw then
		for k,v in ipairs(self._activityBigDrawData) do
			entryId = v.entryId
			isGet = roundRecordData[entryId] or false
			if entryId == curSelectEntryId then
				item	= v.items
				itemId = item.itemId
				itemCount = item.itemNum
				itemKey = tostring(itemId).."|"..tostring(itemCount)
				resultData = tempItemData[itemKey]
				if not resultData then
					resultData = {
						entryId = entryId,
						items = item,
						getNum = 0,
						allNum = 1,
						residueNum = 1,
						qualityId = gModelGeneral:GetCommonItemQualityRef(item)
					}
					tempItemData[itemKey] = resultData
				else
					allNum = resultData.allNum
					resultData.allNum = allNum + 1
				end

				if isGet then
					getNum = resultData.getNum
					resultData.getNum = getNum + 1
				end
				break
			end
		end
	end

	local resultItemData = {}
	for k,v in pairs(tempItemData) do
		table.insert(resultItemData, v)
	end

	for k,v in ipairs(resultItemData) do
		resultItemData[k].residueNum = v.allNum - v.getNum
	end

	table.sort(resultItemData, function(item1, item2)
		if item1.residueNum ~= item2.residueNum and (item1.residueNum <= 0 or item2.residueNum <= 0) then
			return item2.residueNum <= 0
		end

		if item1.qualityId ~= item2.qualityId then
			return item1.qualityId > item2.qualityId
		end

		return item1.entryId < item2.entryId
	end)

	return resultItemData
end

function UIFlandSurplus:InitData()
	self._pageId 	= 3 			--翻牌抽奖id
	self._func 		= self:GetWndArg("func")
	self._sid 		= self:GetWndArg("sid")
	self._activityPageData = self:GetWndArg("pageData")
	self._activityDrawData = self:GetWndArg("drawData")
	self._activityBigDrawData = self:GetWndArg("bigDrawData")

	self._drawType = {
		COMMON = 1,	--常驻奖励
		BIG  = 2,	--大奖
	}
end

function UIFlandSurplus:InitEvent()
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)
	self:SetWndClick(self.mMaskBg, function() self:WndClose() end)
end

function UIFlandSurplus:SetItemList()
	if table.isempty(self._activityPageData)
			or table.isempty(self._activityDrawData)
			or table.isempty(self._activityBigDrawData) then
		return
	end

	local allItemsList = self:GetDrawCellItemsData()
	if not allItemsList then
		return
	end

	local uiList	 = self._uiItemList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self, self.mItemList)
		uiList:EnableScroll(true, false)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawCellItem(...)
		end)
		self._uiItemList = uiList
	end

	uiList:RemoveAll()
	for k,v in pairs(allItemsList) do
		uiList:AddData(k,v)
	end

	uiList:RefreshList()
end

function UIFlandSurplus:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	gModelActivity:OnActivityPageReq(self._sid)
end

function UIFlandSurplus:OnDrawCellItem(list, item, itemdata, itempos)
	local itemText = self:FindWndTrans(item, "ItemText")
	local numText  = self:FindWndTrans(item, "NumText")

	local items = itemdata.items
	local itemName = gModelGeneral:GetCommonItemColorName(items, "*")
	local maxNum = itemdata.allNum
	local itemNum =itemdata.residueNum

	self:SetWndText(itemText, itemName)

	local numStr = string.replace(ccClientText(18721), itemNum, maxNum)
	if itemNum <= 0 then
		numStr = LUtil.FormatColorStr(numStr,"red")
	end

	self:SetWndText(numText, numStr)
end

function UIFlandSurplus:InitMsg()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP,function () self:WndClose() end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)

	gModelActivity:ReqActivityConfigData(self._sid)
end


function UIFlandSurplus:OnActivityPageResp(pb,ret)
	if self._sid ~= pb.sid then return end

	self:ResetActivePageData(pb)
	self:SetItemList()
end


------------------------------------------------------------------
return UIFlandSurplus


