---
--- Created by Administrator.
--- DateTime: 2023/10/3 20:41:05
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGue:LWnd
local UIGue = LxWndClass("UIGue", LWnd)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
--local Tweening = DG.Tweening
local typeofRectTransform = typeof(CS.RectTransform)
local YXUIPointUtil = CS.YXUIPointUtil
local typeUIHollowOut = typeof(CS.UIHollowOut)

UIGue.NORMAL = 1
UIGue.STORY = 2

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGue:UIGue()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGue:OnWndClose()

	if LOG_INFO_ENABLED then
		print("UIGue:OnWndClose()")
	end
	self:StopDelayTimer()

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGue:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGue:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	local canvasRect =LGameUI.GetUICanvasRoot()
	local hollowOut = self.mMask.transform:GetComponent(typeUIHollowOut)
	if hollowOut then
		hollowOut.m_Canvas = canvasRect
		self._hollowOut = hollowOut
	end

	self:InitData()
	self:WndEventRecv(EventNames.ON_WND_FINISH,function (...) self:OnTargetWndFinish(...) end)
	self:WndEventRecv(EventNames.ON_MAP_FINISH,function (...) self:OnMapFinish(...) end)
	self:WndEventRecv(EventNames.ON_WND_CLOSE,function (...) self:OnTargetWndClose(...) end)
	self:WndEventRecv(EventNames.GOTO_NEXT_GUIDE,function (...) self:OnClickFinger(...) end)
	self:WndEventRecv(EventNames.ON_GUIDE_SPINE_FINISH,function (...) self:OnSpineFinish(...) end)
	self:WndEventRecv(EventNames.ON_MAIN_ACTIVITY_SHOW,function () self:OnActivityFinish() end)
	self:WndEventRecv(EventNames.ON_PREPARE_OBJ_OK,function () self:OnBattlePrepareFinish() end)
	self:WndEventRecv(EventNames.ON_SWAP_PREPARE_OK,function () self:OnSwapOk() end)
	self:WndEventRecv(EventNames.GAME_SCREEN_RESETSIZE,function () self:OnScreenResetSize() end)
	self:WndNetMsgRecv(LProtoIds.HeroUpLevelResp,function () self:CheckType9() end)
	self:WndEventRecv(EventNames.On_Item_Change,function () self:CheckType10() end)
	self:WndEventRecv(EventNames.ON_HELP_PICTURE_WND_SHOW,function (...) self:SetGuidePause(...) end)


	self:InitUIEvent()

	self:OnWndRefresh()
end

function UIGue:SetUI(data)
	local cfg = self._cfg
	if not cfg then
		return
	end

	local target,type =data.target,data.type
	if not CS.IsValidObject(target) then
		printInfoN("invalic object target")
		return
	end
	local canvasRect =LGameUI.GetUICanvasRoot()
	local uicamera = gLGameUI:GetCSUICamera()
	--local scale = canvasRect.localScale.x*100
	local offset = Vector2.New(30,30)
	local screenPos = nil
	local targetPos = nil
	local sizeDelta = nil
	if type == 1 then --ui界面
		local rectTran = target:GetComponent(typeOfRectTransform)
		local size,center = LxUiHelper.GetRectPosAndSize(rectTran,self._wndTrans)
		screenPos = center
		sizeDelta = size+ offset
	elseif type ==2 then
		local size,center = LxUiHelper.GetColliderPosAndSize(target,"GameObject",self._wndTrans)
		screenPos =center
		sizeDelta = size+ offset
	elseif type == 3 then
		local size,center = LxUiHelper.GetColliderPosAndSize(target,"Collider",self._wndTrans)
		screenPos =center
		sizeDelta = size+ offset
	end
	targetPos = uicamera:ScreenToWorldPoint(screenPos)

	self.mFinger.position = targetPos
	self.mFinger.sizeDelta = sizeDelta
	self:ShowEffect(screenPos,targetPos)


	local functionId = cfg.origin
	if functionId<=0 then  ---有跳转执行跳转，无跳转执行本身逻辑
	local clickTran = target
		local clickType = type
		if type == 3 then
			clickType = 1
			clickTran = self:FindWndTrans(target,"Collider")
		end
		self._clickFunc = LxUiHelper.GetClickDelegate(clickTran,clickType)
	end

	self._guideOk = true

	self:ShowGuideFrame(sizeDelta)

	--local targetScreenPos=YXUIPointUtil.GetScreenPoint(self.mTypeOne,self.mFinger)
	self:SetTextPos(self.mFinger.localPosition)

	self:ShowSkipBtn(false)
	CS.ShowObject(self.mTypeOne,true)

	self:ShowMaskByEffectType()
end

function UIGue:CheckType10()



	local type,para = self:GetConfigPara()

	if type == ModelGuide.CONDITION_10 then
		local hero = gModelHero:GetMaxLvHero()
		if not hero then
			gModelGuide:EndGuide()
			return
		end

		local lv = hero:GetLv()
		if lv <= tonumber(para) then
			if gModelHero:CheckHeroCanUp(hero) then
				gModelGuide:OnNextGuide(self._guide)
			else
				gModelGuide:EndGuide()
			end
		else
			gModelGuide:EndGuide()
		end
	end
