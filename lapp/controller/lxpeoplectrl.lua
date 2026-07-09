--- 居民 UI界面的controller
local AttrType = {
    --- 城镇温度
    Temperature = 1,
    --- 饱腹值
    Satiety = 2,
    --- 疲劳值
    Tired = 3,
}
--- 对应的增益id
local buffType = {
    --- 饱腹恢复增益id
    [AttrType.Satiety] = SysBuffType.Satiety,
    --- 疲劳恢复增益id
    [AttrType.Tired] = SysBuffType.Tired,
}
--- 属性值类型对应内建筑id
local attrByBuildingId = {
    [AttrType.Temperature] = BuildingType.HuoLu,
    [AttrType.Satiety] = BuildingType.Kitchen,
    [AttrType.Tired] = BuildingType.MinHouse,
}
local WorkBuildingType = {
    [BuildingType.FaMuChang] = 9029,
    [BuildingType.MeiKuangChang] = 9027,
    [BuildingType.TieKuangChang] = 9028,
    [BuildingType.LieRenHouse] = 9057,
    [BuildingType.Kitchen] = 9026,
}
local LxBaseCtrl = require("LApp.controller.LxBaseCtrl")
---@class LxPeopleCtrl:LxBaseCtrl
local LxPeopleCtrl = classX("LxPeopleCtrl", LxBaseCtrl)
function LxPeopleCtrl:Initialize()
    LxBaseCtrl.Initialize(self)

end

function LxPeopleCtrl:Dispose()
    LxBaseCtrl.Dispose(self)
end

--- 根据 小时 获取作息表时间段配置
--- @param hour number 时间
---
---@return V_PeopleTimeRef
function LxPeopleCtrl:GetTimeSlotCfg(hour)
    local timeRefList = GameTable.PeopleTimeRef
    for _, v in pairs(timeRefList) do
        if hour < 0 or hour > 24 then return end
        -- # 处理跨天的情况
        if v.time[1] >= v.time[2] and hour < v.time[2] then
            return v
        elseif hour >= v.time[1] and hour < v.time[2] then
                return v
        end
    end
end

--- 获取通知配置
--- @param refId number
--- @return V_PeopleNoticeRef
function LxPeopleCtrl:GetNoticeRef(refId)
    return GameTable.PeopleNoticeRef[refId]
end

--- 获取居民名字配置
function LxPeopleCtrl:GetPeopleNameRef(refId)
    return GameTable.PeopleNameRef[refId]
end
--- 获取居民配置
function LxPeopleCtrl:GetPeopleRef(refId)
    return GameTable.PeopleRef[refId]
end

--- 获取居民属性的进度值
--- 城镇温度：1 / (当前温度 / 温度上限)
--- 饱腹值：所有居民当前饱腹值总和 / (peopleAttr30 * 居民数)
--- 疲劳值：所有居民当前疲劳值总和 / (peopleAttr33 * 居民数)
function LxPeopleCtrl:GetAttrValue(refId)
    local curValue = 0
    local maxValue = 10
    local isUp = false   -- 状态是否是上升
    local peopleList = ModuleCenter.People:GetHasPeopleList()
    local cfgRef = GameTable.PeopleConfigRef
    --- 温度直接读火炉等级
    if refId == AttrType.Temperature then
        local curLv = ModuleCenter.Building:GetBuildingLvl(BuildingType.HuoLu)
        local huoLuRef = GameTable.BuildingRef[BuildingType.HuoLu]
        local maxCfg = CtrlCenter.Building:GetMainBuildUpgradeCfg(BuildingType.HuoLu, huoLuRef.maxLevel)
        local curCfg = CtrlCenter.Building:GetMainBuildUpgradeCfg(BuildingType.HuoLu, curLv)
        local _tMax = 0
        for _, v in ipairs(maxCfg.buildEffectShow) do
            local effArr = string.split(v, "=")
            local e1 = checknumber(effArr[1])
            local e2 = checknumber(effArr[2])
            if e1 == SysBuffType.Temperature then
                _tMax = e2
                break
            end
        end
        if curLv > 0 and curCfg then
            for _, v in ipairs(curCfg.buildEffectShow) do
                local effArr = string.split(v, "=")
                local e1 = checknumber(effArr[1])
                local e2 = checknumber(effArr[2])
                if e1 == SysBuffType.Temperature then
                    maxValue = e2 / _tMax
                    break
                end
            end
        else
            maxValue = _tMax
        end
        curValue = 1
    else
        local attrValue = refId == AttrType.Satiety and cfgRef.peopleAttr30 or cfgRef.peopleAttr33
        local num = 0
        for _, v in pairs(peopleList) do
            local curAttr = refId == AttrType.Satiety and v.satiety or v.fatigue
            curValue = curValue + curAttr
            num = num + 1
        end
        maxValue = attrValue * num
        local peopleConst = self:GetPeopleConsume()
        local cost = peopleConst[buffType[refId]]
        local buildingId = attrByBuildingId[refId]
        local innerInfo = CtrlCenter.Building:GetInnerBuildUpgradeCfg(buildingId)
        if innerInfo then
            local produce = 0       -- 产出
            local time = 0          -- 时长 单位为秒
            local minProduce = 0    -- 每分钟产出
            for _, v in ipairs(innerInfo.buildEffect) do
                local effArr = string.split(v, "=")
                local e1 = checknumber(effArr[1])
                local e2 = checknumber(effArr[2])
                if buffType[refId] == e1 then
                    produce = e2
                elseif e1 == SysBuffType.WorkTime then
                    time = produce
                end
            end
            minProduce = produce / time * 60
            isUp = cost < minProduce
        end
    end
    maxValue = maxValue <= 0 and 1 or maxValue
    return curValue, maxValue, isUp
