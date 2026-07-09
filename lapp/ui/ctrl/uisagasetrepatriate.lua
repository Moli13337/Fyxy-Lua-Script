---
--- Created by LCM.
--- DateTime: 2024/3/27 15:53:33
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UISagaSetRepatriate:LWnd
local UISagaSetRepatriate = LxWndClass("UISagaSetRepatriate", LWnd)

--- 默认遣返
UISagaSetRepatriate.DEFAULT_STAR = 3

UISagaSetRepatriate.TYPE_OPT_SUB = -1
UISagaSetRepatriate.TYPE_OPT_ADD = 1

UISagaSetRepatriate.TYPE_RACE_SET_MAX = 99999

UISagaSetRepatriate.TYPE_INFO_CONCAT = "|"
UISagaSetRepatriate.TYPE_DATA_CONCAT = "="

------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISagaSetRepatriate:UISagaSetRepatriate()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISagaSetRepatriate:OnWndClose()
    local list = {}
    local raceSaveNum, raceType
    local recordRaceNumMap = self._recordRaceNumMap or {}
    local heroSacrificeSetList = self._heroSacrificeSetList or {}
    for k, v in ipairs(heroSacrificeSetList) do
        raceType = v.race
        raceSaveNum = recordRaceNumMap[raceType] or 0
        table.insert(list, tostring(raceType) .. UISagaSetRepatriate.TYPE_DATA_CONCAT .. tostring(raceSaveNum))
    end
    local str = table.concat(list, UISagaSetRepatriate.TYPE_INFO_CONCAT)
    if LOG_INFO_ENABLED then
        printInfoNR("本地缓存的数据：" .. str)
    end
    LPlayerPrefs.SetHeroSacrificeSet(str)

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISagaSetRepatriate:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISagaSetRepatriate:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:RefreshView()
end

function UISagaSetRepatriate:InitMaxList(list)
    local uiMaxList = self._uiMaxList
    if uiMaxList then
        uiMaxList:RefreshList(list)
    else
        uiMaxList = self:GetUIScroll("uiMaxList")
        self._uiMaxList = uiMaxList
        uiMaxList:Create(self.mMaxList, list, function(...)
            self:OnDrawCommonIconCell(...)
        end, UIItemList.WRAP)
    end
end

function UISagaSetRepatriate:GetHeroRewardList(selHeroList)
    selHeroList = selHeroList or {}
    local starRef, sacrificeGetItem
    local itemList = {}
    local data
    local refId
    for i, v in ipairs(selHeroList) do
        refId = v.refId
        starRef = gModelHero:GetHeroStarRef(refId, nil, v.star)
        if starRef then
            sacrificeGetItem = LUtil.ConvertCommonItemStrToList(starRef.sacrificeGetItem)
            for idx, val in ipairs(sacrificeGetItem) do
                table.insert(itemList, val)
            end
            data = gModelHero:GetPayItemNum({
                lv = v.lv,
                grade = v.grade,
                refId = refId,
            })
            for idx, val in ipairs(data) do
                table.insert(itemList, {
                    itemType = LItemTypeConst.TYPE_ITEM,
                    itemId = val.refId,
                    itemNum = val.num,
                })
            end
        end
    end
    local list = LUtil.GetSortItemAllAddNumList(itemList)
    return list
end

function UISagaSetRepatriate:GetAutoSelHeroList()
    local saveHeroSacrificeStar = self._saveHeroSacrificeStar
    local raceRepatriateList = self:GetRaceRepatriateList()
    local star
    local raceSaveNum, repatriateNum, otherStarNum, heroSacrificeStarNum
    local selHeroList = {}
    for i, v in ipairs(raceRepatriateList) do
        repatriateNum = v.repatriateNum
        if repatriateNum > 0 then
            --- 保留数量
            raceSaveNum = v.raceSaveNum

            --- 共有的数量
            heroSacrificeStarNum = v.heroSacrificeStarNum
            local startInsNum = 0
            local heroList = v.heroList
            for idx, val in ipairs(heroList) do
                if startInsNum >= repatriateNum then
                    break
                end
                star = val.star
                if star == saveHeroSacrificeStar then
                    if raceSaveNum < heroSacrificeStarNum then
                        table.insert(selHeroList, val)
                        startInsNum = startInsNum + 1
                    end
                else
                    table.insert(selHeroList, val)
                    startInsNum = startInsNum + 1
                end
            end
        end
    end
    return selHeroList
end

