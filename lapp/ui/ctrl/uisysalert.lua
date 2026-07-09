---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISysAlert:LWnd
local UISysAlert = LxWndClass("UISysAlert", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISysAlert:UISysAlert()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISysAlert:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISysAlert:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISysAlert:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()

	self:UpdateAlertUI()
end

-----------------------------------------------------------------
function UISysAlert:PreDestroy()
	LWnd.PreDestroy(self)

	if self._showTween then
		self._showTween:Kill(false)
		self._showTween = nil
	end
end

--init data
function UISysAlert:InitData()
	self._title = self:GetWndArg("title")
	self._msg = self:GetWndArg("msg")

	self._okFunc = self:GetWndArg("okFunc")
	self._cancelFunc = self:GetWndArg("cancelFunc")

	self._okMsg = self:GetWndArg("okMsg") or ccClientText(10102)
	self._cancelMsg = self:GetWndArg("cancelMsg") or ccClientText(10101)

	if not self._cancelFunc then
		self._bOkOnly = true
	end
end
-----------------------------------------------------------------
---事件处理
-----------------------------------------------------------------
function UISysAlert:DoCancel()
	local cancelFunc = self._cancelFunc
	self:WndClose()
	if cancelFunc ~= nil then
		cancelFunc(false)
	end
end

function UISysAlert:DoOk()
	local okFunc = self._okFunc
	self:WndClose()
	if okFunc ~= nil then
		okFunc(true)
	end
end

--refresh ui
function UISysAlert:UpdateAlertUI()
	local closefunc = function()
		if self._bOkOnly then
			self:DoOk()
		else
			self:DoCancel()
		end
	end
	self:SetWndClick(self.mBlackBgObj, closefunc)
	self:SetWndClick(self.mBtnClose, closefunc)

	--title
	self:SetXUITextText(self.mLblBiaoti, self._title or "")
	--msg
	self:SetXUITextText(self.mTextContent, self._msg or "")

	-- button
	local okMsg = self._okMsg or ""

	self:SetWndButtonText(self.mBtnOk,okMsg)
	self:SetWndButtonText(self.mBtnOkOnly,okMsg)

	local cancelMsg = self._cancelMsg or ""
	self:SetWndButtonText(self.mBtnCancel, cancelMsg)

	if self._bOkOnly then
		CS.ShowObject(self.mBtnCancel, false)
		CS.ShowObject(self.mBtnOk, false)
		CS.ShowObject(self.mBtnOkOnly, true)

		LxUiHelper.SetTransClick(self.mBtnOkOnly, function()
			self:DoOk()
		end)
	else
		CS.ShowObject(self.mBtnCancel, true)
		CS.ShowObject(self.mBtnOk, true)
		CS.ShowObject(self.mBtnOkOnly, false)

		LxUiHelper.SetTransClick(self.mBtnCancel, function()
			self:DoCancel()
		end)
		LxUiHelper.SetTransClick(self.mBtnOk, function()
			self:DoOk()
		end)
	end
end

-----------------------------------------------------------------
------------------------------------------------------------------
return UISysAlert


