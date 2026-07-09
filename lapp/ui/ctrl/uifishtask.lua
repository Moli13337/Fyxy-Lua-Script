---
--- Created by wzz.
--- DateTime: 2024/7/12 17:36:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishTask:LWnd
local UIFishTask = LxWndClass("UIFishTask", LWnd)

local TaskState = gModelFish.TaskState
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishTask:UIFishTask()
	local ref = gModelFish:GetConfigRef()

	self._refreshCostItemData = LUtil.GetRefItemData(ref.fishingTaskRefresh)
	self._resetCostItemData = LUtil.GetRefItemData(ref.fishingTaskResetting)
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishTask:OnWndClose()
	LWnd.OnWndClose(self)

	FireEvent(EventNames.FISH_TASK_RETURN)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishTask:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishTask:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- true 表示能否重置所有任务
function UIFishTask:CanReSetAll(showTips)
	return gModelFish:CanReSetAll(showTips)
end

-- 初始化item列表
function UIFishTask:InitItemList(root, itemList)
	local instanceID = root:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {}
		local uiList = UIIconEasyList:New()
		uiList:Create(self, root)
		uiList:SetShowNum(true)
		uiList:SetIconParentPath("itemRoot")
		-- uiList:SetShowExtraNum(true, "itemNum")

		itemCache.uiList = uiList
		self:SetComponentCache(instanceID, itemCache)
	end
	itemCache.uiList:RefreshList(itemList)
end

-- 顶部资产
function UIFishTask:RefreshTopAsset()
	local assetIdList = { self._refreshCostItemData.itemId, self._resetCostItemData.itemId }
	self:SetTopAssetList(self.mTopAsset, assetIdList)
end

-- 初始界面化文本
function UIFishTask:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(44249))
	self:SetWndText(self.mTxtCloseTips, ccClientText(41037))

	self._sliderSize = self.mSlider.sizeDelta
end

-- 点击领取
function UIFishTask:OnClickBtnReceive(id, refId)
	gModelFish:FishingOrderReceiveReq(id)
end

-- 点击刷新
function UIFishTask:OnClickBtnRefresh(id, refId)

	local fishTaskRef = gModelFish:GetFishTaskRef(refId)
	local config = gModelFish:GetConfigRef()
	if fishTaskRef.quality >= config.fishingTaskQuality then
		local ref = gModelItem:GetQualityRef(fishTaskRef.quality)
		local name = ccLngText(ref.name)
		name = gModelItem:FormatQualityStr(name, fishTaskRef.quality)

		gModelGeneral:OpenUIOrdinTips({
			refId = 450002,
			func = function()
				gModelFish:RefreshFishingOrderReq(id, 0)
			end,
			para = { name }
		})
		return
	end

	gModelFish:RefreshFishingOrderReq(id, 0)
end

-- 刷新列表
function UIFishTask:RefreshList()
	local dataList = {}
	for k, v in ipairs(gModelFish:GetTaskList(true)) do
		dataList[k] = v
	end
	self._uiDataList = dataList

	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList
		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList:ResetList(dataList)
		self._uiList:DrawAllItems()
	end
end

-- 点击重置按钮
function UIFishTask:OnClickBtnReset()
	if not self:CanReSetAll(true) then
		return
	end
	gModelFish:RefreshFishingOrderReq(0, 1)
end

-- 刷新界面
function UIFishTask:Refresh()
	self:RefreshList()
	self:RefreshTopAsset()

	local baseInfo = gModelFish:GetFishTaskBaseInfo()

	local leftTime = baseInfo.remainResetCount
	self:SetWndText(self.mTxtTimes, ccClientText(44250, leftTime))

	local vigor = tonumber(baseInfo.usedEnergy)
	local vigorMax = math.max(1, tonumber(baseInfo.maxEnergy))

	self.mSlider.sizeDelta = Vector2(math.min(self._sliderSize.x, vigor / vigorMax * self._sliderSize.x),
		self._sliderSize.y)
	self:SetWndText(self.mSliderVal, vigor .. "/" .. vigorMax)
	self:SetWndText(self.mTxtReset, ccClientText(44251, vigorMax))

	local iconPath = gModelItem:GetItemImgByRefId(self._resetCostItemData.itemId)
	self:SetWndEasyImage(self.mCostIcon, iconPath)
	self:SetWndText(self.mCostNum, ccClientText(44256, self._resetCostItemData.itemNum))
	local canReSet = self:CanReSetAll(false)
	self:SetWndButtonGray(self.mBtnReset, not canReSet)
