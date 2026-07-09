--- 模板132 剧情副本
--- Created by Ease.
--- DateTime: 2023/10/17 10:48:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActPtCopy:LWnd
local UIActPtCopy = LxWndClass("UIActPtCopy", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActPtCopy:UIActPtCopy()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActPtCopy:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActPtCopy:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActPtCopy:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitMessage()
	self:InitEvent()
	self:InitData()
end
function UIActPtCopy:GetStoryDateStr(openDayIndex)
	local addTime   = (openDayIndex - 1) * 86400
	local timeValue = self._startTime + addTime
	local y,m,d = LUtil.GetYmdByTimestamp(timeValue)
	return string.replace(ccClientText(21742), m,d)
end
function UIActPtCopy:SetTransPos(trans,pos)
	if(pos and not string.isempty(pos))then
		local posData = LxDataHelper.ParseVector2NotEmpty(pos)
		self:SetAnchorPos(trans,posData)
	end
end
function UIActPtCopy:OnClickStoryHelpBtn()
	local config = self._mainCfg
	if not config then return end
	local content = config.storyHelpDes
	local title = ccClientText(21746)
	GF.OpenWnd("UIBzTips",{title= title,text = content})
end
function UIActPtCopy:SetUI()
	local titlepath = self._mainCfg.storyTitle
	self:SetWndEasyImage(self.mStoryTextImg,titlepath)
	self:SetWndEasyImage(self.mStoryBg,self._mainCfg.storyImage)
	self:SetWndEasyImage(self.mDescImg,self._mainCfg.storyLabel)
	local showDescGroup = self._mainCfg.buffText and not string.isempty(self._mainCfg.buffText)
	CS.ShowObject(self.mDescTxtBg,showDescGroup)
	self:SetWndText(self.mDescTxt,self._mainCfg.buffText)
	self:SetTransPos(self.mTitleImg,self._mainCfg.storyTitlePos)
	self:SetTransPos(self.mStoryTimeBg,self._mainCfg.storyTitlePos)
	self:SetTransPos(self.mStoryHelpBtn,self._mainCfg.storyHelpPos)
	self:SetTransPos(self.mSpineRoot,self._mainCfg.storyLHpos)
	self:SetTransPos(self.mDescImg,self._mainCfg.storyLabelPos)
	self:SetTransPos(self.mDescTxtBg,self._mainCfg.buffTextPos)
	self:SetHeroSpine()
end
-------------------------------------------------------
function UIActPtCopy:RefreshStoryView()
	if not self._activityPageData then return end
	local pageData = self._activityPageData[1]
	if not pageData then
		return
	end
	local curOpenDay = self._openDay
	local dataList = {}
	self._curCanGoStoryChapter = nil
	for k,v in pairs(pageData.entry) do
		local pageId	= v.pageId
		local entryId   = v.entryId
		local data
		local entryCfg  = gModelActivity:GetWebActivityEntryData(self._sid,v.pageId,v.entryId)
		if entryCfg then
			local openDayIndex = tonumber(entryCfg.moreInfo)
			local nameList 	= string.split(entryCfg.name, '|')
			local nameStr 	= string.replace(ccClientText(21743), nameList[1], nameList[2])
			nameStr 		= string.gsub(nameStr,"\\n","\n")

			data 		= {
				pageId		= pageId,
				entryId		= entryId,
				name 		= nameStr,
				icon 		= entryCfg.icon,
				sort		= entryCfg.sort,
				reward		= LxDataHelper.ParseItem(entryCfg.reward),
				goalData	= v.goalData,
				status		= v.goalData.status,
				unlock		= openDayIndex <= curOpenDay,
				openDayIndex= openDayIndex,
			}
			table.insert(dataList, data)

			if data.status == 0 and (not self._curCanGoStoryChapter or self._curCanGoStoryChapter >= k) then
				self._curCanGoStoryChapter = k
			end
		end
	end
	if not self._curCanGoStoryChapter then
		self._curCanGoStoryChapter = #dataList
	end

	table.sort(dataList, function(a,b)
		return a.sort < b.sort
	end)

	self._storyDataList = dataList
	if(self._storyCellUIList)then
		self._storyCellUIList:RefreshData(dataList)
	else
		self._storyCellUIList = self:GetUIScroll("_storyCell")
		self._storyCellUIList:Create(self.mStoryCellScroll,dataList,
				function (...) self:DrawStoryListItem(...) end, UIItemList.SUPER)
	end

	local index
	for k,v in ipairs(dataList) do
		if v.status == 1 or (v.status == 0 and v.unlock and not index) then
			index = k
			break
		end
	end

	if not index then
		index = self._curCanGoStoryChapter
	end

	self._storyCellUIList:MoveToPos(index)
end

function UIActPtCopy:SetRewardItem(itemTrans,itemData,itemPos)
	local iconBg = self:FindWndTrans(itemTrans,"IconBg")
	local icon = self:FindWndTrans(iconBg,"Icon")
	local iconSelect = self:FindWndTrans(itemTrans,"IconSelect")
	local nameTxt = self:FindWndTrans(itemTrans,"NameTxt")
	local getIcon = self:FindWndTrans(itemTrans,"GetIcon")
	local effRoot = self:FindWndTrans(itemTrans,"EffRoot")
	local entryData = self:GetPbEntryDataById(itemData.id)
	local state = entryData.status or entryData.goalData.status
	local isGet = state == 2
	local isCurSelect = state == 1
	CS.ShowObject(getIcon,isGet)
	CS.ShowObject(iconSelect,isCurSelect)
	local bubbleArr = string.split(self._mainCfg.bubble,"|")
	self:SetWndEasyImage(iconBg,bubbleArr[1])
	self:SetWndEasyImage(iconSelect,bubbleArr[2])

	local effCfgArr = string.split(self._mainCfg.bubbleEffect,"|")
	local effName = (effCfgArr[1] and not string.isempty(effCfgArr[1])) and effCfgArr[1] or nil
	local iconSeleScale =(effCfgArr[2] and not string.isempty(effCfgArr[2])) and tonumber(effCfgArr[2]) or 1
	effRoot.localScale = Vector2.New(iconSeleScale,iconSeleScale,1)
	if(effName)then
		local effectKey = effName..effRoot:GetInstanceID()
		self:CreateWndEffect(effRoot, effName, effectKey, 100, false, false, 0, nil, 100)
	end
	CS.ShowObject(effRoot,isCurSelect and effName)

	local nameStr = string.split(itemData.name,"|")[1]
	self:SetWndText(nameTxt,nameStr)
	local reward = LxDataHelper.ParseItem_4(itemData.reward)
	local itemId = reward.itemId
	local iconPath = gModelItem:GetItemImgByRefId(itemId)
	self:SetWndEasyImage(icon,iconPath)
	self:SetWndClick(itemTrans, function()
		if(state == 1)then
			self:OnClickGet()
		else
			GF.ShowMessage(ccLngText(self._mainCfg.unclaimTxt))
			gModelGeneral:ShowCommonItemTipWnd(reward)
		end
	end)
end

------------------------------------------------
function UIActPtCopy:OnTimer(key)
	if(key == self._showTimeKey)then
		self:SetTimeTxt()
	end
end
function UIActPtCopy:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(pb)
		self:OnActivityPageResp(pb)
	end)
