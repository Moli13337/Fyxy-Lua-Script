---
--- Created by Administrator.
--- DateTime: 2024/11/5 15:38:56
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGameHelperDaily:LChildWnd
local UISubGameHelperDaily = LxWndClass("UISubGameHelperDaily", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGameHelperDaily:UISubGameHelperDaily()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGameHelperDaily:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGameHelperDaily:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGameHelperDaily:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:SetDaily()
end

function UISubGameHelperDaily:SetDailyTrans(trans, data)
    local on = CS.FindTrans(trans, "On")
    local onTitle = CS.FindTrans(on, "Title")
    local onDes = CS.FindTrans(on, "Des")
    local off = CS.FindTrans(trans, "Off")
    local offTitle = CS.FindTrans(off, "Title")
    local offDes = CS.FindTrans(off, "Des")

	self:SetWndText(onTitle, ccLngText(data.name))
    self:SetWndText(offTitle, ccLngText(data.name))
	self:SetWndText(onDes, ccLngText(data.desd))
	self:SetWndText(offDes, ccLngText(data.desd1))

	local isOpen = gModelGameHelper:CheckIsOpen(data.open)
    CS.ShowObject(on, isOpen)
    CS.ShowObject(off, not isOpen)
end

function UISubGameHelperDaily:SetDaily()
	local cfg = GameTable.AssistantListRef
	local t = {
		{
			cfg = cfg[101],
			trans = self.mSummonObj
		},
		{
			cfg = cfg[102],
			trans = self.mLikeObj
		},
		{
			cfg = cfg[103],
			trans = self.mGiftObj
		},
		{
			cfg = cfg[104],
			trans = self.mFriendObj
		},
		{
			cfg = cfg[106],
			trans = self.mInvasionBossObj
		},
	}
	for _, v in ipairs(t) do
		self:SetDailyTrans(v.trans, v.cfg)
	end
end

function UISubGameHelperDaily:InitCommon()
	------------------------------------------------------------------
	---member
	self.id = self:GetWndArg("id")
	local cfg = GameTable.AssistantTabRef[self.id]
	------------------------------------------------------------------
	---text
	self:SetTextTile(self.mTitle, ccLngText(cfg.name) .. ccClientText(24228))
end


------------------------------------------------------------------
return UISubGameHelperDaily