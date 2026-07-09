---
--- Created by.
--- DateTime: 2023/10/23 16:08:08
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIEmFight:LWnd
local UIEmFight = LxWndClass("UIEmFight", LWnd)
local YXTouchManager = CS.YXTouchManager

UIEmFight.TYPE_LAYERBATTLE_SINGLE = 1       --- 单阵容
UIEmFight.TYPE_LAYERBATTLE_MULTI = 2        --- 多阵容

UIEmFight.TYPE_OPTHERO_DOWN = 0             --- 下阵
UIEmFight.TYPE_OPTHERO_UP = 1               --- 上阵

UIEmFight.TYPE_BATTLE_SAVEFORMATION = 1     --- 保存阵型
UIEmFight.TYPE_BATTLE_GOTOCHALLENGE = 2     --- 前往战斗

UIEmFight.HERO_NUM = 5

UIEmFight.TYPE_TOGGLE_STATUS_NOTSEL = 0       --- toggle 未选中
UIEmFight.TYPE_TOGGLE_STATUS_SEL = 1          --- toggle 选中


------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIEmFight:UIEmFight()
    self:SetHideHurdle()
    self:SetHideTop()
    self:SetHideBottom()
    FireEvent(EventNames.ON_CHAT_SHOW,false)

    self._fairCompeteTimerKey = "fairCompeteTimerKey"


    self._mapOffset = -2 				-- 场景摄像机偏移位置
    self._showCombatSpiritHeroStatus = false
    self._showFormation = false
    self._heroType = UIHeroRaceList.ALL_RACE_REFID
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIEmFight:OnWndClose()
    FireEvent(EventNames.BATTLE_MAP_OFFSET,0)
    FireEvent(EventNames.ON_CHAT_SHOW,true)

    if gLGameTouch then gLGameTouch:TouchUnRegister(LGameTouch.TOUCH_UI) end

	LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIEmFight:OnCreate()
	LWnd.OnCreate(self)
    self:SetWndSwitchType(LWnd.SWITCH_TYPE_CHANGE_BTN)
	return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIEmFight:OnStart()
	LWnd.OnStart(self)
	self:InitUI()
	self:InitTouchEvent()
    self:InitText()
    self:InitStaticData()
	self:InitEvent()
	self:InitMsg()

    local exceptWnds = {
        ["UIEmFight"] = true,
        ["UIGuePost"] = true,
        -- ["UIActFairCompeteReset"] = true,
    }
    gLGameUI:CloseAllButExcept(exceptWnds)

    self:InitData()
    self:ViewShow()
end

function UIEmFight:GetBattleTeamDataMap()
    local battleTeamDataMap = self._battleTeamDataMap
    if not battleTeamDataMap then
        self:InitBattleTeamDataMap()
        battleTeamDataMap = self._battleTeamDataMap
    end
    return battleTeamDataMap
end

-- function UIEmFight:GetFairCompeteLoseTime()
--     local sid = self._sid
--     if not sid then return false end

--     local isNeedCD = gModelFairCompete:GetFairCompeteDataInfoIsNeedCDBySid(sid)
--     if not isNeedCD then return false end

--     local resetTime = gModelFairCompete:GetFairCompeteDataInfoResetTimeBySid(sid)
--     local curTime = GetTimestamp()
--     local loseTime = math.ceil(resetTime - curTime)
--     local status = loseTime > 0
--     return status,loseTime
-- end

-- function UIEmFight:OnFairCompeteTimer()
--     local status,loseTime = self:GetFairCompeteLoseTime()
--     if not status then
--         self:TimerStop(self._fairCompeteTimerKey)
--         CS.ShowObject(self.mActivityReSetGameCDBg,false)
--         return
--     end
--     if loseTime > 0 then
--         self:SetWndText(self.mActivityReSetGameCDTxt,loseTime)
--         CS.ShowObject(self.mActivityReSetGameCDBg,true)
--     else
--         self:TimerStop(self._fairCompeteTimerKey)
--         CS.ShowObject(self.mActivityReSetGameCDBg,false)
--         return
--     end
-- end

function UIEmFight:OnTimer(key)
    -- if key == self._fairCompeteTimerKey then
    --     self:OnFairCompeteTimer()
    -- end
end

function UIEmFight:RefreshBotToggleSelStatus(showBotToggleInfo)
    local isSel = self:GetBotToggleIsSel(showBotToggleInfo)
    CS.ShowObject(self.mMainBotToggleSelGou,isSel)
end

function UIEmFight:OnClickMainBotToggleBtnFunc()
    local showBotToggleInfo = self:GetBotToggleInfo()
    if not showBotToggleInfo then return end

    local limitFunc = showBotToggleInfo.limitFunc
    if limitFunc and limitFunc() then return end

    local toggleClickFunc = showBotToggleInfo.toggleClickFunc
    if not toggleClickFunc then
        if LOG_INFO_ENABLED then
            printInfoNR("toggleClickFunc 函数未添加相关配置")
        end
        return
    end
    toggleClickFunc()
end

function UIEmFight:OnClickFormationCellFunc(itemdata)
    local isSel = self:CheckFormationTypeIsSel(itemdata)
    if isSel then return end
    local refId = itemdata.refId
    self:SetArrayIdByIndex(itemdata.refId,self._curTeam)
    self:InitFormationList()
end

-- function UIEmFight:InitActivityStarList(list)
--     local uiActivityStarList = self._uiActivityStarList
--     if uiActivityStarList then
--         uiActivityStarList:RefreshList(list)
--     else
--         uiActivityStarList = self:GetUIScroll("uiActivityStarList")
--         self._uiActivityStarList = uiActivityStarList
--         uiActivityStarList:Create(self.mActivityStarList,list,function(...) self:OnDrawActivityStarCell(...) end)
--     end
-- end

-- function UIEmFight:OnDrawActivityStarCell(list,item,itemdata,itempos)
--     local NoActStarTrans = self:FindWndTrans(item,"NoActStar")
--     local ActStarTrans = self:FindWndTrans(item,"ActStar")

--     local isAct = itemdata.isAct
--     local showBox = itemdata.showBox
--     local showActStar,showNoActStar = false,false
--     if not showBox then
--         showNoActStar = not isAct
--         showActStar = isAct
--     end
--     CS.ShowObject(NoActStarTrans,showNoActStar)
--     CS.ShowObject(ActStarTrans,showActStar)

--     local BoxRootTrans = self:FindWndTrans(item,"BoxRoot")
--     if showBox then
--         local BoxSpRootTrans = self:FindWndTrans(BoxRootTrans,"BoxSpRoot")
--         local BoxEffRootTrans = self:FindWndTrans(BoxRootTrans,"BoxEffRoot")
--         local BoxIconTrans = self:FindWndTrans(BoxRootTrans,"BoxIcon")
--         local BoxNumrans = self:FindWndTrans(BoxRootTrans,"BoxNum")
--         local PointTrans = self:FindWndTrans(BoxRootTrans,"Point")

--         local rewardEff = self._rewardEff or {}

--         local useEffShow = #rewardEff > 0

--         local BoxEff = self._BoxEff
--         local effRootKey = BoxEffRootTrans:GetInstanceID()

--         local winNum = itemdata.winNum
--         local boxData = itemdata.boxData
--         local showBoxIcon = true
--         local showRewardEff = false
--         local showBoxEff = false
--         local haveList,finishList,hasGetList = self:GetActivityFairCompeteInfoList(itemdata)
--         local needShowEff = #finishList > 0

