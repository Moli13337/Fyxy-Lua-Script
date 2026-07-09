---
--- Created by Administrator.
--- DateTime: 2023/10/22 16:10:25
---
------------------------------------------------------------------
local LWnd = LWnd
---@class UIFeat:LWnd
local UIFeat = LxWndClass("UIFeat", LWnd)
------------------------------------------------------------------
local YXUIPointUtil = CS.YXUIPointUtil
---@type LUIEffectObject
local LUIEffectObject = LxRequire("LApp.UI.Display.LUIEffectObject")

UIFeat.END_NUM = -1
UIFeat.START_NUM = 1
UIFeat.CENTER_NUM = 0

UIFeat.USE_ITEM_REFID = 108109
------------------------------------------------------------------

--- 窗口成员变量初始化
--- 所有用到的变量都需要在此声明，初始化数值类型尽量不要使用table
------------------------------------------------------------------
function UIFeat:UIFeat()
    ---@type table<number,UIIconEasyList>
    self._uiListTbl = {}

    ---@type table<number,LUIEffectObject>
    self._uiEffectObjList = {}
    self._flayEffIdx = 0

    self._timerPlayIntegrateEffectKey = "PlayIntegrateEffectFlay"
    self._getBtnEffName = "fx_anniu_02"

    self:SetHideHurdle()
end
------------------------------------------------------------------
--- 窗口关闭
--- 处理成员变量销毁工作
------------------------------------------------------------------
function UIFeat:OnWndClose()
    --self:DestroyIntegrateEffectAll()
    --self:DestroyWndEffectAll()
    if self._uiEffectObjList then
        local listObj = self._uiEffectObjList
        for k, v in pairs(listObj) do
            listObj[k] = nil
            v:Destroy()
        end
        self._uiEffectObjList = nil
    end

    if self._simplePool then
        self._simplePool:Destroy()
        self._simplePool = nil
    end

    --if self._uiTypeList then
    --	self._uiTypeList:Destroy()
    --	self._uiTypeList=nil
    --end

    if self._uiListTbl then
        local uiListTbl = self._uiListTbl
        for k, v in pairs(uiListTbl) do
            v:Destroy()
            uiListTbl[k] = v
        end
        self._uiListTbl = nil
    end

    if self._achievementList then
        self._achievementList:OnWndClose()
    end

    --self:DestroyLvlUpEffect()

    LWnd.OnWndClose(self)
end
------------------------------------------------------------------
--- 窗口创建开始
--- 处理窗口属性设置或一些条件检测
------------------------------------------------------------------
function UIFeat:OnCreate()
    LWnd.OnCreate(self)
    return true
end
------------------------------------------------------------------
--- 窗口创建结束
--- 处理窗口数据初始化
------------------------------------------------------------------
function UIFeat:OnStart()
    LWnd.OnStart(self)
    self:InitUI()
    self:InitData()

    local name = gModelItem:GetNameByRefId(UIFeat.USE_ITEM_REFID) or ccClientText(19540)
    self:SetWndText(self.mShowDescTxt, name)
    self:SetWndText(CS.FindTrans(self.mRankLookBtn, "Text"), ccClientText(18901))
    self:InitEvent()
    self:InitMessage()
    self:InitTag()
    self:InitList()
    self:SetPara()
    self:InitTypeList()
    self:InitScheduleList()
    self:InitIntegrateEffectPlayPool()

    self:SetWndText(self.mTitle, ccClientText(19506))
    self:SetWndText(self.mSelectText, ccClientText(19509))

    local cfg = gModelGeneral:GetEmptyCfg(11001)
    local text = ccLngText(cfg.text)
    self:SetWndText(self.mEmptyText, text)

    --关闭任务界面
    GF.CloseWndByName("UIQst")

    self:SetSecretJumpBtn(self.mBtnSecret, 8)
end

function UIFeat:OnTargetWndClose(wndName)
    if wndName == "UIBtnLPop" and self._achievementList then
        --重新开启滑动
        self._achievementList:SetDecelerationRate(0.135)
    end
end

function UIFeat:DestroyLvlUpEffect()
    self:DestroyWndEffectByKey(self._lvlUpEffectKey)
    self._lvlUpEffect = nil
end

function UIFeat:GetPageTypeByRefId(refId)
    local cfg = gModelAchievement:GetAchievementConfig(refId)
    if not cfg then
        return nil
    end

    return cfg.type
end

function UIFeat:RefreshRank()
    local rank = gModelAchievement:GetCurAchievementRank()

    local rankType = ModelRank.RANK_ACHIEVEMENT
    local ref = gModelRank:GetRankingRefData(rankType)
    if not ref then
        LogError("RankingRef[refId] is not find, refId = " .. rankType)
    else
        local quantity = ref.quantity
        if not rank or rank > quantity then
            rank = 0
        end
    end

    local str
    if not rank or rank <= 0 then
        str = ccClientText(19526)
    else
        str = string.replace(ccClientText(19534), rank)
    end

    str = ccClientText(19508) .. str
    self:SetWndText(self.mRankText, str)
end

