---
--- Created by wzz.
--- DateTime: 2024/7/4
--- 鱼场

---@class ModelFish:LModel
local ModelFish = LxClass("ModelFish", LModel)

local string = string

ModelFish.MainFuncId = 35000000
ModelFish.FastFishId = 35000100

-- 釣魚助力礼包商店id
ModelFish.FishShopGifgId = 1009

-- 任务状态
ModelFish.TaskState = {
    -- 未完成
    UnCompleted = 0,
    -- 可领取
    Completed = 1,
    -- 已领取
    Received = 2,
}


function ModelFish:ModelFish()
    -- 当前所在的鱼场id
    self._curRefId = 1

    -- 当前使用鱼竿
    self._fishingRod = 0

    -- 当前使用鱼饵
    self._fishingBait = 0

    -- 玩法关闭时间,秒 开启中有效
    self._closeTime = 0

    -- 下次开启时间,秒 未开启有效
    self._openTime = 0

    -- 0-未开启,1-开启中
    self._state = 0

    -- 已钓鱼次数
    self._fishingCount = 0

    -- 最大解锁鱼
    self._maxUnlockRefId = self._curRefId

    -- 鱼釭等级
    self._fishTankLev = 0

    -- 鱼釭属性
    self._fishTankAttrList = {}

    -- 当前钩到的物品数据
    self._theBaitObj = nil

    -- 鱼釭里的鱼数据
    self._fishTankObjMap = {}

    -- 暂存鱼数据
    self._backpackMap = {}

    -- 钓鱼图鉴_激活信息
    self._fishHandbookObjMap = {}

    -- 钓鱼图鉴_属性
    self._fishHandbookAttrList = {}

    -- 羁绊图鉴数据
    self._fishFetterObjMap = {}

    -- 任务数据
    self._fishingOrderObjList = {}

    -- 已查看的鱼场
    self._hadLookNewFarmMap = {}

    -- 任务 基础信息
    self._taskBaseInfo = {
        -- 剩余重置次数
        remainResetCount = 0,
        -- 已使用体力
        usedEnergy = 0,
        -- 体力完成需要次数
        maxEnergy = 0,
    }

    -- 钓鱼技能等级信息
    self._fishingSkillLevMap = {}

    -- 鱼助力礼包商店配置
    self._shopGifgRef = GameTable.StoreBasicsDateRef[ModelFish.FishShopGifgId]

    -- 玩法结束自动出售获得
    self._endThings = ""

    self:InitRef()
end

function ModelFish:OnModelInit()
    self:ModelNetMsgRecv(LProtoIds.FishingDataResp, function(...) self:OnFishingDataResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.FishingResp, function(...) self:OnFishingResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.SwitchFishBaitResp, function(...) self:OnSwitchFishBaitResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.SellFishResp, function(...) self:OnSellFishResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.SettleFishingResp, function(...) self:OnSettleFishingResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.UpgradeAquariumResp, function(...) self:OnUpgradeAquariumResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.FishHandBookListResp, function(...) self:OnFishHandBookListResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.FishFetterListResp, function(...) self:OnFishFetterListResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.FishHandBookActiveResp, function(...) self:OnFishHandBookActiveResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.FishFetterActiveResp, function(...) self:OnFishFetterActiveResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.SwitchFishSceneResp, function(...) self:OnSwitchFishSceneResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.FishingSkillResp, function(...) self:OnFishingSkillResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.FishingOrderListResp, function(...) self:OnFishingOrderListResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.FishingOrderReceiveResp, function(...) self:OnFishingOrderReceiveResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.RefreshFishingOrderResp, function(...) self:OnRefreshFishingOrderResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.FishingRemoveEndResp, function(...) self:OnFishingRemoveEndResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.FishingShowSceneResp, function(...) self:OnFishingShowSceneResp(...) end)
end

--在协议数据处理完之后需要调用finish
function ModelFish:OnModelRequest()
    if gModelFunctionOpen:CheckIsOpened(ModelFish.MainFuncId, false) then
        self:FishHandBookListReq()
        self:FishFetterListReq()
        self:FishingSkillReq(0)
        -- self:FishingOrderListReq() -- 主推
    end

    self:ModelFinish()
end

-- region 协议 ----------------------------------------------------

-- 钓鱼系统信息,登录下发
function ModelFish:OnFishingDataResp(pb)
    -- 鱼缸信息
    local aquarium = pb.aquarium
    self._fishTankLev = aquarium.level
    self._fishTankObjMap = {}
    for _, fishObj in ipairs(aquarium.fishes) do
        self._fishTankObjMap[fishObj.refId] = fishObj
    end
    self._fishTankAttrList = aquarium.attrs

    self._backpackMap = {}
    for _, fishObj in ipairs(pb.backpack) do
        self._backpackMap[fishObj.id] = fishObj
    end

    if pb:HasField("theBait") then
        self._theBaitObj = pb.theBait
    end

    for i, v in ipairs(pb.showScenes) do
        self._hadLookNewFarmMap[v] = true
    end

    self._curRefId     = pb.currentScene
    self._fishingRod   = pb.fishingRod
    self._fishingBait  = pb.fishingBait
    self._state        = pb.state
    self._fishingCount = pb.fishingCount
    self._openTime     = pb.openTime
    self._closeTime    = pb.closeTime

    self:SetEndThings(pb.endThings)

    -- 商店数据
    gModelShop:ShopListReq(self._shopGifgRef.refId)
    local ref = self:GetConfigRef()
    gModelShop:ShopListReq(ref.fishingShop)

    self:InitLookFishFarm()

    FireEvent(EventNames.FISH_BASE_INFO)
end

-- 请求钓鱼 请求
function ModelFish:FishingReq(autoFishing)
    local pb = LProtoHelper.CreateProto(LProtoIds.FishingReq)
    pb.autoFishing = autoFishing
    SendMessage(pb, LProtoIds.FishingReq)
end

-- 请求钓鱼 返回
function ModelFish:OnFishingResp(pb)
    self._fishingCount = pb.fishingCount
    self._taskBaseInfo.usedEnergy = pb.usedEnergy

    local theBait = nil
    if pb:HasField("theBait") then
        theBait = pb.theBait
    end

    if pb:HasField("handbook") then
        self._fishHandbookObjMap[pb.handbook.fish.refId] = pb.handbook
    end

    if pb.autoFishing == 0 then
        FireEvent(EventNames.FISH_RETURN, { theBait = theBait })
    elseif pb.autoFishing == 2 then
        FireEvent(EventNames.FISH_FAST, { theBait = theBait })
    end

    FireEvent(EventNames.FISH_BASE_INFO)
end

-- 替换鱼饵/鱼竿 请求
function ModelFish:SwitchFishBaitReq(type, itemRefId)
    local pb = LProtoHelper.CreateProto(LProtoIds.SwitchFishBaitReq)
    --  0-替换鱼竿,1-替换鱼饵
    pb.type = type
    pb.itemRefId = itemRefId
    SendMessage(pb, LProtoIds.SwitchFishBaitReq)
end

-- 替换鱼饵/鱼竿 返回
function ModelFish:OnSwitchFishBaitResp(pb)
    if pb.type == 0 then
        self._fishingRod = pb.itemRefId
    else
        self._fishingBait = pb.itemRefId
    end

    FireEvent(EventNames.FISH_BASE_INFO)
