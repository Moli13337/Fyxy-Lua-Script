---
--- 皮肤图鉴Model类
--- Created by Ease.
--- DateTime: 2023/10/26 10:50
---

local LModel = LModel

------------------------------------------------------------------
---@class ModelSkinBook:LModel
local ModelSkinBook = LxClass("ModelSkinBook", LModel)

ModelSkinBook.HeroSkinStarUpgradeRef = "HeroSkinStarUpgradeRef"

function ModelSkinBook:ModelSkinBook()
end


function ModelSkinBook:OnModelInit()
end

function ModelSkinBook:OnHeroSkinBookInfoReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.HeroSkinBookInfoReq)
    SendMessage(pb, LProtoIds.HeroSkinBookInfoReq)
end

function ModelSkinBook:OnHeroSkinPropertyListReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.HeroSkinPropertyListReq)
    SendMessage(pb, LProtoIds.HeroSkinPropertyListReq)
end

function ModelSkinBook:OnHeroSkinPropertyActiveReq(refId)
    local pb = LProtoHelper.CreateProto(LProtoIds.HeroSkinPropertyActiveReq)
    pb.refId = refId
    SendMessage(pb, LProtoIds.HeroSkinPropertyActiveReq)
end

function ModelSkinBook:OnAchievementListReq()
    local pb = LProtoHelper.CreateProto(LProtoIds.AchievementListReq)
    SendMessage(pb,LProtoIds.AchievementListReq)
end

function ModelSkinBook:OnSkinUpStarReq(SkinRefId)
    local pb = LProtoHelper.CreateProto(LProtoIds.HeroSkinUpStarReq)
    pb.refId = SkinRefId
    SendMessage(pb, LProtoIds.HeroSkinUpStarReq)
end

--在协议数据处理完之后需要调用finish
function ModelSkinBook:OnModelRequest()
    self:InitData()
    self:ModelFinish()
end

function ModelSkinBook:InitData()

end

function ModelSkinBook:GetHeroSkinTaskTypeBySkinRefId(skinRefId)
    local HeroSkinTaskRef = GameTable.HeroSkinTaskRef
    for i,v in pairs(HeroSkinTaskRef) do
        if v.Skin == skinRefId then
            return v.Type
        end
    end
    return nil
end

function ModelSkinBook:CheckShowSkinTaskRewardRedPoint(skinType)
    local taskList = self:GetSkinTaskLsitBySkinType(skinType)
    for i, v in ipairs(taskList) do
        local state = v:GetState()
        if state == 1 then
            return true
        end
    end
    return false
end

function ModelSkinBook:CheckGetAllRewardBySkinType(skinType)
    local taskList = self:GetSkinTaskLsitBySkinType(skinType)
    for i, v in ipairs(taskList) do
        local state = v:GetState()
        if state ~= 2 then
            return false
        end
    end
    return true
end



function ModelSkinBook:GetSkinTaskLsitBySkinType(skinType)
    local skinTaskRefIdLsit = {}
    local HeroSkinTaskRef = GameTable.HeroSkinTaskRef
    for i,v in pairs(HeroSkinTaskRef) do
        if v.Type == skinType then
            skinTaskRefIdLsit[v.FinishCond] = v
        end
    end
    local tempInfo = nil
    for i, v in pairs(skinTaskRefIdLsit) do
        if not tempInfo then
            tempInfo = v
        end
    end
    if not tempInfo then return {} end
    local tempTaskInfo = gModelQuest:GetTaskConfig(tempInfo.FinishCond)
    local taskType = tempTaskInfo.type
    local TaskInfoList = gModelQuest:GetTaskList(taskType)
    local skinTaskInfoList = {}
    local Skin
    ---@type V_CharacterEffectRef
    local heroEffectRef
    local curTime = GetTimestamp()
    for i, v in pairs(TaskInfoList) do
        local taskInfo = skinTaskRefIdLsit[v._refId]
        if taskInfo then
            Skin = taskInfo.Skin
            if Skin and Skin > 0 then
                heroEffectRef = gModelHero:GetShowEffectById(Skin)
                if heroEffectRef then
                    if gModelHero:GetHeroActShowState(heroEffectRef.heroType, curTime) then
                        table.insert(skinTaskInfoList,v)
                    end
                end
            end
        end
    end
    return skinTaskInfoList
end

