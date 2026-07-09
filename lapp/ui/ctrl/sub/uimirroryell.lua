---
--- Created by Administrator.
--- DateTime: 2023/10/22 11:42:41
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UIMirrorYell:LChildWnd
local UIMirrorYell = LxWndClass("UIMirrorYell", LChildWnd)

local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMirrorYell:UIMirrorYell()
	---@type table<string,LUIHeroObject>
	self._uiHeroObjList = nil			-- spine列表
	---@type LUIHeroObject
	self._curUIHeroObj = nil 			-- 当前spine
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMirrorYell:OnWndClose()
	self:ClearAllTime()
	LUtil.ClearHashTable(self._uiHeroObjList)
	self._uiHeroObjList = nil
	--这个是从列表器拿出来的，列表进行删除就好了
	self._curUIHeroObj = nil
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMirrorYell:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMirrorYell:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mActRewardBtnTxt,ccClientText(11650))
	self:InitText()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:SetServerData()
	if not table.isempty(self._rewardList) then
		self:InitView()
	end
	self:CreateWndSpine(self.mBoLiRoot,"zhaohuan","zhaohuan",false,function(dpSpine)
		dpSpine:PlayAnimation(0,"idle",true)
	end)

	gModelCallHero:CallOpt(self._page)

	self:SetWndShowByJump()
	self:TimerStart(self._timerPrivileKey,0.5,false,1)
end

function UIMirrorYell:GetRefData()
	self._refData = {}
	local refData = gModelCallHero:GetTypeData(self._page)
	self._refData = table.clone(refData)
	local activityDataList = self:GetActivityData()
	for i,v in ipairs(activityDataList) do
		local sid = v.sid
		local data = v.config
		if data then
			local key = "activity" .. i
			local actRefData = {
				isActivity = true, 							-- 是否是活动
				sid = sid,
				icon = data.icon1,
				freeExtractNum = data.freeExtractNum,
				freeExtractTime = data.freeExtractTime,
				srot = data.srot,
				dayExtractNumMax = data.dayExtractNumMax,
				backgroundIcon = data.backgroundIcon,
				getBackground = data.getBackground,
				btn1 = data.btn1,
				btn2 = data.btn2,
				nameIcon = data.nameIcon,
				showItem = data.showItem,
				oneExpend = data.oneExpend,
				tenExpend = data.tenExpend,
				tipsText = data.tipsText,
				endTime = v.endTime,
			}
			self._actRefIdList[sid] = key
			self._refData[key] = actRefData
		end
	end
end

function UIMirrorYell:SaveParentWndArg()
	local parentWnd = self:GetParentWnd()
	if parentWnd then
		local wndArg = parentWnd:GetWndArgList() or {}
		wndArg["page"] = self._page
		wndArg["subPage"] = self._subPage
		parentWnd:SetWndArg(wndArg)
	end
end

function UIMirrorYell:OnDrawItem(list, item, itemdata, itempos)
	local refId = itemdata.refId
	local bgTrans = self:FindWndTrans(item,"Bg")
	if bgTrans then
		local IconTrans = self:FindWndTrans(bgTrans,"Icon")
		local NumTrans = self:FindWndTrans(bgTrans,"Num")
		if IconTrans then
			local icon = gModelItem:GetItemIconByRefId(refId)
			self:SetWndEasyImage(IconTrans, icon)
		end
		if NumTrans then
			local haveNum = gModelItem:GetNumStrByRefId(refId)
			self:SetWndText(NumTrans, haveNum)
		end
	end
	local BtnTrans = self:FindWndTrans(item,"Btn")
	if BtnTrans then
		self:SetWndClick(BtnTrans,function()
			-- local serverData = self._rewardList[self._subPage]
			-- if serverData then
			-- 	local sid = serverData.sid
			-- 	if sid then
			-- 		GF.OpenWndBottom("UIActCallHeroReward",{sid  = sid})
			-- 		FireEvent(EventNames.ON_MOJING_MAIN)
			-- 		return
			-- 	end
			-- end
			gModelGeneral:OpenGetWayWnd({itemId = refId})
		end)
	end
end
----------------------------- 活动倒计时 -----------------------------
function UIMirrorYell:StartCountDownTimer()
	self:TimerStop(self._timerKey)
	self:TimerStart(self._timerKey,1,false,-1)
end

function UIMirrorYell:InitEvent()
	self:SetWndClick(self.mOneCallBtn,function()
		self:CreateWndEffect(self.mOneCallEffRoot,"fx_ui_ZH_dianji","fx_ui_ZH_dianji_1",100,false,false)
		local isActivity = self:IsActivity()
		if isActivity then
			self:ActOneCall()
		else
			--self:OneCall()
            self:SendCallReq(1)
		end
	end)
	self:SetWndClick(self.mTenCallBtn,function()
		self:CreateWndEffect(self.mTenCallEffRoot,"fx_ui_ZH_dianji","fx_ui_ZH_dianji_10",100,false,false)
		local isActivity = self:IsActivity()
		if isActivity then
			self:ActTenCall()
		else
			--self:TenCall()
            self:SendCallReq(2)
		end
	end)
	self:SetWndClick(self.mBoxBtn,function()
        local integralNeedItem = GameTable.SummonConfigRef["integralNeedItem"]
        local temp = string.split(integralNeedItem, "=")
        local needNum = tonumber(temp[3])
        local needVip = GameTable.SummonConfigRef["integralNeedVip"]
        GF.OpenWnd("UIIntegralYell",{vip = needVip,num = needNum})
	end)
	self:SetWndClick(self.mLogBtn,function()
		local serverData = self._rewardList[self._subPage]
		local sid = serverData.sid
		if sid then
			GF.OpenWnd("UIYellLog",{sid = sid,callType = 3})
		else
			GF.OpenWnd("UIYellLog",{callType = self._page})
		end
	end)
	self:SetWndClick(self.mRecommendBtn,function()
		gModelFunctionOpen:Jump(gModelCallHero:GetCallConfigRefByKey("growJump"),self:GetWndName())
	end)
	self:SetWndClick(self.mLookBtn,function()
		GF.OpenWnd("UIYellHRu",{extractType = self._page})
	end)
	self:SetWndClick(self.mActivityAddBtn,function()
		self:OpenActivitySel()
	end)
	self:SetWndClick(self.mActivityChangeBtn,function()
		self:OpenActivitySel()
	end)
	self:SetWndClick(self.mActRewardBtn,function()
		--self:OpenActivitySel(true)

		local serverData = self._rewardList[self._subPage]
		if serverData then
			local title,desc = serverData.title,serverData.desc
			GF.OpenWnd("UIBzTips",{title = title,text = desc,bTransWarp = true})
		end
	end)
	self:SetWndClick(self.mRankBtn,function ()
		self:OnClickRank()
	end)