end

-- 出售鱼缸内/上钩的鱼 请求
function ModelFish:SellFishReq(type, id)
    local pb = LProtoHelper.CreateProto(LProtoIds.SellFishReq)
    -- 0-上钩的鱼,1-鱼缸内的鱼
    pb.type = type
    pb.id = id
    SendMessage(pb, LProtoIds.SellFishReq)
end

-- 出售鱼缸内/上钩的鱼 返回
function ModelFish:OnSellFishResp(pb)
    if pb.type == 2 then
        for k, v in pairs(self._backpackMap) do
            if v.id == pb.id then
                self._backpackMap[k] = nil
                break
            end
        end
        FireEvent(EventNames.FISH_BASE_INFO)
    end
    GF.CloseWndByName("UIFishGet")
end

-- 放入鱼缸 请求
function ModelFish:SettleFishingReq(type, id, replaceId)
    local pb = LProtoHelper.CreateProto(LProtoIds.SettleFishingReq)
    -- 0-保存,1-替换
    pb.type = type
    pb.id = id
    pb.replaceId = replaceId or 0
    SendMessage(pb, LProtoIds.SettleFishingReq)
end

-- 放入鱼缸 返回
function ModelFish:OnSettleFishingResp(pb)
    local fishObj = pb.handbook.fish
    if pb.type == 1 then
        for k, v in pairs(self._fishTankObjMap) do
            if v.id == pb.id then
                self._fishTankObjMap[k] = nil
                break
            end
        end
        GF.CloseWndByName("UIFishGet")
    else
        GF.ShowMessage(ccClientText(44330))
    end

    if pb.type == 2 then
        self._backpackMap[fishObj.id] = fishObj
    elseif pb.type == 3 or pb.type == 4 then
        self._backpackMap[fishObj.id] = nil
    end

    if pb.type ~= 2 then
        self._fishTankObjMap[fishObj.refId] = fishObj
        self._fishHandbookObjMap[fishObj.refId] = pb.handbook
    end

    -- GF.CloseWndByName("UIFishTankDetail")
    GF.CloseWndByName("UIFishReplace")
    FireEvent(EventNames.FISH_BASE_INFO)
end

-- 升级鱼缸 请求
function ModelFish:UpgradeAquariumReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.UpgradeAquariumReq)
    SendMessage(pb, LProtoIds.UpgradeAquariumReq)
end

-- 升级鱼缸 返回
function ModelFish:OnUpgradeAquariumResp(pb)
    local aquarium = pb.aquarium
    self._fishTankLev = aquarium.level
    for _, fishObj in ipairs(aquarium.fishes) do
        self._fishTankObjMap[fishObj.refId] = fishObj
    end
    self._fishTankAttrList = aquarium.attrs


    FireEvent(EventNames.FISH_BASE_INFO)
end

-- 钓鱼图鉴_列表数据 请求
function ModelFish:FishHandBookListReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.FishHandBookListReq)
    SendMessage(pb, LProtoIds.FishHandBookListReq)
end

-- 钓鱼图鉴_列表数据 返回
function ModelFish:OnFishHandBookListResp(pb)
    for k, obj in ipairs(pb.handbooks) do
        self._fishHandbookObjMap[obj.fish.refId] = obj
    end

    self._fishHandbookAttrList = pb.attrs
end

-- 钓鱼图鉴_激活属性 请求
function ModelFish:FishHandBookActiveReq(type, fishRefId, id)
    local pb = LProtoHelper.CreateProto(LProtoIds.FishHandBookActiveReq)
    -- 0-激活属性 1-激活图鉴 2-领取激活奖励
    pb.type = type
    pb.fishRefId = fishRefId
    pb.id = id or 0
    SendMessage(pb, LProtoIds.FishHandBookActiveReq)
end

-- 钓鱼图鉴_激活属性 返回
function ModelFish:OnFishHandBookActiveResp(pb)
    for k, obj in ipairs(pb.handbooks) do
        self._fishHandbookObjMap[obj.fish.refId] = obj
    end

    local data = self._fishHandbookObjMap[pb.fishRefId]
    data.activeCount = pb.activeCount

    if #pb.attrs > 0 then
        self._fishHandbookAttrList = pb.attrs
    end

    if pb.type == 3 then
        self._backpackMap[pb.id] = nil
    end

    FireEvent(EventNames.FISH_BASE_INFO)

    GF.ShowMessage(ccClientText(44290))
end

-- 羁绊图鉴数据 请求
function ModelFish:FishFetterListReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.FishFetterListReq)
    SendMessage(pb, LProtoIds.FishFetterListReq)
end

-- 羁绊图鉴数据 返回
function ModelFish:OnFishFetterListResp(pb)
    for k, obj in ipairs(pb.list) do
        self._fishFetterObjMap[obj.refId] = obj
    end
end

-- 羁绊图鉴_激活属性 请求
function ModelFish:FishFetterActiveReq(fetterRefId)
    local pb = LProtoHelper.CreateProto(LProtoIds.FishFetterActiveReq)
    pb.fetterRefId = fetterRefId
    SendMessage(pb, LProtoIds.FishFetterActiveReq)
end

-- 羁绊图鉴_激活属性 返回
function ModelFish:OnFishFetterActiveResp(pb)
    -- todo: 羁绊图鉴数据处理

    local fetterObj = pb.fetterObj
    self._fishFetterObjMap[fetterObj.refId] = fetterObj

    FireEvent(EventNames.FISH_BASE_INFO)
end

-- 切换渔场 请求
function ModelFish:SwitchFishSceneReq(refId)
    local pb = LProtoHelper.CreateProto(LProtoIds.SwitchFishSceneReq)
    pb.refId = refId
    SendMessage(pb, LProtoIds.SwitchFishSceneReq)
end

-- 切换渔场 返回
function ModelFish:OnSwitchFishSceneResp(pb)
    self._curRefId = pb.refId

    FireEvent(EventNames.FISH_CHANGE_FARM)
end

-- 查看/升级钓鱼技能 请求
function ModelFish:FishingSkillReq(type)
    local pb = LProtoHelper.CreateProto(LProtoIds.FishingSkillReq)
    -- 技能类型 0-仅列表
    pb.type = type
    SendMessage(pb, LProtoIds.FishingSkillReq)
end

-- 查看/升级钓鱼技能 返回
function ModelFish:OnFishingSkillResp(pb)
    for k, obj in ipairs(pb.skills) do
        self._fishingSkillLevMap[obj.type] = obj.level
    end
    FireEvent(EventNames.FISH_SKILL_RETURN)
end

-- 钓鱼订单列表 请求
function ModelFish:FishingOrderListReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.FishingOrderListReq)
    SendMessage(pb, LProtoIds.FishingOrderListReq)
end

-- 钓鱼订单列表 返回
function ModelFish:OnFishingOrderListResp(pb)
    -- 任务 基础信息
    self._taskBaseInfo.remainResetCount = pb.remainResetCount
    self._taskBaseInfo.usedEnergy = pb.usedEnergy
    self._taskBaseInfo.maxEnergy = pb.maxEnergy

    local list = {}
    local canReceive = false
    local TaskState = ModelFish.TaskState
    for k, v in ipairs(pb.order) do
        list[k] = v
        if v.state == TaskState.Completed then
            -- 状态 0-未完成,1-可领取,2-已领取
            canReceive = true
        end
    end

    -- 任务数据
    self._fishingOrderObjList = list

    if canReceive then
        FireEvent(EventNames.FISH_BASE_INFO)
    else
        FireEvent(EventNames.FISH_TASK_RETURN)
    end
