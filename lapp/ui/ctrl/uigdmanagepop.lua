---
--- Created by BY.
--- DateTime: 2023/10/22 16:14:49
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdManagePop:LWnd
local UIGdManagePop = LxWndClass("UIGdManagePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdManagePop:UIGdManagePop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdManagePop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdManagePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdManagePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdManagePop:OnClickOver()--转让
	if( not gModelGuild:GetAssignCDRByTime())then
		return
	end
	local playerId= self._guildMemberInfo.info._playerId
	local position=1
	local taposition=self._guildMemberInfo.position
	local positionStr
	if(taposition==2)then
		positionStr=ccClientText(12513)
	else
		positionStr=ccClientText(12406)
	end
	GF.OpenWnd("UIOrdinTip",{refId=100004,para={self._guildMemberInfo.info._name,positionStr},func=function ()
		gModelGuild:OnGuildPositionChangeReq(playerId , position)
	end})
end

function UIGdManagePop:OnClickOut()--剔除
	local playerId= self._guildMemberInfo.info._playerId
	GF.OpenWnd("UIOrdinTip",{refId=100005,para={self._guildMemberInfo.info._name},func=function ()
		gModelGuild:OnDeletGuildMemberReq(playerId )
	end})
end

function UIGdManagePop:InitMessage()
	self:WndNetMsgRecv(LProtoIds.GuildPositionChangeResp,function (pb)
		if(pb.position==1)then
			GF.ShowMessage(ccClientText(12514))
		elseif(pb.position==2)then
			GF.ShowMessage(ccClientText(12515))
		else
			GF.ShowMessage(ccClientText(12516))
		end
		self:WndClose()
	end)
	self:WndNetMsgRecv(LProtoIds.DeletGuildMemberResp,function (pb)
		self:WndClose()
	end)
	self:WndNetMsgRecv(LProtoIds.GuildChangeResp,function (pb)
		self:WndClose()
	end)
end

function UIGdManagePop:OnClickAppoint()--任命
	local playerId= self._guildMemberInfo.info._playerId
	gModelGuild:OnGuildPositionChangeReq(playerId , ModelGuild.GUILD_VICE_CHAIRMAN)
end

function UIGdManagePop:OnClickSetFree()--罢免
	local playerId= self._guildMemberInfo.info._playerId
	gModelGuild:OnGuildPositionChangeReq(playerId , ModelGuild.GUILD_MEMBER)
end

function UIGdManagePop:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mOverBtn, function(...) self:OnClickOver() end)
	self:SetWndClick(self.mOutBtn, function(...) self:OnClickOut() end)
	self:SetWndClick(self.mAppointBtn, function(...) self:OnClickAppoint() end)
	self:SetWndClick(self.mSetFreeBtn, function(...) self:OnClickSetFree() end)
end

function UIGdManagePop:InitCommand()
	local guildInfo=gModelGuild:GetGuildInfo()
	local selfInfo= gModelGuild:GetSelfGuildInfo()
	self._guildMemberInfo=self:GetWndArg("guildMemberInfo")
	local _position=selfInfo.position


	self:SetWndButtonText(self.mOutBtn,ccClientText(12426))
	self:SetWndButtonText(self.mOverBtn,ccClientText(12424))
	self:SetWndButtonText(self.mAppointBtn,ccClientText(12425))
	self:SetWndButtonText(self.mSetFreeBtn,ccClientText(12512))


	self:SetWndText(self.mManageText,string.replace(ccClientText(12422),self._guildMemberInfo.info._name))
	self:SetWndText(self.mTitleText,ccClientText(12423))

	if(_position==1)then
		CS.ShowObject(self.mOverBtn,true)
		if(self._guildMemberInfo.position==2)then
			CS.ShowObject(self.mSetFreeBtn,true)
		else
			CS.ShowObject(self.mAppointBtn,true)
		end
	end
	CS.ShowObject(self.mOutBtn,true)
end

------------------------------------------------------------------
return UIGdManagePop


