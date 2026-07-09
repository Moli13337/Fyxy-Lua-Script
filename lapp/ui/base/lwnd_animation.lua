------------------------------------------------------------------
-- 界面动画
------------------------------------------------------------------

------------------------------------------------------------------
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local typeofRectTransform = typeof(UnityEngine.RectTransform)
local typeofYXUIWndAnimationRoot = typeof(CS.YXUIWndAnimationRoot)
local typeofLayoutGroup = typeof(CS.LayoutGroup)
local Tweening = DG.Tweening
local UnityEngine = UnityEngine
local TweeningEase = 
{
	[1] =	  Tweening.Ease.Linear,
    [2] =	  Tweening.Ease.InSine,
    [3] =     Tweening.Ease.OutSine,
    [4] =     Tweening.Ease.InOutSine,
    [5] =     Tweening.Ease.InQuad,
    [6] =     Tweening.Ease.OutQuad,
    [7] =     Tweening.Ease.InOutQuad,
    [8] =     Tweening.Ease.InCubic,
    [9] =     Tweening.Ease.OutCubic,
    [10] =    Tweening.Ease.InOutCubic,
    [11] =    Tweening.Ease.InQuart,
    [12] =    Tweening.Ease.OutQuart,
    [13] =    Tweening.Ease.InOutQuart,
    [14] =    Tweening.Ease.InQuint,
    [15] =    Tweening.Ease.OutQuint,
    [16] =    Tweening.Ease.InOutQuint,
    [17] =    Tweening.Ease.InExpo,
    [18] =    Tweening.Ease.OutExpo,
    [19] =    Tweening.Ease.InOutExpo,
    [20] =    Tweening.Ease.InCirc,
    [21] =    Tweening.Ease.OutCirc,
    [22] =    Tweening.Ease.InOutCirc,
    [23] =    Tweening.Ease.InElastic,
    [24] =    Tweening.Ease.OutElastic,
    [25] =    Tweening.Ease.InOutElastic,
    [26] =    Tweening.Ease.InBack,
    [27] =    Tweening.Ease.OutBack,
    [28] =    Tweening.Ease.InOutBack,
    [29] =    Tweening.Ease.InBounce,
    [30] =    Tweening.Ease.OutBounce,
    [31] =    Tweening.Ease.InOutBounce,
    [32] =    Tweening.Ease.Flash,
    [33] =    Tweening.Ease.InFlash,
    [34] =    Tweening.Ease.OutFlash,
    [35] =    Tweening.Ease.InOutFlash,
}

------------------------------------------------------------------
---@type LWnd
local LWnd = LWnd
-----------------------------------------------------------------
-- 创建窗口后，尝试运行界面动画
function LWnd:InitWndAnimation(endCall)
	local wndName = self:GetWndName()
    local wndAniRef = GameTable.UIWindowAniRef[wndName]
	if not wndAniRef then
		return false
	end
	local aniCfg = wndAniRef.wndOpenAni
	if wndAniRef.wndAniType == 0 then
		return false
	end
	local trans = nil
	local aniTypeRef = nil
	local aniItemMap = self:_ParseAniConfig(aniCfg)
	if not aniItemMap then
		aniItemMap = self:_GetWndAniDefaultConfig("Open")
	end
	
	local aniCount = 0
	local aniEndCount = 0
	local function onAniStepEnd()
		aniEndCount = aniEndCount + 1
		if aniEndCount >= aniCount then
			endCall()
		end
	end
	
	local hasAni = false
	for aniTag,aniTypeId in pairs(aniItemMap or {}) do
		aniTypeRef = GameTable.UIWindowAniTypeRef[aniTypeId]
		if aniTypeRef then
			if aniTag == wndName then
				trans = self:GetWndTrans()
			else
				trans = self:FindWndTrans(nil, aniTag)
			end
			if trans then
				aniCount = aniCount + 1
				hasAni = true
				self:_PlayWndAnimation(aniTypeRef, trans, 0,nil,onAniStepEnd)
			end
		end 
	end
	
	return hasAni
