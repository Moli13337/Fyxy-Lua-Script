---
--- Created by Administrator.
--- DateTime: 2024/3/11 14:31:25
---
------------------------------------------------------------------
local LChildWnd = LChildWnd
---@class UISubOuttsPVE:LChildWnd
local UISubOuttsPVE = LxWndClass("UISubOuttsPVE", LChildWnd)  --对应页面UIDTDNew
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UISubOuttsPVE:UISubOuttsPVE()
    self._timeList = {}
    self._timeKey = "dungeonDailyTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UISubOuttsPVE:OnWndClose()
    LChildWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UISubOuttsPVE:OnCreate()
    LChildWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UISubOuttsPVE:OnStart()
    LChildWnd.OnStart(self)
    self:InitUI()

    self:InitMessage()
    self:InitOutskirtsPVE()
    self:InitCommand()

end

--开计时器
function UISubOuttsPVE:OnTimer(key)
    if (self._timeKey == key) then
        self:SetTime()
    end
end

function UISubOuttsPVE:GetEndlesText2(text1, text2, str)
    if text2 == "" then
        return ""
    end
    local text = ""
    if text2 == "0" then
        text = ccClientText(12819)
    else
        text = ccClientText(12818)
    end
    return string.replace(str, text)
end

function UISubOuttsPVE:CreateListItem(list, item, itemdata, itempos)
    --节点名字

    item.name = "item_"..itemdata.functionId

    --背景
    local bg = self:FindWndTrans(item, "Bg")
    self:SetWndEasyImage(bg, itemdata.bg)
    --名字
    local title = self:FindWndTrans(item, "Title")
    self:SetWndText(title, ccLngText(itemdata.name))

    --是否开启
    local functionId = itemdata.functionId
    local isOpen = gModelFunctionOpen:CheckIsOpened(functionId, false)

    local refId, timeTextR, text1, text2 = itemdata.refId, ccLngText(itemdata.timeText), ccLngText(itemdata.text1), ccLngText(itemdata.text2)
    --时间
    local timeTitle = self:FindWndTrans(item, "time_Title")
    -- 等级
    local lv_Title = self:FindWndTrans(item, "lv_Title")
    -- 已通关
    local StateImg = self:FindWndTrans(item, "StateImg")
    local StateTxt = self:FindWndTrans(StateImg, "StateTxt")
    local NotOpenDiv = self:FindWndTrans(item, "NotOpenDiv")
    --信息——1  Info_Bg
    local infoRoot = self:FindWndTrans(item, "Info_Bg")
    local info_1_Title = self:FindWndTrans(infoRoot, "Info_1_Title")
    --信息--2
    local info_2_Title = self:FindWndTrans(infoRoot, "Info_2_Title")

    local lockStr, passStr
    local showLock = false
    local lvStr = ""
    local showPass = false

    CS.ShowObject(infoRoot, true)
    if isOpen then
        local funcList = gModelDailyGameEnter:GetItemInfoFunc(refId)
        if funcList then

            local text1Str
            if funcList.text1 then
                text1Str = string.replace(text1, funcList.text1())
            end

            local text2StrMaxCount, text2StrLeftCount
            if funcList.text2 then
                text2StrMaxCount, text2StrLeftCount = funcList.text2()
            end
            local text2Str = string.replace(text2, text2StrLeftCount, text2StrMaxCount)

            self:SetWndText(info_1_Title, text1Str)
            self:SetWndText(info_2_Title, text2Str)

            local timeStr
            if funcList.timeText then
                timeStr = string.replace(timeTextR, LUtil.FormatTimespanCn(funcList.timeText()))
            end

            timeStr = self:GetResidueTimeByRefId(itemdata.refId, timeTextR)
            if string.isempty(timeStr) then
                if funcList.timeText_Over then
                    timeStr = funcList.timeText_Over()
                end
            end

            self:SetWndText(timeTitle, timeStr)
            self._timeList[itemdata.refId] = { text = timeTitle, str = timeTextR, isFuncList = true, timeStrFunc = funcList.timeStrFunc }

            CS.ShowObject(infoRoot, funcList.isHaveData())

            if funcList.showLock then
                showLock = funcList.showLock()
            end
            if funcList.lockStr then
                lockStr = funcList.lockStr()
            end
            if funcList.showPass then
                showPass, passStr = funcList.showPass()
            end
        else
            local info = self._infoList and self._infoList[refId]
            local timeStr = gModelDungeonDaily:GetResidueTimeByRefId(itemdata, info)
            local showTime = not string.isempty(timeStr)
            self:SetWndText(timeTitle, timeStr)
            CS.ShowObject(timeTitle, showTime)
            self._timeList[refId] = {
                text = timeTitle,
                str = timeTextR,
                ref = itemdata,
                info = info,
                isFuncList = false
            }

            local text1Str = gModelDungeonDaily:GetText1ByRefId(itemdata, info)
            local text2Str = gModelDungeonDaily:GetText2ByRefId(itemdata, info)

            self:SetWndText(info_1_Title, text1Str)
            self:SetWndText(info_2_Title, text2Str)
            showPass = gModelDungeonDaily:GetGamePlayIsPass(itemdata, info)
            if showPass then
                passStr = ccClientText(41415)
            end
            showLock = gModelDungeonDaily:CheckGamePlayIsLock(itemdata, info)
            if showLock then
                lockStr = gModelDungeonDaily:GetGamePlayLockStr(itemdata)

                --- 梦境之旅未开放时要求这里显示文字
                showPass = true
                passStr = lockStr
            end
            lvStr = gModelDungeonDaily:GetGamePlayLv(itemdata, info)

            if string.isempty(text1Str) then
                CS.ShowObject(infoRoot, false)
            end
        end
    end

    if showPass then
        self:SetWndText(StateTxt, passStr)
    end
    CS.ShowObject(StateImg, showPass)
    CS.ShowObject(NotOpenDiv, showLock)

    self:SetWndText(lv_Title, lvStr)

    if nil == self._timeList then
        self._timeList = {}
    end


    --lock--锁的部分
    local lockRoot = self:FindWndTrans(item, "Lock")
    --是否开启的锁
    local openLock = self:FindWndTrans(lockRoot, "OpenLock")
    local openLockText = self:FindWndTrans(openLock, "UIText")

    local notOpen = not isOpen
    CS.ShowObject(lockRoot, notOpen)
    CS.ShowObject(openLock, notOpen)

    if notOpen then
        local text = gModelFunctionOpen:GetOpenTips(functionId)
        self:SetWndText(openLockText, text)
        self:SetWndClick(item, function()
            if showLock then
                GF.ShowMessage(lockStr)
            else
                gModelFunctionOpen:CheckIsOpened(functionId, true)
            end
        end)
    end

    --是否其他状态的锁
    local otherStateLock = self:FindWndTrans(lockRoot, "OtherStateLock")
    local stateLockText = self:FindWndTrans(otherStateLock, "UIText")

    local isRun = self:ShowRunMask(itemdata)

    if isRun then
        CS.ShowObject(lockRoot, isRun)
        CS.ShowObject(otherStateLock, isRun)
        self:SetWndText(stateLockText, ccClientText(24212))
    end

    if notOpen then
        return
    end

    --红点
    local redTran = self:FindWndTrans(item, "redPoint")

    if redTran then
        self._specialRedTran = self._specialRedTran or {}
        if refId == 109 then

            local data = {}
            data.redtran = redTran
            data.func = function()
                local typeList = gModelDungeonDaily:GetTypeConfig()
                local isRed = false
                for k, v in ipairs(typeList) do
                    local isShow = false
                    local isFreeGetRedpoint = gModelDungeonDaily:CheckShowDungeonRed_New_1(k)
                    local isNewChallenge = gModelDungeonDaily:CheckShowDungeonRed_New_2(k)

                    isShow = isFreeGetRedpoint

                    if not isShow then
                        isShow = isNewChallenge
                    end

                    isRed = isShow

                    if isRed then
                        break
                    end
                end
                return isRed
            end

            CS.ShowObject(data.redtran, data.func())

            self._specialRedTran[refId] = data
        elseif refId == 110 then
            local data = {}
            data.redtran = redTran
            data.func = function()
                return gModelFish:HadRed()
            end
            CS.ShowObject(data.redtran, data.func())

            self._specialRedTran[refId] = data
        else
            self:RegisterFuncItemRed(functionId, redTran)
        end
    end

    --点击方法
    self:SetWndClick(item, function()
        --  GF.ShowMessage("打开了" .. itemdata.functionId .. "对应的功能和方法")

        if gModelFunctionOpen:CheckIsOpened(functionId, true) then
            if functionId == 16400000 then
                local combatList = gModelFunctionOpen:GetFuncRelaCombat(functionId)
                for k, v in pairs(combatList) do
                    if gLFightManager:IsCombatTypeInFight(k) then
                        gLFightManager:PrepareGoToBattle(k, {})
                        return
                    end
                end
                local isOpent = gModelTower:GetIsUnlockRaceTower()
                if not isOpent then
                    GF.OpenWndBottom("UITaWin")
                else
                    GF.OpenWndBottom("UITaRacePopNew")
                end
            elseif functionId == ModelFunctionOpen.DREAMTRIP_ENTER then
                local info = self._infoList and self._infoList[refId]
                if info and not gModelDungeonDaily:CheckGamePlayIsOpen(itemdata, info) then
                    if lockStr then
                        GF.ShowMessage(lockStr)
                    end
                    return
                end
                gModelGeneral:FastDreamTripEntrance()

            elseif functionId == 18201001 then
                local funcList = gModelDailyGameEnter:GetItemInfoFunc(refId)

                if funcList.isHaveData() then
                    gModelFunctionOpen:Jump(functionId)
                else
                    GF.ShowMessage(ccClientText(21075))
                end
            elseif functionId == gModelFish.MainFuncId then
                if gModelFish:IsFishingOpen() then
                    gModelFunctionOpen:Jump(functionId)
                else
                    -- GF.ShowMessage(ccClientText(41414))
                    gModelFunctionOpen:Jump(functionId)
                end
            else
                gModelFunctionOpen:Jump(functionId)
            end
        end
    end)
