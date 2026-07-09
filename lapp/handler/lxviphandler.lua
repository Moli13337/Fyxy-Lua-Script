local LxBaseHandler = require("LApp.handler.LxBaseHandler")
---@class LxVipHandler:LxBaseHandler
local LxVipHandler = classX("LxVipHandler", LxBaseHandler)

function LxVipHandler:Initialize()
    LxBaseHandler.Initialize(self)
end

function LxVipHandler:Dispose()
    LxBaseHandler.Dispose(self)
end

function LxVipHandler:ClearHandler()
    LxBaseHandler.ClearHandler(self)
end

function LxVipHandler:InitOk()
end

-- 完成登录后
function LxVipHandler:LoginOk()
    -- 拉取玩家详细数据
end

function LxVipHandler:InitHandler()
    self:AddMsgHandler(LxProtoIds.VipGiftListResp, self.OnVipGiftListResp, self)--登录推送 礼包列表
    self:AddMsgHandler(LxProtoIds.VipGiftBuyResp, self.OnGiftBuyResp, self)
    self:AddMsgHandler(LxProtoIds.VipLoginRewardResp, self.OnVipLoginRewardResp, self)
end
function LxVipHandler:OnVipLoginRewardResp(pb)
    local loginDay = ModuleCenter.Vip:GetVipLoginDays()
    local temp = loginDay
    if(temp >= 30)then
        temp = 30
    end
    local curConfig = GameTable.VipLoginRewardRef[temp]
    local nextConfig = nil
    if(temp < 30)then
        nextConfig = GameTable.VipLoginRewardRef[temp + 1]
    else
        nextConfig = GameTable.VipLoginRewardRef[temp]
    end
    local curReward = string.split(curConfig.reward,"=")
    local nextReward = string.split(nextConfig.reward,"=")
    ShowAlert({
        refId = 9001,
        args = {
            a1 = curReward[3],
            a2 = loginDay,
            a3 = nextReward[3]
        }
    })
    ModuleCenter.Vip:SetLoginReward(true)
    FireEvent(EventNames.VIP_LOGIN_REWARD)
end
function LxVipHandler:OnVipGiftListResp(pd)
    local oldGifts = ModuleCenter.Vip:GetGiftList()
    local isUpdate = oldGifts and true or false
    local _giftList = {}
    for _, v in ipairs(pd.goodsList) do
        if v.giftRefId then
            _giftList[v.giftRefId] = {
                giftRefId = v.giftRefId,
                buyCount = v.buyCount,
                maxCount = v.maxCount  }
        end
    end
    ModuleCenter.Vip:SetGiftList(_giftList)
    if isUpdate then  FireEvent(EventNames.VIP_GIFT_BUY,nil) end
end

function LxVipHandler:OnGiftBuyResp(pd)
    local rewards = pd.rewardInfo
    local gift = pd.goodsInfo
    if gift then
        ModuleCenter.Vip:GiftListUpdate(gift)
        ShowSysMsg(I18nText(4215))
    end
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.VipGift, rewards)
    FireEvent(EventNames.VIP_GIFT_BUY,{rewards = rewards,refid = gift.giftRefId})
end

function LxVipHandler:OnGiftBuyReq(refId)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.VipGiftBuyReq)
    proto.giftRefId = refId
    SendMessage(LxProtoIds.VipGiftBuyReq,proto)
end
function LxVipHandler:VipLoginRewardReq()
    local proto = LxProtoHelper.CreateProto(LxProtoIds.VipLoginRewardReq)
    SendMessage(LxProtoIds.VipLoginRewardReq,proto)
end
return LxVipHandler