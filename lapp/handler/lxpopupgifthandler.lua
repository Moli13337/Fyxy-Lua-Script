local LxBaseHandler = require("LApp.handler.LxBaseHandler")
---@class LxPopupGiftHandler:LxBaseHandler
local LxPopupGiftHandler = classX("LxPopupGiftHandler", LxBaseHandler)

function LxPopupGiftHandler:Initialize()
    LxBaseHandler.Initialize(self)
end

function LxPopupGiftHandler:Dispose()
    LxBaseHandler.Dispose(self)
end

function LxPopupGiftHandler:ClearHandler()
    LxBaseHandler.ClearHandler(self)
end

function LxPopupGiftHandler:InitOk()

end
-- 完成登录后
function LxPopupGiftHandler:LoginOk()

end

function LxPopupGiftHandler:InitHandler()
    self:AddMsgHandler(LxProtoIds.PopupGiftPanelResp,self.OnPopupGiftPanelResp,self)
    self:AddMsgHandler(LxProtoIds.PopupGiftBuyResp,self.OnPopupGiftBuyResp,self)
    self:AddMsgHandler(LxProtoIds.PopupGiftChoseResp,self.OnPopupGiftChoseResp,self)
    self:AddMsgHandler(LxProtoIds.PopupGiftUpdateResp,self.OnPopupGiftUpdateResp,self)
end

----------------------------------------------
--- c2s

--购买礼包 triggerRefId为礼包组表refId
function LxPopupGiftHandler:PopupGiftBuyReq(groupRefId, giftRefId)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.PopupGiftBuyReq)
    proto.triggerRefId = groupRefId
    proto.giftRefId = giftRefId
    SendMessage(LxProtoIds.PopupGiftBuyReq,proto)
end

--自选奖励选择 triggerRefId为礼包组表refId
function LxPopupGiftHandler:PopupGiftChoseReq(groupRefId, giftRefId, pos, index)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.PopupGiftChoseReq)
    proto.triggerRefId = groupRefId
    proto.giftRefId = giftRefId
    proto.pos = pos
    proto.index = index
    SendMessage(LxProtoIds.PopupGiftChoseReq,proto)
end


----------------------------------------------
--- s2c

-- 礼包面板数据(登录推送)
function LxPopupGiftHandler:OnPopupGiftPanelResp(pb)
    ModuleCenter.PopupGift:SetGiftGroup(pb.groups)
    FireEvent(EventNames.REFRESH_GIFT_GROUP_UPDATE)
end

-- 购买礼包后返回的数据
function LxPopupGiftHandler:OnPopupGiftBuyResp(pb)
    FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.PopupGift, pb.rewardInfo)
    ModuleCenter.PopupGift:UpdateGift(pb.giftObj)
    FireEvent(EventNames.REFRESH_GIFT_GROUP_UPDATE)
end

-- 选完自选奖励后返回的数据
function LxPopupGiftHandler:OnPopupGiftChoseResp(pb)
    ModuleCenter.PopupGift:UpdateGift(pb.giftObj)
    FireEvent(EventNames.REFRESH_SELECT_GIFT_UPDATE)
end

-- 礼包更新推送
function LxPopupGiftHandler:OnPopupGiftUpdateResp(pb)
    -- 新增或更新
    if pb.groups ~= nil then
        ModuleCenter.PopupGift:SetCanPopup(true)
        ModuleCenter.PopupGift:SetGiftGroup(pb.groups, true)
        FireEvent(EventNames.REFRESH_GIFT_GROUP_UPDATE)
    end

    -- 删除
    if pb.removeGroups ~= nil then
        ModuleCenter.PopupGift:DeleteGiftGroup(pb.groups)
        FireEvent(EventNames.REFRESH_GIFT_GROUP_UPDATE)
    end
end

return LxPopupGiftHandler