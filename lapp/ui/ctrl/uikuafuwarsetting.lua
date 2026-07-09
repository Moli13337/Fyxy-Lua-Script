---
--- Created by Administrator.
--- DateTime: 2024/6/14 10:32:04
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuWarSetting:LWnd
local UIKuafuWarSetting = LxWndClass("UIKuafuWarSetting", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuWarSetting:UIKuafuWarSetting()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuWarSetting:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuWarSetting:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuWarSetting:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitMember()
	self:InitEvent()
	self:InitText()
	self:SetSetting()
end

function UIKuafuWarSetting:SetSetting()
	local data = gModelCrossWar:GetSetting()
	self:SetInputText(data.approvalLv)
	self.toggle1.isOn = data.isGuild == 1
	self.toggle2.isOn = data.isServer == 1
	self.toggle3.isOn = data.isFriend == 1
end

function UIKuafuWarSetting:InitEvent()
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBg, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mLvlInput, function()
		self:ClickLvlInput()
	end)
	self:SetWndClick(self.mAdd, function()
		self:ClickAdd()
	end)
	self:SetWndClick(self.mYesBtn, function()
		self:ClickYesBtn()
	end)
	self:SetWndClick(self.mToggle1, function()
		self:ClickToggle(1)
	end)
	self:SetWndClick(self.mToggle2, function()
		self:ClickToggle(2)
	end)
	self:SetWndClick(self.mToggle3, function()
		self:ClickToggle(3)
	end)
end

function UIKuafuWarSetting:SetInputText(input)
	local num = math.min(math.max(self.minLvl, input), self.maxLvl)
	self.curInput = num
	self:SetWndText(self.inputText, self.curInput)
end

function UIKuafuWarSetting:ClickToggle(i)
	local toggle = self["toggle" .. i]
	toggle.isOn = not toggle.isOn
end

function UIKuafuWarSetting:InitMember()
	self.inputText = self:FindWndTrans(self.mLvlInput, "Text")
	local toggle1 = self:FindWndTrans(self.mToggle1, "Toggle")
	local toggle2 = self:FindWndTrans(self.mToggle2, "Toggle")
	local toggle3 = self:FindWndTrans(self.mToggle3, "Toggle")
	self.toggle1 = self:FindWndToggle(toggle1)
	self.toggle2 = self:FindWndToggle(toggle2)
	self.toggle3 = self:FindWndToggle(toggle3)

	self.maxLvl = gModelCrossWar:GetAutoSetMaxLvl()
	self.minLvl = gModelCrossWar:GetAutoSetMinLvl()
end

function UIKuafuWarSetting:ClickYesBtn()
	local data = {
		approvalLv = self.curInput,
		isGuild = self.toggle1.isOn and 1 or 0,
		isServer = self.toggle2.isOn and 1 or 0,
		isFriend = self.toggle3.isOn and 1 or 0,
	}
	gModelCrossWar:CrossWarTempleMasterSettingReq(data)
	self:WndClose()
end

function UIKuafuWarSetting:ClickLvlInput()
	local func = function(input)
		if self:IsWndClosed() then
			return
		end
		self:SetWndText(self.inputText, input)
	end

	local closeFunc = function(input)
		if self:IsWndClosed() then
			return
		end
		self:SetInputText(input)
	end

	local para = {
		minNum = 0,
		maxNum = 999999,
		defaultNum = self.curInput,
		inputFunc = func,
		inputTran = self.mLvlInput,
		closeFunc = closeFunc
	}

	GF.OpenWnd("UINuoardUI", para)
end

function UIKuafuWarSetting:InitText()
	self:SetWndText(self.mLblBiaoti, ccClientText(43807))
	self:SetWndText(self.mConTitle, ccClientText(43813))
	self:SetWndText(self.mLvlText, ccClientText(43814))
	self:SetWndText(self.mAutoTitle, ccClientText(43815))
	self:SetWndButtonText(self.mYesBtn, ccClientText(43816))
	self:SetWndText(self:FindWndTrans(self.mToggle1, "Text"), ccClientText(43817))
	self:SetWndText(self:FindWndTrans(self.mToggle2, "Text"), ccClientText(43818))
	self:SetWndText(self:FindWndTrans(self.mToggle3, "Text"), ccClientText(43819))
end

function UIKuafuWarSetting:ClickAdd()
	local num = self.curInput + 10
	self:SetInputText(num)
end



------------------------------------------------------------------
return UIKuafuWarSetting