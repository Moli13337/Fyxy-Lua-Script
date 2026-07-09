---
--- Created by Administrator.
--- DateTime: 2025/6/9 20:53:14
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubBrandYell:LChildWnd
local UISubBrandYell = LxWndClass("UISubBrandYell", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubBrandYell:UISubBrandYell()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubBrandYell:OnWndClose()
	self:TimerStop(self._timeKey)
	self:TimerStop(self._oneTimeKey)
	if self._delayCallTimer then LxTimer.DelayTimeStop(self._delayCallTimer) end
	self._delayCallTimer = nil

	self:ShowRewardFunc()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubBrandYell:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubBrandYell:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:DoBoxImgAni()
	self:InitData()
	self:InitStatic()
	self:InitEvent()
	self:StartTimer()
	self:InitNeedAddItemList()
	self:RefreshJumpAniStatus()
	self:InitCallBtnTransInfo()
	self:RefreshCallBtn()
	self:InitGrandReward()
	self:OnUpdatePanel()
end

function UISubBrandYell:DoBoxImgAni()
	local trans = self.mBoxImg
	local curPos = trans.localPosition
	local x = curPos.x
	local z = curPos.z
	local curPosY = curPos.y
	local fromPos = Vector3(x,curPosY - 10,z)
	local toPos = Vector3(x,curPosY + 10,z)
	self:TweenSeq_MoveAndBack("move_back",trans,fromPos,toPos,1.5,nil,nil,nil,nil,true,false)
end

function UISubBrandYell:InitStatic()
	self:SetWndText(self.mTxtTile,ccClientText(47530))
	self:SetWndText(self.mTxtRwdTitle,ccClientText(47532))
	self:SetWndText(self.mJumpAniBgTxt,ccClientText(47535))
	self:SetTextTile(self.mBtnGift,ccClientText(47531))
	self:SetTextTile(self.mBtnHelp,ccClientText(41082))
	self:SetTextTile(self.mBtnShop,ccClientText(47536))
	self:SetWndButtonText(self.mBtnReward,ccClientText(47533))
	self:RegisterRedPointFunc(gModelRedPoint.BADGE_CALL_PREPARE,function(isShow)
		CS.ShowObject(self.mImgRed,isShow)
	end)
	self:RegisterRedPointFunc(gModelRedPoint.BADGE_GIFT_FREE,function(isShow)
		self:SetRed(self.mBtnGift,isShow)
	end)

	CS.ShowObject(self.mBtnGift,gModelFunctionOpen:CheckIsShow(37000004))
	if gLGameLanguage:IsRussiaVersion() then
		self:InitTextSizeWithLanguage(self.mTxtTime, -6)
	end
end

function UISubBrandYell:InitData()
	self._oneTimeKey = "oneTimeKey"
	self._timeKey = "timeKey"
	self._showRewardTimeKey = "showRewardTimeKey"
	self.endTime = gModelBadge.endTime
	self._jumpAniStatus = gModelBadge:GetBadgeCallJumpAniStats()
	self.rwdCondi = LxDataHelper.ParseItem_4(GameTable.BadgeConfigRef.badgeRewardCost)
	self:GetDayMidnight()
end
function UISubBrandYell:GetDayMidnight()
	local now = os.date("*t")
	-- 构造零点时间表
	local midnight = {
		year = now.year,
		month = now.month,
		day = now.day+1,
		hour = 0,
		min = 0,
		sec = 0
	}
	-- 转换为时间戳
	self.midnight_timestamp = os.time(midnight)
end


function UISubBrandYell:OnBadgeShowReward(status,rewardFunc)
	local bShowReward = status == 1
	self._rewardFunc = rewardFunc

	if bShowReward and self._jumpAniStatus then
		self:ShowRewardFunc()
		self._sendMsg = false
		return
	end

	CS.ShowObject(self.mGameCallView,bShowReward)
	CS.ShowObject(self.mEffRoot,false)
	self._sendMsg = bShowReward

	if not bShowReward then
		self._sendMsg = false
		return
	end
	local res = "fx_ui_shipinchoujiang"
	self:CreateWndEffect(self.mEffRoot,res,res,100,nil,nil,23,nil,nil,nil,nil,function()
		CS.ShowObject(self.mEffRoot,true)
		self:TimerStop(self._showRewardTimeKey)
		self:TimerStart(self._showRewardTimeKey,1.5,true,1)
	end)
end

function UISubBrandYell:ShowRewardFunc()
	local rewardFunc = self._rewardFunc
	self._rewardFunc = nil
	if rewardFunc then
		rewardFunc()
	end
	self._sendMsg = false
end



function UISubBrandYell:StartTimer()
	self:SetTime()
	self:CreateTimer(self._timeKey)
end
function UISubBrandYell:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	elseif key == self._oneTimeKey then
		self:SetCountDownTime(self._oneCallTimeTxtTrans)
	elseif key == self._showRewardTimeKey then
		self:ShowRewardFunc()
	end
end
function UISubBrandYell:SetCountDownTime(timeTxtTrans)
	local curTime = tonumber(GetTimestamp())
	local remainTime = self.midnight_timestamp - curTime
	local timeStr = ""
	if remainTime <= 0 then
		self:TimerStop(self._oneTimeKey)
	else
		timeStr = string.replace(ccClientText(11623), LUtil.FormatTimespanNumber(remainTime))
	end
	self:SetWndText(timeTxtTrans, timeStr)
end
function UISubBrandYell:SetTime()
	local time = GetTimestamp()
	local timespan = self.endTime - time
	local  timeStr = ""
	if(timespan < 0)then
		timeStr = ccClientText(14301)
		self:TimerStop(self._timeKey)
	else
		local timeF = ccClientText(47573)
		timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(timeF,timeStr)
	end
	self:SetWndText(self.mTxtTime,timeStr)
end
function UISubBrandYell:InitEvent()

	self:SetWndClick(self.mBtnSel,function()
		GF.OpenWnd("UIBrandPrepareRwd",{rwdCondi = self.rwdCondi})
	end)
	self:SetWndClick(self.mBtnHelp, function()
		-- GF.OpenWnd("WndHelpTips",{refId = 135})
		GF.OpenWnd("UIBrandYellRule")
	end)
	self:SetWndClick(self.mOneCallBtn, function()
		self:OnSendCallFunc(1)
	end)
	self:SetWndClick(self.mTenCallBtn, function()
		self:OnSendCallFunc(2)
	end)
	self:SetWndClick(self.mBtnGift, function()
		-- self:OnClickRecommendBtnFunc()
		if not gModelFunctionOpen:CheckIsOpened(37000004,true) then return end
		GF.OpenWnd("UIBrandGift")

	end)
	self:SetWndClick(self.mBtnShop, function()
		local functionId = 14600151
		if not gModelFunctionOpen:CheckIsOpened(functionId, true) then return end
		gModelFunctionOpen:Jump(functionId)
	end)
	self:SetWndClick(self.mBtnReward, function()
		if gModelBadge.selectIndex >0 then
			gModelBadge:BadgeReceiveSelectRewardReq()
		else
			GF.ShowMessage(ccClientText(47570))
		end
	end)
	self:SetWndClick(self.mJumpAniBtn, function()
		self:OnClickJumpAniFunc()
	end)

	self:WndEventRecv(EventNames.BADGE_CALL_UPDATE,function ()
		if self.endTime ~= gModelBadge.endTime then
			self.endTime = gModelBadge.endTime
			self:StartTimer()
		end
		self:OnUpdatePanel()
		self:RefreshCallBtn()
		self:InitGrandReward()
	end)
	self:WndEventRecv(EventNames.On_Item_Change,function ()
		self:InitNeedAddItemList()
	end)
	self:SetWndClick(self.mComIcon, function()
		local selRefId = gModelBadge.fixedReward[gModelBadge.selectIndex]
		local ref = GameTable.BadgeLuckRef[selRefId]
		local reward = LxDataHelper.ParseItem_4(ref.reward)
		gModelGeneral:ShowCommonItemTipWnd(reward,{forceNoShowBtn = true})
	end)
	self:SetWndClick(self.mEmpty, function()
		local fixedNum = GameTable.BadgeConfigRef.badgeFixedNum
		local selIndx = gModelBadge.selectIndex
		if selIndx>fixedNum then return end
		GF.OpenWnd("UIBrandPrepareRwd",{rwdCondi = self.rwdCondi})
	end)
	self:WndEventRecv(EventNames.ON_TIME_ZERO,function()
		self:GetDayMidnight()
	end)
	self:WndEventRecv(EventNames.BADGE_SHOW_REWARD,function(...) self:OnBadgeShowReward(...) end)


	local pbId = LProtoIds.BadgeDropReq
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(msgId, error, args ,errorStr)
		if pbId == msgId then
			self._sendMsg = false
		end
	end)

