---
--- Created by Admin.
--- DateTime: 2023/10/28 17:24
---
------------------------------------------------------------------
local CS = CS
local typeof = typeof
local UnityEngine = UnityEngine
local typeofCanvasGroup = typeof(UnityEngine.CanvasGroup)
local typeOfRectTransform = typeof(UnityEngine.RectTransform)
local LxKVList = LXFW.LxKVList
local typeof_XUIDrag = typeof(CS.YXUIDrag)

---@class UIListBase
local UIListBase = LxClass("UIListBase", nil)
------------------------------------------------------------------
UIListBase.ITEM_NAME = "item"
UIListBase.ITEM_TEMPLATE_NAME = "ItemTemplate"
UIListBase.ITEM_ROOT_NAME = "ItemRoot"
------------------------------------------------------------------
---@class UIListBaseGroup
local UIListBaseGroup = LxClass("UIListBaseGroup", nil)
function UIListBaseGroup:UIListBaseGroup()
	self.groupKey = nil
	self.groupDataCount = nil
	self.groupColSize = nil
	self.groupRowCount = nil
	self.groupRowBegin = nil
end
function UIListBaseGroup:Create(key, colSize, dataCnt)
	self.groupKey = key
	self.groupDataCount = dataCnt
	self.groupColSize = colSize
	local rowCnt = math.floor(dataCnt / colSize)
	if ((dataCnt % colSize) > 0) then
		rowCnt = rowCnt + 1
	end
	self.groupRowCount = rowCnt
end
function UIListBaseGroup:SetGroupRowBegin(dataPosBegin)
	self.groupRowBegin = dataPosBegin
end
function UIListBaseGroup:IsInGroup(rowPos)
	if (rowPos >= self.groupRowBegin and rowPos <= (self.groupRowBegin + self.groupRowCount - 1)) then
		return true
	end
	return false
end
function UIListBaseGroup:GetRowIndexBegin(rowPos)
	return self.groupColSize * (rowPos - self.groupRowBegin)
end
function UIListBaseGroup:IsValidDataPos(dataIndex)
	if (dataIndex <= self.groupDataCount) then
		return true
	end
	return false
end
function UIListBase:GetConstrainCount()
	if (self._csUIScroll) then
		self._constrainCount = self._csUIScroll:GetConstrainCount()
		if self._constrainCount < 1 then
			self._constrainCount = 1
		end
	end
	
	return self._constrainCount
end

------------------------------------------------------------------
function UIListBase:UIListBase()
	---@type LWnd
	self._parentWnd = nil

	---@type LxKVList
	self._dataTable = nil

	---@type LxKVList
	self._groupTable = nil			-- k = groupKey, v = UIListBaseGroup

	self._scrollTrans = nil
	self._itemRootTrans = nil
	self._itemRootRectTrans = nil
	self._itemTemplateTrans = nil

	self._dragDropOpen = false
	self._dragDropKey = nil
	self._dragDropMode = nil

	self._funcOnItemDraw = nil
	self._isWndDestroy = false
	
	self._constrainCount = 1
	self._isMultScroll = true
	self._curDrawFromIndex = 0
	
	-- 当前item的idx
	self._itemPosMap = {}
	self._itemBeginSysTime = os.time()
	
	self._itemLoadType = 0
	self._itemAniType = 0
	
	self._isResetWithoutAni = false
	self._refreshCount = 0
	self._refreshName = ""
	
	self._touchBeginMoveX = nil
	self._touchBeginMoveY = nil
end

