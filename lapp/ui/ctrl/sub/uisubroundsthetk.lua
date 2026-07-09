---
--- Created by Administrator.
--- DateTime: 2023/10/8 19:30:31
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubRoundsTheTk:LChildWnd
local UISubRoundsTheTk = LxWndClass("UISubRoundsTheTk", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubRoundsTheTk:UISubRoundsTheTk()
	---@type table<number,CommonIcon>
	self._uiCommonList = {}

	self._endTimerKey = "_endTimeKey"
	self._roundListScrollKey = "_roundListScrollKey"
	self._getBtnEff = "fx_anniu_02"
	self._specialOpenTypeCancelTabRound = 12

	self._progressFormat = "#a1#/#a2#"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubRoundsTheTk:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil

	self._roundListData = {}
	self._roundTypeList = {}
	self._curIsUnlock = false

	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubRoundsTheTk:OnCreate()
	LChildWnd.OnCreate(self)
	self._roundListData = {}
	self._roundTypeList = {}
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubRoundsTheTk:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitPara()
end

function UISubRoundsTheTk:ResetActivePageData(pb)
	if not self._activityPageData then
		self._activityPageData = {}
	end

	self._pageHaveGets = {}
	for k, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		if page and page.entry then
			local dataList = {}
			local pageId   = v.pageId
			local moreInfo = JSON.decode(page.moreInfo)
			local isUnlock = moreInfo.isUnlock == 1
			local newRounds = moreInfo.newRounds == 1

			local haveGet = false
			for p,q in ipairs(page.entry) do
				local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,pageId,q.entryId)
				local status = q.status or q.goalData.status  --(0-不可领取, 1-可领取，2-已领取)
				local schedules = q.goalData.schedules[1]

				local data = {
					entryId  = q.entryId,
					pageId	 = pageId,
					name	 = entryCfg.name,
					icon	 = entryCfg.icon,
					jumpDesc = entryCfg.jumpDesc,
					jumpId   = entryCfg.jumpId,
					sort     = entryCfg.sort,
					rewards  = LxDataHelper.ParseItem(entryCfg.reward),
					status   = status,
					schedule = schedules.schedule,
					goal	 = schedules.goal,
					isUnlock = isUnlock,
				}
				table.insert(dataList,data)

				if status == 1 then
					haveGet = true
				end
			end

			table.sort(dataList,function(a,b)
				local statusA = a.status
				local statusB = b.status
				if statusA ~= statusB then
					if statusA == 1 or statusB == 1 then
						return statusA == 1
					end

					if statusA == 2 or statusB == 2 then
						return statusB == 2
					end
				end

				return a.sort < b.sort
			end)

			self._activityPageData[pageId] = dataList
			self._roundListData[k].isUnlock = isUnlock
			self._roundListData[k].newRounds = newRounds
			self._pageHaveGets[pageId] = haveGet
		end
	end

	--设置活动进入按钮每日登录红点显示
	self:SetActMainBtnRedShowStatus(true)

	--获取第一次打开分页，默认当前轮次
	if not self._page then
		self._page = self:GetCurRoundTaskIndex()
	end

	self:SetCurRoundIsUnlock()
	if self._isFirst then
		self:SetFirstOpenTab(self._page)
	end

	self._isFirst = false
end

function UISubRoundsTheTk:GetCellScrollJumpIndex()
	if not self._curIsUnlock then
		return 1
	end

	local list = self:GetCurRoundTaskList()
	local maxNum = #list
	local jumpIndex  = maxNum
	local canGetIndex
	for i = maxNum, 1, -1 do
		local curData = list[i]
		local status  = curData.status
		if status == 1 then
			canGetIndex = i
		elseif status == 0 then
			jumpIndex = i
		end
	end

	if canGetIndex then
		return canGetIndex
	end

	return jumpIndex
end

function UISubRoundsTheTk:OnClickGoOn(jump)--前往
	gModelFunctionOpen:Jump(jump,self:GetWndName())
end

function UISubRoundsTheTk:OnClickHelp()--点击帮助
	local activityData = self._activityData
	if not activityData then
		return
	end

	local _sid = self._sid
	local config = self._activityConfig
	local title = gModelActivity:GetLngNameByActivitySid(_sid)
	local content = config.txt
	GF.OpenWnd("UIBzTips",{title= title,text = content, bTransWarp = true})
end