end
function UISubBrandYell:OnUpdatePanel()
	local hasNum = gModelItem:GetNumByRefId(self.rwdCondi.itemId)
	local condiNum = self.rwdCondi.itemNum
	self:SetWndText(self.mTxtSlider,string.replace(ccClientText(10249),hasNum,condiNum))
	local progress = hasNum/condiNum
	self.mSliderFill.fillAmount = progress
	CS.ShowObject(self.mBtnReward,progress>=1)
	self:SetRed(self.mBtnReward,progress>=1)
	local callNumStr = LUtil.FormatHurtNumSpriteText(gModelBadge.accumulate,false)
	self:SetWndText(self.mRandCallTxt,callNumStr)
	local dayMax = GameTable.BadgeConfigRef.badgeMaxNum
	self:SetTextTile(self.mTxtDayCall,string.replace(ccClientText(47534),gModelBadge.daySum,dayMax))
	local fixedNum = GameTable.BadgeConfigRef.badgeFixedNum
	local selIndx = gModelBadge.selectIndex
	CS.ShowObject(self.mEmpty, selIndx==0 or selIndx > fixedNum)
	CS.ShowObject(self.mComIcon, false)

	if selIndx > fixedNum or selIndx == 0 then
		local add = self:FindWndTrans(self.mEmpty,"Add")
		self:SetWndEasyImage(add,selIndx>fixedNum and GameTable.BadgeConfigRef.badgeRandomImg or "resonance_ui_add",nil,true)
	else
		CS.ShowObject(self.mComIcon, true)
		if selIndx>0 then
			local selRefId = gModelBadge.fixedReward[selIndx]
			local ref = GameTable.BadgeLuckRef[selRefId]
			local reward = LxDataHelper.ParseItem_4(ref.reward)
			local instanceId = self.mComIcon:GetInstanceID()
			local baseClass = self:GetCommonIcon(instanceId)
			baseClass:Create(self.mComIcon)
			-- baseClass:SetCommonReward(itype, selRefId)
			baseClass:SetCommonItemdata(reward)
			baseClass:DoApply()
		end
	end