function UISagaSetRepatriate:OnDrawRaceRepatriateCell(list, item, itemdata, itempos)
    local RaceIconTrans = self:FindWndTrans(item, "RaceIcon")
    local RaceNameTrans = self:FindWndTrans(item, "RaceName")

    local NumInputTrans = self:FindWndTrans(item, "NumInput")
    local NumTxtTrans = self:FindWndTrans(NumInputTrans, "NumTxt")

    local SubBtnRootTrans = self:FindWndTrans(NumInputTrans, "SubBtnRoot")
    local SubBtnTrans = self:FindWndTrans(SubBtnRootTrans, "SubBtn")

    local AddBtnRootTrans = self:FindWndTrans(NumInputTrans, "AddBtnRoot")
    local AddBtnTrans = self:FindWndTrans(AddBtnRootTrans, "AddBtn")

    local RaceRepatriateNumTrans = self:FindWndTrans(item, "RaceRepatriateNum")

    local raceType = itemdata.raceType
    local raceRef = gModelHero:GetHeroRaceRefByRefId(raceType)
    if raceRef then
        self:SetWndEasyImage(RaceIconTrans, raceRef.icon, function()
            CS.ShowObject(RaceIconTrans, true)
        end, true)
        self:SetWndText(RaceNameTrans, ccLngText(raceRef.name))
    end

    self:SetWndText(NumTxtTrans, itemdata.inputNum)
    self:SetWndText(RaceRepatriateNumTrans, itemdata.repatriateNum)

    self:SetWndClick(SubBtnTrans, function()
        self:OnClickSubBtnFunc(itemdata)
    end)

    self:SetWndClick(AddBtnTrans, function()
        self:OnClickAddBtnFunc(itemdata)
    end)

    self:SetWndClick(NumInputTrans, function()
        self:OnClickNumInputFunc(itemdata, NumInputTrans, NumTxtTrans)
    end)
end

function UISagaSetRepatriate:RefreshView()
    self:InitRaceRepatriateList()
end

function UISagaSetRepatriate:InitMinList(list)
    local uiMinList = self._uiMinList
    if uiMinList then
        uiMinList:RefreshList(list)
    else
        uiMinList = self:GetUIScroll("uiMinList")
        self._uiMinList = uiMinList
        uiMinList:Create(self.mMinList, list, function(...)
            self:OnDrawCommonIconCell(...)
        end)
    end
end

function UISagaSetRepatriate:OnClickAddBtnFunc(itemdata)
    local heroSetMax = self:GetHeroSetMaxNum(itemdata)
    if not heroSetMax then
        return
    end

    local raceType = itemdata.raceType
    local newRaceSaveNum = itemdata.inputNum + 1
    if newRaceSaveNum > heroSetMax then
        return
    end
    self._recordRaceNumMap[raceType] = newRaceSaveNum
    self:InitRaceRepatriateList()
end

function UISagaSetRepatriate:OnClickNumInputFunc(itemdata, FollowRootTrans, NumTxtTrans)
    local heroSetMax = self:GetHeroSetMaxNum(itemdata)
    if not heroSetMax then
        return
    end

    local raceType = itemdata.raceType
    local tab = {}
    tab.inputTran = FollowRootTrans
    tab.minNum = 0
    tab.maxNum = heroSetMax
    tab.defaultNum = itemdata.inputNum
    tab.inputFunc = function(numStr, cmd)
        if self:IsWndClosed() then
            return
        end
        local num = tonumber(numStr)
        if num then
            if cmd == "C" then
                self:SetWndText(NumTxtTrans, 0)
            elseif cmd == "D" then
                if num > heroSetMax then
                    num = heroSetMax
                end
                self:SetWndText(NumTxtTrans, num)
                self._recordRaceNumMap[raceType] = num
                self:InitRaceRepatriateList()
            else
                self:SetWndText(NumTxtTrans, num)
            end
        end
    end
    GF.OpenWndUp("UINuoardUI", tab)
end

function UISagaSetRepatriate:InitEvent()
    self:SetWndClick(self.mMask, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCloseBtn, function()
        self:WndClose()
    end, LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mRepatriateBtn, function()
        self:OnClickRepatriateBtnFunc()
    end)
end

function UISagaSetRepatriate:GetHeroSetMaxNum(itemdata)
    local recordRaceNumMap = self._recordRaceNumMap
    if not recordRaceNumMap then
        return UISagaSetRepatriate.TYPE_RACE_SET_MAX
    end
    local raceType = itemdata.raceType
    local heroSacrificeSetMaxMap = self._heroSacrificeSetMaxMap
    local heroSetMax = heroSacrificeSetMaxMap[raceType] or UISagaSetRepatriate.TYPE_RACE_SET_MAX
    return heroSetMax
