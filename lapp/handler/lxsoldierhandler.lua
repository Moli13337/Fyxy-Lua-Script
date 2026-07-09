local LxBaseHandler = require("LApp.handler.LxBaseHandler")
---@class LxSoldierHandler:LxBaseHandler
local LxSoldierHandler = classX("LxSoldierHandler", LxBaseHandler)

function LxSoldierHandler:Initialize()
    LxBaseHandler.Initialize(self)
end

function LxSoldierHandler:Dispose()
    LxBaseHandler.Dispose(self)
end

function LxSoldierHandler:ClearHandler()
    LxBaseHandler.ClearHandler(self)
end

function LxSoldierHandler:InitOk()
end
-- 完成登录后
function LxSoldierHandler:LoginOk()
end

function LxSoldierHandler:InitHandler()
    self:AddMsgHandler(LxProtoIds.SoldierChangeResp, self.OnSoldierChangeResp, self)
    self:AddMsgHandler(LxProtoIds.SoldierLockedUpdateResp, self.OnSoldierLockedUpdateResp, self)
    self:AddMsgHandler(LxProtoIds.SoldierReserveResp, self.OnSoldierReserveResp, self)
end

function LxSoldierHandler:OnSoldierChangeResp(pb)
    for _, v in ipairs(pb.addSoldiers) do
        ModuleCenter.Soldier:SetSoldierObj(v, true)
    end
    FireEvent(EventNames.REFRESH_SOLDIER_COUNT)
end

function LxSoldierHandler:OnSoldierLockedUpdateResp(pb)
    ModuleCenter.Soldier:SetSoldierData(pb)
    FireEvent(EventNames.REFRESH_SOLDIER_COUNT)
end

--清空预备役数量
function LxSoldierHandler:OnSoldierReserveResp()
    ModuleCenter.Soldier:ClearReserveSoldiers()
    FireEvent(EventNames.REFRESH_RESERVESOLDIER)
end

--招募预备役士兵
function LxSoldierHandler:SoldierReserveReq()
    local proto = LxProtoHelper.CreateProto(LxProtoIds.SoldierReserveReq)
    SendMessage(LxProtoIds.SoldierReserveReq, proto)
end


return LxSoldierHandler