end

-- 领取钓鱼订单奖励 请求
function ModelFish:FishingOrderReceiveReq(id)
    local pb = LProtoHelper.CreateProto(LProtoIds.FishingOrderReceiveReq)
    pb.id = id
    SendMessage(pb, LProtoIds.FishingOrderReceiveReq)
end

-- 领取钓鱼订单奖励 返回
function ModelFish:OnFishingOrderReceiveResp(pb)
    local obj = pb.order
    for k, v in ipairs(self._fishingOrderObjList) do
        if v.id == obj.id then
            self._fishingOrderObjList[k] = obj
            break
        end
    end
    FireEvent(EventNames.FISH_BASE_INFO)
end

-- 刷新/重置钓鱼订单 请求
function ModelFish:RefreshFishingOrderReq(id, type)
    local pb = LProtoHelper.CreateProto(LProtoIds.RefreshFishingOrderReq)
    pb.id = id
    pb.type = type -- 0-刷新指定订单,1-重置全部
    SendMessage(pb, LProtoIds.RefreshFishingOrderReq)
end

-- 刷新/重置钓鱼订单 返回
function ModelFish:OnRefreshFishingOrderResp(pb)
    if pb.type == 0 then
        for k, v in ipairs(self._fishingOrderObjList) do
            if v.id == pb.id then
                self._fishingOrderObjList[k] = pb.order
                break
            end
        end

        FireEvent(EventNames.FISH_REFRESH_TASK, { id = pb.id, order = pb.order })
    end

    GF.ShowMessage(ccClientText(44321))
end

-- 已查看上一期自动出售获得物品,删除缓存 请求
function ModelFish:FishingRemoveEndReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.FishingRemoveEndReq)

    SendMessage(pb, LProtoIds.FishingRemoveEndReq)
end

-- 已查看上一期自动出售获得物品,删除缓存 返回
function ModelFish:OnFishingRemoveEndResp(pb)
    self:SetEndThings("")
end

-- 记录渔场已展示 请求
function ModelFish:FishingShowSceneReq(scene)
    local pb = LProtoHelper.CreateProto(LProtoIds.FishingShowSceneReq)
    pb.scene = scene

    SendMessage(pb, LProtoIds.FishingShowSceneReq)
end

-- 记录渔场已展示 返回
function ModelFish:OnFishingShowSceneResp(pb)
    for i, v in ipairs(pb.showScenes) do
        self._hadLookNewFarmMap[v] = true
    end
    FireEvent(EventNames.FISH_BASE_INFO)
end


-- OnFishingOrderListResp


-- endregion 协议 ----------------------------------------------------



-- region 数据 ----------------------------------------------------

-- true:钓鱼开放中
function ModelFish:IsFishingOpen()
    if self._state == 1 then
        local curTime = GetTimestamp()
        local closeTime = self:GetEndTime()
        return curTime < closeTime
    end
    return false
end

-- 弹出当前钓到的物品
function ModelFish:PopCurTheBaitObj()
    local obj = self._theBaitObj
    self._theBaitObj = nil
    return obj
end

-- 获取自动调鱼数据
function ModelFish:GetAutoFishingData()
    local data = {}
    data.quality = tonumber(LPlayerPrefs.fishAutoQuality)
    data.selectedQuality = tonumber(LPlayerPrefs.fishAutoQualitySelect) == 1
    data.selectedIllustrated = tonumber(LPlayerPrefs.fishAutoIllustrated) == 1
    data.selectedPowerUp = tonumber(LPlayerPrefs.fishAutoPowerUp) == 1

    data.qualityFast = tonumber(LPlayerPrefs.fishAutoQualityFast)
    data.selectedQualityFast = tonumber(LPlayerPrefs.fishAutoQualitySelectFast) == 1
    data.selectedPowerUpFast = tonumber(LPlayerPrefs.fishAutoPowerUpFast) == 1

    data.fishAutoHadFast = tonumber(LPlayerPrefs.fishAutoHadFast) == 1

    local list = self:GetFishQualityList()
    if data.quality == 0 then
        data.quality = list[1]
        LPlayerPrefs.SetFishAutoQuality(data.quality)
    end
    if data.qualityFast == 0 then
        data.qualityFast = list[1]
        LPlayerPrefs.SetFishAutoQuality(data.qualityFast)
    end

    return data
end

-- 保存自动调鱼数据
function ModelFish:SaveAutoFishingData(data)
    LPlayerPrefs.SetFishAutoQuality(data.quality)
    LPlayerPrefs.SetFishAutoQualitySelect(data.selectedQuality and 1 or 0)
    LPlayerPrefs.SetFishAutoIllustrated(data.selectedIllustrated and 1 or 0)
    LPlayerPrefs.SetFishAutoPowerUp(data.selectedPowerUp and 1 or 0)

    LPlayerPrefs.SetFishAutoQualityFast(data.qualityFast)
    LPlayerPrefs.SetFishAutoQualitySelectFast(data.selectedQualityFast and 1 or 0)
    LPlayerPrefs.SetFishAutoPowerUpFast(data.selectedPowerUpFast and 1 or 0)

    LPlayerPrefs.SetFishAutoHadFast(data.fishAutoHadFast and 1 or 0)
end

-- 获取任务基础数据
function ModelFish:GetFishTaskBaseInfo()
    return self._taskBaseInfo
end

-- 获取任务列表
function ModelFish:GetTaskList(sort)
    local list = self._fishingOrderObjList
    if sort then
        table.sort(list, function(a, b)
            local stateA = a.state
            local stateB = b.state
            if stateA == 1 then
                stateA = -1
            end

            if stateB == 1 then
                stateB = -1
            end

            if stateA ~= stateB then
                return stateA < stateB
            end

            if a.refId ~= b.refId then
                return a.refId < b.refId
            end

            return a.id < b.id
        end)
    end
    return list
end

-- 通过鱼的类型，获取鱼釭鱼的列表数据
function ModelFish:GetFishTankObjListByType(type, isSort)
    local list = {}
    for refId, fishObj in pairs(self._fishTankObjMap) do
        local ref = self:GetFishRef(refId)
        if ref.type == type then
            table.insert(list, fishObj)
        end
    end
    if isSort then
        table.sort(list, function(a, b) return a.refId < b.refId end)
    end

    return list
end

-- 获取暂存鱼
function ModelFish:GetBackpackMap()
    return self._backpackMap
end

-- true:表示需要出售鱼
function ModelFish:NeedSellBackpackFish(fishObj)
    for k, v in pairs(self._backpackMap) do
        if v.refId == fishObj.refId then
            if v.score < fishObj.score then
                self:SellFishReq(2, v.id)
                -- self._backpackMap[k] = nil
                return true, v.id
            end
            return true, 0
        end
    end

    return false, 0
end

-- 获取鱼釭里的鱼
function ModelFish:GetFishTankObj(refId)
    return self._fishTankObjMap[refId]
end

-- 获取鱼釭里所有的鱼
function ModelFish:GetFishTankAllObjs()
    return self._fishTankObjMap
end

-- 通过鱼的类型，获取可上阵鱼的数量
function ModelFish:GetFishNumMaxByType(type, lev)
    lev = lev or self:GetFishTankLev()
    local attrList = self:GetFishTankAttr(lev)
    for k, v in ipairs(attrList) do
        if v.type == type then
            return v.value
        end
    end
    return 0
end

-- 获取鱼釭中鱼的类型解锁等级
function ModelFish:GetFishTankUnLockLevByFishType(type)
    for lev, ref in ipairs(GameTable.FishingTankLvRef) do
        local attrList = self:GetFishTankAttr(lev)
        for k, v in ipairs(attrList) do
            if v.type == type and v.value > 0 then
                return lev
            end
        end
    end
    return 0
end

-- 获取最大解锁鱼场
function ModelFish:GetMaxUnlockRefId()
    local maxUnlockRefId = self._maxUnlockRefId
    for i = maxUnlockRefId, #GameTable.FishingGroundRef do
        local ref = GameTable.FishingGroundRef[i]
        if ref.open == "" then
            maxUnlockRefId = i
        else
            local questRefIdList = self:GetConditionList(ref.refId)
            local isUnlock = true
            for i, v in ipairs(questRefIdList) do
                if not self:IsTaskFinish(v.questRefId) then
                    isUnlock = false
                    break
                end
            end
            if isUnlock then
                maxUnlockRefId = i
            else
                break
            end
        end
    end

    self._maxUnlockRefId = maxUnlockRefId
    return maxUnlockRefId
end

-- true: 表示任务已完成
function ModelFish:IsTaskFinish(questRefId)
    -- local finish = gModelQuest:IsTaskFinish(questRefId) -- 此函数判断有问题

    local data = gModelQuest:GetTaskDataByRefId(questRefId)
    if data then
        local schedule = tonumber(data:GetSchedule())
        local goal = tonumber(data:GetGoal())
        return schedule >= goal
    end
    return false
end

-- 获取鱼场结束时间
function ModelFish:GetEndTime()
    return self._closeTime
end

-- 设置玩法结束自动出售获得
function ModelFish:SetEndThings(str)
    self._endThings = str
end

-- 获取玩法结束自动出售获得
function ModelFish:GetEndThings()
    return self._endThings
end

-- 获取鱼场开始时间
function ModelFish:GetOpenime()
    return self._openTime
end

-- 获取钓鱼次数
function ModelFish:GetFishingCount()
    return self._fishingCount
end

-- 获取当前使用的鱼竿
function ModelFish:GetCurUseFishRod()
    local initFishRod = self:GetInitRodRefId()
    if self._fishingRod == initFishRod then
        return initFishRod
    end
    local data = gModelFish:GetFishItemAttr(self._fishingRod)
    if data.time <= 0 then
        -- 无期限
        return self._fishingRod
    end


    local serData = gModelItem:GetItemServerDataByRefId(self._fishingRod)
    if not serData then
        self._fishingRod = initFishRod
        return initFishRod
    end

    local curTime = GetTimestamp()
    local createTime = serData:GetCreateTime() * 0.001
    if curTime >= createTime + data.time then
        -- 已过期
        self._fishingRod = initFishRod
        return initFishRod
    end

    return self._fishingRod
end

-- 获取当前使用的鱼铒
function ModelFish:GetCurUseFishBait()
    local initFishBait = self:GetInitBaitRefId()
    if self._fishingBait == initFishBait then
        return initFishBait
    end
    local num = gModelItem:GetNumByRefId(self._fishingBait)
    if num <= 0 then
        self._fishingBait = initFishBait
    end
    return self._fishingBait
end

-- 获取鱼的获得次数
function ModelFish:GetFishTimes(refId)
    local obj = self:GetFishHandbookObjObj(refId)
    if not obj then
        return 0
    end
    return obj.count
end

-- 获取鱼的获得的重大重量
function ModelFish:GetFishWeightMax(refId)
    local obj = self:GetFishHandbookObjObj(refId)
    if not obj then
        return 0
    end
    return obj.fish.weight
end

-- 获取鱼釭等级
function ModelFish:GetFishTankLev()
    return self._fishTankLev
end

-- 获取鱼釭属性
function ModelFish:FishTankAttrList()
    return self._fishTankAttrList
end

-- true:表示鱼的收藏属性已激活
function ModelFish:HadFishCollectAttrActive(refId, index)
    local obj = self:GetFishHandbookObjObj(refId)
    if not obj then
        return false
    end
    return obj.activeCount >= index
end

-- true:表示鱼的收藏属性可激活
function ModelFish:CanFishCollectAttrActive(refId, index)
    if self:HadFishCollectAttrActive(refId, index) then
        return false
    end
    local list = self:GetFishCollectAttr(refId)
    local maxNum = list[index].num
    local curNum = self:GetFishTimes(refId)
    return curNum >= maxNum
end

-- true:表示鱼的收藏属性奖励已领取
function ModelFish:HadFishCollectAttrReward(refId)
    local obj = self:GetFishHandbookObjObj(refId)
    if not obj then
        return false
    end
    return obj.getReward == true
end

-- true:表示鱼的收藏属性奖励可领取
function ModelFish:CanFishCollectAttrReward(refId)
    local obj = self:GetFishHandbookObjObj(refId)
    if not obj then
        return false
    end
    return obj.getReward ~= true
end

-- 通过类型获取当前类型等级的技能配置
function ModelFish:GetFishSkillLevByType(type)
    if self._fishingSkillLevMap[type] then
        return self._fishingSkillLevMap[type]
    end
    return 0
end

-- 获取图鉴数据 --> 羁绊
function ModelFish:GetFishFetterObj(refId)
    return self._fishFetterObjMap[refId]
end

-- 获取图鉴数据 --> 鱼
function ModelFish:GetFishHandbookObjObj(refId)
    return self._fishHandbookObjMap[refId]
end

-- 获取图鉴数据 --> 鱼属性总和
function ModelFish:GetFishHandbookAttrList()
    return self._fishHandbookAttrList
end

-- true: 表示鱼已毕业
function ModelFish:IsOver(refId)
    local obj = self:GetFishHandbookObjObj(refId)
    if not obj then
        return false
    end
    if obj.getReward ~= true then
        return false
    end

    local list = self:GetFishCollectAttr(refId)
    return obj.activeCount >= #list
end

-- 返回参数1：true,表示可以升级
-- 返回参数2：升级消耗物品
-- 返回参数3：true,表示已满级
function ModelFish:CanLvUpFishTank(showTips)
    local curLev = self:GetFishTankLev()
    local curRef = self:GetFishTankLevRef(curLev)
    local nextRef = self:GetFishTankLevRef(curLev + 1)
    local isMax = nextRef == nil

    if isMax then
        if showTips then
            GF.ShowMessage(ccClientText(44282))
        end
        return false, nil, true
    end

    local costItem = LUtil.GetRefItemData(curRef.consume)
    local haveNum = gModelItem:GetNumByRefId(costItem.itemId)
    local needNum = costItem.itemNum
    if haveNum < needNum then
        if showTips then
            local itemName = gModelItem:GetNameByRefId(costItem.refId)
            GF.ShowMessage(ccClientText(44297, itemName))
            gModelGeneral:OpenGetWayWnd({ itemId = costItem.refId })
        end
        return false, costItem, false
    end
    return true, costItem, false