--#####################################################################################################################
--## RefPoint #########################################################################################################
--#####################################################################################################################
function UISubRoundsTheTk:SetActMainBtnRedShowStatus(isFirst)
	local isRedShow = gModelRedPoint:CheckActivityShowRed(self._sid)
	if not isRedShow then return end

	for k,v in pairs(self._pageHaveGets) do
		if v == true then
			return
		end
	end

	for k,v in pairs(self._roundListData) do
		if v.newRounds == true then
			return
		end
	end

	if (isFirst and self._isFirst) or (not isFirst) then
		gModelRedPoint:SetActivityRedClicked(self._sid)
	end
end

function UISubRoundsTheTk:SetCurRoundIsUnlock()
	local page = self._page
	local curRoundData = self._roundListData[page]
	self._curIsUnlock = curRoundData.isUnlock
end

function UISubRoundsTheTk:InitEvent()
	self:SetWndClick(self.mHelpBtn,function() self:OnClickHelp() end)
end

function UISubRoundsTheTk:SetEndTime()
	local endTime = self._endTime
	local isShow = endTime and endTime >= 0
	CS.ShowObject(self.mTimeBg, isShow)

	if not isShow then return end

	self:TimerStart(self._endTimerKey,1,false,-1)
	self:StarCountDown()
end

function UISubRoundsTheTk:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...)
		self:OnActivityConfigData(...)
	end)
	--self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
	--	self:RefreshData()
	--end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		self:OnActivityPageResp(pb)
	end)

	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function (pb)
		self:OnActivitySpecialOpResp(pb)
	end)
end

function UISubRoundsTheTk:RefreshView()


	self:RefreshRoundList()
	self:RefreshLockRoot()
	self:RefreshCellScroll()
	self:RefreshRoundList()
end


--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UISubRoundsTheTk:OnActivityConfigData(data, sid)
	if sid ~= self._sid then return end

	self:InitData()
	self:InitTop()
	gModelActivity:OnActivityPageReq(self._sid)
end

function UISubRoundsTheTk:GetCurRoundTaskList()
	local page = self._page
	if not (page and self._activityPageData) then
		return {}
	end

	return self._activityPageData[page] or {}
end


--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UISubRoundsTheTk:InitTop()
	if not self._activityData then return end

	local config = self._activityConfig

	local path   = config.image
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTop, path)
	end

	path = config.hintImage
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTextImg, path,function()
			CS.ShowObject(self.mTextImg, true)

			local pos = LxDataHelper.ParseVector2NotEmpty(config.hintImagePos)
			self:SetAnchorPos(self.mTextImg, pos)
		end,true)
	end

	path = config.image1
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTextImg1, path,function()
			CS.ShowObject(self.mTextImg1,true)

			local pos = LxDataHelper.ParseVector2NotEmpty(config.image1Pos)
			self:SetAnchorPos(self.mTextImg1, pos)
		end,true)
	end

	local pos = LxDataHelper.ParseVector2NotEmpty(config.timePos)
	self:SetAnchorPos(self.mTimeBg, pos)

	self:SetEndTime()
end

function UISubRoundsTheTk:OnDrawItemCell(list, item, itemdata, itempos)
	local tabBtn 	= self:FindWndTrans(item, "BtnTab7")
	local redPoint  = self:FindWndTrans(item, "redPoint")

	local data = {
		page 			= itempos,
		tabBtn 			= tabBtn,
		redPoint 		= redPoint,
	}
	self._roundTypeList[itempos] = data

	self:SetWndTabText(tabBtn, itemdata.pageName)
	self:SetWndClick(tabBtn, function() self:OnClickRoundTab(itempos) end)

	if itempos >= #self._roundTypeList then
		self:RefreshRoundListStatus()
	end
end

function UISubRoundsTheTk:InitData()
	local activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	self._activityData = activityWebData
	local data = activityWebData.config
	self._activityConfig = data

	self._endTime = activityData.endTime
	local restRemind = data.restRemind
	self._restRemind = restRemind * 3600

	local roundListData = {}
	local unlockTasks = string.split(data.unlockTask, '|')
	for k,v in ipairs(unlockTasks) do
		local taskData= string.split(v, '=')
		local roundIndex = tonumber(taskData[1])
		local needCompleteIndex = tonumber(taskData[2])
		local roundName  = data["pageName"..k] or ""

		roundListData[roundIndex] = {
			pageName		  = roundName,
			needCompleteIndex = needCompleteIndex,
			isUnlock		  = false,
			newRounds		  = false,
		}
	end

	self._roundListData = roundListData
end

