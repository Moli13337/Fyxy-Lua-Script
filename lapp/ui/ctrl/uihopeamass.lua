---
--- Created by Administrator.
--- DateTime: 2023/10/2 14:55:02
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeAmass:LWnd
local UIHopeAmass = LxWndClass("UIHopeAmass", LWnd)

UIHopeAmass.WND_TYPE_DREAMTRIP = 1
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeAmass:UIHopeAmass()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeAmass:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeAmass:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeAmass:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEmptyList()
	self:InitEvent()
	self:InitMsg()
	self:InitData()

	local data = {
		refId = 13002,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)

	self:RefreshView()
end

function UIHopeAmass:InitData()
	local showType = self:GetWndArg("showType")
	if showType == nil then
		showType = UIHopeAmass.WND_TYPE_DREAMTRIP
	end
	self._showType = showType
end

function UIHopeAmass:RefreshView()
	local showType = self._showType
	if showType == UIHopeAmass.WND_TYPE_DREAMTRIP then
		gModelFastDreamTrip:OnDreamTripRewardTotalReq()
		self:RefreshDreamTripRewardView()
	end
end

function UIHopeAmass:GetDreamTripRewardList()
	local list = {}
	local tList = {}
	local gridList = gModelFastDreamTrip:GetDreamTripGridInfo()
	for k,v in pairs(gridList or {}) do
		for idx,val in ipairs(v.eventList or {}) do
			if val.state == StructDreamTripGrid.FINISH then
				table.insert(tList,{
					index = val.index,
					rewardList = val.reward,
				})
			end
		end
	end
	table.sort(tList,function(a,b) return a.index < b.index end)
	for i,v in ipairs(tList) do
		for idx,val in ipairs(v.rewardList) do
			table.insert(list,val)
		end
	end
	return list
end

function UIHopeAmass:RefreshDreamTripRewardView()
	self:SetWndText(self.mLblBiaoti,ccClientText(20476))
	self:SetWndText(self.mDescTxt,ccClientText(20475))

--[[	local dreamTripRewardList = self:GetDreamTripRewardList()
	self:RefreshRewardList(dreamTripRewardList)]]
end

function UIHopeAmass:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripRewardTotalResp, function(pb,ret)
		local dreamTripRewardList = {}
		for i,v in ipairs(pb.info) do
			table.insert(dreamTripRewardList,{
				itemType = v.type,
				itemId = v.itemId,
				itemNum = v.count
			})
		end
		self:RefreshRewardList(dreamTripRewardList)
	end)
end

function UIHopeAmass:RefreshRewardList(list,OnDrawItemCellFunc)
	list = list or {}

	local len = #list
	local showEmpty = len < 1
	CS.ShowObject(self.mNoRecord,showEmpty)

	OnDrawItemCellFunc = OnDrawItemCellFunc or function(...)
		self:OnDrawRewardCell(...)
	end

	local uiRewardList = self._uiRewardList
	if uiRewardList then
		uiRewardList:RefreshList(list)
	else
		uiRewardList = self:GetUIScroll("uiRewardList")
		self._uiRewardList = uiRewardList
		uiRewardList:Create(self.mRewardList,list,function(...) OnDrawItemCellFunc(...) end,UIItemList.WRAP)
	end
end

function UIHopeAmass:OnDrawRewardCell(list,item,itemdata,itempos)
	local InstanceID = item:GetInstanceID()
	local itemType,itemId,itemNum = itemdata.itemType,itemdata.itemId,itemdata.itemNum

	local CommonUITrans = self:FindWndTrans(item,"CommonUI")
	local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(IconTrans)
	baseClass:SetCommonReward(itemType, itemId, itemNum)
	baseClass:DoApply()

	self:SetWndClick(CommonUITrans,function()
	gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end

function UIHopeAmass:InitEvent()
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIHopeAmass:InitEmptyList()
	local data = {
		refId = 22001,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("emptyList")
	emptyList:RefreshUI(data)
end
------------------------------------------------------------------
return UIHopeAmass


