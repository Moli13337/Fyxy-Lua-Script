---
--- Created by Administrator.
--- DateTime: 2024/9/13 17:32:12
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIItemSyePop:LWnd
local UIItemSyePop = LxWndClass("UIItemSyePop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIItemSyePop:UIItemSyePop()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIItemSyePop:OnWndClose()
	if self.itemIconCls then
		self.itemIconCls:Destroy()
		self.itemIconCls = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIItemSyePop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIItemSyePop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:InitData()
	self:InitItem()
	self:InitSlider()
end

function UIItemSyePop:InitSlider()
	self.slider = self:UIProgressFind(self.mSlider, "mSlider", 0)
	self.mSlider:GetComponent(typeof(UnityEngine.UI.Slider)).maxValue = self.maxValue
	self.mSlider:GetComponent(typeof(UnityEngine.UI.Slider)).minValue = self.minValue
	self.slider:SetSliderDelegate(function(value)
		self.value = math.floor(value)
		self:SetWndText(self.mValue, self.value)
	end)
	self.slider:SetUIProgress(self.defaultNum)
end

function UIItemSyePop:ClickDetermine()
	if self.func then
		self.func(self.value)
	end
	self:WndClose()
end

function UIItemSyePop:ClickSliderBtn(isAdd)
	local addValue = isAdd and 1 or -1
	local value = self.value + addValue
	self.value = math.min(math.max(value, self.minValue), self.maxValue)
	self.slider:SetUIProgress(self.value)
end

function UIItemSyePop:InitItem()
	local root = CS.FindTrans(self.mItem, "ItemIcon")
	if not self.itemIconCls then
		self.itemIconCls = CommonIcon:New(self)
		self.itemIconCls:Create(root)
	end
	self.itemIconCls:SetCommonReward(LItemTypeConst.TYPE_ITEM, self.refId)
	self.itemIconCls:EnableShowNum(false)
	self.itemIconCls:DoApply()

	local name = gModelItem:GetNameByRefId(self.refId)
	if name then
		self:SetXUITextText(self.mItemName, name)
	end
	local color = gModelItem:GetItemNameColor(self.refId)
	if color then
		self:SetXUITextColor(self.mItemName, color)
	end
	local des = gModelItem:GetDescByRefId(self.refId)
	if des then
		self:SetXUITextText(self.mDescribeText, des)
	end

	self:SetXUITextText(self.mItemValue, string.replace(ccClientText(10205), gModelItem:GetNumByRefId(refId)))
end

function UIItemSyePop:InitCommon()
	-----------------------------------------------
	---text
	self:SetWndText(self.mLblBiaoti, ccClientText(10212))
	self:SetWndText(CS.FindTrans(self.mTextTitle, "UIText"), ccClientText(10208))
	self:SetWndButtonText(self.mCancel, ccClientText(10101))
	self:SetWndButtonText(self.mDetermine, ccClientText(10102))

	-----------------------------------------------
	---click
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mCancel, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mDetermine, function()
		self:ClickDetermine()
	end)
	self:SetWndClick(self.mPlus, function()
		self:ClickSliderBtn(true)
	end)
	self:SetWndClick(self.mReduce, function()
		self:ClickSliderBtn(false)
	end)
	self:SetWndClick(self.mValueBg, function()
		local tab = {}
		tab.inputTran = self.mValueBg
		tab.minNum = self.minValue
		tab.maxNum = self.maxValue
		tab.defaultNum = tonumber(self.mValue.text)
		tab.inputFunc = function(numStr, cmd)
			if self:IsWndClosed() then
				return
			end
			local num = tonumber(numStr)
			if num then
				if cmd == "C" then
					self.slider:SetUIProgress(0)
				elseif cmd == "D" then

				else
					self.slider:SetUIProgress(num)
				end
			end
		end
		GF.OpenWndUp("UINuoardUI", tab)
	end)
end

function UIItemSyePop:InitData()
	self.refId = self:GetWndArg("refId")
	self.defaultNum = self:GetWndArg("defaultNum") or 0
	self.maxValue = self:GetWndArg("maxValue") or 0
	self.minValue = self:GetWndArg("minValue") or 0
	self.func = self:GetWndArg("func")
end



------------------------------------------------------------------
return UIItemSyePop