end

function UISagaSetRepatriate:InitHeroData()
    local recordRaceNumMap = self._recordRaceNumMap
    local heroSacrificeStar = self._heroSacrificeStar
    local tRace
    local recordRaceMap = self._recordRaceMap
    local recordHeroStatusList = {}
    local raceTypeHeroList = {}
    local heroList = gModelHero:GetHeroList()
    for k, v in pairs(heroList) do
        tRace = gModelHero:GetHeroRace(v:GetRefId())
        if recordRaceMap[tRace] then
            local raceTypeHeroInfo = raceTypeHeroList[tRace]
            if not raceTypeHeroInfo then
                raceTypeHeroInfo = {}
                raceTypeHeroList[tRace] = raceTypeHeroInfo
            end
            if v:GetStar() <= heroSacrificeStar then
                if v:GetStatus() == 0 then
                    if recordRaceMap[tRace] then
                        table.insert(raceTypeHeroInfo, v:GetServerData())
                    end
                else
                    table.insert(recordHeroStatusList, v:GetId())
                end
            end
        end
    end

    for k, v in pairs(recordRaceNumMap) do
        if not raceTypeHeroList[k] then
            raceTypeHeroList[k] = {}
        end
    end

    if #recordHeroStatusList > 0 then
        if LOG_INFO_ENABLED then
            printInfoNR("符合条件但是有状态的英雄，不加入到列表中：" .. table.concat(recordHeroStatusList, ","))
        end
    end

    local sortFunc = function(a, b)
        local statusA, statusB = a.status, b.status
        if statusA ~= statusB then
            return statusA < statusB
        end

        if statusA == statusB and statusA == 1 then
            local isCombatA, isCombatB = a.isCombat, b.isCombat
            if isCombatA ~= isCombatB then
                return isCombatA > isCombatB
            end

            local lockA, lockB = a.lock, b.lock
            if lockA ~= lockB then
                return lockA > lockB
            end

            local isResonanceA, isResonanceB = a.isResonance, b.isResonance
            if isResonanceA ~= isResonanceB then
                return isResonanceA > isResonanceB
            end
        end

        local starA, starB = a.star, b.star
        if starA ~= starA then
            return starA < starB
        end

        local lvA, lvB = a.lv, b.lv
        if lvA ~= lvB then
            return lvA < lvB
        end

        local refIdA, refIdB = a.refId, b.refId
        if refIdA ~= refIdB then
            return refIdA < refIdB
        end

        local fightPowerA, fightPowerB = a.fightPower, b.fightPower
        if fightPowerA ~= fightPowerB then
            return fightPowerA < fightPowerB
        end

        return a.id > b.id
    end

    local saveHeroSacrificeStar = self._saveHeroSacrificeStar
    local sortRaceTypeHeroList = {}
    for k, list in pairs(raceTypeHeroList) do
        table.sort(list, sortFunc)

        local heroSacrificeStarNum = 0
        local otherStarNum = 0
        for i, v in ipairs(list) do
            if v.star == saveHeroSacrificeStar then
                heroSacrificeStarNum = heroSacrificeStarNum + 1
            else
                otherStarNum = otherStarNum + 1
            end
        end
        table.insert(sortRaceTypeHeroList, {
            raceType = k,
            heroList = list,
            otherStarNum = otherStarNum,
            heroSacrificeStarNum = heroSacrificeStarNum,
        })
    end
    table.sort(sortRaceTypeHeroList, function(a, b)
        local sortA = recordRaceMap[a.raceType] or 0
        local sortB = recordRaceMap[b.raceType] or 0
        return sortA < sortB
    end)
    self._raceTypeHeroList = raceTypeHeroList
    self._sortRaceTypeHeroList = sortRaceTypeHeroList
end

function UISagaSetRepatriate:InitRaceRepatriateList()
    local list = self:GetRaceRepatriateList()
    local uiRaceRepatriateList = self._uiRaceRepatriateList
    if uiRaceRepatriateList then
        uiRaceRepatriateList:RefreshList(list)
    else
        uiRaceRepatriateList = self:GetUIScroll("uiRaceRepatriateList")
        self._uiRaceRepatriateList = uiRaceRepatriateList
        uiRaceRepatriateList:Create(self.mRaceRepatriateList, list, function(...)
            self:OnDrawRaceRepatriateCell(...)
        end)
    end
    self:RefreshHeroReward()
