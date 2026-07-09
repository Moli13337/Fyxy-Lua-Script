---
--- Created by Admin.
--- DateTime: 2023/10/28 17:24
---
------------------------------------------------------------------
local CS = CS
local UnityEngine = UnityEngine
local typeof = typeof
local typeGridLayoutGroup = typeof(CS.GridLayoutGroup)
local typeVerticalLayoutGroup = typeof(UnityEngine.UI.VerticalLayoutGroup)
local typeHorizontalLayoutGroup = typeof(UnityEngine.UI.HorizontalLayoutGroup)
local typeContentSizeFitter = typeof(CS.ContentSizeFitter)
local typeScrollRect = typeof(CS.ScrollRect)
local typeScrollVCheck = typeof(CS.YXUIScrollVCheck)
local typeRectTransform = typeof(UnityEngine.RectTransform)
local enumPreferredSize = CS.ContentSizeFitter.FitMode.PreferredSize
local LStringUtil = LStringUtil
local UIListBase = UIListBase

---@class UIListEasy:UIListBase
local UIListEasy = LxClass("UIListEasy", UIListBase)
------------------------------------------------------------------

UIListEasy.SCROLL_CENTER=1
UIListEasy.SCROLL_TOP = 2

------------------------------------------------------------------
function UIListEasy:UIListEasy()
	self._csLayoutGrid = nil
	self._csScrollRect = nil
	
	-- 分布加载参数
	self._enableLoadAnimation = false
	self._loadAnimationFrame = 1
	self._loadCountOnce = 1
	-- 0: xy, 1:x 2:y
	self._loadAnimationType = 1
	self._loadItemAniMap = {}
	
	self._delayCallDrawMap = {}
end

function UIListEasy:Create(parentWnd, scrollTrans,anchorType)
	if (not UIListBase.Create(self, parentWnd, scrollTrans,anchorType)) then
		return false
	end
	local itemTemplateTrans = self:GetItemTemplateTrans()
	CS.ShowObject(itemTemplateTrans, false)
	local itemRootTrans = self:GetItemRootTrans()
	local csLayoutGrid = itemRootTrans:GetComponent(typeGridLayoutGroup)
	if (not csLayoutGrid) then
		csLayoutGrid = itemRootTrans:GetComponent(typeVerticalLayoutGroup)
		self._isVertical = true
		if not csLayoutGrid then
			csLayoutGrid = itemRootTrans:GetComponent(typeHorizontalLayoutGroup)
			self._isVertical = false
		end
		if not csLayoutGrid then
			LogError("need GridLayoutGroup or need VerticalLayoutGroup")
			return false
		end
		
		self._constrainCount = 1
	else
		self._constrainCount = csLayoutGrid.constraintCount
	end
	
	self._isMultScroll = nil
	
	self._csLayoutGrid = csLayoutGrid
	local csSizeFitter = itemRootTrans:GetComponent(typeContentSizeFitter)
	if (not csSizeFitter) then
		csSizeFitter = itemRootTrans.gameObject:AddComponent(typeContentSizeFitter)
		csSizeFitter.horizontalFit = enumPreferredSize
		csSizeFitter.verticalFit = enumPreferredSize
	end
	local scrollTrans = self:GetScrollTrans()
	local csScrollRect = scrollTrans:GetComponent(typeScrollRect)
	if (not csScrollRect) then
		csScrollRect = scrollTrans.gameObject:AddComponent(typeScrollRect)
	end
	csScrollRect.content = itemRootTrans
	csScrollRect.enabled = false
	self._csScrollRect = csScrollRect

	local poolName = "ItemPool"
	local itemPoolTrans = scrollTrans:Find(poolName)
	if not itemPoolTrans then
		itemPoolTrans = CS.NewObject(poolName, scrollTrans)
	end
	CS.ShowObject(itemPoolTrans, false)
	--self._itemPoolTrans = itemPoolTrans

	if not self._objPool then
		self._objPool = UIObjPool:New()
		self._objPool:Create(itemPoolTrans,itemTemplateTrans)
	end

	
	if self._parentWnd then
		self._parentWnd:OnWndListCreate(self)
	end
	
	return true
