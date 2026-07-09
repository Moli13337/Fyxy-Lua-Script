---
--- Created by LCM.
--- DateTime: 2024/3/27 11:59:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeRunInTo:LWnd
local UIHopeRunInTo = LxWndClass("UIHopeRunInTo", LWnd)

UIHopeRunInTo.NOT_START_GAME = 0	-- 未开始游戏
UIHopeRunInTo.START_GAME = 1		-- 开始游戏
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeRunInTo:UIHopeRunInTo()
	self._initAniKey = "initAniKey"			-- 初始化动画
	self._initAniStatus = true

	self._runAniKey = "runAniKey"			-- 翻牌动画
	self._runAniStatus = false				-- 是否在翻牌

	self._selHeroAniKey = "selHeroAniKey"
	self._selHeroAniStatus = false

	self._closeWndTimerKey = "closeWndTimerKey"
	self._closeTime = 0.5


	self._startGameStatus = UIHopeRunInTo.NOT_START_GAME
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeRunInTo:OnWndClose()
	self:SendMsg()
	--FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeRunInTo:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeRunInTo:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	CS.ShowObject(self.mInitRoot,true)
	CS.ShowObject(self.mDescTxt,true)
	self:InitEvent()
	self:InitMsg()
	self:InitHeroCardList()
	self:InitHeroCardPosList()
	self:InitData()
	self:InitShow()
end

function UIHopeRunInTo:RunAniFunc()
	if self._runAniStatus then return end
	self._runAniStatus = true
	local seqKey = self._runAniKey
	local seqTween = self:TweenSeqFind(seqKey)
	if seqTween then
		self:TweenSeqKill(seqKey)
		seqTween = nil
	end
	seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local heroCardPosList = self._heroCardPosList
		local fanTime = 0.2
		local allTime = 0
		local initHeroCardPosList = self._initHeroCardPosList
		for i,v in ipairs(initHeroCardPosList) do
			local tween = v.root.transform:DOLocalRotate(Vector3(0,90,0),fanTime)
			seq:AppendCallback(function()
				CS.ShowObject(v.EffTrans,true)
			end)
			seq:Join(tween)
			seq:AppendCallback(function()
				CS.ShowObject(v.BgTrans,true)
				CS.ShowObject(v.HeroQualityBgTrans,false)
			end)
			local tween1 = v.root.transform:DOLocalRotate(Vector3(0,0,0),fanTime)
			seq:Join(tween1)
		end

		allTime = allTime + 1

		local swapTime = 0.3
		--- 卡牌交换位置
		local partnerTime = gModelDreamTrip:GetConfigByKey("partnerTime")
		for i = 1,partnerTime do
			local index1,index2 = self:GetSwapIndex()

			local posInfo1,posInfo2 = initHeroCardPosList[index1],initHeroCardPosList[index2]
			local posindex1,posindex2 = posInfo1.posIndex,posInfo2.posIndex
			local root1 = posInfo1.root
			local root2 = posInfo2.root

			local theroCardPosInfo1 = heroCardPosList[posindex1]
			local theroCardPosInfo2 = heroCardPosList[posindex2]
			local pos1 =  theroCardPosInfo1.pos
			local pos2 =  theroCardPosInfo2.pos

			posInfo1.posIndex = posindex2
			posInfo2.posIndex = posindex1

			local tweener1 = root1:DOLocalMove(pos2,swapTime)
			seq:Append(tweener1)
			local tweener2 = root2:DOLocalMove(pos1,swapTime)
			seq:Join(tweener2)
			seq:AppendInterval(0.1)
		end
		return seq
	end)
	seqTween:OnComplete(function()
		self:TweenSeqKill(seqKey)
		self._runAniStatus = false
	end)
	seqTween:PlayForward()
end

function UIHopeRunInTo:OnClickCloseBtnFunc()
	if self._startGameStatus == UIHopeRunInTo.START_GAME then return end
	self:WndClose()
