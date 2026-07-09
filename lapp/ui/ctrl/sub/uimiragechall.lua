---
--- Created by Administrator.
--- DateTime: 2023/10/4 15:04:26
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UIMirageChall:LChildWnd
local UIMirageChall = LxClass("UIMirageChall", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMirageChall:UIMirageChall()
	self._curCountDownKey = "curCountDownKey"					-- 当前倒计时
	self._beforeCountDownKey = "beforeCountDownKey"				-- 上一轮倒计时
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMirageChall:OnWndClose()
	--self:ClearTimer()
	self:ClearCommonIconList(self._uiCommonList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMirageChall:OnCreate()
	self._uiCommonList = {}
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMirageChall:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:ShowChangeDiv(false)
	self:InitData()
	self:SetWndText(self.mVideoBtnName,ccClientText(14311))
	self:SetWndButtonText(self.mChallengeBtn,ccClientText(15607))
	--self:SetTop()
	self:InitEvent()
	self:CreateCurBtnEff()
	self:InitMsg()
	
	--local pbData = gModelActivity:GetActivityPageBySid(self._sid)
	--if pbData then
	--	self:OnActivityPageResp(pbData)
	--else
	--	gModelActivity:OnActivityPageReq(self._sid)
	--end

	gModelActivity:ReqActivityConfigData(self._sid)
end

function UIMirageChall:CreateBeforeDownTime()
	self:SetBeforeDownTimeStr()
	self:TimerStart(self._beforeCountDownKey,1,false,-1)
end

function UIMirageChall:OnTimer(key)
	if key == self._beforeCountDownKey then
		self:SetBeforeDownTimeStr()
	elseif key == self._curCountDownKey then
		self:SetCurDownTimeStr()
	end
end

function UIMirageChall:RefreshUI()
	local page = self._page
	local dataList = {}
	local maxGroup = 0
	local defeatTitle = ""
	local entry = page and page.entry or {}
	for k,v in ipairs(entry) do
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid,self._pageId,v.entryId)
		if entryCfg then
			local moreInfo = JSON.decode(v.moreInfo)
			local group,power = tonumber(moreInfo.group),tonumber(moreInfo.power)
			local groupList = dataList[group]
			if not groupList then
				groupList = {}
				dataList[group] = groupList
				if group > maxGroup then maxGroup = group end
			end
			local data = {}
			data.power = power
			data.entryId = v.entryId
			data.title = entryCfg.name
			data.desc = entryCfg.description
			data.icon = tonumber(entryCfg.icon)
			data.rewards =LxDataHelper.ParseItem(entryCfg.reward)
			data.status = v.goalData.status
			data.monsterId = tonumber(moreInfo.condition)
			table.insert(groupList,data)
			if data.status == 2 then
				defeatTitle = data.title
			end
		end
	end
	self._maxGroup = maxGroup
	self._defeatTitle = defeatTitle
	if self._defeatTitle ~= "" and self.tips2 then
		self:SetWndText(self.mBossTxt,string.replace(self.tips2,self._defeatTitle))
	end
	self:InitGuanQiaList(dataList)
end

function UIMirageChall:CurMonster(i)
	local index = self._index + i
	local allPage = self._allPage or 0
	if index > allPage then index = 1 end
	if index <= 0 then index = allPage end
	local data = self._data
	if not data then return end
	local status = data[index].status
	self:ClickIcon(index,status)
end

function UIMirageChall:InitData()
	self._sid = self:GetWndArg("sid")
	self._btnKey = "runEff"
	self._group = 1
	self._beforeGroup = 1
	self._index = 1
	self._map = 0
end

function UIMirageChall:SetTimerInfo(trans,time,timeKey,textStr)
	local str = ""
	local curTime = time
	if curTime > 0 then
		--local str = string.replace(ccClientText(15608),LUtil.FormatTimespanCn(curTime))
		str = string.replace(textStr,LUtil.FormatTimespanCn(curTime))
	else
		self:TimerStop(timeKey)
		self:StopTimerFunc(timeKey)
	end
	self:SetWndText(trans,str)
end

function UIMirageChall:InitEvent()
	self:SetWndClick(self.mLeftBtn,function() self:CurMonster(-1) end)
	self:SetWndClick(self.mRightBtn,function() self:CurMonster(1) end)
	self:SetWndClick(self.mChallengeBtn,function()
		self:GoToChallenge()
	end)
	self:SetWndClick(self.mVideoBtn,function()

		-- self._title = itemdata.title
		-- self._entryId = itemdata.entryId
		GF.OpenWnd("UITaVdoPop",{sid = self._sid,passId = self._challengeId,map = self._map,title = ccClientText(14311),openType = 2})
	end)

	self:SetWndClick(self.mChangeRoundBtn,function()
		self:OnClickChangeRoundBtnFunc()
	end)
end

function UIMirageChall:OnDrawGuanQia(list, item, itemdata, itempos, fromHeadTail)


	local mask = self:FindWndTrans(item,"mask")
	local maskIcon = self:FindWndTrans(mask,"Icon")
	local DiffImg = self:FindWndTrans(item,"DiffImg")
	local SelImg = self:FindWndTrans(item,"SelImg")
	local PassImg = self:FindWndTrans(item,"PassImg")

	local icon,prefabName
	local monsterRef = gModelHero:GetShowEffectById(itemdata.icon)
	if monsterRef then
		icon = monsterRef.icon
		prefabName = monsterRef.prefabName
	end
	local index,status = itemdata.index,itemdata.status

    local isSel = self._index == index

	--local SelImgTrans = self:FindWndTrans(item,"SelImg")
	--if SelImgTrans then
		CS.ShowObject(SelImg,isSel)
	--end
	--local IconTrans = self:FindWndTrans(item,"Icon")
	--if IconTrans then
		if icon then self:SetWndEasyImage(maskIcon,icon) end
		self:SetWndClick(maskIcon,function()
			self:ClickIcon(index,status)
		end)
	--end
	--local DiffImgTrans = self:FindWndTrans(item,"DiffImg")
	--if DiffImgTrans then
		local desc = itemdata.desc
		self:SetWndEasyImage(DiffImg,desc)
	--end
	--local PassImgTrans = self:FindWndTrans(item,"PassImg")
	--if PassImgTrans then
		CS.ShowObject(PassImg,status == 2)
	--end
	CS.ShowObject(self.mBossTxt,self._pass and status == 2)
	if self._pass then
	end
    self:SetWndButtonGray(self.mChallengeBtn,isSel and status == 2)

	local selfPower= gModelPower:GetMainPower()
	local showRed = selfPower>itemdata.power and status < 2

	local redPoint = self:FindWndTrans(item,"redPoint")
	CS.ShowObject(redPoint,showRed)



	if self._index == index and prefabName then
		self._title = itemdata.title
		self._entryId = itemdata.entryId
		self._challengeId = tonumber(itemdata.monsterId)
		self:RefreshBotDiv(itemdata,prefabName)
	end
end

function UIMirageChall:RefreshGroup()
	local str = string.replace(ccClientText(15615),self._curGroup)
	self:SetWndText(self.mTitle,str)
end

function UIMirageChall:OnClickChangeRoundBtnFunc()
	local isCurRound = self:CheckIsCurRound()
	if isCurRound then
		self._curGroup = self._beforeGroup
	else
		self._curGroup = self._group
	end
	self:RefreshView()
	self:RefreshUI()
end

function UIMirageChall:InitGuanQiaList(dataList)
	local list = self:GetGuanQuaList(dataList)
	local uiList = self._guanqiaList
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self,self.mGuanQiaList)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawGuanQia(...)
		end)
		self._guanqiaList = uiList
	end
	uiList:RemoveAll()
	for i,v in ipairs(list) do
		uiList:AddData(i,v)
	end
	uiList:RefreshList()
