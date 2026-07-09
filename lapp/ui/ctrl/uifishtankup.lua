---
--- Created by wzz.
--- DateTime: 2024/7/16 17:01:29
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishTankUp:LWnd
local UIFishTankUp = LxWndClass("UIFishTankUp", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishTankUp:UIFishTankUp()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishTankUp:OnWndClose()
	LWnd.OnWndClose(self)

	local func = self:GetWndArg("callFunc")
	if func then
		func()
	end
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishTankUp:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishTankUp:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsForeignVersion()
	
	if self._isEnus then 
		self.mHadMax.sizeDelta = Vector2.New(120,32)
	end 
	
	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 点击升级
function UIFishTankUp:OnClickBtnUp()
	if not gModelFish:CanLvUpFishTank(true) then
		return
	end

	gModelFish:UpgradeAquariumReq()
end

-- 属性item
function UIFishTankUp:OnDrawItem(uiList, item, data)
	if not uiList then
		uiList = {}
		uiList.item = item
		uiList.arrow = CS.FindTrans(item, "Arrow")
		uiList.up = CS.FindTrans(item, "UIText/Up")
		uiList.new = CS.FindTrans(item, "UIText/New")
	end

	self:SetTextTile(uiList.item, data.desc)
	CS.ShowObject(uiList.arrow, data.showArrow == true)
	CS.ShowObject(uiList.up, data.up == true)
	CS.ShowObject(uiList.new, data.isNew == true)

	return uiList
end

-- 刷新界面
function UIFishTankUp:Refresh()
	local assetIdList = gModelFish:GetFishTankUpTopAssetList()
	self:SetTopAssetList(self.mTopAsset, assetIdList)

	local curLev = gModelFish:GetFishTankLev()
	local curRef = gModelFish:GetFishTankLevRef(curLev)
	local nextRef = gModelFish:GetFishTankLevRef(curLev + 1)
	local canUp, costItem, isMax = gModelFish:CanLvUpFishTank(false)

	local leftDataList = {}
	local rightDataList = {}

	local list1 = gModelFish:GetFishTankAttr(curRef.refId)
	if isMax then
		rightDataList[1] = {
			desc = ccClientText(44275, curRef.refId),
		}

		for k, v in ipairs(list1) do
			local data = {}
			local typeRef = gModelFish:GetFishTypeRef(v.type)
			data.desc = ccLngText(typeRef.name) .. ccClientText(44278, v.value)
			table.insert(rightDataList, data)
		end
		local data = {}
		data.desc = ccClientText(44277, curRef.attr * 100)
		table.insert(rightDataList, data)
	else
		leftDataList[1] = {

			desc = ccClientText(44275, curRef.refId),
		}
		rightDataList[1] = {
			showArrow = true,
			desc = ccClientText(44276, nextRef.refId),
		}
		local list2 = gModelFish:GetFishTankAttr(nextRef.refId)
		for k, v in ipairs(list1) do
			local data = {}
			local typeRef = gModelFish:GetFishTypeRef(v.type)
			data.desc = ccLngText(typeRef.name) .. ccClientText(44278, v.value)
			table.insert(leftDataList, data)
		end
		for k, v in ipairs(list2) do
			local beforeVal = list1[k] and list1[k].value or 0
			local data = {}
			data.up = v.value > beforeVal
			data.desc = ccClientText(44278, v.value)
			if data.up then
				data.desc = ccClientText(44279, data.desc)
			end
			table.insert(rightDataList, data)
		end

		if curRef.attr == 0 then
			local data = {}
			data.desc = ""
			table.insert(leftDataList, data)

			local data2 = {}
			data2.isNew = true
			data2.desc = ccClientText(44277, nextRef.attr * 100)
			data.desc = ccClientText(44279, data.desc)
			table.insert(rightDataList, data2)
		else
			local data = {}
			data.desc = ccClientText(44277, curRef.attr * 100)
			table.insert(leftDataList, data)

			local data2 = {}
			data2.desc = ccClientText(44277, nextRef.attr * 100)
			if nextRef.attr > curRef.attr then
				data2.desc = ccClientText(44279, data2.desc)
				data2.up = true
			end
			table.insert(rightDataList, data2)
		end
	end

	CS.ShowObject(self.mHadMax, isMax)
	CS.ShowObject(self.mBtnUp, not isMax)
	CS.ShowObject(self.mLeft, not isMax)
	self:SetRed(self.mBtnUp, canUp)

	if not isMax then
		local iconPath = gModelItem:GetItemImgByRefId(costItem.itemId)
		self:SetWndEasyImage(self.mCostIcon, iconPath)
		local strNum = ""
		if canUp then
			strNum = ccClientText(44280, costItem.itemNum)
		else
			strNum = ccClientText(44281, costItem.itemNum)
		end

		self:SetWndText(self.mCostNum, strNum)
	end

	self:SetComList(self.mLeft, leftDataList, function(...) return self:OnDrawItem(...) end)
	self:SetComList(self.mRight, rightDataList, function(...) return self:OnDrawItem(...) end)
end

-- 初始事件
function UIFishTankUp:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnUp, function() self:OnClickBtnUp() end)

	self:WndEventRecv(EventNames.FISH_BASE_INFO, function(...) self:Refresh(...) end)
end

-- 初始界面化文本
function UIFishTankUp:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(44272))
	self:SetWndText(self.mTxtCloseTips, ccClientText(41037))
	self:SetTextTile(self.mHadMax, ccClientText(44282))
	self:SetWndButtonText(self.mBtnUp, ccClientText(44274))
end

------------------------------------------------------------------
return UIFishTankUp