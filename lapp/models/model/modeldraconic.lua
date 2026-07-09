---@class ModelDraconic:LModel
local ModelDraconic = LxClass("ModelDraconic", LModel)

local LayoutRebuilder = UnityEngine.UI.LayoutRebuilder

local FuncIdEnum = {
    Main = 17400000,        -- 龙魂
    Summon = 17400001,      -- 召唤
    Speech = 17400002,      -- 龙语
    Illustrated = 17400004, -- 图鉴
    Resolve = 17400003,     -- 分解
    Privilege = 10401162,   -- 龙纹特权
}
ModelDraconic.FuncIdEnum = FuncIdEnum

-- 属性排序
function ModelDraconic.SortAttr(a, b)
    return a.refId + a.type * 100000 < b.refId + b.type * 100000
end

-- 属性值校正
function ModelDraconic.CheckAttrValue(attrList)
    for k, v in ipairs(attrList) do
        v.value = math.floor(v.value * 10000 + 0.5) / 10000
    end
end

-- 龙语排序
function ModelDraconic.SortDraconicList(a, b)
    if a.ref.effetcType ~= b.ref.effetcType then
        return a.ref.effetcType < b.ref.effetcType
    end

    if a.ref.sort ~= b.ref.sort then
        return a.ref.sort > b.ref.sort
    end
    return a.ref.refId > b.ref.refId
end

function ModelDraconic:ModelDraconic()
    self._draconicInfo = {}
    self._attrs = {}
    self._draconicsAttr = {}
    self._relationAttr = {}
    self._dressInfos = {}
    self._objs = {}

    self._isEnus = gLGameLanguage:IsForeignVersion()
    self._isVie = gLGameLanguage:IsVieVersion()
    -- 预初始化
    self:GetUpStarRef()
    self:GetUpStarCostRef()
    self:GetDraconicResolveItemList({})
end

function ModelDraconic:OnModelInit()
    self:ModelNetMsgRecv(LProtoIds.DraconicInfoResp, function(...)
        self:OnDraconicInfoResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.DraconicSoulLevelUpResp, function(...)
        self:OnDraconicSoulLevelUpResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.DraconicAttrUpdateResp, function(...)
        self:OnDraconicAttrUpdateResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.DraconicDropResp, function(...)
        self:OnDraconicDropResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.DraconicGetProgressRewardResp, function(...)
        self:OnDraconicGetProgressRewardResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.DraconicDropWishResp, function(...)
        self:OnDraconicDropWishResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.DraconicRankUpResp, function(...)
        self:OnDraconicRankUpResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.DraconicRelationLevelUpResp, function(...)
        self:OnDraconicRelationLevelUpResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.DraconicDecomposeResp, function(...)
        self:OnDraconicDecomposeResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.DraconicOperateResp, function(...)
        self:OnDraconicOperateResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.DraconicDailyUpdateResp, function(...)
        self:OnDraconicDailyUpdateResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.DraconicObjsUpdateResp, function(...)
        self:OnDraconicObjsUpdateResp(...)
    end)
    self:ModelNetMsgRecv(LProtoIds.DraconicLinkResp, function(...)
        self:OnDraconicLinkResp(...)
    end)
end

--在协议数据处理完之后需要调用finish
function ModelDraconic:OnModelRequest()
    self:DraconicInfoReq()

    self:ModelFinish()
end

-- region 协议 ----------------------------------------------------

-- 获取龙语信息 请求
function ModelDraconic:DraconicInfoReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.DraconicInfoReq)
    SendMessage(pb, LProtoIds.DraconicInfoReq)
end

-- 获取龙语信息 返回
function ModelDraconic:OnDraconicInfoResp(pb)
    self._initInfo = true
    self._draconicInfo = pb
    self._attrs = pb.attrs
    self._draconicsAttr = pb.draconicsAttr
    self._relationAttr = pb.relationAttr
    self._dressInfos = pb.dressInfos
    self._objs = pb.objs

    table.sort(self._attrs, ModelDraconic.SortAttr)
    table.sort(self._draconicsAttr, ModelDraconic.SortAttr)
    table.sort(self._relationAttr, ModelDraconic.SortAttr)
    ModelDraconic.CheckAttrValue(self._attrs)
    ModelDraconic.CheckAttrValue(self._draconicsAttr)
    ModelDraconic.CheckAttrValue(self._relationAttr)

    FireEvent(EventNames.DRACONIC_INFO_RETURN)
end

-- 龙魂升级 请求
function ModelDraconic:DraconicSoulLevelUpReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.DraconicSoulLevelUpReq)
    SendMessage(pb, LProtoIds.DraconicSoulLevelUpReq)
end

-- 龙魂升级 返回
function ModelDraconic:OnDraconicSoulLevelUpResp(pb)
    self._draconicInfo.soulLevel = pb.soulLevel
    FireEvent(EventNames.DRACONIC_INFO_RETURN)

    GF.ShowMessage(ccClientText(41057))
    LxUiHelper.PlayAudioSoundName(14)
end

-- 更新属性
function ModelDraconic:OnDraconicAttrUpdateResp(pb)
    self._attrs = pb.attrs
    self._draconicsAttr = pb.draconicsAttr
    self._relationAttr = pb.relationAttr

    table.sort(self._attrs, ModelDraconic.SortAttr)
    table.sort(self._draconicsAttr, ModelDraconic.SortAttr)
    table.sort(self._relationAttr, ModelDraconic.SortAttr)
    ModelDraconic.CheckAttrValue(self._attrs)
    ModelDraconic.CheckAttrValue(self._draconicsAttr)
    ModelDraconic.CheckAttrValue(self._relationAttr)

    FireEvent(EventNames.DRACONIC_ATTRS_RETURN)
end

-- 抽奖 请求
function ModelDraconic:DraconicDropReq(type)
    local pb = LProtoHelper.CreateProto(LProtoIds.DraconicDropReq)
    pb.type = type
    SendMessage(pb, LProtoIds.DraconicDropReq)
end

-- 抽奖 返回
function ModelDraconic:OnDraconicDropResp(pb)
    self._draconicInfo.freeDropNum = pb.freeDropNum
    self._draconicInfo.diamondDropNum = pb.diamondDropNum
    self._draconicInfo.dropProgress = pb.dropProgress

    local items = {}
    local DraconicDropRef = GameTable.DraconicDropRef
    local DraconicRef = GameTable.DraconicRef
    local ItemRef = GameTable.PlayerItemRef
    local draconicRefIdList = {}
    for k, v in ipairs(pb.rewardIds) do
        local ref = DraconicDropRef[v]
        local data = string.split(ref.reward, "=")
        local refId = tonumber(data[2])
        local num = tonumber(data[3])

        if ref.whole == 1 then
            local star, draconicRefId = self:GetSpeechStarByItemId(refId)
            if star and DraconicRef[draconicRefId] then
                table.insert(draconicRefIdList, draconicRefId)
                -- if star > -1 then
                --     -- 已激活
                -- else
                --     refId = draconicRefId
                --     num = 1
                -- end
            end
        end
        items[k] = { refId = refId, num = num }
    end
    local thingsDetail = { items = items }

    local num = 1
    if #pb.rewardIds > 3 then
        num = 10 -- 大于3为10连抽
    end

    local function showItem()
        local item = LUtil.GetRefItemData(GameTable.DraconicConfigRef.rewardFix)
        local param = {
            fixedReward = { refId = item.refId, type = item.type, itemNum = num }
        }

        self:ShowComReward(thingsDetail, param)
    end

    local function showReward()
        if #draconicRefIdList > 0 then
            GF.OpenWnd("UIDraconicGet", { refIdList = draconicRefIdList, callback = showItem })
        else
            showItem()
        end
    end

    FireEvent(EventNames.DRACONIC_INFO_RETURN)
    FireEvent(EventNames.DRACONIC_DROP_RETURN, showReward)
