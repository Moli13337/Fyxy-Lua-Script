---
--- Created by BY.
--- DateTime: 2023/10/14 11:05:19
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActEntryBuyPop:LWnd
local UIActEntryBuyPop = LxWndClass("UIActEntryBuyPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActEntryBuyPop:UIActEntryBuyPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActEntryBuyPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActEntryBuyPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActEntryBuyPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIActEntryBuyPop:OnTryTcpReconnect()
	self:WndClose()
end

function UIActEntryBuyPop:OnClickItemBuy()
	local _entry = self._entry
	local _expend2 = self._expend2
	local items = LxDataHelper.ParseItem(_expend2)
	local item = items[1]
	local dia = gModelItem:GetNumByRefId(item.itemId)
	local itemName = gModelItem:GetNameByRefId(item.itemId)
	local value = item.itemNum
	-- 钻石购买
	local func = function()
		if dia >= value then
			gModelActivity:OnActivityMarkeyBuyReq(self._sid,_entry.pageId,_entry.entryId)
		else
			gModelGeneral:OpenGetWayWnd({itemId = item.itemId})
		end
	end
	GF.OpenWnd("UIOrdinTip",{refId = 110005,func = func,para = {value .. itemName},consume = {value, item.itemId}})
end

function UIActEntryBuyPop:OnClickBuy()
	local _entry = self._entry
	local _entryCfg = self._entryCfg
	if not _entryCfg or not _entry then return end
	local _name = _entryCfg.name
	local func = function()
		gModelPay:GiftPayCtrl(_entry.entryId,self._expend2,ModelPay.PAY_TYPE_ACTIVITY,nil,self._sid,_entry.pageId)
	end
	local moreInfo = _entryCfg.moreInfo
	local arr = string.split(moreInfo,"|")
	local effectId = tonumber(arr[1])
	local effRef = gModelHero:GetShowEffectById(effectId)
	if gModelHero:CheckFovSkinItem(effectId,effRef.heroType) then
		gModelGeneral:OpenUIOrdinTips({refId = 110050,para = {_name},func = func})
		return
	end
	func()
end

function UIActEntryBuyPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		self:WndClose()
	end)
end

function UIActEntryBuyPop:RefreshItem(reward)
	local list = LxDataHelper.ParseItem(reward)
	local uiList1 = self._uiCellList
	if not uiList1 then
		uiList1 = UIIconEasyList:New(self)
		uiList1:Create(self, self.mItemScroll)
		uiList1:SetIconParentPath("Root/CommonUI/Icon")
		self._uiCellList = uiList1
	end
	uiList1:RefreshList(list)
end

function UIActEntryBuyPop:InitCommand()
	local page = self:GetWndArg("page")
	if not page then return end
	local title = page.title or ccClientText(25908)
	local sid = page.sid
	local entry = page.entry
	if not entry or not sid then return end
	self._sid = sid
	self._entry = entry

	self:SetWndText(self.mLblBiaoti,title)
	self:SetWndText(self.mTitleText,ccClientText(25909))

	local pageId = entry.pageId
	local entryId = entry.entryId

	local entryCfg = gModelActivity:GetWebActivityEntryData(sid,pageId,entryId)
	local reward = entryCfg.reward
	local description = entryCfg.description
	self:SetWndText(self.mNumText,description)
	self:RefreshItem(reward)
	local expend2 = entryCfg.expend2
	self._expend2 = expend2
	local isItemBuy2 = string.find(expend2,"=")
	self._entryCfg = entryCfg
	CS.ShowObject(self.mBtnItemBuy,false)
	CS.ShowObject(self.mBtnBuy,false)
	if not isItemBuy2 then
		local cost2 = gModelPay:GetShowByWelfareId(tonumber(expend2))
		CS.ShowObject(self.mBtnBuy,true)
		self:SetWndButtonText(self.mBtnBuy,cost2)
	else
		local costList = LxDataHelper.ParseItem_3List(tostring(expend2))
		local cost = costList[1]
		CS.ShowObject(self.mBtnItemBuy,true)
		self:SetWndText(self.mItemBuyText,cost.itemId)
		local icon = gModelItem:GetItemIconByRefId(tonumber(cost.itemId))
		self:SetWndEasyImage(self.mItemBuyIcon,icon)
	end
end

function UIActEntryBuyPop:InitEvent()
	self:SetWndClick(self.mBgImage,function (...)self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function (...)self:WndClose() end)
	self:SetWndClick(self.mBtnBuy,function (...) self:OnClickBuy() end)
	self:SetWndClick(self.mBtnItemBuy,function (...) self:OnClickItemBuy() end)
end
------------------------------------------------------------------
return UIActEntryBuyPop


