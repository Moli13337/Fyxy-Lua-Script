---
--- Created by LCM.
--- DateTime: 2024/3/14 16:16:40
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeFortuneDraw:LWnd
local UIHopeFortuneDraw = LxWndClass("UIHopeFortuneDraw", LWnd)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local YXTween = YXTween
local Tweening = DG.Tweening
local EaseOutCubic = Tweening.Ease.OutCubic
local EaseInQuad = Tweening.Ease.InQuad
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeFortuneDraw:UIHopeFortuneDraw()
	self._openWndAniKey = "openWndAniKey"

	self._normalArrowRunTime = 0.8								-- 正常转盘的速度
	self._arrowAniTimerKey = "arrowAniTimerKey"

	self._turnCount = 6											-- 旋转圈数
	self._rewardCount = 8										-- 奖励个数
	self._subSpeedGridNum = 5									-- 开始减速

	self._startRunArrowTimerKey = "startRunArrowTimerKey"		-- 开始旋转
	self._centerRunArrowTimerKey = "centerRunArrowTimerKey"		-- 正在旋转
	self._endRunArrowTimerKey = "endRunArrowTimerKey"			-- 结束旋转
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeFortuneDraw:OnWndClose()
	--FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeFortuneDraw:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeFortuneDraw:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitRewardTransInfoList()
	self:InitArrowTransInfoList()
	self:InitAniData()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:InitShow()
	self:RefreshLimitTxt()
	self:InitRewardIcon()
	self:RunOpenWndAni()
end

function UIHopeFortuneDraw:CenterRunLuckyDrawAni()
	local endPosIndex = self._endPosIndex
	local curTurnIndex = self._curTurnIndex
	if endPosIndex > curTurnIndex then
		self:TimerStop(self._centerRunArrowTimerKey)
		self:EndRunLuckyDrawAni()
	else
		local rewardCount = self._rewardCount
		local lastNum = rewardCount - curTurnIndex + endPosIndex
		if lastNum >= self._subSpeedGridNum then
			self:TimerStop(self._centerRunArrowTimerKey)
			self:EndRunLuckyDrawAni()
		else
			self:CheckCenterAniStatus()
			self:SetPos(self._curTurnIndex)
			self:CreateCommmonTimer(self._centerRunArrowTimerKey,self._startRunArrorTime,true,1)
		end
	end
end

function UIHopeFortuneDraw:CheckAniStatus()
	local startRunArrorTime = self._startRunArrorTime
	local baseSubRunTime = self._baseSubRunTime
	local minArrowRunTime = self._minArrowRunTime

	local newTime = startRunArrorTime - baseSubRunTime
	newTime = newTime < minArrowRunTime and minArrowRunTime or newTime
	self._startRunArrorTime = newTime

	local curTurnIndex = self._curTurnIndex
	local newTurnIndex,isNextStatus = self:ChangeArrowPosIndex(curTurnIndex)
	if isNextStatus then
		self._curTurnCount = self._curTurnCount + 1
	end
	self._curTurnIndex = newTurnIndex
end

function UIHopeFortuneDraw:ChangeArrowPosIndex(tIndex)
	local oldIndex = tIndex or self._initArrowPosIndex
	local newIndex = oldIndex + 1
	local len = self._rewardCount
	local status = newIndex > len
	if status then
		newIndex = 1
	end
	return newIndex,status
end

function UIHopeFortuneDraw:OpenRewardWnd(pb)
	local showItemList = self._showItemList
	if not showItemList then
		local pos = self:GetEndPosIndex()
		local rewardRefIdRewardList = self._rewardRefIdRewardList or {}
		local rewardList = rewardRefIdRewardList[pos]
		if not rewardList then
			self:WndClose()
			return
		end
		showItemList = {}
		local doubleCardParam = self._doubleCardParam or 1
		for i,v in ipairs(rewardList) do
			table.insert(showItemList,{
				itype = v.itype,
				itemId = v.itemId,
				count = v.count * doubleCardParam,
			})
		end
	end

	local para =
	{
		itemList = showItemList,
		callBackFunc = function()
			if not self:IsWndValid() then return end
			local loseNum = self:GetLuckyNum()
			if loseNum < 1 then
				gModelCommonDreamTrip:CheckSendSpeedUpEvent(self:GetExtraData())
				self:WndClose()
				return
			end
			self:RefreshLimitTxt()
			self._showItemList = nil
		end,
	}
	gModelWndPop:TryOpenPopWnd("UIAward",para)
