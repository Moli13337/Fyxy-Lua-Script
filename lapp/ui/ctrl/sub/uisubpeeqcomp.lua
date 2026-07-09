---
--- Created by Administrator.
--- DateTime: 2024/6/14 11:36:07
---
------------------------------------------------------------------
local StructPet = LXImport("LApp.Models.Struct.StructPet")
local LChildWnd = LChildWnd
---@class UISubPeEqComp:LChildWnd
local UISubPeEqComp = LxWndClass("UISubPeEqComp", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPeEqComp:UISubPeEqComp()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPeEqComp:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPeEqComp:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPeEqComp:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitText()
	self:InitShowItemList()
	self:UpdateRedPoint()
end

function UISubPeEqComp:InitText()
	for i = 1, 4 do
		local btnStr =ccLngText(gModelPet:GetPetEquipPartRef(i).name)
		self:SetWndTabText(self["mDownBtnObj" .. i], btnStr)
	end
	self:SetWndText(self.mText2, 1)
	self:SetWndText(self:FindWndTrans(self.mSynBtn, "synBtnText"), ccClientText(11316))
	self:SetWndText(self:FindWndTrans(self.mOneSynBtn, "oneSynBtnText"), ccClientText(11315))
	self:SetWndText(self.mEmptyText, ccClientText(11341))
end

function UISubPeEqComp:InitData()
	self.curNum = 1
	self.curSelectEquipId = 0
	self.curSelPart = 1
	self.commonUIList = {}
	self.CurSelBtn = 1
	self.leftCommonIcon, self.rightCommonIcon = nil, nil
	self.leftEquipTex = self:FindWndTrans(self.mEquipObj1, "text")
	self:ClickDownBtn(self.CurSelBtn)
end

function UISubPeEqComp:InitEvent()
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
			gModelGeneral:OpenEquipInfoTip(self.needEquip:GetRefId(), nil, nil, true,nil,nil,nil,LItemTypeConst.TYPE_PET_EQUIP)
		end
	end)
	self:SetWndClick(self.mEquipObj2, function()
		if self.curSelectEquipId ~= 0 then
			gModelGeneral:OpenEquipInfoTip(self.curSelectEquipId, nil, nil, true,nil,nil,nil,LItemTypeConst.TYPE_PET_EQUIP)
		end
	end)

	self:WndNetMsgRecv(LProtoIds.PetEquipCompoundResp, function()
		self.curSelectEquipId = 0
		self:ClickDownBtn(self.CurSelBtn)
		self:SetSelectEquipData()
		self:UpdateRedPoint()
	end)
	self:WndEventRecv(EventNames.PET_EQUIP_CHANGE, function()
		self:InitShowItemList()
		self:UpdateRedPoint()
	end)
end

function UISubPeEqComp:UpdateRedPoint()
	for i = 1, 4 do
		local state = gModelPet:GetEquipCompoundRedPointByPart(i)
		CS.ShowObject(self:FindWndTrans(self["mDownBtnObj" .. i], "redPoint"), state)
	end
end

function UISubPeEqComp:ClickNumBg()
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

function UISubPeEqComp:ClickItemMask(data)
	local item = self.curSelectEquipId ~= data._refId and data or nil
	self.curSelectEquipId = self.curSelectEquipId == data._refId and 0 or data._refId
	self.equipList:DrawAllItems()
	self:SetSelectEquipData(item)
end

function UISubPeEqComp:InitShowItemList()
	-- local list = { { itemType = 1, itemId = 101001 } }
	-- local uiNeedList = self._uiNeedList
	-- if uiNeedList then
	-- 	uiNeedList:RefreshData(list)
	-- else
	-- 	uiNeedList = self:GetUIScroll("uiNeedList")
	-- 	self._uiNeedList = uiNeedList
	-- 	uiNeedList:Create(self.mNeedItemList, list, function(...) self:OnDrawNeedItemCell(...) end)
	-- end
	self:SetScrollView(self.curSelPart)
end

function UISubPeEqComp:ClickDownBtn(index)
	self.CurSelBtn = index
	for i = 1, 4 do
		CS.ShowObject(self:FindWndTrans(self["mDownBtnObj" .. i], "On"), i == index)
	end
	self:SetScrollView(index)
	self.equipList:DrawAllItems()
end

function UISubPeEqComp:ClickNumBtn(isAdd)
	if self.curSelectEquipId == 0 then
		return
	end
	local add = isAdd and 1 or -1
	self:SetInputText(self.curNum + add)
end

function UISubPeEqComp:ClickSysBtn()
	if self.curSelectEquipId == 0 then
		GF.ShowMessage(ccClientText(11343))
		return
	end
	local compound = gModelPet:GetPetEquipRef(self.curSelectEquipId).compound
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
	local needList = {}
	needList[self.needEquip._refId] = self.comConst*self.curNum
	gModelPet:OnPetEquipCompoundReq(needList, rewardEquips, 0)
