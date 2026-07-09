---
--- Created by BY.
--- DateTime: 2023/10/6 14:56:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEvent5:LWnd
local UIHopeEvent5 = LxWndClass("UIHopeEvent5", LWnd)
local typeof = typeof
local CS = CS
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEvent5:UIHopeEvent5()
	---@type table<number, CommonIcon>
	self._commonIconClsTbl = {}
	self.isPlayEffect = false
	self._effKey = "effKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEvent5:OnWndClose()
	self:ClearCommonIconList(self._commonIconClsTbl)
	self._commonIconClsTbl = nil
	--FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEvent5:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEvent5:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitTxt()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
	self:InitToogleList()
	self:InitRewardList()
	self:RefreshDesc()
end

function UIHopeEvent5:InitRewardList()
	local list = self:GetRewardList()
	local uiRewardList = self._uiRewardList
	if uiRewardList then
		uiRewardList:RefreshList(list)
	else
		uiRewardList = self:GetUIScroll("uiRewardList")
		self._uiRewardList = uiRewardList
		uiRewardList:Create(self.mReweardList,list,function(...) self:OnDrawRewardCell(...) end)
	end
end

function UIHopeEvent5:GetToogleList()
	local list = {}
	--local moreInfo = gModelDreamTrip:GetPlatMoreInfoKeyByIndexAndEventId(self._eventId,nil,StructDreamTripEventInfo.QUEST_INFO)

	local extraData = self:GetExtraData()
	local moreInfo = gModelCommonDreamTrip:GetDreamTripEventIdMoreInfoKey({
		mapType = extraData.mapType,
		sid = extraData.sid,
		eventId = self._eventId,
		index = self._index,
		key = StructDreamTripEventInfo.QUEST_INFO,
	})
	if moreInfo then
		local curQuestRefId
		for i,v in ipairs(moreInfo) do
			if v.answer == "0" then
				curQuestRefId = v.questRefId
				break
			end
		end
		if curQuestRefId then
			local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(curQuestRefId)
			if textRef then
				local answerList = textRef.answerList
				for i,v in ipairs(answerList) do
					local answerData = string.split(v,".")
					table.insert(list,{
						text = v,
						selAns = answerData[1]
					})
				end

				local dec = ccLngText(textRef.dec)
				self:SetWndText(self.mDesText,dec)
			end
		end
	end

	--LogError("list = ")
	if LOG_INFO_ENABLED then
		printInfoNR(list)
	end
	return list
end

function UIHopeEvent5:CreateAnsAni(isRight,mySelAns,right,callFunc,isEnd)
	if self.isPlayEffect then return end
	local seqTween
	local yesnoTransList = self._yesnoTransList
	if not yesnoTransList then
		if callFunc then callFunc() end
		return
	end
	self.isPlayEffect = true
	self:TweenSeqKill(self._effKey)

	local myShowAnsTrans,rightTrans
	if not seqTween then
		seqTween = self:TweenSeqCreate(self._effKey,function(seq)
			local Ease = DG.Tweening.Ease.OutCubic
			local showTime = 0.5
			local intervalTime = showTime + 0.1
			local mySelInfo = yesnoTransList[mySelAns]
			myShowAnsTrans = isRight and mySelInfo.yesTrans or mySelInfo.noTrans
			local canvasGroup = myShowAnsTrans:GetComponent(typeofCanvasGroup)
			if canvasGroup then
				CS.ShowObject(myShowAnsTrans,true)
				local showTween = canvasGroup:DOFade(1,showTime):SetEase(Ease)
				seq:Append(showTween)
			end
			if not isRight then
				--seq:AppendInterval(intervalTime)
				local rightInfo = yesnoTransList[right]
				if rightInfo then
					rightTrans = rightInfo.yesTrans
					local canvasGroup1 = rightTrans:GetComponent(typeofCanvasGroup)
					if canvasGroup1 then
						CS.ShowObject(rightTrans,true)
						local showTween1 = canvasGroup1:DOFade(1,showTime):SetEase(Ease)
						seq:Join(showTween1)
					end
				end
				--seq:AppendInterval(0.1)
			end
			seq:InsertCallback(intervalTime,function()
				local textId = isRight and 20448 or 20449
				GF.ShowMessage(ccClientText(textId))
			end)
			if isEnd then
				seq:AppendInterval(1.5)
			end
			return seq
		end)
	end
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self.isPlayEffect = not self.isPlayEffect
		self:TweenSeqKill(self._effKey)
		CS.ShowObject(myShowAnsTrans,false)
		CS.ShowObject(rightTrans,false)
		if callFunc then callFunc() end
	end)
