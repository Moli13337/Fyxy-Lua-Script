---
--- Created by Administrator.
--- DateTime: 2024/10/15 10:56:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFarmPlantBatch:LWnd
local UIFarmPlantBatch = LxWndClass("UIFarmPlantBatch", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFarmPlantBatch:UIFarmPlantBatch()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFarmPlantBatch:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFarmPlantBatch:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFarmPlantBatch:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	
	self.activityData = self:GetWndArg("activityData")
	self.activCfg = gModelActivity:GetWebActivityDataById(self.activityData.sid).config
	self.fertilizerItem = gModelFarm:GetFertilizerInfo(self.activityData.sid)
	self.needCount = 0
	self.maxCount = 0
	self.needCost = 0
	self.selCount = 0
	-- self.landNum = gModelFarm:GetFarmLands(gModelPlayer:GetPlayerId(),true)

	self:InitStatic()
	self:UpdateFertilizer()
	self:SetCurrencyList()
	self:UpdateList()
	self:UpdateSelNum(0)
end

function UIFarmPlantBatch:OnConfirmClick()
	-- local list = {}
	-- for i = 1, self.selCount do
	-- 	table.insert(list,{index=1,seed = self.selSeedId})
	-- end

	if self.selCount>0 then gModelFarm:OnHappyFarmFastPlantReq(self.activityData.sid,self.selCount,self.selSeedId) end
	self:WndClose()
end
function UIFarmPlantBatch:InitStatic()
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirn,function() self:OnConfirmClick() end)
	self:SetWndClick(self.mSubBtn,function() self:UpdateSelNum(-1,true) end)
	self:SetWndClick(self.mAddBtn,function() self:UpdateSelNum(1,true) end)
	self:SetWndClick(self.mMaxBtn,function()
		self.selCount = self.maxCount
		self:UpdateSelNum(0,true)
	end)

	self:SetWndText(self.mCloseTip,ccClientText(41037))
	self:SetWndText(self.mLblBiaoti,ccClientText(45925))
	self:SetWndText(self.mTxtTitle,ccClientText(45926))
	self:SetWndText(self.mTxtTitle2,ccClientText(45909))
	self:SetWndText(self.mTxtDesc,ccClientText(45927))
	self:SetWndButtonText(self.mBtnConfirn,ccClientText(43343))
	self:SetTextTile(self.mValueBg,0)
end

function UIFarmPlantBatch:UpdateSelNum(num,tips)
	-- if self.selCount<=0 and num<=0 then return end
	if not self.selSeedId and tips then
		GF.ShowMessage(ccClientText(45910))
		return
	end
	if self.selCount+num > gModelItem:GetNumByRefId(self.selSeedId) then
		GF.ShowMessage(ccClientText(45937))
		return
	-- elseif self.selCount+num > self.landNum then
	-- 	GF.ShowMessage(ccClientText(45911))
	-- 	return
	elseif self.selCount+num > self.maxCount then
		GF.ShowMessage(ccClientText(45924))
		return
	end

	self.selCount = self.selCount+num
	if self.selCount<=0 then
		self.selCount = 0
	elseif self.selCount> self.maxCount then
		self.selCount = self.maxCount
	end
	self:SetTextTile(self.mValueBg,self.selCount)
	self:SetWndButtonGray(self.mBtnConfirn,self.selCount<=0)
	self:UpdateFertilizer()
end
function UIFarmPlantBatch:UpdateList()
	local seedItems = gModelFarm:GetSeedInfo(self.activityData.sid)
	local seedList = {}
	for seedId, value in pairs(seedItems) do
		table.insert(seedList,seedId)
	end
	table.sort(seedList,function(a, b) return a<b end)
	local uiFarmList = self._uiFarmList
	if uiFarmList then
		uiFarmList:RefreshList(seedList)
	else
		uiFarmList = self:GetUIScroll("plantBatchList")
		---@type UIItemList
		self._uiFarmList = uiFarmList
		uiFarmList:Create(self.mListSeed,seedList,function(...) self:OnDrawCell(...) end)
	end
end