function UIFeat:RefreshBoxSlider()
    if #self._getAnimList > 0 then
        --目前在播放动画
        return
    end

    local curLvl = gModelAchievement:GetCurAchievementLvl()
    self._curAchievementLvl = curLvl
    local curExp = gModelAchievement:GetCurAchievementLvlExp()
    local lvlCfg = gModelAchievement:GetAchievementLvlCfgByLvl(curLvl)
    if not lvlCfg then
        printInfoNR("QuestAchvLvRef, cfg is not find , refId = " .. curLvl)
        return
    end

    local schedule = tonumber(curExp)
    local goal = lvlCfg.exp
    local progress = 0
    local str

    if goal > 0 then
        progress = schedule / goal
        str = string.format("%s/%s", schedule, goal)
    else
        progress = 1
        str = schedule
    end

    local slider = self:UIProgressFind(self.mSlider, self._boxSliderKey, progress)
    slider:SetUIProgress(progress)
    self:SetWndText(self.mTotalProgress, str)
    self:SetWndText(self.mLevelText, string.replace(ccClientText(19507), curLvl))

    --播放等级提升特效
    --if self._oldAchievementLvl and self._oldAchievementLvl < curLvl then
    --	self:ShowLvlUpEffect()
    --end

    self:RefreshBoxRedPoint()
end

function UIFeat:InitList()
    self._pageToType = {
        [1] = ModelAchievement.ALL, --总览
        [2] = ModelAchievement.ATHLETICS, --竞技
        [3] = ModelAchievement.COMBAT, --战斗
        [4] = ModelAchievement.SPECIAL, --特殊
    }

    self._typeNameList = {
        [ModelAchievement.ALL] = ccClientText(19502),
        [ModelAchievement.ATHLETICS] = ccClientText(19503),
        [ModelAchievement.COMBAT] = ccClientText(19504),
        [ModelAchievement.SPECIAL] = ccClientText(19505),
    }

    self._boxSliderKey = "_boxSliderKey"
    self._typeBtnList = {}
    self._effectKeyList = {}
    self._isSelectOnlyCompleted = false
    self._pageRedPointList = {}
    self._isChangeList = false
    self._itemdataList = nil
    self._lvlUpEffectKey = "fx_chengjiu"
    self._lvlUpEffectTime = "lvlUpEffectTime"
    self._oldAchievementLvl = nil
    self._curAchievementLvl = 0
    self._lvlUpEffectSpritePath = "achievement_num_"
    self._integrateItemRefId = 108109 --成绩积分道具id
    self._integrateEffKey = {
        ITEM = "fx_chengjiu_jifen_1",
        FLAY = "fx_chengjiu_jifen_2",
        ICON = "fx_chengjiu_jifen_3",
    }
    self._integrateEffList = {}
    self._getAnimList = {}

    --获取UI节点屏幕坐标。
    self._canvasRect = LGameUI.GetUICanvasRoot()
    self._numBoxEffScreenPos = self:GetTransScreenPos(self.mNumEffect)
end

function UIFeat:RefreshBoxRedPoint()
    local boxRed = self:FindWndTrans(self.mBoxBtn, "redPoint")

    local isShow = gModelRedPoint:CheckShowRedPoint(ModelRedPoint.ACHIEVEMENT_BOX)
    CS.ShowObject(boxRed, isShow)
end

function UIFeat:InitData()
    self._refId = self:GetWndArg("refId")
    self._canGetLvlRefIdList = gModelAchievement:GetCanGetLvlRefIdList() or {}
    self._effList = {}
    self._isFirstOpen = true
end

function UIFeat:InitIntegrateEffectPlayPool()
    local simplePool = LSimplePool:New()
    self._simplePool = simplePool

    simplePool:InitPool(self.mEffectRoot, "integrateEffPlay")

    local effName = self._integrateEffKey.FLAY
    local assetPath = CS.ResPath(CS.RES_ANY_PREFAB, LxResPathUtil.GetEffectAssetPath(effName))
    local args = simplePool:MakeArgs(assetPath, effName, nil, nil)
    simplePool:InitPoolItem(args)
end

function UIFeat:GetTransScreenPos(targetTrans)
    local canvasRect = self._canvasRect
    return YXUIPointUtil.GetScreenPoint(canvasRect, targetTrans)
end