end

function UIListEasy:RemoveAll()
	self:RemoveAllData()
	self:RemoveAllItems()
end
function UIListEasy:RemoveAllItems()
	self:ClearAllLoadAnimation()
	
	self._curDrawFromIndex = 0

	if self._objPool then
		self._objPool:ReturnAllObj()
	end


	--local ObjItemRoot = self:GetItemRootTrans()
	--if (CS.IsValidObject(ObjItemRoot)) then
	--	local itemPoolTrans = self._itemPoolTrans
	--	local childCount = ObjItemRoot.childCount
	--	local listChild = {}
	--	for k=0, childCount-1 do
	--		local childTrans = ObjItemRoot:GetChild(k)
	--		table.insert(listChild, childTrans)
	--	end
    --
	--	for k=1,childCount do
	--		local childTrans = listChild[k]
	--		childTrans:SetParent(itemPoolTrans, false)
	--		childTrans.anchoredPosition = Vector2.zero
	--		CS.ShowObject(childTrans, false)
	--	end
    --
	--	--LxResUtil.DestroyChild(ObjItemRoot)
	--end
end
function UIListEasy:IsMultScroll() 
	local isMultScroll = self._isMultScroll
	if isMultScroll == nil then
		local csScrollRect = self._csScrollRect
		if csScrollRect then
			isMultScroll = csScrollRect.enabled and not csScrollRect.horizontal
		end
	end
	return isMultScroll
end
-----------------------------------------------------------------
function UIListEasy:InsertItem(itemRoot, itempos)
	local itemNew = self._objPool:GetObj()
	--local itemPoolTrans = self._itemPoolTrans
	--if CS.IsValidObject(itemPoolTrans) and itemPoolTrans.childCount > 0 then
	--	itemNew = itemPoolTrans:GetChild(0)
	--else
	--	local objItemTemplate = self:GetItemTemplateTrans()
	--	itemNew = LxResUtil.NewObject(objItemTemplate.gameObject)
	--end
	itemNew.transform:SetParent(itemRoot.transform, false)
	itemNew.name = UIListBase.ITEM_NAME .. "{" .. itempos - 1 .. "}"
	CS.ShowObject(itemNew, true)

	if self._isReverse then
		itemNew.transform:SetAsFirstSibling()
	end

	return itemNew:GetComponent(typeRectTransform)
end

------------------------------------------------------------------
--- 启动/禁止 拖动
function UIListEasy:EnableScroll(b, bHorizontal)
	b = b or false
	bHorizontal = bHorizontal or false
	
	local csScrollRect = self._csScrollRect
	if not csScrollRect then
		return 
	end
	csScrollRect.enabled = b
	csScrollRect.horizontal = bHorizontal
	csScrollRect.vertical = not bHorizontal
end

function UIListEasy:SetLayoutPara(padding,spacing)
	if self._csLayoutGrid then
        self._csLayoutGrid.spacing = spacing
		self._csLayoutGrid.padding.left = padding.x
		self._csLayoutGrid.padding.right = padding.y
		self._csLayoutGrid.padding.top = padding.z
		self._csLayoutGrid.padding.bottom = padding.w

	end
end

function UIListEasy:ClearAllLoadAnimation()
	for idx,timer in pairs(self._delayCallDrawMap) do
		timer:Stop()
	end
	self._delayCallDrawMap = {}
end
------------------------------------------------------------------
--- 主要接口
------------------------------------------------------------------
--- 列表刷新
function UIListEasy:RefreshList(bReset)
	self:RemoveAllItems()
	
	if self._refreshName ~= "RefreshList" then
		self._refreshName = "RefreshList"
		self._refreshCount = 0
	end
	
	self._touchBeginMoveX = nil
	self._touchBeginMoveY = nil
	
	self._itemBeginSysTime = os.time()
	self._curDrawFromIndex = 0
	self._isResetWithoutAni = bReset
	if not bReset then
		self._refreshCount = self._refreshCount + 1
	end
	
	local ObjItemRoot = self:GetItemRootTrans()
	local dataCnt = self:GetDataSize()
	local item
	for i = 1, dataCnt do
		item = self:InsertItem(ObjItemRoot, i)
		self:OnItemDraw(item, i)
	end
