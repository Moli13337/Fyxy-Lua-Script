---
--- Created by Administrator.
--- DateTime: 2025/12/1 17:25:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInviteFriends:LWnd
local UIInviteFriends = LxClass("UIInviteFriends", LWnd)
------------------------------------------------------------------

local StateSortMap = {
	[ModelQuest.TASK_UNFINISH] = 1,
	[ModelQuest.TASK_FINNISH] = 0,
	[ModelQuest.TASK_REWARDED] = 2,
}


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInviteFriends:UIInviteFriends()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInviteFriends:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInviteFriends:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInviteFriends:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UIInviteFriends:OnMsgXXXXX()
end

function UIInviteFriends:OnClickBtnGet(itemdata)
	gModelQuest:OnQuestReceiveReq(itemdata.refId)
end

function UIInviteFriends:OnClickBtnGoto(itemdata)
	local invitedCnt = self._invitedCnt
	if invitedCnt then
		local clickInviteCnt = checknumber(LPlayerPrefs.clickInviteCnt) or 0
		local newClickInviteCnt = clickInviteCnt + 1
		LPlayerPrefs.SetClickInviteCnt(newClickInviteCnt)
		FireEvent(EventNames.CLICK_INTIVE_FRIEND_BTN,newClickInviteCnt,invitedCnt)
	end
	gLSdkImpl:CallMethod(LSdkMethod.Share,"invite")
end

function UIInviteFriends:GetTaskList()
	local taskList = gModelQuest:GetInviteFriendTakes()
	local invitedCnt = 0
	local taskCnt = #taskList
	if taskCnt > 0 then
		local lastTask = taskList[taskCnt]
		---@type StructTask
		local serverData = lastTask.serverData
		invitedCnt = serverData:GetSchedule()
	end
	self._invitedCnt = invitedCnt
	self:SetWndText(self.mInviteNum,string.replace(ccClientText(23518),invitedCnt))

	local list = {}
	for i,v in ipairs(taskList) do
		table.insert(list,v)
	end
	table.sort(list,function(a,b)
		if a.state ~= b.state then
			return StateSortMap[a.state] < StateSortMap[b.state]
		end
		return a.sort < b.sort
	end)

	return list
end


function UIInviteFriends:InitRewardList(listTrans,list)
	local key = listTrans:GetInstanceID()
	local uiList = self:FindUIScroll(key)
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(listTrans, list, function(...) self:OnDrawRewardCell(...) end)
	end
end

function UIInviteFriends:OnClickIconFunc(itemdata)
	gModelGeneral:ShowCommonItemTipWnd(itemdata)
end

function UIInviteFriends:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	-- self:WndNetMsgRecv(LProtoIds.xxxxx,function(...) self:OnMsgXXXXX(...) end)
	self:WndEventRecv(EventNames.ON_QUEST_CHANGE, function() self:RefreshView() end)
end


function UIInviteFriends:InitData()
end

function UIInviteFriends:OnClickXXXBtnFunc()
end

function UIInviteFriends:OnDrawTaskCell(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		local BarBg = self:FindWndTrans(item,"BarBg")
		itemCache = {
			Title = self:FindWndTrans(item,"Title"),
			BarBg = BarBg,
			Bar = self:FindWndTrans(BarBg,"Bar"),
			RewardList = self:FindWndTrans(item,"RewardList"),
			BtnGoto = self:FindWndTrans(item,"BtnGoto"),
			BtnGet = self:FindWndTrans(item,"BtnGet"),
			AlreadyGet = self:FindWndTrans(item,"AlreadyGet"),
			Schedule = self:FindWndTrans(item,"Schedule"),
		}
		self:SetComponentCache(instanceID, itemCache)
	end
	---@type V_QuestRef
	local cfg = itemdata.cfg
	---@type StructTask
	local serverData = itemdata.serverData

	self:SetWndText(itemCache.Title,ccLngText(cfg.description))


	local schedule = serverData:GetSchedule()
	local goal = serverData:GetGoal()
	local scheduleStr = string.replace("#a1#/#a2#",schedule,goal)
	local state = serverData:GetState()
	local isUnFinish = state == ModelQuest.TASK_UNFINISH
	if not isUnFinish then
		scheduleStr = LUtil.FormatColorStr(scheduleStr,"#139057")
	end
	self:SetWndText(itemCache.Schedule,scheduleStr)

	local percent = schedule / goal
	LxUiHelper.SetProgress(itemCache.Bar,percent)


	local BtnGoto = itemCache.BtnGoto
	self:SetWndButtonText(BtnGoto,ccClientText(23503))
	CS.ShowObject(BtnGoto,isUnFinish)

	local BtnGet = itemCache.BtnGet
	self:SetWndButtonText(BtnGet,ccClientText(23501))
	CS.ShowObject(BtnGet,state == ModelQuest.TASK_FINNISH)

	CS.ShowObject(itemCache.AlreadyGet,state == ModelQuest.TASK_REWARDED)

	self:InitRewardList(itemCache.RewardList,itemdata.reward or {})

	self:SetWndClick(BtnGoto,function() self:OnClickBtnGoto(itemdata) end)
	self:SetWndClick(BtnGet,function() self:OnClickBtnGet(itemdata) end)
end

function UIInviteFriends:OnDrawRewardCell(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			Icon = self:FindWndTrans(item,"CommonUI/Icon"),
		}
		self:SetComponentCache(instanceID, itemCache)
	end
	local Icon = itemCache.Icon
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(itemdata.itemType,itemdata.itemId, itemdata.itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()
	self:SetWndClick(Icon,function()
		self:OnClickIconFunc(itemdata)
	end)
end

function UIInviteFriends:InitEvent()
	--- 返回按钮必备
	-- self:SetWndClick(self.mReturnBtn,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mMask,function() self:WndClose() end)
end

function UIInviteFriends:InitText()
end

function UIInviteFriends:InitTaskList()
	local list = self:GetTaskList()

	local uiTaskList = self._uiTaskList
	if uiTaskList then
		uiTaskList:RefreshList(list)
	else
		uiTaskList = self:GetUIScroll("uiTaskList")
		uiTaskList:Create(self.mTaskList, list, function(...) self:OnDrawTaskCell(...) end,UIItemList.WRAP)
	end
end

function UIInviteFriends:OnEventXXXXX()
end

function UIInviteFriends:RefreshView()
	self:InitTaskList()
end

------------------------------------------------------------------
return UIInviteFriends