--#####################################################################################################################
--## Content ##########################################################################################################
--#####################################################################################################################
function UIFeat:RefreshContent()
    local selectType = self._curType
    local itemdataList
    if self._isChangeList and self._itemdataList ~= nil then
        itemdataList = self:GetDataList(self._isSelectOnlyCompleted)
    else
        if selectType == ModelAchievement.ALL then
            itemdataList = gModelAchievement:GetAchievementList(nil, self._isSelectOnlyCompleted)
        else
            itemdataList = gModelAchievement:GetAchievementList(selectType, self._isSelectOnlyCompleted)
        end
    end

    if not self._isSelectOnlyCompleted then
        self._itemdataList = itemdataList
    end

    for k, v in ipairs(self._effectKeyList) do
        self:DestroyWndEffectByKey(v)
    end
    self._effectKeyList = {}
    self._isChangeList = false

    local achievementList = self._achievementList
    if not achievementList then
        achievementList = UIListWrap:New()
        achievementList:Create(self, self.mAchievementContent)
        achievementList:SetFuncOnItemDraw(function(...)
            self:SetAchievementItem(...)
        end)
        achievementList:SetFuncOnItemReturn(function(...)
            self:OnAchievementItemReturn(...)
        end)

        achievementList:EnableLoadAnimation(true, 0.04, 1, 2)
        achievementList:SetLoadAnimationScale(nil, 0.1)
        self._achievementList = achievementList
    else
        achievementList:EnableLoadAnimation(false)
    end
    achievementList:RemoveAll()

    local itemNum = #itemdataList
    local isEmpty = itemNum == 0
    CS.ShowObject(self.mEmptyTips, isEmpty)
    if isEmpty then
        return
    end

    for k, v in ipairs(itemdataList) do
        local refId = v:GetRefId()
        achievementList:AddData(refId, v)
    end

    if not self._refId then
        achievementList:RefreshSimpleList(UIListWrap.RefreshMode.Top)
    else
        local refreshCustom
        for k, v in ipairs(itemdataList) do
            local refId = v:GetRefId()
            if refId == self._refId then
                refreshCustom = k - 1
                break
            end
        end
        achievementList:RefreshList(UIListWrap.RefreshMode.Custom, refreshCustom or 0)
        self._refId = nil
    end
end

function UIFeat:PlayIntegrateEffectIcon()
    local effKey = self._integrateEffKey.ICON
    local effRoot = self.mNumEffect
    if not self:FindWndEffectByKey(effKey) then
        local effName = effKey
        self:CreateWndEffect(effRoot, effName, effKey, 120, false, false)
    else
        CS.ShowObject(effRoot, false)
    end

    CS.ShowObject(effRoot, true)
end

function UIFeat:ShowIntegrateEffect(refId, rewardListKey)
    for k, v in ipairs(self._getAnimList) do
        if v.refId == refId then
            --已有动画
            return
        end
    end

    local rewards = gModelAchievement:GetRewardList(refId)
    local itemPos
    local itemNum = 0
    for k, v in ipairs(rewards) do
        if v.itemId == self._integrateItemRefId then
            itemPos = k
            itemNum = v.itemNum
            break ;
        end
    end
    if not itemPos then
        return
    end

    local uiList = self._uiListTbl[rewardListKey]._uiList
    local itemTrans = uiList:GetItemByIndex(itemPos)
    if not itemTrans then
        return
    end

    local curLvl = self._curAchievementLvl
    local curExp = tonumber(gModelAchievement:GetCurAchievementLvlExp())
    local maxAnim = #self._getAnimList
    if maxAnim > 0 then
        local lastExp = self._getAnimList[maxAnim].oldExp
        curExp = math.max(curExp, lastExp)
    end

    local animData = {
        oldLvl = curLvl,
        oldExp = curExp,
        addExp = itemNum,
        refId = refId,
    }
    table.insert(self._getAnimList, animData)

    self:PlayIntegrateEffectItem(itemTrans, rewardListKey)
    self:PlayIntegrateEffectFlay(itemTrans, rewardListKey)
end

function UIFeat:InitEvent()
    self:SetWndClick(self.mReturnBtn, function()
        self:WndCloseAndBack()
    end)
    self:SetWndClick(self.mTaskBtn, function()
        self._isFirstOpen = true
        GF.OpenWndBottom("UIQst")
    end)

    self:SetWndClick(self.mBoxBtn, function()
        GF.OpenWnd("UIFeatAward")
    end)

    self:SetWndClick(self.mRankText, function()
        self:OnClickRankBtn()
    end)

    self:SetWndClick(self.mRankLookBtn, function()
        self:OnClickRankBtn()
    end)

    if not gModelFunctionOpen:CheckIsShow(11502020) then
        CS.ShowObject(self.mRankLookBtn, false)
        CS.ShowObject(self.mRankText, false)
    end

    self:SetWndClick(self.mLvlUpMask, function()
        self:CloseLvlUpEffect()
    end)

    self:SetWndClick(self.mBoxBg, function()
        gModelGeneral:OpenItemInfoTip(UIFeat.USE_ITEM_REFID)
    end)

    self:SetWndToggleDelegate(self.mSelectToggle, function(value)
        self._isSelectOnlyCompleted = value
        self._isChangeList = true
        self:SetWndToggleValue(self.mSelectToggle, value)
        self:RefreshContent()
    end)
end

function UIFeat:InitScheduleList()
    local list = self:GetScheduleList()
    local uiScheduleList = self._uiScheduleList
    if uiScheduleList then
        uiScheduleList:RefreshData(list)
    else
        uiScheduleList = self:GetUIScroll("uiScheduleList")
        self._uiScheduleList = uiScheduleList
        uiScheduleList:Create(self.mScheduleList, list, function(...)
            self:OnDrawScheduleCell(...)
        end)
        uiScheduleList:EnableScroll(true, true)
    end

    if not self._isFirstOpen then
        return
    end

    self._isFirstOpen = false
    local tminIndex = 1
    local index
    for i, v in ipairs(list) do
        if v.canGet then
            index = i
            break
        end
        if v.addExp >= v.expValue then
            tminIndex = i
        end
    end

    index = index or tminIndex
    if index then
        local uiList = uiScheduleList:GetList()
        uiList:DelayScrollTo(index + 2, UIListEasy.SCROLL_CENTER)
    end
end