function ModelSkinBook:GetSkinUpStarInfoBySkinRefId(SkinRefId)
    local value = {}
    local HeroSkinStarUpgradeRef = GameTable.HeroSkinStarUpgradeRef
    for i, v in pairs(HeroSkinStarUpgradeRef) do
        if v.Skin ==  SkinRefId then
            if v.lv == 1 then
                value = v
                return value
            end
        end
    end
    return value
end

function ModelSkinBook:GetSkinUpStarComsumeByRefId(refId)
    local value = self:GetCacheValueByKey(ModelSkinBook.HeroSkinStarUpgradeRef,refId,"Consume")
    if value then
        return value
    end
    local ref = self:GetSkinUpStarConfig(refId)
    if ref then
        value = LxDataHelper.ParseItem(ref.Consume)
        self:SetCacheValueByKey(ModelSkinBook.HeroSkinStarUpgradeRef,refId,"Consume",value)
    end
    return value
end



function ModelSkinBook:GetSkinUpStarConfig(refId)
    local ref = self:GetModelConfig(ModelSkinBook.HeroSkinStarUpgradeRef)
    local cfg = ref[refId]
    if not cfg then
        printInfoN(string.format("no cfg GameTable.HeroSkinStarUpgradeRef refId %s",refId))
    end
    return cfg
end


function ModelSkinBook:GetHeroSkinRef()
    return GameTable.CharacterSkinRef
end

function ModelSkinBook:GetHeroSkinPropertyRef()
    if not self._initHeroSkinPropertyRefList then
        local tmp = {}
        for i, v in pairs(GameTable.CharacterSkinPropertyRef) do
            table.insert(tmp, v)
        end
        table.sort(tmp, function(a, b)
            return a.need < b.need
        end)
        self._initHeroSkinPropertyRefList = tmp
    end
    return self._initHeroSkinPropertyRefList
end

function ModelSkinBook:CheckSkinBookAllRedPointStatus()
    local showSkinBookAllRP = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.REDPOINT_ID_10304000)
    return showSkinBookAllRP
end

--检测收集红点
function ModelSkinBook:CheckCollectRedPointStatus()
    local properRef = self:GetHeroSkinPropertyRef()
    local collectList = self:GetCollectDataList()
    local btnCnt = self:CheckItemtRedPointStatus(1, true)
    for i, v in pairs(properRef) do
        if (not collectList or table.isempty(collectList) or (collectList and not collectList[v.refId])) then
            if btnCnt and (btnCnt >= v.need) then
                return true
            end
        end
    end
    return false
end

--检测道具红点
function ModelSkinBook:CheckItemtRedPointStatus(btnType, getBtnCnt)
    local btnCtn = 0

    --type==1 return -- 屏蔽掉样式1的红点请求 
    if btnType == 1 then
        return
    end

    local refDataList = btnType == 1 and self:GetSkinBookHeroRef() or self:GetSkinBookSetsRef()
    local heroList = gModelHero:GetHeroList()
    for i, v in pairs(refDataList) do
        local skinIdList = self:GetOpenHeroSkinId(v.skinId)
        for idx, skinRefId in pairs(skinIdList) do
            local heroEffRef = gModelHero:GetShowEffectById(skinRefId)
            if heroEffRef then
                local hadSkin = gModelHero:CheckHeroHadSkin(skinRefId) --检测已激活
                local hasSkinItemId = gModelHero:GetEffectItemId(skinRefId)
                local hasHero = self:CheckPlayerHasHeroById(heroEffRef.heroType, heroList)
                if (hasSkinItemId and (not hadSkin or hadSkin ~= "-1") and hasHero) then
                    if (not getBtnCnt) then
                        btnCtn = btnCtn + 1
                    end
                elseif (getBtnCnt and hadSkin and hadSkin == "-1") then
                    btnCtn = btnCtn + 1
                end
            end
        end
    end
    if (btnCtn == 0 and not getBtnCnt) then
        return self:CheckRewardRedPointStatusByType(btnType)
    end
    return getBtnCnt and btnCtn or btnCtn > 0
end

function ModelSkinBook:CheckPlayerHasHeroById(refId, heroList)
    for i, v in pairs(heroList) do
        if not v:IsTryHero() then
            local heroRefId = v:GetRefId()
            if heroRefId == refId then
                return true
            end
        end
    end
