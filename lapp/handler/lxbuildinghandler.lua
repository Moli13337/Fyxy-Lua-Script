local LxBaseHandler = require("LApp.handler.LxBaseHandler")
---@class LxBuildingHandler:LxBaseHandler
local LxBuildingHandler = classX("LxBuildingHandler", LxBaseHandler)

function LxBuildingHandler:Initialize()
    LxBaseHandler.Initialize(self)
end

function LxBuildingHandler:Dispose()
    LxBaseHandler.Dispose(self)
end

function LxBuildingHandler:ClearHandler()
    LxBaseHandler.ClearHandler(self)
end

function LxBuildingHandler:InitOk()
end
-- 完成登录后
function LxBuildingHandler:LoginOk()
end

function LxBuildingHandler:InitHandler()
    self:AddMsgHandler(LxProtoIds.BuildingUpgradeResp, self.OnBuildingUpgradeResp, self)
    self:AddMsgHandler(LxProtoIds.BuildingUpgradeCancelResp, self.OnBuildingUpgradeCancelResp, self)
    self:AddMsgHandler(LxProtoIds.BuildingAccelerateResp, self.OnBuildingAccelerateResp, self)
    self:AddMsgHandler(LxProtoIds.BuildingActiveSeatResp, self.OnBuildingActiveSeatResp, self)
    self:AddMsgHandler(LxProtoIds.BuildingSetWorkerResp, self.OnBuildingSetWorkerResp, self)
    self:AddMsgHandler(LxProtoIds.BuildingResourceOutputResp, self.OnBuildingResourceOutputResp, self)
    self:AddMsgHandler(LxProtoIds.BuildingGetResourceOutputResp, self.OnBuildingGetResourceOutputResp, self)
    self:AddMsgHandler(LxProtoIds.BuildingReceiveBoxResp, self.OnBuildingReceiveBoxResp, self)

    --兵营建筑
    self:AddMsgHandler(LxProtoIds.BuildingProductionStartResp, self.OnBuildingProductionStartResp, self)
    self:AddMsgHandler(LxProtoIds.BuildingProductionCancelResp, self.OnBuildingProductionCancelResp, self)
    self:AddMsgHandler(LxProtoIds.BuildingProductionAccelerateResp, self.OnBuildingProductionAccelerateResp, self)
    self:AddMsgHandler(LxProtoIds.BuildingProductionFinishResp, self.OnBuildingProductionFinishResp, self)
end

--建造、升级建筑
-- @param refId number 建筑总表refId
-- @param psoitionm number 如果升级内建筑,传内建筑位置
-- @param immediately boolean 使用货币道具立刻完成
-- @param seat number建造位表seat
function LxBuildingHandler:BuildingUpgradeReq(refId,position,immediately,seat)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BuildingUpgradeReq)
    proto.refId = refId
    proto.position = position
    proto.immediately = immediately
    proto.seat = seat
    SendMessage(LxProtoIds.BuildingUpgradeReq, proto)
end

--取消建筑升级
-- @param refId number 建筑总表refId
function LxBuildingHandler:BuildingUpgradeCancelReq(refId)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BuildingUpgradeCancelReq)
    proto.refId = refId
    SendMessage(LxProtoIds.BuildingUpgradeCancelReq, proto)
end

--建筑升级加速
-- @param refId number 建筑总表refId
-- @param items IntKeyValue 使用加速道具，格式 <道具refId,数量>
function LxBuildingHandler:BuildingAccelerateReq(refId,itemList)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BuildingAccelerateReq)
    proto.refId = refId
    local items = proto.items
    for i,v in ipairs(itemList) do
        local kv = items:add()
        kv.key = v.key
        kv.value = v.value
    end
    SendMessage(LxProtoIds.BuildingAccelerateReq, proto)
end

--激活第二建造位
-- @param type number 1-免费体验,2-租用
function LxBuildingHandler:BuildingActiveSeatReq(type)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BuildingActiveSeatReq)
    proto.type = type
    SendMessage(LxProtoIds.BuildingActiveSeatReq, proto)
end

--居民工作
-- @param refId number 建筑总表refId
-- @param workerId number 工人refId
-- @param index number 进入第几个工位
-- @param offWork boolean 是否下岗
function LxBuildingHandler:BuildingSetWorkerReq(refId,workerId,index,offWork)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BuildingSetWorkerReq)
    proto.refId = refId
    proto.workerId = workerId
    proto.index = index
    proto.offWork = offWork
    SendMessage(LxProtoIds.BuildingSetWorkerReq, proto)
end

