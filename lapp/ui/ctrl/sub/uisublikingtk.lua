---
--- Created by BY.
--- DateTime: 2023/10/13 10:49:23
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubLikingTk:LChildWnd
local UISubLikingTk = LxWndClass("UISubLikingTk", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubLikingTk:UISubLikingTk()
	self._tabTrList = {}
	self._uiCommonList = {}

	self._btnStrs=
	{
		[0] =ccClientText(12206),-- "未完成"),
		[1] =ccClientText(12207), --"领  取",
		[2] =ccClientText(12208), --"已领取",
	}
	self._stateImg =
	{
		[0] = "public_btn_2_1",
		[1] = "public_btn_2_2",
		[2] = "public_btn_ash_2",
	}
	self._redTrList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubLikingTk:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubLikingTk:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubLikingTk:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitDate()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UISubLikingTk:InitDate()
	self._modelMagList = {
		[ModelActivity.MODEL_ACTIVITY_TYPE_68] = "UIActKingStreet",
	}
end
function UISubLikingTk:OnClickEntry(itemdata,state,jumpId,isBox)
	if state == 0 then
		if isBox then
			local _bondBoxPreviewTitle = self._bondBoxPreviewTitle
			local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
			local rewards = LxDataHelper.ParseItem(entryCfg.reward)
			GF.OpenWnd("UISowItemListPop",{title = _bondBoxPreviewTitle,itemList = rewards})
			return
		end
		if jumpId and jumpId>0 then
			local isOpen = gModelFunctionOpen:CheckIsOpened(jumpId,true)
			if isOpen then
				local wndName = self._modelMagList[self._modelId]
				gModelFunctionOpen:Jump(jumpId,wndName)
			end
		else
			GF.ShowMessage(ccClientText(14303)) --"任务未完成，无法领取"
		end

	elseif state == 1 then
		local sid = self._sid
		local pageId = itemdata.pageId
		local entryId = itemdata.entryId
		gModelActivity:OnActivityReceiveGoalReq(sid,pageId,entryId)
	elseif state == 2 then
		GF.ShowMessage(ccClientText(12208))
	end
end
function UISubLikingTk:TabListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local tab = self:FindWndTrans(root,"Tab")
	local redPoint = self:FindWndTrans(root,"Tab/redPoint")
	self._tabTrList[itemdata.pageId] = tab
	self._redTrList[itemdata.pageId] = redPoint
	self:SetWndTabText(tab,itemdata.name, -2, -30)
	self:SetWndTabStatus(tab, 1)
	self:SetWndClick(root,function ()
		self:OnClickTab(itemdata.pageId,itemdata.index)
	end)
end

function UISubLikingTk:ResetData(pb)
	local _pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = page.pageId
		_pages[pageId] = page
	end
	self._pages = _pages
	self:RefreshData()
end
--------------------------------------------兑换道具------------------------------------------------
function UISubLikingTk:RefreshItem()
	local _showItem = self._showItem
	local _currency = _showItem
	local list = {}
	if not string.isempty(_currency) then
		local arr = string.split(_currency,"|")
		for i, v in ipairs(arr) do
			table.insert(list,{itemId = tonumber(v)})
		end
	end
	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
	else
		_uiCellList = self:GetUIScroll("mItemScroll_UISubTurntableTk")
		_uiCellList:Create(self.mItemScroll,list,function (...) self:ListItem(...) end)
		self._uiCellList = _uiCellList
	end
