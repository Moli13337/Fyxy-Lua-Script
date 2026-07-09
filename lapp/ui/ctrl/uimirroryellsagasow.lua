---
--- Created by LCM.
--- DateTime: 2024/3/6 15:05:57
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMirrorYellSagaSow:LWnd
local UIMirrorYellSagaSow = LxWndClass("UIMirrorYellSagaSow", LWnd)
local YXTween = YXTween
local Tweening = DG.Tweening
local EaseInQuad = Tweening.Ease.InQuad

UIMirrorYellSagaSow.VIEW_TYPE_MIRRORCALL = 1		-- 魔镜召唤
UIMirrorYellSagaSow.VIEW_TYPE_HEARTCALL = 2		-- 心灵召唤
UIMirrorYellSagaSow.VIEW_TYPE_ITEM = 3			--道具召唤
UIMirrorYellSagaSow.VIEW_TYPE_ACTLIMITCALL = 4		-- 活动召唤

UIMirrorYellSagaSow.STATUS_0 = 0			-- 打开界面
UIMirrorYellSagaSow.STATUS_1 = 1			-- 点击请求数据
UIMirrorYellSagaSow.STATUS_2 = 2			-- 数据返回，界面可关闭
UIMirrorYellSagaSow.STATUS_3 = 3			-- 断网了
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMirrorYellSagaSow:UIMirrorYellSagaSow()
	self._mirrorCallSpineKey = "_mirrorCallSpineKey"

	self._heartCallSpineKey = "_heartCallSpineKey"

	self._mirrorCallRunTime = 2

	self._mirrorCallTimerKey = "_mirrorCallTimerKey"
	self._mirrorCallRefreshSpriteTimeKey = "_mirrorCallRefreshSpriteTimeKey"

	self._heartCallRunTime = 2
	self._heartCallTimerKey = "_heartCallTimerKey"

	self._delayTime = 1
	self._delayTimeKey = "self._delayTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMirrorYellSagaSow:OnWndClose()

	if self.delayTimer then
		LxTimer.DelayTimeStop(self.delayTimer)
		self.delayTimer = nil
	end

	self:CloseFunc()
	gModelGameHelper:RefreshGameSpeed()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMirrorYellSagaSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMirrorYellSagaSow:OnStart()
	LWnd.OnStart(self)
	gModelGameHelper:TemporaryCloseSpeed()
	self:InitUI()

	local viewType = self:GetWndArg("viewType") or UIMirrorYellSagaSow.VIEW_TYPE_MIRRORCALL
	self._viewType = viewType

	if gModelCallHero:IgnoreMirrorCallAni() then
		CS.ShowObject(self.mClickImg,false)
		CS.ShowObject(self.mJumpAniBtn,false)
	end

	self:RefreshViewShow()
	self:InitData()
	self:InitEff()

	self:InitEvent()
	self:InitMsg()
	self:RefreshView()
end

function UIMirrorYellSagaSow:InitHeartCallData()
	self._showRewardFunc = self:GetWndArg("showRewardFunc")
end

function UIMirrorYellSagaSow:InitActLimitCall()
	self._sid = self:GetWndArg("sid")
	self._activityData = self:GetWndArg("activityData")
    self._actCallBackFunc = self:GetWndArg("actCallBackFunc")
    self._getHeroList = self:GetWndArg("getHeroList")
end

function UIMirrorYellSagaSow:InitMirrorCallData()
	self._status = UIMirrorYellSagaSow.STATUS_0
	self._sendMsgFunc = self:GetWndArg("sendMsgFunc")
	self._mirrorCallEndFunc = self:GetWndArg("mirrorCallEndFunc")
	self._getHeroList = self:GetWndArg("getHeroList")

	--self._jumpMirrorAniStatus = gModelCallHero:GetMirrorCallHeroShowJumpAniStatus()
	self._jumpMirrorAniStatus = gModelCallHero:GetMirrorCallJumpAniStats()
	if self._extractType == 4 then
		self._jumpMirrorAniStatus = gModelRegression:GetRegressionCallJumpAniStats()
	end
end

function UIMirrorYellSagaSow:OnTcpReconnect()
	self._status = UIMirrorYellSagaSow.STATUS_3
end

function UIMirrorYellSagaSow:InitMsg()

	-- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
	 self:WndEventRecv(EventNames.ON_MOJING_RET,function(...)
		 self:OnMoJingRet(...)
	 end)
end

