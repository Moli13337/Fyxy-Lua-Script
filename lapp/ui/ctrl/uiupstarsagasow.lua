---
--- Created by Administrator.
--- DateTime: 2023/10/24 12:04:34
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIUpStarSagaSow:LWnd
local UIUpStarSagaSow = LxWndClass("UIUpStarSagaSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIUpStarSagaSow:UIUpStarSagaSow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIUpStarSagaSow:OnWndClose()
	self:ClearTimer()
	--self:ClearTimer(self._timerClick)
	if self._func then self._func() end

	FireEvent(EventNames.ON_HERO_SHOW_WND_CLOSE,self._refId)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIUpStarSagaSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIUpStarSagaSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:CreateWndEffect(self.mBg,"fx_ui_ZH_2","fx_ui_ZH_2",100,true,false)
	self:InitData()
	self:PlayYuanAni()
	self:InitEvent()
	self:ClearTimer()
    LxUiHelper.PlayAudioSoundName(LSoundConst.TRIGGER_CALL_HERO_RARE)
	self._timer = LxTimer.LoopTimeCall(function()
		self:RefreshView()
	end, 0.4, false, 1)

--[[	self:ClearTimer(self._timerClick)
	self._timerClick = LxTimer.LoopTimeCall(function()
		self._clickClose = true
	end, 0.8, false, 1)]]
end

function UIUpStarSagaSow:ClearTimer(timeData)
	local timer = timeData or self._timer
	if timer then
		LxTimer.LoopTimeStop(timer)
		self._timer = nil
	end
end

function UIUpStarSagaSow:InitData()
	self._func = self:GetWndArg("func")
	local refId = self:GetWndArg("refId")
	self._refId = refId

	local star = gModelHero:GetHeroInitStarByRefId(refId)
	self._star = star
	self._heroEffId = gModelHero:GetHeroEffectByRefId(refId,star)

	gModelHero:PlayHeroRoleSound(refId, self._heroEffId)

	self._playKey = "moveYuan"
	self._clickClose = true

	self._bgList = {
		[4] = "callhero_bg_big_6",
		[5] = "callhero_bg_big_7",
	}
	self._botImgList = {
		[4] = "callhero_line_2",
		[5] = "callhero_line_3",
	}
	self._lineImgList = {
		[4] = "callhero_line_5",
		[5] = "callhero_line_6",
	}
	self._starList = {
		self.mStar1,
		self.mStar2,
		self.mStar3,
		self.mStar4,
		self.mStar5,
	}
	local bg
	local ref = gModelHero:GetHeroRef(refId)
	if ref then
		local quality = ref.quality
		local qualityRef = gModelItem:GetQualityRef(quality)
		if qualityRef then
			bg = qualityRef.callHeroShow
		end
	end
	if not bg then
		bg = self._bgList[star]
	end
	if bg then
		self:SetWndEasyImage(self.mBg,bg,function()
			CS.ShowObject(self.mBg,true)
		end)
	end
	bg = self._botImgList[star]
	if bg then
		self:SetWndEasyImage(self.mBotDescBg1,bg)
		self:SetWndEasyImage(self.mBotDescBg2,bg,function()
			CS.ShowObject(self.mBotDescBg,true)
		end)
	end
	bg = self._lineImgList[star]
	if bg then
		self:SetWndEasyImage(self.mTopLine1,bg)
		self:SetWndEasyImage(self.mTopLine2,bg,function()
			CS.ShowObject(self.mTopLine,true)
		end)
	end
end

function UIUpStarSagaSow:InitEvent()
	self:SetWndClick(self.mBg,function() self:CloseWnd() end)
	self:SetWndClick(self.mLookBtn,function()
		--GF.OpenWndTop("UISagaStarPre",{refId = self._refId})
		gModelGeneral:OpenHeroStarPre({refId = self._refId},1)
	end)
	self:SetWndClick(self.mBotDescBg,function() self:CloseWnd() end)

	self:SetWndClick(self.mENLookBtn,function ()
		gModelGeneral:OpenHeroStarPre({refId = self._refId},1)
	end)
end

function UIUpStarSagaSow:CloseWnd()
	if self._clickClose then
		self:WndClose()
	end
end


function UIUpStarSagaSow:PlayYuanAni()
	local seqTween
	self:TweenSeqKill(self._playKey)
	if not seqTween then
		local showTime = 18
		seqTween = self:TweenSeqCreate(self._playKey,function(seq)
			local moveZ = self.mYuan.transform:DORotate(Vector3.New(0,0,180),showTime)
			seq:Append(moveZ)
			return seq
		end)
	end
	seqTween:SetLoops(-1,DG.Tweening.LoopType.Restart)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(self._playKey)
	end)