end

-- 领取档位奖励 请求
function ModelDraconic:DraconicGetProgressRewardReq(rewardIdx)
    local pb = LProtoHelper.CreateProto(LProtoIds.DraconicGetProgressRewardReq)
    pb.rewardIdx = rewardIdx - 1
    SendMessage(pb, LProtoIds.DraconicGetProgressRewardReq)
end

-- 领取档位奖励 返回
function ModelDraconic:OnDraconicGetProgressRewardResp(pb)
    self._draconicInfo.dropProgress = pb.dropProgress

    for i = #self._draconicInfo.progressRewardIdxs, 1, -1 do
        self._draconicInfo.progressRewardIdxs:remove(i)
    end
    for k, v in ipairs(pb.progressRewardIdxs) do
        table.insert(self._draconicInfo.progressRewardIdxs, v)
    end

    self:ShowComReward(pb.thingsDetail)

    FireEvent(EventNames.DRACONIC_INFO_RETURN)
end

-- 寻宝许愿 请求
function ModelDraconic:DraconicDropWishReq(wishDraconicId)
    local pb = LProtoHelper.CreateProto(LProtoIds.DraconicDropWishReq)
    pb.wishDraconicId = wishDraconicId
    SendMessage(pb, LProtoIds.DraconicDropWishReq)
end

-- 寻宝许愿 返回
function ModelDraconic:OnDraconicDropWishResp(pb)
    self._draconicInfo.wishDraconicId = pb.wishDraconicId

    FireEvent(EventNames.DRACONIC_INFO_RETURN)
end

-- 激活/升级龙语 请求
function ModelDraconic:DraconicRankUpReq(refId)
    local pb = LProtoHelper.CreateProto(LProtoIds.DraconicRankUpReq)
    pb.refId = refId
    SendMessage(pb, LProtoIds.DraconicRankUpReq)
end

