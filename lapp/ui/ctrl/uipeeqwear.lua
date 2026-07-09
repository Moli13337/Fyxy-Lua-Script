---
--- Created by Administrator.
--- DateTime: 2024/6/24 20:02:23
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeEqWear:LWnd
local UIPeEqWear = LxWndClass("UIPeEqWear", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeEqWear:UIPeEqWear()
	---@type table<number,CommonIcon>
	self._equipIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeEqWear:OnWndClose()
	self:ClearCommonIconList(self._equipIconList)
	self._equipIconList = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeEqWear:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeEqWear:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:SetEmptyData()
	self:InitEvent()
	self:InitMsg()
	self:InitText()
	if self._isRefId then
		-- 替换
		self:EquipReplaceView()
	else
		-- 穿戴
		self:EquipWearView()
	end
	self:InitEquipList()
end

function UIPeEqWear:OnDrawEquipCell(list, item, itemdata, itempos, fromHeadTail)
	local InstanceID = item:GetInstanceID()
	local refId = itemdata.refId
	self:SetInfo(item,InstanceID,refId,itemdata)
end

function UIPeEqWear:InitEquipList()
	local isRefId = self._isRefId
	local uiList = self._uiList
	if not uiList then
		uiList = UIListWrap:New()
		if isRefId then
			uiList:Create(self,self.mWearList2)
		else
			uiList:Create(self,self.mWearList1)
		end
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawEquipCell(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	local equipType = self._equipType
	local equipList = gModelPet:GetEquipListByPart(tonumber(equipType))

	local isEmpty = table.isempty(equipList)
	if not isEmpty then
		local sortEquipList = {}
		for k,v in pairs(equipList) do
			local refId = v._refId
			if self._refId ~= refId and v:GetNum()>0 then
				local ref = gModelPet:GetPetEquipRef(refId)
				table.insert(sortEquipList,ref)
			end
		end
		table.sort(sortEquipList,function(equip1,equip2)
			local refId1,refId2 = equip1.refId,equip2.refId
			local score1,score2 = gModelPet:GetPetEquipByRefId(refId1)._score,gModelPet:GetPetEquipByRefId(refId2)._score
			return score1 > score2
		end)
		for i,v in ipairs(sortEquipList) do
			uiList:AddData(i,v)
		end
	end
	if isEmpty then
		if self._isRefId then
			CS.ShowObject(self.mNoRecord1,false)
			CS.ShowObject(self.mNoRecord2,true)
			CS.ShowObject(self.mWearList2,false)
		else
			CS.ShowObject(self.mNoRecord1,true)
			CS.ShowObject(self.mNoRecord2,false)
			CS.ShowObject(self.mWearList1,false)
		end
	end
	uiList:RefreshList()
end

function UIPeEqWear:SetEmptyData()
	local data = {refId = 36003,IntroTran = self.mEmptyText,TextBgTran = self.mEmptyTextBg,IconTran = self.mEmptyIcon}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)
	data = {refId = 36003,IntroTran = self.mEmptyText2,TextBgTran = self.mEmptyTextBg2,IconTran = self.mEmptyIcon2}
	emptyList = self:GetCommonEmptyList("_empty2")
	emptyList:RefreshUI(data)
end

function UIPeEqWear:SaveEquipWearData(refId,chang)
	self._refId = refId
	local equipRef = gModelPet:GetPetEquipRef(refId)
	local isRefId = true
	if not equipRef then
		isRefId = false
	else
		self._equipRef = equipRef
	end
	self._isRefId = isRefId
end

function UIPeEqWear:InitMsg()
	self:WndNetMsgRecv(LProtoIds.PetEquipWearResp, function()
		self:WndClose()
	end)
	self:WndNetMsgRecv(LProtoIds.PetEquipUnloadResp, function()
		self:WndClose()
	end)
end

-- 替换界面
function UIPeEqWear:EquipReplaceView()
	self:SetXUITextText(self.mTitle,ccClientText(43740))
	CS.ShowObject(self.mView2,true)
	local ref = self._equipRef
	if ref then
		self:SetInfo(nil,1,self._refId,ref)
	end
end

function UIPeEqWear:InitText()
	self:SetWndButtonText(self.mGetBtn, ccClientText(13247))
	self:SetWndButtonText(self.mGetBtn2, ccClientText(13247))
end

function UIPeEqWear:ClickGetText()
	local cfg = gModelGeneral:GetEmptyCfg(36003)
	gModelGeneral:OpenGetWayWnd({itemId = cfg.jumpItem})
end

function UIPeEqWear:InitData()
	self.petId = self:GetWndArg("petRefId")
	local refId = self:GetWndArg("refId")
	self._equipType = self:GetWndArg("part")
	if not refId then return end
	self._wearAttrList = {
		self.mWearAttr1,
		self.mWearAttr2,
	}
	self:SaveEquipWearData(refId)
end

-- 穿戴界面
function UIPeEqWear:EquipWearView()
	self:SetXUITextText(self.mTitle,ccClientText(43739))
	CS.ShowObject(self.mView1,true)
end

function UIPeEqWear:InitEvent()
	self:SetWndClick(self.mBg,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mGetBtn, function() self:ClickGetText() end)
	self:SetWndClick(self.mGetBtn2, function() self:ClickGetText() end)
end

function UIPeEqWear:SetInfo(item,InstanceID,refId,itemdata)
	local isRefId = self._isRefId
	local isAlike = refId == self._refId
	local EquipIconTrans = self.mEquipIconTrans
	CS.ShowObject(self.mEquipIconTrans,true)
	if item then
		EquipIconTrans = CS.FindTrans(item,"IconRoot")
	end
	if EquipIconTrans then
		local baseClass = self._equipIconList[InstanceID]
		if not baseClass then
			baseClass = CommonIcon:New(self)
			self._equipIconList[InstanceID] = baseClass
			baseClass:Create(CS.FindTrans(EquipIconTrans, "Icon"))
		end
		baseClass:SetCommonReward(LItemTypeConst.TYPE_PET_EQUIP, refId)
		baseClass:EnableShowNum(item ~= nil)
		self:SetIconClickScale(EquipIconTrans, true)
		self:SetWndClick(EquipIconTrans,function()
			gModelGeneral:OpenEquipInfoTip(refId,nil,nil,true,nil,nil,nil,LItemTypeConst.TYPE_PET_EQUIP)
		end)
		baseClass:DoApply()
		-- baseClass._curIconCls._iconInst.transform.localScale = Vector3.New(0.77, 0.77, 0.77)
	end
	local EquipNameTrans = self.mWearEquipName
	if item then
		EquipNameTrans = CS.FindTrans(item,"EquipName")
	end
	if EquipNameTrans then
		local name = ccLngText(itemdata.name)
		self:SetWndText(EquipNameTrans,name)

		local quaId = itemdata.quality
		-- 名字设置颜色
		local color = gModelItem:GetColorByQualityId(quaId)
		self:SetXUITextTransColor(EquipNameTrans,color)
	end
	local attrList = {}
	if item then
		for i = 1,2 do
			local attrTrans = CS.FindTrans(item,"Attr"..i)
			if attrTrans then
				attrList[i] = attrTrans
				CS.ShowObject(attrTrans,false)
			end
		end
	end
	local list = string.split(itemdata.attr,",")
	for i = 1,#list do
		local trans
		if item then
			trans = attrList[i]
		else
			trans = self._wearAttrList[i]
		end
		if trans then
			CS.ShowObject(trans,true)
			local data = list[i]
			local sAttrList = string.split(data,"=")
			local attrType,numType,attrNum = tonumber(sAttrList[1]),tonumber(sAttrList[2]),tonumber(sAttrList[3])
			local attrTrans
			if item then
				attrTrans = CS.FindTrans(trans,"Attr")
			else
				attrTrans = trans
			end
			if attrTrans then
                local value = gModelHero:GetAttributeValueNoNameByIdAndVal(attrType,numType,attrNum)
				local str = gModelHero:GetAttributeNameById(attrType)
				str = str.."：<color=#559175>"..value .. "</color>"
				self:SetWndText(attrTrans,str)
			end
		end
	end
	local ScoreTxtTrans = self.mWearScoreTxt
	if item then
		ScoreTxtTrans = CS.FindTrans(item,"ScoreTxt")
	end
    local scoreNum = gModelPet:GetPetEquipRef(refId).score
	if ScoreTxtTrans then
		local str = ccClientText(11311)
		local score = math.floor(scoreNum + 0.5)
		str = string.replace(str,score)
		self:SetWndText(ScoreTxtTrans,str)
	end
	local WearBtnTrasn = self.mWearBtn
	if item then
		WearBtnTrasn = CS.FindTrans(item,"WearBtn")
	end
	if WearBtnTrasn then
		self:SetWndClick(WearBtnTrasn,function()
			print("==== self._heroId = "..self.petId.."===="..refId)
			if isAlike then
				gModelPet:OnPetEquipUnloadReq(self.petId,{refId})
			else
				-- if self._isRefId then
				-- 	gModelPet:OnPetEquipWearReq(self.petId,{refId},1)
				-- else
				-- end
				gModelPet:OnPetEquipWearReq(self.petId,{refId},1)
			end
		end)
		local btnNameTrans = CS.FindTrans(WearBtnTrasn,"btnName")
		if btnNameTrans then
			if isAlike then
				self:SetWndText(btnNameTrans,ccClientText(11302))
			else
				if self._isRefId then
					self:SetWndText(btnNameTrans,ccClientText(11310))
				else
					self:SetWndText(btnNameTrans,ccClientText(11301))
				end
			end
		end
	end
	if isRefId and item then
		local redPointTrans = CS.FindTrans(item,"redPoint")
		if redPointTrans then
			local show = false
			local curScore = gModelPet:GetPetEquipByRefId(self._refId)._score
			if curScore and curScore < scoreNum then
				show = true
			end
			CS.ShowObject(redPointTrans,show)
		end
	end
end
------------------------------------------------------------------
return UIPeEqWear