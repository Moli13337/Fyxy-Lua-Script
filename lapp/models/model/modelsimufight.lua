local LModel = LModel
------------------------------------------------------------------
---@class ModelSimuFight:LModel
local ModelSimuFight = LxClass("ModelSimuFight",LModel)

LXImport("..Struct.StructSimulateBattleInfo")
LXImport("..Struct.StructSimulateFlowerInfo")


ModelSimuFight.SimulateMatchRef = "SimulateMatchRef"
ModelSimuFight.SimulateMatchSkillRef = "SimulateMatchSkillRef"
ModelSimuFight.SimulateMatchEmoRef = "SimulateMatchEmoRef"
ModelSimuFight.SimulateMatchFlowerRef = "SimulateMatchFlowerRef"
ModelSimuFight.SimulateMatchRankRef = "SimulateMatchRankRef"
ModelSimuFight.SimulateMatchWorshipRef = "SimulateMatchWorshipRef"


ModelSimuFight.SCHEDULE_CLOSE = 0
ModelSimuFight.SCHEDULE_FINALISTS = 1
ModelSimuFight.SCHEDULE_SIGN = 2
ModelSimuFight.SCHEDULE_BREAKOUT = 3
ModelSimuFight.SCHEDULE_GROUP_INIT = 4  ---小组赛准备阶段
ModelSimuFight.SCHEDULE_GROUP_READY = 5 ---小组赛进行阶段
ModelSimuFight.SCHEDULE_GROUP_WARM_UP = 6
ModelSimuFight.SCHEDULE_GROUP_BATTLE = 7
ModelSimuFight.SCHEDULE_SHOP = 8
ModelSimuFight.SCHEDULE_END = 9
ModelSimuFight.SCHEDULE_INTERACT = 10

ModelSimuFight.GROUP_PINNACLE = 1
ModelSimuFight.GROUP_ELITE = 2

ModelSimuFight.BATTLE_NULL = 0
ModelSimuFight.BATTLE_READY = 1
ModelSimuFight.BATTLE_WARM_UP = 2
ModelSimuFight.BATTLE_BATTLE= 3


ModelSimuFight.INTERACT_NULL = 0
ModelSimuFight.INTERACT_SUPPORT = 1
ModelSimuFight.INTERACT_BATTLE = 2
ModelSimuFight.INTERACT_TRANSITION = 3

function ModelSimuFight:ModelSimuFight()

end

function ModelSimuFight:OnModelInit()
    self:ModelNetMsgRecv(LProtoIds.SimulateStateResp,function (...)
        self:OnSimulateStateResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.SimulateConfigResp,function (...)
        self:OnSimulateConfigResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.SimulateRankResp,function (...)
        self:OnSimulateRankResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.SimulateTopInfoResp,function (...)
        self:OnSimulateTopInfoResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.SimulateFlowerMessageResp,function (...)
        self:OnSimulateFlowerMessageResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.SimulateInteractiveInfoResp,function (pb)
        if pb.combatState > 0 then
            self._interactive = 1
        else
            self._interactive = 0
        end

        FireEvent(EventNames.ON_SIMULATE_INTER_OPEN)
    end)

    self:ModelEventRecv(EventNames.ON_TIME_ZERO,function ()
        self:OnSimulateStateReq()
        self:OnSimulateTopInfoReq()
    end)
end

function ModelSimuFight:OnModelRequest()

    self:OnSimulateConfigReq()
    self:OnSimulateStateReq()
    self:OnSimulateTopInfoReq()

    gModelFormation:OnGetFormationListReq({LCombatTypeConst.COMBAT_TYPE_25})

    self:ModelFinish()
end

function ModelSimuFight:OnModelClear()

end


function ModelSimuFight:GetPara(key)
    local ref = self:GetModelConfig(ModelSimuFight.SimulateMatchRef)
    return ref[key]
end


function ModelSimuFight:OnSimulateStateReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateStateReq)
    SendMessage(pb,LProtoIds.SimulateStateReq)
end

function ModelSimuFight:OnSimulateStateResp(pb)
    local oldState = self._state
    local oldCombatState = self._combatState
    local oldRound = self._round
    self._state = pb.state
    self._round = pb.round
    self._combatState = pb.combatState

    self._startTime = pb.startTime
    self._nextStageTime = pb.nextStageTime /1000
    self._endTime =tonumber(pb.endTime)/1000
    self._interactive = pb.interactive
    self._season = pb.seasonId      --当前赛季
    self._groupId = tonumber(pb.matchGroupId) --服务器所在分区

    self._hasNews = pb.wonderful == 1

    self._battleGroup = pb.battleGroup

    self._curRank = pb.rank

    local openGameGroup = {}
    for k,v in ipairs(pb.openGroup) do
        openGameGroup[v] = true
    end

    self._isLiked = pb.like == 1

    self._openGameGroup = openGameGroup

    self._shopStartTime = tonumber(pb.shopStarTime)/1000

    if oldState ~= self._state or oldCombatState ~= self._combatState or self._round ~= oldRound then
        FireEvent(EventNames.SIMULATE_STATE_CHANGE)
    end

    if oldState ~= self._state and self._state == ModelSimuFight.SCHEDULE_FINALISTS then
        self:OnSimulateConfigReq()
    end

    FireEvent(EventNames.ON_SIMULATE_INTER_OPEN)


    self:CheckPopFinalTip()

