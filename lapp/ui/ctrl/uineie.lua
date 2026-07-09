---
--- Created by admin-pc.
--- DateTime: 2024/4/10 16:23:48
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UINeie:LWnd
local UINeie = LxWndClass("UINeie", LWnd)
------------------------------------------------------------------

local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)

---@type LUISpineSpCtrl
local LUISpineSpCtrl = LxRequire("LApp.UI.Display.LUISpineSpCtrl")

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UINeie:UINeie()
	---@type table<string, LUISpineSpCtrl>
	self._uiSpineCtrlDic = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UINeie:OnWndClose()
	if self._uiSpineCtrlDic then
		for k,v in pairs(self._uiSpineCtrlDic) do
			v:Destroy()
		end
		self._uiSpineCtrlDic = nil
	end

	self:ClearPool()
	if self._lastSound then
		gLGameAudio:OnCloseWndMusic(self:GetWndName())
	end
	gModelGameHelper:RefreshGameSpeed()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UINeie:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UINeie:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	gModelGameHelper:TemporaryCloseSpeed()

	gLGpManager:FindNewbieGp():OnWndLoaded(true)

	self._seqCom = SequenceCom:New()
	self:CreatePool()

	self:SetWndClick(self.mSkipBtn,function ()
		self:OnClickSkip()
	end)

	self:SetWndClick(self.mTalkClick, function()
		self:TryFinishedTalk()
	end)

	self:SetWndClick(self.mClick, function()
		self:OnClickNextEvent()
	end)

	CS.ShowObject(self.mBlack,false)
	CS.ShowObject(self.mTalk, false)
	CS.ShowObject(self.mTalkClick ,false)
	CS.ShowObject(self.mClick, false)

	self:OnWndRefresh()

end

function UINeie:TryFinishedTalk()
	if self._talkState then
		self:FinishedTalk()
	elseif self._talkEventId then
		self:HideTalk(self._talkEventId)
	end
end

function UINeie:OnClickNextEvent()
	if self._waitClickEvent and self._waitClickEvent > 0 then
		local eventId = self._waitClickEvent
		self._waitClickEvent = nil
		if self._waitSetId then
			if self._waitClickType == 1 then
				local aniName = self._waitClickAni or "click_demo"
				for k,v in ipairs(self._waitSetId) do
					local effectKey = "uieff_"..v
					local spine = self:FindWndSpineByKey(effectKey)
					if spine then
						spine:PlayAnimation(0,aniName)
					end
				end
			elseif self._waitClickType == 2 then
				local aniName = self._waitClickAni or 0
				for k,v in ipairs(self._waitSetId) do
					local effectKey = "uieff_"..v
					local spine = self:FindWndSpineByKey(effectKey)
					if spine then
						local uiSpineSpCtrl = LUISpineSpCtrl:New()
						local old = self._uiSpineCtrlDic[effectKey]
						if old then
							old:Destroy()
						end
						self._uiSpineCtrlDic[effectKey] = uiSpineSpCtrl
						uiSpineSpCtrl:StartPlayTween({
							type = 1,
							trans = spine:GetDisplayTrans(),
							bgTrans = nil,
							spine = spine,
							closeUpRefId = aniName
						})
					end
				end
			end
		end

		CS.ShowObject(self.mClick, false)
		self:DoEventEnd(eventId)
	end
end

function UINeie:HideFinger(objId)
	if objId~= self._objId then
		return
	end
	if self._fingerEff then
		self:DestroyWndEffectByKey(self._fingerEff)
		self._fingerEff = nil
	end
end


function UINeie:DoEventEnd(eventId)
	if gLGpManager then gLGpManager:FindNewbieGp():OnEventEnd(eventId) end
end

function UINeie:HideEvent()
	local cfg = gModelPlot:GetStoryNewbieRef(self._eventId)
	local setRef = gModelPlot:GetStorySetRef(cfg.set)
	local type = cfg.type
	if type == LNewbieEventType.TALK then

	end
end

