---
--- Created by Administrator.
--- DateTime: 2024/7/1 20:32:36
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightTsureGetView:LWnd
local UIGdHoFightTsureGetView = LxWndClass("UIGdHoFightTsureGetView", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightTsureGetView:UIGdHoFightTsureGetView()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightTsureGetView:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightTsureGetView:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightTsureGetView:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitEvent()
	self:InitText()
	self:InitData()
	self:InitPara()
end

--region 页面初始化 --------------------------------------------------------------------------------
function UIGdHoFightTsureGetView:InitText()
	self:SetWndText(self.mTitle, ccClientText(44049))  --[44049] [寶藏預覽]
end

function UIGdHoFightTsureGetView:InitData()

end

function UIGdHoFightTsureGetView:CreateRewardPreviewList(list, item, itemdata, itempos)
	local itemRoot = CS.FindTrans(item, "ItemIcon")

	--缓存下道具
	local InstanceID = item:GetInstanceID()
	if not self._uiCommonList then
		self._uiCommonList = {}
	end
	local baseClass = self._uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonList[InstanceID] = baseClass
		baseClass:Create(itemRoot)
	end

	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	self:SetWndClick(itemRoot, function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
	baseClass:DoApply()
end
--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIGdHoFightTsureGetView:SetRewardPreview()
	local ref = gModelGuildHolyBattle:GetTreasureRefByRefId(self._para.rewardRefId)
	local showDatas = LxDataHelper.ParseItem(ref.reward)
	local uiList = self._rewardList

	if not uiList then
		uiList = self:GetUIScroll(self.mRewardList:GetInstanceID())
		uiList:Create(self.mRewardList, showDatas, function(...)
			self:CreateRewardPreviewList(...)
		end, UIItemList.SUPER_GRID, false)

		self._rewardList = uiList
	else
		uiList:RefreshList(showDatas)
		uiList:DrawAllItems(true)
	end
end

function UIGdHoFightTsureGetView:InitEvent()
	--ui
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)

	self:SetWndClick(self.mClose, function()
		self:WndClose()
	end)

end

function UIGdHoFightTsureGetView:InitPara()
	self._para = self:GetWndArg("para")
	self:SetRewardPreview()
end

--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIGdHoFightTsureGetView