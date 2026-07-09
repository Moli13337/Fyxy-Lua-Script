---
--- Created by Administrator.
--- DateTime: 2024/10/28 15:25:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightPkAward:LWnd
local UIGdHoFightPkAward = LxWndClass("UIGdHoFightPkAward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightPkAward:UIGdHoFightPkAward()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightPkAward:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightPkAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightPkAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitCommon()
	self:SetList()
	self:SetSelf()
end

function UIGdHoFightPkAward:DrawReward(_, trans, data)
	self:SetRewardItem(trans, data)
end

function UIGdHoFightPkAward:DrawRewardIcon(_, item, data)
	local root = self:FindWndTrans(item, "Root")
	local instanceId = root:GetInstanceID()
	local commonIconCls = self:GetCommonIcon(instanceId)
	commonIconCls:Create(root)
	commonIconCls:SetCommonReward(data.itemType, data.itemId, data.itemNum)
	commonIconCls:DoApply()

	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end

function UIGdHoFightPkAward:SetList()
	local cross = gModelGuildHolyPeak:GetCross()
	local index = cross == 1 and 101 or 1
	local cfg = GameTable.ClanWarPeakRankRewardRef
	self.list = {}
	while cfg[index] do
		table.insert(self.list, cfg[index])
		index = index + 1
	end

	if self.uiList then
		self.uiList:ResetList(self.list)
		self.uiList:DrawAllItems()
	else
		self.uiList = self:GetUIScroll("mList")
		self.uiList:Create(self.mList, self.list, function(...) self:DrawReward(...) end, UIItemList.SUPER)
	end
end

function UIGdHoFightPkAward:SetRewardItem(trans, data)
	local rankIcon = CS.FindTrans(trans, "RankIcon")
	local rankBg = CS.FindTrans(trans, "RankBg")
	local rewardList = CS.FindTrans(trans, "RewardList")
	local title = CS.FindTrans(trans, "Title")
	local noRank = CS.FindTrans(trans, "NoRank")
	local noReward = CS.FindTrans(trans, "NoReward")

	if self._isVie then
		self:SetAnchorPos(noReward,Vector2.New(160,0))
	end
	if title then
		self:SetTextTile(title, ccClientText(20864))
	end
	if data then
		if type(data.rank) == "string" then
			local strTb = string.split(data.rank, ",")
			local rankMin = tonumber(strTb[1])
			local rankMax = tonumber(strTb[2])
			if rankMin >= 1 and rankMin <= 3 then
				self:SetWndEasyImage(rankIcon, "public_num_" .. rankMin)

				CS.ShowObject(rankIcon, true)
				CS.ShowObject(rankBg, false)
			else
				local s = rankMin == rankMax and rankMin or rankMin .. "-" .. rankMax
				self:SetTextTile(rankBg, s)

				CS.ShowObject(rankIcon, false)
				CS.ShowObject(rankBg, true)
			end
		else
			if data.rank <= 3 then
				self:SetWndEasyImage(rankIcon, "public_num_" .. data.rank)

				CS.ShowObject(rankIcon, true)
				CS.ShowObject(rankBg, false)
			else
				self:SetTextTile(rankBg, data.rank)

				CS.ShowObject(rankIcon, false)
				CS.ShowObject(rankBg, true)
			end
		end

		local InstanceID = trans:GetInstanceID()
		local reward = LxDataHelper.ParseItem(data.reward)
		if self.rewardIconUIList[InstanceID] then
			self.rewardIconUIList[InstanceID]:RefreshList(reward)
		else
			self.rewardIconUIList[InstanceID] = self:GetUIScroll("rewardIconUIList" .. InstanceID)
			self.rewardIconUIList[InstanceID]:Create(rewardList, reward, function(...) self:DrawRewardIcon(...) end, UIItemList.SUPER_GRID)
		end
		rewardList.sizeDelta = Vector2.New(#reward * 74 + (#reward - 1) * 5, 74)
	else
		self:SetWndText(noRank, ccClientText(11708))
		self:SetWndText(noReward, ccClientText(11722))

		CS.ShowObject(rankIcon, false)
		CS.ShowObject(rankBg, false)
	end

end

function UIGdHoFightPkAward:SetSelf()
	local guildId = gModelPlayer:GetGuildId()
	local guildInfo = gModelGuildHolyPeak:GetGuildInfoById(guildId)
	local data
	if guildInfo and guildInfo.rank > 0 then
		for _, v in ipairs(self.list) do
			local strTb = string.split(v.rank, ",")
			local rankMin = tonumber(strTb[1])
			local rankMax = tonumber(strTb[2])
			if guildInfo.rank >= rankMin and guildInfo.rank <= rankMax then
				data = {
					rank = guildInfo.rank,
					reward = v.reward
				}
				break
			end
		end
	end
	self:SetRewardItem(self.mSelf, data)
end

function UIGdHoFightPkAward:InitCommon()
	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mMask, function()
        self:WndClose()
    end)

	------------------------------------------------------------------
	---text
	self:SetWndText(self.mTitle_1, ccClientText(28105))
    self:SetWndText(self.mTitle_2, ccClientText(44069))
	self:SetWndText(self.mCloseTip, ccClientText(10103))

	------------------------------------------------------------------
	---member
	self.rewardIconUIList = {}
end



------------------------------------------------------------------
return UIGdHoFightPkAward