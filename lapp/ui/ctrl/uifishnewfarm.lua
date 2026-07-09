---
--- Created by wzz.
--- DateTime: 2024/9/19 17:18:30
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFishNewFarm:LWnd
local UIFishNewFarm = LxWndClass("UIFishNewFarm", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFishNewFarm:UIFishNewFarm()
end

------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFishNewFarm:OnWndClose()
	LWnd.OnWndClose(self)
end

------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFishNewFarm:OnCreate()
	LWnd.OnCreate(self)
	return true
end

------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFishNewFarm:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	local refId = self:GetWndArg("refId")
	self._ref = gModelFish:GetRef(refId)
	gModelFish:SaveLookNewFarm(refId)

	self:InitTexts()
	self:InitEvents()
	self:PlayEffect()
	self:Refresh()
end

-- 点击前往
function UIFishNewFarm:OnClickBtnGoto()
	local refId = self._ref.refId
	GF.OpenWnd("UISowEffect", {
		wndType = 0,
		endFunc = function()
			gModelFish:SwitchFishSceneReq(refId)
			gModelFish:SaveLookFishFarm(refId)
			FireEvent(EventNames.FISH_BASE_INFO)
		end
	})
	GF.CloseWndByName("UIFishList")
	self:WndClose()
end

-- 刷新界面
function UIFishNewFarm:Refresh()
	local ref = self._ref

	self:SetWndText(self.mTxtTitle, ccLngText(ref.name))
	self:SetWndText(self.mTxtDesc, ccLngText(ref.desc))
end

-- 播放动画
function UIFishNewFarm:PlayEffect()
	self:CreateWndEffect(self.mEff, "fx_ui_shengxing_1", 1, 100)
end

-- 初始事件
function UIFishNewFarm:InitEvents()
	self:SetWndClick(self.mBtnGoto, function() self:OnClickBtnGoto() end)
	self:SetWndClick(self.mBtnNoGoto, function() self:WndClose() end)
	self:SetWndClick(self.mMask, function() self:WndClose() end)
end

-- 初始界面化文本
function UIFishNewFarm:InitTexts()
	self:SetWndButtonText(self.mBtnNoGoto, ccClientText(44355))
	self:SetWndButtonText(self.mBtnGoto, ccClientText(44356))
	self:SetWndText(self.mCloseTip, ccClientText(10103))
end

------------------------------------------------------------------
return UIFishNewFarm