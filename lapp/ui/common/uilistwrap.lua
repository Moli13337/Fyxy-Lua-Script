---
--- Created by Admin.
--- DateTime: 2023/10/7 11:09
---
------------------------------------------------------------------
local CS = CS
local YXUIScrollBar = CS.YXUIScrollBar
local YXUIScrollRect = CS.YXUIScrollRect
local UnityEngine = UnityEngine
local typeof = typeof
local typeof_LayoutElement = typeof(UnityEngine.UI.LayoutElement)
local typeXUIScrollRect = typeof(YXUIScrollRect)
local typeXUIScrollBar = typeof(YXUIScrollBar)
local UIListBase = UIListBase

local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)

local Tweening = DG.Tweening

---@class UIListWrap:UIListBase
local UIListWrap = LxClass("UIListWrap", UIListBase)
------------------------------------------------------------------
UIListWrap.FromHeadTail = YXUIScrollRect.FromHeadTail
UIListWrap.RefreshMode = YXUIScrollRect.RefreshTo
UIListWrap.ScrollMode = YXUIScrollRect.ScrollTo
------------------------------------------------------------------

------------------------------------------------------------------
function UIListWrap:UIListWrap()
	self._isWndDestroy = false
	self._csUIScroll = nil
	self._scrollTrans = nil

	self._funcOnItemReturn = nil

	self._funcOnItemReachHead = nil
	self._funcOnItemReachTail = nil

	self._funcOnCenterModeLateUpdate = nil
	self._funcOnCenterModeSelChange = nil

	self._defalutRefreshMode = nil

	-- 分布加载参数
	self._curUsingLoadAnimation = false
	self._enableLoadAnimation = false
	self._loadAnimationTime = 0
	self._loadCountOnce = 1
	-- 0: xy, 1:x 2:y
	self._loadAnimationType = 1
	self._loadItemAniMap = {}
	self._itemOrgScale = nil

	self._aniScaleTo = 0.5
	self._aniScaleTime = 0.1
end

function UIListWrap:Create(parentWnd, scrollTrans, anchorType, initPoolCount)
	if (not UIListBase.Create(self, parentWnd, scrollTrans,anchorType)) then
		return false
	end
	self._scrollTrans = scrollTrans
	local csUIScroll = scrollTrans:GetComponent(typeXUIScrollRect)
	if (not csUIScroll) then
		csUIScroll = scrollTrans.gameObject:AddComponent(typeXUIScrollRect)
	end
	csUIScroll:Initialize(initPoolCount or 5)
	self._csUIScroll = csUIScroll
	--csUIScroll.stopThreshold = 10
	--csUIScroll.speedScale = 1
	--csUIScroll.velocityScale = 20
	
	self._constrainCount = self._csUIScroll:GetConstrainCount()
	self._isMultScroll = true
	
	if self._parentWnd then
		self._parentWnd:OnWndListCreate(self)
	end
	return true
end

function UIListWrap:GetIsDragged()
	if self._csUIScroll then
		return self._csUIScroll.isDragged
	end
	return false
end

function UIListWrap:GetIsReachEnd()
	if self._csUIScroll then
		return self._csUIScroll.isReachEnd
	end
	return false
end

function UIListWrap:SetIsDragged(value)
	self._csUIScroll.isDragged = value or false
end

function UIListWrap:SetContentPosition(x,y)
	local csScrollRect = self._csUIScroll
	if csScrollRect then
		csScrollRect.normalizedPosition = Vector2(x,y)
	end
end

function UIListWrap:SetStopThreshold(threshold)
	local csUIScroll = self._csUIScroll
	if csUIScroll then
		csUIScroll.stopThreshold = threshold
	end
end

function UIListWrap:SetSpeedScale(scale)
	local csUIScroll = self._csUIScroll
	if csUIScroll then
		csUIScroll.speedScale = scale
	end
end

function UIListWrap:SetVelocityScale(scale)
	local csUIScroll = self._csUIScroll
	if csUIScroll then
		csUIScroll.velocityScale = scale
	end
end

function UIListWrap:RemoveAll()
	self:ClearAllLoadAnimation()
	self:RemoveAllData()
	self:RefreshList(nil, nil, nil, true)
end

------------------------------------------------------------------
--- 参数设置
------------------------------------------------------------------
function UIListWrap:SetDefaultRefreshMode(mode)
	self._defalutRefreshMode = mode
end
--- 启动/禁止 拖动
function UIListWrap:EnableScroll(b)
	--b = b or true
	if b == nil then b = true end
	self._csUIScroll.disableHV = not b
end
--- 设置水平滚动条
function UIListWrap:SetScrollBarH(objBar)
	local csScrollBar = objBar:GetComponent(typeXUIScrollBar)
	if (not csScrollBar) then
		print("need scrollbar component")
		return
	end
	self._csUIScroll.horizontalScrollbar = csScrollBar
end
--- 设置垂直滚动条
function UIListWrap:SetScrollBarV(objBar)
	local csScrollBar = objBar:GetComponent(typeXUIScrollBar)
	if (not csScrollBar) then
		print("need scrollbar component")
		return
	end
	self._csUIScroll.verticalScrollbar = csScrollBar
end
--- 动态宽高列表模式下，设置每个item的大小
function UIListWrap:SetItemPreferredSize(item, width, height)
	width = width or 100
	height = height or 100
	local csLayoutElement = item:GetComponent(typeof_LayoutElement)
	if (not csLayoutElement) then
		csLayoutElement = item.gameObject:AddComponent(typeof_LayoutElement)
	end
	csLayoutElement.preferredWidth = width
	csLayoutElement.preferredHeight = height
end
function UIListWrap:GetItemPreferredSize(item)
	local csLayoutElement = item:GetComponent(typeof_LayoutElement)
	if (csLayoutElement) then
		return csLayoutElement.preferredWidth,csLayoutElement.preferredHeight
	end
	return nil
end
--- elastic模式下可拖拽距离系数 0 - 1 , 越小越短
function UIListWrap:SetElasticDragRange(v)
	self._csUIScroll.elasticDragRange = v
end
--- viewrect 左右/上下 溢出距离 , 越大冗余的item就越多
function UIListWrap:SetItemOverflowRange(v)
	self._csUIScroll.itemOverflowRange = v
end
---- DecelerationRate, 在滑动过程中，突然禁止并关闭滑动, 0-1，默认值0.135, 越小越滑不动
function UIListWrap:SetDecelerationRate(v)
	self._csUIScroll.decelerationRate = v
end
--- on item return pool, func(item, datapos)
function UIListWrap:SetFuncOnItemReturn(funcVal)
	self._funcOnItemReturn = funcVal
	if (funcVal) then
		self._csUIScroll.onItemReturn = function(...) self:OnItemReturn(...) end
	else
		self._csUIScroll.onItemReturn = nil
	end
end
--- on item draw, func(item, datapos)
function UIListWrap:SetFuncOnItemDraw(funcVal)
	UIListBase.SetFuncOnItemDraw(self, funcVal)
	if (funcVal) then
		self._csUIScroll.onItemDraw = function(...) self:OnItemDraw(...) end
	else
		self._csUIScroll.onItemDraw = nil
	end
end
--- 列表滑动到头部或离开头部代理 , func(bIn)
function UIListWrap:SetFuncOnItemReachHead(funcVal)
	self._funcOnItemReachHead = funcVal
	if (funcVal) then
		self._csUIScroll.onItemReachHead = function(...) self:OnItemReachHead(...) end
	else
		self._csUIScroll.onItemReachHead = nil
	end
end
--- 列表滑动到尾部或离开尾部代理 , func(bIn)
function UIListWrap:SetFuncOnItemReachTail(funcVal)
	self._funcOnItemReachTail = funcVal
	if (funcVal) then
		self._csUIScroll.onItemReachTail = function(...) self:OnItemReachTail(...) end
	else
		self._csUIScroll.onItemReachTail = nil
	end
end
--- 居中模式下的 lateupdate , func(item, datapos, range2center)
function UIListWrap:SetFuncOnCenterModeLateUpdate(funcVal)
	self._funcOnCenterModeLateUpdate = funcVal
	if (funcVal) then
		self._csUIScroll.onCenterModeLateUpdate = function(...) self:OnCenterModeLateUpdate(...) end
	else
		self._csUIScroll.onCenterModeLateUpdate = nil
	end
end
--- 居中模式下的 当前居中对象变化代理 , func(item, datapos)
function UIListWrap:SetFuncOnCenterModeSelChange(funcVal)
	self._funcOnCenterModeSelChange = funcVal
	if (funcVal) then
		self._csUIScroll.onCenterModeSelChange = function(...) self:OnCenterModeSelChange(...) end
	else
		self._csUIScroll.onCenterModeSelChange = nil
	end
end
function UIListWrap:ShowItemEnterAnimation(item, bAni, datapos)
	if self._isWndDestroy or item == nil or CS.IsNullObject(item.transform) then
        return
    end

    local itemTrans = item.transform

    local seqTween = self._loadItemAniMap[item]
    if seqTween then
        seqTween:Kill(false)
        self._loadItemAniMap[item] = nil
    end

    local aniTrans = CS.FindTrans(itemTrans,"AniRoot")
    if not aniTrans then aniTrans = itemTrans end
	local canvas = item:GetComponent(typeofCanvasGroup)
	if CS.IsNullObject(canvas) then
		canvas = item.gameObject:AddComponent(typeofCanvasGroup)
	end
	if CS.IsValidObject(canvas) then
		canvas.alpha = 1
	end

    if self._itemOrgScale then
        aniTrans.localScale = self._itemOrgScale
    end
    if not bAni or self._loadAnimationType < 0 then
        return
    end

    local localScale = aniTrans.localScale

    local fromScale = nil
    local scale = self._aniScaleTo or 0.5
    if self._loadAnimationType == 1 then
        fromScale = Vector3(scale,localScale.y,scale)
    elseif self._loadAnimationType == 2 then
        fromScale = Vector3(localScale.x,scale,scale)
    else
        fromScale = Vector3(scale,scale,scale)
    end
    if self._aniScaleTime <= 0 then
        aniTrans.localScale = localScale
    else
        aniTrans.localScale = fromScale
		
		local seqTween = Tweening.DOTween.Sequence()
		self._loadItemAniMap[item] = seqTween
		seqTween:AppendInterval(datapos % 5 * 0.08)
		local seqScale = Tweening.DOTween.Sequence()
		local scaleTween1 = aniTrans:DOScale(localScale * 1.15,0.24)
		local scaleTween2 = aniTrans:DOScale(localScale, 0.12)
		seqScale:Append(scaleTween1)
		seqScale:Append(scaleTween2)
		
		seqTween:Append(seqScale)
		if CS.IsValidObject(canvas) then
			canvas.alpha = 0
			local alphaTween = CS.YXDOTweenModuleUI.DOFade(canvas, 1, 0.5)
			seqTween:Join(alphaTween)
		end
		
		seqTween:PlayForward()
    end

    if not self._itemOrgScale then
        self._itemOrgScale = localScale
    end
end
function UIListWrap:ClearAllLoadAnimation()
	for item,aniTween in pairs(self._loadItemAniMap or {}) do
		if item ~= nil and CS.IsValidObject(item.transform) then
			aniTween:Kill(false)
			local aniTrans = CS.FindTrans(item.transform,"AniRoot")
			if not aniTrans then aniTrans = item.transform end
			aniTrans.localScale = self._itemOrgScale
		end
	end
	self._loadItemAniMap = {}
end
------------------------------------------------------------------
--- 代理
------------------------------------------------------------------
function UIListWrap:OnItemReturn(item, datapos)
	if self._enableLoadAnimation then
		--self:ShowItemEnterAnimation(item, false, datapos)
	end
	local itempos = datapos + 1
	UIListBase.OnItemReturn(self, item, itempos)
end
function UIListWrap:OnItemDraw(item, datapos, fromHeadTail, bReset)
	if self._curUsingLoadAnimation then
		--self:ShowItemEnterAnimation(item, true, datapos)
	end
	
	local itempos = datapos + 1
	UIListBase.OnItemDraw(self, item, itempos, fromHeadTail, bReset)
end
function UIListWrap:OnItemReachHead(isIn)
	local funcOnItemReachHead = self._funcOnItemReachHead
	if (funcOnItemReachHead) then
		funcOnItemReachHead(self, isIn)
	end
end
function UIListWrap:OnItemReachTail(isIn)
	local funcOnItemReachTail = self._funcOnItemReachTail
	if (funcOnItemReachTail) then
		funcOnItemReachTail(self, isIn)
	end
end
function UIListWrap:OnCenterModeLateUpdate(item, datapos, centerrange)
	if self._enableLoadAnimation then
		--self:ShowItemEnterAnimation(item, false, datapos)
	end
	local funcOnCenterModeLateUpdate = self._funcOnCenterModeLateUpdate
	if (funcOnCenterModeLateUpdate) then
		local itempos = datapos + 1
		local itemdata = self:GetDataByIndex(itempos)
		funcOnCenterModeLateUpdate(self, item, itemdata, itempos, centerrange)
	end
end
function UIListWrap:OnCenterModeSelChange(item, datapos)
	if self._enableLoadAnimation then
		--self:ShowItemEnterAnimation(item, false, datapos)
	end
	local funcOnCenterModeSelChange = self._funcOnCenterModeSelChange
	if (funcOnCenterModeSelChange) then
		local itempos = datapos + 1
		local itemdata = self:GetDataByIndex(itempos)
		funcOnCenterModeSelChange(self, item, itemdata, itempos)
	end
end


------------------------------------------------------------------
--- 主要接口
------------------------------------------------------------------
--- 列表刷新
--- UIListWrap.RefreshMode.Top
--- UIListWrap.RefreshMode.Bottom
--- UIListWrap.RefreshMode.Custom
--- UIListWrap.RefreshMode.Solid
function UIListWrap:RefreshList(refreshMode, refreshCustom, fixScrollMode, bReset)
	if CS.IsNullObject(self._scrollTrans)  then
		return
	end
	
	if self._refreshName ~= "RefreshList" then
		self._refreshName = "RefreshList"
		self._refreshCount = 0
	end
	
	self._touchBeginMoveX = nil
	self._touchBeginMoveY = nil
	
	self._itemBeginSysTime = os.time()
	self._isResetWithoutAni = bReset
	if not bReset then
		self._refreshCount = self._refreshCount + 1
	end
	
	refreshMode = refreshMode or self._defalutRefreshMode or UIListWrap.RefreshMode.Top
	refreshCustom = refreshCustom or 0
	fixScrollMode = fixScrollMode or UIListWrap.ScrollMode.None
	local dataCnt = self:GetDataSize()
	local csUIScroll = self._csUIScroll
	csUIScroll.dataTotalCount = dataCnt
	self._curDrawFromIndex = refreshCustom
	self._curUsingLoadAnimation = self._enableLoadAnimation
	csUIScroll.enableLoadAnimation = self._enableLoadAnimation
	csUIScroll.loadAnimationTime = self._loadAnimationTime
	csUIScroll.loadCountOnce = self._loadCountOnce
	-- 防止列表关闭后的刷新
	if CS.IsNullObject(self:GetScrollTrans()) then
		return
	end
	
	csUIScroll:DoRefreshToTarget(refreshMode, refreshCustom, fixScrollMode)
end

function UIListWrap:ResetList(refreshMode, refreshCustom, fixScrollMode)
	self._isResetWithoutAni = true
	self:RefreshList(refreshMode, refreshCustom, fixScrollMode, true)
end

--- 列表刷新
--- UIListWrap.RefreshMode.Top
--- UIListWrap.RefreshMode.Bottom
function UIListWrap:RefreshSimpleList(refreshMode, bRefreshTarget, bReset)
	refreshMode = refreshMode or self._defalutRefreshMode or UIListWrap.RefreshMode.Top
	
	if self._refreshName ~= "RefreshSimpleList" then
		self._refreshName = "RefreshSimpleList"
		self._refreshCount = 0
	end
	
	self._itemBeginSysTime = os.time()
	self._curDrawFromIndex = 0
	self._isResetWithoutAni = bReset
	if not bReset then
		self._refreshCount = self._refreshCount + 1
	end
	
	local dataCnt = self:GetDataSize()
	local csUIScroll = self._csUIScroll
	csUIScroll.dataTotalCount = dataCnt
	self._curUsingLoadAnimation = self._enableLoadAnimation
	
	if bRefreshTarget then
		csUIScroll:RefreshToTarget()
	else
		csUIScroll:RefreshSimpleScroll(refreshMode)
	end

end

--- 列表刷新
function UIListWrap:RefreshSilent()
	if self._refreshName ~= "RefreshSilent" then
		self._refreshName = "RefreshSilent"
		self._refreshCount = 0
	end
	
	local dataCnt = self:GetDataSize()
	local csUIScroll = self._csUIScroll
	csUIScroll.dataTotalCount = dataCnt
end

-- 启用动态加载
-- bEnable 是否启用
-- aniTime每次加载间隔，0表示一帧
-- onceCount每次加载次数
-- aniType  1:Y缩放 2:X缩放 0:XY缩放
function UIListWrap:EnableLoadAnimation(bEnable, aniTime, onceCount, aniType)
	--[[
	self._enableLoadAnimation = bEnable==nil or bEnable
	self._loadAnimationTime = aniTime or 0
	self._loadCountOnce = onceCount or 1
	self._loadAnimationType = aniType or 0
	--]]
end

function UIListWrap:SetLoadAnimationScale(scale, time)
	self._aniScaleTo = scale or 0.5
	self._aniScaleTime = time or 0.1
end

function UIListWrap:SetItemLoadType(loadType, aniType)
	if CS.IsNullObject(self._csUIScroll) then
		return
	end
	self._itemLoadType = loadType
	self._itemAniType = aniType
	
	if aniType == 0 then
		self._csUIScroll.enableLoadAnimation = false
		self._enableLoadAnimation = false
		self._enableLoadAnimation = false
		self._curUsingLoadAnimation = false
	elseif aniType == 1 then 
		self._csUIScroll.enableLoadAnimation = false
		self._enableLoadAnimation = false
		self._enableLoadAnimation = false
		self._curUsingLoadAnimation = false
	else
		self._csUIScroll.enableLoadAnimation = loadType==1
		self._csUIScroll.loadAnimationTime = 0
		self._csUIScroll.loadCountOnce = self:GetConstrainCount()
		self._curUsingLoadAnimation = true
		self._enableLoadAnimation = true
		self._loadAnimationTime = 0
		self._loadCountOnce = self:GetConstrainCount()
	end
end

--- 列表滚动
--- UIListWrap.ScrollMode.Top
--- UIListWrap.ScrollMode.Bottom
--- UIListWrap.ScrollMode.Line
--- UIListWrap.ScrollMode.AnchorTop
--- UIListWrap.ScrollMode.AnchorCenter
--- UIListWrap.ScrollMode.AnchorBottom
--- scrollCustom 从1开始
function UIListWrap:ScrollList(scrollMode, scrollCustom, scrollSpeed, scrollElasticStop)
	scrollMode = scrollMode or UIListWrap.ScrollMode.Top
	if (scrollCustom == nil or scrollCustom < 1) then
		scrollCustom = 0
	else
		scrollCustom = scrollCustom - 1
	end
	local csUIScroll = self._csUIScroll
	if (scrollSpeed) then
		csUIScroll.scrollSpeed = scrollSpeed
	end
	if (scrollElasticStop) then
		csUIScroll.scrollSpeed = scrollElasticStop
	end
	csUIScroll:DoScrollToTarget(scrollMode, scrollCustom)
end
--- 居中模式
--- centerDragEndOffset = 拖拽结束后,velocity达到这个临界值就自动居中
function UIListWrap:CenterMode(isCenterMode, centerDragEndOffset)
	isCenterMode = isCenterMode or true
	local csUIScroll = self._csUIScroll
	csUIScroll.centerMode = isCenterMode
	if (centerDragEndOffset) then
		csUIScroll.centerDragEndOffset = centerDragEndOffset
	end
end

------------------------------------------------------------------
--- item操作
------------------------------------------------------------------
function UIListWrap:DrawAllItems()
	self._touchBeginMoveX = nil
	self._touchBeginMoveY = nil
	
	self._curUsingLoadAnimation = false
	local csUIScroll = self._csUIScroll
	return csUIScroll:DrawItemAll()
end
function UIListWrap:DrawItemByIndex(itempos)
	if (not itempos) then return end
	local csUIScroll = self._csUIScroll
	csUIScroll:DrawItemByPos(itempos-1)
end
function UIListWrap:DrawItemByKey(itemkey)
	if (not itemkey) then return end
	local itempos = self:GetIndexByKey(itemkey)
	self:DrawItemByIndex(itempos)
end
function UIListWrap:GetItemByIndex(itempos)
	local csUIScroll = self._csUIScroll
	return csUIScroll:GetItemByPos(itempos-1)
end
function UIListWrap:GetItemByKey(itemkey)
	local itempos = self:GetIndexByKey(itemkey)
	return self:GetItemByIndex(itempos)
end
function UIListWrap:GetItemPosByName(itemname)
	local csUIScroll = self._csUIScroll
	return csUIScroll:GetDataPosByItemname(itemname) + 1
end

function UIListWrap:AddItemByDataPos(itemPos)
	local csUIScroll = self._csUIScroll
	return csUIScroll:AddItemByDataPos(itemPos - 1)
end

function UIListWrap:RemoveItemByDataPos(itemPos)
	self._curUsingLoadAnimation = false
	local csUIScroll = self._csUIScroll
	return csUIScroll:RemoveItemByDataPos(itemPos - 1)
end


-----------------------------------------------------------------
function UIListWrap:OnDispose()
	self._funcOnItemReturn = nil

	self._funcOnItemReachHead = nil
	self._funcOnItemReachTail = nil

	self._funcOnCenterModeLateUpdate = nil
	self._funcOnCenterModeSelChange = nil
	local csUIScroll = self._csUIScroll
	if csUIScroll and CS.IsValidObject(csUIScroll) then
		csUIScroll:StopAllCoroutines()
		csUIScroll.enabled = false
	end
end

------------------------------------------------------------------

return UIListWrap
