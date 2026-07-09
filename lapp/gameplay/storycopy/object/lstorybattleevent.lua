---@class LStoryBattleEvent:LStoryEventBase
local LStoryBattleEvent = LxClass("LStoryBattleEvent",LStoryEventBase)

function LStoryBattleEvent:LStoryBattleEvent()

end

function LStoryBattleEvent:OnStart()

    local cfg = self._eventCfg
    local refId = tonumber(cfg.report)

    local warReportFile = gModelBattle:GetWrReportFileByRefId(refId)
    local reportId = warReportFile
    local battleEndfun = function ()
        --todo 完成事件
        local eventCtrl = self._manager:GetEventCtrl()
        eventCtrl:ClearEvent({self._eventId})
    end
    local battleCfg = gModelBattle:GetWarReportRefByRefId(refId)
    if not battleCfg then
        printErrorN("not warreport cfg refid "..tostring(refId))
        return
    end

    local map = battleCfg.map
    local round = battleCfg.round
    local skip = battleCfg.skip
    local accelerate = battleCfg.accelerate
    local meName = ccLngText(battleCfg.myName)
    local otherName = ccLngText(battleCfg.otherName)
    local accelerateNum = battleCfg.accelerateNum
    local initSpeed = battleCfg.speed
    local hideUI = battleCfg.hideUi == 1
    local combatExtraData = {
        battleEndfun = battleEndfun,
        warReportRefId = refId,
        mapRefId = map,
        round = round,
        skip = skip,
        accelerate = accelerate,
        meName = meName,
        otherName = otherName,
        accelerateNum = accelerateNum,
        initSpeed = initSpeed,
        hideUI = hideUI,
        isNew = true,
    }
    gLFightManager:StartSimulationBattle(reportId, combatExtraData)


end

function LStoryBattleEvent:OnEnd()

end

return LStoryBattleEvent