local LxBaseHandler = require("LApp.handler.LxBaseHandler")
---@class LxBadgeGameHandler:LxBaseHandler
local LxBadgeGameHandler = classX("LxBadgeGameHandler",LxBaseHandler)

function LxBadgeGameHandler:Initialize()
    LxBaseHandler.Initialize(self)
end

function LxBadgeGameHandler:Dispose()
    LxBaseHandler.Dispose(self)
end

function LxBadgeGameHandler:ClearHandler()
    LxBaseHandler.ClearHandler(self)
end

function LxBadgeGameHandler:InitOk()
end

-- 完成登录后
function LxBadgeGameHandler:LoginOk()
    -- 拉取玩家详细数据
end

function LxBadgeGameHandler:InitHandler()
    self:AddMsgHandler(LxProtoIds.BadgeGameInfoResp, self.OnBadgeGameInfoResp, self)--徽章数据
    self:AddMsgHandler(LxProtoIds.BadgeGameStarChestResp, self.OnBadgeGameStarChestResp, self)--领取星星奖励
    self:AddMsgHandler(LxProtoIds.BadgeGameDailyRewardResp, self.OnBadgeGameDailyRewardReq, self)--领取每日福利
    self:AddMsgHandler(LxProtoIds.BadgeGameBattleVideoResp, self.OnBadgeGameBattleVideoResp, self)--录像
    self:AddMsgHandler(LxProtoIds.BadgeGameBattleStarInfoResp, self.OnBadgeGameBattleStarInfoResp, self)--当场战斗星数信息
    
end

--请求徽章数据
function LxBadgeGameHandler:BadgeGameInfoReq()
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BadgeGameInfoReq)
    SendMessage(LxProtoIds.BadgeGameInfoReq,proto)
end
--领取星数宝箱
function LxBadgeGameHandler:BadgeGameStarChestReq(chapterId,refId)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BadgeGameStarChestReq)
    proto.chapterId = chapterId
    proto.chestId = refId
    SendMessage(LxProtoIds.BadgeGameStarChestReq,proto)
end
--领取每日福利
function LxBadgeGameHandler:BadgeGameDailyRewardReq()
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BadgeGameDailyRewardReq)
    SendMessage(LxProtoIds.BadgeGameDailyRewardReq,proto)
end
--关卡录像
function LxBadgeGameHandler:BadgeGameBattleVideoReq(barrier)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BadgeGameBattleVideoReq)
    proto.barrier = barrier
    SendMessage(LxProtoIds.BadgeGameBattleVideoReq,proto)
end

---s - c
function LxBadgeGameHandler:OnBadgeGameInfoResp(pb)
    if pb:HasField("obj") then 
        ModuleCenter.BadgeGame:SetBadgeInfo(pb.obj)
        FireEvent(EventNames.BADGE_GAME_UPDATE)
    end
end

function LxBadgeGameHandler:OnBadgeGameStarChestResp(pb)
    if pb.chapterInfo then
        ModuleCenter.BadgeGame:SetChapterInfo(pb.chapterInfo)
        FireEvent(EventNames.BADGE_GAME_UPDATE)
    end
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.BadgeGame, pb.rewardInfo)
end
--领取每日福利
function LxBadgeGameHandler:OnBadgeGameDailyRewardReq(pb)
    ModuleCenter.BadgeGame.dailyRewardState = pb.dailyRewardState
    FireEvent(EventNames.BADGE_GAME_UPDATE)
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.BadgeGame, pb.rewardInfo)
end

function LxBadgeGameHandler:OnBadgeGameBattleVideoResp(pd)
    if pd.videoObj then
        ModuleCenter.BadgeGame:SetVideoInfo(pd.videoObj)
        FireEvent(EventNames.BADGE_VIDEO_UPDATE)
    end
end
function LxBadgeGameHandler:OnBadgeGameBattleStarInfoResp(pd)
    ModuleCenter.BadgeGame:SetBattleStarInfo(pd)
    FireEvent(EventNames.BADGE_GAME_BATTLE_STAR)
end

return LxBadgeGameHandler