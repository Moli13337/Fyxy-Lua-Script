---
--- Created by Admin.
--- DateTime: 2023/10/10 10:12
---
------------------------------------------------------------------
--- wnd tween control
------------------------------------------------------------------
local Vector2 = Vector2
local Vector3 = Vector3
local UnityEngine = UnityEngine
local typeof = typeof
local typeof_LayoutElement = typeof(UnityEngine.UI.LayoutElement)
local Tweening = DG.Tweening
local EaseOutCubic = Tweening.Ease.OutCubic
local EaseInQuad = Tweening.Ease.InQuad
local EaseOutSine = Tweening.Ease.OutSine
local FastBeyond360 = Tweening.RotateMode.FastBeyond360
local typeRectTransform = typeof(UnityEngine.RectTransform)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local LCurveUtil = LCurveUtil
local YXTween = YXTween
local CS = CS

-----------------------------------------------------------------
---@type LWnd
local LWnd = LWnd
------------------------------------------------------------------


------------------------------------------------------------------
--- wnd tween sequence
------------------------------------------------------------------
function LWnd:TweenSeqDestroyAll(tweenComplete)
	local wndTweenSeqList = self._wndTweenSeqList
	if (wndTweenSeqList) then
		for k,v in pairs(wndTweenSeqList) do
			v:Kill(tweenComplete or false)
		end
		self._wndTweenSeqList = nil
	end
end
--全部动画播完
function LWnd:TweenSeqCompleteAll()
	local wndTweenSeqList = self._wndTweenSeqList
	if (wndTweenSeqList) then
		for k,v in pairs(wndTweenSeqList) do
			v:Complete()
		end
		self._wndTweenSeqList = nil
	end
end
function LWnd:TweenSeqKill(seqKey)
	local wndTweenSeqList = self._wndTweenSeqList
	if (wndTweenSeqList) then
		local obj = wndTweenSeqList[seqKey]
		if (obj) then
			obj:Kill(false)
		end
		self._wndTweenSeqList[seqKey] = nil
	end
end
function LWnd:TweenSeqFind(seqKey)
	local wndTweenSeqList = self._wndTweenSeqList
	if (wndTweenSeqList) then
		return wndTweenSeqList[seqKey]
	end
	return nil
end
function LWnd:TweenSeqCreate(seqKey, seqFunc)
	local wndTweenSeqList = self._wndTweenSeqList
	if (not wndTweenSeqList) then
		wndTweenSeqList = {}
		self._wndTweenSeqList = wndTweenSeqList
	end
	local seq = wndTweenSeqList[seqKey]
	if (not seq) then
		seq = Tweening.DOTween.Sequence()
		seq:SetAutoKill(false)
		seq = seqFunc(seq)
		wndTweenSeqList[seqKey] = seq
	end
	return seq
end
------------------------------------------------------------------
--- new tween
------------------------------------------------------------------
function LWnd:TweenSeq_LocalMoveTrans(seqKey, trans, fromPos, toPos, time, completeFunc, easeType)
	if CS.IsNullObject(trans) then
		return
	end
	time = time or 0.2
	
	if fromPos then
		trans.localPosition = fromPos
	end
	
	local seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local move = trans:DOLocalMove(toPos, time)
		if easeType then
			move:SetEase(easeType)
		end
		seq:Join(move)
		return seq
	end)
	
	seqTween:OnComplete(function() 
		self:TweenSeqKill(seqKey)
		if completeFunc then 
			completeFunc(seqKey) 
		end 
	end)
	
	seqTween:PlayForward()
	
	return seqTween
end

function LWnd:TweenSeq_AlphaCanvasTrans(seqKey, alphaTrans, fromAlpha, toAlpha, time, completeFunc, easeType)
	if CS.IsNullObject(alphaTrans) then
		return
	end
	local canvas = alphaTrans:GetComponent(typeofCanvasGroup)
	if CS.IsNullObject(canvas) then
		return
	end
	time = time or 0.2
	canvas.alpha = fromAlpha
	
	local seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local alphaTween = CS.YXDOTweenModuleUI.DOFade(canvas, toAlpha, time)
		if easeType then
			alphaTween:SetEase(easeType)-- :SetEase(EaseOutCubic)
		end
		seq:Join(alphaTween)
		return seq
	end)
	
	seqTween:OnComplete(function() 
		canvas.alpha = toAlpha
		self:TweenSeqKill(seqKey)
		if completeFunc then 
			completeFunc(seqKey) 
		end 
	end)
	
	seqTween:PlayForward()