end

function ModelSimuFight:OnSimulateSignReq(group)
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateSignReq)
    pb.group = group
    SendMessage(pb,LProtoIds.SimulateSignReq)
end

function ModelSimuFight:OnSimulateSignResp()

end

function ModelSimuFight:OnSimulateCombatListReq(playerId)
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateCombatListReq)
    pb.playerId = playerId
    SendMessage(pb,LProtoIds.SimulateCombatListReq)
end

function ModelSimuFight:OnSimulateCombatListResp()

end

function ModelSimuFight:OnSimulateGroupInfoReq(type,group,round,groupType)
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateGroupInfoReq)
    pb.type = type
    pb.group = group
    pb.round = round
    pb.groupType = groupType
    SendMessage(pb,LProtoIds.SimulateGroupInfoReq)
end

function ModelSimuFight:OnSimulateGroupInfoResp()

end

function ModelSimuFight:OnSimulateGroupReq(seasonId)
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateGroupReq)
    seasonId = seasonId or self:GetCurSeason()
    if not seasonId then
        return
    end
    pb.seasonId = seasonId
    SendMessage(pb,LProtoIds.SimulateGroupReq)
end

function ModelSimuFight:OnSimulateInteractiveInfoReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateInteractiveInfoReq)
    SendMessage(pb,LProtoIds.SimulateInteractiveInfoReq)
end

function ModelSimuFight:OnSimulateInteractiveInfoResp()


end

function ModelSimuFight:OnSimulateFlowerReq(targetId,type,groupType,emoImg,battleIndex)
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateFlowerReq)
    pb.targetId = targetId
    pb.type = type
    pb.groupType = groupType or ModelSimuFight.GROUP_PINNACLE
    if emoImg then
        pb.emoImg = emoImg
    end

    if battleIndex then
        pb.battleIndex = tonumber(battleIndex)
    end

    SendMessage(pb,LProtoIds.SimulateFlowerReq)
end

function ModelSimuFight:OnSimulateConfigReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateConfigReq)
    SendMessage(pb,LProtoIds.SimulateConfigReq)
end

function ModelSimuFight:OnSimulateConfigResp(pb)

    self._worshipShowReward =LxDataHelper.ParseItem_3List(pb.worshipShowReward)
    self._playTypeReward = pb.playTypeReward
    self._rewardGroup = pb.rewardGroup
    self._signLimit =LxDataHelper.ParseIntKVList_Semicolon(pb.resonanceLevel)
    self._teamInfo =LxDataHelper.ParseIntKVList_Semicolon(pb.teamInfo)
    self._tacticalIds = LxDataHelper.ParseNumber_Sign(pb.tacticalIds,";")
    self._signRankLimit = pb.playerNum

end

function ModelSimuFight:OnSimulateLikeListReq(group)
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateLikeListReq)
    pb.group = group
    SendMessage(pb,LProtoIds.SimulateLikeListReq)
end

function ModelSimuFight:OnSimulateLikeListResp(pb)

end

function ModelSimuFight:OnSimulateFlowerMessageReq(type,groupType,page,pageSize)
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateFlowerMessageReq)
    pb.type = type
    pb.groupType = groupType
    pb.page = page
    pb.pageSize = pageSize
    SendMessage(pb,LProtoIds.SimulateFlowerMessageReq)
end

function ModelSimuFight:OnSimulateFlowerMessageResp(pb)
    local type = pb.type
    local groupType = pb.groupType


    local flowerDataList= self._flowerDataList or {}

    if pb.page == 1 then
        flowerDataList = {}
    end
    self._flowerDataList = flowerDataList

    for k,v in ipairs(pb.infos) do
        local data = StructSimulateFlowerInfo:New()
        data:CreateByPb(v)
        table.insert(flowerDataList,data)
    end

    FireEvent(EventNames.ON_FLOWER_DETAIL_RET,type,groupType)

end

function ModelSimuFight:OnSimulateRankReq(group,season,page,pageSize,groupId)
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateRankReq)
    pb.group = group
    pb.season = season
    pb.page = page
    pb.pageSize = pageSize
    pb.groupId = groupId
    SendMessage(pb,LProtoIds.SimulateRankReq)
end