end

function UIMirrorYell:GetActivityData()
	--return gModelActivity:GetActivityDataByModelId(ModelActivity.ACTIVITY_CALLHERO,1)
	local sidList = {}
	-- local actList = gModelActivity:GetActivityDataByModelId(ModelActivity.ACTIVITY_CALLHERO,1)
	-- for i,v in ipairs(actList) do
	-- 	local sid = v.sid
	-- 	local actData = gModelActivity:GetWebActivityDataById(sid)
	-- 	if actData then
	-- 		local data = table.clone(actData)
	-- 		data.sid = sid
	-- 		data.endTime = v.endTime
	-- 		table.insert(sidList,data)
	-- 	end
	-- end
	return sidList
end

function UIMirrorYell:IsHaveFreeNum(refId,times)
	local serverData = self._rewardList[self._subPage]
	local freeNum = serverData.freeNum
	if freeNum == 1 then
		local sid = serverData.sid
		if sid then
			self:SendActMsg(refId,times,true)
		else
			self:SendMsg(refId,times, 0)
		end
		return true
	end
	return false
end

function UIMirrorYell:IsUpperLimit()
	local serverData = self._rewardList[self._subPage]
	local refId = serverData.refId
	local refData = self._refData[refId]
	if serverData and refData then
		local dayExtractNumMax = refData.dayExtractNumMax
		if dayExtractNumMax <= serverData.callNum then
			GF.ShowMessage(ccClientText(11626))
			return true
		end
	end
	return false
end

function UIMirrorYell:InitMsg()
	self:WndNetMsgRecv(LProtoIds.MagicResp, function()
		self:SetServerData()
		self:InitView()
		--self:RefreshCallRedPoint()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivitySelectDropGiftResp, function()
		self:SetServerData()
		self:InitView()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityDropGiftResp, function()
		self._sendMsg = false
		self:SetServerData()
		self:InitView()
		--self:RefreshCallRedPoint()
	end)
	self:WndNetMsgRecv(LProtoIds.CallHeroResp, function()
		self._sendMsg = false
		self._refreshTop = true
		gModelCallHero:CallOpt(self._page)
	end)
	self:WndEventRecv(EventNames.ON_MOJING_ZHAOHUAN,function()
		self._sendMsg = true
	end)
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function()
		self._sendMsg = false
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function()
		if self._uiList then
			local uiList = self._uiList:GetList()
			uiList:RefreshList()
		end
		self:InitView()
	end)
end

function UIMirrorYell:OnTcpReconnect()
	self._sendMsg = false
end

-- 活动数据
function UIMirrorYell:GetActivityCallData()
	local activityCall = {}
	local sidKeyList = {}
	-- local actList = gModelActivity:GetActivityDataByModelId(ModelActivity.ACTIVITY_CALLHERO,1)
	local actList = {}
	for i,v in ipairs(actList) do
		sidKeyList[v.sid] = v
	end
	local activityDataList = self:GetActivityData()
	for i,v in ipairs(activityDataList) do
		local sid = v.sid
		local config = v.config
		if config then
			local wishHero = {}
			local wishHeroList = string.split(config.wishHero,";")
			for idx,val in ipairs(wishHeroList) do
				val = string.split(val,"=")
				local dropId,guard = tonumber(val[1]),tonumber(val[2])
				wishHero[dropId] = guard
			end
			local actData = sidKeyList[sid] or {}
			local moreInfo = JSON.decode(actData.moreInfo) or {}
			local refId = self._actRefIdList[sid]
			local data = {
				sid = sid,
				refId = refId,
				freeNum = moreInfo.freeNum,
				callNum = moreInfo.callNum,
				refreshTimeOfFreeNum = moreInfo.refreshTimeOfFreeNum,
				refreshTimeOfCallNum = moreInfo.refreshTimeOfCallNum,
				nextRefreshTimeOfFreeNum = moreInfo.nextRefreshTimeOfFreeNum,
				nextRefreshTimeOfCallNum = moreInfo.nextRefreshTimeOfCallNum,
				allNum = -1,
				mySelect = moreInfo.mySelect,
				myDropNum = moreInfo.myDropNum,
				mySelectHero = moreInfo.mySelectHero,
				wishHero = wishHero,
				desc = config.desc,
				title = v.title,
			}
			table.insert(activityCall,data)
		end
	end
	return activityCall
end

function UIMirrorYell:CreateFingerEff()
	local effectName = "fx_ui_shou_2"
	self:CreateWndEffect(self.mActivityAddBtn,effectName,self._effKey,100,nil,nil,10)
	self:TimerStop(self._effTimerKey)
end

function UIMirrorYell:InitItemList(dataList)
	if(self._uiList)then
		self._uiList:RefreshList(dataList)
	else
		self._uiList = self:GetUIScroll("_uiList")
		self._uiList:Create(self.mItemList,dataList,function (...) self:OnDrawItem(...) end)
	end
end

function UIMirrorYell:OpenActivitySel(ispre)
	local serverData = self._rewardList[self._subPage]
	if not serverData then return end
	local refData = self._refData[serverData.refId]
	local isActivity = refData.isActivity
	if not isActivity then return end
	local sid,wishHero,mySelectHero = serverData.sid,serverData.wishHero,serverData.mySelectHero
	if ispre then
		mySelectHero = nil
	end
	GF.OpenWnd("UIActSagaSel",{sid = sid,wishHero = wishHero,preview = ispre,mySelectHero = mySelectHero})
end

function UIMirrorYell:OnItemCenter(item, itemdata, itempos)
	self:RefreshTop(itemdata,itempos)
end