function UIFeat:OnWndRefresh()
    self._refId = self:GetWndArg("refId")
    self:SetPara()
    self:InitTypeList()
    self:RefreshUI()
end

function UIFeat:OnClickType(refId)
    if self._curType == refId then
        return
    end

    local oldSelect = self._curType
    if not oldSelect or oldSelect == -1 then
        for k, v in pairs(self._typeBtnList) do
            local BtnTab1 = self:FindWndTrans(v, "BtnTab1")
            self:SetWndTabStatus(BtnTab1, LWnd.StateOff)
        end
    else
        local oldSelectItem = self._typeBtnList[oldSelect]
        if oldSelectItem then
            local BtnTab1 = self:FindWndTrans(oldSelectItem, "BtnTab1")
            self:SetWndTabStatus(BtnTab1, LWnd.StateOff)
        end
    end
    self._curType = refId
    self:SaveWndArg()
    local newSelectItem = self._typeBtnList[refId]
    if newSelectItem then
        local BtnTab1 = self:FindWndTrans(newSelectItem, "BtnTab1")
        self:SetWndTabStatus(BtnTab1, LWnd.StateOn)
    end

    self:RefreshUI()
end
--#####################################################################################################################
--## Effect ###########################################################################################################
--#####################################################################################################################
function UIFeat:ShowLvlUpEffect()
    CS.ShowObject(self.mLvlUpEffect, true)
    CS.ShowObject(self.mLvlUpMask, true)

    --改为不自动关闭
    --self:TimerStop(self._lvlUpEffectTime)
    --self:TimerStart(self._lvlUpEffectTime,3,false,1)

    if self._lvlUpEffect then
        local dpTrans = self._lvlUpEffect:GetDisplayTrans()
        if CS.IsValidObject(dpTrans) then
            self:RefreshLvlUpEffectImage(dpTrans)
            return
        end
    end

    local effectName = self._lvlUpEffectKey
    self._lvlUpEffect = self:CreateWndEffect(self.mLvlUpEffect, effectName, effectName, 100, false, false,
            3, nil, nil, nil, nil,
            function(effectTrans)
                self:RefreshLvlUpEffectImage(effectTrans)
            end)
end
--#####################################################################################################################
--## Time #############################################################################################################
--#####################################################################################################################
function UIFeat:OnTimer(key)
    if key == self._lvlUpEffectTime then
        self:CloseLvlUpEffect()
    end
end

function UIFeat:InitItemList(root, itemList, rewardListKey)
    local uiList = self._uiListTbl[rewardListKey]
    if not uiList then
        uiList = UIIconEasyList:New(self)
        self._uiListTbl[rewardListKey] = uiList
        uiList:Create(self, root)
        uiList:SetShowNum(false)
        uiList:SetIconParentPath("itemRoot/CommonUI/Icon")
        uiList:SetShowExtraNum(true, "itemNum")
        local maxNum = #itemList
        uiList:EnableScroll(maxNum > 4, true)
        uiList:SetItemEff(nil, 88)
    end
    uiList:RefreshList(itemList)
end

function UIFeat:InitMessage()
    self:WndEventRecv(EventNames.ON_ACHIEVEMENT_CHANGE, function(...)
        self:RefreshUI()
    end)
    self:WndEventRecv(EventNames.ON_ACHIEVEMENT_LVL_CHANGE, function(...)
        self:RefreshBoxContent()
    end)
    self:WndEventRecv(EventNames.ON_MAIN_CITY_BTN_CHANGE, function()
        self:WndClose()
    end)
    self:WndEventRecv(EventNames.ON_ENTER_BATTLE_MAP, function()
        self:WndClose()
    end)
    self:WndEventRecv(EventNames.ON_WND_CLOSE, function(...)
        self:OnTargetWndClose(...)
    end)

    gModelAchievement:OnAchievementListReq()
    gModelAchievement:OnAchievementTreasureBoxReq(0)
end

--[[UIFeat.END_NUM = -1
UIFeat.START_NUM = 1
UIFeat.CENTER_NUM = 0]]
function UIFeat:GetScheduleList()
    local canGetLvlRefIdList = self._canGetLvlRefIdList
    if not canGetLvlRefIdList then
        canGetLvlRefIdList = {}
        self._canGetLvlRefIdList = canGetLvlRefIdList
    end
    local cfgList = gModelAchievement:GetAchievementLvlCfgList()
    local list = {}
    local endNum = #cfgList
    local beforeNum = 0
    local curExp = gModelAchievement:GetCurAchievementLvlExp()
    local curLvl = gModelAchievement:GetCurAchievementLvl()
    local lvlCfg = gModelAchievement:GetAchievementLvlCfgByLvl(curLvl)
    local nextExpValue = lvlCfg.expValue
    local addExp = curExp + nextExpValue
    local lastExpValue = 0
    for i, v in ipairs(cfgList) do
        local expValue = v.expValue
        if expValue ~= 0 then
            local refId = v.refId
            local scheduleStatus
            if i == 1 then
                scheduleStatus = UIFeat.START_NUM
            elseif i == endNum then
                scheduleStatus = UIFeat.END_NUM
                lastExpValue = expValue
            else
                scheduleStatus = UIFeat.CENTER_NUM
            end
            local canGet = canGetLvlRefIdList[refId] and true or false
            local interval = expValue - beforeNum
            local lastNum = interval - (interval - (addExp - beforeNum))
            local progress = lastNum / interval
            beforeNum = expValue
            table.insert(list, {
                refId = refId,
                exp = v.exp,
                expValue = expValue,
                reward = v.reward,
                scheduleStatus = scheduleStatus,
                addExp = addExp,
                beforeNum = beforeNum,
                interval = interval,
                lastNum = lastNum,
                progress = progress,
                canGet = canGet,
            })
        else
            beforeNum = expValue
        end
    end

    local str = string.replace(ccClientText(19539), addExp, lastExpValue)
    self:SetWndText(self.mScheduleNum, str)
    return list
