---
--- Created by Administrator.
--- DateTime: 2024/6/27 21:27:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeEqAutoComp:LWnd
local UIPeEqAutoComp = LxWndClass("UIPeEqAutoComp", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeEqAutoComp:UIPeEqAutoComp()
	self._equipIconList ={}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeEqAutoComp:OnWndClose()
	LWnd.OnWndClose(self)
	gModelPet:SetPlayerSel(self._selQualityList)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeEqAutoComp:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeEqAutoComp:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
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

function UIPeEqAutoComp:InitData()
	self._part = self:GetWndArg("part")
	self._compoundList = self:GetWndArg("list")
	self._needList = self:GetWndArg("needList")
	if not self._part then
		return
	end
	local selList = gModelPet:GetPlayerSel()
	if not table.isempty(selList) then
		self._selQualityList = selList
	else
		self._selQualityList = {nil,true,true,true,true,true,nil}
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
	self._rewardList = {}
	local selImgList = self._selImgList
	local selNameList = self._selNameList
	for i,v in pairs(selImgList) do
		if v then
			self:RefreshSelStatus(i+1)
			local qualityRef = gModelItem:GetQualityRef(i+1)
			local str = ccClientText(11323)
			local colorName = ccLngText(qualityRef.name)
			str = string.replace(str,colorName)
			self:SetWndText(selNameList[i], self.selTextColor[i] .. str .. "</color>")
		end
	end

	self:SetWndText(self.mTitle, ccClientText(11315))
end

function UIPeEqAutoComp:OnDrawEquipCell(list, item, itemdata, itempos, fromHeadTail)

	local iconTrans = CS.FindTrans(item,"IconRoot/Icon")
	local refId,num = itemdata:GetRefId(),itemdata:GetNum()
	local instanceId = item:GetInstanceID()
	local baseClass = self._equipIconList[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New(self)
		self._equipIconList[instanceId] = baseClass
		baseClass:Create(iconTrans)
	end
	baseClass:SetCommonReward(LItemTypeConst.TYPE_PET_EQUIP, refId, num)
	baseClass:EnableShowNum(true)
	self:SetIconClickScale(iconTrans, true)
	self:SetWndClick(iconTrans,function()
		-- GF.OpenWndUp("UIEqInfo",{refId = refId,noShowBtn = true,nil})
		gModelGeneral:OpenEquipInfoTip(refId,nil,nil,true,nil,nil,nil,LItemTypeConst.TYPE_PET_EQUIP)
	end)
	baseClass:DoApply()
end

function UIPeEqAutoComp:InitMsg()
	self:WndNetMsgRecv(LProtoIds.PetEquipCompoundResp,function()
		self:WndClose()
	end)
end

function UIPeEqAutoComp:SelQualityBtnEvent(i,btn)
	local selQualityList = self._selQualityList
	local selStatus = selQualityList[i]
	self._selQualityList[i] = not selStatus
	self:RefreshSelStatus(i)
	self:InitEquipList()
end

function UIPeEqAutoComp:InitEvent()
	self:SetWndClick(self.mBg,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEnterBtn,function()
		local compRwdList = {}
		local compNeedList = {}
		for k,item in pairs(self.qualityList) do
			local refId = item:GetRefId()
			local need = self._needList[refId]
			compRwdList[refId] = item:GetNum()
			compNeedList[need.needRefId] = need.needNum
		end
		gModelPet:OnPetEquipCompoundReq(compNeedList,compRwdList,1)
	end)
	self:SetWndClick(self.mCancelBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)

	local selBtnList = self._selBtnList
	for i,v in pairs(selBtnList) do
		if v then
			self:SetWndClick(v,function()
				self:SelQualityBtnEvent(i+1,v)
			end,LSoundConst.CLICK_PAGE_COMMON)
		end
	end
end

function UIPeEqAutoComp:RefreshSelStatus(i)
	local selQuality = self._selQualityList[i]
	local selImg = self._selImgList[i-1]
	CS.ShowObject(selImg,selQuality)
end

function UIPeEqAutoComp:InitEquipList()
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
	self.qualityList = {}
	local isHas = false
	for _, value in ipairs(self._compoundList) do
		local eCfg = gModelPet:GetPetEquipRef(value:GetRefId())
		if self._selQualityList[eCfg.quality] then
			table.insert(self.qualityList,value)
			isHas = true
		end
	end
	self:SetXUITextText(self.mExpendTxt,ccClientText(43762))
	local function sortFunc(equip1,equip2)
		local refId1,refId2 = equip1:GetRefId(),equip2:GetRefId()
		local ref1,ref2 = gModelPet:GetPetEquipRef(refId1),gModelPet:GetPetEquipRef(refId2)
		return ref1.order < ref2.order
	end
	table.sort(self.qualityList,sortFunc)
	for k,v in pairs(self.qualityList) do
		uiList:AddData(k,v)
	end
	CS.ShowObject(self.mNoList,not isHas)
	uiList:RefreshList(UIListWrap.RefreshMode.Solid)
end

------------------------------------------------------------------
return UIPeEqAutoComp