-- 兵营生产
-- @param soldier number 目标士兵refId
-- @param originalSoldier number 原士兵refId,晋升时赋值
-- @param count number 数量
-- @param immediately boolean 使用货币道具立刻完成
function LxBuildingHandler:BuildingProductionStartReq(params, building, taskType, immediately)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BuildingProductionStartReq)
    proto.jParameter = CJSON.encode(params)
    proto.building = building
    proto.taskType = taskType
    proto.immediately = immediately
    self._productionImmediately = immediately
    SendMessage(LxProtoIds.BuildingProductionStartReq, proto)
end

-- 取消兵营生产
-- @param id number 队列id
function LxBuildingHandler:BuildingProductionCancelResp(id)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BuildingProductionCancelReq)
    proto.id = id
    SendMessage(LxProtoIds.BuildingProductionCancelReq, proto)
end

-- 兵营生产加速
-- @param id number 队列id
-- @param items IntKeyValue 使用加速道具，格式 <道具refId,数量>
-- @param immediately boolean 使用货币道具立刻完成
function LxBuildingHandler:BuildingProductionAccelerateReq(id,itemList,immediately)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BuildingProductionAccelerateReq)
    proto.id = id
    local items = proto.items
    for i,v in ipairs(itemList) do
        local kv = items:add()
        kv.key = v.key
        kv.value = v.value
    end
    proto.immediately = immediately
    SendMessage(LxProtoIds.BuildingProductionAccelerateReq, proto)
end

-- 领取兵营生产
-- @param id number 队列id
function LxBuildingHandler:BuildingProductionFinishReq(id, immediately)
    immediately = immediately ~= nil and immediately or false
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BuildingProductionFinishReq)
    proto.id = id
    proto.immediately = immediately
    SendMessage(LxProtoIds.BuildingProductionFinishReq, proto)
end

-- 领取宝箱奖励
function LxBuildingHandler:BuildingReceiveBoxReq(buildId)
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BuildingReceiveBoxReq)
    proto.building = buildId
    SendMessage(LxProtoIds.BuildingReceiveBoxReq, proto)
end

--建筑升级返回数据
function LxBuildingHandler:OnBuildingUpgradeResp(pb)
    local buildId = pb.buildingObj.refId
    local curLvl = ModuleCenter.Building:GetBuildingLvl(buildId)
    ModuleCenter.Building:UpdateBuildDataInfo(pb.buildingObj)
    local newLvl = ModuleCenter.Building:GetBuildingLvl(buildId)
    if buildId == BuildingType.HuoLu then
        CtrlCenter.Story:Build1001SpecialCheck()
        --CtrlCenter.Building:SetStoveUpgradeData({curLvl = curLvl,newLvl = newLvl})
        --ShowPanel(UiNames.BuildStoveUpgradeNew,{curLvl = curLvl,newLvl = newLvl})
        local building100Up = GameTable.BuildingConfigRef.building100Up
        if newLvl > building100Up and newLvl > curLvl then
            CtrlCenter.Building:SetStoveUpgradeData({curLvl = curLvl,newLvl = newLvl})
            CtrlCenter.Building:OnOpenStoveUpgrade()
            self:RealBuildingUpgradeResp(pb,newLvl,curLvl,buildId)
            CtrlCenter.Guild:ReqGuildHelpList()
            return
        end
        ---2025.11.10 黄江让去掉特殊处理
        --if(newLvl == 1 and curLvl == 0)then
        --    CtrlCenter.City:Play1001Born(function()
        --        self:RealBuildingUpgradeResp(pb,newLvl,curLvl,buildId)
        --    end)
        --    return
        --end
        if(newLvl > curLvl)then
            local buildingRef = GameTable.BuildingRef[pb.buildingObj.refId]
            local buildType = buildingRef.type
            local refId = buildType * 1000 + pb.buildingObj.level
            local buildingLvRef = GameTable.BuildingLvRef[refId]
            if(buildingLvRef.upEffect == 1)then
                CtrlCenter.Building:SetStoveUpgradeData({curLvl = curLvl,newLvl = newLvl})
                CtrlCenter.Building:OnOpenStoveUpgradeNew()
            --else
            --    CtrlCenter.Building:SetStoveUpgradeData({curLvl = curLvl,newLvl = newLvl})
            --    CtrlCenter.Building:OnOpenStoveUpgrade()
            end
        end

    end
    self:RealBuildingUpgradeResp(pb,newLvl,curLvl,buildId)
    CtrlCenter.Guild:ReqGuildHelpList()