function UINeie:ShowBg(ref, animationData, endTime)
	local eventId = self._eventId
	local scale = ref.scaling
	local vPos = LxDataHelper.ParseVector2(ref.coord, ",")

	local bg = self._bgRootPool:GetObj()
	bg:SetParent(self.mBgRoot, false)
	local key = "uibg_"..tostring(ref.refId)
	self._useedRootList[key] = bg

	local imageName = ref.image
	local isNative = true
	if imageName == "black" then
		bg.localScale = Vector3.one
		bg.localPosition = Vector3(0, 0, 0)
		bg.anchorMin = Vector2.zero
		bg.anchorMax = Vector2.one
		bg.pivot = Vector2(0.5, 0.5)
		bg.offsetMin = Vector2.zero
		bg.offsetMax = Vector2.zero
		isNative = false
	else
		bg.localScale = Vector3(scale, scale, scale)
		bg.anchoredPosition = vPos
		bg.anchorMin = Vector2(0.5,0.5)
		bg.anchorMax = Vector2(0.5,0.5)
		bg.sizeDelta = Vector2(640, 1400)
		isNative = false
	end

	self:SetWndEasyImage(bg, ref.image, nil, isNative, true,nil,nil)

	local seq = self:GetSeqCom()
	seq:DeleteSeq(key)

	local fadeTime = 0
	local fade = 0
	local stayTime = 0
	if animationData then
		fadeTime = animationData.fadeTime
		fade =animationData.fade
		stayTime = animationData.stay
	end
	local bgCanvasGroup = bg:GetComponent(typeofCanvasGroup)
	if fade > 0 then

		--填了事件参数，做动画
		bgCanvasGroup.alpha = 0
		--淡入显示
		local sequence = seq:CreateSeq(key)
		sequence:Append(bgCanvasGroup:DOFade(1, fadeTime))
		sequence:OnComplete(function()
			self._seqCom:DeleteSeq(key)
		end)
		sequence:PlayForward()
	else
		--直接显示
		bgCanvasGroup.alpha = 1
	end

	if stayTime or stayTime > 0 then
		local bgendKey = "bgend_"..eventId
		local sequence = seq:CreateSeq(bgendKey)
		sequence:AppendInterval(stayTime)
		sequence:OnComplete(function()
			self._seqCom:DeleteSeq(bgendKey)
			self:DoEventEnd(eventId)
		end)
		sequence:PlayForward()
	else
		self:DoEventEnd(eventId)
	end
end

function UINeie:OnWndRefresh()
	local operType = self:GetWndArg("operType")
	local eventId = self:GetWndArg("eventId")
	self._eventId = eventId
	if operType == 1 then
		self:ShowEvent()
	elseif operType == 2 then
		self:HideEvent()
	end
end


function UINeie:ShowFinger(pos,objId)
	if self._fingerEff then
		return
	end
	--printInfoN("ShowFinger")
	self._objId = objId
	local effName = "fx_ui_shou_2"
	self._fingerEff  = "fingerEff"
	self:CreateWndEffect(self.mFingerRoot,effName,self._fingerEff,80)
	local sceneCam = gLGameScene:GetCurrentSceneCamera()
	local uiCam = LGameUI.GetUICamera()
	local screenPos = sceneCam:WorldToScreenPoint(pos)
	local uiPos = uiCam:ScreenToWorldPoint(screenPos)
	self.mFingerRoot.position = uiPos
end