end

function UISubOuttsPVE:OnDailyGameInfoResp(pb)
    self._infoList = gModelGeneral:GetDailyGameInfoResp(pb)
    self:RefreshData()
end

--是否战斗中
function UISubOuttsPVE:ShowRunMask(itemdata)
    local showRunMask = false
    local isOpen = gModelFunctionOpen:CheckIsOpened(itemdata.functionId, false)
    if isOpen then
        local showDreamTripDiv = false
        local showFightDiv = false
        local refId = itemdata.refId
        if refId == 105 then
            --梦境之旅
            -- 开始梦境之旅，未达终点、不在战斗中时，显示进行状态
            local selHero = gModelDreamTrip:IsSelHero()
            if selHero then
                local isEnd = gModelDreamTrip:IsEndMapIdx()
                if not isEnd then
                    local isFight = gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_DREAMTRIP)
                    if not isFight then
                        showRunMask = true
                    end
                end
            end
        else
            local combatType = itemdata.combatType
            if combatType ~= "" then
                local inFight = false
                local combatTypeArr = string.split(combatType, ",")
                for i, v in ipairs(combatTypeArr) do
                    inFight = gLFightManager:IsCombatTypeInFight(tonumber(v))
                    if inFight then
                        break
                    end
                end
                if inFight then
                    showRunMask = true
                end
            end
        end
    end
    return showRunMask
