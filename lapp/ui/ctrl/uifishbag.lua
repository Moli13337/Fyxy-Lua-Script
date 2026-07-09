---
--- Created by wzz.
--- DateTime: 2024/7/10 22:31:43
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishBag:LWnd
local UIFishBag = LxWndClass("UIFishBag", LWnd)
------------------------------------------------------------------


local TabDataList = {
	[1] = { tabName = ccClientText(44232), title = ccClientText(44236), tips = ccClientText(44234), itemType = gModelItem.TTEM_TYPE_FISH_BAIT },
	[2] = { tabName = ccClientText(44233), title = ccClientText(44237), tips = ccClientText(44235), itemType = gModelItem.TTEM_TYPE_FISH_ROD },
}

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishBag:UIFishBag()
	self._baitRefList = gModelFish:GetFishBaitRefList()
	self._rodRefList = gModelFish:GetFishRodRefList()


	self._initBaitRefId = gModelFish:GetInitBaitRefId()
	self._initRodRefId = gModelFish:GetInitRodRefId()

	self._curUseBaitRefId = gModelFish:GetCurUseFishBait()
	self._curUseRodRefId = gModelFish:GetCurUseFishRod()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishBag:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishBag:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishBag:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitTimer()
	self:InitTexts()
	self:InitEvents()
	self:InitTab()
	self:DealWithDataList()
	self:Refresh()
	self:Update()
end

-- 初始时间
function UIFishBag:InitTimer()
	local timePara = {
		key = 1,
		loopcnt = -1,
		interval = 1,
		timescale = false,
		callOnStart = true,
		func = function()
			self:Update()
		end
	}
	self:TimerStartImpl(timePara)
end

-- 刷新时间
function UIFishBag:RefreshTime()
	local ref = self._curSelectRef
	if not ref then
		return
	end

	local strNum, showImgTime, showUse = self:GetNumData(ref.refId)
	self:SetWndText(self.mTxtNum, strNum)
	CS.ShowObject(self.mImgTime, showImgTime)
end

-- 获取数量相关数据
function UIFishBag:GetNumData(refId)
	local strNum = ""
	local showImgTime = false
	local showUse = false
	local showLock = false
	if self._isFishBait then
		if refId == self._initBaitRefId then
			strNum = ccClientText(44296, ccClientText(44241))
			showUse = true
		else
			local num = gModelItem:GetNumByRefId(refId)
			strNum = ccClientText(44296, num)
			showUse = num > 0
			showLock = num <= 0
		end
	else
		if refId == self._initRodRefId then
			strNum = ccClientText(44293)
			showImgTime = true
			showUse = true
		else
			local serData = gModelItem:GetItemServerDataByRefId(refId)
			if not serData then
				strNum = ccClientText(44294)
				showLock = true
			else
				showImgTime = true
				local data = gModelFish:GetFishItemAttr(refId)
				if data.time <= 0 then
					-- 无期限
					strNum = ccClientText(44293)
					showUse = true
				else
					local curTime = GetTimestamp()
					local createTime = serData:GetCreateTime() * 0.001 -- 其实是结束时间
					local leftTime = createTime - curTime
					if leftTime <= 0 then
						-- 过期
						strNum = ccClientText(44295)
						showLock = true
					else
						strNum = LUtil.FormatTimespanCn(math.ceil(leftTime))
						showUse = true
					end
				end
			end
		end
	end

	if showUse then
		showUse = refId ~= self._curUseBaitRefId and refId ~= self._curUseRodRefId
	end
	return strNum, showImgTime, showUse, showLock
end

-- 点击使用按钮
function UIFishBag:OnClickBtnUse()
	local type = self._isFishBait and 1 or 0
	gModelFish:SwitchFishBaitReq(type, self._curSelectRef.refId)
end

-- 初始tab
function UIFishBag:InitTab()
	local uilist = self:GetUIScroll("mTabScroll")
	uilist:Create(self.mTabScroll, TabDataList, function(...)
		self:OnDrawTabItem(...)
	end)
end

