---
--- Created by wzz.
--- DateTime: 2024/5/8
--- 武神殿


---@class ModelWarTemple:LModel
local ModelWarTemple = LxClass("ModelWarTemple", LModel)

-- 武神殿功能id
ModelWarTemple.Main_FuncId = 13800000

-- 武神殿排行榜配置id
ModelWarTemple.Rank_RefId = 509

-- 奖励状态
ModelWarTemple.AwardState = {
    CanGet = 1,    -- 可以领取
    CanNotGet = 2, -- 不能领取
    HadGet = 3,    -- 已领取
}

function ModelWarTemple:ModelWarTemple()
    -- 基本信息
    self._baseInfo          = {}
    -- 挑战列表
    self._challengeList     = {}
    -- 已领取的神殿奖励id
    self._palaceRewardIdMap = {}
    -- 已领取的排名奖励id
    self._rankRewardIdMap   = {}
    -- 战报信息
    self._recordInfos       = {}
    -- 刷新挑战列表剩余时间
    self._refreshRecordTime = 0
    -- 已播特效的神殿
    self._playedEffPalaceId = nil
    -- 主界面排行榜信息
    self._mainUiRankPb      = nil
end

function ModelWarTemple:OnModelInit()
    self:ModelNetMsgRecv(LProtoIds.WarTempleInfoResp, function(...) self:OnWarTempleInfoResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.WarTempleBuyChallengeCntResp, function(...) self:OnWarTempleBuyChallengeCntResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.WarTempleChallengeListUpdateResp,
        function(...) self:OnWarTempleChallengeListUpdateResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.WarTemplePalaceRewardResp, function(...) self:OnWarTemplePalaceRewardResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.WarTempleRankRewardResp, function(...) self:OnWarTempleRankRewardResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.WarTempleEgffigyLvUpResp, function(...) self:OnWarTempleEgffigyLvUpResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.WarTempleBattleRecordResp, function(...) self:OnWarTempleBattleRecordResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.WarTempleShowResp, function(...) self:OnWarTempleShowResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.WarTempleQuickFightResp, function(...) self:OnWarTempleQuickFightResp(...) end)
    self:ModelNetMsgRecv(LProtoIds.WarTempleRankResp, function(...) self:OnWarTempleRankResp(...) end)
end

--在协议数据处理完之后需要调用finish
function ModelWarTemple:OnModelRequest()
    if gModelFunctionOpen:CheckIsOpened(ModelWarTemple.Main_FuncId, false) then
        self:WarTempleInfoReq()
    end

    self:ModelFinish()
end

-- region 协议 ----------------------------------------------------

-- 武神殿数据 请求
function ModelWarTemple:WarTempleInfoReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.WarTempleInfoReq)
    SendMessage(pb, LProtoIds.WarTempleInfoReq)
end

-- 武神殿数据 返回
function ModelWarTemple:OnWarTempleInfoResp(pb)
    self._baseInfo = pb
    self._challengeList = pb.challengeList

    for i, v in ipairs(pb.palaceRewardIds) do
        self._palaceRewardIdMap[v] = v
    end

    for i, v in ipairs(pb.rankRewardIds) do
        self._rankRewardIdMap[v] = v
    end

    if not self._playedEffPalaceId then
        self._playedEffPalaceId = pb.palace
    end

    FireEvent(EventNames.WARTEMPLE_INFO_RETURN)
end

-- 购买挑战次数 请求
function ModelWarTemple:WarTempleBuyChallengeCntReq(times)
    local pb = LProtoHelper.CreateProto(LProtoIds.WarTempleBuyChallengeCntReq)
    pb.challengeCnt = times
    SendMessage(pb, LProtoIds.WarTempleBuyChallengeCntReq)
end

-- 购买挑战次数 返回
function ModelWarTemple:OnWarTempleBuyChallengeCntResp(pb)
    self._baseInfo.buyChallengeCnt = pb.buyChallengeCnt
    self._baseInfo.challengeCnt = pb.challengeCnt

    FireEvent(EventNames.WARTEMPLE_INFO_RETURN)

    GF.ShowMessage(ccClientText(42070,  pb.challengeCnt))
end

-- 刷新挑战列表 请求
function ModelWarTemple:WarTempleChallengeListUpdateReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.WarTempleChallengeListUpdateReq)
    SendMessage(pb, LProtoIds.WarTempleChallengeListUpdateReq)
