---
--- Created by Administrator.
--- DateTime: 2024/6/11 14:23:16
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeWishLandReportResult:LWnd
local UIPeWishLandReportResult = LxWndClass("UIPeWishLandReportResult", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeWishLandReportResult:UIPeWishLandReportResult()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeWishLandReportResult:OnWndClose()
	gModelPetDreanLand:OpenPetDreamLandReportResult()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeWishLandReportResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeWishLandReportResult:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UIPeWishLandReportResult:InitRewardList()
	local list = self:GetRewardList() or {}

	local len = #list
	local isMin = len < 5
	local listTrans = isMin and self.mRewardMinList or self.mRewardMaxList
	local hideTrans = isMin and self.mRewardMaxList or self.mRewardMinList
	CS.ShowObject(listTrans,true)
	CS.ShowObject(hideTrans,false)
	local uiList = self:FindUIScroll("RewardList")
	if uiList then
        uiList:RefreshList(list)
	else
		uiList = self:GetUIScroll("RewardList")
		uiList:Create(listTrans, list, function(...) self:OnDrawRewardCell(...) end)
	end
	uiList:EnableScroll(true,true)
	local isEmpty = #list < 1
	if isEmpty then
		self:InitEmptyList(39003)
	end
	CS.ShowObject(self.mNoRecord2,isEmpty)
end

---@param itemdata StructRewardItem
function UIPeWishLandReportResult:OnDrawRewardCell(list, item, itemdata, itempos)
	local Icon = self:FindWndTrans(item,"CommonUI/Icon")
	local InstanceID = item:GetInstanceID()
	local baseClass = self:GetCommonIcon(InstanceID)
	baseClass:Create(Icon)
	baseClass:SetCommonReward(itemdata.type,itemdata.itemId, itemdata.count)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()
	self:SetWndClick(Icon,function()
		gModelGeneral:ShowCommonItemTipWnd(itemdata)
	end)
end

function UIPeWishLandReportResult:OnClickBtnEnter()
	self:WndClose()
end

function UIPeWishLandReportResult:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	-- self:WndNetMsgRecv(LProtoIds.xxxxx,function(...) self:OnMsgXXXXX(...) end)
end

function UIPeWishLandReportResult:RefreshDesc()
	local desc = ""
	local type = self._type
	if type == ModelPetDreanLand.TYPE_SETTLEMENT_0 then
		desc = string.replace(ccClientText(43386),gModelPetDreanLand:GetPetDreamlandName(self._refId))
	elseif type == ModelPetDreanLand.TYPE_SETTLEMENT_1 then
		desc = string.replace(ccClientText(43341),self._playerInfos.name,self:GetLostItemStr())
	elseif type == ModelPetDreanLand.TYPE_SETTLEMENT_2 then
		desc = string.replace(ccClientText(43383),self._playerInfos.name,self:GetLostItemStr())
	elseif type == ModelPetDreanLand.TYPE_SETTLEMENT_3 then
		desc = string.replace(ccClientText(43385),gModelPetDreanLand:GetPetDreamlandName(self._refId))
	elseif type == ModelPetDreanLand.TYPE_SETTLEMENT_4 then
		desc = string.replace(ccClientText(43384),gModelPetDreanLand:GetPetDreamlandName(self._refId))
	end
	self:SetWndText(self.mDesc,desc)
end


function UIPeWishLandReportResult:InitData()
	--- 幻境id
	self._refId = self:GetWndArg("refId")

	--- 据点id
	self._pointId = self:GetWndArg("pointId")

	---@type table<StructRewardItem> 最终奖励物品列表
	self._itemList = self:GetWndArg("itemList")

	--- 已占领时间
	self._time = self:GetWndArg("time")

	--- 结算类型
	self._type = self:GetWndArg("type")

	---@type StructSimplePlayerInfo
	self._playerInfos = self:GetWndArg("playerInfos")

	---@type table<StructRewardItem> 损失奖励信息
	self._lostItem = self:GetWndArg("lostItem")
end

function UIPeWishLandReportResult:GetLostItemStr()
	local strList = {}
	local loseItem = self._lostItem
	---@param v StructRewardItem
	for i,v in ipairs(loseItem) do
		table.insert(strList,string.replace(ccClientText(43362),
				gModelItem:GetNameByRefId(v.itemId),LUtil.NumberCoversion(v.count)))
	end
	return table.concat(strList,ccClientText(43356))
end

function UIPeWishLandReportResult:OnMsgXXXXX()
end

function UIPeWishLandReportResult:OnEventXXXXX()
end

function UIPeWishLandReportResult:InitText()
	--self:SetWndText(self.mLblBiaoti,ccClientText(43344))
	self:SetWndText(self.mLblBiaoti,ccClientText(43400))
	self:SetWndButtonText(self.mBtnEnter,ccClientText(43343))
end


function UIPeWishLandReportResult:GetRewardList()
	local list = {}

	---@param v StructRewardItem
	local itemList = self._itemList or {}
	for i,v in ipairs(itemList) do
		if v.count > 0 then
			table.insert(list,v)
		end
	end
	return list
end

function UIPeWishLandReportResult:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnEnter,function() self:OnClickBtnEnter() end)
end

function UIPeWishLandReportResult:RefreshView()
	self:RefreshDesc()
	self:InitRewardList()
--[[	self:SetWndText(self.mTimeTxt,string.replace(ccClientText(43342),
			LUtil.FormatTimespanNumber(self._time)))]]
	self:SetWndText(self.mTimeTxt,string.replace(ccClientText(43342),
			LUtil.FormatTimeStr1(self._time)))
end

function UIPeWishLandReportResult:InitEmptyList(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

------------------------------------------------------------------
return UIPeWishLandReportResult