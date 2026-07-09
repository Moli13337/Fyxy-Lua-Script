---
--- Created by Administrator.
--- DateTime: 2023/10/25 20:09:53
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEqSetting:LWnd
local UIEqSetting = LxWndClass("UIEqSetting", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEqSetting:UIEqSetting()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEqSetting:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEqSetting:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEqSetting:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitData()
	self:SetStaticContent()
	self:InitUIEvent()

	self:RefreshContent()
end

function UIEqSetting:InitData()

    local set = gModelInstance:GetOutfitSet()
    self._toggleValue = {}
    for k,v in pairs(set) do
        self._toggleValue[k] = true
    end


	self._toggleData =
	{
		[1] =
		{
			text = ccClientText(22004),
			toggleDelegate = function(value)
				self._toggleValue[1] = value
			end,
		},
		[2] =
		{
			text = ccClientText(22005),
			toggleDelegate = function(value)
				self._toggleValue[2] = value

			end,

		},
		[3] =
		{
			text = ccClientText(22006),
			toggleDelegate = function(value)
				self._toggleValue[3] = value
			end,

		},
		[4] =
		{
			text = ccClientText(22007),
			toggleDelegate = function(value)
				self._toggleValue[4] = value
			end,
		},
	}


end

function UIEqSetting:RefreshContent()
	for k = 1,4 do
		local toggle = self:FindWndTrans(self.mLayout,'Toggle_'..k)
		local data = self._toggleData[k]
		local text = self:FindWndTrans(toggle,'XUIText')
		local colorStr = gModelItem:FormatQualityStr(data.text,k)
		self:SetWndText(text,colorStr)
        self:SetWndToggleValue(toggle,self._toggleValue[k] or false)
        self:SetWndToggleDelegate(toggle,data.toggleDelegate)
	end
end

function UIEqSetting:SaveSetting()
	local set = self._toggleValue
	if not set then
		set = gModelInstance:GetOutfitSet()
	end
	gModelInstance:OnInstanceRecycleSetReq(set)
	self:WndClose()
end

function UIEqSetting:InitUIEvent()
	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mMask,function ()
		self:WndClose()
	end)

	self:SetWndClick(self.mHelpBtn,function ()
		GF.OpenWnd("UIBzTips",{refId= 88})
	end)

    self:SetWndClick(self.mOkBtn,function ()
        self:SaveSetting()
    end)

    self:SetWndClick(self.mCancelBtn,function ()
        self:WndClose()
    end)
end

function UIEqSetting:SetStaticContent()
	local str =ccClientText(22000)-- "装备设置"
	self:SetWndText(self.mLblBiaoti,str)

	str =ccClientText(22001)-- "取消"
	self:SetWndButtonText(self.mCancelBtn,str)
	str =ccClientText(22002)-- "确定"
	self:SetWndButtonText(self.mOkBtn,str)

	str = ccClientText(22003)-- "选中的装备，在领取奖励时自动转化为装备经验道具"
	self:SetWndText(self.mIntro,str)

end

------------------------------------------------------------------
return UIEqSetting