end

function UIMirageChall:RefreshBotDiv(itemdata,prefabName)
	local title = itemdata.title
	local power = itemdata.power
	power = LUtil.PowerNumberCoversion(power)
	local rewards = itemdata.rewards
	self:SetWndText(self.mNameTxt,title)
	local str = string.replace(ccClientText(15609),power)
	self:SetWndText(self.mPowerTxt,str)
	self:CreateSpine(prefabName)
	self:InitItemList(rewards)
end

function UIMirageChall:GoToChallenge()
	if not self._data or not self._index then return end
	local data = self._data[self._index]
	if data and data.status == 2 then
		GF.ShowMessage(ccClientText(15707))
		return
	end
	local sid = self._sid
	local passId = self._passId
	local challengeId = self._challengeId
	local map = self._map
	local battleName = self._title
	local battleRefId = self._entryId

	FireEvent(EventNames.ON_MAIN_CITY_BTN_CHANGE)
	if gLGameUI then
		gLGameUI:CloseAllBySwitchTypeButExcept(LWnd.SWITCH_TYPE_CHANGE_BTN,nil)
	end
	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_ACTIVITY,{sid = sid,passId = passId, monsterId = challengeId,map = map,battleName = battleName,battleRefId = battleRefId})

end

function UIMirageChall:OnActivityPageResp(pb,ret)
	local sid = pb.sid
	if sid ~= self._sid then return end
	local page = pb.pages[1]
	self._pageId = page.pageId
	self._page = page
	self:RefreshUI()