end
function LWnd:TweenSeq_ScaleOpenTrans(seqKey, rootTrans, scaleMap, completeFunc)
	if CS.IsNullObject(rootTrans) or not scaleMap or 0 == #scaleMap then
		if completeFunc then
			completeFunc(seqKey)
		end
		return
	end 
	
	local seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local tweener = nil
		for _,v in ipairs(scaleMap) do
			tweener = rootTrans:DOScale(Vector3(v.scale, v.scale, v.scale), v.time)
			seq:Append(tweener)
		end 
		return seq
	end)
	
	seqTween:OnComplete(function() 
		if CS.IsNullObject(rootTrans) then
			local scale = scaleMap[#scaleMap].scale
			rootTrans.localScale = Vector3(scale,scale,scale)
		end
		self:TweenSeqKill(seqKey)
		if completeFunc then 
			completeFunc(seqKey) 
		end 
	end)
	
	seqTween:PlayForward()
end
------------------------------------------------------------------
--- scale pop
------------------------------------------------------------------
function LWnd:TweenSeq_ScalePop(seqKey, childPath)
	local trans = childPath
	if (type(trans) == 'string') then
		trans = self:FindWndTrans(nil, childPath)
	end
	return self:TweenSeqCreate(seqKey, function(seq)
		local scaleOutMax = 1.1
		local scaleOutTime = 0.2
		local scaleInTime = 0.1
		local tweener
		tweener = trans:DOScale(Vector3(scaleOutMax,scaleOutMax,scaleOutMax), scaleOutTime)
		seq:Append(tweener)
		tweener = trans:DOScale(Vector3.one, scaleInTime)
		seq:Append(tweener)
		return seq
	end)
end
------------------------------------------------------------------
--- scale zoom out in
------------------------------------------------------------------
function LWnd:TweenSeq_ScaleZoomOutIn(seqKey, childPath,interval)
	local trans = childPath
	if (type(trans) == 'string') then
		trans = self:FindWndTrans(nil, childPath)
	end
	return self:TweenSeqCreate(seqKey, function(seq)
		local scaleOutMax = 1.1
		local scaleOutTime = 0.2
		local scaleInTime = 0.1
		local tweener
		tweener = trans:DOScale(Vector3(scaleOutMax,scaleOutMax,scaleOutMax), scaleOutTime)
		seq:Append(tweener)
		tweener = trans:DOScale(Vector3.one, scaleInTime)
		seq:Append(tweener)
		seq:AppendInterval(interval or 1)
		tweener = trans:DOScale(Vector3(scaleOutMax,scaleOutMax,scaleOutMax), scaleInTime)
		seq:Append(tweener)
		tweener = trans:DOScale(Vector3.zero, scaleOutTime)
		seq:Append(tweener)
		return seq
	end)
end
------------------------------------------------------------------
--- position pop
------------------------------------------------------------------
function LWnd:TweenSeq_PositionPop(seqKey, childPath,pos)
	local trans = childPath
	if (type(trans) == 'string') then
		trans = self:FindWndTrans(nil, childPath)
	end
	return self:TweenSeqCreate(seqKey, function(seq)
		local time = 0.2
		local tweener
		tweener = trans:DOLocalMove(pos, time)
		seq:Append(tweener)
		return seq
	end)
end
------------------------------------------------------------------
--- banana
--- 不可重用
------------------------------------------------------------------
function LWnd:TweenSeq_CurveBanana(seqKey, childPath,pos)
	local trans = childPath
	if (type(trans) == 'string') then
		trans = self:FindWndTrans(nil, childPath)
	end
	return self:TweenSeqCreate(seqKey, function(seq)
		local time = 0.2
		local curveFun = LCurveUtil.Banana(trans.localPosition,pos,time)
		local tweener = YXTween.TweenFloat(0,1,time, function(t)
			local p = curveFun(t)
			trans.localPosition = p
		end)
		seq:Append(tweener)
		return seq
	end)
end
------------------------------------------------------------------
--- 飘字
------------------------------------------------------------------
function LWnd:TweenSeq_Flutter(seqKey, childPath, targetPos, time)
	local trans = childPath
	if (type(trans) == 'string') then
		trans = self:FindWndTrans(nil, childPath)
	end
	return self:TweenSeqCreate(seqKey, function(seq)
		time = time or 0.8
		targetPos = targetPos or 35
		local tweener
		tweener = trans:DOLocalMoveY(trans.localPosition.y + targetPos, time)
		seq:Append(tweener)
		return seq
	end)
end
------------------------------------------------------------------
--- 放大缩小(循环)
------------------------------------------------------------------
function LWnd:TweenSeq_LoopScale(seqKey, childPath)
	local trans = childPath
	if (type(trans) == 'string') then
		trans = self:FindWndTrans(nil, childPath)
	end
	return self:TweenSeqCreate(seqKey , function(seq)
		local time = 0.8
		local tweener1 = trans.transform:DOScale(Vector3(1.4,1.4,1.4), time)
		seq:Append(tweener1)
		local tweener2 = trans.transform:DOScale(Vector3.one, time)
		seq:Append(tweener2)
		seq:SetLoops(-1)
		return seq
	end)
end
------------------------------------------------------------------
--- 放大缩小n倍
------------------------------------------------------------------
function LWnd:TweenSeq_DefalutScale(seqKey, childPath, info)
	local trans = childPath
	if (type(trans) == 'string') then
		trans = self:FindWndTrans(nil, childPath)
	end
	self:TweenSeqKill(seqKey)
	local scaleX = info.x or 1
	local scaleY = info.y or 1
	local scaleZ = info.z or 1
	local time = info.time or 0.8
	local loopNum = info.loopNum or -1
	local recover = info.recover or false
	local seqTween = self:TweenSeqCreate(seqKey , function(seq)
		local tweener1 = trans.transform:DOScale(Vector3(scaleX,scaleY,scaleZ), time)
		seq:Append(tweener1)
		if recover then
			local tweener2 = trans.transform:DOScale(Vector3.one, time)
			seq:Append(tweener2)
		end
		seq:SetLoops(loopNum)
		return seq
	end)
	seqTween:OnComplete(function()
		self:TweenSeqKill(seqKey)
	end)
	seqTween:PlayForward()
end
------------------------------------------------------------------
--- 画卷界面展开
------------------------------------------------------------------
function LWnd:TweenSeq_Pictrue(seqKey,childPath,canvasPath,width,FormHeigth,ToHeigth)
	local trans = childPath:GetComponent(typeRectTransform)
	if (type(trans) == 'string') then
		trans = self:FindWndTrans(nil, childPath):GetComponent(typeRectTransform)
	end

	local canvas = canvasPath:GetComponent(typeofCanvasGroup)
	if (type(trans) == 'string') then
		canvas = self:FindWndTrans(nil, canvasPath):GetComponent(typeofCanvasGroup)
	end

	return self:TweenSeqCreate(seqKey , function(seq)
		local time = 0.4
		local tweener1 	= YXTween.TweenInt(FormHeigth, ToHeigth, time,function(ival)
			trans.sizeDelta = Vector2(width,ival)
		end)
		local tweener2 = CS.YXDOTweenModuleUI.DOFade(canvas, 1, time):SetEase(EaseOutCubic)
		seq:AppendInterval(0.1)
		seq:Append(tweener1)
		seq:Append(tweener2)
		return seq
	end)
end
------------------------------------------------------------------
--- 渐隐渐显 wndTrans
------------------------------------------------------------------
function LWnd:TweenSeq_AlphaInOut(isVisible, toTime, fromAlpha, toAlpha)
	local seqKey = "LWnd_Tween_Alpha"
	local seq = self:TweenSeqFind(seqKey)
	if (seq) then
		if (isVisible) then
			self._TweenSeq_AlphaInOut = isVisible
			return 
		end
		self:TweenSeqKill(seqKey)
		seq = nil
	end
	if (not self:IsWndValid()) then
		return 
	end
	local trans = self._wndTrans
	local csCanvasGroup = trans:GetComponent(typeofCanvasGroup)
	fromAlpha = fromAlpha or csCanvasGroup.alpha
	toAlpha = toAlpha or 0
	toTime = toTime or 0.33
	if (isVisible) then
		toAlpha = 1
		toTime = toTime or 0.33
	end
	if (fromAlpha == toAlpha) then
		return 
	end
	csCanvasGroup.alpha = fromAlpha
	csCanvasGroup.interactable = false
	csCanvasGroup.blocksRaycasts = false
	seq =
	self:TweenSeqCreate(seqKey, function(seq)
		if (isVisible) then
			seq:AppendInterval(0.7)
		end
		local tween1 =
		YXTween.TweenFloat(fromAlpha, toAlpha, toTime, function(ival)
			csCanvasGroup.alpha = ival
		end):SetEase(EaseInQuad)
		seq:Append(tween1)
		return seq
	end)
	seq:PlayForward()
	seq:OnStepComplete(function()
		self:TweenSeqKill(seqKey)
		if (isVisible) then
			csCanvasGroup.interactable = true
			csCanvasGroup.blocksRaycasts = true
		end
		local wndVisibleWait = self._TweenSeq_AlphaInOut
		if (wndVisibleWait ~= nil) then
			self:TweenSeq_AlphaInOut(wndVisibleWait)
		end
		self._TweenSeq_AlphaInOut = nil
	end)

end

------------------------------------------------------------------
--- 节点渐隐渐显
--- aniInfo.beforeFunc：动画开始前执行函数
--- aniInfo.aniKey：动画key
--- aniInfo.trans：节点
--- aniInfo.initAlpha：初始化透明度
--- aniInfo.fromAlpha：开始透明度
--- aniInfo.toAlpha：结束透明度
--- aniInfo.toTime：动画时间
--- aniInfo.isVisible：是否渐现
--- aniInfo.loopNum：循环次数
--- aniInfo.endFunc：动画结束执行函数
------------------------------------------------------------------
function LWnd:TweenSeq_RootAlphaInOut(aniInfo)
	if not aniInfo then return end
	local beforeFunc = aniInfo.beforeFunc
	local seqKey = aniInfo.aniKey
	local trans = aniInfo.trans
	local initAlpha = aniInfo.initAlpha
	local isVisible = aniInfo.isVisible

	local seqTween = self:TweenSeqFind(seqKey)
	if seqTween then
		self:TweenSeqKill(seqKey)
		seqTween = nil
	end
	if not self:IsWndValid() then return end

	local csCanvasGroup = trans:GetComponent(typeofCanvasGroup)
	if (not csCanvasGroup) then
		csCanvasGroup = trans.gameObject:AddComponent(typeofCanvasGroup)
		if initAlpha then csCanvasGroup.alpha = 0 end
	end
	if beforeFunc then beforeFunc() end
	local fromAlpha = aniInfo.fromAlpha or csCanvasGroup.alpha
	local toAlpha = aniInfo.toAlpha or 0
	local toTime = aniInfo.toTime or 0.33
	local loopNum = aniInfo.loopNum
	local endFunc = aniInfo.endFunc
	if isVisible then
		toAlpha = 1
		toTime = toTime or 0.33
	end
	if (fromAlpha == toAlpha) then return end
	if not trans.gameObject.activeSelf and fromAlpha == 0 then
		CS.ShowObject(trans,true)
	end
	local isGoBackInit = aniInfo.isGoBackInit
	csCanvasGroup.alpha = fromAlpha
	csCanvasGroup.interactable = false
	csCanvasGroup.blocksRaycasts = false
	seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local tween1 = YXTween.TweenFloat(fromAlpha, toAlpha, toTime, function(ival)
			csCanvasGroup.alpha = ival
		end):SetEase(EaseInQuad)
		seq:Append(tween1)
		if isGoBackInit then
			local tween2 = YXTween.TweenFloat(toAlpha, fromAlpha, toTime, function(ival)
				csCanvasGroup.alpha = ival
			end):SetEase(EaseInQuad)
			seq:Append(tween2)
		end
		return seq
	end)
	if loopNum then
		seqTween:SetLoops(loopNum)
	end
	if aniInfo.ignoreTimeScale then
		seqTween:SetUpdate(aniInfo.ignoreTimeScale)
	end
	local completeFunc = function()
		self:TweenSeqKill(seqKey)
		if isVisible then
			csCanvasGroup.interactable = true
			csCanvasGroup.blocksRaycasts = true
		end
		if endFunc then
			endFunc()
		end
	end
	if loopNum then
		seqTween:OnComplete(function()
			completeFunc()
		end)
	else
		seqTween:OnStepComplete(function()
			completeFunc()
		end)
	end
	seqTween:PlayForward()

