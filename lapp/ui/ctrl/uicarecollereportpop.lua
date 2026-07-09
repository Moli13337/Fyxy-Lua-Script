---
--- Created by BY.
--- DateTime: 2023/10/12 17:06:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UICareColleReportPop:LWnd
local UICareColleReportPop = LxWndClass("UICareColleReportPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UICareColleReportPop:UICareColleReportPop()
	self._tabTrans = {}
	self._reqRefIds = {}
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UICareColleReportPop:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UICareColleReportPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UICareColleReportPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
---------------------------------------------------------------------------------------------
function UICareColleReportPop:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UICareColleReportPop:ListItem(list, item, itemdata, itempos)
	local hurtText = self:FindWndTrans(item, "AniRoot/HurtText")
	local nameText = self:FindWndTrans(item, "AniRoot/NameText")
	local headIcon = self:FindWndTrans(item, "AniRoot/HeadIcon")
	local btnLook = self:FindWndTrans(item, "AniRoot/BtnLook")
	local lookText = self:FindWndTrans(item, "AniRoot/BtnLook/LookText")
	local powerText = self:FindWndTrans(item, "AniRoot/PowerBg_1/PowerText")
	local InstanceID = item:GetInstanceID()

	local info = {
		trans = headIcon,
		icon = gModelPlayer:GetPlayerHead(),
		headFrame = gModelPlayer:GetPlayerHeadFrame(),
		level = gModelPlayer:GetPlayerLv(),
	}
	self:SetHeadIcon(info,InstanceID)

	self:SetWndText(hurtText,string.replace(ccClientText(20919),LUtil.NumberCoversion(tonumber(itemdata.hurt))))
	self:SetWndText(nameText,gModelPlayer:GetPlayerName())
	self:SetWndText(lookText,ccClientText(20920))
	self:SetWndText(powerText,LUtil.NumberCoversion(tonumber(itemdata.power)))
	self:SetWndClick(btnLook,function ()
		self:OnClickLook(itemdata)
	end)
end

function UICareColleReportPop:OnClickTab(refId)
	if(self._refId)then
		if(self._refId == refId)then
			return
		end
		local trans = self._tabTrans[self._refId]
		self:SetWndTabStatus(trans, 1)
	end
	local trans = self._tabTrans[refId]
	self:SetWndTabStatus(trans, 0)
	self._refId = refId
	if self._reqRefIds[refId] then
		self:RefreshData()
	else
		self._reqRefIds[refId] = true
		gModelCareSchool:OnCollegeReportReq(refId)
	end
end

--设置玩家头像
function UICareColleReportPop:SetHeadIcon(info,key)
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[key]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[key] = baseClass
	end
	baseClass:SetHeadData(info)
end

function UICareColleReportPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.CollegeReportResp,function (...)
		self:RefreshData()
	end)
end

function UICareColleReportPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
end

function UICareColleReportPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(20918))

	local list = gModelCareSchool:GetCollegeSimulationRefList()
	local _tabList = self:GetUIScroll("tabList")
	_tabList:Create(self.mTabScroll,list,function (...) self:TabListItem(...) end)

	self:OnClickTab(list[1].refId)
end

function UICareColleReportPop:OnClickLook(itemdata)
	local ref = gModelCareSchool:GetCollegeSimulationRefByRefId(itemdata.refId)
	if not ref then
		return
	end
	local extraData = {}
	extraData.combatType = LCombatTypeConst.COMBAT_TACTICAL_SIMULATION
    extraData.isShare = true
	extraData.hurt = LUtil.NumberCoversion(tonumber(itemdata.hurt))
	extraData.refId = self._refId
	extraData.battleName = ccLngText(ref.name)
	local reportId = itemdata.reportId
	gLFightManager:OnOpenBattleDetails(reportId,extraData)
end

function UICareColleReportPop:TabListItem(list, item, itemdata, itempos)
	local btnTab = self:FindWndTrans(item,"BtnTab1")
	self:SetWndTabText(btnTab,ccLngText(itemdata.name), -4)
	self:SetWndTabStatus(btnTab, 1)
	self._tabTrans[itemdata.refId] = btnTab

	self:SetWndClick(item, function (...) self:OnClickTab(itemdata.refId) end,LSoundConst.CLICK_PAGE_COMMON)
end

function UICareColleReportPop:RefreshData()
	local _refId = self._refId
	local list = gModelCareSchool:GetCollegeReportByRefId(_refId)
	local len = #list
	CS.ShowObject(self.mNoRecord2,len <= 0)
	if len <= 0 then
		self:CreateEmptyShow(9008)

	else
		table.sort(list,function(a, b) return tonumber(a.crateTime)> tonumber(b.crateTime) end)
	end



	local _uiList = self._uiList
	if(_uiList)then
		_uiList:RefreshList(list)
	else
		_uiList = self:GetUIScroll("uiList")
		_uiList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end, UIItemList.SUPER)
		self._uiList = _uiList
		_uiList:EnableScroll(true,false)
	end
	_uiList:DrawAllItems()
end
------------------------------------------------------------------
return UICareColleReportPop


