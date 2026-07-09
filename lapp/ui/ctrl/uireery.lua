---
--- Created by Administrator.
--- DateTime: 2023/10/21 15:41:17
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReery:LWnd
local UIReery = LxWndClass("UIReery", LWnd)
UIReery.RECOVERY_ARTIFACT = 2

-- 【G公共支持】删除神器功能相关数据
-- UIReery.ARTIFACTUPLV = 210001
-- UIReery.ARTIFACTSTRENGTH = 210002
-- UIReery.ARTIFACTENABLING = 210003

-- UIReery.ArtifactItemList = {
-- 	[UIReery.ARTIFACTUPLV] = "Lv:%s",
-- 	[UIReery.ARTIFACTSTRENGTH] = "Lv:%s",
-- 	[UIReery.ARTIFACTENABLING] = "%s",
-- }
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReery:UIReery()
	---@type table<number,CommonIcon>
	self._uiCommonList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReery:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil

	if self._func then self._func() end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIReery:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReery:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitEmptyList()
	self:InitData()
	self:SetWndText(self.mTitle,self._title)
	self:SetWndButtonText(self.mRecoveryBtn,ccClientText(18361))
	self:SetDesc()
	self:InitRecoveryItemList()
end

function UIReery:InitRecoveryList()
	local list = self:GetRecoveryData()
	local uiList = self._uiItemRecoveryList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("_uiItemRecoveryList")
		self._uiItemRecoveryList = uiList
		uiList:Create(self.mRecoveryList,list,function(...) self:OnDrawItemRecoveryCell(...) end)
	end
	self:SetWndText(self.mRecoveryDesc,ccClientText(18360))
end

function UIReery:RecoveryHero()
	return true
end

function UIReery:GetRecoveryType()
	local recoveryType = self._recoveryType or self._changeTypeList[1]
	local commonType = self:RecoveryTypeChangeCommonType(recoveryType)
	return commonType
end

function UIReery:RecoveryDreamLand()
	local status = self._materialItem ~= nil
	-- 【G公共支持】删除神器功能相关数据
	-- if status then
	-- 	gModelDream:OnDreamLandRecoveryReq(self._materialItem)
	-- end
	return status
end

function UIReery:InitMsg()
	self:WndNetMsgRecv(LProtoIds.EquipDecomposeResp, function()
		self:WndClose()
	end)
	self:WndNetMsgRecv(LProtoIds.SellGoodsResp, function()
		self:WndClose()
	end)
	self:WndNetMsgRecv(LProtoIds.DreamLandRecoveryResp, function()
		self:WndClose()
	end)

end

function UIReery:IsEmptyList()
	return self._recoveryList and #self._recoveryList <= 0 or false
end

function UIReery:RecoveryRune()
	return true
end

function UIReery:RecoveryTypeChangeCommonType(recoveryType)
	return self._changeTypeList[recoveryType]
end

function UIReery:RecoveryOutfit()
	return true
end

function UIReery:RecoveryEquip()
	gModelEquip:OnEquipDecomposeReq()
	return true
end

function UIReery:InitEvent()
	self:SetWndClick(self.mBg,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mRecoveryBtn,function()
		self:RecoveryEvent()
	end)
end

function UIReery:OnDrawRecoveryCell(list,item,itemdata,itempos)
	local CommonUITrans = self:FindWndTrans(item,"CommonUI")
	if CommonUITrans then
		local itype,refId,num = itemdata.itemType,itemdata.itemId,itemdata.itemNum
		-- local isArtifactItem = UIReery.ArtifactItemList[refId]【G公共支持】删除神器功能相关数据
		local uiCommonList = self._uiCommonList
		local InstanceID = item:GetInstanceID()
		local baseClass = uiCommonList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New()
			uiCommonList[InstanceID] = baseClass
			baseClass:Create(CS.FindTrans(CommonUITrans,"Icon"))
		end
		baseClass:SetCommonReward(itype, refId, -1)
		baseClass:EnableShowNum(false)
		self:SetWndClick(CommonUITrans,function()
			printInfoNR("=== itemdata = " .. itemdata.itemId)
			-- 【G公共支持】删除神器功能相关数据
			-- if isArtifactItem then
			-- else
				gModelGeneral:ShowCommonItemTipWnd(itemdata)
			-- end
		end)
		baseClass:DoApply()

		local uiNumTrans = self:FindWndTrans(CommonUITrans,"UINum")
		if uiNumTrans then
			local str = UIReery.ArtifactItemList[refId]
			if str then
				str = string.replace(str,num)
			else
				str = LUtil.NumberCoversion(num)
			end
			self:SetWndText(uiNumTrans,str)
		end

		local uiNameTrans = self:FindWndTrans(CommonUITrans,"UIName")
		if uiNameTrans then
			self:SetWndText(uiNameTrans,baseClass:GetName() or "")
		end
	end