end
function LWnd:InitChildWndAnimation(endCall)
	local wndName = self:GetWndName()
    local wndAniRef = GameTable.UIWindowAniRef[wndName]
	if not wndAniRef then
		return false
	end
	local aniCfg = wndAniRef.wndOpenAni
	if wndAniRef.wndAniType == 0 then
		return false
	end
	
	local trans = nil
	local aniTypeRef = nil
	local aniItemMap = self:_ParseAniConfig(aniCfg)
	if not aniItemMap then
		aniItemMap = self:_GetWndAniDefaultConfig("OpenChild")
	end
	
	local aniCount = 0
	local aniEndCount = 0
	local function onAniStepEnd()
		aniEndCount = aniEndCount + 1
		if aniEndCount >= aniCount then
			endCall()
		end
	end
	
	local hasAni = false
	for aniTag,aniTypeId in pairs(aniItemMap or {}) do
		aniTypeRef = GameTable.UIWindowAniTypeRef[aniTypeId]
		if aniTypeRef then
			if aniTag == wndName then
				trans = self:GetWndTrans()
			else
				trans = self:FindWndTrans(nil, aniTag)
			end
			if trans then
				aniCount = aniCount + 1
				hasAni = true
				self:_PlayWndAnimation(aniTypeRef, trans, 0,nil,onAniStepEnd)
			end
		end 
	end
	
	return hasAni
end
-----------------------------------------------------------------
-- 尝试用动画的方式关闭界面
function LWnd:CloseWndAnimation()
	self:ClearAllWndAnimation()

	local wndName = self:GetWndName()
    local wndAniRef = GameTable.UIWindowAniRef[wndName]
	if not wndAniRef then
		return false
	end
	local aniCfg = wndAniRef.wndCloseAni
	if wndAniRef.wndAniType == 0 then
		return false
	end
	
	if self._wndGraphicRaycaster then
		self._wndGraphicRaycaster.enabled = false
	end
	
	local bHasCloseAni = false
	local trans = nil
	local aniTypeRef = nil
	local aniItemMap = self:_ParseAniConfig(aniCfg)
	if not aniItemMap then
		aniItemMap = self:_GetWndAniDefaultConfig("Close")
	end
	for aniTag,aniTypeId in pairs(aniItemMap or {}) do
		aniTypeRef = GameTable.UIWindowAniTypeRef[aniTypeId]
		if aniTypeRef then
			if aniTag == wndName then
				trans = self:GetWndTrans()
			else
				trans = self:FindWndTrans(nil, aniTag)
			end
			if trans then
				bHasCloseAni = true
				self:_PlayWndAnimation(aniTypeRef, trans, 0, 0, function()
					self:WndDestroy()
				end)
			end
		end 
	end
	
	return bHasCloseAni
end
-----------------------------------------------------------------
-- 列表创建后，做做一些动画预处理
function LWnd:OnWndListCreate(listObj)
	local listTrans = listObj:GetScrollTrans()
    if self:IsWndClosed() or CS.IsNullObject(listTrans) then
        return
    end
	
	local listName = listTrans.name
	local wndName = self:GetWndName()
	local wndAniRef = GameTable.UIWindowAniRef[wndName]
	if not wndAniRef then
		return
	end
	
	local aniTypeId = 0
	local aniCfg = wndAniRef.itemOpenAni
	
	if not string.isempty(aniCfg) then
		local aniItemMap = self:_ParseAniConfig(aniCfg) or {}
		aniTypeId = aniItemMap[listName] or 0
	else
		local aniTag = "OpenCell"
		aniTypeId = self:_GetItemAniDefaultConfig(aniTag..listObj:GetConstrainCount())
	end
	
	local aniTypeRef = GameTable.UIWindowAniTypeRef[aniTypeId]
	if not aniTypeRef then
		return
	end
	local itemOpenType = aniTypeRef.itemOpenType
	local itemLoadType = aniTypeRef.itemLoadType
	if wndAniRef then
		if wndAniRef.itemOpenType >= 0 then
			itemOpenType = wndAniRef.itemOpenType
		end
		if wndAniRef.itemLoadType >= 0 then
			itemLoadType = wndAniRef.itemLoadType
		end
	end
	listObj:SetItemLoadType(itemLoadType, itemOpenType)
