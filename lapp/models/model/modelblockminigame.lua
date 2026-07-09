---
--- Created by wzz.
--- DateTime: 2024/6/11
--- 方块小游戏 model 类


---@class ModelBlockMiniGame:LModel
local ModelBlockMiniGame = LxClass("ModelBlockMiniGame", LModel)


ModelBlockMiniGame.AwardState = {
    CanGet = 1, -- 可领取
    UnGet = 2,  -- 未领取
    HadGet = 3  -- 已领取
}
ModelBlockMiniGame.COMMON_MODE = 1		-- 普通模式
ModelBlockMiniGame.ENDLESS_MODE = 2		-- 无尽模式
ModelBlockMiniGame.WX_BS_MODE = 3		-- 微信提审

ModelBlockMiniGame.FuncId = 33000001

function ModelBlockMiniGame:ModelBlockMiniGame()
    -- 已通关的最大关卡
    self._passMaxLev = 0
    self._endlessPassMaxLev = 0
    self._wxBsMaxLev = 0
    
    -- 已领取奖励列表
    self._hadAwardList = {}

    -- 当前关卡例计时
    self._curLevLeftTime = 0

    -- 开始游戏是否大于5分钟
    self._isOutFiveMin = false
end

function ModelBlockMiniGame:OnModelInit()
    self:ModelNetMsgRecv(LProtoIds.BlockMiniGameInfoResp, function(...) self:OnBlockMiniGameInfoResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.BlockMiniGamePassRewardResp, function(...) self:OnBlockMiniGamePassRewardResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.BlockMiniGamePassResp, function(...) self:OnBlockMiniGamePassResp(...) end)
end

--在协议数据处理完之后需要调用finish
function ModelBlockMiniGame:OnModelRequest()
    local isOpen = gModelFunctionOpen:CheckIsOpened(ModelBlockMiniGame.FuncId, false)
    if isOpen then
        self:BlockMiniGameInfoReq()
    end

    self:ModelFinish()
end

-- region 协议 ----------------------------------------------------

-- 方块小游戏信息 请求
function ModelBlockMiniGame:BlockMiniGameInfoReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.BlockMiniGameInfoReq)
    SendMessage(pb, LProtoIds.BlockMiniGameInfoReq)

    if MiniGameLog then
        -- 找错测试用
        print("方块小游戏信息 请求" .. os.clock())
    end

end

-- 方块小游戏信息 返回
function ModelBlockMiniGame:OnBlockMiniGameInfoResp(pb)
    self._passMaxLev = pb.barrierId

    -- 值为固定顺序值，1，2，3...
    for k, v in ipairs(pb.rewardIds) do
        self._hadAwardList[v] = v
    end

    if MiniGameLog then
        -- 找错测试用
        print("方块小游戏信息 返回" .. os.clock())
    end
end

-- 领取通关奖励 请求
function ModelBlockMiniGame:BlockMiniGamePassRewardReq(rewardIds)
    local pb = LProtoHelper.CreateProto(LProtoIds.BlockMiniGamePassRewardReq)
    for k, v in ipairs(rewardIds) do
        table.insert(pb.rewardIds, v)
    end

    SendMessage(pb, LProtoIds.BlockMiniGamePassRewardReq)
end

-- 领取通关奖励 返回
function ModelBlockMiniGame:OnBlockMiniGamePassRewardResp(pb)
    for k, v in ipairs(pb.rewardIds) do
        self._hadAwardList[v] = v
    end

    FireEvent(EventNames.BLOCKMINIGAME_AWARD)
end

-- 通关 请求
function ModelBlockMiniGame:BlockMiniGamePassReq(barrierId, result, useTime, silence)
    local ref = self:GetLevRef(barrierId)
    if(ref.type == ModelBlockMiniGame.WX_BS_MODE)then
        self:ShowWxBsGameOver(barrierId,result)
        return
    end
    
    local pb = LProtoHelper.CreateProto(LProtoIds.BlockMiniGamePassReq)
    pb.barrierId = barrierId
    pb.result = result
    pb.useTime = useTime
    if silence == nil then
        pb.silence = false
    else
        pb.silence = silence
    end

    SendMessage(pb, LProtoIds.BlockMiniGamePassReq)
end

-- 通关 返回
function ModelBlockMiniGame:OnBlockMiniGamePassResp(pb)
    if pb.silence then
        return
    end

    local ref = self:GetLevRef(pb.barrierId)
    if pb.result == 2 then
        -- 失败
        GF.OpenWnd("UIBlockMiniGameFail", { ref = ref })
        return
    end

    local isFirstPass = pb.barrierId > self._passMaxLev
    if isFirstPass then
        self._passMaxLev = pb.barrierId
    end

    GF.OpenWnd("UIBlockMiniGameWin", { ref = ref, isFirstPass = isFirstPass })
end

-- endregion ----------------------------------------------------

-- 直接退出游戏
function ModelBlockMiniGame:ExitGame(refId, useTime)
    self:BlockMiniGamePassReq(refId, 2, useTime, true)
end

