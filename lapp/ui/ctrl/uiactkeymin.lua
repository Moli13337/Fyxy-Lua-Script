---
--- Created by BY.
--- DateTime: 2023/10/28 18:09:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActKeyMin:LWnd
local UIActKeyMin = LxWndClass("UIActKeyMin", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActKeyMin:UIActKeyMin()
	self._uiCommonList = {}
	self._timeKey = "UIActKeyMin"
	self._closeWndTime = "_closeWndTime"
	self._timeMa = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActKeyMin:OnWndClose()
	self:TimerStop(self._timeKey)
	self:ClearCommonIconList(self._uiCommonList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActKeyMin:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActKeyMin:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIActKeyMin:OnActivityConfigData()
	local sid = self._sid
	local activityData = gModelActivity:GetWebActivityDataById(sid)
	local data = activityData.config

	local answerBg,answerTitle,seasonName,endRewardTxt,endReward,answerSuccReward,questionPassReward,endRewardIcon
	= data.answerBg,data.answerTitle,data.seasonName,data.endRewardTxt,data.endReward,data.answerSuccReward,data.questionPassReward,data.endRewardIcon
	self._rankId,self._rankRewardId = data.answerRank,data.answerRankReward
	self._endRewardTxt = endRewardTxt
	if LxUiHelper.IsImgPathValid(answerBg) then
		self:SetWndEasyImage(self.mMask,answerBg)
	end
	if LxUiHelper.IsImgPathValid(answerTitle) then
		local image = self.mTitleImg
		CS.ShowObject(image,true)
		self:SetWndEasyImage(image,answerTitle,nil,true)
	end
	if not string.isempty(seasonName) then
		self:SetWndText(self.mNameText,seasonName)
	end
	if not string.isempty(endRewardTxt) then
		self:SetWndText(self.mDesText,endRewardTxt)
	end
	if not string.isempty(endReward) then
		local reward = LxDataHelper.ParseItem_3(endReward)
		if LxUiHelper.IsImgPathValid(endRewardIcon) then
			self:SetWndEasyImage(self.mRwardIcon,endRewardIcon, function()
				CS.ShowObject(self.mRwardIcon, true)
			end,true, true)
		end
		self:SetWndClick(self.mRwardIcon,function ()
			gModelGeneral:ShowCommonItemTipWnd(reward)
		end)
	end

	if not string.isempty(answerSuccReward) then
		CS.ShowObject(self.mTipsText,true)
		self:SetWndText(self.mTipsText,answerSuccReward)
	end

	if not string.isempty(questionPassReward) then
		local list = LxDataHelper.ParseItem_3List(questionPassReward)
		local _uiCellList = self:GetUIScroll("mCellSuper_UIActKeyMin")
		_uiCellList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end)
	end
	gModelActivity:OnActivityPageReq(sid)
end

function UIActKeyMin:InitCommand()
	local sid = self:GetWndArg("sid")
	self._page = self:GetWndArg("page") or 0 --支持跳转
	local _subPage = self:GetWndArg("subPage")
	if _subPage then
		sid = gModelActivity:GetSidByUniqueJump(_subPage)
	end
	local modelId = gModelActivity:GetActivityModeIdBySid(sid)
	self._sid = sid
	self._modelId = modelId
	gModelActivity:ReqActivityConfigData(sid)
	self:SetWndText(self.mRwardText,ccClientText(26412))
	self:SetWndButtonText(self.mBtnMatching,ccClientText(26415))
	self:SetWndButtonText(self.mBtnCancel,ccClientText(26416))
	self:SetWndText(self.mRankText,ccClientText(26417))
end
function UIActKeyMin:SetTime()
	local time = self._timeMa or 0
	self._timeMa = time + 1
	self:SetWndText(self.mMatchingText,string.replace(ccClientText(26414),time))
end

function UIActKeyMin:RefreshData()
	local sid = self._sid

	local activityDataS = gModelActivity:GetActivityBySid(sid)
	local dataS = JSON.decode(activityDataS.moreInfo)
	local join_answer_room_count = dataS.join_answer_room_count or 0		--今天已成功匹配次数
	local matching_member = dataS.matching_member or 0						-- 1=匹配中
	local accomplish_count = dataS.accomplish_count or 0					-- 答题通关次数
	local answer_room_finally_award = dataS.answer_room_finally_award or 0	-- 答题终极奖励是否领取 1=已领取

	local activityDataW = gModelActivity:GetWebActivityDataById(sid)
	local dataW = activityDataW.config
	local playNum,endRewardCon
	= dataW.playNum,dataW.endRewardCon

	local isMatching = matching_member == 1									--是否在匹配中
	local answerIsRoom = gModelActivity:GetAnswerIsRoom(sid)
	self._residueNum = playNum - join_answer_room_count

	local _timeKey = self._timeKey
	if isMatching and not self:IsTimerExist(_timeKey) then
		self:TimerStart(_timeKey,1,false,-1)
		self:SetTime()
	else
		self._timeMa = 0
		self:TimerStop(_timeKey)
	end

	local isMatchingOrRoom = isMatching or answerIsRoom

	CS.ShowObject(self.mNumText,not isMatchingOrRoom)
	CS.ShowObject(self.mMatchingText,isMatchingOrRoom)
	CS.ShowObject(self.mBtnMatching,not isMatchingOrRoom)
	CS.ShowObject(self.mBtnCancel,isMatchingOrRoom)
	CS.ShowObject(self.mBtnRank,not isMatchingOrRoom)
	CS.ShowObject(self.mBtnClose,not isMatching)


    local btnGet = self._isUSARegion and self.mBtnGetEn or self.mBtnGet
	CS.ShowObject(btnGet,true)
	self:SetWndButtonGray(btnGet,answer_room_finally_award == 1 or accomplish_count < endRewardCon)
	self:SetWndButtonText(btnGet,answer_room_finally_award == 1 and ccClientText(21713) or ccClientText(22706))
	self:SetWndClick(btnGet, function(...)
		if accomplish_count >= endRewardCon  and answer_room_finally_award == 0 then
			self:OnClickGet()
		elseif answer_room_finally_award == 1 then

		else
			GF.ShowMessage(self._endRewardTxt)
		end
	end)

	self.mBarValue.maxValue = endRewardCon
	self.mBarValue.value = accomplish_count <= endRewardCon and accomplish_count or endRewardCon
	self:SetWndText(self.mValueText,accomplish_count.."/"..endRewardCon)
	self:SetWndText(self.mNumText,string.replace(ccClientText(26413),self._residueNum,playNum))

end
function UIActKeyMin:OnClickGet()
	local sid = self._sid
	local activityDataS = gModelActivity:GetActivityBySid(sid)
	local dataS = JSON.decode(activityDataS.moreInfo)
	local accomplish_count = dataS.accomplish_count or 0					-- 答题通关次数
	local answer_room_finally_award = dataS.answer_room_finally_award or 0	-- 答题终极奖励是否领取 1=已领取

	local activityDataW = gModelActivity:GetWebActivityDataById(sid)
	local dataW = activityDataW.config
	local endRewardCon = dataW.endRewardCon

	local isGet = accomplish_count >= endRewardCon
	local isOGet = answer_room_finally_award == 1
	if not isGet or isOGet then
		return
	end
	gModelActivity:OnActivitySpecialOpReq(sid,0,0,nil,nil,ModelActivity.MAGIC_ACADEMY_ANSWER_REWARD)
end
function UIActKeyMin:OnClickCancel()
	gModelActivity:OnActivitySpecialOpReq(self._sid,0,0,nil,"1",ModelActivity.MAGIC_ACADEMY_ANSWER_QUESTIONS)
end

function UIActKeyMin:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if(self._sid ~= sid)then return end
		self:ResetData(pb)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (data,sid)
		if sid ~= self._sid then return end
		self:OnActivityConfigData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityResp,function (pb)
		local sid = pb.sid
		if(self._sid ~= sid)then return end
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityListResp,function (pb)
		local activities = pb.activities
		for i, v in ipairs(activities) do
			if v.sid == self._sid then
				self:RefreshData()
				return
			end
		end
	end)
	self:WndEventRecv(EventNames.ON_JUMP, function(...) self:WndClose() end)

	--self:WndNetMsgRecv(LProtoIds.ActivityMagicAcademyAnswerRoomResp,function (pb)
	--	local sid = pb.sid
	--	if(self._sid ~= sid)then return end
	--	local bool = gModelActivity:GetAnswerIsRoom(sid)
	--	if not bool then return end
	--	self:TimerStart(self._closeWndTime, 1, false, 1)
	--end)
