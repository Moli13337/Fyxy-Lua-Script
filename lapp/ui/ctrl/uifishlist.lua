---
--- Created by wzz.
--- DateTime: 2024/7/4 17:49:30
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishList:LWnd
local UIFishList = LxWndClass("UIFishList", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishList:UIFishList()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishList:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishList:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishList:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._curRef = gModelFish:GetCurRef()
	self._maxUnlockRefId = gModelFish:GetMaxUnlockRefId()

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
end

-- 初始事件
function UIFishList:InitEvents()
	self:SetWndClick(self.mCloseBtn, function() self:OnBtnReturn() end)
	self:WndEventRecv(EventNames.FISH_BASE_INFO, function(...) self:Refresh(...) end)
end

-- 点击item
function UIFishList:OnClickItem(ref)
	-- if ref.refId > self._maxUnlockRefId + 1 then
	-- 	GF.ShowMessage(ccClientText(44212))
	-- 	return
	-- end

	-- if ref.refId == self._maxUnlockRefId + 1 then
	-- 	local conditionList = gModelFish:GetConditionList(ref.refId)
	-- 	for i, data in ipairs(conditionList) do
	-- 		local finish = gModelQuest:IsTaskFinish(data.questRefId)
	-- 		if not finish then
	-- 			local questRef = gModelQuest:GetTaskConfig(data.questRefId)
	-- 			GF.ShowMessage(ccLngText(questRef.description))
	-- 			return
	-- 		end
	-- 	end
	-- end

	GF.OpenWnd("UIFishFarmDetail", { refId = ref.refId })
	if gModelFish:HadRedFishFarmByRefId(ref.refId) then
		gModelFish:SaveLookFishFarm(ref.refId)
		FireEvent(EventNames.FISH_BASE_INFO)
	end
end

-- 刷新界面
function UIFishList:Refresh()
	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList

		local dataList = gModelFish:GetAllFishRefList()
		self._uiDataList = dataList
		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList:DrawAllItems()
	end
end

-- 点击返回
function UIFishList:OnBtnReturn()
	self:WndClose()
end

-- 初始界面化文本
function UIFishList:InitTexts()
	self:SetWndText(self.mTxtClose, ccClientText(42010))
	self:SetWndText(self.mTitle, ccClientText(44207))
end

-- 绘制列表item项
function UIFishList:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			root      = CS.FindTrans(item, "AniRoot"),
			txtTitle  = CS.FindTrans(item, "AniRoot/TxtTitle"),
			lock      = CS.FindTrans(item, "AniRoot/Lock"),
			cur       = CS.FindTrans(item, "AniRoot/Cur"),
			condition = CS.FindTrans(item, "AniRoot/Condition"),
		}

		itemCache.uiList = {}
		for i = 1, 3 do
			local tab           = {}
			tab.txt             = CS.FindTrans(item, "AniRoot/Condition/" .. i)
			tab.lock            = CS.FindTrans(tab.txt, "Lock")
			tab.unLock          = CS.FindTrans(tab.txt, "UnLock")

			itemCache.uiList[i] = tab
		end

		self:SetComponentCache(instanceID, itemCache)
		self:SetTextTile(itemCache.lock, ccClientText(44212))
		self:SetTextTile(itemCache.cur, ccClientText(44213))
	end
	local ref = itemData
	self:SetWndText(itemCache.txtTitle, ccLngText(ref.name))
	self:SetWndEasyImage(itemCache.root, ref.cell)

	local isCur = ref.refId == self._curRef.refId
	CS.ShowObject(itemCache.cur, isCur)

	self:SetRed(itemCache.root, gModelFish:HadRedFishFarmByRefId(ref.refId))

	local showCondition = false

	if ref.refId == self._maxUnlockRefId + 1 then
		local conditionList = gModelFish:GetConditionList(ref.refId)
		showCondition = #conditionList > 0
		for i, tab in ipairs(itemCache.uiList) do
			local data = conditionList[i] or {}
			local questRef = gModelQuest:GetTaskConfig(data.questRefId)
			if data and questRef then
				local finish = false
				local str = ""
				local data = gModelQuest:GetTaskDataByRefId(data.questRefId)
				if data then
					local schedule = tonumber(data:GetSchedule())
					local goal = tonumber(data:GetGoal())
					str = ccClientText(44332, schedule, goal)
					finish = schedule >= goal
				end

				CS.ShowObject(tab.lock, not finish)
				CS.ShowObject(tab.unLock, finish)
				self:SetWndText(tab.txt, ccLngText(questRef.description) .. str)
			end
			CS.ShowObject(tab.txt, data ~= nil)
		end
	end

	CS.ShowObject(itemCache.condition, showCondition)
	CS.ShowObject(itemCache.lock, ref.refId > self._maxUnlockRefId + 1)

	self:SetWndClick(itemCache.root, function()
		self:OnClickItem(itemData)
	end)
end

------------------------------------------------------------------
return UIFishList