end

function UISubOuttsPVE:GetWonderText2(text1, text2, str)
    if text2 == "" then
        return string.replace(str, ccClientText(12820))
    end
    return string.replace(str, text2 .. "/" .. ModelWonderland.LAYER)
end

function UISubOuttsPVE:InitPVEList()
    local uiList = self._uiPVEList
    if not uiList then
        uiList = self:GetUIScroll("mPVEList")
        uiList:Create(self.mPVEList, self._PVEListData, function(...)
            self:CreateListItem(...)
        end, UIItemList.SUPER)
    else
        if self._PVEListData then
            uiList:RefreshList(self._PVEListData)
        end
    end
    self._uiPVEList = uiList
end


--region 消息的初始化和回调的处理 --------------------------------------------------------------------------------
function UISubOuttsPVE:InitMessage()
    self:WndNetMsgRecv(LProtoIds.DailyGameInfoResp, function(pb)
        self:OnDailyGameInfoResp(pb)
        --零点过后 重新请求数据后刷新列表
        self:InitPVEList()
    end)

    self:WndEventRecv(EventNames.ON_RED_CHANGE, function(...) self:InitPVEList() end)

    self:WndEventRecv(EventNames.ON_BRAVE_MSG_RET, function(pb)
        self:RefreshSpecialRedPoint()
    end)

    self:WndEventRecv(EventNames.ON_TIME_ZERO, function()
        self:RefreshReq()
        --一些旧有逻辑的 直接重新获取
        self:InitPVEList()
    end)

    self:WndEventRecv(EventNames.ON_BATTLE_END, function()
        self:RefreshData()
    end)

    self:WndEventRecv(EventNames.ON_ENDLESS_FIGHT_STATE, function()
        self:RefreshData()
    end)


end

function UISubOuttsPVE:GetFairyTaleTDText2(text1, text2, str)
    return str
end

function UISubOuttsPVE:GetFairyTaleTDText1(text1, str)
    --local sort = gModelTowerDefence:GetBattleCurrentShowNum() or 0
    --return string.replace(str, tostring(sort))
end