end

function UIMirageChall:OnActivityReceiveGoalResp(pb,ret)

end

--[[function UIMirageChall:CreateTimer(times)
	self:ClearTimer()
	self:SetTimeStr(times)
	self._timer = LxTimer.LoopTimeCall(function()
		self:SetTimeStr(times)
	end, 1, false, -1)
end

function UIMirageChall:SetTimeStr(times)
	local curTime = times - GetTimestamp()
	if curTime > 0 then
		local str = string.replace(ccClientText(15608),LUtil.FormatTimespanCn(curTime))
		self:SetWndText(self.mDownTxt,str)
	else
		self:ClearTimer()
	end
end

function UIMirageChall:ClearTimer()
	local timer = self._timer
	if timer then
		LxTimer.DelayTimeStop(timer)
		self._timer = nil
	end
end]]

function UIMirageChall:CheckIsCurRound()
	local curGroup = self._curGroup
	local group = self._group
	return curGroup == group
end

function UIMirageChall:GetBeforeDownTime()
	local isCurRound = self:CheckIsCurRound()
	local lastTime
	local textStr = ccClientText(15636)
	if isCurRound then
		lastTime = (self._lastRoundTime + self._challengeDelayTime) - GetTimestamp()
	else
		lastTime = self._nextRoundTime - GetTimestamp()
	end
	return lastTime
end

function UIMirageChall:CreateCurCountDownTime()
	self:SetCurDownTimeStr()
	local time = self:GetCurDownTime()
	if time > 0 then
		self:TimerStart(self._curCountDownKey,1,false,-1)
	end
end

function UIMirageChall:GetCurDownTime()
	local isCurRound = self:CheckIsCurRound()
	local curTime
	local textStr = ccClientText(15636)
	if isCurRound then
		curTime = self._nextRoundTime - GetTimestamp()
	else
		curTime = (self._lastRoundTime + self._challengeDelayTime) - GetTimestamp()
	end
	return curTime
end

function UIMirageChall:InitItemList(dataList)
	if not self._itemUIList then
		self._itemUIList = self:GetUIScroll("itemUIList")
		self._itemUIList:Create(self.mItemList,dataList,function(...) self:OnDrawItem(...) end,UIItemList.NORMAL)
		self._itemUIList:EnableScroll(true,true)
	else
		self._itemUIList:RefreshList(dataList)
	end
end

function UIMirageChall:GetGuanQuaList(dataList)
	local list = {}

	local group = self._curGroup
	if not group then
		group = self._group
	end
	local data = dataList[group]
	local isPass = false
	if not data then
		isPass = true
		group = group  - 1
		data = dataList[group - 1]
		self._curGroup = group
		self._group = group
	end

	self._pass = isPass
	local index = -1
	self._allPage = 0

	if not data then
		return list
	end

	local maxIndex = #data
	for i,v in ipairs(data) do
		local status = v.status
		if status == 0 and index == -1 then
			index = i
		end
		v.index = i
		table.insert(list,v)
		self._allPage = self._allPage + 1
	end

	if isPass then
		index = maxIndex
	else
		if index == -1 then
			index = #data
			self._pass = true
		end
	end

	self._index = index
	self._data = data

	return list
