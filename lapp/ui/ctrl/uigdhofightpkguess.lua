---
--- Created by Administrator.
--- DateTime: 2024/10/21 10:25:14
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIGdHoFightPkGuess:LWnd
local UIGdHoFightPkGuess = LxWndClass("UIGdHoFightPkGuess", LWnd)
local stageText = {
	[ModelGuildHolyPeak.STAGE_3] = ccClientText(46034),
    [ModelGuildHolyPeak.STAGE_4] = ccClientText(46035),
    [ModelGuildHolyPeak.STAGE_5] = ccClientText(46034),
    [ModelGuildHolyPeak.STAGE_6] = ccClientText(46035),
    [ModelGuildHolyPeak.STAGE_7] = ccClientText(46034),
    [ModelGuildHolyPeak.STAGE_8] = ccClientText(46035),
    [ModelGuildHolyPeak.STAGE_9] = ccClientText(46034),
    [ModelGuildHolyPeak.STAGE_10] = ccClientText(46035),
    [ModelGuildHolyPeak.STAGE_11] = ccClientText(46036),
    [ModelGuildHolyPeak.STAGE_12] = ccClientText(46036)
}
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIGdHoFightPkGuess:UIGdHoFightPkGuess()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIGdHoFightPkGuess:OnWndClose()
	if self.timer then
		LxTimer.DelayTimeStop(self.timer)
		self.timer = nil
	end
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIGdHoFightPkGuess:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIGdHoFightPkGuess:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()
	self:InitEnjList()
	self:UpdateGuessList()
	self:UpdateHaveObj()
	self:TimerStart("leftTimeRun", 1, false)

	local pb = self:GetWndArg("pb")
	if pb then
		self:UpdateGuessInfo(pb)
	else
		gModelGuildHolyPeak:GuildPinnacleQuizInfoReq()
	end
	gModelGuildHolyPeak:OpenPeak()
end

function UIGdHoFightPkGuess:UpdateTime()
	local stage = gModelGuildHolyPeak:GetStage()
	if stage > ModelGuildHolyPeak.STAGE_10 then
		self:SetWndText(self.mTimeText, stageText[stage])
		self:TimerStop("leftTimeRun")
		return
	end
	local endTime = tonumber(gModelGuildHolyPeak:GetStageEndTime()) / 1000
	local cur = GetTimestamp()
	local leftTime = math.floor(endTime - cur)
	leftTime = math.max(leftTime, 0)
	local timeS = LUtil.FormatTimespanToMin2New(leftTime)
	self:SetWndText(self.mTimeText, string.replace(stageText[stage], timeS))
	if leftTime <= 0 then
		if stage == 3 or stage == 5 or stage == 7 or stage == 9 then
			self:SetWndText(self.mTimeText, ccClientText(46063))
		end
		self:TimerStop("leftTimeRun")
	end
end

function UIGdHoFightPkGuess:DrawItem(item, data)
	if not data then return end
	local text = self:FindWndTrans(item, "DescTxt")
	local id = tonumber(data.atPlayerId)
	local s = ""
	if id and id ~= 0 then
		s = ccLngText(gModelChat:GetMailNoticesRefByRefId(id).content)
		if id == 105 then
			local s1, s2, s3 = "", "", ""
			local info = JSON.decode(data.msg)
			if info then
				s1 = gLGameLogin:GetServerShotNameById(tonumber(info.a1))
				s2 = info.a2
				s3 = info.a3
				s = string.replace(s, s1, s2, s3)
			end
		end
	else
		data.msg = LUtil.ChatInfoFaceBinToDec(data.msg)
		s = data.playerName .. "：" .. LUtil.GetFaceStr(data.msg, 25)
	end
	self:SetWndText(text, s)
end

function UIGdHoFightPkGuess:OnTimer(key)
	if key == "leftTimeRun" then
		self:UpdateTime()
	end
end

function UIGdHoFightPkGuess:UpdateHaveObj()
	local num = CS.FindTrans(self.mHaveObj, "Num")
	local haveNum = gModelItem:GetNumByRefId(112002)
	self:SetWndText(num, LUtil.NumberCoversion(haveNum))
	UnityEngine.UI.LayoutRebuilder.ForceRebuildLayoutImmediate(self.mHaveObj)
end

function UIGdHoFightPkGuess:ClickSendBtn()
	local msg = self.mChatInput.text
	local bool = gModelChat:GetIfSend(30, msg)
	if not bool then
		return
	else
		local info = gModelChat:GetChatRestrict(msg)
		if info.bool then
			self:SetWndTextInput(self.mChatInput, info.str)
			CS.ShowObject(self.mChatInput, false)
			CS.ShowObject(self.mChatInput, true)
			return
		end
	end
	gModelChat:OnChatMsgReq(30, ModelChat.MSGTYPE_NORMAL, msg)
    self:SetWndTextInput(self.mChatInput, "")
end