end

function UIListEasy:ResetList()
	self._isResetWithoutAni = true
	self:RefreshList(true)
end

function UIListEasy:RefreshListReverse(bReset)
	self:RemoveAllItems()
	
	if self._refreshName ~= "RefreshListReverse" then
		self._refreshName = "RefreshListReverse"
		self._refreshCount = 0
	end
	
	self._itemBeginSysTime = os.time()
	self._curDrawFromIndex = 0
	self._isResetWithoutAni = bReset
	if not bReset then
		self._refreshCount = self._refreshCount + 1
	end
	
	self._isReverse = true
	local ObjItemRoot = self:GetItemRootTrans()
	local dataCnt = self:GetDataSize()
	local item
	for i = dataCnt, 1,-1 do
		item = self:InsertItem(ObjItemRoot, i)
		self:OnItemDraw(item, i)
	end
end
--- on item draw
function UIListEasy:OnItemDraw(item, itempos, bReset)
	if item == nil or CS.IsNullObject(item)  then
		return
	end
	if self._enableLoadAnimation then
		if self._delayCallDrawMap[itempos] then
			self._delayCallDrawMap[itempos]:Stop()
		end
		local waitFrame = 0

		if self._loadCountOnce <= 0 then
			waitFrame = self._loadAnimationFrame * itempos -1
		else
			waitFrame = self._loadAnimationFrame * math.floor(itempos / self._loadCountOnce)
		end

		if waitFrame > 0 then
			self._delayCallDrawMap[itempos] = LxTimer.DelayFrameCall(function()
				if item == nil or CS.IsNullObject(item)  then
					return
				end
				UIListBase.OnItemDraw(self, item, itempos, nil, bReset)
			end, waitFrame)
		else
			UIListBase.OnItemDraw(self, item, itempos, nil, bReset)
		end


	elseif self._enableShowAnimation then
		UIListBase.OnItemDraw(self, item, itempos, nil, bReset)

		if self._delayCallDrawMap[itempos] then
			self._delayCallDrawMap[itempos]:Stop()
		end

		local waitFrame = 0

		if self._isReverse then
			local dataCnt = self:GetDataSize()
			local pos = dataCnt - itempos
			if self._loadCountOnce <= 0 then
				waitFrame = self._loadAnimationFrame * pos
			else
				waitFrame = self._loadAnimationFrame * math.floor(pos / self._loadCountOnce)
			end
		else
			if self._loadCountOnce <= 0 then
				waitFrame = self._loadAnimationFrame * itempos -1
			else
				waitFrame = self._loadAnimationFrame * math.floor(itempos / self._loadCountOnce)
			end
		end
		if waitFrame > 0 then
			self._delayCallDrawMap[itempos] = LxTimer.DelayFrameCall(function()
				if item == nil or CS.IsNullObject(item)  then
					return
				end


			end, waitFrame)
		end
	else
		UIListBase.OnItemDraw(self, item, itempos, nil, bReset)
	end
end

function UIListEasy:SetContentPosition(x,y)
	local csScrollRect = self._csScrollRect
	if csScrollRect then
		csScrollRect.normalizedPosition = Vector2(x,y)
	end
end

function UIListEasy:GetContentPosition()
	local csScrollRect = self._csScrollRect
	if csScrollRect then
		return csScrollRect.normalizedPosition
	end
	return Vector2.zero
end

function UIListEasy:SetItemRootPosition(x,y)
	local csScrollRect = self._csScrollRect
	if csScrollRect then
		local content = csScrollRect.content
		if content then
			x = x or content.localPosition.x
			y = y or content.localPosition.y
			content.localPosition = Vector2(x,y)
		end
	end
