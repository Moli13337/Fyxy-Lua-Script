---
--- Created by wzz.
--- DateTime: 2025/2/28 15:17:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDefenceWarForMation:LWnd
local UIDefenceWarForMation = LxWndClass("UIDefenceWarForMation", LWnd)
------------------------------------------------------------------

local RectangleContainsScreenPoint = UnityEngine.RectTransformUtility.RectangleContainsScreenPoint

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDefenceWarForMation:UIDefenceWarForMation()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDefenceWarForMation:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDefenceWarForMation:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDefenceWarForMation:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitTexts()
	self:InitEvents()
	self:InitMainCardList()
	self:Refresh()
	self:RefreshEmptyTips()
end

-- 刷新主卡片选中
function UIDefenceWarForMation:RefreshMainCardSelect()
	for pos, tab in ipairs(self._uiCardList) do
		CS.ShowObject(tab.select, pos == self._curChangeIndex)
	end
end

-- 刷新空列表
function UIDefenceWarForMation:RefreshEmptyTips()
	local text = self.mEmptyText
	local emptyList = self:GetCommonEmptyList("_empty")
	local data =
	{
		refId = 14007,
		IntroTran = text,
		--TextBgTran,
		--IconTran,
		--GetBtn,
		--GetBtnText
		--ButtonRoot,
	}
	emptyList:RefreshUI(data)
end


-- 点击确认
function UIDefenceWarForMation:OnClickConfirm()
	local list = gModelDefenceWar:GetOneKeyUp()
	local hasChange = false
	for pos, heroId in ipairs(list) do
		local oldRefId = gModelDefenceWar:GetUseRefId(pos)
		if oldRefId ~= heroId then
			hasChange = true
			break
		end
	end

	if not hasChange then
		GF.ShowMessage(ccClientText(46811))
		return
	end

	gModelDefenceWar:ProtectCityFormationReq(list)
	-- self:WndClose()
end

-- 点击头像列表项
function UIDefenceWarForMation:OnClickHeadItem(itemData)
	local ref = itemData.ref
	local heroId = ref.heroId
	if gModelDefenceWar:HadUsed(heroId) then
		GF.ShowMessage(ccClientText(46808))
		return
	end

	-- local list = gModelDefenceWar:GetEmptyPosList()
	-- if #list == 0 then
	-- 	GF.ShowMessage(ccClientText(46809))
	-- 	return
	-- end

	if self._curChangeIndex == nil then
		return
	end

	gModelDefenceWar:ChangeHero(self._curChangeIndex, heroId)
	self._curChangeIndex = nil

	local list = {}
	for pos = 1, 5 do
		local heroId = gModelDefenceWar:GetUseRefId(pos)
		table.insert(list, heroId)
	end
	gModelDefenceWar:ProtectCityFormationReq(list)
	self:RefreshMainCard()
	self:RefreshHeadList()
end

