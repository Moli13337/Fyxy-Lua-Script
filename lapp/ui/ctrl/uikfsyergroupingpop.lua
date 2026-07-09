---
--- Created by BY.
--- DateTime: 2023/10/7 16:17:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKfSyerGroupingPop:LWnd
local UIKfSyerGroupingPop = LxWndClass("UIKfSyerGroupingPop", LWnd)

UIKfSyerGroupingPop.TYPE_GUILDMELEE = 1
UIKfSyerGroupingPop.TYPE_CROSSGRADING = 2
UIKfSyerGroupingPop.TYPE_SIMULATE = 3   ---奥兹模拟战
UIKfSyerGroupingPop.TYPE_DARK_WAR = 4   ---暗黑战争
UIKfSyerGroupingPop.TYPE_GUILD_FEUDAL = 5	--联盟领主
UIKfSyerGroupingPop.TYPE_CORSS_WAR = 6 --女神之争

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKfSyerGroupingPop:UIKfSyerGroupingPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKfSyerGroupingPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKfSyerGroupingPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKfSyerGroupingPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


    self:InitEvent()
	self:InitUIEvent()

	local wndType = self:GetWndArg("wndType") or UIKfSyerGroupingPop.TYPE_GUILDMELEE

    self._wndType = wndType
	if wndType == UIKfSyerGroupingPop.TYPE_SIMULATE then
		self:ShowSimulateContent()
	else
		self:InitCommand()
	end

end

function UIKfSyerGroupingPop:ShowSimulateContent()
	local str =ccClientText(25297) --"参赛服务器"
	self:SetWndText(self.mLblBiaoti,str)

	self._serverList = self:GetWndArg("serverList")
	local groupId = self:GetWndArg("group")
	local str = string.replace(ccClientText(25166),groupId)
	self:SetWndText(self.mTitleText,str)

	self:RefreshContent()
end

function UIKfSyerGroupingPop:ListItem(list, item, itemdata, itempos)
	local text = CS.FindTrans(item,"UIText")
	self:SetWndText(text,itemdata.serverName)
end

function UIKfSyerGroupingPop:InitEvent()
    if self._wndType ==  UIKfSyerGroupingPop.TYPE_SIMULATE then
        self:WndNetMsgRecv(LProtoIds.SimulateGroupResp,function (pb) self:OnSimulateDataRet(pb) end)
    end
end

function UIKfSyerGroupingPop:RefreshContent()
	local serverList = self._serverList or {}

	local isScrollTwo = self._wndType == UIKfSyerGroupingPop.TYPE_DARK_WAR
	local root = isScrollTwo and self.mCellScrollTwo or self.mCellScroll

	CS.ShowObject(self.mCellScrollTwo ,isScrollTwo)
	CS.ShowObject(self.mCellScroll ,not isScrollTwo)

	self:CreateUIScrollImpl("serverList",root,serverList,function (...) self:ListItem(...) end,UIItemList.SUPER_GRID)

    local len = #serverList
    local isEnableScroll = len > 10
	local list = self:FindUIScroll("serverList")
	if list then
		list:EnableScroll(isEnableScroll)
	end
end

function UIKfSyerGroupingPop:InitUIEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
end

function UIKfSyerGroupingPop:InitCommand()
	local wndType = self._wndType

	self:SetWndText(self.mLblBiaoti,ccClientText(17980))


	local list={}
	local id
	local showGroup = true
	if wndType == UIKfSyerGroupingPop.TYPE_GUILDMELEE then
		id = gModelGuildMelee:GetGuildBattleGroupId()
		list = gModelGuildMelee:GetServers()
	elseif wndType == UIKfSyerGroupingPop.TYPE_CROSSGRADING then
		id = self:GetWndArg("groupId")
		list = self:GetWndArg("serverList")
	elseif wndType == UIKfSyerGroupingPop.TYPE_DARK_WAR then
		list = self:GetWndArg("serverList")
		showGroup = false
	elseif UIKfSyerGroupingPop.TYPE_GUILD_FEUDAL == wndType then
		id = gModelGuildFeudal:GetGuildBattleGroupId()
		list = gModelGuildFeudal:GetServers()
	elseif wndType == UIKfSyerGroupingPop.TYPE_CORSS_WAR then
		id = self:GetWndArg("groupId")
		list = self:GetWndArg("serverList")
	end

	if showGroup then
		self:SetWndText(self.mTitleText,string.replace(ccClientText(17981),id))
	end
	CS.ShowObject(self.mTitleText,showGroup)

    self._serverList = list
	self:RefreshContent()
end


------------------------------------------------------------------
return UIKfSyerGroupingPop


