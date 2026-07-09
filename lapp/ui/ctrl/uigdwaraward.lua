---
--- Created by BY.
--- DateTime: 2023/10/14 16:59:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdWarAward:LWnd
local UIGdWarAward = LxWndClass("UIGdWarAward", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdWarAward:UIGdWarAward()
	self:SetHideHurdle()
	self._iconEasyListTbl = {}
	self._tabTrans = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdWarAward:OnWndClose()
	self:ClearCommonIconList(self._iconEasyListTbl)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdWarAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdWarAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UIGdWarAward:InitCommand()
	--self:SetWndText(self.mTitleText,ccClientText())
	local list = {
		{type = 1,name = ccClientText(17942)},
		{type = 2,name = ccClientText(17943)},
	}
	self._list = list
	local _tabList = self:GetUIScroll("_tabList")
	_tabList:Create(self.mTabScroll,list,function (...) self:TabListItem(...) end)
	self:OnClickTab(list[1].type)
end

function UIGdWarAward:TabListItem(list, item, itemdata, itempos)
	local btnTab = CS.FindTrans(item,"BtnTab3")
	self:SetWndTabText(btnTab,itemdata.name)
	self:SetWndTabStatus(btnTab, 1)
	self._tabTrans[itemdata.type] = btnTab

	self:SetWndClick(item, function (...) self:OnClickTab(itemdata.type) end,LSoundConst.CLICK_PAGE_COMMON)
end

function UIGdWarAward:InitEvent()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function () self:WndClose() end)
	self:SetWndClick(self.mCloseBtn, function (...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIGdWarAward:RefreshAwardPage()
	local list = gModelGuildMelee:GetGuildBattleRewardRefByType(self._type)
	if(self._uiAwardList)then
		self._uiAwardList:RefreshList(list)
	else
		self._uiAwardList = self:GetUIScroll("rankAward")
		self._uiAwardList:Create(self.mAwardScroll,list,function (...) self:ListItem(...) end,UIItemList.WRAP)
	end
end

function UIGdWarAward:OnClickTab(type)
	if(self._type)then
		local trans = self._tabTrans[self._type]
		self:ChangeTab(trans,false)
	end
	local trans = self._tabTrans[type]
	self:ChangeTab(trans,true)
	self._type = type
	self:SetWndText(self.mTitleText,self._list[type].name)
	self:InitTextSizeWithLanguage(self.mTitleText, -2)
	self:InitTextLineWithLanguage(self.mTitleText, -50)
	local desStr = ""
	if type == 1 then
		desStr = ccClientText(17944)
	else
		desStr = ccClientText(17967)
	end
	self:SetWndText(self.mDesText,desStr)
	self:InitTextSizeWithLanguage(self.mDesText, -2)
	self:InitTextLineWithLanguage(self.mDesText, -30)
	self:RefreshAwardPage()
end

function UIGdWarAward:ChangeTab(trans,bool)
	local state = bool and 0 or 1
	self:SetWndTabStatus(trans, state)
end

function UIGdWarAward:ListItem(list, item, itemdata, itempos)--设置排行cell	index:1=其他，2=自己
	local rankIcon = CS.FindTrans(item,"RankIcon")
	local rankText = CS.FindTrans(item,"RankText")
	local awardScroll = CS.FindTrans(item,"AwardScroll")

	local rankArr = string.split(itemdata.rank,",")
	local rank = tonumber(rankArr[1])
	local rankStr = ""
	if(rankArr[1] == rankArr[2])then
		rankStr = rankArr[1]
	else
		local num2 = rankArr[2]
		if(rankArr[2] == "-1")then
			num2 = "∞"
		end
		if num2 == "∞" or tonumber(num2) >= 100 then
			num2 = "\n"..num2
		end
		rankStr = string.replace(ccClientText(11714),rankArr[1],num2)
	end
	if(rank >= 1 and rank<=3)then
		CS.ShowObject(rankIcon,true)
		CS.ShowObject(rankText,false)
		local iconStr = "public_num_3"
		if(rank == 1)then
			iconStr = "public_num_1"
		elseif(rank == 2)then
			iconStr = "public_num_2"
		end
		self:SetWndEasyImage(rankIcon,iconStr)
	else
		CS.ShowObject(rankIcon,false)
		CS.ShowObject(rankText,true)
		self:SetWndText(rankText,rankStr)
	end

	local reward1List = LxDataHelper.ParseItem(itemdata.reward)
	local InstanceID = item:GetInstanceID()
	local uiList = self._iconEasyListTbl[InstanceID]
	if not uiList then
		uiList = UIIconEasyList:New()
		self._iconEasyListTbl[InstanceID] = uiList
		uiList:Create(self, awardScroll)
		uiList:SetIconParentPath("Root/CommonUI/Icon")
	end
	uiList:RefreshList(reward1List)
end
------------------------------------------------------------------
return UIGdWarAward


