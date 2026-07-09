---
--- Created by wzz.
--- DateTime: 2024/4/9 15:53:54
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDraconicSummonPool:LWnd
local UIDraconicSummonPool = LxWndClass("UIDraconicSummonPool", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDraconicSummonPool:UIDraconicSummonPool()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDraconicSummonPool:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDraconicSummonPool:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDraconicSummonPool:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self._wishDraconicId = gModelDraconic:GetWishDraconicRefId()

	self:InitTexts()
	self:InitEvents()
	self:InitList()

	self:Refresh()
end

-- 刷新界面
function UIDraconicSummonPool:Refresh()
	CS.ShowObject(self.mItem, self._wishDraconicId ~= 0)

	if self._wishDraconicId ~= 0 then
		local ref = gModelDraconic:GetSummonItemPoolRefById(self._wishDraconicId)
		local item = LUtil.GetRefItemData(ref.reward)

		self:DrawItem(self.mItem, item)
	end
end

-- 长按列表 item
function UIDraconicSummonPool:OnLongClickItem(refId, num)
	GF.OpenWndUp("UIInip", { refId = refId, showNum = num })
end

-- 初始事件
function UIDraconicSummonPool:InitEvents()
	self:SetWndClick(self.mReturnBtn, function(...) self:WndClose() end)
	self:SetWndClick(self.mMask, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function(...) self:OnClickBtnConfirm() end)
end

-- 绘制item
function UIDraconicSummonPool:DrawItem(mItem, itemdata)
	local itemdata = {itype = itemdata.type, refId = itemdata.refId, num = itemdata.count}
	local itype = itemdata.itype
	local refId = itemdata.refId

	local instanceID = mItem:GetInstanceID()
	local baseClass, isNew = self:GetCommonIcon(instanceID)
	if isNew then
		baseClass:Create(mItem)
	end

	if itype == LItemTypeConst.TYPE_RUNE then
		baseClass:EnableShowNum(false)
		baseClass:SetRuneData(itemdata:GetServerData())
	elseif itype == LItemTypeConst.TYPE_EQUIP then
		baseClass:SetEquipIcon(refId)
		baseClass:EnableShowNum(false)
	else
		baseClass:EnableShowNum(false)
		baseClass:SetCommonReward(itype, refId, itemdata.num)
		baseClass:RefreshActiveShow()
	end

	self:SetWndClick(mItem, function()
		if itype == LItemTypeConst.TYPE_EQUIP then
			gModelEquip:SetNewStatusEquip(refId, false)
			CS.ShowObject(redPointTrans, false)
		end
		self:OpenTips({ itype = itype, refId = refId, itemdata = itemdata})
	end)

	baseClass:DoApply()

end

-- 列表
function UIDraconicSummonPool:InitList()
	local uiList = self:GetUIScroll("mCommonList")
	self._uiAllList = uiList

	local items = gModelDraconic:GetSummonItemPoolRef()
	local allListData = {}
	for k, v in ipairs(items) do
		local item = LUtil.GetRefItemData(v.reward)
		allListData[k] = {ref = v, itype = item.type, refId = item.refId, num = item.count}
	end

	uiList:Create(self.mCommonList, allListData, function(...)
		self:OnDrawAllItemCell(...)
	end, UIItemList.SUPER_GRID, false)


	local item = allListData[1]
	local itemRef = GameTable.PlayerItemRef[item.refId]
	local qualityRef = GameTable.RarityRef[itemRef.quality]
	self:SetWndEasyImage(self.mShowBg, qualityRef.iconBg)

	-- else
	--     uiList:RefreshList(allListData)

	--     local superList = uiList:GetList()
	--     if isRefresh then
	--         superList:DrawAllItems(false)
	--     else
	--         superList:MoveToPos(1, 0)
	--         superList:DrawAllItems(true)
	--     end
	-- end
end

-- 点击确认
function UIDraconicSummonPool:OnClickBtnConfirm()
	if self._wishDraconicId == gModelDraconic:GetWishDraconicRefId() then
		self:WndClose()
		return
	end

	gModelDraconic:DraconicDropWishReq(self._wishDraconicId)
	self:WndClose()
end

function UIDraconicSummonPool:OnDrawAllItemCell(list, item, itemdata, itempos)
	local aniNode = CS.FindTrans(item, "AniRoot")
	item = aniNode
	local uiIconRoot = CS.FindTrans(item, "IconRoot")
	local refId = itemdata.refId or itemdata:GetRefId()
	local itype = itemdata.itype or itemdata:GetType()

	local key = refId

	if itype == LItemTypeConst.TYPE_RUNE then
		key = itemdata.id or itemdata:GetRuneId()
	elseif itype == LItemTypeConst.TYPE_OUTFIT then
		key = refId .. itemdata.heroRefId .. itemdata.star .. itemdata.starExp
		-- 【G公共支持】删除伙伴晶石功能相关数据
		-- elseif itype == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD then
		-- 	key = refId..itemdata.cells
		-- elseif itype == LItemTypeConst.ICON_TYPE_CRYSTAL_DRAWING then
		-- 	key = refId
	end


	local OutfitFull = self:FindWndTrans(aniNode, "OutfitFull")
	local isShowOutfitFull = false

	local FullStatus = self:FindWndTrans(aniNode, "FullStatus")
	local showFullStatus = false
	if uiIconRoot then
		local instanceID = item:GetInstanceID()
		local baseClass, isNew = self:GetCommonIcon(instanceID)
		if isNew then
			baseClass:Create(self:FindWndTrans(uiIconRoot, "Icon"))
			baseClass:EnableSupportMulti(true) --格子支持多类型重用
		end

		-- self:CheckDrawItemEffect(item, instanceID, itype, refId, itempos) --物品格子光效创建检测

		if itype == LItemTypeConst.TYPE_RUNE then
			baseClass:EnableShowNum(true)
			baseClass:SetRuneData(itemdata:GetServerData())
			-- 【G公共支持】删除伙伴晶石功能相关数据
			-- elseif itype == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD or itype == LItemTypeConst.ICON_TYPE_CRYSTAL_DRAWING then
			-- 	local itemData = table.light_copy(itemdata)
			-- 	itemData.showNum = itemData.num>0
			-- 	baseClass:SetRewardDetailItem(itemData)
		elseif itype == LItemTypeConst.TYPE_EQUIP then
			baseClass:SetEquipIcon(refId)
			baseClass:EnableShowNum(true)
		else
			baseClass:EnableShowNum(false)
			baseClass:SetCommonReward(itype, refId, itemdata.num)
			baseClass:RefreshActiveShow()
		end

		self:SetWndClick(uiIconRoot, function()
			-- if itype == LItemTypeConst.TYPE_EQUIP then
			-- 	gModelEquip:SetNewStatusEquip(refId, false)
			-- 	CS.ShowObject(redPointTrans, false)
			-- end
			-- self:OpenTips({ itype = itype, refId = refId, itemdata = itemdata})
			self:OnClickItem(itemdata)
		end)

		self:SetWndLongClick(uiIconRoot, function() self:OnLongClickItem(refId, itemdata.num) end)

		baseClass:DoApply()
	end
	CS.ShowObject(OutfitFull, isShowOutfitFull)
	CS.ShowObject(FullStatus, showFullStatus)

	local itemNameTrans = CS.FindTrans(item, "ItemName")
	if itemNameTrans then
		local name = self:GetItemName(itype, refId, itemdata)
		self:SetWndText(itemNameTrans, name)
		self:InitTextShowWithLanguage(itemNameTrans)
	end
	local Select = CS.FindTrans(item, "Select")
	CS.ShowObject(Select, self._wishDraconicId == itemdata.ref.refId)
end

-- 初始界面化文本
function UIDraconicSummonPool:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(41023))
	self:SetWndText(self.mTxtTips1, ccClientText(41024))
	self:SetWndText(self.mTxtTips2, ccClientText(41025, gModelDraconic:GetSummonWishRate()))
	self:SetWndButtonText(self.mBtnConfirm, ccClientText(41026))
