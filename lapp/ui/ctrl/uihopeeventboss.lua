---
--- Created by LCM.
--- DateTime: 2024/3/2 16:34:13
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIHopeEventBoss:LWnd
local UIHopeEventBoss = LxWndClass("UIHopeEventBoss", LWnd)
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIHopeEventBoss:UIHopeEventBoss()
    self._isSkipCheck = false
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIHopeEventBoss:OnWndClose()
    --FireEvent(EventNames.ON_DREAMTRIP_CLEARANISTATUS)
    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIHopeEventBoss:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIHopeEventBoss:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitText()
    self:InitEvent()
    self:InitMsg()
    self:InitData()
    self:InitBossList()
    self:InitItemList()
    self:RefreshView()
end

function UIHopeEventBoss:InitBossList()
    local list = self:GetBossList()
    local uiBossList = self._uiBossList
    if uiBossList then
        uiBossList:RefreshList(list)
    else
        uiBossList = self:GetUIScroll("uiBossList")
        self._uiBossList = uiBossList
        uiBossList:Create(self.mBossList,list,function(...) self:OnDrawBossCell(...) end)
    end
end

function UIHopeEventBoss:OnDrawItemCell(list,item,itemdata,itempos)
    local CommonUITrans = self:FindWndTrans(item,"CommonUI")
    local IconTrans = self:FindWndTrans(CommonUITrans,"Icon")

    local itemType, itemId, itemNum = itemdata.itemType, itemdata.itemId, itemdata.itemNum
    local instanceId = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(IconTrans)
    baseClass:SetCommonReward(itemType, itemId, itemNum)
    baseClass:DoApply()

    self:SetWndClick(IconTrans,function()
        gModelGeneral:ShowCommonItemTipWnd(itemdata,{showSkinCode=true})
    end)
end

function UIHopeEventBoss:GoToBattle()
    local isSkip = self._isSkipCheck
    local extraData = self:GetExtraData()
    local combatType = gModelCommonDreamTrip:GetDreamTripCombatType(extraData)
    local combatData = {
        combatType = combatType,
        targetId = self._eventId,
        --formationA = data,
        sid = extraData.sid,
        skipBattle = isSkip,
    }
    gModelBattle:StartAfterSetFormation(combatData)
end

function UIHopeEventBoss:OnClickGotoBtnFunc()
    local gotoBattleFunc = function()
        if not self:IsWndValid() then return end
        self:GoToBattle()
    end

    local isSkip = self._isSkipCheck

    local extraData = self:GetExtraData()
    local heroList = gModelCommonDreamTrip:GetSelHeroList(extraData)
    if #heroList < 1 then
        self:GoToBattlePre()
    elseif #heroList < 5 then
        gModelGeneral:OpenUIOrdinTips({refId = 300001,func = gotoBattleFunc,leftFunc = function()
            self:GoToBattlePre()
        end})
    else
        if isSkip then
            gotoBattleFunc()
        else
            self:GoToBattlePre()
        end
    end
end

function UIHopeEventBoss:OnClickCancelBtnFunc()
end

function UIHopeEventBoss:InitData()
    self._eventId = self:GetWndArg("eventId")
    self._index = self:GetWndArg("index")

    local extraData = self:GetWndArg("extraData")
    self._extraData = extraData

--[[    local doubleCardParam = gModelDreamTrip:GetEventRewardNum(self._eventId,self._index,self:GetExtraData())
    self._doubleCardParam = doubleCardParam]]
end


function UIHopeEventBoss:InitMsg()

    --- 7.20新增活动梦境之旅
    --self:WndNetMsgRecv(LProtoIds.ActivityDreamTripStartEventResp,function(pb,ret)
    --    if pb.eventId ~= self._eventId then return end
    --    local endInfo = pb.endInfo
    --    if not endInfo then return end
    --    if endInfo.state == 2 then
    --        self:WndClose()
    --    end
    --end)

    -- self:WndNetMsgRecv(LProtoIds.xxx,function(pb) self:Onxxx(pb) end)
    -- self:WndEventRecv(EventNames.NET_ERROR_CODE,function() end)
end

function UIHopeEventBoss:RefreshView()
    local extraData = self:GetExtraData()
    local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,extraData)
    if eventData then
        local eventRefId = eventData.eventRefId
        local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
        if eventRef then
            local choose = tonumber(eventRef.choose)
            local textRef = gModelDreamTrip:GetDreamTripTextRefByRefId(choose)
            if textRef then
                local dec = ccLngText(textRef.dec)
                self:SetWndText(self.mPost,dec)
            end

            self:SetWndText(self.mMainTitle,ccLngText(eventRef.name))

            local prefab = eventRef.prefab
            self:CreateWndSpine(self.mRole,prefab,prefab,false)
        end
        local isSkipCheck = gModelCommonDreamTrip:GetIsSkipOpen({
            mapType = extraData.mapType,
            sid = extraData.sid,
            eventRefId = eventRefId,
        })
        self:SetWndToggleValue(self.mSkipPrepare,isSkipCheck)
        self._isSkipCheck = isSkipCheck
    end
end

function UIHopeEventBoss:OnDrawBossCell(list,item,itemdata,itempos)
    local HeroIconTrans = self:FindWndTrans(item,"HeroIcon")
    local bloodTrans = self:FindWndTrans(item,"blood")

    local instanceId = item:GetInstanceID()
    local baseClass = self:GetCommonIcon(instanceId)
    baseClass:Create(HeroIconTrans)
    local herodata = {
        trans = bloodTrans,
        id = itemdata.id,
        refId = itemdata.monsterRefId,
        star = itemdata.star,
        level = itemdata.lvl,
        isResonance = itemdata.resonance,
        skin = itemdata.skin,
        isMon = true,
    }
    baseClass:SetHeroDataSet(herodata)
    baseClass:DoApply()

    LxUiHelper.SetProgress(bloodTrans,1)