end

function UIHopeEvent5:InitCommand()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")

	local extraData = self:GetWndArg("extraData")
	self._extraData = extraData

	self._yesnoTransList = {}
	self._selAnswer = nil
end

function UIHopeEvent5:GetRewardList()
	local list = {}
	--local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(self._eventId)
	local eventId = self._eventId
	local index = self._index
	local extraData = self:GetExtraData()
	local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(eventId,index,extraData)
	if eventData then
		local reward = eventData.reward
		local len = #reward
		local allNum = 0
		local selNum = 1
		--local quest_info = gModelDreamTrip:GetPlatMoreInfoKeyByIndexAndEventId(eventId,index,StructDreamTripEventInfo.QUEST_INFO)
		local quest_info = gModelCommonDreamTrip:GetDreamTripEventIdMoreInfoKey({
			mapType = extraData.mapType,
			sid = extraData.sid,
			eventId = eventId,
			index = index,
			key = StructDreamTripEventInfo.QUEST_INFO,
		})
		for i,v in ipairs(quest_info or {}) do
			if v.answer ~= "0" then
				selNum = selNum + 1
			end
			allNum = allNum + 1
		end

		local str = string.replace(ccClientText(20460),selNum,allNum)
		self:SetWndText(self.mDTNumTxt,str)

		if len > 0 then
			list = reward
		end
		CS.ShowObject(self.mNotDTTxt,len <= 0)
	end
	return list
end

function UIHopeEvent5:OnDreamTripStartEventResp(pb)
	if tonumber(pb.eventId) ~= self._eventId then return end
	local func = self:GetCommonRewardFunc(pb)
	local isEnd = pb.state == StructDreamTripGrid.FINISH
	self:SendAnsMsg(func,isEnd)
end

function UIHopeEvent5:OnClickConfirm()
	if self.isPlayEffect then return end
	if self._selAnswer then
		--gModelDreamTrip:OnDreamTripStartEventReq(self._eventId,{self._selAnswer})

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
			mapType = extraData.mapType,
			sid = extraData.sid,
			argList = {tostring(self._selAnswer)},
		})
	else
		GF.ShowMessage(ccClientText(20464))
	end
end

function UIHopeEvent5:CloseWnd()
	if self.isPlayEffect then return end
	self:WndClose()
end

function UIHopeEvent5:SendAnsMsg(callFunc,isEnd)
	local oldSelAns = self._selAnswer
	--[[	local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(self._eventId)]]

	local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,self:GetExtraData())
	if eventData then
		local moreInfo = eventData.moreInfo or {}
		local questInfo = moreInfo[StructDreamTripEventInfo.QUEST_INFO] or {}
		local curQuestRefId,curAnswer
		for i,v in ipairs(questInfo) do
			local answer = v.answer
			if answer == "0" then break end
			curQuestRefId = v.questRefId
			curAnswer = answer
		end
		if not curQuestRefId then return end
		local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(curQuestRefId)
		if not textRef then return end
		local right = textRef.right
		local isRight = right == oldSelAns
		self:CreateAnsAni(isRight,oldSelAns,right,callFunc,isEnd)
	end
end

function UIHopeEvent5:InitToogleList()
	local list = self:GetToogleList()
	local uiToogleList = self._uiToogleList
	if uiToogleList then
		uiToogleList:RefreshData(list)
	else
		uiToogleList = self:GetUIScroll("uiToogleList")
		self._uiToogleList = uiToogleList
		uiToogleList:Create(self.mToogleList,list,function(...) self:OnDrawToogleCell(...) end)
	end
end

function UIHopeEvent5:RefreshDesc()
	--local eventData = gModelDreamTrip:GetPlatformByIndexAndEventId(self._eventId)

	local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,self:GetExtraData())
	if eventData then
		local eventRefId = eventData.eventRefId
		local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
		if eventRef then
			local name = ccLngText(eventRef.name)
			self:SetWndText(self.mTitleText,name)

			local prefab = eventRef.prefab
			if prefab then
				self:CreateWndSpine(self.mSpine,prefab,prefab,false,function(dpSpine)
					dpSpine:SetScale(eventRef.prefabSize or 1)
				end)
			end
		end
	end
end

