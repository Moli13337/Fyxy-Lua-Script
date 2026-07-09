local LModel = LModel
LXImport("..Struct.StructStrongholdInfo")
LXImport("..Struct.StructHolyBattleFightPlayer")
---@class ModelGuildHolyBattle:LModel
local ModelGuildHolyBattle = LxClass("ModelGuildHolyBattle", LModel)

--region 初始化 --------------------------------------------------------------------------------
ModelGuildHolyBattle.EventArgs = {
    ["StageDataChange"] = "StageDataChange",
    ["ChallengeDataChange"] = "ChallengeDataChange",
    ["MatchDataChange_Self"] = "MatchDataChange_Self",
    ["MatchDataChange_Match"] = "MatchDataChange_Match",
    ["BattlefieldDataChange"] = "BattlefieldDataChange",
    ["BattlefieldDataChange_Type_2"] = "BattlefieldDataChange_Type_2",
    ["BattlefieldDataChange_Type_3"] = "BattlefieldDataChange_Type_3",
    ["LogDataChange_Self"] = "LogDataChange_Self", 
    ["LogDataChange_Guild"] = "LogDataChange_Guild",
    ["StrongholdDataChange"] = "StrongholdDataChange",
    ["RankDataChange"] = "RankDataChange",
    ["TreasureDataChange"] = "TreasureDataChange",
}

function ModelGuildHolyBattle:ModelGuildBoss()

end

--模块初始化入口
--注册事件监听
--注册协议监听
--预处理数据
function ModelGuildHolyBattle:OnModelInit()
    self:ModelNetMsgRecv(LProtoIds.MatchedGroupResp, function(...)
        self:OnMatchedGroupResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.GuildBattleStageResp, function(...)
        self:OnGuildBattleStageResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.GuildBattleParticipationInfoResp, function(...)
        self:OnGuildBattleParticipationInfoResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.GuildBattleMatchResp, function(...)
        self:OnGuildBattleMatchResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.GuildBattleBattlefieldResp, function(...)
        self:OnGuildBattleBattlefieldResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.GuildBattleFightLogResp, function(...)
        self:OnGuildBattleFightLogResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.GuildBattleViewStrongholdResp, function(...)
        self:OnGuildBattleViewStrongholdResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.GuildBattlePlayerRankResp, function(...)
        self:OnGuildBattlePlayerRankResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.GuildBattleTreasureBoxResp, function(...)
        self:OnGuildBattleTreasureBoxResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.GuildBattleSweepResp, function(...)
        --扫荡的回调 数据在其他部分也会刷新  可以不处理
        self:OnGuildBattleSweepResp(...)

    end)

end

--在协议数据处理完之后需要调用finish
function ModelGuildHolyBattle:OnModelRequest()
    self:ModelFinish()
end
--endregion --------------------------------------------------------------------------------------

--region 配置表处理 --------------------------------------------------------------------------------
function ModelGuildHolyBattle:InitGuildBattleRankRewardRef()
    local list = GameTable.ClanWarRankRewardRef

    if not self._battleRankReward then
        self._battleRankReward = {}
    end

    for k, v in pairs(list) do
        if not self._battleRankReward[v.type] then
            self._battleRankReward[v.type] = {}
        end
        self._battleRankReward[v.type][v.sort] = v

    end
end

function ModelGuildHolyBattle:InitGuildBattleOutcomeRewardRef()
    local list = GameTable.ClanWarOutcomeRewardRef

    if not self._battleOutComeReward then
        self._battleOutComeReward = {}
    end

    for k, v in pairs(list) do
        if not self._battleOutComeReward[v.type] then
            self._battleOutComeReward[v.type] = {}
        end

        if not self._battleOutComeReward[v.type][v.group] then
            self._battleOutComeReward[v.type][v.group] = {}
        end

        table.insert(self._battleOutComeReward[v.type][v.group], v)
    end
    --处理排序
    for k, v in ipairs(self._battleOutComeReward) do
        for i, j in ipairs(v) do

            table.sort(j, function(a, b)
                return a.refId < b.refId
            end)
        end
    end

end

