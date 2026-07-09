---
--- Created by Administrator.
--- DateTime: 2023/10/7 15:54:59
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIPkPerDetails:LWnd
local UIPkPerDetails = LxWndClass("UIPkPerDetails", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIPkPerDetails:UIPkPerDetails()
	---@type table<number,CommonIcon>
	self._iconHeroClsList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIPkPerDetails:OnWndClose()
	self:ClearCommonIconList(self._iconHeroClsList)
	self._iconHeroClsList = nil
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIPkPerDetails:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIPkPerDetails:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitData()
	self:InitView()
	self:InitStaticContent()
end

function UIPkPerDetails:InitEvent()
	self:SetWndClick(self.mBg, function (...) self:WndClose() end)
end

function UIPkPerDetails:SetHero(item, hero, playerId)
	local id ,refId,star,level,grade,fightPower = hero.id,hero.refId,hero.star,hero.level,hero.grade,hero.fightPower
	local heroData = {
		id = id,
		refId = refId,
		star = star,
		level = level,
		skin = hero.skin,
		isResonance = hero.isResonance
	}

	local heroRoot = self:FindWndTrans(item,"HeroIcon")
	local instanceId = item:GetInstanceID()
	local heroIcon = self._iconHeroClsList[instanceId]
	if not heroIcon then
		heroIcon = CommonIcon:New()
		self._iconHeroClsList[instanceId] = heroIcon
		heroIcon:Create(heroRoot)
		self:SetIconClickScale(heroRoot, true)
	end
	heroIcon:SetHeroDataSet(heroData)
	heroIcon:DoApply()

	self:SetWndClick(heroRoot, function()
		local data = {
			id = id,
			refId = refId,
			level = level,
			star = star,
			grade = grade,
			fightPower = fightPower,
			isResonance = hero.isResonance,
			skin = hero.skin,
		}
		gModelHero:ReqShowHeroTip(playerId,data,nil,nil,nil,self._serverId)
	end)
end

function UIPkPerDetails:OnPinnaclePlayerInfoResp(pb)
	if pb.playerId ~= self._playerId then return end

	self._rank		 = pb.rank			--巅峰赛排名（负数表示未参加巅峰赛）
	self._battleCount = pb.battleCount	--巅峰赛战斗次数
	self._winCount	 = pb.winCount		--巅峰赛战斗胜利次数
	self._rankMax	 = pb.rankMax		--历史最佳
	self:RefreshSpeak()
end

function UIPkPerDetails:InitView()
	if not self._playerInfo then return end
	self:RefreshPlayer()
	self:SetHeroSpine()
end

function UIPkPerDetails:OnWeekChampPlayerInfoResp(pb)
	if pb.playerId ~= self._playerId then return end

	self._rank		 = pb.rank			--巅峰赛排名（负数表示未参加巅峰赛）
	self._battleCount = pb.battleCount	--巅峰赛战斗次数
	self._winCount	 = pb.winCount		--巅峰赛战斗胜利次数
	self._rankMax	 = pb.rankMax		--历史最佳
	self:RefreshSpeak()
end

function UIPkPerDetails:InitData()
	local playerInfo = self:GetWndArg("playerInfo")
	local noticeType = self:GetWndArg("noticeType")

	self._playerInfo = playerInfo
	local playerId = playerInfo.playerId
	self._playerId = playerId
	self._figure   = playerInfo.figure

	self._combatData = nil
	local formationType
	if noticeType == ModelGeneral.NOTICE_ARENAPEAK_FOREIGN then
		formationType = LCombatTypeConst.COMBAT_ARENA_PEAK_ATTACK
		gModelArena:OnPinnaclePlayerInfoReq(playerId)
	-- else
	-- 	formationType = LCombatTypeConst.COMBAT_CROSS_SERVER_CHAMPION
	-- 	gModelCrossServer:OnWeekChampPlayerInfoReq(playerId)
	end

	gModelPlayer:OnGetFormationShowReq(playerId, formationType)
end

function UIPkPerDetails:InitUIEvent()
	self:SetWndClick(self.mBgBtn,function () self:OnClickClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIPkPerDetails:SetRunSpineAin(key)
	local dpSpine = self:FindWndSpineByKey(key)
	if not dpSpine:IsDpValid() then return  end
	if not dpSpine:GetAnimation("attack1") then return end
	local entryName = dpSpine:GetCurTrackEntryName()
	if entryName ~= "attack1" then
		dpSpine:PlayAnimation(0,"attack1",false)
		dpSpine:SetAnimationCompleteFunc(function (ainName)
			if ainName == "attack1" then
				dpSpine:PlayAnimation(0,"idle",true)
			end
		end)
	end
end

function UIPkPerDetails:RefreshHeroList()
	local combatData = self._combatData
	if not combatData then return end

	local heros = {}
	for k,v in ipairs(combatData.heros) do
		local grid = combatData.grids[k]
		heros[grid] = v
	end

	local itemTemp = self.mHeroTemplate
	local gridMax = LCombatFormationConst.GRID_MAX
	for i=1,gridMax do
		local root = self:FindWndTrans(self.mHeroList, tostring(i))
		LxResUtil.DestroyChild(root)
		if heros[i] then
			local itemNew = LxResUtil.NewObject(itemTemp.gameObject)
			itemNew.transform:SetParent(root, false)
			itemNew.transform.localPosition = Vector3.zero
			CS.ShowObject(itemNew, true)
			self:SetHero(itemNew.transform, heros[i], self._playerId)
		end
	end
end

function UIPkPerDetails:InitStaticContent()
	self:SetWndText(self.mCloseTip,ccClientText(10103))
end

function UIPkPerDetails:OnGetFormationShowResp(pb)
	local targetId=pb.targetId
	if targetId ~= self._playerId then return end

	self._combatData = pb.heroData
	self:RefreshTeamNode()
end

function UIPkPerDetails:InitMessage()--接协议
	self:WndNetMsgRecv(LProtoIds.GetFormationShowResp,function (...)
		self:OnGetFormationShowResp(...)
	end)
	self:WndNetMsgRecv(LProtoIds.PinnaclePlayerInfoResp,function (...)
		self:OnPinnaclePlayerInfoResp(...)
	end)
	self:WndNetMsgRecv(LProtoIds.WeekChampPlayerInfoResp,function (...)
		self:OnWeekChampPlayerInfoResp(...)
	end)
end

function UIPkPerDetails:RefreshTeamNode()
	self:RefreshHeroList()
	self:RefreshSkillList()
end

function UIPkPerDetails:RefreshPlayer()
	local playerData = self._playerInfo
	local playerName = playerData.name
	local serverId 	= playerData.serverId
	--local serverName = gLGameLogin:GetServerShotNameById(serverId)
	--local nameStr = string.replace(ccClientText(27423), playerName)
	self:SetWndText(self.mName, playerName)
	self:SetWndText(self.mPowerText, LUtil.PowerNumberCoversion(playerData.power))
end

function UIPkPerDetails:RefreshSkillList()
	local combatData = self._combatData
	if not combatData then return end

	local skillInfos = combatData.skillInfo
	local dataList = {}
	for _,v in ipairs(skillInfos) do
		if v.skillRefId > 0 then
			dataList[v.index] = v
		end
	end

	local itemTemp = self.mSkillTemplate
	for i = 1,4 do
		local data = dataList[i]
		if not data then
			data=
			{
				isEmpty = true
			}
		end

		local root = self:FindWndTrans(self.mSkillList, tostring(i))
		LxResUtil.DestroyChild(root)
		if data and not data.isEmpty then
			local itemNew = LxResUtil.NewObject(itemTemp.gameObject)
			itemNew.transform:SetParent(root, false)
			itemNew.transform.localPosition = Vector3.zero
			CS.ShowObject(itemNew, true)
			self:SetSkill(itemNew.transform, data)
		end
	end
end

function UIPkPerDetails:SetHeroSpine()
	if not self._figure then return end
	local ref = gModelPlayer:GetRoleAdventureImage(self._figure)
	if(not ref)then
		return
	end

	CS.ShowObject(self.mHeroSpine,true)
	local spine = self:FindWndSpineByKey("spineKey")
	if(spine)then
		self:DestroyWndSpineByKey("spineKey")
	end
	local paintFlip=ref.paintFlip==1
	local paintMultiple=ref.paintMultiple
	self:CreateWndSpine(self.mHeroSpine,ref.paint,"spineKey",false,function(dpSpine)
		dpSpine:SetScale(paintMultiple)
		dpSpine:SetFlipX(paintFlip)
		local dpTrans =dpSpine:GetDisplayTrans()
		dpTrans.anchorMin = Vector2.New(0.5,0.5)
		dpTrans.anchorMax = Vector2.New(0.5,0.5)
		dpSpine:PlayAnimationSolid("idle",true)
		self:SetWndClick(self.mHeroSpine,function ()
			self:SetRunSpineAin("spineKey")
		end)
	end)
end

function UIPkPerDetails:RefreshSpeak()
	local winCount = self._winCount
	local lostCount = math.max(self._battleCount - winCount, 0)

	local rank = self._rank
	local rankStr
	if rank and rank > 0 then
		rankStr = string.replace(ccClientText(27432), rank)
	else
		rankStr = ccClientText(27431)
	end

	local rankMax = self._rankMax
	local rankMaxStr
	if rankMax and rankMax > 0 then
		rankMaxStr = string.replace(ccClientText(27432), rankMax)
	else
		rankMaxStr = ccClientText(27431)
	end

	local str = string.replace(ccClientText(27430), winCount, lostCount, rankStr, rankMaxStr)
	self:SetWndText(self.mSpeakText, str)
	CS.ShowObject(self.mSpeakBg, true)
end

function UIPkPerDetails:SetSkill(item,itemdata)
	-- local iconBg = self:FindWndTrans(item,"iconBg")
	-- local icon = self:FindWndTrans(item,"icon")

	-- CS.ShowObject(icon,not itemdata.isEmpty)
	-- if itemdata.isEmpty then
	-- 	self:SetWndClick(item,function () end)
	-- 	return
	-- end
	-- local skillRefId = itemdata.skillRefId
	-- local info = gModelTreasure:GetSkillInfo(skillRefId)
	-- local has = false
	-- if info then
	-- 	has = true
	-- 	self:SetWndEasyImage(iconBg,info.iconBg)
	-- 	local iconPath = gModelTreasure:GetTreasureIconByRefId(info.refId, itemdata.info and itemdata.info.skin or nil)
	-- 	self:SetWndEasyImage(icon,iconPath)
	-- end

	-- CS.ShowObject(icon,has)

	-- self:SetWndClick(item, function()
	-- 	gModelGeneral:OpenOnlyTreasureTip({treasureData = itemdata.info})
	-- end)
end



------------------------------------------------------------------
return UIPkPerDetails