function UISubRoundsTheTk:StarCountDown()
	if self._endTime == 0 then
		self:SetWndText(self.mTimeText,ccClientText(14300))
		self:TimerStop(self._endTimerKey)
		return
	end

	local lastTime = self._endTime - GetTimestamp()
	if lastTime < 0 then
		self:TimerStop(self._endTimerKey)
		GF.ShowMessage(ccClientText(14301))
		GF.CloseWndByName("UIAct")
		FireEvent(EventNames.CHANGE_MAIN_BTN,LMainBtnIndexConst.CITY)
		return
	end

	local timeStr = LUtil.FormatTimespanCn(lastTime)

	if lastTime <= self._restRemind then
		timeStr   = LUtil.FormatColorStr(timeStr,"lightRed")
	end

	timeStr = string.replace(ccClientText(22600),timeStr)
	self:SetWndText(self.mTimeText,timeStr)
end

function UISubRoundsTheTk:RefreshRoundListStatus()
	for k,v in ipairs(self._roundTypeList) do
		local pageIndex = v.page
		local sel = self._page == pageIndex
		self:SetWndTabStatus(v.tabBtn, sel and LWnd.StateOn or LWnd.StateOff)

		local isShowRed = self:CheckRedPointRoundTabByIndex(pageIndex)

		CS.ShowObject(v.redPoint, isShowRed)
	end
end

function UISubRoundsTheTk:OnActivityPageResp(pb)
	if(self._sid~=pb.sid)then return end

	self:ResetActivePageData(pb)
	self:RefreshView()
end

function UISubRoundsTheTk:RefreshCellScroll()
	local list = self:GetCurRoundTaskList()
	if(not self._uiList)then
		self._uiList = self:GetUIScroll("uiList")
		self._uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end,UIItemList.SUPER)
	else
		self._uiList:RefreshList(list)
	end

	local index = self:GetCellScrollJumpIndex()
	self._uiList:MoveToPos(index)
end

function UISubRoundsTheTk:OnActivitySpecialOpResp(pb)
	if(self._sid~=pb.sid)then return end

	if pb.opType == self._specialOpenTypeCancelTabRound then
		self:RefreshRoundList()
	end
end

function UISubRoundsTheTk:InitPara()
	self._sid = self:GetWndArg("sid")

	if not self._sid then
		local subpage= self:GetWndArg("subPage") --支持跳转
		if subpage then
			self._sid = gModelActivity:GetSidByUniqueJump(subpage)
		end
	end

	self._page = self:GetWndArg("page")

	self._isFirst = true
	self._pageHaveGets = {}

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UISubRoundsTheTk:OnClickItemRoot()
	if self._curIsUnlock then return end

	local needRoundTaskName = self:GetUnlockNeedRoundName()
	GF.ShowMessage(string.replace(ccClientText(22601), needRoundTaskName))
end

function UISubRoundsTheTk:GetCurRoundTaskIndex()
	if table.isempty(self._roundListData) then
		return 1
	end

	local roundsNum = #self._roundListData
	local unlockList = {}
	for i = roundsNum, 1, -1 do
		local isUnlock = self._roundListData[i].isUnlock
		if isUnlock then
			table.insert(unlockList, i)
		end
	end

	for k,v in ipairs(unlockList) do
		if self:CheckRedPointRoundTabByIndex(v, true) then
			return v
		end
	end

	return unlockList[1] or 1
end

function UISubRoundsTheTk:ListItem(list , item, itemdata, itempos)
	local titleBg 		= self:FindWndTrans(item,"titleBg")
	local title 		= self:FindWndTrans(titleBg,"title")
	local rewardList 	= self:FindWndTrans(item,"rewardList")
	local sliderRoot	= self:FindWndTrans(item, "Slider")
	local sliderProgressText = self:FindWndTrans(sliderRoot, "ProgressText")
	local goBtnTrans 	= self:FindWndTrans(item,"GoBtn")
	local getBtnTrans 	= self:FindWndTrans(item,"GetBtn")
	local getBtnEffTrans = self:FindWndTrans(getBtnTrans,"Eff")
	local showTrans 	= self:FindWndTrans(item,"Show")

	local status 		= itemdata.status
	local isUnlock		= itemdata.isUnlock
	local titleStr		= itemdata.name
	local jumpId  		= itemdata.jumpId
	local canGet 		= status == 1

	self:SetWndEasyImage(titleBg,itemdata.icon)
	self:SetWndText(title,titleStr)

	local InstanceID = item:GetInstanceID()
	local itemList = itemdata.rewards
	local uiIconEasyList = self._uiList:GetItemCls(InstanceID)
	if(not uiIconEasyList)then
		uiIconEasyList = UIIconEasyList:New()
		self._uiList:SetItemCls(InstanceID, uiIconEasyList)
		uiIconEasyList:Create(self, rewardList)
		uiIconEasyList:SetIconParentPath("itemRoot")
	end
	uiIconEasyList:RefreshList(itemList)

	CS.ShowObject(goBtnTrans,  not isUnlock or status == 0)
	CS.ShowObject(getBtnTrans, isUnlock and canGet)
	CS.ShowObject(showTrans,isUnlock and status == 2)
	self:SetWndEasyImage(showTrans, "public_txt_13_1")
	CS.ShowObject(sliderRoot, isUnlock)

	self:SetWndButtonGray(goBtnTrans, not isUnlock)
	self:SetWndClick(goBtnTrans,function()
		if isUnlock then
			self:OnClickGoOn(jumpId)
		else
			self:OnClickItemRoot()
		end
	end)

	if not isUnlock then
		self:SetWndClick(item, function() self:OnClickItemRoot() end)
		self:SetWndButtonText(goBtnTrans, ccClientText(22603))
		return
	end

	local pageId		= itemdata.pageId
	local entryId		= itemdata.entryId
	local schedule		= itemdata.schedule
	local goal 			= itemdata.goal

	local progressValue = schedule/goal
	local progressStr	= string.replace(self._progressFormat, schedule, goal)
	self:SetWndText(sliderProgressText, progressStr)
	LxUiHelper.SetProgress(sliderRoot,progressValue)

	self:SetWndButtonText(goBtnTrans, itemdata.jumpDesc)
	self:SetWndButtonText(getBtnTrans, ccClientText(10151))
	self:SetWndClick(getBtnTrans,function ()
		self:OnClickGet(pageId,entryId)
	end)

	local effKey = self._getBtnEff..InstanceID
	self:DestroyWndEffectByKey(effKey)

	if canGet then
		self:CreateWndEffect(getBtnEffTrans,self._getBtnEff,effKey,100,false,false)
	end
	CS.ShowObject(getBtnEffTrans, canGet)
