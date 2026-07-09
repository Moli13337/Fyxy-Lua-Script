---
--- Created by Administrator.
--- DateTime: 2025/6/16 10:44:48
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActivity166RewSel:LWnd
local UIActivity166RewSel = LxWndClass("UIActivity166RewSel", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActivity166RewSel:UIActivity166RewSel()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActivity166RewSel:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActivity166RewSel:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActivity166RewSel:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end



function UIActivity166RewSel:GetSelRewardList()
	return self._selRewardList or {}
end

function UIActivity166RewSel:RefreshView()
	self:InitSelRewardList()
end

function UIActivity166RewSel:InitMsg()
	-- self:WndEventRecv(EventNames.xxxxx,function (...) self:OnEventXXXXX() end)
	self:WndNetMsgRecv(LProtoIds.ActSelLotteryGuaranteeResp,function(...) self:OnActSelLotteryGuaranteeResp(...) end)
end

function UIActivity166RewSel:OnDrawSelRewardCell(list, item, itemdata, itempos)
	local instanceID = item:GetInstanceID()
	local itemCache = self:GetComponentCache(instanceID)
	if not itemCache then
		local Root = self:FindWndTrans(item,"Root")
		local SelImg = self:FindWndTrans(Root,"SelImg")
		local SelDesc = self:FindWndTrans(SelImg,"SelDesc")
		itemCache = {
			Icon = self:FindWndTrans(Root,"Icon"),
			SelImg = SelImg,
			Name = self:FindWndTrans(Root,"Name"),
		}
		self:SetComponentCache(instanceID, itemCache)

		self:SetWndText(SelDesc,ccClientText(47006))
	end

	local data = itemdata.data
	local type = data.type
	local showNum = type == LItemTypeConst.TYPE_ITEM and true or false
	local baseClass = self:GetCommonIcon(instanceID)
	baseClass:Create(itemCache.Icon)
	baseClass:SetCommonReward(type, data.itemId, data.count)
	baseClass:EnableShowNum(showNum)
	baseClass:DoApply()

	local name = gModelGeneral:GetCommonItemName(data)
	self:SetWndText(itemCache.Name,name)

	CS.ShowObject(itemCache.SelImg,self:CheckIsSelGuaranteeId(itemdata))

	self:SetWndClick(item,function ()
		self:OnClickSelRewardCell(itemdata)
		--gModelGeneral:ShowCommonItemTipWnd(data)
	end)
	self:SetWndLongClick(item,function()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end,0.8,false)
end

function UIActivity166RewSel:OnActSelLotteryGuaranteeResp()
	self:WndClose()
end

function UIActivity166RewSel:CheckIsSelGuaranteeId(itemdata)
	return self._guaranteeId == itemdata.guaranteeId
end


function UIActivity166RewSel:InitData()
	self._sid = self:GetWndArg("sid")
	self._round = self:GetWndArg("round")
	self._guaranteeId = self:GetWndArg("guaranteeId") or 0
	self._selRewardList = self:GetWndArg("selRewardList")
end

function UIActivity166RewSel:OnClickBtnEnter()
	if not self._guaranteeId or self._guaranteeId < 1 then return end
	gModelActivity:OnActSelLotteryGuaranteeReq(self._sid,ModelActivity.PAGE_ACTIVITY_166_CALL,self._round,self._guaranteeId)
end

function UIActivity166RewSel:InitSelRewardList()
	local list = self:GetSelRewardList()

	---@type UIItemList
	local uiSelRewardList = self._uiSelRewardList
	if uiSelRewardList then
		uiSelRewardList:RefreshList(list)
	else
		uiSelRewardList = self:GetUIScroll("SelRewardList")
		self._uiSelRewardList = uiSelRewardList
		uiSelRewardList:Create(self.mSelRewardList, list, function(...) self:OnDrawSelRewardCell(...) end)
		uiSelRewardList:EnableScroll(true)
	end
end

function UIActivity166RewSel:InitText()
	self:SetXUITextText(self.mLblBiaoti,ccClientText(47003))
	self:SetWndText(self.mSelTxt,ccClientText(47006))
	self:SetWndButtonText(self.mBtnEnter,ccClientText(47007))
	self:SetWndText(self.mDescTxt,ccClientText(13266))
end

function UIActivity166RewSel:OnEventXXXXX()
end

function UIActivity166RewSel:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBgImage,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnEnter,function() self:OnClickBtnEnter() end)
end

function UIActivity166RewSel:OnClickSelRewardCell(itemdata)
	self._guaranteeId = itemdata.guaranteeId

	---@type UIItemList
	local uiSelRewardList = self._uiSelRewardList
	local uiList = uiSelRewardList:GetList()
	if uiList then
		uiList:RefreshList()
	end
end

------------------------------------------------------------------
return UIActivity166RewSel