-- 激活/升级龙语 返回
function ModelDraconic:OnDraconicRankUpResp(pb)
    local had = false
    for k, v in ipairs(self._objs) do
        if v.refId == pb.obj.refId then
            v.starRefId = pb.obj.starRefId
            had = true
            break
        end
    end

    if not had then
        self._objs:add()
        local obj = self._objs[#self._objs]
        obj.starRefId = pb.obj.starRefId
        obj.refId = pb.obj.refId

        local ref = GameTable.DraconicSuitRankRef[pb.obj.starRefId]
        GF.OpenWnd("UIDraconicUpStarActive", { refId = pb.obj.refId, starNum = ref.rankNow })
    else
        local ref = GameTable.DraconicSuitRankRef[pb.obj.starRefId]
        GF.OpenWnd("UIDraconicUpStarResult", { refId = pb.obj.refId, starNum = ref.rankNow })
    end

    FireEvent(EventNames.DRACONIC_INFO_RETURN)
end

-- 激活/升级龙语组合 请求
function ModelDraconic:DraconicRelationLevelUpReq(refId)
    local pb = LProtoHelper.CreateProto(LProtoIds.DraconicRelationLevelUpReq)
    pb.refId = refId
    SendMessage(pb, LProtoIds.DraconicRelationLevelUpReq)
end

-- 激活/升级龙语组合 返回
function ModelDraconic:OnDraconicRelationLevelUpResp(pb)
    local had = false
    for k, v in ipairs(self._draconicInfo.relationObjs) do
        if v.refId == pb.obj.refId then
            v.lvRefId = pb.obj.lvRefId
            had = true
            break
        end
    end

    if not had then
        self._draconicInfo.relationObjs:add()
        local obj = self._draconicInfo.relationObjs[#self._draconicInfo.relationObjs]
        obj.lvRefId = pb.obj.lvRefId
        obj.refId = pb.obj.refId

        local ref = GameTable.DraconicRelationLvRef[pb.obj.lvRefId]
        GF.OpenWnd("UIDraconicUpLevActive", { refId = pb.obj.refId, lev = ref.rankNow })
    else
        local ref = GameTable.DraconicRelationLvRef[pb.obj.lvRefId]
        GF.OpenWnd("UIDraconicUpLevResult", { refId = pb.obj.refId, lev = ref.rankNow })
    end

    FireEvent(EventNames.DRACONIC_INFO_RETURN)
end

-- 碎片分解 请求
function ModelDraconic:DraconicDecomposeReq(itemList)
    local pb = LProtoHelper.CreateProto(LProtoIds.DraconicDecomposeReq)
    for k, v in ipairs(itemList) do
        pb.items:add()
        pb.items[k].refId = v.refId
        pb.items[k].num = v.count

        local ref = gModelItem:GetRefByRefId(v.refId)
        pb.items[k].type = ref and ref.type or 0
    end

    SendMessage(pb, LProtoIds.DraconicDecomposeReq)
end

-- 碎片分解 返回
function ModelDraconic:OnDraconicDecomposeResp(pb)
    self:ShowComReward(pb.thingsDetail)
end

-- 龙语操作 请求
function ModelDraconic:DraconicOperateReq(type, refId, formPos, toPos)
    local pb = LProtoHelper.CreateProto(LProtoIds.DraconicOperateReq)
    pb.type = type -- 1上阵 2下阵 3交换
    pb.refId = refId
    pb.slotId = formPos
    pb.exchangeSlotId = toPos or 0
    SendMessage(pb, LProtoIds.DraconicOperateReq)
end

-- 龙语操作 返回
function ModelDraconic:OnDraconicOperateResp(pb)
    self._dressInfos = pb.dressInfos

    if pb.type == 1 then
        GF.ShowMessage(ccClientText(41053))
    elseif pb.type == 2 then
        GF.ShowMessage(ccClientText(41054))
    end

    if pb.type ~= 3 then
        FireEvent(EventNames.DRACONIC_INFO_RETURN)
    end
end

-- 更新每日抽奖次数 返回
function ModelDraconic:OnDraconicDailyUpdateResp(pb)
    self._draconicInfo.freeDropNum = pb.freeDropNum
    self._draconicInfo.diamondDropNum = pb.diamondDropNum

    FireEvent(EventNames.DRACONIC_INFO_RETURN)
end

-- 更新龙语信息
function ModelDraconic:OnDraconicObjsUpdateResp(pb)
    local map = {}
    for k, v in ipairs(self._objs) do
        map[v.refId] = v
    end

    for k, v in ipairs(self._objs) do
        if map[v.refId] then
            self._objs[k] = v
        end
    end

    FireEvent(EventNames.DRACONIC_INFO_RETURN)
end

-- 龙纹附魂 请求
function ModelDraconic:DraconicLinkReq(refId, linkRefId)
    local pb = LProtoHelper.CreateProto(LProtoIds.DraconicLinkReq)
    pb.refId = refId
    pb.linkRefId = linkRefId
    SendMessage(pb, LProtoIds.DraconicLinkReq)
end

-- 龙纹附魂 返回
function ModelDraconic:OnDraconicLinkResp(pb)
    local refId = pb.refId
    for k, v in ipairs(self._objs) do
        if v.refId == refId then
            v.linkRefId = pb.linkRefId
            break
        end
    end
    if pb.linkRefId == 0 then
        GF.ShowMessage(ccClientText(40907))
    else
        GF.ShowMessage(ccClientText(40906))

        for k, v in ipairs(self._dressInfos) do
            if v.refId == pb.linkRefId then
                v.refId = 0
            end
        end
    end

    FireEvent(EventNames.DRACONIC_INFO_RETURN)
end

-- 协议返回的通用奖励
function ModelDraconic:ShowComReward(thingsDetail, param)
    param = param or {}
    local itemList = {}
    for k, v in ipairs(thingsDetail.items) do
        local tab = {
            itype = 1,
            itemId = tonumber(v.refId),
            count = tonumber(v.num),
        }
        table.insert(itemList, tab)
    end
    param.itemList = itemList

    gModelWndPop:TryOpenPopWnd("UIAward", param)
end

-- endregion ----------------------------------------------------


-- region 数据 ----------------------------------------------------

-- 获取龙魂信息
function ModelDraconic:GetInfo()
    return self._draconicInfo
end

-- ture: 表示可以许愿
function ModelDraconic:IsCanWish()
    return not not self._draconicInfo.isCanWish
end

-- 获取龙魂等级
function ModelDraconic:GetLev()
    return self._draconicInfo.soulLevel
end

-- 获取龙魂属性
function ModelDraconic:GetTotalAttrList()
    if #self._attrs == 0 then
        local ref = GameTable.DraconicBuildingLvRef[2] -- 空属性，随便取一个作显示
        local list = string.split(ref.attr, ",")
        for k, v in ipairs(list) do
            local data = string.split(v, "=")
            table.insert(self._attrs, { refId = tonumber(data[1]), value = 0 })
        end
    end

    return self._attrs
end

-- 获取龙语属性
function ModelDraconic:GetSpeechAttrList()
    return self._draconicsAttr
end

-- 获取图鉴属性
function ModelDraconic:GetIllustratedAttrList()
    return self._relationAttr
end

-- 获取龙魂上阵refId, nil表示未上阵
function ModelDraconic:GetUseRefId(pos)
    for _, v in ipairs(self._dressInfos) do
        if v.slot == pos and v.refId ~= 0 then
            return v.refId
        end
    end
    return nil
end

-- 返回true,表示龙魂已上阵
function ModelDraconic:HadUsed(refId)
    for _, v in ipairs(self._dressInfos) do
        if v.refId == refId then
            return true
        end
    end
    return false
end

-- 返回true, 表示龙魂已上阵 (检查所有阵型）
function ModelDraconic:HadUsedCheckAllFormations(refId)
    for _, v in ipairs(self._dressInfos) do
        if v.refId == refId then
            return true
        end
    end

    for k, v in ipairs(self._objs) do
        if v.refId == refId then
            return v.isDeploy == 1
        end
    end

    return false
end

-- 上阵龙语，更换位置
function ModelDraconic:ChangePos(formPos, toPos)
    local formData, toData
    for _, v in ipairs(self._dressInfos) do
        if v.slot == formPos then
            formData = v
        elseif v.slot == toPos then
            toData = v
        end
    end

    for _, v in ipairs(self._dressInfos) do
        if v.slot == formPos then
            if not toData then
                v.slot = toPos
                break
            else
                v.slot = toPos
                toData.slot = formPos
            end
        end
    end
end

-- 获取召唤剩余免费次数
function ModelDraconic:GetLeftFreeSummonTimes()
    return self._draconicInfo.freeDropNum
end

-- 获取召唤剩余钻石次数
function ModelDraconic:GetLeftDiamondSummonTimes()
    return self._draconicInfo.diamondDropNum
end

-- 获取召唤进度（积分）
function ModelDraconic:GetSummonProgress()
    return self._draconicInfo.dropProgress
end

-- 获取召唤宝箱已领取的位置 Map
function ModelDraconic:GetSummonBoxReceivedPosMap()
    local map = {}
    for k, v in ipairs(self._draconicInfo.progressRewardIdxs) do
        map[v + 1] = true
    end
    return map
end

-- 获取当前许愿的refId
function ModelDraconic:GetWishDraconicRefId()
    return self._draconicInfo.wishDraconicId or 0
end

-- 获取龙语星级, -1 表示未激活
function ModelDraconic:GetSpeechStar(refId)
    for k, v in ipairs(self._objs) do
        if v.refId == refId then
            local ref = GameTable.DraconicSuitRankRef[v.starRefId]
            return ref.rankNow
        end
    end
    return -1
end

-- 获取已激活的龙语升星id列表
function ModelDraconic:GetActiveStarRefIdList()
    local list = {}
    for k, v in ipairs(self._objs) do
        list[k] = v.starRefId
    end
    return list
end

-- 获取龙语主动技能列表
function ModelDraconic:GetActiveUpRefList()
    local list = {}
    for k, v in ipairs(self._objs) do
        local upRef = GameTable.DraconicSuitRankRef[v.starRefId]
        local ref = GameTable.DraconicRef[upRef.type]
        if ref.effetcType == 1 then
            table.insert(list, { ref = ref, upRef = upRef })
        end
    end
    table.sort(list, function(a, b)
        return a.ref.sort > b.ref.sort
    end)

    local newList = {}
    for k, v in ipairs(list) do
        table.insert(newList, v.upRef.refId)
    end
    return newList
end

-- 获取龙魂键上阵
function ModelDraconic:GetOneKeyFormationRefIdList(excludeMap)
    local list = {}
    for k, v in ipairs(self._objs) do
        local upRef = GameTable.DraconicSuitRankRef[v.starRefId]
        local ref = GameTable.DraconicRef[upRef.type]
        if ref.effetcType == 1 and not excludeMap[upRef.refId] and self:GetMainAttachRefId(ref.refId) == 0 then
            table.insert(list, { ref = ref, upRef = upRef })
        end
    end

    table.sort(list, function(a, b)
        if a.ref.quality ~= b.ref.quality then
            return a.ref.quality > b.ref.quality
        end
        if a.upRef.rankNow ~= b.upRef.rankNow then
            return a.upRef.rankNow > b.upRef.rankNow
        end
        return a.ref.sort > b.ref.sort
    end)

    local newList = {}
    for i = 1, 4 do
        if list[#list - i + 1] and self:IsSkillOpenByPos(i) then
            newList[i] = list[i].upRef.refId
        end
    end
    return newList
end

-- 获取龙语星级, -1 表示未激活, nil表示没有对应的龙语
function ModelDraconic:GetSpeechStarByItemId(itemRefId)
    if not self._itemResolveRef then
        local map = {}
        for k, v in pairs(GameTable.DraconicRef) do
            map[v.item].ref = v
            map[v.item].itemSell = LUtil.GetRefItemData(v.itemSell)
        end
        self._itemResolveRef = map
    end

    if not self._itemResolveRef[itemRefId] then
        return nil
    end

    local refId = self._itemResolveRef[itemRefId].ref.refId
    local star = self:GetSpeechStar(refId)
    return star, refId
end

-- 获取图鉴级, 0 表示未激活
function ModelDraconic:GetIllustratedLev(refId)
    for k, v in ipairs(self._draconicInfo.relationObjs) do
        if v.refId == refId then
            local ref = GameTable.DraconicRelationLvRef[v.lvRefId]
            return ref.rankNow
        end
    end
    return 0
end

-- 通过物品id判断相应的龙语是否已满星
function ModelDraconic:IsStarMaxByItemRefId(itemRefId)
    local star, refId = self:GetSpeechStarByItemId(itemRefId)
    if not star then
        return true
    end
    if star == -1 then
        return false
    end
    local cost = self:GetUpStarCostRef(refId, star)
    return cost == nil
end

-- true:龙魂可升级
function ModelDraconic:CanUp(showTips)
    local costItemList = self:GetLevCost()
    if not costItemList then
        if showTips then
            GF.ShowMessage(ccClientText(41013))
        end
        return false
    end

    for i, v in ipairs(costItemList) do
        local haveNum = gModelItem:GetNumByRefId(v.refId)
        if haveNum < v.count then
            if showTips then
                gModelGeneral:OpenGetWayWnd({ itemId = v.refId })
            end
            return false
        end
    end
    return true
end

-- true：龙魂有空闲位并且有可上阵的
function ModelDraconic:HadCanUse()
    local lev = self:GetLev()
    local list = {}
    for i = 1, 4 do
        -- 固定4个
        if not self:GetUseRefId(i) then
            local needLev = self:GetSkillOpenLev(i)
            if needLev <= lev then
                table.insert(list, i)
            end
        end
    end

    if #list == 0 then
        return false
    end

    for k, v in ipairs(self:GetAllSpeechRefList2()) do
        if v.effetcType == 1 and not self:HadUsed(v.refId) then
            local starNum = self:GetSpeechStar(v.refId)
            if starNum ~= -1 and self:GetMainAttachRefId(v.refId) == 0 then
                return true
            end
        end
    end
    return false
end

-- true: 有可领取的召唤进度的宝箱
function ModelDraconic:HadReceiveSummonBox()
    local progress = self:GetSummonProgress()
    local refList = self:GetSummonProgressRef()
    local map = self:GetSummonBoxReceivedPosMap()
    for k, v in ipairs(refList) do
        if progress >= v.progress and not map[k] then
            return true
        end
    end
    return false
end

-- true: 满足召唤10次
function ModelDraconic:EnoughSummonTen(showTips)
    local leftDiamond = self:GetLeftDiamondSummonTimes()
    local constList = self:GetSummonCost()
    local refId = constList[1].ten.refId
    local haveNum = gModelItem:GetNumByRefId(refId)
    local needNum = constList[1].ten.count
    local isItem = true
    if haveNum < needNum then
        refId = constList[2].ten.refId
        haveNum = gModelItem:GetNumByRefId(refId)
        needNum = constList[2].ten.count
        isItem = false

        if leftDiamond < 10 then
            if showTips then
                GF.ShowMessage(ccClientText(41022))
            end
            return false
        end
    end

    if haveNum < needNum then
        if showTips then
            gModelGeneral:OpenGetWayWnd({ itemId = refId })
        end
        return false
    end
    return true, isItem, refId, needNum
end

-- true：可激活或升级
function ModelDraconic:CanActiveOrUpStar(refId, showTips)
    local starNum = self:GetSpeechStar(refId)
    local costItem = self:GetUpStarCostRef(refId, starNum)
    if not costItem then
        if showTips then
            GF.ShowMessage(ccClientText(41031))
        end
        return false
    end

    local haveNum = gModelItem:GetNumByRefId(costItem.refId)
    if haveNum < costItem.count then
        if showTips then
            local needNum = costItem.count - haveNum
            gModelGeneral:OpenGetWayWnd({ itemId = costItem.refId, needNum = needNum })
        end
        return false
    end

    return true
end

-- ture: 可升级或激活图鉴
function ModelDraconic:CanUpOrActiveIllustrated(refId, showTips)
    local lev = self:GetIllustratedLev(refId)
    local upRef = self:GetIllustratedUpLevRef(refId, lev)

    local ref = GameTable.DraconicRelationRef[refId]
    local enough = true
    for i = 1, 2 do
        local starNum = self:GetSpeechStar(ref.draconicId[i])
        if upRef.upNeed > starNum then
            enough = false
            break
        end
    end
    if not enough then
        if showTips then
            if upRef.upNeed == 0 then
                GF.ShowMessage(ccClientText(41075, "ff0000", upRef.upNeed))
            else
                GF.ShowMessage(ccClientText(41042, "ff0000", upRef.upNeed))
            end
        end
        return false
    end

    if upRef.upNeed == -1 then
        if showTips then
            GF.ShowMessage(ccClientText(41058))
        end
        return
    end
    return true
end

-- true:表示可附魂
function ModelDraconic:CanAttach(refId)
    local starNum = self:GetSpeechStar(refId)
    if starNum == -1 then
        return false
    end

    local refIdList = self:GetCanAttachRefIdList(refId)
    if #refIdList == 0 then
        return false
    end

    if self:GetAttachRefId(refId) > 0 then
        return false
    end

    for k, v in ipairs(refIdList) do
        if self:GetSpeechStar(v) >= 0 and self:GetMainAttachRefId(v) == 0 then
            return true
        end
    end

    return false
end

-- 龙魂系统子功能红点
function ModelDraconic:GetRedNumByFuncId(funcId)
    if not gModelFunctionOpen:CheckIsOpened(funcId) then
        return 0
    end

    if not self._initInfo then
        return 0
    end

    if funcId == FuncIdEnum.Main then
        if self:CanUp() then
            return 1
        end
        if self:HadCanUse() then
            return 1
        end
        return 0
    end

    if funcId == FuncIdEnum.Summon then
        local leftFreeTimes = self:GetLeftFreeSummonTimes()
        if leftFreeTimes > 0 then
            return 1
        end
        if self:HadReceiveSummonBox() then
            return 1
        end

        local wishDraconicId = self:GetWishDraconicRefId()
        if wishDraconicId == 0 and self:IsCanWish() then
            return 1
        end

        local can, isItem = self:EnoughSummonTen()
        if can and isItem then
            return 1
        end

        return 0
    end

    if funcId == FuncIdEnum.Speech then
        for _, v in pairs(GameTable.DraconicRef) do
            if self:CanActiveOrUpStar(v.refId) then
                return 1
            end

            if self:CanAttach(v.refId) then
                return 1
            end
        end

        return 0
    end

    if funcId == FuncIdEnum.Illustrated then
        for _, v in pairs(GameTable.DraconicRelationRef) do
            if self:CanUpOrActiveIllustrated(v.refId) then
                return 1
            end
        end
        return 0
    end

    return 0
end

-- 龙魂系统红点
function ModelDraconic:GetRedNum()
    if not gModelFunctionOpen:CheckIsOpened(FuncIdEnum.Main) then
        return 0
    end

    for k, v in pairs(FuncIdEnum) do
        if self:GetRedNumByFuncId(v) > 0 then
            return 1
        end
    end

    return 0
end

-- 比较两个龙语，返回星级更高的龙语
function ModelDraconic:CompareSpeech(refUpId1, refUpId2)
    if refUpId1 == refUpId2 or refUpId1 == 0 then
        return refUpId1
    end
    local DraconicSuitRankRef = GameTable.DraconicSuitRankRef
    local ref1 = DraconicSuitRankRef[refUpId1]
    local ref2 = DraconicSuitRankRef[refUpId2]
    if ref1.type == ref2.type then
        return math.max(refUpId1, refUpId2)
    end
    return refUpId1
end

-- 获取附魂龙语RefId, -1:表示不可附魂，0:表示未附魂
function ModelDraconic:GetAttachRefId(refId)
    local list = self:GetCanAttachRefIdList(refId)
    if #list == 0 then
        return -1
    end

    for k, v in ipairs(self._objs) do
        if v.refId == refId then
            return v.linkRefId or 0
        end
    end
    return 0
end

-- 获取当前龙语已被其它龙语附魂的龙语id, 0表示没有被引用
function ModelDraconic:GetMainAttachRefId(refId)
    for k, v in ipairs(self._objs) do
        if v.linkRefId == refId then
            return v.refId
        end
    end
    return 0
end

-- endregion ----------------------------------------------------



-- region 配置 ----------------------------------------------------

-- 获取升级消耗
function ModelDraconic:GetLevCost(lev)
    lev = lev or self:GetLev()
    local ref = self:GetDraconicBuildingLvRef(lev)
    if not ref then
        return nil
    end

    if ref.lvNext == -1 then
        return nil
    end

    -- local nextRef = self:GetDraconicBuildingLvRef(lev + 1)
    -- if not nextRef then
    --     return nil
    -- end
    local list = LUtil.GetRefItemDataList(ref.upNeed)
    return list
end

-- 通过等级获取等级配置
function ModelDraconic:GetDraconicBuildingLvRef(lev)
    if not self._DraconicBuildingLvRef then
        self._DraconicBuildingLvRef = {}
        for k, v in pairs(GameTable.DraconicBuildingLvRef) do
            self._DraconicBuildingLvRef[v.lvNow] = v
        end
    end
    return self._DraconicBuildingLvRef[lev]
end

-- 龙语属性转化字符串
function ModelDraconic:GetBaseAttrConversionStr()
    local lev = self:GetLev()
    local ref = self:GetDraconicBuildingLvRef(lev)

    local str = ccClientText(41007, ref.attrChange .. "%")
    local nextLv = self:GetBaseAttrConversionNextLev()
    if nextLv then
        str = str .. ccClientText(41008, nextLv)
    end
    return str
end

-- 龙语属性转化字符串2
function ModelDraconic:GetHeroAttrConversionStr()
    local lev = self:GetLev()
    local ref = self:GetDraconicBuildingLvRef(lev)

    local value = "0%"
    if ref.attrALL ~= "" then
        local tab = string.split(ref.attrALL, "=")
        value = tonumber(tab[3]) * 100 .. "%"
    end
    local str = ccClientText(41009, value)
    local nextLv = self:GetHeroAttrConversionNextLev()
    if nextLv then
        str = str .. ccClientText(41008, nextLv)
    end
    return str
end

-- 龙语属性转化下一级
function ModelDraconic:GetBaseAttrConversionNextLev()
    if not self._conversionLvList then
        local list = {}
        for k, v in pairs(GameTable.DraconicBuildingLvRef) do
            if v.addMark == 1 then
                table.insert(list, v)
            end
        end
        table.sort(list, function(a, b)
            return a.lvNow < b.lvNow
        end)
        self._conversionLvList = list
    end

    local lev = self:GetLev()
    for k, v in ipairs(self._conversionLvList) do
        if lev < v.lvNow then
            return self._conversionLvList[k].lvNow
        elseif lev == v.lvNow then
            if self._conversionLvList[k + 1] then
                return self._conversionLvList[k + 1].lvNow
            end
            return nil
        end
    end
end

-- 龙语英雄转化下一级
function ModelDraconic:GetHeroAttrConversionNextLev()
    if not self._conversionLvList2 then
        local list = {}
        for k, v in pairs(GameTable.DraconicBuildingLvRef) do
            if v.addMark == 2 then
                table.insert(list, v)
            end
        end
        table.sort(list, function(a, b)
            return a.lvNow < b.lvNow
        end)
        self._conversionLvList2 = list
    end

    local lev = self:GetLev()
    for k, v in ipairs(self._conversionLvList2) do
        if lev < v.lvNow then
            return self._conversionLvList2[k].lvNow
        elseif lev == v.lvNow then
            if self._conversionLvList2[k + 1] then
                return self._conversionLvList2[k + 1].lvNow
            end
            return nil
        end
    end
end

-- 获取龙魂技能解锁等级
function ModelDraconic:GetSkillOpenLev(index)
    if not self._skillOpenList then
        local str = GameTable.DraconicConfigRef.skillOpen
        local tab = string.split(str, ";")
        self._skillOpenList = {}
        for index, v in ipairs(tab) do
            local data = string.split(v, "=")
            self._skillOpenList[index] = tonumber(data[2])
        end
    end
    if index then
        return self._skillOpenList[index]
    end
    return self._skillOpenList
end

-- true:当前位置已解锁
function ModelDraconic:IsSkillOpenByPos(index)
    if not self._skillOpenList then
        local str = GameTable.DraconicConfigRef.skillOpen
        local tab = string.split(str, ";")
        self._skillOpenList = {}
        for index, v in ipairs(tab) do
            local data = string.split(v, "=")
            self._skillOpenList[index] = tonumber(data[2])
        end
    end
    local needLev = self:GetSkillOpenLev(index)
    local lev = self:GetLev()
    
    if nil == needLev or nil == lev then 
        printInfoN2("ModelDraconic","配置丢失--DraconicConfigRef--index"..index)
        return false
    end 
    
    if needLev <= lev then
        return true
    end

    return false, string.replace(ccClientText(41014), needLev)
end

-- 召唤固定奖励
function ModelDraconic:GetSummonFixedReward()
    return LUtil.GetRefItemData(GameTable.DraconicConfigRef.rewardFix)
end

-- 获取召唤消耗
function ModelDraconic:GetSummonCost()
    if not self._summonCostRef then
        self._summonCostRef = {}
        self._summonCostRef[1] = {}
        self._summonCostRef[1].one = LUtil.GetRefItemData(GameTable.DraconicConfigRef.callUseItem)
        self._summonCostRef[1].ten = LUtil.GetRefItemData(GameTable.DraconicConfigRef.callUseItemMore)

        self._summonCostRef[2] = {}
        self._summonCostRef[2].one = LUtil.GetRefItemData(GameTable.DraconicConfigRef.callUseDiamond)
        self._summonCostRef[2].ten = LUtil.GetRefItemData(GameTable.DraconicConfigRef.callUseDiamondMore)
    end

    return self._summonCostRef
end

-- 获取召唤进度配置
function ModelDraconic:GetSummonProgressRef()
    if not self._summonProgressRef then
        local str = GameTable.DraconicConfigRef.rewardAdd
        local tab = string.split(str, ";")
        local list = {}
        for k, v in ipairs(tab) do
            local datas = string.split(v, "|")
            table.insert(list, {
                progress = tonumber(datas[1]),
                items = { LUtil.GetRefItemData(datas[2]) }
            })
        end

        self._summonProgressRef = list
    end

    return self._summonProgressRef
end

-- 获取召唤奖励池配置
function ModelDraconic:GetSummonItemPoolRef()
    if not self._summonItemPoolRef then
        local list = {}
        for k, v in pairs(GameTable.DraconicDropRef) do
            if v.type == 10 then
                table.insert(list, v)
            end
        end

        table.sort(list, function(a, b)
            return a.sort > b.sort
        end)

        self._summonItemPoolRef = list
    end
    return self._summonItemPoolRef
end

-- 获取召唤奖励详情
function ModelDraconic:GetSummonDetail()
    local idMap = {}
    local tab = string.split(GameTable.DraconicConfigRef.jackpotRate, ";")
    for k, v in ipairs(tab) do
        local data = string.split(v, "=")
        idMap[tonumber(data[1])] = true
    end

    local list = {}
    for _, ref in pairs(GameTable.DraconicDropRef) do
        if idMap[ref.type] then
            table.insert(list, ref)
        end
    end

    table.sort(list, function(a, b)
        if a.sort ~= b.sort then
            return a.sort < b.sort
        end
        return a.refId < b.refId
    end)
    return list
end

-- 获取龙语配置
function ModelDraconic:GetDraconicRef(refId)
    return GameTable.DraconicRef[refId]
end

-- 获取召唤奖励池配置
function ModelDraconic:GetSummonItemPoolRefById(refId)
    return GameTable.DraconicDropRef[refId]
end

-- 获取召唤许愿概率
function ModelDraconic:GetSummonWishRate()
    return GameTable.DraconicConfigRef.specialRate * 0.01
end

-- 获取召唤顶部资产
function ModelDraconic:GetSummonTopAssetList()
    return GameTable.DraconicConfigRef.showItem
end

-- 获取龙语配置列表 (按品质分类)
function ModelDraconic:GetAllSpeechRefList()
    if not self._speechRefList then
        local map = {}
        for k, v in pairs(GameTable.DraconicRef) do
            if not map[v.quality] then
                map[v.quality] = {}
            end
            table.insert(map[v.quality], v)
        end

        local function sort(a, b)
            return a.sort < b.sort
        end
        local list = {}
        for k, v in pairs(map) do
            table.sort(v, sort)
            table.insert(list, v)
        end
        table.sort(list, function(a, b)
            return a[1].quality > b[1].quality
        end)
        self._speechRefList = list
    end
    return self._speechRefList
end

-- 获取龙语配置列表
function ModelDraconic:GetAllSpeechRefList2()
    if not self._speechRefList2 then
        local list = {}
        for k, v in pairs(GameTable.DraconicRef) do
            table.insert(list, v)
        end
        table.sort(list, function(a, b)
            if a.sort ~= b.sort then
                return a.sort > b.sort
            end
            return a.refId < b.refId
        end)
        self._speechRefList2 = list
    end
    return self._speechRefList2
end

-- 获取升星配置
function ModelDraconic:GetUpStarRef(type, star)
    if not self._upStarRef then
        local map = {}
        for k, v in pairs(GameTable.DraconicSuitRankRef) do
            if not map[v.type] then
                map[v.type] = {}
            end
            map[v.type][v.rankNow] = v
        end
        self._upStarRef = map
    end
    if self._upStarRef[type] then
        return self._upStarRef[type][star]
    end
    return nil
end

-- 获取升星配置列表
function ModelDraconic:GetUpStarRefList(type)
    if not self._upStarRef then
        local map = {}
        for k, v in pairs(GameTable.DraconicSuitRankRef) do
            if not map[v.type] then
                map[v.type] = {}
            end
            map[v.type][v.rankNow] = v
        end
        self._upStarRef = map
    end
    return self._upStarRef[type]
end

-- 获取升星消耗, 返回nil，表示已满星
function ModelDraconic:GetUpStarCostRef(type, star)
    if not self._upStarCostRef then
        local map = {}
        for k, v in pairs(GameTable.DraconicSuitRankRef) do
            if not map[v.type] then
                map[v.type] = {}
            end
            map[v.type][v.rankNow] = LUtil.GetRefItemData(v.upNeed)
        end
        self._upStarCostRef = map
    end

    if self._upStarCostRef[type] then
        return self._upStarCostRef[type][star + 1]
    end
    return nil
end

-- 获取最大星级
function ModelDraconic:GetStarMax(type)
    if not self._upStarCostRef then
        local map = {}
        for k, v in pairs(GameTable.DraconicSuitRankRef) do
            if not map[v.type] then
                map[v.type] = {}
            end
            map[v.type][v.rankNow] = LUtil.GetRefItemData(v.upNeed)
        end
        self._upStarCostRef = map
    end

    local max = 0
    for k in pairs(self._upStarCostRef[type] or {}) do
        max = math.max(max, k)
    end
    return max
end

-- 获取龙语属性
function ModelDraconic:GetSpeechBaseAttr(type, star)
    local ref = self:GetUpStarRef(type, star)
    local attrList = {}
    for i, v in ipairs(string.split(ref.attr, ",")) do
        v = string.split(v, "=")
        local attrId, type, value = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])
        table.insert(attrList, { attrId = attrId, type = type, value = value })
    end
    return attrList
end

-- 获取龙语技能标签
function ModelDraconic:GetSkillFlagRef(refId)
    local ref = GameTable.DraconicRef[refId]

    local str = ccLngText(ref.logoTxt)
    local list = string.split(str, "|")

    return list, ref.logoIcon
end

-- 获取图鉴配置列表
function ModelDraconic:GetIllustratedRefList()
    if not self._IllustratedRefList then
        local list = {}
        for k, v in pairs(GameTable.DraconicRelationRef) do
            table.insert(list, v)
        end
        table.sort(list, function(a, b)
            return a.sort < b.sort
        end)
        self._IllustratedRefList = list
    end
    return self._IllustratedRefList
end

-- 获取图鉴升级配置列表
function ModelDraconic:GetIllustratedUpLevRef(type, lev)
    if not self._IllustratedUpLevRef then
        local map = {}
        for k, v in pairs(GameTable.DraconicRelationLvRef) do
            if not map[v.type] then
                map[v.type] = {}
            end

            map[v.type][v.rankNow] = v
        end
        self._IllustratedUpLevRef = map
    end
    return self._IllustratedUpLevRef[type][lev]
end

-- 获取图鉴属性
function ModelDraconic:GetIllustratedAttr(type, lev, ref)
    if not ref then
        ref = self:GetIllustratedUpLevRef(type, lev)
    end
    local attrList = {}
    for i, v in ipairs(string.split(ref.attr, ",")) do
        v = string.split(v, "=")
        local attrId, type, value = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])
        table.insert(attrList, { attrId = attrId, type = type, value = value })
    end
    return attrList
