---
--- 模板116 烟花城堡
--- Created by Ease.
--- DateTime: 2023/10/28 21:47:28
---
------------------------------------------------------------------
local typeofImage = typeof(UnityEngine.UI.Image)
local LWnd = LWnd
---@class UIFireastle:LWnd
local UIFireastle = LxWndClass("UIFireastle", LWnd)
UIFireastle.BossSpine = 1
UIFireastle.BoxSpine = 2
UIFireastle.FireworkBtnSoundRefId = 252 --烟花按钮音效
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFireastle:UIFireastle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFireastle:OnWndClose()
	self:StopDelayTimer()
	local wndIns = GF.FindFirstWndByName("UIBulletSay")
	if (wndIns) then
		GF.CloseWndByName("UIBulletSay")
	end
	local wndActivityWarPassEIns = GF.FindFirstWndByName("UIActWarPkE")
	if (wndActivityWarPassEIns) then
		GF.CloseWndByName("UIActWarPkE")
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFireastle:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFireastle:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitBtnEvent()
	self:InitEvent()
	self:InitMessage()
	self:InitData()

	CS.ShowObject(self.mRankTimeTxt.parent, false) -- 应该要求，先隐藏
end

function UIFireastle:UseFireworksItem(itemId, useNum, useTimes)
	local uTimes = useTimes or 1
	--local uTimes = 200
	local num = useNum * uTimes
	local itemList = {
		[1] = { refId = itemId, num = num }
	}
	if (num > 0) then
		gModelItem:OnItemUseReq(itemList)
	end
end

