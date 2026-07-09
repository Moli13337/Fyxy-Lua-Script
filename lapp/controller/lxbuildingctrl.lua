local LxBaseCtrl = require("LApp.controller.LxBaseCtrl")
---@class LxBuildingCtrl:LxBaseCtrl
local LxBuildingCtrl = classX("LxBuildingCtrl", LxBaseCtrl)

function LxBuildingCtrl:Initialize()
    LxBaseCtrl.Initialize(self)
    self:InitEvent()
end

function LxBuildingCtrl:Dispose()
    LxBaseCtrl.Dispose(self)
end

function LxBuildingCtrl:InitEvent()
    self:AddEventHandler(EventNames.ON_NEWBIE_FINISHED, self.OnOpenStoveUpgrade, self)
    self:AddEventHandler(EventNames.GUIDE_FINISH, self.OnOpenStoveUpgrade, self)
end

function LxBuildingCtrl:SetStoveUpgradeData(data)
    self._stoveUpgradeData = data
end

function LxBuildingCtrl:OnOpenStoveUpgrade()
    local isRunning = ModuleCenter.Story:IsNewbieRunning()
    local isGideRun = CtrlCenter.Guide:IsGuideRun()
    if not isRunning and not isGideRun then
        if self._stoveUpgradeData then
            ShowPanel(UiNames.BuildStoveUpgrade,{curLvl = self._stoveUpgradeData.curLvl,newLvl = self._stoveUpgradeData.newLvl})
            self._stoveUpgradeData = false
        end
    end
end
function LxBuildingCtrl:OnOpenStoveUpgradeNew()
    local isRunning = ModuleCenter.Story:IsNewbieRunning()
    local isGideRun = CtrlCenter.Guide:IsGuideRun()
    --if not isRunning and not isGideRun then
        if self._stoveUpgradeData then
            ShowPanel(UiNames.BuildStoveUpgradeNew,{curLvl = self._stoveUpgradeData.curLvl,newLvl = self._stoveUpgradeData.newLvl})
            self._stoveUpgradeData = false
        end
    --end
end
function LxBuildingCtrl:CheckOpenOfflineRevenuePanel()

    local lineTime,rewardInfo = ModuleCenter.Building:GetOutlineData()
    --local pass = CtrlCenter.Story:StoryTriggerIsEnd(GameTable.StorylineConfigRef.tipsStory)
    --if(pass == false)then
    --    return
    --end
    if lineTime > 0 then
        if CtrlCenter.FuncOpen:IsFuncOpen(FuncIds.OfflineRevenue) then
            local rewardInfo = ModuleCenter.Common:NewThingsInfo(rewardInfo)
            CtrlCenter.Game:TryPopPanel(UiNames.OfflineRevenue,{rewardInfo = rewardInfo,lineTime = lineTime})
            --ShowPanel(UiNames.OfflineRevenue,{rewardInfo = rewardInfo,lineTime = lineTime})
        end
    end
end

function LxBuildingCtrl:ReceiveOfflineRevenue(pb)
    ModuleCenter.Building:SetOutlineData(0,{})
    -- local rewardInfo = ModuleCenter.Common:NewThingsInfo(pb.rewardInfo)
    if(ModuleCenter.Story:IsNewbieRunning() == false)then
        FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.BuildReward, pb.rewardInfo)
    end

    ClosePanel(UiNames.OfflineRevenue)
end

function LxBuildingCtrl:OnBuildingActiveSeat(pb)
    ModuleCenter.Building:ActiveBuildSeatInfo(pb)
    -- local seatType = pb.type
    -- if seatType == 1 then
    --     ShowSysMsg("免费体验")
    -- elseif seatType == 2 then
    --     ShowSysMsg("租用")
    -- elseif seatType == 3 then
    --     ShowSysMsg("购买")
    -- end
end


--- 建筑红点
function LxBuildingCtrl:CheckBuildRed(buildId)
    return 0
end

--建筑类型 升级都是通类型拼接id
function LxBuildingCtrl:GetBuildType(buildId)
    local cfg = GameTable.BuildingRef[buildId]
    if cfg then
        return cfg.type
    end
    return buildId
end

--主建筑升级配置
function LxBuildingCtrl:GetMainBuildUpgradeCfg(buildId,buildLvl)
    local refId = buildId * 1000 + buildLvl
    local cfg = GameTable.BuildingLvRef[refId]
    if cfg then
        return cfg
    end
    return false
end

--内建筑升级配置
function LxBuildingCtrl:GetInnerBuildUpgradeCfg(buildId,position)
    local pos = position and position or BuildInnerPosition.InnerMain
    local innerBuild = self:GetInnerBuildInfo(buildId)
    local inner = innerBuild and innerBuild[pos]
    if inner then
        local innerBuildId = inner.value
        local cfg = GameTable.BuildingInLvRef[innerBuildId]
        if cfg then
            -- local buildLvl = ModuleCenter.Building:GetBuildingLvl(buildId)
            --if buildLvl >= cfg.upLimit then
            return cfg
            --end
        end
    end
    return false
end

--是否解锁内建筑副建筑
function LxBuildingCtrl:CheckInnerBuildLock(buildId)
    local buildType = self:GetBuildType(buildId)
    local innerBuildId = buildType * 100 + BuildInnerPosition.InnerDep
    local cfg = GameTable.BuildingInRef[innerBuildId]
    if cfg and cfg.unlcok then
        local lockInfo = string.split(cfg.unlcok, "=")
        local lock1 = checknumber(lockInfo[1])
        local lock3 = checknumber(lockInfo[3])
        if lock1 == BuildInnerPosition.InnerMain then
            local buildLvl = ModuleCenter.Building:GetBuildingLvl(buildId)
            if buildLvl >= lock3 then
                return true
            end 
        end
    end
    return false
end

--是否有内建筑信息
function LxBuildingCtrl:GetInnerBuildInfo(buildId)
    local buildInfo = ModuleCenter.Building:GetBuildingInfo(buildId)
    if buildInfo then
        local innerBuild = buildInfo.ins
        local innerBuildList = {}
        for _, v in ipairs (innerBuild) do
            local inner = ModuleCenter.Common:NewIntKeyValue(v)
            table.insert(innerBuildList,inner)
        end
        table.sort(innerBuildList,function(a,b)
            return a.key < b.key
        end)
        return innerBuildList[1] and innerBuildList or false
    end
    return false
end

--内建筑所有级别配置
function LxBuildingCtrl:GetInnerBuildCfgs(buildId)
    local allInnerCfg = {}
    local cfgs = GameTable.BuildingInRef
    for key,value in pairs(cfgs) do
        if value.type == buildId then
            table.insert(allInnerCfg,value)
        end
    end
    return allInnerCfg
