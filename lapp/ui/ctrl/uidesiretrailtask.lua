---
--- Created by wzz.
--- DateTime: 2024/9/13 9:47:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDesireTrailTask:LWnd
local UIDesireTrailTask = LxWndClass("UIDesireTrailTask", LWnd)
------------------------------------------------------------------

local TabDataList = {
	[1] = { tabName = ccClientText(45426), taskType = gModelDesireTrail.TaskType.Daily }, --183
	[2] = { tabName = ccClientText(45427), taskType = ModelDesireTrail.TaskType.Target }, --184
}

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDesireTrailTask:UIDesireTrailTask()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDesireTrailTask:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDesireTrailTask:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDesireTrailTask:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:InitTexts()
	self:InitEvents()
	self:InitTab()
	self:Refresh()
end

-- tab item
function UIDesireTrailTask:OnDrawTabItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			root   = item,
			btnTab = CS.FindTrans(item, "BtnTab1"),

		}
		self:SetComponentCache(instanceID, itemCache)
	end

	local taskType = itemdata.taskType

	self:SetWndTabStatus(itemCache.btnTab, self._taskType ~= taskType and 1 or 0)
	self:SetWndTabText(itemCache.btnTab, itemdata.tabName)
	self:SetWndClick(itemCache.btnTab, function()
		if self._taskType == taskType then
			return
		end
		self._taskType = taskType
		list:DrawAllItems()
		self:Refresh()
	end)
	self:SetRed(item, gModelDesireTrail:HadTaskRed(taskType))
end

-- 初始化数据
function UIDesireTrailTask:InitData()
	self._taskType = TabDataList[1].taskType
	self._taskList = {}
end

-- 初始事件
function UIDesireTrailTask:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)
	self:WndEventRecv(EventNames.ON_QUEST_CHANGE, function(...)
		self._taskList = {}
		self:Refresh()

		local uilist = self:GetUIScroll("mTabScroll")
		uilist:DrawAllItems()
	end)
end

-- 初始tab
function UIDesireTrailTask:InitTab()
	local uilist = self:GetUIScroll("mTabScroll")
	uilist:Create(self.mTabScroll, TabDataList, function(...)
		self:OnDrawTabItem(...)
	end)
end

-- 点击按钮
function UIDesireTrailTask:OnClickBtn(refId)
	gModelQuest:OnQuestReceiveReq(refId)
end

-- 列表 item
function UIDesireTrailTask:OnDrawListItem(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			txtTitle = CS.FindTrans(item, "AniRoot/Img0/TxtTitle"),
			itemList = CS.FindTrans(item, "AniRoot/ItemList"),
			button   = CS.FindTrans(item, "AniRoot/Button"),
			txtNum   = CS.FindTrans(item, "AniRoot/TxtNum"),
			hadGet   = CS.FindTrans(item, "AniRoot/HadGet"),
		}
		self:SetComponentCache(instanceID, itemCache)

		self:SetWndButtonText(itemCache.button, ccClientText(45428))
	end

	local refId = itemdata:GetRefId()
	local cfg = gModelQuest:GetTaskConfig(refId)

	local itemList = gModelQuest:GetRewardList(refId)
	-- self:InitItemList(itemCache.itemList, itemList)
	self:InitItemList2(itemCache.itemList, itemList)

	local state = itemdata:GetState()
	local hadGet = state == ModelQuest.TASK_REWARDED
	local canGet = state == ModelQuest.TASK_FINNISH
	self:SetWndClick(itemCache.button, function() self:OnClickBtn(refId) end)
	CS.ShowObject(itemCache.button, canGet)
	CS.ShowObject(itemCache.hadGet, hadGet)
	self:ShowBtnEff(itemCache.button, instanceID, canGet)

	local strValue = ""
	if not hadGet then
		local num = tonumber(itemdata:GetSchedule())
		local maxNum = tonumber(itemdata:GetGoal())
		if num >= maxNum then
			strValue = ccClientText(45437, num, maxNum)
		else
			strValue = ccClientText(45437, num, maxNum)
		end
	end

	self:SetWndText(itemCache.txtTitle, ccLngText(cfg.description) .. strValue)

	-- self:SetWndText(itemCache.txtNum, strValue)
end

-- 获取任务列表
function UIDesireTrailTask:GetTaskList(taskType)
	taskType = taskType or self._taskType
	if self._taskList[taskType] then
		return self._taskList[taskType]
	end

	local list = gModelQuest:GetTaskList(taskType)
	self._taskList[taskType] = list
	return list
end

-- 初始化item列表
function UIDesireTrailTask:InitItemList2(root, itemList)
	local instanceID = root:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {}
		local uiList = UIIconEasyList:New()
		uiList:Create(self, root)
		uiList:SetShowNum(true)
		uiList:SetIconParentPath("itemRoot")
		-- uiList:SetShowExtraNum(true, "itemNum")

		itemCache.uiList = uiList
		self:SetComponentCache(instanceID, itemCache)
	end
	itemCache.uiList:RefreshList(itemList)
end

-- 初始界面化文本
function UIDesireTrailTask:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(45425))
	self:SetWndText(self.mCloseTip, ccClientText(10103))
end

-- 刷新界面
function UIDesireTrailTask:Refresh()
	local dataList = self:GetTaskList()
	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList
		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList:ResetList(dataList)
		self._uiList:DrawAllItems()
	end
end

------------------------------------------------------------------
return UIDesireTrailTask