end
function LxBuildingHandler:RealBuildingUpgradeResp(pb,newLvl,curLvl,buildId)
    if newLvl > curLvl then --建筑升级
        CtrlCenter.Building:UpgradeBuildingClosePanel(buildId,pb.immediately)
        local storyRun = ModuleCenter.Story:IsNewbieRunning()
        local otherOpen = false
        if(storyRun)then
            local ctrl = MgrCenter.PanelMgr:GetPanelCtrl(UiNames.BuildCreate)
            if(ctrl)then
                otherOpen = true
                ClosePanel(UiNames.BuildCreate)
            end
            local ctrl2 = MgrCenter.PanelMgr:GetPanelCtrl(UiNames.BuildCreateTwo)
            if(ctrl2)then
                otherOpen = true
                ClosePanel(UiNames.BuildCreateTwo)
            end
            if(otherOpen)then
                local buildType = CtrlCenter.Building:GetBuildType(buildId)
                if(ResourceBuilding[buildType])then
                    ShowPanel(UiNames.BuildUpGrade,{buildId = buildId,isResetCamera = true})
                end

            end
        end
    end
    FireEvent(EventNames.REFRESH_BUILD_INFO)
    FireEvent(EventNames.REFRESH_UPGRADEBUILD)
    if buildId == BuildingType.BingYingBu or buildId == BuildingType.BingYingQi or buildId == BuildingType.BingYingGong then
        FireEvent(EventNames.REFRESH_BARRACK_TASK)
    end
    CtrlCenter.City:RefreshBuildUpGrade()

    if(checknumber(pb.buildingObj.endTime) > 0)then
        local buildRef = GameTable.BuildingRef[pb.buildingObj.refId]
        local buildType = buildRef.type
        local refId = buildType * 1000 + pb.buildingObj.level

        CtrlCenter.Guide:DoTrigger(9,refId)
    else
        CtrlCenter.Guide:DoTrigger()
    end
    if gLxSdkImpl then gLxSdkImpl:CallMethod(SdkMethod.DoRoleLevelUp) end
    CtrlCenter.Guide:CheckGuideTip()
    MgrCenter.UIEffectMgr:CheckShowOrHideEffect()
end
--取消建筑升级
function LxBuildingHandler:OnBuildingUpgradeCancelResp(pb)
    ModuleCenter.Building:CancelUpdateBuildInfo(pb)
    FireEvent(EventNames.REFRESH_BUILD_INFO)
    FireEvent(EventNames.REFRESH_UPGRADEBUILD)
    if pb.thingsInfo then
        pb.thingsInfo.windowType = 1
        FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.BuildReward, pb.thingsInfo)
    end
    CtrlCenter.City:RefreshBuildUpGrade()
    ShowSysMsg(I18nText(9269))
    if gLxSdkImpl then gLxSdkImpl:CallMethod(SdkMethod.DoRoleLevelUp) end
end

--建筑升级加速
function LxBuildingHandler:OnBuildingAccelerateResp(pb)
    local buildId = pb.buildingObj.refId
    local curLvl = ModuleCenter.Building:GetBuildingLvl(buildId)
    ModuleCenter.Building:UpdateBuildDataInfo(pb.buildingObj)
    local newLvl = ModuleCenter.Building:GetBuildingLvl(buildId)
    if buildId == BuildingType.HuoLu then
        local building100Up = GameTable.BuildingConfigRef.building100Up
        if newLvl > building100Up and newLvl > curLvl then
            CtrlCenter.Building:SetStoveUpgradeData({curLvl = curLvl,newLvl = newLvl})
            CtrlCenter.Building:OnOpenStoveUpgrade()
        end
    end
    if newLvl > curLvl then --建筑升级
        CtrlCenter.Building:UpgradeBuildingClosePanel(buildId,true)
    end
    FireEvent(EventNames.REFRESH_BUILD_INFO)
    FireEvent(EventNames.REFRESH_SPEEDUPLV)
    CtrlCenter.City:RefreshBuildUpGrade()
    CtrlCenter.Guild:ReqGuildHelpList()
    ShowSysMsg(I18nText(9270))
end

--激活第二建造位
function LxBuildingHandler:OnBuildingActiveSeatResp(pb)
    CtrlCenter.Building:OnBuildingActiveSeat(pb)
    FireEvent(EventNames.REFRESH_SEAT_ACTIVE)
end

--居民上工、下工
function LxBuildingHandler:OnBuildingSetWorkerResp(pb)
    ModuleCenter.Building:SetBuildWorkerInfo(pb)
    if pb.offWork then
        ShowSysMsg(I18nText(9284))
    else
        ShowSysMsg(I18nText(9283))
    end
    FireEvent(EventNames.REFRESH_WORKER_INFO, pb.offWork)
    CtrlCenter.City:BuildingRestOrWork()
    CtrlCenter.City:PeopleRefreshState()
end


--离线资源产出
function LxBuildingHandler:OnBuildingResourceOutputResp(pb)
    ModuleCenter.Building:SetOutlineData(pb.time,pb.rewardInfo)
