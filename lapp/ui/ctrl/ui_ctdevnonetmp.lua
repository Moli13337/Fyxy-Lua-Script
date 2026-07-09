---
--- Created by By.
--- DateTime: 2023/10/7 20:39:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UI_CTDevNoneTmp:LWnd
local UI_CTDevNoneTmp = LxWndClass("UI_CTDevNoneTmp", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UI_CTDevNoneTmp:UI_CTDevNoneTmp()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UI_CTDevNoneTmp:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UI_CTDevNoneTmp:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UI_CTDevNoneTmp:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetWndClick(self.mTestgcObj, function ()
		--LResRelease.CallBackClearUnusedAndGC(nil,true)
	end)

	self:SetWndClick(self.mTestinittmpObj, function ()
		CS.ClearAllBundle(true, function()
			CS.InitTextMesh()
		end)

	end)

	self:SetWndClick(self.mTestrebootObj, function ()
		LGame.TryReboot()
	end)
end



------------------------------------------------------------------
return UI_CTDevNoneTmp