---@param parentWnd LWnd
---@param scrollTrans @scroll
function UIListBase:Create(parentWnd, scrollTrans,anchorType)
	if (not parentWnd) then
		LogError("need parentWnd")
		return false
	end
	if (not scrollTrans) then
		LogError("need objScroll")
		return false
	end
	scrollTrans = scrollTrans.transform
	self._parentWnd = parentWnd
	self._scrollTrans = scrollTrans

	self._dataTable = LxKVList:New()
	self._groupTable = LxKVList:New()

	local itemRootTrans = scrollTrans:Find(UIListBase.ITEM_ROOT_NAME)
	if (not itemRootTrans) then
		LogError("need ItemRoot")
		return false
	end
	if(anchorType==1)then
		itemRootTrans.anchorMin =  Vector2.New(0, 1)
		itemRootTrans.anchorMax =  Vector2.New(0, 1)
		itemRootTrans.pivot= Vector2.New(0, 1)
	elseif(anchorType==2)then
		itemRootTrans.anchorMin =  Vector2.New(0.5, 1)
		itemRootTrans.anchorMax =  Vector2.New(0.5, 1)
		itemRootTrans.pivot= Vector2.New(0.5, 1)
	end
	self._itemRootTrans = itemRootTrans
	self._itemRootRectTrans = itemRootTrans.gameObject:GetComponent(typeOfRectTransform)
	local itemTemplateTrans = scrollTrans:Find(UIListBase.ITEM_TEMPLATE_NAME)
	if (not itemTemplateTrans) then
		LogError("need ItemTemplate")
		return false
	end
	-- CELL做打开渐变
	local canvasGroup = itemTemplateTrans.gameObject:GetComponent(typeofCanvasGroup)
	if not canvasGroup then
		itemTemplateTrans.gameObject:AddComponent(typeofCanvasGroup)
	end
	self._itemTemplateTrans = itemTemplateTrans

	return true
end
------------------------------------------------------------------
function UIListBase:GetParentWnd() return self._parentWnd end 
function UIListBase:GetScrollTrans() return self._scrollTrans end
function UIListBase:GetCSUIScroll() return self._csUIScroll end
function UIListBase:GetItemRootTrans() return self._itemRootTrans end
function UIListBase:GetItemRootRectTrans() return self._itemRootRectTrans end
function UIListBase:GetItemTemplateTrans() return self._itemTemplateTrans end
function UIListBase:IsMultScroll() return self._isMultScroll end
function UIListBase:SetMultScroll(val) self._isMultScroll = val end
function UIListBase:GetCurDrawFromIndex() return self._curDrawFromIndex end
function UIListBase:GetRefreshCount() return self._refreshCount end
function UIListBase:GetBeginSysTime() return self._itemBeginSysTime end
------------------------------------------------------------------
function UIListBase:IsTouchHorizontal()
	if self._csScrollRect then return self._csScrollRect.horizontal end
	if self._csUIScroll then return self._csUIScroll.horizontal end
	return false
end
function UIListBase:IsTouchVertical()
	if self._csScrollRect then return self._csScrollRect.vertical end
	if self._csUIScroll then return self._csUIScroll.vertical end
	return false
end
function UIListBase:IsAlreadyTouchMoved(itemTrans)
	if not self._itemRootRectTrans then
		return false
	end
	if not self._itemTemplateTrans then
		return false
	end
	local anchoredPos = self._itemRootRectTrans.anchoredPosition
	local itemSize = self._itemTemplateTrans.sizeDelta
	local localPos = self._itemRootRectTrans.localPosition
	local bTouchMove  = false
	if self:IsTouchHorizontal() then
		if anchoredPos.y < -0.01 then
			bTouchMove = true
			if not self._touchBeginMoveX then
				self._touchBeginMoveX = localPos.x
			end
		elseif self._touchBeginMoveX then
			bTouchMove = math.abs(self._touchBeginMoveX - localPos.x) > 1
		end
	else

		if anchoredPos.y > 0.01 then
			bTouchMove = true
			if not self._touchBeginMoveY then
				self._touchBeginMoveY = localPos.y
			end
		elseif self._touchBeginMoveY then
			bTouchMove = math.abs(self._touchBeginMoveY - localPos.y) > 1
		end

		--printInfoN(string.format(" anchoredPos.y %s, self._touchBeginMoveY %s,localposy %s",anchoredPos.y,self._touchBeginMoveY,localPos.y))
	end
	
	return bTouchMove
end
------------------------------------------------------------------
--- 启动/取消 拖拽
function UIListBase:SetDragDrop(b, dragKey, dragMode)
	b = b or true
	dragKey = dragKey or "uilistDragKey"
	dragMode = dragMode or CS.YXUIDrag.DragMode.DragClone
	self._dragDropMode = dragMode
	self._dragDropKey = dragKey
	self._dragDropOpen = b