end
-----------------------------------------------------------------
-- 新增列表Item的动画
function LWnd:PlayItemAnimation(listObj, itemTrans, itempos, aniTypeId)
	local listTrans = listObj:GetScrollTrans()
    if self:IsWndClosed() or CS.IsNullObject(itemTrans) or CS.IsNullObject(listTrans) then
        return
    end
	local bMove = listObj:IsAlreadyTouchMoved(itemTrans)
	local itemAniType = 0
	local wndAniRef, bReset
	local delayCount = 0
	if not aniTypeId then
		local wndName = self:GetWndName()
		wndAniRef = GameTable.UIWindowAniRef[wndName]
		if not wndAniRef then
			return
		end


		local listName = listTrans.name

		local aniCfg = nil
		bReset = listObj:GetRefreshCount() > 1
		--local bMove = (os.time() - listObj:GetBeginSysTime() > 0.5)


		if bMove then
			aniCfg = wndAniRef.itemMoveAni
		elseif bReset then
			aniCfg = wndAniRef.itemResetAni
		else
			aniCfg = wndAniRef.itemOpenAni
		end


		aniTypeId = 0
		-- 如果没有配置动画，尝试使用默认动画配置
		if not string.isempty(aniCfg) then
			local aniItemMap = self:_ParseAniConfig(aniCfg) or {}
			aniTypeId = aniItemMap[listName] or 0
		else
			local aniTag = nil
			if listObj:IsMultScroll() then
				if bMove then
					aniTag = "MoveCell"
				elseif bReset then
					aniTag = "ResetCell"
				else
					aniTag = "OpenCell"
				end
				aniTypeId = self:_GetItemAniDefaultConfig(aniTag..listObj:GetConstrainCount())
			else

			end
		end
	end

	if aniTypeId <= 0 then
		return
	end

	local aniTypeRef = GameTable.UIWindowAniTypeRef[aniTypeId]
	if not aniTypeRef then
		return
	end
	if wndAniRef then
		if bMove then
			itemAniType = aniTypeRef.itemMoveType
			if wndAniRef.itemMoveType >= 0 then
				itemAniType = wndAniRef.itemMoveType
			end
		elseif bReset then
			itemAniType = aniTypeRef.itemResetType
			if wndAniRef.itemResetType >= 0 then
				itemAniType = wndAniRef.itemResetType
			end
		else
			itemAniType = aniTypeRef.itemOpenType
			if wndAniRef.itemOpenType >= 0 then
				itemAniType = wndAniRef.itemOpenType
			end
		end
	else
		itemAniType = aniTypeRef.itemMoveType
	end

	if itemAniType == 0 then
		return
	end

	if CS.IsWebGL() then
		itemAniType = 2
	end

	local fromIdx = listObj:GetCurDrawFromIndex() or 0
	if itemAniType == 1 then
		delayCount = (itempos - 1 - fromIdx) % listObj:GetConstrainCount() 
	else 
		if listObj:IsReversePos() then
			delayCount = math.floor((listObj:GetDataSize()- itempos) / listObj:GetConstrainCount())
		else
			delayCount = math.floor((itempos - 1 - fromIdx) / listObj:GetConstrainCount())
			if delayCount < 0 then
				delayCount = 1
			end
		end
		
		if bMove then
			delayCount = 1
		end 
	end
	local layoutGroup = itemTrans:GetComponent(typeofLayoutGroup)
	if CS.IsValidObject(layoutGroup) then
		if not CS.LayoutRebuilder then
			CS.LayoutRebuilder = UnityEngine.UI.LayoutGroup
		end 
		self:_PlayWndAnimation(aniTypeRef, itemTrans, delayCount, 0, function()
			if CS.IsValidObject(itemTrans) then 
				local rect = itemTrans:GetComponent(typeofRectTransform)
				CS.LayoutRebuilder.MarkLayoutForRebuild(rect)
			end
		end, function()
			if CS.IsValidObject(itemTrans) then
				local rect = itemTrans:GetComponent(typeofRectTransform)
				CS.LayoutRebuilder.MarkLayoutForRebuild(rect)
			end
		end, true)
	else
		self:_PlayWndAnimation(aniTypeRef, itemTrans, delayCount,nil,nil,nil,true)
	end
	
