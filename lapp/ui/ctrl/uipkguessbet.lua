---
--- Created by Administrator.
--- DateTime: 2023/10/6 20:36:20
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPkGuessBet:LWnd
local UIPkGuessBet = LxWndClass("UIPkGuessBet", LWnd)


UIPkGuessBet.BET_TYPE_YES = 1
UIPkGuessBet.BET_TYPE_NO = 2
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPkGuessBet:UIPkGuessBet()
	self.betValue = 0
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPkGuessBet:OnWndClose()
	self:ClearCommonIconList({self.commonIcon})
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPkGuessBet:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPkGuessBet:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitData()
	self:InitSlider()
end

function UIPkGuessBet:InitSlider()
	local guessCoinMax = gModelArena:GetArenaPeakRef("guessCoinMax")
	self.valueSlider = self:UIProgressFind(self.mSlider, "mSlider", 0)
	local guessCoin = gModelArena:GetGuessCoin() or 0
	local maxValue = math.min(guessCoin, guessCoinMax)
	self.mSlider:GetComponent(typeof(UnityEngine.UI.Slider)).maxValue = maxValue
	self.valueSlider:SetSliderDelegate(function(value)
		self.betValue = math.floor(value)
		self:SetWndText(self.mNumText, self.betValue)
	end)
end

function UIPkGuessBet:ClickOkBtn()
	local combatState = gModelArena:GetPeakCombatState()
	if combatState ~= ModelArena.PEAK_BATTLE_STATE_BETTING then
		GF.ShowMessage(ccClientText(11888))
		return
	end
	if self.betValue <= 0 then
		GF.ShowMessage(ccClientText(11887))
		return
	end
	if self.targetId and self.betValue then
		gModelArena:PinnaclePaceGuessReq(self.targetId, self.betValue)
	end
	self:WndClose()
end

function UIPkGuessBet:InitEvent()
	self:SetWndClick(self.mBtnClose, function() self:WndClose() end)
	self:SetWndClick(self.mRed, function() self:ClickSliderBtn(false) end)
	self:SetWndClick(self.mAdd, function() self:ClickSliderBtn(true) end)
	self:SetWndClick(self.mOkBtn, function() self:ClickOkBtn() end)
	self:SetWndClick(self.mCancelBtn, function() self:ClickCancelBtn() end)
end

function UIPkGuessBet:ClickCancelBtn()
	self:WndClose()
end

function UIPkGuessBet:InitData()
	self:SetWndText(self.mNumText, self.betValue)
	self:SetWndText(self.mLblBiaoti, ccClientText(11841))
	self:SetWndButtonText(self.mOkBtn, ccClientText(10102))
	self:SetWndButtonText(self.mCancelBtn, ccClientText(10101))

	local item = LxDataHelper.ParseItem_3(gModelArena:GetArenaPeakRef("guessCoin"))
	self.commonIcon = CommonIcon:New()
	self.commonIcon:Create(self.mItemRoot)
	self.commonIcon:SetCommonReward(item.itemType, item.itemId)
	self.commonIcon:DoApply()
	self:SetWndText(self.mItemText, gModelGeneral:GetCommonItemName(item))
	self:SetWndClick(self.mItemRoot, function() gModelGeneral:ShowCommonItemTipWnd(item) end)

	self.targetId = self:GetWndArg("targetId")
end

function UIPkGuessBet:ClickSliderBtn(isAdd)
	local addValue = isAdd and 1 or -1
	local value = self.betValue + addValue
	local guessCoin = gModelArena:GetGuessCoin() or 0
	self.betValue = math.min(math.max(value, 0), guessCoin)
	self:SetWndText(self.mNumText, self.betValue)
	self.valueSlider:SetUIProgress(value)
end

------------------------------------------------------------------
return UIPkGuessBet


