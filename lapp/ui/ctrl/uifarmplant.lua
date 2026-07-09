---
--- Created by Administrator.
--- DateTime: 2024/10/15 10:50:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFarmPlant:LWnd
local UIFarmPlant = LxWndClass("UIFarmPlant", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFarmPlant:UIFarmPlant()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFarmPlant:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFarmPlant:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFarmPlant:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mLblBiaoti,ccClientText(45907))
	self:SetWndText(self.mTxtTitle,ccClientText(45908))
	self:SetWndText(self.mTxtTitle2,ccClientText(45909))
	self:SetWndText(self.mTxtDesc,ccClientText(45910))
	self:SetWndText(self.mCloseTip,ccClientText(41037))
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(43343))
	self:SetWndButtonGray(self.mBtnConfirm,true)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end)
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm,function() self:OnConfirmClick() end)
	self.activityData = self:GetWndArg("activityData")
	self.landIndex = self:GetWndArg("index")
	self.mainCfg=gModelActivity:GetWebActivityDataById(self.activityData.sid).config
	self.selImg = nil
	self.selData = nil
	self:UpdateList()
end

function UIFarmPlant:OnConfirmClick()
	if 	not self.selData then
		GF.ShowMessage(ccClientText(45910))
		return
	end
	local list = {{index = self.landIndex,seed = self.selData}}
	gModelFarm:OnHappyFarmPlantReq(self.activityData.sid,list)
	self:WndClose()
end

function UIFarmPlant:OnDrawCell(list,item,itemdata,itempos)
	local CommonUI = self:FindWndTrans(item, "CommonUI")
	local ImgSelect = self:FindWndTrans(item, "ImgSelect")
	local TxtName = self:FindWndTrans(item,"TxtName")
	local itemId = itemdata
	local itemType = 1
	local itemNum = gModelItem:GetNumByRefId(itemId)

	local instanceId = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(CommonUI)

	baseClass:SetCommonReward(itemType, itemId, itemNum)
	baseClass:DoApply()
	self:SetWndClick(item,function()
        gModelGeneral:ShowCommonItemTipWnd({itemId = itemId,itemType = itemType,itemNum = itemNum})
	end)

	self:SetWndClick(item,function()
		local oldSel = self.selImg
		CS.ShowObject(oldSel,false)
		self.selImg = ImgSelect
		CS.ShowObject(ImgSelect,true)
		self.selData = itemdata

		local str = gModelItem:GetDescByRefId(itemdata)
		self:SetWndText(self.mTxtDesc,str)
		self:SetWndButtonGray(self.mBtnConfirm,false)
	end)

	local name = gModelItem:GetNameByRefId(itemId)
	self:SetWndText(TxtName,name)
end

function UIFarmPlant:UpdateList()
	local seedItems = string.split(self.mainCfg.seedItem,";")
	local seedList = {}
	for _, value in ipairs(seedItems) do
		local seedStr = string.split(value,"|")
		table.insert(seedList,tonumber(seedStr[1]))
	end
	local uiFarmList = self._uiFarmList
	if uiFarmList then
		uiFarmList:RefreshList(seedList)
	else
		uiFarmList = self:GetUIScroll("FarmPlantList")
		---@type UIItemList
		self._uiFarmList = uiFarmList
		uiFarmList:Create(self.mListSeed,seedList,function(...) self:OnDrawCell(...) end)
	end
end

------------------------------------------------------------------
return UIFarmPlant