end

--建筑是否有居民上工
function LxBuildingCtrl:CheckBuildHasWorker(buildId)
    local workerList = self:GetBuildingWorker(buildId)
    for k,v in ipairs(workerList) do
        if v > 0 then
            return true
        end
    end
    return false
end

--建筑居民工作列表
function LxBuildingCtrl:GetBuildingWorker(buildId)
    local buildInfo = ModuleCenter.Building:GetBuildingInfo(buildId)
    if buildInfo then
        local workers = buildInfo.workers
        return workers
    end
    return {}
end
--获取建筑里有多少人
function LxBuildingCtrl:GetBuildingPeopleNum(buildId)
    local buildConfig = GameTable.BuildingRef[buildId]
    if(buildConfig.type == 2007)then
        --民居
        return 0
    end
    local list = self:GetBuildingWorker(buildId)
    local num = 0;
    if(next(list))then
        for i, v in ipairs(list) do
            if(v > 0)then
                num = num + 1
            end
        end
    end
    return num
end
--建筑居民上工位置
function LxBuildingCtrl:GetWorkPosition(buildId)
    local workers = self:GetBuildingWorker(buildId)
    local num = 0
    for _, v in ipairs(workers) do
        if v ~= 0 then
            num = num + 1
        end
    end
    return num + 1
end

--获取建筑里上工人数
function LxBuildingCtrl:GetBuildingWorkerNum(buildId)
    local workers = self:GetBuildingWorker(buildId)
    local num = 0
    for _, v in ipairs(workers) do
        if v ~= 0 then
            num = num + 1
        end
    end
    return num
end

--第二队列 试用、租用时间
function LxBuildingCtrl:GetBuildingQueueUseTime()
    local seatInfo = ModuleCenter.Building:GetSeatInfo()
    local expireTime = checknumber(seatInfo.expireTime)
    if expireTime == -1 then
        return 0,0
    end
    if seatInfo.trial then --试用
        if expireTime - GetTimestamp() > 0 then
            local totalTime = self:GetQueueCondition(BuildQueueCondition.Free)
            return expireTime,totalTime
        end
    end

    if seatInfo.hired then --租用
        if expireTime - GetTimestamp() > 0 then
            local totalTime = self:GetQueueCondition(BuildQueueCondition.Rent)
            return expireTime,totalTime
        end
    end
    return 0,0
end

--建筑建造 第二队列状态 1Speed加速 2Rent租用 3Use使用 4Test试用 5Active激活 6DontActive未激活
function LxBuildingCtrl:GetBuildingQueueState()
    local seatInfo = ModuleCenter.Building:GetSeatInfo()
    local expireTime = checknumber(seatInfo.expireTime)
    if expireTime == -1 then
        return BuildQueueState.Active
    end

    if not seatInfo.trial then
        return BuildQueueState.Test
    else
        if expireTime - GetTimestamp() > 0 then
            return BuildQueueState.Use
        end
    end
    if not seatInfo.hired then
        return BuildQueueState.Rent
    else
        if expireTime - GetTimestamp() > 0 then
            return BuildQueueState.Use
        else
            if seatInfo.trial then
                return BuildQueueState.Rent
            end
        end
    end
    return BuildQueueState.DontActive
end

--第二建造位条件 1试用 2租用 3购买
function LxBuildingCtrl:GetQueueCondition(conditionIndex)
    local siteRef = GameTable.BuildingsiteRef[QueuePosition.Two]
    local condition = siteRef.condition
    if conditionIndex == BuildQueueCondition.Buy then
        local conInfo = string.split(condition[conditionIndex], "=")
        return checknumber(conInfo[2]),conInfo
    elseif conditionIndex == BuildQueueCondition.Rent then
        local conInfo = string.split(condition[conditionIndex], "=")
        return checknumber(conInfo[4]),conInfo
    else
        local conInfo = string.split(condition[conditionIndex], "=")
        return checknumber(conInfo[3]),conInfo
    end
end

--队列建造信息
function LxBuildingCtrl:GetBuildQueueInfo(queueIndex)
    local builds = ModuleCenter.Building:GetAllBuilds()
    for buildId,buildObj in pairs(builds) do
        if buildObj.seat == queueIndex then
            if (buildObj.endTime - GetTimestamp()) > 0 then
                return buildObj
            end
        end
    end
    return nil
end

--得到建造队列数量
function LxBuildingCtrl:GetBuildQueueNum()
    local builds = ModuleCenter.Building:GetAllBuilds()
    local queueNum = 0
    for buildId,buildObj in pairs(builds) do
        if buildObj.seat > 0 then
            if (buildObj.endTime - GetTimestamp()) > 0 then
                queueNum = queueNum + 1
            end
        end
    end
    return queueNum
end

--建造位是否足够
function LxBuildingCtrl:CheckBuildQueueIsEnough()
    local queueInfo = self:GetBuildQueueInfo(QueuePosition.One)
    if not queueInfo then
        return true,QueuePosition.One
    end
    local queueInfo = self:GetBuildQueueInfo(QueuePosition.Two)
    if not queueInfo then
        local queueState = self:GetBuildingQueueState()
        if queueState == BuildQueueState.Active or queueState == BuildQueueState.Use then
            return true,QueuePosition.Two
        else
            return false,QueuePosition.Two
        end
    end
    return false,QueuePosition.Two
end

--建造队列列表
function LxBuildingCtrl:GetBuildQueueList()
    local queueInfo1 = self:GetBuildQueueInfo(QueuePosition.One)
    local queueList = {}
    local info1 = {}
    if queueInfo1 then
        info1.queueInfo = queueInfo1
    else
        info1.queueInfo = false
    end
    table.insert(queueList,info1)
    local queueInfo2 = self:GetBuildQueueInfo(QueuePosition.Two)
    local info2 = {}
    if queueInfo2 then
        info2.queueInfo = queueInfo2
    else
        info2.queueInfo = false
    end
    table.insert(queueList,info2)
    return queueList
end