end


function UIGue:OnGuideWndPrepared()
	local type,para,para1 = self:GetConfigPara()
	local wnd = self._curGuideWnd
	if type == ModelGuide.CONDITION_9 then
		local hero = nil
		if wnd and wnd.GetCurHero then
			hero = wnd:GetCurHero()
		end

		if not hero then
			gModelGuide:EndGuide()
			return true
		end

		local tarLv = tonumber(para)
		local lv = hero:GetLv()
		if lv >= tarLv then
			gModelGuide:OnNextGuide(self._guide)
			return true
		end
	elseif type == ModelGuide.CONDITION_SKIP then
		if wnd and wnd.HaveStrongEquip then
			if not wnd:HaveStrongEquip() then
				gModelGuide:OnNextGuide(self._guide)
				return true
			end
		end
	elseif type == ModelGuide.CONDITION_SCROLL then
		if not self._isScrolled then
			self._isScrolled = true
			wnd:ScrollWndList(para,tonumber(para1))
			return true
		end
	elseif type == ModelGuide.CONDITION_11 then
		if not self._isScrolled then
			self._isScrolled = true
			if wnd.MoveContent then
				wnd:MoveContent(Vector2.New(0,0))
			end
			return true
		end
	end

	return false
end

function UIGue:GetPathPara()
	if not self._cfg then
		return
	end
	local cfg = self._cfg
	local path = cfg.path
	return path
end

function UIGue:OnActivityFinish()

	if LOG_INFO_ENABLED then
		print("UIGue:OnActivityFinish()")
	end
	if not self:IsWndVisible() then
		return
	end

	local wnd = GF.FindFirstWndByName("UIMCity")
	if not wnd then
		return
	end

	if not self._modelId then
		return
	end

	local tran = wnd:GetActivityTranByModel(self._modelId)
	if not CS.IsValidObject(tran) then
		return
	end

	self._targetPara =
	{
		target = tran,
		type = 1
	}
	self:StartDelaySetUITimer()

end

function UIGue:OnWndRefresh()
	self:SetPara()

	self:StartExecute()
end

function UIGue:OnClickFinger()

	local guideType = self:GetGuideType()
	if guideType == ModelGuide.SOFT then
		gModelGuide:OnNextGuide(self._guide)
		return
	end

	local isRet = self:BeforeGuideExecute()
	if isRet then
		return
	end

	self._guideOk = false
	local clickFunc = self._clickFunc

	if clickFunc then
		clickFunc()
	end

	self:AfterGuideExecute()
end

---界面打开时，延时修改手指和文本框位置
function UIGue:OnTargetWndFinish(wndName)



	if not self:IsWndVisible() then
		return
	end

	local path = self:GetPathPara()
	if self._guideType == ModelGuide.GUIDE_BAG then
		if wndName ~= "UIBags" then
			return
		end
	else
		if not path then
			return
		end
		local rootName = self:GetRootName(path)
		if rootName ~= wndName then
			return
		end
	end

	if LOG_INFO_ENABLED then
		print("guide wnd ready "..wndName)
	end

	local wnd = GF.FindFirstWndByName(wndName)
	if not wnd then
		wnd = gLGameUI:FindChildWndByName(wndName)
	end

	if not wnd then
		return
	end

	local isGuideReady = wnd:IsGuideReady()
	if not isGuideReady then
		return
	end


	if self._guideType == ModelGuide.GUIDE_BAG then
		self:OnUIBagsFinish()
		return
	end


	self._curGuideWnd = wnd

	local isRet = self:OnGuideWndPrepared()
	if isRet then
		return
	end

	local target
	local type, para1 = self:GetConfigPara()
	if type == ModelGuide.CONDITION_14 then
		if wnd.GetHeroFirstHeroIcon then
			target = wnd:GetHeroFirstHeroIcon()
		end

		if not target then
			return
		end
	else
		local rootTran  = wnd:GetWndTrans()
		local relativePath = self:GetRelativePath(path)
		target = self:FindWndTrans(rootTran,relativePath)
		if not target then
			local extraPath = self:GetExtraPath()
			printInfoN(string.format("extrapath %s",extraPath))
			if not string.isempty(extraPath) then
				relativePath = self:GetRelativePath(extraPath)
				target = self:FindWndTrans(rootTran,relativePath)
			end
		end
		if not target then
			if type == ModelGuide.CONDITION_16 then
				if wnd.GetGuideHeroIndex then
					local index = wnd:GetGuideHeroIndex(tonumber(para1))
					if index then
						relativePath = string.gsub(relativePath, "{n}", "{"..tostring(index).."}")
						if LOG_INFO_ENABLED then
							printInfoN(string.format("config=16, guide change path %s",relativePath))
						end
						target = self:FindWndTrans(rootTran, relativePath)
						if not target then
							if wnd.GuideScrollToIndex then
								wnd:GuideScrollToIndex(index + 1)
							end
						end
					end
				end
			end
		end
		if not target then
			return
		end
	end

	self._targetPara =
	{
		target = target,
		type = 1
	}

	self:StartDelaySetUITimer()

