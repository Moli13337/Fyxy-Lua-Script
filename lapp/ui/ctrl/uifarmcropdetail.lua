---
--- Created by Administrator.
--- DateTime: 2024/10/15 11:46:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFarmCropDetail:LWnd
local UIFarmCropDetail = LxWndClass("UIFarmCropDetail", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFarmCropDetail:UIFarmCropDetail()
	self.cropTime = "cropTime"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFarmCropDetail:OnWndClose()
	LWnd.OnWndClose(self)
	self:TimerStop(self.cropTime)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFarmCropDetail:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFarmCropDetail:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:OnEventClicks()
	self:SetWndText(self.mCloseTip,ccClientText(41037))
	local landIndex = self:GetWndArg("index")
	self.activityData = self:GetWndArg("activityData")
	self.callback = self:GetWndArg("func")
	local playerId = gModelPlayer:GetPlayerId()
	---@type StructFarm
	self.farmData = gModelFarm:GetFarmDataByPlayerId(playerId)
	---@type StructFarmLand
	self.landData = self.farmData.lands[landIndex]
	self.useCount = 0
	self:OnCropDetail()
end
function UIFarmCropDetail:SetCropTime()
	local timeDif = os.difftime(self.landData.endTime,GetTimestamp())
	local timeStr = LUtil.FormatTimespanCn(math.max(timeDif,0))
	if timeDif<=0 then
		self:TimerStop(self.cropTime)
		self:WndClose()
	end
	self:SetWndText(self.mTxtTime,timeStr)
end

function UIFarmCropDetail:OnUseFertilizer()
	local sizeDel = self.mFertilizer.parent.sizeDelta
	sizeDel.y = 618
	self.mFertilizer.parent.sizeDelta = sizeDel
	self:SetWndText(self.mLblBiaoti,ccClientText(45919))
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(43343))
	self:SetWndText(self.mTxtTitle4,ccClientText(45923))
	CS.ShowObject(self.mItemGroup2,false)
	CS.ShowObject(self.mFertilizer,true)
	local costNum,costId = gModelFarm:CropNeedFertilizerNum(self.activityData.sid,self.landData.index,GetTimestamp())
	self.fertilizerNum = gModelItem:GetNumByRefId(costId)
	self.fertilizerId = costId
	self.maxCount = math.min(costNum,self.fertilizerNum)
	-- self:OnUpdateFertilizer(math.max(self.maxCount,1))
	self.useCount = math.max(self.maxCount,0)
	self:SetTextTile(self.mValueBg,self.useCount)
	self:SetWndButtonGray(self.mBtnConfirm,self.maxCount<=0)
end
function UIFarmCropDetail:OnEventClicks()
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm,function() self:OnConfirmClick() end)
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mSubBtn,function() self:OnUpdateFertilizer(-1) end)
	self:SetWndClick(self.mAddBtn,function() self:OnUpdateFertilizer(1) end)
	self:SetWndClick(self.mMaxBtn,function()
		self.useCount = self.maxCount
		self:OnUpdateFertilizer(0) end)
end
function UIFarmCropDetail:OnTimer(key)
	if key== self.cropTime then
		self:SetCropTime()
	end
end

function UIFarmCropDetail:OnConfirmClick()
	if self.mFertilizer.gameObject.activeSelf then
		if self.fertilizerNum <=0 then
			gModelGeneral:OpenGetWayWnd({ itemId = self.fertilizerId })
			return
		end
		if self.callback then self.callback() end
		gModelFarm:OnHappyFarmPlantFertilizationReq(self.activityData.sid,{self.landData.index},self.useCount)
		self:WndClose()
	else
		self:OnUseFertilizer()
	end
end
function UIFarmCropDetail:OnCropDetail()
	local sizeDel = self.mFertilizer.parent.sizeDelta
	sizeDel.y = 430
	self.mFertilizer.parent.sizeDelta = sizeDel
	self:InitFertilizer()
	self:SetWndText(self.mLblBiaoti,ccClientText(45918))
	self:SetWndText(self.mTxtTitle,ccClientText(45920))
	self:SetWndText(self.mTxtTitle2,ccClientText(45921))
	self:SetWndText(self.mTxtTitle3,ccClientText(45922))
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(45919))
	CS.ShowObject(self.mItemGroup2,true)
	CS.ShowObject(self.mFertilizer,false)
	local instanceId = self.mCommIcon:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(self.mCommIcon)
	local itemId,itemType,itemNum = self.landData.crop,1,1
	baseClass:SetCommonReward(itemType, itemId, itemNum)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
	local name = gModelItem:GetNameByRefId(itemId)
	self:SetWndText(self.mTxtName,name)
	local itemDesc = gModelItem:GetDescByRefId(itemId)
	self:SetWndText(self.mTxtDesc,itemDesc)
	local cropCfg = gModelFarm:GetCropGrowInfo(self.activityData.sid,self.landData.crop)
	local timeStr = LUtil.FormatTimespanCn(cropCfg.growTime)
	self:SetWndText(self.mTxtTime2,timeStr)
	self:SetWndText(self.mTxtNum,cropCfg.count)
	self:TimerStart(self.cropTime,1,false,-1)
	self:SetCropTime()
end

function UIFarmCropDetail:InitFertilizer()
	local fertilizerItem = gModelFarm:GetFertilizerInfo(self.activityData.sid)
	local instanceId = self.mFertilizerItem:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(self.mFertilizerItem)

	local fertilizerNum = gModelItem:GetNumByRefId(fertilizerItem.itemId)
	baseClass:SetCommonReward(1, fertilizerItem.itemId, fertilizerNum)
	baseClass:DoApply()
	self:SetWndClick(self.mFertilizerItem,function()
        gModelGeneral:ShowCommonItemTipWnd({itemId = fertilizerItem.itemId,itemType = 1,itemNum = fertilizerNum})
	end)
end

function UIFarmCropDetail:OnUpdateFertilizer(num)
	if self.maxCount<=0 then
		GF.ShowMessage(ccClientText(45924))
		return
	end
	self.useCount = self.useCount+num
	if self.useCount<=0 then
		self.useCount = 1
	elseif self.useCount> self.maxCount then
		self.useCount = self.maxCount
	end
	self:SetTextTile(self.mValueBg,self.useCount)
end


------------------------------------------------------------------
return UIFarmCropDetail