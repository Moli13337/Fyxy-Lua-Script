---
--- Created by Administrator.
--- DateTime: 2024/11/21 16:12:51
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UICrossGradingMatchTime:LWnd
local UICrossGradingMatchTime = LxWndClass("UICrossGradingMatchTime", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UICrossGradingMatchTime:UICrossGradingMatchTime()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UICrossGradingMatchTime:OnWndClose()
	if self.numTimer then
        LxTimer.LoopTimeStop(self.numTimer)
        self.numTimer = nil
    end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UICrossGradingMatchTime:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UICrossGradingMatchTime:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:CreateWndEffect(self.mEff, "fx_ui_duanweisai_pipei", "matchEff", 100)
	local wndSortOrder = self:GetWndSortOrder()
    local canvas = self.mNum:GetComponent(typeof(UnityEngine.Canvas))
	canvas.sortingOrder = wndSortOrder + 4
	self.matchTime = 0
	self:SetWndText(self.mNum, LUtil.FormatHurtNumSpriteText(self.matchTime) .. "<size=48><voffset=-100>" .. ccClientText(10355))
	self.numTimer = LxTimer.LoopTimeCall(function()
		self.matchTime = self.matchTime + 1
		self:SetWndText(self.mNum, LUtil.FormatHurtNumSpriteText(self.matchTime) .. "<size=48><voffset=-100>" .. ccClientText(10355))
	end, 1, true, -1)
end



------------------------------------------------------------------
return UICrossGradingMatchTime