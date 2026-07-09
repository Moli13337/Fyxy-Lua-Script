------------------------------------------------------------------
---模块使用示例 需要在LModelManager的列表里填写名字
---创建完之后可以使用gModelInvasion全局变量访问实例
------------------------------------------------------------------
local LModel = LModel
------------------------------------------------------------------
---@class ModelInvasion:LModel
local ModelInvasion = LxClass("ModelInvasion", LModel)
------------------------------------------------------------------
ModelInvasion.SerpentHuntConfigRef = "SerpentHuntConfigRef"
ModelInvasion.SerpentHuntBasicsRef = "SerpentHuntBasicsRef"
--ModelInvasion.AlienInvasionEventRef = "AlienInvasionEventRef"
--ModelInvasion.AlienInvasionTaskRef = "AlienInvasionTaskRef"
ModelInvasion.SerpentHuntBossRankRef = "SerpentHuntBossRankRef"
ModelInvasion.SerpentHuntBossRewardRef = "SerpentHuntBossRewardRef"
ModelInvasion.SerpentHuntBossRef = "SerpentHuntBossRef"
ModelInvasion.SerpentHuntBossAddRef = "SerpentHuntBossAddRef"
ModelInvasion.AlienInvasionEventGroupRef = "AlienInvasionEventGroupRef"
ModelInvasion.AlienInvasionAnimationRef = "AlienInvasionAnimationRef"

ModelInvasion.TASK_NORMAL = 1
ModelInvasion.TASK_ACTIVE = 2

ModelInvasion.EASY_BOSS = 101
ModelInvasion.HARD_BOSS = 102
ModelInvasion.TOUGH_BOSS = 103
ModelInvasion.NORMAL_BOX = 201
ModelInvasion.RARE_BOX = 202
ModelInvasion.LEGEND_BOX = 203

LXImport("..Struct.StructInvasionMap")
LXImport("..Struct.StructInvasionBoss")
LXImport("..Struct.StructPositionInfo")

function ModelInvasion:ModelInvasion()

end

function ModelInvasion:OnModelInit()

    self._timerKey = "_timerKey"

    self._parseFunc = {
        ["taskAddAttr"] = function(value)
            return LxDataHelper.ParseItemByKeyList(value, { "refId", "numType", "value" })
        end,

        ["reward"] = function(value)
            return LxDataHelper.ParseItem(value)
        end,

        ["boxRefreshItem"] = function(value)
            return LxDataHelper.ParseItemByKeyList(value, { "itemType", "itemId", "itemNum" }, "|")
        end,

        ["battleRefreshItem"] = function(value)
            return LxDataHelper.ParseItemByKeyList(value, { "itemType", "itemId", "itemNum" }, "|")
        end,
        ["bossShowReward"] = function(value)
            return LxDataHelper.ParseItem(value)
        end,
        ["showSkill"] = function(value)
            return LxDataHelper.ParseNumber_Sign(value, ",")
        end,
        ["animationSkill"] = function(value)
            return LxDataHelper.ParseNumber_Sign(value, ",")
        end,

        ["rank"] = function(value)
            return LxDataHelper.ParseNumber_Sign(value, ",")
        end,
        ["evenIcon"] = function(value)
            local strs = string.split(value, ";")
            local dataList = {}
            for k, v in ipairs(strs) do
                local temps = string.split(v, '=')
                local type = tonumber(temps[1])
                local icon = temps[2]
                if type then
                    dataList[type] = { icon = icon }
                end
            end
            return dataList
        end,
        ["otherIcon"] = function(value)
            local strs = string.split(value, ";")
            local dataList = {}
            for k, v in ipairs(strs) do
                local temps = string.split(v, '=')
                local type = tonumber(temps[1])
                local icon = temps[2]
                local offset = LxDataHelper.ParseVector(temps[3])
                if type then
                    dataList[type] = { icon = icon, offset = offset }
                end
            end
            return dataList
        end,
        ["buffIcon"] = function(value)
            local str = string.split(value, ";")
            local dataList = {}
            for k, v in ipairs(str) do
                local temps = string.split(v, '=')
                local id = tonumber(temps[1])
                local icon = temps[2]
                if id then
                    dataList[id] = icon
                end
            end
            return dataList
        end
    }

    self._eventBigType = {
        [ModelInvasion.EASY_BOSS] = 1,
        [ModelInvasion.HARD_BOSS] = 1,
        [ModelInvasion.TOUGH_BOSS] = 1,
        [ModelInvasion.NORMAL_BOX] = 2,
        [ModelInvasion.RARE_BOX] = 2,
        [ModelInvasion.LEGEND_BOX] = 2,
    }

    self:ModelNetMsgRecv(LProtoIds.AlienInvasionResp, function(...)
        self:OnAlienInvasionResp(...)
    end)
    --self:ModelNetMsgRecv(LProtoIds.AlienInvasionJoinMapResp, function(...)
    --    self:OnAlienInvasionJoinMapResp(...)
    --end)
    --self:ModelNetMsgRecv(LProtoIds.AlienInvasionEventOpsResp, function(...)
    --    self:OnAlienInvasionEventOpsResp(...)
    --end)
    --self:ModelNetMsgRecv(LProtoIds.AlienInvasionAdditionResp, function(...)
    --    self:OnAlienInvasionAdditionResp(...)
    --end)
    self:ModelNetMsgRecv(LProtoIds.AlienInvasionBossResp, function(...)
        self:OnAlienInvasionBossResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.AlienInvasionHurtInfoResp, function(...)
        self:OnAlienInvasionHurtInfoResp(...)
    end)
    --self:ModelNetMsgRecv(LProtoIds.AlienInvasionPositionResp, function(...)
    --    self:OnAlienInvasionPositionResp(...)
    --end)
    self:ModelNetMsgRecv(LProtoIds.AlienInvasionSweepResp, function(...)
        self:OnAlienInvasionSweepResp(...)
    end)

    --self:ModelEventRecv(EventNames.REFRESH_FUNCTION_STATE,function ()
    --    self:InitNetData()
    --end)