--兵营生产队列列表
function LxBuildingCtrl:GetBarrackQueueList()
    local queueList = {}
    local buildLvl1 = ModuleCenter.Building:GetBuildingLvl(BuildingType.BingYingBu)
    if buildLvl1 > 0 then
        local proTask1 = ModuleCenter.Building:GetProductionTask(BuildingType.BingYingBu)
        local info1 = {}
        info1.soleriderType = BarrackSoldierEnum.BuBing
        info1.buildType = BuildingType.BingYingBu
        if proTask1 then
            info1.queueInfo = proTask1
        else
            info1.queueInfo = false
        end
        info1.barrackIcon = "public_list_shou"
        table.insert(queueList,info1)
    end
    
    local buildLvl2 = ModuleCenter.Building:GetBuildingLvl(BuildingType.BingYingQi)
    if buildLvl2 > 0 then
        local proTask2 = ModuleCenter.Building:GetProductionTask(BuildingType.BingYingQi)
        local info2 = {}
        info2.soleriderType = BarrackSoldierEnum.QiBing
        info2.buildType = BuildingType.BingYingQi
        if proTask2 then
            info2.queueInfo = proTask2
        else
            info2.queueInfo = false
        end
        info2.barrackIcon = "public_list_ren"
        table.insert(queueList,info2)
    end
    
    local buildLvl3 = ModuleCenter.Building:GetBuildingLvl(BuildingType.BingYingGong)
    if buildLvl3 > 0 then
        local proTask3 = ModuleCenter.Building:GetProductionTask(BuildingType.BingYingGong)
        local info3 = {}
        info3.soleriderType = BarrackSoldierEnum.GongBing
        info3.buildType = BuildingType.BingYingGong
        if proTask3 then
            info3.queueInfo = proTask3
        else
            info3.queueInfo = false
        end
        info3.barrackIcon = "public_list_jing"
        table.insert(queueList,info3)
    end
    return queueList
end

--主界面兵营训练队列红点
function LxBuildingCtrl:CheckBarrackRrainingRed()
    local queueList = self:GetBarrackQueueList()
    for i = 1, #queueList do
        if not queueList[i].queueInfo then
            return true
        end
    end
    return false
end

--主界面兵营训练队列红点
function LxBuildingCtrl:FireEventBarrackTaskFinish()
    FireEvent(EventNames.REFRESH_BARRACK_TASK)
end



--得到建筑的队列id
function LxBuildingCtrl:GetBuildQueueId(buildId)
    local builds = ModuleCenter.Building:GetAllBuilds()
    local queueNum = 0
    for buildId,buildObj in pairs(builds) do
        if buildObj.refId == buildId and buildObj.seat > 0 then
            return buildObj.seat
        end
    end
    return 1
end

--建筑 上工位置是否有居民 
function LxBuildingCtrl:CheckHasWorkerPosition(buildId,position)
    local workers = self:GetBuildingWorker(buildId)
    if workers[position] then
        if workers[position] ~= 0 then
            return workers[position] --居民id
        end
    end
    return false
end

--工人解锁条件
function LxBuildingCtrl:GetWorkerLockList(buildId)
    local buildRef = GameTable.BuildingRef[buildId]
    if buildRef then
        local innerRef = GameTable.BuildingInRef[buildRef.type * 100 + 1]
        if innerRef and innerRef.worker ~= nil then
            return innerRef.worker
        end
    end
    return {}
end

--内建筑等级配置
--@param buildId 建筑总表id
--@param innerPos 内建筑位置 1右边 2左边 不传为1
function LxBuildingCtrl:GetInnerBuildLvl(buildId,innerPos)
    local innerPos = innerPos or BuildInnerPosition.InnerMain
    local buildInfo = ModuleCenter.Building:GetBuildingInfo(buildId)
    if buildInfo then
        -- if innerPos == BuildInnerPosition.InnerMain then
        -- elseif innerPos == BuildInnerPosition.InnerDep then
        -- end
        local innerBuild = buildInfo.ins
        for _, v in ipairs (innerBuild) do
            local inner = ModuleCenter.Common:NewIntKeyValue(v)
            local bInRef = GameTable.BuildingInRef[inner.key]
            if bInRef.status == innerPos then
                local bInLvRef = GameTable.BuildingInLvRef[inner.value]
                return bInLvRef,inner.value
            end
        end
    end
    return false
end

--根据加速类型 得到需要的加速道具
function LxBuildingCtrl:GetNeedSpeedItemList(needSpeedType)
    local speedItemList = {}
    local itemMap = ModuleCenter.Item:GetItemMap()
    for k,v in pairs(itemMap) do
        local refId = v.refId
        local ref = LxDataHelper.GetItemRef(refId)
        if ref.type == Item_Types.T_SpeedUp then
            local typeDate = string.split(ref.typeDate, "=")
            local speedType = checknumber(typeDate[1])
            local speedTime = checknumber(typeDate[2] or 0)
            if speedType == BuildSpeedItem.Common or speedType == needSpeedType then
                table.insert(speedItemList,{itemData = v,itemRef = ref,speedTime = speedTime})
            end
        end
    end
    if #speedItemList > 1 then
        table.sort(speedItemList,function(a,b)
            return a.itemRef.sort < b.itemRef.sort
        end)
    end
    return speedItemList
end

--得到建筑加速道具
function LxBuildingCtrl:GetBuildSpeedItemList()
    local speedItemList = {}
    local itemMap = ModuleCenter.Item:GetItemMap()
    for k,v in pairs(itemMap) do
        local refId = v.refId
        local ref = LxDataHelper.GetItemRef(refId)
        if ref.type == Item_Types.T_SpeedUp then
            local typeDate = string.split(ref.typeDate, "=")
            local speedType = checknumber(typeDate[1])
            local speedTime = checknumber(typeDate[2] or 0)
            if speedType == BuildSpeedItem.Common or speedType == BuildSpeedItem.Build then
                table.insert(speedItemList,{itemData = v,itemRef = ref,speedTime = speedTime})
            end
        end
    end
    if #speedItemList > 1 then
        table.sort(speedItemList,function(a,b)
            return a.itemRef.sort < b.itemRef.sort
        end)
    end
    return speedItemList
end

--得到兵营加速道具
function LxBuildingCtrl:GetBarrackSpeedItemList()
    local speedItemList = {}
    local itemMap = ModuleCenter.Item:GetItemMap()
    for k,v in pairs(itemMap) do
        local refId = v.refId
        local ref = LxDataHelper.GetItemRef(refId)
        if ref.type == Item_Types.T_SpeedUp then
            local typeDate = string.split(ref.typeDate, "=")
            local speedType = checknumber(typeDate[1])
            local speedTime = checknumber(typeDate[2] or 0)
            if speedType == BuildSpeedItem.Common or speedType == BuildSpeedItem.Train then
                table.insert(speedItemList,{itemData = v,itemRef = ref,speedTime = speedTime})
            end
        end
    end
    if #speedItemList > 1 then
        table.sort(speedItemList,function(a,b)
            return a.itemRef.sort < b.itemRef.sort
        end)
    end
    return speedItemList
end