end

--领取离线资源产出
function LxBuildingHandler:BuildingGetResourceOutputReq()
    local proto = LxProtoHelper.CreateProto(LxProtoIds.BuildingGetResourceOutputReq)
    SendMessage(LxProtoIds.BuildingGetResourceOutputReq, proto)
end

--领取离线资源产出返回
function LxBuildingHandler:OnBuildingGetResourceOutputResp(pb)
    CtrlCenter.Building:ReceiveOfflineRevenue(pb)
end

--兵营训练、晋升返回数据
function LxBuildingHandler:OnBuildingProductionStartResp(pb)
    ModuleCenter.Building:SetProductionTask(pb.task)
    if pb.task.taskType == BuildingTaskType.Science then
        ShowSysMsg(I18nText(11228))
        FireEvent(EventNames.REFRESH_SCIENCE_TASK)
    elseif pb.task.taskType == BuildingTaskType.TreatSoldier then
        ShowSysMsg(I18nText(9602))
        FireEvent(EventNames.REFRESH_TREATMENTSOLDIER)
    else
        if self._productionImmediately and CtrlCenter.Building:CheckProductionTaskFinish(pb.task.building) then
            ShowSysMsg(I18nText(9415))
        end
        FireEvent(EventNames.REFRESH_BARRACK_TASK)
    end

    CtrlCenter.City:RefreshBuildProductionTask()
end

--取消兵营训练、晋升返回数据
function LxBuildingHandler:OnBuildingProductionCancelResp(pb)
    local taskType = CtrlCenter.Building:GetProductionTaskTypeById(pb.id)

    if pb.rewardInfo then
        pb.rewardInfo.windowType = 1
        local rewardType
        if taskType == BuildingTaskType.Science then
            rewardType = RewardRecvType.Science
        else
            rewardType = RewardRecvType.BarrackReward
        end
        FireEvent(EventNames.REWARDS_RECEIVED, rewardType, pb.rewardInfo)
    end
    CtrlCenter.Building:ClearProductionTask(pb.id)

    if taskType == BuildingTaskType.Science then
        FireEvent(EventNames.REFRESH_SCIENCE_TASK)
    elseif taskType == BuildingTaskType.TreatSoldier then
        FireEvent(EventNames.REFRESH_TREATMENTSOLDIER)
    else
        FireEvent(EventNames.REFRESH_BARRACK_TASK)
    end
    CtrlCenter.City:RefreshBuildProductionTask()
end

--兵营训练加速返回数据
function LxBuildingHandler:OnBuildingProductionAccelerateResp(pb)
    ModuleCenter.Building:SetProductionTask(pb.task)
    if pb.task.taskType == BuildingTaskType.Science then
        FireEvent(EventNames.REFRESH_SCIENCE_TASK)
    elseif pb.task.taskType == BuildingTaskType.TreatSoldier then
        FireEvent(EventNames.REFRESH_TREATMENTSOLDIER)
    else
        FireEvent(EventNames.REFRESH_BARRACK_TASK)
        if CtrlCenter.Building:CheckProductionTaskFinish(pb.task.building) then
            ShowSysMsg(I18nText(9415))
        end
    end

    CtrlCenter.City:RefreshBuildProductionTask()
end

--兵营领取训练奖励完成数据
function LxBuildingHandler:OnBuildingProductionFinishResp(pb)
    local taskType = CtrlCenter.Building:GetProductionTaskTypeById(pb.id)
    CtrlCenter.Building:ClearProductionTask(pb.id)
    if taskType == BuildingTaskType.Science then
        if pb.immediately then
            ShowSysMsg(I18nText(11228))
        end
        FireEvent(EventNames.REFRESH_SCIENCE_TASK)
    elseif taskType == BuildingTaskType.TreatSoldier then
        FireEvent(EventNames.REFRESH_TREATMENTSOLDIER)
    else
        FireEvent(EventNames.REFRESH_BARRACK_TASK)
        FireEvent(EventNames.REFRESH_BARRACK_REWARD)
    end

    CtrlCenter.City:RefreshBuildProductionTask()
end

--领取宝箱奖励返回
function LxBuildingHandler:OnBuildingReceiveBoxResp(pb)
    if pb.rewardInfo then
        FireEvent(EventNames.REWARDS_RECEIVED, RewardRecvType.BuildBoxReward, pb.rewardInfo)
    end
    ModuleCenter.Building:SetBuildBoxTime(pb.building,pb.boxTime)
    FireEvent(EventNames.REFRESH_BUILDBOXREWARD)
    CtrlCenter.City:RefreshBuildBoxState()
end

return LxBuildingHandler