end

-- 初始事件
function UIFishTask:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnReset, function() self:OnClickBtnReset() end)

	self:WndEventRecv(EventNames.FISH_BASE_INFO, function(...) self:Refresh(...) end)
	self:WndEventRecv(EventNames.FISH_TASK_RETURN, function(...) self:Refresh(...) end)
	self:WndEventRecv(EventNames.FISH_REFRESH_TASK, function(...) self:OnRefreshTask(...) end)
	self:WndEventRecv(EventNames.On_Item_Change, function(...) self:RefreshTopAsset(...) end)
end

-- 刷新任务
function UIFishTask:OnRefreshTask(param)
	local id = param.id
	local order = param.order

	local index = 1
	for k, v in ipairs(self._uiDataList) do
		if v.id == id then
			index = k
			self._uiDataList[k] = order
			break
		end
	end

	self._uiList:RefreshOnlyData(self._uiDataList)
	self._uiList:DrawItemByIndex(index)
end

-- 绘制列表item项
function UIFishTask:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			titleBg    = CS.FindTrans(item, "AniRoot/titleBg"),
			txtTitle   = CS.FindTrans(item, "AniRoot/TxtTitle"),
			txtValue   = CS.FindTrans(item, "AniRoot/TxtValue"),
			itemList   = CS.FindTrans(item, "AniRoot/ItemList"),
			btnReceive = CS.FindTrans(item, "AniRoot/BtnReceive"),
			btnRefresh = CS.FindTrans(item, "AniRoot/BtnRefresh"),
			costIcon   = CS.FindTrans(item, "AniRoot/BtnRefresh/Cost/1/CostIcon"),
			costNum    = CS.FindTrans(item, "AniRoot/BtnRefresh/Cost/CostNum"),
			hadGet     = CS.FindTrans(item, "AniRoot/HadGet"),
			slider     = CS.FindTrans(item, "AniRoot/SliderBg/Slider"),
		}
		self:SetComponentCache(instanceID, itemCache)

		itemCache.sliderSize = itemCache.slider.sizeDelta

		self:SetWndButtonText(itemCache.btnReceive, ccClientText(44254))
	end

	local obj = itemData -- FishingOrderObj
	local refId = obj.refId
	local taskRef = gModelQuest:GetTaskConfig(refId)
	local fishTaskRef = gModelFish:GetFishTaskRef(refId)

	self:SetWndText(itemCache.txtTitle, ccLngText(taskRef.description))
	self:SetWndEasyImage(itemCache.titleBg, "public_cell_17_" .. fishTaskRef.quality)

	local itemDataList = LUtil.GetRefItemDataList(taskRef.reward)
	self:InitItemList(itemCache.itemList, itemDataList)

	local num = tonumber(obj.schedule)
	local maxNum = tonumber(obj.goal)

	local strValue = ""
	if num >= maxNum then
		strValue = ccClientText(44253, num, maxNum)
	else
		strValue = ccClientText(44252, num, maxNum)
	end
	self:SetWndText(itemCache.txtValue, strValue)

	itemCache.slider.sizeDelta = Vector2(num / maxNum * itemCache.sliderSize.x, itemCache.sliderSize.y)


	local state = obj.state
	local showhadGet = state == TaskState.Received
	local showReceive = state == TaskState.Completed
	local showRefresh = not showhadGet and not showReceive

	CS.ShowObject(itemCache.hadGet, showhadGet)
	CS.ShowObject(itemCache.btnReceive, showReceive)
	CS.ShowObject(itemCache.btnRefresh, showRefresh)

	self:ShowBtnEff(itemCache.btnReceive, instanceID, showReceive, "fx_shouchong_anniu_zhong")

	if showReceive then
		self:SetWndClick(itemCache.btnReceive, function()
			self:OnClickBtnReceive(obj.id, refId)
		end)
	end

	if showRefresh then
		local iconPath = gModelItem:GetItemImgByRefId(self._refreshCostItemData.itemId)
		self:SetWndEasyImage(itemCache.costIcon, iconPath)
		self:SetWndText(itemCache.costNum, ccClientText(44255, self._refreshCostItemData.itemNum))
		self:SetWndClick(itemCache.btnRefresh, function()
			self:OnClickBtnRefresh(obj.id, refId)
		end)
	end
end

------------------------------------------------------------------
return UIFishTask