end
--- 获取每分钟减少的 疲劳值跟饱腹值
function LxPeopleCtrl:GetPeopleConsume()
    if not table.isempty(self._peopleConst) then
        return self._peopleConst
    end
    local manageList = GameTable.PeopleManageRef
    self._peopleConst = {}
    local _t = {}
    for _, v in pairs(manageList) do
        if v.cost then
            for _, v2 in ipairs(v.cost) do
                local costArr = string.split(v2, "=")
                local c1 = checknumber(costArr[1])
                local c2 = checknumber(costArr[2])
                if not _t[c1] then
                    _t[c1] = {}
                end
                table.insert(_t[c1], c2)
            end
        end
    end
    for k, v in pairs(_t) do
        local sum = 0
        for _, v2 in ipairs(v) do
            sum = sum + v2
        end
        self._peopleConst[k] = sum / #v
    end
    return self._peopleConst
end

--- 获取有工位的资源内建筑
function LxPeopleCtrl:GetCanWorkBuildList()
    local refList = GameTable.BuildingInRef
    local buildingModule = ModuleCenter.Building
    local workBuildList = {}


    for _, v in pairs(refList) do
        local level = buildingModule:GetBuildingLvl(v.type)
        if v.worker ~= nil and level > 0 then
            table.insert(workBuildList, v)
        end
    end
    table.sort(workBuildList, function(a, b) return a.refId < b.refId end)
    return workBuildList
end
--- 获取当前对应阶段跟下一个阶段的民心配置
function LxPeopleCtrl:GetCurStageHeartRef()
    local maxPopular = ModuleCenter.People:GetCurPopular()
    local heartRefList = GameTable.PeopleHeartRef
    local curRef
    local nextRef
    for _, v in ipairs(heartRefList) do
        if v.need > maxPopular then
            nextRef = v
            break
        else
            curRef = v
        end
    end
    return curRef, nextRef
end
--- 获取当前民心任务
function LxPeopleCtrl:GetCurHeartTask()
    local showTask = {}
    local questModule = ModuleCenter.Quest
    local questRefList = GameTable.MissionRef
    local questList = questModule:GetQuestList()
    local peopleList = {}
    for _, v in pairs(questList) do
        local ref = questRefList[v.refId]
        if ref.type == QuestTypeEnum.Popular then
            table.insert(peopleList, ref)
        end
    end
    table.sort(peopleList, function(a, b) return a.refId < b.refId end)
    for _, v in pairs(peopleList) do
        if v.state ~= ActivityTaskState.HadReceive then
            table.insert(showTask, v)
            break
        end
    end
    return showTask