end

function UIHopeFortuneDraw:InitRewardTransInfoList()
	local rewardTransList = {
		self.mReward1, self.mReward2, self.mReward3, self.mReward4, self.mReward5, self.mReward6, self.mReward7, self.mReward8,
	}
	local rewardTransInfoList = {}
	local rewardInitTransInfoList = {}
	for i,v in ipairs(rewardTransList) do
		local transInfo = self:GetRewardTransInfo(v)
		table.insert(rewardTransInfoList,transInfo)

		table.insert(rewardInitTransInfoList,{
			pos = v.localPosition,
			root = v
		})
		v.localPosition = Vector3.zero
	end
	self._rewardTransInfoList = rewardTransInfoList
	self._rewardInitTransInfoList = rewardInitTransInfoList

	self._rewardCount = #rewardTransList
end

function UIHopeFortuneDraw:GetRewardTransInfo(trans)
	local RewardBgTrans = self:FindWndTrans(trans,"RewardBg")
	local IconTrans = self:FindWndTrans(RewardBgTrans,"Icon")
	local UITextTrans = self:FindWndTrans(RewardBgTrans,"UIText")
	return {
		rootTrans = trans,
		rewardBgTrans = RewardBgTrans,
		iconTrans = IconTrans,
		uiTextTrans = UITextTrans,
	}
end

function UIHopeFortuneDraw:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb) self:OnDreamTripStartEventResp(pb) end)
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList)
		--gModelDreamTrip:EventIdCanCel(self._eventId)

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:CancelEventIdStatus({
			mapType = extraData.mapType,
			sid = extraData.sid,
			eventId = self._eventId
		})
	end)


	--- 7.20新增活动梦境之旅
	--self:WndNetMsgRecv(LProtoIds.ActivityDreamTripStartEventResp,function(pb,ret) self:OnDreamTripStartEventResp(pb) end)
end

function UIHopeFortuneDraw:InitArrowTransInfoList()
	local arrowPosTransList = {
		self.mArrowPos1, self.mArrowPos2, self.mArrowPos3, self.mArrowPos4, self.mArrowPos5, self.mArrowPos6, self.mArrowPos7, self.mArrowPos8,
	}

	local arrowPosTransInfoList = {}
	for i,v in ipairs(arrowPosTransList) do
		table.insert(arrowPosTransInfoList,{
			rotation = v.localEulerAngles,
			index = i
		})
	end
	self._arrowPosTransInfoList = arrowPosTransInfoList
	self._initArrowPosIndex = 1
end

function UIHopeFortuneDraw:InitEvent()
	--self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mLuckyDrawBtn,function() self:OnClickLuckyDrawBtnFunc() end)
end

function UIHopeFortuneDraw:CheckEndPosIndex()
	self._endPosIndex = self:GetEndPosIndex()
end

function UIHopeFortuneDraw:OnShowRewardTips(itemdata)
	if not itemdata then return end
	gModelGeneral:ShowCommonItemTipWnd(itemdata)
end

function UIHopeFortuneDraw:GetMoreInfo()
	local extraData = self:GetExtraData()
	local moreInfo = gModelCommonDreamTrip:GetDreamTripEventIdMoreInfoKey({
		mapType = extraData.mapType,
		sid = extraData.sid,
		eventId = self._eventId,
		index = self._index,
		key = StructDreamTripEventInfo.TURNTABLE_RESULT,
	})
	return moreInfo
end