-- 刷新界面顶部
function UIFishBag:RefreshTop()
	local ref = self._curSelectRef
	if not ref then
		return
	end
	local refId = ref.refId
	local strName = gModelItem:GetItemNameRichText(refId)
	self:SetWndText(self.mTxtName, strName)
	self:CreateCommonIconImpl(self.mItemIcon, { itemType = LItemTypeConst.TYPE_ITEM, itemId = refId })

	self:SetWndText(self.mTxtDesc1, ccClientText(44238))
	self:SetWndText(self.mTxtDesc, ccLngText(ref.description))

	local strJump = ""
	local itemRef = gModelItem:GetRefByRefId(refId)
	local jump = itemRef.jump
	if jump ~= "" then
		for i, v in ipairs(string.split(jump, ",")) do
			local list = string.split(v, "=")
			local jumpRefId = tonumber(list[1])
			local jumpRef = GameTable.SourceJumpRef[jumpRefId]
			if jumpRef then
				if strJump ~= "" then
					strJump = strJump .. "、"
				end
				strJump = strJump .. ccLngText(jumpRef.name)
			end
		end
	end
	if strJump == "" then
		strJump = ccClientText(44333)
	end

	self:SetWndText(self.mTxtGet, ccClientText(44239, strJump))

	-- local data = gModelFish:GetFishItemAttr(refId)
	-- local strAttr = ""
	-- for i, v in ipairs(data.attrList) do
	-- 	if strAttr ~= "" then
	-- 		strAttr = strAttr .. "\n"
	-- 	end
	-- 	strAttr = strAttr .. v.desc
	-- end
	-- self:SetWndText(self.mTxtAttr, strAttr)

	self:RefreshTime()

	local strNum, showImgTime, showUse = self:GetNumData(ref.refId)

	CS.ShowObject(self.mBtnUse, showUse)
end

-- tab item
function UIFishBag:OnDrawTabItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			root   = item,
			btnTab = CS.FindTrans(item, "BtnTab1"),

		}
		self:SetComponentCache(instanceID, itemCache)
	end

	self:SetWndTabStatus(itemCache.btnTab, self._curTabIndex ~= itempos and 1 or 0)
	self:SetWndTabText(itemCache.btnTab, itemdata.tabName)
	self:SetWndClick(itemCache.btnTab, function()
		if self._curTabIndex == itempos then
			return
		end
		self._curTabIndex = itempos
		self._curSelectRef = nil
		list:DrawAllItems()
		self:DealWithDataList()
		self:Refresh()
		self:Update()
	end)
end

-- 刷新界面
function UIFishBag:Refresh()
	local tabIndex = self._curTabIndex
	local data = TabDataList[tabIndex]

	self:SetWndText(self.mTitle, data.title)
	self:SetWndText(self.mTips, data.tips)

	local dataList = self._uiDataList
	if not self._curSelectRef then
		self._curSelectRef = dataList[1].ref
	end

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

	self:RefreshTop()
end

-- 初始事件
function UIFishBag:InitEvents()
	self:SetWndClick(self.mBtnUse, function() self:OnClickBtnUse() end)
	self:SetWndClick(self.mBg, function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)
	self:SetWndText(self.mCloseTip, ccClientText(10103))

end

-- 初始化数据
function UIFishBag:InitData()
	self._curSelectRef = nil
	self._curTabIndex = self:GetWndArg("tabIndex") or 1
end

-- 初始界面化文本
function UIFishBag:InitTexts()
	self:SetWndButtonText(self.mBtnUse, ccClientText(44231))
end

