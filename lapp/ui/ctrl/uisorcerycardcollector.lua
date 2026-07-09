---
--- Created by BY.
--- DateTime: 2022/7/26 11:14:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISorceryCardCollector:LWnd
local UISorceryCardCollector = LxWndClass("UISorceryCardCollector", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISorceryCardCollector:UISorceryCardCollector()
	self._btnTabList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISorceryCardCollector:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISorceryCardCollector:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISorceryCardCollector:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISorceryCardCollector:OnClickTab(questType)
	local _questType = self._questType
	local _btnTabList = self._btnTabList
	if _questType then
		local btnTab = _btnTabList[_questType]
		self:SetWndTabStatus(btnTab,LWnd.StateOff)
	end
	local btnTab = _btnTabList[questType]
	self:SetWndTabStatus(btnTab,LWnd.StateOn)
	self._questType = questType
	self:RefreshData(true)
end

function UISorceryCardCollector:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local btnTab = self:FindWndTrans(root,"BtnTab7")

	self._btnTabList[itemdata.questClassify] = btnTab
	self:SetWndTabText(btnTab,ccLngText(itemdata.name))
	self:SetWndTabStatus(btnTab,LWnd.StateOff)
	self:SetWndClick(btnTab,function ()
		self:OnClickTab(itemdata.questClassify)
	end)
end

function UISorceryCardCollector:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = 381})
end
function UISorceryCardCollector:OnClickTask(refId)
	local netData = gModelQuest:GetTaskDataByRefId(refId)
	if not netData then return end
	local state = netData:GetState()
	if state == 0 then
		local cfg = gModelQuest:GetTaskConfig(refId)
		local originId = cfg.originId
		if originId > 0 then
			gModelQuest:TaskGoto(refId,self:GetWndName())
		else
			GF.ShowMessage(ccClientText(12210))
		end
	elseif state== 1 then
		gModelQuest:OnQuestReceiveReq(refId)
	elseif state == 2 then
		GF.ShowMessage(ccClientText(12211))
	end
end
function UISorceryCardCollector:InitMessage()
	self:WndNetMsgRecv(LProtoIds.SorceryCardCollectorResp,function(pb) self:RefreshData() end)
	self:WndNetMsgRecv(LProtoIds.QuestListResp,function (...)
		self:RefreshData()
	end)
end

function UISorceryCardCollector:InitEvent()
	self:SetWndClick(self.mBgImage,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnHelp,function ()self:OnClickHelp() end)
	self:SetWndClick(self.mBtnOverview,function ()self:OnClickOverview() end)
end
function UISorceryCardCollector:TaskListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local titleText = self:FindWndTrans(root,"TitleBg/TitleText")
	local barValue = self:FindWndTrans(root,"BarValue")
	local numText = self:FindWndTrans(root,"NumText")
	local btnGet = self:FindWndTrans(root,"BtnGet")
	local btnJump = self:FindWndTrans(root,"BtnJump")
	local maskTask = self:FindWndTrans(root,"MaskTask")
	local itemScroll = self:FindWndTrans(root,"ItemScroll")
	barValue = self:FindWndSlider(barValue)

	local InstanceID = item:GetInstanceID()
	local _refId = itemdata._refId
	local _state = itemdata._state
	local _schedule = tonumber(itemdata._schedule)
	local _goal = tonumber(itemdata._goal)
	local _scheduleStr = LUtil.NumberCoversion(_schedule)
	local _goalStr = LUtil.NumberCoversion(_goal)
	local ref = gModelQuest:GetTaskConfig(_refId)

	self:SetWndText(titleText,ccLngText(ref.description))
	barValue.maxValue = _goal
	barValue.value = _schedule
	self:SetWndText(numText,string.format("%s/%s",_scheduleStr,_goalStr))
	CS.ShowObject(btnGet,_state == 1)
	CS.ShowObject(btnJump,_state == 0)
	CS.ShowObject(maskTask,_state == 2)
	self:SetWndButtonGray(btnGet,_state == 2)
	local btnGetStr = ccClientText(29540)
	self:SetWndButtonText(btnGet,btnGetStr)
	self:SetWndButtonText(btnJump,ccClientText(30003))
	if self._isVie then
		self:SetAnchorPos(numText,Vector2.New(230,41.4))
	end
	local rewardList = LxDataHelper.ParseItem(ref.reward)
	local uiList1 = self._taskUiList:GetItemCls(InstanceID)
	if not uiList1 then
		uiList1 = UIIconEasyList:New(self)
		self._taskUiList:SetItemCls(InstanceID, uiList1)
		uiList1:Create(self, itemScroll)
		uiList1:SetIconParentPath("Root/CommonUI/Icon")
	end
	uiList1:RefreshList(rewardList)

	self:SetWndClick(btnGet,function ()
		self:OnClickTask(_refId)
	end)
	self:SetWndClick(btnJump,function ()
		self:OnClickTask(_refId)
	end)