end

function UIMirageChall:CreateCurBtnEff()
	local seqTween
	self:TweenSeqKill(self._btnKey)
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._btnKey,function(seq)
			local showTime = 0.5
			local leftPosition = -270
			local rightPosition = 270
			local movePostion = 10
			local leftBtnY = self.mLeftBtn.localPosition.y
			local rightBtnY = self.mRightBtn.localPosition.y
			self.mLeftBtn.localPosition = Vector3(leftPosition,leftBtnY,0)
			self.mRightBtn.localPosition = Vector3(rightPosition,rightBtnY,0)
			local leftBtnMove1 = self.mLeftBtn:DOLocalMoveX(leftPosition + movePostion,showTime)
			local leftBtnMove2 = self.mLeftBtn:DOLocalMoveX(leftPosition,showTime)
			local rightBtnMove1 = self.mRightBtn:DOLocalMoveX(rightPosition - movePostion,showTime)
			local rightBtnMove2 = self.mRightBtn:DOLocalMoveX(rightPosition,showTime)
			seq:Join(leftBtnMove1)
			seq:Join(rightBtnMove1)
			seq:AppendInterval(0)
			seq:Join(leftBtnMove2)
			seq:Join(rightBtnMove2)
			return seq
		end)
	end
	seqTween:SetLoops(-1,DG.Tweening.LoopType.Restart)
	seqTween:PlayForward()
	seqTween:OnComplete(function() self:TweenSeqKill(self._btnKey) end)
end

function UIMirageChall:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (...) self:OnActivityPageResp(...) end)
	self:WndNetMsgRecv(LProtoIds.ActivityReceiveGoalResp,function (...) self:OnActivityReceiveGoalResp(...) end)
	--self:WndNetMsgRecv(LProtoIds.ActivityListResp,function() self:SetTop() end)

	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:SetTop()
		gModelActivity:OnActivityPageReq(self._sid)
	end)
end

function UIMirageChall:SetTop()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end

	local activityCfg = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityCfg then return end

	--local moreInfo = activityData.moreInfo

	local data = activityCfg.config -- JSON.decode(moreInfo)
	local path = data.image
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mTop,path)
	end

	path = data.sceneBg
	if LxUiHelper.IsImgPathValid(path) then
		self:SetWndEasyImage(self.mBg,path)
	end

	self:SetWndClick(self.mHelpBtn,function()
		GF.OpenWnd("UIBzTips",{title= activityData.title,text = data.helpTip})
	end)

	self._map = data.map

	local dynamicData = JSON.decode(activityData.moreInfo)

	local group = tonumber(dynamicData.group)
	if self._maxGroup and self._maxGroup < group then
		group = self._maxGroup
	end
	self._group = group

	self._curGroup = group
	self._beforeGroup = group - 1


	self._nextRoundTime = dynamicData.nextRoundTime

	self._challengeTime = data.challengeTime

	local challengeDelayTime = data.challengeDelayTime
	self._challengeDelayTime = challengeDelayTime

	--local nextRoundTime = dynamicData.nextRoundTime/1000
	--self:CreateTimer(nextRoundTime)
	self:SetWndText(self.mAwardTipsText,data.tips1 or "")
	self.tips2 = data.tips2


	self._nextRoundTime = dynamicData.nextRoundTime / 1000

	local lastRoundTime = dynamicData.lastRoundTime
	if string.isempty(lastRoundTime) then
		lastRoundTime = 0
	end
	if lastRoundTime and tonumber(lastRoundTime) > 0 and challengeDelayTime then
		challengeDelayTime = tonumber(challengeDelayTime)
		lastRoundTime = lastRoundTime / 1000
	end
	self._lastRoundTime = lastRoundTime


	self:RefreshView()
end

function UIMirageChall:SetCurDownTimeStr()
	local time = self:GetCurDownTime()
	local textStr = ccClientText(15608)
	self:SetTimerInfo(self.mDownTxt,time,self._curCountDownKey,textStr)