end

function UIDraconicSummonPool:OpenTips(data)
	local itype, refId, itemdata = data.itype, data.refId, data.itemdata
	local dataStateList = {}
	if itype == LItemTypeConst.TYPE_ITEM then
		if itemdata._state == ModelItem.ITEM_NEW_STATUS then
			table.insert(dataStateList, { type = itype, refId = refId, state = 0 })
		end
		local itemRef = gModelItem:GetRefByRefId(refId)
		local itemType = itemRef.type
		if itemType == ModelItem.Item_LEIDENGITEM or itemType == ModelItem.Item_DENGJILJITEM then
			gModelGeneral:OpenItemInfoTip(refId, nil, nil, nil, nil, nil, nil, nil, itemdata.id)
		--elseif itemType == ModelItem.Item_MainCitySkin then
		--	GF.OpenWnd("UIMCitySnItemPop", { refId = refId })
		elseif itemType == ModelItem.Item_Summon then
			local itemdata = data.itemdata
			gModelGeneral:OpenItemInfoTip(refId, nil, nil, nil, nil, nil, nil, nil, itemdata.id)
		elseif itemType == ModelItem.ITEM_WISH_MATCH then
			gModelGeneral:OpenItemInfoTip(refId, 1, nil, nil, nil, nil, nil, nil, itemdata.id, nil, nil, nil, nil,
				itemdata)
		elseif itemType == ModelItem.ITEM_THOUSAND then
			gModelGeneral:OpenItemInfoPara(itemdata)
		else
			gModelGeneral:OpenItemInfoTip(refId)
		end
	elseif itype == LItemTypeConst.TYPE_EQUIP then
		gModelGeneral:OpenEquipInfoTip(refId, nil, 1)
	elseif itype == LItemTypeConst.TYPE_RUNE then
		isRefresh = true
		local runeData = itemdata:GetServerData()
		local _data = { openWay = 1, runeData = runeData, }
		gModelGeneral:OpenRuneInfoTip(_data)
		local id = runeData.id
		table.insert(dataStateList, { type = itype, refId = refId, id = id, state = 0 })
		-- 【G公共支持】删除伙伴晶石功能相关数据
		-- elseif itype == LItemTypeConst.ICON_TYPE_CRYSTAL_SHARD then
		-- 	local shardData = table.clone(itemdata)
		-- 	shardData.showWear = true
		-- 	gModelGeneral:ShowRewardDetailTip(shardData)
		-- elseif itype == LItemTypeConst.ICON_TYPE_CRYSTAL_DRAWING then
		-- 	local shardData = table.clone(itemdata)
		-- 	shardData.showWear = true
		-- 	gModelGeneral:ShowRewardDetailTip(shardData)
	end
	if #dataStateList > 0 then
		gModelItem:OnDataStateChangeReq(dataStateList)
	end
end

function UIDraconicSummonPool:GetItemName(itype, refId, itemdata)
    local name = gModelGeneral:GetItemName(itype, refId, 1, nil, itemdata)
    return name
end

function UIDraconicSummonPool:OnClickItem(itemData)
	if self._wishDraconicId == itemData.ref.refId then
		self._wishDraconicId = 0
	else
		self._wishDraconicId = itemData.ref.refId
	end
	self._uiAllList:DrawAllItems()
	self:Refresh()
end

------------------------------------------------------------------
return UIDraconicSummonPool