end
function UISubBrandYell:UdpateBadgeGift()
	self:SetRed(self.mBtnGift,gModelBadge:HadShopGiftRed())
end

function UISubBrandYell:InitNeedAddItemList(list)
	local cost = LxDataHelper.ParseItem_4(GameTable.BadgeConfigRef.badgeExpend)
	list = {cost.itemId}
	local uiNeedAddItemList = self._uiNeedAddItemList
	if uiNeedAddItemList then
		uiNeedAddItemList:RefreshList(list)
	else
		uiNeedAddItemList = self:GetUIScroll("uiNeedAddItemList")
		self._uiNeedAddItemList = uiNeedAddItemList
		uiNeedAddItemList:Create(self.mNeedAddItemList, list, function(...)
			self:OnDrawNeedAddItemCell(...)
		end)
	end
end

function UISubBrandYell:OnDrawNeedAddItemCell(list, item, itemdata, itempos)
	local IconTrans = self:FindWndTrans(item, "IconDiv/Icon")
	local NumTrans = self:FindWndTrans(item, "Num")
	local AddBtnTrans = self:FindWndTrans(item, "BtnDiv/AddBtn")

	local itemId = itemdata
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(IconTrans, icon)

	local haveNum = gModelItem:GetNumStrByRefId(itemId)
	self:SetWndText(NumTrans, haveNum)

	self:SetWndClick(AddBtnTrans, function()
		gModelGeneral:OpenGetWayWnd({ itemId = itemId })
	end)
end

function UISubBrandYell:OnClickJumpAniFunc()
	self._jumpAniStatus = not self._jumpAniStatus
	gModelBadge:SetBadgeCallJumpAniStats(self._jumpAniStatus)
	self:RefreshJumpAniStatus()
end
function UISubBrandYell:RefreshJumpAniStatus()
	local status = self._jumpAniStatus
	CS.ShowObject(self.mJumpAniBgGou, status)
end
function UISubBrandYell:InitGrandReward()
	local itemList = gModelBadge.upPool
	local uiList = self:FindUIScroll("GrandReward")
	if uiList then
		uiList:RefreshList(itemList)
	else
		uiList = self:GetUIScroll("GrandReward")
		uiList:Create(self.mPriviReward, itemList, function(...)
			self:RewardListItem(...)
		end)
		uiList:EnableScroll(true, true)
	end
