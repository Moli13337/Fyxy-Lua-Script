---
--- Created by Administrator.
--- DateTime: 2024/4/17 21:36:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdUnBargainMember:LWnd
local UIGdUnBargainMember = LxWndClass("UIGdUnBargainMember", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdUnBargainMember:UIGdUnBargainMember()
	self.playerOnlineIds = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdUnBargainMember:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdUnBargainMember:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdUnBargainMember:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitText()
	gModelGuild:OnGuildNotBargainMemberListReq()
end

function UIGdUnBargainMember:InitText()
	self:SetWndText(self.mTitle, ccClientText(12632))
	self:SetWndText(self.mLeftTitle, ccClientText(12636))
	self:SetWndText(self.mRightTitle, ccClientText(12637))
	local cfg = gModelGeneral:GetEmptyCfg(4006)
    self:SetWndText(self.mEmptyText, ccLngText(cfg.text))
end

function UIGdUnBargainMember:OnGuildNotBargainMemberListResp()
	local list = gModelGuild:GetUnBargainMemberInfo()
	local t = {}
	for _, v in ipairs(list) do
		table.insert(t, v.info.playerId)
	end
	gModelChat:PlayerOnlineReq(t, "3")
end

function UIGdUnBargainMember:UpdataList()
	local list = gModelGuild:GetUnBargainMemberInfo()
	CS.ShowObject(self.mNoRecord2, #list == 0)
	if not self.unBargainList then
		self.unBargainList = self:GetUIScroll("mUnBargainList")
		self.unBargainList:Create(self.mUnBargainList, list, function(...) self:DrawUnBargainItem(...) end, UIItemList.SUPER)
	else
		self.unBargainList:RefreshList(list)
	end
end

function UIGdUnBargainMember:DrawUnBargainItem(_, item, data)
	local aniRoot = self:FindWndTrans(item, "AniRoot")
	local nameText = self:FindWndTrans(aniRoot, "NameText")
	local text = self:FindWndTrans(aniRoot, "Text")

	local playerInfoOn = {
		_lastLogoutTime = data.info.lastLogoutTime,
		_playerState = self.playerOnlineIds[data.info.playerId] and 1 or 0
	}
	self:SetWndText(nameText, data.info.name)
	self:SetWndText(text, gModelFriend:GetLastLogoutTime(playerInfoOn))

	self:SetWndClick(
		aniRoot,
		function()
			gModelGeneral:PlayerShowReq(
				data.info.playerId,
				LCombatTypeConst.COMBAT_MAIN,
				LPlayerShowConst.OTHER_SYSTEM
			)
		end
	)
end

function UIGdUnBargainMember:InitEvent()
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)
	self:SetWndClick(self.mMask, function() self:WndClose() end)

	self:WndEventRecv("OnGuildNotBargainMemberListResp", function() self:OnGuildNotBargainMemberListResp() end)
	self:WndNetMsgRecv(LProtoIds.PlayerOnlineResp, function(pb)
		local playerIdList = pb.playerIdList
		local moreInfo = pb.moreInfo
		if moreInfo ~= "3" then return end
		self.playerOnlineIds = {}
		for _, v in ipairs(playerIdList) do
			self.playerOnlineIds[v] = true
		end
		self:UpdataList()
	end)
end


------------------------------------------------------------------
return UIGdUnBargainMember