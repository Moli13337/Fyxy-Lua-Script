
-------------------------------------------------------------------------

local LModel = LModel
---@class ModelHolyLand:LModel
local ModelHolyLand = LxClass("ModelHolyLand", LModel)

--------------------------------------------------------------------------
function ModelHolyLand:ModelHolyLand()
    ---@type table<level,rank,flowerUseCnt> 
    self.holyLandInfo = {rank = 0,level = 0,flowerUseCnt = 0} --level 是refId 
end

--模块初始化入口
--注册事件监听
--注册协议监听
--预处理数据
function ModelHolyLand:OnModelInit()
    self:ModelNetMsgRecv(LProtoIds.HolyLandLevelUpResp,function(...)
        self:OnHolyLandLevelUpResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.HolyLandInfoResp,function(...)
        self:OnHolyLandInfoResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.HolyLandRewardResp,function(...)
        self:OnHolyLandRewardResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.HolyLandUpdateInfoResp,function(...)
        self:OnHolyLandUpdateInfoResp(...)
    end)
end

--在协议数据处理完之后需要调用finish
function ModelHolyLand:OnModelRequest()
    -- local isOpen = gModelFunctionOpen:CheckIsOpened(10308000, false)
    -- if isOpen then
    --     self:HolyLandInfoReq()
    -- end
    self:ModelFinish()
end
--------------------------请求协议------------------------------

--请求圣域信息
function ModelHolyLand:HolyLandInfoReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.HolyLandInfoReq)
    SendMessage(pb,LProtoIds.HolyLandInfoReq)
end
---圣域升级
function ModelHolyLand:HolyLandLevelUpReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.HolyLandLevelUpReq)
    SendMessage(pb,LProtoIds.HolyLandLevelUpReq)
end
--领取圣域积分
function ModelHolyLand:HolyLandRewardReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.HolyLandRewardReq)
    SendMessage(pb,LProtoIds.HolyLandRewardReq)
end
----------------------------监听协议--------------------------------------
function ModelHolyLand:OnHolyLandInfoResp(pb)--圣域信息返回
    self:UpdateInfo(pb.info)
    local rewards = {}
    local total = 0
    for _, rwd in ipairs(pb.rewardInfos or {}) do
        local score = 0
        for _, value in ipairs(rwd.rewardInfo) do
            score = score + tonumber(value.count)
        end
        total = total + score
        local value = rwd.rewardInfo[1]
        if value then
            local data = {itemId = value.itemId,type = value.type,count = score,heroRefId = rwd.refId,star = rwd.star}
            table.insert(rewards,data)
        end
    end 
    if #rewards >0 then  GF.OpenWnd("UIHoLandScoreRwd",{rwd = rewards,totalItem = {itemId = rewards[1].itemId,count = total}}) end
    FireEvent(EventNames.HOLYLAND_UPDATE)
end

function ModelHolyLand:OnHolyLandLevelUpResp(pb)--升级返回
    local oldRank = self.holyLandInfo.rank

    local ref = GameTable.HolyLandLvRef[self.holyLandInfo.level]
	local list = LxDataHelper.ParseAttrList(ref.attrChange)
    local attrs = {}
    for index, value in ipairs(list) do
        if value.value >0 then table.insert(attrs,{refId = value.refId,addNum = value.value,type = value.type}) end
    end
    self:UpdateInfo(pb.info)
    GF.CloseWndByName("UISagaPowerTips")
	GF.OpenWndDebug("UISagaPowerTips", { dataList = attrs})--powerPre = gModelPlayer:GetPlayerFightPower()
    FireEvent(EventNames.HOLYLAND_UPDATE)

    local newRank = self.holyLandInfo.rank
    if oldRank ~= newRank then
        FireEvent(EventNames.HOLYLAND_RANK_CHANGE, oldRank, newRank)
    end

    LxUiHelper.PlayAudioSoundName(14)
end

function ModelHolyLand:OnHolyLandRewardResp(pb)--积分领取返回
    local reward = pb.rewardInfos
    
end

function ModelHolyLand:OnHolyLandUpdateInfoResp(pb)-- 更新圣域信息
    local oldCount = self.holyLandInfo.flowerUseCnt
    self:UpdateInfo(pb.info)
    local useCount = oldCount - self.holyLandInfo.flowerUseCnt
    if useCount> 0 then
        local itemRef = GameTable.PlayerItemRef[tonumber(GameTable.HolyLandConfigRef.useItem)]
        local list = LxDataHelper.ParseAttrList(itemRef.typeDate)
        local attrList = {}
        for _, value in ipairs(list) do
            if value.value >0 then table.insert(attrList,{refId = value.refId,addNum = value.value*useCount}) end
        end
        GF.CloseWndByName("UISagaPowerTips")
		GF.OpenWndDebug("UISagaPowerTips", { dataList = attrList})
    end
    FireEvent(EventNames.HOLYLAND_UPDATE)
end
function ModelHolyLand:UpdateInfo(value)
    local info = self.holyLandInfo 
    info.rank = value.rank
    info.level = value.level
    info.flowerUseCnt = value.flowerUseCnt
end
--------------------------------------------------------------------------

function ModelHolyLand:GetHolyLandAttrByLv(lv)
    local ref = GameTable.HolyLandLvRef[lv]
    if ref and ref.attr then
        local curAttrMap = {}
        local nextAttrMap = {}
        local curAttrList = LxDataHelper.ParseAttrList(ref.attr)--当前等级属性
        local attrChange = string.isempty(ref.attrChange) and GameTable.HolyLandLvRef[1].attrChange or ref.attrChange
        local nexChange = LxDataHelper.ParseAttrList(attrChange)--下级属性预览
        for _, attr in ipairs(curAttrList) do
            curAttrMap[attr.refId..attr.type] = attr
        end
        local gradeAttrMap = self:GetHolyLandGradeAttrs()--当前阶级属性
        for _, value in ipairs(nexChange) do
            if value.value>0 and ref.lvNext>0 then 
                nextAttrMap[value.refId..value.type] = {type = value.type,value=value.value }
            end
            value.value = 0
            if curAttrMap[value.refId..value.type] then 
                value.value = curAttrMap[value.refId..value.type].value+value.value
                curAttrMap[value.refId..value.type] = nil
            end
            if gradeAttrMap[value.refId..value.type] then 
                value.value = gradeAttrMap[value.refId..value.type].value+value.value
                gradeAttrMap[value.refId..value.type] = nil
            end
        end
        curAttrList = nexChange
        return curAttrList,nextAttrMap
    end
end

function ModelHolyLand:GetHolyLandGradeAttrs()
    local ref = GameTable.HolyLandRankRef
    local attrMap = {}
    for _, cfg in ipairs(ref) do
        if self.holyLandInfo.rank>= cfg.rankNow then 
            local attrs = LxDataHelper.ParseAttrList(cfg.attr)
            for _, attr in ipairs(attrs or {}) do
                if attrMap[attr.refId..attr.type] then
                    attrMap[attr.refId..attr.type].value = attr.value+attrMap[attr.refId..attr.type].value
                else
                    attrMap[attr.refId..attr.type] = attr
                end
            end
        end
    end
    return attrMap
end

---
--清理工作
--停止计时器之类的
function ModelHolyLand:OnModelClear()

end
return ModelHolyLand