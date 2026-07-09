---
--- Created by Administrator.
--- DateTime: 2024/10/21 17:49:49
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubGdHoFightPkReport:LChildWnd
local UISubGdHoFightPkReport = LxWndClass("UISubGdHoFightPkReport", LChildWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubGdHoFightPkReport:UISubGdHoFightPkReport()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubGdHoFightPkReport:OnWndClose()
	LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubGdHoFightPkReport:OnCreate()
	LChildWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubGdHoFightPkReport:OnStart()
	LChildWnd.OnStart(self)
	self:InitUI()
	self:InitCommon()

	gModelGuildHolyPeak:GuildPinnacleBattlefieldReq(self.id, 2)
end

function UISubGdHoFightPkReport:UpdateList(list)
	self.guildA = list[1].guildA
	self.guildB = list[1].guildB
	if self.pos then
		self.showMoreItem[self.pos] = true
	end
	if self.uiList then
		self.uiList:ResetList(list)
		self.uiList:DrawAllItems()
	else
		self.uiList = self:GetUIScroll("List")
		self.uiList:Create(self.mList, list, function(...) self:DrawList(...) end, UIItemList.SUPER)
	end
	if self.pos then
		self.uiList:MoveToPos(self.pos)
		self.pos = nil
	end
end

function UISubGdHoFightPkReport:SetPlayer(trans, data, isWin)
	local headIcon = CS.FindTrans(trans, "HeadIcon")
	local name = CS.FindTrans(trans, "Name")
	local powerText = CS.FindTrans(trans, "PowerBg/PowerText")
	local win = CS.FindTrans(trans, "Win")
	local lose = CS.FindTrans(trans, "Lose")

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

	self:SetWndText(name, data.playerName)
	self:SetWndText(powerText, LUtil.NumberCoversion(data.playerPower))
	CS.ShowObject(win, isWin)
	CS.ShowObject(lose, not isWin)
end

function UISubGdHoFightPkReport:HandlePlayerData(data)
	for _, v in ipairs(data) do
		local t = {
			playerId = v.playerId,
			playerName = v.playerName,
			playerPower = v.playerPower,
			avatar = v.avatar,
			avatarFrame = v.avatarFrame,
			lvl = v.lvl,
		}
		self.playerData[v.playerId] = t
	end
end

function UISubGdHoFightPkReport:SetData(pb)
	self:HandlePlayerData(pb.membersA)
	self:HandlePlayerData(pb.membersB)
	self:UpdateList(pb.reportInfo)
	self:SetGuildInfo(self.mGuild1, self.guildA)
	self:SetGuildInfo(self.mGuild2, self.guildB)
end

function UISubGdHoFightPkReport:SetDraconicSkill(trans, dicList, isLeft)
	local DraconicSuitRankRef = GameTable.DraconicSuitRankRef
	local DraconicRef = GameTable.DraconicRef
	if isLeft then
		local t = dicList
		dicList = {}
		dicList[1] = t[4]
		dicList[2] = t[3]
		dicList[3] = t[2]
		dicList[4] = t[1]
	end
	for i = 1, 4 do
		local data = { ref = nil, upRef = nil }
		if dicList[i] and dicList[i] > 0 then
			local upRef = DraconicSuitRankRef[dicList[i]]
			local ref = DraconicRef[upRef.type]
			data = { ref = ref, upRef = upRef }
		end

		local root = self:FindWndTrans(trans, "Root" .. i)
		self:SetDicIcon(root, data)
	end
end

function UISubGdHoFightPkReport:GetPlayerDataById(id)
	return self.playerData[id] or {}
end

function UISubGdHoFightPkReport:SetDicIcon(root, data)
	local icon = self:FindWndTrans(root, "DraconicSkill")
	CS.ShowObject(icon, data.ref ~= nil)
	if data.ref then
		local param = {
			showName = true,
			showType = true,
			showStar = true,
			upRefId = data.upRef.refId,
		}
		gModelDraconic:DrawSkillItem(self, icon, param)
	end
	self:SetWndClick(icon, function()
		if data.ref then
			GF.OpenWnd("UIDraconicUpStar", { refId = data.ref.refId, starNum = data.upRef.rankNow, tips = true })
		end
	end)
end

function UISubGdHoFightPkReport:SetHero(trans, data, playerId)
	local heros = {}
	for k, v in ipairs(data.heros) do
		local grid = data.grids[k]
		heros[grid] = v
	end
	for i = 1, 10 do
		local root = CS.FindTrans(trans, "Root" .. i)
		local nullImg = CS.FindTrans(root, "NullImg")
		if heros[i] then
			self:SetHeroIcon(root, heros[i], playerId)
		end
		CS.ShowObject(nullImg, heros[i] == nil)
	end
end

function UISubGdHoFightPkReport:SetGuildInfo(trans, id)
	local flag = CS.FindTrans(trans, "Flag")
	local icon = CS.FindTrans(trans, "Icon")
	local lvl = CS.FindTrans(trans, "Text")
	local server = CS.FindTrans(trans, "Server")
	local name = CS.FindTrans(trans, "Name")

	local data = gModelGuildHolyPeak:GetGuildInfoById(id)
	local flagRes = gModelGuild:GetGuildFlagRefByRefId(data.flagBgId).res
	local iconRes = gModelGuild:GetGuildFlagRefByRefId(data.flagId).res
	self:SetWndEasyImage(flag, flagRes)
	self:SetWndEasyImage(icon, iconRes)
	self:SetWndText(name, data.guildName)
	self:SetWndText(lvl, data.level .. ccClientText(46014))
	self:SetWndText(server, "[" .. gLGameLogin:GetServerShotNameById(data.serverId) .. "]")
end

function UISubGdHoFightPkReport:SetHeroIcon(item, hero, playerId)
	local heroData = {
		id = hero.id,
		refId = hero.refId,
		star = hero.star,
		level = hero.level,
		skin = hero.skin,
		isResonance = hero.isResonance,
		grade = hero.grade,
		fightPower = hero.fightPower,
	}

	local root = self:FindWndTrans(item, "Root")
	local instanceId = item:GetInstanceID()
	local heroIcon = self:GetCommonIcon(instanceId)
	heroIcon:Create(root)
	heroIcon:SetHeroDataSet(heroData)
	heroIcon:DoApply()

	self:SetWndClick(item, function()
		local data = {
			id = hero.id,
			refId = hero.refId,
			level = hero.level,
			star = hero.star,
			grade = hero.grade,
			fightPower = hero.fightPower,
			isResonance = hero.isResonance,
			skin = hero.skin,
		}
		gModelHero:ReqShowHeroTip(playerId, data, nil, nil, nil, self.serverId)
	end)
end

function UISubGdHoFightPkReport:DrawList(_, trans, data, pos)
	local on = CS.FindTrans(trans, "On")
	local off = CS.FindTrans(trans, "Off")
	local onArrow = CS.FindTrans(on, "Arrow")
	local offArrow = CS.FindTrans(off, "Arrow")
	local draconicSkill1 = CS.FindTrans(off, "DraconicSkill1")
	local draconicSkill2 = CS.FindTrans(off, "DraconicSkill2")
	local hero1 = CS.FindTrans(off, "Hero1")
	local hero2 = CS.FindTrans(off, "Hero2")
	local reportBtn = CS.FindTrans(off, "ReportBtn")
	local player1 = CS.FindTrans(trans, "Player1")
	local player2 = CS.FindTrans(trans, "Player2")
	local title = CS.FindTrans(trans, "Title")

	self:SetDraconicSkill(draconicSkill1, data.formationA.draconicStarRefIds, true)
	self:SetDraconicSkill(draconicSkill2, data.formationB.draconicStarRefIds, false)
	self:SetHero(hero1, data.formationA, data.memberA)
	self:SetHero(hero2, data.formationB, data.memberB)
	self:SetPlayer(player1, self:GetPlayerDataById(data.memberA), data.winner == data.memberA)
	self:SetPlayer(player2, self:GetPlayerDataById(data.memberB), data.winner == data.memberB)
	self:SetWndText(title, ccClientText(46026))

	CS.ShowObject(off, self.showMoreItem[pos])
	local h = self.showMoreItem[pos] and 490 or 150
	trans.sizeDelta = Vector2.New(630, h)

	self:SetWndClick(onArrow, function()
		self.showMoreItem[pos] = true
		self.uiList:DrawAllItems()
		self.uiList:MoveToPos(pos)
	end)
	self:SetWndClick(offArrow, function()
		self.showMoreItem[pos] = false
		self.uiList:DrawAllItems()
	end)
	self:SetWndClick(reportBtn, function()
		if data.reportId then
			local id = self.id
			local mapRes = gModelBattle:GetBattleMapRes({ combatType = LCombatTypeConst.COMBAT_TYPE_46 })
			local combatExtraDatas =
			{
				battleEndfun = function()
					FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.CITY })
					GF.ChangeMap("LCityMap")
					GF.OpenWnd("UIGdWin")
					GF.OpenWnd("UIGdHoFightPk")
					GF.OpenWnd("UIGdHoFightPkSchedule")
					GF.OpenWnd("UIGdHoFightPkFight", { id = id, index = 2, pos = pos })
				end,
				canSkip = true,
				battleMapName = mapRes,
				videoType = LVideoTypeConst.NORMAL,
				serverId = data.serverId
			}
			gLFightManager:OnPlayBattleVideo(data.reportId, combatExtraDatas)
		end
	end)
end

function UISubGdHoFightPkReport:InitCommon()
	------------------------------------------------------------------
	---member
	self.showMoreItem = {}
	self.playerData = {}
	self.id = self:GetWndArg("id")
	self.pos = self:GetWndArg("pos")

	------------------------------------------------------------------
	---resp
	self:WndNetMsgRecv(LProtoIds.GuildPinnacleBattlefieldResp, function(pb)
		self:SetData(pb)
	end)
end



------------------------------------------------------------------
return UISubGdHoFightPkReport