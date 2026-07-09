---
--- Created by Administrator.
--- DateTime: 2023/10/6 21:29:17
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubInviteAct:LChildWnd
local UISubInviteAct = LxWndClass("UISubInviteAct", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubInviteAct:UISubInviteAct()
	self.rewardIconUIList = {}
	self.commonUIList = {}
	self.isBind = false
	self.isFrist = true
	self.copySelectShow = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubInviteAct:OnWndClose()
	self:ClearCommonIconList(self.commonUIList)
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubInviteAct:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubInviteAct:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitCommon()

	self.sid = self:GetWndArg("sid")
	gModelActivity:OnActivityPageReq(self.sid)
end

function UISubInviteAct:DrawTask(_, item, data, pos)
	local bg = CS.FindTrans(item, "Bg")
	local taskName = CS.FindTrans(bg, "TaskName")
	local barBg = CS.FindTrans(bg, "BarBg")
	local bar = CS.FindTrans(barBg, "Bar")
	local barText = CS.FindTrans(barBg, "BarText")
	local proText = CS.FindTrans(bg, "ProText")
	local rewardList = CS.FindTrans(bg, "RewardList")
	local bigBtn = CS.FindTrans(bg, "BigBtn")
	local smallBtn = CS.FindTrans(bg, "SmallBtn")

	local isColorBg = self.curIndex == 1 and pos == 1
	local res = isColorBg and "activity_40_cell1" or "activity_40_cell2"
	self:SetWndEasyImage(bg, res)
	CS.ShowObject(barBg, isColorBg)
	CS.ShowObject(bigBtn, isColorBg)
	CS.ShowObject(proText, not isColorBg)
	CS.ShowObject(smallBtn, not isColorBg)
	local info = data.goalData.schedules[1]
	local completionsInfo = data.goalData.completionsInfo
	if isColorBg then
		self:SetWndText(barText, info.schedule .. "/" .. info.goal)
		local imgCom = bar:GetComponent(typeof(UnityEngine.UI.Image))
		imgCom.fillAmount = info.schedule / info.goal
	end
	self:SetWndText(taskName, data.desc)
	if completionsInfo then
		if completionsInfo.goal ~= 0 then
			local time = completionsInfo.goal - completionsInfo.schedule + completionsInfo.finish
			self:SetWndText(proText, ccClientText(20875) .. time)
		else
			self:SetWndText(proText, "")
		end
	else
		self:SetWndText(proText, ccClientText(20875) .. info.goal - info.schedule)
	end

	local InstanceID = item:GetInstanceID()
	if data.goalData.status == 1 then
		self:CreateWndEffect(smallBtn, "fx_anniu_02", InstanceID .. "small", 100)
		self:CreateWndEffect(bigBtn, "fx_anniu_03", InstanceID .. "big", 100)
	else
		self:DestroyWndEffectByKey(InstanceID .. "small")
		self:DestroyWndEffectByKey(InstanceID .. "big")
	end
	self:SetWndButtonText(bigBtn, data.goalData.status ~= 2 and ccClientText(18214) or ccClientText(12214))
	self:SetWndButtonText(smallBtn, data.goalData.status ~= 2 and ccClientText(18214) or ccClientText(12214))
	self:SetWndButtonGray(bigBtn, data.goalData.status ~= 1)
	self:SetWndButtonGray(smallBtn, data.goalData.status ~= 1)

	if self.rewardIconUIList[InstanceID] then
		self.rewardIconUIList[InstanceID]:RefreshList(data.items)
	else
		self.rewardIconUIList[InstanceID] = self:GetUIScroll("rewardIconUIList" .. InstanceID)
		self.rewardIconUIList[InstanceID]:Create(rewardList, data.items, function(...) self:DrawRewardIcon(...) end,
			UIItemList.SUPER_GRID)
	end

	rewardList.sizeDelta = Vector2.New(#data.items * 82 + (#data.items - 1) * 8.5, 82)
	self.rewardIconUIList[InstanceID]:DrawAllItems()

	self:SetWndClick(bigBtn, function()
		if data.goalData.status == 1 then
			self.isUpdate = true
			gModelActivity:OnActivityReceiveGoalReq(self.sid, self.curIndex, data.entryId)
		end
	end)
	self:SetWndClick(smallBtn, function()
		if data.goalData.status == 1 then
			self.isUpdate = true
			gModelActivity:OnActivityReceiveGoalReq(self.sid, self.curIndex, data.entryId)
		end
	end)
end

function UISubInviteAct:ClickBox()
	if self.boxState == 1 then
		gModelActivity:OnActivityInvitationReq(3, self.sid)
	elseif self.boxState == 0 then
		GF.ShowMessage(ccClientText(20853))
	else
		GF.ShowMessage(ccClientText(20855))
	end
end

function UISubInviteAct:InitCommon()
	-----------------------------------------------
	--member
	self.tabData = {
		{
			tran = self.mTab1,
			func = function()
				CS.ShowObject(self.mShareObj, true)
				CS.ShowObject(self.mMyObj, false)
				self:ChangeTaskList(self.taskList[1] ~= nil and self.taskList[1].entry or {}, 1)
			end
		},
		{
			tran = self.mTab2,
			func = function()
				CS.ShowObject(self.mShareObj, false)
				CS.ShowObject(self.mMyObj, true)
				local list = (self.isBind and self.taskList[2] ~= nil) and self.taskList[2].entry or {}
				self:ChangeTaskList(list, 2)
			end
		},
	}

	-----------------------------------------------
	--Text
	self:SetWndTabText(self.mTab1, ccClientText(20870))
	self:SetWndTabText(self.mTab2, ccClientText(20871))
	self:SetWndText(self.mMyCodeText, ccClientText(20872))
	self:SetWndText(self.mShareMeText, ccClientText(20873))
	self:SetWndText(self.mEmptyText, ccLngText(GameTable.EmptyTipsRef[14006].text))
	self:SetWndText(CS.FindTrans(self.mInputCode, "TextArea/Placeholder"), ccClientText(20839))
	self:SetWndText(CS.FindTrans(self.mOkBtn, "Text"), ccClientText(12484))
	self:SetWndText(CS.FindTrans(self.mCopyBtn, "Text"), ccClientText(22105))
	self:SetWndText(CS.FindTrans(self.mOneShareBtn, "Text"), ccClientText(23404))
	self:SetWndButtonText(self.mImgBtn, ccClientText(20880))
	self:SetWndButtonText(self.mWorldBtn, ccClientText(20878))
	self:SetWndButtonText(self.mCrossSerBtn, ccClientText(20879))

	-----------------------------------------------
	--order
	self:SetWndTabStatus(self.mTab1, 1)
	self:SetWndTabStatus(self.mTab2, 1)

	local tran = CS.FindTrans(self.mBox, "Eff")
	local canvas = tran:GetComponent(typeof(UnityEngine.Canvas))
	canvas.sortingOrder = self:GetWndSortOrder() + 1
	local tran = CS.FindTrans(self.mBox, "On")
	local canvas = tran:GetComponent(typeof(UnityEngine.Canvas))
	canvas.sortingOrder = self:GetWndSortOrder() + 2
end

function UISubInviteAct:ClickShareBtn()
	self.copySelectShow = not self.copySelectShow
	CS.ShowObject(self.mCopySelect, self.copySelectShow)
end

function UISubInviteAct:ClickImgBtn()
	gLxTKData:OnTAClientEventReq(LxTKData.CLIENT_INVITE, "打开分享界面", "一键邀请")
	GF.OpenWnd("UIGameSpread", {
		sid = self.sid,
		shareTagText = self.uiCfg.shareTagText,
		shareTag = self.uiCfg.shareTag,
	})
end

function UISubInviteAct:UpdateRed()
	local red1 = CS.FindTrans(self.mTab1, "redPoint")
	local showRed = false
	if self.taskList[1] then
		for _, v in ipairs(self.taskList[1].entry) do
			if v.goalData and v.goalData.status == 1 then
				showRed = true
				break
			end
		end
	end
	CS.ShowObject(red1, showRed)

	local red2 = CS.FindTrans(self.mTab2, "redPoint")
	showRed = false
	if self.isBind then
		for _, v in ipairs(self.taskList[2].entry) do
			if v.goalData and v.goalData.status == 1 then
				showRed = true
				break
			end
		end
	else
		showRed = true
	end
	CS.ShowObject(red2, showRed)
end

function UISubInviteAct:InitActData(_, sid, pages)
	if sid ~= self.sid then
		return
	end
	if not self.taskList then
		self.taskList = {}
	end
	for _, v in ipairs(pages) do
		if v.data == "邀请福利" then
			self.taskList[1] = v
		elseif v.data == "萌新福利" then
			self.isFinishNew = true
			for _, v in ipairs(v.entry) do
				if v.goalData.status ~= 2 then
					self.isFinishNew = false
					break
				end
			end
			self.taskList[2] = v
		end
	end
	if self.curIndex then
		self:ClickTab(self.curIndex)
	end
end

function UISubInviteAct:ClickOkBtn()
	self.isUpdate = true
	gModelActivity:OnActivityInvitationReq(1, self.sid, self.mInputCode.text)
end

function UISubInviteAct:ClickLookBtn()
	if #self.invitationList == 0 then
		GF.ShowMessage(ccClientText(20876))
	else
		GF.OpenWnd("UIInviteActPYList", { self.invitationList })
	end
end

function UISubInviteAct:InitCfgData(_, sid)
	if sid ~= self.sid then return end

	local activityData = gModelActivity:GetActivityBySid(self.sid)
	if not activityData then return end
	local moreInfo = JSON.decode(activityData.moreInfo)
	self.invitationCode = moreInfo.invitationCode
	self:SetWndText(self.mCodeText, self.invitationCode)

	local isShare = moreInfo.isShare
	local isGet = moreInfo.onetimeReward
	local b = isShare == 1 and isGet == 0
	self:SetWndTabStatus(self.mBox, b and 0 or 1)
	if b then
		self:CreateWndEffect(CS.FindTrans(self.mBox, "Eff"), "ui_fx_mengjingxueyuan_01", "boxEff", 100)
		self.boxState = 1
	else
		self:DestroyWndEffectByKey("boxEff")
		if isShare == 1 then
			self.boxState = 2
		else
			self.boxState = 0
		end
	end

	local activityCfg = gModelActivity:GetWebActivityDataById(self.sid)
	if not activityCfg then return end
	self.uiCfg = activityCfg.config

	self.inviteCodeLv = self.uiCfg.InviteCodeLv
	self.inviteCodeTime = self.uiCfg.InviteCodeTime
	self:SetWndText(self.mOffNoText, string.replace(ccLngText(GameTable.EmptyTipsRef[14005].text), self.uiCfg.sysCode))
	self:SetWndText(self.mDesText, self.uiCfg.questDesc1)
	CS.ShowObject(self.mHelpBtn, self.uiCfg.helpTips == 1)
	if not string.isempty(self.uiCfg.helpTipsPosition) then
		self.mHelpBtn.localPosition = LxDataHelper.ParseVector(self.uiCfg.helpTipsPosition)
	end
	if not string.isempty(self.uiCfg.titleImage) then
		self:SetWndEasyImage(self.mBanner, self.uiCfg.titleImage)
	end


	gModelActivity:OnActivityInvitationReq(2, self.sid)
end

function UISubInviteAct:OnActivityInvitationResp(pb)
	self.isBind = pb.invitation.type ~= 0
	local regTime = gModelPlayer:GetRegTime()
	local regH = (GetTimestamp() - regTime) / 60 / 60
	local lvl = gModelPlayer:GetPlayerLv()
	local conditions1 = self.inviteCodeTime >= regH and self.inviteCodeLv >= lvl
	local conditions2 = not self.isFinishNew and self.isBind
	self.showTab = conditions1 or conditions2
	CS.ShowObject(self.mSelectTab, self.showTab)

	self:SetWndTabStatus(self.mMyObj, self.isBind and 0 or 1)
	self.invitationList = pb.invitation.invitations or {}
	self:SetWndText(self.mFriendText, ccClientText(20874) .. #self.invitationList)
	if self.isBind then
		if pb.invitation.type == 1 then
			local playerData = pb.invitation.beInvitation
			self:SetHeadIcon(self.mHeadIcon, playerData)
			self:SetWndText(self.mNameText, playerData.name)
			self:SetWndText(self.mServerText, string.replace(ccClientText(20834), playerData.serverName))
			self:SetWndText(CS.FindTrans(self.mPowerBg, "PowerText"), LUtil.NumberCoversion(playerData.power))
		end
		CS.ShowObject(CS.FindTrans(self.mMyObj, "On"), pb.invitation.type == 1)
		CS.ShowObject(CS.FindTrans(self.mMyObj, "ShareMeText"), pb.invitation.type == 1)
	end
	self:UpdateRed()
	if self.isFrist then
		self.isFrist = false
		self:ClickTab(self.showTab and 2 or 1)
	end
end

function UISubInviteAct:ChangeTaskList(data, index)
	local fList, mList, lList, list = {}, {}, {}, {}
	if index == 1 then
		table.insert(list, data[1])
	end
	for i = index == 1 and 2 or 1, #data do
		if data[i].goalData.status == 1 then
			table.insert(fList, data[i])
		end
	end
	for i = index == 1 and 2 or 1, #data do
		if data[i].goalData.status == 0 then
			table.insert(mList, data[i])
		end
	end
	for i = index == 1 and 2 or 1, #data do
		if data[i].goalData.status == 2 then
			table.insert(lList, data[i])
		end
	end
	for _, v in ipairs(fList) do
		table.insert(list, v)
	end
	for _, v in ipairs(mList) do
		table.insert(list, v)
	end
	for _, v in ipairs(lList) do
		table.insert(list, v)
	end

	local listTran = self.showTab and self.mTaskList2 or self.mTaskList
	CS.ShowObject(listTran, true)
	self.curIndex = index
	if not self.taskUIList then
		self.taskUIList = self:GetUIScroll("mTaskList")
		self.taskUIList:Create(listTran, list, function(...) self:DrawTask(...) end, UIItemList.SUPER)
	else
		self.taskUIList:ResetList(list)
		self.taskUIList:DrawAllItems()
	end
end

function UISubInviteAct:ClickCopyBtn()
	if LNativeHelper.CopyToClipboard(self.invitationCode) then
		if CS.IsOSAndroid() then
			LNativeHelper.ShowToast(self.invitationCode)
		else
			GF.ShowMessage(ccClientText(20846))
		end
	end
end

function UISubInviteAct:ClickTab(index)
	for i, v in ipairs(self.tabData) do
		self:SetWndTabStatus(v.tran, i == index and 0 or 1)
		if i == index and v.func then
			v.func()
		end
	end
end

function UISubInviteAct:DrawRewardIcon(_, item, data)
	local root = self:FindWndTrans(item, "Root")
	local instanceId = root:GetInstanceID()
	if not self.commonUIList[instanceId] then
		self.commonUIList[instanceId] = CommonIcon:New()
		self.commonUIList[instanceId]:Create(root)
	end
	self.commonUIList[instanceId]:SetCommonReward(data.type, data.itemId, data.count)
	self.commonUIList[instanceId]:DoApply()

	self:SetWndClick(root, function()
		gModelGeneral:ShowCommonItemTipWnd(data)
	end)
end

function UISubInviteAct:SetHeadIcon(trans, data)
	local playerInfo = {
		trans = trans,
		playerId = data.playerId,
		icon = data.head,
		headFrame = data.headFrame,
		level = data.grade,
	}
	if not self.uiHead then
		self.uiHead = HeadIcon:New(self)
	end
	self.uiHead:SetHeadData(playerInfo)
	self:SetWndClick(trans, function()
		gModelGeneral:PlayerShowReq(data.playerId, LCombatTypeConst.COMBAT_MAIN, LPlayerShowConst.OTHER_SYSTEM)
	end)
end

function UISubInviteAct:InitEvent()
	self:SetWndClick(self.mHelpBtn, function()
		GF.OpenWnd("UIBzTips", { title = self.uiCfg.name, text = self.uiCfg.helpTipsContent })
	end)
	self:SetWndClick(self.mBox, function()
		self:ClickBox()
	end)
	self:SetWndClick(self.mTab1, function()
		self:ClickTab(1)
	end)
	self:SetWndClick(self.mTab2, function()
		self:ClickTab(2)
	end)
	self:SetWndClick(self.mOkBtn, function()
		self:ClickOkBtn()
	end)
	self:SetWndClick(self.mCopyBtn, function()
		self:ClickCopyBtn()
	end)
	self:SetWndClick(self.mOneShareBtn, function()
		self:ClickShareBtn()
	end)
	self:SetWndClick(self.mLookBtn, function()
		self:ClickLookBtn()
	end)
	self:SetWndClick(self.mCopySelectMask, function()
		self:ClickShareBtn()
	end)
	self:SetWndClick(self.mImgBtn, function()
		self:ClickImgBtn()
	end)
	self:SetWndClick(self.mWorldBtn, function()
		local data =
		{
			self.invitationCode,
			ccClientText(20881)
		}
		gModelChat:OnChatShareReq(3, 43, JSON.encode(data))
	end)
	self:SetWndClick(self.mCrossSerBtn, function()
		local data =
		{
			self.invitationCode,
			ccClientText(20881)
		}
		gModelChat:OnChatShareReq(2, 43, JSON.encode(data))
	end)

	self:WndEventRecv(EventNames.ON_ACTIVITY_PAGE_CHANGE, function(_, sid, pages)
		self:InitActData(_, sid, pages)
		gModelActivity:ReqActivityConfigData(self.sid)
	end)
	self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA, function(_, sid)
		self:InitCfgData(_, sid)
	end)
	self:WndNetMsgRecv(LProtoIds.ActivityInvitationResp, function(pb)
		if self.isUpdate then
			self:OnActivityInvitationResp(pb)
			gModelActivity:OnActivityPageReq(self.sid)
			self.isUpdate = false
		else
			self:OnActivityInvitationResp(pb)
		end

		if pb.sid == self.sid then
			if pb.opera == 3 or pb.opera == 4 then
				gModelActivity:OnActivityPageReq(self.sid)
			end
		end
	end)
end

------------------------------------------------------------------
return UISubInviteAct


