---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIBtUpte:LWnd
local UIBtUpte = LxWndClass("UIBtUpte", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIBtUpte:UIBtUpte()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIBtUpte:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIBtUpte:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIBtUpte:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._progress = 0
	self._rtProgress = self:UIProgressFind(self.mBar, "barProgress",self._progress)
	self._rtProgress:SetProgress(self._progress)
end

function UIBtUpte:EndUpdate()
	GF.OpenWnd("UIBtLogin")
end

function UIBtUpte:StartCheckUpdate()

end

------------------------------------------------------------------
return UIBtUpte