end



function UIGue:GetRelativePath(path)
	return LUtil.GetRelativePath(path)
end


function UIGue:StartDelaySetUITimer(from)
	local time = 0.2
	if from == "resize" then
		time = 0.01
	else
		self:ShowMaskByEffectType()
	end
	--self:SetImageAlpha(self.mMask,0.85)
	self:TimerStop(self._delaySetUITimerKey)
	self:TimerStart(self._delaySetUITimerKey,time,false,1)
end

function UIGue:DoMapMove()
	if not self:CheckCanMove() then
		return
	end

	local curGuide = self._guide
	local path = self:GetPathPara()
	local pos = LxDataHelper.ParseVector(path)
	local curMap = GF.GetCurMap()
	if curMap and curMap.MoveCamera then
		curMap:MoveCamera(pos,function ()
			gModelGuide:OnNextGuide(curGuide)
		end,nil,true)
	else
		gModelGuide:EndGuide()
	end
end

function UIGue:ShowSkipBtn(isShow)
	self._showSkip = isShow
	CS.ShowObject(self.mSkipBtn,isShow)
	if isShow then
		self:SetImageAlpha(self.mMask,0.85)
	end
end

function UIGue:StopDelayTimer()
	if self._delayTimer then
		LxTimer.DelayTimeStop(self._delayTimer)
		self._delayTimer = nil
	end
end

function UIGue:IsSwapGuide()
	local type = self:GetConfigPara()
	return type == ModelGuide.CONDITION_SWAP
end

function UIGue:TweenInternal(startSize,endSize,duration)
	local tweener = YXTween.TweenFloat(0,1,duration,function (val)
		local x = val*endSize.x + (1-val)* startSize.x
		local y = val*endSize.y + (1-val)* startSize.y
		self.mIcon.sizeDelta = Vector2.New(x,y)
	end)
	local seqCom = self:GetSeqCom()
	local seq = seqCom:CreateSeq("iconTween")
	seq:Append(tweener)
	seq:SetAutoKill(true)
	seq:OnComplete(function()
		seqCom:DeleteSeq("iconTween")
	end)
	seq:PlayForward()
end

function UIGue:SetGuidePause(isPause)
	if isPause then
		self:PauseGuide()
	else
		self:CheckRestartGuide()
	end
end


function UIGue:ShowMaskByEffectType(isWait)
	local effectType = self:GetEffectType()

	CS.ShowObject(self.mMask,true)
	local maskAlpha = 0.85
	if effectType == 5 or effectType == 4 or effectType == 6 then
		maskAlpha = 0
	end
	if isWait then
		maskAlpha = 0
	end

	self:SetImageAlpha(self.mMask,maskAlpha)
end

function UIGue:DelayShowOnSpine(tran)
	self._targetPara =
	{
		target = tran,
		type = 3
	}
	self:StartDelaySetUITimer()

end


function UIGue:CheckHideMainHurdle()
	local type = self:GetConfigPara()
	if type == ModelGuide.CONDITION_HIDE then
		return true
	end

	return false
end

function UIGue:CheckRestartGuide()
	self._isPause = false

	self:StartExecute()
end

function UIGue:IsFingerInView()
	local effectType = self:GetEffectType()
	if effectType == 6 then
		return true
	end

	local pos = self.mFinger.position
	local camera = gLGameUI:GetUICamera()
	local viewPos = camera:WorldToViewportPoint(pos)
	if (viewPos.x < 0 or viewPos.x > 1 or viewPos.y < 0 or viewPos.y > 1) then
		return false
	else
		return true
	end
end

function UIGue:OnBeginDrag(eventData)
	local spineClick = self:GetTargetClickCom()
	if not spineClick then
		return
	end

	self._recordPos = self.mFinger.localPosition
	spineClick:OnBeginDrag(eventData)

end

function UIGue:PlayGuideSound()
	if not self._cfg then
		return
	end
	local type = self:GetConfigPara()
	if type == ModelGuide.CONDITION_17 then
		gLGameAudio:StopSingleSound()
	end
	local sound = self._cfg.sound
	if not string.isempty(sound) then
		gLGameAudio:PlaySingleSound(sound)
	end
end

function UIGue:CheckClosePlot()
	local type = gModelGuide:GetCurGuideType()
	if type ~= ModelGuide.SOFT then
		gModelPlot:OnPlotComplete()
	end
end

function UIGue:DelayShowSkip()
	local delaySkipTime = gModelGuide:GetDelayTime(self._guide or 0)
	self:TimerStop(self._delaySkipTimer)
	self:TimerStart(self._delaySkipTimer,delaySkipTime,false,1)
end

function UIGue:ClearTween()
	if self.mIcon then self.mIcon.sizeDelta = Vector2.New(0.01,0.01) end
	local seqCom = self:GetSeqCom()
	seqCom:DeleteSeq("iconTween")
end