end

function UISubBrandYell:RewardListItem(list, item, itemdata, itempos)
	local AniRoot = self:FindWndTrans(item, "AniRoot")
	local item = self:FindWndTrans(AniRoot, "item")
	if itemdata then
		local ref = GameTable.BadgeLuckRef[itemdata]
		local reward = LxDataHelper.ParseItem_4(ref.reward)
		local instanceId = item:GetInstanceID()
		local baseClass = self:GetCommonIcon(instanceId)
		baseClass:Create(item)
		baseClass:SetCommonItemdata(reward)
		baseClass:DoApply()
		self:SetWndClick(AniRoot,function()
			gModelGeneral:ShowCommonItemTipWnd(reward,{forceNoShowBtn = true})
		end)

	end
end
function UISubBrandYell:InitCallBtnTransInfo()
	local callBtnTransInfo = {}
	local oneCallBtnTrans = self.mOneCallBtn
	local oneCallTransInfo = self:GetCallBtnTransInfo(oneCallBtnTrans)
	callBtnTransInfo.oneCallTransInfo = oneCallTransInfo
	self:CreateBtnEff(oneCallTransInfo.effRootTrans, "fx_ui_putongzhaohuan_04")

	local tenCallBtnTrans = self.mTenCallBtn
	local tenCallTransInfo = self:GetCallBtnTransInfo(tenCallBtnTrans)
	callBtnTransInfo.tenCallTransInfo = tenCallTransInfo
	self:CreateBtnEff(tenCallTransInfo.effRootTrans, "fx_ui_putongzhaohuan_05")

	self._oneCallTimeTxtTrans = oneCallTransInfo.timeTxtTrans
	self._tenCallTimeTxtTrans = tenCallTransInfo.timeTxtTrans

	self._callBtnTransInfo = callBtnTransInfo
end

function UISubBrandYell:GetCallBtnTransInfo(btnTrans)
	local EffRootTrans = self:FindWndTrans(btnTrans, "EffRoot")
	local btnNameTrans = self:FindWndTrans(btnTrans, "BtnName")
	local timeTxtTrans = self:FindWndTrans(btnTrans, "TimeTxt")
	local payDivTrans = self:FindWndTrans(btnTrans, "PayDiv")
	local iconImgTrans = self:FindWndTrans(payDivTrans, "IconImg")
	local numTxtTrans = self:FindWndTrans(payDivTrans, "NumTxt")
	local freeTxtTrans = self:FindWndTrans(btnTrans, "FreeTxt")
	local redPointTrans = self:FindWndTrans(btnTrans, "redPoint")
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
function UISubBrandYell:CreateTimer(key, time, loopCnt)
	time = time or 1
	loopCnt = loopCnt or -1
	self:TimerStop(key)
	self:TimerStart(key, time, false, loopCnt)
end
function UISubBrandYell:RefreshCallBtn()
	self:TimerStop(self._oneTimeKey)
	self:SetWndText(self._oneCallTimeTxtTrans, "")
	local onePayInfo,tenPayInfo = self:GetCallBtnInfo()
	local baseFreeNum = GameTable.BadgeConfigRef.badgeFreeRefNum or 0
	local freeNum = math.max(baseFreeNum - gModelBadge.free,0)
	local hasFree = freeNum>0
	local freeText
	if hasFree then
		freeText = string.replace(ccClientText(12141), freeNum)
	elseif baseFreeNum>0 then
		self:CreateTimer(self._oneTimeKey)
	end
	local oneCallName = hasFree and ccClientText(45116) or ccClientText(47537)
	local oneCallInfo = {
		btnName = oneCallName,
		freeText = freeText,
		isHaveFree = hasFree,
		itemId = onePayInfo and onePayInfo.itemId,
		itemNum = onePayInfo and onePayInfo.itemNum,
		payType = 1,
	}
	local oneCallTransInfo = self._callBtnTransInfo.oneCallTransInfo
	self:SetCallBtn(oneCallTransInfo, oneCallInfo)

	local tenCallName = ccClientText(47538)
	local tenCallTransInfo = self._callBtnTransInfo.tenCallTransInfo
	local tenCallInfo = {
		btnName = tenCallName,
		freeText = "",
		isHaveFree = false,
		itemId = tenPayInfo and tenPayInfo.itemId,
		itemNum = tenPayInfo and tenPayInfo.itemNum,
		payType = 10,
	}
	self:SetCallBtn(tenCallTransInfo, tenCallInfo)