function ModelGuildHolyBattle:InitHolyBattleRobotData()
    local tempData_1 = GameTable.ClanWarConfigRef["mirroring"]
    local tempData_2 = string.split(tempData_1, ",")
    local tempData_3 = string.split(tempData_2[1], "=")
    local tempData_4 = string.split(tempData_2[2], "=")
    local tempData_5 = string.split(tempData_2[3], "=")
    local tempData_6 = string.split(tempData_2[4], "=")

    self._robot = {}
    self._robot.headIcon = tonumber(tempData_3[2])
    self._robot.lv = tonumber(tempData_4[2])
    self._robot.name = ccClientText(tonumber(tempData_5[2]))
    self._robot.image = tonumber(tempData_6[2])
end

function ModelGuildHolyBattle:InitDifficulty()
    local tempData_1 = GameTable.ClanWarConfigRef["difficulty"]
    local tempData_2 = string.split(tempData_1, ",")
    local tempData_3 = string.split(tempData_2[1], "=")
    local tempData_4 = string.split(tempData_2[2], "=")
    local tempData_5 = string.split(tempData_2[3], "=")

    self._difficulty = {}
    self._difficulty[1] = tempData_3[2]
    self._difficulty[2] = tempData_4[2]
    self._difficulty[3] = tempData_5[2]
end

function ModelGuildHolyBattle:InitGuildBattleSweetBuffRef()
    self._buffCount = #GameTable.ClanWarSweetBuffRef
end

function ModelGuildHolyBattle:InitCrossShowReward()
    local tempData_1 = GameTable.ClanWarConfigRef["showReward"]
    self._corssShowReward = LxDataHelper.ParseItem(tempData_1)
end

function ModelGuildHolyBattle:InitTreasurePreview()
    local tempData_1 = GameTable.ClanWarConfigRef["outcomeWinShowReward"]
    self._winTreasurePreview = LxDataHelper.ParseItem(tempData_1)
    tempData_1 = GameTable.ClanWarConfigRef["outcomeLoseShowReward"]
    self._loseTreasurePreview = LxDataHelper.ParseItem(tempData_1)
end
--endregion --------------------------------------------------------------------------------------

--region 协议请求 --------------------------------------------------------------------------------
--阶段请求
function ModelGuildHolyBattle:SendGuildBattleStageReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.GuildBattleStageReq)
    SendMessage(pb, LProtoIds.GuildBattleStageReq)
end

--个人参赛信息
function ModelGuildHolyBattle:SendGuildBattleParticipationInfoReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.GuildBattleParticipationInfoReq)
    SendMessage(pb, LProtoIds.GuildBattleParticipationInfoReq)
end

--公会匹配信息 请求类型（1=己方匹配信息；2=工会对战列表）
function ModelGuildHolyBattle:SendGuildBattleMatchReq(type)
    local pb = LProtoHelper.CreateProto(LProtoIds.GuildBattleMatchReq)
    pb.type = type
    SendMessage(pb, LProtoIds.GuildBattleMatchReq)
end

--战场数据 
function ModelGuildHolyBattle:SendGuildBattleBattlefieldReq()

    local pb = LProtoHelper.CreateProto(LProtoIds.GuildBattleBattlefieldReq)
    SendMessage(pb, LProtoIds.GuildBattleBattlefieldReq)
end

--战斗日志  (1=我的战报，2=团战报)
function ModelGuildHolyBattle:SendGuildBattleFightLogReq(type)
    local pb = LProtoHelper.CreateProto(LProtoIds.GuildBattleFightLogReq)
    pb.type = type
    SendMessage(pb, LProtoIds.GuildBattleFightLogReq)
end

--据点信息
function ModelGuildHolyBattle:SendGuildBattleViewStrongholdReq(playerId)
    local pb = LProtoHelper.CreateProto(LProtoIds.GuildBattleViewStrongholdReq)
    pb.playerId = playerId
    SendMessage(pb, LProtoIds.GuildBattleViewStrongholdReq)
end

--排名积分
function ModelGuildHolyBattle:SendGuildBattlePlayerRankReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.GuildBattlePlayerRankReq)
    SendMessage(pb, LProtoIds.GuildBattlePlayerRankReq)
end

--宝箱信息
function ModelGuildHolyBattle:SendGuildBattleTreasureBoxReq(type, boxIndex)
    local pb = LProtoHelper.CreateProto(LProtoIds.GuildBattleTreasureBoxReq)

    pb.type = type

    if type == 2 then
        pb.boxIndex = boxIndex
    end

    SendMessage(pb, LProtoIds.GuildBattleTreasureBoxReq)
end