end

-- 刷新挑战列表 返回
function ModelWarTemple:OnWarTempleChallengeListUpdateResp(pb)
    self._challengeList = pb.challengeList
    FireEvent(EventNames.WARTEMPLE_CHALLENGE_LIST_RETURN)
end

-- 领取神殿奖励 请求
function ModelWarTemple:WarTemplePalaceRewardReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.WarTemplePalaceRewardReq)
    SendMessage(pb, LProtoIds.WarTemplePalaceRewardReq)
end

-- 领取神殿奖励 返回
function ModelWarTemple:OnWarTemplePalaceRewardResp(pb)
    for i, v in ipairs(pb.palaceRewardIds) do
        self._palaceRewardIdMap[v] = v
    end
    FireEvent(EventNames.WARTEMPLE_INFO_RETURN)
end

-- 领取排名目标奖励 请求
function ModelWarTemple:WarTempleRankRewardReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.WarTempleRankRewardReq)
    SendMessage(pb, LProtoIds.WarTempleRankRewardReq)
end

-- 领取排名目标奖励 返回
function ModelWarTemple:OnWarTempleRankRewardResp(pb)
    for i, v in ipairs(pb.rankRewardIds) do
        self._rankRewardIdMap[v] = v
    end
    FireEvent(EventNames.WARTEMPLE_INFO_RETURN)
end

-- 升级武神雕像 请求
function ModelWarTemple:WarTempleEgffigyLvUpReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.WarTempleEgffigyLvUpReq)
    SendMessage(pb, LProtoIds.WarTempleEgffigyLvUpReq)
end

-- 升级武神雕像 返回
function ModelWarTemple:OnWarTempleEgffigyLvUpResp(pb)
    self._baseInfo.egfffigyLv = pb.egfffigyLv
    FireEvent(EventNames.WARTEMPLE_INFO_RETURN)
end

-- 查看战报 请求
function ModelWarTemple:WarTempleBattleRecordReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.WarTempleBattleRecordReq)
    SendMessage(pb, LProtoIds.WarTempleBattleRecordReq)
end

-- 查看战报 返回
function ModelWarTemple:OnWarTempleBattleRecordResp(pb)
    self._recordInfos = pb.recordInfos
    FireEvent(EventNames.WARTEMPLE_REPORT_RETURN)
end

-- 展示神殿前x位 请求
function ModelWarTemple:WarTempleShowReq(palace)
    local pb = LProtoHelper.CreateProto(LProtoIds.WarTempleShowReq)
    pb.palace = palace
    SendMessage(pb, LProtoIds.WarTempleShowReq)
end

-- 展示神殿前x位 返回
function ModelWarTemple:OnWarTempleShowResp(pb)
    FireEvent(EventNames.WARTEMPLE_SHOW_LIST_RETURN, pb.showInfoList)
end

-- 快速挑战 请求
function ModelWarTemple:WarTempleQuickFightReq(npcId)
    local pb = LProtoHelper.CreateProto(LProtoIds.WarTempleQuickFightReq)
    pb.npcId = npcId
    SendMessage(pb, LProtoIds.WarTempleQuickFightReq)
end

-- 快速挑战 返回
function ModelWarTemple:OnWarTempleQuickFightResp(pb)
    self:WarTempleInfoReq()
    gModelRank:OnRankReq(2, gModelRank.RANK_WARTEMPLE, 1, 150)
    GF.OpenWnd("UIWarTempleFastFight", {pb = pb})
    gModelWarTemple:WarTempleRankReq()
end

-- 获取排行榜数据 请求
function ModelWarTemple:WarTempleRankReq(num)
    local pb = LProtoHelper.CreateProto(LProtoIds.WarTempleRankReq)
    pb.num = num or 3
    SendMessage(pb, LProtoIds.WarTempleRankReq)
end

-- 获取排行榜数据 返回
function ModelWarTemple:OnWarTempleRankResp(pb)
    self._mainUiRankPb = pb
    FireEvent(EventNames.WARTEMPLE_MAIN_RANK_RETURN)
end

-- endregion ----------------------------------------------------

-- region 数据 ----------------------------------------------------
-- 获取武神殿基本信息
function ModelWarTemple:GetBaseInfo()
    return self._baseInfo
end

-- 主界面排行榜信息
function ModelWarTemple:GetMainUiRankPb()
    return self._mainUiRankPb
