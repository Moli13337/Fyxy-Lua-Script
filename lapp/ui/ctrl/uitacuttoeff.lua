---
--- Created by BY.
--- DateTime: 2023/10/25 16:42:57
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITaCutToEff:LWnd
local UITaCutToEff = LxWndClass("UITaCutToEff", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITaCutToEff:UITaCutToEff()
	self._timeKey1 = "timeKey1"
	self._timeKey2 = "timeKey2"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITaCutToEff:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITaCutToEff:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITaCutToEff:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommand()
end

function UITaCutToEff:SetTime(callFunc)
	local _callFunc = callFunc
	if _callFunc then
		_callFunc()
	end
end

function UITaCutToEff:OnTimer(key)
	if(key == self._timeKey1)then
		self:SetTime(self._callFunc1)
	elseif(key == self._timeKey2)then
		--self:SetTime(self._callFunc2)
		self:WndClose()
	end
end

function UITaCutToEff:InitCommand()
	self._callFunc1 = self:GetWndArg("callfunc1")
	local cutToEff = self:GetWndArg("cutToEff")
	local _eff = "fx_slzt_zhuanchang"
	if cutToEff then
		_eff = cutToEff
	end
	self:CreateWndEffect(self.mEff,_eff,"towerCutToEff",100)
	local effTime = 1
	self:TimerStart(self._timeKey1,effTime,true,1)
	self:TimerStart(self._timeKey2,effTime * 2,true,1)
end
------------------------------------------------------------------
return UITaCutToEff


