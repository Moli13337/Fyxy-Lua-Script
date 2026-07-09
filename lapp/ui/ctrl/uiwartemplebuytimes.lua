---
--- Created by wzz.
--- DateTime: 2024/5/10 17:25:22
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWarTempleBuyTimes:LWnd
local UIWarTempleBuyTimes = LxWndClass("UIWarTempleBuyTimes", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWarTempleBuyTimes:UIWarTempleBuyTimes()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWarTempleBuyTimes:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWarTempleBuyTimes:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWarTempleBuyTimes:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	local baseInfo = gModelWarTemple:GetBaseInfo()
	self._max = baseInfo.buyChallengeCnt or 10
	self._value = 1

	self:InitTexts()
	self:InitEvents()

	self:Refresh()
end

-- 点击确认
function UIWarTempleBuyTimes:OnClickBtnConfirm()
	local refId = ModelItem.ITEM_DIAMOND
	local times = self.mSlider.value
	local price = gModelWarTemple:GetBuyFightTimesPrice(times)
	local haveNum = gModelItem:GetNumByRefId(refId)
	if haveNum < price then
		local itemName = gModelItem:GetNameByRefId(refId)
		GF.ShowMessage(ccClientText(42046, itemName))
		gModelGeneral:OpenGetWayWnd({ itemId = refId })
		return
	end
	gModelWarTemple:WarTempleBuyChallengeCntReq(times)
	self:WndClose()
end

-- 点击 加
function UIWarTempleBuyTimes:OnClickBtnAdd()
	self._value = self._value + 1
	if self._value > self._max then
		self._value = self._max
	end
	self.mSlider.value = self._value
	self:Refresh()
end

-- 初始界面化文本
function UIWarTempleBuyTimes:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(42041))
	self:SetWndText(self.mTips, ccClientText(42042))

	self:SetWndButtonText(self.mBtnConfirm, ccClientText(42044))
	self:SetWndButtonText(self.mBtnCancel, ccClientText(42045))

	self.mSlider.minValue = 1
	self.mSlider.maxValue = self._max
	self.mSlider.value = self._value

	self:SetWndSliderDelegate(self.mSlider, function() self:OnSliderValueChanged() end)
end

-- 滑动条值改变
function UIWarTempleBuyTimes:OnSliderValueChanged()
	self._value = self.mSlider.value
	self:Refresh()
end

-- 点击 减
function UIWarTempleBuyTimes:OnClickBtnSub()
	self._value = self._value - 1
	if self._value < 1 then
		self._value = 1
	end
	self.mSlider.value = self._value
	self:Refresh()
end

-- 刷新界面
function UIWarTempleBuyTimes:Refresh()
	local times = self.mSlider.value
	local price = gModelWarTemple:GetBuyFightTimesPrice(times)
	self:SetWndText(self.mTips2, ccClientText(42043, price, times))
	self:SetWndText(self.mSliderValue, times .. "/".. self._max)
end

-- 初始事件
function UIWarTempleBuyTimes:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mBtnCancel, function() self:WndClose() end)
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function() self:OnClickBtnConfirm() end)
	self:SetWndClick(self.mBtnAdd, function() self:OnClickBtnAdd() end)
	self:SetWndClick(self.mBtnSub, function() self:OnClickBtnSub() end)
end

------------------------------------------------------------------
return UIWarTempleBuyTimes