function UIGue:GetTargetClickCom()
	local curMap = GF.GetCurMap()
	if not curMap or not  curMap:IsSameMap("LBattleMap") then
		return
	end

	local para = self:GetPathPara()
	local grid = tonumber(para)
	if not grid then
		return
	end
	local spine = curMap:GetFormationHero(grid)


	if not spine or not spine:IsValid() then
		return
	end
	local spineClick = spine:GetClickCom()
	if not CS.IsValidObject(spineClick) then
		return
	end
	return spineClick
end

function UIGue:SetTextContent(roleImg,saying)
	local hasSaying = not string.isempty(saying)
	CS.ShowObject(self.mTextBg,hasSaying)
	if not hasSaying then
		return
	end
	self:SetWndEasyImage(self.mFigure,roleImg)
	self:SetWndText(self.mText,saying)
end


---@return boolean 是否拦截
function UIGue:BeforeGuideExecute()
	local type = self:GetConfigPara()
	if type == ModelGuide.CONDITION_SWAP then
		return true
	elseif type == ModelGuide.CONDITION_HIDE then
		self:SetHideActScroll(false)
	end

	self:HideGuideEffect()

	return false
end

function UIGue:HideGuideEffect()
	self:ClearTween()
	self:ShowMaskByEffectType(true)
	self:TimerStop(self._delaySkipTimer)
	self:DestroyWndEffectByKey(self._effectKey)
	self:DestroyWndSpineByKey(self._effectKey)
	CS.ShowObject(self.mSkipBtn,false)
	CS.ShowObject(self.mTextBg,false)
end

function UIGue:ShowGuideTextContent()
	local cfg = self._cfg
	if not cfg then
		return
	end
	local roleImg = cfg.role
	if string.isempty(roleImg) then
		roleImg = gModelGuide:GetGuidePara("roleGuide")
	end
	local intro = ccLngText(cfg.txt)

	self:SetTextContent(roleImg,intro)
end

function UIGue:GetPlot()
	if not self._cfg then
		return
	end
	local cfg = self._cfg
	return cfg.plot
end

function UIGue:InitData()
	self._effectPaths=
	{
		[1]= "fx_ui_shou",
		[2] = "fx_ui_shou_2",
	}
	self._delaySetUITimerKey = "_delaySetUITimerKey"
	self._delaySkipTimer ="_delaySkipTimer"

	self._checkFinger = "_checkFinger"

	self._effectKey = "_effectKey"

	self._needPauseWndList = {
		["UIBzPicturePop"] = true,
	}
end

function UIGue:GetEffectType()
	if not self._cfg then
		return
	end
	local cfg = self._cfg
	local effectType = cfg.effectType
	return effectType
end



function UIGue:ShowEffect(screenPos,targetPos)
	self:DestroyWndEffectByKey(self._effectKey)
	self:DestroyWndSpineByKey(self._effectKey)
	local effectType = self:GetEffectType()
	if effectType == 6 then
		return
	end

	local guideType = self:GetGuideType()
	if guideType == ModelGuide.SOFT then
		return
	end

	self.mEffectRoot.position = targetPos

	local UScreen = UnityEngine.Screen
	local rotateY = Vector3.New(0,0,0)
	if screenPos.y-150<0 then
		rotateY = Vector3.New(180,0,0)
	end

	local rotateX = Vector3.New(0,0,0)
	if screenPos.x+ 150 > UScreen.width then
		rotateX = Vector3.New(0,180,0)
	end

	local rotate = rotateX+ rotateY

	local offset = Vector3.zero
	if effectType == 4 then
		local effect = "fx_ui_arrow_3"
		self:CreateWndEffect(self.mEffectRoot,effect,self._effectKey, 100)
		-- -133, -135
		offset = Vector3.New(-38,-68)
	else
		local effect = self._effectPaths[2]
		self:CreateWndEffect(self.mEffectRoot,effect,self._effectKey,100)
	end


	self.mEffectRoot.localRotation = Quaternion.Euler(rotate.x,rotate.y,0)
	self.mEffectRoot.localPosition =self.mEffectRoot.localPosition +  offset
end

function UIGue:OnTimer(key)
	if key == self._delaySetUITimerKey then
		self:SetUI(self._targetPara)
	elseif key == self._delaySkipTimer then
		self:CheckShowSkipBtn()
	end
end

function UIGue:GetJumpId()
	if not self._cfg then
		return
	end
	local cfg = self._cfg
	return cfg.origin
end

