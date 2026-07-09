---
--- Created by Administrator.
--- DateTime: 2024/11/5 15:39:40
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGameHelperEndLess:LChildWnd
local UISubGameHelperEndLess = LxWndClass("UISubGameHelperEndLess", LChildWnd)
local changeData = {
	{
		refId = 1,
		name = ccClientText(24271)
	},
	{
		refId = 2,
		name = ccClientText(24272)
	},
}
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGameHelperEndLess:UISubGameHelperEndLess()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGameHelperEndLess:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGameHelperEndLess:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGameHelperEndLess:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:UpdateSetting()
end

function UISubGameHelperEndLess:DrawBuffList(_, trans, data)
	local select = CS.FindTrans(trans, "Select")

	self:SetTextTile(trans, ccLngText(data.name))
	CS.ShowObject(select, self.buffType == data.refId)

	self:SetWndClick(trans, function()
		local setting = {
			refId = 1153,
			parameter1 = 1,
			parameter2 = self.changeType,
			parameter3 = data.refId
		}
		gModelGameHelper:GameHelperSettingReq(2, setting)
		self:ClickBuffType()
	end)
end

function UISubGameHelperEndLess:InitBuffTypeList()
	local cfg = GameTable.EternalBuffRef
	local list = {}
	for _, v in ipairs(cfg) do
		table.insert(list, v)
	end
	self.buffUiList = self:GetUIScroll("buffUiList")
	self.buffUiList:Create(self.mBuffTypeList, list, function(...) self:DrawBuffList(...) end, UIItemList.SUPER)
end

function UISubGameHelperEndLess:DrawChangeList(_, trans, data)
	local select = CS.FindTrans(trans, "Select")

	self:SetTextTile(trans, ccLngText(data.name))
	CS.ShowObject(select, self.changeType == data.refId)

	self:SetWndClick(trans, function()
		local setting = {
			refId = 1153,
			parameter1 = 1,
			parameter2 = data.refId,
			parameter3 = self.buffType
		}
		gModelGameHelper:GameHelperSettingReq(2, setting)
		self:ClickChangeType()
	end)
end

function UISubGameHelperEndLess:ClickChangeType()
	self.onChangeType = not self.onChangeType
	self:SetWndTabStatus(self.mChangeTypeSelect, self.onChangeType and 0 or 1)

	self.onBuffType = false
	self:SetWndTabStatus(self.mBuffTypeSelect, self.onBuffType and 0 or 1)
end

function UISubGameHelperEndLess:InitCommon()
	------------------------------------------------------------------
	---member
	self.id = self:GetWndArg("id")
	local cfg = GameTable.AssistantTabRef[self.id]
	self.onBuffType = false
	self.onChangeType = false

	------------------------------------------------------------------
	---text
	self:SetTextTile(self.mTitle, ccLngText(cfg.name) .. ccClientText(24228))
	self:SetTextTile(self.mHelpToggle, ccClientText(24266))
	self:SetTextTile(self.mGoToggle, ccClientText(24267))
	self:SetTextTile(self.mBuffObj, ccClientText(24268))
	self:SetTextTile(self.mChangeObj, ccClientText(24269))
	self:SetTextTile(self.mBuffTypeSelect, ccClientText(24236))
	self:SetTextTile(self.mChangeTypeSelect, ccClientText(24236))

	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mHelpToggle, function()
		local v = self.helpToggle and 0 or 1
		local setting = {
			refId = 1151,
			parameter1 = v,
		}
		gModelGameHelper:GameHelperSettingReq(2, setting)
	end)
	self:SetWndClick(self.mGoToggle, function()
		local v = self.goToggle and 0 or 1
		local setting = {
			refId = 1152,
			parameter1 = v,
		}
		gModelGameHelper:GameHelperSettingReq(2, setting)
	end)
	self:SetWndClick(self.mBuffTypeSelect, function()
		self:ClickBuffType()
	end)
	self:SetWndClick(self.mChangeTypeSelect, function()
		self:ClickChangeType()
	end)
	self:SetWndClick(self.mFightTypeSelect, function()
		self:ClickFightType()
	end)

	------------------------------------------------------------------
	---order
	self:InitBuffTypeList()
	self:InitChangeTypeList()

	------------------------------------------------------------------
	---canvas
	local typeofCanvas = typeof(UnityEngine.Canvas)
	local wndSortOrder = self:GetWndSortOrder()
    local canvas = self.mChangeObj:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 2
	local canvas = self.mBuffObj:GetComponent(typeofCanvas)
    canvas.sortingOrder = wndSortOrder + 1

	------------------------------------------------------------------
	---event
	self:WndEventRecv("GameHelperSettingResp", function()
		self:UpdateSetting()
	end)
end

function UISubGameHelperEndLess:UpdateSetting()
	local setting = gModelGameHelper:GetSettingById(1151)
	self.helpToggle = setting.parameter1 == 1
	self:SetWndTabStatus(self.mHelpToggle, self.helpToggle and 0 or 1)

	local setting = gModelGameHelper:GetSettingById(1152)
	self.goToggle = setting.parameter1 == 1
	self:SetWndTabStatus(self.mGoToggle, self.goToggle and 0 or 1)

	local setting = gModelGameHelper:GetSettingById(1153)
	self.changeType = setting.parameter2
	local data = changeData[self.changeType]
	local s = data and data.name or ccClientText(24236)
	self:SetTextTile(self.mChangeTypeSelect, s)
	if self.changeUiList then
		self.changeUiList:DrawAllItems()
	end

	self.buffType = setting.parameter3
	local cfg = GameTable.EternalBuffRef[self.buffType]
	local s = self.buffType ~= 0 and ccLngText(cfg.name) or ccClientText(24236)
	self:SetTextTile(self.mBuffTypeSelect, s)
	if self.buffUiList then
		self.buffUiList:DrawAllItems()
	end
end

function UISubGameHelperEndLess:InitChangeTypeList()
	self.changeUiList = self:GetUIScroll("changeUiList")
	self.changeUiList:Create(self.mChangeTypeList, changeData, function(...) self:DrawChangeList(...) end, UIItemList.SUPER)
end

function UISubGameHelperEndLess:ClickBuffType()
	self.onBuffType = not self.onBuffType
	self:SetWndTabStatus(self.mBuffTypeSelect, self.onBuffType and 0 or 1)

	self.onChangeType = false
	self:SetWndTabStatus(self.mChangeTypeSelect, self.onChangeType and 0 or 1)
end



------------------------------------------------------------------
return UISubGameHelperEndLess