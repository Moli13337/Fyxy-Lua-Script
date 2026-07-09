---
--- Created by Administrator.
--- DateTime: 2025/1/2 15:56:03
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineWeaponPass:LWnd
local UIDivineWeaponPass = LxWndClass("UIDivineWeaponPass", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineWeaponPass:UIDivineWeaponPass()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineWeaponPass:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineWeaponPass:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineWeaponPass:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)
	self:SetWndText(self.mCloseTip, ccClientText(41037))

	local id = self:GetWndArg("id")
	local cfg = gModelDivineWeaponFight:GetChapterCfgById(id)
	self:SetWndText(self.mText, string.replace(ccClientText(46218), ccLngText(cfg.name)))
end




------------------------------------------------------------------
return UIDivineWeaponPass