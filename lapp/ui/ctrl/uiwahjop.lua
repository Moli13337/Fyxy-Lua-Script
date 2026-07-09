---
--- Created by BY.
--- DateTime: 2023/10/1 21:10:15
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIWahjop:LWnd
local UIWahjop = LxWndClass("UIWahjop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIWahjop:UIWahjop()
	self._commonIconList = {}
	self._uiheadList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIWahjop:OnWndClose()
	self:ClearCommonIconList(self._commonIconList)
	self:ClearCommonIconList(self._uiheadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIWahjop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIWahjop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end

function UIWahjop:ReturnGuild(wndPara)
	GF.CloseWndByName("UIFight")
	GF.ChangeMap("LCityMap")
	GF.OpenWndBottom("UIGdWar2Win",wndPara)
end

function UIWahjop:OnSetPlayerABInfo(trans,info)
	local resultIcon = CS.FindTrans(trans,"ResultIcon")
	local resultText = CS.FindTrans(trans,"ResultText")
	local guildText = CS.FindTrans(trans,"GuildText")
	local nameText = CS.FindTrans(trans,"NameText")
	local serverText = CS.FindTrans(trans,"ServerText")
	local headIcon = CS.FindTrans(trans,"HeadIcon")
	local powerText = CS.FindTrans(trans,"PowerBg/PowerText")
	local bar_1 = CS.FindTrans(trans,"Bar_1")
	local buff = CS.FindTrans(trans,"Buff")
	local buffText = CS.FindTrans(trans,"Buff/BuffText")
	local buffLvText = CS.FindTrans(trans,"Buff/BuffLvText")

	local bar_1 = self:FindWndSlider(bar_1)
	bar_1.maxValue = info.maxHp
	bar_1.value = info.hp

	local guildBuff = info.guildMeleeBuffList[1]
	CS.ShowObject(buff,guildBuff)
	if guildBuff then
		local ref = gModelGuildMelee:GetGuildBattleBuffRefByRefId(guildBuff)
		self:SetWndText(buffText,ccLngText(ref.name))
		self:SetWndText(buffLvText,ref.lv)
		self:SetWndClick(buff,function ()
			--GF.OpenWnd("UINewJNTip",{curSkillId = ref.addAttrSkill,wndType = 2})
			--GF.OpenWndTop("UIJNInfo",{skillId = ref.addAttrSkill})
			gModelGeneral:OpenSkillWnd({curSkillId = ref.addAttrSkill,wndType = 2})
		end)
	end

	CS.ShowObject(resultIcon,info.win)
	CS.ShowObject(resultText,false)
	self:SetWndText(guildText,info.guildName)
	self:SetWndText(nameText,info.name)
	self:SetWndText(serverText,gModelFriend:GetSevenName(info.serverId))
	self:SetWndText(powerText,LUtil.NumberCoversion(info.power))

	if(info.win and info.winCount > 1)then
		CS.ShowObject(resultIcon,false)
		CS.ShowObject(resultText,true)
		local winCount = LUtil.FormatHurtNumSpriteText(info.winCount)
		self:SetWndText(resultText,winCount)
	end

	local InstanceID = trans:GetInstanceID()
	local uiheadlist = self._uiheadList
	local baseClass = uiheadlist[InstanceID]
	if not baseClass then
		baseClass = HeadIcon:New(self)
		uiheadlist[InstanceID] = baseClass
	end
	info.trans = headIcon
	baseClass:SetHeadData(info)
	self:SetWndClick(headIcon, function (...)
		self:OnClickPlayer(info.playerId)
	end)
end

function UIWahjop:OnPlayEnd()
	GF.CloseWndByName("UIFight")
	GF.ChangeMap("LCityMap")
	local channel = LPlayerPrefs.gameChatChannel
	gModelChat:OnClickOpenChat({channel = tonumber(channel)})
end

function UIWahjop:InitMessage()
end

function UIWahjop:InitCommand()
	local _combatData = self:GetWndArg("combatData")--StructGuildMeleeReportInfo	结构
	self._wndType = self:GetWndArg("wndType")
	self._returnWndPara = self:GetWndArg("wndPara")

	self:SetWndText(self.mLblBiaoti,ccClientText(17924))
	self:SetWndText(self.mLookText,ccClientText(17931))
	self:SetWndText(self.mShareText,ccClientText(17979))

	self._combatData = _combatData
	local time = LUtil.FormatTimeStr(_combatData.time,"%H:%M")
	self:SetWndText(self.mTimeText,time)

	local infoA,infoB = self:SetABInfo(_combatData)
	self:OnSetPlayerABInfo(self.mPlayerA,infoA)
	self:OnSetPlayerABInfo(self.mPlayerB,infoB)

	self:InitTeamNodeInfo(self.mPlayerTeam1,infoA,1)
	self:InitTeamNodeInfo(self.mPlayerTeam2,infoB)

	local showShare = self._wndType == 2 -- _combatData.isShare
	CS.ShowObject(self.mShareBtn,showShare)
end

function UIWahjop:InitTeamNodeInfo(trans,info,pos)
	local integralText = CS.FindTrans(trans,"IntegralBg/IntegralText")
	local skillScroll = CS.FindTrans(trans,"SkillScroll")
	local scroll = CS.FindTrans(trans,"HeroScroll")

	local integralStr = ""
	if info.addIntegral and info.addIntegral > 0 then
		integralStr = string.replace(ccClientText(17962),info.integral,"+"..info.addIntegral)
	else
		integralStr = string.replace(ccClientText(17962),info.integral,ccClientText(17963))
	end
	self:SetWndText(integralText,integralStr)

	local list = info.heroList
	for i, v in ipairs(list) do
		v.playerId = info.playerId
		v.serverId = info.serverId
	end
	local InstanceID = trans:GetInstanceID()
	-- local heroList = self:GetUIScroll("heroList"..InstanceID)
	for i = 1, #list do
		self:HeroListItem(_, CS.FindTrans(scroll, "Root" .. i), list[i])
	end
	-- if(heroList:GetList())then
	-- 	heroList:RefreshList(list)
	-- else
	-- 	heroList:Create(scroll,list,function (...) self:HeroListItem(...) end)
	-- end

	local draconicRefIdList = info.draconicList
	list = {}
	if pos == 1 then
		for i = #draconicRefIdList, 1, -1 do
			if draconicRefIdList[i] then
				table.insert(list, draconicRefIdList[i])
			end
		end
	else
		list = draconicRefIdList
	end
	local list2 = {
		{ ref = nil, upRef = nil },
		{ ref = nil, upRef = nil },
		{ ref = nil, upRef = nil },
		{ ref = nil, upRef = nil }
	}
	local DraconicSuitRankRef = GameTable.DraconicSuitRankRef
    local DraconicRef = GameTable.DraconicRef
	for i = 1, #list2 do
		if list[i] and list[i] > 0 then
			local upRef = DraconicSuitRankRef[list[i]]
			local ref = DraconicRef[upRef.type]
			list2[i] = {ref = ref, upRef = upRef}
		end
	end

	local draconicList = self:GetUIScroll("skillList"..InstanceID)
	if(draconicList:GetList())then
		draconicList:RefreshList(list2)
	else
		draconicList:Create(skillScroll,list2,function (...) self:DraconicListItem(...) end)
	end
end

function UIWahjop:SetABInfo(itemdata)
	local maxHpA,hpA = 0,0
	local combatHeroDataA = itemdata.combatHeroDataA
	local _herosA = combatHeroDataA._heros
	local _gridsA = combatHeroDataA._grids
	local _heroAKeylist = {}
	for i, v in pairs(_herosA) do
		maxHpA = maxHpA + v.maxHp
		hpA = hpA + v.hp
		if _gridsA[i] then
			_heroAKeylist[_gridsA[i]] = v
		end
	end
	local heroListA = {}
	for i = 1, 10 do
		if _heroAKeylist[i] then
			table.insert(heroListA,_heroAKeylist[i])
		else
			table.insert(heroListA,{})
		end
	end

	local maxHpB,hpB = 0,0
	local combatHeroDataB = itemdata.combatHeroDataB
	local _herosB = combatHeroDataB._heros
	local _gridsB = combatHeroDataB._grids
	local _heroBKeylist = {}
	for i, v in pairs(_herosB) do
		maxHpB = maxHpB + v.maxHp
		hpB = hpB + v.hp
		if _gridsB[i] then
			_heroBKeylist[_gridsB[i]] = v
		end
	end
	local heroListB = {}
	for i = 1, 10 do
		if _heroBKeylist[i] then
			table.insert(heroListB,_heroBKeylist[i])
		else
			table.insert(heroListB,{})
		end
	end
	local infoA = {
		winCount = itemdata.winCount,
		serverId = itemdata.serverIdA,
		playerId = itemdata.playerIdA,
		name = itemdata.playerNameA,
		icon = itemdata.headA,
		headFrame = itemdata.headFrameA,
		level = itemdata.playerLevelA,
		win = itemdata.win == 1,
		guildId = itemdata.guildIdA,
		guildName = itemdata.guildNameA,
		power = itemdata.powerA,
		maxHp = maxHpA,
		hp = hpA,
		heroList = heroListA,
		addIntegral = itemdata.addIntegralA,
		integral = itemdata.integralA,
		-- skillInfo = combatHeroDataA._skillInfo,
		guildMeleeBuffList = itemdata.guildMeleeBuffListA,
		draconicList = combatHeroDataA._draconicList
	}
	local infoB = {
		winCount = itemdata.winCount,
		serverId = itemdata.serverIdB,
		playerId = itemdata.playerIdB,
		name = itemdata.playerNameB,
		icon = itemdata.headB,
		headFrame = itemdata.headFrameB,
		level = itemdata.playerLevelB,
		win = itemdata.win == 2,
		guildId = itemdata.guildIdB,
		guildName = itemdata.guildNameB,
		power = itemdata.powerB,
		maxHp = maxHpB,
		hp = hpB,
		heroList = heroListB,
		addIntegral = itemdata.addIntegralB,
		integral = itemdata.integralB,
		-- skillInfo = combatHeroDataB._skillInfo,
		guildMeleeBuffList = itemdata.guildMeleeBuffListB,
		draconicList = combatHeroDataB._draconicList
	}
	return infoA,infoB
end

function UIWahjop:DraconicListItem(list, item, itemdata, itempos)
	local DraconicSkill = self:FindWndTrans(item, "DraconicSkill")
	local icon = self:FindWndTrans(DraconicSkill, "icon")
	CS.ShowObject(icon, itemdata.ref ~= nil)
	if itemdata.ref then
		local param = {
			showName = true,
			showType = true,
			showStar = true,
			upRefId = itemdata.upRef.refId,
		}
		gModelDraconic:DrawSkillItem(self, DraconicSkill, param)
	end
	self:SetWndClick(item, function()
		if itemdata.ref then
			GF.OpenWnd("UIDraconicUpStar", { refId = itemdata.ref.refId, starNum = itemdata.upRef.rankNow, tips = true})
		end
    end)
-- 	local Icon = self:FindWndTrans(item,"Icon")
-- 	local skillRefId = itemdata
-- print("381290381290830912830912   "..skillRefId)
-- 	local ref = gModelDraconic:GetDraconicRef(skillRefId)
-- 		local ref = GameTable.DraconicSuitRankRef[skillRefId]
-- 	if ref then
-- 		local iconPath = ref.skillIcon
-- 		self:SetWndEasyImage(Icon,iconPath,function ()
-- 			CS.ShowObject(Icon,true)
-- 		end)
-- 	end
-- 	self:SetWndClick(Icon,function ()
-- 		if ref then
-- 			GF.OpenWnd("UIDraconicUpStar", { refId = skillRefId })
-- 		end
-- 	end)
end

function UIWahjop:OnClickLook()
	local itemdata = self._combatData
	local wndType = self._wndType
	local combatType = LCombatTypeConst.COMBAT_BATTLE_VIDEO
	local reportUrl = itemdata.reportUrl or gModelGuildMelee:GetServerReportUrl(itemdata.reportServerId)
	local reportId = itemdata.reportId
	local wndPara = self._returnWndPara
	local combatData = {
		battleEndfun = function()
			if wndType == 2 then
				self:ReturnGuild(wndPara)
			elseif wndType == 1 then
				self:OnPlayEnd()
			end
		end,
		meName = itemdata.playerNameA,
		otherName = itemdata.playerNameB,
		reportUrl = reportUrl,
		serverId = itemdata.reportServerId,
		videoType = LVideoTypeConst.GUILD_WAR
	}
	gLFightManager:OnPlayBattleVideo(reportId,combatData,combatType)
end

function UIWahjop:InitEvent()
	self:SetWndClick(self.mBgImage, function(...) self:WndClose() end)
	self:SetWndClick(self.mBtnClose, function(...) self:WndClose() end)
	self:SetWndClick(self.mShareBtn, function(...) self:OnClickShare() end)
	self:SetWndClick(self.mLookBtn, function(...) self:OnClickLook() end)
end
-----------------------------------------------------------------------------------------------------------------------
function UIWahjop:OnClickShare()
	local data = {
		root = self.mShareBtn,
		shareType = ModelChat.CHATSHARE_MELEE,
		shareData = JSON.encode(self._combatData)
	}
	gModelGeneral:OpenShareTip(data)
end

function UIWahjop:HeroListItem(list, item, itemdata, itempos)
	local id = itemdata.id
	if(not id)then
		return
	end
	local heroTrans = self:FindWndTrans(item,"Image")
	local mask = self:FindWndTrans(item,"Mask")
	local bar_1 = self:FindWndTrans(item,"Bar_1")
	CS.ShowObject(bar_1,true)
	bar_1 = self:FindWndSlider(bar_1)
	bar_1.maxValue = itemdata.maxHp
	bar_1.value = itemdata.hp
	CS.ShowObject(mask,itemdata.hp <= 0)
	local herodata = {
		id = itemdata.id,
		refId = itemdata.refId,
		star = itemdata.star,
		level = itemdata.lv,
		skin = itemdata.skinId or itemdata.skin,
		grade = itemdata.grade,
		fightPower = itemdata.fightPower,
		isResonance = itemdata.resonance,
	}
	local InstanceID = item:GetInstanceID()
	local baseClass = self._commonIconList[InstanceID]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._commonIconList[InstanceID] = baseClass
		baseClass:Create(heroTrans)
	end
	baseClass:SetHeroDataSet(herodata)
	baseClass:DoApply()

	self:SetWndClick(heroTrans,function ()
		gModelHero:ReqShowHeroTip(itemdata.playerId,herodata,nil,nil,nil,itemdata.serverId)
	end)
end

function UIWahjop:OnClickPlayer(_playerId)
	if not _playerId then return end
	gModelGeneral:PlayerShowReq(_playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.OTHER_SYSTEM)
end

function UIWahjop:OnWndRefresh()
	self:InitCommand()
end
------------------------------------------------------------------
return UIWahjop


