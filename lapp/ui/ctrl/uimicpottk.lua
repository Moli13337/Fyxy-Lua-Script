---
--- Created by Administrator.
--- DateTime: 2024/9/24 10:51:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMicPotTk:LWnd
local UIMicPotTk = LxWndClass("UIMicPotTk", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMicPotTk:UIMicPotTk()
	self.rewardIconUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMicPotTk:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMicPotTk:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMicPotTk:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:UpdateTaskList()
end

function UIMicPotTk:DrawRewardIcon(_, item, data)
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

function UIMicPotTk:DrawTask(_, item, data)
	local title = CS.FindTrans(item, "Title")
	local proText = CS.FindTrans(item, "ProText")
	local proImg = CS.FindTrans(item, "ProBg/ProImg")
	local itemList = CS.FindTrans(item, "ItemList")
	local btn = CS.FindTrans(item, "Btn")
	local isGet = CS.FindTrans(item, "IsGet")
	local unFinish = CS.FindTrans(item, "UnFinish")

	local cfg = gModelQuest:GetTaskConfig(data._refId)

	self:SetWndText(title, ccLngText(cfg.description))
	local str = "<color=#a1#>#a2#/#a3#</color>"
	local color = data._state == 0 and "#9f835c" or "#139057"
	local schedule, goal = tonumber(data._schedule), tonumber(data._goal)
	self:SetWndText(proText, string.replace(str, color, schedule, goal))
	local len = 520 * schedule / goal
	proImg.sizeDelta = Vector2.New(len, 14)

	self:SetWndButtonText(btn, ccClientText(12207))
	local instanceID = item:GetInstanceID()
	if data._state == 1 then
		self:CreateWndEffect(btn, "fx_anniu_03", instanceID, 100)
	else
		self:DestroyWndEffectByKey(instanceID)
	end

	CS.ShowObject(unFinish, data._state == 0)
	CS.ShowObject(btn, data._state == 1)
	CS.ShowObject(isGet, data._state == 2)

	local rewards = LxDataHelper.ParseItem(cfg.reward)
	local InstanceID = item:GetInstanceID()
	local x = math.min(#rewards * 65 + (#rewards - 1) * 4, 272)
	itemList.sizeDelta = Vector2.New(x, 65)
	if self.rewardIconUIList[InstanceID] then
		self.rewardIconUIList[InstanceID]:RefreshList(rewards)
		self.rewardIconUIList[InstanceID]:DrawAllItems()
	else
		self.rewardIconUIList[InstanceID] = self:GetUIScroll("rewardIconUIList" .. InstanceID)
		self.rewardIconUIList[InstanceID]:Create(itemList, rewards, function(...) self:DrawRewardIcon(...) end, UIItemList.SUPER_GRID)
	end

	self:SetWndClick(btn, function()
		if data._state == 1 then
			gModelQuest:OnQuestReceiveReq(data._refId)
		end
	end)
end

function UIMicPotTk:UpdateTaskList()
	local list = gModelQuest:GetTaskListByTypeList({182})
	if self.taskList then
		self.taskList:RefreshList(list)
		self.taskList:DrawAllItems()
	else
		self.taskList = self:GetUIScroll("mTaskList")
		self.taskList:Create(self.mTaskList, list, function(...) self:DrawTask(...) end, UIItemList.SUPER)
	end
end

function UIMicPotTk:InitCommon()
	-----------------------------------------------
	---Text
	self:SetWndText(self.mLblBiaoti, ccClientText(45803))
	self:SetWndText(self.mCloseTip, ccClientText(10103))

	-----------------------------------------------
	---Click
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)

	-----------------------------------------------
	---Event
	self:WndEventRecv(EventNames.ON_QUEST_CHANGE, function()
		self:UpdateTaskList()
	end)
end



------------------------------------------------------------------
return UIMicPotTk