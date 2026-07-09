---
--- Created by Administrator.
--- DateTime: 2023/10/6 20:29:10
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPrepareMirrorYell:LWnd
local UIPrepareMirrorYell = LxWndClass("UIPrepareMirrorYell", LWnd)

UIPrepareMirrorYell.NOT_SAVE = 0
UIPrepareMirrorYell.IS_SAVE = 1
UIPrepareMirrorYell.IS_LOCK = 2

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPrepareMirrorYell:UIPrepareMirrorYell()
	self._endTimeKey = "_endTimeKey"
	self._addCallTimeKey = "_addCallTimeKey"
	self._showAniKey = "showAniKey"
	self._cutHeroTimerKey = "cutHeroTimerKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPrepareMirrorYell:OnWndClose()
	--LPlayerPrefs.SetPrepareMirrorCall("")

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPrepareMirrorYell:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPrepareMirrorYell:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
	self:InitCallBtnTransInfo()
    self:InitStaticContent()
	self:RefreshView()

	if not self._isLock then
		--每次进入预抽卡界面都先出现帮助弹窗
		self:OnClickHelpBtnFunc()
	end
end

function UIPrepareMirrorYell:RefreshCanCallTimeText()
	if self._isLock then return end

	local num = self._haveCallNum
	local str = string.replace(ccClientText(37402), num)
	self:SetWndText(self.mCanCallTxt,str)
end

function UIPrepareMirrorYell:RefreshCallTypeView()
	self:TimerStop(self._oneTimerKey)

	local ref = self:GetCallTypeRef()
	if not ref then return end

	self:SetWndEasyImage(self.mBg, ref.bg)

	self:RefreshCanCallTimeText()
	self:ResetAddCallTimeText()
	self:RefreshLimitText()
end

function UIPrepareMirrorYell:ResetAddCallTimeText()
	local nextAddCallTime = self:GetNextAddCallTime()
	self._nextAddCallTime = nextAddCallTime

	local needStartTime = false
	if nextAddCallTime and nextAddCallTime > 0 then
		local curTime = self:GetCurTime()
		local timeDuration = self._nextAddCallTime - curTime
		if timeDuration > 0 then
			needStartTime = true
		end
	end

	self:TimerStop(self._addCallTimeKey)
	if needStartTime then
		self:TimerStart(self._addCallTimeKey, 1, false, -1)
		self:RefreshAddCallTimeText()
	else
		self:SetWndText(self.mCanCallTimeTxt, "")
	end
end

function UIPrepareMirrorYell:OnClickDetailsBtnFunc()
    GF.OpenWnd("UIYellHRew",{callRefId = self._callRefId,viewType = 2})
end

function UIPrepareMirrorYell:RefreshEndTimeText()
	local curTime = self:GetCurTime()
	local timeDuration = self._endTime - curTime

	if timeDuration < 0 or not gLGameLogin:IsOpenPreDrawCard() then
		self:WndClose()
		return
	end

	local str = LUtil.FormatTimespanToHourAndMin2(timeDuration)
	local dayLimitNumStr = string.replace(ccClientText(37401), str)
	self:SetTextTile(self.mTextTitle7,dayLimitNumStr)
end

function UIPrepareMirrorYell:CreateShowHeroLiHui()
	self:CreateWndSpine(self.mLiHuiPos,"mao_1")
end

--#####################################################################################################################
--## HeroLiHui ########################################################################################################
--#####################################################################################################################
function UIPrepareMirrorYell:RefreshCallShow()
	self:CreateEff()
	local ref = self:GetCallTypeRef()
	if not ref then return end
	self:TimerStop(self._cutHeroTimerKey)
	self:CreateShowHeroLiHui()
end

function UIPrepareMirrorYell:OnClickSaveBtn()
    local saveHeroStatus = self._saveHeroStatus
    if saveHeroStatus == UIPrepareMirrorYell.NOT_SAVE then
        GF.ShowMessage(ccClientText(37400))
    elseif saveHeroStatus == UIPrepareMirrorYell.IS_SAVE then
		local heroId = self._selectHeroId
        local func = function()
			gLGameLogin:PreselectHeroRequestURL(false, heroId)
        end
        gModelGeneral:OpenUIOrdinTips({refId = 10038,func = func})
    else
		GF.ShowMessage(ccClientText(37423))
    end