--得到大学科技加速道具
function LxBuildingCtrl:GetScienceSpeedItemList()
    local speedItemList = {}
    local itemMap = ModuleCenter.Item:GetItemMap()
    for k,v in pairs(itemMap) do
        local refId = v.refId
        local ref = LxDataHelper.GetItemRef(refId)
        if ref.type == Item_Types.T_SpeedUp then
            local typeDate = string.split(ref.typeDate, "=")
            local speedType = checknumber(typeDate[1])
            local speedTime = checknumber(typeDate[2] or 0)
            if speedType == BuildSpeedItem.Common or speedType == BuildSpeedItem.Science then
                table.insert(speedItemList,{itemData = v,itemRef = ref,speedTime = speedTime})
            end
        end
    end
    if #speedItemList > 1 then
        table.sort(speedItemList,function(a,b)
            return a.itemRef.sort < b.itemRef.sort
        end)
    end
    return speedItemList
end

--资源建筑资源总产出
function LxBuildingCtrl:GetBuildResTotalProduc(buildId)
    local num,totalNum = ModuleCenter.Building:GetBuildProduceResNum(buildId)
    return num,totalNum
end

--建筑资源产出速率
function LxBuildingCtrl:GetBuildResProducRate(buildId)
    -- local hasWorker = self:CheckBuildHasWorker(buildId)
    local workTime = 0
    local produce = 0
    -- if hasWorker then
    local innerBuildCfg1 = self:GetInnerBuildUpgradeCfg(buildId,BuildInnerPosition.InnerMain)
    if innerBuildCfg1 then
        local buildEffect = innerBuildCfg1.buildEffect
        for i = 1, #buildEffect do 
            local effectInfo = string.split(buildEffect[i], "=")
            local attrId = checknumber(effectInfo[1])
            local attrValue1 = checknumber(effectInfo[2])
            local attrValue2 = effectInfo[3] and checknumber(effectInfo[3]) or 0
            local attrValue3 = effectInfo[4] and checknumber(effectInfo[4]) or 0
            if attrId == SysBuffType.WorkTime then
                workTime = attrValue1
            elseif attrId == SysBuffType.ResProduce then
                produce = attrValue3
            end
        end
    end
    local innerBuildCfg2 = self:GetInnerBuildUpgradeCfg(buildId,BuildInnerPosition.InnerDep)
    if innerBuildCfg2 then
        local buildEffect = innerBuildCfg2.buildEffect
        for i = 1, #buildEffect do 
            local effectInfo = string.split(buildEffect[i], "=")
            local attrId = checknumber(effectInfo[1])
            local attrValue1 = checknumber(effectInfo[2])
            local attrValue2 = effectInfo[3] and checknumber(effectInfo[3]) or 0
            if attrId == SysBuffType.WorkTime then
                workTime = workTime + attrValue1
            end
        end
    end
    -- end
    return workTime,produce
end

--增益效果
function LxBuildingCtrl:GetInnerBuildEffect(buildId)
    local innerBuildInfo = self:GetInnerBuildInfo(buildId)
    local buildAttrList = {}
    if innerBuildInfo then
        for _, inner in ipairs (innerBuildInfo) do
            local innerBuildLvlId = inner.value
            local lvlRef = GameTable.BuildingInLvRef[innerBuildLvlId]
            if lvlRef then
                for _, v in ipairs(lvlRef.buildEffect) do
                    local attrInfo = string.split(v, "=")
                    local a1 = checknumber(attrInfo[1]) or 0
                    local a2 = checknumber(attrInfo[2]) or 0
                    local a3 = checknumber(attrInfo[3]) or 0
                    local a4 = checknumber(attrInfo[4]) or 0
                    local isItem = false
                    local effectType = a1
                    local effectValue = a2
                    if effectType == SysBuffType.FuelConsume or effectType == SysBuffType.ResProduce then
                        if #attrInfo == 3 then
                            isItem = a2
                            effectValue = a3
                        elseif #attrInfo == 4 then
                            isItem = a3
                            effectValue = a4
                        end
                    elseif effectType == SysBuffType.Tired or effectType == SysBuffType.Health then
                        if #attrInfo == 3 then
                            effectValue = a3
                        end
                    end
                    local dontHas = true
                    if not isItem or effectType == SysBuffType.ResProduce then
                        for i = 1,#buildAttrList do
                            if buildAttrList[i].effectType == effectType then
                                buildAttrList[i].effectValue = buildAttrList[i].effectValue + a2
                                dontHas = false
                                break
                            end
                        end
                    end
                    if dontHas then
                        local bEffect = {}
                        if isItem then
                            bEffect.isItem = isItem
                            bEffect.effectType = effectType
                            bEffect.effectValue = effectValue
                        else
                            bEffect.isItem = false
                            bEffect.effectType = effectType
                            bEffect.effectValue = effectValue
                        end
                        table.insert(buildAttrList,bEffect)
                    end
                end
            end
        end
    end
    return buildAttrList
end

--计算资源建筑产出
function LxBuildingCtrl:CalculateBuildProduceRes(buildId)
    local innerBuildCfg = self:GetInnerBuildUpgradeCfg(buildId)
    local resList = {}
    if innerBuildCfg then
        local buildEffect = innerBuildCfg.buildEffect
        for i = 1, #buildEffect do
            local effectInfo = string.split(buildEffect[i],"=")
            local attrId = checknumber(effectInfo[1])
            local attrValue1 = checknumber(effectInfo[2])
            local attrValue2 = effectInfo[3] and checknumber(effectInfo[3]) or 0
            local attrValue3 = effectInfo[4] and checknumber(effectInfo[4]) or 0
            local info = {}
            info.attrId = attrId
            info.attrValue1 = attrValue1
            info.attrValue2 = attrValue2
            info.attrValue3 = attrValue3
            table.insert(resList,info)
        end
    end
    return resList
end

--计算 快速建造所缺资源扣的金币数量
function LxBuildingCtrl:CalculateBuildResNeedGold(buildId)
    local buildType = self:GetBuildType(buildId)
    local buildLvl = ModuleCenter.Building:GetBuildingLvl(buildId)
    local buildRef = self:GetMainBuildUpgradeCfg(buildType,buildLvl)
    local upCostList = LxDataHelper.ParseItemList(buildRef.upCost)
    local resGold = self:CalculateResNeedGold(upCostList)
    local createTime = buildRef and buildRef.buildTime or 1
    local timeGold = self:CalculateTimeNeedGold(createTime)
    return math.ceil(resGold + timeGold)
end