end

function UIListEasy:SetOnStartDrag(func)
	self._onStartDrag = func

	self:AddScrollCheck()
end

function UIListEasy:SetOnEndDrag(func)
	self._onEndDrag = func

	self:AddScrollCheck()
end

function UIListEasy:AddScrollCheck()
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

function UIListEasy:OnStartScroll()
	if self._onStartDrag then
		self._onStartDrag()
	end
end

function UIListEasy:OnEndScroll()
	if self._onEndDrag then
		self._onEndDrag()
	end
end

--- internal function,please call DelayScrollTo
function UIListEasy:ScrollTo(index)
	if self._isVertical ==nil then
		return
	end

	local scrollTrans = self:GetScrollTrans()

	if not CS.IsValidObject(scrollTrans) then
		return
	end

	local rect = scrollTrans:GetComponent(typeRectTransform).rect
	local viewLength = self._isVertical and rect.height or rect.width
	local itemRootTrans = self:GetItemRootTrans()
	rect = itemRootTrans:GetComponent(typeRectTransform).rect
	local contentLength = self._isVertical and rect.height or rect.width
	if contentLength<=viewLength then
		return
	end
	local total = self:GetDataSize()

	local padding = 0
	if self._isVertical then
		padding = self._csLayoutGrid.padding.bottom
	else
		padding = self._csLayoutGrid.padding.left
	end

	self._curDrawFromIndex = index - 1
	local factor = ( padding + (index-0.5)*contentLength/total -viewLength/2)/(contentLength-viewLength)

	factor = factor<0 and 0 or factor
	if factor>=0  then
		factor = factor>1 and 1 or factor
		if self._isVertical then
			self:SetContentPosition(0,factor)
		else
			self:SetContentPosition(factor,0)
		end

	end
end



function UIListEasy:ScrollToTop(index)
	if self._isVertical ==nil then
		return
	end

	local scrollTrans = self:GetScrollTrans()

	if not CS.IsValidObject(scrollTrans) then
		return
	end

	local rect = scrollTrans:GetComponent(typeRectTransform).rect
	local viewLength = self._isVertical and rect.height or rect.width
	local itemRootTrans = self:GetItemRootTrans()
	rect = itemRootTrans:GetComponent(typeRectTransform).rect
	local contentLength = self._isVertical and rect.height or rect.width
	if contentLength<=viewLength then
		return
	end

	self._curDrawFromIndex = index - 1

	local total = self:GetDataSize()
	local factor = (index-1)*contentLength/total /(contentLength-viewLength)

	if factor>=0  then
		factor = factor>1 and 1 or factor
		if self._isVertical then
			factor = 1- factor
			self:SetContentPosition(0,factor)
		else
			self:SetContentPosition(factor,0)
		end

	end
end

function UIListEasy:ScrollToIndex(index)
	if self._isVertical ==nil then
		return
	end
	local scrollTrans = self:GetScrollTrans()
	local rect = scrollTrans:GetComponent(typeRectTransform).rect
	local viewLength = self._isVertical and rect.height or rect.width
	local itemRootTrans = self:GetItemRootTrans()
	rect = itemRootTrans:GetComponent(typeRectTransform).rect
	local groupType = self._isVertical and typeVerticalLayoutGroup or typeHorizontalLayoutGroup
	local group = itemRootTrans:GetComponent(groupType)
	local spacing = group.spacing
	local contentLength = self._isVertical and rect.height or rect.width
	local itemTemplate = self:GetItemTemplateTrans()
	rect = itemTemplate:GetComponent(typeRectTransform).rect
	local templateLength = self._isVertical and rect.height or rect.width
	if contentLength<=viewLength then
		return
	end
	self._curDrawFromIndex = index - 1
	local dis = contentLength-viewLength
	local len = (index-1)*(templateLength+spacing)
	len = len < dis and len or dis
	local factor =(dis - len)/dis
	if factor>=0  then
		factor = factor>1 and 1 or factor
		if self._isVertical then
			self:SetContentPosition(0,factor)
		else
			self:SetContentPosition(factor,0)
		end
	end
