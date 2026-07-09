---
--- Created by By.
--- DateTime: 2023/10/9 16:20:43
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UI_CTDevTestShare:LWnd
local UI_CTDevTestShare = LxWndClass("UI_CTDevTestShare", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UI_CTDevTestShare:UI_CTDevTestShare()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UI_CTDevTestShare:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UI_CTDevTestShare:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UI_CTDevTestShare:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitEvent()
end

function UI_CTDevTestShare:InitEvent()
	self._showShare = gLSdkImpl:CallMethod(LSdkMethod.IsSupportShareChannel,LShareConst.CHANNEL_WX)

	self:SetWndClick(self.mTestScrollObj, function ()
		if not self._showShare then return end
		gLGameUI:CaptureUIScreen(self:GetWndTrans(), {self.mShareNode}, true, {shareScene=LShareConst.SCENE_WX_PY,shareLocation="testshare"})
	end)
	self:SetWndClick(self.mTestVideoObj, function ()
		if not self._showShare then return end
		gLGameUI:CaptureUIScreen(self:GetWndTrans(), {self.mShareNode}, true, {shareScene=LShareConst.SCENE_WX_PYQ,shareLocation="testshare"})
	end)
end



------------------------------------------------------------------
return UI_CTDevTestShare