function UIGue:RefreshUI()
	self:ClearTween()
	CS.ShowObject(self.mTypeOne,false)

	self._clickFunc = nil

	self:ShowSkipBtn(false)

	self:SetGuideWndVisible(true)

	self:ClearGuideTempPara()


	local curGuide = self._guide
	local plot = self:GetPlot()
	if plot>0 then
		--self:SetGuideWndVisible(false)
		gModelPlot:StartPlotAndCallback(plot,function ()
			gModelGuide:OnNextGuide(curGuide)
		end,true)
		return
	end

	self:PlayGuideSound()

	local guideType = self:GetGuideType()
	local path = self:GetPathPara()

	local jumpId = self:GetJumpId()
	if jumpId>0 then  ---有跳转执行跳转，无跳转执行本身逻辑
		self._clickFunc = function() gModelFunctionOpen:Jump(jumpId) end
	end

	--local delaySkipTime = gModelGuide:GetDelayTime(self._guide)
	--self:TimerStop(self._delaySkipTimer)
	--self:TimerStart(self._delaySkipTimer,delaySkipTime,false,1)
	self:DelayShowSkip()

	self:ShowGuideTextContent()
	self:ShowMaskByEffectType(true)
	CS.ShowObject(self.mFinger,true)



	self._guideType = guideType
	if guideType == ModelGuide.ROLE then --指引目标是小人
		self._spineId = tonumber(path)
		local spineObj = gLFightIdleManager:FindSpineById(self._spineId)
		if spineObj and spineObj:IsReady() then
			local tran = spineObj:GetDisplayTrans()
			self:OnSpineFinish(self._spineId,tran)
		end
	elseif guideType == ModelGuide.ACTIVITY then
		self._modelId = tonumber(path)

		FireEvent(EventNames.SPREAD_ACT_LIST)
		self:OnActivityFinish()
	elseif guideType == ModelGuide.GUIDE_DRAG then
		self:OnBattlePrepareFinish()
	elseif guideType == ModelGuide.MOVE then
		CS.ShowObject(self.mFinger,false)
		self:DoMapMove()
	elseif guideType ==  ModelGuide.FORSHOW then
		CS.ShowObject(self.mFinger,false)
		GF.OpenWndUp("UISowEffect",{wndType = 3,refId = tonumber(path),isFromGuide = true,guideId = curGuide})
		self:SetGuideWndVisible(false)
	elseif guideType == ModelGuide.MAIN_MONSTER then
		CS.ShowObject(self.mFinger,false)
		gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_MAIN)
		gModelGuide:OnNextGuide(curGuide)
	elseif guideType == ModelGuide.GUIDE_POSTER then
		CS.ShowObject(self.mFinger,false)
		GF.OpenWnd("UIGuePost",{refId = tonumber(path)})
		gModelGuide:OnNextGuide(curGuide)
	elseif guideType == ModelGuide.GUIDE_BAG then
		self._itemId= tonumber(path)
		self:OnUIBagsFinish()
	elseif guideType == ModelGuide.GUIDE_CREATENAME then
		CS.ShowObject(self.mFinger,false)
		GF.OpenWnd('UIPerCreateName', {isNew = true})
		gModelGuide:OnNextGuide(curGuide)
	else

		if string.isempty(path)  then
			self:OnClickFinger()
			return
		end

		local rootName = self:GetRootName(path)
		if not rootName then
			return
		end

		if self:CheckHideMainHurdle() then
			self:SetHideActScroll()
		end

		if LOG_INFO_ENABLED then
			printInfoN(string.format("guide path %s",path))
		end

		local s,e = string.find(rootName,"UI")
		if s and e then
			self:OnTargetWndFinish(rootName)
			if rootName ~= "UIOrdinTip" then
				GF.CloseWndByName("UIOrdinTip") --关闭弹窗
			end
			if rootName == "UISayFlow" then
				FireEvent(EventNames.SET_CHAT_FLOAT_SHOW,true)
			end
		else
			self:OnMapFinish(rootName)
		end
	end


end
function UIGue:StartTweenTwo()
	local endSize = self.mFinger.sizeDelta
	local offset = Vector2.New(50,50)
	local startSize = endSize + offset
	local duration = 0.2
	self:TweenInternal(startSize,endSize,duration)
end

function UIGue:CheckAutoNext()
	if not self._guide or self._guide <= 0 then return end
	if not self._cfg then return end
	local type, para1, para2 = self:GetConfigPara()
	if type == ModelGuide.CONDITION_15 then
		self:OnClickFinger()
	end
end





function UIGue:OnGuideInterrupt()
	if self._guideOk then
		gModelGuide:OnNextGuide(self._guide)
	end
end

function UIGue:OnScreenResetSize()
	self:StartDelaySetUITimer("resize")
end



function UIGue:AfterGuideExecute()
	local type,para = self:GetConfigPara()
	if type == ModelGuide.CONDITION_9 then
		self:DelayShowSkip()

		self._isWaitData = true
		return
	elseif type == ModelGuide.CONDITION_INTERRUPT then
		local guideKey = tonumber(para)
		if gModelGuide:IsGuideFinished(guideKey) then
			gModelGuide:EndGuide()
			return
		end
	elseif type == ModelGuide.CONDITION_LOOP then
		if gModelInstance:GetIsGetBoxAward() then
			gModelGuide:StartGuide(self._guide)
			return
		end
	elseif type == ModelGuide.CONDITION_10 then
		self:DelayShowSkip()

		self._isWaitData = true
		return
	end

	gModelGuide:OnNextGuide(self._guide)
end

function UIGue: OnUIBagsFinish()
	local wnd = GF.FindFirstWndByName("UIBags")
	if not wnd then
		return
	end

	local target = wnd:GetTransByRefId(self._itemId)
	if not CS.IsValidObject(target) then
		return
	end

	self._targetPara =
	{
		target = target,
		type = 1
	}

	self:StartDelaySetUITimer()

