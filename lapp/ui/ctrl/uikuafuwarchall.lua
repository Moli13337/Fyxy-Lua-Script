---
--- Created by Administrator.
--- DateTime: 2024/6/17 15:12:29
---
------------------------------------------------------------------
local LWnd = LWnd
local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder
---@class UIKuafuWarChall:LWnd
local UIKuafuWarChall = LxWndClass("UIKuafuWarChall", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIKuafuWarChall:UIKuafuWarChall()
	self.heroIconList = {}
	self.commonUIList = {}
	self.uiHeadList = {}
	self.dicList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIKuafuWarChall:OnWndClose()
	self:ClearCommonIconList(self.heroIconList)
	self:ClearCommonIconList(self.commonUIList)
	self:ClearCommonIconList(self.uiHeadList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIKuafuWarChall:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIKuafuWarChall:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitText()
	self:InitMenber()
	self:InitEvent()
	self:InitData()
end

function UIKuafuWarChall:DrawHero(_, item, data, pos)
	local root = self:FindWndTrans(item, "Root")
	local data = {
		id = data.id,
		refId = data.refId,
		star = data.star,
		level = data.level,
		skin = data.skin,
		isResonance = data.isResonance,
		grade = data.grade,
		fightPower = data.fightPower,
		isMon = self.data.npcId ~= 0
	}
	self.heroIconList[pos] = CommonIcon:New()
	self.heroIconList[pos]:Create(root)
	self.heroIconList[pos]:SetHeroDataSet(data)
	self.heroIconList[pos]:DoApply()

	self:SetWndClick(root,function()
		if self.data.npcId == 0 then
			gModelHero:ReqShowHeroTip(self.data.playerInfo._playerId, data)
		else
			GF.ShowMessage(ccClientText(43857))
		end
	end)
end

function UIKuafuWarChall:SetReward()
	local cfg = gModelCrossWar:GetWarDomainRefById(self.data.rank)
	local data = LUtil.GetRefItemDataList(cfg.rankReward)
	for i, v in ipairs(data) do
		local root = self:FindWndTrans(self.mRewardList, "Root" .. i)
		local instanceId = root:GetInstanceID()
		if not self.commonUIList[instanceId] then
			self.commonUIList[instanceId] = CommonIcon:New()
			self.commonUIList[instanceId]:Create(root)
		end
		self.commonUIList[instanceId]:SetCommonReward(v.itemType, v.itemId, v.itemNum)
		self.commonUIList[instanceId]:DoApply()
		self:SetWndClick(root, function()
			gModelGeneral:ShowCommonItemTipWnd(v)
		end)
		CS.ShowObject(root, true)
	end
end

function UIKuafuWarChall:SetDicList(dicList)
	local DraconicSuitRankRef = GameTable.DraconicSuitRankRef
    local DraconicRef = GameTable.DraconicRef
	for i = 1, 4 do
		local data = {ref = nil, upRef = nil}
		if dicList[i] and dicList[i] > 0 then
			local upRef = DraconicSuitRankRef[dicList[i]]
			local ref = DraconicRef[upRef.type]
			data = {ref = ref, upRef = upRef}
		end

		local root = self:FindWndTrans(self.mDicList, "Root" .. i)
		self:SetDicIcon(root, data)
	end
end

function UIKuafuWarChall:InitData()
	self.data = self:GetWndArgList()
	if not self.data then
		return
	end
	if self.data.npcId == 0 then
		gModelPlayer:OnGetFormationShowReq(self.data.playerInfo._playerId, LCombatTypeConst.COMBAT_CROSS_WAR)
		local selfId = gModelPlayer:GetPlayerId()
		CS.ShowObject(self.mChanllenge, self.data.playerInfo._playerId ~= selfId)
		return
	else
		self.monsterCfg = gModelHero:GetMonsterFormationRefByRefId(self.data.npcId)
		local heroList = {}
		for i = 1, 10 do
			local monster = self.monsterCfg["monster" .. i]
			if monster > 0 then
				local cfg = GameTable.MonsterAttrRef[monster]
				local data = {
					refId = monster,
					level = cfg.lv,
					star = 0,
				}
				table.insert(heroList, data)
			end
		end
		local dicList = { 0, 0, 0, 0 }
		local dicInfo = string.split(self.monsterCfg.draconicList, "|")
		for _, v in ipairs(dicInfo) do
			local s = string.split(v, "=")
			dicList[tonumber(s[1])] = tonumber(s[2])
		end
		self.dicList = dicList
		self:SetHeroList(heroList)
		self:SetDicList(dicList)
		self:SetPlayerInfo()
		self:SetReward()
		self:SetChallenge()
		self:ClickTab(1)
	end
end

function UIKuafuWarChall:ClickTab(index)
	if self.curClick == index then
		return
	end
	if not self.tabBtnTrans[index].checkClick() then
		return
	end
	for i, v in ipairs(self.tabBtnTrans) do
		local isSel = i == index
		self:SetWndTabStatus(v.btn, isSel and 0 or 1)
		CS.ShowObject(v.obj, isSel)
	end
	self.curClick = index
end

function UIKuafuWarChall:SetHeadIcon(trans, data)
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
		if self.data.npcId == 0 then
			gModelGeneral:PlayerShowReq(
				data._playerId,
				LCombatTypeConst.COMBAT_MAIN,
				LPlayerShowConst.OTHER_SYSTEM
			)
		end
	end)
end

function UIKuafuWarChall:SetChallenge()
	local freeNum = gModelCrossWar:GetFreeChallengeNum()
	local buyNum = gModelCrossWar:GetBuyChallengeNum()
	local challengeNum = gModelCrossWar:GetChallengeNum()
	local maxBuyChallengesNum = gModelCrossWar:GetMaxChallengeBuyNum()
	local s = ccClientText(43834)
	local showAdd = false
	if freeNum >= 0 and buyNum == maxBuyChallengesNum then
		s = string.replace(s, freeNum)
		showAdd = freeNum == 0
	else
		s = ccClientText(43835)
		s = string.replace(s, challengeNum, buyNum)
		showAdd = true
	end
	self:SetWndText(self.mChanllengeNumText, s)
	LayoutRebuilder.ForceRebuildLayoutImmediate(self.mChanllengeNumText)
	CS.ShowObject(self.mAddBtn, showAdd)
end

function UIKuafuWarChall:SetHeroList(heros)
	self.heroList = self:GetUIScroll("mHeroList")
	self.heroList:Create(self.mHeroList, heros, function(...) self:DrawHero(...) end, UIItemList.SUPER_GRID)
end

function UIKuafuWarChall:InitMenber()
	self.tabBtnTrans = {
		{
			btn = self.mTeamBtn,
			obj = self.mHeroList,
			checkClick = function()
				return true
			end
		},
		{
			btn = self.mDicBtn,
			obj = self.mDicList,
			checkClick = function()
				for _, v in ipairs(self.dicList) do
					if v > 0 then
						return true
					end
				end
				GF.ShowMessage(ccClientText(43858))
				return false
			end
		}
	}
end

function UIKuafuWarChall:InitEvent()
	self:SetWndClick(self.mBg, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mCloseBtn, function()
		self:WndClose()
	end)
	self:SetWndClick(self.mAddBtn, function()
		self:ClickAddBtn()
	end)
	self:SetWndClick(self.mChanllengeBtn, function()
		self:ClickChanllengeBtn()
	end)
	for i, v in ipairs(self.tabBtnTrans) do
		self:SetWndClick(v.btn, function()
			self:ClickTab(i)
		end)
	end

	self:WndNetMsgRecv(LProtoIds.GetFormationShowResp, function(pb)
		self:OnGetFormationShowResp(pb)
	end)

	self:WndEventRecv("CrossWarTempleBuyChallengeCntResp", function()
		GF.ShowMessage(ccClientText(14131))
		self:InitData()
	end)
end

function UIKuafuWarChall:InitText()
	self:SetWndText(self.mLblBiaoti, ccClientText(43822))
	self:SetWndText(self.mRewardTitle, ccClientText(43823))
	self:SetWndTabText(self.mTeamBtn, ccClientText(43824))
	self:SetWndTabText(self.mDicBtn, ccClientText(43825))
	self:SetWndButtonText(self.mChanllengeBtn, ccClientText(43826))
end

function UIKuafuWarChall:ClickChanllengeBtn()
	local minPalace = gModelCrossWar:GetMinWarTemplePalace()
	if gModelWarTemple:GetBaseInfo().palace < minPalace then
		local s = ccClientText(43828)
		GF.ShowMessage(string.replace(s, ccLngText(GameTable.BattleTemplePalaceRef[minPalace].name)))
		return
	end
	local state = gModelCrossWar:GetState()
	if state == 2 then
		GF.ShowMessage(ccClientText(43829))
		return
	elseif state == 0 then
		GF.ShowMessage(ccClientText(43830))
		return
	end
	local selfOutsideInfo = gModelCrossWar:GetSelfOutsideInfo()
	if not table.isempty(selfOutsideInfo) and self.data.rank >= selfOutsideInfo.rank then
		local str
		if selfOutsideInfo.rank == 1 then
			str = ccClientText(43831)
		elseif self.data.rank >= selfOutsideInfo.rank then
			str = ccClientText(43833)
		end
		GF.ShowMessage(str)
		return
	end
	if gModelCrossWar:GetFreeChallengeNum() < 1 and gModelCrossWar:GetChallengeNum() < 1 then
		GF.ShowMessage(ccClientText(42042))
		if gModelCrossWar:GetBuyChallengeNum() > 0 then
			GF.OpenWnd("UIKuafuWarChallBuy")
		end
		return
	end

	local targetId = self.data.npcId
	local monsterRefId = 0
	local playerId, otherLevel, otherName, otherPlayerHead
	if targetId == 0 then
		targetId = self.data.playerInfo._playerId
		playerId = self.data.playerInfo._playerId
		otherLevel = self.data.playerInfo._grade
		otherName = self.data.playerInfo._name
		otherPlayerHead = self.data.playerInfo._head
	else
		monsterRefId = targetId
		targetId = 0
	end
	gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_CROSS_WAR, {
		wndType = 1,
		targetId = targetId,
		playerId = playerId,
		otherName = otherName,
		otherPlayerHead = otherPlayerHead,
		otherLevel = otherLevel,
		monsterRefId = monsterRefId,
		rank = self.data.rank,
		returnFunc = function()
			FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON,{index = LMainBtnIndexConst.OUTSKIRTS})
			GF.ChangeMap("LCityMap")
			GF.OpenWndBottom("UIOutts", {childIndex = 2})
			GF.OpenWndBottom("UIKuafuWar")
		end,
	})