end

function UISubBrandYell:SetCallBtn(transInfo, dataInfo)
	local btnNameTrans = transInfo.btnNameTrans
	local payDivTrans = transInfo.payDivTrans
	local iconImgTrans = transInfo.iconImgTrans
	local numTxtTrans = transInfo.numTxtTrans
	local freeTxtTrans = transInfo.freeTxtTrans
	local redPointTrans = transInfo.redPointTrans

	local btnName = dataInfo.btnName
	local freeText = dataInfo.freeText
	self:SetWndText(btnNameTrans, btnName)
	CS.ShowObject(btnNameTrans, true)
	self:SetWndText(freeTxtTrans, freeText)

	local itemId = dataInfo.itemId
	local icon = gModelItem:GetItemIconByRefId(itemId)
	self:SetWndEasyImage(iconImgTrans, icon)

	local itemNum = dataInfo.itemNum
	self:SetWndText(numTxtTrans, itemNum)

	local isHaveFree = dataInfo.isHaveFree
	CS.ShowObject(freeTxtTrans, isHaveFree)
	CS.ShowObject(redPointTrans, isHaveFree)
	CS.ShowObject(payDivTrans, not isHaveFree)
end
--- 获取召唤按钮显示道具信息
function UISubBrandYell:GetCallBtnInfo()
	local ref = GameTable.BadgeConfigRef
	if not ref then
		return
	end
	local oneExpend = LUtil.ConvertCommonItemStrToList(ref.badgeExpend, "|")
	local tenExpend = LUtil.ConvertCommonItemStrToList(ref.badgeMoreExpend, "|")
	local onePayInfo = self:GetUsePayInfo(oneExpend)
	local tenPayInfo = self:GetUsePayInfo(tenExpend)
	return onePayInfo, tenPayInfo
end

--- 筛选召唤按钮显示道具信息
function UISubBrandYell:GetUsePayInfo(payList)
	payList = payList or {}
	local len = #payList
	local usePayInfo
	if len == 1 then
		usePayInfo = payList[len]
	else
		local itemId, itemNum, haveNum
		for i, v in ipairs(payList) do
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

function UISubBrandYell:OnSendCallFunc(callType)
	if self._sendMsg then return end

	local sendMsgFunc = function()
		self._sendMsg = true
		gModelBadge:BadgeDropReq(callType)
	end

	local isEnough = self:CheckCallIsEnough( callType)
	if isEnough then
		local status = self._jumpAniStatus
		if status then
			sendMsgFunc()
		else
			self:CallEffect(sendMsgFunc)
		end
	end
end

function UISubBrandYell:CheckCallIsEnough(callType)
	local callTimes = callType == 1 and 1 or 10
	if callType == 1 then  --免费单抽
		local free = GameTable.BadgeConfigRef.badgeFreeRefNum
		if free - gModelBadge.free > 0 then
			return true
		end
	end
	local config = GameTable.BadgeConfigRef
	local dayExtractNumMax = config.badgeMaxNum
	if gModelBadge.daySum + callTimes > dayExtractNumMax then
		GF.ShowMessage(ccClientText(47577))
		return false
	end

	local expend = nil
	if callType == 1 then
		expend = config.badgeExpend
	elseif callType == 2 then
		expend = config.badgeMoreExpend
	end

	local costItem = nil
	local isEnough = false
	local expendItems = LxDataHelper.ParseItem_3List(expend,'|')
	if #expendItems == 1 then
		costItem = expendItems[1]
	elseif #expendItems == 2 then
		local firstItem = expendItems[1]
		if gModelGeneral:CheckItemListEnoughStatus({firstItem}) then
			isEnough = true
			costItem = firstItem
		else
			costItem = expendItems[2]
		end
	end

	if isEnough then
		return true
	end

	return gModelGeneral:CheckItemListEnough({costItem},self:GetWndName())
end

function UISubBrandYell:CallEffect(callBack)
	self._delayCallTimer = LxTimer.DelayTimeCall(function ()
		LxTimer.DelayTimeStop(self._delayCallTimer)
		self._delayCallTimer = nil
		callBack()
	end, 0.5)
end

function UISubBrandYell:CreateBtnEff(trans, effName)
	local key = trans:GetInstanceID()
	self:CreateWndEffect(trans, effName, key, 100, false, false)
end
------------------------------------------------------------------
return UISubBrandYell