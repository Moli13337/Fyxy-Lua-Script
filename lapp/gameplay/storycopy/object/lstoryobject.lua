local LFightIdleObject = LXImport("LApp.gameplay.fightIdle.Object.LFightIdleObject")
local LFightIdleAI = LXImport("LApp.gameplay.fightIdle.Object.LFightIdleAI")
local LFightIdleMoveActor = LXImport("LApp.gameplay.fightIdle.Actor.LFightIdleMoveActor")
local LFightIdleAtkActor = LXImport("LApp.gameplay.fightIdle.Actor.LFightIdleAtkActor")
local LFightIdleAniActor = LXImport("LApp.gameplay.fightIdle.Actor.LFightIdleAniActor")
local LFightIdlePathActor = LXImport("LApp.gameplay.fightIdle.Actor.LFightIdlePathActor")
local LFightIdleAlphaActor = LXImport("LApp.gameplay.fightIdle.Actor.LFightIdleAlphaActor")
local LSkillData = LxRequire("LApp.Models.Data.LSkillData")
local typeSpineClick = typeof(CS.SpineClick)

---@class LStoryObject:LFightIdleObject
local LStoryObject = LxClass("LStoryObject", LFightIdleObject)



function LStoryObject:LStoryObject(manager)
    ---@type LStoryManager
    self._manager = manager
end

-----------------------------------------------------------------
function LStoryObject:Create(ctrl,eventId)
    local cfg = gModelPlot:GetStoryEventRef(eventId)
    local heroId = tonumber(cfg.heroId) --唯一id
    local hero = cfg.hero --表现id
    --local skillExpress =cfg.actEffect  --技能表现
    local faction = cfg.factions --阵营
    local side = nil
    if faction == 0 then
        side = LFightIdleConst.SIDE_A
    elseif faction== 1 then
        side = LFightIdleConst.SIDE_B
    elseif faction == 2 then
        side = LFightIdleConst.SIDE_M --npc
    end

    local scale = cfg.multiple
    self._scaleSize = scale == 0 and 1 or scale

    local heroAtk = cfg.heroAtt
    local heroBlood = cfg.heroBlood
    local act = cfg.act
    local direction = LFightIdleConst.DIRECTION_RIGHT
    if tonumber(act) == 1 then
        direction = LFightIdleConst.DIRECTION_LEFT
    else
        if not string.isempty(act) then
            self._defaultAct = act
            self._isLoop = cfg.circle == 1
        end
    end
    self._direction = direction

    self._bloodType = 2
    self._bloodMax = 1
    local strs = string.split(heroBlood,"=")
    if #strs>= 2 then
        self._bloodType = tonumber(strs[1])
        self._bloodMax = tonumber(strs[2])
    end

    self._heroExpressId = hero
    self._eventType = cfg.eventType
    self._heroAtk = heroAtk

    self._ctrl = ctrl
    self._rootTrans = self._manager:GetObjectRootTrans()
    self._objKey = heroId
    self._objType = LFightIdleConst.OBJ_HERO
    self._side = side
    self._randZ = math.random(100,999) * 0.0000001


    if not self:InitData() then return false end
    self:InitDisplay()
    self:InitActor()

    local pos = LxDataHelper.ParseVector(cfg.coordinate)
    pos = LUtil.ConvertPixelPosToUnitPos(pos)
    local moveSpeed = cfg.moveSpeed*300
    if moveSpeed == 0 then
        moveSpeed = 300
    end

    local boardCfg = cfg.actionBegin1

    local tempStrs = string.split(boardCfg,"|")
    local startBoard = tempStrs[1]
    local startIndex =tonumber(tempStrs[2])

    self:SetPosition(pos)
    self:SetMoveSpeed(moveSpeed)

    if startBoard then
        local boardRef = self._manager:GetBoardRef(startBoard)
        if boardRef then
            local areaCtrl = self._manager:GetAreaCtrl()
            self:SetAreaIndex(areaCtrl:GetAreaIndexByAreaId(boardRef.areaId))
            self:SetBoardRefId(startBoard)
            self:SetPathIndex(startIndex)
            local paths = boardRef.paths
            local pathData = paths[startIndex]
            local left = pathData.left
            local right = pathData.right
            local minPos = Vector3(left.x,left.y,left.z)
            local maxPos = Vector3(right.x,right.y,right.z)

            local pos = self:GetPosition()
            local posX = Mathf.Clamp(pos.x,minPos.x,maxPos.x)
            local posY = Mathf.Clamp(pos.y,minPos.y,maxPos.y)

            self:SetPosition(Vector3.New(posX,posY,pos.z))
            self:SetPathData(minPos,maxPos)
        else
            printErrorN("wrong boardref "..(startBoard or "nil"))
        end

    end


    return true
end

function LStoryObject:InitData()


    local refId = self._heroExpressId


    local attrData = {
        [LAttrConst.Atk] = self._heroAtk,
        [LAttrConst.MaxHP] = self._bloodMax,
    }
    self._curHp = attrData[LAttrConst.MaxHP] or 0
    self._hpMax = self._curHp
    self._attrData = attrData
    self._bInitHp = true

    local effectId = nil
    if self._eventType == LStoryEventType.SPINE_BORN then
        local monRef = gModelHero:GetMonsterAttrByRefId(refId)
        if not monRef then
            return false
        end

        effectId = monRef.effectId

        local list = {}
        local skillGroup = monRef.activeSkill
        local tempStrs = string.split(skillGroup,",")
        for k,v in ipairs(tempStrs) do
            local strs = LxDataHelper.ParseNumber_Sign(v,"=")
            if #strs>1 then
                local skillId = tonumber(strs[1])
                table.insert(list,skillId)
            end
        end

        local skillList = self:FilterActiveHurtSkill(list)
        local commonSkill = monRef.commonSkill
        if commonSkill then
            self._commonSkill = self:CreateSkillData(commonSkill, true, nil)
        end
        self._skillList = skillList or nil
    else
        -- 取消  0  1  的effid 
        local sex = gModelPlayer:GetPlayerSex()
        if sex == 1 or sex ==0  then
            effectId=tonumber(GameTable.SnakeRoleConfigRef["initShow"])
        end
    end

    local aniShowEffRef = gModelHero:GetShowEffectById(effectId)
    
    if nil == aniShowEffRef then
        --printInfoN2("cjh-----------处理 ----",effectId)
        return false 
    end 
    self._spineName = aniShowEffRef.prefabName
    self._aniShowEffectRef = aniShowEffRef

    return true
end

function LStoryObject:InitObjectAI()
    local ai = LFightIdleAI:New()
    self._ai = ai
    ai:CreateAI(self,self._manager, 1)
end

-----------------------------------------------------------------
---绑定表演
function LStoryObject:InitActor()
    self._moveActor = LFightIdleMoveActor:New(self,self._manager)
    self._atkActor = LFightIdleAtkActor:New(self,self._manager)
    self._pathActor = LFightIdlePathActor:New(self,self._manager)
    self._aniActor = LFightIdleAniActor:New(self,self._manager)
    self._alphaActor = LFightIdleAlphaActor:New(self,self._manager)
end

function LStoryObject:DoDeadNoFade()
    if self._bDestroyed then return end
    if self._bDeadEnd then return end
    if self._status == LFightIdleConst.STATUS_DEAD then return end

    self._status = LFightIdleConst.STATUS_DEAD

    self:StopActor(true)

    local deadTime = LxResPathUtil.GetSpineAniTime(self._spineName, LSpineAniConst.die, 0)
    self:PlayAni(LSpineAniConst.die)

    self:KillBirthTween()
    self:KillDeadTween()


    local tweenSeq = YXTween.TweenSequenceIns()

    tweenSeq:AppendInterval(deadTime)
    tweenSeq:InsertCallback(0.1,function ()
        if self._bloodStick then
            self._bloodStick:Destroy()
            self._bloodStick = nil
        end
    end)

    tweenSeq:OnComplete(function()
        self._deadTween = nil
        self._bDeadEnd = true
    end)
    self._manager:NotifyObjDead(self)

    self._deadTween = tweenSeq
    tweenSeq:PlayForward()
end

function LStoryObject:DoHurt(changeType,changeVal)
    local hp = self._curHp
    hp = hp + changeVal

    local bloodType = self._bloodType or 1
    if bloodType == 1 then
        local min = self._hpMax*0.05
        if hp<min then
            --todo check recover
            hp = self._hpMax
        end
    else
        if hp <= 0 then
            hp = 0
        end
    end

    if hp== 0 then
        self:DoDeadCommon()
    end

    local bChange = (hp ~= self._curHp)
    self._curHp = hp

    if bChange then
        self:ChangeBloodStick(self._curHp / self._hpMax)
        FireEvent(EventNames.ON_STORY_OBJ_HURT,self._objKey)

    end

end