end

-- 获取龙魂碎片分解获得的物品
function ModelDraconic:GetDraconicResolveItemList(itemList)
    if not self._itemResolveRef then
        local map = {}
        for k, v in pairs(GameTable.DraconicRef) do
            map[v.item] = {}
            map[v.item].ref = v

            local list = {}
            list[1] = LUtil.GetRefItemData(v.itemSell)
            map[v.item].itemSell = list
        end
        self._itemResolveRef = map
    end

    local map = {}
    for _, v in ipairs(itemList) do
        local list = self._itemResolveRef[v.refId] and self._itemResolveRef[v.refId].itemSell
        for _, tab in ipairs(list or {}) do
            if not map[tab.refId] then
                map[tab.refId] = { refId = tab.refId, count = v.count * tab.count, type = tab.type }
            else
                map[tab.refId].count = map[tab.refId].count + v.count * tab.count
            end
        end
    end

    local list = {}
    for k, v in pairs(map) do
        v.itemId = v.refId
        v.itemNum = v.count
        v.itype = v.type
        v.itemType = v.type
        table.insert(list, v)
    end

    return list
end

-- 通过技能id获取龙语配置
function ModelDraconic:GetDraconicRefBySkillId(skillId)
    if not self._skillRefMap then
        self._skillRefMap = {}
        local DraconicRef = GameTable.DraconicRef
        for k, v in pairs(GameTable.DraconicSuitRankRef) do
            self._skillRefMap[v.skillId] = { ref = DraconicRef[v.type], upRef = v }
        end
    end

    local data = self._skillRefMap[skillId]
    if data then
        return data.ref, data.upRef
    end
    return nil, nil