function ModelSimuFight:OnSimulateRankResp(pb)
    local group = pb.group
    local season = pb.season
    local groupId = pb.groupId
    local rankDataList = self._rankDataList or {}
    if pb.page == 1 then
        rankDataList = {}
    end

    self._rankDataList = rankDataList

    for k,v in ipairs(pb.infos) do
        local data = {}
        data.rank = v.rank
        data.info = StructPlayerData:New()
        data.info:CreateByPb(v.info)

        table.insert(rankDataList,data)

    end

    self._selfRank = pb.selfRank

    local history = {}
    for k,v in ipairs(pb.history) do
        local temps = string.split(v,"_")
        local _seasonId = tonumber(temps[1])
        local _groupId = tonumber(temps[2])

        if _seasonId and _groupId then
            history[_seasonId] = _groupId
        end
    end

    self._rankHistory = history

    self._rewardMoreInfo = pb.moreInfo
    self._curRankSeason = season

    FireEvent(EventNames.ON_SIMULATE_RANK_RET,group,season,groupId)

end

function ModelSimuFight:OnSimulateTopInfoReq(groupId,seasonId)
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateTopInfoReq)
    pb.groupId = groupId or 0
    pb.seasonId = seasonId or 0
    SendMessage(pb,LProtoIds.SimulateTopInfoReq)
end

function ModelSimuFight:OnSimulateTopInfoResp(pb)
    self._isTopLike = pb.isTopLike == 1

    if pb.groupId == self._groupId and pb.seasonId == self._season then
        self._topPlayer = StructPlayerData:New()
        self._topPlayer:CreateByPb(pb.info)
    end

    FireEvent(EventNames.ON_SIMULATE_ADMIRE_RET)
end

function ModelSimuFight:OnSimulateScheduleInfoReq(groupId,type,group)
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateScheduleInfoReq)
    pb.groupId = groupId or 0
    pb.type = type or 0
    pb.group = group or 0
    SendMessage(pb,LProtoIds.SimulateScheduleInfoReq)
end

function ModelSimuFight:OnSimulateScheduleInfoResp()

end

function ModelSimuFight:OnSimulateRaceNewsReq(group)
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateRaceNewsReq)
    pb.group = group or 0
    SendMessage(pb,LProtoIds.SimulateRaceNewsReq)
end

function ModelSimuFight:OnSimulateRaceNewsResp()

end

function ModelSimuFight:OnSimulateSeasonInfoReq(seasonId)
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateSeasonInfoReq)
    pb.seasonId = seasonId or self:GetCurSeason()
    SendMessage(pb,LProtoIds.SimulateSeasonInfoReq)
end

function ModelSimuFight:OnSimulateSeasonInfoResp()

end

function ModelSimuFight:OnSimulateShowGameListReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateShowGameListReq)
    SendMessage(pb,LProtoIds.SimulateShowGameListReq)
end

function ModelSimuFight:OnSimulateShowGameListResp()

end

function ModelSimuFight:OnSimulateTopLikeReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.SimulateTopLikeReq)
    SendMessage(pb,LProtoIds.SimulateTopLikeReq)
end

function ModelSimuFight:OnSimulateTopLikeResp()
end



------------------------------------------------------------

function ModelSimuFight:GetFlowerDetailList()
    return self._flowerDataList or {}
end

function ModelSimuFight:GetRankDataList()
    return self._rankDataList or {}
end


function ModelSimuFight:FormatSchedulePlayerList(infos)
    local playerList = {}
    local playerRecord = {}
    for k=1,4 do
        local data = infos[k]
        if data then
            playerRecord[data.attack.playerId] = true
            playerRecord[data.defense.playerId] = true

            table.insert(playerList,data.attack)
            table.insert(playerList,data.defense)
        else
            table.insert(playerList,{isEmpty = true})
            table.insert(playerList,{isEmpty = true})
        end
    end

    for k= 1,4 do
        local data = infos[k]
        if self:IsBattleInfoEnd(data) then
            table.insert(playerList,data:GetWinnerPlayer())
        else
            table.insert(playerList,{isEmpty = true})
        end
    end

    for k = 5,6 do
        local data = infos[k]
        if self:IsBattleInfoEnd(data) then
            table.insert(playerList,data:GetWinnerPlayer())
        else
            table.insert(playerList,{isEmpty = true})
        end

    end

    local data = infos[7]
    if self:IsBattleInfoEnd(data) then
        table.insert(playerList,data:GetWinnerPlayer())
    else
        table.insert(playerList,{isEmpty = true})
    end
    return playerList,playerRecord
end

function ModelSimuFight:IsBattleInfoEnd(battleInfo)
    if not battleInfo then
        return false
    end

    local state = self:GetState()
    if state > battleInfo.schedule then
        return true
    end

    local curRound = self:GetRound()
    if curRound > battleInfo.round then
        return true
    end

    local combatState = self:GetCombatState()
    if combatState > ModelSimuFight.BATTLE_BATTLE then
        return true
    else
        return false
    end