function UIMirrorYellSagaSow:RefreshHeartCallView()
	--local spine = self:FindWndSpineByKey(self._heartCallSpineKey)
	--if not spine then return end
	--local ani = ModelCallHero.HEART_CALL_EFFNAMELIST[self._callRefId]
	--spine:PlayAnimationSolid(ani,false)
	CS.ShowObject(self.mHeartCallEffRoot,true)
	self:OnClickTimer(self._heartCallTimerKey,self._heartCallRunTime)
end

function UIMirrorYellSagaSow:RefreshMirrorCallView()
	self:RefreshMirrorCallJumpStatus()
	self:RefreshMirrorCallShow()
	self:InitMirrorCallWnd()
	--self:ShowMirrorCallAni()
end

function UIMirrorYellSagaSow:_LoadMirrorCallSpine()
	---@param bgDpSpine LDisplaySpine
	self:CreateWndSpine(self.mSpineBgRoot,ModelCallHero.CALL_SPINE_BGNAME,ModelCallHero.CALL_SPINE_BGNAME,false,function(bgDpSpine)
		---@param dpSpine LDisplaySpine
		self:CreateWndSpine(self.mSpineRoot,ModelCallHero.CALL_SPINE_NAME,ModelCallHero.CALL_SPINE_NAME,false,function(dpSpine)

			local callRefId = self._callRefId

			self:OnClickTimer(self._mirrorCallTimerKey,5.3)


			CS.ShowObject(self.mSpineEffectBRoot,true)

			--- 做缩放
			local key = self.mSpineEffectBRoot:GetInstanceID()
			local seqCom = self:GetSeqCom()
			local seq = seqCom:CreateSeq(key)
			local floatTween = YXTween.TweenFloat(1, 1.5, 1.5, function(val)
				dpSpine:SetScale(val)
			end)
			seq:Append(floatTween)

			--- 2024/5/30: 都有震屏效果
			--if callRefId == ModelCallHero.CALL_TYPE_SPECIAL then
				--seq:Insert(3,self.mSpineEffectBRoot:DOShakePosition(1,20))
				local trans = dpSpine:GetDisplayTrans()
				local bigScale = 1.8
				local smallScale = 1.5
				local times = 0.1
				seq:Insert(3,trans:DOScale(Vector3(bigScale,bigScale,bigScale),times))
				seq:Insert(3 + times,trans:DOScale(Vector3(smallScale,smallScale,smallScale),times))
			--end

			seq:OnComplete(function()
				seqCom:DeleteSeq(key)
			end)
			seq:PlayForward()

			bgDpSpine:PlayAnimationSolid("idle",true)
			CS.ShowObject(self.mSpineBgRoot,true)
			dpSpine:SetAnimationCompleteFunc(function (ainName)
				if gModelCallHero:IgnoreMirrorCallAni() then
					self:RefreshMirrorCallView()
					self:OnClickHeroMirror()
				end
			end)
			local aniName = gModelCallHero:GetCallHeroSpineAni(callRefId)
			if LOG_INFO_ENABLED then
				printInfoNR2("召唤动画播放：","动画名字：" .. aniName)
			end
			dpSpine:PlayAnimationSolid(aniName,false)
			CS.ShowObject(self.mSpineRoot,true)
		end)
	end)
end

function UIMirrorYellSagaSow:OnMoJingRet(func,getHeroList)
	self._mirrorCallEndFunc = func
	self._status = UIMirrorYellSagaSow.STATUS_2
	getHeroList = getHeroList or {}
	self._getHeroList = getHeroList
	self:RefreshEffBg()
	self:RunMirrorCallAni()
end