--计算所缺资源需要的金币数量
function LxBuildingCtrl:CalculateResNeedGold(upCost)
    local upCostList = upCost
    local needGold = 0
    for i = 1, #upCostList do
        local cost = upCostList[i]
        local itemNum = ModuleCenter.Item:GetItemCount(cost.refId)
        if itemNum < cost.num then
            local needNum = cost.num - itemNum
            local lackResId = cost.refId
            local lackResCalRef = {}
            local resDisRef = GameTable.BuildingResDisRef
            for _,ref in pairs(resDisRef) do
                if ref.type == lackResId then
                    table.insert(lackResCalRef,ref)
                end
            end
            table.sort(lackResCalRef,function(a,b)
                return a.refId > b.refId
            end)
            for i = 1,#lackResCalRef do
                local calRef = lackResCalRef[i]
                local calNum = needNum - calRef.mix
                if calNum > 0 then
                    local need = math.ceil((calNum / calRef.base) * calRef.cost)
                    needGold = needGold + need
                    needNum = needNum - calNum
                end
            end
        end
    end
    return math.ceil(needGold)
end

--建筑升级倒计时
function LxBuildingCtrl:GetBuildUpGradeTime(buildId)
    local buildInfo = ModuleCenter.Building:GetBuildingInfo(buildId)
    if buildInfo then
        local endTime = checknumber(buildInfo.endTime)
        local needTime = endTime - GetTimestamp()
        if needTime > 0 then
            return needTime
        end
    end
    return 0
end

--计算 快速升级时间所缺的金币数量
function LxBuildingCtrl:CalculateBuildUpLvlNeedGold(buildId)
    local buildInfo = ModuleCenter.Building:GetBuildingInfo(buildId)
    local needGold = 0
    if buildInfo then
        local endTime = checknumber(buildInfo.endTime)
        local needTime = endTime - GetTimestamp()
        if needTime > 0 then
           needGold = self:CalculateTimeNeedGold(needTime)
        end
    end
    return needGold
end

--计算时间折扣 需要花费多少金币
function LxBuildingCtrl:CalculateTimeNeedGold(timeNum)
    local needGold = 0
    if timeNum > 0 then
        local lackTimeCalRef = {}
        local timeDisRef = GameTable.BuildingTimeDisRef
        for _,ref in pairs(timeDisRef) do
            table.insert(lackTimeCalRef,ref)
        end
        table.sort(lackTimeCalRef,function(a,b)
            return a.refId > b.refId
        end)
        local needTime = timeNum
        for i = 1,#lackTimeCalRef do
            local calRef = lackTimeCalRef[i]
            local calNum = needTime - calRef.mix
            if calNum > 0 then
                local need = math.ceil((calNum / calRef.base) * calRef.cost)
                needGold = needGold + need
                needTime = needTime - calNum
            end
        end
    end
    return math.ceil(needGold)
end

--打开建筑升级界面
function LxBuildingCtrl:OpenBuildUpLevelPanel(buildId,isReset)
    local buildLlv = ModuleCenter.Building:GetBuildingLvl(buildId)
    if buildLlv == 0 then
        ShowPanel(UiNames.BuildCreate,{buildId = buildId,isResetCamera = isReset})
    else
        local buildType = self:GetBuildType(buildId)
        if buildType == BuildingType.HuoLu then
            ShowPanel(UiNames.BuildStove,{buildId = buildId,isResetCamera = isReset})
            local upGradeTime = self:GetBuildUpGradeTime(buildId)
            if upGradeTime > 0 then
                ShowPanel(UiNames.BuildCreateTwo,{buildId = buildId})
            end
        else
            if ResourceBuilding[buildType] then --资源建筑
                local upGradeTime = self:GetBuildUpGradeTime(buildId)
                ShowPanel(UiNames.BuildUpGrade,{buildId = buildId,isResetCamera = isReset})
                if upGradeTime > 0 then
                    ShowPanel(UiNames.BuildCreateTwo,{buildId = buildId})
                end
            else
                ShowPanel(UiNames.BuildCreateTwo,{buildId = buildId,isResetCamera = isReset})
            end
        end
    end
    
end

--是否满足升级条件
function LxBuildingCtrl:CheckBuildingIsUpGrade(buildId)
    if self:CheckBuildingIsUpGrade1(buildId) and self:CheckBuildingIsUpGrade2(buildId) then
        return true
    else
        return false
    end
end

--是否满足建筑前置升级条件
function LxBuildingCtrl:CheckBuildingIsUpGrade1(buildId)
    local buildType = self:GetBuildType(buildId)
    local buildLvl = ModuleCenter.Building:GetBuildingLvl(buildId)
    local buildRef = self:GetMainBuildUpgradeCfg(buildType,buildLvl)
    local upLimit = buildRef.upLimit
    if upLimit then
        for i = 1, #upLimit do 
            local limit = string.split(upLimit[i], "=")
            local v1 = checknumber(limit[1])
            local v2 = checknumber(limit[2])
            local v3 = checknumber(limit[3])
            if v1 == BuildLimitType.Main then
                local buildLvl = ModuleCenter.Building:GetBuildingLvl(v2)
                if buildLvl < v3 then
                    return false
                end
            end
        end
    end
    return true
end

--是否满足建筑消耗材料升级条件
function LxBuildingCtrl:CheckBuildingIsUpGrade2(buildId)
    local buildType = self:GetBuildType(buildId)
    local buildLvl = ModuleCenter.Building:GetBuildingLvl(buildId)
    local buildRef = self:GetMainBuildUpgradeCfg(buildType,buildLvl)
    local upCostList = LxDataHelper.ParseItemList(buildRef.upCost)
    if not CtrlCenter.Item:CheckItemListEnough(upCostList,false) then
        return false
    end
    return true
end

--计算升级最低等级的建筑
function LxBuildingCtrl:CalculateBuildMinLvl()
    local buildLists = {}
    for i, v in pairs(GameTable.BuildingRef) do
        if CtrlCenter.FuncOpen:IsFuncOpen(v.open) and not self:CheckBuildMaxLvl(v.refId) then
            local upGradeTime = self:GetBuildUpGradeTime(v.refId)
            if upGradeTime <= 0 then
                local buildLvl = ModuleCenter.Building:GetBuildingLvl(v.refId)
                table.insert(buildLists,{buildId = v.refId,buildLvl = buildLvl,sort = v.sort})
            end
        end
    end
    table.sort(buildLists,function(a,b)
        if a.buildLvl == b.buildLvl then
            return a.sort < b.sort
        else
            return a.buildLvl < b.buildLvl
        end
    end)
    return buildLists[1]
end

--所有民居的床位
function LxBuildingCtrl:GetAllMinHouseBedNum()
    local bedNum = 0
    for i, v in pairs(GameTable.BuildingRef) do
        if v.type == BuildingType.MinHouse then
            local num = self:GetMinHouseBedNum(v.refId)
            bedNum = bedNum + num
        end
    end
    return bedNum
end