end

-- 获取可以附魂的龙语id列表, 空列表:表示不可附魂; 列表大小为1:表示固定附魂, 大于1：表示可选附魂
function ModelDraconic:GetCanAttachRefIdList(refId)
    local ref = self:GetDraconicRef(refId)
    return ref.linkGoal or {}
end

-- 获取附魂触发概率
function ModelDraconic:GetAttachTriggerRate(refId, star)
    if not star then
        star = self:GetSpeechStar(refId)
        if star == -1 then
            star = 0
        end
    end

    local ref = self:GetUpStarRef(refId, star)

    if ref then
        return ref.linkRate * 100
    end
    return 0
end

-- endregion ----------------------------------------------------


-- region通用ui 配置 ---------------------------------------------

-- 通用卡片


--- 当前如果满星了，显示满星标记
ModelDraconic.ShowFullStar = false

---@param wnd LWnd
function ModelDraconic:DrawCard(wnd, rootTrans, param)
    param = param or {}
    local refId = param.refId

    local instanceID = rootTrans:GetInstanceID()
    local itemCache = wnd:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {}
        itemCache.icon = CS.FindTrans(rootTrans, "icon")
        itemCache.name = CS.FindTrans(rootTrans, "name")
        itemCache.namebg = CS.FindTrans(rootTrans, "namebg")
        itemCache.select = CS.FindTrans(rootTrans, "select")
        itemCache.type1 = CS.FindTrans(rootTrans, "typeRoot/type1")
        itemCache.type2 = CS.FindTrans(rootTrans, "typeRoot/type2")

        local list = {}
        for i = 1, 10 do
            list[i] = CS.FindTrans(rootTrans, "starRoot/star" .. i)
        end
        itemCache.starList = list
        itemCache.starRoot = list[1].parent

        itemCache.txtTips = CS.FindTrans(rootTrans, "txtTips")
        itemCache.select = CS.FindTrans(rootTrans, "select")
        itemCache.mask = CS.FindTrans(rootTrans, "mask")

        local sliderRoot = CS.FindTrans(rootTrans,"sliderRoot")
        itemCache.sliderRoot = sliderRoot
        itemCache.txtSlider = CS.FindTrans(sliderRoot, "txtSlider")
        itemCache.slider = CS.FindTrans(sliderRoot, "sliderBg/slider")
        itemCache.lock = CS.FindTrans(sliderRoot, "Img0")
        itemCache.sliderSize = itemCache.slider.sizeDelta

        local MaxStarDiv = CS.FindTrans(rootTrans,"MaxStarDiv")
        itemCache.MaxStarDiv = MaxStarDiv
        wnd:SetTextTile(MaxStarDiv,ccClientText(43718))

        wnd:SetTextTile(itemCache.type1, ccClientText(41028))
        wnd:SetTextTile(itemCache.type2, ccClientText(41029))

        wnd:SetComponentCache(instanceID, itemCache)
    end

    local ref = GameTable.DraconicRef[refId]
    wnd:SetWndEasyImage(itemCache.icon, ref.icon)

    -- 名字
    local strName
    if param.showName then
        local color = gModelItem:GetColorStringByQualityId(ref.quality)
        strName = ccClientText(41021, color, ccLngText(ref.name))
    end
    wnd:SetWndText(itemCache.name, strName)
    CS.ShowObject(itemCache.namebg, param.showNameBg == true)

    -- 庶罩
    CS.ShowObject(itemCache.mask, param.showMask == true)

    -- 红点
    wnd:SetRed(rootTrans, param.showRed)

    -- -- 技能
    -- if param.showSkill then
    --     wnd:SetWndEasyImage(itemCache.skillBg, ref.skillbg)
    --     wnd:SetWndEasyImage(itemCache.skillIcon, ref.skillIcon)
    -- end
    -- CS.ShowObject(itemCache.skill, param.showSkill ~= nil)

    -- if param.showSkillName then
    --     local color = gModelItem:GetColorStringByQualityId(ref.quality)
    --     local skillName = ccClientText(41021, color, ccLngText(ref.name))
    --     wnd:SetWndText(itemCache.skillName, skillName)
    -- end
    -- CS.ShowObject(itemCache.skillName.parent, param.showSkillName ~= nil)


    -- 类型
    if param.showType then
        CS.ShowObject(itemCache.type1, ref.effetcType == 1)
        CS.ShowObject(itemCache.type2, ref.effetcType == 2)

        if gLGameLanguage:IsJapanRegion() then
            CS.ShowObject(itemCache.type1, false)
            CS.ShowObject(itemCache.type2, false)
        end

        if gLGameLanguage:IsVieVersion() then
            CS.ShowObject(itemCache.type1, false)
            CS.ShowObject(itemCache.type2, false)
        end
    end
    CS.ShowObject(itemCache.type1.parent, param.showType ~= nil)

    local showSelect = not not param.select
    -- 选中
    CS.ShowObject(itemCache.select, showSelect)


    -- 星星
    local starNum = param.starNum
    if starNum then
        if starNum <= 5 then
            for i = 1, 5 do
                CS.ShowObject(itemCache.starList[i], i <= starNum)
            end
            for i = 6, 10 do
                CS.ShowObject(itemCache.starList[i], false)
            end
        else
            for i = 1, 5 do
                CS.ShowObject(itemCache.starList[i], false)
            end
            for i = 6, 10 do
                CS.ShowObject(itemCache.starList[i], i <= starNum)
            end
        end
    end
    CS.ShowObject(itemCache.starRoot, param.starNum and true or false)

    -- 激活进度
    local showSlider = param.showSlider
    if showSlider then
        local costItem = self:GetUpStarCostRef(refId, param.starNum)
        local isMax = not costItem
        local max = 0
        local haveNum = 0
        if isMax then
            -- 已满星
            max = 1
            haveNum = 1
        else
            max = costItem.count
            haveNum = gModelItem:GetNumByRefId(costItem.refId)
        end

        local value = math.min(max, haveNum)
        local strValue
        if param.noSliderMax and isMax then
            costItem = self:GetUpStarCostRef(refId, 1)
            haveNum = gModelItem:GetNumByRefId(costItem.refId)

            haveNum = LUtil.PowerNumberCoversion(haveNum)
            strValue = ccClientText(41021, "FFFFFF", haveNum)
        else
            if param.noSliderMax then
                if value == max then
                    strValue = ccClientText(41021, "FFFFFF", value .. "/" .. max)
                else
                    strValue = ccClientText(41021, "FFFFFF", value .. "/" .. max)
                end
            else
                if value == max then
                    strValue = ccClientText(41021, "25D101", value .. "/" .. max)
                else
                    strValue = ccClientText(41021, "FF7676", value .. "/" .. max)
                end
            end
        end
        itemCache.slider.sizeDelta = Vector2(value / max * itemCache.sliderSize.x, itemCache.sliderSize.y)
        wnd:SetWndText(itemCache.txtSlider, strValue)
        CS.ShowObject(itemCache.lock, param.starNum == -1)

        local showMaxStarDiv = false
        if param.showFullStar and not ModelDraconic.ShowFullStar and isMax then
            showMaxStarDiv = true
            showSlider = false
        end
        CS.ShowObject(itemCache.MaxStarDiv,showMaxStarDiv)
    end
    CS.ShowObject(itemCache.sliderRoot, showSlider)

    local txtTips = param.txtTips or ""
    wnd:SetWndText(itemCache.txtTips, txtTips)