function UIFireastle:SetTaskList()
	self.taskList = self:GetTaskList()
	local schedulesStatusList, moveToIndex = self:SetSchedulesStatus()
	self.schedulesStatusList = schedulesStatusList
	self.maxSchedule = tonumber(self.taskList[#self.taskList].goalData.schedules[1].goal)
	local _scheduleList = self._scheduleList
	if (_scheduleList) then
		_scheduleList:RefreshList(self.taskList)
	else
		_scheduleList = self:GetUIScroll("mScheduleList")
		_scheduleList:Create(self.mScheduleList, self.taskList, function(...)
			self:OnDrawScheduleListCell(...)
		end, UIItemList.SUPER)
		_scheduleList:EnableScroll(true, false)
	end
	self._scheduleList = _scheduleList
	self.moveToIndex = moveToIndex
	_scheduleList:DrawAllItems()
	if (moveToIndex and moveToIndex > 5) then
		self._scheduleList:MoveToPos(moveToIndex)
		self.moveToIndex = nil
	end
end
function UIFireastle:GetCurSchedules()
	local curPbDataList = self.taskList
	local scheduleCnt = 0
	for i, v in ipairs(curPbDataList) do
		local curGoalData = v.goalData
		local curGoal = tonumber(curGoalData.schedules[1].goal)
		local curSchedule = tonumber(curGoalData.schedules[1].goal)
		scheduleCnt = (curGoal == curSchedule) and curGoal or curSchedule
	end
	return scheduleCnt
end

function UIFireastle:OnLongClickFireBtn()
	self.longClickCnt = 0
	if (self.clickStart) then
		return
	end
	self._isPlayFireBoxAni = false
	self.longClickStart = true
	self.longFireBoxAniPlayStart = true
	self:OnClickFireBtn(true)
	self._bossHitLongLoopTimer = LxTimer.LoopTimeCall(function()
		self:OnClickFireBtn(true)
	end, 3, false, -1)
	if (not self._longClickCntTimer) then
		self:CreateLongClickCntTimer(self._mainCfg.boxFashe2)
	end
	--self:PlayClickFirBtnSound(true)
end

function UIFireastle:OnTryRefreshRedPoint(redPointType)
	if redPointType == ModelRedPoint.ACTIVITY_TYPE4 then
		self:SetWarOrderBtnRP()
	end
end

function UIFireastle:StopLongUsingItemDelayTimer()
	if self._longClickCntTimer then
		LxTimer.LoopTimeStop(self._longClickCntTimer)
		self._longClickCntTimer = nil
	end
end

function UIFireastle:GetSchedulesByIndex(index, lastData)
	local curPbData = self.taskList[index]
	local curGoalData = curPbData.goalData
	local curGoal = tonumber(curGoalData.schedules[1].goal)
	local scheduleData = {
		schedules = 0,
		status = curGoalData.status,
	}
	if (not lastData or lastData.schedules == 1) then
		local nextPbData = self.taskList[index + 1]
		if (nextPbData) then
			local nextGoal = tonumber(nextPbData.goalData.schedules[1].goal)
			local nextSchedules = tonumber(nextPbData.goalData.schedules[1].schedule)
			scheduleData.schedules = (nextSchedules - curGoal) / (nextGoal - curGoal)
		end
	end
	return scheduleData
end

function UIFireastle:PlayBossHit()
	if(not self._mainCfg.bossHitAction or string.isempty(self._mainCfg.bossHitAction))then
		return
	end
	local dpSpine = self:GetSpineByType(UIFireastle.BossSpine)
	local bossHitActionArr = string.split(self._mainCfg.bossHitAction, "=")
	local delayPlayTime = tonumber(bossHitActionArr[1])
	local playTotleTimes = tonumber(bossHitActionArr[2])
	local playInterval = tonumber(bossHitActionArr[3])

	self._curBossHitPlayTimes = 0

	self:StopBossHitDelayTimer()
	self:StopHitDelayTimerList()

	local delayCallBack = function()
		if (playTotleTimes > 1) then
			self._bossHitLoopTimer = LxTimer.LoopTimeCall(function()
				self:PlaySpineAnimation(dpSpine, "hit1", function()
					if (self._curBossHitPlayTimes == playTotleTimes) then
						self._curBossHitPlayTimes = 0
						self:StopBossHitDelayTimer()
					end
					dpSpine:PlayAnimationSolid("idle", true)
				end, UIFireastle.BossSpine)
			end, playInterval, false, playTotleTimes - 1)
		else
			self._curBossHitPlayTimes = 0
			self:StopBossHitDelayTimer()
		end
		dpSpine:PlayAnimationSolid("idle", true)
	end

	self._bossDelayTimer = LxTimer.DelayTimeCall(function()
		self:PlaySpineAnimation(dpSpine, "hit1", delayCallBack, UIFireastle.BossSpine)
	end, delayPlayTime, false)

	local hitEffArr = string.split(self._mainCfg.bossHitEffect, "|")
	for i, v in ipairs(hitEffArr) do
		local effDataArr = string.split(v, "=")
		local delay = tonumber(effDataArr[1])
		local pos = effDataArr[2]
		local effName = effDataArr[3]
		local scaleRate = tonumber(effDataArr[4])

		local delayTimer = LxTimer.DelayTimeCall(function()
			self:CreateWndEffect(self.mBossHitEffRoot,
					effName, effName, 100 * scaleRate,
					false, false, nil,
					function(dpTrans)
						if not string.isempty(pos) then
							local effPos = LxDataHelper.ParseVector2NotEmpty(pos)
							local v3Pos = Vector3.New(effPos.x, effPos.y, 0)
							dpTrans.localPosition = v3Pos
						end
					end)
		end, delay, false)
		table.insert(self._bossHitDelayTimerList, delayTimer)
	end
end

--clickType: 1：点击按钮，2：长按按钮
function UIFireastle:LetOffFireworks(itemId, itemNum, clickType)
	self.clickStart = clickType == 1 and true or nil
	if (self.longFireBoxAniPlayStart) then
		--播放烟花特效
		self:ShowFireworksEff()
		--播放年兽受击
		self:PlayBossHit()
	else
		if (clickType == 1) then
			self:PlayFireBoxAniOnClick()
		end
	end
	local usingItemDelayTime = self._mainCfg.effectPlayTime or 4
	--使用道具
	if (clickType == 1 and not self._usingItemDelay) then
		self._usingItemDelay = LxTimer.DelayTimeCall(function()
			self:UseFireworksItem(itemId, itemNum, 1)
			self:StopUsingItemDelayTimer()
			self.clickStart = nil
		end, usingItemDelayTime, false)
	end
end

function UIFireastle:OnCurrencyScroll(list, item, itemdata, itempos)
	local itemIcon = self:FindWndTrans(item, "Icon")
	local num = self:FindWndTrans(item, "Num")
	local itemArr = string.split(itemdata, "=")
	local itemId = itempos == 1 and tonumber(itemArr[1]) or tonumber(itemArr[2])
	local icon = gModelItem:GetItemImgByRefId(itemId)
	local itemNum = 0
	if (itempos == 2) then
		if (self.longClickStart) then
			itemNum = self.longClickStart and self.showCurrencyItemNum or 0
		elseif (self.restCurrency) then
			itemNum = gModelItem:GetNumByRefId(itemId)
		end
	else
		itemNum = gModelItem:GetNumByRefId(itemId)
	end
	self:SetWndEasyImage(itemIcon, icon)
	local numStr = LUtil.NumberCoversion(itemNum)
	self:SetWndText(num, numStr)
	self:SetWndClick(item, function()
		if (itempos == 1) then
			local itemData = {
				itemId = itemId,
				itemNum = itemNum,
				itemType = 1,
			}
			gModelGeneral:ShowCommonItemTipWnd(itemData)
		else
			gModelGeneral:OpenGetWayWnd({ itemId = itemId, srcWnd = "WndMistCastle" })
		end
	end)
end
function UIFireastle:CreateLongClickCntTimer(longClickCntInterval)
	self:StopLongUsingItemDelayTimer()
	self:DoPlayBoxFireAni()
	self._longClickCntTimer = LxTimer.LoopTimeCall(function()
		self:DoPlayBoxFireAni()
	end, longClickCntInterval, false, -1)
end

function UIFireastle:StopDelayTimer()
	self:StopBossHitDelayTimer()
	self:StopBossLongHitDelayTimer()
	self:StopHitDelayTimerList()
	self:StopUsingItemDelayTimer()
	self:StopLongUsingItemDelayTimer()
	self:StopLongClickBtnSoundDelayTimer()
	self:StopdelayPlayClickBtnSoundDelayTimer()
	self:StopLongClickBtnSoundLoopTimer()
end

function UIFireastle:GetTaskList()
	local pageList = self._pbDataList
	for i, v in ipairs(pageList) do
		local page = v
		if (page.pageType == 1) then
			return page.entry
		end
	end
end

function UIFireastle:StopUsingItemDelayTimer()
	if self._usingItemDelay then
		LxTimer.LoopTimeStop(self._usingItemDelay)
		self._usingItemDelay = nil
	end
end

-----------------------------------------------
function UIFireastle:OnUITouchEnd(screenPos)
	self.showCurrencyItemNum = nil
	if (not self.longClickStart) then
		return
	end
	self:LongClickUseFireworksItem()
	self:StopBossLongHitDelayTimer()
	self:StopLongUsingItemDelayTimer()
	self:StopLongClickBtnSoundDelayTimer()
	self:StopdelayPlayClickBtnSoundDelayTimer()
	self:StopLongClickBtnSoundLoopTimer()
	self.longClickStart = nil
	self.longFireBoxAniPlayStart = nil
	self.clickStart = nil
end

function UIFireastle:PlaySpineAnimation(dpSpine, animation, callBackFun, spineType)
	if (dpSpine) then
		if (spineType == UIFireastle.BossSpine) then
			self._curBossHitPlayTimes = self._curBossHitPlayTimes + 1
		end
		if (callBackFun) then
			dpSpine:SetAnimationCompleteFunc(callBackFun)
		end
		if (animation) then
			dpSpine:PlayAnimationSolid(animation, false)
		end
	end
end

function UIFireastle:StopBossHitDelayTimer()
	self:StopHitDelayTimerList()
	if self._bossDelayTimer then
		LxTimer.LoopTimeStop(self._bossDelayTimer)
		self._bossDelayTimer = nil
	end
	if self._bossHitLoopTimer then
		LxTimer.LoopTimeStop(self._bossHitLoopTimer)
		self._bossHitLoopTimer = nil
	end
end

function UIFireastle:GetRankRewardList()
	local modelId = gModelActivity:GetActivityModeIdBySid(self._sid)
	if (modelId == ModelActivity.MODEL_ACTIVITY_TYPE_116) then
		local pageList = self._pbDataList
		for i, v in ipairs(pageList) do
			local page = v
			if (page.pageType == 4) then
				local entry = page.entry
				local rewardList = {}
				for j, k in ipairs(entry) do
					local rewardData = {}
					local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, k.pageId, k.entryId)
					if not entryCfg then
						return
					end
					local entryId = k.entryId
					local items = LxDataHelper.ParseItem(entryCfg.reward)
					rewardData.index = entryId
					rewardData.reward = items
					local str = string.split(entryCfg.name, "~")
					local left = tonumber(str[1])
					local right = (str[2] and tonumber(str[2])) or left
					local rank = {}
					table.insert(rank, left)
					table.insert(rank, right)
					rewardData.rank = rank
					table.insert(rewardList, rewardData)
				end
				return rewardList
			end
		end
	end
end

function UIFireastle:OnActivityPageResp(pb, ret)
	local sid = pb.sid
	if sid ~= self._sid then
		return
	end
	self:SetPageList(pb)
	self._rewardList = self:GetRankRewardList() or {}
	--放烟花按钮
	--self:SetFirBtn()
	self:SetTaskList()
	self:SetCurrencyList(true)
	--排行榜数据请求
	local rankPopWnd = GF.FindFirstWndByName("UIRkPop")
	if (not rankPopWnd) then
		gModelRank:OnRankReq(2, self._rankId, 1, 25, self._sid)
	end
end

function UIFireastle:InitData()
	self.showCurrencyItemNum = nil
	self._bossHitDelayTimerList = {}
	self._uiCommonList = {}
	self._longFireBoxFirstPlayEnd = true
	self._sid = self:GetWndArg("sid")
	if not self._sid then
		local dataList = gModelActivity:GetActivityDataByModelId(ModelActivity.MODEL_ACTIVITY_TYPE_116)
		if dataList[1] then
			self._sid = dataList[1].sid
		else
			return
		end
	end
	--local channel = ModelChat.CHANNEL_FIREWORKS_CASTLE
	self._isBarrageShow = true--gModelChat:GetBarrageIsShow(channel)
	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIFireastle:OnDrawScheduleListCell(list, item, itemdata, itempos)
	local progressBg = self:FindWndTrans(item, "ProgressBg")
	local progress = self:FindWndTrans(progressBg, "Progress")
	local iconGroup = self:FindWndTrans(item, "IconGroup")
	--local icon = self:FindWndTrans(iconGroup, "Icon")
	local itemRoot = self:FindWndTrans(iconGroup, "itemRoot")
	local itemNum = self:FindWndTrans(iconGroup, "itemNum")
	local iconTrans = self:FindWndTrans(itemRoot, "Icon")
	local bg = self:FindWndTrans(iconGroup, "Bg")
	local name = self:FindWndTrans(iconGroup, "Name")
	local num = self:FindWndTrans(iconGroup, "Num")
	local numBg = self:FindWndTrans(iconGroup, "NumBg")
	local indexTxt = self:FindWndTrans(iconGroup, "Index")
	local effRoot = self:FindWndTrans(iconGroup, "EffRoot")
	local redPoint = self:FindWndTrans(iconGroup, "redPoint")
	local hadGet = self:FindWndTrans(iconGroup, "HadGet")
	local cfgData = gModelActivity:GetWebActivityEntryData(self._sid, 1, itemdata.entryId)
	local itemInsdanceID = item:GetInstanceID()
	local hasReward = not string.isempty(cfgData.reward)
	local reward
	local scheduleData = self.schedulesStatusList[itemdata.entryId]
	local schedule = scheduleData.schedules
	local status = scheduleData.status
	local strItemNum = ""
	if (hasReward) then
		reward = LxDataHelper.ParseItem_4(cfgData.reward, "=")
		--local itemPath = gModelItem:GetItemIconByRefId(reward.itemId)
		--self:SetWndEasyImage(icon, itemPath)
		local uiCommonList = self._uiCommonList
		local InstanceID = itemRoot:GetInstanceID()
		local baseClass = uiCommonList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			uiCommonList[InstanceID] = baseClass
			baseClass:Create(iconTrans)
		end
		baseClass:SetCommonReward(reward.itemType, reward.itemId)
		baseClass:EnableShowNum(false)
		baseClass:SetShowGouImg(false)
		baseClass:EnableShowBg(false)
		baseClass:DoApply()
		strItemNum = reward.itemNum
	end
	self:SetWndText(itemNum, strItemNum)
	self:SetWndText(name, cfgData.name)
	local conditionArr = string.split(cfgData.condition, ",")
	self:SetWndText(num, conditionArr[2])
	self:SetWndText(indexTxt, tostring(itemdata.entryId))
	CS.ShowObject(indexTxt, not hasReward)

	CS.ShowObject(progressBg, itemdata.entryId ~= #self.taskList)
	local progressImage = progress:GetComponent(typeofImage)
	progressImage.fillAmount = schedule
	local iconBgPath
	if (status == 0) then
		iconBgPath = self._mainCfg.scheduleBtn1
	else
		iconBgPath = self._mainCfg.scheduleBtn21
	end
	if ((status ~= 0 and schedule == 0) or (schedule > 0 and schedule < 1)) then
		iconBgPath = self._mainCfg.scheduleBtn22
	end
	-- self:SetWndEasyImage(bg, iconBgPath)

	local numBgPath = status == 0 and self._mainCfg.scheduleBubble1 or self._mainCfg.scheduleBubble2
	numBgPath = numBgPath and numBgPath or "activity_spring3_frame_9"
	self:SetWndEasyImage(numBg,numBgPath)
	CS.ShowObject(hadGet, status == 2)

	self:SetWndClick(iconGroup, function()
		if (status == 1) then
			--gModelActivity:OnActivityReceiveGoalReq(self._sid, 1, itemdata.entryId)
			local list = self:ActivityReceiveGoalList()
			if (list and #list > 0) then
				gModelActivity:OnActivityReceiveGoalListReq(list)
			end
		else
			if (reward) then
				gModelGeneral:ShowCommonItemTipWnd(reward)
			end
		end
	end)
	if (status == 1) then
		local effectName = "fx_ui_qiandao_lingqutishi"
		self:CreateWndEffect(effRoot, effectName, tostring(itemInsdanceID), 80, false, false)
	end
	CS.ShowObject(effRoot, status == 1)
	CS.ShowObject(redPoint, false)
	local bigRewardData = self:GetBigRewardData(itemdata.entryId)
	self:SetBigRewardData(bigRewardData)
end

function UIFireastle:OnActivityConfigData(data, sid)
	if sid ~= self._sid then
		return
	end
	self._activityWebData = gModelActivity:GetWebActivityDataById(self._sid)
	self._activityData = gModelActivity:GetActivityBySid(self._sid)
	self._mainCfg = self._activityWebData.config --main表
	self._cfgEntryList = self._activityWebData.chunk --条目表
	self._rankId = self:GetRankId(self._activityWebData)
	if (self._rankId) then
		self._rankTime = "rankTime"
		local times
		local timet = GetTimestamp()
		local rankClear = self._mainCfg.rankClear
		local endTimeData = rankClear == 1 and self._mainCfg.rankClearTime or nil
		if (endTimeData) then
			local endTimeDataArr = string.split(endTimeData, ":")
			times = LUtil.GetNextDayTimes(timet, 0, tonumber(endTimeDataArr[1]), tonumber(endTimeDataArr[2]))
		else
			times = self._activityData.endTime
		end
		self._rankTimes = times
		self:TimerStart(self._rankTime, 1, false, -1)
	else
		self:TimerStop(self._rankTime)
	end
	self:SetDefultUI()
	gModelActivity:OnActivityPageReq(self._sid)
	self._isFirstClickBarrage = self._isFirstClickBarrage ~= false and true or false
	self:OnClickBarrage()
	if (self._rankId) then
		self._rankScoreImgList = {
			[1] = "public_num_1",
			[2] = "public_num_2",
			[3] = "public_num_3",
		}
		self:SetWndText(self.mDetailsRankTxt, ccClientText(36306))
		self:SetWndText(self.mTitleTxt, ccClientText(36305))
	end
	CS.ShowObject(self.mRankGroup, self._rankId and self._mainCfg.rankSwitch == 1)
end

function UIFireastle:ActivityReceiveGoalList()
	local list = {}
	local pbDataList = self.taskList
	for i, v in ipairs(pbDataList) do
		local statue = v.goalData.status
		if (statue == 1) then
			local data = {
				sid = self._sid,
				pageId = v.pageId,
				entryId = v.entryId
			}
			table.insert(list, data)
		end
	end
	return list
end

function UIFireastle:OnClickBarrage()
	--self._isBarrageShow = not self._isBarrageShow
	local channel = ModelChat.CHANNEL_FIREWORKS_CASTLE
	self:ShowBarrage(self._isBarrageShow)
	local isFirst = self._isFirstClickBarrage
	if (not isFirst) then
		gModelChat:SetBarrageSav(channel, self._isBarrageShow)
	end
	self._isFirstClickBarrage = false
end

function UIFireastle:InitEvent()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...)
		self:OnActivityConfigData(...)
	end)
	self:WndEventRecv(EventNames.ON_CHAT_BARRAGE_WIN, function()
		self:OnClickBarrage()
	end)

	gLGameTouch:TouchRegister(LGameTouch.TOUCH_FIREWORKS_CASTLE, LGameTouch.TOUCH_EVT_END, function(screenPos)
		self:OnUITouchEnd(screenPos)
	end)
end

function UIFireastle:OnClickWarOrderBtn()
	--local functionId = 10403802--self._mainCfg.jump
	local functionId = self._mainCfg.jump
	if functionId and not gModelFunctionOpen:CheckIsOpened(functionId, true) then
		return
	end
	--local pagePara = self:ModifyWndPara(functionId)
	--local subPage = pagePara.subPage
	--local sid = gModelActivity:GetSidByUniqueJump(subPage)
	--gModelRedPoint:CheckShowIdMapRedByRedId(redRefId,sid)
	gModelFunctionOpen:Jump(functionId, self:GetWndName())
end

----
---烟花盒子动作
function UIFireastle:PlayFireBoxAni(ani)
	if self._isPlayFireBoxAni then return end

	local dpSpine = self:GetSpineByType(UIFireastle.BoxSpine)
	local callBackFun = function()
		self._isPlayFireBoxAni = false
		--播放烟花特效
		self:ShowFireworksEff()
		--播放年兽受击
		self:PlayBossHit()

		dpSpine:SetAnimationCompleteFunc(nil)

		local longClickCntInterval = self._mainCfg.boxFashe3
		if (self.longClickCnt == 2) then
			self:CreateLongClickCntTimer(longClickCntInterval)
		end
	end

	self._isPlayFireBoxAni = true

	self:PlaySpineAnimation(dpSpine, ani, callBackFun, UIFireastle.BoxSpine)
end

function UIFireastle:OpenRankWnd()
	if (self._rankId and self._rewardList) then
		local rankClear = self._mainCfg.rankClear
		local endTimeData = rankClear == 1 and self._mainCfg.rankClearTime or nil
		local wndData = {
			refId = self._rankId,
			sid = self._sid,
			page = 1,
			rewardList = self._rewardList,
			endTimeData = endTimeData,
			endTime = self._activityData.endTime
		}
		GF.OpenWndBottom("UIRkPop", wndData)
	end
end

function UIFireastle:PlayFireBoxAniOnClick()
	self._isPlayFireBoxAni = false

	local dpSpine = self:GetSpineByType(UIFireastle.BoxSpine)
	local callBackFun = function()
		dpSpine:SetAnimationCompleteFunc(nil)
		dpSpine:PlayAnimationSolid("idle")
		--播放烟花特效
		self:ShowFireworksEff()
		--播放年兽受击
		self:PlayBossHit()
	end
	self:PlaySpineAnimation(dpSpine, "start_1", callBackFun, UIFireastle.BoxSpine)
end

function UIFireastle:OnClickBigRewardGroup()
	local para = {
		title = self._mainCfg.foreshowTipsTitle,
		itemList = self._cfgEntryList[1].entries,
	}
	GF.OpenWnd("UITkAwardPop", para)
end

function UIFireastle:StopLongClickBtnSoundDelayTimer()
	if self._longClickBtnSoundDelayTimer then
		LxTimer.LoopTimeStop(self._longClickBtnSoundDelayTimer)
		self._longClickBtnSoundDelayTimer = nil
	end
end
---------------------------------------------------

function UIFireastle:LongClickUseFireworksItem()
	local cost = self._mainCfg.activityItemId
	local costItem = LxDataHelper.ParseItem_3(cost)
	local itemId = costItem.itemId
	local itemNum = costItem.itemNum
	local isEnough = gModelGeneral:CheckItemEnough(itemId, itemNum * self.longClickCnt)
	if (isEnough) then
		self:UseFireworksItem(itemId, itemNum, self.longClickCnt)
	end
	self.longClickCnt = 0
end

function UIFireastle:StopLongClickBtnSoundLoopTimer()
	if self._longClickBtnSoundLoopTimer then
		LxTimer.LoopTimeStop(self._longClickBtnSoundLoopTimer)
		self._longClickBtnSoundLoopTimer = nil
	end
end

function UIFireastle:SetCurrencyList(restCurrency)
	local useReward1 = self._mainCfg.itemId
	local activityItemId = self._mainCfg.activityItemId
	local list = {}
	self.restCurrency = restCurrency
	if (useReward1) then
		table.insert(list, useReward1)
	end
	if (activityItemId) then
		table.insert(list, activityItemId)
	end
	local _uiCellList = self._uiCellList
	if _uiCellList then
		_uiCellList:RefreshList(list)
	else
		_uiCellList = self:GetUIScroll("mCurrencyScroll")
		_uiCellList:Create(self.mCurrencyList, list, function(...)
			self:OnCurrencyScroll(...)
		end)
		self._uiCellList = _uiCellList
	end
end

function UIFireastle:CheckActivityIsEnd()
	if (not self._activityData or not self._activityData.endTime) then
		return true
	end
	local times = self._activityData.endTime
	local timet = GetTimestamp()
	local timespan = times - timet
	local endTimeDataArr = string.split(self._mainCfg.rankClearTime, ":")
	local times2 = LUtil.GetNextDayTimes(timet, 0, tonumber(endTimeDataArr[1]), tonumber(endTimeDataArr[2]))
	local timespan2 = times - times2
	if (timespan <= 0 or timespan2 <= 0) then
		return true
	end
end

function UIFireastle:OnClickFireBtn(isLong)
	local actIsEnd = self:CheckActivityIsEnd()
	if (actIsEnd) then
		return
	end

	local rewardWndIns = GF.FindFirstWndByName("UIAward")
	if (rewardWndIns) then
		self:OnUITouchEnd()
		return
	end
	local costItem, itemId, itemNum, lastItemNum, isEnough = self:CheckIsEngoutFireworksItem(isLong)
	if (isEnough) then
		self:PlayClickFirBtnSound(isLong)
	end
	if (self._bossDelayTimer or #self._bossHitDelayTimerList > 0 or self.clickStart) then
		return
	end
	local clickType = not isLong and 1 or 2
	if (isEnough) then
		self:LetOffFireworks(itemId, itemNum, clickType)
	else
		if (not isLong or (isLong and self.longClickStart)) then
			self.showCurrencyItemNum = nil
			gModelGeneral:OpenGetWayWnd({ itemId = costItem.itemId, srcWnd = self:GetWndName() })
		end
		if (isLong and self.longClickStart) then
			self:LongClickUseFireworksItem()
			self.longClickStart = nil
			self:StopBossLongHitDelayTimer()
		end
	end
end
-----------------按钮回调-----------------------
function UIFireastle:OnClickHelpBtn()
	local helpTxt = self._mainCfg.signHelpTips
	local para = {
		title = gModelActivity:GetLngNameByActivitySid(self._sid),
		text = helpTxt
	}
	GF.OpenWnd("UIBzTips", para)
end

function UIFireastle:StopBossLongHitDelayTimer()
	if self._bossHitLongLoopTimer then
		LxTimer.LoopTimeStop(self._bossHitLongLoopTimer)
		self._bossHitLongLoopTimer = nil
	end
end

function UIFireastle:GetBigRewardData(entryId)
	--local curIndex = (self.bigRewardShowIndex and self.bigRewardShowIndex > entryId) and entryId + 6 or entryId
	local curIndex = entryId
	if (self.moveToIndex) then
		curIndex = self.moveToIndex + 5
	end

	local curShowBigRewardData
	for i = curIndex, #self.taskList do
		local index = i
		if (not curShowBigRewardData) then
			local cfgData = gModelActivity:GetWebActivityEntryData(self._sid, 1, index)
			local moreInfoArr = string.split(cfgData.moreInfo, "=")
			if (moreInfoArr[2] and moreInfoArr[2] == "1") then
				if (self.bigRewardShowIndex and self.bigRewardShowIndex > index) then
					for j = index + 3, #self.taskList do
						local cfgData2 = gModelActivity:GetWebActivityEntryData(self._sid, 1, j)
						local moreInfoArr2 = string.split(cfgData2.moreInfo, "=")
						if (moreInfoArr2[2] and moreInfoArr2[2] == "1") then
							self.bigRewardShowIndex = j
							return cfgData2
						end
					end
				else
					self.bigRewardShowIndex = index
					return cfgData
				end
			end
		end
	end
	local bigRewardData = gModelActivity:GetWebActivityEntryData(self._sid, 1, #self.taskList)
	return bigRewardData
end

function UIFireastle:CreateSpine(trans, path, pos, scale)
	if string.isempty(path) then
		return
	end

	self:CreateWndSpine(trans, path, path)
	if not string.isempty(pos) then
		self:SetAnchorPos(trans, LxDataHelper.ParseVector2NotEmpty(pos))
	end
	if scale then
		trans.localScale = Vector3.New(scale, scale, 1)
	end
end
function UIFireastle:GetRankList()
	local list = {}
	local rankList = self:GetRankServerDataList()
	local showRankNum = 3
	local insNum = 0
	local rank
	for k, v in ipairs(rankList) do
		rank = v.rank
		if rank <= showRankNum then
			insNum = insNum + 1
			table.insert(list, {
				name = v.info._name,
				rank = rank,
				score = v.score,
				playerId = v.info._playerId,
			})
		end
	end
	if insNum < showRankNum then
		for i = insNum + 1, showRankNum do
			table.insert(list, {
				name = ccClientText(25203),
				rank = i,
				score = "",
				playerId = "-1",
			})
		end
	end
	return list
end

function UIFireastle:OnTimer(key)
	if (self._rankTime == key) then
		self:SetRankTime()
	end
end
function UIFireastle:RefreshRank()
	local list = self:GetRankList()
	local listTrans = self.mRankList
	local key = listTrans:GetInstanceID()
	local uiRankList = self:FindUIScroll(key)
	if uiRankList then
		uiRankList:RefreshList(list)
	else
		uiRankList = self:GetUIScroll(key)
		uiRankList:Create(listTrans, list, function(...)
			self:OnDrawRankCell(...)
		end)
	end

	local meRank = gModelRank:GetMeRank()
	local showMe = false
	if meRank and meRank.rank > 3 then
		self:SetWndText(self.mMeRankTxt, meRank.rank)
		self:SetWndText(self.mMeRankScore, meRank.score)
		self:SetWndText(self.mMeRankName, meRank.info:GetName())
		showMe = true
	end
	CS.ShowObject(self.mMeRankRoot, showMe)
end
function UIFireastle:PlayClickFirBtnSound(isLong)
	local audioName = LxResPathUtil.GetAudioSoundName(nil, UIFireastle.FireworkBtnSoundRefId)
	if not string.isempty(audioName) then
		local delayInv = isLong and 0 or 1.5
		if gLGameAudio and not self._delayPlayClickBtnSoundDelayTimer and not self._longClickBtnSoundDelayTimer then
			self._delayPlayClickBtnSoundDelayTimer = LxTimer.DelayTimeCall(function()
				self._longClickBtnSoundDelayTimer = LxTimer.DelayTimeCall(function()
					if (isLong) then
						self._longClickBtnSoundLoopTimer = LxTimer.LoopTimeCall(function()
							local rewardWndIns = GF.FindFirstWndByName("UIAward")
							if (rewardWndIns) then
								self:StopLongClickBtnSoundDelayTimer()
								self:StopLongClickBtnSoundLoopTimer()
								self:StopdelayPlayClickBtnSoundDelayTimer()
							else
								gLGameAudio:PlaySound(audioName)
							end
						end, 2, false, -1)
					else
						self:StopLongClickBtnSoundDelayTimer()
						self:StopdelayPlayClickBtnSoundDelayTimer()
					end
				end, 6)
				gLGameAudio:PlaySound(audioName)
			end, delayInv)
		end
	end
end

function UIFireastle:CheckIsEngoutFireworksItem(isLong)
	local cost = self._mainCfg.activityItemId
	local costItem = LxDataHelper.ParseItem_3(cost)
	local itemId = costItem.itemId
	local itemNum = costItem.itemNum
	local lastItemNum = isLong and itemNum * self.longClickCnt or 0
	local isEnough = gModelGeneral:CheckItemEnough(itemId, itemNum + lastItemNum)
	return costItem, itemId, itemNum, lastItemNum, isEnough
end

function UIFireastle:SetSchedulesStatus()
	local schedulesStatusList = {}
	local moveToIndex = 1
	local tmpIndex = 1
	local statusIndex
	local tmpData
	for i = 1, #self.taskList do
		local index = i
		local scheduleData = self:GetSchedulesByIndex(index, tmpData)
		tmpData = scheduleData
		table.insert(schedulesStatusList, scheduleData)
		if (not statusIndex and scheduleData.status == 1) then
			statusIndex = index
		end
		if (scheduleData.schedules ~= 0) then
			if (scheduleData.schedules ~= 1) then
				moveToIndex = index
			end
		end
		if (scheduleData.schedules == 1) then
			tmpIndex = index
		end
	end
	if (statusIndex) then
		return schedulesStatusList, statusIndex
	else
		return schedulesStatusList, moveToIndex == 1 and tmpIndex or moveToIndex
	end
end

function UIFireastle:InitBtnEvent()
	self:SetWndClick(self.mReturnBtn, function()
		self:WndClose()--返回按钮
	end, LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHelpBtn, function()
		self:OnClickHelpBtn()
	end) --帮助按钮
	self:SetWndClick(self.mBigReward, function()
		self:OnClickBigRewardGroup()--大奖预览提示
	end)
	self:SetWndClick(self.mRankBtn, function()
		self:OpenRankWnd()--排行榜按钮
	end)
	self:SetWndClick(self.mWarOrderBtn, function()
		self:OnClickWarOrderBtn()--战令按钮
	end)
	self:SetWndClick(self.mFireBtn, function()
		self:OnClickFireBtn()--放烟花按钮
	end)
	self:SetWndLongClick(self.mFireBtn, function()
		self:OnLongClickFireBtn()--长按放烟花按钮
	end, 0.2, false, 0)

	self:SetWndClick(self.mRankClickArea, function()
		self:OpenRankWnd()
	end)

	self:SetWndText(self.mPerviewTxt, ccClientText(36307))
end

function UIFireastle:GetSpineByType(spineType)
	local key = ""
	if (spineType == UIFireastle.BossSpine) then
		key = self._mainCfg.boss
	elseif (spineType == UIFireastle.BoxSpine) then
		key = self._mainCfg.box
		--key = "Yanhualihe"
	end
	local dpSpine = self:FindWndSpineByKey(key)
	return dpSpine
end

function UIFireastle:SetWarOrderBtnRP()
	local isRed
	local jumpActRed = self._mainCfg.jumpActRed
	local jumpActRedArr = string.split(jumpActRed, "=")
	local modelId = tonumber(jumpActRedArr[1])
	local dataList = gModelActivity:GetActivityDataByModelId(modelId)
	if dataList[1] then
		isRed = gModelRedPoint:GetActRedPointMap(dataList[1].sid)
	end
	local rpTrans = self:FindWndTrans(self.mWarOrderBtn, "redPoint")
	CS.ShowObject(rpTrans, isRed)
end

function UIFireastle:OnDrawRankCell(list, item, itemdata, itempos)
	local RankImgTrans = self:FindWndTrans(item, "RankImg")
	local NameTrans = self:FindWndTrans(item, "Name")
	local ScoreTrans = self:FindWndTrans(item, "Score")
	local Me = self:FindWndTrans(item, "Me")
	local rank = itemdata.rank
	local name = itemdata.name
	local score = itemdata.score
	local playerId = itemdata.playerId
	local myPlayerId = gModelPlayer:GetPlayerId()
	local color = myPlayerId == playerId and "#FFE094" or "#ffffff"
	-- name = LUtil.FormatColorStr(name, color)
	self:SetWndText(NameTrans, name)
	self:SetWndText(ScoreTrans, score)
	local rankScoreImgList = self._rankScoreImgList
	local img = rankScoreImgList and rankScoreImgList[rank]
	if img and RankImgTrans then
		self:SetWndEasyImage(RankImgTrans, img)
	end
	CS.ShowObject(Me, myPlayerId == playerId)
end
function UIFireastle:SetBigRewardData(bigRewardData)
	local bigRewardTrans = self.mBigReward
	local cfgData = bigRewardData
	local iconGroup = self:FindWndTrans(bigRewardTrans, "IconGroup")
	local itemRoot = self:FindWndTrans(iconGroup, "itemRoot")
	local iconTrans = self:FindWndTrans(itemRoot, "Icon")
	local name = self:FindWndTrans(iconGroup, "Name")
	local num = self:FindWndTrans(iconGroup, "Num")
	local itemNum = self:FindWndTrans(iconGroup, "itemNum")
	local hasReward = not string.isempty(cfgData.reward)
	local reward
	local strItemNum = ""
	if (hasReward) then
		reward = LxDataHelper.ParseItem_4(cfgData.reward, "=")
		local uiCommonList = self._uiCommonList
		local InstanceID = itemRoot:GetInstanceID()
		local baseClass = uiCommonList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			uiCommonList[InstanceID] = baseClass
			baseClass:Create(iconTrans)

		end
		baseClass:SetCommonReward(reward.itemType, reward.itemId, reward.itemNum)
		baseClass:SetShowGouImg()
		baseClass:EnableShowNum(false)
		baseClass:EnableShowBg(false)
		baseClass:DoApply()
		strItemNum = reward.itemNum
	end
	self:SetWndText(itemNum, strItemNum)
	self:SetWndText(name, cfgData.name)
	self:SetWndText(name, cfgData.name)
	local conditionArr = string.split(cfgData.condition, ",")
	self:SetWndText(num, conditionArr[2])
	--self:SetWndClick(iconGroup, function()
	--	if (reward) then
	--		gModelGeneral:ShowCommonItemTipWnd(reward)
	--	end
	--end)
end
function UIFireastle:StopdelayPlayClickBtnSoundDelayTimer()
	if self._delayPlayClickBtnSoundDelayTimer then
		LxTimer.LoopTimeStop(self._delayPlayClickBtnSoundDelayTimer)
		self._delayPlayClickBtnSoundDelayTimer = nil
	end
end

function UIFireastle:GetRankServerDataList()
	return gModelRank:GetRankListInfo(2, self._rankId)
end

function UIFireastle:SetRankTime()
	local times = self._rankTimes
	local timet = GetTimestamp()
	local timespan = times - timet
	if (timespan <= 0) then
		self:TimerStop(self._rankTime)
		self:SetWndText(self.mRankTimeTxt, ccClientText(20317))
		return
	end
	local timeStr = LUtil.FormatTimespanThreeCn(timespan)
	self:SetWndText(self.mRankTimeTxt, string.replace(ccClientText(11724), timeStr))
end

function UIFireastle:SetDefultUI()
	self:SetWndEasyImage(self.mBgImg, self._mainCfg.image)
	self:SetWndEasyImage(self.mTitleImg, self._mainCfg.txt)
	if not string.isempty(self._mainCfg.txtPos) then
		self:SetAnchorPos(self.mTitleImg, LxDataHelper.ParseVector2NotEmpty(self._mainCfg.txtPos))
	end
	if not string.isempty(self._mainCfg.signHelpTipsPos) then
		self:SetAnchorPos(self.mHelpBtn, LxDataHelper.ParseVector2NotEmpty(self._mainCfg.signHelpTipsPos))
	end
	local returnBtnTxt = self:FindWndTrans(self.mReturnBtn, "ReturnTxt")
	self:SetWndText(returnBtnTxt, ccClientText(36304))

	local bossSpine = self._mainCfg.boss
	local bossSpinePos = self._mainCfg.bossPos
	local bossScale = self._mainCfg.bossAction
	self:CreateSpine(self.mBossSpine, bossSpine, bossSpinePos, bossScale)

	local boxSpine = self._mainCfg.box
	local boxSpinePos = self._mainCfg.boxPos
	local boxScale = self._mainCfg.boxAction
	if (not string.isempty(boxSpine)) then
		self:CreateSpine(self.mBoxSpine, boxSpine, boxSpinePos, boxScale)
		if (not string.isempty(boxSpinePos)) then
			self:SetAnchorPos(self.mBossHitEffRoot, LxDataHelper.ParseVector2NotEmpty(boxSpinePos))
		end
	end
	--烟花特效
	self._fireworksEffPath = self._mainCfg.effect
	if not string.isempty(self._mainCfg.effectPos) then
		self._fireworksEffPos = LxDataHelper.ParseVector2NotEmpty(self._mainCfg.effectPos)
		self:SetAnchorPos(self.mFireworksEffRoot, self._fireworksEffPos)
	end
	--排行榜按钮文本
	local rankBtnTxt = self:FindWndTrans(self.mRankBtn, "Txt")
	self:SetWndText(rankBtnTxt, ccClientText(36300))
	--战令按钮
	local warOrderBtnIcon = self:FindWndTrans(self.mWarOrderBtn, "Icon")
	self:SetWndEasyImage(warOrderBtnIcon, self._mainCfg.giftIcon)
	local warOrderBtnPos = self._mainCfg.giftPos
	if (not string.isempty(warOrderBtnPos)) then
		self:SetAnchorPos(self.mWarOrderBtn, LxDataHelper.ParseVector2NotEmpty(warOrderBtnPos))
	end
	local warOrderBtnTxt = self:FindWndTrans(self.mWarOrderBtn, "Txt")
	self:SetWndText(warOrderBtnTxt, ccClientText(36301))
	self:SetWndText(warOrderBtnTxt, self._mainCfg.giftName)
	--长按可连续使用
	self:SetWndText(self.mDescTxt, self._mainCfg.usebtnTips)--ccClientText(36303)
	CS.ShowObject(self.mRankGroup, self._mainCfg.rankSwitch == 1)

	local bigRewardTrans = self.mBigReward
	--local iconGroup = self:FindWndTrans(bigRewardTrans, "IconGroup")
	local titleImg = self:FindWndTrans(bigRewardTrans, "TitleImg")
	local perviewBtn = self:FindWndTrans(bigRewardTrans, "PerviewBtn")
	self:SetWndEasyImage(titleImg, self._mainCfg.foreshowTxtIcon)
	self:SetWndEasyImage(perviewBtn, self._mainCfg.alineWorld_ui_11)
	self:SetFirBtn()
	self:SetWarOrderBtnRP()
end

function UIFireastle:ShowFireworksEff()
	local id = self._currentFireworkId or 0
	id = id + 1
	if id > 5 then
		id = 1
	end
	self._currentFireworkId = id

	local effectName = self._fireworksEffPath
	local effectKey = effectName..tostring(id)
	self:CreateWndEffect(self.mFireworksEffRoot, effectName, effectKey, 100, false, false)
end

function UIFireastle:SetPageList(pb)
	local pbDataList = self._pbDataList or {}
	for i, v in ipairs(pb.pages) do
		local page = {}
		page = gModelActivity:GenerateActivePageDataFromPb(v)
		local isIns = false
		for k, j in pairs(pbDataList) do
			if (page.pageId == j.pageId) then
				pbDataList[k] = page
				isIns = true
			end
		end
		if isIns == false then
			table.insert(pbDataList, page)
		end
	end
	self._pbDataList = pbDataList
end

function UIFireastle:SetFirBtn(showItemNum)
	local payDivTrans = self:FindWndTrans(self.mFireBtn, "PayDiv")
	local numTxt = self:FindWndTrans(payDivTrans, "NumTxt")
	local cost = self._mainCfg.activityItemId
	local itemArr = string.split(cost, "=")
	local itemId = tonumber(itemArr[2])
	--local itemNum = showItemNum or gModelItem:GetNumByRefId(itemId)
	local itemName = gModelItem:GetNameByRefId(itemId)
	local useItemNum = self._mainCfg.useItemNum
	--local numStr = string.format("%sx%s", itemName, itemNum)
	local numStr = useItemNum and string.replace(useItemNum, itemName) or itemName
	self:SetWndText(numTxt, numStr)
end
function UIFireastle:DoPlayBoxFireAni()
	local costItem, itemId, itemNum, lastItemNum, isEnough = self:CheckIsEngoutFireworksItem(true)
	local own = gModelItem:GetNumByRefId(itemId)
	if (isEnough) then
		self.longClickCnt = self.longClickCnt + 1
		self.showCurrencyItemNum = own - itemNum - lastItemNum
		self:SetCurrencyList()
		--播放烟花盒子动作
		--if(self._longFireBoxFirstPlayEnd == false)then
		--	return
		--end
		if (self.longClickCnt ~= 1) then
			self:PlayFireBoxAni("start_1")
		else
			self:PlayFireBoxAni("start_1")
		end
	else
		self:StopLongUsingItemDelayTimer()
	end
end

function UIFireastle:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...)
		self:OnActivityPageResp(...)
	end)
	self:WndNetMsgRecv(LProtoIds.ItemChangeResp, function(pb)
		self:SetCurrencyList(true)
		gModelRank:OnRankReq(2, self._rankId, 1, 25, self._sid)
	end)
	self:WndEventRecv(EventNames.RANK_UPDATE_END, function(rankType, rankRefId)
		if rankRefId ~= self._rankId then
			return
		end
		self:RefreshRank()
	end)
end
function UIFireastle:GetRankId(activityData)
	local modelId = gModelActivity:GetActivityModeIdBySid(self._sid)
	if (modelId == ModelActivity.MODEL_ACTIVITY_TYPE_116) then
		local chuck = activityData.chunk
		local rankCfg
		for i, v in ipairs(chuck) do
			if (v.type == 4) then
				rankCfg = v
				break
			end
		end
		if (rankCfg) then
			local entryData = rankCfg.entries[1]
			local condition = entryData.condition
			local conditionArr = string.split(condition, ",")
			local eventArr = string.split(conditionArr[1], "=")
			local id = tonumber(eventArr[3])
			return id
		end
	end
end

function UIFireastle:StopHitDelayTimerList()
	if self._bossHitDelayTimerList then
		for i, v in ipairs(self._bossHitDelayTimerList ) do
			LxTimer.DelayTimeStop(v)
		end
	end
	self._bossHitDelayTimerList = {}
end

function UIFireastle:ShowBarrage(bool)
	if (bool) then
		gModelGeneral:OpenBarrage({ channel = ModelChat.CHANNEL_FIREWORKS_CASTLE, barrageFormatStr = self._mainCfg.barrageTxt, sid = self._sid })
	else
		GF.CloseWndByName("UIBulletSay")
	end
end
------------------------------------------------------------------
return UIFireastle