end

function UIFeat:RefreshBoxSliderByData(sliderData)
    local oldLvl = sliderData.oldLvl
    local oldExp = tonumber(sliderData.oldExp)
    local lvlCfg = gModelAchievement:GetAchievementLvlCfgByLvl(oldLvl)
    if not lvlCfg then
        printInfoNR("QuestAchvLvRef, cfg is not find , refId = " .. oldLvl)
        return
    end

    local schedule = oldExp + sliderData.addExp
    local goal = lvlCfg.exp
    local progress = 0
    local str

    if goal > 0 then
        progress = schedule / goal
        str = string.format("%s/%s", schedule, goal)
    else
        progress = 1
        str = schedule
    end

    local slider = self:UIProgressFind(self.mSlider, self._boxSliderKey, progress)
    slider:SetUIProgress(progress)
    self:SetWndText(self.mTotalProgress, str)
    self:SetWndText(self.mLevelText, string.replace(ccClientText(19507), oldLvl))

end
--#####################################################################################################################
--## Top ##############################################################################################################
--#####################################################################################################################
function UIFeat:RefreshBoxContent()
    self._canGetLvlRefIdList = gModelAchievement:GetCanGetLvlRefIdList()
    self:InitScheduleList()
    CS.ShowObject(self.mBoxContent, true)
    self:RefreshBoxSlider()
    self:RefreshRank()
    self:RefreshSelectToggle()
end

function UIFeat:OnClickAchievementGet(refId, rewardListKey)
    local netData = gModelAchievement:GetAchievementDataByRefId(refId)
    if not netData then
        return
    end

    self._oldAchievementLvl = self._curAchievementLvl
    self:ShowIntegrateEffect(refId, rewardListKey)
    gModelAchievement:OnAchievementReceiveReq(refId)
end

function UIFeat:RefreshSelectToggle()
    self:SetWndToggleValue(self.mSelectToggle, self._isSelectOnlyCompleted)
end

function UIFeat:CloseLvlUpEffect()
    self._oldAchievementLvl = nil
    self:TimerStop(self._lvlUpEffectTime)
    CS.ShowObject(self.mLvlUpMask, false)
    CS.ShowObject(self.mLvlUpEffect, false)
end

