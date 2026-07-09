---@class LStorySpineEvent:LStoryEventBase
local LStorySpineEvent = LxClass("LStorySpineEvent",LStoryEventBase)


function LStorySpineEvent:LStorySpineEvent()

    --self._type = LStoryEventType.SPINE
end



function LStorySpineEvent:OnStart()

    local cfg = self._eventCfg
    local eventType = cfg.eventType

    self._type = eventType

    self._act = cfg.act
    self._circleType = cfg.circle
    self._isLoop = tonumber(cfg.circle) == 1
    local heroCfg = cfg.heroId
    local msg = ccLngText(cfg.text)
    self._str = LUtil.GetFaceStr(msg,24)

    local pos = cfg.actionBegin1

    local tempStrs = string.split(pos,"|")
    self._startBoard = tempStrs[1]
    self._startIndex =tonumber(tempStrs[2])

    pos = cfg.actionBegin2
    tempStrs = string.split(pos,"|")
    self._endBoard = tempStrs[1]
    self._endIndex = tempStrs[2]

    self._expressId = cfg.actEffect

    self._moveSpeed = cfg.moveSpeed*100

    if eventType == LStoryEventType.SPINE_SKILL then
        local heroIds = LxDataHelper.ParseNumber_Sign(heroCfg,'|')
        local atkId = tonumber(heroIds[1])
        local tarId = tonumber(heroIds[2])

        self._heroId = atkId
        self._tarId = tarId
    else
        self._heroId = tonumber(heroCfg)
    end

    if eventType == LStoryEventType.SPINE_BORN or eventType == LStoryEventType.SPINE_BORN_SPECIAL then
        self:Born()
    elseif eventType == LStoryEventType.SPINE_SKILL then
        self:PlaySkill()
    end

    self:AfterLoadEvent(self._heroId)

end

function LStorySpineEvent:OnEnd()
    local obj = self:GetObj()
    if self._type == LStoryEventType.SPINE_BORN or self._type == LStoryEventType.SPINE_BORN_SPECIAL then
        self:Remove()
    elseif self._type == LStoryEventType.SPINE_ACT then
        if self._circleType == 2 then
            if obj then
                obj:PlayIdleAni()
            end
        end
    elseif self._type == LStoryEventType.SPINE_TIMELINE then
        if obj then
            obj:PlayIdleAni()
        end
    elseif self._type == LStoryEventType.SPINE_MATERIAL then
        if obj then
            obj:SetDefaultMat(self._timeAfter)
        end
    elseif self._type == LStoryEventType.SPINE_MOVE then
        if obj and obj:SetStatus(LFightIdleConst.STATUS_IDLE) then
            obj:PlayIdleAni()
            self:SetStartBoard()
        end
    end
end

function LStorySpineEvent:OnRun(time)
    if self._type == LStoryEventType.SPINE_MOVE then
        self:OnMoveCheck()
    end


end

function LStorySpineEvent:OnHeroLoaded(heroId)

    self:PlaySkill()

    self:AfterLoadEvent(heroId)

end

function LStorySpineEvent:AfterLoadEvent(heroId)

    if not heroId then
        return
    end

    if self._isEventDone then
        return
    end

    if heroId~= tonumber(self._heroId) then
        return
    end

    if LOG_INFO_ENABLED then
        printInfoN(string.format("AfterLoadEvent %s",heroId))
    end
    if not self:IsObjReady(heroId) then
        if LOG_INFO_ENABLED then
            printInfoN(string.format("is not ready %s",heroId))
        end
        return
    end

    self._isEventDone = true
    local eventType = self._type
    if eventType == LStoryEventType.SPINE_MOVE then
        self:Move()
    elseif eventType == LStoryEventType.SPINE_ACT then
        self:PlayAct()
        --elseif eventType == LStoryEventType.SPINE_PATH then
        --self:Path()
    elseif eventType == LStoryEventType.SPINE_AI then
        self:AiAct()
    elseif eventType == LStoryEventType.SPINE_DEAD then
        self:Dead()
    elseif eventType == LStoryEventType.SPINE_BUBBLE then
        self:ShowBubble()
    elseif eventType == LStoryEventType.SPINE_TIMELINE then
        self:TimeLine()
    elseif eventType == LStoryEventType.SPINE_MATERIAL then
        local para = self._eventCfg.act
        local strs = string.split(para,'|')
        self._timeBefore = strs[1] and tonumber(strs[1]) or 0
        self._timeAfter = strs[2] and tonumber(strs[2]) or 0

        self:ChangeMat(self._timeBefore)

    end
end

function LStorySpineEvent:PlayAct()


    local obj = self:GetObj()
    if not string.isempty(self._act) then
        local changeDir = tonumber(self._act)
        if changeDir == 1 then
            obj:ChangeOppositeDire()
        else
            obj:PlayAni(self._act,self._isLoop)
        end
    end
end