end

function ModelSimuFight:FormatLineDatas(infos)
    local linesData={}
    local cnt = 7
    local result = nil

    local winnerId = {}
    for i =1,cnt do
        local data = infos[i]
        if data then
            local isEnd =self:IsBattleInfoEnd(data)
            result =isEnd and data.winner or 0

            if result == 1 then
                winnerId[i] = data.attack.playerId
            elseif result ==2 then
                winnerId[i] = data.defense.playerId
            end
            if i ==5  then
                if winnerId[1]~= data.attack.playerId then
                    result = self:ConvertResult(result)
                end
            elseif i==6 then
                if winnerId[3]~= data.attack.playerId then
                    result = self:ConvertResult(result)
                end
            elseif i==7 then
                if winnerId[5] ~=  data.attack.playerId then
                    result = self:ConvertResult(result)
                end
            end
        else
            result= 0
        end
        linesData[i]= result
    end
    return linesData
end

function ModelSimuFight:ConvertResult(result)
    if result== 1 then
        return 2
    elseif result==2 then
        return 1
    end
    return result
end

function ModelSimuFight:FormatBtnDatas(infos)
    local cnt = 7

    local t ={}
    for i=1,cnt do
        local result = infos[i]
        local data ={}
        if result then
            local isEnd =self:IsBattleInfoStart(result)
            if isEnd then
                data.isAfter = true
                data.battleInfo = result
            else
                data.isAfter = false
            end
        else
            data.isAfter = false
        end
        table.insert(t,data)
    end
    return t
end

function ModelSimuFight:IsBattleInfoStart(battleInfo)
    if not battleInfo then
        return false
    end

    local state = self:GetState()
    if state > battleInfo.schedule then
        return true
    elseif state == battleInfo.schedule then
        local curRound = self:GetRound()
        if curRound > battleInfo.round then
            return true
        elseif curRound == battleInfo.round then
            local combatState = self:GetCombatState()
            if combatState >= ModelSimuFight.BATTLE_BATTLE then
                return true
            else
                return false
            end
        else
            return false
        end
    else
        return false
    end
end

function ModelSimuFight:GetState()
    return self._state or ModelSimuFight.SCHEDULE_CLOSE
end

function ModelSimuFight:GetCombatState()
    return self._combatState or ModelSimuFight.BATTLE_NULL
end

function ModelSimuFight:GetStartTime()
    return self._startTime or 0
end

function ModelSimuFight:GetEndTime()
    return self._endTime or 0
end

function ModelSimuFight:GetNextStageTime()
    return self._nextStageTime or 0
end

function ModelSimuFight:GetRound()
    return self._round
end

function ModelSimuFight:GetBattleGroup()
    return self._battleGroup
end

function ModelSimuFight:GetTimeShowFormat()

    if self._state == ModelSimuFight.SCHEDULE_GROUP_INIT then
        local str =ccClientText(25296) --"分组阶段：%s"
        return str
    end

    if not self._combatStrs then
        self._combatStrs =
        {
            [0] = ccClientText(25204),--"准备阶段：%s"),
            [1] = ccClientText(25204),--"准备阶段：%s",
            [2] = ccClientText(25205),--"预热阶段：%s",
            [3] = ccClientText(25137),--"战斗阶段：%s",
        }
    end

    local state = self:GetCombatState()

    return self._combatStrs[state]
end

function ModelSimuFight:GetSimulateGameSkill(refId)
    local ref =  self:GetModelConfig(ModelSimuFight.SimulateMatchSkillRef)

    return ref[refId]


end

function ModelSimuFight:OpenSetFormation(callback,combatDataList,groupIndex,targetCombatType)
    gModelGeneral:RecordGameState()


    --combatDataList =
    --{
    --    [1]=
    --    {
    --        index = 1,
    --        round = 1,
    --        combatType = LCombatTypeConst.COMBAT_TYPE_25,
    --    },
    --    [2]=
    --    {
    --        index = 2,
    --        round = 2,
    --        combatType = LCombatTypeConst.COMBAT_TYPE_251,
    --    },
    --}
    --
    --groupIndex = 2

    local combatType = targetCombatType or LCombatTypeConst.COMBAT_TYPE_25

    local teamCount = self:GetTeamCnt(self._state)
    local para = {
        teamCount = teamCount,
        setTargetType = combatType,
        returnFunc = function()
            gModelGeneral:RecoverGameState()
        end,
        saveCallback = callback,
        combatDataList = combatDataList,
        groupIndex = groupIndex,
        retAfterSet = callback ~= nil,
        --isUseFirst = combatDataList ~= nil , ---客户端使用第一个阵型数据初始化其他空阵型
    }
    gModelFormation:OpenMultiOnlySet(para)
end