--获取民居的床位
function LxBuildingCtrl:GetMinHouseBedNum(buildId)
    local bedNum = 0
    local innerBuildCfg = self:GetInnerBuildUpgradeCfg(buildId)
    if innerBuildCfg then
        local buildEffect = innerBuildCfg.buildEffect
        for i = 1, #buildEffect do 
            local effectInfo = string.split(buildEffect[i], "=")
            local attrId = checknumber(effectInfo[1])
            local attrValue1 = checknumber(effectInfo[2])
            if attrId == SysBuffType.Bed then
                bedNum = bedNum + attrValue1
            end
        end
    end
    return bedNum
end

--兵营建筑训练容量
function LxBuildingCtrl:GetBuildTrainingCapacity(buildId)
    local buildType = self:GetBuildType(buildId)
    local buildLvl = ModuleCenter.Building:GetBuildingLvl(buildId)
    local buildCfg = self:GetMainBuildUpgradeCfg(buildId,buildLvl)
    local buildEffect = buildCfg and buildCfg.buildEffect or false
    if buildEffect then
        for i = 1, #buildEffect do 
            local effectInfo = string.split(buildEffect[i], "=")
            local attrId = checknumber(effectInfo[1])
            local attrValue = checknumber(effectInfo[3])
            if attrId == SysBuffType.TrainingCapacity then
                return attrValue
            end
        end
    end
    return 0
end

--兵营士兵的属性
function LxBuildingCtrl:GetBarrackSoldierAttrInfo(soldierId,maxSoldierId)
    local soldierRef = GameTable.SoldierRef[soldierId]
    local soldierAttrList = {}
    if soldierRef then
        local soldierList = {}
        for k,v in pairs(GameTable.SoldierRef) do 
            if v.type == soldierRef.type then
                table.insert(soldierList,v)
            end
        end
        table.sort(soldierList,function(a,b)
            return a.rank > b.rank
        end)
        local disPlayAttr = soldierRef.displayAttr
        local maxDisPlayAttr = soldierList[1].displayAttr
        local info = {}
        info.refId = 0
        info.attrName = I18nText(9413)
        info.attrIcon = "icon_attr_201"
        info.attrDes = ""
        info.valuePro = soldierRef.power / soldierList[1].power
        info.attrValue = soldierRef.power
        table.insert(soldierAttrList,info)
        for i = 1,#disPlayAttr do
            local disAttr = string.split(disPlayAttr[i], "=")
            local maxDisAttr = string.split(maxDisPlayAttr[i], "=")
            local attrId = checknumber(disAttr[1])
            local attrValue = checknumber(disAttr[2])
            local attrNextValue = checknumber(maxDisAttr[2])
            local comRef = LxDataHelper.GetCombatAttributeRef(attrId)
            if comRef then
                local info = {}
                info.refId = attrId
                info.attrName = I18nText(comRef.name)
                info.attrIcon = comRef.icon
                info.attrDes = I18nText(comRef.description)
                info.valuePro = attrValue / attrNextValue
                info.attrValue = LxDataHelper.ConvertAttrValue(attrId,attrValue)
                table.insert(soldierAttrList,info)
            end
        end
    
    end
    return soldierAttrList
end

function LxBuildingCtrl:ClearProductionTask(id)
    local allPTasks = ModuleCenter.Building:GetAllProductionTask()
    for k, task in pairs(allPTasks) do
        if task.id == id then
            ModuleCenter.Building:ClearProductionTask(task.building)
            break
        end
    end
end

function LxBuildingCtrl:GetProductionTaskTypeById(id)
    local allPTasks = ModuleCenter.Building:GetAllProductionTask()
    for k, task in pairs(allPTasks) do
        if task.id == id then
            return task.taskType
        end
    end
    return nil
end

function LxBuildingCtrl:CheckProductionTaskFinish(buildId)
    local pTask = ModuleCenter.Building:GetProductionTask(buildId)
    if pTask then
        local trainTimes = pTask.endTime
        if trainTimes > 0 and trainTimes <= GetTimestamp() then
            return true
        end
    end
    return false
end

--兵营是否有训练、晋升状态
function LxBuildingCtrl:CheckIsProductionTask(buildId)
    local pTask = ModuleCenter.Building:GetProductionTask(buildId)
    if pTask then
        local trainTimes = pTask.endTime
        if trainTimes > 0 and trainTimes > GetTimestamp() then
            return true
        end
    end
    return false
end

--计算兵营快速训练、加速所缺资源扣的金币数量
function LxBuildingCtrl:CalculateBarrackTrainNeedGold(buildId,soldierId,selNum,costList)
    local pTask = ModuleCenter.Building:GetProductionTask(buildId)
    local needGold = 0
    if pTask then
        local trainTimes = pTask.endTime
        local curTime = trainTimes - GetTimestamp()
        if curTime > 0 then
            needGold = self:CalculateTimeNeedGold(curTime)
        end
    else
        local soldierRef = GameTable.SoldierRef[soldierId]
        local totalTime = math.floor(soldierRef.traningT / 1000 * selNum)
        local needCostList = {}
        for i = 1,#costList do
            local needCost = {}
            needCost.type = costList[i].type
            needCost.refId = costList[i].refId
            needCost.num = costList[i].num * selNum
            table.insert(needCostList,needCost)
        end
        local needGold1 = self:CalculateTimeNeedGold(totalTime)
        local needGold2 = self:CalculateResNeedGold(needCostList)
        needGold = needGold1 + needGold2
    end
    
    return math.ceil(needGold)
end

--计算大学科技立即完成或升级所需要的金币数量
function LxBuildingCtrl:CalculateScienceNeedGold(buildId, scienceGroupId)
    local needGold = 0
    local remainTime = ModuleCenter.Science:GetScienceUplevelReallyCostTime(scienceGroupId)
    if remainTime > 0 then
        needGold = self:CalculateTimeNeedGold(remainTime)
    end

    return math.ceil(needGold)
end

--建筑是否满级
function LxBuildingCtrl:CheckBuildMaxLvl(buildId)
    local buildLvl = ModuleCenter.Building:GetBuildingLvl(buildId)
    local buildType = self:GetBuildType(buildId)
    local buildRef = self:GetMainBuildUpgradeCfg(buildType,buildLvl)
    local buildTime = buildRef.buildTime
    if buildTime == -1 then
        return true
    end
    return false
end

