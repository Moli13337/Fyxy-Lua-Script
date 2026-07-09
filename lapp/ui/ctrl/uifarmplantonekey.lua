---
--- Created by Administrator.
--- DateTime: 2024/10/15 11:02:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFarmPlantOneKey:LWnd
local UIFarmPlantOneKey = LxWndClass("UIFarmPlantOneKey", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFarmPlantOneKey:UIFarmPlantOneKey()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFarmPlantOneKey:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFarmPlantOneKey:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFarmPlantOneKey:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self.activityData = self:GetWndArg("activityData")
	local playerId = gModelPlayer:GetPlayerId()
	self.landNum,self.landList = gModelFarm:GetFarmLands(playerId,true)
	self:SetWndText(self.mLblBiaoti,ccClientText(45913))
	self:SetWndText(self.mCloseTip,ccClientText(41037))
	self:SetWndButtonText(self.mBtnConfirn,ccClientText(43343))
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndText(self.mTxtTitle,ccClientText(45909))
	self:SetWndButtonGray(self.mBtnConfirn,true)
	self:SetWndClick(self.mBtnConfirn,function() self:OnConfirmClick() end)
	self.selData = {}
	self.plantNum = 0 
	self:UpdateList()
end

function UIFarmPlantOneKey:OnConfirmClick()

	local list = {}
	local isReq = false
	for seedId, count in pairs(self.selData) do
		for i = 1, count do
			table.insert(list,{index = table.remove(self.landList,1),seed = seedId})
			isReq = true
		end
	end
	if isReq then
		gModelFarm:OnHappyFarmPlantReq(self.activityData.sid,list)
	end
	self:WndClose()
end
function UIFarmPlantOneKey:OnDrawCell(list,item,itemdata,itempos)
	local CommonUI = self:FindWndTrans(item, "CommonUI")
	local ImgSelect = self:FindWndTrans(item, "ImgSelect")
	local TxtName = self:FindWndTrans(item,"TxtName")
	local ValueBg = self:FindWndTrans(item,"ValueBg")
	local SubBtn = self:FindWndTrans(item,"ValueBg/SubBtn")
	local AddBtn = self:FindWndTrans(item,"ValueBg/AddBtn")
	local itemId = itemdata
	local itemType = 1
	local itemNum = gModelItem:GetNumByRefId(itemId)
	CS.ShowObject(ImgSelect,false)
	CS.ShowObject(ValueBg,itemNum>0)
	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(CommonUI)
	baseClass:SetCommonReward(itemType, itemId, itemNum)
	baseClass:DoApply()
	self:SetWndClick(item,function()
        gModelGeneral:ShowCommonItemTipWnd({itemId = itemId,itemType = itemType,itemNum = itemNum})
		-- local oldSel = self.selImg
		-- CS.ShowObject(oldSel,false)
		-- self.selImg = ImgSelect
		-- CS.ShowObject(ImgSelect,true)
	end)
	self:SetTextTile(ValueBg,0)
	self:SetWndClick(SubBtn,function()
		if self.selData[itemId] and self.selData[itemId] >0 then
			local count = self.selData[itemId] or 0
			self.selData[itemId] = count-1
			self.plantNum = self.plantNum-1
			self:SetTextTile(ValueBg,self.selData[itemId])
		end
		self:SetWndButtonGray(self.mBtnConfirn,self.plantNum<=0)
	end)
	self:SetWndClick(AddBtn,function()
		local curNum = self.selData[itemId] or 0
		if self.plantNum<self.landNum and curNum < itemNum then
			local count = self.selData[itemId] or 0
			self.selData[itemId] = count+1
			self.plantNum = self.plantNum+1
			self:SetTextTile(ValueBg,self.selData[itemId])
		else
			if self.plantNum>=self.landNum then
				GF.ShowMessage(ccClientText(45911))
			else
				GF.ShowMessage(ccClientText(45912))
			end
		end
		self:SetWndButtonGray(self.mBtnConfirn,self.plantNum<=0)
	end)

	local name = gModelItem:GetNameByRefId(itemId)
	self:SetWndText(TxtName,name)
end
function UIFarmPlantOneKey:UpdateList()
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
		uiFarmList = self:GetUIScroll("FarmPlantOneList")
		---@type UIItemList
		self._uiFarmList = uiFarmList
		uiFarmList:Create(self.mListSeed,seedList,function(...) self:OnDrawCell(...) end)
	end
end

------------------------------------------------------------------
return UIFarmPlantOneKey