end

function UIGue:CheckCanMove()
	local type,para = self:GetConfigPara()
	if not type then
		return true
	end
	if type == ModelGuide.CONDITION_MAP then
		if tonumber(para) == 1 then
			local curMap = GF.GetCurMap()
			if curMap and curMap:IsSameMap("LOneNightSpaceMap") then
				return true
			end
		end
	end
	return false
end

function UIGue:OnClickSkip()
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_SKIP,nil,self._guide)
	gModelGuide:EndGuide()

	local battleNode = gModelInstance:GetBattleNode()
	local isStoryNode = gModelPlot:IsStoryInstanceInternal(battleNode)
	if isStoryNode then
		local confirmFun = function() gModelGuide:GuideJumpReq(1,3) end

		local para =
		{
			refId = 170012,
			func = confirmFun,
		}
		local manager = gLGpManager:FindStoryCopyGp()
		if manager then
			manager:Pause()
		end
		gModelGeneral:OpenUIOrdinTips(para, true, true)
	end
end

function UIGue:OnBattlePrepareFinish()

	if not self:IsWndVisible() then
		return
	end

	local guideType = self:GetGuideType()
	if guideType ~= ModelGuide.GUIDE_DRAG then
		return
	end
	local target = self:GetPrepareObjTran()
	if not target then
		return
	end

	self:DelayShowOnSpine(target)

end

function UIGue:OnSwapOk()

	if not self:IsWndVisible() then
		return
	end

	if self:IsSwapGuide() then
		gModelGuide:OnNextGuide(self._guide)
	end
end

function UIGue:GetGuideType()
	if not self._cfg then
		return
	end
	local cfg = self._cfg
	local type = cfg.type
	return type
end

function UIGue:GetPrepareObjTran()
	local curMap = GF.GetCurMap()
	if not curMap or not  curMap:IsSameMap("LBattleMap") then
		return
	end
	local para = self:GetPathPara()
	local grid = tonumber(para)
	if not grid then
		return
	end
	local spine = curMap:GetFormationHero(grid)

	return spine and spine:GetDisplayTrans()
end

function UIGue:OnClickMask()
	if not self._guideOk then
		return
	end

	local guideType = self:GetGuideType()
	if guideType == ModelGuide.SOFT then
		gModelGuide:OnNextGuide(self._guide)
		return
	end

	local effectType = self:GetEffectType()
	if effectType == 0 then
		return
	end

	if self._showSkip  then
		return
	end

	self:ClearTween()

	self:StartTweenTwo()

	self:ShowWrongClickTip()
end

function UIGue:StartTween()
	local duration = gModelGuide:GetGuidePara("specialTime") or 1
	local canvasRect =LGameUI.GetUICanvasRoot()

	local canvasRectTran = canvasRect:GetComponent(typeofRectTransform)
	local area = canvasRectTran.rect
	local startSize = Vector2.New(area.height*2,area.height*2)


	local endSize = self.mFinger.sizeDelta

	self:TweenInternal(startSize,endSize,duration)
end


function UIGue:ShowWrongClickTip()
	local roleImg = gModelGuide:GetGuidePara("roleGuide")
	local text =ccLngText(gModelGuide:GetGuidePara("roleGuideTxt"))
	self:SetTextContent(roleImg,text)

	self:StopDelayTimer()

	local time = gModelGuide:GetGuidePara("roleGuideTime")
	self._delayTimer = LxTimer.DelayTimeCall(function()
		self:ShowGuideTextContent()
	end, time)
end

function UIGue:OnDrag(eventData)
	local spineClick = self:GetTargetClickCom()
	if not spineClick then
		return
	end

	local camera = eventData.pressEventCamera
	local pos = camera:ScreenToWorldPoint(eventData.position)
	pos = self.mFinger.parent:InverseTransformPoint(pos)
	self.mFinger.localPosition = pos

	spineClick:OnDrag(eventData)
end

function UIGue:GetCurGuide()
	return self._guide
end

function UIGue:OnEndDrag(eventData)
	local spineClick = self:GetTargetClickCom()
	if not spineClick then
		return
	end

	self.mFinger.localPosition = self._recordPos

	spineClick:OnEndDrag(eventData)
end

function UIGue:GetConfigPara()
	if not self._cfg then
		return
	end
	local para = self._cfg.config
	if string.isempty(para) then
		return
	end

	local strs = string.split(para,'=')
	local type = tonumber(strs[1])
	local para1 = strs[2]
	local para2 = strs[3]
	return type,para1,para2
end


---目标界面被关闭，需要关闭引导界面
function UIGue:OnTargetWndClose(wndName)
	if not self:IsWndVisible() then
		return
	end

	local path = self:GetPathPara()
	if string.isempty(path) then
		return
	end
	local s,e,ret= string.find(path,wndName)
	if not s or not e then
		return
	end

	self:ShowSkipBtn(true)
	self:OnGuideInterrupt()
end

function UIGue:CheckShowSkipBtn()
	if self._guideOk and self:IsFingerInView() then
		return
	end

	self:ShowSkipBtn(true)
end