function UIGdHoFightPkGuess:SetGuildData(trans, data)
	local flag = CS.FindTrans(trans, "Flag")
	local icon = CS.FindTrans(trans, "Icon")
	local lvlText = CS.FindTrans(trans, "LvlText")
	local name = CS.FindTrans(trans, "Name")
	local num = CS.FindTrans(trans, "Num")
	local powerText = CS.FindTrans(trans, "PowerText")
	local roleList = CS.FindTrans(trans, "RoleList")
	local supportText = CS.FindTrans(trans, "SupportText")
	local isSupport = CS.FindTrans(trans, "IsSupport")
	local supportBtn = CS.FindTrans(trans, "SupportBtn")

	local guildData = gModelGuildHolyPeak:GetGuildInfoById(data.guildId)
	local flagRes = gModelGuild:GetGuildFlagRefByRefId(guildData.flagBgId).res
	local iconRes = gModelGuild:GetGuildFlagRefByRefId(guildData.flagId).res
	self:SetWndEasyImage(flag, flagRes)
	self:SetWndEasyImage(icon, iconRes)
	self:SetWndText(lvlText, guildData.level .. ccClientText(46014))
	self:SetWndText(name, guildData.guildName)

	local memberData = {}
	for _, v in ipairs(data.member) do
		if v.playerId ~= "0" then
			local t = {
				playerId = v.playerId,
				avatar = v.avatar,
				avatarFrame = v.avatarFrame,
				lvl = v.lvl
			}
			table.insert(memberData, t)
		end
	end
	self:SetWndText(num, #memberData)
	self:SetWndText(powerText, LUtil.NumberCoversion(guildData.guildPower))

	local key = trans.gameObject.name
	if self.roleList[key] then
		self.roleList[key]:RefreshList(memberData)
		self.roleList[key]:DrawAllItems()
	else
		self.roleList[key] = self:GetUIScroll("roleList" .. key)
		self.roleList[key]:Create(roleList, memberData, function(...) self:DrawRole(...) end, UIItemList.SUPER_GRID)
	end

	local str = ccClientText(46015)
	local support = self.allNum <= 0 and 0 or data.support / self.allNum
	local color1 = support < 0.5 and "#c81212" or "#139057"
	local color2 = data.odds > 1 and "#139057" or "#c81212"
	support = string.format("%.2f", support)
	self:SetWndText(supportText, string.replace(str, color1, support * 100, color2, string.format("%.2f", data.odds)))
	self:SetWndButtonText(supportBtn, ccClientText(46038))
	self:SetWndText(isSupport, ccClientText(46016) .. " " .. self.guessNum)
	if gLGameLanguage:IsJapanVersion() then
		self:InitTextSizeWithLanguage(supportText,-4)
	end
	CS.ShowObject(isSupport, self.guessGuildId == data.guildId)
	CS.ShowObject(supportBtn, self.guessGuildId == 0)
	self:SetWndClick(supportBtn, function()
		local stage = gModelGuildHolyPeak:GetStage()
		if stage == 3 or stage == 5 or stage == 7 or stage == 9 then
			GF.OpenWnd("UIGdHoFightPkGuessBet", { guildId = data.guildId })
		else
			GF.ShowMessage(ccClientText(46039))
		end
	end)
	self:SetWndClick(flag, function()
		if data then
			gModelGuild:OnGuildMemberListReq(guildData.guildId, guildData.serverId)
		end
	end)
	self:SetWndClick(icon, function()
		if data then
			gModelGuild:OnGuildMemberListReq(guildData.guildId, guildData.serverId)
		end
	end)
end

function UIGdHoFightPkGuess:ClickEnjBtn()
	self.showEnj = not self.showEnj
	CS.ShowObject(self.mEnjObj, self.showEnj)
	local res = self.showEnj and "chat_btn_jian" or "chat_btn_jia"
	self:SetWndEasyImage(self.mEnjBtn, res)
end

function UIGdHoFightPkGuess:UpdateGuessInfo(pb)
	local data = {
		{
			guildId = pb.guildA,
			member = pb.memberA,
			odds = pb.oddsA,
			support = pb.supportA
		},
		{
			guildId = pb.guildB,
			member = pb.memberB,
			odds = pb.oddsB,
			support = pb.supportB
		},
	}
	self.allNum = pb.supportA + pb.supportB
	self.guessGuildId = pb.quizGuildId
	self.guessNum = pb.quizItem
	self.id = pb.id

	local support = self.allNum <= 0 and 0.5 or pb.supportA / self.allNum
	LxUiHelper.SetProgress(self.mBar, support)

	local stage = tonumber(string.split(pb.id, "_")[1])
	self:SetWndText(self.mStateText, gModelGuildHolyPeak:GetGuessStageText(stage))

	self:SetGuildData(self.mGuild1, data[1])
	self:SetGuildData(self.mGuild2, data[2])
end

function UIGdHoFightPkGuess:InitEnjList()
	local DrawEnj = function(_, item, data)
		local img = CS.FindTrans(item, "Image")
		self:SetWndEasyImage(img, data.faceIcon)
		self:SetWndClick(img, function()
			self:SetWndTextInput(self.mChatInput, self.mChatInput.text .. data.faceinstead)
		end)
	end

	local list = gModelChat:GetEmojiByType(1)
	local enjList = self:GetUIScroll("enjList")
	enjList:Create(self.mEnjList, list, function(...) DrawEnj(...) end, UIItemList.SUPER_GRID)
end

function UIGdHoFightPkGuess:DrawRole(_, trans, data)
	local headIcon = CS.FindTrans(trans, "HeadIcon")
	local instanceId = trans:GetInstanceID()
	local playerInfo = {
		trans = headIcon,
		playerId = data.playerId,
		icon = data.avatar,
		headFrame = data.avatarFrame,
		level = data.lvl,
	}
	local headIconCls = self:GetHeadIcon(instanceId)
	headIconCls:SetHeadData(playerInfo)

	self:SetWndClick(trans, function()
		gModelGeneral:PlayerShowReq(
			data.playerId,
			LCombatTypeConst.COMBAT_MAIN,
			LPlayerShowConst.OTHER_SYSTEM
		)
	end)
end

function UIGdHoFightPkGuess:InitCommon()
	------------------------------------------------------------------
	---click
	self:SetWndClick(self.mMask, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mBtnClose, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mEnjBtn, function()
		self:ClickEnjBtn()
	end)
	self:SetWndClick(self.mEnjClose, function()
		self:ClickEnjBtn()
	end)
	self:SetWndClick(self.mSendBtn, function()
		self:ClickSendBtn()
	end)
	self:SetWndClick(self.mGuessListBtn, function()
		GF.OpenWnd("UIGdHoFightPkGuessList")
	end)

	------------------------------------------------------------------
	---text
	self:SetWndText(self.mLblBiaoti, ccClientText(46021))
	self:SetWndText(CS.FindTrans(self.mChatInput, "TextArea/Placeholder"), ccClientText(11133))
	self:SetWndText(CS.FindTrans(self.mHaveObj, "Text"), ccClientText(46037))
	self:SetWndButtonText(self.mSendBtn, ccClientText(12433))
	self:SetTextTile(self.mGuessListBtn, ccClientText(11823))

	------------------------------------------------------------------
	---resp
	self:WndNetMsgRecv(LProtoIds.GuildPinnacleQuizInfoResp, function(pb)
		self:UpdateGuessInfo(pb)
	end)
	self:WndNetMsgRecv(LProtoIds.ChatMsgPushResp, function(pb)
        self:UpdateGuessList(pb)
    end)

	------------------------------------------------------------------
	---event
	self:WndEventRecv("GuildPinnacleStageResp", function()
		self:TimerStop("leftTimeRun")
		self:TimerStart("leftTimeRun", 1, false)
		self:UpdateTime()
	end)
	self:WndEventRecv(EventNames.On_Item_Change, function()
		self:UpdateHaveObj()
	end)
	self:WndEventRecv("GuildPinnacleFightResultResp", function(data)
		if data.id == self.id then
			if gLGameUI:FindWndByName("UIGdHoFightPkFight") then
				GF.CloseWndByName("UIGdHoFightPkFight")
			end
			GF.OpenWnd("UIGdHoFightPkFight", { id = self.id })
		end
	end)

	------------------------------------------------------------------
	---ui
	local res = gModelItem:GetItemImgByRefId(112002)
	self:SetWndEasyImage(CS.FindTrans(self.mHaveObj, "Icon"), res)

	------------------------------------------------------------------
	---member
	self.roleList = {}
end

function UIGdHoFightPkGuess:UpdateGuessList(pb)
	if not self.notFirst then
		self.notFirst = true
		local list = gModelChat:GetTypeInfo(30)
		local start = math.max(1, #list - 50 + 1)
		for i = start, #list do
			local item = CS.FindTrans(self.mItemPool, "ItemTemplate")
			self:DrawItem(item, list[i])
			LxUnity.SetParentTrans(item, self.mItemRoot)
		end
	else
		if not pb then return end
		for _, v in ipairs(pb.msgs) do
			if v.channel == 30 then
				local item = CS.FindTrans(self.mItemPool, "ItemTemplate")
				if item == nil then
					item = CS.FindTrans(self.mItemRoot, "ItemTemplate")
					LxUnity.SetParentTrans(item, self.mItemPool)
				end
				self:DrawItem(item, v)
				LxUnity.SetParentTrans(item, self.mItemRoot)
			end
		end
	end
	self.timer = LxTimer.DelayTimeCall(function()
		if self.mItemRoot and self.mItemRoot.rect.height > 217.93 then
			if not self.seqCom then
				self.seqCom = self:GetSeqCom()
			end
			self.seqCom:DeleteSeq("delayFreeze")
			local seq = self.seqCom:CreateSeq("delayFreeze")
			local y = self.mItemRoot.rect.height - 217.93
			local pos = Vector2.New(0, y)
			local downTweener = self.mItemRoot:DOLocalMove(pos, 0.3):SetEase(DG.Tweening.Ease.Linear)
			seq:Insert(0, downTweener)
			seq:PlayForward()
			self.timer = nil
		end
	end, 0.3)
end



------------------------------------------------------------------
return UIGdHoFightPkGuess