function UIFeat:SetAchievementItem(list, item, itemdata, itemPos)
    local bg = self:FindWndTrans(item, "bg")
    local completeIcon = self:FindWndTrans(bg, "completeIcon")
    local bgTitle = self:FindWndTrans(bg, "title")
    local rateTitle = self:FindWndTrans(bg, "rateTitle")
    local desc = self:FindWndTrans(bg, "Desc")
    local bgSlider = self:FindWndTrans(bg, "Slider")
    local SliderFillArea = self:FindWndTrans(bgSlider, "FillArea")
    local FillAreaFill = self:FindWndTrans(SliderFillArea, "Fill")
    local scheduleNum = self:FindWndTrans(bg, "scheduleNum")
    local bgProgress = self:FindWndTrans(bg, "progress")
    local bgItemList = self:FindWndTrans(bg, "itemList")
    local bgButton = self:FindWndTrans(bg, "button")
    local effTrans = self:FindWndTrans(bg, "Eff")
    local dateText = self:FindWndTrans(bg, "dateText")
    local Share = self:FindWndTrans(bg, "Share")
    local instance = item:GetInstanceID()

    local refId = itemdata:GetRefId()
    local cfg = gModelAchievement:GetAchievementConfig(refId)

    if not cfg then
        return
    end

    local rewards = gModelAchievement:GetRewardList(refId)
    --[[	local rewardListKey = refId..itemPos]]
    local rewardListKey = bgItemList:GetInstanceID()
    if rewards then
        self:InitItemList(bgItemList, rewards, rewardListKey)
    end

    local schedule = tonumber(itemdata:GetSchedule())
    local goal = tonumber(itemdata:GetGoal())

    local color = "black"
    if schedule >= goal then
        color = "green"
    end
    local scheduleValue = LUtil.NumberCoversion(schedule)
    local goalValue = LUtil.NumberCoversion(goal)
    local str = LUtil.FormatColorStr(string.format("%s/%s", scheduleValue, goalValue), color)
    self:SetWndText(bgProgress, str)

    local scheduleStr = string.format("%s/%s", schedule, goal)
    self:SetWndText(scheduleNum, scheduleStr)

    local nameStr = ccLngText(cfg.name)
    local severVal = itemdata:GetServerVal()
    local severValStr
    if severVal == 100 or severVal == 0 then
        severValStr = string.replace(ccClientText(19533), severVal)
    elseif severVal < 0.1 then
        severValStr = string.replace(ccClientText(19528), 0.1)
    elseif severVal > 99.9 then
        severValStr = string.replace(ccClientText(19529), 99.9)
    else
        severValStr = math.floor(severVal * 10) / 10
        severValStr = string.replace(ccClientText(19533), severValStr)
    end
    self:SetWndText(bgTitle, nameStr)
    self:InitTextSizeWithLanguage(bgTitle, -4)
    self:SetWndText(rateTitle, severValStr)
    self:SetWndText(desc, ccLngText(cfg.description))

    if gLGameLanguage:IsVieVersion() then
        self:InitTextLineWithLanguage(desc, 10)
    else
        self:InitTextLineWithLanguage(desc, -30)
    end
    local state = itemdata:GetState()
    CS.ShowObject(completeIcon, state == ModelAchievement.ACHIEVEMENT_REWARDED)
    CS.ShowObject(bgSlider, true)
    CS.ShowObject(scheduleNum, true)

    local originId = cfg.originId
    local canJump = not string.isempty(originId) and originId > 0
    local showBtn = state ~= ModelAchievement.ACHIEVEMENT_REWARDED
    CS.ShowObject(bgButton, showBtn)
    if showBtn then
        local txtId
        local color = "#ffffff"
        if state == ModelAchievement.ACHIEVEMENT_UNFINISH then
            if not canJump then
                txtId = 12206
            else
                txtId = 10152
                color = "#5c6d9a"
            end
        else
            txtId = 19512
        end

        local img = state == ModelAchievement.ACHIEVEMENT_UNFINISH and "public_btn_2_1" or "public_btn_2_2"
        self:SetWndButtonImg(bgButton, img)
        --local outlineMat = state == ModelAchievement.ACHIEVEMENT_UNFINISH and "blue" or "yellow"
        --local mat = LUtil.GetOutLineMat(outlineMat)
        --self:SetWndButtonTextMat(bgButton,mat)

        self:SetWndButtonText(bgButton, LUtil.FormatColorStr(ccClientText(txtId), color))
        self:SetWndButtonGray(bgButton, state == ModelAchievement.ACHIEVEMENT_UNFINISH and not canJump)
    end

    local isShowEff = state == ModelAchievement.ACHIEVEMENT_FINNISH
    CS.ShowObject(effTrans, isShowEff)
    if (isShowEff and not self._effList[instance]) then
        self:CreateWndEffect(effTrans, self._getBtnEffName, instance, 100, false, false, 0, nil, 100)
        self._effList[instance] = true
    end

    -- 6.24 修改效果图，没有显示时间
    --CS.ShowObject(bgProgress, state == ModelAchievement.ACHIEVEMENT_UNFINISH)
    CS.ShowObject(dateText, state == ModelAchievement.ACHIEVEMENT_REWARDED)

    local dateValue = itemdata:GetFinishTime()
    if state ~= ModelAchievement.ACHIEVEMENT_UNFINISH then
        local dateStr = dateValue
        local year, month, day = LUtil.GetYmdByTimestamp(dateStr)
        dateStr = string.replace(ccClientText(19527), year, fixedTimeToTwo(month), fixedTimeToTwo(day))
        self:SetWndText(dateText, dateStr) --完成日期
    end

    --self:SetImageActorState(bgButton,btnState)
    self:SetImageActorState(FillAreaFill, 1)

    local value = 0
    if goal > 0 then
        value = schedule / goal
    end
    LxUiHelper.SetProgress(bgSlider, value)

    self:SetWndClick(bgButton, function()
        if state == ModelAchievement.ACHIEVEMENT_UNFINISH then
            if canJump then
                gModelFunctionOpen:Jump(originId, self:GetWndName())
            end
        else
            self:OnClickAchievementGet(refId, rewardListKey)
        end
    end)
    self:SetWndClick(bg, function()
        self:OnClickShare(refId, state, dateValue, severVal, bgButton)
    end)
    self:SetWndClick(Share, function()
        self:OnClickShowRate(nameStr, severVal)
    end)
end

function UIFeat:DestroyIntegrateEffectByKey(key)
    if not self._integrateEffList then
        return
    end

    local effKey = self._integrateEffList[key].effKey
    self._integrateEffList[key] = nil
    self:DestroyWndEffectByKey(effKey)
end

function UIFeat:SetTypeItem(list, item, itemdata, itempos)
    local BtnTab1 = self:FindWndTrans(item, "BtnTab1")
    local bg = self:FindWndTrans(item, "bg")
    local redPointTrans = self:FindWndTrans(bg, "redPoint")
    local refId = itemdata
    local typeName = self._typeNameList[refId]
    self:SetWndTabText(BtnTab1, typeName)
    self:SetWndClick(bg, function()
        self:OnClickType(refId)
    end)
    local state = refId == self._curType and LWnd.StateOn or LWnd.StateOff

    self:SetWndTabStatus(BtnTab1, state)

    self._typeBtnList[refId] = item
    self._pageRedPointList[refId] = redPointTrans
    return item
end