function UIFarmPlantBatch:InitMaxNum(maxSeedNum)--种子最大数量，肥料种植最大数量，地块最大数量
	local crops = gModelFarm:GetSeedInfo(self.activityData.sid,self.selSeedId)
	local maxGrowTime = 0
	local maxTimeCrop = nil
	for crop, val in pairs(crops) do
		local cropData = gModelFarm:GetCropGrowInfo(self.activityData.sid,crop)
		if maxGrowTime==0 or cropData.growTime>maxGrowTime then
			maxGrowTime = cropData.growTime
			maxTimeCrop = crop
		end
	end

	local needCost = math.ceil(maxGrowTime/self.fertilizerItem.addTime) or 0
	self.needCost = needCost
	local canUseNum = math.floor(gModelItem:GetNumByRefId(self.fertilizerItem.itemId)/needCost)
	canUseNum = math.min(canUseNum,maxSeedNum)
	-- canUseNum = math.min(canUseNum,self.landNum)
	self.maxCount = canUseNum
end

function UIFarmPlantBatch:UpdateFertilizer()
	local instanceId = self.mFertilizer:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(self.mFertilizer)

	local fertilizerNum = self.needCost*self.selCount
	baseClass:SetCommonReward(1, self.fertilizerItem.itemId, fertilizerNum)
	baseClass:DoApply()
	self:SetWndClick(self.mFertilizer,function()
        gModelGeneral:ShowCommonItemTipWnd({itemId = self.fertilizerItem.itemId,itemType = 1,itemNum = fertilizerNum})
	end)
end
function UIFarmPlantBatch:SetCurrencyList()
	local list = {self.fertilizerItem.itemId}
	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
	else
		_uiCellList = self:GetUIScroll("_CurrencyPlant")
		_uiCellList:Create(self.mCurrencyList, list, function(...)
			self:OnCurrencyScroll(...)
		end)
		self._uiCellList = _uiCellList
	end
end

function UIFarmPlantBatch:OnDrawCell(list,item,itemdata,itempos)
	local CommonUI = self:FindWndTrans(item, "CommonUI")
	local ImgSelect = self:FindWndTrans(item, "ImgSelect")
	local TxtName = self:FindWndTrans(item,"TxtName")

	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(CommonUI)

	local itemNum = gModelItem:GetNumByRefId(itemdata)
	baseClass:SetCommonReward(1, itemdata, itemNum)
	baseClass:DoApply()
	local maxNum = gModelItem:GetNumByRefId(itemdata)
	local name = gModelItem:GetNameByRefId(itemdata)
	self:SetWndText(TxtName,name)

	self:SetWndClick(item,function()
		if self.selImg and self.selImg == ImgSelect then return end
		if maxNum <=0 then
			gModelGeneral:ShowCommonItemTipWnd({itemId = itemdata,itemType = 1,itemNum = itemNum})
			return
		end
		local oldSel = self.selImg
		CS.ShowObject(oldSel,false)
		self.selImg = ImgSelect
		CS.ShowObject(ImgSelect,true)
		self.selSeedId = itemdata
		self.selCount = 0
		self:InitMaxNum(maxNum)
		self:UpdateSelNum(0)
	end)

end

function UIFarmPlantBatch:OnCurrencyScroll(list, item, itemdata, itempos)
	local itemIcon = self:FindWndTrans(item, "Icon")
	local num = self:FindWndTrans(item, "Num")
	local itemId = tonumber(itemdata)
	local icon = gModelItem:GetItemImgByRefId(itemId)
	local itemNum = 0
	itemNum = gModelItem:GetNumByRefId(itemId)
	self:SetWndEasyImage(itemIcon, icon)
	local numStr = LUtil.NumberCoversion(itemNum)
	self:SetWndText(num, numStr)
	self:SetWndClick(item, function()
		local itemData = {
			itemId = itemId,
			itemNum = itemNum,
			itemType = 1,
		}
		gModelGeneral:ShowCommonItemTipWnd(itemData)
	end)
end

------------------------------------------------------------------
return UIFarmPlantBatch