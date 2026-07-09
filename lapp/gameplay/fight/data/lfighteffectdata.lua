---@class LFightEffectData
local LFightEffectData = LxClass("LFightEffectData",nil)

LFightEffectData.HURT = 0
LFightEffectData.BUFF = 1
LFightEffectData.TREATS = 2
LFightEffectData.SHIELD = 3
LFightEffectData.SHIELDHURT = 4
LFightEffectData.PSHIELD = 5
LFightEffectData.ANGER = 6
LFightEffectData.POSITION = 7
LFightEffectData.SELECT = 8
LFightEffectData.SUMMON = 9
LFightEffectData.ROUND = 10
--- buf的统计数据
LFightEffectData.STATISTICS = 11


function LFightEffectData:LFightEffectData()
    self.aId = nil
    self.eId = nil
    self.type = nil
    --self.targetType = nil
    self.hitType  =nil

    self.ht = nil
    self.hurt = nil
    self.dead = nil
    self.spurtingList = nil
    self.afterHp = nil

    self.buffUniqueId = nil
    self.etype = nil
    self.buffId = nil
    self.round = nil

    self.treat = nil
    self.skill = nil
    self.express = nil
    self.relive = nil
    self.effectType = nil

    self.shieldUniqueId = nil
    self.hp = nil

    self.hurt = nil

    self.blockUniqueId = nil
    self.count = nil

    self.angerValue = nil

    --- buf效果唯一ID
    self.buffEffectId = nil

    --- 已受击次数
    self.beAttackCount = nil

    --- 最大受击次数
    self.maxAttackCount = nil
end

function LFightEffectData:CreateByPb(pb,indexInfo)
    self.aId = pb.aId
    self.eId = pb.eId
    local type = pb.type
    self.type = type
    self.hitType = pb.hitType

    if type == LFightEffectData.HURT then
        local hurtEffect = pb.hurtEffect
        self.ht = hurtEffect.ht
        self.hurt = hurtEffect.hurt
        self.dead = hurtEffect.dead == 1
        self.spurtingList={}
        for k,v in ipairs(hurtEffect.spurtingList) do
            local effectData = LFightEffectData:New()
            effectData:CreateByPb(v)
            table.insert(self.spurtingList,effectData)
        end
        self.afterHp = hurtEffect.afterHp
    elseif type == LFightEffectData.BUFF then
        local buffEffect = pb.buffEffect
        self.buffUniqueId = buffEffect.buffUniqueId
        self.etype = buffEffect.etype
        self.buffId = buffEffect.buffId
        self.round = buffEffect.round
        self.show = buffEffect.show == 0
    elseif type == LFightEffectData.TREATS then
        local treatEffect = pb.treatEffect
        self.treat = treatEffect.treat
        self.skill = treatEffect.skill
        ---兼容旧数据
        local expressId = treatEffect.express or 0
        if expressId < 0 then
            expressId = -expressId
        else
            expressId = 0
        end
        self.express = expressId
        self.relive = treatEffect.relive == 1
        self.afterHp = treatEffect.afterHp
        self.effectType = treatEffect.effectType
    elseif type == LFightEffectData.SHIELD then
        local shieldEffect = pb.shieldEffect
        self.shieldUniqueId = shieldEffect.shieldUniqueId
        self.buffUniqueId = shieldEffect.buffUniqueId
        self.hp = shieldEffect.hp
    elseif type == LFightEffectData.SHIELDHURT then
        local shieldHurtEffect = pb.shieldHurtEffect
        self.shieldUniqueId = shieldHurtEffect.shieldUniqueId
        self.hurt = shieldHurtEffect.hurt
    elseif type == LFightEffectData.PSHIELD then
        local pShieldEffect = pb.pShieldEffect
        self.blockUniqueId = pShieldEffect.blockUniqueId
        self.buffUniqueId = pShieldEffect.buffUniqueId
        self.count = pShieldEffect.count
    elseif type == LFightEffectData.ANGER then
        local angerEffect = pb.angerEffect
        self.buffUniqueId = angerEffect.buffUniqueId
        self.angerValue = angerEffect.angerValue
    elseif type == LFightEffectData.POSITION then
        local positionEffect = pb.positionEffect
        self.buffUniqueId = positionEffect.buffUniqueId
        self.oldIndex = positionEffect.oldIndex
        self.newIndex = positionEffect.newIndex
        self.wayIndexList = positionEffect.wayIndexList or {}
    elseif type == LFightEffectData.SUMMON then
        local summonEffect = pb.summonEffect
        self.buffUniqueId = summonEffect.buffUniqueId
        self.belong = summonEffect.belong
        local hero = summonEffect.hero
        self.hero = {
            id = hero.id,
            index = hero.index,
            refId = hero.refId,
            level = hero.level,
            star = hero.star,
            grade = hero.grade,
            maxHp = hero.maxHp,
            hp = hero.hp,
            fightPower = hero.fightPower,
            skinId = hero.skinId,
            resonance = hero.resonance,
            unitType = hero.unitType, --1 怪物，2 英雄，3 宠物
            quality = hero.quality,
            sorceryCardRefId = hero.sorceryCardRefId,
            sorceryCardInfo = {
                scRefId = hero.sorceryCardInfo.scRefId,
                level = hero.sorceryCardInfo.level
            },
            changeStatus = hero.changeStatus,
        }
    elseif type == LFightEffectData.ROUND then
        local roundEffect = pb.roundEffect
        self.buffUniqueId = roundEffect.buffUniqueId
        self.round = roundEffect.round
    elseif type == LFightEffectData.STATISTICS then
        --- 回合数效果结构
        local statisticEffect = pb.statisticEffect
        self.buffUniqueId = statisticEffect.buffUniqueId
        self.buffEffectId = statisticEffect.buffEffectId
        self.beAttackCount = statisticEffect.beAttackCount
        self.maxAttackCount = statisticEffect.maxAttackCount
    end

end

function LFightEffectData:CreateByJson(json)
    self.aId            = json.aId
    self.eId            = json.eId
    self.type           = json.type
    self.hitType        = json.hitType

    self.ht             = json.ht
    self.hurt           = json.hurt
    self.dead           = json.dead
    self.spurtingList   = json.spurtingList
    self.afterHp        = json.afterHp

    self.buffUniqueId   = json.buffUniqueId
    self.etype          = json.etype
    self.buffId         = json.buffId
    self.round          = json.round

    self.treat          = json.treat
    self.skill          = json.skill
    self.express        = json.express
    self.relive         = json.relive
    self.effectType     = json.effectType

    self.shieldUniqueId = json.shieldUniqueId
    self.hp             = json.hp

    self.hurt           = json.hurt

    self.blockUniqueId  = json.blockUniqueId
    self.count          = json.count

    self.angerValue     = json.angerValue

    --- 回合数效果结构
    self.buffEffectId = json.buffEffectId
    self.beAttackCount = json.beAttackCount
    self.maxAttackCount = json.maxAttackCount

end


return LFightEffectData