---
--- Created by wzz.
--- DateTime: 2024/9/11 20:08:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIDesireTrailBuyTimes:LWnd
local UIDesireTrailBuyTimes = LxWndClass("UIDesireTrailBuyTimes", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIDesireTrailBuyTimes:UIDesireTrailBuyTimes()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIDesireTrailBuyTimes:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIDesireTrailBuyTimes:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIDesireTrailBuyTimes:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._itemRefId, self._exchangeNum = gModelDesireTrail:GetChallengeExchange()
	self._itemName = gModelItem:GetNameByRefId(self._itemRefId)
	local haveNum = gModelItem:GetNumByRefId(self._itemRefId)
	local maxNum = math.max(1, math.floor(haveNum / self._exchangeNum))
	self._max = maxNum
	self._value = 1

	self:InitTexts()
	self:InitEvents()
	self:Refresh()
	self:RefreshAsset()
end

-- 初始界面化文本
function UIDesireTrailBuyTimes:InitTexts()
	self:SetWndText(self.mTitle, ccClientText(45419))
	self:SetWndText(self.mCloseTip, ccClientText(10103))
	self:SetWndButtonText(self.mBtnConfirm, ccClientText(45422))

	self.mSlider.minValue = 1
	self.mSlider.maxValue = self._max
	self.mSlider.value = self._value

	self:SetWndSliderDelegate(self.mSlider, function() self:OnSliderValueChanged() end)
end

-- 初始事件
function UIDesireTrailBuyTimes:InitEvents()
	self:SetWndClick(self.mMask, function() self:WndClose() end)
	self:SetWndClick(self.mReturnBtn, function() self:WndClose() end)
	self:SetWndClick(self.mBtnConfirm, function() self:OnBtnConfirmClick() end)
	self:SetWndClick(self.mBtnAdd, function() self:OnClickBtnAdd() end)
	self:SetWndClick(self.mBtnSub, function() self:OnClickBtnSub() end)
end

-- 刷新界面
function UIDesireTrailBuyTimes:Refresh()
	local times = self.mSlider.value

	self:SetWndText(self.mTips2, ccClientText(45423, self._itemName, times * self._exchangeNum, times))
	self:SetWndText(self.mSliderValue, times)
end

-- 滑动条值改变
function UIDesireTrailBuyTimes:OnSliderValueChanged()
	self._value = self.mSlider.value
	self:Refresh()
end

-- 点击 减
function UIDesireTrailBuyTimes:OnClickBtnSub()
	self._value = self._value - 1
	if self._value < 1 then
		self._value = 1
	end
	self.mSlider.value = self._value
	self:Refresh()
end

-- 刷新资产
function UIDesireTrailBuyTimes:RefreshAsset()
	self:SetTopAssetList(self.mTopAsset, {self._itemRefId})
end

-- 点击确认
function UIDesireTrailBuyTimes:OnBtnConfirmClick()
	local haveNum = gModelItem:GetNumByRefId(self._itemRefId)
	if (haveNum < self._value * self._exchangeNum) then
		GF.ShowMessage(ccClientText(45424, self._itemName))
		gModelGeneral:OpenGetWayWnd({ itemId = self._itemRefId })
		return
	end

	gModelDesireTrail:DesireTrailBuyChallengeReq(self._value)
	self:WndClose()
end

-- 点击 加
function UIDesireTrailBuyTimes:OnClickBtnAdd()
	self._value = self._value + 1
	if self._value > self._max then
		self._value = self._max
	end
	self.mSlider.value = self._value
	self:Refresh()
end

------------------------------------------------------------------
return UIDesireTrailBuyTimes