end

function ModelSkinBook:CheckRewardRedPointStatusByType(refType)
    if refType == 1 then
        return
    end

    local refData = refType == 1 and self:GetSkinBookHeroRef() or self:GetSkinBookSetsRef()
    for i, v in pairs(refData) do
        local finishCond = string.split(v.finishCond, ",")
        for idx, val in ipairs(finishCond) do
            val = checknumber(val)
            local taskData = gModelQuest:GetTaskDataByRefId(val)
            local isTaskFinish = gModelQuest:IsTaskFinish(val)
            isTaskFinish = isTaskFinish and 2 or 0
            local taskState = taskData and taskData:GetState() or isTaskFinish
            if (taskState == 1) then
                return true
            end
        end
    end
end

function ModelSkinBook:SetCollectDataList(dataList)
    self._collectDataList = dataList
end
function ModelSkinBook:GetCollectDataList()
    return self._collectDataList
end

function ModelSkinBook:SetHeroBtnRPStatus(status)
    self._heroBtnRP = status
end
function ModelSkinBook:GetHeroBtnRPStatus()
    return self._heroBtnRP
end
function ModelSkinBook:SetSetsBtnRPStatus(status)
    self._setsBtnRP = status
end
function ModelSkinBook:GetSetsBtnRPStatus()
    return self._setsBtnRP
end

function ModelSkinBook:SetSkinBookHeroRef()
    local refData = self:GetHeroSkinRef()
    self._heroRef = {}
    if (refData) then
        for i, v in pairs(refData) do
            if v.type == 1 then
                table.insert(self._heroRef, v)
            end
        end
    end
