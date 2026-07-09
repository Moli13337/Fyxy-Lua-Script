------------------------------------------------------------------
---模块使用示例 需要在LModelManager的列表里填写名字
---创建完之后可以使用gModelSkill全局变量访问实例
------------------------------------------------------------------
local LModel = LModel
------------------------------------------------------------------
---@class ModelSkill:LModel
local ModelSkill = LxClass("ModelSkill",LModel)

local LSkillData = LXImport("..Data.LSkillData")
------------------------------------------------------------------


ModelSkill.CombatBuffRef = "CombatBuffRef"
ModelSkill.SnakeSkillVfxRef= "SnakeSkillVfxRef"
ModelSkill.SnakeSkillExpressionRef = "SnakeSkillExpressionRef"
-- ModelSkill.SkillSkinRelationTreasureRef = "SkillSkinRelationTreasureRef"
ModelSkill.SnakeSkillMonsterSkinRef = "SnakeSkillMonsterSkinRef"


ModelSkill.TYPE_BUFFEFFSHOWTIME_DEAL = 1            --- 1=死亡时播放
ModelSkill.TYPE_BUFFEFFSHOWTIME_HIT = 2             --- 2=受击时播放
ModelSkill.TYPE_BUFFEFFSHOWTIME_REPLACE = 3         --- 3=buff获得且播放完技能表现后播放并替代idle动作


ModelSkill.TYPE_SHOWSTATE_DIEBEFORE = 1         --- 死亡前表现
ModelSkill.TYPE_SHOWSTATE_DIEAFTER = 2          --- 死亡后表现
ModelSkill.TYPE_SHOWSTATE_SHIELD = 3            --- 护盾破碎血=0或被覆盖（备注：buff回合消失不算，buff103变更不算）
ModelSkill.TYPE_SHOWSTATE_BOOM = 4              --- 红龙熔岩炸弹（受击次数达到或死亡，播放）
ModelSkill.TYPE_SHOWSTATE_TIGERUNFOLD = 5       --- 白虎光翼展开动作特效（被动获得buff的表现）

function ModelSkill:ModelSkill()

end

--模块初始化入口
--注册事件监听
--注册协议监听
--预处理数据
function ModelSkill:OnModelInit()
    self:ParseConfig()
end

--在协议数据处理完之后需要调用finish
function ModelSkill:OnModelRequest()
    self:ModelFinish()
end


function ModelSkill:IsMultiBulletShow(refId,vfxId)
    local cfg = GameTable.SnakeSkillEffectRef[refId]
    if not cfg then
        --printErrorN("skillEffectRef is nil refId "..(refId or ""))
        return false
    end
    local isTrue = cfg.skillShowType == 1
    if not isTrue then
        return false
    end

    local index = self:GetMultiBulletIndex(vfxId)

    return true,index
end