end

function LWnd:ClearWndAnimation(itemTrans)
	if self:IsDestroy() or CS.IsNullObject(itemTrans) then
        return
    end
	if not self._wndAniTransPosMap or not self._wndAniTransScaleMap then
		return
	end
	
	local instanceId = itemTrans:GetInstanceID()
	self._wndAniTransPosMap[instanceId] = nil
	self._wndAniTransScaleMap[instanceId] = nil
	
	local seqTween = self._wndAniSeqMap[instanceId]
	if not seqTween then
		return
	end 
	seqTween:Kill(false)
	self._wndAniSeqMap[instanceId] = nil
	
	-- clear pos and scale org data
	local aniTrans = CS.FindTrans(itemTrans,"AniRoot")
	if not aniTrans then 
		aniTrans = CS.FindTrans(itemTrans,"Root")
	end
	if not aniTrans then 
		aniTrans = CS.FindTrans(itemTrans,"IconRoot")
	end
	
    if not aniTrans then 
		local childMaxIdx = itemTrans.childCount - 1
		local childTrans = nil
		for idx = 0, childMaxIdx do
			childTrans = itemTrans:GetChild(idx)
			local childInstanceId = childTrans:GetInstanceID()
			if self._wndAniTransScaleMap[childInstanceId]then
				childTrans.localScale = self._wndAniTransScaleMap[childInstanceId]
			end
			if self._wndAniTransPosMap[childInstanceId] then
				childTrans.localPosition = self._wndAniTransPosMap[childInstanceId]
			end
		
			self._wndAniTransPosMap[childInstanceId] = nil
			self._wndAniTransScaleMap[childInstanceId] = nil
		end
		
	else
		local aniInstanceId = aniTrans:GetInstanceID()
		if self._wndAniTransScaleMap[aniInstanceId]then
			aniTrans.localScale = self._wndAniTransScaleMap[aniInstanceId]
		end
		if self._wndAniTransPosMap[aniInstanceId] then
			aniTrans.localPosition = self._wndAniTransPosMap[aniInstanceId]
		end
		self._wndAniTransScaleMap[aniInstanceId] = nil
		self._wndAniTransPosMap[aniInstanceId] = nil 
	end
end
function LWnd:ClearAllWndAnimation()
    if not self._wndAniSeqMap then
        return
    end
	
	for id,seqTween in pairs(self._wndAniSeqMap or {}) do
        seqTween:Kill(false)
    end
	
	self._wndAniSeqMap = {}
	self._wndAniTransPosMap = {}
	self._wndAniTransScaleMap = {}