end

------------------------------------------------------------------
--- 放大/缩小 LayoutElement
------------------------------------------------------------------
function LWnd:TweenSeq_Scale_LayoutElement(seqKey, trans, fromW, fromH, toW, toH, toTime)
	local seqTween = self:TweenSeqFind(seqKey)
	if (seqTween) then
		return 
	end
	local csLayoutElement = trans:GetComponent(typeof_LayoutElement)
	if (not csLayoutElement) then
		csLayoutElement = trans.gameObject:AddComponent(typeof_LayoutElement)
	end
	if (csLayoutElement.preferredWidth == toW and csLayoutElement.preferredHeight == toH) then
		return 
	end
	seqTween =
		self:TweenSeqCreate(seqKey, function(seq)
			local tweener
			tweener = YXTween.TweenInt(fromW, toW, toTime, function(intVal)
				csLayoutElement.preferredWidth = intVal
			end)
			seq:Insert(0, tweener)
			tweener = YXTween.TweenInt(fromH, toH, toTime, function(intVal)
				csLayoutElement.preferredHeight = intVal
			end)
			seq:Insert(0, tweener)
			return seq
		end)
	csLayoutElement.preferredWidth = fromW
	csLayoutElement.preferredHeight = fromH
	seqTween:PlayForward()
	seqTween:OnStepComplete(function()
		self:TweenSeqKill(seqKey)
		csLayoutElement.preferredWidth = toW
		csLayoutElement.preferredHeight = toH
	end)
	return seqTween
