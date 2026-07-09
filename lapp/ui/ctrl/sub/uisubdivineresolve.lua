---
--- Created by Administrator.
--- DateTime: 2024/11/14 17:18:46
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubDivineResolve:LChildWnd
local UISubDivineResolve = LxWndClass("UISubDivineResolve", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubDivineResolve:UISubDivineResolve()
	self._resolveSelectMap = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubDivineResolve:OnWndClose()
	LChildWnd.OnWndClose(self)
	self:ClearTimer()
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubDivineResolve:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubDivineResolve:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mTxtResolveAwardTips,ccClientText(10253))
	self:SetWndText(self.mTxtResolveTitle,ccClientText(46146))
	self:SetWndButtonText(self.mBtnResolve, ccClientText(41048))
	self:SetWndButtonText(self.mBtnResolveAll, ccClientText(41047))
	self:SetWndClick(self.mBtnResolve, function() self:OnClickBtnResolve() end)
	self:SetWndClick(self.mBtnResolveAll, function() self:OnClickBtnResolveAll() end)
	self:SetWndClick(self.mBtnHelp, function() self:OnHelp() end)
	self:WndEventRecv(EventNames.On_Item_Change,function() self:RefreshResolve() end)
	self:RefreshResolve()
	self:InitEmptyTips()
end

-- 一键分解
function UISubDivineResolve:OnClickBtnResolveAll()
	local list = {}
	for k, v in ipairs(self._uiResolveDataList) do
		local refId = v:GetRefId()
		local count = v:GetNum()
		if self:IsStarMaxByItemRefId(refId) then
			table.insert(list, { refId = refId, count = count })
		end
	end
	if #list == 0 then
		GF.ShowMessage(ccClientText(46155))
		return
	end

	self._resolveSelectMap = {}
	for k, v in ipairs(list) do
		self._resolveSelectMap[v.refId] = v.count
	end
	self:RefreshResolve()

	self:ShowResolveItemList(list)
end
function UISubDivineResolve:IsStarMaxByItemRefId(itemRefId)
    local star, refId = gModelDivineWeapon:GetDivineStarByItemId(itemRefId)
    if not star then
        return false
    end
    return star >= gModelDivineWeapon:GetMaxStar(refId)
end

-- 点击 分解列表 item
function UISubDivineResolve:OnCickResolveItem(refId, num)
	if self._resolveSelectMap[refId] then
		self._resolveSelectMap[refId] = nil
	else
		self._resolveSelectMap[refId] = num
	end
	self:RefreshResolve()
end

-- 空列表提示
function UISubDivineResolve:InitEmptyTips()
	local text = self.mEmptyText
	local emptyList = self:GetCommonEmptyList("_empty")
	local data =
	{
		refId = 43001,
		IntroTran = text,
	}
	emptyList:RefreshUI(data)
