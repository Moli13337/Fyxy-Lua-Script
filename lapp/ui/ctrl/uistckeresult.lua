---
--- Created by Administrator.
--- DateTime: 2024/9/5 22:17:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIStCkeResult:LWnd
local UIStCkeResult = LxWndClass("UIStCkeResult", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIStCkeResult:UIStCkeResult()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIStCkeResult:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIStCkeResult:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIStCkeResult:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:InitEvent()
end

function UIStCkeResult:InitEvent()
	self:SetWndClick(self.mMask, function()
		self:WndClose()
		GF.CloseWndByName("UIStCkeGame")
	end)
end

function UIStCkeResult:InitCommon()
	-----------------------------------------------
	---text
	self:SetWndText(self.mCloseText, ccClientText(41037))

	local args = self:GetWndArg("args")
	local cfg = self:GetWndArg("config")
	local strs = string.split(args, '|')
	local txt1 = cfg.txt1 or ccClientText(29709)
	local str = string.replace(txt1, strs[1])
	local txt2 = cfg.txt2 or ccClientText(29710)
	str = str .. "\n" .. string.replace(txt2, strs[3] .. "%")
	self:SetWndText(self.mText, str)
	self:SetWndText(self.mScore, LUtil.NumberCoversion(tonumber(strs[2])))

	-----------------------------------------------
	---spine
	self:CreateWndSpine(self.mSpine, "LH_Jinglingnvpu01", "spine")
end



------------------------------------------------------------------
return UIStCkeResult