end

function UIPrepareMirrorYell:FakeMirrorCallHeroList(num)
	self:InitJackpotData()

	local getHeroList = {}
	math.randomseed(tostring(os.time()):reverse():sub(1, 7))
	local usedNum = self._usedNum
	local needTenCertainGet = self._tenCertainGetQuality and self._tenCertainGetQuality > 0
	local needAccumulateGet = false
	local haveAccumulateQuality = false
	local enoughTenCertainGetNum = 0
	for i = 1, num do
		usedNum = usedNum + 1

		local heroData
		if usedNum % 20 == 0 then
			--触发累积低保
			needAccumulateGet = true
		end

		if i == num and needAccumulateGet and not haveAccumulateQuality then
			heroData = self:GetRandomHeroDataByJackPotId(self._accumulateJackpot)
		elseif needTenCertainGet and i >= (10 - self._tenCertainGetNum) then
			heroData = self:GetRandomHeroDataByJackPotId(self._tenCertainJackpot)
		else
			heroData = self:GetRandomHeroDataByJackPotId()
		end

		if i < num then
			local itemQuality = heroData.itemQuality
			if needTenCertainGet then
				if itemQuality >= self._tenCertainGetQuality then
					enoughTenCertainGetNum = enoughTenCertainGetNum + 1
				end
				needTenCertainGet = enoughTenCertainGetNum < self._tenCertainGetNum
			end

			if not haveAccumulateQuality then
				haveAccumulateQuality = itemQuality >= self._accumulateCertainGetQuality
			end
		end


		table.insert(getHeroList, heroData.itemId)
	end

	return getHeroList
end

function UIPrepareMirrorYell:OnClickHelpBtnFunc()
	GF.OpenWnd("UIBzTips",{refId = 154, jumpTAClient = true})
end

function UIPrepareMirrorYell:InitData()
	self._callRefId		= self:GetWndArg("callRefId") or ModelCallHero.CALL_TYPE_PREPARE

	local channelOpenTime 	= gLGameLogin:GetChannelOpenTime()
	if channelOpenTime then
		self._endTime 		= tonumber(channelOpenTime)/1000 --开服时间,也是玩法结束时间
	end

	self._serverTimeStamp 	= tonumber(gLGameLogin:GetTimeStamp())/1000	  --玩家登录游戏的时间戳，GetTimestamp()是从这里开始算时间的

	--测试
	--self._endTime			= 1666108717.8
	--self._serverTimeStamp 	= self._endTime - 86400

	--LogError("结束时间"..LUtil.FormatYearMonthDay(self._endTime).."; "..LUtil.FormatInTheDayTime(self._endTime))
	--LogError("登录时间"..LUtil.FormatYearMonthDay(self._serverTimeStamp).."; "..LUtil.FormatInTheDayTime(self._serverTimeStamp))

	self._countDownTime 	= self:GetWndArg("countDownTime") --开服倒计时

	self._callRefIdEff = "fx_ui_putongzhaohuan_02"
	self._jumpAniStatus = false

    self._preCallLimit = gModelCallHero:GetCallConfigRefByKey("preCallLimit")
	self._openCallTime = self:GetMirrorCallStartTime()

	self:InitMirrorCallLocalHaveNumData()
	self:RefreshSelectHeroData()


	self._lihuiInitPos = self.mLiHuiPos.localPosition
end

function UIPrepareMirrorYell:OnClickOneCallBtnFunc()
	self:OnSendCallFunc(1)
end

function UIPrepareMirrorYell:ResetSelHeroIcon()
    local heroId = self._selectHeroId
	local iconTrans = CS.FindTrans(self.mSel,"CommonUI/Icon")
	local baseClass = self._commonIcon
	if not baseClass then
		baseClass = CommonIcon:New()
		self._commonIcon = baseClass
		baseClass:Create(iconTrans)
	end

	local heroRef = gModelHero:GetHeroRef(heroId)
	local heroStar = heroRef.initStar

	local heroData = {
		refId = heroId,
		star = heroStar,
		--level = itemdata.breakLv,
	}
	baseClass:SetHeroDataSet(heroData)
	baseClass:SetNoShowLv(true)
	baseClass:SetShowLock(self._saveHeroStatus == UIPrepareMirrorYell.IS_LOCK)
	baseClass:DoApply()

	self:SetWndClick(iconTrans,function()
		GF.OpenWndTop("UINewSagaStarPre", { refId = heroId, nextStar = heroStar, showType = 2, hideAwaken = true })
	end)
