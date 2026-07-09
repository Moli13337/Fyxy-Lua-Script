LXImport("..Struct.StructMagicCircleData")

local LModel = LModel
------------------------------------------------------------------
---@class ModelMagic:LModel
local ModelMagic = LxClass("ModelMagic", LModel)

--region 初始化--------------------------------------------------------------------------------
function ModelMagic:ModelMagic()
    self:InitCacheServerData()
    self:InitCacheConfigData()
end

--模块初始化入口
--注册事件监听
--注册协议监听
--预处理数据
function ModelMagic:OnModelInit()
    self:ModelNetMsgRecv(LProtoIds.MagicInfoResp, function(...)
        self:OnMagicInfoResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.MagicLightCandleResp, function(...)
        self:OnMagicLightCandleResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.MagicUpLevelResp, function(...)
        self:OnMagicUpLevelResp(...)
    end)

    self:ModelNetMsgRecv(LProtoIds.MagicCollectionActiveResp, function(...)
        self:OnMagicCollectionActiveResp(...)
    end)
end

--在协议数据处理完之后需要调用finish
function ModelMagic:OnModelRequest()
    self:ModelFinish()
end

--初始化数据
--协议用到的缓存字段
function ModelMagic:InitCacheServerData()
    self._collectionRefId = 0
    self._collectionCode = 0

    self._candleData = {}
    self._circleData = {}

end

--解析配置表的缓存字段
function ModelMagic:InitCacheConfigData()
    self._magicCircleRefCache = {}
    self._magicCandleMapCircle = {}
    self._magicCandleTotalNeedCount = {}

    self._buffOriginIdMagicCircleRefId = {}
    self._buffCfg = {}

    self:ParseMagicCircleRef()
    self:ParseMagicBuffLvRef()
end

--endregion --------------------------------------------------------------------------------------

--region 定义事件常量 --------------------------------------------------------------------------------
ModelMagic.EventArgs = {
    ["LightCandle"] = "ModelMagic_LightCandle",
    ["CollectionActive"] = "ModelMagic_CollectionActive",
    ["UpLightCandle"] = "ModelMagic_UpLightCandle",
}

--endregion --------------------------------------------------------------------------------------

--region 收发协议 --------------------------------------------------------------------------------
--receive

--玩家的所有魔法阵数据
function ModelMagic:OnMagicInfoResp(pb)
    self._collectionRefId = pb.info.collectionRefId
    self._collectionCode = pb.info.collectionCode

    for k, v in ipairs(pb.info.circleData or {}) do
        local circleData = StructMagicCircleData:New()
        circleData:CreateByPb(v)
        local circleKey = circleData:GetMagicRefId()
        self._circleData[circleKey] = circleData
    end

    --阵法使用的蜡烛的信息
    for k, v in ipairs(pb.info.candleData or {}) do
        self._candleData[v.candleRefId] = v.num
    end
end

--点亮后 回发的魔法阵的数据
function ModelMagic:OnMagicLightCandleResp(pb)
    --收集度 直接替换掉
    self._collectionCode = pb.collection

    --魔法阵数据 进行更新
    local changeId = pb.circleData.magicRefId
    local circleData = self._circleData[changeId] or StructMagicCircleData:New()
    circleData:CreateByPb(pb.circleData)
    local circleKey = circleData:GetMagicRefId()
    self._circleData[circleKey] = circleData

    --阵法使用的蜡烛的信息
    for k, v in ipairs(pb.candleData or {}) do
        self._candleData[v.candleRefId] = v.num
    end

    FireEvent(self.EventArgs.LightCandle)
end

--升级后 回发的魔法阵的数据
function ModelMagic:OnMagicUpLevelResp(pb)
    --替换掉数据
    local changeId = pb.circleData.magicRefId
    local circleData = self._circleData[changeId] or StructMagicCircleData:New()
    circleData:CreateByPb(pb.circleData)
    local circleKey = circleData:GetMagicRefId()
    self._circleData[circleKey] = circleData

    FireEvent(self.EventArgs.UpLightCandle)

end