end

------------------------------------------------------------------
--- 对象渐显+偏移归位
------------------------------------------------------------------
function LWnd:TweenSeq_AlphaOut_Offset(seqKey, trans, offsetX, offsetY, delayIndex, delayAddTime)
	local seqTween = self:TweenSeqFind(seqKey)
	if (seqTween) then
		return 
	end
	local csCanvasGroup = trans:GetComponent(typeofCanvasGroup)
	if (not csCanvasGroup) then
		csCanvasGroup = trans.gameObject:AddComponent(typeofCanvasGroup)
	end
	delayAddTime = delayAddTime or 0
	seqTween =
		self:TweenSeqCreate(seqKey, function(seq)
			local tweener
			tweener = csCanvasGroup:DOFade(1, 0.033*6):SetDelay(0.033*3 * delayIndex + delayAddTime)
			seq:Insert(0, tweener)
			tweener = csCanvasGroup.transform:DOLocalMoveY(0, 0.033*6):SetDelay(0.033*3 * delayIndex + delayAddTime)
			seq:Insert(0, tweener)
			return seq
		end)
	csCanvasGroup.alpha = 0
	csCanvasGroup.transform.localPosition = Vector2.New(offsetX, offsetY)
	seqTween:PlayForward()
	seqTween:OnStepComplete(function()
		self:TweenSeqKill(seqKey)
	end)
	return seqTween