function UIHopeEvent5:InitMessage()
	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb,ret) self:OnDreamTripStartEventResp(pb) end)

	--- 7.20新增活动梦境之旅
	--self:WndNetMsgRecv(LProtoIds.ActivityDreamTripStartEventResp,function(pb,ret) self:OnActivityDreamTripStartEventResp(pb) end)
end

function UIHopeEvent5:GetCommonRewardFunc(pb)
	local func = function()
		local endInfo = pb.endInfo
		if endInfo and endInfo.state == StructDreamTripGrid.FINISH then
			local extraData = self:GetExtraData()
			local endInfoServerData = gModelDreamTrip:GetEventInfoServerDataByPb(endInfo)
			if endInfoServerData then
				local reward = {}
				for i,v in ipairs(endInfoServerData.reward) do
					table.insert(reward,{
						itemId = v.itemId,
						itype = v.itemType,
						count = v.itemNum,
					})
				end
				gModelWndPop:TryOpenPopWnd("UIAward", {itemList = reward,callBackFunc = function()
					gModelCommonDreamTrip:CheckSendSpeedUpEvent(extraData)
					gModelCommonDreamTrip:OnDreamTripRobberInfoProcessor(extraData)
				end})
			end
			self:WndClose()
			return
		end
		self._selAnswer = nil
		self:InitToogleList()
		self:InitRewardList()
	end
	return func
end

function UIHopeEvent5:OnDrawToogleCell(list,item,itemdata,itempos)
	local OnImage = self:FindWndTrans(item,"OnImage")
	local Text = self:FindWndTrans(item,"Text")
	local YesImg = self:FindWndTrans(item,"YesImg")
	local NoImg = self:FindWndTrans(item,"NoImg")
	CS.ShowObject(YesImg,false)
	CS.ShowObject(NoImg,false)

	local text = itemdata.text
	local selAns = itemdata.selAns
	--LogError(itempos)
	if LOG_INFO_ENABLED then
		printInfoNR(itemdata)
	end

	local yesnoTransList = self._yesnoTransList
	if not yesnoTransList then
		yesnoTransList = {}
		self._yesnoTransList = yesnoTransList
	end
	yesnoTransList[selAns] = {
		yesTrans = YesImg,
		noTrans = NoImg,
	}

	self:SetWndText(Text,text)
	local show = selAns	 == self._selAnswer
	CS.ShowObject(OnImage,show)
	self:SetWndClick(item,function()
		self:SelAnsEvent(selAns)
	end)
end

function UIHopeEvent5:OnActivityDreamTripStartEventResp(pb)
	if tonumber(pb.eventId) ~= self._eventId then return end
	local func = self:GetCommonRewardFunc(pb)
	local isEnd = pb.state == StructDreamTripGrid.FINISH
	self:SendAnsMsg(func,isEnd)
end

function UIHopeEvent5:InitTxt()
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(10102))
	self:SetTextTile(self.mTextTitle,ccClientText(20442))
	self:SetWndText(self.mNotDTTxt,ccClientText(20461))
end

function UIHopeEvent5:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:CloseWnd() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBgImage, function(...) self:CloseWnd() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnConfirm, function(...) self:OnClickConfirm() end)
end

function UIHopeEvent5:GetExtraData()
	return self._extraData
end

function UIHopeEvent5:OnDrawRewardCell(list,item,itemdata,itempos)
	local CommonIconTrans = self:FindWndTrans(item,"CommonIcon")
	local instanceId = item:GetInstanceID()
	local itemType,itemId,itemNum = itemdata.itemType,itemdata.itemId,itemdata.itemNum
	if CommonIconTrans then
		local iconCls = self._commonIconClsTbl[instanceId]
		if not iconCls then
			iconCls = CommonIcon:New()
			self._commonIconClsTbl[instanceId] = iconCls
			iconCls:Create(CommonIconTrans)
		end
		iconCls:SetCommonReward(itemType, itemId, itemNum)
		iconCls:EnableShowNum(true)
		iconCls:DoApply()
		self:SetWndClick(CommonIconTrans, function()
			gModelGeneral:ShowCommonItemTipWnd(itemdata)
		end)
	end
end

function UIHopeEvent5:SelAnsEvent(selAns)
	if self.isPlayEffect then return end
	if self._selAnswer == selAns then return end
	self._selAnswer = selAns
	local uiToogleList = self._uiToogleList
	if uiToogleList then
		local uiList = uiToogleList:GetList()
		uiList:RefreshList()
	end
end
------------------------------------------------------------------
return UIHopeEvent5