end

function UISorceryCardCollector:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end
function UISorceryCardCollector:OnClickOverview()
	GF.OpenWnd("UISorceryCardCollectorOverview")
end
function UISorceryCardCollector:ArrtListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local icon = self:FindWndTrans(root,"Icon")
	local nameText = self:FindWndTrans(root,"NameText")
	local addText = self:FindWndTrans(root,"AddText")

	local iconStr = gModelHero:GetAttributeIconById(itemdata.refId)
	local nameStr = gModelHero:GetAttributeNameById(itemdata.refId)
	local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(itemdata.refId,itemdata.numType,itemdata.value)
	self:SetWndEasyImage(icon,iconStr)
	self:SetWndText(nameText,nameStr)
	self:SetWndText(addText,valueStr)
end
function UISorceryCardCollector:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(29539))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:SetWndText(self.mOverviewText,ccClientText(29519))
	self:SetWndText(self.mAttrText,ccClientText(29522))
	self:SetWndText(self.mTaskText,ccClientText(29518))

	local list = gModelSorceryCard:GetCollectTaskRef()
	local uiList = self:GetUIScroll("tabUiList_UISorceryCardCollector")
	uiList:Create(self.mTabScroll,list,function(...) self:ListItem(...) end)
	self:OnClickTab(list[1].questClassify)
	--gModelSorceryCard:OnSorceryCardCollectorReq()
end

function UISorceryCardCollector:RefreshData(isTab)
	local _questType = self._questType
	local refId,integral = gModelSorceryCard:GetCollectorInfo()
	if not refId then
		gModelSorceryCard:OnSorceryCardCollectorReq()
		return
	end
	local ref = gModelSorceryCard:GetCollectLevelRefByRefId(refId)
	self:SetWndText(self.mNameText,ccLngText(ref.name))
	self:SetWndEasyImage(self.mCollectorIcon,ref.icon)
	local upNeed = ref.upNeed
	CS.ShowObject(self.mBarCollector,upNeed > 0)
	if upNeed > 0 then
		self.mBarCollector.maxValue = ref.upNeed
		self.mBarCollector.value = integral
		self:SetWndText(self.mBarNumText,string.format("%s/%s",integral,ref.upNeed))
	end

	local arrtList = LUtil.GetRefAttrData(ref.attr)
	local _arrtUiList = self._arrtUiList
	if _arrtUiList then
		_arrtUiList:RefreshList(arrtList)
	else
		_arrtUiList = self:GetUIScroll("mArrtSuper_UISorceryCardCollector")
		self._arrtUiList = _arrtUiList
		_arrtUiList:Create(self.mArrtScroll,arrtList,function(...) self:ArrtListItem(...) end)
		_arrtUiList:EnableScroll(#arrtList > 4,false)
	end

	local taskList = gModelQuest:GetTaskListByType(_questType)
	local len = #taskList
	CS.ShowObject(self.mNoRecord2,len <= 0)
	if len <= 0 then
		self:CreateEmptyShow(10007)
	--else
	--	table.sort(taskList,function (a,b)
	--		local a_state = a._state == 1 and -1 or a._state
	--		local b_state = b._state == 1 and -1 or b._state
	--		if a_state ~= b_state then
	--			return a_state < b_state
	--		end
    --
    --
	--	end)
	end
	local _taskUiList = self._taskUiList
	if _taskUiList then
		_taskUiList:RefreshList(taskList)
		_taskUiList:DrawAllItems()
	else
		_taskUiList = self:GetUIScroll("mTaskScroll_UISorceryCardCollector")
		self._taskUiList = _taskUiList
		_taskUiList:Create(self.mTaskSuper,taskList,function(...) self:TaskListItem(...) end,UIItemList.SUPER)
		_taskUiList:EnableScroll(true,false)
	end
	if isTab then
		_taskUiList:MoveToPos(1)
	end
end
------------------------------------------------------------------
return UISorceryCardCollector