end
function ModelSkinBook:GetSkinBookHeroRef()
    if (not self._heroRef or #self._heroRef == 0) then
        self:SetSkinBookHeroRef()
    end
    return self._heroRef
end
function ModelSkinBook:SetSkinBookSetsRef()
    local refData = self:GetHeroSkinRef()
    ---@type V_CharacterSkinRef[]
    self._setsRef = {}
    if (refData) then
        for i, v in pairs(refData) do
            if v.type == 2 then
                table.insert(self._setsRef, v)
            end
        end
    end
end
function ModelSkinBook:GetSkinBookSetsRef()
    if (not self._setsRef or #self._setsRef == 0) then
        self:SetSkinBookSetsRef()
    end
    ---@type V_CharacterSkinRef[]
    local list = {}
    for i,v in ipairs(self._setsRef) do
        local skinList = self:GetOpenHeroSkinId(v.skinId)
        if skinList and #skinList > 0 then
            table.insert(list,v)
        end
    end
    return list
end

--获取当前皮肤列表可领取奖励或可激活下标
function ModelSkinBook:GetSkinListActivityIndex(dataList)
    local itemIndex = 1
    local actIndex = 1
    for i, v in pairs(dataList) do
        local taskData = gModelQuest:GetTaskDataByRefId(v.finishCond)
        local isTaskFinish = gModelQuest:IsTaskFinish(v.finishCond)
        isTaskFinish = isTaskFinish and 2 or 0
        local taskState = taskData and taskData:GetState() or isTaskFinish
        if (taskState == 1) then
            itemIndex = i
            return itemIndex
        end
        if (actIndex == 1) then
            local skinIdList = self:GetOpenHeroSkinId(v.skinId)
            for index, skinRefId in ipairs(skinIdList) do
                local hasSkinItemId = gModelHero:GetEffectItemId(skinRefId)
                local skinEndTime = gModelHero:CheckHeroHadSkin(skinRefId) --检测已激活
                local hadSkin = skinEndTime and skinEndTime == "-1"
                if (hasSkinItemId and not hadSkin) then
                    actIndex = i
                    return actIndex
                end
            end
        end
    end
    return actIndex
end

--获取当前收集列表可激活下标
function ModelSkinBook:GetCollectListActivityIndex(dataList, collectDataList, curSkinCnt)
    local index = 1
    for i, v in pairs(dataList) do
        if (not collectDataList or not collectDataList[checknumber(v.refId)]) then
            if (curSkinCnt >= v.need) then
                return i
            end
        else
            index = i + 1
        end
    end
    return index
end

function ModelSkinBook:RaceType(type)
    if (type) then
        self._raceType = type
    else
        return self._raceType or 0
    end
end

function ModelSkinBook:CareerType(type)
    if (type) then
        self._careerType = type
    else
        return self._careerType or 0
    end
end

function ModelSkinBook:OpenRewardWnd(reward, finishSkinRewardInfo, itemdata)
    gModelQuest:OnQuestReceiveReqInternal({ itemdata.finishCond })
    local rewardList = {}
    local showUIAwardCntInfo
    local rewardArr = reward
    for i, v in pairs(rewardArr) do
        local data = {
            itype = v.itemType,
            itemId = v.itemId,
            count = v.itemNum,
        }
        table.insert(rewardList, data)
    end
    showUIAwardCntInfo, rewardList = self:GetUIAwardSowTxt(finishSkinRewardInfo, itemdata)
    if (showUIAwardCntInfo) then
        local popWndData = {
            itemList = rewardList,
            parameters = { "SKIN_BOOK", showUIAwardCntInfo.allCnt, showUIAwardCntInfo.oldCnt },
        }
        gModelWndPop:TryOpenPopWnd("UIAward", popWndData)
    else
        local rewardArr = string.split(itemdata.reward, "|")
        rewardList = {}
        local rewardCnt = 0
        for i, v in pairs(rewardArr) do
            local data = self:GetShowRewardList(v)
            rewardCnt = rewardCnt + data.count
            table.insert(rewardList, data)
        end
        local tmpData = rewardList[1]
        tmpData.count = rewardCnt
        local popWndData = {
            itemList = { tmpData },
        }
        gModelWndPop:TryOpenPopWnd("UIAward", popWndData)
    end
end

function ModelSkinBook:GetUIAwardSowTxt(finishSkinRewardInfo, itemData)
    if (finishSkinRewardInfo and finishSkinRewardInfo[itemData.refId]) then
        local rList = {}
        local oldRewards = {}
        local finshHeroIdListStr = finishSkinRewardInfo[itemData.refId]
        local finshHeroIdListArr = string.split(finshHeroIdListStr, ",")
        local heroIdList = {}
        for i, v in pairs(finshHeroIdListArr) do
            heroIdList[v] = 1
        end

        local skinIdList = self:GetOpenHeroSkinId(itemData.skinId)

        local rewardListArr = itemData.reward
        local rewardList = string.split(rewardListArr, "|")--所有奖励
        local newRewardCnt = 0
        for i, v in ipairs(skinIdList) do
            v = tostring(v)
            local rewardInfo = rewardList[i]
            if (heroIdList[v]) then
                oldRewards[v] = rewardInfo--已领取奖励
            else
                local data = self:GetShowRewardList(rewardInfo)
                newRewardCnt = newRewardCnt + data.count
                data.count = newRewardCnt
                rList = { data }
            end
        end
        local oldRewardCnt = self:GetShowRewardCnt(oldRewards)
        local allRewardCnt = self:GetShowRewardCnt(rewardList)

        return { oldCnt = oldRewardCnt, allCnt = allRewardCnt }, rList
    end
end
function ModelSkinBook:GetShowRewardList(reward)
    local infoArr = string.split(reward, "=")
    local data = {
        itype = checknumber(infoArr[1]),
        itemId = checknumber(infoArr[2]),
        count = checknumber(infoArr[3]),
    }
    return data
end
--获得弹框领取钻石数量
function ModelSkinBook:GetShowRewardCnt(rewardList)
    local cnt = 0
    for i, v in pairs(rewardList) do
        local arr = string.split(v, "=")
        cnt = cnt + checknumber(arr[3])
    end
    return cnt
end
function ModelSkinBook:SetFinishRewardInfo(heroSkinBookInfo)
    local info = heroSkinBookInfo.info
    if (info) then
        local finishSkinIdInfo = info.finishSkinIdInfo
        if (finishSkinIdInfo) then
            local finishSkinRewardInfo = {}
            for i, v in pairs(finishSkinIdInfo) do
                if (v.refId) then
                    finishSkinRewardInfo[v.refId] = v.heroIds
                end
            end
            return finishSkinRewardInfo
        end
    end
end

--获取当前的套装收集的奖励
function ModelSkinBook:GetCollectRewardByRefid(refid)
    local heroSkinRef = self:GetHeroSkinRef()
    
    if not heroSkinRef[refid] then
        if LOG_INFO_ENABLED then
            printInfoN2("cjh--------", refid .. "GameTable.CharacterSkinRef--任务配置丢失奖励配置--皮肤部分")
        end
        return
    end
    
    local cfgReward = heroSkinRef[refid].finishCond
    local quests = string.split(cfgReward, ",")
    local allrewards = {}
    for k, v in ipairs(quests) do
        printInfoN2("cjh--------", v)
        local rewards = gModelQuest:GetQuestRewardByRefId(checknumber(v))
        if rewards then
            for index, reward in ipairs(rewards) do
                if allrewards[reward.itemId] then
                    allrewards[reward.itemId].itemNum = allrewards[reward.itemId].itemNum + reward.itemNum
                else
                    allrewards[reward.itemId] = reward
                end
            end
        else
            if LOG_INFO_ENABLED then
                printInfoN2("cjh--------", v .. "任务配置丢失奖励配置")
            end
        end

    end
    return allrewards
end

--新增一个接口
function ModelSkinBook:GetCollectRewardByRefid_New(refid)
    local heroSkinRef = self:GetHeroSkinRef()

    if not heroSkinRef[refid] then
        if LOG_INFO_ENABLED then
            printInfoN2("cjh--------", refid .. "GameTable.CharacterSkinRef--任务配置丢失奖励配置--皮肤部分")
        end
        return
    end

    local cfgReward = heroSkinRef[refid].finishCond
    local quests = string.split(cfgReward, ",")
    local allrewards = {}
    for k, v in ipairs(quests) do

        local rewards = gModelQuest:GetQuestRewardByRefId(checknumber(v))
        if rewards then
    
            local data={quest= checknumber(v),rewards=rewards}
            
            table.insert(allrewards,data)
        else
            if LOG_INFO_ENABLED then
                printInfoN2("cjh--------", v .. "任务配置丢失奖励配置")
            end
        end
  
    end
    return allrewards
end


--获取当前的套装对应index的奖励
function ModelSkinBook:GetCollectRewardAndQuestByRefidAndIndex(refid, index)
    local heroSkinRef = self:GetHeroSkinRef()
    local cfgReward = heroSkinRef[refid].finishCond

    local quests = string.split(cfgReward, ",")
    local quest = quests[index]
    local allrewards = {}

    local rewards = gModelQuest:GetQuestRewardByRefId(checknumber(quest))
    if rewards then
        for index, reward in ipairs(rewards) do
            if allrewards[reward.itemId] then
                allrewards[reward.itemId].itemNum = allrewards[reward.itemId].itemNum + reward.itemNum
            else
                allrewards[reward.itemId] = reward
            end
        end
    else
        if LOG_INFO_ENABLED then
            printInfoN2("cjh--------", quest .. "任务配置丢失奖励配置")
        end
    end

    return allrewards, quest
end

function ModelSkinBook:GetTaskState(questId)
    local taskData = gModelQuest:GetTaskDataByRefId(questId)

    if questId== 371002 then
        printInfoN2("---","---371002")
    end  
    
    if taskData then
        return taskData:GetState()
    end

end

function ModelSkinBook:FinishSkinTask(questId)
    local refIds = {}
    table.insert(refIds, questId)
    gModelQuest:OnQuestReceiveReqInternal(refIds)
end

function ModelSkinBook:InitQuestIdsAndIndexBySkinId()
    local heroSkinRef = self:GetHeroSkinRef()

    self._skinQuestIDs = { }
    for k, v in pairs(heroSkinRef) do
        local cfgReward = v.finishCond
        local quests = string.split(cfgReward, ",")
        local skinIds = self:GetOpenHeroSkinId(v.skinId)
        for index, skinId in ipairs(skinIds) do
            local data = {}
            data.questId = checknumber(quests[index])
            data.index = index
            data.heroSkinRef = v
            self._skinQuestIDs[skinId] = data
        end
    end
end

function ModelSkinBook:GetQuestIdBySkinId(skinId)

    if self._skinQuestIDs == nil then
        self:InitQuestIdsAndIndexBySkinId()
    end

    return self._skinQuestIDs[skinId]
end



function ModelSkinBook:GetParseSkinBookSetsRef()
    if not self._parseSkinBookSetsList then
        local parseSkinBookSetsList = {}
        local sets = self:GetSkinBookSetsRef()
        local skinList
        for k,v in pairs(sets) do
            skinList = self:GetOpenHeroSkinId(v.skinId)
            if #skinList > 0 then
                local skins = {}
                for idx,val in ipairs(skinList) do
                    table.insert(skins,val)
                end
                parseSkinBookSetsList[k] = skins
            end
        end
        self._parseSkinBookSetsList = parseSkinBookSetsList
    end
    return self._parseSkinBookSetsList
end

function ModelSkinBook:CalcCurSkinCnt()
    --收集加成
    local curSkinCnt = 0
    local playerSkinList = gModelHero:GetHeroSkinList()
    local heroList
    local skinData
    local initParseSkinBookList = self:GetParseSkinBookSetsRef()
    for k,skins in pairs(initParseSkinBookList) do
        for i,skinId in ipairs(skins) do
            heroList = gModelHero:GetServerHeroListByRefId(skinId) or {}
            skinData = playerSkinList[skinId]
            if skinData and skinData.endTime == "-1" or #heroList > 0 then
                curSkinCnt = curSkinCnt + 1
            end
        end
    end
    return curSkinCnt
end


function ModelSkinBook:CheckCollectActRedPointStatus()
    if not self._collectDataList then return false end

    --收集加成
    local curSkinCnt = self:CalcCurSkinCnt()

    local collectDataList = self._collectDataList

    local properRef = self:GetHeroSkinPropertyRef()
    for i,v in ipairs(properRef) do
        if not collectDataList[v.refId] and curSkinCnt >= v.need then
            return true
        end
    end
    return false
end


function ModelSkinBook:CheckHasSkinCanUpStar()
    local HeroSkinList = gModelHero:GetHeroSkinList()
    for i, v in pairs(HeroSkinList) do
        if v.starLevel < 5 then
            local Comsume = self:GetSkinUpStarComsumeByRefId(v.starRefId)
            if Comsume then
                local first = Comsume[1]
                local haveNum = gModelItem:GetNumByRefId(ModelItem.ITEM_SKIN_DEBRIS) -- 皮肤碎片
                if haveNum >= first.itemNum then
                    return true
                end
            end
        end
    end
    return false
end

function ModelSkinBook:CheckTimeWearActRedPointStatus()
    local showCollectRP = self:CheckCollectActRedPointStatus()
    if showCollectRP then
        return true
    end

    local skinTaskList = gModelQuest:GetTaskList(ModelQuest.TYPE_152)
    for i, v in ipairs(skinTaskList) do
        local state = v:GetState()
        if state == 1 then
            return true
        end
    end

    if self:CheckHasSkinCanUpStar() then
        return true
    end

    local skinBookList = self:GetSkinBookSetsRef()
    for i, v in ipairs(skinBookList) do
        local skinIdList = self:GetOpenHeroSkinId(v.skinId)
        for n, skinRefId in ipairs(skinIdList) do
            local skinEndTime = gModelHero:CheckHeroHadSkin(skinRefId) --检测已激活
            local hadSkin = skinEndTime and skinEndTime == "-1"
            local hasSkinItemId = gModelHero:GetEffectItemId(skinRefId)
            if hasSkinItemId and not hadSkin then
                return true
            end
        end
    end
    return false
end


function ModelSkinBook:GetOpenHeroSkinId(skinId)
    if string.isempty(skinId) then return {} end
    local showHeroSkinIds = {}
    local skinIds = self:GetParaSkinId(skinId)
    for i,v in ipairs(skinIds) do
        local heroEffectRef = gModelHero:GetShowEffectById(v)
        if heroEffectRef and gModelHero:GetHeroActShowState(heroEffectRef.heroType) then
            table.insert(showHeroSkinIds,v)
        end
    end
    return showHeroSkinIds
end

---@param skinId string
function ModelSkinBook:GetParaSkinId(skinId)
    if string.isempty(skinId) then return {} end
    if not self._paraSkinIdMap then
        self._paraSkinIdMap = {}
    end
    local paraSkinIds = self._paraSkinIdMap[skinId]
    if not paraSkinIds then
        paraSkinIds = {}
        local skinIds = string.split(skinId,",")
        for i,v in ipairs(skinIds) do
            table.insert(paraSkinIds,checknumber(v))
        end
        self._paraSkinIdMap[skinId] = paraSkinIds
    end
    return paraSkinIds
end

return ModelSkinBook