end

function UISubPeEqComp:OnDrawItem(list, item, itemData, itemPos)
	local anitRoot = self:FindWndTrans(item, "AniRoot")
	local iconObj = self:FindWndTrans(anitRoot, "iconObj")
	local redPoint = self:FindWndTrans(anitRoot, "redPoint")
	local numText = self:FindWndTrans(anitRoot, "NumTxt")
	self:SetWndText(numText, itemData:GetNum())

	local instanceId = item:GetInstanceID()
	self:SetWndClick(iconObj, function() self:ClickItemMask(itemData) end)
	if not self.commonUIList[instanceId] then
		self.commonUIList[instanceId] = CommonIcon:New()
		self.commonUIList[instanceId]:Create(iconObj)
	end
	self.commonUIList[instanceId]:SetPetEquipIcon(itemData._refId)
	self.commonUIList[instanceId]:DoApply()
	self.commonUIList[instanceId]:ShowGouImg(itemData._refId== self.curSelectEquipId)

	local maxCompNum = gModelPet:CheckEquipCanCompound(itemData:GetRefId()).maxCompNum
	CS.ShowObject(redPoint, maxCompNum>0)
end

function UISubPeEqComp:SetSelectEquipData(itemData)
	if not self.leftCommonIcon then
		self.leftCommonIcon = CommonIcon:New()
		self.leftCommonIcon:Create(self.mEquipObj1)
	end
	if not self.rightCommonIcon then
		self.rightCommonIcon = CommonIcon:New()
		self.rightCommonIcon:Create(self.mEquipObj2)
	end
	self.comConst = 0
	if itemData then
		local compInfo = gModelPet:CheckEquipCanCompound(itemData:GetRefId())
		self.maxCompNum = compInfo.maxCompNum
		self.comConst = compInfo.comConst	--需要裝備數量
		self.needMoney = compInfo.needMoney--需要貨幣
		self.costItem = compInfo.costItem--貨幣id
		self.needEquip = compInfo.needEquip ~= 0 and gModelPet:GetPetEquipByRefId(compInfo.needEquip) or StructPetEquip.NewStructPetEquip(compInfo.needEquip)--消耗裝備
		local color = self.needEquip._num< self.comConst and "<#c81313>" or "<#68e6ac>"
		self.leftCommonIcon:SetPetEquipIcon(self.needEquip:GetRefId() ~= 0 and self.needEquip:GetRefId() or itemData:GetRefId())
		self.rightCommonIcon:SetPetEquipIcon(itemData:GetRefId())
		CS.ShowObject(self.leftEquipTex, true)
		self:SetWndText(self.leftEquipTex, color .. self.needEquip:GetNum() .. "</color>/" .. self.comConst)

		self:SetInputText(self.maxCompNum)
		if self.costItem and self.costItem ~= 0 then
			CS.ShowObject(self.mMoneyObj, true)
			local icon = gModelItem:GetItemImgByRefId(self.costItem)
			self:SetWndEasyImage(self.mMoneyIcon, icon)
		else
			CS.ShowObject(self.mMoneyObj, false)
		end
	else
		self.leftCommonIcon:SetPetEquipIcon(nil)
		self.rightCommonIcon:SetPetEquipIcon(nil)
		CS.ShowObject(self.leftEquipTex, false)
		CS.ShowObject(self.mMoneyObj, false)
	end
	self.leftCommonIcon:DoApply()
	self.rightCommonIcon:DoApply()
end



function UISubPeEqComp:SetScrollView(part)
	self.curSelPart = part
	local equipList = gModelPet:GetPetEquipListByPart(part)
	table.sort(equipList, function(a, b)
		return a._equipRef.composeOrder < b._equipRef.composeOrder
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

function UISubPeEqComp:SetInputText(num)
	if not gModelPet:GetPetEquipRef(self.curSelectEquipId).compound then
		self:SetWndText(self.mText2, 1)
		return
	end
	self.curNum = math.max(1, math.min(num, self.maxCompNum))
	self:SetWndText(self.mText2, self.curNum)
	local haveMoney = self.costItem and gModelItem:GetNumByRefId(self.costItem) or 0
	local color = haveMoney > self.needMoney * self.curNum and "<#D2EFFF>" or "<#c81313>"
	local payMoney = LUtil.NumberCoversion(self.needMoney * self.curNum)
	self:SetWndText(self.mMoneyText, color .. payMoney .. "</color>")
end

function UISubPeEqComp:ClickOneSynBtn()
	local list,needList,has = gModelPet:CheckOneKeyAllCompund(self.curSelPart)
	if not has then
		GF.ShowMessage(ccClientText(11335))
		return
	end
	GF.OpenWnd("UIPeEqAutoComp", { part = self.curSelPart ,list = list,needList = needList})
end


------------------------------------------------------------------
return UISubPeEqComp