function UIHopeFortuneDraw:InitData()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")

	self._sendMsg = false

	local extraData = self:GetWndArg("extraData")
	self._extraData = extraData

	local doubleCardParam = gModelDreamTrip:GetEventRewardNum(self._eventId,self._index,self:GetExtraData())
	self._doubleCardParam = doubleCardParam
	if self._eventId and self._index then
		--local serverData = gModelDreamTrip:GetPlatformByIndexAndEventId(self._eventId,self._index)
		local serverData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,self:GetExtraData())
		if serverData then
			local eventRefId = serverData.eventRefId
			local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
			if eventRef then
				local rewardItemRefList = gModelDreamTrip:GetDreamTripRewardListByGroup(eventRef.reward)
				local rewardItemList = {}
				local rewardRefIdPosList = {}
				local rewardRefIdRewardList = {}
				local refId,location
				for i,v in ipairs(rewardItemRefList) do
					refId = v.refId
					location = v.location

					rewardRefIdPosList[refId] = location

					local reward = {}
					table.insert(reward,{
						itype = v.itemType,
						itemId = v.itemId,
						count = v.itemNum,
					})
					rewardRefIdRewardList[location] = reward

					rewardItemList[location] = {
						itemType = v.itemType,
						itemId = v.itemId,
						itemNum = v.itemNum,
					}

					--[[					table.insert(rewardItemList,{
                                            itemType = v.itemType,
                                            itemId = v.itemId,
                                            itemNum = v.itemNum,
                                        })]]
				end
				self._rewardItemList = rewardItemList
				self._rewardRefIdPosList = rewardRefIdPosList
				self._rewardRefIdRewardList = rewardRefIdRewardList
			end
		end
	end
end

function UIHopeFortuneDraw:CreateCommmonTimer(key,time,timeScale,loopCnt)
	timeScale = timeScale and true or false
	loopCnt = loopCnt or -1
	self:TimerStop(key)
	self:TimerStart(key,time,timeScale,loopCnt)
end

function UIHopeFortuneDraw:GetTransCanvasGroup(trans)
	local csCanvasGroup = trans:GetComponent(typeofCanvasGroup)
	if not csCanvasGroup then
		csCanvasGroup = trans.gameObject:AddComponent(typeofCanvasGroup)
	end
	csCanvasGroup.alpha = 0
	return csCanvasGroup
end

function UIHopeFortuneDraw:OnClickLuckyDrawBtnFunc()
	if self._sendMsg then return end
	self._sendMsg = true
	--gModelDreamTrip:OnDreamTripStartEventReq(self._eventId)

	local extraData = self:GetExtraData()
	gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
		mapType = extraData.mapType,
		sid = extraData.sid,
		argList = {},
	})
end

function UIHopeFortuneDraw:SetPos(index)
	local initPos = index == nil
	index = index or self._initArrowPosIndex
	local arrowPosTransInfoList = self._arrowPosTransInfoList
	local arrowPosTransInfo = arrowPosTransInfoList[index]
	if initPos then
		self._initArrowPosIndex = self:ChangeArrowPosIndex()
	end
	if not arrowPosTransInfo then
		return
	end
	local rotation = arrowPosTransInfo.rotation
	self.mArrowStartRoot.localRotation = Quaternion.Euler(rotation.x,rotation.y,rotation.z)
end

function UIHopeFortuneDraw:OnDreamTripStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end
	if pb.endInfo and pb.endInfo.state == 1 then
		self._showItemList = {}
		for i,v in ipairs(pb.endInfo.reward) do
			table.insert(self._showItemList,{
				itype = v.type,
				itemId = v.itemId,
				count = tonumber(v.count),
			})
		end
	end

	self._rewardFunc = function()
		self:OpenRewardWnd(pb)
	end
	self:RefreshLimitTxt()
	self:RunLuckyDrawAni()
end

function UIHopeFortuneDraw:OpenNewRewardWnd(pb)

end

function UIHopeFortuneDraw:RunArrorAni()
	self:SetPos()
	self:CreateCommmonTimer(self._arrowAniTimerKey,self._normalArrowRunTime,false,-1)
end

function UIHopeFortuneDraw:GetExtraData()
	return self._extraData
