---
--- Created by wzz.
--- DateTime: 2024/9/9
--- 爱欲小径

---@class ModelDesireTrail:LModel
local ModelDesireTrail           = LxClass("ModelDesireTrail", LModel)

local string                     = string

ModelDesireTrail.MainFuncId      = 16800000

-- 效果类型
ModelDesireTrail.EffectType      = {
    -- 前进
    Move = 0,
}

ModelDesireTrail.TaskType        = {}
ModelDesireTrail.TaskType.Daily  = 183 -- 日常
ModelDesireTrail.TaskType.Target = 184 -- 目标


-- 英雄类型
ModelDesireTrail.HeroType               = {}
ModelDesireTrail.HeroType.SELF_HERO     = 1 -- 玩家英雄
ModelDesireTrail.HeroType.HIRE_HERO     = 2 -- 雇佣英雄
ModelDesireTrail.HeroType.ENEMY_MONSTER = 3 -- 怪物
ModelDesireTrail.HeroType.ENEMY_HERO    = 4 -- 玩家镜像

-- 格子状态
ModelDesireTrail.GridStatus             = {
    -- 不可走
    CanNotMove = 0,
    -- 可走
    CanMove    = 1,
    -- 已走过
    HasMove    = 2,
    -- 消失
    Disappear  = 3,
    -- 被选中
    Selected   = 4,
}

local function tableSize(t)
    local count = 0
    for _ in pairs(t) do
        count = count + 1
    end
    return count
end

function ModelDesireTrail:ModelDesireTrail()
    -- 当前格子数据 [[x] = {[y] = EventInfo} ]
    self._gridMap = {}

    -- 格子状态变化列表 [[x] = {[y] = EventInfo} ]
    self._changedGridMap = {}

    -- 当前玩家所在主题
    self._themeRefId = 0

    -- 已重置次数
    self._resetCount = 0

    -- 剩余可挑战次数
    self._challengeCount = 0

    -- 下一次重置时间
    self._resetTime = 0

    -- 当前主角所在的格子坐标
    self._roleX = 0
    self._roleY = 0
    -- self:InitRef()

    -- 当前效果类型列表
    self._curEffectList = {}

    -- 当前怪物英雄数据
    self._monsterPb = nil

    -- 已通关次数（碾压判断条件）
    self._clearanceCount = 0

    -- 正在扫荡的中
    self._sweeping = false

    -- 扫荡失败结果
    self._sweepResultPb = nil
end

function ModelDesireTrail:OnModelInit()
    self:ModelNetMsgRecv(LProtoIds.DesireTrailThemeResp, function(...) self:OnDesireTrailThemeResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.DesireTrailMonsterResp, function(...) self:OnDesireTrailMonsterResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.DesireTrailOpsResp, function(...) self:OnDesireTrailOpsResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.DesireTrailResetResp, function(...) self:OnDesireTrailResetResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.DesireTrailEffectResp, function(...) self:OnDesireTrailEffectResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.DesireTrailBuyChallengeResp, function(...) self:OnDesireTrailBuyChallengeResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.DesireTrailCrushingResp, function(...) self:OnDesireTrailCrushingResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.DesireTrailNextThemeResp, function(...) self:OnDesireTrailNextThemeResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.DesireTrailSweepResp, function(...) self:OnDesireTrailSweepResp(...) end)


    -- todo:后续服务端主动推了，删掉
    self:ModelEventRecv(EventNames.ON_PLAYER_LEVEL_CHANGE, function(oldLv, newLv)
        self:OnCheckRequest()
    end)

    self:ModelNetMsgRecv(LProtoIds.PlayerInstanceResp, function(...)
        self:OnCheckRequest()
    end)
end

--在协议数据处理完之后需要调用finish
function ModelDesireTrail:OnModelRequest()
    if gModelFunctionOpen:CheckIsOpened(ModelDesireTrail.MainFuncId, false) then
        self:DesireTrailThemeReq()
        
    	if gModelFormation:IsFormationEmpty(LCombatTypeConst.COMBAT_DESIRETRAIL) then
            gModelFormation:OnGetFormationListReq({LCombatTypeConst.COMBAT_DESIRETRAIL})
        end
    end

    self:ModelFinish()
end

-- region 协议 ----------------------------------------------------

-- 检查数据
function ModelDesireTrail:OnCheckRequest()
    if gModelFunctionOpen:CheckIsOpened(ModelDesireTrail.MainFuncId, false) and self:GetGridCount() == 0 then
        self:DesireTrailThemeReq()
    end