end

------------------------------------------------------------------
--- 渐显-停留-消失
------------------------------------------------------------------
function LWnd:TweenSeq_FadeInStaysAway(seqKey, trans, info)
	if CS.IsNullObject(trans) then return end
	local seq = self:TweenSeqFind(seqKey)
	if seq then
		self:TweenSeqKill(seqKey)
		seq = nil
	end
	if (not self:IsWndValid()) then return end

	if not info then info = {} end

	local easeType = info.easeType or EaseInQuad
	local showTime = info.showTime or 0.2
	local waitTime = info.waitTime or 3
	local noShowTime = info.noShowTime or 0.2
	local fromAlpha = info.fromAlpha or 0
	local toAlpha = info.toAlpha or 1
	local completeFunc = info.completeFunc
	local runFunc = info.runFunc
	local endFunc = info.endFunc
	local isLoop = info.isLoop
	local openInteractable = info.openInteractable or false

	local csCanvasGroup = trans:GetComponent(typeofCanvasGroup)
	if (not csCanvasGroup) then
		csCanvasGroup = trans.gameObject:AddComponent(typeofCanvasGroup)
	end

	csCanvasGroup.alpha = fromAlpha
	csCanvasGroup.interactable = openInteractable
	csCanvasGroup.blocksRaycasts = openInteractable
	if not trans.gameObject.activeSelf and fromAlpha == 0 then
		CS.ShowObject(trans,true)
	end

	seq = self:TweenSeqCreate(seqKey, function(seq)
		local tween1
		if showTime ~= 0 then
			tween1 = YXTween.TweenFloat(fromAlpha, toAlpha, showTime, function(ival)
				csCanvasGroup.alpha = ival
			end):SetEase(easeType)
		end
		if tween1 then seq:Append(tween1) end
		local newTime = showTime + waitTime
		seq:InsertCallback(newTime,function()
			if runFunc then runFunc() end
		end)
		local tween2 = YXTween.TweenFloat(toAlpha, fromAlpha, noShowTime, function(ival)
			csCanvasGroup.alpha = ival
		end):SetEase(easeType)
		seq:Append(tween2)

		if endFunc then
			local endTime = showTime + waitTime + noShowTime
			seq:InsertCallback(endTime,function()
				if endFunc then endFunc() end
			end)
		end

		if isLoop then
			seq:SetLoops(-1,Tweening.LoopType.Restart)
		end
		return seq
	end)

	seq:OnComplete(function()
		self:TweenSeqKill(seqKey)
		csCanvasGroup.interactable = true
		csCanvasGroup.blocksRaycasts = true
		if completeFunc then
			completeFunc(seqKey)
		end
	end)
	seq:PlayForward()

	return seq
end

------------------------------------------------------------------
--- 列表滚动自动滚动效果
------------------------------------------------------------------
function LWnd:TweenSeq_UIListAutoMove(seqKey,transList,move,moveTime,textTransName,callFunc)
	if not seqKey then return end
	if #transList <= 0 then return end
	if (not self:IsWndValid()) then return end
	local seqTween = self:TweenSeqFind(seqKey)
	if seqTween then
		self:TweenSeqKill(seqKey)
		seqTween = nil
	end
	seqTween = self:TweenSeqCreate(seqKey, function(seq)
		if not moveTime then moveTime = 0.5 end
		if not textTransName then textTransName = "UIText" end
		local tweener
		local len = #transList
		for i,v in ipairs(transList) do
			if not move then
				move = v.localPosition.y + 10
			end
			CS.ShowObject(v,true)
			local vec = Vector3(v.localPosition.x,v.localPosition.y + move)
			tweener = v:DOLocalMove(vec,moveTime)
			seq:Join(tweener)

			local text = self:FindWndTrans(v,textTransName)
			local canvasGroup = text:GetComponent(typeofCanvasGroup)
			if (not canvasGroup) then
				canvasGroup = v.gameObject:AddComponent(typeofCanvasGroup)
			end
			if canvasGroup then
				local taskAlpha = 0
				if i == len - 2 then
					taskAlpha = 0.6
				elseif i == len - 1 then
					taskAlpha =0.8
				elseif i == len then
					taskAlpha = 1
				end
				local tween = canvasGroup:DOFade(taskAlpha,1)
				seq:Join(tween)
			end
		end
		return seq
	end)
	seqTween:PlayForward()
	seqTween:OnComplete(function()
		self:TweenSeqKill(seqKey)
		if callFunc then
			callFunc()
		end
	end)
