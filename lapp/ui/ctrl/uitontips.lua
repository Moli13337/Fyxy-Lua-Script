---
--- Created by Administrator.
--- DateTime: 2023/10/12 16:43:56
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UITonTips:LWnd
local UITonTips = LxWndClass("UITonTips", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UITonTips:UITonTips()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UITonTips:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UITonTips:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UITonTips:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetContent()
end

function UITonTips:OnClickOk()

	local checkCallback = self:GetWndArg("checkCallback")
	if self._isCheck then
		if checkCallback then
			checkCallback()
		end
	end

	local okCall = self:GetWndArg("okCall")
	if okCall then
		okCall()
	end

	self:WndClose()
end

function UITonTips:SetContent()
	local str = ccClientText(27413)
	self:SetWndText(self.mTitle1,str)
	str = ccClientText(27191)
	self:SetWndText(self.mToggleText,str)
	str = ccClientText(27190)
	self:SetWndText(self.mContent1,str)
	str = ccClientText(22304)
	self:SetWndButtonText(self.mBtnCancel,str)
	str = ccClientText(12605)
	self:SetWndButtonText(self.mBtnOk,str)

	self:SetWndClick(self.mBtnCancel,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mBtnOk,function ()
		self:OnClickOk()
	end)

	self:SetWndClick(self.mCloseBtn,function ()
		self:WndClose()
	end)

	self._isCheck = true
	self:SetWndToggleValue(self.mToggle,self._isCheck)
	self:SetWndToggleDelegate(self.mToggle,function (value)
		self._isCheck = value
	end)
end

------------------------------------------------------------------
return UITonTips