end
-----------------------------------------------------------------------
function LWnd:_PlayWndAnimation(aniTypeRef, trans, delayCnt, addDelayTime, completeFunc, updateFunc, isItem)
	local wndTrans = self:GetWndTrans()
	if not aniTypeRef or CS.IsNullObject(trans) or CS.IsNullObject(wndTrans) then
		if completeFunc then completeFunc() end
		return
	end
	addDelayTime = addDelayTime or 0
	delayCnt = delayCnt or 0
	local instanceId = trans:GetInstanceID()
	local seqTween = self._wndAniSeqMap[instanceId]
	if seqTween and seqTween:IsActive() then
		seqTween:Kill(false)
		self._wndAniSeqMap[instanceId] = nil
	end

	local bHasAniRoot = false

	local aniTrans = CS.FindTrans(trans,"AniRoot")
	local initScale = self:_ParseVector3Config(aniTypeRef.initScale)
	local initAlpha = aniTypeRef.initAlpha
	local initPos = self:_ParseVector3Config(aniTypeRef.initPos)
	local delayTime = aniTypeRef.delayTime * delayCnt + addDelayTime
	local aniScaleList = self:_ParseAniTypeScaleConfig(aniTypeRef.aniScale)
	local aniAlphaList = self:_ParseAniTypeAlphaConfig(aniTypeRef.aniAlpha)
	local aniPosList = self:_ParseAniTypePosConfig(aniTypeRef.aniPos)
	local bHasWndAni = false
	local bRecordPos = isItem or aniScaleList ~= nil
	local bRecordScale = isItem or aniPosList ~= nil

    if not aniTrans then 
		aniTrans = trans 
		
		local childMaxIdx = aniTrans.childCount - 1
		local childTrans = nil
		for idx = 0, childMaxIdx do
			childTrans = aniTrans:GetChild(idx)
			local childInstanceId = childTrans:GetInstanceID()
			if bRecordPos and not self._wndAniTransPosMap[childInstanceId] then
				self._wndAniTransPosMap[childInstanceId] = childTrans.localPosition
			end
			
			if bRecordScale and not self._wndAniTransScaleMap[childInstanceId] then
				self._wndAniTransScaleMap[childInstanceId] = childTrans.localScale
			end
		end
	else
		bHasAniRoot = true
	end
	local canvas = trans:GetComponent(typeofCanvasGroup)
	if CS.IsNullObject(canvas) then
		canvas = trans.gameObject:AddComponent(typeofCanvasGroup)
	end
	
	local effTrans = CS.FindTrans(aniTrans,"Eff")
	CS.ShowObject(effTrans, false)
	
	-- 头像框列表叫这个才可以实现功能
	if self._uiheadList then
		local headIconObj = self._uiheadList[trans:GetInstanceID()]
		if headIconObj and headIconObj.OnAniHeadFrame then
			headIconObj:OnAniHeadFrame(true)
		end
	end
	
	local aniRootObj = trans:GetComponent(typeofYXUIWndAnimationRoot)
	if aniRootObj then
		aniRootObj:SetNodesActive(false)
	end
	
	local aniInstanceId = aniTrans:GetInstanceID()
	local orgScale = self._wndAniTransScaleMap[aniInstanceId]
	if not orgScale then
		orgScale = aniTrans.localScale
		self._wndAniTransScaleMap[aniInstanceId] = orgScale
	end
	local orgPos = self._wndAniTransPosMap[aniInstanceId]
	if not orgPos then
		orgPos = aniTrans.localPosition
		self._wndAniTransPosMap[aniInstanceId] = orgPos
	end
	local seqTween = Tweening.DOTween.Sequence()
	seqTween:SetAutoKill(true)
	self._wndAniSeqMap[instanceId] = seqTween

	
	if bHasAniRoot then
		aniTrans.localScale = Vector3.Scale(initScale, orgScale)
		if initPos.x ~= 0 or initPos.y ~= 0 then
			aniTrans.localPosition = initPos + orgPos
		end
	else
		local childMaxIdx = aniTrans.childCount - 1
		local childTrans = nil
		for idx = 0, childMaxIdx do
			childTrans = aniTrans:GetChild(idx)
			local childInstanceId = childTrans:GetInstanceID()
			local childOrgPos = self._wndAniTransPosMap[childInstanceId]
			local childOrgScale = self._wndAniTransScaleMap[childInstanceId]
			if childOrgPos then
				if initPos.x ~= 0 or initPos.y ~= 0 then
					childTrans.localPosition = initPos + childOrgPos
				end
			end
			if childOrgScale then
				childTrans.localScale = Vector3.Scale(initScale, childOrgScale)
			end
		end
	end
	canvas.alpha = initAlpha
	
	if delayTime > 0 then
		seqTween:AppendInterval(delayTime)
	end
	
	if aniAlphaList then
		bHasWndAni = true
		local seqAlpha = Tweening.DOTween.Sequence()
		seqAlpha:SetAutoKill(true)
		for idx,alphaItem in ipairs(aniAlphaList) do
			local alphaTween = CS.YXDOTweenModuleUI.DOFade(canvas, alphaItem.aniValue, alphaItem.timeValue)
			if alphaItem.easeValue > 0 and alphaItem.easeValue < 36 then
				alphaTween:SetEase(TweeningEase[alphaItem.easeValue])
			end
			seqAlpha:Append(alphaTween)
		end
		seqTween:Append(seqAlpha)
	end
	
	if aniScaleList then
		bHasWndAni = true
		if bHasAniRoot then
			local seqScale = Tweening.DOTween.Sequence()
			seqScale:SetAutoKill(true)
			for idx,scaleItem in ipairs(aniScaleList) do
				local toScale = Vector3.Scale(scaleItem.aniValue, orgScale)
				local scaleTween = aniTrans:DOScale(toScale, scaleItem.timeValue)
				if scaleItem.easeValue > 0 and scaleItem.easeValue < 36 then
					scaleTween:SetEase(TweeningEase[scaleItem.easeValue])
				end
				seqScale:Append(scaleTween)
			end
			seqTween:Join(seqScale)
		else
			local childMaxIdx = aniTrans.childCount - 1
			local childTrans = nil
			for idx = 0, childMaxIdx do
				childTrans = aniTrans:GetChild(idx)
				local childInstanceId = childTrans:GetInstanceID()
				local childOrgScale = self._wndAniTransScaleMap[childInstanceId]
				if childOrgScale then
					local seqScale = Tweening.DOTween.Sequence()
					seqScale:SetAutoKill(true)
					for idx,scaleItem in ipairs(aniScaleList) do
						local toScale = Vector3.Scale(scaleItem.aniValue, childOrgScale)
						local scaleTween = childTrans:DOScale(toScale, scaleItem.timeValue)
						if scaleItem.easeValue > 0 and scaleItem.easeValue < 36 then
							scaleTween:SetEase(TweeningEase[scaleItem.easeValue])
						end
						seqScale:Append(scaleTween)
					end
					seqTween:Join(seqScale)
				end
			end
		end
		
	end
	
	if aniPosList then 
		bHasWndAni = true
		if bHasAniRoot then
			local seqPos = Tweening.DOTween.Sequence()
			seqPos:SetAutoKill(true)
			for idx,posItem in ipairs(aniPosList) do
				local moveTween = aniTrans:DOLocalMove(posItem.aniValue + orgPos, posItem.timeValue)
				if posItem.easeValue > 0 and posItem.easeValue < 36 then
					moveTween:SetEase(TweeningEase[posItem.easeValue])
				end
				seqPos:Append(moveTween)
			end
			seqTween:Join(seqPos)
		else
			local childMaxIdx = aniTrans.childCount - 1
			local childTrans = nil
			for idx = 0, childMaxIdx do
				childTrans = aniTrans:GetChild(idx)
				local childInstanceId = childTrans:GetInstanceID()
				local childOrgPos = self._wndAniTransPosMap[childInstanceId]
				if childOrgPos then
					local seqPos = Tweening.DOTween.Sequence()
					seqPos:SetAutoKill(true)
					for idx,posItem in ipairs(aniPosList) do
						local moveTween = childTrans:DOLocalMove(posItem.aniValue + childOrgPos, posItem.timeValue)
						if posItem.easeValue > 0 and posItem.easeValue < 36 then
							moveTween:SetEase(TweeningEase[posItem.easeValue])
						end
						seqPos:Append(moveTween)
					end
					seqTween:Join(seqPos)
				end 
			end
			
		end 
	end
	seqTween:AppendCallback(function()
		if completeFunc then 
			completeFunc() 
		end 
	end)
	seqTween:OnComplete(function() 
		CS.ShowObject(effTrans, true)
		-- 头像框列表叫这个才可以实现功能
		if self._uiheadList then
			local headIconObj = self._uiheadList[trans:GetInstanceID()]
			if headIconObj and headIconObj.OnAniHeadFrame then
				headIconObj:OnAniHeadFrame(false)
			end
		end
		
		if aniRootObj then
			aniRootObj:SetNodesActive(true)
		end
		self:ClearWndAnimation(trans)
	end)
	
	if updateFunc then
		seqTween:OnUpdate(updateFunc)
	end
	
	seqTween:PlayForward()