end

------------------------------------------------------------------
--- 抖动效果
------------------------------------------------------------------
function LWnd:TweenSeq_ShakeTrans(seqKey, trans, strength, time, completeFunc, easeType)
	if CS.IsNullObject(trans) then
		return
	end
	time = time or 0.5
	strength = strength or 1

	local seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local shake = trans:DOShakePosition(time, strength)
		if easeType then
			shake:SetEase(easeType)
		end
		seq:Join(shake)
		return seq
	end)

	seqTween:OnComplete(function()
		self:TweenSeqKill(seqKey)
		if completeFunc then
			completeFunc(seqKey)
		end
	end)

	seqTween:PlayForward()

	return seqTween
end

------------------------------------------------------------------
--- 悬浮效果
------------------------------------------------------------------
function LWnd:TweenSeq_Suspend(seqKey,trans,fromPos,toPos,time,completeFunc,easeType,isLoop,ignoreTimeScale)
	if CS.IsNullObject(trans) then
		return
	end
	if not seqKey then
		return
	end
	time = time or 0.2

	if fromPos then
		trans.localPosition = fromPos
	end

	local seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local move = trans:DOLocalMove(toPos, time)
		if easeType then
			move:SetEase(easeType)
		end
		seq:Join(move)

		if isLoop then
			seq:SetLoops(-1,Tweening.LoopType.Yoyo)
		end

		return seq
	end)

	if ignoreTimeScale then
		seqTween:SetUpdate(ignoreTimeScale)
	end

	seqTween:OnComplete(function()
		self:TweenSeqKill(seqKey)
		if completeFunc then
			completeFunc(seqKey)
		end
	end)

	seqTween:PlayForward()

	return seqTween
end


------------------------------------------------------------------
--- 偏移，渐现，偏移，消失
------------------------------------------------------------------
function LWnd:TweenSeq_MoveFadeInStaysAway(seqKey,transInfo,info)
	local trans = transInfo.trans
	seqKey = seqKey or trans:GetInstanceID()
	local seq = self:TweenSeqFind(seqKey)
	if seq then
		self:TweenSeqKill(seqKey)
		seq = nil
	end
	if (not self:IsWndValid()) then return end
	local transP = transInfo.transP
	info = info or {}
	local initPos = info.initPos
	if initPos then
		trans.localPosition = initPos
	end
	local csCanvasGroup = trans:GetComponent(typeofCanvasGroup)
	if (not csCanvasGroup) then
		csCanvasGroup = trans.gameObject:AddComponent(typeofCanvasGroup)
		csCanvasGroup.alpha = 0
	end
	if transP then CS.ShowObject(transP,true) end
	CS.ShowObject(trans,true)

	local fromAlpha = info.fromAlpha or 0
	local toAlpha = info.toAlpha or 1
	local showTime = info.showTime or 0.5
	local waitTime = info.waitTime or 0.5
	local noShowTime = info.noShowTime	or 0.5

	local pos = info.pos
	if not pos then
		local curTransLocalPosition = trans.localPosition
		pos = Vector3(curTransLocalPosition.x,curTransLocalPosition.y + 40,curTransLocalPosition.z)
	end
	local toPos = info.toPos
	if not toPos then
		toPos = Vector3(pos.x,pos.y + 40,pos.z)
	end
	local inQuadEaseType = info.easeType or EaseInQuad
	local outQuadEaseType = info.easeType or EaseOutSine

	seq = self:TweenSeqCreate(seqKey, function(seq)
		local tweenShowAlpha = YXTween.TweenFloat(fromAlpha, toAlpha, showTime, function(ival)
			csCanvasGroup.alpha = ival
		end):SetEase(inQuadEaseType)
		seq:Append(tweenShowAlpha)
		local tweenMoveTo = trans:DOLocalMove(pos, showTime)
		seq:Join(tweenMoveTo):SetEase(inQuadEaseType)

		local newTime = showTime + waitTime
		seq:AppendInterval(newTime)

		local tween2 = YXTween.TweenFloat(toAlpha, fromAlpha, noShowTime, function(ival)
			csCanvasGroup.alpha = ival
		end):SetEase(outQuadEaseType)
		seq:Append(tween2)
		local tweenMoveToHide = trans:DOLocalMove(toPos, showTime)
		seq:Join(tweenMoveToHide):SetEase(outQuadEaseType)

		return seq
	end)

	seq:OnComplete(function()
		self:TweenSeqKill(seqKey)
		CS.ShowObject(trans,false)
	end)
	seq:PlayForward()