end

function UIHopeFortuneDraw:RefreshLimitTxt()
	local loseNum = self:GetLuckyNum()
	local str = string.replace(ccClientText(28724),loseNum)
	self:SetWndText(self.mLuckyNumTxt,str)
end

function UIHopeFortuneDraw:RunOpenWndAni()
	local seqKey = self._openWndAniKey
	local seqTween = self:TweenSeqFind(seqKey)
	if seqTween then
		self:TweenSeqKill(seqKey)
		seqTween = nil
	end
	seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local showTime = 0
		local panBgCG = self:GetTransCanvasGroup(self.mPanBg)
		CS.ShowObject(self.mPanBg,true)
		if panBgCG then
			showTime = 0.5
			local panShowTween = YXTween.TweenFloat(0, 1, showTime, function(ival)
				panBgCG.alpha = ival
			end):SetEase(EaseInQuad)
			seq:Append(panShowTween)
		end

		local moveToTime = 0.2
		local runTime = showTime + 0.1
		local rewardInitTransInfoList = self._rewardInitTransInfoList
		for i,initTransInfo in ipairs(rewardInitTransInfoList) do
			local root = initTransInfo.root
			local moveTween = root:DOLocalMove(initTransInfo.pos,moveToTime)
			seq:Insert(runTime,moveTween)
			seq:InsertCallback(runTime,function()
				CS.ShowObject(root,true)
			end)
			runTime = runTime + moveToTime - 0.1
		end

		local titleEndPos = self.mTitleImgEndPos.localPosition
		CS.ShowObject(self.mTitleImg,true)
		local moveTween = self.mTitleImg:DOLocalMove(titleEndPos,moveToTime)
		seq:Append(moveTween)

		--[[		local btnTrans = self.mLuckyDrawBtn
                btnTrans.localScale = Vector3.zero
                CS.ShowObject(btnTrans,true)
                local btnTween = btnTrans:DOScale(Vector3(1,1,1), moveToTime)
                seq:Join(btnTween)]]

		local arrowMaskCG = self:GetTransCanvasGroup(self.mArrowMask)
		if arrowMaskCG then
			seq:AppendCallback(function()
				CS.ShowObject(self.mArrowMask,true)
			end)
			showTime = 0.5
			local arrowMaskTween = YXTween.TweenFloat(0, 1, showTime, function(ival)
				arrowMaskCG.alpha = ival
			end):SetEase(EaseInQuad)
			seq:Append(arrowMaskTween)
		end

		local arrowStartRootCG = self:GetTransCanvasGroup(self.mArrowStartRoot)
		if arrowStartRootCG then
			seq:AppendCallback(function()
				CS.ShowObject(self.mArrowRoot,true)
			end)
			showTime = 0.5
			local arrowStartRootTween = YXTween.TweenFloat(0, 1, showTime, function(ival)
				arrowStartRootCG.alpha = ival
			end):SetEase(EaseInQuad)
			seq:Append(arrowStartRootTween)
		end

		return seq
	end)
	seqTween:OnComplete(function()
		CS.ShowObject(self.mLuckyDrawBtn,true)
		CS.ShowObject(self.mLuckyNumTxt,true)
		self:TweenSeqKill(seqKey)
		self:RunArrorAni()
	end)
	seqTween:PlayForward()
end

function UIHopeFortuneDraw:CheckCenterAniStatus()
	local startRunArrorTime = self._startRunArrorTime
	local baseSubRunTime = self._baseSubRunTime
	local newTime = startRunArrorTime + baseSubRunTime
	if newTime > self._maxArrowRunTime then
		newTime = self._maxArrowRunTime
	end
	self._startRunArrorTime = newTime

	local newTurnIndex = self:ChangeArrowPosIndex(self._curTurnIndex)
	self._curTurnIndex = newTurnIndex
end