function UINeie:DoShowEffect(ref, speed, animationData, isLoop)
	local eventId = self._eventId
	local setId = ref.refId
	local effectKey = "uieff_"..setId
	local effect = ref.image
	local scale = ref.scaling
	local vPos = LxDataHelper.ParseVector2(ref.coord, ",")
	local effectType = ref.imageType

	local root = self._effRootPool:GetObj()
	local rectTran = root.transform
	rectTran:SetParent(self.mEffRoot,false)
	rectTran.localScale = Vector3(scale,scale,scale)
	rectTran.anchoredPosition = vPos

	self._useedRootList[effectKey] = root

	--淡入动画
	local fadeTime = 0
	local stay = 0
	local fade = 0
	if animationData then
		fadeTime = animationData.fadeTime
		stay = animationData.stay
		fade = animationData.fade
	end

	local canvasGroup = rectTran:GetComponent(typeofCanvasGroup)
	canvasGroup.alpha = 1
	local sequence = self._seqCom:CreateSeq(effectKey)
	sequence:AppendInterval(stay)

	sequence:OnComplete(function()
		self._seqCom:DeleteSeq(effectKey)
		if not isLoop then

			self:HideEffect(setId, effectType)
		end
		self:DoEventEnd(eventId)
	end)

	if effectType == 1 then
		if fade > 0 then
			canvasGroup.alpha = 0
			sequence:Insert(0,canvasGroup:DOFade(1, fadeTime))
		end

		self:CreateWndEffect_Ex({effKey = effectKey,effName = effect, trans = rectTran, endFunc = function(dpEff)
			if self:IsDestroy() then return end
			if speed and speed ~= 1 and speed > 0 then
				dpEff:SetSpeed(speed)
			end
			sequence:PlayForward()
		end})


	elseif effectType == 3 then
		local dp = self:CreateWndSpine(rectTran,effect,effectKey, nil , function(dpSpine)
			if self:IsDestroy() then return end
			if speed and speed ~= 1 and speed > 0 then
				dpSpine:SetAnimationTimeScale(speed)
			end
		end, false, true)

		if fade > 0 then
			if dp then
				dp:SetAlpha(0)
				local canvasShowTween = YXTween.TweenFloat(0, 1, fadeTime, function(ival)
					dp:SetAlpha(ival)
				end)
				sequence:Insert(0,canvasShowTween)
			end
		end
		sequence:PlayForward()
	end
end

function UINeie:ShowEvent()
	local eventId = self._eventId

	local cfg = gModelPlot:GetStoryNewbieRef(eventId)
	local setRef = gModelPlot:GetStorySetRef(cfg.set)
	local animationData = self:ParseAnimationData(cfg.aniparam)
	local type = cfg.type
	local parameter = cfg.parameter

	local sound = setRef and setRef.sound or nil
	local isRemoveSound = false

	if type == LNewbieEventType.BG then
		local params = LxDataHelper.ParseNumber_Sign(parameter, "=")
		local isShow = checknumber(params[1]) > 0
		if isShow then
			self:ShowBg(setRef, animationData)
		else
			self:HideBg(setRef, animationData)
			isRemoveSound = true
		end
	elseif type == LNewbieEventType.BLACK then
		local params = LxDataHelper.ParseNumber_Sign(parameter, "=")
		self:ShowBlack(params[1] or 0, params[2] or 0)

	elseif type == LNewbieEventType.ONCE_EFFECT then
		local speed = tonumber(parameter) or 1
		self:DoShowEffect(setRef, speed, animationData)
	elseif type == LNewbieEventType.LOOP_EFFECT then
		local params = LxDataHelper.ParseNumber_Sign(parameter, "=")
		local isShow = (params[1] or 0) > 0
		if isShow then
			local speed = tonumber(parameter) or 1
			self:DoShowEffect(setRef, speed, animationData,true)
		else
			self:DoHideEffect(setRef, animationData)
			isRemoveSound = true
		end
	elseif type == LNewbieEventType.SPECIAL then
		local params = string.split(parameter, "=")
		local specialType = checknumber(params[1])
		local aniName = params[2]
		if specialType == 2 then
			self._waitClickEvent = self._eventId
			self._waitSetId = string.split(params[3] or "", "|") or {}
			self._waitClickAni = aniName
			self._waitClickType = 1
			CS.ShowObject(self.mClick, true)
		elseif specialType == 3 then
			self._waitClickEvent = self._eventId
			self._waitSetId = string.split(params[3] or "", "|") or {}
			self._waitClickAni = tonumber(aniName)
			self._waitClickType = 2
			CS.ShowObject(self.mClick, true)
		else
			self:ShowSpecialSpine(specialType, setRef, animationData)
		end
		if specialType == 0 then
			isRemoveSound = true
		end
	elseif type == LNewbieEventType.TALK then
		local params = LxDataHelper.ParseNumber_Sign(parameter, "=")
		local ref = gModelPlot:GetStoryTextRef(params[1])
		self:ShowTalk(ref, params[2], animationData)
	end

	if not string.isempty(sound) then
		if isRemoveSound and self._lastSound == sound then
			self._lastSound = nil
			if gLGameAudio then
				gLGameAudio:OnCloseWndMusic(self:GetWndName())
			end
		else
			self._lastSound = sound
			gLGameAudio:OnPlayWndMusic(sound, self:GetWndName())
		end
	end