end

-- 请求主题数据 请求
function ModelDesireTrail:DesireTrailThemeReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.DesireTrailThemeReq)
    SendMessage(pb, LProtoIds.DesireTrailThemeReq)
end

-- 入口进去需要显示的数据 返回
function ModelDesireTrail:OnDesireTrailThemeResp(pb)
    self._resetCount = pb.resetCount
    self._challengeCount = pb.challengeCount
    self._resetTime = pb.resetTime

    local resetAll = self._themeRefId ~= pb.themeRefId
    self._themeRefId = pb.themeRefId
    self._clearanceCount = pb.clearanceCount

    if resetAll then
        self._gridMap = {}
        self._changedGridMap = {}
    end

    local gridChange = false
    local oldTotal = self:GetGridCount()
    if oldTotal > 0 and oldTotal > #pb.info.eventInfo and not resetAll then
        -- 格子变化推送
        for k, v in ipairs(pb.info.eventInfo) do
            local girdData = self:GetGridData(v.y, v.x)
            if girdData and girdData.status ~= v.status then
                -- 格子状态变化
                if not self._changedGridMap[v.y] then
                    self._changedGridMap[v.y] = {}
                end
                self._changedGridMap[v.y][v.x] = v
            end
        end
        gridChange = true
    else
        resetAll = true
        self._changedGridMap = {}
        self._gridMap = {}
    end

    for k, v in ipairs(pb.info.eventInfo) do
        if not self._gridMap[v.y] then
            self._gridMap[v.y] = {}
        end
        self._gridMap[v.y][v.x] = v
    end

    self:SetRolePos(pb.x, pb.y)

    if gridChange then
        FireEvent(EventNames.DESIRE_TRAIL_GRID_CHANGE)
    end


    if resetAll then
        FireEvent(EventNames.DESIRE_TRAIL_RESET)
    else
        FireEvent(EventNames.DESIRE_TRAIL_BASE_INFO)
    end
end

-- 各种效果通知 返回
function ModelDesireTrail:OnDesireTrailEffectResp(pb)
    local EffectType = ModelDesireTrail.EffectType
    for k, v in ipairs(pb.infos) do
        local data = { effectType = v.eventType }
        if data.effectType == EffectType.Move then
            local list = string.split(v.effectVal, "=")
            local tab1 = string.split(list[1], ",")
            local tab2 = string.split(list[2], ",")

            data.oldX = tonumber(tab1[1])
            data.oldY = tonumber(tab1[2])
            data.newX = tonumber(tab2[1])
            data.newY = tonumber(tab2[2])
        end

        self:PushEffect(data)
    end
end

-- 重置 请求
function ModelDesireTrail:DesireTrailResetReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.DesireTrailResetReq)
    SendMessage(pb, LProtoIds.DesireTrailResetReq)
end

-- 重置 返回
function ModelDesireTrail:OnDesireTrailResetResp()
    -- 重置成功返回DesireTrailThemeResp协议

    FireEvent(EventNames.DESIRE_TRAIL_RESET)
end

-- 兑换数量 请求
function ModelDesireTrail:DesireTrailBuyChallengeReq(num)
    local pb = LProtoHelper.CreateProto(LProtoIds.DesireTrailBuyChallengeReq)
    pb.num = num
    SendMessage(pb, LProtoIds.DesireTrailBuyChallengeReq)
end

-- 兑换数量 返回
function ModelDesireTrail:OnDesireTrailBuyChallengeResp(pb)
    self._challengeCount = pb.challengeCount
    FireEvent(EventNames.DESIRE_TRAIL_BUY_CHALLENGE)
    GF.ShowMessage(ccClientText(45421))
end

-- 查看怪物数据 请求
function ModelDesireTrail:DesireTrailMonsterReq(x, y)
    local pb = LProtoHelper.CreateProto(LProtoIds.DesireTrailMonsterReq)
    pb.x = x
    pb.y = y
    SendMessage(pb, LProtoIds.DesireTrailMonsterReq)
end

-- 查看怪物数据 返回
function ModelDesireTrail:OnDesireTrailMonsterResp(pb)
    self._monsterPb = pb
    FireEvent(EventNames.DESIRE_TRAIL_MONSTER_INFO, pb)
end

