---
--- Created by BY.
--- DateTime: 2023/10/30 14:36:47
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIAdjstFonPop:LWnd
local UIAdjstFonPop = LxWndClass("UIAdjstFonPop", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIAdjstFonPop:UIAdjstFonPop()
	self._playerTrList = {}				--玩家队伍transform列表
	self._monsterTrList = {}			--怪物队伍transform列表
	self._commonIconList = {}
    self._indexTextList = {}
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIAdjstFonPop:OnWndClose()
	self:CleanDragList()
	self:ClearCommonIconList(self._commonIconList)
	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIAdjstFonPop:OnCreate()
	LWnd.OnCreate(self)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIAdjstFonPop:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitEvent()
	self:InitMessage()
	self:InitCommand()
end
function UIAdjstFonPop:InitEmenyPlayerList()
	local _formationLen = self._formationLen or 0
	local _monsterList = {}
	if(not self._monsterList or #self._monsterList == 0)then
		return
	end
	for i, v in pairs(self._monsterList) do
		local getMonsterData = function(heroList)
			local list = {}
			for j, k in pairs(heroList) do
				local data = {
					refId = k.refId,
					star = k.star,
					level = k.lv,
				}
				table.insert(list,data)
			end
			return list
		end
		local getSkillData = function(treasureIdList)
			local list = {}
			for j, k in pairs(treasureIdList) do
				if k.skillRefId > 0 then
					--local suitRef = GameTable.TreasureSuitRankRef[k.info.skillRefId]
					--table.insert(list,suitRef.type)

					local upRef = GameTable.DraconicSuitRankRef[k]
					local ref = GameTable.DraconicRef[upRef.type]
					table.insert(list,upRef.type)
				end
			end
			return list
		end
		local data = {
			monsterData = getMonsterData(v.prefabNameList),
			skillData = getSkillData(v.combatTreasures)
		}
		table.insert(_monsterList,data)
	end
	local _monsterTrList = self._monsterTrList or {}
	for i = 1, 5 do
		local isShow = i <= _formationLen
		local tr = _monsterTrList[i]
		if not tr then
			break
		end
		CS.ShowObject(tr,isShow)
		self:RefreshTeam(tr,_monsterList[i],i,"monster")
	end
end
function UIAdjstFonPop:CheckDragItemSwap(curData, curPos)
	local curIndexPos = self._dragOriginPos[curData.index]
	local curOriginPosY = curIndexPos.y + curData.centerY
	local centerY = curData.centerY + curPos.y
	local swapIndex = nil
	local bMoveUp = true
	for k,v in pairs(self._dragIndexList) do
		if k ~= curData.index and not self:IsItemLock(k) then
			local originPos = self._dragOriginPos[k]
			local dragKey = "_dragItem_"..v
			local dragItemData = self._dragItemDataList[dragKey]
			local itemcenterY = dragItemData.centerY + originPos.y
			local itemmidH = dragItemData.midH
			local odis = centerY - itemcenterY
			local dis = odis
			if dis < 0 then
				dis = -dis
			end
			if dis < itemmidH then
				bMoveUp = curOriginPosY >= itemcenterY
				swapIndex = k
				break
			end
		end
	end
	if not swapIndex then return end

	local min = bMoveUp and (curData.index + 1) or (curData.index - 1)
	local max = bMoveUp and swapIndex or swapIndex

	local delta = bMoveUp and -1 or 1

	for k=min, max, -delta do
		local keyIndex = self._dragIndexList[k]
		local dragKey = "_dragItem_"..keyIndex
		local dragItemData = self._dragItemDataList[dragKey]
		local newIndex = k + delta
		local oldIndex = dragItemData.index
		dragItemData.index = newIndex
		local item = dragItemData.item
		local tween = dragItemData.tween
		if tween then
			tween:Kill(false)
		end
		local originPos = self._dragOriginPos[newIndex]
		tween = item:DOLocalMoveY(originPos.y, 0.2)
		tween:OnComplete(function()
			local dragItemData = self._dragItemDataList[dragKey]
			if dragItemData then
				dragItemData.tween = nil
			end
		end)
		dragItemData.tween = tween
		tween:PlayForward()
		self:OnSwap(oldIndex, newIndex)
	end
	table.remove(self._dragIndexList, curData.index)
	curData.index = swapIndex
	table.insert(self._dragIndexList,swapIndex, curData.keyIndex)
end
---------------------------------------拖动-----------------------------------
function UIAdjstFonPop:InitDragList()
	self._dragItemDataList = {}
	self._dragOriginPos = {}
	self._dragIndexList = {}
	local _formationLen = self._formationLen
	for k,v in ipairs(self._playerTrList) do
		if k > _formationLen then
			break
		end
		table.insert(self._dragIndexList, k)

		local dragKey = "_dragItem_"..k

		local vector3List = v:GetLocalCorners()
		local vecMin = vector3List[0]
		local vecMax = vector3List[2]

		local minX = vecMin.x
		local minY = vecMin.y
		local maxX = vecMax.x
		local maxY = vecMax.y
		local centerX = (vecMax.x + vecMin.x) / 2
		local centerY = (vecMax.y + vecMin.y) / 2

		local width = vecMax.x - vecMin.x
		local height = vecMax.y - vecMin.y
		local midW = width / 2
		local midH = height / 2

		self._dragItemDataList[dragKey] = {
			key = dragKey,
			keyIndex = k,
			index = k,
			item = v,
			minX=minX,
			minY=minY,
			maxX=maxX,
			maxY=maxY,
			centerX = centerX,
			centerY = centerY,
			width = width,
			height = height,
			midW = midW,
			midH = midH,
		}
		table.insert(self._dragOriginPos, v.localPosition)
		self:InternalUIDragSetItem(dragKey,v,CS.YXUIDrag.DragMode.DragNothing)
	end

	local len = #self._dragOriginPos
	local top = self._dragOriginPos[1]
	local bottom = self._dragOriginPos[len]
	local itemTopData = self._dragItemDataList["_dragItem_1"]
	local itemBottomData = self._dragItemDataList["_dragItem_"..len]

	self._dragOriginLimitMinY = bottom.y + itemBottomData.minY
	self._dragOriginLimitMaxY = top.y + itemTopData.maxY

end

function UIAdjstFonPop:HeroListItem(list, item, itemdata, itempos)
	if not itemdata then
		return
	end
	local image = self:FindWndTrans(item,"Image")
	local root = self:FindWndTrans(item,"Root")
	CS.ShowObject(root,itemdata.refId > 0)
	CS.ShowObject(image,itemdata.refId <= 0)
	if itemdata.refId <= 0 then
		return
	end
	local InstanceID = item:GetInstanceID()
	self:InitHero(root,InstanceID,itemdata)
end
function UIAdjstFonPop:CleanDragList()
	for k,v in pairs(self._dragItemDataList or {}) do
		v.item = nil
		if v.tween then
			v.tween:Kill(false)
			v.tween = nil
		end
	end
end
function UIAdjstFonPop:IsItemLock(index)
	return false
end
--移除高阶段位赛
-- function UIAdjstFonPop:GetCombatTypeDataHighStageRace37()
-- 	local emenyHeroDataList = self:GetWndArg("emenyHeroDataList")
-- 	local extraData = self:GetWndArg("extraData")
-- 	--local fomationList = self:GetWndArg("fomationList")
-- 	local teamCnt = self:GetWndArg("teamCnt")
-- 	local formationLen,monsterList,monsterHead,monsterName
-- 	if(emenyHeroDataList and extraData)then
-- 		formationLen = teamCnt
-- 		monsterList = emenyHeroDataList
-- 		gModelGeneral:PlayerShowReq(extraData.playerId, LCombatTypeConst.COMBAT_MAIN,LPlayerShowConst.NOTHING)
-- 	end
-- 	return {formationLen=formationLen,monsterList=monsterList}
-- end
-- function UIAdjstFonPop:GetCombatTypeDataHighStageRace()
-- 	local combatType = self._combatType
-- 	local monsterEffectId
-- 	local highInfo = gModelHighStageRace:GetCrossGradingHighInfo()
-- 	local lvl = highInfo.level
-- 	lvl = (not lvl or lvl == 0) and 1 or lvl
-- 	local intervalCfg = gModelHighStageRace:GetConfigByTypeAndKey(ModelHighStageRace.Interval,lvl)
-- 	local monsterListArr = string.split(intervalCfg.monster,"|")
-- 	local monsterListIndex = highInfo.voteType == 1 and 2 or 1
-- 	local monsterArr = string.split(monsterListArr[monsterListIndex],",")
-- 	local formationLen,monsterList = 0,{}
-- 	local gridMax = LCombatFormationConst.GRID_MAX
-- 	for i, v in ipairs(monsterArr) do
-- 		local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(tonumber(v))
-- 		if not monsterFormationRef then
-- 			LogError(string.format("nil MonsterFormationRef refId  %s",tonumber(v)))
-- 			return
-- 		end
-- 		local data = {}
-- 		local monsterDataList = {}
-- 		for j = 1, gridMax do
-- 			local monsterId = monsterFormationRef["monster"..j]
-- 			if monsterId > 0 then
-- 				local monsterAttrRef = gModelHero:GetMonsterAttrByRefId(monsterId)
-- 				local monsterData = {
-- 					refId = monsterAttrRef.effectId,
-- 					star = monsterAttrRef.starLv,
-- 					level = monsterAttrRef.lv,
-- 				}
-- 				if not monsterEffectId then
-- 					monsterEffectId = monsterAttrRef.effectId
-- 				end
-- 				table.insert(monsterDataList,monsterData)
-- 			end
-- 		end
-- 		data.monsterData = monsterDataList
-- 		if #monsterDataList <= 0 then
-- 			break
-- 		end
-- 		-- local treasureList = monsterFormationRef.treasureList
-- 		local skillDataList = {}
-- 		-- if not string.isempty(treasureList) then
-- 		-- 	local strArr = string.split(treasureList,"|")
-- 		-- 	for j, k in ipairs(strArr) do
-- 		-- 		local isPositive,skillId = gModelTreasure:IsPositiveSkill(tonumber(k))
-- 		-- 		if isPositive then
-- 		-- 			local ref = gModelTreasure:GetSkillInfo(skillId)
-- 		-- 			table.insert(skillDataList,ref.refId)
-- 		-- 		end
-- 		-- 	end
-- 		-- end
-- 		data.skillData = skillDataList
-- 		table.insert(monsterList,data)
-- 	end
-- 	formationLen = #monsterList
-- 	local effRef = gModelHero:GetShowEffectById(monsterEffectId)
-- 	local title
-- 	if(combatType == LCombatTypeConst.COMBAT_TYPE_36)then
-- 		local showMonsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(monsterArr[1])
-- 		title = ccLngText(showMonsterFormationRef.name)
-- 	else
-- 		title = self:GetWndArg("targetName")
-- 	end
-- 	local data = {
-- 		formationLen = formationLen,
-- 		monsterList = monsterList,
-- 		--monsterHead = effRef.icon,
-- 		monsterHead = intervalCfg.monsterIcon,
-- 		monsterName = title
-- 	}
-- 	return data
-- end

function UIAdjstFonPop:GetBossTowerCombatTypeData(...)
	-- local bossId = self._bossId
	-- if not bossId then return end
	-- local combatType = self._combatType
	-- local isBossTower = self._isBossTower
	-- if not isBossTower then return end
	-- local monsterEffectId
	-- local formationLen,monsterList = 0,{}
	-- local monster = gModelBossTower:GetBossTowerCombatMonsterListByRefId(bossId,combatType)
	-- for i,monsterId in ipairs(monster) do
	-- 	if monsterId > 0 then
	-- 		local data = {}
	-- 		local monsterDataList = {}
	-- 		local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(monsterId)
	-- 		local monsterFormationList = gModelHero:GetMonsterList(monsterId)
	-- 		for idx,monsterRefId in ipairs(monsterFormationList) do
	-- 			local monsterAttrRef = gModelHero:GetMonsterAttrByRefId(monsterRefId)
	-- 			local monsterData = {
	-- 				quality = monsterAttrRef.quality,
	-- 				raceType = monsterAttrRef.raceType,
	-- 				refId = monsterAttrRef.effectId,
	-- 				effectId = monsterAttrRef.effectId,
	-- 				star = monsterAttrRef.starLv,
	-- 				level = monsterAttrRef.lv,
	-- 				isMon = true,
	-- 			}
	-- 			if not monsterEffectId then
	-- 				monsterEffectId = monsterAttrRef.effectId
	-- 			end
	-- 			table.insert(monsterDataList,monsterData)
	-- 		end
	-- 		data.monsterData = monsterDataList
	-- 		if #monsterDataList <= 0 then
	-- 			break
	-- 		end
	-- 		-- local treasureList = monsterFormationRef.treasureList
	-- 		local skillDataList = {}
	-- 		-- if not string.isempty(treasureList) then
	-- 		-- 	local strArr = string.split(treasureList,"|")
	-- 		-- 	for j, k in ipairs(strArr) do
	-- 		-- 		local isPositive,skillId = gModelTreasure:IsPositiveSkill(tonumber(k))
	-- 		-- 		if isPositive then
	-- 		-- 			local ref = gModelTreasure:GetSkillInfo(skillId)
	-- 		-- 			table.insert(skillDataList,ref.refId)
	-- 		-- 		end
	-- 		-- 	end
	-- 		-- end
	-- 		data.skillData = skillDataList
	-- 		table.insert(monsterList,data)
	-- 	end
	-- end
	-- formationLen = #monsterList
	-- local effRef = gModelHero:GetShowEffectById(monsterEffectId)
	-- local title = gModelBossTower:GetBossTowerBossNameByRefIdAndCombatType(bossId,combatType)
	-- local data = {
	-- 	formationLen = formationLen,
	-- 	monsterList = monsterList,
	-- 	monsterHead = effRef.icon,
	-- 	monsterName = title
	-- }
	return {}
end


function UIAdjstFonPop:InitCommand()
	self:SetWndText(self.mLblBiaoti,ccClientText(22315))
	self:SetWndText(self.mDesText,ccClientText(22316))

	local combatType = self:GetWndArg("combatType")
    local fomationList = self:GetWndArg("fomationList")
	self._bossId = self:GetWndArg("bossId")
	self._sid = self:GetWndArg("sid")
	local formationLen,monsterList,monsterHead,monsterName = 0,{}

	-- local isBossTower = gModelBossTower:IsBossTowerCombat(combatType)
	self._isBossTower = false

	self._combatType = combatType
	local func = self._getMonstorDataByCombatTypeFunc[combatType]
	if func then
		local _data = func(combatType)
		if _data then
			formationLen,monsterList,monsterHead,monsterName = _data.formationLen,_data.monsterList,_data.monsterHead,_data.monsterName
		end
	end

	local combatData={}
	combatData.combatType=combatType
	monsterName = gModelBattle:GetOtherName(combatData)
	if formationLen <= 0 then
		LogError(string.format("combatType : 	%s 	nil data",combatType))
		return
	end
	self._formationLen = formationLen
    self._monsterList = monsterList
    self._fomationList = fomationList

    self:GetFomationListByCombatType()
	self:InitPlayerList()
	-- if(combatType == LCombatTypeConst.COMBAT_TYPE_37)then
	-- 	self:InitEmenyPlayerList()
	-- else
		self:InitMonsterList()
	-- end

	if monsterHead then
		self:SetWndEasyImage(self.mMonsterHead,monsterHead)
	end
	if monsterName then
		self:SetWndText(self.mMonsterNameText,monsterName)
	end
	local playerInfo = {
		trans = self.mHeadIcon,
		icon = gModelPlayer:GetPlayerHead(),
		headFrame = gModelPlayer:GetPlayerHeadFrame(),
		level = gModelPlayer:GetPlayerLv(),
	}
	local baseClass = HeadIcon:New(self)
	baseClass:SetHeadData(playerInfo)
	baseClass:RefreshUI()
	local playerName = gModelPlayer:GetPlayerName()
	self:SetWndText(self.mPlayerNameText,playerName)

	self:InitDragList()
end

function UIAdjstFonPop:InitPlayerList()
	local _playerList = self._playerList
	local _formationLen = self._formationLen or 0
	local _playerTrList = self._playerTrList or {}
	if not _playerList then
		return
	end
	for i = 1, 5 do
		local isShow = i <= _formationLen
		local tr = _playerTrList[i]
		if not tr then
			break
		end
		CS.ShowObject(tr,isShow)
		self:RefreshTeam(tr,_playerList[i],i,"hero")
	end
end
function UIAdjstFonPop:OnSwap(oldIndex, newIndex)
	--local _playerList = self._playerList
	--local oldItem = _playerList[oldIndex]
	--local newItem = _playerList[newIndex]
	--_playerList[oldIndex] = newItem
	--_playerList[newIndex] = oldItem
	--self._playerList = _playerList

	--local _playerTrList = self._playerTrList
	--local oldItem = _playerTrList[oldIndex]
	--local newItem = _playerTrList[newIndex]
	--_playerTrList[oldIndex] = newItem
	--_playerTrList[newIndex] = oldItem
	--self._playerTrList = _playerTrList
    local _indexTextList = self._indexTextList
    self:SetWndText(_indexTextList[oldIndex],self._getIVByNumFunc[newIndex])
    self:SetWndText(_indexTextList[newIndex],self._getIVByNumFunc[oldIndex])

	-- 交换节点信息
	local newTextTrans = _indexTextList[newIndex]
	local oldTextTrans = _indexTextList[oldIndex]
	_indexTextList[oldIndex] = newTextTrans
	_indexTextList[newIndex] = oldTextTrans

	--self:InitPlayerList()
    FireEvent(EventNames.ON_BATTLE_FORMATION_END,newIndex - 1,oldIndex - 1)
	--gModelFormation:OnFormationExchangeReq(combatType,newIndex,combatType,oldIndex)
end

function UIAdjstFonPop:InitMonsterList()
	local _formationLen = self._formationLen or 0
	local _monsterList = self._monsterList or {}
	local _monsterTrList = self._monsterTrList or {}

	for i = 1, 5 do
		local isShow = i <= _formationLen
		local tr = _monsterTrList[i]
		if not tr then
			break
		end
		CS.ShowObject(tr,isShow)
		self:RefreshTeam(tr,_monsterList[i],i,"monster")
	end
end
------------------------------------------------------------------
function UIAdjstFonPop:GetCombatTypeData75(...)
	local monsterEffectId
	local formationLen,monsterList = 0,{}
	local gridMax = LCombatFormationConst.GRID_MAX
	local monsterArr = gModelTower:GetTowerLayerMonstorLen(ModelTower.RACE_TYPE_99)
	for i, v in ipairs(monsterArr) do
		local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(tonumber(v))
		local data = {}
		local monsterDataList = {}
		for j = 1, gridMax do
			local monsterId = monsterFormationRef["monster"..j]
			if monsterId > 0 then
				local monsterAttrRef = gModelHero:GetMonsterAttrByRefId(monsterId)
				local monsterData = {
					refId = monsterAttrRef.effectId,
					star = monsterAttrRef.starLv,
					level = monsterAttrRef.lv,
				}
				if not monsterEffectId then
					monsterEffectId = monsterAttrRef.effectId
				end
				table.insert(monsterDataList,monsterData)
			end
		end
		data.monsterData = monsterDataList
		if #monsterDataList <= 0 then
			break
		end
		-- local treasureList = monsterFormationRef.treasureList
		local skillDataList = {}
		-- if not string.isempty(treasureList) then
		-- 	local strArr = string.split(treasureList,"|")
		-- 	for j, k in ipairs(strArr) do
		-- 		local isPositive,skillId = gModelTreasure:IsPositiveSkill(tonumber(k))
		-- 		if isPositive then
		-- 			local ref = gModelTreasure:GetSkillInfo(skillId)
		-- 			table.insert(skillDataList,ref.refId)
		-- 		end
		-- 	end
		-- end
		data.skillData = skillDataList
		table.insert(monsterList,data)
	end
	formationLen = #monsterList
	local effRef = gModelHero:GetShowEffectById(monsterEffectId)
	local title = gModelTower:GetTowerCurrNameByType(ModelTower.RACE_TYPE_99)
	local data = {
		formationLen = formationLen,
		monsterList = monsterList,
		monsterHead = effRef.icon,
		monsterName = title
	}
	return data
end
--拖动中
function UIAdjstFonPop:UIDragOnDrag(dragKey,eventData)
	if self._dragItemData and self._dragItemData.key == dragKey then
		local trans = self._dragItemData.item
		local camera = eventData.pressEventCamera
		local pos = camera:ScreenToWorldPoint(eventData.position)
		pos = trans.parent:InverseTransformPoint(pos)
		pos.y = pos.y + self._dragOffsetPosY

		local min = pos.y + self._dragItemData.minY
		local max = self._dragItemData.maxY + pos.y

		if min < self._dragOriginLimitMinY then
			pos.y = self._dragOriginLimitMinY -  self._dragItemData.minY
		elseif max > self._dragOriginLimitMaxY then
			pos.y = self._dragOriginLimitMaxY -  self._dragItemData.maxY
		end

		local transPos = trans.localPosition
		local curPos = Vector3.New(transPos.x,pos.y,transPos.z)
		trans.localPosition = curPos
		self:CheckDragItemSwap(self._dragItemData, curPos)
	end
end

function UIAdjstFonPop:InitEvent()
	self._playerTrList = self:GetTrList(self.mPlayerMar)
	self._monsterTrList = self:GetTrList(self.mMonsterMar)
	self._getMonstorDataByCombatTypeFunc = {
		[LCombatTypeConst.COMBAT_TYPE_75] = function (...) return self:GetCombatTypeData75(...) end,
		[LCombatTypeConst.COMBAT_TYPE_30] = function (...) return self:GetCombatTypeDataMainLine(...) end,
		[LCombatTypeConst.COMBAT_TYPE_31] = function (...) return self:GetCombatTypeDataMainLine(...) end,
		-- [LCombatTypeConst.COMBAT_TYPE_36] = function (...) return self:GetCombatTypeDataHighStageRace(...) end, --移除高阶段位赛
		-- [LCombatTypeConst.COMBAT_TYPE_37] = function (...) return self:GetCombatTypeDataHighStageRace37(...) end,
	}
	-- local towerBossFightType = gModelBossTower:GetBossTowerConfigRefByKey("towerBossFightType")
	-- self._getMonstorDataByCombatTypeFunc[towerBossFightType] = function(...) return self:GetBossTowerCombatTypeData(...) end

	-- local towerFightType = gModelBossTower:GetBossTowerConfigRefByKey("towerFightType")
	-- self._getMonstorDataByCombatTypeFunc[towerFightType] = function(...) return self:GetBossTowerCombatTypeData(...) end

	self._getIVByNumFunc = {
		[1] = "trial1_num_1",
		[2] = "trial1_num_2",
		[3] = "trial1_num_3",
		[4] = "trial1_num_4",
		[5] = "trial1_num_5",
	}




	self:SetWndClick(self.mBtnClose,function() self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
	self:SetWndClick(self.mBgImage,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
end

function UIAdjstFonPop:SkillListItem(list, item, itemdata, itempos)
	if not itemdata then
		return
	end
	local icon = self:FindWndTrans(item,"Icon")
	CS.ShowObject(icon,itemdata > 0)
	if itemdata <= 0 then
		return
	end
	local ref = GameTable.DraconicRef[itemdata]
	if ref then
		self:SetWndEasyImage(icon,ref.skillIcon)
	end
	icon.localScale = Vector3.one * 0.9
end

function UIAdjstFonPop:InitHero(root,key,herodata)
	local baseClass = self._commonIconList[key]
	if not baseClass then
		baseClass = CommonIcon:New()
		self._commonIconList[key] = baseClass
		baseClass:Create(root)
	end
	-- local isMon = herodata.isMon
	-- if self._isBossTower and isMon then
	-- 	local effRef = gModelHero:GetShowEffectById(herodata.refId)
	-- 	local qualityRef = gModelItem:GetQualityRef(herodata.quality)
	-- 	local raceRef = gModelHero:GetHeroRaceRefByRefId(herodata.raceType)
	-- 	local heroShowInfo = {
	-- 		iconPath = effRef and effRef.icon,
	-- 		iconBgPath = qualityRef and qualityRef.iconBg,
	-- 		raceImg = raceRef and raceRef.icon,
	-- 		star = herodata.star,
	-- 		lv = herodata.level,
	-- 	}
	-- 	baseClass:SetHeroOnlyShow(heroShowInfo)
	-- else
		baseClass:SetHeroDataSet(herodata)
	-- end
	baseClass:DoApply()
end
--结束拖动
function UIAdjstFonPop:UIDragOnEnd(dragKey, eventData)
	if self._dragItemData and self._dragItemData.key == dragKey then
		local dragItemData = self._dragItemData
		local item = dragItemData.item
		local tween = dragItemData.tween
		if tween then
			tween:Kill(false)
		end
		local originPos = self._dragOriginPos[dragItemData.index]
		tween = item:DOLocalMoveY(originPos.y, 0.15)
		tween:OnComplete(function()
			local dragItemData = self._dragItemDataList[dragKey]
			if dragItemData then
				dragItemData.tween = nil
			end
		end)
		dragItemData.tween = tween
		tween:PlayForward()
	end
	self._dragItemData = nil
end

function UIAdjstFonPop:RefreshTeam(item,itemData,itemPos,key)
	local indexText = self:FindWndTrans(item,"Image/IndexText")
	local IndexNum = self:FindWndTrans(item,"Image/IndexNum")
	local heroList = self:FindWndTrans(item,"Image/HeroList")
	local skillList = self:FindWndTrans(item,"Image/SkillList")
	local tipsText = self:FindWndTrans(item,"TipsText")

    if key == "hero" and not self._indexTextList[itemPos] then
        self._indexTextList[itemPos] = indexText
        --self:SetWndText(indexText,self._getIVByNumFunc[itemPos])
    end

	self:SetWndEasyImage(IndexNum,self._getIVByNumFunc[itemPos],nil,true)

	local mRefId = 0
	if itemData then
		if itemData.monsterData[1]then
			mRefId = itemData.monsterData[1].refId
		end
	end
	local isHaveData = itemData	 and mRefId > 0		--是否有数据
	CS.ShowObject(heroList,isHaveData)
	CS.ShowObject(skillList,isHaveData)
	CS.ShowObject(tipsText,not isHaveData)
    self:SetWndText(tipsText,ccClientText(22317))
	if not isHaveData then
		return
	end
	local monsterData = itemData.monsterData or {}
	local skillData = itemData.skillData or {}
	local len = #monsterData
	local sLen = #skillData
	if len < 5 then
		for i = len + 1, 5 do
			table.insert(monsterData,{refId = 0})
		end
	end
	if sLen < 4 then
		for i = sLen + 1, 4 do
			table.insert(skillData,0)
		end
	end

	local uiHeroList = self:GetUIScroll(key.."heroUIList"..itemPos)
	local uiSkillList = self:GetUIScroll(key.."skillUIList"..itemPos)
	if uiHeroList:GetList() then
		uiHeroList:RefreshList(monsterData)
	else
		uiHeroList:Create(heroList,monsterData,function (...) self:HeroListItem(...) end)
	end
	if uiSkillList:GetList() then
		uiSkillList:RefreshList(skillData)
	else
		uiSkillList:Create(skillList,skillData,function (...) self:SkillListItem(...) end)
	end
end

function UIAdjstFonPop:GetTrList(marRoot)
	local teamList = self:FindWndTrans(marRoot,"TeamList")
	local list = {}
	for i = 1, 5 do
		local tr = self:FindWndTrans(teamList,"Team"..i)
		if tr then
			CS.ShowObject(tr,false)
			table.insert(list,tr)
		end
	end
	return list
end

function UIAdjstFonPop:GetFomationListByCombatType()
    local combatType = self._combatType
    local formationLen = self._formationLen
    local fomationList = self._fomationList
	-- local isBossTower = self._isBossTower
    local _playerList = {}
    if fomationList then
        for i = 0, formationLen - 1 do
            local monsterData = {}
            local skillData = {}
            local formatData = fomationList[i]
            if formatData then
                local grids = formatData.indexToId
                local treasureSkilIds = formatData.treasureIdList
				for j, k in pairs(grids) do
					local id =  k
					local data
					-- if isBossTower then
					-- 	id = tonumber(id)
					-- 	local ref = gModelBossTower:GetBossTowerHeroRefByRefId(id)
					-- 	local serverData = gModelBossTower:GetBossTowerHeroDataByKeyAndRefId(self._sid,id)
					-- 	local type = ref.type
					-- 	data = {
					-- 		id = type,
					-- 		refId = type,
					-- 		star = gModelBossTower:GetHeroStarByRefId(id),
					-- 		level = serverData and serverData.breakLv or 1,
					-- 	}
					-- else
						local heroData = gModelHero:GetHeroById(id)
						data = {
							id = id,
							refId = heroData._refId,
							star = heroData._star,
							level = heroData._level,
						}
					-- end
					table.insert(monsterData,data)
				end
                for j, k in ipairs(treasureSkilIds) do
                    if k > 0 then
                        --local suitRef = GameTable.TreasureSuitRankRef[k]
                        --table.insert(skillData,suitRef.type)
						local upRef = GameTable.DraconicSuitRankRef[k]
						local ref = GameTable.DraconicRef[upRef.type]
						table.insert(skillData,upRef.type)
                    end
                end
            end
            local data = {
                monsterData = monsterData,
                skillData = skillData,
            }
            table.insert(_playerList,data)
        end
        self._playerList = _playerList
        return
    end

    local formationList = gModelFormation:GetFormationList(combatType)
    if formationList then
        for i = 0, formationLen - 1 do
            local monsterData = {}
            local skillData = {}
            local formatData = formationList[i]
            if formatData then
                local grids = formatData.grids
                local treasureSkilIds = formatData.treasureSkilIds
                for j, k in ipairs(grids) do
                    local id =  k.id
                    local heroData = gModelHero:GetHeroById(id)
                    local data = {
                        id = id,
                        refId = heroData._refId,
                        star = heroData._star,
                        level = heroData._level,
                    }
                    table.insert(monsterData,data)
                end
                for j, k in ipairs(treasureSkilIds) do
                    if k > 0 then
                        --local suitRef = GameTable.TreasureSuitRankRef[k]
                        --table.insert(skillData,suitRef.type)

						local upRef = GameTable.DraconicSuitRankRef[k]
						local ref = GameTable.DraconicRef[upRef.type]
						table.insert(skillData,upRef.type)
                    end
                end
            end
            local data = {
                monsterData = monsterData,
                skillData = skillData,
            }
            table.insert(_playerList,data)
        end
    end
    self._playerList = _playerList
end

function UIAdjstFonPop:SetEnemyHeadGroup(playerInfo)
	local playerData = {
		trans = self.mMonsterIcon,
		icon = playerInfo._head,
		headFrame = playerInfo._headFrame,
	}
	local baseClass = HeadIcon:New(self)
	baseClass:SetHeadData(playerData)
	baseClass:RefreshUI()
	local headFrameTrans = self:FindWndTrans(self.mMonsterIcon,"HeadFrame")
	self:SetWndText(self.mMonsterNameText,playerInfo._name)
	CS.ShowObject(headFrameTrans,true)
	local headIconTrans = self:FindWndTrans(self.mMonsterIcon,"IconBg/Icon")
	CS.ShowObject(headIconTrans,true)
end
function UIAdjstFonPop:GetCombatTypeDataMainLine(...)
	local _combatType = self._combatType
	local diffLvlData = nil
	if _combatType == LCombatTypeConst.COMBAT_TYPE_30 then
		diffLvlData = gModelInstance:GetBraveDiffLvlData()
	elseif _combatType == LCombatTypeConst.COMBAT_TYPE_31 then
		diffLvlData = gModelInstance:GetHeroDiffLvlData()
	end
	if not diffLvlData then return end
	local monsterEffectId
	local battleNode = diffLvlData.battleNode
	local ref = gModelInstance:GetMissionCfg(battleNode)
	if not ref then return end
	local monsterArr = LxDataHelper.ParseNumber_Sign(ref.monsterMore,',')
	local formationLen,monsterList = 0,{}
	local gridMax = LCombatFormationConst.GRID_MAX
	for i, v in ipairs(monsterArr) do
		local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(tonumber(v))
		if not monsterFormationRef then
			LogError(string.format("nil MonsterFormationRef refId  %s",tonumber(v)))
			return
		end
		local data = {}
		local monsterDataList = {}
		for j = 1, gridMax do
			local monsterId = monsterFormationRef["monster"..j]
			if monsterId > 0 then
				local monsterAttrRef = gModelHero:GetMonsterAttrByRefId(monsterId)
				local monsterData = {
					refId = monsterAttrRef.effectId,
					star = monsterAttrRef.starLv,
					level = monsterAttrRef.lv,
				}
				if not monsterEffectId then
					monsterEffectId = monsterAttrRef.effectId
				end
				table.insert(monsterDataList,monsterData)
			end
		end
		data.monsterData = monsterDataList
		if #monsterDataList <= 0 then
			break
		end
		-- local treasureList = monsterFormationRef.treasureList
		local skillDataList = {}
		-- if not string.isempty(treasureList) then
		-- 	local strArr = string.split(treasureList,"|")
		-- 	for j, k in ipairs(strArr) do
		-- 		local isPositive,skillId = gModelTreasure:IsPositiveSkill(tonumber(k))
		-- 		if isPositive then
		-- 			local ref = gModelTreasure:GetSkillInfo(skillId)
		-- 			table.insert(skillDataList,ref.refId)
		-- 		end
		-- 	end
		-- end
		data.skillData = skillDataList
		table.insert(monsterList,data)
	end
	formationLen = #monsterList
	local effRef = gModelHero:GetShowEffectById(monsterEffectId)
	local title = ccLngText(ref.nameWorld)
	local data = {
		formationLen = formationLen,
		monsterList = monsterList,
		monsterHead = effRef.icon,
		monsterName = title
	}
	return data
end

function UIAdjstFonPop:InitMessage()
	--self:WndNetMsgRecv(LProtoIds.FormationExchangeResp,function (pb)
	--	--交换成功
	--end)
	-- self:WndEventRecv(EventNames.ON_ENEMY_DATA_RET,function (pb)
	-- 	if(self._combatType == LCombatTypeConst.COMBAT_TYPE_37)then
	-- 		local playerInfo = pb.playerInfo
	-- 		self:SetEnemyHeadGroup(playerInfo)
	-- 	end
	-- end)
end
--开始拖动
function UIAdjstFonPop:UIDragOnBegin(dragKey, eventData)
	self._dragItemData = nil

	local itemData = self._dragItemDataList[dragKey]
	if self:IsItemLock(itemData.index) then
		return
	end

	local item = itemData.item
	self._dragItemData = itemData
	item:SetAsLastSibling()
	local camera = eventData.pressEventCamera
	local pos = camera:ScreenToWorldPoint(eventData.position)
	pos = item.parent:InverseTransformPoint(pos)
	self._dragOffsetPosY = item.localPosition.y - pos.y
end
------------------------------------------------------------------
return UIAdjstFonPop