end

-- 技能标签
function ModelDraconic:DrawSkillFlag(wnd, rootTrans, refId)
    local instanceID = rootTrans:GetInstanceID()
    local itemCache = wnd:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {}
        itemCache.uiList = {}
        wnd:SetComponentCache(instanceID, itemCache)
    end

    local txtList, imgList = self:GetSkillFlagRef(refId)
    for k, v in ipairs(txtList) do
        if not itemCache.uiList[k] then
            local obj = CS.InstantObject(rootTrans.gameObject)
            local trans = obj.transform
            trans:SetParent(rootTrans.parent, false)
            CS.ShowObject(trans, true)
            itemCache.uiList[k] = trans
        end
        CS.ShowObject(itemCache.uiList[k], true)
        wnd:SetTextTile(itemCache.uiList[k], txtList[k])
        wnd:SetWndEasyImage(itemCache.uiList[k], imgList[k])
    end

    for i = #txtList + 1, #itemCache.uiList do
        CS.ShowObject(itemCache.uiList[k], false)
    end
end

-- 龙魂技能item
function ModelDraconic:DrawSkillItem(wnd, rootTrans, param)
    local instanceID = rootTrans:GetInstanceID()
    local itemCache = wnd:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {}
        itemCache.bg = CS.FindTrans(rootTrans, "bg")
        itemCache.icon = CS.FindTrans(rootTrans, "icon")
        itemCache.levBg = CS.FindTrans(rootTrans, "levBg")
        itemCache.lev = CS.FindTrans(rootTrans, "levBg/lev")
        itemCache.select = CS.FindTrans(rootTrans, "select")
        itemCache.lock = CS.FindTrans(rootTrans, "lock")
        itemCache.mask = CS.FindTrans(rootTrans, "mask")
        itemCache.empty = CS.FindTrans(rootTrans, "empty")
        itemCache.name = CS.FindTrans(rootTrans, "name")
        itemCache.type1 = CS.FindTrans(rootTrans, "typeRoot/type1")
        itemCache.type2 = CS.FindTrans(rootTrans, "typeRoot/type2")

        local list = {}
        for i = 1, 10 do
            list[i] = CS.FindTrans(rootTrans, "starRoot/star" .. i)
        end
        itemCache.starList = list

        wnd:SetTextTile(itemCache.type1, ccClientText(41028))
        wnd:SetTextTile(itemCache.type2, ccClientText(41029))

        wnd:SetComponentCache(instanceID, itemCache)
    end

    local select = not not param.select
    local mask = not not param.mask
    local lock = not not param.lock

    CS.ShowObject(itemCache.select, select)
    CS.ShowObject(itemCache.mask, mask or select)
    CS.ShowObject(itemCache.lock, lock)
    CS.ShowObject(itemCache.empty, param.upRefId == nil)

    if not param.upRefId then
        return
    end

    local upRef = GameTable.DraconicSuitRankRef[param.upRefId]
    local ref = GameTable.DraconicRef[upRef.type]

    wnd:SetWndEasyImage(itemCache.bg, ref.skillbg)
    wnd:SetWndEasyImage(itemCache.icon, ref.skillIcon)

    local strName = "";
    if param.showName then
        local color = gModelItem:GetColorStringByQualityId(ref.quality)
        strName = ccClientText(41021, color, ccLngText(ref.name))
    end
    wnd:SetWndText(itemCache.name, strName)

    if self._isEnus then
        wnd:InitTextShowWithLanguage(itemCache.name)
    end

    if param.showLev then
        wnd:SetWndText(itemCache.lev, upRef.rankNow + 1)
    end
    CS.ShowObject(itemCache.levBg, param.showLev ~= nil)

    if param.clickFunc then
        wnd:SetWndClick(rootTrans, param.clickFunc)
    end

    -- 星星
    if param.showStar then
        local starNum = upRef.rankNow
        if starNum <= 5 then
            for i = 1, 5 do
                CS.ShowObject(itemCache.starList[i], i <= starNum)
            end
            for i = 6, 10 do
                CS.ShowObject(itemCache.starList[i], false)
            end
        else
            for i = 1, 5 do
                CS.ShowObject(itemCache.starList[i], false)
            end
            for i = 6, 10 do
                CS.ShowObject(itemCache.starList[i], i <= starNum)
            end
        end
    end


    -- 类型
    if param.showType then
        CS.ShowObject(itemCache.type1, ref.effetcType == 1)
        CS.ShowObject(itemCache.type2, ref.effetcType == 2)
    end
    CS.ShowObject(itemCache.type1.parent, param.showType ~= nil)