--扫荡
function ModelGuildHolyBattle:SendGuildBattleSweepReq(playerId, guildId)
    local pb = LProtoHelper.CreateProto(LProtoIds.GuildBattleSweepReq)
    pb.playerId = playerId
    pb.guildId = guildId

    SendMessage(pb, LProtoIds.GuildBattleSweepReq)
end
--endregion --------------------------------------------------------------------------------------


--region 协议回调处理 --------------------------------------------------------------------------------
--分组的请求 
function ModelGuildHolyBattle:OnMatchedGroupResp(pb)
    local pbItem = nil
    for _, v in ipairs(pb.typeData) do
        if v.type == 107 then
            pbItem = v
            break
        end
    end
    if not pbItem then
        return
    end
    self._servers = {}
    self._groupReportUrl = pbItem.reportUrl
    for i, v in ipairs(pbItem.servers) do
        local info = StructServer:New()
        info:CreateByPb(v, true)
        table.insert(self._servers, info)
    end
    if not self._guildBattleGroupId then
        self._guildBattleGroupId = pbItem.groupId

    end


end

-- 阶段
function ModelGuildHolyBattle:OnGuildBattleStageResp(pb)
    self.stage = pb.stage
    self.starTime = pb.starTime
    self.stageEndTime = pb.stageEndTime
    self.isCross = pb.isCross
    self.participate = pb.participate

    FireEvent(self.EventArgs.StageDataChange)
    

end

-- 参赛信息
function ModelGuildHolyBattle:OnGuildBattleParticipationInfoResp(pb)
    self.challengeCount = pb.challengeCount
    self.score = pb.score
    self.buff = pb.buff

    FireEvent(self.EventArgs.ChallengeDataChange)
end

-- 工会匹配数据
function ModelGuildHolyBattle:OnGuildBattleMatchResp(pb)
    local type = pb.type

    if type == 1 then
        self:ParseGuildBattleMatchResp_1(pb)

        FireEvent(self.EventArgs.MatchDataChange_Self)
    elseif type == 2 then
        --2 类型 同时也刷新一次1类型的数据
        self:ParseGuildBattleMatchResp_1(pb)
        self:ParseGuildBattleMatchResp_2(pb)
        FireEvent(self.EventArgs.MatchDataChange_Match)
    end
end

--Match Type 1   
function ModelGuildHolyBattle:ParseGuildBattleMatchResp_1(pb)
    local temp_self = pb.self

    if not self._guildInfo then
        self._guildInfo = {}
    end

    if not self._guildMatchInfo then
        self._guildMatchInfo = {}
    end

    local count = 0

    if temp_self.guildA then
        local data = self:CreateGuildInfo(temp_self.guildA)
        if temp_self.guildA.guildId == 0 then
        else
            self._guildInfo[temp_self.guildA.guildId] = data
            count = count + data.starCount
        end
    end

    if temp_self.guildB then
        local data = self:CreateGuildInfo(temp_self.guildB)
        self._guildInfo[temp_self.guildB.guildId] = data
        count = count + data.starCount

        if temp_self.guildA.guildId == 0 then
        else
            local selfGuild = gModelPlayer:GetGuildId()
            local guild
            if temp_self.guildA.guildId == selfGuild then
                guild = temp_self.guildB.guildId
            else
                guild = temp_self.guildA.guildId
            end

            self._guildMatchInfo[selfGuild] = guild
        end
    else
        self._guildMatchInfo[temp_self.guildA.guildId] = 0  -- 0  表示轮空
    end

    self._guildTotalCount = count
end



--MatchType 2 
function ModelGuildHolyBattle:ParseGuildBattleMatchResp_2(pb)
    local temp_match = pb.match

    if not self._guildOtherInfo then
        self._guildOtherInfo = {}
    end

    if not self._guildOtherMatchInfo then
        self._guildOtherMatchInfo = {}
    end

    for k, v in ipairs(temp_match) do
        local matchInfo = {}
        matchInfo.guildA = 0
        matchInfo.guildB = 0
        if v.guildA then
            local data = self:CreateGuildInfo(v.guildA)
            self._guildOtherInfo[v.guildA.guildId] = data
            matchInfo.guildA = v.guildA.guildId
        end

        if v.guildB then
            local data = self:CreateGuildInfo(v.guildB)
            self._guildOtherInfo[v.guildB.guildId] = data
            matchInfo.guildB = v.guildB.guildId

        end

        table.insert(self._guildOtherMatchInfo, matchInfo)
    end
end

