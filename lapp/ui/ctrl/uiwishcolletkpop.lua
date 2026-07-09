---
--- Created by BY.
--- DateTime: 2023/10/24 14:48:43
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWishColleTkPop:LWnd
local UIWishColleTkPop = LxWndClass("UIWishColleTkPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWishColleTkPop:UIWishColleTkPop()
	self._uiCommonIconList = {}
	self._tabTransList = {}
	self._timeKey = "taskTimeKey"
	self._redList = {}
	self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWishColleTkPop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWishColleTkPop:OnCreate()
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWishColleTkPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIWishColleTkPop:InitEvent()
	--self:SetWndClick(self.mBgImage,function () self:WndClose() end)
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:OnClickClose() end)
	self:SetWndClick(self.mBtnHelp, function(...) self:OnClickHelp() end)
end

function UIWishColleTkPop:RefreshDate()
	local _type = self._type
	local ref = self.ref
	local _schoolInfo = self._schoolInfo
	local questStr = ""
	if _type == 1 then
		questStr = ref.questDay
	else
		questStr = ref.questWeek
	end
	if questStr == "" then
		return
	end
	local questList = _schoolInfo.questList
	local yetReceiveNum = 0
	for i, v in pairs(questList) do
		if v.questType == _type then
			yetReceiveNum = yetReceiveNum + 1
		end
	end
	self._yetReceiveNum = yetReceiveNum
	self._questList = questList
	self:RefreshTaskRed()
	local questArr = string.split(questStr,"=")
	local receiveNum = tonumber(questArr[3])
	self._receiveNum = receiveNum
	local tasks = gModelQuest:GetTaskKeyList(tonumber(questArr[1]))
	local list = {}
	for i, v in pairs(tasks) do
		table.insert(list,v)
	end
	table.sort(list,function (a,b)
		local isReceiveA = self._questList[a._refId] and 1 or 2
		local isReceiveB = self._questList[b._refId] and 1 or 2
		if isReceiveA ~= isReceiveB then
			return isReceiveA < isReceiveB
		end
		if a._sort and b._sort then
			return a._sort < b._sort
		end
	end)
	self._timeTextList = {}
	local _uiList = self._uiList
	if not _uiList then
		_uiList = self:GetUIScroll("popCell")
		_uiList:Create(self.mTaskSuper,list,function (...) self:ListItem(...) end, UIItemList.SUPER)
		self._uiList = _uiList
	else
		_uiList:RefreshList(list)
	end
	_uiList:MoveToPos()
	local color = yetReceiveNum >= receiveNum and "red" or "green"
	local taskStr = string.replace(ccClientText(20312),yetReceiveNum,receiveNum)
	self:SetWndText(self.mTaskText,string.replace(ccClientText(20310),LUtil.FormatColorStr(taskStr,color)))
	self:SetTime()
	self:SetTaskResetTime()
	self:SetTaskEndTime()
	if not self:IsTimerExist(self._timeKey)then
		self:TimerStart(self._timeKey,1,false,-1)
	end
end

function UIWishColleTkPop:SetTaskEndTime()
	local time = GetTimestamp()
	local _schoolInfo = self._schoolInfo
	local endTime = 0
	local timeDesStr = ""
	if self._type == 1 then
		endTime = _schoolInfo.dayQuestEndTime
		timeDesStr = ccClientText(20322)
	else
		endTime = _schoolInfo.weekQuestEndTime
		timeDesStr = ccClientText(20323)
	end
	local timespan = endTime/1000 - time
	CS.ShowObject(self.mTimeBg,timespan > 0)
	if(timespan > 0)then
		local timeStr = LUtil.FormatTimespanCn(timespan)
		self:SetWndText(self.mTimeText,string.replace(timeDesStr,timeStr))
	end
end

function UIWishColleTkPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.QuestListResp,function (...)
		self:RefreshDate()
	end)
	self:WndNetMsgRecv(LProtoIds.SchoolInfoListResp,function (...)
		local _schoolInfos = gModelDreamSchool:GetSchoolInfos()
		self._schoolInfo = _schoolInfos[self.ref.refId]
		self:RefreshDate()
	end)
	self:WndNetMsgRecv(LProtoIds.SchoolInfoChangeResp,function (...)
		local _schoolInfos = gModelDreamSchool:GetSchoolInfos()
		self._schoolInfo = _schoolInfos[self.ref.refId]
		self:RefreshDate()
	end)