end

-- 龙魂碎片item
function ModelDraconic:DrawItem(wnd, rootTrans, param)
    local instanceID = rootTrans:GetInstanceID()
    local itemCache = wnd:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {}
        itemCache.bg = CS.FindTrans(rootTrans, "bg")
        itemCache.icon = CS.FindTrans(rootTrans, "icon")
        itemCache.num = CS.FindTrans(rootTrans, "num")
        itemCache.select = CS.FindTrans(rootTrans, "select")
        itemCache.lock = CS.FindTrans(rootTrans, "lock")
        itemCache.mask = CS.FindTrans(rootTrans, "mask")
        itemCache.empty = CS.FindTrans(rootTrans, "empty")
        wnd:SetComponentCache(instanceID, itemCache)
    end

    local refId = param.refId
    if refId then
        local strNum = ""
        if param.num and param.num > 0 then
            strNum = LUtil.NumberCoversion(param.num)
        end

        local iconPath, iconBgPath = gModelItem:GetItemImgByRefId(refId)
        wnd:SetWndEasyImage(itemCache.icon, iconPath)
        wnd:SetWndEasyImage(itemCache.bg, iconBgPath)
        wnd:SetWndText(itemCache.num, strNum)
    end
    CS.ShowObject(itemCache.empty, refId ~= nil)

    local select = not not param.select
    local mask = not not param.mask
    local lock = not not param.lock
    CS.ShowObject(itemCache.select, select)
    CS.ShowObject(itemCache.mask, mask or select)
    CS.ShowObject(itemCache.lock, lock)

    if param.clickFunc then
        wnd:SetWndClick(rootTrans, param.clickFunc)
    end