--
function UISubOuttsPVE:RefreshSpecialRedPoint()

    if self._specialRedTran then

        for k, v in pairs(self._specialRedTran) do
            CS.ShowObject(v.redtran, v.func())
        end

    end
end

function UISubOuttsPVE:GetInvasionText1(text1, str)
    if text1 == "" then
        return string.replace(str, ccClientText(12820))
    end
    local ref = ModelInvasion:GetMapRef(tonumber(text1))
    return string.replace(str, ccLngText(ref.bossName))
end
--刷新
function UISubOuttsPVE:RefreshData()
    local itemList = self._uiPVEList
    if itemList then
        --itemList:RefreshList(refList)
        itemList:DrawAllItems(false)
    else
        itemList = self:GetUIScroll("mPVEList")
        itemList:Create(self.mPVEList, self._PVEListData, function(...)
            self:CreateListItem(...)
        end, UIItemList.SUPER)

        self._uiPVEList = itemList
    end
    if not self._bDelaySendFinished then
        self:DelaySendFinish(0.1)
        self._bDelaySendFinished = true
    end

    local isStart = false
    local _timeKey = self._timeKey
    for i, v in pairs(self._timeList) do
        isStart = true
        break
    end
    -- if isStart then
        if not self:IsTimerExist(_timeKey) then
            self:TimerStart(_timeKey, 1, false, -1)
        end
    -- else
    --     self:TimerStop(_timeKey)
    -- end
end

--解析文本 text1 和相关的方法
function UISubOuttsPVE:GetText1ByRefId(refId, str)
    if not self._infoList then
        return ""
    end
    local info = self._infoList[refId]
    local text1 = info and info.text1 or ""
    local funcList = self._funcList
    if not funcList then
        funcList = {
            [102] = function(...)
                return self:GetEndlesText1(...)
            end,
            [103] = function(...)
                return self:GetTimeCorridorText1(...)
            end,
            [104] = function(...)
                return self:GetWonderText1(...)
            end,
            [105] = function(...)
                return self:GetDreamTripText1(...)
            end,
            [107] = function(...)
                return self:GetInvasionText1(...)
            end,
            [108] = function(...)
                return self:GetFairyTaleTDText1(...)
            end,
        }
        self._funcList = funcList
    end
    local func = funcList[refId]
    if func then
        return func(text1, ccLngText(str))
    end
    return ""
end

function UISubOuttsPVE:GetEndlesText1(text1, str)
    if text1 == "" then
        return ""
    end
    local text = ""
    local text1Arr = string.split(text1, "|")
    for i, v in ipairs(text1Arr) do
        local arr = string.split(v, "=")
        local titleStr = ccClientText((12812 + tonumber(arr[1])))
        local ref = gModelEndles:GetEndlessCheckpointRefByRefId(tonumber(arr[2]))
        if i == 1 then
            text = string.replace(titleStr, ref and ref.id or arr[2])
        else
            text = text .. "/" .. string.replace(titleStr, ref and ref.id or arr[2])
        end
    end
    return string.replace(str, text)
end

function UISubOuttsPVE:GetInvasionText2(text1, text2, str)
    if text2 == "" then
        return string.replace(str, ccClientText(12820))
    end
    return string.replace(str, text2)
end


--endregion --------------------------------------------------------------------------------------


--region 页面方法 --------------------------------------------------------------------------------
--页面初始化
UISubOuttsPVE.pageDailyGameEnterType = 1

function UISubOuttsPVE:InitOutskirtsPVE()
    self:InitPVEListData()

    local isOpen = gModelFunctionOpen:CheckIsOpened(12400000, false)
    if isOpen then
        for i = 1, 4 do
            gModelDungeonDaily:DailyBraveMessageReq(i)
        end
    end
end

function UISubOuttsPVE:GetTimeCorridorText2(text1, text2, str)
    if text2 == "" then
        return string.replace(str, ccClientText(12820))
    end
    return string.replace(str, text2 .. "%")
end

--列表的数据初始化和创建
function UISubOuttsPVE:InitPVEListData()
    self._PVEListData = { }

    self._PVEListData = gModelDailyGameEnter:GetEnterList(UISubOuttsPVE.pageDailyGameEnterType)

end

function UISubOuttsPVE:GetTimeCorridorText1(text1, str)
    --if text1 == "" then
    return string.replace(str, ccClientText(12820))
    --end
    --local ref = gModelTimeCorridor:GetCheckpointRef(tonumber(text1))
    --local nameStr = nil
    --if ref.isShow == 0 then
    --    nameStr = string.format("%s-%s", ccClientText(19141), ccLngText(ref.name))
    --else
    --    nameStr = string.format("%s-%s", ccClientText(19142), ccLngText(ref.name))
    --
    --end
    --return string.replace(str, nameStr)