--收集进度更新
function ModelMagic:OnMagicCollectionActiveResp(pb)
    self._collectionRefId = pb.collectionRefId
    FireEvent(self.EventArgs.CollectionActive)
end

--send

--获取魔法阵数据
function ModelMagic:SendMagicInfoReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.MagicInfoReq)
    SendMessage(pb, LProtoIds.MagicInfoReq)
end

--点亮蜡烛
function ModelMagic:SendMagicLightCandleReq(magicRefId, seat)
    local pb = LProtoHelper.CreateProto(LProtoIds.MagicLightCandleReq)
    pb.magicRefId = magicRefId
    pb.seat = seat
    SendMessage(pb, LProtoIds.MagicLightCandleReq)
end

--魔法阵升级
function ModelMagic:SendMagicUpLevelReq(magicRefId, type, itemList)
    local pb = LProtoHelper.CreateProto(LProtoIds.MagicUpLevelReq)
    pb.magicRefId = magicRefId
    pb.type = type
    --用于升级
    if type == 1 then
        if itemList then
            local itemUseInfos = pb.items
            for i, v in ipairs(itemList) do
                local useInfo = itemUseInfos:add()
                useInfo.refId = v.itemId
                useInfo.num = v.itemNum
                useInfo.params = v.params or ""
            end
        end

    end

    SendMessage(pb, LProtoIds.MagicUpLevelReq)
end

--收集度
function ModelMagic:SendMagicCollectionActiveReq(refId)
    local pb = LProtoHelper.CreateProto(LProtoIds.MagicCollectionActiveReq)
    pb.refId = refId
    SendMessage(pb, LProtoIds.MagicCollectionActiveReq)
end
--endregion --------------------------------------------------------------------------------------

--region 协议数据获取接口 --------------------------------------------------------------------------------
--获取对应魔法阵的数据 无则为0   
function ModelMagic:GetCircleData(circleKey)
    return self._circleData[circleKey]
end

--获取进度和对应解锁的状态
function ModelMagic:GetCollectSchedule()
    return self._collectionCode, self._collectionRefId
end

--获取阵法使用的蜡烛的id和属性  
function ModelMagic:GetAllCandleData()
    return self._candleData
end
--endregion --------------------------------------------------------------------------------------

--region 配置缓存处理--------------------------------------------------------------------------------
function ModelMagic:ParseMagicCircleRef()
    -- 通过type 缓存一次
    for k, v in pairs(GameTable.MagicCircleRef) do
        if not self._magicCircleRefCache[v.type] then
            self._magicCircleRefCache[v.type] = {}
        end
        self._magicCircleRefCache[v.type][v.refId] = v


        --这里遍历 顺便缓存蜡烛对应的refId 
        local candleCount, cellItemPosition = self:ParseCandleCell(v.cell)
        --遍历需要的道具 

        local mapCache = {}
        for i, j in pairs(cellItemPosition) do
            if not self._magicCandleMapCircle[j.itemId] then
                self._magicCandleMapCircle[j.itemId] = {}
            end

            -- 防止重复创建  这里只需要记录一次 需要的阵法
            local key = k + j.itemId
            if mapCache[key] then
            else
                mapCache[key] = true
                table.insert(self._magicCandleMapCircle[j.itemId], k)
            end

            --这里顺便缓存每个蜡烛的总需求 _magicCandleTotalNeedCount
            if not self._magicCandleTotalNeedCount[j.itemId] then
                self._magicCandleTotalNeedCount[j.itemId] = 0
            end
            self._magicCandleTotalNeedCount[j.itemId] = self._magicCandleTotalNeedCount[j.itemId] + j.itemNum
        end

        self._buffOriginIdMagicCircleRefId[v.buff] = k
    end


    --type 为所有系列的key 缓存一份
    if not self._magicType then
        self._magicType = {}
    end

    for k, v in pairs(self._magicCircleRefCache) do
        table.insert(self._magicType, k)
    end

    table.sort(self._magicType, function(a, b)
        return a > b
    end)

    printInfoN2("---ParseMagicCircleRef", "--")
end

