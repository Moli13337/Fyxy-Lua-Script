---
--- Created by Administrator.
--- DateTime: 2026/6/1 21:02:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISkinBreakReward:LWnd
local UISkinBreakReward = LxClass("UISkinBreakReward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISkinBreakReward:UISkinBreakReward()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISkinBreakReward:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISkinBreakReward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISkinBreakReward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	self:SetUI()
end



function UISkinBreakReward:InitData()
	self._ConsumeData = self:GetWndArg("consumeData")
	self._itemData = self:GetWndArg("itemData")
end

function UISkinBreakReward:InitEvent()
	self:SetWndClick(self.mBtnOk,function()
		--gModelHolyLand:HolyLandRewardReq()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end)
end

function UISkinBreakReward:SetUI()
	self:SetWndText(self.mTitle,ccClientText(47304))
	self:SetWndText(self.mTxtBtnName,ccClientText(44308))
	self:UpdateRewardList()
	local itemPath = gModelItem:GetItemIconByRefId(ModelItem.ITEM_SKIN_DEBRIS)
	self:SetWndEasyImage(self.mImgIcon,itemPath)
	self:SetWndText(self.mItemNum,self._itemData[1].num)
end

function UISkinBreakReward:UpdateRewardList()
	local dataList = {}
	for i = 1, #self._ConsumeData do
		table.insert(dataList,self._ConsumeData[i])
	end
	local list = self:GetUIScroll("ScoreRwdList")
	list:Create(self.mCommonList,dataList,function(...) self:OnDrawRewardItem(...) end)
end

function UISkinBreakReward:OnDrawRewardItem(list, item, itemData, index)
	local instanceId = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceId)
	if not itemCache then
		itemCache = {
			CommonUIIcon = self:FindWndTrans(item,"CommonUI/Icon"),
			ItemNum = self:FindWndTrans(item,"CommonUI/ItemNum"),
			ImgIcon = self:FindWndTrans(item,"Eff/ImgIcon"),
			ItemValue = self:FindWndTrans(item,"Eff/ItemValue"),
		}
		self:SetComponentCache(instanceId,itemCache)
	end
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(itemCache.CommonUIIcon)
	baseClass:SetCommonReward(LItemTypeConst.TYPE_ITEM, itemData.refId)
	baseClass:DoApply()
	local itemRef = gModelItem:GetRefByRefId(itemData.refId)
	local sellData = itemRef.sell
	sellData = string.split(itemRef.sell,"=")
	local itemPath = gModelItem:GetItemIconByRefId(tonumber(sellData[2]))
	self:SetWndEasyImage(itemCache.ImgIcon,itemPath)
	self:SetWndText(itemCache.ItemNum,itemData.num)
	self:SetWndText(itemCache.ItemValue,tonumber(sellData[3]))
	self:SetWndClick(itemCache.CommonUIIcon,function()
		gModelGeneral:ShowCommonItemTipWnd(itemData,{showSkinCode=true})
	end)

end

------------------------------------------------------------------
return UISkinBreakReward