function UIMirrorYell:StarCountDown()
	local lastTime = self._endTime - GetTimestamp()
	if lastTime < 0 then
		self:SetWndText(self.mChouquTxt,ccClientText(14301))
		self:TimerStop(self._timerKey)
	else
		local timeStr = LUtil.FormatTimespanCn(lastTime)
		--timeStr = LUtil.FormatColorStr(timeStr,"green")
		timeStr = string.replace(ccClientText(11640),timeStr)
		self:SetWndText(self.mChouquTxt,timeStr)
	end
end

function UIMirrorYell:IsActSelHero()
	local serverData = self._rewardList[self._subPage]
	if serverData then
		local mySelect = serverData.mySelect
		if mySelect and mySelect ~= 0 then
			return true
		end
	end
	GF.ShowMessage(ccClientText(11646))
	self:TimerStop(self._effTimerKey)
	self:DestroyWndEffectByKey(self._effKey)
	self:CreateFingerEff()
	return false
end

function UIMirrorYell:InitView()

	self:CreateWndEffect(self.mOneCallEffRoot,"fx_ui_ZH_anniu","OneCall",100,false,false)
	self:CreateWndEffect(self.mTenCallEffRoot,"fx_ui_ZH_anniu","TenCall",100,false,false)
	local dataList = {}
	local rewardList = self._rewardList

	local leftIndex,centerIndex,rightIndex = 2,1,3

	local leftData = rewardList[leftIndex]
	leftData.index = leftIndex
	table.insert(dataList,leftData)

	local firstData = rewardList[centerIndex]
	firstData.index = centerIndex
	table.insert(dataList,firstData)

--[[	local rightData = rewardList[rightIndex]
	rightData.index = rightIndex
	table.insert(dataList,rightData)]]

	local refData = self._refData
	for i,v in ipairs(rewardList) do
		local tRefId = v.refId
		local refInfo = refData[tRefId]
		if refInfo then
			local srot = refInfo.srot
			if self._init then
				local sid = v.sid
				if sid and sid == self._sid then
					self._subPage = srot
				end
			end
			if srot ~= leftIndex and srot ~= centerIndex then
				local cloneData = table.clone(v)
				cloneData.index = srot
				cloneData.pageIndex = i
				table.insert(dataList,cloneData)
			end
		end
	end
	self._init = false

	local index = 1
	if self._subPage == 1 then
		index = 2
	elseif self._subPage == 2 then
		index = 1
	elseif self._subPage == 3 then
		index = 3
	else
		index = self._subPage
	end

	self._dataList = dataList

	local uiList = self._uiCallHeroList
	if uiList then
		local list = uiList:GetList()
		list:RemoveAll()
	else
		uiList = self:GetUIScroll("callMirrorList")
		self._uiCallHeroList = uiList
	end

	self:RefreshTop(dataList[index])

	if not CS.IsShowObject(self.mCallTypeList) then
		return
	end

	self:SaveParentWndArg()

	uiList:InitListData({
		root = self.mCallTypeList,
		dataList = dataList,
		setFunc = function (...) self:TabListItem(...) end,
		type = UIItemList.CIRCLE,
		onCenterFunc = function (...) self:OnItemCenter(...) end,
		centerPos = index
	})
	self:RefreshCallRedPoint()
end

function UIMirrorYell:ClearTimer(request,index)
	local timerList = self._timerList
	local timer = timerList[index]
	if timer then
		LxTimer.DelayTimeStop(timer)
		timerList[index] = nil
	end
	if request then
		gModelCallHero:CallOpt(self._page)
	end
end

-- 每日定时器
function UIMirrorYell:SetDayTimer(addHour,index,trans)
	local curTime = GetTimestamp()
	local curYear = tonumber(LUtil.OSDate("%Y",curTime))
	local curMon = tonumber(LUtil.OSDate("%m",curTime))
	local curDay = tonumber(LUtil.OSDate("%d",curTime))
	local curHour = tonumber(LUtil.OSDate("%H",curTime))
	local addDay = 0
	if curHour >= addHour then addDay = 1 end
	local newDay = curDay + addDay

	local serverData = self._rewardList[index]
	if serverData then
		local refreshTimeOfFreeNum = serverData.refreshTimeOfFreeNum
		local serDay = tonumber(LUtil.OSDate("%d",refreshTimeOfFreeNum/1000))
		if newDay - serDay > 1 then
			self:ClearAllTime(true)
			return
		end
	end

	local nextDayTime = LUtil.OSTime({hour = addHour,day = newDay,month = curMon,year = curYear})
	local remainTime = nextDayTime - curTime
	local str = string.replace(ccClientText(11623),LUtil.FormatTimespanNumber(remainTime))
	if remainTime <= 0 then
		self:SetWndText(trans,"")
		self:ClearTimer(true,index)
	else
		self:SetWndText(trans,str)
	end
end

function UIMirrorYell:ClearAllTime(request)
	if request then gModelCallHero:CallOpt(self._page) end
	if table.isempty(self._timerList) then return end
	for k,v in pairs(self._timerList) do
		LxTimer.DelayTimeStop(v)
	end
	self._timerList = {}
end

--function UIMirrorYell:CreateBoLiSpine()
--	local spine = self._createList[self._subPage]
--end

function UIMirrorYell:ChangePayBtn(expend, iconTrans, numTrans,payTimes,isActivity,tipsText,callNum,dayExtractNumMax)
	expend = string.split(expend, "|")
	local payRefId, payNum,haveNum
	if #expend == 1 then
		local data = string.split(expend[1], "=")
		payRefId, payNum = tonumber(data[2]), tonumber(data[3])
		haveNum = gModelItem:GetNumByRefId(payRefId)
	else
		for i, v in ipairs(expend) do
			local data = string.split(v, "=")
			local refId, num = tonumber(data[2]), tonumber(data[3])
			haveNum = gModelItem:GetNumByRefId(refId)
			if i == 1 and haveNum >= num then
				payRefId,payNum = refId,num
				break
			else
				payRefId,payNum = refId,num
			end
		end
	end
	if payTimes == 1 then
		self._onePayRefId,self._onePayNum = payRefId,payNum
	elseif payTimes == 10 then
		self._tenPayRefId,self._tenPayNum = payRefId,payNum
	end
	self:SetWndText(numTrans, payNum)

	local icon = gModelItem:GetItemIconByRefId(payRefId)
	self:SetWndEasyImage(iconTrans, icon)

	if payTimes == 10  then
		CS.ShowObject(self.mTenRedShowImg,isActivity ~= nil)
		if isActivity then
			self:SetWndText(self.mTenRedShowTxt,tipsText)
			local str = string.replace(ccClientText(11639),callNum,dayExtractNumMax)
			self:SetWndText(self.mTenCallNumTxt,str)
		end
	end
