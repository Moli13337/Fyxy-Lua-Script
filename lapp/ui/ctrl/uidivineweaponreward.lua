---
--- Created by Administrator.
--- DateTime: 2025/1/2 14:52:32
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineWeaponReward:LWnd
local UIDivineWeaponReward = LxWndClass("UIDivineWeaponReward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineWeaponReward:UIDivineWeaponReward()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineWeaponReward:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineWeaponReward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineWeaponReward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:InitList()
end

function UIDivineWeaponReward:AwardListItem(_, trans, data)
	local root = CS.FindTrans(trans, "Root")
	local uiCommonList = self._uiCommonList
	local InstanceID = trans:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
	end
	baseClass:SetCommonReward(data.itemType, data.itemId, data.itemNum)
	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
	baseClass:DoApply()
end

function UIDivineWeaponReward:DrawList(_, trans, data)
	local titleText = CS.FindTrans(trans,"TitleText")
	local awardScroll = CS.FindTrans(trans,"AwardScroll")

	self:SetWndText(titleText, data.star)
	local reward = LxDataHelper.ParseItem(data.reward)

	local instanceID = trans:GetInstanceID()
	local uiAwardList = self:GetUIScroll(instanceID)
	if uiAwardList:GetList() then
		uiAwardList:RefreshList(reward)
	else
		uiAwardList:Create(awardScroll, reward, function(...) self:AwardListItem(...) end)
	end
end

function UIDivineWeaponReward:InitList()
	local cfg = gModelDivineWeaponFight:GetChapterCfgById(self.id)
	local starInfo = string.split(cfg.starProgress, "=")
	local rewards = {}
	for i = 1, 3 do
		table.insert(rewards, {
			star = starInfo[i],
			reward = cfg["Reward" .. i]
		})
	end

	local list = self:GetUIScroll("list")
	list:Create(self.mCellScroll, rewards, function(...) self:DrawList(...) end)
	list:EnableScroll(true)
end

function UIDivineWeaponReward:InitCommon()
	------------------------------------------------------------------
	---member
	self.id = self:GetWndArg("id")
	self._uiCommonList = {}

	------------------------------------------------------------------
	---text
	self:SetWndText(self.mTitleText, ccClientText(46216))
	self:SetWndText(self.mTipsText, ccClientText(46217))

	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mBgImage, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end)
end


------------------------------------------------------------------
return UIDivineWeaponReward