function UIFeat:InitTag()
    self:SetWndTabText(self.mTaskBtn, ccClientText(19500))
    self:SetWndTabText(self.mAchievementBtn, ccClientText(19501))

    self:SetWndTabStatus(self.mTaskBtn, LWnd.StateOff)
    self:SetWndTabStatus(self.mAchievementBtn, LWnd.StateOn)
end

function UIFeat:PlayIntegrateEffectFlay(itemTrans, rewardListKey)
    local effName = self._integrateEffKey.FLAY
    local startPos = self:GetTransScreenPos(itemTrans)

    local idx = self._flayEffIdx + 1
    self._flayEffIdx = idx
    local uiEffectObj = LUIEffectObject:New(self)
    self._uiEffectObjList[idx] = uiEffectObj

    local completeFunc = function()
        local tmpObj = self._uiEffectObjList[idx]
        tmpObj:Destroy()
        self._uiEffectObjList[idx] = nil
        self:PlayIntegrateEffectIcon()
        local sliderData = table.remove(self._getAnimList, 1)
        if #self._getAnimList > 0 then
            self:RefreshBoxSliderByData(sliderData)
        else
            self:RefreshBoxSlider()
        end
    end

    uiEffectObj:EnablePool(self._simplePool)
    uiEffectObj:Create(self.mFlayEffRoot, effName, 100, 0, 2, function(obj)
        local dpEff = obj:GetDisplayEffect()
        dpEff:SetVisible(true)
        dpEff:GetDisplayTrans().localPosition = startPos
        obj:InitTweenMove(self._numBoxEffScreenPos, 0.5, completeFunc)
    end)
    uiEffectObj:StartLoad()
end

function UIFeat:GetDataList(onlyComplete)
    if not self._itemdataList then
        self._itemdataList = {}
    end

    local dataList = {}
    for k, v in ipairs(self._itemdataList) do
        local needAdd = true
        if onlyComplete then
            local state = v:GetState()
            needAdd = state ~= ModelAchievement.ACHIEVEMENT_UNFINISH
        end

        if needAdd then
            table.insert(dataList, v)
        end
    end

    return dataList
end

function UIFeat:OnAchievementItemReturn(list, item, itemdata, itemPos)
    if not itemdata then
        return
    end
    local refId = itemdata:GetRefId()
    local key = "achievement" .. tostring(refId)
    self:DestroyWndEffectByKey(key)
end

function UIFeat:PlayIntegrateEffectItem(itemTrans, rewardListKey)
    local effRoot = CS.FindTrans(itemTrans, "Eff")
    if effRoot then
        local effName = self._integrateEffKey.ITEM
        local effKey = effName .. rewardListKey
        self:DestroyWndEffectByKey(effKey)
        self:CreateWndEffect(effRoot, effName, effKey, 100, false, false)
    else
        LxResUtil.DestroyChildImmediate(effRoot)
    end
end

function UIFeat:SetPara()
    local refId = self._refId
    if refId then
        self._curType = self:GetPageTypeByRefId(refId)
    end

    local page = self:GetWndArg("page")
    if not self._curType and page then
        self._curType = self._pageToType[page]
    end

    if not self._curType then
        self._curType = gModelAchievement:GetShowType()
    end
end

function UIFeat:DestroyIntegrateEffectAll()
    if not self._integrateEffList then
        return
    end

    for k, v in pairs(self._integrateEffList) do
        self:DestroyIntegrateEffectByKey(k)
    end

    self._integrateEffList = nil
end

function UIFeat:RefreshLvlUpEffectImage(effectTrans)
    local ziTrans = CS.FindTrans(effectTrans, "yuan/zi")
    local zi1Trans = CS.FindTrans(effectTrans, "yuan/zi1")
    local zi2Trans = CS.FindTrans(effectTrans, "yuan/zi2")

    local curLvl = self._curAchievementLvl
    if curLvl > 99 then
        LogError("curLvl is to big, curLvl = " .. curLvl)
        return
    end

    local firstNum = curLvl % 10
    local secondNum = (curLvl - firstNum) / 10
    local isTwoIcon = secondNum > 0

    CS.ShowObject(ziTrans, not isTwoIcon)
    CS.ShowObject(zi1Trans, isTwoIcon)
    CS.ShowObject(zi2Trans, isTwoIcon)

    if not self._lvlUpEffect then
        return
    end

    if isTwoIcon then
        self:SetWndSpriteRenderer(zi2Trans, self._lvlUpEffectSpritePath .. firstNum)
        self:SetWndSpriteRenderer(ziTrans, self._lvlUpEffectSpritePath .. secondNum)
    else
        self:SetWndSpriteRenderer(ziTrans, self._lvlUpEffectSpritePath .. firstNum)
    end
end

--#####################################################################################################################
--## Common ###########################################################################################################
--#####################################################################################################################
function UIFeat:InitTypeList()
    self._typeShowList = gModelAchievement:GetAchievementTypeList()
    local typeDataList = {}
    for k, v in ipairs(self._pageToType) do
        if k == 1 then
            table.insert(typeDataList, v)
        elseif self._typeShowList[v] then
            table.insert(typeDataList, v)
        end
    end

    self._pageRedPointList = {}
    local uiTypeList = self:FindUIScroll("uiTypeList")
    if not uiTypeList then
        uiTypeList = self:GetUIScroll("uiTypeList")
        uiTypeList:Create(self.mTypeList, typeDataList, function(...)
            self:SetTypeItem(...)
        end)
    else
        uiTypeList:RefreshList(typeDataList)
    end
    --self._uiTypeList = UIItemList:New(self)
    --self._uiTypeList:Create(self.mTypeList,typeDataList,function (...) self:SetTypeItem(...) end)
