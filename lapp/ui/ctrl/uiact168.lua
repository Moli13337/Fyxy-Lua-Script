---
--- Created by wzz.
--- DateTime: 2025/10/11 10:53:18
--- 活动168 0元购
------------------------------------------------------------------
local LWndBaseActivity = LWndBaseActivity
---@class UIAct168:LWndBaseActivity
local UIAct168    = LxClass("UIAct168", LWndBaseActivity)
------------------------------------------------------------------

local LayoutRebuilder  = UnityEngine.UI.LayoutRebuilder
local LUIHeroObject    = LxRequire("LApp.UI.Display.LUIHeroObject")
local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAct168:UIAct168()
	if not LUtil.IsToDay(checknumber(LPlayerPrefs.openActivity82) or 0) then
		LPlayerPrefs.SetOpenActivity82(GetTimestamp())
		FireEvent(EventNames.ON_ACTIVITY_LOCAL_CLICK_RED_CHANGE)
	end

	self._needUpdateItemList = {}
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAct168:OnStartFinish()
	self:InitData()
	self:InitTexts()
	self:InitEvents()
	self:InitTimer()
end

-- 初始数据
function UIAct168:InitData()
	local actData = gModelActivity:GetActivityBySid(self.sid)
	local endTime = actData.endTime
	local showEndTime = actData.showEndTime
	if showEndTime and showEndTime > endTime then
		endTime = showEndTime
	end
	self._actEndTime = tonumber(endTime)
end

-- 初始界面化文本
function UIAct168:InitTexts()
	self:SetWndText(self.mTxtClose, ccClientText(10320))
end

-- 初始事件
function UIAct168:InitEvents()
	self:SetWndClick(self.mCloseBtn, function() self:WndClose() end)
	self:SetWndClick(self.mBtnHelp, function() self:OnClickHelpBtn() end)
end

-- 初始时间
function UIAct168:InitTimer()
	local timePara = {
		key = 1,
		loopcnt = -1,
		interval = 1,
		timescale = false,
		callOnStart = false,
		func = function()
			self:Update()
		end
	}
	self:TimerStartImpl(timePara)
end

-- 获取page配置和对应的服务数据
function UIAct168:GetPageConfigAndData(pageId)
	local pageList = gModelActivity:GetActivityPagesListBySid(self.sid)
	local pageDataList = pageList[pageId].entry
	local webData = gModelActivity:GetWebActivityDataById(self.sid)
	local entries = webData.chunk[pageId].entries
	local dataList = {}
	for k, v in pairs(entries) do
		dataList[k] = {
			config = v,
			data = pageDataList[k]
		}
	end
	return dataList
end

-- 计算当前所在的天数
function UIAct168:CalcInDay()
	local curTime = GetTimestamp()
	local actData = gModelActivity:GetActivityBySid(self.sid)
	local startTime = actData.startTime
	local oneDaySceonds = 86400
	local inDay = math.floor((curTime - startTime) / oneDaySceonds) + 1
	return inDay
end

-- 计算距离当天所在0点的结束时间
function UIAct168:CalcDayEndTime()
	local curTime = GetTimestamp()
	local date = os.date("*t", curTime)
	local hour = date.hour * 3600
	local min = date.min * 60
	local sec = date.sec
	local oneDaySceonds = 86400
	local leftTime = oneDaySceonds - (hour + min + sec)
	return curTime + leftTime
end

-- 计算总天数
function UIAct168:CalcTotalDays()
	local list = self:GetPageConfigAndData(1)
	if #list == 0 then
		return 1
	end
	return #list
end

-- 计算是否可以购买所有
function UIAct168:CalcCanBuyAll()
	return self._inDay > self._totalDays
end

-- 计算已购买的天数
function UIAct168:CalcCurDay()
	local list = self:GetPageConfigAndData(1)

	local day = 0
	for k, v in ipairs(list) do
		local data = v.data or {}
		local status = self:CalcItemStatus(data)
		if status == 1 or status == 2 then
			-- 已购买或可购买
			day = day + 1
		end
	end
	return day