end

-- true：表示能够钓鱼
function ModelFish:CanFishing(showTips, tipsId)
    if not self:IsFishingOpen() then
        if showTips then
            GF.ShowMessage(ccClientText(44298))
        end
        return false
    end

    local costItem = self:GetCostItem()
    local hadNum = gModelItem:GetNumByRefId(costItem.refId)
    if hadNum < costItem.itemNum then
        if showTips then
            local itemName = gModelItem:GetNameByRefId(costItem.refId)
            tipsId = tipsId or 44299
            GF.ShowMessage(ccClientText(tipsId, itemName))
            GF.OpenWnd("UIFishGift")
        end
        return false
    end
    return true
end

-- 获取激活羁绊图鉴需要的数量列表
function ModelFish:GetActiveIllustratedDataList(refId)
    local fishIdList = self:GetActiveIllustratedNeedFishRefIdList(refId)
    local objData = self:GetFishFetterObj(refId)

    local activeItemMap = {}
    local hadActive = false
    local canActive = true
    if objData then
        hadActive = objData.open
        for i, v in ipairs(objData.points) do
            activeItemMap[v] = true
        end
    end

    local dataList = {}
    for i, fishId in ipairs(fishIdList) do
        local data = { refId = fishId, lock = activeItemMap[fishId] == nil }
        dataList[i] = data
        if data.lock or hadActive then
            canActive = false
        end
    end
    return dataList, canActive, hadActive
end

-- 羁绊图鉴 true: 表示存在红点
function ModelFish:HadRedIllustratedByType(type)
    for k, v in pairs(GameTable.FishingTrammelsRef) do
        if v.type == type then
            local dataList, canActive, hadActive = self:GetActiveIllustratedDataList(v.refId)
            if canActive then
                return true
            end
        end
    end
    return false
end

-- 羁绊图鉴 true: 表示存在红点
function ModelFish:HadRedIllustrated()
    for k, v in pairs(GameTable.FishingTrammelsRef) do
        local dataList, canActive, hadActive = self:GetActiveIllustratedDataList(v.refId)
        if canActive then
            return true
        end
    end
    return false
end

-- 鱼图鉴 true: 表示存在红点
function ModelFish:HadRedIllustratedFish()
    for k, v in pairs(GameTable.FishingArticleRef) do
        if v.bookShow == 1 then
            if self:HadRedByFishRefId(v.refId) then
                return true
            end
        end
    end

    return false
end

-- 鱼tips true: 表示存在红点
function ModelFish:HadRedByFishRefId(refId)
    local canGet = self:CanFishCollectAttrReward(refId)
    if canGet then
        return true
    end

    local list = self:GetFishCollectAttr(refId)
    for index, item in ipairs(list) do
        if self:CanFishCollectAttrActive(refId, index) then
            return true
        end
    end

    return false
end

-- ture: 技能能升级
function ModelFish:CanUpSkill(type, showTips)
    local curLev = self:GetFishSkillLevByType(type)
    local curRef = self:GetFishSkillRef(type, curLev)
    local nextRef = self:GetFishSkillRef(type, curLev + 1)
    local isMax = nextRef == nil
    local costItem = LUtil.GetRefItemData(curRef.consume)
    if isMax then
        return false, isMax, costItem
    end
    local haveNum = gModelItem:GetNumByRefId(costItem.itemId)
    if haveNum < costItem.itemNum then
        if showTips then
            local itemName = gModelItem:GetNameByRefId(costItem.itemId)
            GF.ShowMessage(ccClientText(44314, itemName))
            gModelGeneral:OpenGetWayWnd({ itemId = costItem.itemId })
        end

        return false, isMax, costItem
    end
    return true, isMax, costItem
end

-- true: 表示存在红点
function ModelFish:HadRedSkill()
    if self._hadLookSkill then
        return false
    end

    local list = self:GetFishSkillList()
    for _, v in ipairs(list) do
        if self:CanUpSkill(v.type, false) then
            return true
        end
    end
    return false
end

-- 保存查看技能
function ModelFish:SaveLookSkill()
    self._hadLookSkill = true
end

-- 初始化已查看的鱼场
function ModelFish:InitLookFishFarm()
    self._hadLookFarmMap = {}
    local str = LPlayerPrefs.fishLookFishFarm
    local list = string.split(str, "|")
    for i, v in ipairs(list or {}) do
        self._hadLookFarmMap[tonumber(v)] = true
    end
end

-- 保存查看的鱼场
function ModelFish:SaveLookFishFarm(refId)
    self._hadLookFarmMap[refId] = true

    local str = ""
    for k in pairs(self._hadLookFarmMap) do
        if str ~= "" then
            str = str .. "|"
        end
        str = str .. k
    end

    LPlayerPrefs.SetFishLookFishFarm(str)
end

-- 保存新查看的鱼场
function ModelFish:SaveLookNewFarm(refId)
    self:FishingShowSceneReq(refId)
end

-- 返回新鱼场refId, nil表示没有
function ModelFish:CheckNewFarm()
    local maxUnlockRefId = self:GetMaxUnlockRefId()
    if maxUnlockRefId == 1 then
        return nil
    end

    if self._hadLookNewFarmMap[maxUnlockRefId] then
        return nil
    end
    return maxUnlockRefId
end

-- true: 表示该鱼场有红点
function ModelFish:HadRedFishFarmByRefId(refId)
    if self._hadLookFarmMap[refId] then
        return false
    end
    local maxUnlockRefId = self:GetMaxUnlockRefId()
    return refId <= maxUnlockRefId
end

-- true: 表示该鱼场有红点
function ModelFish:HadRedFishFarm()
    for k, v in pairs(GameTable.FishingGroundRef) do
        if self:HadRedFishFarmByRefId(v.refId) then
            return true
        end
    end
    return false
end

-- true: 表示商店存在红点
function ModelFish:HadShopRed()
    local ref = self:GetConfigRef()
    local showRed = gModelRedPoint:CheckSingleShopRedPoint(ref.fishingShop)
    return showRed
end

-- true: 表示礼包存在红点
function ModelFish:HadShopGiftRed()
    local shopId = self._shopGifgRef.refId
    local isOpened = gModelShop:CheckIsShopOpen(shopId)

    if not isOpened then
        return false
    end

    local refList = self:GetFishGiftRefList()
    for k, ref in ipairs(refList) do
        local goods = gModelShop:GetShopItemCfg(ref.refId)

        if goods.price and goods.price.itemNum == 0 then
            -- 免费
            local goodsId = ref.refId
            local itemdata = gModelShop:GetShopItemNetData(shopId, goodsId)
            if itemdata then
                local maxNum = goods.limitCount and goods.limitCount.itemNum or 0
                local hasBuyNum = itemdata:GetHasBuyNum()
                if hasBuyNum < maxNum then
                    return true
                end
            end
        end
    end
    return false
end

-- true: 表示任务存在红点
function ModelFish:HadRedTask()
    local list = self:GetTaskList(false)
    local Completed = ModelFish.TaskState.Completed
    for k, v in ipairs(list) do
        if v.state == Completed then
            return true
        end
    end
    return false
end