function LStorySpineEvent:SetStartBoard()

    if not self._startBoard then
        return
    end
    local obj = self:GetObj()
    local startBoard = self._startBoard
    local startIndex = self._startIndex

    local boardRef = self._manager:GetBoardRef(startBoard)
    if not boardRef then
        printErrorN("no boardRef "..(startBoard or "nil"))
        return
    end
    local areaCtrl = self._manager:GetAreaCtrl()
    obj:SetAreaIndex(areaCtrl:GetAreaIndexByAreaId(boardRef.areaId))
    obj:SetBoardRefId(startBoard)
    obj:SetPathIndex(startIndex)
    local paths = boardRef.paths
    local pathData = paths[startIndex]
    local left = pathData.left
    local right = pathData.right
    local minPos = Vector3(left.x,left.y,left.z)
    local maxPos = Vector3(right.x,right.y,right.z)

    local pos = obj:GetPosition()
    local posX = Mathf.Clamp(pos.x,minPos.x,maxPos.x)
    local posY = Mathf.Clamp(pos.y,minPos.y,maxPos.y)

    obj:SetPosition(Vector3.New(posX,posY,pos.z))
    obj:SetPathData(minPos,maxPos)

end

function LStorySpineEvent:PathToBoard()
    if not self._endBoard then
        return
    end
    local obj = self:GetObj()
    local actionType = LFightIdleConst.ACTION_PATH
    local ai = obj:GetAI()
    ai:ChangeAction(actionType)
    local action = ai:GetAction(actionType)
    action:StartPathToBoard(self._endBoard)
end

function LStorySpineEvent:PlaySkill()

    if self._type ~= LStoryEventType.SPINE_SKILL then
        return
    end

    if self._skillUsed then
        return
    end

    if string.isempty(self._expressId) then
        return
    end

    local atkId = self._heroId
    local tarId = self._tarId


    local obj = self:GetObj(atkId)
    if not obj or not obj:IsReady() then
        return
    end

    local tarObj = self:GetObj(tarId)
    if not tarObj or not tarObj:IsReady() then
        return
    end

    obj:SetTarObjKey(tarId)

    self._skillUsed = true
    obj:UseSkill(tonumber(self._expressId))
end

function LStorySpineEvent:Move()

    local cfg = self._eventCfg

    local obj = self:GetObj()

    local time = nil

    local endPos = LxDataHelper.ParseVector(cfg.moveCoordinate)
    endPos = LUtil.ConvertPixelPosToUnitPos(endPos)

    --local timeSpan = self._endTime - self._startTime
    --if timeSpan >0 then
    --    time = timeSpan
    --else
    obj:SetMoveSpeed(self._moveSpeed)
    local startPos = obj:GetPosition()
    local distance = Vector3.Distance(startPos,endPos)
    local speed = obj:GetMoveSpeed()
    time = distance / speed*100
    --end

    if obj:SetStatus(LFightIdleConst.STATUS_MOVE) or not obj:IsRunAni() then
        obj:PlayRunAni()
    end

    obj:ChangeDirToPos(endPos)

    obj:GetMoveActor():MoveTo(endPos,time)

end

function LStorySpineEvent:OnMoveCheck()

    local isReady = self:IsObjReady()
    if not isReady then
        return
    end
    local obj = self:GetObj()

    local isMoving = obj:GetMoveActor():IsMoving()
    if isMoving then
        return
    end

    if obj:SetStatus(LFightIdleConst.STATUS_IDLE) then
        obj:PlayIdleAni()
        self:SetStartBoard()
    end
end

function LStorySpineEvent:Born()
    local objCtrl = self._manager:GetObjCtrl()
    objCtrl:MakeObject({refId = self._eventId})
end

function LStorySpineEvent:Path()
    self:SetStartBoard()
    self:PathToBoard()
end

function LStorySpineEvent:AiAct()
    local obj = self:GetObj()
    local ai = obj:GetAI()
    ai:StartAI()
end

function LStorySpineEvent:Dead()
    local obj = self:GetObj()
    obj:DoDeadCommon()
end

function LStorySpineEvent:ShowBubble()
    local obj = self:GetObj()
    local timeSpan = self._endTime - self._startTime
    obj:ShowBubbleStick(self._str,timeSpan)
end

function LStorySpineEvent:IsObjReady(heroId)
    local obj= self:GetObj(heroId)
    if not obj or not obj:IsReady() then
        return false
    end
    return true
end

function LStorySpineEvent:TimeLine()
    local obj = self:GetObj()
    local spineGo = obj:GetDisplayTrans().gameObject

    local timeLinePlayer = self._timeLinePlayer
    if not timeLinePlayer then
        timeLinePlayer = LTimeLinePlayer:New()
        self._timeLinePlayer = timeLinePlayer
    end

    local cfg = self._eventCfg
    local paras = string.split(cfg.act,"|")
    local timeLineName = paras[1]
    local direction = tonumber(paras[2]) or LFightIdleConst.DIRECTION_RIGHT

    obj:SetDirection(direction)
    obj:PlayRunAni()

    self._timeLinePlayer:PlayTimeLine(spineGo,timeLineName)
end

---@return LStoryObject
function LStorySpineEvent:GetObj(heroId)
    local tarId = heroId or self._heroId
    local objCtrl = self._manager:GetObjCtrl()
    local obj = objCtrl:GetObjByKey(tarId)
    return obj
end

function LStorySpineEvent:Remove()
    local heroId = self._heroId
    local objCtrl = self._manager:GetObjCtrl()
    objCtrl:RemoveObjectById(heroId)
end

function LStorySpineEvent:ChangeMat(fadeTime)
    local obj = self:GetObj()
    local matName = self._eventCfg.effectName
    obj:ChangeMat(matName,fadeTime)
end



return LStorySpineEvent