end

function UIMirrorYell:OnTimer(key)
	if key == self._timerKey then
		self:StarCountDown()
	elseif key == self._effTimerKey then
		self:CreateFingerEff()
	elseif key == self._timerPrivileKey then
		self:OpentPrivileKey()
	end
end

function UIMirrorYell:IsActivity()
	local serverData = self._rewardList[self._subPage]
	if serverData and serverData.sid then
		return true
	end
	return false
end

-- 时间间隔定时器
function UIMirrorYell:SetHourTimer(addHour,index,trans)
	local serverData = self._rewardList[index]
	local serverTime = serverData.refreshTimeOfFreeNum / 1000
	local curYear = tonumber(LUtil.OSDate("%Y",serverTime))
	local curMon = tonumber(LUtil.OSDate("%m",serverTime))
	local curDay = tonumber(LUtil.OSDate("%d",serverTime))
	local curHour = tonumber(LUtil.OSDate("%H",serverTime))
	local nextDayTime = LUtil.OSTime({hour = curHour + addHour,day = curDay,month = curMon,year = curYear})
	local curTime = tonumber(GetTimestamp())
	if nextDayTime < curTime then
		self:ClearTimer(true,index)
	else
		local remainTime = nextDayTime - curTime
		local str = string.replace(ccClientText(11623),LUtil.FormatTimespanNumber(remainTime))
		self:SetWndText(trans,str)
		if remainTime <= 0 then
			self:ClearTimer(true,index)
		end
	end
end
----------------------------- 定时器 -----------------------------
function UIMirrorYell:CreateServerTimer(endTime,refId,trans)
	self:ClearTimer(nil,refId)
	if not self._timerList then self._timerList = {} end
	endTime = endTime/1000
	self:CallHeroCountDown(endTime,refId,trans)
	self._timerList[refId] = LxTimer.LoopTimeCall(function()
		self:CallHeroCountDown(endTime,refId,trans)
	end, 1, false, -1)
end

--function UIMirrorYell:OneCall(callTime)
--	if self._sendMsg then return end
--	if not self._rewardList then
--		self._sendMsg = false
--		return
--	end
--	callTime = callTime or 1
--	local callData = self._rewardList[self._subPage]
--	local refId = callData.refId
--	if self:IsUpperLimit() then return end
--	if self:IsHaveFreeNum(refId,1) then return end
--	local func = function()
--		self:IsOpenGetWay(self._onePayRefId,self._onePayNum,function()
--			self:SendMsg(refId,1)
--		end,callData.freeNum > 0)
--	end
--	local data = self._refData[refId]
--	local fixedReward = data.fixedReward
--	if self._onePayRefId == 102001 then
--		local wndId = 50101
--		local openFunc = function()
--			if callData.freeNum > 0 then
--				if func then
--					func()
--				end
--				return
--			end
--			local temp = string.split(fixedReward,"=")
--			local fixName,fixNum = gModelItem:GetNameByRefId(temp[2]),tonumber(temp[3]) * callTime
--			local str = fixNum..fixName
--			local payNum,name,payName = self._onePayNum,str ,ccLngText(data.typeName)
--
--			local serverData = self._rewardList[self._subPage]
--			local sid
--			if serverData then
--				sid = serverData.sid
--			end
--
--			if self._onePayRefId == 102001 then
--				--GF.OpenWnd("UIOrdinTip",{refId = wndId,func = func,para = {payNum,name,callTime,payName}})
--				gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func,para = {payNum,name,callTime,payName},sid = sid})
--			else
--				fixName = gModelItem:GetNameByRefId(self._onePayRefId)
--				--GF.OpenWnd("UIOrdinTip",{refId = wndId,func = func,para = {fixName,1,callTime,payName}})
--				gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func,para = {fixName,1,callTime,payName},sid = sid})
--			end
--		end
--		if string.isempty(fixedReward) then
--			func()
--		else
--			self:IsOpenGetWay(self._onePayRefId,self._onePayNum,function()
--				--gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)
--				--gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func,openFunc = openFunc})
--				self:OpenUIOrdinTip(wndId,func,openFunc)
--			end,callData.freeNum > 0)
--		end
--	else
--		self:IsOpenGetWay(self._onePayRefId,self._onePayNum,function()
--			func()
--		end,callData.freeNum > 0)
--	end
--end

function UIMirrorYell:ActOneCall(callTime)
	if self._sendMsg then return end
	if not self._rewardList then
		self._sendMsg = false
		return
	end

	if not self:IsActSelHero() then return end

	callTime = callTime or 1
	local refId = self._rewardList[self._subPage].refId
	if self:IsHaveFreeNum(refId,callTime) then return end
	local isActUpper,subNum = self:IsActUpperLimit(callTime,self._onePayRefId)
	if isActUpper then return end
	--if subNum then callTime = subNum end
	local func = function()
		self:IsOpenGetWay(self._onePayRefId,self._onePayNum,function()
			self:SendActMsg(refId,callTime)
		end)
	end
	if self._onePayRefId == 102001 then
		local wndId = 110008
		local openFunc = function()
			local showItemList = self._showItemList
			local showItemRefId = showItemList[1] and showItemList[1].refId
			if not showItemRefId then
				local data = self._refData[refId]
				local showItem = string.split(data.showItem)
				showItemRefId = tonumber(showItem[2])
			end
			local payItemRefId = 104001
			local payNum,payName,payTime = self._onePayNum,gModelItem:GetNameByRefId(payItemRefId),callTime
			--GF.OpenWnd("UIOrdinTip",{refId = wndId,func = func,para = {payNum,payName,payTime}})

			local serverData = self._rewardList[self._subPage]
			local sid
			if serverData then
				sid = serverData.sid
			end
			gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func,para = {payNum,payName,payTime},sid = sid,consume=payNum})
		end
		self:IsOpenGetWay(self._onePayRefId,self._onePayNum,function()
			--gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)
			--gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func,openFunc = openFunc,})
			self:OpenUIOrdinTip(wndId,func,openFunc)
		end)
	else
		self:IsOpenGetWay(self._onePayRefId,self._onePayNum,func)
	end