end

function UIListEasy:DelayScrollTo(index,type)
	local scrollType = type or UIListEasy.SCROLL_CENTER

	if scrollType == UIListEasy.SCROLL_CENTER then
		self._delayUpdateScrollTimer=LxTimer.DelayFrameCall(function () self:ScrollTo(index) end,1)
	elseif scrollType== UIListEasy.SCROLL_TOP then
		self._delayUpdateScrollTimer=LxTimer.DelayFrameCall(function () self:ScrollToTop(index) end,1)

	end
end


------------------------------------------------------------------
--- item操作
------------------------------------------------------------------
function UIListEasy:DrawAllItems()
	self._touchBeginMoveX = nil
	self._touchBeginMoveY = nil
	
	local dataCnt = self:GetDataSize()
	for i = 1, dataCnt do
		self:DrawItemByIndex(i)
	end
end
function UIListEasy:DrawItemByIndex(itempos)
	local item = self:GetItemByIndex(itempos)
	self:OnItemDraw(item, itempos, true)
end
function UIListEasy:DrawItemByKey(itemkey)
	local itempos = self:GetIndexByKey(itemkey)
	self:DrawItemByIndex(itempos)
end
function UIListEasy:GetItemByIndex(itempos)
	local ObjItemRoot = self:GetItemRootTrans()
	if (itempos <= ObjItemRoot.transform.childCount) then
		return ObjItemRoot.transform:GetChild(itempos-1)
	end
	return nil
end
function UIListEasy:GetItemByKey(itemkey)
    local itempos = self:GetIndexByKey(itemkey)
    return self:GetItemByIndex(itempos)
end
function UIListEasy:GetItemPosByName(itemname)
	local strDataPos = LStringUtil.StringMatchFirst(itemname, UIListBase.ITEM_NAME)
	if (strDataPos) then
		return tonumber(strDataPos) + 1
	end
	return nil
end


-- 启用动态加载
-- bEnable 是否启用
-- aniTime每次加载间隔，0表示一帧
-- onceCount每次加载次数
function UIListEasy:EnableLoadAnimation(bEnable, aniTime, onceCount, aniType)
	--[[
	self._enableLoadAnimation = bEnable or true
	self._loadCountOnce = onceCount or 1
	self._loadAnimationType = aniType or 0
	
	aniTime = aniTime or 0
	if aniTime <= 0 then
		self._loadAnimationFrame = 1
	else
		local gameFrame = gLGameQuality:GetFrameRate()
		if gameFrame <= 0 then
			self._loadAnimationFrame = 1
		else
			local frameTime = 1 / gameFrame
			self._loadAnimationFrame = math.ceil(aniTime / frameTime)
		end
	end
	--]]
end

function UIListEasy:EnableShowAnimation(bEnable,aniTime,onceCount)
	self._enableShowAnimation = bEnable
	self._loadCountOnce = onceCount or 1
	aniTime = aniTime or 0
	if aniTime <= 0 then
		self._loadAnimationFrame = 1
	else
		local gameFrame = gLGameQuality:GetFrameRate()
		if gameFrame <= 0 then
			self._loadAnimationFrame = 1
		else
			local frameTime = 1 / gameFrame
			self._loadAnimationFrame = math.ceil(aniTime / frameTime)
		end
	end
end

------------------------------------------------------------------
function UIListEasy:Destroy()
	self:ClearAllLoadAnimation()
	if self._delayUpdateScrollTimer then
		LxTimer.DelayTimeStop(self._delayUpdateScrollTimer)
		self._delayUpdateScrollTimer = nil
	end

	if self._objPool then
		self._objPool:DestroyAllObj()
		self._objPool = nil
	end
end

------------------------------------------------------------------

return UIListEasy