end
------------------------------------------------------------------
--- 拖拽检测
------------------------------------------------------------------
function UIListBase:DragDropCheck(item)
	if item == nil or CS.IsNullObject(item)  then
		return
	end
	local csUIDrag = item:GetComponent(typeof_XUIDrag)
	local dragDropOpen = self._dragDropOpen
	local dragKey = self._dragDropKey
	if (dragDropOpen) then
		if (not csUIDrag) then
			local parentWnd = self._parentWnd
			csUIDrag = item.gameObject:AddComponent(typeof_XUIDrag)
			csUIDrag.rootParent = parentWnd:GetWndTrans().gameObject
			csUIDrag.onBeginDrag = function(...) parentWnd:UIDragTryOnBegin(dragKey, ..., self) end
			csUIDrag.onDrag = function(...) parentWnd:UIDragTryOnDrag(dragKey, ..., self) end
			csUIDrag.onEndDrag = function(...) parentWnd:UIDragTryOnEnd(dragKey, ..., self) end
			csUIDrag.resetChildPivot = true
		end
	end
	if (csUIDrag) then
		csUIDrag.dragMode = self._dragDropMode
		csUIDrag.enabled = dragDropOpen
	end
end

------------------------------------------------------------------
--- item draw
------------------------------------------------------------------
function UIListBase:SetFuncOnItemDraw(funcVal)
	self._funcOnItemDraw = funcVal
end
function UIListBase:OnItemDraw(item, itempos, fromHeadTail, bReset)
	self._itemPosMap[item:GetInstanceID()] = itempos

	self:DragDropCheck(item)
	local funcOnItemDraw = self._funcOnItemDraw
	if (funcOnItemDraw) then
		if self._parentWnd then
			local wndName = self._parentWnd:GetWndName()
			if gLGameLanguage:IsAutoLanguage(wndName) then
				self._parentWnd:InitNodeLanguage(item)
			end
		end
		
		local itemdata = self:GetDataByIndex(itempos)
		funcOnItemDraw(self, item, itemdata, itempos, fromHeadTail)
	end
	
	if self._isResetWithoutAni then
		bReset = true
	end
	
	if not self._touchBeginMoveX or not self._touchBeginMoveY then
		if CS.IsValidObject(self._itemRootRectTrans) then
			local localPos = self._itemRootRectTrans.localPosition
			self._touchBeginMoveX = localPos.x
			self._touchBeginMoveY = localPos.y
		end
	end

	if self._parentWnd and not bReset then
		--printInfoN(string.format("play item animation"))
		self._parentWnd:PlayItemAnimation(self, item, itempos)
	end
end
function UIListBase:OnItemReturn(item, itempos)
	self._itemPosMap[item:GetInstanceID()] = nil
	local funcOnItemReturn = self._funcOnItemReturn
    if (funcOnItemReturn) then
        local itemdata = self:GetDataByIndex(itempos)
        funcOnItemReturn(self, item, itemdata, itempos)
    end

	if self._parentWnd then
		self._parentWnd:ClearWndAnimation(item)
	end
end
------------------------------------------------------------------
--- 数据操作
------------------------------------------------------------------
--- 清除所有数据
function UIListBase:RemoveAllData()
	self._curDrawFromIndex = 0
	self._dataTable:RemoveAll()
end
function UIListBase:RefreshList(bReset)
	self._touchBeginMoveX = nil
	self._touchBeginMoveY = nil
	
	self._isResetWithoutAni = false
	self._itemBeginSysTime = os.time()
	if not bReset then
		self._refreshCount = self._refreshCount + 1
	end
end
function UIListBase:ResetList()
	self._touchBeginMoveX = nil
	self._touchBeginMoveY = nil
	
	self._isResetWithoutAni = true
	self._itemBeginSysTime = os.time()
end
function UIListBase:RefreshItems()
	self._touchBeginMoveX = nil
	self._touchBeginMoveY = nil
	
	for itemInstanceID,itempos in pairs(self._itemPosMap) do
		if itempos then
			self:DrawItemByIndex(itempos)
		end
	end
end
function UIListBase:DrawItemByIndex(itempos)
end
--- 获得所有数据数量
function UIListBase:GetDataSize()
	return self._dataTable:GetSize()
end
function UIListBase:IsReversePos()
	return self._isReversePos
end
function UIListBase:SetReversePos(bReversePos)
	self._isReversePos = bReversePos
end
--- 根据 itempos 获得 itemkey
function UIListBase:GetKeyByIndex(index)
	return self._dataTable:GetKeyAt(index)