function LStoryObject:DoDeadCommon()
    local bloodType = self._bloodType or 1
    if bloodType == 2 or bloodType == 4 then
        self:DoDead()
    elseif bloodType == 3 then
        self:DoDeadNoFade()
    end
end

---死亡
function LStoryObject:DoDead()
    if self._bDestroyed then return end
    if self._bDeadEnd then return end
    if self._status == LFightIdleConst.STATUS_DEAD then return end

    self._status = LFightIdleConst.STATUS_DEAD

    self:StopActor(true)

    local deadTime = LxResPathUtil.GetSpineAniTime(self._spineName, LSpineAniConst.die, 0)
    self:PlayAni(LSpineAniConst.die)

    self:KillBirthTween()
    self:KillDeadTween()


    local tweenSeq = YXTween.TweenSequenceIns()

    local showtime = 0.1

    local alphaFunc = function (value)
        self._displayObj:SetAlpha(value)
    end

    local alphaTween = YXTween.TweenFloat(1,0.5,showtime,alphaFunc):SetEase(DG.Tweening.Ease.InSine)
    local alphaTween1 = YXTween.TweenFloat(0.5,1,showtime,alphaFunc):SetEase(DG.Tweening.Ease.OutSine)
    local alphaTween2 = YXTween.TweenFloat(1,0,showtime,alphaFunc):SetEase(DG.Tweening.Ease.InSine)

    tweenSeq:AppendInterval(deadTime)
    tweenSeq:Append(alphaTween)
    tweenSeq:Append(alphaTween1)
    tweenSeq:Append(alphaTween2)

    tweenSeq:InsertCallback(0.1,function ()
        if self._bloodStick then
            self._bloodStick:SetVisible(false)
        end
    end)

    tweenSeq:OnComplete(function()
        self._deadTween = nil
        self._bDeadEnd = true

        if self._bloodType == 4 then
            self:ReBorn()
        end
    end)

    if self._bloodType ~= 4 then
        self._manager:NotifyObjDead(self)
    end
    self._deadTween = tweenSeq
    tweenSeq:PlayForward()


end



function LStoryObject:OnLoaded()
    self._displayObj:SetUseLookValid(true)
    local tran = self._displayObj:GetDisplayTrans()
    tran.localPosition = self._localPosition
    self:InitBtObjectView()

    self:CreateBloodStick()
    self:SetBloodStickShow(false)
    self:CreateHeadEffect()
    self:ShowBirth()

    tran.name = self._objKey

end

function LStoryObject:ShowBirth()
    self._status = LFightIdleConst.STATUS_BIRTH
    self:KillBirthTween()
    self._displayObj:SetAlpha(0)

    self:SetDirection(self._direction)

    local waitTime = math.random() * 0.5

    local tweenSeq = YXTween.TweenSequenceIns()

    local showtime = 1

    local alphaTween = YXTween.TweenFloat(0,1,showtime * 0.5,function (value)
        self._displayObj:SetAlpha(value)
    end):SetEase(DG.Tweening.Ease.InSine)

    tweenSeq:AppendInterval(waitTime)
    tweenSeq:AppendCallback(function ()
        if self._defaultAct then
            local timeScale = 1
            local loop = self._isLoop
            if self._defaultAct == "die" then
                timeScale = 100
            end
            self:PlayAni(self._defaultAct,loop,0,timeScale)
        else
            self:PlayIdleAni()
        end
    end)
    tweenSeq:Append(alphaTween)
    tweenSeq:OnComplete(function()
        self._birthTween = nil
        self._status = LFightIdleConst.STATUS_IDLE
        if self._ai then
            self._ai:StartAI()
        end

        self:OnBirthEnd()


    end)

    self._birthTween = tweenSeq
    tweenSeq:PlayForward()
end

function LStoryObject:ReBorn()
    self._curHp =self._hpMax
    self:SetPosition(self._bornPos)
    self._status = LFightIdleConst.STATUS_IDLE
    self:PlayIdleAni()
    self:ChangeBloodStick(1)
    self._bDeadEnd = false
    self._displayObj:SetAlpha(1)
end

function LStoryObject:OnBirthEnd()
    self:SetBloodStickShow(self._showBlood)
    self:SetClickFun(self._clickFun)
    self._manager:NotifyHeroLoaded(self._objKey)
end

function LStoryObject:SetBloodStickShow(isShow)
    self._showBlood = isShow
    if self._bloodStick then
        self._bloodStick:SetVisible(isShow)
    end
end

