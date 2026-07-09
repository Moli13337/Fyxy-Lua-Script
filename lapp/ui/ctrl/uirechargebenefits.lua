---
--- Created by Administrator.
--- DateTime: 2025/12/16 11:28:09
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIRechargeBenefits:LWnd
local UIRechargeBenefits = LxClass("UIRechargeBenefits", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIRechargeBenefits:UIRechargeBenefits()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIRechargeBenefits:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIRechargeBenefits:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIRechargeBenefits:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitText()
	self:InitEvent()
	self:InitMsg()
	self:InitData()
	self:RefreshView()
end

function UIRechargeBenefits:InitText()
end

function UIRechargeBenefits:OnClickBtnGo()
	if string.isempty(self._link) then return end

	CS.UApplication.OpenURL(self._link)
	self:WndClose()
end

function UIRechargeBenefits:RefreshView()
end

function UIRechargeBenefits:InitEvent()
	--- 返回按钮必备
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnGo,function() self:OnClickBtnGo() end)
end

function UIRechargeBenefits:InitMsg()
end

function UIRechargeBenefits:InitData()
	local showInfo = self:GetWndArg("showInfo")
	if not showInfo then return end

	--local imgUrl = showInfo.imgUrl
	--if not string.isempty(imgUrl) then
	--	local uiPngTexture = self.mBg:GetComponent("YXTextureImage")
	--	uiPngTexture.isNativeSize = true
	--	uiPngTexture.isColorReset = true
	--	uiPngTexture:SetImageFromFullPath(imgUrl)
	--end
	self:SetWndText(self.mShowTxt,showInfo.content)
	self:SetCommonButtonText(self.mBtnGo,showInfo.btnText)

	self._link = showInfo.link
end



------------------------------------------------------------------
return UIRechargeBenefits