end

function UISubRoundsTheTk:OnClickGet(pageId, entryId)--领取
	gModelActivity:OnActivityReceiveGoalReq(self._sid,pageId,entryId)
end

function UISubRoundsTheTk:OnClickRoundTab(tabIndex)
	if self._page == tabIndex then
		return
	end

	self._page = tabIndex

	self:SetCurRoundIsUnlock()
	self:RefreshView()
	self:SetFirstOpenTab(tabIndex)
end

--#####################################################################################################################
--## Content ##########################################################################################################
--#####################################################################################################################
function UISubRoundsTheTk:RefreshLockRoot()
	local curIsUnlock = self._curIsUnlock
	CS.ShowObject(self.mLockRoot, not curIsUnlock)
	if curIsUnlock then return end

	local needRoundTaskName = self:GetUnlockNeedRoundName()
	local str = string.replace(ccClientText(22602), needRoundTaskName)
	self:SetWndText(self.mLockText, str)
end

function UISubRoundsTheTk:GetUnlockNeedRoundName()
	local page = self._page
	local curRoundData = self._roundListData[page]

	local needCompleteIndex = curRoundData.needCompleteIndex
	local needRoundData		= self._roundListData[needCompleteIndex]
	if not needRoundData then
		return ""
	end

	return needRoundData.pageName
end

function UISubRoundsTheTk:OnTimer(key)
	if key == self._endTimerKey then
		self:StarCountDown()
	end
end

function UISubRoundsTheTk:SetFirstOpenTab(tabIndex)
	local page = self._page
	local curRoundData = self._roundListData[page]
	local newRounds = curRoundData.newRounds
	if not newRounds then
		return
	end

	self._roundListData[tabIndex].newRounds = false
	gModelActivity:OnActivitySpecialOpReq(self._sid,tabIndex,0,self._specialOpenTypeCancelTabRound)
end

--#####################################################################################################################
--## RoundList ########################################################################################################
--#####################################################################################################################
function UISubRoundsTheTk:RefreshRoundList()
	local key = self._roundListScrollKey
	local list = self._roundListData
	local uiList = self:FindUIScroll(key)
	if uiList then
		--uiList:RefreshList(list)
		self:RefreshRoundListStatus()
	else
		uiList = self:GetUIScroll(key)
		uiList:Create(self.mRoundList, list,function(...) self:OnDrawItemCell(...) end)
	end
end

function UISubRoundsTheTk:CheckRedPointRoundTabByIndex(roundIndex, jumpCheckNew)
	if table.isempty(self._activityPageData) then
		return false
	end


	local roundsData = self._roundListData[roundIndex]
	if not jumpCheckNew and roundsData.newRounds then
		return true
	end

	if not roundsData.isUnlock then
		return false
	end

	local data = self._activityPageData[roundIndex]
	if table.isempty(data) then
		return false
	end

	for k,v in ipairs(data) do
		if v.status == 1 then
			return true
		end
	end

	return false
end

------------------------------------------------------------------
return UISubRoundsTheTk