end

--模块初始化入口
--注册事件监听
--注册协议监听
--预处理数据
--在协议数据处理完之后需要调用finish
function ModelInvasion:OnModelRequest()

    --if gModelFunctionOpen:CheckIsOpened(ModelFunctionOpen.INVASION) then
    --    self:OnAlienInvasionReq()
    --end

    --self:InitNetData()


    self:ModelFinish()
end

---req
function ModelInvasion:OnAlienInvasionReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.AlienInvasionReq)
    SendMessage(pb, LProtoIds.AlienInvasionReq)
end

function ModelInvasion:OnAlienInvasionJoinMapReq(refId)
    --local pb = LProtoHelper.CreateProto(LProtoIds.AlienInvasionJoinMapReq)
    --pb.refId = refId
    --SendMessage(pb, LProtoIds.AlienInvasionJoinMapReq)
end

function ModelInvasion:OnAlienInvasionEventOpsReq(data)
    --local pb = LProtoHelper.CreateProto(LProtoIds.AlienInvasionEventOpsReq)
    --pb.eventType = data.eventType
    --pb.x = data.x
    --pb.y = data.y
    --if data.moreInfo then
    --    pb.moreInfo = data.moreInfo
    --end
    --if data.reset then
    --    pb.reset = data.reset
    --end
    --
    --SendMessage(pb, LProtoIds.AlienInvasionEventOpsReq)
end

function ModelInvasion:OnAlienInvasionQuestReq(data)
    local pb = LProtoHelper.CreateProto(LProtoIds.AlienInvasionQuestReq)
    pb.type = data.type
    if data.questRefId then
        pb.questRefId = data.questRefId
    end
    SendMessage(pb, LProtoIds.AlienInvasionQuestReq)
end

function ModelInvasion:OnAlienInvasionBossReq(data)
    local pb = LProtoHelper.CreateProto(LProtoIds.AlienInvasionBossReq)
    pb.type = data.type
    if data.rewardRefId then
        pb.rewardRefId = data.rewardRefId

    end
    if data.moreInfo then
        pb.moreInfo = data.moreInfo

    end
    SendMessage(pb, LProtoIds.AlienInvasionBossReq)
end

