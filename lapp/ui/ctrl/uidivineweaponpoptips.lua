---
--- Created by Administrator.
--- DateTime: 2024/12/16 19:46:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDivineWeaponPopTips:LWnd
local UIDivineWeaponPopTips = LxWndClass("UIDivineWeaponPopTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDivineWeaponPopTips:UIDivineWeaponPopTips()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDivineWeaponPopTips:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDivineWeaponPopTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDivineWeaponPopTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	local id = self:GetWndArg("refId")
	local ref = gModelDivineWeapon:GetDivineWeaponRef(id)
	self:SetWndEasyImage(self.mDivineIcon,ref.icon)
	local itemDesc = gModelItem:GetDescByRefId(ref.item)
	self:SetWndText(self.mDivineDesc,itemDesc or "")
	self:SetWndText(self.mDivineName,ccLngText(ref.name))
	self:SetWndClick(self.mMask,function() self:WndClose() end)
end



------------------------------------------------------------------
return UIDivineWeaponPopTips