--缓存一次buff表
function ModelMagic:ParseMagicBuffLvRef()


    for k, v in pairs(GameTable.MagicBuffLvRef) do

        local curKey = v.type

        if not self._buffCfg[curKey] then
            self._buffCfg[curKey] = {}
        end
        table.insert(self._buffCfg[curKey], v)
    end

    --全部塞进去
    for k, v in pairs(self._buffCfg) do
        table.sort(v, function(a, b)
            return a.lv < b.lv
        end)
    end

    printInfoN2("---ParseMagicBuffLvRef", "--")
end
--endregion --------------------------------------------------------------------------------------

--region 配置表数据获取接口  转换数据用的接口 --------------------------------------------------------------------------------

--直接通过refId 获取到对应表的数据

--蜡烛表
function ModelMagic:GetMagicRef(refId)
    return GameTable.MagicRef[refId]
end

-- 阵法表
function ModelMagic:GetMagicCircleRef(refId)
    return GameTable.MagicCircleRef[refId]
end

-- 系列表
function ModelMagic:GetMagicTypeRef(refId)
    return GameTable.MagicTypeRef[refId]
end

-- 系列表类型 
function ModelMagic:GetMagicType()
    return self._magicType or {}
end
-- 增益等级表
function ModelMagic:GetMagicBuffLvRef(refId)
    return GameTable.MagicBuffLvRef[refId]
end

-- 收集度表
function ModelMagic:GetMagicCollectionRefByRefId(refId)
    return GameTable.MagicCollectionRef[refId]
end

--整张表的返回
function ModelMagic:GetMagicCollectionRef()
    return GameTable.MagicCollectionRef
end
-- 通过type 获取一组阵法表配置
function ModelMagic:GetMagicCircleRefsByType(type)
    return self._magicCircleRefCache[type]
end

-- 解析cell部分 蜡烛道具配置=格子id|蜡烛道具配置=格子id….
---@return number,table
function ModelMagic:ParseCandleCell(cell)
    local tempCell = string.split(cell, "|")
    local candleCount = #tempCell

    local cellItemPosition = {}

    for k, v in ipairs(tempCell) do
        local tempCell_2 = string.split(v, "=")

        local position = tonumber(tempCell_2[5])

        local itemType, itemId, itemNum = tonumber(tempCell_2[1]), tonumber(tempCell_2[2]), tonumber(tempCell_2[3])
        local data = {
            itemType = itemType,
            itemId = itemId,
            itemNum = itemNum,
        }

        cellItemPosition[position] = data
    end

    return candleCount, cellItemPosition

end

-- 解析对应的属性部分 这里直接拿到对应的name和value 
---@return  number,table
function ModelMagic:ParseAttr(attr)
    local temp_value_1 = string.split(attr, ",")

    local count = #temp_value_1

    local attrList = {}
    for k, v in ipairs(temp_value_1) do
        local data = {}
        v = string.split(v, "=")
        local attrRefId, attrType, attrValue = tonumber(v[1]), tonumber(v[2]), tonumber(v[3])
        local attrName = gModelHero:GetAttributeNameById(attrRefId)
        local attrStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, attrType, attrValue)
        data.attrRefId = attrRefId
        data.attrName = attrName
        data.attrType = attrType
        data.attrStr = attrStr
        data.attrValue = attrValue

        table.insert(attrList, data)
    end

    return count, attrList
end

--根据汇总的id 获取到对应的  --收益部分
---@return  number,table
function ModelMagic:GetAttrBenifitByRefId(refId)
    local showData = gModelMagic:GetMagicCollectionRef()
    local allAttrList = {}

    for k, v in ipairs(showData) do
        if v.refId <= refId then
            local count, attrList = gModelMagic:ParseAttr(v.attr)

            for i = 1, count do
                local attrRefId = attrList[i].attrRefId
                local attrKey = attrRefId * 10 + attrList[i].attrType
                if allAttrList[attrKey] then
                    allAttrList[attrKey].attrValue = allAttrList[attrKey].attrValue + attrList[i].attrValue
                else
                    allAttrList[attrKey] = {}
                    allAttrList[attrKey].attrRefId = attrList[i].attrRefId
                    allAttrList[attrKey].attrType = attrList[i].attrType
                    allAttrList[attrKey].attrValue = attrList[i].attrValue
                end
            end
        end
    end

    --计算完  转换成列表塞入结果中
    local result = self:ConvertAttrListToList(allAttrList)
    return #result, result
