---
--- Created by wzz.
--- DateTime: 2024/8/7 11:20:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishAutoFast:LWnd
local UIFishAutoFast = LxWndClass("UIFishAutoFast", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishAutoFast:UIFishAutoFast()
	self._costItem = gModelFish:GetCostItem()
	self._uidataList = {}
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishAutoFast:OnWndClose()
	if self._timer then
		LxTimer.DelayTimeStop(self._timer)
		self._timer = nil
	end

	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishAutoFast:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishAutoFast:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._autoFishData = self:GetWndArg("autoData")

	self:InitTexts()
	self:InitEvents()
	self:SendMsg(0)
	self:Refresh()
end

-- 获取剩余次数
function UIFishAutoFast:GetLeftTimes()
	local hadNum = gModelItem:GetNumByRefId(self._costItem.refId)
	local leftTimes = math.floor(hadNum / self._costItem.itemNum)
	return leftTimes
end

-- 刷新界面
function UIFishAutoFast:Refresh()
	local dataList = self._uidataList

	local leftTimes = self:GetLeftTimes()
	self:SetWndText(self.mTxtTimes, ccClientText(44340, leftTimes))


	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList
		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList:RefreshData(dataList)
	end
	self._uiList:MoveToPos(#dataList)

	self:SetWndEasyImage(self.mBgTitle,"fish_bg_big_txt1",function() CS.ShowObject(self.mBgTitle,true)  end)
end

-- 快速钓鱼返回
function UIFishAutoFast:OnFastReturn(data)
	local theBait = data.theBait
	local data = {theBait = theBait}
	local id

	if theBait then
		local state = self:CheckDealWith(theBait)
		for k, v in pairs(state) do
			data[k] = v
		end
		id = theBait.fish.id
	end
	table.insert(self._uidataList, data)


	if data.openGet then
		GF.OpenWnd("UIFishGet", { theBait = theBait, callback = function()
			self:SendMsg()
		end })
	elseif data.save then
		gModelFish:SettleFishingReq(2, id)
	elseif data.sell then
		gModelFish:SellFishReq(0, id)
	end

	self:Refresh()
	if not data.openGet then
		self:SendMsg()
	end
end

-- 发送信息
function UIFishAutoFast:SendMsg(time)
	if self._timer then
		LxTimer.DelayTimeStop(self._timer)
		self._timer = nil
	end
	time = time or 0.75
	self._timer = LxTimer.DelayTimeCall(function()
		if self._isStopAuto then
			return
		end

		if gModelFish:CheckNewFarm() then
			self:WndClose()
			return
		end
		gModelFish:FishingReq(2)


	 end, time)
end

-- 初始界面化文本
function UIFishAutoFast:InitTexts()
	self:SetWndText(self.mCloseTip, ccClientText(44351))
end

-- 绘制列表item项
function UIFishAutoFast:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			aniRoot  = CS.FindTrans(item, "AniRoot"),
			txtTitle = CS.FindTrans(item, "AniRoot/txtTitle"),
			txtType  = CS.FindTrans(item, "AniRoot/txtType"),
			txtFlee  = CS.FindTrans(item, "AniRoot/txtFlee"),
			txtSave  = CS.FindTrans(item, "AniRoot/txtSave"),
			txtSell  = CS.FindTrans(item, "AniRoot/txtSell"),
			fishItem = CS.FindTrans(item, "AniRoot/fishItem"),
			sellItem = CS.FindTrans(item, "AniRoot/sellItem"),
			txtKg    = CS.FindTrans(item, "AniRoot/txtKg"),

		}
		self:SetComponentCache(instanceID, itemCache)
	end
	if itemPos == #self._uidataList then
		self:PlayItemAnimation(list, item, itemPos, 1001)
	end


	local strTitle, strType, strFlee, strSave, strSell, strWeight = "", "", "", "", "", ""
	local theBait = itemData.theBait
	if theBait then
		local fishObj = theBait.fish
		local refId = fishObj.refId
		local fishRef = gModelFish:GetFishRef(refId)
		local fishTypeRef = gModelFish:GetFishTypeRef(fishRef.type)
		local fishItemData = { itemId = refId, itemType = CommonIcon.ICON_TYPE_FISH }
		self:CreateCommonIconImpl(itemCache.fishItem, fishItemData, {
			showNum = false,
			clickFunc = function()
				GF.OpenWnd("UIFishTips", { refId = refId, isTips = true })
			end
		})

		local showWeight = gModelFish:InFishTankTypeList(refId)
		if showWeight then
			strWeight = gModelFish:WeightToString(fishObj.weight)
		end

		strTitle = ccLngText(fishRef.name)
		strType = ccLngText(fishTypeRef.name)

		if itemData.sell then
			local sellItemData = LUtil.GetRefItemData(fishRef.sell)
			sellItemData.itemType = CommonIcon.ICON_TYPE_ITEM
			self:CreateCommonIconImpl(itemCache.sellItem, sellItemData, {
				showNum = true,
			})
			strSell = ccClientText(44343)
		elseif itemData.save then
			strSave = ccClientText(44342)
		elseif itemData.openGet then
			strSave = ccClientText(44344)
		end
	else
		strFlee = ccClientText(44341)
	end
	self:SetWndText(itemCache.txtKg, strWeight)
	self:SetWndText(itemCache.txtFlee, strFlee)
	self:SetWndText(itemCache.txtTitle, strTitle)
	self:SetWndText(itemCache.txtType, strType)
	self:SetWndText(itemCache.txtSave, strSave)
	self:SetWndText(itemCache.txtSell, strSell)

	CS.ShowObject(itemCache.sellItem, itemData.sell == true)
	CS.ShowObject(itemCache.fishItem, theBait ~= nil)
end

-- 判断处理鱼的方式
function UIFishAutoFast:CheckDealWith(theBait)
	local autoFishData = self._autoFishData
	local fishObj      = theBait.fish
	local fishRef      = gModelFish:GetFishRef(fishObj.refId)
	local state         = {
		openGet = false,
		sell = true,
		save = false,
	}

	if theBait.type == CommonIcon.ICON_TYPE_FISH then
		local canInFishTank = gModelFish:InFishTankTypeList(fishRef.refId)
		if autoFishData.selectedQualityFast and canInFishTank then
			-- 品质需求
			state.save = fishRef.quality >= autoFishData.qualityFast
		end

		if not state.save and autoFishData.selectedPowerUpFast and canInFishTank then
			-- 评分提升
			-- local data = gModelFish:GetFishTankObj(fishRef.refId)
			-- if data then
			-- 	state.save = fishObj.estimatePower > 0
			-- else
			-- 	if not gModelFish:NeedOpenFishTank(fishObj) then
			-- 		state.save = true
			-- 	end
			-- end
			state.save = fishObj.estimatePower > 0
		end
		if state.save then
			local sellOld, id = gModelFish:NeedSellBackpackFish(fishObj)
			if sellOld then
				if id == 0 then
					state.save = false
					state.sell = true
				else
					for k, v in ipairs(self._uidataList) do
						if v.theBait and v.theBait.fish.id == id then
							v.save = false
							v.sell = true
							break
						end
					end
				end
			end
		end


		if state.save then
			state.sell = false
		end
	else
		-- 宝箱
		state.openGet = true
	end

	return state
end

-- 初始事件
function UIFishAutoFast:InitEvents()
	self:SetWndClick(self.mMask, function() self:OnClickWnd() end)
	self:WndEventRecv(EventNames.FISH_FAST, function(...) self:OnFastReturn(...) end)
end

-- 点击界面
function UIFishAutoFast:OnClickWnd()

	if self._isStopAuto then
		self:WndClose()
		return
	end
	GF.ShowMessage(ccClientText(44352))

	self._isStopAuto = true
	self:SetWndText(self.mCloseTip, ccClientText(10103))
end

------------------------------------------------------------------
return UIFishAutoFast