-- 地图操作相关 请求
function ModelDesireTrail:DesireTrailOpsReq(param)
    local pb = LProtoHelper.CreateProto(LProtoIds.DesireTrailOpsReq)
    pb.type = param.type
    pb.x = param.x
    pb.y = param.y
    pb.moreinfo = param.moreinfo or ""
    self._desireTrailOpsCallback = param.callback
    SendMessage(pb, LProtoIds.DesireTrailOpsReq)
end

-- 地图操作相关 返回
function ModelDesireTrail:OnDesireTrailOpsResp(pb)
    local func = self._desireTrailOpsCallback
    self._desireTrailOpsCallback = nil

    if func then
        func()
    end
end

-- 一键碾压 请求
function ModelDesireTrail:DesireTrailCrushingReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.DesireTrailCrushingReq)
    SendMessage(pb, LProtoIds.DesireTrailCrushingReq)
end

-- 一键碾压 返回
function ModelDesireTrail:OnDesireTrailCrushingResp(pb)
    local itemList = {}

    local info = gModelGeneral:GetThingsDetailInfoByPb(pb.thingsDetail)
    local allRewardList = info:GetThingsDetailAllRewardList() or {}
    for idx, val in ipairs(allRewardList) do
        table.insert(itemList, val.serverData)
    end

    FireEvent(EventNames.DESIRE_TRAIL_CRUSHING)
    GF.OpenWnd("UIDesireTrailFastFight", { itemList = itemList })
end

-- 切换到下一个主题 请求
function ModelDesireTrail:DesireTrailNextThemeReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.DesireTrailNextThemeReq)
    SendMessage(pb, LProtoIds.DesireTrailNextThemeReq)
end

-- 切换到下一个主题 返回
function ModelDesireTrail:OnDesireTrailNextThemeResp(pb)

end

-- 扫荡 请求
function ModelDesireTrail:DesireTrailSweepReq(y, x, isLeft)
    local pb = LProtoHelper.CreateProto(LProtoIds.DesireTrailSweepReq)
    pb.x = x
    pb.y = y
    pb.left = isLeft and 1 or 0
    SendMessage(pb, LProtoIds.DesireTrailSweepReq)

    self:SetSweeping(true)
end

-- 扫荡 返回
function ModelDesireTrail:OnDesireTrailSweepResp(pb)
    local isWin = true
    local isLeft = pb.left == 1
    self._challengeCount = pb.challengeCount
    local itemList = {}
    if pb.stop == 1 then
        -- 终止扫荡（战斗失败）
        isWin = false
    else
        local info = gModelGeneral:GetThingsDetailInfoByPb(pb.thingsDetail)
        local allRewardList = info:GetThingsDetailAllRewardList() or {}
        for idx, val in ipairs(allRewardList) do
            table.insert(itemList, val.serverData)
        end
        -- self:SetRolePos(pb.x, pb.y)
    end


    local data = { x = pb.x, y = pb.y, isLeft = isLeft, isWin = isWin, itemList = itemList }

    FireEvent(EventNames.DESIRE_TRAIL_SWEEP, data)
    FireEvent(EventNames.DESIRE_TRAIL_BUY_CHALLENGE)
end

-- endregion 协议 ----------------------------------------------------
--


-- region 数据 ----------------------------------------------------

-- 获取当前主题配置
function ModelDesireTrail:GetCurThemeRef()
    return self:GetThemeRef(self._themeRefId)
end

-- ture:表示最后一个主题
function ModelDesireTrail:IsMaxTheme()
    local ref = self:GetThemeRef(self._themeRefId + 1)
    return ref == nil
end

-- 获取当前主题的格子数据
function ModelDesireTrail:GetGridDataMap()
    -- local list = {}
    -- list[1] = { y = 0, x = 0, refId = 0, state = 0 }
    -- list[2] = { y = 1, x = 0, refId = 1101, state = 0 }
    -- list[3] = { y = 1, x = 1, refId = 1201, state = 0 }
    -- list[4] = { y = 2, x = 0, refId = 1201, state = 0 }
    -- list[5] = { y = 2, x = 1, refId = 1201, state = 0 }
    -- list[6] = { y = 2, x = 2, refId = 1301, state = 0 }
    -- list[7] = { y = 3, x = 0, refId = 1301, state = 0 }
    -- list[8] = { y = 3, x = 1, refId = 1301, state = 0 }
    -- list[9] = { y = 4, x = 0, refId = 2201, state = 0 }

    -- self._gridMap = {}
    -- for k, v in ipairs(list) do
    --     if not self._gridMap[v.y] then
    --         self._gridMap[v.y] = {}
    --     end
    --     self._gridMap[v.y][v.x] = v
    -- end
    return self._gridMap