end

function UIPrepareMirrorYell:ShiftCallHeroShowList(getHeroList)
	local list = {}
	for k,v in ipairs(getHeroList) do
		table.insert(list, {itemId = v})
	end

	return list
end


function UIPrepareMirrorYell:OnSendCallFunc(callType)
	if self._isLock then
		GF.ShowMessage(ccClientText(37407))
		return
	end

	if not table.isempty(self._lastCallHerList) then
		GF.ShowMessage(ccClientText(37429))
		self:OpenCallReward(self._lastCallHerList)
		return
	end

	local cullNum = callType == 1 and 1 or 10
	local usedNum = self._usedNum + cullNum
	local preCallLimit = self._preCallLimit
	if preCallLimit and preCallLimit > 0 and usedNum >= preCallLimit then
		GF.ShowMessage(ccClientText(37406))
		return
	end

	if self._haveCallNum < cullNum then
		GF.ShowMessage(ccClientText(37405))
		return
	end

	local getHeroList = self:FakeMirrorCallHeroList(cullNum)
	local haveNum = self._haveCallNum - cullNum
	gModelCallHero:SetLocalPrepareMirrorCallData(haveNum, nil, cullNum, getHeroList)

	if self._jumpAniStatus then
		self:MirrorCallEndFunc(getHeroList)
	else
		GF.OpenWnd("UIMirrorYellSagaSow",{
			viewType = 1,
			callRefId = self._callRefId,
			mirrorCallEndFunc = function() return self:MirrorCallEndFunc(getHeroList) end,
			getHeroList = self:ShiftCallHeroShowList(getHeroList),
			callNum = cullNum,
		})
	end
end
--#####################################################################################################################
--## CallBtn ##########################################################################################################
--#####################################################################################################################
function UIPrepareMirrorYell:InitCallBtnTransInfo()
	local callBtnTransInfo = {}
	local oneCallBtnTrans = self.mOneCallBtn
	local oneCallTransInfo = self:GetCallBtnTransInfo(oneCallBtnTrans)
	callBtnTransInfo.oneCallTransInfo = oneCallTransInfo
	self:CreateBtnEff(oneCallTransInfo.effRootTrans,"fx_ui_putongzhaohuan_04")

	local tenCallBtnTrans = self.mTenCallBtn
	local tenCallTransInfo = self:GetCallBtnTransInfo(tenCallBtnTrans)
	callBtnTransInfo.tenCallTransInfo = tenCallTransInfo
	self:CreateBtnEff(tenCallTransInfo.effRootTrans,"fx_ui_putongzhaohuan_05")

	self._oneCallTimeTxtTrans = oneCallTransInfo.timeTxtTrans
	self._tenCallTimeTxtTrans = tenCallTransInfo.timeTxtTrans

	self._callBtnTransInfo = callBtnTransInfo

	self:RefreshCallBtn()
end

function UIPrepareMirrorYell:RefreshSaveBtn()
    local status = self._saveHeroStatus
	local str
	local isGary = false
	if status == UIPrepareMirrorYell.NOT_SAVE then
		str = ccClientText(37424)
	elseif status == UIPrepareMirrorYell.IS_SAVE then
		str = ccClientText(37425)
	else
		str = ccClientText(37428)
		isGary = true
	end

	self:SetWndButtonText(self.mSaveBtn, str)
	self:SetWndButtonTextLine(self.mSaveBtn, -30)
	self:SetWndButtonGray(self.mSaveBtn, isGary)
end

