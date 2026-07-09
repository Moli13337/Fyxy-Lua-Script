---
--- Created by Administrator.
--- DateTime: 2024/4/26 15:34:21
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubPkAllSchedule:LChildWnd
local UISubPkAllSchedule = LxWndClass("UISubPkAllSchedule", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubPkAllSchedule:UISubPkAllSchedule()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubPkAllSchedule:OnWndClose()
	self:CloseAllChild()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubPkAllSchedule:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubPkAllSchedule:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()

	self.downBtnData = {
		{
			name = ccClientText(17533),
			childWnd = "UISubPkGroup"
		},
		{
			name = ccClientText(11801),
			childWnd = "UISubPkSchedule"
		},
		{
			name = ccClientText(17535),
			childWnd = "UISubPkFinal"
		},
	}

	self.roundOpenIndex = {
		[0] = 1,
		1,  --海选1
		1,  --海选2
		1,  --海选3
		1,  --海选4
		1,  --海选5
		1,  --海选6
		2,  --64
		2,  --32
		2,  --16
		3,  --8
		3,  --半决
		3   --决赛
	}

	self.downBtn = {self.mBtn1, self.mBtn2, self.mBtn3}

	self:InitData()
	self:ClickDownBtn(self.roundOpenIndex[gModelArena:GetPeakRound()])
end

function UISubPkAllSchedule:ClickDownBtn(index)
	if self.curClick == index then return end
	self.curClick = index
	for i, v in ipairs(self.downBtn) do
		self:SetWndTabStatus(v, index == i and LWnd.StateOn or LWnd.StateOff)
	end
	self:CloseAllChild()
	self:CreateChildWnd(self.mChildRoot, self.downBtnData[index].childWnd)
end

function UISubPkAllSchedule:InitData()
	for i, v in ipairs(self.downBtn) do
		self:SetWndClick(v, function() self:ClickDownBtn(i) end)
		-- self:SetWndTabText(v, self.downBtnData[i].name)
	end
end



------------------------------------------------------------------
return UISubPkAllSchedule