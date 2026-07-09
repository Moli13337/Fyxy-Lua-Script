---
--- Created by Administrator.
--- DateTime: 2025/2/18 17:38:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIExptrance:LWnd
local UIExptrance = LxWndClass("UIExptrance", LWnd)
------------------------------------------------------------------

local UIBtnTabList = LXImport('LApp.UI.Common.UIBtnTabList')

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIExptrance:UIExptrance()
	---@type UIBtnTabList
	self._uiBtnTabList = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIExptrance:OnWndClose()
	if self._uiBtnTabList then
		self._uiBtnTabList:Destroy()
		self._uiBtnTabList = nil
	end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIExptrance:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIExptrance:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitTexts()
	self:InitTabScroll()
	self:InitStaticDatas()
	self:InitDatas()
	self:InitClicks()
	self:InitEvents()
	self:RefreshBtnTemplatesStatus()
	self:RefreshBtnTemplatesRP()
	self:RefreshView()
end

function UIExptrance:InitEvents()
	self:WndEventRecv(EventNames.ON_CLICK_MAIN_BTN,function(index)
		if index ~= 1 then
			GF.CloseWndByName("UIDivineWeaponWin")
			self:WndClose()
		end
	end)
end

function UIExptrance:InitTabScroll()
	--- 后续如果有新增页签按钮，则在这里注册
	---@type UIBtnTabList
	self._uiBtnTabList = UIBtnTabList:New()
end

function UIExptrance:InitClicks()
	self:SetWndClick(self.mCloseBtn,function() self:WndCloseAndBack() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mHelpBtn,function() self:OnClickHelpBtn() end)

	local btnTemplates = self._btnTemplates
	for i,v in ipairs(btnTemplates) do
		self:SetWndClick(v.btnTrans,function()
			gModelDailyGameEnter:ClickEnterItem(v)
		end)
	end
end

function UIExptrance:InitDatas()

end

function UIExptrance:RefreshBtnTemplatesStatus()
	local btnTemplates = self._btnTemplates
	for i,v in ipairs(btnTemplates) do
		local isOpen = self:IsTemplateOpen(v)
		self:SetWndButtonGray(v.btnTrans,not isOpen)
	end
end

function UIExptrance:InitStaticDatas()
	local btnTemplates = {}
	---@type V_DailyGameRef[]
	local refs = gModelDailyGameEnter:GetExpandDevelopDatas()
	for i,v in ipairs(refs) do
		local btnTrans = self["mBtnTemplate"..v.sort]
		local functionId = v.functionId
		local refId = v.refId
		table.insert(btnTemplates,{
			btnTrans = btnTrans,
			functionId = functionId,
			btnName = ccLngText(v.name),
			checkRPFunc = function()
				return gModelDailyGameEnter:CheckDailyGameRP(refId)
			end,
		})
	end
	self._btnTemplates = btnTemplates

	for i,v in ipairs(btnTemplates) do
		self:SetWndButtonText(v.btnTrans,v.btnName)
	end
end

function UIExptrance:RefreshView()

end

function UIExptrance:IsTemplateOpen(itemdata,showTips)
	local functionId = itemdata.functionId
	if functionId and functionId > 0 then
		if not gModelFunctionOpen:CheckIsOpened(functionId,showTips) then
			return false
		end
	end
	return true
end

function UIExptrance:RefreshBtnTemplatesRP()
	local btnTemplates = self._btnTemplates
	for i,v in ipairs(btnTemplates) do
		local showRP = false
		local checkRPFunc = v.checkRPFunc
		if checkRPFunc then
			showRP = checkRPFunc()
		end
		self:SetRed(v.btnTrans,showRP)
	end
end

function UIExptrance:OnClickHelpBtn()
	printInfoNR("暂无定义")
end

function UIExptrance:InitTexts()
	self:SetWndText(self.mTitle,ccClientText(46219))
	self:SetWndText(self.mTxtClose,ccClientText(30205))
end

------------------------------------------------------------------
return UIExptrance