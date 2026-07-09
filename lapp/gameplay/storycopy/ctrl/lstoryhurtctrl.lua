---@class LStoryHurtCtrl
local LStoryHurtCtrl = LxClass("LStoryHurtCtrl",nil)

local LFightIdleHudData = LxRequire("LApp.gameplay.fightIdle.Data.LFightIdleHudData")


function LStoryHurtCtrl:LStoryHurtCtrl(mgr)
    ---@type LStoryManager
    self._mgr = mgr
end

function LStoryHurtCtrl:InitFloat()
    self._atkUp = gModelPlot:GetPara("storyHeroAttUp")
    self._atkDown = gModelPlot:GetPara("storyHeroAttDown")
end

function LStoryHurtCtrl:CalcHurt(obj,tarObj,skillData)


    local fromAttrData = obj:GetAttrData()
    --local toAttrData = tarObj:GetAttrData()
    local atk = fromAttrData[LAttrConst.Atk] or 0

    local rate = math.random()*(self._atkDown - self._atkUp) + self._atkUp
    local hurt = math.floor(atk*rate)
    local changeType = LFightIdleConst.HP_TYPE_HURT_MONSTER
    self:ApplyHurt(obj,tarObj,changeType,hurt,skillData)
end

-----------------------------------------------------------------
---执行技能伤害 飘字 被击 光效 播报等
---@param obj LFightIdleObject
---@param tarObj LFightIdleObject
function LStoryHurtCtrl:ApplyHurt(obj,tarObj,changeType,hurt,skillData)

    local hudDataList = self:CalcHurtWaveData(changeType,hurt)
    tarObj:DoHurt(changeType,-hurt)
    if hurt > 0 then
        self:GetHudCtrl():CreateHud(tarObj,hudDataList)
        if tarObj:IsLive() then
            local ai = tarObj:GetAI()
            if ai then
                ai:ChangeAction(LFightIdleConst.ACTION_BEHIT)
                tarObj:PlayHitSound()
            end
        end
    end
end

-----------------------------------------------------------------
---组织 飘字数据结构
function LStoryHurtCtrl:GenerateHudData(changeType,hurt,delay,floatHurtY,floatHurtXMin,floatHurtXMax)
    return LFightIdleHudData:New(changeType,hurt,delay,floatHurtY,floatHurtXMin,floatHurtXMax)
end

function LStoryHurtCtrl:CalcHurtWaveData(changeType,hurt)
    return {self:GenerateHudData(changeType,hurt,0,0,0,0)}
end

function LStoryHurtCtrl:GetHudCtrl()
    return self._mgr:GetHudCtrl()
end

function LStoryHurtCtrl:Destroy()
    table.removeall(self)
end

return LStoryHurtCtrl