-- true: 表示开启自动钓鱼
function ModelFish:OpenAutoFishing(showTips)
    local curTimes = self:GetFishingCount()
    local config = self:GetConfigRef()
    local needTimes = config.fishingAuto
    if curTimes < needTimes then
        if showTips then
            GF.ShowMessage(ccClientText(44312, needTimes - curTimes))
        end
        return false
    end
    return true
end

-- true: 快速钓鱼有红点
function ModelFish:HadRedFishFast()
    local open = gModelFunctionOpen:CheckIsOpened(gModelFish.FastFishId, false)
    if not open then
        return false
    end

    if not self:OpenAutoFishing(false) then
        return false
    end

    local data = self:GetAutoFishingData()
    if data.fishAutoHadFast then
        return false
    end

    if self:CanFishing(false) then
        return true
    end

    if self:IsAutoFishingEndTime(false) then
        return false
    end

    return false
end

-- ture: 快速钓鱼倒计时已结束
function ModelFish:IsAutoFishingEndTime(showTips)
    local cfg = self:GetConfigRef()
    local curTime = GetTimestamp()
    local closeTime = self:GetEndTime()
    local leftTime = cfg.fishingFastTimes or 0
    if closeTime - curTime < leftTime then
        if showTips then
            GF.ShowMessage(ccClientText(44354))
        end
        return true
    end
    return false
end

-- true: 暂存鱼有红点
function ModelFish:HadRedBackpack()
    for k, value in pairs(self._backpackMap) do
        return true
    end
    return false
end

-- true: 表示该模块有红点
function ModelFish:HadRed()
    if not gModelFunctionOpen:CheckIsOpened(ModelFish.MainFuncId, false) then
        return false
    end

    if not self:IsFishingOpen() then
        return false
    end

    -- 鱼图鉴
    if self:HadRedIllustratedFish() then
        return true
    end

    -- 羁绊图鉴
    if self:HadRedIllustrated() then
        return true
    end

    -- 能钓鱼
    if self:CanFishing(false) then
        return true
    end

    -- 鱼釭
    if self:CanLvUpFishTank(false) then
        return true
    end

    -- 技能
    if self:HadRedSkill() then
        return true
    end

    -- 鱼助力礼包
    if self:HadShopGiftRed() then
        return true
    end

    -- 鱼商店
    if self:HadShopRed() then
        return true
    end

    -- 鱼场
    if self:HadRedFishFarm() then
        return true
    end

    -- 鱼任务
    if self:HadRedTask() then
        return true
    end

    -- 快速钓鱼
    if self:HadRedFishFast() then
        return true
    end

    -- 暂存鱼
    if self:HadRedBackpack() then
        return true
    end

    return false
end

-- true: 表示需要打开鱼釭
function ModelFish:NeedOpenFishTank(fishObj)
    local fishRef  = self:GetFishRef(fishObj.refId)
    local fishType = fishRef.type

    local maxNum   = self:GetFishNumMaxByType(fishType)
    if maxNum == 0 then
        return true
    end

    local oldObj = self:GetFishTankObj(fishRef.refId)
    if oldObj then
        return true
    end

    local fishObjList = self:GetFishTankObjListByType(fishType)
    local curNum = #fishObjList
    return curNum == maxNum
end

-- true 表示能否重置所有任务
function ModelFish:CanReSetAll(showTips, noCost)
    local list = self:GetTaskList(true)
    local obj = list[1]
    if not obj then
        return false
    end

    if obj.state == ModelFish.TaskState.Completed then
        if showTips then
            GF.ShowMessage(ccClientText(44315))
        end
        return false
    end
    if obj.state == ModelFish.TaskState.UnCompleted then
        if showTips then
            GF.ShowMessage(ccClientText(44316))
        end
        return false
    end
    local baseInfo = self:GetFishTaskBaseInfo()
    if baseInfo.remainResetCount <= 0 then
        if showTips then
            GF.ShowMessage(ccClientText(44317))
        end
        return false
    end

    if noCost then
        return true
    end


    local ref = self:GetConfigRef()
    local resetCostItemData = LUtil.GetRefItemData(ref.fishingTaskResetting)

    local needNum = resetCostItemData.itemNum
    local hadNum = gModelItem:GetNumByRefId(resetCostItemData.itemId)
    if hadNum < needNum then
        if showTips then
            gModelGeneral:OpenGetWayWnd({ itemId = resetCostItemData.itemId })
        end
        return false
    end
    return true
end

-- endregion 数据 ----------------------------------------------------



-- region 配置 ----------------------------------------------------

-- 获取所有鱼场配置列表
function ModelFish:GetAllFishRefList()
    return GameTable.FishingGroundRef
end

-- 当前所在鱼场配置
function ModelFish:GetCurRef()
    return self:GetRef(self._curRefId)
end

-- 获取鱼场配置
function ModelFish:GetRef(refId)
    return GameTable.FishingGroundRef[refId]
end

-- 鱼的配置
function ModelFish:GetFishRef(refId)
    return GameTable.FishingArticleRef[refId]
end

-- 钓鱼任务配置
function ModelFish:GetFishTaskRef(refId)
    local taskRef = gModelQuest:GetTaskConfig(refId)
    local fishTaskRef = GameTable.FishingTaskRef[refId]

    return fishTaskRef, taskRef
end

-- 获取解锁条件列表
function ModelFish:GetConditionList(refId)
    self._conditionList = self._conditionList or {}
    if not self._conditionList[refId] then
        local ref = GameTable.FishingGroundRef[refId]
        local questRefIdList = {}
        if ref.open ~= "" then
            local list = string.split(ref.open, ",")
            for i, v in ipairs(list) do
                questRefIdList[i] = { questRefId = tonumber(v) }
            end
        end
        self._conditionList[refId] = questRefIdList
    end
    return self._conditionList[refId]
end

-- 参数配置
function ModelFish:GetConfigRef()
    return GameTable.FishingConfigRef
end

-- 获取顶部资产列表
function ModelFish:GetTopAssetList()
    if not self._topAssetList then
        local constItem, constItemMax = self:GetCostItem()
        local refId = next(GameTable.FishingArticleRef)
        local ref = GameTable.FishingArticleRef[refId]
        local sellItem = LUtil.GetRefItemData(ref.sell)
        self._topAssetList = { sellItem.refId, constItem.refId }
        self._topAssetListMaxMap = { [constItem.refId] = constItemMax }
    end
    return self._topAssetList, self._topAssetListMaxMap
end

-- 获取 每次钓鱼消耗的体力道具和数量
function ModelFish:GetCostItem()
    if not self._costItem then
        local ref = self:GetConfigRef()
        self._costItem = LUtil.GetRefItemData(ref.fishingVigor)
        self._costItemMax = ref.fishingTaskCompleteVigorNum
    end

    return self._costItem, self._costItemMax
end

-- 获随图鉴羁绊配置列表
function ModelFish:GetIllustratedRefList(type)
    if not self._illustratedRefList then
        self._illustratedRefList = {}
        for k, v in pairs(GameTable.FishingTrammelsRef) do
            if not self._illustratedRefList[v.type] then
                self._illustratedRefList[v.type] = {}
            end
            table.insert(self._illustratedRefList[v.type], v)
        end

        for k, v in pairs(self._illustratedRefList) do
            table.sort(v, function(a, b)
                return a.refId < b.refId
            end)
        end
    end
    return self._illustratedRefList[type]