end
function UISubLikingTk:OnActivityConfigData()
	local sid = self._sid
	if not self._pages then
		gModelActivity:OnActivityPageReq(self._sid)
	end
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	if not activityData then return end
	local data = activityData.config

	local taskList = {}
	for i = 1, 2 do
		local taskData = {
			taskBg = data["taskBg"..i],
			taskHero = data["taskHero"..i],
			taskHeroPos = data["taskHeroPos"..i],
			taskHeroTxt = data["taskHeroTxt"..i],
		}
		taskList[i] = taskData
	end
	self._taskList = taskList
	self._showItem = data.showItem
	self._taskHelpTitle,self._taskHelpTxt = data.taskHelpTitle,data.taskHelpTxt
	self._bondBoxReceiveEff = data.bondBoxReceiveEff
	self._bondBoxPreviewTitle = data.bondBoxPreviewTitle

	local bondBoxSwitch = data.bondBoxSwitch
	if not string.isempty(bondBoxSwitch) then
		local boxArr = string.split(bondBoxSwitch,"|")
		local list = {}
		for i, v in ipairs(boxArr) do
			local arr = string.split(v,"=")
			list[tonumber(arr[1])] = tonumber(arr[2])
		end
		self._bondBoxSwitch = list
	end

	local taskTab = data.taskTab
	local _uiTabList = self._uiTabList
	if not _uiTabList then
		if not string.isempty(taskTab) then
			local tabArr = string.split(taskTab,"|")
			local list = {}
			for i, v in ipairs(tabArr) do
				local arr = string.split(v,"=")
				local data = {
					pageId = tonumber(arr[1]),
					name = arr[2],
					index = tonumber(arr[3])
				}
				table.insert(list,data)
			end
			_uiTabList = self:GetUIScroll("mTabScroll_UISubLikingTk")
			_uiTabList:Create(self.mTabScroll,list,function (...) self:TabListItem(...) end)
			self._uiTabList = _uiTabList
			self:OnClickTab(list[1].pageId,list[1].index)
		end
	end
	self:RefreshRed()
end
function UISubLikingTk:RefreshData()
	local _pages = self._pages
	local _pageId = self._pageId
	local page = _pages[_pageId]
	local _taskList = self._taskList
	local _index = self._index
	local _bondBoxSwitch = self._bondBoxSwitch
	if not page then return end
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityData then return end
	self:RefreshItem()

	local _taskData = _taskList[_index]
	if _taskData then
		local taskBg,taskHero,taskHeroPos,taskHeroTxt,taskHeroTxtPos
		= _taskData.taskBg,_taskData.taskHero,_taskData.taskHeroPos,_taskData.taskHeroTxt,_taskData.taskHeroTxtPos
		if LxUiHelper.IsImgPathValid(taskBg) then
			CS.ShowObject(self.mBg,true)
			self:SetWndEasyImage(self.mBg,taskBg)
		end
		if not string.isempty(taskHero) then
			local imgArr = string.split(taskHero,"=")
			local parent
			if imgArr[1] == "1" then
				parent = self.mHeroImg
				self:SetWndEasyImage(parent,imgArr[2],nil,true)
			else
				parent = self.mHeroSpine
				local spineName = imgArr[2]
				self:CreateWndSpine(parent,spineName,spineName.."UISubLikingTk",false)
			end
			if imgArr[3] then
				local flip = tonumber(imgArr[3])
				parent.localScale = Vector2.New(flip,1)
			end
			CS.ShowObject(parent,true)
			if not string.isempty(taskHeroPos) then
				local pos = LxDataHelper.ParseVector2NotEmpty2(taskHeroPos)
				self:SetAnchorPos(parent, pos)
			end
		end
		if not string.isempty(taskHeroTxt) then
			local parent
			if LxUiHelper.IsImgPathValid(taskHeroTxt) then
				parent = self.mHeroTxt
				self:SetWndEasyImage(parent,taskHeroTxt,nil,true)
			else
				parent = self.mHeroTextBg
				self:SetWndText(self.mHeroText,taskHeroTxt)
			end
			CS.ShowObject(parent,true)
			if not string.isempty(taskHeroTxtPos) then
				local pos = LxDataHelper.ParseVector2NotEmpty2(taskHeroTxtPos)
				self:SetAnchorPos(parent, pos)
			end
		end
	end
	local boxSwitch = _bondBoxSwitch and _bondBoxSwitch[_pageId]
	CS.ShowObject(self.mBoxTask,boxSwitch)
	if boxSwitch then
		local boxPage = _pages[boxSwitch]
		local boxEntrys = boxPage.entry
		local curBoxTask = boxEntrys[#boxEntrys]
		for i, v in ipairs(boxEntrys) do
			local goalData = v.goalData
			local status = goalData.status
			if status ~= 2 then
				curBoxTask = v
				break
			end
		end
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,curBoxTask.pageId,curBoxTask.entryId)
		local goalData = curBoxTask.goalData
		--self:SetWndText(self.mBoxDesText,entryCfg.name)
		local status = goalData.status
		local schedule = goalData.schedules[1].schedule
		--local goal = goalData.schedules[1].goal
		--self.mBoxBar.maxValue = tonumber(goal)
		--self.mBoxBar.value = tonumber(schedule)
		local _bondBoxReceiveEff = self._bondBoxReceiveEff
		if not string.isempty(_bondBoxReceiveEff)then
			self:CreateWndEffect(self.mBoxEff,_bondBoxReceiveEff,_bondBoxReceiveEff,100)
		end
		CS.ShowObject(self.mBoxImg,status ~= 1)
		CS.ShowObject(self.mBoxEff,status == 1)
		self:SetWndText(self.mBoxDesText,string.replace(entryCfg.name,schedule))
		local jumpId = tonumber(entryCfg.jumpId)
		self:SetWndClick(self.mBoxTask,function () self:OnClickEntry(curBoxTask,status,jumpId,true) end)
		CS.ShowObject(self.mBoxMask,status == 2)
	end

	local list = page.entry
	table.sort(list,function (a,b)
		local aStatus = a.goalData.status
		local bStatus = b.goalData.status
		local aSort = aStatus == 1 and -1 or aStatus
		local bSort = bStatus == 1 and -1 or bStatus
		local aEntryId = a.entryId
		local bEntryId = b.entryId
		if aSort ~= bSort then
			return aSort < bSort
		end
		return aEntryId < bEntryId
	end)
	local _uiTaskList = self._uiTaskList
	if(_uiTaskList)then
		_uiTaskList:RefreshList(list)
	else
		_uiTaskList = self:GetUIScroll("mTaskScroll_UISubLikingTk")
		self._uiTaskList = _uiTaskList
		_uiTaskList:Create(self.mTaskScroll,list,function (...) self:TaskListItem(...) end, UIItemList.SUPER)
	end
	_uiTaskList:MoveToPos(1)