function ModelInvasion:OnAlienInvasionPositionReq(position, mapRefId)
    --local pb = LProtoHelper.CreateProto(LProtoIds.AlienInvasionPositionReq)
    --if position then
    --    pb.position = position --string.format("%s|%s",x,y)
    --end
    --
    --if mapRefId then
    --    pb.mapRefId = mapRefId
    --end
    --
    --SendMessage(pb, LProtoIds.AlienInvasionPositionReq)
end

function ModelInvasion:OnAlienInvasionAdditionReq()
    --local pb = LProtoHelper.CreateProto(LProtoIds.AlienInvasionAdditionReq)
    --
    --SendMessage(pb, LProtoIds.AlienInvasionAdditionReq)
end

---resp
function ModelInvasion:OnAlienInvasionResp(pb)
    local oldRoundTime = self._invasionMainData and self._invasionMainData.roundEndTime
    self._invasionMainData = pb

    --self:InitInvasionMapData()

    local curRoundEndTime = self._invasionMainData.roundEndTime
    if oldRoundTime ~= curRoundEndTime then
        self:CheckRoundEnd()
    end

end

function ModelInvasion:GetCurMapId()
    local curMapId = nil
    if self._invasionMainData then
        curMapId = self._invasionMainData.mapRefId
    end

    return curMapId
end

function ModelInvasion:OnAlienInvasionJoinMapResp(pb)
    local data = self._invasionMapData
    if not data then
        data = StructInvasionMap:New()
    end
    data:CreateByPb(pb)
    self._invasionMapData = data

    FireEvent(EventNames.ON_INVASION_EVENT_UPDATE)
end

function ModelInvasion:OnAlienInvasionAdditionResp(pb)
    local attrs = {}
    for k, v in ipairs(pb.attrs) do
        attrs[v.refId] = v.value
    end

    self._attrs = attrs
end

function ModelInvasion:OnAlienInvasionBossResp(pb)
    local data = StructInvasionBoss:New()
    data:CreateByPb(pb)

    self._bossData = data

    FireEvent(EventNames.ON_ALIENINVASIONBOSS_UPDATE)
end

function ModelInvasion:OnAlienInvasionHurtInfoResp(pb)
    self._hurtInfoList = pb
end

function ModelInvasion:OnAlienInvasionEventOpsResp(pb)

end

function ModelInvasion:OnAlienInvasionPositionResp(pb)
    if not self._mapRoleDatas then
        self._mapRoleDatas = {}
    end

    local refreshType = pb.refreshType

    if refreshType == 0 or refreshType == 1 then
        for k, v in ipairs(pb.infos) do
            local data = StructPositionInfo:New()
            data:CreateByPb(v)
            self._mapRoleDatas[data.pid] = data
        end
    elseif refreshType == 2 then
        for k, v in ipairs(pb.infos) do
            self._mapRoleDatas[v.pid] = nil
        end
    end

    FireEvent(EventNames.ON_INVASION_ROLE_UPDATE)
end

function ModelInvasion:ClearOldPosition()
    self._mapRoleDatas = {}
end

function ModelInvasion:OnAlienInvasionSweepResp(pb)
    local refId = 220003
    local numStr = LUtil.NumberCoversion(pb.hurt)
    gModelBattle:OpenCommonResult({
        refId = refId,
        invasionData = pb,
        combatType = LCombatTypeConst.COMBAT_INVASION_BOSS,
        accWndType = 4,
        isFromBack = true,
        other = { numStr },
    })
end


--function ModelInvasion:InitNetData()

--if self._isDataInit then
--    return
--end
--
--if gModelFunctionOpen:CheckIsOpened(ModelFunctionOpen.INVASION) then
--    self._isDataInit = true
--    self:OnAlienInvasionReq()
--    self:OnAlienInvasionBossReq({type = 0})
--end
--end

---get
function ModelInvasion:GetMapData()
    return self._invasionMapData
end

function ModelInvasion:GetBigCircleEndTime()
    if self._invasionMainData then
        return self._invasionMainData.endTime / 1000
    end
    return 0
end

function ModelInvasion:GetBigCircleStartTime()
    if self._invasionMainData then
        return self._invasionMainData.starTime / 1000
    end
    return 0
end

function ModelInvasion:GetRoleDatas()
    return self._mapRoleDatas
end

function ModelInvasion:GetAttrsAdd()
    return self._attrs or {}
end

---get config data

