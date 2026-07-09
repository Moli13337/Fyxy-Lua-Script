---
--- Created by BY.
--- DateTime: 2023/10/2 14:08:28
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBulletSayListPop:LWnd
local UIBulletSayListPop = LxWndClass("UIBulletSayListPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBulletSayListPop:UIBulletSayListPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBulletSayListPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBulletSayListPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBulletSayListPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIBulletSayListPop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIBulletSayListPop:InitMessage()

end

function UIBulletSayListPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(17615))

	local channel = self:GetWndArg("channel")
	self._channel = channel
	local list = gModelChat:GetTypeInfo(channel)
	for i, v in ipairs(list) do
		v.index = i
	end
	table.sort(list,function (a,b)
		local at = a.sendTime or "0"
		local bt = b.sendTime or "0"
		return at > bt
	end)
	local uiList = self:GetUIScroll("barrageList")
	uiList:Create(self.mCellSuper,list,function (...) self:ListItem(...) end, UIItemList.SUPER)
end

function UIBulletSayListPop:OnClickReport(itempos)
	GF.OpenWnd("UIRepin",{channelId = self._channel, channelIndex = itempos})
end

function UIBulletSayListPop:ListItem(list, item, itemdata, itempos)
	local msgText = CS.FindTrans(item,"MsgText")
	local btnReport = CS.FindTrans(item,"BtnReport")
	local reportText = CS.FindTrans(item,"BtnReport/ReportText")

	local myId = gModelPlayer:GetPlayerId()
	local playerId = itemdata.playerId
	local isShowReport = myId ~= playerId
	self:SetWndText(reportText,ccClientText(17616))
	local msg = itemdata:GetMsg()
	self:SetWndText(msgText,LUtil.GetFaceStr(msg,32))

	CS.ShowObject(btnReport,isShowReport)
	self:SetWndClick(btnReport,function ()
		self:OnClickReport(itemdata.index)
	end)
end
------------------------------------------------------------------
return UIBulletSayListPop