end

function UIMirrorYell:TabListItem(list,item, itemdata, itempos)
	local refId = itemdata.refId
	local SelTrans = self:FindWndTrans(item,"Sel")
	if SelTrans then
		self._TypeBtnList[refId] = SelTrans
	end
	local IconTrans = self:FindWndTrans(item,"Icon")
	if IconTrans then
		local ref = self._refData[refId]
		local icon = ref.icon
		self:SetWndEasyImage(IconTrans,icon)
	end
	local freeNum = itemdata.freeNum
	local FreeTxtTrans = self:FindWndTrans(item,"FreeTxt")
	if FreeTxtTrans then
		if freeNum > 0 then
			self:SetWndText(FreeTxtTrans,ccClientText(11610))
		else
			local refData = self._refData[refId]
			local freeExtractNum = refData.freeExtractNum
			if freeExtractNum == 0 then
				self:SetWndText(FreeTxtTrans,"")
			else
				if self._getServerTime then
					self:CreateServerTimer(itemdata.nextRefreshTimeOfFreeNum,itemdata.refId,FreeTxtTrans)
				else
					local freeExtractTime = refData.freeExtractTime
					self:CreateTimer(freeExtractTime,itemdata.index,FreeTxtTrans)
				end
			end
		end
	end
	local RedPointTrans = self:FindWndTrans(item,"redPoint")
	if RedPointTrans then
		local showRedPoint
		if refId == 1003 then
			showRedPoint = gModelCallHero:GetFriendCallStatus()
		else
			showRedPoint = freeNum and freeNum >= 1
		end
		CS.ShowObject(RedPointTrans,showRedPoint)
	end
end

function UIMirrorYell:IsOpenGetWay(refId,num,func,bool)
	local haveNum = gModelItem:GetNumByRefId(refId)
	if haveNum < num and not bool then
		gModelGeneral:OpenGetWayWnd({itemId = refId,srcWnd = self:GetWndName()})
	else
		if func then func() end
	end
end

function UIMirrorYell:SendCallReq(type)
    if self._sendMsg then
        return
    end
    if not self._rewardList then
        self._sendMsg = false
        return
    end

	local callData = self._rewardList[self._subPage]
	local refId = callData.refId
	local wndName = self:GetParentWndName()
	gModelCallHero:SendCallHeroReq(refId,type,wndName)
end
----------------------------- 活动倒计时 -----------------------------
function UIMirrorYell:StartShowFingerTimer()
	self:TimerStop(self._effTimerKey)
	self:TimerStart(self._effTimerKey,2,false,1)
end

function UIMirrorYell:RefreshTop(itemdata,itempos)
	local refId = itemdata.refId
	local index = itemdata.pageIndex
	if not index then
		index = itemdata.index
	end
	self._subPage = index
	self:ChangeTypeBtn(refId)
	self:SaveParentWndArg()
	local serverData = self._rewardList[index]
	local refData = self._refData[refId]

	local isActivity = refData.isActivity
	local tipsText = refData.tipsText
	CS.ShowObject(self.mActivityImg,isActivity ~= nil)

	local mySelect = serverData.mySelect
	local mySelectHero = serverData.mySelectHero
	local myDropNum = serverData.myDropNum
	local wishHero = serverData.wishHero or {}

	local callNum = serverData.callNum
	local dayExtractNumMax = refData.dayExtractNumMax
	self:TimerStop(self._timerKey)

	self:TimerStop(self._effTimerKey)
	self:DestroyWndEffectByKey(self._effKey)
	local str
	if isActivity then
		if mySelect and mySelect ~= 0 then
			local key = serverData.sid .. mySelectHero
			self:CreateHeroSpine(key,mySelectHero)

			local guard = wishHero[mySelect] or 0
			local last = guard - myDropNum
			if last <= 0 then last = 1 end
			str = string.replace(ccClientText(11638),last)
			CS.ShowObject(self.mHeroSp,true)
		else
			str = ccClientText(11646)

			self:StartShowFingerTimer()
			CS.ShowObject(self.mHeroSp,false)
		end

		local endTime = refData.endTime
		self._endTime = endTime
		self:StarCountDown()
		self:StartCountDownTimer()
	else
		CS.ShowObject(self.mHeroSp,false)

		local showStar = refData.showStar
		showStar = string.split(showStar,",")
		str = string.replace(ccClientText(11605), showStar[1], showStar[2])

		local chouStr = string.replace(ccClientText(11609), callNum, dayExtractNumMax)
		self:SetWndText(self.mChouquTxt,chouStr)
	end
	self:SetWndText(self.mDescTxt, str)
	CS.ShowObject(self.mLookBtn,isActivity == nil)
	CS.ShowObject(self.mActRewardBtn,isActivity ~= nil)

	local srot = refData.srot
	if srot == 1 then
		local allNum = serverData.allNum
		local fixedNumReward = refData.fixedNumReward
		fixedNumReward = string.split(fixedNumReward,",")
		local temp = tonumber(string.split(fixedNumReward[2],"=")[1])
		if allNum < temp then
			local lastNum = temp + 1 - allNum
			if lastNum > 1 then
				local zhaohuanStr = string.replace(ccClientText(11628),lastNum)
				self:SetWndText(self.mZhaohuanTxt,zhaohuanStr)
				CS.ShowObject(self.mZhaohuanBg,true)
			else
				CS.ShowObject(self.mZhaohuanBg,false)
			end
		else
			CS.ShowObject(self.mZhaohuanBg,false)
		end
	else
		CS.ShowObject(self.mZhaohuanBg,false)
	end
	self:SetWndEasyImage(self.mGaojiTxt,"callhero_txt_2_1")
	CS.ShowObject(self.mGaojiTxt,srot == 1)

	local backgroundIcon = refData.backgroundIcon
	if isActivity then
		self:SetWndEasyImage(self.mActivityBigImg,backgroundIcon)
	else
		self:SetWndEasyImage(self.mTypeIcon,backgroundIcon)
	end
	CS.ShowObject(self.mTypeIcon,isActivity == nil)
	CS.ShowObject(self.mActivityBigImg,isActivity ~= nil)

	local getBackground = refData.getBackground
	self:SetWndEasyImage(self.mBg,getBackground)

	local btn1,btn2 = refData.btn1,refData.btn2
	self:SetWndEasyImage(self.mOneCallBtn,btn1)
	self:SetWndEasyImage(self.mTenCallBtn,btn2)
	-- 重设按钮文字描边
	self:SetTextOutline(self.mOneCallBtnName, self.mOnePayNum, btn1)
	self:SetTextOutline(self.mTenCallBtnName, self.mTenPayNum, btn2)

	local oneExpend,tenExpend = refData.oneExpend, refData.tenExpend
	self:ChangePayBtn(oneExpend,self.mOnePayIcon,self.mOnePayNum,1)
	self:ChangePayBtn(tenExpend,self.mTenPayIcon,self.mTenPayNum,10,isActivity,tipsText,callNum,dayExtractNumMax)

	CS.ShowObject(self.mActivityCallImg,isActivity ~= nil)
	local showAddBtn = isActivity ~= nil
	if mySelect and showAddBtn then
		showAddBtn = mySelect == 0
	end
	CS.ShowObject(self.mActivityAddBtn,showAddBtn)

	local changeBtn = isActivity ~= nil
	if mySelect and changeBtn then
		changeBtn = mySelect ~= 0
	end
	CS.ShowObject(self.mActivityChangeBtn,changeBtn)

    -- 进度条计算
    local integralNeedItem = GameTable.SummonConfigRef["integralNeedItem"]
    integralNeedItem = string.split(integralNeedItem, "=")
    local needRefId, needNum = tonumber(integralNeedItem[2]), tonumber(integralNeedItem[3])
    local haveNum = gModelItem:GetNumByRefId(needRefId)
    local percentage = haveNum / needNum
    LxUiHelper.SetProgress(self.mJinDuTiao, percentage)
    str = string.format("%s/%s",haveNum,needNum)
    self:SetWndText(self.mJinDuTxt,str)
	local showBox = true
	local effectKey = "fx_baoxiang_paiweisai01"
	if haveNum >= needNum then
		showBox = false
		self:CreateWndEffect(self.mBoxEffect,effectKey,effectKey,100,false,false)
	else
		self:DestroyWndEffectByKey(effectKey)
	end
	CS.ShowObject(self.mBoxImage,showBox)
	CS.ShowObject(self.mBoxBtn,isActivity == nil)

