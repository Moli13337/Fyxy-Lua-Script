---
--- Created by Administrator.
--- DateTime: 2024/9/23 16:03:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPeLinkReplace:LWnd
local UIPeLinkReplace = LxWndClass("UIPeLinkReplace", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPeLinkReplace:UIPeLinkReplace()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPeLinkReplace:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPeLinkReplace:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPeLinkReplace:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self._uicommonList = {}
	local confirmFun = self:GetWndArg("func")
	self.listData = self:GetWndArg("itemList") or {}					-- 要展示的道具
	self:SetWndText(self.mTitle2,ccClientText(26310))
	self:SetWndText(self.mTxtContent,ccClientText(43771))
	self:SetWndButtonText(self.mBtnCancel,ccClientText(42045))
	self:SetWndButtonText(self.mBtnConfirm,ccClientText(42044))
	self:SetWndClick(self.mBtnCancel,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mCloseBtn2,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnConfirm,function()
		if not self.selectData then return end
		if confirmFun then confirmFun(self.selectData) end
		self:WndClose()
	end)
	self:InitScrollView()
end

function UIPeLinkReplace:uilist_OnDrad(list, item, itemdata, itempos)
	local refId = itemdata

	local instanceId = item:GetInstanceID()
	local iconRootTrans = CS.FindTrans(item,"CommonUI/IconRoot")
	local uicommonlist = self._uicommonList
	local baseClass = uicommonlist[instanceId]
	if not baseClass then
		baseClass = CommonIcon:New()
		uicommonlist[instanceId] = baseClass
		baseClass:Create(CS.FindTrans(iconRootTrans,"Icon"))
	end
	baseClass:SetPetDataSet(refId)
	baseClass:EnableShowNum(false)
	baseClass:DoApply()
	self:SetWndButtonGray(self.mBtnConfirm,not self.selectData)
	self:SetWndClick(iconRootTrans, function()
		local oldSel = self.selectItem
		if oldSel then
			local itemClass = self._uicommonList[oldSel:GetInstanceID()]
			itemClass:ShowGouImg(false)
		end
		baseClass:ShowGouImg(true)
		self.selectItem = item
		self.selectData = itemdata
		self:SetWndButtonGray(self.mBtnConfirm,not self.selectData)
	end)
	self:SetWndLongClick(iconRootTrans,function()
		GF.OpenWnd("UIPeView",{refId = refId,playerId = gModelPlayer:GetPlayerId()})
	end)
	self:SetIconClickScale(iconRootTrans, true)

	local uiNameTrans = CS.FindTrans(iconRootTrans, "UIName")
	local uiNameText = uiNameTrans and self:FindWndText(uiNameTrans) or nil
	if uiNameText then
		local itemname,itemcolor = baseClass:GetName()
		self:SetXUITextText(uiNameText, itemname or "")
		if itemcolor then
			self:SetXUITextColor(uiNameText, itemcolor)
		end
		--self:InitTextModeWithLanguage(uiNameTrans)

		self:InitTextShowWithLanguage(uiNameText)
	end
end

function UIPeLinkReplace:InitScrollView()
	local uiList = self._uiList
	if not uiList then
		uiList = UIListEasy:New()
		uiList:Create(self,self.mLimitList)
		uiList:EnableScroll(true,true)
		uiList:SetFuncOnItemDraw(function(...)
			self:uilist_OnDrad(...)
		end)
		self._uiList = uiList
	end
	uiList:RemoveAll()
	local rewardList = self.listData or {}
	for k,v in ipairs(rewardList) do
		uiList:AddData(k,v)
	end
    uiList:RefreshList()
end

------------------------------------------------------------------
return UIPeLinkReplace