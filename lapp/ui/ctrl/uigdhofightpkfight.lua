---
--- Created by Administrator.
--- DateTime: 2024/10/17 10:58:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightPkFight:LWnd
local UIGdHoFightPkFight = LxWndClass("UIGdHoFightPkFight", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightPkFight:UIGdHoFightPkFight()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightPkFight:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightPkFight:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightPkFight:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:InitTabList()
	self:ClickBotBtn(self.index)
end

function UIGdHoFightPkFight:ClickBotBtn(index)
	if self.CurSelBtn == index then
		return
	end
	local oldIndex = self.CurSelBtn
	self.CurSelBtn = index
	self:SetWndTabStatus(self.tabBtn[oldIndex], 1)
	self:SetWndTabStatus(self.tabBtn[index], 0)
	self:CloseAllChild()
	self:CreateChildWnd(self.mChildRoot, self.BotBtnData[index].childWnd, { id = self.id , pos = self.reportPos })
end

function UIGdHoFightPkFight:OnDrawTab(_, item, data, index)
	local On = CS.FindTrans(item,"On")
	local Off = CS.FindTrans(item,"Off")

	self:SetWndTabText(item, data.name)
	self:SetWndTabStatus(item, 1)
	self:SetWndEasyImage(On, data.icon)
	self:SetWndEasyImage(Off, data.icon)
	self.tabBtn[index] = item
	self:SetWndClick(item, function (...)
		self:ClickBotBtn(index)
	end)
end

function UIGdHoFightPkFight:InitTabList()
	self.tabList = self:GetUIScroll("TabScroll")
	self.tabList:Create(self.mTabScroll, self.BotBtnData, function(...) self:OnDrawTab(...) end)
end

function UIGdHoFightPkFight:InitCommon()
	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end)

	------------------------------------------------------------------
	---text
	self:SetWndText(self.mTxtClose, ccClientText(30205))
	self:SetWndText(self.mTitle, ccClientText(46002))

	------------------------------------------------------------------
	---member
	self.BotBtnData = {
		{
			name = ccClientText(46012),
			icon = "guildBattle_btn4",
			childWnd = "UISubGdHoFightPkActually"
		},
		{
			name = ccClientText(46013),
			icon = "actionarena_ting",
			childWnd = "UISubGdHoFightPkReport"
		},
	}
	self.tabBtn = {}
	self.id = self:GetWndArg("id")
	self.index = self:GetWndArg("index") or 1
	self.reportPos = self:GetWndArg("pos")
end



------------------------------------------------------------------
return UIGdHoFightPkFight