end

-- 获取当前殿名字
function ModelWarTemple:GetPalaceName()
    if not next(self._baseInfo) then
        return ""
    end
    
    if nil == self._baseInfo or nil == self._baseInfo.palace then 
        return ""
    end 
    
    local ref = GameTable.BattleTemplePalaceRef[self._baseInfo.palace]
    if nil == ref or nil ==ref.name then
        return ""
    end 
    
    return ccLngText(ref.name)
end

-- 获取雕像等级
function ModelWarTemple:GetEffigyLev()
    local ref = GameTable.BattleTempleEeffigyRef[self._baseInfo.egfffigyLv]
    return ref.lvNow
end

-- 获取挑战列表
function ModelWarTemple:GetChallengeList()
    return self._challengeList
end

-- 获取战报列表
function ModelWarTemple:GetRecordInfos()
    return self._recordInfos
end

-- 获取战报列表刷新剩余时间
function ModelWarTemple:GetLeftRefreshRecordTime()
    return math.max(0, GameTable.BattleTempleConfigRef.refreshTime - (os.time() - self._refreshRecordTime))
end

-- 获取战报列表刷新剩余时间
function ModelWarTemple:SaveRefreshRecordTime()
    self._refreshRecordTime = os.time()
end

-- 获取购买挑战次数价格
function ModelWarTemple:GetBuyFightTimesPrice(times)
    local list = self:GetBuyFightTimesPriceList()
    local curTimes = #list - self._baseInfo.buyChallengeCnt + 1
    local totalPrice = 0
    for i = curTimes, curTimes + times - 1 do
        totalPrice = totalPrice + list[i]
    end
    return totalPrice
end