end

function UINeie:FinishedTalk()
	self._talkState = nil
	self.mTalkText.maxVisibleCharacters = 99999
end

function UINeie:ShowTalk(ref, time, aniTimeData)
	time = time or 0

	local stayTime = aniTimeData and aniTimeData.stay
	if stayTime == 0 then
		stayTime = 0.01
	end

	local eventId = self._eventId
	self._talkEventId = eventId
	self._talkState = 1

	local words = ccLngText(ref.text)
	local textInfo = self.mTalkText:GetTextInfo(words)
	local count = textInfo.characterCount
	CS.ShowObject(self.mTalk, true)
	CS.ShowObject(self.mTalkClick, true)
	self.mTalkText.maxVisibleCharacters = 0
	self:SetWndText(self.mTalkText.transform, words)
	local soundP = ref.soundP
	if not string.isempty(soundP) then
		if gLGameAudio then gLGameAudio:PlaySingleSound(soundP) end
	end
	local sequence = self._seqCom:CreateSeq("_talkKey")
	if time > 0 then
		local tween = YXTween.TweenFloat(0, 1, time, function(ival)
			if self._talkState then
				if ival == 1 then
					ival = count
					self._talkState = nil
				else
					ival = math.floor(ival * count)
				end
				self.mTalkText.maxVisibleCharacters = ival
			end
		end)
		sequence:Append(tween)
	else
		self._talkState = nil
		self.mTalkText.maxVisibleCharacters = count
	end
	sequence:AppendInterval(stayTime)
	sequence:OnComplete(function()
		self:FinishedTalk()
		self:HideTalk(eventId)
	end)
	sequence:PlayForward()
end

function UINeie:DoHideEffect(ref, animationData)
	local eventId = self._eventId
	local setId = ref.refId
	local effectKey = "uieff_"..setId
	local effectType = ref.imageType
	local fadeTime = 0
	local fade = 0
	if animationData then
		fadeTime = animationData.fadeTime
		fade = animationData.fade
	end
	if fade == 0 or fadeTime == 0 then
		self._seqCom:DeleteSeq(effectKey)
		self:HideEffect(setId, effectType)
		self:DoEventEnd(eventId)
	else
		local targetTran = self._useedRootList[effectKey]
		if not targetTran then
			LogError("effect key not exitst = "..tostring(effectKey))
			self:DoEventEnd(eventId)
			return
		end

		local sequence = self._seqCom:CreateSeq(effectKey)
		if effectType == 3 then
			local dp = self:FindWndSpineByKey(effectKey)
			if dp then
				local canvasShowTween = YXTween.TweenFloat(dp:GetAlpha()  or 1, 0, fadeTime, function(ival)
					dp:SetAlpha(ival)
				end)
				sequence:Insert(0,canvasShowTween)
			end
		else
			local canvasGroup = targetTran:GetComponent(typeofCanvasGroup)
			sequence:Append(canvasGroup:DOFade(0, fadeTime))
		end
		sequence:OnComplete(function()
			self._seqCom:DeleteSeq(effectKey)
			self:HideEffect(setId, effectType)
			self:DoEventEnd(eventId)
		end)
		sequence:PlayForward()
	end
end

function UINeie:ParseAnimationData(arr)
	local numList = arr or {}
	if #numList == 0 then return nil end
	return {stay=numList[1] or 0, fadeTime= numList[2] or 0, fade=numList[3] or 0}
end

