---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UINotch:LWnd
local UINotch = LxWndClass("UINotch", LWnd)
------------------------------------------------------------------
local UnityScreen = UnityEngine.Screen
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UINotch:UINotch()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UINotch:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UINotch:OnCreate()
	LWnd.OnCreate(self)
	self:SetAutoAdjustNotch(-1)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UINotch:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._transList = { self.mImageTTrans,self.mImageBTrans }

	self:WndEventRecv(EventNames.NOTCH_SAFE_AREA_UPDATE,function(...) self:OnNotchSafeAreaUpdate(...) end)
	self:WndEventRecv(EventNames.VIDEO_SHOW_BLACK,function(...) self:OnVideoShowBlack(...) end)
	self:WndEventRecv(EventNames.NOTCH_HIDE_VIEW,function(...)
		self:HideView(...)
	end)
	self:OnNotchSafeAreaUpdate()
end

function UINotch:GetNotchList()
	return self._transList
end

function UINotch:OnNotchSafeAreaUpdate()
    local showNotDraw = false
    local topMaxY = LNotchUtil.NotchAnchorMax.y
	self.mImageTRectTrans.anchorMin = Vector2(0,topMaxY)
	self.mImageTRectTrans.pivot = Vector2(0.5, 0.5)
	self.mImageTRectTrans.offsetMin = Vector2.zero
	self.mImageTRectTrans.offsetMax = Vector2.zero
    local topMaxYT = 0.9703792
    showNotDraw = topMaxY >= topMaxYT
    CS.ShowObject(self.mNotDrawT,showNotDraw)
    CS.ShowObject(self.mDrawT,not showNotDraw)

    local botMinY = LNotchUtil.NotchAnchorMin.y
	self.mImageBRectTrans.anchorMax = Vector2(1,botMinY)
	self.mImageBRectTrans.pivot = Vector2(0.5, 0.5)
	self.mImageBRectTrans.offsetMin = Vector2.zero
	self.mImageBRectTrans.offsetMax = Vector2.zero
    local botMinYT = 0.03870458
    showNotDraw = botMinY <= botMinYT
    CS.ShowObject(self.mNotDrawB,showNotDraw)
    CS.ShowObject(self.mDrawB,not showNotDraw)

	CS.ShowObject(self.mPower,false)
	CS.ShowObject(self.mWifiImg,false)
	if 1 - LNotchUtil.NotchAnchorMax.y < 0.000001 then
	else
		local batteryLevel = CS.GetBatteryLevel()
		LxUiHelper.SetProgress(self.mPowerImg,batteryLevel)
		local batteryStatus = CS.GetBatteryStatus()
		CS.ShowObject(self.mChargeImg,batteryStatus == "Charging")
	end

    local leftMinX = LNotchUtil.NotchAnchorMin.x
    local leftMinXT = 0.15
	self.mImageLRectTrans.anchorMax = Vector2(leftMinX,1)
	self.mImageLRectTrans.pivot = Vector2(0.5, 0.5)
	self.mImageLRectTrans.offsetMin = Vector2.zero
	self.mImageLRectTrans.offsetMax = Vector2.zero
    showNotDraw = leftMinX <= leftMinXT
    CS.ShowObject(self.mNotDrawL,showNotDraw)
    CS.ShowObject(self.mDrawL,not showNotDraw)


    local rightMaxX = LNotchUtil.NotchAnchorMax.x
    local rightMaxXT = 0.85
	self.mImageRRectTrans.anchorMin = Vector2(rightMaxX, 0)
	self.mImageRRectTrans.pivot = Vector2(0.5, 0.5)
	self.mImageRRectTrans.offsetMin = Vector2.zero
	self.mImageRRectTrans.offsetMax = Vector2.zero
    showNotDraw = rightMaxX >= rightMaxXT
    CS.ShowObject(self.mNotDrawR,showNotDraw)
    CS.ShowObject(self.mDrawR,not showNotDraw)
end

function UINotch:OnVideoShowBlack(bShow)
	local bActive = not bShow
	CS.ShowObject(self.mImageTRectTrans,bActive)
	CS.ShowObject(self.mImageBRectTrans,bActive)
end

function UINotch:HideView(bShow)
	--printInfoNR("========== bShow = " .. bShow)
	self:SetWndVisible(bShow)
end
------------------------------------------------------------------
return UINotch