-- 获取挑战次数价格列表
function ModelWarTemple:GetBuyFightTimesPriceList()
    if not self._buyFightTimesPriceList then
        self._buyFightTimesPriceList = {}
        local strList = string.split(GameTable.BattleTempleConfigRef.challengeNumConsume, ";")
        local list = {}
        for i, v in ipairs(strList) do
            local tab = string.split(v, "=")
            list[tonumber(tab[1])] = tonumber(tab[2])
        end
        self._buyFightTimesPriceList = list
    end
    local list = table.clone(self._buyFightTimesPriceList)

    local price = list[#list]
    local vipAdd = 0
    for i = 1, vipAdd do
        table.insert(list, price)
    end
    return list
end

-- 获取神殿奖励状态
function ModelWarTemple:GetPalaceRewardState(refId)
    if self._palaceRewardIdMap[refId] then
        return ModelWarTemple.AwardState.HadGet
    end

    if self._baseInfo.maxPalace >= refId then
        return ModelWarTemple.AwardState.CanGet
    end

    return ModelWarTemple.AwardState.CanNotGet
end

-- 获取神殿目标奖励状态
function ModelWarTemple:GetTargetRewardState(refId)
    if self._rankRewardIdMap[refId] then
        return ModelWarTemple.AwardState.HadGet
    end

    local ref = GameTable.BattleTempleCombatAwardRef[refId]
    local list = string.split(ref.finishCond, ",")
    local needRank = tonumber(list[2])
    local list2 = string.split(list[1], "=")
    local needPalace = tonumber(list2[3])


    if self._baseInfo.maxPalace > needPalace then
        return ModelWarTemple.AwardState.CanGet
    end
    if self._baseInfo.maxPalace == needPalace then
        if self._baseInfo.maxRank <= needRank then
            return ModelWarTemple.AwardState.CanGet
        end
    end

    return ModelWarTemple.AwardState.CanNotGet
end

-- true：表示在结算期间
function ModelWarTemple:DuringSettlement(showTips)
    local curTime = GetTimestamp()

    if curTime < self._baseInfo.endSettleTime and curTime > self._baseInfo.settleTime then
        if showTips then
            GF.ShowMessage(ccClientText(42068))
        end
        return true
    end
    return false
end

-- 保存今日免费挑战红点
function ModelWarTemple:SaveTodyWarTempleFreeFightRed()
    local curTime = math.ceil(GetTimestamp())

    local time = tonumber(LPlayerPrefs.warTempleFreeFight) or 0
    if time > 0 and LUtil.IsToDay(time) then
        return
    end

    LPlayerPrefs.SetWarTempleFreeFight(curTime)
    FireEvent(EventNames.WARTEMPLE_INFO_RETURN)
end

-- ture 表示有免费挑战红点
function ModelWarTemple:HadFreeFightRed()
    if self._baseInfo.freeChallengeCnt == 0 then
        return false
    end

    if self:DuringSettlement(false) then
        return false
    end

    return not LUtil.IsToDay(tonumber(LPlayerPrefs.warTempleFreeFight) or 0)
end

-- true 表示有神殿奖励
function ModelWarTemple:HadPalaceReward()
    local CanGet = ModelWarTemple.AwardState.CanGet
    for k, v in pairs(GameTable.BattleTemplePalaceRef) do
        if self:GetPalaceRewardState(v.refId) == CanGet then
            return true
        end
    end
    return false
end

-- true 表示有神殿目标奖励
function ModelWarTemple:HadTargetReward()
    local CanGet = ModelWarTemple.AwardState.CanGet
    for k, v in pairs(GameTable.BattleTempleCombatAwardRef) do
        if self:GetTargetRewardState(v.refId) == CanGet then
            return true
        end
    end
    return false
end

-- true 表示神殿有点赞
function ModelWarTemple:HadLike()
    for k, v in pairs(GameTable.BattleTemplePalaceRef) do
        if v.like > 0 then
            if not gModelRank:IsLikeLimit(v.like, false) then
                return true
            end
        end
    end
    return false
end

-- 神殿红点
function ModelWarTemple:HadRed()
    if not gModelFunctionOpen:CheckIsOpened(ModelWarTemple.Main_FuncId, false) then
        return false
    end

    if not next(self._baseInfo) then
        return false
    end

    if self:HadFreeFightRed() then
        return true
    end

    if self:HadLike() then
        return true
    end
    if self:HadPalaceReward() then
        return true
    end
    if self:HadTargetReward() then
        return true
    end

    if self:CanLvUpEgffigy() then
        return true
    end

    return false
end

-- 判断神殿是否需要播特效
function ModelWarTemple:NeedPlayEff(palace)
    if self._playedEffPalaceId == nil then
        return true
    end

    if self._playedEffPalaceId < palace and self._baseInfo.palace == palace then
        self._playedEffPalaceId = palace
        return true
    end
    return false
end

-- endregion ------------------------------------------------------

-- region 配置 ----------------------------------------------------
-- 获取武神殿配置列表
function ModelWarTemple:GetWarTempleRefList()
    if not self._warTempleRefList then
        self._warTempleRefList = {}
        for i, v in pairs(GameTable.BattleTemplePalaceRef) do
            table.insert(self._warTempleRefList, v)
        end
        table.sort(self._warTempleRefList, function(a, b)
            return a.sort < b.sort
        end)
    end
    return self._warTempleRefList
end

-- 获取武神殿配置
function ModelWarTemple:GetWarTempleRef(placeRefId)
    return GameTable.BattleTemplePalaceRef[placeRefId]
end

-- 获取武神殿目标奖励配置列表
function ModelWarTemple:GetWarTempleTargetRefList()
    if not self._warTempleTargetRefList then
        self._warTempleTargetRefList = {}
        for i, v in pairs(GameTable.BattleTempleCombatAwardRef) do
            table.insert(self._warTempleTargetRefList, v)
        end
        table.sort(self._warTempleTargetRefList, function(a, b)
            return a.sort < b.sort
        end)
    end
    return self._warTempleTargetRefList
end

-- 获取每日排名奖励物品
function ModelWarTemple:GetDailyRewardItem(refId, rank)
    if not self._dailyReward then
        self._dailyReward = {}
        for k, v in pairs(GameTable.BattleTempleAwardRef) do
            if v.sort == 1 then
                if not self._dailyReward[v.PalacerId] then
                    self._dailyReward[v.PalacerId] = {}
                end
                self._dailyReward[v.PalacerId][v.rank] = v
            end
        end
    end

    if rank == 0 or refId == 0 then
        return LUtil.GetRefItemDataList(GameTable.BattleTempleConfigRef.alterAward)
    end
    local ref = self._dailyReward[refId][rank]
    return LUtil.GetRefItemDataList(ref.reward)
end

-- 初始化配置
function ModelWarTemple:InitEffigyRefMap()
    if not self._effigyRefMap then
        self._effigyRefMap = {}
        for i, v in pairs(GameTable.BattleTempleEeffigyRef) do
            self._effigyRefMap[v.lvNow] = v
        end
    end
end

-- 获取武神殿属性列表
function ModelWarTemple:GetWarTempleAttrList(lev)
    self:InitEffigyRefMap()

    local attrList = {}
    local ref = self._effigyRefMap[lev]
    if lev == 0 then
        attrList = LUtil.GetRefAttrData(ref.attrChange)
        for i, v in ipairs(attrList) do
            v.addValue = v.value
            v.value = 0
        end
    elseif ref.lvNext == -1 then
        attrList = LUtil.GetRefAttrData(ref.attrChange)
    else
        attrList = LUtil.GetRefAttrData(ref.attr)
        local addAttrList = LUtil.GetRefAttrData(ref.attrChange)
        for i, v in ipairs(attrList) do
            v.addValue = addAttrList[i].value
        end
    end
    return attrList
end

-- 返回参数1：true,表示雕像可以升级
-- 返回参数2：升级消耗物品列表
-- 返回参数3：true,表示已满级
function ModelWarTemple:CanLvUpEgffigy(showTips)
    self:InitEffigyRefMap()

    local lev = self:GetEffigyLev()
    local costList
    local ref = self._effigyRefMap[lev]
    if ref.lvNext == -1 then
        ref = self._effigyRefMap[lev - 1]
        costList = LUtil.GetRefItemDataList(ref.upNeed)
        if showTips then
            GF.ShowMessage(ccClientText(42021))
        end
        return false, costList, true
    end

    costList = LUtil.GetRefItemDataList(ref.upNeed)
    for i, v in ipairs(costList) do
        local haveNum = gModelItem:GetNumByRefId(v.refId)
        local needNum = v.count
        if haveNum < needNum then
            if showTips then
                local itemName = gModelItem:GetNameByRefId(v.refId)
                GF.ShowMessage(ccClientText(42039, itemName))
                gModelGeneral:OpenGetWayWnd({ itemId = v.refId })
            end
            return false, costList, false
        end
    end
    return true, costList, false
end

-- 获取神殿守卫展示的英雄id, 名字
function ModelWarTemple:GetShowHeroRefId(npcId)
    local ref = GameTable.BattleTempleDefendRef[npcId]
    local palaceRef = GameTable.BattleTemplePalaceRef[ref.PalacerId]
    local monsterRef = GameTable.MonsterFormationRef[ref.monster]
    return palaceRef.defendShow, ccLngText(monsterRef.name)
end

-- 获取英雄对应的头像 与 服务端下发的 play head 一致
function ModelWarTemple:GetHeroHeadByRefId(hoerRefId)
    local ref = gModelHero:GetHeroShowRefByRefId(hoerRefId, nil)
    return ref.rankingId
end

-- 跟据排行获取神殿守卫id, 名字, 神殿名字, 殿内排名
function ModelWarTemple:GetNpcIdByRank(rank)
    if not self._rankToNpcIdMap then
        self._rankToNpcIdMap = {}
        for k, v in pairs(GameTable.BattleTempleDefendRef) do
            self._rankToNpcIdMap[v.seat] = v
        end
    end
    rank = math.max(rank, 0)
    if rank == 0 then
        rank = self._rankToNpcIdMap[#self._rankToNpcIdMap].seat
    end

    local ref = self._rankToNpcIdMap[rank]
    local monsterRef = GameTable.MonsterFormationRef[ref.monster]
    local palaceRef = GameTable.BattleTemplePalaceRef[ref.PalacerId]

    return ref.refId, ccLngText(monsterRef.name), ccLngText(palaceRef.name), ref.rank
end

-- 获取排名为0时，的排行值
function ModelWarTemple:GetZeroRank()
    local max = 0
    for k, v in pairs(GameTable.BattleTempleMatchRef) do
        max = math.max(max, v.rankSectionMin)
    end
    return max + 1
end

-- 获取神殿配置by排名
function ModelWarTemple:GetWarTemplePalaceRefByRank(rank)
    for _, v in pairs(GameTable.BattleTemplePalaceRef) do
        if not string.isempty(v.rankScope) then
            local rankInfo = string.split(v.rankScope, ",")
            local min = tonumber(rankInfo[1])
            local max = tonumber(rankInfo[2])
            if rank >= min and rank <= max then
                return v
            end
        end
    end
end

-- endregion ------------------------------------------------------



return ModelWarTemple
