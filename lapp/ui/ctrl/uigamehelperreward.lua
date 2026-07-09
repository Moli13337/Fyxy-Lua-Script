---
--- Created by Administrator.
--- DateTime: 2024/11/6 15:56:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGameHelperReward:LWnd
local UIGameHelperReward = LxWndClass("UIGameHelperReward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGameHelperReward:UIGameHelperReward()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGameHelperReward:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGameHelperReward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGameHelperReward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._isEnus = gLGameLanguage:IsEnglishVersion()
	self._isJapaness  =gLGameLanguage:IsJapanVersion()
	self:InitCommon()

	local list = self:GetWndArg("list")
	self:UpdateList(list)
end

function UIGameHelperReward:DrawRewardIcon(_, item, data)
	local root = self:FindWndTrans(item, "Root")
	local reward = data.serverData
	local instanceId = root:GetInstanceID()
	local commonIcon = self:GetCommonIcon(instanceId)
	commonIcon:Create(root)
	local type = reward.itemType or reward.itype
	local id = reward.itemId or reward.refId
	commonIcon:SetCommonReward(type, id, reward.itemNum)
	commonIcon:DoApply()

	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end)
end

function UIGameHelperReward:SetItem(trans, data)
	local title = CS.FindTrans(trans, "Title")
	local uiRewardList = CS.FindTrans(trans, "RewardList")
	local no = CS.FindTrans(trans, "No")

	local cfg = GameTable.AssistantListRef[data.refId]
	self:SetTextTile(title, ccLngText(cfg.name))

	if self._isJapaness or self._isEnus then
      local width = 244
		-- 107  108 变大
		if data.refId==107 or data.refId == 108 then
			width =415
		end
		LxUiHelper.SetSizeWithCurAnchor(title,0,width)
	end

	local rewardInfo = gModelGeneral:GetThingsDetailInfoByPb(data.reward)
	local rewardNum = rewardInfo:GetThingsDetailRewardNum()
	local rewardList = rewardInfo:GetThingsDetailAllRewardList()

	if rewardNum == 0 then
		if data.error.code ~= 0 then
			self:SetWndText(no, ccServerText(data.error.code))
		else
			self:SetWndText(no, ccLngText(cfg.desd2))
		end
	end

	local InstanceID = trans:GetInstanceID()
	uiRewardList.sizeDelta = Vector2.New(math.min(#rewardList * 92, 527), 92)
	if self.rewardIconUIList[InstanceID] then
		self.rewardIconUIList[InstanceID]:RefreshList(rewardList)
		self.rewardIconUIList[InstanceID]:DrawAllItems()
	else
		self.rewardIconUIList[InstanceID] = self:GetUIScroll("rewardIconUIList" .. InstanceID)
		self.rewardIconUIList[InstanceID]:Create(uiRewardList, rewardList, function(...) self:DrawRewardIcon(...) end, UIItemList.SUPER_GRID)
	end

	CS.ShowObject(no, rewardNum == 0)
	CS.ShowObject(uiRewardList, rewardNum > 0)
end

function UIGameHelperReward:UpdateList(list)
	for _, v in ipairs(list) do
			if not self.itemList[v.refId] then
				local gameObj = LxUnity.InstantObject(self.mItem.gameObject)
				gameObj.name = "Item" .. v.refId
				local item = gameObj.transform
				self.itemList[v.refId] = item
				LxUnity.SetParentTrans(item, self.mContent)
				CS.ShowObject(item, true)
			end
			self:SetItem(self.itemList[v.refId], v)
	end
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mContent)
	local height = self.mContent.rect.height
	if height > 666	 then
		local duration = 2.5
		local seqcom = self:GetSeqCom()
		local seq = seqcom:CreateSeq("moveContent")
		local csScrollRect = self.mScrollView.gameObject:GetComponent(typeof(CS.ScrollRect))
		local curPos = csScrollRect.normalizedPosition
		local endPos = Vector2.New(0, 0)
		local tween = YXTween.TweenFloat(0, 1, duration, function(t)
			local pos = Vector2.Lerp(curPos, endPos, t)
			csScrollRect.normalizedPosition = pos
		end)
		seq:Append(tween)
		seq:PlayForward()
	end
end

function UIGameHelperReward:InitCommon()
	------------------------------------------------------------------
	---member
	self.itemList = {}
	self.rewardIconUIList = {}

	------------------------------------------------------------------
	---text
	self:SetWndText(self.mLblBiaoti, ccClientText(24246))

	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)
end



------------------------------------------------------------------
return UIGameHelperReward