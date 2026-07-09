---
--- Created by Administrator.
--- DateTime: 2024/5/27 19:45:56
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubNewAct18Award:LChildWnd
local UISubNewAct18Award = LxWndClass("UISubNewAct18Award", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubNewAct18Award:UISubNewAct18Award()
	self.rewardIconUIList = {}
	self.commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubNewAct18Award:OnWndClose()
	self:ClearCommonIconList(self.rewardIconUIList)
	self:ClearCommonIconList(self.commonUIList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubNewAct18Award:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubNewAct18Award:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
end

function UISubNewAct18Award:updateMyReward()
	if self.myRank and self.list then
		for _, v in ipairs(self.list) do
			local rank = v.rank
			if rank[1] <= self.myRank and (self.myRank <= rank[2] or rank[2] <= 0) then
				self:SetRewardItem(self.mMyReward, v)
				return
			end
		end
	end
	self:SetRewardItem(self.mMyReward, {})
end

function UISubNewAct18Award:DrawRewardIcon(_, item, data)
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

function UISubNewAct18Award:InitEvent()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		self:OnActivityPageResp(pb)
	end)
	self:WndEventRecv(EventNames.RANK_UPDATE_END, function()
		self.myRank = gModelRank:GetMeRank().rank
		self:updateMyReward()
	end)
end

function UISubNewAct18Award:DrawReward(_, item, data)
	self:SetRewardItem(item, data)
end

function UISubNewAct18Award:InitData()
	self.cfg = self:GetWndArg("cfg")
	self.sid = self:GetWndArg("sid")
	self.rankId = self.cfg.rankId

	gModelActivity:OnActivityPageReq(self.sid)
	gModelRank:OnRankReq(2, self.rankId, 1, 25, self.sid)
end

function UISubNewAct18Award:OnActivityPageResp(pb)
	if pb.sid ~= self.sid then return end
	local page2
	if pb.pages[2] then
		page2 = StructActivityPage:New()
		page2:CreateByPb(pb.pages[2])
	end

	self.list = {}
	if page2 then
		for _, v in ipairs(page2.entry) do
			local entryCfg = gModelActivity:GetWebActivityEntryData(page2.sid, v.pageId, v.entryId)
			if entryCfg then
				local entryId = v.entryId
				local data = {}
				data.index = entryId
				local reward = LxDataHelper.ParseItem(entryCfg.reward)
				data.reward = {}
				for i = #reward, 1, -1 do
					table.insert(data.reward, reward[i])
				end
				local str = string.split(entryCfg.name, "~")
				local left = tonumber(str[1]) or 0
				local right = (str[2] and tonumber(str[2])) or left
				local rank = {}
				table.insert(rank, left)
				table.insert(rank, right)
				data.rank = rank
				table.insert(self.list, data)
			end
		end
	end

	if not self.rewardList then
		self.rewardList = self:GetUIScroll("mRewardList")
		self.rewardList:Create(self.mRewardList, self.list, function(...) self:DrawReward(...) end, UIItemList.SUPER)
	else
		self.rewardList:ResetList(self.list)
		self.rewardList:DrawAllItems()
	end

	self:updateMyReward()
end

function UISubNewAct18Award:SetRewardItem(trans, data)
	local rankIcon = self:FindWndTrans(trans, "RankIcon")
	local rankObj = self:FindWndTrans(trans, "RankObj")
	local rankText = self:FindWndTrans(trans, "RankObj/RankText")
	local isMeText = self:FindWndTrans(trans, "IsMe/Text")
	local noReward = self:FindWndTrans(trans, "NoReward")
	local rewardList = self:FindWndTrans(trans, "RewardList")

	self:SetWndText(isMeText, ccClientText(11726))
	self:SetWndText(noReward, ccClientText(11722))

	if data.rank then
		local rankMin = data.rank[1]
		local rankMax = data.rank[2]
		if rankMin == rankMax and (rankMin >= 1 and rankMin <= 3) then
			self:SetWndEasyImage(rankIcon, "public_num_" .. rankMin)

			CS.ShowObject(rankIcon, true)
			CS.ShowObject(rankObj, false)
		else
			self:SetWndText(rankText, rankMin .. "-" .. rankMax)

			CS.ShowObject(rankIcon, false)
			CS.ShowObject(rankObj, true)
		end
	else
		CS.ShowObject(rankIcon, false)
		CS.ShowObject(rankObj, false)
	end


	if data.reward and #data.reward > 0 then
		local InstanceID = trans:GetInstanceID()

		if self.rewardIconUIList[InstanceID] then
			self.rewardIconUIList[InstanceID]:RefreshList(data.reward)
			self.rewardIconUIList[InstanceID]:DrawAllItems()
		else
			self.rewardIconUIList[InstanceID] = self:GetUIScroll("rewardIconUIList" .. InstanceID)
			self.rewardIconUIList[InstanceID]:Create(rewardList, data.reward, function(...) self:DrawRewardIcon(...) end, UIItemList.SUPER_GRID)
		end

		rewardList.sizeDelta = Vector2.New(#data.reward * 73 + (#data.reward - 1) * 3, 73)

		CS.ShowObject(noReward, false)
		CS.ShowObject(rewardList, true)
	else
		CS.ShowObject(noReward, true)
		CS.ShowObject(rewardList, false)
	end
end

------------------------------------------------------------------
return UISubNewAct18Award