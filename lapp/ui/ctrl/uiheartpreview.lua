---
--- Created by Administrator.
--- DateTime: 2023/10/11 17:34:27
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHeartPreview:LWnd
local UIHeartPreview = LxWndClass("UIHeartPreview", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHeartPreview:UIHeartPreview()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHeartPreview:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHeartPreview:OnCreate()
	LWnd.OnCreate(self)
	self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHeartPreview:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitUIEvent()

	self:OnWndRefresh()
end

function UIHeartPreview:RefreshSetShow()
	local curFigure = gModelOneNight:GetLoginFigure()
	local isSet = curFigure == self._itemdata.refId
	CS.ShowObject(self.mTag,isSet)
	CS.ShowObject(self.mBtnSet,not isSet)
end

function UIHeartPreview:InitUIEvent()
	self:SetWndClick(self.mBtnSet,function ()
		gModelOneNight:SetLoginFigure(self._itemdata.refId)

		local str = ccClientText(26107)-- "设置成功"
		GF.ShowMessage(str)
	end)

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end)

	self:WndEventRecv(EventNames.REFRESH_THEME_USING,function (type)
		if type ~= 3 then
			return
		end

		self:RefreshSetShow()

	end)
end


function UIHeartPreview:OnWndRefresh()

	local itemdata = self:GetWndArg("itemdata")
	self._itemdata = itemdata

	local data =
	{
		trans = self.mEff1,
		effName = itemdata.effectRes,
		effKey = "effect1",
		bDefaultSorting = true,
		sortOrder = 1,
	}

	self:CreateWndEffectImpl(data)

	local data =
	{
		trans = self.mEff2,
		effName = itemdata.uiRes1,
		effKey = "effect2",
		bDefaultSorting = true,
		sortOrder = 30,

	}

	self:CreateWndEffectImpl(data)

	local data =
	{
		trans = self.mEff3,
		effName = itemdata.uiRes2,
		effKey = "effect3",
		bDefaultSorting = true,
		sortOrder = 40,
	}

	self:CreateWndEffectImpl(data)

	local data =
	{
		trans = self.mSpine1,
		spineName = itemdata.spine,
		key = "spine1",
		sortOrder = 20,
	}

	self:CreateWndSpineImpl(data)


	self:RefreshSetShow()

	local str =ccClientText(26110)-- "设为登录形象"
	self:SetTextTile(self.mBtnSet,str)
end


------------------------------------------------------------------
return UIHeartPreview


