local LxBaseHandler = require("LApp.handler.LxBaseHandler")
---@class LxDailyMainHandler:LxBaseHandler
local LxDailyMainHandler = classX("LxDailyMainHandler", LxBaseHandler)

function LxDailyMainHandler:Initialize()
    LxBaseHandler.Initialize(self)
end

function LxDailyMainHandler:Dispose()
    LxBaseHandler.Dispose(self)
end

function LxDailyMainHandler:ClearHandler()
    LxBaseHandler.ClearHandler(self)
end

function LxDailyMainHandler:InitOk()
end
-- 完成登录后
function LxDailyMainHandler:LoginOk()
end

function LxDailyMainHandler:InitHandler()
    self:AddMsgHandler(LxProtoIds.DunDailySweepResp, self.OnDunDailySweepResp, self)
    self:AddMsgHandler(LxProtoIds.DunDailyFastSweepResp, self.OnDunDailyFastSweepResp, self)
    self:AddMsgHandler(LxProtoIds.DunDailyTargetRewardResp, self.OnDunDailyTargetRewardResp, self)
end

----------------------------------------------
--- c2s
---
--扫荡
function LxDailyMainHandler:DunDailySweepReq(type,refId)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.DunDailySweepReq)
    proto.type = type
    SendMessage(LxProtoIds.DunDailySweepReq, proto)
end

--一键扫荡 1-免费次数扫荡,2-付费次数扫荡
function LxDailyMainHandler:DunDailyFastSweepReq(sweepType)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.DunDailyFastSweepReq)
    proto.sweepType = sweepType
    SendMessage(LxProtoIds.DunDailyFastSweepReq, proto)
end

--领取目标奖励
function LxDailyMainHandler:DunDailyTargetRewardReqReq(type)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.DunDailyTargetRewardReq)
    proto.type = type
    SendMessage(LxProtoIds.DunDailyTargetRewardReq, proto)
end

----------------------------------------------
--- s2c
---
--扫荡数据变化
function LxDailyMainHandler:OnDunDailySweepResp(pb)
    local data = ModuleCenter.DailyMain:GetDailyDunData(pb.type)
    if data ~= nil then
        data:SetSweepCount(pb.sweepCount)
        data:SetFreeSweepCount(pb.freeSweepCount)
    end
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.DailyMain, pb.rewards)
    FireEvent(EventNames.REFRESH_DAILY_MAIN_CENTER)
end

--一键扫荡数据变化
function LxDailyMainHandler:OnDunDailyFastSweepResp(pb)
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.DailyMain, pb.rewards)
end

--目标奖励最新数据
function LxDailyMainHandler:OnDunDailyTargetRewardResp(pb)
    local data = ModuleCenter.DailyMain:GetDailyDunData(pb.type)
    if data ~= nil then
        data:SetTargetRewards(pb.targetRewards)
    end
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.DailyMain, pb.rewards)
    FireEvent(EventNames.REFRESH_DAILY_MAIN_TOP)
end

return LxDailyMainHandler