---
--- Created by BY.
--- DateTime: 2023/10/23 15:47:21
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdApplyForPop:LWnd
local UIGdApplyForPop = LxWndClass("UIGdApplyForPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdApplyForPop:UIGdApplyForPop()
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdApplyForPop:OnWndClose()
	self:OnClickWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdApplyForPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdApplyForPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdApplyForPop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildApplyInfoResp,function (...)
		self:RefreshData()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildApplyProcessResp,function (pb)
		gModelGuild:OnGuildApplyInfoReq()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildMemberListResp,function (pb)
		self:RefreshData()
	end)
end

function UIGdApplyForPop:OnClickLose()
	if(not self._isNewApply)then
		GF.ShowMessage(ccClientText(12556))
	end
	gModelGuild:OnGuildApplyProcessReq(4)
end

function UIGdApplyForPop:ListItem(list,item, itemdata, itempos)
	local root = CS.FindTrans(item,"Root/")
	local headIcon = CS.FindTrans(item,"Root/HeadIcon")
	local nameText = CS.FindTrans(item,"Root/NameText")
	local powerText = CS.FindTrans(item,"Root/PowerBg_1/PowerText")
	local powerName = CS.FindTrans(item,"Root/PowerBg_1/PowerName")
	local consentBtn = CS.FindTrans(item,"Root/BtnYellow3")
	local timeText = CS.FindTrans(item,"Root/TimeText")

	local timeStr = ""
	if(itemdata._playerState==1)then
		timeStr = ccClientText(12008)
	else
		local time = GetTimestamp()
		timeStr = string.replace(ccClientText(12561),LUtil.FormatTimeToMin(time-itemdata._lastLogoutTime/1000))
	end

	local playerData = {
		trans = headIcon,
		icon = itemdata._head,
		headFrame = itemdata._headFrame,
		level = itemdata._grade,
	}

	local uiheadlist = self._uiheadList
	local InstanceID = item:GetInstanceID()
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerData)
	baseClass:RefreshUI()

	self:SetWndText(nameText,itemdata._name)
	self:SetWndText(powerText,LUtil.NumberCoversion(itemdata._power))
	self:SetWndText(powerName,ccClientText(12623))
	self:SetWndButtonText(consentBtn,ccClientText(12478))
	self:SetWndText(timeText,timeStr)
	self:SetWndClick(root, function(...) self:OnClickHeadIcon(itemdata) end)
	self:SetWndClick(headIcon, function(...) self:OnClickHeadIcon(itemdata) end)
	self:SetWndClick(consentBtn, function(...) self:OnClickOnConsent(itemdata) end)
end

function UIGdApplyForPop:OnClickHeadIcon(playerInfo)
	gModelGeneral:PlayerShowReq(playerInfo._playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end

function UIGdApplyForPop:RefreshData()
	local list=gModelGuild:GetApplyPlayerInfoList()
	local _isNewApply = #list > 0
	self._isNewApply = _isNewApply
	CS.ShowObject(self.mNoRecord,not _isNewApply)
	if not _isNewApply then
		self:CreateEmptyShow(4003)
	end
	if(self._uiList)then
		self._uiList:RefreshList(list)
	else
		self._uiList = self:GetUIScroll("_uiList")
		self._uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end, UIItemList.WRAP)
	end
end

function UIGdApplyForPop:OnClickWndClose()
	local callFunc = self._callFunc
	if callFunc then
		callFunc()
	end
	self:WndClose()
end

function UIGdApplyForPop:InitCommand()
	self._callFunc = self:GetWndArg("callFunc")
	self:SetWndText(self.mTitleText,ccClientText(12481))
	self:SetWndButtonText(self.mLoseBtn,ccClientText(12479))
	self:SetWndButtonText(self.mConsentBtn,ccClientText(12480))
	gModelGuild:OnGuildApplyInfoReq()
end

function UIGdApplyForPop:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty")
	emptyList:RefreshUI(data)
end

function UIGdApplyForPop:OnClickOnConsent(itemdata)
	gModelGuild:OnGuildApplyProcessReq(1 , itemdata._playerId)
end

function UIGdApplyForPop:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mConsentBtn, function(...) self:OnClickConsent() end)
	self:SetWndClick(self.mLoseBtn, function(...) self:OnClickLose() end)
end

function UIGdApplyForPop:OnClickConsent()
	if(not self._isNewApply)then
		GF.ShowMessage(ccClientText(12556))
	end
	gModelGuild:OnGuildApplyProcessReq(3)
end
------------------------------------------------------------------
return UIGdApplyForPop


