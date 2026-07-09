local LxBaseHandler = require("LApp.handler.LxBaseHandler")
---@class LxClothesHandler:LxBaseHandler
local LxClothesHandler = classX("LxClothesHandler",LxBaseHandler)

function LxClothesHandler:Initialize()
    LxBaseHandler.Initialize(self)
end

function LxClothesHandler:Dispose()
    LxBaseHandler.Dispose(self)
end

function LxClothesHandler:ClearHandler()
    LxBaseHandler.ClearHandler(self)
end

function LxClothesHandler:InitOk()
end

-- 完成登录后
function LxClothesHandler:LoginOk()
    -- 拉取玩家详细数据
end

function LxClothesHandler:InitHandler()
    --self:AddMsgHandler(LxProtoIds.ClothesLevelUpResp, self.OnClothesLevelUpResp, self)--升级返回
    --self:AddMsgHandler(LxProtoIds.ClothesDressResp, self.OnClothesDressResp, self)--穿戴
    --self:AddMsgHandler(LxProtoIds.ClothesDropResp, self.OnClothesDropResp, self)--卸下
    --self:AddMsgHandler(LxProtoIds.ClothesCollectActiveResp, self.OnClothesCollectActiveResp, self)--收集
    --self:AddMsgHandler(LxProtoIds.ClothesUpdateResp, self.OnClothesUpdateResp, self)--临时激活
    
end

--请求激活升级
function LxClothesHandler:ClothesLevelUpReq(refId)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.ClothesLevelUpReq)
    proto.refId = refId
    SendMessage(LxProtoIds.ClothesLevelUpReq,proto)
end
--穿戴
function LxClothesHandler:ClothesDressReq(refId)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.ClothesDressReq)
    proto.refId = refId
    SendMessage(LxProtoIds.ClothesDressReq,proto)
end
--卸下
function LxClothesHandler:ClothesDropReq(refId)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.ClothesDropReq)
    proto.refId = refId
    SendMessage(LxProtoIds.ClothesDropReq,proto)
end
--收集激活
function LxClothesHandler:ClothesCollectActiveReq()
    local proto = LxProtoHelper.CreateProto(LxProtoIds.ClothesCollectActiveReq)
    SendMessage(LxProtoIds.ClothesCollectActiveReq,proto)
end

---s - c
function LxClothesHandler:OnClothesLevelUpResp(pb)
    if pb:HasField("clothInfo") then 
        local clothes = ModuleCenter.Clothes:GetClothesById(pb.clothInfo.refId)
        local oldAttr = clothes:GetAttribute(clothes:GetLevel()) or {}
        if clothes.levelRefId== 0 and clothes.levelRefId ~= pb.clothInfo.levelRefId then 
            ShowSysMsg(I18nText(5929))
        else
            ShowSysMsg(I18nText(5936))
        end
        ModuleCenter.Clothes:SetClothesInfo(pb.clothInfo)
        FireEvent(EventNames.CLOTHES_UPDATE)

        local newAttr = clothes:GetAttribute() or {}
        ShowPanel(UiNames.FloatAttr, {old = oldAttr, new = newAttr})
    end
end

function LxClothesHandler:OnClothesDressResp(pb)
    if pb:HasField("clothInfo") then 
        local clothes = ModuleCenter.Clothes:GetClothesById(pb.clothInfo.refId)
        local oldState = clothes.isDress
        ModuleCenter.Clothes:SetClothesInfo(pb.clothInfo)
        if oldState ~= pb.clothInfo.isDress then 
            ShowSysMsg(I18nText(6751))
        end
    end
    if pb:HasField("dropClothInfo") then 
        -- local clothes = ModuleCenter.Clothes:GetClothesById(pb.dropClothInfo.refId)
        -- if clothes.isDress ~= pb.dropClothInfo.isDress then 
        --     ShowSysMsg(I18nText(6751))
        -- end
        ModuleCenter.Clothes:SetClothesInfo(pb.dropClothInfo)
    end
    FireEvent(EventNames.CLOTHES_UPDATE)
end
--
function LxClothesHandler:OnClothesDropResp(pb)
    if pb:HasField("clothInfo") then 
        local clothes = ModuleCenter.Clothes:GetClothesById(pb.clothInfo.refId)
        if clothes.isDress ~= pb.clothInfo.isDress then 
            ShowSysMsg(I18nText(6752))
        end
        ModuleCenter.Clothes:SetClothesInfo(pb.clothInfo)
        FireEvent(EventNames.CLOTHES_UPDATE)
    end
end

function LxClothesHandler:OnClothesCollectActiveResp(pd)
    local oldAttrRef = GameTable.ClothesCollectRef[ModuleCenter.Clothes.collectId]
    oldAttrRef = oldAttrRef and LxDataHelper.ParseAttrList(oldAttrRef.attribute) or {}
    local newAttrRef = GameTable.ClothesCollectRef[pd.refId]
    newAttrRef = newAttrRef and LxDataHelper.ParseAttrList(newAttrRef.attribute) or {}

    ModuleCenter.Clothes.collectId = pd.refId
    FireEvent(EventNames.CLOTHES_COLLECT_UPDATE)
    ShowPanel(UiNames.FloatAttr, {old = oldAttrRef, new = newAttrRef})
end

function LxClothesHandler:OnClothesUpdateResp(pb)
    local isTime = false
    local firstAct = false
    for _, newClothe in ipairs(pb.clothes or {}) do
        local oldClothe = ModuleCenter.Clothes:GetClothesById(newClothe.refId)
        local addTime =  newClothe.endTime - (oldClothe.endTime==0 and GetTimestamp() or oldClothe.endTime)
        if addTime>0 then 
            addTime = LxUtil.SecToDHorHMOrMS(addTime)
            local name = oldClothe:GetRef().name
            local isLimit = oldClothe.endTime - GetTimestamp()
            local str = isLimit<=0 and I18nText(7633) or I18nText(7632)
            ShowSysMsg(string.replace(str,I18nText(name),addTime))
            isTime = true
            if not firstAct and isLimit<=0 then firstAct = true end
        end
        ModuleCenter.Clothes:SetClothesInfo(newClothe)
    end
        
    if isTime then 
        FireEvent(EventNames.CLOTHES_LIMIT_TIME_ACT,firstAct)
    else
        FireEvent(EventNames.CLOTHES_UPDATE)
    end
end
return LxClothesHandler