function ModelGuildHolyBattle:CreateGuildInfo(guild)
    local data = {}
    data.guildId = guild.guildId
    data.guildName = guild.guildName
    data.flagId = guild.flagId
    data.starCount = guild.starCount
    data.guildPower = guild.guildPower
    data.level = guild.level
    data.flagBgId = guild.flagBgId
    data.isSelf = guild.guildId == gModelPlayer:GetGuildId()
    data.serverId = guild.serverId
    data.serverName = gLGameLogin:GetServerShotNameById(guild.serverId)

    return data
end

-- 战场数据
function ModelGuildHolyBattle:OnGuildBattleBattlefieldResp(pb)

    local type = pb.type
    if type == 1 then
        self:ParseBattleBattlefieldRespType_1(pb)
        FireEvent(self.EventArgs.BattlefieldDataChange)
    elseif type == 2 then
        local changeIndex = self:ParseBattleBattlefieldRespType_2_And_3(pb.attacker, self._attackBattlefield)
        FireEvent(self.EventArgs.BattlefieldDataChange_Type_2, changeIndex)
    elseif type == 3 then
        local changeIndex = self:ParseBattleBattlefieldRespType_2_And_3(pb.defence, self._defendBattlefield)
        FireEvent(self.EventArgs.BattlefieldDataChange_Type_3, changeIndex)
    end

end

function ModelGuildHolyBattle:ParseBattleBattlefieldRespType_1(pb)
    local attacker = pb.attacker
    local defence = pb.defence

    if attacker then
        self._attackBattlefield = self:ParseAttackBattlefield(attacker)
    end

    if defence then
        self._defendBattlefield = self:ParseAttackBattlefield(defence)
    end
end

function ModelGuildHolyBattle:ParseAttackBattlefield(itemData)
    local list = {}

    for k, v in ipairs(itemData) do
        local data = StructStrongholdInfo:New()
        data:CreateByPb(v)

        table.insert(list, data)
    end

    table.sort(list, function(a, b)
        return a.refId < b.refId
    end)
    return list
end

function ModelGuildHolyBattle:ParseBattleBattlefieldRespType_2_And_3(pbdata, list)
    --遍历list 然后把对应的数据替换掉就可以了
    local changeIndex = {}

    if not list then
        return
    end

    for k, v in ipairs(list) do
        for i, j in ipairs(pbdata) do

            if v.playerId == j.playerId then
                local data = StructStrongholdInfo:New()
                data:CreateByPb(j)

                list[k] = data
                table.insert(changeIndex, k)
            end
        end
    end

    return changeIndex

end


-- 战斗日志数据
function ModelGuildHolyBattle:OnGuildBattleFightLogResp(pb)
    local type = pb.type

    if type == 1 then
        self._selfLog = self:ParseLog(pb)
        FireEvent(self.EventArgs.LogDataChange_Self)
    else
        self._guildLog = self:ParseLog(pb)
        FireEvent(self.EventArgs.LogDataChange_Guild)
    end
end

function ModelGuildHolyBattle:ParseLog(pb)
    local log = {}
    for k, v in ipairs(pb.log) do
        local data = {}
        data.reportId = v .reportId
        data.serverId = v .serverId

        local own = StructHolyBattleFightPlayer:New()
        own:CreateByPb(v.own)
        data.own = own

        local enemy = StructHolyBattleFightPlayer:New()
        enemy:CreateByPb(v.enemy)
        data.enemy = enemy

        data.win = v .win
        data.star = v .star
        data.attack = v .attack
        data.fightTime = v .fightTime

        table.insert(log, data)
    end

    table.sort(log, function(a, b)
        return a.fightTime > b.fightTime
    end)

    return log
end


-- 查看据点信息
function ModelGuildHolyBattle:OnGuildBattleViewStrongholdResp(pb)
    local info = pb.info

    local key = info.playerId
    local defence = pb.defence
    local monsterRefId = pb.monsterRefId
    local formation = pb.formation

    if not self._shrongholdInfo then
        self._shrongholdInfo = {}
    end

    local data = {}

    data.playerId = key

    data.defence = defence

    data.monsterRefId = monsterRefId

    local infodata = StructStrongholdInfo:New()
    infodata:CreateByPb(info)
    data.info = infodata

    local cHeroDataA = StructCombatHeroData:New()
    cHeroDataA:CreateByPb(formation)
    data.formation = cHeroDataA

    self._shrongholdInfo[key] = data

    FireEvent(self.EventArgs.StrongholdDataChange)