function UINeie:ShowBlack(fadeInTime, fadeOutTime)
	local eventId = self._eventId
	CS.ShowObject(self.mBlack,true)
	local sequence = self._seqCom:CreateSeq("blackFade")
	local canvasGroup = self.mBlackCanvasGroup
	canvasGroup.alpha = 0
	sequence:Append(canvasGroup:DOFade(1,fadeInTime))
	sequence:AppendInterval(0.01)
	sequence:Append(canvasGroup:DOFade(0,fadeOutTime))
	sequence:OnComplete(function()
		CS.ShowObject(self.mBlack,false)
		self._seqCom:DeleteSeq("blackFade")
		self:DoEventEnd(eventId)
	end)
	sequence:PlayForward()
end

function UINeie:CreatePool()
	self._objPool = UIObjPool:New()
	self._objPool:Create(self.mUnUse,self.mIntroItem)

	self._textObjPool = UIObjPool:New()
	self._textObjPool:Create(self.mUnUse,self.mTextTemplate)

	self._effRootPool = UIObjPool:New()
	self._effRootPool:Create(self.mUnUse,self.mEffect)

	self._bgRootPool = UIObjPool:New()
	self._bgRootPool:Create(self.mUnUse,self.mBg)

	self._useedRootList = {}
end

function UINeie:HideBg(ref, animationData)
	local eventId = self._eventId
	local key = "uibg_"..ref.refId
	local bg = self._useedRootList[key]
	self._seqCom:DeleteSeq(key)
	if not bg then
		self:DoEventEnd(eventId)
		return
	end
	local fadeTime = 0
	local fade = 0
	if animationData then
		fadeTime = animationData.fadeTime
		fade =animationData.fade
	end
	local bgCanvasGroup = bg:GetComponent(typeofCanvasGroup)
	if fade > 0 then
		--填了事件参数，做动画

		--淡出隐藏
		local sequence = self._seqCom:CreateSeq(key)
		sequence:Append(bgCanvasGroup:DOFade(0, fadeTime))
		sequence:OnComplete(function()
			self._seqCom:DeleteSeq(key)
			self._bgRootPool:ReturnObj(bg)
			self._useedRootList[key] = nil
			self:DoEventEnd(eventId)
		end)
		sequence:PlayForward()
	else
		--直接隐藏
		bgCanvasGroup.alpha = 0
		self._bgRootPool:ReturnObj(bg)
		self._useedRootList[key] = nil
		self:DoEventEnd(eventId)
	end
end

function UINeie:ClearPool()
	if self._objPool then
		self._objPool:Destroy()
	end
	if self._textObjPool then
		self._textObjPool:Destroy()
	end
	if self._effRootPool then
		self._effRootPool:Destroy()
	end
	if self._bgRootPool then
		self._bgRootPool:Destroy()
	end
end

function UINeie:HideEffect(setId,type)
	local eventId = self._eventId
	local effectKey = "uieff_"..setId

	if type == 1 then
		self:DestroyWndEffectByKey(effectKey)
	elseif type == 3 then
		self:DestroyWndSpineByKey(effectKey)
		local old = self._uiSpineCtrlDic[effectKey]
		if old then
			old:Destroy()
			self._uiSpineCtrlDic[effectKey] = nil
		end
	end
	local root = self._useedRootList[effectKey]
	if root then
		self._useedRootList[effectKey] = nil
		self._effRootPool:ReturnObj(root)
	end
end

function UINeie:HideTalk(eventId)
	self._talkEventId = nil
	self._seqCom:DeleteSeq("_talkKey")
	CS.ShowObject(self.mTalkClick ,false)
	CS.ShowObject(self.mTalk, false)
	self:DoEventEnd(eventId)
end

function UINeie:ShowSpecialSpine(specialType, ref, animationData)
	if not ref then
		if LOG_INFO_ENABLED  then
			printErrorN(string.format("事件id=%s, 配置的场景id找不到", tostring(self._eventId)))
		end
	end
	if specialType == 0 then
		self:DoHideEffect(ref, animationData)
	elseif specialType == 1 then
		self:DoShowEffect(ref,1, animationData, true)
	end
end

------------------------------------------------------------------
return UINeie