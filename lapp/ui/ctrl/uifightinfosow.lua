---
--- Created by Administrator.
--- DateTime: 2023/10/10 21:06:11
--- 战报详情
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFightInfoSow:LWnd
local UIFightInfoSow = LxWndClass("UIFightInfoSow", LWnd)
------------------------------------------------------------------


local TabTypeEnums = {
	Skill = 1,
	Exclusive = 2,
	Rune = 3,
	Treasure = 4,
	Other = 5,
	DivineWeapon = 6,
}


--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFightInfoSow:UIFightInfoSow()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFightInfoSow:OnWndClose()
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFightInfoSow:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFightInfoSow:OnStart()
	LWnd.OnStart(self)
	self:InitUI()

	self._isEnus = gLGameLanguage:IsEnglishVersion()
	self._isVie = gLGameLanguage:IsVieVersion()
	self:InitData()
	self:SetStaticContent()
	self:InitUIEvent()
	self:RefreshContent()
end

function UIFightInfoSow:OnClickTab(itemdata)
	if self:CheckIsSelTab(itemdata) then return end

	self._curType =itemdata.type
	local list = self:FindUIScroll("tabList")
	if list then
		list:DrawAllItems(false)
	end

	self:RefreshBuffList()
end

function UIFightInfoSow:CheckIsSelTab(itemdata)
	return self._curType == itemdata.type
end

