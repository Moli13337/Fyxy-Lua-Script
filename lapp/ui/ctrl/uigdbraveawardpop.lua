---
--- Created by BY.
--- DateTime: 2023/10/15 16:41:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdBraveAwardPop:LWnd
local UIGdBraveAwardPop = LxWndClass("UIGdBraveAwardPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdBraveAwardPop:UIGdBraveAwardPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdBraveAwardPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdBraveAwardPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdBraveAwardPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIGdBraveAwardPop:ListItem(list,item, itemdata, itempos)
	local titleText= CS.FindTrans(item,"Image/TitleText")
	local itemScroll= CS.FindTrans(item,"ItemScroll")
	self:SetWndText(titleText,itemdata.name)
	local list = gModelGuild:GetGuildDungeonMonsterRefAwardByRefId(self._refId,itemdata.type)

	local InstanceID = item:GetInstanceID()
	local uiIconEasyList = self._uiList:GetItemCls(InstanceID)
	if not uiIconEasyList then
		uiIconEasyList = UIIconEasyList:New()
		self._uiList:SetItemCls(InstanceID, uiIconEasyList)
		uiIconEasyList:Create(self, itemScroll)
	end
	uiIconEasyList:RefreshList(list)
end

function UIGdBraveAwardPop:InitCommand()
	self._refId=self:GetWndArg("refId")
	self:SetWndText(self.mTitleText,ccClientText(14105))
	local list={
		{name=ccClientText(14113),type=1},
		{name=ccClientText(14114),type=2},
		{name=ccClientText(14115),type=3},
	}
	if(self._uiList)then
		self._uiList:RefreshList(list)
	else
		self._uiList = self:GetUIScroll("_uiList")
		self._uiList:Create(self.mCellScroll,list,function (...) self:ListItem(...) end)
	end
end

function UIGdBraveAwardPop:InitMessage()
	--self:WndNetMsgRecv(LProtoIds.TowerStateRewardResp,function (...)
	--	self:RefreshData()
	--end)
end

function UIGdBraveAwardPop:InitEvent()
	self:SetWndClick(self.mBtnClose, function(...)
		self:WndClose()
	end)
	self:SetWndClick(self.mBgImage, function(...)
		self:WndClose()
	end)
end
------------------------------------------------------------------
return UIGdBraveAwardPop


