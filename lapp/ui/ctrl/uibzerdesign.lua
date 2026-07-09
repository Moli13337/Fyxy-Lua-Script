---
--- Created by Administrator.
--- DateTime: 2023/10/14 17:44:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBzerDesign:LWnd
local UIBzerDesign = LxWndClass("UIBzerDesign", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBzerDesign:UIBzerDesign()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBzerDesign:OnWndClose()

	self:ClearTween()

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBzerDesign:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBzerDesign:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetStaticContent()
	self:InitUIEvent()
	self:OnWndRefresh()
end


function UIBzerDesign:OnWndRefresh()
	self._isForeign = gLGameLanguage:IsForeignVersion()
	--local dataList = gModelGameHelper:GetDesignPlayList()

	--local root = self:FindWndTrans(self.mItemList,"ItemRoot")
	--for k,v in ipairs(dataList) do
	--	local item = self:FindWndTrans(root,"playItem_"..k)
	--	self:OnDrawItem(item,v,k)
	--end
	--
	--self:InitDrag(dataList)
end

function UIBzerDesign:InitDrag(dataList)
	if self._dragItemDataList then
		return
	end

	self._dragItemDataList = {}
	self._dragOriginPos = {}

	local ItemRoot = self:FindWndTrans(self.mItemList,"ItemRoot")
	local keyName = "playItem_"
	local trans
	for k,v in ipairs(dataList) do
		local transKey = keyName..k
		trans = self:FindWndTrans(ItemRoot,transKey)

		local vector3List = trans:GetLocalCorners()
		local vecMin = vector3List[0]
		local vecMax = vector3List[2]
		local minX = vecMin.x
		local minY = vecMin.y
		local maxX = vecMax.x
		local maxY = vecMax.y
		local centerX = (vecMax.x + vecMin.x) / 2
		local centerY = (vecMax.y + vecMin.y) / 2
		local width = vecMax.x - vecMin.x
		local height = vecMax.y - vecMin.y
		local midW = width / 2
		local midH = height / 2

		self._dragItemDataList[transKey] = {
			key = transKey,
			sortIndex = k,       --根据拖拽变动
			metaData = v,
			item = trans,
			minX=minX,
			minY=minY,
			maxX=maxX,
			maxY=maxY,
			centerX = centerX,
			centerY = centerY,
			width = width,
			height = height,
			midW = midW,
			midH = midH,
		}
		table.insert(self._dragOriginPos, trans.localPosition)

		self:InternalUIDragSetItem(transKey,trans,CS.YXUIDrag.DragMode.DragNothing)
	end


	local len = #self._dragOriginPos
	local top = self._dragOriginPos[1]
	local bottom = self._dragOriginPos[len]
	local firstName,lastName = keyName .. "1",keyName .. len
	local itemTopData = self._dragItemDataList[firstName]
	local itemBottomData = self._dragItemDataList[lastName]

	self._dragOriginLimitMinY = bottom.y + itemBottomData.minY
	self._dragOriginLimitMaxY = top.y + itemTopData.maxY

	self._dragOriginLimitMinX =  top.x + itemTopData.minX
	self._dragOriginLimitMaxX =  bottom.x + itemBottomData.maxX

end

function UIBzerDesign:UIDragOnBegin(dragKey, eventData)
	self._dragItemData = nil

	local itemData = self._dragItemDataList[dragKey]
	if not itemData then return end

	local item = itemData.item
	self._dragItemData = itemData
	item:SetAsLastSibling()
	local camera = eventData.pressEventCamera
	local pos = camera:ScreenToWorldPoint(eventData.position)
	pos = item.parent:InverseTransformPoint(pos)
	self._dragOffset = item.localPosition - pos
end

function UIBzerDesign:ClearTween()
	if self._dragItemDataList then
		for k,v in pairs(self._dragItemDataList) do
			if v.tween then
				v.tween:Kill(false)
			end
		end
	end
end

function UIBzerDesign:OnDrawItem(item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootIndex = self:FindWndTrans(AniRoot,"index")

	local namePath = self._isForeign and "nameEn" or "name"
	local AniRootName = self:FindWndTrans(AniRoot,namePath)

	self:SetWndText(AniRootIndex,itempos)
	self:SetWndText(AniRootName,ccLngText(itemdata.ref.name))
end

function UIBzerDesign:UIDragOnDrag(dragKey,eventData)
	if not self._dragItemData or self._dragItemData.key ~= dragKey then
		return
	end
	local trans = self._dragItemData.item
	local camera = eventData.pressEventCamera
	local pos = camera:ScreenToWorldPoint(eventData.position)
	pos = trans.parent:InverseTransformPoint(pos)
	pos = pos + self._dragOffset

	local minY = pos.y + self._dragItemData.minY
	local maxY = pos.y + self._dragItemData.maxY
	local minX = pos.x + self._dragItemData.minX
	local maxX = pos.x + self._dragItemData.maxX
	if minY < self._dragOriginLimitMinY then
		pos.y = self._dragOriginLimitMinY -  self._dragItemData.minY
	elseif maxY > self._dragOriginLimitMaxY then
		pos.y = self._dragOriginLimitMaxY -  self._dragItemData.maxY
	end

	if minX < self._dragOriginLimitMinX then
		pos.x = self._dragOriginLimitMinX -  self._dragItemData.minX
	elseif maxX > self._dragOriginLimitMaxX then
		pos.x = self._dragOriginLimitMaxX -  self._dragItemData.maxX
	end

	local transPos = trans.localPosition
	local curPos = Vector3.New(pos.x,pos.y,transPos.z)
	trans.localPosition = curPos

	self:CheckDragItemSwap(self._dragItemData, curPos)
end

function UIBzerDesign:OnClickSave()
	local dataMap = {}
	for k,v in pairs(self._dragItemDataList) do
		local refId = v.metaData.ref.refId
		dataMap[refId] = v.sortIndex
	end

	gModelGameHelper:SaveDesignSort(dataMap)

	FireEvent(EventNames.ON_GAME_HELPER_REFRESH)

	local str = ccClientText(24223) --"战斗助手列表的排列已发生改变"
	GF.ShowMessage(str)
	self:WndClose()
end

function UIBzerDesign:CheckDragItemSwap(curData, curPos)
	local centerY = curData.centerY + curPos.y
	local centerX = curData.centerX + curPos.x
	local defaultIndex = curData.sortIndex
	local swapIndex = nil
	for k,v in pairs(self._dragItemDataList) do
		if v.sortIndex ~= curData.sortIndex then
			local originPos = self._dragOriginPos[v.sortIndex]
			local dragItemData = v
			local itemCenterY = dragItemData.centerY + originPos.y
			local itemCenterX = dragItemData.centerX + originPos.x
			local odisY = math.abs(centerY - itemCenterY)
			local odisX = math.abs(centerX - itemCenterX)
			if odisY < dragItemData.midH and odisX < dragItemData.midW then
				swapIndex = v.sortIndex
				break
			end
		end
	end
	if not swapIndex then return end

	printInfoN("swap index "..swapIndex)

	local startIndex = curData.sortIndex
	local endIndex = swapIndex
	local isUp = false
	if endIndex < startIndex then
		local temp = startIndex
		startIndex = endIndex
		endIndex = temp
		isUp = true
	end

	for k,v in pairs(self._dragItemDataList) do
		if v.sortIndex == defaultIndex then
			self:OnChangeIndex(v,swapIndex)
		elseif v.sortIndex >= startIndex and v.sortIndex <= endIndex then
			if isUp then
				self:OnChangeIndex(v,v.sortIndex + 1)
			else
				self:OnChangeIndex(v,v.sortIndex - 1)
			end

			local item = v.item
			local tween = v.tween
			if tween then
				tween:Kill(false)
			end
			local originPos = self._dragOriginPos[v.sortIndex]
			tween = item:DOLocalMove(originPos, 0.2)
			tween:OnComplete(function()
				v.tween = nil
			end)
			v.tween = tween
			tween:PlayForward()
		end
	end
end

function UIBzerDesign:SetStaticContent()
	local str =ccClientText(24217)
	self:SetWndText(self.mTitle,str)
	str =ccClientText(24224) --"拖动图标可以改变玩法在战斗助手列表的排列"
	self:SetWndText(self.mIntro,str)
	self:InitTextLineWithLanguage(self.mIntro, -30)
	str =ccClientText(24225) --"恢复初始化"
	self:SetWndButtonText(self.mBtnRecover,str, nil, -2, -30)
	str =ccClientText(24226) --"保存设置"
	self:SetWndButtonText(self.mBtnSave,str, nil, -2, -30)

end

function UIBzerDesign:UIDragOnEnd(dragKey, eventData)
	local dragItemData = self._dragItemData
	self._dragItemData = nil
	if not dragItemData or dragItemData.key ~= dragKey then
		return
	end
	local item = dragItemData.item
	local tween = dragItemData.tween
	if tween then
		tween:Kill(false)
	end
	local originPos = self._dragOriginPos[dragItemData.sortIndex]
	tween = item:DOLocalMove(originPos, 0.15)
	tween:OnComplete(function()
		local dragItemData = self._dragItemDataList[dragKey]
		if dragItemData then
			dragItemData.tween = nil
		end
	end)
	dragItemData.tween = tween
	tween:PlayForward()
end

function UIBzerDesign:OnChangeIndex(dragItemData,newIndex)

	dragItemData.sortIndex = newIndex

	local item = dragItemData.item
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootIndex = self:FindWndTrans(AniRoot,"index")
	self:SetWndText(AniRootIndex,dragItemData.sortIndex)
end

function UIBzerDesign:OnClickRecover()
	for k,v in pairs(self._dragItemDataList) do
		self:OnChangeIndex(v,v.metaData.ref.sort)
		local originPos = self._dragOriginPos[v.sortIndex]
		v.item.localPosition= originPos
	end

	gModelGameHelper:SaveDesignSort({})
	FireEvent(EventNames.ON_GAME_HELPER_REFRESH)

	local str = ccClientText(24222) --"战斗助手列表的排列已恢复到初始化状态"
	GF.ShowMessage(str)
	self:WndClose()
end

function UIBzerDesign:InitUIEvent()
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnRecover,function ()
		self:OnClickRecover()
	end)

	self:SetWndClick(self.mBtnSave,function ()
		self:OnClickSave()
	end)
end

------------------------------------------------------------------
return UIBzerDesign


