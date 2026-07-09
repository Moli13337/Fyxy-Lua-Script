---
--- Created by Administrator.
--- DateTime: 2023/10/7 15:37:11
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIReMelting:LWnd
local UIReMelting = LxWndClass("UIReMelting", LWnd)

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIReMelting:UIReMelting()
	---@type CommonIcon
	self._itemIconCls = nil
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIReMelting:OnWndClose()
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
function UIReMelting:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIReMelting:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self:SetWndText(self.mTitle,ccClientText(13240))
	self:SetWndButtonText(self.mCancelBtn,ccClientText(10101))
	self:SetWndButtonText(self.mEnterBtn,ccClientText(13265))
	--self:SetWndText(self.mCloseTip,ccClientText(10103))

	self:InitData()
	self:InitEvent()
	self:InitMsg()
	self:Refresh()
end

function UIReMelting:Refresh()
	local meltingNeed = GameTable.MagicRuneConfigRef["meltingNeed"]
	local str = string.split(meltingNeed,"=")
	local needRefId,needNum = tonumber(str[2]),tonumber(str[3])
	local haveNum = gModelItem:GetNumByRefId(needRefId)
	local color = "c81212ff"
	if haveNum >= needNum then color = "139057ff" end
	local txt = string.replace(ccClientText(13231),color,haveNum,needNum)
	self:SetWndText(self.mYaoqiu,txt)

	local meltingQualityShow = GameTable.MagicRuneConfigRef["meltingQualityShow"]
	str = string.split(meltingQualityShow,"=")
	needRefId,needNum = tonumber(str[2]),tonumber(str[3])
	local itemType = tonumber(str[1])

	local baseClass = self._itemIconCls
	if not baseClass then
		baseClass = CommonIcon:New(self)
		self._itemIconCls = baseClass
		baseClass:Create(self.mItemIcon)
	end

	baseClass:SetCommonReward(itemType, needRefId, needNum)
	baseClass:EnableShowNum(true)
	baseClass:DoApply()

	self:SetIconClickScale(self.mItemIcon, true)
	self:SetWndClick(self.mItemIcon,function()
		local data =
		{
			itemId = needRefId,
			itemType = itemType,
			itemNum = needNum,
		}
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)

	self:SetWndText(self.mContent,ccClientText(13259))
end

function UIReMelting:InitMsg()
	self:WndNetMsgRecv(LProtoIds.RuneMeltingResp,function() self:WndClose() end)
end

function UIReMelting:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end)
	self:SetWndClick(self.mCloseBtn,function() self:WndClose() end)
	self:SetWndClick(self.mCancelBtn,function() self:WndClose() end)
	self:SetWndClick(self.mEnterBtn,function() gModelRune:OnRuneMeltingReq() end)
end

function UIReMelting:InitData()

end
------------------------------------------------------------------
return UIReMelting