end

function UIWishColleTkPop:OnClickTab(type)
	if self._type then
		self:ChangeTab(self._type,false)
	end
	self._type = type
	self:ChangeTab(type,true)
	self:RefreshDate()
end

function UIWishColleTkPop:OnClickClose()--关闭界面
	local _callFun = self._callFun
	if _callFun ~= nil then
		_callFun()
	end
	self:WndClose()
end

function UIWishColleTkPop:OnTimer(key)
	self:SetTime()
	self:SetTaskResetTime()
	self:SetTaskEndTime()
end

function UIWishColleTkPop:SetTime()
	local time = GetTimestamp()
	for i, v in pairs(self._timeTextList) do
		local info = self._questList[i]
		if info then
			local endTime = info.endTime
			local timespan = endTime/1000 - time
			if(timespan > 0)then
				local timeStr = LUtil.FormatTimespanCn(timespan)
				--self:SetWndText(v,string.replace(ccClientText(17241),timeStr))
				self:SetWndText(v,timeStr)
			else
				gModelDreamSchool:OnSchoolInfoListReq()
			end
		end
	end
end

function UIWishColleTkPop:OnClickHelp()
	if not self.ref then
		return
	end
end

function UIWishColleTkPop:RefreshTaskRed()
	local ref = self.ref
	for i, v in pairs(self._redList) do
		local questStr = ""
		if i == 1 then
			questStr = ref.questDay
		else
			questStr = ref.questWeek
		end
		local questArr = string.split(questStr,"=")
		local tasks = gModelQuest:GetTaskKeyList(tonumber(questArr[1]))
		local bool = false
		for j, k in pairs(tasks) do
			local isReceive = self._questList[k._refId]
			if k._state == 1 and isReceive then
				bool = true
				break
			end
		end
		if not bool then
			local questList = self._schoolInfo.questList
			local yetReceiveNum = 0
			for j, k in pairs(questList) do
				if k.questType == i then
					yetReceiveNum = yetReceiveNum + 1
				end
			end
			local receiveNum = tonumber(questArr[3])
			if yetReceiveNum < receiveNum then
				bool = true
			end
		end
		CS.ShowObject(v,bool)
	end
end

function UIWishColleTkPop:ListItem(list,item, itemdata, itempos)
	local InstanceID = item:GetInstanceID()
	local itemRoot = CS.FindTrans(item,"ItemRoot")
	local desText = CS.FindTrans(item,"DesText")
	local timeBg = CS.FindTrans(item,"TimeBg")
	local timeText = CS.FindTrans(item,"TimeBg/TimeText")
	local valueText = CS.FindTrans(item,"ValueText")
	local btnGoTo = CS.FindTrans(item,"BtnGoTo")
	local btnGet = CS.FindTrans(item,"BtnGet")
	local mask = CS.FindTrans(item,"Mask")
	local eff = CS.FindTrans(item,"Eff")

	CS.ShowObject(btnGet,false)
	CS.ShowObject(btnGoTo,false)
	CS.ShowObject(valueText,false)
	local state = itemdata._state
	local ref = gModelQuest:GetTaskConfig(itemdata._refId)
	self:SetWndText(desText,ccLngText(ref.description))
	self:SetWndText(valueText,string.replace(ccClientText(20312),itemdata._schedule,itemdata._goal))

	local itemList = LxDataHelper.ParseItem(ref.reward)
	local baseClass = self._uiCommonIconList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonIconList[InstanceID] = baseClass
		baseClass:Create(itemRoot)
	end
	baseClass:SetCommonReward(itemList[1].itemType, itemList[1].itemId, itemList[1].itemNum)
	baseClass:DoApply()
	self:SetWndClick(itemRoot,function ()
		gModelGeneral:ShowCommonItemTipWnd(itemList[1],{showSkinCode=true})
	end)

	CS.ShowObject(mask,state == 2)
	CS.ShowObject(timeBg,false)
	CS.ShowObject(eff,false)
	local isReceive = self._questList[itemdata._refId]
	if not isReceive then
		if self._yetReceiveNum < self._receiveNum then
			CS.ShowObject(btnGet,true)
			self:SetWndButtonText(btnGet,ccClientText(20313))
			self:SetWndClick(btnGet,function ()
				self:OnClickAcceptQuest(itemdata._refId)
			end)
		end
		return
	end
	if state == 1 then
		CS.ShowObject(eff,true)
		self:CreateWndEffect(eff,"fx_shouchong_anniu_zhong",InstanceID,100)
	end
	if state ~= 2 then
		CS.ShowObject(valueText,true)
		CS.ShowObject(timeBg,true)
	end
	self._timeTextList[itemdata._refId] = timeText

	self:SetWndButtonText(btnGoTo,ccClientText(20307))
	self:SetWndButtonText(btnGet,ccClientText(20316))
	CS.ShowObject(btnGoTo,state == 0)
	CS.ShowObject(btnGet,state == 1)
	self:SetWndClick(btnGoTo,function ()
		gModelQuest:TaskGoto(itemdata._refId,self:GetWndName())
	end)
	self:SetWndClick(btnGet,function ()
		gModelQuest:OnQuestReceiveReq(itemdata._refId)
	end)