end

-- 获取格子数据
function ModelDesireTrail:GetGridData(y, x)
    if not self._gridMap[y] then
        return nil
    end
    return self._gridMap[y][x]
end

-- 获取一行的格子总数, 传nil则获取总行数
function ModelDesireTrail:GetOneLineGridCount(y)
    local count = 0
    local tab = (y and self._gridMap[y] or {}) or self._gridMap
    for _ in pairs(tab) do
        count = count + 1
    end
    return count
end

-- 获取当前格子总数
function ModelDesireTrail:GetGridCount()
    local count = 0
    for _, v in pairs(self._gridMap) do
        for _ in pairs(v) do
            count = count + 1
        end
    end
    return count
end

-- 设置主角所在的格子坐标
function ModelDesireTrail:SetRolePos(x, y)
    self._roleX = x
    self._roleY = y
end

-- 获取主角所在的格子坐标
function ModelDesireTrail:GetRolePos()
    local x, y = self._roleX, self._roleY
    for _, v in ipairs(self._curEffectList) do
        if v.effectType == ModelDesireTrail.EffectType.Move then
            x = v.oldX
            y = v.oldY
        end
    end
    return x, y
end

-- 弹出一个效果
function ModelDesireTrail:PopEffect()
    return table.remove(self._curEffectList, 1)
end

-- 压入一个效果
function ModelDesireTrail:PushEffect(data)
    table.insert(self._curEffectList, data)
end

-- 获取当前格子状态变化列表
function ModelDesireTrail:GetChangedGridMap()
    return self._changedGridMap
end

-- 清空当前格子状态变化列表
function ModelDesireTrail:ClearChangedGridMap()
    self._changedGridMap = {}
end

-- true: 表示有格子状态变化
function ModelDesireTrail:HasChangedGrid()
    return next(self._changedGridMap) ~= nil
end

-- ture: 表示需要播动画
function ModelDesireTrail:NeedPlayAnim(y, x)
    if self._changedGridMap[y] and self._changedGridMap[y][x] then
        return true
    end
    return false
end

-- 获取当前剩余可挑战次数
function ModelDesireTrail:GetChallengeCount()
    return self._challengeCount or 0 
end

-- 获取重置消耗, -1表示无重置次数
function ModelDesireTrail:GetResetCost()
    local ref = self:GetConfRef()
    local itemRefId = 102001 -- 固定钻石
    local list = string.split(ref.manualResetConsume, ";")
    for i, v in ipairs(list) do
        local tab = string.split(v, "=")
        local times = tonumber(tab[1])
        local cost = tonumber(tab[2])

        if self._resetCount + 1 == times then
            return itemRefId, cost
        end
    end

    return itemRefId, -1
end

-- true:表示能重置
function ModelDesireTrail:CanReset(showTips)
    local itemRefId, needNum = self:GetResetCost()
    if needNum == -1 then
        if showTips then
            GF.ShowMessage(ccClientText(45417))
        end
        return false
    end

    local haveNum = gModelItem:GetNumByRefId(itemRefId)
    if haveNum < needNum then
        if showTips then
            local itemName = gModelItem:GetNameByRefId(itemRefId)
            GF.ShowMessage(ccClientText(45418, itemName))
            gModelGeneral:OpenGetWayWnd({ itemId = itemRefId })
        end
        return false
    end
    return true
end

-- 获取兑换物品id 和 比例
function ModelDesireTrail:GetChallengeExchange()
    local ref = self:GetConfRef()
    local list = string.split(ref.challengeExchange, "=")
    return tonumber(list[1]), tonumber(list[2])
end

-- 日常任务有红点
function ModelDesireTrail:HadTaskDailyRed()
    return self:HadTaskRed(ModelDesireTrail.TaskType.Daily)
end

-- 目标任务有红点
function ModelDesireTrail:HadTaskTargetRed()
    return self:HadTaskRed(ModelDesireTrail.TaskType.Target)
end

