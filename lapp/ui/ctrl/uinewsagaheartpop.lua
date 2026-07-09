---
--- Created by BY.
--- DateTime: 2023/10/19 15:10:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UINewSagaHeartPop:LWnd
local UINewSagaHeartPop = LxWndClass("UINewSagaHeartPop", LWnd)
local LUIHeroObject = LxRequire("LApp.UI.Display.LUIHeroObject")
local LUISpineSpCtrl = LxRequire("LApp.UI.Display.LUISpineSpCtrl")
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UINewSagaHeartPop:UINewSagaHeartPop()
	self._timeKey = "_UINewSagaHeartPop__timeKey"
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UINewSagaHeartPop:OnWndClose()
	if self.uiSpineSpCtrl then
		self.uiSpineSpCtrl:Destroy()
		self.uiSpineSpCtrl = nil
	end
	if self.dpSpine then
		self.dpSpine:Destroy()
		self.dpSpine = nil
	end

	self:TimerStop(self._timeKey)
	gLGameAudio:StopSingleSound()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UINewSagaHeartPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UINewSagaHeartPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UINewSagaHeartPop:OnClickClose()
	if not self.canClose then
		if self.spineObj then
			self:PlayFadeAni()
			self.uiSpineSpCtrl:StopPlayTween()
			self.uiSpineSpCtrl:ResetPlayPos()
			self.spineObj:PlayIdleAni()
		end
		if self.dpSpine then
			self.dpSpine:PlayAnimation(0, "idle", false)
			self:PlayFadeAni()
		end
		self.canClose = true
		gLGameAudio:StopSingleSound()
		return
	end
	self:WndClose()
end

function UINewSagaHeartPop:PlayFadeAni()
	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("delayFreeze")
	local canvasGroup = self.mUI:GetComponent(typeof(UnityEngine.CanvasGroup))
	local alphaTween = canvasGroup:DOFade(1, 1.5):SetEase(DG.Tweening.Ease.InSine)
	seq:Insert(0, alphaTween)
	seq:PlayForward()
end

function UINewSagaHeartPop:SetTime()
	local activityData = gModelActivity:GetActivityBySid(self._sid)
	if not activityData then return end
	local endTime = activityData.endTime
	if endTime == 0 then
		self:TimerStop(self._timeKey)
		self:SetWndText(self.mTimeText, ccClientText(18404))
		return
	end
	local time = GetTimestamp()
	local timespan = endTime - time
	local timeStr = ""
	if (timespan < 0) then
		timeStr = ccClientText(14301)
		self:TimerStop(self._timeKey)
	else
		timeStr = LUtil.FormatTimespanCn(timespan)
		timeStr = string.replace(ccClientText(18400), timeStr)
	end
	self:SetWndText(self.mTimeText, timeStr)
end