end

-- 初始化配置
function ModelFish:InitRef()
    self:InitFishRef()
    self:InitIllustratedFishRef()
    self:InitFishCollectAttrRef()
    self:InitFishBagRef()
    self:InitFishSkillRef()
end

-- 鱼场配置
function ModelFish:InitFishRef()
    local map = {}
    local qualityMap = {}
    local typeMap = {}

    for k, v in ipairs(self:GetFishTankDetailFishTypeList()) do
        typeMap[v] = true
    end

    for k, v in pairs(GameTable.FishingArticleRef) do
        for i, refId in ipairs(string.split(v.get, ",")) do
            refId = tonumber(refId)
            
            local fishRef = self:GetRef(refId)
            if fishRef then
                if not map[refId] then
                    map[refId] = {}
                end
                table.insert(map[refId], v)
            end
        end
        if typeMap[v.type] then
            -- 鱼类
            qualityMap[v.quality] = v.quality
        end
    end

    local list = {}
    for k, v in pairs(qualityMap) do
        table.insert(list, v)
    end
    table.sort(list, function(a, b)
        return a < b
    end)
    self._fishQualityList = list

    for k, v in pairs(map) do
        table.sort(v, function(a, b)
            return a.refId < b.refId
        end)
    end
    self._fishFarmRefMap = map
end

-- 初始化鱼背包配置
function ModelFish:InitFishBagRef()
    local typeBait = gModelItem.TTEM_TYPE_FISH_BAIT
    local typeRod = gModelItem.TTEM_TYPE_FISH_ROD

    local map1 = {}
    local map2 = {}
    for k, v in pairs(GameTable.PlayerItemRef) do
        if v.type == typeBait then
            table.insert(map1, v)
        elseif v.type == typeRod then
            table.insert(map2, v)
        end
    end
    self._fishBaitRefList = map1
    self._fishRodRefList = map2
end

-- 初始化技能配置
function ModelFish:InitFishSkillRef()
    self._fishSkillRef = {}
    for k, v in pairs(GameTable.FishingSkillRef) do
        if not self._fishSkillRef[v.type] then
            self._fishSkillRef[v.type] = {}
        end
        self._fishSkillRef[v.type][v.lv] = v
    end
end

-- 初始化图鉴鱼场配置
function ModelFish:InitIllustratedFishRef()
    local minFarmMap = {} -- 最小所在的鱼场
    local FishingArticleRef = GameTable.FishingArticleRef
    for k, v in pairs(FishingArticleRef) do
        if v.bookShow == 1 then
            -- 可激活图鉴
            for i, farmRefId in ipairs(string.split(v.get, ",")) do
                farmRefId = tonumber(farmRefId)
                if not minFarmMap[v.refId] then
                    minFarmMap[v.refId] = farmRefId
                else
                    minFarmMap[v.refId] = math.min(minFarmMap[v.refId], farmRefId)
                end
            end
        end
    end

    local map = {}
    for refId, farmRefId in pairs(minFarmMap) do
        if not map[farmRefId] then
            map[farmRefId] = { refId = farmRefId, refList = {} }
        end
        table.insert(map[farmRefId].refList, FishingArticleRef[refId])
    end

    local function Sort(a, b)
        return a.refId < b.refId
    end

    local list = {}
    for k, v in pairs(map) do
        table.insert(list, v)
        table.sort(v.refList, Sort)
    end

    table.sort(list, Sort)
    self._illustratedFishRefList = list

    local map = {}
    for k, ref in pairs(GameTable.FishingTrammelsRef) do
        map[ref.refId] = {}
        for k, v in ipairs(string.split(ref.petId, ",")) do
            table.insert(map[ref.refId], tonumber(v))
        end
    end
    self._illustratedRefPetIdMap = map
end

-- 鱼的收藏属性
function ModelFish:InitFishCollectAttrRef()
    self._fishCollectAttr = {}
    local ParseAttr = LxDataHelper.ParseAttr
    for refId, v in pairs(GameTable.FishingArticleRef) do
        local dataList = {}
        for i, val in ipairs(string.split(v.attrHandbook, ",") or {}) do
            local list = string.split(val, "|")
            table.insert(dataList, { num = tonumber(list[1]), attr = ParseAttr(list[2]) })
        end
        self._fishCollectAttr[refId] = dataList
    end
end

-- 获取鱼的收藏属性
function ModelFish:GetFishCollectAttr(refId)
    return self._fishCollectAttr[refId]
end

-- 获取图鉴鱼场配置列表
function ModelFish:GetillustratedFishRefList()
    return self._illustratedFishRefList
end

-- 鱼类型配置
function ModelFish:GetFishTypeRef(type)
    return GameTable.FishingTpyeRef[type]
end

-- 通过鱼场Id,获取鱼场里所有的鱼
function ModelFish:GetAllFishByRefId(refId)
    return self._fishFarmRefMap[refId]
end

-- 获取鱼背包配置列表
function ModelFish:GetFishBaitRefList()
    return self._fishBaitRefList
end

-- 获取鱼钩配置列表
function ModelFish:GetFishRodRefList()
    return self._fishRodRefList
end

-- 获取物品属性
function ModelFish:GetFishItemAttr(refId)
    self._fishItemAttr = self._fishItemAttr or {}
    if not self._fishItemAttr[refId] then
        local itemRef = gModelItem:GetRefByRefId(refId)
        local FishingAttrRef = GameTable.FishingAttrRef
        local attrList = {}
        local list = string.split(itemRef.typeDate, "|")
        for i, v in ipairs(string.split(list[1], ",") or {}) do
            local tab = string.split(v, "=")
            local data = {}
            data.refId = tonumber(tab[1])
            data.value = tonumber(tab[2])

            local attrRef = FishingAttrRef[data.refId]
            if attrRef then
                data.desc = ccLngText(attrRef.name) .. ccClientText(44240, math.round(data.value * 100, 2))

                table.insert(attrList, data)
            end
        end
        local time = tonumber(list[2]) or 0
        self._fishItemAttr[refId] = { attrList = attrList, time = time }
    end
    return self._fishItemAttr[refId]
end

-- 鱼的基础属性
function ModelFish:GetFishBaseAttr(refId)
    self._fishBaseAttr = self._fishBaseAttr or {}
    if not self._fishBaseAttr[refId] then
        local ref = self:GetFishRef(refId)

        self._fishBaseAttr[refId] = LxDataHelper.ParseAttrList(ref.attr)
    end
    return self._fishBaseAttr[refId]
end

-- 初始鱼铒物品id
function ModelFish:GetInitBaitRefId()
    local ref = self:GetConfigRef()
    return ref.fishingBait
end

-- 初始鱼竿物品id
function ModelFish:GetInitRodRefId()
    local ref = self:GetConfigRef()
    return ref.fishingRod
end

-- 获取钓鱼技能顶部资产id列表
function ModelFish:GetFishSkillTopAssetList()
    for k, v in pairs(GameTable.FishingSkillRef) do
        if v.lv > 1 then
            -- 随便取一下即可
            local item = LUtil.GetRefItemData(v.consume)
            return { item.refId }
        end
    end
end

