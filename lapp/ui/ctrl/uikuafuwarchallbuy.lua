---
--- Created by Administrator.
--- DateTime: 2024/6/17 18:14:00
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuWarChallBuy:LWnd
local UIKuafuWarChallBuy = LxWndClass("UIKuafuWarChallBuy", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuWarChallBuy:UIKuafuWarChallBuy()
	self.num = 1
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuWarChallBuy:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuWarChallBuy:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuWarChallBuy:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitText()
	self:InitSlider()
end

function UIKuafuWarChallBuy:InitText()
	self:SetWndText(self.mLblBiaoti, ccClientText(43845))
	self:SetWndButtonText(self.mOkBtn, ccClientText(10102))
	self:SetWndButtonText(self.mCancelBtn, ccClientText(10101))
end

function UIKuafuWarChallBuy:InitEvent()
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)
	self:SetWndClick(self.mRed, function() self:ClickSliderBtn(false) end)
	self:SetWndClick(self.mAdd, function() self:ClickSliderBtn(true) end)
	self:SetWndClick(self.mOkBtn, function() self:ClickOkBtn() end)
	self:SetWndClick(self.mCancelBtn, function() self:WndClose() end)
end

function UIKuafuWarChallBuy:OnUpdate()
	local maxValue = gModelCrossWar:GetBuyChallengeNum()
	self:SetWndText(self.mNumText, self.num .. "/" .. maxValue)
	self:SetText()
end

function UIKuafuWarChallBuy:InitSlider()
	self.valueSlider = self:UIProgressFind(self.mSlider, "mSlider", 0)
	local maxValue = gModelCrossWar:GetBuyChallengeNum()
	self:OnUpdate()
	self.mSlider:GetComponent(typeof(UnityEngine.UI.Slider)).maxValue = maxValue
	self.valueSlider:SetSliderDelegate(function(value)
		self.num = math.min(math.max(0, math.floor(value)), maxValue)
		self:OnUpdate()
	end)
	self.valueSlider:SetUIProgress(self.num)
end

function UIKuafuWarChallBuy:SetText()
	local maxChallengeBuyNum = gModelCrossWar:GetMaxChallengeBuyNum()
	local buyChallengeNum = gModelCrossWar:GetBuyChallengeNum()
	local buyNum = maxChallengeBuyNum - buyChallengeNum
	local time = buyNum + 1
	local money = 0
	if self.num > 0 then
		for i = time, time + self.num - 1 do
			local v = gModelCrossWar:GetChallengeMoneyByNum(i)
			money = money + v
		end
	end
	local s = ccClientText(43846)
	self:SetWndText(self.mText, string.replace(s, money, self.num))
end

function UIKuafuWarChallBuy:ClickOkBtn()
	gModelCrossWar:CrossWarTempleBuyChallengeCntReq(self.num)
	self:WndClose()
end

function UIKuafuWarChallBuy:ClickSliderBtn(isAdd)
	local addValue = isAdd and 1 or -1
	local num = self.num + addValue
	self.valueSlider:SetUIProgress(num)
end



------------------------------------------------------------------
return UIKuafuWarChallBuy