end

function ModelGuildHolyBattle:OnGuildBattlePlayerRankResp(pb)
    local _selfRank = pb.selfRank
    local selfRank = StructRankInfo:New()
    selfRank:CreateByPb(_selfRank, true)
    self._selfRank = selfRank

    if not self._guildRank then
        self._guildRank = {}
    end

    for i = 1, #pb.infos do
        local log = pb.infos[i]
        local info = StructRankInfo:New()
        info:CreateByPb(log, true)
        self._guildRank[i] = info
    end

    FireEvent(self.EventArgs.RankDataChange)
end

function ModelGuildHolyBattle:OnGuildBattleTreasureBoxResp(pb)
    local boxList = pb.boxList

    self._treasure = {}

    for k, v in ipairs(boxList) do
        local data = {}
        data.index = v.index
        data.rewardRefId = v.rewardRefId

        table.insert(self._treasure, data)
    end
    self._isWin = pb.win == 1
    FireEvent(self.EventArgs.TreasureDataChange)
end

function ModelGuildHolyBattle:OnGuildBattleSweepResp(pb)

    local sweepPbData = self:ParseSweepPb(pb)

    --构建弹窗的 rewardlist
    local tempItem = sweepPbData.info:GetThingsDetailItems()
    local itemList = {  }
    for k, v in ipairs(tempItem) do
        local tab = {
            itype = tonumber(v.serverData.itemType),
            itemId = tonumber(v.serverData.itemId),
            count = tonumber(v.serverData.itemNum),
        }
        table.insert(itemList, tab)
    end

    local beforeBufRefId = sweepPbData.beforeBufRefId
    local lastBufRefId = sweepPbData.lastBufRefId

    local para = {
        itemList = itemList,
        callBackFunc = function()
            if beforeBufRefId == lastBufRefId then
                --GF.ShowMessage("扫荡成功")
            else
                GF.OpenWnd("UIGdHoFightBfInfo", { showEffct = true })
            end

        end,
    }
    gModelWndPop:TryOpenPopWnd("UIAward", para)
    --请求排名
    self:SendGuildBattlePlayerRankReq()
end

function ModelGuildHolyBattle:ParseSweepPb(pb)
    local data = {}

    local info = StructThingsDetailInfo:New()
    info:CreateByPb(pb.rewardInfo)

    data.info = info
    data.beforeBufRefId = pb.beforeBufRefId
    data.lastBufRefId = pb.lastBufRefId

    return data
end
--endregion --------------------------------------------------------------------------------------

--region 对外接口 --------------------------------------------------------------------------------
function ModelGuildHolyBattle:CheckIsOpen(isShowTips)
    return gModelFunctionOpen:CheckIsOpened(12111000, isShowTips)
end

function ModelGuildHolyBattle:CheckIsCross()
    if self.isCross == 1 then
        return true
    else
        return false
    end
end

function ModelGuildHolyBattle:CheckGuildPartInState()
    local stage = self:GetStage()
    local participate = self.participate or 0
    --结合阶段判断
    if stage == 0 then
        return false
    end

    if stage > 0 then
        if participate == 0 then
            return false
        end
    end

    return true
end

function ModelGuildHolyBattle:CheckPlayerPartInState()
    local participate = self.participate or 0

    if participate == 0 or participate == 1 then
        return false
    elseif participate == 2 then
        return true
    end

    return false
end

--获取次轮是否为胜利
function ModelGuildHolyBattle:CheckGuildHolyIsWin()
    return self._isWin
end

--這個方法只用在戰鬥返回 值判斷階段
function ModelGuildHolyBattle:CheckIsCanBacktoBattle()
    local isCan = true

    isCan = self.stage == 3

    return isCan
end

--跨服模式开启时
function ModelGuildHolyBattle:CheckIsOpenCrossReward()
    if self:CheckCrossIsOpen() then
        return
    end

    if not self:CheckIsOpen() then
        return
    end

    if not self:CheckIsCross() then
        return
    end

    local itemReward = self:GetCrossShowReward()
    local para = {}
    para.itemReward = itemReward
    GF.OpenWnd("UIGdHoFightKfuAward", { para = para })

    self:SetOpenCrossState()
end

--是否开启
function ModelGuildHolyBattle:CheckCrossIsOpen()
    local isOpen = tonumber(LPlayerPrefs.guildHolyBattleCross)

    if isOpen == 1 then
        return true
    end

    return false
end

--判断是否在战斗状态
function ModelGuildHolyBattle:CheckIsInFight()
    if gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_TYPE_44) then
        gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TYPE_44, {})
        return true
    else
        return false
    end
end

function ModelGuildHolyBattle:GetStage()
    --（0=未开启，1=匹配，2=准备，3=战斗，4=结算）
    return self.stage or 0
end

function ModelGuildHolyBattle:GetStarTime()
    return self.starTime or 0
end

function ModelGuildHolyBattle:GetStarTimeDes()
    if self.starTime == 0 then
        return ""
    end

    local curMon = tonumber(LUtil.OSDate("%m", self.starTime))
    local curDay = tonumber(LUtil.OSDate("%d", self.starTime))

    local curHour_1 = tonumber(LUtil.OSDate("%H", self.starTime))
    local curHour_2 = tonumber(LUtil.OSDate("%M", self.starTime))
    if tonumber(curHour_2) < 10 then
        curHour_2 = "0" .. curHour_2
    end

    local curHour = curHour_1 .. ":" .. curHour_2

    local desStr = string.replace(ccClientText(44006), curMon, curDay, curHour)

    return desStr
end

function ModelGuildHolyBattle:GetStageEndTime()
    return self.stageEndTime or 0
end

function ModelGuildHolyBattle:GetStageTextStr(stage)
    local str
    if stage == 0 then
        str = ccClientText(44001)
    elseif stage == 1 then
        str = ccClientText(44002)
    elseif stage == 2 then
        str = ccClientText(44003)
    elseif stage == 3 then
        str = ccClientText(44004)
    elseif stage == 4 then
        str = ccClientText(44005)
    elseif stage == 5 then
        str = ccClientText(44060)
    end

    return str
end

function ModelGuildHolyBattle:GetPrepareShowHeroList(isSelf)
    return isSelf and self._attackBattlefield or self. _defendBattlefield
end

function ModelGuildHolyBattle:GetGuildInfo()
    return self._guildInfo
end

function ModelGuildHolyBattle:GetMatchInfo(guildId)
    return self._guildMatchInfo[guildId]
end

function ModelGuildHolyBattle:GetOtherGuildInfo(guild)
    return self._guildOtherInfo[guild]
end

function ModelGuildHolyBattle:GetOtherMatchInfo()

    return self._guildOtherMatchInfo
end

function ModelGuildHolyBattle:GetGuildTotalCount()
    return self._guildTotalCount
end

function ModelGuildHolyBattle:GetChallengeCount()
    if not self.challengeCount then
        self:SendGuildBattleParticipationInfoReq()

        return self.challengeCount or 0,false
    end 
    
    return self.challengeCount or 0,true
end

function ModelGuildHolyBattle:GetScore()
    return self.score
end

function ModelGuildHolyBattle:GetBuff()
    return self.buff
end

function ModelGuildHolyBattle:GetTotalCount()
    return GameTable.ClanWarConfigRef["count"]
end

function ModelGuildHolyBattle:GetShrongholdInfo(key)
    return self._shrongholdInfo[key]
end

function ModelGuildHolyBattle:GetShrongholdReward(refId)
    local ref = GameTable.ClanWarStrongPointRef[refId]

    if not ref then
        printInfoNR("GuildBattleStrongPointRef缺少配置" .. refId)
        return
    end
    local itemDataList = LxDataHelper.ParseItem(ref.reward) -- itemdata.items
    return itemDataList
end

function ModelGuildHolyBattle:GetRobotData()
    if not self._robot then
        self:InitHolyBattleRobotData()
    end
    return self._robot.headIcon, self._robot.lv, self._robot.name, self._robot.image
end

function ModelGuildHolyBattle:GetDifficulty(index)
    if not self._difficulty then
        self:InitDifficulty()
    end

    return self._difficulty[index]
end

function ModelGuildHolyBattle:GetStarIntegral(refId, index)
    local ref = GameTable.ClanWarStrongPointRef[refId]

    if not ref then
        printInfoNR("GuildBattleStrongPointRef缺少配置" .. refId)
        return
    end

    if index == 1 then
        return ref.oneStarIntegral
    elseif index == 2 then
        return ref.twoStarIntegral
    elseif index == 3 then
        return ref.threeStarIntegral
    end
    return 0
end

function ModelGuildHolyBattle:GetMonsterList(monsterId)
    local tList = {}
    local tMonsterRef
    local monsters = {}
    tList = gModelHero:GetMonsterList(monsterId)
    if tList and #tList > 0 then
        for idx, val in ipairs(tList) do
            tMonsterRef = GameTable.MonsterAttrRef[val]
            if tMonsterRef then
                table.insert(monsters, {
                    id = tMonsterRef.heroId,
                    --refId = tMonsterRef.refId,
                    refId = tMonsterRef.heroId,
                    star = tMonsterRef.starLv,
                    level = tMonsterRef.lv,
                    resonance = 0,
                })
            end
        end
    end

    return monsters
end

function ModelGuildHolyBattle:GetSelfRank()
    return self._selfRank
end

function ModelGuildHolyBattle:GetRank()
    return self._guildRank
end

--获取buff部分
function ModelGuildHolyBattle:GetBuffRef(refId)
    local ref = GameTable.ClanWarSweetBuffRef[refId]

    if not ref then
        printInfoNR("GuildBattleSweetBuffRef缺少配置" .. refId)
        return
    end

    return ref
end

function ModelGuildHolyBattle:GetBuffCount()
    if not self._buffCount then
        self:InitGuildBattleSweetBuffRef()
    end
    return self._buffCount
end

function ModelGuildHolyBattle:GetBuffDes(buffLv)
    local ref = self:GetBuffRef(buffLv)
    if not ref then
        return
    end

    local icon = {}
    local tempDes = ccLngText(ref.desc)
    local des = string.split(tempDes, ",")

    local tempIcon_1 = string.split(ref.icon, ",")

    for i = 1, #des do
        local tempIcon_2 = string.split(tempIcon_1[i], "=")
        table.insert(icon, tempIcon_2[2])
    end

    return des, icon
end

--获取日志
function ModelGuildHolyBattle:GetLog(isSelf)
    return isSelf and self._selfLog or self._guildLog
end

--获取排行奖励
function ModelGuildHolyBattle:GetRankReward()
    if not self._battleRankReward then
        self:InitGuildBattleRankRewardRef()
    end

    local type = 0

    if self:CheckIsCross() then
        type = 2
    else
        type = 1
    end

    return self._battleRankReward[type]
end



--获取宝箱状态和时间
function ModelGuildHolyBattle:GetTreasureInfo()
    local isCanGet, endtime = false, 0

    isCanGet = self:GetStage() >= 4

    if isCanGet then
        local nDayTime = LUtil.GetNextDayTimes(GetTimestamp(), 1)
        endtime = nDayTime - GetTimestamp()
    end

    -- 第三个参数 只有在TreasureDataChange的时候才有值
    return isCanGet, endtime, self._treasure or {}
end

--获取宝箱的预览信息  group 1 胜利  2 失败  
function ModelGuildHolyBattle:GetTreasureReward(group)
    if not self._battleOutComeReward or #self._battleOutComeReward == 0 then
        self:InitGuildBattleOutcomeRewardRef()
    end
    local type = 1

    if self:CheckIsCross() then
        type = 2
    else
        type = 1
    end

    return self._battleOutComeReward[type][group]

end

function ModelGuildHolyBattle:GetTreasurePreviewReward(group)
    if not self._previewReward then
        self._previewReward = {}
    end

    if not self._previewReward[group] then
        self._previewReward[group] = {}

        local rewardRef = self:GetTreasureReward(group)

        for k, v in ipairs(rewardRef) do

            local itemDataList = LxDataHelper.ParseItem(v.reward) -- itemdata.items

            for i, itemdata in ipairs(itemDataList) do
                table.insert(self._previewReward[group], itemdata)
            end
        end
    end

    return self._previewReward[group]
end


--直接使用refId 获取整条的配置
function ModelGuildHolyBattle:GetTreasureRefByRefId(refId)
    return GameTable.ClanWarOutcomeRewardRef[refId]
end

function ModelGuildHolyBattle:SetDefendHero()
    local teamCount = 1
    local para = {
        teamCount = teamCount,
        setTargetType = LCombatTypeConst.COMBAT_TYPE_45,
        returnFunc = function()
            local returnFunc = function()
                gLGameUI:CloseAllButExcept()
                FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON, { index = LMainBtnIndexConst.CITY })
                GF.ChangeMap("LCityMap")

                GF.OpenWnd("UIGdHoFight", { isSelf = true })
            end

            if returnFunc then
                returnFunc()
            end
        end,
        retAfterSet = teamCount <= 1
    }

    gModelFormation:OpenMultiOnlySet(para)
end

function ModelGuildHolyBattle:GetCrossShowReward()
    if not self._corssShowReward then
        self:InitCrossShowReward()
    end

    return self._corssShowReward
end

--打开跨服奖励提醒的标记
function ModelGuildHolyBattle:SetOpenCrossState()
    LPlayerPrefs.SetHolyBattleCross(1)
end

function ModelGuildHolyBattle:GetStageColor(stage)
    --（0=未开启，1=匹配，2=准备，3=战斗，4=结算，5=结束）

    local colorStr = "<color=#d2efff>%s</color>"
    if stage == 1 then
        colorStr = "<color=#5dccff>%s</color>"
    elseif stage == 2 then
        colorStr = "<color=#5dccff>%s</color>"
    elseif stage == 3 then
        colorStr = "<color=#ff7676>%s</color>"
    elseif stage == 4 then
        colorStr = "<color=#d2efff>%s</color>"
    elseif stage == 5 then
        colorStr = "<color=#d2efff>%s</color>"
    end

    return colorStr
end

function ModelGuildHolyBattle:GetWinTreasurePreviewData()
    if not self._winTreasurePreview then
        self:InitTreasurePreview()
    end

    return self._winTreasurePreview
end

function ModelGuildHolyBattle:GetLoseTreasurePreviewData()
    if not self._loseTreasurePreview then
        self:InitTreasurePreview()
    end

    return self._loseTreasurePreview
end

function ModelGuildHolyBattle:GetServers()
    return self._servers, self._guildBattleGroupId
end

--endregion --------------------------------------------------------------------------------------
--region 红点相关的逻辑 --------------------------------------------------------------------------------
--12110000  圣骑之战备战布阵
function ModelGuildHolyBattle:CheckRedPointPrepare()
    local isRed = gModelRedPoint:CheckShowRedPoint(12110000)

    return isRed
end

function ModelGuildHolyBattle:SetRedPointPrepareClick()
    gModelRedPoint:SetRedPointClicked(12110000)
end

--12110001 有战斗次数的红点
function ModelGuildHolyBattle:CheckRedPointBattle()
    local isRed = gModelRedPoint:CheckShowRedPoint(12110001)

    return isRed
end

--12110002 结算红点 --宝箱部分
function ModelGuildHolyBattle:CheckRedpointTreasure()
    local isRed = gModelRedPoint:CheckShowRedPoint(12110002)

    --if isRed then
    --    local isCanGet, _, truasure = self:GetTreasureInfo()
    --    isRed = isRed and isCanGet
    --
    --    if isRed then
    --        if truasure then
    --            isRed = #truasure > 0
    --        end
    --
    --    end
    --end

    return isRed
end


--12110003 任务部分 个人部分
function ModelGuildHolyBattle:CheckRedPointTaskSelf()
    local isRed = gModelRedPoint:CheckShowRedPoint(12110003)
    -- 服务器部分是有任务就是red 

    if isRed then
        --遍历所有的任务 确认有没有 == 1
        local taskData = gModelQuest:GetTaskList(ModelQuest.GuildHolyBattle_Self)
        isRed = false
        for k, itemdata in ipairs(taskData) do
            local state = itemdata:GetState()

            if state == 1 then
                isRed = true
                break
            end
        end
    end

    return isRed
end

--12110004 任务部分 个人部分
function ModelGuildHolyBattle:CheckRedPointTaskGuild()
    local isRed = gModelRedPoint:CheckShowRedPoint(12110004)

    if isRed then
        --遍历所有的任务 确认有没有 == 1
        local taskData = gModelQuest:GetTaskList(ModelQuest.GuildHolyBattle_Guild)
        isRed = false
        for k, itemdata in ipairs(taskData) do
            local state = itemdata:GetState()

            if state == 1 then
                isRed = true
                break
            end
        end
    end

    return isRed
end
--endregion --------------------------------------------------------------------------------------


--region 清理工作 --------------------------------------------------------------------------------
--清理工作
--停止计时器之类的
function ModelGuildHolyBattle:OnModelClear()
    local timer = self._timer
    if timer then
        timer:Destroy()
        self._timer = nil
    end
end

--endregion --------------------------------------------------------------------------------------
return ModelGuildHolyBattle