function ModelSimuFight:GetTeamCnt(curSchedule)

    local type = nil
    if curSchedule <= ModelSimuFight.SCHEDULE_GROUP_INIT then
        type = 1
    elseif curSchedule <= ModelSimuFight.SCHEDULE_GROUP_READY then
        type = 2
    else
        type = 3
    end

    if self._teamInfo then
        return self._teamInfo[type] or 1
    end
    return 1
end

function ModelSimuFight:GetSignLimit(type)
    if self._signLimit then
        return self._signLimit[type]
    end
end

function ModelSimuFight:GetEmoList()

    local dataList = self._emoList
    if dataList then
        return dataList
    end

    local ref = self:GetModelConfig(ModelSimuFight.SimulateMatchEmoRef)
    local dataList = {}
    for k,v in pairs(ref) do
        table.insert(dataList,v)
    end

    table.sort(dataList,function (a,b)
        return a.refId<b.refId
    end)
    self._emoList = dataList
    return dataList
end

function ModelSimuFight:GetEmoRef(refId)
    local ref = self:GetModelConfig(ModelSimuFight.SimulateMatchEmoRef)
    return ref[refId]
end

function ModelSimuFight:GetFlowerNum(type,groupType)
    local dataMap = self._flowerNumMap
    if not dataMap then
        dataMap = {}
        local ref = self:GetModelConfig(ModelSimuFight.SimulateMatchFlowerRef)
        for k,v in pairs(ref) do
            local temp = dataMap[v.type1]
            if not temp then
                temp = {}
                dataMap[v.type1] = temp
            end

            temp[v.type2] = v.value
        end
        self._flowerNumMap = dataMap

    end

    return dataMap[type][groupType]

end

function ModelSimuFight:GetMaxSeason()
    return self._season
end


function ModelSimuFight:GetRankRewardGroup()
    if not self._simulateConfig then
        return 1
    end
    return self._simulateConfig.rewardGroup
end

function ModelSimuFight:GetRankRewardList(type)
    local dataMap = self._rankRewardMap

    local limit = 1
    if self._curRankSeason == self:GetCurSeason() then
        limit = self:GetRankShowLimit()
    end


    local numList = LxDataHelper.ParseNumber_Sign(self._rewardMoreInfo,"|")
    local group = numList[1] or 1
    local groupType = numList[2] or 0
    local rank = numList[3] or -1

    if rank < limit then -- 当前赛季显示限制
        rank = -1
    end

    local curKey = string.format("%s_%s",type,group)
    if not dataMap then
        dataMap = {}
        local ref = self:GetModelConfig(ModelSimuFight.SimulateMatchRankRef)
        for k,v in pairs(ref) do
            local key = string.format("%s_%s",v.type,v.group)
            local temp = dataMap[key] or {}
            dataMap[key] = temp
            table.insert(temp,v)
        end

        for k,v in pairs(dataMap) do
            table.sort(v,function (a,b)
                return a.refId < b.refId
            end)
        end

        self._rankRewardMap = dataMap
    end

    return dataMap[curKey],groupType,rank
end

function ModelSimuFight:GetTacticalList()
    return self._tacticalIds
end

function ModelSimuFight:GetSignRankLimit()
    local limit = nil
    if self._signRankLimit then
        limit = tonumber(self._signRankLimit)
    end
    if not limit then
        limit = 1
    end
    return limit
end

function ModelSimuFight:GetPlayTypeReward()
    return self._playTypeReward
end

function ModelSimuFight:GetWorshipShowReward()
    return self._worshipShowReward
end

function ModelSimuFight:GetCurGroupId()
    return self._groupId
end

function ModelSimuFight:GetCurSeason()
    return self._season
end

function ModelSimuFight:GetWorshipText(refId)
    local ref = self:GetModelConfig(ModelSimuFight.SimulateMatchWorshipRef)
    return ref[refId]
end

function ModelSimuFight:IsInteractiveOpen()
    return self._interactive == 1
end

function ModelSimuFight:CheckIsBattleStart(battleInfo)
    local startTime = battleInfo.startTime/1000
    if startTime < GetTimestamp() then
        return true
    end
    printInfoN(string.format("report start time %s ,current time %s",startTime,GetTimestamp()))

    ---测试代码
    --return true
end

function ModelSimuFight:CheckSingleBattleIsStart(battleInfo,index)
    local teamCnt = gModelSimuFight:GetTeamCnt(battleInfo.schedule)
    local delay = math.min(teamCnt,index)
    local startTime = battleInfo.startTime /1000
    local singleStart = startTime + (delay -1) * self:GetPara("reportShow") * 60
    if singleStart < GetTimestamp() then
        return true
    end

    ---测试代码
    --return true
end

function ModelSimuFight:CheckSingleBattleIsEnd(battleInfo,index)
    local teamCnt = gModelSimuFight:GetTeamCnt(battleInfo.schedule)
    local delay = math.min(teamCnt,index)
    local startTime = battleInfo.startTime /1000
    local singleStart = startTime + delay * self:GetPara("reportShow") * 60
    if singleStart < GetTimestamp() then
        return true
    end

    ---测试代码
    --return true