end
function UIActPtCopy:SetHeroSpine()
	local heroRefId = self._mainCfg.storyLH
	local spinePos = self._mainCfg.storyLHpos
	local effectRef = gModelHero:GetHeroShowRefByRefId(heroRefId)
	if not effectRef then return end
	local heroDrawing = effectRef.heroDrawing
	self:CreateSpine(heroDrawing, self.mSpineRoot, heroDrawing, spinePos)
end
function UIActPtCopy:SetRewardListGroup()
	local isShow = self._mainCfg.isReward
	CS.ShowObject(self.mProgressRewardGroup,isShow)
	if(not isShow)then
		return
	end
	local rewardGroupTrans = self.mProgressRewardGroup
	local progressBg = self:FindWndTrans(rewardGroupTrans,"ProgressBg")
	local progress = self:FindWndTrans(progressBg,"Progress")
	local getCnt = self:GetCurGetRewardCnt()
	local cfgList = self._rewardsEntriesCfg
	local rate = (getCnt-1)/#cfgList
	LxUiHelper.SetProgress(progress, rate)

	local rewardList = self:FindWndTrans(rewardGroupTrans,"RewardList")
	for i = 1, #cfgList do
		local itemData = cfgList[i]
		local nameStr = string.split(itemData.name,"|")[3] or i
		local trans = rewardList:GetChild(tonumber(nameStr)-1)
		CS.ShowObject(trans,true)
		self:SetRewardItem(trans,itemData,i)
	end