function UIPrepareMirrorYell:InitMirrorCallLocalHaveNumData()
	local data = LPlayerPrefs.prepareMirrorCall
	if string.isempty(data) then
		self._firstLoginTime = self._serverTimeStamp
		return
	end

	--非首次进入,需要计算玩家离线期间，恢复的次数
	local originCallNum = self:GetOriginCallNum()

	local dataList = string.split(data, '=')
	local usedCallNum = dataList[3]
	local usedNum
	if not string.isempty(usedCallNum) then
		usedNum = tonumber(usedCallNum)
	else
		usedNum = 0
	end

	local firstLoginTime = tonumber(dataList[5])
	self._firstLoginTime = firstLoginTime / 1000

	--测试
	--self._firstLoginTime = self._serverTimeStamp
	--LogError("第一次登录时间"..LUtil.FormatYearMonthDay(self._firstLoginTime).."; "..LUtil.FormatInTheDayTime(self._firstLoginTime))


	--从开服开始，已经过去的时间
	local nextTime, addNum = self:GetNextAddCallTime()
	local haveNum = originCallNum + addNum - usedNum

	gModelCallHero:SetLocalPrepareMirrorCallData(haveNum)
end

function UIPrepareMirrorYell:RefreshAddCallTimeText()
	local curTime = self:GetCurTime()
	local timeDuration = self._nextAddCallTime - curTime
	if timeDuration < 0 then
		gModelCallHero:SetLocalPrepareMirrorCallData(self._haveCallNum + 1)
		self:RefreshSelectHeroData()
		self:RefreshCanCallTimeText()
		self:ResetAddCallTimeText()
		return
	end

	local str = LUtil.FormatTimeToCn3(timeDuration)
	local dayLimitNumStr = string.replace(ccClientText(37403), str)
	self:SetWndText(self.mCanCallTimeTxt,dayLimitNumStr)
end