end

-- update
function UIAct168:Update()
	local curTime = GetTimestamp()
	local leftTime = self._actEndTime - curTime
	if leftTime > 0 then
		local timeStr = LUtil.FormatTimespanCn(leftTime)
		self:SetWndText(self.mTxtTime, ccClientText(15905, timeStr))
	else

	end

	for itemCache, itemData in pairs(self._needUpdateItemList) do
		local status = self:CalcItemStatus(itemData.data)
		local str = ""
		if status == 4 and not self._canByAll then
			leftTime = self._dayEndTime - curTime
			if leftTime < 0 then
				leftTime = 0
			end
			str = LUtil.FormatTimespanNumber(leftTime)
			str = string.replace(self._buyCountdown, str)
		end
		self:SetWndText(itemCache.txtTips1, str)
	end
end

-- 配置返回刷新 （界面已完成且必定存在配置数据）
function UIAct168:OnConfigRefresh()
	local webData = gModelActivity:GetWebActivityDataById(self.sid)
	local config = webData.config

	self:SetWndText(self.mTxtSliderTips, config.SignIncontinuously)
	self:SetWndEasyImage(self.mImgTitle1, config.descIcon, nil, true)
	if not string.isempty(config.descIconPosition) then
		local pos = LxDataHelper.ParseVector2NotEmpty(config.descIconPosition)
		self:SetAnchorPos(self.mGiftTitleImg, pos)
	end
	self:SetWndText(self.mTxtDesc, config.descIconTxt)

	local data = string.split(config.ImageHero, "=")
	if data[1] == "1" then
		self:SetWndEasyImage(self.mSpineImg, data[2])
	elseif data[1] == "2" then
		self:CreateWndSpine(self.mSpine, data[2], data[2], false)
	end
	CS.ShowObject(self.mSpineImg, data[1] == "1")
	CS.ShowObject(self.mSpine, data[1] == "2")

	if not string.isempty(config.ImageHeroPos) then
		local pos = LxDataHelper.ParseVector2NotEmpty(config.ImageHeroPos)
		self:SetAnchorPos(self.mSpineImg, pos)
		self:SetAnchorPos(self.mSpine, pos)
	end

	if not string.isempty(config.timeTxtColor) then
		self:SetTextColor(self.mTxtTime, LUtil.ColorByHex_6(config.timeTxtColor))
	end

	if not string.isempty(config.endTimePosition) then
		local pos = LxDataHelper.ParseVector2NotEmpty(config.endTimePosition)
		self:SetAnchorPos(self.mTimeBg, pos)
	end
	CS.ShowObject(self.mTimeBg, config.endTime == 1)

	self._cellDescIcon = config.cellDescIcon
	self._buyCountdown = config.buyCountdown
end

-- page数据返回刷新 （界面已完成且必定存在配置数据和page数据）
function UIAct168:OnPageRefresh()
	-- 当前所在的天数
	self._inDay      = self:CalcInDay()
	-- 当天结束时间
	self._dayEndTime = self:CalcDayEndTime()
	-- 当前已购买的天数
	self._curDay     = self:CalcCurDay()
	-- 总天数
	self._totalDays  = self:CalcTotalDays()
	-- 所有可以购买
	self._canByAll   = self:CalcCanBuyAll()

	self:RefreshProgress()
	self:RefreshList()
end

