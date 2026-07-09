---
--- Created by Administrator.
--- DateTime: 2024/3/7 20:19:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIMCityClickArea:LWnd
local UIMCityClickArea = LxWndClass("UIMCityClickArea", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIMCityClickArea:UIMCityClickArea()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIMCityClickArea:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIMCityClickArea:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIMCityClickArea:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitText()
	self:RegisterEvent()

	local wndCanvas = self:GetWndCanvas()
	wndCanvas.sortingOrder = 1
	
end

function UIMCityClickArea:OnChengBaoClick()
	GF.ShowMessage("点击城堡")
end

function UIMCityClickArea:OnShangDianClick()
	GF.ShowMessage("点击商店")
end

function UIMCityClickArea:OnMoTaClick()
	GF.ShowMessage("点击魔塔")
end

function UIMCityClickArea:OnGongMingMoJingClick()
	GF.ShowMessage("点击共鸣水晶")
end
--绑定点击
function UIMCityClickArea:RegisterEvent()
	self:SetWndClick(self.mMiLingBtn, function(...) self:OnMiLingClick() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mShangDianBtn, function(...) self:OnShangDianClick() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mMoTaBtn, function(...) self:OnMoTaClick() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mGongMingMoJingBtn, function(...) self:OnGongMingMoJingClick() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mGongHuiBtn, function(...) self:OnGongHuiClick() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mChengBaoBtn, function(...) self:OnChengBaoClick() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mShuiJingHuBtn, function(...) self:OnShuiJingHuClick() end,LSoundConst.CLICK_CLOSE_COMMON)
end


--region 点击方法 --------------------------------------------------------------------------------
function UIMCityClickArea:OnMiLingClick()
	GF.ShowMessage("点击秘灵坊")
end

function UIMCityClickArea:OnGongHuiClick()
	GF.ShowMessage("点击公会")
end

--初始化显示
function UIMCityClickArea:InitText()
	self:SetWndText(self.mMiLing,ccClientText(13431))
	self:SetWndText(self.mShangDian,ccClientText(13432))
	self:SetWndText(self.mMoTa,ccClientText(13433))
	self:SetWndText(self.mGongMingMoJing,ccClientText(13434))
	self:SetWndText(self.mGongHui,ccClientText(13435))
	self:SetWndText(self.mChengBao,ccClientText(13436))
	self:SetWndText(self.mShuiJingHu,ccClientText(13437))
end

function UIMCityClickArea:OnShuiJingHuClick()
	GF.ShowMessage("点击水晶湖")
end

--endregion --------------------------------------------------------------------------------------

--region 刷新红点 --------------------------------------------------------------------------------


--endregion --------------------------------------------------------------------------------------
------------------------------------------------------------------
return UIMCityClickArea