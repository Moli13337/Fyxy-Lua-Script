---
--- Created by Administrator.
--- DateTime: 2023/10/24 17:24
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIIntegralYell:LWnd
local UIIntegralYell = LxWndClass("UIIntegralYell", LWnd)


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIIntegralYell:UIIntegralYell()
	---@type CommonIcon
	self._itemIconCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIIntegralYell:OnWndClose()
	if self._itemIconCls then
		self._itemIconCls:Destroy()
		self._itemIconCls = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIIntegralYell:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIIntegralYell:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:RefreshView()
	self:SetXUITextText(self.mCloseTip,ccClientText(10103))
end

function UIIntegralYell:RefreshView()
	local wndData = self._wndData
	local title = ccLngText(wndData.title)
	self:SetXUITextText(self.mTitle,title)

	local btnText = ccLngText(wndData.btnTxt)
	local strs = string.split(btnText,"|")
	for i,v in ipairs(self._btnNameList) do
		self:SetXUITextText(v,strs[i])
	end

	local btnPng = wndData.btnPng
	local pngStr = string.split(btnPng,"|")
	for i,v in ipairs(self._btnList) do
		self:SetWndEasyImage(v,pngStr[i])
	end

	local text = ccLngText(wndData.text)
	text = string.replace(text,self._num)
	self:SetXUITextText(self.mContent,text)

	local str = ccClientText(11615)
	str = string.replace(str,self._vipLimit)
	self:SetXUITextText(self.mYaoqiu,str)

	local integralNeedItem = GameTable.SummonConfigRef["integralNeedItem"]
	local integralShowItem = GameTable.SummonConfigRef["integralShowItem"]
	local strList = string.split(integralShowItem,"=")
	local refId = tonumber(strList[2])
	local num = tonumber(strList[3])

	local baseClass = self._itemIconCls
	if not baseClass then
		baseClass = CommonIcon:New()
		self._itemIconCls = baseClass
		baseClass:Create(self.mItemIcon)
	end
	local itemType = tonumber(strList[1])
	baseClass:SetCommonReward(itemType, refId, num)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	self:SetIconClickScale(self.mItemIcon, true)
	self:SetWndClick(self.mItemIcon, function()
		local data =
		{
			itemId = refId,
			itemType = itemType,
			itemNum = num,
		}
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
	self._consumeRefId = refId
end

function UIIntegralYell:InitMsg()
	self:WndNetMsgRecv(LProtoIds.CallHeroResp, function()
		self:WndClose()
	end)
end

function UIIntegralYell:InitEvent()
	self:SetWndClick(self.mHeroIcon,function()
		local str = GameTable.SummonConfigRef["integralShowItem"]
		local strList = string.split(str,"=")
		local refId = tonumber(strList[2])
		gModelGeneral:OpenItemInfoTip(refId)
	end)
	self:SetWndClick(self.mMask,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mCloseBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mCancelBtn,function()
		self:WndClose()
	end)
	self:SetWndClick(self.mEnterBtn,function()
		gModelCallHero:OnCallHeroReq(0,1, self._consumeRefId)
	end)
end

function UIIntegralYell:InitData()
	self._vipLimit = self:GetWndArg("vip")
	self._num = self:GetWndArg("num")
	self._wndId = 50102
	self._wndData = GameTable.UIWindowAttRef[self._wndId]
	self._btnNameList = {
		self.mCancelBtnName,
		self.mEnterBtnName,
	}
	self._btnList = {
		self.mCancelBtn,
		self.mEnterBtn,
	}
end

------------------------------------------------------------------
return UIIntegralYell