end

function LWnd:_ParseVector3Config(posStr)
	if string.isempty(posStr) then
		return nil
	end
	local posList = string.split(posStr, ',')
	local x = tonumber(posList[1]) or 0
	local y = tonumber(posList[2]) or x
	local z = tonumber(posList[3]) or y
	return Vector3.New(x, y, z)
end
function LWnd:_ParseAniConfig(cfgStr)
	if string.isempty(cfgStr) then
		return nil
	end
	local aniItemMap = {}
	local strList= string.split(cfgStr,';')
	for k,v in pairs(strList) do
		local aniItem = string.split(v,'=')
		local aniTag = aniItem[1]
		local aniTypeId = tonumber(aniItem[2]) or 0
		aniItemMap[aniTag] = aniTypeId
	end
	return aniItemMap
end
function LWnd:_ParseAniTypeScaleConfig(cfgStr)
	if string.isempty(cfgStr) then
		return nil
	end
	
	local aniTypeList = {}
	local strList= string.split(cfgStr,';')
	for k,v in pairs(strList) do
		if not string.isempty(v) then
			local aniItem = string.split(v,'=')
			local aniValue = self:_ParseVector3Config(aniItem[1])
			local timeValue = tonumber(aniItem[2]) or 0
			local easeValue = tonumber(aniItem[3]) or 0
			local aniTypeItem = {aniValue = aniValue, timeValue = timeValue, easeValue = easeValue}
			table.insert(aniTypeList, aniTypeItem)
		end
	end
	return aniTypeList