--建筑升级 操作界面
function LxBuildingCtrl:UpgradeBuildingClosePanel(buildId,closeQueue)
    local buildType = self:GetBuildType(buildId)
    if ResourceBuilding[buildType] then --资源建筑
        if IsOpenPanel(UiNames.BuildCreateTwo) then
            ClosePanel(UiNames.BuildCreateTwo)
        end
    end
    
    if closeQueue then
        if IsOpenPanel(UiNames.BuildQueue) then
            local uiCtrl = MgrCenter.PanelMgr:GetPanelCtrl(UiNames.BuildQueue)
            if uiCtrl then
                uiCtrl:RefreshAllQueue()
            end
        end
    end
end

--资源不足打开相关界面
function LxBuildingCtrl:ResNotHasOpenPanel(upCostList,self)
    
    local isShowResPanel = false
    local resPageList = {}
    for k,v in pairs(GameTable.BuildingResRef) do 
        table.insert(resPageList,v)
    end
    table.sort(resPageList, function(a, b)
        return a.refId < b.refId
    end)

    for i = 1, #upCostList do
        local hasNum = ModuleCenter.Item:GetItemCount(upCostList[i].refId)
        local needNum = upCostList[i].num
        local checkRes = false
        for j = 1,#resPageList do
            if resPageList[j].item == upCostList[i].refId then
                checkRes = true
                break
            end
        end
        if checkRes and hasNum < needNum then
            isShowResPanel = true
            break
        end
    end
    if isShowResPanel then
        ShowPanel(UiNames.BuildGainRes,{upCostList = upCostList})
        return false
    else
        if not CtrlCenter.Item:CheckItemListEnough(upCostList,true,self:GetUiName()) then
            return false
        else
            return true
        end
    end
    -- local coinInfo = {}
    -- local otherInfo = {}
    -- for i = 1,#costList do
    --     local refId = costList[i].refId
    --     if refId == Item_Ids.SilverCoin then
    --         table.insert(coinInfo,costList[i])
    --     else
    --         table.insert(otherInfo,costList[i])
    --     end
    -- end

    -- if #otherInfo > 0 then
    --     if not CtrlCenter.Item:CheckItemListEnough(otherInfo,false,self:GetUiName()) then
    --         ShowPanel(UiNames.BuildGainRes,{upCostList = otherInfo})
    --         return false
    --     end
    -- end

    -- if #coinInfo > 0 then
    --     if not CtrlCenter.Item:CheckItemListEnough(coinInfo,true,self:GetUiName()) then
    --         return false
    --     end
    -- end
    
end

--计算建造、升级时间
function LxBuildingCtrl:CalculateBuildTotalTime(buildTime)
    local skillData = ModuleCenter.People:GetSkillObj(1005) --民心技能 提供缩短时间
    local curTime = GetTimestamp()
    local timePer = 0
    if skillData then
        local skillRef = CtrlCenter.People:GetSkillRef(skillData.refId)
        if skillRef then
            local endTime = skillData.endTime
            if endTime > curTime then
                local effectValue = skillRef.value
                for i = 1, #effectValue do 
                    local effectInfo = string.split(effectValue[i], "=")
                    local attrId = checknumber(effectInfo[1])
                    local attrValue2 = checknumber(effectInfo[2])
                    local attrValue3 = checknumber(effectInfo[3]) or 0
                    if attrId == SysBuffType.BuildCreateTime then
                        timePer = timePer + math.abs(attrValue3)
                        break
                    end
                end
            end
        end
    end
    local cardObj = ModuleCenter.MonthCard:GetCardObj(4) --月卡 提供缩短时间
    if cardObj then
        local monthActive = false
        if checknumber(cardObj.time) == -1 then
            monthActive = true
        else
            local endTime = cardObj.time / 1000;
            local timeTick = endTime - curTime
            if timeTick > 0 then
                monthActive = true
            end
        end
        if monthActive then
            local ref = GameTable.MonthlyCardRef[4]
            if ref then
                local effectValue = ref.buffList
                for i = 1, #effectValue do 
                    local effectInfo = string.split(effectValue[i], "=")
                    local attrId = checknumber(effectInfo[1])
                    local attrValue2 = checknumber(effectInfo[2])
                    local attrValue3 = checknumber(effectInfo[3]) or 0
                    if attrId == SysBuffType.BuildCreateTime then
                        timePer = timePer + math.abs(attrValue3)
                        break
                    end
                end
            end
        end
    end

    local endTime = ModuleCenter.Vip:GetVipEndTime()
    local timeTick = endTime - curTime
    if timeTick > 0 then
        local curVipLv = ModuleCenter.Role:GetRoleVipLevel()
        local list = ModuleCenter.Vip:GetVipPrivilegeDesc(curVipLv)
        for i = 1,#list do
            local effectValue = list[i].sysBuffRefId
            if effectValue then
                for j = 1, #effectValue do 
                    local effectInfo = string.split(effectValue[j], "=")
                    local attrId = checknumber(effectInfo[1])
                    local attrValue2 = checknumber(effectInfo[2])
                    local attrValue3 = checknumber(effectInfo[3]) or 0
                    if attrId == SysBuffType.BuildCreateTime then
                        timePer = timePer + math.abs(attrValue3)
                        break
                    end
                end
            end
        end
    end
    local needBuildTime = buildTime - (buildTime * timePer)
    return needBuildTime
end

--计算建筑建造、升级时间可免费升级
function LxBuildingCtrl:CalculateBuildFreeTime()
    local skillData = ModuleCenter.People:GetSkillObj(1003) --民心技能 升级时间提供免費完成
    local freeTime = 0
    if skillData then
        local skillRef = CtrlCenter.People:GetSkillRef(skillData.refId)
        if skillRef then
            local endTime = skillData.endTime
            if endTime > GetTimestamp() then
                local effectValue = skillRef.value
                for i = 1, #effectValue do 
                    local effectInfo = string.split(effectValue[i], "=")
                    local attrId = checknumber(effectInfo[1])
                    local attrValue2 = checknumber(effectInfo[2])
                    if attrId == SysBuffType.BuildFreeCreateTime then
                        freeTime = freeTime + attrValue2
                        break
                    end
                end
            end
        end
    end
    return freeTime 
end

--获取某个建筑的属性值
function LxBuildingCtrl:CheckSysIdGetBuildBuffValue(buildId,sysBuffId)
    local buildType = self:GetBuildType(buildId)
    local buildLvl = ModuleCenter.Building:GetBuildingLvl(buildId)
    local buildRef = self:GetMainBuildUpgradeCfg(buildType,buildLvl)
    if buildRef then
        local buildEffect = buildRef.buildEffect
        if buildEffect then
            for i = 1, #buildEffect do 
                local effectInfo = string.split(buildEffect[i], "=")
                local attrId = checknumber(effectInfo[1])
                local attrValue = checknumber(effectInfo[2])
                if attrId == sysBuffId then
                    return attrValue
                end
            end
        end
    end
    return 0