end

function UIReery:InitRecoveryItemList()
	local list = self:GetRecoveryList()
	local showRedPoint = #list > 0
	CS.ShowObject(self.mRecoveryBtnRedPoint,showRedPoint)
	self._recoveryList = list
	local uiList = self._uiRecoveryList
	if uiList then
		uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("_uiRecoveryList")
		self._uiRecoveryList = uiList
		uiList:Create(self.mRecoveryItemList,list,function(...) self:OnDrawRecoveryCell(...) end,UIItemList.WRAP)
	end
	local len = #list
	if len > 0 then
		self:InitRecoveryList()
	end
	CS.ShowObject(self.mNoRecord,len <= 0)
end

-- 【G公共支持】删除神器功能相关数据
-- function UIReery:GetArtifact(Materials)
-- 	local list = {}
-- 	if not Materials then
-- --[[		local recovery = gModelDream:IsRecovery()
-- 		if not recovery then
-- 			local artifactItemList = self._artifactItemList
-- 			if artifactItemList then
-- 				local findArtifactItemNumList = self._findArtifactItemNumList or {}
-- 				for i,v in ipairs(artifactItemList) do
-- 					local func = findArtifactItemNumList[v]
-- 					if func then
-- 						local haveNum = func()
-- 						table.insert(list,{
-- 							itemType = LItemTypeConst.TYPE_ITEM,
-- 							itemId = v,
-- 							itemNum = haveNum,
-- 						})
-- 					end
-- 				end
-- 			end
-- 		end]]
-- 	end
-- 	local materialItemList = self._materialItemList
-- 	if materialItemList then
-- 		for i,v in ipairs(materialItemList) do
-- 			local haveNum = gModelItem:GetNumByRefId(v)
-- 			if haveNum > 0 then
-- 				table.insert(list,{
-- 					itemType = LItemTypeConst.TYPE_ITEM,
-- 					itemId = v,
-- 					itemNum = haveNum,
-- 				})
-- 			end
-- 		end
-- 	end
-- 	return list
-- end

function UIReery:GetRecoveryList()
	local list = {}
	local recoveryType = self:GetRecoveryType()
	if recoveryType == LItemTypeConst.TYPE_EQUIP then
		list = self:GetEquipList()
	-- 【G公共支持】删除神器功能相关数据
	-- elseif recoveryType == UIReery.RECOVERY_ARTIFACT then
		-- list = self:GetArtifact()
	end
	return list
end

function UIReery:InitData()
	self._func = self:GetWndArg("func")
	self._title = self:GetWndArg("title")
	local funcData = self:GetWndArg("funcData")
	self._recoveryType = funcData.recoveryType
	self._materialItemList = funcData.materialItemList
	-- 【G公共支持】删除神器功能相关数据
	-- self._artifactItemList = funcData.artifactItemList
	-- self._artifactItem = funcData.artifactItem
	self._materialItem = funcData.materialItem
	self._noChangeTxt = funcData.noChangeTxt
	self._sendMsg = false
	self._changeTypeList = {
		[1] = LItemTypeConst.TYPE_EQUIP,
		-- [2] = UIReery.RECOVERY_【G公共支持】删除神器功能相关数据
	}
	-- 【G公共支持】删除神器功能相关数据
	-- self._findArtifactItemNumList = {
	-- 	[UIReery.ARTIFACTUPLV] = function() return gModelDream:GetArtifactLv()  end,
	-- 	[UIReery.ARTIFACTSTRENGTH] = function() return gModelDream:GetRefineLv() end,
	-- 	[UIReery.ARTIFACTENABLING] = function() return gModelDream:GetMagicCount() or 0 end,
	-- }
end

