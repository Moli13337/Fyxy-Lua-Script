---
--- Created by Administrator.
--- DateTime: 2024/6/11 18:21:55
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuWarAward:LWnd
local UIKuafuWarAward = LxWndClass("UIKuafuWarAward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuWarAward:UIKuafuWarAward()
	self.rewardIconUIList = {}
	self.commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuWarAward:OnWndClose()
	self:ClearCommonIconList(self.rewardIconUIList)
	self:ClearCommonIconList(self.commonUIList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuWarAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuWarAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitText()
	self:InitRewardList()
end

function UIKuafuWarAward:DrawReward(_, item, data)
	local rankIcon = self:FindWndTrans(item, "Rank/RankIcon")
	local rankBg = self:FindWndTrans(item, "Rank/RankBg")
	local rankText = self:FindWndTrans(rankBg, "Text")
	local rewardList = self:FindWndTrans(item, "RewardList")
	if data.rank > 3 then
		self:SetWndText(rankText, data.rank)
	else
		self:SetWndEasyImage(rankIcon, "public_num_" .. data.rank)
	end
	CS.ShowObject(rankIcon, data.rank <= 3)
	CS.ShowObject(rankBg, data.rank > 3)

	rewardList.sizeDelta = Vector2.New(#data.reward * 80 + (#data.reward - 1) * 3, 80)
	if data.reward and #data.reward > 0 then
		local InstanceID = item:GetInstanceID()
		if self.rewardIconUIList[InstanceID] then
			self.rewardIconUIList[InstanceID]:RefreshList(data.reward)
			self.rewardIconUIList[InstanceID]:DrawAllItems()
		else
			self.rewardIconUIList[InstanceID] = self:GetUIScroll("rewardIconUIList" .. InstanceID)
			self.rewardIconUIList[InstanceID]:Create(rewardList, data.reward, function(...) self:DrawRewardIcon(...) end, UIItemList.SUPER_GRID)
		end
	end
end

function UIKuafuWarAward:InitText()
	self:SetWndText(self.mLblBiaoti, ccClientText(43811))
end

function UIKuafuWarAward:InitEvent()
	self:SetWndClick(self.mBg, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end)
end

function UIKuafuWarAward:DrawRewardIcon(_, item, data)
	local root = self:FindWndTrans(item, "Root")
	local instanceId = root:GetInstanceID()
	if not self.commonUIList[instanceId] then
		self.commonUIList[instanceId] = CommonIcon:New()
		self.commonUIList[instanceId]:Create(root)
	end
	self.commonUIList[instanceId]:SetCommonReward(data.itemType, data.itemId, data.itemNum)
	self.commonUIList[instanceId]:DoApply()

	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end

function UIKuafuWarAward:InitRewardList()
	local cfg = GameTable.BattleTempleDomainRef
	local list = {}
	for _, v in pairs(cfg) do
		list[v.refId] = {
			reward = LUtil.GetRefItemDataList(v.seasonReward),
			rank = v.refId
		}
	end

	if not self.rewardList then
		self.rewardList = self:GetUIScroll("mRewardList")
		self.rewardList:Create(self.mRewardList, list, function(...) self:DrawReward(...) end, UIItemList.SUPER)
	else
		self.rewardList:ResetList(list)
		self.rewardList:DrawAllItems()
	end
end



------------------------------------------------------------------
return UIKuafuWarAward