---
--- Created by Administrator.
--- DateTime: 2025/6/5 11:45:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandStrengthenSel:LWnd
local UIBrandStrengthenSel = LxWndClass("UIBrandStrengthenSel", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandStrengthenSel:UIBrandStrengthenSel()
	self.selList = {}
	self.selListNum = 0
	self.ownNum = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandStrengthenSel:OnWndClose()
	self:FuncCallBack()
	LWnd.OnWndClose(self)

end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandStrengthenSel:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandStrengthenSel:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitCommnoList()
end

function UIBrandStrengthenSel:InitCommnoList(isRefresh)
	local uiList = self._uiAllList
	local color =self.selListNum>=self.needNum and "#0f6f23" or "#b20000"
	self:SetWndText(self.mTxtCost,string.replace(ccClientText(47557),color,self.selListNum,self.needNum))
	if not uiList then
		uiList = self:GetUIScroll("BadgeAllList")
		self._uiAllList = uiList
		uiList:Create(self.mCommonList, self.list, function(...)
			self:OnDrawAllItemCell(...)
		end, UIItemList.SUPER_GRID, false)
		local superList = uiList:GetList()
		superList:EnableLoadAnimation(true)
		superList:SetLoadAnimationScale(0.2, 0.15)
		superList:RefreshList(isRefresh)
	else
		uiList:RefreshList(self.list)

		local superList = uiList:GetList()
		if isRefresh then
			superList:DrawAllItems(false)
		else
			-- superList:MoveToPos(1, 0)
			superList:DrawAllItems(true)
		end
	end
end

function UIBrandStrengthenSel:InitEmptyList(isShow)
	CS.ShowObject(self.mEmptyTips,isShow)
	local emptyId = 50000
	local data = {
		refId = emptyId,
		IntroTran = self.mEmptyText,
		IconTran = self.mEmptyIcon,
		TextBgTran = self.mEmptyTextBg,
		GetBtn = self.mGetBtn,
		GetBtnText = self.mGetBtnTxt,
		ButtonRoot = self.mGetBtn,
		-- para = { xxx },
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)

	CS.ShowObject(self.mGetBtn, true)
end

function UIBrandStrengthenSel:InitData()
	local baseItem = self:GetWndArg("baseItem") or {}
	self.baseItem = baseItem

	local recordBaseItemMap = {}
	for i,v in ipairs(baseItem) do
		recordBaseItemMap[v.itemId] = v.itemNum
	end

	self.quality = self:GetWndArg("quality")
	self.needNum = self:GetWndArg("itemNum")
	local selList = self:GetWndArg("selList")
	self.callBack = self:GetWndArg("funcCall")
	local itemList = gModelBadge:GetBadgeItemByQuality(self.quality)
	local lists = {}
	local num
	local baseUseNum
	for _, item in ipairs(itemList) do
		num = checknumber(item.num)
		baseUseNum = recordBaseItemMap[item.refId]
		if baseUseNum and baseUseNum > 0 then
			num = num - baseUseNum
		end
		if num > 0 then
			for i = 1, num do
				table.insert(lists,{refId = item.refId,itype = item.itype,num = 1})
			end
		end
	end
	self.list = lists
	self.ownNum = #lists
	if selList then
		self.selList = selList.selList
		self.selListNum = selList.selListNum
		--校验数据是否还在？
		----
	end
	self:InitEmptyList(self.ownNum<=0)
	self:SetWndText(self.mTxtTitle,ccClientText(47556))
	self:SetWndButtonText(self.mBtnOk,ccClientText(24702))
	self:SetWndButtonText(self.mBtnOneKey,ccClientText(43744))
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnOk,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnOneKey,function()
		if self.selListNum<self.needNum then
			for index, item in ipairs(self.list) do
				if not self.selList[index] then
					self.selList[index] = item.refId
					self.selListNum = math.min(self.selListNum+1,self.needNum)
				end
				if self.selListNum>=self.needNum then break end
			end
			self:InitCommnoList()
		end
	end)
end

function UIBrandStrengthenSel:FuncCallBack()
	if self.callBack then
		self.callBack(self.selList,self.selListNum,self.ownNum)
	end
end

function UIBrandStrengthenSel:OnDrawAllItemCell(list, item, itemdata, itempos, fromHeadTail)
	local aniNode = CS.FindTrans(item, "AniRoot")
	item = aniNode
	local uiIconRoot = CS.FindTrans(item, "IconRoot")
	local refId = itemdata.refId
	-- local itype = LItemTypeConst.TYPE_BADGE
	local TypeImg = CS.FindTrans(item, "TypeImg")
	local instanceID = item:GetInstanceID()
	local baseClass, isNew = self:GetCommonIcon(instanceID)
	if isNew then
		baseClass:Create(self:FindWndTrans(uiIconRoot, "Icon"))
	end
	baseClass:EnableShowNum(false)
	baseClass:SetCommonReward(itemdata.itype, refId, itemdata.num)
	baseClass:RefreshActiveShow()
	local isSel = self.selList[itempos] and self.selList[itempos] == itemdata.refId
	baseClass:ShowGouImg(isSel)
	self:SetWndClick(uiIconRoot, function()
		if self.selList[itempos] then
			self.selList[itempos] = nil
			self.selListNum = math.max(self.selListNum-1,0)
		else
			if self.selListNum>= self.needNum then return end
			self.selList[itempos] = itemdata.refId
			self.selListNum = math.min(self.selListNum+1,self.needNum)
		end
		self:InitCommnoList()
	end)
	self:SetWndLongClick(uiIconRoot,function ()
		-- GF.OpenWnd("UIBrandTips",{refId = itemdata.refId})
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
	baseClass:DoApply()
	CS.ShowObject(TypeImg,false)
	local itemNameTrans = CS.FindTrans(item, "ItemName")
	if itemNameTrans then
		local ref = GameTable.PlayerItemRef[itemdata.refId]
		local name = ccLngText(ref.name)
		self:SetWndText(itemNameTrans, name)
	end

end
------------------------------------------------------------------
return UIBrandStrengthenSel