function ModelSkill:GetSkillExpressionId(skillExpressId,attackCnt)
    local expression = self:GetExpressConfigData(skillExpressId)
    if not expression then
        --printErrorN(string.format("expression is nil id %s cnt %s",skillExpressId,attackCnt))
        return
    end

    if expression.type == 1 then
        return skillExpressId
    elseif expression.type == 2 then
        local numList = expression.numList
        local first = numList[1]
        local last = numList[#numList]

        local key =Mathf.Clamp(attackCnt,first,last)
        local expressionId = expression.effectList[key]

        return expressionId
    end
end

function ModelSkill:GetSkillPlayEffList(skillExpressId)
    local expression = self:GetExpressConfigData(skillExpressId)
    if not expression then
        printErrorN(string.format("expression is nil id %s",skillExpressId))
        return
    end

    if expression.type == 1 then
        return {skillExpressId}
    else
        local list = {}
        for k,v in pairs(expression.effectList) do
            table.insert(list,v)
        end
        return list
    end

end

function ModelSkill:ParseConfig()
    self._skillExpressionList = {}
    self._skillEffList = {}
    self._skinToExpressList = {} --皮肤数据表

    self:CreateGeneralSkill() --通用技能数据初始化
end

function ModelSkill:ParseSingleSkillEff(skillEffect)
    local idList = {}
    local moreSplitList = string.split(skillEffect,";")
    if moreSplitList and #moreSplitList > 1 then
        for i,v in ipairs(moreSplitList) do
            self:_ParseSingleSkillEff(v,idList)
        end
    else
        self:_ParseSingleSkillEff(skillEffect,idList)
    end

    return idList
end

function ModelSkill:_ParseSingleSkillEff(effectStr,idList)
    local ids = {}
    local needSplit = string.split(effectStr,"=")
    if needSplit and #needSplit > 2 then
        local type = tonumber(needSplit[1])
        local str = needSplit[3]
        str = string.gsub(str, "{", "")
        str = string.gsub(str, "}", "")
        if type ==1 or type == 2 or type == 3 then
            ids = LxDataHelper.ParseNumber_Sign(str,",")
        elseif type == 4 then
            str = string.split(str,",")
            for k,v in ipairs(str) do
                local tempList = LxDataHelper.ParseNumber_Sign(v)
                for k1,v1 in ipairs(tempList) do
                    table.insert(ids,v1)
                end
            end
        end
    else
        ids = LxDataHelper.ParseNumber_Sign(effectStr)
    end
    for i,v in ipairs(ids) do
        table.insert(idList,tonumber(v))
    end
end

---@param skillExpressCfg V_SkillExpressionRef
function ModelSkill:ParseSingleExpress(skillExpressCfg)
    local data = nil
    local playEffType = skillExpressCfg.playEffType
    local playEff = skillExpressCfg.playEff

    local hitEffList = {}
    --- 1：溅射受击（填写技能动效表对应ID）
    ----# 1=溅射弹道ID=溅射受击特效ID
    ----# 溅射弹道：填写特效名，无则填0
    ----# 受击特效：填写特效名，无则填0
    ----# 该项默认不填，则无溅射受击特殊表现效果
    local hitEffType = skillExpressCfg.hitEffType
    if not string.isempty(hitEffType) then
        hitEffType = string.split(hitEffType,"=")
        table.insert(hitEffList,{
            hitEffectType = tonumber(hitEffType[1]),
            hitBullet = tonumber(hitEffType[2]),
            hitEffRefId = tonumber(hitEffType[3]),
        })
    end

    local effectList = LxDataHelper.ParseNumber_Sign(playEff)
    if string.isempty(playEffType) then
        data = {type = 1,effectList = effectList,hitEffList = hitEffList}
    else
        local effType = self:ParsePlayEffType(playEffType)
        if effType then
            if effType.type == 1 then
                local cnt = #effType.numList
                local temp = {}
                for k1 = 1,cnt do
                    local key = effType.numList[k1]
                    local value = effectList[k1]
                    temp[key] = value
                end
                data = {type = 2,effectList = temp,numList = effType.numList,hitEffList = hitEffList}
            end
        end
    end

    return data
end

---@return V_SkillExpressionRef
function ModelSkill:GetSkillExpressionRefByRefId(refId)
    local ref = self:GetModelConfig(ModelSkill.SnakeSkillExpressionRef)
    return ref[refId]
end

function ModelSkill:GetExpressConfigData(expressId)
    local cfg = self:GetSkillExpressionRefByRefId(expressId)
    if not cfg then
        return
    end
    local expressData = self._skillExpressionList[expressId]
    if not expressData then
        expressData = self:ParseSingleExpress(cfg)
    end

    return expressData
end


function ModelSkill:ParseSingleSkin(skinSkillExpression)
    local strs = string.split(skinSkillExpression,",")
    local skinToExpress ={}
    for k1,v1 in ipairs(strs) do
        local tempStrs = string.split(v1,"=")
        if #tempStrs>=2 then
            local skinId = tonumber(tempStrs[1])
            local express = tonumber(tempStrs[2])
            skinToExpress[skinId] = express
        end
    end
    return skinToExpress
end

function ModelSkill:ParsePlayEffType(str)
    local strs = string.split(str,"=")
    if #strs>=2 then
        local type  = tonumber(strs[1])
        local numList = LxDataHelper.ParseNumber_Sign(strs[2])
        return {type = type,numList = numList}
    end
end

--返回技能效果列表
function ModelSkill:GetEffectList(skillId)
    local skillCfg = GameTable.SnakeSkillRef[skillId]
    if not skillCfg then
        return {}
    end

    local effList = self._skillEffList[skillId]
    if not effList then
        effList = self:ParseSingleSkillEff(skillCfg.skillEffect)
        self._skillEffList[skillId] = effList
    end

    return effList
end


function ModelSkill:GetExpressionList(skillId)
    local skillCfg = GameTable.SnakeSkillRef[skillId]
    if not skillCfg then
        return {}
    end

    local effList = self._skillEffList[skillId]
    if not effList then
        effList = self:ParseSingleSkillEff(skillCfg.skillEffect)
        self._skillEffList[skillId] = effList
    end

    local dataList = {}
    if effList then
        for k,v in ipairs(effList) do
            local cfg = GameTable.SnakeSkillEffectRef[v]
            if cfg then
                local expressionId = cfg.skillShowEff
                if expressionId > 0 then
                    local data = {
                        skillEffId = v,
                        expressionId = expressionId,
                    }
                    table.insert(dataList,data)
                end
            end
        end
    end

    return dataList
end

function ModelSkill:GetSkinExpress(skinId,defaultExpress,useRef)
    -- SkillSkinRelationRef 配置已删
    if not useRef then
        return defaultExpress
    end

    local cfg = GameTable.SnakeSkillSkinRelationRef[defaultExpress]
    if not cfg then
        return defaultExpress
    end

    local skinToExpress = self._skinToExpressList[defaultExpress]
    if not skinToExpress then
        local skinSkillExpression = cfg.skinSkillExpression
        skinToExpress = self:ParseSingleSkin(skinSkillExpression)
        self._skinToExpressList[defaultExpress] = skinToExpress
    end

    local express = skinToExpress[skinId]
    if express then
        return express
    end
    --printInfoN(string.format("use defalut skinid %s expressid %s",skinId,defaultExpress))
    return defaultExpress
end

--- 技能皮肤表的 SkillType
function ModelSkill:GetSkinSkillType(skinId,expressionId)
    local cfg = GameTable.SnakeSkillSkinRelationRef[expressionId]
    if not cfg then
        return LFightConst.SKIN_SKILLTYPE_NORMAL
    end
    if not self._skinToSkillType then
        self._skinToSkillType = {}
    end
    local skinToSkillType = self._skinToSkillType[expressionId]
    if not skinToSkillType then
        skinToSkillType = {}

        local skillType = cfg.skillType
        local skinSkillExpression = cfg.skinSkillExpression
        local skinToExpress = self:ParseSingleSkin(skinSkillExpression)
        for _skinId,express in pairs(skinToExpress) do
            skinToSkillType[_skinId] = skillType
        end
        self._skinToSkillType[expressionId] = skinToSkillType
    end
    local data = skinToSkillType[skinId]
    if data then return data end

    return LFightConst.SKIN_SKILLTYPE_NORMAL
end

function ModelSkill:CreateGeneralSkill()

    local skillDataList = {}

    local para = gModelHero:GeConfigByKey("heroBelongSkillGroup")
    local strs = string.split(para,",")
    for k,v in ipairs(strs) do
        local tempstrs = string.split(v,"=")
        if #tempstrs>=2 then
            local type = tonumber(tempstrs[1])
            local isNormal = type == 1
            local skillId = tonumber(tempstrs[2])
            local skillExpressList = self:GetExpressionList(skillId)
            for k1,v1 in ipairs(skillExpressList) do
                local expressionList = self:GetSkillPlayEffList(v1.expressionId)
                if expressionList then
                    for k2,v2 in ipairs(expressionList) do
                        local expressId = v2
                        local skillData = LSkillData:New()
                        if skillData:InitData(skillId,v1.skillEffId,expressId,isNormal) then
                            skillDataList[expressId] = skillData
                        end
                    end
                end
            end

        end
    end

    self._skillDataList = skillDataList
end

function ModelSkill:GetGeneralSkillData(expressionId)
    return self._skillDataList[expressionId]
end

function ModelSkill:GetMultiBulletIndex(expressionId)
    local cfg = self:GetSkillVfxRef(expressionId)  --GameTable.SnakeSkillVfxRef[expressionId]
    if not cfg then
        return 1
    end
    local effType = cfg.effType
    if effType == LSkillEffConst.PLAY_EFF_HIT_HUD or effType == LSkillEffConst.PLAY_EFF_HUD then
        return effType.effTargetIndex
    end
    local nextPlay = cfg.nextPlay
    local nextPlayIds = LxDataHelper.ParseNumber_Sign(nextPlay,"|")
    for k,v in ipairs(nextPlayIds) do
        local temp = self:GetSkillVfxRef(v) --GameTable.SnakeSkillVfxRef[v]
        effType = temp.effType
        if effType == LSkillEffConst.PLAY_EFF_HIT_HUD or effType == LSkillEffConst.PLAY_EFF_HUD then
            return temp.effTargetIndex
        end
    end

    return 1
end


function ModelSkill:FormatBloodPlayData(oldHp,newHp,time,playNum)
    local change = newHp - oldHp
    local dataList = {}
    local sTime = time
    local changePercent = 0
    local data =nil
    local tempTime = sTime
    if playNum and #playNum>0 then
        for i, v in ipairs(playNum) do
            changePercent = changePercent + v[2]
            data =
            {
                startTime = tempTime,
                curHp = oldHp + math.floor(changePercent* change),
            }
            tempTime = sTime + v[1]
            table.insert(dataList,data)
        end
    end

    data =
    {
        startTime = tempTime,
        curHp = newHp,
    }

    table.insert(dataList,data)
    return dataList
end

function ModelSkill:GetTotalDelay(playNum)
    local totalDelay = 0
    if playNum and #playNum>0 then
        local last = playNum[#playNum]
        totalDelay = last[1]
    end

    return totalDelay
end


function ModelSkill:GetSkillRef(refId)
    local ref = GameTable.SnakeSkillRef[refId]
    if not ref and LOG_INFO_ENABLED then
        printInfoNR(" 缺少技能配置， GameTable.SnakeSkillRef[refId]， refId = "..(refId or "nil"))
    end
    return ref
end

function ModelSkill:GetSkillEffectRef(refId)
    return GameTable.SnakeSkillEffectRef[refId]
end

function ModelSkill:GetSkillCdRound(refId)
    local cfg = GameTable.SnakeSkillRef[refId]
    if not cfg then
        return 0
    end
    return cfg.cdRound
end

function ModelSkill:GetSkillIcon(refId)
    local cfg = GameTable.SnakeSkillRef[refId]
    if not cfg then
        return
    end
    return cfg.icon
end


function ModelSkill:GetBuffSkillData(refId,skinId,useRef)
    local ref = self:GetBuffRef(refId)
    if not ref then
        printErrorN(string.format("no buff ref id %s",refId))
        return
    end

    if string.isempty(ref.buffSkill) then return end

    local strs = string.split(ref.buffSkill,"=")
    local expressionId = tonumber(strs[1])
    -- 1 死亡状态不表现
    -- 2 死亡状态表现
    -- 3 护盾破碎血=0或被覆盖（备注：buff回合消失不算，buff103变更不算）
    -- 4，红龙熔岩炸弹（受击次数达到或死亡，播放）
    -- 5，白虎光翼展开动作特效（被动获得buff的表现）
    local showState = tonumber(strs[2])
    expressionId = self:GetSkinExpress(skinId,expressionId,useRef)
    return expressionId,showState
end

---@return V_SkillVfxRef
function ModelSkill:GetSkillVfxRef(refId)
    local ref = self:GetModelConfig(ModelSkill.SnakeSkillVfxRef)
    return ref[refId]
end

---@return V_BuffRef
function ModelSkill:GetBuffRef(refId)
    local ref = self:GetModelConfig(ModelSkill.CombatBuffRef)
    return ref[refId]
end

function ModelSkill:FormatBuffShowList(buffList)
    local showBuffMap = {}
    local buffShowData = nil
    for k,v in pairs(buffList) do
        local buffId = v.buffId
        local round = v.round
        local curRound = v.currentRound
        local buffRef = self:GetBuffRef(buffId)

        if buffRef then

            local show = buffRef.show1
            if show==1 then
                local groupId = buffRef.groupId
                if round == 0 or curRound>0 then

                    buffShowData =
                    {
                        refId = buffId,
                        icon = buffRef.icon,
                        name = ccLngText(buffRef.name),
                        description = ccLngText(buffRef.description),
                        level = buffRef.groupLv,
                        round = round,
                        curRound = curRound,
                        showType = buffRef.buffShowType
                    }

                    local data = showBuffMap[groupId]
                    if not data then
                        data =
                        {
                            buffShowList = {}
                        }
                        showBuffMap[groupId] = data
                    end

                    table.insert(data.buffShowList,buffShowData)
                end
            end

        end

    end

    local showList = {}

    for k,v in pairs(showBuffMap) do
        table.sort(v.buffShowList,function (a,b)
            local aPrio = a.round == 0 and 1 or 2
            local bPrio = b.round == 0 and 1 or 2

            if aPrio ~= bPrio then
                return aPrio > bPrio
            end

            return a.curRound< b.curRound
        end)

        v.buffShowData = v.buffShowList[1]

        table.insert(showList,v)
    end

    table.sort(showList,function (a,b)
        local aData = a.buffShowData
        local bData = b.buffShowData

        local aPrio = aData.round == 0 and 1 or 2
        local bPrio = bData.round == 0 and 1 or 2

        if aPrio ~= bPrio then
            return aPrio > bPrio
        end

        return aData.curRound< bData.curRound

    end)

    return showList


end

function ModelSkill:GetExpreIdBySkill(refId)
    local effectList = self:GetEffectList(refId) or {}
    local expressId = nil
    local targetNum = nil
    for k,v in ipairs(effectList) do
        local effectRef =  self:GetSkillEffectRef(v)
        local effectType =  effectRef.effectType
        if effectType == 1 or effectType == 2 then
            if not expressId then
                expressId = effectRef.skillShowEff
            end

            if not targetNum then
                targetNum = effectRef.targetHeroNum
            else
                targetNum = math.max(targetNum,effectRef.targetHeroNum)
            end

        end
    end

    if expressId then
        expressId = self:GetSkillExpressionId(expressId,0)
    end

    return expressId,targetNum
end

function ModelSkill:IsPositionSkill(refId)
    local ref = GameTable.SnakeSkillRef[refId]
    if ref and ref.type == 1 then
        return true
    end
end

function ModelSkill:GetBuffMat(refId)
    local ref = self:GetBuffRef(refId)
    if ref then
        return ref.buffMaterial
    end
end

function ModelSkill:GetBuffName(refId)
    local ref = self:GetBuffRef(refId)
    if ref then
        return ccLngText(ref.name)
    end
end

function ModelSkill:GetReliveSkillType(skillId)
    if (skillId==0) then
        return 0
    end
    local ref = self:GetSkillRef(skillId)
    if not ref then
        return 0
    end

    return ref.revive
end

function ModelSkill:GetSkillDataCommon(skillId,expressId,skinId,skillType)
    if LOG_INFO_ENABLED then
        printErrorN(string.format("战斗中没找到skillData skillId %s ,expressId %s",skillId,expressId))
    end

    local skillDataList = self._skillDataList or {}
    local skillData = skillDataList[expressId]
    if skillData then
        return skillData
    end

    self._skillDataList = skillDataList


    local skillExpressList = self:GetExpressionList(skillId)
    for k1,v1 in ipairs(skillExpressList) do
        local expressionList = self:GetSkillPlayEffList(v1.expressionId)
        if expressionList then
            for k2,v2 in ipairs(expressionList) do
                local tempRefId = v2
                local skinTempRefId = self:GetSkinExpress(skinId,tempRefId,true)

                ---@type LSkillData
                local lSkillData = LSkillData:New()
                lSkillData:SetSkinSkillType(skillType)
                if lSkillData:InitData(skillId,v1.skillEffId,skinTempRefId,false,skinId) then
                    skillDataList[skinTempRefId] = lSkillData
                end
            end
        end
    end

    return skillDataList[expressId]

end

function ModelSkill:GetSingleSkillData(skillId,expressId,skinId,expressionRefId)
    local skillDataList = self._skillDataList or {}
    local skillData = skillDataList[expressId]
    if skillData then
        return skillData
    end

    self._skillDataList = skillDataList

    local skillExpressList = self:GetExpressionList(skillId)
    for k1,v1 in ipairs(skillExpressList) do
        ---@type LSkillData
        local lSkillData = LSkillData:New()
        if lSkillData:InitData(skillId,v1.skillEffId,expressId,false,skinId) then
            skillDataList[expressId] = lSkillData
        end
    end

    return skillDataList[expressId]
end

function ModelSkill:IsSameSkillGroup(skillExpressList)
    if not skillExpressList or #skillExpressList < 1 then return false end

    local sameNum = 0
    local recordGroup
    local skillEffGroup
    local skillEffecrRef
    for i,v in ipairs(skillExpressList) do
        skillEffecrRef = self:GetSkillEffectRef(tonumber(v.skillEffId))
        if skillEffecrRef then
            skillEffGroup = skillEffecrRef.skillEffGroup
            if skillEffGroup and skillEffGroup > 0 then
                if not recordGroup then
                    recordGroup = skillEffGroup
                    sameNum = sameNum + 1
                elseif recordGroup == skillEffGroup then
                    sameNum = sameNum + 1
                end
            end
        end
    end
    return sameNum == #skillExpressList
end

function ModelSkill:GetBuffAct(refId)
    local parseFun = function(value)
        if string.isempty(value) then
            return
        end

        local strs = string.split(value,"=")
        local spineName = strs[1]
        local temps = string.split(strs[2],';')
        local aniList = {}
        for k,v in ipairs(temps) do
            local temp = string.split(v,":")
            local cnt = tonumber(temp[1])
            local ani = temp[2]
            table.insert(aniList,{cnt = cnt,ani = ani})
        end

        return {spineName = spineName,aniList = aniList}
    end

    local value = self:GetConfigValueImpl(ModelSkill.CombatBuffRef,refId,"buffAct",parseFun)
    return value

end

function ModelSkill:GetTreasureSkinExpress(skinId,defaultExpress)
    --local cfg = GameTable.SkillSkinRelationTreasureRef[defaultExpress]
    local cfg = nil
    if not cfg then
        return defaultExpress
    end

    if not self._treaSkinToExpressList then
        self._treaSkinToExpressList = {}
    end

    local skinToExpress = self._treaSkinToExpressList[defaultExpress]
    if not skinToExpress then
        local skinSkillExpression = cfg.skinSkillExpression
        skinToExpress = self:ParseSingleSkin(skinSkillExpression)
        self._treaSkinToExpressList[defaultExpress] = skinToExpress
    end

    local express = skinToExpress[skinId]
    if express then
        printInfoN(string.format("treasure use skinid %s expressid %s",skinId,express))
        return express
    end
    printInfoN(string.format("treasure use defalut skinid %s expressid %s",skinId,defaultExpress))
    return defaultExpress
end

-- 后续有需求再拓展
function ModelSkill:GetDivineWeaponSkinExpress(skinId,defaultExpress)
    local cfg = nil
    if not cfg then
        return defaultExpress
    end
end

function ModelSkill:GetBuffBuffUi(refId)
    local parseFunc = function(value)
        if string.isempty(value) then return end

        local strs = string.split(value,"=")
        local type = checknumber(strs[1])
        local temps = string.split(strs[2],":")
        local para = {
            uiType= type,
            baPath = temps[1],
            bgPath1 = string.format("%s_1",temps[1]),
            fillPath = temps[2],
            fillPath1 = temps[3],
        }

        return para
    end

    local value = self:GetConfigValueImpl(ModelSkill.CombatBuffRef,refId,"buffUi",parseFunc)

    return value
end

function ModelSkill:GetParsePlayNumFunc(effType)
    if not self._playNumParse then
        self._playNumParse =
        {
            [LSkillEffConst.PLAY_EFF_BULLET] = function(value) return self:ParsePlayNumOne(value) end,
            [LSkillEffConst.PLAY_EFF_HIT_HUD] = function(value) return self:ParsePlayNumTwo(value) end,
        }
    end

    local func = self._playNumParse[effType]
    if not func then
        func = function(value) return tonumber(value) end
    end
    return func
end

function ModelSkill:ParsePlayNumOne(value)
    local playNumTable = {}
    local strList = string.split(value,",") or {}
    for e, q in ipairs(strList) do
        table.insert(playNumTable,tonumber(q) or 0)
    end
    return playNumTable
end

function ModelSkill:ParsePlayNumTwo(value)
    local playNumTable = {}
    local strList = string.split(value,",") or {}
    for i, v in ipairs(strList) do
        local stringList = string.split(v,"=") or {}
        local number = {}
        for j, k in ipairs(stringList) do
            table.insert(number,tonumber(k) or 0)
        end
        if #number >= 2 then
            table.insert(playNumTable,number)
        end
    end

    return playNumTable
end

function ModelSkill:GetUISkillExpress(expressId)
    local ref = self:GetSkillExpressionRefByRefId(expressId)
    if ref and ref.uiShow > 0 then
        return ref.uiShow
    end

    return expressId
end

function ModelSkill:GetSummonShowSkin(monsterRefId,skinId)
    local parseFunc = function(value)
        local strs = string.split(value,',')
        local record = {}
        for k,v in ipairs(strs) do
            local temps = string.split(v,'=')
            record[tonumber(temps[1])] = tonumber(temps[2])
        end
        return record
    end

    local record = self:GetConfigValueImpl(ModelSkill.SnakeSkillMonsterSkinRef,monsterRefId,"skinMonster",parseFunc)

    return record and record[skinId]
end
function ModelSkill:GetSkillSoundBattle(heroEffRefId,skillVfxId)
    if not skillVfxId then return end
    local skillVfxRef = GameTable.SnakeSkillVfxRef[skillVfxId]
    if not skillVfxRef or not skillVfxRef.soundBattle or skillVfxRef.soundBattle=="" then return end
    local sounds = string.split(skillVfxRef.soundBattle,"=")
    if #sounds<=1 then return sounds[1] end
    if not heroEffRefId then return end
    local heroRefId = GameTable.CharacterEffectRef[heroEffRefId].heroType
    if not heroRefId then return end
    local loveLevel = gModelHero:GetHeroLoveLvByRefId(heroRefId) or 0
    if loveLevel>=tonumber(sounds[2]) then return sounds[1] end
end

function ModelSkill:ParamsSkillBuffEffDamageTypes(refId)
    if not self._buffEffDamageTypes then
        self._buffEffDamageTypes = {}
    end
    local damageTypeMap = self._buffEffDamageTypes[refId]
    if not damageTypeMap then
        ---@type V_BuffRef
        local ref = self:GetBuffRef(refId)
        if ref and not string.isempty(ref.buffEffDamageType) then
            local buffEffDamageType = string.split(ref.buffEffDamageType,"|")
            damageTypeMap = {}
            for i,v in ipairs(buffEffDamageType) do
                v = tonumber(v)
                damageTypeMap[v] = true
            end
            self._buffEffDamageTypes[refId] = damageTypeMap
        end
    end
    return damageTypeMap
end

function ModelSkill:CheckNeedShowDamageBuffEff(buffId,ht)
    local damageTypeMap = self:ParamsSkillBuffEffDamageTypes(buffId)
    if not damageTypeMap then return false end
    return damageTypeMap[ht]
end

---@return V_SkillExpressionRef 技能表现表
function ModelSkill:GetSkillExpressionRef(refId)
    return GameTable.SnakeSkillExpressionRef[refId]
end

---@return V_SkillExpressionRef 技能表现表
function ModelSkill:ParsePlayEff(hadMap,playEffListStr,skinId,needCheckSound,skinSkillType)
    local arrPlayEffId = string.split(playEffListStr or "","|") or {}
    local playEffList = {}
    --跟随子弹的动效表现列表
    for k,strId in ipairs(arrPlayEffId) do
        local refId = tonumber(strId)
        local data = self:_ParamSkillVfxRefData(refId,needCheckSound,skinSkillType)
        if data then
            hadMap[refId] = data
            table.insert(playEffList,data)
        end
    end
    return playEffList
end

function ModelSkill:_ParamSkillVfxRefData(refId,needCheckSound,skinSkillType)
    local skillVfxRef = self:GetSkillVfxRef(refId)
    if not skillVfxRef then return end

    local extraData = nil
    local effType = skillVfxRef.effType
    local effRes = skillVfxRef.effRes
    if effType == LSkillEffConst.PALY_OBJ_SORCERYCARD then
        local effResInfo = string.split(effRes,"=")
        effRes = effResInfo[2]
        extraData = {
            sorceryCardId = checknumber(effResInfo[1]),
        }
    end
    return {
        refId = refId,
        effType = skillVfxRef.effType,
        effRes = effRes,
        actionReset = skillVfxRef.actionReset,
        delayTime = skillVfxRef.delayTime,
        playTime = skillVfxRef.playTime,
        dissipateTime = skillVfxRef.dissipateTime,
        moveSpeed = skillVfxRef.moveSpeed,
        nextPlay = skillVfxRef.nextPlay,
        excursionIObject = skillVfxRef.excursionIObject,
        effOffsetStart = self:ParseOffset(skillVfxRef.effOffsetStart),
        effOffsetEnd = self:ParseOffset(skillVfxRef.effOffsetEnd),
        effTarget = skillVfxRef.effTarget,
        bulletCdTime = skillVfxRef.bulletCdTime,
        effTargetIndex = skillVfxRef.effTargetIndex,
        bulletTrack = skillVfxRef.bulletTrack,
        playNum = self:ParsePlayNum(skillVfxRef.playNum,skillVfxRef.effType),
        nextPlayList = {},
        soundBattle = skillVfxRef.soundBattle,
        talkTxt = ccLngText(skillVfxRef.talkTxt),
        effStartType = skillVfxRef.effOffsetStartType,
        battleHierarchy = skillVfxRef.battleHierarchy or 0,
        boneName = skillVfxRef.boneName,
        showLoop = skillVfxRef.showLoop,
        needCheckSound = needCheckSound,
        skinSkillType = skinSkillType,
        extraData = extraData,
    }
end

function ModelSkill:ParseOffset(str)
    if string.isempty(str) then return Vector3.zero end
    local offset = LxDataHelper.ParseVector(str)
    return offset
end

--对4类型
--# 用于服务端是同一伤害但使用多次弹道射击
--# 留空=只射1颗
--# 第1与第2间隔cd,第2和第3间隔cd,第3和第4间隔…第n-1和第n颗子弹间隔
function ModelSkill:ParsePlayNum(str,effType)
    if string.isempty(str) then return {} end
    local func = self:GetParsePlayNumFunc(effType)
    return func(str)
    --local playNumTable = {}
    --local strList = string.split(str,",") or {}
    --if effType == LSkillEffConst.PLAY_EFF_BULLET then
    --	for e, q in ipairs(strList) do
    --		table.insert(playNumTable,tonumber(q) or 0)
    --	end
    --elseif effType == LSkillEffConst.PLAY_EFF_FADE or
    --		effType == LSkillEffConst.PLAY_EFF_TOP_FADE or
    --		effType == LSkillEffConst.PLAY_EFF_TREASURE or
    --		effType == LSkillEffConst.PLAY_EFF_FADE_EXTRA or
    --		effType == LSkillEffConst.PLAY_EFF_FADE_TOP_EXTRA
    --then
    --	return tonumber(str)
    --elseif effType == LSkillEffConst.PLAY_EFF_EFFECT then
    --	for e, q in ipairs(strList) do
    --		table.insert(playNumTable,tonumber(q) or 0)
    --	end
    --else
    --	for i, v in ipairs(strList) do
    --		local stringList = string.split(v,"=") or {}
    --		local number = {}
    --		for j, k in ipairs(stringList) do
    --			table.insert(number,tonumber(k) or 0)
    --		end
    --		if #number >= 2 then
    --			table.insert(playNumTable,number)
    --		end
    --	end
    --end
    --
    --return playNumTable
end

function ModelSkill:IsShowSorceryEff(buffId)
    local buffRef = self:GetBuffRef(buffId)
    return buffRef and buffRef.specialShow == 4
end


function ModelSkill:GetBuffEffShowTimeInfo(refId)
    local initBuffEffShowTimeInfo = self._initBuffEffShowTimeInfo
    if not initBuffEffShowTimeInfo then
        initBuffEffShowTimeInfo = {}
        self._initBuffEffShowTimeInfo = initBuffEffShowTimeInfo
    end
    local data = initBuffEffShowTimeInfo[refId]
    if not data then
        local buffRef = self:GetBuffRef(refId)
        if buffRef then
            data = {}
            local buffEffShowTime = buffRef.buffEffShowTime
            if type(buffEffShowTime) == "number" then
                data.buffEffShowTime = buffEffShowTime
            else
                local buffEffShowTimeInfo = string.split(buffEffShowTime,"=")
                if #buffEffShowTimeInfo > 1 then
                    data.buffEffShowTime = checknumber(buffEffShowTimeInfo[1])
                    data.expressionId = checknumber(buffEffShowTimeInfo[2])
                    data.showState = ModelSkill.TYPE_BUFFEFFSHOWTIME_REPLACE
                else
                    data.buffEffShowTime = checknumber(buffEffShowTime)
                end
            end
            initBuffEffShowTimeInfo[refId] = data
        end
    end
    return data
end

function ModelSkill:GetBuffEffShowTime(refId)
    local info = self:GetBuffEffShowTimeInfo(refId)
    if not info then return 0 end

    return info.buffEffShowTime
end

function ModelSkill:GetBuffEffShowSkillId(refId)
    local info = self:GetBuffEffShowTimeInfo(refId)
    if not info then return end

    return info.expressionId
end


function ModelSkill:CheckIsHitShowBuff(refId)
    local buffEffShowTime = self:GetBuffEffShowTime(refId)
    return buffEffShowTime == ModelSkill.TYPE_BUFFEFFSHOWTIME_HIT
end


function ModelSkill:CalcSkillTime(playEffectList,depth)
    if not playEffectList or #playEffectList < 1 then return 0 end
    local maxTime = 0

    local maxIncludeTime = 0
    depth = depth or 0
    for k,v in pairs(playEffectList) do
        local max = v.delayTime + v.playTime
        local maxInclude = v.delayTime + v.playTime
        if v.effType == LSkillEffConst.PLAY_EFF_BULLET then
            maxInclude = maxInclude + self:GetBulletTime()
        end
        if depth == 0 and #v.nextPlayList > 0 then
            local time1,time2 = self:CalcSkillTime(v.nextPlayList,depth + 1)
            max = max + time1
            maxInclude = maxInclude + time2
        end
        if max > maxTime then
            maxTime = max
        end

        if maxInclude> maxIncludeTime then
            maxIncludeTime = maxInclude
        end
    end
    return maxTime,maxIncludeTime
end

function ModelSkill:GetBulletTime()
    return GameTable.BattleConfigRef["bulletTime"] or 0
end

--清理工作
--停止计时器之类的
function ModelSkill:OnModelClear()

end

return ModelSkill