end

--- 获取当前任务对应的居民
function LxPeopleCtrl:GetCurTaskPeople(questId)
    local pList = ModuleCenter.People:GetSortHasPeopleList()
    if #pList == 0 then
        return 1001
    end
    if #pList == 1 then
        return pList[1].refId
    end
    math.randomseed(os.time())
    local randomNum = math.random(1, #pList)
    return pList[randomNum].refId
end

--- 民心 技能配置
function LxPeopleCtrl:GetSkillRef(refId)
    return GameTable.PeopleSkillRef[refId]
end

--- 民心技能 是否可使用
function LxPeopleCtrl:CheckSkillIsCanUse(refId)
    local isUnlock = self:GetPeopleSkillIsUnlock(refId)
    if not isUnlock then
        return false
    end
    local skillObj = ModuleCenter.People:GetSkillObj(refId)
    local skillRef = self:GetSkillRef(refId)
    for _, v in ipairs(skillRef.useSkill) do
        local item = LxDataHelper.ParseItem(v)
        local hasNum = ModuleCenter.Item:GetItemCount(item.refId)
        if hasNum < item.num then
            return false
        end
    end
    if table.isempty(skillObj) then
        return true
    end
    local timeCD = skillRef.timeCD
    --- 冷却时间没到
    if GetTimestamp() < (skillObj.useTime + timeCD) then
        return false
    end
    --- 使用限制
    if not string.isempty(skillRef.useLimit) then
        return self:CheckSkillSatisfyUseLimit(skillRef.useLimit)
    end
    return true
end
--- 根据技能id 获取对应的民心配置
function LxPeopleCtrl:GetPeopleHeartRefBySkillId(skillId)
    local heartRefList = GameTable.PeopleHeartRef
    for _, v in ipairs(heartRefList) do
        if not table.isempty(v.showSkill) then
            for _, v2 in ipairs(v.showSkill) do
                if v2 == skillId then
                    return v
                end
            end
        end
    end
end
--- 判断技能是否已经解锁
function LxPeopleCtrl:GetPeopleSkillIsUnlock(skillId)
    local skillRef = GameTable.PeopleSkillRef[skillId]
    return self:CheckCondition(skillRef.unlock)
end
--- 是否显示技能
function LxPeopleCtrl:GetPeopleSkillIsShow(skillId)
    local skillRef = GameTable.PeopleSkillRef[skillId]
    return self:CheckCondition(skillRef.show)
end
--- 检查条件是否满足
function LxPeopleCtrl:CheckCondition(condition)
    local maxPopular = ModuleCenter.People:GetMaxPopular()
    -- 解锁条件
    local conditions = string.split(condition, "=")
    local cdtType = checknumber(conditions[1])  -- 解锁类型
    local cdtValue = checknumber(conditions[2])
    if cdtType == PeopleUnlockSkillType.Popular then
        local ref = GameTable.PeopleHeartRef[cdtValue]
        if maxPopular >= ref.need then
            return true
        end
    elseif cdtType == PeopleUnlockSkillType.HuoLu then
        local lv = ModuleCenter.Building:GetBuildingLvl(BuildingType.HuoLu)
        if lv >= cdtValue then
            return true
        end
    end
    return false
end
--- 是否满足使用限制要求
function LxPeopleCtrl:CheckSkillSatisfyUseLimit(condition)
    local conditions = string.split(condition, "=")
    local cdtType = checknumber(conditions[1])  -- 解锁类型
    local cdtValue = checknumber(conditions[2])
    if cdtType == PeopleUseSkillLimit.Time then     -- 特点时间段使用
        local hour, _ = self:GetGameHourAndMin(self:GetPeopleTime())
        local timeRef = self:GetTimeSlotCfg(hour)
        if timeRef.refId == cdtValue then
            return true
        end
    elseif cdtType == PeopleUseSkillLimit.Sick then -- 存在生病的人数
        local peopleObjList = ModuleCenter.People:GetHasPeopleList()
        local sickNum = 0
        for _, v in pairs(peopleObjList) do
            if v.sick then
                sickNum = sickNum + 1
            end
        end
        if sickNum >= cdtValue then
            return true
        end
    elseif cdtType == PeopleUseSkillLimit.Buff then -- 存在某种buff
        local buffObj = ModuleCenter.Buff:GetBuffObj(cdtValue)
        return table.isempty(buffObj)
    end
    return false
end
--- 获取当前居民工作状态  return 工作中的数量， 生病中的数量， 未分配的数量
function LxPeopleCtrl:GetPeopleStateNum()
    local working, patient, idle = 0, 0, 0
    local peopleList = ModuleCenter.People:GetHasPeopleList()
    for _, v in pairs(peopleList) do
        if v.building > 0 then
            working = working + 1
        elseif v.sick then
            patient = patient + 1
        else
            idle = idle + 1
        end
    end
    return working, patient, idle
end

--- 获取当前空闲居民的列表
function LxPeopleCtrl:GetIdlePeopleList()
    local showList = {}
    local peopleList = ModuleCenter.People:GetSortHasPeopleList()
    for _, v in ipairs(peopleList) do
        if v.building <= 0 and not v.sick then
            table.insert(showList, v)
        end
    end
    table.sort(showList, function(a, b) return a.refId < b.refId end)
    return showList
end
--- 获取对应建筑的岗位列表
--- @param buildingId number 建筑refId
function LxPeopleCtrl:GetWorkPostByBuildingId(buildingId)
    local buildingInRef = GameTable.BuildingInRef[buildingId]
    local worker = buildingInRef.worker
    local buildingCtrl = CtrlCenter.Building
    local showList = {}
    if worker ~= nil then
        for i, _ in ipairs(worker) do
            local buildInfo = buildingCtrl:GetInnerBuildLvl(buildingInRef.type)
            local curLv = buildInfo.level

            local cdt = string.split(worker[i], "=")
            --- 当前工作 岗位id
            local curId = checknumber(cdt[1])
            --- 需要的等级
            local needLv = checknumber(cdt[2])
            if curLv >= needLv then
                local _t = {}
                _t.buildingId = buildingId
                _t.worker = worker[i]
                _t.curId = curId
                _t.needLv = needLv
                _t.curLv = curLv
                _t.type = buildingInRef.type
                table.insert(showList, _t)
            end
        end
    end
    return showList
end

--- 居民民心 是否弹出历史最大值提升弹窗
function LxPeopleCtrl:CheckHeartUp()
    local maxPopular = ModuleCenter.People:GetMaxPopular()
    local oldMaxPopular = ModuleCenter.People:GetOldMaxPopular()
    if maxPopular > oldMaxPopular then
        local oldRefId, newRefId = 0, 0
        local heartRefList = GameTable.PeopleHeartRef
        for _, v in ipairs(heartRefList) do
            if maxPopular < v.need then
                break
            else
                if oldMaxPopular >= v.need then
                    oldRefId = v.refId
                end
                if maxPopular >= v.need then
                    newRefId = v.refId
                end
            end
        end
        if newRefId > 0 and newRefId > oldRefId then
            self._waitShowHeartInfo = {oldRefId = oldRefId, newRefId = newRefId}
            FireEvent(EventNames.PEOPLE_REFRESH_POPULAR_UP)
        end
    end
    ModuleCenter.People:SetOldMaxPopular()
end
--若休息周期，在民居中，显示：睡觉中
--若吃饭周期，在厨房中，显示：吃饭中
--若工作周期，但居民空闲时，显示：闲置中
--若工作周期，在伐木场上工，显示：伐木中
--若工作周期，在厨房中，显示：做饭中
--若工作周期，在铁矿场，显示：冶铁中
--若工作周期，在煤矿场，显示：采煤中
--若工作周期，在猎人小屋，显示：狩猎中
--- 获取居民状态
function LxPeopleCtrl:GetPeopleStatus(refId)
    local manageRef = self:GetPeopleManage(refId)
    return manageRef.desc
end
--- 获取当前时间  服务器当前时间 - 基准时间 = 现实过去了多少秒，按比列算游戏时间过去了多少秒
function LxPeopleCtrl:GetPeopleTime()
    local serverTime = GetTimestamp()
    -- 基准时间
    local timeBase = ModuleCenter.People:GetTimeBase()
    -- 现实时间与游戏时间的倍率
    local ratio = self:GetGameTimeRatio()
    --- 当前游戏经历的时间 单位：秒
    local curGameTime = (serverTime - timeBase) * ratio
    return curGameTime
end
--- 获取现实时间 对应游戏时间的 倍率
function LxPeopleCtrl:GetGameTimeRatio()
    local cfgRef = GameTable.PeopleConfigRef
    -- 游戏时间换算，游戏时间x分钟=现实时间多少秒
    local gameTime = cfgRef.gameTime
    local times = string.split(gameTime, "=")
    local gTime = checknumber(times[1])
    local realityTime = checknumber(times[2]) / gTime
    -- 现实时间与游戏时间的倍率
    local ratio = 60 / realityTime
    return ratio
end
--- 获取换算后的 游戏时、分
--- @param gameTime number LxPeopleCtrl:GetPeopleTime() 返回的时间戳
function LxPeopleCtrl:GetGameHourAndMin(gameTime)
    --local day = math.floor(gameTime / 86400)
    local hour = math.floor(gameTime % 86400 / 3600)
    local min = math.floor(gameTime % 3600 / 60)
    return hour, min
end

--- 总红点
function LxPeopleCtrl:CheckPeopleAllRed()
    if self:CheckHeartRed() then
        return 1
    end
    if self:CheckWorkRed() then
        return 1
    end
    return 0
end

--- 民心红点
function LxPeopleCtrl:CheckHeartRed()
    local questList = self:GetCurHeartTask()
    local questModule = ModuleCenter.Quest
    local skillList = ModuleCenter.People:GetSkillList()

    for _, v in ipairs(skillList) do
        if self:CheckSkillIsCanUse(v.refId) then
            return true
        end
    end

    local limitTaskRef = CtrlCenter.Quest:GetLimitPopularRef()
    local isShowLimit = not table.isempty(limitTaskRef)
    if isShowLimit then
        local taskCount = #limitTaskRef.quest
        local finishCount = 0
        for _, v in ipairs(limitTaskRef.quest) do
            local refId = checknumber(v)
            local questObj = questModule:GetQuest(refId)
            if questObj and questObj.progress >= questObj.goal then
                finishCount = finishCount + 1
            end
        end
        local isFinishAll = finishCount == taskCount
        if isFinishAll then
            return true
        end
    else
        for _, v in ipairs(questList) do
            local questObj = questModule:GetQuest(v.refId)
            if questObj and questObj.state == ActivityTaskState.CanReceive then
                return true
            end
        end
    end
    return false
end
--- 居民工作红点
function LxPeopleCtrl:CheckWorkRed()
    local peopleList = ModuleCenter.People:GetHasPeopleList()
    --- 是否都在岗位上
    local isWork = true
    for _, v in pairs(peopleList) do
        if v.building <= 0 then
            isWork = false
            break
        end
    end
    if isWork then
        return false
    end
    local buildingModule = ModuleCenter.Building
    local buildingCtrl = CtrlCenter.Building
    local workList = self:GetCanWorkBuildList()
    for _, v in ipairs(workList) do
        local buildInfo = buildingCtrl:GetInnerBuildLvl(v.type)
        local curLv = buildInfo and buildInfo.level or 0
        for _, v2 in ipairs(v.worker) do
            local cdt = string.split(v2, "=")
            --- 当前工作 岗位id
            local curId = checknumber(cdt[1])
            --- 需要的等级
            local needLv = checknumber(cdt[2])
            --- 是否已经解锁
            local isUnlock = curLv >= needLv
            if not isUnlock then break end
            --- 岗位是否有人
            local workerId = buildingCtrl:CheckHasWorkerPosition(v.type, curId)
            if not workerId then
                return true
            end
        end

    end
    return false
end
--- 获取床位
function LxPeopleCtrl:GetMaxBedNum()
    local num = CtrlCenter.Building:GetAllMinHouseBedNum()
    return num
end


--- 获取对应问题的答案列表
function LxPeopleCtrl:GetAnswerList(questionId)
    local questionRefList = GameTable.PeopleQuestionTxtRef
    local showList = {}
    local beginIndex = 1 -- 问答文本索引 居民问答表refId * 10 + beginIndex
    for _, v in pairs(questionRefList) do
        local ref = questionRefList[questionId * 10 + beginIndex]
        if not ref then
            return showList
        end
        table.insert(showList, ref)
        beginIndex = beginIndex + 1
    end
end

--- 获取居民献礼文本
function LxPeopleCtrl:GetGiftDesc()
    local peopleObj
    local pList = ModuleCenter.People:GetSortHasPeopleList()
    if #pList == 1 then
        peopleObj = pList[1]
    else
        --- 健康的居民列表
        local healthList = {}
        for _, v in ipairs(pList) do
            if not v.sick then
                table.insert(healthList, v)
            end
        end
        math.randomseed(os.time())
        local randomNum = math.random(1, #healthList)
        peopleObj = healthList[randomNum]

    end
    if not peopleObj then
        return
    end
    local manageRef = self:GetPeopleManage(peopleObj.refId)
    return I18nText(manageRef.desc1, peopleObj.name)
end
--- 获取居民管理状态
--- @return V_PeopleManageRef
function LxPeopleCtrl:GetPeopleManage(refId)
    local manageList = GameTable.PeopleManageRef
    local curHour, min = self:GetGameHourAndMin(self:GetPeopleTime())
    local peopleObj = ModuleCenter.People:GetPeopleObj(refId)
    local timeRef = self:GetTimeSlotCfg(curHour)
    for _, v in ipairs(manageList) do
        if timeRef.type == PeopleTimeType.Work then
            if peopleObj.building <= 0 and table.isempty(v.build) then
                return v
            else
                for _, v2 in ipairs(v.time) do
                    if timeRef.refId == v2 and v.build and v.build[1] == peopleObj.building then
                        return v
                    end
                end
            end
        else
            for _, v2 in ipairs(v.time) do
                if timeRef.refId == v2 then
                    return v
                end
            end
        end
    end
end

--- 获取当前展示的技能列表
function LxPeopleCtrl:GetPeopleSkill()
    local skillList = GameTable.PeopleSkillRef
    local showList = {}
    for _, v in pairs(skillList) do
        local isShow = self:GetPeopleSkillIsShow(v.refId)
        if isShow then
            local _t = {}
            local isUnlock = self:GetPeopleSkillIsUnlock(v.refId)
            _t.ref = v
            _t.sort = isUnlock and 10000 + v.refId or v.refId
            table.insert(showList, _t)
        end
    end
    table.sort(showList, function(a, b) return a.sort > b.sort end)
    return showList
end

--- 获取当前等级最小的民居
function LxPeopleCtrl:GetMinLvHouse()
    local attrRefList = GameTable.PeopleAttrRef
    local buildingM = ModuleCenter.Building
    local buildingC = CtrlCenter.Building
    local refList = GameTable.BuildingRef
    local houseList
    local minId = 0
    local minLv = 999
    for _, v in ipairs(attrRefList) do
        if checknumber(v.type) == SysBuffType.Tired then
            houseList = v.jump
            break
        end
    end
    for _, v in ipairs(houseList) do
        local lv = buildingM:GetBuildingLvl(v)
        local isCanUp = buildingC:CheckBuildingIsUpGrade(v)
        local buildRef = refList[v]
        if CtrlCenter.FuncOpen:IsFuncOpen(buildRef.open) then
            if lv == 0 and isCanUp then
                minId = v
                break
            end
            if lv <= minLv then
                minId = v
                minLv = lv
            end
        end

    end
    return minId
end
--建筑居民按顺序上下岗
--- @param type number 0 下岗 1 上岗
function LxPeopleCtrl:GetSequencePosition(buildId, type, refId)
    local workers = CtrlCenter.Building:GetBuildingWorker(buildId)
    if type == 1 then
        --- 已经解锁的岗位
        local unlockPos = self:GetWorkPostByBuildingId(refId)
        for k, v in ipairs(unlockPos) do
            if workers[k] == 0 then
                return k
            end
        end
    else
        for i = #workers, 1, -1 do
            if workers[i] > 0 then
                return i
            end
        end
    end

    return -1
end

--居民是否在医院治疗
function LxPeopleCtrl:PeopleIsInHospital(refId)
    local build = ModuleCenter.Building:GetBuildingInfo(2006)--医院建筑
    if(build == nil)then
        return false
    end
    local workers = CtrlCenter.Building:GetBuildingWorker(2006);
    for i, v in ipairs(workers) do
        if(v == refId)then
            return true
        end
    end
    return false
end
--医院有床位空缺，生病居民可以去医院
function LxPeopleCtrl:PeopleCanGoHospital()
    local build = ModuleCenter.Building:GetBuildingInfo(2006)--医院建筑
    if(build == nil)then
        return false
    end
    local workers = CtrlCenter.Building:GetBuildingWorker(2006);
    for i, v in ipairs(workers) do
        if(v <= 0)then
            return true
        end
    end
    return false
end
--是否在技能的持续时间内
function LxPeopleCtrl:InSkillTime(skillId)
    local skillData = ModuleCenter.People:GetSkillObj(skillId)
    if(skillData == nil)then
        return false
    end
    if(skillData.endTime <= 0 or skillData.useTime <= 0)then
        return false
    end
    --根据当前事件判断是否在持续时间内
    local serverTime = GetTimestamp()
    if(serverTime >= skillData.useTime and serverTime <= skillData.endTime)then
        return true
    end
    return false
end
--技能剩余时间
function LxPeopleCtrl:GetSkillRemainTime(skillId)
    local inSkillTime = self:InSkillTime(skillId)
    if(inSkillTime == false)then
        return 0
    end
    local skillData = ModuleCenter.People:GetSkillObj(skillId)
    local serverTime = GetTimestamp()
    return skillData.endTime - serverTime
end
--- 获取民居建筑拥有居民数量
function LxPeopleCtrl:GetBuildPeopleLiveNum(buildId)
    local num = 0
    local peopleList = ModuleCenter.People:GetHasPeopleList()
    for _, v in pairs(peopleList) do
        if v.house == buildId then
            num = num + 1
        end
    end
    return num
end

function LxPeopleCtrl:CheckIsWaitShowHeartUp()
    return not table.isempty(self._waitShowHeartInfo)
end
function LxPeopleCtrl:ShowHeartUp()
    if table.isempty(self._waitShowHeartInfo)  then
        return
    end
    local guide = CtrlCenter.Guide:IsGuideRun()
    if(guide)then
        local cur = ModuleCenter.Guide:GetCurGuideConditionRefId()
        local triggerData = ModuleCenter.Guide:GetTriggerDataByGuideId(cur)
        if(triggerData ~= nil)then
            local triggerId = triggerData.refId or 0
            local skip = string.split(GameTable.NewPlayerGuideConfigRef.prosperityTipsGuide,"|")
            for i, v in pairs(skip) do
                if(checknumber(v) == triggerId)then
                    return
                end
            end
        else
            local skip = string.split(GameTable.NewPlayerGuideConfigRef.prosperityTipsGuide,"|")
            for i, v in pairs(skip) do
                if(checknumber(v) == cur)then
                    return
                end
            end
        end

    end
    ShowPanel(UiNames.PeopleHeartUp, self._waitShowHeartInfo)
end
function LxPeopleCtrl:ClearShowHeartInfo()
    self._waitShowHeartInfo = nil
end
--- 获取当前时刻的配置
function LxPeopleCtrl:GetCurTimeSlotRef()
    local gameTime = self:GetPeopleTime()
    local hour, _ = self:GetGameHourAndMin(gameTime)
    return self:GetTimeSlotCfg(hour)
end
--- 获取对应限时民心的结束时间
function LxPeopleCtrl:GetLimitQuestTime(refId)
    local timeStr = LxPlayerPrefs.LimitPopularQuestTime
    if string.isvalid(timeStr) then
        local strArr = string.split(timeStr, "=")
        local t1 = checknumber(strArr[1])
        if refId == t1 then
            return checknumber(strArr[2])
        end
    end
    local ref = GameTable.QuestTmieRef[refId]
    if ref then
        local curTime = GetTimestamp()
        local endTime = math.floor(curTime) + ref.time
        LxPlayerPrefs.LimitPopularQuestTime = refId .. "=" .. endTime
        return endTime
    end
    return 0
end


return LxPeopleCtrl