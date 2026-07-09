---
--- Created by Administrator.
--- DateTime: 2024/9/23 17:26:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMicPotAward:LWnd
local UIMicPotAward = LxWndClass("UIMicPotAward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMicPotAward:UIMicPotAward()
	self.rewardIconUIList = {}
	self.onePotNum = GameTable.MagicGetConfigRef.magicGetOnePot
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMicPotAward:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMicPotAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMicPotAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()

	gModelMagicPot:MagicPotInfoReq()
end

function UIMicPotAward:DrawRewardIcon(_, item, data)
	local root = self:FindWndTrans(item, "Root")
	local instanceId = root:GetInstanceID()
	local commonIcon = self:GetCommonIcon(instanceId)
	commonIcon:Create(root)
	commonIcon:SetCommonReward(data.itemType, data.itemId, data.itemNum)
	commonIcon:DoApply()

	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end

function UIMicPotAward:OnMagicPotInfoResp()
	self.potNum = math.floor(gModelMagicPot:GetPotNum() / self.onePotNum)
	self.phaseReward = gModelMagicPot:GetPhaseReward()
	self:UpdateList()
end

function UIMicPotAward:InitCommon()
	-----------------------------------------------
	---text
	self:SetWndText(self.mLblBiaoti, ccClientText(45814))
	self:SetWndText(self.mTopText, ccClientText(45815))

	-----------------------------------------------
	---Click
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end)

	-----------------------------------------------
	---event
	self:WndEventRecv("MagicPotInfoResp", function()
		self:OnMagicPotInfoResp()
	end)
	self:WndEventRecv("MagicPotPhaseRewardResp", function()
		gModelMagicPot:MagicPotInfoReq()
	end)
end

function UIMicPotAward:DrawList(_, item, data)
	local title = CS.FindTrans(item, "Title")
	local rewardList = CS.FindTrans(item, "RewardList")
	local getBtn = CS.FindTrans(item, "GetBtn")
	local isGet = CS.FindTrans(item, "IsGet")

	local str = string.replace(ccClientText(45816), data.floor)
	local str2 = "(<color=#a1#>#a2#/#a3#</color>)"
	local color = self.potNum >= data.floor and "#139057" or "#c81212"
	str2 = string.replace(str2, color, self.potNum, data.floor)
	self:SetWndText(title, str .. str2)
	local InstanceID = item:GetInstanceID()
	rewardList.sizeDelta = Vector2.New(#data.reward * 88 + (#data.reward - 1) * 3, 88)
	if self.rewardIconUIList[InstanceID] then
		self.rewardIconUIList[InstanceID]:RefreshList(data.reward)
		self.rewardIconUIList[InstanceID]:DrawAllItems()
	else
		self.rewardIconUIList[InstanceID] = self:GetUIScroll("rewardIconUIList" .. InstanceID)
		self.rewardIconUIList[InstanceID]:Create(rewardList, data.reward, function(...) self:DrawRewardIcon(...) end, UIItemList.SUPER_GRID)
	end
	if self.potNum >= data.floor and not self.phaseReward[data.refId] then
		self:CreateWndEffect(getBtn, "fx_anniu_02", InstanceID, 100)
	else
		self:DestroyWndEffectByKey(InstanceID)
	end

	self:SetWndButtonText(getBtn, ccClientText(12207))
	CS.ShowObject(getBtn, self.potNum >= data.floor and not self.phaseReward[data.refId])
	CS.ShowObject(isGet, self.phaseReward[data.refId])
	self:SetWndClick(getBtn, function()
		gModelMagicPot:MagicPotPhaseRewardReq(data.refId)
	end)
end

function UIMicPotAward:UpdateList()
	local t = gModelMagicPot:GetRewardList()
	local list = {}
	for _, v in ipairs(t) do
		if not self.phaseReward[v.refId] then
			table.insert(list, v)
		end
	end
	if self.uiList then
		self.uiList:ResetList(list)
		self.uiList:DrawAllItems()
	else
		self.uiList = self:GetUIScroll("mRewardList")
		self.uiList:Create(self.mList, list, function(...) self:DrawList(...) end, UIItemList.SUPER)
	end
	local moveIndex = 1
	for i, v in ipairs(list) do
		if self.potNum >= v.floor and not self.phaseReward[v.refId] then
			moveIndex = i
			break
		end
	end
	self.uiList:MoveToPos(moveIndex)
end



------------------------------------------------------------------
return UIMicPotAward