-- 列表 item
function UIFishBag:OnDrawListItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			itemRoot = CS.FindTrans(item, "itemRoot"),
			select = CS.FindTrans(item, "select"),
			use = CS.FindTrans(item, "use"),
			lock = CS.FindTrans(item, "lock"),

		}
		self:SetComponentCache(instanceID, itemCache)
	end

	local ref = itemdata.ref
	CS.ShowObject(itemCache.select, self._curSelectRef == ref)

	local strNum, showImgTime, showUse, showLock = self:GetNumData(ref.refId)
	CS.ShowObject(itemCache.lock, showLock)

	local itemNum = 0
	local isShowUnlimited= false
	if ref.refId == self._initBaitRefId then
		itemNum = -2
		isShowUnlimited=true
	elseif ref.refId == self._initRodRefId then
		itemNum = -2
		isShowUnlimited=true
	else
		itemNum = gModelItem:GetNumByRefId(ref.refId)
	end
	local showUse = false
	if self._isFishBait then
		showUse = ref.refId == self._curUseBaitRefId
	else
		showUse = ref.refId == self._curUseRodRefId
	end
	CS.ShowObject(itemCache.use, showUse)

	self:CreateCommonIconImpl(itemCache.itemRoot,
		{ itemType = LItemTypeConst.TYPE_ITEM, itemNum = itemNum, itemId = ref.refId,isShowUnlimited = isShowUnlimited }, {
			clickFunc = function()
				if self._curSelectRef == ref then
					return
				end
				self._curSelectRef = ref
				self:Refresh()
				self:Update()
			end,
			showNum = self._isFishBait,
		})
end

-- 处理列表数据
function UIFishBag:DealWithDataList()
	local tabIndex = self._curTabIndex
	local data = TabDataList[tabIndex]
	self._isFishBait = data.itemType == gModelItem.TTEM_TYPE_FISH_BAIT

	local dataList = {}
	if data.itemType == gModelItem.TTEM_TYPE_FISH_BAIT then
		local curTab
		for i, v in ipairs(self._baitRefList) do
			local tab = {}
			tab.ref = v
			tab.num = gModelItem:GetNumByRefId(v.refId)
			tab.time = 0
			if tab.ref.refId == self._initBaitRefId then
				tab.sort = 10
			else
				tab.sort = tab.num > 0 and 1 or 0
			end
			if tab.ref.refId == self._curUseBaitRefId then
				tab.sort = 999
			end
			table.insert(dataList, tab)
		end
		table.sort(dataList, function(a, b)
			if a.sort ~= b.sort then
				return a.sort > b.sort
			end
			return a.ref.refId < b.ref.refId
		end)
	else
		local curTab
		local curTime = GetTimestamp()
		for i, v in ipairs(self._rodRefList) do
			local tab = {}
			tab.ref = v
			tab.num = gModelItem:GetNumByRefId(v.refId)
			local data = gModelFish:GetFishItemAttr(v.refId)
			local time = data.time
			if tab.ref.refId == self._initRodRefId then
				tab.sort = 20
				tab.time = 0
			else
				if tab.num > 0 then
					if time > 0 then
						tab.sort = 2
					else
						local serData = gModelItem:GetItemServerDataByRefId(v.refId)
						local createTime = serData:GetCreateTime() * 0.001 -- 其实是结束时间
						if curTime >= createTime then
							-- 过期
							tab.sort = 0
						else
							tab.sort = 2
						end
					end
				else
					tab.sort = -1
				end
			end

			if tab.ref.refId == self._curUseRodRefId then
				tab.sort = 999
			end
			table.insert(dataList, tab)
		end
		table.sort(dataList, function(a, b)
			if a.sort ~= b.sort then
				return a.sort > b.sort
			end
			return a.ref.refId < b.ref.refId
		end)
		if curTab then
			table.insert(dataList, 1, curTab)
		end
	end
	self._uiDataList = dataList
end

-- Update
function UIFishBag:Update()
	self:RefreshTime()

	if self._curUseBaitRefId ~= gModelFish:GetCurUseFishBait() then
		self._curUseBaitRefId = gModelFish:GetCurUseFishBait()
		self:DealWithDataList()
		self:Refresh()
		return
	end

	if self._curUseRodRefId ~= gModelFish:GetCurUseFishRod() then
		self._curUseRodRefId = gModelFish:GetCurUseFishRod()
		self:DealWithDataList()
		self:Refresh()
		return
	end
end

------------------------------------------------------------------
return UIFishBag