function UIPrepareMirrorYell:GetRandomHeroDataByJackPotId(jackPot)
	local heroList, allProbabilityValue
	if not jackPot then
		--heroList, allProbabilityValue = gModelCallHero:GetPrepareMirrorCallHeroList()
		heroList, allProbabilityValue = gModelCallHero:GetPrepareMirrorCallHeroListByCommonJackPot()
	else
		heroList, allProbabilityValue = gModelCallHero:GetPrepareMirrorCallHeroListBySmallJackPot(jackPot)
	end

	local tempValue = math.random(1,allProbabilityValue)
	local heroData
	for k,v in ipairs(heroList) do
		if v.firstProbability < tempValue and tempValue <= v.endProbability then
			heroData = v
			break
		end
	end


	if not heroData then
		tempValue = math.random(1,#heroList)
		heroData = heroData[tempValue]
	end

	return heroData
end

function UIPrepareMirrorYell:CreateBtnEff(trans,effName)
	local key = trans:GetInstanceID()
	self:CreateWndEffect(trans,effName,key,100,false,false)
end

function UIPrepareMirrorYell:OpenCallReward(getHeroList, needAni)
	GF.OpenWnd("UIPrepareMirrorYellAwardTop",{rewards = getHeroList, needAni = needAni})
end

function UIPrepareMirrorYell:OnClickTenCallBtnFunc()
	self:OnSendCallFunc(2)
end

function UIPrepareMirrorYell:RefreshSelText()
    --local saveHeroStatus = self._saveHeroStatus
    --local str
    --if saveHeroStatus == UIPrepareMirrorYell.NOT_SAVE then
    --
    --elseif saveHeroStatus == UIPrepareMirrorYell.NOT_SAVE then
    --
    --else
    --
    --end

    self:SetWndText(self.mSelText, ccClientText(37422))
end

function UIPrepareMirrorYell:RefreshJumpAniStatus()
	local status = self._jumpAniStatus
	CS.ShowObject(self.mJumpAniBgGou,status)
end


--#####################################################################################################################
--## Timer ############################################################################################################
--#####################################################################################################################
function UIPrepareMirrorYell:OnTimer(key)
	if key == self._endTimeKey then
		self:RefreshEndTimeText()
	elseif key == self._addCallTimeKey then
		self:RefreshAddCallTimeText()
	elseif key == self._cutHeroTimerKey then
		self:TimerStop(self._cutHeroTimerKey)
	end
end

function UIPrepareMirrorYell:InitEvent()
    self:SetWndClick(self.mDetailsBtn,function() self:OnClickDetailsBtnFunc() end)
	self:SetWndClick(self.mHelpBtn,function() self:OnClickHelpBtnFunc() end)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
	self:SetWndClick(self.mSaveBtn, function() self:OnClickSaveBtn() end)
    self:SetWndClick(self.mNoSel, function() self:OnClickNoSel() end)
	self:SetWndClick(self.mJumpAniBtn,function() self:OnClickJumpAniFunc() end)
	self:SetWndClick(self.mJumpAniBg,function() self:OnClickJumpAniFunc() end)
	self:SetWndClick(self.mOneCallBtn,function() self:OnClickOneCallBtnFunc() end)
	self:SetWndClick(self.mTenCallBtn,function() self:OnClickTenCallBtnFunc() end)
end

function UIPrepareMirrorYell:CreateTimer(key,time,loopCnt)
	time = time or 1
	loopCnt = loopCnt or -1
	self:TimerStop(key)
	self:TimerStart(key,time,false,loopCnt)
end

function UIPrepareMirrorYell:RefreshCallBtn()
	local callBtnTransInfo = self._callBtnTransInfo
	local oneCallInfo = {
		btnName = ccClientText(11600),
		payType = 1,
	}

	local oneCallTransInfo = callBtnTransInfo.oneCallTransInfo
	self:SetCallBtn(oneCallTransInfo,oneCallInfo)

	local tenCallTransInfo = callBtnTransInfo.tenCallTransInfo
	local tenCallInfo = {
		btnName = ccClientText(11608),
		payType = 10,
	}
	self:SetCallBtn(tenCallTransInfo,tenCallInfo)
end

function UIPrepareMirrorYell:GetCallTypeRef()
    if not self._callRef then
        local callRefId = self._callRefId
        self._callRef = gModelCallHero:GetCallRefByRefId(callRefId)
    end

    return self._callRef
end

function UIPrepareMirrorYell:GetNextAddCallTime()
	local startTime 	= self._openCallTime
	local curTime 		= self:GetCurTime()
	local recoveryTime 	= gModelCallHero:GetCallConfigRefByKey("recoveryTime")
	local preCallTime 	= gModelCallHero:GetCallConfigRefByKey("preCallTime")
	local recoveryTimeValue = recoveryTime * 60

	local durationNum = math.floor(preCallTime / recoveryTime) + 1
	local nextRefreshTime = startTime
	local addNum = 0
	for i = 1, durationNum do
		nextRefreshTime = nextRefreshTime + recoveryTimeValue
		if nextRefreshTime > curTime then
			break
		end

		if nextRefreshTime> self._firstLoginTime then
			addNum = addNum + 1
		end
	end

	--LogError("下次刷新时间"..LUtil.FormatYearMonthDay(nextRefreshTime).."; "..LUtil.FormatInTheDayTime(nextRefreshTime))
	--LogError("当前时间"..LUtil.FormatYearMonthDay(curTime).."; "..LUtil.FormatInTheDayTime(curTime))


	if nextRefreshTime >= self._endTime then
		return nil, addNum
	end

	return nextRefreshTime, addNum
end

function UIPrepareMirrorYell:OnClickJumpAniFunc()
	self._jumpAniStatus = not self._jumpAniStatus
	self:RefreshJumpAniStatus()
end

function UIPrepareMirrorYell:SetCallBtn(transInfo,dataInfo)
	local btnNameTrans = transInfo.btnNameTrans
	local payDivTrans = transInfo.payDivTrans
	local iconImgTrans = transInfo.iconImgTrans
	local numTxtTrans = transInfo.numTxtTrans
	local freeTxtTrans = transInfo.freeTxtTrans
	local redPointTrans = transInfo.redPointTrans

	local btnName = dataInfo.btnName

	self:SetWndText(btnNameTrans,btnName)
	CS.ShowObject(btnNameTrans,true)

	local freeText = dataInfo.freeText
	if freeText then
		self:SetWndText(freeTxtTrans,freeText)
	end

	local itemId = dataInfo.itemId
	if itemId then
		local icon = gModelItem:GetItemIconByRefId(itemId)
		self:SetWndEasyImage(iconImgTrans,icon)

		local itemNum = dataInfo.itemNum
		self:SetWndText(numTxtTrans,itemNum)
	end

	local isHaveFree = dataInfo.isHaveFree
	CS.ShowObject(freeTxtTrans,isHaveFree)
	CS.ShowObject(redPointTrans,isHaveFree)
	CS.ShowObject(payDivTrans,not isHaveFree and itemId)
end

function UIPrepareMirrorYell:OnClickNoSel()
    GF.ShowMessage(ccClientText(37400))
end

function UIPrepareMirrorYell:GetMirrorCallStartTime()
	local preCallTime = gModelCallHero:GetCallConfigRefByKey("preCallTime")

	local openTime = self._endTime - preCallTime * 60
	return openTime
end

function UIPrepareMirrorYell:GetMirrorCallLocalData()
	local data = LPlayerPrefs.prepareMirrorCall
	local haveNum, selectHeroId, usedNum, lastCallHeroList
	if not string.isempty(data) then
		--非首次进入
		local dataList = string.split(data, '=')
		local haveCallNum = dataList[1]
		if not string.isempty(haveCallNum) then
			haveNum = tonumber(haveCallNum)
		end

		local heroId = dataList[2]
		if not string.isempty(heroId) then
			selectHeroId = tonumber(heroId)
		end

		local usedCallNum = dataList[3]
		if not string.isempty(usedCallNum) then
			usedNum = tonumber(usedCallNum)
		end

		local heroListStr = dataList[4]
		if not string.isempty(heroListStr) then
			lastCallHeroList = {}
			local list = string.split(heroListStr, "|")
			for k,v in ipairs(list) do
				table.insert(lastCallHeroList, tonumber(v))
			end
		end
	end

	if not haveNum then
		--首次进入
		haveNum = self:GetOriginCallNum()
	end

	if not usedNum then
		usedNum = 0
	end

	return haveNum, selectHeroId, usedNum, lastCallHeroList
end

function UIPrepareMirrorYell:RefreshSelHeroIcon()
    local isShowHero  = self._saveHeroStatus ~= UIPrepareMirrorYell.NOT_SAVE
    CS.ShowObject(self.mNoSel, not isShowHero)
    CS.ShowObject(self.mSel, isShowHero)

    if isShowHero then
        self:ResetSelHeroIcon()
    end
end
--#####################################################################################################################
--## SelPage ##########################################################################################################
--#####################################################################################################################
function UIPrepareMirrorYell:RefreshSelPage()
    local saveHeroStatus = UIPrepareMirrorYell.NOT_SAVE
    if self._isLock then
        saveHeroStatus = UIPrepareMirrorYell.IS_LOCK
    elseif self._selectHeroId ~= nil then
        saveHeroStatus = UIPrepareMirrorYell.IS_SAVE
    end
    self._saveHeroStatus = saveHeroStatus

    self:RefreshSelHeroIcon()
    self:RefreshSaveBtn()
    self:RefreshSelText()
end

--#####################################################################################################################
--## CallView #########################################################################################################
--#####################################################################################################################
function UIPrepareMirrorYell:RefreshCallView()

	self:RefreshCallTypeView()
end

function UIPrepareMirrorYell:RefreshLimitText()
	local ref = self:GetCallTypeRef()
	if not ref then return end
	if not self._preCallLimit or self._preCallLimit <= 0 then return end

	local callNum = self._usedNum
	local dayLimitNumStr = string.replace(ccClientText(37404), callNum, self._preCallLimit)
	self:SetWndText(self.mLimitCallTxt, dayLimitNumStr)
end

function UIPrepareMirrorYell:SetRandCallText()
	local ref = self:GetCallTypeRef()
	if not ref then return end

	local showStar = string.split(ref.showStar,",")
	local showStarStr = string.replace(ccClientText(11605), showStar[1], showStar[2])
	self:SetWndText(self.mRandCallTxt,showStarStr)
end


--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UIPrepareMirrorYell:RefreshView()
	self:SetRandCallText()
	self:RefreshJumpAniStatus()

	self:RefreshCallView()
	self:RefreshCallShow()

	self:RefreshSelPage()
	self:RefreshEndTimeText()
	self:CreateTimer(self._endTimeKey)
end

function UIPrepareMirrorYell:InitJackpotData()
	if self._tenCertainJackpot or self._accumulateJackpot then return end

	local ref = self:GetCallTypeRef()
	local tenCertainGet = ref.tenCertainGet
	if not string.isempty(tenCertainGet) then
		local tenCertainGetData 	= string.split(tenCertainGet, "=")
		self._tenCertainGetQuality 	= tonumber(tenCertainGetData[1])
		self._tenCertainGetNum 		= tonumber(tenCertainGetData[2])
	end

	self._tenCertainJackpot			= ref.tenCertainJackpot

	local accumulateCertainGet 		= ref.accumulateCertainGet
	if not string.isempty(accumulateCertainGet) then
		local accumulateCertainGetData 		= string.split(accumulateCertainGet, "=")
		self._accumulateCertainGetTimes 	= tonumber(accumulateCertainGetData[1])
		self._accumulateCertainGetQuality 	= tonumber(accumulateCertainGetData[2])
	end

	self._accumulateJackpot			= ref.accumulateJackpot
end

function UIPrepareMirrorYell:GetCurTime()
	return self._serverTimeStamp + GetTimestamp()
end

function UIPrepareMirrorYell:RefreshSelectHeroData()
	local haveNum, selectHeroId, usedNum, lastCallHerList = self:GetMirrorCallLocalData()
	self._haveCallNum = haveNum
	local prepareHeroId = gModelCallHero:GetPrepareHeroId() or selectHeroId
	self._selectHeroId = prepareHeroId
	self._usedNum = usedNum
	self._lastCallHerList = lastCallHerList

	local canGet = gModelCallHero:CanGetPrepareHero()
	self._isLock = prepareHeroId and canGet
end


function UIPrepareMirrorYell:RefreshHeroCVName(heroRefId)
	local cvName = gModelHero:GetHeroCVName(heroRefId)

	cvName =  ""

	local isShow = not string.isempty(cvName)
	CS.ShowObject(self.mCVNameBg, isShow)
	if not isShow then return end

	local cvNameStr = string.replace(ccClientText(19786), cvName)
	self:SetWndText(self.mCVNameTxt, cvNameStr)
end

function UIPrepareMirrorYell:InitStaticContent()
    self:SetTextTile(self.mDetailsBtn,ccClientText(37437))			-- 详情
	self:SetTextTile(self.mHelpBtn,ccClientText(37438))			-- 详情
	self:SetWndText(self.mJumpAniBgTxt,ccClientText(18321))
	self:InitTextLineWithLanguage(self.mJumpAniBgTxt, -30)
end

function UIPrepareMirrorYell:GetOriginCallNum()
    local ref = self:GetCallTypeRef()
    return ref.originNum
end

function UIPrepareMirrorYell:MirrorCallEndFunc(getHeroList)
	self:OpenCallReward(getHeroList, true)
end

function UIPrepareMirrorYell:InitMsg()
	self:WndEventRecv(EventNames.ON_PREPARE_SERVER_READY, function ()
		self:RefreshSelectHeroData()
		self:RefreshSelPage()
	end)

	self:WndEventRecv(EventNames.ON_WND_CLOSE,function (wndName)
		if wndName == "UIPrepareMirrorYellAwardTop" then
			self:RefreshSelectHeroData()
			self:RefreshCallView()
			self:RefreshSelPage()
		end
	end)
end

function UIPrepareMirrorYell:GetCallBtnTransInfo(btnTrans)
	local EffRootTrans = self:FindWndTrans(btnTrans,"EffRoot")
	local btnNameTrans = self:FindWndTrans(btnTrans,"BtnName")
	local timeTxtTrans = self:FindWndTrans(btnTrans,"TimeTxt")
	local payDivTrans = self:FindWndTrans(btnTrans,"PayDiv")
	local iconImgTrans = self:FindWndTrans(payDivTrans,"IconImg")
	local numTxtTrans = self:FindWndTrans(payDivTrans,"NumTxt")
	local freeTxtTrans = self:FindWndTrans(btnTrans,"FreeTxt")
	local redPointTrans = self:FindWndTrans(btnTrans,"redPoint")
	return {
		effRootTrans = EffRootTrans,
		btnNameTrans = btnNameTrans,
		timeTxtTrans = timeTxtTrans,
		payDivTrans = payDivTrans,
		iconImgTrans = iconImgTrans,
		numTxtTrans = numTxtTrans,
		freeTxtTrans = freeTxtTrans,
		redPointTrans = redPointTrans,
	}
end

function UIPrepareMirrorYell:CreateEff()
	local effName = self._callRefIdEff
	if not effName then return end
	local newEffect = self:FindWndEffectByKey(effName)
	if newEffect then
		newEffect:SetVisible(true)
	else
		self:CreateWndEffect(self.mEffRoot,effName,effName,100,false,false)
	end
end



------------------------------------------------------------------
return UIPrepareMirrorYell


