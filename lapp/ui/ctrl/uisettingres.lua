---
--- Created by admin-pc.
--- DateTime: 2025/2/11 23:22:17
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISettingRes:LWnd
local UISettingRes = LxWndClass("UISettingRes", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISettingRes:UISettingRes()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISettingRes:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISettingRes:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISettingRes:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:InitView()
	self:InitUIEvent()
end

function UISettingRes:SelKey(keyIndex)
	self._selIndex = keyIndex
	self:InitListView()
end

function UISettingRes:ListItem(list , item, itemdata, itempos)
	local nameIcon = self:FindWndTrans(item, "UIText")
	local key = itemdata.key

	self:SetWndText(nameIcon, itemdata.name)

	self:SetWndToggleValue(item, key == self._selIndex)
	self:SetWndToggleDelegate(item,function (value)
		if value then
			self:SelKey(key)
		end
	end)
end

function UISettingRes:InitUIEvent()
	self:SetWndClick(self.mMaskObj,function ()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnClose,function ()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnCancel,function ()
		self:WndClose()
	end, LSoundConst.CLICK_CLOSE_COMMON)

	self:SetWndClick(self.mBtnOK,function ()
		self:OnClickOK()
	end, LSoundConst.CLICK_CLOSE_COMMON)
end

function UISettingRes:OnClickOK()
	LPlayerPrefs.SetForceSensitiveRes(self._selIndex == 1 and "1" or "0")
	self:WndClose()
end

function UISettingRes:InitView()
	self:SetXUITextText(self.mTitleText, ccClientText(15072))

	self:SetWndButtonText(self.mBtnCancel,ccClientText(10101))
	self:SetWndButtonText(self.mBtnOK,ccClientText(10102))

	self._contentNameList = {
		{key = 0, name = ccClientText(15073)},
		{key = 1, name = ccClientText(15074)},
	}

	self._selIndex = LPlayerPrefs.GetIsForceSensitiveRes() > 1 and 1 or 0

	self:InitListView()
end

function UISettingRes:InitListView()
	local listData	  = self._contentNameList
	local uiList = self._uiList
	if uiList then
		uiList:RefreshList(listData)
	else
		uiList = self:GetUIScroll("LangList")
		self._uiList = uiList
		uiList:Create(self.mContentRoot,listData,function (...) self:ListItem(...) end)
	end
	if #listData > 6 then
		uiList:EnableScroll(true,false)
	end
end

------------------------------------------------------------------
return UISettingRes