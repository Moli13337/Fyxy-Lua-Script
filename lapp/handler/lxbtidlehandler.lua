local LxBaseHandler = require("LApp.handler.LxBaseHandler")
---@class LxFightIdleHandler:LxBaseHandler
local LxFightIdleHandler = classX("LxFightIdleHandler", LxBaseHandler)

function LxFightIdleHandler:Initialize()
    LxBaseHandler.Initialize(self)
end

function LxFightIdleHandler:Dispose()
    LxBaseHandler.Dispose(self)
end

function LxFightIdleHandler:ClearHandler()
    LxBaseHandler.ClearHandler(self)
end

function LxFightIdleHandler:InitOk()
end

-- 完成登录后
function LxFightIdleHandler:LoginOk()
    -- 拉取玩家详细数据
end

function LxFightIdleHandler:InitHandler()
    --- 领取章节奖励下发
    self:AddMsgHandler(LxProtoIds.InstanceChapterRewardResp, self.OnInstanceChapterRewardResp, self)
    --- 更新放置挂机数据
    self:AddMsgHandler(LxProtoIds.InstanceViewPlaceRewardResp, self.OnInstanceViewPlaceRewardResp, self)
    --- 领取放置挂机奖励下发
    self:AddMsgHandler(LxProtoIds.InstanceReceivePlaceRewardResp, self.OnInstanceReceivePlaceRewardResp, self)
    --- 领取快速挂机奖励下发
    self:AddMsgHandler(LxProtoIds.InstanceQuickPlaceRewardResp, self.OnInstanceQuickPlaceRewardResp, self)
end
--- 领取章节奖励
--- @param chapterRefId number 章节refId
--- @param insReward table 关卡奖励表refId
function LxFightIdleHandler:InstanceChapterRewardReq(chapterRefId, insReward)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.InstanceChapterRewardReq)
    proto.chapterRefId = chapterRefId
    for _, v in ipairs(insReward) do
        table.insert(proto.insReward, v)
    end
    SendMessage(LxProtoIds.InstanceChapterRewardReq, proto)
end
--- 查看放置挂机奖励
function LxFightIdleHandler:InstanceViewPlaceRewardReq()
    local proto = LxProtoHelper.CreateProto(LxProtoIds.InstanceViewPlaceRewardReq)
    SendMessage(LxProtoIds.InstanceViewPlaceRewardReq, proto)
end
--- 领取放置挂机奖励
function LxFightIdleHandler:InstanceReceivePlaceRewardReq()
    local proto = LxProtoHelper.CreateProto(LxProtoIds.InstanceReceivePlaceRewardReq)
    SendMessage(LxProtoIds.InstanceReceivePlaceRewardReq, proto)
end
--- 快速挂机
function LxFightIdleHandler:InstanceQuickPlaceRewardReq()
    local proto = LxProtoHelper.CreateProto(LxProtoIds.InstanceQuickPlaceRewardReq)
    SendMessage(LxProtoIds.InstanceQuickPlaceRewardReq, proto)
end
--- 领取章节奖励下发
function LxFightIdleHandler:OnInstanceChapterRewardResp(pb)
    ModuleCenter.FightIdle:SetReceives(pb)
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.Common, pb.rewardInfo)
    FireEvent(EventNames.FightIdle_INFO_CHANGE)
end
--- 更新放置挂机数据
function LxFightIdleHandler:OnInstanceViewPlaceRewardResp(pb)
    ModuleCenter.FightIdle:SetInstanceInfo(pb.placeObj)
    FireEvent(EventNames.FightIdle_INFO_CHANGE)
end
--- 领取放置挂机奖励下发
function LxFightIdleHandler:OnInstanceReceivePlaceRewardResp(pb)
    ModuleCenter.FightIdle:SetInstanceInfo(pb.placeObj)
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.Common, pb.rewardInfo)
    FireEvent(EventNames.FightIdle_INFO_CHANGE)
end
--- 领取快速挂机奖励下发
function LxFightIdleHandler:OnInstanceQuickPlaceRewardResp(pb)
    ModuleCenter.FightIdle:SetInstanceInfo(pb.placeObj)
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.Common, pb.rewardInfo)
    FireEvent(EventNames.FightIdle_INFO_CHANGE)
end
return LxFightIdleHandler