end

function UIMirageChall:RefreshView()
	self:InitTimer()
	self:RefreshGroup()
end

function UIMirageChall:SetBeforeDownTimeStr()
	local textStr = ccClientText(15636)
	local lastTime = self:GetBeforeDownTime()
	self:SetTimerInfo(self.mChangeRoundTime,lastTime,self._beforeCountDownKey,textStr)
end

function UIMirageChall:ClickIcon(index,status)
	local oldIndex = self._index
	self._index = index
	if self._guanqiaList then
		self._guanqiaList:DrawItemByKey(oldIndex)
		self._guanqiaList:DrawItemByKey(index)
	end
	CS.ShowObject(self.mBossTxt,status == 2)
	self:SetWndButtonGray(self.mChallengeBtn,status == 2)
end

function UIMirageChall:StopTimerFunc(timeKey)
	local isCurRound = self:CheckIsCurRound()
	if isCurRound then
		gModelActivity:ReqActivityConfigData(self._sid)
	else
		self._curGroup = self._group
		self:RefreshView()
		self:RefreshUI()
	end


--[[	if timeKey == self._beforeCountDownKey then
		self._curGroup = self._group
		self:RefreshView()
	elseif timeKey == self._curCountDownKey then

	end]]
end

function UIMirageChall:ShowChangeDiv(show)
	CS.ShowObject(self.mChangeDiv,show)
end

function UIMirageChall:OnDrawItem(list, item,itemdata,itempos)
	--local rootTrans = self:FindWndTrans(item,"root")
	local root = self:FindWndTrans(item,"root/Icon")
	if root then
		local rewards = itemdata
		local formatData = rewards
		local uiCommonList = self._uiCommonList
		local InstanceID = item:GetInstanceID()
		local baseClass = uiCommonList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			uiCommonList[InstanceID] = baseClass
			baseClass:Create(root)
		end
		baseClass:SetCommonReward(formatData.itemType, formatData.itemId, formatData.itemNum)
		baseClass:DoApply()
		self:SetIconClickScale(root, true)
		self:SetWndClick(root, function() gModelGeneral:ShowCommonItemTipWnd(formatData) end)
	end
end

function UIMirageChall:InitTimer()
	self:TimerStop(self._curCountDownKey)
	self:TimerStop(self._beforeCountDownKey)

	local isCurRound = self:CheckIsCurRound()
	local textStr = isCurRound and ccClientText(15634) or ccClientText(15635)
	self:SetWndButtonText(self.mChangeRoundBtn,textStr)


	local lastTime = isCurRound and self._lastRoundTime or self._nextRoundTime

	local lastRoundTime = self._lastRoundTime
	local beforeGroup = self._beforeGroup
	local challengeDelayTime = self._challengeDelayTime
	local showChangeDiv = lastRoundTime ~= nil and beforeGroup > 0 and challengeDelayTime ~= nil and lastTime ~= nil
	if showChangeDiv then
		local tLastTime = self:GetBeforeDownTime()
		if tLastTime > 0 then
			self:CreateBeforeDownTime()
		else
			showChangeDiv = false
		end
		--self:CreateBeforeDownTime()
	end
	self:ShowChangeDiv(showChangeDiv)

	self:CreateCurCountDownTime()
end

function UIMirageChall:CreateSpine(prefabName,key)
	key = key or prefabName
	local spine = self:FindWndSpineByKey(key)
	if not spine then
		if self._lastSpine then
			CS.ShowObject(self._lastSpine:GetDisplayTrans(),false)
		end

		local scale = 3
		if gLGameLanguage:IsJapanRegion() then
			scale = 2.5
		end

		self._lastSpine = self:CreateWndSpine(self.mHeroPos,prefabName,key,false,function(dpSpine)
			dpSpine:PlayAnimation(0,"idle",true)
			dpSpine:SetScale(scale)
		end)
	else
		CS.ShowObject(self._lastSpine:GetDisplayTrans(),false)
		self._lastSpine = spine
		CS.ShowObject(spine:GetDisplayTrans(),true)
	end
end
------------------------------------------------------------------
return UIMirageChall