end

--解析单个蜡烛的加成
function ModelMagic:GetCandleAttr(candleRefId, num)
    local allAttrList = {}

    local candleCfg = self:GetMagicRef(candleRefId)

    local attr = candleCfg.attr

    local count, attrList = self:ParseAttr(attr)

    for i = 1, count do
        local attrRefId = attrList[i].attrRefId
        local attrKey = attrRefId * 10 + attrList[i].attrType

        if allAttrList[attrKey] then
            allAttrList[attrKey].attrValue = allAttrList[attrKey].attrValue + attrList[i].attrValue * num
        else
            allAttrList[attrKey] = {}
            allAttrList[attrKey].attrRefId = attrList[i].attrRefId
            allAttrList[attrKey].attrType = attrList[i].attrType
            allAttrList[attrKey].attrValue = attrList[i].attrValue * num
        end
    end

    --计算完  转换成列表塞入结果中

    local result = self:ConvertAttrListToList(allAttrList)

    return #result, result
end

--获取所有的蜡烛加成
function ModelMagic:GetAllCandleAttr()
    --先写几个假的数据
    if table.isempty(self._candleData) then
        return false
    end

    local allAttrList = {}

    for k, v in pairs(self._candleData) do
        --拿到对应的配置
        local candleCfg = self:GetMagicRef(k)

        local attr = candleCfg.attr

        local count, attrList = self:ParseAttr(attr)

        for i = 1, count do
            local attrRefId = attrList[i].attrRefId

            local attrKey = attrRefId * 10 + attrList[i].attrType
            if allAttrList[attrKey] then
                allAttrList[attrKey].attrValue = allAttrList[attrKey].attrValue + attrList[i].attrValue * v
            else
                allAttrList[attrKey] = {}
                allAttrList[attrKey].attrRefId = attrList[i].attrRefId
                allAttrList[attrKey].attrType = attrList[i].attrType
                allAttrList[attrKey].attrValue = attrList[i].attrValue * v
            end
        end
    end

    --计算完  转换成列表塞入结果中
    local result = self:ConvertAttrListToList(allAttrList)
    return #result, result
end

function ModelMagic:ConvertAttrListToList(allAttrList)
    local result = {}

    for k, v in pairs(allAttrList) do
        local attrRefId, attrType, attrValue = v.attrRefId, v.attrType, v.attrValue
        local attrName = gModelHero:GetAttributeNameById(attrRefId)
        local attrStr = gModelHero:GetAttributeValueNoNameByIdAndVal(attrRefId, attrType, attrValue)

        local data = {}
        data.attrRefId = attrRefId
        data.attrName = attrName
        data.attrType = attrType
        data.attrStr = attrStr
        data.attrValue = attrValue

        table.insert(result, data)
    end

    table.sort(result, function(a, b)

        if a.attrRefId == b.attrRefId then
            return a.attrType < b.attrType
        end
        return a.attrRefId < b.attrRefId
    end)

    return result
end

--那目前所有增发的增益状态
function ModelMagic:GetAllMagicBenefitInfo()
    if table.isempty(self._circleData) then
        return false
    end

    local result = {}
    for k, v in pairs(self._circleData) do
        local data = {}
        data.isActive = v:GetActive()
        if data.isActive then
            data.magicRefId = v:GetMagicRefId()
            data.level = v:GetLevel()
            table.insert(result, data)
        end
    end

    table.sort(result, function(a, b)
        return a.magicRefId < b.magicRefId
    end)

    return #result, result
end

function ModelMagic:GetBuffCfgByOriginIdAndLv(originRefId, lv)
    local lv = lv + 1

    local refId = self._buffOriginIdMagicCircleRefId[originRefId]

    local buffCfg = self._buffCfg[refId][lv]

    return buffCfg
end

function ModelMagic:GetCandleQualityTipsImgPath(quality, num)
    return string.format("magic_tips_%s%s", quality, num)
end