function UINewSagaHeartPop:OnActivityConfigData()
	local activityData = gModelActivity:GetWebActivityDataById(self._sid)
	if not activityData then return end
	local data = activityData.config
	self._uniqueJump = data.uniqueJump1
	self.playAction = data.action


	if not string.isempty(data.adverTitle) then
		self:SetWndEasyImage(self.mTitle, data.adverTitle, nil, true)
	end
	if not string.isempty(data.adverTitlePos) then
		local pos = LxDataHelper.ParseVector2NotEmpty(data.adverTitlePos)
		self:SetAnchorPos(self.mTitle, pos)
	end
	if not string.isempty(data.denseFog) then
		local info = string.split(data.denseFog, ";")
		for i, v in ipairs(info) do
			local tran = CS.FindTrans(self.mFogObj, "Fog" .. i)
			if tran then
				local fogData = string.split(v, "=")
				self:SetWndEasyImage(tran, fogData[1], nil, true)
				self:SetAnchorPos(tran, LxDataHelper.ParseVector(fogData[2]))
				CS.ShowObject(tran, true)
			end
		end
	end
	if not string.isempty(data.actionSound) then
		self.sound = data.actionSound
	end
	if data.adHeroSpine then
		local ref = gModelHero:GetShowEffectById(data.adHeroSpine)
		if ref and not string.isempty(ref.prefabName) then
			self:CreateWndSpine(self.mSpineRoot, ref.prefabName, "prefabName", false)
		else
			CS.ShowObject(self.mSpineRoot, false)
		end
	else
		CS.ShowObject(self.mSpineRoot, false)
	end
	if not string.isempty(data.adverHero) then
		local arr = string.split(data.adverHero, "|")
		local ref = gModelHero:GetShowEffectById(tonumber(arr[1]))
		if not string.isempty(self.playAction) then
			if self.playAction == "1" or self.playAction == 1 then
				if not self.spineObj then
					local spineObj = LUIHeroObject:New(self)
					self.spineObj = spineObj
					local initPos = self.mHeroSpine.anchoredPosition
					spineObj:Create(self.mHeroSpine, "mHeroSpine", ref.heroDrawing)
					spineObj:SetScale(arr[2])
					spineObj:ShowHero(true)
					spineObj:SetLoadedFunction(function()
						if self.clickOpen then
							self:PlayFadeAni()
							self.canClose = true
							return
						end
						local uiSpineSpCtrl = LUISpineSpCtrl:New()
						self.uiSpineSpCtrl = uiSpineSpCtrl
						local cbFunction = function()
							if not self:IsWndValid() then return end
							self:PlayFadeAni()
							uiSpineSpCtrl:ResetPlayPos()
							spineObj:PlayIdleAni()
							self.canClose = true
						end
						uiSpineSpCtrl:StartPlayTween({
							type = 2,
							uiHeroObj = spineObj,
							bgImgTrans = self.mHeroBgImg,
							closeUpRefId = tonumber(ref.heroCloseUpSpAction) or 1,
							initPos = initPos,
							cb = cbFunction
						})
						if self.sound then
							gLGameAudio:PlaySingleSound(self.sound)
						end
					end)
					spineObj:StartLoad()
				end
			else
				if not self.dpSpine then
					local dpSpine = LDisplaySpine:New()
					self.dpSpine = dpSpine
					dpSpine:CreateSpine(self.mHeroSpine, ref.heroDrawing, LDisplaySpine.TYPE_UI)
					dpSpine:SetScale(arr[2])
					dpSpine:SetLoadedFunction(function()
						if self.clickOpen then
							self:PlayFadeAni()
							self.canClose = true
							return
						end
						dpSpine:PlayAnimation(0, self.playAction, false)
						if self.sound then
							gLGameAudio:PlaySingleSound(self.sound)
						end
					end)
					dpSpine:SetAnimationCompleteFunc(function()
						if self.clickOpen then
							return
						end
						dpSpine:PlayAnimation(0, "idle", false)
						self:PlayFadeAni()
						self.canClose = true
					end)
					dpSpine:StartLoad()
				end
			end
		end

		if not string.isempty(data.adverHeroPos) then
			local pos = LxDataHelper.ParseVector2NotEmpty(data.adverHeroPos)
			self:SetAnchorPos(self.mHeroSpine, pos)
		end
		if ref then
			local heroRef = gModelHero:GetHeroRef(ref.heroType)
			if heroRef then
				local name = ccLngText(ref.name)
				local raceType = heroRef.raceType
				local careerType = heroRef.careerType

				local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
				local careerRef = gModelHero:GetCareerRefByRefId(careerType)
				local careerName = ccLngText(careerRef.name)
				local location = string.format("[%s]", ccLngText(ref.location))
				location = LUtil.FormatColorStr(location, "#68e6ac")

				self:SetWndEasyImage(self.mRaceIcon, raceRef.icon)
				self:SetWndEasyImage(self.mQuality, heroRef.qualityIcon)
				self:SetWndText(self.mHeroNameText, name)
				self:SetWndText(self.mHeroJobText, ccLngText(ref.nickName))
				self:SetWndText(self.mSmallText, careerName .. location)


				if self._isEnus then
					self:InitTextSizeWithLanguage(self.mSmallText,-4)
				end

				if not string.isempty(ref.skinSpineHd) then
					self:CreateWndSpine(self.mHeroBgHd, ref.skinSpineHd, "skinSpineHd", false)
				end
				if not string.isempty(ref.skinSpineBg) then
					self:CreateWndSpine(self.mHeroBg, ref.skinSpineBg, "skinSpineBg", false)
				elseif not string.isempty(ref.skinBg) then
					self:SetWndEasyImage(self.mHeroBgImg, ref.skinBg)
				else
					self:SetWndEasyImage(self.mHeroBgImg, ref.heroBg)
				end
			end
		end
	end

	self:TimerStop(self._timeKey)
	self:TimerStart(self._timeKey, 1, false, -1)
	self:SetTime()
end

function UINewSagaHeartPop:InitCommand()
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndText(self.mToggleText, ccClientText(10155))

	local sid = self:GetWndArg("sid")
	self.clickOpen = self:GetWndArg("clickOpen")
	self.canClose = false

	self._sid = sid
	local bool = gModelGeneral:FindAlertId(sid)
	self:SetWndToggleValue(self.mToggle, bool)
	gModelActivity:ReqActivityConfigData(sid)
end

function UINewSagaHeartPop:OnClickJump()
	local jump = self._uniqueJump
	gModelFunctionOpen:Jump(jump, self:GetWndName())
end

function UINewSagaHeartPop:OnTimer(key)
	if (key == self._timeKey) then
		self:SetTime()
	end
end

function UINewSagaHeartPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:OnClickClose() end)
	self:SetWndClick(self.mBtnJump, function(...) self:OnClickJump() end)
end

function UINewSagaHeartPop:InitMessage()
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(...) self:OnActivityConfigData(...) end)
	self:SetWndToggleDelegate(self.mToggle, function(value)
		if value then
			gModelGeneral:SetAlertId(self._sid)
		else
			gModelGeneral:ClearAlertId(self._sid)
		end
	end)
end

------------------------------------------------------------------
return UINewSagaHeartPop