-- 是否有红点
function ModelBlockMiniGame:IsHadRed()

end

-- true：表示需要弹帮助界面
function ModelBlockMiniGame:NeedPopHelp()
    return self._passMaxLev == 0
end

-- 已通关的最大关卡
function ModelBlockMiniGame:GetPassMaxLev(LevelMode)
    local levelMode = LevelMode
    if not LevelMode then
        levelMode = ModelBlockMiniGame.COMMON_MODE
    end
    local maxLevel
    if levelMode == ModelBlockMiniGame.COMMON_MODE then
        maxLevel = self._passMaxLev
    elseif levelMode == ModelBlockMiniGame.ENDLESS_MODE then
        maxLevel = self._endlessPassMaxLev
    else
        maxLevel = self._wxBsMaxLev
    end
    local levelRef = self:GetLevRef(maxLevel)
    if levelRef then
        return levelRef.level
    end
    return 0
end

-- 已通关全部
function ModelBlockMiniGame:IsPassAll()
    return self._passMaxLev == #GameTable.BlockLevelRef
end

-- 已领取的最大奖励Id
function ModelBlockMiniGame:GetHadMaxAwardId()
    return self._hadAwardList[#self._hadAwardList] or 0
end

-- 获取关卡奖励列表
function ModelBlockMiniGame:GetCurAwardList()
    local BlockRewardRef = GameTable.BlockRewardRef

    local minRefId = self:GetHadMaxAwardId()
    minRefId = math.max(minRefId, 1)
    minRefId = math.min(minRefId, #BlockRewardRef - 3)

    local maxRefId = math.min(minRefId + 3, #BlockRewardRef)

    local list = {}
    local min = 0
    local max = 0
    for i = minRefId, maxRefId do
        local ref = BlockRewardRef[i]
        table.insert(list, ref)
        max = ref.num
    end

    if BlockRewardRef[minRefId - 1] then
        min = BlockRewardRef[minRefId - 1].num
    else
        min = 0
    end

    return list, min, max
end

-- 获取奖励状态，1：可领取，2：未领取，3：已领取
function ModelBlockMiniGame:GetAwardStatus(refId)
    local hadMaxId = self:GetHadMaxAwardId()
    local ref = GameTable.BlockRewardRef[refId]

    if ref.refId <= hadMaxId then
        return ModelBlockMiniGame.AwardState.HadGet
    end

    local passMax = self:GetPassMaxLev()
    if ref.num <= passMax then
        return ModelBlockMiniGame.AwardState.CanGet
    end
    return ModelBlockMiniGame.AwardState.UnGet
end

-- 获取当前关卡配置
function ModelBlockMiniGame:GetCurLevRef(LevelMode)
    local levId
    if not LevelMode then
        LevelMode = ModelBlockMiniGame.COMMON_MODE
    end

    if LevelMode == ModelBlockMiniGame.COMMON_MODE then
        levId = self._passMaxLev
    elseif LevelMode == ModelBlockMiniGame.ENDLESS_MODE then
        levId = self._endlessPassMaxLev
    else
        levId = self._wxBsMaxLev
    end

    if levId == 0 then
        if LevelMode == ModelBlockMiniGame.COMMON_MODE then
            return self:GetLevRef(1)
        elseif LevelMode == ModelBlockMiniGame.ENDLESS_MODE then
            return self:GetLevRef(1001)
        else
            return self:GetLevRef(100001)
        end
    end
    levId = self:GetNextLev(levId)
    return self:GetLevRef(levId)
end

-- 获取当前关卡配置
function ModelBlockMiniGame:GetAllLevRef()
    return GameTable.BlockLevelRef
end

-- 获取关卡配置
function ModelBlockMiniGame:GetLevRef(refId)
    return GameTable.BlockLevelRef[refId]
end

-- 获取下一关卡
function ModelBlockMiniGame:GetNextLev(lev)
    local ref = self:GetLevRef(lev + 1)
    if not ref then
        return lev
    end
    local passMax = self:GetPassMaxLev()
    if ref.refId <= passMax then
        return ref.refId
    end

    local isOpen = gModelFunctionOpen:CheckOpenCondition(ref.condition)
    if isOpen then
        return ref.refId
    end
    return lev
end

-- 获取当前关卡剩余时间（秒）
function ModelBlockMiniGame:GetCurLevLeftTime(type)
    if self._curLevLeftTime == 0 then
        local ref = self:GetCurLevRef(type)
        self._curLevLeftTime = ref.time
    end
    return self._curLevLeftTime
end

-- 设置当前关卡剩余时间（秒）
function ModelBlockMiniGame:SetCurLevLeftTime(type)
    if self._curLevLeftTime == 0 then
        local ref = self:GetCurLevRef(type)
        self._curLevLeftTime = ref.time
    end
    return self._curLevLeftTime
end

-- 获取当前关卡的随机方块id
function ModelBlockMiniGame:GetRandomBlockRefId(ref)
    local levId = ref.refId
    self._blockWeight = self._blockWeight or {}
    if not self._blockWeight[levId] then
        self._blockWeight[levId] = {}

        local list1 = string.split(ref.blockWeight, ",")
        local list = {}
        local total = 0
        for _, v in ipairs(list1) do
            local list2 = string.split(v, "=")
            local weight = tonumber(list2[2])
            local refId = tonumber(list2[1])
            total = total + weight
            table.insert(list, { refId = refId, weight = weight })
        end
        table.sort(list, function(a, b)
            if a.weight ~= b.weight then
                return a.weight < b.weight
            end
            return a.refId < b.refId
        end)

        local weightIndex = 0
        for k, v in ipairs(list) do
            weightIndex = weightIndex + v.weight
            v.weightIndex = weightIndex
        end
        self._blockWeight[levId] = { list = list, total = total }
    end
    local weight = math.random(1, self._blockWeight[levId].total)
    for _, v in ipairs(self._blockWeight[levId].list) do
        if v.weightIndex >= weight then
            return v.refId
        end
    end
    return self._blockWeight[levId].list[1].refId
end

-- 获取方块配置
function ModelBlockMiniGame:GetBlockRef(refId)
    return GameTable.BlockTypeRef[refId]
end

-- 获取怪物配置
function ModelBlockMiniGame:GetMonsterRef(monsterRefId)
    return GameTable.BlockMonsterRef[monsterRefId]
end

-- 获取英雄展示配置
function ModelBlockMiniGame:GetHeroEffectRef(monsterRefId)
    local ref = self:GetMonsterRef(monsterRefId)
    return GameTable.CharacterEffectRef[ref.monsterShow]
end

-- 获取技能配置表
function ModelBlockMiniGame:GetSkillRef(skillId)
    return GameTable.BlockEffectRef[skillId]
end

-- 获取消行配置
function ModelBlockMiniGame:GetClearLineRef(lineNum)
    return GameTable.BlockContinuousSterilizationRef[lineNum]
end

--region #5864 【W微信小程序】提审模式下前置小游戏功能
--region 获取微小提审第一关
function ModelBlockMiniGame:GetWXBSFirstRefId()
    local ref = self:GetWXBSRef()
    return (ref and ref[1]) and ref[1].refId or nil
end
--endregion
--region 获取微小提审关卡
function ModelBlockMiniGame:GetWXBSRef()
    local allDataList = GameTable.BlockLevelRef
    local type = 3
    local dataList = {}
    for k, v in pairs(allDataList) do
        if v.type == type then
            table.insert(dataList,v)
        end
    end
    table.sort(dataList, function(a, b)
        return a.refId < b.refId
    end)
    return dataList
end
--endregion
--region 开始游戏是否大于5分钟
function ModelBlockMiniGame:SetIsOutFiveMin(b)
    self._isOutFiveMin = b
end
function ModelBlockMiniGame:GetIsOutFiveMin()
    return self._isOutFiveMin
end
--endregion

--region 微信提审进入游戏提示
function ModelBlockMiniGame:ShowEntryGameMainTips(cancelFunc)
    local _isOutFiveMin = self:GetIsOutFiveMin()
    if(not _isOutFiveMin)then
        cancelFunc()
        return
    end
    gModelGeneral:OpenUIOrdinTips({ refId = 530001, func = function()
    --gModelGeneral:OpenUIOrdinTips({ refId = 470001, func = function()
        self:SetIsOutFiveMin(false)
        GF.ChangeMap("LCityMap")
        GF.CloseWndByName("UIBlockMiniGame")
        GF.CloseWndByName("UIBlockMiniGameFail")
        GF.CloseWndByName("UIBlockMiniGameWin")
    end ,leftFunc = cancelFunc})
end
--endregion

--region 类型3 微小提审游戏结束弹框，不走协议
function ModelBlockMiniGame:ShowWxBsGameOver(barrierId, result)
    local ref = self:GetLevRef(barrierId)
    if result == 2 then
        -- 失败
        GF.OpenWnd("UIBlockMiniGameFail", { ref = ref })
        return
    end

    local isFirstPass = barrierId > self._wxBsMaxLev
    if isFirstPass then
        self._wxBsMaxLev = barrierId
    end
    GF.OpenWnd("UIBlockMiniGameWin", { ref = ref, isFirstPass = isFirstPass })
end
--endregion
function ModelBlockMiniGame:SetWXBSFlag(b)
    self._wxBsFlag = b
    self:SetWXBSCameraFlag(true)
end
function ModelBlockMiniGame:GetWXBSFlag()
    return self._wxBsFlag
end
function ModelBlockMiniGame:SetWXBSCameraFlag(b)
    self._wxBsCameraFlag = b
end
function ModelBlockMiniGame:GetWXBSCameraFlag()
    return self._wxBsCameraFlag
end

function ModelBlockMiniGame:CheckNeedLoginEntranceGame()
    if CS.IsWebGL() and LWxHelper.IsWxPlatform() and PRODUCT_G_VER ~= 0 then
        local packageId = gModelActivity:GetPackageId()
        if packageId == 505 then
            return true
        end
    end
    return false
end

--endregion
return ModelBlockMiniGame