function ModelInvasion:GetMapRef(refId)
    local ref = self:GetModelConfig(ModelInvasion.SerpentHuntBasicsRef)

    return ref[refId]
end

function ModelInvasion:GetMapList()
    local ref = self:GetModelConfig(ModelInvasion.SerpentHuntBasicsRef)
    return ref
end

function ModelInvasion:GetInvasionPara(key)

    local value = self:GetCacheParaValueByKey(ModelInvasion.SerpentHuntConfigRef, key)
    if value then
        return value
    end

    local ref = self:GetModelConfig(ModelInvasion.SerpentHuntConfigRef)
    value = ref[key]
    local parseFunc = self._parseFunc[key]
    if parseFunc then
        value = parseFunc(value)
        self:SetCacheParaValueByKey(ModelInvasion.SerpentHuntConfigRef, key, value)
    end
    return value
end



--function ModelInvasion:GetInvasionTaskRef(refId)
--    local ref = self:GetModelConfig(ModelInvasion.AlienInvasionTaskRef)
--    return ref[refId]
--end

function ModelInvasion:GetRefreshCost(type, curTimes)
    local key = nil
    if type == 1 then
        key = "battleRefreshItem"
    else
        key = "boxRefreshItem"
    end

    local costList = self:GetInvasionPara(key)
    local nextTime = curTimes + 1

    local cnt = #costList
    local index = nextTime > cnt and cnt or nextTime

    return costList[index]

end

function ModelInvasion:GetBossRefValueByKey(refId, key)
    return self:GetRefValueByKey(ModelInvasion.SerpentHuntBasicsRef, refId, key)
end

function ModelInvasion:GetBossEndTime()
    if self._bossData then
        return self._bossData.endTime / 1000
    end
    return 0
end

function ModelInvasion:GetNextRefresh()

    if self._invasionMainData then
        return self._invasionMainData.eventRefreshTime / 1000
    end

    return 0
end

function ModelInvasion:GetBossData()
    return self._bossData
end

function ModelInvasion:GetRankReward()
    local rank = self._bossData and self._bossData.rank or 1
    if rank < 0 then
        return {}
    end
    local refId = self:GetCurMapId()
    local list = self:GetRankRewardList(refId)
    if not list then
        return {}
    end
    local rankLimit, reward
    for k, v in ipairs(list) do
        rankLimit = self:GetRefValueByKey(ModelInvasion.SerpentHuntBossRankRef, v.refId, "rank")
        if rank >= rankLimit[1] and rank <= rankLimit[2] then
            reward = self:GetRefValueByKey(ModelInvasion.SerpentHuntBossRankRef, v.refId, "reward")
            return reward
        end
    end

    return {}
end

function ModelInvasion:GetBossRankRef(round)
    local ref = self:GetModelConfig(ModelInvasion.SerpentHuntBossRankRef)
    local list = {}
    for k, v in pairs(ref) do
        if v.round == round then
            table.insert(list, v)
        end
    end

    table.sort(list, function(a, b)
        return a.sort < b.sort
    end)

    return list
end

function ModelInvasion:GetCurRankRewardList()
    local refId = self:GetCurMapId()
    return self:GetRankRewardList(refId)
end

function ModelInvasion:GetRankRewardList(refId)
    local mapRef = self:GetMapRef(refId)
    if not mapRef then
        return
    end
    local round = mapRef.round
    local list = self:GetBossRankRef(round)
    return list
end

function ModelInvasion:GetCurBossReward()
    local refId = self:GetCurMapId()
    local mapRef = self:GetMapRef(refId)
    if not mapRef then
        return
    end
    local round = mapRef.round
    return self:GetBossRewardRef(round)
end

function ModelInvasion:GetBossRewardRef(round)

    if not self._bossRewardCacheList then
        self._bossRewardCacheList = {}
    end

    local data = self._bossRewardCacheList[round]
    if data then
        return data.singleList, data.allList
    end

    local ref = self:GetModelConfig(ModelInvasion.SerpentHuntBossRewardRef)
    local singleList = {}
    local allList = {}
    for k, v in pairs(ref) do
        if v.round == round then
            if v.type == 1 then
                table.insert(singleList, v)
            else
                table.insert(allList, v)
            end
        end
    end

    table.sort(singleList, function(a, b)
        return a.sort < b.sort
    end)

    table.sort(allList, function(a, b)
        return a.sort < b.sort
    end)

    self._bossRewardCacheList[round] = { singleList = singleList, allList = allList }

    return singleList, allList

end

function ModelInvasion:GetBossRewardShow(refId)
    return self:GetRefValueByKey(ModelInvasion.SerpentHuntBossRewardRef, refId, "reward")
end

function ModelInvasion:GetRefValueByKey(refName, refId, key)
    local parseFunc = self._parseFunc[key]

    return self:GetConfigValueImpl(refName, refId, key, parseFunc)
end

function ModelInvasion:GetBossRewardState(refId)
    local state = self._bossData and self._bossData.targetInfo[refId] or 0
    return state
end

function ModelInvasion:GetMapDetailData()
    local cnt1, cnt2 = 0, 0   ---宝箱,怪物

    local subList = {
        [1] = 0,
        [2] = 0,
        [3] = 0
    }
    local eventList = self:GetEventDataList()

    if not eventList then
        return cnt1, cnt2, subList
    end

    local eventId = nil
    local eventRef = nil
    local eventType = nil
    for k, v in ipairs(eventList) do
        if v.state == 0 then
            eventId = v.randomEventRefId
            eventRef = self:GetEventRef(eventId)
            if eventRef then
                eventType = eventRef.type
                if self:IsBoxEventType(eventType) then
                    cnt1 = cnt1 + 1
                else
                    cnt2 = cnt2 + 1
                    if eventType == ModelInvasion.EASY_BOSS then
                        subList[1] = subList[1] + 1
                    elseif eventType == ModelInvasion.HARD_BOSS then
                        subList[2] = subList[2] + 1
                    elseif eventType == ModelInvasion.TOUGH_BOSS then
                        subList[3] = subList[3] + 1
                    end
                end
            else

            end

        end
    end

    return cnt1, cnt2, subList
end

function ModelInvasion:GetBossRewardByHurt(monsterId, hurtNum)
    local round = self:GetRoundByMonsterId(monsterId)
    return self:GetAccountReward(round, hurtNum)
end

function ModelInvasion:GetAccountReward(round, hurtNum)
    local rewardList = self:GetBossRewardRef(round)
    local rewardRef = nil
    local nextRewardRef = nil
    for k, v in ipairs(rewardList) do
        nextRewardRef = v
        if tonumber(hurtNum) <= tonumber(v.needHurt) then
            break
        end
        rewardRef = v

    end

    return rewardRef, nextRewardRef
end

function ModelInvasion:GetRoundByMonsterId(monsterId)
    if not self._roundToBoss then
        self._roundToBoss = {}
    end

    local round = self._roundToBoss[monsterId]
    if round then
        return round
    end

    local bossRef = self:GetModelConfig(ModelInvasion.SerpentHuntBossRef)
    local round = 1
    for k, v in pairs(bossRef) do
        if v.monstet == monsterId then
            round = v.round
            break
        end
    end
    self._roundToBoss[monsterId] = round
    return round
end

function ModelInvasion:GetBossAddByRound(round)

    if not self._bossAddCache then
        self._bossAddCache = {}
    end

    local value = self._bossAddCache[round]
    if value then
        return value
    end

    local buffRef = self:GetModelConfig(ModelInvasion.SerpentHuntBossAddRef)
    local dataList = {}
    for k, v in pairs(buffRef) do
        if v.type == round then
            table.insert(dataList, v)
        end
    end

    table.sort(dataList, function(a, b)
        return a.level < b.level
    end)
    self._bossAddCache[round] = dataList

    return dataList
end

function ModelInvasion:GetBossBuffByHurt(bossId, hurtNum)
    local round = self:GetRoundByMonsterId(bossId)

    local bossAddList = self:GetBossAddByRound(round)

    for k, v in ipairs(bossAddList) do
        if hurtNum >= v.needHurtMin and (hurtNum < v.needHurtMax or v.needHurtMax == -1) then
            return v
        end
    end

end

function ModelInvasion:GetBossBuffIcon(bossId)
    local config = self:GetInvasionPara('buffIcon')
    local round = self:GetRoundByMonsterId(bossId)
    return config[round]
