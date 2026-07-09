---
--- Created by Administrator.
--- DateTime: 2024/5/27 20:58:19
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubNewAct18Tk:LChildWnd
local UISubNewAct18Tk = LxWndClass("UISubNewAct18Tk", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubNewAct18Tk:UISubNewAct18Tk()
	self.statePriority = {
		[0] = 2,
		[1] = 1,
		[2] = 3,
	}
	self.rewardIconUIList = {}
	self.commonUIList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubNewAct18Tk:OnWndClose()
	self:ClearCommonIconList(self.rewardIconUIList)
	self:ClearCommonIconList(self.commonUIList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubNewAct18Tk:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubNewAct18Tk:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
end

function UISubNewAct18Tk:DrawRewardIcon(_, item, data)
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

function UISubNewAct18Tk:InitEvent()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		if pb.sid ~= self.sid then
			return
		end
		self:OnActivityPageResp(pb)
	end)
end

function UISubNewAct18Tk:InitData()
	self.cfg = self:GetWndArg("cfg")
	self.sid = self:GetWndArg("sid")

	gModelActivity:OnActivityPageReq(self.sid)
end

function UISubNewAct18Tk:OnDrawItem(_, item, data)
	local titleBg = self:FindWndTrans(item, "TitleBg")
	local titleText = self:FindWndTrans(titleBg, "TitleText")
	local numText = self:FindWndTrans(item, "NumText")
	local btn = self:FindWndTrans(item, "Btn")
	local rewardList = self:FindWndTrans(item, "RewardList")
	local isGet = self:FindWndTrans(item, "IsGet")

	local times, schedule, status = data.times, data.schedule, data.status
	local pass = times <= schedule
	local color = pass and "0fb93f" or "c81212"
	local str = string.replace(ccClientText(16211), color, schedule, times)
	self:SetWndText(numText, str)

	self:SetWndText(titleText, data.title)

	local btnstr = status == 0 and ccClientText(14003) or ccClientText(14007)
	local color = status == 0 and "#5C6D9A" or "#FFFFFF"
	btnstr = string.replace("<color=#a1#>#a2#</color>", color, btnstr)
	local btnImg = status == 0 and "public_btn_2_1" or "public_btn_2_2"
	self:SetWndButtonText(btn, btnstr)
	self:SetWndButtonImg(btn, btnImg)
	self:SetWndButtonImg(btn, btnImg)
	CS.ShowObject(btn, status ~= 2)
	CS.ShowObject(isGet, status == 2)

	if status == 1 then
		self:CreateWndEffect(btn, "fx_anniu_02", "btnEff" .. item:GetInstanceID(), 100)
	else
		self:DestroyWndEffectByKey("btnEff" .. item:GetInstanceID())
	end

	self:SetWndClick(btn, function()
		if status == 0 then
			if gModelFunctionOpen:CheckIsOpened(data.jumpId, true) then
				gModelFunctionOpen:Jump(data.jumpId)
			end
		elseif status == 1 then
			gModelActivity:OnActivityReceiveGoalReq(self.sid, self.pageId, data.entryId)
		end
	end)

	local InstanceID = item:GetInstanceID()

	local x = math.min(#data.rewards * 90, 360)
	rewardList.sizeDelta = Vector2.New(x, 90)
	if self.rewardIconUIList[InstanceID] then
		self.rewardIconUIList[InstanceID]:RefreshList(data.rewards)
		self.rewardIconUIList[InstanceID]:DrawAllItems()
	else
		self.rewardIconUIList[InstanceID] = self:GetUIScroll("rewardIconUIList" .. InstanceID)
		self.rewardIconUIList[InstanceID]:Create(rewardList, data.rewards, function(...) self:DrawRewardIcon(...) end, UIItemList.SUPER_GRID)
	end
end

function UISubNewAct18Tk:OnActivityPageResp(pb)
	if not pb.pages[1] then
		return
	end
	local page = StructActivityPage:New()
	page:CreateByPb(pb.pages[1])
	self.pageId = page.pageId

	local dataList = {}
	for _, v in ipairs(page.entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(page.sid, v.pageId, v.entryId)
		if entryCfg then
			local data = {}
			data.entryId = v.entryId
			data.title = entryCfg.name
			data.rewards = LxDataHelper.ParseItem(entryCfg.reward)
			data.status = v.goalData.status
			data.sort = entryCfg.sort
			--会掺杂其他的任务数据--跳转的时候--这里进行过滤
			if v.goalData.schedules[1] then
				data.schedule = tonumber(v.goalData.schedules[1].schedule)
				data.times = tonumber(v.goalData.schedules[1].goal)
				data.jumpId = tonumber(entryCfg.jumpId)
				table.insert(dataList, data)
			end
		end
	end
	table.sort(dataList, function(a, b)
		local aPrio = self.statePriority[a.status] or 1
		local bPrio = self.statePriority[b.status] or 1
		if aPrio ~= bPrio then return aPrio < bPrio end
		return a.sort < b.sort
	end)

	if self.taskList then
		self.taskList:RefreshList(dataList)
		self.taskList:DrawAllItems()
	else
		self.taskList = self:GetUIScroll("mTaskList")
		self.taskList:Create(self.mTaskList, dataList, function(...) self:OnDrawItem(...) end, UIItemList.SUPER)
	end
end



------------------------------------------------------------------
return UISubNewAct18Tk