end

function LWnd:TweenSeq_MoveFadeInStaysAwayList(seqKey,transInfoList,info,callBack)
	local seq = self:TweenSeqFind(seqKey)
	if seq then
		self:TweenSeqKill(seqKey)
		seq = nil
	end
	if not transInfoList or #transInfoList < 1 then return end
	if (not self:IsWndValid()) then return end

	local transLen = #transInfoList
	local showAniTime = 0.1

	local showTime = info.showTime or 0.5
	local waitTime = info.waitTime or 0.5
	local noShowTime = info.noShowTime	or 0.5

	local showTimeS = (showTime + waitTime + noShowTime) * transLen - transLen * showAniTime

	seq = self:TweenSeqCreate(seqKey, function(seq)
		for i,transInfo in ipairs(transInfoList) do
			seq:AppendCallback(function ()
				self:TweenSeq_MoveFadeInStaysAway(nil,transInfo,info)
			end)
			seq:AppendInterval(showAniTime)
		end
		seq:AppendInterval(showTimeS)
		return seq
	end)

	seq:OnComplete(function()
		self:TweenSeqKill(seqKey)
		for i,v in ipairs(transInfoList) do
			if v.transP then CS.ShowObject(v.transP,false) end
		end
		if callBack then
			callBack()
		end
	end)
	seq:PlayForward()

end


------------------------------------------------------------------
--- 拓展参数
--- extraData.initAlpha：初始化节点透明度
--- extraData.startShowFunc：开始处理函数
--- extraData.fromAlpha：渐隐开始透明度
--- extraData.toAlpha：渐隐结束透明度
--- extraData.vanishTime：渐隐时间
--- extraData.showFromAlpha：渐现开始透明度，没有传参数则使用 extraData.toAlpha
--- extraData.showToAlpha：渐现结束透明度，没有传参数则使用 extraData.fromAlpha
--- extraData.nextShowAni：是否需要渐现动画
--- extraData.nextShowFunc：渐现动画处理函数
--- extraData.showTime：渐现时间
--- extraData.endFunc：动画结束执行函数
---
--- 节点列表参数
--- transInfo.trans：节点
--- transInfo.aniStarPos：节点渐隐动画开始初始化位置
--- transInfo.vanishPos：节点需要移动到渐隐位置
--- transInfo.aniShowPos：节点渐现动画开始初始化位置
--- transInfo.showPos：节点需要移动到渐现位置
------------------------------------------------------------------
function LWnd:TweenSeq_MoveFadeAni(seqKey,transInfoList,extraData)
	if not seqKey then
		printInfoNR("没有对应的seqKey")
		return
	end

	local seqTween = self:TweenSeqFind(seqKey)
	if seqTween then
		self:TweenSeqKill(seqKey)
		seqTween = nil
	end

	transInfoList = transInfoList or {}
	local len = #transInfoList
	if len < 1 then return end

	extraData = extraData or {}

	local initAlpha = extraData.initAlpha or 0

	for i,transInfo in ipairs(transInfoList) do
		local trans = transInfo.trans
		local csCanvasGroup = trans:GetComponent(typeofCanvasGroup)
		if (not csCanvasGroup) then
			csCanvasGroup = trans.gameObject:AddComponent(typeofCanvasGroup)
		end
		csCanvasGroup.alpha = initAlpha
	end

	local startShowFunc = extraData.startShowFunc
	if startShowFunc then
		startShowFunc()
	end

	local fromAlpha = extraData.fromAlpha or 0
	local toAlpha = extraData.toAlpha or 1
	local vanishTime = extraData.vanishTime or 0.5

	local inQuadEaseType = extraData.easeType or EaseInQuad

	local nextShowAni = extraData.nextShowAni or false

	seqTween = self:TweenSeqCreate(seqKey, function(seq)
		for i,transInfo in ipairs(transInfoList) do
			local trans = transInfo.trans
			local aniStarPos = transInfo.aniStarPos
			if aniStarPos then
				trans.localPosition = aniStarPos
			end

			local csCanvasGroup = trans:GetComponent(typeofCanvasGroup)
			local tweenShowAlpha = YXTween.TweenFloat(fromAlpha, toAlpha, vanishTime, function(ival)
				csCanvasGroup.alpha = ival
			end):SetEase(inQuadEaseType)
			seq:Append(tweenShowAlpha)

			local vanishPos = transInfo.vanishPos
			local tweenMoveTo = trans:DOLocalMove(vanishPos, vanishTime)
			seq:Join(tweenMoveTo):SetEase(inQuadEaseType)
		end

		if nextShowAni then
			local payAniTime = len * vanishTime
			seq:AppendInterval(payAniTime)
			seq:AppendCallback(function()
				local nextShowFunc = extraData.nextShowFunc
				if nextShowFunc then
					nextShowFunc()
				end

				for i,transInfo in ipairs(transInfoList) do
					local trans = transInfo.trans
					local aniShowPos = transInfo.aniShowPos
					if aniShowPos then
						trans.localPosition = aniShowPos
					end
				end
			end)

			local showTime = extraData.showTime or 0.5
			local showFromAlpha = extraData.showFromAlpha or toAlpha
			local showToAlpha = extraData.showToAlpha or fromAlpha
			for i,transInfo in ipairs(transInfoList) do
				local trans = transInfo.trans
				local csCanvasGroup = trans:GetComponent(typeofCanvasGroup)
				local tweenShowAlpha = YXTween.TweenFloat(showFromAlpha, showToAlpha, showTime, function(ival)
					csCanvasGroup.alpha = ival
				end):SetEase(inQuadEaseType)
				seq:Append(tweenShowAlpha)

				local showPos = transInfo.showPos
				local tweenMoveTo = trans:DOLocalMove(showPos, vanishTime)
				seq:Join(tweenMoveTo):SetEase(inQuadEaseType)
			end
		end

		return seq
	end)

	seqTween:OnComplete(function()
		self:TweenSeqKill(seqKey)

		local endFunc = extraData.endFunc
		if endFunc then
			endFunc()
		end
	end)

	seqTween:PlayForward()