end
function UIActKeyMin:OnClickHelp()
	GF.OpenWnd("UIBzTips",{refId = 135})
end

function UIActKeyMin:OnClickRank()
	local sid = self._sid
	local _pages = self.pages
	local _rankRewardId = self._rankRewardId or 12
	local page =  _pages[_rankRewardId]
	if not page then return end
	local _rewardList = LxDataHelper.SevenParseRewardList(sid,page)
	GF.OpenWndBottom("UIRkPop",{refId = self._rankId,sid = sid,rewardList = _rewardList,callFunc = function()
		GF.OpenWnd("UIActKeyMin",{sid = sid})
	end})
end
function UIActKeyMin:CreateCommonIcon(data)
	local instanceID = data.instanceID
	local trans = data.trans
	local itemType,itemId,itemNum = data.itemType, data.itemId, data.itemNum
	local baseClass = self._uiCommonList[instanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._uiCommonList[instanceID] = baseClass
		baseClass:Create(trans)
	end
	baseClass:SetCommonReward(itemType,itemId,itemNum)
	local showNum = itemNum > 0
	baseClass:EnableShowNum(showNum)
	baseClass:DoApply()
	self:SetWndClick(trans,function ()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end
function UIActKeyMin:OnClickMatching()
	if self._residueNum <= 0 then
		GF.ShowMessage(ccClientText(26431))
		return
	end
	gModelActivity:OnActivitySpecialOpReq(self._sid,0,0,nil,"0",ModelActivity.MAGIC_ACADEMY_ANSWER_QUESTIONS)
end

function UIActKeyMin:ListItem(list,item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local itemRoot = self:FindWndTrans(root,"ItemRoot")
	local instanceID = item:GetInstanceID()

	local reward = itemdata
	reward.instanceID = instanceID
	reward.trans = itemRoot
	self:CreateCommonIcon(reward)
end

function UIActKeyMin:OnTryTcpReconnect()
	self:WndClose()
end
function UIActKeyMin:OnTimer(key)
	if(key == self._timeKey)then
		self:SetTime()
	elseif(key == self._closeWndTime)then
		self:WndClose()
	end
end

function UIActKeyMin:InitEvent()
	self._modelMagList = {
		-- [ModelActivity.MODEL_ACTIVITY_TYPE_66] = "UIActMagicShcool",
	}
	self:SetWndClick(self.mBtnClose, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnRank, function(...) self:OnClickRank() end)
	self:SetWndClick(self.mBtnCancel, function(...) self:OnClickCancel() end)
	self:SetWndClick(self.mBtnMatching, function(...) self:OnClickMatching() end)
	self:SetWndClick(self.mBtnHelp,function (...)self:OnClickHelp() end)
end

function UIActKeyMin:ResetData(pb)
	local list = self.pages or {}
	for i, v in ipairs(pb.pages) do
		local page = gModelActivity:GenerateActivePageDataFromPb(v)
		list[page.pageId] = page
	end
	self.pages = list
	self:RefreshData()
end

function UIActKeyMin:OnClickClose()
	local wndName = self._modelMagList[self._modelId]
	GF.OpenWnd(wndName,{sid = self._sid})
	self:WndClose()
end
------------------------------------------------------------------
return UIActKeyMin


