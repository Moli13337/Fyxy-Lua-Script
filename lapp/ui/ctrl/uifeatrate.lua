---
--- Created by Administrator.
--- DateTime: 2023/10/23 16:45:58
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFeatRate:LWnd
local UIFeatRate = LxWndClass("UIFeatRate", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFeatRate:UIFeatRate()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFeatRate:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFeatRate:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFeatRate:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitContent()

	self:SetWndText(self.mTitle, ccClientText(19520))
	self:SetWndText(self.mButtomDesc, ccClientText(19532))
end

function UIFeatRate:InitContent()
	local rateStr
	local rateValue = self._rateValue
	if rateValue == 0 or rateValue == 100 then
		rateStr = ""
	elseif rateValue >= 0.1 then
		if rateValue > 99.9 then
			rateStr = ccClientText(19516)
			rateValue = 99.9
		else
			rateStr = ""
			rateValue = math.floor(rateValue * 10) / 10
		end
	else
		rateStr = ccClientText(19517)
		rateValue = 0.1
	end

	rateStr = rateStr..string.replace(ccClientText(19518), rateValue)
	self:SetWndText(self.mText, string.replace(ccClientText(19519), self._name, rateStr))
end

function UIFeatRate:InitEvent()
	self:SetWndClick(self.mMask, function(...) self:WndClose() end)
end

function UIFeatRate:InitData()
	self._name 		= self:GetWndArg("name")
	self._rateValue = self:GetWndArg("rate")
end



------------------------------------------------------------------
return UIFeatRate


