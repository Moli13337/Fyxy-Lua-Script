---
--- Created by BY.
--- DateTime: 2023/10/8 21:03:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdBraveBossLog:LWnd
local UIGdBraveBossLog = LxWndClass("UIGdBraveBossLog", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdBraveBossLog:UIGdBraveBossLog()
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdBraveBossLog:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdBraveBossLog:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdBraveBossLog:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self._isVie =gLGameLanguage:IsVieVersion()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdBraveBossLog:CreateEmptyShow(refId)
	local data = {
		refId = refId,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("_empty1")
	emptyList:RefreshUI(data)
end

function UIGdBraveBossLog:OnClickPlayer(playerId)
	gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end
function UIGdBraveBossLog:InitCommand()
	self:SetWndText(self.mTitleText,ccClientText(32711))

	gModelGuildBoss:OnGuildNewBraveLogReq()
end

function UIGdBraveBossLog:ListItem(list, item, itemdata, itempos)
	local root = self:FindWndTrans(item,"Root")
	local headIcon = self:FindWndTrans(root,"HeadIcon")
	local nameText = self:FindWndTrans(root,"NameText")
	local numText = self:FindWndTrans(root,"NumText")
	local timeText = self:FindWndTrans(root,"TimeText")
	local leve =CS.FindTrans(root,"HeadIcon/lvBg/level")
	if self._isVie then
		self:SetAnchorPos(leve,Vector2.New(0,-8))
	end
	local info = itemdata.info
	local hurt = itemdata.hurt
	local time = itemdata.time

	local InstanceID = item:GetInstanceID()
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	local data = {
		icon = info.head,
		headFrame = info.headFrame,
		level = info.grade,
	}
	data.trans = headIcon
	baseClass:SetHeadData(data)
	self:SetWndText(nameText,info.name)
	self:SetWndText(numText,string.replace(ccClientText(32712),hurt))
	local timeStr = gModelFriend:GetStateTime(time)
	self:SetWndText(timeText,timeStr)
	self:SetWndClick(headIcon, function (...)
		self:OnClickPlayer(info.playerId)
	end)
end

function UIGdBraveBossLog:RefreshData()
	local list = gModelGuildBoss:GetGuildBraveLogInfo()

	CS.ShowObject(self.mNoRecord3,#list <= 0)
	if #list <= 0 then
		self:CreateEmptyShow(4001)
	else
		table.sort(list,function (a,b)
			return a.time > b.time
		end)
	end
	local logUiList = self._logUiList
	if logUiList then
		logUiList:RefreshList(list)
		logUiList:DrawAllItems()
	else
		logUiList = self:GetUIScroll("skillUiList")
		logUiList:Create(self.mLogSuper,list,function(...) self:ListItem(...) end,UIItemList.SUPER)
		self._logUiList = logUiList
	end
end

function UIGdBraveBossLog:InitEvent()
	self:SetWndClick(self.mBgImage,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)
end
function UIGdBraveBossLog:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildNewBraveLogResp,function(pb) self:RefreshData() end)
end
------------------------------------------------------------------
return UIGdBraveBossLog