end

function UIHopeRunInTo:GetSwapIndex()
	local indexList = self._indexList
	local list = {}
	for i,v in ipairs(indexList) do
		table.insert(list,v)
	end
	local randomFunc = function()
		local randomNum = math.random(1,#list)
		return table.remove(list,randomNum)
	end
	return randomFunc(),randomFunc()
end

function UIHopeRunInTo:InitData()
	self._eventId = self:GetWndArg("eventId")
	self._index = self:GetWndArg("index")


	local extraData = self:GetWndArg("extraData")
	self._extraData = extraData

	self._selHeroRefId = nil
	self:InitConfigData()
	self._isForeign = gLGameLanguage:IsForeignRegion()

	local eventRefId
	--local serverData = gModelDreamTrip:GetPlatformByIndexAndEventId(self._eventId,self._index)

	local serverData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,self:GetExtraData())
	if serverData then
		eventRefId = serverData.eventRefId
	end
	if eventRefId then
		local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
		if eventRef then
			local name = ccLngText(eventRef.name)
			self:SetWndText(self.mLblBiaoti,name)
		end
	end
end

function UIHopeRunInTo:SendMsg()
	if self._sendMsgFunc then
		self._sendMsgFunc()
	end
	self._sendMsgFunc = nil
end

function UIHopeRunInTo:OnDreamTripStartEventResp(pb)
	if pb.eventId ~= self._eventId then return end
	local endInfo = pb.endInfo
	if not endInfo then return end
	if endInfo.state == StructDreamTripGrid.FINISH then
		self:TimerStop(self._closeWndTimerKey)
		self:TimerStart(self._closeWndTimerKey,self._closeTime,false,1)
	else
		self:WndClose()
	end
	self._startGameStatus = UIHopeRunInTo.NOT_START_GAME
end

function UIHopeRunInTo:DisposeHeroCard(heroRefId,transInfo)
	local heroRef = gModelHero:GetHeroRef(heroRefId)
	local effRef = gModelHero:GetHeroShowRefByRefId(heroRefId)
	if heroRef and effRef then
		if transInfo then
			local quality = heroRef.quality
			local qualityRef = gModelItem:GetQualityRef(quality)
			if qualityRef then
			end


			local raceTypeImg = gModelHero:GetRaceImgByRefId(heroRef.raceType)
			self:SetWndEasyImage(transInfo.RaceTypeTrans,raceTypeImg)

			self:SetWndEasyImage(transInfo.HeroIconTrans,effRef.iconBig,function()
				CS.ShowObject(transInfo.HeroIconTrans,true)
			end,true)

			local name = gModelHero:GetHeroNameByRefId(heroRefId)
			self:SetWndText(transInfo.HeroNameTrans,name)

			local isShowCoverBg = false
			local CoverImgTrans = transInfo.CoverImgTrans
			CS.ShowObject(CoverImgTrans, isShowCoverBg)

			self:SetWndClick(transInfo.BgTrans,function()
				self:OnClickBgTransFunc(heroRefId,transInfo)
			end)

			self:SetWndClick(transInfo.HeroQualityBgTrans,function()
				self:OnClickHeroQualityBgTransFunc(heroRefId)
			end)
		end
	end
end

function UIHopeRunInTo:GetExtraData()
	return self._extraData
end

function UIHopeRunInTo:InitHeroCardList()
	local heroCardTransList = {
		self.mHeroCard1,
		self.mHeroCard2,
		self.mHeroCard3,
	}
	local indexList = {}
	local initHeroCardPosList = {}
	local initHeroCardTransInfoList = {}
	for i,v in ipairs(heroCardTransList) do
		table.insert(indexList,i)

		local heroCardInfo = self:InitHeroCardTrans(v)
		table.insert(initHeroCardPosList,{
			root = v,
			BgTrans = heroCardInfo.BgTrans,
			EffTrans = heroCardInfo.EffTrans,
			HeroQualityBgTrans = heroCardInfo.HeroQualityBgTrans,
			pos = v.localPosition,
			posIndex = i,
			dataIndex = i
		})
		table.insert(initHeroCardTransInfoList,heroCardInfo)
	end

	self._indexList = indexList
	self._initHeroCardPosList = initHeroCardPosList
	self._initHeroCardTransInfoList = initHeroCardTransInfoList
