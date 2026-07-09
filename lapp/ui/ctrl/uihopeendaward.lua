---
--- Created by Administrator.
--- DateTime: 2023/10/12 16:55:26
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEndAward:LWnd
local UIHopeEndAward = LxWndClass("UIHopeEndAward", LWnd)
local Tweening = DG.Tweening
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEndAward:UIHopeEndAward()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEndAward:OnWndClose()
	self:ClearTween()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEndAward:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEndAward:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:SetTextTile(self.mSubTitle,ccClientText(20446))
	self:SetWndButtonText(self.mEndBtn,ccClientText(20447))
	self:SetWndText(self.mCloseTip,ccClientText(10103))
	self:InitEvent()
	self:InitMsg()
	self._itemList = {}
	gModelFastDreamTrip:OnDreamTripStartEventReq(-1)
end

function UIHopeEndAward:ClearTween()
	if self._seq then
		self._seq:Kill(false)
		self._seq = nil
	end

	if self._iconList then
		self._iconList:Destroy()
		self._iconList = nil
	end
end

function UIHopeEndAward:InitItemList()
	local itemList = self._itemList
	local uiIconEasyList = self._iconList
	if not uiIconEasyList then
		uiIconEasyList = UIIconEasyList:New()
		self._iconList = uiIconEasyList
		uiIconEasyList:Create(self, self.mItemList)
		uiIconEasyList:EnableIconAni(true)
	end
	uiIconEasyList:RefreshList(itemList)


	local effectName = "fx_ui_gongxihuode"
	self:CreateWndEffect(self.mTitle,effectName,effectName,120)
end

function UIHopeEndAward:InitMsg()
	self:WndNetMsgRecv(LProtoIds.DreamTripStartEventResp,function(pb,ret)
		local endInfo = pb.endInfo
		if endInfo then
			local serverData = gModelFastDreamTrip:GetEventInfoServerDataByPb(endInfo)
			self._itemList = serverData.reward
			self:StartTween()
		end
	end)
end

function UIHopeEndAward:InitEvent()
	self:SetWndClick(self.mMask,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mEndBtn,function()
		self:WndClose()
	end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIHopeEndAward:StartTween()
	local root = self.mCommonBg_5
	root.transform.localRotation = Quaternion.Euler(90,0,0)
	local seq = Tweening.DOTween.Sequence()
	local duration = 0.4
	local rotateTween = root.transform:DORotate(Vector3.New(0,0,0),duration)
	seq:Append(rotateTween)
	seq:InsertCallback(0.1,function ()
		self:InitItemList()
	end)
	seq:OnComplete(function()
		self._seq = nil
	end)
	seq:PlayForward()

	self._seq = seq
end


------------------------------------------------------------------
return UIHopeEndAward