end

function ModelInvasion:FormatTargetStateList(bossRefId, allHurt, rewardMap)
    local bossRef = self:GetModelConfig(ModelInvasion.SerpentHuntBossRef)
    local round = bossRef[bossRefId].round
    local _, allList = self:GetBossRewardRef(round)
    local state = {}
    for k, v in ipairs(allList) do
        local refId = v.refId
        if rewardMap[refId] then
            state[refId] = ModelQuest.TASK_REWARDED
        elseif tonumber(v.needHurt) <= tonumber(allHurt) then
            state[refId] = ModelQuest.TASK_FINNISH
        else
            state[refId] = ModelQuest.TASK_UNFINISH
        end
    end

    return state
end

function ModelInvasion:GetEventBigType(eventType)
    return self._eventBigType[eventType]
end

function ModelInvasion:GetJumpBoss()

    if not self._invasionMapData then
        return
    end

    local list = {
        ModelInvasion.EASY_BOSS,
        ModelInvasion.HARD_BOSS,
        ModelInvasion.TOUGH_BOSS,
    }

    local totalList = {}
    for k, v in ipairs(list) do
        local eventList = self._invasionMapData:GetMonsterEventList(v)
        if eventList then
            for k1, v1 in ipairs(eventList) do
                table.insert(totalList, v1)
            end
        end

    end
    if #totalList == 0 then
        return
    end
    local index = self._monsterIndex or 0
    index = index + 1

    if index > #totalList then
        index = 1
    end

    self._monsterIndex = index

    return totalList[index]
end

function ModelInvasion:GetJumpBossDetail(eventType)
    if not self._invasionMapData then
        return
    end
    local list = self._invasionMapData:GetMonsterEventList(eventType)
    if not list or #list == 0 then
        return
    end

    if not self._detailIndexMap then
        self._detailIndexMap = {}
    end

    local index = self._detailIndexMap[eventType] or 0
    index = index + 1

    if index > #list then
        index = 1
    end
    self._detailIndexMap[eventType] = index

    return list[index]

end

function ModelInvasion:GetJumpBox()

    if not self._invasionMapData then
        return
    end
    local boxList = self._invasionMapData:GetBoxEventList()
    if not boxList or #boxList == 0 then
        return
    end

    local index = self._bosIndex
    if not index then
        index = 0
    end

    index = index + 1
    if index > #boxList then
        index = 1
    end

    self._bosIndex = index

    return boxList[index].eventData
end

function ModelInvasion:IsBoxEventType(eventType)
    return self._eventBigType[eventType] == 2
end

function ModelInvasion:GetEventDataByPos(x, y)
    if self._invasionMapData then
        return self._invasionMapData:GetEventByPos(x, y)
    end
end

function ModelInvasion:GetEventDataList()
    return self._invasionMapData and self._invasionMapData.eventInfo
end

function ModelInvasion:FormatBattleData(pb, extraData)
    local battledata = {}
    battledata.formationRefId = pb.formationRefId

    local heros = {}
    for k, v in ipairs(pb.heros) do
        local data = {
            refId = v.refId,
            id = v.id,
            level = v.level,
            star = v.star,
            fightPower = v.fightPower,
            grade = v.grade,
            skin = v.skin,
            form = v.form,
        }

        table.insert(heros, data)
    end

    battledata.bossList = heros

    local grids = {}
    for k, v in ipairs(pb.grids) do
        table.insert(grids, v)
    end
    -- local treasureIds = nil
    -- if pb.skillInfo then
    --     treasureIds = {}
    --     for k,v in ipairs(pb.skillInfo) do
    --         local data =
    --         {
    --             index = v.index,
    --             skillId = v.skillRefId,
    --         }
    --         treasureIds[data.index] =data
    --     end
    -- end


    battledata.grids = grids
    battledata.otherName = extraData.eventName
    battledata.eventName = extraData.eventName
    battledata.power = extraData.power
    battledata.x = extraData.x
    battledata.y = extraData.y
    battledata.monster = pb.monster
    -- battledata.treasureIds = treasureIds

    return battledata
end