end
function UISubLikingTk:OnDrawReward(list, item,itemdata,itempos)
	local itemType,itemRefId,itemCount = itemdata.itemType,itemdata.itemId,itemdata.itemNum
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local itemNum = self:FindWndTrans(item,"itemNum")
	local EffTrans = self:FindWndTrans(item,"Eff")
	if EffTrans then
		local show = false
		if itemType == LItemTypeConst.TYPE_ITEM then
			LxResUtil.DestroyChildImmediate(EffTrans)
			local itemRef = gModelItem:GetRefByRefId(itemRefId)
			local bgEff = itemRef and itemRef.bgEff or nil
			if not string.isempty(bgEff) then
				show = true
				local instanceId = item:GetInstanceID()
				self:CreateWndEffect(EffTrans,bgEff,instanceId,90,false,false)
			end
		end
		CS.ShowObject(EffTrans,show)
	end

	if itemRoot then
		local formatData =
		{
			itemId = itemRefId,
			itemType = itemType,
			itemNum = itemCount,
		}
		local uiCommonList = self._uiCommonList
		local InstanceID = item:GetInstanceID()
		local baseClass = uiCommonList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			uiCommonList[InstanceID] = baseClass
			baseClass:Create(CS.FindTrans(itemRoot,"Icon"))
		end
		baseClass:SetCommonReward(itemType, itemRefId, -1)
		self:SetWndClick(itemRoot, function()
			gModelGeneral:ShowCommonItemTipWnd(formatData)
		end)
		baseClass:DoApply()
	end

	local numStr = LUtil.NumberCoversion(itemCount)
	self:SetWndText(itemNum,numStr)
end
function UISubLikingTk:GetReturnRed(pageId)
	return gModelRedPoint:GetActivityRedPointPage(self._sid,pageId)
end
function UISubLikingTk:ListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local itemBg = self:FindWndTrans(root,"ItemBg")
	local itemIcon = self:FindWndTrans(itemBg,"ItemIcon")
	--local itemAdd = self:FindWndTrans(itemBg,"ItemAdd")
	local itemText = self:FindWndTrans(itemBg,"ItemText")

	local itemId = itemdata.itemId
	local icon,iconBg = gModelItem:GetItemImgByRefId(itemId)
	local itemNum = gModelItem:GetNumByRefId(itemId)

	self:SetWndEasyImage(itemIcon,icon)
	self:SetWndText(itemText,LUtil.NumberCoversion(itemNum))

	self:SetWndClick(root,function ()
		local wndName = self._modelMagList[self._modelId]
		gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = wndName})
	end)
