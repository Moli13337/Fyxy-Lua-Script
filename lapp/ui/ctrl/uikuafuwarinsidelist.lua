---
--- Created by Administrator.
--- DateTime: 2024/6/14 17:02:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIKuafuWarInsideList:LWnd
local UIKuafuWarInsideList = LxWndClass("UIKuafuWarInsideList", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuWarInsideList:UIKuafuWarInsideList()
	self.tabBtnData = {
		ccClientText(43820),
		ccClientText(43821)
	}
	self.tabBtnTrans = {}
	self.uiList = {}
	self.uiHeadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuWarInsideList:OnWndClose()
	self:ClearCommonIconList(self.uiHeadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuWarInsideList:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuWarInsideList:OnStart()
	LWnd.OnStart(self)
	self:InitUI()


	self._isVie =gLGameLanguage:IsVieVersion()
	self:InitEvent()
	self:InitMenber()
	self:InitText()
	self:InitTabList()
	self:ClickTabBtn(1)
	self:SetNumText()
	gModelRedPoint:SetRedPointClicked(13900060)
	gModelRedPoint:RedPointClickReq(13900060)
end

function UIKuafuWarInsideList:InitEvent()
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBg, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mHelpBtn, function()
		GF.OpenWnd("UIBzTips", { refId = 173 })
	end)

	self:WndEventRecv("CrossWarTempleInfoResp", function()
		self:OnUpdate()
	end)
	self:WndEventRecv("CrossWarTempleRetinueApplyResp", function()
		self:OnUpdate()
	end)
	self:WndEventRecv("CrossWarTempleFollowResp", function()
		self:OnUpdate()
	end)
end

function UIKuafuWarInsideList:InitText()
	self:SetWndText(self.mLblBiaoti, ccClientText(43836))
end

function UIKuafuWarInsideList:ClickTabBtn(index)
	if self.curClick == index then
		return
	end
	self.curClick = index
	for i, v in ipairs(self.tabBtnTrans) do
		self:SetWndTabStatus(v, index == i and 0 or 1)
		CS.ShowObject(self.listData[i].trans, index == i)
	end
	self:SetList(index)
end

function UIKuafuWarInsideList:DrawRetinue(_, item, data)
	local headIcon = self:FindWndTrans(item,"HeadIcon")
	local leve = CS.FindTrans(item,"HeadIcon/lvBg/level")
	local nameText = self:FindWndTrans(item,"NameText")
	local powerText = self:FindWndTrans(item,"PowerBg/PowerText")
	local numText = self:FindWndTrans(item,"NumText")
	local applyBtn = self:FindWndTrans(item,"ApplyBtn")
	local cancelBtn = self:FindWndTrans(item,"CancelBtn")
	local garyBtn = self:FindWndTrans(item,"GaryBtn")
	local rankIcon = self:FindWndTrans(item, "Rank/RankIcon")
	local rankBg = self:FindWndTrans(item, "Rank/RankBg")
	local rankText = self:FindWndTrans(rankBg, "Text")

	if self._isVie then
		self:SetAnchorPos(leve,Vector2.New(0,-8))
	end

	local cfg = gModelCrossWar:GetWarDomainRefById(data.rank)
	self:SetHeadIcon(headIcon, data.playerInfo)
	local name = data.playerInfo.robot and gModelCrossWar:GetRobotName() or data.playerInfo._name
	self:SetWndText(nameText, name)
	self:SetWndText(powerText, LUtil.NumberCoversion(data.power))
	self:SetWndText(numText, data.retinueNum .. "/" .. cfg.protectNum)
	self:SetWndText(self:FindWndTrans(applyBtn, "Text"), ccClientText(43837))
	self:SetWndText(self:FindWndTrans(cancelBtn, "Text"), ccClientText(43838))
	self:SetWndText(self:FindWndTrans(garyBtn, "Text"), ccClientText(43839))
	if data.retinueNum < cfg.protectNum then
		local isRetinue = data.retinueStatus == 1
		CS.ShowObject(applyBtn, not isRetinue)
		CS.ShowObject(cancelBtn, isRetinue)
		CS.ShowObject(garyBtn, false)
	else
		CS.ShowObject(applyBtn, false)
		CS.ShowObject(cancelBtn, false)
		CS.ShowObject(garyBtn, true)
	end
	if data.rank > 3 then
		self:SetWndText(rankText, data.rank)
	else
		self:SetWndEasyImage(rankIcon, "public_num_" .. data.rank)
	end
	CS.ShowObject(rankIcon, data.rank <= 3)
	CS.ShowObject(rankBg, data.rank > 3)

	self:SetWndClick(applyBtn, function()
		if gModelCrossWar:GetApplyNum() >= gModelCrossWar:GetMaxApplyNum() then
			GF.ShowMessage(ccClientText(43840))
		end
		gModelCrossWar:CrossWarTempleRetinueApplyReq(1, data.rank)
	end)
	self:SetWndClick(cancelBtn, function()
		gModelGeneral:OpenUIOrdinTips({
			refId = 150011,
			func = function()
				gModelCrossWar:CrossWarTempleRetinueApplyReq(2, data.rank)
			end,
			para = {data.playerInfo._name}
		})
	end)
	self:SetWndClick(garyBtn, function()
		GF.ShowMessage(ccClientText(43841))
	end)
end

function UIKuafuWarInsideList:DrawFollow(_, item, data)
	local headIcon = self:FindWndTrans(item,"HeadIcon")
	local nameText = self:FindWndTrans(item,"NameText")
	local powerText = self:FindWndTrans(item,"PowerBg/PowerText")
	local numText = self:FindWndTrans(item,"NumText")
	local applyBtn = self:FindWndTrans(item,"ApplyBtn")
	local cancelBtn = self:FindWndTrans(item,"CancelBtn")
	local garyBtn = self:FindWndTrans(item,"GaryBtn")
	local rankIcon = self:FindWndTrans(item, "Rank/RankIcon")
	local rankBg = self:FindWndTrans(item, "Rank/RankBg")
	local rankText = self:FindWndTrans(rankBg, "Text")

	local cfg = gModelCrossWar:GetWarDomainRefById(data.rank)
	self:SetHeadIcon(headIcon, data.playerInfo)
	local name = data.playerInfo.robot and gModelCrossWar:GetRobotName() or data.playerInfo._name
	self:SetWndText(nameText, name)
	self:SetWndText(powerText, LUtil.NumberCoversion(data.power))
	self:SetWndText(numText, data.followNum .. "/" .. cfg.followNum)
	self:SetWndText(self:FindWndTrans(applyBtn, "Text"), ccClientText(43842))
	self:SetWndText(self:FindWndTrans(garyBtn, "Text"), ccClientText(43839))
	CS.ShowObject(applyBtn, data.followNum < cfg.followNum)
	CS.ShowObject(garyBtn, data.followNum >= cfg.followNum)
	CS.ShowObject(cancelBtn, false)
	if data.rank > 3 then
		self:SetWndText(rankText, data.rank)
	else
		self:SetWndEasyImage(rankIcon, "public_num_" .. data.rank)
	end
	CS.ShowObject(rankIcon, data.rank <= 3)
	CS.ShowObject(rankBg, data.rank > 3)
	self:SetWndClick(applyBtn, function()
		gModelCrossWar:CrossWarTempleFollowReq(1, data.rank)
	end)
	self:SetWndClick(garyBtn, function()
		GF.ShowMessage(ccClientText(43843))
	end)
end

function UIKuafuWarInsideList:OnDrawTab(_, item, data, index)
	self:SetWndTabText(item, data)
	self:SetWndTabStatus(item, 0)
	self.tabBtnTrans[index] = item
	self:SetWndClick(item, function()
		self:ClickTabBtn(index)
	end)
end

function UIKuafuWarInsideList:InitTabList()
	self.tabList = self:GetUIScroll("TabBtnList")
	self.tabList:Create(self.mTabBtnList, self.tabBtnData, function(...) self:OnDrawTab(...) end)

	local showTab = self:GetWndArg("showTab")
	CS.ShowObject(self.mTabBtnList, showTab)
end

function UIKuafuWarInsideList:SetHeadIcon(trans, data)
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

function UIKuafuWarInsideList:InitMenber()
	self.listData = {
		{
			trans = self.mRetinueList,
			func = 	function(...)
				self:DrawRetinue(...)
			end
		},
		{
			trans = self.mFollowList,
			func = 	function(...)
				self:DrawFollow(...)
			end
		},
	}
end

function UIKuafuWarInsideList:SetList(index)
	local data = self.listData[index]
	local list = gModelCrossWar:GetInnerTempleInfo().applyInfoList
	if not self.uiList[index] then
		self.uiList[index] = self:GetUIScroll("List" .. index)
		self.uiList[index]:Create(data.trans, list, data.func, UIItemList.SUPER)
	else
		self.uiList[index]:ResetList(list)
		self.uiList[index]:DrawAllItems()
	end
end

function UIKuafuWarInsideList:OnUpdate()
	if table.isempty(gModelCrossWar:GetSelfInsideInfo()) then
		self:SetNumText()
		self:SetList(self.curClick)
	else
		self:WndClose()
		GF.OpenWnd("UIKuafuWarInside")
	end
end

function UIKuafuWarInsideList:SetNumText()
	local s = ccClientText(43844)
	self:SetWndText(self.mNumText, string.replace(s, gModelCrossWar:GetApplyNum(), gModelCrossWar:GetMaxApplyNum()))
end



------------------------------------------------------------------
return UIKuafuWarInsideList