-- 刷新进度
function UIAct168:RefreshProgress()
	local dataList = self:GetPageConfigAndData(2)
	local actData = gModelActivity:GetWebActivityDataById(self.sid)
	local actConfig = actData.config
	if not self._nodeList then
		self._nodeList = {}
		-- 应要求固定三个
		local template = self.mNodeTemplate.gameObject
		for i = 1, 3 do
			local parent = self["mNode" .. i]

			local obj = CS.InstantObject(template)
			local trans = obj.transform
			trans.localPosition = Vector3.zero
			trans:SetParent(parent, false)
			CS.ShowObject(obj, true)

			local txtDay   = CS.FindTrans(trans, "TxtDay")
			local itemIcon = CS.FindTrans(trans, "Iconbg/ItemIcon")
			local get      = CS.FindTrans(trans, "Get")
			local canGet   = CS.FindTrans(trans, "CanGet")
			local noReach  = CS.FindTrans(trans, "NoReach")
			local redPoint = CS.FindTrans(trans, "redPoint")

			self:SetWndEasyImage(get, "public_txt_13_1", nil, true)
			self:SetWndEasyImage(canGet, "public_txt_4_4", nil, true)
			self:SetWndEasyImage(noReach, "activity_turn_txt_16", nil, true)

			local config   = dataList[i].config
			self:SetWndText(txtDay, string.replace(actConfig.CumulativeDay,config.name))

			local item = LxDataHelper.ParseItem_3(config.reward)
			self:CreateCommonIconImpl(itemIcon, item, { showNum = true, noClick = true })

			local imgSlider   = self:FindWndTrans(self["mSlider" .. i])

			local uiList      = {}
			uiList.trans      = trans
			uiList.get        = get
			uiList.canGet     = canGet
			uiList.noReach    = noReach
			uiList.redPoint   = redPoint
			uiList.imgSlider  = imgSlider

			self._nodeList[i] = uiList
		end
	end


	local totalDays = self._totalDays
	local curDay = self._curDay
	local slider = self:FindWndSlider(self.mSlider)
	slider.value = curDay / totalDays
	self:SetWndText(self.mTxtSliderTotal, curDay)

	local lastDay = 0
	for k, uiList in ipairs(self._nodeList) do
		local config = dataList[k].config
		local data = dataList[k].data or {}
		local goalData = data.goalData or {}
		local schedules = goalData.schedules and goalData.schedules[1] or {}
		local needDay = tonumber(schedules.goal) or 1
		local hadGet = goalData.status == 2
		local showCanGet = false
		local showGet = false
		local showNoReach = false
		if curDay >= needDay then
			if hadGet then
				-- 已领取
				showGet = true
			else
				-- 可领取
				showCanGet = true
			end
		else
			-- 未达成
			showNoReach = true
		end
		CS.ShowObject(uiList.get, showGet)
		CS.ShowObject(uiList.canGet, showCanGet)
		CS.ShowObject(uiList.redPoint, showCanGet)
		CS.ShowObject(uiList.noReach, showNoReach)

		local item = LxDataHelper.ParseItem_3(config.reward)
		self:SetWndClick(uiList.trans, function()
			if showCanGet then
				gModelActivity:OnActivityReceiveGoalReq(self.sid, data.pageId, data.entryId)
			else
				gModelGeneral:ShowCommonItemTipWnd(item)
			end
		end)

		-- 进度条
		local size = Vector2.New(150, 19)
		size.x = size.x * math.min(1, math.max(0,((curDay - lastDay) /  (needDay - lastDay))))
		uiList.imgSlider.sizeDelta = size
		--uiList.imgSlider.fillAmount = (curDay - lastDay) /  (needDay - lastDay)
		lastDay = needDay
	end
end

-- 刷新列表
function UIAct168:RefreshList()
	local dataList = self:GetPageConfigAndData(1)

	self._needUpdateItemList = {}
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

	self._uiList:MoveToPos(math.max(0, self._inDay - 1))
end

