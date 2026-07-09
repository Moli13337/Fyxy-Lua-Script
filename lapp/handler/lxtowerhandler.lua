local LxBaseHandler = require("LApp.handler.LxBaseHandler")
---@class LxTowerHandler:LxBaseHandler
local LxTowerHandler = classX("LxTowerHandler",LxBaseHandler)

function LxTowerHandler:Initialize()
    LxBaseHandler.Initialize(self)
end

function LxTowerHandler:Dispose()
    LxBaseHandler.Dispose(self)
end

function LxTowerHandler:ClearHandler()
    LxBaseHandler.ClearHandler(self)
end

function LxTowerHandler:InitOk()
end

-- 完成登录后
function LxTowerHandler:LoginOk()
    -- 拉取玩家详细数据
end

function LxTowerHandler:InitHandler()
    self:AddMsgHandler(LxProtoIds.TowerBattleVideoResp, self.OnTowerBattleVideo, self)--录像
    self:AddMsgHandler(LxProtoIds.TowerSweepResp, self.OnTowerSweep, self)--扫荡
    self:AddMsgHandler(LxProtoIds.TowerNoBattlePassResp, self.OnTowerNoBattlePass, self)--免战通关
    self:AddMsgHandler(LxProtoIds.TowerBuySweepCountResp, self.OnTowerBuySweepCount, self)--购买扫荡次数
    self:AddMsgHandler(LxProtoIds.ReceiveTargetRewardResp, self.OnReceiveTargetRewardResp, self)--购买扫荡次数

    
end

function LxTowerHandler:OnTowerBattleVideo(pd)
    if pd.videoObj then
        ModuleCenter.Tower:SetTowerVideoInfo(pd.videoObj)

        FireEvent(EventNames.TOWER_VIDEO_UPDATE)
    end
    
end
--扫荡成功
function LxTowerHandler:OnTowerSweep(pd)
    if pd.rewardInfo then 
        ModuleCenter.Tower.sweepRwds = pd.rewardInfo
    end
    if pd.barrierRewards then
        ModuleCenter.Tower:SetSweepReward(pd.barrierRewards,pd.lastBarrier)
    end
    -- if pd.lastBarrier then ModuleCenter.Tower:SetTowerLastPassedLv(pd.lastBarrier) end
    if pd:HasField("dataObj") then -- 爬塔
        ModuleCenter.Tower:SetTowerInfo(pd.dataObj)
    end
    FireEvent(EventNames.TOWER_INFO_UPDATE)
end
--免战通关
function LxTowerHandler:OnTowerNoBattlePass(pd)
    -- ShowSysMsg("免战通关成功！")
    if pd:HasField("dataObj") then
        ModuleCenter.Tower:SetTowerInfo(pd.dataObj)
        FireEvent(EventNames.TOWER_INFO_UPDATE)
    end
    if pd.rewardInfo then
        local itemDatas = {}
        local itemType = ThingType.Item
        for k,v in ipairs(pd.rewardInfo.items or {}) do
            table.insert(itemDatas, {type=itemType, refId = v.refId, num =v.num,level = pd.passBarriers})
        end
    
        itemType = ThingType.Hero
        for k,v in ipairs(pd.rewardInfo.heros or {}) do
            table.insert(itemDatas, {type=itemType, refId = v.refId, num = 1,level = pd.passBarriers})
        end
        itemType = ThingType.Equip
        for k,v in ipairs(pd.rewardInfo.equips or {}) do
            table.insert(itemDatas, {type=itemType, refId = v.refId, num = v.num,level = pd.passBarriers})
        end
        ShowPanel(UiNames.Prize, {prizes=itemDatas, type=nil, moreInfo=nil})
    end
end

function LxTowerHandler:OnTowerBuySweepCount(pd)

    if pd:HasField("dataObj") then
        local oldCount = ModuleCenter.Tower.remainCount
        if (pd.dataObj.remainCount or 0)> oldCount then ShowSysMsg(I18nText(4215)) end
        ModuleCenter.Tower:SetTowerInfo(pd.dataObj)
        FireEvent(EventNames.TOWER_QUICK_FINISH)
    end
end
function LxTowerHandler:OnReceiveTargetRewardResp(pd)
    for index, value in ipairs(pd.target or {}) do
        ModuleCenter.Tower.receives[value] = value
    end
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.Tower, pd.rewardInfo)
end
--扫荡
function LxTowerHandler:OnTowerQuickReq()
    local proto = LxProtoHelper.CreateProto(LxProtoIds.TowerSweepReq)
    SendMessage(LxProtoIds.TowerSweepReq,proto)
end
--购买扫荡
function LxTowerHandler:OnTowerBuySweepCountReq()
    local proto = LxProtoHelper.CreateProto(LxProtoIds.TowerBuySweepCountReq)
    SendMessage(LxProtoIds.TowerBuySweepCountReq,proto)
end
--免战通关
function LxTowerHandler:OnTowerNoBattlePassReq()
    local proto = LxProtoHelper.CreateProto(LxProtoIds.TowerNoBattlePassReq)
    SendMessage(LxProtoIds.TowerNoBattlePassReq,proto)
end
--关卡录像
function LxTowerHandler:OnTowerBattleVideoReq(level)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.TowerBattleVideoReq)
    proto.barrier = level
    SendMessage(LxProtoIds.TowerBattleVideoReq,proto)
end
function LxTowerHandler:OnReceiveTargetRewardReq(chapter,targets)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.ReceiveTargetRewardReq)
    proto.chapter = chapter
    for _, refId in ipairs(targets) do
        table.insert(proto.target, refId)
    end
    SendMessage(LxProtoIds.ReceiveTargetRewardReq,proto)
end
return LxTowerHandler