function UIGue:ShowGuideFrame(sizeDelta)
	local effectType = self:GetEffectType()

	local isCircle = false
	local isSquare = false

	if effectType == 0 then
		isSquare = true
		self:StartTween()
	elseif effectType == 1 or effectType == 2 or effectType == 5 or effectType == 7 then
		isSquare = true
		self.mIcon.sizeDelta = sizeDelta
	elseif effectType == 3 then
		isCircle = true
	elseif effectType == 6 then
		CS.ShowObject(self.mIcon,false)
		CS.ShowObject(self.mCircle,false)
		CS.ShowObject(self.mEmptyArea,true)
		self:SetWndClick(self.mEmptyArea,function ()
			self:OnClickFinger()
		end)
		return
	end

	local iconPath = "plot_bg_guide"
	if effectType == 5 then
		iconPath = "plot_bg_guide_2"
	end
	self:SetWndEasyImage(self.mIcon,iconPath)

	CS.ShowObject(self.mIcon,isSquare)
	CS.ShowObject(self.mCircle,isCircle)
	CS.ShowObject(self.mEmptyArea,false)
	self:SetWndClick(self.mEmptyArea,function () end)
	if isCircle then
		self._hollowOut.m_Target = self.mCircle
	elseif isSquare then
		self._hollowOut.m_Target = self.mIcon
	end
end


function UIGue:CheckType9()


	local type,para = self:GetConfigPara()

	local wnd = self._curGuideWnd
	if type == ModelGuide.CONDITION_9 then
		local hero = nil
		if wnd and wnd.GetCurHero then
			hero = wnd:GetCurHero()
		end

		if not hero then
			gModelGuide:EndGuide()
			return
		end

		local tarLv = tonumber(para)
		local lv = hero:GetLv()
		if lv < tarLv then
			if gModelHero:CheckHeroCanUp(hero) then
				gModelGuide:StartGuide(self._guide)
			else
				gModelGuide:EndGuide()
			end
		elseif lv == tarLv then
			gModelGuide:OnNextGuide(self._guide)
		end
	end
end

function UIGue:PauseGuide()
	self._isPause = true
	self:SetGuideWndVisible(false)

end

function UIGue:StartExecute()
	if not self._guide then
		return
	end

	if self._isPause then
		return
	end

	self._guideOk = false
	self._isScrolled = false
	if self._wndType == UIGue.NORMAL then
		self:RefreshUI()
	else
		self:RefreshUI_Story()
	end
end

function UIGue:OnGuideEnd()
	self:SetGuideWndVisible(false)
	self:HideGuideEffect()
	printInfoN("---------------on guide end")
	self:SetHideActScroll(false)
	self._guide = nil
	self._cfg = nil
end



function UIGue:InitUIEvent()
	self:SetWndClick(self.mFinger,function  () self:OnClickFinger() end)
	self:SetWndClick(self.mSkipBtn,function () self:OnClickSkip() end)
	self:SetWndClick(self.mMask,function () self:OnClickMask() end)

	CS.SetOnBeginDrag(self.mFinger.gameObject,function (go,eventdata)
		self:OnBeginDrag(eventdata)
	end)
	CS.SetOnEndDrag(self.mFinger.gameObject,function (go,eventdata)
		self:OnEndDrag(eventdata)
	end)
	CS.SetOnDrag(self.mFinger.gameObject,function (go,eventdata)
		self:OnDrag(eventdata)
	end)
end


function UIGue:SetPara()
	self._guide = self:GetWndArg("refId")
	if not self._guide then
		self:SetGuideWndVisible(false)
		return
	end

	self._wndType = self:GetWndArg("wndType") or UIGue.NORMAL
	self._targetTran = self:GetWndArg("targetTran")

	self._cfg = gModelGuide:GetGuideEventConfig(self._guide)
end

function UIGue:SetGuideWndVisible(active)
	self:SetWndVisible(active,true)
end


function UIGue:OnMapFinish(mapName)

	if not self:IsWndVisible() then
		return
	end

	if not mapName then
		return
	end

	local path = self:GetPathPara()
	local guideType = self:GetGuideType()
	if guideType == ModelGuide.MOVE then
		self:DoMapMove()
		return
	end


	if not path then
		return
	end

	--printInfoN("UIGue OnMapFinish "..mapName)
	local rootName = self:GetRootName(path)
	if rootName ~= mapName then
		return
	end
	local scene = GF.GetNowSceneClass()
	local mapTran = nil
	if scene and scene.GetCurMapTran then
		mapTran = scene:GetCurMapTran()
	end
	if not CS.IsValidObject(mapTran) then
		return
	end


	local relativePath = self:GetRelativePath(path)
	local target = mapTran:Find(relativePath)
	if not target then
		return
	end

	if not target.gameObject.activeInHierarchy then
		printInfoN('target name '..target.name)
		gModelGuide:EndGuide()
		return
	end

	self._targetPara =
	{
		target = target,
		type = 2
	}

	self:StartDelaySetUITimer()
end