end
------------------------- List -------------------------

function UISagaSetRepatriate:GetRaceRepatriateList()
    local list = {}

    local saveHeroSacrificeStar = self._saveHeroSacrificeStar
    local recordRaceNumMap = self._recordRaceNumMap or {}
    local sortRaceTypeHeroList = self._sortRaceTypeHeroList or {}
    local raceType, raceSaveNum, heroList, heroSacrificeStarNum, inputNum
    for i, v in ipairs(sortRaceTypeHeroList) do
        raceType = v.raceType
        inputNum = recordRaceNumMap[raceType] or 0
        raceSaveNum = inputNum
        heroList = v.heroList or {}
        heroSacrificeStarNum = v.heroSacrificeStarNum
        if raceSaveNum > heroSacrificeStarNum then
            raceSaveNum = heroSacrificeStarNum
        end
        local len = #heroList
        local repatriateNum = len - raceSaveNum
        if repatriateNum < 0 then
            repatriateNum = 0
        end
        if LOG_INFO_ENABLED then
            local retNum = heroSacrificeStarNum - raceSaveNum
            local ret3StarNum = heroSacrificeStarNum - retNum
            if retNum < 0 then
                retNum = 0
                ret3StarNum = retNum
            end
            printInfoNR("打印而已，莫慌    种族：" .. raceType .. "，该种族拥有的英雄数量：" .. len .. "，输入保留的数量：" .. inputNum .. "，3星总数量：" .. heroSacrificeStarNum ..
                    "，实际保留3星数量：" .. ret3StarNum .. "，被遣返3星数量：" .. retNum .. "，遣返总数量：" .. repatriateNum)
        end

        if not (raceType == 4 or raceType == 5) then
            table.insert(list, {
                raceType = raceType,
                raceSaveNum = raceSaveNum,
                inputNum = inputNum,
                repatriateNum = repatriateNum,
                repatriateAllNum = len,
                heroList = heroList,
                otherStarNum = v.otherStarNum,
                heroSacrificeStarNum = heroSacrificeStarNum,
            })

        end
    end
    return list
end

function UISagaSetRepatriate:OnClickSubBtnFunc(itemdata)
    local recordRaceNumMap = self._recordRaceNumMap
    if not recordRaceNumMap then
        return
    end
    local newRaceSaveNum = itemdata.inputNum - 1
    if newRaceSaveNum < 0 then
        return
    end
    local raceType = itemdata.raceType
    self._recordRaceNumMap[raceType] = newRaceSaveNum
    self:InitRaceRepatriateList()
end

function UISagaSetRepatriate:OnClickRepatriateBtnFunc()
    if self._sendMsg then
        return
    end

    local selHeroList = self:GetAutoSelHeroList()
    local selHeroNum = #selHeroList
    if selHeroNum < 1 then
        GF.ShowMessage(ccClientText(14462))
        return
    end

    if LOG_INFO_ENABLED then
        local saveHeroSacrificeStar = self._saveHeroSacrificeStar
        local saveNum = 0
        local otherNum = 0
        for i, v in ipairs(selHeroList) do
            if v.star == saveHeroSacrificeStar then
                saveNum = saveNum + 1
            else
                otherNum = otherNum + 1
            end
        end
        printInfoNR("打印而已，莫慌          其他星级的数量 = " .. otherNum .. ",3星遣返数量 = " .. saveNum)
    end

    local list = self:GetHeroRewardList(selHeroList)
    local selHeroMap = {}
    for i, v in ipairs(selHeroList) do
        selHeroMap[v.id] = v
    end
    local func = function()
        self._sendMsg = true
        gModelHero:OnHeroSacrificeReq(selHeroMap)
        FireEvent(EventNames.ON_HERO_SACRIFICE)
    end
    gModelGeneral:OpenUIOrdinTips({ func = func, refId = 50903, itemList = list, para = { selHeroNum } })
end

------------------------- List -------------------------
--重连
function UISagaSetRepatriate:OnTcpReconnect()
    self._sendMsg = false
    self:InitData()
    self:RefreshView()
end

