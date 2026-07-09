---
--- Created by BY.
--- DateTime: 2023/10/30 14:47:37
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActLotteryTkPop:LWnd
local UIActLotteryTkPop = LxWndClass("UIActLotteryTkPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActLotteryTkPop:UIActLotteryTkPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActLotteryTkPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActLotteryTkPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActLotteryTkPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMessage()
	self:InitCommon()
end
function UIActLotteryTkPop:GetCurItem(entry)
	local curLv = nil
	for i, v in ipairs(entry) do
		local goalData = v.goalData
		local status = goalData.status
		if status ~= 2 then
			curLv = v
			break
		end
	end
	if not curLv then
		curLv = entry[#entry]
	end
	return curLv
end
function UIActLotteryTkPop:RefreshData()
	local _pages = self.pages or {}
	local _page = _pages[self._roomTaskEnum]
	if not _page then return end
	local list = _page.entry

	table.sort(list,function (a,b)
		local aStatus = a.goalData.status
		local bStatus = b.goalData.status
		local aSort = aStatus == 1 and -1 or aStatus
		local bSort = bStatus == 1 and -1 or bStatus
		if aSort ~= bSort then
			return aSort < bSort
		end
		return a.entryId < b.entryId
	end)
	local len = #list
	local num = 0
	local isGet = false
	for i, v in ipairs(list) do
		local status = v.goalData.status
		if status > 0 then
			num = num + 1
		end
		if status == 1 then
			isGet = true
		end
	end
	self:SetWndText(self.mTitleText,string.replace(ccClientText(27654),num,len))
	self:SetWndButtonGray(self.mBtnOnKey,not isGet)

	local _uiTaskList = self._uiTaskList
	if not _uiTaskList then
		_uiTaskList = self:GetUIScroll("UIActLotteryTkPop_task")
		self._uiTaskList = _uiTaskList
		_uiTaskList:Create(self.mTaskSuper,list,function (...) self:ListItem(...) end, UIItemList.SUPER)
	else
		_uiTaskList:RefreshList(list)
	end
	_uiTaskList:DrawAllItems()
end
function UIActLotteryTkPop:ResetData(pb)
	local pages = self.pages or {}
	for i, v in ipairs(pb.pages) do
		if self._roomTaskEnum == v.pageId then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			pages[v.pageId] = page
		end
	end
	self.pages = pages
	self:RefreshData()
end

function UIActLotteryTkPop:OnActivityConfigData()

end

function UIActLotteryTkPop:ListItem(list, item, itemdata, itempos)
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local root = self:FindWndTrans(item,"Root")
	local titleText = self:FindWndTrans(root,"TitleBg/TitleText")
	local numText = self:FindWndTrans(root,"NumText")
	local itemScroll = self:FindWndTrans(root,"ItemScroll")
	local btnGet = self:FindWndTrans(root,"BtnGet")
	local mask = self:FindWndTrans(root,"Mask")
	local eff = self:FindWndTrans(root,"Eff")

	local InstanceID = item:GetInstanceID()
	local reward = entryCfg.reward
	local name = entryCfg.name
	local goalData = itemdata.goalData
	local status = goalData.status
	local schedules = goalData.schedules
	local schedule = schedules[1]

	CS.ShowObject(eff,status == 1)
	if status == 1 then
		self:CreateWndEffect(eff,"fx_anniu_02",InstanceID,100,false,false)
	end
	CS.ShowObject(btnGet,status ~= 2)
	CS.ShowObject(mask,status == 2)
	self:SetWndButtonText(btnGet,entryCfg.jumpDesc)
	self:SetWndButtonGray(btnGet,status == 0)
	if schedule then
		local scheduleStr = schedule.schedule
		local goalStr = schedule.goal
		self:SetWndText(titleText,string.replace(name,LUtil.FormatColorStr(goalStr,"green")))
		local str = string.format("(%s/%s)",scheduleStr,goalStr)
		if scheduleStr == goalStr and status == 1 then
			str = LUtil.FormatColorStr(str,"green")
		elseif status == 0 then
			scheduleStr = LUtil.FormatColorStr(scheduleStr,"red")
			str = string.format("(%s/%s)",scheduleStr,goalStr)
		end
		self:SetWndText(numText,str)
	end

	local rewardList = LxDataHelper.ParseItem(reward)
	local uiList1 = self._uiTaskList:GetItemCls(InstanceID)
	if not uiList1 then
		uiList1 = UIIconEasyList:New(self)
		self._uiTaskList:SetItemCls(InstanceID, uiList1)
		uiList1:Create(self, itemScroll)
		uiList1:SetIconParentPath("Root/CommonUI/Icon")
	end
	uiList1:RefreshList(rewardList)

	self:SetWndClick(btnGet,function ()
		if status == 1 then
			gModelActivity:OnActivityReceiveGoalReq(self._sid,itemdata.pageId,itemdata.entryId)
		else
			--local jumpId = entryCfg.jumpId
			--if jumpId and jumpId > 0 then
			--	local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId,true)
			--	if isOpen then
			--		local wndName = self:GetWndName()
			--		gModelFunctionOpen:Jump(jumpId,wndName)
			--	end
			--end
			GF.ShowMessage(ccClientText(12210))
		end
	end)
end

function UIActLotteryTkPop:OnTryTcpReconnect()
	self:WndClose()
end
function UIActLotteryTkPop:InitData()
	self._modelEnumList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = ModelActivity.SWEET_COUNTRY_22,
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_96] = ModelActivity.MOTIF_ACTIVITY_LOTTERY_6,
	}

	self:SetWndText(self.mLblBiaoti,ccClientText(27653))
	self:SetWndButtonText(self.mBtnOnKey,ccClientText(27655))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
end
function UIActLotteryTkPop:InitEvent()
	self:SetWndClick(self.mBg,function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnOnKey, function() self:OnClickOnKey() end, LSoundConst.CLICK_BUTTON_COMMON)
end

function UIActLotteryTkPop:OnClickOnKey()
	local list = {}
	local _pages = self.pages or {}
	local _page = _pages[self._roomTaskEnum]
	if not _page then return end
	local entry = _page.entry
	for i, v in ipairs(entry) do
		local status = v.goalData.status
		if status == 1 then
			table.insert(list,{sid = self._sid,pageId = v.pageId,entryId = v.entryId})
		end
	end
	if #list <= 0 then
		GF.ShowMessage(ccClientText(27662))
		return
	end
	gModelActivity:OnActivityReceiveGoalListReq(list)
end
function UIActLotteryTkPop:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...) self:OnActivityConfigData(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
end
function UIActLotteryTkPop:InitCommon()
	local sid = self:GetWndArg("sid")
	local pages 	= self:GetWndArg("pages")
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._sid = sid
	self.pages = pages
	self._roomTaskEnum = self._modelEnumList[modelId]
	self:RefreshData()
end
------------------------------------------------------------------
return UIActLotteryTkPop