--[[	local needVip = GameTable.SummonConfigRef["integralNeedVip"]
	local curVip = gModelPlayer:GetVipLevel()
	local show = false
	if curVip >= needVip then
		show = haveNum >= needNum
	end
	CS.ShowObject(self.mBoxRedPoint,show)]]

	local nameIcon = refData.nameIcon
	self:SetWndEasyImage(self.mTypeName,nameIcon,nil,true)

    local freeNum = serverData.freeNum
	local refId = serverData.refId
	local newYearList = {}

	local isNewYear,activitys,textList = gModelActivity:GetPrivilegeShow1(1)
	local freeStr = textList[1] or ""
	if isNewYear then
		for i, v in ipairs(activitys) do
			local activity = v
			local moreInfo = JSON.decode(activity.moreInfo)
			local refIds = moreInfo.privilegeShow1
			local refIdArr = string.split(refIds,"|")
			for i, v in ipairs(refIdArr) do
				local ref = gModelGeneral:GetSysEffectRef(tonumber(v))
				local effectValue = ref.effectValue
				local arr = string.split(effectValue,"=")
				local key = tonumber(arr[1])
				newYearList[key] = tonumber(arr[2])
			end
		end
	end
	local isShowBuff = newYearList[refId]
	CS.ShowObject(self.mBuffBg,isShowBuff)
	if isShowBuff then
		local buffStr = textList[3] or ""
		local tipsStr = textList[4] or ""
		self:SetWndText(self.mBuffText,buffStr)
		self:SetWndClick(self.mBuffBg,function ()
			GF.ShowMessage(tipsStr)
		end)
	end

	local oneCallBtnName,freeText = "",""
    if freeNum > 0 then
		oneCallBtnName = ccClientText(11610)
		if isNewYear then
			freeText = string.replace(freeStr,freeNum)
		elseif gModelBackflow:GetPrivilegesTypeListByType(9) then
			freeText = string.replace(ccClientText(12141),freeNum)
		end
    else
		oneCallBtnName = ccClientText(11607)
    end

	self:SetWndText(self.mOneCallBtnName,oneCallBtnName)
	self:SetWndText(self.mFreeText,freeText)

    self:SetWndText(self.mTenCallBtnName,ccClientText(11608))

    CS.ShowObject(self.mOnePayIcon,freeNum == 0)
    CS.ShowObject(self.mOnePayNum,freeNum == 0)

	local showItem = refData.showItem
	showItem = string.split(showItem,"|")
	local itemList = {}
	for i,v in ipairs(showItem) do
		v = string.split(v,"=")
		table.insert(itemList,{refId = tonumber(v[2])})
	end
	self._showItemList = itemList
	self:InitItemList(itemList)
end

--function UIMirrorYell:TenCall()
--	if self._sendMsg then return end
--	if not self._rewardList then
--		self._sendMsg = false
--		return
--	end
--
--	local refId = self._rewardList[self._subPage].refId
--	if self:IsUpperLimit() then return end
--
--	local func = function()
--		self:IsOpenGetWay(self._tenPayRefId,self._tenPayNum,function()
--			self:SendMsg(refId,10)
--		end)
--	end
--
--	local data = self._refData[refId]
--	local fixedReward = data.fixedReward
--	if self._tenPayRefId == 102001 then
--		local wndId = 50101
--		local openFunc = function()
--			local temp = string.split(fixedReward,"=")
--			local fixName,fixNum = gModelItem:GetNameByRefId(temp[2]),tonumber(temp[3]) * 10
--			local str = fixNum..fixName
--			local payNum,name,times,payName = self._tenPayNum,str ,10,ccLngText(data.typeName)
--
--
--			local serverData = self._rewardList[self._subPage]
--			local sid
--			if serverData then
--				sid = serverData.sid
--			end
--
--			if self._tenPayRefId == 102001 then
--				gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func,para = {payNum,name,times,payName},sid = sid})
--			else
--				fixName = gModelItem:GetNameByRefId(self._tenPayRefId)
--				gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func,para = {fixName,1,times,payName},sid = sid})
--			end
--		end
--		if string.isempty(fixedReward) then
--			func()
--		else
--			self:IsOpenGetWay(self._tenPayRefId,self._tenPayNum,function()
--				self:OpenUIOrdinTip(wndId,func,openFunc)
--			end)
--		end
--	else
--		self:IsOpenGetWay(self._tenPayRefId,self._tenPayNum,function()
--			func()
--		end)
--	end
--end