end
function LWnd:_ParseAniTypeAlphaConfig(cfgStr)
	if string.isempty(cfgStr) then
		return nil
	end
	
	local aniTypeList = {}
	local strList= string.split(cfgStr,';')
	for k,v in pairs(strList) do
		if not string.isempty(v) then
			local aniItem = string.split(v,'=')
			local aniValue = tonumber(aniItem[1]) or 0
			local timeValue = tonumber(aniItem[2]) or 0
			local easeValue = tonumber(aniItem[3]) or 0
			local aniTypeItem = {aniValue = aniValue, timeValue = timeValue, easeValue = easeValue}
			table.insert(aniTypeList, aniTypeItem)
		end
	end
	return aniTypeList
end
function LWnd:_ParseAniTypePosConfig(cfgStr)
	if string.isempty(cfgStr) then
		return nil
	end
	
	local aniTypeList = {}
	local strList= string.split(cfgStr,';')
	for k,v in pairs(strList) do
		if not string.isempty(v) then
			local aniItem = string.split(v,'=')
			local aniValue = self:_ParseVector3Config(aniItem[1] or '')
			local timeValue = tonumber(aniItem[2]) or 0
			local easeValue = tonumber(aniItem[3]) or 0
			local aniTypeItem = {aniValue = aniValue, timeValue = timeValue, easeValue = easeValue}
			table.insert(aniTypeList, aniTypeItem)
		end
	end
	return aniTypeList
end
-----------------------------------------------------------------------
-- 默认动画 tag = Open/Close
function LWnd:_GetWndAniDefaultConfig(tag)
	local wndAniTag = tag..self:GetWndSortLayer()
	local aniTypeId = GameTable.UIWindowAniDefaultRef[wndAniTag]
	if not aniTypeId then
		return nil
	end
	local aniItemMap = {}
	local wndName = self:GetWndName()
	aniItemMap[wndName] = aniTypeId
	return aniItemMap
end

function LWnd:_GetItemAniDefaultConfig(aniTag)
	aniTag = aniTag or ""
	local aniTypeId = GameTable.UIWindowAniDefaultRef[aniTag] or 0
	return aniTypeId
end

-----------------------------------------------------------------------
-- Get Ease By Val
function LWnd:_GetEaseByValue(val)
	
end