function UIMirrorYellSagaSow:ChangeHeroBg(heroRefIdList)
	heroRefIdList = heroRefIdList or {}
	--printInfoN("#heroRefIdList = " .. #heroRefIdList)
	if #heroRefIdList < 1 then return end
	local dpEff = self:FindWndEffectByKey(self._mirrorCallSpineKey)
	if not dpEff then return end
	local dpTrans = dpEff:GetDisplayTrans()
	if not CS.IsValidObject(dpTrans) then return end
	local suipianTrans = self:FindWndTrans(dpTrans,"suipian")
	if not suipianTrans then return end
	local suipianIndexTrans
	local heroEffectRef,heroBookIcon
	local heroInfo,heroRefId
	for i = 1,10 do
		suipianIndexTrans = self:FindWndTrans(suipianTrans,tostring(i))
		if suipianIndexTrans and CS.IsValidObject(suipianIndexTrans) then
			heroInfo = heroRefIdList[i] or heroRefIdList[1]
			if heroInfo then
				heroRefId = heroInfo.itemId
				heroEffectRef = gModelHero:GetHeroShowRefByRefId(heroRefId)
				if heroEffectRef then
					heroBookIcon = heroEffectRef.iconBig
					--printInfoN("heroBookIcon = " .. heroBookIcon)
					self:SetWndSpriteRenderer(suipianIndexTrans,heroBookIcon)
				end
			end
		end
	end
end

function UIMirrorYellSagaSow:OnTimer(key)
	if key == self._mirrorCallTimerKey then
		--self:CloseFunc()

		if gModelCallHero:IgnoreMirrorCallAni() then
			self:RefreshMirrorCallView()
			self:OnClickHeroMirror()
		end

	elseif key == self._heartCallTimerKey then
		self:CloseFunc()
	elseif key == self._mirrorCallRefreshSpriteTimeKey then
	elseif key == self._delayTimeKey then
		self:WndClose()
	end
end

function UIMirrorYellSagaSow:ShowMirrorCallAni()
	local playMirrorAniKey = "playMirrorAniKey"
	local seqTween = self:TweenSeqFind(playMirrorAniKey)
	if seqTween then
		self:TweenSeqKill(playMirrorAniKey)
		seqTween = nil
	end
	seqTween = self:TweenSeqCreate(playMirrorAniKey, function(seq)
		local showTime = 0.5
		local moveY = self.mMirrorCallMirrorBg:DOLocalMoveY(0,showTime)
		seq:Append(moveY)
		local canvasGroup = self:GetCanvasGroup(self.mClickImg)
		if canvasGroup then
			local canvasShowTween = YXTween.TweenFloat(0, 1, showTime, function(ival)
				canvasGroup.alpha = ival
			end):SetEase(EaseInQuad)
			seq:Join(canvasShowTween)
		end
		local scaleTween = self.mMirrorCallMirrorBg:DOScale(Vector3(1,1,1),showTime)
		seq:Join(scaleTween)
		return seq
	end)
	seqTween:OnComplete(function()
		self:TweenSeqKill(playMirrorAniKey)
	end)

	seqTween:PlayForward()
end

function UIMirrorYellSagaSow:OnClickHeroMirror()
	local viewType = self._viewType
	if viewType == UIMirrorYellSagaSow.VIEW_TYPE_ITEM or viewType == UIMirrorYellSagaSow.VIEW_TYPE_ACTLIMITCALL then
		self:WndClose()
		return
	end
	if LOG_INFO_ENABLED then
		printInfoNR("打印而已，莫慌     当前状态:" .. self._status)
	end

	if self._status == UIMirrorYellSagaSow.STATUS_3 then
		self:WndClose()
		return
	end

	if self._status == UIMirrorYellSagaSow.STATUS_2 then
		self:WndClose()
		return
	end

	if self._status ~= UIMirrorYellSagaSow.STATUS_0 then
		return
	end

	if ModelCallHero.MIRRORCALLHERO_STATUS == 1 then
		self:RunMirrorCallAni()
		self._status = UIMirrorYellSagaSow.STATUS_2
	else
		if self._sendMsgFunc then
			self._sendMsgFunc()
		end
		self._status = UIMirrorYellSagaSow.STATUS_1
	end
end

function UIMirrorYellSagaSow:InitEvent()
	self:SetWndClick(self.mMirrorCallBg,function() self:OnClickHeroMirror() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMirrorCallMirrorBg,function() self:OnClickHeroMirror() end)

	self:SetWndClick(self.mJumpAniBtn,function() self:OnClickJumpAniBtnFunc() end)
	self:SetWndClick(self.mJumpAniBg,function() self:OnClickJumpAniBtnFunc() end)

	self:SetWndClick(self.mHeartCallBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHeartCallMaskBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

    self:SetWndClick(self.mActivityCallBg,function() self:OnClickHeroMirror() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mActivityCallMirrorBg,function() self:OnClickHeroMirror() end)
end
function UIMirrorYellSagaSow:InitItemCallHeroList()
	self._getHeroList = self:GetWndArg("getHeroList")
	self._callEndFunc = self:GetWndArg("callEndFunc")
end

function UIMirrorYellSagaSow:RunTime()
    local dpEff = self:FindWndEffectByKey(self._mirrorCallSpineKey)
    if not dpEff then
        self:WndClose()
        return
    end

	local dpTrans = dpEff:GetDisplayTrans()
	if not CS.IsValidObject(dpTrans) then
		self:WndClose()
		return
	end

	dpEff:SetVisible(true)


	local runTime = 2
	self:OnClickTimer(self._mirrorCallTimerKey,runTime)
end

function UIMirrorYellSagaSow:RefreshActLimitCallView()
    local activityData = self._activityData
    if not activityData then return end
    local config = activityData.config
    local image = config.image
    if not string.isempty(image) then
        self:SetWndEasyImage(self.mActivityCallBg,image,function()
            CS.ShowObject(self.mActivityCallBg,true)
        end)
    end
    local callMirrorImg = config.callMirrorImg
    if not string.isempty(callMirrorImg) then
        self:SetWndEasyImage(self.mActivityCallMirrorBg,callMirrorImg,function()
            CS.ShowObject(self.mActivityCallMirrorBg,true)
        end)
    end
end

function UIMirrorYellSagaSow:RefreshMirrorCallShow()
	local viewType = self._viewType
	if viewType == UIMirrorYellSagaSow.VIEW_TYPE_ITEM then
		CS.ShowObject(self.mMirrorCallBg,true)
		return
	end
    local callRefId = self._callRefId
    if not callRefId then return end
    local ref = gModelCallHero:GetCallRefByRefId(callRefId)
    if not ref then return end
    self:SetWndEasyImage(self.mMirrorCallBg,ref.bg,function()
		CS.ShowObject(self.mMirrorCallBg,true)
	end)
end

function UIMirrorYellSagaSow:RefreshEffBg()
	self:ChangeHeroBg(self._getHeroList)
end

function UIMirrorYellSagaSow:OnClickJumpAniBtnFunc()
	self._jumpMirrorAniStatus = not self._jumpMirrorAniStatus
	if self._extractType == 1 then
		gModelCallHero:SetMirrorCallJumpAniStats(self._jumpMirrorAniStatus)
	elseif self._extractType ==4 then
		gModelRegression:SetRegressionCallJumpAniStats(self._jumpMirrorAniStatus)
	end
	FireEvent(EventNames.ON_REFRESH_ANIJUMPSTATUS)
	self:RefreshMirrorCallJumpStatus()
end

function UIMirrorYellSagaSow:RefreshViewShow()
	local viewType = self._viewType
	if viewType == UIMirrorYellSagaSow.VIEW_TYPE_MIRRORCALL then
		CS.ShowObject(self.mMirrorCallView,true)
		self:SetWndText(self.mJumpAniBgTxt,ccClientText(18321))
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_HEARTCALL then
		CS.ShowObject(self.mHeartCallView,true)
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_ITEM then
		CS.ShowObject(self.mMirrorCallView,true)
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_ACTLIMITCALL then
		CS.ShowObject(self.mActivityCallView,true)
	end
end

function UIMirrorYellSagaSow:InitData()
	self._callRefId = self:GetWndArg("callRefId")
	self._callNum = self:GetWndArg("callNum")

	local extractType = self:GetWndArg("extractType")
	local ref = gModelCallHero:GetCallRefByRefId(self._callRefId)
	if not extractType then
		extractType = ref and ref.extractType or 1
	end
	self._extractType = extractType
	if ref and not string.isempty(ref.soundId) then
		if ref.type == 1 or ref.type == 2 or ref.type == 3 then
			self.delayTimer = LxTimer.DelayTimeCall(function()
				LxUiHelper.PlayAudioSoundName(ref.soundId)
			end, 1.8)
		else
			LxUiHelper.PlayAudioSoundName(ref.soundId)
		end
	end


	local viewType = self._viewType
	if viewType == UIMirrorYellSagaSow.VIEW_TYPE_MIRRORCALL then
		self:InitMirrorCallData()
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_HEARTCALL then
		self:InitHeartCallData()
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_ITEM then
		self:InitItemCallHeroList()
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_ACTLIMITCALL then
		self:InitActLimitCall()
	end
end

function UIMirrorYellSagaSow:OnClickTimer(key,time,isLoop)
	isLoop = isLoop and true or false

	local loopCnt = isLoop and -1 or 1

	self:TimerStop(key)
	self:TimerStart(key,time,true,loopCnt)
end

function UIMirrorYellSagaSow:RefreshMirrorCallJumpStatus()
	CS.ShowObject(self.mJumpAniBgGou,self._jumpMirrorAniStatus)
end


function UIMirrorYellSagaSow:InitMirrorCallWnd()
	CS.ShowObject(self.mMirrorCallEffRoot,false)
end

function UIMirrorYellSagaSow:RefreshView()
	local viewType = self._viewType
	if viewType == UIMirrorYellSagaSow.VIEW_TYPE_MIRRORCALL then
		if gModelCallHero:IgnoreMirrorCallAni() then
			--self:RefreshMirrorCallView()
			--self:OnClickHeroMirror()
		else
			if ModelCallHero.MIRRORCALLHERO_STATUS == 1 then
				self:RefreshEffBg()
			end
			self:RefreshMirrorCallView()
		end
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_HEARTCALL then
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_ACTLIMITCALL then
        self:RefreshActLimitCallView()
	end
end

function UIMirrorYellSagaSow:CloseFunc()
	local viewType = self._viewType
	if viewType == UIMirrorYellSagaSow.VIEW_TYPE_MIRRORCALL then
		if self._mirrorCallEndFunc then
			self._mirrorCallEndFunc()
		end
		self._mirrorCallEndFunc = nil
		self:OnClickTimer(self._delayTimeKey,self._delayTime,1)
		return
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_HEARTCALL then
		if self._showRewardFunc then
			self._showRewardFunc()
		end
		self._showRewardFunc = nil
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_ITEM then
		local _callEndFunc = self._callEndFunc
		if _callEndFunc then
			_callEndFunc()
		end
    elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_ACTLIMITCALL then
        if self._actCallBackFunc then
            self._actCallBackFunc()
        end
        self._actCallBackFunc = nil
	end
	self:WndClose()
end

function UIMirrorYellSagaSow:InitEff()
	local viewType = self._viewType
	if viewType == UIMirrorYellSagaSow.VIEW_TYPE_MIRRORCALL then
		--local callHero = self._callNum == 1 and "fx_ui_ZH" or "fx_ui_posuizhaohuan"
		if ModelCallHero.TYPE_SHOW_STATE == 0 then
			local callHero = "fx_ui_yuwangchoujiang_putong"
			self:CreateWndEffect(self.mMirrorCallEffRoot,callHero,self._mirrorCallSpineKey,100,false,false,50,function(dpTrans)
				dpTrans.gameObject:SetActive(true)
				if gModelCallHero:IgnoreMirrorCallAni() then
					self:RefreshMirrorCallView()
					self:OnClickHeroMirror()
				end
			end)
		else
			CS.ShowObject(self.mMirrorCallEffRoot,false)

			local callRefId = self._callRefId
			local effName = gModelCallHero:GetMirrorCallBgAniEff(callRefId)
			self:CreateWndEffect_Ex({
				trans = self.mSpineEffectBRoot,
				effName = effName,
				effKey = effName,
				endFunc = function()
					self:_LoadMirrorCallSpine()
				end ,
			})
		end
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_HEARTCALL then
		local callHero = "fx_ui_yuwangchoujiang_putong"
		self:CreateWndEffect(self.mHeartCallEffRoot,callHero,self._heartCallSpineKey,100,false,false,50,function(dpTrans)
			dpTrans.gameObject:SetActive(true)
			self:RefreshHeartCallView()
		end)
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_ITEM then
		local callHero = "fx_ui_posuizhaohuan"
		self:CreateWndEffect(self.mMirrorCallEffRoot,callHero,self._mirrorCallSpineKey,100,false,false,50,function(dpTrans)
			dpTrans.gameObject:SetActive(true)
			self:RefreshEffBg()
			if gModelCallHero:IgnoreMirrorCallAni() then
				self:RefreshMirrorCallView()
				self:RunMirrorCallAni()
			end
		end)
	elseif viewType == UIMirrorYellSagaSow.VIEW_TYPE_ACTLIMITCALL then
		local callHero = self._callNum == 10 and "fx_ui_posuizhaohuan" or "fx_ui_ZH"
		self:CreateWndEffect(self.mActivityEffRoot,callHero,self._mirrorCallSpineKey,100,false,false,50,function(dpTrans)
			dpTrans.gameObject:SetActive(true)
			self:RefreshEffBg()
            self:ShowMirrorCallAni()
            self:RunMirrorCallAni()
		end)
	end
end

function UIMirrorYellSagaSow:RunMirrorCallAni()
	if self._jumpMirrorAniStatus then
		self:WndClose()
	else
		--self:RefreshEffBg()
		CS.ShowObject(self.mMirrorCallEffRoot,true)
		self:RunTime()
	end
end
------------------------- List -------------------------


------------------------- List -------------------------

------------------------------------------------------------------
return UIMirrorYellSagaSow