function ModelInvasion:GetCurBossFormation()
    if not self._bossData then
        return
    end

    local mapRefId = self:GetCurMapId()
    local mapRef = self:GetMapRef(mapRefId)
    if not mapRef then
        return
    end
    local round = mapRef.round

    local ref = self:GetModelConfig(ModelInvasion.SerpentHuntBossRef)
    for k, v in pairs(ref) do
        if v.round == round then
            return v.monstet
        end
    end

end

function ModelInvasion:EnterMap(showBoss, eventData, isSweep)
    local mapId = self:GetCurMapId()
    local ref = gModelInvasion:GetMapRef(mapId)
    if not ref then
        printErrorN("no invasion ref id " .. tostring(mapId))
        return
    end
    if not self._invasionMainData then
        return
    end

    local isEnterFail = false

    if self:IsCurCircleEnd() then
        local str = ccClientText(21045)-- "本轮已结束"
        GF.ShowMessage(str)
        isEnterFail = true
    end

    if self:IsStopFightTime() then
        local str = ccClientText(21044)--"休战时间..."
        GF.ShowMessage(str)
        isEnterFail = true
    end

    if isEnterFail then
        GF.ChangeMap("LCityMap")
        GF.OpenWndBottom("UIInvoss")
        return
    end

    self:InitInvasionFormation()

    --gLGameUI:CloseAllButExcept({["UIInvoss"]= true})
    --self:InitInvasionMapData()

    --local mapName = ref.map

    GF.ChangeMap("LCityMap")
    --GF.ChangeMap("LInvasionMap",false,{mapName = mapName,eventData= eventData,showBoss = showBoss,isSweep = isSweep})

    GF.OpenWnd("UIInvoss")

    if isSweep then
        self:OnClickSweep()
    end
end

function ModelInvasion:InitInvasionFormation()
    --local formation = gModelFormation:GetFormation(LCombatTypeConst.COMBAT_INVASION)
    --if not formation then
    --    gModelFormation:OnGetFormationReq(LCombatTypeConst.COMBAT_INVASION)
    --end
    local formation = gModelFormation:GetFormation(LCombatTypeConst.COMBAT_INVASION_BOSS)
    if not formation then
        gModelFormation:OnGetFormationReq(LCombatTypeConst.COMBAT_INVASION_BOSS)
    end
end

function ModelInvasion:IsStopFightTime()
    local curTime = GetTimestamp()
    if self._invasionMainData then
        local roundStartTime = self._invasionMainData.roundStarTime / 1000
        return curTime < roundStartTime
    end

    return false
end

function ModelInvasion:IsCurCircleEnd()
    if not self._invasionMainData then
        return true
    end
    local roundEndTime = self._invasionMainData.roundEndTime / 1000
    local isEnd = GetTimestamp() > roundEndTime
    if isEnd then
        return true
    end

    local endTime = self._invasionMainData.endTime / 1000
    local isEnd = endTime < GetTimestamp()
    return isEnd
end

function ModelInvasion:GetCurInvasionRefId()
    return self:GetCurMapId()
end

function ModelInvasion:SetIsSkipBattle(isSkip, showTip)

    if isSkip then
        local canSkip = gModelBattle:CanSkip(LCombatTypeConst.COMBAT_INVASION, showTip)
        if not canSkip then
            return false
        end
    end

    self._skipBattle = isSkip
    return true
end

function ModelInvasion:GetIsSkipBattle()
    return self._skipBattle or false
end

function ModelInvasion:GetCircleEndTime()
    if self._invasionMainData then
        return self._invasionMainData.roundEndTime
    end

    return 0
end

function ModelInvasion:CheckRoundEnd()

    self:ClearOldPosition()

    local curMap = GF.GetCurMap()
    if not curMap or not curMap:IsSameMap("LInvasionMap") then
        return
    end

    local refId = 220001
    gModelGeneral:OpenUIOrdinTips({ refId = refId, func = function()


        gLGameUI:CloseAllButExcept()
        GF.ChangeMap("LCityMap")
        GF.OpenWndBottom("UIInvoss")

    end })

    return true
end

--function ModelInvasion:StopTimer()
--    if self._timer then
--        self._timer:TimerRemoveByKey(self._timerKey)
--    end
--end

