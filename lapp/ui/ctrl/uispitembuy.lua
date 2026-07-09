---
--- Created by Administrator.
--- DateTime: 2023/10/26 14:33:07
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISpItemBuy:LWnd
local UISpItemBuy = LxWndClass("UISpItemBuy", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISpItemBuy:UISpItemBuy()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISpItemBuy:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISpItemBuy:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISpItemBuy:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitUIEvent()
	self:OnWndRefresh()
	self:SetWndText(self.mCloseTip,ccClientText(10103))

end

function UISpItemBuy:OnClickOk()
	if self._callback then
		self._callback()
	end

	self:WndClose()
end

function UISpItemBuy:InitUIEvent()
	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mCancelBtn,function ()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnOk,function ()
		self:OnClickOk()
	end)
end

function UISpItemBuy:OnWndRefresh()

	self._callback = self:GetWndArg("callback")

	local str =ccClientText(27301)
	self:SetWndButtonText(self.mCancelBtn,str)

	str = ccClientText(27300)
	self:SetWndButtonText(self.mBtnOk,str)

	local para = self:GetWndArg("para")

	local title = self:GetWndArg("title")

	self:SetWndText(self.mTitleText,title)


	str = string.replace(ccClientText(27302),unpack(para))
	self:SetWndText(self.mIntro,str)


end

------------------------------------------------------------------
return UISpItemBuy


