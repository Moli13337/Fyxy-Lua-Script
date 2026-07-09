---
--- Created by Administrator.
--- DateTime: 2024/4/2 15:06:44
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubEqSynthesis:LChildWnd
local UISubEqSynthesis = LxWndClass("UISubEqSynthesis", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubEqSynthesis:UISubEqSynthesis()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubEqSynthesis:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubEqSynthesis:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubEqSynthesis:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitText()
	self:InitShowItemList()
	self:UpdateRedPoint()
end

function UISubEqSynthesis:SetInputText(num)
	if not gModelEquip:GetEquipRefByRefId(self.curSelectEquipId).compound then
		self:SetWndText(self.mText2, 1)
		return
	end
	self.curNum = math.max(1, math.min(num, self.maxCompNum))
	self:SetWndText(self.mText2, self.curNum)
	local haveMoney = gModelItem:GetNumByRefId(self.costItem)
	local color = haveMoney > self.needMoney * self.curNum and "<#D2EFFF>" or "<#c81313>"
	local payMoney = LUtil.NumberCoversion(self.needMoney * self.curNum)
	self:SetWndText(self.mMoneyText, color .. payMoney .. "</color>")
end

function UISubEqSynthesis:OnDrawNeedItemCell(list, item, itemdata, itempos)
	local IconTrans = self:FindWndTrans(item, "Icon")
	local NumTrans = self:FindWndTrans(item, "Num")
	local AddBtnTrans = self:FindWndTrans(item, "BtnDiv/AddBtn")
	local refId = itemdata.itemId
	if IconTrans then
		local icon = gModelItem:GetItemIconByRefId(refId)
		self:SetWndEasyImage(IconTrans, icon)
	end
	if NumTrans then
		local haveNum = gModelItem:GetNumByRefId(refId)
		haveNum = LUtil.NumberCoversion(haveNum)
		self:SetWndText(NumTrans, haveNum)
	end
	if AddBtnTrans then
		self:SetWndClick(AddBtnTrans, function()
			self:AddItemEvent(refId)
		end)
	end
end

function UISubEqSynthesis:ClickNumBg()
	if self.curSelectEquipId == 0 then
		return
	end
	local func = function(input)
		if self:IsWndClosed() then
			return
		end
		self:SetWndText(self.mText2, input)
	end

	local closeFunc = function(input)
		if self:IsWndClosed() then
			return
		end
		self:SetInputText(input)
	end

	local para = {
		minNum = 1,
		maxNum = 999999,
		defaultNum = 0,
		inputFunc = func,
		inputTran = self.mNumBg,
		closeFunc = closeFunc
	}

	GF.OpenWnd("UINuoardUI", para)
end

function UISubEqSynthesis:InitText()
	for i = 1, 4 do
		local typeName =gModelEquip:GetEquipPartRefByPart(i).typeName
		self:SetWndTabText(self["mDownBtnObj" .. i], ccLngText(typeName))
	end
	self:SetWndText(self.mText2, 1)
	self:SetWndText(self:FindWndTrans(self.mSynBtn, "synBtnText"), ccClientText(11316))
	self:SetWndText(self:FindWndTrans(self.mOneSynBtn, "oneSynBtnText"), ccClientText(11315))
	self:SetWndText(self.mEmptyText, ccClientText(11341))
end

function UISubEqSynthesis:ClickOneSynBtn()
	local list = gModelEquip:GetCanCompoundEquipList4(self.curSelPart, {true, true, true, true, true})
	local isHave = false
	for _, v in pairs(list) do
		if v.num ~= 0 then
			isHave = true
			break
		end
	end
	if not isHave then
		GF.ShowMessage(ccClientText(11335))
		return
	end
	GF.OpenWnd("UIEqAutoComp", { EquipType = self.curSelPart })
end

function UISubEqSynthesis:InitData()
	self.curNum = 1
	self.curSelectEquipId = 0
	self.curSelPart = 1
	self.commonUIList = {}
	self.CurSelBtn = 1
	self.leftCommonIcon, self.rightCommonIcon = nil, nil
	self.leftEquipTex = self:FindWndTrans(self.mEquipObj1, "text")
	self:ClickDownBtn(self.CurSelBtn)
end

function UISubEqSynthesis:SetScrollView(part)
	self.curSelPart = part
	local equipList = self:GetEquipListByPart(part)
	table.sort(equipList, function(a, b)
		return a:GetScore() > b:GetScore()
	end)
	CS.ShowObject(self.mNoRecord2, #equipList == 0)
	CS.ShowObject(self.mEquipList, #equipList ~= 0)
	if self.equipList == nil then
		self.equipList = self:GetUIScroll("mEquipList")
		self.equipList:Create(self.mEquipList, equipList, function(...) self:OnDrawItem(...) end, UIItemList.SUPER_GRID)
		self:ClickItemMask(equipList[#equipList])
	else
		self.equipList:RefreshList(equipList)
	end
end

function UISubEqSynthesis:OnDrawItem(list, item, itemData, itemPos)
	local anitRoot = self:FindWndTrans(item, "AniRoot")
	local iconObj = self:FindWndTrans(anitRoot, "iconObj")
	local redPoint = self:FindWndTrans(anitRoot, "redPoint")
	local numText = self:FindWndTrans(anitRoot, "NumText")
	local itemStruct = gModelEquip:GetEquipStructByRefId(itemData:GetRefId())
	self:SetWndText(numText, itemStruct:GetNum())
	local instanceId = item:GetInstanceID()
	self:SetWndClick(iconObj, function() self:ClickItemMask(itemData) end)
	if not self.commonUIList[instanceId] then
		self.commonUIList[instanceId] = CommonIcon:New()
		self.commonUIList[instanceId]:Create(iconObj)
	end
	self.commonUIList[instanceId]:SetEquipIcon(itemData:GetRefId())
	self.commonUIList[instanceId]:DoApply()
	self.commonUIList[instanceId]:ShowGouImg(itemData:GetRefId() == self.curSelectEquipId)



	local maxCompNum = gModelEquip:CheckEquipCanCompound(itemData).maxCompNum
	CS.ShowObject(redPoint, maxCompNum > 0)
end

function UISubEqSynthesis:GetEquipListByPart(part)
	local list = {}
	for _, v in pairs(GameTable.RoleEquipRef) do
		if v.type == part and v.compound and v.compound ~= "" and v.composeOrder > 0 then
			table.insert(list, gModelEquip:GetEquipStructByRefId(v.refId))
		end
	end
	return list
end

function UISubEqSynthesis:ClickNumBtn(isAdd)
	if self.curSelectEquipId == 0 then
		return
	end
	local add = isAdd and 1 or -1
	self:SetInputText(self.curNum + add)
end

function UISubEqSynthesis:ClickSysBtn()
	if self.curSelectEquipId == 0 then
		GF.ShowMessage(ccClientText(11340))
		return
	end
	local compound = gModelEquip:GetEquipRefByRefId(self.curSelectEquipId).compound
	if not compound and compound == "" then
		GF.ShowMessage(ccClientText(11343))
		return
	end
	if self.curNum > math.floor(self.needEquip:GetNum() / self.comConst) then
		GF.ShowMessage(ccClientText(11335))
		return
	end
	if self.needMoney and self.costItem then
		if gModelItem:GetNumByRefId(self.costItem) < self.needMoney * self.curNum then
			GF.ShowMessage(ccClientText(11335))
			gModelGeneral:OpenGetWayWnd({ itemId = self.costItem, srcWnd = self:GetWndName() })
			return
		end
	end
	local rewardEquips = {}
	rewardEquips[self.curSelectEquipId] = self.curNum
	gModelEquip:OnEquipCompoundReq(rewardEquips, rewardEquips, 0)
end

function UISubEqSynthesis:ClickItemMask(data)
	local item = self.curSelectEquipId ~= data:GetRefId() and data or nil
	self.curSelectEquipId = self.curSelectEquipId == data:GetRefId() and 0 or data:GetRefId()
	self.equipList:DrawAllItems()
	self:SetSelectEquipData(item)
end

function UISubEqSynthesis:SetSelectEquipData(item)
	if not self.leftCommonIcon then
		self.leftCommonIcon = CommonIcon:New()
		self.leftCommonIcon:Create(self.mEquipObj1)
	end
	if not self.rightCommonIcon then
		self.rightCommonIcon = CommonIcon:New()
		self.rightCommonIcon:Create(self.mEquipObj2)
	end
	self.comConst = 0
	if item then
		local compInfo = gModelEquip:CheckEquipCanCompound(item)
		self.maxCompNum = compInfo.maxCompNum
		self.comConst = compInfo.comConst
		self.needMoney = compInfo.needMoney
		self.costItem = compInfo.costItem
		self.needEquip = compInfo.needEquip ~= 0 and gModelEquip:GetEquipStructByRefId(compInfo.needEquip) or item
		local color = self.needEquip:GetNum() < self.comConst and "<#c81313>" or "<#68e6ac>"
		self.leftCommonIcon:SetEquipIcon(self.needEquip:GetRefId() ~= 0 and self.needEquip:GetRefId() or item:GetRefId())
		self.rightCommonIcon:SetEquipIcon(item:GetRefId())
		CS.ShowObject(self.leftEquipTex, true)
		self:SetWndText(self.leftEquipTex, color .. self.needEquip:GetNum() .. "</color>/" .. self.comConst)

		self:SetInputText(self.maxCompNum)
		if self.costItem ~= 0 then
			CS.ShowObject(self.mMoneyObj, true)
			local icon = gModelItem:GetItemImgByRefId(self.costItem)
			self:SetWndEasyImage(self.mMoneyIcon, icon)
		else
			CS.ShowObject(self.mMoneyObj, false)
		end
	else
		self.leftCommonIcon:SetEquipIcon(nil)
		self.rightCommonIcon:SetEquipIcon(nil)
		CS.ShowObject(self.leftEquipTex, false)
		CS.ShowObject(self.mMoneyObj, false)
	end
	self.leftCommonIcon:DoApply()
	self.rightCommonIcon:DoApply()
end

function UISubEqSynthesis:InitEvent()
	self:SetWndClick(self.mAddBtn, function() self:ClickNumBtn(true) end)
	self:SetWndClick(self.mSubBtn, function() self:ClickNumBtn(false) end)
	for i = 1, 4 do
		self:SetWndClick(self["mDownBtnObj" .. i], function() self:ClickDownBtn(i) end)
	end
	self:SetWndClick(self.mSynBtn, function() self:ClickSysBtn() end)
	self:SetWndClick(self.mOneSynBtn, function() self:ClickOneSynBtn() end)
	self:SetWndClick(self.mNumBg, function() self:ClickNumBg() end)
	self:SetWndClick(self.mEquipObj1, function()
		if self.curSelectEquipId ~= 0 then
			gModelGeneral:OpenEquipInfoTip(self.needEquip:GetRefId(), nil, nil, true)
		end
	end)
	self:SetWndClick(self.mEquipObj2, function()
		if self.curSelectEquipId ~= 0 then
			gModelGeneral:OpenEquipInfoTip(self.curSelectEquipId, nil, nil, true)
		end
	end)

	self:WndNetMsgRecv(LProtoIds.EquipCompoundResp, function()
		self.curSelectEquipId = 0
		self:ClickDownBtn(self.CurSelBtn)
		self:SetSelectEquipData()
		self:UpdateRedPoint()
	end)
	self:WndEventRecv(EventNames.On_Item_Change, function()
		self:InitShowItemList()
		self:UpdateRedPoint()
	end)
end

function UISubEqSynthesis:InitShowItemList()
	local list = { { itemType = 1, itemId = 101001 } }
	local uiNeedList = self._uiNeedList
	if uiNeedList then
		uiNeedList:RefreshData(list)
	else
		uiNeedList = self:GetUIScroll("uiNeedList")
		self._uiNeedList = uiNeedList
		uiNeedList:Create(self.mNeedItemList, list, function(...) self:OnDrawNeedItemCell(...) end)
	end
end

function UISubEqSynthesis:UpdateRedPoint()
	for i = 1, 4 do
		local state = gModelEquip:GetEquipCompoundRedPointByPart(i)
		CS.ShowObject(self:FindWndTrans(self["mDownBtnObj" .. i], "redPoint"), state)
	end
end

function UISubEqSynthesis:AddItemEvent(refId)
	gModelGeneral:OpenGetWayWnd({ itemId = refId, srcWnd = self:GetWndName() })
end

function UISubEqSynthesis:ClickDownBtn(index)
	self.CurSelBtn = index
	for i = 1, 4 do
		CS.ShowObject(self:FindWndTrans(self["mDownBtnObj" .. i], "On"), i == index)
	end
	self:SetScrollView(index)
	self.equipList:DrawAllItems()
end


------------------------------------------------------------------
return UISubEqSynthesis