function UIReery:GetRecoveryData()
	local recoveryType = self:GetRecoveryType()
	local list = {}
	local recoveryList = {}
	if recoveryType == LItemTypeConst.TYPE_EQUIP then
		recoveryList = self._recoveryList
	-- 【G公共支持】删除神器功能相关数据
	-- elseif recoveryType == UIReery.RECOVERY_ARTIFACT then
	-- 	local coin = gModelDream:ChangeCoinByItem()
	-- 	if coin then table.insert(recoveryList,coin) end
	-- 	local materials = self:GetArtifact(true)
	-- 	for i,v in ipairs(materials) do
	-- 		table.insert(recoveryList,v)
	-- 	end
	end
	for i,v in ipairs(recoveryList) do
		local itype,refId,num = v.itemType,v.itemId,v.itemNum
		local coin
		if recoveryType == LItemTypeConst.TYPE_EQUIP then
			local ref = gModelEquip:GetEquipRefByRefId(refId)
			if ref then coin = ref.coin end
			-- 【G公共支持】删除神器功能相关数据
		-- elseif recoveryType == UIReery.RECOVERY_ARTIFACT then
			-- if refId then
			-- 	local ref = gModelItem:GetRefByRefId(refId)
			-- 	if ref then coin = ref.sell end
			-- else
			-- 	coin = v
			-- end
		end
		if coin then
			num = num or 1
			local coinList = string.split(coin,",")
			for idx,data in ipairs(coinList) do
				data = string.split(data,"=")
				local itemType,itemId,itemNum = tonumber(data[1]),tonumber(data[2]),tonumber(data[3])
				local listData = list[itemId]
				if not listData then
					listData = {
						itemType = itemType,
						itemNum = 0
					}
					list[itemId] = listData
				end
				local curNum = listData.itemNum
				listData.itemNum = curNum + num * itemNum
			end
		end
	end
	local retList = {}
	for k,v in pairs(list) do
		local data = {
			itemType = v.itemType,
			itemId = k,
			itemNum = v.itemNum,
		}
		table.insert(retList,data)
	end
	return retList
end

function UIReery:SetDesc()
	local textId
	local str = ""
	local recoveryType = self:GetRecoveryType()
	if recoveryType == LItemTypeConst.TYPE_EQUIP then
		textId = 18359
	-- 【G公共支持】删除神器功能相关数据
	-- elseif recoveryType == UIReery.RECOVERY_ARTIFACT then
	-- 	textId = 18801
	end
	if textId then str = ccClientText(textId) end
	self:SetWndText(self.mDescTxt,str)
end

function UIReery:GetEquipList()
	local equipList = gModelEquip:GetEquipItemList()
	table.sort(equipList,function(a,b)
		local refId1,refId2 = a.itemId,b.itemId
		local ref1 = gModelEquip:GetEquipRefByRefId(refId1)
		local ref2 = gModelEquip:GetEquipRefByRefId(refId2)
		local eType1,eType2 = ref1.type,ref2.type
		if eType1 ~= eType2 then
			return eType1 < eType2
		else
			return ref1.composeOrder < ref2.composeOrder
		end
	end)
	return equipList
end

function UIReery:InitEmptyList()
	local data = {
		refId = 114,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIReery:RecoveryItem(data)
	local status = data and #data > 0
	if status then
		gModelGeneral:OnSellGoodsReq(data)
	else
		printInfoNR("==== no set list")
	end
	return status
end

function UIReery:RecoveryEvent()
	if self._sendMsg then return end
	local noChangeTxt = self._noChangeTxt
	local status = self:IsEmptyList()
	local recoveryType = self:GetRecoveryType()
	if recoveryType == LItemTypeConst.TYPE_EQUIP then
		if status then
			if not noChangeTxt then noChangeTxt = ccClientText(18371) end
			GF.ShowMessage(noChangeTxt)
		else
			status = self:RecoveryEquip()
		end
	-- 【G公共支持】删除神器功能相关数据
	-- elseif recoveryType == UIReery.RECOVERY_ARTIFACT then
		-- if status then
		-- 	if not noChangeTxt then noChangeTxt = ccClientText(18802) end
		-- 	GF.ShowMessage(noChangeTxt)
		-- else
		-- 	status = self:RecoveryDreamLand()
		-- end
	end
	self._sendMsg = status
end

function UIReery:OnDrawItemRecoveryCell(list,item,itemdata,itempos)
	local itype,refId,num = itemdata.itemType,itemdata.itemId,itemdata.itemNum
	local IconTrans = self:FindWndTrans(item,"Icon")
	if IconTrans then
		local icon
		if itype == LItemTypeConst.TYPE_ITEM then
			icon = gModelItem:GetItemIconByRefId(refId)
		end
		if icon then self:SetWndEasyImage(IconTrans,icon) end
	end
	local NumTrans = self:FindWndTrans(item,"Num")
	if NumTrans then
		num = LUtil.NumberCoversion(num)
		self:SetWndText(NumTrans,num)
	end
end
------------------------------------------------------------------
return UIReery