end
--------------------------------------------兑换道具------------------------------------------------
function UISubLikingTk:OnClickTab(pageId,index)
	local _tabTrList = self._tabTrList
	local _pageId = self._pageId
	if _pageId then
		self:SetWndTabStatus(_tabTrList[_pageId], 1)
	end
	self:SetWndTabStatus(_tabTrList[pageId], 0)
	self._pageId = pageId
	self._index = index
	self:RefreshData()
end

function UISubLikingTk:OnClickHelp()
	local _txt = self._taskHelpTxt or ""
	_txt = string.gsub(_txt,"\\n","\n")
	GF.OpenWnd("UIBzTips",{title = self._taskHelpTitle,text = _txt})
end
function UISubLikingTk:RefreshRed()
	local _bondBoxSwitch = self._bondBoxSwitch or {}
	local _redTrList = self._redTrList or {}
	for i, v in pairs(_redTrList) do
		local pId = _bondBoxSwitch[i]
		CS.ShowObject(v,self:GetReturnRed(i) or (pId and self:GetReturnRed(pId)))
	end
end
function UISubLikingTk:TaskListItem(list,item,itemdata,itempos)
	local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,itemdata.pageId,itemdata.entryId)
	local titleBgTitle = self:FindWndTrans(item,"TitleBg/Title")
	local rewardList = self:FindWndTrans(item,"RewardList")
	local btn = self:FindWndTrans(item,"Btn")
	local btnText = self:FindWndTrans(btn,"Text")
	local ShowText = self:FindWndTrans(item,"Show")

	local title = entryCfg.name
	local rewards = LxDataHelper.ParseItem(entryCfg.reward)
	local jumpId = tonumber(entryCfg.jumpId)
	local jumpDesc = entryCfg.jumpDesc

	local goalData = itemdata.goalData
	local status   = goalData.status
	local schedule = goalData.schedules[1].schedule
	local goal = goalData.schedules[1].goal

	self:SetWndText(titleBgTitle,title)
	local InstanceID = item:GetInstanceID()
	local uiList =  self:GetUIScroll("key"..InstanceID)
	local drawRewardList = uiList:GetList()
	if(drawRewardList)then
		uiList:RefreshList(rewards)
		drawRewardList:SetContentPosition(0,0)
	else
		uiList:Create(rewardList,rewards,function (...) self:OnDrawReward(...)  end)
		drawRewardList = uiList:GetList()
		drawRewardList:SetContentPosition(0,0)
	end
	if #rewards >5 then
		uiList:EnableScroll(true,true)
	end

	local btnstr = self._btnStrs[status]
	local btnState = 0
	if status == 0 then
		btnState = 0
		if jumpId and jumpId >0 then
			btnstr = jumpDesc
		end
	elseif status == 1 then
		btnState = 1
	elseif status == 2 then
		btnState = 2
	end

	local img = self._stateImg[btnState]
	self:SetBtnImageAndMat(btn,img,btnText)

	if ShowText then
		CS.ShowObject(ShowText,status == 2)
	end
	CS.ShowObject(btn,status ~= 2)

	local DescTxtTrans = self:FindWndTrans(item, "DescTxt")
	if DescTxtTrans then
		local color = "red"
		if btnState ~= 0 then color = "green" end

		local str = string.format("(%s/%s)",schedule,goal)
		str = LUtil.FormatColorStr(str,color)
		self:SetWndText(DescTxtTrans,str)
	end

	self:SetImageActorState(btn,btnState)
	self:SetWndText(btnText,btnstr)
	self:SetWndClick(btn,function () self:OnClickEntry(itemdata,status,jumpId) end)
end
function UISubLikingTk:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ItemChangeResp,function (pb)
		self:RefreshItem()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshRed() end)
end
function UISubLikingTk:InitEvent()
	self:SetWndClick(self.mBtnHelp,function (...)self:OnClickHelp() end)
end
function UISubLikingTk:InitCommand()
	local sid = self:GetWndArg("sid")
	local pages = self:GetWndArg("pages")
	self._pages = pages
	self._sid = sid
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._modelId = modelId

	self:OnActivityConfigData()
end
------------------------------------------------------------------
return UISubLikingTk