end

function UIHopeRunInTo:OnClickBgTransFunc(heroRefId,transInfo)
	if not self._selHeroRefId then return end
	if self._selHeroAniStatus then return end
	if self._runAniStatus then return end
	local isSame = heroRefId == self._selHeroRefId
	if isSame then
		self:RunSuccessAni(transInfo)
	else
		self:RunFailAni(transInfo)
	end
end

function UIHopeRunInTo:OnClickHeroQualityBgTransFunc(heroRefId)
	local initHeroMaskTransList = self._initHeroMaskTransList
	for k,maskTrans in pairs(initHeroMaskTransList) do
		local show = heroRefId ~= k
		CS.ShowObject(maskTrans,show)
	end
	self._selHeroRefId = heroRefId
end

function UIHopeRunInTo:RefreshHeroCard()
	local showHeroRefIdList = self._showHeroRefIdList
	local initHeroCardTransInfoList = self._initHeroCardTransInfoList

	local initHeroMaskTransList = {}
	for i,heroRefId in ipairs(showHeroRefIdList) do
		local transInfo = initHeroCardTransInfoList[i]
		if transInfo then
			initHeroMaskTransList[heroRefId] = transInfo.MaskTrans
		end
	end
	self._initHeroMaskTransList = initHeroMaskTransList

	for i,heroRefId in ipairs(showHeroRefIdList) do
		local transInfo = initHeroCardTransInfoList[i]
		if transInfo then
			self:DisposeHeroCard(heroRefId,transInfo)
		end
	end
end

function UIHopeRunInTo:OnTimer(key)
	if self._closeWndTimerKey == key then
		--gModelCommonDreamTrip:CheckSendSpeedUpEvent(self:GetExtraData())
		self:WndClose()
	end
end

function UIHopeRunInTo:CreateSelHeroShow()
	local heroRefId = self._selHeroRefId
	if not heroRefId then return end
	local prefabName = gModelHero:GetHeroPrefabNameByRefId(heroRefId)
	if not prefabName then return end
	self:CreateWndSpine(self.mSpineRoot,prefabName,prefabName,false,function(spine)
	end)
	local heroName = gModelHero:GetHeroNameByRefId(heroRefId)
	local str = string.replace(ccClientText(28723),heroName)
	self:SetWndText(self.mDemandTxt,str)
	self:InitTextLineWithLanguage(self.mDemandTxt, -30)
	CS.ShowObject(self.mDescTxt,false)
end

function UIHopeRunInTo:InitShow()
	self:RefreshHeroCard()
	CS.ShowObject(self.mInitRoot,true)
	CS.ShowObject(self.mRewardRoot,false)
	CS.ShowObject(self.mStartBtn,true)
	self:RunInitShowAni()
end

function UIHopeRunInTo:InitConfigData()
	self._showHeroRefIdList = {}
	if not self._eventId or not self._index then return end
	--local moreInfo = gModelDreamTrip:GetPlatMoreInfoKeyByIndexAndEventId(self._eventId,self._index,StructDreamTripEventInfo.ENCOUNTER_HERO)

	local extraData = self:GetExtraData()
	local moreInfo = gModelCommonDreamTrip:GetDreamTripEventIdMoreInfoKey({
		mapType = extraData.mapType,
		sid = extraData.sid,
		eventId = self._eventId,
		index = self._index,
		key = StructDreamTripEventInfo.ENCOUNTER_HERO,
	})
	local len = #moreInfo
	local endInfo = moreInfo[len]
	local heroList = endInfo.heroList
	for i,v in ipairs(heroList) do
		table.insert(self._showHeroRefIdList,v)
	end
