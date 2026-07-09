---
--- Created by Administrator.
--- DateTime: 2024/8/9 14:41:42
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIInviteActPYList:LWnd
local UIInviteActPYList = LxWndClass("UIInviteActPYList", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIInviteActPYList:UIInviteActPYList()
	self.uiHeadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIInviteActPYList:OnWndClose()
	self:ClearCommonIconList(self.uiHeadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIInviteActPYList:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIInviteActPYList:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:InitList()
end

function UIInviteActPYList:SetHeadIcon(trans, data)
	local InstanceID = trans:GetInstanceID()
	local playerInfo = {
		trans = trans,
		playerId = data.playerId,
		icon = data.head,
		headFrame = data.headFrame,
		level = data.grade,
	}
	if not self.uiHeadList[InstanceID] then
		self.uiHeadList[InstanceID] = HeadIcon:New(self)
	end
	self.uiHeadList[InstanceID]:SetHeadData(playerInfo)
	self:SetWndClick(trans, function()
		gModelGeneral:PlayerShowReq(data.playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
	end)
end

function UIInviteActPYList:DrawList(_, item, data)
	local headIcon = CS.FindTrans(item, "HeadIcon")
	local name = CS.FindTrans(item, "Name")
	local powerText = CS.FindTrans(item, "PowerBg/PowerText")
	local vipTex = CS.FindTrans(item, "vipObj/vipTex")

	self:SetHeadIcon(headIcon, data)
	self:SetWndText(name, data.name)
	self:SetWndText(powerText, data.power)
	self:SetWndText(vipTex, data.vipLevel)
end

function UIInviteActPYList:InitList()
	local list = self:GetWndArg(1)
	local uiList = self:GetUIScroll("mList")
	uiList:Create(self.mList, list, function(...) self:DrawList(...) end, UIItemList.SUPER)
end

function UIInviteActPYList:InitCommon()
	-----------------------------------------------
	--event
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end)

	-----------------------------------------------
	--Text
	self:SetWndText(self.mLblBiaoti, ccClientText(20829))
	self:SetWndText(self.mFriendName, ccClientText(20877))
	self:SetWndText(self.mForceText, ccClientText(12623))
	self:SetWndText(self.mVipText, ccClientText(20825))
end



------------------------------------------------------------------
return UIInviteActPYList