function UIGue:SetTextPos(targetScreenPos)

	printInfoN(string.format("text pos x: %s,y: %s",targetScreenPos.x,targetScreenPos.y))

	local rectHeight = nil
	local effectType = self:GetEffectType()
	if effectType == 3 then
		rectHeight = self.mCircle.rect.height
	elseif effectType == 6 then
		rectHeight = 10
	else
		rectHeight = self.mIcon.rect.height
	end
	--local canvasRect =LGameUI.GetUICanvasRoot()
	--local uicamera = gLGameUI:GetCSUICamera()
	local screenPosMin = self.mLeftBottom.localPosition
	local screenPosMax =  self.mRightTop.localPosition

	printInfoN(string.format("screen posMin  x %s,y %s",screenPosMin.x,screenPosMin.y))
	printInfoN(string.format("screen posMax  x %s,y %s",screenPosMax.x,screenPosMax.y))

	--local UScreen = UnityEngine.Screen
	--local UHeight = UScreen.height
	--local UWidth = UScreen.width
	--local curScreenHeight = UHeight * LGameQuality.SCREEN_WIDTH_DESIGN /UWidth
	--local curScreenWidth = LGameQuality.SCREEN_WIDTH_DESIGN
	local cfgDis = gModelGuide:GetGuidePara("roleRange")
	local textHeight = self.mTextBg.rect.height
	local offsetY = cfgDis + textHeight/2 + rectHeight/2
	local textPosY =targetScreenPos.y + offsetY
	if textPosY + textHeight/2 > screenPosMax.y then
		textPosY = targetScreenPos.y -offsetY
	end

	local textWidth = self.mTextBg.rect.width
	local rangeXMax = screenPosMax.x - textWidth/2 - 20
	local rangeXMin = screenPosMin.x + textWidth/2 + 20

	local center = (screenPosMax.x + screenPosMin.x)/2
	if rangeXMin > rangeXMax then
		rangeXMax,rangeXMin = center,center
	end

	local rangeYMax = screenPosMax.y - textHeight/2 - 20
	local rangeYMin = screenPosMin.y + textHeight/2 + 20

	center = (screenPosMax.y + screenPosMin.y)/2
	if rangeYMin > rangeYMax then
		rangeYMin,rangeYMax = center,center
	end

	printInfoN(string.format("x min %s ,max %s ;y min %s, max %s ",rangeXMin,rangeXMax,rangeYMin,rangeYMax))

	local textPosX = Mathf.Clamp(targetScreenPos.x,rangeXMin,rangeXMax)
	local textPosY = Mathf.Clamp(textPosY,rangeYMin,rangeYMax)

	printInfoN(string.format("textPos x %s,y %s",textPosX,textPosY))

	local screenPos = Vector2.New(textPosX,textPosY)
	--local wPos = uicamera:ScreenToWorldPoint(screenPos)
	--local localPos =self.mTypeOne:InverseTransformPoint(wPos)
	--local localPos = YXUIPointUtil.InverseScreenPoint(self.mTypeOne,screenPos,uicamera)
	self.mTextBg.localPosition = screenPos
end

function UIGue:ClearGuideTempPara()
	self._spineId = nil
	self._modelId = nil
	self._itemId = nil
	self._curGuideWnd = nil
end

function UIGue:OnSpineFinish(spineId,tran)

	if not self:IsWndVisible() then
		return
	end

	if self._spineId ~= spineId then
		return
	end
	self:DelayShowOnSpine(tran)
end

function UIGue:GetRootName(path)
	return LUtil.GetRootName(path)
end

function UIGue:RefreshUI_Story()
	CS.ShowObject(self.mTypeOne,false)
	self:ClearTween()

	self._clickFunc = nil

	self:ShowSkipBtn(false)

	--local delaySkipTime = gModelGuide:GetDelayTime(self._guide)
	--self:TimerStop(self._delaySkipTimer)
	--self:TimerStart(self._delaySkipTimer,delaySkipTime,false,1)
	self:DelayShowSkip()

	self:PlayGuideSound()

	local jumpId = self:GetJumpId()
	if jumpId>0 then  ---有跳转执行跳转，无跳转执行本身逻辑
		self._clickFunc = function() gModelFunctionOpen:Jump(jumpId) end
	end

	self:ShowGuideTextContent()

	self:ShowMaskByEffectType(true)
	CS.ShowObject(self.mFinger,true)
	self:SetGuideWndVisible(true)
	local curGuide = self._guide
	local plot = self:GetPlot()
	if plot>0 then
		gModelPlot:StartPlotAndCallback(plot,function ()
			gModelGuide:OnNextGuide(curGuide)
		end,true)
		return
	end

	if self._targetTran then
		self:DelayShowOnSpine(self._targetTran)
	elseif plot<=0 then
		self:OnClickFinger()
	end

end

function UIGue:GetExtraPath()
	local type,para = self:GetConfigPara()
	if type == ModelGuide.CONDITION_13 then
		return para
	end
end

function UIGue:SetWndVisible(active,record)
	if not record then
		active = self:IsWndVisible()
	end
	print("active guide wnd "..tostring(active))
	LWnd.SetWndVisible(self,active)
end

------------------------------------------------------------------
return UIGue