end

function UISubOuttsPVE:GetWonderText1(text1, str)
    if text1 == "" then
        return string.replace(str, ccClientText(12821))
    end
    local ref = gModelWonderland:GetThemeConfig(tonumber(text1))
    local pattern = ref.pattern
    local patternName = nil
    if pattern == ModelWonderland.NORMAL then
        patternName = ccClientText(16793)
    elseif pattern == ModelWonderland.HARD then
        patternName = ccClientText(16794)
    else
        patternName = ccClientText(16795)
    end
    local name = string.format("%s[%s]", ccLngText(ref.name), patternName)
    return string.replace(str, name)
end

function UISubOuttsPVE:GetDreamTripText1(text1, str)
    if text1 == "" then
        return string.replace(str, ccClientText(12820))
    end
    local mapId = tonumber(text1)
    local ref = gModelDreamTrip:GetMapRefByMapId(mapId)
    if not ref then
        return string.replace(str, ccClientText(12821))
    end
    return string.replace(str, ccLngText(ref.name))
end

--这里会去请求一次消息
function UISubOuttsPVE:InitCommand()
    --self:RefreshData()
    self:RefreshReq()
end

function UISubOuttsPVE:RefreshReq()
    local refList = gModelDailyGameEnter:GetEnterList(UISubOuttsPVE.pageDailyGameEnterType)
    local list = {}
    for i, v in pairs(refList) do
        table.insert(list, v.refId)
    end
    gModelGeneral:OnDailyGameInfoReq(list)
end
--解析部分要挪到Model类型中
--解析时间
function UISubOuttsPVE:GetResidueTimeByRefId(refId, str)
    if not self._infoList then
        return ""
    end
    local info = self._infoList[refId]
    local timeText = info and info.timeText or ""
    if timeText == "" then
        return ""
    end
    local timespan = (tonumber(timeText) or 0) / 1000 - GetTimestamp()
    if timespan < 0 then
        return ""
    end
    local textStr = ccLngText(str)
    if refId == 105 then
        local isEnd = gModelDreamTrip:IsEndMapIdx()
        if isEnd then
            textStr = ccClientText(20496)
        end
    end
    local timeStr = LUtil.FormatTimespanCn(timespan)
    return string.replace(textStr, timeStr)
end

function UISubOuttsPVE:SetTime()
    for i, v in pairs(self._timeList) do
        if v.str then
            local timeStr
            if v.ref and v.info then
                timeStr = gModelDungeonDaily:GetResidueTimeByRefId(v.ref, v.info)
            elseif v.timeStrFunc then
                timeStr = v.timeStrFunc()
            else
                timeStr = self:GetResidueTimeByRefId(i, v.str)
            end
            self:SetWndText(v.text, timeStr)
        end
    end
end

--解析文本表--2和相关的方法
function UISubOuttsPVE:GetText2ByRefId(refId, str)
    if not self._infoList then
        return ""
    end
    local info = self._infoList[refId]
    local text1 = info and info.text1 or ""
    local text2 = info and info.text2 or ""

    local funcList = self._func2List
    if not funcList then
        funcList = {
            [102] = function(...)
                return self:GetEndlesText2(...)
            end,
            [103] = function(...)
                return self:GetTimeCorridorText2(...)
            end,
            [104] = function(...)
                return self:GetWonderText2(...)
            end,
            [105] = function(...)
                return self:GetDreamTripText2(...)
            end,
            [107] = function(...)
                return self:GetInvasionText2(...)
            end,
            [108] = function(...)
                return self:GetFairyTaleTDText2(...)
            end,
        }
        self._func2List = funcList
    end
    local func = funcList[refId]
    if func then
        return func(text1, text2, ccLngText(str))
    end
end

function UISubOuttsPVE:GetDreamTripText2(text1, text2, str)
    if text1 == "" then
        return string.replace(str, ccClientText(12820))
    end
    local ref = gModelDreamTrip:GetMapRefByMapId(tonumber(text1))
    if text2 == "" then
        return string.replace(str, ccClientText(12820))
    end

    if not ref then
        return ""
    end

    if gModelDreamTrip:IsEndMapIdx() then
        return string.replace(str, ccClientText(20494))
    end

    return string.replace(str, tonumber(text2) + 1 .. "/" .. ref.count)
end

--endregion --------------------------------------------------------------------------------------





------------------------------------------------------------------
return UISubOuttsPVE