function UISagaSetRepatriate:InitText()
    self:SetWndButtonText(self.mRepatriateBtn, ccClientText(14459))
    self:SetWndText(self.mSaveStarNumDesc, ccClientText(14455))
    self:SetWndText(self.mRepatriateStarNumDesc, ccClientText(14456))
    self:SetWndText(self.mRaceRepatriateDesc, ccClientText(14457))
    self:SetWndText(self.mEmptyTxt, ccClientText(14461))
    self:SetTextTile(self.mTitleTxt, ccClientText(14454))
    self:SetTextTile(self.mRewardTxt, ccClientText(14458))
end

function UISagaSetRepatriate:OnDrawCommonIconCell(list, item, itemdata, itempos)
    local CommonUITrans = self:FindWndTrans(item, "CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans, "Icon")

    local instanceID = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceID)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemdata.itemType, itemdata.itemId, itemdata.itemNum)
    baseClass:DoApply()
end

function UISagaSetRepatriate:OnHeroSacrificeResp(pb)
    self._sendMsg = false
    --[[    self:InitHeroData()
        self:RefreshView()]]
    self:WndClose()
end

function UISagaSetRepatriate:InitData()
    local heroSacrificeStar = gModelHero:GeConfigByKey("heroSacrificeStar")
    if not heroSacrificeStar then
        heroSacrificeStar = UISagaSetRepatriate.DEFAULT_STAR
    end
    self._heroSacrificeStar = heroSacrificeStar

    local saveHeroSacrificeStar = gModelHero:GeConfigByKey("saveHeroSacrificeStar")
    if not saveHeroSacrificeStar then
        --- 需要保留的星级
        saveHeroSacrificeStar = UISagaSetRepatriate.DEFAULT_STAR
    end
    self._saveHeroSacrificeStar = saveHeroSacrificeStar

    local heroSacrificeSet = LPlayerPrefs.heroSacrificeSet
    if string.isempty(heroSacrificeSet) then
        heroSacrificeSet = gModelHero:GeConfigByKey("heroSacrificeSet")
    end
    heroSacrificeSet = string.split(heroSacrificeSet, UISagaSetRepatriate.TYPE_INFO_CONCAT)
    self._heroSacrificeSet = heroSacrificeSet

    local heroSacrificeSetList = {}
    local tRace
    local recordRaceMap = {}
    local recordRaceNumMap = {}
    for i, v in ipairs(heroSacrificeSet) do
        v = string.split(v, UISagaSetRepatriate.TYPE_DATA_CONCAT)
        tRace = tonumber(v[1])
        recordRaceMap[tRace] = i
        recordRaceNumMap[tRace] = tonumber(v[2])
        table.insert(heroSacrificeSetList, {
            race = tRace,
            saveNum = tonumber(v[2]),
        })
    end
    self._recordRaceMap = recordRaceMap
    self._recordRaceNumMap = recordRaceNumMap
    self._heroSacrificeSetList = heroSacrificeSetList

    self:InitHeroData()

    local heroSacrificeSetMaxMap = {}
    local heroSacrificeSetMax = gModelHero:GeConfigByKey("heroSacrificeSetMax")
    if not heroSacrificeSetMax then
        heroSacrificeSetMax = "1=99999|2=99999|3=99999|4=99999|5=99999"
    end
    heroSacrificeSetMax = string.split(heroSacrificeSetMax, UISagaSetRepatriate.TYPE_INFO_CONCAT)
    for i, v in ipairs(heroSacrificeSetMax) do
        v = string.split(v, UISagaSetRepatriate.TYPE_DATA_CONCAT)
        heroSacrificeSetMaxMap[tonumber(v[1])] = tonumber(v[2])
    end
    self._heroSacrificeSetMaxMap = heroSacrificeSetMaxMap
end

function UISagaSetRepatriate:InitMsg()
    self:WndNetMsgRecv(LProtoIds.HeroSacrificeResp, function(pb, ret)
        self:OnHeroSacrificeResp(pb)
    end)

    -- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
    -- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UISagaSetRepatriate:RefreshHeroReward()
    local selHeroList = self:GetAutoSelHeroList()
    local list = self:GetHeroRewardList(selHeroList)
    local listLen = #list
    local showMin = listLen <= 5
    local showListTrans = showMin and self.mMinList or self.mMaxList
    local hideListTrans = showMin and self.mMaxList or self.mMinList
    CS.ShowObject(showListTrans, true)
    CS.ShowObject(hideListTrans, false)
    if showMin then
        self:InitMinList(list)
    else
        self:InitMaxList(list)
    end
    CS.ShowObject(self.mEmptyTxt, listLen < 1)
end
------------------------------------------------------------------
return UISagaSetRepatriate



