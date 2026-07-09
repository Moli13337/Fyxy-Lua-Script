---
--- Created by Administrator.
--- DateTime: 2023/10/27 16:32:13
---
------------------------------------------------------------------
---数据结构数据示例
---多模块使用的数据结构应该有对应的类声明
------------------------------------------------------------------
---@class StructSimulateBattleInfo
local StructSimulateBattleInfo = LxClass("StructSimulateBattleInfo", nil)

LXImport(".StructPlayerData")
function StructSimulateBattleInfo:StructSimulateBattleInfo()

end

function StructSimulateBattleInfo:CreateByPb(pb)
    --token_variant_auto_export
    self.reportId=pb.reportId
    self.combatType=pb.combatType
    self.winner=pb.winner
    self.startTime=pb.startTime
    self.attack=pb.attack
    self.defense=pb.defense
    self.winnerNumber=pb.winnerNumber
    self.scoreA=pb.scoreA
    self.scoreB=pb.scoreB
    self.serverId=pb.serverId
    self.schedule=pb.schedule
    self.round=pb.round
    self.sort=pb.sort
    self.id=pb.id
    self.attackFlower=pb.attackFlower
    self.defenceFlower=pb.defenceFlower
    --token_variant_auto_export

    self.attack = StructPlayerData:New()
    self.attack:CreateByPb(pb.attack)
    self.defense = StructPlayerData:New()
    self.defense:CreateByPb(pb.defense)

    self._selfPos = self.attack.playerId == gModelPlayer:GetPlayerId() and 1 or 2

    local reports = {}
    for k,v in ipairs(pb.reportId) do
        table.insert(reports,v)
    end

    self.reportId = reports

    local winnerNumber = {}
    for k,v in ipairs(pb.winnerNumber) do
        table.insert(winnerNumber,v)
    end

    self.winnerNumber = winnerNumber
end


function StructSimulateBattleInfo:IsWin()
    return self.winner == self._selfPos
end

function StructSimulateBattleInfo:GetScoreChange()
    if self._selfPos == 1 then
        return self.scoreA
    else
        return self.scoreB
    end
end

function StructSimulateBattleInfo:GetOtherPlayerInfo()
    if self._selfPos == 1 then
        return self.defense
    else
        return self.attack
    end
end

function StructSimulateBattleInfo:ToJson()
    local data =
    {
        reportId  =self.reportId ,
        combatType=self.combatType,
        winner    =self.winner,
        startTime =self.startTime,
        attack    = self:ParsePlayerInfo(self.attack),
        defense     = self:ParsePlayerInfo(self.defense),
        winnerNumber=self.winnerNumber,
        scoreA      =self.scoreA,
        scoreB      =self.scoreB,
        serverId    =self.serverId,
        schedule    =self.schedule,
        round=self.round,
        sort=self.sort,
        id=self.id,
        attackFlower=self.attackFlower,
        defenceFlower=self.defenceFlower,
    }

    return JSON.encode(data)
end

function StructSimulateBattleInfo:ParsePlayerInfo(info)
    return
    {
        playerId=info.playerId,
        power=info.power,
        grade=info.grade,
        head=info.head,
        name=info.name,
        headFrame=info.headFrame,
        serverName=info.serverName,
    }
end


function StructSimulateBattleInfo:GetWinnerPlayer()
    if self.winner == 1 then
        return self.attack
    else
        return self.defense
    end
end

function StructSimulateBattleInfo:GetWinNumberShow()
    local winC = 0
    local failC = 0
    for k,v in ipairs(self.winnerNumber) do
        if v==1 then
            winC = winC + 1
        else
            failC = failC + 1
        end
    end

    return winC,failC
end

function StructSimulateBattleInfo:GetTeamWinState(index)
    return self.winnerNumber[index]
end

---轮空
function StructSimulateBattleInfo:IsEmptyReport()
    if self.attack.playerId == 0 or self.defense.playerId == 0 then
        return true
    end
end

function StructSimulateBattleInfo:GetOppositePlayer(playerId)
    if self.attack.playerId == playerId then
        return self.defense
    else
        return self.attack
    end
end

return StructSimulateBattleInfo