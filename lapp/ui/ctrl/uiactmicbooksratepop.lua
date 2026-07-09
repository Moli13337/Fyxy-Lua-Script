---
--- Created by Administrator.
--- DateTime: 2023/10/28 22:00:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIActMicBooksRatePop:LWnd
local UIActMicBooksRatePop = LxWndClass("UIActMicBooksRatePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIActMicBooksRatePop:UIActMicBooksRatePop()
	---@type table<number,CommonIcon>
	self._uiCommonList = {}

	---@type LUIHeroObject
	self._curUIHeroObj = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIActMicBooksRatePop:OnWndClose()
	self:ClearCommonIconList(self._uiCommonList)
	self._uiCommonList = nil
	self._curUIHeroObj = nil

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIActMicBooksRatePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIActMicBooksRatePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMsg()
	self:InitCommand()

	self:SetWndText(self.mTitleText, ccClientText(23216))
	self:SetWndButtonText(self.mOkBtn, ccClientText(10102))

	if not gLGameLanguage:IsForeignRegion() then
		CS.ShowObject(self.mDescContent, true)
		self:SetWndText(self.mDescText, ccClientText(38217))
	end
end

function UIActMicBooksRatePop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mCloseBtn, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mOkBtn, function(...) self:WndClose() end,LSoundConst.CLICK_BUTTON_COMMON)
	self:SetWndClick(self.mHelpBtn, function() self:OnClickHelp() end, LSoundConst.CLICK_ERROR_COMMON)
end

function UIActMicBooksRatePop:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ActivityPageResp, function(...) self:OnActivityPageResp(...) end)
end

--#####################################################################################################################
--## Server ###########################################################################################################
--#####################################################################################################################
function UIActMicBooksRatePop:OnActivityPageResp(pb, ret)
	local sid = pb.sid
	if self._sid ~= sid then
		return
	end

	self:ResetActivePageData(pb)
	self:RefreshUI()
end

function UIActMicBooksRatePop:OnDrawRewardListItem(list, item,itemdata,itempos)
	local itemRoot = self:FindWndTrans(item,"itemRoot")
	local itemText = self:FindWndTrans(item,"itemText")

	local itemList = itemdata.reward
	if table.isempty(itemList) then return end
	local curData  = itemList[1]
	local itemType,itemRefId,itemCount = curData.itemType,curData.itemId,curData.itemNum
	local itemRate = itemdata.itemRate

	local rateValue = math.floor(itemRate / self._allRate * 10000) / 100
	local txtStr   = rateValue.."%"
	self:SetWndText(itemText, txtStr)

	local formatData =
	{
		itemId = itemRefId,
		itemType = itemType,
		itemNum = itemCount,
	}
	local uiCommonList = self._uiCommonList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiCommonList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		uiCommonList[InstanceID] = baseClass
		baseClass:Create(CS.FindTrans(itemRoot,"CommonUI/Icon"))
	end
	baseClass:SetCommonReward(itemType, itemRefId, itemCount)
	self:SetWndClick(itemRoot, function()
		gModelGeneral:ShowCommonItemTipWnd(formatData)
	end)
	baseClass:DoApply()
end

--#####################################################################################################################
--## Content ##########################################################################################################
--#####################################################################################################################
function UIActMicBooksRatePop:RefreshUI()
	local contentList = self._gridRateData
	local uiList = self:GetUIScroll("contentList")
	if(uiList:GetList())then
		uiList:RefreshList(contentList)
	else
		uiList:Create(self.mContentList,contentList,function (...) self:OnDrawRewardListItem(...) end,UIItemList.WRAP)
	end

	uiList:EnableScroll(true, false)
end

--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UIActMicBooksRatePop:ResetActivePageData(pb)
	for i, v in ipairs(pb.pages) do
		local pageId = v.pageId
		if pageId == self._page then
			local page = gModelActivity:GenerateActivePageDataFromPb(v)
			self._pages = page
			break
		end
	end

	if not self._pages then
		return
	end

	local allRate = 0
	for p,q in ipairs(self._pages.entry) do
		local entryId = q.entryId
		local entryCfg = gModelActivity:GetWebActivityEntryData(self._sid, q.pageId, entryId)
		if entryCfg then
			if not self._gridRateData[entryId] then
				self._gridRateData[entryId] = {}
			end

			local itemRate   = entryCfg.rate
			allRate = allRate + itemRate

			local itemData = {
				reward 		= LxDataHelper.ParseItem(entryCfg.reward),
				itemRate   	= itemRate,
			}
			self._gridRateData[entryId] = itemData
		end
	end
	self._allRate = allRate
end

function UIActMicBooksRatePop:InitCommand()
	local sid = self:GetWndArg("sid")
	local page = self:GetWndArg("page")
	self._sid = sid
	self._page = page
	self._pages = {}
	self._gridRateData = {}

	local pbData = gModelActivity:GetActivityPageBySid(sid)
	if pbData then
		self:ResetActivePageData(pbData)
		self:RefreshUI()
	else
		gModelActivity:OnActivityPageReq(sid)
	end
end

------------------------------------------------------------------
return UIActMicBooksRatePop