end
--- 根据 itemkey 获得 itempos
function UIListBase:GetIndexByKey(key)
	return self._dataTable:GetIndexByKey(key)
end
---获取item绑定的数据 通过键key
function UIListBase:GetDataByKey(key)
	return self._dataTable:GetByKey(key)
end
---获取item绑定的数据 通过索引index
function UIListBase:GetDataByIndex(index)
	return self._dataTable:GetAt(index)
end
---设置item绑定的数据 通过key不会修改list长度
---@itemkey list有这个key才会处理
---@itemdata 数据
function UIListBase:SetDataByKey(itemkey, itemdata)
	self._dataTable:SetByKey(itemkey,itemdata)
end
---删除数据 会修改list 的长度
---@itemkey list有这个key才会处理
---return 返回删除的数据
function UIListBase:DelDataByKey(itemkey)
	return self._dataTable:RemoveByKey(itemkey)
end
---设置item绑定的数据 通过索引 不会修改list长度
---@itempos 索引 itempos 不能超过list长度
---@itemdata 数据
function UIListBase:SetDataByIndex(itempos, itemdata)
	self._dataTable:SetAt(itempos,itemdata)
end
---删除数据 会修改list 的长度
---@itempos 不超过list 长度
---return 返回删除的数据
function UIListBase:DelDataByIndex(itempos)
	return self._dataTable:RemoveAt(itempos)
end
---增加列表数据 会修改列表长度的新增唯一方法
function UIListBase:AddData(itemkey, itemdata, itempos)
	if (itempos == nil) then
		itempos = self._dataTable:GetSize() + 1
	end
	self._dataTable:Add(itemkey, itemdata, itempos)
end
------------------------------------------------------------------
--- 分组模式
------------------------------------------------------------------
---@return UIListBaseGroup | nil
function UIListBase:FindGroupDataByKey(groupkey)
	return self._groupTable:GetByKey(groupkey)
end

---@return UIListBaseGroup | nil
function UIListBase:FindGroupDataByPos(itemPos)
	local groupTable = self._groupTable
	local group
	for i = 1, groupTable:GetSize() do
		group = groupTable:GetAt(i)
		if (group:IsInGroup(itemPos)) then
			return group
		end
	end
	return nil
end

---@return UIListBaseGroup
function UIListBase:AddGroupData(groupKey, colSize, dataCount)
	local groupTable = self._groupTable
	---@type UIListBaseGroup
	local group = groupTable:GetByKey(groupKey)
	if (not group) then
		group = UIListBaseGroup:New()
		groupTable:Add(groupKey, group)
	end
	group:Create(groupKey, colSize, dataCount)
	local dataPosBegin = 0
	for i = 1, groupTable:GetSize() do
		group = groupTable:GetAt(i)
		if (group.groupKey == groupKey) then
			break
		end
		dataPosBegin = dataPosBegin + group.groupRowCount
	end
	dataPosBegin = dataPosBegin + 1
	group:SetGroupRowBegin(dataPosBegin)
	return group
end

function UIListBase:ClearAllLoadAnimation()
	-- 用来重载的
end

function UIListBase:ShowItemEnterAnimation(item, bAni, datapos)
	-- 用来重载的
		
end

-- 启用动态加载
-- bEnable 是否启用
-- aniTime每次加载间隔，0表示一帧
-- onceCount每次加载次数
-- aniType  1:Y缩放 2:X缩放 0:XY缩放
function UIListBase:EnableLoadAnimation(bEnable, aniTime, onceCount, aniType)
	-- 用来重载的
end

function UIListBase:SetLoadAnimationScale(scale, time)
	-- 用来重载的
end
function UIListBase:SetItemLoadType(loadType, aniType)
	-- 用来重载的
	self._itemLoadType = loadType
	self._itemAniType = aniType
end

function UIListBase:SetMetaData(data)
	self._metaData = data
end

function UIListBase:GetMetaData()
	return self._metaData
end

function UIListBase:OnWndClose()
	self._isWndDestroy = true
	self._itemPosMap = {}
	self._funcOnItemDraw = nil
	self:ClearAllLoadAnimation()
	if self.OnDispose then
		self:OnDispose()
	end
	if self.Destroy then
		self:Destroy()
	end
end

function UIListBase:IsDestroy()
	return self._isWndDestroy
end
------------------------------------------------------------------

return UIListBase