end

------------------------------------------------------------------
--- 旋转效果
------------------------------------------------------------------
function LWnd:TweenSeq_Rotate(trans,info)
	if CS.IsNullObject(trans) then
		return
	end
	info = info or {}
	local seqKey = info.seqKey or trans:GetInstanceID()
	self:TweenSeqKill(seqKey)
	local showTime = info.showTime or 18
	local rotateX = info.rotateX or 0
	local rotateY = info.rotateY or 0
	local rotateZ = info.rotateZ or 0
	local seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local runRotateTween = trans.transform:DORotate(Vector3.New(rotateX,rotateY,rotateZ),showTime)
		seq:Append(runRotateTween)
		return seq
	end)
	local isLoop = info.loop or false
	if isLoop then
		local restartType = info.restartType or DG.Tweening.LoopType.Restart
		seqTween:SetLoops(-1,restartType)
	end
	seqTween:OnComplete(function()
		self:TweenSeqKill(seqKey)
	end)

	seqTween:PlayForward()

	return seqTween
end

function LWnd:TweenSeq_LocalRotate(trans,info)
	if CS.IsNullObject(trans) then
		return
	end
	info = info or {}
	local seqKey = info.seqKey or trans:GetInstanceID()
	self:TweenSeqKill(seqKey)
	local showTime = info.showTime or 18
	local rotateX = info.rotateX or 0
	local rotateY = info.rotateY or 0
	local rotateZ = info.rotateZ or 0
	local seqTween = self:TweenSeqCreate(seqKey, function(seq)
		local runRotateTween = trans.transform:DOLocalRotate(Vector3.New(rotateX,rotateY,rotateZ),showTime,FastBeyond360)
		seq:Append(runRotateTween)
		return seq
	end)
	local isLoop = info.loop or false
	if isLoop then
		local restartType = info.restartType or DG.Tweening.LoopType.Restart
		seqTween:SetLoops(-1,restartType)
	end
	seqTween:OnComplete(function()
		self:TweenSeqKill(seqKey)
	end)

	seqTween:PlayForward()

	return seqTween
end

------------------------------------------------------------------
--- 来回移动效果，兼容中间停顿也就是 "来-停-回-停-来"  的节奏
------------------------------------------------------------------
function LWnd:TweenSeq_MoveAndBack(seqKey,trans,fromPos,toPos,time,beginTime, backTime, completeFunc,easeType,isLoop,ignoreTimeScale)
	if CS.IsNullObject(trans) then
		return
	end
	if not seqKey then
		return
	end
	time = time or 0.5

	if fromPos then
		trans.localPosition = fromPos
	end

	local seqTween = self:TweenSeqCreate(seqKey, function(seq)
		if beginTime then
			seq:AppendInterval(beginTime)
		end

		local move = trans:DOLocalMove(toPos, time)
		if easeType then
			move:SetEase(easeType)
		end
		seq:Append(move)

		if backTime then
			seq:AppendInterval(backTime)
		end

		local back = trans:DOLocalMove(fromPos, time)
		if easeType then
			back:SetEase(easeType)
		end
		seq:Append(back)

		if isLoop then
			seq:SetLoops(-1,Tweening.LoopType.Restart)
		end

		return seq
	end)

	if ignoreTimeScale then
		seqTween:SetUpdate(ignoreTimeScale)
	end

	seqTween:OnComplete(function()
		self:TweenSeqKill(seqKey)
		if completeFunc then
			completeFunc(seqKey)
		end
	end)
	seqTween:PlayForward()

	return seqTween
end
