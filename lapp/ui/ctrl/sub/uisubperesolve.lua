---
--- Created by Administrator.
--- DateTime: 2024/6/13 14:35:12
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPeResolve:LChildWnd
local UISubPeResolve = LxWndClass("UISubPeResolve", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPeResolve:UISubPeResolve()
	self.resolveMap = {}
	self.moneyId = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPeResolve:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPeResolve:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPeResolve:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:SetWndText(self.mTxtResolveTitle,ccClientText(43741))
	self:SetWndTabText(self.mBtnCancelAll,ccClientText(43742))
	self:SetWndTabText(self.mBtnResolve,ccClientText(43743))
	self:SetWndButtonText(self.mBtnAllSelect,ccClientText(43744))
	self:SetWndText(self.mToggleText,ccClientText(43745))
	self:SetWndText(self.mTxtDesc,ccClientText(43746))
	CS.ShowObject(self.mToggleGou,true)
	self:OnAddClick()
	self:OnInitPanel()
	self:RefreshResolveList()
	self:InitEmptyTips()
end
function UISubPeResolve:OnUpdateMoney()
	local count = gModelItem:GetNumByRefId(self.moneyId)
	self:SetWndText(self.mTxtMoney,LUtil.NumberCoversion(count))
end

function UISubPeResolve:OneKeySelect()
	local isTips = true
	local num = 0
	for k, v in ipairs(self._uiResolveDataList) do
		local refId = v:GetRefId()
		local count = v:GetNum()
		if self:isFullStarByItemId(refId) then--满星筛选
			self.resolveMap[refId] = count
			num = num+1
			isTips = false
			if num>=20 then break end
		end
	end
	if isTips then
		GF.ShowMessage(ccClientText(43747))
		return
	end
	self:RefreshResolveList()
end


-- 空列表提示
function UISubPeResolve:InitEmptyTips()
	local emptyList = self:GetCommonEmptyList("_empty")
	local data =
	{
		refId = 36001,
		IntroTran = self.mEmptyText,
		IconTran = self:FindWndTrans(self.mNoRecord,"EmptyIcon"),
		TextBgTran = self:FindWndTrans(self.mNoRecord,"EmptyTextBg"),
	}
	emptyList:RefreshUI(data)
	local emptyList = self:GetCommonEmptyList("_empty2")
	local data =
	{
		refId = 36002,
		IntroTran = self.mEmptyText2,
	}
	emptyList:RefreshUI(data)
	CS.ShowObject(self.mNoRecord2, true)
end

function UISubPeResolve:GotoResolveItem()
	local count = #self.resolveList
	if count<=0 then
		GF.ShowMessage(ccClientText(43749))
		return
	end
	if not self.mToggleGou.gameObject.activeSelf and #self.hasNotFull>0 then
		local func = function()
			gModelPet:OnPetDecomposeReq(self.resolveList)
		end
		gModelGeneral:OpenUIOrdinTips({refId = 430001,func = func,itemList = self.hasNotFull})
	else

		gModelPet:OnPetDecomposeReq(self.resolveList)
	end

end
-- 分解获得的物品
function UISubPeResolve:RefreshResolveToRwd()
	local list = {}
	local isShow =true
	self.selMaxNum = 0--选中最大数
	self.hasNotFull = {}--有未满星
	for refId, count in pairs(self.resolveMap) do
		table.insert(list, { refId = refId, count = count })
		isShow = false
		self.selMaxNum = self.selMaxNum+1
		if not self:isFullStarByItemId(refId) then table.insert(self.hasNotFull,{ itemId = refId,itemType = 1, itemNum = count }) end
	end
	self.resolveList = list
	self:SetWndTabStatus(self.mBtnResolve,not isShow and 0 or 1)
	local itemList = gModelPet:GetResolveListToRwd(list)
	self:SetWndTabStatus(self.mBtnCancelAll,not isShow and 0 or 1)

	local instanceID = self.mResolveAward:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		itemCache = {}
		local uiList = UIIconEasyList:New()
		uiList:Create(self, self.mResolveAward)
		uiList:SetIconParentPath("itemRoot")
		-- uiList:SetShowNum(false)
		-- uiList:SetShowExtraNum(true, "itemNum")

		itemCache.uiList = uiList
		self:SetComponentCache(instanceID, itemCache)
	end
	itemCache.uiList:RefreshList(itemList)
	CS.ShowObject(self.mResolveAward, #itemList > 0)

	CS.ShowObject(self.mEmptyText2, true)
end
function UISubPeResolve:OnInitPanel()
	local cost = nil
	for _, value in pairs(GameTable.MagicPetRef) do
		cost = value.itemSell
		break
	end
	if cost then
		cost = LUtil.GetRefItemData(cost)
		self.moneyId  = cost.itemId
		local itemRef = GameTable.PlayerItemRef[self.moneyId]
		self:SetWndEasyImage(self.mImgMoney,itemRef.icon)
		local count = gModelItem:GetNumByRefId(self.moneyId)
		self:SetWndText(self.mTxtMoney,LUtil.NumberCoversion(count))

		if not string.isempty(itemRef.jump) then
			CS.ShowObject(self.mImgAdd,true)
		else
			CS.ShowObject(self.mImgAdd,false)
		end
	end
end

function UISubPeResolve:OnCickResolveItem(refId, num)
	if self.resolveMap[refId] then
		self.resolveMap[refId] = nil
	else
		if self.selMaxNum>=20 then
			GF.ShowMessage(ccClientText(43748))
			return
		end
		self.resolveMap[refId] = num
	end
	self:RefreshResolveList()
end
function UISubPeResolve:isFullStarByItemId(itemRefId)
	local petId = GameTable.PlayerItemRef[itemRefId].typeDate and tonumber(GameTable.PlayerItemRef[itemRefId].typeDate)
	local pet = gModelPet:GetPetById(petId)
	if not pet then return false end
	local starCfg = pet:GetPetStarCfg()
	if starCfg and starCfg.rankNext<0 then return true end
	return false
end
function UISubPeResolve:OnDrawResolveItem(list, item, itemdata, itempos)
	local refId = itemdata:GetRefId()
	local num = tonumber(itemdata:GetNum())
	local select = self.resolveMap[refId] ~= nil

	local param = {
		refId = refId,
		num = num,
		select = select
	}
	local itemRoot = CS.FindTrans(item, "DraconicItem")
	self:DrawItem( itemRoot, param)

	self:SetWndLongClick(itemRoot, function()
		GF.OpenWndUp("UIInip", { refId = refId, showNum = num })
	end)
end
function UISubPeResolve:OnAddClick()
	self:SetWndClick(self.mImgHelp, function()
		GF.OpenWnd("UIBzTips",{refId = 170})
    end)

	self:SetWndClick(self.mImgAdd,function()
		if self.moneyId then
			gModelGeneral:OpenGetWayWnd({ itemId = self.moneyId })
		end
	end)
	self:SetWndClick(self.mBtnCancelAll,function()
		self.resolveMap = {}
		self:RefreshResolveList()
		--更新列表
	end)
	self:SetWndClick(self.mBtnResolve,function()
		self:GotoResolveItem()
	end)
	self:SetWndClick(self.mBtnAllSelect,function()
		self.resolveMap = {}
		--更新列表
		self:OneKeySelect()
	end)

	self:SetWndClick(self.mToggle,function()
		CS.ShowObject(self.mToggleGou,not self.mToggleGou.gameObject.activeSelf)
		if self.mToggleGou.gameObject.activeSelf then
			for refId, value in pairs(self.resolveMap) do
				if not self:isFullStarByItemId(tonumber(refId)) then
					self.resolveMap[tonumber(refId)] = nil
				end
			end
		end
		self:RefreshResolveList()
	end)
	self:WndNetMsgRecv(LProtoIds.PetDecomposeResp,function()
		self.resolveList = {}
		self.resolveMap  = {}
		self:RefreshResolveList()
	end)

	self:WndEventRecv(EventNames.On_Item_Change,function()
		self:OnUpdateMoney()
	end)
end

function UISubPeResolve:DrawItem(rootTrans, param)
    local instanceID = rootTrans:GetInstanceID()
    local itemCache = self:GetComponentCache(instanceID)
    if not itemCache then
        itemCache        = {}
        itemCache.bg     = CS.FindTrans(rootTrans, "bg")
        itemCache.icon   = CS.FindTrans(rootTrans, "icon")
        itemCache.num    = CS.FindTrans(rootTrans, "num")
        itemCache.select = CS.FindTrans(rootTrans, "select")
        itemCache.lock   = CS.FindTrans(rootTrans, "lock")
        itemCache.mask   = CS.FindTrans(rootTrans, "mask")
        itemCache.empty  = CS.FindTrans(rootTrans, "empty")
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
    CS.ShowObject(itemCache.empty, refId ~= nil)

    local select = not not param.select
    local mask = not not param.mask
    local lock = not not param.lock
    CS.ShowObject(itemCache.select, select)
    CS.ShowObject(itemCache.mask, mask or select)
    CS.ShowObject(itemCache.lock, lock)

    self:SetWndClick(rootTrans, function()
		self:OnCickResolveItem(refId, param.num)
	end)
end

function UISubPeResolve:RefreshResolveList()
	local dataList = gModelItem:GetItemListByItemType(gModelItem.TTEM_TYPE_PET, true)
	if self.mToggleGou.gameObject.activeSelf then
		local itemList = {}
		for _, value in ipairs(dataList or {}) do
			if self:isFullStarByItemId(value:GetRefId()) then--满星筛选
				table.insert(itemList,value)
			end
		end
		dataList = itemList
	end
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
	self:RefreshResolveToRwd()
	CS.ShowObject(self.mNoRecord, #dataList == 0)
end
------------------------------------------------------------------
return UISubPeResolve