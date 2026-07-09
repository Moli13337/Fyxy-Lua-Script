---
--- Created by Administrator.
--- DateTime: 2023/10/8 15:52:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInviteListSow:LWnd
local UIInviteListSow = LxWndClass("UIInviteListSow", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInviteListSow:UIInviteListSow()
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInviteListSow:OnWndClose()
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInviteListSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInviteListSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()

	gModelActivity:OnActivityInvitationReq(ModelActivity.INVITATION_PLAYER_INFO,self._sid)
end

function UIInviteListSow:OnDrawPlayerCell(list,item,itemdata,itempos)
	local Head = self:FindWndTrans(item,"Head")
	local HeadIconTrans = self:FindWndTrans(Head,"HeadIcon")
	local PlayerName = self:FindWndTrans(item,"PlayerName")
	local ServerName = self:FindWndTrans(item,"ServerName")
	local PlayerLv = self:FindWndTrans(item,"PlayerLv")
	local VipLv = self:FindWndTrans(item,"VipLv")

	local playerId = itemdata._playerId
	local InstanceID = item:GetInstanceID()
	local playerInfo={
		trans = HeadIconTrans,
		playerId = playerId,
		icon = itemdata._head,
		headFrame = itemdata._headFrame,
		level = itemdata._grade,
		func = function()
			gModelGeneral:PlayerShowReq(playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
		end
	}
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	baseClass:SetHeadData(playerInfo)

	self:SetWndText(PlayerName,itemdata._name)

	--local serverNameStr = string.replace(ccClientText(20834),itemdata._serverName)
	local serverNameStr = string.replace(ccClientText(20834),itemdata._serverName)
	self:SetWndText(ServerName,serverNameStr)

	local playerLvStr = string.replace(ccClientText(20835),itemdata._grade)
	self:SetWndText(PlayerLv,playerLvStr)

	local vipLvStr = string.replace(ccClientText(20836),itemdata._vipLevel)
	self:SetWndText(VipLv,vipLvStr)
end

function UIInviteListSow:InitText()
	self:SetWndText(self.mTitleText,ccClientText(20822))
	self:SetWndText(self.mName,ccClientText(20823))
	self:SetWndText(self.mLv,ccClientText(17912))
	self:SetWndText(self.mVipLv,ccClientText(20825))
end

function UIInviteListSow:InitMsg()
	self:WndNetMsgRecv(LProtoIds.ActivityInvitationResp,function (pb)
		local sid = pb.sid
		if self._sid ~= sid then return end
		local opera = pb.opera
		if opera == ModelActivity.INVITATION_PLAYER_INFO then
			local invitation = pb.invitation
			local invitations = invitation.invitations
			self:InitList(invitations)
		end
	end)
end

function UIInviteListSow:InitData()
	self._sid = self:GetWndArg("sid")
end

function UIInviteListSow:InitPlayerList(list)
	local uiPlayerList = self._uiPlayerList
	if uiPlayerList then
		uiPlayerList:RefreshList(list)
	else
		uiPlayerList = self:GetUIScroll("uiPlayerList")
		self._uiPlayerList = uiPlayerList
		uiPlayerList:Create(self.mPlayerList,list,function(...) self:OnDrawPlayerCell(...) end,UIItemList.WRAP)
	end
end

function UIInviteListSow:InitList(invitations)
	local list = {}
	for i,v in ipairs(invitations) do
		local player = gModelGeneral:SetPlayerInfo(v)
		table.insert(list,player)
	end
	self:InitPlayerList(list)
end

function UIInviteListSow:InitEvent()
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

------------------------------------------------------------------
return UIInviteListSow