-- true: 表示任务有红点
function ModelDesireTrail:HadTaskRed(taskType)
    if taskType == nil then
        if self:HadTaskDailyRed() then
            return true
        end
        return self:HadTaskTargetRed()
    end

    local list = gModelQuest:GetTaskList(taskType)
    local canGet = ModelQuest.TASK_FINNISH
    for i, data in ipairs(list) do
        local state = data:GetState()
        if state == canGet then
            return true
        end
    end
    return false
end

-- true: 表示有重置红点
function ModelDesireTrail:HadResetRed()
    local itemRefId, needNum = self:GetResetCost()
    if needNum == 0 then
        local time = tonumber(LPlayerPrefs.desireTrailResetRed) or 0
        if time > 0 and LUtil.IsToDay(time) then
            return false
        end
        return true
    end
    return false
end

-- 保存今日重置红点
function ModelDesireTrail:SaveTodyResetRed()
    local curTime = math.ceil(GetTimestamp())

    local time = tonumber(LPlayerPrefs.desireTrailResetRed) or 0
    if time > 0 and LUtil.IsToDay(time) then
        return
    end

    LPlayerPrefs.SetDesireTrailResetRed(curTime)
    FireEvent(EventNames.DESIRE_TRAIL_BASE_INFO)
end

-- 活动战令红点
function ModelDesireTrail:HadActivityRed()
    local dataList = gModelActivity:GetActivityDataByModelId(gModelActivity.MODEL_PASSC)
    for _, v in ipairs(dataList) do
        if gModelRedPoint:CheckActivityShowRed(v.sid) then
            return true
        end
    end
    return false
end

-- 挑战次数红点
function ModelDesireTrail:HadChallengeRed()
    if self._hadShowChallengeRed then
        return false
    end
    return self:GetChallengeCount() > 0
end

-- 保存挑战次数红点
function ModelDesireTrail:SaveChallengeRed()
    if self:GetChallengeCount() > 0 then
        local had = self._hadShowChallengeRed
        self._hadShowChallengeRed = true
        if not had then
            FireEvent(EventNames.DESIRE_TRAIL_BASE_INFO)
        end
    end
end

-- true: 表示有红点
function ModelDesireTrail:HadRed()
    if not gModelFunctionOpen:CheckIsOpened(ModelDesireTrail.MainFuncId, false) then
        return false
    end

    -- 挑战次数红点
    if self:HadChallengeRed() then
        return true
    end

    -- 任务红点
    if self:HadTaskRed(nil) then
        return true
    end

    -- 重置红点
    if self:HadResetRed() then
        return true
    end

    -- 活动战令红点
    if self:HadActivityRed() then
        return true
    end

    return false
end

-- true: 表示最后一个格子
function ModelDesireTrail:IsLastGrid(y)
    local count = tableSize(self._gridMap)
    return y == count - 1
end

-- true: 表示开启一键碾压
function ModelDesireTrail:IsCrushingOpen(showTips)
    local ref = self:GetConfRef()
    if self._clearanceCount < ref.passNum then
        if showTips then
            GF.ShowMessage(ccClientText(45439, ref.passNum - self._clearanceCount))
        end
        return false
    end

    if self:GetChallengeCount() == 0 then
        if showTips then
            GF.ShowMessage(ccClientText(45430))
        end
        return false
    end
    return true
end

-- ture: 表示开启扫荡
function ModelDesireTrail:IsSweepOpen(showTips)
    if gModelFunctionOpen:CheckIsOpened(16800060, showTips) then
        if self:GetChallengeCount() == 0 and showTips then
            if showTips then
                GF.ShowMessage(ccClientText(45430))
            end
            return false
        end
        return true
    else
        return false
    end
end

-- true: 表示正在扫荡中
function ModelDesireTrail:IsSweeping(showTips)
    if self._sweeping then
        if showTips then
            GF.ShowMessage(ccClientText(45442))
        end
        return true
    end
    return false
end

-- 设置扫荡
function ModelDesireTrail:SetSweeping(isSweeping)
    self._sweeping = isSweeping
end

-- 保存战斗结果
function ModelDesireTrail:SaveSweepResult(pb)
    self._sweepResultPb = pb
end

-- 显示扫荡战斗结果
function ModelDesireTrail:ShowSweepResult()
    if self._sweepResultPb == nil then
        return
    end

    gModelBattle:OnCombatResultResp(self._sweepResultPb, 0)
    self._sweepResultPb = nil
end

-- endregion 数据 ----------------------------------------------------

-- region 配置 ----------------------------------------------------
-- 获取参数表
function ModelDesireTrail:GetConfRef()
    return GameTable.DreamlandConfigRef