end
-- 显示分解获得的物品列表
function UISubDivineResolve:RefreshResolveItem()
	local list = {}
	for refId, count in pairs(self._resolveSelectMap or {}) do
		table.insert(list, { refId = refId, count = count })
	end
	local itemList = gModelDivineWeapon:GetDivineResolveItemList(list)

	local instanceID = self.mResolveAward:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {}
		local uiList = UIIconEasyList:New()
		uiList:Create(self, self.mResolveAward)
		-- uiList:SetShowNum(false)
		uiList:SetIconParentPath("itemRoot")
		-- uiList:SetShowExtraNum(true, "itemNum")

		itemCache.uiList = uiList
		self:SetComponentCache(instanceID, itemCache)
	end
	itemCache.uiList:RefreshList(itemList)
	itemCache.uiList:EnableScroll(true,true)
	CS.ShowObject(self.mResolveAward.parent, #itemList > 0)
end
function UISubDivineResolve:ResolveEffect(list)
	self:ClearTimer()
	self._timer = LxTimer.DelayTimeCall(function()
		gModelDivineWeapon:OnDivineWeaponDecomposeReq(list)
		self:ClearTimer()
	end,1.2)
	local instance = self.mEffect:GetInstanceID()
	self:CreateWndEffect(self.mEffect, "fx_sw_fenjie", instance, 100, false, false)
end
function UISubDivineResolve:RefreshResolve()
	local dataList = gModelItem:GetItemListByItemType(gModelItem.TTEM_TYPE_DIVINE, true)

	self._uiResolveDataList = dataList
	if not self._uiResolveList then
		local uiList = self:GetUIScroll("mResolveList")
		self._uiResolveList = uiList

		uiList:Create(self.mResolveList, dataList, function(...)
			self:OnDrawResolveItem(...)
		end, UIItemList.SUPER_GRID, true)
	else
		self._uiResolveList:RefreshList(dataList)
		self._uiResolveList:DrawAllItems()
	end
	self:RefreshResolveItem()

	CS.ShowObject(self.mNoRecord, #dataList == 0)
end

-- 长按分解列表 item
function UISubDivineResolve:OnLongClickResolveItem(refId, num)
	GF.OpenWndUp("UIInip", { refId = refId, showNum = num })
end

function UISubDivineResolve:ClearTimer()
    local timer = self._timer
    if timer then
        LxTimer.DelayTimeStop(timer)
        self._timer = nil
    end
end

-- 分解
function UISubDivineResolve:OnClickBtnResolve()
	local list = {}
	for refId, count in pairs(self._resolveSelectMap) do
		table.insert(list, { refId = refId, count = count })
	end
	if #list == 0 then
		GF.ShowMessage(ccClientText(46154))
		return
	end

	self:ShowResolveItemList(list)
end

-- 显示分解获得的物品列表
function UISubDivineResolve:ShowResolveItemList(list)
	local itemList = gModelDivineWeapon:GetDivineResolveItemList(list)
	local function rightFunc()
		self._resolveSelectMap = {}
		self:ResolveEffect(list)
	end

	for k, v in ipairs(itemList) do
		v.itemId = v.refId
		v.itype = v.type
	end

	gModelGeneral:OpenUIOrdinTips({
		refId = 480000,--1800002
		itemList = itemList,
		func = rightFunc,
	})
end

-- 分解列表 item
function UISubDivineResolve:OnDrawResolveItem(list, item, itemdata, itempos)
	local refId = itemdata:GetRefId()
	local num = tonumber(itemdata:GetNum())
	local select = self._resolveSelectMap[refId] ~= nil

	local param = {
		refId = refId,
		num = num,
		select = select,
		clickFunc = function() self:OnCickResolveItem(refId, num) end
	}
	local itemRoot = CS.FindTrans(item, "Item")
	self:SetWndLongClick(itemRoot, function() self:OnLongClickResolveItem(refId, num) end)

	local instanceID = itemRoot:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {}
        itemCache.bg = CS.FindTrans(itemRoot, "bg")
        itemCache.icon = CS.FindTrans(itemRoot, "icon")
        itemCache.num = CS.FindTrans(itemRoot, "num")
        itemCache.select = CS.FindTrans(itemRoot, "select")
        self:SetComponentCache(instanceID, itemCache)
    end

    local refId = param.refId
    if refId then
        local strNum = ""
        if param.num and param.num > 0 then
            strNum = LUtil.NumberCoversion(param.num)
        end

        local iconPath, iconBgPath = gModelItem:GetItemImgByRefId(refId)
        self:SetWndEasyImage(itemCache.icon, iconPath)
        self:SetWndEasyImage(itemCache.bg, iconBgPath)
        self:SetWndText(itemCache.num, strNum)
    end

    local select = not not param.select
    local mask = not not param.mask
    local lock = not not param.lock
    CS.ShowObject(itemCache.select, select)

    if param.clickFunc then
        self:SetWndClick(itemRoot, param.clickFunc)
    end

end
function UISubDivineResolve:OnHelp()
	GF.OpenWnd("UIBzTips",{refId = 186})
end

------------------------------------------------------------------
return UISubDivineResolve