--根据传入的蜡烛的refId获取对应的表
function ModelMagic:GetMagicByCandleRefId(candleRefId)
    return self._magicCandleMapCircle[candleRefId]
end

--根据传入的蜡烛的id 判断能点亮第几个 是否被点亮
function ModelMagic:GetCandleCanLightMagicCircle(candleId, circleRefId)
    local result = 0
    local canLight = false
    --
    local cirCleRef = gModelMagic:GetMagicCircleRef(circleRefId)
    local count, cell = self:ParseCandleCell(cirCleRef.cell)

    local canLightCell = {}
    for k, v in pairs(cell) do
        if v.itemId == candleId then
            table.insert(canLightCell, k)
        end
    end

    table.sort(canLightCell, function(a, b)
        return a < b
    end)

    local circleData = gModelMagic:GetCircleData(circleRefId)

    if not circleData then
        canLight = true
        result = canLightCell[1]
        return canLight, result
    end

    local seat = circleData:GetSeat()
    local lightPos = {}

    for k, v in ipairs(seat) do
        for i, j in ipairs(canLightCell) do
            if v == j then
                lightPos[j] = true
            end
        end
    end

    for k, v in ipairs(canLightCell) do
        if not lightPos[v] then
            canLight = true
            result = v
            break
        end
    end

    --如果全点亮了 就返回第一个
    if result == 0 then
        canLight = false
        result = canLightCell[1]
    end
    return canLight, result
end

--从一组list seat 中的 转为 [seat]=true的形式
function ModelMagic:ConvertSeat(seat)
    local result = {}
    for k, v in ipairs(seat) do
        result[v] = true
    end

    return result
end

--获取能够用于升级的蜡烛
function ModelMagic:GetCanUpLvCandle()
    --local candleItems = gModelItem:GetItemListByType(gModelItem.TTEM_Tab_TYPE_CANDLE)
    local candleItems = gModelItem:GetItemTypeListByType_Convert(gModelItem.TTEM_TYPE_CANDLE)
    
    local result = {}
    for k, itemdata in ipairs(candleItems) do
        local isCanUp = true

        -- 获取下点亮还需要的部分
        --local leftNum = self:GetCanUpLvCandleNum(itemdata.itemId)
        local leftNum = self:GetCanUpLvCandleNum(itemdata.itemId)
        isCanUp = leftNum > 0

        
        if itemdata.itemId  ==3210011  then 
            printInfoN2("--","--")
        end 
        
        --遍历完使用情况
        if isCanUp then
            itemdata.itemNum = leftNum
            table.insert(result, itemdata)
        end
    end

    return result
end

--获取蜡烛可用于升级的数量
function ModelMagic:GetCanUpLvCandleNum(candleRefId)
    local haveNum = gModelItem:GetNumByRefId(candleRefId) or 0

    local candleLightNeedCount = checknumber(self._magicCandleTotalNeedCount[candleRefId]) - checknumber(self._candleData[candleRefId])
    local leftNum = haveNum - candleLightNeedCount

    return leftNum
end
--endregion --------------------------------------------------------------------------------------

--region check方法 --------------------------------------------------------------------------------
--能否升级阵法
function ModelMagic:CheckCanUpBuff(buffRefId)
    local isOpen = gModelFunctionOpen:CheckIsOpened(21008001, false)

    if not isOpen then
        return
    end

    local buffCfg = self:GetMagicBuffLvRef(buffRefId)
    if not buffCfg then
        printInfoN2("------MagicBuffLvRef---", "不存在refId" .. buffRefId)
        return
    end

    if buffCfg.next == -1 then
        printInfoN2("------MagicBuffLvRef---", "当前buff为满级")
        return
    end

    local need = string.split(buffCfg.upNeed, "=")
    local expItemId = checknumber(need[2])
    need = checknumber(need[3])

    local haveNum = gModelItem:GetNumByRefId(expItemId) or 0

    local candleItems = self:GetCanUpLvCandle()

    for k, itemdata in ipairs(candleItems) do
        --转换成经验道具
        local candleCfg = self:GetMagicRef(itemdata.itemId)

        if candleCfg then
            local exp = candleCfg.exp
            exp = string.split(exp, "=")
            exp = checknumber(exp[3])

            local changeNum = itemdata.itemNum * exp
            haveNum = haveNum + changeNum
        else

            printInfoNR2("--modelmagic-- candle cfg --not --itemId-- ", itemdata.itemId)
        end
    end

    return haveNum >= need,need-haveNum