end

function ModelSimuFight:GetBattleInfoState(battleInfo)
    local cnt = #battleInfo.reportId
    if cnt == 0 then
        printErrorN("reportList is empty")
        return 1 ---等待中...
    end
    
    local state = self:GetState()

    if state > battleInfo.schedule then
        return 3 ---已结束
    elseif state == battleInfo.schedule then
        local round = self:GetRound()
        if round > battleInfo.round then
            return 3
        elseif round == battleInfo.round then
            local combatState = self:GetCombatState()
            if combatState > ModelSimuFight.BATTLE_BATTLE then
                return 3
            elseif combatState == ModelSimuFight.BATTLE_BATTLE then
                return 2 ---战斗中
            end
        end
    else
        return 1
    end
end

function ModelSimuFight:GetScheduleName(schedule)
    if not self._scheduleNameMap then
        self._scheduleNameMap = {
            [1] = ccClientText(25101),--"入围赛",
            [2] = ccClientText(25102),--"报名",
            [3] = ccClientText(25103),--"突围赛",
            [4] = ccClientText(25104),--"小组赛",
            [5] = ccClientText(25104),--"小组赛",
            [6] = ccClientText(25105),--"半决赛",
            [7] = ccClientText(25106),--"总决赛",
            [8] = ccClientText(25252),--"兑换奖励",
            [10] =ccClientText(25133), --"互动赛",
        }
    end

    return self._scheduleNameMap[schedule]
end

function ModelSimuFight:GetCurScheduleName()
    local state = self._state
    if not state then
        return ""
    end

    return self:GetScheduleName(state)
end

--小组赛准备阶段
function ModelSimuFight:IsCurGroupBattleReady(battleInfo)
    local battleRound = battleInfo.round
    local state = gModelSimuFight:GetState()
    if state ~= ModelSimuFight.SCHEDULE_GROUP_READY then
        return false
    end

    local curRound = gModelSimuFight:GetRound()

    if battleRound == 1 or battleRound == 2 then
        if curRound ~= 1 then
            return false
        end
    elseif battleRound == 3 or battleRound == 4 then
        if curRound ~=3 then
            return false
        end
    elseif battleRound > 4 then
        if curRound ~=5 then
            return false
        end
    end


    local combatState = gModelSimuFight:GetCombatState()
    if combatState ~= ModelSimuFight.BATTLE_READY then
        return false
    end

    return true
end

function ModelSimuFight:GetPrepareGroupRound()
    local state = gModelSimuFight:GetState()
    if state ~= ModelSimuFight.SCHEDULE_GROUP_READY then
        return 0
    end
    local curRound = gModelSimuFight:GetRound()

    local combatState = gModelSimuFight:GetCombatState()
    if combatState ~= ModelSimuFight.BATTLE_READY then
        return 0
    else
        return curRound
    end
end

function ModelSimuFight:GetGroupRunning()
    local state = gModelSimuFight:GetState()
    if state ~= ModelSimuFight.SCHEDULE_GROUP_READY then
        return {}
    end
    local curRound = gModelSimuFight:GetRound()

    local combatState = gModelSimuFight:GetCombatState()
    if combatState > ModelSimuFight.BATTLE_READY then
        return {[curRound] = true}
    elseif combatState == ModelSimuFight.BATTLE_READY then
        if curRound == 1 then
            return {[1] = true,[2] = true}
        elseif curRound == 3 then
            return {[3] = true,[4] = true}
        elseif curRound == 5 then
            return {[5] = true,[6] = true,[7]= true}
        end
    end
    return {}
end

function ModelSimuFight:GetEnterGameGroup()
    if not self._openGameGroup then
        return 0
    end

    if self._openGameGroup[self._battleGroup] then
        return self._battleGroup
    end

    return 0
end

function ModelSimuFight:GetSelfRank()
    return self._selfRank
end

function ModelSimuFight:IsSimulateRunning()
    if not self._state then
        return
    end

    return self._state > ModelSimuFight.SCHEDULE_CLOSE and self._state < ModelSimuFight.SCHEDULE_END
end

function ModelSimuFight:CheckPopNews()

    local inGuide = gModelGuide:IsInGuide()
    if inGuide then
        return
    end

    if not self._hasNews then
        return
    end

    local timeRecord = LPlayerPrefs.simulateNewsTime
    local time = tonumber(timeRecord) or 0
    if not LUtil.IsNewDay(time,GetTimestamp()) then
        return
    end
    LPlayerPrefs.SetSimulateNewsTime(GetTimestamp())

    GF.OpenWnd("UISuNews")


end

function ModelSimuFight:FormatInteractiveText(interactiveInfo)
    local startTime = nil

    local nextTime = interactiveInfo.nextTime/1000
    local combatState = interactiveInfo.combatState
    if combatState == 1 then
        startTime = nextTime - self:GetPara("supportTime")*60
    elseif combatState == 2 then
        startTime = nextTime - self:GetPara("supportTime")*60 - self:GetPara("supportFightTime")*60
    elseif combatState == 3 then
        startTime = nextTime - self:GetPara("supportGameTime")*60
    end

    --printInfoN(string.format("interact start time %s ",startTime))
    if not startTime then
        return {}
    end

    local dataList ={}
    local str =ccClientText(25253) --"本场互动赛正式开始~"
    table.insert(dataList,{type = 1,content = str,time = startTime})
    str = ccClientText(25254) --"支持你们心目中的强者吧!"
    table.insert(dataList,{type = 1,content = str,time = startTime + 0.01})

    local time = startTime + self:GetPara("supportTime")*60 - self:GetPara("supportRemind1")*60
    if time < GetTimestamp() then
        str = string.replace(ccClientText(25255),self:GetPara("supportRemind1"))
        table.insert(dataList,{type = 1,content = str,time = time})
    end
    time = startTime + self:GetPara("supportTime")*60 - self:GetPara("supportRemind2")
    if time < GetTimestamp() then
        str = string.replace(ccClientText(25294),self:GetPara("supportRemind2"))
        table.insert(dataList,{type = 1,content = str,time = time})
    end

    if combatState == 3 then
        local state,day = self:GetInterInfoState(interactiveInfo.round)
        if state == 1 then
            str = ccClientText(25256) --"本场互动赛已结束（%s分钟后进行下一场）"
            local timeLeft = (nextTime - GetTimestamp())/60
            str = string.replace(str,math.ceil(timeLeft))
            table.insert(dataList,{type = 1,content = str,time = GetTimestamp()})
        elseif state == 2 then
            str = ccClientText(25257) --"本场互动赛已结束（明天%s点进行新一轮的比赛）"
            local hour =  gModelSimuFight:GetInterStartTime(day)
            str = string.replace(str,hour)
            table.insert(dataList,{type = 1,content = str,time = GetTimestamp()})
        elseif state == 3 then
            str = ccClientText(25258) --"本场互动赛已结束"
            table.insert(dataList,{type = 1,content = str,time = GetTimestamp()})
        end

    end

    local format = ccClientText(25259) -- "%s:给%s支持，冲鸭！"

    for k,v in ipairs(interactiveInfo.textInfos) do
        local strs = string.split(v,'|')

        local data =
        {
            type = 2,
            content = string.replace(format,strs[1],strs[2]),
            time = tonumber(strs[3])/1000
        }

        table.insert(dataList,data)
    end

    table.sort(dataList,function (a,b)
        return a.time < b.time
    end)

    --for k,v in ipairs(dataList) do
    --    printInfoN(string.format("text info content %s ,time %s",v.content,v.time))
    --end

    return dataList
end

function ModelSimuFight:GetInterRoundInfo()
    if not self._interRoundInfo then
        local roundTotal1 = self:GetPara("game64ShowNum")
        local roundTotal2 = self:GetPara("game16ShowNum")
        local roundTotal3 = self:GetPara("game4ShowNum")

        local temp =  {roundTotal1,roundTotal1,roundTotal1,roundTotal2,roundTotal2,roundTotal2,roundTotal3}

        local dataList = {}
        for k,v in ipairs(temp) do
            local data = 0
            for k1 = 1,k do
                data = data + temp[k1]
            end

            dataList[k] = data
        end

        self._interRoundInfo = dataList
    end

    return self._interRoundInfo
end

function ModelSimuFight:GetInterInfoState(round)
    local info = self:GetInterRoundInfo()
    for k,v in ipairs(info) do
        if round < v then
            return 1,k
        elseif round == v then
            if k ~= #info then
                return 2,k
            else
                return 3
            end
        end
    end
end

function ModelSimuFight:GetInterStartTime(day)
    local dataList = self:GetParaConfigValueImpl(ModelSimuFight.SimulateMatchRef,"gameShowTime",function (value)
        return LxDataHelper.ParseNumber_Sign(value,";")
    end)

    return dataList[day + 1]

end

function ModelSimuFight:HasNews()
    return self._hasNews
end

function ModelSimuFight:CanAdmire()
    return self._isTopLike
end

function ModelSimuFight:IsAdmired()
    return self._isLiked
end

function ModelSimuFight:ShowServerGroup(seasonInfo,groupId)
    if not seasonInfo then
        return
    end
    local serverList = {}
    local group = groupId or gModelSimuFight:GetCurGroupId()
    for k,v in ipairs(seasonInfo.group) do
        if v.group == group then
            for k1,v1 in ipairs(v.serverId) do
                local temps = string.split(v1,"|")
                local serverId = temps[1]
                local serverName= temps[2]
                if not string.isempty(serverName) then
                    table.insert(serverList,{serverId = serverId,serverName = serverName})
                end

            end
        end
    end

    if #serverList == 0 then
        local str = ccClientText(25324) --"分组数据迷失在奥兹圣殿深处"
        GF.ShowMessage(str)
        return
    end

    table.sort(serverList,function (a,b)
        return a.serverId < b.serverId
    end)

    GF.OpenWnd("UIKfSyerGroupingPop",{wndType = 3, group = group, serverList = serverList})
end

function ModelSimuFight:GetBalanceList()
    local ref = GameTable.SimulateMatchBalanceRef
    local dataList = {}
    for k,v in pairs(ref) do
        table.insert(dataList,v)
    end

    table.sort(dataList,function (a,b)
        return a.refId < b.refId
    end)

    return dataList
end

function ModelSimuFight:GetTopPlayer()
    return self._topPlayer
end

function ModelSimuFight:GetRankHistory()
    return self._rankHistory
end

function ModelSimuFight:GetShopOpenTime()
    return self._shopStartTime or -1
end

function ModelSimuFight:GetShopEndTime()
    return self._endTime or -1
end

function ModelSimuFight:CanBuyRareGoods()

    if not self._curRank then
        return false
    end

    if self._curRank > 0 and self._curRank <= self:GetPara("specialShopReward") then
        return true
    end
end

function ModelSimuFight:GetHelpList()
    local ref = GameTable.SimulateMatchTipsRef

    local dataList = {}
    for k,v in pairs(ref) do
        table.insert(dataList,v)
    end

    table.sort(dataList,function (a,b)
        return a.refId < b.refId
    end)
    return dataList
end

function ModelSimuFight:GetGroupName(group)
    local groupameKey = group == 1 and "groupName1" or "groupName2"
    local groupName = ccLngText(self:GetPara(groupameKey))
    return groupName
end

function ModelSimuFight:IsInStage(state,combatState)
    if state ~= self._state then
        return false
    end
    if combatState ~= self._combatState then
        return false
    end

    return true
end

function ModelSimuFight:GetRankShowLimit()
    local parseFunc = function(value)
        local dataMap = {}
        local strs = string.split(value,";")
        for k,v in ipairs(strs) do
            local s,e,m1,m2 = string.find(v,"(%d+)=(%d+)")

            local data =
            {
                state = tonumber(m1),
                limit = tonumber(m2),
            }

            dataMap[data.state] = data
        end

        return dataMap
    end

    local dataMap = self:GetParaConfigValueImpl(ModelSimuFight.SimulateMatchRef,"rankFlash",parseFunc)
    if not dataMap then
        return 1
    end
    local index = 1

    local state = self._state
    if state then
        if state > ModelSimuFight.SCHEDULE_GROUP_BATTLE then
            index = 3
        elseif state > ModelSimuFight.SCHEDULE_GROUP_WARM_UP then
            index = 2
        elseif state > ModelSimuFight.SCHEDULE_GROUP_READY then
            index = 1
        else
            index = 0
        end
    end


    local data = dataMap[index]
    if data then
        return data.limit
    end

    return 1

end

function ModelSimuFight:CheckPopFinalTip()
    local needPop = true
    if self._state ~= ModelSimuFight.SCHEDULE_GROUP_BATTLE then
        needPop = false
    end

    local time = tonumber(LPlayerPrefs.simulateTipTime) or 0
    local isOtherDay = LUtil.IsNewDay(time,GetTimestamp())
    if not isOtherDay then
        needPop = false
    end

    gModelWndPop:RemovePopWnd("UISuFinalPop")

    if needPop then
        LPlayerPrefs.SetSimulateTipTime(tostring(GetTimestamp()))
        gModelWndPop:TryOpenPopWnd("UISuFinalPop")
    end
end

function ModelSimuFight:GetRoundStr(round)
    if not self._roundStrList then
        self._roundStrList =
        {
            [1] =ccClientText(25115),
            [2] =ccClientText(25116),
            [3] =ccClientText(25117),
            [4] =ccClientText(25118),
            [5] =ccClientText(25119),
            [6] =ccClientText(25120),
            [7] =ccClientText(25121),
        }
    end

    return self._roundStrList[round]
end

function ModelSimuFight:GetGroupTag(group)
    if not self._groupDataList then
        self._groupDataList =
        {
            [1] = "A",
            [2] = "B",
            [3] = "C",
            [4] = "D",
            [5] = "E",
            [6] = "F",
            [7] = "G",
            [8] = "H",
        }
    end

    return self._groupDataList[group]

end

function ModelSimuFight:GetInterFightEnd(startTime)
    if not startTime then
        return true
    end
    return startTime /1000 + self:GetPara("supportFightTime")*60
end

function ModelSimuFight:GetInterFightStart(startTime)
    return startTime /1000
end


return ModelSimuFight