end
---获取建筑里副建筑列表
function LxBuildingCtrl:GetInnerDepBuildings(buildId)
    local res = {}
    local buildRef = GameTable.BuildingRef[buildId]

    local innerCfgList = self:GetInnerBuildCfgs(buildRef.type)
    for i, v in pairs(innerCfgList) do
        if(v.status == BuildInnerPosition.InnerDep)then
            table.insert(res,v.refId)
        end
    end
    return res
end

---获取建筑内主建筑配置
function LxBuildingCtrl:GetInnerMainBuilding(buildId)
    local buildRef = GameTable.BuildingRef[buildId]
    local innerCfgList = self:GetInnerBuildCfgs(buildRef.type)
    for i, v in pairs(innerCfgList) do
        if(v.status == BuildInnerPosition.InnerMain)then
            return v
        end
    end
    return nil
end

---军医所 士兵免费治疗数量/免费治疗容量
function LxBuildingCtrl:GetMilitaryTreatmentFreeNum()
    local soldierModule = ModuleCenter.Soldier
    local freeCount = soldierModule:GetFreeTreatCount()
    local totalFreeCount = self:CheckSysIdGetBuildBuffValue(BuildingType.JunYiSuo,SysBuffType.TreatFreeSoldier)
    local canMilitaryNum = totalFreeCount - freeCount
    if canMilitaryNum <= 0 then
        canMilitaryNum = 0
    end
    return freeCount,canMilitaryNum,totalFreeCount
end

---建筑生产时间、产出值
function LxBuildingCtrl:GetBuildingWorkerTimeProduc(buildId)
    local buildAttrList = self:GetInnerBuildEffect(buildId)
    local needWorkTime = 5
    local produceValue = 0
    local workerNum = self:GetBuildingWorkerNum(buildId)
    for i = 1, #buildAttrList do
        local effectType = buildAttrList[i].effectType
        if effectType == SysBuffType.WorkTime then
            needWorkTime = buildAttrList[i].effectValue
        elseif effectType == SysBuffType.ResProduce then
            produceValue = buildAttrList[i].effectValue * workerNum
        elseif effectType == SysBuffType.Satiety then
            produceValue = buildAttrList[i].effectValue * workerNum
        end
    end
    local hasTimes = needWorkTime
    local totalTime = GetTimestamp() + hasTimes
    local state = BuildWorkState.Free
    local isWorker = self:CheckBuildHasWorker(buildId)
    if isWorker then
        local slotRef = CtrlCenter.People:GetCurTimeSlotRef()
        if slotRef then
            if slotRef.type == PeopleTimeType.Sleep then
                state = BuildWorkState.Free
            elseif slotRef.type == PeopleTimeType.Work then
                state = BuildWorkState.Work
            else
                state = BuildWorkState.Dine
            end
        end
    end
    local buildType = self:GetBuildType(buildId)
    local bResId = buildType * 10 + state
    local buildStateRef = GameTable.BuildingResStateRef[bResId]
    if buildStateRef and (buildStateRef.type == BuildWorkState.Work or buildStateRef.type == BuildWorkState.Dine) then
        return hasTimes,totalTime,produceValue
    else
        return 0,0,0
    end
end

--军医所 免费治疗伤兵 需要总时间
function LxBuildingCtrl:CalculateTreatSoldierNeedTotalTime()
    local proTask = ModuleCenter.Building:GetProductionTask(BuildingType.JunYiSuo)
    local treatmentTime = 0
    local totalNum = 0
    if proTask then
        local treatSoldiers = proTask.treatSoldiers
        for i = 1, #treatSoldiers do
            local soldierInfo = string.split(treatSoldiers[i], "=")
            local soldierId = checknumber(soldierInfo[1])
            local soldierNum = checknumber(soldierInfo[2])
            local soldierRef = GameTable.SoldierRef[soldierId]
            if soldierRef then
                treatmentTime = treatmentTime + math.floor(soldierRef.treatmentTime / 1000 * soldierNum)
                totalNum = totalNum + soldierNum
            end
        end
    end
    return treatmentTime,totalNum
end

--计算治疗伤兵生产数量
function LxBuildingCtrl:GetProductionTaskSoldierNum(refId)
    local proTask = ModuleCenter.Building:GetProductionTask(BuildingType.JunYiSuo)
    if proTask then
        local treatSoldiers = proTask.treatSoldiers
        for i = 1, #treatSoldiers do
            local soldierInfo = string.split(treatSoldiers[i], "=")
            local soldierId = checknumber(soldierInfo[1])
            local soldierNum = checknumber(soldierInfo[2])
            if soldierId == refId then
                return soldierNum
            end
        end
    end
    return 0
end

--检测选择升级伤兵是否是最大免费数量
function LxBuildingCtrl:CheckHurtSoldierMaxFreeNum(selectMaxNum)
    local freeCount = ModuleCenter.Soldier:GetFreeTreatCount()
    local totalFreeCount = self:CheckSysIdGetBuildBuffValue(BuildingType.JunYiSuo,SysBuffType.TreatFreeSoldier)
    local canMilitaryNum = totalFreeCount - freeCount
    if selectMaxNum >= canMilitaryNum then
        return true
    else
        return false
    end
end

--计算治疗伤兵完成数量
function LxBuildingCtrl:GetProductionSoldierFinishList()
    local proTask = ModuleCenter.Building:GetProductionTask(BuildingType.JunYiSuo)
    local finishList = {}
    if proTask then
        local treatSoldiers = proTask.treatSoldiers
        for i = 1, #treatSoldiers do
            local soldierInfo = string.split(treatSoldiers[i], "=")
            local soldierId = checknumber(soldierInfo[1])
            local soldierNum = checknumber(soldierInfo[2])
            if soldierId > 0 then
                table.insert(finishList,{refId = soldierId,num = soldierNum})
            end
        end
    end
    table.sort(finishList, function(a, b)
        local aCfg = GameTable.SoldierRef[a.refId]
        local bCfg = GameTable.SoldierRef[b.refId]
        if aCfg.rank == bCfg.rank then
            return aCfg.refId < bCfg.refId
        else
            return aCfg.rank > bCfg.rank
        end
    end)
    return finishList
end

function LxBuildingCtrl:CheckTreatHasFreeNum()
    local totalFreeCount = self:CheckSysIdGetBuildBuffValue(BuildingType.JunYiSuo,SysBuffType.TreatFreeSoldier)
    if totalFreeCount > 0 then
        local freeCount = ModuleCenter.Soldier:GetFreeTreatCount()
        local canMilitaryNum = totalFreeCount - freeCount
        return canMilitaryNum > 0
    end
    return false
end

return LxBuildingCtrl