function UIHopeFortuneDraw:StartRunLuckyDrawAni()
	if self._curTurnCount == self._turnCount then
		self:TimerStop(self._startRunArrowTimerKey)
		local endPosIndex = self._endPosIndex
		local curTurnIndex = self._curTurnIndex
		if endPosIndex >= curTurnIndex then
			self:CenterRunLuckyDrawAni()
		else
			self:EndRunLuckyDrawAni()
		end
	else
		self:CheckAniStatus()
		self:SetPos(self._curTurnIndex)
		self:CreateCommmonTimer(self._startRunArrowTimerKey,self._startRunArrorTime,true,1)
	end
end

function UIHopeFortuneDraw:GetLuckyNum()
	local luckyNum = gModelDreamTrip:GetConfigByKey("luckyNum")

	--local moreInfo = gModelDreamTrip:GetPlatMoreInfoKeyByIndexAndEventId(self._eventId,self._index,StructDreamTripEventInfo.TURNTABLE_RESULT)

	local moreInfo = self:GetMoreInfo()
	local getNum = 0
	if moreInfo then
		local len = #moreInfo
		local endReward = moreInfo[len]
		if endReward then
			getNum = endReward.allNum
		end
	end
	return luckyNum - getNum
end

function UIHopeFortuneDraw:InitText()
	self:SetWndButtonText(self.mLuckyDrawBtn,ccClientText(28703))
end

function UIHopeFortuneDraw:OnTimer(key)
	if key == self._arrowAniTimerKey then
		self:SetPos()
	elseif key == self._startRunArrowTimerKey then
		self:StartRunLuckyDrawAni()
	elseif key == self._centerRunArrowTimerKey then
		self:CenterRunLuckyDrawAni()
	elseif key == self._endRunArrowTimerKey then
		self:EndRunLuckyDrawAni()
	end
end

function UIHopeFortuneDraw:GetEndPosIndex()
	--local moreInfo = gModelDreamTrip:GetPlatMoreInfoKeyByIndexAndEventId(self._eventId,self._index,StructDreamTripEventInfo.TURNTABLE_RESULT)

	local moreInfo = self:GetMoreInfo()
	if not moreInfo then
		return 1
	end
	local len = #moreInfo
	local endReward = moreInfo[len]
	if not endReward then
		return 1
	end
	local allNum = endReward.allNum
	local rewardIdList = endReward.rewardIdList
	local selReward = rewardIdList[allNum]
	local rewardRefIdPosList = self._rewardRefIdPosList or {}
	local pos = rewardRefIdPosList[selReward] or 1
	return pos
end

function UIHopeFortuneDraw:InitShow()
	local image = gModelDreamTrip:GetDreamTripEventImageByRefId(self._eventId,self._index,self:GetExtraData())
	if string.isempty(image) then return end
	local imageList = string.split(image,ModelDreamTrip.EVENTREF_IMAGE_SPLIT)
	--- 背景大图
	local bg = imageList[1]
	if not string.isempty(bg) then
		self:SetWndEasyImage(self.mMask,bg)
	end

	--- 标题底图
	local titleBg = imageList[2]
	if not string.isempty(titleBg) then
		self:SetWndEasyImage(self.mTitleImg,titleBg,nil,true)
	end

	local titleBgPos = imageList[3]
	if not string.isempty(titleBgPos) then
		titleBgPos = string.split(titleBgPos,",")
		self.mTitleImgEndPos.localPosition = Vector3(tonumber(titleBgPos[1]),tonumber(titleBgPos[2]),tonumber(titleBgPos[3]))
	end

	--- 转盘素材
	local panBg = imageList[4]
	if not string.isempty(panBg) then
		self:SetWndEasyImage(self.mPanBg,panBg,nil,true)
	end

	--- 转盘素材
	local panPos = imageList[5]
	if not string.isempty(panPos) then
		panPos = string.split(panPos,",")
		self.mPanBg.localPosition = Vector3(tonumber(panPos[1]),tonumber(panPos[2]),tonumber(panPos[3]))
	end

	--- 转盘 + 奖励位置
	local rewardCenterPos = imageList[6]
	if not string.isempty(rewardCenterPos) then
		rewardCenterPos = string.split(rewardCenterPos,",")
		self.mShowRoot.localPosition = Vector3(tonumber(rewardCenterPos[1]) or 0,tonumber(rewardCenterPos[2]) or 0,tonumber(rewardCenterPos[3]) or 0)
	end

	--- 抽奖按钮位置
	local luckyDrawBtnPos = imageList[7]
	if not string.isempty(luckyDrawBtnPos) then
		luckyDrawBtnPos = string.split(luckyDrawBtnPos,",")
		self.mLuckyDrawBtn.localPosition = Vector3(tonumber(luckyDrawBtnPos[1]) or 0,tonumber(luckyDrawBtnPos[2]) or 0,tonumber(luckyDrawBtnPos[3]) or 0)
	end

	--- 抽奖次数位置
	local luckyDrawTxtPos = imageList[8]
	if not string.isempty(luckyDrawTxtPos) then
		luckyDrawTxtPos = string.split(luckyDrawTxtPos,",")
		self.mLuckyNumTxt.localPosition = Vector3(tonumber(luckyDrawTxtPos[1]) or 0,tonumber(luckyDrawTxtPos[2]) or 0,tonumber(luckyDrawTxtPos[3]) or 0)
	end