function UIMirrorYell:ActTenCall(callTime)
	if self._sendMsg then return end
	if not self._rewardList then
		self._sendMsg = false
		return
	end

	if not self:IsActSelHero() then return end

	callTime = callTime or 10
	local refId = self._rewardList[self._subPage].refId

	local isActUpper,subNum = self:IsActUpperLimit(callTime,self._tenPayRefId)
	if isActUpper then return end
	if subNum then callTime = subNum end
	local func = function()
		self:IsOpenGetWay(self._tenPayRefId,self._tenPayNum,function()
			self:SendActMsg(refId,callTime)
		end)
	end
	if self._tenPayRefId == 102001 then
		local wndId = 110008
		local openFunc = function()
			local showItemList = self._showItemList
			local showItemRefId = showItemList[1] and showItemList[1].refId
			if not showItemRefId then
				local data = self._refData[refId]
				local showItem = string.split(data.showItem)
				showItemRefId = tonumber(showItem[2])
			end

			local serverData = self._rewardList[self._subPage]
			local sid
			if serverData then
				sid = serverData.sid
			end

			local payItemId = 104001
			local payNum,payName,payTime = self._tenPayNum,gModelItem:GetNameByRefId(payItemId),callTime
			--GF.OpenWnd("UIOrdinTip",{refId = wndId,func = func,para = {payNum,payName,payTime}})
			gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func,para = {payNum,payName,payTime},sid = sid,consume=payNum})
		end
		self:IsOpenGetWay(self._tenPayRefId,self._tenPayNum,function()
			--gModelGeneral:ShowUIOrdinTip(wndId,func,openFunc)
			--gModelGeneral:OpenUIOrdinTips({refId = wndId,func = func,openFunc = openFunc})
			self:OpenUIOrdinTip(wndId,func,openFunc)
		end)
	else
		self:IsOpenGetWay(self._tenPayRefId,self._tenPayNum,func)
	end
end

function UIMirrorYell:IsFullHeroBag(times)
	return gModelGeneral:IsFullHeroBag(times,nil,nil,nil,nil,self:GetParentWndName())
end

function UIMirrorYell:RefreshCallRedPoint()
	local parentWnd = self:GetParentWnd()
	if not parentWnd then
		return
	end
	local parentWndName = parentWnd:GetWndName()
	self:RegisterRedPoint(parentWndName,true)
end

function UIMirrorYell:CreateTimer(freeExtractTime,index,trans)
	self:ClearTimer(nil,index)
	freeExtractTime = string.split(freeExtractTime,"=")
	if tonumber(freeExtractTime[1]) == 1 then
		self:SetDayTimer(tonumber(freeExtractTime[2]),index,trans)           -- 如果是定时已开启，则先走下，把字体贴上

		self._timerList[index] = LxTimer.LoopTimeCall(function()
			self:SetDayTimer(tonumber(freeExtractTime[2]),index,trans)
		end, 1, false, -1)
	else
		self:SetHourTimer(tonumber(freeExtractTime[2]),index,trans)         -- 如果是定时已开启，则先走下，把字体贴上

		self._timerList[index] = LxTimer.LoopTimeCall(function()
			self:SetHourTimer(tonumber(freeExtractTime[2]),index,trans)
		end, 1, false, -1)
	end
end

function UIMirrorYell:SendActMsg(refId,times,isFree)
	local isFull = self:IsFullHeroBag(times)
	if not isFull then
		self._sendMsg = true
		local refData = self._refData[refId]
		local isActivity = refData.isActivity
		if isActivity then
			local callType
			if isFree then
				callType = 3
			else
				local callPayRefId
				if times == 1 then
					callPayRefId = self._onePayRefId
				else
					callPayRefId = self._tenPayRefId
				end
				if callPayRefId == 102001 then
					callType = 1
				else
					callType = 2
				end
			end
			gModelActivity:OnActivityDropGiftReq(refData.sid,1,times,callType)
		end
	end
end

function UIMirrorYell:OnClickRank()
	GF.OpenWndBottom("UIRain",{rankType = ModelRank.RANK_TYPE_CALL})
	local callName = gModelCallHero:GetCallWndName()
	GF.CloseWndByName(callName)
end

function UIMirrorYell:IsActUpperLimit(callTime,callPayRefId)
	local serverData = self._rewardList[self._subPage]
	local refId = serverData.refId
	local refData = self._refData[refId]
	local subNum
	if serverData and refData and callPayRefId == 102001 then
		local endTime = refData.endTime
		if endTime - GetTimestamp() < 0 then
			GF.ShowMessage(ccClientText(14301))
			return true
		end
		local dayExtractNumMax = refData.dayExtractNumMax
		local callNum = serverData.callNum
		local lastNum = callNum + callTime
		if dayExtractNumMax < lastNum then
--[[			if dayExtractNumMax > callNum then
				GF.ShowMessage(ccClientText(11648))
			else
				GF.ShowMessage(ccClientText(11647))
			end]]
			if callNum < dayExtractNumMax and callTime == 10 then
				GF.ShowMessage(ccClientText(11648))
			else
				GF.ShowMessage(ccClientText(11647))
			end
			return true
		end
	end
	return false,subNum
end

function UIMirrorYell:SendMsg(refId,times, callPayRefId)
	local isFull = self:IsFullHeroBag(times)
	if not isFull then
		self._sendMsg = true
		gModelCallHero:OnCallHeroReq(refId,times, callPayRefId)
	end
end