end

function UIUpStarSagaSow:OnAwake()
	local delay = gModelGuide:GetGuidePara("heroDelay")
	self:DelaySendFinish(delay)
end

function UIUpStarSagaSow:RefreshView()

	local refId,star = self._refId,self._star
	--
	local starEffectList = {
		[4] = "fx_ui_ZHJS_zise_xingdian",
		[5] = "fx_ui_ZHJS_chengse_xingdian",
	}
	local starHuoxingEffectList = {
		[5] = "fx_ui_ZHJS_chengse_huoxing",
	}

	local ref = gModelHero:GetHeroRef(refId)
	local starEffect
	if ref then
		local quality = ref.quality
		local qualityRef = gModelItem:GetQualityRef(quality)
		if qualityRef then
			starEffect = qualityRef.callHeroShowEff
		end
	end
	if not starEffect then
		starEffect = starEffectList[star]
	end
	if starEffect then
		self:CreateWndEffect(self.mTopEffect,starEffect,starEffect,100,true,false)
	end
	local huoxing = starHuoxingEffectList[star]
	if huoxing then
		self:CreateWndEffect(self.mHeroPb,huoxing,huoxing,100,true,false)
	end

	local showEngDiv = gLGameLanguage:IsForeignVersion()

	if ref then
		local typeId = gModelHero:GetHeroType(refId)
		local typeImg = gModelHero:GetRaceImgByRefId(typeId)
		if typeImg then
			self:SetWndEasyImage(self.mTypeImg,typeImg,function()
				CS.ShowObject(self.mTypeImg,true)
			end)
		end
		local careerType = ref.careerType
		local careerRef = gModelHero:GetCareerRefByRefId(careerType)
		local jobNameBg = careerRef.jobNameBg
		local jobNameBg1 = careerRef.jobNameBg1
		local jobBgTrans = showEngDiv and self.mENJobBg or self.mJobBg
		local jobImgTrans = showEngDiv and self.mENJobImg or self.mJobImg
		self:SetWndEasyImage(jobImgTrans,jobNameBg,function()
			CS.ShowObject(jobImgTrans,true)
		end)
		self:SetWndEasyImage(jobBgTrans,jobNameBg1,function()
			CS.ShowObject(jobBgTrans,true)
		end)

		CS.ShowObject(self.mCHDiv,not showEngDiv)
		CS.ShowObject(self.mENDiv,showEngDiv)
--[[		self:SetWndEasyImage(self.mJobImg,jobNameBg,function()
			CS.ShowObject(self.mJobImg,true)
		end)]]
	end
	local starImg,showNum = gModelHero:GetHeroStarImg(star)
	for i,v in ipairs(self._starList) do
		if i <= showNum then
			self:SetWndEasyImage(v,starImg)
		end
		CS.ShowObject(v,i <= showNum)
	end
	local heroEffectRef = gModelHero:GetShowEffectById(self._heroEffId)
	if heroEffectRef then
		local heroDrawing = heroEffectRef.heroDrawing
		--local heroDrawingImage = heroEffectRef.heroDrawingImage
		local heroDrawingImage = nil
		if not string.isempty(heroDrawing) then
			self:CreateWndSpine(self.mHeroPb,heroDrawing,heroDrawing,false,function(dpSpine)
				--dpSpine:SetScale(2.5)
			end)
		elseif not string.isempty(heroDrawingImage) then
			local bgTrans = self.mHeroImg
			self:SetWndEasyImage(bgTrans,heroDrawingImage,function()
				local csImage = self:FindWndImage(bgTrans)
				csImage:SetNativeSize()
				CS.ShowObject(bgTrans,true)
			end)
		end
		local name = ccLngText(heroEffectRef.name)
		self:SetWndText(self.mHeroName,name)
		local callLocation = ccLngText(heroEffectRef.location)
		local locationTrans = showEngDiv and self.mENLocationTxt or self.mLocationTxt
		self:SetWndText(locationTrans,callLocation)
		local callDesc = ccLngText(heroEffectRef.callDesc)
		self:SetWndText(self.mDescTxt,callDesc)
	end
end

------------------------------------------------------------------
return UIUpStarSagaSow


