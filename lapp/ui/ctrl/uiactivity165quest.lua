---
--- Created by Administrator.
--- DateTime: 2025/5/26 10:42:06
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActivity165Quest:LWnd
local UIActivity165Quest = LxWndClass("UIActivity165Quest", LWnd)
------------------------------------------------------------------

local statusSortMap = {
	[0] = 2,
	[1] = 3,
	[2] = 1,
}


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActivity165Quest:UIActivity165Quest()
	---@type number 任务类型id
	self._taskId = nil
	self._pages = {}
	self._taskInfos = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActivity165Quest:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActivity165Quest:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActivity165Quest:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
end

function UIActivity165Quest:InitData()
	local sid = self:GetWndArg("sid")

	local subPage = self:GetWndArg("subPage")
	if subPage then
		sid = gModelActivity:GetSidByUniqueJump(subPage)
	end

	if not sid then return end

	self._sid = sid

	self._stateStr = {
		[0] = ccClientText(12206),
		[1] = ccClientText(12207),
		[2] = ccClientText(12214),
	}
	self._stateImg = {
		[0] = "public_btn_1_1",
		[1] = "public_btn_1_2",
		[2] = "public_btn_ash_1",
	}

	self._pageId = self:GetWndArg("pageId") or 1

	local taskId = self:GetWndArg("taskId")
	if taskId and taskId > 0 then
		self._taskId = taskId
	end

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIActivity165Quest:DisposeTasks()
	local taskIdsMap = {}
	local tabRPMap = {}
	local taskIdList = {}
	local sid = self._sid
	local pages = self._pages
	local pageId = self._pageId or 1
	---@type StructActivityPage
	local taskPage = pages and pages[pageId]
	---@type StructActivityEntry[]
	local entry = taskPage and taskPage.entry or {}
	local entryId,status
	for i,v in ipairs(entry) do
		entryId = v.entryId
		local cfg = gModelActivity:GetWebActivityEntryData(sid, pageId, entryId)
		if cfg then
			local goalData = v.goalData
			status = goalData and goalData.status or 0

			local moreInfo = checknumber(cfg.moreInfo)
			table.insert(taskIdList,moreInfo)
			if not tabRPMap[moreInfo] then
				if status == 1 then
					tabRPMap[moreInfo] = true
				end
			end

			local taskIds = taskIdsMap[moreInfo]
			if not taskIds then
				taskIds = {}
				taskIdsMap[moreInfo] = taskIds
			end
			table.insert(taskIds,{
				entry = v,
				name = cfg.name,
				desc = cfg.description,
				jumpDesc = cfg.jumpDesc,
				jumpId = checknumber(cfg.jumpId),
				status = status,
				entryId = entryId,
			})
		end
	end
	if not self._taskId and #taskIdList > 0 then
		self._taskId = taskIdList[1]
	end
	for k,v in pairs(taskIdsMap) do
		table.sort(v,function(a,b)
			local sortA = statusSortMap[a.status]
			local sortB = statusSortMap[b.status]
			if sortA ~= sortB then
				return sortA > sortB
			end
			return a.entryId < b.entryId
		end)
	end
	self._taskIdsMap = taskIdsMap
	self._tabRPMap = tabRPMap
end

function UIActivity165Quest:OnDrawItemCell(list, item, itemdata, itempos)
	local instanceId = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceId)
	if not itemCache then
		itemCache = {
			Icon = self:FindWndTrans(item,"CommonUI/Icon"),
			itemNum = self:FindWndTrans(item,"itemNum"),
		}
		self:SetComponentCache(instanceId,itemCache)
	end

	local count = itemdata.count
	local iconTrans = itemCache.Icon
	local baseClass = self:GetCommonIcon(instanceId)
	baseClass:Create(iconTrans)
	baseClass:SetCommonReward(itemdata.type,itemdata.itemId, count)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()

	self:SetWndText(itemCache.itemNum,LUtil.NumberCoversion(count))

	self:SetWndClick(iconTrans,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata,{ showSkinCode = true })
	end)
end

function UIActivity165Quest:OnActivityResp(pb)
end

function UIActivity165Quest:OnClickXXXBtnFunc()
end

function UIActivity165Quest:InitText()
	self:SetWndText(self.mLblBiaoti,ccClientText(45103))
end

function UIActivity165Quest:InitTaskList()
	local list = self:GetTaskList()
	local uiTaskList = self._uiTaskList
	if uiTaskList then
		uiTaskList:RefreshList(list)
	else
		uiTaskList = self:GetUIScroll("uiTaskList")
		self._uiTaskList = uiTaskList
		uiTaskList:Create(self.mTaskList, list, function(...) self:OnDrawTaskCell(...) end)
	end
end

function UIActivity165Quest:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	-- self:SetWndClick(self.mXXXBtn,function() self:OnClickXXXBtnFunc() end)
end

function UIActivity165Quest:OnClickTypeCell(itemdata)
	if self:CheckIsSelTaskId(itemdata) then return end

	self._taskId = itemdata.taskId

	local uiTypeList = self._uiTypeList
	if uiTypeList then
		local uiList = uiTypeList:GetList()
		uiList:RefreshList()
	end

	self:RefreshView()
end

function UIActivity165Quest:CheckIsTabRPShow(itemdata)
	local tabRPMap = self._tabRPMap or {}
	return tabRPMap[itemdata.taskId]
end

function UIActivity165Quest:OnDrawTaskCell(list, item, itemdata, itempos)
	local instanceId = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceId)
	if not itemCache then
		itemCache = {
			title = self:FindWndTrans(item, "TitleDiv/title"),
			progress = self:FindWndTrans(item, "progress"),
			Slider = self:FindWndTrans(item, "Slider"),
			itemList = self:FindWndTrans(item, "itemList"),
			AllGet = self:FindWndTrans(item, "AllGet"),
			button = self:FindWndTrans(item, "button"),
			text = self:FindWndTrans(item, "button/text"),
			unlockTip = self:FindWndTrans(item, "unlockTip"),
		}
		self:SetComponentCache(instanceId,itemCache)
	end

	---@type StructActivityEntry
	local entry = itemdata.entry
	local schedule,goal = 0,0
	---@type StructGoalData
	local goalData = entry and entry.goalData

	self:SetWndText(itemCache.title,itemdata.name)

	local createEff = false
	local isLock = false
	local isAllGet = false
	local state = goalData and goalData.status or 0
	if state == ModelQuest.TASK_UNFINISH then
	elseif state == ModelQuest.TASK_FINNISH then
		createEff = true
	elseif state == ModelQuest.TASK_REWARDED then
		isAllGet = true
	elseif state == ModelQuest.TASK_LOCK then
		isLock = true
	end

	local button = itemCache.button
	local showBtn = not isLock and not isAllGet
	if showBtn then
		if createEff then
			self:CreateWndEffect(button,"fx_shouchong_anniu_zhong",instanceId,100,nil,nil,nil,nil,nil,true)
		else
			self:DestroyWndEffectByKey(instanceId)
		end

		local color = "#5c6d9a"
		local btnName = self._stateStr[state]
		local jumpDesc = itemdata.jumpDesc
		if state == 0 then
			if not string.isempty(jumpDesc) then
				btnName = jumpDesc
			end
		elseif state == 1 then
			color = "#ffffff"
		end
		btnName = LUtil.FormatColorStr(btnName,color)
		self:SetWndText(itemCache.text,btnName)

		local jumpId = itemdata.jumpId
		self:SetWndClick(button,function()
			if state == 1 then
				gModelActivity:OnActivityReceiveGoalReq(self._sid, self._pageId, itemdata.entryId)
			else
				if jumpId and jumpId > 0 then
					local wndArgList = self:GetWndArgList()
					if wndArgList then
						wndArgList.taskId = self._taskId
					end
					gModelFunctionOpen:Jump(jumpId,self:GetWndName())
				else
					if LOG_INFO_ENABLED then
						printInfoNR2("活动165打印：","暂无配置 jumpId")
					end
				end
			end
		end)
	end

	if not isAllGet then
		local imgPath = self._stateImg[state]
		self:SetBtnImageAndMat(button,imgPath)
	end

	CS.ShowObject(button,showBtn)

	CS.ShowObject(itemCache.AllGet,isAllGet)


	local schedules = goalData and goalData.schedules
	if schedules and #schedules > 0 then
		---@type StructGoalSchedule
		local schedule1 = schedules[1]
		schedule,goal = checknumber(schedule1.schedule),checknumber(schedule1.goal)
	end
	local value = 0
	if goal > 0 then
		value = schedule/goal
	end
	LxUiHelper.SetProgress(itemCache.Slider,value)

	local isStandards = goal > 0 and schedule >= goal or false
	local color = isStandards and "green" or "black"
	local progressStr = string.replace("#a1#/#a2#",
			LUtil.NumberCoversion(schedule),LUtil.NumberCoversion(goal))
	local str = LUtil.FormatColorStr(progressStr,color)
	self:SetWndText(itemCache.progress,str)

	self:InitItemList(itemCache.itemList,entry.items)
end

function UIActivity165Quest:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	-- self:WndNetMsgRecv(LProtoIds.xxxxx,function(...) self:OnMsgXXXXX(...) end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function(pb) self:OnActivityListResp(pb) end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
end

function UIActivity165Quest:GetTaskList()
	local list = {}
	local taskId = self._taskId
	if taskId and taskId > 0 then
		local taskIdsMap = self._taskIdsMap
		if taskIdsMap and taskIdsMap[taskId] then
			list = taskIdsMap[taskId]
		end
	end
	return list
end

function UIActivity165Quest:OnActivityPageResp(pb)
	local sid = pb.sid
	if sid ~= self._sid then return end

	local pages = self._pages
	if not pages then
		pages = {}
		self._pages = pages
	end
	for i, v in ipairs(pb.pages) do
		---@type StructActivityPage
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		pages[page.pageId] = page
	end
	self:DisposeTasks()

	self:InitTypeList()
	self:RefreshView()
end

function UIActivity165Quest:OnDrawTypeCell(list, item, itemdata, itempos)
	local instanceId = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceId)
	if not itemCache then
		itemCache = {
			BtnTab1 = self:FindWndTrans(item, "BtnTab1"),
			redPointTrans = self:FindWndTrans(item, "redPoint"),
		}
		self:SetComponentCache(instanceId,itemCache)
	end
	local BtnTab1 = itemCache.BtnTab1
	self:SetWndTabText(BtnTab1,itemdata.taskName)

	local state = self:CheckIsSelTaskId(itemdata) and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(BtnTab1, state)

	CS.ShowObject(itemCache.redPointTrans,self:CheckIsTabRPShow(itemdata))

	self:SetWndClick(BtnTab1, function() self:OnClickTypeCell(itemdata) end)
end

function UIActivity165Quest:CheckIsSelTaskId(itemdata)
	return itemdata.taskId == self._taskId
end

function UIActivity165Quest:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:SetContent()
	gModelActivity:OnActivityPageReq(sid)
end





---@param list StructRewardItem[]
function UIActivity165Quest:InitItemList(listObj,list)
	list = list or {}
	local instanceId = listObj:GetInstanceID()
	local uiList = self:FindUIScroll(instanceId)
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll(instanceId)
		uiList:Create(listObj, list, function(...) self:OnDrawItemCell(...) end)
	end
end


function UIActivity165Quest:RefreshView()
	self:InitTaskList()
end

function UIActivity165Quest:OnActivityListResp(pb)
end

function UIActivity165Quest:SetContent()
	local webData = gModelActivity:GetWebActivityDataById(self._sid)
	if not webData then return end

	local config = webData.config
	local taskInfos = {}
	local taskTab = string.split(config.taskTab,"|")
	for i,v in ipairs(taskTab) do
		v = string.split(v,"=")
		table.insert(taskInfos,{
			taskId = checknumber(v[1]),
			taskName = v[2],
		})
	end
	self._taskInfos = taskInfos
end

function UIActivity165Quest:InitTypeList()
	local list = self._taskInfos or {}
	if not self._taskId and #list > 0 then
		self._taskId = list[1].taskId
	end
	local uiTypeList = self._uiTypeList
	if uiTypeList then
		uiTypeList:RefreshList(list)
	else
		uiTypeList = self:GetUIScroll("uiTypeList")
		self._uiTypeList = uiTypeList
		uiTypeList:Create(self.mTypeList, list, function(...) self:OnDrawTypeCell(...) end)
	end
end

------------------------------------------------------------------
return UIActivity165Quest