function UIMirrorYell:InitText()
	local transList = {self.mLogBtn,self.mRecommendBtn,self.mRankBtn}
	local textList = {ccClientText(11672),ccClientText(11673),ccClientText(11674),}
	for i,v in ipairs(transList) do
		local t = self:FindWndTrans(v,"Text")
		if t then
			self:SetWndText(t,textList[i])
			self:InitTextLineWithLanguage(t, -40)
		end
	end

	--屏蔽欧皇榜
	if not gModelFunctionOpen:CheckIsShow(15500100) then
		CS.ShowObject(self.mRankBtn, false)
	end

end

function UIMirrorYell:OpenUIOrdinTip(wndId,func,openFunc)
	local isAlert = gModelGeneral:FindAlertId(wndId)
	if isAlert then
		if func then func() end
	else
		if openFunc then openFunc() end
	end
end

function UIMirrorYell:SetServerData()
	local rewardList = {}
	local serverData = gModelCallHero:GetCallHeroData()
	for k,v in pairs(serverData) do
		table.insert(rewardList,v)
	end
	local list = self:GetActivityCallData()
	for i,v in ipairs(list) do
		table.insert(rewardList,v)
	end
	table.sort(rewardList,function(data1,data2)
		local sort1,sort2 = self._refData[data1.refId].srot,self._refData[data2.refId].srot
		return sort1 < sort2
	end)
	self._rewardList = rewardList
end
function UIMirrorYell:OpentPrivileKey()
	--gModelBackflow:SetPrivileBtn(self.mBtnPrivile,9,self)

	-- local priviCom = self:GetPrivilegeCom()
	-- priviCom:Create(self.mBtnPrivile,9,self)
end

function UIMirrorYell:SetTextOutline(btnTxt, numTxt, btnImg)
	local numOutlines = {
		["callhero_btn_1"] = "OPPOSansRMixB_550b00_2",
		["callhero_btn_2"] = "OPPOSansRMixB_132262_2",
		["callhero_btn_3"] = "OPPOSansRMixB_531e80_2",
		["callhero_btn_4"] = "OPPOSansRMixB_442a00_2"
	}
	local nameOutlines = {
		["callhero_btn_1"] = "SourceHanSerifCN_550b00_2",
		["callhero_btn_2"] = "SourceHanSerifCN_132262_2",
		["callhero_btn_3"] = "SourceHanSerifCN_531e80_2",
		["callhero_btn_4"] = "SourceHanSerifCN_442a00_2"
	}

	local numMatName = numOutlines[btnImg]
	local nameMatName = nameOutlines[btnImg]
	if numMatName then
		self:SetWndTextMat(numTxt, numMatName)
	end
	if nameMatName then
		self:SetWndTextMat(btnTxt, nameMatName)
	end
end

function UIMirrorYell:ChangeTypeBtn(refId)
	for k,v in pairs(self._TypeBtnList) do
		CS.ShowObject(v,k == refId)
	end
end

function UIMirrorYell:CreateHeroSpine(prefabKey,heroRefId)
	local uiHeroObjList = self._uiHeroObjList
	if not uiHeroObjList then
		uiHeroObjList = {}
		self._uiHeroObjList = uiHeroObjList
	end
	local ref = gModelHero:GetHeroRef(heroRefId)
	if not ref then return end
	local effectRef = gModelHero:GetHeroShowRefByRefId(heroRefId)
	if not effectRef then return end
	local star = ref.initStar
	local prefabName = effectRef.prefabName

	local newUIHeroObj = uiHeroObjList[prefabKey]

	local oldUIHeroObj = self._curUIHeroObj
	if oldUIHeroObj and newUIHeroObj ~= oldUIHeroObj then
		oldUIHeroObj:ShowHero(false)
	end
	if not newUIHeroObj then
		newUIHeroObj = LUIHeroObject:New(self)

		uiHeroObjList[prefabKey] = newUIHeroObj

		self._curUIHeroObj = newUIHeroObj
		newUIHeroObj:Create(self.mHeroSp,prefabKey,prefabName)
		newUIHeroObj:SetScale(2)
		newUIHeroObj:SetClickFunc(function(...) self:OnClickHeroSpine(...) end)
		newUIHeroObj:SetHeroData(nil,heroRefId,star,nil,true)
		newUIHeroObj:ShowHero(true)
		newUIHeroObj:StartLoad()
	else
		self._curUIHeroObj = newUIHeroObj
		newUIHeroObj:SetHeroData(nil,heroRefId,star,nil,true)
		newUIHeroObj:ShowHero(true)
	end
end

function UIMirrorYell:SetWndShowByJump() --跳转需要特殊表现
	if self._functionId and self._functionId == 50000020 then
		CS.ShowObject(self.mItemList,false)
		CS.ShowObject(self.mTopRight,false)
		CS.ShowObject(self.mCallTypeBg,false)

	end
end

function UIMirrorYell:InitData()
	self._page = self:GetWndArg("page") or 1
	self._subPage = self:GetWndArg("subPage") or 1
	self._functionId = self:GetWndArg("functionId")
	self._sid = self:GetWndArg("sid")
	self._init = self._sid ~= nil

	self._getServerTime = ModelCallHero.USE_SERVERTIME == 1

	self._timerList = {}
	self._TypeBtnList = {}
	self._actRefIdList = {}
	self._heroList = {}
	self:GetRefData()
	self._spineList = {
		"TeshuzhaohuanUI",
		"PutongzhaohuanUI",
		"YouqingzhaohuanUI",
	}
	self._createList = {}
	self._sendMsg = false 			-- 是否发送事件
	self._timerKey = "countDown"
	self._effTimerKey = "effTimerKey"
	self._effKey = "guideFinger"
	self._timerPrivileKey = "_timerPrivileKey"
end

function UIMirrorYell:CallHeroCountDown(times,refId,trans)
	local curTime = GetTimestamp()
	local lastTime = times - curTime
	if lastTime <= 0 then
		self:ClearAllTime(true)
		return
	else
		local str = string.replace(ccClientText(11623),LUtil.FormatTimespanNumber(lastTime))
		if lastTime <= 0 then
			self:SetWndText(trans,"")
			self:ClearTimer(true,refId)
		else
			self:SetWndText(trans,str)
		end
	end
end


----------------------------- 定时器 -----------------------------
return UIMirrorYell