end

function UIActPtCopy:OnActivityPageResp(pb, ret)
	local sid = pb.sid
	if sid ~= self._sid then
		return
	end
	local page = pb.pages[1]
	local pageId = page.pageId
	local pageData = gModelActivity:GenerateActivePageDataFromPb(page)
	self._page = pageData
	if not self._activityPageData then
		self._activityPageData = {}
	end
	for i, v in ipairs(pb.pages) do
		local page=gModelActivity:GenerateActivePageDataFromPb(v)
		if page then
			self._activityPageData[v.pageId] = page
		end
	end
	self:SetRewardListGroup()
	self:RefreshStoryView()
end
function UIActPtCopy:OnClickPageStory()
	local isFightType = gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_ACTIVITY_PLOT_COPY)
	if isFightType then
		--优先进入当前的战斗中
		gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_ACTIVITY_PLOT_COPY,{})
		return
	end

	self:RefreshStoryView()
end
function UIActPtCopy:GetCurGetRewardCnt()
	local cnt = 0
	local pageData = self._activityPageData[3]
	local entry =pageData and pageData.entry or nil
	self._pbRewardEntryDict = {}
	self._pbRewardEntryCanGetList = {}
	if not entry then
		return cnt
	end
	for k, v in ipairs(entry) do
		local status = v.status or v.goalData.status
		if status ~= 0 then
			cnt = cnt + 1
		end
		self._pbRewardEntryDict[v.entryId] = v
		if status == 1 then
			local data = { sid = self._sid, pageId = v.pageId, entryId = v.entryId }
			table.insert(self._pbRewardEntryCanGetList, data)
		end
	end
	return cnt
end

function UIActPtCopy:StoryRewardListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"itemRoot/Icon")
	local EffTrans = self:FindWndTrans(item,"Eff")
	local showEff = itemdata.isShowEff
	if EffTrans then
		local show = false
		if itemdata.itemType == LItemTypeConst.TYPE_ITEM and showEff then
			LxResUtil.DestroyChildImmediate(EffTrans)
			local itemRef = gModelItem:GetRefByRefId(itemdata.itemId)
			local bgEff = itemRef and itemRef.bgEff or nil
			if not string.isempty(bgEff) then
				show = true
				local instanceId = item:GetInstanceID()
				self:CreateWndEffect(EffTrans,bgEff,instanceId,66,false,false)
			end
		end
		CS.ShowObject(EffTrans,show)
	end

	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(root)
	end
	baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()
	self:SetIconClickScale(root, true)
	self:SetWndClick(root, function() gModelGeneral:ShowCommonItemTipWnd(itemdata) end)
end
function UIActPtCopy:GetPbEntryDataById(entryId)
	return self._pbRewardEntryDict[entryId]
end
function UIActPtCopy:InitBtnEvent()
	self:SetWndClick(self.mReturnBtn, function()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mReportLogBtn, function()
		self:OnClickReportLogBtn()
	end)
	self:SetWndClick(self.mStoryHelpBtn, function()
		self:OnClickStoryHelpBtn()
	end)
end
function UIActPtCopy:OnActivityConfigData(data, sid)
	if sid ~= self._sid then
		return
	end
	self.activityData = gModelActivity:GetActivityBySid(self._sid)
	self._cfgData = data
	self._startTime = self.activityData.startTime
	self._endTime = self.activityData.endTime
	local moreInfo 	= JSON.decode(self.activityData.moreInfo)
	self._openDay   = moreInfo.openDay
	self:TimerStop(self._showTimeKey)
	if(self._startTime~=0)then
		self:TimerStart(self._showTimeKey, 1, false, -1)
		self:SetTimeTxt()
	end
	CS.ShowObject(self.mStoryTimeBg,self._startTime~=0)
	self:SetData()
	gModelActivity:OnActivityPageReq(self._sid)
end
function UIActPtCopy:OnClickGet()
	local list = self._pbRewardEntryCanGetList or {}
	if(#list>0)then
		gModelActivity:OnActivityReceiveGoalListReq(list)
	end
end
function UIActPtCopy:DrawStoryListItem(list,item, itemdata, itempos)
	local image 	= self:FindWndTrans(item, "Image")
	local nameText 	= self:FindWndTrans(item, "NameText")
	local rewardList = self:FindWndTrans(item, "RewardList")
	local progressText = self:FindWndTrans(item, "ProgressText")
	local goBtn 	= self:FindWndTrans(item, "GoBtn")
	local redPoint  = self:FindWndTrans(goBtn, "redPoint")
	local lookBackBtn = self:FindWndTrans(item, "LookBackBtn")
	local lockCoverBg = self:FindWndTrans(item, "LockCoverBg")

	local InstanceID = item:GetInstanceID()
	local entryId	= itemdata.entryId
	local pageId 	= itemdata.pageId
	local rewards 	= itemdata.reward
	local status 	= itemdata.status
	local isLock	= itemdata.unlock
	local waitFrontChapter = isLock and itempos > self._curCanGoStoryChapter
	local unlock	= isLock and itempos <= self._curCanGoStoryChapter

	local schedule = itemdata.goalData.schedules[1]
	local goal  = tonumber(schedule.goal)
	local scdle = tonumber(schedule.schedule)
	local haveTime = scdle < goal

	self:SetWndEasyImage(image, itemdata.icon)
	self:SetWndText(nameText, itemdata.name)
	local addLine = 25
	if gLGameLanguage:IsForeignVersion() and not gLGameLanguage:IsEnglishVersion() then
		addLine = -5
	end
	self:InitTextLineWithLanguage(nameText, addLine)
	self:InitTextSizeWithLanguage(nameText, -2)

	local scheduleStr = scdle
	if haveTime then
		scheduleStr = LUtil.FormatColorStr(scheduleStr,"red")
	end
	scheduleStr = string.replace(ccClientText(21725), scheduleStr, goal)
	self:SetWndText(progressText, scheduleStr)

	local uiList = self:GetUIScroll(InstanceID.."Story")
	if(uiList:GetList())then
		uiList:RefreshList(rewards)
	else
		uiList:Create(rewardList,rewards,function (...) self:StoryRewardListItem(...) end)
	end

	local isShowGoing = true
	local btnStr
	local goBtnFunc = nil
	local isShowRed = false
	if unlock then
		if status == 0 then
			btnStr = ccClientText(21726)
			goBtnFunc = function()
				self:OnClickOpenStoryBtn(entryId)
			end
			isShowRed = true
		elseif status == 1 then
			btnStr = ccClientText(21712)
			local sid = self._sid
			local getRewardList = {
				{sid = sid,pageId = pageId,entryId = entryId},
			}
			goBtnFunc = function()
				self:OnClickGetStoryRewardBtn(getRewardList)
			end
			isShowRed = true
		else
			isShowGoing = false
			btnStr = ccClientText(21727)
			goBtnFunc = function()
				self:OnClickOpenStoryBtn(entryId)
			end
		end
	else
		btnStr = ccClientText(21726)
	end

	local btn = isShowGoing and goBtn or lookBackBtn
	CS.ShowObject(goBtn, isShowGoing)
	CS.ShowObject(redPoint, isShowRed)
	CS.ShowObject(lookBackBtn, not isShowGoing)
	self:SetWndButtonGray(btn,not unlock)
	self:SetWndButtonText(btn, btnStr)
	self:SetWndClick(btn, goBtnFunc)

	CS.ShowObject(lockCoverBg, not unlock)
	if not unlock then
		local lockText	  = self:FindWndTrans(lockCoverBg, "LockText")
		local lockStr
		if waitFrontChapter then
			lockStr = ccClientText(21728)
		else
			local openDayIndex = itemdata.openDayIndex
			local dayDateStr = self:GetStoryDateStr(openDayIndex)
			lockStr = string.replace(ccClientText(21724), dayDateStr)
		end
		self:SetWndText(lockText, lockStr)
	end
end
function UIActPtCopy:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
		self:OnActivityConfigData(...)
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end
function UIActPtCopy:SetDefultUI()
	self:SetWndText(self.mReturnBtnTxt,ccClientText(39000))
	self:SetWndText(self.mReportLogBtnName,ccClientText(39001))
end
function UIActPtCopy:OnClickOpenStoryBtn(entryId)
	local sid = self._sid
	-- GF.OpenWnd("UIActNewHeroThemeStory",{sid= sid,entryId = entryId,activityMode = ModelActivity.MODEL_ACTIVITY_TYPE_132})
end
function UIActPtCopy:InitData()
	self._uiCommonList 	= {}
	self._sid = self:GetWndArg("sid")
	local subpage= self:GetWndArg("subPage") --支持跳转
	if subpage then
		self._sid = gModelActivity:GetSidByUniqueJump(subpage)
	end
	self._showTimeKey = "_endTimeKey"
	self:SetDefultUI()
	gModelActivity:ReqActivityConfigData(self._sid)
end
function UIActPtCopy:CreateSpine(key, spineRoot, spineName, pos, isTurn,scaleValue)
	self:DestroyWndSpineByKey(spineName)
	local dpSpineObj = self:CreateWndSpine(spineRoot, spineName, key, false, function(dpSpine)
		dpSpine:SetIgnoreTimeScale(true)
	end)
	local scaleX = isTurn and -1 or 1
	local scaleNum = scaleValue and scaleValue or 1
	if (pos) then
		self:SetAnchorPos(spineRoot, LxDataHelper.ParseVector2NotEmpty3(pos))
	end
	spineRoot.localScale = Vector3.New(scaleX * scaleNum, scaleNum, 1)
	return dpSpineObj
end
function UIActPtCopy:SetTimeTxt()
	local nowTime = GetTimestamp()
	local timeDif = os.difftime(self._endTime, nowTime)
	if timeDif < 0 then
		self:TimerStop(self._showTimeKey)
		self:WndClose()
		return
	end
	local timeStr = LUtil.FormatTimespanCn(timeDif)
	timeStr = string.replace(ccClientText(39002),timeStr)
	--timeStr = string.replace(timeStr)
	self:SetWndText(self.mStoryTimeText,timeStr)
end
------------------------------------------------------------------
function UIActPtCopy:OnClickReportLogBtn()
	local storyWarReport = self._mainCfg.storyWarReport
	local sid = self._sid
	-- GF.OpenWnd("UIActNewHeroThemeVideo",
	-- 		{sid = sid, storyWarReport = storyWarReport, activityMode = ModelActivity.MODEL_ACTIVITY_TYPE_132})
end
function UIActPtCopy:SetData()
	local cfgData = self._cfgData --配置表f
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if (not cfgData or not activityData) then
		return
	end
	self._mainCfg = cfgData.config
	self._copyEntriesCfg = cfgData.chunk[1].entries--副本
	self._levelEntriesCfg = cfgData.chunk[2].entries--关卡
	self._rewardsEntriesCfg = cfgData.chunk[3].entries--进度奖励
	self:SetUI()
end
function UIActPtCopy:OnClickGetStoryRewardBtn(list)
	gModelActivity:OnActivityReceiveGoalListReq(list)
end
------------------------------------------------------------------
return UIActPtCopy