-- 获取鱼釭升级顶部资产id列表
function ModelFish:GetFishTankUpTopAssetList()
    for k, v in pairs(GameTable.FishingTankLvRef) do
        if v.consume ~= "-1" and v.consume ~= "" then
            -- 随便取一下即可
            local item = LUtil.GetRefItemData(v.consume)
            return { item.refId }
        end
    end
end

-- 获取鱼釭配置
function ModelFish:GetFishTankLevRef(refId)
    return GameTable.FishingTankLvRef[refId]
end

-- 获取鱼釭属性
function ModelFish:GetFishTankAttr(lev)
    self._fishTankAttr = self._fishTankAttr or {}
    if not self._fishTankAttr[lev] then
        local ref = self:GetFishTankLevRef(lev)
        local list = {}
        for k, v in ipairs(string.split(ref.war, ",")) do
            local tab = string.split(v, "=")
            local type = tonumber(tab[1])
            local value = tonumber(tab[2])
            table.insert(list, { type = type, value = value })
        end
        self._fishTankAttr[lev] = list
    end
    return self._fishTankAttr[lev]
end

-- 获取鱼釭详情鱼类型列表
function ModelFish:GetFishTankDetailFishTypeList()
    return { 1, 2, 3, 4 }
end

-- true:是鱼釭的鱼类型之一
function ModelFish:InFishTankTypeList(refId)
    local ref = self:GetFishRef(refId)
    for k, v in ipairs(self:GetFishTankDetailFishTypeList()) do
        if v == ref.type then
            return true
        end
    end
    return false
end

-- 获取技能配置
function ModelFish:GetFishSkillRef(type, lev)
    return self._fishSkillRef[type][lev]
end

-- 重量转成带单位字符串
function ModelFish:WeightToString(weight)
    if weight < 1000 then
        weight = math.floor(weight)
        return weight .. ccClientText(44289)
        -- elseif weight < 1000 then
        --     return weight * 0.001 .. ccClientText(44288)
    end
    weight = math.floor(weight * 0.1)
    weight = weight * 0.01

    return weight .. ccClientText(44288)
end

-- 获取鱼礼包配置列表
function ModelFish:GetFishGiftRefList()
    if not self._shopGifgRefList then
        local list = {}
        local type = self._shopGifgRef.type
        for k, v in pairs(GameTable.StoreFixedRef) do
            if v.type == type then
                table.insert(list, v)
            end
        end
        table.sort(list, function(a, b)
            return a.sequence < b.sequence
        end)
        self._shopGifgRefList = list
    end
    return self._shopGifgRefList
end

-- 获取鱼礼包配置商店配置
function ModelFish:GetFishGiftShopRef()
    return self._shopGifgRef
end

-- 鱼的品质列表
function ModelFish:GetFishQualityList()
    return self._fishQualityList
end

-- 羁绊表激活，需要的鱼列表id
function ModelFish:GetActiveIllustratedNeedFishRefIdList(refId)
    return self._illustratedRefPetIdMap[refId]
end

-- 获取技能列表
function ModelFish:GetFishSkillList()
    if not self._fishSkillList then
        self._fishSkillList = {
            [1] = { type = 1, icon = "fish_skill_1", desc = ccClientText(44261) },
            [2] = { type = 2, icon = "fish_skill_2", desc = ccClientText(44262) },
            [3] = { type = 3, icon = "fish_skill_3", desc = ccClientText(44263) },
            [4] = { type = 4, icon = "fish_skill_4", desc = ccClientText(44264) },
            [5] = { type = 5, icon = "fish_skill_5", desc = ccClientText(44265) },

        }
    end
    return self._fishSkillList
end

-- 检查属性值
function ModelFish:CheckAttrValue(attrId, type, value)
    local ref = gModelHero:GetAttributeRefById(attrId)
    if type == 1 and ref.numType == 1 then
        value = math.floor(value)
    else
        value = value * 100
        value = tonumber(math.floor2(value, 2))
        value = value / 100
    end
    return value
end

-- 获取鱼游动配置
function ModelFish:GetFishRunRef(refId)
    return GameTable.FishingRunRef[refId]
end

-- 获取鱼游动的类型配置
function ModelFish:GetFishRunTypeMap()
    if not self._fishRunTypeMap then
        local map = {}
        for k, v in pairs(GameTable.FishingRunRef) do
            if v.type ~= 0 then
                if not map[v.type] then
                    map[v.type] = {}
                end
                table.insert(map[v.type], v.refId)
            end
        end
        self._fishRunTypeMap = map
    end
    return self._fishRunTypeMap
end

-- 奖池 配置
function ModelFish:GetFishingJackpotRef()
    return GameTable.FishingJackpotRef
end


-- endregion 配置 ----------------------------------------------------


-- region 通用ui 配置 ------------------------------------------------
function ModelFish:DrawAttrList(wnd, rootTrans, param)
    local instanceID = rootTrans:GetInstanceID()
    local itemCache = wnd:GetComponentCache(instanceID)
    if not itemCache then
        itemCache        = {}
        local item       = CS.FindTrans(rootTrans, "item")
        itemCache.item   = item
        itemCache.uiList = {}
        CS.ShowObject(item, false)
        wnd:SetComponentCache(instanceID, itemCache)
    end

    local attrDataList = {}
    if param.strAttr then
        attrDataList = LxDataHelper.ParseAttrList(param.strAttr)
    end

    for i, data in ipairs(attrDataList) do
        local uiList = itemCache.uiList[i]
        if not uiList then
            uiList = {}
            local obj = CS.InstantObject(itemCache.item.gameObject)
            local item = obj.transform
            item:SetParent(itemCache.item.parent, false)
            uiList.item         = item
            uiList.icon         = CS.FindTrans(item, "icon")
            uiList.name         = CS.FindTrans(item, "name")
            uiList.value        = CS.FindTrans(item, "value")
            itemCache.uiList[i] = uiList
        end
        CS.ShowObject(uiList.item, true)

        local icon = gModelHero:GetAttributeIconById(data.refId)
        wnd:SetWndEasyImage(uiList.icon, icon)

        local name = gModelHero:GetAttributeNameById(data.refId)
        wnd:SetWndText(uiList.name, name)

        local valueStr = gModelHero:GetAttributeValueNoNameByIdAndVal(data.refId, data.type, data.value)
        wnd:SetWndText(uiList.value, valueStr)
    end

    for i = #attrDataList + 1, #itemCache.uiList do
        local ui = itemCache.uiList[i]
        CS.ShowObject(ui.item, false)
    end
end

-- endregion 通用ui 配置 ---------------------------------------------

-- 鱼场相关界面
function ModelFish:GetFishViewList()
    local list = {
        "UIFishAuto",
        "UIFishAutoFast",
        "UIFishBag",
        "UIFishFarmDetail",
        "UIFishGet",
        "UIFishGift",
        "UIFishIllustrated",
        "UIFishIllustratedDetail",
        "UIFishList",
        "UIFishSkill",
        "UIFishTank",
        "UIFishTankDetail",
        "UIFishTankUp",
        "UIFishTask",
        "UIFishTips",
        "UIFishBackpack",
        "UIFishReplace",
    }
    return list
end

-- 玩法结束
function ModelFish:PlayOver()
    GF.CloseWndByName("UIFish")

    for k, name in ipairs(self:GetFishViewList()) do
        GF.CloseWndByName(name)
    end
end

return ModelFish