end

function UIFeat:RefreshUI()
    self._itemdataList = nil
    self:RefreshBoxContent()
    self:RefreshContent()
end

function UIFeat:OnClickRankBtn()
    GF.OpenWndBottom("UIRkPop", { refId = ModelRank.RANK_ACHIEVEMENT, })
end

function UIFeat:OnClickShare(refId, state, dateValue, severVal, btnTrans)
    if self._achievementList then
        --停止滑动
        self._achievementList:SetDecelerationRate(0)
    end

    local shareData = {
        achievementRefId = refId,
        achievementState = state,
        achievementDate = dateValue,
        achievementRate = severVal,
        fightPower = gModelPlayer:GetPlayerFightPower(),
        playerLevel = gModelPlayer:GetPlayerLv(),
    }

    local jsonStr = JSON.encode(shareData)
    local data = {
        root = btnTrans,
        shareType = ModelChat.CHATSHARE_ACHIEVEMENT,
        shareData = jsonStr
    }

    gModelGeneral:OpenShareTip(data)
end

function UIFeat:SaveWndArg()
    local pageIdex = nil
    for idx, v in pairs(self._pageToType) do
        if v == self._curType then
            pageIdex = idx
            break
        end
    end

    if pageIdex then
        local argList = self:GetWndArgList() or {}
        argList["page"] = pageIdex
        self:SetWndArg(argList)
    end
end

function UIFeat:OnClickShowRate(nameStr, severVal)
    GF.OpenWnd("UIFeatRate", { name = nameStr, rate = severVal })
end

function UIFeat:OnDrawScheduleCell(list, item, itemdata, itempos)
    local LeftDiv = self:FindWndTrans(item, "LeftDiv")
    local RightDiv = self:FindWndTrans(item, "RightDiv")
    local CenterDiv = self:FindWndTrans(item, "CenterDiv")
    local div
    local scheduleStatus = itemdata.scheduleStatus
    if scheduleStatus == UIFeat.START_NUM then
        div = LeftDiv
        CS.ShowObject(RightDiv, false)
        CS.ShowObject(CenterDiv, false)
    elseif scheduleStatus == UIFeat.END_NUM then
        div = RightDiv
        CS.ShowObject(LeftDiv, false)
        CS.ShowObject(CenterDiv, false)
    else
        div = CenterDiv
        CS.ShowObject(RightDiv, false)
        CS.ShowObject(LeftDiv, false)
    end
    local width = item.sizeDelta.x
    LxUiHelper.SetSizeWithCurAnchor(item, 0, width)
    CS.ShowObject(div, true)

    local instanceId = item:GetInstanceID()
    local refId = itemdata.refId
    local addExp = itemdata.addExp
    local expValue = itemdata.expValue
    local isFull = addExp >= expValue

    local Schedule = self:FindWndTrans(div, "Div/Schedule")
    local Image = self:FindWndTrans(Schedule, "Image")

    local jiao = self:FindWndTrans(div, "jiao")
    local Box = self:FindWndTrans(jiao, "Box")
    local OpenBox = self:FindWndTrans(jiao, "OpenBox")
    local Btn = self:FindWndTrans(jiao, "Btn")
    local canGet = itemdata.canGet
    local showBox, showOpenBox = false, false
    self:DestroyWndEffectByKey(instanceId)
    if canGet then
        --self:CreateWndEffect(Box, "fx_baoxiang_paiweisai01", instanceId, 80)
        self:CreateWndEffect(Box, "fx_richangbaoxiang", instanceId, 80)
        showBox = true
    else
        if isFull then
            showBox = false
        else
            showBox = true
        end
        showOpenBox = not showBox
    end
    CS.ShowObject(Box, showBox)
    CS.ShowObject(OpenBox, showOpenBox)
    self:SetWndClick(Btn, function()
        if showBox then
            if canGet then
                gModelAchievement:OnAchievementTreasureBoxReq(refId)
            else
                GF.OpenWnd("UIFeatAward")
            end
        elseif showOpenBox then
            GF.OpenWnd("UIFeatAward")
        end
    end)

    local NumBg = self:FindWndTrans(div, "NumBg")
    local MissTxt = self:FindWndTrans(NumBg, "MissTxt")
    local ReachTxt = self:FindWndTrans(NumBg, "ReachTxt")

    local showTxtTrans, hideTxtTrans
    if isFull then
        showTxtTrans, hideTxtTrans = ReachTxt, MissTxt
    else
        showTxtTrans, hideTxtTrans = MissTxt, ReachTxt
    end
    self:SetWndText(showTxtTrans, expValue)
    CS.ShowObject(showTxtTrans, true)
    CS.ShowObject(hideTxtTrans, false)

    local progress = itemdata.progress
    LxUiHelper.SetProgress(Image, progress)
end

------------------------------------------------------------------
return UIFeat