end

-- 技能template
function ModelDraconic:DrawSkillTemplate(wnd, trans, data)
    local instanceID = trans:GetInstanceID()
    local itemCache = wnd:GetComponentCache(instanceID)
    if not itemCache then
        itemCache = {
            txtSkillDesc = CS.FindTrans(trans, "txtSkillDesc"),
            img1= CS.FindTrans(trans, "top/Img1"),
            txtSkillLev = CS.FindTrans(trans, "top/Img1/txtSkillLev"),
            skillBg = CS.FindTrans(trans, "top/1/skillBg"),
            skillIcon = CS.FindTrans(trans, "top/1/skillIcon"),
            lock = CS.FindTrans(trans, "top/1/lock"),
            txtTips = CS.FindTrans(trans, "top/Img2/txtTips"),
            txtTips2 = CS.FindTrans(trans, "top/Img2/txtTips2"),
            skillFlag = CS.FindTrans(trans, "top/Img2/skillFlagRoot/skillFlag"),
            btnTips = CS.FindTrans(trans, "top/btnTips"),
            skillFlagRoot = CS.FindTrans(trans, "top/Img2/skillFlagRoot"),
        }
        wnd:SetComponentCache(instanceID, itemCache)
    end

    local refId = data.refId

    wnd:SetWndText(itemCache.txtTips, data.txtTips or "")
    wnd:SetWndText(itemCache.txtTips2, data.txtTips2 or "")

    if self._isEnus then
        wnd:SetAnchorPos(itemCache.img1,Vector2.New(-134.5,-80))
        if data.lock == true then
            wnd:SetAnchorPos(itemCache.skillFlagRoot, Vector2.New(250, 0))
            wnd:SetAnchorPos(itemCache.txtTips2, Vector2.New(290, 0))
        else
            wnd:SetAnchorPos(itemCache.skillFlagRoot, Vector2.New(269.6, 0))
            wnd:SetAnchorPos(itemCache.txtTips2, Vector2.New(278, 0))
        end
    end
    
    if self._isVie then
        wnd:SetAnchorPos(itemCache.img1,Vector2.New(-134.5,-80))
        if data.lock == true then
            wnd:SetAnchorPos(itemCache.skillFlagRoot, Vector2.New(310, 0))
            wnd:SetAnchorPos(itemCache.txtTips2, Vector2.New(290, 0))
        else
            wnd:SetAnchorPos(itemCache.skillFlagRoot, Vector2.New(310, 0))
            wnd:SetAnchorPos(itemCache.txtTips2, Vector2.New(278, 0))
        end

        wnd:SetAnchorPos(itemCache.txtTips2, Vector2.New(-68, -24))
    end 

    -- 技能标签
    if not data.hideSkillFlag then
        self:DrawSkillFlag(wnd, itemCache.skillFlag, refId)
    end

    -- 技能图标
    local ref = self:GetDraconicRef(refId)
    wnd:SetWndEasyImage(itemCache.skillBg, ref.skillbg)
    wnd:SetWndEasyImage(itemCache.skillIcon, ref.skillIcon)
    CS.ShowObject(itemCache.lock, data.lock == true)

    local starNum = data.starNum or self:GetSpeechStar(refId)
    wnd:SetWndText(itemCache.txtSkillLev, ccClientText(41036, starNum + 1))

    local upRef = self:GetUpStarRef(refId, math.max(0, starNum))
    local skillRef = GameTable.SnakeSkillRef[upRef.skillId]

    if self._isEnus then
        wnd:SetWndText(itemCache.txtSkillDesc, "             " .. ccLngText(skillRef.description))
        wnd:InitTextLineWithLanguage(itemCache.txtSkillDesc, 20)
    else
        wnd:SetWndText(itemCache.txtSkillDesc, "           " .. ccLngText(skillRef.description))
    end
    LayoutRebuilder.ForceRebuildLayoutImmediate(itemCache.txtSkillDesc)

    CS.ShowObject(itemCache.btnTips, data.btnTipsFunc ~= nil)
    if data.btnTipsFunc then
        wnd:SetWndClick(itemCache.btnTips, function()
            data.btnTipsFunc()
        end)
    end
end

-- endregion ----------------------------------------------------
return ModelDraconic