end

-- 获取主题配置列表
function ModelDesireTrail:GetThemeRef(refId)
    return GameTable.DreamlandThemeRef[refId]
end

-- 获取当前主题格子上升下降动效
function ModelDesireTrail:GetCurThemeGridUpOrDownAnim()
    self._curThemeGridUpOrDownAnim = self._curThemeGridUpOrDownAnim or {}
    local list = self._curThemeGridUpOrDownAnim[self._themeRefId]
    if not list then
        local ref = self:GetThemeRef(self._themeRefId)
        list = string.split(ref.platform, ",")
        self._curThemeGridUpOrDownAnim[self._themeRefId] = list
    end

    -- up down
    return list[1], list[2]
end

-- 获取难度配置列表
function ModelDesireTrail:GetLevList()
    return GameTable.DreamlandThemeRef
end

-- 事件配置
function ModelDesireTrail:GetEventConfig(refId)
    return GameTable.DreamlandEventRef[refId]
end

-- 获取事件名
function ModelDesireTrail:GetEventName(eventRefId)
    local eventRef = self:GetEventConfig(eventRefId)
    return ccLngText(eventRef.name) or ""
end

-- 获取战斗场景地图id
function ModelDesireTrail:GetBattleMapId()
    local themeId = self._themeRefId
    local cfg = self:GetThemeRef(themeId)
    return cfg.battleScene
end

-- 获取事件奖励配置
function ModelDesireTrail:GetEventAwardRef(eventRefId, floor, lev)
    if not self._eventAwardRef then
        self._eventAwardRef = {}
        for k, v in pairs(GameTable.DreamlandRewardRef) do
            if not self._eventAwardRef[v.rewardGroup] then
                self._eventAwardRef[v.rewardGroup] = {}
            end
            if not self._eventAwardRef[v.rewardGroup][v.floor] then
                self._eventAwardRef[v.rewardGroup][v.floor] = {}
            end
            table.insert(self._eventAwardRef[v.rewardGroup][v.floor], v)
        end
    end

    local rewardGroup = self:GetEventRewardGroup(eventRefId)

    lev = lev or gModelPlayer:GetPlayerLv()
    if floor == -1 then
        -- 终点奖励
        return self._eventAwardRef[rewardGroup][floor][1]
    end

    local list = self._eventAwardRef[rewardGroup][floor] or {}
    for i, v in ipairs(list) do
        if v.levelMin <= lev and lev <= v.levelMax then
            return v
        end
    end

    return nil
end

-- 获取事件奖励物品列表
function ModelDesireTrail:GetEventAwardItemList(eventRefId, floor, lev)
    lev = lev or gModelPlayer:GetPlayerLv()

    local ref = self:GetEventAwardRef(eventRefId, floor, lev)
    if not ref then
        return {}
    end

    local itemList = LUtil.GetRefItemDataList(ref.reward)
end

-- 获取事件奖励组id
function ModelDesireTrail:GetEventRewardGroup(eventRefId)
    local eventRef = self:GetEventConfig(eventRefId)
    local curRef = self:GetCurThemeRef()

    local pattern = curRef.pattern
    local list = string.split(eventRef.reward, "|")
    for i, v in ipairs(list) do
        local tab = string.split(v, "=")
        if tonumber(tab[1]) == pattern then
            return tonumber(tab[2])
        end
    end
    return nil
end

-- 获得英雄数据
function ModelDesireTrail:GetHeroData(id)
    if self._monsterPb then
        for k, v in ipairs(self._monsterPb.heroInfo) do
            if v.id == id then
                return v
            end
        end
    end
    return nil
end

-- endregion 配置 ----------------------------------------------------

-- region 地图处理 ----------------------------------------------------
-- 点击格子
function ModelDesireTrail:OnClickGrid(y, x)
    local data = self:GetGridData(y, x)
    if not data then
        return
    end
    local eventRefId = data.refId
    local eventRef = self:GetEventConfig(eventRefId)

    if eventRef.type == 1 then
        -- 怪物
        GF.OpenWnd("UIDesireTrailMonsterTips", { x = x, y = y, eventRefId = eventRefId })
    elseif eventRef.type == 3 then
        -- 宝箱
        GF.OpenWnd("UIDesireTrailBoxTips", { x = x, y = y, eventRefId = eventRefId })
    end
end

-- endregion 地图处理 ----------------------------------------------------


return ModelDesireTrail