---@param itemdata LFightObjectData
function UIFightInfoSow:OnDrawHero(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	--local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootHero = self:FindWndTrans(AniRoot,"hero")
	local AniRootMask = self:FindWndTrans(AniRoot,"mask")
	--
	local AniRootSele = self:FindWndTrans(AniRoot,"sele")

	local maskDead = self:FindWndTrans(AniRootMask,"Dead")
	self:SetWndEasyImage(maskDead,"timecopy_txt_1")

	CS.ShowObject(AniRootHero,not itemdata.isEmpty)
	CS.ShowObject(AniRootMask,false)
	CS.ShowObject(AniRootSele,false)
	if itemdata.isEmpty then
		return
	end

	local id = itemdata:GetId()
	-- local objType = itemdata:GetArtifactType()
	-- 【C宠物系统】删掉宠物系统相关
	-- if objType == LFightConst.OBJ_PET then
	-- 	local petData = {
	-- 		id = id,
	-- 		refId = itemdata:GetRefId(),
	-- 		star = itemdata:GetStar(),
	-- 		level= itemdata:GetLevel(),
	-- 	}

	-- 	self:CreatePetIconImpl(AniRootHero,petData)

	-- else
		local herodata = {}
		herodata.id = id
		herodata.refId = itemdata:GetRefId()
		herodata.star = itemdata:GetStar()
		herodata.level = itemdata:GetLevel()
		herodata.isMon = itemdata:IsMonster()
		herodata.isResonance = itemdata:GetResonanceStatus()
		herodata.skin = itemdata:GetSkinId()

		local quality = itemdata:GetQuality()
		if quality and quality>0 then
			herodata.quality = quality
		end

		self:CreateHeroIconImpl(AniRootHero,herodata)
	-- end


	local isDead = itemdata:IsDead() or itemdata:GetHp() == 0
	CS.ShowObject(AniRootMask, isDead)

	self:SetWndClick(AniRootHero,function ()
		self:ShowHeroBuff(itemdata)
	end)
	self:SetWndLongClick(AniRootHero,function ()
		self:OnClickHeroIcon(itemdata)
	end,0.8,false)

	local curHeroId = self._selectHero and self._selectHero:GetId()
	local isSel = curHeroId == id
	CS.ShowObject(AniRootSele,isSel)

	self._uiRecord[id] = AniRootSele
end

function UIFightInfoSow:OnDrawTab(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local AniRootBtnTab = self:FindWndTrans(AniRoot,"BtnTab")

	self:SetWndTabText(AniRootBtnTab,itemdata.name)
	local isSel = self:CheckIsSelTab(itemdata)
	local state = isSel and LWnd.StateOn or LWnd.StateOff
	self:SetWndTabStatus(AniRootBtnTab,state)
	self:SetWndClick(AniRoot,function ()
		self:OnClickTab(itemdata)
	end)
end




function UIFightInfoSow:RefreshContent()
	local battleUnit = gLFightManager:GetCurBattleUnit()
	if not battleUnit then
		return
	end



	self._formationA = battleUnit:GetInfoShowFormation(LFightConst.SIDE_TEAM_A)
	self._formationB = battleUnit:GetInfoShowFormation(LFightConst.SIDE_TEAM_B)

	self._teamA = battleUnit:GetTeamAData()
	self._teamB = battleUnit:GetTeamBData()

	self._combatType = battleUnit:GetCombatType()
	self._reportCombatType = battleUnit:GetReportCombatType()

	self._uiRecord = {}

	self:InitItemList()

	self:RefreshBuffList()
end

function UIFightInfoSow:OnDrawBuff(list,item,itemdata,itempos)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	--local AniRootImage = self:FindWndTrans(AniRoot,"Image")
	local AniRootBuffIcon = self:FindWndTrans(AniRoot,"buffIcon")
	local AniRootName = self:FindWndTrans(AniRoot,"name")
	local AniRootRound = self:FindWndTrans(AniRoot,"round")
	local AniRootScroll = self:FindWndTrans(AniRoot,"scroll")
	local scrollDetail = self:FindWndTrans(AniRootScroll,"detail")
	local AniRootLvbg = self:FindWndTrans(AniRoot,"lvbg")
	local lvbgLv = self:FindWndTrans(AniRootLvbg,"lv")

	if(itemdata.isHighStageRaceSkill)then
		self:SetHighStageRaceSkillItem(item ,itemdata.skillId)
		return
	end

	local buffData = itemdata.buffShowData
	local cnt = #itemdata.buffShowList

	self:SetWndEasyImage(AniRootBuffIcon,buffData.icon)
	self:SetWndText(AniRootName,string.format("%s*%s",buffData.name,cnt))
	self:SetWndText(lvbgLv,buffData.level)
	self:SetWndText(scrollDetail,buffData.description)
	local str =""
	if buffData.round>0 then
		str = string.replace(ccClientText(16612),buffData.curRound)
	end
	self:SetWndText(AniRootRound,str)
end

function UIFightInfoSow:SetStaticContent()
	local str =ccClientText(31005) -- "加成详情")
	self:SetWndText(self.mTitle,str)

	self:CreateUIScrollImpl("tabList",self.mTabList,self._tabDataList,function(...)
		self:OnDrawTab(...)
	end)

	local data = {
		refId = 19002,
		IntroTran = self.mEmptyText,
		TextBgTran = self.mEmptyTextBg,
		IconTran = self.mEmptyIcon,
	}
	local emptyList = self:GetCommonEmptyList("norecord")
	emptyList:RefreshUI(data)
end
function UIFightInfoSow:SetHighStageRaceSkillItem(item,skillId)
	local AniRoot = self:FindWndTrans(item,"AniRoot")
	local buffIcon = self:FindWndTrans(AniRoot,"buffIcon")
	local nameTxt = self:FindWndTrans(AniRoot,"name")
	local round = self:FindWndTrans(AniRoot,"round")
	local AniRootScroll = self:FindWndTrans(AniRoot,"scroll")
	local descTxt = self:FindWndTrans(AniRootScroll,"detail")
	local AniRootLvbg = self:FindWndTrans(AniRoot,"lvbg")
	local lvlTxt = self:FindWndTrans(AniRootLvbg,"lv")
	local skillRef = gModelSkill:GetSkillRef(skillId)
	local buffName = ccLngText(skillRef.name)
	self:SetWndText(nameTxt,string.format("%s*%s",buffName,"1"))
	self:SetWndText(round,ccClientText(37768))
	self:SetWndText(lvlTxt,skillRef.level)
	self:SetWndText(descTxt,ccLngText(skillRef.description))
	self:SetWndEasyImage(buffIcon,skillRef.icon)
end

---@param itemdata LFightObjectData
function UIFightInfoSow:OnClickHeroIcon(itemdata)
	local objType = itemdata:GetArtifactType()
	if objType ~= LFightConst.OBJ_NORMAL then
		return
	end

	if self._combatType == LCombatTypeConst.COMBAT_BATTLE_VIDEO_SIMULATION then
		local str =ccClientText(16905) --"不可查看英雄信息"
		GF.ShowMessage(str)
		return
	end



	local showTip = true
	local playerId
	local serverId
	local _actOn = itemdata:GetActOn()
	if _actOn == 1 then
		playerId = self._teamA.playerId
		serverId = self._teamA.serverId
	else
		playerId = self._teamB.playerId
		serverId = self._teamB.serverId
		showTip = gModelBattle:CheckShowEnemyTip(self._reportCombatType)
	end

	if showTip then
		local data = {
			id = itemdata:GetId(),
			refId = itemdata:GetRefId(),
			level = itemdata:GetLevel(),
			star = itemdata:GetStar(),
			grade = itemdata:GetGrade(),
			fightPower = itemdata:GetFightPower() or 0,
			isResonance = itemdata:GetResonanceStatus(),
			skin = itemdata:GetSkinId(),
		}
		gModelHero:ReqShowHeroTipEx({playerId = playerId,heroData = data,serverId = serverId})
	else
		local str = ccClientText(16905)
		GF.ShowMessage(str)
	end
end

function UIFightInfoSow:InitItemList()
	local heroListA = self:GetShowHeroDataList(self._formationA)
	local heroListB = self:GetShowHeroDataList(self._formationB)
    local gridMax = LCombatFormationConst.GRID_MAX
	for i = 1, gridMax do
		local obj1 = LxUnity.InstantObject(self.mItemTemplateObj)
		local obj2 = LxUnity.InstantObject(self.mItemTemplateObj)
		obj1:SetActive(true)
		obj2:SetActive(true)
		local trans1 = obj1.transform
		local trans2 = obj2.transform
		trans1:SetParent(self["mLeftPos" .. i], false)
		trans2:SetParent(self["mRightPos" .. i], false)
		self:OnDrawHero(nil, trans1, heroListA[i])
		self:OnDrawHero(nil, trans2, heroListB[i])
	end
end

function UIFightInfoSow:ShowHeroBuff(itemdata)
	local heroId = itemdata:GetId()
	local oldHeroId = nil
	if self._selectHero then
		oldHeroId = self._selectHero:GetId()
	end
	if oldHeroId == heroId then
		return
	end

	self._selectHero = itemdata

	self:RefreshBuffList()

	for k,v in pairs(self._uiRecord) do
		local isSel = heroId == k
		CS.ShowObject(v,isSel)
	end

end

function UIFightInfoSow:GetShowHeroDataList(formationdata)
	local selId = self:GetWndArg("selId")
	local indexToHero ={}
	for k,v in ipairs(formationdata) do
		indexToHero[v:GetIndex()] = v
	end
	local heroList = {}
	local gridMax = LCombatFormationConst.GRID_MAX
	for k = 1,gridMax do
		local herodata = indexToHero[k]
		if herodata then
			table.insert(heroList,herodata)
			local id = herodata:GetId()
			if id == selId then
				self._selectHero = herodata
			end
		else
			table.insert(heroList,{isEmpty = true})
		end
	end

	return heroList
end


function UIFightInfoSow:InitData()
	--local tabDataList = {}
	--table.insert(tabDataList,{type = TabTypeEnums.Skill,name = ccClientText(31000)}) 		--"技 能"
	--table.insert(tabDataList,{type = TabTypeEnums.Exclusive,name = ccClientText(31001)}) 	--"专 属"
	--table.insert(tabDataList,{type = TabTypeEnums.Rune,name = ccClientText(31002)}) 		--"符 文"
	--table.insert(tabDataList,{type = TabTypeEnums.Treasure,name = ccClientText(31003)}) 	--"灵 物"
	--table.insert(tabDataList,{type = TabTypeEnums.Other,name = ccClientText(31004)}) 		--"其 它"
	--self._tabDataList = tabDataList

	local tabDataList = {}
	for k,v in pairs(GameTable.BuffTabRef) do
		table.insert(tabDataList,{
			type = k,
			name = ccLngText(v.name),
			sort = v.sort,
		})
	end
	table.sort(tabDataList,function(a, b) return a.sort < b.sort end)
	self._curType = tabDataList[1].type
	self._tabDataList = tabDataList
end

function UIFightInfoSow:RefreshBuffList()
	local itemdata = self._selectHero
	if not itemdata then return end

	local buffList = itemdata:GetBuffList()
	local dataList = gModelSkill:FormatBuffShowList(buffList)

	local showList = {}
	for k,v in ipairs(dataList) do
		if v.buffShowData.showType == self._curType then
			table.insert(showList,v)
		end
	end
	--移除高阶段位赛
	-- local isHighStageRaceType = gModelHighStageRace:IsHighStageRace(self._combatType)
	-- if(self._curType == 1 and isHighStageRaceType)then
	-- 	local highInfo = gModelHighStageRace:GetCrossGradingHighInfo()
	-- 	if(highInfo and highInfo.voteType == 2 and highInfo.voteResultList)then
	-- 		for i, v in ipairs(highInfo.voteResultList) do
	-- 			local data = {}
	-- 			data.isHighStageRaceSkill = true
	-- 			data.skillId = v
	-- 			table.insert(showList,data)
	-- 		end
	-- 	end
	-- end
	local isEmpty = #showList == 0
	CS.ShowObject(self.mNoRecord2,isEmpty)
	CS.ShowObject(self.mBuffList,not isEmpty)
	if isEmpty then
		return
	end

	self:CreateUIScrollImpl("buffList",self.mBuffList,showList,function (...)
		self:OnDrawBuff(...)
	end,UIItemList.SUPER)

	local list = self:FindUIScroll("buffList")
	list:MoveToPos(1)
end

function UIFightInfoSow:InitUIEvent()
	self:SetWndClick(self.mMask,function () self:WndClose() end)
	self:SetWndClick(self.mBtnClose,function () self:WndClose() end)

end


------------------------------------------------------------------
return UIFightInfoSow