end

function UIKuafuWarChall:SetDicIcon(root, data)
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
		if data.ref and self.data.npcId == 0 then
			GF.OpenWnd("UIDraconicUpStar", { refId = data.ref.refId, starNum = data.upRef.rankNow, tips = true})
		end
    end)
end

function UIKuafuWarChall:ClickAddBtn()
	if gModelCrossWar:GetBuyChallengeNum() > 0 then
		GF.OpenWnd("UIKuafuWarChallBuy")
	else
		GF.ShowMessage(ccClientText(43827))
	end
end

function UIKuafuWarChall:SetPlayerInfo()
	if self.data.npcId == 0 then
		self:SetHeadIcon(self.mHeadIcon, self.data.playerInfo)
		local s = "【#a1#】#a2#"
		self:SetWndText(self.mText, string.replace(s, self.data.playerInfo._serverName, self.data.playerInfo._name))
		self:SetWndText(self.mPowerText, LUtil.NumberCoversion(self.data.power))
	else
		local icon = self:FindWndTrans(self.mHeadIcon, "IconBg/Icon")
		local cfg = gModelCrossWar:GetWarDomainRefById(self.data.rank)
		local iconRes = GameTable.CharacterEffectRef[cfg.monsterShow].icon
		self:SetWndEasyImage(icon, iconRes)
		self:SetWndText(self.mText, ccLngText(self.monsterCfg.name))
		self:SetWndText(self.mPowerText, LUtil.NumberCoversion(self.monsterCfg.monsterPower))
	end

end

function UIKuafuWarChall:OnGetFormationShowResp(pb)
	self:SetPlayerInfo()
	self:SetReward()
	self:SetHeroList(pb.heroData.heros)
	self:SetDicList(pb.heroData.draconicStarRefIds)
	self.dicList = pb.heroData.draconicStarRefIds
	self:SetChallenge()
	self:ClickTab(1)
end



------------------------------------------------------------------
return UIKuafuWarChall