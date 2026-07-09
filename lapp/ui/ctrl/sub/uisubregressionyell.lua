---
--- Created by Administrator.
--- DateTime: 2024/8/7 22:33:19
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubRegressionYell:LChildWnd
local UISubRegressionYell = LxWndClass("UISubRegressionYell", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubRegressionYell:UISubRegressionYell()
	self._jumpAniStatus = gModelRegression:GetRegressionCallJumpAniStats()
	self._oneTimerKey = "RegressionCallKey"
	self._callRefId = ModelCallHero.CALL_TYPE_REGRESSION
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubRegressionYell:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubRegressionYell:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubRegressionYell:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	self:OnAddClick()
	self:OnUpdatePanel()
	self:InitNeedAddItemList()
	self:InitCallBtnTransInfo()
	self:RefreshJumpAniStatus()
	self:InitSpine()
end
function UISubRegressionYell:RefreshJumpAniStatus()
	local status = self._jumpAniStatus
	CS.ShowObject(self.mJumpAniBgGou,status)
end

function UISubRegressionYell:RefreshCallTypeView()
	self:TimerStop(self._oneTimerKey)

	local ref = self:GetCallTypeRef()
	if not ref then return end
	local serverData = self._callHeroServerData[self._callRefId]
	local callNum = serverData and serverData.callNum or 0
	local callNum2 = serverData and serverData.callNum2 or 0
	local dayLimitNumStr = string.replace(ccClientText(45105), callNum, ref.dayExtractNumMax)
	self:SetWndText(self.mTxtCallCount,dayLimitNumStr)
	local str = gModelEquip:GetLevelDesStr(serverData and serverData.guaranteesNum or 0)
	self:SetWndText(self.mTxtCallNum,str)
	self:SetWndText(self.mLeftCallTimes,str)
	local totalNum = GameTable.ReturnBackConfigRef.diamondTimes
	self:SetWndText(self.mTipsText, string.replace(ccClientText(45122),math.max(totalNum-callNum2,0)))

	if self._isEnus then
		self:SetAnchorPos(self.mTipsText,Vector2.New(180,-13))
	end

	self:SetWndEasyImage(self.mBg,ref.bg)
	self:RefreshCallBtn()
end

function UISubRegressionYell:OnUpdatePanel()
	-- self:SetWndText(self.mTxtCallNum,0)
	-- self:SetWndText(self.mTxtCallCount,string.replace(ccClientText(45105),0,10))

	-- local curActivityData = {}
	-- local dropNumToday = curActivityData.dropNumToday
	-- local callMaxNum = curActivityData.callMaxNum
	-- local callMaxStr = string.replace(curActivityData.callLimitTips,dropNumToday,callMaxNum)
	-- self:SetTextTile(self.mTxtCallCount,callMaxStr)
end
function UISubRegressionYell:InitCallBtnTransInfo()
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
end
function UISubRegressionYell:OnTimer(key)
	if key == self._oneTimerKey then
		local serverData = self._callHeroServerData[self._callRefId]
		if not serverData then
			self:TimerStop(self._oneTimerKey)
			return
		end
		local serverTime = serverData.nextRefreshTimeOfFreeNum / 1000

		local curTime = tonumber(GetTimestamp())
		local remainTime = serverTime - curTime
		local timeStr = ""
		if remainTime <= 0 then
			self:TimerStop(self._oneTimerKey)
		else
			timeStr = string.replace(ccClientText(11623),LUtil.FormatTimespanNumber(remainTime))
		end
		self:SetWndText(self._oneCallTimeTxtTrans,timeStr)
	end
end

function UISubRegressionYell:InitSpine()
	local spineName = ModelCallHero.CALL_SPINE_NAME
	self:CreateWndSpine(self.mSpineBgRoot,spineName,spineName,false,function(dpSpine)
		dpSpine:PlayAnimationSolid("idle",true)
	end)
	if PRODUCT_G_VER ~= 0 then
		CS.ShowObject(self.mSpineBgRoot , false)
	end
end

function UISubRegressionYell:GetCallBtnTransInfo(btnTrans)
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
function UISubRegressionYell:CreateBtnEff(trans,effName)
	local key = trans:GetInstanceID()
	self:CreateWndEffect(trans,effName,key,100,false,false)
end

function UISubRegressionYell:InitNeedAddItemList()
	local items = GameTable.SummonRef[gModelCallHero.CALL_TYPE_REGRESSION].showItem
	local list = LxDataHelper.ParseItem(items,"|")
	local uiNeedAddItemList = self._uiNeedAddItemList
	if uiNeedAddItemList then
		uiNeedAddItemList:RefreshList(list)
	else
		uiNeedAddItemList = self:GetUIScroll("uiNeedAddItemList")
		self._uiNeedAddItemList = uiNeedAddItemList
		uiNeedAddItemList:Create(self.mNeedAddItemList,list,function(...) self:OnDrawNeedAddItemCell(...) end)
	end
end

function UISubRegressionYell:OnDrawNeedAddItemCell(list,item,itemdata,itempos)
	local IconTrans = self:FindWndTrans(item,"IconDiv/Icon")
	local NumTrans = self:FindWndTrans(item,"Num")
	local AddBtnTrans = self:FindWndTrans(item,"BtnDiv/AddBtn")

	local itemId = itemdata.itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(IconTrans,icon)

	local haveNum = gModelItem:GetNumStrByRefId(itemId)
	self:SetWndText(NumTrans,haveNum)

	self:SetWndClick(AddBtnTrans,function()
		gModelGeneral:OpenGetWayWnd({itemId = itemId})
	end)
end
--- 获取召唤按钮显示道具信息
function UISubRegressionYell:GetCallBtnInfo()
	local ref = self:GetCallTypeRef()
	if not ref then return end
	local oneExpend = LUtil.ConvertCommonItemStrToList(ref.oneExpend,"|")
	local tenExpend = LUtil.ConvertCommonItemStrToList(ref.tenExpend,"|")
	local onePayInfo = self:GetUsePayInfo(oneExpend)
	local tenPayInfo = self:GetUsePayInfo(tenExpend)
	return onePayInfo,tenPayInfo
end

function UISubRegressionYell:RefreshCallBtn()
	local callBtnTransInfo = self._callBtnTransInfo
	local serverData = self._callHeroServerData[self._callRefId]
	local onePayInfo,tenPayInfo = self:GetCallBtnInfo()
	local freeNum = serverData and serverData.freeNum or 0
	local isHaveFree = freeNum > 0
	self:TimerStop(self._oneTimerKey)
	self:SetWndText(self._oneCallTimeTxtTrans,"")
	local oneCallTransInfo = callBtnTransInfo.oneCallTransInfo
	local freeText = ""
	local isNewYear,activitys,textList = gModelActivity:GetPrivilegeShow1(1)
	if isHaveFree then
		if isNewYear then
			local freeStr = textList[1] or ""
			freeText = string.replace(freeStr,freeNum)
		elseif gModelBackflow:GetPrivilegesTypeListByType(9) then
			freeText = string.replace(ccClientText(12141),freeNum)
		end
		freeText = string.replace(ccClientText(12141),freeNum)
	else
		self:CreateTimer(self._oneTimerKey)
	end

	local newYearList = {}
	if isNewYear then
		for i, v in ipairs(activitys) do
			local activity = v
			local moreInfo = JSON.decode(activity.moreInfo)
			local refIds = moreInfo.privilegeShow1
			local refIdArr = string.split(refIds,"|")
			for idx, val in ipairs(refIdArr) do
				local ref = gModelGeneral:GetSysEffectRef(tonumber(val))
				local effectValue = ref.effectValue
				local arr = string.split(effectValue,"=")
				local key = tonumber(arr[1])
				newYearList[key] = tonumber(arr[2])
			end
		end
	end
	local refId = serverData and serverData.refId or self._callRefId
	local isShowBuff = refId and newYearList[refId]
	CS.ShowObject(self.mBuffBg,isShowBuff)
	if isShowBuff then
		local buffStr = textList[3] or ""
		local tipsStr = textList[4] or ""
		self:SetWndText(self.mBuffText,buffStr)
		self:SetWndClick(self.mBuffBg,function ()
			GF.ShowMessage(tipsStr)
		end)
	end

	local oneCallName = gModelCallHero:GetCallBtnName(refId,ModelCallHero.LEFT,isHaveFree)
	local oneCallInfo = {
		btnName = oneCallName,
		freeText = freeText,
		isHaveFree = isHaveFree,
		itemId = onePayInfo and onePayInfo.itemId,
		itemNum = onePayInfo and onePayInfo.itemNum,
		payType = 1,
	}
	self:SetCallBtn(oneCallTransInfo,oneCallInfo)


	local tenCallName = gModelCallHero:GetCallBtnName(refId,ModelCallHero.RIGHT)
	local tenCallTransInfo = callBtnTransInfo.tenCallTransInfo
	local tenCallInfo = {
		btnName = tenCallName,
		freeText = "",
		isHaveFree = false,
		itemId = tenPayInfo and tenPayInfo.itemId,
		itemNum = tenPayInfo and tenPayInfo.itemNum,
		payType = 10,
	}
	self:SetCallBtn(tenCallTransInfo,tenCallInfo)
end

--- 筛选召唤按钮显示道具信息
function UISubRegressionYell:GetUsePayInfo(payList)
	payList = payList or {}
	local len = #payList
	local usePayInfo
	if len == 1 then
		usePayInfo = payList[len]
	else
		local itemId,itemNum,haveNum
		for i,v in ipairs(payList) do
			itemId = v.itemId
			itemNum = v.itemNum
			haveNum = gModelItem:GetNumByRefId(itemId)
			if i == 1 and haveNum >= itemNum then
				usePayInfo = v
				break
			end
		end
		if not usePayInfo then
			usePayInfo = payList[len]
		end
	end
	return usePayInfo
end
function UISubRegressionYell:OnClickDetailsBtnFunc()
	GF.OpenWnd("UIYellHRew",{callRefId = self._callRefId,viewType = 2})
end

function UISubRegressionYell:OnSendCallFunc(callType)
	local sendMsgFunc = function()
		if self._sendMsg then return end
		local sendFunc = function()
			self._sendMsg = true
		end
		local wndName = self:GetParentWndName()
		gModelCallHero:SendCallHeroReq(self._callRefId,callType,wndName,true,sendFunc)
	end

	local isEnough = gModelCallHero:CheckCallIsEnough(self._callRefId,callType,self:GetParentWndName())
	if isEnough == 1 then
		--- 背包满了
		return
	end
	if isEnough then
		local status = self._jumpAniStatus
		if status then
			sendMsgFunc()
		else
			if ModelCallHero.MIRRORCALLHERO_STATUS == 1 then
				sendMsgFunc()
			elseif PRODUCT_G_VER ~= 0 then --提审屏蔽
				sendMsgFunc()
			else

				local callNum = callType == 1 and 1 or 10
				GF.OpenWnd("UIMirrorYellSagaSow",{
					viewType = 1,
					callRefId = self._callRefId,
					sendMsgFunc = sendMsgFunc,
					callNum = callNum
				})
			end
		end
	else
		sendMsgFunc()
	end

end

function UISubRegressionYell:OnClickLogBtnFunc()
	local callType = GameTable.SummonRef[self._callRefId].extractType
	GF.OpenWnd("UIYellLog",{callType = callType})
end

function UISubRegressionYell:InitCallServerData()
	self._callHeroServerData = gModelCallHero:GetCallHeroData()
end

function UISubRegressionYell:OnAddClick()
	self:SetTextTile(self.mLogBtn,ccClientText(45106))
	self:SetTextTile(self.mDetailsBtn,ccClientText(45107))
	self:SetWndClick(self.mLogBtn,function()
		self:OnClickLogBtnFunc()
	end)
	self:SetWndClick(self.mBtnClose,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mDetailsBtn,function()
		self:OnClickDetailsBtnFunc()
	end)
	self:SetWndClick(self.mBtnGet,function()

	end)
	self:SetWndText(self.mJumpAniBgTxt,ccClientText(18321))
	self:SetWndClick(self.mJumpAniBtn,function() self:OnClickJumpAniFunc() end)
	self:SetWndClick(self.mJumpAniBg,function() self:OnClickJumpAniFunc() end)
	self:SetWndClick(self.mOneCallBtn,function() self:OnSendCallFunc(1) end)
	self:SetWndClick(self.mTenCallBtn,function() self:OnSendCallFunc(2) end)

	self:WndNetMsgRecv(LProtoIds.MagicResp, function()
		self:RefreshServerData()
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function() self:InitNeedAddItemList() end)
	gModelCallHero:OnMagicReq(4)
end
function UISubRegressionYell:SetCallBtn(transInfo,dataInfo)
	local btnNameTrans = transInfo.btnNameTrans
	local payDivTrans = transInfo.payDivTrans
	local iconImgTrans = transInfo.iconImgTrans
	local numTxtTrans = transInfo.numTxtTrans
	local freeTxtTrans = transInfo.freeTxtTrans
	local redPointTrans = transInfo.redPointTrans

	local btnName = dataInfo.btnName
	local freeText = dataInfo.freeText
	self:SetWndText(btnNameTrans,btnName)
	CS.ShowObject(btnNameTrans,true)
	self:SetWndText(freeTxtTrans,freeText)

	local itemId = dataInfo.itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(iconImgTrans,icon)

	local itemNum = dataInfo.itemNum
	self:SetWndText(numTxtTrans,itemNum)

	local isHaveFree = dataInfo.isHaveFree
	CS.ShowObject(freeTxtTrans,isHaveFree)
	CS.ShowObject(redPointTrans,isHaveFree)
	CS.ShowObject(payDivTrans,not isHaveFree)
end

function UISubRegressionYell:OnClickJumpAniFunc()
	self._jumpAniStatus = not self._jumpAniStatus
	gModelRegression:SetRegressionCallJumpAniStats(self._jumpAniStatus)
	self:RefreshJumpAniStatus()
end

function UISubRegressionYell:RefreshServerData()
	self._sendMsg = false
	self:InitCallServerData()
	self:RefreshCallTypeView()
end
function UISubRegressionYell:GetCallTypeRef()
	local callRefId = self._callRefId
	return gModelCallHero:GetCallRefByRefId(callRefId)
end
function UISubRegressionYell:CreateTimer(key,time,loopCnt)
	time = time or 1
	loopCnt = loopCnt or -1
	self:TimerStop(key)
	self:TimerStart(key,time,false,loopCnt)
end


------------------------------------------------------------------
return UISubRegressionYell