function ModelInvasion:OnClickSweep(isAuto)
    if not self._bossData then
        return
    end
    local leftCnt = self._bossData.alreadyDareCount
    if leftCnt <= 0 then
        if isAuto then
            return
        end
        local str = ccClientText(21013)-- "次数不足"
        GF.ShowMessage(str)
        return
    end

    local times = self:GetFightBossTimes()
    if times <= 0 then
        local str = ccClientText(21040)-- "请先挑战BOSS"
        GF.ShowMessage(str)
        return
    end
    local refId = self:GetCurMapId()
    local mapRef = self:GetMapRef(refId)
    if not mapRef then
        return
    end
    local round = mapRef.round
    local lastHurt = self._bossData.lastHurt

    if lastHurt == 0 then
        local str = ccClientText(21040)-- "请先挑战BOSS"
        GF.ShowMessage(str)
        return
    end

    local reward = self:GetAccountReward(round, lastHurt)

    local itemList = {}
    if reward then
        itemList = self:GetRefValueByKey(ModelInvasion.SerpentHuntBossRewardRef, reward.refId, "reward")
    end

    local numStr = LUtil.NumberCoversion(self._bossData.lastHurt)

    local para = {
        refId = 220005,
        para = { numStr },
        itemList = itemList,
        func = function()
            self:OnAlienInvasionBossReq({ type = 2 })
        end
    }

    gModelGeneral:OpenUIOrdinTips(para)

end

function ModelInvasion:GetFightBossTimes()
    local maxCnt = self:GetInvasionPara("bossMaxNum")
    local alreadyCnt = maxCnt - self._bossData.alreadyDareCount
    return alreadyCnt
end

function ModelInvasion:GetEventName(eventId)
    local ref = self:GetEventRef(eventId)
    if ref then
        return ccLngText(ref.name)
    end

end

function ModelInvasion:GetMapCameraSize()
    local size = tonumber(LPlayerPrefs.invaCamSize)
    local minValue = gModelInvasion:GetInvasionPara("cameraSize")
    local maxValue = gModelInvasion:GetInvasionPara("cameraSizeMax")

    size = Mathf.Clamp(size, minValue, maxValue)
    return size
end

function ModelInvasion:GetBossExpreData(refId)

    local skillIdList = {}

    local skillDataList = gModelInvasion:GetBossRefValueByKey(refId, "animationSkill")
    for k, v in ipairs(skillDataList) do
        local isPositive = gModelSkill:IsPositionSkill(v)
        if isPositive then
            local expreId, targetNum = gModelSkill:GetExpreIdBySkill(v)
            if expreId then
                table.insert(skillIdList, { skillId = v, expreId = expreId, targetNum = targetNum })
            end

        end
    end

    return skillIdList
end

function ModelInvasion:GetIconShowInfo(type)
    local dataMap = self:GetInvasionPara("evenIcon")
    local info = dataMap[type]
    if not info then
        dataMap = self:GetInvasionPara("otherIcon")
        info = dataMap[type]
    end

    if info then
        return info.icon, info.offset
    end
end

function ModelInvasion:InitInvasionMapData()
    if not self._invasionMainData then
        return
    end

    local funcId = 18200000
    if not gModelFunctionOpen:CheckIsOpened(funcId) then
        return
    end

    local curTime = GetTimestamp()
    local endTime = self._invasionMainData.endTime / 1000
    local startTime = self._invasionMainData.starTime / 1000

    if curTime < startTime or curTime > endTime then
        return
    end

    local roundStartTime = self._invasionMainData.roundStarTime / 1000
    local roundEndTime = self._invasionMainData.roundEndTime / 1000
    if curTime < roundStartTime or curTime > roundEndTime then
        return
    end

    local curMapId = self:GetCurMapId()
    if not curMapId then
        return
    end
    local needReq = true
    if self._invasionMapData and self._invasionMapData.refId == curMapId then
        needReq = false
    end

    if needReq then
        self:OnAlienInvasionJoinMapReq(curMapId)
    end
end

function ModelInvasion:IsTipClicked()
    return self._isTipClicked
end

function ModelInvasion:SetTipClicked()
    self._isTipClicked = true
end

--清理工作
--停止计时器之类的
function ModelInvasion:OnModelClear()
    if self._timer then
        self._timer:Destroy()
        self._timer = nil
    end
end

return ModelInvasion