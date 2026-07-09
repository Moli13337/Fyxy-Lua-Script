---
--- Created by Administrator.
--- DateTime: 2025/6/10 15:02:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBrandPrepareSel:LWnd
local UIBrandPrepareSel = LxWndClass("UIBrandPrepareSel", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBrandPrepareSel:UIBrandPrepareSel()
	self.selList = {}
	self.selListNum = 0
	self.needNum = GameTable.BadgeConfigRef.badgeRandomNum
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBrandPrepareSel:OnWndClose()
	if self.callBack then
		self.callBack(self.sList)
		self.callBack = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBrandPrepareSel:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBrandPrepareSel:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:_InitEventClick()
	self:InitData()
	self:InitSelReward()
	self:InitCommnoList()
end
function UIBrandPrepareSel:InitCommnoList(isRefresh)
	local uiList = self._uiAllList
	if not uiList then
		uiList = self:GetUIScroll("AllSelRwdList")
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
			superList:MoveToPos(1, 0)
			superList:DrawAllItems(true)
		end
	end
end

function UIBrandPrepareSel:OnDrawAllItemCell(list, item, itemdata, itempos, fromHeadTail)
	local aniNode = CS.FindTrans(item, "AniRoot")
	item = aniNode
	local uiIconRoot = CS.FindTrans(item, "IconRoot")
	-- local itemNameTrans = CS.FindTrans(item, "ItemName")
	local TypeImg = CS.FindTrans(item, "TypeImg")
	-- local itype = LItemTypeConst.TYPE_BADGE
	local instanceID = item:GetInstanceID()
	local baseClass, isNew = self:GetCommonIcon(instanceID)
	if isNew then
		baseClass:Create(self:FindWndTrans(uiIconRoot, "Icon"))
	end
	local refId = itemdata.ref.refId
	local ref = GameTable.BadgeLuckRef[refId]
	local reward = LxDataHelper.ParseItem_4(ref.reward)
	baseClass:EnableShowNum(false)
	-- baseClass:SetCommonReward(itype, refId)
	baseClass:SetCommonItemdata(reward)
	baseClass:RefreshActiveShow()
	local isSel = self.selList[refId] and self.selList[refId] == refId
	baseClass:ShowGouImg(isSel)
	self:SetWndClick(uiIconRoot, function()
		if self.selList[refId] then
			self.selList[refId] = nil
			self.selListNum = math.max(self.selListNum-1,0)
			for indx, value in ipairs(self.sList) do
				if value == refId then table.remove(self.sList,indx) end
			end
		else
			if self.selListNum>= self.needNum then return end
			self.selList[refId] = refId
			self.selListNum = math.min(self.selListNum+1,self.needNum)
			table.insert(self.sList,refId)
		end
		self:InitCommnoList()
		self:InitSelReward()
	end)
	self:SetWndLongClick(uiIconRoot,function ()
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end)
	baseClass:DoApply()
	CS.ShowObject(TypeImg,false)
	-- if itemNameTrans then
	-- 	local ref = GameTable.BadgeRef[itemdata.refId]
	--     local name = ccLngText(ref.name)
	--     self:SetWndText(itemNameTrans, name)
	-- end

end
function UIBrandPrepareSel:InitSelReward()
	local itemList = {}
	local randomNum = GameTable.BadgeConfigRef.badgeRandomNum
	local curNum = self.selListNum
	for _, value in pairs(self.sList) do
		table.insert(itemList,{refId = value})
	end
	for i = curNum+1, randomNum do
		table.insert(itemList,{})
	end
	local uiList = self:FindUIScroll("selRwdList")
	if uiList then
		uiList:RefreshList(itemList)
	else
		uiList = self:GetUIScroll("selRwdList")
		uiList:Create(self.mSelRwdList, itemList, function(...)
			self:RewardListItem(...)
		end)
		uiList:EnableScroll(true, true)
	end
end
function UIBrandPrepareSel:_InitEventClick()
	-- self:SetWndClick(self.mMask,function()
	-- 	self:WndClose()
	-- end)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnOk,function()
		if self.selListNum< GameTable.BadgeConfigRef.badgeRandomNum then
			GF.ShowMessage(string.replace(ccClientText(47571),GameTable.BadgeConfigRef.badgeRandomNum))
			return
		end
		self:WndClose()

	end)
end

function UIBrandPrepareSel:RewardListItem(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item, "Icon")
	local Empty = self:FindWndTrans(Icon, "Empty")
	local instanceId = Icon:GetInstanceID()
	CS.ShowObject(Empty,not itemdata.refId )
	local reward
	if itemdata.refId then
		local baseClass = self:GetCommonIcon(instanceId)
		-- local itype = LItemTypeConst.TYPE_BADGE
		local ref = GameTable.BadgeLuckRef[itemdata.refId]
		reward = LxDataHelper.ParseItem_4(ref.reward)
		baseClass:Create(Icon)
		-- baseClass:SetCommonReward(itype, itemdata.refId)
		baseClass:SetCommonItemdata(reward)
		baseClass:DoApply()
		-- local ref = GameTable.BadgeRef[itemdata.refId]
		-- self:SetTextTile(item,ccLngText(ref.name))
	else
		self:DeleteCommonIcon(instanceId)
		-- self:SetTextTile(item,ccClientText(47542))
	end
	self:SetWndClick(Icon,function()
		if not itemdata.refId then  return end
		gModelGeneral:ShowCommonItemTipWnd(reward)
	end)
end
function UIBrandPrepareSel:InitData()
	self.callBack = self:GetWndArg("func")
	self.list = self:GetWndArg("rwdList")
	local selList = self:GetWndArg("selList") or {}
	self.sList = {}
	self.selListNum = 0
	for index, value in ipairs(selList) do
		if value.refId then
			self.selListNum = index
			self.selList[value.refId] = value.refId
			table.insert(self.sList,value.refId)
		end
	end

	self:SetWndText(self.mTxtAttrTitle,ccClientText(47567))
	self:SetWndText(self.mTxtTitle,ccClientText(47543))
	self:SetWndButtonText(self.mBtnOk,ccClientText(47527))
	CS.ShowObject(self.mCloseBtn,true)
end
------------------------------------------------------------------
return UIBrandPrepareSel