end

function ModelMagic:CheckMagicTypeIsOpen(typeRefId)
    local typeCfg = self:GetMagicTypeRef(typeRefId)
    local playerLv = gModelPlayer:GetPlayerLv()
    local conditionLv = checknumber(typeCfg.lv)
    local conditionCollect = checknumber(typeCfg.collectionDegree)

    local isOpen = (playerLv >= conditionLv) and (self._collectionCode >= conditionCollect)

    --local str = string.replace(ccClientText(45728), conditionLv, conditionCollect)

    local str = ccLngText(typeCfg.desc)

    return isOpen, str
end

function ModelMagic:CheckCandleIdCanLightMagicCircle(candleRefId)
    local magicCircleRefIds = self:GetMagicByCandleRefId(candleRefId)
    local isNeed = false

    if not magicCircleRefIds then
        return isNeed
    end

    for k, itemdata in ipairs(magicCircleRefIds) do
        local magicCfg = gModelMagic:GetMagicCircleRef(itemdata)
        local typeRefId = magicCfg.type
        local isOpen = gModelMagic:CheckMagicTypeIsOpen(typeRefId)
        local canLight, pos
        if isOpen then
            --该阵法还需不需要这个蜡烛 是第几个位置
            canLight, pos = gModelMagic:GetCandleCanLightMagicCircle(candleRefId, magicCfg.refId)

            isNeed = canLight
        else
            isNeed = false
        end

        if isNeed then
            break
        end
    end

    return isNeed
end
--endregion --------------------------------------------------------------------------------------

--region 红点的检查 --------------------------------------------------------------------------------
--检查魔法阵是否有红点
function ModelMagic:CheckMagicCircleRedpoint(magicCircleRefId)
    local magicCfg = self:GetMagicCircleRef(magicCircleRefId)
    local isOpen = self:CheckMagicTypeIsOpen(magicCfg.type)

    --是否开启
    if not isOpen then
        return false
    end

    local count, cell = self:ParseCandleCell(magicCfg.cell)
    local circleData = self:GetCircleData(magicCircleRefId)

    if not circleData then
        --没有数据 check位置时候有道具 有则return true
        for k, v in pairs(cell) do
            local haveNum = gModelItem:GetNumByRefId(v.itemId)
            if haveNum >= v.itemNum then
                return true
            end
        end

        --遍历完 无可点亮
        return false
    end

    --有数据 判断是否激活了
    local isActive = circleData:GetActive()

    if not isActive then
        --未激活判断是否有剩余位置可以激活
        local seat = circleData:GetSeat()

        --判断下进度部分
        if #seat == count then
            return true
        end

        local posIsLightData = self:ConvertSeat(seat)
        for k, v in pairs(cell) do
            if posIsLightData[k] then
                --点亮了的不判断
            else
                local haveNum = gModelItem:GetNumByRefId(v.itemId)
                if haveNum >= v.itemNum then
                    return true
                end

            end
        end


        --无可点亮的
        return false
    else
        --判断是否可以升级     ModelMagic:CheckCanUpBuff(buffRefId)
        local lv = circleData:GetLevel()
        local buffCfg = self:GetBuffCfgByOriginIdAndLv(magicCfg.buff, lv)

        local isCan = self:CheckCanUpBuff(buffCfg.refId)

        return isCan
    end
end

--是否可收集
function ModelMagic:CheckCollectRedpoint()
    local collectData = self:GetMagicCollectionRef()
    local code, collectRefId = gModelMagic:GetCollectSchedule()
    for k, v in ipairs(collectData) do
        if collectRefId >= v.refId then

        else

            if code >= v.collectionDegree then
                return true
            end
        end


    end
end

--endregion --------------------------------------------------------------------------------------

----------------------------------------------------------------------------------------------------------------

return ModelMagic