end

function UIWishColleTkPop:SetTaskResetTime()
	local time = GetTimestamp()
	local _data = LUtil.OSDate("*t", time)
	local y = _data.year
	local m = _data.month
	local d = _data.day
	local day = 1
	if self._type == 1 then
		day = 1
	else
		day = 7
	end
	local endTime = LUtil.OSTime({year = y, month = m, day = d + day, hour = 0,min = 0,sec = 0})
	local timespan = endTime - time
	if(timespan > 0)then
		local timeStr = LUtil.FormatTimespanCn(timespan)
		self:SetWndText(self.mTaskTimeText,string.replace(ccClientText(20311),timeStr))
	end
end

function UIWishColleTkPop:ChangeTab(type,bool)
	local tab = self._tabTransList[type]
	self:SetWndTabStatus(tab, bool and 0 or 1)
end

function UIWishColleTkPop:TabListItem(list,item, itemdata, itempos)
	local btnTab = CS.FindTrans(item,"BtnTab3")
	local redPoint = CS.FindTrans(item,"redPoint")
	self._redList[itemdata.type] = redPoint
	self._tabTransList[itemdata.type] = btnTab
	self:SetWndTabText(btnTab,itemdata.name)
	self:SetWndTabStatus(btnTab, 1)
	self:SetWndClick(item,function  ()
		self:OnClickTab(itemdata.type)
	end)
end

function UIWishColleTkPop:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(20321))
	local refId = self:GetWndArg("refId")
	self._callFun = self:GetWndArg("func")
	local ref = gModelDreamSchool:GetSchoolThemeRefByRefId(refId)
	if not ref then
		return
	end
	local _schoolInfos = gModelDreamSchool:GetSchoolInfos()
	local _schoolInfo = _schoolInfos[refId]
	if not _schoolInfo then
		return
	end
	self.ref = ref
	self._schoolInfo = _schoolInfo
	local questDay = string.split(ref.questDay,"=")
	local questWeek = string.split(ref.questWeek,"=")
	local list = {
		{type = 1 ,name = ccClientText(20308),questType = tonumber(questDay[1])},
		{type = 2 ,name = ccClientText(20309),questType = tonumber(questWeek[1])}
	}
	local _uiList = self:GetUIScroll("popTab")
	_uiList:Create(self.mTabSuper,list,function (...) self:TabListItem(...) end, UIItemList.SUPER)
	_uiList:MoveToPos()
	self:OnClickTab(list[1].type)
end

function UIWishColleTkPop:OnClickAcceptQuest(refId)
	gModelDreamSchool:OnSchoolAcceptQuestReq(self.ref.refId,refId,self._type)
end
------------------------------------------------------------------
return UIWishColleTkPop