-- 绘制列表item项
function UIAct168:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			txtTips1   = CS.FindTrans(item, "AniRoot/TxtTips1"),
			txtTips2   = CS.FindTrans(item, "AniRoot/TxtTips2"),
			txtTips3   = CS.FindTrans(item, "AniRoot/TxtTips3"),
			txtTitle   = CS.FindTrans(item, "AniRoot/1/TxtTitle"),
			itemList   = CS.FindTrans(item, "AniRoot/Scroll View/Viewport/ItemList"),
			btnReceive = CS.FindTrans(item, "AniRoot/BtnReceive"),
			btnLock    = CS.FindTrans(item, "AniRoot/BtnLock"),
			scrollView = CS.FindComponent(item, "AniRoot/Scroll View", typeOfScrollRect),
		}
		self:SetComponentCache(instanceID, itemCache)
		self:SetWndButtonText(itemCache.btnLock, ccClientText(22603))
		self:SetWndText(itemCache.txtTips2, self._cellDescIcon)
	end
	self._needUpdateItemList[itemCache] = itemData
	local config = itemData.config
	local data = itemData.data
	self:SetWndText(itemCache.txtTitle, config.name)

	-- 1.可领取 2.已领取 3.未解锁 4.已解锁(可购买) 5.已过期（未领取，未购买）
	local status = self:CalcItemStatus(data)
	local btnStr = ""
	local btnIsGray = false
	if status == 1 then
		btnStr = ccClientText(45807)
	elseif status == 2 then
		btnStr = ccClientText(12208)
		btnIsGray = true
	elseif status == 3 then
	elseif status == 4 then
		local expend2 = config.expend2
		btnStr = gModelPay:GetShowByWelfareId(tonumber(expend2))
	elseif status == 5 then
		btnStr = ccClientText(44295)
		btnIsGray = true
	end
	self:SetWndButtonText(itemCache.btnReceive, btnStr)
	self:SetWndButtonGray(itemCache.btnReceive, btnIsGray)

	CS.ShowObject(itemCache.btnReceive, status ~= 3)
	CS.ShowObject(itemCache.btnLock, status == 3)

	local items = LxDataHelper.ParseItem_3List(config.reward)
	local itemList = {}
	for k, v in ipairs(items) do
		if k > 1 then -- 第一个不显示
			table.insert(itemList, v)
		end
	end

	itemCache.scrollView.enabled = #itemList >= 4
	self:SetComList(itemCache.itemList, itemList, function(...) return self:OnComAwardListItem(...) end)
	self:SetWndClick(itemCache.btnReceive, function() self:OnClickBtnReceive(itemData, status) end)
	self:SetWndClick(itemCache.btnLock, function() GF.ShowMessage(ccClientText(45008)) end)

	self:ShowBtnEff(itemCache.btnReceive, instanceID, status == 1, nil)
	self:Update()
end

-- 计算item状态：1.可领取 2.已领取 3.未解锁 4.已解锁(可购买) 5.已过期（未领取，未购买）
function UIAct168:CalcItemStatus(data)
	if self._inDay < data.entryId then
		return 3
	end

	if data.MarketData.personalGoal == data.MarketData.personal then
		return 2
	end

	if self._inDay == data.entryId then
		return 4
	end

	if self._canByAll then
		return 4
	end

	return 5
end

-- 点击领取按钮
function UIAct168:OnClickBtnReceive(itemData, status)
	-- 1.可领取 2.已领取 3.未解锁 4.已解锁(可购买) 5.已过期（未领取，未购买）
	local entry = itemData.data
	local config = itemData.config
	local sid = self.sid

	if status == 2 then
		GF.ShowMessage(ccClientText(12208))
		return
	end
	if status == 1 then
		gModelActivity:OnActivityReceiveGoalReq(sid, entry.pageId, entry.entryId)
		return
	end
	if status == 5 then
		GF.ShowMessage(ccClientText(44295))
		return
	end

	gModelPay:GiftPayCtrl(entry.entryId, config.expend2, ModelPay.PAY_TYPE_ACTIVITY, 0, sid, entry.pageId, nil, true)
end

-- comList列表 item
function UIAct168:OnComAwardListItem(uiList, trans, data)
	if not uiList then
		uiList = {}
	end

	self:CreateCommonIconImpl(trans, data, { showNum = true })
	return uiList
end

function UIAct168:OnClickHelpBtn()
	local webData = gModelActivity:GetWebActivityDataById(self.sid)
	local config = webData.config
	local title = config.name
	local text = config.descIconTxt
	GF.OpenWnd("UIBzTips",{title = title, text = text })
end

------------------------------------------------------------------
return UIAct168