--         --- 完成使用特效的形式配置
--         local useSpecialShow = false
--         if useEffShow then
-- --[[            #胜场宝箱特效：去掉treasureImage1和treasureImage2，只通过rewardEff取待机和可领状态
--             ——#不可领和已领取显示为：idle
--             ——#已领取显示为：show]]
--             local effInfo = rewardEff[winNum]
--             if effInfo then
--                 useSpecialShow = true
--                 local showAniName = needShowEff and "show" or "idle"
--                 self:CreateActivitySpecialShow({
--                     showStr = effInfo,
--                     rewardEffKey = effRootKey,
--                     effectRoot = BoxEffRootTrans,
--                     spineRoot = BoxEffRootTrans,
--                     showAniName = showAniName,
--                     callBack = function()
--                         if not self:IsWndValid() then return end
--                         CS.ShowObject(BoxEffRootTrans,true)
--                     end,
--                 })
--                 CS.ShowObject(BoxIconTrans,false)
--             end
--         end
--         if not useSpecialShow then
--             if needShowEff then
--                 showBoxIcon = false
--                 if rewardEff then
--                     local effName = rewardEff[winNum]
--                     if effName then
--                         if LOG_INFO_ENABLED then
--                             printInfoNR("可领取特效 effName = " .. effName)
--                         end
--                         showRewardEff = true
--                         local rewardEffKey = effRootKey .. "_" .. effName
--                         self:DestroyWndEffectByKey(rewardEffKey)
--                         self:CreateWndEffect(BoxEffRootTrans,effName,rewardEffKey,90,false,false)
--                     end
--                 end
--                 if BoxEff then
--                     showBoxEff = true
--                     local BoxEffKey = effRootKey .. "_" .. BoxEff
--                     self:DestroyWndEffectByKey(BoxEffKey)
--                     self:CreateWndEffect(BoxEffRootTrans,BoxEff,BoxEffKey,90,false,false)
--                 end
--             end

--             CS.ShowObject(BoxSpRootTrans,false)
--             CS.ShowObject(BoxEffRootTrans,needShowEff)

--             if showBoxIcon then
--                 local entryList = boxData.entryList or {}
--                 local allLen = #entryList
--                 local hasLen = #hasGetList
--                 local imgList
--                 if hasLen >= allLen then
--                     imgList = self._treasureImage2
--                 else
--                     imgList = self._treasureImage1
--                 end
--                 if imgList then
--                     local img = imgList[winNum]
--                     if img then
--                         self:SetWndEasyImage(BoxIconTrans,img)

--                         if LOG_INFO_ENABLED then
--                             if hasLen >= allLen then
--                                 printInfoNR("已领取 treasureImage2 img = " .. img)
--                             else
--                                 printInfoNR("不可领取 treasureImage1 img = " .. img)
--                             end
--                         end
--                     end
--                 end
--             end
--             CS.ShowObject(BoxIconTrans,showBoxIcon)
--         end

--         local allNum = boxData.allNum
--         local finishNum = allNum - boxData.finishNum
--         local isFull = finishNum > 0
--         local textStr = isFull and ccClientText(37549) or ccClientText(37550)
--         textStr = string.replace(textStr,finishNum,allNum)
--         self:SetWndText(BoxNumrans,textStr)

--         -- self:SetWndClick(BoxRootTrans,function()
--         --     self:OnClickActivityStarBoxFunc(itemdata,PointTrans)
--         -- end)
--     end
--     CS.ShowObject(BoxRootTrans,showBox)
-- end

-- function UIEmFight:GetActivityFairCompeteInfoList(itemdata)
--     local showBox = itemdata.showBox
--     if not showBox then return {},{},{} end
--     local boxData = itemdata.boxData or {}
--     local entryList = boxData.entryList or {}
--     if #entryList < 1 then return {},{},{} end
--     local haveList = {}
--     local finishList = {}
--     local hasGetList = {}
--     for i,v in ipairs(entryList) do
--         if v.status == ModelActivity.REWARD_STATUE_HAD_GET then
--             table.insert(hasGetList,v)
--         elseif v.status == ModelActivity.REWARD_STATUE_CAN_GET then
--             table.insert(finishList,v)
--         else
--             table.insert(haveList,v)
--         end
--     end
--     return haveList,finishList,hasGetList,boxData
-- end

-- function UIEmFight:OnClickActivityStarBoxFunc(itemdata,BoxRootTrans)
--     local showBox = itemdata.showBox
--     if not showBox then return end
--     local haveList,finishList,hasGetList,boxData = self:GetActivityFairCompeteInfoList(itemdata)
--     if #finishList > 0 then
--         local first = finishList[1]
--         gModelActivity:OnActivityReceiveGoalReq(self._sid,first.pageId,first.entryId)
--         return
--     end
--     local winNum = itemdata.winNum
--     local offsetX = 0.12
--     if winNum == 1 then
--         offsetX = 0.13
--     elseif winNum == 3 then
--         offsetX = 0.13
--     end
--     local offsetY = -0.1
--     if #haveList > 0 then
--         local first = haveList[1]
--         local allNum = boxData.allNum
--         local finishNum = allNum - boxData.finishNum
--         local isFull = finishNum > 0
--         local textStr = isFull and ccClientText(37549) or ccClientText(37550)
--         textStr = string.replace(textStr,finishNum,allNum)
--         local desc = string.replace(ccClientText(37551),first.name,textStr)
--         local boxRootPos = BoxRootTrans.position
--         local offsetPos = Vector3(boxRootPos.x - offsetX,boxRootPos.y + offsetY,boxRootPos.z)
--         gModelFairCompete:OpenActivityFairCompeteRewardTip({
--             itemInfo = first.items[1],
--             desc = desc,
--             offsetPos = offsetPos,
--         })
--         return
--     end

--     local entryList = boxData.entryList or {}

-- --[[    local itemMap = {}
--     for i,v in ipairs(entryList) do
--         gModelFairCompete:DisposeItemList2ItemMap(itemMap,v.items)
--     end
--     local itemList = gModelFairCompete:DisposeItemMap2ItemList(itemMap)
--     gModelFairCompete:OpenActivityFairCompeteReward({
--         pageId = boxData.pageId,
--         itemList = itemList,
--     })]]

--     local lastInfo = entryList[#entryList]
--     if not lastInfo then return end

--     local boxRootPos = BoxRootTrans.position
--     local offsetPos = Vector3(boxRootPos.x - offsetX,boxRootPos.y + offsetY,boxRootPos.z)
--     local textStr = string.replace(ccClientText(37550),0,#entryList)
--     local desc = string.replace(ccClientText(37551),lastInfo.name,textStr)
--     gModelFairCompete:OpenActivityFairCompeteRewardTip({
--         itemInfo = lastInfo.items[1],
--         desc = desc,
--         offsetPos = offsetPos,
--     })
-- end

function UIEmFight:InitTreasureSkillList(trans,treasureSkilIds)
    local list = {}
    for i = 1,4 do
        local data = treasureSkilIds[i] or 0
        table.insert(list,{
            refId = data,
            index = i,
        })
    end
    local skillListTrans =self:FindWndTrans(trans,"skillList")
    local key = skillListTrans:GetInstanceID()
    local uiList = self:FindUIScroll(key)
    if uiList then
        uiList:RefreshList(list)
    else
        uiList = self:GetUIScroll(key)
        uiList:Create(skillListTrans,list,function(...) self:OnDrawSkillInfoCell(...) end)
    end
end

function UIEmFight:GetActivityDataList()
    return self._activityDataList or {}
end

function UIEmFight:InitData()
    --- 必选英雄
    self._requiredHeroMap = {}

    self._extraData = self:GetWndArg("extraData")
    self:DisposeExtraData()

    local isTreasureUse = not gModelFormation:CheckTreasureNotUse(self._combatType)
    CS.ShowObject(self.mActiveSkillsBtnDiv,isTreasureUse)
    CS.ShowObject(self.mPassiveSkillsBtnDiv,isTreasureUse)

    self:InitBattleTeamDataMap()

    --- 只会影响界面的显示，不影响数据方面
    local layerBattleType = self:GetWndArg("layerBattleType") or UIEmFight.TYPE_LAYERBATTLE_SINGLE
    self._layerBattleType = layerBattleType

    --不用弹宝物提示弹窗
    self._noNeedAskTreasure = {}
end

function UIEmFight:GetIdPosByIdAndIndex(id,index)
    local idToIndex = self:GetIdToIndexByIndex(index)
    return idToIndex[id]
end

function UIEmFight:OnClickBtnTeamMirrorAFunc()
end

function UIEmFight:InitUIShow(bShow, aniTime)
    local offsetY = -500
    local bottomTrans = self.mMainBattleBot

    if not self._bottomUIOrgPos then
        self._bottomUIOrgPos = bottomTrans.localPosition
    end
    aniTime = aniTime or 0
    local bottomPos = self._bottomUIOrgPos:Clone()
    if not bShow then
        bottomPos.y = bottomPos.y + offsetY
        FireEvent(EventNames.BATTLE_MAP_OFFSET,0)
        return
    else
        FireEvent(EventNames.BATTLE_MAP_OFFSET,self._mapOffset,0.4,true)
    end
end

function UIEmFight:OnSwapHeroInfo(index1,index2)
    local index = self._curTeam
    local indexToId = self:GetIndexToIdByIndex(index)
    local id1 = indexToId[index1]
    local id2 = indexToId[index2]

    local swapInfo1 = {
        id = id1,
        index = index1,
    }
    local swapInfo2 = {
        id = id2,
        index = index2,
    }
    self:SetSwapIdAndIndex(swapInfo1,swapInfo2)
end

function UIEmFight:GetNoShowRaceList()
    local heroRaceRefIdList = {}
    heroRaceRefIdList[UIHeroRaceList.ALL_RACE_REFID] = UIHeroRaceList.ALL_RACE_REFID
    for k,v in pairs(GameTable.CharacterRaceRef) do
        heroRaceRefIdList[k] = k
    end
    local list = {}
    local race = self._race
    if race then
        local raceArr = string.split(race,";")
        local raceLimitMap = {}
        for i, v in ipairs(raceArr) do
            raceLimitMap[tonumber(v)] = v
        end
        self._raceKeyList = raceLimitMap
        for k,v in pairs(heroRaceRefIdList) do
            if not raceLimitMap[k] and k ~= UIHeroRaceList.ALL_RACE_REFID then
                list[k] = k
            end
        end
    end
    if self._combatType and self._raceKeyList then
        self._showCombatSpiritHeroStatus = gModelFormation:CheckCombatShowSpiritHero(self._combatType)
        if self._showCombatSpiritHeroStatus then
            if list[ModelSpiritHero.SPIRITHERO_RACE] then
                list[ModelSpiritHero.SPIRITHERO_RACE] = nil
            end
            self._raceKeyList[ModelSpiritHero.SPIRITHERO_RACE] = tostring(ModelSpiritHero.SPIRITHERO_RACE)
        end
    end
    return list
end

function UIEmFight:GetBotToggleStatus()
    local showBotToggleInfo = self:GetBotToggleInfo()
    if not showBotToggleInfo then return end
    return showBotToggleInfo.status
end

function UIEmFight:OpenSelBattleTreasure(para)
    GF.OpenWnd("UISelFightTsure",para)
end

function UIEmFight:CheckCurCombatTypeBotToggleIsSel()
    local showBotToggleInfo = self:GetBotToggleInfo()
    if not showBotToggleInfo then return false end
    return self:GetBotToggleIsSel(showBotToggleInfo)
end

function UIEmFight:RefreshLayerTypeView()
    -- local layerBattleType = self._layerBattleType or UIEmFight.TYPE_LAYERBATTLE_SINGLE
    -- if layerBattleType == UIEmFight.TYPE_LAYERBATTLE_SINGLE then
    --     self:RefreshSingleView()
    -- elseif layerBattleType == UIEmFight.TYPE_LAYERBATTLE_MULTI then
        self:RefreshMultiView()
    -- end
end

function UIEmFight:CheckFormationTypeIsSel(itemdata)
    local arrayId = self:GetArrayIdByIndex(self._curTeam)
    local refId = itemdata.refId
    return arrayId == refId
end

--- 设置阵容
function UIEmFight:SetArrayIdByIndex(arrayId,index)
    local battleTeamData = self:GetBattleTeamFormationDataByIndex(index)
    battleTeamData.arrayId = arrayId
    self:RefreshFormationIcon()
end

-- function UIEmFight:RefreshCombatType33Formation()
--     local formationData = gModelFairCompete:GetSidFormationData(self._sid)
--     if not formationData then return false end

--     local teamIndex = formationData.teamIndex
--     self._curTeam = teamIndex

--     local formationRefId = formationData.formationRefId
--     self:SetArrayIdByIndex(formationRefId,teamIndex)

--     local matrix = gModelFormation:GetFormationPosByRefId(formationRefId)
--     local matrixToIndex = {}
--     for k,v in pairs(matrix) do
--         matrixToIndex[v] = k
--     end
--     local oldCnt = 0
--     local idToIndex = self:GetIdToIndexByIndex(teamIndex)
--     local indexToId = self:GetIndexToIdByIndex(teamIndex)
--     local isEmptySave = true
--     local pos
--     local recordIdToIndex = {}
--     local recordIndexToId = {}
--     for k,v in pairs(idToIndex) do
--         if isEmptySave then
--             isEmptySave = false
--         end
--         pos = matrix[v]
--         recordIdToIndex[k] = pos
--         recordIndexToId[pos] = k
--         oldCnt = oldCnt + 1
--     end

--     local newIdToIndex = {}
--     local newIndexToId = {}
--     local grid,id
--     local cnt = 0
--     local gridNum = 0
--     local grids = formationData.grids or {}
-- --[[    for k,v in pairs(grids) do
--         --- 排除一遍已经上阵的，并且更新位置修改的
--         grid = v.grid
--         id = v.id
--         tempPos = recordIdToIndex[id]
--         if tempPos then
--             newIdToIndex[id] = tempPos
--             newIndexToId[tempPos] = id
--         else
--             pos = matrixToIndex[grid]
--             tempPos = recordIndexToId[pos]
--             if tempPos then
--                 newIdToIndex[id] = tempPos
--                 newIndexToId[tempPos] = id
--             else
--                 newIdToIndex[id] = pos
--                 newIndexToId[pos] = id
--             end
--         end
--         cnt = cnt + 1
--         gridNum = gridNum + 1
--     end]]

--     if isEmptySave then
--         for k,v in pairs(grids) do
--             --- 排除一遍已经上阵的，并且更新位置修改的
--             grid = v.grid
--             id = v.id
--             pos = matrixToIndex[grid]
--             newIdToIndex[id] = pos
--             newIndexToId[pos] = id
--             cnt = cnt + 1
--             gridNum = gridNum + 1
--         end
--     else
--         for k,v in pairs(recordIdToIndex) do
--             pos = matrixToIndex[v]
--             newIdToIndex[k] = pos
--             newIndexToId[pos] = k
--             cnt = cnt + 1
--             gridNum = gridNum + 1
--         end
--     end

-- --[[    if gridNum < ModelFairCompete.BATTLE_NUM then
--         for k,v in pairs(grids) do
--             id = v.id
--             if not newIdToIndex[id] then
--                 grid = v.grid
--                 pos = matrixToIndex[grid]
--                 if newIndexToId[pos] then
--                     local isHavePos = false
--                     for idx = 1,ModelFairCompete.BATTLE_NUM do
--                         if not newIndexToId[idx] then
--                             newIdToIndex[id] = idx
--                             newIndexToId[idx] = id
--                             isHavePos = true
--                             break
--                         end
--                     end
--                     if isHavePos then
--                         cnt = cnt + 1
--                         gridNum = gridNum + 1
--                     end
--                 else
--                     newIdToIndex[id] = pos
--                     newIndexToId[pos] = id
--                     cnt = cnt + 1
--                     gridNum = gridNum + 1
--                 end
--             end
--         end
--     end]]

--     if gridNum < oldCnt then
--         for recordId,recordIdx in pairs(recordIdToIndex) do
--             if not newIdToIndex[recordId] then
--                 newIdToIndex[recordId] = recordIdx
--                 newIndexToId[recordIdx] = recordId
--                 cnt = cnt + 1
--                 gridNum = gridNum + 1
--             end
--         end
--     end

--     local battleTeamData = self:GetBattleTeamFormationDataByIndex(teamIndex)
--     battleTeamData.idToIndex = newIdToIndex
--     battleTeamData.indexToId = newIndexToId


-- --[[    if LOG_INFO_ENABLED then
--         local newPosList = {}
--         for k,v in pairs(newIdToIndex) do
--             table.insert(newPosList,"id = " .. k .. ",index = " .. v)
--         end
--         LogError("当前位置：" .. table.concat(newPosList,"\n"))
--     end]]

--     self:SetCntByIndex(cnt)

--     self:SetTreasureIdListByPbAndIndex(formationData.treasureSkilIds,teamIndex)
--     self:SetPasvListByPbAndIndex(formationData.treasurePassiveSkill,teamIndex)


--     FireEvent(EventNames.REFRESH_LEFT_TEMP_HERO,battleTeamData,self._sid)
-- end

-- function UIEmFight:RefreshCurCombatSet()
--     local combatType = self._combatType
--     if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
--         self:RefreshCombatType33Formation()
--     end
-- end

function UIEmFight:RefreshFormationIcon()
    local arrayId = self:GetArrayIdByIndex(self._curTeam)
    local ref = gModelFormation:GetFormationByRefId(arrayId)
    if not ref then return end

    FireEvent(EventNames.Change_Hero_Matrix,arrayId)


    local icon = ref.icon
    local imageTran = self:FindWndTrans(self.mFormationBtn,"Image")
    self:SetWndEasyImage(imageTran,icon)

    local name = ccLngText(ref.name)
    self:SetXUITextText(self.mFormationBtnName,name)
end

function UIEmFight:OnActivityResp(pb)
    if self._sid ~= pb.sid then return end
    gModelActivity:ReqActivityConfigData(self._sid)
end

-- function UIEmFight:OnClickCombatType33ToggleFunc()
--     local status = self:GetBotToggleStatus()
--     if not status then return end
--     local newStatus
--     if status == UIEmFight.TYPE_TOGGLE_STATUS_NOTSEL then
--         newStatus = UIEmFight.TYPE_TOGGLE_STATUS_SEL
--     else
--         newStatus = UIEmFight.TYPE_TOGGLE_STATUS_NOTSEL
--     end
--     self:SetBotToggleStatus(newStatus)
--     self:RefreshCurBotToggleShow()
--     self:InitCombatType33HeroList()
-- end

function UIEmFight:InitStaticData()

    local initState = gModelActivity:GetNameToggleState(self._sid) or UIEmFight.TYPE_TOGGLE_STATUS_NOTSEL

    self._showBotToggleMap = {
        -- [LCombatTypeConst.COMBAT_TYPE_33] = {
        --     --defaultStatus =  initState,
        --     status = initState,
        --     toggleNoSelName = ccClientText(37509),
        --     toggleSelName = ccClientText(37509),
        --     getInitStatusFunc = function()
        --         --- 获取保存在本地的数据或者服务端下发的数据，修改 status 数据
        --         return gModelActivity:GetNameToggleState(self._sid) or UIEmFight.TYPE_TOGGLE_STATUS_NOTSEL
        --     end,
        --     toggleClickFunc = function(...)
        --         --- 点击勾选框后要执行的函数
        --         self:OnClickCombatType33ToggleFunc()
        --     end,
        --     limitFunc = function(...)
        --         --- 限制函数，比如功能为开放等。。。
        --         return false
        --     end,
        -- },
    }
end

function UIEmFight:OnClickReturnBtnFunc()
    local returnFunc = self._returnFunc
    if returnFunc then
        returnFunc()
    end
    self._returnFunc = nil
    self:WndClose()
end

function UIEmFight:GetGeneralUIActivityHeroList(list,onDrawFunc)
    self:RefreshShowHeroList(false)
    local uiActivityHeroList = self._uiActivityHeroList
    if uiActivityHeroList then
        uiActivityHeroList:RefreshList(list)
    else
        uiActivityHeroList = self:GetUIScroll("uiActivityHeroList")
        self._uiActivityHeroList = uiActivityHeroList
        uiActivityHeroList:Create(self.mActivityHeroList,list,function(...) onDrawFunc(...) end,UIItemList.WRAP,false)
    end
    -- local isEmpty = #list < 1
    -- local showEmptyRoot
    -- local combatType = self._combatType
    -- if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
    --     showEmptyRoot = self.mNoActivityHeroListTxt
    --     if isEmpty then
    --         self:SetWndText(showEmptyRoot,ccClientText(37564))
    --     end
    -- -- end
    -- if showEmptyRoot then
    --     CS.ShowObject(showEmptyRoot,isEmpty)
    -- end
end

function UIEmFight:SetPasvListByPbAndIndex(pasvListPb,index)
    local pasvList = self:GetPasvListByIndex(index)
    local temp
    for i = 1,4 do
        temp = pasvListPb[i] or 0
        pasvList[i] = temp
    end
    self:InitTreasureSkillList(self.mPassiveSkillsBtn,pasvList)
end

function UIEmFight:GetActivityWebData()
    return self._activityWebData
end

-- function UIEmFight:RefreshActivityConfigData(sid)
--     sid = sid or self._sid
--     local combatType = self._combatType
--     if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
--         local requireHeroMap = gModelFairCompete:GetActivityRequireHeroMap(sid)
--         self._requiredHeroMap = requireHeroMap
--         local activityWebData = self:GetActivityWebData()
--         if activityWebData then
--             local config = activityWebData.config
--             if not self._resettingEff then
--                 local resettingEff = config.resettingEff
--                 if not string.isempty(resettingEff) then
--                     self._resettingEff = resettingEff
--                     self:CreateActivitySpecialShow({
--                         showStr = resettingEff,
--                         rewardEffKey = self.mActivityReSetGameEffRoot:GetInstanceID(),
--                         effectRoot = self.mActivityReSetGameEffRoot,
--                         spineRoot = self.mActivityReSetGameEffRoot,
--                         scaleSize = tonumber(config.resettingEffScale) or 50,
--                         needShow = false,
--                     })
--                 end
--             end

--             if not self._rewardEff then
--                 if not string.isempty(config.rewardEff) then
--                     self._rewardEff = {}
--                     local rewardEff = string.split(config.rewardEff,"|")
--                     for i,v in ipairs(rewardEff) do
--                         self._rewardEff[i] = v
--                     end
--                 end
--             end

--             if not self._BoxEff then
--                 if not string.isempty(config.BoxEff) then
--                     self._BoxEff = config.BoxEff
--                 end
--             end

--             if not self._treasureImage1 then
--                 if LOG_INFO_ENABLED then
--                     if config.treasureImage1 then
--                         printInfoNR("config.treasureImage1 = " .. config.treasureImage1)
--                     end
--                 end
--                 --- 不可领取
--                 self._treasureImage1 = {}
--                 local treasureImage1 = string.split(config.treasureImage1,"|")
--                 for i,v in ipairs(treasureImage1) do
--                     self._treasureImage1[i] = v
--                 end
--             end

--             if not self._treasureImage2 then
--                 if config.treasureImage2 then
--                     printInfoNR("config.treasureImage2 = " .. config.treasureImage2)
--                 end
--                 --- 已领取
--                 self._treasureImage2 = {}
--                 local treasureImage2 = string.split(config.treasureImage2,"|")
--                 for i,v in ipairs(treasureImage2) do
--                     self._treasureImage2[i] = v
--                 end
--             end

--             if not self._recruitEff2 then
--                 local recruitEff2 = config.recruitEff2
--                 if not string.isempty(recruitEff2) then
--                     self._recruitEff2 = recruitEff2
--                     self:CreateActivitySpecialShow({
--                         showStr = recruitEff2,
--                         rewardEffKey = self.mActivityDropBtnEffRoot:GetInstanceID(),
--                         effectRoot = self.mActivityDropBtnEffRoot,
--                         spineRoot = self.mActivityDropBtnEffRoot,
--                     })
--                 end
--             end

--             if not self._rewardEff2 then
--                 local rewardEff2 = config.rewardEff2
--                 if not string.isempty(rewardEff2) then
--                     self._rewardEff2 = rewardEff2
--                     self:CreateActivitySpecialShow({
--                         showStr = rewardEff2,
--                         rewardEffKey = self.mActivityBoxEffRoot:GetInstanceID(),
--                         effectRoot = self.mActivityBoxEffRoot,
--                         spineRoot = self.mActivityBoxEffRoot,
--                         callBack = function()
--                             CS.ShowObject(self.mActivityBoxEffRoot,true)
--                         end,
--                     })
--                 end
--             end

--             local shopId = config.shopId
--             CS.ShowObject(self.mShopBtn,shopId ~= nil)
--         end

--         gModelFairCompete:GetActivityAboutReq(sid)
--         self:InitCombatType33HeroList()
--         self:RefreshCombatType33ActivityShow()
--     end
-- end

function UIEmFight:GetCombatType33AllowFailure()
    local activityWebData = self:GetActivityWebData()
    if not activityWebData then return 0 end
    local config = activityWebData.config
    return tonumber(config.allowFailure)
end

function UIEmFight:OnClickBtnTeamMirrorBFunc()
end

function UIEmFight:GetIndexToIdByIndex(index)
    local battleTeamData = self:GetBattleTeamFormationDataByIndex(index)
    return battleTeamData.indexToId
end

function UIEmFight:GetIdToIndexByIndex(index)
    local battleTeamData = self:GetBattleTeamFormationDataByIndex(index)
    return battleTeamData.idToIndex
end

function UIEmFight:GetArrayIdByIndex(index)
    local battleTeamData = self:GetBattleTeamFormationDataByIndex(index)
    return battleTeamData.arrayId
end

-- function UIEmFight:RefreshActivityFairCompeteDropNum()
--     local recruitTimes = 0
--     local sid = self._sid
--     if sid then
--         recruitTimes = gModelFairCompete:GetFairCompeteDataInfoRecruitTimesBySid(sid)
--     end
--     local isEnough = recruitTimes > 0
--     local str = isEnough and ccClientText(37511) or ccClientText(37512)
--     str = string.replace(str,recruitTimes)
--     self:SetWndText(self.mActivityDropNum,str)
--     local showDropEff = isEnough
--     if showDropEff then
--         local status = gModelFairCompete:GetFairCompeteViewStatusBySid(sid)
--         if status == ModelFairCompete.TYPE_STAGE_RESET then
--             showDropEff = false
--         elseif status == ModelFairCompete.TYPE_STAGE_CLOSING then
--             showDropEff = false
--         end
--     end
--     CS.ShowObject(self.mActivityDropBtnEffRoot,showDropEff)
-- end

-- function UIEmFight:RefreshCombatType33ActivityShow()
--     local activityDataList = self:GetActivityDataList() or {}
--     local box1PageData = activityDataList[ModelFairCompete.TYPE_BOX_1] or {}

--     local winNum
--     local boxMap = {}
--     local box1RewardList = gModelFairCompete:GetBox1RewardList(box1PageData)
--     for i,v in ipairs(box1RewardList) do
--         winNum = v.winNum
--         local boxMapInfo = boxMap[winNum]
--         if not boxMapInfo then
--             boxMapInfo = {}
--             boxMapInfo.finishNum = 0
--             boxMapInfo.allNum = 0
--             boxMapInfo.entryList = {}
--             boxMap[winNum] = boxMapInfo
--         end
--         if v.status == ModelActivity.REWARD_STATUE_HAD_GET then
--             boxMapInfo.finishNum = boxMapInfo.finishNum + 1
--         end
--         boxMapInfo.allNum = boxMapInfo.allNum + 1
--         table.insert(boxMapInfo.entryList,v)
--     end

--     local sid = self._sid

--     local win = gModelFairCompete:GetFairCompeteDataInfoResultWinBySid(sid)
--     local lose = gModelFairCompete:GetFairCompeteDataInfoResultLoseBySid(sid)
--     local allowFailure = self:GetCombatType33AllowFailure()
--     local mustWin = self:GetCombatType33MustWin()
--     local progress = win / mustWin
--     LxUiHelper.SetProgress(self.mActivityBarSlider, progress)

--     self:SetWndText(self.mActivityScheduleTxt,win)

--     if LOG_INFO_ENABLED then
--         printInfoNR("打印而已，莫慌          ==== 胜利场数(win)：" .. win .. ",失败场数(lose)：" .. lose .. "，最多允许失败场数(allowFailure)：" .. allowFailure .. "，总胜利场数(mustWin)：" .. mustWin)
--     end

--     local status = gModelFairCompete:GetFairCompeteViewStatusBySid(sid)
--     local isClose = status == ModelFairCompete.TYPE_STAGE_CLOSING

--     local showResetGameEff = false
--     local isLoseFull = lose >= allowFailure
--     if isLoseFull then
--         showResetGameEff = true
--     elseif isClose then
--         showResetGameEff = true
--     end
--     CS.ShowObject(self.mActivityReSetGameEffRoot,showResetGameEff)

--     local textStr = isLoseFull and ccClientText(37550) or ccClientText(37549)
--     textStr = string.replace(textStr,lose,allowFailure)
--     self:SetWndText(self.mActivityReSetGameNum,textStr)

--     self:RefreshActivityBox()

--     local index = 1
--     local list = {}
--     for i = 1,mustWin do
--         local boxData = boxMap[i]
--         local data = {}
--         data.isAct = win >= i
--         data.showBox = boxData ~= nil
--         data.winNum = index
--         data.boxData = boxData
--         table.insert(list,data)
--         if data.showBox then
--             index = index + 1
--         end
--     end
--     self:InitActivityStarList(list)

--     self:RefreshActivityFairCompeteDropNum()

--     local fightBtnName = ""
--     if status == ModelFairCompete.TYPE_STAGE_RESET then
--         fightBtnName = ccClientText(37508)
--     elseif status == ModelFairCompete.TYPE_STAGE_START or status == ModelFairCompete.TYPE_STAGE_RESET_NEW then
--         fightBtnName = ccClientText(37510)
--     elseif isClose then
--         fightBtnName = ccClientText(37508)
--     else
--         fightBtnName = ccClientText(37548)
--     end
--     self:SetWndButtonText(self.mFightBtn,fightBtnName)
-- end

-- function UIEmFight:RefreshCombatType33View()
--     local isBattleView = self._wndType == UIEmFight.TYPE_BATTLE_GOTOCHALLENGE
--     CS.ShowObject(self.mActivityReSetGameDiv,isBattleView)
--     CS.ShowObject(self.mActivityBoxDiv,isBattleView)
--     CS.ShowObject(self.mShareBtn,isBattleView)
--     CS.ShowObject(self.mSquadsBtn,isBattleView)
--     CS.ShowObject(self.mReportBtn,isBattleView)
--     CS.ShowObject(self.mRuleBtn,isBattleView)
--     CS.ShowObject(self.mActivityTop,isBattleView)
--     if not isBattleView then
--         self:RefreshActivityFairCompeteDropNum()
--         return
--     end
--     self:RefreshCombatType33ActivityShow()
-- end

-- function UIEmFight:RefreshSingleView()
--     local combatType = self._combatType
--     if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
--         self:RefreshCombatType33View()
--     end
-- end

function UIEmFight:RefreshMultiView()

end

-- function UIEmFight:OnClickActivityDropBtnFunc()
--     if not self._sid then return end

--     local sid = self._sid
--     local recruitTimes = gModelFairCompete:GetFairCompeteDataInfoRecruitTimesBySid(sid)
--     if recruitTimes < 1 then
--         GF.ShowMessage(ccClientText(37554))
--         return
--     end

--     self._sendMsg = true
--     gModelFairCompete:OnFairCompeteHeroDropReq(sid)
-- end

function UIEmFight:GetShareData()

end

-- function UIEmFight:OnFairCompeteGetFormationResp(pb)
--     if self._sid ~= pb.sid then return end
--     if self._isOnClickResetBtn then return end
--     self:RefreshCurCombatSet()
-- end

-- function UIEmFight:OnFairCompeteSetFormationResp(pb)
--     if self._wndType == UIEmFight.TYPE_BATTLE_SAVEFORMATION then
--         self._sendMsg = false
--         GF.ShowMessage(ccClientText(37552))
--         return
--     end
--     if self._sid ~= pb.sid then return end
--     self:SendStartBattleMsg()
-- end

function UIEmFight:OnSceneHeroDown(pos)
    local index = self._curTeam
    local idToIndex = self:GetIdToIndexByIndex(index)
    local indexToId = self:GetIndexToIdByIndex(index)
    local downId = indexToId[pos]
    -- local combatType = self._combatType
    -- if combatType and combatType == LCombatTypeConst.COMBAT_TYPE_33 then
    --     if self:CheckHeroIsInterval({
    --         id = downId,
    --     }) then
    --         GF.ShowMessage(ccClientText(37553))
    --         return
    --     end
    -- end
    indexToId[pos] = nil
    idToIndex[downId] = nil
    local cnt = self:GetCntByIndex(index)
    self:SetCntByIndex(cnt - 1)
    self:InitHeroList()
end

function UIEmFight:RefreshCurBotToggleShow()
    local showBotToggleInfo = self:GetBotToggleInfo()
    if not showBotToggleInfo then return end
    self:RefreshBotToggleDesc(showBotToggleInfo)
    self:RefreshBotToggleSelStatus(showBotToggleInfo)
end

function UIEmFight:RefreshView()
    -- self:RefreshCurCombatSet()
    self:InitFormationList()
    self:RefreshLayerTypeView()
    self:InitHeroList()
end

function UIEmFight:SetTreasureIdListByPbAndIndex(treasureIdListPb,index)
    local treasureIdList = self:GetTreasureIdListByIndex(index)
    local temp
    for i = 1,4 do
        temp = treasureIdListPb[i] or 0
        treasureIdList[i] = temp
    end
    self:InitTreasureSkillList(self.mActiveSkillsBtn,treasureIdList)
end

function UIEmFight:GetFormationList()
    local list = {}
    local myLv = gModelPlayer:GetPlayerLv()
    local cfgList = gModelFormation:GetFormationCfgList()
    for i,v in ipairs(cfgList) do
        local isLock = myLv < v.needLv
        table.insert(list,{
            refId = v.refId,
            needLv = v.needLv,
            name = ccLngText(v.name),
            icon = v.icon,
            isLock = isLock,
        })
    end
    return list
end

-- function UIEmFight:OnClickShareBtnFunc()
--     local combatType = self._combatType
--     if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
--         local curTeam = self._curTeam
--         local cnt = self:GetCntByIndex(curTeam)
--         if cnt <= 0 then
--             GF.ShowMessage(ccClientText(10127))
--             return
--         elseif cnt < ModelFairCompete.BATTLE_NUM then
--             GF.ShowMessage(ccClientText(37566))
--             return
--         end

--         local battleTeamData = self:GetBattleTeamFormationDataByIndex(curTeam)
--         local shareData = gModelFairCompete:GetShareFormationTeam(battleTeamData)
--         local data = {
--             root = self.mShareBtn,
--             shareType = ModelChat.CHAT_SHARE_37,
--             shareData = shareData,
--         }
--         gModelGeneral:OpenShareTip(data)
--     end
-- end

-- function UIEmFight:OnClickSquadsBtnFunc()
--     local combatType = self._combatType
--     if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
--         if not self._sid then return end

--         gModelFairCompete:OpenActivityFairCompeteRank({
--             sid = self._sid,
--         })
--     end
-- end

-- function UIEmFight:OnClickReportBtnFunc()
--     local combatType = self._combatType
--     if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
--         if not self._sid then return end

--         gModelFairCompete:OpenActivityFairCompeteVideo({
--             sid = self._sid,
--             combatType = combatType,
--         })
--     end
-- end

-- function UIEmFight:OnClickRuleBtnFunc()
--     local combatType = self._combatType
--     if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
--         local activityWebData = self:GetActivityWebData()
--         if not activityWebData then return end
--         local config = activityWebData.config
--         local helpTipsContent = config.helpTipsContent
--         local title = gModelActivity:GetLngNameByActivitySid(self._sid)
--         GF.OpenWnd("UIBzTips",{title = title,text = helpTipsContent})
--     end
-- end

-- function UIEmFight:OnClickActivityBoxBtnFunc()
--     local combatType = self._combatType
--     if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
--         local activityDataList = self:GetActivityDataList()
--         if not activityDataList then return end

--         local box2PageData = activityDataList[ModelFairCompete.TYPE_BOX_2]
--         if not box2PageData then return end

--         local activityWebData = self:GetActivityWebData()
--         if not activityWebData then return end

--         local config = activityWebData.config
--         local competeWinReward = config.competeWinReward or ""
--         if string.isempty(competeWinReward) then return end

--         competeWinReward = string.split(competeWinReward,";")
--         local competeWinRewardList = {}
--         for i,v in ipairs(competeWinReward) do
--             v = string.split(v,"=")
--             table.insert(competeWinRewardList,{
--                 winNum = tonumber(v[1]),                --- 累胜次数
--                 scoreNum = tonumber(v[2]),              --- 积分数量
--             })
--         end

--         local disposeEntryList = gModelFairCompete:GetBox2RewardList(box2PageData)

--         local winNum,scoreNum
--         local list = {}
--         for i,v in ipairs(competeWinRewardList) do
--             winNum,scoreNum = v.winNum,v.scoreNum
--             local firstData
--             local rewardMap = {}
--             for idx,val in ipairs(disposeEntryList) do
--                 if val.scoreNum <= scoreNum then
--                     gModelFairCompete:DisposeItemList2ItemMap(rewardMap,val.items)
--                     firstData = val
--                 else
--                     break
--                 end
--             end
--             if firstData then
--                 local rewardList = gModelFairCompete:DisposeItemMap2ItemList(rewardMap)
--                 table.insert(list,{
--                     title = string.replace(ccClientText(37558),winNum),
--                     rewardList = rewardList,
--                     sort = firstData.entryId,
--                 })
--             end
--         end
--         table.sort(list,function(a,b)
--             return a.sort < b.sort
--         end)
--         gModelFairCompete:OpenActivityFairCompeteRewardShow({
--             sid = self._sid,
--             itemList = list
--         })
--     end
-- end

-- function UIEmFight:OnClickActivityReSetGameBtnFunc()
--     self:OnCombatType33ReSetGameFunc()
-- end

-- function UIEmFight:OnClickShopBtnFunc()
--     local combatType = self._combatType
--     if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
--         local activityWebData = self:GetActivityWebData()
--         if not activityWebData then return end
--         local config = activityWebData.config
--         local shopId = config.shopId
--         if not shopId then return end
--         GF.CloseWndByName("UIActFairCompeteMain")
--         local sid = self._sid
--         GF.OpenWndBottom("UIDian",{page = ModelShop.ACTIVITY,subPage = sid,func = function()
--             local activityData = gModelActivity:GetActivityBySid(sid)
--             if activityData and activityData.status ~= ModelActivity.STATUS_NO_SHOW then
--                 gModelFairCompete:OpenActivityFairCompeteMain(activityData)
--                 gModelGeneral:ClearRecordGameState()
--                 return
--             end
--         end})
--         FireEvent(EventNames.ONLY_CHANGE_MAIN_BTN_ON,{index = 1})
--         GF.ChangeMap("LCityMap")
--         self._returnFunc = nil
--         self:WndClose()
--     end
-- end

function UIEmFight:InitEvent()
    self:SetWndClick(self.mFormationBtn,function() self:OnClickFormationBtnFunc() end)
    self:SetWndClick(self.mActiveSkillsBtn,function() self:OnClickActiveSkillsBtnFunc() end)
    self:SetWndClick(self.mPassiveSkillsBtn,function() self:OnClickPassiveSkillsBtnFunc() end)
    self:SetWndClick(self.mBtnTeamMirrorA,function() self:OnClickBtnTeamMirrorAFunc() end)
    self:SetWndClick(self.mBtnTeamMirrorB,function() self:OnClickBtnTeamMirrorBFunc() end)
    self:SetWndClick(self.mReturnBtn,function() self:OnClickReturnBtnFunc() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mFightBtn,function() self:OnClickFightBtnFunc() end)
    -- self:SetWndClick(self.mActivityDropBtn,function() self:OnClickActivityDropBtnFunc() end)
    -- self:SetWndClick(self.mShareBtn,function() self:OnClickShareBtnFunc() end)
    -- self:SetWndClick(self.mSquadsBtn,function() self:OnClickSquadsBtnFunc() end)
    -- self:SetWndClick(self.mReportBtn,function() self:OnClickReportBtnFunc() end)
    -- self:SetWndClick(self.mRuleBtn,function() self:OnClickRuleBtnFunc() end)
    -- self:SetWndClick(self.mActivityBoxBtn,function() self:OnClickActivityBoxBtnFunc() end)
    -- self:SetWndClick(self.mActivityReSetGameBtn,function() self:OnClickActivityReSetGameBtnFunc() end)
    -- self:SetWndClick(self.mActivityReSetGameIconBtn,function() self:OnClickActivityReSetGameBtnFunc() end)
    -- self:SetWndClick(self.mShopBtn,function() self:OnClickShopBtnFunc() end)
end

function UIEmFight:GetEmptyPosToIdByIndex(index)
    local indexToId = self:GetIndexToIdByIndex(index)
    local pos
    local recordNum = 0
    for i = 1,UIEmFight.HERO_NUM do
        if not indexToId[i]  then
            pos = i
            break
        end
        recordNum = recordNum + 1
    end
    local isFull = recordNum == UIEmFight.HERO_NUM
    return pos,isFull
end

function UIEmFight:InitFormationList()
    local list = self:GetFormationList()
    local uiFormationList = self._uiFormationList
    if uiFormationList then
        uiFormationList:RefreshList(list)
    else
        uiFormationList = self:GetUIScroll("uiFormationList")
        self._uiFormationList = uiFormationList
        uiFormationList:Create(self.mFormationList,list,function(...) self:OnDrawFormationCell(...) end)
    end
end

-- function UIEmFight:OnFairCompeteHeroDropResp(pb)
--     if self._sid ~= pb.sid then return end

--     self._sendMsg = false

--     --gModelFairCompete:OnFairCompeteGetFormationReq(self._sid)
-- end

-- function UIEmFight:OnFairCompeteDataInfoResp(pb)
--     if self._sid ~= pb.data.sid then return end
--     self._sendMsg = false
--     local key = self._fairCompeteTimerKey
--     self:TimerStop(key)
--     self:TimerStart(key,1,false,-1)
--     if self._isOnClickResetBtn then return end
--     if self._isCombat then return end
--     self:RefreshView()
-- end

-- function UIEmFight:OnFairCompeteResetResp(pb)
--     if self._sid ~= pb.sid then return end

--     self._recordHeroSortMap = {}
--     self._sendMsg = false
--     self._isOnClickResetBtn = false
--     self:InitBattleTeamDataMap()
--     self:RefreshCurCombatSet()
--     if pb.op == ModelFairCompete.RESET_OPT_TYPE_1 then return end
-- --[[    self:InitBattleTeamDataMap()
--     gModelFairCompete:GetActivityAboutReq(self._sid)]]
-- end

function UIEmFight:InitMsg()
    self:WndEventRecv(EventNames.ON_ACTIVITY_CONFIG_DATA,function (...) self:OnActivityConfigData(...) end)
    self:WndNetMsgRecv(LProtoIds.ActivityResp,function(pb) self:OnActivityResp(pb) end)
    self:WndNetMsgRecv(LProtoIds.ActivityPageResp,function(pb) self:OnActivityPageResp(pb) end)


    -- self:WndNetMsgRecv(LProtoIds.FairCompeteGetFormationResp,function(pb) self:OnFairCompeteGetFormationResp(pb) end)
    -- self:WndNetMsgRecv(LProtoIds.FairCompeteSetFormationResp,function(pb) self:OnFairCompeteSetFormationResp(pb) end)
    -- self:WndNetMsgRecv(LProtoIds.FairCompeteHeroDropResp,function(pb) self:OnFairCompeteHeroDropResp(pb) end)
    -- self:WndNetMsgRecv(LProtoIds.FairCompeteDataInfoResp,function(pb) self:OnFairCompeteDataInfoResp(pb) end)
    -- self:WndNetMsgRecv(LProtoIds.FairCompeteResetResp,function(pb) self:OnFairCompeteResetResp(pb) end)


     self:WndEventRecv(EventNames.Scene_Hero_Down,function(pos) self:OnSceneHeroDown(pos) end)
    -- 英雄交换数据
    self:WndEventRecv(EventNames.Swap_Hero_Info, function(...) self:OnSwapHeroInfo(...) end)

    self:WndEventRecv(EventNames.NET_ERROR_CODE,function(code,error, argList)
        self:InitStatus()
    end)
end

function UIEmFight:GetGeneralUIHeroList(list,onDrawFunc)
    self:RefreshShowHeroList(true)
    local uiHeroList = self._uiHeroList
    if uiHeroList then
        uiHeroList:RefreshList(list)
    else
        uiHeroList = self:GetUIScroll("uiHeroList")
        self._uiHeroList = uiHeroList
        uiHeroList:Create(self.mHeroList,list,function(...) onDrawFunc(...) end,UIItemList.WRAP)
    end
end

function UIEmFight:SetBotToggleStatus(status)
    local showBotToggleInfo = self:GetBotToggleInfo()
    if not showBotToggleInfo then return end
    showBotToggleInfo.status = status


    gModelActivity:RecordToggleState(self._sid,status)
end

function UIEmFight:RefreshShowHeroList(showHeroList)
    CS.ShowObject(self.mHeroList,showHeroList)

    local showActHeroList = not showHeroList
    CS.ShowObject(self.mActivityHeroList,showActHeroList)
    CS.ShowObject(self.mActivityHeroDiv,showActHeroList)
end

function UIEmFight:OnActivityPageResp(pb)
    if self._sid ~= pb.sid then return end
    local activityDataList = self._activityDataList
    if not activityDataList then
        activityDataList = {}
        self._activityDataList = activityDataList
    end
    local pages = pb.pages
    local pageId,page
    for i, v in ipairs(pages) do
        page = gModelActivity:GenerateActivePageDataFromPb(v)
        pageId = v.pageId
        activityDataList[pageId] = page
    end
    self:RefreshActivityServerData()
end

function UIEmFight:GetBotToggleIsSel(showBotToggleInfo)
    local status = showBotToggleInfo and showBotToggleInfo.status or UIEmFight.TYPE_TOGGLE_STATUS_NOTSEL
    return status == UIEmFight.TYPE_TOGGLE_STATUS_SEL
end

function UIEmFight:SetIdToIndexByIdAndPosFromIndex(id,pos,optType,index,needUpCnt)
    local idToIndex = self:GetIdToIndexByIndex(index)
    local indexToId = self:GetIndexToIdByIndex(index)
    local cnt = self:GetCntByIndex(index)
    local optNum
    if optType == UIEmFight.TYPE_OPTHERO_UP then
        idToIndex[id] = pos
        indexToId[pos] = id
        optNum = cnt + 1
    else
        idToIndex[id] = nil
        indexToId[pos] = nil
        optNum = cnt - 1
    end
    if needUpCnt == nil then
        needUpCnt = true
    end
    if needUpCnt then
        self:SetCntByIndex(optNum)
    end
end

function UIEmFight:GetBotToggleInfo()
    local combatType = self._combatType
    if not combatType then return end
    local showBotToggleInfo = self._showBotToggleMap[combatType]
    if not showBotToggleInfo then
        if LOG_INFO_ENABLED then
            printInfoNR("暂未找到 Toggle 相关配置，如需要开启 BotToggle 功能，请前往 InitStaticData 函数 的 self._showBotToggleMap 添加配置")
        end
    end
    return showBotToggleInfo
end

function UIEmFight:InitBattleTeamDataMap()
    self._battleTeamDataMap = {}
end

--- v.refId 是 GameTable.FairCompeteHeroRef 的refId
-- function UIEmFight:GetCombatType33HeroList()
--     if not self._sid then return {} end
--     local activityHeroList = gModelFairCompete:GetFairCompeteDataInfoHeroInfoBySid(self._sid) or {}
--     if #activityHeroList < 1 then return {} end

--     local isHaveRecord = true
--     local recordHeroList = self._recordHeroList
--     if not recordHeroList then
--         isHaveRecord = false
--         recordHeroList = {}
--         self._recordHeroList = recordHeroList
--     end

--     local isHaveSortRecord = true
--     local recordHeroSortMap = self._recordHeroSortMap
--     if not recordHeroSortMap then
--         isHaveSortRecord = false
--         recordHeroSortMap = {}
--         self._recordHeroSortMap = recordHeroSortMap
--     end
--     local heroType = self._heroType
--     local ref,refId,typeHero,typeHeroRace,id
--     local isIns
--     local list = {}
--     local allLen = #activityHeroList
--     local idx
--     local intervalNum = 0
--     local newNum = 1
--     local defaultNum = allLen + 1
--     for i,v in ipairs(activityHeroList) do
--         refId = v.refId
--         ref = gModelFairCompete:GetFairCompeteHeroRefByRefId(refId)
--         if ref then
--             typeHero = ref.type
--             isIns = true
--             if heroType ~= UIHeroRaceList.ALL_RACE_REFID then
--                 typeHeroRace = gModelHero:GetHeroRace(typeHero)
--                 isIns = typeHeroRace == heroType
--             end
--             if isIns then
--                 id = tostring(refId)
--                 local isInterval = self:CheckHeroIsInterval({
--                     id = id,
--                 })
--                 self:UpdataRequiredHero(id,ref.attr)

--                 local showEff = false
--                 if isHaveRecord and not recordHeroList[id] then
--                     showEff = true
--                 end

--                 if isHaveSortRecord then
--                     if recordHeroSortMap[id] then
--                         idx = recordHeroSortMap[id]
--                     else
--                         if isInterval then
--                             idx = intervalNum
--                             intervalNum = intervalNum - 1
--                         elseif showEff then
--                             idx = newNum
--                             newNum = newNum + 1
--                         else
--                             idx = defaultNum
--                             defaultNum = defaultNum + 1
--                         end
--                         recordHeroSortMap[id] = idx
--                     end
--                 else
--                     if isInterval then
--                         idx = intervalNum
--                         intervalNum = intervalNum - 1
--                     elseif showEff then
--                         idx = newNum
--                         newNum = newNum + 1
--                     else
--                         idx = defaultNum
--                         defaultNum = defaultNum + 1
--                     end
--                     recordHeroSortMap[id] = idx
--                 end
--                 table.insert(list,{
--                     refId = refId,
--                     createTime = v.createTime,
--                     typeHero = typeHero,
--                     monster = ref.attr,
--                     id = id,
--                     isInterval = isInterval,
--                     showEff = showEff,
--                     idx = idx,
--                 })
--             end
--         end
--     end
--     table.sort(list,function(a,b)
--         local isIntervalStatusA = a.isInterval and 1 or 0
--         local isIntervalStatusB = b.isInterval and 1 or 0
--         if isIntervalStatusA ~= isIntervalStatusB then
--             return isIntervalStatusA > isIntervalStatusB
--         end
--         return a.createTime > b.createTime
-- --[[        local showEffStatusA = a.showEff and 1 or 0
--         local showEffStatusB = b.showEff and 1 or 0
--         if showEffStatusA ~= showEffStatusB then
--             return showEffStatusA > showEffStatusB
--         end
--         return a.idx < b.idx]]
--     end)

--     self._recordHeroSortMap = recordHeroSortMap

--     local newRecordHeroList = {}
--     for i,v in ipairs(activityHeroList) do
--         newRecordHeroList[tostring(v.refId)] = true
--     end
--     self._recordHeroList = newRecordHeroList

--     return list
-- end

-- function UIEmFight:InitCombatType33HeroList()
--     CS.ShowObject(self.mHeroList,false)

--     local wndIns = GF.FindFirstWndByName("UIActFairCompeteReset")
--     if wndIns then return end
--     local list = self:GetCombatType33HeroList()
--     self:GetGeneralUIActivityHeroList(list,function(...) self:OnDrawCombatType33HeroCell(...) end)
-- end

-- function UIEmFight:CheckHeroIsInterval(itemdata)
--     local combatType = self._combatType
--     if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
--         if not self._requiredHeroMap then return false end
--         return self._requiredHeroMap[itemdata.id] ~= nil
--     end
--     return false
-- end

-- function UIEmFight:OnDrawCombatType33HeroCell(list,item,itemdata,itempos)
--     local intervalImgTrans = self:FindWndTrans(item,"intervalImg")
--     local EffRootTrans = self:FindWndTrans(item,"EffRoot")

--     local showEff = itemdata.showEff or false

--     local effKey = EffRootTrans:GetInstanceID()
--     self:DestroyWndEffectByKey(effKey)
--     if showEff then
--         local activityWebData = self:GetActivityWebData()
--         if activityWebData then
--             local config = activityWebData.config
--             local recruitEff = config.recruitEff
--             if not string.isempty(recruitEff) then
--                 self:CreateActivitySpecialShow({
--                     showStr = recruitEff,
--                     rewardEffKey = effKey,
--                     effectRoot = EffRootTrans,
--                     spineRoot = EffRootTrans,
--                     callBack = function()
--                         if not self:IsWndValid() then return end
--                         CS.ShowObject(EffRootTrans,true)
--                     end,
--                 })
--             else
--                 CS.ShowObject(EffRootTrans,false)
--             end
--         else
--             CS.ShowObject(EffRootTrans,false)
--         end
--     else
--         CS.ShowObject(EffRootTrans,false)
--     end

--     local isInterval = self:CheckHeroIsInterval(itemdata)
--     CS.ShowObject(intervalImgTrans,isInterval)

--     local HeroIconTrans = self:GetHeroIconTrans(item)
--     self:SetIconClickScale(HeroIconTrans,true)

--     local isSel = self:CheckCurHeroIsSel(itemdata)
--     local showName = self:CheckCurCombatTypeBotToggleIsSel()

--     local instanceID = item:GetInstanceID()
--     local baseClass = self:GetCommonIcon(instanceID)
--     baseClass:Create(HeroIconTrans)
-- --[[    baseClass:SetHeroIcon(itemdata.typeHero)
--     baseClass:SetNoShowLv(true)]]

--     local monster = itemdata.monster
--     local monsterRef = gModelHero:GetMonsterAttrByRefId(monster)
--     baseClass:SetHeroDataSet({
--         refId = monster,
--         star = monsterRef and monsterRef.starLv or 1,
--         level = monsterRef and monsterRef.lv or 1,
--         isMon = true,
--     })
--     baseClass:ShowGouImg(isSel)
--     baseClass:SetShowNameStatus(showName)
--     baseClass:DoApply()

--     -- self:SetWndClick(HeroIconTrans,function()
--     --     self:OnClickCombatType33HeroFunc(itemdata)
--     -- end)
-- end

-- function UIEmFight:OnClickCombatType33HeroFunc(itemdata)
--     local isSel = self:CheckCurHeroIsSel(itemdata)
--     local bLineUp = false
--     local id = itemdata.id
--     local emptyPos
--     if isSel then
--         local isInterval = self:CheckHeroIsInterval(itemdata)
--         if isInterval then
--             GF.ShowMessage(ccClientText(37553))
--             return
--         end
--         local pos = self:GetIdPosByIdAndIndex(id)
--         if pos then
--             emptyPos = pos
--             self:SetIdToIndexByIdAndPosFromIndex(id,pos,UIEmFight.TYPE_OPTHERO_DOWN)
--         end
--     else
--         if self:GetCntByIndex() == UIEmFight.HERO_NUM then
--             --上阵人数已达上限
--             GF.ShowMessage(ccClientText(16605))
--             return
--         end
--         local pos,fullStatus = self:GetEmptyPosToIdByIndex()
--         if fullStatus then
--             --上阵人数已达上限
--             GF.ShowMessage(ccClientText(16605))
--             return
--         end
--         self:SetIdToIndexByIdAndPosFromIndex(id,pos,UIEmFight.TYPE_OPTHERO_UP)
--         bLineUp = true
--         emptyPos = pos
--     end
--     FireEvent(EventNames.Scene_Hero_GoTo, itemdata.monster, emptyPos, bLineUp, true)

--     self:InitCombatType33HeroList()
-- end

function UIEmFight:InitHeroList()
    -- local combatType = self._combatType
    -- if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
    --     self:InitCombatType33HeroList()
    -- end
end

-- function UIEmFight:OnCombatType33ReSetGameFunc()
--     if not self._sid then return end
--     if self._sendMsg then return end
--     local status,loseTime = self:GetFairCompeteLoseTime()
--     if status then
--         status = gModelFairCompete:GetFairCompeteViewStatusBySid(self._sid)
--         if not (status == ModelFairCompete.TYPE_STAGE_RESET or status == ModelFairCompete.TYPE_STAGE_CLOSING) then
--             GF.ShowMessage(ccClientText(37568))
--             return
--         end
--     end
--     local para = {
--         refId = 350003,
--         func = function()
--             self._sendMsg = true
--             self._isOnClickResetBtn = true
--             gModelFairCompete:OnFairCompeteResetReq(self._sid,ModelFairCompete.RESET_OPT_TYPE_1)
--         end,
--     }
--     gModelGeneral:OpenUIOrdinTips(para)
-- end

-- function UIEmFight:SendNetMsg()
--     self._sendMsg = true
--     self._isCombat = true
--     local sid = self._sid
--     local combatType = self._combatType
--     local curTeam = self._curTeam
--     local battleTeamData = self:GetBattleTeamFormationDataByIndex(curTeam)
--     local idToIndex = battleTeamData.idToIndex
--     local formationData = {
--         arrayId = battleTeamData.arrayId,
--         combatType = combatType,
--         teamIndex = curTeam,
--         idToIndex = idToIndex,
--         -- artifact = 0,【G公共支持】删除神器功能相关数据
--         treasureSkilIds = battleTeamData.treasureIdList,
--         treasurePassiveSkill = battleTeamData.pasvList,
--     }
--     gModelFairCompete:OnFairCompeteSetFormationReq(sid,formationData)
-- end

-- function UIEmFight:OnCombatType33SendMsg()
--     local sid = self._sid
--     local status = gModelFairCompete:GetFairCompeteViewStatusBySid(sid)
--     if status == ModelFairCompete.TYPE_STAGE_RESET or status == ModelFairCompete.TYPE_STAGE_CLOSING then
--         self:OnCombatType33ReSetGameFunc()
--         return
--     end
--     local cnt = self:GetCntByIndex(0)
--     if cnt <= 0 then
--         GF.ShowMessage(ccClientText(10127))
--         return
--     elseif cnt < ModelFairCompete.BATTLE_NUM then
--         GF.ShowMessage(ccClientText(37555))
--         return
--     end

--     local wndType = self._wndType
--     if wndType == UIEmFight.TYPE_BATTLE_GOTOCHALLENGE and gModelFairCompete:CheckIsInBanTime(sid) then
--         GF.ShowMessage(ccClientText(37569))
--         return
--     end

--     local combatType = self._combatType
--     local needAskPasv = false
--     local needAsk = false
--     if not gModelFormation:CheckTreasureNotUse(combatType) then
--         needAsk = self:NeedAskTreasure()
--         needAskPasv = self:NeedAskPasv()
--     end

--     local sendMsgFunc = function()
--         if self:IsWndClosed() then return end
--         self:SendNetMsg()
--     end

--     if wndType == UIEmFight.TYPE_BATTLE_SAVEFORMATION then
--         local func1 = function()
--             if self:IsWndClosed() then return end

--             if needAskPasv then
--                 gModelGeneral:OpenUIOrdinTips({refId = 52004,func = sendMsgFunc})
--                 return
--             end
--             sendMsgFunc()
--         end
--         if needAsk then
--             gModelGeneral:OpenUIOrdinTips({refId = 52002,func = func1})
--             return
--         end

--         func1()
--     elseif wndType == UIEmFight.TYPE_BATTLE_GOTOCHALLENGE then
--         local func1 = function()
--             if self:IsWndClosed() then return end

--             if needAskPasv then
--                 gModelGeneral:OpenUIOrdinTips({refId = 52003,func = sendMsgFunc})
--                 return
--             end
--             sendMsgFunc()
--         end
--         if needAsk then
--             gModelGeneral:OpenUIOrdinTips({refId = 52001,func = func1})
--             return
--         end

--         func1()
--     end
-- end

function UIEmFight:OnClickSingleFightBtnFunc()
    -- local combatType = self._combatType
    -- if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
    --     self:OnCombatType33SendMsg()
    -- else
        self:SendStartBattleMsg()
    -- end
end

function UIEmFight:InitRaceTypeList()
    local noShowRaceList = self:GetNoShowRaceList()
    local data = {
        wndClass = self,
        listTrans = self.mHeroRaceList,
        showType = UIHeroRaceList.TYPE_NORMAL,
        showListBg = true,
        noShowRaceList = noShowRaceList,
        callbackFunc = function(raceType)
            if not self:IsWndValid() then return end
            self:TypeBtnEvent(raceType)
        end,
        checkSelFunc = function(raceType)
            if not self:IsWndValid() then return end
            return self._heroType == raceType
        end,
    }
    self:GetUIHeroRaceList(data)
end



function UIEmFight:OnTryTcpReconnect()
    self:ViewShow()
end

function UIEmFight:TypeBtnEvent(raceType)
    if raceType ~= UIHeroRaceList.ALL_RACE_REFID then
        if self._raceKeyList and not self._raceKeyList[raceType] then
            return
        end
    end

    self._heroType = raceType
    self:InitHeroList()
end

function UIEmFight:SetTopRightBtnName(trans,name)
    local BtnNameTrans = self:FindWndTrans(trans,"BtnName")
    self:SetWndText(BtnNameTrans,name)
end

function UIEmFight:GetCombatType33MustWin()
    local activityWebData = self:GetActivityWebData()
    if not activityWebData then return 0 end
    local config = activityWebData.config
    return tonumber(config.mustWin)
end

function UIEmFight:ViewShow()
    self:InitStatus()
    self:InitUIShow(true,0.4)
    self:InitRaceTypeList()
    self:RefreshBotToggle()
    self:RefreshView()

    if self._sid then
        gModelActivity:ReqActivityConfigData(self._sid)
    end
end

function UIEmFight:CreateActivitySpecialShow(info)
    if not info then return end
    local showStr = info.showStr
    if not showStr then return end
    if LOG_INFO_ENABLED  then
        printInfoNR("打印而已，莫慌           配置表现：" .. showStr)
    end
    local needShow = info.needShow
    if needShow == nil then
        needShow = true
    end
    local callBack = info.callBack
    local showStrInfo = string.split(showStr,"=")
    local showType = tonumber(showStrInfo[1])
    local refName = showStrInfo[2]
    local rewardEffKey = info.rewardEffKey .. "_" .. refName
    if showType == 1 then
        self:DestroyWndEffectByKey(rewardEffKey)
        -- 特效
        local scaleSize = info.scaleSize or 100
        local effectRoot = info.effectRoot
        self:CreateWndEffect(effectRoot,refName,rewardEffKey,scaleSize,false)
        CS.ShowObject(effectRoot,needShow)
    elseif showType == 2 then
        local showAniName = info.showAniName
        local spine = self:FindWndSpineByKey(rewardEffKey)
        if spine then
            if showAniName then
                spine:PlayAnimationSolid(showAniName,true)
            end
        else
            local spineRoot = info.spineRoot
            self:CreateWndSpine(spineRoot,refName,rewardEffKey,false,function(dpSpine)
                if showAniName then
                    dpSpine:PlayAnimationSolid(showAniName,true)
                end
                if callBack then
                    callBack()
                else
                    CS.ShowObject(spineRoot,false)
                    self:RefreshLayerTypeView()
                end
            end)
        end
    end
end

function UIEmFight:SendStartBattleMsg()
    self._sendMsg = true
    local cnt = self:GetCntByIndex(0)
    if cnt <= 0 then
        GF.ShowMessage(ccClientText(10127))
        return
    end
    local curTeam = self._curTeam
    local battleTeamData = self:GetBattleTeamFormationDataByIndex(curTeam)
    local arrayId = battleTeamData.arrayId
    local matrix = gModelFormation:GetFormationPosByRefId(arrayId)
    local grids = {}
    local idToIndex = battleTeamData.idToIndex
    for k,v in pairs(idToIndex) do
        table.insert(grids, {
            id = k,
            grid = matrix[v],
        })
    end
    local skipBattle = false
    local x,y,pageId,entryId,eventRefId,url,rewardBoxData,chapterEntryId,endFunc,bossTowerPkType

    local combatData = {
        combatType = self._combatType,
        formationRefId = arrayId,
        grids = grids,
        -- artifact = 0,【G公共支持】删除神器功能相关数据
        teamIndex = curTeam,
        treasureSkilIds = battleTeamData.treasureIdList,
        treasurePassiveSkill = battleTeamData.pasvList,

        targetId = nil,
        skipBattle = skipBattle,
        battleName = self._battleName,
        battleRefId = nil,
        pageId = pageId,
        entryId = entryId,
        x = x,
        y = y,
        eventRefId = eventRefId,

        ---PK请求相关数据
        serverId = self._serverId,
        playerId = self._playerId,
        url = url,
        ---界面显示相关

        isBattleToBackground = false,
        dungeonId = self._dungeonId,
        map = self._map,
        mapRefId = self._mapRefId,
        sid = self._sid,

        rewardBoxData = rewardBoxData or {},
        chapterEntryId = chapterEntryId or nil,
        fromPrepare  = true,

        endFunc = endFunc,
        bossTowerPkType = bossTowerPkType,
    }
    gModelBattle:StartBattleReq(combatData)
end

function UIEmFight:OnActivityConfigData(data,sid)
    if sid ~= self._sid then return end

    local activityData = gModelActivity:GetActivityBySid(sid)
    self._activityData = activityData
    if not activityData then return end

    local activityWebData = gModelActivity:GetWebActivityDataById(sid)
    self._activityWebData = activityWebData
    if not activityWebData then return end

    -- self:RefreshActivityConfigData(sid)

    gModelActivity:OnActivityPageReq(sid)
end

function UIEmFight:NeedAskTreasure()
    -- if self._noNeedAskTreasure[self._combatType] then return false end

    -- local treasureIdList = self:GetTreasureIdListByIndex()
    -- local upSkillNum = 0
    -- local idRecord = {}
    -- for k,v in pairs(treasureIdList) do
    --     if v ~= 0 then
    --         upSkillNum = upSkillNum + 1
    --         idRecord[v] = true
    --     end
    -- end
    -- local canUpNum = gModelTreasure:CanUpSkillNum() - upSkillNum
    -- local canUpTreasureList = gModelTreasure:GetActiveSkillList(idRecord)
    -- local canLen = #canUpTreasureList ---还剩几个宝物
    -- canUpNum = math.min(canUpNum,canLen)
    -- if canUpNum <= 0  then return false end

    return false
end

function UIEmFight:OnClickFightBtnFunc()
    if self._sendMsg then return end
    local layerBattleType = self._layerBattleType
    if layerBattleType == UIEmFight.TYPE_LAYERBATTLE_SINGLE then
        self:OnClickSingleFightBtnFunc()
    else
    end
end

function UIEmFight:RefreshBotToggleDesc(showBotToggleInfo)
    local isSel = self:GetBotToggleIsSel(showBotToggleInfo)
    local toggleName = isSel and showBotToggleInfo.toggleSelName or showBotToggleInfo.toggleNoSelName
    self:SetWndText(self.mMainBotToggleDesc,toggleName)
end

function UIEmFight:DisposeExtraData()
    local extraData = self._extraData
    local wndType = extraData and extraData.wndType or UIEmFight.TYPE_BATTLE_SAVEFORMATION
    self._wndType = wndType
    if not extraData then return end
    self._combatType = extraData.combatType
    self._curTeam = extraData.curTeam or 0
    self._returnFunc = extraData.returnFunc
    self._sid = extraData.sid
    self._race = extraData.race
    self._requiredHeroMap = extraData.requiredHeroMap
end

function UIEmFight:GetBattleTeamFormationDataByIndex(index)
    index = index or self._curTeam

    local battleTeamDataMap = self:GetBattleTeamDataMap()
    local battleTeamDataIndex = battleTeamDataMap[index]
    if not battleTeamDataIndex then
        battleTeamDataIndex = {}

        --- { combatType,idToIndex,arrayId,treasureIdList,pasvList,cnt }
        battleTeamDataIndex.combatType = self._combatType
        battleTeamDataIndex.idToIndex = {}
        battleTeamDataIndex.indexToId = {}
        battleTeamDataIndex.arrayId = 1
        battleTeamDataIndex.treasureIdList = {}
        battleTeamDataIndex.pasvList = {}
        battleTeamDataIndex.cnt = 0

        battleTeamDataMap[index] = battleTeamDataIndex
    end
    return battleTeamDataIndex
end

function UIEmFight:GetTreasureIdListByIndex(index)
    local battleTeamData = self:GetBattleTeamFormationDataByIndex(index)
    return battleTeamData.treasureIdList
end

function UIEmFight:OnClickActiveSkillsBtnFunc()
    if gModelFormation:CheckTreasureNotUse(self._combatType,true) then return end

    local treasureIdList = self:GetTreasureIdListByIndex()
    local skillIdList = {}
    for i = 1,4 do
        if treasureIdList[i] then
            skillIdList[i] = treasureIdList[i]
        end
    end
    local para = {
        wndType = 1,
        treasureSkilIds = skillIdList,
        combatType = self._combatType,
        idRecord = {},
        func = function(list)
            if self:IsWndClosed() then return end
            self:SetTreasureIdListByPbAndIndex(list)
        end
    }
    self:OpenSelBattleTreasure(para)
end

function UIEmFight:SetSwapIdAndIndex(swapInfo1,swapInfo2)
    local curTeam = self._curTeam
    local idToIndex = self:GetIdToIndexByIndex(curTeam)
    local indexToId = self:GetIndexToIdByIndex(curTeam)

    local id1 = swapInfo1.id
    local index1 = swapInfo1.index

    local id2 = swapInfo2.id
    local index2 = swapInfo2.index

    local isEmptyPos1 = id1 == nil
    local isEmptyPos2 = id2 == nil
    local isMoveEmpty = isEmptyPos1 or isEmptyPos2

    if not isEmptyPos1 then
        idToIndex[id1] = nil
        indexToId[index1] = nil
    end

    if not isEmptyPos2 then
        idToIndex[id2] = nil
        indexToId[index2] = nil
    end

    if not isEmptyPos1 then
        idToIndex[id1] = index2
        indexToId[index2] = id1
    end

    if not isEmptyPos2 then
        idToIndex[id2] = index1
        indexToId[index1] = id2
    end

--[[    if LOG_INFO_ENABLED then
        local newPosList = {}
        for k,v in pairs(idToIndex) do
            table.insert(newPosList,"id = " .. k .. ",index = " .. v)
        end
        LogError("交换后的位置：" .. table.concat(newPosList,"\n"))
    end]]
end

function UIEmFight:RefreshActivityServerData()
    -- local combatType = self._combatType
    -- if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
    --     if self._isCombat then return end
    --     self:RefreshCombatType33View()
    -- end
end

function UIEmFight:IsPasvPartActive()
    if self._noNeedAskTreasure[self._combatType] then return false end

    local isOpen = gModelFunctionOpen:CheckIsShow(17404100)
    if not isOpen then return false end

    return true
end
------------------------- List -------------------------

-- function UIEmFight:CheckCurHeroIsSel(itemdata)
--     local combatType = self._combatType
--     if combatType == LCombatTypeConst.COMBAT_TYPE_33 then
--         return self:CheckIsHeroIdIsSelByIndex(itemdata.id)
--     end
--     return true
-- end


function UIEmFight:GetHeroIconTrans(item)
    return self:FindWndTrans(item,"Hero/HeroIcon")
end

function UIEmFight:SetCntByIndex(newCnt,index)
    local battleTeamData = self:GetBattleTeamFormationDataByIndex(index)
    battleTeamData.cnt = newCnt
end

function UIEmFight:OnDrawSkillInfoCell(list,item,itemdata,itempos)
    local IconTrans = self:FindWndTrans(item,"Icon")
    local AddImgTrans = self:FindWndTrans(item,"AddImg")
    local LockImgTrans = self:FindWndTrans(item,"LockImg")

    local refId = itemdata.refId
    local index = itemdata.index

    -- local isOpen = gModelTreasure:CheckTreaPosOpen(ModelTreasure.TYPE_SKILLTYPE_ZHUDONG,index)
    local isOpen =false
    -- local isHaveSkill = refId and refId > 0
    -- if isHaveSkill then
    --     local iconPath = gModelTreasure:GetTreasureSkillIconBySkillRefId(refId)
    --     self:SetWndEasyImage(IconTrans,iconPath)
    -- end
    if not isOpen then
        CS.ShowObject(IconTrans,false)
        CS.ShowObject(AddImgTrans,false)
        CS.ShowObject(LockImgTrans,true)
    -- else
    --     CS.ShowObject(IconTrans,isHaveSkill)
    --     CS.ShowObject(AddImgTrans,not isHaveSkill)
    --     CS.ShowObject(LockImgTrans,false)
    end
end

function UIEmFight:OnClickPassiveSkillsBtnFunc()
    if gModelFormation:CheckTreasureNotUse(self._combatType,true) then return end

    local pasvList = self:GetPasvListByIndex()
    local skillIdList = {}
    for i = 1,4 do
        if pasvList[i] then
            skillIdList[i] = pasvList[i]
        end
    end
    local para = {
        wndType = 3,
        treasureSkilIds = skillIdList,
        combatType = self._combatType,
        idRecord = {},
        func = function(list)
            if self:IsWndClosed() then return end
            self:SetPasvListByPbAndIndex(list)
        end
    }
    self:OpenSelBattleTreasure(para)
end

function UIEmFight:InitTouchEvent()

    local op = LGameTouch.TOUCH_UI
    local wndName = self:GetWndName()
    gLGameTouch:TouchRegister(op,LGameTouch.TOUCH_EVT_START,function (screenPos)
        local touchObject = YXTouchManager.EventSystemRaycastGameObject(screenPos)
        if touchObject then
            local path = LxUiHelper.GetRelativePath(wndName,touchObject.transform)
            if string.find(path,"FormationBtn") or string.find(path,"FormationBg") then
            else
                self:HideFormationBg()
            end
        else
            self:HideFormationBg()
        end
    end)
end

function UIEmFight:OnDrawFormationCell(list,item,itemdata,itempos)
    local formationTrans = self:FindWndTrans(item,"formation")
    local iconTrans = self:FindWndTrans(formationTrans,"icon")
    local nameTrans = self:FindWndTrans(formationTrans,"name")
    local selectTrans = self:FindWndTrans(formationTrans,"select")
    local lockTrans = self:FindWndTrans(formationTrans,"lock")

    self:SetWndEasyImage(iconTrans,itemdata.icon)
    self:SetWndText(nameTrans,itemdata.name)
    CS.ShowObject(lockTrans,itemdata.isLock)

    local isSel = self:CheckFormationTypeIsSel(itemdata)
    CS.ShowObject(selectTrans,isSel)

    self:SetWndClick(formationTrans,function()
        self:OnClickFormationCellFunc(itemdata)
    end,LSoundConst.CLICK_BUTTON_COMMON)
end

function UIEmFight:RefreshBotToggle()
    local showBotToggleInfo = self:GetBotToggleInfo()
    if not showBotToggleInfo then
        CS.ShowObject(self.mMainBotToggleDiv,false)
        return
    end

    local getInitStatusFunc = showBotToggleInfo.getInitStatusFunc
    if getInitStatusFunc then
        local recordStatus = getInitStatusFunc()
        self:SetBotToggleStatus(recordStatus)
    end

    self:RefreshBotToggleDesc(showBotToggleInfo)
    self:RefreshBotToggleSelStatus(showBotToggleInfo)

    self:SetWndClick(self.mMainBotToggleBtn,function()
        self:OnClickMainBotToggleBtnFunc()
    end)

    CS.ShowObject(self.mMainBotToggleDiv,true)
end

function UIEmFight:GetCntByIndex(index)
    local battleTeamData = self:GetBattleTeamFormationDataByIndex(index)
    return battleTeamData.cnt
end

function UIEmFight:InitStatus()
    self._sendMsg = false
    self._isOnClickResetBtn = false
    self._isCombat = false
end

function UIEmFight:CheckIsHeroIdIsSelByIndex(id,index)
    index = index or self._curTeam
    local idToIndex = self:GetIdToIndexByIndex(index)
    return idToIndex and idToIndex[id] ~= nil
end

function UIEmFight:GetPasvListByIndex(index)
    local battleTeamData = self:GetBattleTeamFormationDataByIndex(index)
    return battleTeamData.pasvList
end

function UIEmFight:OnClickFormationBtnFunc()
    self._showFormation = not self._showFormation
    CS.ShowObject(self.mFormationBg,self._showFormation)
end

function UIEmFight:HideFormationBg()
    if not self._showFormation then return end
    self._showFormation = not self._showFormation
    CS.ShowObject(self.mFormationBg,self._showFormation)
end

function UIEmFight:RefreshActivityBox()
--[[    local activityDataList = self:GetActivityDataList() or {}
    local box1PageData = activityDataList[ModelFairCompete.TYPE_BOX_1] or {}
    local box1RewardList = gModelFairCompete:GetBox1RewardList(box1PageData)
    local len = #box1RewardList
    self:SetWndText(self.mActivityBoxNum,len)]]
    -- local win = 0
    -- local sid = self._sid
    -- if sid then
    --     win = gModelFairCompete:GetFairCompeteDataInfoResultWinBySid(sid)
    -- end
    -- self:SetWndText(self.mActivityBoxNum,win)
end

function UIEmFight:InitText()
    self:SetWndText(self.mActivityReSetGameDesc,ccClientText(37503))
    self:SetWndText(self.mActivityBoxName,ccClientText(37500))

    self:SetTopRightBtnName(self.mShareBtn,ccClientText(37504))
    self:SetTopRightBtnName(self.mSquadsBtn,ccClientText(37505))
    self:SetTopRightBtnName(self.mReportBtn,ccClientText(37506))
    self:SetTopRightBtnName(self.mRuleBtn,ccClientText(37507))
    self:SetTopRightBtnName(self.mShopBtn,ccClientText(37570))
end

function UIEmFight:GetActivityData()
    return self._activityData
end


function UIEmFight:UpdataRequiredHero(id,effId)
    if not id then return end
    local requiredHeroMap = self._requiredHeroMap or {}
    if requiredHeroMap[id] and not self:CheckIsHeroIdIsSelByIndex(id) then
        local pos,fullStatus = self:GetEmptyPosToIdByIndex()
        if not fullStatus then
            self:SetIdToIndexByIdAndPosFromIndex(id,pos,UIEmFight.TYPE_OPTHERO_UP)
            FireEvent(EventNames.Scene_Hero_GoTo, effId, pos, true, true)
        end
    end
end

function UIEmFight:NeedAskPasv()
    -- if not self:IsPasvPartActive() then return false end

    -- local pasvList = self:GetPasvListByIndex()
    -- local upSkillNum = 0
    -- local idRecord = {}
    -- for k,v in pairs(pasvList) do
    --     if v ~= 0 then
    --         upSkillNum = upSkillNum + 1
    --         idRecord[v] = true
    --     end
    -- end
    -- local canUpNum = gModelTreasure:GetPasvUnLockNum() - upSkillNum
    -- local canUpTreasureList = gModelTreasure:GetPasvSkillList(idRecord)
    -- local canLen = #canUpTreasureList ---还剩几个宝物
    -- canUpNum = math.min(canUpNum,canLen)
    -- if canUpNum <= 0  then return false end

    return false
end
------------------------- List -------------------------

------------------------------------------------------------------
return UIEmFight