end

function UIHopeRunInTo:InitText()
	self:SetWndText(self.mDescTxt,ccClientText(28721))
	self:InitTextLineWithLanguage(self.mDescTxt, -30)
	self:SetWndButtonText(self.mStartBtn,ccClientText(28708))
end

function UIHopeRunInTo:CommonSelHeroAni(transInfo,isSuc)
	self._status = isSuc and 1 or -1
	self._sendMsgFunc = function()
		--gModelDreamTrip:OnDreamTripStartEventReq(self._eventId,{self._status or 1})

		local state = self._status or 1
		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:OnDreamTripStartEventProcessor(self._eventId,{
			mapType = extraData.mapType,
			sid = extraData.sid,
			argList = {tostring(state)},
		})
	end
	self._selHeroAniStatus = true
	local seqKey = self._selHeroAniKey
	local seqTween = self:TweenSeqFind(seqKey)
	if seqTween then
		self:TweenSeqKill(seqKey)
		seqTween = nil
	end
	seqTween = self:TweenSeqCreate(seqKey, function(seq)
		--- 打错也需要点亮
		CS.ShowObject(transInfo.MaskTrans,false)
		local fanTime = 0.2
		seq:AppendCallback(function()
			CS.ShowObject(transInfo.EffTrans,true)
		end)
		local tween = transInfo.RootTrans.transform:DOLocalRotate(Vector3(0,90,0),fanTime)
		seq:Join(tween)
		seq:AppendCallback(function()
			CS.ShowObject(transInfo.BgTrans,false)
			CS.ShowObject(transInfo.HeroQualityBgTrans,true)
		end)
		local tween1 = transInfo.RootTrans.transform:DOLocalRotate(Vector3(0,0,0),fanTime)
		seq:Join(tween1)
		seq:AppendInterval(0.5)
		seq:AppendCallback(function()
			self:ShowRewardRoot(isSuc)
		end)
		seq:AppendInterval(1)
		seq:AppendCallback(function()
			self:SendMsg()
		end)
		return seq
	end)
	seqTween:OnComplete(function()
		CS.ShowObject(transInfo.EffTrans,false)
		self:TweenSeqKill(seqKey)
	end)
	seqTween:PlayForward()
end

function UIHopeRunInTo:InitHeroCardTrans(trans)
	local BgTrans = self:FindWndTrans(trans,"Bg")
	local HeroQualityBgTrans = self:FindWndTrans(trans,"HeroQualityBg")
	local HeroIconTrans = self:FindWndTrans(HeroQualityBgTrans,"HeroIcon")
	local RaceTypeTrans = self:FindWndTrans(HeroQualityBgTrans,"RaceType")
	local NameBgTrans = self:FindWndTrans(HeroQualityBgTrans,"NameBg")
	local HeroNameTrans = self:FindWndTrans(NameBgTrans,"HeroName")
	local MaskTrans = self:FindWndTrans(HeroQualityBgTrans,"Mask")
	local CoverImgTrans = self:FindWndTrans(HeroQualityBgTrans,"CoverImg")
	local EffTrans = self:FindWndTrans(HeroQualityBgTrans,"Eff")
	local key = EffTrans:GetInstanceID()
	self:CreateWndEffect(EffTrans,"fx_mjfanpai",key,70,false,false)
	return {
		RootTrans = trans,
		BgTrans = BgTrans,
		HeroQualityBgTrans = HeroQualityBgTrans,
		HeroIconTrans = HeroIconTrans,
		RaceTypeTrans = RaceTypeTrans,
		NameBgTrans = NameBgTrans,
		HeroNameTrans = HeroNameTrans,
		MaskTrans = MaskTrans,
		CoverImgTrans = CoverImgTrans,
		EffTrans = EffTrans,
	}