function LStoryObject:OnRun(time)
    if self:IsDestroy() then return false end
    if self._status == LFightIdleConst.STATUS_DEAD then
        if self:IsDeadEnd() and self._bloodType == 2 then
            return false
        end
    else
        if self._enableAi then
            local ai = self._ai
            ai:OnRun(time)
        end

    end
    self._moveActor:OnRun(time)
    self._atkActor:OnRun(time)
    self._pathActor:OnRun(time)
    self._aniActor:OnRun(time)
    self._alphaActor:OnRun(time)

    if self._bubbleStick then self._bubbleStick:OnRun(time) end

    return true
end

function LStoryObject:StartAi()
    if not self._ai then
        self:InitObjectAI()
        self._enableAi = true
        self._ai:StartAI()
    end

    if self._side == LFightIdleConst.SIDE_M then
        return
    end

    self:SetBloodStickShow(true)
end

function LStoryObject:StopAi()
    if not self._ai then
        return
    end
    self._enableAi = false
    self._ai:StopAI()
    self._atkActor:StopAtk()
    self:PlayIdleAni()

    if self._side == LFightIdleConst.SIDE_M then
        return
    end

    self:SetBloodStickShow(false)
end

function LStoryObject:GetStatus()
    return self._status
end

function LStoryObject:UseSkill(expressId)
    self._atkActor:DoAtk(expressId,1)
end

function LStoryObject:CanCollider()
    return self._canCollider
end

function LStoryObject:SetCanCollider(bCan)
    self._canCollider = bCan
end

function LStoryObject:ChangeOppositeDire()
    local direction = self:GetDirection()
    local newDir = LFightIdleConst.DIRECTION_RIGHT
    if direction == LFightIdleConst.DIRECTION_RIGHT then
        newDir = LFightIdleConst.DIRECTION_LEFT
    end
    self:SetDirection(newDir)
end

function LStoryObject:TimePause()
    self._aniActor:Pause()
    local objView = self:GetBtObjectView()
    if CS.IsValidObject(objView) then
        objView:TimePause()
    end
end

function LStoryObject:TimeResume()
    self._aniActor:Resume()
    local objView = self:GetBtObjectView()
    if CS.IsValidObject(objView) then
        objView:TimeResume()
    end
end

function LStoryObject:IsCheckSameBoard()
    return self._side == LFightIdleConst.SIDE_B
end

function LStoryObject:SetClickFun(func)

    if not func  then
        return
    end
    self._clickFun = func

    if not self:IsReady() then
        return
    end
    local spineTrans = self._displayObj:GetSpineTrans()
    local spineClick = spineTrans:GetComponent(typeSpineClick)
    if not spineClick then
        spineClick = spineTrans.gameObject:AddComponent(typeSpineClick)
        spineClick.isUISpine = true
    end

    if spineClick then
        spineClick.onClick = function()
            if func then
                func(self._objKey)
            end
        end
    end

end


function LStoryObject:InitBtObjectView()
    local dpTrans = self._displayObj:GetSpineTrans()
    local dpGo = dpTrans.gameObject
    local typeofBtObjectView = typeof(CardEHT.BtObjectView)
    local comp = dpGo:GetComponent(typeofBtObjectView)
    if(not comp) then
        comp = dpGo:AddComponent(typeofBtObjectView)
    end
    comp:SetRandZ(self._randZ)
    self._btObjectView = comp
    local collider = CS.FindTrans(dpTrans,"Collider")
    if collider then
        local box2d = collider:GetComponent(typeof(UnityEngine.BoxCollider2D))
        if box2d then
            local scale = self._scaleSize or 1
            local size = box2d.size * scale
            local offset = box2d.offset * scale
            self._bodyBounds = Bounds(offset,size)
            self._bodyX = size.x * 0.5
        end
    end
end

function LStoryObject:GetHitSound()
    local aniShowEfffect = self._aniShowEffectRef
    if aniShowEfffect["soundHit"] ~= nil then
        return aniShowEfffect.soundHit
    end
end

function LStoryObject:PlayHitSound()
    local sound = self:GetHitSound()
    if string.isempty(sound) then
        return
    end
    gLGameAudio:PlaySound(sound)
end

function LStoryObject:ChangeMat(matName,fadeTime)
    if self._displayObj then
        self._displayObj:SetSpineMat(matName,0,fadeTime)
    end
end

function LStoryObject:SetDefaultMat(fadeTime)
    if self._displayObj then
        self._displayObj:SetSpineDefaultMat(fadeTime)
    end
end

return LStoryObject