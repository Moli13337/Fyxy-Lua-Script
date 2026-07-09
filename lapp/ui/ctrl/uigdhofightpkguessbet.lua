---
--- Created by Administrator.
--- DateTime: 2024/10/21 15:55:35
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightPkGuessBet:LWnd
local UIGdHoFightPkGuessBet = LxWndClass("UIGdHoFightPkGuessBet", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightPkGuessBet:UIGdHoFightPkGuessBet()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightPkGuessBet:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightPkGuessBet:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightPkGuessBet:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:InitSlider()
end

function UIGdHoFightPkGuessBet:ClickOkBtn()
	local stage = gModelGuildHolyPeak:GetStage()
	local b = stage == 3 or stage == 5 or stage == 7 or stage == 9
	if not b then
		GF.ShowMessage(ccClientText(46039))
		return
	end
	if self.betValue <= 0 then
		GF.ShowMessage(ccClientText(46018))
		return
	end
	gModelGuildHolyPeak:GuildPinnacleQuizReq(self.guildId, self.betValue)
	self:WndClose()
end

function UIGdHoFightPkGuessBet:ClickSliderBtn(isAdd)
	local addValue = isAdd and 1 or -1
	local value = self.betValue + addValue
	local guessCoin = gModelItem:GetNumByRefId(self.item.itemId)
	self.betValue = math.min(math.max(value, 0), guessCoin)
	self:SetWndText(self.mNumText, self.betValue)
	self.valueSlider:SetUIProgress(value)
end

function UIGdHoFightPkGuessBet:InitSlider()
	self.valueSlider = self:UIProgressFind(self.mSlider, "mSlider", 0)
	local maxValue = gModelItem:GetNumByRefId(self.item.itemId)
	self.mSlider:GetComponent(typeof(UnityEngine.UI.Slider)).maxValue = maxValue
	self.valueSlider:SetSliderDelegate(function(value)
		self.betValue = math.floor(value)
		self:SetWndText(self.mNumText, self.betValue)
	end)
end

function UIGdHoFightPkGuessBet:InitCommon()
	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBgImage, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mRed, function()
		self:ClickSliderBtn(false)
	end)
	self:SetWndClick(self.mAdd, function()
		self:ClickSliderBtn(true)
	end)
	self:SetWndClick(self.mOkBtn, function()
		self:ClickOkBtn()
	end)
	self:SetWndClick(self.mCancelBtn, function()
		self:WndClose()
	end)

	------------------------------------------------------------------
	---text
	self:SetWndText(self.mNumText, "0")
	self:SetWndText(self.mLblBiaoti, ccClientText(46017))
	self:SetWndButtonText(self.mOkBtn, ccClientText(10102))
	self:SetWndButtonText(self.mCancelBtn, ccClientText(10101))

	------------------------------------------------------------------
	---icon
	local item = gModelGuildHolyPeak:GetGuessItem()
	self.item = item
	local commonIconCls = self:GetCommonIcon("guessIcon")
	commonIconCls:Create(self.mItemRoot)
	commonIconCls:SetCommonReward(item.itemType, item.itemId)
	commonIconCls:DoApply()
	self:SetWndText(self.mItemText, gModelGeneral:GetCommonItemName(item))
	self:SetWndClick(self.mItemRoot, function()
		gModelGeneral:ShowCommonItemTipWnd(item)
	end)

	------------------------------------------------------------------
	---member
	self.guildId = self:GetWndArg("guildId")
	self.betValue = 0
end



------------------------------------------------------------------
return UIGdHoFightPkGuessBet