end

function UIHopeFortuneDraw:RunLuckyDrawAni()
	self:TimerStop(self._arrowAniTimerKey)
	self:CheckEndPosIndex()

	self._curTurnIndex = self._initArrowPosIndex - 1
	self:StartRunLuckyDrawAni()
end

function UIHopeFortuneDraw:EndRunLuckyDrawAni()
	if self._curTurnIndex == self._endPosIndex then
		self:InitAniData()
		self:TimerStop(self._endRunArrowTimerKey)
		self._initArrowPosIndex = self._endPosIndex
		self:RunArrorAni()
		self:RunRewardFunc()
	else
		self:CheckCenterAniStatus()
		self:SetPos(self._curTurnIndex)
		self:CreateCommmonTimer(self._endRunArrowTimerKey,self._startRunArrorTime,true,1)
	end
end

function UIHopeFortuneDraw:RunRewardFunc()
	if self._rewardFunc then
		self._rewardFunc()
	end
	self._rewardFunc = nil
end

function UIHopeFortuneDraw:InitRewardIcon()
	local rewardItemList = self._rewardItemList
	if not rewardItemList then
		rewardItemList = {
			{ itemType = 1, itemId = 101001, itemNum = 100, },
			{ itemType = 1, itemId = 100239, itemNum = 100, },
			{ itemType = 1, itemId = 100252, itemNum = 100, },
			{ itemType = 1, itemId = 100267, itemNum = 100, },
			{ itemType = 1, itemId = 9004036, itemNum = 100, },
			{ itemType = 1, itemId = 9004038, itemNum = 100, },
			{ itemType = 1, itemId = 1203302, itemNum = 100, },
			{ itemType = 1, itemId = 110106, itemNum = 100, },
		}
	end
	local rewardTransInfoList = self._rewardTransInfoList
	for i,v in ipairs(rewardTransInfoList) do
		local itemData = rewardItemList[i]
		if itemData then
			local icon = gModelItem:GetItemIconByRefId(itemData.itemId)
			self:SetWndEasyImage(v.iconTrans,icon)

			local rewardBgTrans = v.rewardBgTrans
			CS.ShowObject(rewardBgTrans,true)
			self:SetWndClick(rewardBgTrans,function()
				self:OnShowRewardTips(itemData)
			end)

			self:SetWndText(v.uiTextTrans,itemData.itemNum)
		end
	end
end

function UIHopeFortuneDraw:InitAniData()
	self._minArrowRunTime = 0.05				-- 最小的速度
	self._maxArrowRunTime = 0.8				-- 最大的速度
	self._startRunArrorTime = 0.4			-- 起步的速度
	self._baseSubRunTime = 0.1				-- 每次减少的时间
	self._curTurnCount = 0					-- 开始转圈数
	self._curTurnIndex = 1					-- 开始转下标
end


------------------------- List -------------------------


------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeFortuneDraw



