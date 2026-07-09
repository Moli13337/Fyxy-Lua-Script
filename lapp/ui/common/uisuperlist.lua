local UIListBase = UIListBase
local LxKVList = LXFW.LxKVList
local SuperViewHelper = CS.SuperViewHelper
local typeSuperViewHelper = typeof(SuperViewHelper)
local ScrollTypeGrid = SuperViewHelper.ScrollType.Grid
local ScrollTypeList = SuperViewHelper.ScrollType.List
local typeOfScrollRect = typeof(UnityEngine.UI.ScrollRect)
local typeScrollVCheck = typeof(CS.YXUIScrollVCheck)
local typeScrollRect = typeof(CS.ScrollRect)
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)

local Tweening = DG.Tweening

------------------------------------------------------------------
---@class UISuperList:UIListBase
local UISuperList = LxClass("UISuperList", UIListBase)
UISuperList.VIEW_PORT_TEMPLATE_NAME = "ViewPort/ItemTemplate"
------------------------------------------------------------------
function UISuperList:UISuperList()
    self._scrollType = ScrollTypeList

    self._loadAnimationType = 1
    self._loadItemAniMap = {}
    self._itemOrgScale = Vector3.one

    self._aniScaleTo = 0.5
    self._aniScaleTime = 0.1
end

function UISuperList:SetScrollType(typeNum)
    if typeNum == 2 then
        self._scrollType =  ScrollTypeGrid
    else
        self._scrollType =  ScrollTypeList
    end
end

function UISuperList:Create(parentWnd, scrollTrans)
	if (not parentWnd) then
		LogError("UISuperList need parentWnd")
		return false
	end
	if (not scrollTrans) then
		LogError("UISuperList need objScroll")
		return false
	end
	self._parentWnd = parentWnd
	self._scrollTrans = scrollTrans

	local itemTemplateTrans = scrollTrans:Find(UIListBase.ITEM_TEMPLATE_NAME)
	if (not itemTemplateTrans) then
		itemTemplateTrans = scrollTrans:Find(UISuperList.VIEW_PORT_TEMPLATE_NAME)
	end
	-- CELL做打开渐变
	if itemTemplateTrans then
		itemTemplateTrans.gameObject:AddComponent(typeofCanvasGroup)
		self._itemTemplateTrans = itemTemplateTrans
	end

    self._dataTable = LxKVList:New()
    self._scrollTrans = scrollTrans
    local csUIScroll = scrollTrans.gameObject:GetComponent(typeSuperViewHelper)
    if (not csUIScroll) then
        csUIScroll = scrollTrans.gameObject:AddComponent(typeSuperViewHelper)
    end
    self._csUIScroll = csUIScroll
    self._csScrollRect = scrollTrans.gameObject:GetComponent(typeScrollRect)

	self._itemRootTrans = self._csScrollRect.content
	if self._itemRootTrans then
		self._itemRootRectTrans = self._itemRootTrans.gameObject:GetComponent(typeOfRectTransform)
	end

	self._isMultScroll = true

	if self._parentWnd then
		self._parentWnd:OnWndListCreate(self)
	end
end

---c#只刷新了数据个数,重画item需要调用 DrawAllItems 或者 MoveToPos
---SuperViewHelper.ScrollType.List
---SuperViewHelper.ScrollType.Grid
function UISuperList:RefreshList(bReset)
	self._touchBeginMoveX = nil
	self._touchBeginMoveY = nil

	self._itemBeginSysTime = os.time()
	self._curDrawFromIndex = 0

	if self._refreshName ~= "RefreshList" then
		self._refreshName = "RefreshList"
		self._refreshCount = 0
	end

	self._isResetWithoutAni = bReset
	if not bReset then
		self._refreshCount = self._refreshCount + 1
	end

    local scrollType = self._scrollType
    local dataCnt = self:GetDataSize()
    self:ApplyLoadAnimation()
    self._csUIScroll:InitView(dataCnt,scrollType)
	self:SetItemLoadType(self._itemLoadType, self._itemAniType)
end

function UISuperList:ResetList()
	self._isResetWithoutAni = true
	self:RefreshList(true)
end

--- on item return pool, func(item, datapos)
function UISuperList:SetFuncOnItemReturn(funcVal)
    self._funcOnItemReturn = funcVal
    if (funcVal) then
        self._csUIScroll.onItemReturn = function(...) self:OnItemReturn(...) end
    else
        self._csUIScroll.onItemReturn = nil
    end
end
--- on item draw, func(item, datapos)
function UISuperList:SetFuncOnItemDraw(funcVal)
    UIListBase.SetFuncOnItemDraw(self, funcVal)
    if (funcVal) then
        self._csUIScroll.onItemDraw = function(...) self:OnItemDraw(...) end
    else
        self._csUIScroll.onItemDraw = nil
    end
end

function UISuperList:SetOnStartDrag(func)
    self._onStartDrag = func

    self:AddScrollCheck()
end

function UISuperList:SetOnEndDrag(func)
    self._onEndDrag = func

    self:AddScrollCheck()
end

function UISuperList:AddScrollCheck()
    if self._scrollVCheck then
        return
    end
    local scrollVCheck = self._scrollTrans.gameObject:GetComponent(typeScrollVCheck)
    if not scrollVCheck then
        scrollVCheck = self._scrollTrans.gameObject:AddComponent(typeScrollVCheck)
    end
    scrollVCheck.mOnStartScroll = function() self:OnStartScroll() end
    scrollVCheck.mOnEndScroll = function() self:OnEndScroll() end
    self._scrollVCheck = scrollVCheck
end

function UISuperList:SetOnSnapNearestChanged(func)
    self._csUIScroll.onSnapNearestChanged = function(col, row)
        if not self:IsDestroy() then
            func(col, row)
        end
    end
end

function UISuperList:OnItemDraw(item, datapos, bReset)
    local itempos = datapos + 1
    UIListBase.OnItemDraw(self, item, itempos, nil, bReset)
end

function UISuperList:OnItemReturn(item,datapos)
    local itempos = datapos + 1
	UIListBase.OnItemReturn(self, item, itempos)
end

function UISuperList:SetFuncOnItemReachHead(funcVal)
    if funcVal then
        self._csUIScroll.onReachHead = function (...)
            if not self:IsDestroy() then
                funcVal(...)
            end
        end
    else
        self._csUIScroll.onReachHead = nil
    end
end

function UISuperList:SetFuncOnItemReachTail(funcVal)
    if (funcVal) then
        self._csUIScroll.onReachTail = function(...)
            if not self:IsDestroy() then
                funcVal(...)
            end
        end
    else
        self._csUIScroll.onReachTail = nil
    end
end

function UISuperList:RemoveAll()
    self:RemoveAllData()
end

function UISuperList:DrawAllItems(bLoadAni)
	if bLoadAni == nil then
		bLoadAni = true
	end
    self._curUsingLoadAnimation = false
	self._isResetWithoutAni = not bLoadAni
    if bLoadAni then
        self:ApplyLoadAnimation()
    end
    self._csUIScroll:RefreshAllItem()
end

function UISuperList:DrawItemByIndex(index)
    self._curUsingLoadAnimation = false
	if self._scrollType == ScrollTypeGrid then
		local mLoopGridView = self._csUIScroll.mLoopGridView
		if mLoopGridView then
			local item = mLoopGridView:GetShownItemByItemIndex(index - 1)
			if item then
				self:OnItemDraw(item.transform, index - 1, true)
			end
			return
		end
	end
    self._csUIScroll:RefreshItemByIndex(index-1)
end

function UISuperList:MoveToPos(index,offset,notAni, offsetY)
    index = index or 1
	self._curDrawFromIndex = index - 1
    if notAni == nil then
        notAni = true
    end
    self._curUsingLoadAnimation = notAni
    self._csUIScroll:MoveToPos(index -1,offset or 0, offsetY or 0)
end


function UISuperList:MoveToBottom(offset)
    local cnt = self:GetDataSize()
    local index = cnt -1
    index = math.max(0,index)
	self._curDrawFromIndex = index - 1
    self._csUIScroll:MoveToPos(index -1,offset or 0, 0)
end

function UISuperList:Destroy()
    self._funcOnItemReturn = nil
    self:OnEndScroll()
end


function UISuperList:ApplyLoadAnimation()
    self._curUsingLoadAnimation = self._enableLoadAnimation
end

-- 启用动态加载
-- bEnable 是否启用
-- aniTime每次加载间隔，0表示一帧
-- onceCount每次加载次数
-- aniType  1:Y缩放 2:X缩放 0:XY缩放
function UISuperList:EnableLoadAnimation(bEnable, aniTime, onceCount, aniType)
	--[[
    self._enableLoadAnimation = bEnable==nil or bEnable
    self._loadAnimationTime = aniTime or 0
    self._loadCountOnce = onceCount or 1
    self._loadAnimationType = aniType or 0
	--]]
end

function UISuperList:SetLoadAnimationScale(scale, time)
    self._aniScaleTo = scale or 0.5
    self._aniScaleTime = time or 0.1
end

function UISuperList:ClearAllLoadAnimation()
    for item,seqTween in pairs(self._loadItemAniMap or {}) do
        if item ~= nil and CS.IsValidObject(item.transform) then
            seqTween:Kill(false)
            local aniTrans = CS.FindTrans(item.transform,"AniRoot")
            if not aniTrans then aniTrans = item.transform end
            aniTrans.localScale = self._itemOrgScale
			local canvas = aniTrans:GetComponent(typeofCanvasGroup)
			if CS.IsValidObject(canvas) then
				canvas.alpha = 1
			end
        end
    end
    self._loadItemAniMap = {}
end

function UISuperList:ShowItemEnterAnimation(item, bAni, datapos)
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

function UISuperList:EnableScroll(enable,bHorizontal)
    local scrollRect = self._scrollRectCom
    if not scrollRect then
        scrollRect = self._scrollTrans:GetComponent(typeOfScrollRect)
        self._scrollRectCom = scrollRect
    end

    if not CS.IsValidObject(scrollRect) then
        return
    end

    enable = enable or false
    bHorizontal = bHorizontal or false
	self._isMultScroll = not bHorizontal

    scrollRect.enabled = enable
    scrollRect.horizontal = bHorizontal
    scrollRect.vertical = not bHorizontal
end

function UISuperList:OnStartScroll()

    if self._onStartDrag then
        self._onStartDrag()
    end
end

function UISuperList:OnEndScroll()
    if self._onEndDrag then
        self._onEndDrag()
    end
end


function UISuperList:SetContentPosition(pos)
    local csScrollRect = self._csScrollRect
    if csScrollRect then
        csScrollRect.normalizedPosition = pos
    end
end

function UISuperList:GetContentPosition()
    local csScrollRect = self._csScrollRect
    if csScrollRect then
        return csScrollRect.normalizedPosition
    end
    return Vector2.zero
end

function UISuperList:GetContentSize()
    if not self._csScrollRect then
        return 100
    end
    local content = self._csScrollRect.content
    return content.rect.size
end

function UISuperList:SetItemLoadType(loadType, aniType, doOnce)
	if CS.IsNullObject(self._csUIScroll) then
		return
	end
	if not doOnce then
		self._itemLoadType = loadType
		self._itemAniType = aniType
	end

    if CS.IsWebGL() then
        ---webgl 从左到右 1帧一个
        self._csUIScroll:EnableFrameNew(true, 1, 1)
        return
    end

	if aniType == 0 then
		self._csUIScroll:EnableFrameNew(false, 0, 0)
	elseif aniType == 1 then
		self._csUIScroll:EnableFrameNew(loadType == 1, 10, 1)
	else
		self._csUIScroll:EnableFrameNew(loadType == 1, self:GetConstrainCount(), 0)
	end
end

function UISuperList:Freeze(bFrozen)
    if not self._csUIScroll then return end
    self._csUIScroll:EnableScrollView(not bFrozen)
    if self._csScrollRect then
        self._csScrollRect.enabled = not bFrozen
    end
end

return UISuperList