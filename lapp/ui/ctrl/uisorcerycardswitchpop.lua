---
--- Created by BY.
--- DateTime: 2022/7/15 10:40:23
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISorceryCardSwitchPop:LWnd
local UISorceryCardSwitchPop = LxWndClass("UISorceryCardSwitchPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISorceryCardSwitchPop:UISorceryCardSwitchPop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISorceryCardSwitchPop:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISorceryCardSwitchPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISorceryCardSwitchPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommand()
end

function UISorceryCardSwitchPop:OnClickConfirm()
	local alertId = self._popAlertId
	local func = self._callFunc
	if func then func() end
	if self._toggleValue then
		gModelGeneral:SetAlertId(alertId)
	end
	self:WndClose()
end
function UISorceryCardSwitchPop:SetCardItem(item,ref)
	local icon = self:FindWndTrans(item,"Icon")
	local themeRef = gModelSorceryCard:GetSorceryCardThemeRefByRefId(ref.theme)

	self:SetWndEasyImage(item,themeRef.cardFrame,nil,true)
	self:SetWndEasyImage(icon,ref.icon,nil,true)
end
function UISorceryCardSwitchPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(29530))
	self:SetWndText(self.mToggleText,ccClientText(29531))
	self:SetWndButtonText(self.mBtnCancel,ccClientText(29545))
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(29546))

	local func = self:GetWndArg("func")
	local heroId = self:GetWndArg("heroId")
	local popAlertId = self:GetWndArg("popAlertId") or 0
	local oldRefId = self:GetWndArg("oldRefId")
	local newRefId = self:GetWndArg("newRefId")

	self._callFunc = func
	self._popAlertId = popAlertId
	local oldCardName,newCardName = "",""
	local oldRef = gModelSorceryCard:GetSorceryCardRefByRefId(oldRefId)
	newCardName = ccLngText(oldRef.name)
	local newRef = gModelSorceryCard:GetSorceryCardRefByRefId(newRefId)
	oldCardName = ccLngText(newRef.name)
	local des = string.replace(ccClientText(29504),oldCardName,newCardName)

	local heroName = gModelHero:GetHeroNameById(heroId)
	self:SetWndText(self.mNameText,heroName)
	self:SetWndText(self.mDesText,des)
	self:SetWndToggleValue(self.mToggle,false)
	self:SetCardItem(self.mCard2,oldRef)
	self:SetCardItem(self.mCard1,newRef)

	local baseClass = self._heroRoot
	if not baseClass then
		baseClass = CommonIcon:New(self)
		self._heroRoot = baseClass
		baseClass:Create(self.mHeroRoot)
	end
	baseClass:SetHeroPlayer(heroId)
	baseClass:DoApply()
end

function UISorceryCardSwitchPop:InitEvent()
	self:SetWndClick(self.mBgImage,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function ()self:WndClose() end)
	self:SetWndClick(self.mBtnCancel,function ()self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBtnConfirm,function ()self:OnClickConfirm() end)
	self:SetWndToggleDelegate(self.mToggle,function (value)
		self._toggleValue = value
	end)
end
------------------------------------------------------------------
return UISorceryCardSwitchPop