end

function UIHopeRunInTo:RunFailAni(transInfo)
	self:CommonSelHeroAni(transInfo,false)
end

function UIHopeRunInTo:InitHeroCardPosList()
	local heroCardPosTransList = {
		self.mHeroCardPos1,self.mHeroCardPos2,self.mHeroCardPos3
	}
	local heroCardPosList = {}
	for i,v in ipairs(heroCardPosTransList) do
		table.insert(heroCardPosList,{
			pos = v.localPosition,
			root = v
		})
	end
	self._heroCardPosList = heroCardPosList
end

function UIHopeRunInTo:RunInitShowAni()
	local seqKey = self._initAniKey
	local seqTween = self:TweenSeqFind(seqKey)
	if seqTween then
		self:TweenSeqKill(seqKey)
		seqTween = nil
	end
	local initHeroCardPosList = self._initHeroCardPosList
	seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local fanTime = 0.2
		for i,v in ipairs(initHeroCardPosList) do
			local tween = v.root.transform:DOLocalRotate(Vector3(0,90,0),fanTime)
			seq:AppendCallback(function()
				CS.ShowObject(v.EffTrans,true)
			end)
			seq:Join(tween)
			seq:AppendCallback(function()
				CS.ShowObject(v.BgTrans,false)
				CS.ShowObject(v.HeroQualityBgTrans,true)
			end)
			local tween1 = v.root.transform:DOLocalRotate(Vector3(0,0,0),fanTime)
			seq:Join(tween1)
		end
		return seq
	end)
	seqTween:OnComplete(function()
		for i,v in ipairs(initHeroCardPosList) do
			CS.ShowObject(v.EffTrans,false)
		end
		self:TweenSeqKill(seqKey)
		self._initAniStatus = false
	end)
	seqTween:PlayForward()
end

function UIHopeRunInTo:RunSuccessAni(transInfo)
	self:CommonSelHeroAni(transInfo,true)
end

function UIHopeRunInTo:InitEvent()
	self:SetWndClick(self.mMask,function() self:OnClickCloseBtnFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:OnClickCloseBtnFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mStartBtn,function() self:OnClickStartBtnFunc() end)
end

function UIHopeRunInTo:OnClickStartBtnFunc()
	if not self._selHeroRefId then
		return
	end
	self._startGameStatus = UIHopeRunInTo.START_GAME
	CS.ShowObject(self.mStartBtn,false)
	self:CreateSelHeroShow()
	self:RunAniFunc()
end

function UIHopeRunInTo:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb) self:OnDreamTripStartEventResp(pb) end)
	self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList)
		--gModelDreamTrip:EventIdCanCel(self._eventId)

		local extraData = self:GetExtraData()
		gModelCommonDreamTrip:CancelEventIdStatus({
			mapType = extraData.mapType,
			sid = extraData.sid,
			eventId = self._eventId
		})

		self._startGameStatus = UIHopeRunInTo.NOT_START_GAME
		self:WndClose()
	end)

	--- 7.20新增活动梦境之旅
	--self:WndNetMsgRecv(LProtoIds.ActivityDreamTripStartEventResp,function(pb,ret) self:OnDreamTripStartEventResp(pb) end)
end

function UIHopeRunInTo:ShowRewardRoot(isSuc)
	CS.ShowObject(self.mRewardRoot,true)
	CS.ShowObject(self.mInitRoot,false)
	local textId = isSuc and 28709 or 28722
	self:SetWndText(self.mRewardTxt,ccClientText(textId))
	self:InitTextLineWithLanguage(self.mRewardTxt, -30)
	local showTrans = isSuc and self.mYesImg or self.mNotImg
	local hideTrans = isSuc and self.mNotImg or self.mYesImg
	CS.ShowObject(showTrans,true)
	CS.ShowObject(hideTrans,false)
end

------------------------- List -------------------------


------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeRunInTo


