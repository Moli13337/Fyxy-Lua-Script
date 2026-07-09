---
--- Created by BY.
--- DateTime: 2023/10/16 16:35:45
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubActRoom:LChildWnd
local UISubActRoom = LxWndClass("UISubActRoom", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubActRoom:UISubActRoom()
	self._uiheadList = {}
	self._rankType = 2		--1跨服2个人3单服
	self._rankTypeList = {}
	self._rankInfoTypeList = {}
	self._timeKey = "UISubActRoom_timeKey"
	self._timeShowTipsKey = "UISubActRoom__timeShowTipsKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubActRoom:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubActRoom:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubActRoom:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UISubActRoom:RefreshData()
	--local activityDataS = gModelActivity:GetActivityBySid(self._sid)
	--local dataS = JSON.decode(activityDataS.moreInfo)
	--self._guildSumExp = dataS.guildSumExp
	self:RefreshUse()
	self:RefreshLvBox()
	self:RefreshContributeBox()
	self:RefreshRed()
end
function UISubActRoom:OnClickCard()
	GF.OpenWnd("UIActPrigeCard",{sid = self._sid})
end

function UISubActRoom:ReqRank()
	local rankType = self._rankType
	local listIndex = rankType == 2 and 2 or 1
	local _rankTypeData = self._rankTypeList[listIndex]
	local _reqRankId = _rankTypeData.rankId
	gModelRank:OnRankReq(2,_reqRankId,1,3,self._sid)
end

function UISubActRoom:InitData()
	self._modelEnumList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = {
		-- 	ModelActivity.SWEET_COUNTRY_21,
		-- 	ModelActivity.SWEET_COUNTRY_13,
		-- 	ModelActivity.SWEET_COUNTRY_23,
		-- 	ModelActivity.SWEET_COUNTRY_24,
		-- },
	}
	self._modelPageIdList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = {
		-- 	ModelActivity.SWEET_COUNTRY_19,
		-- },
	}
	self._modelOpTypeList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_72] = ModelActivity.SWEETS_COUNTRY_GUILD_DONATION,
	}
	self:SetWndText(self.mTop1Text,ccClientText(27633))
	self:SetWndText(self.mRankText,ccClientText(27636))
	self:SetWndText(self.mCardText,ccClientText(27639))
	self:SetWndText(self.mShopText,ccClientText(27640))
	self:SetWndText(self.mLogText,ccClientText(27641))
	self:SetWndText(self.mLevelText,ccClientText(27663))

	CS.ShowObject(self.mBtnRank,true)
	CS.ShowObject(self.mBtnLook,true)
	CS.ShowObject(self.mBtnLog,true)
end
function UISubActRoom:RefreshRank()
	local rankType = self._rankType
	local listIndex = rankType == 2 and 2 or 1
	local _rankTypeData = self._rankTypeList[listIndex]
	local _rankInfoTypeData = self._rankInfoTypeList[listIndex]
	if not _rankTypeData or not _rankInfoTypeData then return end

	local list = {}
	for i = 1, 3 do
		local info = _rankInfoTypeData[i]
		table.insert(list,info)
	end
	local uiRankList = self._uiRankList
	if uiRankList then
		uiRankList:RefreshList(list)
	else
		uiRankList = self:GetUIScroll("UISubActRoom_mRankScroll")
		uiRankList:Create(self.mRankScroll,list,function(...) self:RankListItem(...) end)
		self._uiRankList = uiRankList
	end
end
function UISubActRoom:RefreshGuild()
	local isGuild =  gModelGuild:GetBHaveGuild()
	CS.ShowObject(self.mGuildMask,not isGuild)
	if not isGuild then
		self:CreateEmptyShow( 5402)
		return
	end
	gModelActivity:OnActivitySweetsCountryLogsReq(self._sid)
end
function UISubActRoom:OnClickCutRank()
	local _activityOpenType = self._activityOpenType
	local rankType = self._rankType
	local qfType = _activityOpenType == 1 and 3 or 1
	rankType = rankType == 2 and qfType or 2
	self._rankType = rankType
	local listIndex = rankType == 2 and 2 or 1
	local _rankTypeData = self._rankTypeList[listIndex]
	local _reqRankId = _rankTypeData.rankId
	local top2QfStr = _activityOpenType == 2 and ccClientText(27634) or ccClientText(27664)
	local lookQfStr = _activityOpenType == 2 and ccClientText(27638) or ccClientText(27665)
	self:SetWndText(self.mTop2Text,rankType == 2 and ccClientText(27651) or top2QfStr)
	self:SetWndText(self.mTop3Text,rankType == 2 and ccClientText(27652) or ccClientText(27635))
	self:SetWndText(self.mLookText,rankType == 2 and lookQfStr or ccClientText(27637))
	gModelRank:OnRankReq(2,_reqRankId,1,3,self._sid)
end
function UISubActRoom:GetCurBoxItem(entry)
	local curLv = nil
	for i, v in ipairs(entry) do
		local goalData = v.goalData
		local status = goalData.status
		if status == 1 then
			curLv = v
			break
		end
	end
	return curLv
end
function UISubActRoom:OnClickBox(itemdata)
	local goalData = itemdata.goalData
	local status = goalData.status
	if status == 0 then
		return
	elseif status == 2 then
		GF.ShowMessage(ccClientText(27656))
		return
	end
	gModelActivity:OnActivityReceiveGoalReq(self._sid,itemdata.pageId,itemdata.entryId)
end

function UISubActRoom:CreateEmptyShow(refId)
	local text = self:FindWndTrans(self.mEmptyBtn,"Light/Text")
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
		GetBtn = self.mEmptyBtn,
		GetBtnText = text,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end
function UISubActRoom:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildInfoResp,function (pb)
		self:RefreshGuild()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:ResetData(pb)
	end)
	--self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
	--	if sid ~= self._sid then return end
	--	self:OnActivityConfigData()
	--end)
	--self:WndNetMsgRecv(LProtoIds.ActivitySweetsCountryLogsResp,function (pb)
	--	self:RefreshLog()
	--end)
	self:WndNetMsgRecv(LProtoIds.ActivitySpecialOpResp,function (pb)
		local sid = pb.sid
		local opType = pb.opType
		if opType == self._donateEnum then
			gModelActivity:OnActivitySweetsCountryLogsReq(self._sid)
			self:ReqRank()
		end
	end)
	self:WndNetMsgRecv(LProtoIds.RankResp,function (pb)
		local sid = pb.activityId
		if(not sid or self._sid ~= sid)then return end
		local _rankTypeList = self._rankTypeList
		if #_rankTypeList <= 0 then return end
		local rankRespType = 1
		local rankType = pb.rankType
		for i, v in ipairs(_rankTypeList) do
			if rankType == v.rankId then
				rankRespType = i
				break
			end
		end

		local rankInfoList = {}
		local isThree = false
		local selfRank = gModelRank:GetStructRankInfo(pb.selfRank)
		local infos = pb.infos
		local rankInfos = {}
		local len = 0
		for i, v in ipairs(infos) do
			local info = gModelRank:GetStructRankInfo(v)
			if selfRank.rank == info.rank then
				isThree = true
			end
			len = len + 1
			table.insert(rankInfos,info)
		end
		if isThree or selfRank.rank == 0 or selfRank.rank == -1 then
			rankInfoList = rankInfos
		else
			local beforeRank = gModelRank:GetStructRankInfo(pb.beforeRank)
			rankInfoList[1] = rankInfos[1]
			if beforeRank and beforeRank.rank > 0 then
				rankInfoList[2] = beforeRank
				rankInfoList[3] = selfRank
			else
				rankInfoList[2] = selfRank
			end
		end
		self._rankInfoTypeList[rankRespType] = rankInfoList

		self:RefreshRank()
	end)
	self:WndNetMsgRecv(LProtoIds.ItemChangeResp,function (pb)
		self:RefreshUse()
	end)
	self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:RefreshRed() end)
end
function UISubActRoom:RefreshLvBox()
	local _sid = self._sid
	local _pages = self._pages or {}
	local _page = _pages[self._roomEnum]
	if not _page then return end
	local entry = _page.entry
	local moreInfo = JSON.decode(_page.moreInfo)
	local guild_donation_count = {}
	for i, v in ipairs(self._itemUseLimit) do
		local itemId = v.itemId
		local num = moreInfo[tostring(itemId)]
		guild_donation_count[itemId] = num
	end
	self._guild_donation_count = guild_donation_count
	local guildSumExp = moreInfo.guildSumExp
	local curLv = self:GetCurBoxItem(entry)
	CS.ShowObject(self.mBtnLvBox,curLv)
	if curLv then
		self._lvItemData = curLv
	end
	local curBarLv = self:GetCurBarItem(entry)
	if curBarLv then
		self._barItemData = curBarLv
		local goalData = curBarLv.goalData
		local status = goalData.status
		local schedule = goalData.schedules[1]
		local goal = schedule.goal
		local schedule = schedule.schedule
		local entryCfg = gModelActivity:GetWebActivityEntryData(_sid,curBarLv.pageId,curBarLv.entryId)

		local goal = tonumber(goal)
		local nexValue = guildSumExp > goal and goal or guildSumExp
		self.mLvBar.maxValue = goal
		self.mLvBar.value = nexValue
		local _oldValue = self._oldValue
		if _oldValue and _oldValue ~= nexValue then
			local chaValue = nexValue - _oldValue
			local chaValueStr = LUtil.FormatHurtNumSpriteText(chaValue)
			self:SetWndText(self.mExpUpText,"<sprite index=10>"..chaValueStr)
			CS.ShowObject(self.mExpUpText,true)
			local _timeKey = self._timeShowTipsKey
			self:TimerStop(_timeKey)
			self:TimerStart(_timeKey,1,false,1)
		end
		self._oldValue = nexValue
		self:SetWndText(self.mLvText,entryCfg.name)
		self:SetWndText(self.mLvBarText,string.format("%s/%s",guildSumExp,goal))

		local _oldEntryId = self._oldEntryId
		if _oldEntryId and _oldEntryId ~= curBarLv.entryId then
			self:CreateWndEffect(self.mEff,self._changeEff,"UISubActRoom_mEff",100)
		end
		self._oldEntryId = curBarLv.entryId

		local moreInfo = string.split(entryCfg.moreInfo,"|")
		if #moreInfo <= 0 then return end
		for i, v in ipairs(moreInfo) do
			local img = self:FindWndTrans(self.mBgImage2,"Image"..i)
			if img then
				local arr = string.split(v,"=")
				if LxUiHelper.IsImgPathValid(arr[1]) then
					CS.ShowObject(img,true)
					self:SetWndEasyImage(img,arr[1],nil,true)
					if not string.isempty(arr[2]) then
						local pos = LxDataHelper.ParseVector2NotEmpty(arr[2])
						self:SetAnchorPos(img, pos)
					end
				end
			end
		end
	end
end
function UISubActRoom:OnClickRank()
	local sid = self._sid
	local _pages = self._pages
	local rankType = self._rankType
	local listIndex = rankType == 2 and 2 or 1
	local _rankTypeData = self._rankTypeList[listIndex]
	local _reqRankId = _rankTypeData.rankId
	local rankAwardId = _rankTypeData.rankAwardId
	local _rewardList = nil
	if rankAwardId then
		local page =  _pages[rankAwardId]
		if not page then return end
		_rewardList = LxDataHelper.SevenParseRewardList(sid,page)
	end
	local wndName = self:GetParentWndName()
	GF.OpenWndBottom("UIRkPop",{refId = _reqRankId,sid = sid,rewardList = _rewardList,callFunc = function()
		GF.OpenWnd(wndName,{sid = sid})
	end})
	GF.CloseWndByName(wndName)
end
function UISubActRoom:InitEvent()
	self:SetWndClick(self.mBtnLvBox,function ()self:OnClickLvBox() end)
	self:SetWndClick(self.mBtnHelp,function ()self:OnClickHelp() end)
	self:SetWndClick(self.mBtnCard,function ()self:OnClickCard() end)
	self:SetWndClick(self.mBtnShop,function ()self:OnClickShop() end)
	self:SetWndClick(self.mBtnLog,function ()self:OnClickLog() end)
	self:SetWndClick(self.mContributeBox,function ()self:OnClickContributeBox() end)
	self:SetWndClick(self.mBtnRank,function ()self:OnClickRank() end)
	self:SetWndClick(self.mBtnLook,function ()self:OnClickCutRank() end)
end
function UISubActRoom:ResetData(pb)
	local _pages = self._pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		local pageId = page.pageId
		_pages[pageId] = page
	end
	self._pages = _pages
	self:RefreshData()
end
function UISubActRoom:OnClickContributeBox()
	local itemdata = self._taskItemData
	if not itemdata then
		GF.ShowMessage(ccClientText(27656))
		return
	end
	local goalData = itemdata.goalData
	local status = goalData.status
	local schedules = goalData.schedules[1]
	local goal = schedules.goal
	local schedule = schedules.schedule
	if status == 0 then
		GF.ShowMessage(string.replace(ccClientText(27659),goal - schedule))
		local items = itemdata.items
		local rewardList = LxDataHelper.SevenParseItems(items)
		GF.OpenWnd("UIringBoxDetailTop",{self.mContributeBox, rewardList})
		return
	end
	self:OnClickBox(itemdata)
end
function UISubActRoom:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config
	local itemUseLimit,rankId,candyGameBg,changeEff,changeEffPos
	= data.expSettings,data.rankId,data.candyGame,data.changeEff,data.changeEffPos
	self._candyGameHelpTxt = data.candyGameHelpTxt
	self._changeEff = changeEff
	self._activityOpenType = data.activityOpenType or 1

	if LxUiHelper.IsImgPathValid(candyGameBg) then
		self:SetWndEasyImage(self.mBgImage2,candyGameBg,nil,true)
	end
	if not string.isempty(itemUseLimit) then
		local arr = string.split(itemUseLimit,"|")
		local list = {}
		for i, v in ipairs(arr) do
			local items = string.split(v,",")
			local data = {
				itemId = tonumber(items[1]),
				limit = tonumber(items[2]),
			}
			table.insert(list,data)
		end
		self._itemUseLimit = list
	end
	if not string.isempty(rankId) then
		local rankArr = string.split(rankId,",")
		local rankTypeList = {}
		for i, v in ipairs(rankArr) do
			local arr = string.split(v,"=")
			local rankId = arr[1] and tonumber(arr[1])
			local rankAwardId = arr[2] and tonumber(arr[2])
			rankTypeList[i] = {
				rankId = rankId,
				rankAwardId = rankAwardId,
			}
		end
		self._rankTypeList = rankTypeList
		self:OnClickCutRank()
	end
	if not string.isempty(changeEffPos) then
		local pos = LxDataHelper.ParseVector2NotEmpty2(changeEffPos)
		self:SetAnchorPos(self.mEff, pos)
	end

	local activityDatas = gModelActivity:GetActivityBySid(sid)
	local _endTime = activityDatas.endTime
	local _timeKey = self._timeKey
	if(_endTime and _endTime ~= -1)then
		self:TimerStop(_timeKey)
		self:TimerStart(_timeKey,1,false,-1)
		self:SetTime()
	end

	local enums = self._modelEnumList[self._modelId]
	gModelActivity:OnActivityPageReq(self._sid,enums)
	--self:RefreshData()
end
function UISubActRoom:RefreshUseItem(trans,itemdata)
	if not trans then return end
	local iconTr = self:FindWndTrans(trans,"Icon")
	local maskTr = self:FindWndTrans(trans,"Mask")
	local textTr = self:FindWndTrans(trans,"NumBg/Text")

	local itemId = itemdata.itemId
	CS.ShowObject(trans,true)
	local quality = gModelItem:GeQualityByRefId(itemId)
	self:SetWndEasyImage(trans,"activity_music3_bg_"..quality)
	local icon,iconBg = gModelItem:GetItemImgByRefId(itemId)
	local itemNum = gModelItem:GetNumByRefId(itemId)
	self:SetWndEasyImage(iconTr,icon)
	local textStr = LUtil.FormatColorStr(LUtil.NumberCoversion(itemNum),itemNum <= 0 and "lightRed" or "white")
	self:SetWndText(textTr,textStr)
	CS.ShowObject(maskTr,itemNum <= 0)
	self:SetWndClick(trans,function ()
		if itemNum > 0 then
			self:OnClickItem(itemdata)
		else
			local wndName = self:GetParentWndName()
			gModelGeneral:OpenGetWayWnd({itemId = itemId,srcWnd = wndName})
		end
	end)
end
function UISubActRoom:RankListItem(list, item, itemdata, itempos)
	local rankIcon = self:FindWndTrans(item,"RankIcon")
	local rankText = self:FindWndTrans(item,"RankText")
	local nameText = self:FindWndTrans(item,"NameText")
	local scoreText = self:FindWndTrans(item,"ScoreText")

	if not itemdata then return end
	local rank = itemdata.rank
	local score = itemdata.score
	local serverName = itemdata.serverName
	local info = itemdata.info
	local _name = info and info._name or ""
	local rankType = self._rankType
	local _activityOpenType = self._activityOpenType or 1

	CS.ShowObject(rankIcon,0 < rank and rank <= 3)
	CS.ShowObject(rankText,rank < 0 or rank > 3)
	self:SetWndText(rankText,rank == -1 and ccClientText(26422) or rank)
	self:SetWndEasyImage(rankIcon,"public_num_"..rank)
	local nameQfStr = _activityOpenType == 2 and serverName or info._guildName
	self:SetWndText(nameText,rankType == 2 and _name or nameQfStr)
	local scoreStr = LUtil.NumberCoversion(score)
	self:SetWndText(scoreText,scoreStr)
end
function UISubActRoom:RefreshLog()
	local logs = gModelActivity:GetSweetsCountryLogs()
	if not logs then return end
	local list = {}
	local logLen = #logs
	if logs[logLen - 1] then
		table.insert(list,logs[logLen - 1])
	end
	if logs[logLen] then
		table.insert(list,logs[logLen])
	end
	local uiLogList = self._uiLogList
	if uiLogList then
		uiLogList:RefreshList(list)
	else
		uiLogList = self:GetUIScroll("UISubActRoom_mLogScroll")
		uiLogList:Create(self.mLogScroll,list,function (...) self:LogListItem(...) end)
	end
end
function UISubActRoom:LogListItem(list, item, itemdata, itempos)
	local image = self:FindWndTrans(item,"Image")
	local headIcon = self:FindWndTrans(item,"HeadMag/HeadIcon")
	local desText = self:FindWndTrans(item,"DesText")

	local playerName = itemdata.playerName
	local consume = LxDataHelper.ParseItem_3(itemdata.consume)
	local info = {
		icon = itemdata.head,
		headFrame = itemdata.headFrame,
	}
	local InstanceID = item:GetInstanceID()
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	info.trans = headIcon
	baseClass:SetHeadData(info)

	local desStr = ccClientText(27642)
	local name = gModelGeneral:GetCommonItemColorNameNoNum(consume)
	self:SetWndText(desText,string.replace(desStr,playerName,name .."*".. consume.itemNum))
	self:SetWndClick(headIcon,function ()
		gModelGeneral:PlayerShowReq(itemdata.playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
	end)
	self:SetWndClick(image,function ()
		self:OnClickLog()
	end)
end
function UISubActRoom:OnClickHelp()
	local content = self._candyGameHelpTxt
	local title = ccClientText(11614)
	GF.OpenWnd("UIBzTips",{title= title,text = content})
end

function UISubActRoom:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	elseif key == self._timeShowTipsKey then
		CS.ShowObject(self.mExpUpText,false)
	end
end
function UISubActRoom:OnClickItem(itemdata)
	if not itemdata then return end
	local itemId = itemdata.itemId
	local limit = itemdata.limit
	--if limit == -1 then
	--	limit = nil
	--end
	local itemNum = gModelItem:GetNumByRefId(itemId)
	local _guild_donation_count = self._guild_donation_count
	local useNum = _guild_donation_count[itemId] or 0

	local limitNum = (limit == -1 or limit > itemNum) and itemNum or limit - useNum
	GF.OpenWndUp("UISyeProp",{refId = itemId,maxValue = limitNum,callFunc = function (num)
		local _sid = self._sid
		local _donateEnum = self._donateEnum
		local _lvItemData = self._barItemData

		local itemId = itemId
		local str = itemId .. "=" .. num
		gModelActivity:OnActivitySpecialOpReq(_sid,_lvItemData.pageId,_lvItemData.entryId,0,str,_donateEnum)
	end})


end
function UISubActRoom:GetCurBarItem(entry)
	local curLv = nil
	for i, v in ipairs(entry) do
		local goalData = v.goalData
		local status = goalData.status
		if status == 0 then
			curLv = v
			break
		end
	end
	if not curLv then
		curLv = entry[#entry]
	end
	return curLv
end
function UISubActRoom:SetTime()
	local mTimeText = self.mTimeText
	local _timeKey = self._timeKey
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then
		return
	end
	local endTime = activityData.endTime
	if endTime == 0 then
		self:TimerStop(_timeKey)
		self:SetWndText(mTimeText,ccClientText(18404))
		return
	end
	local time = GetTimestamp()
	local timespan = endTime - time
	local  timeStr = ""
	if(timespan < 0)then
		timeStr = ccClientText(14301)
		self:TimerStop(_timeKey)
	else
		timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(ccClientText(27645),timeStr)
	end
	self:SetWndText(mTimeText,timeStr)
end
function UISubActRoom:OnClickLog()
	GF.OpenWnd("UIActRoomLogPop",{sid = self._sid})
end
function UISubActRoom:RefreshRed()
	local _sid = self._sid
	local taskRed = gModelRedPoint:GetActivityRedPointPage(_sid,self._roomTaskEnum)
	CS.ShowObject(self.mContributeRedPoint,taskRed)
	local taskRed = gModelRedPoint:GetActivityRedPointPage(_sid,self._roomCardEnum)
	CS.ShowObject(self.mCardRedPoint,taskRed)
end
-------------------------------------------------------点击事件---------------------------------------------------------
function UISubActRoom:OnClickLvBox()
	local itemdata = self._lvItemData
	if not itemdata then return end
	self:OnClickBox(itemdata)
end
function UISubActRoom:InitCommand()
	local sid = self:GetWndArg("sid")
	--local entry = self:GetWndArg("entry")
	--local pages = self:GetWndArg("pages")

	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._sid = sid
	--self._pages = pages
	self._modelId = modelId

	local enums = self._modelEnumList[modelId]
	self._roomEnum = enums[1]
	self._roomTaskEnum = enums[2]
	local pageIds = self._modelPageIdList[modelId]
	self._roomCardEnum = pageIds[1]
	local opTypes = self._modelOpTypeList[modelId]
	self._donateEnum = opTypes
	self:OnActivityConfigData()

	self:RefreshGuild()
end
function UISubActRoom:GetCurItem(entry)
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
function UISubActRoom:RefreshUse()
	local _itemUseLimit = self._itemUseLimit or {}
	for i, v in ipairs(_itemUseLimit) do
		local trans = self:FindWndTrans(self.mBtnItemMag,"BtnItem"..i)
		self:RefreshUseItem(trans,v)
	end
	CS.ShowObject(self.mBtnItemMag,true)
end
function UISubActRoom:RefreshContributeBox()
	local _sid = self._sid
	local _pages = self._pages or {}
	local _page = _pages[self._roomTaskEnum]
	if not _page then return end
	local entry = _page.entry

	local curLv = self:GetCurItem(entry)
	if curLv then
		self._taskItemData = curLv
		local goalData = curLv.goalData
		local status = goalData.status
		local schedule = goalData.schedules[1]
		local goal = schedule.goal
		local schedule = schedule.schedule
		local entryCfg = gModelActivity:GetWebActivityEntryData(_sid,curLv.pageId,curLv.entryId)

		local isGet = tonumber(schedule) >= tonumber(goal)
		local str = LUtil.FormatColorStr(schedule,isGet and "lightGreen" or "lightRed")
		local des = string.replace(entryCfg.name,str)
		des = string.gsub(des,"\\n","\n")
		if status == 2 then
			des = ccClientText(27660)
		elseif status == 1 then
			des = ccClientText(27661)
		end
		self:SetWndText(self.mContributeText,des)
	end
end
function UISubActRoom:OnClickShop()
	local _sid = self._sid
	GF.OpenWndBottom("UIDian",{page = ModelShop.ACTIVITY,subPage = _sid})
end
------------------------------------------------------------------
return UISubActRoom