end

function UIHopeEventBoss:GetExtraData()
    return self._extraData
end

function UIHopeEventBoss:GoToBattlePre()
    local extraData = self:GetExtraData()
    local bossId = gModelActivityDreamTrip:GetCurBossId()
    if not bossId then return end

    local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(bossId)
    local monsterName = monsterFormationRef and ccLngText(monsterFormationRef.name) or ""

    local monsterPower = 0
    local formation = monsterFormationRef and monsterFormationRef.formation or 1
    local monsterId = self:GetMonsterRefId()
    --local monsterRef = gModelHero:GetMonsterAttrByRefId(monsterId)
    if monsterFormationRef then
        monsterPower = monsterFormationRef.monsterPower
    end

    local bossIdList = {}
    table.insert(bossIdList,bossId)

    local powerList = {}
    table.insert(powerList,monsterPower)

    local sid = extraData.sid
    local combatType = gModelCommonDreamTrip:GetDreamTripCombatType(extraData)
    local cExtraData = {
        bossId = bossId,
        bossIdList = bossIdList,
        monsterPower = monsterPower,
        monsterId = monsterId,
        formation = formation,
        sid = sid,
        targetId = self._eventId,
        otherName = monsterName,
        skipBattle = self._isSkipCheck,
        returnFunc = function()
            local gridInfo = gModelActivityDreamTrip:GetDreamTripGridInfoBySid(sid)
            if gridInfo then
                gModelGeneral:RecoverGameState()
            else
                gModelGeneral:ClearRecordGameState()
                gModelCommonDreamTrip:GoToActivityDreamTrip(sid,{ignoreEff = true})
            end
        end
    }
    gModelGeneral:RecordGameState()
    gLFightManager:PrepareGoToBattle(combatType,cExtraData)
end

function UIHopeEventBoss:InitEvent()
    self:SetWndClick(self.mMask,function () self:WndClose() end,LSoundConst.CLICK_CLOSE_COMMON)
    self:SetWndClick(self.mCancelBtn,function() self:OnClickCancelBtnFunc() end)
    self:SetWndClick(self.mGotoBtn,function() self:OnClickGotoBtnFunc() end)
    self:SetWndToggleDelegate(self.mSkipPrepare,function(value)
        self._isSkipCheck = value
        local extraData = self:GetExtraData()
        local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,extraData)
        if eventData then
            if not gModelCommonDreamTrip:SetIsSkipOpen({
                value = value,
                mapType = extraData.mapType,
                sid = extraData.sid,
                eventRefId = eventData.eventRefId,
            }) then
                self:SetWndToggleValue(self.mSkipPrepare,false)
            end
        end
    end)
end

function UIHopeEventBoss:InitText()
    self:SetWndButtonText(self.mGotoBtn,ccClientText(30108))
    self:SetWndText(self.mTitle,ccClientText(30110))
    self:SetWndText(self:FindWndTrans(self.mSkipPrepare,"Label"),ccClientText(30109))
    self:SetWndText(self.mCloseTip,ccClientText(10103))
end
------------------------- List -------------------------

function UIHopeEventBoss:GetBossList()
    local list = {}
    local monsterId = self:GetMonsterRefId()
    if monsterId then
        list = gModelCommonDreamTrip:GetDreamTripMonsterList({
            bossIdList = {monsterId}
        })
    end
    return list
end

function UIHopeEventBoss:GetMonsterRefId()
    local bossId = gModelActivityDreamTrip:GetCurBossId()
    if bossId then
        local monsterFormationRef = gModelHero:GetMonsterFormationRefByRefId(bossId)
        if monsterFormationRef then
            local extraData = self:GetExtraData()
            local bossIndex = gModelActivity:GetModel84BossIndexBySidAndBossId(extraData.sid,bossId)
            if bossIndex then
                local key = "monster" .. bossIndex
                local monsterId = monsterFormationRef[key]
                return monsterId
            end
        end
    end
end

function UIHopeEventBoss:GetHistory()
    local list = LWnd.GetHistory(self)
    local wndArgList = list.wndArgList
    wndArgList.extraData = self:GetExtraData()
    return list
end

function UIHopeEventBoss:GetItemList()
    local list = {}
    local eventData = gModelCommonDreamTrip:GetPlatformEventInfo(self._eventId,self._index,self:GetExtraData())
    if eventData then
        local eventRefId = eventData.eventRefId
        local eventRef = gModelDreamTrip:GetDreamTripEventInfoByRefId(eventRefId)
        if eventRef then
            list = gModelDreamTrip:GetDreamTripRewardListByGroup(eventRef.reward)
        end
    end
    return list
end

function UIHopeEventBoss:InitItemList()
    local list = self:GetItemList()
    local uiItemList = self._uiItemList
    if uiItemList then
        uiItemList:RefreshList(list)
    else
        uiItemList = self:GetUIScroll("uiItemList")
        self._uiItemList = uiItemList
        uiItemList:Create(self.mItemList,list,function(...) self:OnDrawItemCell(...) end)
    end
end

------------------------- List -------------------------

------------------------------------------------------------------
return UIHopeEventBoss



