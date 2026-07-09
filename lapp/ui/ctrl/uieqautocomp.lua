---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEqAutoComp:LWnd
local UIEqAutoComp = LxWndClass("UIEqAutoComp", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEqAutoComp:UIEqAutoComp()
	---@type table<number,CommonIcon>
	self._equipIconList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEqAutoComp:OnWndClose()
	self:ClearCommonIconList(self._equipIconList)
	self._equipIconList = nil

	gModelEquip:SetPlayerSel(self._selQualityList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEqAutoComp:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEqAutoComp:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self.jpj = gLGameLanguage:IsJapanVersion()
	local data = {refId = 102,IntroTran = self.mEmptyText,TextBgTran = self.mEmptyTextBg}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
	self:SetXUITextText(self.mCancelBtnName,ccClientText(10101))
	self:SetXUITextText(self.mEnterBtnName,ccClientText(10102))
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:InitEquipList()
end

function UIEqAutoComp:OnDrawEquipCell(list, item, itemdata, itempos, fromHeadTail)
--[[	local equipIconList = self._equipIconList
	local equipTrans = CS.FindTrans(item,"EquipIcon")
	local refId = itemdata.refId
	local num = itemdata.num
	local InstanceID = item:GetInstanceID()
	local baseClass = equipIconList[InstanceID]
	if not baseClass then
		baseClass = EquipIcon:New(self)
		equipIconList[InstanceID] = baseClass
	end
	baseClass:ShowNum(true,num)
	baseClass:Create(equipTrans,refId,function()
		GF.OpenWndUp("UIEqInfo",{refId = refId,noShowBtn = true})
	end)]]


	local iconTrans = CS.FindTrans(item,"IconRoot/Icon")
	local refId,num = itemdata.refId,itemdata.num
	local instanceId = item:GetInstanceID()
	local baseClass = self._equipIconList[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		self._equipIconList[instanceId] = baseClass
		baseClass:Create(iconTrans)
	end
	baseClass:SetCommonReward(LItemTypeConst.TYPE_EQUIP, refId, num)
	baseClass:EnableShowNum(true)
	self:SetIconClickScale(iconTrans, true)
	self:SetWndClick(iconTrans,function()
		GF.OpenWndUp("UIEqInfo",{refId = refId,noShowBtn = true})
	end)
	baseClass:DoApply()
end

function UIEqAutoComp:InitEquipList()
	local uiList = self._uiEquipList
	if not uiList then
		uiList = UIListWrap:New()
		uiList:Create(self,self.mEquipList)
		uiList:SetFuncOnItemDraw(function(...)
			self:OnDrawEquipCell(...)
		end)
		self._uiEquipList = uiList
	end
	uiList:RemoveAll()
	local list,payGold,canCompoundList = gModelEquip:GetCanCompoundEquipList4(self._type,self._selQualityList)
	for k,v in pairs(canCompoundList) do
		if v == 0 then
			canCompoundList[k] = nil
		end
	end
	self._compoundList = canCompoundList
	self._rewardList = list
	local numStr = ccClientText(11322)
	local tpayGold = payGold
	if tpayGold < 0 then tpayGold = 0 end
	tpayGold = LUtil.NumberCoversion(tpayGold)
	numStr = string.replace(numStr,tpayGold)
	self:SetXUITextText(self.mExpendTxt,numStr)
	local sortList = {}
	for k,v in pairs(list) do
		if v.num ~= 0 then
			table.insert(sortList,v)
		end
	end
	local function sortFunc(equip1,equip2)
		local refId1,refId2 = equip1.refId,equip2.refId
		local ref1,ref2 = gModelEquip:GetEquipRefByRefId(refId1),gModelEquip:GetEquipRefByRefId(refId2)
		return ref1.order < ref2.order
	end
	table.sort(sortList,sortFunc)
	for k,v in pairs(sortList) do
		uiList:AddData(k,v)
	end
	local show = table.isempty(sortList)
	CS.ShowObject(self.mNoList,show)
	uiList:RefreshList(UIListWrap.RefreshMode.Solid)
end

function UIEqAutoComp:InitEvent()
	self:SetWndClick(self.mBg,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function()
		local list = self._compoundList
		local rewardList = self._rewardList
		if not table.isempty(list) and  not table.isempty(rewardList) then
			--local tab = {}
			--for k,v in pairs(list) do
			--	tab[k] = v.num
			--end
			local temp = {}
			for k,v in pairs(rewardList) do
				temp[k] = v.num
			end
			gModelEquip:OnEquipCompoundReq(list,temp,1)
		end
	end)
	self:SetWndClick(self.mCancelBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	local selBtnList = self._selBtnList
	for i,v in ipairs(selBtnList) do
		self:SetWndClick(v,function()
			self:SelQualityBtnEvent(i,v)
		end,LSoundConst.CLICK_PAGE_COMMON)
	end
end

function UIEqAutoComp:InitMsg()
	self:WndNetMsgRecv(LProtoIds.EquipCompoundResp,function()
		self:WndClose()
	end)
end

function UIEqAutoComp:RefreshSelStatus(i)
	local selQuality = self._selQualityList[i]
	local selImg = self._selImgList[i]
	CS.ShowObject(selImg,selQuality)
end

function UIEqAutoComp:SelQualityBtnEvent(i,btn)
	local selQualityList = self._selQualityList
	local selStatus = selQualityList[i]
	self._selQualityList[i] = not selStatus
	self:RefreshSelStatus(i)
	self:InitEquipList()
end

function UIEqAutoComp:InitData()
	self._type = self:GetWndArg("EquipType")
	if not self._type then
		return
	end
	local selList = gModelEquip:GetPlayerSel()
	if not table.isempty(selList) then
		self._selQualityList = selList
	else
		self._selQualityList = {true,true,true,true,true}
	end
	self._selBtnList = {
		self.mSelBtn1,
		self.mSelBtn2,
		self.mSelBtn3,
		self.mSelBtn4,
		self.mSelBtn5,
	}
	self._selImgList = {
		self.mSelImg1,
		self.mSelImg2,
		self.mSelImg3,
		self.mSelImg4,
		self.mSelImg5,
	}
	self._selNameList = {
		self.mSelName1,
		self.mSelName2,
		self.mSelName3,
		self.mSelName4,
		self.mSelName5,
	}
	self.selTextColor = {
		"<#139056>",
		"<#1b62a3>",
		"<#9624ab>",
		"<#d2730f>",
		"<#c81313>",
	}
	self._compoundList = {}
	self._rewardList = {}
	local selImgList = self._selImgList
	local selNameList = self._selNameList
	for i,v in ipairs(selImgList) do
		self:RefreshSelStatus(i)
		local qualityRef = gModelItem:GetQualityRef(i+1)
		local str = ccClientText(11323)
		local colorName = ccLngText(qualityRef.name)
		str = string.replace(str,colorName)
		self:SetWndText(selNameList[i], self.selTextColor[i] .. str .. "</color>")
		if self.jpj then
			self:InitTextSizeWithLanguage(selNameList[i],-6)
			self:InitTextLineWithLanguage(selNameList[i],-50)
		end
		if gLGameLanguage:IsVieVersion() then
			self:InitTextLineWithLanguage(selNameList[i],0)
		end
	end

	self:SetWndText(self.mTitle, ccClientText(11315))
end
------------------------------------------------------------------
return UIEqAutoComp


