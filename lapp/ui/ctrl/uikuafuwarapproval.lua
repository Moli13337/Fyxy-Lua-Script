---
--- Created by Administrator.
--- DateTime: 2024/6/14 15:12:31
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuWarApproval:LWnd
local UIKuafuWarApproval = LxWndClass("UIKuafuWarApproval", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuWarApproval:UIKuafuWarApproval()
	self.uiHeadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuWarApproval:OnWndClose()
	self:ClearCommonIconList(self.uiHeadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuWarApproval:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuWarApproval:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitText()
	self:UpdateList()

	gModelRedPoint:SetRedPointClicked(13900050)
	gModelRedPoint:RedPointClickReq(13900050)
	gModelRedPoint:ShowPointRed(13900050, false)
end

function UIKuafuWarApproval:SetHeadIcon(trans, data)
	local icon = self:FindWndTrans(trans, "IconBg/Icon")
	local headFrame = self:FindWndTrans(trans, "headFrame")

	if not data or (data._playerId and data._playerId == 0) then
		self:SetWndEasyImage(icon, "icon_role_chat_0")
		CS.ShowObject(headFrame, false)
		return
	end
	local InstanceID = trans:GetInstanceID()

	local playerInfo = {
		trans = trans,
		playerId = data._playerId,
		icon = data._head,
		headFrame = data._headFrame,
		level = data._grade,
	}
	if not self.uiHeadList[InstanceID] then
		self.uiHeadList[InstanceID] = HeadIcon:New(self)
	end
	self.uiHeadList[InstanceID]:SetHeadData(playerInfo)
	self:SetWndClick(trans, function()
		if data and data._playerId ~= 0 then
			gModelGeneral:PlayerShowReq(
				data._playerId,
				LCombatTypeConst.COMBAT_MAIN,
				LPlayerShowConst.OTHER_SYSTEM
			)
		end
	end)
end

function UIKuafuWarApproval:InitEvent()
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBg, function()
		self:WndClose()
	end)

	self:WndEventRecv("CrossWarTempleInfoResp", function()
		self:UpdateList()
	end)
	self:WndEventRecv("CrossWarTempleRetinueApplyResp", function()
		self:UpdateList()
	end)

	self:SetWndClick(self.mNeglectBtn,function()
		--一键拒绝
		gModelCrossWar:CrossWarTempleRetinueApprovalReq(false, 0)
	end)

	self:SetWndClick(self.mConsentBtn,function()
		--一键接受
		gModelCrossWar:CrossWarTempleRetinueApprovalReq(true,0)
	end)
end

function UIKuafuWarApproval:DrawApproval(_, item, data)
	local headIcon = self:FindWndTrans(item, "HeadIcon")
	local nameText = self:FindWndTrans(item, "NameText")
	local timeText = self:FindWndTrans(item, "TimeText")
	local powerText = self:FindWndTrans(item, "PowerBg/PowerText")
	local okBtn = self:FindWndTrans(item, "OkBtn")
	local cancelBtn = self:FindWndTrans(item, "CancelBtn")

	self:SetHeadIcon(headIcon, data.playerInfo)
	self:SetWndText(nameText, data.playerInfo._name)
	self:SetWndText(powerText, LUtil.NumberCoversion(data.power))
	local time = GetTimestamp() - data.applyTime
	self:SetWndText(timeText, LUtil.FormatTimeToCn1(time))
	self:SetWndClick(okBtn, function()
		gModelCrossWar:CrossWarTempleRetinueApprovalReq(true, data.playerInfo._playerId)
	end)
	self:SetWndClick(cancelBtn, function()
		gModelCrossWar:CrossWarTempleRetinueApprovalReq(false, data.playerInfo._playerId)
	end)
end

function UIKuafuWarApproval:UpdateList()
	local list = gModelCrossWar:GetInnerTempleInfo().approvalList
	CS.ShowObject(self.mNoRecord2, #list == 0)
	if not self.rewardList then
		self.rewardList = self:GetUIScroll("mApprovalList")
		self.rewardList:Create(self.mApprovalList, list, function(...) self:DrawApproval(...) end, UIItemList.SUPER)
	else
		self.rewardList:ResetList(list)
		self.rewardList:DrawAllItems()
	end
end

function UIKuafuWarApproval:InitText()
	self:SetWndText(self.mLblBiaoti, ccClientText(43805))
	self:SetWndTabText(self.mRetinueBtn, ccClientText(43820))
	self:SetWndTabText(self.mFollowBtn, ccClientText(43821))
	local data =
	{
		refId= 37102,
		IntroTran= self.mEmptyText,
	}
	self:GetCommonEmptyList("_empty"):RefreshUI(data)

	local str = ccClientText(12065)
	self:SetWndButtonText(self.mNeglectBtn, str, nil, -2, -30)
	str = ccClientText(12066)
	self:SetWndButtonText(self.mConsentBtn, str, nil, -2, -30)
end



------------------------------------------------------------------
return UIKuafuWarApproval