---
--- Created by Administrator.
--- DateTime: 2024/7/24 20:14:48
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIOuttsList:LWnd
local UIOuttsList = LxWndClass("UIOuttsList", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIOuttsList:UIOuttsList()
    self._timeList = {}
    self._timeKey = "UIOuttsList_dungeonDailyTimeKey"
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIOuttsList:OnWndClose()
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIOuttsList:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIOuttsList:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self._isVie = gLGameLanguage:IsVieVersion()
    self:InitEvent()
    self:InitPara()
    self:DoReq()
    self:SetTitleName()

    --printInfoN2("----------cjh ---------redpoint--17100000", gModelRedPoint:CheckShowRedPoint(17100000))
    --printInfoN2("----------cjh ---------redpoint--17100010", gModelRedPoint:CheckShowRedPoint(17100010))
    --printInfoN2("----------cjh ---------redpoint--17100020", gModelRedPoint:CheckShowRedPoint(17100020))
    self:VersionRefresh()
end

--信息请求
function UIOuttsList:DoReq()
    local list = {}
    for i, v in pairs(self._listData) do
        if v.style == 2 then
            --这里只做2  样式的信息请求
            table.insert(list, v.refId)
        end
    end
    gModelGeneral:OnDailyGameInfoReq(list)
    if gModelFunctionOpen:CheckIsOpened(36000010) then
        gModelDivineWeaponFight:DescendsInfoReq()
    end

    gModelCrusadeAgainst:OnCrusadeAgainstInfoReq()
end
--endregion --------------------------------------------------------------------------------------

--region 计时器 --------------------------------------------------------------------------------
--开计时器
function UIOuttsList:OnTimer(key)
    if (self._timeKey == key) then
        self:SetTime()
    end
end
--region 页面初始化 --------------------------------------------------------------------------------
function UIOuttsList:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:WndClose()
    end)

    self:WndNetMsgRecv(LProtoIds.DailyGameInfoResp, function(pb)
        local refId = pb.infos[1].refId
        local isSubData = false
        for k, v in ipairs(self._listData) do

            if v.refId == refId then
                isSubData = true
                break
            end
        end

        if isSubData then
            self:OnDailyGameInfoResp(pb)
        end

    end)

    self:WndEventRecv(EventNames.FISH_BASE_INFO, function(...)
        self:SetListItem()
    end)
    self:WndEventRecv(EventNames.DESIRE_TRAIL_BASE_INFO, function(...)
        self:SetListItem()
    end)

    self:WndEventRecv(EventNames.On_Item_Change, function(...)
        self:SetListItem()
    end)
    self:WndEventRecv("DescendsInfoResp", function(...)
        self:SetListItem()
    end)

    self:WndNetMsgRecv(LProtoIds.CrusadeAgainstInfoResp, function(pb)
        self:SetListItem()
    end)
end

function UIOuttsList:SetTitleName()
    if self._listRefId > 0 then
        local parentRef = GameTable.DailyGamePlayRef[self._listRefId]

        local name = ccLngText(parentRef.name)
        self:SetWndText(self.mTitle, name)
    end
end

function UIOuttsList:InitPara()
    self._listRefId = self:GetWndArg("listRefId")

    if (not self._listRefId) or self._listRefId == 0 then
        self:WndClose()
        return
    end

    self._listData = gModelDailyGameEnter:GetSubListByGroup(self._listRefId)

    if table.isempty(self._listData) then
        self:WndClose()
        return
    end
    self:SetListItem()
end

function UIOuttsList:SetTime()
    local refreshItem = false
    for i, v in pairs(self._timeList) do
        if v.str then
            local timeStr
            if v.ref and v.info then
                timeStr = gModelDungeonDaily:GetResidueTimeByRefId(v.ref, v.info)
            elseif v.timeStrFunc then
                timeStr = v.timeStrFunc()
                if timeStr == "" then
                    refreshItem = true
                end
            else
                timeStr = self:GetResidueTimeByRefId(i, v.str)
            end
            self:SetWndText(v.text, timeStr)
        end
    end
    if refreshItem then
        self:SetListItem()
    end
end


--endregion --------------------------------------------------------------------------------------

--region 事件部分 --------------------------------------------------------------------------------
--事件
function UIOuttsList:OnDailyGameInfoResp(pb)
    self._infoList = gModelGeneral:GetDailyGameInfoResp(pb)
    self:SetListItem()

    if not self:IsTimerExist(self._timeKey) then
        self:TimerStart(self._timeKey, 1, false, -1)
    end
end

function UIOuttsList:VersionRefresh()
    if gLGameLanguage:IsSEALngRegion() then
        if PRODUCT_G_VER ~= 0 then
            -- 提审
            local packId = LGameLanguage:GetPackProductInfo()
            if packId == 3 then
                CS.ShowObject(self.mTitle, false)
                CS.ShowObject(self.mReturnBtn, false)
            end
        end
    end
end
--是否战斗中
function UIOuttsList:ShowRunMask(itemdata)
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

function UIOuttsList:CreateListItem(list, item, itemdata, itempos)
    --节点名字
    item.name = "item_" .. itemdata.functionId

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

    if self._isVie then
        self:SetAnchorPos(timeTitle,Vector2.New(80,47))
        self:SetAnchorPos(lv_Title,Vector2.New(150,8.5))
    end

    CS.ShowObject(infoRoot, true)
    if isOpen then
        local funcList = gModelDailyGameEnter:GetItemInfoFunc(refId)
        if funcList then
            local info = self._infoList and self._infoList[refId] or nil
            local text1Str
            if funcList.text1 then
                if info then
                    text1Str = funcList.text1(info.text1, ccLngText(text1))
                else
                    text1Str = string.replace(text1, funcList.text1())
                end
            end

            local text2StrMaxCount, text2StrLeftCount

            local text2Str
            if funcList.text2 then
                if info then

                    text2Str = funcList.text2(info.text2, ccLngText(text2))
                else
                    text2StrMaxCount, text2StrLeftCount = funcList.text2()
                    text2Str = string.replace(text2, text2StrLeftCount, text2StrMaxCount)
                end
            end

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

            if funcList.isHaveData then
                CS.ShowObject(infoRoot, funcList.isHaveData())
            end

            if funcList.showLock then
                showLock = funcList.showLock()
            end
            if funcList.lockStr then
                lockStr = funcList.lockStr()
            end
            if funcList.showPass then
                showPass, passStr = funcList.showPass()
            end
            self:SetTime()
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
        elseif refId == 102 then
            local data = {}
            data.redtran = redTran
            data.func = function()
                return gModelDesireTrail:HadRed()
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
                    GF.ShowMessage(ccClientText(41414))
                end
            elseif functionId == ModelDesireTrail.MainFuncId then
                gModelGeneral:DesireTrailEntrance()
            elseif functionId == 36000010 then
                if gLFightManager:IsCombatTypeInFight(LCombatTypeConst.COMBAT_TYPE_47) then
                    gLFightManager:PrepareGoToBattle(LCombatTypeConst.COMBAT_TYPE_47, {})
                    return
                end
                GF.OpenWnd("UIDivineWeaponFight")
            else
                gModelFunctionOpen:Jump(functionId)
            end
        end
    end)
end

--解析时间
function UIOuttsList:GetResidueTimeByRefId(refId, str)
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


--endregion --------------------------------------------------------------------------------------

--region 页面方法 --------------------------------------------------------------------------------
function UIOuttsList:SetListItem()
    local itemList = self._uiPVEList
    if itemList then
        --itemList:RefreshList(refList)
        itemList:DrawAllItems(false)
    else
        itemList = self:GetUIScroll("mPVEList")
        itemList:Create(self.mPVEList, self._listData, function(...)
            self:CreateListItem(...)
        end, UIItemList.SUPER)

        self._uiPVEList = itemList
    end
end


--endregion --------------------------------------------------------------------------------------

------------------------------------------------------------------
return UIOuttsList