-- 绘制列表item项
function UIDefenceWarForMation:OnDrawListItem(list, item, itemData, itemPos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {
			bg     = CS.FindTrans(item, "AniRoot/Bg"),
			icon   = CS.FindTrans(item, "AniRoot/Icon"),
			select = CS.FindTrans(item, "AniRoot/Select"),
			txtLev = CS.FindTrans(item, "AniRoot/TxtLev"),
		}
		self:SetComponentCache(instanceID, itemCache)
		CS.ShowObject(itemCache.select, false)
	end

	local ref = itemData.ref
	local lev = itemData.lev

	self:SetWndEasyImage(itemCache.icon, ref.headIcon)
	self:SetWndEasyImage(itemCache.bg, "public_item_bg_" .. ref.quality)

	self:SetWndText(itemCache.txtLev, lev)

	self:SetWndClick(item, function()
		self:OnClickHeadItem(itemData)
	end)
end

-- 初始主卡片列表
function UIDefenceWarForMation:InitMainCardList()
	self._uiCardList = {}
	for i = 1, 5 do
		local tab           = {}
		local trans         = self["mCard" .. i]
		tab.trans           = trans
		tab.lock            = CS.FindTrans(trans, "Lock")
		tab.add             = CS.FindTrans(trans, "Add")
		tab.empty           = CS.FindTrans(trans, "Empty")
		tab.cardRoot        = CS.FindTrans(trans, "Card")
		tab.card            = CS.FindTrans(trans, "Card/DefenceWarCard")
		tab.select          = CS.FindTrans(trans, "Select")
		tab.btnChange       = CS.FindTrans(trans, "BtnChange")
		self._uiCardList[i] = tab

		self:SetWndClick(trans, function() self:OnClickMainCard(i) end)
		self:SetWndClick(tab.btnChange, function() self:OnClickBtnChange(i) end)
		self:InternalUIDragSetItem(i, tab.cardRoot, CS.YXUIDrag.DragMode.DragCloneHideOrigin, nil, nil,
			trans.parent.gameObject)
	end
end

-- 开始拖
function UIDefenceWarForMation:UIDragTryOnBegin(pos, eventData)

end

-- 点击主卡片
function UIDefenceWarForMation:OnClickMainCard(i)

end

-- 初始界面化文本
function UIDefenceWarForMation:InitTexts()
	-- self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndText(self.mTitle, ccClientText(46805))
	self:SetWndButtonText(self.mBtnConfirm, ccClientText(46807))

	for i = 2, 5 do
		self:SetWndText(self["mTxtIndex" .. i], i)
	end
	self:SetWndText(self.mTxtIndex1, ccClientText(46806))
end

-- 刷新界面
function UIDefenceWarForMation:Refresh()
	self:RefreshMainCard()
	self:RefreshHeadList()
end

-- 正在拖
function UIDefenceWarForMation:UIDragTryOnDrag(pos, eventData)

end

-- 结束拖
function UIDefenceWarForMation:UIDragTryOnEnd(pos, eventData)
	local toPos = self:ContainItem(eventData.position, eventData.pressEventCamera)
	if not toPos then
		return
	end

	if pos == toPos then
		return
	end
	self._curChangeIndex = nil
	gModelDefenceWar:ChangePos(pos, toPos)

	local list = {}
	for pos = 1, 5 do
		local heroId = gModelDefenceWar:GetUseRefId(pos)
		table.insert(list, heroId)
	end
	gModelDefenceWar:ProtectCityFormationReq(list)
	self:RefreshMainCard()
end

-- 刷新主卡片
function UIDefenceWarForMation:RefreshMainCard()
	for pos, tab in ipairs(self._uiCardList) do
		local heroId = gModelDefenceWar:GetUseRefId(pos)
		local lev = gModelDefenceWar:GetHeroLev(heroId)
		local empty = heroId == nil
		CS.ShowObject(tab.empty, empty)
		CS.ShowObject(tab.add, empty)
		CS.ShowObject(tab.card, not empty)
		if heroId then
			gModelDefenceWar:DrawCard(self, tab.card, { heroId = heroId, lev = lev })
		end
	end
	self:RefreshMainCardSelect()
end


-- 坐标是否在item内
function UIDefenceWarForMation:ContainItem(pos, camera)
	for index, v in ipairs(self._uiCardList) do
		if RectangleContainsScreenPoint(v.trans, pos, camera) then
			return index
		end
	end
	return nil
end

-- 点击按钮更换
function UIDefenceWarForMation:OnClickBtnChange(i)
	if self._curChangeIndex == i then
		return
	end
	self._curChangeIndex = i
	self:RefreshMainCardSelect()
end

-- 初始事件
function UIDefenceWarForMation:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function() self:OnClickConfirm() end)

	self:WndEventRecv(EventNames.DEFENCEWAR_BASE_INFO, function() self:Refresh() end)
	self:WndEventRecv(EventNames.DEFENCEWAR_FORMATION_CHANGE, function() self:Refresh() end)
end

-- 刷新头像列表
function UIDefenceWarForMation:RefreshHeadList()
	local useMap = {}
	for pos = 1, 5 do
		local heroId = gModelDefenceWar:GetUseRefId(pos)
		if heroId then
			useMap[heroId] = true
		end
	end

	local dataList = {}
	local list = gModelDefenceWar:GetHeroDataList(true)
	for _, data in ipairs(list) do
		if data.lev > 0 and not useMap[data.ref.heroId] then
			table.insert(dataList, data)
		end
	end

	if not self._uiList then
		local uiList = self:GetUIScroll("mList")
		self._uiList = uiList

		uiList:Create(self.mList, dataList, function(...)
			self:OnDrawListItem(...)
		end, UIItemList.SUPER_GRID)
	else
		self._uiList:RefreshList(dataList)
		self._uiList:DrawAllItems()
	end

	CS.ShowObject(self.mNoRecord2, #dataList == 0)
end

------------------------------------------------------------------
return UIDefenceWarForMation